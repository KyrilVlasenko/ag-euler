# AlphaGrowth Euler Vault Addresses

Snapshot date: 2026-05-05

Last verified for DefiLlama adapter PR: 2026-05-07

Risk manager multisig: `0x4f894Bfc9481110278C356adE1473eBe2127Fd3C`

Source criterion: Euler vault metadata where `governorAdmin` equals the AlphaGrowth risk manager multisig.

Label format: `[market or cluster name] [vault asset]`, matching the inline labels in `projects/alpha-growth/index.js` where the vault is explicitly listed.

DefiLlama implementation note: vaults marked `explicit euler list` should be listed in `projects/alpha-growth/index.js`. Vaults marked `covered by eulerVaultOwners` are already discovered by the existing creator-based helper and should not be added explicitly, to avoid double counting.

Chain IDs used for verification:

| Chain | Chain ID |
| --- | --- |
| Ethereum | `1` |
| Base | `8453` |
| Unichain | `130` |
| Linea | `59144` |
| Arbitrum | `42161` |

DefiLlama adapter test snapshot from 2026-05-07:

| Chain | Approximate TVL |
| --- | ---: |
| Unichain | `$4.54M` |
| Base | `$3.89M` |
| Ethereum | `$1.58M` |
| Linea | `$191k` |
| Arbitrum | `$0` |
| Total | `$10.20M` |

Notes:

- `explicit euler list` means the vault is manually listed under `euler` in the AlphaGrowth DefiLlama adapter.
- `covered by eulerVaultOwners` means the vault is discovered automatically by the existing creator-based helper.
- Do not manually add a `covered by eulerVaultOwners` vault to the explicit `euler` list unless the helper behavior changes; doing so can double count TVL.
- Keep this file's explicit-vault labels synced with the inline comments in `market-curation/defillama-adapters/projects/alpha-growth/index.js`.

## Ethereum

| Label | Euler vault | Asset | Address | DefiLlama coverage |
| --- | --- | --- | --- | --- |
| Falcon USDC | EVK Vault eUSDC-45 (`eUSDC-45`) | USDC - USD Coin | `0x3573A84Bee11D49A1CbCe2b291538dE7a7dD81c6` | explicit euler list |
| Falcon USDT | EVK Vault eUSDT-17 (`eUSDT-17`) | USDT - Tether USD | `0xbFdc482616787b420BC6C710212fE3167E7198e9` | explicit euler list |
| Falcon USDf | EVK Vault eUSDf-1 (`eUSDf-1`) | USDf - Falcon USD | `0x412D0E31790D77b6e7a7872a9fd6967B6E640229` | explicit euler list |
| Falcon sUSDf | EVK Vault esUSDf-1 (`esUSDf-1`) | sUSDf - Staked Falcon USD | `0x2F849ba554C1ea2eDe9C240Bbe9d247dd6eC8A6B` | explicit euler list |
| Falcon PT-USDf-29JAN2026 | EVK Vault ePT-USDf-29JAN2026-1 (`ePT-USDf-29JAN2026-1`) | PT-USDf-29JAN2026 | `0xa7A064f56FbcA60cBeD47eD3e13C4B945DEf7eC3` | explicit euler list |
| Falcon PT-sUSDf-29JAN2026 | EVK Vault ePT-sUSDf-29JAN2026-1 (`ePT-sUSDf-29JAN2026-1`) | PT-sUSDf-29JAN2026 | `0xFBCc21fedd4C4e9097Ef1Baa65B7Ad386b59512D` | explicit euler list |
| Cap USDC | EVK Vault eUSDC-63 (`eUSDC-63`) | USDC - USD Coin | `0x6Fe7Fa90756434645F0b0428fDff78E99Dda0FBc` | explicit euler list |
| Cap USDT | EVK Vault eUSDT-30 (`eUSDT-30`) | USDT - Tether USD | `0x35d4f830543700B7280084280ae3236f178E88e3` | explicit euler list |
| Cap cUSD | EVK Vault ecUSD-1 (`ecUSD-1`) | cUSD - cap USD | `0x55F9bACE2C864aC0D3392Ea9fa654b605F21A3d3` | explicit euler list |
| Cap stcUSD | EVK Vault estcUSD-1 (`estcUSD-1`) | stcUSD - Staked cap USD | `0xb7522C867B8AFae5e89638b59fb38f31B0821795` | explicit euler list |
| Cap PT-cUSD-29JAN2026 | EVK Vault ePT-cUSD-29JAN2026-1 (`ePT-cUSD-29JAN2026-1`) | PT-cUSD-29JAN2026 | `0x69a2fAD6AC96DDa502f7d240fB4EC88f85217705` | explicit euler list |
| Cap PT-stcUSD-29JAN2026 | EVK Vault ePT-stcUSD-29JAN2026-1 (`ePT-stcUSD-29JAN2026-1`) | PT-stcUSD-29JAN2026 | `0x97C72647be549C6079dC95235271A9a0Fe7ECc21` | explicit euler list |
| mAPOLLO USDC | EVK Vault eUSDC-69 (`eUSDC-69`) | USDC - USD Coin | `0x2a356443FeE07703266066c6Bb1B11b82d8246AD` | explicit euler list |
| mAPOLLO USDT | EVK Vault eUSDT-33 (`eUSDT-33`) | USDT - Tether USD | `0xC11d6b78D8c609A6cbf66E89DBfea06b011B0AEf` | explicit euler list |
| mAPOLLO mAPOLLO | EVK Vault emAPOLLO-1 (`emAPOLLO-1`) | mAPOLLO - Midas Apollo Crypto | `0x49d9fd20f1d61648Fa9434a8c0C33174F5614eB8` | explicit euler list |
| mAPOLLO PT-mAPOLLO-20NOV2025 | EVK Vault ePT-mAPOLLO-20NOV2025-1 (`ePT-mAPOLLO-20NOV2025-1`) | PT-mAPOLLO-20NOV2025 | `0xF75D18F76859764aBe4D13cA2eBaCeFF0b90b262` | explicit euler list |
| Ethereum ARM ARM-WETH-stETH | EVK Vault eARM-WETH-stETH-1 (`eARM-WETH-stETH-1`) | ARM-WETH-stETH - Lido ARM | `0xbD858DCee56Df1F0CBa44e6F5a469FbfeC0246cd` | explicit euler list |
| Ethereum WETH WETH | EVK Vault eWETH-43 (`eWETH-43`) | WETH - Wrapped Ether | `0x2ff5F1Ca35f5100226ac58E1BFE5aac56919443B` | explicit euler list |

