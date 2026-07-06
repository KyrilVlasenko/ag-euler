// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {USDatCurveEMAOracle, ICurveEMAPool} from "../src/oracle/USDatCurveEMAOracle.sol";

contract USDatCurveEMAOracleForkTest is Test {
    address internal constant USDAT = 0x23238f20b894f29041f48D88eE91131C395Aaa71;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant CURVE_POOL = 0xF4d0CF32908b2C7f1021339c43Df0F77f06896d7;
    uint256 internal constant EMA_INDEX = 0;
    uint256 internal constant MAX_STALENESS = 90_000;

    USDatCurveEMAOracle internal oracle;

    function setUp() external {
        vm.createSelectFork(vm.envOr("RPC_URL_MAINNET", string("https://ethereum.publicnode.com")));
        oracle = new USDatCurveEMAOracle(USDAT, USDC, CURVE_POOL, EMA_INDEX, MAX_STALENESS);
    }

    function testMetadata() external view {
        assertEq(oracle.name(), "USDatCurveEMAOracle");
        assertEq(oracle.base(), USDAT);
        assertEq(oracle.quote(), USDC);
        assertEq(oracle.pool(), CURVE_POOL);
        assertEq(oracle.emaIndex(), EMA_INDEX);
        assertEq(oracle.maxStaleness(), MAX_STALENESS);
    }

    function testForwardUSDatToUSDCMatchesCurveEMA() external view {
        uint256 inAmount = 1e6;
        uint256 ema = ICurveEMAPool(CURVE_POOL).price_oracle(EMA_INDEX);
        uint256 expected = inAmount * ema / 1e18;

        assertEq(oracle.getQuote(inAmount, USDAT, USDC), expected);
    }

    function testInverseUSDCToUSDatMatchesCurveEMA() external view {
        uint256 inAmount = 1e6;
        uint256 ema = ICurveEMAPool(CURVE_POOL).price_oracle(EMA_INDEX);
        uint256 expected = inAmount * 1e18 / ema;

        assertEq(oracle.getQuote(inAmount, USDC, USDAT), expected);
    }

    function testGetQuotesReturnsSameBidAsk() external view {
        (uint256 bid, uint256 ask) = oracle.getQuotes(1e6, USDAT, USDC);
        assertEq(bid, oracle.getQuote(1e6, USDAT, USDC));
        assertEq(ask, bid);
    }

    function testZeroInputReturnsZero() external view {
        assertEq(oracle.getQuote(0, USDAT, USDC), 0);
    }

    function testUnsupportedPairReverts() external {
        vm.expectRevert();
        oracle.getQuote(1e6, address(0x1234), USDC);
    }

    function testStaleEMAReverts() external {
        uint256 updatedAt = ICurveEMAPool(CURVE_POOL).ma_last_time() >> 128;
        vm.warp(updatedAt + MAX_STALENESS + 1);

        vm.expectRevert();
        oracle.getQuote(1e6, USDAT, USDC);
    }
}
