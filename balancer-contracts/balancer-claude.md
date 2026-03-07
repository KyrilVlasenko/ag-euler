# Balancer BPT Vault Deployment — AI Context

Deployment completed on Monad (chain 143). This file covers the contract deployment, the BalancerBptAdapter for multiply, and hard-won lessons.

---

## Deployed Addresses

### Euler Vaults

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

LP Oracles and ChainlinkOracle adapters in `.env`.

### Balancer BPT Adapters

| Contract | Address | Pool |
|---|---|---|
| Pool 1 BPT Adapter | `0xC904aAB60824FC8225F6c8843897fFba14c8Bf98` | wnUSDT0/wnAUSD/wnUSDC |
| Pool 4 BPT Adapter | `0x8753eCb44370fcd4068Dd5BA1BE5bdd85122c832` | AZND/wnAUSD/wnLOAZND |

### External Contracts (Monad)

| Contract | Address |
|---|---|
| Balancer V3 Router | `0x9dA18982a33FD0c7051B19F0d7C76F2d5E7e017c` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |
| Euler Swapper | `0xB6D7194fD09F27890279caB08d565A6424fb525D` |
| Euler SwapVerifier | `0x65bF068c88e0f006f76b871396B4DB1150dd9EAD` |

---

## BalancerBptAdapter (`src/BalancerBptAdapter.sol`)

### Purpose

Enables "multiply" (leveraged looping) for Balancer V3 BPT collateral vaults on Euler V2. When a user wants to leverage their BPT position, Euler borrows the borrow asset (AUSD), converts it to BPT, and deposits the BPT as collateral — all in one EVC batch.

The adapter handles the conversion step: borrow asset → (ERC4626 wrap) → Balancer pool token → addLiquidityUnbalanced → BPT.

### Why it exists

Enso Finance (the routing API) cannot route into Pool 1 or Pool 4 for the forward direction (AUSD → BPT) because these pools use ERC4626-wrapped tokens (wnAUSD, wnUSDT0, etc.) that have no direct DEX liquidity. The adapter bridges this gap by handling wrapping + single-sided Balancer deposit in one call.

### Architecture

```
EVC Batch (atomic):
  1. Euler borrow vault → borrow AUSD → send to Swapper
  2. Swapper.multicall([
       swap(GenericHandler → adapter.zapIn) → AUSD becomes BPT in Swapper,
       deposit(BPT, collateralVault, account) → BPT into Euler vault
     ])
  3. SwapVerifier.verifyAmountMinAndSkim → ensures enough BPT was deposited
```

The Swapper inherits GenericHandler (not delegatecall — direct inheritance). When GenericHandler calls `target.call(payload)`, `msg.sender` in the adapter is the **Swapper address**. The adapter pulls tokens from the Swapper and sends output back to the Swapper.

### Multiply vs Repay routing

| Direction | Pool 1 | Pool 2 | Pool 3 | Pool 4 |
|---|---|---|---|---|
| **Multiply** (borrow→BPT) | Adapter | Enso | Enso | Adapter |
| **Repay** (BPT→borrow) | Enso | Enso | Enso | Enso |

Enso can route BPT → underlying for all 4 pools (reverse direction). The adapter's `zapOut` function exists but is **not used in production** because Balancer V3 pool hooks block `removeLiquiditySingleTokenExactIn` (reverts with `AfterRemoveLiquidityHookFailed`).

### Key implementation details

1. **Permit2 for addLiquidity**: Balancer V3 Router uses Permit2 for pulling tokens during `addLiquidity`, not standard ERC20 approve. The constructor pre-approves all pool tokens to Permit2 (`IERC20.approve(PERMIT2, max)`). Before each addLiquidity call, `IPermit2.approve(token, router, maxAmount, maxExpiration)` is called.

2. **Direct approve for removeLiquidity**: Balancer V3 Router uses standard ERC20 approve (not Permit2) for pulling BPT during `removeLiquidity`.

3. **Return type mismatch**: The Balancer V3 Router's `addLiquidityUnbalanced` returns `(uint256 bptAmountOut)`, NOT `(uint256[] memory)`. Using the wrong return type causes a silent ABI decode failure.

4. **One adapter per pool**: Each adapter is configured at deploy time with the pool address, router, and per-token config (poolToken, underlying, needsWrap). Stateless between calls.

### Deploying a new adapter

```bash
# Edit the deploy script with the correct pool/token addresses
# Then:
source .env && forge script script/08_DeployBptAdapter.s.sol \
  --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
  --broadcast --gas-estimate-multiplier 400
```

### Frontend config

