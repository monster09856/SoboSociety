'use client'

import React from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { buyukHarf } from '@/lib/utils'
import { Calendar, Users, Zap, Bell } from 'lucide-react'

export function AdminNav() {
  const pathname = usePathname()

  const navItems = [
    {
      href: '/admin/today',
      label: '5 Saniyelik Panel',
      icon: Zap,
    },
    {
      href: '/admin/members',
      label: 'Üye & Paket Yönetimi',
      icon: Users,
    },
    {
      href: '/admin/schedule',
      label: 'Ders Türetme & Şablon',
      icon: Calendar,
    },
    {
      href: '/admin/notifications',
      label: 'Push & Bildirimler',
      icon: Bell,
    },
  ]

  return (
    <nav className="border-b border-line bg-ivory/95 backdrop-blur-md sticky top-0 z-40 text-ink shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-2xl bg-espresso text-ivory flex items-center justify-center font-serif font-extrabold text-lg shadow-xs">
              S
            </div>
            <Link href="/admin/today" className="font-serif text-xl font-bold tracking-wide text-espresso flex items-center">
              SOBO <span className="text-xs font-sans font-extrabold text-mocha uppercase tracking-widest ml-2 px-2.5 py-0.5 rounded-full bg-sand border border-line">Admin 2.0</span>
            </Link>
          </div>

          <div className="flex items-center gap-1 sm:gap-2">
            {navItems.map((item) => {
              const Icon = item.icon
              const isActive = pathname === item.href
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs sm:text-sm font-bold transition-all duration-200 ${
                    isActive
                      ? 'bg-espresso text-ivory shadow-xs'
                      : 'text-secondary hover:text-ink hover:bg-sand'
                  }`}
                >
                  <Icon className={`w-4 h-4 ${isActive ? 'text-mocha' : 'text-secondary'}`} />
                  <span>{buyukHarf(item.label)}</span>
                </Link>
              )
            })}
          </div>
        </div>
      </div>
    </nav>
  )
}