## Base

| Label | Euler vault | Asset | Address | DefiLlama coverage |
| --- | --- | --- | --- | --- |
| Base WETH | EVK Vault eWETH-1 (`eWETH-1`) | WETH - Wrapped Ether | `0x859160DB5841E5cfB8D3f144C6b3381A85A4b410` | explicit euler list |
| Base wstETH | EVK Vault ewstETH-1 (`ewstETH-1`) | wstETH - Wrapped liquid staked Ether 2.0 | `0x7b181d6509DEabfbd1A23aF1E65fD46E89572609` | explicit euler list |
| Base cbETH | EVK Vault ecbETH-1 (`ecbETH-1`) | cbETH - Coinbase Wrapped Staked ETH | `0x358f25F82644eaBb441d0df4AF8746614fb9ea49` | explicit euler list |
| Base weETH | EVK Vault eweETH-1 (`eweETH-1`) | weETH - Wrapped eETH | `0xd4A805261B28f375fc9c3d89EcD2C952Cd130d14` | explicit euler list |
| Base USDC | EVK Vault eUSDC-1 (`eUSDC-1`) | USDC - USD Coin | `0x0A1a3b5f2041F33522C4efc754a7D096f880eE16` | explicit euler list |
| Base cbBTC | EVK Vault ecbBTC-1 (`ecbBTC-1`) | cbBTC - Coinbase Wrapped BTC | `0x882018411Bc4A020A879CEE183441fC9fa5D7f8B` | explicit euler list |
| Base LBTC | EVK Vault eLBTC-1 (`eLBTC-1`) | LBTC - Lombard Staked Bitcoin | `0x3f0d3Fd87A42BDaa3dfCC13ADA42eA922e638a7A` | explicit euler list |
| Base AERO | EVK Vault eAERO-1 (`eAERO-1`) | AERO - Aerodrome | `0x5Fe2DE3E565a6a501a4Ec44AAB8664b1D674ac25` | explicit euler list |
| YO yoBTC Market cbBTC | EVK Vault ecbBTC-7 (`ecbBTC-7`) | cbBTC - Coinbase Wrapped BTC | `0xe72eA97aAF905c5f10040f78887cc8dE8eAec7E4` | explicit euler list |
| YO yoBTC Market yoBTC | EVK Vault eyoBTC-1 (`eyoBTC-1`) | yoBTC - yoVaultBTC | `0xFab9aF50F7A1Cfe201CAE1c15fCFdDaE7705ccD3` | explicit euler list |
| YO yoUSD Market USDC | EVK Vault eUSDC-29 (`eUSDC-29`) | USDC - USD Coin | `0x085178078796Da17B191f9081b5E2fCCc79A7eE7` | explicit euler list |
| YO yoUSD Market yoUSD | EVK Vault eyoUSD-1 (`eyoUSD-1`) | yoUSD - yoVaultUSD | `0x990d616ca6E7192625d1B7C41Fb67b5758DF7CF2` | explicit euler list |
| YO yoUSD Market PT-yoUSD-26MAR2026 | EVK Vault ePT-yoUSD-26MAR2026-1 (`ePT-yoUSD-26MAR2026-1`) | PT-yoUSD-26MAR2026 | `0x24D633664Aea3F551B2Fa34fA66Dd1BA52a33933` | explicit euler list |
| Base Vaults reUSD | EVK Vault ereUSD-2 (`ereUSD-2`) | reUSD - Re Protocol reUSD | `0x81744B5B5527852832F2dd3554C191d3B1342108` | covered by eulerVaultOwners |
| Base Vaults USDC | EVK Vault eUSDC-49 (`eUSDC-49`) | USDC - USD Coin | `0x4C1aeda9B43EfcF1da1d1755b18802aAbe90f61E` | covered by eulerVaultOwners |

