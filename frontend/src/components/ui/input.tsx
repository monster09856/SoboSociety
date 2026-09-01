import * as React from 'react'
import { cn } from '@/lib/utils'

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: boolean
}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, error, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          'flex h-11 w-full rounded-input border border-line bg-ivory/90 hover:bg-ivory px-4 py-2.5 text-sm text-ink placeholder:text-muted/70 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-espresso/30 focus-visible:border-espresso disabled:cursor-not-allowed disabled:opacity-50 transition-all duration-200 shadow-xs',
          error && 'border-clay focus-visible:ring-clay/30 focus-visible:border-clay',
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = 'Input'
