// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

interface IEVault {
    function setLTV(address collateral, uint16 borrowLTV, uint16 liquidationLTV, uint32 rampDuration) external;
}

/// @title 27_RemoveVolatileVolatileLTV
/// @notice Remove volatile-to-volatile cross-collateral pairs so that:
///         - VVV, ZRO, VIRTUAL, AERO can only be borrowed against USDC or ETH collateral
///         - USDC and ETH keep all collateral types (including each other)
///
/// @dev 12 setLTV calls total — zeroing borrow + liquidation LTV for each pair.
///
///      Matrix after this script:
///      Borrow\Coll  USDC  ETH  VVV  ZRO  VIRTUAL  AERO
///      USDC          -    ✅    ✅   ✅    ✅       ✅
///      ETH          ✅    -     ✅   ✅    ✅       ✅
///      VVV          ✅   ✅     -    ❌    ❌       ❌
///      ZRO          ✅   ✅     ❌   -     ❌       ❌
///      VIRTUAL      ✅   ✅     ❌   ❌    -        ❌
///      AERO         ✅   ✅     ❌   ❌    ❌       -
///
/// @dev Run:
///      source .env && forge script script/27_RemoveVolatileVolatileLTV.s.sol \
///        --rpc-url $RPC_URL_BASE --private-key $PRIVATE_KEY --broadcast
contract RemoveVolatileVolatileLTV is Script {
    function run() external {
        // Borrow vaults (volatile only — USDC/ETH unchanged)
        address vvvBorrow     = vm.envAddress("VVV_BORROW_VAULT");
        address zroBorrow     = vm.envAddress("ZRO_BORROW_VAULT");
        address virtualBorrow = vm.envAddress("VIRTUAL_BORROW_VAULT");
        address aeroBorrow    = vm.envAddress("AERO_BORROW_VAULT");

        // Collateral vaults (volatile only — these are what we're removing)
        address vvvColl     = vm.envAddress("VVV_COLLATERAL_VAULT");
        address zroColl     = vm.envAddress("ZRO_COLLATERAL_VAULT");
        address virtualColl = vm.envAddress("VIRTUAL_COLLATERAL_VAULT");
        address aeroColl    = vm.envAddress("AERO_COLLATERAL_VAULT");

        vm.startBroadcast();

        // ── VVV borrow: remove ZRO, VIRTUAL, AERO collateral ──
        IEVault(vvvBorrow).setLTV(zroColl,     0, 0, 0);
        IEVault(vvvBorrow).setLTV(virtualColl,  0, 0, 0);
        IEVault(vvvBorrow).setLTV(aeroColl,     0, 0, 0);

        // ── ZRO borrow: remove VVV, VIRTUAL, AERO collateral ──
        IEVault(zroBorrow).setLTV(vvvColl,      0, 0, 0);
        IEVault(zroBorrow).setLTV(virtualColl,   0, 0, 0);
        IEVault(zroBorrow).setLTV(aeroColl,      0, 0, 0);

        // ── VIRTUAL borrow: remove VVV, ZRO, AERO collateral ──
        IEVault(virtualBorrow).setLTV(vvvColl,   0, 0, 0);
        IEVault(virtualBorrow).setLTV(zroColl,    0, 0, 0);
        IEVault(virtualBorrow).setLTV(aeroColl,   0, 0, 0);

        // ── AERO borrow: remove VVV, ZRO, VIRTUAL collateral ──
        IEVault(aeroBorrow).setLTV(vvvColl,      0, 0, 0);
        IEVault(aeroBorrow).setLTV(zroColl,       0, 0, 0);
        IEVault(aeroBorrow).setLTV(virtualColl,   0, 0, 0);

        vm.stopBroadcast();

        console.log("\n=== STEP 27 COMPLETE: Volatile-to-Volatile LTV Removed ===");
        console.log("\nVVV borrow (%s):", vvvBorrow);
        console.log("  Removed: ZRO coll, VIRTUAL coll, AERO coll");
        console.log("  Kept:    USDC coll, WETH coll");
        console.log("\nZRO borrow (%s):", zroBorrow);
        console.log("  Removed: VVV coll, VIRTUAL coll, AERO coll");
        console.log("  Kept:    USDC coll, WETH coll");
        console.log("\nVIRTUAL borrow (%s):", virtualBorrow);
        console.log("  Removed: VVV coll, ZRO coll, AERO coll");
        console.log("  Kept:    USDC coll, WETH coll");
        console.log("\nAERO borrow (%s):", aeroBorrow);
        console.log("  Removed: VVV coll, ZRO coll, VIRTUAL coll");
        console.log("  Kept:    USDC coll, WETH coll");
        console.log("\nUSDC and ETH borrow vaults: UNCHANGED (keep all collateral)");
    }
}
