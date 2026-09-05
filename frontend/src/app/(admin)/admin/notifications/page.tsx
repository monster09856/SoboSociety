'use client'

import React, { useEffect, useState } from 'react'
import { Bell, Send, Clock, Trash2, CheckCircle2, AlertCircle, Sparkles, Users } from 'lucide-react'
import { adminApi } from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'

interface CampaignItem {
  id: number
  baslik: string
  mesaj: string
  hedef_kitle: string
  zamanlama_tipi: string
  zamanlama_saat: string | null
  gonderilen_sayisi: number
  aktif: boolean
}

export default function AdminNotificationsPage() {
  const [activeTab, setActiveTab] = useState<'instant' | 'scheduled'>('instant')

  // Instant Push Form
  const [instantBaslik, setInstantBaslik] = useState('')
  const [instantMesaj, setInstantMesaj] = useState('')
  const [instantKitle, setInstantKitle] = useState('TUM_UYELER')
  const [instantLoading, setInstantLoading] = useState(false)
  const [instantResult, setInstantResult] = useState<string | null>(null)

  // Scheduled Campaign Form
  const [schedBaslik, setSchedBaslik] = useState('')
  const [schedMesaj, setSchedMesaj] = useState('')
  const [schedSaat, setSchedSaat] = useState('10:00')
  const [schedKitle, setSchedKitle] = useState('TUM_UYELER')
  const [schedLoading, setSchedLoading] = useState(false)

  const [campaigns, setCampaigns] = useState<CampaignItem[]>([])
  const [membersList, setMembersList] = useState<{ id: number; ad: string; kullanici_adi?: string | null; telefon?: string | null }[]>([])
  const [loadingList, setLoadingList] = useState(true)

  const loadData = async () => {
    try {
      setLoadingList(true)
      const [cData, mData] = await Promise.all([
        adminApi.getCampaigns(),
        adminApi.getMembers().catch(() => []),
      ])
      setCampaigns(cData || [])
      setMembersList(mData || [])
    } catch (err) {
      console.error('Veriler yüklenemedi:', err)
    } finally {
      setLoadingList(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [])

  const handleInstantSend = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!instantBaslik || !instantMesaj) return
    try {
      setInstantLoading(true)
      setInstantResult(null)
      const res = await adminApi.broadcastPush({
        baslik: instantBaslik,
        mesaj: instantMesaj,
        hedef_kitle: instantKitle,
      })
      setInstantResult(`Bildirim ${res.gonderilen_sayisi} alıcıya başarıyla gönderildi! 🚀`)
      setInstantBaslik('')
      setInstantMesaj('')
    } catch (err) {
      alert('Bildirim gönderilirken hata oluştu.')
    } finally {
      setInstantLoading(false)
    }
  }

  const handleCreateCampaign = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!schedBaslik || !schedMesaj) return
    try {
      setSchedLoading(true)
      await adminApi.createCampaign({
        baslik: schedBaslik,
        mesaj: schedMesaj,
        hedef_kitle: schedKitle,
        zamanlama_tipi: 'GUNLUK_TEKRAR',
        zamanlama_saat: schedSaat,
      })
      setSchedBaslik('')
      setSchedMesaj('')
      await loadData()
      alert('Otomatik günlük kampanya başarıyla oluşturuldu!')
    } catch (err) {
      alert('Kampanya oluşturulurken hata oluştu.')
    } finally {
      setSchedLoading(false)
    }
  }

  const handleDeleteCampaign = async (id: number) => {
    if (!confirm('Bu kampanyayı silmek istediğinize emin misiniz?')) return
    try {
      await adminApi.deleteCampaign(id)
      await loadData()
    } catch (err) {
      alert('Kampanya silinemedi.')
    }
  }

  return (
    <div className="min-h-screen bg-ivory text-ink py-10 px-4 sm:px-6 lg:px-8">
      <div className="max-w-5xl mx-auto space-y-8">
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-line pb-6">
          <div>
            <div className="flex items-center gap-2">
              <span className="p-2 rounded-chip bg-mocha/10 text-mocha">
                <Bell className="w-5 h-5" />
              </span>
              <h1 className="font-serif text-3xl font-medium tracking-wide text-ink">
                Bildirim & Push Konsolu
              </h1>
            </div>
            <p className="text-secondary text-xs mt-1">
              Özel Firebase / APNs Push Konsolu: Anlık toplu bildirim gönderin veya günlük otomatik hatırlatma kampanyaları zamanlayın.
            </p>
          </div>

          <div className="flex items-center gap-2 bg-sand-light p-1 rounded-input border border-line">
            <button
              onClick={() => setActiveTab('instant')}
              className={`px-4 py-2 text-xs font-medium rounded-chip transition-all flex items-center gap-1.5 cursor-pointer ${
                activeTab === 'instant'
                  ? 'bg-espresso text-white shadow-xs'
                  : 'text-secondary hover:text-ink'
              }`}
            >
              <Send className="w-3.5 h-3.5" />
              <span>Anlık Bildirim</span>
            </button>

            <button
              onClick={() => setActiveTab('scheduled')}
              className={`px-4 py-2 text-xs font-medium rounded-chip transition-all flex items-center gap-1.5 cursor-pointer ${
                activeTab === 'scheduled'
                  ? 'bg-espresso text-white shadow-xs'
                  : 'text-secondary hover:text-ink'
              }`}
            >
              <Clock className="w-3.5 h-3.5" />
              <span>Günlük Zamanlama</span>
            </button>
          </div>
        </div>

        {/* Tab 1: Instant Push Console */}
        {activeTab === 'instant' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2">
              <Card className="sobo-card">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Sparkles className="w-5 h-5 text-mocha" />
                    <span>Anlık Toplu Push Bildirimi Gönder</span>
                  </CardTitle>
                  <CardDescription>
                    Tüm üyelere veya seçili kitleye anında mobil push ve uygulama içi bildirim gönderir.
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleInstantSend} className="space-y-5">
                    <div>
                      <label className="block text-xs font-medium text-secondary mb-1">
                        Bildirim Başlığı
                      </label>
                      <input
                        type="text"
                        required
                        placeholder="Örn: Akşam Reformer Dersinde Son Yerler! 🧘‍♀️"
                        value={instantBaslik}
                        onChange={(e) => setInstantBaslik(e.target.value)}
                        className="w-full px-4 py-3 bg-ivory border border-line rounded-input text-xs text-ink focus:outline-none focus:border-espresso transition-colors"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-medium text-secondary mb-1">
                        Bildirim Mesajı Body
                      </label>
                      <textarea
                        required
                        rows={3}
                        placeholder="Örn: Bu akşam saat 19:00 Barre Studio dersinde son 2 kontenjan kaldı, hemen yerinizi ayırtın."
                        value={instantMesaj}
                        onChange={(e) => setInstantMesaj(e.target.value)}
                        className="w-full px-4 py-3 bg-ivory border border-line rounded-input text-xs text-ink focus:outline-none focus:border-espresso transition-colors"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-medium text-secondary mb-1">
                        Hedef Kitle
                      </label>
                      <select
                        value={instantKitle}
                        onChange={(e) => setInstantKitle(e.target.value)}
                        className="w-full px-4 py-3 bg-ivory border border-line rounded-input text-xs text-ink focus:outline-none focus:border-espresso transition-colors font-medium"
                      >
                        <optgroup label="Genel Bildirim Grupları">
                          <option value="TUM_UYELER">Tüm Aktif Üyeler (Toplu)</option>
                          <option value="AKTIF_PAKETLI">Aktif Paketi Olanlar</option>
                        </optgroup>
                        {membersList.length > 0 && (
                          <optgroup label="Kişiye Özel Bildirim (Tek Üye)">
                            {membersList.map((m) => (
                              <option key={m.id} value={`MEMBER_${m.id}`}>
                                Kişiye Özel: {m.ad} {m.kullanici_adi ? `(@${m.kullanici_adi})` : ''} {m.telefon ? `[${m.telefon}]` : ''}
                              </option>
                            ))}
                          </optgroup>
                        )}
                      </select>
                    </div>

                    {instantResult && (
                      <div className="p-4 bg-sage/10 border border-sage/30 rounded-input text-xs text-sage flex items-center gap-2">
                        <CheckCircle2 className="w-4 h-4 shrink-0" />
                        <span>{instantResult}</span>
                      </div>
                    )}

                    <Button
                      type="submit"
                      disabled={instantLoading}
                      variant="primary"
                      className="w-full py-3 text-xs tracking-wider uppercase font-medium flex items-center justify-center gap-2 cursor-pointer"
                    >
                      <Send className="w-4 h-4" />
                      <span>{instantLoading ? 'Gönderiliyor...' : 'ANINDA TOPLU PUSH GÖNDER'}</span>
                    </Button>
                  </form>
                </CardContent>
              </Card>
            </div>

            {/* Quick Tips */}
            <div>
              <Card className="sobo-card bg-sand-light/50 border-line">
                <CardHeader>
                  <CardTitle className="text-base flex items-center gap-2">
                    <Users className="w-4 h-4 text-mocha" />
                    <span>Push Konsol Bilgisi</span>
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3 text-xs text-secondary leading-relaxed">
                  <p>
                    • **Anlık Bildirim:** Mesajınız hem iOS cihazlardaki APNs servisine hem de Web PWA bildirim sistemine eşzamanlı iletilir.
                  </p>
                  <p>
                    • **Uygulama İçi Saklama:** Gönderilen bildirimler aynı zamanda üyelerin profillerindeki bildirim geçmişine kaydedilir.
                  </p>
                </CardContent>
              </Card>
            </div>
          </div>
        )}

        {/* Tab 2: Scheduled Campaigns Console */}
        {activeTab === 'scheduled' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-1">
              <Card className="sobo-card">
                <CardHeader>
                  <CardTitle className="text-base flex items-center gap-2">
                    <Clock className="w-4 h-4 text-mocha" />
                    <span>Günlük Otomatik Kampanya Ekle</span>
                  </CardTitle>
                  <CardDescription>
                    Her gün belirlediğiniz saatte otomatik olarak üyelere bildirim gönderir.
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <form onSubmit={handleCreateCampaign} className="space-y-4">
                    <div>
                      <label className="block text-xs font-medium text-secondary mb-1">
                        Kampanya Başlığı
                      </label>
                      <input
                        type="text"
                        required
                        placeholder="Örn: Günün Derslerini Keşfedin ☀️"
                        value={schedBaslik}
                        onChange={(e) => setSchedBaslik(e.target.value)}
                        className="w-full px-3 py-2.5 bg-ivory border border-line rounded-input text-xs text-ink focus:outline-none focus:border-espresso"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-medium text-secondary mb-1">
                        Bildirim Mesajı
                      </label>
                      <textarea
                        required
                        rows={3}
                        placeholder="Örn: Bugünkü Pilates ve Barre derslerinde son kontenjanlar açık. Hemen yerinizi rezerve edin."
                        value={schedMesaj}
                        onChange={(e) => setSchedMesaj(e.target.value)}
                        className="w-full px-3 py-2.5 bg-ivory border border-line rounded-input text-xs text-ink focus:outline-none focus:border-espresso"
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-medium text-secondary mb-1">
                        Her Gün Çalışma Saati (HH:MM)
                      </label>
                      <input
                        type="time"
                        required
                        value={schedSaat}
                        onChange={(e) => setSchedSaat(e.target.value)}
                        className="w-full px-3 py-2.5 bg-ivory border border-line rounded-input text-xs text-ink focus:outline-none focus:border-espresso"
                      />
                    </div>

                    <Button
                      type="submit"
                      disabled={schedLoading}
                      variant="primary"
                      className="w-full py-2.5 text-xs font-medium cursor-pointer"
                    >
                      {schedLoading ? 'Kaydediliyor...' : 'ZAMANLANMIŞ KAMPANYA EKLE'}
                    </Button>
                  </form>
                </CardContent>
              </Card>
            </div>

            {/* Scheduled Campaigns List */}
            <div className="lg:col-span-2">
              <Card className="sobo-card">
                <CardHeader>
                  <CardTitle className="text-base">Aktif Otomatik Kampanyalar</CardTitle>
                  <CardDescription>
                    Her gün otomatik olarak çalışan aktif bildirim senaryoları.
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {loadingList ? (
                    <div className="py-8 text-center text-xs text-secondary">Kampanyalar yükleniyor...</div>
                  ) : campaigns.length === 0 ? (
                    <div className="py-8 text-center text-xs text-secondary border border-dashed border-line rounded-card">
                      Henüz tanımlanmış otomatik kampanya bulunmuyor.
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {campaigns.map((c) => (
                        <div
                          key={c.id}
                          className="p-4 bg-sand-light/40 border border-line rounded-card flex items-center justify-between gap-4"
                        >
                          <div className="space-y-1">
                            <div className="flex items-center gap-2">
                              <h4 className="font-serif text-sm font-medium text-ink">{c.baslik}</h4>
                              <Badge variant="sage" className="text-[10px]">
                                Her Gün {c.zamanlama_saat || '10:00'}
                              </Badge>
                            </div>
                            <p className="text-xs text-secondary max-w-lg">{c.mesaj}</p>
                          </div>

                          <button
                            onClick={() => handleDeleteCampaign(c.id)}
                            className="p-2 text-clay hover:bg-clay/10 rounded-chip transition-colors cursor-pointer"
                            title="Kampanyayı Sil"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
