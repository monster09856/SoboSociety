import * as React from 'react'
import { cn } from '@/lib/utils'

export interface BadgeProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?:
    | 'sage'
    | 'clay'
    | 'mocha'
    | 'espresso'
    | 'sand'
    | 'emerald'
    | 'coral'
    | 'amber'
    | 'violet'
    | 'rose'
    | 'gradient'
    | 'glass'
    | 'default'
    | 'outline'
}

export const Badge = React.forwardRef<HTMLDivElement, BadgeProps>(
  ({ className, variant = 'default', ...props }, ref) => {
    const baseStyles =
      'inline-flex items-center rounded-full px-3 py-1 text-xs font-medium tracking-wide transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-espresso focus:ring-offset-2'

    const variants = {
      sage: 'bg-sage/15 text-sage border border-sage/30',
      clay: 'bg-clay/15 text-clay border border-clay/30',
      mocha: 'bg-mocha/15 text-mocha border border-mocha/30',
      espresso: 'bg-espresso text-white border border-espresso',
      sand: 'bg-sand-light text-ink border border-line',
      emerald: 'bg-sage/15 text-sage border border-sage/30',
      coral: 'bg-clay/15 text-clay border border-clay/30',
      amber: 'bg-mocha/15 text-mocha border border-mocha/30',
      violet: 'bg-mocha/15 text-mocha border border-mocha/30',
      rose: 'bg-clay/15 text-clay border border-clay/30',
      gradient: 'bg-espresso text-white border border-espresso',
      glass: 'bg-ivory/80 text-ink border border-line backdrop-blur-md',
      default: 'bg-sand-light text-ink border border-line',
      outline: 'border border-line text-secondary hover:border-mocha',
    }

    return (
      <div
        ref={ref}
        className={cn(baseStyles, variants[variant], className)}
        {...props}
      />
    )
  }
)

Badge.displayName = 'Badge'
