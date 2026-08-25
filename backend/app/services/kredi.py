from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import CreditLedger, LedgerTipi, MemberPackage, Package


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
    """
    paket = await db.get(Package, package_id)
    if paket is None:
        raise ValueError(f"Paket bulunamadı: {package_id}")

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
