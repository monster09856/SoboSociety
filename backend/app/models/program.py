from datetime import date, datetime
from enum import StrEnum

from sqlalchemy import (
    Boolean, CheckConstraint, Date, DateTime, ForeignKey,
    Integer, String, UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, ZamanDamgali


class SessionDurumu(StrEnum):
    AKTIF = "active"
    IPTAL = "cancelled"


class ClassType(ZamanDamgali, Base):
    """Ders tipi: Barre, Pilates, Functional, Birebir."""

    __tablename__ = "class_types"

    id: Mapped[int] = mapped_column(primary_key=True)
    ad: Mapped[str] = mapped_column(String(80), unique=True)
    kontenjan: Mapped[int] = mapped_column(Integer)
    sure_dk: Mapped[int] = mapped_column(Integer)
    renk: Mapped[str] = mapped_column(String(9), default="#A2846F")
    iptal_penceresi_saat: Mapped[int] = mapped_column(Integer, default=6)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)

    __table_args__ = (
        CheckConstraint("kontenjan > 0", name="ck_class_type_kontenjan"),
        CheckConstraint("sure_dk > 0", name="ck_class_type_sure"),
    )


class Room(ZamanDamgali, Base):
    """Salon. v1'de tek kayıt var ama model çoklu salonu destekliyor —
    ikinci salon açıldığında şema değişmesin."""

    __tablename__ = "rooms"

    id: Mapped[int] = mapped_column(primary_key=True)
    ad: Mapped[str] = mapped_column(String(80), unique=True)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)


class ScheduleTemplate(ZamanDamgali, Base):
    """Haftalık tekrar eden program satırı: "her Salı 19:00 Barre".

    Somut ders oturumları buradan üretilir (Task 4). Şablon değişince geçmiş
    oturumlar etkilenmez.
    """

    __tablename__ = "schedule_templates"

    id: Mapped[int] = mapped_column(primary_key=True)
    hafta_gunu: Mapped[int] = mapped_column(Integer)  # 0=Pazartesi .. 6=Pazar
    saat_dk: Mapped[int] = mapped_column(Integer)     # gün başından dakika (19:00 -> 1140)

    class_type_id: Mapped[int] = mapped_column(ForeignKey("class_types.id"))
    instructor_id: Mapped[int] = mapped_column(ForeignKey("instructors.id"))
    room_id: Mapped[int] = mapped_column(ForeignKey("rooms.id"))

    gecerli_baslangic: Mapped[date] = mapped_column(Date)
    gecerli_bitis: Mapped[date | None] = mapped_column(Date, default=None)

    __table_args__ = (
        CheckConstraint("hafta_gunu BETWEEN 0 AND 6", name="ck_template_gun"),
        CheckConstraint("saat_dk BETWEEN 0 AND 1439", name="ck_template_saat"),
    )


class ClassSession(ZamanDamgali, Base):
    """Somut ders oturumu — belirli bir tarih ve saatteki ders."""

    __tablename__ = "class_sessions"

    id: Mapped[int] = mapped_column(primary_key=True)
    baslangic: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)

    class_type_id: Mapped[int] = mapped_column(ForeignKey("class_types.id"))
    instructor_id: Mapped[int] = mapped_column(ForeignKey("instructors.id"))
    room_id: Mapped[int] = mapped_column(ForeignKey("rooms.id"))

    # Kontenjan, class_types.kontenjan'ın KOPYASIDIR — referansı değil.
    # Ders tipinin kontenjanı 8'den 6'ya düşerse geçmiş oturumların kaydı
    # bozulmamalı. Ayrıca tek bir dersin kontenjanı istisnaen değişebilir
    # (iki reformer arızalandı). Snapshot bu yüzden.
    kontenjan: Mapped[int] = mapped_column(Integer)
    dolu_sayi: Mapped[int] = mapped_column(Integer, default=0)

    durum: Mapped[str] = mapped_column(String(16), default=SessionDurumu.AKTIF)
    template_id: Mapped[int | None] = mapped_column(
        ForeignKey("schedule_templates.id"), default=None
    )

    class_type: Mapped["ClassType"] = relationship("ClassType", lazy="selectin")
    instructor: Mapped["Instructor"] = relationship("Instructor", lazy="selectin")
    room: Mapped["Room"] = relationship("Room", lazy="selectin")

    __table_args__ = (
        # Aynı salonda aynı anda iki ders olamaz. Bu kısıt aynı zamanda
        # şablon üretiminin idempotent olmasını da garanti eder (Task 4).
        UniqueConstraint("room_id", "baslangic", name="uq_salon_saat"),
        CheckConstraint(
            "dolu_sayi >= 0 AND dolu_sayi <= kontenjan", name="ck_session_dolu_sayi"
        ),
    )


class StudioEvent(ZamanDamgali, Base):
    """Stüdyo içi özel Etkinlik & Workshop kayıtları (Kahve Buluşmaları, Atölyeler)."""

    __tablename__ = "studio_events"

    id: Mapped[int] = mapped_column(primary_key=True)
    baslik: Mapped[str] = mapped_column(String(120))
    turu: Mapped[str] = mapped_column(String(40), default="WORKSHOP")  # WORKSHOP | ETKINLIK | KAHVE
    tarih_saat: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    aciklama: Mapped[str] = mapped_column(String(500), default="")
    kontenjan: Mapped[int] = mapped_column(Integer, default=15)
    ucret: Mapped[str] = mapped_column(String(40), default="Ücretsiz / Üyelere Özel")
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)

