# tests/test_program_uretimi.py
from datetime import UTC, date, datetime

from sqlalchemy import func, select

from app.models import ClassSession, ClassType, Instructor, Room, ScheduleTemplate
from app.services.program_uretimi import uret


async def _sablon_kur(db, *, hafta_gunu: int, saat_dk: int, gecerli_bitis: date | None = None):
    tip = ClassType(ad="Barre", kontenjan=8, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    db.add_all([tip, egitmen, salon])
    await db.flush()

    sablon = ScheduleTemplate(
        hafta_gunu=hafta_gunu,
        saat_dk=saat_dk,
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        gecerli_baslangic=date(2026, 9, 1),
        gecerli_bitis=gecerli_bitis,
    )
    db.add(sablon)
    await db.flush()
    return sablon


async def _oturumlar(db) -> list[ClassSession]:
    sonuc = await db.execute(select(ClassSession).order_by(ClassSession.baslangic))
    return list(sonuc.scalars())


async def test_haftalik_sablon_dogru_gunlerde_oturum_uretir(db):
    # 1 Eylül 2026 Salı. hafta_gunu=1 -> Salı
    await _sablon_kur(db, hafta_gunu=1, saat_dk=19 * 60)

    sayi = await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 21))

    assert sayi == 3
    tarihler = [o.baslangic.astimezone(UTC).date() for o in await _oturumlar(db)]
    assert tarihler == [date(2026, 9, 1), date(2026, 9, 8), date(2026, 9, 15)]


async def test_yerel_saat_utc_ye_cevrilir(db):
    """Şablon 19:00 yerel saat der; Europe/Istanbul UTC+3, yani 16:00 UTC."""
    await _sablon_kur(db, hafta_gunu=1, saat_dk=19 * 60)

    await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 2))

    oturum = (await _oturumlar(db))[0]
    assert oturum.baslangic.astimezone(UTC) == datetime(2026, 9, 1, 16, 0, tzinfo=UTC)


async def test_iki_kez_calistirmak_cift_oturum_uretmez(db):
    await _sablon_kur(db, hafta_gunu=1, saat_dk=19 * 60)

    ilk = await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 21))
    ikinci = await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 21))

    assert ilk == 3
    assert ikinci == 0

    toplam = await db.execute(select(func.count()).select_from(ClassSession))
    assert toplam.scalar_one() == 3


async def test_gecerlilik_bitisinden_sonra_uretilmez(db):
    await _sablon_kur(
        db, hafta_gunu=1, saat_dk=19 * 60, gecerli_bitis=date(2026, 9, 8)
    )

    sayi = await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 21))

    assert sayi == 2  # 1 ve 8 Eylül; 15 Eylül geçerlilik dışında


async def test_kontenjan_ders_tipinden_kopyalanir(db):
    await _sablon_kur(db, hafta_gunu=1, saat_dk=19 * 60)

    await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 2))

    oturum = (await _oturumlar(db))[0]
    assert oturum.kontenjan == 8
    assert oturum.dolu_sayi == 0


async def test_pasif_ders_tipi_icin_oturum_uretilmez(db):
    sablon = await _sablon_kur(db, hafta_gunu=1, saat_dk=19 * 60)

    tip = await db.get(ClassType, sablon.class_type_id)
    tip.aktif = False
    await db.flush()

    sayi = await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 21))

    assert sayi == 0
    assert await _oturumlar(db) == []


async def test_yerel_gece_yarisi_utc_de_onceki_gune_duser(db):
    """Salı 00:00 yerel = Pazartesi 21:00 UTC. Bu doğru davranıştır.

    Gün döngüsü `weekday()`'i YEREL takvim günü olarak karşılaştırır; şablon
    "Salı" der ve yerel Salı gecesi üretilir. UTC gösteriminin bir gün geride
    olması TZ dönüşümünün doğal sonucudur, hata değildir.
    """
    await _sablon_kur(db, hafta_gunu=1, saat_dk=0)

    await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 2))

    oturum = (await _oturumlar(db))[0]
    assert oturum.baslangic.astimezone(UTC) == datetime(2026, 8, 31, 21, 0, tzinfo=UTC)
