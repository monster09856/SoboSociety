from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, Field

from app.schemas.member import ClassTypeResponse, InstructorResponse


class AttendeeResponse(BaseModel):
    booking_id: int
    member_id: int
    ad: str
    telefon: str
    durum: str

    model_config = ConfigDict(from_attributes=True)


class TodaySessionResponse(BaseModel):
    id: int
    baslangic: datetime
    kontenjan: int
    dolu_sayi: int
    durum: str
    class_type: ClassTypeResponse | None = None
    instructor: InstructorResponse | None = None
    katilimcilar: list[AttendeeResponse] = Field(default_factory=list)
    attendees: list[AttendeeResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class QuickBookingRequest(BaseModel):
    telefon: str = Field(..., description="Üyenin cep telefonu numarası")
    session_id: int = Field(..., description="Ders oturumu ID'si")
    ad: str | None = Field(default=None, description="Üye adı (yeni üye oluşturulursa kullanılır)")
    package_id: int | None = Field(default=None, description="Opsiyonel paket ID (paket tanımlanacaksa)")


class AttendanceSubmitRequest(BaseModel):
    session_id: int = Field(..., description="Ders oturumu ID'si")
    gelen_member_ids: list[int] = Field(default_factory=list, description="Derse gelen üye ID'leri listesi")


class AttendanceSubmitResponse(BaseModel):
    gelen: int
    gelmeyen: int


class PackageAssignRequest(BaseModel):
    member_id: int = Field(..., description="Paket tanımlanacak üye ID'si")
    package_id: int = Field(..., description="Tanımlanacak paket ID'si")
    baslangic: date | None = Field(default=None, description="Paket başlangıç tarihi (varsayılan bugün)")


class MemberPackageResponse(BaseModel):
    id: int
    member_id: int
    package_id: int
    baslangic: date
    bitis: date

    model_config = ConfigDict(from_attributes=True)


class SessionGenerateRequest(BaseModel):
    baslangic: date = Field(..., description="Başlangıç tarihi")
    bitis: date = Field(..., description="Bitiş tarihi (dahil)")


class SessionGenerateResponse(BaseModel):
    uretilen_oturum_sayisi: int


class SessionCreateRequest(BaseModel):
    class_type_id: int = Field(..., description="Ders tipi ID'si (1: Barre, 2: Pilates, 3: Yoga)")
    instructor_id: int = Field(..., description="Eğitmen ID'si")
    baslangic: datetime = Field(..., description="Ders başlangıç tarihi ve saati")
    kontenjan: int = Field(default=5, ge=1, description="Ders kontenjan sınırı (varsayılan 5)")
    room_id: int = Field(default=1, description="Salon ID'si")


class MemberUpdateRequest(BaseModel):
    ad: str | None = None
    telefon: str | None = None
    aktif: bool | None = None
    bakiye_override: int | None = Field(default=None, description="Elle kural dışı bakiye tanımlama / düzeltme")


class MemberAdminDetailResponse(BaseModel):
    id: int
    ad: str
    telefon: str
    bakiye: int
    aktif: bool
    is_admin: bool
    toplam_rezervasyon: int = 0

    model_config = ConfigDict(from_attributes=True)


class MemberSinglePushRequest(BaseModel):
    baslik: str
    mesaj: str


class EventCreateRequest(BaseModel):
    baslik: str
    turu: str = "WORKSHOP"  # WORKSHOP | ETKINLIK | KAHVE
    tarih_saat: datetime
    aciklama: str = ""
    kontenjan: int = 15
    ucret: str = "Ücretsiz / Üyelere Özel"


class EventResponse(BaseModel):
    id: int
    baslik: str
    turu: str
    tarih_saat: datetime
    aciklama: str
    kontenjan: int
    ucret: str
    aktif: bool

    model_config = ConfigDict(from_attributes=True)


