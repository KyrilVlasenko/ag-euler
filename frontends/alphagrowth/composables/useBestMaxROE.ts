import type { MarketGroup } from '~/entities/lend-discovery'
import { type BestMaxRoeResult, getBorrowableVaults, isVaultType } from '~/utils/discoveryCalculations'
import { nanoToValue } from '~/utils/crypto-utils'
import { getMaxMultiplier, getMaxRoe } from '~/utils/leverage'

/**
 * Computes the best max ROE for each market group by iterating all actual
 * collateral/liability pairs with LTV relationships. Uses leveraged return
 * (max ROE) instead of simple net APY spread.
 *
 * Returns a reactive map of marketGroupId -> BestMaxRoeResult.
 */
export const useBestMaxROE = (marketGroups: Ref<MarketGroup[]>) => {
  const { withIntrinsicSupplyApy, withIntrinsicBorrowApy, version: intrinsicVersion } = useIntrinsicApy()
  const { getSupplyRewardApy, getBorrowRewardApy, getLoopingRewardApy, version: rewardsVersion } = useRewardsApy()

  const computeForGroup = (group: MarketGroup): BestMaxRoeResult => {
    const borrowableVaults = getBorrowableVaults(group)

    const allVaults = [...group.vaults, ...group.externalCollateral]
    const knownAddresses = new Set(
      allVaults.map(v => (isVaultType(v) ? v.address : '').toLowerCase()).filter(Boolean),
    )

    let best = -Infinity
    let bestHasRewards = false
    let bestPair = ''
    let bestMultiplier = 1
    let bestSupplyAPY = 0
    let bestBorrowAPY = 0
    let bestBorrowLTV = 0
    let bestBorrowVaultAddress = ''
    let bestCollateralAddress = ''

    for (const liability of borrowableVaults) {
      const borrowBase = nanoToValue(liability.interestRateInfo.borrowAPY, 25)
      const borrowApy = withIntrinsicBorrowApy(borrowBase, liability.asset.address)

      for (const ltv of liability.collateralLTVs) {
        if (ltv.borrowLTV <= 0n) continue
        const colAddr = ltv.collateral.toLowerCase()
        if (!knownAddresses.has(colAddr)) continue

        const collateral = allVaults.find(
          v => isVaultType(v) && v.address.toLowerCase() === colAddr,
        )
        if (!collateral || !isVaultType(collateral)) continue

        const supplyBase = nanoToValue(collateral.interestRateInfo.supplyAPY, 25)
        const supplyApy = withIntrinsicSupplyApy(supplyBase, collateral.asset.address)
        const supplyRewards = getSupplyRewardApy(collateral.address)
        const borrowRewards = getBorrowRewardApy(liability.address, collateral.address)
        const loopingRewards = getLoopingRewardApy(liability.address, collateral.address)

        const supplyFinal = supplyApy + supplyRewards
        const borrowFinal = borrowApy - borrowRewards
        const maxMultiplier = getMaxMultiplier(ltv.borrowLTV)
        const roe = getMaxRoe(maxMultiplier, supplyFinal, borrowFinal, loopingRewards)

        if (roe > best) {
          best = roe
          bestHasRewards = supplyRewards > 0 || borrowRewards > 0 || loopingRewards > 0
          bestPair = `${collateral.asset.symbol}/${liability.asset.symbol}`
          bestMultiplier = maxMultiplier
          bestSupplyAPY = supplyFinal
          bestBorrowAPY = borrowFinal
          bestBorrowLTV = nanoToValue(ltv.borrowLTV, 2)
          bestBorrowVaultAddress = liability.address
          bestCollateralAddress = collateral.address
        }
      }
    }

    const value = Number.isFinite(best) && best > -Infinity ? best : 0
    return {
      value,
      hasRewards: bestHasRewards,
      pair: bestPair,
      maxMultiplier: bestMultiplier,
      supplyAPY: bestSupplyAPY,
      borrowAPY: bestBorrowAPY,
      borrowLTV: bestBorrowLTV,
      borrowVaultAddress: bestBorrowVaultAddress,
      collateralAddress: bestCollateralAddress,
    }
  }

  const bestMaxROEMap = computed((): Map<string, BestMaxRoeResult> => {
    void intrinsicVersion.value
    void rewardsVersion.value

    const result = new Map<string, BestMaxRoeResult>()
    for (const group of marketGroups.value) {
      result.set(group.id, computeForGroup(group))
    }
    return result
  })

  const defaultResult: BestMaxRoeResult = {
    value: 0,
    hasRewards: false,
    pair: '',
    maxMultiplier: 1,
    supplyAPY: 0,
    borrowAPY: 0,
    borrowLTV: 0,
    borrowVaultAddress: '',
    collateralAddress: '',
  }

  const getBestMaxROE = (groupId: string): BestMaxRoeResult => {
    return bestMaxROEMap.value.get(groupId) ?? defaultResult
  }

  return {
    bestMaxROEMap,
    getBestMaxROE,
  }
}
