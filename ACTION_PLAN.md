# GOAL
Finalize and launch ZRO, VVV, and AERO markets on Base.

# BALANCER - ACTION PLAN
[x] test all zaps and supply borrow actions (20 min)
[X] check if aprs are calculated correctly on our end (10 min) - NO PRICE FOR AUSD BPT
[X] fix pricing issues (30 min)
[] create a filter system to show only markets of specific campaign (30 min)
  [] maybe remove the onboarding page
[] frontend small tweaks
[] test the new filter solution (10 min)
[] share a new filtered link with balancer team (10 min)

## Elements to fix on FE
[] crasy high negative apr number on AUSD borrow positions and negative asset value
[] Incomplete pricing: Some assets in your portfolio don't have price data available. The displayed value may be higher than shown.
[] borrowing takes a while
[] gray test on button <button class="w-full py-16 rounded-12 text-body-md font-semibold transition-all bg-accent-400 text-euler-dark-900 hover:bg-accent-300 shadow-lg hover:shadow-xl"> Zap Again </button>
[] white stroke on the block - update to gray <div class="relative p-16 rounded-16 flex flex-col gap-16 bg-euler-dark-400 border border-border-subtle shadow-[var(--ui-form-field-shadow)]" style="overflow: hidden;"><div class="absolute top-0 left-0 right-0 h-[3px] bg-[rgba(200,200,200,0.1)] rounded-t-8 after:content-[''] after:absolute after:top-0 after:left-[-50%] after:w-[40%] after:h-[3px] after:bg-euler-dark-700 after:rounded-tl-8 after:animate-[loading_1.5s_linear_infinite]" style="display: none;"></div><div class="flex justify-between flex-wrap gap-8 items-start"><p class="text-content-tertiary shrink-0">Projected earnings per month</p><div class="ml-auto text-right"><p class="text-content-tertiary"><span class="text-content-primary text-p2">0</span> WMON  ≈ $0</p></div></div><div class="flex justify-between flex-wrap gap-8 items-center"><p class="text-content-tertiary shrink-0">Supply APY</p><div class="ml-auto text-right"><p class="text-p2"><span class="text-content-primary">5.63%</span></p></div></div></div>
[] Add logos to tokens on Rewards tab

## New issues
[] need to use adapter for AUSD -> loANZD BPT on swap-and-withdraw and swap-and-supply here:
  [] http://localhost:3000/lend/0x438cedcE647491B1d93a73d491eC19A50194c222/0/withdraw?network=143
  [] http://localhost:3000/position/17/supply?collateral=0x2067936155c7DB57b1cdCF776B04B9678c245626&network=143
  [] http://localhost:3000/lend/0x2067936155c7DB57b1cdCF776B04B9678c245626/0/withdraw?network=143
  [] http://localhost:3000/position/18/repay?network=143
[x] use adapter everywhere where AUSD ->loANZD BPT route is needed: Borrow, Multiply, Supply collateral, withdraw AUSD - SHOULD BE FIXED ONCE NEW loANZD COLLATERAL IS LINKED TO AUSD POOL
[x] Net APY % is not displayed on position borrow pages: http://localhost:3000/position/19/borrow?network=143


## If have time:
[] update token names to drop "wn" prefixes: AUSD-USDC-USDT0
[] disable onboardnig screen to people can land directly on borrow page

# BASE MARKET - ACTION PLAN
[x] Adjust Supply rate for USDC to be 15% at 90% kink
[x] Adjust Borrow rate for ETH to be 7% at 90% kink (Supply rate - 6%)
[x] Add AERO as a collateral and borrowable asset
[x] Update and push new lables to Github to add AERO market on local frontend
[x] Add token logos
[X] Add VIRTUAL as collateral
[X] Test all assets on all markets
  [x] Supply
  [x] Witdraw
  [x] Supply collateral
  [x] Borrow
  [x] Repay
  [X] Withdraw collateral
  [X] Multiply
[x] Fix issues if any
[x] Update and deploy lables to show new markets on euler.alphagrowth.io
[x] Final tests: supply collateral and borrow the same collateral on all markets
[x] clone lateast euler-labels and euler-oracle-checks and add our lables
[x] Swap my dev wallet to AG multisig?
[x] Ping Kasper to pull new lables and oracle-checks to their main repo
[] Make sure everything looks good on the euler's frontend

