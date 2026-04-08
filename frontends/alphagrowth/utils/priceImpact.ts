export const PRICE_IMPACT_WARNING_THRESHOLD = -5
export const PRICE_IMPACT_DANGER_THRESHOLD = -10
export const SLIPPAGE_WARNING_THRESHOLD = 1

export const isPriceImpactWarning = (impact: number | null): boolean =>
  impact !== null && impact <= PRICE_IMPACT_WARNING_THRESHOLD

export const isPriceImpactDanger = (impact: number | null): boolean =>
  impact !== null && impact <= PRICE_IMPACT_DANGER_THRESHOLD

export const isSlippageWarning = (slippage: number): boolean =>
  slippage > SLIPPAGE_WARNING_THRESHOLD

export const computeMultipliedPriceImpact = (
  directImpact: number | null,
  multiplier: number | null,
): number | null => {
  if (directImpact === null || multiplier === null || multiplier <= 1) return null
  const result = directImpact * multiplier
  return Number.isFinite(result) ? result : null
}
