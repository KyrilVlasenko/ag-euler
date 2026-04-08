import { createSimpleProvider } from './createSimpleProvider'
import type { IntrinsicApySourceConfig } from '~/entities/custom'
import type { IntrinsicApyProvider } from '~/entities/intrinsic-apy'

export const createOndoProvider = (sources: readonly IntrinsicApySourceConfig[]): IntrinsicApyProvider =>
  createSimpleProvider({
    providerName: 'Ondo',
    providerKey: 'ondo',
    extractApy: (data) => {
      const assets = (data as { assets?: Array<{ symbol?: string, apy?: number }> }).assets ?? []
      const usdy = assets.find(a => a.symbol?.toLowerCase() === 'usdy')
      return Number(usdy?.apy ?? 0)
    },
    sourceUrl: 'https://ondo.finance',
  }, sources)
