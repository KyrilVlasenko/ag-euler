import { createSimpleProvider } from './createSimpleProvider'
import type { IntrinsicApySourceConfig } from '~/entities/custom'
import type { IntrinsicApyProvider } from '~/entities/intrinsic-apy'

export const createEtherfiProvider = (sources: readonly IntrinsicApySourceConfig[]): IntrinsicApyProvider =>
  createSimpleProvider({
    providerName: 'Ether.fi',
    providerKey: 'etherfi',
    extractApy: (data) => {
      const d = data as { '7_day_apr'?: number, '7_day_restaking_apr'?: number }
      return ((d['7_day_apr'] ?? 0) / 0.9) + (d['7_day_restaking_apr'] ?? 0)
    },
    sourceUrl: 'https://app.ether.fi',
  }, sources)
