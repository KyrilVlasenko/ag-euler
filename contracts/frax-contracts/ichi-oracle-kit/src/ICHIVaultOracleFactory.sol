// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ICHIVaultOracle} from "./ICHIVaultOracle.sol";

/// @title ICHIVaultOracleFactory
/// @notice Deploys ICHIVaultOracle instances and maintains a registry.
/// @dev One oracle per vault. Permissionless deployment — anyone can create
///      an oracle for a vault, but only the EulerRouter governor decides
///      which oracles are actually used for pricing.
contract ICHIVaultOracleFactory {
    event OracleDeployed(address indexed vault, address indexed oracle, uint32 twapPeriod, uint32 maxStaleness);

    /// @notice vault address => deployed oracle address
    mapping(address => address) public oracles;

    /// @notice All deployed oracle addresses (for enumeration)
    address[] public allOracles;

    /// @notice Deploy a new ICHIVaultOracle for a given vault.
    /// @param vault       The ICHI vault to price
    /// @param twapPeriod  TWAP lookback in seconds
    /// @param maxStaleness Max seconds since last oracle write
    /// @return oracle     The deployed oracle address
    function deploy(address vault, uint32 twapPeriod, uint32 maxStaleness)
        external
        returns (address oracle)
    {
        require(oracles[vault] == address(0), "already deployed");

        oracle = address(new ICHIVaultOracle(vault, twapPeriod, maxStaleness));
        oracles[vault] = oracle;
        allOracles.push(oracle);

        emit OracleDeployed(vault, oracle, twapPeriod, maxStaleness);
    }

    /// @notice Total number of deployed oracles.
    function oracleCount() external view returns (uint256) {
        return allOracles.length;
    }
}
