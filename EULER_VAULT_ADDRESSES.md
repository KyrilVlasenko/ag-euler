# AlphaGrowth Euler Vault Addresses

Snapshot date: 2026-08-15

Risk manager multisig: `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C`

## Scope and verification method

This inventory was reconciled against Euler's live V3 deployment registry on all chains in the current `EulerChains.json` deployment manifest.

- An EVK vault is included when its live `governorAdmin` equals the AlphaGrowth risk manager multisig.
- An EulerEarn vault is included when its live owner equals the AlphaGrowth multisig, or its on-chain name identifies it as an AlphaGrowth vault. The latter rule retains pending or incomplete AlphaGrowth deployments and marks their exact status.
- `Active` means core EVK operations are enabled and the vault has not been identified as deprecated or superseded. It does not assert that the vault currently has TVL, a non-zero cap, or an official Euler product label.
- `Deprecated` means the live Euler labels list the vault as deprecated, or a formerly listed maturity/removal is no longer in the live product.
- `Inactive` means all core EVK operations are disabled on-chain, or an Earn deployment is incomplete and unmanaged.
- `Superseded` means a replacement vault is live. Some superseded vaults still have operations enabled so users can unwind; do not treat that as a current market listing.

Live scan totals:

| Chain | Chain ID | EVK vaults | EulerEarn vaults |
| --- | ---: | ---: | ---: |
| Ethereum | `1` | 27 | 1 |
| Base | `8453` | 35 | 1 |
| Unichain | `130` | 15 | 1 |
| Monad | `143` | 14 | 2 |
| Arbitrum | `42161` | 4 | 0 |
| Linea | `59144` | 4 | 0 |
| **Total** |  | **99** | **5** |

No AlphaGrowth-governed EVK or AlphaGrowth-named/owned EulerEarn vaults were found on the other live Euler deployment chains in the registry at the snapshot time.

## Ethereum

| Market / cluster | Euler vault | Asset | Address | Status |
| --- | --- | --- | --- | --- |
| Falcon | `eUSDC-45` | USDC | `0x3573A84Bee11D49A1CbCe2b291538dE7a7dD81c6` | Active |
| Falcon | `eUSDT-17` | USDT | `0xbFdc482616787b420BC6C710212fE3167E7198e9` | Deprecated/unlisted; removed from the live Falcon product |
| Falcon | `eUSDf-1` | USDf | `0x412D0E31790D77b6e7a7872a9fd6967B6E640229` | Active |
| Falcon | `esUSDf-1` | sUSDf | `0x2F849ba554C1ea2eDe9C240Bbe9d247dd6eC8A6B` | Active |
| Falcon | `ePT-sUSDf-25SEP2025-1` | PT-sUSDf-25SEP2025 | `0xE415952f5ee06f8A548F4f7D5bE18FBf144b4E4D` | Deprecated/unlisted; matured |
| Falcon | `ePT-USDf-29JAN2026-1` | PT-USDf-29JAN2026 | `0xa7A064f56FbcA60cBeD47eD3e13C4B945DEf7eC3` | Deprecated/unlisted; matured |
| Falcon | `ePT-sUSDf-29JAN2026-1` | PT-sUSDf-29JAN2026 | `0xFBCc21fedd4C4e9097Ef1Baa65B7Ad386b59512D` | Deprecated/unlisted; matured |
| Cap | `eUSDC-63` | USDC | `0x6Fe7Fa90756434645F0b0428fDff78E99Dda0FBc` | Active |
| Cap | `eUSDT-30` | USDT | `0x35d4f830543700B7280084280ae3236f178E88e3` | Deprecated/unlisted; removed from the live Cap product |
| Cap | `ecUSD-1` | cUSD | `0x55F9bACE2C864aC0D3392Ea9fa654b605F21A3d3` | Active |
| Cap | `estcUSD-1` | stcUSD | `0xb7522C867B8AFae5e89638b59fb38f31B0821795` | Active |
| Cap | `ePT-cUSD-29JAN2026-1` | PT-cUSD-29JAN2026 | `0x69a2fAD6AC96DDa502f7d240fB4EC88f85217705` | Deprecated/unlisted; matured |
| Cap | `ePT-stcUSD-29JAN2026-1` | PT-stcUSD-29JAN2026 | `0x97C72647be549C6079dC95235271A9a0Fe7ECc21` | Deprecated/unlisted; matured |
| Mainnet RWA | `eUSDC-69` | USDC | `0x2a356443FeE07703266066c6Bb1B11b82d8246AD` | Active |
| Mainnet RWA | `eUSDT-33` | USDT | `0xC11d6b78D8c609A6cbf66E89DBfea06b011B0AEf` | Active |
| Mainnet RWA | `emAPOLLO-1` | mAPOLLO | `0x49d9fd20f1d61648Fa9434a8c0C33174F5614eB8` | Active |
| Mainnet RWA | `ePT-mAPOLLO-20NOV2025-1` | PT-mAPOLLO-20NOV2025 | `0xF75D18F76859764aBe4D13cA2eBaCeFF0b90b262` | Deprecated/unlisted; matured |
| Mainnet RWA | `ePAXG-3` | PAXG | `0x05E09415398659B19C5aeF202289270B37F1Fb31` | Active |
| Mainnet RWA | `ereUSD-1` | reUSD | `0x72a6D005374DB6B7975Fb5768A1802F5c0979474` | Active |
| Mainnet RWA | `ereUSDe-1` | reUSDe | `0xF81b08Cb4669049049B9C2A38c7D27d480655Bb3` | Active |
| Mainnet RWA | `eUSDS-8` | USDS | `0xd4CCf87cBfe6c1f1390706667917b5FD3Ceb43BB` | Active |
| Mainnet RWA / Saturn removal | `eUSDat-1` | USDat | `0x7FDb59A3232F435c50B9108361E38674e25da87c` | Inactive to new activity; supply and borrow caps are zero and the vault was removed from the live RWA product |
| Mainnet RWA / Saturn removal | `esUSDat-1` | sUSDat | `0xd5020aad0CF1aB6F1c020Ba8b14B37e5Fb869F5B` | Inactive to new activity; supply and borrow caps are zero and the vault was removed from the live RWA product |
| Origin ARM | `eWETH-43` | WETH | `0x2ff5F1Ca35f5100226ac58E1BFE5aac56919443B` | Active |
| Origin ARM | `eARM-WETH-stETH-1` | ARM-WETH-stETH | `0xbD858DCee56Df1F0CBa44e6F5a469FbfeC0246cd` | Active |
| Unlabeled AlphaGrowth-governed vault | `eUSDC-127` | USDC | `0xb639d1B47215d1Bc6E2d33b299b3F386627c0F2b` | Review; operations enabled, near-zero assets, and not in a live Euler product |
| Unlabeled AlphaGrowth-governed vault | `eWBTC-16` | WBTC | `0x915104922E6a55B00B7245d56EE950cd591782C2` | Review; operations enabled, zero assets, and not in a live Euler product |

