from datetime import datetime, timezone
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, ZamanDamgali


class Notification(ZamanDamgali, Base):
    """Üyeye gönderilen içi ve anlık (push) bildirimler."""

    __tablename__ = "notifications"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(Integer, ForeignKey("members.id", ondelete="CASCADE"), index=True)
    baslik: Mapped[str] = mapped_column(String(120))
    mesaj: Mapped[str] = mapped_column(Text)
    tip: Mapped[str] = mapped_column(String(40), default="DUYURU")
    okundu: Mapped[bool] = mapped_column(Boolean, default=False, index=True)


class DeviceToken(ZamanDamgali, Base):
    """Anlık bildirim (APNs / Web Push) için üye cihaz token'ları."""

    __tablename__ = "device_tokens"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(Integer, ForeignKey("members.id", ondelete="CASCADE"), index=True)
    device_token: Mapped[str] = mapped_column(String(500), unique=True, index=True)
    platform: Mapped[str] = mapped_column(String(20), default="ios")


class NotificationCampaign(ZamanDamgali, Base):
    """Admin tarafından zamanlanan veya anlık toplu bildirim kampanyaları."""

    __tablename__ = "notification_campaigns"

    id: Mapped[int] = mapped_column(primary_key=True)
    baslik: Mapped[str] = mapped_column(String(120))
    mesaj: Mapped[str] = mapped_column(Text)
    hedef_kitle: Mapped[str] = mapped_column(String(40), default="TUM_UYELER")
    zamanlama_tipi: Mapped[str] = mapped_column(String(40), default="ANLIK")
    zamanlama_saat: Mapped[str | None] = mapped_column(String(10), default=None)
    son_gonderim_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)
    gonderilen_sayisi: Mapped[int] = mapped_column(Integer, default=0)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)
