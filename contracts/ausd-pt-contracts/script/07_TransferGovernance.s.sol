// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {MarketConfig as C} from "../src/MarketConfig.sol";
import {IEVault} from "../src/Interfaces.sol";

contract TransferGovernance is Script {
    address internal constant MULTISIG = 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C;

    function run() external {
        require(block.chainid == C.CHAIN_ID, "wrong chain");

        address[4] memory vaults = [
            vm.envAddress("AUSD_PT_BORROW_VAULT"),
            vm.envAddress("AUSD_PT_COLLATERAL_VAULT"),
            vm.envAddress("EARNAUSD_PT_BORROW_VAULT"),
            vm.envAddress("EARNAUSD_PT_COLLATERAL_VAULT")
        ];

        vm.startBroadcast();
        for (uint256 i; i < vaults.length; ++i) {
            require(IEVault(vaults[i]).governorAdmin() == C.GOVERNOR, "unexpected current governor");
            IEVault(vaults[i]).setGovernorAdmin(MULTISIG);
        }
        vm.stopBroadcast();
    }
}
