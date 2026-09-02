import { getToken } from './auth'

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
export async function apiFetch<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken()

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const getBaseUrl = () => {
    if (process.env.NEXT_PUBLIC_API_URL) return process.env.NEXT_PUBLIC_API_URL
    return '/api/v1'
  }
  const baseUrl = getBaseUrl()
  const url = endpoint.startsWith('http')
    ? endpoint
    : `${baseUrl}${endpoint.startsWith('/') ? '' : '/'}${endpoint}`

  try {
    const response = await fetch(url, {
      ...options,
      headers,
    })

    if (!response.ok) {
      let errorDetail: any = null
      let errorMessage = `API hatası: ${response.status} ${response.statusText}`
      try {
        errorDetail = await response.json()
        if (typeof errorDetail.detail === 'string') {
          errorMessage = errorDetail.detail
        } else if (
          Array.isArray(errorDetail.detail) &&
          errorDetail.detail.length > 0
        ) {
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
      throw error
    }
    const message =
      error instanceof Error ? error.message : 'Bağlantı hatası oluştu'
    throw new ApiError(0, message, error)
  }
}

// Auth DTO Types
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
}

export interface TokenResponse {
  access_token: string
  token_type: string
}

export interface MemberMeResponse {
  id: number
  telefon: string
  ad: string
  kvkk_onay_at: string | null
  katilimci_gorunurluk_onay: boolean
  aktif: boolean
  is_admin: boolean
}

// Session & Booking DTO Types
export interface ClassTypeResponse {
  id: number
  ad: string
  kontenjan: number
  sure_dk: number
  renk: string
  iptal_penceresi_saat: number
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

export interface MemberSummaryResponse {
  id: number
  ad: string
  telefon: string
  bakiye: number
  aktif_rezervasyonlar: BookingResponse[]
  gecmis_rezervasyonlar: BookingResponse[]
}

// API Endpoints Namespace
export const api = {
  auth: {
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
  },
  sessions: {
    list: () => apiFetch<ClassSessionResponse[]>('/sessions'),
  },
  bookings: {
    create: (data: BookingCreateRequest) =>
      apiFetch<BookingResponse>('/bookings', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
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
  class_type?: ClassTypeResponse | null
  instructor?: InstructorResponse | null
  katilimcilar: AttendeeResponse[]
  attendees?: AttendeeResponse[]
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
  package_id: number
  baslangic?: string | null
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

export const adminApi = {
  getToday: (tarih?: string) =>
    apiFetch<TodaySessionResponse[]>(
      `/admin/today${tarih ? `?tarih=${encodeURIComponent(tarih)}` : ''}`
    ),
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

