<a id="derived-distributions" name="derived-distributions"></a>

# 4. Derived distributions

[Specification contents](../README.md#table-of-contents) · [← Ledger effects](ledger-effects.md) · [Appendices →](appendices.md) · [Verification record](../verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/chapters/derived-distributions.md)

> **Scope:** These rules and examples remain documented; stake and voting tests are deferred.

> **Determine stake and voting power from the resulting ledger under their existing rules.**

## Table of contents

<ul type="none"><li>
<details>
  <summary><a href="#ds-stake">4.1 Stake</a></summary>
  <div><ul type="none"><li>
      <div>•&numsp;<a href="#ds-stake-n01">4.1.1 N01 - counts the full ADA in min-ADA outputs under the existing staking rules</a></div>
      <div>•&numsp;<a href="#ds-stake-n02">4.1.2 N02 - counts only application ADA in deposit-backed outputs under the existing staking rules</a></div>
      <div>•&numsp;<a href="#ds-stake-n03">4.1.3 N03 - does not add the global Store balance to stake totals</a></div>
      <div>•&numsp;<a href="#ds-stake-n04">4.1.4 N04 - Derive stake from applied allocations</a></div>
      <div>•&numsp;<a href="#ds-stake-n05">4.1.5 N05 - Derive stake from applied releases</a></div>
      <div>•&numsp;<a href="#ds-stake-n06">4.1.6 N06 - Ignore unapplied collateral</a></div>
      <div>•&numsp;<a href="#ds-stake-n07">4.1.7 N07 - Derive stake from collateral on phase-2 failure</a></div>
      <div>•&numsp;<a href="#ds-stake-n08">4.1.8 N08 - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects</a></div>
  </li></ul></div>
</details>
<details>
  <summary><a href="#ds-voting">4.2 Voting</a></summary>
  <div><ul type="none"><li>
      <div>•&numsp;<a href="#ds-voting-n01">4.2.1 N01 - preserves the expected voting distribution from eligible funds while excluding allocated UTxO capacity deposits and Store balance</a></div>
  </li></ul></div>
</details>
</li></ul>

<a id="ds-stake" name="ds-stake"></a>

## 4.1 Stake

> **Determine which output ADA contributes under the existing staking rules.**
>
> Min-ADA output: full ADA · Deposit-backed output: application ADA · External deposit: no additional stake.

**Decision:** Exclude DepositStore UTxO capacity deposits from stake for the current prototype.

Apply the existing staking eligibility and delegation rules to the output's ADA contribution:

```math
\text{stakeContribution}(\text{output}) =
\begin{cases}
\text{full ADA in output} & \text{if output is implicit} \\
\text{application ADA in output} & \text{if output is deposit-backed}
\end{cases}
```

An eligible min-ADA output containing 10 ADA therefore contributes 10 ADA. A deposit-backed output containing 8 application ADA with a 2 ADA allocated deposit contributes only 8 ADA where otherwise eligible. Do not attribute its external allocated deposit to its staking credential or add the global Store balance separately to stake totals.

An allocation or release affects stake through the outputs and other existing stake updates actually applied. It creates no independent Store attribution. Ordinary success leaves collateral settlement and collateral return unapplied; accepted phase-2 failure derives stake effects from collateral consumption and return, without applying ordinary outputs or ordinary Store operations.

Existing registration, eligibility, delegation and snapshot timing remain in force. A contribution amount is not a claim that every output currently participates in stake. The exclusion also does not remove Store ADA from monetary conservation under `DS-STATE-CONSERVATION`. Voting weight is checked separately under `DS-VOTING`.

<a id="ds-stake-n01" name="ds-stake-n01"></a>

### 4.1.1 N01 - counts the full ADA in min-ADA outputs under the existing staking rules

Given a min-ADA output eligible under the existing staking rules, use its full output ADA as its stake contribution. Keeping the legacy minimum inside that value does not create an external amount to subtract.

<a id="ds-stake-n02" name="ds-stake-n02"></a>

### 4.1.2 N02 - counts only application ADA in deposit-backed outputs under the existing staking rules

Given an eligible deposit-backed output, count its application ADA and exclude its externally allocated deposit. For 8 application ADA and a 2 ADA deposit, the contribution base is 8 ADA.

<a id="ds-stake-n03" name="ds-stake-n03"></a>

### 4.1.3 N03 - does not add the global Store balance to stake totals

Given a nonzero global Store balance, do not add that pot separately to stake totals or assign it to output credentials. Only otherwise eligible output ADA follows the existing stake rules.

<a id="ds-stake-n04" name="ds-stake-n04"></a>

### 4.1.4 N04 - Derive stake from applied allocations

```math
\begin{aligned}
\text{ordinary success} \land \text{net allocation}>0
\implies\quad
\text{stake effects}
&= \text{existing stake rules}(\text{applied ordinary UTxO effects})
\end{aligned}
```

Given an ordinary successful allocation, derive stake effects from the ordinary outputs and existing stake updates actually applied. Funding the external deposit creates no separate credited stake.

<a id="ds-stake-n05" name="ds-stake-n05"></a>

### 4.1.5 N05 - Derive stake from applied releases

```math
\begin{aligned}
\text{ordinary success} \land \text{net release}>0
\implies\quad
\text{stake effects}
&= \text{existing stake rules}(\text{applied ordinary UTxO effects})
\end{aligned}
```

Given an ordinary successful release, derive stake effects from the resulting ordinary outputs under existing eligibility rules. The released amount does not create an additional Store attribution beside those effects.

<a id="ds-stake-n06" name="ds-stake-n06"></a>

### 4.1.6 N06 - Ignore unapplied collateral

```math
\text{ordinary success} \implies
\text{additional stake effects from collateral} = 0
```

Given ordinary success with supplied collateral and a possible return, do not apply additional stake effects from collateral settlement or that return. Include an input shared with ordinary spending: its ordinary consumption affects stake once, while inputs used only as collateral remain live.

<a id="ds-stake-n07" name="ds-stake-n07"></a>

### 4.1.7 N07 - Derive stake from collateral on phase-2 failure

```math
\begin{aligned}
\text{accepted phase-2 failure} \implies\quad
\text{stake effects}
&= \text{existing stake rules}(\text{applied collateral UTxO effects}) \\
\text{stake effects from unapplied ordinary activity} &= 0
\end{aligned}
```

Given an accepted phase-2 failure, compare the resulting stake distribution with the independently selected collateral consumption and return effects under existing rules. Cover absent, min-ADA and deposit-backed returns and an input shared with ordinary spending. Unapplied ordinary outputs, allocations and releases add no stake effects.

<a id="ds-stake-n08" name="ds-stake-n08"></a>

### 4.1.8 N08 - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects

Given allocation, release or collateral effects, observe positive eligible stake alongside ineligible credentials and distinct delegation destinations before and after the existing snapshot boundary. Compare the expected distribution under unchanged registration, eligibility, delegation and timing rules. Excluding external deposits must neither remove eligible application ADA nor create eligibility or apply a snapshot early.

<a id="ds-voting" name="ds-voting"></a>

## 4.2 Voting

> **Exclude external deposits from additional voting power.**
>
> Application ADA follows existing eligibility rules. Store ADA remains part of monetary conservation, but adds no voting weight.

**Decision:** Exclude DepositStore UTxO capacity deposits from voting power for the current prototype.

ADA held in the Store creates no additional voting weight. Do not attribute a deposit-backed output's allocated deposit to its credential or count the global Store balance separately in voting distributions. The application ADA remaining in outputs continues through existing eligibility, delegation and snapshot rules.

This concerns the resulting voting distribution, separately from the stake observations in `DS-STAKE`. The excluded Store ADA still exists in the monetary total checked by `DS-STATE-CONSERVATION`.

<a id="ds-voting-n01" name="ds-voting-n01"></a>

### 4.2.1 N01 - preserves the expected voting distribution from eligible funds while excluding allocated UTxO capacity deposits and Store balance

Compare the complete resulting voting distribution with an independent expectation under existing eligibility, delegation and snapshot rules. Include positive eligible min-ADA output ADA and deposit-backed application ADA, other existing eligible funds, ineligible and differently delegated controls, nonzero recorded deposits across multiple live outputs. Observe ordinary success and accepted phase-2 failure before and after the existing snapshot boundary. Neither records nor the global Store balance add weight, while eligible funds retain their expected weight; an all-zero distribution must fail the positive controls.
