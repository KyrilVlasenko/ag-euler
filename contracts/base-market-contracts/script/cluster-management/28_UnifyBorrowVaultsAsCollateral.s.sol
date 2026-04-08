// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EulerRouter} from "euler-price-oracle/EulerRouter.sol";

interface IEVault {
    function setLTV(address collateral, uint16 borrowLTV, uint16 liquidationLTV, uint32 rampDuration) external;
}

/// @title 28_UnifyBorrowVaultsAsCollateral
/// @notice Rewire the cluster so borrow vaults double as collateral vaults.
///         After this script, each asset has ONE vault that users deposit into
///         for both lending yield and collateral. The old standalone collateral
///         vaults are zeroed out and become unused.
///
/// @dev Three phases:
///      A. Oracle: govSetResolvedVault on all 6 borrow vaults so the router
///         can price them when used as collateral.
///      B. LTV add: each borrow vault accepts other borrow vaults as collateral.
///         Volatile-to-volatile pairs are NOT added (matches step 27 restriction):
///           - USDC/ETH accept all 5 others
///           - VVV/ZRO/VIRTUAL/AERO accept only USDC + ETH
///      C. LTV remove: zero out old collateral vault references on all borrow vaults.
///
/// @dev Run:
///      source .env && forge script script/28_UnifyBorrowVaultsAsCollateral.s.sol \
///        --rpc-url $RPC_URL_BASE --private-key $PRIVATE_KEY --broadcast
contract UnifyBorrowVaultsAsCollateral is Script {
    uint16 constant BORROW_LTV      = 0.80e4; // 80%
    uint16 constant LIQUIDATION_LTV = 0.85e4; // 85%

    function run() external {
        // ── Shared oracle router ──
        address router = vm.envAddress("EULER_ROUTER");

        // ── Borrow vaults (will also serve as collateral) ──
        address vvvBorrow     = vm.envAddress("VVV_BORROW_VAULT");
        address usdcBorrow    = vm.envAddress("USDC_BORROW_VAULT");
        address ethBorrow     = vm.envAddress("ETH_BORROW_VAULT");
        address zroBorrow     = vm.envAddress("ZRO_BORROW_VAULT");
        address virtualBorrow = vm.envAddress("VIRTUAL_BORROW_VAULT");
        address aeroBorrow    = vm.envAddress("AERO_BORROW_VAULT");

        // ── Old collateral vaults (to be zeroed out) ──
        address usdcColl    = vm.envAddress("USDC_COLLATERAL_VAULT");
        address vvvColl     = vm.envAddress("VVV_COLLATERAL_VAULT");
        address wethColl    = vm.envAddress("WETH_COLLATERAL_VAULT");
        address zroColl     = vm.envAddress("ZRO_COLLATERAL_VAULT");
        address virtualColl = vm.envAddress("VIRTUAL_COLLATERAL_VAULT");
        address aeroColl    = vm.envAddress("AERO_COLLATERAL_VAULT");

        vm.startBroadcast();

        // ════════════════════════════════════════════════════
        // Phase A: Oracle — resolve borrow vaults
        // ════════════════════════════════════════════════════
        EulerRouter r = EulerRouter(router);
        r.govSetResolvedVault(vvvBorrow,     true);
        r.govSetResolvedVault(usdcBorrow,    true);
        r.govSetResolvedVault(ethBorrow,     true);
        r.govSetResolvedVault(zroBorrow,     true);
        r.govSetResolvedVault(virtualBorrow, true);
        r.govSetResolvedVault(aeroBorrow,    true);

        // ════════════════════════════════════════════════════
        // Phase B: Add borrow vaults as collateral
        // ════════════════════════════════════════════════════

        // ── USDC borrow: accepts all 5 others ──
        IEVault(usdcBorrow).setLTV(ethBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(usdcBorrow).setLTV(vvvBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(usdcBorrow).setLTV(zroBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(usdcBorrow).setLTV(virtualBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(usdcBorrow).setLTV(aeroBorrow,    BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── ETH borrow: accepts all 5 others ──
        IEVault(ethBorrow).setLTV(usdcBorrow,    BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(ethBorrow).setLTV(vvvBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(ethBorrow).setLTV(zroBorrow,     BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(ethBorrow).setLTV(virtualBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(ethBorrow).setLTV(aeroBorrow,    BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── VVV borrow: accepts only USDC + ETH ──
        IEVault(vvvBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(vvvBorrow).setLTV(ethBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── ZRO borrow: accepts only USDC + ETH ──
        IEVault(zroBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(zroBorrow).setLTV(ethBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── VIRTUAL borrow: accepts only USDC + ETH ──
        IEVault(virtualBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(virtualBorrow).setLTV(ethBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);

        // ── AERO borrow: accepts only USDC + ETH ──
        IEVault(aeroBorrow).setLTV(usdcBorrow, BORROW_LTV, LIQUIDATION_LTV, 0);
        IEVault(aeroBorrow).setLTV(ethBorrow,  BORROW_LTV, LIQUIDATION_LTV, 0);

        // ════════════════════════════════════════════════════
        // Phase C: Remove old collateral vault LTVs
        // ════════════════════════════════════════════════════

        // ── USDC borrow: remove old collateral vaults ──
        IEVault(usdcBorrow).setLTV(vvvColl,     0, 0, 0);
        IEVault(usdcBorrow).setLTV(wethColl,    0, 0, 0);
        IEVault(usdcBorrow).setLTV(zroColl,     0, 0, 0);
        IEVault(usdcBorrow).setLTV(virtualColl, 0, 0, 0);
        IEVault(usdcBorrow).setLTV(aeroColl,    0, 0, 0);

        // ── ETH borrow: remove old collateral vaults ──
        IEVault(ethBorrow).setLTV(usdcColl,    0, 0, 0);
        IEVault(ethBorrow).setLTV(vvvColl,     0, 0, 0);
        IEVault(ethBorrow).setLTV(zroColl,     0, 0, 0);
        IEVault(ethBorrow).setLTV(virtualColl, 0, 0, 0);
        IEVault(ethBorrow).setLTV(aeroColl,    0, 0, 0);

        // ── VVV borrow: remove old collateral vaults ──
        IEVault(vvvBorrow).setLTV(usdcColl, 0, 0, 0);
        IEVault(vvvBorrow).setLTV(wethColl, 0, 0, 0);

        // ── ZRO borrow: remove old collateral vaults ──
        IEVault(zroBorrow).setLTV(usdcColl, 0, 0, 0);
        IEVault(zroBorrow).setLTV(wethColl, 0, 0, 0);

        // ── VIRTUAL borrow: remove old collateral vaults ──
        IEVault(virtualBorrow).setLTV(usdcColl, 0, 0, 0);
        IEVault(virtualBorrow).setLTV(wethColl, 0, 0, 0);

        // ── AERO borrow: remove old collateral vaults ──
        IEVault(aeroBorrow).setLTV(usdcColl, 0, 0, 0);
        IEVault(aeroBorrow).setLTV(wethColl, 0, 0, 0);

        vm.stopBroadcast();

        console.log("\n=== STEP 28 COMPLETE: Borrow Vaults Now Serve as Collateral ===");
        console.log("\nOracle resolved (6 borrow vaults):");
        console.log("  VVV:     %s", vvvBorrow);
        console.log("  USDC:    %s", usdcBorrow);
        console.log("  ETH:     %s", ethBorrow);
        console.log("  ZRO:     %s", zroBorrow);
        console.log("  VIRTUAL: %s", virtualBorrow);
        console.log("  AERO:    %s", aeroBorrow);
        console.log("\nLTV added (borrow vault as collateral):");
        console.log("  USDC/ETH borrow: accept VVV, ZRO, VIRTUAL, AERO, and each other");
        console.log("  VVV/ZRO/VIRTUAL/AERO borrow: accept only USDC + ETH");
        console.log("\nLTV removed (old collateral vaults zeroed out):");
        console.log("  USDC coll: %s", usdcColl);
        console.log("  VVV coll:  %s", vvvColl);
        console.log("  WETH coll: %s", wethColl);
        console.log("  ZRO coll:  %s", zroColl);
        console.log("  VIRTUAL coll: %s", virtualColl);
        console.log("  AERO coll:    %s", aeroColl);
        console.log("\nUpdate products.json to remove old collateral vault addresses.");
    }
}
