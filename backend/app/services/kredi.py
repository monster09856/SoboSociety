from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import CreditLedger, LedgerTipi, MemberPackage, Package
from app.services.hatalar import GecersizHareket, KayitBulunamadi


async def bakiye(db: AsyncSession, member_id: int) -> int:
    """Üyenin kalan ders kredisi.

    Her zaman ledger'dan hesaplanır, hiçbir yerde sayaç tutulmaz. Sayaç ile
    tarihçe ayrışabilir; ayrıştığında hangisinin doğru olduğunu kimse bilemez.
    """
    sonuc = await db.execute(
        select(func.coalesce(func.sum(CreditLedger.miktar), 0)).where(
            CreditLedger.member_id == member_id
        )
    )
    return int(sonuc.scalar_one())


async def aktif_paket_sec(
    db: AsyncSession, *, member_id: int, bugun: date
) -> MemberPackage | None:
    """Krediyi düşmek için kullanılacak paketi seçer.

    Kural: geçerlilik süresi devam eden paketler arasından **en erken biten**
    seçilir. Sebebi üyenin lehine: süresi dolmak üzere olan paket önce
    tüketilirse yanma riski azalır.

    Ledger satırlarının hangi pakete ait olduğu yazılmazsa "bu paketten kaç
    ders kaldı" sorusu sonradan cevaplanamaz — ve geçmiş satırların atfı
    geriye dönük kurtarılamaz.

    `bitis` "geçersiz olduğu İLK gün"dür (bkz. `MemberPackage.bitis`), bu
    yüzden karşılaştırma `>= bugun` değil `> bugun` olmalıdır: `bitis`
    gününde paket artık geçerli değildir.
    """
    sonuc = await db.execute(
        select(MemberPackage)
        .where(
            MemberPackage.member_id == member_id,
            MemberPackage.baslangic <= bugun,
            MemberPackage.bitis > bugun,
        )
        .order_by(MemberPackage.bitis)
        .limit(1)
    )
    return sonuc.scalar_one_or_none()


async def hareket_ekle(
    db: AsyncSession,
    *,
    member_id: int,
    tip: LedgerTipi,
    miktar: int,
    sebep: str,
    member_package_id: int | None = None,
    booking_id: int | None = None,
) -> CreditLedger:
    """Ledger'a bir satır yazar. Satırlar asla güncellenmez veya silinmez."""
    # Sebep zorunlu (tasarım §5.2(b)). `String(200) NOT NULL` boş string'i
    # geçirir; boş sebeple yazılmış bir ADMIN_ADJUST satırı tarihçeyi
    # okunamaz kılar — ve satır append-only olduğu için sonradan
    # düzeltilemez, yalnız üzerine yeni satır yazılabilir.
    if not sebep or not sebep.strip():
        raise GecersizHareket("Ledger satırı için sebep zorunludur")

    kayit = CreditLedger(
        member_id=member_id,
        member_package_id=member_package_id,
        tip=tip,
        miktar=miktar,
        sebep=sebep,
        booking_id=booking_id,
    )
    db.add(kayit)
    await db.flush()
    return kayit


async def paket_tanimla(
    db: AsyncSession, *, member_id: int, package_id: int, baslangic: date
) -> MemberPackage:
    """Üyeye paket açar ve karşılığında PURCHASE satırını yazar.

    İkisi tek işlemde olmalı: paket açılıp kredi yazılmazsa üye parasını
    ödemiş ama ders hakkı görünmeyen bir hesapla kalır.

    `bitis` hesabı `baslangic + gecerlilik_gun` gündür ve bu tarih paketin
    **geçersiz olduğu İLK gündür**, son geçerli gün DEĞİLDİR. 60 günlük bir
    paket 1 Eylül'de açılırsa son geçerli gün 30 Ekim, `bitis` ise 31
    Ekim'dir. Geçerlilik kontrolü bu yüzden `baslangic <= gun < bitis`
    yarı-açık aralığıdır.
    """
    paket = await db.get(Package, package_id)
    if paket is None:
        raise KayitBulunamadi(f"Paket bulunamadı: {package_id}")

    uye_paketi = MemberPackage(
        member_id=member_id,
        package_id=package_id,
        baslangic=baslangic,
        bitis=baslangic + timedelta(days=paket.gecerlilik_gun),
    )
    db.add(uye_paketi)
    await db.flush()

    await hareket_ekle(
        db,
        member_id=member_id,
        tip=LedgerTipi.PURCHASE,
        miktar=paket.ders_adedi,
        sebep=f"{paket.ad} paketi tanımlandı",
        member_package_id=uye_paketi.id,
    )
    return uye_paketi
