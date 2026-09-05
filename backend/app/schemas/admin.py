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
    fiyat_tl: float | None = 900.0
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
    package_id: int | None = Field(default=None, description="Tanımlanacak paket ID'si")
    baslangic: date | None = Field(default=None, description="Paket başlangıç tarihi (varsayılan bugün)")
    ozel_paket_adi: str | None = Field(default=None, description="Özelleştirilmiş paket adı")
    ozel_ders_adedi: int | None = Field(default=None, description="Özelleştirilmiş ders kredisi adedi")
    ozel_gecerlilik_gun: int | None = Field(default=None, description="Özelleştirilmiş geçerlilik gün sayısı")


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
    fiyat_tl: float | None = Field(default=900.0, description="Ders tekil fiyatı TL")
    tek_ders_acik: bool = Field(default=False, description="Sitede üyeliksiz tek ders satışına açık mı?")
    room_id: int = Field(default=1, description="Salon ID'si")


class SessionUpdateRequest(BaseModel):
    baslangic: datetime | None = Field(default=None, description="Ders başlangıç tarihi ve saati")
    class_type_id: int | None = Field(default=None, description="Ders tipi ID'si")
    instructor_id: int | None = Field(default=None, description="Eğitmen ID'si")
    kontenjan: int | None = Field(default=None, description="Ders kontenjan sınırı")
    fiyat_tl: float | None = Field(default=None, description="Ders tekil fiyatı TL")
    tek_ders_acik: bool | None = Field(default=None, description="Sitede üyeliksiz tek ders satışına açık mı?")


class MemberUpdateRequest(BaseModel):
    ad: str | None = None
    telefon: str | None = None
    aktif: bool | None = None
    bakiye_override: int | None = Field(default=None, description="Elle kural dışı bakiye tanımlama / düzeltme")
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


class MemberAdminDetailResponse(BaseModel):
    id: int
    ad: str
    kullanici_adi: str | None = None
    telefon: str | None = None
    bakiye: int
    aktif: bool
    is_admin: bool
    toplam_rezervasyon: int = 0

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

    # Aktif Paket Bilgileri & Paket Geçmişi & Aktif Ders Rezervasyonları
    aktif_member_package_id: int | None = None
    aktif_paket_adi: str | None = None
    paket_bitis_tarihi: str | None = None
    kalan_gun_sayisi: int | None = None
    tanimlanan_paketler: list[str] = Field(default_factory=list)
    aktif_rezervasyonlar: list[str] = Field(default_factory=list)

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
    tek_katilim_acik: bool = True
    tek_katilim_ucret_tl: float | None = 0.0


class EventResponse(BaseModel):
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
    aktif: bool

class AdminCredentialsUpdateRequest(BaseModel):
    yeni_kullanici_adi: str | None = Field(default=None, description="Yeni Yönetici Kullanıcı Adı")
    yeni_sifre: str = Field(..., description="Yeni Yönetici Şifresi")
    mevcut_sifre: str | None = Field(default=None, description="Mevcut Şifre (Güvenlik doğrulaması için)")


class PackageResponse(BaseModel):
    id: int
    ad: str
    ders_adedi: int
    gecerlilik_gun: int
    fiyat_tl: float
    fiyat_kurus: int
    aktif: bool

    model_config = ConfigDict(from_attributes=True)


class PackageCreateUpdateRequest(BaseModel):
    ad: str
    ders_adedi: int
    gecerlilik_gun: int
    fiyat_tl: float | None = 0.0
    aktif: bool = True




