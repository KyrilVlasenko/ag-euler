// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {BalancerBptAdapter} from "../src/BalancerBptAdapter.sol";

/// @title 15_RedeployBptAdapter
/// @notice Deploy new BalancerBptAdapter for Pool 4 (wnLOAZND/AZND/wnAUSD) with the
///         correct Merkl-incentivized BPT address.
///
///         The new pool has identical token order and addresses as the old pool:
///           [0] AZND        = 0x4917a5ec9fCb5e10f47CBB197aBe6aB63be81fE8
///           [1] wnAUSD      = 0x82c370ba90E38ef6Acd8b1b078d34fD86FC6bAC9  (wraps AUSD)
///           [2] wnLOAZND    = 0xD786F7569C39A9F64E6A54Eb77db21364E90F279  (wraps LOAZND)
///
///         Only the BPT/pool address changes:
///           Old: 0xD328E74AdD15Ac98275737a7C1C884ddc951f4D3
///           New: 0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE
///
/// @dev Run:
///      source .env && forge script redeployment-scripts/15_RedeployBptAdapter.s.sol \
///        --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
///        --broadcast --gas-estimate-multiplier 400
///
/// @dev After running: paste NEW_POOL4_BPT_ADAPTER into .env,
///      then run 16_EnableOperations.s.sol.
contract RedeployBptAdapter is Script {
    // Balancer V3 Router on Monad
    address constant BALANCER_ROUTER = 0x9dA18982a33FD0c7051B19F0d7C76F2d5E7e017c;

    // New Pool 4 BPT (correct Merkl-incentivized pool)
    address constant NEW_POOL4_BPT = 0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE;

    // Pool tokens in on-chain registration order (identical to old pool)
    address constant AZND      = 0x4917a5ec9fCb5e10f47CBB197aBe6aB63be81fE8;
    address constant WN_AUSD   = 0x82c370ba90E38ef6Acd8b1b078d34fD86FC6bAC9;
    address constant WN_LOAZND = 0xD786F7569C39A9F64E6A54Eb77db21364E90F279;

    // Underlying tokens
    address constant AUSD   = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address constant LOAZND = 0x9c82eB49B51F7Dc61e22Ff347931CA32aDc6cd90;

    function run() external {
        BalancerBptAdapter.TokenConfig[] memory configs = new BalancerBptAdapter.TokenConfig[](3);

        // [0] AZND — no wrapping needed, goes directly into pool
        configs[0] = BalancerBptAdapter.TokenConfig({
            poolToken: AZND,
            underlying: AZND,
            needsWrap: false
        });

        // [1] wnAUSD — wraps AUSD via ERC4626
        configs[1] = BalancerBptAdapter.TokenConfig({
            poolToken: WN_AUSD,
            underlying: AUSD,
            needsWrap: true
        });

        // [2] wnLOAZND — wraps LOAZND via ERC4626
        configs[2] = BalancerBptAdapter.TokenConfig({
            poolToken: WN_LOAZND,
            underlying: LOAZND,
            needsWrap: true
        });

        vm.startBroadcast();

        BalancerBptAdapter adapter = new BalancerBptAdapter(
            BALANCER_ROUTER,
            NEW_POOL4_BPT,
            configs
        );

        vm.stopBroadcast();

        console.log("\n=== SCRIPT 15 COMPLETE: BPT Adapter ===");
        console.log("NEW_POOL4_BPT_ADAPTER=%s", address(adapter));
        console.log("\nAdapter supports:");
        console.log("  [0] AZND      -> New Pool4 BPT (no wrap)");
        console.log("  [1] AUSD      -> wnAUSD -> New Pool4 BPT (ERC4626 wrap)");
        console.log("  [2] LOAZND    -> wnLOAZND -> New Pool4 BPT (ERC4626 wrap)");
        console.log("\nFor multiply via AUSD borrow: use tokenIndex=1");
        console.log("Paste NEW_POOL4_BPT_ADAPTER into .env, then run 16_EnableOperations.s.sol");
    }
}
