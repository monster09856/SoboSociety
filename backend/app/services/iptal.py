from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, CreditLedger,
    LedgerTipi, Member,
)
from app.services.hatalar import GecIptalEngellendi, KayitBulunamadi, ZatenIptal
from app.services.kredi import hareket_ekle


@dataclass(frozen=True)
class IptalSonucu:
    booking: Booking
    iade_edildi: bool
    bosalan_yer: bool


async def iptal_et(
    db: AsyncSession,
    *,
    booking_id: int,
    now: datetime,
    is_admin: bool = False,
) -> IptalSonucu:
    """Rezervasyonu iptal eder.

    Pencerede iptal (>= 12 saat): kredi iade edilir (CANCEL_REFUND, +1).
    Geç iptal (< 12 saat): Üye için ENGELLENİR (GecIptalEngellendi hatası döner).
    Yönetici (is_admin=True) ise her an iptal edebilir.
    """
    kayit = await db.get(Booking, booking_id)
    if kayit is None:
        raise KayitBulunamadi(f"Rezervasyon bulunamadı: {booking_id}")

    kilit = await db.execute(
        select(Member.id).where(Member.id == kayit.member_id).with_for_update()
    )
    if kilit.scalar_one_or_none() is None:
        raise KayitBulunamadi(f"Üye bulunamadı: {kayit.member_id}")

    oturum = await db.get(ClassSession, kayit.session_id)
    tip = await db.get(ClassType, oturum.class_type_id)

    son_iptal_ani = oturum.baslangic - timedelta(hours=tip.iptal_penceresi_saat)
    pencerede = now <= son_iptal_ani

    kapatma = await db.execute(
        update(Booking)
        .where(Booking.id == booking_id, Booking.durum == BookingDurumu.BOOKED)
        .values(durum=BookingDurumu.CANCELLED, cancelled_at=now)
        .returning(Booking.id)
    )
    if kapatma.first() is None:
        raise ZatenIptal("Bu rezervasyon zaten kapatılmış")

    sonuc = await db.execute(
        update(ClassSession)
        .where(ClassSession.id == oturum.id, ClassSession.dolu_sayi > 0)
        .values(dolu_sayi=ClassSession.dolu_sayi - 1)
        .returning(ClassSession.dolu_sayi)
    )
    bosalan_yer = sonuc.first() is not None

    sonuc = await db.execute(
        select(CreditLedger.member_package_id).where(
            CreditLedger.booking_id == kayit.id,
            CreditLedger.tip == LedgerTipi.BOOKING,
        )
    )
    kaynak_paket_id = sonuc.scalar_one_or_none()

    # İptal kuralı: 12 saatten fazla varsa (pencerede) veya yönetici ise iade yapılır.
    # 12 saatten az süre kala yapılan iptallerde ders hakkı kesinlikle iade edilmez (yanar).
    if pencerede or is_admin:
        await hareket_ekle(
            db, member_id=kayit.member_id, tip=LedgerTipi.CANCEL_REFUND, miktar=1,
            sebep=f"{tip.ad} — iptal (bakiye iadesi)",
            member_package_id=kaynak_paket_id, booking_id=kayit.id,
        )
        iade = True
    else:
        kalan_saat = max(0.0, (oturum.baslangic - now).total_seconds() / 3600)
        await hareket_ekle(
            db, member_id=kayit.member_id, tip=LedgerTipi.LATE_CANCEL, miktar=0,
            sebep=f"{tip.ad} — ders saatine {kalan_saat:.1f} saat kala iptal (geç iptal - hakkı yandı)",
            member_package_id=kaynak_paket_id, booking_id=kayit.id,
        )
        iade = False

    await db.flush()
    await db.refresh(kayit)

    # Bildirimler: Hem üyeye hem de adminlere (Eda Hanım) anlık push & in-app
    from app.services.bildirim import bildirim_gonder, adminlere_bildirim_gonder
    member_rec = await db.get(Member, kayit.member_id)
    member_ad = member_rec.ad if member_rec else f"Üye #{kayit.member_id}"
    ders_saat_str = oturum.baslangic.strftime("%d.%m %H:%M")
    durum_aciklama = "1 ders hakkı hesabınıza iade edildi." if iade else "Geç iptal (12 saatten az kala) sebebiyle stüdyo kuralı gereği ders hakkı iadesi yapılmadı (ders hakkınız yandı)."

    # Üyeye bildirim
    await bildirim_gonder(
        db,
        member_id=kayit.member_id,
        baslik="Ders İptal Onayı ⏱️",
        mesaj=f"{tip.ad} ({ders_saat_str}) ders rezervasyonunuz iptal edildi. {durum_aciklama}",
        tip="DERS_IPTALI",
    )

    # Adminlere (Eda Hanım'a) anlık bildirim & push
    kalan_bos_yer = oturum.kontenjan - oturum.dolu_sayi
    await adminlere_bildirim_gonder(
        db,
        baslik="🚨 Üye Ders İptali!",
        mesaj=f"{member_ad} üyesi {tip.ad} ({ders_saat_str}) dersini iptal etti. Yeri boşaldı! (Kalan Boş Yer: {kalan_bos_yer}/{oturum.kontenjan} • {durum_aciklama})",
        tip="DERS_IPTALI",
    )

    return IptalSonucu(booking=kayit, iade_edildi=iade, bosalan_yer=bosalan_yer)
