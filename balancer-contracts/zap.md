# Balancer BPT Multiply Zap — Implementation Spec

## Objective

Build a "Multiply" (leveraged looping) flow on Euler V2 where the collateral asset is a **Balancer Pool Token (BPT)** from a shMON/wMON pool on Monad. The user deposits wMON, which gets converted to BPT and used as collateral to borrow more wMON, looping for leverage.

**Target loop:**
```
Borrow wMON → Zap wMON into shMON/wMON BPT → Deposit BPT as collateral → Borrow more wMON → Loop
```

---

## Architecture Overview

The solution has **three layers**, each with distinct deliverables:

| Layer | What | New Code Required |
|-------|------|-------------------|
| **Smart Contract** | Custom Swapper handler that converts wMON ↔ BPT | Yes — `BalancerBptHandler.sol` |
| **Oracle** | BPT pricing for the Euler vault's LTV calculations | Config only — use existing `RateProviderOracle` |
| **Off-chain / Frontend** | Orderflow router strategy + Euler UI integration | Yes — custom strategy + UI config |

---

## Layer 1: Smart Contract — BalancerBptHandler

### Context: How Euler Swaps Work

Euler V2 swaps execute inside an **EVC batch** as a sequence of steps:

1. **Withdraw/Borrow** the input token from a vault → send to the `Swapper` contract
2. **Swapper** executes a swap via a pluggable **handler** (1Inch, Uniswap, etc.)
3. **SwapVerifier** validates the output (trusted, audited contract)
4. **Deposit** the output token into the collateral vault

Key design facts:
- `Swapper.sol` and all handlers are **untrusted** code. The protocol doesn't care what happens inside them — only the `SwapVerifier` result matters.
- Handlers are internal modules addressed by type in the swap parameters. The handler receives tokens and must produce output tokens at a specified receiver address.
- The Swapper has **no access control** — anyone can interact with it. Do NOT leave tokens in it.

### Reference: Existing Handler Pattern

Look at the EVK periphery repo: `euler-xyz/evk-periphery`, branch `development`, path `src/Swaps/`. Examine any existing handler (1Inch, UniswapV3) to understand the interface. The handler receives:
- Input token + amount (already transferred to the Swapper)
- Encoded swap parameters (handler-specific calldata)
- Expected output token
- Receiver address

The handler must:
1. Take the input tokens from its own balance (they were sent to Swapper, which delegatecalls or calls the handler)
2. Execute the conversion
3. Ensure output tokens arrive at the specified receiver

### What to Build: `BalancerBptHandler.sol`

This handler converts between wMON and BPT (shMON/wMON pool) in both directions.

#### wMON → BPT (Opening/Increasing Position)

**Approach A — Balancer V3 Single Token Add Liquidity (RECOMMENDED)**

Balancer V3 Vault exposes `addLiquidity` with kind `UNBALANCED`, which accepts arbitrary amounts of pool tokens. The Router wraps this as `addLiquidityUnbalanced`.

```solidity
// Pseudocode for the handler's core logic
function _zapIntoBpt(uint256 wmonAmount, address receiver) internal {
    // 1. Approve Balancer V3 Router (or Vault via permit2) to spend wMON
    IERC20(WMON).approve(BALANCER_ROUTER, wmonAmount);
    
    // 2. Build the amountsIn array — only wMON has a nonzero value
    //    Token ordering must match the pool's registered token order
    uint256[] memory maxAmountsIn = new uint256[](2);
    maxAmountsIn[WMON_INDEX] = wmonAmount;
    maxAmountsIn[SHMON_INDEX] = 0;
    
    // 3. Call addLiquidityUnbalanced on the Balancer Router
    uint256 bptOut = IBalancerRouter(BALANCER_ROUTER).addLiquidityUnbalanced(
        POOL_ADDRESS,    // address pool
        maxAmountsIn,    // uint256[] exactAmountsIn
        0,               // uint256 minBptAmountOut (SwapVerifier handles slippage)
        false,           // bool wethIsEth
        ""               // bytes userData
    );
    
    // 4. Transfer BPT to receiver
    IERC20(POOL_ADDRESS).transfer(receiver, bptOut);
}
```

