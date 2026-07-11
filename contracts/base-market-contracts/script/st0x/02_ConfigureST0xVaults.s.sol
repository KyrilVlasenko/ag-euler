// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import {IEVault} from "euler-vault-kit/EVault/IEVault.sol";
import {ST0xAddresses} from "./ST0xAddresses.sol";

/// @notice Configures deployer-governed settings on the new ST0x vaults.
contract ConfigureST0xVaults is Script {
    uint16 internal constant INTEREST_FEE = 1000;
    uint16 internal constant MAX_LIQUIDATION_DISCOUNT = 1500;
    uint16 internal constant LIQUIDATION_COOL_OFF = 1;

    uint16 internal constant SPYM_LTV = 8000;
    uint16 internal constant SPYM_LLTV = 8500;
    uint16 internal constant VOLATILE_LTV = 7000;
    uint16 internal constant VOLATILE_LLTV = 8000;

    uint16 internal constant SPYM_SUPPLY_CAP = 10_258;
    uint16 internal constant SPYM_BORROW_CAP = 8_978;
    uint16 internal constant MSTR_SUPPLY_CAP = 1_938;
    uint16 internal constant MSTR_BORROW_CAP = 1_938;
    uint16 internal constant COIN_SUPPLY_CAP = 5_138;
    uint16 internal constant COIN_BORROW_CAP = 4_498;

    function run() external {
        address deployer = vm.envAddress("DEPLOYER_ACCOUNT");

        address spymVault = vm.envAddress("ST0X_SPYM_VAULT");
        address mstrVault = vm.envAddress("ST0X_MSTR_VAULT");
        address coinVault = vm.envAddress("ST0X_COIN_VAULT");
        address spymIrm = vm.envAddress("ST0X_SPYM_IRM");
        address mstrIrm = vm.envAddress("ST0X_MSTR_IRM");
        address coinIrm = vm.envAddress("ST0X_COIN_IRM");

        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](21);
        uint256 index;

        index = _addVaultConfig(
            items, index, deployer, spymVault, spymIrm, SPYM_SUPPLY_CAP, SPYM_BORROW_CAP, SPYM_LTV, SPYM_LLTV
        );
        index = _addVaultConfig(
            items,
            index,
            deployer,
            mstrVault,
            mstrIrm,
            MSTR_SUPPLY_CAP,
            MSTR_BORROW_CAP,
            VOLATILE_LTV,
            VOLATILE_LLTV
        );
        index = _addVaultConfig(
            items,
            index,
            deployer,
            coinVault,
            coinIrm,
            COIN_SUPPLY_CAP,
            COIN_BORROW_CAP,
            VOLATILE_LTV,
            VOLATILE_LLTV
        );

        require(index == items.length, "incorrect batch length");

        vm.startBroadcast();
        IEVC(ST0xAddresses.EVC).batch(items);
        vm.stopBroadcast();

        console.log("Configured ST0x vaults. Operations remain disabled until router wiring is live.");
    }

    function _addVaultConfig(
        IEVC.BatchItem[] memory items,
        uint256 index,
        address deployer,
        address vault,
        address irm,
        uint16 supplyCap,
        uint16 borrowCap,
        uint16 borrowLTV,
        uint16 liquidationLTV
    ) internal pure returns (uint256) {
        items[index++] = _item(deployer, vault, abi.encodeCall(IEVault(vault).setInterestRateModel, (irm)));
        items[index++] = _item(deployer, vault, abi.encodeCall(IEVault(vault).setCaps, (supplyCap, borrowCap)));
        items[index++] =
            _item(deployer, vault, abi.encodeCall(IEVault(vault).setMaxLiquidationDiscount, (MAX_LIQUIDATION_DISCOUNT)));
        items[index++] =
            _item(deployer, vault, abi.encodeCall(IEVault(vault).setLiquidationCoolOffTime, (LIQUIDATION_COOL_OFF)));
        items[index++] = _item(deployer, vault, abi.encodeCall(IEVault(vault).setInterestFee, (INTEREST_FEE)));
        items[index++] =
            _item(deployer, vault, abi.encodeCall(IEVault(vault).setFeeReceiver, (ST0xAddresses.SAFE_MULTISIG)));
        items[index++] = _item(
            deployer,
            vault,
            abi.encodeCall(IEVault(vault).setLTV, (ST0xAddresses.EXISTING_USDC_VAULT, borrowLTV, liquidationLTV, 0))
        );

        return index;
    }

    function _item(address deployer, address target, bytes memory data) internal pure returns (IEVC.BatchItem memory) {
        return IEVC.BatchItem({targetContract: target, onBehalfOfAccount: deployer, value: 0, data: data});
    }
}
