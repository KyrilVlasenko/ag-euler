# Balancer BPT Collateral Vault Redeployment Plan

**Date:** 2026-04-15
**Chain:** Monad (143)
**Reason:** Pools 2, 3, 4 were deployed with wrong BPT addresses. The correct BPTs are the Merkl-incentivized pools.

---

## Problem Summary

A vault's underlying asset is immutable (baked into the factory proxy's trailing data). We cannot change the BPT on existing vaults — we must deploy new collateral vaults with the correct BPTs and wire them into the existing cluster.

Pool 1 (wnAUSD/wnUSDC/wnUSDT0) is unaffected and stays as-is.

## Address Reference

### Correct BPT Addresses (NEW — Merkl-incentivized)

| Pool | Name | Correct BPT |
|---|---|---|
| Pool 2 | Kintsu (wnSMON/wnWMON) | `0x02b34a02db24179Ac2D77Ae20AA6215C7153E7f8` |
| Pool 3 | Fastlane (wnSHMON/wnWMON) | `0x340Fa62AE58e90473da64b0af622cdd6113106Cb` |
| Pool 4 | AZND (wnLOAZND/AZND/wnAUSD) | `0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE` |

### Wrong BPT Addresses (OLD — currently deployed)

| Pool | Name | Wrong BPT | Old Vault |
|---|---|---|---|
| Pool 2 | Kintsu | `0x3475Ea1c3451a9a10Aeb51bd8836312175B88BAc` | `0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5` |
| Pool 3 | Fastlane | `0x150360c0eFd098A6426060Ee0Cc4a0444c4b4b68` | `0x6660195421557BC6803e875466F99A764ae49Ed7` |
| Pool 4 | AZND | `0xD328E74AdD15Ac98275737a7C1C884ddc951f4D3` | `0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92` |

### Existing Infrastructure (unchanged)

| Contract | Address |
|---|---|
| AlphaGrowth Multisig (governor) | `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C` |
| EulerRouter | `0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73` |
| AUSD Borrow Vault | `0x438cedcE647491B1d93a73d491eC19A50194c222` |
| WMON Borrow Vault | `0x75B6C392f778B8BCf9bdB676f8F128b4dD49aC19` |
| EVault Factory | `0xba4Dd672062dE8FeeDb665DD4410658864483f1E` |
| Balancer V3 Vault | `0xbA1333333333a1BA1108E8412f11850A5C319bA9` |
| Balancer V3 Router | `0x9dA18982a33FD0c7051B19F0d7C76F2d5E7e017c` |
| StableLPOracle Factory | `0xbC169a08cBdCDB218d91Cd945D29B59F78c96B77` |
| ConstantPriceFeed | `0x5DbAd78818D4c8958EfF2d5b95b28385A22113Cd` |
| Pool 1 Vault (unchanged) | `0x5795130BFb9232C7500C6E57A96Fdd18bFA60436` |
| Pool 1 BPT Adapter (unchanged) | `0xC904aAB60824FC8225F6c8843897fFba14c8Bf98` |

### On-Chain Token Order (verified 2026-04-15)

**New Pool 2 — Kintsu** (`0x02b34a02...`):
- [0] wnSMON: `0x08139339dd9A480CEB84D9C7CcE48BE436dB20b3`
- [1] wnWMON: `0xdB39A9D4a1f1b4e93A5684d602207628aD60613C`

**New Pool 3 — Fastlane** (`0x340Fa62A...`):
- [0] wnSHMON: `0x5e073494678fB7FA4a05bB17d45941Dd9Dc469c1`
- [1] wnWMON: `0xdB39A9D4a1f1b4e93A5684d602207628aD60613C`

**New Pool 4 — AZND** (`0xbddb004A...`):
- [0] AZND: `0x4917a5ec9fCb5e10f47CBB197aBe6aB63be81fE8`
- [1] wnAUSD: `0x82c370ba90E38ef6Acd8b1b078d34fD86FC6bAC9`
- [2] wnLOAZND: `0xD786F7569C39A9F64E6A54Eb77db21364E90F279`

Pool 4 token order is identical to the old pool. Pools 2 & 3 use different wrapped token addresses (wnSMON, wnSHMON) but same wnWMON. This does not affect deployment — oracles and vaults only reference the BPT address, not individual pool tokens. Enso routing has been verified to work with the new wrapper addresses.

---

## Deployment Steps

### Phase 1: Permissionless Deploys (deployer wallet)

