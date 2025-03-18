import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

/**
 * Utilitário para mesclar classes CSS com suporte ao Tailwind
 * @param inputs - Classes CSS a serem mescladas
 * @returns {string} Classes CSS mescladas e otimizadas
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
} 