import { describe, it, expect } from 'vitest'
import { FixedPoint } from '~/utils/fixed-point'

describe('FixedPoint.fromValue', () => {
  it('creates with bigint value', () => {
    const fp = FixedPoint.fromValue(1000n, 3)
    expect(fp.value).toBe(1000n)
    expect(fp.decimals).toBe(3)
  })

  it('creates with number value', () => {
    const fp = FixedPoint.fromValue(42, 18)
    expect(fp.value).toBe(42n)
    expect(fp.decimals).toBe(18)
  })

  it('defaults to 18 decimals', () => {
    const fp = FixedPoint.fromValue(1n)
    expect(fp.decimals).toBe(18)
  })

  it('accepts bigint decimals', () => {
    const fp = FixedPoint.fromValue(1n, 6n)
    expect(fp.decimals).toBe(6)
  })
})

describe('FixedPoint.mul', () => {
  it('multiplies two values with same decimals', () => {
    // 2.0 * 3.0 = 6.0 (with 18 decimals)
    const a = FixedPoint.fromValue(2n * 10n ** 18n, 18)
    const b = FixedPoint.fromValue(3n * 10n ** 18n, 18)
    const result = a.mul(b)
    expect(result.value).toBe(6n * 10n ** 18n)
    expect(result.decimals).toBe(18)
  })

  it('preserves this.decimals', () => {
    const a = FixedPoint.fromValue(100n, 2)
    const b = FixedPoint.fromValue(200n, 2)
    const result = a.mul(b)
    expect(result.decimals).toBe(2)
  })

  it('multiplies by zero', () => {
    const a = FixedPoint.fromValue(1000n, 3)
    const b = FixedPoint.fromValue(0n, 3)
    expect(a.mul(b).value).toBe(0n)
  })

  it('multiplies values with different decimals', () => {
    // a = 2.00 (decimals=2, value=200), b = 3.000 (decimals=3, value=3000)
    // result = (200 * 3000) / 10^3 = 600, decimals = 2 (this.decimals) = 6.00
    const a = FixedPoint.fromValue(200n, 2)
    const b = FixedPoint.fromValue(3000n, 3)
    const result = a.mul(b)
    expect(result.value).toBe(600n)
    expect(result.decimals).toBe(2)
  })
})

describe('FixedPoint.div', () => {
  it('divides two values', () => {
    // 6.0 / 2.0 = 3.0
    const a = FixedPoint.fromValue(6n * 10n ** 18n, 18)
    const b = FixedPoint.fromValue(2n * 10n ** 18n, 18)
    const result = a.div(b)
    expect(result.value).toBe(3n * 10n ** 18n)
  })

  it('returns 0 when dividing by zero', () => {
    const a = FixedPoint.fromValue(1000n, 3)
    const b = FixedPoint.fromValue(0n, 3)
    expect(a.div(b).value).toBe(0n)
  })

  it('handles fractional results', () => {
    // 1.0 / 3.0 ≈ 0.333...
    const a = FixedPoint.fromValue(10n ** 18n, 18)
    const b = FixedPoint.fromValue(3n * 10n ** 18n, 18)
    const result = a.div(b)
    expect(result.toUnsafeFloat()).toBeCloseTo(1 / 3, 10)
  })
})

describe('FixedPoint.add', () => {
  it('adds same-decimal values', () => {
    const a = FixedPoint.fromValue(100n, 2)
    const b = FixedPoint.fromValue(200n, 2)
    expect(a.add(b).value).toBe(300n)
  })

  it('aligns decimals when different', () => {
    const a = FixedPoint.fromValue(1n, 0) // 1
    const b = FixedPoint.fromValue(500n, 3) // 0.5
    const result = a.add(b)
    expect(result.decimals).toBe(3)
    expect(result.value).toBe(1500n) // 1.500
  })
})

describe('FixedPoint.sub', () => {
  it('subtracts values', () => {
    const a = FixedPoint.fromValue(500n, 2)
    const b = FixedPoint.fromValue(200n, 2)
    expect(a.sub(b).value).toBe(300n)
  })

  it('clamps to zero for negative results', () => {
    const a = FixedPoint.fromValue(100n, 2)
    const b = FixedPoint.fromValue(200n, 2)
    expect(a.sub(b).value).toBe(0n)
  })
})

describe('FixedPoint.subUnsafe', () => {
  it('allows negative results', () => {
    const a = FixedPoint.fromValue(100n, 2)
    const b = FixedPoint.fromValue(200n, 2)
    expect(a.subUnsafe(b).value).toBe(-100n)
  })

  it('aligns decimals before subtracting', () => {
    const a = FixedPoint.fromValue(500n, 3) // 0.500
    const b = FixedPoint.fromValue(1n, 0) // 1
    const result = a.subUnsafe(b)
    expect(result.value).toBe(-500n) // 0.500 - 1.000 = -0.500
    expect(result.decimals).toBe(3)
  })
})

