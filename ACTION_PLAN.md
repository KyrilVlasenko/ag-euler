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
[] need to use adapter for AUSD -> loANZD BPT on swap-and-withdraw here: http://localhost:3000/lend/0x438cedcE647491B1d93a73d491eC19A50194c222/0/withdraw?network=143
[] use adapter everywhere where AUSD ->loANZD BPT route is needed: Borrow, Multiply, Supply collateral, withdraw AUSD - SHOULD BE FIXED ONCE NEW loANZD COLLATERAL IS LINKED TO AUSD POOL

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