### Ethereum EulerEarn

| Earn vault | Asset | Address | Status |
| --- | --- | --- | --- |
| AlphaGrowth Earn USDC (`agUSDC`) | USDC | `0xA5A84a76bA96Eb2816D967FA91533cC38064c47A` | Active and owned by the AlphaGrowth multisig; zero assets at snapshot |

## Base

| Market / cluster | Euler vault | Asset | Address | Status |
| --- | --- | --- | --- | --- |
| Base Market | `eWETH-1` | WETH | `0x859160DB5841E5cfB8D3f144C6b3381A85A4b410` | Active |
| Base Market | `ewstETH-1` | wstETH | `0x7b181d6509DEabfbd1A23aF1E65fD46E89572609` | Active |
| Base Market | `ecbETH-1` | cbETH | `0x358f25F82644eaBb441d0df4AF8746614fb9ea49` | Active |
| Base Market | `eweETH-1` | weETH | `0xd4A805261B28f375fc9c3d89EcD2C952Cd130d14` | Active |
| Base Market | `eUSDC-1` | USDC | `0x0A1a3b5f2041F33522C4efc754a7D096f880eE16` | Active |
| Base Market | `ecbBTC-1` | cbBTC | `0x882018411Bc4A020A879CEE183441fC9fa5D7f8B` | Active |
| Base Market | `eLBTC-1` | LBTC | `0x3f0d3Fd87A42BDaa3dfCC13ADA42eA922e638a7A` | Active |
| Base Market | `eAERO-1` | AERO | `0x5Fe2DE3E565a6a501a4Ec44AAB8664b1D674ac25` | Active |
| YO yoBTC | `ecbBTC-7` | cbBTC | `0xe72eA97aAF905c5f10040f78887cc8dE8eAec7E4` | Active |
| YO yoBTC | `eyoBTC-1` | yoBTC | `0xFab9aF50F7A1Cfe201CAE1c15fCFdDaE7705ccD3` | Active |
| YO yoUSD | `eUSDC-29` | USDC | `0x085178078796Da17B191f9081b5E2fCCc79A7eE7` | Active |
| YO yoUSD | `eyoUSD-1` | yoUSD | `0x990d616ca6E7192625d1B7C41Fb67b5758DF7CF2` | Active |
| YO yoUSD | `ePT-yoUSD-26MAR2026-1` | PT-yoUSD-26MAR2026 | `0x24D633664Aea3F551B2Fa34fA66Dd1BA52a33933` | Active in the live product despite maturity date |
| Base RWA, superseded v1 | `ereUSD-1` | reUSD | `0x45Bad72887C23234F44cf77004a1473F0c9439C8` | Superseded/unlisted; operations enabled, zero assets |
| Base RWA, superseded v1 | `eUSDC-48` | USDC | `0x39cCf4e962191840e2c8065949947C80b5b2e20C` | Superseded/unlisted; operations enabled, zero assets |
| Base RWA | `ereUSD-2` | reUSD | `0x81744B5B5527852832F2dd3554C191d3B1342108` | Active |
| Base RWA | `eUSDC-49` | USDC | `0x4C1aeda9B43EfcF1da1d1755b18802aAbe90f61E` | Active |
| Base RWA, superseded ST0x v1 | `ewtSPYM-1` | wtSPYM | `0x67aF8ff5B13e9E697aa461e866fe0f41f68493c3` | Inactive; all core EVK operations disabled |
| Base RWA, superseded ST0x v1 | `ewtMSTR-1` | wtMSTR | `0xb5A2fDa01456Aee7437e740b73ae8fB77fb135dB` | Inactive; all core EVK operations disabled |
| Base RWA, superseded ST0x v1 | `ewtCOIN-1` | wtCOIN | `0xc572516b2eA4613d1f206B1f47309d310fA452Ac` | Inactive; all core EVK operations disabled |
| Base RWA | `ewtSPYM-2` | wtSPYM | `0xd54d33dA9C326AEE7513cEFdedA5c93a41809caD` | Active replacement |
| Base RWA | `ewtMSTR-2` | wtMSTR | `0xD864d46c62685A6062A722AFD7C8c978c410aAaF` | Active replacement |
| Base RWA | `ewtCOIN-2` | wtCOIN | `0x2645CBAF62F2f336B0e988375d7e6bCAb66A296C` | Active replacement |
| Base AI, superseded v1 | `eUSDC-87` | USDC | `0x21c8c8A56790A2b10370373fAcb94e925fD6a06E` | Superseded/unlisted; operations still enabled |
| Base AI, superseded v1 | `eWETH-34` | WETH | `0x68AAD2c78065E2D28d2B46f6A80c5a813461FFf4` | Superseded/unlisted; operations still enabled |
| Base AI, superseded v1 | `eVVV-1` | VVV | `0x4B6509B06f664eb8c8a4e9072655A4C6cafc1D9C` | Superseded/unlisted; operations still enabled |
| Base AI, superseded v1 | `eZRO-1` | ZRO | `0xCB935d7916B20748e7f14C3B95931b8dcdA2472D` | Superseded/unlisted; operations still enabled |
| Base AI, superseded v1 | `eAERO-2` | AERO | `0xAf5F576396730C212A8C6056A00eaA58123d78B6` | Superseded/unlisted; operations still enabled |
| Base AI, superseded v1 | `eVIRTUAL-1` | VIRTUAL | `0x3Bd428B28C52f3534CC78075799CA798e4BcE5a8` | Superseded/unlisted; operations still enabled |
| Base AI | `eUSDC-102` | USDC | `0xEef57677c2FC1a930eed234E3545e750C88f6743` | Active replacement |
| Base AI | `eWETH-38` | WETH | `0xC64FD6138f980a5587412dAC75E04363046aE32E` | Active replacement |
| Base AI | `eVVV-3` | VVV | `0x13632ED686495b1F5E7F81dcc5977AB55aAb98A4` | Active replacement |
| Base AI | `eZRO-3` | ZRO | `0xcf8f0E47Cd510938FDD445Cf1A24108A681743A6` | Active replacement |
| Base AI | `eAERO-4` | AERO | `0x9F876520F1937D4B4f6F4DefE29fa5EA6d4526d0` | Active replacement |
| Base AI | `eVIRTUAL-3` | VIRTUAL | `0x6aE4eCc3C9467c587AA4953365E0d8454fe77EF1` | Active replacement |

