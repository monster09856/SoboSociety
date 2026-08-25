import asyncio
from datetime import UTC, date, datetime

import pytest
from sqlalchemy import select

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, Instructor,
    Member, Package, Room, SessionDurumu,
)
from app.services.hatalar import (
    DersDolu, DersIptalEdilmis, YetersizKredi, ZatenRezerve,
)
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et


async def _senaryo(db, *, kontenjan: int = 2, kredi_ver: bool = True):
    uye = Member(telefon="+905316033080", ad="Selin")
    tip = ClassType(ad="Barre", kontenjan=kontenjan, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    db.add_all([uye, tip, egitmen, salon, paket])
    await db.flush()

    oturum = ClassSession(
        baslangic=datetime(2026, 9, 1, 16, 0, tzinfo=UTC),
        class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=kontenjan,
    )
    db.add(oturum)
    await db.flush()

    if kredi_ver:
        await paket_tanimla(
            db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
        )
    return uye, oturum, paket


async def test_rezervasyon_dolu_sayiyi_artirir_ve_kredi_duser(db):
    uye, oturum, _ = await _senaryo(db)

    kayit = await rezerve_et(db, member_id=uye.id, session_id=oturum.id)

    await db.refresh(oturum)
    assert kayit.durum == BookingDurumu.BOOKED
    assert oturum.dolu_sayi == 1
    assert await bakiye(db, uye.id) == 7


async def test_kontenjan_dolunca_rezervasyon_reddedilir(db):
    uye, oturum, paket = await _senaryo(db, kontenjan=1)

    await rezerve_et(db, member_id=uye.id, session_id=oturum.id)

    baskasi = Member(telefon="+905321112233", ad="Ece")
    db.add(baskasi)
    await db.flush()
    await paket_tanimla(db, member_id=baskasi.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    with pytest.raises(DersDolu):
        await rezerve_et(db, member_id=baskasi.id, session_id=oturum.id)


async def test_kredisi_olmayan_uye_rezervasyon_yapamaz(db):
    uye, oturum, _ = await _senaryo(db, kredi_ver=False)

    with pytest.raises(YetersizKredi):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id)

    await db.refresh(oturum)
    # Kredi kontrolü kontenjan artışından ÖNCE olmalı — reddedilen istek
    # kontenjandan yer çalmamalı
    assert oturum.dolu_sayi == 0


async def test_ayni_derse_iki_kez_rezervasyon_yapilamaz(db):
    uye, oturum, _ = await _senaryo(db)

    await rezerve_et(db, member_id=uye.id, session_id=oturum.id)

    with pytest.raises(ZatenRezerve):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id)


async def test_iptal_edilmis_derse_rezervasyon_yapilamaz(db):
    uye, oturum, _ = await _senaryo(db)
    oturum.durum = SessionDurumu.IPTAL
    await db.flush()

    with pytest.raises(DersIptalEdilmis):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id)


async def test_son_yere_ayni_anda_basan_iki_uyeden_yalniz_biri_kazanir(temiz_db):
    """Kontenjan yarışının gerçek sınaması.

    İki ayrı veritabanı bağlantısı son yer için aynı anda yarışır.
    PostgreSQL READ COMMITTED'da ikinci UPDATE birincinin satır kilidini
    bekler ve commit sonrası WHERE koşulunu YENİDEN değerlendirir; bu yüzden
    son yer iki kez satılamaz.
    """
    async with temiz_db() as hazirlik:
        tip = ClassType(ad="Barre", kontenjan=1, sure_dk=50)
        egitmen = Instructor(ad="Deniz")
        salon = Room(ad="Stüdyo")
        paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
        selin = Member(telefon="+905316033080", ad="Selin")
        ece = Member(telefon="+905321112233", ad="Ece")
        hazirlik.add_all([tip, egitmen, salon, paket, selin, ece])
        await hazirlik.flush()

        oturum = ClassSession(
            baslangic=datetime(2026, 9, 1, 16, 0, tzinfo=UTC),
            class_type_id=tip.id, instructor_id=egitmen.id,
            room_id=salon.id, kontenjan=1,
        )
        hazirlik.add(oturum)
        await hazirlik.flush()

        for uye in (selin, ece):
            await paket_tanimla(
                hazirlik, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
            )

        oturum_id, selin_id, ece_id = oturum.id, selin.id, ece.id
        await hazirlik.commit()

    async def dene(member_id: int) -> str:
        async with temiz_db() as oturum_db:
            try:
                await rezerve_et(oturum_db, member_id=member_id, session_id=oturum_id)
                await oturum_db.commit()
                return "kazandi"
            except DersDolu:
                await oturum_db.rollback()
                return "doldu"

    sonuclar = await asyncio.gather(dene(selin_id), dene(ece_id))

    assert sorted(sonuclar) == ["doldu", "kazandi"]

    async with temiz_db() as kontrol:
        guncel = await kontrol.get(ClassSession, oturum_id)
        assert guncel.dolu_sayi == 1

        kayitlar = await kontrol.execute(
            select(Booking).where(Booking.session_id == oturum_id)
        )
        assert len(list(kayitlar.scalars())) == 1
