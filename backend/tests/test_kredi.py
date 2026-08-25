from datetime import date

import pytest
from sqlalchemy.exc import IntegrityError

from app.models import LedgerTipi, Member, Package
from app.services.hatalar import GecersizHareket, KayitBulunamadi
from app.services.kredi import (
    aktif_paket_sec, bakiye, hareket_ekle, paket_tanimla,
)


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


async def test_bos_sebeple_ledger_satiri_yazilamaz(db):
    """B3: tasarım §5.2(b) sebebi zorunlu tutar.

    `String(200) NOT NULL` boş string'i geçirir. Satır append-only olduğu
    için sonradan düzeltilemez; sebepsiz bir ADMIN_ADJUST tarihçeyi
    okunamaz kılar.
    """
    uye, _ = await _uye_ve_paket(db)

    for gecersiz in ("", "   ", "\n\t"):
        with pytest.raises(GecersizHareket):
            await hareket_ekle(
                db, member_id=uye.id, tip=LedgerTipi.ADMIN_ADJUST,
                miktar=2, sebep=gecersiz,
            )

    assert await bakiye(db, uye.id) == 0


async def test_hayalet_booking_id_ile_ledger_satiri_yazilamaz(db):
    """B2: `booking_id` artık foreign key — olmayan rezervasyona iz yazılamaz."""
    uye, _ = await _uye_ve_paket(db)

    with pytest.raises(IntegrityError):
        await hareket_ekle(
            db, member_id=uye.id, tip=LedgerTipi.BOOKING, miktar=-1,
            sebep="hayalet", booking_id=999999,
        )


async def test_aktif_paket_sec_en_erken_biteni_secer(db):
    """A2: üyenin lehine — yanma riski en yüksek paket önce tüketilir."""
    uye, uzun = await _uye_ve_paket(db)
    kisa = Package(ad="4 Ders", ders_adedi=4, gecerlilik_gun=10, fiyat_kurus=240000)
    db.add(kisa)
    await db.flush()

    await paket_tanimla(db, member_id=uye.id, package_id=uzun.id, baslangic=date(2026, 9, 1))
    kisa_paket = await paket_tanimla(
        db, member_id=uye.id, package_id=kisa.id, baslangic=date(2026, 9, 1)
    )

    secilen = await aktif_paket_sec(db, member_id=uye.id, bugun=date(2026, 9, 5))

    assert secilen is not None
    assert secilen.id == kisa_paket.id


async def test_aktif_paket_sec_bitis_gununde_paketi_secmez(db):
    """D2: `bitis` GEÇERSİZ OLDUĞU İLK GÜNDÜR, son geçerli gün değil.

    1 Eylül'de açılan 60 günlük paketin son geçerli günü 30 Ekim,
    `bitis` değeri 31 Ekim'dir. `>= bitis` yazmak pakete bir gün fazladan
    ömür verirdi.
    """
    uye, paket = await _uye_ve_paket(db)
    uye_paketi = await paket_tanimla(
        db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
    )
    assert uye_paketi.bitis == date(2026, 10, 31)

    son_gecerli = await aktif_paket_sec(db, member_id=uye.id, bugun=date(2026, 10, 30))
    assert son_gecerli is not None and son_gecerli.id == uye_paketi.id

    assert await aktif_paket_sec(db, member_id=uye.id, bugun=date(2026, 10, 31)) is None
    # Başlangıç günü dahildir.
    assert await aktif_paket_sec(db, member_id=uye.id, bugun=date(2026, 8, 31)) is None
    baslangic_gunu = await aktif_paket_sec(
        db, member_id=uye.id, bugun=date(2026, 9, 1)
    )
    assert baslangic_gunu is not None and baslangic_gunu.id == uye_paketi.id


async def test_bulunmayan_paket_domain_hatasi_verir(db):
    """B1: `ValueError` değil `SoboHata`."""
    uye, _ = await _uye_ve_paket(db)

    with pytest.raises(KayitBulunamadi):
        await paket_tanimla(
            db, member_id=uye.id, package_id=999999, baslangic=date(2026, 9, 1)
        )
