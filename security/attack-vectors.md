# Euler V2 Market Attack-Vector Checklist

## Purpose

Use this checklist before deploying a new Euler V2 market, adding collateral or debt assets to an existing cluster, changing an oracle route, or enabling custom hooks, adapters, operators, or swap flows.

This is the repository's working checklist derived from the security and attack-vector material in the local Euler documentation snapshot:

- [Donation Attacks](../reference/euler-docs-deployed/llms-full.md#donation-attacks)
- [EVK Security Considerations](../reference/euler-docs-deployed/llms-full.md#security-considerations)
- [EVC Known Limitations and Attack Vectors](../reference/euler-docs-deployed/llms-full.md#known-limitations-and-attack-vectors)
- [Price Oracles](../reference/euler-docs-deployed/llms-full.md#price-oracles)

This file is a deployment gate, not a substitute for an audit. Review the current upstream and local Euler documentation whenever it changes, and add newly documented vectors here.

## Required Review Record

Copy the table below into the partner's deployment notes and complete it for every market. Do not leave a row blank.

Allowed dispositions:

- `Not applicable` — explain why the vector cannot apply.
- `Mitigated` — identify the mitigation and attach evidence.
- `Blocked` — the market must not launch until the finding is resolved.

| Field | Value |
|---|---|
| Partner / market | |
| Chain ID | |
| Collateral vaults and assets | |
| Liability vaults and assets | |
| Oracle router and routes | |
| Hooks / adapters / operators / custom flows | |
| Reviewer | |
| Review date | |
| Documentation revision or commit | |

| ID | Vector | Applies? | Disposition | Evidence / mitigation | Owner |
|---|---|---|---|---|---|
| AV-01 | ERC-4626 donation and exchange-rate manipulation | | | | |
| AV-02 | Malicious or unsafe collateral vault | | | | |
| AV-03 | Token callback, transfer, and accounting incompatibility | | | | |
| AV-04 | Hook denial of service or liquidation interference | | | | |
| AV-05 | Nested-vault re-entrancy and failed liquidation | | | | |
| AV-06 | Oracle manipulation, failure, or misconfiguration | | | | |
| AV-07 | Unsafe LTV, liquidation, liquidity, and bad-debt parameters | | | | |
| AV-08 | Supply, borrow, utilization, and accounting-limit failure | | | | |
| AV-09 | Governance, factory-admin, and finalization risk | | | | |
| AV-10 | EVC privilege and arbitrary-call misuse | | | | |
| AV-11 | Deferred-check and read-only re-entrancy misuse | | | | |
| AV-12 | Misleading simulation against untrusted contracts | | | | |
| AV-13 | Controller privilege and lock-in risk | | | | |
| AV-14 | Operator compromise or overbroad delegation | | | | |
| AV-15 | Untrusted swapper, adapter, or custom-call outcome | | | | |
| AV-16 | PT/YT oracle-induced liquidation manipulation | | | | |

## Attack Vectors and Required Checks

### AV-01 — ERC-4626 Donation and Exchange-Rate Manipulation

**Threat.** An attacker manipulates an ERC-4626 share price by reducing circulating shares and donating assets directly to the vault. If the lending market values shares through the manipulable exchange rate, inflated collateral can be used to extract assets while a related share-denominated debt position becomes insolvent. Empty or near-empty external vaults are especially exposed.

The documented worst-case sequence is:

1. Build large, opposing collateral and debt positions with flash liquidity.
2. Loop borrowing and depositing of the ERC-4626 share token.
3. Redeem almost all shares, leave a very small share supply, and donate assets directly to the vault.
4. Let the donation multiply the reported exchange rate and collateral value.
5. Borrow against the inflated collateral and leave bad debt in the opposing account.

**Required checks.**

- Identify every ERC-4626 asset in the collateral, liability, and oracle-resolution paths, including nested vaults.
- Determine whether its exchange rate uses internal accounting or the token's raw `balanceOf(vault)`.
- Test whether direct donations, rounding, deposits, withdrawals, or privileged operations can increase or decrease `convertToAssets()` unexpectedly.
- Check the vault at empty, near-empty, and expected production liquidity.
- Determine whether the same vulnerable share asset can be both collateral and borrowable anywhere in the connected cluster.
- Trace third-party price feeds and wrapped exchange-rate oracles to ensure they do not ultimately inherit a manipulable ERC-4626 redemption rate.
- Model an atomic flash-loan attack using the configured LTVs, liquidity, supply caps, and borrow caps.

**Mitigations.** Prefer internally tracked balances and virtual deposits, as used by EVK vaults. Otherwise, do not list the vulnerable vault as collateral or do not make its shares borrowable. Use conservative supply and borrow caps. A wrapped exchange-rate oracle may cap increases or limit per-block rate changes, but it must be reviewed to ensure its own source is not manipulable.

**Evidence.** Record implementation links, exchange-rate tests, liquidity assumptions, attack simulation results, cap calculations, and the final oracle route.

### AV-02 — Malicious or Unsafe Collateral Vault

**Threat.** A badly implemented or malicious collateral vault can refuse to release assets during liquidation, misstate the value of its holdings, expose illiquid or manipulable assets, or use configurations that create bad debt.

**Required checks.**

- Verify the vault was created by the expected trusted factory, including `isProxy()` where applicable.
- Review the vault code, underlying asset, dependencies, governance, hooks, and configuration.
- Confirm that assets can be withdrawn or seized under liquidation conditions.
- Validate reported holdings and exchange rates independently.
- Assess the liquidity and manipulability of both the vault shares and underlying assets.
- Review any collateral accepted by the collateral vault itself; risk can be transitive.

**Mitigations.** Restrict accepted collateral to reviewed, known-good contracts or a validated registry/factory. Set exposure limits appropriate to liquidity and dependency risk.

**Evidence.** Record factory checks, audit references, contract versions, dependency maps, withdrawal/liquidation tests, and liquidity analysis.

### AV-03 — Token Callback, Transfer, and Accounting Incompatibility

**Threat.** A token or vault-share transfer that calls untrusted external code can introduce re-entrancy. Non-standard accounting behavior can also invalidate assumptions about how many assets were sent, received, or retained.

**Required checks.**

- Review `transfer`, `transferFrom`, deposit, withdrawal, mint, burn, and redemption behavior for external callbacks.
- Identify fee-on-transfer, rebasing, blacklist, pause, upgrade, proxy, ERC-777-style callback, or other non-standard behavior.
- Confirm token decimals and amount scaling in caps and oracle quotes.
- Test accounting with the exact deployed token contracts, not only standard mocks.
- Verify that privileged token roles cannot unexpectedly freeze, seize, mint, burn, or redirect market assets.

**Mitigations.** Reject incompatible assets, isolate them behind a reviewed adapter or wrapper where safe, limit exposure, and ensure all solvency and vault-status checks occur after token interactions.

**Evidence.** Record token implementation and proxy addresses, behavior tests, decimals, privileged roles, and any wrapper or adapter assessment.

### AV-04 — Hook Denial of Service or Liquidation Interference

**Threat.** A hook can maliciously or accidentally revert critical operations, especially liquidation. A bad hooked-operations bitfield or target can also leave deposits, withdrawals, borrowing, repayment, or liquidation disabled.

**Required checks.**

- Record each hook target, its code/version, governor, and hooked-operations bitfield.
- Review every path that can revert, consume excessive gas, depend on external state, or change behavior over time.
- Test liquidation, repayment, withdrawal, and emergency operations with the hook active.
- Confirm the hook cannot block liquidation or make a position impossible to unwind.
- For markets without an intended hook, verify `hookConfig()` has target `address(0)` and hooked operations `0` after activation.

**Mitigations.** Use audited, narrowly scoped hooks; avoid hooking liquidation unless required and proven safe; retain a reviewed emergency procedure when governance is intended.

**Evidence.** Record configuration calls, on-chain `hookConfig()` output, test transactions, audit references, and emergency controls.

### AV-05 — Nested-Vault Re-entrancy and Failed Liquidation

**Threat.** Using a vault as collateral for its own liability vault, directly or through a pricing/dependency cycle, can cause liquidation to fail because pricing re-enters the nested vault.

**Required checks.**

- Build a graph of every collateral, liability, vault-share resolution, and oracle dependency.
- Reject direct and indirect self-reference unless a specific implementation has been reviewed and liquidation tested.
- Simulate liquidation at multiple unhealthy positions and with every collateral ordering.

**Mitigations.** Prefer acyclic vault and oracle configurations. Remove nested collateral relationships that can re-enter the liability vault.

**Evidence.** Attach the dependency graph and successful liquidation simulations.

### AV-06 — Oracle Manipulation, Failure, or Misconfiguration

**Threat.** Incorrect, stale, manipulable, or unavailable prices can permit excess borrowing, cause unfair liquidation, or leave bad debt. Risks include short-term manipulation of market oracles, sustained depegs hidden by fixed-price oracles, unsafe exchange-rate oracles, wrong feeds or pair orientation, decimal errors, stale data, fragile cross-price routes, and compromised governed routers.

**Required checks.**

- Verify router, adapter, base, quote, unit of account, feed ID/source, decimals, inversion, heartbeat, deviation threshold, and maximum staleness on-chain.
- Test quotes for one whole base token and compare them with the primary source and an independent reference.
- Trace every hop of a cross-price route; the route is only as safe as its weakest source.
- Assess manipulation cost and available liquidity for market-based sources.
- For fixed or fundamental pricing, model sustained depeg and redemption scenarios.
- For ERC-4626 resolution through `convertToAssets()`, complete AV-01.
- For pull-based feeds such as Pyth, verify fresh-price updates occur before every dependent operation and liquidation, including update fees and failure behavior.
- Verify stale, zero, negative, extreme, paused, and unavailable-feed behavior.
- Confirm the frontend, bots, and custom batches use the same effective pricing route as the vault.
- Review who can change the router and how quickly a compromised source can be replaced.

**Mitigations.** Use reliable, sufficiently decentralized sources; conservative staleness and risk parameters; non-zero bid/ask spreads where appropriate; a non-zero liquidation cool-off period where required; and monitored governance capable of replacing unsafe routes. Finalize a router only after accepting that it cannot be repaired if a source later fails.

**Evidence.** Record on-chain getter output, sample quotes and timestamps, independent comparisons, manipulation/depeg analysis, route diagrams, pull-update tests, and governance controls.

### AV-07 — Unsafe LTV, Liquidation, Liquidity, and Bad-Debt Parameters

**Threat.** Excessive LTVs, inadequate liquidation incentives, insufficient market liquidity, price gaps, delayed liquidation, or an unsafe oracle can make positions unliquidatable before debt exceeds recoverable collateral. Excessive liquidation discounts can also amplify losses or liquidation spirals, while discounts that are too low may not attract liquidators.

**Required checks.**

- Set borrow and liquidation LTVs from volatility, correlation, oracle latency, market depth, and unwind-cost analysis.
- Preserve a sufficient gap between borrow LTV and liquidation LTV.
- Model adverse price moves, interest accrual, slippage, gas, congestion, oracle delay, and liquidation discount.
- Verify sufficient on-chain exit liquidity for each collateral at configured caps.
- Test partial and full liquidation, including the worst collateral ordering and stressed liquidity.
- Confirm liquidator infrastructure supports the chain, oracle type, token, hook, and custom flow.
- Decide whether bad-debt socialization is enabled and document depositor impact.
- Use LTV ramping for reductions that would otherwise trigger sudden liquidation.

**Mitigations.** Lower LTVs and caps, improve liquidation routes and bot coverage, use appropriate cool-off and maximum-discount values, and keep emergency governance procedures ready.

**Evidence.** Attach parameter models, stress tests, liquidity sources, liquidation test transactions, bot support confirmation, and the bad-debt policy.

### AV-08 — Supply, Borrow, Utilization, and Accounting-Limit Failure

**Threat.** Unbounded exposure or extreme utilization can deplete available liquidity and magnify loss. If supply, borrow, cash, or the interest accumulator approaches implementation limits, vault accounting can overflow or become undefined. Incorrect cap encoding or token decimals can silently create much larger exposure than intended.

**Required checks.**

- Recalculate encoded supply and borrow caps using the deployed token's actual decimals.
- Confirm caps on-chain and compare them with intended human-readable values.
- Set caps from available liquidity, circulating supply, manipulation cost, and maximum acceptable loss.
- Review utilization controls and withdrawal liquidity under stressed borrowing.
- Bound interest-rate behavior and model long periods at maximum utilization/rate.
- Check numerical limits for total supply, borrows, cash, shares, and the interest accumulator.

**Mitigations.** Use conservative caps, utilization controls, monitored IRMs, and explicit alerts well before numerical or liquidity limits.

**Evidence.** Record cap calculations and decoding, on-chain values, utilization stress tests, and overflow bounds.

### AV-09 — Governance, Factory-Admin, and Finalization Risk

**Threat.** A compromised or mistaken governor can change LTVs, oracles, hooks, caps, and other market controls. Upgradeable vaults also trust the factory admin. Conversely, immutable or finalized components cannot respond to a newly discovered bug, unsafe collateral, or failed oracle.

**Required checks.**

- Identify the governor, governor admin, router governor, factory admin, pause/emergency roles, multisig threshold, and upgrade path.
- Enumerate the exact powers of every role and all transitive protocol dependencies.
- Confirm role addresses and ownership on-chain.
- Assess whether timelocks allow users to respond without preventing urgent incident response.
- Decide deliberately which components remain governed, become finalized, or remain upgradeable.
- Define emergency procedures for oracle failure, collateral failure, hook failure, compromised keys, and critical implementation bugs.

**Mitigations.** Use transparent multisigs, timelocks for sensitive routine changes, narrowly scoped governor contracts where possible, monitoring, and documented emergency playbooks.

**Evidence.** Record role getter output, signer/threshold policy, timelocks, allowed actions, finalization decisions, and incident owners.

### AV-10 — EVC Privilege and Arbitrary-Call Misuse

**Threat.** The EVC can call arbitrary contracts with arbitrary calldata. Giving the EVC special privileges or allowing it to retain tokens or native currency creates a powerful target and can expand the impact of a malicious batch or integration.

**Required checks.**

- Verify the EVC has no special privilege in market, token, adapter, or hook contracts beyond the documented integration requirements.
- Confirm the EVC does not retain tokens or native currency outside temporary mid-batch balances.
- Ensure custom vaults cannot make unrestricted calls to arbitrary contracts.
- Restrict custom-call targets and collateral vaults to reviewed addresses or validated registries.

**Mitigations.** Keep the EVC unprivileged, make batches settle all temporary balances, and allowlist trusted call targets.

**Evidence.** Record role/allowance checks, end-of-batch balance tests, and custom-call allowlists.

### AV-11 — Deferred-Check and Read-Only Re-entrancy Misuse

**Threat.** EVC account and vault checks may be deferred until the end of an execution context. Integrations that read controller/collateral sets mid-batch, authenticate the wrong account, omit required status checks, or apply incompatible re-entrancy guards can make unsafe decisions or break critical operations.

**Required checks.**

- Use `callThroughEVC` or the equivalent recommended pattern.
- Authenticate through `getCurrentOnBehalfOfAccount` when called via EVC.
- Require account and vault status checks after every operation that can affect solvency or vault invariants.
- Implement `checkAccountStatus` and, where needed, `checkVaultStatus` with correct access and execution-context checks.
- Do not rely on controller or collateral sets while checks are deferred.
- Test direct calls and EVC calls; ensure status-check callbacks do not deadlock a re-entrancy guard.
- Test malicious callback attempts from collateral and token contracts.

**Mitigations.** Follow the EVC utility/modifier patterns, keep intermediate state consistent, restrict untrusted calls, and use the documented callback-compatible re-entrancy pattern.

**Evidence.** Record code references, unit/fuzz/invariant tests, callback tests, and successful end-of-batch solvency failures.

### AV-12 — Misleading Simulation Against Untrusted Contracts

**Threat.** External contracts can observe the EVC simulation flag and behave differently during simulation than during execution. A successful simulation therefore does not prove safety when a batch calls untrusted code.

**Required checks.**

- Identify every external target reached by simulated transactions.
- Treat results involving untrusted or mutable contracts as estimates, not security guarantees.
- Enforce all outcome, balance, debt, slippage, and solvency checks on-chain during real execution.

**Mitigations.** Do not approve a market or transaction solely because simulation succeeds. Restrict targets and verify outcomes atomically.

**Evidence.** Record external targets and the execution-time invariants that make simulation divergence harmless.

### AV-13 — Controller Privilege and Lock-In Risk

**Threat.** Enabling a controller subjects all enabled collateral in the account to that controller's rules. Only the controller can normally disable itself, so a malicious or defective controller can control collateral or prevent a clean exit.

**Required checks.**

- Use only reviewed controllers and verify their deployed bytecode/version.
- Confirm standard `disableController` behavior after all debt is repaid.
- Test repay, disable, and collateral-withdrawal flows, including paused or stressed states.
- Ensure interfaces clearly identify the controller being enabled.

**Mitigations.** Restrict integrations to trusted controllers, isolate strategies in sub-accounts, and document emergency unwind procedures.

**Evidence.** Record controller verification and successful enable/repay/disable tests.

### AV-14 — Operator Compromise or Overbroad Delegation

**Threat.** Operator permissions are broad and effectively binary for an authorized sub-account. A compromised, malicious, or defective operator can act across the delegated position.

**Required checks.**

- Review and audit every operator contract and its upgrade/governance controls.
- Limit each operator to a dedicated sub-account where practical.
- Test permission revocation, EVC lockdown mode, and permit-disabled mode.
- Monitor operator actions and define rapid-revocation procedures.
- Ensure no deployment script or interface grants an operator unintentionally.

**Mitigations.** Authorize only trusted operators, isolate permissions by sub-account, and maintain tested emergency revocation controls.

**Evidence.** Record operator addresses and code versions, permissions, revocation tests, monitoring, and incident contacts.

### AV-15 — Untrusted Swapper, Adapter, or Custom-Call Outcome

**Threat.** The Swapper is intentionally untrusted, and custom adapters or handlers add external calls and protocol dependencies. Without execution-time verification, a malicious route, excessive slippage, incorrect recipient, missing sweep, or unexpected token behavior can leave insufficient collateral, excessive debt, or stranded assets.

**Required checks.**

- Put the trusted `SwapVerifier` after the Swapper in every EVC batch and verify the intended result.
- Enforce minimum received, maximum spent/debt, recipient, deadline, slippage, and no-stranded-balance conditions on-chain.
- Review and allowlist custom handler/adapter targets and exact selectors.
- Trace all external calls, approvals, callbacks, and token custody.
- Test zero liquidity, high price impact, partial fill, revert, stale quote, malicious return data, and fee-on-transfer behavior.
- For leverage/multiply flows, include a debt safety margin and test end-of-batch solvency under worst permitted slippage.

**Mitigations.** Trust the verifier and explicit invariants rather than the route executor, constrain call targets, minimize approvals, sweep residual balances safely, and use conservative slippage and debt bounds.

**Evidence.** Record representative batch calldata, verifier configuration, target allowlists, failure-case tests, and balance/debt assertions.

### AV-16 — PT/YT Oracle-Induced Liquidation Manipulation

**Threat.** An attacker can deliberately lower the oracle value of Principal Token (PT) collateral by aggressively buying the corresponding Yield Token (YT). A typical Pendle YT purchase can mint paired PT and YT from SY, sell the unwanted PT into the PT/SY market, and deliver the YT to the buyer. In a shallow market, this creates concentrated PT sell pressure, raises the implied yield, and lowers the PT market price. If an Euler market consumes that price directly or through a short TWAP, the attacker may be able to force leveraged PT-backed accounts into liquidation and capture the liquidation discount, discounted PT, arbitrage, or PT/YT recombination value.

The attack path is:

`Buy YT aggressively → paired PT is sold into a thin PT/SY market → PT price and PT oracle/TWAP fall → leveraged PT collateral crosses liquidation LTV → attacker or aligned liquidator captures discounted collateral → liquidation-related PT sales may deepen the move`

This is an economic oracle attack, not necessarily an oracle implementation bug or misconfiguration. A TWAP can report the manipulated market accurately and still provide too little economic security for the lending exposure that depends on it.

**Incident context.** On August 25, 2026, a price move in Pendle's PT-reUSD market triggered liquidations in a third-party PT-reUSD/USDC Morpho market. [Pendle stated](https://x.com/pendle_fi/status/2092171615631249863) that the oracle was configured correctly and operated as designed; public reporting described a roughly 3% PT price decline flowing through a 15-minute market-price reference and liquidating highly leveraged positions with health factors below approximately 1.03. The incident reportedly produced no bad debt, but it demonstrates that correct oracle operation and lender solvency do not by themselves prevent economically induced borrower liquidations. This was not an Euler incident, but the same mechanism applies to any Euler market that accepts PT collateral and uses a manipulable PT market price.

**Conditions that increase feasibility.**

- PT-backed debt and collateral exposure are large relative to the usable depth of the exact Pendle market observed by the oracle.
- Many borrowers are looped or concentrated immediately below liquidation LTV, creating a liquidation cliff.
- The oracle uses spot pricing or a TWAP that is inexpensive to move and hold for its full observation window.
- YT is inexpensive, particularly as maturity approaches, so relatively little net capital can create a large quantity of paired PT sell flow.
- The liquidation discount, arbitrage, recombination, or post-liquidation PT recovery exceeds the attacker's all-in manipulation cost.
- The attacker can also liquidate, control the liquidation path, or use temporary liquidity to capture most of the available incentive.
- Liquidators must sell seized PT through the same shallow pool, creating a feedback loop of lower PT prices and further liquidations.
- The oracle passes a downward Pendle market price even while the underlying asset, SY conversion rate, redemption value, or a fundamental PT curve remains stable.

**Required quantitative test.** For every PT-backed market, model oracle declines of at least **1%, 2%, 3%, 5%, and 10%**, sustained for the **entire configured observation period**. Repeat the analysis across representative dates to maturity and stressed pool states; a one-time spot quote is not sufficient.

For each shock `Δ` and observation window `T`, calculate:

```text
C_manip(Δ, T) = net cost to create and sustain the oracle move
Π_extractable(Δ) = liquidation incentive + arbitrage/recombination value
                   + MEV/OEV captured + other recoverable value
```

`C_manip` must be net of the value recovered when the YT/PT position is unwound and must include pool fees, price impact, TWAP maintenance trades, financing, hedging, gas, MEV leakage, inventory risk, and exit losses. Do not use gross trade notional as manipulation cost.

Block or reduce the market if:

```text
C_manip(Δ, T) <= Π_extractable(Δ)
```

The manipulation cost should be materially greater than extractable profit under conservative assumptions, not merely one dollar above break-even. The market review must state the required safety multiple and justify it.

At every shock level, also calculate:

- total accounts and debt that become liquidatable;
- PT collateral seized and the maximum liquidation discount;
- the share of liquidation value one actor could realistically capture;
- the price impact from selling or hedging seized PT;
- any second-round liquidations caused by that sale; and
- lender bad debt if liquidations are delayed or cannot be executed profitably.

Plot or tabulate liquidatable debt against oracle price. Flag **liquidation cliffs** where a small additional price move unlocks a disproportionate amount of debt or collateral.

**Required market and oracle checks.**

- Verify the exact PT, YT, SY, Pendle market, expiry, oracle contract, oracle type (`PT_TO_SY` or `PT_TO_ASSET`), TWAP duration, observation cardinality, and every downstream price hop.
- Confirm the oracle has enough initialized observations for the full configured TWAP window; never use a zero-duration spot rate in production.
- Measure the pool's executable depth and price impact in both directions. TVL alone is not a depth or manipulation-cost measure.
- Simulate the actual YT-buy route, including paired PT minting/sale, limit orders, aggregators, fees, AMM bounds, and any external PT/YT venues.
- Run the manipulation for the full TWAP duration rather than extrapolating from one trade. Include the cost of defending the price against arbitrageurs throughout the window.
- Repeat at current liquidity, stressed liquidity, cap utilization, different implied yields, and multiple times to maturity. Explicitly test the period when YT is cheap near expiry.
- Inspect every borrower's health-factor distribution, leverage, and correlated accounts rather than relying only on aggregate collateral or debt.
- Compare Pendle PT price with SY value, underlying price, direct redemption value, a fundamental maturity curve, and external PT markets. Model both deliberate manipulation and genuine underlying impairment.
- Test liquidation execution and PT disposal before and after maturity. Pendle documents different unwind paths: PT is generally sold for SY before maturity and redeemed after maturity.
- Include flash liquidity, private order flow, MEV/OEV, self-liquidation, and attacker/liquidator coordination in the profit model.
- Verify that caps are specific to the PT maturity and cannot grow beyond the tested pool depth without a new review.
- Re-run the assessment after material changes in Pendle liquidity, oracle duration or composition, Euler exposure, LTVs, liquidation incentives, borrower concentration, or time to maturity.

**Mitigations.**

- Cap PT collateral and associated debt according to manipulation cost and liquidation depth, not headline Pendle TVL or total lending-market TVL.
- Set borrow and liquidation LTVs with enough buffer to avoid large position clusters within an economically cheap oracle move.
- Consider a longer TWAP when it materially raises sustained manipulation cost, while separately modeling the bad-debt and unfair-liquidation risks created by delayed recognition of genuine price changes.
- Prefer a reviewed PT-specific hybrid oracle over a pure pool TWAP where appropriate. A hybrid may compare market, SY, underlying, redemption, and maturity-curve values, but its choice of minimum, maximum, clamps, and rate-of-change limits must be modeled in both directions. A fundamental floor can protect borrowers during manipulation while exposing lenders during a real impairment; a market-price minimum can protect lenders while making induced liquidations easier.
- Add deviation monitoring and carefully designed circuit breakers or emergency controls. Do not introduce a hook that can permanently block legitimate liquidation.
- Reduce extractable liquidation value where possible while retaining enough incentive for prompt liquidation under genuine stress.
- Monitor PT/YT trades, implied-yield jumps, oracle-versus-fundamental divergence, TWAP trajectory, pool depth, borrower health-factor concentration, and liquidation activity in real time.
- Freeze exposure growth and repeat the review when the economic-security margin falls below the approved safety multiple.

**Primary security principle.** Do not allow leveraged exposure that depends on an oracle to grow beyond the economic security of the market used to determine that oracle. Large lending TVL is not inherently unsafe; the dangerous condition is when manipulating a thin pricing market is materially cheaper than the liquidation and arbitrage value unlocked downstream.

**Evidence.** Record the Pendle contracts and expiry, oracle configuration and readiness, pool-state snapshots, executable-depth curves, YT-buy/PT-sell simulations, full-window manipulation costs, borrower health-factor distribution, liquidation-cliff table, extractable-profit model, liquidation/unwind tests, cap and LTV derivation, monitoring thresholds, and the approved safety multiple.

**Technical references.** See Pendle's guidance on [PT collateral risk](https://docs.pendle.finance/pendle-v2-dev/Oracles/PTAsCollateral), including oracle exploitation and liquidation-liquidity analysis; its [PT/LP oracle integration guide](https://docs.pendle.finance/pendle-v2-dev/Oracles/HowToIntegratePtAndLpOracle), including TWAP duration, initialization, and PT liquidation paths; and the Euler governance forum's [oracle policy for PT and derivative markets](https://forum.euler.finance/t/objective-labs-oracle-policy-for-euler-dao-markets/1693), which recommends PT-specific hybrid pricing rather than relying only on a pure Pendle TWAP.

## Final Sign-Off

Before launch, confirm all of the following:

- [ ] Every AV row has a disposition and evidence.
- [ ] Every `Not applicable` row explains why it cannot apply.
- [ ] No `Blocked` finding remains.
- [ ] All mitigations are reflected in deployed on-chain configuration.
- [ ] Liquidation and emergency-unwind paths were tested against deployed contracts.
- [ ] Oracle routes and quotes were independently verified.
- [ ] Supply, borrow, LTV, liquidation, and hook settings match the reviewed values.
- [ ] Governance and monitoring owners accepted their ongoing responsibilities.
- [ ] The completed review is stored with the partner's deployment records.
