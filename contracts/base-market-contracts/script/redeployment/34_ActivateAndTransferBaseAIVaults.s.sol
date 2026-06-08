// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {IEVC} from "ethereum-vault-connector/interfaces/IEthereumVaultConnector.sol";
import {IEVault} from "euler-vault-kit/EVault/IEVault.sol";
import {Addresses} from "../Addresses.sol";

/// @notice Activates the fully configured Base AI vaults and transfers governance.
contract ActivateAndTransferBaseAIVaults is Script {
    address internal constant DEPLOYER = 0x8b59FC48E305AFE0934A897F0Cac6cbD3764F3dd;
    address internal constant FINAL_GOVERNOR = 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C;

    uint16 internal constant BLUE_CHIP_LTV = 8700;
    uint16 internal constant BLUE_CHIP_LLTV = 9000;
    uint16 internal constant VOLATILE_LTV = 8000;
    uint16 internal constant VOLATILE_LLTV = 8500;
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

        _verifyLTV(vaults[0], vaults[1], BLUE_CHIP_LTV, BLUE_CHIP_LLTV);
        _verifyLTV(vaults[1], vaults[0], BLUE_CHIP_LTV, BLUE_CHIP_LLTV);

        for (uint256 collateralIndex = 2; collateralIndex < vaults.length; ++collateralIndex) {
            _verifyLTV(vaults[0], vaults[collateralIndex], VOLATILE_LTV, VOLATILE_LLTV);
            _verifyLTV(vaults[1], vaults[collateralIndex], VOLATILE_LTV, VOLATILE_LLTV);
            _verifyLTV(vaults[collateralIndex], vaults[0], VOLATILE_LTV, VOLATILE_LLTV);
            _verifyLTV(vaults[collateralIndex], vaults[1], VOLATILE_LTV, VOLATILE_LLTV);
        }

        IEVC.BatchItem[] memory items = new IEVC.BatchItem[](12);
        uint256 index;
        for (uint256 i; i < vaults.length; ++i) {
            IEVault vault = IEVault(vaults[i]);
            require(vault.governorAdmin() == DEPLOYER, "unexpected vault governor");
            (address hookTarget, uint32 hookedOps) = vault.hookConfig();
            require(hookTarget == address(0), "unexpected hook target");
            require(hookedOps == INITIAL_HOOKED_OPS, "vault already activated");

            items[index++] = _item(vaults[i], abi.encodeCall(vault.setHookConfig, (address(0), 0)));
            items[index++] = _item(vaults[i], abi.encodeCall(vault.setGovernorAdmin, (FINAL_GOVERNOR)));
        }

        vm.startBroadcast();
        IEVC(Addresses.EVC).batch(items);
        vm.stopBroadcast();

        console.log("Activated six Base AI vaults and transferred governance to %s", FINAL_GOVERNOR);
    }

    function _verifyLTV(
        address borrowVault,
        address collateralVault,
        uint16 expectedBorrowLTV,
        uint16 expectedLiquidationLTV
    ) internal view {
        IEVault vault = IEVault(borrowVault);
        require(vault.LTVBorrow(collateralVault) == expectedBorrowLTV, "incorrect borrow LTV");
        require(vault.LTVLiquidation(collateralVault) == expectedLiquidationLTV, "incorrect liquidation LTV");
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
