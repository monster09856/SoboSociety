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
    bitis: date | None = Field(default=None, description="Paket bitiş tarihi (opsiyonel)")
    ozel_paket_adi: str | None = Field(default=None, description="Özelleştirilmiş paket adı")
    ozel_ders_adedi: int | None = Field(default=None, description="Özelleştirilmiş ders kredisi adedi")
    ozel_gecerlilik_gun: int | None = Field(default=None, description="Özelleştirilmiş geçerlilik gün sayısı")
    sabit_ders_saatleri: str | None = Field(default=None, description="Haftalık sabit gün ve saatler (örn: Salı, Perşembe 11:30)")
    session_id: int | None = Field(default=None, description="Opsiyonel ilk ders oturumu ID'si")
    borc_bakiye: float | None = Field(default=None, description="Paket tanımlanırken işlenecek borç bakiyesi TL")


class AdminBookSessionRequest(BaseModel):
    session_id: int = Field(..., description="Üyenin kaydedileceği ders oturumu ID'si")
    haftalik_tekrar_sayisi: int = Field(default=1, ge=1, le=16, description="Haftalık tekrarlama sayısı (1=yalnızca bu seans, 4=4 hafta, 8=8 hafta vb.)")


class MemberPackageResponse(BaseModel):
    id: int
    member_id: int
    package_id: int
    baslangic: date
    bitis: date

    model_config = ConfigDict(from_attributes=True)


class MemberPackageUpdateRequest(BaseModel):
    baslangic: date | None = Field(default=None, description="Yeni başlangıç tarihi (YYYY-MM-DD)")
    bitis: date | None = Field(default=None, description="Yeni bitiş tarihi (YYYY-MM-DD)")
    ek_gun: int | None = Field(default=None, description="Mevcut bitişe eklenecek gün sayısı")
    kalan_ders: int | None = Field(default=None, description="Yeni kalan ders adedi")
    paket_adi: str | None = Field(default=None, description="Özel paket adı")
    sabit_ders_saatleri: str | None = Field(default=None, description="Haftalık sabit ders saatleri")


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
    sabit_ders_saatleri: str | None = None
    yeni_sifre: str | None = Field(default=None, description="Üyeye yeni şifre belirleme / sıfırlama")
    borc_bakiye: float | None = Field(default=None, description="Üyenin güncellenen borç bakiyesi TL")


class MemberPackageDetail(BaseModel):
    id: int
    ad: str
    baslangic_tarihi: str
    bitis_tarihi: str
    kalan_gun: int
    toplam_ders: int
    kalan_ders: int = 0
    kategori: str = "Grup"  # "Grup" veya "Bireysel"
    aktif: bool

    model_config = ConfigDict(from_attributes=True)


class ReservedBookingDetail(BaseModel):
    booking_id: int
    session_id: int
    ders_adi: str
    tarih_saat: str
    egitmen: str

    model_config = ConfigDict(from_attributes=True)


class MemberAdminDetailResponse(BaseModel):
    id: int
    ad: str
    kullanici_adi: str | None = None
    telefon: str | None = None
    bakiye: int
    grup_bakiye: int = 0
    bireysel_bakiye: int = 0
    borc_bakiye: float = 0.0
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
    sabit_ders_saatleri: str | None = None
    olcum_sayisi: int = 0

    # Aktif Paket Bilgileri & Paket Geçmişi & Aktif Ders Rezervasyonları
    aktif_member_package_id: int | None = None
    aktif_paket_adi: str | None = None
    paket_baslangic_tarihi: str | None = None
    paket_bitis_tarihi: str | None = None
    kalan_gun_sayisi: int | None = None
    is_bireysel: bool = False
    aktif_paketler: list[MemberPackageDetail] = Field(default_factory=list)
    tanimlanan_paketler: list[str] = Field(default_factory=list)
    aktif_rezervasyonlar: list[str] = Field(default_factory=list)
    rezerve_ders_detaylari: list[ReservedBookingDetail] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class AutoBookFixedScheduleRequest(BaseModel):
    hafta_sayisi: int = Field(default=4, ge=1, le=12, description="Kaç haftalık seans takvime işlenecek (varsayılan 4 hafta)")
    class_type_id: int | None = Field(default=None, description="Opsiyonel özel ders tipi ID'si")
    instructor_id: int | None = Field(default=None, description="Opsiyonel eğitmen ID'si")


class AutoBookFixedScheduleResponse(BaseModel):
    success: bool
    member_id: int
    member_name: str
    is_bireysel: bool
    booked_count: int
    failed_count: int = 0
    kalan_bakiye: int
    dates: list[str]
    message: str


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


class EventRSVPAttendeeResponse(BaseModel):
    rsvp_id: int
    member_id: int
    ad: str
    telefon: str
    tek_katilim: bool = True
    durum: str = "registered"
    created_at: datetime | None = None


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
    katilimcilar: list[EventRSVPAttendeeResponse] = []

class AdminCredentialsUpdateRequest(BaseModel):
    yeni_kullanici_adi: str | None = Field(default=None, description="Yeni Yönetici Kullanıcı Adı")
    yeni_sifre: str = Field(..., description="Yeni Yönetici Şifresi")
    mevcut_sifre: str | None = Field(default=None, description="Mevcut Şifre (Güvenlik doğrulaması için)")


class PackageResponse(BaseModel):
    id: int
    ad: str
    ders_adedi: int
    gecerlilik_gun: int
    fiyat_tl: float | None = None
    fiyat_kurus: int | None = None
    aktif: bool

    model_config = ConfigDict(from_attributes=True)


class PackageCreateUpdateRequest(BaseModel):
    ad: str
    ders_adedi: int
    gecerlilik_gun: int
    fiyat_tl: float | None = 0.0
    aktif: bool = True




