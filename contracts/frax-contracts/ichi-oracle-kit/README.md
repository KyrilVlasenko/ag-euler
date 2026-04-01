# ICHI Vault Oracle Kit

TWAP-hardened oracle adapter for pricing ICHI vault shares as collateral in
Euler lending markets. Zero oracle subscription cost — reads the Algebra
pool's built-in VolatilityOracle accumulator.

## Components

```
src/
├── ICHIVaultOracle.sol          # Euler price adapter (per vault)
├── ICHIVaultOracleFactory.sol   # Deploy + registry for multiple vaults
├── interfaces/IMinimal.sol      # Minimal interfaces (no dep trees)
├── lib/LiqAmounts.sol           # Inlined liquidity math
└── keeper/
    ├── OraclePoke.sol           # On-chain keeper (covers all pools)
    └── keeper.ts                # Off-chain cron bot
```

## The Problem

ICHI vault's `getTotalAmounts()` reads `globalState().sqrtPriceX96` from the
Algebra pool — that's the live spot price, manipulable via flash loans. If a
lending market naively prices vault shares using spot, an attacker can:

1. Flash loan → manipulate pool price
2. Inflate apparent vault share value
3. Borrow against inflated collateral
4. Repay flash loan, exit with borrowed assets

## The Solution

This adapter replaces spot with a TWAP derived from the same pool's
VolatilityOracle plugin. The Algebra plugin writes timepoint data on every
swap automatically (free). We just read it from the lending market's
perspective.

Specifically:

1. Read raw position liquidity from the vault (`getBasePosition`, `getLimitPosition`)
2. Fetch a TWAP tick from the Algebra VolatilityOracle (`consult` equivalent)
3. Recompute token amounts using TWAP-derived sqrtPrice (not spot)
4. Add idle vault balances (real `balanceOf`, not price-dependent)
5. Price total value in the quote token using the same TWAP
6. Divide by `totalSupply()` pro-rata for the queried share amount

Flash loans can't hold a manipulated price across a 30-minute TWAP window.

## Deployment

### 1. Deploy the Oracle Adapter

```solidity
// For the frxUSD/BRZ ICHI vault on Hydrex (Base)
ICHIVaultOracle oracle = new ICHIVaultOracle(
    0x80CBb36F48fad69069a3B93989EEE3bAD8f3f103,  // vault
    1800,                                          // 30 min TWAP
    7200                                           // 2 hour max staleness
);
```

Or use the factory for multiple vaults:

```solidity
ICHIVaultOracleFactory factory = new ICHIVaultOracleFactory();

factory.deploy(vault_frxUSD_BRZ, 1800, 7200);
factory.deploy(vault_WETH_USDC, 1800, 3600);
factory.deploy(vault_cbETH_WETH, 1800, 3600);
```

### 2. Register in EulerRouter

```solidity
// The vault share token is the "base", the borrow asset is the "quote"
// For the frxUSD loop: collateral = vault shares, borrow = frxUSD
eulerRouter.govSetConfig(
    0x80CBb36F48fad69069a3B93989EEE3bAD8f3f103,  // base: vault shares
    frxUSD_ADDRESS,                                // quote: frxUSD (token0)
    address(oracle)                                // this adapter
);
```

**Important:** ICHI vaults are NOT ERC4626. Do NOT use `govSetResolvedVault`.
Use `govSetConfig` with this adapter as the oracle.

### 3. Deploy the Poke Keeper

```solidity
OraclePoke poke = new OraclePoke();

// Register the Algebra pool underlying the vault
address pool = IICHIVaultMinimal(vault).pool();
poke.addPool(pool, 1800);  // poke if stale > 30 min

// Seed with dust tokens (1 USDC worth of each token is plenty)
IERC20(frxUSD).transfer(address(poke), 1e18);
IERC20(BRZ).transfer(address(poke), 5e18);
```

### 4. Run the Off-chain Keeper

```bash
# Every 10 minutes via cron
*/10 * * * * PRIVATE_KEY=0x... POKE_ADDRESS=0x... npx ts-node keeper.ts

# Or as a systemd timer, or a Railway/Render cron job
```

