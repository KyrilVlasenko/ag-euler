# Base Unified Market — Deployed Addresses (Base 8453)

6-asset unified market: USDC, ETH, VVV, ZRO, AERO, VIRTUAL. Each borrow vault serves as both lending pool and collateral. Consolidated from the former venice-contracts, zro-contracts, aero-contracts, and virtual-contracts directories.

## Shared Infrastructure

| Contract | Address |
|----------|---------|
| EulerRouter | `0x0293B19af06dF6CB00323e1e924AA8995bC1718B` |
| Fee Receiver | `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C` |
| Governor Admin | `0x8b59FC48E305AFE0934A897F0Cac6cbD3764F3dd` |

## Oracle Adapters

| Adapter | Address |
|---------|---------|
| VVV/USD Chainlink | `0x52cACC037E8F6f681718E08BafaEe305FB1e5512` |
| USDC/USD Chainlink (existing Base) | `0x5C9d3504d64B401BE0E6fDA1b7970e2f5FF75485` |
| ETH/USD Chainlink (existing Base) | `0xeCa05CC73e67c344d5B146311B13ddB75F7fE4E4` |
| ZRO/USD Chainlink | `0x9D39B08C040501c0977274F865cD11891BF3c1d2` |
| AERO/USD Chainlink | `0x3E5221be796DDb59183193Da9a01f38449b0f7Be` |
| VIRTUAL/USD Chainlink | `0xFd73B3A1b55d0E95d25308Dc34360003a8f1Ba28` |

## Interest Rate Models

| IRM | Address | Parameters |
|-----|---------|------------|
| VVV KinkIRM | `0x23bBDD9B5c795626A043a52C7984e6F3EE47BBDf` | Base=1%, Kink(80%)=40%, Max=100% |
| USDC KinkIRM | `0x419caC0AdF2Ea56e84AF25E242DA8699AE950217` | Base=0%, Kink(90%)=18.52%, Max=100% |
| ETH KinkIRM | `0x9De9af414CF12D307abF6D2c560e631353f8eD2A` | Base=0%, Kink(90%)=7.41%, Max=100% |
| ZRO KinkIRM | `0xD362cf3119854BdB08A0F160B37528EfF5F0280d` | Base=2%, Kink(70%)=15%, Max=200% |
| AERO KinkIRM | `0x78F615b0C47099eF9B1D3ad5087f24c26074b325` | Base=0%, Kink(85%)=16%, Max=750% |
| VIRTUAL KinkIRM | `0x6D429C42038E9270039bf16B97406912CeAAc28E` | Base=0%, Kink(80%)=15%, Max=100% |

## Borrow Vaults (Active — unified lending + collateral)

| Vault | Address | Asset | Caps |
|-------|---------|-------|------|
| USDC | `0x21c8c8A56790A2b10370373fAcb94e925fD6a06E` | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 1,500,000 |
| ETH | `0x68AAD2c78065E2D28d2B46f6A80c5a813461FFf4` | `0x4200000000000000000000000000000000000006` | 800 |
| VVV | `0x4B6509B06f664eb8c8a4e9072655A4C6cafc1D9C` | `0xacfE6019Ed1A7Dc6f7B508C02d1b04ec88cC21bf` | 200,000 |
| ZRO | `0xCB935d7916B20748e7f14C3B95931b8dcdA2472D` | `0x6985884C4392D348587B19cb9eAAf157F13271cd` | 185,000 |
| AERO | `0xAf5F576396730C212A8C6056A00eaA58123d78B6` | `0x940181a94A35A4569E4529A3CDfB74e38FD98631` | 10,000,000 |
| VIRTUAL | `0x3Bd428B28C52f3534CC78075799CA798e4BcE5a8` | `0x0b3e328455c4059EEb9e3f84b5543F74E24e7E1b` | 3,300,000 |

## Risk Parameters

All pairs: LTV 85% / LLTV 87% / Max Liquidation Discount 5% / Interest Fee 10%

## Cross-Collateral Matrix

Borrow vaults accept other borrow vaults as collateral. No volatile-to-volatile pairs.

| Borrow ↓ / Collateral → | USDC | ETH | VVV | ZRO | VIRTUAL | AERO |
|---|---|---|---|---|---|---|
| **USDC** | - | ✅ | ✅ | ✅ | ✅ | ✅ |
| **ETH** | ✅ | - | ✅ | ✅ | ✅ | ✅ |
| **VVV** | ✅ | ✅ | - | ❌ | ❌ | ❌ |
| **ZRO** | ✅ | ✅ | ❌ | - | ❌ | ❌ |
| **VIRTUAL** | ✅ | ✅ | ❌ | ❌ | - | ❌ |
| **AERO** | ✅ | ✅ | ❌ | ❌ | ❌ | - |

## Legacy Collateral Vaults (Deprecated)

LTVs zeroed out. No longer referenced by any borrow vault. Kept for reference only.

| Vault | Address |
|-------|---------|
| USDC Collateral | `0x70abc7848ce268017728aD8E45F979F6F1071403` |
| VVV Collateral | `0xDA8f11258CAC545F2A6f28b13aAca364E08F8599` |
| WETH Collateral | `0xeC0c00e9b0894553c9D63C1Dd930c27a303F953c` |
| ZRO Collateral | `0xaA73062F331873581991eDdD6848e0e57575E14f` |
| AERO Collateral | `0x2172Df80c6ba09F2a314318C4c1D385F67582a1c` |
| VIRTUAL Collateral | `0xced5E60B38B3cfE5cF945762c4f015fB4727bD64` |
