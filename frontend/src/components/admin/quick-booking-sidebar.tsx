'use client'

import React, { useState } from 'react'
import { admin, TodaySessionResponse } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { Input } from '@/components/ui/input'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Zap, CheckCircle2, AlertCircle, Phone, User, Calendar, Loader2, Sparkles } from 'lucide-react'

interface QuickBookingSidebarProps {
  sessions: TodaySessionResponse[]
  onSuccess?: () => void
  selectedSessionId?: number | null
  onSelectSessionId?: (id: number | null) => void
}

export function QuickBookingSidebar({
  sessions,
  onSuccess,
  selectedSessionId,
  onSelectSessionId,
}: QuickBookingSidebarProps) {
  const [sessionId, setSessionId] = useState<string>(
    selectedSessionId ? String(selectedSessionId) : ''
  )
  const [telefon, setTelefon] = useState('')
  const [ad, setAd] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  // Update selected session if prop changes
  React.useEffect(() => {
    if (selectedSessionId) {
      setSessionId(String(selectedSessionId))
    }
  }, [selectedSessionId])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setMessage(null)

    if (!sessionId) {
      setMessage({ type: 'error', text: 'Lütfen bir ders seçin.' })
      return
    }

    if (!telefon.trim()) {
      setMessage({ type: 'error', text: 'Lütfen telefon numarasını girin.' })
      return
    }

    setLoading(true)
    try {
      await admin.quickBooking({
        session_id: Number(sessionId),
        telefon: telefon.trim(),
        ad: ad.trim() || undefined,
      })

      setMessage({
        type: 'success',
        text: 'Üye derse 5 saniyede eklendi!',
      })
      setTelefon('')
      setAd('')
      if (onSuccess) {
        onSuccess()
      }
    } catch (err: any) {
      setMessage({
        type: 'error',
        text: err?.message || 'Hızlı kayıt yapılırken bir hata oluştu.',
      })
    } finally {
      setLoading(false)
    }
  }

  const formatSessionTime = (isoString: string) => {
    try {
      const date = new Date(isoString)
      return date.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })
    } catch {
      return ''
    }
  }

  return (
    <Card className="border border-line shadow-xs bg-sand border-line sticky top-20 rounded-2xl text-ink overflow-hidden">
      <CardHeader className="pb-4 border-b border-line/80">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-2xl bg-espresso text-ivory shadow-xs shrink-0">
            <Zap className="w-5 h-5 fill-ivory" />
          </div>
          <div>
            <CardTitle className="text-lg font-serif font-bold text-ink tracking-wide">
              {buyukHarf("5 Saniyede DM Kayıt")}
            </CardTitle>
            <p className="text-xs text-secondary mt-0.5 font-medium">
              Eğitmenler için Instagram DM tek tık hızlı rezervasyon
            </p>
          </div>
        </div>
      </CardHeader>

      <CardContent className="pt-5 space-y-4">
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Ders Seçimi */}
          <div className="space-y-1.5">
            <label className="block text-xs font-bold text-secondary uppercase tracking-wider flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-mocha" />
              <span>{buyukHarf("Ders Seçimi")}</span>
            </label>
            <select
              value={sessionId}
              onChange={(e) => {
                const val = e.target.value
                setSessionId(val)
                if (onSelectSessionId) {
                  onSelectSessionId(val ? Number(val) : null)
                }
              }}
              className="flex h-11 w-full rounded-xl border border-line bg-ivory px-3.5 py-2 text-sm text-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-espresso/20 transition-colors font-medium cursor-pointer"
              required
            >
              <option value="" className="bg-ivory text-secondary">-- Ders Seçiniz --</option>
              {sessions.map((s) => {
                const title = s.class_type?.ad || 'Ders'
                const time = formatSessionTime(s.baslangic)
                const instructorName = s.instructor?.ad ? `(${s.instructor.ad})` : ''
                const capacity = `${s.dolu_sayi}/${s.kontenjan}`
                return (
                  <option key={s.id} value={s.id} className="bg-ivory text-ink py-1">
                    {time} - {title} {instructorName} [{capacity}]
                  </option>
                )
              })}
            </select>
          </div>

          {/* Telefon Numarası */}
          <div className="space-y-1.5">
            <label className="block text-xs font-bold text-secondary uppercase tracking-wider flex items-center gap-1.5">
              <Phone className="w-3.5 h-3.5 text-mocha" />
              <span>{buyukHarf("Üye Telefon Numarası")}</span>
            </label>
            <Input
              type="tel"
              placeholder="05321234567"
              value={telefon}
              onChange={(e) => setTelefon(e.target.value)}
              className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-xl h-11 px-3.5 font-medium"
              required
            />
          </div>

          {/* Ad Soyad (Opsiyonel) */}
          <div className="space-y-1.5">
            <label className="block text-xs font-bold text-secondary uppercase tracking-wider flex items-center gap-1.5">
              <User className="w-3.5 h-3.5 text-mocha" />
              <span>{buyukHarf("Üye Adı (Opsiyonel)")}</span>
            </label>
            <Input
              type="text"
              placeholder="Ahmet Yılmaz"
              value={ad}
              onChange={(e) => setAd(e.target.value)}
              className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-xl h-11 px-3.5 font-medium"
            />
          </div>

          {/* Geribildirim Mesajı */}
          {message && (
            <div
              className={`p-3.5 rounded-xl text-xs font-medium flex items-start gap-2.5 ${
                message.type === 'success'
                  ? 'bg-sage/15 text-sage border border-sage/40'
                  : 'bg-clay/15 text-clay border border-clay/40'
              }`}
            >
              {message.type === 'success' ? (
                <CheckCircle2 className="w-4 h-4 text-sage shrink-0 mt-0.5" />
              ) : (
                <AlertCircle className="w-4 h-4 text-clay shrink-0 mt-0.5" />
              )}
              <span>{message.text}</span>
            </div>
          )}

          {/* Espresso DERSE EKLE Butonu */}
          <button
            type="submit"
            disabled={loading}
            className="w-full h-12 rounded-xl text-ivory font-extrabold text-sm tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99] border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 mt-2"
          >
            {loading ? (
              <>
                <Loader2 className="w-4 h-4 mr-1 animate-spin" />
                Kaydediliyor...
              </>
            ) : (
              <>
                <Zap className="w-4 h-4 fill-ivory" />
                <span>DERSE EKLE</span>
                <Sparkles className="w-4 h-4 text-mocha opacity-80" />
              </>
            )}
          </button>
        </form>
      </CardContent>
    </Card>
  )
}
