import React from 'react'
import { Clock, User, CheckCircle2, ListOrdered, Loader2, Sparkles, Flame, Heart } from 'lucide-react'
import { ClassSessionResponse, BookingResponse } from '@/lib/api'
import { Button } from '@/components/ui/button'
import { buyukHarf, cn } from '@/lib/utils'

interface SessionCardProps {
  session: ClassSessionResponse
  userBooking?: BookingResponse | null
  isWaitlisted?: boolean
  onBook?: (sessionId: number) => void
  onCancel?: (bookingId: number) => void
  onWaitlist?: (sessionId: number) => void
  isLoading?: boolean
}

export const SessionCard: React.FC<SessionCardProps> = ({
  session,
  userBooking,
  isWaitlisted = false,
  onBook,
  onCancel,
  onWaitlist,
  isLoading = false,
}) => {
  const classType = session.class_type
  const instructor = session.instructor
  const kalanYer = session.kontenjan - session.dolu_sayi
  const percentFilled = Math.min(100, Math.max(0, Math.round((session.dolu_sayi / session.kontenjan) * 100)))

  // Time calculations
  const baslangicTarihi = new Date(session.baslangic)
  const baslangicSaat = baslangicTarihi.toLocaleTimeString('tr-TR', {
    hour: '2-digit',
    minute: '2-digit',
  })

  let bitisSaat = ''
  if (classType?.sure_dk) {
    const bitisTarihi = new Date(
      baslangicTarihi.getTime() + classType.sure_dk * 60000
    )
    bitisSaat = bitisTarihi.toLocaleTimeString('tr-TR', {
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  // Class Type Color Theme (Instagram Brand: Barre = Mocha, Pilates = Sage, Functional = Clay)
  const getClassTheme = () => {
    const name = (classType?.ad || '').toLowerCase()
    if (name.includes('barre')) {
      return {
        badgeBg: 'bg-mocha/15 text-mocha border-mocha/30',
        stripe: 'bg-mocha',
        progressBar: 'bg-mocha',
        icon: Heart,
        label: 'Barre',
      }
    }
    if (name.includes('pilates') || name.includes('reformer') || name.includes('cadillac') || name.includes('mat')) {
      return {
        badgeBg: 'bg-sage/15 text-sage border-sage/30',
        stripe: 'bg-sage',
        progressBar: 'bg-sage',
        icon: Sparkles,
        label: 'Pilates',
      }
    }
    if (name.includes('functional') || name.includes('fonksiyonel') || name.includes('hiit') || name.includes('güç')) {
      return {
        badgeBg: 'bg-clay/15 text-clay border-clay/30',
        stripe: 'bg-clay',
        progressBar: 'bg-clay',
        icon: Flame,
        label: 'Functional',
      }
    }
    return {
      badgeBg: 'bg-mocha/15 text-mocha border-mocha/30',
      stripe: 'bg-mocha',
      progressBar: 'bg-mocha',
      icon: Sparkles,
      label: classType?.ad || 'Ders',
    }
  }

  const theme = getClassTheme()

  // Capacity status label & badge
  const getCapacityBadge = () => {
    if (kalanYer > 1) {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-sage/15 text-sage border border-sage/30">
          <span className="w-1.5 h-1.5 rounded-full bg-sage" />
          {kalanYer} Yer Kaldı
        </span>
      )
    }
    if (kalanYer === 1) {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-clay/15 text-clay border border-clay/40 animate-pulse">
          <span className="w-1.5 h-1.5 rounded-full bg-clay" />
          Son 1 Yer!
        </span>
      )
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-secondary/15 text-secondary border border-line">
        Dolu — Bekleme Listesi
      </span>
    )
  }

  const isBooked = !!userBooking && userBooking.durum === 'booked'

  return (
    <div className="relative group overflow-hidden rounded-2xl bg-sand/60 hover:bg-sand border border-line hover:border-mocha/60 p-5 shadow-xs hover:shadow-md transition-all duration-300">
      {/* Brand Accent Stripe */}
      <div
        className={cn(
          'absolute top-0 left-0 bottom-0 w-2 transition-all duration-300 group-hover:w-2.5',
          theme.stripe
        )}
      />

      <div className="pl-3 flex flex-col justify-between h-full gap-4">
        {/* Header: Time & Capacity Badge */}
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2 text-xs font-semibold text-secondary">
            <div className="p-1 rounded-md bg-espresso/10 text-espresso">
              <Clock className="w-3.5 h-3.5" />
            </div>
            <span className="font-bold text-ink">
              {baslangicSaat} {bitisSaat ? `- ${bitisSaat}` : ''}
            </span>
            {classType?.sure_dk && (
              <span className="text-muted font-normal">({classType.sure_dk} dk)</span>
            )}
          </div>
          {getCapacityBadge()}
        </div>

        {/* Title & Instructor & Class Type Badge */}
        <div className="space-y-2">
          <div className="flex items-center justify-between gap-2">
            <h3 className="font-serif text-xl font-bold text-ink tracking-wide">
              {classType ? buyukHarf(classType.ad) : 'DERS'}
            </h3>
            <span className={cn('inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold border', theme.badgeBg)}>
              {theme.label}
            </span>
          </div>
          {instructor && (
            <div className="flex items-center gap-1.5 text-xs font-medium text-secondary">
              <User className="w-3.5 h-3.5 text-mocha" />
              <span>Eğitmen: <strong className="text-ink font-semibold">{instructor.ad}</strong></span>
            </div>
          )}
        </div>

        {/* Capacity Progress Bar */}
        <div className="space-y-1.5 pt-1">
          <div className="flex justify-between items-center text-[11px] font-semibold text-secondary">
            <span>Kontenjan Durumu</span>
            <span className="text-ink font-bold">{session.dolu_sayi} / {session.kontenjan} Dolu</span>
          </div>
          <div className="w-full h-2 bg-line/50 rounded-full overflow-hidden p-0.5 border border-line/40">
            <div
              className={cn('h-full rounded-full transition-all duration-500', theme.progressBar)}
              style={{ width: `${percentFilled}%` }}
            />
          </div>
        </div>

        {/* Action Area */}
        <div className="pt-3 border-t border-line/60 flex items-center justify-between gap-3 mt-auto">
          {isBooked ? (
            <div className="flex items-center justify-between w-full">
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-sage/15 text-sage border border-sage/40 text-xs font-bold">
                <CheckCircle2 className="w-4 h-4 text-sage" />
                <span>Rezerve Edildi</span>
              </div>
              <Button
                variant="destructive"
                size="sm"
                disabled={isLoading}
                onClick={() => userBooking && onCancel?.(userBooking.id)}
                className="bg-clay hover:bg-clay/90 text-white font-bold text-xs px-3.5 py-1.5 rounded-xl border-none shadow-xs"
              >
                {isLoading ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  'İptal Et'
                )}
              </Button>
            </div>
          ) : isWaitlisted ? (
            <div className="flex items-center justify-between w-full">
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-mocha/15 text-mocha border border-mocha/30 text-xs font-bold">
                <ListOrdered className="w-4 h-4 text-mocha" />
                <span>Bekleme Sırasındasınız</span>
              </div>
              <Button variant="ghost" size="sm" disabled className="text-xs font-semibold text-secondary">
                Sıradassınız
              </Button>
            </div>
          ) : kalanYer > 0 ? (
            <button
              disabled={isLoading}
              onClick={() => onBook?.(session.id)}
              className={cn(
                'w-full py-2.5 px-4 rounded-xl text-ivory font-extrabold text-sm tracking-wider uppercase',
                'bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99]',
                'flex items-center justify-center gap-2 border-none cursor-pointer disabled:opacity-50'
              )}
            >
              {isLoading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <>
                  <Sparkles className="w-4 h-4 text-mocha" />
                  <span>Rezerve Et</span>
                </>
              )}
            </button>
          ) : (
            <button
              disabled={isLoading}
              onClick={() => onWaitlist?.(session.id)}
              className={cn(
                'w-full py-2.5 px-4 rounded-xl text-white font-extrabold text-sm tracking-wider uppercase',
                'bg-clay hover:bg-clay/90 shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99]',
                'flex items-center justify-center gap-2 border-none cursor-pointer disabled:opacity-50'
              )}
            >
              {isLoading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <>
                  <ListOrdered className="w-4 h-4" />
                  <span>Sıraya Gir</span>
                </>
              )}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