**Approach B — Balancer V3 Swap Path (ALTERNATIVE)**

In Balancer V3, when `tokenOut == pool address` in a swap path, the Router automatically performs an `addLiquidity UNBALANCED` operation. This means a standard swap call can produce BPT:

```
SwapPathStep { pool: POOL_ADDRESS, tokenOut: POOL_ADDRESS, isBuffer: false }
```

This may be usable via aggregators that support Balancer V3 paths (LiFi, potentially Balmy SDK). Evaluate whether this path is available on Monad before building a custom handler.

#### BPT → wMON (Closing/Reducing Position)

Reverse the process using `removeLiquidity` with kind `SINGLE_TOKEN_EXACT_IN`:

```solidity
function _zapOutOfBpt(uint256 bptAmount, address receiver) internal {
    // Approve Balancer Router to spend BPT
    IERC20(POOL_ADDRESS).approve(BALANCER_ROUTER, bptAmount);
    
    // Build minAmountsOut — only care about wMON
    uint256[] memory minAmountsOut = new uint256[](2);
    minAmountsOut[WMON_INDEX] = 0; // SwapVerifier handles slippage
    minAmountsOut[SHMON_INDEX] = 0;
    
    // removeLiquidity with SINGLE_TOKEN_EXACT_OUT or proportional + swap
    // Details depend on pool type and desired output
    IBalancerRouter(BALANCER_ROUTER).removeLiquiditySingleTokenExactIn(
        POOL_ADDRESS,
        bptAmount,
        IERC20(WMON),
        0,        // minAmountOut
        false,    // wethIsEth
        ""        // userData
    );
    
    // Transfer wMON to receiver
    uint256 wmonBalance = IERC20(WMON).balanceOf(address(this));
    IERC20(WMON).transfer(receiver, wmonBalance);
}
```

#### Constructor Parameters

```solidity
constructor(
    address _balancerRouter,  // Balancer V3 Router on Monad
    address _balancerVault,   // Balancer V3 Vault on Monad
    address _pool,            // shMON/wMON pool address (also the BPT token)
    address _wmon,            // wMON token address
    address _shmon,           // shMON token address
    uint256 _wmonIndex,       // Index of wMON in the pool's token array
    uint256 _shmonIndex       // Index of shMON in the pool's token array
)
```

#### Security Considerations

1. **The handler is untrusted by design.** The SwapVerifier provides the safety net. Do NOT add complex access control — keep it simple and let the verification layer do its job.
2. **Never hold tokens.** All tokens must be forwarded to the receiver in the same transaction. Sweep any dust.
3. **No reentrancy assumptions.** Balancer V3 Vault uses transient storage for settlement, which means callbacks are possible. The handler should be stateless.
4. **Slippage is NOT the handler's job.** Set `minBptAmountOut = 0` or `minAmountOut = 0` in the Balancer calls. The Euler `SwapVerifier` enforces slippage at the batch level. Adding slippage checks in the handler creates double-bound issues.
5. **Token approval pattern.** Approve only the exact amount needed per call. Do not leave standing approvals on the handler.

---

## Layer 2: Oracle — BPT Pricing

### Existing Infrastructure

