<a id="spec-appendices" name="spec-appendices"></a>

# Appendices

[Specification contents](../README.md#table-of-contents) · [← Derived distributions](derived-distributions.md) · [Verification record](../verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/chapters/appendices.md)

Use Appendix A to implement the ledger interfaces and encodings. Use Appendix B to check the net change a SubTx or TopTx declares.

## Table of contents

<ul type="none"><li>
<details>
  <summary><a href="#ledger-interfaces-and-encodings">A. Ledger interfaces and encodings</a></summary>
  <div><ul type="none"><li>
    <div>•&numsp;<a href="#declaration-api">A.1 Declaration API and body fields</a></div>
    <div>•&numsp;<a href="#declaration-encoding">A.2 Declaration encoding</a></div>
    <div>•&numsp;<a href="#state-modules-apis-and-encoding">A.3 Ledger state APIs and snapshots</a></div>
  </li></ul></div>
</details>
<details>
  <summary><a href="#net-change-conformance-cases">B. Net-change conformance cases</a></summary>
  <div><ul type="none"><li>
    <div>•&numsp;<a href="#subtx-net-change-test-cases">B.1 SubTx cases</a></div>
    <div>•&numsp;<a href="#toptx-net-change-test-cases">B.2 TopTx cases</a></div>
  </li></ul></div>
</details>
</li></ul>

<a id="section-8" name="section-8"></a><a id="a-remaining-design-work" name="a-remaining-design-work"></a><a id="a1-plutus-compatibility" name="a1-plutus-compatibility"></a><a id="a2-plutus-compatibility" name="a2-plutus-compatibility"></a><a id="ds-plutus-compatibility" name="ds-plutus-compatibility"></a>[Script-visible output value](domain-model.md#script-visible-output-value) · <a id="section-9" name="section-9"></a><a id="b-tag-migration" name="b-tag-migration"></a><a id="b-reading-test-case-identifiers" name="b-reading-test-case-identifiers"></a>[Test case identifiers](../README.md#reading-test-case-identifiers) · <a id="a3-local-settlement" name="a3-local-settlement"></a><a id="ds-tx-settlement-refinement" name="ds-tx-settlement-refinement"></a>[Settlement output rule](transaction-rules.md#ds-tx-settlement-output-coin)

<a id="section-10" name="section-10"></a><a id="c-code-references" name="c-code-references"></a>
<a id="ledger-interfaces-and-encodings" name="ledger-interfaces-and-encodings"></a>

## A. Ledger interfaces and encodings

Transaction builders use the declaration types and body fields in A.1 and the wire formats in A.2.
Ledger clients use the state queries and snapshot formats in A.3. For test coverage and results,
see the [verification record](../verification.md#current-implementation-status).

<a id="c1-declaration-api" name="c1-declaration-api"></a><a id="declaration-api" name="declaration-api"></a>
<a id="c2-transaction-body-fields" name="c2-transaction-body-fields"></a><a id="transaction-body-fields" name="transaction-body-fields"></a>

### A.1 Declaration API and body fields

The TopTx field declares the net change for the complete transaction. Each SubTx field declares its
own change and can request TopTx funding or settlement. The body types expose these fields through
separate lenses. [Dijkstra transaction bodies](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxBody.hs#L1688)

| Body | Declaration type | Declaration field and lens | Own regular outputs |
| --- | --- | --- | --- |
| TopTx | `TopTxUTxODepositDeclaration` | `dtbrNetUTxODepositChange` / `netUTxODepositChangeTxBodyL` | `dtbrOutputs` |
| SubTx | `SubTxUTxODepositDeclaration` | `dstbrNetUTxODepositChange` / `subTxNetUTxODepositChangeTxBodyL` | `dstbrOutputs` |

Use the qualifier `TopTx.` or `SubTx.` to select the pattern from the declaring body’s module.
[TopTx API](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/TopTx.hs) · [SubTx API](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/SubTx.hs)

| Declaration | Pattern | Body |
| --- | --- | --- |
| Absent | `NoUTxODepositDeclaration` | Both |
| Explicit zero | `DeclaresZeroNetUTxODeposit` | Both |
| Allocate | `DeclaresNetUTxODepositAllocation amount` | Both |
| Release | `DeclaresNetUTxODepositRelease amount destination` | Both, with body-specific destinations in A.2 |
| Allocate with TopTx funding | `RequestsUTxODepositFromTopTx amount` | SubTx |

`hasUTxODepositDeclaration` is true for every explicit form, including zero.
`mkStrictlyPositiveCoin` accepts amounts from 1 to $2^{64}-1$ lovelace and returns
`Nothing` outside that range. The declaration requirements specify when a body must supply
the field. [Amount API](../../../libs/cardano-ledger-core/src/Cardano/Ledger/StrictlyPositiveCoin.hs) · [Declaration requirements](transaction-rules.md#ds-tx-declarations-requirements)

<a id="c3-declaration-encoding" name="c3-declaration-encoding"></a><a id="declaration-encoding" name="declaration-encoding"></a>

### A.2 Declaration encoding

Both transaction bodies use optional CBOR map key `28` and the JSON field
`netUTxODepositChange`. An absent declaration omits the CBOR key. The JSON body encoder
writes `null` for absence and the decoder accepts either a missing field or `null`.
In the encodings below, `a` is the positive amount in lovelace and `d` is the destination
encoded for the declaring body. [TopTx CDDL](../../../eras/dijkstra/impl/cddl/data/dijkstra.cddl#L979) · [SubTx CDDL](../../../eras/dijkstra/impl/cddl/data/dijkstra.cddl#L877) · [Body JSON codec](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxBody.hs#L713)

| Declaration | Body | Value at CBOR key 28 | JSON field value |
| --- | --- | --- | --- |
| Explicit zero | TopTx | `[2]` | `{"kind":"noChange"}` |
| Explicit zero | SubTx | `[3]` | `{"kind":"noChange"}` |
| Allocate | Both | `[0, a]` | `{"kind":"allocate","amount":a}` |
| Release | TopTx | `[1, a, d]` | `{"kind":"release","amount":a,"settlement":d}` |
| Release | SubTx | `[1, a, d]` | `{"kind":"release","amount":a,"target":d}` |
| Request TopTx funding | SubTx | `[2, a]` | `{"kind":"requestUTxODepositFromTopTx","amount":a}` |

A settlement output index `i` is an unsigned 16-bit integer counting from zero in the
declaring body’s own regular outputs. [Settlement index rule](transaction-rules.md#ds-tx-settlement-output-index)

| Destination | Body | CBOR `d` | JSON `d` |
| --- | --- | --- | --- |
| `NoTopTxSettlement` | TopTx | `[0]` | `{"kind":"noTopTxSettlement"}` |
| `TopTxSettlementOutput i` | TopTx | `[1, i]` | `{"kind":"topTxSettlementOutput","outputIndex":i}` |
| `SubTxSettlementOutput i` | SubTx | `[0, i]` | `{"kind":"subTxSettlementOutput","outputIndex":i}` |
| `DelegateToTopTx` | SubTx | `[1]` | `{"kind":"delegateToTopTx"}` |

The decoders reject zero, negative and overflowing operation amounts. The binary tests exercise
the exact bytes, JSON objects and field omission for both bodies. [Encoding tests](../../../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Binary/Golden.hs)

<a id="a4-state-representation" name="a4-state-representation"></a><a id="ds-state-representation" name="ds-state-representation"></a>
<a id="c4-state-representation" name="c4-state-representation"></a><a id="c4-state-modules-apis-and-encoding" name="c4-state-modules-apis-and-encoding"></a>
<a id="state-modules-apis-and-encoding" name="state-modules-apis-and-encoding"></a>

### A.3 Ledger state APIs and snapshots

`allocations store` maps each live `TxIn` to an `Unspent TxOut` with its accepted output and
allocation origin. Both minimum-ADA and deposit-backed outputs have entries. A minimum-ADA
output keeps its reserve in its value and contributes zero to the Store’s external total.
[Ledger state layout and updates](ledger-effects.md#ds-state-representation)

| Operation | Interface |
| --- | --- |
| Read proposed outputs | `outputsTxBody` indexes the body’s regular `Sized TxOut` values. `producedTxOuts` selects regular outputs or collateral return for a TopTx. [Body outputs](../../../libs/cardano-ledger-core/src/Cardano/Ledger/Core.hs#L539) · [Transaction outputs](../../../libs/cardano-ledger-api/src/Cardano/Ledger/Api/Tx.hs#L150) |
| Read accepted entries | `lookupUTxO` returns one entry. `restrictToInputs` preserves allocation origins for selected inputs. `sumDepositAmounts history` gives their total external deposit. [IndexedUTxOs](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/IndexedUTxOs.hs) |
| Apply or restore Store state | `projectTx slot tx store` projects the TopTx’s own selected inputs and outputs. It returns `updatedStore`, `consumedOutputs` and `producedOutputs`. `mkUTxOStore history entries` reconstructs the Store and derives its external total. [Store API](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Store.hs) |

The CBOR encoding of `LedgerState` is
`[certState, [store, deposited, fees, govState, instantStake, donation]]`.
Reading the certificate state first lets later fields share decoded credentials.
Ledger JSON exposes `delegationState` and `utxoState`, with governance under `utxoState.ppups`.
[Ledger state codecs](../../../eras/shelley/impl/src/Cardano/Ledger/Shelley/LedgerState/Types.hs#L390)

| Era | Indexed UTxO query CBOR | Store snapshot and standalone Store CBOR |
| --- | --- | --- |
| Before Dijkstra | Map from input to output payload. | The legacy map with MemPack inputs and output payloads. Decoding reconstructs `AtStoreMigration` entries with zero external deposits. |
| Dijkstra | Map from input to `[output, allocatedAt]`. | `[depositFormulaHistory, cachedTotal, allocationMap]`. The map uses MemPack inputs and output payloads and retains each allocation origin. The decoder checks the order of the dated changes and verifies the cached total against the entries. |

<a id="a1-historical-pricing" name="a1-historical-pricing"></a><a id="ds-pricing-history" name="ds-pricing-history"></a>

Dijkstra snapshots carry the history as `[initialFormula, formulaChanges]`, including when the
Store is empty. The origin encodes as `[0]` for `AtStoreMigration` or `[3, slot]` for `AtSlot slot`.
Dijkstra decoding requires the pricing history to restore the original deposits.
[Store codec](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Store/Internals.hs#L217) · [Allocation origin codec](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Unspent.hs#L100)

Pre-Dijkstra snapshots contain only the input-to-output map. Ordinary decoding supplies a V1
baseline of 4,310 lovelace per byte. `decodeUTxOStoreWithFormula` accepts a caller-supplied
baseline for those bytes. At the Dijkstra fork, translation uses the effective protocol parameters
for the migration baseline. [Historical pricing](domain-model.md#ds-pricing-history) · [Fork translation](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Translation.hs#L237)

<a id="net-change-test-cases" name="net-change-test-cases"></a><a id="d-net-change-test-cases" name="d-net-change-test-cases"></a><a id="net-change-conformance-cases" name="net-change-conformance-cases"></a>

## B. Net-change conformance cases

The [net-change rule](transaction-rules.md#ds-tx-accounting-net-change) checks each declaring SubTx’s own change and the TopTx’s total for the batch. Both use the required backing of proposed ordinary outputs and the backing credited to ordinary inputs. The cases that isolate external deposits match the embedded reserves on both sides. Chapter 2 also gives examples where the embedded reserves differ.

Case identifiers link to the executable tests. The one-lovelace mutations keep both the original and altered magnitudes positive and representable. The accepted examples satisfy the other ledger checks.

<a id="subtx-net-change-test-cases" name="subtx-net-change-test-cases"></a><a id="d1-subtx-net-change-cases" name="d1-subtx-net-change-cases"></a>

### B.1 SubTx cases

The TopTx declares the correct batch total throughout. Each rejected case must report `InexactSubTxDepositChange`. [SubTx net-change rule](transaction-rules.md#ds-tx-accounting-net-change-subtx)

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-exactness-contribution-p01" name="ds-tx-exactness-contribution-p01"></a><a id="ds-tx-exactness-subtx-p01" name="ds-tx-exactness-subtx-p01"></a><a id="ds-tx-accounting-subtx-p01" name="ds-tx-accounting-subtx-p01"></a><a id="ds-tx-accounting-net-change-subtx-p01" name="ds-tx-accounting-net-change-subtx-p01"></a>[P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L90) | Price the outputs and recover the backing of inputs independently for every SubTx with a declaration. | SubTx exactness passes if and only if every declared amount equals that body's own change. |
| <a id="ds-tx-exactness-contribution-n01" name="ds-tx-exactness-contribution-n01"></a><a id="ds-tx-exactness-subtx-n01" name="ds-tx-exactness-subtx-n01"></a><a id="ds-tx-accounting-subtx-n01" name="ds-tx-accounting-subtx-n01"></a><a id="ds-tx-accounting-net-change-subtx-n01" name="ds-tx-accounting-net-change-subtx-n01"></a>[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L126) | A SubTx accounts locally for its allocation, release or zero change. | Accept the signed amount computed for that body. |
| <a id="ds-tx-exactness-contribution-f01" name="ds-tx-exactness-contribution-f01"></a><a id="ds-tx-exactness-subtx-f01" name="ds-tx-exactness-subtx-f01"></a><a id="ds-tx-accounting-subtx-f01" name="ds-tx-accounting-subtx-f01"></a><a id="ds-tx-accounting-net-change-subtx-f01" name="ds-tx-accounting-net-change-subtx-f01"></a>[F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L148) | An allocation greater than one lovelace is understated by one lovelace. | Reject the smaller allocation. |
| <a id="ds-tx-exactness-contribution-f02" name="ds-tx-exactness-contribution-f02"></a><a id="ds-tx-exactness-subtx-f02" name="ds-tx-exactness-subtx-f02"></a><a id="ds-tx-accounting-subtx-f02" name="ds-tx-accounting-subtx-f02"></a><a id="ds-tx-accounting-net-change-subtx-f02" name="ds-tx-accounting-net-change-subtx-f02"></a>[F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L166) | A positive allocation is overstated by one lovelace. | Reject the larger allocation. |
| <a id="ds-tx-exactness-contribution-f03" name="ds-tx-exactness-contribution-f03"></a><a id="ds-tx-exactness-subtx-f03" name="ds-tx-exactness-subtx-f03"></a><a id="ds-tx-accounting-subtx-f03" name="ds-tx-accounting-subtx-f03"></a><a id="ds-tx-accounting-net-change-subtx-f03" name="ds-tx-accounting-net-change-subtx-f03"></a>[F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L184) | A release greater than one lovelace is understated by one lovelace. | Reject the smaller release. Its signed value is one lovelace too high. |
| <a id="ds-tx-exactness-contribution-f04" name="ds-tx-exactness-contribution-f04"></a><a id="ds-tx-exactness-subtx-f04" name="ds-tx-exactness-subtx-f04"></a><a id="ds-tx-accounting-subtx-f04" name="ds-tx-accounting-subtx-f04"></a><a id="ds-tx-accounting-net-change-subtx-f04" name="ds-tx-accounting-net-change-subtx-f04"></a>[F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L202) | A positive release is overstated by one lovelace. | Reject the larger release. Its signed value is one lovelace too low. |
| <a id="ds-tx-exactness-contribution-f05" name="ds-tx-exactness-contribution-f05"></a><a id="ds-tx-exactness-subtx-f05" name="ds-tx-exactness-subtx-f05"></a><a id="ds-tx-accounting-subtx-f05" name="ds-tx-accounting-subtx-f05"></a><a id="ds-tx-accounting-net-change-subtx-f05" name="ds-tx-accounting-net-change-subtx-f05"></a>[F05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L220) | Two SubTxs have opposite, nonzero errors that cancel in the batch total. | Reject even though the TopTx total is exact. |
| <a id="ds-tx-exactness-contribution-n03" name="ds-tx-exactness-contribution-n03"></a><a id="ds-tx-exactness-subtx-n02" name="ds-tx-exactness-subtx-n02"></a><a id="ds-tx-accounting-subtx-n02" name="ds-tx-accounting-subtx-n02"></a><a id="ds-tx-accounting-net-change-subtx-n02" name="ds-tx-accounting-net-change-subtx-n02"></a>[N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L239) | Allocations equal releases, including the case where both are zero. | Accept an explicit zero declaration. |
| <a id="ds-tx-exactness-contribution-f06" name="ds-tx-exactness-contribution-f06"></a><a id="ds-tx-exactness-subtx-f06" name="ds-tx-exactness-subtx-f06"></a><a id="ds-tx-accounting-subtx-f06" name="ds-tx-accounting-subtx-f06"></a><a id="ds-tx-accounting-net-change-subtx-f06" name="ds-tx-accounting-net-change-subtx-f06"></a>[F06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L248) | A SubTx with a net allocation declares explicit zero. | Reject. The SubTx must declare the allocation. |
| <a id="ds-tx-exactness-contribution-n04" name="ds-tx-exactness-contribution-n04"></a><a id="ds-tx-exactness-subtx-n03" name="ds-tx-exactness-subtx-n03"></a><a id="ds-tx-accounting-subtx-n03" name="ds-tx-accounting-subtx-n03"></a><a id="ds-tx-accounting-net-change-subtx-n03" name="ds-tx-accounting-net-change-subtx-n03"></a>[N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L266) | A SubTx requests funding from the TopTx. | Accept `RequestsUTxODepositFromTopTx` for the child's exact allocation. |
| <a id="ds-tx-exactness-contribution-n05" name="ds-tx-exactness-contribution-n05"></a><a id="ds-tx-exactness-subtx-n04" name="ds-tx-exactness-subtx-n04"></a><a id="ds-tx-accounting-subtx-n04" name="ds-tx-accounting-subtx-n04"></a><a id="ds-tx-accounting-net-change-subtx-n04" name="ds-tx-accounting-net-change-subtx-n04"></a>[N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L278) | A SubTx delegates its release to the TopTx. | Accept `DelegateToTopTx` with the child's exact release magnitude. |
| <a id="ds-tx-exactness-contribution-n06" name="ds-tx-exactness-contribution-n06"></a><a id="ds-tx-exactness-subtx-n05" name="ds-tx-exactness-subtx-n05"></a><a id="ds-tx-accounting-subtx-n05" name="ds-tx-accounting-subtx-n05"></a><a id="ds-tx-accounting-net-change-subtx-n05" name="ds-tx-accounting-net-change-subtx-n05"></a>[N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L290) | A SubTx consumes historical external deposits and creates only min-ADA outputs. Embedded input and output backing are equal. | Accept a release equal to the external deposits consumed. |
| <a id="ds-tx-exactness-contribution-f07" name="ds-tx-exactness-contribution-f07"></a><a id="ds-tx-exactness-subtx-f07" name="ds-tx-exactness-subtx-f07"></a><a id="ds-tx-accounting-subtx-f07" name="ds-tx-accounting-subtx-f07"></a><a id="ds-tx-accounting-net-change-subtx-f07" name="ds-tx-accounting-net-change-subtx-f07"></a>[F07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L302) | A SubTx with a net release declares explicit zero. | Reject. The SubTx must declare the release. |
| <a id="ds-tx-exactness-contribution-n07" name="ds-tx-exactness-contribution-n07"></a><a id="ds-tx-exactness-subtx-n06" name="ds-tx-exactness-subtx-n06"></a><a id="ds-tx-accounting-subtx-n06" name="ds-tx-accounting-subtx-n06"></a><a id="ds-tx-accounting-net-change-subtx-n06" name="ds-tx-accounting-net-change-subtx-n06"></a>[N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L320) | An allocation by the TopTx or a sibling offsets some, all or more than the SubTx release. | Accept the child's full own release in each case. |
| <a id="ds-tx-exactness-contribution-n08" name="ds-tx-exactness-contribution-n08"></a><a id="ds-tx-exactness-subtx-n07" name="ds-tx-exactness-subtx-n07"></a><a id="ds-tx-accounting-subtx-n07" name="ds-tx-accounting-subtx-n07"></a><a id="ds-tx-accounting-net-change-subtx-n07" name="ds-tx-accounting-net-change-subtx-n07"></a>[N07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L342) | A SubTx creates one deposit-backed output with no application assets, at a positive rate, and releases no external deposits. | Accept the allocation covering the formula's base charge. |
| <a id="ds-tx-exactness-contribution-n09" name="ds-tx-exactness-contribution-n09"></a><a id="ds-tx-exactness-subtx-n08" name="ds-tx-exactness-subtx-n08"></a><a id="ds-tx-accounting-subtx-n08" name="ds-tx-accounting-subtx-n08"></a><a id="ds-tx-accounting-net-change-subtx-n08" name="ds-tx-accounting-net-change-subtx-n08"></a>[N08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L354) | A translated min-ADA input is the sole ordinary input funding deposit-backed outputs. Its credited reserve equals the reserve on the min-ADA change output. | Accept the allocation equal to the new external deposits. |
| <a id="ds-tx-exactness-contribution-f08" name="ds-tx-exactness-contribution-f08"></a><a id="ds-tx-exactness-subtx-f08" name="ds-tx-exactness-subtx-f08"></a><a id="ds-tx-accounting-subtx-f08" name="ds-tx-accounting-subtx-f08"></a><a id="ds-tx-accounting-net-change-subtx-f08" name="ds-tx-accounting-net-change-subtx-f08"></a>[F08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L366) | In the N08 transaction, the SubTx declares a different positive, representable allocation. | Reject the inexact allocation. |
| <a id="ds-tx-exactness-contribution-f09" name="ds-tx-exactness-contribution-f09"></a><a id="ds-tx-exactness-subtx-f09" name="ds-tx-exactness-subtx-f09"></a><a id="ds-tx-accounting-subtx-f09" name="ds-tx-accounting-subtx-f09"></a><a id="ds-tx-accounting-net-change-subtx-f09" name="ds-tx-accounting-net-change-subtx-f09"></a>[F09](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L385) | A SubTx with zero change or a release claims part of the recorded deposits on one to four other outputs that remain unspent. | Reject the extra release. The original declaration passes. |
| <a id="ds-tx-exactness-contribution-f10" name="ds-tx-exactness-contribution-f10"></a><a id="ds-tx-exactness-subtx-f10" name="ds-tx-exactness-subtx-f10"></a><a id="ds-tx-accounting-subtx-f10" name="ds-tx-accounting-subtx-f10"></a><a id="ds-tx-accounting-net-change-subtx-f10" name="ds-tx-accounting-net-change-subtx-f10"></a>[F10](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L410) | A SubTx requiring an allocation declares a release, either locally or through delegation. | Reject either release form. |
| <a id="ds-tx-exactness-contribution-f11" name="ds-tx-exactness-contribution-f11"></a><a id="ds-tx-exactness-subtx-f11" name="ds-tx-exactness-subtx-f11"></a><a id="ds-tx-accounting-subtx-f11" name="ds-tx-accounting-subtx-f11"></a><a id="ds-tx-accounting-net-change-subtx-f11" name="ds-tx-accounting-net-change-subtx-f11"></a>[F11](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L429) | A SubTx requiring a release declares a local allocation or requests funding from the TopTx. | Reject either allocation form. |
| <a id="ds-tx-exactness-contribution-n10" name="ds-tx-exactness-contribution-n10"></a><a id="ds-tx-exactness-subtx-n09" name="ds-tx-exactness-subtx-n09"></a><a id="ds-tx-accounting-subtx-n09" name="ds-tx-accounting-subtx-n09"></a><a id="ds-tx-accounting-net-change-subtx-n09" name="ds-tx-accounting-net-change-subtx-n09"></a>[N09](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L449) | A script fails as declared. Each participating SubTx declares its exact ordinary backing change. | Accept the collateral outcome. The ledger applies only collateral effects. |
| <a id="ds-tx-exactness-contribution-f12" name="ds-tx-exactness-contribution-f12"></a><a id="ds-tx-exactness-subtx-f12" name="ds-tx-exactness-subtx-f12"></a><a id="ds-tx-accounting-subtx-f12" name="ds-tx-accounting-subtx-f12"></a><a id="ds-tx-accounting-net-change-subtx-f12" name="ds-tx-accounting-net-change-subtx-f12"></a>[F12](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L471) | A script fails as declared, but a SubTx changes its otherwise exact declaration. | Reject before collateral settlement. |

<a id="toptx-net-change-test-cases" name="toptx-net-change-test-cases"></a><a id="d2-toptx-net-change-cases" name="d2-toptx-net-change-cases"></a>

### B.2 TopTx cases

Every participating SubTx declaration is exact. Each rejected case must report `InexactTopTxDepositChange`. [TopTx net-change rule](transaction-rules.md#ds-tx-accounting-net-change-toptx)

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-exactness-netting-p01" name="ds-tx-exactness-netting-p01"></a><a id="ds-tx-exactness-toptx-p01" name="ds-tx-exactness-toptx-p01"></a><a id="ds-tx-accounting-toptx-p01" name="ds-tx-accounting-toptx-p01"></a><a id="ds-tx-accounting-net-change-toptx-p01" name="ds-tx-accounting-net-change-toptx-p01"></a>[P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L72) | Calculate the backing change independently across the TopTx and all SubTxs. | TopTx exactness passes if and only if its declaration equals that total. |
| <a id="ds-tx-attribution-n02" name="ds-tx-attribution-n02"></a><a id="ds-tx-accounting-net-change-toptx-p02" name="ds-tx-accounting-net-change-toptx-p02"></a>[P02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L90) | Keep originating Store operations fixed. For a child allocation and a child release, compare local accounting with delegation. Fund, sign and settle each version for its own declarations. | Accept both versions with the same batch declaration. Responsibility follows [Attribution P02](transaction-rules.md#ds-tx-accounting-attribution-p02). |
| <a id="ds-tx-exactness-netting-n01" name="ds-tx-exactness-netting-n01"></a><a id="ds-tx-exactness-toptx-n01" name="ds-tx-exactness-toptx-n01"></a><a id="ds-tx-accounting-toptx-n01" name="ds-tx-accounting-toptx-n01"></a><a id="ds-tx-accounting-net-change-toptx-n01" name="ds-tx-accounting-net-change-toptx-n01"></a>[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L122) | At least one child has a nonzero own change. The parent's own change may be zero or nonzero. | Accept the sum of the parent's and every child's own change, each counted once. |
| <a id="ds-tx-exactness-contribution-n02" name="ds-tx-exactness-contribution-n02"></a><a id="ds-tx-exactness-toptx-n02" name="ds-tx-exactness-toptx-n02"></a><a id="ds-tx-accounting-toptx-n02" name="ds-tx-accounting-toptx-n02"></a><a id="ds-tx-accounting-net-change-toptx-n02" name="ds-tx-accounting-net-change-toptx-n02"></a>[N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L135) | Subtract all present, exact child declarations, including delegated ones, from the exact batch total. Each undeclared child in this case has zero net embedded backing. | The remainder equals the parent's own change. In the general case subtract every child's computed backing change. |
| <a id="ds-tx-exactness-netting-n02" name="ds-tx-exactness-netting-n02"></a><a id="ds-tx-exactness-toptx-n03" name="ds-tx-exactness-toptx-n03"></a><a id="ds-tx-accounting-toptx-n03" name="ds-tx-accounting-toptx-n03"></a><a id="ds-tx-accounting-net-change-toptx-n03" name="ds-tx-accounting-net-change-toptx-n03"></a>[N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L148) | Across the batch, 5 ADA is allocated and 3 ADA is released. | Accept `Allocate 2 ADA`. |
| <a id="ds-tx-exactness-netting-n03" name="ds-tx-exactness-netting-n03"></a><a id="ds-tx-exactness-toptx-n04" name="ds-tx-exactness-toptx-n04"></a><a id="ds-tx-accounting-toptx-n04" name="ds-tx-accounting-toptx-n04"></a><a id="ds-tx-accounting-net-change-toptx-n04" name="ds-tx-accounting-net-change-toptx-n04"></a>[N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L159) | Across the batch, 3 ADA is allocated and 5 ADA is released. | Accept `Release 2 ADA`. |
| <a id="ds-tx-exactness-netting-n04" name="ds-tx-exactness-netting-n04"></a><a id="ds-tx-exactness-toptx-n05" name="ds-tx-exactness-toptx-n05"></a><a id="ds-tx-accounting-toptx-n05" name="ds-tx-accounting-toptx-n05"></a><a id="ds-tx-accounting-net-change-toptx-n05" name="ds-tx-accounting-net-change-toptx-n05"></a>[N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L171) | Nonzero body changes offset one another exactly. | Accept an explicit zero declaration. |
| <a id="ds-tx-exactness-netting-f01" name="ds-tx-exactness-netting-f01"></a><a id="ds-tx-exactness-toptx-f01" name="ds-tx-exactness-toptx-f01"></a><a id="ds-tx-accounting-toptx-f01" name="ds-tx-accounting-toptx-f01"></a><a id="ds-tx-accounting-net-change-toptx-f01" name="ds-tx-accounting-net-change-toptx-f01"></a>[F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L181) | A standalone TopTx creates one more deposit-backed output than it consumes. Its required allocation exceeds one lovelace. | Reject an allocation understated by one lovelace. |
| <a id="ds-tx-exactness-netting-f02" name="ds-tx-exactness-netting-f02"></a><a id="ds-tx-exactness-toptx-f02" name="ds-tx-exactness-toptx-f02"></a><a id="ds-tx-accounting-toptx-f02" name="ds-tx-accounting-toptx-f02"></a><a id="ds-tx-accounting-net-change-toptx-f02" name="ds-tx-accounting-net-change-toptx-f02"></a>[F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L193) | A standalone TopTx creates one more deposit-backed output than it consumes and has a positive net allocation. | Reject an allocation overstated by one lovelace. |
| <a id="ds-tx-exactness-netting-f03" name="ds-tx-exactness-netting-f03"></a><a id="ds-tx-exactness-toptx-f03" name="ds-tx-exactness-toptx-f03"></a><a id="ds-tx-accounting-toptx-f03" name="ds-tx-accounting-toptx-f03"></a><a id="ds-tx-accounting-net-change-toptx-f03" name="ds-tx-accounting-net-change-toptx-f03"></a>[F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L206) | A standalone TopTx creates only min-ADA outputs. Its required release exceeds one lovelace. | Reject a release understated by one lovelace. |
| <a id="ds-tx-exactness-netting-f04" name="ds-tx-exactness-netting-f04"></a><a id="ds-tx-exactness-toptx-f04" name="ds-tx-exactness-toptx-f04"></a><a id="ds-tx-accounting-toptx-f04" name="ds-tx-accounting-toptx-f04"></a><a id="ds-tx-accounting-net-change-toptx-f04" name="ds-tx-accounting-net-change-toptx-f04"></a>[F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L219) | A standalone TopTx creates only min-ADA outputs and must declare a positive release magnitude. | Reject a release overstated by one lovelace. |
| <a id="ds-tx-exactness-netting-f05" name="ds-tx-exactness-netting-f05"></a><a id="ds-tx-exactness-toptx-f05" name="ds-tx-exactness-toptx-f05"></a><a id="ds-tx-accounting-toptx-f05" name="ds-tx-accounting-toptx-f05"></a><a id="ds-tx-accounting-net-change-toptx-f05" name="ds-tx-accounting-net-change-toptx-f05"></a>[F05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L231) | The batch requires an allocation or a release, and the TopTx declares explicit zero. | Reject for either nonzero total. |
| <a id="ds-tx-exactness-netting-f06" name="ds-tx-exactness-netting-f06"></a><a id="ds-tx-exactness-toptx-f06" name="ds-tx-exactness-toptx-f06"></a><a id="ds-tx-accounting-toptx-f06" name="ds-tx-accounting-toptx-f06"></a><a id="ds-tx-accounting-net-change-toptx-f06" name="ds-tx-accounting-net-change-toptx-f06"></a>[F06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L247) | The batch total is zero, and the TopTx declares an allocation or a release. | Reject either nonzero declaration. |
| <a id="ds-tx-exactness-netting-f07" name="ds-tx-exactness-netting-f07"></a><a id="ds-tx-exactness-toptx-f07" name="ds-tx-exactness-toptx-f07"></a><a id="ds-tx-accounting-toptx-f07" name="ds-tx-accounting-toptx-f07"></a><a id="ds-tx-accounting-net-change-toptx-f07" name="ds-tx-accounting-net-change-toptx-f07"></a>[F07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L262) | The batch requires an allocation and the TopTx declares a release, or vice versa. | Reject either reversal of direction. |
| <a id="ds-tx-exactness-netting-n05" name="ds-tx-exactness-netting-n05"></a><a id="ds-tx-exactness-toptx-n06" name="ds-tx-exactness-toptx-n06"></a><a id="ds-tx-accounting-toptx-n06" name="ds-tx-accounting-toptx-n06"></a><a id="ds-tx-accounting-net-change-toptx-n06" name="ds-tx-accounting-net-change-toptx-n06"></a>[N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L281) | The parent's own release is exactly offset by child allocations. | Accept an explicit zero batch declaration. |
| <a id="ds-tx-exactness-netting-n06" name="ds-tx-exactness-netting-n06"></a><a id="ds-tx-exactness-toptx-n07" name="ds-tx-exactness-toptx-n07"></a><a id="ds-tx-accounting-toptx-n07" name="ds-tx-accounting-toptx-n07"></a><a id="ds-tx-accounting-net-change-toptx-n07" name="ds-tx-accounting-net-change-toptx-n07"></a>[N07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L291) | The parent's own allocation is exactly offset by child releases. | Accept an explicit zero batch declaration. |
| <a id="ds-tx-exactness-netting-n07" name="ds-tx-exactness-netting-n07"></a><a id="ds-tx-exactness-toptx-n08" name="ds-tx-exactness-toptx-n08"></a><a id="ds-tx-accounting-toptx-n08" name="ds-tx-accounting-toptx-n08"></a><a id="ds-tx-accounting-net-change-toptx-n08" name="ds-tx-accounting-net-change-toptx-n08"></a>[N08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L301) | A script fails as declared. The TopTx declares the exact batch change calculated from ordinary inputs and proposed ordinary outputs. | Accept the collateral outcome. |
| <a id="ds-tx-exactness-netting-f08" name="ds-tx-exactness-netting-f08"></a><a id="ds-tx-exactness-toptx-f08" name="ds-tx-exactness-toptx-f08"></a><a id="ds-tx-accounting-toptx-f08" name="ds-tx-accounting-toptx-f08"></a><a id="ds-tx-accounting-net-change-toptx-f08" name="ds-tx-accounting-net-change-toptx-f08"></a>[F08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L313) | A script fails as declared. The TopTx declares an inexact ordinary batch total. | Reject before collateral settlement. |
| <a id="ds-tx-exactness-netting-f09" name="ds-tx-exactness-netting-f09"></a><a id="ds-tx-exactness-toptx-f09" name="ds-tx-exactness-toptx-f09"></a><a id="ds-tx-accounting-toptx-f09" name="ds-tx-accounting-toptx-f09"></a><a id="ds-tx-accounting-net-change-toptx-f09" name="ds-tx-accounting-net-change-toptx-f09"></a>[F09](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L330) | A child delegates a nonzero change. The TopTx omits it from the batch total or counts it twice. | Reject both declarations. The total includes the child's originating change once. |
