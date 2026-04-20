// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";

interface IEVaultFactory {
    function createProxy(address implementation, bool upgradeable, bytes calldata trailingData)
        external returns (address vault);
}

/// @title 13_RedeployCollateralVaults
/// @notice Redeploy 3 BPT collateral vaults with the correct Merkl-incentivized pool addresses.
///
/// @dev Replaces:
///      Pool 2 - Kintsu sMON/wnWMON     (old BPT: 0x3475...BAc → new: 0x02b3...7f8)
///      Pool 3 - Fastlane shMON/wnWMON  (old BPT: 0x1503...b68 → new: 0x340F...6Cb)
///      Pool 4 - wnLOAZND/AZND/wnAUSD   (old BPT: 0xD328...D3  → new: 0xbddb...dE)
///
/// @dev Pool 1 (wnAUSD/wnUSDC/wnUSDT0) is unchanged — correct BPT already deployed.
///
/// @dev Run:
///      source .env && forge script redeployment-scripts/13_RedeployCollateralVaults.s.sol \
///        --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
///        --broadcast --verify
///
/// @dev After running: paste NEW_POOL2_VAULT, NEW_POOL3_VAULT, NEW_POOL4_VAULT into .env,
///      then run 14_RedeployOracles.s.sol
contract RedeployCollateralVaults is Script {
    address constant EVAULT_FACTORY = 0xba4Dd672062dE8FeeDb665DD4410658864483f1E;

    // Correct BPT addresses (Merkl-incentivized pools)
    address constant NEW_POOL2_BPT = 0x02b34a02db24179Ac2D77Ae20AA6215C7153E7f8; // Kintsu wnSMON/wnWMON
    address constant NEW_POOL3_BPT = 0x340Fa62AE58e90473da64b0af622cdd6113106Cb; // Fastlane wnSHMON/wnWMON
    address constant NEW_POOL4_BPT = 0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE; // wnLOAZND/AZND/wnAUSD

    function run() external {
        vm.startBroadcast();

        // Collateral vaults: asset=BPT, oracle=address(0), unitOfAccount=address(0).
        // Factory requires exactly 60 bytes of trailingData (prepends bytes4(0) → 64 = PROXY_METADATA_LENGTH).
        // Oracle/UoA on collateral vaults are unused — pricing happens via the borrow vault's EulerRouter.
        address newPool2Vault = IEVaultFactory(EVAULT_FACTORY).createProxy(
            address(0), true, abi.encodePacked(NEW_POOL2_BPT, address(0), address(0))
        );
        address newPool3Vault = IEVaultFactory(EVAULT_FACTORY).createProxy(
            address(0), true, abi.encodePacked(NEW_POOL3_BPT, address(0), address(0))
        );
        address newPool4Vault = IEVaultFactory(EVAULT_FACTORY).createProxy(
            address(0), true, abi.encodePacked(NEW_POOL4_BPT, address(0), address(0))
        );

        vm.stopBroadcast();

        console.log("\n=== SCRIPT 13 COMPLETE: Redeployed Collateral Vaults ===");
        console.log("NEW_POOL2_VAULT=%s  (Kintsu wnSMON/wnWMON)", newPool2Vault);
        console.log("NEW_POOL3_VAULT=%s  (Fastlane wnSHMON/wnWMON)", newPool3Vault);
        console.log("NEW_POOL4_VAULT=%s  (wnLOAZND/AZND/wnAUSD)", newPool4Vault);
        console.log("\nPaste all three into .env, then run 14_RedeployOracles.s.sol");
    }
}
