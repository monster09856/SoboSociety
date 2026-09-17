'use client'

import React, { useState, useEffect } from 'react'
import { AdminNav } from '@/components/admin/admin-nav'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { apiFetch, ApiError } from '@/lib/api'
import {
  Sparkles,
  CheckCircle2,
  XCircle,
  Clock,
  User,
  Phone,
  Plus,
  Loader2,
  AlertCircle,
  RefreshCw,
  Search,
  MessageSquare,
  Check,
  X
} from 'lucide-react'

interface SingleBookingItem {
  id: number
  durum: 'pending_payment' | 'booked' | 'cancelled' | 'attended'
  kaynak: string
  olusturuldu_utc: string | null
  member: {
    id: number
    ad: string
    telefon: string
    kullanici_adi: string | null
  }
  session: {
    id: number
    baslangic: string
    fiyat_tl: number
    class_type_ad: string
  }
}

interface AdminSessionOption {
  id: number
  baslangic: string
  class_type?: { ad: string } | null
}

export default function SingleBookingsAdminPage() {
  const [bookings, setBookings] = useState<SingleBookingItem[]>([])
  const [sessionsOptions, setSessionsOptions] = useState<AdminSessionOption[]>([])
  const [loading, setLoading] = useState(true)
  const [actionLoadingId, setActionLoadingId] = useState<number | null>(null)
  const [filter, setFilter] = useState<'all' | 'pending_payment' | 'booked' | 'cancelled'>('all')
  const [search, setSearch] = useState('')
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null)

  // New Single Booking Modal State
  const [showAddModal, setShowAddModal] = useState(false)
  const [modalAd, setModalAd] = useState('')
  const [modalTelefon, setModalTelefon] = useState('')
  const [modalSessionId, setModalSessionId] = useState<number | ''>('')
  const [modalDurum, setModalDurum] = useState<'booked' | 'pending_payment'>('booked')
  const [modalSubmitting, setModalSubmitting] = useState(false)

  const loadData = async () => {
    setLoading(true)
    setFeedback(null)
    try {
      const data = await apiFetch<SingleBookingItem[]>('/admin/single-bookings')
      setBookings(data)

      const sess = await apiFetch<AdminSessionOption[]>('/admin/sessions')
      setSessionsOptions(sess)
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Veriler yüklenirken hata oluştu.' })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [])

  const handleApprove = async (bookingId: number) => {
    setActionLoadingId(bookingId)
    setFeedback(null)
    try {
      const res = await apiFetch<{ mesaj: string }>(`/admin/bookings/${bookingId}/approve`, { method: 'POST' })
      setFeedback({ type: 'success', message: res.mesaj || 'Ödeme ve rezervasyon onaylandı!' })
      await loadData()
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Onaylama işlemi başarısız.' })
    } finally {
      setActionLoadingId(null)
    }
  }

  const handleReject = async (bookingId: number) => {
    if (!confirm('Bu rezervasyon talebini iptal etmek istediğinize emin misiniz?')) return
    setActionLoadingId(bookingId)
    setFeedback(null)
    try {
      const res = await apiFetch<{ mesaj: string }>(`/admin/bookings/${bookingId}/reject`, { method: 'POST' })
      setFeedback({ type: 'success', message: res.mesaj || 'Talep iptal edildi.' })
      await loadData()
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'İptal işlemi başarısız.' })
    } finally {
      setActionLoadingId(null)
    }
  }

  const handleCreateSingleBooking = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!modalAd.trim() || !modalTelefon.trim() || !modalSessionId) {
      setFeedback({ type: 'error', message: 'Lütfen Ad Soyad, Telefon ve Ders Oturumu seçiniz.' })
      return
    }

    setModalSubmitting(true)
    try {
      const res = await apiFetch<{ mesaj: string }>('/admin/single-bookings', {
        method: 'POST',
        body: JSON.stringify({
          session_id: Number(modalSessionId),
          ad: modalAd.trim(),
          telefon: modalTelefon.trim(),
          durum: modalDurum,
        }),
      })
      setFeedback({ type: 'success', message: res.mesaj || 'Tek ders kaydı eklendi!' })
      setShowAddModal(false)
      setModalAd('')
      setModalTelefon('')
      setModalSessionId('')
      await loadData()
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Kayıt eklenirken bir hata oluştu.' })
    } finally {
      setModalSubmitting(false)
    }
  }

  const filteredBookings = bookings.filter((b) => {
    if (filter !== 'all' && b.durum !== filter) return false
    if (search.trim()) {
      const q = search.toLowerCase()
      const matchName = b.member.ad.toLowerCase().includes(q)
      const matchPhone = b.member.telefon.includes(q)
      const matchLesson = b.session.class_type_ad.toLowerCase().includes(q)
      return matchName || matchPhone || matchLesson
    }
    return true
  })

  const pendingCount = bookings.filter((b) => b.durum === 'pending_payment').length
  const bookedCount = bookings.filter((b) => b.durum === 'booked').length

  return (
    <div className="min-h-screen bg-ivory text-ink">
      <AdminNav />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        {/* Top Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-3xl border border-line shadow-xs">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <Badge variant="sage" className="uppercase tracking-widest text-[10px] font-extrabold px-3 py-1">
                Yönetici Paneli
              </Badge>
              {pendingCount > 0 && (
                <span className="bg-amber-100 text-amber-900 border border-amber-300 text-xs font-bold px-2.5 py-0.5 rounded-full flex items-center gap-1 animate-pulse">
                  <Clock className="w-3.5 h-3.5" />
                  {pendingCount} Ödeme Bekleyen Var
                </span>
              )}
            </div>
            <h1 className="font-serif text-3xl font-bold text-espresso">
              Tek Ders & Ödeme Talepleri
            </h1>
            <p className="text-secondary text-xs sm:text-sm">
              Siteden üyeliksiz tek ders alan müşterileri görüntüleyin, WhatsApp ödemelerini onaylayın veya manuel kayıt ekleyin.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={loadData}
              disabled={loading}
              className="p-3 rounded-2xl bg-sand border border-line text-secondary hover:text-ink cursor-pointer hover:bg-sand-light transition-all"
              title="Yenile"
            >
              <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
            </button>
            <button
              onClick={() => setShowAddModal(true)}
              className="px-5 py-3 rounded-2xl bg-espresso hover:bg-espresso-dark text-ivory font-extrabold text-xs tracking-wider uppercase shadow-xs transition-all flex items-center gap-2 cursor-pointer"
            >
              <Plus className="w-4 h-4 text-mocha" />
              <span>Tek Ders Kaydı Ekle</span>
            </button>
          </div>
        </div>

        {/* Global Feedback Notice */}
        {feedback && (
          <div
            className={`p-4 rounded-2xl border text-xs font-bold flex items-center justify-between shadow-xs ${
              feedback.type === 'success'
                ? 'bg-sage/20 border-sage/40 text-sage'
                : 'bg-clay/20 border-clay/40 text-clay'
            }`}
          >
            <div className="flex items-center gap-2">
              {feedback.type === 'success' ? <CheckCircle2 className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
              <span>{feedback.message}</span>
            </div>
            <button onClick={() => setFeedback(null)} className="text-secondary hover:text-ink cursor-pointer">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* Filter Ribbon & Search Bar */}
        <div className="flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto pb-2 md:pb-0 no-scrollbar">
            <button
              onClick={() => setFilter('all')}
              className={`px-4 py-2 rounded-xl text-xs font-bold uppercase tracking-wider transition-all cursor-pointer ${
                filter === 'all' ? 'bg-espresso text-white shadow-xs' : 'bg-white text-secondary border border-line hover:text-ink'
              }`}
            >
              Tümü ({bookings.length})
            </button>
            <button
              onClick={() => setFilter('pending_payment')}
              className={`px-4 py-2 rounded-xl text-xs font-bold uppercase tracking-wider transition-all cursor-pointer flex items-center gap-1.5 ${
                filter === 'pending_payment'
                  ? 'bg-amber-600 text-white shadow-xs'
                  : 'bg-amber-50 text-amber-900 border border-amber-200 hover:bg-amber-100'
              }`}
            >
              <Clock className="w-3.5 h-3.5" />
              Ödeme Bekleyenler ({pendingCount})
            </button>
            <button
              onClick={() => setFilter('booked')}
              className={`px-4 py-2 rounded-xl text-xs font-bold uppercase tracking-wider transition-all cursor-pointer flex items-center gap-1.5 ${
                filter === 'booked'
                  ? 'bg-emerald-700 text-white shadow-xs'
                  : 'bg-emerald-50 text-emerald-900 border border-emerald-200 hover:bg-emerald-100'
              }`}
            >
              <CheckCircle2 className="w-3.5 h-3.5" />
              Onaylananlar ({bookedCount})
            </button>
            <button
              onClick={() => setFilter('cancelled')}
              className={`px-4 py-2 rounded-xl text-xs font-bold uppercase tracking-wider transition-all cursor-pointer ${
                filter === 'cancelled'
                  ? 'bg-clay text-white shadow-xs'
                  : 'bg-white text-secondary border border-line hover:text-ink'
              }`}
            >
              İptaller
            </button>
          </div>

          <div className="relative w-full md:w-72">
            <Search className="absolute left-3.5 top-3 w-4 h-4 text-mocha" />
            <input
              type="text"
              placeholder="Ad, telefon veya ders ara..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-white border border-line rounded-2xl h-10 pl-10 pr-4 text-xs font-medium text-ink focus:outline-none focus:border-espresso"
            />
          </div>
        </div>

        {/* Bookings List */}
        {loading ? (
          <div className="py-20 text-center space-y-3">
            <Loader2 className="w-8 h-8 animate-spin mx-auto text-mocha" />
            <p className="text-xs text-secondary font-bold">Tek ders talepleri yükleniyor...</p>
          </div>
        ) : filteredBookings.length === 0 ? (
          <Card className="p-12 text-center bg-white border-line rounded-3xl">
            <Sparkles className="w-10 h-10 mx-auto text-mocha mb-3" />
            <h3 className="font-serif text-lg font-bold text-ink">Henüz Tek Ders Kaydı Bulunmuyor</h3>
            <p className="text-xs text-secondary mt-1">
              Filtrelere uygun tek derslik rezervasyon talebi bulunamadı.
            </p>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredBookings.map((b) => {
              const isPending = b.durum === 'pending_payment'
              const isBooked = b.durum === 'booked'
              const isCancelled = b.durum === 'cancelled'
              const formattedDate = new Date(b.session.baslangic).toLocaleString('tr-TR', {
                weekday: 'short',
                day: 'numeric',
                month: 'short',
                hour: '2-digit',
                minute: '2-digit',
              })

              const cleanTel = b.member.telefon.replace(/\D/g, '')
              const waUrl = `https://wa.me/${cleanTel.startsWith('90') ? cleanTel : '90' + cleanTel}?text=Merhaba%20${encodeURIComponent(b.member.ad)}`

              return (
                <Card
                  key={b.id}
                  className={`relative overflow-hidden bg-white p-6 rounded-3xl border transition-all ${
                    isPending
                      ? 'border-amber-400 bg-amber-50/20 shadow-md'
                      : isBooked
                      ? 'border-emerald-300'
                      : 'border-line opacity-75'
                  }`}
                >
                  <div className="space-y-4">
                    {/* Header: Customer Name & Status Badge */}
                    <div className="flex items-start justify-between gap-3">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <User className="w-4 h-4 text-mocha" />
                          <h3 className="font-serif text-xl font-bold text-ink leading-snug">
                            {b.member.ad}
                          </h3>
                        </div>
                        <div className="flex items-center gap-2 text-xs text-secondary font-medium">
                          <Phone className="w-3.5 h-3.5 text-secondary" />
                          <span>{b.member.telefon || 'Telefon Yok'}</span>
                          {b.member.telefon && (
                            <a
                              href={waUrl}
                              target="_blank"
                              rel="noreferrer"
                              className="text-emerald-700 hover:underline text-[11px] font-bold flex items-center gap-1 ml-1"
                            >
                              <MessageSquare className="w-3 h-3" />
                              WhatsApp
                            </a>
                          )}
                        </div>
                      </div>

                      <Badge
                        variant={
                          isPending
                            ? ('mocha' as const)
                            : isBooked
                            ? ('sage' as const)
                            : ('clay' as const)
                        }
                        className="shrink-0 font-bold"
                      >
                        {isPending ? '⏳ Ödeme Bekliyor' : isBooked ? '✅ Onaylı Kayıt' : '❌ İptal'}
                      </Badge>
                    </div>

                    {/* Lesson Details */}
                    <div className="bg-sand/60 border border-line/60 rounded-2xl p-3.5 space-y-2 text-xs">
                      <div className="flex items-center justify-between">
                        <span className="font-bold text-espresso">{b.session.class_type_ad}</span>
                        <span className="text-[11px] font-bold text-mocha">WhatsApp İletişim</span>
                      </div>
                      <div className="flex items-center gap-2 text-secondary font-medium">
                        <Clock className="w-3.5 h-3.5 text-mocha" />
                        <span>Tarih & Saat: {formattedDate}</span>
                      </div>
                      <div className="text-[11px] text-secondary flex items-center justify-between pt-1 border-t border-line/40">
                        <span>Kayıt Tipi: {b.kaynak === 'web' ? 'Web (Siteden Tek Ders)' : 'Admin'}</span>
                        <span>ID: #{b.id}</span>
                      </div>
                    </div>

                    {/* Admin Action Buttons */}
                    <div className="pt-2 flex items-center gap-2">
                      {isPending && (
                        <>
                          <button
                            type="button"
                            disabled={actionLoadingId === b.id}
                            onClick={() => handleApprove(b.id)}
                            className="flex-1 h-10 rounded-2xl bg-emerald-700 hover:bg-emerald-800 text-white font-extrabold text-xs uppercase tracking-wider shadow-xs transition-all flex items-center justify-center gap-1.5 cursor-pointer disabled:opacity-50"
                          >
                            {actionLoadingId === b.id ? (
                              <Loader2 className="w-4 h-4 animate-spin" />
                            ) : (
                              <>
                                <Check className="w-4 h-4" />
                                <span>ÖDEMEYİ ONAYLA</span>
                              </>
                            )}
                          </button>

                          <button
                            type="button"
                            disabled={actionLoadingId === b.id}
                            onClick={() => handleReject(b.id)}
                            className="h-10 px-3.5 rounded-2xl border border-clay/40 bg-clay/10 hover:bg-clay text-clay hover:text-white font-bold text-xs transition-all flex items-center justify-center cursor-pointer disabled:opacity-50"
                            title="Talebi İptal Et"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        </>
                      )}

                      {isBooked && (
                        <button
                          type="button"
                          disabled={actionLoadingId === b.id}
                          onClick={() => handleReject(b.id)}
                          className="w-full h-9 rounded-xl border border-line bg-sand-light hover:bg-sand text-secondary hover:text-clay font-bold text-xs transition-all flex items-center justify-center gap-1 cursor-pointer disabled:opacity-50"
                        >
                          <span>Rezervasyonu İptal Et</span>
                        </button>
                      )}
                    </div>
                  </div>
                </Card>
              )
            })}
          </div>
        )}
      </main>

      {/* Admin Manual Single Booking Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center bg-black/40 backdrop-blur-xs p-4 sm:p-6 min-h-screen">
          <div className="bg-ivory border border-line rounded-3xl p-6 sm:p-8 max-w-md w-full max-h-[90vh] overflow-y-auto shadow-2xl relative my-auto flex flex-col">
            <button
              onClick={() => setShowAddModal(false)}
              className="absolute top-4 right-4 text-secondary hover:text-ink p-1 rounded-full hover:bg-sand cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-2xl bg-espresso text-white flex items-center justify-center">
                <Plus className="w-6 h-6 text-mocha" />
              </div>
              <div>
                <h3 className="font-serif text-xl font-bold text-ink">Manuel Tek Ders Kaydı</h3>
                <p className="text-xs text-secondary font-medium">Müşteri için tek derslik rezervasyon oluşturun.</p>
              </div>
            </div>

            <form onSubmit={handleCreateSingleBooking} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  Müşteri Ad Soyad
                </label>
                <input
                  type="text"
                  required
                  placeholder="Müşterinin Adı Soyadı"
                  value={modalAd}
                  onChange={(e) => setModalAd(e.target.value)}
                  className="w-full bg-sand/60 border border-line rounded-2xl h-11 px-4 text-xs font-bold text-ink focus:outline-none focus:border-espresso"
                  disabled={modalSubmitting}
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  Cep Telefonu
                </label>
                <input
                  type="tel"
                  required
                  placeholder="0532 XXX XX XX"
                  value={modalTelefon}
                  onChange={(e) => setModalTelefon(e.target.value)}
                  className="w-full bg-sand/60 border border-line rounded-2xl h-11 px-4 text-xs font-bold text-ink focus:outline-none focus:border-espresso"
                  disabled={modalSubmitting}
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  Ders Oturumu Seçin
                </label>
                <select
                  required
                  value={modalSessionId}
                  onChange={(e) => setModalSessionId(Number(e.target.value) || '')}
                  className="w-full bg-sand/60 border border-line rounded-2xl h-11 px-4 text-xs font-bold text-ink focus:outline-none focus:border-espresso"
                  disabled={modalSubmitting}
                >
                  <option value="">-- Ders Oturumu Seçiniz --</option>
                  {sessionsOptions.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.class_type?.ad || 'Ders'} - {new Date(s.baslangic).toLocaleString('tr-TR', { weekday: 'short', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  Ödeme Durumu
                </label>
                <select
                  value={modalDurum}
                  onChange={(e) => setModalDurum(e.target.value as any)}
                  className="w-full bg-sand/60 border border-line rounded-2xl h-11 px-4 text-xs font-bold text-ink focus:outline-none focus:border-espresso"
                  disabled={modalSubmitting}
                >
                  <option value="booked">Ödeme Alındı (Kesin Kayıt)</option>
                  <option value="pending_payment">Ödeme Bekliyor (Talep)</option>
                </select>
              </div>

              <div className="pt-3 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                >
                  Vazgeç
                </button>
                <button
                  type="submit"
                  disabled={modalSubmitting}
                  className="px-5 py-2.5 rounded-xl text-xs font-bold bg-espresso hover:bg-espresso-dark text-white uppercase tracking-wider shadow-xs cursor-pointer disabled:opacity-50 flex items-center gap-2"
                >
                  {modalSubmitting ? <Loader2 className="w-4 h-4 animate-spin" /> : 'KAYDI EKLE'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
