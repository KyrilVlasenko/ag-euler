import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const outputDir = fileURLToPath(new URL(".", import.meta.url));

const CHAIN_ID = "8453";
const CREATED_AT = 1780617600000; // 2026-06-04T00:00:00.000Z
const IRM_FACTORY = "0x2d94C898a17f9D8c0bA75010A51cd61BF55b402E";
const MULTISIG = "0x4f894Bfc9481110278C356adE1473eBe2127Fd3C";

const vaults = {
  USDC: "0x21c8c8A56790A2b10370373fAcb94e925fD6a06E",
  WETH: "0x68AAD2c78065E2D28d2B46f6A80c5a813461FFf4",
  VVV: "0x4B6509B06f664eb8c8a4e9072655A4C6cafc1D9C",
  VIRTUAL: "0x3Bd428B28C52f3534CC78075799CA798e4BcE5a8",
  ZRO: "0xCB935d7916B20748e7f14C3B95931b8dcdA2472D",
  AERO: "0xAf5F576396730C212A8C6056A00eaA58123d78B6",
};

const irmDeploymentOrder = [
  {
    asset: "USDC",
    curve: "0/10/120/90",
    predictedAddress: "0x8b304DEBB377Fb620A7A1f30373fbc0Bced92235",
    baseRate: "0",
    slope1: "781343251",
    slope2: "51141157152",
    kink: "3865470566",
  },
  {
    asset: "WETH",
    curve: "0/5/120/90",
    predictedAddress: "0xDCB187e27B17De035051377Cd388D80681BA724a",
    baseRate: "0",
    slope1: "399976852",
    slope2: "54573454741",
    kink: "3865470566",
  },
  {
    asset: "VVV",
    curve: "0/12/120/90",
    predictedAddress: "0xa54a6D20FAdDC6D014D1782085cD46A999FBfeC6",
    baseRate: "0",
    slope1: "929057149",
    slope2: "49811732071",
    kink: "3865470566",
  },
  {
    asset: "VIRTUAL",
    curve: "0/12/120/90",
    predictedAddress: "0x1633Bbf9e830B9D8857ec585F72b725edbf76394",
    baseRate: "0",
    slope1: "929057149",
    slope2: "49811732071",
    kink: "3865470566",
  },
  {
    asset: "ZRO",
    curve: "0/10/120/90",
    predictedAddress: "0xB270276C558e28c082CC9d68c76EFc3B15584336",
    baseRate: "0",
    slope1: "781343251",
    slope2: "51141157152",
    kink: "3865470566",
  },
  {
    asset: "AERO",
    curve: "0/16/120/90",
    predictedAddress: "0x944D26f3Fa9D642B5570CCa5583466a80aa7Ce6F",
    baseRate: "0",
    slope1: "1216732257",
    slope2: "47222656100",
    kink: "3865470566",
  },
];

const caps = {
  USDC: { supplyCap: "79", borrowCap: "79", note: "10,000,000 USDC" },
  WETH: { supplyCap: "3542", borrowCap: "3542", note: "5,500 WETH" },
  VVV: { supplyCap: "2136", borrowCap: "1112", note: "330,000 supply / 170,000 borrow VVV" },
  VIRTUAL: { supplyCap: "2137", borrowCap: "14424", note: "3,300,000 supply / 2,250,000 borrow VIRTUAL" },
  ZRO: { supplyCap: "2840", borrowCap: "1752", note: "440,000 supply / 270,000 borrow ZRO" },
  AERO: { supplyCap: "986", borrowCap: "986", note: "15,000,000 AERO" },
};

const liquidationDiscounts = {
  USDC: "1000",
  WETH: "1000",
  VVV: "1500",
  VIRTUAL: "1500",
  ZRO: "1500",
  AERO: "1500",
};

