'use client'

import React, { useState } from 'react'
import { admin, SessionGenerateResponse } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { AdminNav } from '@/components/admin/admin-nav'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Calendar, Sparkles, CheckCircle2, AlertCircle, Loader2, Info } from 'lucide-react'

export default function AdminSchedulePage() {
  const [startDate, setStartDate] = useState(() => {
    return new Date().toISOString().split('T')[0]
  })
  const [endDate, setEndDate] = useState(() => {
    const nextWeek = new Date()
    nextWeek.setDate(nextWeek.getDate() + 7)
    return nextWeek.toISOString().split('T')[0]
  })

  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<SessionGenerateResponse | null>(null)
  const [error, setError] = useState<string | null>(null)

  const setPresetRange = (days: number) => {
    const start = new Date()
    const end = new Date()
    end.setDate(start.getDate() + days)

    setStartDate(start.toISOString().split('T')[0])
    setEndDate(end.toISOString().split('T')[0])
  }

  const handleGenerate = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setResult(null)

    if (!startDate || !endDate) {
      setError('Lütfen başlangıç ve bitiş tarihlerini eksiksiz giriniz.')
      return
    }

    if (new Date(startDate) > new Date(endDate)) {
      setError('Başlangıç tarihi bitiş tarihinden sonra olamaz.')
      return
    }

    setLoading(true)
    try {
      const res = await admin.generateSessions({
        baslangic: startDate,
        bitis: endDate,
      })
      setResult(res)
    } catch (err: any) {
      setError(err?.message || 'Ders oturumları türetilirken bir hata oluştu.')
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

      <main className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8 relative z-10">
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-1.5">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-sand text-espresso border border-line">
              <Sparkles className="w-3.5 h-3.5 text-mocha" />
              <span>Ders Türetme Engine</span>
            </span>
          </div>
          <h1 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
            {buyukHarf("Şablondan Ders Oturumları Türet")}
          </h1>
          <p className="text-sm text-secondary font-medium mt-1">
            Haftalık sabit ders programı şablonunu seçtiğiniz tarih aralığı için otomatik oturumlara dönüştürün.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Sol Kolon: Türetme Formu */}
          <div className="md:col-span-2 space-y-6">
            <Card className="border border-line shadow-xs bg-sand rounded-2xl text-ink overflow-hidden">
              <CardHeader className="border-b border-line/80 pb-4">
                <CardTitle className="flex items-center gap-2.5 text-xl font-serif font-bold text-ink">
                  <Calendar className="w-5 h-5 text-espresso" />
                  <span>{buyukHarf("Tarih Aralığı Seçimi")}</span>
                </CardTitle>
                <CardDescription className="text-secondary text-xs font-medium">
                  Ders oturumlarının otomatik türetileceği başlangıç ve bitiş tarihlerini belirleyin.
                </CardDescription>
              </CardHeader>

              <CardContent className="pt-6 space-y-6">
                <form onSubmit={handleGenerate} className="space-y-6">
                  {/* Hızlı Seçim Butonları */}
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-2.5">
                      {buyukHarf("Hızlı Tarih Şablonları")}
                    </label>
                    <div className="flex flex-wrap gap-2.5">
                      <button
                        type="button"
                        onClick={() => setPresetRange(7)}
                        className="px-4 py-2 rounded-xl text-xs font-bold bg-ivory text-espresso border border-line hover:border-mocha/60 transition-all cursor-pointer shadow-xs"
                      >
                        Gelecek 7 Gün
                      </button>
                      <button
                        type="button"
                        onClick={() => setPresetRange(14)}
                        className="px-4 py-2 rounded-xl text-xs font-bold bg-ivory text-espresso border border-line hover:border-mocha/60 transition-all cursor-pointer shadow-xs"
                      >
                        Gelecek 14 Gün
                      </button>
                      <button
                        type="button"
                        onClick={() => setPresetRange(30)}
                        className="px-4 py-2 rounded-xl text-xs font-bold bg-ivory text-espresso border border-line hover:border-mocha/60 transition-all cursor-pointer shadow-xs"
                      >
                        Gelecek 30 Gün
                      </button>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {/* Başlangıç Tarihi */}
                    <div className="space-y-1.5">
                      <label className="block text-xs font-bold text-secondary uppercase tracking-wider">
                        {buyukHarf("Başlangıç Tarihi")}
                      </label>
                      <Input
                        type="date"
                        value={startDate}
                        onChange={(e) => setStartDate(e.target.value)}
                        className="bg-ivory border-line text-ink focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-xl h-11 px-3.5 font-medium cursor-pointer"
                        required
                      />
                    </div>

                    {/* Bitiş Tarihi */}
                    <div className="space-y-1.5">
                      <label className="block text-xs font-bold text-secondary uppercase tracking-wider">
                        {buyukHarf("Bitiş Tarihi (Dahil)")}
                      </label>
                      <Input
                        type="date"
                        value={endDate}
                        onChange={(e) => setEndDate(e.target.value)}
                        className="bg-ivory border-line text-ink focus:border-espresso focus:ring-2 focus:ring-espresso/20 rounded-xl h-11 px-3.5 font-medium cursor-pointer"
                        required
                      />
                    </div>
                  </div>

                  {/* Hata Bildirimi */}
                  {error && (
                    <div className="p-4 rounded-xl bg-clay/15 text-clay border border-clay/40 text-xs font-medium flex items-start gap-2.5">
                      <AlertCircle className="w-4 h-4 text-clay shrink-0 mt-0.5" />
                      <span>{error}</span>
                    </div>
                  )}

                  {/* Başarı Bildirimi */}
                  {result && (
                    <div className="p-4 rounded-xl bg-sage/15 border border-sage/40 text-sage text-xs space-y-2">
                      <div className="flex items-center gap-2 font-bold text-sm text-sage">
                        <CheckCircle2 className="w-5 h-5 shrink-0" />
                        <span>Ders Oturumları Başarıyla Türetildi!</span>
                      </div>
                      <p className="text-ink text-xs pl-7 font-medium leading-relaxed">
                        <strong>{formatDate(startDate)}</strong> - <strong>{formatDate(endDate)}</strong> tarihleri arasında toplam <span className="font-extrabold text-sage underline">{result.uretilen_oturum_sayisi} adet</span> yeni ders oturumu takvime eklendi.
                      </p>
                    </div>
                  )}

                  {/* Espresso DERS OTURUMLARINI TÜRET Butonu */}
                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full h-12 rounded-xl text-ivory font-extrabold text-sm tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99] border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 mt-2"
                  >
                    {loading ? (
                      <>
                        <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                        Oturumlar Türetiliyor...
                      </>
                    ) : (
                      <>
                        <Sparkles className="w-4 h-4 text-mocha opacity-80" />
                        <span>DERS OTURUMLARINI TÜRET</span>
                      </>
                    )}
                  </button>
                </form>
              </CardContent>
            </Card>
          </div>

          {/* Sağ Kolon: Bilgilendirme Kutusu */}
          <div className="md:col-span-1 space-y-4">
            <Card className="border border-line bg-sand shadow-xs rounded-2xl text-ink overflow-hidden">
              <CardHeader className="pb-3 border-b border-line/80">
                <CardTitle className="text-base font-serif font-bold text-ink flex items-center gap-2">
                  <Info className="w-4 h-4 text-espresso" />
                  <span>{buyukHarf("Şablon Mantığı")}</span>
                </CardTitle>
              </CardHeader>
              <CardContent className="pt-4 text-xs text-secondary space-y-3 leading-relaxed font-medium">
                <p>
                  Sistem, haftanın her günü için tanımlı olan sabit ders şablonlarını tarar.
                </p>
                <p>
                  Belirttiğiniz tarih aralığında çakışan veya önceden üretilmiş oturumlar atlanarak yalnızca yeni ders oturumları oluşturulur.
                </p>
                <div className="p-3 bg-ivory rounded-xl border border-line text-ink font-mono text-[11px] space-y-1">
                  <p className="text-espresso font-bold">Örnek Şablon Akışı:</p>
                  <p>Pzt 09:00 - Reformer</p>
                  <p>Çrş 18:00 - Mat Pilates</p>
                  <p>Cum 10:00 - Cadillac</p>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  )
}