These are new contract deployments. Any funded wallet can execute them. The deployer becomes the initial governor of new vaults.

#### Script 13: Deploy 3 New Collateral Vaults

**Pattern:** `04_DeployCollateralVaults.s.sol`

Call `IEVaultFactory.createProxy(address(0), true, abi.encodePacked(BPT, address(0), address(0)))` for each new BPT:

| Vault | BPT (underlying) | Borrows against |
|---|---|---|
| New Pool 2 | `0x02b34a02db24179Ac2D77Ae20AA6215C7153E7f8` | WMON borrow vault |
| New Pool 3 | `0x340Fa62AE58e90473da64b0af622cdd6113106Cb` | WMON borrow vault |
| New Pool 4 | `0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE` | AUSD borrow vault |

**Output:** 3 new vault addresses → save as `NEW_POOL2_VAULT`, `NEW_POOL3_VAULT`, `NEW_POOL4_VAULT` in `.env`

#### Script 14: Deploy 3 New LP Oracles + Chainlink Adapters

**Pattern:** `05_DeployOracles.s.sol`

For each new BPT:
1. Deploy `StableLPOracle` via factory — same config as original (constant price feeds for all pool tokens, `shouldRevertIfVaultUnlocked=true`, `shouldUseBlockTimeForOldestFeedUpdate=true`)
2. Deploy `ChainlinkOracle(newBPT, borrowAsset, lpOracle, 72 hours)` adapter

| BPT | Quote (borrow asset) |
|---|---|
| New Pool 2 BPT | WMON `0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A` |
| New Pool 3 BPT | WMON `0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A` |
| New Pool 4 BPT | AUSD `0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a` |

**Output:** 3 LP oracle addresses, 3 Chainlink adapter addresses → save as `NEW_LP_ORACLE_2`, `NEW_LP_ORACLE_3`, `NEW_LP_ORACLE_4`, `NEW_CHAINLINK_2`, `NEW_CHAINLINK_3`, `NEW_CHAINLINK_4` in `.env`. The Chainlink adapter addresses are needed for Safe tx calldata in step 2B.

#### Script 15: Deploy New BPT Adapter for Pool 4

**Pattern:** `08_DeployBptAdapter.s.sol`

Pool 4 uses adapter routing (ERC4626-wrapped tokens). Deploy a new `BalancerBptAdapter` with:
- Router: `0x9dA18982a33FD0c7051B19F0d7C76F2d5E7e017c`
- Pool/BPT: `0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE` (NEW)
- Token configs (same order, same addresses as old pool):
  - [0] AZND `0x4917a5ec...` → no wrap
  - [1] wnAUSD `0x82c370ba...` → wraps AUSD `0x00000000eFE302...`, needsWrap=true
  - [2] wnLOAZND `0xD786F756...` → wraps LOAZND `0x9c82eB49...`, needsWrap=true

**Output:** 1 new adapter address

#### Script 16: Enable Operations

The deployer is the initial governor of the new vaults, so these calls can be made directly:

1. `setHookConfig(address(0), 0)` on each of the 3 new collateral vaults (enables all operations)

**Note:** Governance transfer (`setGovernorAdmin` → multisig) is NOT part of this redeployment. The deployer retains governor access for testing. Transfer to the multisig (`0x4f894Bfc9481110278C356adE1473eBe2127Fd3C`) will be done manually after all vaults are tested and confirmed working.

---

### Phase 1 Verification

Run these checks immediately after Phase 1, before proceeding to Phase 2:

