'use client'

import React, { useState, useEffect } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { Phone, KeyRound, ArrowLeft, Loader2, AlertCircle, Sparkles } from 'lucide-react'
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

  // Step 1: Telefon, Step 2: 6 Haneli OTP Kod
  const [step, setStep] = useState<1 | 2>(1)
  const [telefon, setTelefon] = useState('')
  const [kod, setKod] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [resendTimer, setResendTimer] = useState(0)

  useEffect(() => {
    let interval: NodeJS.Timeout
    if (resendTimer > 0) {
      interval = setInterval(() => {
        setResendTimer((prev) => prev - 1)
      }, 1000)
    }
    return () => clearInterval(interval)
  }, [resendTimer])

  // Telefon numarasını standart formata getirme (+90 ile başlama garantisi)
  const formatTelefon = (rawTel: string): string => {
    let clean = rawTel.replace(/\D/g, '')
    if (clean.startsWith('90')) {
      return '+' + clean
    }
    if (clean.startsWith('0')) {
      clean = clean.substring(1)
    }
    if (clean.length === 10) {
      return '+90' + clean
    }
    if (!rawTel.startsWith('+') && clean.length > 0) {
      return '+' + clean
    }
    return rawTel.trim()
  }

  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    const formattedTel = formatTelefon(telefon)
    if (!formattedTel || formattedTel.length < 10) {
      setError('Lütfen geçerli bir telefon numarası girin (Örn: 0532 123 45 67)')
      return
    }

    setLoading(true)
    try {
      await api.auth.sendOtp({ telefon: formattedTel })
      setTelefon(formattedTel)
      setStep(2)
      setResendTimer(60)
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('OTP kodu gönderilirken bir hata oluştu. Lütfen tekrar deneyin.')
      }
    } finally {
      setLoading(false)
    }
  }

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    const cleanKod = kod.trim()
    if (cleanKod.length !== 6) {
      setError('Lütfen 6 haneli doğrulama kodunu eksiksiz girin.')
      return
    }

    setLoading(true)
    try {
      const res = await api.auth.verifyOtp({
        telefon,
        kod: cleanKod,
      })

      // Token kaydet
      setToken(res.access_token)

      if (onSuccess) {
        onSuccess()
      } else {
        try {
          const user = await api.auth.getMe()
          if (user.is_admin) {
            router.push('/admin/today')
          } else {
            router.push(redirectTarget)
          }
        } catch {
          router.push(redirectTarget)
        }
      }
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('Doğrulama kodu geçersiz veya süresi dolmuş.')
      }
    } finally {
      setLoading(false)
    }
  }

  const handleResend = async () => {
    if (resendTimer > 0 || loading) return
    setError(null)
    setLoading(true)
    try {
      await api.auth.sendOtp({ telefon })
      setResendTimer(60)
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('Kodu tekrar gönderirken bir hata oluştu.')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card className="w-full max-w-md bg-sand/80 border border-line shadow-md rounded-3xl p-2 text-ink">
      <CardHeader className="text-center pb-3">
        <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-espresso text-ivory shadow-xs">
          {step === 1 ? (
            <Phone className="h-7 w-7" />
          ) : (
            <KeyRound className="h-7 w-7" />
          )}
        </div>
        <CardTitle className="text-2xl font-serif font-bold text-ink tracking-wide">
          {step === 1 ? 'Sobo Society Giriş' : 'Doğrulama Kodu'}
        </CardTitle>
        <CardDescription className="text-secondary text-xs mt-1">
          {step === 1
            ? 'Telefon numaranızı girin, SMS ile 6 haneli doğrulama kodunu gönderelim.'
            : `${telefon} numarasına gönderilen 6 haneli doğrulama kodunu girin.`}
        </CardDescription>
      </CardHeader>

      <CardContent className="space-y-4">
        {error && (
          <div className="flex items-start space-x-2.5 rounded-2xl border border-clay/40 bg-clay/15 p-3.5 text-xs text-clay font-medium shadow-xs">
            <AlertCircle className="h-4 w-4 shrink-0 mt-0.5 text-clay" />
            <span>{error}</span>
          </div>
        )}

        {step === 1 ? (
          <form onSubmit={handleSendOtp} className="space-y-4">
            <div className="space-y-2">
              <label htmlFor="telefon" className="text-xs font-bold text-secondary uppercase tracking-wider block">
                Telefon Numarası
              </label>
              <Input
                id="telefon"
                type="tel"
                placeholder="05XX XXX XX XX"
                value={telefon}
                onChange={(e) => setTelefon(e.target.value)}
                className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-2xl h-12 px-4 font-medium"
                autoFocus
                disabled={loading}
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full h-12 rounded-2xl text-ivory font-extrabold text-sm tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99] border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
            >
              {loading ? (
                <>
                  <Loader2 className="h-5 w-5 animate-spin" />
                  Kod Gönderiliyor...
                </>
              ) : (
                <>
                  <Sparkles className="h-4 w-4 text-mocha" />
                  <span>Giriş Kodu Gönder</span>
                </>
              )}
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerifyOtp} className="space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <label htmlFor="kod" className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  6 Haneli Kod
                </label>
                <button
                  type="button"
                  onClick={() => {
                    setStep(1)
                    setError(null)
                  }}
                  className="text-xs text-mocha hover:text-espresso flex items-center gap-1 font-semibold transition-colors"
                >
                  <ArrowLeft className="h-3.5 w-3.5" /> Numarayı Değiştir
                </button>
              </div>

              <Input
                id="kod"
                type="text"
                inputMode="numeric"
                pattern="[0-9]*"
                maxLength={6}
                placeholder="123456"
                value={kod}
                onChange={(e) => setKod(e.target.value.replace(/\D/g, ''))}
                className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 text-center text-2xl tracking-[0.5em] font-mono h-14 rounded-2xl"
                autoFocus
                disabled={loading}
              />
            </div>

            <button
              type="submit"
              disabled={loading || kod.trim().length !== 6}
              className="w-full h-12 rounded-2xl text-ivory font-extrabold text-sm tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99] border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
            >
              {loading ? (
                <>
                  <Loader2 className="h-5 w-5 animate-spin" />
                  Doğrulanıyor...
                </>
              ) : (
                'Giriş Yap'
              )}
            </button>

            <div className="text-center pt-2">
              <button
                type="button"
                onClick={handleResend}
                disabled={resendTimer > 0 || loading}
                className="text-xs text-secondary hover:text-espresso disabled:opacity-50 font-medium transition-colors"
              >
                {resendTimer > 0
                  ? `Kodu tekrar gönder (${resendTimer}s)`
                  : 'Kodu tekrar gönder'}
              </button>
            </div>
          </form>
        )}
      </CardContent>

      <CardFooter className="justify-center border-t border-line/80 pt-4">
        <p className="text-[11px] text-secondary text-center leading-relaxed font-medium">
          Giriş yaparak Sobo Society Üyelik ve KVKK Aydınlatma Metnini kabul etmiş olursunuz.
        </p>
      </CardFooter>
    </Card>
  )
}
