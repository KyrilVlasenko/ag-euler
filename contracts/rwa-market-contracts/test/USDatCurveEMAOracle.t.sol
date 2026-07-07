// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {USDatCurveEMAOracle} from "../src/oracle/USDatCurveEMAOracle.sol";

contract MockERC20Decimals {
    uint8 public immutable decimals;

    constructor(uint8 _decimals) {
        decimals = _decimals;
    }
}

contract MockCurveEMAPool {
    address public immutable coin0;
    address public immutable coin1;

    uint256 public price;
    uint256 public maLastTime;

    constructor(address _coin0, address _coin1) {
        coin0 = _coin0;
        coin1 = _coin1;
    }

    function coins(uint256 i) external view returns (address) {
        if (i == 0) return coin0;
        if (i == 1) return coin1;
        revert();
    }

    function price_oracle(uint256 i) external view returns (uint256) {
        if (i != 0) revert();
        return price;
    }

    function ma_last_time() external view returns (uint256) {
        return maLastTime;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function setMaLastTime(uint256 priceTime, uint256 dTime) external {
        maLastTime = priceTime | (dTime << 128);
    }
}

contract USDatCurveEMAOracleTest is Test {
    uint256 internal constant MAX_STALENESS = 90_000;

    MockERC20Decimals internal usdat;
    MockERC20Decimals internal usdc;
    MockCurveEMAPool internal pool;
    USDatCurveEMAOracle internal oracle;

    function setUp() external {
        usdat = new MockERC20Decimals(6);
        usdc = new MockERC20Decimals(6);
        pool = new MockCurveEMAPool(address(usdc), address(usdat));
        pool.setPrice(1.01e18);

        oracle = new USDatCurveEMAOracle(address(usdat), address(usdc), address(pool), 0, MAX_STALENESS);
    }

    function testConstructorRevertsForInvalidEMAIndex() external {
        vm.expectRevert();
        new USDatCurveEMAOracle(address(usdat), address(usdc), address(pool), 1, MAX_STALENESS);
    }

    function testStalePriceTimestampRevertsEvenWhenDOracleTimestampIsFresh() external {
        uint256 nowTime = 1_000_000;
        uint256 stalePriceTime = nowTime - MAX_STALENESS - 1;
        uint256 freshDTime = nowTime;

        vm.warp(nowTime);
        pool.setMaLastTime(stalePriceTime, freshDTime);

        vm.expectRevert();
        oracle.getQuote(1e6, address(usdat), address(usdc));
    }

    function testFreshPriceTimestampQuotesEvenWhenDOracleTimestampIsStale() external {
        uint256 nowTime = 1_000_000;
        uint256 freshPriceTime = nowTime;
        uint256 staleDTime = nowTime - MAX_STALENESS - 1;

        vm.warp(nowTime);
        pool.setMaLastTime(freshPriceTime, staleDTime);

        assertEq(oracle.getQuote(1e6, address(usdat), address(usdc)), 1_010_000);
    }
}