Euler's `euler-xyz/euler-price-oracle` repo already contains `RateProviderOracle.sol` — an adapter specifically for Balancer Rate Providers. It:
- Queries `IRateProvider.getRate()` on a Balancer rate provider contract
- Returns quotes via the standard `IPriceOracle` interface
- Uses 18-decimal fixed point (Balancer's native precision)
- Was audited by yAudit (Sept 2024) — a decimals bug was found and fixed

### Configuration

For a Composable Stable Pool (shMON/wMON), the pool itself can serve as a rate provider. The "BPT rate" = `pool invariant / totalSupply`.

**CRITICAL WARNING from Balancer docs:** `getRate()` on Weighted Pools **reverts unconditionally** because the rate is manipulable. For Composable Stable Pools, the rate provider works but carries manipulation risk. Evaluate:

1. **Is the shMON/wMON pool a Composable Stable Pool?** If yes, the pool can be the rate provider.
2. **If Weighted Pool**, you need a TWAP-based oracle or a CrossAdapter that prices BPT via its constituent assets.
3. **Consider a CrossAdapter approach**: Price BPT by computing its NAV from the underlying tokens' prices (wMON + shMON), each priced via their own oracle. This is more manipulation-resistant but requires two oracle feeds.

### Deployment Checklist

- [ ] Determine pool type on Monad (Composable Stable vs Weighted)
- [ ] If Composable Stable: deploy `RateProviderOracle` with pool as rate provider
- [ ] If Weighted: build custom NAV-based adapter or use CrossAdapter
- [ ] Install oracle adapter in the vault's EulerRouter
- [ ] Set appropriate LTV parameters (Borrow LTV, Liquidation LTV) accounting for BPT depeg risk

---

## Layer 3: Off-Chain Integration

### Orderflow Router Strategy

The `euler-xyz/euler-orderflow-router` repo processes swap requests through a **strategy pipeline** per chain. Strategies are defined in `src/swapService/config/`. The pipeline is an ordered array — the first matching strategy handles the request.

**Key precedent:** The router already has a `StrategyERC4626Wrapper` that wraps/unwraps ERC-4626 vault shares before re-running the pipeline with the underlying asset. BPT is conceptually similar (a receipt token for pooled assets).

**New strategy needed: `StrategyBalancerBpt`**

```typescript
// Pseudocode for the strategy
class StrategyBalancerBpt {
    static name() { return "BalancerBpt"; }
    
    async handle(request: SwapRequest): Promise<SwapResponse> {
        // If tokenOut is a BPT address:
        //   1. Calculate how much BPT we get for the input via Balancer queryAddLiquidityUnbalanced
        //   2. Encode the handler calldata for the Swapper
        //   3. Encode SwapVerifier calldata with expected output
        
        // If tokenIn is a BPT address:
        //   1. Calculate how much underlying we get via queryRemoveLiquidity
        //   2. Encode handler calldata for reverse direction
        //   3. Encode SwapVerifier calldata
    }
}
```

**Pipeline configuration for Monad:**
```typescript
const pipeline = [
    {
        strategy: StrategyRepayWrapper.name(),
        match: { isRepay: true, swapperModes: [SwapperMode.EXACT_IN] },
    },
    {
        strategy: StrategyBalancerBpt.name(),
        match: { 
            tokens: [BPT_ADDRESS],  // Match when BPT is involved
        },
        config: {
            pool: POOL_ADDRESS,
            router: BALANCER_ROUTER_ADDRESS,
            handler: BALANCER_BPT_HANDLER_ADDRESS,
        },
    },
    // Fallback to standard aggregators for non-BPT swaps
    {
        strategy: StrategyBalmySDK.name(),
        config: {
            sourcesFilter: { includeSources: ["1inch", "li-fi"] },
        },
    },
]
```

### EVC Batch Construction

The frontend (or any caller) constructs the Multiply batch as:

```typescript
const batchItems = [
    // 1. Borrow wMON from the debt vault
    {
        targetContract: wmonVault,
        onBehalfOfAccount: userSubAccount,
        value: 0,
        data: encodeFunctionData({
            abi: EVAULT_ABI,
            functionName: "borrow",
            args: [borrowAmount, swapperAddress]  // Send directly to Swapper
        })
    },
    // 2. Execute Swapper (calls BalancerBptHandler internally)
    {
        targetContract: swapperAddress,
        onBehalfOfAccount: userSubAccount,
        value: 0,
        data: swapperCalldata  // From orderflow router API
    },
    // 3. Verify swap result
    {
        targetContract: swapVerifierAddress,
        onBehalfOfAccount: userSubAccount,
        value: 0,
        data: verifierCalldata  // From orderflow router API
    },
    // 4. Deposit BPT into collateral vault
    {
        targetContract: bptVault,
        onBehalfOfAccount: userSubAccount,
        value: 0,
        data: encodeFunctionData({
            abi: EVAULT_ABI,
            functionName: "deposit",
            args: [bptAmount, userSubAccount]
        })
    },
]

// Wrap in EVC batch — deferred liquidity check passes at the end
const tx = encodeFunctionData({
    abi: EVC_ABI,
    functionName: "batch",
    args: [batchItems]
});
```

**Note on deferred checks:** The EVC defers solvency checks until the end of the batch. This means the intermediate states (borrowed but not yet deposited collateral) won't revert. The position only needs to be healthy at batch completion.

### Leverage Calculation

For the Multiply UI, the max leverage depends on:
- **Borrow LTV** of BPT collateral vault (set by risk curator)
- **Price impact** of the wMON → BPT conversion at size
- **Oracle price** of BPT vs wMON

```
Max Multiplier ≈ 1 / (1 - Borrow_LTV)
Effective Multiplier = lower due to price impact and slippage
```

For a Composable Stable Pool with correlated assets (shMON ≈ wMON), expect relatively low price impact. A 90% Borrow LTV would give ~10x max leverage. Actual recommended LTVs should be determined by risk analysis of:
- Pool TVL and depth
- shMON/wMON exchange rate stability
- Oracle manipulation surface

---

## Vault Setup Requirements

Before the Multiply flow works, these Euler vaults must exist:

1. **wMON Debt Vault** — standard EVK vault where wMON is the borrowable asset
2. **BPT Collateral Vault** — EVK vault where shMON/wMON BPT is deposited as collateral (may be non-borrowable)
3. **Oracle Router** — configured with BPT pricing adapter, wMON pricing
4. **LTV Configuration** — BPT vault recognized as collateral for the wMON vault with appropriate Borrow LTV and Liquidation LTV

---

## Implementation Order

### Phase 1: Foundation (Week 1)
1. Confirm pool type (Composable Stable vs Weighted) with Balancer team
2. Get Balancer V3 contract addresses on Monad (Router, Vault, Pool)
3. Deploy and test `RateProviderOracle` for BPT pricing (or custom oracle if needed)

### Phase 2: Smart Contract (Week 2)
4. Build `BalancerBptHandler.sol` — start with wMON→BPT direction only
5. Write Foundry fork tests against Monad testnet (or mainnet fork if available)
6. Add BPT→wMON (exit) direction
7. Deploy Swapper with the new handler registered

### Phase 3: Off-Chain (Week 3)
8. Build `StrategyBalancerBpt` for the orderflow router
9. Configure pipeline for Monad chain
10. Test end-to-end batch construction via the API

### Phase 4: Integration (Week 4)
11. Euler frontend configuration for the BPT Multiply strategy
12. End-to-end testing on testnet
13. Risk parameter review with AG / Euler risk team

---

## Key Repositories

| Repo | What to Look At |
|------|----------------|
| `euler-xyz/evk-periphery` (`development` branch) | `src/Swaps/` — Swapper.sol, SwapVerifier.sol, existing handlers |
| `euler-xyz/euler-orderflow-router` (`master` branch) | `src/swapService/strategies/` — strategy pattern, ERC4626 wrapper as reference |
| `euler-xyz/euler-price-oracle` (`master` branch) | `src/adapter/rate/RateProviderOracle.sol` — Balancer rate provider adapter |
| `balancer/balancer-v3-monorepo` (`main` branch) | `pkg/interfaces/contracts/vault/` — IVault, IRouter, VaultTypes |

---

## Open Questions (Resolve Before Building)

1. **What pool type is Balancer deploying on Monad for shMON/wMON?** Composable Stable or Weighted? This determines the oracle approach and handler complexity.
2. **Is Balancer V3 live on Monad, or V2?** The above spec assumes V3. If V2, the Vault API and Router interfaces are different (use `joinPool` instead of `addLiquidity`, BPT preminting changes in composable pools).
3. **What aggregators support Balancer on Monad?** If LiFi or Balmy SDK already route through Balancer V3 on Monad, the custom handler may not be needed — a standard aggregator path could work.
4. **Is there already a wMON debt vault and BPT collateral vault on Euler Monad?** Or do these need to be created as part of this work?
5. **Token ordering in the pool** — which index is wMON and which is shMON? This is immutable at pool creation and must be correct in the handler.