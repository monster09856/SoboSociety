'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { Calendar, Users, Sparkles, MapPin, Clock, MessageCircle, ArrowRight, CheckCircle2, Compass, Lock } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { api } from '@/lib/api'
import { isAuthenticated } from '@/lib/auth'

interface WorkshopItem {
  id: number
  baslik: string
  turu: string
  tarih_saat: string
  aciklama: string
  kontenjan: number
  dolu_sayi: number
  ucret: string
  tek_katilim_acik?: boolean
  tek_katilim_ucret_tl?: number
  aktif: boolean
}

export function Workshops() {
  const [events, setEvents] = useState<WorkshopItem[]>([])
  const [loading, setLoading] = useState(true)
  const [isLoggedIn, setIsLoggedIn] = useState(false)

  useEffect(() => {
    setIsLoggedIn(isAuthenticated())
  }, [])

  useEffect(() => {
    async function fetchEvents() {
      try {
        const data = await api.events.list()
        if (data && data.length > 0) {
          setEvents(data)
        } else {
          setEvents(defaultWorkshops)
        }
      } catch (err) {
        console.error('Workshoplar çekilemedi:', err)
        setEvents(defaultWorkshops)
      } finally {
        setLoading(false)
      }
    }
    fetchEvents()
  }, [])

  const defaultWorkshops: WorkshopItem[] = [
    {
      id: 1,
      baslik: 'Belgrad Ormanı Doğa Yürüyüşü & Kahve Buluşması',
      turu: 'Doğa Yürüyüşü',
      tarih_saat: 'Cumartesi, 09:30',
      aciklama: 'Temiz havada yürüyüş, nefes egzersizleri ve ardından tüm Sobo topluluğu ile kahve sohbeti.',
      kontenjan: 20,
      dolu_sayi: 12,
      ucret: 'Ücretsiz / Topluluk Etkinliği',
      aktif: true,
    },
    {
      id: 2,
      baslik: 'Ses Çanağı & Derin Meditasyon (Sound Bath)',
      turu: 'Sound Bath',
      tarih_saat: 'Pazar, 18:00',
      aciklama: 'Tibet ses çanaklarının şifalı frekansları eşliğinde derin zihinsel ve bedensel dinlenme seansı.',
      kontenjan: 12,
      dolu_sayi: 8,
      ucret: '750 ₺',
      aktif: true,
    },
    {
      id: 3,
      baslik: 'Postür, Omurga & Mobilite Masterclass',
      turu: 'Masterclass',
      tarih_saat: 'Cuma, 19:30',
      aciklama: 'Masa başı çalışanlar için özel omurga sağlığı, duruş bozukluklarını düzeltici teknikler ve mobilite çalışması.',
      kontenjan: 10,
      dolu_sayi: 6,
      ucret: '600 ₺',
      aktif: true,
    },
  ]

  const getCategoryIcon = (turu: string) => {
    const t = turu.toLowerCase()
    if (t.includes('yürüyüş') || t.includes('doğa')) return Compass
    if (t.includes('sound') || t.includes('ses') || t.includes('meditasyon')) return Sparkles
    return Calendar
  }

  return (
    <section id="workshoplar" className="py-24 bg-sand-light/60 relative border-b border-line/60 overflow-hidden">
      {/* Background Decorative Blur Element */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-sand/80 rounded-full blur-3xl -z-10 pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        {/* Header */}
        <div className="text-center max-w-2xl mx-auto mb-16 space-y-4">
          <Badge variant="mocha" className="uppercase tracking-widest px-3.5 py-1 text-xs font-medium">
            Topluluk & Özel Atölyeler
          </Badge>
          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-medium text-ink tracking-tight">
            Workshop & Etkinlikler
          </h2>
          <p className="text-secondary text-base leading-relaxed">
            Doğa yürüyüşlerinden ses çanağı meditasyonuna, kahve buluşmalarından özel masterclass serilerine kadar Sobo Society ayrıcalıkları.
          </p>
        </div>

        {/* Grid of Event Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-14">
          {events.map((ev) => {
            const Icon = getCategoryIcon(ev.turu)
            const kalan = Math.max(0, ev.kontenjan - ev.dolu_sayi)
            const dolulukYuzde = ev.kontenjan > 0 ? Math.min(100, Math.round((ev.dolu_sayi / ev.kontenjan) * 100)) : 0

            return (
              <Card
                key={ev.id}
                className="bg-ivory border-line hover:border-mocha transition-all duration-300 shadow-sobo hover:shadow-sobo-md flex flex-col justify-between group rounded-card overflow-hidden"
              >
                <CardContent className="p-7 flex-1 flex flex-col justify-between space-y-6">
                  <div className="space-y-4">
                    {/* Top Row: Category Badge & Status */}
                    <div className="flex items-center justify-between">
                      <Badge variant="sage" className="gap-1.5 px-3 py-1 text-[11px] font-semibold tracking-wide">
                        <Icon className="w-3.5 h-3.5" />
                        <span>{ev.turu}</span>
                      </Badge>
                      {ev.kontenjan > 0 && (
                        <span className={`text-[11px] font-bold px-2.5 py-1 rounded-full ${
                          kalan === 0
                            ? 'bg-rose-100 text-rose-700'
                            : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                        }`}>
                          {kalan === 0 ? 'Kontenjan Doldu' : `${kalan} Koltuk Kaldı`}
                        </span>
                      )}
                    </div>

                    {/* Title */}
                    <h3 className="font-serif text-2xl font-medium text-ink group-hover:text-espresso transition-colors leading-snug">
                      {ev.baslik}
                    </h3>

                    {/* Date / Time & Fee Bar */}
                    <div className="bg-sand/70 p-3.5 rounded-2xl border border-line/60 space-y-2 text-xs">
                      <div className="flex items-center justify-between text-espresso font-semibold">
                        <div className="flex items-center gap-2">
                          <Clock className="w-4 h-4 text-mocha shrink-0" />
                          <span>{ev.tarih_saat}</span>
                        </div>
                        {isLoggedIn ? (
                          <span className="font-bold text-ink">{ev.ucret}</span>
                        ) : (
                          <span className="font-semibold text-mocha flex items-center gap-1 bg-ivory px-2.5 py-1 rounded-full border border-line">
                            <Lock className="w-3 h-3 text-mocha" />
                            <span>Üyelere Özel</span>
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Description */}
                    <p className="text-xs text-secondary leading-relaxed pt-1">
                      {ev.aciklama}
                    </p>
                  </div>

                  {/* Progress Bar & Actions */}
                  <div className="space-y-4 pt-4 border-t border-line/60">
                    {ev.kontenjan > 0 && (
                      <div className="space-y-1">
                        <div className="flex justify-between text-[11px] font-medium text-secondary">
                          <span>Katılımcı Durumu</span>
                          <span className="font-semibold text-ink">{ev.dolu_sayi} / {ev.kontenjan} Kayıtlı</span>
                        </div>
                        <div className="w-full bg-sand rounded-full h-1.5 overflow-hidden border border-line/40">
                          <div
                            className="bg-espresso h-full rounded-full transition-all duration-500"
                            style={{ width: `${dolulukYuzde}%` }}
                          />
                        </div>
                      </div>
                    )}

                    <div className="flex flex-col sm:flex-row gap-2">
                      <a
                        href={`https://wa.me/905316033080?text=${encodeURIComponent(
                          `Merhaba! Sobo Society'nin "${ev.baslik}" (${ev.tarih_saat}) etkinliği hakkında bilgi almak ve yerimi ayırtmak istiyorum.`
                        )}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex-1"
                      >
                        <Button variant="secondary" className="w-full text-xs font-medium justify-center gap-1.5 py-2.5">
                          <MessageCircle className="w-3.5 h-3.5" />
                          <span>WhatsApp İle Kayıt</span>
                        </Button>
                      </a>
                      <Link href="/giris" className="flex-1">
                        <Button variant="primary" className="w-full text-xs font-medium justify-center gap-1 py-2.5">
                          <span>Uygulamada Aç</span>
                          <ArrowRight className="w-3.5 h-3.5" />
                        </Button>
                      </Link>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )
          })}
        </div>

        {/* Note banner */}
        <div className="bg-sand/80 rounded-2xl p-6 border border-line max-w-3xl mx-auto text-center space-y-2">
          <div className="flex items-center justify-center gap-2 text-espresso font-serif text-lg font-medium">
            <Sparkles className="w-5 h-5 text-mocha" />
            <span>Tüm Workshop & Etkinlikler Sobo Mobil Uygulamasında!</span>
          </div>
          <p className="text-xs text-secondary leading-relaxed max-w-xl mx-auto">
            Mobil uygulamamızı indirerek yeni eklenen tüm workshop ve topluluk etkinliklerinden anında push bildirimi alabilir ve tek tıkla kaydolabilirsiniz.
          </p>
        </div>
      </div>
    </section>
  )
}
