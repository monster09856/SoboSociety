import logging
import os
import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.bildirim import DeviceToken, Notification

logger = logging.getLogger("sobo.bildirim")

# Initialize Firebase Admin SDK
_firebase_app = None
try:
    cred_path = "/root/ilac-bilgi/firebase-service-account.json"
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info("[FCM] Firebase Admin SDK initialized for sobosociety backend.")
except Exception as e:
    logger.warning(f"[FCM] Firebase init warning: {e}")


async def bildirim_gonder(
    db: AsyncSession,
    member_id: int,
    baslik: str,
    mesaj: str,
    tip: str = "DUYURU",
) -> Notification:
    """Üyeye uygulama içi bildirim oluşturur ve Firebase Cloud Messaging (FCM) ile anında Push gönderir."""
    notif = Notification(
        member_id=member_id,
        baslik=baslik,
        mesaj=mesaj,
        tip=tip,
        okundu=False,
    )
    db.add(notif)
    await db.flush()

    # Cihaz token'ları var mı kontrol et ve FCM Push Gönder
    res = await db.execute(select(DeviceToken).where(DeviceToken.member_id == member_id))
    tokens = res.scalars().all()
    for tok in tokens:
        logger.info(f"[PUSH NOTIFICATION] Member {member_id} ({tok.platform}): {baslik} - {mesaj}")
        if tok.device_token and _firebase_app:
            try:
                fcm_msg = messaging.Message(
                    notification=messaging.Notification(
                        title=baslik,
                        body=mesaj,
                    ),
                    data={
                        "id": str(notif.id),
                        "baslik": baslik,
                        "mesaj": mesaj,
                        "tip": tip,
                    },
                    android=messaging.AndroidConfig(
                        priority="high",
                        notification=messaging.AndroidNotification(
                            channel_id="high_importance_channel",
                            priority="max",
                            default_sound=True,
                            default_vibrate_timings=True,
                            click_action="FLUTTER_NOTIFICATION_CLICK",
                        ),
                    ),
                    apns=messaging.APNSConfig(
                        headers={
                            "apns-priority": "10",
                            "apns-push-type": "alert",
                        },
                        payload=messaging.APNSPayload(
                            aps=messaging.Aps(
                                alert=messaging.ApsAlert(title=baslik, body=mesaj),
                                sound="default",
                                badge=1,
                                content_available=True,
                            ),
                        ),
                    ),
                    token=tok.device_token,
                )
                messaging.send(fcm_msg)
                logger.info(f"[FCM PUSH SUCCESS] Sent FCM push to member {member_id} token {tok.device_token[:15]}...")
            except Exception as push_err:
                logger.warning(f"[FCM PUSH ERROR] Failed to send to {tok.device_token[:15]}: {push_err}")
                err_str = str(push_err).lower()
                if "unregistered" in err_str or "not a valid fcm" in err_str or "notfound" in err_str:
                    try:
                        await db.delete(tok)
                        await db.commit()
                        logger.info(f"[FCM PUSH CLEANUP] Removed invalid/unregistered token for member {member_id}")
                    except Exception:
                        pass

    return notif


async def device_token_kaydet(
    db: AsyncSession,
    member_id: int,
    device_token: str,
    platform: str = "android",
) -> DeviceToken:
    """Üyenin APNs veya Web/FCM Push cihaz token'ını kaydeder veya günceller."""
    res = await db.execute(select(DeviceToken).where(DeviceToken.device_token == device_token))
    existing = res.scalar_one_or_none()
    if existing:
        existing.member_id = member_id
        existing.platform = platform
        await db.commit()
        await db.refresh(existing)
        logger.info(f"[DEVICE TOKEN] Updated existing token for member {member_id}: {device_token[:15]}...")
        return existing

    dt = DeviceToken(member_id=member_id, device_token=device_token, platform=platform)
    db.add(dt)
    await db.commit()
    await db.refresh(dt)
    logger.info(f"[DEVICE TOKEN] Saved new device token for member {member_id}: {device_token[:15]}...")
    return dt
