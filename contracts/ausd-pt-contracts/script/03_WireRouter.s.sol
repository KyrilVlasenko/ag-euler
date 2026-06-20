// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {MarketConfig as C} from "../src/MarketConfig.sol";
import {IEulerRouter, IEulerRouterFactory} from "../src/Interfaces.sol";

contract WireRouter is Script {
    function run() external {
        require(block.chainid == C.CHAIN_ID, "wrong chain");
        address ausdPtCollateral = vm.envAddress("AUSD_PT_COLLATERAL_VAULT");
        address earnAusdPtCollateral = vm.envAddress("EARNAUSD_PT_COLLATERAL_VAULT");
        IEulerRouter router = IEulerRouter(C.ROUTER);

        require(IEulerRouterFactory(C.ORACLE_ROUTER_FACTORY).isValidDeployment(C.ROUTER), "invalid router");
        require(router.governor() == C.GOVERNOR, "unexpected router governor");
        require(
            router.getConfiguredOracle(C.AUSD_PT, C.AUSD) == C.AUSD_PT_ADAPTER,
            "AUSD PT adapter mismatch"
        );
        require(
            router.getConfiguredOracle(C.EARNAUSD_PT, C.AUSD) == C.EARNAUSD_PT_ADAPTER,
            "earnAUSD PT adapter mismatch"
        );

        vm.startBroadcast();
        router.govSetResolvedVault(ausdPtCollateral, true);
        router.govSetResolvedVault(earnAusdPtCollateral, true);
        vm.stopBroadcast();

        require(router.resolvedVaults(ausdPtCollateral) == C.AUSD_PT, "AUSD PT vault unresolved");
        require(
            router.resolvedVaults(earnAusdPtCollateral) == C.EARNAUSD_PT,
            "earnAUSD PT vault unresolved"
        );
    }
}

