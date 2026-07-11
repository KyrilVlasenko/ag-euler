// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import {IEVault} from "euler-vault-kit/EVault/IEVault.sol";
import {ST0xAddresses} from "./ST0xAddresses.sol";

/// @notice Safe-governed script: enables wtSPYM, wtMSTR, and wtCOIN vaults as collateral for the existing USDC vault.
contract ConfigureUSDCForST0x is Script {
    uint16 internal constant SPYM_LTV = 8000;
    uint16 internal constant SPYM_LLTV = 8500;
    uint16 internal constant VOLATILE_LTV = 7000;
    uint16 internal constant VOLATILE_LLTV = 8000;

    function run() external {
        address spymVault = vm.envAddress("ST0X_SPYM_VAULT");
        address mstrVault = vm.envAddress("ST0X_MSTR_VAULT");
        address coinVault = vm.envAddress("ST0X_COIN_VAULT");

        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](3);
        items[0] = _item(
            abi.encodeCall(IEVault(ST0xAddresses.EXISTING_USDC_VAULT).setLTV, (spymVault, SPYM_LTV, SPYM_LLTV, 0))
        );
        items[1] = _item(
            abi.encodeCall(IEVault(ST0xAddresses.EXISTING_USDC_VAULT).setLTV, (mstrVault, VOLATILE_LTV, VOLATILE_LLTV, 0))
        );
        items[2] = _item(
            abi.encodeCall(IEVault(ST0xAddresses.EXISTING_USDC_VAULT).setLTV, (coinVault, VOLATILE_LTV, VOLATILE_LLTV, 0))
        );

        vm.startBroadcast();
        IEVC(ST0xAddresses.EVC).batch(items);
        vm.stopBroadcast();

        console.log("Configured existing USDC vault LTVs for ST0x collateral.");
        console.log("Note: this script does not raise the existing USDC vault max liquidation discount.");
    }

    function _item(bytes memory data) internal pure returns (IEVC.BatchItem memory) {
        return IEVC.BatchItem({
            targetContract: ST0xAddresses.EXISTING_USDC_VAULT,
            onBehalfOfAccount: ST0xAddresses.SAFE_MULTISIG,
            value: 0,
            data: data
        });
    }
}