const ltvUpdates = [
  ["USDC", "WETH", "8700", "9000"],
  ["WETH", "USDC", "8700", "9000"],

  ["USDC", "VVV", "8000", "8500"],
  ["USDC", "VIRTUAL", "8000", "8500"],
  ["USDC", "ZRO", "8000", "8500"],
  ["USDC", "AERO", "8000", "8500"],
  ["WETH", "VVV", "8000", "8500"],
  ["WETH", "VIRTUAL", "8000", "8500"],
  ["WETH", "ZRO", "8000", "8500"],
  ["WETH", "AERO", "8000", "8500"],

  ["VVV", "USDC", "8000", "8500"],
  ["VVV", "WETH", "8000", "8500"],
  ["VIRTUAL", "USDC", "8000", "8500"],
  ["VIRTUAL", "WETH", "8000", "8500"],
  ["ZRO", "USDC", "8000", "8500"],
  ["ZRO", "WETH", "8000", "8500"],
  ["AERO", "USDC", "8000", "8500"],
  ["AERO", "WETH", "8000", "8500"],
];

function tx(to, method, inputs, values) {
  return {
    to,
    value: "0",
    data: null,
    contractMethod: {
      inputs,
      name: method,
      payable: false,
    },
    contractInputsValues: values,
  };
}

const deployInputs = [
  { name: "baseRate", type: "uint256", internalType: "uint256" },
  { name: "slope1", type: "uint256", internalType: "uint256" },
  { name: "slope2", type: "uint256", internalType: "uint256" },
  { name: "kink", type: "uint32", internalType: "uint32" },
];

const setInterestRateModelInputs = [
  { name: "newModel", type: "address", internalType: "address" },
];

const setCapsInputs = [
  { name: "supplyCap", type: "uint16", internalType: "uint16" },
  { name: "borrowCap", type: "uint16", internalType: "uint16" },
];

const setMaxLiquidationDiscountInputs = [
  { name: "discount", type: "uint16", internalType: "uint16" },
];

const setLtvInputs = [
  { name: "collateral", type: "address", internalType: "address" },
  { name: "borrowLTV", type: "uint16", internalType: "uint16" },
  { name: "liquidationLTV", type: "uint16", internalType: "uint16" },
  { name: "rampDuration", type: "uint32", internalType: "uint32" },
];

const deployPayload = {
  version: "1.0",
  chainId: CHAIN_ID,
  createdAt: CREATED_AT,
  meta: {
    name: "Base AI cluster - deploy updated IRMs",
    description:
      "Deploys six Kink IRMs for USDC, WETH, VVV, VIRTUAL, ZRO, and AERO. IMPORTANT: update payload assumes factory nonce 112 before this transaction is executed.",
  },
  transactions: irmDeploymentOrder.map((irm) =>
    tx(IRM_FACTORY, "deploy", deployInputs, {
      baseRate: irm.baseRate,
      slope1: irm.slope1,
      slope2: irm.slope2,
      kink: irm.kink,
    }),
  ),
};

const irmByAsset = Object.fromEntries(irmDeploymentOrder.map((irm) => [irm.asset, irm.predictedAddress]));

const updatePayload = {
  version: "1.0",
  chainId: CHAIN_ID,
  createdAt: CREATED_AT,
  meta: {
    name: "Base AI cluster - update caps, LTVs, discounts, and IRMs",
    description:
      "Applies the June 2026 Base AI market parameters. Execute only after payload 01 has deployed the six expected IRM addresses and verification passes.",
  },
  transactions: [
    ...Object.entries(caps).map(([asset, cap]) =>
      tx(vaults[asset], "setCaps", setCapsInputs, {
        supplyCap: cap.supplyCap,
        borrowCap: cap.borrowCap,
      }),
    ),
    ...Object.entries(liquidationDiscounts).map(([asset, discount]) =>
      tx(vaults[asset], "setMaxLiquidationDiscount", setMaxLiquidationDiscountInputs, {
        discount,
      }),
    ),
    ...ltvUpdates.map(([borrowAsset, collateralAsset, borrowLTV, liquidationLTV]) =>
      tx(vaults[borrowAsset], "setLTV", setLtvInputs, {
        collateral: vaults[collateralAsset],
        borrowLTV,
        liquidationLTV,
        rampDuration: "0",
      }),
    ),
    ...irmDeploymentOrder.map((irm) =>
      tx(vaults[irm.asset], "setInterestRateModel", setInterestRateModelInputs, {
        newModel: irmByAsset[irm.asset],
      }),
    ),
  ],
};

