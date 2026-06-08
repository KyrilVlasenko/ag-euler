// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import {IEVault} from "euler-vault-kit/EVault/IEVault.sol";
import {Addresses} from "../Addresses.sol";

/// @notice Atomically configures non-oracle-dependent settings on the replacement Base AI vaults.
contract ConfigureBaseAIVaults is Script {
    address internal constant DEPLOYER = 0x8b59FC48E305AFE0934A897F0Cac6cbD3764F3dd;
    address internal constant FEE_RECEIVER = 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C;

    address internal constant USDC_IRM = 0x8b304DEBB377Fb620A7A1f30373fbc0Bced92235;
    address internal constant WETH_IRM = 0xDCB187e27B17De035051377Cd388D80681BA724a;
    address internal constant VVV_IRM = 0xa54a6D20FAdDC6D014D1782085cD46A999FBfeC6;
    address internal constant VIRTUAL_IRM = 0x1633Bbf9e830B9D8857ec585F72b725edbf76394;
    address internal constant ZRO_IRM = 0xB270276C558e28c082CC9d68c76EFc3B15584336;
    address internal constant AERO_IRM = 0x944D26f3Fa9D642B5570CCa5583466a80aa7Ce6F;

    uint16 internal constant USDC_CAP = 79;
    uint16 internal constant WETH_CAP = 3542;
    uint16 internal constant VVV_SUPPLY_CAP = 2136;
    uint16 internal constant VVV_BORROW_CAP = 1112;
    uint16 internal constant VIRTUAL_SUPPLY_CAP = 2137;
    uint16 internal constant VIRTUAL_BORROW_CAP = 14424;
    uint16 internal constant ZRO_SUPPLY_CAP = 2840;
    uint16 internal constant ZRO_BORROW_CAP = 1752;
    uint16 internal constant AERO_CAP = 986;

    uint16 internal constant BLUE_CHIP_LIQ_DISCOUNT = 1000;
    uint16 internal constant VOLATILE_LIQ_DISCOUNT = 1500;
    uint16 internal constant LIQUIDATION_COOL_OFF = 1;
    uint16 internal constant INTEREST_FEE = 1000;

    function run() external {
        address usdcVault = vm.envAddress("NEW_USDC_VAULT");
        address wethVault = vm.envAddress("NEW_WETH_VAULT");
        address vvvVault = vm.envAddress("NEW_VVV_VAULT");
        address virtualVault = vm.envAddress("NEW_VIRTUAL_VAULT");
        address zroVault = vm.envAddress("NEW_ZRO_VAULT");
        address aeroVault = vm.envAddress("NEW_AERO_VAULT");

        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](36);
        uint256 index;

        index = _addVaultConfig(
            items, index, usdcVault, USDC_IRM, USDC_CAP, USDC_CAP, BLUE_CHIP_LIQ_DISCOUNT
        );
        index = _addVaultConfig(
            items, index, wethVault, WETH_IRM, WETH_CAP, WETH_CAP, BLUE_CHIP_LIQ_DISCOUNT
        );
        index = _addVaultConfig(
            items, index, vvvVault, VVV_IRM, VVV_SUPPLY_CAP, VVV_BORROW_CAP, VOLATILE_LIQ_DISCOUNT
        );
        index = _addVaultConfig(
            items,
            index,
            virtualVault,
            VIRTUAL_IRM,
            VIRTUAL_SUPPLY_CAP,
            VIRTUAL_BORROW_CAP,
            VOLATILE_LIQ_DISCOUNT
        );
        index = _addVaultConfig(
            items, index, zroVault, ZRO_IRM, ZRO_SUPPLY_CAP, ZRO_BORROW_CAP, VOLATILE_LIQ_DISCOUNT
        );
        index = _addVaultConfig(
            items, index, aeroVault, AERO_IRM, AERO_CAP, AERO_CAP, VOLATILE_LIQ_DISCOUNT
        );

        require(index == items.length, "incorrect batch length");

        vm.startBroadcast();
        IEVC(Addresses.EVC).batch(items);
        vm.stopBroadcast();

        console.log("Configured non-LTV settings on six Base AI vaults.");
        console.log("LTVs and operations remain disabled pending Oracle Router resolution.");
    }

    function _addVaultConfig(
        IEVC.BatchItem[] memory items,
        uint256 index,
        address vault,
        address irm,
        uint16 supplyCap,
        uint16 borrowCap,
        uint16 maxLiquidationDiscount
    ) internal pure returns (uint256) {
        items[index++] = _item(vault, abi.encodeCall(IEVault(vault).setInterestRateModel, (irm)));
        items[index++] = _item(vault, abi.encodeCall(IEVault(vault).setCaps, (supplyCap, borrowCap)));
        items[index++] =
            _item(vault, abi.encodeCall(IEVault(vault).setMaxLiquidationDiscount, (maxLiquidationDiscount)));
        items[index++] =
            _item(vault, abi.encodeCall(IEVault(vault).setLiquidationCoolOffTime, (LIQUIDATION_COOL_OFF)));
        items[index++] = _item(vault, abi.encodeCall(IEVault(vault).setInterestFee, (INTEREST_FEE)));
        items[index++] = _item(vault, abi.encodeCall(IEVault(vault).setFeeReceiver, (FEE_RECEIVER)));
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
