import { Navigation } from '@/components/site/navigation'
import { Hero } from '@/components/site/hero'
import { LiveSchedule } from '@/components/site/live-schedule'
import { Workshops } from '@/components/site/workshops'
import { Packages } from '@/components/site/packages'
import { Footer } from '@/components/site/footer'
import { AIConciergeModal } from '@/components/site/ai-concierge-modal'

export const dynamic = 'force-dynamic'
export const revalidate = 0

export default function Home() {
  return (
    <div className="min-h-screen bg-ivory text-ink font-sans flex flex-col justify-between selection:bg-mocha/20 selection:text-espresso">
      <Navigation />
      <main className="flex-1">
        <Hero />
        <LiveSchedule />
        <Workshops />
        <Packages />
      </main>
      <Footer />
      <AIConciergeModal />
    </div>
  )
}
