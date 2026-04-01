# ichi-claude.md — ICHI Vault Oracle Kit Context

AI context file for the ICHI Vault Oracle Kit, deployed on Base (8453) as part of the Frax FX Markets cluster.

---

## What This Project Is

A **zero-cost oracle adapter** that lets Euler Finance lending markets accept
ICHI vault shares as collateral without getting flash-loan exploited.

ICHI vaults are concentrated liquidity managers on Algebra V3 DEXes (like
Hydrex on Base). They take single-sided deposits (e.g., deposit only frxUSD),
manage the liquidity range automatically, and issue ERC20 share tokens.

The adapter reads the Algebra pool's **built-in TWAP accumulator** (the
VolatilityOracle plugin) instead of spot price. The plugin writes timepoint
data on every swap for free. We just read it from a different angle.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Euler Lending Market               │
│                                                     │
│  EulerRouter.getQuote(collateralEVault, frxUSD)     │
│       │                                             │
│       ▼                                             │
│  govSetResolvedVault(collateralEVault) → ICHI addr  │
│  govSetConfig(ichiVault, frxUSD, oracleAddr)        │
│       │                                             │
└───────┼─────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────┐
│              ICHIVaultOracle (this adapter)          │
│                                                     │
│  1. Read position liquidity from vault              │
│  2. Fetch TWAP tick from Algebra VolatilityOracle   │
│  3. Recompute token amounts at TWAP price           │
│  4. Add idle vault balances                         │
│  5. Price in quote token, divide by totalSupply     │
│                                                     │
│  Stateless. Pure view functions. No keeper needed   │
│  for the oracle itself.                             │
└───────┬─────────────────────────────────────────────┘
        │ reads
        ▼
┌───────────────────────┐    ┌────────────────────────┐
│    ICHI Vault         │    │  Algebra Pool          │
│                       │    │                        │
│  baseLower/Upper      │    │  VolatilityOracle      │
│  limitLower/Upper     │    │  plugin (TWAP data)    │
│  getBasePosition()    │    │                        │
│  getLimitPosition()   │    │  getTimepoints()       │
│  totalSupply()        │    │  lastTimepointTimestamp │
└───────────────────────┘    └────────────────────────┘
                                      ▲
                                      │ pokes when stale
                             ┌────────┴───────────────┐
                             │    OraclePoke (keeper)  │
                             │    dust swaps to keep   │
                             │    timepoints fresh     │
                             └────────────────────────┘
