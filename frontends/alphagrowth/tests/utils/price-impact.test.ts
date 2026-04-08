import { describe, it, expect } from 'vitest'
import {
  isPriceImpactWarning,
  isPriceImpactDanger,
  isSlippageWarning,
  computeMultipliedPriceImpact,
  PRICE_IMPACT_WARNING_THRESHOLD,
  PRICE_IMPACT_DANGER_THRESHOLD,
  SLIPPAGE_WARNING_THRESHOLD,
} from '~/utils/priceImpact'

describe('isPriceImpactWarning', () => {
  it('returns false for null', () => {
    expect(isPriceImpactWarning(null)).toBe(false)
  })

  it('returns false above threshold', () => {
    expect(isPriceImpactWarning(-2)).toBe(false)
  })

  it('returns true at threshold', () => {
    expect(isPriceImpactWarning(PRICE_IMPACT_WARNING_THRESHOLD)).toBe(true)
  })

  it('returns true below threshold', () => {
    expect(isPriceImpactWarning(-10)).toBe(true)
  })

  it('returns false for zero impact', () => {
    expect(isPriceImpactWarning(0)).toBe(false)
  })
})

describe('isPriceImpactDanger', () => {
  it('returns false for null', () => {
    expect(isPriceImpactDanger(null)).toBe(false)
  })

  it('returns false above threshold', () => {
    expect(isPriceImpactDanger(-5)).toBe(false)
  })

  it('returns true at threshold', () => {
    expect(isPriceImpactDanger(PRICE_IMPACT_DANGER_THRESHOLD)).toBe(true)
  })

  it('returns true below threshold', () => {
    expect(isPriceImpactDanger(-15)).toBe(true)
  })
})

describe('isSlippageWarning', () => {
  it('returns false at threshold', () => {
    expect(isSlippageWarning(SLIPPAGE_WARNING_THRESHOLD)).toBe(false)
  })

  it('returns true above threshold', () => {
    expect(isSlippageWarning(2)).toBe(true)
  })

  it('returns false below threshold', () => {
    expect(isSlippageWarning(0.5)).toBe(false)
  })

  it('returns false for zero slippage', () => {
    expect(isSlippageWarning(0)).toBe(false)
  })
})

describe('computeMultipliedPriceImpact', () => {
  it('returns null when directImpact is null', () => {
    expect(computeMultipliedPriceImpact(null, 2)).toBeNull()
  })

  it('returns null when multiplier is null', () => {
    expect(computeMultipliedPriceImpact(-5, null)).toBeNull()
  })

  it('returns null when multiplier <= 1', () => {
    expect(computeMultipliedPriceImpact(-5, 1)).toBeNull()
    expect(computeMultipliedPriceImpact(-5, 0.5)).toBeNull()
  })

  it('multiplies impact by multiplier', () => {
    expect(computeMultipliedPriceImpact(-5, 3)).toBe(-15)
  })

  it('returns null for non-finite result', () => {
    expect(computeMultipliedPriceImpact(Infinity, 2)).toBeNull()
  })
})
