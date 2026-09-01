'use client'

import React, { useEffect, useState, useMemo } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import {
  api,
  ClassSessionResponse,
  MemberSummaryResponse,
  BookingResponse,
  ApiError,
} from '@/lib/api'
import { getToken } from '@/lib/auth'
import { CreditBadge } from '@/components/uye/credit-badge'
import { SessionCard } from '@/components/uye/session-card'
import { Button } from '@/components/ui/button'
import {
  Calendar as CalendarIcon,
  User,
  AlertCircle,
  CheckCircle2,
  Loader2,
  LogIn,
  RefreshCw,
  Sparkles,
} from 'lucide-react'

function formatDateKey(date: Date): string {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function getGunAdi(date: Date): string {
  const gunler = ['Pzr', 'Pzt', 'Sal', 'Çrş', 'Prş', 'Cum', 'Cmt']
  return gunler[date.getDay()]
}

function getAyAdi(date: Date): string {
  const aylar = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ]
  return aylar[date.getMonth()]
}

export default function RezervasyonPage() {
  const router = useRouter()
  const [isLoggedIn, setIsLoggedIn] = useState<boolean>(false)
  const [sessions, setSessions] = useState<ClassSessionResponse[]>([])
  const [summary, setSummary] = useState<MemberSummaryResponse | null>(null)
  const [loading, setLoading] = useState<boolean>(true)
  const [actionLoadingId, setActionLoadingId] = useState<number | null>(null)
  const [notification, setNotification] = useState<{
    type: 'success' | 'error'
    message: string
  } | null>(null)

  // Generate 14 days starting from today
  const days = useMemo(() => {
    const list = []
    const today = new Date()
    for (let i = 0; i < 14; i++) {
      const d = new Date(today)
      d.setDate(today.getDate() + i)
      list.push(d)
    }
    return list
  }, [])

  const [selectedDateKey, setSelectedDateKey] = useState<string>(
    formatDateKey(new Date())
  )

  const fetchData = async () => {
    setLoading(true)
    setNotification(null)
    const token = getToken()
    setIsLoggedIn(!!token)

    try {
      const sessionsData = await api.sessions.list()
      setSessions(sessionsData)

      if (token) {
        try {
          const summaryData = await api.my.getSummary()
          setSummary(summaryData)
        } catch (err) {
          console.error('Failed to load member summary:', err)
        }
      }
    } catch (err) {
      console.error('Failed to load sessions:', err)
      const msg = err instanceof ApiError ? err.message : 'Dersler yüklenirken bir hata oluştu.'
      setNotification({ type: 'error', message: msg })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [])

  const handleBook = async (sessionId: number) => {
    if (!isLoggedIn) {
      router.push('/giris')
      return
    }
    setActionLoadingId(sessionId)
    setNotification(null)
    try {
      await api.bookings.create({ session_id: sessionId })
      setNotification({
        type: 'success',
        message: 'Ders rezervasyonunuz başarıyla tamamlandı.',
      })
      await fetchData()
    } catch (err) {
      const msg =
        err instanceof ApiError ? err.message : 'Rezervasyon yapılırken hata oluştu.'
      setNotification({ type: 'error', message: msg })
    } finally {
      setActionLoadingId(null)
    }
  }

  const handleCancel = async (bookingId: number) => {
    setActionLoadingId(bookingId)
    setNotification(null)
    try {
      await api.bookings.cancel(bookingId)
      setNotification({
        type: 'success',
        message: 'Rezervasyonunuz başarıyla iptal edildi.',
      })
      await fetchData()
    } catch (err) {
      const msg =
        err instanceof ApiError ? err.message : 'İptal işlemi sırasında hata oluştu.'
      setNotification({ type: 'error', message: msg })
    } finally {
      setActionLoadingId(null)
    }
  }

  const handleWaitlist = async (sessionId: number) => {
    if (!isLoggedIn) {
      router.push('/giris')
      return
    }
    setActionLoadingId(sessionId)
    setNotification(null)
    try {
      const res = await api.waitlist.join({ session_id: sessionId })
      setNotification({
        type: 'success',
        message: `Bekleme listesine eklendiniz. Sıranız: ${res.sira}`,
      })
      await fetchData()
    } catch (err) {
      const msg =
        err instanceof ApiError ? err.message : 'Bekleme listesine girerken hata oluştu.'
      setNotification({ type: 'error', message: msg })
    } finally {
      setActionLoadingId(null)
    }
  }

  // Active bookings map indexed by session_id
  const activeBookingsMap = useMemo(() => {
    const map = new Map<number, BookingResponse>()
    if (summary?.aktif_rezervasyonlar) {
      summary.aktif_rezervasyonlar.forEach((b) => {
        if (b.durum === 'booked') {
          map.set(b.session_id, b)
        }
      })
    }
    return map
  }, [summary])

  // Filter sessions for selected date
  const filteredSessions = useMemo(() => {
    return sessions.filter((s) => {
      const d = new Date(s.baslangic)
      return formatDateKey(d) === selectedDateKey
    })
  }, [sessions, selectedDateKey])

  const selectedDateObj = useMemo(() => {
    return days.find((d) => formatDateKey(d) === selectedDateKey) || new Date()
  }, [days, selectedDateKey])

  return (
    <div className="min-h-screen bg-ivory text-ink flex flex-col antialiased">
      {/* Top Header - Mobile First Sticky Navbar */}
      <header className="sticky top-0 z-30 bg-ivory/95 backdrop-blur-md border-b border-line px-4 py-3 shadow-xs">
        <div className="max-w-md mx-auto flex items-center justify-between">
          <Link href="/" className="group flex items-center gap-2">
            <span className="w-8 h-8 rounded-full bg-espresso text-ivory flex items-center justify-center font-serif font-bold text-base shadow-xs">
              S
            </span>
            <span className="font-serif text-2xl font-bold tracking-widest text-espresso uppercase">
              SOBO
            </span>
          </Link>

          <div className="flex items-center gap-2.5">
            {isLoggedIn ? (
              <>
                <CreditBadge credits={summary?.bakiye ?? 0} />
                <Link href="/hesabim">
                  <Button variant="ghost" size="icon" className="rounded-full hover:bg-sand border border-line">
                    <User className="w-5 h-5 text-espresso" />
                  </Button>
                </Link>
              </>
            ) : (
              <Link href="/giris">
                <Button size="sm" className="gap-1.5 text-xs font-bold bg-espresso hover:bg-espresso-dark text-ivory border-none shadow-xs rounded-full px-4">
                  <LogIn className="w-3.5 h-3.5" />
                  Giriş Yap
                </Button>
              </Link>
            )}
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 max-w-md w-full mx-auto px-4 py-6 space-y-6">
        {/* Dynamic Balance Banner / Member greeting */}
        {isLoggedIn && summary && (
          <div className="p-4 rounded-2xl bg-sand/80 border border-line flex items-center justify-between shadow-xs">
            <div className="space-y-0.5">
              <p className="text-xs text-secondary font-medium">Hoş geldiniz,</p>
              <p className="font-serif text-lg font-bold text-ink">{summary.ad}</p>
            </div>
            <div className="text-right">
              <span className="text-[11px] uppercase font-bold text-secondary block">Kullanılabilir Bakiye</span>
              <span className="font-serif text-xl font-extrabold text-espresso">
                {summary.bakiye} Ders Kredisi
              </span>
            </div>
          </div>
        )}

        {/* Title Section */}
        <div className="flex items-end justify-between">
          <div>
            <div className="flex items-center gap-1.5 text-xs font-bold text-mocha uppercase tracking-widest">
              <Sparkles className="w-3.5 h-3.5 text-mocha" />
              <span>Canlı Ders Takvimi</span>
            </div>
            <h1 className="font-serif text-2xl font-bold text-ink tracking-wide mt-0.5">
              DERS PROGRAMI
            </h1>
            <p className="text-xs text-secondary font-medium">
              {selectedDateObj.getDate()} {getAyAdi(selectedDateObj)}{' '}
              {selectedDateObj.getFullYear()}
            </p>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={fetchData}
            disabled={loading}
            className="text-secondary hover:text-espresso hover:bg-sand rounded-xl"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-espresso' : ''}`} />
          </Button>
        </div>

        {/* Canlı Gün Seçim Hapları (Active Day Selector Ribbon) */}
        <div className="relative">
          <div className="flex items-center gap-2.5 overflow-x-auto pb-3 pt-1 scrollbar-none snap-x">
            {days.map((date) => {
              const key = formatDateKey(date)
              const isSelected = key === selectedDateKey
              const dayName = getGunAdi(date)
              const dayNum = date.getDate()
              const isToday = formatDateKey(new Date()) === key

              return (
                <button
                  key={key}
                  onClick={() => setSelectedDateKey(key)}
                  className={`flex flex-col items-center justify-center min-w-[58px] h-[72px] rounded-2xl transition-all duration-200 snap-start border cursor-pointer ${
                    isSelected
                      ? 'bg-espresso text-ivory shadow-xs scale-105 border-none font-bold'
                      : 'bg-sand/70 text-ink border-line hover:border-mocha/60 hover:bg-sand'
                  }`}
                >
                  <span
                    className={`text-[10px] uppercase font-bold tracking-wider ${
                      isSelected ? 'text-ivory/80' : 'text-secondary'
                    }`}
                  >
                    {isToday ? 'BUGÜN' : dayName}
                  </span>
                  <span
                    className={`font-serif text-2xl font-extrabold mt-0.5 ${
                      isSelected ? 'text-ivory' : 'text-ink'
                    }`}
                  >
                    {dayNum}
                  </span>
                </button>
              )
            })}
          </div>
        </div>

        {/* Notification Banner */}
        {notification && (
          <div
            className={`p-4 rounded-2xl text-xs flex items-center gap-3 border shadow-xs ${
              notification.type === 'success'
                ? 'bg-sage/15 border-sage/40 text-sage font-semibold'
                : 'bg-clay/15 border-clay/40 text-clay font-semibold'
            }`}
          >
            {notification.type === 'success' ? (
              <CheckCircle2 className="w-5 h-5 text-sage shrink-0" />
            ) : (
              <AlertCircle className="w-5 h-5 text-clay shrink-0" />
            )}
            <span>{notification.message}</span>
          </div>
        )}

        {/* Login Prompt for Guest */}
        {!isLoggedIn && (
          <div className="p-4 rounded-2xl bg-sand/60 border border-line shadow-xs text-xs flex items-center justify-between gap-3">
            <div className="flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-mocha shrink-0" />
              <span className="text-secondary font-medium">
                Ders rezerve etmek ve bakiye kullanmak için giriş yapın.
              </span>
            </div>
            <Link href="/giris">
              <Button size="sm" className="whitespace-nowrap bg-espresso hover:bg-espresso-dark text-ivory font-bold rounded-xl border-none shadow-xs text-xs">
                Giriş Yap
              </Button>
            </Link>
          </div>
        )}

        {/* Sessions List */}
        {loading ? (
          <div className="flex flex-col items-center justify-center py-16 gap-3 text-secondary">
            <Loader2 className="w-8 h-8 animate-spin text-espresso" />
            <p className="text-xs font-semibold text-secondary">Ders oturumları yükleniyor...</p>
          </div>
        ) : filteredSessions.length > 0 ? (
          <div className="space-y-4">
            {filteredSessions.map((session) => (
              <SessionCard
                key={session.id}
                session={session}
                userBooking={activeBookingsMap.get(session.id)}
                isLoading={actionLoadingId === session.id}
                onBook={handleBook}
                onCancel={handleCancel}
                onWaitlist={handleWaitlist}
              />
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center py-14 px-4 bg-sand/40 border border-dashed border-line rounded-2xl text-center space-y-3">
            <div className="p-3 rounded-full bg-sand text-espresso">
              <CalendarIcon className="w-8 h-8 opacity-80" />
            </div>
            <p className="font-serif text-lg font-bold text-ink">
              Seçilen Tarihte Ders Bulunamadı
            </p>
            <p className="text-xs text-secondary max-w-xs leading-relaxed">
              Bu tarihte henüz bir ders planlanmamış. Yukarıdaki gün şeridinden farklı bir tarih seçebilirsiniz.
            </p>
          </div>
        )}
      </main>
    </div>
  )
}
