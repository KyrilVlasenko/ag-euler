// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {ChainlinkOracle} from "euler-price-oracle/adapter/chainlink/ChainlinkOracle.sol";

interface IBalancerVault {
    function getPoolTokens(address pool) external view returns (address[] memory);
}

interface IStableLPOracleFactory {
    function create(
        address pool,
        bool shouldUseBlockTimeForOldestFeedUpdate,
        bool shouldRevertIfVaultUnlocked,
        address[] memory feeds
    ) external returns (address oracle);
}

/// @title 14_RedeployOracles
/// @notice Deploy 3 StableLPOracles + 3 ChainlinkOracle adapters for the new BPT pools.
///
/// @dev This script only deploys oracles. It does NOT wire the EulerRouter (govSetConfig)
///      because the deployer is not the router governor. Router wiring is done via Safe
///      in Step 2B of the redeployment plan (govSetConfig + govSetResolvedVault).
///
/// @dev Oracle chain per pool:
///      Balancer StableLPOracle (AggregatorV3Interface, 18-dec BPT price)
///          -> ChainlinkOracle adapter (Euler IPriceOracle)
///              -> EulerRouter.govSetConfig(BPT, borrowAsset, chainlinkAdapter)  [done via Safe]
///
/// @dev All pools use ConstantPriceFeed (1.0) for every token because:
///      - All pools are boosted pools with rate providers on all tokens
///      - Balancer live balances already apply rate conversion to the unit-of-account
///      - Pool2/3 output = BPT priced in WMON; Pool4 output = BPT priced in AUSD
///
/// @dev shouldRevertIfVaultUnlocked = true  -- blocks flash loan manipulation
///      shouldUseBlockTimeForOldestFeedUpdate = true -- updatedAt = block.timestamp always
///      ChainlinkOracle maxStaleness = 72 hours (max allowed; staleness never triggers in practice)
///
/// @dev Run:
///      source .env && forge script redeployment-scripts/14_RedeployOracles.s.sol \
///        --rpc-url $RPC_URL_MONAD --private-key $PRIVATE_KEY \
///        --broadcast --verify
///
/// @dev After running: paste NEW_LP_ORACLE_* and NEW_CHAINLINK_* into .env.
///      The NEW_CHAINLINK_* addresses are needed for Safe tx calldata in Step 2B.
///      Then run 15_RedeployBptAdapter.s.sol.
contract RedeployOracles is Script {
    // Balancer v3 on Monad
    address constant BAL_VAULT                = 0xbA1333333333a1BA1108E8412f11850A5C319bA9;
    address constant STABLE_LP_ORACLE_FACTORY = 0xbC169a08cBdCDB218d91Cd945D29B59F78c96B77;
    address constant CONSTANT_PRICE_FEED      = 0x5DbAd78818D4c8958EfF2d5b95b28385A22113Cd;

    // Correct BPT addresses (Merkl-incentivized pools)
    address constant NEW_POOL2_BPT = 0x02b34a02db24179Ac2D77Ae20AA6215C7153E7f8; // Kintsu wnSMON/wnWMON
    address constant NEW_POOL3_BPT = 0x340Fa62AE58e90473da64b0af622cdd6113106Cb; // Fastlane wnSHMON/wnWMON
    address constant NEW_POOL4_BPT = 0xbddb004A6c393C3F83BCCCF7F07eE9d409b214dE; // wnLOAZND/AZND/wnAUSD

    // Borrow assets (unit of account for each pool pair)
    address constant AUSD = 0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a;
    address constant WMON = 0x3bd359C1119dA7Da1D913D1C4D2B7c461115433A;

    // ChainlinkOracle: max 72 hours (enforced bound). updatedAt = block.timestamp so never stale.
    uint256 constant MAX_STALENESS = 72 hours;

    function run() external {
        vm.startBroadcast();

        // Deploy StableLPOracles
        address lpOracle2 = _deployLPOracle(NEW_POOL2_BPT);
        address lpOracle3 = _deployLPOracle(NEW_POOL3_BPT);
        address lpOracle4 = _deployLPOracle(NEW_POOL4_BPT);

        // Deploy ChainlinkOracle adapters (base=BPT, quote=borrowAsset, feed=StableLPOracle)
        address chainlink2 = address(new ChainlinkOracle(NEW_POOL2_BPT, WMON, lpOracle2, MAX_STALENESS));
        address chainlink3 = address(new ChainlinkOracle(NEW_POOL3_BPT, WMON, lpOracle3, MAX_STALENESS));
        address chainlink4 = address(new ChainlinkOracle(NEW_POOL4_BPT, AUSD, lpOracle4, MAX_STALENESS));

        vm.stopBroadcast();

        console.log("\n=== SCRIPT 14 COMPLETE: Oracles ===");
        console.log("NEW_LP_ORACLE_2=%s  (Kintsu)", lpOracle2);
        console.log("NEW_LP_ORACLE_3=%s  (Fastlane)", lpOracle3);
        console.log("NEW_LP_ORACLE_4=%s  (AZND)", lpOracle4);
        console.log("NEW_CHAINLINK_2=%s  (BPT->WMON)", chainlink2);
        console.log("NEW_CHAINLINK_3=%s  (BPT->WMON)", chainlink3);
        console.log("NEW_CHAINLINK_4=%s  (BPT->AUSD)", chainlink4);
        console.log("\nPaste all six into .env.");
        console.log("Use NEW_CHAINLINK_* addresses for Safe tx calldata in Step 2B:");
        console.log("  govSetConfig(NEW_POOL2_BPT, WMON, NEW_CHAINLINK_2)");
        console.log("  govSetConfig(NEW_POOL3_BPT, WMON, NEW_CHAINLINK_3)");
        console.log("  govSetConfig(NEW_POOL4_BPT, AUSD, NEW_CHAINLINK_4)");
        console.log("  govSetResolvedVault(NEW_POOL2_VAULT, true)");
        console.log("  govSetResolvedVault(NEW_POOL3_VAULT, true)");
        console.log("  govSetResolvedVault(NEW_POOL4_VAULT, true)");
        console.log("\nThen run 15_RedeployBptAdapter.s.sol.");
    }

    /// @dev Builds a feeds[] array of ConstantPriceFeed for every token in the pool
    ///      and calls StableLPOracleFactory.create().
    function _deployLPOracle(address pool) internal returns (address oracle) {
        address[] memory tokens = IBalancerVault(BAL_VAULT).getPoolTokens(pool);
        address[] memory feeds  = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            feeds[i] = CONSTANT_PRICE_FEED;
        }
        oracle = IStableLPOracleFactory(STABLE_LP_ORACLE_FACTORY).create(
            pool,
            true,  // shouldUseBlockTimeForOldestFeedUpdate
            true,  // shouldRevertIfVaultUnlocked
            feeds
        );
    }
}
