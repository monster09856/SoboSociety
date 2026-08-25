from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, CreditLedger,
    LedgerTipi, Member,
)
from app.services.hatalar import KayitBulunamadi, ZatenIptal
from app.services.kredi import hareket_ekle


@dataclass(frozen=True)
class IptalSonucu:
    booking: Booking
    iade_edildi: bool
    bosalan_yer: bool


async def iptal_et(db: AsyncSession, *, booking_id: int, now: datetime) -> IptalSonucu:
    """Rezervasyonu iptal eder.

    Pencerede iptal: kredi iade edilir (CANCEL_REFUND, +1).
    Geç iptal: kredi yanar (LATE_CANCEL, 0) — ama satır yine yazılır ki
    üye "neden bir dersim eksik" diye sorduğunda cevap tarihçede olsun.

    Her iki durumda da KONTENJAN BOŞALIR. Üye gelmeyecekse o yer başkasına
    açılmalıdır; geç iptali cezalandırmanın yolu yeri boş tutmak değil,
    krediyi yakmaktır.
    """
    kayit = await db.get(Booking, booking_id)
    if kayit is None:
        raise KayitBulunamadi(f"Rezervasyon bulunamadı: {booking_id}")

    # Global kilit sırasını koru: members -> class_sessions.
    #
    # Bu kilit olmadan sıra fiilen tersine dönüyordu: credit_ledger INSERT'i
    # member_id FK'si yüzünden `members` üzerinde örtük FOR KEY SHARE alır ve
    # bu, `siraya_gir`/`rezerve_et`'in FOR UPDATE'i ile çatışır. İnceleme bu
    # döngüyle gerçek bir DeadlockDetectedError üretti.
    kilit = await db.execute(
        select(Member.id).where(Member.id == kayit.member_id).with_for_update()
    )
    if kilit.scalar_one_or_none() is None:
        raise KayitBulunamadi(f"Üye bulunamadı: {kayit.member_id}")

    oturum = await db.get(ClassSession, kayit.session_id)
    tip = await db.get(ClassType, oturum.class_type_id)

    son_iptal_ani = oturum.baslangic - timedelta(hours=tip.iptal_penceresi_saat)
    # Sınır kullanıcı lehine: tam sınırda iptal hakkı vardır.
    pencerede = now <= son_iptal_ani

    # Durumu ATOMIK olarak değiştir. ORM ataması yarışa açıktı: aynı
    # rezervasyon için iki eşzamanlı iptal çağrısında ikisi de durumu
    # BOOKED görür, ikisi de geçer ve kontenjan iki kişilik boşalırdı.
    # Etkilenen satır 0 ise bu rezervasyon başka biri tarafından çoktan
    # kapatılmıştır.
    kapatma = await db.execute(
        update(Booking)
        .where(Booking.id == booking_id, Booking.durum == BookingDurumu.BOOKED)
        .values(durum=BookingDurumu.CANCELLED, cancelled_at=now)
        .returning(Booking.id)
    )
    if kapatma.first() is None:
        raise ZatenIptal("Bu rezervasyon zaten kapatılmış")

    # Kontenjanı atomik olarak azalt. dolu_sayi > 0 koşulu, çift iptalin
    # sayacı eksiye düşürmesini veritabanı seviyesinde engeller.
    sonuc = await db.execute(
        update(ClassSession)
        .where(ClassSession.id == oturum.id, ClassSession.dolu_sayi > 0)
        .values(dolu_sayi=ClassSession.dolu_sayi - 1)
        .returning(ClassSession.dolu_sayi)
    )
    bosalan_yer = sonuc.first() is not None

    # İade/ceza satırı, kredinin DÜŞÜLDÜĞÜ paketle aynı pakete yazılmalı.
    # Burada yeniden `aktif_paket_sec` çağırmak YANLIŞ olurdu: aradan geçen
    # sürede yeni bir paket açılmış olabilir ve iade, krediyi hiç almamış
    # bir pakete gider. Doğru kaynak, bu rezervasyonun BOOKING satırıdır.
    sonuc = await db.execute(
        select(CreditLedger.member_package_id).where(
            CreditLedger.booking_id == kayit.id,
            CreditLedger.tip == LedgerTipi.BOOKING,
        )
    )
    kaynak_paket_id = sonuc.scalar_one_or_none()

    if pencerede:
        await hareket_ekle(
            db, member_id=kayit.member_id, tip=LedgerTipi.CANCEL_REFUND, miktar=1,
            sebep=f"{tip.ad} — pencerede iptal",
            member_package_id=kaynak_paket_id, booking_id=kayit.id,
        )
    else:
        kalan_saat = (oturum.baslangic - now).total_seconds() / 3600
        await hareket_ekle(
            db, member_id=kayit.member_id, tip=LedgerTipi.LATE_CANCEL, miktar=0,
            sebep=f"{tip.ad} — ders saatine {kalan_saat:.1f} saat kala iptal",
            member_package_id=kaynak_paket_id, booking_id=kayit.id,
        )

    await db.flush()
    await db.refresh(kayit)
    return IptalSonucu(booking=kayit, iade_edildi=pencerede, bosalan_yer=bosalan_yer)
