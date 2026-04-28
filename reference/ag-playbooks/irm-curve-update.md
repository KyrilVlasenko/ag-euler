# Playbook: Update IRM curves on a deployed Euler V2 vault

End-to-end runbook for changing the borrow rate curve on an existing Euler V2 vault. Generic across partners — written from the AUSD/WMON Balancer-Monad update on 2026-04-28, but the procedure is the same for any vault using `IRMLinearKink` from the canonical Euler `EulerKinkIRMFactory`.

---

## When to use this

Any time you want to change `baseRate`, `slope1`, `slope2`, or `kink` on a live vault. Examples:
- Lower max APY because utilization is sticky high (AUSD/WMON, 2026-04-28).
- Raise kink rate when collateral incentives launch (AUSD/WMON v2→v3, see `MARKET_PARAMETERS.md` history).
- Move the kink utilization point.

## Why it's a full redeploy

`IRMLinearKink` constructor params are `immutable` (see `reference/euler-vault-kit/src/InterestRateModels/IRMLinearKink.sol`). You can't mutate them. To change a curve you must:

1. Deploy a **new** `IRMLinearKink` via the canonical `EulerKinkIRMFactory`.
2. Call `setInterestRateModel(newIrm)` on the vault.

Step 2 is `governorOnly` (`reference/euler-vault-kit/src/EVault/modules/Governance.sol:333`). On a live AG market, the governor is usually the AG Safe multisig (`0x4f894Bfc9481110278C356adE1473eBe2127Fd3C` on Monad), so step 2 is a Safe transaction. Pre-Safe-handover deployments (e.g. fresh deploy in the same session as the script) called this directly from the EOA — see `script/10_UpdateIRM.s.sol` and `script/11_UpdateIRM_v2.s.sol` for that older pattern.

`setInterestRateModel` accrues interest using the **old** IRM via `updateVault()` before swapping in the new one, then computes the first new rate against the new IRM. No manual accrual or pause needed.

---

## Step 0 — Decide the new curve

Pick `(baseRate%, kinkRate%, maxRate%, kinkUtilization%)`. Then run:

```bash
node reference/evk-periphery/script/utils/calculate-irm-linear-kink.js \
  borrow <baseRate> <kinkRate> <maxRate> <kinkUtilization>

# Example: 0% base, 8% at 93% kink, 80% max
node reference/evk-periphery/script/utils/calculate-irm-linear-kink.js borrow 0 8 80 93
# →   0, 610566643, 53841818838, 3994319585
```

Output is `baseRate, slope1, slope2, kink` in factory-constructor order. The `kink` value is `floor(kinkUtilization * 2^32)`, so 93% → 3,994,319,585.

The factory enforces a 1000% APY ceiling and runs `computeInterestRateView` at deploy as a sanity probe (`reference/evk-periphery/src/IRMFactory/EulerKinkIRMFactory.sol`). Anything above that, or a malformed IRM, reverts at deploy.

---

## Step 1 — Pre-flight checks

```bash
cd contracts/<partner>-contracts
source .env

# Deployer has gas
cast balance $DEPLOYER --rpc-url $RPC_URL_<CHAIN> --ether

# Each vault's governor is the expected Safe (or EOA, for pre-handover)
cast call <BORROW_VAULT> "governorAdmin()(address)" --rpc-url $RPC_URL_<CHAIN>

# Safe threshold (so you know how many sigs you need)
cast call <SAFE> "getThreshold()(uint256)" --rpc-url $RPC_URL_<CHAIN>

# Snapshot current IRM, in case rollback is needed
cast call <BORROW_VAULT> "interestRateModel()(address)" --rpc-url $RPC_URL_<CHAIN>
```

---

## Step 2 — Write the deploy script

Template — adapt for any number of vaults:

```solidity
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";

interface IKinkIRMFactory {
    function deploy(uint256 baseRate, uint256 slope1, uint256 slope2, uint32 kink)
        external returns (address irm);
}

contract LowerIRM_<MARKET> is Script {
    address constant KINK_IRM_FACTORY = 0x...;  // chain-specific

    uint256 constant BASE   = 0;
    uint256 constant SLOPE1 = ...;  // from calculator
    uint256 constant SLOPE2 = ...;
    uint32  constant KINK   = ...;

    function run() external {
        vm.broadcast();
        address irm = IKinkIRMFactory(KINK_IRM_FACTORY).deploy(
            BASE, SLOPE1, SLOPE2, KINK
        );
        console.log("NEW_IRM=%s", irm);
    }
}
```

