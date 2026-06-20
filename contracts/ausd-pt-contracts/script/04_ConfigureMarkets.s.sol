// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {MarketConfig as C} from "../src/MarketConfig.sol";
import {IEVault} from "../src/Interfaces.sol";

contract ConfigureMarkets is Script {
    function run() external {
        require(block.chainid == C.CHAIN_ID, "wrong chain");

        address ausdPtIrm = vm.envAddress("AUSD_PT_IRM");
        address earnAusdPtIrm = vm.envAddress("EARNAUSD_PT_IRM");
        IEVault ausdPtBorrow = IEVault(vm.envAddress("AUSD_PT_BORROW_VAULT"));
        IEVault ausdPtCollateral = IEVault(vm.envAddress("AUSD_PT_COLLATERAL_VAULT"));
        IEVault earnAusdPtBorrow = IEVault(vm.envAddress("EARNAUSD_PT_BORROW_VAULT"));
        IEVault earnAusdPtCollateral = IEVault(vm.envAddress("EARNAUSD_PT_COLLATERAL_VAULT"));

        vm.startBroadcast();

        ausdPtBorrow.setInterestRateModel(ausdPtIrm);
        ausdPtBorrow.setMaxLiquidationDiscount(C.MAX_LIQUIDATION_DISCOUNT);
        ausdPtBorrow.setLiquidationCoolOffTime(C.LIQUIDATION_COOL_OFF);
        ausdPtBorrow.setInterestFee(C.INTEREST_FEE);
        ausdPtBorrow.setFeeReceiver(C.FEE_RECEIVER);
        ausdPtBorrow.setCaps(0, 0);
        ausdPtBorrow.setLTV(
            address(ausdPtCollateral), C.AUSD_PT_BORROW_LTV, C.AUSD_PT_LIQUIDATION_LTV, 0
        );
        ausdPtCollateral.setCaps(C.AUSD_PT_SUPPLY_CAP, C.ZERO_CAP);

        earnAusdPtBorrow.setInterestRateModel(earnAusdPtIrm);
        earnAusdPtBorrow.setMaxLiquidationDiscount(C.MAX_LIQUIDATION_DISCOUNT);
        earnAusdPtBorrow.setLiquidationCoolOffTime(C.LIQUIDATION_COOL_OFF);
        earnAusdPtBorrow.setInterestFee(C.INTEREST_FEE);
        earnAusdPtBorrow.setFeeReceiver(C.FEE_RECEIVER);
        earnAusdPtBorrow.setCaps(0, 0);
        earnAusdPtBorrow.setLTV(
            address(earnAusdPtCollateral),
            C.EARNAUSD_PT_BORROW_LTV,
            C.EARNAUSD_PT_LIQUIDATION_LTV,
            0
        );
        earnAusdPtCollateral.setCaps(C.EARNAUSD_PT_SUPPLY_CAP, C.ZERO_CAP);

        vm.stopBroadcast();
    }
}

