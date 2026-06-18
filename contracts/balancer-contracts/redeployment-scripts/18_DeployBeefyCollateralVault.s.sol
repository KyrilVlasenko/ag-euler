// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";

interface IEVaultFactory {
    function createProxy(address implementation, bool upgradeable, bytes calldata trailingData)
        external
        returns (address vault);
}

/// @title 18_DeployBeefyCollateralVault
/// @notice Deploy the Beefy ERC4626 wrapper collateral EVault for the AUSD cluster.
///
/// @dev This script only deploys the collateral vault. It does NOT transfer governance,
///      update frontend labels, wire the EulerRouter, or set AUSD LTVs.
///
/// @dev The collateral EVault asset is the Beefy wrapper token, not the raw moo token.
///      The wrapper itself resolves to the Pool 1 Balancer BPT through ERC4626 asset().
///
/// @dev Run:
///      source .env && forge script redeployment-scripts/18_DeployBeefyCollateralVault.s.sol \
///        --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
///        --broadcast --verify --gas-estimate-multiplier 400
///
/// @dev After running:
///      1. Save NEW_BEEFY_COLLATERAL_EVAULT=<deployed address> in .env.
///      2. Run 19_EnableBeefyCollateralOperations.s.sol.
///      3. Generate Safe tx JSON with generate-beefy-safe-txs.js.
contract DeployBeefyCollateralVault is Script {
    address constant EVAULT_FACTORY = 0xba4Dd672062dE8FeeDb665DD4410658864483f1E;

    // WMoo Balancer Monad wnUSDT0-wnAUSD-wnUSDC.
    // asset() = Pool 1 Balancer BPT 0x2DAA146dfB7EAef0038F9F15B2EC1e4DE003f72b.
    address constant BEEFY_WRAPPER = 0x6e58131ea11ed990D4b62476529cF2502Fe0eC5F;

    function run() external {
        vm.startBroadcast();

        // Collateral vault: asset=Beefy wrapper, oracle=address(0), unitOfAccount=address(0).
        // Factory requires exactly 60 bytes of trailingData (prepends bytes4(0) -> 64 bytes).
        // Pricing happens through the AUSD borrow vault's EulerRouter after Safe wiring.
        address beefyCollateralVault = IEVaultFactory(EVAULT_FACTORY)
            .createProxy(address(0), true, abi.encodePacked(BEEFY_WRAPPER, address(0), address(0)));

        vm.stopBroadcast();

        console.log("\n=== SCRIPT 18 COMPLETE: Beefy Collateral Vault Deployed ===");
        console.log("NEW_BEEFY_COLLATERAL_EVAULT=%s", beefyCollateralVault);
        console.log("BEEFY_WRAPPER=%s", BEEFY_WRAPPER);
        console.log("\nNext:");
        console.log("1. Add NEW_BEEFY_COLLATERAL_EVAULT to .env.");
        console.log("2. Run 19_EnableBeefyCollateralOperations.s.sol.");
        console.log("3. Generate Safe JSON payloads with generate-beefy-safe-txs.js.");
        console.log("\nNo governance transfer or frontend label updates are performed by this script.");
    }
}
