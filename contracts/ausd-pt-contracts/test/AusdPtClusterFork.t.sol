// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {MarketConfig as C} from "../src/MarketConfig.sol";
import {
    IKinkIRMFactory,
    IEVaultFactory,
    IEulerRouter,
    IEVault,
    IEVC,
    IERC20
} from "../src/Interfaces.sol";

contract AusdPtClusterForkTest is Test {
    IEVault internal ausdPtBorrow;
    IEVault internal ausdPtCollateral;
    IEVault internal earnAusdPtBorrow;
    IEVault internal earnAusdPtCollateral;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal lender = makeAddr("lender");
    address internal constant AUSD_HOLDER = 0x438cedcE647491B1d93a73d491eC19A50194c222;
    address internal constant AUSD_PT_HOLDER = 0x6f99CF00ee7290aE78a072Bb6910eF72D1129fE7;
    address internal constant EARNAUSD_PT_HOLDER = 0x475B98c83AEdBfdd0a0aBaA930ec8cb501aC93B1;

    function setUp() external {
        vm.createSelectFork(vm.envString("RPC_URL_MONAD"));

        address ausdPtIrm = IKinkIRMFactory(C.KINK_IRM_FACTORY).deploy(
            C.AUSD_PT_IRM_BASE, C.AUSD_PT_IRM_SLOPE1, C.AUSD_PT_IRM_SLOPE2, C.AUSD_PT_IRM_KINK
        );
        address earnAusdPtIrm = IKinkIRMFactory(C.KINK_IRM_FACTORY).deploy(
            C.EARNAUSD_PT_IRM_BASE,
            C.EARNAUSD_PT_IRM_SLOPE1,
            C.EARNAUSD_PT_IRM_SLOPE2,
            C.EARNAUSD_PT_IRM_KINK
        );

        IEVaultFactory factory = IEVaultFactory(C.EVAULT_FACTORY);
        ausdPtBorrow = IEVault(
            factory.createProxy(address(0), true, abi.encodePacked(C.AUSD, C.ROUTER, C.AUSD))
        );
        ausdPtCollateral = IEVault(
            factory.createProxy(address(0), true, abi.encodePacked(C.AUSD_PT, address(0), address(0)))
        );
        earnAusdPtBorrow = IEVault(
            factory.createProxy(address(0), true, abi.encodePacked(C.AUSD, C.ROUTER, C.AUSD))
        );
        earnAusdPtCollateral = IEVault(
            factory.createProxy(
                address(0), true, abi.encodePacked(C.EARNAUSD_PT, address(0), address(0))
            )
        );

        vm.startPrank(C.GOVERNOR);
        IEulerRouter(C.ROUTER).govSetResolvedVault(address(ausdPtCollateral), true);
        IEulerRouter(C.ROUTER).govSetResolvedVault(address(earnAusdPtCollateral), true);
        vm.stopPrank();

        _configureBorrow(
            ausdPtBorrow,
            ausdPtCollateral,
            ausdPtIrm,
            C.AUSD_PT_BORROW_LTV,
            C.AUSD_PT_LIQUIDATION_LTV
        );
        ausdPtCollateral.setCaps(C.AUSD_PT_SUPPLY_CAP, C.ZERO_CAP);

        _configureBorrow(
            earnAusdPtBorrow,
            earnAusdPtCollateral,
            earnAusdPtIrm,
            C.EARNAUSD_PT_BORROW_LTV,
            C.EARNAUSD_PT_LIQUIDATION_LTV
        );
        earnAusdPtCollateral.setCaps(C.EARNAUSD_PT_SUPPLY_CAP, C.ZERO_CAP);

        ausdPtBorrow.setHookConfig(address(0), 0);
        ausdPtCollateral.setHookConfig(address(0), 0);
        earnAusdPtBorrow.setHookConfig(address(0), 0);
        earnAusdPtCollateral.setHookConfig(address(0), 0);
    }

    function testDepositBorrowRepayWithdraw() external {
        vm.prank(AUSD_HOLDER);
        assertTrue(IERC20(C.AUSD).transfer(lender, 1_000e6));
        vm.startPrank(lender);
        IERC20(C.AUSD).approve(address(ausdPtBorrow), type(uint256).max);
        ausdPtBorrow.deposit(1_000e6, lender);
        vm.stopPrank();

        vm.prank(AUSD_PT_HOLDER);
        assertTrue(IERC20(C.AUSD_PT).transfer(alice, 1_000e6));
        vm.startPrank(alice);
        IERC20(C.AUSD_PT).approve(address(ausdPtCollateral), type(uint256).max);
        ausdPtCollateral.deposit(1_000e6, alice);
        IEVC(C.EVC).enableCollateral(alice, address(ausdPtCollateral));
        IEVC(C.EVC).enableController(alice, address(ausdPtBorrow));
        ausdPtBorrow.borrow(500e6, alice);
        assertEq(IERC20(C.AUSD).balanceOf(alice), 500e6);

        IERC20(C.AUSD).approve(address(ausdPtBorrow), type(uint256).max);
        ausdPtBorrow.repay(500e6, alice);
        IEVC(C.EVC).disableController(alice);
        ausdPtCollateral.withdraw(1_000e6, alice, alice);
        vm.stopPrank();

        assertEq(IERC20(C.AUSD_PT).balanceOf(alice), 1_000e6);
    }

    function testRejectsCrossMarketCollateral() external {
        vm.prank(AUSD_HOLDER);
        assertTrue(IERC20(C.AUSD).transfer(lender, 1_000e6));
        vm.startPrank(lender);
        IERC20(C.AUSD).approve(address(ausdPtBorrow), type(uint256).max);
        ausdPtBorrow.deposit(1_000e6, lender);
        vm.stopPrank();

        vm.prank(EARNAUSD_PT_HOLDER);
        assertTrue(IERC20(C.EARNAUSD_PT).transfer(bob, 1_000e6));
        vm.startPrank(bob);
        IERC20(C.EARNAUSD_PT).approve(address(earnAusdPtCollateral), type(uint256).max);
        earnAusdPtCollateral.deposit(1_000e6, bob);
        IEVC(C.EVC).enableCollateral(bob, address(earnAusdPtCollateral));
        IEVC(C.EVC).enableController(bob, address(ausdPtBorrow));
        vm.expectRevert();
        ausdPtBorrow.borrow(1e6, bob);
        vm.stopPrank();
    }

    function testCapsDecodeExactly() external pure {
        assertEq(_decodeCap(C.AUSD_PT_SUPPLY_CAP), 6_000_000e6);
        assertEq(_decodeCap(C.EARNAUSD_PT_SUPPLY_CAP), 2_500_000e6);
        assertEq(_decodeCap(C.ZERO_CAP), 0);
    }

    function _configureBorrow(
        IEVault borrowVault,
        IEVault collateralVault,
        address irm,
        uint16 borrowLtv,
        uint16 liquidationLtv
    ) internal {
        borrowVault.setInterestRateModel(irm);
        borrowVault.setMaxLiquidationDiscount(C.MAX_LIQUIDATION_DISCOUNT);
        borrowVault.setLiquidationCoolOffTime(C.LIQUIDATION_COOL_OFF);
        borrowVault.setInterestFee(C.INTEREST_FEE);
        borrowVault.setFeeReceiver(C.FEE_RECEIVER);
        borrowVault.setCaps(0, 0);
        borrowVault.setLTV(address(collateralVault), borrowLtv, liquidationLtv, 0);
    }

    function _decodeCap(uint16 raw) internal pure returns (uint256) {
        if (raw == 0) return type(uint256).max;
        return 10 ** (raw & 63) * (raw >> 6) / 100;
    }
}
