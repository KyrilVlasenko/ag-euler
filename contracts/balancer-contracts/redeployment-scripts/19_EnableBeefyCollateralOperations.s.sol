// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";

interface IEVault {
    function setHookConfig(address hookTarget, uint32 hookedOps) external;
    function hookConfig() external view returns (address hookTarget, uint32 hookedOps);
    function asset() external view returns (address);
}

/// @title 19_EnableBeefyCollateralOperations
/// @notice Clear the disabled-operations flag on the Beefy wrapper collateral EVault.
///
/// @dev The Monad EVault factory initializes vaults with hookedOps=32767
///      (all ops disabled) and hookTarget=address(0). This must be called
///      after deployment to enable deposit/withdraw/etc.
///
/// @dev This script does NOT transfer governance and does NOT update labels.
///
/// @dev IMPORTANT: forge script --broadcast may fail on Monad due to gas estimation
///      and nonce issues. If so, use cast send instead:
///
///      source .env
///      cast send $NEW_BEEFY_COLLATERAL_EVAULT "setHookConfig(address,uint32)" \
///        "0x0000000000000000000000000000000000000000" 0 \
///        --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MONAD
///
/// @dev Verify with:
///      cast call $NEW_BEEFY_COLLATERAL_EVAULT "hookConfig()(address,uint32)" --rpc-url $RPC_URL_MONAD
///      # Should return address(0) and 0.
///
/// @dev Run:
///      source .env && forge script redeployment-scripts/19_EnableBeefyCollateralOperations.s.sol \
///        --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
///        --broadcast --gas-estimate-multiplier 400
contract EnableBeefyCollateralOperations is Script {
    address constant BEEFY_WRAPPER = 0x6e58131ea11ed990D4b62476529cF2502Fe0eC5F;

    function run() external {
        address beefyCollateralVault = vm.envAddress("NEW_BEEFY_COLLATERAL_EVAULT");
        IEVault v = IEVault(beefyCollateralVault);

        address vaultAsset = v.asset();
        require(vaultAsset == BEEFY_WRAPPER, "unexpected Beefy collateral asset");

        vm.startBroadcast();

        (address hookTarget, uint32 hookedOps) = v.hookConfig();
        if (hookTarget == address(0) && hookedOps != 0) {
            v.setHookConfig(address(0), 0);
            console.log("Enabled operations on Beefy collateral vault: %s", beefyCollateralVault);
        } else {
            console.log("Already OK: %s (hookTarget=%s, hookedOps=%s)", beefyCollateralVault, hookTarget, hookedOps);
        }

        vm.stopBroadcast();

        console.log("\n=== SCRIPT 19 COMPLETE: Beefy Collateral Operations Enabled ===");
        console.log("NEW_BEEFY_COLLATERAL_EVAULT=%s", beefyCollateralVault);
        console.log("Verified asset=%s", vaultAsset);
        console.log("\nNext: generate Safe tx JSON with generate-beefy-safe-txs.js.");
        console.log("Governance transfer and frontend label updates are intentionally not included.");
    }
}
