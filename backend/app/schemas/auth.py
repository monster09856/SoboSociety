from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class OTPSendRequest(BaseModel):
    telefon: str = Field(..., description="Üye cep telefonu numarası (örn: +905316033080)")


class OTPSendResponse(BaseModel):
    mesaj: str = Field(default="OTP doğrulama kodu gönderildi")
    telefon: str


class OTPVerifyRequest(BaseModel):
    telefon: str = Field(..., description="Üye cep telefonu numarası")
    kod: str = Field(..., description="6 haneli OTP kodu")


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class MemberMeResponse(BaseModel):
    id: int
    telefon: str
    ad: str
    kvkk_onay_at: datetime | None = None
    katilimci_gorunurluk_onay: bool = False
    aktif: bool = True
    is_admin: bool = False

    model_config = ConfigDict(from_attributes=True)
