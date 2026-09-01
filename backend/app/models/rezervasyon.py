from datetime import datetime
from enum import StrEnum

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, ZamanDamgali


class BookingDurumu(StrEnum):
    BOOKED = "booked"
    CANCELLED = "cancelled"
    ATTENDED = "attended"
    NO_SHOW = "no_show"


class BookingKaynagi(StrEnum):
    APP = "app"
    WEB = "web"
    ADMIN = "admin"


class Booking(ZamanDamgali, Base):
    __tablename__ = "bookings"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id"), index=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("class_sessions.id"), index=True)

    durum: Mapped[str] = mapped_column(String(16), default=BookingDurumu.BOOKED)
    kaynak: Mapped[str] = mapped_column(String(8), default=BookingKaynagi.APP)
    cancelled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=None
    )

    session: Mapped["ClassSession"] = relationship("ClassSession", lazy="selectin")

    __table_args__ = (
        # Kısmi unique index: bir üye aynı derse aynı anda yalnız BİR aktif
        # rezervasyon yapabilir. Tam unique olsaydı iptal edip yeniden
        # rezerve etmek imkânsız olurdu.
        Index(
            "uq_aktif_rezervasyon",
            "member_id",
            "session_id",
            unique=True,
            postgresql_where=text("durum = 'booked'"),
        ),
    )


class WaitlistEntry(ZamanDamgali, Base):
    """Dolu derse sıraya giren üye. Sıra numarası girilme anına göre artar."""

    __tablename__ = "waitlist_entries"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id"), index=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("class_sessions.id"), index=True)
    sira: Mapped[int] = mapped_column(Integer)
    # Yer açıldığında bu üyeye teklif edildi; bu ana kadar cevap vermezse sıra ilerler
    teklif_bitis: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=None
    )
    kullanildi: Mapped[bool] = mapped_column(default=False)

    session: Mapped["ClassSession"] = relationship("ClassSession", lazy="selectin")

    __table_args__ = (
        Index("uq_bekleme", "member_id", "session_id", unique=True),
    )
