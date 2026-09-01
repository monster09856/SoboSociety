from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class ClassTypeResponse(BaseModel):
    id: int
    ad: str
    kontenjan: int
    sure_dk: int
    renk: str
    iptal_penceresi_saat: int

    model_config = ConfigDict(from_attributes=True)


class InstructorResponse(BaseModel):
    id: int
    ad: str
    biyografi: str | None = None
    foto_url: str | None = None

    model_config = ConfigDict(from_attributes=True)


class ClassSessionResponse(BaseModel):
    id: int
    baslangic: datetime
    kontenjan: int
    dolu_sayi: int
    durum: str
    class_type: ClassTypeResponse | None = None
    instructor: InstructorResponse | None = None

    model_config = ConfigDict(from_attributes=True)


class BookingCreateRequest(BaseModel):
    session_id: int = Field(..., description="Rezerve edilecek ders oturumu ID'si")


class BookingResponse(BaseModel):
    id: int
    member_id: int
    session_id: int
    durum: str
    kaynak: str
    cancelled_at: datetime | None = None
    session: ClassSessionResponse | None = None

    model_config = ConfigDict(from_attributes=True)


class WaitlistCreateRequest(BaseModel):
    session_id: int = Field(..., description="Bekleme listesine girilecek ders oturumu ID'si")


class WaitlistResponse(BaseModel):
    id: int
    member_id: int
    session_id: int
    sira: int
    teklif_bitis: datetime | None = None
    kullanildi: bool
    session: ClassSessionResponse | None = None

    model_config = ConfigDict(from_attributes=True)


class MemberSummaryResponse(BaseModel):
    id: int
    ad: str
    telefon: str
    bakiye: int
    aktif_rezervasyonlar: list[BookingResponse] = []
    gecmis_rezervasyonlar: list[BookingResponse] = []

    model_config = ConfigDict(from_attributes=True)
