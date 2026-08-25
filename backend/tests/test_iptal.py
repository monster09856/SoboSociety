import asyncio
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, Instructor, LedgerTipi,
    Member, Package, Room,
)
from app.services.hatalar import ZatenIptal
from app.services.iptal import iptal_et
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et

DERS_ANI = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)


async def _rezervasyonlu_senaryo(db, *, iptal_penceresi_saat: int = 6):
    uye = Member(telefon="+905316033080", ad="Selin")
    tip = ClassType(
        ad="Barre", kontenjan=8, sure_dk=50,
        iptal_penceresi_saat=iptal_penceresi_saat,
    )
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    db.add_all([uye, tip, egitmen, salon, paket])
    await db.flush()

    oturum = ClassSession(
        baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=8,
    )
    db.add(oturum)
    await db.flush()

    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))
    kayit = await rezerve_et(db, member_id=uye.id, session_id=oturum.id)
    return uye, oturum, kayit


async def test_pencere_icinde_iptal_krediyi_iade_eder(db):
    uye, oturum, kayit = await _rezervasyonlu_senaryo(db)
    assert await bakiye(db, uye.id) == 7

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))

    assert sonuc.iade_edildi is True
    assert sonuc.bosalan_yer is True
    assert await bakiye(db, uye.id) == 8

    await db.refresh(oturum)
    assert oturum.dolu_sayi == 0


async def test_gec_iptal_krediyi_yakar_ama_yeri_bosaltir(db):
    uye, oturum, kayit = await _rezervasyonlu_senaryo(db)

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=2))

    assert sonuc.iade_edildi is False
    assert sonuc.bosalan_yer is True
    assert await bakiye(db, uye.id) == 7  # kredi yandı

    await db.refresh(oturum)
    # Yer yine de boşalır — üye gelmeyecekse o yer başkasına açılmalı
    assert oturum.dolu_sayi == 0


async def test_tam_sinirda_iptal_hakki_vardir(db):
    """now == son_iptal_ani -> iade edilir. Sınır kullanıcı lehine."""
    uye, _, kayit = await _rezervasyonlu_senaryo(db, iptal_penceresi_saat=6)

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=6))

    assert sonuc.iade_edildi is True
    assert await bakiye(db, uye.id) == 8


async def test_sinirdan_bir_saniye_sonra_gec_iptaldir(db):
    uye, _, kayit = await _rezervasyonlu_senaryo(db, iptal_penceresi_saat=6)

    sonuc = await iptal_et(
        db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=6) + timedelta(seconds=1)
    )

    assert sonuc.iade_edildi is False
    assert await bakiye(db, uye.id) == 7


async def test_iptal_penceresi_ders_tipine_gore_degisir(db):
    """Birebir dersin penceresi 24 saat olabilir."""
    uye, _, kayit = await _rezervasyonlu_senaryo(db, iptal_penceresi_saat=24)

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))

    assert sonuc.iade_edildi is False  # 8 saat kala, 24 saatlik pencerede geç
    assert await bakiye(db, uye.id) == 7


async def test_ayni_rezervasyon_iki_kez_iptal_edilemez(db):
    _, _, kayit = await _rezervasyonlu_senaryo(db)
    await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))

    with pytest.raises(ZatenIptal):
        await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))


async def test_iptal_ledgerda_iz_birakir(db):
    from app.models import CreditLedger

    uye, _, kayit = await _rezervasyonlu_senaryo(db)
    await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=2))

    sonuc = await db.execute(
        select(CreditLedger).where(CreditLedger.member_id == uye.id)
        .order_by(CreditLedger.id)
    )
    tipler = [k.tip for k in sonuc.scalars()]
    assert tipler == [
        LedgerTipi.PURCHASE, LedgerTipi.BOOKING, LedgerTipi.LATE_CANCEL,
    ]


