'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { Calendar, Clock, User, CheckCircle2, Flame, Sparkles, HeartHandshake, Users } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'

interface ClassSession {
  id: string
  title: string
  category: 'Barre' | 'Pilates' | 'Functional'
  instructor: string
  time: string
  duration: string
  capacity: number
  enrolled: number
  status: 'available' | 'few_left' | 'full'
  statusText: string
}

const scheduleData: Record<string, ClassSession[]> = {
  Pazartesi: [
    {
      id: 'paz-1',
      title: 'Sobo Barre Morning',
      category: 'Barre',
      instructor: 'Ece Karaca',
      time: '08:30 - 09:20',
      duration: '50 dk',
      capacity: 5,
      enrolled: 4,
      status: 'available',
      statusText: '4 Yer Kaldı',
    },
    {
      id: 'paz-2',
      title: 'Core & Posture Pilates',
      category: 'Pilates',
      instructor: 'Defne Yılmaz',
      time: '10:00 - 10:50',
      duration: '50 dk',
      capacity: 5,
      enrolled: 7,
      status: 'few_left',
      statusText: 'Son 1 Yer',
    },
    {
      id: 'paz-3',
      title: 'Functional Sculpt',
      category: 'Functional',
      instructor: 'Can Tezcan',
      time: '18:30 - 19:20',
      duration: '50 dk',
      capacity: 5,
      enrolled: 8,
      status: 'full',
      statusText: 'Dolu (Sıra Bekleme)',
    },
  ],
  Salı: [
    {
      id: 'sal-1',
      title: 'Sobo Flow & Stretch',
      category: 'Pilates',
      instructor: 'Defne Yılmaz',
      time: '09:00 - 09:50',
      duration: '50 dk',
      capacity: 5,
      enrolled: 3,
      status: 'available',
      statusText: '5 Yer Kaldı',
    },
    {
      id: 'sal-2',
      title: 'Barre Burn & Tone',
      category: 'Barre',
      instructor: 'Ece Karaca',
      time: '12:15 - 13:05',
      duration: '50 dk',
      capacity: 5,
      enrolled: 6,
      status: 'few_left',
      statusText: 'Son 2 Yer',
    },
    {
      id: 'sal-3',
      title: 'High-Sweat Functional',
      category: 'Functional',
      instructor: 'Can Tezcan',
      time: '19:00 - 19:50',
      duration: '50 dk',
      capacity: 5,
      enrolled: 5,
      status: 'available',
      statusText: '3 Yer Kaldı',
    },
  ],
  Çarşamba: [
    {
      id: 'car-1',
      title: 'Sunrise Barre',
      category: 'Barre',
      instructor: 'Ece Karaca',
      time: '08:00 - 08:50',
      duration: '50 dk',
      capacity: 5,
      enrolled: 2,
      status: 'available',
      statusText: '6 Yer Kaldı',
    },
    {
      id: 'car-2',
      title: 'Reformer & Mat Alignment',
      category: 'Pilates',
      instructor: 'Defne Yılmaz',
      time: '11:00 - 11:50',
      duration: '50 dk',
      capacity: 5,
      enrolled: 8,
      status: 'full',
      statusText: 'Dolu (Sıra Bekleme)',
    },
    {
      id: 'car-3',
      title: 'Evening Sculpt & Abs',
      category: 'Functional',
      instructor: 'Can Tezcan',
      time: '18:30 - 19:20',
      duration: '50 dk',
      capacity: 5,
      enrolled: 6,
      status: 'few_left',
      statusText: 'Son 2 Yer',
    },
  ],
  Perşembe: [
    {
      id: 'per-1',
      title: 'Postural Pilates',
      category: 'Pilates',
      instructor: 'Defne Yılmaz',
      time: '09:30 - 10:20',
      duration: '50 dk',
      capacity: 5,
      enrolled: 4,
      status: 'available',
      statusText: '4 Yer Kaldı',
    },
    {
      id: 'per-2',
      title: 'Barre Masterclass',
      category: 'Barre',
      instructor: 'Ece Karaca',
      time: '18:00 - 18:50',
      duration: '50 dk',
      capacity: 5,
      enrolled: 7,
      status: 'few_left',
      statusText: 'Son 1 Yer',
    },
  ],
  Cuma: [
    {
      id: 'cum-1',
      title: 'Friday Energy Functional',
      category: 'Functional',
      instructor: 'Can Tezcan',
      time: '08:30 - 09:20',
      duration: '50 dk',
      capacity: 5,
      enrolled: 3,
      status: 'available',
      statusText: '5 Yer Kaldı',
    },
    {
      id: 'cum-2',
      title: 'Sobo Signature Barre',
      category: 'Barre',
      instructor: 'Ece Karaca',
      time: '17:30 - 18:20',
      duration: '50 dk',
      capacity: 5,
      enrolled: 8,
      status: 'full',
      statusText: 'Dolu (Sıra Bekleme)',
    },
  ],
  Cumartesi: [
    {
      id: 'cts-1',
      title: 'Weekend Warrior Barre',
      category: 'Barre',
      instructor: 'Ece Karaca',
      time: '10:00 - 10:50',
      duration: '50 dk',
      capacity: 5,
      enrolled: 7,
      status: 'few_left',
      statusText: 'Son 1 Yer',
    },
    {
      id: 'cts-2',
      title: 'Full Body Pilates',
      category: 'Pilates',
      instructor: 'Defne Yılmaz',
      time: '11:30 - 12:20',
      duration: '50 dk',
      capacity: 5,
      enrolled: 4,
      status: 'available',
      statusText: '4 Yer Kaldı',
    },
  ],
  Pazar: [
    {
      id: 'paz-sun-1',
      title: 'Sunday Recovery & Flow',
      category: 'Pilates',
      instructor: 'Defne Yılmaz',
      time: '11:00 - 11:50',
      duration: '50 dk',
      capacity: 5,
      enrolled: 2,
      status: 'available',
      statusText: '6 Yer Kaldı',
    },
  ],
}

