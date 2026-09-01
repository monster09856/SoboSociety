import * as React from 'react'
import { cn } from '@/lib/utils'

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?:
    | 'primary'
    | 'secondary'
    | 'tertiary'
    | 'ghost'
    | 'outline'
    | 'destructive'
    | 'gradient'
    | 'glass'
    | 'glow'
    | 'emerald'
  size?: 'sm' | 'md' | 'lg' | 'icon'
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', ...props }, ref) => {
    const baseStyles =
      'inline-flex items-center justify-center font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-espresso focus-visible:ring-offset-2 focus-visible:ring-offset-ivory disabled:pointer-events-none disabled:opacity-50 rounded-input cursor-pointer select-none'

    const variants = {
      primary:
        'bg-espresso hover:bg-espresso-dark text-white font-medium shadow-sm hover:scale-[1.01] active:scale-[0.99] border border-espresso',
      secondary:
        'bg-sand-light hover:bg-sand border border-line text-ink font-medium hover:scale-[1.01] active:scale-[0.99]',
      tertiary:
        'bg-ivory hover:bg-sand-light border border-line/60 text-ink font-medium',
      outline:
        'border border-espresso text-espresso hover:bg-espresso hover:text-white font-medium transition-all',
      ghost:
        'bg-transparent text-ink hover:bg-sand-light/60 hover:text-espresso font-medium',
      destructive:
        'bg-clay text-white hover:bg-clay/90 font-medium shadow-sm',
      gradient:
        'bg-espresso hover:bg-espresso-dark text-white font-medium shadow-sm border border-espresso',
      glass:
        'bg-ivory/80 backdrop-blur-md hover:bg-sand-light border border-line text-ink font-medium',
      glow:
        'bg-espresso hover:bg-espresso-dark text-white font-medium shadow-md shadow-espresso/20 border border-espresso',
      emerald:
        'bg-sage text-white hover:bg-sage/90 font-medium shadow-sm',
    }

    const sizes = {
      sm: 'h-9 px-3.5 text-xs rounded-chip',
      md: 'h-11 px-5 text-sm',
      lg: 'h-12 px-7 text-base rounded-card',
      icon: 'h-10 w-10 p-0 rounded-chip',
    }

    return (
      <button
        ref={ref}
        className={cn(baseStyles, variants[variant], sizes[size], className)}
        {...props}
      />
    )
  }
)

Button.displayName = 'Button'
