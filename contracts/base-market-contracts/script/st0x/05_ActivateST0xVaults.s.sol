// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import {IEVault} from "euler-vault-kit/EVault/IEVault.sol";
import {ST0xAddresses} from "./ST0xAddresses.sol";

/// @notice Activates the ST0x vaults after router wiring and LTV configuration are complete.
contract ActivateST0xVaults is Script {
    uint32 internal constant INITIAL_HOOKED_OPS = 32767;

    function run() external {
        address deployer = vm.envAddress("DEPLOYER_ACCOUNT");
        address[3] memory vaults = [
            vm.envAddress("ST0X_SPYM_VAULT"),
            vm.envAddress("ST0X_MSTR_VAULT"),
            vm.envAddress("ST0X_COIN_VAULT")
        ];

        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](3);

        for (uint256 i; i < vaults.length; ++i) {
            IEVault vault = IEVault(vaults[i]);
            require(vault.governorAdmin() == deployer, "unexpected vault governor");
            (address hookTarget, uint32 hookedOps) = vault.hookConfig();
            require(hookTarget == address(0), "unexpected hook target");
            require(hookedOps == INITIAL_HOOKED_OPS, "vault already activated");

            items[i] = IEVC.BatchItem({
                targetContract: vaults[i],
                onBehalfOfAccount: deployer,
                value: 0,
                data: abi.encodeCall(vault.setHookConfig, (address(0), 0))
            });
        }

        vm.startBroadcast();
        IEVC(ST0xAddresses.EVC).batch(items);
        vm.stopBroadcast();

        console.log("Activated ST0x vaults. Governance remains with deployer.");
    }
}
