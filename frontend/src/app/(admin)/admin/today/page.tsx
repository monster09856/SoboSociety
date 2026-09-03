'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { admin, TodaySessionResponse } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { AdminNav } from '@/components/admin/admin-nav'
import { TodaySessionCard } from '@/components/admin/today-session-card'
import { QuickBookingSidebar } from '@/components/admin/quick-booking-sidebar'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { RefreshCw, Calendar as CalendarIcon, AlertCircle, Loader2, Zap, Sparkles, Plus, CheckCircle2 } from 'lucide-react'

export default function AdminTodayPage() {
  const [sessions, setSessions] = useState<TodaySessionResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedDate, setSelectedDate] = useState<string>(() => {
    const today = new Date()
    return today.toISOString().split('T')[0]
  })
  const [selectedSessionId, setSelectedSessionId] = useState<number | null>(null)

  // New Class Modal / Toggle State
  const [showAddForm, setShowAddForm] = useState(false)
  const [newClassTypeId, setNewClassTypeId] = useState(1)
  const [newInstructorId, setNewInstructorId] = useState(1)
  const [newDateTime, setNewDateTime] = useState(() => {
    const d = new Date()
    d.setHours(10, 0, 0, 0)
    return d.toISOString().slice(0, 16)
  })
  const [newCapacity, setNewCapacity] = useState(5)
  const [addingSession, setAddingSession] = useState(false)

  const [classList, setClassList] = useState<{ id: number; ad: string }[]>([
    { id: 1, ad: 'Barre' },
    { id: 2, ad: 'Pilates' },
    { id: 3, ad: 'Yoga' },
  ])
  const [instructorList, setInstructorList] = useState<{ id: number; ad: string }[]>([
    { id: 1, ad: 'Ece Karaca' },
    { id: 2, ad: 'Defne Yılmaz' },
    { id: 3, ad: 'Can Tezcan' },
  ])

  const loadDropdowns = async () => {
    try {
      const [cts, ins] = await Promise.all([
        admin.getClassTypes().catch(() => []),
        admin.getInstructors().catch(() => []),
      ])
      if (cts && cts.length > 0) {
        setClassList(cts)
        setNewClassTypeId(cts[0].id)
      }
      if (ins && ins.length > 0) {
        setInstructorList(ins)
        setNewInstructorId(ins[0].id)
      }
    } catch (_) {}
  }

  const fetchSessions = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await admin.getToday(selectedDate)
      setSessions(data)
    } catch (err: any) {
      setError(err?.message || 'Bugünün dersleri yüklenirken bir hata oluştu.')
    } finally {
      setLoading(false)
    }
  }, [selectedDate])

  useEffect(() => {
    fetchSessions()
    loadDropdowns()
  }, [fetchSessions])

  const handleAddSession = async (e: React.FormEvent) => {
    e.preventDefault()
    setAddingSession(true)
    setError(null)

    try {
      const isoStart = new Date(newDateTime).toISOString()
      await admin.createSession({
        class_type_id: Number(newClassTypeId),
        instructor_id: Number(newInstructorId),
        baslangic: isoStart,
        kontenjan: Number(newCapacity),
      })
      setShowAddForm(false)
      fetchSessions()
    } catch (err: any) {
      setError(err?.message || 'Yeni ders eklenirken bir hata oluştu.')
    } finally {
      setAddingSession(false)
    }
  }

  const formatDateDisplay = (dateString: string) => {
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString('tr-TR', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      })
    } catch {
      return dateString
    }
  }

  return (
    <div className="min-h-screen bg-ivory text-ink font-sans antialiased relative">
      <AdminNav />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 relative z-10 space-y-8">
        {/* Başlık ve Tarih Seçimi */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1.5">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-sand text-espresso border border-line">
                <Zap className="w-3.5 h-3.5 text-mocha fill-mocha" />
                <span>5 Saniyelik Hızlı Panel</span>
              </span>
            </div>
            <h1 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
              {buyukHarf("Bugünün Dersleri & Yoklama")}
            </h1>
            <p className="text-sm text-secondary font-medium mt-1">
              {formatDateDisplay(selectedDate)}
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowAddForm(!showAddForm)}
              className="px-4 py-2.5 rounded-xl font-bold text-xs uppercase tracking-wider bg-espresso text-ivory hover:bg-espresso-dark transition-all flex items-center gap-2 cursor-pointer shadow-xs"
            >
              <Plus className="w-4 h-4" />
              <span>{showAddForm ? 'Kapat' : 'Tekil Ders Ekle'}</span>
            </button>

            <div className="flex items-center gap-2 bg-sand px-3.5 py-2 rounded-xl border border-line shadow-xs">
              <CalendarIcon className="w-4 h-4 text-espresso" />
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="bg-transparent text-sm font-semibold text-ink focus:outline-none cursor-pointer"
              />
            </div>

            <Button
              variant="outline"
              size="sm"
              onClick={fetchSessions}
              disabled={loading}
              className="gap-2 bg-sand text-ink border-line hover:border-mocha/60 hover:bg-sand rounded-xl h-10 font-bold"
            >
              <RefreshCw className={`w-4 h-4 text-espresso ${loading ? 'animate-spin' : ''}`} />
              <span>Yenile</span>
            </Button>
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
                İstediğiniz tarih ve saati seçerek takvime yeni ders ekleyin.
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
                    {classList.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.ad}
                      </option>
                    ))}
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
                    {instructorList.map((i) => (
                      <option key={i.id} value={i.id}>
                        {i.ad}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                    Ders Günü ve Saati
                  </label>
                  <Input
                    type="datetime-local"
                    value={newDateTime}
                    onChange={(e) => setNewDateTime(e.target.value)}
                    className="bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium cursor-pointer"
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

        {/* Ana İçerik Grid (Dersler + Hızlı Kayıt Çubuğu) */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Ders Kartları Listesi */}
          <div className="lg:col-span-2 space-y-6">
            {loading ? (
              <div className="flex flex-col items-center justify-center py-20 border border-dashed border-line rounded-2xl bg-sand/40">
                <Loader2 className="w-9 h-9 text-espresso animate-spin mb-3" />
                <p className="text-sm text-secondary font-semibold">
                  Ders programı ve katılımcı listesi yükleniyor...
                </p>
              </div>
            ) : error ? (
              <div className="p-6 border border-clay/40 rounded-2xl bg-clay/15 text-clay flex items-start gap-3 shadow-xs">
                <AlertCircle className="w-5 h-5 shrink-0 mt-0.5 text-clay" />
                <div>
                  <h3 className="font-bold text-sm">Yükleme Hatası</h3>
                  <p className="text-xs mt-1">{error}</p>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={fetchSessions}
                    className="mt-3 text-xs border-clay text-clay hover:bg-clay hover:text-white rounded-xl"
                  >
                    Tekrar Deneyin
                  </Button>
                </div>
              </div>
            ) : sessions.length === 0 ? (
              <div className="p-14 text-center border border-dashed border-line rounded-2xl bg-sand/40 space-y-3">
                <div className="p-3.5 rounded-full bg-sand text-espresso inline-block">
                  <CalendarIcon className="w-8 h-8 opacity-80" />
                </div>
                <h3 className="font-serif text-xl font-bold text-ink">
                  Seçilen Tarihte Ders Bulunmuyor
                </h3>
                <p className="text-sm text-secondary max-w-md mx-auto leading-relaxed">
                  {selectedDate} tarihinde tanımlanmış bir ders oturumu yoktur. Yukarıdaki &quot;Tekil Ders Ekle&quot; butonundan veya Ders Programı sayfasından ders ekleyebilirsiniz.
                </p>
              </div>
            ) : (
              <div className="space-y-6">
                <div className="flex items-center justify-between text-xs font-semibold text-secondary px-1">
                  <span>Toplam <strong>{sessions.length} ders oturumu</strong> listeleniyor</span>
                  <span className="flex items-center gap-1 text-mocha">
                    <Sparkles className="w-3.5 h-3.5" /> Canlı Yoklama & Ders Düzenleme Modu
                  </span>
                </div>
                {sessions.map((session) => (
                  <TodaySessionCard
                    key={session.id}
                    session={session}
                    onAttendanceSaved={fetchSessions}
                    onSelectForQuickBooking={(id) => setSelectedSessionId(id)}
                  />
                ))}
              </div>
            )}
          </div>

          {/* Sağ Kolon: Hızlı Kayıt Çubuğu */}
          <div className="lg:col-span-1">
            <QuickBookingSidebar
              sessions={sessions}
              selectedSessionId={selectedSessionId}
              onSelectSessionId={setSelectedSessionId}
              onSuccess={fetchSessions}
            />
          </div>
        </div>
      </main>
    </div>
  )
}
