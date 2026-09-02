import React from 'react'
import Link from 'next/link'
import { MapPin, Instagram, MessageSquare, Mail, Phone } from 'lucide-react'

export function Footer() {
  return (
    <footer id="iletisim" className="bg-sand-light/70 text-ink pt-16 pb-12 relative overflow-hidden border-t border-line">
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-10 pb-12 border-b border-line">
          {/* Brand Info */}
          <div className="space-y-4 md:col-span-1">
            <Link href="/" className="flex items-center space-x-2 group">
              <div className="flex flex-col">
                <span className="font-serif text-2xl font-medium tracking-[0.2em] text-ink group-hover:text-espresso transition-colors">
                  SOBO SOCIETY
                </span>
                <span className="text-[9px] uppercase tracking-[0.35em] text-mocha font-light -mt-1">
                  WELLNESS STUDIO
                </span>
              </div>
            </Link>
            <p className="text-secondary text-xs leading-relaxed max-w-sm">
              Barre, Pilates ve Functional antrenman metotlarını modern şehir insanı için yüksek enerji ve rafine bir atmosferde harmanlayan butik stüdyo topluluğu.
            </p>
          </div>

          {/* Quick Links */}
          <div className="space-y-3">
            <h4 className="font-serif text-lg font-medium text-ink tracking-wide">
              Hızlı Bağlantılar
            </h4>
            <ul className="space-y-2.5 text-xs text-secondary">
              <li>
                <a href="#dersler" className="hover:text-espresso transition-colors">
                  Dersler (Barre, Pilates & Functional)
                </a>
              </li>
              <li>
                <a href="#canli-program" className="hover:text-espresso transition-colors">
                  Haftalık Canlı Program & Doluluk
                </a>
              </li>
              <li>
                <a href="#paketler" className="hover:text-espresso transition-colors">
                  Üyelik & Paket Fiyatları
                </a>
              </li>
              <li>
                <Link href="/giris" className="hover:text-espresso transition-colors">
                  Üye Girişi / Rezervasyon
                </Link>
              </li>
            </ul>
          </div>

          {/* Contact Details */}
          <div className="space-y-3">
            <h4 className="font-serif text-lg font-medium text-ink tracking-wide">
              Stüdyo Konumu
            </h4>
            <div className="space-y-3 text-xs text-secondary">
              <div className="flex items-start gap-2.5">
                <MapPin className="w-4 h-4 text-mocha shrink-0 mt-0.5" />
                <span>Teşvikiye, Abdi İpekçi Cd. No:42, Nişantaşı / İstanbul</span>
              </div>
              <div className="flex items-center gap-2.5">
                <Phone className="w-4 h-4 text-mocha shrink-0" />
                <a href="tel:+905316033080" className="hover:text-espresso transition-colors">+90 531 603 30 80</a>
              </div>
              <div className="flex items-center gap-2.5">
                <Mail className="w-4 h-4 text-mocha shrink-0" />
                <span>hello@thesobosociety.com</span>
              </div>
            </div>
          </div>

          {/* Social & WhatsApp Buttons */}
          <div className="space-y-3">
            <h4 className="font-serif text-lg font-medium text-ink tracking-wide">
              İletişim & Sosyal Medya
            </h4>
            <div className="space-y-3 pt-1">
              <a
                href="https://wa.me/905316033080"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2.5 text-xs font-medium bg-sage hover:bg-sage/90 border border-sage/40 px-4 py-3 rounded-input text-white shadow-xs transition-all w-full cursor-pointer"
              >
                <MessageSquare className="w-4 h-4 text-white" />
                <span>WhatsApp İletişim Hattı</span>
              </a>

              <a
                href="https://instagram.com/thesobosociety"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2.5 text-xs font-medium bg-espresso hover:bg-espresso-dark px-4 py-3 rounded-input text-white shadow-xs transition-all w-full cursor-pointer"
              >
                <Instagram className="w-4 h-4 text-white" />
                <span>@thesobosociety (Instagram)</span>
              </a>
            </div>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-secondary">
          <p>© {new Date().getFullYear()} Sobo Society. Tüm hakları saklıdır.</p>
          <div className="flex items-center gap-4">
            <Link href="/gizlilik" className="hover:text-espresso underline transition-colors">
              Gizlilik Politikası & KVKK
            </Link>
            <span>•</span>
            <Link href="/privacy" className="hover:text-espresso underline transition-colors">
              Privacy Policy
            </Link>
          </div>
        </div>
      </div>
    </footer>
  )
}
