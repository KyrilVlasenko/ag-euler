import { useAccount } from '@wagmi/vue'
import { SHOW_ALL_HINT_DISMISSED_KEY } from '~/entities/constants'

const dismissed = useLocalStorage<boolean>(SHOW_ALL_HINT_DISMISSED_KEY, false)

export const useShowAllHint = () => {
  const {
    hiddenBorrowCount,
    hiddenDepositCount,
    isPositionsLoaded,
    isDepositsLoaded,
    isShowAllPositions,
  } = useEulerAccount()

  const { isSpyMode } = useSpyMode()
  const { isConnected } = useAccount()

  const hasHiddenPositions = computed(() =>
    hiddenBorrowCount.value > 0 || hiddenDepositCount.value > 0,
  )

  const shouldShowHint = computed(() => {
    return isConnected.value
      && !isSpyMode.value
      && isPositionsLoaded.value
      && isDepositsLoaded.value
      && hasHiddenPositions.value
      && !dismissed.value
      && !isShowAllPositions.value
  })

  const dismissHint = () => {
    dismissed.value = true
  }

  watch(isShowAllPositions, (newVal) => {
    if (newVal && !dismissed.value) {
      dismissed.value = true
    }
  })

  return {
    shouldShowHint,
    hiddenBorrowCount,
    hiddenDepositCount,
    dismissHint,
  }
}
