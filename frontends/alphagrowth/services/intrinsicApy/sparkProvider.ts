import { createSimpleProvider } from './createSimpleProvider'
import type { IntrinsicApySourceConfig } from '~/entities/custom'
import type { IntrinsicApyProvider } from '~/entities/intrinsic-apy'

export const createSparkProvider = (sources: readonly IntrinsicApySourceConfig[]): IntrinsicApyProvider =>
  createSimpleProvider({
    providerName: 'Spark',
    providerKey: 'spark',
    extractApy: (data) => {
      const arr = data as Array<{ sky_savings_rate_apy?: string }>
      return Number(arr[0]?.sky_savings_rate_apy ?? 0) * 100
    },
    sourceUrl: 'https://info-sky.blockanalitica.com',
  }, sources)
