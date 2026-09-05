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

        # Yöneticilere (Hocalara) üyenin ders iptal bildirimini gönder
        oturum = await db.get(ClassSession, sonuc.booking.session_id)
        class_type_ad = "Ders"
        if oturum and oturum.class_type_id:
            ct = await db.get(ClassType, oturum.class_type_id)
            if ct:
                class_type_ad = ct.ad

        res_admins = await db.execute(
            select(Member).where(
                (Member.kullanici_adi == "admin") | (Member.telefon.in_(ayarlar.admin_telefons))
            )
        )
        admins = res_admins.scalars().all()
        for adm in admins:
            await bildirim_gonder(
                db,
                member_id=adm.id,
                baslik="🚨 Üye Ders İptali",
                mesaj=f"{current_member.ad} üyesi {class_type_ad} dersindeki rezervasyonunu iptal etti.",
                tip="DERS_IPTALI",
            )

        await db.commit()
        await db.refresh(sonuc.booking)
        return sonuc.booking
    except Exception:
        await db.rollback()
        raise


@router.post("/waitlist", response_model=WaitlistResponse)
async def create_waitlist_entry(
    body: WaitlistCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Dolu derse bekleme sırası kaydı açar."""
    now = datetime.now(timezone.utc)
    try:
        entry = await siraya_gir(
            db,
            member_id=current_member.id,
            session_id=body.session_id,
            now=now,
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

    res_admins = await db.execute(
        select(Member).where(
            (Member.kullanici_adi == "admin") | (Member.telefon.in_(ayarlar.admin_telefons))
        )
    )
    admins = res_admins.scalars().all()
    for adm in admins:
        await bildirim_gonder(
            db,
            member_id=adm.id,
            baslik="⏳ Üyeliksiz Tek Ders Talebi!",
            mesaj=f"{ad_str} ({norm_tel}) üyesi {ct_ad} dersi için ödeme bekleyen talep oluşturdu.",
            tip="YENI_REZERVASYON",
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
