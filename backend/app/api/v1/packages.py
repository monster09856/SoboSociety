from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.models.kredi import Package
from app.schemas.admin import PackageResponse

router = APIRouter(prefix="/packages", tags=["packages"])


@router.get("", response_model=list[PackageResponse])
async def list_public_packages(
    db: AsyncSession = Depends(get_db),
):
    """Tüm aktif stüdyo ders paketlerini ve fiyatlarını döndürür."""
    res = await db.execute(
        select(Package)
        .where(Package.aktif == True, Package.fiyat_kurus > 0)
        .order_by(Package.id.asc())
    )
    pkgs = res.scalars().all()
    return [
        PackageResponse(
            id=p.id,
            ad=p.ad,
            ders_adedi=p.ders_adedi,
            gecerlilik_gun=p.gecerlilik_gun,
            fiyat_tl=p.fiyat_kurus / 100.0,
            fiyat_kurus=p.fiyat_kurus,
            aktif=p.aktif,
        )
        for p in pkgs
    ]
