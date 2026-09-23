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


async def bakiye_detay(db: AsyncSession, member_id: int) -> tuple[int, int, int]:
    """Üyenin toplam, grup ve bireysel ders bakiyesini döndürür: (toplam, grup, bireysel)."""
    tot = await bakiye(db, member_id)

    stmt = (
        select(MemberPackage, Package)
        .outerjoin(Package, MemberPackage.package_id == Package.id)
        .where(MemberPackage.member_id == member_id)
    )
    res = await db.execute(stmt)
    rows = res.all()

    grup = 0
    bireysel = 0
    assigned_total = 0

    for mp, p in rows:
        p_name = getattr(mp, "ozel_paket_adi", None) or (p.ad if p else "")
        is_b = any(k in p_name.lower() for k in ["bireysel", "özel", "birebir", "1-on-1"])

        l_res = await db.execute(
            select(func.coalesce(func.sum(CreditLedger.miktar), 0))
            .where(CreditLedger.member_package_id == mp.id)
        )
        rem = int(l_res.scalar_one() or 0)
        assigned_total += rem
        if is_b:
            bireysel += rem
        else:
            grup += rem

    # Pakete bağlanmamış doğrudan admin hareketleri varsa
    diff = tot - assigned_total
    if diff != 0:
        if bireysel > 0 and grup == 0:
            bireysel += diff
        else:
            grup += diff

    return tot, max(0, grup), max(0, bireysel)


async def aktif_paket_sec(
    db: AsyncSession, *, member_id: int, bugun: date, is_bireysel: bool | None = None
) -> MemberPackage | None:
    """Krediyi düşmek için kullanılacak paketi seçer.
    Eğer is_bireysel belirtilmişse ilgili kategoriye (Bireysel / Grup) ait paketi önceliklendirir.
    """
    stmt = (
        select(MemberPackage, Package)
        .outerjoin(Package, MemberPackage.package_id == Package.id)
        .where(
            MemberPackage.member_id == member_id,
            MemberPackage.baslangic <= bugun,
            MemberPackage.bitis > bugun,
        )
        .order_by(MemberPackage.bitis)
    )
    res = await db.execute(stmt)
    rows = res.all()
    if not rows:
        return None

    if is_bireysel is not None:
        for mp, p in rows:
            p_name = getattr(mp, "ozel_paket_adi", None) or (p.ad if p else "")
            is_pkg_bireysel = any(k in p_name.lower() for k in ["bireysel", "özel", "birebir", "1-on-1"])
            if is_pkg_bireysel == is_bireysel:
                return mp

    return rows[0][0]


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
