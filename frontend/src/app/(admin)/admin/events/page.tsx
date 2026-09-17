'use client'

import React, { useState, useEffect } from 'react'
import { admin } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { AdminNav } from '@/components/admin/admin-nav'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import {
  Sparkles,
  Plus,
  Trash2,
  Edit2,
  Calendar,
  Clock,
  Users,
  Coffee,
  Footprints,
  HeartHandshake,
  Sun,
  Flame,
  AlertCircle,
  CheckCircle2,
  Loader2,
  Info,
  X,
  Layers,
  Compass,
  Phone,
  MessageCircle,
  ExternalLink,
} from 'lucide-react'

interface EventAttendee {
  rsvp_id: number
  member_id: number
  ad: string
  telefon: string
  tek_katilim: boolean
  durum: string
  created_at?: string
}

interface EventItem {
  id: number
  baslik: string
  turu: string
  tarih_saat: string
  aciklama: string
  kontenjan: number
  dolu_sayi?: number
  ucret: string
  aktif: boolean
  katilimcilar?: EventAttendee[]
}

export default function AdminEventsPage() {
  const [events, setEvents] = useState<EventItem[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  // Form State
  const [showAddForm, setShowAddForm] = useState(false)
  const [baslik, setBaslik] = useState('')
  const [turu, setTuru] = useState('YURUYUS')
  const [ozelTuruAdi, setOzelTuruAdi] = useState('')
  const [tarihSaat, setTarihSaat] = useState(() => {
    const nextWeek = new Date()
    nextWeek.setDate(nextWeek.getDate() + 7)
    nextWeek.setHours(10, 0, 0, 0)
    const tzOffset = nextWeek.getTimezoneOffset() * 60000
    return new Date(nextWeek.getTime() - tzOffset).toISOString().slice(0, 16)
  })
  const [aciklama, setAciklama] = useState('')
  const [kontenjan, setKontenjan] = useState(20)
  const [ucret, setUcret] = useState('Ücretsiz / Tüm Üyelere ve Misafirlere Açık')
  const [submitting, setSubmitting] = useState(false)

  // Edit Modal State
  const [editingEvent, setEditingEvent] = useState<EventItem | null>(null)
  const [editBaslik, setEditBaslik] = useState('')
  const [editTuru, setEditTuru] = useState('WORKSHOP')
  const [editTarihSaat, setEditTarihSaat] = useState('')
  const [editAciklama, setEditAciklama] = useState('')
  const [editKontenjan, setEditKontenjan] = useState(15)
  const [editUcret, setEditUcret] = useState('')
  const [updating, setUpdating] = useState(false)
  const [editError, setEditError] = useState<string | null>(null)

  // Attendees Modal State
  const [selectedEventForAttendees, setSelectedEventForAttendees] = useState<EventItem | null>(null)
  const [removingRsvpId, setRemovingRsvpId] = useState<number | null>(null)

  const handleRemoveAttendee = async (eventId: number, rsvpId: number, memberName: string) => {
    if (!confirm(`"${memberName}" adlı katılımcıyı bu etkinlikten çıkarmak istediğinizden emin misiniz?`)) return
    setRemovingRsvpId(rsvpId)
    try {
      await admin.deleteEventRsvp(eventId, rsvpId)
      setEvents((prev) =>
        prev.map((e) => {
          if (e.id === eventId) {
            const updatedAttendees = (e.katilimcilar || []).filter((k) => k.rsvp_id !== rsvpId)
            return {
              ...e,
              katilimcilar: updatedAttendees,
              dolu_sayi: updatedAttendees.length,
            }
          }
          return e
        })
      )
      setSelectedEventForAttendees((prev) => {
        if (!prev || prev.id !== eventId) return prev
        const updatedAttendees = (prev.katilimcilar || []).filter((k) => k.rsvp_id !== rsvpId)
        return {
          ...prev,
          katilimcilar: updatedAttendees,
          dolu_sayi: updatedAttendees.length,
        }
      })
      setSuccess(`"${memberName}" katılımcı listesinden çıkarıldı.`)
    } catch (err: any) {
      alert(err?.message || 'Katılımcı silinirken bir hata oluştu.')
    } finally {
      setRemovingRsvpId(null)
    }
  }

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

  const applyPreset = (preset: {
    turu: string
    baslik: string
    kontenjan: number
    ucret: string
    aciklama: string
  }) => {
    setShowAddForm(true)
    setTuru(preset.turu)
    setBaslik(preset.baslik)
    setKontenjan(preset.kontenjan)
    setUcret(preset.ucret)
    setAciklama(preset.aciklama)
  }

  const handleCreateEvent = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError(null)
    setSuccess(null)

    try {
      const isoDate = new Date(tarihSaat).toISOString()
      const finalTuru = turu === 'OZEL' ? (ozelTuruAdi.trim() || 'Özel Etkinlik') : turu

      await admin.createEvent({
        baslik,
        turu: finalTuru,
        tarih_saat: isoDate,
        aciklama,
        kontenjan: Number(kontenjan),
        ucret,
      })
      setSuccess(`"${baslik}" etkinliği başarıyla yayınlandı!`)
      setBaslik('')
      setAciklama('')
      setOzelTuruAdi('')
      setShowAddForm(false)
      loadEvents()
    } catch (err: any) {
      setError(err?.message || 'Etkinlik eklenirken bir hata oluştu.')
    } finally {
      setSubmitting(false)
    }
  }

  const openEditModal = (ev: EventItem) => {
    setEditingEvent(ev)
    setEditBaslik(ev.baslik)
    setEditTuru(ev.turu)
    setEditAciklama(ev.aciklama || '')
    setEditKontenjan(ev.kontenjan || 15)
    setEditUcret(ev.ucret || '')
    try {
      const dt = new Date(ev.tarih_saat)
      const tzOffset = dt.getTimezoneOffset() * 60000
      setEditTarihSaat(new Date(dt.getTime() - tzOffset).toISOString().slice(0, 16))
    } catch {
      setEditTarihSaat('')
    }
    setEditError(null)
  }

  const handleUpdateEvent = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editingEvent) return
    setUpdating(true)
    setEditError(null)

    try {
      const isoDate = new Date(editTarihSaat).toISOString()
      await admin.updateEvent(editingEvent.id, {
        baslik: editBaslik.trim(),
        turu: editTuru,
        tarih_saat: isoDate,
        aciklama: editAciklama,
        kontenjan: Number(editKontenjan),
        ucret: editUcret,
      })
      setSuccess(`"${editBaslik}" etkinliği güncellendi.`)
      setEditingEvent(null)
      loadEvents()
    } catch (err: any) {
      setEditError(err?.message || 'Etkinlik güncellenirken hata oluştu.')
    } finally {
      setUpdating(false)
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
              {buyukHarf("Doğa Yürüyüşü, Atölyeler & Etkinlikler")}
            </h1>
            <p className="text-sm text-secondary font-medium mt-1">
              Stüdyonuzda düzenleyeceğiniz doğa yürüyüşü, kahve sohbetleri, workshop ve özel atölyeleri manuel veya hazır şablonlarla yönetin.
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

        {/* Hızlı Şablon Butonları (Presets) */}
        <div className="bg-sand p-4 rounded-2xl border border-line space-y-2.5">
          <div className="flex items-center justify-between">
            <label className="text-xs font-bold text-secondary uppercase tracking-wider flex items-center gap-1.5">
              <Compass className="w-4 h-4 text-espresso" />
              <span>Hızlı Etkinlik Şablonları (Tek Tıkla Doldur)</span>
            </label>
            <span className="text-[11px] text-secondary font-medium">Tıklayıp alanları otomatik doldurun veya elle özgürce yazın</span>
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              onClick={() =>
                applyPreset({
                  turu: 'YURUYUS',
                  baslik: 'Sobo Doğa Yürüyüşü & Açık Hava Kahve Buluşması',
                  kontenjan: 25,
                  ucret: 'Ücretsiz / Tüm Üyelere ve Misafirlere Açık',
                  aciklama: 'Doğanın içinde hafif tempolu yürüyüşün ardından açık havada kahve ve sohbet buluşmamıza tüm Sobo üyelerimizi ve davetlilerini bekliyoruz.',
                })
              }
              className="px-3.5 py-2 rounded-xl text-xs font-bold bg-ivory text-espresso border border-line hover:border-espresso transition-all flex items-center gap-1.5 cursor-pointer shadow-2xs"
            >
              <Footprints className="w-3.5 h-3.5 text-mocha" />
              <span>🚶‍♂️ Doğa Yürüyüşü & Kahve</span>
            </button>

            <button
              type="button"
              onClick={() =>
                applyPreset({
                  turu: 'KAHVE',
                  baslik: 'Sobo Mat Work & Kahve Sohbeti',
                  kontenjan: 15,
                  ucret: 'Ücretsiz / Üyelere Özel',
                  aciklama: 'Stüdyomuzda güne enerjik bir mat seansı ile başlıyor, ardından taze demlenmiş nitelikli kahveler eşliğinde sohbet ediyoruz.',
                })
              }
              className="px-3.5 py-2 rounded-xl text-xs font-bold bg-ivory text-espresso border border-line hover:border-espresso transition-all flex items-center gap-1.5 cursor-pointer shadow-2xs"
            >
              <Coffee className="w-3.5 h-3.5 text-mocha" />
              <span>☕ Mat & Kahve Buluşması</span>
            </button>

            <button
              type="button"
              onClick={() =>
                applyPreset({
                  turu: 'WORKSHOP',
                  baslik: 'Bireysel Postür Düzeltme & Omurga Sağlığı Atölyesi',
                  kontenjan: 10,
                  ucret: 'Üyelere Özel / Seans',
                  aciklama: 'Günlük hayattaki duruş bozukluklarını düzeltmeye ve bel-boyun ağrılarını hafifletmeye yönelik kapsamlı uygulamalı atölye.',
                })
              }
              className="px-3.5 py-2 rounded-xl text-xs font-bold bg-ivory text-espresso border border-line hover:border-espresso transition-all flex items-center gap-1.5 cursor-pointer shadow-2xs"
            >
              <Sparkles className="w-3.5 h-3.5 text-mocha" />
              <span>🧘‍♀️ Postür & Omurga Workshop</span>
            </button>

            <button
              type="button"
              onClick={() =>
                applyPreset({
                  turu: 'SOUNDBATH',
                  baslik: 'Sound Bath & Derin Gevşeme Meditasyonu',
                  kontenjan: 8,
                  ucret: 'Üyelere Özel / Seans',
                  aciklama: 'Tibet ses çanaklarının şifalı titreşimleri eşliğinde zihinsel dinginlik ve derin beden gevşemesi sağlayan özel ses terapisi.',
                })
              }
              className="px-3.5 py-2 rounded-xl text-xs font-bold bg-ivory text-espresso border border-line hover:border-espresso transition-all flex items-center gap-1.5 cursor-pointer shadow-2xs"
            >
              <Sun className="w-3.5 h-3.5 text-mocha" />
              <span>🎵 Ses Çanağı & Meditasyon</span>
            </button>

            <button
              type="button"
              onClick={() => {
                setShowAddForm(true)
                setTuru('OZEL')
                setOzelTuruAdi('Piknik & Etkinlik')
                setBaslik('')
                setAciklama('')
                setKontenjan(20)
                setUcret('')
              }}
              className="px-3.5 py-2 rounded-xl text-xs font-bold bg-espresso text-ivory border border-espresso hover:bg-espresso-dark transition-all flex items-center gap-1.5 cursor-pointer shadow-2xs"
            >
              <Plus className="w-3.5 h-3.5 text-mocha" />
              <span>✏️ Manuel Elle Sıfırdan Yaz</span>
            </button>
          </div>
        </div>

        {/* New Event Form */}
        {showAddForm && (
          <Card className="border border-espresso/30 bg-sand rounded-2xl text-ink shadow-md animate-in fade-in slide-in-from-top-2 duration-200">
            <CardHeader className="border-b border-line pb-4">
              <CardTitle className="flex items-center gap-2 text-lg font-serif font-bold text-ink">
                <Sparkles className="w-5 h-5 text-espresso" />
                <span>Yeni Workshop / Etkinlik Ekle</span>
              </CardTitle>
              <CardDescription className="text-xs text-secondary">
                Doğa yürüyüşü, atölye veya özel buluşma detaylarını elle girin ya da yukarıdaki şablonlardan birini kullanın.
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-6">
              <form onSubmit={handleCreateEvent} className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Etkinlik Türü / Kategorisi</label>
                    <select
                      value={turu}
                      onChange={(e) => setTuru(e.target.value)}
                      className="w-full bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium focus:ring-2 focus:ring-espresso cursor-pointer"
                    >
                      <option value="YURUYUS">🚶‍♂️ Doğa Yürüyüşü & Outdoor</option>
                      <option value="KAHVE">☕ Kahve Buluşması & Sohbet</option>
                      <option value="WORKSHOP">🧘‍♀️ Workshop & Atölye</option>
                      <option value="MEDITASYON">🧘‍♂️ Nefes & Meditasyon</option>
                      <option value="SOUNDBATH">🎵 Ses Çanağı & Terapi</option>
                      <option value="EGITIM">🎓 Eğitmen Eğitimi & Masterclass</option>
                      <option value="ETKINLIK">✨ Özel Stüdyo Etkinliği</option>
                      <option value="OZEL">✏️ Elle Özel Tür Yaz (Manuel)</option>
                    </select>
                  </div>

                  {turu === 'OZEL' && (
                    <div>
                      <label className="block text-xs font-bold text-espresso uppercase mb-1">Manuel Özel Tür Adı</label>
                      <Input
                        placeholder="Örn: Piknik, Bisiklet Turu, Brunch"
                        value={ozelTuruAdi}
                        onChange={(e) => setOzelTuruAdi(e.target.value)}
                        className="bg-ivory border-espresso text-xs font-bold rounded-xl h-11"
                        required
                      />
                    </div>
                  )}

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Etkinlik / Workshop Adı *</label>
                    <Input
                      placeholder="Örn: Sobo Doğa Yürüyüşü & Kahve Buluşması"
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
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-11 cursor-pointer"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Kontenjan (Kişi)</label>
                    <Input
                      type="number"
                      min={1}
                      max={200}
                      value={kontenjan}
                      onChange={(e) => setKontenjan(Number(e.target.value))}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Ücret / Katılım Şartı</label>
                    <Input
                      placeholder="Örn: Ücretsiz, Üyelere Özel veya Bilgi Alınız"
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
                    placeholder="Etkinlik içeriği, toplanma yeri, eğitmen/konuk bilgisi ve katılım gereksinimleri..."
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
              <p>Yukarıdaki hızlı şablonları kullanarak veya sıfırdan manuel girerek etkinlik açabilirsiniz.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {events.map((ev) => (
                <Card key={ev.id} className="border border-line bg-sand rounded-2xl overflow-hidden hover:border-espresso/40 transition-all shadow-xs flex flex-col justify-between">
                  <CardHeader className="pb-3 border-b border-line/60 bg-sand-light/50">
                    <div className="flex items-center justify-between">
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] uppercase font-bold tracking-wider bg-espresso text-ivory">
                        {ev.turu === 'YURUYUS' ? (
                          <Footprints className="w-3 h-3 text-mocha" />
                        ) : ev.turu === 'KAHVE' ? (
                          <Coffee className="w-3 h-3 text-mocha" />
                        ) : (
                          <Sparkles className="w-3 h-3 text-mocha" />
                        )}
                        <span>{ev.turu}</span>
                      </span>
                      <span className="text-xs font-extrabold text-espresso bg-ivory px-2.5 py-1 rounded-lg border border-line">{ev.ucret}</span>
                    </div>
                    <CardTitle className="font-serif text-lg font-bold text-ink mt-2">
                      {ev.baslik}
                    </CardTitle>
                  </CardHeader>

                  <CardContent className="pt-4 space-y-3 text-xs text-secondary font-medium flex-1">
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

                    {/* Katılımcı Durum Rozeti */}
                    <div className="flex items-center justify-between p-2 rounded-xl bg-sand border border-line text-xs font-bold text-ink">
                      <span className="flex items-center gap-1.5 text-secondary">
                        <Users className="w-3.5 h-3.5 text-espresso" />
                        <span>Kayıtlı Katılımcı:</span>
                      </span>
                      <span className="px-2.5 py-0.5 rounded-full bg-espresso text-ivory text-[11px] font-extrabold">
                        {ev.katilimcilar ? ev.katilimcilar.length : (ev.dolu_sayi || 0)} / {ev.kontenjan}
                      </span>
                    </div>

                    {ev.aciklama && (
                      <p className="text-ink/80 text-xs bg-ivory p-3 rounded-xl border border-line leading-relaxed">
                        {ev.aciklama}
                      </p>
                    )}

                    <div className="pt-3 border-t border-line/50 flex flex-wrap gap-2 justify-between items-center">
                      <button
                        onClick={() => setSelectedEventForAttendees(ev)}
                        className="px-3 py-1.5 rounded-lg text-[11px] font-bold bg-espresso text-ivory hover:bg-espresso-dark transition-colors flex items-center gap-1.5 cursor-pointer shadow-2xs"
                      >
                        <Users className="w-3.5 h-3.5 text-mocha" />
                        <span>Katılımcılar ({ev.katilimcilar ? ev.katilimcilar.length : (ev.dolu_sayi || 0)})</span>
                      </button>

                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => openEditModal(ev)}
                          className="px-2.5 py-1.5 rounded-lg text-[11px] font-bold bg-ivory border border-line hover:border-espresso text-espresso transition-colors flex items-center gap-1 cursor-pointer shadow-2xs"
                        >
                          <Edit2 className="w-3.5 h-3.5 text-mocha" />
                          <span>Düzenle</span>
                        </button>

                        <button
                          onClick={() => handleDeleteEvent(ev.id, ev.baslik)}
                          className="px-2.5 py-1.5 rounded-lg text-[11px] font-bold text-clay hover:bg-clay/10 transition-colors flex items-center gap-1 cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                          <span>Sil</span>
                        </button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>
      </main>

      {/* Edit Event Modal */}
      {editingEvent && (
        <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs overflow-y-auto p-4 sm:p-6 flex items-center justify-center min-h-screen">
          <Card className="max-w-md w-full max-h-[90vh] flex flex-col my-auto bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150 overflow-hidden text-ink">
            <CardHeader className="border-b border-line pb-4 relative shrink-0">
              <button
                type="button"
                onClick={() => setEditingEvent(null)}
                className="absolute top-4 right-4 text-secondary hover:text-ink p-1 rounded-full hover:bg-sand cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
              <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                <Edit2 className="w-5 h-5 text-espresso" />
                <span>Etkinlik Detaylarını Düzenle</span>
              </CardTitle>
              <CardDescription className="text-xs text-secondary">
                Etkinlik başlığını, tarihini, kontenjanını ve açıklamasını güncelleyin.
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-6 space-y-4 overflow-y-auto flex-1">
              <form onSubmit={handleUpdateEvent} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-secondary uppercase mb-1">Etkinlik Türü</label>
                  <select
                    value={editTuru}
                    onChange={(e) => setEditTuru(e.target.value)}
                    className="w-full bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium focus:ring-2 focus:ring-espresso"
                  >
                    <option value="YURUYUS">🚶‍♂️ Doğa Yürüyüşü & Outdoor</option>
                    <option value="KAHVE">☕ Kahve Buluşması & Sohbet</option>
                    <option value="WORKSHOP">🧘‍♀️ Workshop & Atölye</option>
                    <option value="MEDITASYON">🧘‍♂️ Nefes & Meditasyon</option>
                    <option value="SOUNDBATH">🎵 Ses Çanağı & Terapi</option>
                    <option value="EGITIM">🎓 Eğitmen Eğitimi & Masterclass</option>
                    <option value="ETKINLIK">✨ Özel Stüdyo Etkinliği</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase mb-1">Etkinlik Adı</label>
                  <Input
                    value={editBaslik}
                    onChange={(e) => setEditBaslik(e.target.value)}
                    className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase mb-1">Tarih & Saat</label>
                  <Input
                    type="datetime-local"
                    value={editTarihSaat}
                    onChange={(e) => setEditTarihSaat(e.target.value)}
                    className="bg-ivory border-line text-xs font-medium rounded-xl h-11 cursor-pointer"
                    required
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Kontenjan</label>
                    <Input
                      type="number"
                      min={1}
                      max={200}
                      value={editKontenjan}
                      onChange={(e) => setEditKontenjan(Number(e.target.value))}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Ücret / Şart</label>
                    <Input
                      value={editUcret}
                      onChange={(e) => setEditUcret(e.target.value)}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase mb-1">Açıklama</label>
                  <textarea
                    rows={3}
                    value={editAciklama}
                    onChange={(e) => setEditAciklama(e.target.value)}
                    className="w-full bg-ivory border border-line rounded-xl p-3 text-xs font-medium text-ink focus:ring-2 focus:ring-espresso"
                  />
                </div>

                {editError && (
                  <div className="p-3 rounded-xl bg-clay/15 text-clay text-xs font-bold border border-clay/30 flex items-center gap-2">
                    <AlertCircle className="w-4 h-4 text-clay shrink-0" />
                    <span>{editError}</span>
                  </div>
                )}

                <div className="pt-2 flex justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setEditingEvent(null)}
                    className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                  >
                    İptal
                  </button>
                  <button
                    type="submit"
                    disabled={updating}
                    className="px-5 py-2.5 rounded-xl font-extrabold text-xs uppercase tracking-wider bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                  >
                    {updating ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle2 className="w-4 h-4" />}
                    <span>ETKİNLİĞİ GÜNCELLE</span>
                  </button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Attendees List Modal */}
      {selectedEventForAttendees && (
        <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs overflow-y-auto p-4 sm:p-6 flex items-center justify-center min-h-screen">
          <Card className="max-w-xl w-full max-h-[90vh] flex flex-col my-auto bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150 overflow-hidden text-ink">
            <CardHeader className="border-b border-line pb-4 relative shrink-0">
              <button
                type="button"
                onClick={() => setSelectedEventForAttendees(null)}
                className="absolute top-4 right-4 text-secondary hover:text-ink p-1 rounded-full hover:bg-sand cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
              <div className="flex items-center gap-2 mb-1">
                <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] uppercase font-bold tracking-wider bg-espresso text-ivory">
                  {selectedEventForAttendees.turu}
                </span>
                <span className="text-xs font-bold text-secondary">
                  {formatDate(selectedEventForAttendees.tarih_saat)} • {formatTime(selectedEventForAttendees.tarih_saat)}
                </span>
              </div>
              <CardTitle className="font-serif text-lg sm:text-xl font-bold text-ink flex items-center gap-2">
                <Users className="w-5 h-5 text-espresso" />
                <span>{selectedEventForAttendees.baslik}</span>
              </CardTitle>
              <CardDescription className="text-xs text-secondary font-medium flex items-center gap-2">
                <span>Kayıtlı Katılımcı Listesi:</span>
                <strong className="text-espresso">
                  {selectedEventForAttendees.katilimcilar ? selectedEventForAttendees.katilimcilar.length : (selectedEventForAttendees.dolu_sayi || 0)} / {selectedEventForAttendees.kontenjan} Kişi
                </strong>
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-4 space-y-3 overflow-y-auto flex-1">
              {(!selectedEventForAttendees.katilimcilar || selectedEventForAttendees.katilimcilar.length === 0) ? (
                <div className="py-12 text-center space-y-2">
                  <Users className="w-10 h-10 text-secondary/50 mx-auto" />
                  <p className="font-serif font-bold text-sm text-ink">Henüz kayıtlı katılımcı bulunmuyor.</p>
                  <p className="text-xs text-secondary">
                    Üyeler veya dışarıdan misafirler workshopa kayıt olduklarında anında burada görünecektir.
                  </p>
                </div>
              ) : (
                <div className="divide-y divide-line/60">
                  {selectedEventForAttendees.katilimcilar.map((att, idx) => {
                    const cleanPhone = att.telefon.replace(/\D/g, '')
                    const waPhone = cleanPhone.startsWith('90')
                      ? cleanPhone
                      : cleanPhone.startsWith('0')
                      ? `90${cleanPhone.slice(1)}`
                      : `90${cleanPhone}`

                    return (
                      <div key={att.rsvp_id || idx} className="py-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 first:pt-0 last:pb-0">
                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <span className="w-6 h-6 rounded-full bg-espresso text-ivory text-xs font-bold flex items-center justify-center">
                              {idx + 1}
                            </span>
                            <span className="font-bold text-sm text-ink">{att.ad}</span>
                            <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold ${
                              att.tek_katilim
                                ? 'bg-amber-100 text-amber-900 border border-amber-300'
                                : 'bg-sage/20 text-sage border border-sage/40'
                            }`}>
                              {att.tek_katilim ? 'Tek Katılım' : 'Sobo Üyesi'}
                            </span>
                          </div>
                          {att.created_at && (
                            <div className="text-[11px] text-secondary pl-8">
                              Kayıt: {formatDate(att.created_at)} {formatTime(att.created_at)}
                            </div>
                          )}
                        </div>

                        <div className="flex items-center gap-2 pl-8 sm:pl-0">
                          <a
                            href={`tel:${att.telefon}`}
                            className="px-2.5 py-1.5 rounded-lg bg-ivory text-ink hover:border-espresso border border-line text-xs font-bold flex items-center gap-1.5 transition-colors shadow-2xs"
                            title="Ara"
                          >
                            <Phone className="w-3.5 h-3.5 text-mocha" />
                            <span>{att.telefon}</span>
                          </a>

                          <a
                            href={`https://wa.me/${waPhone}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="px-2.5 py-1.5 rounded-lg bg-emerald-600 text-white text-xs font-bold hover:bg-emerald-700 flex items-center gap-1.5 transition-colors shadow-2xs"
                            title="WhatsApp Mesaj Gönder"
                          >
                            <MessageCircle className="w-3.5 h-3.5" />
                            <span>WhatsApp</span>
                          </a>

                          <button
                            type="button"
                            onClick={() => handleRemoveAttendee(selectedEventForAttendees.id, att.rsvp_id, att.ad)}
                            disabled={removingRsvpId === att.rsvp_id}
                            className="p-1.5 rounded-lg text-clay hover:bg-clay/10 transition-colors cursor-pointer"
                            title="Katılımcıyı Çıkar"
                          >
                            {removingRsvpId === att.rsvp_id ? (
                              <Loader2 className="w-4 h-4 animate-spin text-clay" />
                            ) : (
                              <Trash2 className="w-4 h-4" />
                            )}
                          </button>
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </CardContent>
            <div className="p-4 border-t border-line bg-sand-light/50 flex justify-end">
              <button
                type="button"
                onClick={() => setSelectedEventForAttendees(null)}
                className="px-4 py-2 rounded-xl text-xs font-bold bg-espresso text-ivory hover:bg-espresso-dark transition-colors cursor-pointer"
              >
                Kapat
              </button>
            </div>
          </Card>
        </div>
      )}
    </div>
  )
}
