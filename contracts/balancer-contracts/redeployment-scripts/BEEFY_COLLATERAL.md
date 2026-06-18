# Beefy Wrapper Collateral Deployment

This runbook adds the Beefy ERC4626 wrapper for the Pool 1 Balancer BPT as a new AUSD collateral vault.

## Addresses

| Item | Address |
|---|---|
| Chain | Monad `143` |
| EVault Factory | `0xba4Dd672062dE8FeeDb665DD4410658864483f1E` |
| EulerRouter | `0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73` |
| AUSD Borrow Vault | `0x438cedcE647491B1d93a73d491eC19A50194c222` |
| AUSD | `0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a` |
| Beefy moo vault | `0xd0331a023C35514c2EF99Eb34ED868737e9dCeA3` |
| Beefy ERC4626 wrapper | `0x6e58131ea11ed990d4b62476529cf2502fe0ec5f` |
| Pool 1 BPT | `0x2DAA146dfB7EAef0038F9F15B2EC1e4DE003f72b` |

## Deploy

Deploy the collateral EVault. The EVault asset is the Beefy wrapper token.

```bash
source .env
forge script redeployment-scripts/18_DeployBeefyCollateralVault.s.sol \
  --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
  --broadcast --verify --gas-estimate-multiplier 400
```

Save the output:

```bash
NEW_BEEFY_COLLATERAL_EVAULT=0x...
```

Enable EVault operations:

```bash
source .env
forge script redeployment-scripts/19_EnableBeefyCollateralOperations.s.sol \
  --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
  --broadcast --gas-estimate-multiplier 400
```

If the script has Monad gas-estimation issues, use the direct cast call printed in the script comments.

## Safe Payloads

Generate Safe Transaction Builder JSON after `NEW_BEEFY_COLLATERAL_EVAULT` is known:

```bash
source .env
node redeployment-scripts/generate-beefy-safe-txs.js
```

Validate payload generation without writing files:

```bash
NEW_BEEFY_COLLATERAL_EVAULT=0x1111111111111111111111111111111111111111 \
  node redeployment-scripts/generate-beefy-safe-txs.js --dry-run
```

This writes:

- `redeployment-scripts/safe-tx-beefy-wire-router.json`
- `redeployment-scripts/safe-tx-beefy-add-ausd-ltv.json`

Submit these manually through the AG Safe. Do not submit before the deployment and enable-operations checks pass.

Router payload:

- `govSetResolvedVault(NEW_BEEFY_COLLATERAL_EVAULT, true)`
- `govSetResolvedVault(0x6e58131ea11ed990d4b62476529cf2502fe0ec5f, true)`

AUSD LTV payload:

- `setLTV(NEW_BEEFY_COLLATERAL_EVAULT, 9500, 9600, 0)`

## Verification

Before Safe submission:

```bash
cast call $NEW_BEEFY_COLLATERAL_EVAULT "asset()(address)" --rpc-url $RPC_URL_MONAD
cast call $NEW_BEEFY_COLLATERAL_EVAULT "hookConfig()(address,uint32)" --rpc-url $RPC_URL_MONAD
```

Expected:

- `asset()` returns `0x6e58131ea11ed990d4b62476529cf2502fe0ec5f`
- `hookConfig()` returns `address(0)` and `0`

After router Safe execution:

```bash
cast call 0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73 \
  "resolvedVaults(address)(address)" \
  $NEW_BEEFY_COLLATERAL_EVAULT --rpc-url $RPC_URL_MONAD

cast call 0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73 \
  "resolvedVaults(address)(address)" \
  0x6e58131ea11ed990d4b62476529cf2502fe0ec5f --rpc-url $RPC_URL_MONAD

cast call 0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73 \
  "getQuote(uint256,address,address)(uint256)" \
  1000000000000000000 \
  0x6e58131ea11ed990d4b62476529cf2502fe0ec5f \
  0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a \
  --rpc-url $RPC_URL_MONAD

cast call 0x77C3b512d1d9E1f22EeCde73F645Da14f49CeC73 \
  "getQuote(uint256,address,address)(uint256)" \
  1000000000000000000 \
  $NEW_BEEFY_COLLATERAL_EVAULT \
  0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a \
  --rpc-url $RPC_URL_MONAD
```

Expected:

- `resolvedVaults(NEW_BEEFY_COLLATERAL_EVAULT)` returns the Beefy wrapper.
- `resolvedVaults(BEEFY_WRAPPER)` returns Pool 1 BPT.
- Both `getQuote` calls return non-zero AUSD values.

After AUSD LTV Safe execution:

```bash
cast call 0x438cedcE647491B1d93a73d491eC19A50194c222 \
  "LTVBorrow(address)(uint16)" \
  $NEW_BEEFY_COLLATERAL_EVAULT --rpc-url $RPC_URL_MONAD

cast call 0x438cedcE647491B1d93a73d491eC19A50194c222 \
  "LTVLiquidation(address)(uint16)" \
  $NEW_BEEFY_COLLATERAL_EVAULT --rpc-url $RPC_URL_MONAD
```

Expected:

- `LTVBorrow` returns `9500`.
- `LTVLiquidation` returns `9600`.

## Explicit Non-Goals

- Do not transfer governance of the new vault until explicitly requested.
- Do not update frontend labels until explicitly requested.
- Do not submit Safe transactions from scripts.
- Do not add reverse route or unwind adapter support in this step.
- Do not add raw moo-token wrap-and-supply support in this step.