Issues
[x] shMON Rewards token has no logo https://euler.alphagrowth.io/portfolio/rewards?network=143
[x] some borrowing positions take a while to borrow - probably an rpc issue
  [x] happens only when spending cap approval is required - share code with claude
[x] cannot multiply loanz
  [x] check if it was working on previous versions
[x] cannot swap collateral for loas - DISABLE swap collateral feature entirely
[x] need to update link preview with custom alphagrowth vaults descriptoin
[x] change governor to our multisig 0x4f894Bfc9481110278C356adE1473eBe2127Fd3C in labels
[x] make sure enso retries 3 times here when finding the swap routes: https://euler.alphagrowth.io/borrow/0x578c60e6Df60336bE41b316FDE74Aa3E2a4E0Ea5/0x75B6C392f778B8BCf9bdB676f8F128b4dD49aC19?network=143
[x] add "Please select swap route" warning message when using swap-and-supply features

## Bugs to fix for base markets
[] (our frontend inssue only - no need to fix) all deposit transactions pass from the second try due to a spending cap approval issue 
[] there are currently 6 markets (one for each asset). on each of those markets you can only borrow the underlying asset with 5 other assets as collateral. you cannot borrow collateral assets against the underlying within the same market - you need to go the the specific market for that underlying. So, really this should be just one big market with all collateral and underlying assets available to borrow and borrow against. OR maybe it's how it should be? I thin that's how it should be: https://app.euler.finance/positions/0x0A1a3b5f2041F33522C4efc754a7D096f880eE16/0x7b181d6509DEabfbd1A23aF1E65fD46E89572609?network=base
[] https://app.euler.finance/vault/0x3Bd428B28C52f3534CC78075799CA798e4BcE5a8?network=base&tab=savings
  [x] vault name is "unknown"
  [x] oracle is unknown - should be chainlink for all
  [x] risk curator is unknown - should be AG - fixed on our FE, might be cashed on EULER's FE
  [x] vault type is unknown - should be governed - fixed on our FE, might be cashed on EULER's FE
  [] NEED TO CHECK reUSD VAULT CODE FOR ALL THESE --^

## Latest issues
[x] Incentives are being doublecounded on AUSD borrow vault: it counts merkl rewards + the same merkl rewards from Balancer via Defillama. Need to enable merkl rewards, and only track yiled form yieldbaring tokens from Balancer.
[x] Price impact on loAZND borrow vault is too high - it's not an actual nubmer, so need to disable
[] IR curves are too high. need to decrease to 8% and 80% for AUSD, and 16% and 80% for WMON


# BASE AI MARKET LAUNCH
[] Check drop twenty and SUPPLY caps for each asset
  [] VVV: 330,000	($6.85M)
  [x] VIRTUAL: 3,300,000 ($2.44M)
  [] MOR: 18,000 ($40k)
  [] ZRO: 180,000	($230k)
  [x] AERO: 15,000,000 ($5,55M)
  [] USDC: 10,000,000 ($10M)
  [] WETH: 5,500 ($10M)
[] Check drop twenty and BORROW caps for each asset
  [] VVV: 170,000	($4.5M)
  [] VIRTUAL: 2,250,000 ($2M)
  [] MOR: 11,500 ($35k)
  [] ZRO: 74,000 ($120k)
  [] AERO: 15,000,000 ($5.55M)
  [] USDC: 10,000,000 ($10M)
  [] WETH: 5,500 ($10M)
[] Check LTVs and LLTV based on price volatility of each asset
  [] VVV: LTV: 80, LLTV 85, Bonus: 15
  [] VIRTUAL: LTV: 80, LLTV 85, Bonus: 15
  [] MOR: LTV: 75, LLTV 80, Bonus: 15
  [] ZRO: LTV: 80, LLTV 85, Bonus: 15
  [] AERO: LTV: 80, LLTV 85, Bonus: 15
  [] USDC/ETH: LTV: 85, LLTV 87, Bonus: 15
  [] USDC/other tokens: LTV: 80, LLTV 85, Bonus: 15
  [] WETH/USDC: LTV: 85, LLTV 87, Bonus: 15
  [] WETH/other tokens: LTV: 80, LLTV 85, Bonus: 15
