'use client'

import React, { useState, useEffect } from 'react'
import { admin, SessionGenerateResponse, ClassSessionResponse } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { AdminNav } from '@/components/admin/admin-nav'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Calendar, Sparkles, CheckCircle2, AlertCircle, Loader2, Info, Plus, Trash2, Clock, Users, User, RefreshCw } from 'lucide-react'

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

  // Active Sessions state
  const [sessions, setSessions] = useState<ClassSessionResponse[]>([])
  const [fetchingSessions, setFetchingSessions] = useState(false)

  // New manual session form state
  const [showAddForm, setShowAddForm] = useState(false)
  const [newClassTypeId, setNewClassTypeId] = useState(1)
  const [newInstructorId, setNewInstructorId] = useState(1)
  const [newDateTime, setNewDateTime] = useState(() => {
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    tomorrow.setHours(10, 0, 0, 0)
    return tomorrow.toISOString().slice(0, 16)
  })
  const [newCapacity, setNewCapacity] = useState(5)
  const [addingSession, setAddingSession] = useState(false)
  const [addSuccess, setAddSuccess] = useState(false)

  const loadSessions = async () => {
    setFetchingSessions(true)
    try {
      const data = await admin.getSessions()
      setSessions(data || [])
    } catch (err) {
      console.error('Ders oturumları yüklenemedi:', err)
    } finally {
      setFetchingSessions(false)
    }
  }

  useEffect(() => {
    loadSessions()
  }, [])

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
      loadSessions()
    } catch (err: any) {
      setError(err?.message || 'Ders oturumları türetilirken bir hata oluştu.')
    } finally {
      setLoading(false)
    }
  }

  const handleAddSession = async (e: React.FormEvent) => {
    e.preventDefault()
    setAddingSession(true)
    setError(null)
    setAddSuccess(false)

    try {
      const isoStart = new Date(newDateTime).toISOString()
      await admin.createSession({
        class_type_id: Number(newClassTypeId),
        instructor_id: Number(newInstructorId),
        baslangic: isoStart,
        kontenjan: Number(newCapacity),
      })
      setAddSuccess(true)
      setShowAddForm(false)
      loadSessions()
    } catch (err: any) {
      setError(err?.message || 'Yeni ders eklenirken bir hata oluştu.')
    } finally {
      setAddingSession(false)
    }
  }

  const handleDeleteSession = async (sessionId: number) => {
    if (!confirm('Bu dersi takvimden silmek/iptal etmek istediğinizden emin misiniz?')) return
    try {
      await admin.deleteSession(sessionId)
      loadSessions()
    } catch (err: any) {
      alert(err?.message || 'Ders silinirken hata oluştu.')
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

      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8 relative z-10 space-y-10">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1.5">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-sand text-espresso border border-line">
                <Sparkles className="w-3.5 h-3.5 text-mocha" />
                <span>Yönetici Ders & Program Paneli</span>
              </span>
            </div>
            <h1 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
              {buyukHarf("Ders Programı & Oturum Yönetimi")}
            </h1>
            <p className="text-sm text-secondary font-medium mt-1">
              Stüdyonuzdaki dersleri canlı olarak düzenleyin, yeni dersler ekleyin, silin veya haftalık şablondan otomatik üretin.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowAddForm(!showAddForm)}
              className="px-5 py-2.5 rounded-xl font-bold text-xs uppercase tracking-wider bg-espresso text-ivory hover:bg-espresso-dark transition-all flex items-center gap-2 cursor-pointer shadow-xs"
            >
              <Plus className="w-4 h-4" />
              <span>{showAddForm ? 'Kapat' : 'Tekil Ders Ekle'}</span>
            </button>
            <button
              onClick={loadSessions}
              className="p-2.5 rounded-xl bg-sand border border-line text-ink hover:text-espresso transition-colors cursor-pointer"
              title="Yenile"
            >
              <RefreshCw className={`w-4 h-4 ${fetchingSessions ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>

        {/* Tekil Ders Ekleme Formu */}
        {showAddForm && (
          <Card className="border border-espresso/30 shadow-md bg-sand rounded-2xl text-ink animate-in fade-in slide-in-from-top-2 duration-200">
            <CardHeader className="border-b border-line/80 pb-4">
              <CardTitle className="flex items-center gap-2 text-lg font-serif font-bold text-ink">
                <Plus className="w-5 h-5 text-espresso" />
                <span>Manuel Yeni Ders Oturumu Ekle</span>
              </CardTitle>
              <CardDescription className="text-secondary text-xs">
                Tarih, saat, ders tipi ve eğitmen seçerek takvime tekil ders ekleyin.
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-6">
              <form onSubmit={handleAddSession} className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 items-end">
                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                    Ders Tipi
                  </label>
                  <select
                    value={newClassTypeId}
                    onChange={(e) => setNewClassTypeId(Number(e.target.value))}
                    className="w-full bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium focus:ring-2 focus:ring-espresso"
                  >
                    <option value={1}>Barre</option>
                    <option value={2}>Pilates</option>
                    <option value={3}>Yoga</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                    Eğitmen
                  </label>
                  <select
                    value={newInstructorId}
                    onChange={(e) => setNewInstructorId(Number(e.target.value))}
                    className="w-full bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium focus:ring-2 focus:ring-espresso"
                  >
                    <option value={1}>Ece Karaca</option>
                    <option value={2}>Defne Yılmaz</option>
                    <option value={3}>Can Tezcan</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                    Tarih & Saat
                  </label>
                  <Input
                    type="datetime-local"
                    value={newDateTime}
                    onChange={(e) => setNewDateTime(e.target.value)}
                    className="bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                    Kontenjan (Max Üye)
                  </label>
                  <Input
                    type="number"
                    min={1}
                    max={20}
                    value={newCapacity}
                    onChange={(e) => setNewCapacity(Number(e.target.value))}
                    className="bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium"
                    required
                  />
                </div>

                <div className="sm:col-span-2 md:col-span-4 pt-2 flex justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setShowAddForm(false)}
                    className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink transition-colors cursor-pointer"
                  >
                    İptal
                  </button>
                  <button
                    type="submit"
                    disabled={addingSession}
                    className="px-6 py-2.5 rounded-xl font-extrabold text-xs uppercase tracking-wider bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                  >
                    {addingSession ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
                    <span>Dersi Takvime Ekle</span>
                  </button>
                </div>
              </form>
            </CardContent>
          </Card>
        )}

        {/* Canlı Takvimdeki Dersler Listesi Grid */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <Calendar className="w-5 h-5 text-espresso" />
              <span>Takvimdeki Mevcut Dersler ({sessions.length})</span>
            </h2>
            <span className="text-xs text-secondary font-medium">Her sınıfta varsayılan maks. 5 üye</span>
          </div>

          {fetchingSessions ? (
            <div className="flex h-32 items-center justify-center rounded-2xl bg-sand/60 border border-line">
              <Loader2 className="w-6 h-6 animate-spin text-espresso" />
            </div>
          ) : sessions.length === 0 ? (
            <div className="p-8 text-center bg-sand/60 border border-line rounded-2xl space-y-3">
              <Info className="w-8 h-8 text-mocha mx-auto opacity-60" />
              <p className="text-sm font-medium text-ink">Henüz aktif ders oturumu bulunmamaktadır.</p>
              <p className="text-xs text-secondary max-w-sm mx-auto">
                Aşağıdaki türetme motorunu kullanarak şablondan haftalık dersler oluşturabilir veya yukarıdaki &quot;Tekil Ders Ekle&quot; butonunu kullanabilirsiniz.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {sessions.map((s) => (
                <Card key={s.id} className="border border-line shadow-xs bg-sand rounded-2xl overflow-hidden hover:border-espresso/40 transition-all">
                  <CardHeader className="pb-3 border-b border-line/60 bg-sand-light/50">
                    <div className="flex items-center justify-between">
                      <span className="inline-block px-2.5 py-0.5 rounded-full text-[10px] uppercase font-bold tracking-wider bg-espresso text-ivory">
                        {s.class_type?.ad || 'Ders'}
                      </span>
                      <span className="text-xs font-extrabold text-espresso">
                        {s.dolu_sayi} / {s.kontenjan} Üye (%{Math.round((s.dolu_sayi / (s.kontenjan || 1)) * 100)})
                      </span>
                    </div>
                    <CardTitle className="font-serif text-lg font-bold text-ink mt-2">
                      {s.class_type?.ad} Seansı
                    </CardTitle>
                  </CardHeader>

                  <CardContent className="pt-4 space-y-3 text-xs text-secondary font-medium">
                    <div className="flex items-center gap-2 text-ink font-semibold">
                      <Calendar className="w-3.5 h-3.5 text-mocha shrink-0" />
                      <span>{formatDate(s.baslangic)}</span>
                    </div>

                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Clock className="w-3.5 h-3.5 text-mocha shrink-0" />
                        <span>Saat: {formatTime(s.baslangic)} ({s.class_type?.sure_dk || 50} dk)</span>
                      </div>
                      <div className="flex items-center gap-1.5">
                        <User className="w-3.5 h-3.5 text-mocha shrink-0" />
                        <span className="text-ink font-semibold">{s.instructor?.ad || 'Eğitmen'}</span>
                      </div>
                    </div>

                    {/* Action buttons */}
                    <div className="pt-2 border-t border-line/50 flex justify-end">
                      <button
                        onClick={() => handleDeleteSession(s.id)}
                        className="px-3 py-1.5 rounded-lg text-[11px] font-bold text-clay hover:bg-clay/10 transition-colors flex items-center gap-1.5 cursor-pointer"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        <span>Dersi İptal Et / Sil</span>
                      </button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* Şablondan Toplu Ders Oturumu Türetme Engine */}
        <div className="pt-6 border-t border-line/80">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* Sol Kolon: Türetme Formu */}
            <div className="md:col-span-2 space-y-6">
              <Card className="border border-line shadow-xs bg-sand rounded-2xl text-ink overflow-hidden">
                <CardHeader className="border-b border-line/80 pb-4">
                  <CardTitle className="flex items-center gap-2.5 text-xl font-serif font-bold text-ink">
                    <Calendar className="w-5 h-5 text-espresso" />
                    <span>{buyukHarf("Şablondan Toplu Ders Oturumları Türet")}</span>
                  </CardTitle>
                  <CardDescription className="text-secondary text-xs font-medium">
                    Haftalık sabit ders programı şablonunu seçtiğiniz tarih aralığı için otomatik oturumlara dönüştürün.
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
                    <span>{buyukHarf("Admin Yetki Rehberi")}</span>
                  </CardTitle>
                </CardHeader>
                <CardContent className="pt-4 text-xs text-secondary space-y-3 leading-relaxed font-medium">
                  <p>
                    Yönetici olarak stüdyonun tüm haftalık ve günlük ders programını tam yetkiyle yönetebilirsiniz:
                  </p>
                  <ul className="space-y-1.5 pl-4 list-disc text-ink font-semibold">
                    <li>Tekil yeni ders ekleyebilirsiniz</li>
                    <li>İptal olan dersleri silebilirsiniz</li>
                    <li>Sınıf kontenjanını düzenleyebilirsiniz</li>
                    <li>Haftalık şablondan toplu ders türetebilirsiniz</li>
                  </ul>
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
