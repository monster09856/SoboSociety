from datetime import date

from app.models import LedgerTipi, Member, Package
from app.services.kredi import bakiye, hareket_ekle, paket_tanimla


async def _uye_ve_paket(db):
    uye = Member(telefon="+905316033080", ad="Selin")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    db.add_all([uye, paket])
    await db.flush()
    return uye, paket


async def test_hareketi_olmayan_uyenin_bakiyesi_sifir(db):
    uye, _ = await _uye_ve_paket(db)
    assert await bakiye(db, uye.id) == 0


async def test_paket_tanimlamak_bakiyeyi_ders_adedi_kadar_artirir(db):
    uye, paket = await _uye_ve_paket(db)

    uye_paketi = await paket_tanimla(
        db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
    )

    assert await bakiye(db, uye.id) == 8
    assert uye_paketi.bitis == date(2026, 10, 31)  # 1 Eylül + 60 gün


async def test_rezervasyon_ve_iade_bakiyede_dengelenir(db):
    uye, paket = await _uye_ve_paket(db)
    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    await hareket_ekle(db, member_id=uye.id, tip=LedgerTipi.BOOKING, miktar=-1, sebep="Barre 09:30")
    assert await bakiye(db, uye.id) == 7

    await hareket_ekle(db, member_id=uye.id, tip=LedgerTipi.CANCEL_REFUND, miktar=1, sebep="Pencerede iptal")
    assert await bakiye(db, uye.id) == 8


async def test_gec_iptal_bakiyeyi_degistirmez_ama_iz_birakir(db):
    uye, paket = await _uye_ve_paket(db)
    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))
    await hareket_ekle(db, member_id=uye.id, tip=LedgerTipi.BOOKING, miktar=-1, sebep="Barre 09:30")

    kayit = await hareket_ekle(
        db, member_id=uye.id, tip=LedgerTipi.LATE_CANCEL, miktar=0,
        sebep="Ders saatine 2 saat kala iptal",
    )

    assert await bakiye(db, uye.id) == 7  # kredi yandı, geri gelmedi
    assert kayit.tip == LedgerTipi.LATE_CANCEL
    assert kayit.miktar == 0


async def test_admin_duzeltmesi_bakiyeyi_degistirir(db):
    uye, paket = await _uye_ve_paket(db)
    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    await hareket_ekle(
        db, member_id=uye.id, tip=LedgerTipi.ADMIN_ADJUST, miktar=2,
        sebep="Eğitmen hastalandı, iki ders iade edildi",
    )

    assert await bakiye(db, uye.id) == 10


async def test_bakiye_baska_uyenin_hareketlerini_saymaz(db):
    uye, paket = await _uye_ve_paket(db)
    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    baskasi = Member(telefon="+905321112233", ad="Ece")
    db.add(baskasi)
    await db.flush()

    assert await bakiye(db, baskasi.id) == 0
