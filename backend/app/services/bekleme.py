from datetime import datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Booking, BookingKaynagi, ClassSession, WaitlistEntry
from app.services.hatalar import (
    DersDoluDegil, TeklifSuresiDolmus, ZatenSirada,
)
from app.services.rezervasyon import rezerve_et

TEKLIF_SURESI_DK = 20


async def siraya_gir(
    db: AsyncSession, *, member_id: int, session_id: int
) -> WaitlistEntry:
    """Dolu bir derse bekleme sırası kaydı açar."""
    # Ders satırını kilitle. Bu kilit İKİ işi birden yapıyor:
    #
    # 1. Kontenjanı TAZE okur. ORM nesnesinden okumak yanlış olurdu:
    #    `rezerve_et` kontenjanı atomik UPDATE ile artırır ve identity
    #    map'teki ClassSession nesnesi bunu görmez, `dolu_sayi` bayat kalır.
    # 2. Sıra numarası üretimini serileştirir. `MAX(sira) + 1` kilitsiz
    #    olsaydı iki üye aynı anda sıraya girip aynı numarayı alırdı ve
    #    yer açıldığında yanlış kişiye teklif giderdi.
    #
    # Kilit sırası güvenli: bu fonksiyon yalnız class_sessions kilitler,
    # başka kaynağa gitmez, dolayısıyla members -> class_sessions sırasını
    # izleyen `rezerve_et` ile döngü kuramaz.
    sonuc = await db.execute(
        select(ClassSession.dolu_sayi, ClassSession.kontenjan)
        .where(ClassSession.id == session_id)
        .with_for_update()
    )
    satir = sonuc.one_or_none()
    if satir is None:
        raise ValueError(f"Ders bulunamadı: {session_id}")
    dolu_sayi, kontenjan = satir
    if dolu_sayi < kontenjan:
        raise DersDoluDegil("Derste yer var, doğrudan rezervasyon yapılabilir")

    mevcut = await db.execute(
        select(WaitlistEntry).where(
            WaitlistEntry.member_id == member_id,
            WaitlistEntry.session_id == session_id,
        )
    )
    if mevcut.scalar_one_or_none() is not None:
        raise ZatenSirada("Bu dersin bekleme listesindesin")

    sonuc = await db.execute(
        select(func.coalesce(func.max(WaitlistEntry.sira), 0)).where(
            WaitlistEntry.session_id == session_id
        )
    )
    kayit = WaitlistEntry(
        member_id=member_id,
        session_id=session_id,
        sira=int(sonuc.scalar_one()) + 1,
    )
    db.add(kayit)
    await db.flush()
    return kayit


async def sirayi_ilerlet(
    db: AsyncSession, *, session_id: int, now: datetime
) -> WaitlistEntry | None:
    """Sıradaki uygun üyeye teklif açar. Sıra boşsa None döner.

    Teklif süresi `min(20 dk, derse kalan süre)`: ders 10 dakika sonra
    başlıyorsa 20 dakika beklemek yeri tamamen boşa harcar.
    """
    oturum = await db.get(ClassSession, session_id)
    if oturum is None:
        raise ValueError(f"Ders bulunamadı: {session_id}")

    sonuc = await db.execute(
        select(WaitlistEntry)
        .where(
            WaitlistEntry.session_id == session_id,
            WaitlistEntry.kullanildi.is_(False),
        )
        .order_by(WaitlistEntry.sira)
    )
    for kayit in sonuc.scalars():
        # Süresi dolmuş teklifleri atla — bunlar sırayı kaybetmiştir
        if kayit.teklif_bitis is not None and kayit.teklif_bitis <= now:
            continue
        if kayit.teklif_bitis is not None:
            return kayit  # hâlâ açık bir teklif var, yenisini verme

        kayit.teklif_bitis = min(
            now + timedelta(minutes=TEKLIF_SURESI_DK), oturum.baslangic
        )
        await db.flush()
        return kayit

    return None


async def teklifi_kullan(
    db: AsyncSession, *, entry_id: int, now: datetime
) -> Booking:
    """Bekleme listesi teklifini rezervasyona çevirir."""
    kayit = await db.get(WaitlistEntry, entry_id)
    if kayit is None:
        raise ValueError(f"Bekleme kaydı bulunamadı: {entry_id}")
    if kayit.teklif_bitis is None:
        raise TeklifSuresiDolmus("Bu kayda henüz teklif açılmadı")
    if now > kayit.teklif_bitis:
        raise TeklifSuresiDolmus("Teklif süresi doldu")

    rezervasyon = await rezerve_et(
        db,
        member_id=kayit.member_id,
        session_id=kayit.session_id,
        kaynak=BookingKaynagi.APP,
    )
    kayit.kullanildi = True
    await db.flush()
    return rezervasyon
