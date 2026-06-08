// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import {IEVault} from "euler-vault-kit/EVault/IEVault.sol";
import {IPriceOracle} from "euler-price-oracle/interfaces/IPriceOracle.sol";
import {Addresses} from "../Addresses.sol";

interface IEulerRouter {
    function resolvedVaults(address vault) external view returns (address);
}

interface IEVaultFactory {
    function isProxy(address proxy) external view returns (bool);
}

/// @notice Verifies router resolution and atomically configures the six-vault LTV matrix.
contract ConfigureBaseAILTVs is Script {
    address internal constant NEW_ORACLE_ROUTER = 0x78C68E226437EC334BCfeF969c75D3224d6176d4;
    address internal constant DEPLOYER = 0x8b59FC48E305AFE0934A897F0Cac6cbD3764F3dd;
    address internal constant FINAL_GOVERNOR = 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C;

    address internal constant USDC_IRM = 0x8b304DEBB377Fb620A7A1f30373fbc0Bced92235;
    address internal constant WETH_IRM = 0xDCB187e27B17De035051377Cd388D80681BA724a;
    address internal constant VVV_IRM = 0xa54a6D20FAdDC6D014D1782085cD46A999FBfeC6;
    address internal constant VIRTUAL_IRM = 0x1633Bbf9e830B9D8857ec585F72b725edbf76394;
    address internal constant ZRO_IRM = 0xB270276C558e28c082CC9d68c76EFc3B15584336;
    address internal constant AERO_IRM = 0x944D26f3Fa9D642B5570CCa5583466a80aa7Ce6F;

    uint16 internal constant BLUE_CHIP_LTV = 8700;
    uint16 internal constant BLUE_CHIP_LLTV = 9000;
    uint16 internal constant VOLATILE_LTV = 8000;
    uint16 internal constant VOLATILE_LLTV = 8500;
    uint16 internal constant BLUE_CHIP_LIQ_DISCOUNT = 1000;
    uint16 internal constant VOLATILE_LIQ_DISCOUNT = 1500;
    uint16 internal constant LIQUIDATION_COOL_OFF = 1;
    uint16 internal constant INTEREST_FEE = 1000;
    uint32 internal constant INITIAL_HOOKED_OPS = 32767;

    function run() external {
        address[6] memory vaults = [
            vm.envAddress("NEW_USDC_VAULT"),
            vm.envAddress("NEW_WETH_VAULT"),
            vm.envAddress("NEW_VVV_VAULT"),
            vm.envAddress("NEW_VIRTUAL_VAULT"),
            vm.envAddress("NEW_ZRO_VAULT"),
            vm.envAddress("NEW_AERO_VAULT")
        ];
        address[6] memory assets =
            [Addresses.USDC, Addresses.WETH, Addresses.VVV, Addresses.VIRTUAL, Addresses.ZRO, Addresses.AERO];
        address[6] memory irms = [USDC_IRM, WETH_IRM, VVV_IRM, VIRTUAL_IRM, ZRO_IRM, AERO_IRM];
        uint16[6] memory supplyCaps = [uint16(79), 3542, 2136, 2137, 2840, 986];
        uint16[6] memory borrowCaps = [uint16(79), 3542, 1112, 14424, 1752, 986];
        uint16[6] memory liquidationDiscounts = [
            BLUE_CHIP_LIQ_DISCOUNT,
            BLUE_CHIP_LIQ_DISCOUNT,
            VOLATILE_LIQ_DISCOUNT,
            VOLATILE_LIQ_DISCOUNT,
            VOLATILE_LIQ_DISCOUNT,
            VOLATILE_LIQ_DISCOUNT
        ];
        uint256[6] memory quoteAmounts = [uint256(1e6), 1e18, 1e18, 1e18, 1e18, 1e18];

        IEulerRouter router = IEulerRouter(NEW_ORACLE_ROUTER);
        IEVaultFactory factory = IEVaultFactory(Addresses.EVAULT_FACTORY);

        for (uint256 i; i < vaults.length; ++i) {
            _verifyVault(
                factory,
                router,
                vaults[i],
                assets[i],
                irms[i],
                supplyCaps[i],
                borrowCaps[i],
                liquidationDiscounts[i],
                quoteAmounts[i]
            );
        }

        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](18);
        uint256 index;

        index = _addLtv(items, index, vaults[0], vaults[1], BLUE_CHIP_LTV, BLUE_CHIP_LLTV);
        index = _addLtv(items, index, vaults[1], vaults[0], BLUE_CHIP_LTV, BLUE_CHIP_LLTV);

        index = _addLtv(items, index, vaults[0], vaults[2], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[0], vaults[3], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[0], vaults[4], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[0], vaults[5], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[1], vaults[2], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[1], vaults[3], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[1], vaults[4], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[1], vaults[5], VOLATILE_LTV, VOLATILE_LLTV);

        index = _addLtv(items, index, vaults[2], vaults[0], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[2], vaults[1], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[3], vaults[0], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[3], vaults[1], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[4], vaults[0], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[4], vaults[1], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[5], vaults[0], VOLATILE_LTV, VOLATILE_LLTV);
        index = _addLtv(items, index, vaults[5], vaults[1], VOLATILE_LTV, VOLATILE_LLTV);

        require(index == items.length, "incorrect batch length");

        vm.startBroadcast();
        IEVC(Addresses.EVC).batch(items);
        vm.stopBroadcast();

        console.log("Configured LTVs on six Base AI vaults.");
        console.log("Operations remain disabled and governance remains with %s", DEPLOYER);
    }

    function _verifyVault(
        IEVaultFactory factory,
        IEulerRouter router,
        address vaultAddress,
        address asset,
        address irm,
        uint16 expectedSupplyCap,
        uint16 expectedBorrowCap,
        uint16 expectedLiquidationDiscount,
        uint256 quoteAmount
    ) internal view {
        IEVault vault = IEVault(vaultAddress);
        require(factory.isProxy(vaultAddress), "vault not registered by factory");
        require(vault.asset() == asset, "incorrect vault asset");
        require(vault.oracle() == NEW_ORACLE_ROUTER, "incorrect vault oracle");
        require(vault.unitOfAccount() == Addresses.USD, "incorrect unit of account");
        require(vault.governorAdmin() == DEPLOYER, "unexpected vault governor");
        require(router.resolvedVaults(vaultAddress) == asset, "vault not resolved in router");
        require(vault.interestRateModel() == irm, "incorrect IRM");
        (uint16 supplyCap, uint16 borrowCap) = vault.caps();
        require(supplyCap == expectedSupplyCap, "incorrect supply cap");
        require(borrowCap == expectedBorrowCap, "incorrect borrow cap");
        require(vault.maxLiquidationDiscount() == expectedLiquidationDiscount, "incorrect liquidation discount");
        require(vault.liquidationCoolOffTime() == LIQUIDATION_COOL_OFF, "incorrect liquidation cool-off");
        require(vault.interestFee() == INTEREST_FEE, "incorrect interest fee");
        require(vault.feeReceiver() == FINAL_GOVERNOR, "incorrect fee receiver");
        (address hookTarget, uint32 hookedOps) = vault.hookConfig();
        require(hookTarget == address(0), "unexpected hook target");
        require(hookedOps == INITIAL_HOOKED_OPS, "vault already activated");

        IPriceOracle(NEW_ORACLE_ROUTER).getQuote(quoteAmount, vaultAddress, Addresses.USD);
    }

    function _addLtv(
        IEVC.BatchItem[] memory items,
        uint256 index,
        address borrowVault,
        address collateralVault,
        uint16 borrowLtv,
        uint16 liquidationLtv
    ) internal pure returns (uint256) {
        items[index++] = _item(
            borrowVault,
            abi.encodeCall(IEVault(borrowVault).setLTV, (collateralVault, borrowLtv, liquidationLtv, 0))
        );
        return index;
    }

    function _item(address target, bytes memory data) internal pure returns (IEVC.BatchItem memory) {
        return IEVC.BatchItem({
            targetContract: target,
            onBehalfOfAccount: DEPLOYER,
            value: 0,
            data: data
        });
    }
}
