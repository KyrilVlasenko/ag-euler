// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {MarketConfig as C} from "../src/MarketConfig.sol";
import {IEVaultFactory} from "../src/Interfaces.sol";

contract DeployVaults is Script {
    function run() external {
        require(block.chainid == C.CHAIN_ID, "wrong chain");

        IEVaultFactory factory = IEVaultFactory(C.EVAULT_FACTORY);
        vm.startBroadcast();
        address ausdPtBorrow = factory.createProxy(
            address(0), true, abi.encodePacked(C.AUSD, C.ROUTER, C.AUSD)
        );
        address ausdPtCollateral = factory.createProxy(
            address(0), true, abi.encodePacked(C.AUSD_PT, address(0), address(0))
        );
        address earnAusdPtBorrow = factory.createProxy(
            address(0), true, abi.encodePacked(C.AUSD, C.ROUTER, C.AUSD)
        );
        address earnAusdPtCollateral = factory.createProxy(
            address(0), true, abi.encodePacked(C.EARNAUSD_PT, address(0), address(0))
        );
        vm.stopBroadcast();

        console.log("AUSD_PT_BORROW_VAULT=%s", ausdPtBorrow);
        console.log("AUSD_PT_COLLATERAL_VAULT=%s", ausdPtCollateral);
        console.log("EARNAUSD_PT_BORROW_VAULT=%s", earnAusdPtBorrow);
        console.log("EARNAUSD_PT_COLLATERAL_VAULT=%s", earnAusdPtCollateral);
    }
}

