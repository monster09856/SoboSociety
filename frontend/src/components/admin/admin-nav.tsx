'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { buyukHarf } from '@/lib/utils'
import { Calendar, Users, Zap, Bell, Sparkles, ShieldCheck, KeyRound, User, Loader2, CheckCircle2, AlertCircle, X } from 'lucide-react'
import { adminApi, ApiError } from '@/lib/api'

export function AdminNav() {
  const pathname = usePathname()
  const [showSettingsModal, setShowSettingsModal] = useState(false)

  // Settings form state
  const [newUsername, setNewUsername] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [successMsg, setSuccessMsg] = useState<string | null>(null)

  const navItems = [
    {
      href: '/admin/today',
      label: '5 Saniyelik Yoklama',
      icon: Zap,
    },
    {
      href: '/admin/members',
      label: 'Üye & Bakiye',
      icon: Users,
    },
    {
      href: '/admin/schedule',
      label: 'Ders Programı',
      icon: Calendar,
    },
    {
      href: '/admin/events',
      label: 'Workshop & Etkinlik',
      icon: Sparkles,
    },
    {
      href: '/admin/notifications',
      label: 'Bildirimler',
      icon: Bell,
    },
  ]

  const handleUpdateCredentials = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setSuccessMsg(null)

    if (!newPassword.trim()) {
      setError('Lütfen yeni şifrenizi girin.')
      return
    }

    setLoading(true)
    try {
      const res = await adminApi.updateCredentials({
        yeni_kullanici_adi: newUsername.trim() || undefined,
        yeni_sifre: newPassword.trim(),
      })
      setSuccessMsg(res.mesaj)
      setNewPassword('')
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message)
      } else {
        setError('Giriş bilgileri güncellenirken bir hata oluştu.')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <>
      <nav className="border-b border-line bg-ivory/95 backdrop-blur-md sticky top-0 z-40 text-ink shadow-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-3">
              <img src="/logo.png" alt="Sobo Society Admin" className="h-9 w-auto rounded-xl shadow-xs" />
              <Link href="/admin/today" className="font-serif text-xl font-bold tracking-wide text-espresso flex items-center">
                SOBO <span className="text-xs font-sans font-extrabold text-mocha uppercase tracking-widest ml-2 px-2.5 py-0.5 rounded-full bg-sand border border-line">Admin 2.0</span>
              </Link>
            </div>

            <div className="flex items-center gap-1 sm:gap-2">
              {navItems.map((item) => {
                const Icon = item.icon
                const isActive = pathname === item.href
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition-all duration-200 ${
                      isActive
                        ? 'bg-espresso text-ivory shadow-xs'
                        : 'text-secondary hover:text-ink hover:bg-sand'
                    }`}
                  >
                    <Icon className={`w-4 h-4 ${isActive ? 'text-mocha' : 'text-secondary'}`} />
                    <span>{buyukHarf(item.label)}</span>
                  </Link>
                )
              })}

              {/* Admin Settings Button */}
              <button
                onClick={() => setShowSettingsModal(true)}
                className="flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold bg-sand text-espresso border border-line hover:border-mocha hover:bg-sand-light transition-all cursor-pointer ml-2"
              >
                <ShieldCheck className="w-4 h-4 text-espresso" />
                <span>GİRİŞ BİLGİLERİ</span>
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Admin Credentials Settings Modal */}
      {showSettingsModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4">
          <div className="bg-ivory border border-line rounded-3xl p-6 sm:p-8 max-w-md w-full shadow-2xl relative">
            <button
              onClick={() => setShowSettingsModal(false)}
              className="absolute top-4 right-4 text-secondary hover:text-ink p-1 rounded-full hover:bg-sand cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-2xl bg-espresso text-white flex items-center justify-center">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-serif text-xl font-bold text-ink">Yönetici Giriş Bilgileri</h3>
                <p className="text-xs text-secondary font-medium">Panel giriş kullanıcı adı ve şifrenizi değiştirin.</p>
              </div>
            </div>

            {error && (
              <div className="mb-4 p-3 rounded-2xl bg-clay/15 border border-clay/30 text-clay text-xs font-bold flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            {successMsg && (
              <div className="mb-4 p-3 rounded-2xl bg-sage/20 border border-sage/40 text-sage text-xs font-bold flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 shrink-0" />
                <span>{successMsg}</span>
              </div>
            )}

            <form onSubmit={handleUpdateCredentials} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  Yeni Yönetici Kullanıcı Adı (Opsiyonel)
                </label>
                <div className="relative">
                  <User className="absolute left-3.5 top-3.5 h-4 w-4 text-mocha" />
                  <input
                    type="text"
                    placeholder="admin (Değiştirmek istemiyorsanız boş bırakın)"
                    value={newUsername}
                    onChange={(e) => setNewUsername(e.target.value)}
                    className="w-full bg-sand/60 border border-line rounded-2xl h-11 pl-10 pr-4 text-xs font-bold text-ink focus:outline-none focus:border-espresso"
                    disabled={loading}
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold text-secondary uppercase tracking-wider block">
                  Yeni Yönetici Şifresi
                </label>
                <div className="relative">
                  <KeyRound className="absolute left-3.5 top-3.5 h-4 w-4 text-mocha" />
                  <input
                    type="password"
                    placeholder="Yeni şifreniz"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    className="w-full bg-sand/60 border border-line rounded-2xl h-11 pl-10 pr-4 text-xs font-bold text-ink focus:outline-none focus:border-espresso"
                    disabled={loading}
                  />
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowSettingsModal(false)}
                  className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                >
                  Vazgeç
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="px-5 py-2.5 rounded-xl text-xs font-bold bg-espresso hover:bg-espresso-dark text-white uppercase tracking-wider shadow-xs cursor-pointer disabled:opacity-50 flex items-center gap-2"
                >
                  {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Giriş Bilgilerini Güncelle'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  )
}
