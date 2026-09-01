'use client'

import React, { useState } from 'react'
import { admin, MemberPackageResponse } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { AdminNav } from '@/components/admin/admin-nav'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Package, UserCheck, Calendar, CheckCircle2, AlertCircle, Loader2, CreditCard, Sparkles, Search } from 'lucide-react'

// Preset package list for trainer selection
const PRESET_PACKAGES = [
  { id: 1, ad: '8 Seanslık Reformer Pilates Paketi', kredi: 8, gecerlilik: '30 Gün' },
  { id: 2, ad: '12 Seanslık Reformer Pilates Paketi', kredi: 12, gecerlilik: '45 Gün' },
  { id: 3, ad: '24 Seanslık Avantajlı Üyelik Paketi', kredi: 24, gecerlilik: '90 Gün' },
  { id: 4, ad: '1 Seanslık Tekil Ders Deneme Paketi', kredi: 1, gecerlilik: '7 Gün' },
]

export default function AdminMembersPage() {
  const [memberIdInput, setMemberIdInput] = useState('')
  const [packageIdInput, setPackageIdInput] = useState('')
  const [startDate, setStartDate] = useState(() => {
    return new Date().toISOString().split('T')[0]
  })

  const [loading, setLoading] = useState(false)
  const [resultPackage, setResultPackage] = useState<MemberPackageResponse | null>(null)
  const [error, setError] = useState<string | null>(null)

  const handleAssignPackage = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setResultPackage(null)

    const mId = Number(memberIdInput)
    const pId = Number(packageIdInput)

    if (!mId || isNaN(mId)) {
      setError('Lütfen geçerli bir Üye ID giriniz.')
      return
    }

    if (!pId || isNaN(pId)) {
      setError('Lütfen tanımlanacak paketi seçiniz veya Paket ID giriniz.')
      return
    }

    setLoading(true)
    try {
      const res = await admin.assignPackage({
        member_id: mId,
        package_id: pId,
        baslangic: startDate || undefined,
      })

      setResultPackage(res)
    } catch (err: any) {
      setError(err?.message || 'Paket tanımlanırken bir hata oluştu.')
    } finally {
      setLoading(false)
    }
  }

  const formatDate = (dateStr: string) => {
    try {
      return new Date(dateStr).toLocaleDateString('tr-TR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      })
    } catch {
      return dateStr
    }
  }

  return (
    <div className="min-h-screen bg-ivory text-ink font-sans antialiased relative">
      <AdminNav />

      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8 relative z-10">
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-1.5">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-sand text-espresso border border-line">
              <Package className="w-3.5 h-3.5 text-mocha" />
              <span>Üye & Paket Yönetimi</span>
            </span>
          </div>
          <h1 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
            {buyukHarf("Üye Paket Tanımlama Ekranı")}
          </h1>
          <p className="text-sm text-secondary font-medium mt-1">
            Üyelere ders kredisi ve paket tanımı yaparak sistem bakiyelerini anında güncelleyin.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Sol / Orta Kolon: Paket Tanımlama Formu */}
          <div className="lg:col-span-2 space-y-6">
            <Card className="border border-line shadow-xs bg-sand rounded-2xl text-ink overflow-hidden">
              <CardHeader className="border-b border-line/80 pb-4">
                <CardTitle className="flex items-center gap-2.5 text-xl font-serif font-bold text-ink">
                  <CreditCard className="w-5 h-5 text-espresso" />
                  <span>{buyukHarf("Paket Atama Formu")}</span>
                </CardTitle>
                <CardDescription className="text-secondary text-xs font-medium">
                  Seçilen üyeye yeni bir paket atayın ve geçerlilik başlangıcını belirleyin.
                </CardDescription>
              </CardHeader>

              <CardContent className="pt-6">
                <form onSubmit={handleAssignPackage} className="space-y-5">
                  {/* Zarif Arama / Üye ID */}
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider flex items-center gap-1.5">
                      <UserCheck className="w-4 h-4 text-mocha" />
                      <span>{buyukHarf("Üye Arama & ID")}</span>
                    </label>
                    <div className="relative">
                      <Search className="w-4 h-4 text-secondary absolute left-3.5 top-3.5" />
                      <Input
                        type="number"
                        placeholder="Üye No / ID girin (Örn: 101)"
                        value={memberIdInput}
                        onChange={(e) => setMemberIdInput(e.target.value)}
                        className="bg-ivory border-line text-ink placeholder-muted focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-xl h-11 pl-10 pr-3.5 font-medium"
                        required
                      />
                    </div>
                    <p className="text-[11px] text-secondary font-medium">
                      Sistemde kayıtlı üyenin benzersiz kimlik numarası (ID).
                    </p>
                  </div>

                  {/* Paket Seçimi / ID */}
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider flex items-center gap-1.5">
                      <Package className="w-4 h-4 text-mocha" />
                      <span>{buyukHarf("Tanımlanacak Paket")}</span>
                    </label>
                    <select
                      value={packageIdInput}
                      onChange={(e) => setPackageIdInput(e.target.value)}
                      className="flex h-11 w-full rounded-xl border border-line bg-ivory px-3.5 py-2 text-sm text-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-espresso/20 transition-colors font-medium cursor-pointer"
                      required
                    >
                      <option value="" className="bg-ivory text-secondary">-- Paket Seçiniz --</option>
                      {PRESET_PACKAGES.map((pkg) => (
                        <option key={pkg.id} value={pkg.id} className="bg-ivory text-ink">
                          Paket #{pkg.id}: {pkg.ad} ({pkg.gecerlilik})
                        </option>
                      ))}
                    </select>
                  </div>

                  {/* Başlangıç Tarihi */}
                  <div className="space-y-1.5">
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider flex items-center gap-1.5">
                      <Calendar className="w-4 h-4 text-mocha" />
                      <span>{buyukHarf("Paket Başlangıç Tarihi")}</span>
                    </label>
                    <Input
                      type="date"
                      value={startDate}
                      onChange={(e) => setStartDate(e.target.value)}
                      className="bg-ivory border-line text-ink focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-xl h-11 px-3.5 font-medium cursor-pointer"
                      required
                    />
                  </div>

                  {/* Hata Bildirimi */}
                  {error && (
                    <div className="p-4 rounded-xl bg-clay/15 text-clay border border-clay/40 text-xs font-medium flex items-start gap-2.5">
                      <AlertCircle className="w-4 h-4 text-clay shrink-0 mt-0.5" />
                      <span>{error}</span>
                    </div>
                  )}

                  {/* Başarı Bildirimi */}
                  {resultPackage && (
                    <div className="p-4 rounded-xl bg-sage/15 border border-sage/40 text-sage text-xs space-y-2">
                      <div className="flex items-center gap-2 font-bold text-sm text-sage">
                        <CheckCircle2 className="w-5 h-5" />
                        <span>Paket Başarıyla Tanımlandı!</span>
                      </div>
                      <div className="text-ink text-xs pl-7 space-y-1 font-medium">
                        <p><strong>Üye ID:</strong> #{resultPackage.member_id}</p>
                        <p><strong>Paket ID:</strong> #{resultPackage.package_id}</p>
                        <p><strong>Başlangıç:</strong> {formatDate(resultPackage.baslangic)}</p>
                        <p><strong>Bitiş (Son Kullanma):</strong> {formatDate(resultPackage.bitis)}</p>
                      </div>
                    </div>
                  )}

                  {/* Espresso PAKETİ TANIMLA Butonu */}
                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full h-12 rounded-xl text-ivory font-extrabold text-sm tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99] border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 mt-2"
                  >
                    {loading ? (
                      <>
                        <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                        Paket Tanımlanıyor...
                      </>
                    ) : (
                      <>
                        <Package className="w-4 h-4" />
                        <span>PAKETİ TANIMLA</span>
                        <Sparkles className="w-4 h-4 text-mocha opacity-80" />
                      </>
                    )}
                  </button>
                </form>
              </CardContent>
            </Card>
          </div>

          {/* Sağ Kolon: Paket Türleri Kartları */}
          <div className="lg:col-span-1 space-y-4">
            <Card className="border border-line bg-sand shadow-xs rounded-2xl text-ink overflow-hidden">
              <CardHeader className="pb-3 border-b border-line/80">
                <CardTitle className="text-lg font-serif font-bold text-ink flex items-center gap-2">
                  <Package className="w-4 h-4 text-espresso" />
                  <span>{buyukHarf("Paket Türleri")}</span>
                </CardTitle>
                <CardDescription className="text-secondary text-xs font-medium">
                  Sistemde tanımlı standart üyelik ve ders paketleri
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-4 space-y-3">
                {PRESET_PACKAGES.map((pkg) => {
                  const isSelected = packageIdInput === String(pkg.id)
                  return (
                    <div
                      key={pkg.id}
                      onClick={() => setPackageIdInput(String(pkg.id))}
                      className={`p-4 rounded-xl border cursor-pointer transition-all duration-200 ${
                        isSelected
                          ? 'bg-espresso text-ivory border-none shadow-xs scale-[1.02]'
                          : 'bg-ivory/80 border-line text-ink hover:border-mocha/60 hover:bg-ivory'
                      }`}
                    >
                      <div className="flex items-center justify-between font-bold text-xs mb-1">
                        <span>Paket #{pkg.id}</span>
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-extrabold ${
                            isSelected ? 'bg-ivory/20 text-ivory' : 'bg-sand text-espresso border border-line'
                          }`}
                        >
                          {pkg.kredi} Ders Kredisi
                        </span>
                      </div>
                      <p className={`text-xs font-bold ${isSelected ? 'text-ivory' : 'text-ink'}`}>
                        {pkg.ad}
                      </p>
                      <p className={`text-[11px] mt-1 font-medium ${isSelected ? 'text-ivory/80' : 'text-secondary'}`}>
                        Geçerlilik süresi: {pkg.gecerlilik}
                      </p>
                    </div>
                  )
                })}
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  )
}