const readme = `# Base AI Cluster Safe Payloads

Generated for Base chain ID ${CHAIN_ID}.

## Files

- \`01-deploy-base-ai-irms.json\`: Safe Transaction Builder payload that deploys six new Kink IRMs through \`${IRM_FACTORY}\`.
- \`02-update-base-ai-params.json\`: Safe Transaction Builder payload that updates caps, max liquidation discounts, LTVs, and vault IRM pointers.

## Critical Execution Order

1. Before importing \`01-deploy-base-ai-irms.json\`, confirm the IRM factory nonce is still \`112\`:

   \`\`\`sh
   cast nonce ${IRM_FACTORY} --rpc-url "$RPC_URL_BASE"
   \`\`\`

2. Execute \`01-deploy-base-ai-irms.json\` from the Safe.
3. Verify the six deployed IRMs exactly match the predicted addresses and parameters below.
4. Only then import and execute \`02-update-base-ai-params.json\`.

If the factory nonce is not \`112\` before step 1, regenerate these payloads before using the update JSON.

## Expected IRMs

| Asset | Expected IRM | Curve |
|---|---|---|
${irmDeploymentOrder.map((irm) => `| ${irm.asset} | \`${irm.predictedAddress}\` | ${irm.curve} |`).join("\n")}

## Verification Commands

Replace \`<IRM>\` with each expected IRM address:

\`\`\`sh
cast call <IRM> 'baseRate()(uint256)' --rpc-url "$RPC_URL_BASE"
cast call <IRM> 'slope1()(uint256)' --rpc-url "$RPC_URL_BASE"
cast call <IRM> 'slope2()(uint256)' --rpc-url "$RPC_URL_BASE"
cast call <IRM> 'kink()(uint32)' --rpc-url "$RPC_URL_BASE"
\`\`\`

Expected IRM constants:

| Asset | baseRate | slope1 | slope2 | kink |
|---|---:|---:|---:|---:|
${irmDeploymentOrder.map((irm) => `| ${irm.asset} | ${irm.baseRate} | ${irm.slope1} | ${irm.slope2} | ${irm.kink} |`).join("\n")}

## Vault Updates

Governor multisig: \`${MULTISIG}\`

Caps:

| Asset | Supply Cap Encoded | Borrow Cap Encoded | Human Target |
|---|---:|---:|---|
${Object.entries(caps).map(([asset, cap]) => `| ${asset} | ${cap.supplyCap} | ${cap.borrowCap} | ${cap.note} |`).join("\n")}

Max liquidation discount:

| Asset | Encoded |
|---|---:|
${Object.entries(liquidationDiscounts).map(([asset, discount]) => `| ${asset} | ${discount} |`).join("\n")}

LTV policy:

- USDC borrow / WETH collateral and WETH borrow / USDC collateral: 87% borrow LTV, 90% liquidation LTV.
- Any USDC or WETH borrow vault with volatile collateral: 80% borrow LTV, 85% liquidation LTV.
- Any volatile borrow vault with USDC or WETH collateral: 80% borrow LTV, 85% liquidation LTV.
- Volatile-to-volatile pairs remain disabled and are not included in the update payload.
`;

await fs.mkdir(outputDir, { recursive: true });
await fs.writeFile(path.join(outputDir, "01-deploy-base-ai-irms.json"), JSON.stringify(deployPayload, null, 2) + "\n");
await fs.writeFile(path.join(outputDir, "02-update-base-ai-params.json"), JSON.stringify(updatePayload, null, 2) + "\n");
await fs.writeFile(path.join(outputDir, "README.md"), readme);

console.log("Generated Base AI Safe payloads");
console.log(`01 transactions: ${deployPayload.transactions.length}`);
console.log(`02 transactions: ${updatePayload.transactions.length}`);
