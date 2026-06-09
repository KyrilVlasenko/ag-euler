// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import {IEVault} from "euler-vault-kit/EVault/IEVault.sol";
import {Addresses} from "../Addresses.sol";

/// @notice Atomically transfers governance of the six new Base AI vaults to the multisig.
contract TransferBaseAIVaultGovernance is Script {
    address internal constant DEPLOYER = 0x8b59FC48E305AFE0934A897F0Cac6cbD3764F3dd;
    address internal constant MULTISIG = 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C;

    function run() external {
        address[6] memory vaults = [
            vm.envAddress("NEW_USDC_VAULT"),
            vm.envAddress("NEW_WETH_VAULT"),
            vm.envAddress("NEW_VVV_VAULT"),
            vm.envAddress("NEW_VIRTUAL_VAULT"),
            vm.envAddress("NEW_ZRO_VAULT"),
            vm.envAddress("NEW_AERO_VAULT")
        ];

        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](vaults.length);
        for (uint256 i; i < vaults.length; ++i) {
            IEVault vault = IEVault(vaults[i]);
            require(vault.governorAdmin() == DEPLOYER, "unexpected vault governor");
            (address hookTarget, uint32 hookedOps) = vault.hookConfig();
            require(hookTarget == address(0), "unexpected hook target");
            require(hookedOps == 0, "vault not active");

            items[i] = IEVC.BatchItem({
                targetContract: vaults[i],
                onBehalfOfAccount: DEPLOYER,
                value: 0,
                data: abi.encodeCall(vault.setGovernorAdmin, (MULTISIG))
            });
        }

        vm.startBroadcast();
        IEVC(Addresses.EVC).batch(items);
        vm.stopBroadcast();

        console.log("Transferred governance of six Base AI vaults to %s", MULTISIG);
    }
}
