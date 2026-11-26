<a id="domain-model" name="domain-model"></a>

# 1. Domain model

[Specification contents](../README.md#table-of-contents) · [Transaction rules →](transaction-rules.md) · [Verification record](../verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/chapters/domain-model.md)

> **Establish the vocabulary and determine the deposit required by each new output.**

## Table of contents

<div>
<a href="#section-1">1.1 Outputs</a><br>
<a href="#section-1-1">1.2 DepositStore</a><br>
<a href="#section-1-4">1.3 Transaction bodies</a><br>
<details>
  <summary><a href="#ds-pricing">1.4 Deposit calculation</a></summary>
  <dl>
    <dd>
      <a href="#ds-pricing-p01">1.4.1 P01 - Price each created output</a><br>
      <a href="#ds-pricing-n01">1.4.2 N01 - Count distinct native assets</a><br>
      <a href="#ds-pricing-n02">1.4.3 N02 - Price an applied collateral return</a><br>
      <a href="#ds-pricing-n03">1.4.4 N03 - Measure datum and reference script payloads</a><br>
      <a href="#ds-pricing-n04">1.4.5 N04 - Vary the declaration independently</a><br>
      <a href="#ds-pricing-n05">1.4.6 N05 - Preserve the price across ADA encoding boundaries</a><br>
      <a href="#ds-pricing-n06">1.4.7 N06 - Keep a min-ADA reserve inside its output</a><br>
    </dd>
  </dl>
</details>
</div>

<a id="section-1" name="section-1"></a>

## 1.1 Outputs

> **Distinguish the value carried by an output from its storage deposit.**

A **UTxO capacity deposit** is the ADA required for an output's storage capacity.
The two output variants carry that obligation differently:

| Output | Spendable value | UTxO capacity deposit |
| --- | --- | --- |
| Min-ADA (`MinAdaTxOut`) | Full output value | The existing minimum ADA remains inside that value. |
| Deposit-backed (`DepositBackedTxOut`) | Application assets: ADA and native assets | Recorded alongside the live UTxO entry and held externally in the DepositStore. |

For a deposit-backed output, distinguish its **required deposit**, calculated when it is
created, from its **allocated deposit**, the exact recorded amount associated with the
live output. [Deposit calculation](#ds-pricing) defines the required amount;
[Allocations](ledger-effects.md#ds-state-allocations) defines how the ledger records and releases it.

Outputs are indexed occurrences. Equal output values at different indices represent
separate outputs and have separate allocated deposits when deposit-backed. The external
deposit metadata is outside the serialized output.

<a id="section-1-1" name="section-1-1"></a>

## 1.2 DepositStore

> **Retain the output and its allocation origin. The origin selects the formula for its refund.**

```haskell
data UTxOStore era = UTxOStore
  { depositFormulaHistory :: !DepositFormulaHistory
  , totalDepositAmount :: !DepositAmount
  , allocations :: !(IndexedUTxOs era)
  }

newtype DepositAmount = DepositAmount {toCoin :: Coin}

newtype IndexedUTxOs era = IndexedUTxOs
  { unIndexedUTxOs :: Map TxIn (Unspent (TxOut era))
  }

data Unspent output = Unspent
  { output :: !output
  , allocatedAt :: !AllocatedAt
  }

data AllocatedAt
  = AtStoreMigration
  | AtSlot !SlotNo

data DepositFormulaHistory = DepositFormulaHistory
  { initialFormula :: !DepositFormula
  , formulaChanges :: !(Map SlotNo DepositFormula)
  }
```

An accepted output enters the Store as `Unspent output (AtSlot slot)`.
The fork imports each translated min-ADA output as `Unspent output AtStoreMigration`.
The output provides the asset, datum and script measurements for [Deposit calculation](#ds-pricing).

**History always has a baseline.** `mkDepositFormulaHistory baseline` starts with no dated
changes. The default is V1 at **4310 lovelace per byte**, with no dated changes;
`Default UTxOStore` uses this history and empty allocations. `initialFormula`
prices imported entries permanently and all dated entries preceding the first change.
Each subsequent change retains its formula and parameters over $`[s_i,s_{i+1})`$; the final interval has no upper bound.

**Prototype migration uses one initial formula.** Imported outputs and new outputs
allocated before the first change use the same baseline. This history records
changes introduced after the fork; it does not reconstruct pre-fork pricing or
require a migration slot. Later activations affect newly allocated outputs while
existing entries retain their allocation-time formula.

| Allocation | Formula retained |
| --- | --- |
| Imported at migration | `initialFormula = DepositFormulaV1 rateA` |
| New, before the first change | `DepositFormulaV1 rateA` |
| New, after a parameter change | `DepositFormulaV1 rateB` |
| New, after a formula-version change | `DepositFormulaV2 rateC` |

V1 prices a base of 250 bytes plus 74 bytes per distinct native asset. The experimental
V2 changes these coefficients to 260 and 80. Both add the datum and reference script
payload lengths and multiply by their recorded rate.

Let $`f_b`$ be the baseline formula and $`(s_i,f_i)`$ the ordered changes:

```math
H(s)=
\begin{cases}
f_b & \text{if no change starts at or before }s \\
f_j & j=\max\{i\mid s_i\leq s\}
\end{cases}
```

| Allocation origin | Formula $`F_H(u)`$ |
| --- | --- |
| `AtStoreMigration` | The baseline $`f_b`$, including after later changes. |
| `AtSlot slot` | $`H(\text{slot})`$: the latest applicable change, otherwise the baseline. |

`formulaAt`, `latestFormula` and the Store's derived `currentFormula`
return a formula directly. `periods` includes the baseline interval with
`fromInclusive = Nothing`; the last interval has `untilExclusive = Nothing`.

**The output variant determines where the reserve is held.** Let $`C(u)`$ be the
output ADA and $`P(u)=F_H(u)(\text{output}(u))`$ its calculated deposit.

| View | `MinAdaTxOut` | `DepositBackedTxOut` |
| --- | --- | --- |
| `computeDeposit` | $`\min(C(u),P(u))`$ | $`P(u)`$ |
| Application ADA | $`C(u)-\min(C(u),P(u))`$ | $`C(u)`$ |
| `computeExternalDeposit` | $`0`$ | $`P(u)`$ |
| Stored output payload | Unchanged; reserve remains included | Unchanged; deposit is external |

Native assets are preserved in both application views. When a min-ADA output cannot
cover the calculated reserve, its application ADA is zero. This is a **view**, not
a transfer or payload rewrite. Spending that output still provides its complete
value; its reserve must never be credited a second time.

```math
\text{totalDepositAmount}(S)
= \sum_{u\in\text{allocations}(S)}
\text{computeExternalDeposit}(\text{depositFormulaHistory}(S),u)
```

The cached total contains only separately held deposits. Min-ADA reserves remain
inside output ADA; there is no unallocated Store surplus.

**Builder queries use explicit history and return values directly.** Every
allocation resolves either the baseline or a dated change. The reserve query returns
`DepositAmount`; use `toCoin` when combining it with output ADA:

```haskell
-- Dijkstra builder queries, shown specialized to the active era.
computeDeposit ::
  DepositFormulaHistory -> Unspent (TxOut DijkstraEra) -> DepositAmount

computeApplicationAssets ::
  DepositFormulaHistory -> Unspent (TxOut DijkstraEra) -> ApplicationAssets DijkstraEra

-- The shared Store sums only separately held deposits.
computeExternalDeposit ::
  EraDepositBackedTxOut era => DepositFormulaHistory -> Unspent (TxOut era) -> Coin

-- Resolve many inputs against the same history.
depositFor = computeDeposit (depositFormulaHistory store)
depositFor entry
```

`mkUTxOStore history entries` preserves output payloads and allocation origins and
derives the external total. `sumDepositAmounts history entries` and
`allocatedDepositTotalAmount history inputs entries` return `DepositAmount`;
use `toCoin` explicitly for Coin arithmetic.

| Operation | Contract |
| --- | --- |
| `allocate slot outputs` | Keep occupied references and record each new output with `allocatedAt = AtSlot slot`. |
| `release inputs` | Remove selected entries and debit their historical **external** deposits. |
| `appendFormula slot formula` | Add the first dated change or one strictly after the latest; reject replacement or insertion into existing periods. |
| `activateNewFormula slot formula` | Append without repricing existing entries; reject V2 → V1. Rates may increase or decrease within either version. Reapplying the latest formula is a no-op. |

Activation preserves existing entries and the cached total. Effective parameter
changes use the **actual epoch boundary slot**, even when the first transaction
arrives later. TopTx, its SubTxs and any collateral return record their ledger slot.

Formula activation only moves forward in version:

```math
\mathrm{version}(F_{\mathrm{next}}) \geq \mathrm{version}(F_{\mathrm{active}})
```

Existing V1 allocations still use V1 for their refunds after V2 becomes active.

```haskell
Store.projectTx slot tx previousStore
Store.Internals.projectValidTxBody slot body previousStore
Store.Internals.projectInvalidTxBody slot body previousStore
```

Each projection returns `TxProjected {updatedStore, consumedOutputs, producedOutputs}`.
Regular and collateral paths report actual Store changes; retained colliding
references are not produced again. Stake updates use those same entries. The ledger
selects SubTx execution and controls event emission.

**Migration initializes the baseline.** `mkDepositFormulaHistory formula` records V1
with the effective translated protocol parameters as `initialFormula`; dated
changes start empty. Imported entries retain the translated output and `AtStoreMigration`. Their baseline-priced reserve remains embedded
and capped by existing ADA. No creation slot is invented or recovered. Later changes
do not reprice these entries; the external total starts at zero.

Test-network initial funds also enter as `AtStoreMigration`. Injection preserves
the supplied Store's complete history and existing entries, including when dated
changes begin at a nonzero slot. A network started directly in Dijkstra begins
with V1 at its effective genesis rate and no dated changes.

**Persistence preserves the pricing inputs.** History encodes
`[initialFormula, formulaChanges]`; Dijkstra entries encode
`[output, allocatedAt]`; the Store encodes
`[depositFormulaHistory, cachedTotal, allocationMap]`. Decoding validates entry shape, activation order, formula versions and the cached total. Prior
per-entry formula and nullable/history-map schemas are not this format.

Before Dijkstra, existing payload-only formats remain unchanged. They preserve no
Store history or original creation dates. Ordinary legacy decoding uses the default
V1/4310 history. `Store.decodeUTxOStoreWithFormula baseline credentials` allows
a caller to override that baseline. Dijkstra snapshots remain self-contained and
retain their persisted history. The assigned legacy baseline is a model policy,
not recovery of each output's original minimum deposit.

Empty Stores retain their baseline and dated changes. Zero-priced new outputs still receive allocation records.

[Ledger effects](ledger-effects.md#ds-state) specifies the resulting allocations and exact cached total.

<a id="section-1-4" name="section-1-4"></a>

## 1.3 Transaction bodies

> **Identify each body's own operations and the complete transaction's total.**
>
> $`\text{Transaction}=\text{TopTx body}+\text{its SubTx bodies}`$.

| Scope | Inputs and outputs | Declaration describes |
| --- | --- | --- |
| TopTx body | Its own regular inputs and outputs, excluding those of its SubTxs | The net deposit change of the complete transaction. |
| SubTx body | That SubTx's own regular inputs and outputs | Its net deposit contribution and whether accounting is local or delegated to TopTx. |
| Complete transaction | TopTx and every SubTx body, each counted once | The sum of all body contributions. |

Spent outputs are obtained by resolving the body's spending inputs against the
applicable UTxO. Reference inputs do not consume outputs or release deposits.
Collateral inputs and collateral return belong to the separate [Collateral](transaction-rules.md#ds-collateral)
calculation. An input may also be an ordinary spending input; it is counted once in
that hypothetical ordinary calculation and once in the alternative collateral
calculation. [Execution](ledger-effects.md#ds-state-execution) applies only the selected outcome.

For each body:

```math
\begin{aligned}
\text{releasedUTxODeposits(body)}
&= \sum_{\text{input}\in\text{consumed deposit-backed inputs(body)}}
\text{recordedDeposit(input)} \\
\text{allocatedUTxODeposits(body)}
&= \sum_{\text{output}\in\text{new deposit-backed outputs(body)}}
\text{requiredDeposit(output)} \\
\text{storeChange(body)}
&= \text{allocatedUTxODeposits(body)} - \text{releasedUTxODeposits(body)} \\
\text{requiredNetUTxODepositChange(body)}
&= \text{storeChange(body)} + \text{newEmbeddedMinima(body)} - \text{creditedEmbeddedReserves(body)} \\
\text{requiredTxTotalNetUTxODepositChange}
&= \sum_{\text{body}\in\text{TopTx and all SubTx bodies}}
\text{requiredNetUTxODepositChange(body)}
\end{aligned}
```

Each new min-ADA output contributes its full minimum under the active formula.
Each consumed min-ADA input contributes its historical minimum capped at its
serialized ADA. Imported inputs use the fork's initial formula. Dated inputs use
the formula in effect at allocation. The external deposits use the same creation
and historical prices, respectively, with the full historical deposit released.

The declaration supplies a separate value, `declaredTxTotalNetUTxODepositChange`.
[TopTx accounting](transaction-rules.md#ds-tx-accounting-net-change-toptx) compares that supplied total with the required
total above. For each explicit SubTx declaration, [SubTx accounting](transaction-rules.md#ds-tx-accounting-net-change-subtx)
compares `declaredSubTxNetUTxODepositChange(subTx)` with its required own change.
Never obtain the expected amounts from the declarations being checked.

| Body operations | Required own change | Correct declaration |
| --- | ---: | --- |
| TopTx releases 3 ADA | $`-3`$ ADA | Explicit zero, because the complete transaction nets to zero. |
| Its SubTx allocates 3 ADA | $`+3`$ ADA | An allocation of 3 ADA, locally accounted or explicitly delegated. |

TopTx's **accounting amount**, `topTxNetUTxODepositChange`, is the declared total
minus locally accounted SubTx contributions. It includes delegated contributions;
it is distinct from TopTx's own operations. [Attribution](transaction-rules.md#ds-tx-accounting-attribution) defines it.

Net quantities are signed: positive means net allocation, negative means net release,
and zero means no net change. **An absent declaration has no declared value**; it is
not an explicit declaration of zero. `hasDeclaration(body)` distinguishes these cases
and is true for every explicit declaration, including zero.

A **settlement output** is the output designated to contain a release's settlement
amount. [Settlement](transaction-rules.md#ds-tx-settlement) determines TopTx’s responsibility, the
destination and required amount.
The [body-field reference](appendices.md#transaction-body-fields) maps these concepts to the API.

<a id="ds-pricing" name="ds-pricing"></a>

## 1.4 Deposit calculation

**At the Dijkstra fork and at direct Dijkstra genesis, V1 is the initial formula.**
Dijkstra evaluates both output forms, including migrated `MinAdaTxOut`s. Earlier-era
pricing rules stay unchanged; they do not implement this formula.
The rate $`p`$ is the effective `coinsPerUTxOByte`, in lovelace per byte. For an output $`o`$:

```math
\begin{aligned}
F_{1,p}(o) &= p\,(250 + 74N(o) + D(o) + R(o)) \\
F_{2,p}(o) &= p\,(260 + 80N(o) + D(o) + R(o))
\end{aligned}
```

| Component | Measurement |
| --- | --- |
| $`N(o)`$ | Number of distinct native assets. Each pair of policy ID and asset name counts once, regardless of quantity. ADA contributes zero. |
| $`D(o)`$ | No datum: zero. Datum hash: length of the hash in bytes. Inline datum: length of its original payload in bytes. |
| $`R(o)`$ | No reference script: zero. Otherwise, the original byte length of the underlying native or Plutus script. |

**The formula takes typed measures.** `NativeAssetCount`, `DatumBytes` and
`ReferenceScriptBytes` each wrap `Natural`. The core calculation depends on these
nonnegative quantities, without knowing an output representation:

```haskell
computeDeposit ::
  DepositFormula ->
  NativeAssetCount ->
  DatumBytes ->
  ReferenceScriptBytes ->
  DepositAmount
```

Dijkstra's `Deposit.Formula.computeDeposit` extracts those measures from a `TxOut`
and calls this core function. `Unspent.computeDeposit` additionally selects the
historical formula and caps a min-ADA reserve. Both return `DepositAmount`;
`getDepositTxOut` and `computeExternalDeposit` expose `Coin` through `toCoin`
at the shared Store boundary.

The lengths count payload bytes. Address length, application ADA and the outer CBOR
envelopes of the datum, script and output contribute no term. Transaction bodies
still retain their `Sized` outputs for serialization; neither Dijkstra deposit
pricing nor its [minimum-coin check](transaction-rules.md#ds-tx-minimum-coin) uses that total size.

The Store holds the full computed amount externally for each created `DepositBackedTxOut`.
For a `MinAdaTxOut`, its embedded reserve is capped at the output's ADA.
The [allocation origin](#section-1-1) selects the formula and rate on refund.

**Experiment.** Two otherwise identical Deposit-backed outputs contain two distinct
native assets, no datum and no reference script. At $`p=4310`$, their deposits depend
on which side of the V2 activation slot $`s`$ they were allocated.

| Allocation slot | Price at allocation | Refund when spent after $`s`$ |
| --- | ---: | ---: |
| Before $`s`$ (V1) | $`4310(250+74\cdot2)=1{,}715{,}380`$ lovelace | 1,715,380 lovelace |
| At $`s`$ (V2) | $`4310(260+80\cdot2)=1{,}810{,}200`$ lovelace | 1,810,200 lovelace |

The [live-ledger experiment](ledger-effects.md#ds-state-balance-p08) accepts these outputs, restores their snapshot and spends both under V2. The refund remains the sum of their historical deposits.

The following cases describe the pricing contract across ordinary outputs and collateral.

<a id="ds-pricing-p01" name="ds-pricing-p01"></a>

### 1.4.1 P01 - Price each created output

For each newly created Deposit-backed reference, compute $`N`$, $`D`$ and $`R`$ from its
output. Compare the independently calculated $`F_{v,p}(o)`$ with the allocation read
from the ledger. Include TopTx, SubTx and an applied collateral return.

<a id="ds-pricing-n01" name="ds-pricing-n01"></a>

### 1.4.2 N01 - Count distinct native assets

Under V1, increasing a token's quantity leaves the deposit unchanged. Adding a new
asset name under the same policy increases it by $`74p`$. The same asset name under
a different policy is also a distinct asset. Under V2 each additional asset costs $`80p`$.

<a id="ds-pricing-n02" name="ds-pricing-n02"></a>

### 1.4.3 N02 - Price an applied collateral return

An accepted phase-2 failure creating a Deposit-backed collateral return allocates
$`F_{v,p}(o)`$ for its output. The same output under the same formula and rate costs
the same on the ordinary path.

<a id="ds-pricing-n03" name="ds-pricing-n03"></a>

### 1.4.4 N03 - Measure datum and reference script payloads

For fixed assets and rate, a datum hash of 32 bytes adds $`32p`$. An inline datum
of $`d`$ bytes adds $`dp`$. Adding a reference script of $`r`$ bytes adds another $`rp`$.
Exercise absent payloads, native scripts and Plutus scripts.

<a id="ds-pricing-n04" name="ds-pricing-n04"></a>

### 1.4.5 N04 - Vary the declaration independently

Hold the output and formula fixed and vary the surrounding body declaration. The
required deposit stays fixed. Accounting compares the declared amount with that
independently calculated requirement.

<a id="ds-pricing-n05" name="ds-pricing-n05"></a>

### 1.4.6 N05 - Preserve the price across ADA encoding boundaries

For two Deposit-backed outputs with identical $`N,D,R`$, change application ADA from
23 to 24 lovelace. Their coin encodings differ in length, but both incur the same
external deposit. The same reasoning applies to a change in address length.

<a id="ds-pricing-n06" name="ds-pricing-n06"></a>

### 1.4.7 N06 - Keep a min-ADA reserve inside its output

An existing `MinAdaTxOut` with $`C`$ lovelace contributes zero to the external total.
Its reserve is $`\min(C,F_{v,p}(o))`$, selected from its allocation history, and its
application ADA is the remainder. A newly proposed `MinAdaTxOut` is also allowed,
but must contain at least the full deposit under the Store's **current** formula.
The historical reserve cap does not relax admission of a new output.