const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']

export function LiveSchedule() {
  const [selectedDay, setSelectedDay] = useState('Pazartesi')

  const currentSessions = scheduleData[selectedDay] || []

  return (
    <section id="canli-program" className="py-24 bg-ivory/50 relative overflow-hidden border-b border-line/60">
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <div className="text-center max-w-2xl mx-auto mb-14 space-y-4">
          <Badge variant="sage" className="uppercase tracking-widest px-3.5 py-1 text-xs font-medium">
            Program & Kontenjan Takibi
          </Badge>
          <h2 className="font-serif text-3xl sm:text-4xl md:text-5xl font-medium text-ink tracking-tight">
            Haftalık Ders Programı
          </h2>
          <p className="text-secondary text-base leading-relaxed">
            Butik stüdyomuzda her sınıfta maksimum 5 üye kabul edilir. Kontenjan durumunu takip edebilir ve saniyeler içinde yerinizi rezerve edebilirsiniz.
          </p>
        </div>

        {/* Days Selector Ribbon (Sand / Ivory) */}
        <div className="flex items-center justify-start sm:justify-center gap-2.5 overflow-x-auto pb-4 mb-10 no-scrollbar">
          {days.map((day) => {
            const isActive = selectedDay === day
            return (
              <button
                key={day}
                onClick={() => setSelectedDay(day)}
                className={`px-5 py-2.5 rounded-full text-sm font-medium transition-all duration-200 whitespace-nowrap cursor-pointer ${
                  isActive
                    ? 'bg-espresso text-white shadow-xs border border-espresso'
                    : 'bg-sand-light hover:bg-sand text-ink border border-line'
                }`}
              >
                {day}
              </button>
            )
          })}
        </div>

        {/* Session Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {currentSessions.map((session) => {
            const occupancyPercentage = Math.round((session.enrolled / session.capacity) * 100)
            const isFull = session.status === 'full'
            const isFewLeft = session.status === 'few_left'

            const badgeVariant = isFull ? ('clay' as const) : isFewLeft ? ('mocha' as const) : ('sage' as const)

            const CategoryIcon =
              session.category === 'Barre'
                ? Sparkles
                : session.category === 'Pilates'
                ? HeartHandshake
                : Flame

            return (
              <Card
                key={session.id}
                className="relative overflow-hidden bg-white/90 border-line hover:border-mocha/50 p-6 flex flex-col justify-between"
              >
                <div className="space-y-5">
                  {/* Header info */}
                  <div className="flex items-start justify-between gap-3">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <CategoryIcon className="w-4 h-4 text-mocha" />
                        <span className="text-xs font-semibold uppercase tracking-wider text-secondary">
                          {session.category}
                        </span>
                      </div>
                      <h3 className="font-serif text-2xl font-medium text-ink tracking-tight">
                        {session.title}
                      </h3>
                    </div>

                    <Badge variant={badgeVariant} className="shrink-0">
                      {session.statusText}
                    </Badge>
                  </div>

                  {/* Occupancy Progress Bar */}
                  <div className="space-y-1.5 pt-2">
                    <div className="flex items-center justify-between text-xs text-secondary font-medium">
                      <span>Doluluk Oranı</span>
                      <span className="font-semibold text-ink">
                        {session.enrolled} / {session.capacity} Üye ({occupancyPercentage}%)
                      </span>
                    </div>
                    <div className="w-full bg-sand-light h-2 rounded-full overflow-hidden p-0.5 border border-line/40">
                      <div
                        className={`h-full rounded-full transition-all duration-500 ${
                          isFull
                            ? 'bg-clay'
                            : isFewLeft
                            ? 'bg-mocha'
                            : 'bg-sage'
                        }`}
                        style={{ width: `${occupancyPercentage}%` }}
                      />
                    </div>
                  </div>

                  {/* Details list */}
                  <div className="space-y-2.5 text-sm text-secondary pt-3 border-t border-line/50">
                    <div className="flex items-center gap-2.5">
                      <Clock className="w-4 h-4 text-mocha" />
                      <span>
                        {session.time} <strong className="text-ink font-normal">({session.duration})</strong>
                      </span>
                    </div>
                    <div className="flex items-center gap-2.5">
                      <User className="w-4 h-4 text-mocha" />
                      <span>Eğitmen: <strong className="text-ink font-medium">{session.instructor}</strong></span>
                    </div>
                    <div className="flex items-center gap-2.5">
                      <Users className="w-4 h-4 text-mocha" />
                      <span>Butik Sınıf (Max 5 Kişi)</span>
                    </div>
                  </div>
                </div>

                {/* Action button */}
                <div className="pt-6">
                  <Link href="/giris" className="w-full block">
                    <Button
                      variant={isFull ? 'secondary' : 'primary'}
                      className="w-full justify-center text-sm py-3 font-medium"
                    >
                      {isFull ? 'Bekleme Listesine Katıl' : 'Hemen Rezerve Et'}
                    </Button>
                  </Link>
                </div>
              </Card>
            )
          })}
        </div>

        {/* Bottom Notice */}
        <div className="mt-12 text-center text-xs text-secondary flex items-center justify-center gap-2">
          <CheckCircle2 className="w-4 h-4 text-sage" />
          <span>Rezervasyon iptalleri dersten en geç 4 saat öncesine kadar bakiye iadesiyle yapılabilir.</span>
        </div>
      </div>
    </section>
  )
}
