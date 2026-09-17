'use client'

import React, { useState, useEffect } from 'react'
import { admin, PackageResponse } from '@/lib/api'
import { buyukHarf } from '@/lib/utils'
import { AdminNav } from '@/components/admin/admin-nav'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import {
  Package as PackageIcon,
  Plus,
  Edit2,
  Trash2,
  RefreshCw,
  Loader2,
  CheckCircle2,
  AlertCircle,
  X,
  Sparkles,
  Info,
  Clock,
  Layers,
} from 'lucide-react'

export default function AdminPackagesPage() {
  const [packages, setPackages] = useState<PackageResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // New package form state
  const [showAddForm, setShowAddForm] = useState(false)
  const [newAd, setNewAd] = useState('')
  const [newDersAdedi, setNewDersAdedi] = useState<number>(8)
  const [newBirim, setNewBirim] = useState<'hafta' | 'gun'>('hafta')
  const [newVal, setNewVal] = useState<number>(6)
  const [newFiyatTl, setNewFiyatTl] = useState<number>(3200)
  const [newAktif, setNewAktif] = useState(true)
  const [creating, setCreating] = useState(false)

  // Edit package state
  const [editingPackage, setEditingPackage] = useState<PackageResponse | null>(null)
  const [editAd, setEditAd] = useState('')
  const [editDersAdedi, setEditDersAdedi] = useState<number>(8)
  const [editBirim, setEditBirim] = useState<'hafta' | 'gun'>('hafta')
  const [editVal, setEditVal] = useState<number>(6)
  const [editFiyatTl, setEditFiyatTl] = useState<number>(3200)
  const [editAktif, setEditAktif] = useState(true)
  const [updating, setUpdating] = useState(false)
  const [editModalError, setEditModalError] = useState<string | null>(null)

  const formatValidityText = (days: number) => {
    if (!days) return ''
    if (days % 7 === 0) {
      const hafta = days / 7
      return `${hafta} Hafta (${days} Gün)`
    }
    const hafta = Math.floor(days / 7)
    const kalan = days % 7
    if (hafta > 0) {
      return `${hafta} Hafta ${kalan} Gün`
    }
    return `${days} Gün`
  }

  const fetchPackages = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await admin.getPackages()
      setPackages(data || [])
    } catch (err: any) {
      setError(err?.message || 'Ders paketleri yüklenirken bir hata oluştu.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchPackages()
  }, [])

  const handleCreatePackage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newAd.trim()) {
      setError('Lütfen paket adını yazınız.')
      return
    }

    const calculatedDays = newBirim === 'hafta' ? Number(newVal) * 7 : Number(newVal)

    setCreating(true)
    setError(null)
    try {
      await admin.createPackage({
        ad: newAd.trim(),
        ders_adedi: Number(newDersAdedi),
        gecerlilik_gun: calculatedDays,
        fiyat_tl: Number(newFiyatTl) || 0,
        aktif: newAktif,
      })
      setNewAd('')
      setShowAddForm(false)
      fetchPackages()
    } catch (err: any) {
      setError(err?.message || 'Paket oluşturulurken bir hata oluştu.')
    } finally {
      setCreating(false)
    }
  }

  const openEditModal = (pkg: PackageResponse) => {
    setEditingPackage(pkg)
    setEditAd(pkg.ad)
    setEditDersAdedi(pkg.ders_adedi)
    if (pkg.gecerlilik_gun % 7 === 0) {
      setEditBirim('hafta')
      setEditVal(pkg.gecerlilik_gun / 7)
    } else {
      setEditBirim('gun')
      setEditVal(pkg.gecerlilik_gun)
    }
    setEditFiyatTl(pkg.fiyat_tl)
    setEditAktif(pkg.aktif)
    setEditModalError(null)
  }

  const handleUpdatePackage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editingPackage) return
    if (!editAd.trim()) {
      setEditModalError('Lütfen paket adını yazınız.')
      return
    }

    const calculatedEditDays = editBirim === 'hafta' ? Number(editVal) * 7 : Number(editVal)

    setUpdating(true)
    setEditModalError(null)
    try {
      await admin.updatePackage(editingPackage.id, {
        ad: editAd.trim(),
        ders_adedi: Number(editDersAdedi),
        gecerlilik_gun: calculatedEditDays,
        fiyat_tl: Number(editFiyatTl) || 0,
        aktif: editAktif,
      })
      setEditingPackage(null)
      fetchPackages()
    } catch (err: any) {
      setEditModalError(err?.message || 'Paket güncellenirken bir hata oluştu.')
    } finally {
      setUpdating(false)
    }
  }

  const handleDeletePackage = async (pkgId: number, pkgAd: string) => {
    if (!confirm(`"${pkgAd}" paketini silmek veya pasife almak istediğinizden emin misiniz?`)) return
    try {
      const res = await admin.deletePackage(pkgId)
      alert(res.mesaj)
      fetchPackages()
    } catch (err: any) {
      alert(err?.message || 'Paket silinirken hata oluştu.')
    }
  }

  return (
    <div className="min-h-screen bg-ivory text-ink font-sans antialiased relative">
      <AdminNav />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 relative z-10 space-y-8">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1.5">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-sand text-espresso border border-line">
                <PackageIcon className="w-3.5 h-3.5 text-mocha" />
                <span>Stüdyo Üyelik & Paket Konsolu</span>
              </span>
            </div>
            <h1 className="font-serif text-3xl sm:text-4xl font-extrabold tracking-tight text-ink">
              {buyukHarf("Ders Paketleri & Fiyat Yönetimi")}
            </h1>
            <p className="text-sm text-secondary font-medium mt-1">
              Stüdyonuzda satılan tüm ders paketlerinin adını, ders adedini, kullanım süresini ve TL fiyatlarını tanımlayın ve yönetin.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowAddForm(!showAddForm)}
              className="px-5 py-2.5 rounded-xl font-bold text-xs uppercase tracking-wider bg-espresso text-ivory hover:bg-espresso-dark transition-all flex items-center gap-2 cursor-pointer shadow-xs"
            >
              <Plus className="w-4 h-4" />
              <span>{showAddForm ? 'Kapat' : '+ Yeni Paket Ekle'}</span>
            </button>

            <button
              onClick={fetchPackages}
              disabled={loading}
              className="p-2.5 rounded-xl bg-sand border border-line text-ink hover:text-espresso transition-colors cursor-pointer"
              title="Yenile"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>

        {/* Hata Mesajı */}
        {error && (
          <div className="p-4 rounded-xl bg-clay/15 text-clay border border-clay/40 text-xs font-medium flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Yeni Paket Ekleme Formu */}
        {showAddForm && (
          <Card className="border border-espresso/30 shadow-md bg-sand rounded-2xl text-ink animate-in fade-in slide-in-from-top-2 duration-200">
            <CardHeader className="border-b border-line/80 pb-4">
              <CardTitle className="flex items-center gap-2 text-lg font-serif font-bold text-ink">
                <Plus className="w-5 h-5 text-espresso" />
                <span>Yeni Stüdyo Ders Paketi Tanımla</span>
              </CardTitle>
              <CardDescription className="text-secondary text-xs">
                Sitede ve uygulamada üyelere sunulacak yeni bir ders paketi ekleyin.
              </CardDescription>
            </CardHeader>

            <CardContent className="pt-6">
              <form onSubmit={handleCreatePackage} className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 items-end">
                <div className="lg:col-span-2">
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                    Paket Adı
                  </label>
                  <Input
                    type="text"
                    placeholder="Örn: Barre Class 8 Ders / Reformer Bireysel 12 Ders"
                    value={newAd}
                    onChange={(e) => setNewAd(e.target.value)}
                    className="bg-ivory border-line text-ink rounded-xl h-11 px-3.5 text-xs font-medium"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                    Ders Adedi
                  </label>
                  <Input
                    type="number"
                    min={1}
                    value={newDersAdedi}
                    onChange={(e) => setNewDersAdedi(Number(e.target.value))}
                    className="bg-ivory border-line text-ink rounded-xl h-11 px-3.5 text-xs font-medium"
                    required
                  />
                </div>

                <div>
                  <div className="flex items-center justify-between mb-1.5">
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider">
                      Geçerlilik Süresi
                    </label>
                    <div className="flex items-center gap-1 bg-ivory p-0.5 rounded-lg border border-line">
                      <button
                        type="button"
                        onClick={() => { setNewBirim('hafta'); setNewVal(6); }}
                        className={`px-2 py-0.5 text-[10px] font-extrabold rounded cursor-pointer transition-all ${newBirim === 'hafta' ? 'bg-espresso text-ivory shadow-xs' : 'text-secondary hover:text-ink'}`}
                      >
                        Hafta
                      </button>
                      <button
                        type="button"
                        onClick={() => { setNewBirim('gun'); setNewVal(42); }}
                        className={`px-2 py-0.5 text-[10px] font-extrabold rounded cursor-pointer transition-all ${newBirim === 'gun' ? 'bg-espresso text-ivory shadow-xs' : 'text-secondary hover:text-ink'}`}
                      >
                        Gün
                      </button>
                    </div>
                  </div>
                  <div className="relative">
                    <Input
                      type="number"
                      min={1}
                      value={newVal}
                      onChange={(e) => setNewVal(Number(e.target.value))}
                      className="bg-ivory border-line text-ink rounded-xl h-11 px-3.5 text-xs font-bold"
                      placeholder="6"
                      required
                    />
                    <span className="absolute right-3 top-3.5 text-[10px] font-extrabold text-espresso">
                      {newBirim === 'hafta' ? `${newVal} Hafta (${newVal * 7} Gün)` : `${newVal} Gün`}
                    </span>
                  </div>
                </div>

                <div>
                  <div className="flex items-center justify-between mb-1.5">
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider">
                      Paket Fiyatı (₺ TL)
                    </label>
                    <button
                      type="button"
                      onClick={() => setNewFiyatTl(0)}
                      className="text-[10px] font-bold text-mocha hover:underline cursor-pointer"
                    >
                      Fiyatı Gizle
                    </button>
                  </div>
                  <Input
                    type="number"
                    min={0}
                    step={50}
                    value={newFiyatTl}
                    onChange={(e) => setNewFiyatTl(Number(e.target.value))}
                    className="bg-ivory border-line text-ink rounded-xl h-11 px-3.5 text-xs font-medium"
                    placeholder="0 (Fiyat gizli)"
                  />
                  <p className="text-[10px] text-secondary mt-1">
                    {Number(newFiyatTl) > 0 ? `₺${Number(newFiyatTl).toLocaleString('tr-TR')}` : '0 ise fiyat gizlenir'}
                  </p>
                </div>

                <div className="lg:col-span-5 pt-2 flex items-center justify-between">
                  <label className="flex items-center gap-2 cursor-pointer text-xs font-bold text-ink">
                    <input
                      type="checkbox"
                      checked={newAktif}
                      onChange={(e) => setNewAktif(e.target.checked)}
                      className="rounded border-line text-espresso focus:ring-espresso w-4 h-4"
                    />
                    <span>Paket Sitede & Uygulamada Yayında Olsun (Aktif)</span>
                  </label>

                  <div className="flex gap-3">
                    <button
                      type="button"
                      onClick={() => setShowAddForm(false)}
                      className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                    >
                      İptal
                    </button>
                    <button
                      type="submit"
                      disabled={creating}
                      className="px-6 py-2.5 rounded-xl font-extrabold text-xs uppercase tracking-wider bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                    >
                      {creating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
                      <span>Paketi Kaydet</span>
                    </button>
                  </div>
                </div>
              </form>
            </CardContent>
          </Card>
        )}

        {/* Paket Kartları Listesi */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <Layers className="w-5 h-5 text-espresso" />
              <span>Stüdyo Paket Listesi ({packages.length})</span>
            </h2>
            <span className="text-xs text-secondary font-medium">Paket fiyatları üyelerinize web ve uygulamada görünecektir</span>
          </div>

          {loading ? (
            <div className="flex flex-col items-center justify-center py-20 border border-line rounded-2xl bg-sand/40">
              <Loader2 className="w-8 h-8 text-espresso animate-spin mb-3" />
              <p className="text-xs text-secondary font-semibold">Ders paketleri yükleniyor...</p>
            </div>
          ) : packages.length === 0 ? (
            <div className="p-10 text-center bg-sand/60 border border-line rounded-2xl space-y-3">
              <Info className="w-8 h-8 text-mocha mx-auto opacity-60" />
              <p className="text-sm font-medium text-ink">Henüz kayıtlı bir ders paketi bulunmamaktadır.</p>
              <p className="text-xs text-secondary max-w-sm mx-auto">
                Yukarıdaki &quot;+ Yeni Paket Ekle&quot; butonuna basarak üyeler için ders paketi tanımlayabilirsiniz.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {packages.map((pkg) => (
                <Card
                  key={pkg.id}
                  className={`border shadow-xs rounded-2xl overflow-hidden transition-all ${
                    pkg.aktif
                      ? 'bg-sand border-line hover:border-espresso/40'
                      : 'bg-sand/40 border-line/50 opacity-70'
                  }`}
                >
                  <CardHeader className="pb-3 border-b border-line/60 bg-sand-light/50">
                    <div className="flex items-center justify-between">
                      <span
                        className={`inline-block px-2.5 py-0.5 rounded-full text-[10px] uppercase font-bold tracking-wider ${
                          pkg.aktif ? 'bg-sage/15 text-sage border border-sage/30' : 'bg-clay/15 text-clay border border-clay/30'
                        }`}
                      >
                        {pkg.aktif ? 'Yayında (Aktif)' : 'Pasif'}
                      </span>
                      <span className="text-xs font-bold text-mocha bg-mocha/10 px-2.5 py-1 rounded-xl border border-mocha/30">
                        Fiyat: WhatsApp İletişim
                      </span>
                    </div>

                    <CardTitle className="font-serif text-xl font-bold text-ink mt-3">
                      {pkg.ad}
                    </CardTitle>
                  </CardHeader>

                  <CardContent className="pt-4 space-y-4 text-xs text-secondary font-medium">
                    <div className="grid grid-cols-2 gap-3">
                      <div className="p-3 bg-ivory/80 rounded-xl border border-line/60">
                        <span className="text-[10px] uppercase font-bold text-secondary block mb-0.5">Ders Adedi</span>
                        <span className="text-base font-extrabold text-ink">{pkg.ders_adedi} Seans</span>
                      </div>

                      <div className="p-3 bg-ivory/80 rounded-xl border border-line/60">
                        <span className="text-[10px] uppercase font-bold text-secondary block mb-0.5">Geçerlilik Süresi</span>
                        <span className="text-base font-extrabold text-ink">{formatValidityText(pkg.gecerlilik_gun)}</span>
                      </div>
                    </div>

                    <div className="pt-2 border-t border-line/50 flex justify-between items-center">
                      <button
                        onClick={() => openEditModal(pkg)}
                        className="px-3.5 py-1.5 rounded-xl text-xs font-bold bg-ivory border border-line hover:border-espresso text-espresso transition-colors flex items-center gap-1.5 cursor-pointer shadow-xs"
                      >
                        <Edit2 className="w-3.5 h-3.5 text-mocha" />
                        <span>Fiyat & Detay Düzenle</span>
                      </button>

                      <button
                        onClick={() => handleDeletePackage(pkg.id, pkg.ad)}
                        className="px-3 py-1.5 rounded-xl text-xs font-bold text-clay hover:bg-clay/10 transition-colors flex items-center gap-1.5 cursor-pointer"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        <span>Sil</span>
                      </button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* Modal: Edit Package */}
        {editingPackage && (
          <div className="fixed inset-0 z-50 bg-ink/60 backdrop-blur-xs overflow-y-auto p-4 sm:p-6 flex items-center justify-center min-h-screen">
            <Card className="max-w-md w-full max-h-[90vh] flex flex-col my-auto bg-sand border border-line rounded-2xl shadow-xl animate-in fade-in zoom-in-95 duration-150 overflow-hidden">
              <CardHeader className="border-b border-line pb-4 relative shrink-0">
                <button
                  onClick={() => setEditingPackage(null)}
                  className="absolute top-4 right-4 text-secondary hover:text-ink p-1 rounded-full hover:bg-sand cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
                <CardTitle className="font-serif text-lg font-bold text-ink flex items-center gap-2">
                  <Edit2 className="w-5 h-5 text-espresso" />
                  <span>Paket Detaylarını & Fiyatını Güncelle</span>
                </CardTitle>
                <CardDescription className="text-xs text-secondary">
                  &quot;{editingPackage.ad}&quot; paketinin fiyatını, geçerlilik gün sayısını veya adını değiştirin.
                </CardDescription>
              </CardHeader>

              <CardContent className="pt-6 space-y-4 overflow-y-auto flex-1">
                <form onSubmit={handleUpdatePackage} className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                      Paket Adı
                    </label>
                    <Input
                      type="text"
                      value={editAd}
                      onChange={(e) => setEditAd(e.target.value)}
                      className="bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium"
                      required
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-xs font-bold text-secondary uppercase tracking-wider mb-1.5">
                        Ders Adedi
                      </label>
                      <Input
                        type="number"
                        min={1}
                        value={editDersAdedi}
                        onChange={(e) => setEditDersAdedi(Number(e.target.value))}
                        className="bg-ivory border-line text-ink rounded-xl h-11 px-3 text-xs font-medium"
                        required
                      />
                    </div>

                    <div>
                      <div className="flex items-center justify-between mb-1.5">
                        <label className="block text-xs font-bold text-secondary uppercase tracking-wider">
                          Geçerlilik
                        </label>
                        <div className="flex items-center gap-1 bg-ivory p-0.5 rounded-lg border border-line">
                          <button
                            type="button"
                            onClick={() => { setEditBirim('hafta'); }}
                            className={`px-2 py-0.5 text-[10px] font-extrabold rounded cursor-pointer transition-all ${editBirim === 'hafta' ? 'bg-espresso text-ivory shadow-xs' : 'text-secondary hover:text-ink'}`}
                          >
                            Hafta
                          </button>
                          <button
                            type="button"
                            onClick={() => { setEditBirim('gun'); }}
                            className={`px-2 py-0.5 text-[10px] font-extrabold rounded cursor-pointer transition-all ${editBirim === 'gun' ? 'bg-espresso text-ivory shadow-xs' : 'text-secondary hover:text-ink'}`}
                          >
                            Gün
                          </button>
                        </div>
                      </div>
                      <div className="relative">
                        <Input
                          type="number"
                          min={1}
                          value={editVal}
                          onChange={(e) => setEditVal(Number(e.target.value))}
                          className="bg-ivory border-line text-ink font-bold rounded-xl h-11 px-3 text-xs"
                          required
                        />
                        <span className="absolute right-3 top-3.5 text-[10px] font-extrabold text-espresso">
                          {editBirim === 'hafta' ? `${editVal} Hafta (${editVal * 7} Gün)` : `${editVal} Gün`}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center justify-between mb-1.5">
                      <label className="block text-xs font-bold text-secondary uppercase tracking-wider">
                        Yeni Paket Fiyatı (₺ TL)
                      </label>
                      <button
                        type="button"
                        onClick={() => setEditFiyatTl(0)}
                        className="text-[11px] font-bold text-mocha hover:underline cursor-pointer"
                      >
                        Fiyatı Sil / Gizle
                      </button>
                    </div>
                    <Input
                      type="number"
                      min={0}
                      step={50}
                      value={editFiyatTl}
                      onChange={(e) => setEditFiyatTl(Number(e.target.value))}
                      className="bg-ivory border-line text-ink font-bold rounded-xl h-11 px-3 text-sm"
                      placeholder="0 (Fiyat gizli)"
                    />
                    <p className="text-[11px] text-secondary mt-1">
                      {Number(editFiyatTl) > 0
                        ? `Üyeler sitede ve mobilde ₺${Number(editFiyatTl).toLocaleString('tr-TR')} olarak görecektir.`
                        : '💡 0 veya boş bırakılırsa sitede ve mobilde fiyat gizlenir, "Fiyat İçin İletişime Geçin" butonu görünür.'}
                    </p>
                  </div>

                  <label className="flex items-center gap-2 cursor-pointer text-xs font-bold text-ink pt-1">
                    <input
                      type="checkbox"
                      checked={editAktif}
                      onChange={(e) => setEditAktif(e.target.checked)}
                      className="rounded border-line text-espresso focus:ring-espresso w-4 h-4"
                    />
                    <span>Paket Sitede & Uygulamada Yayında Olsun (Aktif)</span>
                  </label>

                  {editModalError && (
                    <div className="p-3 rounded-xl bg-clay/15 text-clay text-xs font-bold border border-clay/30 flex items-center gap-2">
                      <AlertCircle className="w-4 h-4 text-clay shrink-0" />
                      <span>{editModalError}</span>
                    </div>
                  )}

                  <div className="pt-2 flex justify-end gap-3">
                    <button
                      type="button"
                      onClick={() => setEditingPackage(null)}
                      className="px-4 py-2.5 rounded-xl text-xs font-bold text-secondary hover:text-ink cursor-pointer"
                    >
                      İptal
                    </button>
                    <button
                      type="submit"
                      disabled={updating}
                      className="px-5 py-2.5 rounded-xl font-extrabold text-xs uppercase tracking-wider bg-espresso text-ivory hover:bg-espresso-dark transition-all cursor-pointer shadow-xs flex items-center gap-2"
                    >
                      {updating ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle2 className="w-4 h-4" />}
                      <span>PAKETİ GÜNCELLE</span>
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
