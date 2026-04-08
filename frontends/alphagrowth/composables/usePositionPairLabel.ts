import type { AccountBorrowPosition } from '~/entities/account'

/**
 * Builds a pair assets label like "BOLD/USDC" or "BOLD & others/USDC"
 * based on whether the position has multiple collaterals.
 */
export function usePositionPairLabel(position: Ref<AccountBorrowPosition | undefined | null>) {
  return computed(() => {
    if (!position.value) return undefined
    const collateralSymbol = position.value.collateral.asset.symbol
    const borrowSymbol = position.value.borrow.asset.symbol
    const hasMultiple = (position.value.collaterals?.length || 0) > 1
    const label = hasMultiple ? `${collateralSymbol} & others` : collateralSymbol
    return `${label}/${borrowSymbol}`
  })
}
