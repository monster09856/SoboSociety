import React from 'react'
import Link from 'next/link'
import { Navigation } from '@/components/site/navigation'
import { Footer } from '@/components/site/footer'
import { Shield, Lock, Trash2, Mail, Phone, Calendar, ArrowLeft } from 'lucide-react'
import { Badge } from '@/components/ui/badge'

export const metadata = {
  title: 'Gizlilik Politikası & KVKK Aydınlatma Metni | SOBO Society',
  description: 'SOBO Society Wellness Studio kişisel verilerin korunması, gizlilik politikası ve Apple App Store uyumluluk şartları.',
}

export default function GizlilikPolitikasiPage() {
  return (
    <div className="min-h-screen bg-ivory text-ink font-sans antialiased flex flex-col justify-between">
      <Navigation />

      <main className="py-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        {/* Header */}
        <div className="space-y-4 text-center sm:text-left border-b border-line pb-8">
          <Link href="/" className="inline-flex items-center gap-2 text-xs font-bold text-secondary hover:text-espresso transition-colors mb-2">
            <ArrowLeft className="w-4 h-4" />
            <span>Ana Sayfaya Dön</span>
          </Link>
          <div className="flex flex-wrap items-center gap-3">
            <Badge variant="mocha" className="uppercase tracking-widest text-[11px]">
              Resmi Aydınlatma Metni
            </Badge>
            <span className="text-xs text-secondary font-medium">Son Güncelleme: 2 Eylül 2026</span>
          </div>
          <h1 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-ink">
            Gizlilik Politikası & KVKK Metni
          </h1>
          <p className="text-secondary text-sm sm:text-base leading-relaxed">
            SOBO Society Wellness Studio olarak kişisel verilerinizin güvenliğine ve gizliliğinize en yüksek düzeyde önem veriyoruz. Bu politika, mobil uygulamamızı ve web sitemizi kullanırken toplanan verilerin kapsamını ve kullanım amaçlarını açıklar.
          </p>
        </div>

        {/* Highlight Summary Card */}
        <div className="bg-sand/60 rounded-2xl p-6 border border-line space-y-4">
          <div className="flex items-center gap-3 text-espresso">
            <Shield className="w-6 h-6 shrink-0" />
            <h2 className="font-serif text-xl font-bold text-ink">Özet Taahhütlerimiz</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs text-ink/90 font-medium">
            <div className="p-3 bg-ivory rounded-xl border border-line/60">
              <strong className="block text-espresso mb-1">🔒 Veri Güvenliği</strong>
              Tüm veri transferleri 256-bit SSL/TLS şifrelemeyle korunur.
            </div>
            <div className="p-3 bg-ivory rounded-xl border border-line/60">
              <strong className="block text-espresso mb-1">❌ Üçüncü Taraflara Satılmaz</strong>
              Kişisel verileriniz asla reklam veya pazarlama amaçlı satılmaz.
            </div>
            <div className="p-3 bg-ivory rounded-xl border border-line/60">
              <strong className="block text-espresso mb-1">📱 Sadece Gerekli Veriler</strong>
              Sadece ders rezervasyonu ve hesap doğrulaması için gereken veriler işlenir.
            </div>
            <div className="p-3 bg-ivory rounded-xl border border-line/60">
              <strong className="block text-espresso mb-1">🗑️ Hesabı & Verileri Silme Hakkı</strong>
              İstediğiniz an hesabınızı ve tüm verilerinizi tamamen sildirebilirsiniz.
            </div>
          </div>
        </div>

        {/* Detailed Sections */}
        <div className="space-y-10 text-sm text-ink/90 leading-relaxed font-normal">
          {/* Section 1 */}
          <section className="space-y-3">
            <h3 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <span className="text-espresso font-sans text-lg">1.</span>
              <span>Veri Sorumlusu</span>
            </h3>
            <p>
              6698 sayılı Kişisel Verilerin Korunması Kanunu (&quot;KVKK&quot;) ve ilgili mevzuat uyarınca, <strong>SOBO Society Wellness Studio</strong> (&quot;Şirket&quot; veya &quot;Stüdyo&quot;), mobil uygulama ve web platformları üzerinden toplanan kişisel verileriniz bakımından Veri Sorumlusu sıfatına sahiptir.
            </p>
          </section>

          {/* Section 2 */}
          <section className="space-y-3">
            <h3 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <span className="text-espresso font-sans text-lg">2.</span>
              <span>Toplanan Kişisel Veriler ve Amaçları</span>
            </h3>
            <p>Uygulamamız ve web sitemiz aracılığıyla aşağıdaki kişisel veriler işlenmektedir:</p>
            <ul className="list-disc pl-5 space-y-2 text-xs sm:text-sm">
              <li>
                <strong>Kimlik ve İletişim Bilgileri:</strong> Ad, soyad ve cep telefonu numarası (SMS OTP ile güvenli giriş yapmak, üyelik profili oluşturmak ve rezervasyon teyidi sağlamak amacıyla).
              </li>
              <li>
                <strong>Ders ve İşlem Bilgileri:</strong> Katıldığınız dersler, ders paketleriniz, kalan kredi bakiyeniz ve yoklama kayıtlarınız.
              </li>
              <li>
                <strong>Cihaz ve Bildirim Bilgileri:</strong> İzniniz dahilinde gönderilen ders hatırlatmaları ve stüdyo duyuruları için cihaz Push Notification belirteci (token).
              </li>
            </ul>
          </section>

          {/* Section 3 */}
          <section className="space-y-3">
            <h3 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <span className="text-espresso font-sans text-lg">3.</span>
              <span>Verilerin Aktarımı ve Üçüncü Taraf Hizmetler</span>
            </h3>
            <p>
              Kişisel verileriniz, yalnızca hizmetin ifası için zorunlu olan altyapı sağlayıcıları ile paylaşılır:
            </p>
            <ul className="list-disc pl-5 space-y-2 text-xs sm:text-sm">
              <li>
                <strong>SMS Doğrulama Sağlayıcısı (İletimerkezi / Netgsm):</strong> Tek kullanımlık şifre (OTP) SMS gönderimi amacıyla cep telefonu numaranız güvenli API entegrasyonuyla iletilir.
              </li>
              <li>
                <strong>Push Bildirim Altyapısı:</strong> Ders hatırlatması ve stüdyo bildirimlerinin iletilmesi amacıyla.
              </li>
            </ul>
            <p className="text-xs text-secondary italic">
              Verileriniz kesinlikle üçüncü taraf reklam ağlarına, veri simsarlarına veya pazarlama şirketlerine aktarılmaz.
            </p>
          </section>

          {/* Section 4 */}
          <section className="space-y-3">
            <h3 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <span className="text-espresso font-sans text-lg">4.</span>
              <span>Apple App Store İnceleme ve Hesap Silme Şartı (Account Deletion)</span>
            </h3>
            <p>
              Apple App Store İnceleme Yönergeleri (Madde 5.1.1(v)) uyarınca, uygulamamız üzerinden hesap oluşturan tüm kullanıcılar diledikleri zaman hesaplarını ve ilişkili tüm verilerini sildirme hakkına sahiptir.
            </p>
            <div className="p-4 bg-sand/40 border border-line rounded-xl space-y-2 text-xs">
              <strong className="block text-espresso text-sm font-bold">Hesabınızı ve Verilerinizi Nasıl Silebilirsiniz?</strong>
              <p>
                Uygulama içerisindeki <strong>Hesabım ➔ Hesabı Sil</strong> seçeneğini kullanarak veya stüdyomuza <a href="mailto:info@thesobosociety.com" className="underline text-espresso font-bold">info@thesobosociety.com</a> adresinden kayıtlı telefon numaranızla talep göndererek hesabınızın ve geçmiş verilerinizin 48 saat içerisinde sistemlerimizden kalıcı olarak silinmesini sağlayabilirsiniz.
              </p>
            </div>
          </section>

          {/* Section 5 */}
          <section className="space-y-3">
            <h3 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <span className="text-espresso font-sans text-lg">5.</span>
              <span>Kullanıcı Hakları (KVKK Madde 11)</span>
            </h3>
            <p>KVKK&apos;nın 11. maddesi kapsamında aşağıdaki haklara sahipsiniz:</p>
            <ul className="list-disc pl-5 space-y-1.5 text-xs sm:text-sm">
              <li>Kişisel verilerinizin işlenip işlenmediğini öğrenme,</li>
              <li>İşlenmişse buna ilişkin bilgi talep etme,</li>
              <li>Verilerin düzeltilmesini veya silinmesini isteme,</li>
              <li>Verilerinize erişim sağlama ve kopyasını talep etme.</li>
            </ul>
          </section>

          {/* Section 6 */}
          <section className="space-y-3 pt-4 border-t border-line">
            <h3 className="font-serif text-2xl font-bold text-ink">İletişim & Adres Bilgileri</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs font-medium pt-2">
              <div className="flex items-center gap-3 p-3 bg-sand/30 rounded-xl border border-line/60">
                <Mail className="w-5 h-5 text-espresso shrink-0" />
                <div>
                  <span className="block text-secondary text-[10px] uppercase font-bold">E-Posta Adresi</span>
                  <a href="mailto:info@thesobosociety.com" className="text-ink hover:text-espresso font-bold">
                    info@thesobosociety.com
                  </a>
                </div>
              </div>

              <div className="flex items-center gap-3 p-3 bg-sand/30 rounded-xl border border-line/60">
                <Phone className="w-5 h-5 text-espresso shrink-0" />
                <div>
                  <span className="block text-secondary text-[10px] uppercase font-bold">WhatsApp & Telefon</span>
                  <a href="https://wa.me/905316033080" target="_blank" rel="noopener noreferrer" className="text-ink hover:text-espresso font-bold">
                    +90 531 603 30 80
                  </a>
                </div>
              </div>
            </div>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  )
}
