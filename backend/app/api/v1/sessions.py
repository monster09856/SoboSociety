from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_member, get_db
from app.models.program import ClassSession, SessionDurumu
from app.models.uyelik import Member
from app.schemas.member import ClassSessionResponse

router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.get("", response_model=list[ClassSessionResponse])
async def list_sessions(
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Gelecekteki aktif ders oturumlarını listeler."""
    now = datetime.now(timezone.utc)
    stmt = (
        select(ClassSession)
        .where(
            ClassSession.baslangic >= now,
            ClassSession.durum == SessionDurumu.AKTIF,
        )
        .order_by(ClassSession.baslangic)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())
