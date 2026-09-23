'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import {
  Download,
  Smartphone,
  ShieldCheck,
  CheckCircle2,
  HelpCircle,
  AlertTriangle,
  Sparkles,
  BellRing,
  ChevronDown,
  ChevronUp,
  MessageSquare,
  Apple,
} from 'lucide-react'
import { Button } from '@/components/ui/button'

export function AppDownload() {
  const [showGuide, setShowGuide] = useState(false)

  const steps = [
    {
      num: '1',
      title: 'İndirmeyi Başlatın',
      desc: 'Yukarıdaki "Android APK İndir" butonuna tıklayın. İndirme işlemi doğrudan telefonunuza başlayacaktır.',
      badge: 'Doğrudan İndirme',
    },
    {
      num: '2',
      title: '"Yine de İndir" Seçeneğine Dokunun',
      desc: 'Google Play dışından indirilen tüm güvenli uygulamalarda Android sistemi standart olarak "Dosya zararlı olabilir" uyarısı verir. Bu stüdyomuzun orijinal uygulamasıdır; güvenle "Yine de İndir" butonuna dokunabilirsiniz.',
      badge: 'Standart Sistem Uyarısı',
      highlight: true,
    },
    {
      num: '3',
      title: 'Bilinmeyen Kaynaklara İzin Verin',
      desc: 'İndirme tamamlandığında bildirim çubuğundan sobosociety-app.apk dosyasına dokunun. Telefonunuz izin isterse "Ayarlar"a tıklayıp "Bu kaynaktan izin ver" seçeneğini aktif yapın.',
      badge: 'Bir Defaya Mahsus İzin',
    },
    {
      num: '4',
      title: 'Yükleyin & Bildirimleri Açın',
      desc: '"Yükle" butonuna dokunarak kurulumu tamamlayın. Uygulama açılışında sorulacak olan bildirim iznini onaylayarak ders telafi ve workshop duyurularını anında kilit ekranınızda görün.',
      badge: 'Anlık Bildirimler',
    },
  ]

  return (
    <section id="uygulama" className="py-24 bg-sand/35 relative border-b border-line/60 overflow-hidden">
      {/* Ambient background blur */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[500px] bg-sand-light/80 rounded-full blur-[140px] pointer-events-none" />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto space-y-4">
          <div className="inline-flex items-center space-x-2 bg-sand-light border border-line px-3.5 py-1.5 rounded-full shadow-xs">
            <Sparkles className="w-3.5 h-3.5 text-mocha" />
            <span className="text-[11px] font-bold uppercase tracking-[0.2em] text-espresso">
              Mobil Uygulama
            </span>
          </div>

          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-normal text-ink tracking-tight">
            Stüdyo Cebinizde. <br />
            <span className="italic text-espresso">İstediğiniz An Rezervasyon Yapın.</span>
          </h2>

          <p className="text-secondary text-sm sm:text-base leading-relaxed">
            Haftalık sabit ve telafi derslerinizi kolayca takip edin, tek dokunuşla yerinizi ayırtın ve
            özel workshop duyurularından anlık bildirimlerle ilk siz haberdar olun.
          </p>
        </div>

        {/* Feature Highlights Pills */}
        <div className="mt-8 flex flex-wrap items-center justify-center gap-2.5 max-w-2xl mx-auto text-xs text-secondary">
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/80 border border-line shadow-xs">
            <BellRing className="w-3.5 h-3.5 text-mocha" /> Anlık Push Bildirimleri
          </span>
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/80 border border-line shadow-xs">
            <ShieldCheck className="w-3.5 h-3.5 text-sage" /> Güvenli & Reklamsız
          </span>
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/80 border border-line shadow-xs">
            <Smartphone className="w-3.5 h-3.5 text-espresso" /> Otomatik Arka Plan Güncellemesi
          </span>
        </div>

        {/* Action Cards: Android & iOS */}
        <div className="mt-12 grid grid-cols-1 lg:grid-cols-12 gap-8 items-stretch max-w-5xl mx-auto">
          {/* Android Card (Featured) */}
          <div className="lg:col-span-7 bg-white rounded-3xl p-7 sm:p-9 border-2 border-espresso/15 shadow-sobo flex flex-col justify-between relative overflow-hidden">
            <div className="absolute top-0 right-0 bg-sage text-white text-[10px] font-bold tracking-widest uppercase px-4 py-1.5 rounded-bl-2xl">
              Doğrudan APK
            </div>

            <div className="space-y-6">
              <div className="flex items-center gap-3.5">
                <div className="w-12 h-12 rounded-2xl bg-sand flex items-center justify-center text-espresso shadow-xs">
                  <Smartphone className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="font-serif text-xl font-bold text-ink">
                    Android İçin Doğrudan İndir
                  </h3>
                  <p className="text-xs text-secondary mt-0.5">
                    Sürüm 1.0.4 • 63 MB • Android 8.0 ve üzeri
                  </p>
                </div>
              </div>

              <p className="text-xs sm:text-sm text-secondary leading-relaxed">
                Google Play bekleme süresi olmadan güncel Sobo Society uygulamasını hemen telefonunuza indirin.
                Tüm ders programı, rezervasyon, üyelik ve anlık bildirim özellikleri eksiksiz çalışır.
              </p>

              <div className="pt-2 flex flex-col sm:flex-row gap-3">
                <a
                  href="/sobosociety-app.apk"
                  download="sobosociety-app.apk"
                  className="flex-1"
                >
                  <Button variant="primary" size="lg" className="w-full gap-2.5 shadow-md">
                    <Download className="w-5 h-5" />
                    <span>Android APK İndir</span>
                  </Button>
                </a>

                <Button
                  variant="secondary"
                  size="lg"
                  onClick={() => setShowGuide(!showGuide)}
                  className="gap-2 border-line text-xs font-semibold"
                >
                  <HelpCircle className="w-4 h-4 text-mocha" />
                  <span>{showGuide ? 'Rehberi Gizle' : 'Nasıl Kurulur?'}</span>
                  {showGuide ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                </Button>
              </div>
            </div>

            <div className="mt-6 pt-5 border-t border-line/60 flex items-center justify-between text-[11px] text-secondary">
              <span className="flex items-center gap-1.5 text-sage font-medium">
                <ShieldCheck className="w-4 h-4 text-sage" /> SHA-256 Güvenli Orijinal Paket
              </span>
              <span>Otomatik Güncelleme Destekli</span>
            </div>
          </div>

          {/* iOS Card */}
          <div className="lg:col-span-5 bg-sand-light/60 rounded-3xl p-7 sm:p-9 border border-line shadow-xs flex flex-col justify-between">
            <div className="space-y-6">
              <div className="flex items-center gap-3.5">
                <div className="w-12 h-12 rounded-2xl bg-espresso text-white flex items-center justify-center shadow-xs">
                  <Apple className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="font-serif text-xl font-bold text-ink">
                    iOS (Apple)
                  </h3>
                  <p className="text-xs text-secondary mt-0.5">
                    iPhone & iPad Uyumlu
                  </p>
                </div>
              </div>

              <p className="text-xs sm:text-sm text-secondary leading-relaxed">
                iPhone kullanıcıları stüdyo uygulamamıza App Store üzerinden erişebilir veya web uygulamamız üzerinden
                tüm işlemlerini hızlıca tamamlayabilir.
              </p>

              <div className="pt-2">
                <Link href="/giris" className="w-full">
                  <Button variant="outline" size="lg" className="w-full gap-2 text-xs font-semibold">
                    <Smartphone className="w-4 h-4" />
                    <span>Web / iOS Girişi Yap</span>
                  </Button>
                </Link>
              </div>
            </div>

            <div className="mt-6 pt-5 border-t border-line/60 text-[11px] text-secondary flex items-center justify-between">
              <span>Apple Ekosistemi</span>
              <span className="font-medium text-espresso">Sobo Society Canlıda</span>
            </div>
          </div>
        </div>

        {/* Step-by-Step Installation Guide (Expandable or Open on Demand) */}
        {showGuide && (
          <div className="mt-10 max-w-4xl mx-auto bg-white rounded-3xl p-6 sm:p-9 border border-line shadow-sobo animate-in fade-in slide-in-from-top-4 duration-300">
            <div className="flex items-start justify-between pb-6 border-b border-line gap-4">
              <div>
                <div className="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-espresso bg-sand/60 px-3 py-1 rounded-full mb-2">
                  <HelpCircle className="w-3.5 h-3.5 text-mocha" />
                  <span>Android Kurulum Rehberi</span>
                </div>
                <h4 className="font-serif text-2xl font-bold text-ink">
                  4 Kolay Adımda Uygulamayı Yükleyin
                </h4>
                <p className="text-xs sm:text-sm text-secondary mt-1">
                  Google Play dışından indirilen APK dosyalarında Android telefonlar standart bir güvenlik teyidi ister. Aşağıdaki adımları takip ederek 30 saniyede tamamlayabilirsiniz:
                </p>
              </div>
              <button
                onClick={() => setShowGuide(false)}
                className="text-xs text-secondary hover:text-espresso font-semibold p-2"
              >
                Kapat ✕
              </button>
            </div>

            {/* Warning Callout Box */}
            <div className="mt-6 p-4 rounded-2xl bg-amber-50/70 border border-amber-200/80 flex items-start gap-3">
              <AlertTriangle className="w-5 h-5 text-amber-700 shrink-0 mt-0.5" />
              <div className="text-xs text-amber-900 leading-relaxed">
                <strong className="font-bold text-amber-950">Önemli Not:</strong> İndirme anında karşınıza çıkan <em>&quot;Dosya zararlı olabilir&quot;</em> veya <em>&quot;Bilinmeyen kaynak&quot;</em> uyarısı, Google&apos;ın Play Store dışındaki tüm APK indirmelerinde gösterdiği standart bir bilgilendirmedir. Sobo Society uygulaması stüdyomuz tarafından güvenle derlenmiştir, gönül rahatlığıyla <strong>&quot;Yine de İndir&quot;</strong> butonuna basabilirsiniz.
              </div>
            </div>

            {/* Step Grid */}
            <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
              {steps.map((st) => (
                <div
                  key={st.num}
                  className={`p-5 rounded-2xl border transition-all ${
                    st.highlight
                      ? 'bg-sand/30 border-mocha/40'
                      : 'bg-sand-light/40 border-line'
                  }`}
                >
                  <div className="flex items-center justify-between mb-3">
                    <span className="w-7 h-7 rounded-full bg-espresso text-white text-xs font-bold flex items-center justify-center">
                      {st.num}
                    </span>
                    <span className="text-[10px] font-bold uppercase tracking-wider text-mocha bg-white px-2.5 py-0.5 rounded-full border border-line">
                      {st.badge}
                    </span>
                  </div>
                  <h5 className="font-serif text-base font-bold text-ink mb-1.5">
                    {st.title}
                  </h5>
                  <p className="text-xs text-secondary leading-relaxed">
                    {st.desc}
                  </p>
                </div>
              ))}
            </div>

            {/* WhatsApp Assistance Bar */}
            <div className="mt-6 pt-5 border-t border-line/60 flex flex-col sm:flex-row items-center justify-between gap-4">
              <div className="text-xs text-secondary text-center sm:text-left">
                Kurulumda yardıma mı ihtiyacınız var? Stüdyo ekibimiz size anında destek vermekten mutluluk duyar.
              </div>
              <a
                href="https://wa.me/905316033080?text=Merhaba,%20Sobo%20Society%20Android%20uygulamasi%20kurulumunda%20yardim%20alabilir%20miyim?"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Button variant="emerald" size="sm" className="gap-2 text-xs font-semibold whitespace-nowrap">
                  <MessageSquare className="w-3.5 h-3.5 text-white" />
                  <span>WhatsApp ile Destek Al</span>
                </Button>
              </a>
            </div>
          </div>
        )}
      </div>
    </section>
  )
}
