// Oracle Poke Keeper — Off-chain bot
//
// Periodically checks if any registered Algebra pools have gone stale
// and calls pokeStale() on the OraclePoke contract to refresh their
// VolatilityOracle timepoints.
//
// Run: PRIVATE_KEY=0x... POKE_ADDRESS=0x... npx ts-node keeper.ts
//
// Or via cron (every 10 minutes):
//   crontab: */10 * * * * cd /path/to/keeper && npx ts-node keeper.ts
//
// On Base, each poke tx costs ~0.0001 ETH.

import { createPublicClient, createWalletClient, http, parseAbi } from "viem";
import { base } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

// ── Config ──────────────────────────────────────────────────────────────

const POKE_ADDRESS = process.env.POKE_ADDRESS as `0x${string}`;
const PRIVATE_KEY = process.env.PRIVATE_KEY as `0x${string}`;
const RPC_URL = process.env.RPC_URL || "https://mainnet.base.org";

if (!POKE_ADDRESS || !PRIVATE_KEY) {
  console.error("Set POKE_ADDRESS and PRIVATE_KEY env vars");
  process.exit(1);
}

// ── ABI (minimal) ───────────────────────────────────────────────────────

const POKE_ABI = parseAbi([
  "function getStalePoolIndices() view returns (uint256[])",
  "function pokeStale() returns (uint256)",
  "function poolCount() view returns (uint256)",
]);

// ── Main ────────────────────────────────────────────────────────────────

async function main() {
  const account = privateKeyToAccount(PRIVATE_KEY);

  const publicClient = createPublicClient({
    chain: base,
    transport: http(RPC_URL),
  });

  const walletClient = createWalletClient({
    account,
    chain: base,
    transport: http(RPC_URL),
  });

  // Check how many pools are registered
  const poolCount = await publicClient.readContract({
    address: POKE_ADDRESS,
    abi: POKE_ABI,
    functionName: "poolCount",
  });

  console.log(`[${new Date().toISOString()}] Registered pools: ${poolCount}`);

  // Check which are stale
  const staleIndices = await publicClient.readContract({
    address: POKE_ADDRESS,
    abi: POKE_ABI,
    functionName: "getStalePoolIndices",
  });

  if (staleIndices.length === 0) {
    console.log("No stale pools. Exiting.");
    return;
  }

  console.log(`Stale pools: ${staleIndices.length} — indices: [${staleIndices.join(", ")}]`);

  // Poke all stale pools in one tx
  // Explicit gas limit required — KRWQ pool's beforeSwap hook + community vault
  // transfer causes default gas estimation to be too tight, leading to silent OOG
  // inside the try/catch.
  const hash = await walletClient.writeContract({
    address: POKE_ADDRESS,
    abi: POKE_ABI,
    functionName: "pokeStale",
    gas: 500_000n,
  });

  console.log(`Poke tx submitted: ${hash}`);

  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  console.log(
    `Poke confirmed in block ${receipt.blockNumber} — gas used: ${receipt.gasUsed}`
  );
}

main().catch((err) => {
  console.error("Keeper error:", err);
  process.exit(1);
});
