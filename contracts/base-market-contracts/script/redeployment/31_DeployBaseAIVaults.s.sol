// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {Addresses} from "../Addresses.sol";

interface IEVaultFactory {
    function createProxy(address implementation, bool upgradeable, bytes calldata trailingData)
        external
        returns (address vault);
}

interface IEulerRouter {
    function governor() external view returns (address);
}

/// @notice Deploys the six replacement Base AI vaults with operations left disabled.
contract DeployBaseAIVaults is Script {
    address internal constant NEW_ORACLE_ROUTER = 0x78C68E226437EC334BCfeF969c75D3224d6176d4;
    address internal constant DEPLOYER = 0x8b59FC48E305AFE0934A897F0Cac6cbD3764F3dd;

    function run() external {
        require(IEulerRouter(NEW_ORACLE_ROUTER).governor() == DEPLOYER, "unexpected router governor");

        vm.startBroadcast();

        address usdcVault = _deploy(Addresses.USDC);
        address wethVault = _deploy(Addresses.WETH);
        address vvvVault = _deploy(Addresses.VVV);
        address virtualVault = _deploy(Addresses.VIRTUAL);
        address zroVault = _deploy(Addresses.ZRO);
        address aeroVault = _deploy(Addresses.AERO);

        vm.stopBroadcast();

        console.log("NEW_USDC_VAULT=%s", usdcVault);
        console.log("NEW_WETH_VAULT=%s", wethVault);
        console.log("NEW_VVV_VAULT=%s", vvvVault);
        console.log("NEW_VIRTUAL_VAULT=%s", virtualVault);
        console.log("NEW_ZRO_VAULT=%s", zroVault);
        console.log("NEW_AERO_VAULT=%s", aeroVault);
    }

    function _deploy(address asset) internal returns (address) {
        return IEVaultFactory(Addresses.EVAULT_FACTORY).createProxy(
            address(0), true, abi.encodePacked(asset, NEW_ORACLE_ROUTER, Addresses.USD)
        );
    }
}
