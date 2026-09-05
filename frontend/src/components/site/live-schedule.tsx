'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { Calendar, Clock, User, CheckCircle2, Flame, Sparkles, HeartHandshake, Users, Phone, X, Loader2, ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'
import { api, ClassSessionResponse } from '@/lib/api'

interface ScheduleSession {
  id: number
  title: string
  category: 'Barre' | 'Pilates' | 'Functional'
  instructor: string
  time: string
  duration: string
  capacity: number
  enrolled: number
  fiyat_tl: number
  status: 'available' | 'few_left' | 'full'
  statusText: string
  tek_ders_acik?: boolean
}

const mockScheduleData: Record<string, ScheduleSession[]> = {
  Pazartesi: [
    { id: 101, title: 'Sobo Barre Morning', category: 'Barre', instructor: 'Ece Karaca', time: '08:30 - 09:20', duration: '50 dk', capacity: 5, enrolled: 4, fiyat_tl: 900, status: 'available', statusText: '1 Yer Kaldı', tek_ders_acik: true },
    { id: 102, title: 'Core & Posture Pilates', category: 'Pilates', instructor: 'Defne Yılmaz', time: '10:00 - 10:50', duration: '50 dk', capacity: 5, enrolled: 4, fiyat_tl: 900, status: 'few_left', statusText: 'Son 1 Yer', tek_ders_acik: true },
    { id: 103, title: 'Functional Sculpt', category: 'Functional', instructor: 'Can Tezcan', time: '18:30 - 19:20', duration: '50 dk', capacity: 5, enrolled: 5, fiyat_tl: 900, status: 'full', statusText: 'Dolu (Sıra Bekleme)', tek_ders_acik: true },
  ],
  Salı: [
    { id: 104, title: 'Sobo Flow & Stretch', category: 'Pilates', instructor: 'Defne Yılmaz', time: '09:00 - 09:50', duration: '50 dk', capacity: 5, enrolled: 2, fiyat_tl: 900, status: 'available', statusText: '3 Yer Kaldı', tek_ders_acik: true },
    { id: 105, title: 'Barre Burn & Tone', category: 'Barre', instructor: 'Ece Karaca', time: '12:15 - 13:05', duration: '50 dk', capacity: 5, enrolled: 3, fiyat_tl: 900, status: 'few_left', statusText: 'Son 2 Yer', tek_ders_acik: true },
  ],
  Çarşamba: [
    { id: 106, title: 'Sunrise Barre', category: 'Barre', instructor: 'Ece Karaca', time: '08:00 - 08:50', duration: '50 dk', capacity: 5, enrolled: 1, fiyat_tl: 900, status: 'available', statusText: '4 Yer Kaldı', tek_ders_acik: true },
    { id: 107, title: 'Reformer & Mat Alignment', category: 'Pilates', instructor: 'Defne Yılmaz', time: '11:00 - 11:50', duration: '50 dk', capacity: 5, enrolled: 5, fiyat_tl: 900, status: 'full', statusText: 'Dolu (Sıra Bekleme)', tek_ders_acik: true },
  ],
  Perşembe: [
    { id: 108, title: 'Postural Pilates', category: 'Pilates', instructor: 'Defne Yılmaz', time: '09:30 - 10:20', duration: '50 dk', capacity: 5, enrolled: 3, fiyat_tl: 900, status: 'available', statusText: '2 Yer Kaldı', tek_ders_acik: true },
  ],
  Cuma: [
    { id: 109, title: 'Friday Energy Functional', category: 'Functional', instructor: 'Can Tezcan', time: '08:30 - 09:20', duration: '50 dk', capacity: 5, enrolled: 2, fiyat_tl: 900, status: 'available', statusText: '3 Yer Kaldı', tek_ders_acik: true },
  ],
  Cumartesi: [
    { id: 110, title: 'Weekend Warrior Barre', category: 'Barre', instructor: 'Ece Karaca', time: '10:00 - 10:50', duration: '50 dk', capacity: 5, enrolled: 4, fiyat_tl: 900, status: 'few_left', statusText: 'Son 1 Yer', tek_ders_acik: true },
  ],
  Pazar: [
    { id: 111, title: 'Sunday Recovery & Flow', category: 'Pilates', instructor: 'Defne Yılmaz', time: '11:00 - 11:50', duration: '50 dk', capacity: 5, enrolled: 1, fiyat_tl: 900, status: 'available', statusText: '4 Yer Kaldı', tek_ders_acik: true },
  ],
}

