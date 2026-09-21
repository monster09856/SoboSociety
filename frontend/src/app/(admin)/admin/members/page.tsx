'use client'

import React, { useState, useEffect } from 'react'
import { admin } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { AdminNav } from '@/components/admin/admin-nav'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Users, Search, Plus, CreditCard, Send, Edit2, ShieldAlert, CheckCircle2, Loader2, Sparkles, UserCheck, AtSign, Phone, Ruler, X, Package, Trash2, UserX, Clock, XCircle, Calendar, KeyRound } from 'lucide-react'

interface MemberDetail {
  id: number
  ad: string
  kullanici_adi?: string | null
  telefon?: string | null
  bakiye: number
  aktif: boolean
  is_admin: boolean
  bel?: string | null
  kalca?: string | null
  sag_ic_bacak?: string | null
  sag_bacak?: string | null
  sol_ic_bacak?: string | null
  sol_bacak?: string | null
  sag_kol?: string | null
  sol_kol?: string | null
  boy?: string | null
  kilo?: string | null
  saglik_notu?: string | null
  sabit_ders_saatleri?: string | null
  aktif_member_package_id?: number | null
  aktif_paket_adi?: string | null
  paket_baslangic_tarihi?: string | null
  paket_bitis_tarihi?: string | null
  kalan_gun_sayisi?: number | null
  aktif_paketler?: {
    id: number
    ad: string
    baslangic_tarihi: string
    bitis_tarihi: string
    kalan_gun: number
    toplam_ders: number
    aktif: boolean
  }[]
  tanimlanan_paketler?: string[]
  aktif_rezervasyonlar?: string[]
  rezerve_ders_detaylari?: {
    booking_id: number
    session_id: number
    ders_adi: string
    tarih_saat: string
    egitmen: string
  }[]
}