### Base EulerEarn

| Earn vault | Asset | Address | Status |
| --- | --- | --- | --- |
| AlphaGrowth Earn USDC (`agUSDC`) | USDC | `0xC72F073A311e037d4bc909FedAE94De38494EE5b` | Active and owned by the AlphaGrowth multisig |

## Unichain

| Market / cluster | Euler vault | Asset | Address | Status |
| --- | --- | --- | --- | --- |
| Unichain Market | `eWETH-1` | WETH | `0x1f3134C3f3f8AdD904B9635acBeFC0eA0D0E1ffC` | Active |
| Unichain Market | `ewstETH-1` | wstETH | `0x54ff502df96CD9B9585094EaCd86AAfCe902d06A` | Active |
| Unichain Market | `eweETH-1` | weETH | `0xe36DA4Ea4D07E54B1029eF26A896A656A3729f86` | Active |
| Unichain Market | `eUSDC-1` | USDC | `0x6eAe95ee783e4D862867C4e0E4c3f4B95AA682Ba` | Active |
| Unichain Market | `eUSD₮0-1` | USD₮0 | `0xD49181c522eCDB265f0D9C175Cf26FFACE64eAD3` | Active |
| Unichain Market | `esUSDC-1` | sUSDC | `0x7650D7ae1981f2189d352b0EC743b9099D24086F` | Active |
| Unichain Market | `eWBTC-2` | WBTC | `0x5d2511C1EBc795F4394f7f659f693f8C15796485` | Active |
| Unichain collateral | `eezETH-1` | ezETH | `0x45b41B20B11cD2e71A6BF3021bdbc3F8aFEa5538` | Active |
| Unichain collateral | `ersETH-1` | rsETH | `0x59215f65cB2F5Ddf048eFA8136Fc2C19F9A6C416` | Active |
| Unichain collateral | `eUNI-1` | UNI | `0x576f68B0395738AEF01811b8F8EeC25302829F1d` | Active |
| Unichain Vaults, superseded deployment | `erETH-1` | rETH | `0x2dd0dc1Ee8086f7Bc0Bd12c7B19F6d2fc592EbF6` | Inactive; all core EVK operations disabled |
| Unichain Vaults, superseded deployment | `eWETH-3` | WETH | `0xF39a75D03e77b8FB730B55d17d64b4C500601E71` | Inactive; all core EVK operations disabled |
| Unichain Vaults | `erETH-2` | rETH | `0x218c9e961fC5f6c8280bA160365FAbe8A53Ec6E5` | Active replacement |
| Unichain Vaults | `eWETH-4` | WETH | `0x5ADAde21c703912547BFc8952fe1B52f09437E2A` | Active replacement |
| Unichain Cap maturity | `ePT-cUSD-29JAN2026-(ETH)-1` | PT-cUSD-29JAN2026-(ETH) | `0xeE85660f8bb7C020A69C20886D1C91e7F984006a` | Deprecated/unlisted; matured |

