// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

interface IEVault {
    function setLTV(address collateral, uint16 borrowLTV, uint16 liquidationLTV, uint32 rampDuration) external;
}

/// @title 29_FixLTVs
/// @notice Fix LTVs from 80/85 back to 85/87 on all borrow-vault-as-collateral pairs.
///
/// @dev Run:
///      source .env && forge script script/29_FixLTVs.s.sol \
///        --rpc-url $RPC_URL_BASE --private-key $PRIVATE_KEY --broadcast
contract FixLTVs is Script {
    uint16 constant BORROW_LTV      = 0.85e4; // 85%
    uint16 constant LIQUIDATION_LTV = 0.87e4; // 87%

    function run() external {
        address vvvBorrow     = vm.envAddress("VVV_BORROW_VAULT");
        address usdcBorrow    = vm.envAddress("USDC_BORROW_VAULT");
        address ethBorrow     = vm.envAddress("ETH_BORROW_VAULT");
        address zroBorrow     = vm.envAddress("ZRO_BORROW_VAULT");
        address virtualBorrow = vm.envAddress("VIRTUAL_BORROW_VAULT");
        address aeroBorrow    = vm.envAddress("AERO_BORROW_VAULT");

        vm.startBroadcast();

        // ── USDC borrow: 5 collateral pairs ──
        IEVault(usdcBorrow).setLTV(ethBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(usdcBorrow).setLTV(vvvBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(usdcBorrow).setLTV(zroBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(usdcBorrow).setLTV(virtualBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(usdcBorrow).setLTV(aeroBorrow,    BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── ETH borrow: 5 collateral pairs ──
        IEVault(ethBorrow).setLTV(usdcBorrow,    BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(ethBorrow).setLTV(vvvBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(ethBorrow).setLTV(zroBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(ethBorrow).setLTV(virtualBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(ethBorrow).setLTV(aeroBorrow,    BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── VVV borrow: USDC + ETH only ──
        IEVault(vvvBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(vvvBorrow).setLTV(ethBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── ZRO borrow: USDC + ETH only ──
        IEVault(zroBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(zroBorrow).setLTV(ethBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── VIRTUAL borrow: USDC + ETH only ──
        IEVault(virtualBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(virtualBorrow).setLTV(ethBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── AERO borrow: USDC + ETH only ──
        IEVault(aeroBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(aeroBorrow).setLTV(ethBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);

        vm.stopBroadcast();

        console.log("\n=== STEP 29 COMPLETE: LTVs Fixed to 85%%/87%% ===");
        console.log("Updated 20 collateral pairs across 6 borrow vaults.");
    }
}
