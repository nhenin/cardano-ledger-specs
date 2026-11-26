<a id="section-1-3" name="section-1-3"></a><a id="ds-state" name="ds-state"></a>

<a id="ds-state-execution-p01" name="ds-state-execution-p01"></a><a id="ds-state-execution-n01" name="ds-state-execution-n01"></a><a id="ds-state-execution-n04" name="ds-state-execution-n04"></a><a id="ds-state-execution-n02" name="ds-state-execution-n02"></a><a id="ds-state-execution-n03" name="ds-state-execution-n03"></a>

# 3. Ledger effects

[Specification contents](../README.md#table-of-contents) · [← Transaction rules](transaction-rules.md) · [Derived distributions →](derived-distributions.md) · [Verification record](../verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/chapters/ledger-effects.md)

> **Observe the state produced by an accepted transaction.**
>
> Transaction rules decide validity. Ledger effects checks the resulting UTxO,
> Store records and monetary pots; Lifecycle checks translation and epoch boundaries.

| Responsibility | Observation |
| --- | --- |
| [UTxO](#ds-state-utxo) | Exact consumed and created output references. |
| [Store / Allocations](#ds-state-allocations) | Exact allocation map for live Deposit-backed outputs. |
| [Store / Balance](#ds-state-balance) | Change in the sum of recorded deposits. |
| [Fees](#ds-state-fees) | Fee credit and unchanged treasury. |
| [Conservation](#ds-state-conservation) | Correct ADA total and its preservation. |
| [Lifecycle](#ds-state-lifecycle) | Era translation and ordinary epoch boundaries. |

The accepted outcome selects the inputs and outputs used by all these observations:

| Outcome | $`\mathit{consumedInputs}`$ | $`\mathit{createdOutputs}`$ |
| --- | --- | --- |
| Ordinary success | Ordinary inputs of TopTx and every SubTx. | Their signed ordinary outputs, each under its own body's identifier and output index. |
| Accepted phase-2 failure | Collateral inputs. | The signed collateral return, when present. |

Settlement ADA is already included in the signed output. Reference-only and
unrelated inputs remain unchanged; an input used in both consuming roles is
consumed once through the selected path. Tests assert acceptance before checking
these effects. Executed counts and timings belong to the [verification record](../verification.md).

## Table of contents

<div>
<details>
  <summary><a href="#ds-state-utxo">3.1 UTxO</a></summary>
  <dl>
    <dd>
      <a href="#ds-state-utxo-n01">3.1.1 N01 - Ordinary execution</a><br>
      <a href="#ds-state-utxo-n02">3.1.2 N02 - Successful scripts leave collateral inactive</a><br>
      <a href="#ds-state-utxo-n03">3.1.3 N03 - Failed scripts select collateral</a><br>
      <a href="#ds-state-utxo-n04">3.1.4 N04 - Failed TopTx, inactive SubTxs</a><br>
      <a href="#ds-state-utxo-n05">3.1.5 N05 - One input, two consuming roles</a><br>
    </dd>
  </dl>
</details>
<details>
  <summary><a href="#ds-state-store">3.2 Store</a></summary>
  <dl>
    <dd>
      <details>
        <summary><a href="#ds-state-allocations">3.2.1 Allocations</a></summary>
        <dl>
          <dd>
            <a href="#ds-state-allocations-p01">3.2.1.1 P01 - Ordinary records</a><br>
            <a href="#ds-state-allocations-p02">3.2.1.2 P02 - Collateral records</a><br>
            <a href="#ds-state-allocations-p03">3.2.1.3 P03 - Restore the historical deposit</a><br>
            <a href="#ds-state-allocations-n01">3.2.1.4 N01 - Zero-priced allocations still have records</a><br>
            <a href="#ds-state-allocations-p04">3.2.1.5 P04 - No ordinary records on failure</a><br>
          </dd>
        </dl>
      </details>
      <details>
        <summary><a href="#ds-state-balance">3.2.2 Balance</a></summary>
        <dl>
          <dd>
            <a href="#ds-state-balance-p01">3.2.2.1 P01 - Ordinary transfer</a><br>
            <a href="#ds-state-balance-p02">3.2.2.2 P02 - Collateral transfer</a><br>
            <a href="#ds-state-balance-p03">3.2.2.3 P03 - Historical release after restoration</a><br>
            <a href="#ds-state-balance-p04">3.2.2.4 P04 - No ordinary transfer on failure</a><br>
            <a href="#ds-state-balance-p05">3.2.2.5 P05 - Refund mixed historical prices</a><br>
            <a href="#ds-state-balance-p06">3.2.2.6 P06 - Restore and refund a child output</a><br>
            <a href="#ds-state-balance-p07">3.2.2.7 P07 - Restore and refund a collateral return</a><br>
            <a href="#ds-state-balance-p08">3.2.2.8 P08 - Refund across formula versions</a><br>
          </dd>
        </dl>
      </details>
    </dd>
  </dl>
</details>
<details>
  <summary><a href="#ds-state-fees">3.3 Fees</a></summary>
  <dl>
    <dd>
      <a href="#ds-state-fees-p01">3.3.1 P01 - Ordinary fee</a><br>
      <a href="#ds-state-fees-p02">3.3.2 P02 - Collateral fee</a><br>
    </dd>
  </dl>
</details>
<details>
  <summary><a href="#ds-state-conservation">3.4 Conservation</a></summary>
  <dl>
    <dd>
      <a href="#ds-state-conservation-n01">3.4.1 N01 - Count actual ADA once</a><br>
      <a href="#ds-state-conservation-n02">3.4.2 N02 - Ordinary conservation</a><br>
      <a href="#ds-state-conservation-n03">3.4.3 N03 - Collateral conservation</a><br>
    </dd>
  </dl>
</details>
<details>
  <summary><a href="#ds-state-lifecycle">3.5 Lifecycle</a></summary>
  <dl>
    <dd>
      <details>
        <summary><a href="#ds-state-translation">3.5.1 Translation</a></summary>
        <dl>
          <dd>
            <a href="#ds-state-translation-n01">3.5.1.1 N01 - Introduce legacy allocations</a><br>
          </dd>
        </dl>
      </details>
      <details>
        <summary><a href="#ds-state-epoch">3.5.2 Epoch</a></summary>
        <dl>
          <dd>
            <a href="#ds-state-epoch-n01">3.5.2.1 N01 - Retain the populated Store</a><br>
            <a href="#ds-state-epoch-n02">3.5.2.2 N02 - Activate the effective price</a><br>
          </dd>
        </dl>
      </details>
    </dd>
  </dl>
</details>
</div>

<a id="ds-state-execution" name="ds-state-execution"></a><a id="ds-state-utxo" name="ds-state-utxo"></a>

## 3.1 UTxO

> **Apply exactly the selected inputs and signed outputs.**

```math
\mathit{utxoAfter}
=(\mathit{utxoBefore}\setminus\mathit{consumedInputs})
\cup\mathit{createdOutputs}
```

Here, subtraction removes map entries by input reference; union inserts the
selected outputs without changing their payloads.

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-utxo-n01" name="ds-state-utxo-n01"></a>**1.&nbsp;[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L34)** | **Ordinary execution.** Standalone and multi-SubTx transactions allocate, release or replace deposits. Compare the entire resulting UTxO with the ordinary-input/output equation. |
| <a id="ds-state-utxo-n02" name="ds-state-utxo-n02"></a>**2.&nbsp;[N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L48)** | **Successful scripts leave collateral inactive.** Generate collateral proposals with absent, implicit or Deposit-backed returns. Only ordinary outputs are created; collateral-only and reference-only inputs survive. |
| <a id="ds-state-utxo-n03" name="ds-state-utxo-n03"></a>**3.&nbsp;[N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L62)** | **Failed scripts select collateral.** Submit a genuine phase-2 failure. Only collateral inputs disappear and only the collateral return is created; ordinary and reference-only inputs survive. |
| <a id="ds-state-utxo-n04" name="ds-state-utxo-n04"></a>**4.&nbsp;[N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L77)** | **Failed TopTx, inactive SubTxs.** A real failing TopTx script selects collateral even when several children propose allocations and releases. Compare the complete UTxO: none of those ordinary effects is applied. |
| <a id="ds-state-utxo-n05" name="ds-state-utxo-n05"></a>**5.&nbsp;[N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L95)** | **One input, two consuming roles.** A Deposit-backed input belongs to both ordinary and collateral sets. Exercise both actual script outcomes and compare the complete UTxO against the selected path; consume the shared input once. |

<a id="ds-state-execution-f01" name="ds-state-execution-f01"></a>

<a id="ds-state-execution-p02" name="ds-state-execution-p02"></a>

**Rejected submissions.** A rejected transaction produces no new accepted state.
The submission adapter installs a state only on success, so comparing its snapshots
after rejection would mainly retest that adapter. Rejection assertions remain in
Transaction rules; this section measures applied effects. Likewise, these failing
scripts execute at TopTx: they do not claim to test propagation of a failing
SubTx script through the upstream batch evaluator.

<a id="ds-state-store" name="ds-state-store"></a>

## 3.2 Store

`UTxOStore` owns `depositFormulaHistory`, one indexed map of `Unspent (TxOut era)` and a
checked cached `totalDepositAmount`. Each entry retains its output and allocation origin (`AtStoreMigration` or `AtSlot slot`). History resolves its
formula as described in [DepositStore](domain-model.md#section-1-1). Output references and
allocations share one map; the cached total counts only separately held ADA.

<a id="ds-state-allocations" name="ds-state-allocations"></a><a id="ds-state-store-allocations" name="ds-state-store-allocations"></a>

<a id="ds-state-allocations-n04" name="ds-state-allocations-n04"></a><a id="ds-state-allocations-n05" name="ds-state-allocations-n05"></a><a id="ds-state-allocations-n02" name="ds-state-allocations-n02"></a><a id="ds-state-allocations-n03" name="ds-state-allocations-n03"></a><a id="ds-state-allocations-n06" name="ds-state-allocations-n06"></a><a id="ds-state-allocations-n07" name="ds-state-allocations-n07"></a><a id="ds-state-allocations-n08" name="ds-state-allocations-n08"></a>

### 3.2.1 Allocations

> **Retain one allocation for each live Deposit-backed output.**

Here, $`\mathit{recordsBefore}`$ is mathematical notation for the deposits calculated from retained creation-time metadata, not a separate ledger type or stored map. The owning allocation map also contains min-ADA outputs, whose external deposit is zero.
Construct $`\mathit{newAllocations}`$ only for Deposit-backed outputs in
$`\mathit{createdOutputs}`$, priced from their contents and allocation-time formulas under
[Deposit calculation](domain-model.md#ds-pricing). Min-ADA outputs have no external-deposit record in this view; their legacy allocations remain in the owning map. A Deposit-backed output priced at zero still has a deposit record. For either accepted outcome:

```math
\begin{aligned}
\mathit{recordsAfter}
&=(\mathit{recordsBefore}\setminus\mathit{consumedInputs})
  \cup\mathit{newAllocations} \\
\mathit{keys}(\mathit{recordsAfter})
&=\{\,\mathit{outputRef}\mid\mathit{utxoAfter}[\mathit{outputRef}]\text{ is Deposit-backed}\,\} \\
\mathit{recordsAfter}[\mathit{outputRef}]&\geq0
\quad\text{for every recorded }\mathit{outputRef}
\end{aligned}
```

Compare the actual map with this independently constructed map, and its domain
with the actual resulting UTxO. Equality between two sums of the same unchecked
map would miss missing, misplaced or incorrectly priced records. A consistent
starting state has this exact domain and nonnegative recorded amounts.
[Balance](#ds-state-balance) checks the resulting ADA change against independently
calculated allocations and retained releases.

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-allocations-p01" name="ds-state-allocations-p01"></a>**1.&nbsp;[P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L75)** | **Ordinary records.** Derive records from signed Deposit-backed outputs, remove consumed references, then compare the complete map and its domain with the resulting UTxO. Cover local and delegated multi-SubTx activity and equal-valued outputs at distinct references. |
| <a id="ds-state-allocations-p02" name="ds-state-allocations-p02"></a>**2.&nbsp;[P02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L96)** | **Collateral records.** Generate mixed input forms and absent, implicit or Deposit-backed returns. Real script success removes only ordinary records, including shared ordinary/collateral inputs. Real failure removes only collateral records and adds the Deposit-backed return; reference-only records survive. |
| <a id="ds-state-allocations-p03" name="ds-state-allocations-p03"></a>**3.&nbsp;[P03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L121)** | **Restore the historical deposit.** Submit a noncanonical CBOR output whose accepted encoding is one byte longer than its canonical encoding. Restore the serialized state, activate V2 and double the byte price, then reference the output: its payload, allocation origin and V1 deposit are unchanged. Spending it removes precisely that record. |
| <a id="ds-state-allocations-n01" name="ds-state-allocations-n01"></a>**4.&nbsp;[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L166)** | **Zero-priced allocations still have records.** Spend translated min-ADA sources and create Deposit-backed outputs in TopTx and SubTx at a zero byte price. Record each new reference with amount zero; min-ADA sources never acquire allocation records. |
| <a id="ds-state-allocations-p04" name="ds-state-allocations-p04"></a>**5.&nbsp;[P04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L190)** | **No ordinary records on failure.** A real failing TopTx script has several children proposing Store allocations and releases. With implicit-only collateral, the entire allocation map remains unchanged. |

Historical release **amounts** are checked separately by [Balance P03](#ds-state-balance-p03).

<a id="ds-state-balance" name="ds-state-balance"></a><a id="ds-state-store-balance" name="ds-state-store-balance"></a>

### 3.2.2 Balance

> **The Store balance changes by newly allocated deposits minus recorded releases.**

Derive the transfer from new allocations and retained consumed records:

```math
\begin{aligned}
\mathit{releasedDeposits}
&=\sum_{\mathit{input}\in\mathit{consumedInputs}\cap\mathit{keys}(\mathit{recordsBefore})}
  \mathit{recordsBefore}[\mathit{input}] \\
\mathit{storeBalanceAfter}
&=\mathit{storeBalanceBefore}+\sum\mathit{newAllocations}
  -\mathit{releasedDeposits}
\end{aligned}
```

On ordinary success, the Store balance changes by the actual external deposits
created minus those consumed, across TopTx and all SubTxs. Embedded reserves
enter the signed declaration and travel in serialized output values. On accepted
phase-2 failure, only collateral allocations and releases affect the Store.

<a id="ds-state-balance-n02" name="ds-state-balance-n02"></a>
For every Store, its cached balance must equal the sum calculated from its historical records:

```math
\mathit{storeBalance}=\sum\mathit{records}
```

The transfer assertion compares the observed amount with independently calculated
allocations and releases. Separate assertions recompute the total from each output’s
asset count, datum and script, using the version and rate selected by its origin.
[Historical pricing](domain-model.md#ds-pricing-history) keeps the original refund for each allocation.

<a id="ds-state-balance-n01" name="ds-state-balance-n01"></a><a id="ds-state-balance-n03" name="ds-state-balance-n03"></a>

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-balance-p01" name="ds-state-balance-p01"></a>**1.&nbsp;[P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L61)** | **Ordinary transfer.** Measure new deposits from signed outputs and releases from the consumed records. The sum of the resulting records changes by their difference, including multi-SubTx local/delegated funding and zero net replacement. |
| <a id="ds-state-balance-p02" name="ds-state-balance-p02"></a>**2.&nbsp;[P02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L82)** | **Collateral transfer.** Successful scripts release only ordinary records, including inputs shared with collateral. Failed scripts apply only the return deposit minus recorded collateral releases; deposits of all unspent outputs remain recorded. |
| <a id="ds-state-balance-p03" name="ds-state-balance-p03"></a>**3.&nbsp;[P03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L103)** | **Historical release after restoration.** Create an allocation from genuinely noncanonical accepted bytes, restore the state and change the price. Spending the output reduces the Store by the original allocation, not a newly calculated deposit. |
| <a id="ds-state-balance-p04" name="ds-state-balance-p04"></a>**4.&nbsp;[P04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L127)** | **No ordinary transfer on failure.** The same failing-parent, multi-SubTx scenarios use implicit-only collateral. The Store balance remains unchanged despite their ordinary declarations. |
| <a id="ds-state-balance-p05" name="ds-state-balance-p05"></a>**5.&nbsp;[P05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L141)** | **Mixed historical prices.** Accept two noncanonical outputs at different prices, restore their state and consume both while creating a replacement at a third price. The balance changes by the current new deposit minus both historical deposits. Retained metadata and cache totals are checked independently. |
| <a id="ds-state-balance-p06" name="ds-state-balance-p06"></a>**6.&nbsp;[P06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L175)** | **Child output history.** Accept a noncanonical SubTx output, restore its allocation and change the price. A later spend of the child's own reference releases exactly its original contribution. |
| <a id="ds-state-balance-p07" name="ds-state-balance-p07"></a>**7.&nbsp;[P07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L198)** | **Collateral-return history.** Accept a real script failure with a noncanonical Deposit-backed return. Restore that applied allocation, change the price and spend the return; its contents and allocation-time formula determine the refund. |
| <a id="ds-state-balance-p08" name="ds-state-balance-p08"></a>**8.&nbsp;[P08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L227)** | **Across formula versions.** Accept identical two-asset outputs before and after V2 activation, restore the state and spend both together. Each refunds its allocation-time formula: $`\text{refund}=F_{1,p}(o)+F_{2,p}(o)`$. |

<a id="ds-state-solvency" name="ds-state-solvency"></a><a id="34-solvency" name="34-solvency"></a><a id="ds-state-solvency-p01" name="ds-state-solvency-p01"></a><a id="341-p01---keep-every-accepted-state-solvent" name="341-p01---keep-every-accepted-state-solvent"></a><a id="ds-state-solvency-n02" name="ds-state-solvency-n02"></a><a id="344-n02---observes-store-backing-in-the-completed-batch-result-with-local-and-delegated-contributions" name="344-n02---observes-store-backing-in-the-completed-batch-result-with-local-and-delegated-contributions"></a>
**Exact cache invariant.** The former solvency comparison is replaced by equality:
`mkUTxOStore` establishes the cached total, `allocate` and `release` preserve it for a valid store, and decoding rejects a total that differs from the historical record sum. Raw allocation construction is separate from these checks. Direct record updates must preserve the same equality.
The nonnegative-record and live-output correspondence requirements remain in
[Allocations](#ds-state-allocations).

<a id="ds-state-solvency-n01" name="ds-state-solvency-n01"></a><a id="342-n01---classifies-proposed-states-at-exact-backing-and-one-lovelace-above-as-solvent" name="342-n01---classifies-proposed-states-at-exact-backing-and-one-lovelace-above-as-solvent"></a><a id="ds-state-solvency-f01" name="ds-state-solvency-f01"></a><a id="343-f01---classifies-a-proposed-state-one-lovelace-below-its-independently-calculated-obligations-as-insolvent" name="343-f01---classifies-a-proposed-state-one-lovelace-below-its-independently-calculated-obligations-as-insolvent"></a>
The former below/exact/above-backing cases are retired. Their independently varied
balance is not a valid Store: cached-total mismatch is now covered by codec rejection, rather than permitting surplus or a separate insolvency state. These anchors remain for older links.

<a id="ds-collateral-surplus" name="ds-collateral-surplus"></a>
<a id="224-surplus" name="224-surplus"></a>
<a id="ds-state-fees" name="ds-state-fees"></a>
<a id="38-fees" name="38-fees"></a>

<a id="ds-collateral-surplus-n01" name="ds-collateral-surplus-n01"></a><a id="2241-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury" name="2241-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury"></a><a id="ds-state-fees-n01" name="ds-state-fees-n01"></a><a id="381-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury" name="381-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury"></a><a id="341-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury" name="341-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury"></a><a id="ds-collateral-surplus-p01" name="ds-collateral-surplus-p01"></a><a id="2242-p01---released-surplus-reaches-fees" name="2242-p01---released-surplus-reaches-fees"></a><a id="382-p01---released-surplus-reaches-fees" name="382-p01---released-surplus-reaches-fees"></a><a id="342-p01---released-surplus-reaches-fees" name="342-p01---released-surplus-reaches-fees"></a><a id="ds-collateral-surplus-p02" name="ds-collateral-surplus-p02"></a><a id="2243-p02---treasury-remains-unchanged" name="2243-p02---treasury-remains-unchanged"></a><a id="383-p02---treasury-remains-unchanged" name="383-p02---treasury-remains-unchanged"></a><a id="343-p02---treasury-remains-unchanged" name="343-p02---treasury-remains-unchanged"></a>

## 3.3 Fees

> **Credit the fee selected by the actual execution path.**

```math
\begin{aligned}
\mathit{additionalDeposit}&=\max(0,\mathit{returnDeposit}-\mathit{releasedDeposits})\\
\mathit{releasedSurplus}&=\max(0,\mathit{releasedDeposits}-\mathit{returnDeposit})\\
\mathit{collateralCoinFee}&=\mathit{inputCoins}-\mathit{returnCoins}-\mathit{additionalDeposit}
\end{aligned}
```

| Accepted outcome | $`\mathit{feesAfter}-\mathit{feesBefore}`$ |
| --- | --- |
| Ordinary success | $`\mathit{txFee}`$ |
| Phase-2 failure | $`\mathit{collateralCoinFee}+\mathit{releasedSurplus}`$ |

Both paths preserve the treasury:
$`\mathit{treasuryAfter}=\mathit{treasuryBefore}`$.

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-fees-p01" name="ds-state-fees-p01"></a>**1.&nbsp;[P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs#L29)** | **Ordinary fee.** Local and delegated ordinary Store operations, plus real successful scripts with collateral proposals, credit only the declared transaction fee. |
| <a id="ds-state-fees-p02" name="ds-state-fees-p02"></a>**2.&nbsp;[P02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs#L53)** | **Collateral fee.** Real failing scripts credit the application-coin fee plus unused recorded deposits. Cover absent returns, mixed inputs, deposit shortfall/equality/surplus and a changed byte price. |

The input/return funding constraints belong to [Funding](transaction-rules.md#ds-collateral-funding).
[Allocations](#ds-state-allocations) and [Balance](#ds-state-balance) observe the
corresponding Store effects; these fee tests observe only fees and treasury.

<a id="ds-state-conservation" name="ds-state-conservation"></a><a id="35-conservation" name="35-conservation"></a>

## 3.4 Conservation

> **Count every actual ADA pot, including the whole Store balance, exactly once.**

Start from a valid ledger state and submit an accepted transaction. Read each
actual pot independently from the observed state. Min-ADA outputs
contribute their full coin; Deposit-backed outputs contribute application coin.
The deposited pot is `utxosDeposited`, backing certificate/governance deposits.
Sum allocation records once as `storeBalance`; do not add their total a second time.

```math
\begin{aligned}
\mathit{actualAda}
&=\mathit{outputAda}+\mathit{storeBalance}+\mathit{fees}
  +\mathit{deposited}\\
&\quad+\mathit{rewards}+\mathit{treasury}+\mathit{reserves}
  +\mathit{donations}
\end{aligned}
```

```math
\begin{aligned}
\mathit{actualAdaAfter}&=\mathit{actualAdaBefore} \\
\mathit{totalAdaES}(\mathit{state})+\mathit{donations}(\mathit{state})&=\mathit{actualAda}(\mathit{state})
\quad\text{for }\mathit{state}\in\{\mathit{before},\mathit{after}\}
\end{aligned}
```

The second equation checks the [production total](../../../eras/shelley/impl/src/Cardano/Ledger/Shelley/AdaPots.hs#L99)
against the independent sum: `totalAdaES` includes Store balance but excludes the
donation pot. Its certificate/governance obligation projection agrees with the
deposited pot in a consistent valid state. Use positive recorded deposits so the
comparison detects either omission or double counting of Store ADA, and nonzero
donations so that pot cannot be silently omitted.

<a id="ds-collateral-conservation" name="ds-collateral-conservation"></a><a id="227-conservation" name="227-conservation"></a><a id="ds-collateral-conservation-n01" name="ds-collateral-conservation-n01"></a><a id="2271-n01---conserves-ada-for-mixed-collateral-inputs-when-return-storage-needs-an-additional-deposit" name="2271-n01---conserves-ada-for-mixed-collateral-inputs-when-return-storage-needs-an-additional-deposit"></a><a id="ds-collateral-conservation-p01" name="ds-collateral-conservation-p01"></a><a id="2272-p01---collateral-settlement-conserves-ada" name="2272-p01---collateral-settlement-conserves-ada"></a><a id="351-n01---still-counts-store-ada-in-total-monetary-conservation" name="351-n01---still-counts-store-ada-in-total-monetary-conservation"></a>

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-conservation-n01" name="ds-state-conservation-n01"></a>**1.&nbsp;[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L38)** | **Count actual ADA once.** Use positive allocation records and nonzero donations. Before and after an accepted transaction, compare the production total plus donations with the independent sum of actual pots. |
| <a id="ds-state-conservation-n02" name="ds-state-conservation-n02"></a>**2.&nbsp;[N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L60)** | **Ordinary conservation.** Compare independent actual-ADA sums immediately before and after accepted standalone and multi-SubTx transactions, with local or delegated funding. |
| <a id="ds-state-conservation-n03" name="ds-state-conservation-n03"></a>**3.&nbsp;[N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L72)** | **Collateral conservation.** Repeat that comparison around real accepted phase-2 failures: mixed inputs, absent returns, and return deposits smaller than, equal to or greater than the recorded releases. |

For collateral, the same accounting projects to
$`\mathit{collateralInputCoins}+\mathit{releasedDeposits} =\mathit{returnCoins}+\mathit{returnDeposit}+\mathit{collateralFee}`$.
Its funding prerequisites belong to [Funding](transaction-rules.md#ds-collateral-funding); this
contract observes the actual applied state.

<a id="ds-state-lifecycle" name="ds-state-lifecycle"></a>

## 3.5 Lifecycle

Translation establishes legacy allocations with zero external deposits. Ordinary epoch processing preserves an
existing allocation map and therefore its derived balance. Effective parameter changes
update only the formula for future allocations.

<a id="ds-state-initialization" name="ds-state-initialization"></a><a id="36-initialization" name="36-initialization"></a><a id="ds-state-translation" name="ds-state-translation"></a>

### 3.5.1 Translation

> **Preserve Conway outputs and existing pots while introducing legacy allocations with zero external deposits.**

```math
\begin{aligned}
\mathit{outputReferencesAfter}&=\mathit{outputReferencesBefore} \\
\mathit{outputPayloadsAfter}&=\mathit{outputPayloadsBefore} \\
\mathit{recordsAfter}&=\varnothing \\
\mathit{existingMonetaryPotsAfter}&=\mathit{existingMonetaryPotsBefore}
\end{aligned}
```

Every translated output is min-ADA and has a legacy allocation in the owning map.
Here `recordsAfter` denotes the empty external-deposit view; the cached total is zero.
Migration initializes V1 from the effective translated protocol parameters with
`mkDepositFormulaHistory formula`, leaving dated changes empty. Each imported entry
is marked `AtStoreMigration`. Its translated output and this permanent baseline
determine its embedded reserve. Its reserve is capped by its existing ADA, and remains inside that value.
Preserve each output’s semantic address, value, datum
and reference script under era translation; do not extract its implicit minimum
coin. Translate a complete Conway `NewEpochState`, then compare these fields with
their Conway values: output references and payloads; treasury, reserves, fees,
deposited ADA and donations; each account's rewards and deposit. This checks the
Store introduction and its preservation boundary, rather than equality of every
field across two different era types.

| Case | Contract | Scenario axes |
| --- | --- | --- |
| <a id="ds-state-translation-n01" name="ds-state-translation-n01"></a><a id="ds-state-initialization-n01" name="ds-state-initialization-n01"></a><a id="361-n01---preserves-existing-output-references-addresses-values-datums-and-reference-scripts-and-keeps-those-outputs-implicit" name="361-n01---preserves-existing-output-references-addresses-values-datums-and-reference-scripts-and-keeps-those-outputs-implicit"></a><a id="ds-state-initialization-n02" name="ds-state-initialization-n02"></a><a id="362-n02---initializes-store-balance-and-utxo-capacity-deposit-obligations-to-zero" name="362-n02---initializes-store-balance-and-utxo-capacity-deposit-obligations-to-zero"></a><a id="ds-state-initialization-n03" name="ds-state-initialization-n03"></a><a id="363-n03---does-not-transfer-funds-from-another-ledger-pot-during-initialization" name="363-n03---does-not-transfer-funds-from-another-ledger-pot-during-initialization"></a>**1.&nbsp;[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/TranslationSpec.hs#L38)** | **Introduce legacy allocations.** Apply the real era translation; compare the listed fields independently with their source values, require one legacy allocation per output and assert a zero cached total and empty external-deposit view. | Each generated pair has zero and distinct positive pots. Ten outputs cover absent/hash/inline datums × absent/native/Plutus reference scripts, plus identical payloads at distinct indices. Compare full asset values, datum semantics and script identity. |

<a id="ds-state-epoch" name="ds-state-epoch"></a>

### 3.5.2 Epoch

> **Preserve historical deposits; activate effective parameters for future allocations.**

```math
\mathit{recordsAfter}=\mathit{recordsBefore}
\implies \mathit{storeBalanceAfter}=\mathit{storeBalanceBefore}
```

| Case | Contract | Scenario axes |
| --- | --- | --- |
| <a id="ds-state-epoch-n01" name="ds-state-epoch-n01"></a><a id="ds-state-solvency-n03" name="ds-state-solvency-n03"></a><a id="345-n03---preserve-solvency-across-epochs" name="345-n03---preserve-solvency-across-epochs"></a>**1.&nbsp;[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs#L37)** | **Retain the populated Store.** Cross actual epoch boundaries and compare the complete allocation map. | Fund one to five live allocations through an accepted transaction and cross two successive boundaries. Verify each epoch advanced and protocol parameters stayed unchanged; the cached balance and all historical metadata are preserved. |
| <a id="ds-state-epoch-n02" name="ds-state-epoch-n02"></a>**2.&nbsp;[N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs#L59)** | **Activate the effective price.** A scheduled parameter update changes the current rate without repricing live entries. | Cross real epoch boundaries with V1 and V2 selected. Compare the effective parameters, current formula, complete allocation map and cached total. |

For N02, $`V`$ is the selected formula version, $`r'`$ the newly effective byte price,
and $`s'`$ the first slot of the epoch where the update becomes effective. Append
$`(s',V(r'))`$ to history; entries allocated earlier retain their earlier formula:

```math
\begin{aligned}
\text{currentFormulaAfter} &= V(r') \\
\text{allocationsAfter} &= \text{allocationsBefore} \\
\text{totalDepositAmountAfter} &= \text{totalDepositAmountBefore}
\end{aligned}
```

<a id="ds-state-recovery" name="ds-state-recovery"></a><a id="37-recovery" name="37-recovery"></a><a id="ds-state-recovery-n01" name="ds-state-recovery-n01"></a><a id="371-n01---preserves-the-complete-ledger-state-through-serialization-and-restoration-including-outputs-allocated-records-and-store-surplus" name="371-n01---preserves-the-complete-ledger-state-through-serialization-and-restoration-including-outputs-allocated-records-and-store-surplus"></a>
**Existing codec coverage.** Dijkstra's [test entry point](../../../eras/dijkstra/impl/test/Main.hs#L51)
registers the [Conway common](../../../eras/conway/impl/testlib/Test/Cardano/Ledger/Conway/Binary/RoundTrip.hs#L27)
→ [Alonzo](../../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Binary/RoundTrip.hs#L35)
→ [Shelley state round trips](../../../eras/shelley/impl/testlib/Test/Cardano/Ledger/Shelley/Binary/RoundTrip.hs#L66),
including `AccountingState`, `LedgerState`, `EpochState` and `NewEpochState`. The [state generator](../../../eras/shelley/impl/testlib/Test/Cardano/Ledger/Shelley/Arbitrary.hs#L205)
includes an arbitrary Dijkstra Store, and the [output generator](../../../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Arbitrary.hs#L68)
includes both output forms. This existing serialization coverage stays in the
binary suite. [Allocations P03](#ds-state-allocations-p03) additionally submits an
output whose accepted CBOR is one byte longer than its canonical encoding, then
restores the serialized `AccountingState` and doubles the price. A reference-only
transaction must retain its original record; spending must remove that record.
[Balance P03](#ds-state-balance-p03) checks that the actual Store debit equals the
recorded creation deposit.

<a id="ds-state-recovery-n02" name="ds-state-recovery-n02"></a><a id="372-n02---restores-the-complete-prior-ledger-state-on-rollback-after-ordinary-success-or-accepted-phase-2-failure" name="372-n02---restores-the-complete-prior-ledger-state-on-rollback-after-ordinary-success-or-accepted-phase-2-failure"></a>
**Rollback integration gap.** This ledger package exposes no rollback operation
for a LedgerEffects case to exercise. Consensus integration must restore the
complete prior semantic state after either accepted outcome, then replay the
transition to reproduce its result. Codec equality does not establish rollback
coverage; the former Recovery N02 remains this explicit integration requirement.
