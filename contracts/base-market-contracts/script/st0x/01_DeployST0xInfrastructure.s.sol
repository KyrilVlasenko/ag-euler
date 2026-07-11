// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {DIAST0xOracle} from "../../src/oracle/DIAST0xOracle.sol";
import {ST0xAddresses} from "./ST0xAddresses.sol";

interface IKinkIRMFactory {
    function deploy(uint256 baseRate, uint256 slope1, uint256 slope2, uint32 kink) external returns (address);
}

interface IEVaultFactory {
    function createProxy(address implementation, bool upgradeable, bytes calldata trailingData)
        external
        returns (address vault);
}

/// @notice Deploys DIA adapters, Kink IRMs, and eVault proxies for wtSPYM, wtMSTR, and wtCOIN.
contract DeployST0xInfrastructure is Script {
    uint256 internal constant MAX_STALENESS = 96 hours;

    uint256 internal constant SPYM_IRM_BASE = 0;
    uint256 internal constant SPYM_IRM_SLOPE1 = 630_918_865;
    uint256 internal constant SPYM_IRM_SLOPE2 = 19_147_019_810;
    uint32 internal constant SPYM_IRM_KINK = 3_865_470_566;

    uint256 internal constant VOLATILE_IRM_BASE = 0;
    uint256 internal constant VOLATILE_IRM_SLOPE1 = 2_150_835_820;
    uint256 internal constant VOLATILE_IRM_SLOPE2 = 61_699_293_867;
    uint32 internal constant VOLATILE_IRM_KINK = 3_865_470_566;

    function run() external {
        vm.startBroadcast();

        address spymAdapter = address(new DIAST0xOracle(
            ST0xAddresses.WT_SPYM,
            ST0xAddresses.USD,
            ST0xAddresses.DIA_ORACLE,
            "SPYM",
            MAX_STALENESS
        ));
        address mstrAdapter = address(new DIAST0xOracle(
            ST0xAddresses.WT_MSTR,
            ST0xAddresses.USD,
            ST0xAddresses.DIA_ORACLE,
            "MSTR",
            MAX_STALENESS
        ));
        address coinAdapter = address(new DIAST0xOracle(
            ST0xAddresses.WT_COIN,
            ST0xAddresses.USD,
            ST0xAddresses.DIA_ORACLE,
            "COIN",
            MAX_STALENESS
        ));

        IKinkIRMFactory irmFactory = IKinkIRMFactory(ST0xAddresses.KINK_IRM_FACTORY);
        address spymIrm = irmFactory.deploy(SPYM_IRM_BASE, SPYM_IRM_SLOPE1, SPYM_IRM_SLOPE2, SPYM_IRM_KINK);
        address mstrIrm =
            irmFactory.deploy(VOLATILE_IRM_BASE, VOLATILE_IRM_SLOPE1, VOLATILE_IRM_SLOPE2, VOLATILE_IRM_KINK);
        address coinIrm =
            irmFactory.deploy(VOLATILE_IRM_BASE, VOLATILE_IRM_SLOPE1, VOLATILE_IRM_SLOPE2, VOLATILE_IRM_KINK);

        IEVaultFactory vaultFactory = IEVaultFactory(ST0xAddresses.EVAULT_FACTORY);
        address spymVault = _createVault(vaultFactory, ST0xAddresses.WT_SPYM);
        address mstrVault = _createVault(vaultFactory, ST0xAddresses.WT_MSTR);
        address coinVault = _createVault(vaultFactory, ST0xAddresses.WT_COIN);

        vm.stopBroadcast();

        console.log("=== ST0x infrastructure deployed ===");
        console.log("WT_SPYM=%s", ST0xAddresses.WT_SPYM);
        console.log("WT_MSTR=%s", ST0xAddresses.WT_MSTR);
        console.log("WT_COIN=%s", ST0xAddresses.WT_COIN);
        console.log("ST0X_SPYM_ADAPTER=%s", spymAdapter);
        console.log("ST0X_MSTR_ADAPTER=%s", mstrAdapter);
        console.log("ST0X_COIN_ADAPTER=%s", coinAdapter);
        console.log("ST0X_SPYM_IRM=%s", spymIrm);
        console.log("ST0X_MSTR_IRM=%s", mstrIrm);
        console.log("ST0X_COIN_IRM=%s", coinIrm);
        console.log("ST0X_SPYM_VAULT=%s", spymVault);
        console.log("ST0X_MSTR_VAULT=%s", mstrVault);
        console.log("ST0X_COIN_VAULT=%s", coinVault);
    }

    function _createVault(IEVaultFactory vaultFactory, address asset) internal returns (address) {
        return vaultFactory.createProxy(
            address(0),
            true,
            abi.encodePacked(asset, ST0xAddresses.SHARED_ROUTER, ST0xAddresses.USD)
        );
    }
}
