import asyncio
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select, text

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, CreditLedger,
    Instructor, LedgerTipi, Member, Package, Room,
)
from app.services.hatalar import DersBaslamamis
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et
from app.services.yoklama import yoklama_al

DERS_ANI = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)
# Rezervasyon/sıra anı dersten önce olmalı; başlamış derse kayıt alınmaz.
REZERVASYON_ANI = DERS_ANI - timedelta(hours=8)
DERS_SONRASI = DERS_ANI + timedelta(hours=1)


async def _iki_kayitli_ders(db):
    tip = ClassType(ad="Barre", kontenjan=8, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    selin = Member(telefon="+905316033080", ad="Selin")
    ece = Member(telefon="+905321112233", ad="Ece")
    db.add_all([tip, egitmen, salon, paket, selin, ece])
    await db.flush()

    oturum = ClassSession(
        baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=8,
    )
    db.add(oturum)
    await db.flush()

    for uye in (selin, ece):
        await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI)

    return oturum, selin, ece


async def test_gelenler_attended_gelmeyenler_no_show_olur(db):
    oturum, selin, ece = await _iki_kayitli_ders(db)

    sonuc = await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI
    )

    assert (sonuc.gelen, sonuc.gelmeyen) == (1, 1)

    kayitlar = await db.execute(
        select(Booking).where(Booking.session_id == oturum.id).order_by(Booking.id)
    )
    durumlar = {k.member_id: k.durum for k in kayitlar.scalars()}
    assert durumlar[selin.id] == BookingDurumu.ATTENDED
    assert durumlar[ece.id] == BookingDurumu.NO_SHOW


async def test_no_show_krediyi_yakar_gelen_etkilenmez(db):
    oturum, selin, ece = await _iki_kayitli_ders(db)
    assert await bakiye(db, selin.id) == 7
    assert await bakiye(db, ece.id) == 7

    await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI
    )

    # İkisinin de bakiyesi 7 — rezervasyonda zaten düşmüştü, no-show iade etmez
    assert await bakiye(db, selin.id) == 7
    assert await bakiye(db, ece.id) == 7

    # Ama gelmeyen için ledger'da iz var
    izler = await db.execute(
        select(CreditLedger).where(
            CreditLedger.member_id == ece.id,
            CreditLedger.tip == LedgerTipi.NO_SHOW,
        )
    )
    iz = izler.scalar_one()
    assert iz.miktar == 0


async def test_no_show_kontenjani_geri_vermez(db):
    """Ders geçmiştir; o yerin başkasına satılması diye bir şey yok."""
    oturum, selin, _ = await _iki_kayitli_ders(db)

    await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI
    )

    await db.refresh(oturum)
    assert oturum.dolu_sayi == 2


async def test_iptal_edilmis_rezervasyon_yoklamaya_girmez(db):
    from datetime import timedelta as td

    from app.services.iptal import iptal_et

    oturum, selin, ece = await _iki_kayitli_ders(db)
    kayitlar = await db.execute(
        select(Booking).where(Booking.member_id == ece.id)
    )
    await iptal_et(
        db, booking_id=kayitlar.scalar_one().id, now=DERS_ANI - td(hours=14)
    )

    sonuc = await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI
    )

    assert (sonuc.gelen, sonuc.gelmeyen) == (1, 0)


async def test_yoklama_iki_kez_alinirsa_ikinci_kez_kredi_yakmaz(db):
    """İdempotanlık: eğitmen kaydet'e iki kez basarsa ceza iki kez yazılmamalı."""
    oturum, selin, ece = await _iki_kayitli_ders(db)

    await yoklama_al(db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI)
    sonuc = await yoklama_al(db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI)

    assert (sonuc.gelen, sonuc.gelmeyen) == (0, 0)

    izler = await db.execute(
        select(CreditLedger).where(
            CreditLedger.member_id == ece.id,
            CreditLedger.tip == LedgerTipi.NO_SHOW,
        )
    )
    assert len(list(izler.scalars())) == 1


