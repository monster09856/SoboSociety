from datetime import date, datetime
from enum import StrEnum

from sqlalchemy import (
    Boolean, CheckConstraint, Date, DateTime, ForeignKey,
    Integer, String, func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, ZamanDamgali


class LedgerTipi(StrEnum):
    """Kredi hareketi tipleri.

    LATE_CANCEL ve NO_SHOW miktarı 0'dır ama satır yine de yazılır: bakiyeyi
    değiştirmezler, NEYİN NEDEN YANDIĞINI anlatırlar. "Benim 3 dersim daha
    vardı" tartışması küçük stüdyoda her ay çıkar ve sayaçla değil, tarihçeyle
    kapanır.
    """

    PURCHASE = "purchase"
    BOOKING = "booking"
    CANCEL_REFUND = "cancel_refund"
    LATE_CANCEL = "late_cancel"
    NO_SHOW = "no_show"
    EXPIRE = "expire"
    ADMIN_ADJUST = "admin_adjust"


class Package(ZamanDamgali, Base):
    __tablename__ = "packages"

    id: Mapped[int] = mapped_column(primary_key=True)
    ad: Mapped[str] = mapped_column(String(80))
    ders_adedi: Mapped[int] = mapped_column(Integer)
    gecerlilik_gun: Mapped[int] = mapped_column(Integer)
    # Fiyat kuruş cinsinden tam sayı — para asla float tutulmaz
    fiyat_kurus: Mapped[int] = mapped_column(Integer)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)

    __table_args__ = (
        CheckConstraint("ders_adedi > 0", name="ck_package_ders_adedi"),
        CheckConstraint("gecerlilik_gun > 0", name="ck_package_gecerlilik"),
    )


class MemberPackage(ZamanDamgali, Base):
    """Üyeye tanımlanmış paket. Kalan ders sayacı YOKTUR — bakiye ledger'dan
    hesaplanır."""

    __tablename__ = "member_packages"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id"), index=True)
    package_id: Mapped[int] = mapped_column(ForeignKey("packages.id"))
    baslangic: Mapped[date] = mapped_column(Date)
    # DİKKAT: `bitis` paketin GEÇERSİZ OLDUĞU İLK GÜNDÜR, son geçerli gün
    # değildir. `paket_tanimla` bunu `baslangic + gecerlilik_gun` olarak
    # hesaplar: 1 Eylül'de açılan 60 günlük paketin son geçerli günü 30 Ekim,
    # `bitis` değeri 31 Ekim'dir. Geçerlilik kontrolü bu yüzden yarı-açık
    # aralıktır: `baslangic <= gun < bitis`. `<= bitis` yazmak pakete bir gün
    # fazladan ömür verir.
    bitis: Mapped[date] = mapped_column(Date)


class CreditLedger(Base):
    """Append-only kredi hareket defteri.

    Bu tablodaki satırlar ASLA UPDATE veya DELETE edilmez. Düzeltme yeni bir
    ADMIN_ADJUST satırıyla yapılır. `updated_at` bilerek yoktur — güncellenen
    bir satır kavramı bu tabloda yanlış olurdu.
    """

    __tablename__ = "credit_ledger"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id"), index=True)
    member_package_id: Mapped[int | None] = mapped_column(
        ForeignKey("member_packages.id"), default=None
    )
    tip: Mapped[str] = mapped_column(String(24))
    miktar: Mapped[int] = mapped_column(Integer)
    sebep: Mapped[str] = mapped_column(String(200))
    # FK: `bookings` tablosu Task 7'de geldi, bu sütunun başta FK'siz
    # bırakılma sebebi ortadan kalktı. FK olmadan `booking_id=999999` ile
    # hayalet satır yazılabiliyordu — `member_id` FK'li olduğu için tutarsızdı.
    booking_id: Mapped[int | None] = mapped_column(
        ForeignKey("bookings.id"), default=None, index=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