The frontend reads adapter config from `NUXT_PUBLIC_CONFIG_BPT_ADAPTER_CONFIG` — a JSON map of collateral vault address → `{adapter, tokenIndex}`:

```
NUXT_PUBLIC_CONFIG_BPT_ADAPTER_CONFIG={"0xVaultAddr":{"adapter":"0xAdapterAddr","tokenIndex":1}}
```

---

## Hard-Won Lessons

### 1. `[etherscan]` in foundry.toml breaks `forge script` on unknown chains

The `[etherscan]` block with `chain = "143"` causes `Error: Chain 143 not supported` even for dry runs with no `--verify` flag. Remove the entire `[etherscan]` section.

### 2. EVault `createProxy` trailingData must be exactly 60 bytes

`GenericFactory.createProxy(implementation, upgradeable, trailingData)` prepends `bytes4(0)` to trailingData, making it 64 bytes (`PROXY_METADATA_LENGTH`). The vault's `initialize()` checks `msg.data.length == 4 + 32 + 64` and reverts with `E_ProxyMetadata()` if wrong.

Correct format: `abi.encodePacked(asset, oracle, unitOfAccount)` = 3 x 20 bytes = 60 bytes.

For **borrow vaults**: pass real oracle (EulerRouter) and unitOfAccount.
For **collateral vaults**: pass `address(0)` for both oracle and unitOfAccount — they're unused.

### 3. `forge script` gas estimates are ~3-4x too low on Monad

Always use `--gas-estimate-multiplier 400` for all `forge script --broadcast` calls on Monad.

### 4. Never mix deploy + config in the same forge script on Monad

Deploy in one script, configure in the next. Read addresses from `.env` via `vm.envAddress()`.

### 5. `setLTV` takes `uint32 rampDuration`, not `uint16`

```solidity
function setLTV(address collateral, uint16 borrowLTV, uint16 liquidationLTV, uint32 rampDuration) external;
```

### 6. Oracle for collateral vaults is set on the BORROW vault

The EulerRouter lives on the borrow vault. When Euler prices collateral, it uses the borrow vault's configured oracle.

### 7. IRM factory: use KinkIRM, not KinkyIRM

`kinkIRMFactory` (`0x05Cc...`): 4-param standard 2-slope linear. This is what the calculator outputs.

### 8. `ethereum-vault-connector` remapping must point to `src/`

Add to `remappings.txt`:
```
ethereum-vault-connector/=lib/euler-price-oracle/lib/ethereum-vault-connector/src/
```

### 9. Solidity requires EIP-55 checksummed addresses

### 10. `cast send` works when `forge script --broadcast` fails on Monad

### 11. Monad EVault factory initializes vaults with operations disabled

Call `setHookConfig(address(0), 0)` on each vault after deployment.

### 12. Frontend CSP blocks chain default RPCs

Route wagmi through the app's server proxy (`/api/rpc/<chainId>`).

### 13. TOS signing must be explicitly bypassed when unset

Add early return in `prepareTos()` when `enableTermsOfUseSignature` is false.

### 14. EulerRouter requires `govSetResolvedVault` for collateral vaults

```bash
for VAULT in $POOL1_VAULT $POOL2_VAULT $POOL3_VAULT $POOL4_VAULT; do
  cast send $EULER_ROUTER "govSetResolvedVault(address,bool)" $VAULT true \
    --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MONAD
done
```

### 15. Balancer V3 Router uses Permit2 for addLiquidity, ERC20 approve for removeLiquidity

Two different approval patterns for the same contract. For deposits: ERC20 approve token → Permit2, then `Permit2.approve(token, router, amount, expiration)`. For BPT removal: direct `BPT.approve(router, amount)`.

### 16. Balancer V3 `addLiquidityUnbalanced` returns `uint256`, not `uint256[]`

The Solidity interface must match exactly or ABI decoding fails silently. The Router returns a single `uint256 bptAmountOut`. Declaring the return as `uint256[] memory` causes the adapter to revert with empty data after the Router call succeeds.

### 17. Pool hooks can block `removeLiquiditySingleTokenExactIn`

Balancer V3 pools can have hooks that reject certain operations. Our pools' `onAfterRemoveLiquidity` hook returns `false` for single-sided removals, causing `AfterRemoveLiquidityHookFailed()`. This affects ALL callers, not just the adapter. Use Enso for the reverse direction — it routes through alternative paths (AMMs, proportional remove, etc.).

### 18. Adapter iterations: expect multiple deploys

The adapter went through 5 versions during testing due to Permit2 discovery, ABI mismatch, and hook rejection. Each deploy is cheap (<$0.01 on Monad). Don't over-engineer — deploy, test with `cast`, iterate.
