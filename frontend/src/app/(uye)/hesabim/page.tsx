'use client'

import React, { useEffect, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { api, MemberSummaryResponse, ApiError, MemberMeResponse } from '@/lib/api'
import { getToken, logout } from '@/lib/auth'
import { CreditBadge } from '@/components/uye/credit-badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { buyukHarf } from '@/lib/utils'
import {
  Phone,
  Calendar,
  Clock,
  LogOut,
  ChevronLeft,
  Loader2,
  CheckCircle2,
  AlertCircle,
  History,
  Sparkles,
  Package,
  Activity,
  Save,
  Ruler,
} from 'lucide-react'

export default function HesabimPage() {
  const router = useRouter()
  const [summary, setSummary] = useState<MemberSummaryResponse | null>(null)
  const [me, setMe] = useState<MemberMeResponse | null>(null)
  const [loading, setLoading] = useState<boolean>(true)
  const [cancelLoadingId, setCancelLoadingId] = useState<number | null>(null)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)
  const [successMsg, setSuccessMsg] = useState<string | null>(null)

  // Body Measurements Form State
  const [savingMeasurements, setSavingMeasurements] = useState(false)
  const [bel, setBel] = useState('')
  const [kalca, setKalca] = useState('')
  const [sagIcBacak, setSagIcBacak] = useState('')
  const [sagBacak, setSagBacak] = useState('')
  const [solIcBacak, setSolIcBacak] = useState('')
  const [solBacak, setSolBacak] = useState('')
  const [sagKol, setSagKol] = useState('')
  const [solKol, setSolKol] = useState('')
  const [boy, setBoy] = useState('')
  const [kilo, setKilo] = useState('')
  const [saglikNotu, setSaglikNotu] = useState('')

  const fetchSummary = async () => {
    setLoading(true)
    setErrorMsg(null)
    const token = getToken()
    if (!token) {
      router.push('/giris')
      return
    }

    try {
      const [sumData, meData] = await Promise.all([
        api.my.getSummary(),
        api.auth.getMe(),
      ])
      setSummary(sumData)
      setMe(meData)

      // Prefill measurement fields
      setBel(meData.bel || '')
      setKalca(meData.kalca || '')
      setSagIcBacak(meData.sag_ic_bacak || '')
      setSagBacak(meData.sag_bacak || '')
      setSolIcBacak(meData.sol_ic_bacak || '')
      setSolBacak(meData.sol_bacak || '')
      setSagKol(meData.sag_kol || '')
      setSolKol(meData.sol_kol || '')
      setBoy(meData.boy || '')
      setKilo(meData.kilo || '')
      setSaglikNotu(meData.saglik_notu || '')
    } catch (err) {
      console.error('Failed to fetch user summary:', err)
      if (err instanceof ApiError && err.status === 401) {
        logout('/giris')
        return
      }
      setErrorMsg('Hesap bilgileri yüklenirken bir sorun oluştu.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchSummary()
  }, [])

  const handleSaveMeasurements = async (e: React.FormEvent) => {
    e.preventDefault()
    setSavingMeasurements(true)
    setErrorMsg(null)
    setSuccessMsg(null)

    try {
      const updated = await api.auth.updateMe({
        bel,
        kalca,
        sag_ic_bacak: sagIcBacak,
        sag_bacak: sagBacak,
        sol_ic_bacak: solIcBacak,
        sol_bacak: solBacak,
        sag_kol: sagKol,
        sol_kol: solKol,
        boy,
        kilo,
        saglik_notu: saglikNotu,
      })
      setMe(updated)
      setSuccessMsg('Vücut ölçüleriniz ve form bilgileriniz başarıyla güncellendi!')
    } catch (err: any) {
      setErrorMsg(err?.message || 'Ölçüler güncellenirken hata oluştu.')
    } finally {
      setSavingMeasurements(false)
    }
  }

  const handleCancelBooking = async (bookingId: number) => {
    setCancelLoadingId(bookingId)
    setErrorMsg(null)
    setSuccessMsg(null)
    try {
      await api.bookings.cancel(bookingId)
      setSuccessMsg('Rezervasyonunuz başarıyla iptal edildi.')
      await fetchSummary()
    } catch (err) {
      const msg =
        err instanceof ApiError ? err.message : 'İptal işlemi yapılamadı.'
      setErrorMsg(msg)
    } finally {
      setCancelLoadingId(null)
    }
  }

  const formatDateTime = (dateStr?: string) => {
    if (!dateStr) return '-'
    const d = new Date(dateStr)
    return d.toLocaleDateString('tr-TR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  const getStatusBadge = (durum: string) => {
    switch (durum) {
      case 'attended':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-sage/15 text-sage border border-sage/40 shadow-xs">
            <span className="w-1.5 h-1.5 rounded-full bg-sage" />
            Katıldı
          </span>
        )
      case 'no_show':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-clay/15 text-clay border border-clay/40 shadow-xs">
            <span className="w-1.5 h-1.5 rounded-full bg-clay" />
            Gelmedi
          </span>
        )
      case 'booked':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-espresso/15 text-espresso border border-espresso/40 shadow-xs">
            <span className="w-1.5 h-1.5 rounded-full bg-espresso" />
            Rezerve
          </span>
        )
      case 'cancelled':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-line/60 text-secondary border border-line">
            İptal Edildi
          </span>
        )
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-sand text-ink border border-line">
            {durum}
          </span>
        )
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-ivory text-ink flex items-center justify-center">
        <div className="flex flex-col items-center gap-3 text-secondary">
          <Loader2 className="w-8 h-8 animate-spin text-espresso" />
          <p className="text-sm font-semibold text-secondary">Hesap bilgileri yükleniyor...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-ivory text-ink flex flex-col antialiased">
      {/* Header */}
      <header className="sticky top-0 z-30 bg-ivory/95 backdrop-blur-md border-b border-line px-4 py-3 shadow-xs">
        <div className="max-w-md mx-auto flex items-center justify-between">
          <Link
            href="/rezervasyon"
            className="flex items-center gap-1 text-sm font-semibold text-secondary hover:text-espresso transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
            <span>Program</span>
          </Link>
          <span className="font-serif text-xl font-bold tracking-widest text-espresso uppercase">
            ÜYELİĞİM
          </span>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => logout('/giris')}
            className="text-secondary hover:text-clay gap-1 text-xs font-semibold"
          >
            <LogOut className="w-3.5 h-3.5" />
            <span>Çıkış</span>
          </Button>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 max-w-md w-full mx-auto px-4 py-6 space-y-6">
        {/* Messages */}
        {errorMsg && (
          <div className="p-3.5 rounded-2xl bg-clay/15 border border-clay/40 text-clay text-xs font-medium flex items-center gap-2.5 shadow-xs">
            <AlertCircle className="w-4 h-4 text-clay shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}
        {successMsg && (
          <div className="p-3.5 rounded-2xl bg-sage/15 border border-sage/40 text-sage text-xs font-medium flex items-center gap-2.5 shadow-xs">
            <CheckCircle2 className="w-4 h-4 text-sage shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        {/* Member Profile Card */}
        {summary && (
          <div className="p-6 rounded-2xl bg-sand border border-line shadow-xs space-y-5">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-2xl bg-espresso text-ivory flex items-center justify-center font-serif font-extrabold text-xl shadow-xs">
                  {summary.ad.charAt(0).toUpperCase()}
                </div>
                <div className="space-y-0.5">
                  <h2 className="font-serif text-2xl font-bold text-ink">
                    {buyukHarf(summary.ad)}
                  </h2>
                  <div className="flex items-center gap-1.5 text-xs text-secondary font-medium">
                    <Phone className="w-3.5 h-3.5 text-mocha" />
                    <span>{summary.telefon || me?.kullanici_adi || 'Kayıtlı Üye'}</span>
                  </div>
                </div>
              </div>
              <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-[10px] font-extrabold uppercase bg-sage/15 text-sage border border-sage/30">
                <Sparkles className="w-3 h-3 text-sage" />
                Aktif Üye
              </span>
            </div>

            {/* Aktif Paket & Bakiye Kartı */}
            <div className="pt-4 border-t border-line/80 space-y-3">
              <div className="flex items-center justify-between text-xs font-bold text-secondary uppercase tracking-wider">
                <span className="flex items-center gap-1.5">
                  <Package className="w-4 h-4 text-mocha" />
                  Aktif Paket Durumu
                </span>
                <span className="text-sage font-extrabold">Geçerli Paket</span>
              </div>

              <div className="bg-ivory/80 rounded-xl p-3.5 border border-line flex items-center justify-between">
                <CreditBadge credits={summary.bakiye} />
                <Link href="/rezervasyon">
                  <Button size="sm" className="text-xs font-bold bg-espresso hover:bg-espresso-dark text-ivory border-none shadow-xs rounded-xl px-4">
                    Ders Seç
                  </Button>
                </Link>
              </div>
            </div>
          </div>
        )}

        {/* Vücut Ölçülerim & Form Bilgilerim Form Card */}
        <div className="p-6 rounded-2xl bg-sand border border-line shadow-xs space-y-4">
          <div className="flex items-center justify-between border-b border-line/80 pb-3">
            <div className="flex items-center gap-2">
              <Ruler className="w-5 h-5 text-espresso" />
              <h3 className="font-serif text-lg font-bold text-ink tracking-wide">
                Vücut Ölçülerim & Form
              </h3>
            </div>
            <span className="text-[11px] font-bold text-mocha">Stüdyo Takibi</span>
          </div>
          <p className="text-xs text-secondary font-medium leading-relaxed">
            Eğitmenlerimizin takibi için vücut ölçülerinizi ve gelişim bilgilerinizi buraya girebilirsiniz.
          </p>

          <form onSubmit={handleSaveMeasurements} className="space-y-4 pt-1">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Bel</label>
                <Input
                  type="text"
                  placeholder="Örn: 68 cm"
                  value={bel}
                  onChange={(e) => setBel(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Kalça</label>
                <Input
                  type="text"
                  placeholder="Örn: 94 cm"
                  value={kalca}
                  onChange={(e) => setKalca(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sağ İç Bacak</label>
                <Input
                  type="text"
                  placeholder="Örn: 52 cm"
                  value={sagIcBacak}
                  onChange={(e) => setSagIcBacak(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sağ Bacak</label>
                <Input
                  type="text"
                  placeholder="Örn: 54 cm"
                  value={sagBacak}
                  onChange={(e) => setSagBacak(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sol İç Bacak</label>
                <Input
                  type="text"
                  placeholder="Örn: 52 cm"
                  value={solIcBacak}
                  onChange={(e) => setSolIcBacak(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sol Bacak</label>
                <Input
                  type="text"
                  placeholder="Örn: 54 cm"
                  value={solBacak}
                  onChange={(e) => setSolBacak(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sağ Kol</label>
                <Input
                  type="text"
                  placeholder="Örn: 27 cm"
                  value={sagKol}
                  onChange={(e) => setSagKol(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sol Kol</label>
                <Input
                  type="text"
                  placeholder="Örn: 27 cm"
                  value={solKol}
                  onChange={(e) => setSolKol(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Boy</label>
                <Input
                  type="text"
                  placeholder="Örn: 168 cm"
                  value={boy}
                  onChange={(e) => setBoy(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Kilo</label>
                <Input
                  type="text"
                  placeholder="Örn: 56 kg"
                  value={kilo}
                  onChange={(e) => setKilo(e.target.value)}
                  className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                />
              </div>
            </div>

            <div>
              <label className="block text-[11px] font-bold text-secondary uppercase mb-1">
                Hedef, Sakatlık veya Özel Notlar
              </label>
              <textarea
                rows={2}
                placeholder="Örn: Bel fıtığı hassasiyeti var, bacak ve kalça sıkılaşması hedefleniyor."
                value={saglikNotu}
                onChange={(e) => setSaglikNotu(e.target.value)}
                className="w-full bg-ivory border border-line text-xs font-medium rounded-xl p-3 focus:ring-2 focus:ring-espresso text-ink"
              />
            </div>

            <Button
              type="submit"
              disabled={savingMeasurements}
              className="w-full h-11 bg-espresso hover:bg-espresso-dark text-ivory font-bold text-xs uppercase tracking-wider rounded-xl flex items-center justify-center gap-2 shadow-xs border-none cursor-pointer"
            >
              {savingMeasurements ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
              <span>Ölçülerimi Kaydet</span>
            </Button>
          </form>
        </div>

        {/* Aktif Rezervasyonlar Section */}
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Calendar className="w-4 h-4 text-espresso" />
            <h3 className="font-serif text-lg font-bold text-ink tracking-wide">
              Aktif Rezervasyonlarım
            </h3>
          </div>

          {summary?.aktif_rezervasyonlar &&
          summary.aktif_rezervasyonlar.length > 0 ? (
            <div className="space-y-3">
              {summary.aktif_rezervasyonlar.map((booking) => {
                const session = booking.session
                const classType = session?.class_type
                const instructor = session?.instructor

                return (
                  <div
                    key={booking.id}
                    className="p-4 rounded-2xl bg-sand/80 border border-line shadow-xs flex flex-col gap-3 hover:border-mocha/60 transition-all"
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <h4 className="font-serif text-base font-bold text-ink">
                          {classType ? buyukHarf(classType.ad) : 'Ders Oturumu'}
                        </h4>
                        {instructor && (
                          <p className="text-xs text-secondary font-medium mt-0.5">
                            Eğitmen: <strong className="text-ink">{instructor.ad}</strong>
                          </p>
                        )}
                      </div>
                      {getStatusBadge(booking.durum)}
                    </div>

                    <div className="flex items-center justify-between pt-2.5 border-t border-line/60 text-xs">
                      <div className="flex items-center gap-1.5 font-medium text-secondary">
                        <Clock className="w-3.5 h-3.5 text-espresso" />
                        <span>{formatDateTime(session?.baslangic)}</span>
                      </div>

                      {booking.durum === 'booked' && (
                        <Button
                          variant="destructive"
                          size="sm"
                          disabled={cancelLoadingId === booking.id}
                          onClick={() => handleCancelBooking(booking.id)}
                          className="h-7 text-xs px-3 font-bold bg-clay hover:bg-clay/90 text-white rounded-xl shadow-xs border-none"
                        >
                          {cancelLoadingId === booking.id ? (
                            <Loader2 className="w-3 h-3 animate-spin" />
                          ) : (
                            'İptal Et'
                          )}
                        </Button>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="p-4 rounded-2xl bg-sand/40 border border-dashed border-line text-center text-xs text-secondary font-medium">
              Aktif bir ders rezervasyonunuz bulunmamaktadır.
            </div>
          )}
        </div>

        {/* Geçmiş Katılım Kayıtları Section */}
        <div className="space-y-3 pt-2">
          <div className="flex items-center gap-2">
            <History className="w-4 h-4 text-mocha" />
            <h3 className="font-serif text-lg font-bold text-ink tracking-wide">
              Geçmiş Ders Katılımları
            </h3>
          </div>

          {summary?.gecmis_rezervasyonlar &&
          summary.gecmis_rezervasyonlar.length > 0 ? (
            <div className="space-y-2.5">
              {summary.gecmis_rezervasyonlar.map((booking) => {
                const session = booking.session
                const classType = session?.class_type
                const instructor = session?.instructor

                return (
                  <div
                    key={booking.id}
                    className="p-3.5 rounded-2xl bg-sand/40 border border-line flex items-center justify-between text-xs hover:bg-sand/70 transition-colors"
                  >
                    <div className="space-y-1">
                      <p className="font-serif text-sm font-bold text-ink">
                        {classType ? buyukHarf(classType.ad) : 'Geçmiş Ders'}
                      </p>
                      <p className="text-[11px] text-secondary font-medium">
                        {formatDateTime(session?.baslangic)}
                        {instructor ? ` • ${instructor.ad}` : ''}
                      </p>
                    </div>
                    {getStatusBadge(booking.durum)}
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="p-4 rounded-2xl bg-sand/40 border border-dashed border-line text-center text-xs text-secondary font-medium">
              Geçmiş ders kaydı bulunmamaktadır.
            </div>
          )}
        </div>
      </main>
    </div>
  )
}
