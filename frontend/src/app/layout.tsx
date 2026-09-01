import type { Metadata } from 'next'
import { Cormorant_Garamond, Jost } from 'next/font/google'
import './globals.css'

const cormorant = Cormorant_Garamond({
  subsets: ['latin'],
  weight: ['300', '400', '500', '600', '700'],
  variable: '--font-cormorant',
  display: 'swap',
})

const jost = Jost({
  subsets: ['latin'],
  weight: ['300', '400', '500', '600', '700'],
  variable: '--font-jost',
  display: 'swap',
})

export const metadata: Metadata = {
  title: "Sobo Society | Barre • Pilates • Functional",
  description: "Not just a studio. It's a society.",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="tr" className={`${cormorant.variable} ${jost.variable} scroll-smooth`}>
      <body className="bg-ivory text-ink font-sans antialiased min-h-screen flex flex-col selection:bg-mocha/20 selection:text-espresso">
        {children}
      </body>
    </html>
  )
}
