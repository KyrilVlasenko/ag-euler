# Balancer × Euler V2 Contracts (Monad)

Foundry project for deploying and configuring Euler V2 lending vaults backed by Balancer V3 BPT collateral on Monad (chain 143).

## What's here

- **Deployment scripts** (`script/01-07`): Deploy IRM, oracle router, borrow vaults, collateral vaults, LP oracles, cluster config, and enable operations.
- **BalancerBptAdapter** (`src/BalancerBptAdapter.sol`): Custom adapter for multiply/leverage on BPT vaults where Enso routing fails. Handles ERC4626 wrapping + single-sided Balancer V3 addLiquidity via Permit2.
- **Adapter deploy scripts** (`script/08, 09`): Deploy per-pool adapters for Pool 1 and Pool 4.

## Deployed addresses

| Contract | Address |
|---|---|
| AUSD Borrow Vault | `0x438cedcE647491B1d93a73d491eC19A50194c222` |
| WMON Borrow Vault | `0x75B6C392f778B8BCf9bdB676f8F128b4dD49aC19` |
| Pool 1 Vault (wnAUSD/wnUSDC/wnUSDT0) | `0x5795130BFb9232C7500C6E57A96Fdd18bFA60436` |
| Pool 2 Vault (sMON/wnWMON) | `0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5` |
| Pool 3 Vault (shMON/wnWMON) | `0x6660195421557BC6803e875466F99A764ae49Ed7` |
| Pool 4 Vault (wnLOAZND/AZND/wnAUSD) | `0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92` |
| Pool 1 BPT Adapter | `0xC904aAB60824FC8225F6c8843897fFba14c8Bf98` |
| Pool 4 BPT Adapter | `0x8753eCb44370fcd4068Dd5BA1BE5bdd85122c832` |

Full address list in `.env`.

## How the adapter works

Balancer V3 pools on Monad use ERC4626-wrapped tokens (wnAUSD, wnUSDT0, etc.). Enso Finance can't route into these pools for the forward direction. The `BalancerBptAdapter` handles:

1. Pull underlying token (e.g. AUSD) from the Euler Swapper
2. Wrap via ERC4626 deposit (AUSD → wnAUSD)
3. Permit2-approve wrapped token to Balancer Router
4. Call `addLiquidityUnbalanced` for single-sided entry
5. Return BPT to the Swapper

The adapter is invoked via the Euler Swapper's `GenericHandler` within an EVC batch. One adapter per pool, configured at deploy time, stateless.

## Quick start

```bash
# Install deps
forge install

# Build
forge build

# Deploy (example: Pool 4 adapter)
source .env && forge script script/08_DeployBptAdapter.s.sol \
  --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
  --broadcast --gas-estimate-multiplier 400
```

Always use `--gas-estimate-multiplier 400` on Monad — default gas estimates are 3-4x too low.

## AI context

See `balancer-claude.md` for full deployment learnings and adapter architecture details.