Conventions to keep:
- **One `vm.broadcast()` per IRM**, not `startBroadcast`/`stopBroadcast` wrapping all of them. If a later deploy reverts, the earlier one still gets a clean broadcast artifact.
- **Do NOT call `setInterestRateModel` from this script** if the governor is a Safe. That call belongs in the Safe JSON.
- Reference scripts: `contracts/balancer-contracts/script/17_LowerIRM_AUSD_WMON.s.sol` (Safe-governed pattern), `script/12_UpdateIRM_AUSD_v3.s.sol` (single market), `script/11_UpdateIRM_v2.s.sol` (two markets).

### Known kink IRM factory addresses

| Chain | Factory |
|---|---|
| Monad (143) | `0x05Cccb5d0f1e1D568804453B82453a719Dc53758` |

Add new chains here as they're used.

---

## Step 3 — Broadcast

```bash
source .env && forge script script/<NN>_LowerIRM_<MARKET>.s.sol \
  --rpc-url $RPC_URL_<CHAIN> --private-key $PRIVATE_KEY \
  --broadcast --gas-estimate-multiplier 400
```

`--gas-estimate-multiplier 400` is needed on Monad (estimator quirk) — drop or lower on other chains.

The factory is permissionless; any funded EOA can deploy. The deployer doesn't need governor rights.

Capture the new IRM addresses from `console.log` stdout, OR from `broadcast/<script>/<chainId>/run-latest.json` (factory-deployed contracts appear under `additionalContracts` of the relevant transaction, since the inner `CREATE` is from the factory, not the script).

---

## Step 4 — Mandatory gate: verify the deployed IRM matches the script

**Before generating any Safe JSON.** This catches transcription errors and wrong-network deploys before signers commit.

```bash
NEW_IRM=0x...
cast call $NEW_IRM "baseRate()(uint256)" --rpc-url $RPC_URL_<CHAIN>
cast call $NEW_IRM "slope1()(uint256)"   --rpc-url $RPC_URL_<CHAIN>
cast call $NEW_IRM "slope2()(uint256)"   --rpc-url $RPC_URL_<CHAIN>
cast call $NEW_IRM "kink()(uint256)"     --rpc-url $RPC_URL_<CHAIN>
```

Each must match the script constants exactly.

Per-second rate sanity probe at the kink (utilization == kink == 93%):

```bash
# cash + borrows = type(uint32).max so utilization == borrows. borrows == kink → utilization == 93%.
cast call $NEW_IRM "computeInterestRateView(address,uint256,uint256)(uint256)" \
  0x0000000000000000000000000000000000000000 300647711 3994319585 \
  --rpc-url $RPC_URL_<CHAIN>
```

Expected raw value: `slope1 * kink` (per-second rate scaled by 1e27). Convert to APY:

```
APY = exp(rate * 31556952 / 1e27) - 1
```

(`computeInterestRateView`'s first arg is the vault address, but `IRMLinearKink` ignores it — pass `address(0)`. Don't try `computeInterestRate` from `cast`: it asserts `msg.sender == vault` and reverts with `E_IRMUpdateUnauthorized()`.)

If anything mismatches, **stop**. Re-deploy with corrected constants.

---

## Step 5 — Generate the Safe Transaction Builder JSON

One transaction per vault, batched into a single Safe multisend:

```json
{
  "version": "1.0",
  "chainId": "<chain>",
  "createdAt": <unix-ms>,
  "meta": {
    "name": "Lower <MARKET> IRM curves",
    "description": "..."
  },
  "transactions": [
    {
      "to": "<BORROW_VAULT>",
      "value": "0",
      "data": null,
      "contractMethod": {
        "inputs": [{ "name": "newModel", "type": "address", "internalType": "address" }],
        "name": "setInterestRateModel",
        "payable": false
      },
      "contractInputsValues": { "newModel": "<NEW_IRM>" }
    }
  ]
}
```

Reference: `contracts/balancer-contracts/redeployment-scripts/safe-tx-2c-add-new-collateral.json` for working schema, `safe-tx-lower-ausd-wmon-irm.json` for the IRM-update pattern.

Also emit raw calldata as a fallback (so signers can paste it into the Safe UI manually if the JSON import fails):

```bash
cast calldata "setInterestRateModel(address)" $NEW_IRM
```

Selector for `setInterestRateModel(address)`: `0x8bcd4016`.

---

## Step 6 — Execute the Safe transaction

1. Open the AG Safe in the Safe UI on the target chain.
2. Apps → Transaction Builder → drag the JSON in.
3. **Verify decoded calls** — `to` is the vault, `newModel` is the deployed IRM.
4. Click **Simulate** (Tenderly, built into the Safe UI). Both calls should succeed.
5. Propose → collect signatures to threshold → execute.
6. Save the executed Safe tx hash.

The batched calls run atomically via Safe's `MultiSendCallOnly` — either all succeed or all revert.

---

## Step 7 — Post-execution on-chain verification