Cost on Base: ~$0.002 per poke. 20 pools × 6 pokes/hour × 24 hours = ~$0.58/day.

## Constructor Parameters

| Param          | Recommended | Notes                                          |
|----------------|-------------|-------------------------------------------------|
| `twapPeriod`   | 1800        | 30 min. Resist manipulation while tracking real |
|                |             | price moves. Match or exceed vault's own TWAP.  |
| `maxStaleness` | 3600-7200   | Must be >= twapPeriod. Reverts if pool has no   |
|                |             | swaps in this window. Wider for exotic pairs.   |

## Risk Parameters (Euler Vault Config)

### frxUSD/BRZ Single-Sided Vault (frxUSD loop)

The vault is single-sided frxUSD deposit. Collateral is *mostly frxUSD
already*. BRZ exposure is a minority component (~10-20%) that only
accumulates as price moves through the ICHI range.

| Parameter          | Suggested  | Rationale                                     |
|--------------------|------------|-----------------------------------------------|
| Collateral Factor  | 0.75-0.80  | Same-asset loop (borrow frxUSD against frxUSD |
|                    |            | wrapper). BRZ minority exposure well within   |
|                    |            | the 20-25% collateral buffer.                 |
| Borrow Cap         | 50% of TVL | Don't lend more than half the vault's AUM.    |
| Liquidation Bonus  | 5-8%       | Tighter than cross-asset because underlying   |
|                    |            | redeems mostly to the borrow asset.           |
| Max Staleness      | 7200s      | Wider for exotic pair. BRZ minority exposure  |
|                    |            | limits damage from stale pricing.             |

### High-Volume Pairs (WETH/USDC, cbETH/WETH, etc.)

| Parameter          | Suggested  | Rationale                                     |
|--------------------|------------|-----------------------------------------------|
| Collateral Factor  | 0.65-0.75  | More bilateral exposure, higher vol.          |
| Borrow Cap         | 30% of TVL | Conservative for cross-asset.                 |
| Liquidation Bonus  | 10-15%     | CL withdrawal adds slippage.                  |
| Max Staleness      | 3600s      | Active pools, tighter is fine.                |

## What's Omitted (v1 tradeoffs)

**Uncollected fees (tokensOwed):** Skipped. Typically <1% of position value,
not manipulable, and reading them requires computing the vault's position key
via assembly. Adding later:

```solidity
bytes32 key;
address vaultAddr = vault;
int24 lower = v.baseLower();
int24 upper = v.baseUpper();
assembly {
    key := or(shl(24, or(shl(24, vaultAddr), and(lower, 0xFFFFFF))), and(upper, 0xFFFFFF))
}
(, , , uint128 owed0, uint128 owed1) = IAlgebraPool(pool).positions(key);
```

**Bid/ask spread:** `getQuotes()` returns same value for both. Override in v2
to apply a discount to bid (liquidation value) and premium to ask.

**Multi-hop pricing:** If the Euler market quotes in a token that isn't token0
or token1, chain through the EulerRouter:

```
govSetConfig(vaultToken, frxUSD, ichiVaultOracle);  // this adapter
govSetConfig(frxUSD, WETH, chainlinkAdapter);        // second hop
```

The router handles the composition automatically.

## Scaling Playbook

1. **Ship** the frxUSD/BRZ vault as first market (same-asset loop, low risk)
2. **Prove** the adapter works under real conditions
3. **Deploy** across ICHI vaults on deeper Algebra pools (Hydrex, Camelot, etc.)
4. **Approach Redstone** with: "Working oracle pattern for an entire collateral
   category. Co-develop into your framework. I maintain adapter logic, you
   handle push infra and trust layer." Contributor, not customer.
5. **Factory pattern** makes new vault onboarding a single function call

## Dependencies

```
euler-price-oracle    — BaseAdapter, IPriceOracle, Errors, Governable
cryptoalgebra         — FullMath, TickMath (core libraries only)
forge-std             — IERC20 interface
```

## License

GPL-2.0-or-later (matches Euler oracle repo)
