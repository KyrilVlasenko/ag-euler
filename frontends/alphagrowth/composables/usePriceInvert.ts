import { ref, computed, toValue, reactive, watch, type MaybeRefOrGetter } from 'vue'

export function usePriceInvert(
  symbolA: MaybeRefOrGetter<string | undefined>,
  symbolB: MaybeRefOrGetter<string | undefined>,
) {
  const isInverted = ref(false)

  const toggle = () => {
    isInverted.value = !isInverted.value
  }

  const invertValue = (value: number | null | undefined): number | undefined => {
    if (value == null) return undefined
    if (!isInverted.value) return value
    if (value === 0 || !Number.isFinite(value)) return undefined
    return 1 / value
  }

  const displaySymbol = computed(() => {
    const a = toValue(symbolA) || ''
    const b = toValue(symbolB) || ''
    return isInverted.value ? `${b}/${a}` : `${a}/${b}`
  })

  // Auto-invert based on the first valid price value.
  // Call after the price ref/computed is defined to avoid TDZ issues.
  let autoInvertDone = false
  const autoInvert = (value: MaybeRefOrGetter<number | null | undefined>) => {
    watch(
      () => toValue(value),
      (val) => {
        if (autoInvertDone) return
        if (val != null && val > 0 && Number.isFinite(val)) {
          autoInvertDone = true
          isInverted.value = val < 1
        }
      },
      { immediate: true },
    )
  }

  return reactive({ isInverted, toggle, invertValue, displaySymbol, autoInvert })
}