async def test_ayni_anda_iki_kez_yoklama_alinirsa_ceza_bir_kez_yazilir(temiz_db):
    """Eğitmen 'kaydet'e çift tıklarsa no-show cezası iki kez yazılmamalı.

    İdempotanlık atomik UPDATE'in `durum = 'booked'` koşulundan gelir.
    """
    async with temiz_db() as hazirlik:
        tip = ClassType(ad="Barre", kontenjan=8, sure_dk=50)
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
            await rezerve_et(hazirlik, member_id=uye.id, session_id=oturum.id, now=REZERVASYON_ANI)

        oturum_id, selin_id, ece_id = oturum.id, selin.id, ece.id
        await hazirlik.commit()

    kapi = asyncio.Barrier(2)

    async def dene():
        async with temiz_db() as oturum_db:
            # Yarışı gerçekten kurabilmek için bağlantıyı önceden ısıtmak VE
            # iki görevi tam aynı anda serbest bırakmak gerekiyor. Yalnız
            # biri yapılırsa görevler kayar ve çakışma penceresi kapanır —
            # test kilit silinse bile yeşil kalır.
            await oturum_db.execute(text("SELECT 1"))
            async with asyncio.timeout(10):
                await kapi.wait()
            sonuc = await yoklama_al(
                oturum_db, session_id=oturum_id, gelen_member_ids={selin_id},
                now=DERS_SONRASI,
            )
            await oturum_db.commit()
            return sonuc

    sonuc1, sonuc2 = await asyncio.gather(dene(), dene())

    toplam_gelen = sonuc1.gelen + sonuc2.gelen
    toplam_gelmeyen = sonuc1.gelmeyen + sonuc2.gelmeyen
    assert (toplam_gelen, toplam_gelmeyen) == (1, 1)
    assert {(sonuc1.gelen, sonuc1.gelmeyen), (sonuc2.gelen, sonuc2.gelmeyen)} == {(1, 1), (0, 0)}

    async with temiz_db() as kontrol:
        izler = await kontrol.execute(
            select(CreditLedger).where(
                CreditLedger.member_id == ece_id,
                CreditLedger.tip == LedgerTipi.NO_SHOW,
            )
        )
        assert len(list(izler.scalars())) == 1


async def test_kimse_gelmediyse_hepsi_no_show_olur(db):
    """gelen_member_ids boş küme olduğunda tüm kayıtlar no_show olmalı."""
    oturum, selin, ece = await _iki_kayitli_ders(db)

    sonuc = await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids=set(), now=DERS_SONRASI
    )

    assert (sonuc.gelen, sonuc.gelmeyen) == (0, 2)

    kayitlar = await db.execute(
        select(Booking).where(Booking.session_id == oturum.id).order_by(Booking.id)
    )
    durumlar = {k.member_id: k.durum for k in kayitlar.scalars()}
    assert durumlar[selin.id] == BookingDurumu.NO_SHOW
    assert durumlar[ece.id] == BookingDurumu.NO_SHOW

    izler = await db.execute(
        select(CreditLedger).where(CreditLedger.tip == LedgerTipi.NO_SHOW)
    )
    assert len(list(izler.scalars())) == 2


async def test_ders_baslamadan_yoklama_alinamaz(db):
    """D1: yanlış karta basmak KALICI hasar demekti.

    Ders başlamadan günler önce yoklama alınıp herkes `no_show`
    yapılabiliyordu ve geri alma yolu yok: `iptal_et` `ZatenIptal`
    fırlatır, ledger append-only.
    """
    oturum, selin, ece = await _iki_kayitli_ders(db)

    with pytest.raises(DersBaslamamis):
        await yoklama_al(
            db, session_id=oturum.id, gelen_member_ids={selin.id},
            now=DERS_ANI - timedelta(days=30),
        )

    kayitlar = await db.execute(
        select(Booking).where(Booking.session_id == oturum.id)
    )
    assert all(k.durum == BookingDurumu.BOOKED for k in kayitlar.scalars())


async def test_tam_ders_aninda_yoklama_alinabilir(db):
    """Sınır: `now == baslangic` anında ders başlamıştır."""
    oturum, selin, _ = await _iki_kayitli_ders(db)

    sonuc = await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_ANI
    )

    assert (sonuc.gelen, sonuc.gelmeyen) == (1, 1)


async def test_no_show_satiri_kredinin_dusuldugu_pakete_yazilir(db):
    """A2: ceza satırı yeni paket seçimiyle değil, orijinal paketle yazılır."""
    oturum, selin, ece = await _iki_kayitli_ders(db)

    ece_booking = (
        await db.execute(select(Booking).where(Booking.member_id == ece.id))
    ).scalar_one()
    booking_satiri = (
        await db.execute(
            select(CreditLedger).where(
                CreditLedger.booking_id == ece_booking.id,
                CreditLedger.tip == LedgerTipi.BOOKING,
            )
        )
    ).scalar_one()
    assert booking_satiri.member_package_id is not None

    # Tuzak: daha erken biten yeni paket — yeniden seçim yapılsaydı bu gelirdi.
    kisa_paket = Package(
        ad="2 Ders", ders_adedi=2, gecerlilik_gun=10, fiyat_kurus=120000
    )
    db.add(kisa_paket)
    await db.flush()
    yeni_paket = await paket_tanimla(
        db, member_id=ece.id, package_id=kisa_paket.id, baslangic=date(2026, 9, 1)
    )

    await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI
    )

    ceza = (
        await db.execute(
            select(CreditLedger).where(
                CreditLedger.booking_id == ece_booking.id,
                CreditLedger.tip == LedgerTipi.NO_SHOW,
            )
        )
    ).scalar_one()

    assert ceza.member_package_id == booking_satiri.member_package_id
    assert ceza.member_package_id != yeni_paket.id
