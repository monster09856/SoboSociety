'use client'

import React, { useState, useEffect } from 'react'
import { admin } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { AdminNav } from '@/components/admin/admin-nav'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Users, Search, Plus, CreditCard, Send, Edit2, ShieldAlert, CheckCircle2, Loader2, Sparkles, UserCheck } from 'lucide-react'

interface MemberDetail {
  id: number
  ad: string
  telefon: string
  bakiye: number
  aktif: boolean
  is_admin: boolean
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
  const [updating, setUpdating] = useState(false)

  // Single Push Notification Modal State
  const [notifMember, setNotifMember] = useState<MemberDetail | null>(null)
  const [notifTitle, setNotifTitle] = useState('')
  const [notifBody, setNotifBody] = useState('')
  const [sendingNotif, setSendingNotif] = useState(false)

  // Assign Package Modal State
  const [pkgMember, setPkgMember] = useState<MemberDetail | null>(null)
  const [selectedPkgId, setSelectedPkgId] = useState<number>(1)
  const [assigningPkg, setAssigningPkg] = useState(false)

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

  useEffect(() => {
    loadMembers()
  }, [])

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    loadMembers(search)
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
      })
      setSuccess(`${newName} üyesinin bilgileri ve bakiyesi güncellendi.`)
      setEditingMember(null)
      loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Üye güncellenirken bir hata oluştu.')
    } finally {
      setUpdating(false)
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
      await admin.assignPackage({
        member_id: pkgMember.id,
        package_id: selectedPkgId,
      })
      setSuccess(`${pkgMember.ad} üyesine yeni ders paketi tanımlandı.`)
      setPkgMember(null)
      loadMembers(search)
    } catch (err: any) {
      setError(err?.message || 'Paket tanımlanırken hata oluştu.')
    } finally {
      setAssigningPkg(false)
    }
  }

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
                <span>Yönetici Üye & Bakiye Konsolu</span>
              </span>
            </div>
            <h1 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
              {buyukHarf("Üye Yönetimi & Bakiye Müdahale")}
            </h1>
            <p className="text-sm text-secondary font-medium mt-1">
              Stüdyodaki tüm üyeleri listeleyin, bakiyelerine doğrudan müdahale edin veya üyeye özel duyuru gönderin.
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
                placeholder="Üye adı veya cep telefonu numarası ile ara..."
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

        {/* Members Grid */}
        <div className="space-y-4">
          <h2 className="font-serif text-xl font-bold text-ink flex items-center gap-2">
            <Users className="w-5 h-5 text-espresso" />
            <span>Kayıtlı Üyeler ({members.length})</span>
          </h2>

          {loading ? (
            <div className="flex h-32 items-center justify-center rounded-2xl bg-sand border border-line">
              <Loader2 className="w-6 h-6 animate-spin text-espresso" />
            </div>
          ) : members.length === 0 ? (
            <div className="p-8 text-center bg-sand border border-line rounded-2xl text-xs text-secondary font-medium">
              Arama kriterlerine uygun üye bulunamadı.
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {members.map((m) => (
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
                    <CardDescription className="text-xs text-secondary font-mono">
                      {m.telefon}
                    </CardDescription>
                  </CardHeader>

                  <CardContent className="pt-4 space-y-4 text-xs font-medium">
                    <div className="flex items-center justify-between p-3 rounded-xl bg-ivory border border-line">
                      <span className="text-secondary font-semibold">Kalan Ders Bakiyesi:</span>
                      <span className="font-serif text-xl font-bold text-espresso">{m.bakiye} Kredi</span>
                    </div>

                    {/* Actions */}
                    <div className="grid grid-cols-3 gap-2 pt-1">
                      <button
                        onClick={() => {
                          setEditingMember(m)
                          setNewName(m.ad)
                          setNewBakiye(m.bakiye)
                        }}
                        className="p-2 rounded-xl bg-ivory border border-line hover:border-espresso text-ink hover:text-espresso text-[11px] font-bold flex flex-col items-center gap-1 transition-all cursor-pointer"
                        title="Bakiye / İsim Müdahalesi"
                      >
                        <Edit2 className="w-3.5 h-3.5 text-mocha" />
                        <span>Müdahale</span>
                      </button>

                      <button
                        onClick={() => {
                          setPkgMember(m)
                          setSelectedPkgId(1)
                        }}
                        className="p-2 rounded-xl bg-ivory border border-line hover:border-espresso text-ink hover:text-espresso text-[11px] font-bold flex flex-col items-center gap-1 transition-all cursor-pointer"
                        title="Paket Tanımla"
                      >
                        <CreditCard className="w-3.5 h-3.5 text-mocha" />
                        <span>+ Paket</span>
                      </button>

                      <button
                        onClick={() => {
                          setNotifMember(m)
                          setNotifTitle('Sobo Society Duyuru')
                          setNotifBody('')
                        }}
                        className="p-2 rounded-xl bg-ivory border border-line hover:border-espresso text-ink hover:text-espresso text-[11px] font-bold flex flex-col items-center gap-1 transition-all cursor-pointer"
                        title="Özel Bildirim Gönder"
                      >
                        <Send className="w-3.5 h-3.5 text-mocha" />
                        <span>Özel Bildirim</span>
                      </button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* Modal 1: Member Edit / Credit Intervention */}
        {editingMember && (
          <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs flex items-center justify-center p-4">
            <Card className="max-w-md w-full bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150">
              <CardHeader className="border-b border-line pb-4">
                <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                  <Edit2 className="w-4 h-4 text-espresso" />
                  <span>Üye Bilgisi & Bakiye Müdahalesi</span>
                </CardTitle>
                <CardDescription className="text-xs text-secondary">
                  {editingMember.telefon} numaralı üye için bilgileri ve kredi bakiyesini doğrudan değiştirin.
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-6 space-y-4">
                <form onSubmit={handleUpdateMember} className="space-y-4">
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
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Kalan Ders Bakiyesi (Kredi)</label>
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
                      <span>KAYDET & GÜNCELLE</span>
                    </button>
                  </div>
                </form>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Modal 2: Single Member Notification */}
        {notifMember && (
          <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs flex items-center justify-center p-4">
            <Card className="max-w-md w-full bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150">
              <CardHeader className="border-b border-line pb-4">
                <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                  <Send className="w-4 h-4 text-espresso" />
                  <span>Üyeye Özel Bildirim Gönder</span>
                </CardTitle>
                <CardDescription className="text-xs text-secondary">
                  <strong>{notifMember.ad}</strong> üyesine doğrudan push bildirim ve duyuru iletin.
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-6 space-y-4">
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
                      placeholder="Örn: Merhaba Ayşe Hanım, yarınki Barre dersiniz saat 10:00'da başlayacaktır."
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

        {/* Modal 3: Assign Package */}
        {pkgMember && (
          <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs flex items-center justify-center p-4">
            <Card className="max-w-md w-full bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150">
              <CardHeader className="border-b border-line pb-4">
                <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                  <CreditCard className="w-4 h-4 text-espresso" />
                  <span>Üyeye Paket Tanımla</span>
                </CardTitle>
                <CardDescription className="text-xs text-secondary">
                  <strong>{pkgMember.ad}</strong> üyesine yeni ders paketi yükleyin.
                </CardDescription>
              </CardHeader>
              <CardContent className="pt-6 space-y-4">
                <form onSubmit={handleAssignPackage} className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase mb-1">Paket Seçimi</label>
                    <select
                      value={selectedPkgId}
                      onChange={(e) => setSelectedPkgId(Number(e.target.value))}
                      className="w-full bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium focus:ring-2 focus:ring-espresso"
                    >
                      <option value={1}>Sobo Trial (1 Ders / 14 Gün)</option>
                      <option value={2}>Sobo Starter (5 Ders / 45 Gün)</option>
                      <option value={3}>Sobo Core (10 Ders / 60 Gün)</option>
                      <option value={4}>Society Pass (20 Ders / 90 Gün)</option>
                    </select>
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
      </main>
    </div>
  )
}
