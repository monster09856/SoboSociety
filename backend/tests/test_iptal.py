import asyncio
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, CreditLedger,
    Instructor, LedgerTipi, Member, Package, Room,
)
from app.services.hatalar import GecIptalEngellendi, KayitBulunamadi, ZatenIptal
from app.services.iptal import iptal_et
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et

DERS_ANI = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)
# Rezervasyon/sıra anı dersten önce olmalı; başlamış derse kayıt alınmaz.
REZERVASYON_ANI = DERS_ANI - timedelta(hours=14)


async def _rezervasyonlu_senaryo(db, *, iptal_penceresi_saat: int = 12):
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
    kayit = await rezerve_et(db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI)
    return uye, oturum, kayit


async def test_pencere_icinde_iptal_krediyi_iade_eder(db):
    uye, oturum, kayit = await _rezervasyonlu_senaryo(db)
    assert await bakiye(db, uye.id) == 7

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=14))

    assert sonuc.iade_edildi is True
    assert sonuc.bosalan_yer is True
    assert await bakiye(db, uye.id) == 8

    await db.refresh(oturum)
    assert oturum.dolu_sayi == 0


async def test_gec_iptal_engellenir_ve_hata_verir(db):
    uye, oturum, kayit = await _rezervasyonlu_senaryo(db)

    with pytest.raises(GecIptalEngellendi):
        await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=2))


async def test_tam_sinirda_iptal_hakki_vardir(db):
    """now == son_iptal_ani -> iade edilir. Sınır kullanıcı lehine."""
    uye, _, kayit = await _rezervasyonlu_senaryo(db, iptal_penceresi_saat=12)

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=12))

    assert sonuc.iade_edildi is True
    assert await bakiye(db, uye.id) == 8


async def test_sinirdan_bir_saniye_sonra_gec_iptaldir(db):
    uye, _, kayit = await _rezervasyonlu_senaryo(db, iptal_penceresi_saat=12)

    with pytest.raises(GecIptalEngellendi):
        await iptal_et(
            db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=12) + timedelta(seconds=1)
        )


async def test_iptal_penceresi_ders_tipine_gore_degisir(db):
    """Birebir dersin penceresi 24 saat olabilir."""
    uye, _, kayit = await _rezervasyonlu_senaryo(db, iptal_penceresi_saat=24)

    with pytest.raises(GecIptalEngellendi):
        await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))


async def test_olmayan_booking_iptal_edilemez(db):
    with pytest.raises(KayitBulunamadi):
        await iptal_et(db, booking_id=99999, now=DERS_ANI - timedelta(hours=14))


async def test_zaten_iptal_edilmis_booking_tekrar_iptal_edilemez(db):
    _, _, kayit = await _rezervasyonlu_senaryo(db)
    await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=14))

    with pytest.raises(ZatenIptal):
        await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=14))


async def test_dolu_sayi_ile_aktif_rezervasyon_sayisi_tutarli(db):
    uye1 = Member(telefon="+905316033081", ad="Ayşe")
    uye2 = Member(telefon="+905316033082", ad="Fatma")
    uye3 = Member(telefon="+905316033083", ad="Zeynep")
    tip = ClassType(ad="Reformer", kontenjan=8, sure_dk=50, iptal_penceresi_saat=12)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo 2")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    db.add_all([uye1, uye2, uye3, tip, egitmen, salon, paket])
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

    kayit1 = await rezerve_et(db, member_id=uye1.id, session_id=oturum.id, now=REZERVASYON_ANI)
    kayit2 = await rezerve_et(db, member_id=uye2.id, session_id=oturum.id, now=REZERVASYON_ANI)
    await rezerve_et(db, member_id=uye3.id, session_id=oturum.id, now=REZERVASYON_ANI)

    # uye1: pencere içinde iptal
    await iptal_et(db, booking_id=kayit1.id, now=DERS_ANI - timedelta(hours=14))
    # uye3: rezervasyonu duruyor

    await db.refresh(oturum)

    sayim = await db.execute(
        select(Booking).where(
            Booking.session_id == oturum.id, Booking.durum == BookingDurumu.BOOKED
        )
    )
    aktif_rezervasyon_sayisi = len(list(sayim.scalars()))

    assert oturum.dolu_sayi == aktif_rezervasyon_sayisi
    assert oturum.dolu_sayi == 2


async def test_iade_satiri_kredinin_dusuldugu_pakete_yazilir(db):
    uye, _, kayit = await _rezervasyonlu_senaryo(db)

    booking_satiri = (
        await db.execute(
            select(CreditLedger).where(
                CreditLedger.booking_id == kayit.id,
                CreditLedger.tip == LedgerTipi.BOOKING,
            )
        )
    ).scalar_one()
    assert booking_satiri.member_package_id is not None

    kisa_paket = Package(
        ad="2 Ders", ders_adedi=2, gecerlilik_gun=10, fiyat_kurus=120000
    )
    db.add(kisa_paket)
    await db.flush()
    yeni_paket = await paket_tanimla(
        db, member_id=uye.id, package_id=kisa_paket.id, baslangic=date(2026, 9, 1)
    )

    await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=14))

    iade = (
        await db.execute(
            select(CreditLedger).where(
                CreditLedger.booking_id == kayit.id,
                CreditLedger.tip == LedgerTipi.CANCEL_REFUND,
            )
        )
    ).scalar_one()

    assert iade.member_package_id == booking_satiri.member_package_id
    assert iade.member_package_id != yeni_paket.id
