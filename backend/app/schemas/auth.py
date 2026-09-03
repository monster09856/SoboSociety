from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class MemberRegisterRequest(BaseModel):
    ad: str = Field(..., description="Ad Soyad")
    kullanici_adi: str = Field(..., description="Kullanıcı adı")
    sifre: str = Field(..., description="Şifre")
    telefon: str | None = Field(default=None, description="Cep telefonu (Opsiyonel)")


class MemberLoginRequest(BaseModel):
    kullanici_adi: str = Field(..., description="Kullanıcı adı veya Telefon numarası")
    sifre: str = Field(..., description="Şifre")


class OTPSendRequest(BaseModel):
    telefon: str = Field(..., description="Üye cep telefonu numarası (örn: +905316033080)")


class OTPSendResponse(BaseModel):
    mesaj: str = Field(default="OTP doğrulama kodu gönderildi")
    telefon: str


class OTPVerifyRequest(BaseModel):
    telefon: str = Field(..., description="Üye cep telefonu numarası")
    kod: str = Field(..., description="6 haneli OTP kodu")
    ad: str | None = Field(default=None, description="Kayıt esnasında Ad Soyad (Opsiyonel)")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class MemberMeResponse(BaseModel):
    id: int
    ad: str
    kullanici_adi: str | None = None
    telefon: str | None = None
    kvkk_onay_at: datetime | None = None
    katilimci_gorunurluk_onay: bool = False
    aktif: bool = True
    is_admin: bool = False

    # Vücut Ölçüleri & Sağlık / Hedef Notları
    bel: str | None = None
    kalca: str | None = None
    sag_ic_bacak: str | None = None
    sag_bacak: str | None = None
    sol_ic_bacak: str | None = None
    sol_bacak: str | None = None
    sag_kol: str | None = None
    sol_kol: str | None = None
    boy: str | None = None
    kilo: str | None = None
    saglik_notu: str | None = None

    model_config = ConfigDict(from_attributes=True)


class MemberProfileUpdateRequest(BaseModel):
    ad: str | None = None
    bel: str | None = None
    kalca: str | None = None
    sag_ic_bacak: str | None = None
    sag_bacak: str | None = None
    sol_ic_bacak: str | None = None
    sol_bacak: str | None = None
    sag_kol: str | None = None
    sol_kol: str | None = None
    boy: str | None = None
    kilo: str | None = None
    saglik_notu: str | None = None
