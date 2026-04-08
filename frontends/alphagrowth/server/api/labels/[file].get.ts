import { createError, getQuery, getRouterParam } from 'h3'
import { createRateLimiter } from '~/server/utils/rate-limit'
import { createTtlCache } from '~/server/utils/cache'
import { fetchWithTimeout } from '~/server/utils/fetchWithTimeout'
import { logWarn } from '~/server/utils/log'

const TIMEOUT_MS = 10_000
const CACHE_TTL_MS = 300_000

const ALLOWED_FILES = new Set([
  'products.json',
  'entities.json',
  'earn-vaults.json',
  'points.json',
])

const OPTIONAL_FILES = new Set([
  'earn-vaults.json',
  'points.json',
])

const rateLimiter = createRateLimiter({
  max: 1000,
  windowMs: 60_000,
  label: 'labels',
})

const cache = createTtlCache<unknown>({ ttlMs: CACHE_TTL_MS })

function getUpstreamUrl(chainId: number, file: string): string {
  const baseUrl = (process.env.NUXT_PUBLIC_CONFIG_LABELS_BASE_URL || '').trim().replace(/\/+$/, '')
  if (baseUrl) {
    return `${baseUrl}/${chainId}/${file}`
  }

  const repo = process.env.NUXT_PUBLIC_CONFIG_LABELS_REPO || 'euler-xyz/euler-labels'
  const branch = process.env.NUXT_PUBLIC_CONFIG_LABELS_REPO_BRANCH || 'master'
  return `https://raw.githubusercontent.com/${repo}/refs/heads/${branch}/${chainId}/${file}`
}

export default defineEventHandler(async (event) => {
  rateLimiter.consume(event)

  const file = getRouterParam(event, 'file')
  if (!file || !ALLOWED_FILES.has(file)) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid file' })
  }

  const query = getQuery(event)
  const chainId = Number(query.chainId)
  if (!Number.isInteger(chainId) || chainId <= 0) {
    throw createError({ statusCode: 400, statusMessage: 'Invalid chainId' })
  }

  const key = `${chainId}:${file}`

  const cached = cache.get(key)
  if (cached) return cached

  try {
    const resp = await fetchWithTimeout(getUpstreamUrl(chainId, file), TIMEOUT_MS)
    if (!resp.ok) {
      if (resp.status === 404 && OPTIONAL_FILES.has(file)) {
        const stale = cache.getStale(key)
        if (stale) return stale
        const empty: unknown[] = []
        cache.set(key, empty)
        return empty
      }
      throw new Error(`Upstream returned ${resp.status}`)
    }

    const data: unknown = await resp.json()
    cache.set(key, data)
    return data
  }
  catch (err) {
    logWarn('labels', `Failed to fetch ${file} for chain ${chainId}:`, err instanceof Error ? err.message : err)

    const stale = cache.getStale(key)
    if (stale) return stale

    throw createError({ statusCode: 502, statusMessage: 'Upstream error' })
  }
})
