// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {ICHIVaultOracle} from "../src/ICHIVaultOracle.sol";
import {ICHIVaultOracleFactory} from "../src/ICHIVaultOracleFactory.sol";
import {OraclePoke} from "../src/keeper/OraclePoke.sol";
import {IICHIVaultMinimal} from "../src/interfaces/IMinimal.sol";

/// @notice Deploy the full oracle kit for a single ICHI vault.
/// @dev Usage:
///   forge script script/Deploy.s.sol:DeployKit \
///     --rpc-url base \
///     --broadcast \
///     --verify \
///     -vvvv
contract DeployKit is Script {
    // ── Config (edit these) ─────────────────────────────────────────────

    // frxUSD/BRZ ICHI vault on Hydrex (Base)
    address constant VAULT = 0x80CBb36F48fad69069a3B93989EEE3bAD8f3f103;

    uint32 constant TWAP_PERIOD = 1800;       // 30 minutes
    uint32 constant MAX_STALENESS = 7200;     // 2 hours (exotic pair)
    uint32 constant POKE_THRESHOLD = 1800;    // poke if stale > 30 min

    // ── Deploy ──────────────────────────────────────────────────────────

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // 1. Deploy factory
        ICHIVaultOracleFactory factory = new ICHIVaultOracleFactory();
        console.log("Factory:", address(factory));

        // 2. Deploy oracle for this vault
        address oracle = factory.deploy(VAULT, TWAP_PERIOD, MAX_STALENESS);
        console.log("Oracle:", oracle);

        // 3. Deploy poke keeper
        OraclePoke poke = new OraclePoke();
        console.log("Poke:", address(poke));

        // 4. Register the pool in the poke keeper
        address pool = IICHIVaultMinimal(VAULT).pool();
        poke.addPool(pool, POKE_THRESHOLD);
        console.log("Pool registered:", pool);

        vm.stopBroadcast();

        // ── Post-deploy manual steps ────────────────────────────────────
        console.log("");
        console.log("=== MANUAL STEPS ===");
        console.log("1. Register oracle in EulerRouter:");
        console.log("   eulerRouter.govSetConfig(VAULT, frxUSD, oracle)");
        console.log("");
        console.log("2. Seed poke keeper with dust tokens:");
        console.log("   frxUSD.transfer(poke, 1e18)");
        console.log("   BRZ.transfer(poke, 5e18)");
        console.log("");
        console.log("3. Start keeper cron:");
        console.log("   POKE_ADDRESS=%s PRIVATE_KEY=... npx ts-node keeper.ts", address(poke));
    }
}
