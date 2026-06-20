# AlphaGrowth AUSD PT Cluster — Monad

Foundry deployment package for two isolated Euler V2 markets:

- Borrow AUSD against PT-AUSD-8OCT2026
- Borrow AUSD against PT-earnAUSD-8OCT2026

Both markets use the existing factory-deployed Euler router and remain governed by the deployment wallet. This package intentionally does not transfer governance or modify labels/frontend files.

## Execution order

Source a secret-bearing environment outside version control, then run:

```bash
forge script script/01_DeployIRMs.s.sol --rpc-url "$RPC_URL_MONAD" --private-key "$PRIVATE_KEY" --broadcast --slow --gas-estimate-multiplier 400
forge script script/02_DeployVaults.s.sol --rpc-url "$RPC_URL_MONAD" --private-key "$PRIVATE_KEY" --broadcast --slow --gas-estimate-multiplier 400
forge script script/03_WireRouter.s.sol --rpc-url "$RPC_URL_MONAD" --private-key "$PRIVATE_KEY" --broadcast --slow --gas-estimate-multiplier 400
forge script script/04_ConfigureMarkets.s.sol --rpc-url "$RPC_URL_MONAD" --private-key "$PRIVATE_KEY" --broadcast --slow --gas-estimate-multiplier 400
forge script script/05_ActivateMarkets.s.sol --rpc-url "$RPC_URL_MONAD" --private-key "$PRIVATE_KEY" --broadcast --slow --gas-estimate-multiplier 400
forge script script/06_VerifyDeployment.s.sol --rpc-url "$RPC_URL_MONAD"
forge script script/07_TransferGovernance.s.sol --rpc-url "$RPC_URL_MONAD" --private-key "$PRIVATE_KEY" --broadcast --slow --gas-estimate-multiplier 400
```

Add each script's output addresses to the environment before running the next dependent step.

## Safety checks

- `03_WireRouter` refuses to run if the router factory, governor, or existing adapter routes do not match the reviewed configuration.
- `--slow` is mandatory on Monad so each transaction receipt is confirmed before the next nonce is sent.
- `06_VerifyDeployment` verifies IRMs, metadata, governance, fees, caps, LTV isolation, hooks, router resolution, and live collateral-vault quotes.
- The fork test exercises deposit, borrow, repay, withdraw, cap decoding, and rejection of cross-market collateral.