async def test_ayni_rezervasyon_ayni_anda_iki_kez_iptal_edilemez(temiz_db):
    """İki eşzamanlı iptal çağrısı kontenjanı iki kişilik boşaltmamalı.

    Durum değişikliği atomik UPDATE ile yapıldığı için yalnız biri geçer;
    diğeri ZatenIptal alır ve kontenjan yalnız 1 azalır.
    """
    async with temiz_db() as hazirlik:
        tip = ClassType(ad="Barre", kontenjan=8, sure_dk=50, iptal_penceresi_saat=6)
        egitmen = Instructor(ad="Deniz")
        salon = Room(ad="Stüdyo")
        paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
        selin = Member(telefon="+905316033080", ad="Selin")
        ece = Member(telefon="+905321112233", ad="Ece")
        hazirlik.add_all([tip, egitmen, salon, paket, selin, ece])
        await hazirlik.flush()

        oturum = ClassSession(
            baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
            room_id=salon.id, kontenjan=8,
        )
        hazirlik.add(oturum)
        await hazirlik.flush()

        for uye in (selin, ece):
            await paket_tanimla(
                hazirlik, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
            )

        selin_kayit = await rezerve_et(hazirlik, member_id=selin.id, session_id=oturum.id)
        await rezerve_et(hazirlik, member_id=ece.id, session_id=oturum.id)

        oturum_id, booking_id = oturum.id, selin_kayit.id
        await hazirlik.commit()

    async def dene() -> str:
        async with temiz_db() as oturum_db:
            try:
                await iptal_et(
                    oturum_db, booking_id=booking_id, now=DERS_ANI - timedelta(hours=8)
                )
                await oturum_db.commit()
                return "iptal_edildi"
            except ZatenIptal:
                await oturum_db.rollback()
                return "zaten_iptal"

    sonuclar = await asyncio.gather(dene(), dene())

    assert sorted(sonuclar) == ["iptal_edildi", "zaten_iptal"]

    async with temiz_db() as kontrol:
        guncel = await kontrol.get(ClassSession, oturum_id)
        assert guncel.dolu_sayi == 1


async def test_dolu_sayi_ile_aktif_rezervasyon_sayisi_tutarli(db):
    """Rezervasyon ve iptal karışık yapıldıktan sonra sayaç gerçekle uyuşmalı.

    `dolu_sayi` denormalize bir sayaçtır; gerçeği `bookings` tablosudur.
    """
    tip = ClassType(ad="Barre", kontenjan=8, sure_dk=50, iptal_penceresi_saat=6)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    uye1 = Member(telefon="+905316033080", ad="Selin")
    uye2 = Member(telefon="+905321112233", ad="Ece")
    uye3 = Member(telefon="+905321112244", ad="Ada")
    db.add_all([tip, egitmen, salon, paket, uye1, uye2, uye3])
    await db.flush()

    oturum = ClassSession(
        baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=8,
    )
    db.add(oturum)
    await db.flush()

    for uye in (uye1, uye2, uye3):
        await paket_tanimla(
            db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
        )

    kayit1 = await rezerve_et(db, member_id=uye1.id, session_id=oturum.id)
    kayit2 = await rezerve_et(db, member_id=uye2.id, session_id=oturum.id)
    await rezerve_et(db, member_id=uye3.id, session_id=oturum.id)

    # uye1: pencere içinde iptal
    await iptal_et(db, booking_id=kayit1.id, now=DERS_ANI - timedelta(hours=8))
    # uye2: geç iptal
    await iptal_et(db, booking_id=kayit2.id, now=DERS_ANI - timedelta(hours=2))
    # uye3: rezervasyonu duruyor

    await db.refresh(oturum)

    sayim = await db.execute(
        select(Booking).where(
            Booking.session_id == oturum.id, Booking.durum == BookingDurumu.BOOKED
        )
    )
    aktif_rezervasyon_sayisi = len(list(sayim.scalars()))

    assert oturum.dolu_sayi == aktif_rezervasyon_sayisi
    assert oturum.dolu_sayi == 1
