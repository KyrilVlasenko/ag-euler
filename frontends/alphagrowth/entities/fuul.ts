export interface FuulPool {
  name: string
  token0_symbol: string
  token0_address: string
}

export interface FuulTrigger {
  type: string
  context: {
    chain_id: number
    token_address?: string
    depositVault?: string
    borrowVault?: string
    min_leverage?: number
    max_leverage?: number
    min_leverage_operator?: string
    max_leverage_operator?: string
  }
}

export interface FuulIncentive {
  conversion: string
  project: string
  protocol: string
  chain_id: number
  pool: FuulPool
  trigger: FuulTrigger
  apr: number
  tvl: number
  refreshed_at: string
}

export interface FuulClaimableReward {
  currency_address: string
  currency_chain_id: string
  currency_name: string
  currency_decimals: number
  amount: string
  project_address: string
  reason: number
  token_id: string
  deadline: number
  proof: string
  signatures: string[]
}

export interface FuulClaimableEntry {
  protocol: string
  chain_id: number
  user_address: string
  pool: FuulPool
  trigger: FuulTrigger
  conversion: string
  project: string
  claimable_rewards: FuulClaimableReward[]
  refreshed_at: string
}
