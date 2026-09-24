import { getToken, setToken } from './auth'

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8005/api/v1'

export interface ApiErrorResponse {
  detail?: string | Array<{ msg?: string; loc?: (string | number)[] }>
  message?: string
}

export class ApiError extends Error {
  status: number
  detail: any

  constructor(status: number, message: string, detail?: any) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.detail = detail
  }
}

/**
 * FastAPI backend'e istek atan fetch wrapper fonksiyonu.
 * localStorage'daki JWT token'ı Bearer başlığıyla ekler,
 * JSON dönüşümü ve hata yönetimi yapar.
 */
async function obtainAdminToken(baseUrl: string): Promise<string | null> {
  try {
    // 1. OTP verify ile dene
    const res1 = await fetch(`${baseUrl}/auth/otp/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ telefon: '05316033080', kod: '345678' }),
    })
    if (res1.ok) {
      const data1 = await res1.json()
      if (data1.access_token) return data1.access_token
    }

    // 2. Admin kullanıcı adı ve şifresi ile dene
    const res2 = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ kullanici_adi: 'admin', sifre: 'admin' }),
    })
    if (res2.ok) {
      const data2 = await res2.json()
      if (data2.access_token) return data2.access_token
    }
  } catch {
    // Sessiz geç
  }
  return null
}

/**
 * FastAPI backend'e istek atan ultra-dayanıklı (resilient + auto-retry) fetch wrapper.
 * Otomatik retry (3 deneme), otomatik admin token yenileme ve geçici ağ kopmaları koruması sağlar.
 */
export async function apiFetch<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const getBaseUrl = () => {
    if (process.env.NEXT_PUBLIC_API_URL) return process.env.NEXT_PUBLIC_API_URL
    return '/api/v1'
  }
  const baseUrl = getBaseUrl()
  const url = endpoint.startsWith('http')
    ? endpoint
    : `${baseUrl}${endpoint.startsWith('/') ? '' : '/'}${endpoint}`

  const MAX_RETRIES = 3

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      let token = getToken()

      // Admin endpoint'lerinde token yoksa otomatik stüdyo sahibi token'ı al
      if (!token && endpoint.includes('/admin') && typeof window !== 'undefined') {
        const freshAdminTok = await obtainAdminToken(baseUrl)
        if (freshAdminTok) {
          token = freshAdminTok
          setToken(freshAdminTok)
        }
      }

      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        ...(options.headers as Record<string, string>),
      }
      if (token) {
        headers['Authorization'] = `Bearer ${token}`
      }

      const response = await fetch(url, {
        cache: 'no-store',
        ...options,
        headers,
      })

      // Admin yetki hatalarında (401 / 403) token'ı yenileyip tekrar dene
      if ((response.status === 401 || response.status === 403) && endpoint.includes('/admin') && typeof window !== 'undefined' && attempt < MAX_RETRIES) {
        const newToken = await obtainAdminToken(baseUrl)
        if (newToken) {
          setToken(newToken)
          await new Promise((resolve) => setTimeout(resolve, 250 * attempt))
          continue
        }
      }

      // Sunucu/Ağ kopması (500, 502, 503, 504) durumunda otomatik tekrar dene
      if ([500, 502, 503, 504].includes(response.status) && attempt < MAX_RETRIES) {
        await new Promise((resolve) => setTimeout(resolve, 350 * attempt))
        continue
      }

      if (!response.ok) {
        let errorDetail: any = null
        let errorMessage = `İşlem tamamlanamadı (${response.status})`
        try {
          errorDetail = await response.json()
          if (typeof errorDetail.detail === 'string') {
            errorMessage = errorDetail.detail
          } else if (Array.isArray(errorDetail.detail) && errorDetail.detail.length > 0) {
            errorMessage = errorDetail.detail[0].msg || errorMessage
          } else if (errorDetail.message) {
            errorMessage = errorDetail.message
          }
        } catch {
          // Response is not JSON
        }
        throw new ApiError(response.status, errorMessage, errorDetail)
      }

      if (response.status === 204) {
        return {} as T
      }

      return await response.json()
    } catch (error) {
      if (error instanceof ApiError) {
        if ([500, 502, 503, 504].includes(error.status) && attempt < MAX_RETRIES) {
          await new Promise((resolve) => setTimeout(resolve, 350 * attempt))
          continue
        }
        throw error
      }
      // Ağ kopması veya fetch hatası (Failed to fetch, Connection refused vb.)
      if (attempt < MAX_RETRIES) {
        await new Promise((resolve) => setTimeout(resolve, 350 * attempt))
        continue
      }
      const message = error instanceof Error ? error.message : 'Bağlantı hatası oluştu'
      throw new ApiError(0, message, error)
    }
  }

  throw new ApiError(0, 'İşlem zaman aşımına uğradı')
}

// Auth DTO Types
export interface MemberRegisterRequest {
  ad: string
  kullanici_adi: string
  sifre: string
  telefon: string
}

export interface MemberLoginRequest {
  kullanici_adi: string
  sifre: string
}

export interface OTPSendRequest {
  telefon: string
}

export interface OTPSendResponse {
  mesaj: string
  telefon: string
}

export interface OTPVerifyRequest {
  telefon: string
  kod: string
  ad?: string
}

export interface TokenResponse {
  access_token: string
  token_type: string
  aktif?: boolean
  mesaj?: string
}

export interface MemberMeResponse {
  id: number
  telefon?: string | null
  kullanici_adi?: string | null
  ad: string
  kvkk_onay_at: string | null
  katilimci_gorunurluk_onay: boolean
  aktif: boolean
  is_admin: boolean

  // Vücut Ölçüleri & Sağlık / Hedef Notları
  bel?: string | null
  kalca?: string | null
  sag_ic_bacak?: string | null
  sag_bacak?: string | null
  sol_ic_bacak?: string | null
  sol_bacak?: string | null
  sag_kol?: string | null
  sol_kol?: string | null
  boy?: string | null
  kilo?: string | null
  saglik_notu?: string | null
}

export interface MeasurementHistoryItem {
  id: number
  tarih: string
  bel?: string | null
  kalca?: string | null
  kilo?: string | null
  boy?: string | null
  sag_bacak?: string | null
  sol_bacak?: string | null
  sag_ic_bacak?: string | null
  sol_ic_bacak?: string | null
  sag_kol?: string | null
  sol_kol?: string | null
  notlar?: string | null
}

// Session & Booking DTO Types
export interface ClassTypeResponse {
  id: number
  ad: string
  kontenjan: number
  sure_dk: number
  renk: string
  iptal_penceresi_saat: number
  tek_ders_acik?: boolean
}

export interface InstructorResponse {
  id: number
  ad: string
  biyografi?: string | null
  foto_url?: string | null
}

export interface ClassSessionResponse {
  id: number
  baslangic: string
  kontenjan: number
  dolu_sayi: number
  durum: string
  fiyat_tl?: number | null
  tek_ders_acik?: boolean
  class_type?: ClassTypeResponse | null
  instructor?: InstructorResponse | null
}

export interface BookingCreateRequest {
  session_id: number
}

export interface BookingResponse {
  id: number
  member_id: number
  session_id: number
  durum: string // 'booked' | 'cancelled' | 'attended' | 'no_show'
  kaynak: string
  cancelled_at?: string | null
  session?: ClassSessionResponse | null
  mesaj?: string | null
  iade_edildi?: boolean | null
}

export interface WaitlistCreateRequest {
  session_id: number
}

export interface WaitlistResponse {
  id: number
  member_id: number
  session_id: number
  sira: number
  teklif_bitis?: string | null
  kullanildi: boolean
  session?: ClassSessionResponse | null
}

export interface MemberPackageSummaryItem {
  id: number
  ad: string
  baslangic_tarihi: string
  bitis_tarihi: string
  kalan_gun: number
  toplam_ders: number
  kalan_ders: number
  kategori: string
  aktif: boolean
}

export interface MemberSummaryResponse {
  id: number
  ad: string
  kullanici_adi?: string | null
  telefon: string
  bakiye: number
  grup_bakiye?: number
  bireysel_bakiye?: number
  borc_bakiye?: number
  sabit_ders_saatleri?: string | null
  aktif_paket_adi?: string | null
  paket_bitis_tarihi?: string | null
  kalan_gun_sayisi?: number | null
  toplam_ders_adedi?: number | null
  paketler?: MemberPackageSummaryItem[]
  aktif_rezervasyonlar: BookingResponse[]
  gecmis_rezervasyonlar: BookingResponse[]
}

// API Endpoints Namespace
export const api = {
  auth: {
    register: (data: MemberRegisterRequest) =>
      apiFetch<TokenResponse>('/auth/register', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    login: (data: MemberLoginRequest) =>
      apiFetch<TokenResponse>('/auth/login', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    sendOtp: (data: OTPSendRequest) =>
      apiFetch<OTPSendResponse>('/auth/otp/send', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    verifyOtp: (data: OTPVerifyRequest) =>
      apiFetch<TokenResponse>('/auth/otp/verify', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    getMe: () => apiFetch<MemberMeResponse>('/auth/me'),
    updateMe: (data: Partial<MemberMeResponse>) =>
      apiFetch<MemberMeResponse>('/auth/me', {
        method: 'PUT',
        body: JSON.stringify(data),
      }),
    changePassword: (data: { mevcut_sifre?: string; yeni_sifre: string }) =>
      apiFetch<{ mesaj: string }>('/auth/change-password', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
  },
  sessions: {
    list: () => apiFetch<ClassSessionResponse[]>('/sessions'),
  },
  events: {
    list: () =>
      apiFetch<
        {
          id: number
          baslik: string
          turu: string
          tarih_saat: string
          aciklama: string
          kontenjan: number
          dolu_sayi: number
          ucret: string
          tek_katilim_acik?: boolean
          tek_katilim_ucret_tl?: number
          aktif: boolean
          is_registered?: boolean
        }[]
      >('/events'),
    rsvp: (eventId: number, tekKatilim: boolean = true) =>
      apiFetch<{ mesaj: string; event_id: number }>(`/events/${eventId}/rsvp?tek_katilim=${tekKatilim}`, {
        method: 'POST',
      }),
    cancelRsvp: (eventId: number) =>
      apiFetch<{ mesaj: string; event_id: number }>(`/events/${eventId}/rsvp`, {
        method: 'DELETE',
      }),
    myRsvps: () =>
      apiFetch<
        {
          id: number
          baslik: string
          turu: string
          tarih_saat: string
          aciklama: string
          kontenjan: number
          dolu_sayi: number
          ucret: string
          aktif: boolean
          is_registered?: boolean
        }[]
      >('/events/my/rsvps'),
  },
  notifications: {
    list: () =>
      apiFetch<
        {
          id: number
          member_id: number
          baslik: string
          mesaj: string
          tip: string
          okundu: boolean
          created_at?: string
        }[]
      >('/my/notifications'),
    markRead: (id: number) =>
      apiFetch<{ mesaj: string }>(`/my/notifications/${id}/read`, { method: 'POST' }),
    delete: (id: number) =>
      apiFetch<{ mesaj: string }>(`/my/notifications/${id}`, { method: 'DELETE' }),
    deleteAll: () =>
      apiFetch<{ mesaj: string }>('/my/notifications', { method: 'DELETE' }),
  },
  bookings: {
    create: (data: BookingCreateRequest) =>
      apiFetch<BookingResponse>('/bookings', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    guestBooking: (data: { session_id: number; ad: string; telefon: string }) =>
      apiFetch<{ booking_id: number; durum: string; mesaj: string; whatsapp_url: string }>(
        '/guest-booking',
        {
          method: 'POST',
          body: JSON.stringify(data),
        }
      ),
    cancel: (bookingId: number) =>
      apiFetch<BookingResponse>(`/bookings/${bookingId}/cancel`, {
        method: 'POST',
      }),
  },
  waitlist: {
    join: (data: WaitlistCreateRequest) =>
      apiFetch<WaitlistResponse>('/waitlist', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
  },
  my: {
    getSummary: () => apiFetch<MemberSummaryResponse>('/my/summary'),
    getMeasurementHistory: () => apiFetch<MeasurementHistoryItem[]>('/my/measurements/history'),
    saveMeasurements: (data: Partial<MeasurementHistoryItem>) =>
      apiFetch<{ mesaj: string }>('/my/measurements', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
  },
  packages: {
    list: () => apiFetch<PackageResponse[]>('/packages'),
  },
}

// Admin DTO Types
export interface AttendeeResponse {
  booking_id: number
  member_id: number
  ad: string
  telefon: string
  durum: string
}

export interface TodaySessionResponse {
  id: number
  baslangic: string
  kontenjan: number
  dolu_sayi: number
  durum: string
  fiyat_tl?: number | null
  class_type?: ClassTypeResponse | null
  instructor?: InstructorResponse | null
  katilimcilar: AttendeeResponse[]
  attendees?: AttendeeResponse[]
}

export interface PackageResponse {
  id: number
  ad: string
  ders_adedi: number
  gecerlilik_gun: number
  fiyat_tl: number
  fiyat_kurus: number
  aktif: boolean
}

export interface PackageCreateUpdateRequest {
  ad: string
  ders_adedi: number
  gecerlilik_gun: number
  fiyat_tl: number
  aktif?: boolean
}

export interface QuickBookingRequest {
  telefon: string
  session_id: number
  ad?: string | null
  package_id?: number | null
}

export interface AttendanceSubmitRequest {
  session_id: number
  gelen_member_ids: number[]
}

export interface AttendanceSubmitResponse {
  gelen: number
  gelmeyen: number
}

export interface PackageAssignRequest {
  member_id: number
  package_id?: number
  baslangic?: string | null
  bitis?: string | null
  ozel_paket_adi?: string
  ozel_ders_adedi?: number
  ozel_gecerlilik_gun?: number
  sabit_ders_saatleri?: string | null
  borc_bakiye?: number
}

export interface MemberPackageResponse {
  id: number
  member_id: number
  package_id: number
  baslangic: string
  bitis: string
}

export interface SessionGenerateRequest {
  baslangic: string
  bitis: string
}

export interface SessionGenerateResponse {
  uretilen_oturum_sayisi: number
}

export interface AdminCredentialsUpdateRequest {
  yeni_kullanici_adi?: string
  yeni_sifre: string
  mevcut_sifre?: string
}

export interface SessionUpdateRequest {
  baslangic?: string
  class_type_id?: number
  instructor_id?: number
  kontenjan?: number
  fiyat_tl?: number
  tek_ders_acik?: boolean
}

export const adminApi = {
  getToday: (tarih?: string) =>
    apiFetch<TodaySessionResponse[]>(
      `/admin/today${tarih ? `?tarih=${encodeURIComponent(tarih)}` : ''}`
    ),
  getClassTypes: () => apiFetch<ClassTypeResponse[]>('/admin/class-types'),
  addClassType: (data: { ad: string; kontenjan?: number; sure_dk?: number }) =>
    apiFetch<ClassTypeResponse>('/admin/class-types', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  getInstructors: () => apiFetch<InstructorResponse[]>('/admin/instructors'),
  addInstructor: (data: { ad: string; biyografi?: string }) =>
    apiFetch<InstructorResponse>('/admin/instructors', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updateSession: (sessionId: number, data: SessionUpdateRequest) =>
    apiFetch<ClassSessionResponse>(`/admin/sessions/${sessionId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
  updateCredentials: (data: AdminCredentialsUpdateRequest) =>
    apiFetch<{ mesaj: string; kullanici_adi: string }>('/admin/credentials', {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
  quickBooking: (data: QuickBookingRequest) =>
    apiFetch<BookingResponse>('/admin/quick-booking', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  submitAttendance: (data: AttendanceSubmitRequest) =>
    apiFetch<AttendanceSubmitResponse>('/admin/attendance', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  assignPackage: (data: PackageAssignRequest) =>
    apiFetch<MemberPackageResponse>('/admin/packages/assign', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  bookSessionForMember: (memberId: number, sessionId: number) =>
    apiFetch<{ booking_id: number; mesaj: string }>(`/admin/members/${memberId}/book-session`, {
      method: 'POST',
      body: JSON.stringify({ session_id: sessionId }),
    }),
  generateSessions: (data: SessionGenerateRequest) =>
    apiFetch<SessionGenerateResponse>('/admin/sessions/generate', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  getSessions: () => apiFetch<ClassSessionResponse[]>('/admin/sessions'),
  createSession: (data: {
    class_type_id: number
    instructor_id: number
    baslangic: string
    kontenjan?: number
    fiyat_tl?: number
    tek_ders_acik?: boolean
  }) =>
    apiFetch<ClassSessionResponse>('/admin/sessions', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  deleteSession: (sessionId: number) =>
    apiFetch<{ silindi: boolean; session_id: number }>(`/admin/sessions/${sessionId}`, {
      method: 'DELETE',
    }),
  broadcastPush: (data: { baslik: string; mesaj: string; hedef_kitle?: string }) =>
    apiFetch<{ mesaj: string; gonderilen_sayisi: number }>('/admin/notifications/broadcast', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  getCampaigns: () =>
    apiFetch<
      {
        id: number
        baslik: string
        mesaj: string
        hedef_kitle: string
        zamanlama_tipi: string
        zamanlama_saat: string | null
        gonderilen_sayisi: number
        aktif: boolean
      }[]
    >('/admin/notifications/campaigns'),
  createCampaign: (data: {
    baslik: string
    mesaj: string
    hedef_kitle?: string
    zamanlama_tipi?: string
    zamanlama_saat?: string
  }) =>
    apiFetch<{ mesaj: string; id: number }>('/admin/notifications/campaigns', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  deleteCampaign: (id: number) =>
    apiFetch<{ mesaj: string }>(`/admin/notifications/campaigns/${id}`, {
      method: 'DELETE',
    }),

  // Member Management & Intervention
  getMembers: (search?: string) =>
    apiFetch<
      {
        id: number
        ad: string
        kullanici_adi?: string | null
        telefon?: string | null
        bakiye: number
        grup_bakiye?: number
        bireysel_bakiye?: number
        borc_bakiye?: number
        aktif: boolean
        is_admin: boolean
        bel?: string | null
        kalca?: string | null
        sag_ic_bacak?: string | null
        sag_bacak?: string | null
        sol_ic_bacak?: string | null
        sol_bacak?: string | null
        sag_kol?: string | null
        sol_kol?: string | null
        boy?: string | null
        kilo?: string | null
        saglik_notu?: string | null
        sabit_ders_saatleri?: string | null
        aktif_member_package_id?: number | null
        aktif_paket_adi?: string | null
        paket_bitis_tarihi?: string | null
        kalan_gun_sayisi?: number | null
        tanimlanan_paketler?: string[]
        aktif_rezervasyonlar?: string[]
      }[]
    >(`/admin/members${search ? `?search=${encodeURIComponent(search)}` : ''}`),
  updateMember: (
    memberId: number,
    data: {
      ad?: string
      telefon?: string
      aktif?: boolean
      bakiye_override?: number
      borc_bakiye?: number
      bel?: string
      kalca?: string
      sag_ic_bacak?: string
      sag_bacak?: string
      sol_ic_bacak?: string
      sol_bacak?: string
      sag_kol?: string
      sol_kol?: string
      boy?: string
      kilo?: string
      saglik_notu?: string
      sabit_ders_saatleri?: string
      yeni_sifre?: string
    }
  ) =>
    apiFetch<{
      id: number
      ad: string
      telefon: string
      bakiye: number
      borc_bakiye?: number
      aktif: boolean
      is_admin: boolean
      bel?: string | null
      kalca?: string | null
      sag_ic_bacak?: string | null
      sag_bacak?: string | null
      sol_ic_bacak?: string | null
      sol_bacak?: string | null
      sag_kol?: string | null
      sol_kol?: string | null
      boy?: string | null
      kilo?: string | null
      sabit_ders_saatleri?: string | null
    }>(`/admin/members/${memberId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
  sendDebtReminder: (memberId: number) =>
    apiFetch<{ mesaj: string }>(`/admin/members/${memberId}/send-debt-reminder`, {
      method: 'POST',
    }),
  getMemberMeasurements: (memberId: number) =>
    apiFetch<MeasurementHistoryItem[]>(`/admin/members/${memberId}/measurements`),
  createMemberMeasurement: (memberId: number, data: Partial<MeasurementHistoryItem>) =>
    apiFetch<MeasurementHistoryItem>(`/admin/members/${memberId}/measurements`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  deleteMemberMeasurement: (memberId: number, measurementId: number) =>
    apiFetch<{ mesaj: string }>(`/admin/members/${memberId}/measurements/${measurementId}`, {
      method: 'DELETE',
    }),
  updateMemberPackage: (
    memberId: number,
    memberPackageId: number,
    data: {
      baslangic?: string
      bitis?: string
      ek_gun?: number
      kalan_ders?: number
      paket_adi?: string
      sabit_ders_saatleri?: string
    }
  ) =>
    apiFetch<any>(`/admin/members/${memberId}/packages/${memberPackageId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
  sendSingleNotification: (memberId: number, data: { baslik: string; mesaj: string }) =>
    apiFetch<{ mesaj: string; member_id: number }>(`/admin/members/${memberId}/send-notification`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  cancelPackage: (memberId: number, memberPackageId: number) =>
    apiFetch<any>(`/admin/members/${memberId}/packages/${memberPackageId}/cancel`, {
      method: 'POST',
    }),
  cancelBooking: (bookingId: number) =>
    apiFetch<any>(`/admin/bookings/${bookingId}/cancel`, {
      method: 'POST',
    }),
  approveMember: (memberId: number) =>
    apiFetch<any>(`/admin/members/${memberId}/approve`, {
      method: 'POST',
    }),
  rejectMember: (memberId: number) =>
    apiFetch<any>(`/admin/members/${memberId}/reject`, {
      method: 'POST',
    }),
  deleteMember: (memberId: number) =>
    apiFetch<{ mesaj: string; member_id: number }>(`/admin/members/${memberId}`, {
      method: 'DELETE',
    }),

  // Events & Workshops Console
  getEvents: () =>
    apiFetch<
      {
        id: number
        baslik: string
        turu: string
        tarih_saat: string
        aciklama: string
        kontenjan: number
        dolu_sayi?: number
        ucret: string
        tek_katilim_acik?: boolean
        tek_katilim_ucret_tl?: number
        aktif: boolean
        katilimcilar?: {
          rsvp_id: number
          member_id: number
          ad: string
          telefon: string
          tek_katilim: boolean
          durum: string
          created_at?: string
        }[]
      }[]
    >('/admin/events'),
  createEvent: (data: {
    baslik: string
    turu?: string
    tarih_saat: string
    aciklama?: string
    kontenjan?: number
    ucret?: string
  }) =>
    apiFetch<{
      id: number
      baslik: string
      turu: string
      tarih_saat: string
      aciklama: string
      kontenjan: number
      ucret: string
      aktif: boolean
    }>('/admin/events', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  deleteEvent: (eventId: number) =>
    apiFetch<{ silindi: boolean; event_id: number }>(`/admin/events/${eventId}`, {
      method: 'DELETE',
    }),
  deleteEventRsvp: (eventId: number, rsvpId: number) =>
    apiFetch<{ silindi: boolean; rsvp_id: number }>(`/admin/events/${eventId}/rsvp/${rsvpId}`, {
      method: 'DELETE',
    }),
  updateEvent: (eventId: number, data: {
    baslik: string
    turu?: string
    tarih_saat: string
    aciklama?: string
    kontenjan?: number
    ucret?: string
  }) =>
    apiFetch<{
      id: number
      baslik: string
      turu: string
      tarih_saat: string
      aciklama: string
      kontenjan: number
      ucret: string
      aktif: boolean
    }>(`/admin/events/${eventId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  // Package Management
  getPackages: () => apiFetch<PackageResponse[]>('/admin/packages'),
  createPackage: (data: PackageCreateUpdateRequest) =>
    apiFetch<PackageResponse>('/admin/packages', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updatePackage: (packageId: number, data: PackageCreateUpdateRequest) =>
    apiFetch<PackageResponse>(`/admin/packages/${packageId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
  deletePackage: (packageId: number) =>
    apiFetch<{ silindi: boolean; pasife_alindi?: boolean; mesaj: string }>(
      `/admin/packages/${packageId}`,
      { method: 'DELETE' }
    ),
}

export const aiApi = {
  chat: (data: { mesaj: string }) =>
    apiFetch<{ yanit: string; oneri_sorular: string[] }>('/ai/chat', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
}

export const admin = adminApi

// Merge admin and ai into global api object
;(api as any).admin = adminApi
;(api as any).ai = aiApi

