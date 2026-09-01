from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_member, get_db
from app.models.bildirim import DeviceToken, Notification
from app.models.uyelik import Member
from app.services.bildirim import device_token_kaydet

router = APIRouter(tags=["Notifications"])


class NotificationResponse(BaseModel):
    id: int
    baslik: str
    mesaj: str
    tip: str
    okundu: bool
    olusturuldu_at: str


class DeviceTokenRequest(BaseModel):
    device_token: str
    platform: str = "ios"


@router.get("/my/notifications", response_model=list[NotificationResponse])
async def get_my_notifications(
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
):
    """Giriş yapmış üyenin tüm ve okunmamış bildirimlerini getirir."""
    res = await db.execute(
        select(Notification)
        .where(Notification.member_id == member.id)
        .order_by(Notification.id.desc())
        .limit(50)
    )
    items = res.scalars().all()
    return [
        NotificationResponse(
            id=item.id,
            baslik=item.baslik,
            mesaj=item.mesaj,
            tip=item.tip,
            okundu=item.okundu,
            olusturuldu_at=item.olusturuldu_at.isoformat(),
        )
        for item in items
    ]


@router.post("/my/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: int,
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
):
    """Bildirimi okundu işaretler."""
    await db.execute(
        update(Notification)
        .where(Notification.id == notification_id, Notification.member_id == member.id)
        .values(okundu=True)
    )
    return {"mesaj": "Okundu işaretlendi"}


@router.post("/my/device-token")
async def register_device_token(
    body: DeviceTokenRequest,
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
):
    """APNs (iOS) veya Web Push cihaz token'ını kaydeder."""
    dt = await device_token_kaydet(
        db, member_id=member.id, device_token=body.device_token, platform=body.platform
    )
    return {"mesaj": "Cihaz token'ı kaydedildi", "id": dt.id}
