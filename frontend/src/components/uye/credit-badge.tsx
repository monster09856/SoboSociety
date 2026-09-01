import React from 'react'
import { Ticket } from 'lucide-react'
import { cn } from '@/lib/utils'

interface CreditBadgeProps {
  credits: number
  className?: string
}

export const CreditBadge: React.FC<CreditBadgeProps> = ({ credits, className }) => {
  return (
    <div
      className={cn(
        'inline-flex items-center gap-2.5 rounded-full px-3.5 py-1.5 transition-all duration-300',
        'bg-sand/80 border border-line hover:border-mocha/60 shadow-xs',
        'font-sans text-xs sm:text-sm cursor-default select-none',
        className
      )}
    >
      <div className="flex items-center justify-center w-6 h-6 rounded-full bg-espresso text-ivory shadow-xs shrink-0">
        <Ticket className="w-3.5 h-3.5" />
      </div>

      <div className="flex items-center gap-1.5">
        <span className="font-serif font-extrabold text-base text-espresso tracking-tight">
          {credits}
        </span>
        <span className="text-[11px] font-bold tracking-wider text-secondary uppercase">
          Kredi
        </span>
      </div>
    </div>
  )
}
