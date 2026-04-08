import { describe, it, expect } from 'vitest'
import { createRaceGuard } from '~/utils/race-guard'

describe('createRaceGuard', () => {
  it('starts at generation 0', () => {
    const guard = createRaceGuard()
    expect(guard.current()).toBe(0)
  })

  it('increments on next()', () => {
    const guard = createRaceGuard()
    expect(guard.next()).toBe(1)
    expect(guard.next()).toBe(2)
    expect(guard.current()).toBe(2)
  })

  it('detects stale generation', () => {
    const guard = createRaceGuard()
    const gen = guard.current()
    expect(guard.isStale(gen)).toBe(false)
    guard.next()
    expect(guard.isStale(gen)).toBe(true)
  })

  it('current generation is never stale', () => {
    const guard = createRaceGuard()
    guard.next()
    guard.next()
    const gen = guard.current()
    expect(guard.isStale(gen)).toBe(false)
  })
})
