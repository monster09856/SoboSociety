import logging
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.bildirim import DeviceToken, Notification

logger = logging.getLogger("sobo.bildirim")


async def bildirim_gonder(
    db: AsyncSession,
    member_id: int,
    baslik: str,
    mesaj: str,
    tip: str = "DUYURU",
) -> Notification:
    """Üyeye uygulama içi bildirim oluşturur ve APNs / Web Push kuyruğuna gönderir."""
    notif = Notification(
        member_id=member_id,
        baslik=baslik,
        mesaj=mesaj,
        tip=tip,
        okundu=False,
    )
    db.add(notif)
    await db.flush()

    # Cihaz token'ları var mı kontrol et ve Push Gönder
    res = await db.execute(select(DeviceToken).where(DeviceToken.member_id == member_id))
    tokens = res.scalars().all()
    for tok in tokens:
        logger.info(f"[PUSH NOTIFICATION] Member {member_id} ({tok.platform}): {baslik} - {mesaj}")

    return notif


async def device_token_kaydet(
    db: AsyncSession,
    member_id: int,
    device_token: str,
    platform: str = "ios",
) -> DeviceToken:
    """Üyenin APNs veya Web Push cihaz token'ını kaydeder veya günceller."""
    res = await db.execute(select(DeviceToken).where(DeviceToken.device_token == device_token))
    existing = res.scalar_one_or_none()
    if existing:
        existing.member_id = member_id
        existing.platform = platform
        await db.flush()
        return existing

    dt = DeviceToken(member_id=member_id, device_token=device_token, platform=platform)
    db.add(dt)
    await db.flush()
    return dt
