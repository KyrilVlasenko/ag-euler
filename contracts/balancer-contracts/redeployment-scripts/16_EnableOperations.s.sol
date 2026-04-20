// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";

interface IEVault {
    function setHookConfig(address hookTarget, uint32 hookedOps) external;
    function hookConfig() external view returns (address hookTarget, uint32 hookedOps);
    function governorAdmin() external view returns (address);
    function asset() external view returns (address);
}

/// @title 16_EnableOperations
/// @notice Clear the disabled-operations flag on the 3 new collateral vaults.
///
/// @dev The Monad EVault factory initializes vaults with hookedOps=32767
///      (all ops disabled) and hookTarget=address(0). This must be called
///      to enable deposit/withdraw/etc.
///
/// @dev The deployer is the initial governor of these new vaults, so these
///      calls can be made directly without the multisig.
///
/// @dev Governance transfer (setGovernorAdmin → multisig) is NOT done here.
///      It will be done manually in Step 2E after all testing is complete.
///
/// @dev IMPORTANT: forge script --broadcast may fail on Monad due to gas estimation
///      and nonce issues with batched transactions. If so, use cast send instead:
///
///      source .env
///      for VAULT in $NEW_POOL2_VAULT $NEW_POOL3_VAULT $NEW_POOL4_VAULT; do
///        cast send $VAULT "setHookConfig(address,uint32)" \
///          "0x0000000000000000000000000000000000000000" 0 \
///          --private-key $PRIVATE_KEY --rpc-url $RPC_URL_MONAD
///      done
///
/// @dev Verify with:
///      cast call $VAULT "hookConfig()(address,uint32)" --rpc-url $RPC_URL_MONAD
///      # Should return address(0) and 0
///
/// @dev Run:
///      source .env && forge script redeployment-scripts/16_EnableOperations.s.sol \
///        --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY --broadcast
contract EnableOperations is Script {
    function run() external {
        address newPool2Vault = vm.envAddress("NEW_POOL2_VAULT");
        address newPool3Vault = vm.envAddress("NEW_POOL3_VAULT");
        address newPool4Vault = vm.envAddress("NEW_POOL4_VAULT");

        address[3] memory vaults = [newPool2Vault, newPool3Vault, newPool4Vault];
        string[3] memory names = ["New Pool2 (Kintsu)", "New Pool3 (Fastlane)", "New Pool4 (AZND)"];

        vm.startBroadcast();

        for (uint256 i = 0; i < vaults.length; i++) {
            IEVault v = IEVault(vaults[i]);

            (address hookTarget, uint32 hookedOps) = v.hookConfig();
            if (hookTarget == address(0) && hookedOps != 0) {
                v.setHookConfig(address(0), 0);
                console.log("Enabled ops on %s: %s", names[i], vaults[i]);
            } else {
                console.log("Already OK   %s: %s (hookedOps=%s)", names[i], vaults[i], hookedOps);
            }
        }

        vm.stopBroadcast();

        console.log("\n=== SCRIPT 16 COMPLETE: Operations enabled ===");
        console.log("\nPhase 1 complete. Run Phase 1 Verification checks, then proceed to Phase 2.");
        console.log("Next: Step 2A -- hide new vaults in frontend (hiddenCollateralVaults.ts)");
    }
}