```bash
# Confirm underlying is the correct BPT
cast call $NEW_POOL2_VAULT "asset()(address)" --rpc-url $RPC_URL_MONAD
# Expected: 0x02b34a02db24179Ac2D77Ae20AA6215C7153E7f8
cast call $NEW_POOL3_VAULT "asset()(address)" --rpc-url $RPC_URL_MONAD
# Expected: 0x340Fa62AE58e90473da64b0af622cdd6113106Cb
cast call $NEW_POOL4_VAULT "asset()(address)" --rpc-url $RPC_URL_MONAD
# Expected: 0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE

# Confirm hook config is cleared (operations enabled)
# Expected: address(0), 0
cast call $NEW_POOL2_VAULT "hookConfig()(address,uint32)" --rpc-url $RPC_URL_MONAD
cast call $NEW_POOL3_VAULT "hookConfig()(address,uint32)" --rpc-url $RPC_URL_MONAD
cast call $NEW_POOL4_VAULT "hookConfig()(address,uint32)" --rpc-url $RPC_URL_MONAD

# Confirm governor is deployer
# Expected: 0x8b59FC48E305AFE0934A897F0Cac6cbD3764F3dd
cast call $NEW_POOL2_VAULT "governorAdmin()(address)" --rpc-url $RPC_URL_MONAD
cast call $NEW_POOL3_VAULT "governorAdmin()(address)" --rpc-url $RPC_URL_MONAD
cast call $NEW_POOL4_VAULT "governorAdmin()(address)" --rpc-url $RPC_URL_MONAD

# Test oracle adapters directly (before router wiring)
# Call latestRoundData on each LP oracle — should return a sane BPT price
cast call $NEW_LP_ORACLE_2 "latestRoundData()(uint80,int256,uint256,uint256,uint80)" --rpc-url $RPC_URL_MONAD
cast call $NEW_LP_ORACLE_3 "latestRoundData()(uint80,int256,uint256,uint256,uint80)" --rpc-url $RPC_URL_MONAD
cast call $NEW_LP_ORACLE_4 "latestRoundData()(uint80,int256,uint256,uint256,uint80)" --rpc-url $RPC_URL_MONAD

# Verify caps are factory defaults (0 = unlimited, same as old collateral vaults)
cast call $NEW_POOL2_VAULT "caps()(uint16,uint16)" --rpc-url $RPC_URL_MONAD
cast call $NEW_POOL3_VAULT "caps()(uint16,uint16)" --rpc-url $RPC_URL_MONAD
cast call $NEW_POOL4_VAULT "caps()(uint16,uint16)" --rpc-url $RPC_URL_MONAD

# Test BPT deposit into new collateral vaults (manual small deposit)
```

---

### Phase 2: Multisig Governance Calls (staged rollout)

These calls modify existing contracts governed by the AlphaGrowth multisig. Submit as Safe transactions. **Each step is a separate Safe transaction** — do not batch across steps. Wait for testing and confirmation between steps.

#### Step 2A: Hide new vaults in frontend

**BEFORE submitting any governance transactions**, add the 3 new vault addresses (and old Pools 2 & 3 as a safety net) to the hidden vaults list so they don't appear in the live UI.

Edit `frontends/alphagrowth/entities/hiddenCollateralVaults.ts`:

```typescript
export const HIDDEN_COLLATERAL_VAULTS = new Set([
  '0x578c60e6df60336be41b316fde74aa3e2a4e0ea5', // OLD Pool 2 — wrong Merkl pool
  '0x6660195421557bc6803e875466f99a764ae49ed7', // OLD Pool 3 — wrong Merkl pool
  '0x175831af06c30f2ea5ea1e3f5eba207735eb9f92', // OLD Pool 4 — wrong Merkl pool
  '<new_pool2_vault_lowercase>',                  // NEW Pool 2 — hidden pending testing
  '<new_pool3_vault_lowercase>',                  // NEW Pool 3 — hidden pending testing
  '<new_pool4_vault_lowercase>',                  // NEW Pool 4 — hidden pending testing
])
```

Note: Old Pools 2 & 3 are currently not visible because the WMON product is removed from labels. Adding them to the hidden set is a safety net for when the WMON product is re-added with new vaults.

This file is imported by `useVaults.ts`, `VaultItem.vue`, `VaultOverviewBlockBorrow.vue`, and `VaultCollateralExposureModal.vue`. Any address in this Set (lowercase) is filtered out from all collateral pair listings and UI display.

Deploy this frontend change before proceeding.

#### Step 2B: Wire EulerRouter (Safe tx #1)

On `EulerRouter` (`0x77C3b512...`):

**Oracle configs** — tell the router how to price each new BPT:
```
govSetConfig(0x02b34a02db24179Ac2D77Ae20AA6215C7153E7f8, WMON, NEW_CHAINLINK_2)
govSetConfig(0x340Fa62AE58e90473da64b0af622cdd6113106Cb, WMON, NEW_CHAINLINK_3)
govSetConfig(0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE, AUSD, NEW_CHAINLINK_4)
```

