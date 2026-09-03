'use client'

import React, { useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { User, KeyRound, Loader2, AlertCircle, Sparkles, UserPlus, LogIn, Phone } from 'lucide-react'
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

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    if (!regAd.trim() || !regKullaniciAdi.trim() || !regSifre.trim()) {
      setError('Lütfen Ad Soyad, Kullanıcı Adı ve Şifre alanlarını doldurun.')
      return
    }

    setLoading(true)
    try {
      const res = await api.auth.register({
        ad: regAd.trim(),
        kullanici_adi: regKullaniciAdi.trim(),
        sifre: regSifre.trim(),
        telefon: regTelefon.trim() || undefined,
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
              <label htmlFor="loginSifre" className="text-xs font-bold text-secondary uppercase tracking-wider block">
                Şifre
              </label>
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
                Cep Telefonu (Opsiyonel)
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
  )
}
