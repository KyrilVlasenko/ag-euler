// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {USDatCurveEMAOracle} from "../src/oracle/USDatCurveEMAOracle.sol";

contract DeployUSDatCurveEMAOracle is Script {
    address internal constant USDAT = 0x23238f20b894f29041f48D88eE91131C395Aaa71;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant CURVE_POOL = 0xF4d0CF32908b2C7f1021339c43Df0F77f06896d7;

    uint256 internal constant EMA_INDEX = 0;
    uint256 internal constant MAX_STALENESS = 90_000;

    function run() external {
        vm.startBroadcast();

        USDatCurveEMAOracle oracle =
            new USDatCurveEMAOracle(USDAT, USDC, CURVE_POOL, EMA_INDEX, MAX_STALENESS);

        vm.stopBroadcast();

        console.log("USDAT_CURVE_EMA_ORACLE=%s", address(oracle));
        console.log("base USDat=%s", USDAT);
        console.log("quote USDC=%s", USDC);
        console.log("curve pool=%s", CURVE_POOL);
        console.log("ema index=%s", EMA_INDEX);
        console.log("max staleness=%s", MAX_STALENESS);
    }
}
