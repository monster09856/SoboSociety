'use client'

import React, { useState, useEffect } from 'react'
import { admin, api, TodaySessionResponse, AttendeeResponse, ClassTypeResponse, InstructorResponse } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import {
  Users,
  Clock,
  UserCheck,
  UserX,
  CheckCircle2,
  AlertCircle,
  Loader2,
  PlusCircle,
  Sparkles,
  Edit2,
  X,
  Plus,
  Trash2,
} from 'lucide-react'

interface TodaySessionCardProps {
  session: TodaySessionResponse
  onAttendanceSaved?: () => void
  onSelectForQuickBooking?: (sessionId: number) => void
}

export function TodaySessionCard({
  session,
  onAttendanceSaved,
  onSelectForQuickBooking,
}: TodaySessionCardProps) {
  const attendeesList: AttendeeResponse[] =
    session.katilimcilar && session.katilimcilar.length > 0
      ? session.katilimcilar
      : session.attendees || []

  const [attendedSet, setAttendedSet] = useState<Set<number>>(() => {
    const initial = new Set<number>()
    attendeesList.forEach((att) => {
      if (att.durum === 'attended' || att.durum === 'booked') {
        initial.add(att.member_id)
      }
    })
    return initial
  })

  useEffect(() => {
    const nextSet = new Set<number>()
    attendeesList.forEach((att) => {
      if (att.durum === 'attended' || att.durum === 'booked') {
        nextSet.add(att.member_id)
      }
    })
    setAttendedSet(nextSet)
  }, [session])

  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  // Edit Modal State
  const [showEditModal, setShowEditModal] = useState(false)
  const [editClassTypeId, setEditClassTypeId] = useState(session.class_type?.id || 1)
  const [editInstructorId, setEditInstructorId] = useState(session.instructor?.id || 1)
  const [editDateTime, setEditDateTime] = useState('')
  const [editCapacity, setEditCapacity] = useState(session.kontenjan || 5)
  const [updatingSession, setUpdatingSession] = useState(false)

  // Dynamic Lists for Class Types & Instructors
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
      if (cts && cts.length > 0) setClassList(cts)
      if (ins && ins.length > 0) setInstructorList(ins)
    } catch (_) {}
  }

  useEffect(() => {
    if (showEditModal) {
      loadDropdowns()
    }
  }, [showEditModal])

  useEffect(() => {
    if (session.baslangic) {
      try {
        const dt = new Date(session.baslangic)
        const tzOffset = dt.getTimezoneOffset() * 60000
        const localISOTime = (new Date(dt.getTime() - tzOffset)).toISOString().slice(0, 16)
        setEditDateTime(localISOTime)
      } catch {
        setEditDateTime('')
      }
    }
  }, [session.baslangic])

  const handleAddNewClassType = async () => {
    const ad = prompt('Yeni Ders Tipi Adı (Örn: Reformer Pilates, Zumba, HIIT):')
    if (!ad || !ad.trim()) return
    try {
      const created = await admin.addClassType({ ad: ad.trim() })
      setClassList((prev) => [...prev.filter((c) => c.id !== created.id), created])
      setEditClassTypeId(created.id)
    } catch (err: any) {
      alert(err?.message || 'Ders tipi eklenemedi.')
    }
  }

  const handleAddNewInstructor = async () => {
    const ad = prompt('Yeni Eğitmen Adı Soyadı (Örn: Selin Yılmaz):')
    if (!ad || !ad.trim()) return
    try {
      const created = await admin.addInstructor({ ad: ad.trim() })
      setInstructorList((prev) => [...prev.filter((i) => i.id !== created.id), created])
      setEditInstructorId(created.id)
    } catch (err: any) {
      alert(err?.message || 'Eğitmen eklenemedi.')
    }
  }

  const toggleAttendance = (memberId: number, attended: boolean) => {
    setAttendedSet((prev) => {
      const copy = new Set(prev)
      if (attended) {
        copy.add(memberId)
      } else {
        copy.delete(memberId)
      }
      return copy
    })
  }

  const handleSaveAttendance = async () => {
    setMessage(null)
    setLoading(true)
    try {
      const gelenIds = Array.from(attendedSet)
      const res = await admin.submitAttendance({
        session_id: session.id,
        gelen_member_ids: gelenIds,
      })

      setMessage({
        type: 'success',
        text: `Yoklama kaydedildi: ${res.gelen} Katılan, ${res.gelmeyen} Gelmeyen`,
      })

      if (onAttendanceSaved) {
        onAttendanceSaved()
      }
    } catch (err: any) {
      setMessage({
        type: 'error',
        text: err?.message || 'Yoklama kaydedilirken bir hata oluştu.',
      })
    } finally {
      setLoading(false)
    }
  }

  const handleUpdateSession = async (e: React.FormEvent) => {
    e.preventDefault()
    setUpdatingSession(true)
    setMessage(null)

    try {
      const isoStart = new Date(editDateTime).toISOString()
      await admin.updateSession(session.id, {
        class_type_id: Number(editClassTypeId),
        instructor_id: Number(editInstructorId),
        baslangic: isoStart,
        kontenjan: Number(editCapacity),
      })
      setShowEditModal(false)
      if (onAttendanceSaved) {
        onAttendanceSaved()
      }
    } catch (err: any) {
      setMessage({
        type: 'error',
        text: err?.message || 'Ders saatleri güncellenirken hata oluştu.',
      })
    } finally {
      setUpdatingSession(false)
    }
  }

  const handleCancelMemberBooking = async (bookingId: number, memberName: string) => {
    if (!confirm(`${memberName} üyesinin bu dersteki kaydını iptal edip kredisini iade etmek istediğinizden emin misiniz?`)) return
    try {
      await api.bookings.cancel(bookingId)
      setMessage({ type: 'success', text: `${memberName} üyesinin kaydı iptal edildi ve ders kredisi iade edildi.` })
      if (onAttendanceSaved) onAttendanceSaved()
    } catch (err: any) {
      setMessage({ type: 'error', text: err?.message || 'İptal edilirken hata oluştu.' })
    }
  }

  const formatTime = (isoString: string) => {
    try {
      const date = new Date(isoString)
      return date.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })
    } catch {
      return ''
    }
  }

  const classTitle = session.class_type?.ad || 'Grupsal Ders'
  const instructorName = session.instructor?.ad || 'Atanmadı'
  const startTime = formatTime(session.baslangic)
  const capacityRatio = `${session.dolu_sayi}/${session.kontenjan}`

  return (
    <Card className="border border-line shadow-xs bg-sand/60 hover:bg-sand rounded-2xl text-ink overflow-hidden transition-all duration-300 relative">
      <CardHeader className="pb-4 border-b border-line/80">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2 mb-1.5">
              <span className="inline-flex items-center gap-1 px-3 py-0.5 rounded-full text-xs font-bold bg-espresso/10 text-espresso border border-line">
                <Clock className="w-3.5 h-3.5" />
                {startTime}
              </span>
              <span
                className={`inline-flex items-center gap-1 px-3 py-0.5 rounded-full text-xs font-bold ${
                  session.dolu_sayi >= session.kontenjan
                    ? 'bg-clay/15 text-clay border border-clay/30'
                    : 'bg-sage/15 text-sage border border-sage/30'
                }`}
              >
                <Users className="w-3.5 h-3.5" />
                {capacityRatio} Dolu
              </span>
            </div>
            <CardTitle className="text-2xl font-serif font-bold text-ink tracking-wide">
              {buyukHarf(classTitle)}
            </CardTitle>
            <p className="text-xs text-secondary font-medium mt-1">
              Eğitmen: <span className="font-semibold text-ink">{instructorName}</span>
            </p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowEditModal(true)}
              className="px-3 py-2 rounded-xl text-xs font-bold bg-ivory hover:bg-sand text-espresso border border-line transition-all flex items-center gap-1.5 cursor-pointer shadow-xs"
              title="Ders Günü ve Saatini Değiştir"
            >
              <Edit2 className="w-4 h-4 text-mocha" />
              <span>Saat / Gün Düzenle</span>
            </button>

            {onSelectForQuickBooking && (
              <button
                onClick={() => onSelectForQuickBooking(session.id)}
                className="px-3.5 py-2 rounded-xl text-xs font-bold bg-espresso hover:bg-espresso-dark text-ivory transition-all flex items-center gap-1.5 cursor-pointer shadow-xs"
              >
                <PlusCircle className="w-4 h-4 text-ivory" />
                <span>+ Hızlı Kayıt</span>
              </button>
            )}
          </div>
        </div>
      </CardHeader>

      <CardContent className="pt-5 pb-3 space-y-3">
        <div className="flex items-center justify-between">
          <h4 className="text-xs font-bold uppercase tracking-wider text-secondary flex items-center gap-1.5">
            <Sparkles className="w-3.5 h-3.5 text-mocha" />
            <span>Katılımcı Yoklama Listesi</span> ({attendeesList.length})
          </h4>
          <span className="text-[11px] font-semibold text-secondary">
            <strong className="text-sage">{attendedSet.size} Katıldı</strong> / <strong className="text-clay">{attendeesList.length - attendedSet.size} Gelmedi</strong>
          </span>
        </div>

        {attendeesList.length === 0 ? (
          <div className="p-6 text-center border border-dashed border-line rounded-2xl bg-ivory/60">
            <p className="text-xs text-secondary font-medium">Bu derse henüz üye kaydolmadı.</p>
          </div>
        ) : (
          <div className="space-y-2.5 max-h-64 overflow-y-auto pr-1">
            {attendeesList.map((att) => {
              const isAttended = attendedSet.has(att.member_id)
              return (
                <div
                  key={att.booking_id}
                  className={`flex items-center justify-between p-3 rounded-xl border transition-all ${
                    isAttended
                      ? 'bg-sage/10 border-sage/30 text-ink'
                      : 'bg-clay/10 border-clay/30 text-ink'
                  }`}
                >
                  <div className="min-w-0 pr-2">
                    <p className="text-sm font-bold text-ink truncate">{att.ad}</p>
                    <p className="text-xs text-secondary font-mono">{att.telefon}</p>
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      type="button"
                      onClick={() => toggleAttendance(att.member_id, true)}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs transition-all cursor-pointer ${
                        isAttended
                          ? 'bg-sage text-white font-extrabold shadow-xs border-none'
                          : 'bg-ivory text-secondary hover:bg-sage/15 hover:text-sage border border-line font-medium'
                      }`}
                    >
                      <UserCheck className="w-3.5 h-3.5" />
                      <span>Katıldı</span>
                    </button>

                    <button
                      type="button"
                      onClick={() => toggleAttendance(att.member_id, false)}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs transition-all cursor-pointer ${
                        !isAttended
                          ? 'bg-clay text-white font-extrabold shadow-xs border-none'
                          : 'bg-ivory text-secondary hover:bg-clay/15 hover:text-clay border border-line font-medium'
                      }`}
                    >
                      <UserX className="w-3.5 h-3.5" />
                      <span>Gelmedi</span>
                    </button>

                    <button
                      type="button"
                      onClick={() => handleCancelMemberBooking(att.booking_id, att.ad)}
                      className="p-1.5 rounded-xl text-clay hover:bg-clay/15 transition-all cursor-pointer border border-clay/30"
                      title="Bu üyenin kaydını iptal et ve kredisini iade et"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {message && (
          <div
            className={`p-3 rounded-xl text-xs font-medium flex items-center gap-2.5 ${
              message.type === 'success'
                ? 'bg-sage/15 text-sage border border-sage/40'
                : 'bg-clay/15 text-clay border border-clay/40'
            }`}
          >
            {message.type === 'success' ? (
              <CheckCircle2 className="w-4 h-4 text-sage shrink-0" />
            ) : (
              <AlertCircle className="w-4 h-4 text-clay shrink-0" />
            )}
            <span>{message.text}</span>
          </div>
        )}
      </CardContent>

      <CardFooter className="pt-3">
        <button
          onClick={handleSaveAttendance}
          disabled={loading || attendeesList.length === 0}
          className="w-full h-11 rounded-xl text-ivory font-extrabold text-xs tracking-wider uppercase bg-espresso hover:bg-espresso-dark shadow-xs transition-all duration-200 transform hover:scale-[1.01] active:scale-[0.99] border-none flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
        >
          {loading ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              Kaydediliyor...
            </>
          ) : (
            <>
              <CheckCircle2 className="w-4 h-4 text-mocha" />
              <span>YOKLAMAYI KAYDET</span>
            </>
          )}
        </button>
      </CardFooter>

      {/* Modal: Edit Class Hours & Details */}
      {showEditModal && (
        <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs flex items-center justify-center p-4">
          <Card className="max-w-md w-full bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150 text-ink">
            <CardHeader className="border-b border-line pb-4 relative">
              <button
                type="button"
                onClick={() => setShowEditModal(false)}
                className="absolute top-4 right-4 text-secondary hover:text-ink p-1 rounded-full hover:bg-sand cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
              <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                <Edit2 className="w-5 h-5 text-espresso" />
                <span>Ders Günü & Saatini Değiştir</span>
              </CardTitle>
              <p className="text-xs text-secondary mt-1">
                <strong>{classTitle}</strong> dersinin yapılacağı tarihi, saati, eğitmeni ve kontenjanını güncelleyin.
              </p>
            </CardHeader>
            <CardContent className="pt-6 space-y-4">
              <form onSubmit={handleUpdateSession} className="space-y-4">
                <div>
                  <div className="flex items-center justify-between mb-1.5">
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider">
                      Ders Tipi
                    </label>
                    <button
                      type="button"
                      onClick={handleAddNewClassType}
                      className="text-[11px] font-bold text-espresso hover:underline flex items-center gap-1 cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      <span>+ Yeni Tipi Ekle</span>
                    </button>
                  </div>
                  <select
                    value={editClassTypeId}
                    onChange={(e) => setEditClassTypeId(Number(e.target.value))}
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
                  <div className="flex items-center justify-between mb-1.5">
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider">
                      Eğitmen
                    </label>
                    <button
                      type="button"
                      onClick={handleAddNewInstructor}
                      className="text-[11px] font-bold text-espresso hover:underline flex items-center gap-1 cursor-pointer"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      <span>+ Yeni Eğitmen Ekle</span>
                    </button>
                  </div>
                  <select
                    value={editInstructorId}
                    onChange={(e) => setEditInstructorId(Number(e.target.value))}
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
                    Ders Günü & Başlangıç Saati
                  </label>
                  <Input
                    type="datetime-local"
                    value={editDateTime}
                    onChange={(e) => setEditDateTime(e.target.value)}
                    className="bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium cursor-pointer"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                    Kontenjan (Maksimum Üye Sayısı)
                  </label>
                  <Input
                    type="number"
                    min={1}
                    max={20}
                    value={editCapacity}
                    onChange={(e) => setEditCapacity(Number(e.target.value))}
                    className="bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium"
                    required
                  />
                </div>

                <div className="pt-2 flex justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setShowEditModal(false)}
                    className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                  >
                    İptal
                  </button>
                  <button
                    type="submit"
                    disabled={updatingSession}
                    className="px-5 py-2.5 rounded-xl font-extrabold text-xs uppercase tracking-wider bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                  >
                    {updatingSession ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle2 className="w-4 h-4" />}
                    <span>DERSİ GÜNCELLE</span>
                  </button>
                </div>
              </form>
            </CardContent>
          </Card>
        </div>
      )}
    </Card>
  )
}
