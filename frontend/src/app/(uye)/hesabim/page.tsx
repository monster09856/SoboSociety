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
  X,
  KeyRound,
  CreditCard,
  Users,
  User,
} from 'lucide-react'

export default function HesabimPage() {
  const router = useRouter()
  const [summary, setSummary] = useState<MemberSummaryResponse | null>(null)
  const [me, setMe] = useState<MemberMeResponse | null>(null)
  const [myWorkshops, setMyWorkshops] = useState<any[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [cancelLoadingId, setCancelLoadingId] = useState<number | null>(null)
  const [cancelWorkshopId, setCancelWorkshopId] = useState<number | null>(null)
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

  // Password Change Form State
  const [showPasswordModal, setShowPasswordModal] = useState(false)
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [changingPassword, setChangingPassword] = useState(false)
  const [pwError, setPwError] = useState<string | null>(null)
  const [pwSuccess, setPwSuccess] = useState<string | null>(null)

  const fetchSummary = async () => {
    setLoading(true)
    setErrorMsg(null)
    const token = getToken()
    if (!token) {
      router.push('/giris')
      return
    }

    try {
      const [sumData, meData, workshopsData] = await Promise.all([
        api.my.getSummary(),
        api.auth.getMe(),
        api.events.myRsvps().catch(() => []),
      ])
      setSummary(sumData)
      setMe(meData)
      setMyWorkshops(workshopsData || [])

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

  const handleCancelBooking = async (bookingId: number, classTitle?: string) => {
    if (!confirm(`"${classTitle || 'Ders'}" rezervasyonunuzu iptal etmek istediğinizden emin misiniz? 1 ders hakkınız hesabınıza iade edilecek ve sınıfta yer açılacaktır.`)) return
    setCancelLoadingId(bookingId)
    setErrorMsg(null)
    setSuccessMsg(null)
    try {
      const res = await api.bookings.cancel(bookingId)
      setSuccessMsg(res?.mesaj || 'Rezervasyonunuz başarıyla iptal edildi.')
      await fetchSummary()
    } catch (err) {
      const msg =
        err instanceof ApiError ? err.message : 'İptal işlemi yapılamadı.'
      setErrorMsg(msg)
    } finally {
      setCancelLoadingId(null)
    }
  }

  const handleCancelWorkshop = async (eventId: number, eventTitle: string) => {
    if (!confirm(`"${eventTitle}" workshop kaydınızı iptal etmek istediğinizden emin misiniz?`)) return
    setCancelWorkshopId(eventId)
    setErrorMsg(null)
    setSuccessMsg(null)
    try {
      await api.events.cancelRsvp(eventId)
      setSuccessMsg(`"${eventTitle}" workshop kaydınız başarıyla iptal edildi.`)
      setMyWorkshops((prev) => prev.filter((w) => w.id !== eventId))
    } catch (err: any) {
      setErrorMsg(err?.message || 'Workshop iptal edilirken bir hata oluştu.')
    } finally {
      setCancelWorkshopId(null)
    }
  }

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    setPwError(null)
    setPwSuccess(null)

    if (!newPassword.trim()) {
      setPwError('Lütfen yeni bir şifre girin.')
      return
    }
    if (newPassword.length < 4) {
      setPwError('Yeni şifreniz en az 4 karakter olmalıdır.')
      return
    }
    if (newPassword !== confirmPassword) {
      setPwError('Yeni şifreleriniz birbiriyle eşleşmiyor.')
      return
    }

    setChangingPassword(true)
    try {
      const res = await api.auth.changePassword({
        mevcut_sifre: currentPassword.trim() || undefined,
        yeni_sifre: newPassword.trim(),
      })
      setPwSuccess(res.mesaj || 'Şifreniz başarıyla güncellendi! ✨')
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
      setTimeout(() => {
        setShowPasswordModal(false)
        setPwSuccess(null)
      }, 2000)
    } catch (err: any) {
      setPwError(err?.message || 'Şifre güncellenirken bir hata oluştu.')
    } finally {
      setChangingPassword(false)
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
                  <div className="flex items-center gap-2 pt-1.5">
                    <button
                      type="button"
                      onClick={() => { setShowPasswordModal(true); setPwError(null); setPwSuccess(null); }}
                      className="px-2.5 py-1 rounded-xl bg-ivory border border-line text-[11px] font-bold text-espresso hover:bg-sand transition-all flex items-center gap-1.5 cursor-pointer shadow-2xs"
                    >
                      <KeyRound className="w-3 h-3 text-mocha" />
                      <span>Şifremi Değiştir</span>
                    </button>
                  </div>
                </div>
              </div>
              <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-[10px] font-extrabold uppercase bg-sage/15 text-sage border border-sage/30">
                <Sparkles className="w-3 h-3 text-sage" />
                Aktif Üye
              </span>
            </div>

            {/* Aktif Paket & Kategori Bazlı Bakiye Kutucukları */}
            <div className="pt-4 border-t border-line/80 space-y-3">
              <div className="flex items-center justify-between text-xs font-bold text-secondary uppercase tracking-wider">
                <span className="flex items-center gap-1.5">
                  <Package className="w-4 h-4 text-mocha" />
                  Ders Hakları & Paket Durumu
                </span>
                <span className="text-sage font-extrabold">
                  {summary.bakiye > 0 ? `${summary.bakiye} Toplam Hak` : 'Paket Yok'}
                </span>
              </div>

              {/* İki Farklı Paket (Grup & Bireysel) Durumu */}
              {(summary.bireysel_bakiye ?? 0) > 0 && (summary.grup_bakiye ?? 0) > 0 ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {/* Grup Dersi Kutucuğu */}
                  <div className="bg-ivory/90 rounded-2xl p-4 border border-line shadow-xs space-y-2 flex flex-col justify-between">
                    <div>
                      <div className="flex items-center justify-between">
                        <span className="inline-flex items-center gap-1 text-[11px] font-extrabold uppercase tracking-wide text-forest bg-sage/15 px-2.5 py-0.5 rounded-full">
                          <Users className="w-3 h-3 text-forest" />
                          Grup Dersleri
                        </span>
                        <span className="text-xs text-secondary font-medium">Barre / Yoga</span>
                      </div>
                      <div className="mt-2.5 flex items-baseline gap-1.5">
                        <span className="text-3xl font-serif font-bold text-ink">
                          {summary.grup_bakiye}
                        </span>
                        <span className="text-xs text-secondary font-bold">Ders Hakkı</span>
                      </div>
                    </div>
                    <Link href="/rezervasyon" className="mt-2 block">
                      <Button size="sm" className="w-full text-xs font-bold bg-espresso hover:bg-espresso-dark text-ivory border-none shadow-xs rounded-xl py-2">
                        Grup Dersi Seç
                      </Button>
                    </Link>
                  </div>

                  {/* Bireysel Seans Kutucuğu */}
                  <div className="bg-amber-50/60 rounded-2xl p-4 border border-amber-200/80 shadow-xs space-y-2 flex flex-col justify-between">
                    <div>
                      <div className="flex items-center justify-between">
                        <span className="inline-flex items-center gap-1 text-[11px] font-extrabold uppercase tracking-wide text-amber-900 bg-amber-200/70 px-2.5 py-0.5 rounded-full">
                          <User className="w-3 h-3 text-amber-800" />
                          Bireysel Seans
                        </span>
                        <span className="text-xs text-amber-800 font-medium">1-on-1 Reformer</span>
                      </div>
                      <div className="mt-2.5 flex items-baseline gap-1.5">
                        <span className="text-3xl font-serif font-bold text-amber-950">
                          {summary.bireysel_bakiye}
                        </span>
                        <span className="text-xs text-amber-900 font-bold">Seans Hakkı</span>
                      </div>
                    </div>
                    <div className="mt-2 text-[11px] text-amber-800/90 font-medium text-center py-1.5 bg-amber-100/60 rounded-xl">
                      Eğitmen Eşliğinde Özel Seans ✨
                    </div>
                  </div>
                </div>
              ) : (summary.bireysel_bakiye ?? 0) > 0 ? (
                /* Sadece Bireysel Paketi Olan Üye */
                <div className="bg-amber-50/70 rounded-2xl p-4 border border-amber-200 shadow-xs flex items-center justify-between">
                  <div className="space-y-1">
                    <span className="inline-flex items-center gap-1 text-[11px] font-extrabold uppercase tracking-wide text-amber-900 bg-amber-200 px-2.5 py-0.5 rounded-full">
                      <User className="w-3 h-3 text-amber-800" />
                      Bireysel Özel Seans
                    </span>
                    <div className="flex items-baseline gap-1.5 pt-1">
                      <span className="text-2xl font-serif font-bold text-amber-950">
                        {summary.bireysel_bakiye}
                      </span>
                      <span className="text-xs text-amber-900 font-bold">Kalan Özel Seans</span>
                    </div>
                  </div>
                  <span className="text-xs text-amber-800 font-semibold">1-on-1 Reformer ✨</span>
                </div>
              ) : (
                /* Standart Grup Paketi veya Tek Paket */
                <div className="bg-ivory/80 rounded-2xl p-3.5 border border-line flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <CreditBadge credits={summary.bakiye} />
                    {summary.aktif_paket_adi && (
                      <span className="text-xs text-secondary font-medium hidden sm:inline">
                        {summary.aktif_paket_adi}
                      </span>
                    )}
                  </div>
                  <Link href="/rezervasyon">
                    <Button size="sm" className="text-xs font-bold bg-espresso hover:bg-espresso-dark text-ivory border-none shadow-xs rounded-xl px-4">
                      Ders Seç
                    </Button>
                  </Link>
                </div>
              )}

              {/* Tanımlı Paketlerin Listesi ve Bitiş Tarihleri */}
              {summary.paketler && summary.paketler.length > 0 && (
                <div className="space-y-1.5 pt-1">
                  {summary.paketler.map((pkg) => (
                    <div
                      key={pkg.id}
                      className="px-3 py-2 rounded-xl bg-sand-light/60 border border-line/60 flex items-center justify-between text-xs"
                    >
                      <div className="flex items-center gap-2">
                        <span className={`w-2 h-2 rounded-full ${pkg.aktif ? 'bg-sage' : 'bg-secondary/40'}`} />
                        <span className="font-semibold text-ink">{pkg.ad}</span>
                        <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-sand border border-line text-secondary">
                          {pkg.kategori || 'Grup'}
                        </span>
                      </div>
                      <div className="text-secondary text-[11px] font-medium">
                        Kalan: <strong className="text-espresso">{pkg.kalan_ders ?? pkg.toplam_ders} ders</strong> • Bitiş: {pkg.bitis_tarihi || '-'} ({pkg.kalan_gun} gün)
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Borç / Bekleyen Ödeme Durumu Kartı */}
            {(summary.borc_bakiye ?? 0) > 0 ? (
              <div className="p-4 rounded-2xl bg-amber-50 border border-amber-300 text-amber-950 shadow-xs space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2 font-bold text-xs uppercase tracking-wider text-amber-800">
                    <CreditCard className="w-4 h-4 text-amber-700" />
                    <span>Bekleyen Paket Ödemesi</span>
                  </div>
                  <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold uppercase bg-amber-200 text-amber-900 border border-amber-300">
                    Ödeme Bekleniyor
                  </span>
                </div>
                <div className="flex items-baseline justify-between pt-0.5">
                  <div>
                    <span className="text-2xl font-serif font-bold text-amber-950">
                      {summary.borc_bakiye} TL
                    </span>
                    <span className="text-xs text-amber-800 font-medium ml-1.5">Borç Bakiyesi</span>
                  </div>
                  <span className="text-[11px] font-semibold text-amber-800">
                    Dersleriniz Aktif ✨
                  </span>
                </div>
                <p className="text-[11px] text-amber-800/90 leading-relaxed border-t border-amber-200 pt-2">
                  Paket ödemenizi stüdyo resepsiyonunda nakit/kart veya banka havalesi ile gerçekleştirebilirsiniz. Sorularınız için eğitmenimizle iletişime geçebilirsiniz.
                </p>
              </div>
            ) : (
              <div className="p-3 rounded-xl bg-sage/10 border border-sage/30 flex items-center justify-between text-xs">
                <span className="font-bold text-sage flex items-center gap-1.5">
                  <CheckCircle2 className="w-3.5 h-3.5 text-sage" />
                  Ödeme Durumu: Borcunuz Bulunmamaktadır
                </span>
                <span className="font-extrabold text-sage text-[11px]">0 TL</span>
              </div>
            )}

            {/* Haftalık Sabit Ders Programı (Eda Hanım Tanımlı) */}
            {summary.sabit_ders_saatleri && summary.sabit_ders_saatleri.trim().length > 0 && (
              <div className="pt-4 border-t border-line/80 space-y-2">
                <div className="p-4 rounded-2xl bg-sage/15 border border-sage/40 space-y-1.5">
                  <div className="flex items-center gap-2 text-sage font-extrabold text-xs uppercase tracking-wider">
                    <Clock className="w-4 h-4 text-sage" />
                    <span>HAFTALIK SABİT DERS PROGRAMINIZ</span>
                  </div>
                  <div className="font-serif text-xl font-bold text-ink">
                    {summary.sabit_ders_saatleri}
                  </div>
                  <p className="text-[11px] text-secondary leading-relaxed">
                    Stüdyomuzdaki yeriniz bu gün ve saatler için sabittir. Seansınıza gelemediğiniz haftalarda aşağıdaki seans listesinden iptal ederek yerinizi açabilir ve hakkınızı iade alabilirsiniz ✨
                  </p>
                </div>
              </div>
            )}
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

                    <div className="pt-2.5 border-t border-line/60 space-y-3 text-xs">
                      <div className="flex items-center gap-1.5 font-bold text-ink">
                        <Clock className="w-4 h-4 text-espresso" />
                        <span>Tarih & Saat: {formatDateTime(session?.baslangic)}</span>
                      </div>

                      {booking.durum === 'booked' && (
                        <Button
                          variant="destructive"
                          disabled={cancelLoadingId === booking.id}
                          onClick={() => handleCancelBooking(booking.id, classType?.ad || 'Ders')}
                          className="w-full h-10 text-xs font-bold bg-clay hover:bg-clay/90 text-white rounded-xl shadow-xs border-none flex items-center justify-center gap-2 cursor-pointer transition-all"
                        >
                          {cancelLoadingId === booking.id ? (
                            <Loader2 className="w-4 h-4 animate-spin" />
                          ) : (
                            <>
                              <X className="w-4 h-4" />
                              <span>REZERVASYONU İPTAL ET (1 DERS İADE AL)</span>
                            </>
                          )}
                        </Button>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="p-4 rounded-2xl bg-sand/40 border border-dashed border-line text-center text-xs text-secondary font-medium flex flex-col items-center gap-2">
              <span>Aktif bir ders rezervasyonunuz bulunmamaktadır.</span>
              <Link href="/rezervasyon" className="text-espresso font-bold underline hover:text-mocha">
                Ders Programından Seans Seç →
              </Link>
            </div>
          )}
        </div>

        {/* Workshop & Etkinlik Kayıtlarım Section */}
        <div className="space-y-3 pt-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-mocha" />
              <h3 className="font-serif text-lg font-bold text-ink tracking-wide">
                Workshop & Etkinlik Kayıtlarım
              </h3>
            </div>
            {myWorkshops.length > 0 && (
              <span className="text-xs font-bold text-sage bg-sage/15 px-2.5 py-0.5 rounded-full border border-sage/30">
                {myWorkshops.length} Kayıt
              </span>
            )}
          </div>

          {myWorkshops && myWorkshops.length > 0 ? (
            <div className="space-y-3">
              {myWorkshops.map((ev) => (
                <div
                  key={ev.id}
                  className="p-4 rounded-2xl bg-sand/80 border border-line shadow-xs flex flex-col gap-3 hover:border-mocha/60 transition-all"
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <span className="inline-block px-2.5 py-0.5 rounded-md text-[10px] font-bold bg-sage/15 text-sage border border-sage/30 uppercase mb-1">
                        {ev.turu || 'Workshop'}
                      </span>
                      <h4 className="font-serif text-base font-bold text-ink">
                        {ev.baslik}
                      </h4>
                    </div>
                    <span className="text-[11px] font-bold text-sage bg-ivory px-2.5 py-1 rounded-full border border-line shadow-2xs">
                      Kayıtlısınız ✨
                    </span>
                  </div>

                  <div className="pt-2 border-t border-line/60 space-y-3 text-xs">
                    <div className="flex items-center gap-1.5 font-bold text-ink">
                      <Clock className="w-4 h-4 text-espresso" />
                      <span>{ev.tarih_saat}</span>
                    </div>

                    <Button
                      variant="destructive"
                      disabled={cancelWorkshopId === ev.id}
                      onClick={() => handleCancelWorkshop(ev.id, ev.baslik)}
                      className="w-full h-10 text-xs font-bold bg-clay hover:bg-clay/90 text-white rounded-xl shadow-xs border-none flex items-center justify-center gap-2 cursor-pointer transition-all"
                    >
                      {cancelWorkshopId === ev.id ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <>
                          <X className="w-4 h-4" />
                          <span>WORKSHOP KAYDINI İPTAL ET</span>
                        </>
                      )}
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="p-4 rounded-2xl bg-sand/40 border border-dashed border-line text-center text-xs text-secondary font-medium flex flex-col items-center gap-2">
              <span>Kayıtlı bir workshop veya atölye etkinliğiniz bulunmamaktadır.</span>
              <a href="/#workshoplar" className="text-espresso font-bold underline hover:text-mocha">
                Workshop & Etkinlikleri İncele →
              </a>
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

      {showPasswordModal && (
        <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-sand border border-line rounded-3xl p-6 max-w-sm w-full shadow-2xl space-y-4 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between border-b border-line pb-3">
              <div className="flex items-center gap-2 text-espresso font-serif font-bold text-lg">
                <KeyRound className="w-5 h-5 text-mocha" />
                <span>Şifremi Değiştir</span>
              </div>
              <button
                type="button"
                onClick={() => setShowPasswordModal(false)}
                className="text-secondary hover:text-ink p-1 rounded-full hover:bg-ivory cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {pwError && (
              <div className="p-3 rounded-xl bg-clay/15 border border-clay/30 text-clay text-xs font-medium flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{pwError}</span>
              </div>
            )}

            {pwSuccess && (
              <div className="p-3 rounded-xl bg-sage/15 border border-sage/30 text-sage text-xs font-medium flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 shrink-0" />
                <span>{pwSuccess}</span>
              </div>
            )}

            <form onSubmit={handleChangePassword} className="space-y-3 pt-1">
              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Mevcut Şifreniz</label>
                <Input
                  type="password"
                  placeholder="Mevcut şifreniz"
                  value={currentPassword}
                  onChange={(e) => setCurrentPassword(e.target.value)}
                  className="bg-ivory border-line text-xs rounded-xl h-10"
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Yeni Şifre</label>
                <Input
                  type="password"
                  placeholder="En az 4 karakter"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="bg-ivory border-line text-xs rounded-xl h-10"
                  required
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Yeni Şifre (Tekrar)</label>
                <Input
                  type="password"
                  placeholder="Yeni şifrenizi tekrar girin"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="bg-ivory border-line text-xs rounded-xl h-10"
                  required
                />
              </div>

              <div className="pt-2">
                <button
                  type="submit"
                  disabled={changingPassword}
                  className="w-full h-11 rounded-2xl bg-espresso hover:bg-espresso-dark text-ivory font-extrabold text-xs uppercase tracking-wider cursor-pointer shadow-xs transition-colors flex items-center justify-center gap-2"
                >
                  {changingPassword ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" />
                      Güncelleniyor...
                    </>
                  ) : (
                    <span>ŞİFREYİ GÜNCELLE</span>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
