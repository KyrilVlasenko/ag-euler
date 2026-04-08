// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EulerRouter} from "euler-price-oracle/EulerRouter.sol";

interface IEVault {
    function setGovernorAdmin(address newGovernorAdmin) external;
}

/// @title 30_TransferGovernance
/// @notice Transfer governor of all 6 borrow vaults and the oracle router
///         from the deployer EOA to the Reservoir DAO Multisig.
///
/// @dev Run:
///      source .env && forge script script/cluster-management/30_TransferGovernance.s.sol \
///        --rpc-url $RPC_URL_BASE --private-key $PRIVATE_KEY --broadcast
contract TransferGovernance is Script {
    address constant MULTISIG = 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C;

    function run() external {
        address router        = vm.envAddress("EULER_ROUTER");
        address usdcBorrow    = vm.envAddress("USDC_BORROW_VAULT");
        address ethBorrow     = vm.envAddress("ETH_BORROW_VAULT");
        address vvvBorrow     = vm.envAddress("VVV_BORROW_VAULT");
        address zroBorrow     = vm.envAddress("ZRO_BORROW_VAULT");
        address aeroBorrow    = vm.envAddress("AERO_BORROW_VAULT");
        address virtualBorrow = vm.envAddress("VIRTUAL_BORROW_VAULT");

        vm.startBroadcast();

        // ── Transfer vault governance ──
        IEVault(usdcBorrow).setGovernorAdmin(MULTISIG);
        IEVault(ethBorrow).setGovernorAdmin(MULTISIG);
        IEVault(vvvBorrow).setGovernorAdmin(MULTISIG);
        IEVault(zroBorrow).setGovernorAdmin(MULTISIG);
        IEVault(aeroBorrow).setGovernorAdmin(MULTISIG);
        IEVault(virtualBorrow).setGovernorAdmin(MULTISIG);

        // ── Transfer oracle router governance ──
        EulerRouter(router).transferGovernance(MULTISIG);

        vm.stopBroadcast();

        console.log("\n=== STEP 30 COMPLETE: Governance Transferred ===");
        console.log("New governor: %s (Reservoir DAO Multisig)", MULTISIG);
        console.log("\nVaults transferred:");
        console.log("  USDC:    %s", usdcBorrow);
        console.log("  ETH:     %s", ethBorrow);
        console.log("  VVV:     %s", vvvBorrow);
        console.log("  ZRO:     %s", zroBorrow);
        console.log("  AERO:    %s", aeroBorrow);
        console.log("  VIRTUAL: %s", virtualBorrow);
        console.log("  Router:  %s", router);
    }
}
