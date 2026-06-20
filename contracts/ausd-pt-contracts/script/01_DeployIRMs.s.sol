// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {MarketConfig as C} from "../src/MarketConfig.sol";
import {IKinkIRMFactory} from "../src/Interfaces.sol";

contract DeployIRMs is Script {
    function run() external {
        require(block.chainid == C.CHAIN_ID, "wrong chain");

        vm.startBroadcast();
        address ausdPtIrm = IKinkIRMFactory(C.KINK_IRM_FACTORY).deploy(
            C.AUSD_PT_IRM_BASE, C.AUSD_PT_IRM_SLOPE1, C.AUSD_PT_IRM_SLOPE2, C.AUSD_PT_IRM_KINK
        );
        address earnAusdPtIrm = IKinkIRMFactory(C.KINK_IRM_FACTORY).deploy(
            C.EARNAUSD_PT_IRM_BASE,
            C.EARNAUSD_PT_IRM_SLOPE1,
            C.EARNAUSD_PT_IRM_SLOPE2,
            C.EARNAUSD_PT_IRM_KINK
        );
        vm.stopBroadcast();

        console.log("AUSD_PT_IRM=%s", ausdPtIrm);
        console.log("EARNAUSD_PT_IRM=%s", earnAusdPtIrm);
    }
}

