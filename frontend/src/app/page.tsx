import { Navigation } from '@/components/site/navigation'
import { Hero } from '@/components/site/hero'
import { LiveSchedule } from '@/components/site/live-schedule'
import { Packages } from '@/components/site/packages'
import { Footer } from '@/components/site/footer'
import { AIConciergeModal } from '@/components/site/ai-concierge-modal'

export default function Home() {
  return (
    <div className="min-h-screen bg-ivory text-ink font-sans flex flex-col justify-between selection:bg-mocha/20 selection:text-espresso">
      <Navigation />
      <main className="flex-1">
        <Hero />
        <LiveSchedule />
        <Packages />
      </main>
      <Footer />
      <AIConciergeModal />
    </div>
  )
}
