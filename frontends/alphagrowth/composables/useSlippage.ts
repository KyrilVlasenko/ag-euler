import {
  DEFAULT_SLIPPAGE,
  DEFAULT_STABLECOIN_SLIPPAGE,
  MAX_SLIPPAGE,
  MIN_SLIPPAGE,
  SLIPPAGE_EXPIRY_MS,
  SLIPPAGE_STORAGE_KEY,
  SLIPPAGE_TIMESTAMP_STORAGE_KEY,
} from '~/entities/constants'

interface UseSlippageOptions {
  fromSymbol?: () => string | undefined
  toSymbol?: () => string | undefined
}

interface SwapContext {
  fromSymbol?: string
  toSymbol?: string
}

const isUsdStablecoin = (symbol: string | undefined): boolean => {
  if (!symbol) return false
  return symbol.toUpperCase().includes('USD')
}

const normalizeSlippage = (value: number) => {
  if (!Number.isFinite(value)) {
    return DEFAULT_SLIPPAGE
  }
  return Math.min(MAX_SLIPPAGE, Math.max(MIN_SLIPPAGE, value))
}

export const useSlippage = (options?: UseSlippageOptions) => {
  const userValue = useState<number>(SLIPPAGE_STORAGE_KEY, () => DEFAULT_SLIPPAGE)
  const persistedValue = useLocalStorage<number>(SLIPPAGE_STORAGE_KEY, DEFAULT_SLIPPAGE)
  const setAt = useState<number>(SLIPPAGE_TIMESTAMP_STORAGE_KEY, () => 0)
  const setAtPersisted = useLocalStorage<number>(SLIPPAGE_TIMESTAMP_STORAGE_KEY, 0)

  const swapContext = useState<SwapContext | null>('slippage-swap-context', () => null)

  // Reactive clock for expiry detection (ticks every 60s)
  const now = ref(Date.now())
  useIntervalFn(() => {
    now.value = Date.now()
  }, 60_000)

  // Sync localStorage → state on load
  watch(persistedValue, (val) => {
    const normalized = normalizeSlippage(val)
    if (userValue.value !== normalized) {
      userValue.value = normalized
    }
  }, { immediate: true })

  watch(setAtPersisted, (val) => {
    if (setAt.value !== val) {
      setAt.value = val
    }
  }, { immediate: true })

  // When caller provides swap context, write it to shared state.
  // Deferred to nextTick so getters can reference variables declared
  // after useSlippage() in the calling scope.
  if (options?.fromSymbol || options?.toSymbol) {
    let stopWatch: (() => void) | undefined

    nextTick(() => {
      stopWatch = watchEffect(() => {
        swapContext.value = {
          fromSymbol: options.fromSymbol?.(),
          toSymbol: options.toSymbol?.(),
        }
      })
    })

    onScopeDispose(() => {
      stopWatch?.()
      swapContext.value = null
    })
  }

  const isStablecoinPair = computed(() => {
    const ctx = swapContext.value
    if (!ctx) return false
    return isUsdStablecoin(ctx.fromSymbol) && isUsdStablecoin(ctx.toSymbol)
  })

  const defaultSlippage = computed(() =>
    isStablecoinPair.value ? DEFAULT_STABLECOIN_SLIPPAGE : DEFAULT_SLIPPAGE,
  )

  const isOverrideActive = computed(() => {
    if (setAt.value <= 0) return false
    // Only expire overrides above the general default — low slippage isn't dangerous
    if (userValue.value <= DEFAULT_SLIPPAGE) return true
    return (now.value - setAt.value) < SLIPPAGE_EXPIRY_MS
  })

  const effectiveSlippage = computed(() =>
    isOverrideActive.value ? userValue.value : defaultSlippage.value,
  )

  // Keep persisted value in sync when override expires
  watchEffect(() => {
    const effective = effectiveSlippage.value
    if (userValue.value !== effective) {
      userValue.value = effective
    }
    if (persistedValue.value !== effective) {
      persistedValue.value = effective
    }
  })

  const setSlippage = (value: number) => {
    const normalized = normalizeSlippage(value)
    userValue.value = normalized
    persistedValue.value = normalized

    if (normalized === defaultSlippage.value) {
      setAt.value = 0
      setAtPersisted.value = 0
    }
    else {
      const timestamp = Date.now()
      setAt.value = timestamp
      setAtPersisted.value = timestamp
    }
  }

  return {
    slippage: effectiveSlippage as Ref<number>,
    setSlippage,
    minSlippage: MIN_SLIPPAGE,
    maxSlippage: MAX_SLIPPAGE,
    defaultSlippage,
    isOverrideActive,
  }
}
