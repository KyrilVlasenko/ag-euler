import { ref, readonly } from 'vue'

const portfolioRefreshCounter = ref(0)

export const usePortfolioRefresh = () => ({
  portfolioRefreshCounter: readonly(portfolioRefreshCounter),
  triggerPortfolioRefresh: () => { portfolioRefreshCounter.value++ },
})
