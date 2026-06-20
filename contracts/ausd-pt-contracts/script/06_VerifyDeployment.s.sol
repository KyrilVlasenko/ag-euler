// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {MarketConfig as C} from "../src/MarketConfig.sol";
import {
    IKinkIRMFactory,
    IEulerRouter,
    IEVault,
    IIRMLinearKink
} from "../src/Interfaces.sol";

contract VerifyDeployment is Script {
    function run() external view {
        address ausdPtIrm = vm.envAddress("AUSD_PT_IRM");
        address earnAusdPtIrm = vm.envAddress("EARNAUSD_PT_IRM");
        address ausdPtBorrow = vm.envAddress("AUSD_PT_BORROW_VAULT");
        address ausdPtCollateral = vm.envAddress("AUSD_PT_COLLATERAL_VAULT");
        address earnAusdPtBorrow = vm.envAddress("EARNAUSD_PT_BORROW_VAULT");
        address earnAusdPtCollateral = vm.envAddress("EARNAUSD_PT_COLLATERAL_VAULT");

        _verifyIrm(
            ausdPtIrm,
            C.AUSD_PT_IRM_BASE,
            C.AUSD_PT_IRM_SLOPE1,
            C.AUSD_PT_IRM_SLOPE2,
            C.AUSD_PT_IRM_KINK
        );
        _verifyIrm(
            earnAusdPtIrm,
            C.EARNAUSD_PT_IRM_BASE,
            C.EARNAUSD_PT_IRM_SLOPE1,
            C.EARNAUSD_PT_IRM_SLOPE2,
            C.EARNAUSD_PT_IRM_KINK
        );
        _verifyMarket(
            ausdPtBorrow,
            ausdPtCollateral,
            C.AUSD_PT,
            ausdPtIrm,
            C.AUSD_PT_SUPPLY_CAP,
            C.AUSD_PT_BORROW_LTV,
            C.AUSD_PT_LIQUIDATION_LTV
        );
        _verifyMarket(
            earnAusdPtBorrow,
            earnAusdPtCollateral,
            C.EARNAUSD_PT,
            earnAusdPtIrm,
            C.EARNAUSD_PT_SUPPLY_CAP,
            C.EARNAUSD_PT_BORROW_LTV,
            C.EARNAUSD_PT_LIQUIDATION_LTV
        );

        require(IEVault(ausdPtBorrow).LTVBorrow(earnAusdPtCollateral) == 0, "cross LTV enabled");
        require(IEVault(earnAusdPtBorrow).LTVBorrow(ausdPtCollateral) == 0, "cross LTV enabled");

        uint256 q1 = IEulerRouter(C.ROUTER).getQuote(1e6, ausdPtCollateral, C.AUSD);
        uint256 q2 = IEulerRouter(C.ROUTER).getQuote(1e6, earnAusdPtCollateral, C.AUSD);
        require(q1 != 0 && q2 != 0, "vault share quote failed");

        console.log("AUSD_PT_COLLATERAL_QUOTE_1_SHARE=%s", q1);
        console.log("EARNAUSD_PT_COLLATERAL_QUOTE_1_SHARE=%s", q2);
        console.log("DEPLOYMENT_VERIFIED=true");
    }

    function _verifyIrm(address irm, uint256 base, uint256 slope1, uint256 slope2, uint32 kink)
        internal
        view
    {
        require(IKinkIRMFactory(C.KINK_IRM_FACTORY).isValidDeployment(irm), "invalid IRM");
        IIRMLinearKink model = IIRMLinearKink(irm);
        require(model.baseRate() == base, "bad base");
        require(model.slope1() == slope1, "bad slope1");
        require(model.slope2() == slope2, "bad slope2");
        require(model.kink() == kink, "bad kink");
    }

    function _verifyMarket(
        address borrowAddress,
        address collateralAddress,
        address collateralAsset,
        address irm,
        uint16 supplyCap,
        uint16 borrowLtv,
        uint16 liquidationLtv
    ) internal view {
        IEVault borrow = IEVault(borrowAddress);
        IEVault collateral = IEVault(collateralAddress);
        _verifyVaultMetadata(borrow, collateral, collateralAsset);
        _verifyBorrowConfig(borrow, collateralAddress, irm, borrowLtv, liquidationLtv);
        _verifyCollateralConfig(collateral, supplyCap);
        _verifyHooks(borrow, collateral);
        require(IEulerRouter(C.ROUTER).resolvedVaults(collateralAddress) == collateralAsset, "unresolved vault");
    }

    function _verifyVaultMetadata(IEVault borrow, IEVault collateral, address collateralAsset)
        internal
        view
    {
        require(borrow.asset() == C.AUSD, "bad borrow asset");
        require(borrow.oracle() == C.ROUTER, "bad borrow oracle");
        require(borrow.unitOfAccount() == C.AUSD, "bad unit of account");
        require(collateral.asset() == collateralAsset, "bad collateral asset");
        require(borrow.governorAdmin() == C.GOVERNOR, "bad borrow governor");
        require(collateral.governorAdmin() == C.GOVERNOR, "bad collateral governor");
    }

    function _verifyBorrowConfig(
        IEVault borrow,
        address collateralAddress,
        address irm,
        uint16 borrowLtv,
        uint16 liquidationLtv
    ) internal view {
        require(borrow.interestRateModel() == irm, "bad IRM");
        require(borrow.maxLiquidationDiscount() == C.MAX_LIQUIDATION_DISCOUNT, "bad discount");
        require(borrow.liquidationCoolOffTime() == C.LIQUIDATION_COOL_OFF, "bad cooloff");
        require(borrow.interestFee() == C.INTEREST_FEE, "bad fee");
        require(borrow.feeReceiver() == C.FEE_RECEIVER, "bad fee receiver");
        (uint16 borrowSupplyCap, uint16 borrowBorrowCap) = borrow.caps();
        require(borrowSupplyCap == 0 && borrowBorrowCap == 0, "bad AUSD caps");
        require(borrow.LTVBorrow(collateralAddress) == borrowLtv, "bad borrow LTV");
        require(borrow.LTVLiquidation(collateralAddress) == liquidationLtv, "bad liquidation LTV");
        address[] memory list = borrow.LTVList();
        require(list.length == 1 && list[0] == collateralAddress, "market not isolated");
    }

    function _verifyCollateralConfig(IEVault collateral, uint16 supplyCap) internal view {
        (uint16 collateralSupplyCap, uint16 collateralBorrowCap) = collateral.caps();
        require(collateralSupplyCap == supplyCap, "bad PT supply cap");
        require(collateralBorrowCap == C.ZERO_CAP, "bad PT borrow cap");
    }

    function _verifyHooks(IEVault borrow, IEVault collateral) internal view {
        (address borrowHook, uint32 borrowOps) = borrow.hookConfig();
        (address collateralHook, uint32 collateralOps) = collateral.hookConfig();
        require(borrowHook == address(0) && borrowOps == 0, "borrow vault inactive");
        require(collateralHook == address(0) && collateralOps == 0, "collateral vault inactive");
    }
}