### Unichain EulerEarn

| Earn vault | Asset | Address | Status |
| --- | --- | --- | --- |
| AlphaGrowth Earn USDC (`agUSDC`) | USDC | `0xd325A54926C937710daa1b46d1c6587155084a63` | Pending ownership transfer; live owner is `0x36639EA17c35A4639eaE371391497Cb3D02d120a`, zero assets at snapshot |

## Monad

| Market / cluster | Euler vault | Asset | Address | Status |
| --- | --- | --- | --- | --- |
| Balancer BPT | `eAUSD-11` | AUSD | `0x438cedcE647491B1d93a73d491eC19A50194c222` | Active |
| Balancer BPT | `eWMON-12` | WMON | `0x75B6C392f778B8BCf9bdB676f8F128b4dD49aC19` | Active |
| Balancer BPT pool 1 | `ewnAUSD-wnUSDC-wnUSDT0-1` | wnAUSD-wnUSDC-wnUSDT0 | `0x5795130BFb9232C7500C6E57A96Fdd18bFA60436` | Active |
| Balancer BPT pool 2, superseded | `esMON-wnWMON-1` | sMON-wnWMON | `0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5` | Superseded/unlisted; operations still enabled |
| Balancer BPT pool 3, superseded | `eshMON-wnWMON-1` | shMON-wnWMON | `0x6660195421557BC6803e875466F99A764ae49Ed7` | Superseded/unlisted; operations still enabled |
| Balancer BPT pool 4, superseded | `ewnLOAZND-AZND-wnAUSD-1` | wnLOAZND-AZND-wnAUSD | `0x175831aF06c30F2EA5EA1e3F5EBA207735Eb9F92` | Superseded/unlisted; operations still enabled |
| Balancer BPT pool 2 | `ewnSMON-wnWMON-1` | wnSMON-wnWMON | `0x7ad9f09B431A4C5F4CbA809d449Fde842192f9ec` | Active replacement |
| Balancer BPT pool 3 | `ewnSHMON-wnWMON-1` | wnSHMON-wnWMON | `0x7A81A1613D50ffF334027Aad76F2416368f6050f` | Active replacement |
| Balancer BPT pool 4 | `ewnLOAZND-AZND-wnAUSD-2` | wnLOAZND-AZND-wnAUSD | `0x2067936155c7DB57b1cdCF776B04B9678c245626` | Active replacement |
| Balancer Beefy collateral | `ewmooBalancerMonadwnUSDT0-wnAUSD-wnUSDC-1` | wmooBalancerMonadwnUSDT0-wnAUSD-wnUSDC | `0xf18f3BC9440ad7940E6E2a86fD0C724AdD2dd0Aa` | Active |
| AUSD PT | `eAUSD-18` | AUSD | `0x248C74aA002A571c340a3d894aAF294884A49bE1` | Active |
| AUSD PT | `ePT-AUSD-8OCT2026-1` | PT-AUSD-8OCT2026 | `0xf3E55a17c4c59Cb70EA44973795fA8F3c3BAad72` | Active |
| earnAUSD PT | `eAUSD-19` | AUSD | `0x7cc566d100E81a9708fd23B18F6B92D3249430C9` | Active |
| earnAUSD PT | `ePT-earnAUSD-8OCT2026-1` | PT-earnAUSD-8OCT2026 | `0xC4fAbE0B5A280163aB47E3162689A278C81df3f9` | Active |