```bash
cast call <BORROW_VAULT> "interestRateModel()(address)" --rpc-url $RPC_URL_<CHAIN>
# Expected: $NEW_IRM
```

Optional: read `interestAccumulator()` and `lastInterestUpdate()` to confirm the accrual pass happened during the swap.

---

## Step 8 — MonadScan verification (chain 143 specific; analog for other chains)

This is the trickiest part. The CLAUDE.md gotcha says `forge verify-contract --chain 143 --verifier etherscan` doesn't work because forge doesn't know chain 143. **It does work via the Etherscan V2 API multi-chain endpoint with explicit `--verifier-url`.** Recipe:

### 8.1 — Find the *right* compiler version

`IRMLinearKink` is deployed by the factory via `new IRMLinearKink(...)`. Its bytecode is determined by **whatever compiler the factory was built with**, NOT what you're using locally. As of 2026-04-28, the Monad `EulerKinkIRMFactory` was compiled with:

| Setting | Value |
|---|---|
| solc | **0.8.24** |
| optimizer | enabled, 20000 runs |
| evmVersion | **cancun** |

If those become wrong (Euler redeploys the factory), **diff the bytecode**:

```bash
LOCAL=$(jq -r '.deployedBytecode.object' \
  reference/euler-vault-kit/out/IRMLinearKink.sol/IRMLinearKink.json)
DEPLOYED=$(cast code $NEW_IRM --rpc-url $RPC_URL_<CHAIN>)

# Compare lengths (must be equal)
echo "$((${#LOCAL} - 2)) vs $((${#DEPLOYED} - 2))"

# Compare opening (catches solc opcode-emission differences across versions)
echo "${LOCAL:0:200}" ; echo "${DEPLOYED:0:200}"

# Compare trailing metadata (catches solc version)
echo "${LOCAL: -100}" ; echo "${DEPLOYED: -100}"
```

The metadata trailer ends `solc<3-byte-version>0033`. e.g. `solc434300081800` → solc 0.8.24, `solc434300081b00` → solc 0.8.27. That tells you the compiler version straight from the deployed bytecode.

A common mismatch fingerprint: 0.8.27 emits `5f5ffd` for revert-with-empty (PUSH0, PUSH0, REVERT), while 0.8.24 emits `5f80fd` (PUSH0, DUP1, REVERT). If you see that delta, you're on the wrong solc.

### 8.2 — Compile locally with the matching settings

```bash
cd reference/euler-vault-kit
rm -rf out/IRMLinearKink.sol  # clear stale artifact
forge build src/InterestRateModels/IRMLinearKink.sol \
  --use 0.8.24 --evm-version cancun --optimizer-runs 20000
```

The euler-vault-kit foundry project is the right build context — it's where `IRMLinearKink.sol` lives with proper imports. The balancer-contracts (or any partner) project doesn't have `IIRM` in its remappings.

Re-diff bytecode with the deployed contract — bytecode body should now match. Only the IPFS metadata hash (last ~64 chars) will differ; that's expected and Etherscan accepts it as a "partial match" via constructor-args reconstruction.

### 8.3 — Submit verification

```bash
source contracts/<partner>-contracts/.env  # need MONADSCAN_API_KEY
NEW_IRM=0x...
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(uint256,uint256,uint256,uint32)" \
  <baseRate> <slope1> <slope2> <kink>)

cd reference/euler-vault-kit
forge verify-contract \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=143" \
  --etherscan-api-key $MONADSCAN_API_KEY \
  --compiler-version 0.8.24 \
  --num-of-optimizations 20000 \
  --evm-version cancun \
  --constructor-args $CONSTRUCTOR_ARGS \
  $NEW_IRM \
  src/InterestRateModels/IRMLinearKink.sol:IRMLinearKink
```

Returns a GUID. Poll for status:

```bash
curl -s "https://api.etherscan.io/v2/api?chainid=143&module=contract&action=checkverifystatus&guid=<GUID>&apikey=$MONADSCAN_API_KEY"
```

Expected: `{"status":"1","message":"OK","result":"Pass - Verified"}`.

### 8.4 — Auto-match the rest

Once the first IRM with new params is verified, **subsequent IRMs of the same contract type** auto-match (Etherscan recognizes identical bytecode bodies). Submitting verification for a second IRM in the same session typically returns `"is already verified. Skipping verification."` immediately. So with N IRMs of the same shape, you only have to do 8.1–8.3 once — the rest verify for free.

### 8.5 — Ignore the "LostStorageArrayWriteOnSlotOverflow" warning

MonadScan tags every contract verified with solc 0.8.24 with a generic `LostStorageArrayWriteOnSlotOverflow` low-severity bug warning, keyed off the compiler version (it's listed in Solidity's `bugs.json` for 0.8.24). The warning does NOT analyze the contract's code — it appears whether or not the bug pattern is present.

