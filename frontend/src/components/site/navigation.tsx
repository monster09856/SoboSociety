'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { Menu, X, Calendar, User } from 'lucide-react'
import { Button } from '@/components/ui/button'

export function Navigation() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 20) {
        setScrolled(true)
      } else {
        setScrolled(false)
      }
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const navLinks = [
    { href: '#dersler', label: 'Dersler' },
    { href: '#canli-program', label: 'Canlı Program' },
    { href: '#paketler', label: 'Paketler' },
    { href: '#iletisim', label: 'İletişim' },
  ]

  return (
    <header
      className={`sticky top-0 z-50 transition-all duration-300 ${
        scrolled
          ? 'bg-ivory/95 backdrop-blur-md border-b border-line shadow-sobo py-3'
          : 'bg-ivory/80 backdrop-blur-md border-b border-line/60 py-4'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-14">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-3 group">
            <img src="/logo.png" alt="Sobo Society" className="h-9 w-auto rounded-lg shadow-xs" />
            <div className="flex flex-col">
              <span className="font-serif text-2xl sm:text-3xl font-medium tracking-[0.2em] text-ink group-hover:text-espresso transition-colors">
                SOBO SOCIETY
              </span>
              <span className="text-[9px] uppercase tracking-[0.35em] text-mocha font-light -mt-1">
                WELLNESS STUDIO
              </span>
            </div>
          </Link>

          {/* Desktop Navigation Links */}
          <nav className="hidden md:flex items-center space-x-8">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="text-sm font-medium text-ink/80 hover:text-espresso transition-all tracking-wide relative py-1 group"
              >
                {link.label}
                <span className="absolute bottom-0 left-0 w-0 h-0.5 bg-espresso transition-all duration-300 group-hover:w-full" />
              </a>
            ))}
          </nav>

          {/* Action Button */}
          <div className="hidden md:flex items-center space-x-4">
            <Link href="/giris">
              <Button variant="primary" size="md" className="gap-2 font-medium">
                <Calendar className="w-4 h-4" />
                <span>Giriş Yap / Rezervasyon</span>
              </Button>
            </Link>
          </div>

          {/* Mobile Menu Button */}
          <div className="md:hidden flex items-center">
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2.5 rounded-input bg-sand-light border border-line text-ink hover:text-espresso transition-colors focus:outline-none"
              aria-label="Menüyü aç/kapat"
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Navigation Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden border-b border-line bg-ivory px-4 pt-4 pb-6 mt-2 space-y-4 shadow-sobo-md animate-in slide-in-from-top-2 duration-200">
          <nav className="flex flex-col space-y-2">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                onClick={() => setMobileMenuOpen(false)}
                className="text-base font-medium text-ink hover:text-espresso transition-colors py-2.5 border-b border-line/50 flex items-center justify-between"
              >
                <span>{link.label}</span>
                <span className="text-xs text-mocha font-sans">→</span>
              </a>
            ))}
          </nav>
          <div className="pt-2">
            <Link href="/giris" onClick={() => setMobileMenuOpen(false)} className="w-full block">
              <Button variant="primary" className="w-full justify-center flex items-center gap-2 py-3">
                <User className="w-4 h-4" />
                <span>Giriş Yap / Rezervasyon</span>
              </Button>
            </Link>
          </div>
        </div>
      )}
    </header>
  )
}