const formatDateToInput = (d: Date): string => {
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

const addDaysToDate = (dateStr: string, days: number): string => {
  if (!dateStr) return ''
  const parts = dateStr.split('-')
  if (parts.length !== 3) return ''
  const d = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
  d.setDate(d.getDate() + days)
  return formatDateToInput(d)
}

const toIsoDate = (dStr: string | null | undefined): string => {
  if (!dStr) return ''
  if (dStr.includes('-')) return dStr
  if (dStr.includes('.')) {
    const parts = dStr.split('.')
    if (parts.length === 3) {
      const d = parts[0].padStart(2, '0')
      const m = parts[1].padStart(2, '0')
      const y = parts[2]
      return `${y}-${m}-${d}`
    }
  }
  return ''
}

export default function AdminMembersPage() {
  const [members, setMembers] = useState<MemberDetail[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  // Edit / Intervention State
  const [editingMember, setEditingMember] = useState<MemberDetail | null>(null)
  const [newBakiye, setNewBakiye] = useState<number>(0)
  const [newName, setNewName] = useState<string>('')
  const [editBel, setEditBel] = useState('')
  const [editKalca, setEditKalca] = useState('')
  const [editSagIcBacak, setEditSagIcBacak] = useState('')
  const [editSagBacak, setEditSagBacak] = useState('')
  const [editSolIcBacak, setEditSolIcBacak] = useState('')
  const [editSolBacak, setEditSolBacak] = useState('')
  const [editSagKol, setEditSagKol] = useState('')
  const [editSolKol, setEditSolKol] = useState('')
  const [editBoy, setEditBoy] = useState('')
  const [editKilo, setEditKilo] = useState('')
  const [editSaglikNotu, setEditSaglikNotu] = useState('')
  const [editSabitDersSaatleri, setEditSabitDersSaatleri] = useState('')
  const [editPassword, setEditPassword] = useState('')
  const [updating, setUpdating] = useState(false)

  // Package Edit Modal State
  const [editingPkgMember, setEditingPkgMember] = useState<MemberDetail | null>(null)
  const [editingPkg, setEditingPkg] = useState<any | null>(null)
  const [pkgEditKalanDers, setPkgEditKalanDers] = useState<number>(0)
  const [pkgEditSabitDers, setPkgEditSabitDers] = useState<string>('')
  const [pkgEditEkGun, setPkgEditEkGun] = useState<number | null>(null)
  const [pkgEditBaslangic, setPkgEditBaslangic] = useState<string>('')
  const [pkgEditBitis, setPkgEditBitis] = useState<string>('')
  const [updatingPkg, setUpdatingPkg] = useState(false)

  // Single Push Notification Modal State
  const [notifMember, setNotifMember] = useState<MemberDetail | null>(null)
  const [notifTitle, setNotifTitle] = useState('')
  const [notifBody, setNotifBody] = useState('')
  const [sendingNotif, setSendingNotif] = useState(false)

  // Assign Package Modal State
  const [pkgMember, setPkgMember] = useState<MemberDetail | null>(null)
  const [availablePackages, setAvailablePackages] = useState<any[]>([])
  const [selectedPkgId, setSelectedPkgId] = useState<number>(11)
  const [pkgBaslangic, setPkgBaslangic] = useState<string>('')
  const [pkgBitis, setPkgBitis] = useState<string>('')
  const [isCustomPkg, setIsCustomPkg] = useState(false)
  const [customPkgName, setCustomPkgName] = useState('')
  const [customCredits, setCustomCredits] = useState(10)
  const [customUnit, setCustomUnit] = useState<'hafta' | 'gun'>('hafta')
  const [customVal, setCustomVal] = useState(6)
  const [pkgSabitDersSaatleri, setPkgSabitDersSaatleri] = useState('')
  const [assigningPkg, setAssigningPkg] = useState(false)

  // Book Member into Session Modal State
  const [bookingMember, setBookingMember] = useState<MemberDetail | null>(null)
  const [sessionsList, setSessionsList] = useState<any[]>([])
  const [selectedSessionId, setSelectedSessionId] = useState<number | null>(null)
  const [loadingSessions, setLoadingSessions] = useState(false)
  const [bookingLoading, setBookingLoading] = useState(false)

  const openBookSessionModal = async (m: MemberDetail) => {
    setBookingMember(m)
    setSelectedSessionId(null)
    setLoadingSessions(true)
    try {
      const data = await admin.getSessions()
      const now = new Date()
      // Filter sessions that are upcoming
      const upcoming = (data || []).filter((s: any) => new Date(s.baslangic) >= now)
      setSessionsList(upcoming)
      if (upcoming.length > 0) {
        setSelectedSessionId(upcoming[0].id)
      }
    } catch (err: any) {
      console.error('Seanslar yüklenemedi:', err)
      setError('Ders seansları listelenirken hata oluştu.')
    } finally {
      setLoadingSessions(false)
    }
  }

  const handleBookSessionForMember = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!bookingMember || !selectedSessionId) return
    setBookingLoading(true)
    setError(null)
    setSuccess(null)
    try {
      const res = await admin.bookSessionForMember(bookingMember.id, selectedSessionId)
      setSuccess(res.mesaj || `${bookingMember.ad} derse başarıyla kaydedildi.`)
      setBookingMember(null)
      loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Derse kayıt sırasında hata oluştu.')
    } finally {
      setBookingLoading(false)
    }
  }

  const loadMembers = async (query?: string) => {
    setLoading(true)
    setError(null)
    try {
      const data = await admin.getMembers(query)
      setMembers(data || [])
    } catch (err: any) {
      console.error('Üyeler yüklenemedi:', err)
      setError(err?.message || 'Üye listesi çekilirken hata oluştu.')
    } finally {
      setLoading(false)
    }
  }

  const loadPackages = async () => {
    try {
      const pkgs = await admin.getPackages()
      const activePkgs = (pkgs || []).filter((p: any) => p.aktif)
      const list = activePkgs.length > 0 ? activePkgs : pkgs || []
      setAvailablePackages(list)
      if (list.length > 0) {
        setSelectedPkgId(list[0].id)
      }
    } catch (err) {
      console.error('Paketler yüklenemedi:', err)
    }
  }

  useEffect(() => {
    loadMembers()
    loadPackages()
  }, [])

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    loadMembers(search)
  }

  const openAssignModal = (m: MemberDetail) => {
    const todayStr = formatDateToInput(new Date())
    setPkgMember(m)
    setIsCustomPkg(false)
    setCustomPkgName(`${m.ad} Özel Paket`)
    setCustomCredits(10)
    setCustomUnit('hafta')
    setCustomVal(6)
    setPkgSabitDersSaatleri(m.sabit_ders_saatleri || '')
    setPkgBaslangic(todayStr)

    const defaultPkg = availablePackages.find((p) => p.id === selectedPkgId) || availablePackages[0]
    const pId = defaultPkg ? defaultPkg.id : 11
    setSelectedPkgId(pId)
    const days = defaultPkg ? defaultPkg.gecerlilik_gun : 42
    setPkgBitis(addDaysToDate(todayStr, days))
  }

  const openEditModal = (m: MemberDetail) => {
    setEditingMember(m)
    setNewName(m.ad)
    setNewBakiye(m.bakiye)
    setEditBel(m.bel || '')
    setEditKalca(m.kalca || '')
    setEditSagIcBacak(m.sag_ic_bacak || '')
    setEditSagBacak(m.sag_bacak || '')
    setEditSolIcBacak(m.sol_ic_bacak || '')
    setEditSolBacak(m.sol_bacak || '')
    setEditSagKol(m.sag_kol || '')
    setEditSolKol(m.sol_kol || '')
    setEditBoy(m.boy || '')
    setEditKilo(m.kilo || '')
    setEditSaglikNotu(m.saglik_notu || '')
    setEditSabitDersSaatleri(m.sabit_ders_saatleri || '')
    setEditPassword('')
  }

  const openEditPackageModal = (m: MemberDetail, pkg: any) => {
    setEditingPkgMember(m)
    setEditingPkg(pkg)
    setPkgEditKalanDers(pkg.toplam_ders || m.bakiye || 0)
    setPkgEditSabitDers(m.sabit_ders_saatleri || '')
    setPkgEditEkGun(null)
    const startIso = toIsoDate(pkg.baslangic_tarihi || m.paket_baslangic_tarihi)
    setPkgEditBaslangic(startIso || formatDateToInput(new Date()))
    const endIso = toIsoDate(pkg.bitis_tarihi || m.paket_bitis_tarihi)
    setPkgEditBitis(endIso)
  }

  const handleUpdateMember = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editingMember) return
    setUpdating(true)
    setError(null)
    setSuccess(null)

    try {
      await admin.updateMember(editingMember.id, {
        ad: newName,
        bakiye_override: Number(newBakiye),
        bel: editBel,
        kalca: editKalca,
        sag_ic_bacak: editSagIcBacak,
        sag_bacak: editSagBacak,
        sol_ic_bacak: editSolIcBacak,
        sol_bacak: editSolBacak,
        sag_kol: editSagKol,
        sol_kol: editSolKol,
        boy: editBoy,
        kilo: editKilo,
        saglik_notu: editSaglikNotu,
        sabit_ders_saatleri: editSabitDersSaatleri,
        ...(editPassword.trim() ? { yeni_sifre: editPassword.trim() } : {}),
      })
      setSuccess(`${newName} üyesinin tüm bilgileri, sabit ders saatleri ve bakiyesi güncellendi.${editPassword.trim() ? ' Yeni şifre başarıyla tanımlandı.' : ''}`)
      setEditingMember(null)
      setEditPassword('')
      loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Üye güncellenirken bir hata oluştu.')
    } finally {
      setUpdating(false)
    }
  }

  const handleUpdatePackage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editingPkgMember || !editingPkg) return
    setUpdatingPkg(true)
    setError(null)
    setSuccess(null)

    try {
      const payload: any = {}
      if (pkgEditKalanDers !== undefined) payload.kalan_ders = Number(pkgEditKalanDers)
      if (pkgEditBaslangic) payload.baslangic = pkgEditBaslangic
      if (pkgEditEkGun) payload.ek_gun = Number(pkgEditEkGun)
      else if (pkgEditBitis) payload.bitis = pkgEditBitis
      if (pkgEditSabitDers !== undefined) payload.sabit_ders_saatleri = pkgEditSabitDers.trim()

      await admin.updateMemberPackage(editingPkgMember.id, editingPkg.id, payload)
      if (pkgEditSabitDers.trim()) {
        try {
          await admin.updateMember(editingPkgMember.id, { sabit_ders_saatleri: pkgEditSabitDers.trim() })
        } catch (_) {}
      }

      setSuccess(`${editingPkgMember.ad} üyesinin paket bilgileri ve sabit ders saatleri güncellendi. ✨`)
      setEditingPkgMember(null)
      setEditingPkg(null)
      loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Paket güncellenirken hata oluştu.')
    } finally {
      setUpdatingPkg(false)
    }
  }

  const handleSendSinglePush = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!notifMember) return
    setSendingNotif(true)
    setError(null)
    setSuccess(null)

    try {
      await admin.sendSingleNotification(notifMember.id, {
        baslik: notifTitle,
        mesaj: notifBody,
      })
      setSuccess(`${notifMember.ad} üyesine özel bildirim başarıyla gönderildi!`)
      setNotifMember(null)
      setNotifTitle('')
      setNotifBody('')
    } catch (err: any) {
      setError(err?.message || 'Bildirim gönderilemedi.')
    } finally {
      setSendingNotif(false)
    }
  }

  const handleAssignPackage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!pkgMember) return
    setAssigningPkg(true)
    setError(null)
    setSuccess(null)

    try {
      if (isCustomPkg) {
        const actualDays = customUnit === 'hafta' ? Number(customVal) * 7 : Number(customVal)
        await admin.assignPackage({
          member_id: pkgMember.id,
          ozel_paket_adi: customPkgName.trim() || 'Özel Üye Paketi',
          ozel_ders_adedi: Number(customCredits),
          ozel_gecerlilik_gun: actualDays,
          baslangic: pkgBaslangic || undefined,
          bitis: pkgBitis || undefined,
          sabit_ders_saatleri: pkgSabitDersSaatleri.trim() || undefined,
        })
        setSuccess(`${pkgMember.ad} üyesine özel ${customPkgName || 'Özel Paket'} (${customCredits} Ders / ${actualDays} Gün - ${customUnit === 'hafta' ? `${customVal} Hafta` : ''}) tanımlandı.`)
      } else {
        await admin.assignPackage({
          member_id: pkgMember.id,
          package_id: selectedPkgId,
          baslangic: pkgBaslangic || undefined,
          bitis: pkgBitis || undefined,
          sabit_ders_saatleri: pkgSabitDersSaatleri.trim() || undefined,
        })
        setSuccess(`${pkgMember.ad} üyesine ders paketi tanımlandı.`)
      }
      if (pkgSabitDersSaatleri.trim()) {
        try {
          await admin.updateMember(pkgMember.id, { sabit_ders_saatleri: pkgSabitDersSaatleri.trim() })
        } catch (_) {}
      }
      setPkgMember(null)
      setPkgSabitDersSaatleri('')
      loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Paket tanımlanırken hata oluştu.')
    } finally {
      setAssigningPkg(false)
    }
  }

  const handleCancelPackage = async (memberId: number, memberPackageId: number, packageName: string, memberName: string) => {
    if (!confirm(`${memberName} üyesinin '${packageName}' paketini ve bu pakete ait ders hakkını iptal etmek istediğinizden emin misiniz?`)) return
    try {
      await admin.cancelPackage(memberId, memberPackageId)
      setSuccess(`${memberName} üyesinin '${packageName}' paketi başarıyla iptal edildi.`)
      await loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Paket iptal edilirken bir hata oluştu.')
    }
  }

  const handleCancelReservation = async (bookingId: number, memberName: string, sessionInfo: string) => {
    if (!confirm(`${memberName} üyesinin "${sessionInfo}" rezervasyonunu iptal etmek istediğinize emin misiniz?\n\n• Ders hakkı üyenin bakiyesine anında geri iade edilecektir.\n• Seans kontenjanı boşalacaktır.`)) return
    try {
      await admin.cancelBooking(bookingId)
      setSuccess(`${memberName} üyesinin rezervasyonu iptal edildi ve ders hakkı iade edildi.`)
      await loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Rezervasyon iptal edilirken bir hata oluştu.')
    }
  }

  const handleDeleteMember = async (m: MemberDetail) => {
    if (!confirm(`${m.ad} (${m.telefon || 'Telefon Yok'}) isimli üyeyi ve tüm geçmiş ders kayıtlarını veritabanından kalıcı olarak silmek istediğinizden emin misiniz?`)) return
    try {
      await admin.deleteMember(m.id)
      setSuccess(`${m.ad} isimli üye ve tüm geçmiş kayıtları veritabanından silindi.`)
      loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Üye silinirken bir hata oluştu.')
    }
  }

  const handleApproveMember = async (m: MemberDetail) => {
    try {
      await admin.approveMember(m.id)
      setSuccess(`${m.ad} üyeliği başarıyla onaylandı ve hesabı aktif edildi. ✨`)
      await loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Üyelik onaylanırken bir hata oluştu.')
    }
  }

  const handleRejectMember = async (m: MemberDetail) => {
    if (!confirm(`${m.ad} (${m.telefon || 'Telefon Yok'}) kullanıcısının üyelik başvurusunu reddetmek ve kaydını silmek istediğinize emin misiniz?`)) return
    try {
      await admin.rejectMember(m.id)
      setSuccess(`${m.ad} üyelik başvurusu reddedildi.`)
      await loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Üyelik başvurusu reddedilirken bir hata oluştu.')
    }
  }

  const pendingMembers = members.filter((m) => m.aktif === false)
  const activeMembers = members.filter((m) => m.aktif !== false)

  return (
    <div className="min-h-screen bg-ivory text-ink font-sans antialiased relative">
      <AdminNav />

      <main className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        {/* Header & Title */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1.5">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-sand text-espresso border border-line">
                <Users className="w-3.5 h-3.5 text-mocha" />
                <span>Yönetici Üye & Ölçü Konsolu</span>
              </span>
            </div>
            <h1 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
              {buyukHarf("Üye Yönetimi & Detaylı Vücut Ölçüleri")}
            </h1>
            <p className="text-sm text-secondary font-medium mt-1">
              Stüdyodaki tüm üyeleri listeleyin, bel, kalça, kol, bacak ölçülerini inceleyin veya özel paket tanımlayın.
            </p>
          </div>
        </div>

        {/* Global Success / Error Banners */}
        {success && (
          <div className="p-4 rounded-xl bg-sage/15 border border-sage/40 text-sage text-xs font-bold flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{success}</span>
          </div>
        )}
        {error && (
          <div className="p-4 rounded-xl bg-clay/15 border border-clay/40 text-clay text-xs font-bold flex items-center gap-2">
            <ShieldAlert className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Search Bar */}
        <Card className="border border-line bg-sand shadow-xs rounded-2xl p-4">
          <form onSubmit={handleSearch} className="flex gap-3">
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-secondary absolute left-3.5 top-3.5" />
              <Input
                type="text"
                placeholder="Üye adı, kullanıcı adı veya cep telefonu ile ara..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="bg-ivory border-line pl-10 h-11 text-xs font-medium rounded-xl"
              />
            </div>
            <button
              type="submit"
              className="px-5 py-2.5 rounded-xl text-xs font-extrabold bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs"
            >
              ARA
            </button>
          </form>
        </Card>

        {/* Onay Bekleyen Üyelik Başvuruları */}
        {pendingMembers.length > 0 && (
          <div className="p-6 rounded-2xl bg-amber-500/10 border-2 border-clay/40 space-y-4 shadow-sm">
            <div className="flex items-center gap-3">
              <span className="p-2.5 rounded-xl bg-clay/20 text-clay">
                <Clock className="w-5 h-5" />
              </span>
              <div>
                <h3 className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                  <span>Onay Bekleyen Üyelik Başvuruları</span>
                  <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-clay text-white">
                    {pendingMembers.length}
                  </span>
                </h3>
                <p className="text-xs text-secondary">
                  Yeni kaydolan kullanıcılar onayınızdan sonra stüdyo derslerini ve paketlerini görüntüleyebilir.
                </p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {pendingMembers.map((m) => (
                <div key={m.id} className="p-4 rounded-xl bg-white border border-line shadow-xs space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-ink text-sm">{m.ad}</span>
                    <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-900 border border-amber-300">
                      Onay Bekliyor
                    </span>
                  </div>
                  <div className="text-xs text-secondary space-y-0.5 font-mono">
                    {m.kullanici_adi && <div className="text-espresso font-bold">@{m.kullanici_adi}</div>}
                    <div>{m.telefon || 'Telefon Eklenmedi'}</div>
                  </div>
                  <div className="flex items-center gap-2 pt-1">
                    <button
                      onClick={() => handleApproveMember(m)}
                      className="flex-1 py-2 px-3 rounded-lg text-xs font-bold bg-sage text-white hover:bg-sage/90 transition-all flex items-center justify-center gap-1.5 cursor-pointer shadow-2xs"
                    >
                      <CheckCircle2 className="w-4 h-4" /> Üyeliği Onayla
                    </button>
                    <button
                      onClick={() => handleRejectMember(m)}
                      className="py-2 px-3 rounded-lg text-xs font-bold border border-red-300 text-red-700 hover:bg-red-50 transition-all flex items-center justify-center gap-1 cursor-pointer"
                    >
                      <XCircle className="w-4 h-4" /> Reddet
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Members Grid */}
        <div className="space-y-4">
          <h2 className="font-serif text-xl font-bold text-ink flex items-center gap-2">
            <Users className="w-5 h-5 text-espresso" />
            <span>Kayıtlı ve Aktif Üyeler ({activeMembers.length})</span>
          </h2>

          {loading ? (
            <div className="flex h-32 items-center justify-center rounded-2xl bg-sand border border-line">
              <Loader2 className="w-6 h-6 animate-spin text-espresso" />
            </div>
          ) : activeMembers.length === 0 ? (
            <div className="p-8 text-center bg-sand border border-line rounded-2xl text-xs text-secondary font-medium">
              Arama kriterlerine uygun aktif üye bulunamadı.
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {activeMembers.map((m) => (
                <Card key={m.id} className="border border-line bg-sand rounded-2xl overflow-hidden hover:border-espresso/40 transition-all shadow-xs">
                  <CardHeader className="pb-3 border-b border-line/60 bg-sand-light/50">
                    <div className="flex items-center justify-between">
                      <span className="font-serif text-lg font-bold text-ink">{m.ad}</span>
                      {m.is_admin ? (
                        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-espresso text-ivory">
                          Yönetici
                        </span>
                      ) : (
                        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-sage/20 text-sage border border-sage/40">
                          Aktif Üye
                        </span>
                      )}
                    </div>
                    <div className="space-y-0.5 mt-1">
                      {m.kullanici_adi && (
                        <div className="flex items-center gap-1 text-xs text-espresso font-bold">
                          <AtSign className="w-3 h-3 text-mocha" />
                          <span>{m.kullanici_adi}</span>
                        </div>
                      )}
                      {m.telefon ? (
                        <div className="flex items-center gap-1 text-xs text-secondary font-mono">
                          <Phone className="w-3 h-3 text-mocha" />
                          <span>{m.telefon}</span>
                        </div>
                      ) : (
                        <span className="text-[11px] text-muted italic block">Telefon Eklenmedi</span>
                      )}
                    </div>
                  </CardHeader>

                  <CardContent className="pt-4 space-y-3.5 text-xs font-medium">
                    {/* Tanımlı Aktif Paketler Rozeti */}
                    <div className="p-3 rounded-xl bg-sand-light border border-espresso/30 space-y-2 text-[11px] shadow-2xs">
                      <div className="flex items-center justify-between text-secondary font-bold border-b border-line/50 pb-1">
                        <span className="flex items-center gap-1 text-espresso font-extrabold">
                          <Package className="w-3.5 h-3.5 text-mocha" /> Tanımlı Aktif Paketler
                        </span>
                        {m.aktif_paketler && m.aktif_paketler.length > 0 ? (
                          <span className="text-[10px] text-sage font-bold bg-sage/15 px-2 py-0.5 rounded-full border border-sage/40">
                            {m.aktif_paketler.length} Aktif Paket
                          </span>
                        ) : m.aktif_paket_adi ? (
                          <span className="text-[10px] text-sage font-bold bg-sage/15 px-2 py-0.5 rounded-full border border-sage/40">
                            {m.kalan_gun_sayisi} Gün Kaldı
                          </span>
                        ) : (
                          <span className="text-[10px] text-clay font-bold bg-clay/15 px-2 py-0.5 rounded-full border border-clay/40">
                            Aktif Paket Yok
                          </span>
                        )}
                      </div>
                      <div className="space-y-1.5 pt-0.5">
                        {m.aktif_paketler && m.aktif_paketler.length > 0 ? (
                          m.aktif_paketler.map((pkg) => (
                            <div key={pkg.id} className="p-2.5 rounded-lg bg-white/80 border border-line/70 flex items-center justify-between gap-2 shadow-2xs">
                              <div className="space-y-0.5 min-w-0">
                                <div className="font-bold text-ink text-xs flex items-center gap-1.5 truncate">
                                  <CheckCircle2 className="w-3.5 h-3.5 text-sage shrink-0" />
                                  <span className="truncate">{pkg.ad}</span>
                                  <span className="text-[10px] text-mocha font-extrabold shrink-0">({pkg.toplam_ders} Derslik Paket)</span>
                                </div>
                                <div className="text-[10px] text-secondary font-medium pl-5 flex flex-wrap items-center gap-x-2 gap-y-0.5">
                                  {pkg.baslangic_tarihi && <span>Başlangıç: {pkg.baslangic_tarihi}</span>}
                                  <span>Bitiş: {pkg.bitis_tarihi}</span>
                                  <span className="text-sage font-bold">({pkg.kalan_gun} Gün Kaldı)</span>
                                </div>
                              </div>
                              <div className="flex items-center gap-1.5 shrink-0">
                                <button
                                  type="button"
                                  onClick={() => openEditPackageModal(m, pkg)}
                                  className="px-2 py-1 rounded-md text-[10px] font-extrabold text-espresso hover:bg-espresso/10 border border-espresso/30 transition-all flex items-center gap-1 cursor-pointer shadow-2xs"
                                  title="Paketi uzat, kalan ders veya sabit saatleri düzenle"
                                >
                                  <Clock className="w-3 h-3 text-mocha" />
                                  <span>Uzat/Düzenle</span>
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleCancelPackage(m.id, pkg.id, pkg.ad, m.ad)}
                                  className="px-2 py-1 rounded-md text-[10px] font-extrabold text-clay hover:bg-clay/10 border border-clay/30 transition-all flex items-center gap-1 cursor-pointer shrink-0 shadow-2xs"
                                  title="Bu paketi iptal et"
                                >
                                  <Trash2 className="w-3 h-3 text-clay" />
                                  <span>İptal</span>
                                </button>
                              </div>
                            </div>
                          ))
                        ) : m.aktif_paket_adi ? (
                          <div className="flex items-center justify-between gap-2 pt-0.5">
                            <div className="space-y-0.5">
                              <div className="font-bold text-ink text-xs flex items-center gap-1.5">
                                <CheckCircle2 className="w-3.5 h-3.5 text-sage shrink-0" />
                                <span>{m.aktif_paket_adi}</span>
                              </div>
                              <div className="text-[10px] text-mocha font-semibold pl-5 flex flex-wrap items-center gap-x-2">
                                {m.paket_baslangic_tarihi && <span>Başlangıç: {m.paket_baslangic_tarihi}</span>}
                                <span>Bitiş: {m.paket_bitis_tarihi}</span>
                              </div>
                            </div>
                            {m.aktif_member_package_id && (
                              <div className="flex items-center gap-1.5 shrink-0">
                                <button
                                  type="button"
                                  onClick={() => openEditPackageModal(m, { 
                                    id: m.aktif_member_package_id, 
                                    ad: m.aktif_paket_adi, 
                                    baslangic_tarihi: m.paket_baslangic_tarihi,
                                    bitis_tarihi: m.paket_bitis_tarihi, 
                                    toplam_ders: m.bakiye 
                                  })}
                                  className="px-2 py-1 rounded-md text-[10px] font-extrabold text-espresso hover:bg-espresso/10 border border-espresso/30 transition-all flex items-center gap-1 cursor-pointer shadow-2xs"
                                  title="Paketi uzat, kalan ders veya sabit saatleri düzenle"
                                >
                                  <Clock className="w-3 h-3 text-mocha" />
                                  <span>Uzat/Düzenle</span>
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleCancelPackage(m.id, m.aktif_member_package_id!, m.aktif_paket_adi!, m.ad)}
                                  className="px-2.5 py-1 rounded-lg text-[10px] font-extrabold text-clay hover:bg-clay/10 border border-clay/30 transition-all flex items-center gap-1 cursor-pointer shrink-0 shadow-2xs"
                                  title="Bu aktif paketi iptal et"
                                >
                                  <Trash2 className="w-3 h-3 text-clay" />
                                  <span>İptal</span>
                                </button>
                              </div>
                            )}
                          </div>
                        ) : (
                          <span className="text-muted italic text-[11px] block">Henüz aktif paket tanımlanmamış.</span>
                        )}
                      </div>
                    </div>

                    {/* Sabit Ders Saatleri Rozeti */}
                    {m.sabit_ders_saatleri ? (
                      <div className="p-2.5 rounded-xl bg-sage/15 border border-sage/40 flex items-center justify-between text-xs">
                        <div className="flex items-center gap-1.5 text-sage font-extrabold truncate">
                          <Clock className="w-3.5 h-3.5 shrink-0 text-sage" />
                          <span className="truncate">Sabit Saatler: {m.sabit_ders_saatleri}</span>
                        </div>
                        <button
                          type="button"
                          onClick={() => openEditModal(m)}
                          className="text-[10px] font-bold text-sage underline hover:text-espresso shrink-0 cursor-pointer ml-1"
                        >
                          Düzenle
                        </button>
                      </div>
                    ) : (
                      <button
                        type="button"
                        onClick={() => openEditModal(m)}
                        className="p-2 rounded-xl bg-ivory border border-dashed border-line hover:border-espresso text-secondary hover:text-espresso text-[11px] font-medium flex items-center justify-center gap-1.5 transition-all cursor-pointer w-full text-center"
                      >
                        <Clock className="w-3.5 h-3.5 text-secondary" />
                        <span>+ Sabit Ders Saati Tanımla (Salı 11:30 vb.)</span>
                      </button>
                    )}

                    {/* Ders Bakiye ve Rezervasyon Özeti */}
                    {(() => {
                      const rezerveCount = m.rezerve_ders_detaylari?.length ?? m.aktif_rezervasyonlar?.length ?? 0
                      const toplamBakiye = m.bakiye + rezerveCount
                      return (
                        <div className="p-3 rounded-xl bg-ivory border border-line space-y-2">
                          <div className="flex items-center justify-between">
                            <span className="text-secondary font-bold text-xs">Paket Ders Durumu:</span>
                            <span className="font-serif text-base font-bold text-espresso">
                              {toplamBakiye} Derslik Bakiye
                            </span>
                          </div>
                          <div className="grid grid-cols-2 gap-2 pt-1 border-t border-line/60">
                            <div className="p-2 rounded-lg bg-white/90 border border-line/50">
                              <span className="text-[10px] text-secondary font-semibold block">Rezerveye Açık (Boş)</span>
                              <span className="text-sm font-bold text-forest">{m.bakiye} Ders</span>
                            </div>
                            <div className="p-2 rounded-lg bg-white/90 border border-line/50">
                              <span className="text-[10px] text-secondary font-semibold block">Rezerve Edilmiş</span>
                              <span className="text-sm font-bold text-mocha">{rezerveCount} Ders</span>
                            </div>
                          </div>
                          {rezerveCount > 0 && (
                            <p className="text-[10.5px] text-secondary italic leading-tight pt-0.5">
                              💡 Bilgi: Üye {rezerveCount} derse kaydedildiği için kontenjan tutulmuştur ({toplamBakiye} &rarr; {m.bakiye}). Derse geldiğinde tekrar ders düşülmez.
                            </p>
                          )}
                        </div>
                      )
                    })()}

                    {/* Rezerve Ettiği Dersler Rozeti */}
                    <div className="p-3 rounded-xl bg-sand-light border border-sage/30 space-y-1.5 text-[11px] shadow-2xs">
                      <div className="flex items-center justify-between text-secondary font-bold border-b border-line/50 pb-1">
                        <span className="flex items-center gap-1 text-espresso font-extrabold">
                          <CheckCircle2 className="w-3.5 h-3.5 text-sage" /> Rezerve Dersleri ({m.rezerve_ders_detaylari?.length ?? m.aktif_rezervasyonlar?.length ?? 0})
                        </span>
                        <button
                          type="button"
                          onClick={() => openBookSessionModal(m)}
                          className="px-2 py-0.5 rounded-md text-[10px] font-extrabold bg-espresso text-ivory hover:bg-espresso/80 transition-all flex items-center gap-1 cursor-pointer shadow-2xs"
                          title="Üyeyi doğrudan bir seansa kaydet"
                        >
                          <Plus className="w-3 h-3" />
                          <span>+ Derse Kaydet</span>
                        </button>
                      </div>
                      {m.rezerve_ders_detaylari && m.rezerve_ders_detaylari.length > 0 ? (
                        <div className="space-y-1.5 pt-1">
                          {m.rezerve_ders_detaylari.map((rd) => (
                            <div key={rd.booking_id} className="p-1.5 rounded-lg bg-white/90 border border-line/60 flex items-center justify-between gap-1.5 shadow-2xs">
                              <div className="flex items-center gap-1.5 truncate">
                                <span className="w-1.5 h-1.5 rounded-full bg-sage shrink-0" />
                                <span className="font-bold text-ink text-[11px] truncate">
                                  {rd.ders_adi} · {rd.tarih_saat} {rd.egitmen ? `(${rd.egitmen})` : ''}
                                </span>
                              </div>
                              <button
                                type="button"
                                onClick={() => handleCancelReservation(rd.booking_id, m.ad, `${rd.ders_adi} (${rd.tarih_saat})`)}
                                className="px-2 py-0.5 rounded text-[10px] font-bold text-clay hover:bg-clay/10 border border-clay/30 transition-all shrink-0 cursor-pointer"
                                title="Bu rezervasyonu iptal et ve ders hakkını iade et"
                              >
                                İptal Et
                              </button>
                            </div>
                          ))}
                        </div>
                      ) : m.aktif_rezervasyonlar && m.aktif_rezervasyonlar.length > 0 ? (
                        <div className="space-y-1 pt-1">
                          {m.aktif_rezervasyonlar.map((ders, idx) => (
                            <div key={idx} className="font-bold text-ink text-[11px] flex items-center gap-1.5">
                              <span className="w-1.5 h-1.5 rounded-full bg-sage shrink-0" />
                              <span>{ders}</span>
                            </div>
                          ))}
                        </div>
                      ) : (
                        <span className="text-muted italic text-[10px] block pt-0.5">Rezerve edilmiş aktif ders bulunmuyor.</span>
                      )}
                    </div>

                    {/* Vücut Ölçüleri Özet Rozeti */}
                    <div className="p-3 rounded-xl bg-ivory/60 border border-line space-y-1 text-[11px]">
                      <div className="flex items-center justify-between text-secondary font-bold border-b border-line/50 pb-1">
                        <span className="flex items-center gap-1 text-espresso">
                          <Ruler className="w-3 h-3" /> Ölçü Özeti
                        </span>
                        <span className="text-[10px] text-mocha font-semibold">
                          {m.kilo ? `${m.kilo} kg` : ''} {m.boy ? `• ${m.boy} cm` : ''}
                        </span>
                      </div>
                      <div className="grid grid-cols-2 gap-x-2 gap-y-0.5 text-secondary font-medium pt-1">
                        <span>Bel: <strong className="text-ink">{m.bel || '-'}</strong></span>
                        <span>Kalça: <strong className="text-ink">{m.kalca || '-'}</strong></span>
                        <span>Sağ Bacak: <strong className="text-ink">{m.sag_bacak || '-'}</strong></span>
                        <span>Sol Bacak: <strong className="text-ink">{m.sol_bacak || '-'}</strong></span>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="grid grid-cols-4 gap-1.5 pt-1">
                      <button
                        onClick={() => openEditModal(m)}
                        className="p-1.5 rounded-xl bg-ivory border border-line hover:border-espresso text-ink hover:text-espresso text-[10px] font-bold flex flex-col items-center gap-1 transition-all cursor-pointer"
                        title="Tüm Bilgileri Gör / Düzenle"
                      >
                        <Edit2 className="w-3.5 h-3.5 text-mocha" />
                        <span className="truncate w-full text-center">Ölçü/Müdahale</span>
                      </button>

                      <button
                        onClick={() => openAssignModal(m)}
                        className="p-1.5 rounded-xl bg-ivory border border-line hover:border-espresso text-ink hover:text-espresso text-[10px] font-bold flex flex-col items-center gap-1 transition-all cursor-pointer"
                        title="Paket Tanımla"
                      >
                        <CreditCard className="w-3.5 h-3.5 text-mocha" />
                        <span className="truncate w-full text-center">+ Paket</span>
                      </button>

                      <button
                        onClick={() => {
                          setNotifMember(m)
                          setNotifTitle('Sobo Society Duyuru')
                          setNotifBody('')
                        }}
                        className="p-1.5 rounded-xl bg-ivory border border-line hover:border-espresso text-ink hover:text-espresso text-[10px] font-bold flex flex-col items-center gap-1 transition-all cursor-pointer"
                        title="Özel Bildirim Gönder"
                      >
                        <Send className="w-3.5 h-3.5 text-mocha" />
                        <span className="truncate w-full text-center">Bildirim</span>
                      </button>

                      <button
                        onClick={() => handleDeleteMember(m)}
                        className="p-1.5 rounded-xl bg-clay/10 border border-clay/30 hover:bg-clay text-clay hover:text-white text-[10px] font-bold flex flex-col items-center gap-1 transition-all cursor-pointer"
                        title="Üyeyi Veritabanından Sil"
                      >
                        <UserX className="w-3.5 h-3.5 text-clay hover:text-white" />
                        <span className="truncate w-full text-center">Üyeyi Sil</span>
                      </button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* Modal 1: Member Edit / Full Body Measurements & Credit Intervention */}
        {editingMember && (
          <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs overflow-y-auto p-4 sm:p-6 flex items-center justify-center min-h-screen">
            <Card className="max-w-lg w-full max-h-[90vh] flex flex-col my-auto bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150 overflow-hidden">
              <CardHeader className="border-b border-line pb-4 relative shrink-0">
                <button
                  type="button"
                  onClick={() => setEditingMember(null)}
                  className="absolute top-4 right-4 text-secondary hover:text-ink p-1 rounded-full hover:bg-sand cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
                <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                  <Ruler className="w-5 h-5 text-espresso" />
                  <span>Üye Detayları & Vücut Ölçüleri Müdahalesi</span>
                </CardTitle>
                <CardDescription className="text-xs text-secondary">
                  <strong>{editingMember.ad}</strong> üyesinin tüm ölçülerini, bakiyesini ve özel notlarını düzenleyin.
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-6 space-y-5 overflow-y-auto flex-1">
                <form onSubmit={handleUpdateMember} className="space-y-4">
                  {/* Üye Hesap Bilgileri Özeti */}
                  <div className="flex items-center justify-between p-3 rounded-xl bg-ivory border border-line text-xs">
                    <div>
                      <span className="text-[10px] uppercase font-bold text-secondary block">Kullanıcı Adı</span>
                      <span className="font-bold text-espresso">@{editingMember.kullanici_adi || 'Tanımsız'}</span>
                    </div>
                    <div className="text-right">
                      <span className="text-[10px] uppercase font-bold text-secondary block">Kayıtlı Telefon</span>
                      <span className="font-semibold text-ink">{editingMember.telefon || 'Kayıtsız'}</span>
                    </div>
                  </div>

                  {/* Temel Üye Bilgileri */}
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs font-bold text-secondary uppercase mb-1">Üye Adı Soyadı</label>
                      <Input
                        value={newName}
                        onChange={(e) => setNewName(e.target.value)}
                        className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                        required
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold text-secondary uppercase mb-1">Kalan Ders Bakiyesi</label>
                      <Input
                        type="number"
                        min={0}
                        max={999}
                        value={newBakiye}
                        onChange={(e) => setNewBakiye(Number(e.target.value))}
                        className="bg-ivory border-line text-lg font-bold text-espresso rounded-xl h-11"
                        required
                      />
                    </div>
                  </div>

                  {/* Vücut Ölçüleri Grid */}
                  <div className="p-4 rounded-xl bg-ivory/70 border border-line space-y-3">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-espresso flex items-center gap-1.5 border-b border-line pb-2">
                      <Ruler className="w-4 h-4 text-mocha" />
                      <span>Vücut Ölçüleri & Form Bilgileri</span>
                    </h4>

                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 pt-1">
                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Bel</label>
                        <Input
                          placeholder="Örn: 68 cm"
                          value={editBel}
                          onChange={(e) => setEditBel(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Kalça</label>
                        <Input
                          placeholder="Örn: 94 cm"
                          value={editKalca}
                          onChange={(e) => setEditKalca(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sağ İç Bacak</label>
                        <Input
                          placeholder="Örn: 52 cm"
                          value={editSagIcBacak}
                          onChange={(e) => setEditSagIcBacak(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sağ Bacak</label>
                        <Input
                          placeholder="Örn: 54 cm"
                          value={editSagBacak}
                          onChange={(e) => setEditSagBacak(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sol İç Bacak</label>
                        <Input
                          placeholder="Örn: 52 cm"
                          value={editSolIcBacak}
                          onChange={(e) => setEditSolIcBacak(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sol Bacak</label>
                        <Input
                          placeholder="Örn: 54 cm"
                          value={editSolBacak}
                          onChange={(e) => setEditSolBacak(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sağ Kol</label>
                        <Input
                          placeholder="Örn: 27 cm"
                          value={editSagKol}
                          onChange={(e) => setEditSagKol(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Sol Kol</label>
                        <Input
                          placeholder="Örn: 27 cm"
                          value={editSolKol}
                          onChange={(e) => setEditSolKol(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Boy</label>
                        <Input
                          placeholder="Örn: 168 cm"
                          value={editBoy}
                          onChange={(e) => setEditBoy(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-bold text-secondary uppercase mb-1">Kilo</label>
                        <Input
                          placeholder="Örn: 56 kg"
                          value={editKilo}
                          onChange={(e) => setEditKilo(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-9"
                        />
                      </div>
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">
                      Sağlık, Sakatlık veya Hedef Notları
                    </label>
                    <textarea
                      rows={3}
                      placeholder="Örn: Sol diz hassasiyeti var, hamstring esnetmesi önerilir."
                      value={editSaglikNotu}
                      onChange={(e) => setEditSaglikNotu(e.target.value)}
                      className="w-full bg-ivory border border-line text-xs font-medium rounded-xl p-3 focus:ring-2 focus:ring-espresso text-ink"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">
                      Haftalık Sabit Ders Günleri & Saatleri
                    </label>
                    <Input
                      placeholder="Örn: Salı 11:30, Perşembe 11:30"
                      value={editSabitDersSaatleri}
                      onChange={(e) => setEditSabitDersSaatleri(e.target.value)}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                    />
                    <p className="text-[11px] text-secondary mt-1">
                      Üyenin her hafta düzenli geleceği sabit gün ve saatler. Üye uygulamasında ve profilinde bunu görebilir.
                    </p>
                  </div>

                  {/* Şifre Sıfırlama / Yeni Şifre Ata */}
                  <div className="p-4 rounded-xl bg-ivory/80 border border-line space-y-2">
                    <div className="flex items-center gap-2">
                      <KeyRound className="w-4 h-4 text-espresso" />
                      <span className="text-xs font-bold text-espresso uppercase tracking-wider">Şifre Sıfırlama / Yeni Şifre Ata</span>
                    </div>
                    <p className="text-[11px] text-secondary">
                      Üye şifresini unuttuysa veya giriş yapamıyorsa buraya yeni bir şifre yazabilirsiniz (örn: 123456). Boş bırakılırsa mevcut şifresi değişmez.
                    </p>
                    <Input
                      type="text"
                      placeholder="Yeni şifre belirleyin (boş bırakılırsa değişmez)"
                      value={editPassword}
                      onChange={(e) => setEditPassword(e.target.value)}
                      className="bg-white border-line text-xs font-medium rounded-xl h-10"
                    />
                  </div>

                  <div className="flex justify-end gap-2 pt-2">
                    <button
                      type="button"
                      onClick={() => setEditingMember(null)}
                      className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                    >
                      İptal
                    </button>
                    <button
                      type="submit"
                      disabled={updating}
                      className="px-5 py-2.5 rounded-xl text-xs font-extrabold uppercase bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                    >
                      {updating && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                      <span>TÜM BİLGİLERİ KAYDET</span>
                    </button>
                  </div>
                </form>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Modal 2: Single Member Notification */}
        {notifMember && (
          <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs overflow-y-auto p-4 sm:p-6 flex items-center justify-center min-h-screen">
            <Card className="max-w-md w-full max-h-[90vh] flex flex-col my-auto bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150 overflow-hidden">
              <CardHeader className="border-b border-line pb-4 shrink-0">
                <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                  <Send className="w-4 h-4 text-espresso" />
                  <span>Üyeye Özel Bildirim Gönder</span>
                </CardTitle>
                <CardDescription className="text-xs text-secondary">
                  <strong>{notifMember.ad}</strong> üyesine doğrudan push bildirim ve duyuru iletin.
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-6 space-y-4 overflow-y-auto flex-1">
                <form onSubmit={handleSendSinglePush} className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Bildirim Başlığı</label>
                    <Input
                      value={notifTitle}
                      onChange={(e) => setNotifTitle(e.target.value)}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-11"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Mesaj İçeriği</label>
                    <textarea
                      rows={3}
                      value={notifBody}
                      onChange={(e) => setNotifBody(e.target.value)}
                      placeholder="Örn: Merhaba Sedat Bey, yarınki Barre dersiniz saat 10:00'da başlayacaktır."
                      className="w-full bg-ivory border border-line text-xs font-medium rounded-xl p-3 focus:ring-2 focus:ring-espresso text-ink"
                      required
                    />
                  </div>

                  <div className="flex justify-end gap-2 pt-2">
                    <button
                      type="button"
                      onClick={() => setNotifMember(null)}
                      className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                    >
                      İptal
                    </button>
                    <button
                      type="submit"
                      disabled={sendingNotif}
                      className="px-5 py-2.5 rounded-xl text-xs font-extrabold uppercase bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                    >
                      {sendingNotif && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                      <span>BİLDİRİMİ GÖNDER</span>
                    </button>
                  </div>
                </form>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Modal 3: Assign Custom / Standard Package */}
        {pkgMember && (
          <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs overflow-y-auto p-4 sm:p-6 flex items-center justify-center min-h-screen">
            <Card className="max-w-md w-full max-h-[90vh] flex flex-col my-auto bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150 overflow-hidden">
              <CardHeader className="border-b border-line pb-4 shrink-0">
                <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                  <CreditCard className="w-4 h-4 text-espresso" />
                  <span>Üyeye Paket Tanımla</span>
                </CardTitle>
                <CardDescription className="text-xs text-secondary">
                  <strong>{pkgMember.ad}</strong> üyesi için hazır veya kişiye özel paket tanımlayın.
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-6 space-y-4 overflow-y-auto flex-1">
                <form onSubmit={handleAssignPackage} className="space-y-4">
                  {/* Paket Tipi Seçimi (Hazır / Özel) */}
                  <div className="flex rounded-xl bg-ivory p-1 border border-line">
                    <button
                      type="button"
                      onClick={() => setIsCustomPkg(false)}
                      className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all cursor-pointer ${
                        !isCustomPkg ? 'bg-espresso text-ivory shadow-xs' : 'text-secondary hover:text-ink'
                      }`}
                    >
                      Hazır Şablon Paketler
                    </button>
                    <button
                      type="button"
                      onClick={() => setIsCustomPkg(true)}
                      className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all flex items-center justify-center gap-1 cursor-pointer ${
                        isCustomPkg ? 'bg-espresso text-ivory shadow-xs' : 'text-secondary hover:text-ink'
                      }`}
                    >
                      <Sparkles className="w-3.5 h-3.5 text-mocha" />
                      <span>Özel Paket Oluştur</span>
                    </button>
                  </div>

                  {!isCustomPkg ? (
                    <div>
                      <label className="block text-xs font-bold text-secondary uppercase mb-1">Hazır Paket Seçimi</label>
                      <select
                        value={selectedPkgId}
                        onChange={(e) => {
                          const newId = Number(e.target.value)
                          setSelectedPkgId(newId)
                          const pkg = availablePackages.find((p) => p.id === newId)
                          if (pkg && pkgBaslangic) {
                            setPkgBitis(addDaysToDate(pkgBaslangic, pkg.gecerlilik_gun))
                          }
                        }}
                        className="w-full bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium focus:ring-2 focus:ring-espresso"
                      >
                        {availablePackages.length > 0 ? (
                          availablePackages.map((p) => (
                            <option key={p.id} value={p.id}>
                              {p.ad} ({p.ders_adedi} Ders / {p.gecerlilik_gun} Gün)
                            </option>
                          ))
                        ) : (
                          <>
                            <option value={9}>Barre Class - 1 Ders (1 Ders / 7 Gün)</option>
                            <option value={10}>Barre Class (4 Ders/4 Hafta) (4 Ders / 28 Gün)</option>
                            <option value={11}>Barre Class (8 Ders / 6 Hafta) (8 Ders / 42 Gün)</option>
                            <option value={12}>Barre Class (12 Ders / 8 Hafta) (12 Ders / 56 Gün)</option>
                            <option value={13}>Yoga Class - 1 Ders (1 Ders / 7 Gün)</option>
                            <option value={14}>Yoga Class 4 Ders / 5 Hafta (4 Ders / 35 Gün)</option>
                            <option value={15}>Barre - Bireysel Mini (8 Ders / 42 Gün)</option>
                            <option value={16}>Barre - Bireysel Standart (12 Ders / 56 Gün)</option>
                            <option value={17}>Reformer Pilates - Bireysel Mini (8 Ders / 42 Gün)</option>
                            <option value={18}>Reformer Pilates - Bireysel Standart (12 Ders / 56 Gün)</option>
                          </>
                        )}
                      </select>
                    </div>
                  ) : (
                    <div className="space-y-3.5 p-3.5 rounded-xl bg-ivory/60 border border-line">
                      <div>
                        <label className="block text-xs font-bold text-secondary uppercase mb-1">Özel Paket Adı</label>
                        <Input
                          type="text"
                          placeholder="Örn: Sedat Bey Özel VIP Paket veya Yaz Fırsatı"
                          value={customPkgName}
                          onChange={(e) => setCustomPkgName(e.target.value)}
                          className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                          required
                        />
                      </div>

                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <label className="block text-xs font-bold text-secondary uppercase mb-1">Ders Hak Sayısı</label>
                          <Input
                            type="number"
                            min={1}
                            max={500}
                            value={customCredits}
                            onChange={(e) => setCustomCredits(Number(e.target.value))}
                            className="bg-ivory border-line text-sm font-bold text-espresso rounded-xl h-10"
                            required
                          />
                        </div>

                        <div>
                          <div className="flex items-center justify-between mb-1">
                            <label className="block text-xs font-bold text-secondary uppercase">Geçerlilik</label>
                            <div className="flex items-center gap-1 bg-ivory p-0.5 rounded-lg border border-line">
                              <button
                                type="button"
                                onClick={() => {
                                  setCustomUnit('hafta')
                                  setCustomVal(6)
                                  if (pkgBaslangic) setPkgBitis(addDaysToDate(pkgBaslangic, 42))
                                }}
                                className={`px-2 py-0.5 text-[10px] font-extrabold rounded cursor-pointer transition-all ${customUnit === 'hafta' ? 'bg-espresso text-ivory shadow-xs' : 'text-secondary hover:text-ink'}`}
                              >
                                Hafta
                              </button>
                              <button
                                type="button"
                                onClick={() => {
                                  setCustomUnit('gun')
                                  setCustomVal(42)
                                  if (pkgBaslangic) setPkgBitis(addDaysToDate(pkgBaslangic, 42))
                                }}
                                className={`px-2 py-0.5 text-[10px] font-extrabold rounded cursor-pointer transition-all ${customUnit === 'gun' ? 'bg-espresso text-ivory shadow-xs' : 'text-secondary hover:text-ink'}`}
                              >
                                Gün
                              </button>
                            </div>
                          </div>
                          <Input
                            type="number"
                            min={1}
                            max={52}
                            value={customVal}
                            onChange={(e) => {
                              const val = Number(e.target.value)
                              setCustomVal(val)
                              const days = customUnit === 'hafta' ? val * 7 : val
                              if (pkgBaslangic) {
                                setPkgBitis(addDaysToDate(pkgBaslangic, days))
                              }
                            }}
                            className="bg-ivory border-line text-sm font-bold text-espresso rounded-xl h-10"
                            required
                          />
                          <span className="text-[10px] font-extrabold text-espresso mt-1 block">
                            (= {customUnit === 'hafta' ? customVal * 7 : customVal} Gün)
                          </span>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Paket Başlangıç & Bitiş Tarihleri */}
                  <div className="grid grid-cols-2 gap-3 p-3.5 rounded-xl bg-ivory border border-line">
                    <div>
                      <label className="block text-xs font-bold text-secondary uppercase mb-1">
                        Başlangıç Tarihi
                      </label>
                      <Input
                        type="date"
                        value={pkgBaslangic}
                        onChange={(e) => {
                          const newStart = e.target.value
                          setPkgBaslangic(newStart)
                          const days = isCustomPkg
                            ? (customUnit === 'hafta' ? customVal * 7 : customVal)
                            : (availablePackages.find((p) => p.id === selectedPkgId)?.gecerlilik_gun || 42)
                          if (newStart) {
                            setPkgBitis(addDaysToDate(newStart, days))
                          }
                        }}
                        className="bg-sand border-line text-xs font-medium rounded-xl h-10"
                        required
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-secondary uppercase mb-1">
                        Bitiş Tarihi
                      </label>
                      <Input
                        type="date"
                        value={pkgBitis}
                        onChange={(e) => setPkgBitis(e.target.value)}
                        className="bg-sand border-line text-xs font-medium rounded-xl h-10"
                        required
                      />
                    </div>
                    <p className="col-span-2 text-[11px] text-mocha font-medium">
                      💡 Başlangıç ve bitiş tarihlerini geçmişe veya ileriye dönük dilediğiniz gibi ayarlayabilirsiniz. Bitiş tarihi otomatik hesaplanır, isterseniz serbestçe değiştirebilirsiniz.
                    </p>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">
                      Haftalık Sabit Ders Gün & Saatleri
                    </label>
                    <Input
                      type="text"
                      placeholder="Örn: Salı 11:30, Perşembe 11:30"
                      value={pkgSabitDersSaatleri}
                      onChange={(e) => setPkgSabitDersSaatleri(e.target.value)}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                    />
                    <p className="text-[11px] text-secondary mt-1">
                      Üyenin her hafta düzenli katılacağı sabit ders saatleri.
                    </p>
                  </div>

                  <div className="flex justify-end gap-2 pt-2">
                    <button
                      type="button"
                      onClick={() => setPkgMember(null)}
                      className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                    >
                      İptal
                    </button>
                    <button
                      type="submit"
                      disabled={assigningPkg}
                      className="px-5 py-2.5 rounded-xl text-xs font-extrabold uppercase bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                    >
                      {assigningPkg && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                      <span>PAKETİ TANIMLA</span>
                    </button>
                  </div>
                </form>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Modal 4: Edit Member Package & Fixed Hours */}
        {editingPkgMember && editingPkg && (
          <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs overflow-y-auto p-4 sm:p-6 flex items-center justify-center min-h-screen">
            <Card className="max-w-md w-full my-auto bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150 overflow-hidden">
              <CardHeader className="border-b border-line pb-4 shrink-0">
                <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                  <Clock className="w-4 h-4 text-espresso" />
                  <span>Paket & Ders Düzenle</span>
                </CardTitle>
                <CardDescription className="text-xs text-secondary">
                  <strong>{editingPkgMember.ad}</strong> • {editingPkg.ad || 'Ders Paketi'}
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-6 space-y-4">
                <form onSubmit={handleUpdatePackage} className="space-y-4">
                  <div className="grid grid-cols-2 gap-3 p-3 rounded-xl bg-ivory border border-line">
                    <div>
                      <label className="block text-xs font-bold text-secondary uppercase mb-1">Başlangıç Tarihi</label>
                      <Input
                        type="date"
                        value={pkgEditBaslangic}
                        onChange={(e) => setPkgEditBaslangic(e.target.value)}
                        className="bg-sand border-line text-xs font-medium rounded-xl h-10"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-secondary uppercase mb-1">Bitiş Tarihi</label>
                      <Input
                        type="date"
                        value={pkgEditBitis}
                        onChange={(e) => {
                          setPkgEditBitis(e.target.value)
                          setPkgEditEkGun(null)
                        }}
                        className="bg-sand border-line text-xs font-medium rounded-xl h-10"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Kalan Ders Sayısı</label>
                    <Input
                      type="number"
                      min={0}
                      max={500}
                      value={pkgEditKalanDers}
                      onChange={(e) => setPkgEditKalanDers(Number(e.target.value))}
                      className="bg-ivory border-line text-sm font-bold text-espresso rounded-xl h-10"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">
                      Haftalık Sabit Ders Günleri & Saatleri
                    </label>
                    <Input
                      type="text"
                      placeholder="Örn: Salı 11:30, Perşembe 11:30"
                      value={pkgEditSabitDers}
                      onChange={(e) => setPkgEditSabitDers(e.target.value)}
                      className="bg-ivory border-line text-xs font-medium rounded-xl h-10"
                    />
                    <p className="text-[11px] text-secondary mt-1">
                      Üyenin her hafta düzenli katılacağı sabit gün ve saatler.
                    </p>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Hızlı Bitiş Uzatma (+ Gün)</label>
                    <div className="flex flex-wrap gap-2">
                      {[7, 14, 30, 45, 60].map((days) => (
                        <button
                          key={days}
                          type="button"
                          onClick={() => {
                            const base = pkgEditBitis ? new Date(pkgEditBitis) : new Date()
                            base.setDate(base.getDate() + days)
                            setPkgEditBitis(formatDateToInput(base))
                            setPkgEditEkGun(null)
                          }}
                          className="px-3 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer bg-ivory text-espresso border border-line hover:border-espresso hover:bg-espresso hover:text-ivory"
                        >
                          +{days} Gün Ekle
                        </button>
                      ))}
                    </div>
                  </div>

                  <div className="flex justify-end gap-2 pt-2">
                    <button
                      type="button"
                      onClick={() => {
                        setEditingPkgMember(null)
                        setEditingPkg(null)
                      }}
                      className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                    >
                      İptal
                    </button>
                    <button
                      type="submit"
                      disabled={updatingPkg}
                      className="px-5 py-2.5 rounded-xl text-xs font-extrabold uppercase bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                    >
                      {updatingPkg && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                      <span>DEĞİŞİKLİKLERİ KAYDET</span>
                    </button>
                  </div>
                </form>
              </CardContent>
            </Card>
          </div>
        )}
        {/* Modal: Book Member into Session */}
        {bookingMember && (
          <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs overflow-y-auto p-4 sm:p-6 flex items-center justify-center min-h-screen">
            <Card className="max-w-lg w-full max-h-[90vh] flex flex-col my-auto bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150 overflow-hidden">
              <CardHeader className="border-b border-line pb-4 relative shrink-0">
                <button
                  type="button"
                  onClick={() => setBookingMember(null)}
                  className="absolute top-4 right-4 text-secondary hover:text-ink p-1 rounded-full hover:bg-sand cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
                <CardTitle className="font-serif text-xl font-bold text-ink flex items-center gap-2">
                  <Calendar className="w-5 h-5 text-espresso" />
                  <span>Üyeyi Derse Kaydet</span>
                </CardTitle>
                <CardDescription className="text-xs text-secondary mt-1">
                  <strong>{bookingMember.ad}</strong> üyesini stüdyo ders programındaki açık bir seansa kaydedin. Kayıt yapıldığında üyenin kalan hakkından 1 ders düşülür ve üyeye anında push bildirim iletilir.
                </CardDescription>
              </CardHeader>

              <CardContent className="pt-5 overflow-y-auto flex-1 space-y-4">
                <div className="p-3 bg-ivory rounded-xl border border-line flex items-center justify-between">
                  <span className="text-xs font-semibold text-secondary">Mevcut Bakiye:</span>
                  <span className="font-serif text-base font-bold text-espresso">{bookingMember.bakiye} Ders</span>
                </div>

                {loadingSessions ? (
                  <div className="py-12 flex flex-col items-center justify-center gap-2 text-secondary text-xs">
                    <Loader2 className="w-6 h-6 animate-spin text-espresso" />
                    <span>Ders seansları yükleniyor...</span>
                  </div>
                ) : sessionsList.length === 0 ? (
                  <div className="py-8 text-center text-secondary text-xs bg-ivory rounded-xl border border-line">
                    Yaklaşan uygun ders oturumu bulunamadı. Lütfen önce Takvim sayfasından ders ekleyin.
                  </div>
                ) : (
                  <form onSubmit={handleBookSessionForMember} className="space-y-4">
                    <div className="space-y-1.5">
                      <label className="text-xs font-bold text-espresso block">
                        Kayıt Edilecek Ders Seansı Seçin:
                      </label>
                      <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
                        {sessionsList.map((s) => {
                          const dateObj = new Date(s.baslangic)
                          const isFull = s.dolu_sayi >= (s.kontenjan || 5)
                          const dateStr = dateObj.toLocaleDateString('tr-TR', {
                            weekday: 'short',
                            day: 'numeric',
                            month: 'short',
                            hour: '2-digit',
                            minute: '2-digit',
                          })
                          const isSelected = selectedSessionId === s.id
                          return (
                            <div
                              key={s.id}
                              onClick={() => setSelectedSessionId(s.id)}
                              className={`p-3 rounded-xl border cursor-pointer transition-all flex items-center justify-between ${
                                isSelected
                                  ? 'bg-espresso text-ivory border-espresso shadow-xs'
                                  : 'bg-ivory border-line hover:border-mocha text-ink'
                              }`}
                            >
                              <div className="min-w-0 pr-2">
                                <div className={`font-bold text-xs ${isSelected ? 'text-ivory' : 'text-ink'}`}>
                                  {s.class_type?.ad || 'Ders'}
                                </div>
                                <div className={`text-[11px] mt-0.5 ${isSelected ? 'text-ivory/80' : 'text-secondary'}`}>
                                  🗓 {dateStr}
                                </div>
                                {s.instructor && (
                                  <div className={`text-[10px] mt-0.5 ${isSelected ? 'text-ivory/70' : 'text-mocha'}`}>
                                    Eğitmen: {s.instructor.ad}
                                  </div>
                                )}
                              </div>
                              <div className="text-right shrink-0">
                                <span
                                  className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                                    isFull
                                      ? 'bg-clay/20 text-clay'
                                      : isSelected
                                      ? 'bg-ivory/20 text-ivory'
                                      : 'bg-sage/15 text-sage'
                                  }`}
                                >
                                  {s.dolu_sayi} / {s.kontenjan || 5} Kişi
                                </span>
                              </div>
                            </div>
                          )
                        })}
                      </div>
                    </div>

                    <div className="flex justify-end gap-2 pt-2 border-t border-line">
                      <button
                        type="button"
                        onClick={() => setBookingMember(null)}
                        className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                      >
                        Vazgeç
                      </button>
                      <button
                        type="submit"
                        disabled={bookingLoading || !selectedSessionId}
                        className="px-5 py-2.5 rounded-xl text-xs font-extrabold uppercase bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                      >
                        {bookingLoading && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                        <span>SEANSA KAYDET</span>
                      </button>
                    </div>
                  </form>
                )}
              </CardContent>
            </Card>
          </div>
        )}
      </main>
    </div>
  )
}
