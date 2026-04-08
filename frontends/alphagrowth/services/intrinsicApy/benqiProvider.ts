import { createSimpleProvider } from './createSimpleProvider'
import type { IntrinsicApySourceConfig } from '~/entities/custom'
import type { IntrinsicApyProvider } from '~/entities/intrinsic-apy'

export const createBenqiProvider = (sources: readonly IntrinsicApySourceConfig[]): IntrinsicApyProvider =>
  createSimpleProvider({
    providerName: 'Benqi',
    providerKey: 'benqi',
    extractApy: data => Number((data as { apr?: number }).apr ?? 0) * 100,
    sourceUrl: 'https://benqi.fi',
  }, sources)
