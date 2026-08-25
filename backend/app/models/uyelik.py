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
    telefon: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    ad: Mapped[str] = mapped_column(String(120))

    # KVKK aydınlatma onayı — zaman damgası kanıttır, boolean yeterli değil
    kvkk_onay_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=None
    )
    # Ders katılımcı listesinde adının görünmesine rıza. AYRI ve varsayılan KAPALI.
    katilimci_gorunurluk_onay: Mapped[bool] = mapped_column(Boolean, default=False)

    aktif: Mapped[bool] = mapped_column(Boolean, default=True)


class Instructor(ZamanDamgali, Base):
    __tablename__ = "instructors"

    id: Mapped[int] = mapped_column(primary_key=True)
    ad: Mapped[str] = mapped_column(String(120))
    biyografi: Mapped[str | None] = mapped_column(Text, default=None)
    foto_url: Mapped[str | None] = mapped_column(String(500), default=None)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)
