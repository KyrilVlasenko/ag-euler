# Balancer BPT Market Parameters (Monad, chain 143)

On-chain parameters snapshot taken 2026-04-13. Use this as reference when redeploying vaults with corrected Balancer pool addresses.

## Governor

All vaults governed by AlphaGrowth Multisig: `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C`

## Borrow Vaults

### AUSD Borrow Vault — `0x438cedcE647491B1d93a73d491eC19A50194c222`

| Parameter | Value |
|---|---|
| Underlying | AUSD `0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a` (6 decimals) |
| IRM address | `0xDB4cA8a900a837033b9d7723CDfbd105d1971B7f` |
| IRM base rate | 0 |
| IRM slope1 | 756,138,630 |
| IRM slope2 | 63,012,954,036 |
| IRM kink | 3,994,319,585 (93%) |
| IRM human-readable | Base=0%, Kink(93%)=10% APY, Max=100% APY |
| Max liquidation discount | 500 (5%) |
| Liquidation cool-off time | 1 |
| Supply cap | 0 (unlimited) |
| Borrow cap | 0 (unlimited) |
| Hook config | address(0), 0 (all ops enabled) |

**IRM history:** 5% (v1, script 01) → 3.5% (v2, script 10) → 15% (v3, script 11) → 10% (v4, script 12)

**Collateral LTVs:**

| Collateral | Borrow LTV | Liquidation LTV | Ramp Duration |
|---|---|---|---|
| Pool 1 `0x5795130BFb9232C7500C6E57A96Fdd18bFA60436` | 9500 (95%) | 9600 (96%) | 0 |
| Pool 4 `0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92` | 9500 (95%) | 9600 (96%) | 0 |

### WMON Borrow Vault — `0x75B6C392f778B8BCf9bdB676f8F128b4dD49aC19`

| Parameter | Value |
|---|---|
| Underlying | WMON `0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A` (18 decimals) |
| IRM address | `0x22d3553a16b595d1789D67edfCbaa8f3cb62E0DE` |
| IRM base rate | 0 |
| IRM slope1 | 1,446,439,121 |
| IRM slope2 | 53,841,818,943 |
| IRM kink | 3,994,319,585 (93%) |
| IRM human-readable | Base=0%, Kink(93%)=20% APY, Max=100% APY |
| Max liquidation discount | 500 (5%) |
| Liquidation cool-off time | 1 |
| Supply cap | 0 (unlimited) |
| Borrow cap | 0 (unlimited) |
| Hook config | address(0), 0 (all ops enabled) |

**IRM history:** 5% (v1, script 01) → 9% (v2, script 10) → 20% (v3, script 11)

**Collateral LTVs:**

| Collateral | Borrow LTV | Liquidation LTV | Ramp Duration |
|---|---|---|---|
| Pool 2 `0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5` | 9500 (95%) | 9600 (96%) | 0 |
| Pool 3 `0x6660195421557BC6803e875466F99A764ae49Ed7` | 9500 (95%) | 9600 (96%) | 0 |

## Collateral Vaults

All collateral vaults have identical risk config:

| Parameter | Value |
|---|---|
| Supply cap | 0 (unlimited) |
| Borrow cap | 0 (unlimited) |
| Hook config | address(0), 0 (all ops enabled) |

### Pool 1 — Stablecoin (wnAUSD/wnUSDC/wnUSDT0)

| Field | Value |
|---|---|
| Vault | `0x5795130BFb9232C7500C6E57A96Fdd18bFA60436` |
| BPT (underlying) | `0x2DAA146dfB7EAef0038F9F15B2EC1e4DE003f72b` |
| BPT Adapter | `0xC904aAB60824FC8225F6c8843897fFba14c8Bf98` |
| Routing | Adapter (ERC4626-wrapped tokens) |
| Merkl identifier | `0x2DAA146dfB7EAef0038F9F15B2EC1e4DE003f72b` (same as BPT) |
| Status | **ACTIVE** — correct pool, Merkl incentives match |

### Pool 2 — Kintsu (sMON/wnWMON)

| Field | Value |
|---|---|
| Vault | `0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5` |
| BPT (underlying) | `0x3475Ea1c3451a9a10Aeb51bd8836312175B88BAc` |
| BPT Adapter | None (Enso routing) |
| Routing | Enso Finance |
| Merkl identifier | `0x02b34a02db24179Ac2D77Ae20AA6215C7153E7f8` |
| Status | **HIDDEN** — BPT does not receive Merkl incentives; correct pool is `0x02b34a02db24179Ac2D77Ae20AA6215C7153E7f8` |

### Pool 3 — Fastlane (shMON/wnWMON)

| Field | Value |
|---|---|
| Vault | `0x6660195421557BC6803e875466F99A764ae49Ed7` |
| BPT (underlying) | `0x150360c0eFd098A6426060Ee0Cc4a0444c4b4b68` |
| BPT Adapter | None (Enso routing) |
| Routing | Enso Finance |
| Merkl identifier | `0x340Fa62AE58e90473da64b0af622cdd6113106Cb` |
| Status | **HIDDEN** — BPT does not receive Merkl incentives; correct pool is `0x340Fa62AE58e90473da64b0af622cdd6113106Cb` |

### Pool 4 — AZND (wnLOAZND/AZND/wnAUSD)

| Field | Value |
|---|---|
| Vault | `0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92` |
| BPT (underlying) | `0xD328E74AdD15Ac98275737a7C1C884ddc951f4D3` |
| BPT Adapter | `0x8753eCb44370fcd4068Dd5BA1BE5bdd85122c832` |
| Routing | Adapter (ERC4626-wrapped tokens) |
| Merkl identifier | `0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE` |
| Status | **HIDDEN** — BPT does not receive Merkl incentives; correct pool is `0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE` |

## Shared Infrastructure

| Contract | Address |
|---|---|
| EulerRouter | `0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73` |
| KinkIRM Factory | `0x05Cccb5d0f1e1D568804453B82453a719Dc53758` |
| Balancer V3 Router | `0x9dA18982a33FD0c7051B19F0d7C76F2d5E7e017c` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| Euler Swapper | `0xB6D7194fD09F27890279caB08d565A6424fb525D` |
| Euler SwapVerifier | `0x65bF068c88e0f006f76b871396B4DB1150dd9EAD` |

## Redeployment Notes

To redeploy Pools 2, 3, 4 with the correct Merkl-incentivized BPT addresses:

1. Deploy new collateral vaults with correct BPT as underlying (script 04 pattern)
2. Deploy new LP oracles + Chainlink adapters for the new BPTs (script 05 pattern)
3. Wire `govSetConfig` + `govSetResolvedVault` on the EulerRouter for new vaults
4. Call `setLTV` on existing borrow vaults to add new collateral vaults (same 95%/96% params)
5. Call `setHookConfig(address(0), 0)` on new collateral vaults to enable operations
6. For Pools 2 & 3 (Enso routing): no adapter needed, verify Enso can route into the new BPTs
7. For Pool 4 (adapter routing): deploy new `BalancerBptAdapter` pointing to the correct BPT
8. Update labels (`products.json`, `vaults.json`) and frontend config (`useLoopZap.ts`, `custom.ts`)
9. Set LTV to 0 on old collateral vaults to remove them from the UI
