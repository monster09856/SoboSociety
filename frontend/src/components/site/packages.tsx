import React from 'react'
import Link from 'next/link'
import { Check, Star, ShieldCheck, Zap, Users, Sparkles } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'

export function Packages() {
  const packagesList = [
    {
      title: 'Sobo Trial',
      subtitle: 'Tekli Deneme Dersi',
      price: '650 ₺',
      validity: '14 Gün Geçerli',
      isPopular: false,
      features: [
        '1 Adet Stüdyo Ders Hakkı',
        'Birebir Postür & Seviye Analizi',
        'Tüm Ders Türlerinde Geçerli (Barre/Pilates)',
        'Dolap & Mat Kullanımı Dahil',
      ],
      buttonVariant: 'secondary' as const,
    },
    {
      title: 'Sobo Starter',
      subtitle: '5 Derslik Paket',
      price: '2.800 ₺',
      validity: '45 Gün Geçerli',
      isPopular: false,
      features: [
        '5 Adet Stüdyo Ders Hakkı',
        'Esnek İptal (4 Saat Öncesine Kadar)',
        'Bekleme Listesi Önceliği',
        'Mobil Uygulama İle Kolay Takip',
      ],
      buttonVariant: 'secondary' as const,
    },
    {
      title: 'Sobo Core',
      subtitle: '10 Derslik Paket',
      price: '5.200 ₺',
      validity: '60 Gün Geçerli',
      isPopular: true,
      popularTag: 'En Çok Tercih Edilen 🏆',
      features: [
        '10 Adet Stüdyo Ders Hakkı',
        '1 Adet Ücretsiz Misafir Getirme Hakkı',
        'Esnek İptal & Bakiye İadesi',
        'Gelişim & Katılım İstatistikleri',
      ],
      buttonVariant: 'primary' as const,
    },
    {
      title: 'Society Pass',
      subtitle: '20 Derslik Elite Paket',
      price: '9.600 ₺',
      validity: '90 Gün Geçerli',
      isPopular: false,
      features: [
        '20 Adet Stüdyo Ders Hakkı',
        '7 Gün Önceden Erken Rezervasyon',
        'Özel Topluluk Workshop Davetiyeleri',
        '2 Adet Misafir Getirme Hakkı',
      ],
      buttonVariant: 'secondary' as const,
    },
  ]

  const advantages = [
    {
      icon: Users,
      title: 'Butik Kontenjan (Max 8)',
      desc: 'Kalabalık salonlar yok. Her derste kişiye özel ilgi ve doğru form kontrolü.',
    },
    {
      icon: Zap,
      title: 'Esnek İptal & Bakiye Koruma',
      desc: 'Derse 4 saat kalana kadar tek tıkla iptal edin, kredinizi kaybetmeyin.',
    },
    {
      icon: ShieldCheck,
      title: 'Uzman Eğitmen Kadrosu',
      desc: 'Uluslararası sertifikalı eğitmenler eşliğinde güvenli ve etkili antrenman.',
    },
    {
      icon: Sparkles,
      title: 'Sobo Community & Etkinlikler',
      desc: 'Sadece bir stüdyo değil; özel davetler, kahve buluşmaları ve atölyeler.',
    },
  ]

  return (
    <section id="paketler" className="py-24 bg-ivory relative border-b border-line/60">
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Title */}
        <div className="text-center max-w-2xl mx-auto mb-16 space-y-4">
          <Badge variant="mocha" className="uppercase tracking-widest px-3.5 py-1 text-xs font-medium">
            Üyelik & Ders Paketleri
          </Badge>
          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-medium text-ink tracking-tight">
            Esnek Ders Paketleri
          </h2>
          <p className="text-secondary text-base leading-relaxed">
            Taahhüt yok, gizli ücret yok. İhtiyacınıza en uygun paketi seçin ve topluluğumuzun bir parçası olun.
          </p>
        </div>

        {/* Pricing Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-20 items-stretch">
          {packagesList.map((pkg) => (
            <Card
              key={pkg.title}
              className={`relative flex flex-col justify-between transition-all duration-300 ${
                pkg.isPopular
                  ? 'bg-sand-light border-2 border-espresso shadow-sobo-md scale-[1.02] z-10'
                  : 'bg-sand-light border-line hover:border-mocha'
              }`}
            >
              {pkg.isPopular && (
                <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-espresso text-white text-xs font-medium px-4 py-1.5 rounded-full uppercase tracking-wider shadow-sm flex items-center gap-1.5 whitespace-nowrap">
                  <Star className="w-3.5 h-3.5 fill-white text-white" />
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
                    <span className="font-serif text-4xl font-normal text-espresso">
                      {pkg.price}
                    </span>
                    <span className="text-xs text-muted block mt-1 font-medium">{pkg.validity}</span>
                  </div>

                  <ul className="space-y-3 pt-5 border-t border-line/60">
                    {pkg.features.map((feature, idx) => (
                      <li key={idx} className="flex items-start text-xs sm:text-sm text-ink/90">
                        <Check className="w-4 h-4 text-sage shrink-0 mr-2.5 mt-0.5" />
                        <span>{feature}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="pt-4">
                  <Link href="/giris" className="w-full block">
                    <Button variant={pkg.buttonVariant} className="w-full justify-center py-3 text-sm font-medium">
                      Paketi Seç
                    </Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

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
      </div>
    </section>
  )
}
