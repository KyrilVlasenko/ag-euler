#!/bin/bash
set -e

echo "=== Oracle Keeper Droplet Setup ==="

# Install Node 22
echo "Installing Node.js 22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Create keeper directory
mkdir -p /opt/oracle-keeper
cd /opt/oracle-keeper

# Write .env
cat > .env << 'ENVEOF'
POKE_ADDRESS=0x455587b12e079bd1dAc1a16C7470df8F7Fbe69BC
PRIVATE_KEY=0xbaf11b83b9a92ebe8d72df00685b4401a9926571a428422bcfdf95a391a9cdd0
RPC_URL=https://base-mainnet.g.alchemy.com/v2/L4npEG7kW8B-VtaxLnMPv155ercjCL1-
ENVEOF
chmod 600 .env

# Write package.json
cat > package.json << 'PKGEOF'
{
  "name": "oracle-keeper",
  "version": "1.0.0",
  "scripts": { "poke": "tsx keeper.ts" },
  "dependencies": {
    "tsx": "^4.21.0",
    "viem": "^2.47.4"
  }
}
PKGEOF

# Write keeper.ts
cat > keeper.ts << 'TSEOF'
// Oracle Poke Keeper — Off-chain bot
//
// Checks if any registered Algebra pools have gone stale
// and calls pokeStale() on the OraclePoke contract.

import { createPublicClient, createWalletClient, http, parseAbi } from "viem";
import { base } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const POKE_ADDRESS = process.env.POKE_ADDRESS as `0x${string}`;
const PRIVATE_KEY = process.env.PRIVATE_KEY as `0x${string}`;
const RPC_URL = process.env.RPC_URL || "https://mainnet.base.org";

if (!POKE_ADDRESS || !PRIVATE_KEY) {
  console.error("Set POKE_ADDRESS and PRIVATE_KEY env vars");
  process.exit(1);
}

const POKE_ABI = parseAbi([
  "function getStalePoolIndices() view returns (uint256[])",
  "function pokeStale() returns (uint256)",
  "function poolCount() view returns (uint256)",
]);

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

  const poolCount = await publicClient.readContract({
    address: POKE_ADDRESS,
    abi: POKE_ABI,
    functionName: "poolCount",
  });

  console.log(`[${new Date().toISOString()}] Registered pools: ${poolCount}`);

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
TSEOF

# Install dependencies
echo "Installing npm dependencies..."
npm install

# Test run
echo "Testing keeper..."
source .env && npx tsx keeper.ts

# Set up cron (every 10 minutes)
echo "Setting up cron..."
(crontab -l 2>/dev/null || true; echo '*/10 * * * * cd /opt/oracle-keeper && export $(cat .env | xargs) && /usr/bin/npx tsx keeper.ts >> /var/log/oracle-keeper.log 2>&1') | crontab -

echo ""
echo "=== Setup Complete ==="
echo "Keeper directory: /opt/oracle-keeper"
echo "Cron: every 10 minutes"
echo "Logs: /var/log/oracle-keeper.log"
crontab -l