```

### Two-Layer Router Wiring

Euler's router needs **two** registrations per collateral vault:

1. `govSetConfig(ichiVault, frxUSD, oracle)` — tells the router how to price ICHI shares in frxUSD
2. `govSetResolvedVault(collateralEVault, true)` — resolves the Euler eVault (which IS ERC-4626) to its underlying asset (the ICHI shares), then uses the config above

The collateral eVaults are standard Euler eVaults wrapping ICHI shares. `govSetResolvedVault` is needed so Euler can look up the oracle when pricing collateral during `setLTV`.

---

## Deployed Addresses (Base 8453)

| Contract | Address |
|---|---|
| ICHIVaultOracleFactory | `0x279901f966160dCf3D53236EbEAc08DC372e0821` |
| Oracle (frxUSD/BRZ) | `0xAf9063c6155D11aFe6FB049c11d8014046702F12` |
| Oracle (tGBP/frxUSD) | `0x570E49e1fe27403619446ec348Ba6397019Bd6B7` |
| Oracle (USDC/frxUSD) | `0x53c04a2FF4B8c1F9F3695dBe4d7fE295EdA23ff2` |
| Oracle (IDRX/frxUSD) | `0x8A24Ac8fbA59ebb328Ea2de5DccD19e7EDd450a5` |
| Oracle (KRWQ/frxUSD) | `0xB00D6E2a06a5bD8e624B2b0E0D4D391854431583` |
| OraclePoke | `0x455587b12e079bd1dAc1a16C7470df8F7Fbe69BC` |
| EulerRouter | `0x6565475B4Ed91aD20Ea9C3799fB04648D1a170CA` |

Oracle params: `twapPeriod=1800` (30 min), `maxStaleness=7200` (2 hours).

### ICHI Vaults (single-sided frxUSD on Hydrex)

| # | Pair | ICHI Vault Address |
|---|---|---|
| 0 | frxUSD/BRZ | `0x80CBb36F48fad69069a3B93989EEE3bAD8f3f103` |
| 1 | tGBP/frxUSD | `0x52801C578172c7cb60a0646fc0af6a42A47bA403` |
| 2 | USDC/frxUSD | `0x6F28872Ed9b0dAe3273f5d9eadBeD224f8D24c19` |
| 3 | IDRX/frxUSD | `0x1ffEa4b2d372d2c85fE3A7f28BB1B213dF8c58ED` |
| 4 | KRWQ/frxUSD | `0xdD01Aa17Db58068b877001f3741422DF439c0E0d` |

### Euler Collateral Vaults (eVaults wrapping ICHI shares)

| # | Pair | Collateral eVault Address |
|---|---|---|
| 0 | BRZ | `0xB5587B4BE26608c7a6E6081B50C43AEBbA09E187` |
| 1 | tGBP | `0xd8277Cbb6576085C192b9F920c5447aa5624a84B` |
| 2 | USDC | `0x417E102f1d2BF2E52d0599Da14Fb79dDb4B0b89F` |
| 3 | IDRX | `0x3371667cB5f6676fa14d95c3839da77705E46A39` |
| 4 | KRWQ | `0x764Fb38Fe7519d2544BACBc8A495Cf64c0505b44` |

frxUSD Borrow Vault: `0x42BA0a943EDcc846333642d62F500894b199A798`

---

## The Poke Problem

The Algebra VolatilityOracle only writes new timepoints when swaps happen.
If a pool has no trading activity, the TWAP data goes stale. The adapter
enforces a `maxStaleness` check — if `lastTimepointTimestamp()` is too old,
`getQuote()` reverts, which freezes the lending market (no new borrows).

The `OraclePoke` contract solves this by executing dust-sized swaps (1 wei)
through pools that have gone stale. This triggers the Algebra plugin's
BEFORE_SWAP_FLAG hook, which writes a fresh timepoint. On Base this costs
fractions of a cent per poke.

### Keeper Setup

- **On-chain:** `OraclePoke.sol` at `0x455587b12e079bd1dAc1a16C7470df8F7Fbe69BC`
  - 5 pools registered (indices 0-4 matching the table above)
  - Funded with 0.1 frxUSD (enough for millions of poke cycles)
  - Owner: `0x5304ebB378186b081B99dbb8B6D17d9005eA0448`
- **Off-chain:** `keeper.ts` — viem-based cron bot
  - Checks `getStalePoolIndices()`, calls `pokeStale()` if any are stale
  - Run every 10 minutes via cron
  - **Must use explicit gas limit of 500,000** (see below)
- **Droplet:** DigitalOcean `oracle-keeper` at `134.209.120.52`
  - Setup script: `keeper/setup-droplet.sh`

### Gas Limit Requirement (Critical)

The `pokeStale()` call **MUST** use an explicit gas limit of 500k+. The KRWQ pool's Algebra `beforeSwap` hook + community vault transfer uses slightly more gas than the default estimator predicts. Without an explicit gas limit, the swap runs out of gas inside the OraclePoke's `try/catch`, which silently catches the OOG error — the transaction succeeds (status 1) but with zero logs and no timepoint update.

All 5 pools work correctly with `gas: 500_000n` in the keeper. The other 4 pools happen to work with default gas estimation, but use the explicit limit for all to be safe.

### Keeper Environment Variables

```
POKE_ADDRESS=0x455587b12e079bd1dAc1a16C7470df8F7Fbe69BC
PRIVATE_KEY=<deployer key with Base ETH for gas>
RPC_URL=<Base RPC URL>
```

Run: `cd /opt/oracle-keeper && npx tsx keeper.ts`

Cron: `*/10 * * * * cd /opt/oracle-keeper && export $(cat .env | xargs) && /usr/bin/npx tsx keeper.ts >> /var/log/oracle-keeper.log 2>&1`

---

## Dependencies and Setup

This is a **Foundry** project nested inside `frax-contracts/`. The parent `foundry.toml` sets:
- `src = "ichi-oracle-kit/src"`
- `solc = "0.8.20"`
- `evm_version = "cancun"` (Base supports Cancun since March 2024; required because Euler V2 contracts use `PUSH0`)

### Remappings (in `frax-contracts/remappings.txt`)

```
euler-price-oracle/=lib/euler-price-oracle/src/
@cryptoalgebra/integral-core/=lib/Algebra/src/core/
forge-std/=lib/forge-std/src/
ethereum-vault-connector/=lib/euler-price-oracle/lib/ethereum-vault-connector/src/
@openzeppelin/contracts/=lib/euler-price-oracle/lib/openzeppelin-contracts/contracts/
```

### Algebra Version

The Algebra library must be on tag `v1.2.2-integral` (or compatible `^0.8.0` pragma). The default branch uses `^0.4.0 || ^0.5.0 || ^0.6.0 || ^0.7.0` pragmas in FullMath.sol, which are incompatible with Solc 0.8.x.

```bash
cd lib/Algebra && git checkout v1.2.2-integral
```

---

## Files

```
ichi-oracle-kit/
├── ichi-claude.md                     # This file
├── foundry.toml                       # Reference config (parent foundry.toml is used)
├── script/
│   └── Deploy.s.sol                   # Original single-vault deploy script (reference)
└── src/
    ├── ICHIVaultOracle.sol            # Core TWAP adapter (~170 lines)
    ├── ICHIVaultOracleFactory.sol     # Deploy registry (prevents duplicate deploys per vault)
    ├── interfaces/
    │   └── IMinimal.sol               # Lean interfaces for ICHI/Algebra
    ├── lib/
    │   └── LiqAmounts.sol             # Inlined liquidity math (getAmountsForLiquidity)
    └── keeper/
        ├── OraclePoke.sol             # On-chain poke contract
        ├── keeper.ts                  # Off-chain cron bot (viem + tsx)
        ├── setup-droplet.sh           # DigitalOcean droplet setup script
        └── package.json               # Keeper npm deps (viem, tsx)
