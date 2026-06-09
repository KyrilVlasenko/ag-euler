# New Market — Standard Operating Procedure

Step-by-step playbook for deploying a new Euler V2 partner market. Distilled from the Origin (simple pair), Cork (custom contracts), and Balancer (multi-pool) deployments.

**Canonical status:** This is the source of truth for every new AlphaGrowth Euler market launch. Older partner READMEs and deployment scripts document what was done historically; where they conflict with this SOP, follow this SOP.

**Context files:** This SOP covers the deployment workflow. For labels architecture and integration context, see `AGENTS.md`. For per-partner contract details, see the relevant file under `contracts/<partner>-contracts/`.

## Non-Negotiable Oracle Deployment Policy

1. **Deploy every new Oracle Router through Euler's Oracle Router interface:**
   [https://create.euler.finance/oracle/](https://create.euler.finance/oracle/)
2. **Deploy every new supported Oracle adapter through Euler's Oracle Deployer interface:**
   [https://oracle-deployer.euler.finance/oracles](https://oracle-deployer.euler.finance/oracles)
3. **Do not instantiate `EulerRouter` or a supported adapter directly from a Foundry script**, even if an older partner deployment contains such a script.
4. Export and retain any revision/configuration file offered by the Euler interface. Browser-local revisions are not sufficient deployment records.

Why this matters:

- Euler's factory deployment path makes routers discoverable by Euler infrastructure, including oracle checks and frontend tooling.
- A vault's Oracle Router address is embedded in immutable vault initialization data. It cannot be replaced after the vault is deployed.
- Adapter addresses are configured inside the router and can be changed by router governance.

### Legacy Deployment Remediation

| Legacy problem | Required remediation |
|---|---|
| Oracle Router was deployed directly instead of through Euler's factory | Deploy a replacement router through Euler's interface, then redeploy every vault whose immutable oracle address points to the old router. Reconfigure, activate, test, transfer governance, migrate labels/liquidity, and deprecate the old vaults. |
| Supported Oracle adapter was deployed directly | Redeploy the adapter through Euler's Oracle Deployer, verify it, then update every affected router with `govSetConfig`. Vault redeployment is not required if the vault already points to a valid factory-deployed router. |
| Router and adapters were both deployed directly | Redeploy adapters through the Oracle Deployer, deploy and configure a new router through the router factory interface, then redeploy all vaults that reference the old router. |

Do not migrate a live market piecemeal without a written sequence. A partially updated cluster can produce inconsistent collateral valuations across vaults.

For a live router migration:

1. Inventory every vault that returns the legacy router from `oracle()`.
2. Inventory every configured route, resolved vault, governor, LTV, cap, IRM, fee, hook, and label.
3. Deploy and verify replacement adapters through Euler's Oracle Deployer.
4. Deploy and verify the replacement router through Euler's factory interface.
5. Redeploy all affected vaults with the new router address.
6. Reapply all configuration and run deposit, borrow, repay, withdraw, and liquidation tests.
7. Transfer governance and publish labels for the replacement vaults.
8. Deprecate old vaults carefully. Zeroing supply/borrow caps prevents new exposure but does not migrate or erase existing user positions. Keep the old router functional until all debt and collateral positions are safely closed or migrated.

---

## Phase 0: Research & Market Design

Before writing any code, answer these questions:

### 0.1 Token Identification

- What is the **collateral token**? Get its address on the target chain.
- What is the **borrow token**? (WETH, USDC, etc.)
- Is the collateral token **ERC-4626**? (`convertToAssets` / `asset()` exist and return the borrow token or a path to it.) This determines oracle strategy.
- Are there **multiple collateral types** or just one?

### 0.2 Oracle Strategy Decision Tree

```
Is collateral ERC-4626?
├─ YES: Does convertToAssets eventually resolve to the borrow token?
│  ├─ YES → Use govSetResolvedVault (Origin pattern, zero custom contracts)
│  └─ NO  → Need a Chainlink/Pyth adapter for the gap (check existing adapters below)
└─ NO: Is there a Chainlink or Pyth feed for collateral/borrowAsset?
   ├─ YES: Is the adapter already deployed on this chain? (check CSV below)
   │  ├─ YES → Use existing adapter address directly
   │  └─ NO  → Deploy a supported adapter through Euler's Oracle Deployer
   └─ NO  → Design a custom adapter and obtain Euler confirmation on the supported
             deployment/registration path before deploying any vault
```

Existing adapters may be reused only after confirming their base, quote, feed/source, staleness settings, chain, and current quote behavior. Do not rely on an address list alone.

If the Oracle Deployer does not support the required adapter type, stop and coordinate with Euler. Do not silently fall back to direct deployment for a production market.

### 0.3 Adding to an Existing Cluster?

If a borrow vault for your desired borrow asset (e.g. USDC, ETH) already exists and you want to add a new collateral type to it, you do NOT need to deploy a new borrow vault. **Skip to Phase 2B** instead of Phase 2.

Key difference: you deploy only your token's vault and, when required by the cluster architecture, a new factory-deployed router. You then wire the new asset into the existing cluster's routers and vaults. This requires governor access to the existing contracts. See Phase 2B; legacy ZRO scripts are architecture references, not current oracle deployment instructions.

### 0.4 Check Existing Oracle Adapters

Every chain has a CSV of deployed adapters:

```
reference/euler-interfaces/addresses/<chainId>/OracleAdaptersAddresses.csv
```

Search it for your collateral/borrow tokens before building anything. If an adapter exists, note its address — you can wire it directly in step 5.

For every reused adapter, record:

| Field | How to verify |
|---|---|
| Adapter address | Chain registry and explorer |
| Adapter type/name | `name()` or verified source |
| Base token | `base()` |
| Quote token / unit of account | `quote()` |
| Feed/source | Adapter-specific getter such as `feed()` |
| Max staleness | `maxStaleness()` where applicable |
| Live quote | `getQuote()` for one whole base token |
| Feed heartbeat/deviation | Oracle provider documentation |

The adapter's base and quote must match the route that will be configured in the router. Token decimals and the unit-of-account convention must be verified before deployment.

### 0.5 Look Up Euler V2 Core Addresses

All addresses live in the `reference/euler-interfaces/` submodule:

```
reference/euler-interfaces/addresses/<chainId>/CoreAddresses.json        # EVC, eVaultFactory, Permit2
reference/euler-interfaces/addresses/<chainId>/PeripheryAddresses.json   # kinkIRMFactory, oracleRouterFactory, swapper, swapVerifier
reference/euler-interfaces/addresses/<chainId>/LensAddresses.json        # vaultLens, oracleLens
reference/euler-interfaces/addresses/<chainId>/EulerSwapAddresses.json   # EulerSwap factories
```

Update the submodule before starting: `cd reference/euler-interfaces && git pull origin master`.

---

## Euler V2 Core Address Quick Reference

Addresses used in deployment scripts. Canonical source: `reference/euler-interfaces/addresses/<chainId>/`.

### Ethereum Mainnet (1)

| Contract | Address |
|---|---|
| EVC | `0x0C9a3dd6b8F28529d72d7f9cE918D493519EE383` |
| eVaultFactory | `0x29a56a1b8214D9Cf7c5561811750D5cBDb45CC8e` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| KinkIRM Factory | `0xcAe0A39B45Ee9C3213f64392FA6DF30CE034C9F9` |
| Oracle Router Factory | `0x70B3f6F61b7Bf237DF04589DdAA842121072326A` |
| Swapper | `0x2Bba09866b6F1025258542478C39720A09B728bF` |
| Swap Verifier | `0xae26485ACDDeFd486Fe9ad7C2b34169d360737c7` |

### Base (8453)

| Contract | Address |
|---|---|
| EVC | `0x5301c7dD20bD945D2013b48ed0DEE3A284ca8989` |
| eVaultFactory | `0x7F321498A801A191a93C840750ed637149dDf8D0` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| KinkIRM Factory | `0x2d94C898a17f9D8c0bA75010A51cd61BF55b402E` |
| Oracle Router Factory | `0xA9287853987B107969f181Cce5e25e0D09c1c116` |
| Swapper | `0x0D3d0F97eD816Ca3350D627AD8e57B6AD41774df` |
| Swap Verifier | `0x30660764A7a05B84608812C8AFC0Cb4845439EEe` |

### Monad (143)

| Contract | Address |
|---|---|
| EVC | `0x7a9324E87C839CF808712e6C8e7d3Ae4096DD3E4` |
| eVaultFactory | `0xba4Dd672B9C4F02F13F6C31c0388E120c3c7ca00` |
| KinkIRM Factory | `0x05Cccb5d80a804a14bAA56f0FA6c6D3f07c1D55B` |
| Oracle Router Factory | `0x5c69a22c2c93A6950D29c37BEAE6a4C98bEB8c56` |
| Swapper | `0x3d1C8E7e5E87B11B0a6A57D4356bb6d5aF06d98E` |
| Swap Verifier | `0x7C79D6bc5aD3F2C0dDB3F09D29658EB77F57E37a` |

---

## Phase 1: Scaffold Contract Directory

### 1.0 Ensure reference repos are populated

The deployment scripts import Solidity from `../reference/` (euler-price-oracle, euler-vault-kit, etc.). If you cloned the repo fresh or the directories are empty, initialize them:

```bash
git submodule update --init --recursive
```

Verify: `ls reference/euler-price-oracle/src/` should show `.sol` files. If any reference repo is a manually cloned directory (not a submodule), `git pull` inside it instead.

### 1.1 Create the directory

```
mkdir contracts/<partner>-contracts
cd contracts/<partner>-contracts
forge init --no-commit --no-git
```

### 1.2 Copy from Origin (simplest template)

Origin (`contracts/origin-contracts/`) is the baseline for a simple collateral/borrow pair with ERC-4626 oracle resolution. Copy these files and adapt:

```
contracts/origin-contracts/
├── foundry.toml          ← Update rpc_endpoints for your chain
├── remappings.txt        ← Keep as-is (references ../../reference/)
├── .env                  ← Template: RPC, PRIVATE_KEY, output addresses
└── script/
    ├── Addresses.sol     ← Replace with target chain's Euler core + token addresses
    ├── 01_DeployIRM.s.sol
    ├── 03_DeployBorrowVault.s.sol
    ├── 05_WireOracle.s.sol
    ├── 06_ConfigureCluster.s.sol
    ├── 07_SetFeeReceiver.s.sol
    └── 08_ActivateMarkets.s.sol
```

**Delete or disable copied scripts that directly deploy `EulerRouter` or supported oracle adapters.** Their presence in an older template does not make them valid for a new launch. The router and adapter addresses used by the remaining scripts must come from Euler's interfaces.

Use the unified-vault pattern by default. Do not copy a standalone collateral-vault script unless the market design genuinely requires separate collateral vaults and that exception has been documented.

### 1.3 Install forge-std

```
cd <partner>-contracts
forge install foundry-rs/forge-std --no-commit
```

### 1.4 Configure foundry.toml

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.24"
optimizer = true
optimizer_runs = 20_000
evm_version = "cancun"
allow_paths = ["../../reference"]

fs_permissions = [{ access = "read-write", path = "./" }]

[rpc_endpoints]
<chain_name> = "${RPC_URL_<CHAIN>}"

# Block explorer verification — required for --verify to work.
# Each chain has a different API URL. Add the correct one for your chain.
[etherscan]
<chain_name> = { chain = "<chainId>", key = "${ETHERSCAN_API_KEY}", url = "<explorer_api_url>" }
```

**Explorer API URLs by chain:**

| Chain | URL |
|---|---|
| Ethereum (1) | `https://api.etherscan.io/api` |
| Base (8453) | `https://api.basescan.org/api` |
| Arbitrum (42161) | `https://api.arbiscan.io/api` |
| Monad (143) | `https://api.monadscan.com/api` (or skip `--verify` if unsupported) |

Get a free API key from the relevant block explorer site (e.g. basescan.org for Base).

### 1.5 Configure remappings.txt

```
forge-std/=lib/forge-std/src/
euler-price-oracle/=../../reference/euler-price-oracle/src/
ethereum-vault-connector/=../../reference/ethereum-vault-connector/src/
euler-vault-kit/=../../reference/euler-vault-kit/src/
evk-periphery/=../../reference/evk-periphery/src/
@openzeppelin/contracts/=../../reference/euler-price-oracle/lib/openzeppelin-contracts/contracts/
```

### 1.6 Write Addresses.sol

Replace addresses for your target chain. Pull from the core address registry above.

```solidity
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

library Addresses {
    // ─── Euler Core (from CoreAddresses.json) ───
    address constant EVC            = 0x...;
    address constant EVAULT_FACTORY = 0x...;
    address constant PERMIT2        = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    // ─── Euler Periphery (from PeripheryAddresses.json) ───
    address constant KINK_IRM_FACTORY      = 0x...;
    address constant ORACLE_ROUTER_FACTORY = 0x...;
    address constant SWAPPER               = 0x...;
    address constant SWAP_VERIFIER         = 0x...;

    // ─── Tokens ───
    address constant BORROW_TOKEN     = 0x...; // e.g. WETH, USDC
    address constant COLLATERAL_TOKEN = 0x...; // e.g. sfrxETH, ARM token

    // ─── Oracles (if using Chainlink/Pyth adapters) ───
    // address constant CHAINLINK_XXX_YYY = 0x...;
}
```

### 1.7 Prepare .env

```bash
# <Partner> × Euler — Deployment Environment

# ─── RPC ───
RPC_URL_<CHAIN>=

# ─── Deployer ───
PRIVATE_KEY=
ETHERSCAN_API_KEY=

# ─── Outputs (filled by scripts as you deploy) ───
# Step 1
KINK_IRM=
# Euler Oracle Router interface output
EULER_ROUTER=
# Euler Oracle Deployer outputs
<ASSET>_ORACLE_ADAPTER=
# Vault deployment outputs
BORROW_VAULT=

# ─── Fee Receiver ───
FEE_RECEIVER=0x4f894Bfc9481110278C356adE1473eBe2127Fd3C
```

---

## Phase 2: Deploy Oracles, Router, and Markets

The mandatory order is:

1. Finalize token, unit-of-account, feed, staleness, and route design.
2. Deploy any required supported adapters through Euler's Oracle Deployer.
3. Deploy the Oracle Router through Euler's Oracle Router interface/factory.
4. Deploy vaults with the factory-deployed router address embedded in `trailingData`.
5. Configure router routes/resolved vaults, risk parameters, fees, and operations.
6. Verify the complete market before transferring governance or publishing labels.

### Step 0: Prepare the Oracle Deployment Worksheet

Prepare one row for every price edge needed by the router:

| Field | Required information |
|---|---|
| Chain | Chain name and chain ID |
| Adapter type | Chainlink, Pyth, Redstone, ERC-4626 resolution, or approved custom type |
| Base | Token being priced |
| Quote | Borrow asset or unit of account |
| Feed/source | Verified provider contract/feed ID |
| Token decimals | Base and quote decimals |
| Heartbeat/deviation | Provider's documented update policy |
| Max staleness | Risk-approved value, normally heartbeat plus a documented buffer |
| Expected price | Independent reference price and acceptable tolerance |
| Reuse/deploy | Existing verified adapter or new deployment |

Common unit of account:

```text
ISO USD address(840) = 0x0000000000000000000000000000000000000348
Euler treats this address as an 18-decimal unit of account.
```

Never guess a feed address or copy one from another chain.

### Step 0A (if needed): Deploy Oracle Adapters Through Euler

Open [https://oracle-deployer.euler.finance/oracles](https://oracle-deployer.euler.finance/oracles).

1. Select the target chain and create an oracle deployment revision.
2. Add one adapter for each worksheet row that cannot reuse an approved existing adapter.
3. Enter the exact base, quote, feed/source, and risk-approved staleness parameters.
4. Review directionality. `TOKEN/USD` and `USD/TOKEN` are not interchangeable configurations.
5. Connect the intended deployment wallet on the correct chain.
6. Deploy and record the adapter address and transaction hash.
7. Export the revision/configuration JSON and store it with the partner's deployment records.
8. Verify the deployed adapter on-chain before using it in a router.

For a Chainlink adapter, verify at minimum:

```bash
cast call <ADAPTER> "base()(address)" --rpc-url $RPC
cast call <ADAPTER> "quote()(address)" --rpc-url $RPC
cast call <ADAPTER> "feed()(address)" --rpc-url $RPC
cast call <ADAPTER> "maxStaleness()(uint256)" --rpc-url $RPC
cast call <ADAPTER> "getQuote(uint256,address,address)(uint256)" \
  <ONE_WHOLE_BASE_TOKEN> <BASE> <QUOTE> --rpc-url $RPC
```

Compare the result with the underlying feed and an independent market-price source. Check both quote directions if the market/router may use both.

**Output:** one `<ASSET>_ORACLE_ADAPTER=0x...` per deployed adapter.

**Custom adapters:** If the required type is not supported by the interface, obtain an approved deployment/registration procedure from Euler before proceeding. Custom source code still requires unit tests, fork tests, verification, economic manipulation analysis, and explicit documentation of all external dependencies.

### Step 1: Deploy IRM

Deploys a KinkIRM via the factory with your chosen rate curve.

**Parameters to customize:**
- `IRM_BASE` — base rate at 0% utilization (in ray/sec)
- `IRM_SLOPE1` — slope below kink
- `IRM_SLOPE2` — slope above kink (punitive)
- `IRM_KINK` — target utilization as fraction of `type(uint32).max`

**Kink encoding:** `kinkPercent / 100 * type(uint32).max`. For 80% → `0.80 * 4294967295 = 3435973836`.

**Rate calculation helper:**
```bash
node reference/evk-periphery/script/utils/calculate-irm-linear-kink.js borrow <baseAPY> <kinkAPY> <maxAPY> <kinkUtil>
```

Example (Origin): Base=0.5%, Kink(80%)=2.5%, Max=50%.

**Run:**
```bash
source .env && forge script script/01_DeployIRM.s.sol \
  --rpc-url $RPC_URL_<CHAIN> --private-key $PRIVATE_KEY \
  --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

**Output:** `KINK_IRM=0x...` → paste into `.env`

### Step 2: Deploy Oracle Router

Open [https://create.euler.finance/oracle/](https://create.euler.finance/oracle/) and deploy the router through Euler's Oracle Router factory.

Before opening the interface, prepare:

- Target chain and chain ID
- Initial governor address
- Unit of account
- Every base/quote route
- Adapter address for every route
- Any already-existing ERC-4626/eVault address that must be resolved
- Expected quotes for test amounts

Deployment procedure:

1. Connect the deployment/governance wallet on the target chain.
2. Create a new Oracle Router configuration.
3. Add every adapter route from the worksheet if the interface includes route configuration in the deployment flow.
4. Add known existing resolved vaults/ERC-4626 wrappers if the interface supports them. Newly deployed market vaults are resolved later in Step 5, after their addresses exist.
5. Review the initial route graph and deployment parameters.
6. Deploy through the interface and confirm that the transaction uses Euler's listed Oracle Router factory for that chain.
7. Record the router address, factory address, deployment transaction, chain, initial governor, routes, and resolved vaults.
8. Export/save any configuration artifact offered by the interface.
9. Verify the router before deploying vaults.

If the interface deploys the router without all final routes, apply the remaining `govSetConfig` calls immediately after deployment and verify them before creating vaults. Do not replace the factory deployment with a direct constructor call.

Verification:

```bash
cast call <ROUTER> "governor()(address)" --rpc-url $RPC
cast call <ROUTER> "getQuote(uint256,address,address)(uint256)" \
  <TEST_AMOUNT> <BASE> <QUOTE> --rpc-url $RPC
```

Also confirm through the explorer transaction that the router was created by Euler's factory, not by a direct contract-creation transaction from the deployer.

**Critical immutability checkpoint:** Do not deploy a vault until the router address and quote behavior have been independently reviewed. The router address placed in vault `trailingData` cannot be changed later.

**Output:** `EULER_ROUTER=0x...` → paste into `.env`

### Step 3: Deploy Borrow Vault

Creates the borrow vault via `eVaultFactory.createProxy()`.

**Key concept — trailingData:**
```
trailingData = abi.encodePacked(borrowAsset, oracleRouter, unitOfAccount)  // 60 bytes
```

- `borrowAsset` — the token users deposit to lend / borrow
- `oracleRouter` — the EulerRouter from step 2
- `unitOfAccount` — the denominator for LTV calculations (often same as borrowAsset; use USD `address(840)` for multi-asset clusters)

**Run:**
```bash
source .env && forge script script/03_DeployBorrowVault.s.sol \
  --rpc-url $RPC_URL_<CHAIN> --private-key $PRIVATE_KEY \
  --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

**Output:** `BORROW_VAULT=0x...` → paste into `.env`

### Step 4: Deploy Additional Borrow Vaults (Unified Market Pattern)

**In a unified market, there are NO separate collateral vaults.** Each asset gets a borrow vault, and borrow vaults reference each other as collateral. This means users deposit into a single vault per asset that both earns lending yield AND serves as collateral for borrowing other assets — matching the pattern used on the official Euler frontend (app.euler.finance).

Deploy one borrow vault per asset in the cluster, each with the shared oracle router and USD unit of account:

```
trailingData = abi.encodePacked(asset, oracleRouter, USD)  // 60 bytes
```

Repeat step 3 for each additional asset. For a 6-asset cluster (e.g. USDC, ETH, VVV, ZRO, VIRTUAL, AERO), you deploy 6 borrow vaults total.

**Output:** One `<ASSET>_BORROW_VAULT=0x...` per asset → paste into `.env`

> **Legacy pattern (separate collateral vaults):** Older deployments used standalone collateral vaults with `oracle = address(0)` and `unitOfAccount = address(0)`. This created a split where users had to choose between earning yield (deposit in borrow vault) or using as collateral (deposit in collateral vault). The unified pattern above eliminates this split. See `contracts/venice-contracts/script/28_UnifyBorrowVaultsAsCollateral.s.sol` for an example of migrating from split to unified.

### Step 5: Wire Oracle

Connect the oracle router so it can price each asset and resolve borrow vault shares to their underlying tokens.

**Price adapters** — set up a price feed for each token in the cluster:

```solidity
router.govSetConfig(tokenA, USD, tokenA_USD_adapter);
router.govSetConfig(tokenB, USD, tokenB_USD_adapter);
// ... repeat for each token
```

**Resolve borrow vaults** — tell the router that borrow vault shares resolve to the underlying token. This is required so that when Vault A accepts Vault B as collateral, the router can price Vault B's shares:

```solidity
router.govSetResolvedVault(borrowVaultA, true);  // eVaultA shares → tokenA
router.govSetResolvedVault(borrowVaultB, true);  // eVaultB shares → tokenB
// ... repeat for each borrow vault
```

The resolution chain is: eVault shares → `asset()` → underlying token → price adapter → USD value.

This is the point where newly deployed vault addresses are added as resolved vaults. Verify the complete route graph after these calls and before enabling LTVs.

**ERC-4626 resolution (Origin pattern):** If collateral is itself an ERC-4626 wrapper (e.g. sfrxETH → WETH), use `govSetResolvedVault` on the token itself for multi-hop resolution.

**Custom oracle path (Cork pattern):** Implement and test the custom pricing contract in `src/`, then coordinate with Euler so the production adapter is deployed through the Oracle Deployer or another explicitly approved Euler workflow before wiring it with `govSetConfig`.

Do not directly deploy a production adapter just because an older Cork, Frax, Balancer, or Base script did so.

**Run:**
```bash
source .env && forge script script/05_WireOracle.s.sol \
  --rpc-url $RPC_URL_<CHAIN> --private-key $PRIVATE_KEY \
  --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

### Step 6: Configure Cluster

Sets all risk parameters on each borrow vault and wires cross-collateral LTVs.

**Parameters to customize:**

| Parameter | Origin Default | Description |
|---|---|---|
| Borrow LTV | 90% (0.90e4) | Max borrow power |
| Liquidation LTV | 93% (0.93e4) | Liquidation trigger (must be > borrow LTV) |
| Max Liq Discount | 5% (0.05e4) | Liquidator bonus |
| Liq Cool-Off | 1 second | Delay between liquidations |
| Interest Fee | 10% (0.10e4) | Protocol revenue share on interest |
| Supply Cap | 0 (uncapped) | Max deposits — tighten post-launch |
| Borrow Cap | 0 (uncapped) | Max borrows — tighten post-launch |

**LTV guidelines:**
- Highly correlated pairs (e.g. sfrxETH/WETH): 90-92% borrow, 93-95% liquidation
- Moderately correlated (e.g. stablecoin/stablecoin): 85-90% borrow, 88-93% liquidation
- Low correlation or volatile: 70-80% borrow, 75-85% liquidation

**Cross-collateral LTV (unified market):** In the unified pattern, each borrow vault accepts other borrow vaults as collateral. A vault cannot accept itself as collateral (`setLTV(address(this), ...)` reverts with `E_InvalidLTVAsset`).

```solidity
// Example: 3-asset cluster (USDC, ETH, VVV)
// USDC borrow vault accepts ETH and VVV borrow vaults as collateral
IEVault(usdcBorrow).setLTV(ethBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
IEVault(usdcBorrow).setLTV(vvvBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);

// ETH borrow vault accepts USDC and VVV borrow vaults as collateral
IEVault(ethBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
IEVault(ethBorrow).setLTV(vvvBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);

// VVV borrow vault accepts USDC and ETH borrow vaults as collateral
IEVault(vvvBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
IEVault(vvvBorrow).setLTV(ethBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);
```

**Restricting volatile-to-volatile pairs:** To avoid risky positions (e.g. borrowing VVV against AERO), you can omit `setLTV` between volatile assets and only allow them as collateral for stable/blue-chip borrow vaults (USDC, ETH). See `contracts/venice-contracts/script/27_RemoveVolatileVolatileLTV.s.sol` for an example.

**Run:**
```bash
source .env && forge script script/06_ConfigureCluster.s.sol \
  --rpc-url $RPC_URL_<CHAIN> --private-key $PRIVATE_KEY --broadcast
```

### Step 7: Set Fee Receiver

Sets the address that accrues the interest fee share.

**AG fee receiver:** `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C`

**Run:**
```bash
source .env && forge script script/07_SetFeeReceiver.s.sol \
  --rpc-url $RPC_URL_<CHAIN> --private-key $PRIVATE_KEY --broadcast
```

### Step 8: Activate Markets (Enable Vault Operations)

**CRITICAL — without this step, all vault operations (deposit, withdraw, borrow, repay, liquidate) will fail with "Operation Disabled".**

Euler V2 factory proxies are created with `hookedOps = 32767` (all operations disabled) and `hookTarget = address(0)`. This acts as a kill switch — when hookedOps bits are set but there is no hook contract, those operations are blocked. You must clear the hookedOps bitmask on **every** vault (both borrow and collateral) by calling `setHookConfig(address(0), 0)`.

**Verify a vault needs activation:**
```bash
cast call <VAULT_ADDRESS> "hookConfig()(address,uint32)" --rpc-url $RPC_URL_<CHAIN>
# Second value = 32767 → operations DISABLED, needs activation
# Second value = 0     → operations ENABLED, good to go
```

**Activate a single vault:**
```bash
cast send <VAULT_ADDRESS> "setHookConfig(address,uint32)" \
  0x0000000000000000000000000000000000000000 0 \
  --rpc-url $RPC_URL_<CHAIN> --private-key $PRIVATE_KEY
```

**You must run this for every vault you deployed.** In the unified market pattern, this means one activation per borrow vault. For example, a 6-asset unified market requires 6 activation transactions.

This can also be added as an additional deployment script (e.g. `08_ActivateMarkets.s.sol`) or run manually via `cast send` after all other steps are complete.

---

## Phase 3: Labels

The labels repo controls which vaults appear in the frontend. **If a vault isn't in `products.json`, it's invisible.**

All partner labels are consolidated in `frontends/labels/alphagrowth/`. Each chain has its own directory. If the new partner deploys on a chain that already exists, merge into the existing chain directory. If it's a new chain, create a new directory.

### 3.1 Add to Consolidated Labels

```
frontends/labels/alphagrowth/
├── <chainId>/              ← Add or merge into existing chain directory
│   ├── products.json       ← Add new product entry
│   ├── vaults.json         ← Add new vault entries
│   ├── entities.json       ← Add partner entity (if not already present)
│   ├── points.json         ← Add incentive programs or leave as []
│   └── opportunities.json  ← Add safety modules or leave as {}
└── logo/
    └── <partner>.svg       ← Add partner logo
```

### 3.2 File Templates

**products.json** — Defines vault clusters. Every vault address here becomes visible. In the unified market pattern, list only borrow vaults (no separate collateral vaults):

```json
{
  "<chain>-unified": {
    "name": "<Chain> Unified Market",
    "description": "Borrow and lend <Asset1>, <Asset2>, ... on <Chain>. Curated by Alpha Growth.",
    "entity": ["alphagrowth", "euler"],
    "url": "https://alphagrowth.io",
    "vaults": [
      "0x<ASSET1_BORROW_VAULT_CHECKSUM>",
      "0x<ASSET2_BORROW_VAULT_CHECKSUM>",
      "0x<ASSET3_BORROW_VAULT_CHECKSUM>"
    ]
  }
}
```

**vaults.json** — Per-vault display metadata. Each borrow vault serves as both lending and collateral:

```json
{
  "0x<ASSET1_BORROW_VAULT_CHECKSUM>": {
    "name": "<Asset1> Lending",
    "description": "Lend <Asset1> to earn yield, or use as collateral to borrow other assets.",
    "entity": "alphagrowth"
  },
  "0x<ASSET2_BORROW_VAULT_CHECKSUM>": {
    "name": "<Asset2> Lending",
    "description": "Lend <Asset2> to earn yield, or use as collateral to borrow other assets.",
    "entity": "<partner>"
  }
}
```

**entities.json** — Organization metadata and logos.

**CRITICAL: The `alphagrowth` entity MUST include the deployer's governor address in `addresses`.** The frontend checks if each vault's on-chain `governorAdmin` matches an address in the entity's `addresses` map. Without this, Risk Manager shows "Unknown" and Vault Type shows "Unknown" instead of "AlphaGrowth" / "Governed". Query the governor address with: `cast call <VAULT> "governorAdmin()(address)" --rpc-url $RPC_URL`.

```json
{
  "alphagrowth": {
    "name": "AlphaGrowth",
    "logo": "alphagrowth.svg",
    "description": "DeFi risk curation and vault management",
    "url": "https://alphagrowth.io",
    "addresses": {
      "0x<GOVERNOR_ADMIN_ADDRESS>": "AlphaGrowth Curator Wallet"
    },
    "social": { "twitter": "", "discord": "", "telegram": "", "github": "" }
  },
  "<partner>": {
    "name": "<Partner Name>",
    "logo": "<partner>.svg",
    "website": "https://<partner-website>",
    "addresses": {}
  },
  "euler": {
    "name": "Euler Finance",
    "logo": "euler.svg",
    "description": "Modular lending protocol",
    "url": "https://euler.finance",
    "addresses": {},
    "social": { "twitter": "eulerfinance", "discord": "https://discord.euler.finance/", "github": "euler-xyz" }
  }
}
```

**points.json** — Incentive programs (empty if none).

```json
[]
```

**opportunities.json** — Cozy Finance safety modules (empty if not applicable).

```json
{}
```

### 3.3 Logo Assets

The `logo/` directory already has `alphagrowth.svg` and `euler.svg`. Just add the new partner's logo as SVG or PNG.

### 3.4 Push to Custom Labels Repo

After editing the labels locally, push the consolidated labels repo to GitHub so the frontend can fetch them at runtime via raw GitHub URLs. Test on localhost before proceeding.

### 3.5 Submit to Official Euler Labels (app.euler.finance Listing)

To have vaults verified and displayed correctly on the **official** Euler dApp, submit a PR to [euler-xyz/euler-labels](https://github.com/euler-xyz/euler-labels).

**Prerequisites:**
- Governance MUST be transferred to the team multisig BEFORE submitting the PR. The multisig address must match what's in the `alphagrowth` entity's `addresses` map in the upstream repo. If you submit with a dev wallet as governor, vaults will show "Unknown" for Risk Manager on the official frontend.
- The `alphagrowth` entity and logo already exist in the upstream repo — you only need to add vault and product entries.

**Process:**
1. Fork `euler-xyz/euler-labels` to your GitHub account
2. Clone your fork locally (or add as remote to the existing `reference/euler-labels/` clone)
3. Add vault entries to `<chainId>/vaults.json` — use naming pattern `"AlphaGrowth <ASSET> <Chain> Vault"`, entity `"alphagrowth"`
4. Add vault addresses to an existing AlphaGrowth product in `<chainId>/products.json`, or create a new product
5. If the governor address isn't already in the upstream `alphagrowth` entity's `addresses`, add it to `<chainId>/entities.json`
6. Run `npm i && node verify.js` — must print `OK`
7. Push to your fork, create PR to `euler-xyz/euler-labels`

**What each label controls on the official frontend:**

| Label | Controls | Without it |
|---|---|---|
| Vault in `products.json` | Vault appears on the dApp | Vault is invisible |
| Vault in `vaults.json` | Vault name, description | Shows "Unknown" for market name |
| Governor in entity `addresses` | Risk Manager + Vault Type display | Shows "Unknown" / "Unverified" |

**Oracle provider/methodology** is NOT controlled by labels. It comes from `euler-xyz/oracle-checks`, which auto-crawls all oracle routers every 6 hours. Custom Chainlink adapters will be picked up automatically — no PR needed.

**Reference:** See `contracts/base-market-contracts/` for the Base unified market PR example.

---

## Phase 4: Frontend Integration

The frontend is a consolidated euler-lite fork at `frontends/alphagrowth/`. All partners share it. Michael (AG webmaster) handles production deployment to `euler.alphagrowth.io`.

### 4.1 Standard Flow (No Custom Code)

For most partners, no frontend code changes are needed. Just:
1. Add the chain RPC and subgraph to `.env` (if not already present)
2. Labels handle the rest — the frontend discovers vaults from `products.json`

### 4.2 Custom Flows

If the partner needs custom swap routing, non-standard collateral flows, or dedicated pages, add them to `frontends/alphagrowth/` behind a feature flag. Existing examples:

| Feature | Flag | Files |
|---|---|---|
| Cork dual-collateral borrow | `ENABLE_CORK_BORROW_PAGE` | `pages/cork-borrow.vue`, `composables/borrow/useCorkBorrowForm.ts` |
| Balancer BPT multiply | `ENABLE_ENSO_MULTIPLY` + `BPT_ADAPTER_CONFIG` | `composables/useEnsoRoute.ts` |
| Origin ARM multiply | `ARM_ADAPTER_CONFIG` | `composables/useArmRoute.ts` |
| Balancer loop-zap | `ENABLE_LOOP_ZAP_PAGE` | `pages/loop-zap/index.vue` |

### 4.3 Environment Variables

The `.env` in `frontends/alphagrowth/` already has all current partners configured. For a new partner, add:

```bash
# ─── Chain RPC (if new chain) ───
RPC_URL_HTTP_<chainId>="https://<your-rpc-url>"

# ─── Subgraph (if new chain) ───
NUXT_PUBLIC_SUBGRAPH_URI_<chainId>="<subgraph-url>"

# ─── Custom adapter config (if needed) ───
# NUXT_PUBLIC_CONFIG_<ADAPTER>_CONFIG=<json>
```

The labels repo, branding, and standard feature flags are already set for the consolidated deployment.

### 4.4 Known Subgraph URIs

Copy-paste ready. These are the full URIs for `NUXT_PUBLIC_SUBGRAPH_URI_<chainId>`.

| Chain | ID | URI |
|---|---|---|
| Ethereum | 1 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-mainnet/latest/gn` |
| Base | 8453 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-base/latest/gn` |
| Arbitrum | 42161 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-arbitrum/latest/gn` |
| Monad | 143 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-monad/latest/gn` |
| Sonic | 146 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-sonic/latest/gn` |
| Unichain | 130 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-unichain/latest/gn` |
| Avalanche | 43114 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-avalanche/latest/gn` |
| BSC | 56 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-bsc/latest/gn` |
| Berachain | 80094 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-berachain/latest/gn` |
| Swell | 1923 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-swell/latest/gn` |
| Bob | 60808 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-bob/latest/gn` |
| Linea | 59144 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-linea/latest/gn` |
| TAC | 239 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-tac/latest/gn` |
| Plasma | 9745 | `https://api.goldsky.com/api/public/project_cm4iagnemt1wp01xn4gh1agft/subgraphs/euler-simple-plasma/latest/gn` |

### 4.5 Vercel Deployment (Michael)

Michael redeploys the consolidated Vercel project with the updated `.env`. No new Vercel project needed — all partners share one deployment.

### 4.6 Optional: Intrinsic APY Sources

If the collateral token has a DeFi Llama or Merkl yield source, add it to `entities/custom.ts` in the frontend:

```typescript
intrinsicApySources: [
  {
    provider: 'defillama',
    chainId: <chainId>,
    address: '<collateral_token_address>',
    poolId: '<defillama_pool_uuid>'
  }
]
```

---

## Phase 5: Post-Deployment Checklist

### Verification

- [ ] **All new supported adapters were deployed through Euler's Oracle Deployer** — deployment revisions/configuration exports and transaction hashes retained
- [ ] **Oracle Router was deployed through Euler's Oracle Router factory interface** — factory creation confirmed on the explorer
- [ ] Router address embedded in every vault matches the reviewed factory-deployed router — verify with `cast call <vault> "oracle()(address)"`
- [ ] Router governor is the expected deployment wallet or multisig
- [ ] Every adapter's base, quote, feed/source, and staleness match the deployment worksheet
- [ ] Every adapter quote matches its source and an independent reference within the approved tolerance
- [ ] Every router route resolves for both underlying assets and vault-share collateral
- [ ] **Markets activated** — `setHookConfig(address(0), 0)` called on ALL borrow vaults. Verify: `cast call <vault> "hookConfig()(address,uint32)"` returns `0` for the second value.
- [ ] Vaults appear in frontend (check `products.json` is fetched correctly)
- [ ] Entity logos render (check `entities.json` + `logo/` directory)
- [ ] Risk Manager shows "AlphaGrowth" (not "Unknown") — verify `entities.json` has the vault's `governorAdmin` address in the `alphagrowth` entity's `addresses` map
- [ ] Vault Type shows "Governed" (not "Unknown") — same root cause as above
- [ ] Vault names and descriptions display correctly (`vaults.json`)
- [ ] Lending flow works (deposit into borrow vault, earn yield)
- [ ] Borrowing flow works (deposit into one borrow vault as collateral, borrow from another)
- [ ] Each vault shows both "Borrow against" and "Use as collateral" on the frontend (unified market)
- [ ] Multiply flow works (if applicable)
- [ ] Oracle prices resolve correctly on-chain
- [ ] Oracle deployment revision/configuration exports are stored with the market deployment records

### Hardening

- [ ] Tighten supply/borrow caps via `setCaps()` — do NOT leave uncapped in production
- [ ] Test liquidation end-to-end (create underwater position, confirm liquidation succeeds)
- [ ] Confirm fee receiver is set and accruing
- [ ] If collateral token has per-address caps (like Origin ARM's CapManager), ensure the Swapper contract is whitelisted

### Documentation

- [ ] Add a new section to `TODO.md` for this partner (follow the format of existing sections: status, deployed addresses table, remaining TODOs)
- [ ] Document all deployed addresses in `contracts/<partner>-contracts/.env`
- [ ] If custom contracts or non-obvious architecture, create or update the partner's `AGENTS.md`/deployment context file

### Governance

**IMPORTANT: Transfer governance BEFORE submitting the euler-labels PR.** The official frontend checks `governorAdmin` against entity addresses — if the dev wallet is still governor but not in the entity's `addresses`, vaults show "Unknown" for Risk Manager.

- [ ] Transfer ALL borrow vault governors from deployer EOA to multisig via `setGovernorAdmin()` — see `contracts/base-market-contracts/script/cluster-management/30_TransferGovernance.s.sol` for reference
- [ ] Transfer oracle router governance via `transferGovernance()`
- [ ] Verify on-chain: `cast call <vault> "governorAdmin()(address)"` returns the multisig
- [ ] Verify on-chain: `cast call <router> "governor()(address)"` returns the multisig
- [ ] Verify the multisig address exists in the `alphagrowth` entity's `addresses` in `euler-xyz/euler-labels`

---

## When Do You Need Custom Contracts?

For most ERC-4626 collateral/borrow pairs, the standard factory/UI plus Foundry workflow works with zero custom Solidity. You need custom contracts when:

| Situation | Example | Reference |
|---|---|---|
| Custom oracle pricing logic | Cork: vbUSDC priced via pool NAV/swap rate formula | `contracts/cork-contracts/src/oracle/` |
| Borrow hook (extra validation) | Cork: enforces dual-collateral pairing (vbUSDC + cST) | `contracts/cork-contracts/src/hook/` |
| Custom collateral vault logic | Cork: paired deposit/withdraw invariants | `contracts/cork-contracts/src/vault/` |
| Custom liquidation path | Cork: seize + exercise via external protocol | `contracts/cork-contracts/src/liquidator/` |
| Swap adapter for multiply | Balancer: BPT adapter for single-sided LP | `contracts/balancer-contracts/src/` |
| Custom oracle with keeper | Frax: ICHI vault TWAP oracle + OraclePoke | `contracts/frax-contracts/ichi-oracle-kit/src/` |

If any of these apply, create `src/` in your contracts directory and add the custom Solidity. Test and audit it locally, but coordinate the production oracle-adapter deployment path with Euler before launching the market. Non-oracle custom contracts can continue to use project deployment scripts.

---

## Quick Reference: Run Commands

Foundry-managed contract steps follow the same pattern. Replace `<N>` with step number and `<CHAIN>` with your chain name. **Do not use this pattern to deploy Oracle Routers or supported oracle adapters.**

```bash
# Load env
source .env

# Deploy (with verification)
forge script script/0<N>_<ScriptName>.s.sol \
  --rpc-url $RPC_URL_<CHAIN> \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Deploy (without verification, e.g. chains without block explorer API)
forge script script/0<N>_<ScriptName>.s.sol \
  --rpc-url $RPC_URL_<CHAIN> \
  --private-key $PRIVATE_KEY \
  --broadcast
```

---

## Phase 2B: Adding a Token to an Existing Cluster

Use this instead of Phase 2 when borrow vaults (e.g. USDC, ETH) already exist and you want to add a new collateral token that is also borrowable against those existing vaults.

**Historical architecture reference:** `contracts/base-market-contracts/script/zro/` (ZRO added to the Base cluster). Its direct adapter deployment step is obsolete; use Euler's Oracle Deployer.

### Prerequisites

You need from the existing cluster deployer:

```bash
# Existing vault addresses
USDC_BORROW_VAULT=0x...
ETH_BORROW_VAULT=0x...

# Existing oracle router addresses (one per vault)
USDC_EULER_ROUTER=0x...
ETH_EULER_ROUTER=0x...
```

The deployer running scripts that touch existing vaults/routers **must be governor** of those contracts.

### Step 0: Deploy Oracle Adapter (if needed)

If no approved adapter exists for your token on this chain, deploy it through:

[https://oracle-deployer.euler.finance/oracles](https://oracle-deployer.euler.finance/oracles)

Check `reference/euler-interfaces/addresses/<chainId>/OracleAdaptersAddresses.csv` first — if an adapter already exists, skip this step and use that address.

Apply the full worksheet, deployment-record, and verification procedure from Phase 2 Step 0/0A.

### Step 1: Deploy IRM

Deploy a KinkIRM for your new token's borrow market only. The existing vaults already have their own IRMs.

```bash
forge script script/02_DeployIRMs.s.sol --rpc-url base --broadcast --verify
```

### Step 2: Deploy Router

If the architecture requires a router for the new vault, deploy it through Euler's Oracle Router factory interface:

[https://create.euler.finance/oracle/](https://create.euler.finance/oracle/)

The existing vaults keep their current routers only if those routers are valid factory-deployed routers. If an existing router was directly deployed, remediate it and redeploy every vault that immutably references it before treating the cluster as production-ready.

### Step 3: Deploy Your Borrow Vault

Deploy one vault for your new token. `unitOfAccount` must match the existing cluster (typically USD).

```solidity
address vault = eVaultFactory.createProxy(
    address(0), true,
    abi.encodePacked(newToken, yourRouter, USD)
);
```

### Step 4: Wire ALL Routers

This is the critical step that differs from a standalone deployment. You must wire **your** router AND **every existing** router.

**Your new router** needs adapters for every token in the cluster:

```solidity
// Price your own token + every existing collateral token in USD
yourRouter.govSetConfig(newToken,      USD, newTokenAdapter);
yourRouter.govSetConfig(existingToken, USD, existingTokenAdapter); // repeat per token

// Resolve every existing vault you accept as collateral
yourRouter.govSetResolvedVault(usdcVault, true);
yourRouter.govSetResolvedVault(ethVault,  true);
```

**Each existing router** needs your token's adapter + resolved vault:

```solidity
// Add pricing for your token
existingRouter.govSetConfig(newToken, USD, newTokenAdapter);

// Resolve your vault so it can be used as collateral
existingRouter.govSetResolvedVault(newVault, true);
```

**Governor requirement:** The caller must be governor of every router touched. If a co-worker deployed the existing cluster, they run this script.

### Step 5: Configure Cluster

Set IRM, caps, and liquidation params on your new vault. Then add `setLTV` on **both sides**:

```solidity
// Your vault accepts existing vaults as collateral
IEVault(newVault).setLTV(usdcVault, borrowLTV, liqLTV, 0);
IEVault(newVault).setLTV(ethVault,  borrowLTV, liqLTV, 0);

// Existing vaults accept your vault as collateral
IEVault(usdcVault).setLTV(newVault, borrowLTV, liqLTV, 0);
IEVault(ethVault).setLTV(newVault,  borrowLTV, liqLTV, 0);
```

**Governor requirement:** Same as step 4 — caller must be governor of existing vaults.

**Cap coordination:** Your token shares the existing vaults' supply/borrow caps with all other collateral types. Coordinate with the cluster owner to ensure caps account for your token's added exposure.

### Step 6: Set Fee Receiver

Set fee receiver on your new vault only. Existing vaults' fee receivers are unchanged.

### Summary: Who Runs What

| Step | Who runs it | Why |
|---|---|---|
| 0–3 | You (new token deployer) | Creates new contracts you own |
| 4–5 | Existing cluster governor | Touches existing vaults/routers |
| 6 | You | Only touches your new vault |

If you and the cluster governor share a deployer key or multisig, one person runs everything.

### Governance Handoff

If two people are deploying into the same cluster, someone needs governor access to the other's contracts for steps 4–5. Two approaches:

**Option A: Temporary transfer (pass the baton)**

The existing cluster governor temporarily transfers governance to you, you run all scripts, then transfer back:

```solidity
// EulerRouter — single function
router.transferGovernance(newGovernor);

// eVault — different function name
vault.setGovernorAdmin(newGovernorAdmin);
```

With `cast`:
```bash
# Transfer router governance
cast send $ROUTER "transferGovernance(address)" $NEW_GOVERNOR \
  --rpc-url $RPC --private-key $CURRENT_GOVERNOR_KEY

# Transfer vault governance
cast send $VAULT "setGovernorAdmin(address)" $NEW_GOVERNOR \
  --rpc-url $RPC --private-key $CURRENT_GOVERNOR_KEY
```

**Option B: They run your scripts**

Push your scripts to the shared repo. The existing governor pulls them, fills in `.env`, and runs steps 4–5 themselves. No governance transfer needed.

**Option C: Multisig (long-term)**

Deploy a Safe multisig, transfer all vaults + routers to it, both parties are signers. This is the right end state — do it before production regardless.

**Checking current governor:**
```bash
# Router
cast call $ROUTER "governor()(address)" --rpc-url $RPC

# Vault
cast call $VAULT "governorAdmin()(address)" --rpc-url $RPC
```

---

## File Index

| What | Where |
|---|---|
| Base unified market (6-asset cluster) | `contracts/base-market-contracts/` |
| Base market scripts (per-asset folders) | `contracts/base-market-contracts/script/{vvv-usdc-eth,zro,aero,virtual,cluster-management}/` |
| Origin contracts (simplest template) | `contracts/origin-contracts/script/` |
| Cork contracts (custom oracle/hook) | `contracts/cork-contracts/script/` + `contracts/cork-contracts/src/` |
| Balancer contracts (multi-pool + adapter) | `contracts/balancer-contracts/script/` + `contracts/balancer-contracts/src/` |
| Frax contracts (ICHI oracle + keeper) | `contracts/frax-contracts/script/` + `contracts/frax-contracts/ichi-oracle-kit/` |
| Custom labels (AG frontend) | `frontends/ag-euler-balancer-labels/` |
| Consolidated frontend (all partners) | `frontends/alphagrowth/` |
| Official Euler labels (for PRs) | `reference/euler-labels/` (fork of `euler-xyz/euler-labels`) |
| Oracle checks (auto-crawled) | `reference/oracle-checks/` (clone of `euler-xyz/oracle-checks`) |
| Euler V2 addresses per chain | `reference/euler-interfaces/addresses/<chainId>/` |
| Oracle adapters per chain | `reference/euler-interfaces/addresses/<chainId>/OracleAdaptersAddresses.csv` |
| Euler reference repos | `reference/` (EVC, EVK, price oracle, etc.) |
| IRM calculator | `reference/evk-periphery/script/utils/calculate-irm-linear-kink.js` |
| Project task tracker | `TODO.md` |
| Labels + integration context | `AGENTS.md` |

---

## Lessons Learned (Base Unified Market Deployment)

### 1. Use unified vaults, not separate borrow + collateral vaults

**Problem:** The original deployment created separate "collateral vaults" (`oracle = address(0)`, `unitOfAccount = address(0)`) for each asset. This forced users to choose between earning yield (deposit in borrow vault) OR using as collateral (deposit in collateral vault) — they couldn't do both. It also fragmented liquidity across duplicate pools.

**Solution:** Deploy ONE borrow vault per asset. Set `setLTV` between borrow vaults so they accept each other as collateral. Resolve all borrow vaults in the oracle router via `govSetResolvedVault`. This matches the pattern used on the official Euler frontend (e.g. eUSDC-1).

**Reference:** `contracts/base-market-contracts/script/cluster-management/28_UnifyBorrowVaultsAsCollateral.s.sol`

### 2. Restrict volatile-to-volatile collateral pairs

To avoid risky positions (e.g. borrowing VVV against AERO), only set LTV between volatile assets and stable/blue-chip assets (USDC, ETH). Omit `setLTV` calls between volatile pairs entirely. Don't add them and then remove — just never configure them.

**Reference:** `contracts/base-market-contracts/script/cluster-management/27_RemoveVolatileVolatileLTV.s.sol`

### 3. Use consistent LTV values in scripts

When rewriting LTV configuration (e.g. migrating from split to unified vaults), copy the EXACT LTV values from the original configuration. Hardcoding default values (e.g. 80/85) in a new script will silently overwrite custom values (e.g. 85/87) that were set per-pair.

### 4. Transfer governance before submitting euler-labels PR

The official Euler frontend resolves "Risk Manager" and "Vault Type" by checking if `vault.governorAdmin` matches an address in the entity's `addresses` map. If you submit the PR while a dev wallet is still governor, the vaults will show as "Unverified" on app.euler.finance. Transfer to multisig first, then submit the PR.

**Order:** Deploy → Test → Transfer governance to multisig → Verify on-chain → Submit labels PR

### 5. Oracle provider labels are auto-discovered

Don't manually submit adapter metadata to `euler-xyz/oracle-checks`. The system runs a GitHub Action every 6 hours that crawls all oracle routers deployed via the factory and auto-generates adapter JSON files. Custom Chainlink adapters will be picked up automatically.

For local testing, you can override with `NUXT_PUBLIC_CONFIG_ORACLE_CHECKS_REPO` in the frontend `.env`.

### 6. Product grouping in labels is purely visual

Adding vaults to the same product in `products.json` only affects how they're grouped in the UI. It does NOT create any on-chain relationship between vaults. Cross-collateral capability is determined solely by `setLTV` configuration. Vaults in the same product that have no LTV set between them are completely independent markets.

### 7. AmountCap encoding for supply/borrow caps

Euler V2 encodes caps as 16-bit values: `10^(raw & 63) * (raw >> 6) / 100`. The `/100` is easy to forget — without it, decoded values are 100x too high. Use the `AmountCapLib.resolve()` function from `reference/euler-vault-kit/src/EVault/shared/types/AmountCap.sol` as the reference.

### 8. Deploy Oracle Routers only through Euler's factory interface

The router address is immutable in each vault's initialization data. A directly deployed router cannot be swapped out of an existing vault. If the router must be replaced with a factory-deployed router, every vault using the old address must be redeployed and fully reconfigured.

**Correct order:** deploy/verify adapters → deploy/verify factory router → independently review router → deploy vaults.

Never use a legacy `new EulerRouter(...)` script for a new production market.

### 9. Deploy supported oracle adapters through Euler's Oracle Deployer

Adapter addresses are mutable router configuration, so replacing a directly deployed adapter normally requires `govSetConfig`, not vault redeployment. Update every router that uses the adapter, then verify router quotes before and after the change.

Keep the exported deployment revision, adapter parameters, transaction hash, and verification results. A contract address without its base, quote, feed/source, staleness policy, and expected quote is not a sufficient deployment record.

### 10. Treat oracle configuration as a reviewed dependency graph

Test the complete route from collateral vault shares to the unit of account, not only each adapter in isolation:

```text
eVault share → underlying token → optional wrapper/adapter hops → unit of account
```

A valid individual adapter does not prove the router can price every collateral accepted by every borrow vault. Run `getQuote` tests for each enabled LTV edge and use realistic token amounts that account for decimals.

### 11. Never leave browser-only deployment records

Euler's oracle tools store revisions locally in the browser. Export configuration artifacts immediately and store them with the market's address manifest and transaction hashes. Losing browser storage should not make the deployment impossible to reproduce or audit.
