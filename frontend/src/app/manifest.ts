import type { MetadataRoute } from 'next'

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Sobo Society | Barre • Pilates • Functional',
    short_name: 'Sobo Society',
    description: "Not just a studio. It's a society.",
    start_url: '/rezervasyon',
    display: 'standalone',
    background_color: '#F7F4EF',
    theme_color: '#6F5647',
    icons: [
      {
        src: '/icon-192.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: '/icon-512.png',
        sizes: '512x512',
        type: 'image/png',
      },
    ],
  }
}