## Unichain

| Label | Euler vault | Asset | Address | DefiLlama coverage |
| --- | --- | --- | --- | --- |
| Unichain WETH | EVK Vault eWETH-1 (`eWETH-1`) | WETH - Wrapped Ether | `0x1f3134C3f3f8AdD904B9635acBeFC0eA0D0E1ffC` | explicit euler list |
| Unichain wstETH | EVK Vault ewstETH-1 (`ewstETH-1`) | wstETH - Wrapped liquid staked Ether 2.0 | `0x54ff502df96CD9B9585094EaCd86AAfCe902d06A` | explicit euler list |
| Unichain weETH | EVK Vault eweETH-1 (`eweETH-1`) | weETH - Wrapped eETH | `0xe36DA4Ea4D07E54B1029eF26A896A656A3729f86` | explicit euler list |
| Unichain USDC | EVK Vault eUSDC-1 (`eUSDC-1`) | USDC | `0x6eAe95ee783e4D862867C4e0E4c3f4B95AA682Ba` | explicit euler list |
| Unichain USDT0 | EVK Vault eUSDT0-1 (`eUSDT0-1`) | USDT0 | `0xD49181c522eCDB265f0D9C175Cf26FFACE64eAD3` | explicit euler list |
| Unichain sUSDC | EVK Vault esUSDC-1 (`esUSDC-1`) | sUSDC - Spark USDC Vault | `0x7650D7ae1981f2189d352b0EC743b9099D24086F` | explicit euler list |
| Unichain WBTC | EVK Vault eWBTC-2 (`eWBTC-2`) | WBTC - Wrapped BTC | `0x5d2511C1EBc795F4394f7f659f693f8C15796485` | explicit euler list |
| Unichain Vaults rETH | EVK Vault erETH-2 (`erETH-2`) | rETH - Rocket Pool ETH | `0x218c9e961fC5f6c8280bA160365FAbe8A53Ec6E5` | covered by eulerVaultOwners |
| Unichain Vaults WETH | EVK Vault eWETH-4 (`eWETH-4`) | WETH - Wrapped Ether | `0x5ADAde21c703912547BFc8952fe1B52f09437E2A` | covered by eulerVaultOwners |

## Linea

| Label | Euler vault | Asset | Address | DefiLlama coverage |
| --- | --- | --- | --- | --- |
| Linea wstETH WETH | EVK Vault eWETH-1 (`eWETH-1`) | WETH - Wrapped Ether | `0xa8A02E6a894a490D04B6cd480857A19477854968` | explicit euler list |
| Linea wstETH wstETH | EVK Vault ewstETH-1 (`ewstETH-1`) | wstETH - Wrapped liquid staked Ether 2.0 | `0x359e363c11fC619BE76EEC8BaAa01e61D521aA18` | explicit euler list |
| Linea weETH WETH | EVK Vault eWETH-2 (`eWETH-2`) | WETH - Wrapped Ether | `0xF4712fC5E6483DE9e1Ff661D95DD686664327086` | explicit euler list |
| Linea weETH weETH | EVK Vault eweETH-1 (`eweETH-1`) | weETH - Wrapped eETH | `0x8955d7dCdE9bD9694B64732aD28fF2113eb217B4` | explicit euler list |

## Arbitrum

| Label | Euler vault | Asset | Address | DefiLlama coverage |
| --- | --- | --- | --- | --- |
| Arbitrum Vaults yUSND | EVK Vault eyUSND-1 (`eyUSND-1`) | yUSND - Yearn USND | `0x124BeC4d119bc4B5d250f0b0114f2087f8EeDB57` | explicit euler list |
| Arbitrum Vaults USND | EVK Vault eUSND-1 (`eUSND-1`) | USND - US Nerite Dollar | `0x4aD21eBbB639c21ccd9F1eaF388Cd91D015E02ee` | explicit euler list |
| Arbitrum Vaults reUSD | EVK Vault ereUSD-1 (`ereUSD-1`) | reUSD - Re Protocol Deposit Token | `0x8Ca487811a5e7599A5c68F49Ac1fE348371e4c46` | explicit euler list |
| Arbitrum Vaults USDC | EVK Vault eUSDC-7 (`eUSDC-7`) | USDC - USD Coin | `0x06b763aA769ad01F6859a56c5a856E47896e6a7F` | explicit euler list |
