// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DIAST0xOracle} from "../src/oracle/DIAST0xOracle.sol";

contract MockToken {
    uint8 public immutable decimals;

    constructor(uint8 _decimals) {
        decimals = _decimals;
    }
}

contract MockDIAOracle {
    uint128 public value;
    uint128 public timestamp;

    function setValue(uint128 _value, uint128 _timestamp) external {
        value = _value;
        timestamp = _timestamp;
    }

    function getValue(string calldata) external view returns (uint128, uint128) {
        return (value, timestamp);
    }
}

contract DIAST0xOracleTest is Test {
    address internal constant USD = address(840);

    MockToken internal token;
    MockDIAOracle internal dia;
    DIAST0xOracle internal adapter;

    function setUp() external {
        vm.warp(1_800_000_000);
        token = new MockToken(18);
        dia = new MockDIAOracle();
        adapter = new DIAST0xOracle(address(token), USD, address(dia), "SPYM", 96 hours);
    }

    function testQuoteForwardAndInverse() external {
        dia.setValue(100e18, uint128(block.timestamp));

        assertEq(adapter.getQuote(1e18, address(token), USD), 100e18);
        assertEq(adapter.getQuote(100e18, USD, address(token)), 1e18);
    }

    function testRevertsOnStalePrice() external {
        dia.setValue(100e18, uint128(block.timestamp - 96 hours - 1));

        vm.expectRevert();
        adapter.getQuote(1e18, address(token), USD);
    }
}
