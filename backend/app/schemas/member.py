from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class ClassTypeResponse(BaseModel):
    id: int
    ad: str
    kontenjan: int
    sure_dk: int
    renk: str
    iptal_penceresi_saat: int
    fiyat_tl: float | None = 900.0
    tek_ders_acik: bool = False

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
    fiyat_tl: float | None = 900.0
    tek_ders_acik: bool = False
    class_type: ClassTypeResponse | None = None
    instructor: InstructorResponse | None = None

    model_config = ConfigDict(from_attributes=True)


class BookingCreateRequest(BaseModel):
    session_id: int = Field(..., description="Rezerve edilecek ders oturumu ID'si")


class GuestBookingRequest(BaseModel):
    session_id: int = Field(..., description="Rezerve edilecek ders oturumu ID'si")
    ad: str = Field(..., description="Müşteri Ad Soyad")
    telefon: str = Field(..., description="Müşteri Cep Telefonu")


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
    kullanici_adi: str | None = None
    telefon: str | None = None
    bakiye: int
    aktif_rezervasyonlar: list[BookingResponse] = []
    gecmis_rezervasyonlar: list[BookingResponse] = []

    model_config = ConfigDict(from_attributes=True)


class StudioEventResponse(BaseModel):
    id: int
    baslik: str
    turu: str
    tarih_saat: datetime
    aciklama: str
    kontenjan: int
    dolu_sayi: int = 0
    ucret: str
    tek_katilim_acik: bool = True
    tek_katilim_ucret_tl: float | None = 0.0
    aktif: bool = True
    is_registered: bool = False

    model_config = ConfigDict(from_attributes=True)


class StudioEventCreateRequest(BaseModel):
    baslik: str
    turu: str = "WORKSHOP"
    tarih_saat: datetime
    aciklama: str = ""
    kontenjan: int = 15
    ucret: str = "Ücretsiz / Üyelere Özel"
    tek_katilim_acik: bool = True
    tek_katilim_ucret_tl: float | None = 0.0


class MeasurementCreateRequest(BaseModel):
    bel: str | None = None
    kalca: str | None = None
    kilo: str | None = None
    boy: str | None = None
    sag_bacak: str | None = None
    sol_bacak: str | None = None
    sag_kol: str | None = None
    sol_kol: str | None = None
    saglik_notu: str | None = None


class MeasurementHistoryResponse(BaseModel):
    id: int
    tarih: datetime
    bel: str | None = None
    kalca: str | None = None
    kilo: str | None = None
    boy: str | None = None
    sag_bacak: str | None = None
    sol_bacak: str | None = None
    sag_kol: str | None = None
    sol_kol: str | None = None

    model_config = ConfigDict(from_attributes=True)


class MemberStatsResponse(BaseModel):
    completed_this_month: int = 0
    total_attended: int = 0
    current_streak_weeks: int = 0
    badges: list[str] = []