```

---

## Known Issues

### `@inheritdoc BaseAdapter` natspec error
The original `ICHIVaultOracle.sol` had a `/// @inheritdoc BaseAdapter` tag that Solc 0.8.20 rejects because the overridden function signature doesn't match. **Fix:** Remove the `@inheritdoc` line.

### OraclePoke import path
The original `OraclePoke.sol` imported from `"./interfaces/IMinimal.sol"` but the file lives at `"../interfaces/IMinimal.sol"`. **Fix:** Correct the relative path.

### Factory blocks duplicate deploys
`ICHIVaultOracleFactory.deploy()` reverts with "already deployed" if an oracle for a vault already exists. To deploy a second oracle with different params (e.g., different maxStaleness), deploy `ICHIVaultOracle` directly via `new ICHIVaultOracle(vault, twapPeriod, maxStaleness)`.

### KRWQ pool poke gas estimation
See the "Gas Limit Requirement" section above. This is the most subtle issue — everything looks correct in simulation but silently fails on-chain without an explicit gas limit.

### Community vault fee transfer
All 5 Algebra pools have community vaults configured. During each swap, the pool transfers a fee portion to the community vault address. This is normal and doesn't affect oracle pricing, but it adds gas overhead to each poke (contributing to the KRWQ gas estimation issue).
