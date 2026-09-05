from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_member, get_db, get_optional_current_member
from app.models import EventRSVP, Member, StudioEvent
from app.schemas.member import StudioEventResponse

router = APIRouter(prefix="/events", tags=["events"])


@router.get("", response_model=list[StudioEventResponse])
async def list_studio_events(
    db: AsyncSession = Depends(get_db),
    current_member: Member | None = Depends(get_optional_current_member),
):
    """Aktif studio workshop ve etkinlik kayıtlarını döndürür."""
    stmt = (
        select(StudioEvent)
        .where(StudioEvent.aktif == True)
        .order_by(StudioEvent.tarih_saat.asc())
    )
    res = await db.execute(stmt)
    events = res.scalars().all()

    # Check member rsvps if logged in
    member_rsvps = set()
    if current_member:
        stmt_r = select(EventRSVP.event_id).where(
            EventRSVP.member_id == current_member.id,
            EventRSVP.durum == "registered",
        )
        res_r = await db.execute(stmt_r)
        member_rsvps = set(res_r.scalars().all())

    response_list = []
    for ev in events:
        resp = StudioEventResponse.model_validate(ev)
        resp.is_registered = (ev.id in member_rsvps)
        response_list.append(resp)

    return response_list


@router.post("/{event_id}/rsvp", response_model=dict)
async def rsvp_studio_event(
    event_id: int,
    tek_katilim: bool = True,
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Workshop veya Etkinlik için LCV / Tek katılımlı kayıt yapılması."""
    event = await db.get(StudioEvent, event_id)
    if not event or not event.aktif:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Etkinlik veya Workshop bulunamadı",
        )

    if event.kontenjan > 0 and event.dolu_sayi >= event.kontenjan:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bu etkinlik için kontenjan dolmuştur",
        )

    # Check if already registered
    stmt_check = select(EventRSVP).where(
        EventRSVP.event_id == event_id,
        EventRSVP.member_id == current_member.id,
        EventRSVP.durum == "registered",
    )
    res_check = await db.execute(stmt_check)
    existing = res_check.scalar_one_or_none()

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Bu etkinliğe zaten kayıtlısınız",
        )

    rsvp = EventRSVP(
        event_id=event_id,
        member_id=current_member.id,
        tek_katilim=tek_katilim,
        durum="registered",
    )
    event.dolu_sayi += 1

    db.add(rsvp)
    await db.commit()

    return {
        "mesaj": f"'{event.baslik}' etkinliğine kaydınız başarıyla alındı!",
        "event_id": event_id,
        "tek_katilim": tek_katilim,
        "ucret_bilgisi": event.ucret if not tek_katilim else f"{event.tek_katilim_ucret_tl} TL (Tek Katılım)",
    }
