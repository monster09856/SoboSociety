from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.models.program import ClassSession, ClassType, SessionDurumu
from app.models.uyelik import Member
from app.schemas.member import ClassSessionResponse

router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.get("", response_model=list[ClassSessionResponse])
async def list_sessions(
    db: AsyncSession = Depends(get_db),
):
    """Gelecekteki aktif tüm grup ders oturumlarını kamuya açık listeler.
    Bireysel (kontenjan=1 / özel) seanslar haftalık genel programda listelenmez;
    yalnızca ilgili üyenin ve stüdyo hocasının kendi panelinde görünür."""
    now = datetime.now(timezone.utc)
    stmt = (
        select(ClassSession)
        .join(ClassType, ClassSession.class_type_id == ClassType.id)
        .where(
            ClassSession.baslangic >= now,
            ClassSession.durum == SessionDurumu.AKTIF,
            ClassSession.kontenjan > 1,
            ClassType.kontenjan > 1,
        )
        .order_by(ClassSession.baslangic)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())
