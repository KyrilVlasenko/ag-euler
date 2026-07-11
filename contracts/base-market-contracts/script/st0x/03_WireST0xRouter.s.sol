// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {EulerRouter} from "euler-price-oracle/EulerRouter.sol";
import {ST0xAddresses} from "./ST0xAddresses.sol";

/// @notice Safe-governed script: wires DIA adapters and resolves ST0x eVaults in the shared router.
contract WireST0xRouter is Script {
    function run() external {
        address spymAdapter = vm.envAddress("ST0X_SPYM_ADAPTER");
        address mstrAdapter = vm.envAddress("ST0X_MSTR_ADAPTER");
        address coinAdapter = vm.envAddress("ST0X_COIN_ADAPTER");
        address spymVault = vm.envAddress("ST0X_SPYM_VAULT");
        address mstrVault = vm.envAddress("ST0X_MSTR_VAULT");
        address coinVault = vm.envAddress("ST0X_COIN_VAULT");

        EulerRouter router = EulerRouter(ST0xAddresses.SHARED_ROUTER);

        vm.startBroadcast();

        router.govSetConfig(ST0xAddresses.WT_SPYM, ST0xAddresses.USD, spymAdapter);
        router.govSetConfig(ST0xAddresses.WT_MSTR, ST0xAddresses.USD, mstrAdapter);
        router.govSetConfig(ST0xAddresses.WT_COIN, ST0xAddresses.USD, coinAdapter);

        router.govSetResolvedVault(spymVault, true);
        router.govSetResolvedVault(mstrVault, true);
        router.govSetResolvedVault(coinVault, true);

        vm.stopBroadcast();

        console.log("Wired ST0x adapters and resolved ST0x vaults on shared router.");
    }
}
