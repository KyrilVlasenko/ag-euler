// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IEVault} from "euler-vault-kit/EVault/IEVault.sol";
import {ST0xAddresses} from "./ST0xAddresses.sol";

interface IEVaultFactory {
    function createProxy(address implementation, bool upgradeable, bytes calldata trailingData)
        external
        returns (address vault);
}

/// @notice Deploys replacement ST0x EVaults as collateral-only markets.
/// @dev Does not deploy or configure IRMs, does not set reverse LTVs, does not activate vaults,
///      and does not transfer governance.
contract DeployST0xCollateralOnlyVaults is Script {
    uint16 internal constant ZERO_CAP = 1;

    uint16 internal constant INTEREST_FEE = 1000;
    uint16 internal constant MAX_LIQUIDATION_DISCOUNT = 1500;
    uint16 internal constant LIQUIDATION_COOL_OFF = 1;

    uint16 internal constant SPYM_SUPPLY_CAP = 10_260;
    uint16 internal constant MSTR_SUPPLY_CAP = 19_219;
    uint16 internal constant COIN_SUPPLY_CAP = 51_219;

    function run() external {
        vm.startBroadcast();

        IEVaultFactory vaultFactory = IEVaultFactory(ST0xAddresses.EVAULT_FACTORY);

        address spymVault = _createVault(vaultFactory, ST0xAddresses.WT_SPYM);
        address mstrVault = _createVault(vaultFactory, ST0xAddresses.WT_MSTR);
        address coinVault = _createVault(vaultFactory, ST0xAddresses.WT_COIN);

        _configureCollateralOnlyVault(spymVault, SPYM_SUPPLY_CAP);
        _configureCollateralOnlyVault(mstrVault, MSTR_SUPPLY_CAP);
        _configureCollateralOnlyVault(coinVault, COIN_SUPPLY_CAP);

        vm.stopBroadcast();

        console.log("=== ST0x collateral-only replacement vaults deployed ===");
        console.log("ST0X_SPYM_COLLATERAL_ONLY_VAULT=%s", spymVault);
        console.log("ST0X_MSTR_COLLATERAL_ONLY_VAULT=%s", mstrVault);
        console.log("ST0X_COIN_COLLATERAL_ONLY_VAULT=%s", coinVault);
        console.log("Governance remains with deployer. Vault operations remain disabled.");
    }

    function _createVault(IEVaultFactory vaultFactory, address asset) internal returns (address) {
        return vaultFactory.createProxy(
            address(0),
            true,
            abi.encodePacked(asset, ST0xAddresses.SHARED_ROUTER, ST0xAddresses.USD)
        );
    }

    function _configureCollateralOnlyVault(address vault, uint16 supplyCap) internal {
        IEVault(vault).setCaps(supplyCap, ZERO_CAP);
        IEVault(vault).setMaxLiquidationDiscount(MAX_LIQUIDATION_DISCOUNT);
        IEVault(vault).setLiquidationCoolOffTime(LIQUIDATION_COOL_OFF);
        IEVault(vault).setInterestFee(INTEREST_FEE);
        IEVault(vault).setFeeReceiver(ST0xAddresses.SAFE_MULTISIG);
    }
}
