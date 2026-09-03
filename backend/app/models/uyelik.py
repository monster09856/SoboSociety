from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, ZamanDamgali


class Member(ZamanDamgali, Base):
    """Stüdyo üyesi. Kimlik anahtarı telefon numarasıdır — e-posta yok.

    Eğitmen üyeyi panelden telefonla açar; üye uygulamaya/web'e girip aynı
    numarayı doğrulayınca kayıt kendiliğinden eşleşir. Instagram DM'den
    sisteme geçişi mümkün kılan mekanizma budur.
    """

    __tablename__ = "members"

    id: Mapped[int] = mapped_column(primary_key=True)
    kullanici_adi: Mapped[str | None] = mapped_column(String(60), unique=True, index=True, default=None)
    sifre_hash: Mapped[str | None] = mapped_column(String(255), default=None)
    telefon: Mapped[str | None] = mapped_column(String(16), unique=True, index=True, default=None)
    ad: Mapped[str] = mapped_column(String(120))

    # KVKK aydınlatma onayı — zaman damgası kanıttır, boolean yeterli değil
    kvkk_onay_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=None
    )
    # Ders katılımcı listesinde adının görünmesine rıza. AYRI ve varsayılan KAPALI.
    katilimci_gorunurluk_onay: Mapped[bool] = mapped_column(Boolean, default=False)

    # Vücut Ölçüleri ve Sağlık / Hedef Notları
    bel: Mapped[str | None] = mapped_column(String(40), default=None)
    kalca: Mapped[str | None] = mapped_column(String(40), default=None)
    sag_ic_bacak: Mapped[str | None] = mapped_column(String(40), default=None)
    sag_bacak: Mapped[str | None] = mapped_column(String(40), default=None)
    sol_ic_bacak: Mapped[str | None] = mapped_column(String(40), default=None)
    sol_bacak: Mapped[str | None] = mapped_column(String(40), default=None)
    sag_kol: Mapped[str | None] = mapped_column(String(40), default=None)
    sol_kol: Mapped[str | None] = mapped_column(String(40), default=None)
    boy: Mapped[str | None] = mapped_column(String(40), default=None)
    kilo: Mapped[str | None] = mapped_column(String(40), default=None)
    saglik_notu: Mapped[str | None] = mapped_column(Text, default=None)

    aktif: Mapped[bool] = mapped_column(Boolean, default=True)


class Instructor(ZamanDamgali, Base):
    __tablename__ = "instructors"

    id: Mapped[int] = mapped_column(primary_key=True)
    ad: Mapped[str] = mapped_column(String(120))
    biyografi: Mapped[str | None] = mapped_column(Text, default=None)
    foto_url: Mapped[str | None] = mapped_column(String(500), default=None)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)
