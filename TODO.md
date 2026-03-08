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

**Status: LIVE.** Contracts deployed, frontend live at [balancer.alphagrowth.fun](https://balancer.alphagrowth.fun). Lending, borrowing, multiply (Pools 1, 2, 4), Zap BPT, and repay all functional.

**Frontend repo:** `rootdraws/ag-euler-lite-balancer` (fork of euler-lite, customized for Balancer BPT markets)
**Labels repo:** `rootdraws/ag-euler-balancer-labels`
**Vercel project:** `ag-euler-balancer`

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
| Pool 1 BPT Adapter | `0xC904aAB60824FC8225F6c8843897fFba14c8Bf98` |
| Pool 4 BPT Adapter | `0x8753eCb44370fcd4068Dd5BA1BE5bdd85122c832` |

### What's Working

- [x] Contracts deployed (9 scripts: IRM, router, borrow vaults, collateral vaults, oracles, cluster config, operations, 2 adapters)
- [x] Labels repo created and configured
- [x] Frontend deployed on Vercel (`ag-euler-balancer`)
- [x] Lending (deposit into borrow vaults)
- [x] Borrowing (borrow against BPT collateral)
- [x] Multiply — Pool 1 (adapter) and Pool 4 (adapter) — working
- [x] Multiply — Pool 2 (Enso) — working (with safety margin for swap slippage)
- [x] Zap BPT — all 4 pools (Enso for 1-3, adapter for Pool 4)
- [x] Repay — all pools via Enso
- [x] Oracle pricing verified on-chain

### Architecture Decisions (Resolved)

| Decision | Outcome |
|---|---|
| Enso Bundle vs EVC Batch | **EVC Batch + Enso Route** (Architecture B). Enso does not support Euler V2 on Monad. |
| Forward routing (borrow→BPT) | Adapter for Pools 1,4 (ERC4626 wrapped tokens). Enso Route for Pools 2,3. |
| Reverse routing (BPT→borrow) | Enso for all pools. Adapter `zapOut` blocked by pool hooks. |
| Swapper multicall strategy | `swap` + `sweep` (not `deposit`). `deposit()` consumes tokens, breaking `verifyAmountMinAndSkim`. |
| BPT preview method | `ERC4626.previewDeposit` + decimal scaling. `queryAddLiquidityUnbalanced` reverts with `NotStaticCall()` on Monad. |
| Debt safety margin | `max(3× slippage, 1%)` reduction on borrow amount to account for swap price impact. |

### Remaining TODOs

- [ ] **`setFeeReceiver(agAddress)`** on both borrow vaults — once AG has a Monad fee address. Currently revenue goes nowhere.
- [ ] **`setCaps()`** — tighten supply/borrow caps on both borrow vaults. Currently unlimited (0,0). Set sensible limits before any real capital flows.
- [ ] **Pool 3 multiply** — untested. Should work via Enso (same path as Pool 2) but needs verification.
- [ ] **Liquidation testing** — confirm liquidation works end-to-end for BPT-collateralized positions.
- [ ] **Governor transfer** — transfer from deployer EOA to multisig after stable.