### Monad EulerEarn

| Earn vault | Asset | Address | Status |
| --- | --- | --- | --- |
| AlphaGrowth Earn AUSD (`agAUSD`) | AUSD | `0x6f63732BbBB1780E546C6183C187957B63E1C9d4` | Active and owned by the AlphaGrowth multisig |
| AlphaGrowth Earn USDC (`agUSDC`) | Unknown in live V3 metadata | `0x4E1e53C6C40e1022d9eF6b0346a8f97e4fEb5467` | Inactive/incomplete; zero assets and no live asset, owner, or guardian metadata |

## Arbitrum

Euler's live labels explicitly deprecate this entire cluster due to low activity. The EVK contracts still have operations enabled, which allows orderly exit and does not make them current markets.

| Market / cluster | Euler vault | Asset | Address | Status |
| --- | --- | --- | --- | --- |
| Arbitrum Vaults | `eyUSND-1` | yUSND | `0x124BeC4d119bc4B5d250f0b0114f2087f8EeDB57` | Deprecated due to low activity |
| Arbitrum Vaults | `eUSND-1` | USND | `0x4aD21eBbB639c21ccd9F1eaF388Cd91D015E02ee` | Deprecated due to low activity |
| Arbitrum Vaults | `ereUSD-1` | reUSD | `0x8Ca487811a5e7599A5c68F49Ac1fE348371e4c46` | Deprecated due to low activity |
| Arbitrum Vaults | `eUSDC-7` | USDC | `0x06b763aA769ad01F6859a56c5a856E47896e6a7F` | Deprecated due to low activity |

## Linea

| Market / cluster | Euler vault | Asset | Address | Status |
| --- | --- | --- | --- | --- |
| Linea wstETH | `eWETH-1` | WETH | `0xa8A02E6a894a490D04B6cd480857A19477854968` | Active |
| Linea wstETH | `ewstETH-1` | wstETH | `0x359e363c11fC619BE76EEC8BaAa01e61D521aA18` | Active |
| Linea weETH | `eWETH-2` | WETH | `0xF4712fC5E6483DE9e1Ff661D95DD686664327086` | Active |
| Linea weETH | `eweETH-1` | weETH | `0x8955d7dCdE9bD9694B64732aD28fF2113eb217B4` | Active |

## DefiLlama coverage note

This file is now the complete live AlphaGrowth governance inventory, not just the subset used by the AlphaGrowth DefiLlama adapter.

As of the prior 2026-05-07 adapter review, these four vaults were discovered through `eulerVaultOwners` and were not meant to be duplicated in the adapter's explicit `euler` list:

- Base `ereUSD-2`: `0x81744B5B5527852832F2dd3554C191d3B1342108`
- Base `eUSDC-49`: `0x4C1aeda9B43EfcF1da1d1755b18802aAbe90f61E`
- Unichain `erETH-2`: `0x218c9e961fC5f6c8280bA160365FAbe8A53Ec6E5`
- Unichain `eWETH-4`: `0x5ADAde21c703912547BFc8952fe1B52f09437E2A`

Do not infer current DefiLlama coverage for newly added rows from this inventory alone. Reconcile the adapter separately before adding explicit entries, or TVL can be double counted.
