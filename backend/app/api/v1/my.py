from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_member, get_db
from app.models.rezervasyon import Booking, BookingDurumu
from app.models.uyelik import Member
from app.schemas.member import MemberSummaryResponse
from app.services.kredi import bakiye

router = APIRouter(prefix="/my", tags=["my"])


@router.get("/summary", response_model=MemberSummaryResponse)
async def get_my_summary(
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Giriş yapmış üyenin bakiye ve rezervasyon özetini döndürür."""
    kredi_bakiye = await bakiye(db, current_member.id)
    now = datetime.now(timezone.utc)

    stmt = (
        select(Booking)
        .where(Booking.member_id == current_member.id)
        .order_by(Booking.id.desc())
    )
    result = await db.execute(stmt)
    bookings = list(result.scalars().all())

    aktif = []
    gecmis = []
    for b in bookings:
        if b.durum == BookingDurumu.BOOKED and (b.session is None or b.session.baslangic >= now):
            aktif.append(b)
        else:
            gecmis.append(b)

    return MemberSummaryResponse(
        id=current_member.id,
        ad=current_member.ad,
        telefon=current_member.telefon,
        bakiye=kredi_bakiye,
        aktif_rezervasyonlar=aktif,
        gecmis_rezervasyonlar=gecmis,
    )