**Resolved vaults** — tell the router what underlying asset each new vault holds (required for collateral value lookups — see balancer-claude.md lesson #14):
```
govSetResolvedVault(NEW_POOL2_VAULT, true)
govSetResolvedVault(NEW_POOL3_VAULT, true)
govSetResolvedVault(NEW_POOL4_VAULT, true)
```

Without `govSetResolvedVault`, the router cannot resolve vault addresses to their BPT underlying, and `getQuote` calls from borrow vaults will fail — borrows against new collateral would revert.

This is non-destructive — only adds new oracle pricing configs and vault resolution entries. Does not affect any existing vaults or positions.

**Verify:** After this tx confirms, test router pricing:

```bash
# getQuote(1e18 BPT, BPT, borrowAsset) — should return a non-zero value
cast call $EULER_ROUTER "getQuote(uint256,address,address)(uint256)" 1000000000000000000 \
  0x02b34a02db24179Ac2D77Ae20AA6215C7153E7f8 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A \
  --rpc-url $RPC_URL_MONAD

cast call $EULER_ROUTER "getQuote(uint256,address,address)(uint256)" 1000000000000000000 \
  0x340Fa62AE58e90473da64b0af622cdd6113106Cb 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A \
  --rpc-url $RPC_URL_MONAD

cast call $EULER_ROUTER "getQuote(uint256,address,address)(uint256)" 1000000000000000000 \
  0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a \
  --rpc-url $RPC_URL_MONAD
```

#### Step 2C: Add new collateral to borrow vaults (Safe tx #2)

On **WMON Borrow Vault** (`0x75B6C392...`):
```
setLTV(NEW_POOL2_VAULT, 9500, 9600, 0)   // 95% borrow / 96% liquidation
setLTV(NEW_POOL3_VAULT, 9500, 9600, 0)
```

On **AUSD Borrow Vault** (`0x438cedcE...`):
```
setLTV(NEW_POOL4_VAULT, 9500, 9600, 0)
```

This only expands what the borrow vaults accept as collateral. **Does not affect existing positions or collateral at all.** Old vaults remain fully functional in parallel.

New vaults are hidden in the UI (step 2A), so real users won't see them yet.

**Test:** Using a **local dev frontend** (with new vaults removed from `hiddenCollateralVaults.ts` and `BPT_ADAPTER_CONFIG` updated with the new Pool 4 adapter), manually test:
- Deposit BPT into new collateral vault
- Borrow against it from the borrow vault
- Full multiply flow (Enso for Pools 2 & 3, adapter for Pool 4)
- Repay and withdraw

Production frontend keeps vaults hidden throughout testing.

#### Step 2D: Remove old collateral from borrow vaults (Safe tx #3)

**Only after new vaults are confirmed working via manual testing:**

On **WMON Borrow Vault** (`0x75B6C392...`):
```
setLTV(0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5, 0, 0, 0)   // old Pool 2
setLTV(0x6660195421557BC6803e875466F99A764ae49Ed7, 0, 0, 0)   // old Pool 3
```

On **AUSD Borrow Vault** (`0x438cedcE...`):
```
setLTV(0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92, 0, 0, 0)   // old Pool 4
```

Setting LTV to 0 prevents new borrows against the old vaults. Existing test positions can still unwind.

#### Step 2E: Transfer governance of new vaults to multisig

From the deployer wallet, call on each new vault:
```
setGovernorAdmin(0x4f894Bfc9481110278C356adE1473eBe2127Fd3C)
```

#### Step 2F: Unhide new vaults + update labels & frontend config

**Last step — only after all on-chain changes are confirmed and governance is transferred.**

1. Update labels (`frontends/labels/alphagrowth/143/`):
   - `products.json`: Replace old vault addresses with new vault addresses in the WMON and AUSD products
   - `vaults.json`: Add entries for the 3 new vault addresses (display name, description, entity)

2. Update frontend `.env` — `NUXT_PUBLIC_CONFIG_BPT_ADAPTER_CONFIG`:
   - Key is the **collateral vault address** (not BPT address)
   - Add new Pool 4 vault as key with new adapter and pool addresses
   - Remove old Pool 4 entry (`0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92`)

3. Update `frontends/alphagrowth/composables/useLoopZap.ts`:
   - Pool 2: update `collateralVault` and `bptAddress` to new addresses
   - Pool 3: update `collateralVault` and `bptAddress` to new addresses
   - Pool 4: update `collateralVault` and `bptAddress` to new addresses

4. Update `frontends/alphagrowth/entities/custom.ts`:
   - Lines ~91-93: Update DefiLlama APY config `address` fields from old BPT to new BPT for Pools 2, 3, 4
   - Lines ~96-98: Update Merkl incentive config `address` fields from old BPT to new BPT for Pools 2, 3, 4
     (the `merklIdentifier` values already point to the correct new BPTs — only the `address` field needs changing)

5. Update `ADAPTER_ONLY_VAULTS` sets — replace old Pool 4 vault address with new Pool 4 vault address in:
   - `frontends/alphagrowth/composables/borrow/useBorrowForm.ts` (line ~389)
   - `frontends/alphagrowth/composables/borrow/useMultiplyForm.ts` (line ~586)
   - `frontends/alphagrowth/pages/position/[number]/multiply.vue` (line ~576)
   Without this, the new Pool 4 vault won't be recognized as adapter-only and multiply will try Enso/standard routing, which will fail for ERC4626-wrapped tokens.

6. Remove all vault addresses from `hiddenCollateralVaults.ts` (old and new — old vaults are invisible once removed from `products.json`, new vaults should now be visible)

7. Deploy frontend changes

**Complete file update checklist for Step 2F:**

| File | What to update |
|---|---|
| `products.json` | Vault addresses |
| `vaults.json` | Add new vault entries |
| `.env` (`BPT_ADAPTER_CONFIG`) | New Pool 4 vault as key |
| `useLoopZap.ts` | `collateralVault` + `bptAddress` for pools 2, 3, 4 |
| `entities/custom.ts` | DefiLlama + Merkl BPT address entries |
| `useBorrowForm.ts` | `ADAPTER_ONLY_VAULTS` — Pool 4 vault address |
| `useMultiplyForm.ts` | `ADAPTER_ONLY_VAULTS` — Pool 4 vault address |
| `multiply.vue` | `ADAPTER_ONLY_VAULTS` — Pool 4 vault address |
| `hiddenCollateralVaults.ts` | Remove all entries |

---

## Script File Summary

| Script | Phase | Description |
|---|---|---|
| `13_RedeployCollateralVaults.s.sol` | 1 (permissionless) | Deploy 3 new collateral vaults with correct BPTs |
| `14_RedeployOracles.s.sol` | 1 (permissionless) | Deploy 3 LP oracles + 3 Chainlink adapters (oracle deployment only, no router wiring) |
| `15_RedeployBptAdapter.s.sol` | 1 (permissionless) | Deploy new BPT adapter for Pool 4 |
| `16_EnableOperations.s.sol` | 1 (permissionless) | Enable ops on new vaults |

Phase 2 governance calls are executed manually via Gnosis Safe — no forge scripts needed. The calldata is straightforward (`govSetConfig`, `setLTV`).

---

## Risk Notes

1. **Existing positions are test-only** — old vaults have test deposits (~407 BPT Pool 2, ~576 BPT Pool 3, ~15.9 BPT Pool 4) and active borrows (~11.6 WMON, ~158 AUSD). These are all test positions and can be ignored.
2. **Old oracle configs** on the router (for old BPTs) must remain — they're needed for correct pricing of existing test positions until they're unwound.
3. **Enso routing verified** — both new Pool 2 and Pool 3 BPTs route successfully via Enso (tested 2026-04-15).
4. **Monad gas quirks** — forge script `--broadcast` may fail on batched transactions. Use `cast send` for individual calls if needed (see script 07 comments).
5. **Pool 4 adapter** — token order is identical to the old pool, so the same adapter logic applies. Only the BPT address changes.
6. **Governance transfer deferred** — new vaults remain governed by the deployer wallet (`0x8b59FC48E305AFE0934A897F0Cac6cbD3764F3dd`) until testing is complete. Transfer to multisig is step 2E.
7. **Multisig execution** — governance calls are submitted via Gnosis Safe at `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C`. Each step is a separate tx — do not batch across steps.
8. **Hidden vaults** — new collateral vaults must be added to `frontends/alphagrowth/entities/hiddenCollateralVaults.ts` BEFORE governance calls. This prevents untested vaults from appearing in the live frontend. The hidden vaults mechanism filters by lowercase address in a Set, checked by `useVaults.ts`, `VaultItem.vue`, `VaultOverviewBlockBorrow.vue`, and `VaultCollateralExposureModal.vue`.
9. **Staged rollout protects production** — adding new collateral (step 2C) does not affect existing positions. Old vaults stay fully functional until explicitly zeroed (step 2D). New vaults are hidden from users until the very last step (step 2F).
