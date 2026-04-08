import { createSimpleProvider } from './createSimpleProvider'
import type { IntrinsicApySourceConfig } from '~/entities/custom'
import type { IntrinsicApyProvider } from '~/entities/intrinsic-apy'

export const createTreehouseProvider = (sources: readonly IntrinsicApySourceConfig[]): IntrinsicApyProvider =>
  createSimpleProvider({
    providerName: 'Treehouse',
    providerKey: 'treehouse',
    extractApy: data => Number((data as { total_apr_teth?: number }).total_apr_teth ?? 0),
    sourceUrl: 'https://www.treehouse.finance',
  }, sources)