[] Check IR curves for each asset (kink, borrow@base, @kink, @max)
  [] VVV: 90% kink, 0% @base, 12% @kink, 120% @max  
  [] VIRTUAL: 90% kink, 0% @base, 12% @kink, 100% @max  
  [] MOR: 90% kink, 0% @base, 12% @kink, 100% @max
  [] ZRO: 90% kink, 0% @base, 10% @kink, 100% @max  
  [] AERO: 90% kink, 0% @base, 16% @kink, 120% @max
  [] USDC: 90% kink, 0% @base, 8% @kink, 100% @max
  [] WETH: 90% kink, 0% @base, 4% @kink, 80% @max
[x] Launch local frontend and see the current market configuration. 
[] Add MOR to the mix - NEED ORACLE
  [] Deploy MOR vault
  [] Link it with USDC and ETH collateral
[x] Configure all marekts
  [x] Ping brian to sell in the first transaction. 
  [x] Sign second transaction to configure all markets. 
[x] Check and update labels on all markets 
[x] Test everything on local frontend. 
[] Ask Euler to whitelist all new markets

# 0G MORPHO MARKET LAUNCH
[x] Check what Vault owner can do. 
  [x] If it has any control over the vault or allocation, ask Kyle to transfer ownership to AlphaGrowth multisig - WAITING
[x] Confirm LLTV rates for all assets 
  [x] W0G: 86%
  [x] USDC: 94%
[x] Confirm supply caps for each asset 
  [x] W0G: 
  [x] USDC: 
[] Ask Oku to list new vaults on their frontend 
[] Set up a call with 0G team

# MONAD AUSD/AUSD-PT MARKET
[] Addresses
  [] AUSD token: https://monadscan.com/token/0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a
  [] Pendle AUSD PT token: https://monadscan.com/address/0x9fc74f8ed616b5baf52a170caa97d6d3898602d1
[] Oracles
  [] Unit of account: AUSD token: https://monadscan.com/token/0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a
  [] AUSD token - no oracle needed, already in the unit of account
  [] Pendle AUSD-PT token - pendle oracle (need to figure out)
[] Collaterals
  [] Pendle AUSD PT token
[] Borrow assets
  [] AUSD token
[] Supply caps
  [] AUSD token - unlimited
  [] Pendle AUSD PT token - $6M
[] Borrow caps
  [] AUSD token - unlimited
  [] Pendle AUSD PT token - 0
[] LTVs / LLTVs / Max liq. bonus
  [] Pendle AUSD PT token: 90/94/15
[] IRM curves (kink %, borrow rate at 0%, at kink, at 100%)
  [] AUSD/AUSD-PT: kink at 90%, borrow rate: 0%, 6%, 50%
  
# MONAD AUSD/earnAUSD-PT MARKET
[] Addresses
  [] AUSD token: https://monadscan.com/token/0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a
  [] Pendle earnAUSD PT token: https://monadscan.com/address/0xdaf216939826acaba0c2312f7e30a890213845cd
[] Oracles
  [] Unit of account: AUSD token: https://monadscan.com/token/0x00000000eFE302BEAA2b3e6e1b18d08D69a9012a
  [] AUSD token - no oracle needed, already in the unit of account
  [] Pendle earnAUSD-PT token - pendle oracle (need to figure out)
[] Collaterals
  [] Pendle earnAUSD PT token
[] Borrow assets
  [] AUSD token
[] Supply caps
  [] AUSD token - unlimited
  [] Pendle earnAUSD PT token - $2.5M
[] Borrow caps
  [] AUSD token - unlimited
  [] Pendle earnAUSD PT token - 0
[] LTVs / LLTVs / Max liq. bonus
  [] Pendle earnAUSD PT token: 88/92/15
[] IRM curves (kink %, borrow rate at 0%, at kink, at 100%)
  [] AUSD/earnAUSD-PT: kink at 90%, borrow rate: 0%, 12%, 60%
