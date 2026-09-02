import React, { Suspense } from 'react'
import Link from 'next/link'
import { OtpForm } from '@/components/uye/otp-form'
import { Loader2, Sparkles } from 'lucide-react'

export const metadata = {
  title: 'Giriş Yap | Sobo Society',
  description: 'Sobo Society üye ve eğitmen SMS OTP giriş ekranı',
}

export default function GirisPage() {
  return (
    <main className="min-h-screen bg-ivory text-ink flex flex-col justify-between items-center px-4 py-8 md:py-12 relative overflow-hidden antialiased">
      {/* Header / Brand */}
      <div className="w-full max-w-md text-center space-y-3 mt-4 md:mt-8 relative z-10">
        <Link href="/" className="inline-block group">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-sand border border-line text-espresso text-xs font-bold mb-3 shadow-xs">
            <Sparkles className="w-3.5 h-3.5 text-mocha" />
            <span>Sobo Society</span>
          </div>
          <h1 className="text-4xl md:text-5xl font-serif font-extrabold tracking-[0.2em] text-espresso group-hover:opacity-90 transition-opacity">
            SOBO
          </h1>
          <p className="text-xs tracking-[0.35em] text-secondary font-bold mt-1.5">
            SOCIETY
          </p>
        </Link>
        <p className="text-sm italic font-serif text-secondary">
          &quot;Not just a studio. It&apos;s a society.&quot;
        </p>
      </div>

      {/* Main Login Form Container */}
      <div className="w-full max-w-md my-auto py-8 flex justify-center relative z-10">
        <Suspense
          fallback={
            <div className="flex h-64 w-full items-center justify-center rounded-3xl bg-sand/80 border border-line backdrop-blur-md">
              <Loader2 className="h-7 w-7 animate-spin text-espresso" />
            </div>
          }
        >
          <OtpForm />
        </Suspense>
      </div>

      {/* Footer Info */}
      <div className="w-full max-w-md text-center text-xs text-secondary space-y-2 relative z-10">
        <p>© {new Date().getFullYear()} Sobo Society. Tüm hakları saklıdır.</p>
        <div className="flex justify-center space-x-4 text-xs font-semibold">
          <Link href="/" className="hover:text-espresso transition-colors">
            Ana Sayfa
          </Link>
          <span>•</span>
          <Link href="/rezervasyon" className="hover:text-espresso transition-colors">
            Ders Programı
          </Link>
        </div>
      </div>
    </main>
  )
}
