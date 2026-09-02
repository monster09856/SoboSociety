import React from 'react'
import Link from 'next/link'
import { ArrowRight, Sparkles, HeartHandshake, Flame, Sun } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'

export function Hero() {
  const disciplines = [
    {
      title: 'Barre',
      desc: 'Bale, pilates ve fonksiyonel antrenmanı birleştiren, küçük ve kontrollü hareketlerle tüm vücudu güçlendiren ve şekillendiren dinamik bir antrenman seansı.',
      icon: Sparkles,
      tag: 'Zarafet & Güç',
      badgeVariant: 'mocha' as const,
      iconBg: 'bg-sand text-espresso border-line',
    },
    {
      title: 'Pilates',
      desc: 'Omurga sağlığı, postür düzeltme ve derin çekirdek (core) kuvvetini maksimum stabilite ve hizalanma ile geliştiren seanslar.',
      icon: HeartHandshake,
      tag: 'Postür & Denge',
      badgeVariant: 'sage' as const,
      iconBg: 'bg-sage/10 text-sage border-sage/20',
    },
    {
      title: 'Yoga',
      desc: 'Nefes ve hareketi bir araya getirerek esneklik, denge ve gücü geliştiren; bedeni ve zihni bütünsel olarak destekleyen seanslar.',
      icon: Sun,
      tag: 'Nefes & Denge',
      badgeVariant: 'clay' as const,
      iconBg: 'bg-clay/10 text-clay border-clay/20',
    },
  ]

  return (
    <section className="relative overflow-hidden bg-ivory pt-16 pb-24 md:pt-24 md:pb-32 border-b border-line/60">
      {/* Subtle organic ambient background gradients */}
      <div className="absolute top-[-100px] right-[-100px] -z-0 w-[600px] h-[600px] bg-sand-light/60 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-[-100px] left-[-100px] -z-0 w-[500px] h-[500px] bg-ivory-dark/40 rounded-full blur-[140px] pointer-events-none" />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-4xl mx-auto space-y-8">
          {/* Studio Atmosphere Badge */}
          <div className="inline-flex items-center space-x-2.5 bg-sand-light border border-line px-4 py-2 rounded-full shadow-xs">
            <span className="relative flex h-2.5 w-2.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-sage opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-sage"></span>
            </span>
            <span className="text-xs uppercase tracking-[0.2em] text-ink font-medium">
              Uydukent • Afyonkarahisar Stüdyosu
            </span>
          </div>

          {/* Main Headline */}
          <h1 className="font-serif text-4xl sm:text-6xl md:text-7xl lg:text-8xl font-normal text-ink tracking-tight leading-[1.08]">
            Not just a studio. <br />
            <span className="font-serif italic font-normal text-espresso">
              It&apos;s a society.
            </span>
          </h1>

          {/* Subtitle */}
          <p className="text-secondary text-base sm:text-lg md:text-xl font-normal leading-relaxed max-w-2xl mx-auto">
            <strong className="text-ink font-medium">Barre</strong>, <strong className="text-ink font-medium">Pilates</strong>, <strong className="text-ink font-medium">Yoga</strong> ve <strong className="text-ink font-medium">Functional Training</strong>’i; hareket, denge ve iyi yaşam odağında, SOBO’nun butik atmosferi ve topluluk ruhuyla buluşturuyoruz.
          </p>

          {/* Action CTA Buttons */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
            <a href="#canli-program" className="w-full sm:w-auto">
              <Button variant="primary" size="lg" className="w-full sm:w-auto gap-2.5 text-base">
                <span>Ders Programı & Rezervasyon</span>
                <ArrowRight className="w-5 h-5" />
              </Button>
            </a>
            <a href="#paketler" className="w-full sm:w-auto">
              <Button variant="secondary" size="lg" className="w-full sm:w-auto text-base">
                <span>Ders Paketlerini İncele</span>
              </Button>
            </a>
          </div>

          {/* Key Stats Strip */}
          <div className="pt-10 grid grid-cols-3 gap-6 max-w-lg mx-auto border-t border-line/60">
            <div>
              <div className="font-serif text-3xl sm:text-4xl font-medium text-ink">Max 5</div>
              <div className="text-xs text-muted uppercase tracking-wider font-medium mt-1">Butik Sınıf</div>
            </div>
            <div>
              <div className="font-serif text-3xl sm:text-4xl font-medium text-espresso">50 dk</div>
              <div className="text-xs text-muted uppercase tracking-wider font-medium mt-1">Özel Seans</div>
            </div>
            <div>
              <div className="font-serif text-3xl sm:text-4xl font-medium text-sage">%100</div>
              <div className="text-xs text-muted uppercase tracking-wider font-medium mt-1">Kişiye Özel İlgi</div>
            </div>
          </div>
        </div>

        {/* Core Disciplines Showcase (Barre / Pilates / Functional) */}
        <div id="dersler" className="mt-20 grid grid-cols-1 md:grid-cols-3 gap-6">
          {disciplines.map((item) => {
            const Icon = item.icon
            return (
              <div
                key={item.title}
                className="group relative bg-sand-light border border-line p-8 rounded-card transition-all duration-300 hover:border-mocha hover:shadow-sobo-md cursor-pointer"
              >
                <div className="flex items-center justify-between mb-6">
                  <div className={`w-12 h-12 rounded-chip border flex items-center justify-center transition-transform group-hover:scale-105 ${item.iconBg}`}>
                    <Icon className="w-6 h-6" />
                  </div>
                  <Badge variant={item.badgeVariant}>
                    {item.tag}
                  </Badge>
                </div>
                <h3 className="font-serif text-2xl sm:text-3xl font-medium text-ink mb-3">
                  {item.title}
                </h3>
                <p className="text-secondary text-sm leading-relaxed">
                  {item.desc}
                </p>
                <div className="mt-6 pt-4 border-t border-line/60 flex items-center text-xs font-medium text-espresso opacity-90 group-hover:opacity-100 transition-opacity">
                  <span>Ders Detaylarını Gör</span>
                  <ArrowRight className="w-3.5 h-3.5 ml-1 group-hover:translate-x-1 transition-transform" />
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
