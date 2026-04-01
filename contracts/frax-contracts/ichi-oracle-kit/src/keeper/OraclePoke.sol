// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IAlgebraPoolMinimal, IVolatilityOracleMinimal} from "../interfaces/IMinimal.sol";

/// @title OraclePoke
/// @notice Keeps Algebra VolatilityOracle timepoints fresh by executing
///         dust-sized swaps when pools go stale. One contract covers all pools.
/// @dev The keeper (off-chain bot) calls `pokeStale()` periodically.
///      The contract holds small token balances for dust swaps.
///      On Base, each poke costs fractions of a cent in gas.
contract OraclePoke {
    struct PoolConfig {
        address pool;
        address token0;
        address token1;
        uint32 stalenessThreshold; // seconds before we consider it stale
        bool active;
    }

    address public owner;
    PoolConfig[] public pools;

    event PoolAdded(uint256 indexed index, address pool, uint32 stalenessThreshold);
    event PoolRemoved(uint256 indexed index, address pool);
    event Poked(address indexed pool, uint32 staleDuration);
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);

    error NotOwner();
    error SwapFailed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ── Pool management ─────────────────────────────────────────────────

    /// @notice Register a pool for oracle keepalive.
    /// @param pool               Algebra pool address
    /// @param stalenessThreshold Seconds of inactivity before poking
    function addPool(address pool, uint32 stalenessThreshold) external onlyOwner {
        address t0 = IAlgebraPoolMinimal(pool).token0();
        address t1 = IAlgebraPoolMinimal(pool).token1();

        pools.push(PoolConfig({
            pool: pool,
            token0: t0,
            token1: t1,
            stalenessThreshold: stalenessThreshold,
            active: true
        }));

        // Pre-approve pool to spend dust
        IERC20(t0).approve(pool, type(uint256).max);
        IERC20(t1).approve(pool, type(uint256).max);

        emit PoolAdded(pools.length - 1, pool, stalenessThreshold);
    }

    /// @notice Deactivate a pool (doesn't delete to preserve indices).
    function removePool(uint256 index) external onlyOwner {
        pools[index].active = false;
        emit PoolRemoved(index, pools[index].pool);
    }

    // ── Poke logic ──────────────────────────────────────────────────────

    /// @notice Check all pools and poke any that are stale.
    /// @return pokedCount Number of pools that were poked.
    function pokeStale() external returns (uint256 pokedCount) {
        uint256 len = pools.length;
        for (uint256 i; i < len;) {
            if (pools[i].active && _isStale(i)) {
                _poke(i);
                pokedCount++;
            }
            unchecked { ++i; }
        }
    }

    /// @notice Poke a specific pool by index (for targeted keepalive).
    function pokeSingle(uint256 index) external {
        require(pools[index].active, "inactive");
        _poke(index);
    }

    /// @notice Check which pools are currently stale (view for off-chain).
    /// @return staleIndices Array of pool indices that need poking.
    function getStalePoolIndices() external view returns (uint256[] memory staleIndices) {
        uint256 len = pools.length;
        uint256 count;

        // First pass: count stale
        for (uint256 i; i < len;) {
            if (pools[i].active && _isStale(i)) count++;
            unchecked { ++i; }
        }

        // Second pass: collect indices
        staleIndices = new uint256[](count);
        uint256 idx;
        for (uint256 i; i < len;) {
            if (pools[i].active && _isStale(i)) {
                staleIndices[idx++] = i;
            }
            unchecked { ++i; }
        }
    }

    // ── Internal ────────────────────────────────────────────────────────

    function _isStale(uint256 index) internal view returns (bool) {
        PoolConfig memory cfg = pools[index];
        address plugin = IAlgebraPoolMinimal(cfg.pool).plugin();

        IVolatilityOracleMinimal oracle = IVolatilityOracleMinimal(plugin);
        if (!oracle.isInitialized()) return true;

        uint32 lastUpdate = oracle.lastTimepointTimestamp();
        return (block.timestamp - lastUpdate) > cfg.stalenessThreshold;
    }

    /// @dev Execute a dust swap (1 wei of token0 → token1) to trigger
    ///      the Algebra plugin's BEFORE_SWAP_FLAG, which writes a new timepoint.
    function _poke(uint256 index) internal {
        PoolConfig memory cfg = pools[index];

        // Determine which token we have balance for
        uint256 bal0 = IERC20(cfg.token0).balanceOf(address(this));
        uint256 bal1 = IERC20(cfg.token1).balanceOf(address(this));

        bool zeroToOne = bal0 > 0;
        if (!zeroToOne && bal1 == 0) return; // no dust to swap with

        // Dust swap: 1 wei, no price limit enforcement
        // The swap will likely return 0 output but still writes the timepoint
        uint160 sqrtPriceLimit = zeroToOne
            ? 4295128740          // MIN_SQRT_RATIO + 1
            : 1461446703485210103287273052203988822378723970341; // MAX_SQRT_RATIO - 1

        // Use try/catch — if the swap reverts (e.g., pool locked, zero liquidity)
        // we skip silently. The staleness check will catch it next round.
        try IAlgebraPoolSwap(cfg.pool).swap(
            address(this), // recipient
            zeroToOne,
            int256(1),     // 1 wei exact input
            sqrtPriceLimit,
            abi.encode(address(this))
        ) {
            uint32 staleDuration = uint32(block.timestamp) - IVolatilityOracleMinimal(
                IAlgebraPoolMinimal(cfg.pool).plugin()
            ).lastTimepointTimestamp();
            emit Poked(cfg.pool, staleDuration);
        } catch {
            // Pool might be locked or have zero liquidity — skip
        }
    }

    // ── Algebra swap callback ───────────────────────────────────────────

    /// @dev Required for Algebra pool to pull tokens during swap.
    function algebraSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        // Only pay positive deltas (tokens owed to pool)
        if (amount0Delta > 0) {
            // Find which pool called us
            IERC20(_getToken0(msg.sender)).transfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20(_getToken1(msg.sender)).transfer(msg.sender, uint256(amount1Delta));
        }
    }

    function _getToken0(address pool) internal view returns (address) {
        return IAlgebraPoolMinimal(pool).token0();
    }

    function _getToken1(address pool) internal view returns (address) {
        return IAlgebraPoolMinimal(pool).token1();
    }

    // ── Admin ───────────────────────────────────────────────────────────

    /// @notice Withdraw tokens from the contract (dust management).
    function withdraw(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /// @notice Deposit dust tokens for poke swaps.
    /// @dev Just transfer tokens to this contract address. This function
    ///      exists for discoverability.
    function deposit(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnerTransferred(owner, newOwner);
        owner = newOwner;
    }

    function poolCount() external view returns (uint256) {
        return pools.length;
    }
}

/// @dev Minimal swap interface — separate to avoid import bloat
interface IAlgebraPoolSwap {
    function swap(
        address recipient,
        bool zeroToOne,
        int256 amountRequired,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}
