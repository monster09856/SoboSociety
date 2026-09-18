from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_member, get_db
from app.models.program import ClassSession, ClassType, SessionDurumu
from app.models.rezervasyon import Booking, BookingKaynagi
from app.models.uyelik import Member
from app.schemas.member import (
    BookingCreateRequest,
    BookingResponse,
    GuestBookingRequest,
    WaitlistCreateRequest,
    WaitlistResponse,
)
from app.services.bekleme import siraya_gir
from app.services.bildirim import bildirim_gonder
from app.services.hatalar import KayitBulunamadi
from app.services.iptal import iptal_et
from app.services.rezervasyon import rezerve_et
from app.settings import ayarlar

router = APIRouter(tags=["bookings"])


@router.post("/bookings", response_model=BookingResponse)
async def create_booking(
    body: BookingCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Derse rezervasyon yapar."""
    now = datetime.now(timezone.utc)
    try:
        booking = await rezerve_et(
            db,
            member_id=current_member.id,
            session_id=body.session_id,
            now=now,
            kaynak=BookingKaynagi.APP,
        )
        await db.commit()
        await db.refresh(booking)
        return booking
    except Exception:
        await db.rollback()
        raise


@router.post("/bookings/{booking_id}/cancel", response_model=BookingResponse)
async def cancel_booking(
    booking_id: int,
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Rezervasyonu iptal eder ve yöneticilere (Hocalara) anında canlı bildirim gönderir."""
    booking = await db.get(Booking, booking_id)
    if booking is None:
        raise KayitBulunamadi(f"Rezervasyon bulunamadı: {booking_id}")
    if booking.member_id != current_member.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu rezervasyon size ait değil",
        )

    now = datetime.now(timezone.utc)
    try:
        sonuc = await iptal_et(db, booking_id=booking_id, now=now)
        await db.commit()
        await db.refresh(sonuc.booking)
        resp = BookingResponse.model_validate(sonuc.booking)
        resp.iade_edildi = sonuc.iade_edildi
        if sonuc.iade_edildi:
            resp.mesaj = "Ders rezervasyonunuz başarıyla iptal edildi. 1 ders hakkınız hesabınıza iade edildi."
        else:
            resp.mesaj = "Ders rezervasyonunuz iptal edildi. 12 saat kuralı gereği ders hakkınız iade edilmemiştir (yanmıştır)."
        return resp
    except Exception:
        await db.rollback()
        raise


@router.post("/waitlist", response_model=WaitlistResponse)
async def create_waitlist_entry(
    body: WaitlistCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Dolu derse bekleme sırası kaydı açar ve adminlere anında bildirim gönderir."""
    now = datetime.now(timezone.utc)
    try:
        entry = await siraya_gir(
            db,
            member_id=current_member.id,
            session_id=body.session_id,
            now=now,
        )
        from app.services.bildirim import adminlere_bildirim_gonder
        session = await db.get(ClassSession, body.session_id)
        ct_name = session.class_type.ad if session and session.class_type else "Ders"
        saat_str = session.baslangic.strftime("%d.%m %H:%M") if session else ""
        await adminlere_bildirim_gonder(
            db,
            baslik="📋 Bekleme Listesi Kaydı",
            mesaj=f"{current_member.ad} üyesi {ct_name} ({saat_str}) dersi için bekleme sırasına girdi (Sıra No: {entry.sira}).",
            tip="BEKLEME_LISTESI",
        )
        await db.commit()
        await db.refresh(entry)
        return entry
    except Exception:
        await db.rollback()
        raise


@router.post("/guest-booking")
async def create_guest_booking(
    body: GuestBookingRequest,
    db: AsyncSession = Depends(get_db),
):
    """Üyeliksiz misafirlerin tek derslik rezervasyon talebi (Ödeme Bekliyor) oluşturması için uç nokta."""
    from urllib.parse import quote
    from app.services.telefon import normalize_telefon
    from app.models.rezervasyon import BookingDurumu

    norm_tel = normalize_telefon(body.telefon)
    if not norm_tel:
        raise HTTPException(status_code=400, detail="Lütfen geçerli bir cep telefonu numarası giriniz.")

    ad_str = body.ad.strip()
    if not ad_str:
        raise HTTPException(status_code=400, detail="Lütfen Adınız ve Soyadınızı giriniz.")

    session = await db.get(ClassSession, body.session_id)
    if not session or session.durum != SessionDurumu.AKTIF:
        stmt_active = select(ClassSession).where(ClassSession.durum == SessionDurumu.AKTIF).order_by(ClassSession.id.desc())
        session = (await db.execute(stmt_active)).scalars().first()

    if not session:
        raise HTTPException(status_code=404, detail="Şu an için aktif ders oturumu bulunmuyor.")

    # Telefon numarasıyla mevcut üye var mı kontrol et yoksa şifresiz misafir üye aç
    stmt = select(Member).where(Member.telefon == norm_tel)
    res = await db.execute(stmt)
    member = res.scalar_one_or_none()
    if not member:
        member = Member(
            ad=ad_str,
            telefon=norm_tel,
            kullanici_adi=None,
            sifre_hash=None,
        )
        db.add(member)
        await db.flush()

    # Aynı derse beklemede veya onaylı aktif rezervasyonu var mı?
    check_stmt = select(Booking).where(
        Booking.member_id == member.id,
        Booking.session_id == session.id,
        Booking.durum.in_([BookingDurumu.BOOKED, BookingDurumu.PENDING_PAYMENT])
    )
    existing_b = (await db.execute(check_stmt)).scalar_one_or_none()
    if existing_b:
        if existing_b.durum == BookingDurumu.PENDING_PAYMENT:
            raise HTTPException(status_code=400, detail="Bu ders için zaten ödeme beklemede olan bir rezervasyon talebiniz bulunmaktadır.")
        else:
            raise HTTPException(status_code=400, detail="Bu ders için zaten onaylı rezervasyonunuz bulunmaktadır.")

    # Status: PENDING_PAYMENT
    booking = Booking(
        member_id=member.id,
        session_id=session.id,
        durum=BookingDurumu.PENDING_PAYMENT,
        kaynak=BookingKaynagi.WEB,
    )
    db.add(booking)
    await db.flush()

    # Yöneticilere bildirim fırlat
    ct_ad = "Ders"
    if session.class_type_id:
        ct = await db.get(ClassType, session.class_type_id)
        if ct:
            ct_ad = ct.ad

    from app.services.bildirim import adminlere_bildirim_gonder
    await adminlere_bildirim_gonder(
        db,
        baslik="⏳ Misafir Tek Ders Talebi!",
        mesaj=f"{ad_str} ({norm_tel}), {ct_ad} dersi için tek ders talebi oluşturdu.",
        tip="MISAFIR_TALEP",
    )

    await db.commit()
    await db.refresh(booking)

    class_title = ct_ad
    wa_msg = quote(f"Merhaba, {class_title} dersi için tek derslik rezervasyon talebi oluşturdum ({ad_str} - {norm_tel}). Ödemeyi tamamlayıp onaylatmak istiyorum.")
    wa_url = f"https://wa.me/905316033080?text={wa_msg}"

    return {
        "booking_id": booking.id,
        "durum": booking.durum,
        "mesaj": "Tek derslik rezervasyon talebiniz alındı! Ödemeyi tamamlamak için WhatsApp hattımıza yönlendiriliyorsunuz.",
        "whatsapp_url": wa_url,
    }