const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']

export function LiveSchedule() {
  const [selectedDay, setSelectedDay] = useState('Pazartesi')
  const [selectedSession, setSelectedSession] = useState<ScheduleSession | null>(null)
  
  // Real Sessions API State
  const [realSessions, setRealSessions] = useState<Record<string, ScheduleSession[]>>({})
  
  // Guest Booking Modal Form State
  const [guestAd, setGuestAd] = useState('')
  const [guestTelefon, setGuestTelefon] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [successMsg, setSuccessMsg] = useState<string | null>(null)

  useEffect(() => {
    async function loadSessions() {
      try {
        const res = await api.sessions.list()
        if (res && Array.isArray(res) && res.length > 0) {
          const grouped: Record<string, ScheduleSession[]> = {
            Pazartesi: [],
            Salı: [],
            Çarşamba: [],
            Perşembe: [],
            Cuma: [],
            Cumartesi: [],
            Pazar: [],
          }
          const dayNames = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi']

          res.forEach((s) => {
            const dt = new Date(s.baslangic)
            const dayName = dayNames[dt.getDay()] || 'Pazartesi'
            const timeStr = dt.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })
            const category: 'Barre' | 'Pilates' | 'Functional' =
              (s.class_type?.ad?.toLowerCase().includes('barre') ? 'Barre' :
               s.class_type?.ad?.toLowerCase().includes('pilates') ? 'Pilates' : 'Functional')

            const enrolled = s.dolu_sayi || 0
            const capacity = s.kontenjan || 5
            const rem = capacity - enrolled
            const status = rem <= 0 ? 'full' : rem <= 2 ? 'few_left' : 'available'
            const statusText = rem <= 0 ? 'Dolu (Sıra Bekleme)' : rem <= 2 ? `Son ${rem} Yer` : `${rem} Yer Kaldı`

            const mapped: ScheduleSession = {
              id: s.id,
              title: s.class_type?.ad || 'Ders Seansı',
              category,
              instructor: s.instructor?.ad || 'Eğitmen',
              time: `${timeStr}`,
              duration: `${s.class_type?.sure_dk || 50} dk`,
              capacity,
              enrolled,
              fiyat_tl: s.fiyat_tl ?? 900,
              status,
              statusText,
              tek_ders_acik: s.tek_ders_acik ?? false,
            }

            if (!grouped[dayName]) grouped[dayName] = []
            grouped[dayName].push(mapped)
          })
          setRealSessions(grouped)
        }
      } catch (err) {
        console.error('Failed to load real sessions:', err)
      }
    }
    loadSessions()
  }, [])

  const currentSessions = (realSessions[selectedDay] && realSessions[selectedDay].length > 0)
    ? realSessions[selectedDay]
    : (mockScheduleData[selectedDay] || [])

  const handleGuestBooking = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedSession) return
    setError(null)
    setSuccessMsg(null)

    if (!guestAd.trim() || !guestTelefon.trim()) {
      setError('Lütfen Ad Soyad ve Cep Telefonu alanlarını doldurun.')
      return
    }

    setLoading(true)
    try {
      const res = await api.bookings.guestBooking({
        session_id: selectedSession.id,
        ad: guestAd.trim(),
        telefon: guestTelefon.trim(),
      })

      setSuccessMsg('Talebiniz oluşturuldu! Ödemeyi tamamlamak için WhatsApp hattımıza yönlendiriliyorsunuz...')
      setTimeout(() => {
        if (res.whatsapp_url) {
          window.location.href = res.whatsapp_url
        }
      }, 1500)
    } catch (err: any) {
      setError(err.message || 'Rezervasyon talebi oluşturulurken bir hata oluştu.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <section id="canli-program" className="py-24 bg-ivory/50 relative overflow-hidden border-b border-line/60">
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-2xl mx-auto mb-14 space-y-4">
          <Badge variant="sage" className="uppercase tracking-widest px-3.5 py-1 text-xs font-medium">
            Program & Kontenjan Takibi
          </Badge>
          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-medium text-ink tracking-tight">
            Haftalık Ders Programı
          </h2>
          <p className="text-secondary text-base leading-relaxed">
            Butik stüdyomuzda her sınıfta maksimum 5 üye kabul edilir. Kontenjan durumunu takip edebilir, üye olarak veya tek derslik katılımlarınız için yerinizi rezerve edebilirsiniz.
          </p>
        </div>

        {/* Days Selector Ribbon (Sand / Ivory) */}
        <div className="flex items-center justify-start sm:justify-center gap-2.5 overflow-x-auto pb-4 mb-10 no-scrollbar">
          {days.map((day) => {
            const isActive = selectedDay === day
            return (
              <button
                key={day}
                onClick={() => setSelectedDay(day)}
                className={`px-5 py-2.5 rounded-full text-sm font-medium transition-all duration-200 whitespace-nowrap cursor-pointer ${
                  isActive
                    ? 'bg-espresso text-white shadow-xs border border-espresso'
                    : 'bg-sand-light hover:bg-sand text-ink border border-line'
                }`}
              >
                {day}
              </button>
            )
          })}
        </div>

        {/* Session Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {currentSessions.map((session) => {
            const occupancyPercentage = Math.round((session.enrolled / session.capacity) * 100)
            const isFull = session.status === 'full'
            const isFewLeft = session.status === 'few_left'

            const badgeVariant = isFull ? ('clay' as const) : isFewLeft ? ('mocha' as const) : ('sage' as const)

            const CategoryIcon =
              session.category === 'Barre'
                ? Sparkles
                : session.category === 'Pilates'
                ? HeartHandshake
                : Flame

            return (
              <Card
                key={session.id}
                className="relative overflow-hidden bg-white/90 border-line hover:border-mocha/50 p-6 flex flex-col justify-between"
              >
                <div className="space-y-5">
                  {/* Header info */}
                  <div className="flex items-start justify-between gap-3">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <CategoryIcon className="w-4 h-4 text-mocha" />
                        <span className="text-xs font-semibold uppercase tracking-wider text-secondary">
                          {session.category}
                        </span>
                      </div>
                      <h3 className="font-serif text-2xl font-medium text-ink tracking-tight">
                        {session.title}
                      </h3>
                    </div>

                    <Badge variant={badgeVariant} className="shrink-0">
                      {session.statusText}
                    </Badge>
                  </div>

                  {/* Occupancy Progress Bar */}
                  <div className="space-y-1.5 pt-2">
                    <div className="flex items-center justify-between text-xs text-secondary font-medium">
                      <span>Doluluk Oranı</span>
                      <span className="font-semibold text-ink">
                        {session.enrolled} / {session.capacity} Üye ({occupancyPercentage}%)
                      </span>
                    </div>
                    <div className="w-full bg-sand-light h-2 rounded-full overflow-hidden p-0.5 border border-line/40">
                      <div
                        className={`h-full rounded-full transition-all duration-500 ${
                          isFull
                            ? 'bg-clay'
                            : isFewLeft
                            ? 'bg-mocha'
                            : 'bg-sage'
                        }`}
                        style={{ width: `${occupancyPercentage}%` }}
                      />
                    </div>
                  </div>

                  {/* Details list */}
                  <div className="space-y-2.5 text-sm text-secondary pt-3 border-t border-line/50">
                    <div className="flex items-center gap-2.5">
                      <Clock className="w-4 h-4 text-mocha" />
                      <span>
                        {session.time} <strong className="text-ink font-normal">({session.duration})</strong>
                      </span>
                    </div>
                    <div className="flex items-center gap-2.5">
                      <User className="w-4 h-4 text-mocha" />
                      <span>Eğitmen: <strong className="text-ink font-medium">{session.instructor}</strong></span>
                    </div>
                    <div className="flex items-center justify-between text-xs text-espresso font-bold pt-1">
                      <span>Tek Ders Ücreti:</span>
                      <span className="text-sm font-serif font-extrabold text-mocha">{session.fiyat_tl} ₺</span>
                    </div>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="pt-6 space-y-2">
                  {session.tek_ders_acik && (
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedSession(session)
                        setError(null)
                        setSuccessMsg(null)
                      }}
                      className="w-full h-11 rounded-2xl bg-espresso hover:bg-espresso-dark text-ivory font-extrabold text-xs tracking-wider uppercase shadow-xs transition-all flex items-center justify-center gap-2 cursor-pointer"
                    >
                      <Sparkles className="w-4 h-4 text-mocha" />
                      <span>Tek Ders Al (Üyeliksiz)</span>
                    </button>
                  )}

                  <Link href="/giris" className="w-full block">
                    <button
                      type="button"
                      className="w-full h-10 rounded-2xl border border-line bg-sand-light hover:bg-sand text-ink font-bold text-xs tracking-wider uppercase transition-all flex items-center justify-center gap-1.5 cursor-pointer"
                    >
                      <span>Üye Girişi ile Rezerve Et</span>
                    </button>
                  </Link>
                </div>
              </Card>
            )
          })}
        </div>

        {/* Bottom Notice */}
        <div className="mt-12 text-center text-xs text-secondary flex items-center justify-center gap-2">
          <CheckCircle2 className="w-4 h-4 text-sage" />
          <span>Tek derslik veya paketli tüm rezervasyonlar stüdyomuz tarafından onaylandıktan sonra kesinleşmektedir.</span>
        </div>
      </div>

      {/* Guest Booking Modal (Üyeliksiz Tek Ders Talebi) */}
      {selectedSession && (
        <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-sand border border-line shadow-2xl rounded-3xl w-full max-w-md p-6 relative animate-in fade-in zoom-in duration-200">
            <button
              type="button"
              onClick={() => setSelectedSession(null)}
              className="absolute right-4 top-4 text-secondary hover:text-ink cursor-pointer p-1 rounded-full hover:bg-line/40"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="text-center mb-6">
              <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-espresso text-ivory shadow-xs">
                <Sparkles className="h-6 w-6 text-mocha" />
              </div>
              <h3 className="font-serif text-2xl font-bold text-ink">
                Tek Ders Rezervasyon Talebi
              </h3>
              <p className="text-xs text-secondary mt-1">
                Üye olmadan Ad ve Telefonunuzla ödeme bekleyen rezervasyon talebi oluşturabilirsiniz.
              </p>
            </div>

            {/* Session Info Badge */}
            <div className="bg-ivory border border-line p-3.5 rounded-2xl mb-5 space-y-1.5">
              <div className="flex items-center justify-between text-xs font-bold text-espresso">
                <span>{selectedSession.title}</span>
                <span className="text-mocha">{selectedSession.fiyat_tl} ₺</span>
              </div>
              <div className="flex items-center gap-3 text-xs text-secondary">
                <span>Saat: {selectedSession.time}</span>
                <span>•</span>
                <span>Eğitmen: {selectedSession.instructor}</span>
              </div>
              <div className="text-[11px] text-amber-800 font-medium pt-1 flex items-center gap-1">
                <Clock className="w-3.5 h-3.5 shrink-0" />
                <span>Talebiniz <b>'Ödeme Bekliyor'</b> olarak kaydolur ve WhatsApp'tan onaylanır.</span>
              </div>
            </div>

            {error && (
              <div className="mb-4 rounded-xl border border-clay/40 bg-clay/15 p-3 text-xs text-clay font-medium">
                {error}
              </div>
            )}

            {successMsg && (
              <div className="mb-4 rounded-xl border border-sage/40 bg-sage/15 p-3 text-xs text-sage font-bold flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 shrink-0" />
                <span>{successMsg}</span>
              </div>
            )}

            <form onSubmit={handleGuestBooking} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  Adınız Soyadınız
                </label>
                <div className="relative">
                  <User className="absolute left-4 top-3 h-4 w-4 text-mocha" />
                  <input
                    type="text"
                    required
                    placeholder="Adınız Soyadınız"
                    value={guestAd}
                    onChange={(e) => setGuestAd(e.target.value)}
                    className="w-full bg-ivory border border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-2xl h-11 pl-11 pr-4 font-medium text-sm outline-none"
                    disabled={loading || !!successMsg}
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  Cep Telefonunuz
                </label>
                <div className="relative">
                  <Phone className="absolute left-4 top-3 h-4 w-4 text-mocha" />
                  <input
                    type="tel"
                    required
                    placeholder="0532 XXX XX XX"
                    value={guestTelefon}
                    onChange={(e) => setGuestTelefon(e.target.value)}
                    className="w-full bg-ivory border border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-2xl h-11 pl-11 pr-4 font-medium text-sm outline-none"
                    disabled={loading || !!successMsg}
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={loading || !!successMsg}
                className="w-full h-12 rounded-2xl text-ivory font-extrabold text-xs tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 mt-4"
              >
                {loading ? (
                  <>
                    <Loader2 className="h-5 w-5 animate-spin" />
                    Talep Oluşturuluyor...
                  </>
                ) : (
                  <>
                    <ArrowRight className="h-4 w-4 text-mocha" />
                    <span>TALEBİ OLUŞTUR VE WHATSAPP İLE İLETİŞİME GEÇ</span>
                  </>
                )}
              </button>
            </form>
          </div>
        </div>
      )}
    </section>
  )
}