describe('FixedPoint.addUnsafe', () => {
  it('adds without aligning decimals', () => {
    const a = FixedPoint.fromValue(100n, 2)
    const b = FixedPoint.fromValue(50n, 3)
    // Raw addition: 100 + 50 = 150, keeps this.decimals (2)
    const result = a.addUnsafe(b)
    expect(result.value).toBe(150n)
    expect(result.decimals).toBe(2)
  })
})

describe('FixedPoint comparisons', () => {
  it('isZero', () => {
    expect(FixedPoint.fromValue(0n, 18).isZero()).toBe(true)
    expect(FixedPoint.fromValue(1n, 18).isZero()).toBe(false)
  })

  it('isNegative', () => {
    expect(FixedPoint.fromValue(-1n, 18).isNegative()).toBe(true)
    expect(FixedPoint.fromValue(0n, 18).isNegative()).toBe(false)
    expect(FixedPoint.fromValue(1n, 18).isNegative()).toBe(false)
  })

  it('lt with same decimals', () => {
    const a = FixedPoint.fromValue(100n, 2)
    const b = FixedPoint.fromValue(200n, 2)
    expect(a.lt(b)).toBe(true)
    expect(b.lt(a)).toBe(false)
    expect(a.lt(a)).toBe(false)
  })

  it('lt with different decimals', () => {
    const a = FixedPoint.fromValue(1n, 0) // 1
    const b = FixedPoint.fromValue(2000n, 3) // 2.0
    expect(a.lt(b)).toBe(true)
  })

  it('lte', () => {
    const a = FixedPoint.fromValue(100n, 2)
    const b = FixedPoint.fromValue(100n, 2)
    expect(a.lte(b)).toBe(true)
    expect(a.lte(FixedPoint.fromValue(50n, 2))).toBe(false)
  })

  it('gte', () => {
    const a = FixedPoint.fromValue(200n, 2)
    const b = FixedPoint.fromValue(100n, 2)
    expect(a.gte(b)).toBe(true)
    expect(a.gte(a)).toBe(true)
    expect(b.gte(a)).toBe(false)
  })
})

describe('FixedPoint.round', () => {
  it('expands decimals', () => {
    const fp = FixedPoint.fromValue(100n, 2) // 1.00
    const rounded = fp.round(4)
    expect(rounded.value).toBe(10000n) // 1.0000
    expect(rounded.decimals).toBe(4)
  })

  it('contracts decimals with rounding', () => {
    const fp = FixedPoint.fromValue(155n, 2) // 1.55
    const rounded = fp.round(1)
    // half = 10/2 = 5, (155 + 5) / 10 = 16
    expect(rounded.value).toBe(16n) // 1.6
    expect(rounded.decimals).toBe(1)
  })

  it('rounds negative values correctly', () => {
    const fp = FixedPoint.fromValue(-155n, 2)
    const rounded = fp.round(1)
    expect(rounded.value).toBe(-16n)
  })

  it('no-op when same decimals', () => {
    const fp = FixedPoint.fromValue(123n, 3)
    const rounded = fp.round(3)
    expect(rounded.value).toBe(123n)
  })
})

describe('FixedPoint.toFormat', () => {
  it('delegates to round with decimals param', () => {
    const fp = FixedPoint.fromValue(1500n, 3)
    const result = fp.toFormat({ decimals: 1 })
    expect(result.value).toBe(15n)
    expect(result.decimals).toBe(1)
  })
})

describe('FixedPoint.toUnsafeFloat', () => {
  it('converts to float', () => {
    const fp = FixedPoint.fromValue(1500n, 3)
    expect(fp.toUnsafeFloat()).toBe(1.5)
  })

  it('handles zero', () => {
    expect(FixedPoint.fromValue(0n, 18).toUnsafeFloat()).toBe(0)
  })

  it('handles zero decimals', () => {
    expect(FixedPoint.fromValue(42n, 0).toUnsafeFloat()).toBe(42)
  })

  it('handles negative values', () => {
    const fp = FixedPoint.fromValue(-2500n, 3)
    expect(fp.toUnsafeFloat()).toBe(-2.5)
  })
})

describe('FixedPoint.toString', () => {
  it('formats with fractional part', () => {
    const fp = FixedPoint.fromValue(1500n, 3)
    expect(fp.toString()).toBe('1.500')
  })

  it('formats zero', () => {
    expect(FixedPoint.fromValue(0n, 3).toString()).toBe('0.000')
  })

  it('formats with zero decimals', () => {
    expect(FixedPoint.fromValue(42n, 0).toString()).toBe('42')
  })

  it('formats negative values', () => {
    expect(FixedPoint.fromValue(-1500n, 3).toString()).toBe('-1.500')
  })

  it('pads fractional part with leading zeros', () => {
    const fp = FixedPoint.fromValue(5n, 3) // 0.005
    expect(fp.toString()).toBe('0.005')
  })
})
