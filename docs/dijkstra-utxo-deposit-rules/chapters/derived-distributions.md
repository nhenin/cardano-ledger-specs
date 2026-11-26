<a id="derived-distributions" name="derived-distributions"></a>

# 4. Derived distributions

[Specification contents](../README.md#table-of-contents) · [← Ledger effects](ledger-effects.md) · [Appendices →](appendices.md) · [Verification record](../verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/chapters/derived-distributions.md)

**Should an external deposit carry stake or voting weight while its output is unspent?** The deposit rules determine how much ADA the ledger holds and when it releases it. The protocol can choose separately how that ADA contributes to the stake distribution and to delegated voting power.

The **prototype** uses the ADA in the output’s value for both distributions. For an eligible minimum-ADA output, that includes its embedded reserve. For an eligible deposit-backed output, only its application ADA carries weight.

## Table of contents

<ul type="none"><li>
<details>
  <summary><a href="#ds-stake">4.1 Stake</a></summary>
  <div><ul type="none"><li>
      <div>•&numsp;<a href="#ds-stake-n01">4.1.1 N01 - Full ADA in a minimum-ADA output</a></div>
      <div>•&numsp;<a href="#ds-stake-n02">4.1.2 N02 - Application ADA in a deposit-backed output</a></div>
      <div>•&numsp;<a href="#ds-stake-n03">4.1.3 N03 - Several deposits in the Store</a></div>
      <div>•&numsp;<a href="#ds-stake-n04">4.1.4 N04 - Allocate a deposit</a></div>
      <div>•&numsp;<a href="#ds-stake-n05">4.1.5 N05 - Release a deposit</a></div>
      <div>•&numsp;<a href="#ds-stake-n06">4.1.6 N06 - Ordinary success with collateral</a></div>
      <div>•&numsp;<a href="#ds-stake-n07">4.1.7 N07 - Accepted phase-2 failure</a></div>
      <div>•&numsp;<a href="#ds-stake-n08">4.1.8 N08 - Eligibility, delegation and snapshots</a></div>
  </li></ul></div>
</details>
<details>
  <summary><a href="#ds-voting">4.2 Voting</a></summary>
  <div><ul type="none"><li>
      <div>•&numsp;<a href="#ds-voting-n01">4.2.1 N01 - Weight delegated to two DReps</a></div>
  </li></ul></div>
</details>
</li></ul>

Consider one eligible deposit-backed output holding **8 ADA** in its value, with **2 ADA** held separately. The figure compares two ways to calculate its contribution to a distribution from the same ledger state.

![An eligible output carries 8 ADA and requires a separate 2 ADA deposit. The prototype attributes 8 ADA to the credential. A policy that also attributes the external deposit gives it 10 ADA. The ledger accounts for 10 ADA in both cases.](../images/external-deposit-distribution-policy.svg)

The prototype can derive both distributions from the output values it already tracks. An **alternative** could credit each live external deposit to its output’s staking credential at the relevant snapshot. For an eligible credential, converting a 10 ADA minimum-ADA output into the 8 + 2 ADA form would then preserve its weight. Such a policy would need to specify the recipient, eligibility and snapshot for each distribution. All nodes must agree on those rules.

Under either policy, the 2 ADA remains in the deposit until the output is spent. The ledger counts it once in the monetary total. [Deposit accounting](domain-model.md#section-1-1) · [ADA conservation](ledger-effects.md#ds-state-conservation)

<a id="ds-stake" name="ds-stake"></a>

## 4.1 Stake

The prototype updates instant stake from the outputs the ledger actually consumes and creates. For each output with a base staking credential, it uses the ADA in the output’s value. Registration and pool delegation determine which credentials contribute to the pool distribution at its usual snapshot. [Stake update](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/Stake.hs#L19-L24) · [Output ADA by credential](../../../eras/conway/impl/src/Cardano/Ledger/Conway/State/Accounting/InstantStake.hs#L102-L123) · [Pool snapshot](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Snap.hs#L124-L130)

**While the output is live.** Assume the examples below use eligible, delegated credentials.

| Case | Live outputs | Contribution under the prototype |
| --- | --- | --- |
| <a id="ds-stake-n01" name="ds-stake-n01"></a><a id="411-n01---counts-the-full-ada-in-min-ada-outputs-under-the-existing-staking-rules" name="411-n01---counts-the-full-ada-in-min-ada-outputs-under-the-existing-staking-rules"></a>**4.1.1 N01** | A minimum-ADA output holds **10 ADA**, including its embedded reserve. | The credential contributes **10 ADA**. |
| <a id="ds-stake-n02" name="ds-stake-n02"></a><a id="412-n02---counts-only-application-ada-in-deposit-backed-outputs-under-the-existing-staking-rules" name="412-n02---counts-only-application-ada-in-deposit-backed-outputs-under-the-existing-staking-rules"></a>**4.1.2 N02** | A deposit-backed output holds **8 ADA** and has a **2 ADA** external deposit. | The credential contributes **8 ADA**. An output carrying only tokens contributes **0 ADA**, even with a positive deposit. |
| <a id="ds-stake-n03" name="ds-stake-n03"></a><a id="413-n03---does-not-add-the-global-store-balance-to-stake-totals" name="413-n03---does-not-add-the-global-store-balance-to-stake-totals"></a>**4.1.3 N03** | Two deposit-backed outputs carry **8 ADA** and **4 ADA** for different credentials. Their deposits are 2 ADA and 1 ADA. | The credentials contribute **8 ADA** and **4 ADA** respectively. The Store’s 3 ADA total adds no weight to either credential. |

**When a transaction is applied.** The ledger updates each credential’s UTxO stake as it spends and creates outputs. The pool distribution uses those amounts at the applicable snapshot. The allocation and release examples below keep the same credential and fund fees separately.

| Case | Applied transaction | Effect on stake |
| --- | --- | --- |
| <a id="ds-stake-n04" name="ds-stake-n04"></a><a id="414-n04---derive-stake-from-applied-allocations" name="414-n04---derive-stake-from-applied-allocations"></a>**4.1.4 N04** | Spend the 10 ADA minimum-ADA output. Create an output carrying 8 ADA with a 2 ADA external deposit. | The credential’s base goes from **10 to 8 ADA**. The new output supplies the 8 ADA. |
| <a id="ds-stake-n05" name="ds-stake-n05"></a><a id="415-n05---derive-stake-from-applied-releases" name="415-n05---derive-stake-from-applied-releases"></a>**4.1.5 N05** | Spend that deposit-backed output. Put its 8 ADA of value and the released 2 ADA into a 10 ADA minimum-ADA output. | The base goes from **8 to 10 ADA**. The new output already includes the released ADA. |
| <a id="ds-stake-n06" name="ds-stake-n06"></a><a id="416-n06---ignore-unapplied-collateral" name="416-n06---ignore-unapplied-collateral"></a>**4.1.6 N06** | Ordinary execution succeeds. | Remove the ordinary inputs and add the ordinary outputs. Collateral-only inputs stay live. A reference used for both ordinary spending and collateral is consumed once. The proposed collateral return adds no stake. |
| <a id="ds-stake-n07" name="ds-stake-n07"></a><a id="417-n07---derive-stake-from-collateral-on-phase-2-failure" name="417-n07---derive-stake-from-collateral-on-phase-2-failure"></a>**4.1.7 N07** | An accepted phase-2 failure spends collateral. | Remove the spent collateral inputs, including an input also named for ordinary spending. Add the ADA carried by the actual return, if any, if its address supplies a staking credential. This applies to both return forms. Unapplied ordinary outputs contribute nothing. |
| <a id="ds-stake-n08" name="ds-stake-n08"></a><a id="418-n08---preserves-existing-staking-eligibility-delegation-and-snapshot-timing-after-allocation-release-and-collateral-effects" name="418-n08---preserves-existing-staking-eligibility-delegation-and-snapshot-timing-after-allocation-release-and-collateral-effects"></a>**4.1.8 N08** | An allocation, release or collateral spend changes which outputs are live before a snapshot. | At the usual boundary, each eligible credential contributes to its delegated pool. An output without an eligible delegation adds no pool stake. The transaction itself does not advance the snapshot. |

<a id="ds-voting" name="ds-voting"></a>

## 4.2 Voting

The prototype makes the same choice for **delegated representative (DRep) voting power**. The UTxO contribution comes from the ADA attributed to each eligible staking credential. Its DRep delegation determines who receives that weight. The existing voting calculation also includes eligible account balances and governance proposal deposits under their own rules. [DRep distribution calculation](../../../eras/conway/impl/src/Cardano/Ledger/Conway/Governance/DRepPulser.hs#L210-L242)

<a id="ds-voting-n01" name="ds-voting-n01"></a><a id="421-n01---preserves-the-expected-voting-distribution-from-eligible-funds-while-excluding-allocated-utxo-capacity-deposits-and-store-balance" name="421-n01---preserves-the-expected-voting-distribution-from-eligible-funds-while-excluding-allocated-utxo-capacity-deposits-and-store-balance"></a>

### 4.2.1 N01 - Weight delegated to two DReps

At the voting snapshot, consider two credentials with eligible delegations.

- **DRep A** receives **10 ADA** of weight from a minimum-ADA output carrying 10 ADA. Its embedded reserve is included in that value.
- **DRep B** receives **8 ADA** of weight from the deposit-backed output in the figure. Crediting the external deposit as well would give B **10 ADA** under the alternative policy.

To check the prototype’s policy, compare the complete distribution across a snapshot after ordinary success and after an accepted phase-2 failure. Include other eligible funds, a credential without an eligible DRep delegation, and external deposits on multiple live outputs. Check the amount attributed to **each DRep**. A grand total alone would miss weight credited to the wrong representative.

**Verification status.** The eight stake cases and the voting case above describe expected prototype behavior. Their dedicated distribution tests are deferred. [Verification record](../verification.md#current-implementation-status)
