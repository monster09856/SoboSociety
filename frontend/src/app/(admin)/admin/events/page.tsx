'use client'

import React, { useState, useEffect } from 'react'
import { admin } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { AdminNav } from '@/components/admin/admin-nav'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Sparkles, Plus, Trash2, Calendar, Clock, Users, Coffee, Tag, AlertCircle, CheckCircle2, Loader2, Info } from 'lucide-react'

interface EventItem {
  id: number
  baslik: string
  turu: string
  tarih_saat: string
  aciklama: string
  kontenjan: number
  ucret: string
  aktif: boolean
}

export default function AdminEventsPage() {
  const [events, setEvents] = useState<EventItem[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  // Form State
  const [showAddForm, setShowAddForm] = useState(false)
  const [baslik, setBaslik] = useState('')
  const [turu, setTuru] = useState('WORKSHOP')
  const [tarihSaat, setTarihSaat] = useState(() => {
    const nextWeek = new Date()
    nextWeek.setDate(nextWeek.getDate() + 7)
    nextWeek.setHours(14, 0, 0, 0)
    return nextWeek.toISOString().slice(0, 16)
  })
  const [aciklama, setAciklama] = useState('')
  const [kontenjan, setKontenjan] = useState(15)
  const [ucret, setUcret] = useState('Ücretsiz / Üyelere Özel')
  const [submitting, setSubmitting] = useState(false)

  const loadEvents = async () => {
    setLoading(true)
    try {
      const data = await admin.getEvents()
      setEvents(data || [])
    } catch (err: any) {
      console.error('Etkinlikler yüklenemedi:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadEvents()
  }, [])

  const handleCreateEvent = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    setSuccess(null)

    try {
      const isoDate = new Date(tarihSaat).toISOString()
      await admin.createEvent({
        baslik,
        turu,
        tarih_saat: isoDate,
        aciklama,
        kontenjan: Number(kontenjan),
        ucret,
      })
      setSuccess(`"${baslik}" etkinliği başarıyla yayınlandı!`)
      setBaslik('')
      setAciklama('')
      setShowAddForm(false)
      loadEvents()
    } catch (err: any) {
      setError(err?.message || 'Etkinlik eklenirken bir hata oluştu.')
    } finally {
      setSubmitting(false)
    }
  }

  const handleDeleteEvent = async (eventId: number, eventTitle: string) => {
    if (!confirm(`"${eventTitle}" etkinliğini silmek istediğinizden emin misiniz?`)) return
    try {
      await admin.deleteEvent(eventId)
      setSuccess(`"${eventTitle}" etkinliği silindi.`)
      loadEvents()
    } catch (err: any) {
      alert(err?.message || 'Etkinlik silinirken hata oluştu.')
    }
  }

  const formatDate = (dateStr: string) => {
    try {
      return new Date(dateStr).toLocaleDateString('tr-TR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        weekday: 'long',
      })
    } catch {
      return dateStr
    }
  }

  const formatTime = (dateStr: string) => {
    try {
      return new Date(dateStr).toLocaleTimeString('tr-TR', {
        hour: '2-digit',
        minute: '2-digit',
      })
    } catch {
      return ''
    }
  }

  return (
    <div className="min-h-screen bg-ivory text-ink font-sans antialiased relative">
      <AdminNav />

      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1.5">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-sand text-espresso border border-line">
                <Sparkles className="w-3.5 h-3.5 text-mocha" />
                <span>Yönetici Workshop & Etkinlik Konsolu</span>
              </span>
            </div>
            <h1 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
              {buyukHarf("Workshop, Atölye & Kahve Buluşmaları")}
            </h1>
            <p className="text-sm text-secondary font-medium mt-1">
              Stüdyonuzda düzenleyeceğiniz özel workshop, eğitim, atölye ve kahve buluşmalarını buradan yönetin.
            </p>
          </div>

          <button
            onClick={() => setShowAddForm(!showAddForm)}
            className="px-5 py-2.5 rounded-xl font-bold text-xs uppercase tracking-wider bg-espresso text-ivory hover:bg-espresso-dark transition-all flex items-center gap-2 cursor-pointer shadow-xs"
          >
            <Plus className="w-4 h-4" />
            <span>{showAddForm ? 'Kapat' : 'Yeni Etkinlik / Workshop Ekle'}</span>
          </button>
        </div>

        {/* Global Notifications */}
        {success && (
          <div className="p-4 rounded-xl bg-sage/15 border border-sage/40 text-sage text-xs font-bold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{success}</span>
          </div>
        )}
        {error && (
          <div className="p-4 rounded-xl bg-clay/15 border border-clay/40 text-clay text-xs font-bold flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* New Event Form */}
        {showAddForm && (
          <Card className="border border-espresso/30 bg-sand rounded-2xl text-ink shadow-md animate-in fade-in slide-in-from-top-2 duration-200">
            <CardHeader className="border-b border-line pb-4">
              <CardTitle className="flex items-center gap-2 text-lg font-serif font-bold text-ink">
                <Sparkles className="w-5 h-5 text-espresso" />
                <span>Yeni Workshop / Etkinlik Ekle</span>
              </CardTitle>
              <CardDescription className="text-xs text-secondary">
                Etkinlik başlığı, tarihi, kontenjanı ve ücret bilgilerini girerek stüdyo takvimine ekleyin.
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-6">
              <form onSubmit={handleCreateEvent} className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Etkinlik Türü</label>
                    <select
                      value={turu}
                      onChange={(e) => setTuru(e.target.value)}
                      className="w-full bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium focus:ring-2 focus:ring-espresso"
                    >
                      <option value="WORKSHOP">Workshop & Atölye</option>
                      <option value="KAHVE">Kahve Buluşması & Sohbet</option>
                      <option value="ETKINLIK">Özel Stüdyo Etkinliği</option>
                      <option value="EGITIM">Özel Eğitmen Eğitimi</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Etkinlik / Workshop Adı *</label>
                    <Input
                      placeholder="Örn: Nefes & Ses Çanağı Meditasyon Atölyesi"
                      value={baslik}
                      onChange={(e) => setBaslik(e.target.value)}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Tarih & Saat *</label>
                    <Input
                      type="datetime-local"
                      value={tarihSaat}
                      onChange={(e) => setTarihSaat(e.target.value)}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Kontenjan (Kişi)</label>
                    <Input
                      type="number"
                      min={1}
                      max={100}
                      value={kontenjan}
                      onChange={(e) => setKontenjan(Number(e.target.value))}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Ücret / Katılım Şartı</label>
                    <Input
                      placeholder="Örn: Ücretsiz / Üyelere Özel veya 500 TL"
                      value={ucret}
                      onChange={(e) => setUcret(e.target.value)}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase mb-1">Açıklama & Detaylar</label>
                  <textarea
                    rows={3}
                    placeholder="Etkinlik içeriği, eğitmen/konuk bilgisi ve katılım gereksinimleri..."
                    value={aciklama}
                    onChange={(e) => setAciklama(e.target.value)}
                    className="w-full bg-ivory border border-line rounded-xl p-3 text-xs font-medium text-ink focus:ring-2 focus:ring-espresso"
                  />
                </div>

                <div className="flex justify-end gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => setShowAddForm(false)}
                    className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                  >
                    İptal
                  </button>
                  <button
                    type="submit"
                    disabled={submitting}
                    className="px-6 py-2.5 rounded-xl text-xs font-extrabold uppercase bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                  >
                    {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Sparkles className="w-4 h-4 text-mocha" />}
                    <span>ETKİNLİĞİ YAYINLA</span>
                  </button>
                </div>
              </form>
            </CardContent>
          </Card>
        )}

        {/* Events Grid */}
        <div className="space-y-4">
          <h2 className="font-serif text-xl font-bold text-ink flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-espresso" />
            <span>Aktif Etkinlikler & Workshoplar ({events.length})</span>
          </h2>

          {loading ? (
            <div className="flex h-32 items-center justify-center rounded-2xl bg-sand border border-line">
              <Loader2 className="w-6 h-6 animate-spin text-espresso" />
            </div>
          ) : events.length === 0 ? (
            <div className="p-8 text-center bg-sand border border-line rounded-2xl space-y-2 text-xs font-medium text-secondary">
              <Info className="w-6 h-6 text-mocha mx-auto opacity-60" />
              <p className="text-ink">Henüz yayınlanmış bir workshop veya etkinlik bulunmuyor.</p>
              <p>Yukarıdaki &quot;Yeni Etkinlik / Workshop Ekle&quot; butonunu kullanarak stüdyo topluluğuna özel etkinlik açabilirsiniz.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {events.map((ev) => (
                <Card key={ev.id} className="border border-line bg-sand rounded-2xl overflow-hidden hover:border-espresso/40 transition-all shadow-xs">
                  <CardHeader className="pb-3 border-b border-line/60 bg-sand-light/50">
                    <div className="flex items-center justify-between">
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] uppercase font-bold tracking-wider bg-espresso text-ivory">
                        {ev.turu === 'KAHVE' ? <Coffee className="w-3 h-3" /> : <Sparkles className="w-3 h-3 text-mocha" />}
                        <span>{ev.turu}</span>
                      </span>
                      <span className="text-xs font-bold text-espresso">{ev.ucret}</span>
                    </div>
                    <CardTitle className="font-serif text-lg font-bold text-ink mt-2">
                      {ev.baslik}
                    </CardTitle>
                  </CardHeader>

                  <CardContent className="pt-4 space-y-3 text-xs text-secondary font-medium">
                    <div className="flex items-center gap-2 text-ink font-semibold">
                      <Calendar className="w-3.5 h-3.5 text-mocha shrink-0" />
                      <span>{formatDate(ev.tarih_saat)}</span>
                    </div>

                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Clock className="w-3.5 h-3.5 text-mocha shrink-0" />
                        <span>Saat: {formatTime(ev.tarih_saat)}</span>
                      </div>
                      <div className="flex items-center gap-1.5 text-ink font-semibold">
                        <Users className="w-3.5 h-3.5 text-mocha shrink-0" />
                        <span>Kontenjan: {ev.kontenjan} Kişi</span>
                      </div>
                    </div>

                    {ev.aciklama && (
                      <p className="text-ink/80 text-xs bg-ivory p-3 rounded-xl border border-line leading-relaxed">
                        {ev.aciklama}
                      </p>
                    )}

                    <div className="pt-2 border-t border-line/50 flex justify-end">
                      <button
                        onClick={() => handleDeleteEvent(ev.id, ev.baslik)}
                        className="px-3 py-1.5 rounded-lg text-[11px] font-bold text-clay hover:bg-clay/10 transition-colors flex items-center gap-1.5 cursor-pointer"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        <span>Etkinliği Sil</span>
                      </button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  )
}
