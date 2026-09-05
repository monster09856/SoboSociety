'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { Check, ShieldCheck, Zap, Users, Sparkles, UserCheck, MessageCircle, Lock, Clock, Loader2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { api, PackageResponse } from '@/lib/api'

interface PackageItem {
  id?: number
  title: string
  subtitle: string
  validity: string
  fiyat_tl?: number
  isPopular?: boolean
  popularTag?: string
  features: string[]
  buttonVariant: 'primary' | 'secondary'
}

export function Packages() {
  const [activeTab, setActiveTab] = useState<'grup' | 'bireysel'>('grup')
  const [dbPackages, setDbPackages] = useState<PackageResponse[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function loadPackages() {
      try {
        const pkgs = await api.packages.list()
        setDbPackages(pkgs || [])
      } catch (err) {
        console.error('Paketler çekilemedi:', err)
      } finally {
        setLoading(false)
      }
    }
    loadPackages()
  }, [])

  // Static Fallback Bireysel Ders Paketleri (Private Class / Individual)
  const defaultBireyselPackages: PackageItem[] = [
    {
      title: 'Barre Class Bireysel',
      subtitle: '8 Derslik Bireysel Paket',
      validity: 'Kullanım Süresi: 45 Gün',
      fiyat_tl: 6400,
      features: [
        '8 Bireysel Class Seansı',
        'Kişiye Özel Birebir Eğitmen',
        'Kullanım Süresi: 45 Gün',
        'Tüm Mat & Ekipmanlar Dahil',
      ],
      buttonVariant: 'secondary',
    },
    {
      title: 'Barre Class Bireysel Premium',
      subtitle: '12 Derslik Bireysel Paket',
      validity: 'Kullanım Süresi: 60 Gün',
      fiyat_tl: 9200,
      popularTag: '12 Saat Önceden İade Hakkı ⏱️',
      features: [
        '12 Bireysel Class Seansı',
        'Kişiye Özel Birebir Eğitmen',
        'Kullanım Süresi: 60 Gün',
        'Esnek İptal & Öncelikli Randevu',
      ],
      buttonVariant: 'primary',
    },
    {
      title: 'Reformer Class Bireysel',
      subtitle: '8 Derslik Bireysel Reformer',
      validity: 'Kullanım Süresi: 45 Gün',
      fiyat_tl: 7200,
      features: [
        '8 Bireysel Reformer Seansı',
        'Kişiye Özel Reformer Cihazı',
        'Kullanım Süresi: 45 Gün',
        'Birebir Postür & Seviye Analizi',
      ],
      buttonVariant: 'secondary',
    },
    {
      title: 'Reformer Class Bireysel Elite',
      subtitle: '12 Derslik Bireysel Reformer',
      validity: 'Kullanım Süresi: 60 Gün',
      fiyat_tl: 10400,
      features: [
        '12 Bireysel Reformer Seansı',
        'Kişiye Özel Reformer Cihazı',
        'Kullanım Süresi: 60 Gün',
        'Esnek Ders İptal Hakkı',
      ],
      buttonVariant: 'secondary',
    },
  ]

  // Static Fallback Grup Ders Paketleri (Class Packages)
  const defaultGrupPackages: PackageItem[] = [
    {
      title: 'Barre Class Tek Ders',
      subtitle: 'Tek Derslik Katılım',
      validity: 'Tek Kullanımlık',
      fiyat_tl: 900,
      features: [
        '1 Adet Barre Class Dersi',
        'Butik Sınıf (Maks. 5 Üye)',
        'Tüm Mat & Ekipmanlar Dahil',
      ],
      buttonVariant: 'secondary',
    },
    {
      title: 'Barre Class 4 Ders',
      subtitle: '4 Derslik Grup Paketi',
      validity: 'Kullanım Süresi: 30 Gün',
      fiyat_tl: 3200,
      features: [
        '4 Adet Barre Class Dersi',
        'Butik Sınıf (Maks. 5 Üye)',
        'Kullanım Süresi: 30 Gün',
        '12 Saat Önceden İade Hakkı',
      ],
      buttonVariant: 'secondary',
    },
    {
      title: 'Barre Class 8 Ders',
      subtitle: '8 Derslik Grup Paketi',
      validity: 'Kullanım Süresi: 45 Gün',
      fiyat_tl: 5800,
      popularTag: 'Popüler Seçim ⭐',
      features: [
        '8 Adet Barre Class Dersi',
        'Butik Sınıf (Maks. 5 Üye)',
        'Kullanım Süresi: 45 Gün',
        'Mobil İle Kolay Rezervasyon',
      ],
      buttonVariant: 'primary',
    },
    {
      title: 'Barre Class 12 Ders',
      subtitle: '12 Derslik Grup Paketi',
      validity: 'Kullanım Süresi: 60 Gün',
      fiyat_tl: 8400,
      features: [
        '12 Adet Barre Class Dersi',
        'Butik Sınıf (Maks. 5 Üye)',
        'Kullanım Süresi: 60 Gün',
        'Öncelikli Bekleme Sırası',
      ],
      buttonVariant: 'secondary',
    },
  ]

  // Prepare active package list combining backend DB packages and fallbacks
  const dynamicPackages: PackageItem[] = dbPackages.map((p, idx) => {
    const isBireysel = p.ad.toLowerCase().includes('bireysel') || p.ad.toLowerCase().includes('özel')
    return {
      id: p.id,
      title: p.ad,
      subtitle: `${p.ders_adedi} Derslik Stüdyo Paketi`,
      validity: `Kullanım Süresi: ${p.gecerlilik_gun} Gün`,
      fiyat_tl: p.fiyat_tl,
      isPopular: idx === 1,
      popularTag: idx === 1 ? 'Popüler Paket ⭐' : undefined,
      features: [
        `${p.ders_adedi} Adet Class Seansı`,
        `Geçerlilik Süresi: ${p.gecerlilik_gun} Gün`,
        isBireysel ? 'Kişiye Özel Birebir Eğitmen' : 'Butik Sınıf (Maks. 5 Üye)',
        'Tüm Ekipman ve Mat Kullanımı Dahil',
        '12 Saat Önceden Kolay İptal & İade',
      ],
      buttonVariant: idx === 1 ? 'primary' : 'secondary',
    }
  })

  // Filter packages based on activeTab
  let currentPackages: PackageItem[] = []
  if (dynamicPackages.length > 0) {
    if (activeTab === 'bireysel') {
      currentPackages = dynamicPackages.filter(
        (p) => p.title.toLowerCase().includes('bireysel') || p.title.toLowerCase().includes('özel')
      )
      if (currentPackages.length === 0) currentPackages = dynamicPackages
    } else {
      currentPackages = dynamicPackages.filter(
        (p) => !p.title.toLowerCase().includes('bireysel') && !p.title.toLowerCase().includes('özel')
      )
      if (currentPackages.length === 0) currentPackages = dynamicPackages
    }
  } else {
    currentPackages = activeTab === 'grup' ? defaultGrupPackages : defaultBireyselPackages
  }

  const advantages = [
    {
      icon: Users,
      title: 'Class Kontenjanı (Max 5 Kişi)',
      desc: 'Kalabalık salonlar yok. Her derste kişiye özel ilgi ve doğru form kontrolü.',
    },
    {
      icon: Zap,
      title: '12 Saat İptal & Ders Hakkı Koruma',
      desc: 'Derse 12 saat kalana kadar tek tıkla iptal edin, ders hakkınızı kaybetmeyin.',
    },
    {
      icon: ShieldCheck,
      title: 'Uzman Eğitmen Kadrosu',
      desc: 'Uluslararası sertifikalı eğitmenler eşliğinde güvenli ve etkili antrenman.',
    },
    {
      icon: Sparkles,
      title: 'Sobo Society & Etkinlikler',
      desc: 'Özel atölyeler, etkinlikler ve workshop\'lar.',
    },
  ]

  return (
    <section id="paketler" className="py-24 bg-ivory relative border-b border-line/60">
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Title */}
        <div className="text-center max-w-2xl mx-auto mb-12 space-y-4">
          <Badge variant="mocha" className="uppercase tracking-widest px-3.5 py-1 text-xs font-medium">
            Üyelik & Ders Paketleri
          </Badge>
          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-medium text-ink tracking-tight">
            Sobo Class Paketleri
          </h2>
          <p className="text-secondary text-base leading-relaxed">
            İhtiyacınıza ve hedefinize en uygun ders paketini seçin, Sobo Society ayrıcalıklı topluluğuna katılın.
          </p>
        </div>

        {/* Tab Selector: Grup vs Bireysel */}
        <div className="flex justify-center mb-14">
          <div className="inline-flex p-1.5 rounded-full bg-sand border border-line shadow-xs">
            <button
              onClick={() => setActiveTab('grup')}
              className={`px-6 py-2.5 rounded-full text-xs font-bold uppercase tracking-wider transition-all cursor-pointer flex items-center gap-2 ${
                activeTab === 'grup'
                  ? 'bg-espresso text-ivory shadow-sm'
                  : 'text-ink hover:text-espresso'
              }`}
            >
              <Users className="w-4 h-4" />
              <span>Grup Class Paketleri (Barre & Yoga)</span>
            </button>

            <button
              onClick={() => setActiveTab('bireysel')}
              className={`px-6 py-2.5 rounded-full text-xs font-bold uppercase tracking-wider transition-all cursor-pointer flex items-center gap-2 ${
                activeTab === 'bireysel'
                  ? 'bg-espresso text-ivory shadow-sm'
                  : 'text-ink hover:text-espresso'
              }`}
            >
              <UserCheck className="w-4 h-4" />
              <span>Bireysel Class Paketleri (Birebir Seanslar)</span>
            </button>
          </div>
        </div>

        {/* Pricing Cards Grid */}
        {loading ? (
          <div className="flex justify-center py-16">
            <Loader2 className="w-8 h-8 text-espresso animate-spin" />
          </div>
        ) : (
          <div className={`grid grid-cols-1 sm:grid-cols-2 ${currentPackages.length >= 4 ? 'lg:grid-cols-4' : 'lg:grid-cols-3'} gap-6 mb-20 items-stretch`}>
            {currentPackages.map((pkg) => (
              <Card
                key={pkg.id || pkg.title}
                className={`relative flex flex-col justify-between transition-all duration-300 ${
                  pkg.isPopular
                    ? 'bg-sand-light border-2 border-espresso shadow-sobo-md scale-[1.02] z-10'
                    : 'bg-sand-light border-line hover:border-mocha'
                }`}
              >
                {pkg.popularTag && (
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-espresso text-white text-xs font-medium px-4 py-1.5 rounded-full uppercase tracking-wider shadow-sm flex items-center gap-1.5 whitespace-nowrap">
                    <Clock className="w-3.5 h-3.5 fill-white text-white" />
                    <span>{pkg.popularTag}</span>
                  </div>
                )}

                <CardContent className="p-6 flex-1 flex flex-col justify-between space-y-6">
                  <div>
                    <div className="space-y-1">
                      <h3 className="font-serif text-2xl font-medium text-ink">
                        {pkg.title}
                      </h3>
                      <p className="text-xs text-secondary font-medium">{pkg.subtitle}</p>
                    </div>

                    <div className="mt-5 mb-3">
                      <div className="py-3 px-4 bg-sand/80 rounded-2xl border border-line flex items-center justify-between text-espresso shadow-xs">
                        <div>
                          <span className="text-[10px] font-bold uppercase tracking-wider text-secondary block">
                            Paket Ücreti
                          </span>
                          <span className="text-[11px] text-mocha font-medium block">{pkg.validity}</span>
                        </div>
                        <div className="text-right">
                          <span className="text-2xl font-extrabold text-espresso tracking-tight">
                            ₺{pkg.fiyat_tl ? pkg.fiyat_tl.toLocaleString('tr-TR') : '---'}
                          </span>
                        </div>
                      </div>
                    </div>

                    <ul className="space-y-3 pt-4 border-t border-line/60">
                      {pkg.features.map((feature, idx) => (
                        <li key={idx} className="flex items-start text-xs sm:text-sm text-ink/90">
                          <Check className="w-4 h-4 text-sage shrink-0 mr-2.5 mt-0.5" />
                          <span>{feature}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  <div className="pt-4">
                    <a
                      href={`https://wa.me/905316033080?text=${encodeURIComponent(
                        `Merhaba! Sobo Society'den ${pkg.title} (₺${pkg.fiyat_tl ? pkg.fiyat_tl.toLocaleString('tr-TR') : ''}) paketi hakkında bilgi almak ve satın almak istiyorum. Yardımcı olabilir misiniz?`
                      )}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="w-full block"
                    >
                      <Button variant={pkg.buttonVariant} className="w-full justify-center py-3 text-sm font-medium gap-2">
                        <MessageCircle className="w-4 h-4" />
                        <span>Fiyat Bilgisi & Satın Al (WhatsApp)</span>
                      </Button>
                    </a>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}

        {/* Member Advantages Section */}
        <div className="bg-sand-light rounded-card p-8 sm:p-12 border border-line shadow-sobo">
          <div className="text-center max-w-xl mx-auto mb-10 space-y-2">
            <Badge variant="sage" className="uppercase tracking-widest px-3 py-1 text-xs font-medium">
              Sobo Ayrıcalıkları
            </Badge>
            <h3 className="font-serif text-2xl sm:text-3xl font-medium text-ink">
              Neden Sobo Society?
            </h3>
            <p className="text-secondary text-sm">
              Üyelerimize sunduğumuz ayrıcalıklı stüdyo ve topluluk standartları.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {advantages.map((item, i) => {
              const Icon = item.icon
              return (
                <div key={i} className="space-y-3 text-center md:text-left group">
                  <div className="w-12 h-12 rounded-chip bg-white border border-line flex items-center justify-center text-espresso mx-auto md:mx-0 group-hover:scale-105 group-hover:border-mocha transition-all">
                    <Icon className="w-6 h-6" />
                  </div>
                  <h4 className="font-serif text-xl font-medium text-ink">
                    {item.title}
                  </h4>
                  <p className="text-xs text-secondary leading-relaxed">
                    {item.desc}
                  </p>
                </div>
              )
            })}
          </div>
        </div>

        {/* Official Studio Rules & Terms Section */}
        <div className="mt-12 bg-sand/60 rounded-card p-8 sm:p-10 border border-line shadow-xs space-y-8">
          <div className="text-center max-w-xl mx-auto space-y-2">
            <Badge variant="mocha" className="uppercase tracking-widest px-3 py-1 text-xs font-medium">
              Resmi Stüdyo & Paket Koşulları
            </Badge>
            <h3 className="font-serif text-2xl sm:text-3xl font-medium text-ink">
              Paket Kullanım Süreleri & Ders Kuralları
            </h3>
            <p className="text-secondary text-xs sm:text-sm">
              Spor verimliliği ve stüdyo düzenimiz için geçerli resmi kullanım esasları.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-2">
            {/* Validity Summary Table Card */}
            <div className="bg-ivory/90 p-6 rounded-2xl border border-line space-y-4 shadow-xs">
              <h4 className="font-serif text-lg font-bold text-espresso border-b border-line/60 pb-2">
                Paket Kullanım Süreleri
              </h4>
              <div className="space-y-2 text-xs text-ink font-medium">
                <div className="flex justify-between py-1.5 border-b border-line/40">
                  <span className="text-secondary font-bold">4 Derslik Paket</span>
                  <span className="font-bold text-espresso">30 Gün</span>
                </div>
                <div className="flex justify-between py-1.5 border-b border-line/40">
                  <span className="text-secondary font-bold">8 Derslik Paket (Mini)</span>
                  <span className="font-bold text-espresso">45 Gün</span>
                </div>
                <div className="flex justify-between py-1.5">
                  <span className="text-secondary font-bold">12 Derslik Paket (Standart)</span>
                  <span className="font-bold text-espresso">60 Gün</span>
                </div>
              </div>
              <p className="text-[11px] text-secondary italic leading-relaxed pt-2">
                * Belirtilen süreler üyenin haftada en az 2 derse katılımı esas alınarak spor verimliliği açısından hesaplanmıştır.
              </p>
            </div>

            {/* General Rules Card */}
            <div className="bg-ivory/90 p-6 rounded-2xl border border-line space-y-3 shadow-xs">
              <h4 className="font-serif text-lg font-bold text-espresso border-b border-line/60 pb-2">
                Genel Kurallar
              </h4>
              <ul className="space-y-2 text-xs text-ink/90 font-medium leading-relaxed">
                <li className="flex items-start gap-2">
                  <span className="text-espresso font-bold">•</span>
                  <span>Ders süreleri <strong>45 - 50 dakikadır</strong>.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-espresso font-bold">•</span>
                  <span>Ders saatine zamanında katılım üyenin sorumluluğundadır.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-espresso font-bold">•</span>
                  <span>Ders akışı için dersten en erken <strong>15 dakika önce</strong> stüdyoda bulunulması önerilir.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-espresso font-bold">•</span>
                  <span>Barre class dersleri min. 2 kişi olmak üzere <strong>2 - 5 kişilik</strong> butik gruplarla yapılır.</span>
                </li>
              </ul>
            </div>

            {/* Cancellation Rules Card */}
            <div className="bg-ivory/90 p-6 rounded-2xl border border-line space-y-3 shadow-xs">
              <h4 className="font-serif text-lg font-bold text-espresso border-b border-line/60 pb-2">
                İptal & Devamlılık
              </h4>
              <ul className="space-y-2 text-xs text-ink/90 font-medium leading-relaxed">
                <li className="flex items-start gap-2">
                  <span className="text-espresso font-bold">•</span>
                  <span>Ders iptal/değişiklik bildirimleri en geç <strong>12 saat önceden</strong> iletilmelidir.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-espresso font-bold">•</span>
                  <span>12 saatten az kala bildirilen iptallerde ders yapılmış sayılır.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-espresso font-bold">•</span>
                  <span>Süresi dolan paketler sistem tarafından otomatik kapatılır.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-espresso font-bold">•</span>
                  <span>Telafi dersleri uygun olan telafi gruplarına katılarak tamamlanır.</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
