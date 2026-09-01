import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function buyukHarf(metin: string): string {
  return metin.toLocaleUpperCase('tr-TR')
}
