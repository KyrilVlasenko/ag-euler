const SLOW_THRESHOLD_MS = 10_000

export const useSlowLoading = (loading: Ref<boolean>) => {
  const isSlow = ref(false)
  let timer: ReturnType<typeof setTimeout> | null = null

  const cleanup = () => {
    if (timer) {
      clearTimeout(timer)
      timer = null
    }
  }

  watch(loading, (value) => {
    cleanup()
    if (value) {
      timer = setTimeout(() => {
        if (loading.value) {
          isSlow.value = true
        }
      }, SLOW_THRESHOLD_MS)
    }
    else {
      isSlow.value = false
    }
  }, { immediate: true })

  onScopeDispose(cleanup)

  return { isSlow }
}
