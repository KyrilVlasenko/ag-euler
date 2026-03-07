# AG-Euler — TODO

Consolidated task tracker across all partner deployments and repo-wide work.

---

## Repo-Wide

### Repo Reorganization + Shared Lib Deduplication

Current layout (`cork-contracts/`, `balancer-contracts/`) doesn't scale — adding a third partner means `threshold-contracts/`, `infinifi-contracts/`, etc. Reorganize into a cleaner structure:

```
AG-Euler/
├── contracts/
│   ├── cork/
│   ├── balancer/
│   ├── <next-partner>/
│   └── shared/           ← deduplicated libs (forge-std, euler-price-oracle, evk-periphery)
├── labels/
│   ├── cork/             ← currently rootdraws/ag-euler-cork-labels (separate repo)
│   ├── balancer/         ← currently rootdraws/ag-euler-balancer-labels (separate repo)
│   └── <next-partner>/
├── euler-lite/
├── reference/
└── ...
```

Do this carefully — nothing should break.

- [ ] Plan the migration (verify no hardcoded paths in scripts, CI, or Vercel)
- [ ] Move `cork-contracts/` → `contracts/cork/`
- [ ] Move `balancer-contracts/` → `contracts/balancer/`
- [ ] Create `contracts/shared/` with deduplicated `forge-std`, `euler-price-oracle`, `evk-periphery`
- [ ] Update each partner's `foundry.toml` and `remappings.txt` to point at `../shared/`
- [ ] Delete duplicated copies from each partner dir
- [ ] Verify both `forge build` still compile clean
- [ ] Decide whether labels stay as separate GitHub repos or move into `labels/` (labels must be fetchable via raw GitHub URL — local paths won't work without a frontend change)

---

## Cork Protocol — Ethereum Mainnet

Contracts deployed and verified. Labels live at `rootdraws/ag-euler-cork-labels`. Frontend at [cork.alphagrowth.fun](https://cork.alphagrowth.fun).

### Liquidator — CRITICAL: Redeploy Required

The mainnet-deployed liquidator (`0x1e95cC20ad3917ee523c677faa7AB3467f885CFe`) has a **bug in the seizure order** — it seizes vbUSDC before cST, which causes `InvalidParams()` on every liquidation because zero cST is seized when the violator's debt is already cleared. The fixed version (in `cork-contracts/src/liquidator/CorkProtectedLoopLiquidator.sol`) seizes cST first, then vbUSDC, and caps the Cork exercise amount via `previewExercise`. Tested end-to-end on Tenderly fork — full liquidation cycle succeeds.

- [ ] **Redeploy fixed `CorkProtectedLoopLiquidator` to mainnet** — run `07_DeployLiquidator.s.sol` with updated source
- [ ] **Send NEW liquidator address to Cork team for whitelist** — old address is useless
- [ ] **Confirm Cork whitelist on new address** — `WhitelistManager.addToMarketWhitelist(poolId, newAddress)`
- [ ] **Also whitelist deployer EOA** `0x5304ebB378186b081B99dbb8B6D17d9005eA0448` for minting test cST

### Liquidation Bot — Built, Needs Production Deploy

Bot scripts at `cork-contracts/script/bot/`. Tested manually on Tenderly fork (successful liquidation: ~6000 sUSDe debt cleared, ~291 sUSDe profit). Uses `cast` (Foundry) and runs as a polling loop.

- [x] Bot scripts created (`setup.sh`, `run.sh`, `.env.example`)
- [x] Bot tested on Tenderly fork — full liquidation cycle confirmed
- [ ] **Deploy bot to Digital Ocean** — install Foundry, configure `.env` with mainnet RPC + bot private key
- [ ] **Fund bot wallet with ETH** for gas on mainnet
- [ ] **Run `setup.sh`** on mainnet (enable controller, set operator, approve sUSDe)
- [ ] **Start `run.sh`** as a systemd service or `nohup` background process

### Post-Deployment Testing

- [x] Borrow tested on Tenderly — hook enforces dual-collateral pairing (vbUSDC + cST)
- [x] Liquidation tested on Tenderly — full cycle works with fixed contract
- [x] Frontend deployed at cork.alphagrowth.fun (Tenderly fork demo)
- [ ] **Acquire mainnet test assets:**
  - vbUSDC: approve USDC → deposit into Cork's vbUSDC vault (1:1)
  - sUSDe: buy via Ethena or DEX
  - cST: `CorkPoolManager.mint()` — requires Cork whitelist on deployer EOA
- [ ] **Switch cork.alphagrowth.fun to mainnet** — update `.env` from Tenderly RPC to mainnet RPC, remove fork chain mapping if not needed
- [ ] **Verify on cork.alphagrowth.fun** — cluster appears, vaults load, deposit/borrow UI works on real mainnet
- [ ] **Test borrow on mainnet** — deposit vbUSDC + cST, borrow sUSDe
- [ ] **Test liquidation on mainnet** — create unhealthy position, confirm end-to-end

### Blocked on Cork Team

Require `CorkSeriesRegistry` which Cork has not deployed.

- [ ] **H_pool auto-reduction near expiry** — oracle should reduce `hPool → 0` if no valid successor cST exists within `liqWindow`. Mitigation: governor manually calls `CorkOracleImpl.setHPool(0)` before expiry.
- [ ] **Borrow restriction within liqWindow** — hook should block new borrows near expiry without successor cST. Same dependency.
- [ ] **Rollover exception in hook** — `RolloverOperator` temporarily moves cST within EVC batch. Not needed until April 19, 2026.

### Ongoing Monitoring

- [ ] **Rollover operator** — keeper for cST_old → cST_new before expiry. Must be operational before April 19, 2026.
- [ ] **hPool governance** — if Cork pool impaired, call `CorkOracleImpl.setHPool(value)` to reduce collateral value.
- [ ] **Governor transfer** — after demo stable, transfer from deployer EOA to multisig via `setGovernorAdmin` (borrow vault) and `transferGovernance` (router).

---

## Balancer — Monad (Chain 143)

Contracts deployed. 6/6 scripts broadcast successfully. All vaults, oracles, and cluster config are live on-chain. Frontend integration has not started.

### Deployed Addresses

| Contract | Address |
|---|---|
| KinkIRM | `0x2CB88c8E5558380077056ECb9DDbe1e00fdbC402` |
| EulerRouter | `0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73` |
| AUSD Borrow Vault | `0x438cedcE647491B1d93a73d491eC19A50194c222` |
| WMON Borrow Vault | `0x75B6C392f778B8BCf9bdB676f8F128b4dD49aC19` |
| Pool1 Vault (wnAUSD/wnUSDC/wnUSDT0) | `0x5795130BFb9232C7500C6E57A96Fdd18bFA60436` |
| Pool2 Vault (sMON/wnWMON) | `0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5` |
| Pool3 Vault (shMON/wnWMON) | `0x6660195421557BC6803e875466F99A764ae49Ed7` |
| Pool4 Vault (wnLOAZND/AZND/wnAUSD) | `0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92` |

### Contract TODOs

- [ ] **`setFeeReceiver(agAddress)`** on both borrow vaults — once AG has a Monad fee address. Currently revenue goes nowhere.
- [ ] **`setCaps()`** — tighten supply/borrow caps on both borrow vaults. Currently unlimited (0,0). Set sensible limits before any real capital flows.

### Labels Repo — `rootdraws/ag-euler-balancer-labels`

The critical path item. Without this, the frontend shows zero vaults.

- [ ] **Create GitHub repo** `rootdraws/ag-euler-balancer-labels`
- [ ] **`143/products.json`** — two products with deployed vault addresses:
  ```json
  {
    "ausd-bpt-leverage": {
      "name": "Stablecoin BPT Leverage",
      "description": "Borrow AUSD against Balancer stablecoin BPT collateral on Monad",
      "entity": ["alphagrowth", "balancer", "euler"],
      "url": "https://balancer.fi",
      "vaults": [
        "0x438cedcE647491B1d93a73d491eC19A50194c222",
        "0x5795130BFb9232C7500C6E57A96Fdd18bFA60436",
        "0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92"
      ]
    },
    "wmon-bpt-leverage": {
      "name": "MON LST BPT Leverage",
      "description": "Borrow WMON against Balancer LST BPT collateral on Monad",
      "entity": ["alphagrowth", "balancer", "euler"],
      "url": "https://balancer.fi",
      "vaults": [
        "0x75B6C392f778B8BCf9bdB676f8F128b4dD49aC19",
        "0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5",
        "0x6660195421557BC6803e875466F99A764ae49Ed7"
      ]
    }
  }
  ```
- [ ] **`143/vaults.json`** — display names for each vault
- [ ] **`143/entities.json`** — entries for `alphagrowth`, `balancer`, `euler`
- [ ] **`143/points.json`** — `[]`
- [ ] **`143/opportunities.json`** — `{}`
- [ ] **`logo/alphagrowth.svg`** — already exists in `public/entities/`, copy over
- [ ] **`logo/balancer.svg`** — source from Balancer brand assets
- [ ] **`logo/euler.svg`** — source from Euler brand assets

### Multiply Position — Enso Bundle Integration

The core product feature: one-click leveraged BPT positions. Uses Enso's Bundle API to compose flashloan + Balancer V3 zap + Euler deposit/borrow into a single atomic transaction. Full spec in `balancer-contracts/zap.md`.

**Phase 1: Validate Enso on Monad (FIRST — gates everything below)**

- [ ] **Check Enso protocol support:** `GET https://api.enso.build/api/v1/protocols?chainId=143` — look for `euler-v2` and `balancer-v3`
- [ ] **Test Enso route wMON → BPT:** `GET /api/v1/shortcuts/route?chainId=143&tokenIn=WMON&tokenOut=BPT&amountIn=1e18` — confirms Balancer V3 zap works
- [ ] **Test Enso bundle with Euler V2:** `POST /api/v1/shortcuts/bundle` with `protocol: "euler-v2"` deposit + borrow — confirms Euler V2 is supported
- [ ] **Decision gate:** Enso supports both → Architecture A. Balancer only → Architecture B (hybrid). Neither → Architecture C (custom handler). See `zap.md` for full decision tree.

**Phase 2: Build Integration (after Phase 1 decision)**

- [ ] **Get Enso API key** at [enso.finance/developers](https://enso.finance/developers) for production use
- [ ] **Create `server/api/enso/bundle.post.ts`** — Nitro server proxy to Enso Bundle API (keeps API key server-side)
- [ ] **Create `server/api/enso/route.get.ts`** — Nitro server proxy to Enso Route API
- [ ] **Create `composables/useEnsoBundle.ts`** — Enso API client composable
- [ ] **Adapt `useMultiplyForm.ts`** — support Enso bundle path for BPT vault pairs
- [ ] **Add Enso tx execution path** in `useEulerOperations/execution.ts` (single tx format vs multi-step TxPlan)
- [ ] **Test multiply flow end-to-end** — deposit wMON, multiply to BPT, verify position

**Phase 3: Unwind (reduce/close position)**

- [ ] **Test reduce multiply** — partial BPT → wMON conversion via Enso route (Balancer `removeLiquiditySingleTokenExactIn`)
- [ ] **Test full close** — withdraw all BPT collateral, repay all wMON debt
- [ ] **Verify liquidation path** — confirm liquidation works for BPT-collateralized positions

### Frontend Patch

Upstream `EulerChains.json` already includes chain 143 (Monad). Verify whether the address injection in `useEulerAddresses.ts` is still needed, or if setting `RPC_URL_HTTP_143` is sufficient.

- [ ] **Test with just `RPC_URL_HTTP_143` set** — if Monad vaults load, no code change needed
- [ ] **If not:** inject Monad addresses into `useEulerAddresses.ts` (fallback patch from `balancer-TODO.md` TODO 3)
- [ ] **Add `balancer.svg`** to `euler-lite/public/entities/`
- [ ] **Add Monad token icons** to `euler-lite/assets/tokens/` if needed (WMON, AUSD, BPT tokens)

### Vercel Deployment — `balancer.alphagrowth.fun`

- [ ] **Create new Vercel project** → source: `rootdraws/ag-euler-lite`
- [ ] **Set custom domain** `balancer.alphagrowth.fun`
- [ ] **Configure env vars:**
  ```
  NUXT_PUBLIC_APP_URL=https://balancer.alphagrowth.fun
  RPC_URL_HTTP_143=<monad-rpc-url>
  NUXT_PUBLIC_SUBGRAPH_URI_143=<goldsky-monad-subgraph-url>
  NUXT_PUBLIC_CONFIG_LABELS_REPO=rootdraws/ag-euler-balancer-labels
  NUXT_PUBLIC_CONFIG_LABELS_REPO_BRANCH=main
  NUXT_PUBLIC_CONFIG_APP_TITLE="Alpha Growth × Balancer — BPT Leverage"
  NUXT_PUBLIC_CONFIG_APP_DESCRIPTION="BPT leverage on Monad, curated by Alpha Growth."
  NUXT_PUBLIC_CONFIG_ENABLE_EARN_PAGE=false
  NUXT_PUBLIC_CONFIG_ENABLE_EXPLORE_PAGE=false
  NUXT_PUBLIC_CONFIG_ENABLE_LEND_PAGE=true
  NUXT_PUBLIC_CONFIG_ENABLE_ENTITY_BRANDING=true
  NUXT_PUBLIC_CONFIG_ENABLE_VAULT_TYPE=true
  APPKIT_PROJECT_ID=6a6da30f10e95d57f86c538e2edc4ea6
  NUXT_PUBLIC_EULER_API_URL=https://indexer.euler.finance
  NUXT_PUBLIC_SWAP_API_URL=https://swap-dev.euler.finance
  NUXT_PUBLIC_PRICE_API_URL=https://indexer.euler.finance
  NUXT_PUBLIC_PYTH_HERMES_URL=https://hermes.pyth.network
  ```
- [ ] **Verify deployment** — vaults appear, branding correct, wallet connect works

### Smoke Test

- [ ] **Deposit BPT into a collateral vault** via the UI
- [ ] **Borrow AUSD or WMON** against BPT collateral
- [ ] **Verify oracle pricing** — vault shows correct BPT valuation
- [ ] **Verify liquidation path** — create undercollateralized position, confirm liquidation works

