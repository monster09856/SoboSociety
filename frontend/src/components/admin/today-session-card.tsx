'use client'

import React, { useState, useEffect } from 'react'
import { admin, TodaySessionResponse, AttendeeResponse } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card'
import {
  Users,
  Clock,
  UserCheck,
  UserX,
  CheckCircle2,
  AlertCircle,
  Loader2,
  PlusCircle,
  Sparkles,
} from 'lucide-react'

interface TodaySessionCardProps {
  session: TodaySessionResponse
  onAttendanceSaved?: () => void
  onSelectForQuickBooking?: (sessionId: number) => void
}

export function TodaySessionCard({
  session,
  onAttendanceSaved,
  onSelectForQuickBooking,
}: TodaySessionCardProps) {
  const attendeesList: AttendeeResponse[] =
    session.katilimcilar && session.katilimcilar.length > 0
      ? session.katilimcilar
      : session.attendees || []

  // Track which members are marked as attended (set of member_id)
  const [attendedSet, setAttendedSet] = useState<Set<number>>(() => {
    const initial = new Set<number>()
    attendeesList.forEach((att) => {
      if (att.durum === 'attended' || att.durum === 'booked') {
        initial.add(att.member_id)
      }
    })
    return initial
  })

  // Sync state when session changes
  useEffect(() => {
    const nextSet = new Set<number>()
    attendeesList.forEach((att) => {
      if (att.durum === 'attended' || att.durum === 'booked') {
        nextSet.add(att.member_id)
      }
    })
    setAttendedSet(nextSet)
  }, [session])

  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const toggleAttendance = (memberId: number, attended: boolean) => {
    setAttendedSet((prev) => {
      const copy = new Set(prev)
      if (attended) {
        copy.add(memberId)
      } else {
        copy.delete(memberId)
      }
      return copy
    })
  }

  const handleSaveAttendance = async () => {
    setMessage(null)
    setLoading(true)
    try {
      const gelenIds = Array.from(attendedSet)
      const res = await admin.submitAttendance({
        session_id: session.id,
        gelen_member_ids: gelenIds,
      })

      setMessage({
        type: 'success',
        text: `Yoklama kaydedildi: ${res.gelen} Katılan, ${res.gelmeyen} Gelmeyen`,
      })

      if (onAttendanceSaved) {
        onAttendanceSaved()
      }
    } catch (err: any) {
      setMessage({
        type: 'error',
        text: err?.message || 'Yoklama kaydedilirken bir hata oluştu.',
      })
    } finally {
      setLoading(false)
    }
  }

  const formatTime = (isoString: string) => {
    try {
      const date = new Date(isoString)
      return date.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })
    } catch {
      return ''
    }
  }

  const classTitle = session.class_type?.ad || 'Grupsal Ders'
  const instructorName = session.instructor?.ad || 'Atanmadı'
  const startTime = formatTime(session.baslangic)
  const capacityRatio = `${session.dolu_sayi}/${session.kontenjan}`

  return (
    <Card className="border border-line shadow-xs bg-sand/60 hover:bg-sand rounded-2xl text-ink overflow-hidden transition-all duration-300">
      <CardHeader className="pb-4 border-b border-line/80">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2 mb-1.5">
              <span className="inline-flex items-center gap-1 px-3 py-0.5 rounded-full text-xs font-bold bg-espresso/10 text-espresso border border-line">
                <Clock className="w-3.5 h-3.5" />
                {startTime}
              </span>
              <span
                className={`inline-flex items-center gap-1 px-3 py-0.5 rounded-full text-xs font-bold ${
                  session.dolu_sayi >= session.kontenjan
                    ? 'bg-clay/15 text-clay border border-clay/30'
                    : 'bg-sage/15 text-sage border border-sage/30'
                }`}
              >
                <Users className="w-3.5 h-3.5" />
                {capacityRatio} Dolu
              </span>
            </div>
            <CardTitle className="text-2xl font-serif font-bold text-ink tracking-wide">
              {buyukHarf(classTitle)}
            </CardTitle>
            <p className="text-xs text-secondary font-medium mt-1">
              Eğitmen: <span className="font-semibold text-ink">{instructorName}</span>
            </p>
          </div>

          {onSelectForQuickBooking && (
            <button
              onClick={() => onSelectForQuickBooking(session.id)}
              className="px-3.5 py-2 rounded-xl text-xs font-bold bg-ivory hover:bg-sand text-espresso border border-line transition-all flex items-center gap-1.5 cursor-pointer shadow-xs"
            >
              <PlusCircle className="w-4 h-4 text-mocha" />
              <span>Hızlı Kayıt</span>
            </button>
          )}
        </div>
      </CardHeader>

      <CardContent className="pt-5 pb-3 space-y-3">
        <div className="flex items-center justify-between">
          <h4 className="text-xs font-bold uppercase tracking-wider text-secondary flex items-center gap-1.5">
            <Sparkles className="w-3.5 h-3.5 text-mocha" />
            <span>Katılımcı Yoklama Listesi</span> ({attendeesList.length})
          </h4>
          <span className="text-[11px] font-semibold text-secondary">
            <strong className="text-sage">{attendedSet.size} Katıldı</strong> / <strong className="text-clay">{attendeesList.length - attendedSet.size} Gelmedi</strong>
          </span>
        </div>

        {attendeesList.length === 0 ? (
          <div className="p-6 text-center border border-dashed border-line rounded-2xl bg-ivory/60">
            <p className="text-xs text-secondary font-medium">Bu derse henüz üye kaydolmadı.</p>
          </div>
        ) : (
          <div className="space-y-2.5 max-h-64 overflow-y-auto pr-1">
            {attendeesList.map((att) => {
              const isAttended = attendedSet.has(att.member_id)
              return (
                <div
                  key={att.booking_id}
                  className={`flex items-center justify-between p-3 rounded-xl border transition-all ${
                    isAttended
                      ? 'bg-sage/10 border-sage/30 text-ink'
                      : 'bg-clay/10 border-clay/30 text-ink'
                  }`}
                >
                  <div className="min-w-0 pr-2">
                    <p className="text-sm font-bold text-ink truncate">{att.ad}</p>
                    <p className="text-xs text-secondary font-mono">{att.telefon}</p>
                  </div>

                  {/* Canlı Seçim Düğmeleri (Katıldı Adaçayı Yeşil, Gelmedi Kiremit Kırmızı) */}
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      type="button"
                      onClick={() => toggleAttendance(att.member_id, true)}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs transition-all cursor-pointer ${
                        isAttended
                          ? 'bg-sage text-white font-extrabold shadow-xs border-none'
                          : 'bg-ivory text-secondary hover:bg-sage/15 hover:text-sage border border-line font-medium'
                      }`}
                    >
                      <UserCheck className="w-3.5 h-3.5" />
                      <span>Katıldı</span>
                    </button>

                    <button
                      type="button"
                      onClick={() => toggleAttendance(att.member_id, false)}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs transition-all cursor-pointer ${
                        !isAttended
                          ? 'bg-clay text-white font-extrabold shadow-xs border-none'
                          : 'bg-ivory text-secondary hover:bg-clay/15 hover:text-clay border border-line font-medium'
                      }`}
                    >
                      <UserX className="w-3.5 h-3.5" />
                      <span>Gelmedi</span>
                    </button>
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {message && (
          <div
            className={`p-3 rounded-xl text-xs font-medium flex items-center gap-2.5 ${
              message.type === 'success'
                ? 'bg-sage/15 text-sage border border-sage/40'
                : 'bg-clay/15 text-clay border border-clay/40'
            }`}
          >
            {message.type === 'success' ? (
              <CheckCircle2 className="w-4 h-4 text-sage shrink-0" />
            ) : (
              <AlertCircle className="w-4 h-4 text-clay shrink-0" />
            )}
            <span>{message.text}</span>
          </div>
        )}
      </CardContent>

      <CardFooter className="pt-3">
        <button
          onClick={handleSaveAttendance}
          disabled={loading || attendeesList.length === 0}
          className="w-full h-11 rounded-xl text-ivory font-extrabold text-xs tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99] border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
        >
          {loading ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              Kaydediliyor...
            </>
          ) : (
            <>
              <CheckCircle2 className="w-4 h-4 text-mocha" />
              <span>YOKLAMAYI KAYDET</span>
            </>
          )}
        </button>
      </CardFooter>
    </Card>
  )
}
