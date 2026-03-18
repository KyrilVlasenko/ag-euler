// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {BaseAdapter} from "euler-price-oracle/adapter/BaseAdapter.sol";
import {FullMath} from "@cryptoalgebra/integral-core/contracts/libraries/FullMath.sol";
import {TickMath} from "@cryptoalgebra/integral-core/contracts/libraries/TickMath.sol";

import {IICHIVaultMinimal, IAlgebraPoolMinimal, IVolatilityOracleMinimal} from "./interfaces/IMinimal.sol";
import {LiqAmounts} from "./lib/LiqAmounts.sol";

// ════════════════════════════════════════════════════════════════════════
//  ICHIVaultOracle — TWAP-hardened Euler price adapter for ICHI Vaults
//  on Algebra V3 pools.
//
//  Instead of trusting the vault's own getTotalAmounts() (which reads
//  the pool's live sqrtPriceX96 — flash-loanable), this adapter:
//
//    1. Reads raw position liquidity from the vault
//    2. Fetches a TWAP tick from the Algebra VolatilityOracle plugin
//    3. Recomputes token amounts using the TWAP-derived sqrtPrice
//    4. Adds idle vault balances (real balances, not spot-dependent)
//    5. Prices everything in the quote token using the same TWAP
//
//  The Algebra VolatilityOracle accumulates tick data on every swap for
//  free — no oracle subscription required.
//
//  Deploy one per vault. Register in EulerRouter via govSetConfig().
// ════════════════════════════════════════════════════════════════════════

contract ICHIVaultOracle is BaseAdapter {
    string public constant name = "ICHIVaultOracle";

    address public immutable vault;
    address public immutable pool;
    address public immutable token0;
    address public immutable token1;
    uint8 public immutable token0Decimals;
    uint8 public immutable token1Decimals;
    uint32 public immutable twapPeriod;
    uint32 public immutable maxStaleness;

    error OracleNotInitialized();
    error StaleOracle();
    error InvalidBase();
    error InvalidQuote();
    error ZeroSupply();

    /// @param _vault        ICHI vault address (also the ERC20 share token)
    /// @param _twapPeriod   TWAP lookback in seconds (e.g. 1800 for 30 min)
    /// @param _maxStaleness Max seconds since last oracle write before revert
    constructor(address _vault, uint32 _twapPeriod, uint32 _maxStaleness) {
        require(_vault != address(0), "zero vault");
        require(_twapPeriod > 0, "zero twap");
        require(_maxStaleness >= _twapPeriod, "staleness < twap");

        vault = _vault;
        pool = IICHIVaultMinimal(_vault).pool();
        token0 = IICHIVaultMinimal(_vault).token0();
        token1 = IICHIVaultMinimal(_vault).token1();
        token0Decimals = _getDecimals(token0);
        token1Decimals = _getDecimals(token1);
        twapPeriod = _twapPeriod;
        maxStaleness = _maxStaleness;
    }

    // ── Core pricing ────────────────────────────────────────────────────

    /// @dev Prices `inAmount` of vault shares in terms of `quote`.
    ///      `base` must be the vault share token. `quote` must be token0 or token1.
    function _getQuote(uint256 inAmount, address base, address quote)
        internal
        view
        override
        returns (uint256 outAmount)
    {
        if (base != vault) revert InvalidBase();
        if (quote != token0 && quote != token1) revert InvalidQuote();

        uint256 supply = IERC20(vault).totalSupply();
        if (supply == 0) revert ZeroSupply();

        // 1. Get manipulation-resistant TWAP tick (reverts if stale)
        int24 twapTick = _getTwapTick();
        uint160 twapSqrtX96 = TickMath.getSqrtRatioAtTick(twapTick);

        // 2. Recompute position amounts using TWAP price (not spot)
        (uint256 total0, uint256 total1) = _getTwapTotalAmounts(twapSqrtX96);

        // 3. Denominate total vault value in the quote token
        uint256 totalValueInQuote;
        if (quote == token1) {
            uint256 value0in1 = _quoteAtTick(twapTick, total0, token0, token1);
            totalValueInQuote = value0in1 + total1;
        } else {
            uint256 value1in0 = _quoteAtTick(twapTick, total1, token1, token0);
            totalValueInQuote = total0 + value1in0;
        }

        // 4. Pro-rata for inAmount shares
        outAmount = (totalValueInQuote * inAmount) / supply;
    }

    // ── TWAP-adjusted vault accounting ──────────────────────────────────

    /// @dev Recomputes total vault token amounts using TWAP sqrtPrice
    ///      instead of the live pool sqrtPrice.
    function _getTwapTotalAmounts(uint160 twapSqrtX96)
        internal
        view
        returns (uint256 total0, uint256 total1)
    {
        IICHIVaultMinimal v = IICHIVaultMinimal(vault);

        // Base position
        (uint128 baseLiq,,) = v.getBasePosition();
        if (baseLiq > 0) {
            (uint256 b0, uint256 b1) = LiqAmounts.getAmountsForLiquidity(
                twapSqrtX96,
                TickMath.getSqrtRatioAtTick(v.baseLower()),
                TickMath.getSqrtRatioAtTick(v.baseUpper()),
                baseLiq
            );
            total0 += b0;
            total1 += b1;
        }

        // Limit position
        (uint128 limitLiq,,) = v.getLimitPosition();
        if (limitLiq > 0) {
            (uint256 l0, uint256 l1) = LiqAmounts.getAmountsForLiquidity(
                twapSqrtX96,
                TickMath.getSqrtRatioAtTick(v.limitLower()),
                TickMath.getSqrtRatioAtTick(v.limitUpper()),
                limitLiq
            );
            total0 += l0;
            total1 += l1;
        }

        // Idle balances — real token balances, not spot-dependent
        total0 += IERC20(token0).balanceOf(vault);
        total1 += IERC20(token1).balanceOf(vault);
    }

    // ── TWAP from Algebra VolatilityOracle ──────────────────────────────

    /// @dev Reads the Algebra plugin, computes TWAP tick, enforces staleness.
    function _getTwapTick() internal view returns (int24 twapTick) {
        address plugin = IAlgebraPoolMinimal(pool).plugin();
        IVolatilityOracleMinimal oracle = IVolatilityOracleMinimal(plugin);

        if (!oracle.isInitialized()) revert OracleNotInitialized();

        // Staleness enforcement
        uint32 lastUpdate = oracle.lastTimepointTimestamp();
        if (block.timestamp - lastUpdate > maxStaleness) revert StaleOracle();

        // Fetch tick cumulatives
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = twapPeriod;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives,) = oracle.getTimepoints(secondsAgos);
        int56 delta = tickCumulatives[1] - tickCumulatives[0];

        twapTick = int24(delta / int56(uint56(twapPeriod)));

        // Round toward negative infinity
        if (delta < 0 && (delta % int56(uint56(twapPeriod)) != 0)) {
            twapTick--;
        }
    }

    // ── Price math ──────────────────────────────────────────────────────

    /// @dev Given a tick and base amount, returns equivalent quote amount.
    function _quoteAtTick(int24 tick, uint256 baseAmount, address baseToken, address quoteToken)
        internal
        pure
        returns (uint256 quoteAmount)
    {
        if (baseAmount == 0) return 0;
        require(baseAmount <= type(uint128).max, "amount overflow");

        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, uint128(baseAmount), 1 << 192)
                : FullMath.mulDiv(1 << 192, uint128(baseAmount), ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, uint128(baseAmount), 1 << 128)
                : FullMath.mulDiv(1 << 128, uint128(baseAmount), ratioX128);
        }
    }
}
