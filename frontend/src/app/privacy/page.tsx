import React from 'react'
import Link from 'next/link'
import { Navigation } from '@/components/site/navigation'
import { Footer } from '@/components/site/footer'
import { Shield, Lock, Trash2, Mail, Phone, ArrowLeft } from 'lucide-react'
import { Badge } from '@/components/ui/badge'

export const metadata = {
  title: 'Privacy Policy | SOBO Society Wellness Studio',
  description: 'Privacy policy, data protection, and Apple App Store Review compliance guidelines for SOBO Society Wellness Studio.',
}

export default function PrivacyPolicyPage() {
  return (
    <div className="min-h-screen bg-ivory text-ink font-sans antialiased flex flex-col justify-between">
      <Navigation />

      <main className="py-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        {/* Header */}
        <div className="space-y-4 text-center sm:text-left border-b border-line pb-8">
          <Link href="/" className="inline-flex items-center gap-2 text-xs font-bold text-secondary hover:text-espresso transition-colors mb-2">
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Home</span>
          </Link>
          <div className="flex flex-wrap items-center gap-3">
            <Badge variant="mocha" className="uppercase tracking-widest text-[11px]">
              Apple App Store Compliant
            </Badge>
            <span className="text-xs text-secondary font-medium">Last Updated: September 2, 2026</span>
          </div>
          <h1 className="font-serif text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-ink">
            Privacy Policy
          </h1>
          <p className="text-secondary text-sm sm:text-base leading-relaxed">
            At <strong>SOBO Society Wellness Studio</strong>, we prioritize the privacy and security of your personal data. This Privacy Policy describes how we collect, use, and protect your information when using our iOS mobile app and web services.
          </p>
        </div>

        {/* Highlight Summary Card */}
        <div className="bg-sand/60 rounded-2xl p-6 border border-line space-y-4">
          <div className="flex items-center gap-3 text-espresso">
            <Shield className="w-6 h-6 shrink-0" />
            <h2 className="font-serif text-xl font-bold text-ink">Privacy Commitments</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs text-ink/90 font-medium">
            <div className="p-3 bg-ivory rounded-xl border border-line/60">
              <strong className="block text-espresso mb-1">🔒 Data Encryption</strong>
              All data transfers are encrypted via standard 256-bit SSL/TLS protocols.
            </div>
            <div className="p-3 bg-ivory rounded-xl border border-line/60">
              <strong className="block text-espresso mb-1">❌ No Data Selling</strong>
              We never sell or distribute your personal information to third-party advertisers.
            </div>
            <div className="p-3 bg-ivory rounded-xl border border-line/60">
              <strong className="block text-espresso mb-1">📱 Minimal Collection</strong>
              We only collect data strictly necessary for SMS authentication and studio bookings.
            </div>
            <div className="p-3 bg-ivory rounded-xl border border-line/60">
              <strong className="block text-espresso mb-1">🗑️ Account Deletion</strong>
              Users have the absolute right to request full deletion of their account and personal data.
            </div>
          </div>
        </div>

        {/* Detailed Sections */}
        <div className="space-y-10 text-sm text-ink/90 leading-relaxed font-normal">
          {/* Section 1 */}
          <section className="space-y-3">
            <h3 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <span className="text-espresso font-sans text-lg">1.</span>
              <span>Data Controller</span>
            </h3>
            <p>
              <strong>SOBO Society Wellness Studio</strong> (&quot;Company&quot;, &quot;We&quot;, or &quot;Studio&quot;) acts as the Data Controller regarding personal information collected via the SOBO Society iOS App and official website.
            </p>
          </section>

          {/* Section 2 */}
          <section className="space-y-3">
            <h3 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <span className="text-espresso font-sans text-lg">2.</span>
              <span>Information We Collect & Purpose</span>
            </h3>
            <p>We process the following categories of personal data:</p>
            <ul className="list-disc pl-5 space-y-2 text-xs sm:text-sm">
              <li>
                <strong>Contact & Identity Data:</strong> Mobile phone number and full name (used for SMS OTP verification, profile creation, and booking confirmations).
              </li>
              <li>
                <strong>Class & Booking Activity:</strong> Studio class attendances, active package credits, and attendance history.
              </li>
              <li>
                <strong>Device Notification Token:</strong> Device push notification tokens used strictly to deliver class reminders and studio updates upon user permission.
              </li>
            </ul>
          </section>

          {/* Section 3 */}
          <section className="space-y-3">
            <h3 className="font-serif text-2xl font-bold text-ink flex items-center gap-2">
              <span className="text-espresso font-sans text-lg">3.</span>
              <span>Apple App Store Guideline 5.1.1(v) — Account Deletion</span>
            </h3>
            <p>
              In compliance with Apple App Store Review Guideline 5.1.1(v), all users who create an account in the app have the right to delete their account and associated data.
            </p>
            <div className="p-4 bg-sand/40 border border-line rounded-xl space-y-2 text-xs">
              <strong className="block text-espresso text-sm font-bold">How to Request Account & Data Deletion:</strong>
              <p>
                You can initiate account deletion within the mobile app via <strong>Account ➔ Delete Account</strong> or by sending an email to <a href="mailto:sobosociety@gmail.com" className="underline text-espresso font-bold">sobosociety@gmail.com</a> with your registered phone number. Your account and personal records will be permanently erased within 48 hours.
              </p>
            </div>
          </section>

          {/* Section 4 */}
          <section className="space-y-3 pt-4 border-t border-line">
            <h3 className="font-serif text-2xl font-bold text-ink">Contact Information</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs font-medium pt-2">
              <div className="flex items-center gap-3 p-3 bg-sand/30 rounded-xl border border-line/60">
                <Mail className="w-5 h-5 text-espresso shrink-0" />
                <div>
                  <span className="block text-secondary text-[10px] uppercase font-bold">Email Address</span>
                  <a href="mailto:sobosociety@gmail.com" className="text-ink hover:text-espresso font-bold">
                    sobosociety@gmail.com
                  </a>
                </div>
              </div>

              <div className="flex items-center gap-3 p-3 bg-sand/30 rounded-xl border border-line/60">
                <Phone className="w-5 h-5 text-espresso shrink-0" />
                <div>
                  <span className="block text-secondary text-[10px] uppercase font-bold">WhatsApp & Phone</span>
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
