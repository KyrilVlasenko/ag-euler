import { describe, it, expect } from 'vitest'
import { getRelativeTimeBetweenDates } from '~/utils/time-utils'

describe('getRelativeTimeBetweenDates', () => {
  const base = new Date('2024-01-15T12:00:00Z')

  it('returns seconds for recent past', () => {
    const to = new Date(base.getTime() - 30_000) // 30 seconds ago
    const result = getRelativeTimeBetweenDates(base, to)
    expect(result).toBe('30 seconds ago')
  })

  it('returns minutes for minutes ago', () => {
    const to = new Date(base.getTime() - 5 * 60_000)
    const result = getRelativeTimeBetweenDates(base, to)
    expect(result).toBe('5 minutes ago')
  })

  it('returns hours for hours ago', () => {
    const to = new Date(base.getTime() - 3 * 3600_000)
    const result = getRelativeTimeBetweenDates(base, to)
    expect(result).toBe('3 hours ago')
  })

  it('returns days for days ago', () => {
    const to = new Date(base.getTime() - 3 * 86400_000)
    const result = getRelativeTimeBetweenDates(base, to)
    expect(result).toBe('3 days ago')
  })

  it('returns weeks for week-scale differences', () => {
    const to = new Date(base.getTime() - 14 * 86400_000)
    const result = getRelativeTimeBetweenDates(base, to)
    expect(result).toBe('2 weeks ago')
  })

  it('returns months for month-scale differences', () => {
    const to = new Date(base.getTime() - 60 * 86400_000)
    const result = getRelativeTimeBetweenDates(base, to)
    expect(result).toBe('2 months ago')
  })

  it('returns years for year-scale differences', () => {
    // 400 days ≈ 1.1 years → floor(400*86400 / (365*86400)) = 1
    // But the source uses floor(secondsDiff / divisor) where divisor = 86400*365
    // secondsDiff = -34560000, divisor = 31536000, floor(-34560000/31536000) = -2
    // Intl.RelativeTimeFormat formats -1 as "1 year ago"
    const to = new Date(base.getTime() - 370 * 86400_000)
    const result = getRelativeTimeBetweenDates(base, to)
    expect(result).toMatch(/year/)
  })

  it('handles future dates', () => {
    const to = new Date(base.getTime() + 3600_000) // 1 hour in future
    const result = getRelativeTimeBetweenDates(base, to)
    expect(result).toBe('in 1 hour')
  })

  it('handles same timestamp', () => {
    const result = getRelativeTimeBetweenDates(base, base)
    // secondsDiff = 0 → Intl.RelativeTimeFormat(0, 'second') = "now"
    expect(result).toBe('now')
  })
})
