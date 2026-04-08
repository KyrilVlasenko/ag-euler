import { createSimpleProvider } from './createSimpleProvider'
import type { IntrinsicApySourceConfig } from '~/entities/custom'
import type { IntrinsicApyProvider } from '~/entities/intrinsic-apy'

export const createAvantProvider = (sources: readonly IntrinsicApySourceConfig[]): IntrinsicApyProvider =>
  createSimpleProvider({
    providerName: 'Avant',
    providerKey: 'avant',
    extractApy: data => Number((data as { savusdApy?: number }).savusdApy ?? 0),
    sourceUrl: 'https://avantprotocol.com',
  }, sources)
