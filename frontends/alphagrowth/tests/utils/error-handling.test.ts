import { describe, it, expect, vi } from 'vitest'
import { isAbortError, logWarn, catchToFallback } from '~/utils/errorHandling'

describe('isAbortError', () => {
  it('returns true for DOMException AbortError', () => {
    const err = new DOMException('aborted', 'AbortError')
    expect(isAbortError(err)).toBe(true)
  })

  it('returns true for object with name AbortError', () => {
    expect(isAbortError({ name: 'AbortError' })).toBe(true)
  })

  it('returns true for object with name CanceledError (Axios)', () => {
    expect(isAbortError({ name: 'CanceledError' })).toBe(true)
  })

  it('returns false for regular Error', () => {
    expect(isAbortError(new Error('test'))).toBe(false)
  })

  it('returns false for null', () => {
    expect(isAbortError(null)).toBe(false)
  })

  it('returns false for string', () => {
    expect(isAbortError('AbortError')).toBe(false)
  })

  it('returns false for undefined', () => {
    expect(isAbortError(undefined)).toBe(false)
  })

  it('returns false for non-object types', () => {
    expect(isAbortError(42)).toBe(false)
    expect(isAbortError(true)).toBe(false)
  })
})

describe('logWarn', () => {
  it('calls console.warn by default', () => {
    const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
    logWarn('test', 'message')
    expect(spy).toHaveBeenCalledWith('[test]', 'message')
    spy.mockRestore()
  })

  it('calls console.error when severity is error', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
    logWarn('test', 'message', { severity: 'error' })
    expect(spy).toHaveBeenCalledWith('[test]', 'message')
    spy.mockRestore()
  })

  it('does nothing when severity is silent', () => {
    const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    logWarn('test', 'message', { severity: 'silent' })
    expect(warnSpy).not.toHaveBeenCalled()
    expect(errorSpy).not.toHaveBeenCalled()
    warnSpy.mockRestore()
    errorSpy.mockRestore()
  })

  it('includes additional data when provided', () => {
    const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
    logWarn('ctx', 'err', { data: { extra: true } })
    expect(spy).toHaveBeenCalledWith('[ctx]', 'err', { extra: true })
    spy.mockRestore()
  })
})

describe('catchToFallback', () => {
  it('returns function result on success', async () => {
    const result = await catchToFallback(async () => 42, 0)
    expect(result).toBe(42)
  })

  it('returns fallback on error', async () => {
    const thrower = async () => {
      throw new Error('fail')
    }
    const result = await catchToFallback(thrower, 99)
    expect(result).toBe(99)
  })

  it('logs error when logContext provided', async () => {
    const spy = vi.spyOn(console, 'warn').mockImplementation(() => {})
    const thrower = async () => {
      throw new Error('fail')
    }
    await catchToFallback(thrower, 99, 'test/ctx')
    expect(spy).toHaveBeenCalled()
    spy.mockRestore()
  })
})