For `IRMLinearKink` specifically the warning is structurally inapplicable: the contract has no storage variables (all 4 fields are `immutable`, stored in code), no storage writes, and no arrays. The bug requires writing to dynamic storage arrays at extremely high indices. Cannot apply. Safe to ignore.

The only way to drop the warning would be for Euler to redeploy the canonical factory with solc ≥ 0.8.26, which is out of our control.

---

## Step 9 — Update `MARKET_PARAMETERS.md`

For each market, in `contracts/<partner>-contracts/MARKET_PARAMETERS.md`:

- Replace the `IRM address`, `IRM slope1`, `IRM slope2`, `IRM human-readable` rows with the new values (kink usually unchanged).
- Append to the `**IRM history:**` line: `→ <newKinkRate>% (v<n>, script <NN>, <reason>, <YYYY-MM-DD>, Safe tx \`<hash>\`)`.

Per-market versioning: each market has its own version count. Don't share version numbers across markets in one update. (E.g. AUSD bumped v4→v5 in script 17, while WMON bumped v3→v4 in the same script. The script number is shared; the version label is per-market.)

---

## Step 10 — Frontend smoke test

The frontend reads `interestRateModel()` from each vault on every render — no labels/products.json change needed. Just open the affected market page and confirm the new APY shows up.

If a multiply position page renders borrow APY, check that too — same vault read, but worth a spot check.

---

## Rollback

If something looks wrong after Step 6, the rollback is **another Safe transaction** pointing each vault back at its *previous* IRM address (you snapshotted them in Step 1). Old IRMs aren't paused or destroyed by this procedure — they remain on-chain forever, callable any time.

Same Safe + threshold applies, so plan for the same signing latency.

---

## Worked example — AUSD + WMON on Monad, 2026-04-28

For reference, the actual values from the AUSD/WMON update:

| | AUSD v4 → v5 | WMON v3 → v4 |
|---|---|---|
| Vault | `0x438cedcE647491B1d93a73d491eC19A50194c222` | `0x75B6C392f778B8BCf9bdB676f8F128b4dD49aC19` |
| Old IRM | `0xDB4cA8a900a837033b9d7723CDfbd105d1971B7f` | `0x22d3553a16b595d1789D67edfCbaa8f3cb62E0DE` |
| New IRM | `0x62C049DE81E407509354172c8f7aB6D2F2001Fd8` | `0xe072FeAA81D2b71360138fBFB6ae877b3d130F1F` |
| Old curve | 0% → 10% → 100% @ 93% | 0% → 20% → 100% @ 93% |
| New curve | 0% → 8% → 80% @ 93% | 0% → 16% → 80% @ 93% |
| Calc args | `borrow 0 8 80 93` | `borrow 0 16 80 93` |
| baseRate | 0 | 0 |
| slope1 | 610,566,643 | 1,177,482,829 |
| slope2 | 53,841,818,838 | 46,309,932,376 |
| kink | 3,994,319,585 | 3,994,319,585 |

Shared:
- Deploy script: `contracts/balancer-contracts/script/17_LowerIRM_AUSD_WMON.s.sol`
- Safe JSON: `contracts/balancer-contracts/redeployment-scripts/safe-tx-lower-ausd-wmon-irm.json`
- AG Safe (governor): `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C` (3-of-6)
- Safe execution tx: `0x80e1688c123158cc35b503f0ca8835b9931169cb32dd8aefd5429a3869e132a7`
- IRM factory: `0x05Cccb5d0f1e1D568804453B82453a719Dc53758`
- Factory's compile settings: solc 0.8.24, optimizer 20000, evmVersion cancun

---

## Reference files

| Purpose | Path |
|---|---|
| Calculator | `reference/evk-periphery/script/utils/calculate-irm-linear-kink.js` |
| `IRMLinearKink` source | `reference/euler-vault-kit/src/InterestRateModels/IRMLinearKink.sol` |
| Factory source | `reference/evk-periphery/src/IRMFactory/EulerKinkIRMFactory.sol` |
| `setInterestRateModel` source | `reference/euler-vault-kit/src/EVault/modules/Governance.sol:333` |
| Latest deploy script (Safe-governed) | `contracts/balancer-contracts/script/17_LowerIRM_AUSD_WMON.s.sol` |
| Latest Safe JSON | `contracts/balancer-contracts/redeployment-scripts/safe-tx-lower-ausd-wmon-irm.json` |
| Schema reference for Safe JSON | `contracts/balancer-contracts/redeployment-scripts/safe-tx-2c-add-new-collateral.json` |
| Older direct-EOA pattern (pre-handover) | `contracts/balancer-contracts/script/10_UpdateIRM.s.sol`, `11_UpdateIRM_v2.s.sol`, `12_UpdateIRM_AUSD_v3.s.sol` |
