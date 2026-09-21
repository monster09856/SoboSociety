'use client'

import React, { useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { User, KeyRound, Loader2, AlertCircle, Sparkles, UserPlus, LogIn, Phone, Clock, HelpCircle, X } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card'
import { api, ApiError } from '@/lib/api'
import { setToken } from '@/lib/auth'

interface OtpFormProps {
  onSuccess?: () => void
  redirectTo?: string
}

export function OtpForm({ onSuccess, redirectTo }: OtpFormProps) {
  const router = useRouter()
  const searchParams = useSearchParams()
  const redirectTarget = redirectTo || searchParams?.get('redirect') || '/rezervasyon'

  // Tab mode: 'login' | 'register'
  const [tab, setTab] = useState<'login' | 'register'>('login')

  // Register state
  const [regAd, setRegAd] = useState('')
  const [regKullaniciAdi, setRegKullaniciAdi] = useState('')
  const [regSifre, setRegSifre] = useState('')
  const [regTelefon, setRegTelefon] = useState('')

  // Login state
  const [loginKullaniciAdi, setLoginKullaniciAdi] = useState('')
  const [loginSifre, setLoginSifre] = useState('')
  const [showForgotModal, setShowForgotModal] = useState(false)

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [pendingApproval, setPendingApproval] = useState(false)

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setPendingApproval(false)

    if (!regAd.trim() || !regKullaniciAdi.trim() || !regSifre.trim() || !regTelefon.trim()) {
      setError('Lütfen Ad Soyad, Kullanıcı Adı, Şifre ve Cep Telefonu alanlarını eksiksiz doldurun.')
      return
    }

    const cleanPhone = regTelefon.replace(/\D/g, '')
    if (!cleanPhone || cleanPhone.length < 10 || cleanPhone.length > 11 || (!cleanPhone.startsWith('5') && !cleanPhone.startsWith('05'))) {
      setError('Telefon numaranızı eksik veya yanlış tuşladınız. Lütfen kontrol ediniz (örn: 05XX XXX XX XX).')
      return
    }

    setLoading(true)
    try {
      const res = await api.auth.register({
        ad: regAd.trim(),
        kullanici_adi: regKullaniciAdi.trim(),
        sifre: regSifre.trim(),
        telefon: regTelefon.trim(),
      })

      if (res.aktif === false || !res.access_token) {
        setPendingApproval(true)
        setTab('login')
        setLoginKullaniciAdi(regKullaniciAdi.trim())
        setLoginSifre('')
        return
      }

      setToken(res.access_token)

      if (onSuccess) {
        onSuccess()
      } else {
        const user = await api.auth.getMe()
        if (user.is_admin) {
          router.push('/admin/today')
        } else {
          router.push(redirectTarget)
        }
      }
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('Kayıt oluşturulurken bir hata oluştu.')
      }
    } finally {
      setLoading(false)
    }
  }

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    if (!loginKullaniciAdi.trim() || !loginSifre.trim()) {
      setError('Lütfen Kullanıcı Adı ve Şifre alanlarını girin.')
      return
    }

    setLoading(true)
    try {
      const res = await api.auth.login({
        kullanici_adi: loginKullaniciAdi.trim(),
        sifre: loginSifre.trim(),
      })

      setToken(res.access_token)

      if (onSuccess) {
        onSuccess()
      } else {
        const user = await api.auth.getMe()
        if (user.is_admin) {
          router.push('/admin/today')
        } else {
          router.push(redirectTarget)
        }
      }
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('Kullanıcı adı veya şifre hatalı.')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <>
      <Card className="w-full max-w-md bg-sand/80 border border-line shadow-md rounded-3xl p-2 text-ink">
      {/* Tab Switcher Header */}
      <div className="p-1 bg-ivory rounded-2xl border border-line flex mb-2">
        <button
          type="button"
          onClick={() => { setTab('login'); setError(null) }}
          className={`flex-1 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
            tab === 'login'
              ? 'bg-espresso text-white shadow-xs'
              : 'text-secondary hover:text-ink'
          }`}
        >
          <LogIn className="w-4 h-4" />
          <span>Giriş Yap</span>
        </button>

        <button
          type="button"
          onClick={() => { setTab('register'); setError(null) }}
          className={`flex-1 py-2.5 rounded-xl text-xs font-bold uppercase tracking-wider transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
            tab === 'register'
              ? 'bg-espresso text-white shadow-xs'
              : 'text-secondary hover:text-ink'
          }`}
        >
          <UserPlus className="w-4 h-4" />
          <span>Kayıt Ol</span>
        </button>
      </div>

      <CardHeader className="text-center pb-3 pt-2">
        <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-espresso text-ivory shadow-xs">
          {tab === 'login' ? <LogIn className="h-6 w-6" /> : <UserPlus className="h-6 w-6" />}
        </div>
        <CardTitle className="text-2xl font-serif font-bold text-ink tracking-wide">
          {tab === 'login' ? 'Sobo Society Giriş' : 'Üye Hesabı Oluştur'}
        </CardTitle>
        <CardDescription className="text-secondary text-xs mt-1">
          {tab === 'login'
            ? 'Kullanıcı adınız ve şifrenizle giriş yapın.'
            : 'Ad Soyad, kullanıcı adı ve şifrenizi belirleyerek üye olun.'}
        </CardDescription>
      </CardHeader>

      <CardContent className="space-y-4">
        {pendingApproval && (
          <div className="flex items-start space-x-3 rounded-2xl border border-amber-500/40 bg-amber-500/10 p-4 text-xs font-medium shadow-xs">
            <Clock className="h-5 w-5 shrink-0 text-amber-700 mt-0.5" />
            <div className="space-y-1">
              <p className="font-bold text-sm text-amber-950">Başvurunuz Alındı ✨</p>
              <p className="text-amber-900 leading-relaxed">
                Sobo Pilates butik stüdyomuza üyeliğiniz yönetici tarafından incelenmektedir.
                Başvurunuz stüdyo yönetimi tarafından onaylandıktan sonra kullanıcı adı ve şifrenizle giriş yapabilirsiniz.
              </p>
            </div>
          </div>
        )}

        {error && (
          <div className="flex items-start space-x-2.5 rounded-2xl border border-clay/40 bg-clay/15 p-3.5 text-xs text-clay font-medium shadow-xs">
            <AlertCircle className="h-4 w-4 shrink-0 mt-0.5 text-clay" />
            <span>{error}</span>
          </div>
        )}

        {tab === 'login' ? (
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-2">
              <label htmlFor="loginKullaniciAdi" className="text-xs font-bold text-secondary uppercase tracking-wider block">
                Kullanıcı Adı veya Telefon
              </label>
              <div className="relative">
                <User className="absolute left-4 top-3.5 h-5 w-5 text-mocha" />
                <Input
                  id="loginKullaniciAdi"
                  type="text"
                  placeholder="Kullanıcı adınız"
                  value={loginKullaniciAdi}
                  onChange={(e) => setLoginKullaniciAdi(e.target.value)}
                  className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-2xl h-12 pl-12 pr-4 font-medium"
                  autoFocus
                  disabled={loading}
                />
              </div>
            </div>

            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <label htmlFor="loginSifre" className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  Şifre
                </label>
                <button
                  type="button"
                  onClick={() => setShowForgotModal(true)}
                  className="text-[11px] font-semibold text-mocha hover:text-espresso underline underline-offset-2 transition-colors cursor-pointer"
                >
                  Şifremi Unuttum?
                </button>
              </div>
              <div className="relative">
                <KeyRound className="absolute left-4 top-3.5 h-5 w-5 text-mocha" />
                <Input
                  id="loginSifre"
                  type="password"
                  placeholder="••••••••"
                  value={loginSifre}
                  onChange={(e) => setLoginSifre(e.target.value)}
                  className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-2xl h-12 pl-12 pr-4 font-medium"
                  disabled={loading}
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full h-12 rounded-2xl text-ivory font-extrabold text-sm tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99] border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
            >
              {loading ? (
                <>
                  <Loader2 className="h-5 w-5 animate-spin" />
                  Giriş Yapılıyor...
                </>
              ) : (
                <>
                  <Sparkles className="h-4 w-4 text-mocha" />
                  <span>GİRİŞ YAP</span>
                </>
              )}
            </button>
          </form>
        ) : (
          <form onSubmit={handleRegister} className="space-y-3.5">
            <div className="space-y-1.5">
              <label htmlFor="regAd" className="text-xs font-bold text-secondary uppercase tracking-wider block">
                Ad Soyad
              </label>
              <div className="relative">
                <User className="absolute left-4 top-3 h-4 w-4 text-mocha" />
                <Input
                  id="regAd"
                  type="text"
                  placeholder="Adınız Soyadınız"
                  value={regAd}
                  onChange={(e) => setRegAd(e.target.value)}
                  className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-2xl h-11 pl-11 pr-4 font-medium text-sm"
                  disabled={loading}
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label htmlFor="regKullaniciAdi" className="text-xs font-bold text-secondary uppercase tracking-wider block">
                Kullanıcı Adı
              </label>
              <div className="relative">
                <User className="absolute left-4 top-3 h-4 w-4 text-mocha" />
                <Input
                  id="regKullaniciAdi"
                  type="text"
                  placeholder="kullaniciadi"
                  value={regKullaniciAdi}
                  onChange={(e) => setRegKullaniciAdi(e.target.value.toLowerCase().replace(/\s+/g, ''))}
                  className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-2xl h-11 pl-11 pr-4 font-medium text-sm"
                  disabled={loading}
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label htmlFor="regSifre" className="text-xs font-bold text-secondary uppercase tracking-wider block">
                Şifre
              </label>
              <div className="relative">
                <KeyRound className="absolute left-4 top-3 h-4 w-4 text-mocha" />
                <Input
                  id="regSifre"
                  type="password"
                  placeholder="••••••••"
                  value={regSifre}
                  onChange={(e) => setRegSifre(e.target.value)}
                  className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-2xl h-11 pl-11 pr-4 font-medium text-sm"
                  disabled={loading}
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label htmlFor="regTelefon" className="text-xs font-bold text-secondary uppercase tracking-wider block">
                Cep Telefonu *
              </label>
              <div className="relative">
                <Phone className="absolute left-4 top-3 h-4 w-4 text-mocha" />
                <Input
                  id="regTelefon"
                  type="tel"
                  placeholder="0532 XXX XX XX"
                  value={regTelefon}
                  onChange={(e) => setRegTelefon(e.target.value)}
                  className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-2xl h-11 pl-11 pr-4 font-medium text-sm"
                  disabled={loading}
                  required
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full h-12 rounded-2xl text-ivory font-extrabold text-sm tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99] border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 mt-2"
            >
              {loading ? (
                <>
                  <Loader2 className="h-5 w-5 animate-spin" />
                  Hesabınız Oluşturuluyor...
                </>
              ) : (
                <>
                  <UserPlus className="h-4 w-4 text-mocha" />
                  <span>ÜYE HESABI OLUŞTUR</span>
                </>
              )}
            </button>
          </form>
        )}
      </CardContent>

      <CardFooter className="justify-center border-t border-line/80 pt-4">
        <p className="text-[11px] text-secondary text-center leading-relaxed font-medium">
          Giriş yaparak veya üye olarak Sobo Society Üyelik ve KVKK Aydınlatma Metnini kabul etmiş olursunuz.
        </p>
      </CardFooter>
    </Card>

    {showForgotModal && (
      <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs flex items-center justify-center p-4">
        <div className="bg-sand border border-line rounded-3xl p-6 max-w-sm w-full shadow-2xl space-y-4 animate-in fade-in zoom-in-95 duration-150">
          <div className="flex items-center justify-between border-b border-line pb-3">
            <div className="flex items-center gap-2 text-espresso font-serif font-bold text-lg">
              <HelpCircle className="w-5 h-5 text-mocha" />
              <span>Şifremi Unuttum</span>
            </div>
            <button
              type="button"
              onClick={() => setShowForgotModal(false)}
              className="text-secondary hover:text-ink p-1 rounded-full hover:bg-ivory cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="space-y-3 text-xs text-secondary leading-relaxed">
            <p>
              Şifrenizi unuttuysanız veya değiştirmek istiyorsanız lütfen stüdyo yöneticimiz ile iletişime geçiniz.
            </p>
            <div className="p-3 bg-ivory rounded-2xl border border-line text-ink font-medium space-y-1">
              <p className="font-bold text-espresso text-[11px] uppercase tracking-wider">Hızlı Destek</p>
              <p>Yönetici panelinden yeni şifreniz anında tanımlanacak ve tarafınıza iletilecektir. ✨</p>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setShowForgotModal(false)}
            className="w-full h-11 rounded-2xl bg-espresso hover:bg-espresso-dark text-ivory font-bold text-xs uppercase tracking-wider cursor-pointer shadow-xs transition-colors"
          >
            Anladım
          </button>
        </div>
      </div>
    )}
  </>
  )
}
