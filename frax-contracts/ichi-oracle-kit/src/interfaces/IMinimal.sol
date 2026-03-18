// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IICHIVaultMinimal {
    function pool() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function baseLower() external view returns (int24);
    function baseUpper() external view returns (int24);
    function limitLower() external view returns (int24);
    function limitUpper() external view returns (int24);
    function getBasePosition() external view returns (uint128 liquidity, uint256 amount0, uint256 amount1);
    function getLimitPosition() external view returns (uint128 liquidity, uint256 amount0, uint256 amount1);
}

interface IAlgebraPoolMinimal {
    function plugin() external view returns (address);
    function globalState()
        external
        view
        returns (uint160 sqrtPriceX96, int24 tick, uint16 fee, uint8 pluginConfig, uint16 communityFee, bool unlocked);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IVolatilityOracleMinimal {
    function getTimepoints(uint32[] memory secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint88[] memory volatilityCumulatives);
    function isInitialized() external view returns (bool);
    function lastTimepointTimestamp() external view returns (uint32);
    function timepointIndex() external view returns (uint16);
}
