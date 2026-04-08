import { createSimpleProvider } from './createSimpleProvider'
import type { IntrinsicApySourceConfig } from '~/entities/custom'
import type { IntrinsicApyProvider } from '~/entities/intrinsic-apy'

export const createPufferProvider = (sources: readonly IntrinsicApySourceConfig[]): IntrinsicApyProvider =>
  createSimpleProvider({
    providerName: 'Puffer',
    providerKey: 'puffer',
    extractApy: data => Number((data as { apy?: number }).apy ?? 0),
    sourceUrl: 'https://www.puffer.fi',
  }, sources)
