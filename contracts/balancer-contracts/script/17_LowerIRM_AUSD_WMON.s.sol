// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";

interface IKinkIRMFactory {
    function deploy(uint256 baseRate, uint256 slope1, uint256 slope2, uint32 kink)
        external returns (address irm);
}

/// @title 17_LowerIRM_AUSD_WMON
/// @notice Lower AUSD + WMON IRM curves to reduce max-utilization stress.
///         AUSD: 10% → 8% at kink, 100% → 80% at max.
///         WMON: 20% → 16% at kink, 100% → 80% at max.
///         Kink unchanged at 93%.
///
/// @dev Governance is now the AG Safe multisig 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C,
///      so this script ONLY deploys the new IRM contracts. The
///      setInterestRateModel(address) call is bundled into a Safe transaction
///      (redeployment-scripts/safe-tx-lower-ausd-wmon-irm.json) and executed
///      separately via the Safe Transaction Builder.
///
/// @dev AUSD IRM: Base=0%, Kink(93%)=8% APY, Max=80% APY
///      node reference/evk-periphery/script/utils/calculate-irm-linear-kink.js borrow 0 8 80 93
///
/// @dev WMON IRM: Base=0%, Kink(93%)=16% APY, Max=80% APY
///      node reference/evk-periphery/script/utils/calculate-irm-linear-kink.js borrow 0 16 80 93
///
/// @dev Run:
///      source .env && forge script script/17_LowerIRM_AUSD_WMON.s.sol \
///        --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
///        --broadcast --gas-estimate-multiplier 400
contract LowerIRM_AUSD_WMON is Script {
    address constant KINK_IRM_FACTORY = 0x05Cccb5d0f1e1D568804453B82453a719Dc53758;

    // AUSD v5: Base=0%, Kink(93%)=8% APY, Max=80% APY
    uint256 constant AUSD_BASE   = 0;
    uint256 constant AUSD_SLOPE1 = 610_566_643;
    uint256 constant AUSD_SLOPE2 = 53_841_818_838;
    uint32  constant AUSD_KINK   = 3_994_319_585;

    // WMON v4: Base=0%, Kink(93%)=16% APY, Max=80% APY
    uint256 constant WMON_BASE   = 0;
    uint256 constant WMON_SLOPE1 = 1_177_482_829;
    uint256 constant WMON_SLOPE2 = 46_309_932_376;
    uint32  constant WMON_KINK   = 3_994_319_585;

    function run() external {
        vm.broadcast();
        address ausdIrm = IKinkIRMFactory(KINK_IRM_FACTORY).deploy(
            AUSD_BASE, AUSD_SLOPE1, AUSD_SLOPE2, AUSD_KINK
        );

        vm.broadcast();
        address wmonIrm = IKinkIRMFactory(KINK_IRM_FACTORY).deploy(
            WMON_BASE, WMON_SLOPE1, WMON_SLOPE2, WMON_KINK
        );

        console.log("\n=== IRM DEPLOY (AUSD v5 + WMON v4) COMPLETE ===");
        console.log("AUSD_KINK_IRM_V5=%s  (8%% at 93%% kink, 80%% max)", ausdIrm);
        console.log("WMON_KINK_IRM_V4=%s  (16%% at 93%% kink, 80%% max)", wmonIrm);
        console.log("\nNext: paste addresses back into the chat so the Safe tx can be generated.");
        console.log("setInterestRateModel will run via the AG Safe multisig, not this script.");
    }
}
