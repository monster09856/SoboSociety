import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        ivory: {
          DEFAULT: '#F7F4EF',
          soft: '#FAFAF7',
          dark: '#EFECE6',
        },
        sand: {
          DEFAULT: '#E9E1D6',
          light: '#F2ECE2',
          deep: '#DED4C6',
        },
        line: {
          DEFAULT: '#DDD3C7',
          soft: '#EAE3D9',
        },
        ink: {
          DEFAULT: '#2B2522',
          soft: '#3D3531',
        },
        secondary: '#6B5D52',
        muted: '#8A7B6E',
        mocha: '#A2846F',
        espresso: {
          DEFAULT: '#6F5647',
          dark: '#584336',
          hover: '#5A463A',
        },
        sage: {
          DEFAULT: '#7D8B72',
          light: '#EAF0E8',
        },
        clay: {
          DEFAULT: '#B5714E',
          light: '#F8ECE6',
        },
        gold: {
          DEFAULT: '#C6A75E',
          light: '#F7F3E8',
        },
      },
      fontFamily: {
        serif: ['var(--font-cormorant)', 'Georgia', 'serif'],
        sans: ['var(--font-jost)', 'sans-serif'],
        cormorant: ['var(--font-cormorant)', 'serif'],
        jost: ['var(--font-jost)', 'sans-serif'],
      },
      borderRadius: {
        chip: '10px',
        input: '12px',
        card: '14px',
        panel: '18px',
        sheet: '24px',
      },
      boxShadow: {
        sobo: '0 4px 20px -2px rgba(43, 37, 34, 0.05)',
        'sobo-md': '0 8px 30px -4px rgba(43, 37, 34, 0.08)',
        'sobo-lg': '0 16px 40px -6px rgba(43, 37, 34, 0.12)',
      },
    },
  },
  plugins: [],
}

export default config
