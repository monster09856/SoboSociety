from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_member, get_db
from app.models.rezervasyon import Booking, BookingKaynagi
from app.models.uyelik import Member
from app.schemas.member import (
    BookingCreateRequest,
    BookingResponse,
    WaitlistCreateRequest,
    WaitlistResponse,
)
from app.services.bekleme import siraya_gir
from app.services.hatalar import KayitBulunamadi
from app.services.iptal import iptal_et
from app.services.rezervasyon import rezerve_et

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
    """Rezervasyonu iptal eder."""
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
