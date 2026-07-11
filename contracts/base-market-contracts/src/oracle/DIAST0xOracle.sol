// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import {BaseAdapter, Errors, IPriceOracle} from "euler-price-oracle/adapter/BaseAdapter.sol";
import {ScaleUtils, Scale} from "euler-price-oracle/lib/ScaleUtils.sol";

interface IDIAOracle {
    function getValue(string calldata key) external view returns (uint128 value, uint128 timestamp);
}

/// @title DIAST0xOracle
/// @notice Euler price oracle adapter for ST0x tokenized-stock feeds published by DIA.
contract DIAST0xOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "DIAST0xOracle";

    uint256 internal constant MAX_STALENESS_LOWER_BOUND = 1 minutes;
    uint256 internal constant MAX_STALENESS_UPPER_BOUND = 7 days;
    uint8 internal constant DIA_DECIMALS = 18;

    address public immutable base;
    address public immutable quote;
    address public immutable diaOracle;
    string public key;
    uint256 public immutable maxStaleness;

    Scale internal immutable scale;

    constructor(address _base, address _quote, address _diaOracle, string memory _key, uint256 _maxStaleness) {
        if (
            _base == address(0) || _quote == address(0) || _diaOracle == address(0)
                || bytes(_key).length == 0 || _maxStaleness < MAX_STALENESS_LOWER_BOUND
                || _maxStaleness > MAX_STALENESS_UPPER_BOUND
        ) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        base = _base;
        quote = _quote;
        diaOracle = _diaOracle;
        key = _key;
        maxStaleness = _maxStaleness;

        scale = ScaleUtils.calcScale(_getDecimals(_base), _getDecimals(_quote), DIA_DECIMALS);
    }

    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        (uint128 value, uint128 timestamp) = IDIAOracle(diaOracle).getValue(key);
        if (value == 0 || timestamp == 0 || timestamp > block.timestamp) {
            revert Errors.PriceOracle_InvalidAnswer();
        }

        uint256 staleness = block.timestamp - uint256(timestamp);
        if (staleness > maxStaleness) revert Errors.PriceOracle_TooStale(staleness, maxStaleness);

        return ScaleUtils.calcOutAmount(inAmount, uint256(value), scale, inverse);
    }
}
