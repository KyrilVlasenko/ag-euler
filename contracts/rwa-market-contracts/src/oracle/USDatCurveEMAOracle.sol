// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {BaseAdapter, Errors, IPriceOracle} from "euler-price-oracle/adapter/BaseAdapter.sol";
import {ScaleUtils} from "euler-price-oracle/lib/ScaleUtils.sol";

interface ICurveEMAPool {
    function coins(uint256 i) external view returns (address);
    function price_oracle(uint256 i) external view returns (uint256);
    function ma_last_time() external view returns (uint256);
}

/// @title USDatCurveEMAOracle
/// @notice Euler oracle adapter that prices USDat in USDC using Curve's EMA oracle.
/// @dev This is only the USDat/USDC leg. Compose it with USDC/USD via Euler's CrossAdapter for USDat/USD.
contract USDatCurveEMAOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "USDatCurveEMAOracle";

    /// @notice USDat token, Curve coin 1.
    address public immutable base;

    /// @notice USDC token, Curve coin 0.
    address public immutable quote;

    /// @notice Curve USDC/USDat pool.
    address public immutable pool;

    /// @notice Curve EMA oracle index for coin 1 priced in coin 0.
    uint256 public immutable emaIndex;

    /// @notice Maximum allowed age for Curve's EMA timestamp.
    uint256 public immutable maxStaleness;

    constructor(address _base, address _quote, address _pool, uint256 _emaIndex, uint256 _maxStaleness) {
        if (_base == address(0) || _quote == address(0) || _pool == address(0) || _maxStaleness == 0) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        if (_getDecimals(_base) != 6 || _getDecimals(_quote) != 6) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        if (ICurveEMAPool(_pool).coins(0) != _quote || ICurveEMAPool(_pool).coins(1) != _base) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        base = _base;
        quote = _quote;
        pool = _pool;
        emaIndex = _emaIndex;
        maxStaleness = _maxStaleness;
    }

    /// @notice Get a quote using Curve's WAD-scaled EMA price.
    /// @param inAmount Native token units. USDat and USDC both use 6 decimals.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);
        if (inAmount == 0) return 0;

        uint256 ema = ICurveEMAPool(pool).price_oracle(emaIndex);
        if (ema == 0) revert Errors.PriceOracle_InvalidAnswer();

        uint256 updatedAt = _maLastTime(emaIndex);
        if (updatedAt == 0 || updatedAt > block.timestamp) revert Errors.PriceOracle_InvalidAnswer();

        uint256 staleness = block.timestamp - updatedAt;
        if (staleness > maxStaleness) revert Errors.PriceOracle_TooStale(staleness, maxStaleness);

        if (inverse) {
            return FixedPointMathLib.fullMulDiv(inAmount, 1e18, ema);
        }

        return FixedPointMathLib.fullMulDiv(inAmount, ema, 1e18);
    }

    function _maLastTime(uint256 index) internal view returns (uint256) {
        uint256 packed = ICurveEMAPool(pool).ma_last_time();
        if (index == 0) return packed >> 128;
        if (index == 1) return uint128(packed);
        revert Errors.PriceOracle_InvalidConfiguration();
    }
}
