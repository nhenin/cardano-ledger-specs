# Dijkstra DepositStore transaction rules

This specification defines the DepositStore business rules, their meaning and the
examples used to check them. Stable rule identifiers connect the business cases to
the corresponding executable specs.

Implementation status and test execution results are recorded separately in the
[verification record](dijkstra-deposit-store-verification.md).

## Table of contents

Section numbers organize the document; `DS-*` tags identify stable protocol rules.
The domain model defines the shared concepts, followed by rules grouped by domain,
remaining design questions, executable examples and code references.

- [1. Mathematical domain model](#1-mathematical-domain-model)
  - [1.1 UTxO capacity deposit terminology and state](#11-utxo-capacity-deposit-terminology-and-state)
  - [1.2 Validity predicates](#12-validity-predicates)
  - [1.3 Expected transitions and derived invariants](#13-expected-transitions-and-derived-invariants)
- [2. Transaction body scope](#2-transaction-body-scope)
- [3. Transaction declarations and accounting](#3-transaction-declarations-and-accounting)
  - [3.1 DS-TX-001 - A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change](#31-ds-tx-001---a-body-creating-or-spending-store-backed-outputs-must-declare-its-own-utxo-capacity-deposit-change)
    - [3.1.1 Acceptance cases](#311-acceptance-cases)
  - [3.2 DS-TX-002 - Batch net change and accounting responsibility](#32-ds-tx-002---batch-net-change-and-accounting-responsibility)
  - [3.3 DS-TX-003 - Exact UTxO capacity deposit accounting for each body](#33-ds-tx-003---exact-utxo-capacity-deposit-accounting-for-each-body)
  - [3.4 DS-TX-004 - Financial balance of TopTx](#34-ds-tx-004---financial-balance-of-toptx)
  - [3.5 DS-TX-005 - Net release when leaving store-backed outputs](#35-ds-tx-005---net-release-when-leaving-store-backed-outputs)
  - [3.6 DS-TX-006 - TopTx participation in net-release settlement](#36-ds-tx-006---toptx-participation-in-net-release-settlement)
  - [3.7 DS-TX-007 - Settlement output validation](#37-ds-tx-007---settlement-output-validation)
    - [3.7.1 Local release accounting refinement](#371-local-release-accounting-refinement)
  - [3.8 DS-TX-008 - Explicit zero contribution and positive SubTx amounts](#38-ds-tx-008---explicit-zero-contribution-and-positive-subtx-amounts)
  - [3.9 DS-TX-009 - A SubTx declaration requires a TopTx declaration](#39-ds-tx-009---a-subtx-declaration-requires-a-toptx-declaration)
    - [3.9.1 DS-TX-009-C01 - Declaration dependency](#391-ds-tx-009-c01---declaration-dependency)
      - [3.9.1.1 P01 - any SubTx has a declaration ⇒ TopTx has a declaration](#3911-p01---any-subtx-has-a-declaration--toptx-has-a-declaration)
    - [3.9.2 DS-TX-009-C02 - Absence and explicit zero](#392-ds-tx-009-c02---absence-and-explicit-zero)
      - [3.9.2.1 N01 - accepts absent declarations at both levels](#3921-n01---accepts-absent-declarations-at-both-levels)
      - [3.9.2.2 N02 - accepts explicit zero at both levels](#3922-n02---accepts-explicit-zero-at-both-levels)
      - [3.9.2.3 N03 - accepts TopTx zero without a SubTx declaration](#3923-n03---accepts-toptx-zero-without-a-subtx-declaration)
      - [3.9.2.4 F01 - rejects SubTx zero without a TopTx declaration](#3924-f01---rejects-subtx-zero-without-a-toptx-declaration)
    - [3.9.3 DS-TX-009-C03 - Equal allocations and releases](#393-ds-tx-009-c03---equal-allocations-and-releases)
      - [3.9.3.1 N01 - passes declaration presence with TopTx declaring the zero net amount](#3931-n01---passes-declaration-presence-with-toptx-declaring-the-zero-net-amount)
      - [3.9.3.2 F01 - rejects an absent TopTx declaration despite the zero net amount](#3932-f01---rejects-an-absent-toptx-declaration-despite-the-zero-net-amount)
    - [3.9.4 DS-TX-009-C04 - Local and delegated accounting](#394-ds-tx-009-c04---local-and-delegated-accounting)
      - [3.9.4.1 N01 - passes declaration presence with TopTx zero for every explicit SubTx form](#3941-n01---passes-declaration-presence-with-toptx-zero-for-every-explicit-subtx-form)
      - [3.9.4.2 F01 - rejects an absent TopTx declaration for every explicit SubTx form](#3942-f01---rejects-an-absent-toptx-declaration-for-every-explicit-subtx-form)
    - [3.9.5 DS-TX-009-C05 - Phase-2 failure](#395-ds-tx-009-c05---phase-2-failure)
      - [3.9.5.1 N01 - accepts zero declarations at both levels on the phase-2 failure path](#3951-n01---accepts-zero-declarations-at-both-levels-on-the-phase-2-failure-path)
      - [3.9.5.2 F01 - rejects SubTx zero without a TopTx declaration on the phase-2 failure path](#3952-f01---rejects-subtx-zero-without-a-toptx-declaration-on-the-phase-2-failure-path)
    - [3.9.6 DS-TX-009-C06 - Fixture integrity](#396-ds-tx-009-c06---fixture-integrity)
      - [3.9.6.1 P01 - preserves the number of SubTxs, including those with repeated declarations](#3961-p01---preserves-the-number-of-subtxs-including-those-with-repeated-declarations)
  - [3.10 DS-TX-010 - Validation of delegated SubTx contributions](#310-ds-tx-010---validation-of-delegated-subtx-contributions)
  - [3.11 DS-TX-011 - UTxO capacity deposit release authority follows the store-backed output](#311-ds-tx-011---utxo-capacity-deposit-release-authority-follows-the-store-backed-output)
  - [3.12 DS-TX-012 - Zero application ADA and empty application assets](#312-ds-tx-012---zero-application-ada-and-empty-application-assets)
- [4. Collateral](#4-collateral)
  - [4.1 DS-COLL-001 - Both output variants supported for collateral](#41-ds-coll-001---both-output-variants-supported-for-collateral)
  - [4.2 DS-COLL-002 - Collateral UTxO capacity deposit surplus and shortfall](#42-ds-coll-002---collateral-utxo-capacity-deposit-surplus-and-shortfall)
  - [4.3 DS-COLL-003 - Total collateral declaration](#43-ds-coll-003---total-collateral-declaration)
  - [4.4 DS-COLL-004 - Derived collateral DepositStore settlement](#44-ds-coll-004---derived-collateral-depositstore-settlement)
- [5. DepositStore state and pricing](#5-depositstore-state-and-pricing)
  - [5.1 DS-STORE-001 - DepositStore solvency](#51-ds-store-001---depositstore-solvency)
  - [5.2 DS-STORE-002 - Historical pricing for output UTxO capacity deposits](#52-ds-store-002---historical-pricing-for-output-utxo-capacity-deposits)
  - [5.3 DS-STORE-003 - UTxO capacity deposits calculated from output size](#53-ds-store-003---utxo-capacity-deposits-calculated-from-output-size)
  - [5.4 DS-STORE-004 - DepositStore initialization at the Conway transition](#54-ds-store-004---depositstore-initialization-at-the-conway-transition)
  - [5.5 DS-STORE-005 - Consistency of UTxO capacity deposit records](#55-ds-store-005---consistency-of-utxo-capacity-deposit-records)
- [6. Script compatibility](#6-script-compatibility)
  - [6.1 DS-PLUTUS-001 - Plutus compatibility](#61-ds-plutus-001---plutus-compatibility)
- [7. Stake and voting](#7-stake-and-voting)
  - [7.1 DS-STAKE-001 - Stake and voting power](#71-ds-stake-001---stake-and-voting-power)
- [8. Remaining design work](#8-remaining-design-work)
- [9. Executable domain specification](#9-executable-domain-specification)
  - [9.1 Domain scenarios](#91-domain-scenarios)
  - [9.2 Ledger adapter boundary](#92-ledger-adapter-boundary)
  - [9.3 DS-TX-009 - Declaration dependency examples](#93-ds-tx-009---declaration-dependency-examples)
  - [9.4 DS-TX-001 - Creation declaration examples](#94-ds-tx-001---creation-declaration-examples)
  - [9.5 Business rules and executable specs](#95-business-rules-and-executable-specs)
- [10. Code references](#10-code-references)

## 1. Mathematical domain model

This model separates definitions, validity predicates and state transitions. Unless
explicitly discussing collateral, it describes an ordinary successful batch under a
fixed pricing policy. Existing ledger requirements still apply: regular inputs exist in
the original UTxO, cannot be spent twice, and new output identifiers are fresh. Outputs
are indexed occurrences, so equal output values at different indices are counted
separately.

### 1.1 UTxO capacity deposit terminology and state

A **UTxO capacity deposit** is the ADA required for an output's storage capacity. For a
store-backed output, its allocated UTxO capacity deposit is recorded alongside the live UTxO
entry and held externally in the DepositStore. An implicit-deposit output retains the
legacy minimum-ADA mechanism inside its value.

Use these terms consistently:

| Term | Meaning |
| --- | --- |
| `requiredUTxODeposit(output)` | UTxO capacity deposit calculated for a new store-backed output. |
| `allocatedUTxODeposit(output)` | Exact UTxO capacity deposit recorded for an existing store-backed output. |
| Allocate | Assign a UTxO capacity deposit to a newly created store-backed output. |
| Release | Free an output's allocated UTxO capacity deposit when that output is consumed. |
| `allocatedUTxODeposits(body)` | Sum allocated to the body's new store-backed outputs. |
| `releasedUTxODeposits(body)` | Sum released by consuming the body's store-backed inputs. |
| `totalUTxODeposits(utxo)` | Sum allocated to all live store-backed outputs, which the DepositStore must cover. |
| `storeBalance` | Actual ADA balance of the DepositStore. |
| Settlement output | Output named to receive a settlement amount under the net-release rules. |

Allocation and release describe the lifecycle of individual UTxO capacity deposits. A release
can offset a new allocation in the same batch, without ADA leaving the DepositStore.
Declarations describe **net allocation**, **net release** or **no net change**, at the
body or batch scope defined below.

The API uses `UTxODeposit` for the domain term **UTxO capacity deposit**. Domain code
uses two qualified modules:

```haskell
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
```

`TopTx.TopTxUTxODepositDeclaration` and `SubTx.SubTxUTxODepositDeclaration` are distinct
newtypes. Their patterns express absence, explicit zero and nonzero declarations at
the appropriate body level:

| Domain term | API spelling |
| --- | --- |
| TopTx batch declaration | `TopTx.TopTxUTxODepositDeclaration` |
| No TopTx declaration | `TopTx.NoUTxODepositDeclaration` |
| TopTx net allocation | `TopTx.DeclaresNetUTxODepositAllocation amount` |
| TopTx net release and settlement | `TopTx.DeclaresNetUTxODepositRelease amount settlement` |
| TopTx explicit zero | `TopTx.DeclaresZeroNetUTxODeposit` |
| TopTx settlement participation | `NoTopTxSettlement` or `TopTxSettlementOutput index` |
| SubTx contribution declaration | `SubTx.SubTxUTxODepositDeclaration` |
| No SubTx declaration | `SubTx.NoUTxODepositDeclaration` |
| SubTx net allocation, accounted locally | `SubTx.DeclaresNetUTxODepositAllocation amount` |
| SubTx net allocation, funding delegated to TopTx | `SubTx.RequestsUTxODepositFromTopTx amount` |
| SubTx net release and settlement | `SubTx.DeclaresNetUTxODepositRelease amount target` |
| SubTx explicit zero | `SubTx.DeclaresZeroNetUTxODeposit` |
| SubTx settlement destination | `SubTxSettlementOutput index` or `DelegateToTopTx` |

Each newtype wraps an internal `StrictMaybe` representation at the codec boundary:
`NetUTxODepositChange` for TopTx and `SubTxNetUTxODepositChange` for SubTx. The legacy
payload constructors remain available at that boundary. For example, the two
`DeclaresZeroNetUTxODeposit` patterns carry `NoUTxODepositChange` and
`SubTxNoUTxODepositChange`, respectively. Domain examples use the qualified patterns
so that absence and explicit zero are clear without exposing the representation.

The wrappers preserve the same operations, accounting rules and wire representation.
The JSON body field remains `netUTxODepositChange`; operation kinds remain `allocate`,
`release`, `noChange` and, for SubTx funding requests, `requestUTxODepositFromTopTx`.
Settlement kinds remain `noTopTxSettlement`, `topTxSettlementOutput`,
`subTxSettlementOutput` and `delegateToTopTx`. Optional body CBOR key `28`, payload
tags and encoded bytes are unchanged. `StoreBackedTxOut` remains the output variant
name.

Let `utxo` contain live outputs and their allocated UTxO capacity deposit metadata:

```text
allocatedUTxODeposit(existingStoreBackedOutput) = its recorded UTxO capacity deposit

requiredUTxODeposit(newStoreBackedOutput) =
    coinsPerUTxOByte * (160 + acceptedSize(newStoreBackedOutput))

totalUTxODeposits(utxo) =
    sum(allocatedUTxODeposit(output) for each live store-backed output)
```

`acceptedSize` is the size of the accepted serialized output, not a later
reserialization. The UTxO capacity deposit metadata is outside that output.
`totalUTxODeposits` is an obligation, not a second pot of coins. Implicit outputs
contribute zero to this Store obligation; this does not remove their existing
minimum-ADA requirement.

For each body `b`, considering only its own regular inputs and outputs:

```text
releasedUTxODeposits(b) =
    sum(allocatedUTxODeposit(utxo[input]) for each store-backed input consumed by b)
allocatedUTxODeposits(b) =
    sum(requiredUTxODeposit(output) for each store-backed output created by b)
netUTxODepositChange(b) = allocatedUTxODeposits(b) - releasedUTxODeposits(b)

txTotalNetUTxODepositChange    = sum(netUTxODepositChange(b) for every TopTx and SubTx body b)
txTotalNetRelease = max(0, -txTotalNetUTxODepositChange)
```

Net quantities use signed integers. A positive declaration denotes a net allocation, a
negative declaration denotes a net release, and an explicit no-change declaration
denotes zero. An absent declaration has no declared value; it is not identified with an
explicit zero.

### 1.2 Validity predicates

Required declaration presence and agreement with the model are separate checks:

```text
createsStoreBackedOutput(b) ∨ spendsStoreBackedOutput(b) ⇒ hasDeclaration(b)
any SubTx has a declaration ⇒ TopTx has a declaration

for each declared SubTx s:
    declaredNetUTxODepositChange(s) = netUTxODepositChange(s)

when TopTx has a declaration:
    declaredNetUTxODepositChange(TopTx) = txTotalNetUTxODepositChange
```

The declaration requirement applies separately to each body's own created and spent
store-backed outputs, even when its net UTxO capacity deposit change is zero.
References and collateral do not trigger ordinary
Store activity. Declaration presence alone does not authorize a UTxO capacity deposit release
or establish exact funding.

Delegation assigns accounting responsibility without changing the net amount:

```text
subTxLocalNetUTxODepositChange(s) =
    netUTxODepositChange(s)     if accounted locally
    0                    if delegated to TopTx or no declaration is present

topTxNetUTxODepositChange    = txTotalNetUTxODepositChange - sum(subTxLocalNetUTxODepositChange(s) for SubTxs s)
topTxNetRelease = max(0, -topTxNetUTxODepositChange)
```

All presence and declaration checks above still apply. For the whole batch, require
value conservation with the Store transfer counted once:

```text
consumedValue(batch) + inject(max(0, -txTotalNetUTxODepositChange))
    = producedValue(batch) + inject(max(0, txTotalNetUTxODepositChange))
```

These consumed and produced values exclude the new Store transfers but retain all
ordinary ledger terms, including fees and certificate effects. `inject` adds only ADA;
the equality also conserves native assets. There is no additional financial balance
equality for individual SubTxs.

For every declared settlement output:

```text
0 ≤ index < length(ownOutputs)
coin(ownOutputs[index]) ≥ settlementAmount
```

`coin` reads the full output ADA for implicit outputs and application ADA for
store-backed outputs, excluding external UTxO capacity deposits. For a locally settled SubTx
net release, the settlement amount is its declared amount. For a TopTx target it is
`topTxNetRelease`. When `txTotalNetUTxODepositChange < 0`, require
`NoTopTxSettlement` exactly when `topTxNetRelease = 0`, and a valid TopTx target
otherwise. DS-TX-006 and DS-TX-007 give the routing details. This lower bound does not
prove an increase over an unspecified pre-release output amount.

### 1.3 Expected transitions and derived invariants

On ordinary success, remove regular inputs and insert regular outputs with their
allocated UTxO capacity deposits. The supplied output values already include their settlement
amounts:

```text
utxoAfter = (utxoBefore without regularInputs) union newRegularOutputsWithUTxODeposits
storeBalanceAfter = storeBalanceBefore + txTotalNetUTxODepositChange
```

From exact accounting and the definition of live UTxO capacity deposits, derive:

```text
totalUTxODepositsAfter = totalUTxODepositsBefore + txTotalNetUTxODepositChange
storeBalanceAfter - totalUTxODepositsAfter = storeBalanceBefore - totalUTxODepositsBefore
```

Every live allocated amount is nonnegative. Therefore a solvent initial state and a
valid transition preserve `storeBalanceAfter ≥ totalUTxODepositsAfter ≥ 0`.
Collateral is untouched on ordinary success. An accepted phase-2 failure uses the
separate collateral transition in DS-COLL-002 through DS-COLL-004; rejected batches
leave the accepted ledger state unchanged.

Tests must compare actual ledger decisions and observed state with independently
calculated model expectations. Evaluating both sides using only the same model
definitions would check an identity, not the ledger implementation. Acceptance
comparisons must use fixtures satisfying the other ledger rules, include valid cases,
and preserve the existing ability of SubTxs to fund TopTx fees.

## 2. Transaction body scope

DS-TX-001 applies separately to each top-level transaction body and each sub-transaction
body:

| Body | Operation field | Own outputs |
| --- | --- | --- |
| `DijkstraTxBodyRaw TopTx era` | `dtbrNetUTxODepositChange` | `dtbrOutputs` |
| `DijkstraTxBodyRaw SubTx era` | `dstbrNetUTxODepositChange` | `dstbrOutputs` |

The TopTx field has type `TopTx.TopTxUTxODepositDeclaration`; the SubTx field has type
`SubTx.SubTxUTxODepositDeclaration`. `TopTx.NoUTxODepositDeclaration` and
`SubTx.NoUTxODepositDeclaration` make no declaration and request no delegation. The
other patterns explicitly declare the operation carried by their body, including
explicit zero. The TopTx field declares the net change for the batch; SubTx fields
specify their contributions and where they are accounted for, as defined in DS-TX-002.

In body-generic tables, `NoUTxODepositDeclaration` means the qualified pattern for
that body's level. `hasDeclaration(body)` is false for that pattern and true for every
explicit declaration, including `DeclaresZeroNetUTxODeposit`.

For DS-TX-001, an output means the `TxOut` inside a `Sized` element of the body's own
output sequence. The cached size does not affect the check. A TopTx's own outputs do not
include its SubTx outputs. Spent outputs are obtained by resolving the body's own
spending inputs against the applicable UTxO. Reference inputs do not consume outputs or
release UTxO capacity deposits. Collateral inputs and collateral return have separate rules
under DS-COLL-001 and DS-COLL-002.

## 3. Transaction declarations and accounting

### 3.1 DS-TX-001 - A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change

**Rule identifier:** `DS-TX-001`

**Decision:** Agreed

A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change.

This requirement applies separately to TopTx and each SubTx. An explicit zero is a
declaration; an absent declaration is not. The declared amount must also satisfy the
separate exact-accounting rules, including TopTx's declaration of the batch total.

Define:

- `outputs(body)`: the body's own outputs, after removing the `Sized` wrapper.
- `spentOutputs(body)`: the outputs resolved from the body's own spending inputs.
- `change(body)`: the declaration field for that body's level, as listed above.
- `hasDeclaration(body)`: whether that field explicitly declares an operation,
  including explicit zero.
- `createsStoreBackedOutput(body)`: at least one element of `outputs(body)` has the
  `StoreBackedTxOut` constructor.
- `spendsStoreBackedOutput(body)`: at least one element of `spentOutputs(body)`
  has the `StoreBackedTxOut` constructor.

The required condition is:

```text
createsStoreBackedOutput(body) ∨ spendsStoreBackedOutput(body)
    ⇒ hasDeclaration(body)
```

Equivalently:

```text
NOT hasDeclaration(body)
    ⇒ every element of outputs(body) and spentOutputs(body)
        is an ImplicitDepositTxOut
```

If either condition is true and `hasDeclaration(body)` is false, reject the body.
DS-TX-005 additionally requires a release
contribution when store-backed outputs are spent without creating any new store-backed
outputs.

#### 3.1.1 Acceptance cases

These results concern **DS-TX-001 only**. Passing this check does not establish that the
transaction satisfies funding, release, or other ledger rules.

| Own spent outputs | Own created outputs | Own operation field | Result for DS-TX-001 |
| --- | --- | --- | --- |
| Only implicit-deposit outputs, or empty | Only implicit-deposit outputs, or empty | `NoUTxODepositDeclaration` | Pass |
| At least one store-backed output | Only implicit-deposit outputs, or empty | `NoUTxODepositDeclaration` | Reject |
| Any | At least one store-backed output | `NoUTxODepositDeclaration` | Reject |
| Any | Any | Explicit declaration, including zero | Pass |

The same cases apply to TopTx and SubTx. In particular:

- A TopTx declaration does not replace a missing SubTx declaration. If the SubTx
  creates or spends a store-backed output with `SubTx.NoUTxODepositDeclaration`, reject that SubTx even
  when the TopTx declares an operation.
- A SubTx declaration does not replace a missing TopTx declaration either. If
  the TopTx creates or spends a store-backed output with `TopTx.NoUTxODepositDeclaration`, reject the
  TopTx even when its SubTx bodies declare operations.
- A SubTx that requests funding through `SubTx.RequestsUTxODepositFromTopTx amount`
  has made an explicit declaration and passes this presence check. DS-TX-010
  separately validates that TopTx fulfils the request.
- A TopTx whose own spent and created outputs are all implicit-deposit outputs
  and whose field is `TopTx.NoUTxODepositDeclaration`, containing a SubTx with store-backed outputs
  and an explicit operation, passes this check for both bodies. This says nothing
  about overall validity: DS-TX-009 rejects the missing TopTx declaration.
- Creating store-backed outputs still requires a declaration when the net
  funding requirement is zero. TopTx expresses this with
  `TopTx.DeclaresZeroNetUTxODeposit`; SubTx uses `SubTx.DeclaresZeroNetUTxODeposit`
  under DS-TX-008.

### 3.2 DS-TX-002 - Batch net change and accounting responsibility

**Rule identifier:** `DS-TX-002`

**Decision:** Agreed

The TopTx DepositStore operation declares the net change for the entire batch: total
UTxO capacity deposits allocated minus total UTxO capacity deposits released, including the
contributions of its SubTx bodies. It is not an additional operation to add on top of
those contributions. The declared net change must match the batch's exact change in
UTxO capacity deposit obligations under DS-TX-003 and be funded under DS-TX-004.

Delegation changes where a SubTx contribution is accounted for:

- `SubTx.DeclaresZeroNetUTxODeposit`: explicitly declare zero contribution and no
  delegation request.
- `SubTx.DeclaresNetUTxODepositAllocation amount`: account for the net allocation in the SubTx.
- `SubTx.RequestsUTxODepositFromTopTx amount`: account for the net allocation in the TopTx.
- `SubTx.DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput index)`: account for the net release
  in the SubTx and settle it in its named output.
- `SubTx.DeclaresNetUTxODepositRelease amount DelegateToTopTx`: account for the net release
  in the TopTx; its settlement must satisfy DS-TX-006 and DS-TX-007.

Every contribution is included in the batch total regardless of delegation. Changing its
accounting location must not count the contribution again, remove its UTxO capacity deposit
obligation, or change the amount declared by the SubTx. A body can have its operation
accounted for locally without requiring its own inputs to fund that operation
independently. A SubTx may remain financially imbalanced; TopTx must balance the
complete batch, including its SubTx contributions.

Define `batchNetAllocations` and `batchNetReleases` as the nonnegative totals of the
batch's net allocation and net release contributions, each counted once regardless of
delegation. Then:

```text
txTotalNetUTxODepositChange = batchNetAllocations - batchNetReleases

topTxNetUTxODepositChange + sum(subTxLocalNetUTxODepositChanges) = txTotalNetUTxODepositChange
```

`txTotalNetUTxODepositChange` is the signed net change declared by TopTx for the
entire transaction, including every SubTx. `topTxNetUTxODepositChange` is the
portion handled by TopTx, including delegated operations.
`subTxLocalNetUTxODepositChanges` contains only contributions handled locally by
SubTx bodies; DS-TX-006 gives the calculation. These are signed accounting quantities:
net allocations are positive and net releases negative. This notation does not require
negative `Coin` amounts in the transaction interface or additional declared amount
fields.

The TopTx's accounting allocation can have a different sign from its declared batch net
change. For example, a local SubTx net allocation of 5 ADA and a net release of 3 ADA
delegated to TopTx attribute `+5` to SubTx and `-3` to TopTx, while TopTx declares the
batch's `TopTx.DeclaresNetUTxODepositAllocation 2`.

DS-TX-001 and DS-TX-009 determine when TopTx must declare a change. When present, its
declaration must represent the total as follows:

| Batch net change | TopTx declaration |
| --- | --- |
| Positive | `TopTx.DeclaresNetUTxODepositAllocation positiveAmount` |
| Negative | `TopTx.DeclaresNetUTxODepositRelease positiveAmount settlement` |
| Zero | `TopTx.DeclaresZeroNetUTxODeposit` |

`positiveAmount` is the absolute value of the net change, represented by `PositiveCoin`.
This abstract type permits only 1 through 18446744073709551615 lovelace, matching the
positive part of the CBOR `Coin` range. Its checked constructor and CBOR/JSON decoders
reject zero, negative and out-of-range amounts.

`TopTx.DeclaresZeroNetUTxODeposit` encodes as CBOR `[2]` and JSON `{"kind":"noChange"}`.
Existing net-allocation and net-release tags remain `0` and `1`, respectively.
`TopTx.DeclaresNetUTxODepositAllocation 0` and `TopTx.DeclaresNetUTxODepositRelease 0
settlement` are no longer valid forms. An absent field
(`TopTx.NoUTxODepositDeclaration`) remains distinct from an explicit zero declaration;
it fails DS-TX-001 when TopTx creates or spends store-backed outputs. The interface
expresses this distinction; the ledger must still enforce the DS-TX-001 spending
requirement and reconcile the net amount with the batch's contributions.

For example, a batch allocating 5 ADA and releasing 3 ADA declares
`TopTx.DeclaresNetUTxODepositAllocation 2`. On successful settlement, the store balance
increases by 2 ADA. Reversing those amounts requires
`TopTx.DeclaresNetUTxODepositRelease 2 settlement` and decreases the store balance by 2
ADA. The settlement choice describes TopTx's participation as defined in DS-TX-006.
These examples use ADA for readability; code amounts are in lovelace.

Netting determines the store's balance change. It does not remove the obligation to
validate individual declarations, fulfil delegation requests, or authorize net-release
contributions. A net release delegated to TopTx can offset net allocations without a
separate payment from the Store. In the 5 ADA allocation and 3 ADA delegated net-release
example, TopTx funds a net allocation of 2 ADA; there is no separate 3 ADA payment from
the Store. No additional TopTx settlement output is needed in this case. The TopTx
output index applies when the net operation is `TopTx.DeclaresNetUTxODepositRelease`.
With equal net allocations and net releases, TopTx declares
`TopTx.DeclaresZeroNetUTxODeposit` and the net store transfer is zero.

For a batch containing net allocations only, the accounting amounts must reconcile as:

```text
topTxNetUTxODepositChange + sum(subTxLocalNetUTxODepositChanges) = txTotalNetUTxODepositChange
```

`topTxNetUTxODepositChange` includes net allocations delegated to TopTx and its own
contribution. It does not include net allocations already accounted for in SubTx. All
terms in this net-allocation-only equation are nonnegative. The equation describes
accounting allocation; it is not sufficient on its own to validate UTxO capacity deposits or
delegation requests.

The TopTx can also create its own store-backed outputs and fund their UTxO capacity deposits.
For a batch containing net allocations only, the total can therefore be expressed as:

```text
txTotalNetUTxODepositChange
    = ownTopTxNetAllocation + sum(localSubTxNetAllocations) + sum(delegatedSubTxNetAllocations)

topTxNetUTxODepositChange
    = ownTopTxNetAllocation + sum(delegatedSubTxNetAllocations)
```

`ownTopTxNetAllocation` is the contribution attributable to TopTx's own activity; it is
not a separate field in the current interface. Its required amount is subject to the
UTxO capacity deposit allocation and release policy. It need not be zero.

For example, one SubTx contributes 3 ADA and TopTx's own store-backed outputs require an
additional contribution of 2 ADA. There are no releases:

| SubTx declaration | TopTx declaration | Accounted in SubTx | Accounted in TopTx | Net allocation funded in the Store |
| --- | --- | --- | --- | --- |
| `SubTx.DeclaresNetUTxODepositAllocation 3` | `TopTx.DeclaresNetUTxODepositAllocation 5` | 3 | 2 | 5 |
| `SubTx.RequestsUTxODepositFromTopTx 3` | `TopTx.DeclaresNetUTxODepositAllocation 5` | 0 | 5 | 5 |

These examples use ADA amounts for readability. `Coin` amounts in the code are
denominated in lovelace. The store receives 5 ADA in either case. If TopTx's own
contribution were zero, the total would instead be 3 ADA in both cases. These credits
assume successful settlement of the batch. The same once-only accounting requirement
applies to releases.

DS-TX-006 distinguishes TopTx settlement participation while allowing mixed TopTx and
SubTx destinations. DS-TX-007 validates the selected output and its coin amount, using
the derived TopTx amount defined in DS-TX-006.

### 3.3 DS-TX-003 - Exact UTxO capacity deposit accounting for each body

**Rule identifier:** `DS-TX-003`

**Decision:** Agreed

Each TopTx and SubTx body must account exactly for its own change in UTxO capacity deposit
obligations. Reject both an excessive and an insufficient contribution, even when
another body's opposite error makes the batch total correct. This UTxO capacity deposit
accounting condition is separate from financial conservation: SubTx may be financially
imbalanced, but the completed TopTx batch must balance.

For each body, define:

- `releasedUTxODeposits(body)`: sum of allocated UTxO capacity deposits released by
  consuming that body's store-backed inputs under the agreed pricing and release
  policy. This is not the Store's global available balance.
- `allocatedUTxODeposits(body)`: UTxO capacity deposits required for that body's own newly created
  store-backed outputs.
- `declaredNetContribution(body)`: the signed contribution attributable to that
  body, with net allocations positive and net releases negative.

Require:

```text
releasedUTxODeposits(body) + declaredNetContribution(body)
    = allocatedUTxODeposits(body)
```

Equivalently, separating positive net allocations and net releases:

```text
releasedUTxODeposits(body) + declaredNetAllocation(body)
    = allocatedUTxODeposits(body) + declaredNetRelease(body)
```

Thus `declaredNetContribution(body)` must equal `allocatedUTxODeposits(body) -
releasedUTxODeposits(body)`. Positive differences require an exact net allocation,
negative differences require an exact net release, and zero requires a zero
contribution, subject to the declaration-presence rules.

For example, when a body releases no UTxO capacity deposits and creates outputs requiring 2
ADA, declaring a net allocation of 3 ADA is an accounting error. A net allocation of 1
ADA also fails; the correct contribution is exactly 2 ADA. The remaining transaction
funds may be placed in regular outputs under the financial balance rules.

For SubTx, use the declared contribution regardless of accounting delegation:

| SubTx declaration | Contribution for that SubTx's UTxO capacity deposit accounting |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | `0`; the exact UTxO capacity deposit accounting and release rules still apply |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | `+amount` |
| `SubTx.RequestsUTxODepositFromTopTx amount` | `+amount` |
| `SubTx.DeclaresNetUTxODepositRelease amount target` | `-amount`, for either target |
| `SubTx.NoUTxODepositDeclaration` | `0`; DS-TX-001 rejects absence if the body creates or spends any store-backed output |

For TopTx's own UTxO capacity deposit accounting, remove all SubTx contributions from the
declared batch net change, including contributions delegated to TopTx:

```text
declaredNetContribution(TopTx)
    = txTotalNetUTxODepositChange
        - sum(declaredNetContribution(subTx))
```

This is the contribution attributable to TopTx's own activity, not the financial amount
accounted for in TopTx, which also includes delegated contributions. Each declared
contribution is counted at its full amount. An allocation-funding request counts toward
the originating SubTx's declared UTxO capacity deposit contribution, but acceptance also
requires its funding to be fulfilled in the batch accounting. Passing this equality
alone does not establish financial balance or a valid settlement output. Summing the
exact body contributions gives the batch requirement:

```text
txTotalNetUTxODepositChange = sum(allocatedUTxODeposits(body) - releasedUTxODeposits(body))
```

The sum includes TopTx's own activity and every SubTx body exactly once, regardless of
delegation.

For example, SubTx A releases no UTxO capacity deposits, creates outputs requiring 3 ADA and
declares a net allocation of 5 ADA. SubTx B also releases none and creates outputs
requiring 3 ADA, but declares only 1 ADA. Both fail this exact accounting check. The
batch must be rejected even though the combined net allocation of 6 ADA equals the
combined requirement. Each SubTx must explicitly declare exactly 3 ADA, locally or
through a request to TopTx.

DS-STORE-003 defines the pricing formula and allocated UTxO capacity deposits for the current
scope. Voluntary excess net allocations through these operations are not permitted. The
current scope assumes a constant `coinsPerUTxOByte`; DS-STORE-002 records the deferred
requirement to retain historical pricing. Collateral effects follow DS-COLL-001 through
DS-COLL-004.

### 3.4 DS-TX-004 - Financial balance of TopTx

**Rule identifier:** `DS-TX-004`

**Decision:** Agreed

TopTx must balance the complete batch. SubTx may be individually imbalanced; their
contributions must be included in the final conservation check.

Expressing the existing consumed and produced values before adding the new DepositStore
term, require:

```text
txTotalNetRelease = max(0, -txTotalNetUTxODepositChange)

consumedValue(batch) + inject(txTotalNetRelease)
    = producedValue(batch) + inject(max(0, txTotalNetUTxODepositChange))
```

`txTotalNetUTxODepositChange` is positive for `TopTx.DeclaresNetUTxODepositAllocation`,
negative for `TopTx.DeclaresNetUTxODepositRelease`, and zero for
`TopTx.DeclaresZeroNetUTxODeposit`. `txTotalNetRelease` is the amount in TopTx's
`TopTx.DeclaresNetUTxODepositRelease`, or zero otherwise. Absence of a declaration is
subject to the separate presence and reconciliation rules.

Consumed and produced values include the complete batch's inputs, outputs and other
existing ledger terms, including fees and existing deposit/refund rules. The net store
amount is counted once, using TopTx's declaration; SubTx store contributions are not
added again. This equality preserves all assets, whereas DS-TX-003 concerns exact ADA
UTxO capacity deposit accounting for each body.

### 3.5 DS-TX-005 - Net release when leaving store-backed outputs

**Rule identifier:** `DS-TX-005`

**Decision:** Agreed

When a body spends store-backed outputs and creates no new store-backed outputs, it must
explicitly account for a net release equal to the released UTxO capacity deposits. Omitting
the declaration or allocating a zero contribution to that body does not satisfy this
rule. Released UTxO capacity deposits must not silently remain in the store in this case.

```text
spendsStoreBackedOutput(body) AND NOT hasStoreBackedOutput(body)
    ⇒ declaredNetContribution(body) = -releasedUTxODeposits(body)
```

The released amount is the sum of UTxO capacity deposits allocated to the consumed
store-backed outputs under DS-STORE-003. This rule does not grant access to unrelated
store surplus. It applies to bodies creating only implicit-deposit outputs, as well as
bodies creating no outputs; a release's target must still satisfy the settlement rules.

For SubTx, the net-release contribution is declared with
`SubTx.DeclaresNetUTxODepositRelease amount target`, including explicit delegation when
TopTx accounts for it. For TopTx's own activity, the contribution is derived as in
DS-TX-003. The TopTx field continues to declare the entire batch's net change, so it may
declare a net allocation or explicit zero when other contributions offset the release.
This does not erase the body's net-release contribution.

For example, a SubTx releasing 3 ADA of UTxO capacity deposits and creating only
implicit-deposit outputs declares a net release of 3 ADA. If another SubTx contributes a
5 ADA net allocation and TopTx has no own contribution, TopTx declares
`TopTx.DeclaresNetUTxODepositAllocation 2`. The store receives 2 ADA net; no separate
payment for the gross release is required.

### 3.6 DS-TX-006 - TopTx participation in net-release settlement

**Rule identifier:** `DS-TX-006`

**Decision:** Agreed

A net release declares the batch amount and, separately, whether TopTx receives a share:

```haskell
TopTx.DeclaresNetUTxODepositRelease amount settlement
```

Here `amount` has type `PositiveCoin`, and the settlement choices remain:

```haskell
data TopTxReleaseSettlement
  = NoTopTxSettlement
  | TopTxSettlementOutput !TxIx
```

`NoTopTxSettlement` means that no settlement amount remains to be paid in TopTx's
outputs after reconciling the contributions. Destinations are already declared by the
corresponding `SubTx.DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput index)`
operations. This does not mean zero batch net release: the amount is positive. It must
not leave an outstanding TopTx settlement requirement unfulfilled.

`TopTxSettlementOutput index` names a zero-based index into TopTx's own outputs. It
permits both TopTx-only settlement and mixed settlement in TopTx and SubTx outputs. The
selected TopTx output already includes TopTx's share. That share is determined from the
accounting; it is not automatically the entire amount in
`TopTx.DeclaresNetUTxODepositRelease`.

The operation's amount always remains the entire batch's net release under DS-TX-002. It
is not an additional payment or a second credit to SubTx outputs. Offsetting net
allocations participate in the net calculation, so the declared amount need not equal
the gross sum of local SubTx releases.

Derive the TopTx amounts from the signed total and the SubTx declarations:

```text
txTotalNetRelease = max(0, -txTotalNetUTxODepositChange)

topTxNetUTxODepositChange = txTotalNetUTxODepositChange - sum(subTxLocalNetUTxODepositChanges)
topTxNetRelease = max(0, -topTxNetUTxODepositChange)
```

Each SubTx contributes the following signed amount to
`subTxLocalNetUTxODepositChanges`:

| SubTx declaration | Local net UTxO capacity deposit change |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | `0`; no delegation |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | `+amount` |
| `SubTx.DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput index)` | `-amount` |
| `SubTx.RequestsUTxODepositFromTopTx amount` | `0`; TopTx handles the net allocation |
| `SubTx.DeclaresNetUTxODepositRelease amount DelegateToTopTx` | `0`; TopTx handles the net release |
| `SubTx.NoUTxODepositDeclaration` | `0`; declaration requirements still apply |

Delegated contributions are already included in `txTotalNetUTxODepositChange`. Do
not subtract them as local contributions: they remain TopTx's responsibility. These
amounts are derived; no additional TopTx amount field is required. Unlike TopTx's own
UTxO capacity deposit contribution in DS-TX-003, `topTxNetUTxODepositChange` includes
delegated operations.

For a net-release transaction (`txTotalNetUTxODepositChange < 0`), require:

| Derived TopTx amount | Required settlement |
| --- | --- |
| `topTxNetRelease == 0` | `NoTopTxSettlement` |
| `topTxNetRelease > 0` | `TopTxSettlementOutput index`, with the selected output containing at least `topTxNetRelease` |

`txTotalNetRelease` is the net ADA amount transferred from the Store for the entire
transaction. `topTxNetRelease` is the amount to settle in TopTx's selected output. Net
allocations funded locally by SubTx bodies can make the latter larger than the former.
For example, a local SubTx net allocation of 3 ADA and TopTx's own release contribution
of 5 ADA give:

```text
txTotalNetUTxODepositChange = -2
txTotalNetRelease = 2
topTxNetUTxODepositChange = -2 - 3 = -5
topTxNetRelease = 5
```

TopTx declares `TopTx.DeclaresNetUTxODepositRelease 2 (TopTxSettlementOutput index)`.
The selected output contains at least 5 ADA: 3 ADA supplied by the SubTx and 2 ADA from
the store. These funds are included in the batch conservation check once. Conversely, a
local SubTx net release of 5 ADA and a TopTx net allocation contribution of 3 ADA give
`topTxNetUTxODepositChange = 3` and `topTxNetRelease = 0`; the declaration is
`TopTx.DeclaresNetUTxODepositRelease 2 NoTopTxSettlement`.

This settlement requirement applies to the `TopTx.DeclaresNetUTxODepositRelease` branch.
A net allocation or explicit zero still follows DS-TX-002 and does not introduce a TopTx
settlement output merely because its derived accounting portion is negative.

For example, with no offsetting net allocations:

| Local SubTx net releases | TopTx share | TopTx declaration |
| --- | --- | --- |
| 3 ADA | 0 | `TopTx.DeclaresNetUTxODepositRelease 3 NoTopTxSettlement` |
| 0 | 2 ADA | `TopTx.DeclaresNetUTxODepositRelease 2 (TopTxSettlementOutput index)` |
| 3 ADA | 2 ADA | `TopTx.DeclaresNetUTxODepositRelease 5 (TopTxSettlementOutput index)` |

These amounts are in ADA for readability. Each SubTx retains its own declared amount and
destination. In the mixed example, 5 ADA leaves the store in total: 3 ADA is settled in
SubTx outputs and 2 ADA in the selected TopTx output.

CBOR encodes the settlement as `[0]` for `NoTopTxSettlement` or `[1, index]` for
`TopTxSettlementOutput index`. A release is now `[1, amount, settlement]`, replacing the
previous prototype's bare index. JSON uses a `settlement` object with kind
`noTopTxSettlement`, or kind `topTxSettlementOutput` and an `outputIndex` field. The interface
expresses these cases. DS-TX-007 specifies output validation; implementing the
calculation and ledger enforcement remains pending.

### 3.7 DS-TX-007 - Settlement output validation

**Rule identifier:** `DS-TX-007`

**Decision:** Destination checks and existing SubTx imbalance preserved; stronger settlement semantics open

Each declared settlement output must exist in the body that owns the index. Its coin
value must be at least the settlement amount specified or derived for that output. The
output may also contain other funds.

```text
0 ≤ index < length(outputs(body))
coin(outputs(body)[index]) ≥ settlementAmount(body, index)
```

For `SubTx.DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput index)`, resolve
the index in that SubTx's own output sequence and use `amount` as its settlement amount.
For `TopTxSettlementOutput index`, resolve the index in TopTx's own output sequence and
use `topTxNetRelease` derived in DS-TX-006, not automatically the batch's entire net
release amount. Neither index refers to an input, another body's outputs, or collateral
return.

The selected output already includes the settlement amount. Applying the transaction
must not add the amount to the output a second time. This check does not replace
financial conservation, exact UTxO capacity deposit accounting or release authorization under
DS-TX-011. `NoTopTxSettlement` has no TopTx index to validate; DS-TX-006 still requires
no outstanding TopTx settlement share.

For example, with a batch net release of 5 ADA split as 3 ADA in a SubTx and 2 ADA in
TopTx, the selected TopTx output must contain at least 2 ADA. An output containing 2 ADA
or 4 ADA passes this amount check; an output containing 1 ADA or a missing output fails.
The selected SubTx output must contain at least its own declared 3 ADA.

#### 3.7.1 Local release accounting refinement

The agreed example is a SubTx consuming 10 ADA of application assets and releasing 2 ADA
of UTxO capacity deposits, with a local release targeting its only output, an implicit
output. With no other ADA sources, charges or transfers, that output must contain 12
ADA. An output containing 10 ADA must fail. The existing destination bound alone accepts
10 ADA, and exact UTxO capacity deposit accounting plus batch conservation does not prevent
the other 2 ADA from funding another body's outputs or TopTx fees.

SubTx ADA surplus must remain available to fund TopTx fees or other bodies, including
when the SubTx settles a net Store release locally. Choosing
`SubTx.DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput index)` must not
impose independent SubTx balance or prohibit net ADA exports. The proposed no-export
inequality `ordinaryProducedADA ≥ ordinaryConsumedADA + amount` is therefore not
adopted.

For a local release, the accounting identity can be expressed as:

```text
netADAExport = ordinaryConsumedADA + amount - ordinaryProducedADA
```

Positive values contribute ADA to the rest of the batch; negative values receive
funding. This is a derived accounting quantity, not a new field or an additional balance
constraint. For example, 10 application ADA plus a 2 ADA release can fund an output of
10 ADA and contribute 2 ADA to TopTx fees. With no such export or other ADA terms, the
output must contain 12 ADA.

Both ordinary amounts exclude DepositStore transfers. Consumed ADA includes the body's
regular input coins, account withdrawals and applicable refunds. Produced ADA includes
its regular output coins, certificate and proposal deposits, treasury donations and
direct account deposits. Certificate effects must be attributed using their actual batch
processing order. TopTx fees are not a SubTx charge in this calculation.

The open question is what additional settlement guarantee is required beyond exact
UTxO capacity deposit changes, the destination bound and batch conservation. Existing fields
do not specify an output's amount before release or an independent export allowance.
Deriving the export from final outputs cannot distinguish an intended fee contribution
from a release redirected elsewhere in the batch. No additional signed allocation
information or restriction is agreed here.

### 3.8 DS-TX-008 - Explicit zero contribution and positive SubTx amounts

**Rule identifier:** `DS-TX-008`

**Decision:** Agreed

SubTx declares zero contribution with its own explicit declaration pattern. All net allocations,
net releases and allocation-funding requests carry a strictly positive amount, including
releases delegated to TopTx:

| Explicit SubTx declaration | Amount and settlement |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | Zero, with no settlement target |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | `PositiveCoin`, accounted locally |
| `SubTx.RequestsUTxODepositFromTopTx amount` | `PositiveCoin`, funding delegated to TopTx |
| `SubTx.DeclaresNetUTxODepositRelease amount target` | `PositiveCoin` and a `SubTxReleaseTarget` |

`SubTx.DeclaresZeroNetUTxODeposit` contributes zero to both the SubTx's UTxO capacity
deposit contribution and its local accounting amount. It requests no delegation and has
no settlement output. It is distinct from `SubTx.NoUTxODepositDeclaration`: the latter
makes no declaration and fails DS-TX-001 when the SubTx creates or spends a store-backed
output.

For example, a SubTx spending and creating store-backed outputs with equal UTxO capacity
deposit obligations can explicitly declare zero, provided all other rules hold. This
does not bypass DS-TX-003 exact accounting or DS-TX-005 release when leaving
store-backed outputs. If either rule requires a nonzero contribution, an explicit zero
does not satisfy it.

`PositiveCoin` permits 1 through 18446744073709551615 lovelace, as for TopTx. Checked
construction and CBOR/JSON decoding reject zero, negative and out-of-range operation
amounts. In particular, zero cannot encode a net allocation, an allocation-funding
request or a net release.

The explicit zero encodes as CBOR `[3]` and JSON `{"kind":"noChange"}`. Existing SubTx
tags remain `0` for a net allocation, `1` for a net release and `2` for a funding
request. Previously accepted zero-amount operation encodings now fail decoding; an
explicit zero must use the explicit-zero form.

### 3.9 DS-TX-009 - A SubTx declaration requires a TopTx declaration

**Rule identifier:** `DS-TX-009`

**Decision:** Agreed

**Executable spec:** [DeclarationDependencySpec.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs)

Categories, case titles and order match the executable spec. Each linked test ID
completes its category tag: `N` for nominal cases, `F` for failures, and `P` for the
universal rule and fixture check. Numbering restarts in each category.

**Reading the outcomes:** $\mathsf{PassesDS009}$ and $\mathsf{FailsDS009}$ concern only
declaration presence. $\mathsf{Accepted}$ and $\mathsf{Rejected}$ describe submission
of the prepared transaction to the ledger. Exact amounts and Store accounting are
covered by DS-TX-002 and DS-TX-003.

#### 3.9.1 DS-TX-009-C01 - Declaration dependency

Any explicit SubTx declaration requires a TopTx declaration, including zero and
delegated operations. TopTx need not have Store activity of its own for this rule to apply.

$\mathrm{hasDeclaration}(\mathit{body})$ means that the body explicitly declares
a UTxO capacity deposit change; $\mathrm{subTransactions}(\mathit{topTx})$ is its
sequence of SubTxs.

$$
\begin{aligned}
&\left(\exists\,\mathit{subTx}\in\mathrm{subTransactions}(\mathit{topTx}):
\mathrm{hasDeclaration}(\mathit{subTx})\right) \\
&\qquad\implies\mathrm{hasDeclaration}(\mathit{topTx})
\end{aligned}
$$

If every SubTx omits its declaration, DS-TX-009 imposes no requirement on TopTx.
DS-TX-001 may still require a declaration for TopTx's own Store activity.

##### 3.9.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L61) - any SubTx has a declaration ⇒ TopTx has a declaration

Let $\mathrm{rejectsDS009}(\mathit{topTx})$ mean that the isolated validator
reports `MissingTopTxDeclaration`.

$$
\begin{aligned}
\mathrm{rejectsDS009}(\mathit{topTx})
\iff\bigl(&\neg\mathrm{hasDeclaration}(\mathit{topTx}) \\
&\land\exists\,\mathit{subTx}\in\mathrm{subTransactions}(\mathit{topTx}): \\
&\qquad\mathrm{hasDeclaration}(\mathit{subTx})\bigr)
\end{aligned}
$$

**Why:** A declaration is missing exactly when a SubTx requires one and TopTx provides
none. The equivalence checks both rejection of forbidden combinations and success for
combinations the rule permits.

**Coverage:** The property compares the validator's complete result with an independently
expressed rule. Generated cases include every declaration form, empty SubTx sequences,
an absent declaration, and an explicit declaration at each position among four SubTxs.
Random combinations also exercise several declaring SubTxs together.

#### 3.9.2 DS-TX-009-C02 - Absence and explicit zero

**Situation:** TopTx and its single SubTx consume and create only implicit-deposit
outputs. There is no Store allocation or release. Each case submits a funded,
phase-2-valid transaction whose other ledger requirements are satisfied.

| TopTx declaration ↓ / SubTx declaration → | Absent | Explicit zero |
| --- | --- | --- |
| **Absent** | ✓ Accepted · N01 | ✗ Rejected · F01 |
| **Explicit zero** | ✓ Accepted · N03 | ✓ Accepted · N02 |

$\mathsf{Absent}$ means no declaration; $\mathsf{ExplicitZero}$ acknowledges a zero net
change. The latter still triggers the dependency:

$$
\mathrm{declaresZero}(\mathit{body})
\implies\mathrm{hasDeclaration}(\mathit{body})
$$

##### 3.9.2.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L66) - accepts absent declarations at both levels

$$
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\}
\implies \mathsf{Accepted}
$$

**Why:** With no Store activity and no SubTx declaration, neither body needs to declare.

##### 3.9.2.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L70) - accepts explicit zero at both levels

$$
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\}
\implies \mathsf{Accepted}
$$

**Why:** The SubTx explicitly declares zero, and TopTx supplies the declaration it requires.

##### 3.9.2.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L74) - accepts TopTx zero without a SubTx declaration

$$
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero} \\
\mathit{subTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\}
\implies \mathsf{Accepted}
$$

**Why:** TopTx may declare independently; its declaration creates no obligation for the SubTx.

##### 3.9.2.4 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L78) - rejects SubTx zero without a TopTx declaration

$$
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\}
\implies \mathsf{Rejected}
$$

**Why:** Explicit zero is still a declaration, so the SubTx requires TopTx to declare.

**Expected failure:** `MissingTopTxUTxODepositDeclaration`.

**State invariant:**

$$
\mathit{ledgerStateAfterRejectedSubmit}=\mathit{ledgerStateBeforeSubmit}
$$

The comparison starts immediately before submission, after funding and preparation.

#### 3.9.3 DS-TX-009-C03 - Equal allocations and releases

**Situation:** Two SubTxs declare local operations using the same generated strictly
positive amount: one allocates it, the other releases it to output index zero. Their
declared contributions cancel; TopTx has no contribution of its own.

$$
\begin{aligned}
&\sum_{\mathit{subTx}\in\mathrm{subTransactions}(\mathit{topTx})}
\mathrm{declaredNetContribution}(\mathit{subTx}) \\
&\qquad=\mathit{declaredAmount}-\mathit{declaredAmount}=0
\end{aligned}
$$

These properties validate declarations directly. They do not fund operations, construct
a settlement output or exercise a Store transfer. In the formulas below,
$\mathit{declaredAmount}\in\mathsf{PositiveCoin}$.

##### 3.9.3.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L84) - passes declaration presence with TopTx declaring the zero net amount

$$
\begin{gathered}
\forall\,\mathit{declaredAmount}\in\mathsf{PositiveCoin}: \\
\left.
\begin{aligned}
\mathit{declaredAllocation} &= \mathit{declaredAmount} \\
\mathit{declaredRelease} &= \mathit{declaredAmount} \\
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\}
\implies\mathsf{PassesDS009}
\end{gathered}
$$

**Why:** A zero net amount can be acknowledged explicitly. TopTx's zero declaration fulfils the
presence requirement for the two declaring SubTxs.

##### 3.9.3.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L87) - rejects an absent TopTx declaration despite the zero net amount

$$
\begin{gathered}
\forall\,\mathit{declaredAmount}\in\mathsf{PositiveCoin}: \\
\left.
\begin{aligned}
\mathit{declaredAllocation} &= \mathit{declaredAmount} \\
\mathit{declaredRelease} &= \mathit{declaredAmount} \\
\mathit{topTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\}
\implies\mathsf{FailsDS009}
\end{gathered}
$$

**Why:** The amounts cancel, but the two declarations still exist. Their zero sum cannot
replace TopTx's explicit declaration.

**Expected failure:** `MissingTopTxDeclaration` from the isolated validator.

#### 3.9.4 DS-TX-009-C04 - Local and delegated accounting

**Situation:** Each generated sample provides all five explicit SubTx declaration
forms, using a strictly positive amount and a settlement output index where needed.
Call this collection $\mathit{explicitSubTxDeclarations}$:

| Declaration form | Accounting responsibility |
| --- | --- |
| Explicit zero | No amount to allocate or release |
| Local allocation | SubTx accounts for the allocation |
| Allocation requested from TopTx | TopTx accounts for the requested allocation |
| Local release | SubTx settles the release at its declared output index |
| Release delegated to TopTx | TopTx accounts for the release |

Each form is checked **separately**, in a transaction body with one SubTx. TopTx's zero
is a presence control even for nonzero operations; it does not assert that the declared
total is financially correct. Amount and settlement validation belong to other rules.

##### 3.9.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L92) - passes declaration presence with TopTx zero for every explicit SubTx form

$$
\begin{gathered}
\forall\,\mathit{subTxDeclaration}\in\mathit{explicitSubTxDeclarations}: \\
\left.
\begin{aligned}
\mathit{subTxDeclarations} &= [\mathit{subTxDeclaration}] \\
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\}
\implies\mathsf{PassesDS009}
\end{gathered}
$$

**Why:** Every explicit SubTx form finds the TopTx declaration it requires, regardless of where
the operation is accounted for.

##### 3.9.4.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L98) - rejects an absent TopTx declaration for every explicit SubTx form

$$
\begin{gathered}
\forall\,\mathit{subTxDeclaration}\in\mathit{explicitSubTxDeclarations}: \\
\left.
\begin{aligned}
\mathit{subTxDeclarations} &= [\mathit{subTxDeclaration}] \\
\mathit{topTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\}
\implies\mathsf{FailsDS009}
\end{gathered}
$$

**Why:** Neither local accounting nor delegation removes the dependency. Every explicit form,
including zero, requires TopTx to declare.

**Expected failure:** `MissingTopTxDeclaration` for each individually checked form.

#### 3.9.5 DS-TX-009-C05 - Phase-2 failure

**Situation:** The prepared transaction is marked phase-2 invalid and contains an
actual failing script plus collateral. Its single SubTx declares zero; neither body
has Store activity. Funding and preparation satisfy the other ledger requirements.

The cases submit the transaction to the ledger. They check declaration dependency on
the failure path, without independently checking collateral arithmetic or requiring
script evaluation to precede declaration rejection.

##### 3.9.5.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L107) - accepts zero declarations at both levels on the phase-2 failure path

$$
\left.
\begin{aligned}
\mathit{phase2Status} &= \mathsf{Invalid} \\
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\}
\implies \mathsf{Accepted}
$$

**Why:** Both declarations satisfy the dependency. The prepared transaction is accepted
on the phase-2 failure path, even though its script fails.

##### 3.9.5.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L111) - rejects SubTx zero without a TopTx declaration on the phase-2 failure path

$$
\left.
\begin{aligned}
\mathit{phase2Status} &= \mathsf{Invalid} \\
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\}
\implies \mathsf{Rejected}
$$

**Why:** Marking the transaction phase-2 invalid does not waive the TopTx declaration
required by its SubTx.

**Expected failure:** `MissingTopTxUTxODepositDeclaration`.

**State invariant:**

$$
\mathit{ledgerStateAfterRejectedSubmit}=\mathit{ledgerStateBeforeSubmit}
$$

The comparison starts immediately before submission, after funding and preparation.

#### 3.9.6 DS-TX-009-C06 - Fixture integrity

**Situation:** The fixture builds transaction bodies from generated declarations.
SubTxs are occurrences in a sequence, so equal declarations must remain separate
entries. This is a test-construction invariant, not an additional protocol rule.

##### 3.9.6.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs#L118) - preserves the number of SubTxs, including those with repeated declarations

**Construction:**

$$
\mathit{constructedBody}=\mathrm{declarationToTxBody}(\mathit{fixture})
$$

**Invariant:**

$$
\begin{aligned}
&\mathrm{length}\left(\mathrm{subTransactions}(\mathit{constructedBody})\right) \\
&\qquad=\mathrm{length}\left(\mathrm{subTxDeclarations}(\mathit{fixture})\right)
\end{aligned}
$$

**Why:** Building the test transaction must preserve the number of SubTxs being tested.
Two equal declarations count as two occurrences; deduplicating them could silently
change whether the declaration rule is being exercised as intended.

**Checked:** The property compares the requested and constructed counts over generated
fixtures. It checks count equality; preservation of declaration contents and order
would require separate assertions.

### 3.10 DS-TX-010 - Validation of delegated SubTx contributions

**Rule identifier:** `DS-TX-010`

**Decision:** Agreed

Validate delegation through the originating SubTx's exact UTxO capacity deposit accounting
and the completed batch's financial accounting:

1. The SubTx's declared contribution must equal its own UTxO capacity deposit change under
   DS-TX-003, regardless of delegation.
2. A delegated contribution is accounted for by TopTx exactly once. It is
   excluded from `subTxLocalNetUTxODepositChanges` and included in `topTxNetUTxODepositChange` under
   DS-TX-002 and DS-TX-006.
3. TopTx must declare the entire batch's exact net change, including every
   SubTx contribution, under DS-TX-002, DS-TX-003 and DS-TX-009.
4. The complete batch must fund that net change and balance under DS-TX-004.
   Release settlement must also satisfy DS-TX-006 and DS-TX-007.

For example, a SubTx requesting a net allocation of 3 ADA, with no other Store activity
in the batch, requires `TopTx.DeclaresNetUTxODepositAllocation 3` in TopTx. Reject
`TopTx.DeclaresNetUTxODepositAllocation 2`, even if the Store already has surplus funds.
A correct declaration also fails if the batch does not provide the required funds.

An opposing valid contribution may offset a delegated request in the batch net change;
this does not cancel its originating body's exact accounting obligation. Each
contribution must be included once, with the correct sign.

This validation adds neither an independent financial-balance requirement for SubTx nor
an additional declaration field. Local and delegated contributions remain subject to the
same exact UTxO capacity deposit rule; delegation determines their accounting location within
the batch.

### 3.11 DS-TX-011 - UTxO capacity deposit release authority follows the store-backed output

**Rule identifier:** `DS-TX-011`

**Decision:** Agreed

On the ordinary successful spending path, the authority to release an output's allocated
UTxO capacity deposit follows that output's spending conditions. Satisfy its existing key or
script authorization; no separate DepositStore release credential or witness is
required. Funding the original deposit gives the funder no retained refund claim or
additional approval right.

Released UTxO capacity deposits participate in exact accounting under DS-TX-003. A body whose
released UTxO capacity deposits exceed its newly allocated UTxO capacity deposits has a release
contribution. SubTx declares its own contribution; TopTx declares the net change for the
complete batch. Batch netting and settlement still follow DS-TX-002, DS-TX-006 and
DS-TX-007; release does not imply an extra gross Store release.

For example, Alice funds a UTxO capacity deposit of 2 ADA for a store-backed output
controlled by Bob. If Bob validly spends it without creating replacement store-backed
outputs, its body must account for a 2 ADA release contribution. Alice's approval is not
required, and the settlement destination need not be Alice.

A SubTx authorizes delegated release through its explicit `DelegateToTopTx` target.
TopTx handles settlement under the existing netting rules; the SubTx does not select a
final TopTx output index. Ordinary spending authorization cannot be replaced by a
declaration or by referencing an output. Collateral consumption follows its separate
authorization and settlement rules under DS-COLL-001 through DS-COLL-004.

### 3.12 DS-TX-012 - Zero application ADA and empty application assets

**Rule identifier:** `DS-TX-012`

**Decision:** Agreed

A store-backed output may contain zero application ADA, including any of these cases:

- Native assets with no ADA.
- No application assets, with a datum or reference script.
- No application assets, datum or reference script, retaining its address.

Each output still requires the full allocated UTxO capacity deposit calculated under
DS-STORE-003. Empty application assets do not make an output free to store: its address,
encoding and fixed overhead still enter the size-based formula. Creating it remains
subject to the explicit declaration and exact accounting requirements of DS-TX-001 and
DS-TX-003.

This permission does not relax other output validation, including nonnegative asset
amounts, size limits or address validity. Implicit-deposit outputs retain their existing
minimum-coin requirements. A store-backed collateral return may also have zero
application value, provided the collateral funding and settlement rules hold; the
externally held UTxO capacity deposits do not count as its application coins.

## 4. Collateral

### 4.1 DS-COLL-001 - Both output variants supported for collateral

**Rule identifier:** `DS-COLL-001`

**Decision:** Both variants must be supported

Collateral inputs and collateral return must support both `ImplicitDepositTxOut` and
`StoreBackedTxOut`, subject to the applicable collateral validation rules. Restricting
collateral to implicit-deposit outputs is not the intended first-version behavior.

Preserve the existing collateral validation trigger: require collateral and run
`validateBatchCollateral` when TopTx or any SubTx contains redeemers. The UTxO capacity
deposit funding, minimum collateral fee and supplied `totalCollateral` checks use this
same scope. Store-backed outputs or DepositStore declarations alone do not introduce a
collateral requirement. Existing checks on supplied inputs and outputs that run
independently of this trigger continue to apply.

On the phase-2 failure path, the effects applied to the UTxO are collateral consumption
and collateral return, rather than ordinary spending and output creation. Store-backed
collateral consumption can release UTxO capacity deposits; a store-backed collateral return
requires a UTxO capacity deposit. Their accounting must preserve ADA and DepositStore
solvency using the effects actually applied.

The ordinary DepositStore declaration and its regular settlement outputs cannot simply
be applied unchanged on this path. DS-COLL-002 specifies the funding and destination of
the collateral UTxO capacity deposit adjustment. Whether that adjustment increases or
decreases the store is derived under DS-COLL-004; there is no separate collateral
DepositStore declaration.

### 4.2 DS-COLL-002 - Collateral UTxO capacity deposit surplus and shortfall

**Rule identifier:** `DS-COLL-002`

**Decision:** Agreed for a fixed pricing policy

On an accepted phase-2 failure, use the UTxO capacity deposits released by consumed
store-backed collateral to cover the UTxO capacity deposit required by the collateral return.
Transfer all excess released UTxO capacity deposits to the fee pot. Fund any shortfall from
the collateral inputs' coins, while still covering the required collateral fee.

Define:

- `releasedUTxODeposits`: the sum of UTxO capacity deposits allocated to the consumed store-backed
  collateral inputs. Implicit-deposit inputs contribute zero to this amount.
- `collateralReturnUTxODeposit`: the UTxO capacity deposit required by a store-backed collateral return
  under the fixed policy. An absent or implicit-deposit return contributes zero.
- `collateralInputCoins`: the sum of the collateral inputs' output coins.
- `collateralReturnCoins`: the return output's coins, or zero when absent.

Output coins include the whole ADA value of an implicit-deposit output and the
application ADA of a store-backed output. Any implicit minimum is already part of those
coins; do not also count it as UTxO capacity deposit released from the DepositStore. A fixed
pricing policy does not imply equal input and return UTxO capacity deposits: their chargeable
sizes or other priced characteristics may differ.

```text
additionalUTxODeposit = max 0 (collateralReturnUTxODeposit - releasedUTxODeposits)
releasedUTxODepositFee = max 0 (releasedUTxODeposits - collateralReturnUTxODeposit)

collateralCoinFee = collateralInputCoins - collateralReturnCoins - additionalUTxODeposit
collateralFee = collateralCoinFee + releasedUTxODepositFee
minimumCollateralFee = ceil(txFee * collateralPercentage / 100)

collateralCoinFee ≥ minimumCollateralFee
```

Collateral coins must cover the minimum fee after funding the return and any additional
deposit. All excess released UTxO capacity deposits are added to the fee pot on top of that
independently funded minimum; that surplus cannot satisfy or reduce the minimum
collateral requirement. Released UTxO capacity deposit surplus cannot instead finance a
larger return.

The following conservation equation must hold:

```text
collateralInputCoins + releasedUTxODeposits
    = collateralReturnCoins + collateralReturnUTxODeposit + collateralFee
```

On settlement, the DepositStore balance and its UTxO capacity deposit obligation both change
by `collateralReturnUTxODeposit - releasedUTxODeposits`, and the fee pot
receives `collateralFee`. This collateral settlement does not credit the treasury
directly. It preserves the existing solvency margin and total ADA. Only the excess
UTxO capacity deposit released by these collateral inputs is transferred; an unrelated
surplus already in the store is untouched.

These transfers are separate from the successful execution path. Ordinary DepositStore
declarations and ordinary output creation are not applied on this failure path.
Conversely, collateral settlement is not applied on success.

For example, using ADA units and a minimum collateral fee of 1 ADA:

| Input coins | Return coins | Released UTxO capacity deposits | Required UTxO capacity deposits | Additional deposit | Released UTxO capacity deposit fee | Collateral fee | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 5 | 3 | 2 | 1 | 0 | 1 | 3 | Funded |
| 5 | 3 | 1 | 2 | 1 | 0 | 1 | Funded |
| 5 | 4 | 1 | 2 | 1 | 0 | 0 | Reject |
| 5 | 5 | 2 | 1 | 0 | 1 | 1 | Reject: collateral coin fee below minimum |

The transaction must already specify enough collateral coins to fund its return and any
additional UTxO capacity deposits, with the remaining coins covering the minimum collateral
fee. Excess released UTxO capacity deposits are added to the fee pot. The ledger cannot
reduce the signed return amount or select extra inputs to repair a shortfall; such a
transaction fails collateral validation. A funded case still has to satisfy the other
collateral rules, including native-asset conservation and the implicit minimum when the
return uses that variant.

DS-COLL-003 specifies the meaning and validation of `totalCollateral` with this UTxO capacity
deposit adjustment. DS-COLL-004 requires the adjustment to be derived without a separate
declaration. Parameter changes remain deferred under DS-STORE-002.

### 4.3 DS-COLL-003 - Total collateral declaration

**Rule identifier:** `DS-COLL-003`

**Decision:** Agreed

When supplied, `dtbrTotalCollateral` declares the coins taken from the collateral
outputs after subtracting the specified collateral return. It includes any additional
deposit funded from those coins and excludes UTxO capacity deposits released from the
DepositStore.

Enforce the following equality within the collateral validation scope defined in
DS-COLL-001:

```text
computedTotalCollateral = collateralInputCoins - collateralReturnCoins

dtbrTotalCollateral = SJust amount
    ⇒ amount = computedTotalCollateral

collateralCoinFee = computedTotalCollateral - additionalUTxODeposit
collateralFee = collateralCoinFee + releasedUTxODepositFee

collateralCoinFee ≥ minimumCollateralFee
```

Reject a supplied amount that differs from the computed total. If the optional field is
absent, derive the total from the collateral inputs and return; absence does not bypass
UTxO capacity deposit funding or the minimum collateral fee check. Other collateral
validation requirements continue to apply.

For example, 5 ADA of input coins and a 2 ADA return require a supplied
`totalCollateral` of 3 ADA. If the UTxO capacity deposit shortfall is 1 ADA, 2 ADA remains
for the collateral coin fee. Excess released UTxO capacity deposits, when present instead,
are added separately to the fee credit under DS-COLL-002.

This rule retains the existing optional field and its input-minus-return relationship.
The collateral DepositStore adjustment is derived under DS-COLL-004.

### 4.4 DS-COLL-004 - Derived collateral DepositStore settlement

**Rule identifier:** `DS-COLL-004`

**Decision:** Agreed

The ledger derives the collateral DepositStore change from the resolved collateral
inputs and the specified collateral return, using the UTxO capacity deposit amounts defined
in DS-COLL-002:

```text
collateralStoreChange = collateralReturnUTxODeposit - releasedUTxODeposits
```

A positive result increases the store balance; a negative result decreases it. No
separate collateral DepositStore operation field is required. The existing optional
`dtbrTotalCollateral` retains its meaning under DS-COLL-003.

On successful execution, apply the ordinary DepositStore operations; collateral inputs
remain unspent and the collateral return is not created. On an accepted phase-2 failure,
apply only the derived collateral settlement under DS-COLL-002; ordinary TopTx and SubTx
DepositStore operations have no effect on that path. Reject collateral that cannot fund
the derived settlement and required fee, without changing ledger state.

## 5. DepositStore state and pricing

### 5.1 DS-STORE-001 - DepositStore solvency

**Rule identifier:** `DS-STORE-001`

**Decision:** Agreed

Every accepted ledger state must have enough ADA in the DepositStore to cover its
outstanding obligations.

For a ledger state `state`, define:

- `storeBalance(state)`: the actual ADA held in the DepositStore.
- `totalUTxODeposits(utxo(state))`: the total UTxO capacity deposit obligation for the live
  store-backed outputs, under the agreed pricing and release policy.
  Implicit-deposit outputs do not impose obligations on this store.

The invariant is:

```text
storeBalance(state) ≥ totalUTxODeposits(utxo(state)) ≥ 0
```

Both quantities are denominated in ADA. `totalUTxODeposits` is an obligation, not
another balance to add to the ledger's total ADA. DS-STORE-003 defines the UTxO capacity
deposits allocated under the fixed policy; DS-STORE-002 covers the deferred historical
information needed when parameters change.

For a transition from `before` to `after`:

```text
storeBalance(after)
    = storeBalance(before) + netAllocationApplied - netReleaseApplied

storeBalance(before) + netAllocationApplied - netReleaseApplied
    ≥ totalUTxODeposits(utxo(after))
```

`netAllocationApplied` and `netReleaseApplied` are nonnegative amounts actually settled
by that transition, each counted once. A request for TopTx funding does not increase the
balance until the funding is settled. The full amount of an actual transfer is counted;
DS-TX-003 requires the declared net transfer to match the exact change in UTxO capacity
deposit obligations. Under DS-TX-002, SubTx accounting amounts are contributions within
the TopTx net change, not additional transfers to add to it. When the batch's declared
operations settle successfully:

```text
netAllocationApplied - netReleaseApplied = txTotalNetUTxODepositChange

txTotalNetUTxODepositChange = totalUTxODeposits(utxo(after)) - totalUTxODeposits(utxo(before))
```

For a successful batch under the fixed policy, store balance and required UTxO capacity
deposits therefore change by the same amount. This preserves any existing solvency
margin; it does not replace the global solvency inequality with an assumption that every
initial or migrated state has zero margin.

For a transaction batch, the resulting state includes both TopTx and SubTx effects. The
batch must not be accepted with an underfunded DepositStore. This invariant does not
require each SubTx to balance financially on its own. Any temporary accounting used
while processing SubTx before TopTx must not be exposed as an accepted ledger state or
treated as proof that a SubTx is independently valid.

The invariant also applies to accepted states after initialization, era translation,
epoch and parameter changes, and collateral processing. On script failure, the check
must use the effects actually applied; declared operations that were not applied cannot
contribute funding. Both collateral output variants must be supported under DS-COLL-001,
with the fixed-policy settlement described by DS-COLL-002.

For example, starting with a store balance of 10 ADA:

| Net allocation applied | Net release applied | UTxO capacity deposits required after | Balance after | Result for DS-STORE-001 |
| --- | --- | --- | --- | --- |
| 0 | 1 | 9 | 9 | Pass |
| 0 | 2 | 9 | 8 | Reject |
| 0 | 2 | 6 | 8 | Pass |
| 3 | 0 | 12 | 13 | Pass |

These results establish solvency only. A passing resulting state does not show that a
transaction satisfies DS-TX-003: reject any net allocation or net release that does not
match the exact change from its prior UTxO capacity deposit obligations. These examples do
not authorize releasing unrelated surplus or validate a target.

### 5.2 DS-STORE-002 - Historical pricing for output UTxO capacity deposits

**Rule identifier:** `DS-STORE-002`

**Decision:** Historical pricing must be recoverable; handling parameter changes is deferred

The current increment assumes that `coinsPerUTxOByte` does not change. It does not yet
handle pricing changes over time. This restriction does not remove the future
requirement to account correctly for outputs created under different parameter values.

For each live store-backed output, the ledger must eventually be able to recover the
pricing basis used when its UTxO capacity deposit was established, including the applicable
`coinsPerUTxOByte` value and any relevant pricing formula or chargeable-size definition.
The current protocol parameters alone cannot recover that historical basis after the
price changes. Do not silently recompute an old output's historically allocated UTxO capacity
deposit using the latest price.

For illustration, DS-STORE-003 charges 260 bytes for an output whose serialized size is
100 bytes, including the fixed 160-byte overhead. At a hypothetical price of 4 lovelace
per byte, its allocated UTxO capacity deposit is 1040 lovelace. A later price of 6 would give
1560 lovelace for that same size; it does not establish that 1560 lovelace was
originally allocated to the output.

Live UTxO entries retain the allocated UTxO capacity deposit amount under DS-STORE-005. The
representation of any additional historical pricing information remains undecided: it
could retain the applicable parameter directly or a pricing reference with enough
history to recover it. Its retention policy remains to be designed; this requirement
does not mandate adding a field to the serialized transaction `TxOut`. Era translation
must preserve the pricing basis of any existing store-backed outputs. The
Conway-to-Dijkstra transition introduces no such outputs under DS-STORE-004.

DS-TX-003 requires exact UTxO capacity deposit accounting and rejects voluntary excess net
allocations, so these operations create no separate overpayment refund claims. Whether
an explicit repricing transition is permitted remains a separate decision. The solvency
rule must eventually cover parameter changes under that policy; constant-price tests
alone will not establish this.

### 5.3 DS-STORE-003 - UTxO capacity deposits calculated from output size

**Rule identifier:** `DS-STORE-003`

**Decision:** Agreed for a fixed pricing policy

Retain the existing byte-based minimum-UTxO formula for the UTxO capacity deposits allocated
to each newly created store-backed output:

```text
requiredUTxODeposit(output)
    = coinsPerUTxOByte * (160 + serializedSize(output))
```

`serializedSize(output)` uses the existing CBOR-sized-output convention. It includes the
address, application assets, datum, reference script and their encoding overhead, as
present in the output. The fixed 160-byte overhead is retained. The DepositStore balance
and the body's DepositStore declaration are outside the output and do not add bytes to
its serialized size.

For a finalized output and fixed parameters, the UTxO capacity deposit amount is determined.
Allocating that UTxO capacity deposit in the external store does not change the output's
serialized size, so it does not require adding a deposit field and recalculating that
field's encoding contribution. Transaction construction can still change the output
itself: changing application ADA, assets, address, datum or script requires using the
size of the resulting output. This rule does not assert that overall transaction
balancing requires no iteration.

Use this formula for both regular store-backed outputs and a store-backed collateral
return. Sum the allocated amounts of a body's own new store-backed outputs to obtain
`allocatedUTxODeposits(body)`. Spending a store-backed output releases its allocated
UTxO capacity deposit; recover that stored amount from the resolved live UTxO entry under
DS-STORE-005.

The charged size is the size measured when accepting the output. CBOR encoding is not
canonical, so reserializing a decoded output later need not reproduce that size. Recover
the allocated UTxO capacity deposit from retained information, such as its amount or original
charged size, even while the price remains constant.

Implicit-deposit outputs retain their existing minimum-coin validation and contribute no
UTxO capacity deposit obligation to the DepositStore. Parameter changes remain deferred under
DS-STORE-002; DS-STORE-004 defines Conway-to-Dijkstra initialization.

### 5.4 DS-STORE-004 - DepositStore initialization at the Conway transition

**Rule identifier:** `DS-STORE-004`

**Decision:** Agreed

When transitioning from Conway to Dijkstra, retain every existing UTxO as an
implicit-deposit output with its full ADA and native-asset value. Do not automatically
convert outputs into store-backed outputs or extract their implicit minimum into the
DepositStore.

Initialize the new DepositStore with:

```text
storeBalance = 0
totalUTxODeposits = 0
```

Existing ledger pots are not used to fund the new Store during this transition.
Subsequent transactions introduce store-backed outputs and fund their UTxO capacity deposits
under DS-TX-003 and DS-TX-004. Spending an existing implicit-deposit output releases no
UTxO capacity deposits from the DepositStore; its coins can fund the UTxO capacity deposit
required by newly created store-backed outputs through normal transaction accounting.
Collateral return creation follows DS-COLL-002 through DS-COLL-004 on the failure path.

### 5.5 DS-STORE-005 - Consistency of UTxO capacity deposit records

**Rule identifier:** `DS-STORE-005`

**Decision:** Agreed

Every live store-backed UTxO must have exactly one recoverable allocated UTxO capacity
deposit amount associated with its `TxIn`. Treat `utxoDepositRecords(state)` as a
logical map from each live store-backed `TxIn` to its allocated UTxO capacity deposit amount.
Its keys must match the live store-backed outputs:

```text
keys(utxoDepositRecords(state))
    = { txIn | output(UTxO(state)[txIn]) is StoreBackedTxOut }

totalUTxODeposits(utxo(state)) = sum(values(utxoDepositRecords(state)))
```

Creating a store-backed output establishes its UTxO capacity deposit record using
DS-STORE-003. Consuming that output releases the allocated amount exactly once and
removes the record. Reference inputs leave the record unchanged and release no UTxO capacity
deposits. Implicit-deposit outputs have no Store UTxO capacity deposit obligation.

UTxO changes, UTxO capacity deposit records and the Store balance must settle atomically. On
success, update the records for the ordinary effects actually applied. On an accepted
phase-2 failure, update only those for the collateral effects. Rejecting a transaction
leaves all three unchanged. No accepted state may have a missing record, an orphan
record or a UTxO capacity deposit amount released twice.

Store the allocated UTxO capacity deposit alongside the output in its live UTxO entry, keyed
by `TxIn`. An implicit entry has no DepositStore obligation; a store-backed entry
retains exactly one allocated amount. The conceptual representation is:

```haskell
data UTxOEntry era
  = ImplicitDepositEntry !(ImplicitDepositTxOut era)
  | StoreBackedEntry !(StoreBackedTxOut era) !Coin
    -- Coin is the allocated UTxO capacity deposit.

newtype UTxO era =
  UTxO { unUTxO :: Map TxIn (UTxOEntry era) }
```

Calculate the amount from the accepted sized output before its charged size is
discarded. Keep it in ledger-state serialization and snapshots so restoring or rolling
back state preserves the allocated amount. This is ledger-state metadata; transaction
output contents and the `TxIn` reference need no additional field.

The global Store balance holds the actual ADA. Entry amounts record its UTxO capacity deposit
obligations and must not be counted again as monetary balances or stake. Recording the
allocated amount supports exact release accounting; the additional historical-pricing
work under DS-STORE-002 remains deferred. The precise API and state encoding for each
era remain implementation work.

## 6. Script compatibility

### 6.1 DS-PLUTUS-001 - Plutus compatibility

**Rule identifier:** `DS-PLUTUS-001`

**Decision:** Target compatibility with all supported Plutus versions

The intended design supports store-backed outputs with Plutus V1, V2, V3 and V4, subject
to each version's existing feature restrictions. Store UTxO capacity deposits alone should
not impose a V4-only restriction.

The context translation and any exposure of DepositStore information remain to be
designed and tested. The current legacy translation paths contain `unexpected
StoreBackedTxOut` errors that must be addressed in that work. No context-value
projection or translation change is selected here.

## 7. Stake and voting

### 7.1 DS-STAKE-001 - Stake and voting power

**Rule identifier:** `DS-STAKE-001`

**Decision:** Exclude DepositStore UTxO capacity deposits for the current prototype

ADA held in the DepositStore contributes neither stake nor voting power. Do not
attribute an output's allocated UTxO capacity deposit to its staking credential or count the
Store balance separately in stake or voting distributions.

Before applying the existing staking eligibility and delegation rules, the output's ADA
contribution is:

```text
stakeContribution(ImplicitDepositTxOut output) = full ADA in output
stakeContribution(StoreBackedTxOut output) = application ADA in output
```

An implicit output containing 10 ADA therefore contributes 10 ADA where eligible. A
store-backed output containing 8 ADA with an allocated UTxO capacity deposit of 2 ADA
contributes only 8 ADA. Existing registration, delegation and snapshot timing still
apply.

Net allocations and net releases affect stake through the actual resulting outputs and
the existing stake update rules; they do not create a separate Store attribution.
Excluding UTxO capacity deposits from stake and voting power does not exclude them from
ledger balances or ADA conservation. The Store remains an ADA pot under DS-STORE-001.

## 8. Remaining design work

DS-TX-001 requires an explicit declaration; DS-TX-002 assigns the batch net change to
TopTx and accounts for each contribution once; DS-TX-003 requires exact accounting for
each body's UTxO capacity deposit obligations; DS-TX-004 requires TopTx batch financial
balance; DS-TX-005 requires release accounting when leaving store-backed outputs;
DS-TX-006 derives TopTx's settlement amount and allows mixed release settlement;
DS-TX-007 requires valid destinations containing their settlement amounts; DS-TX-008
makes zero SubTx contributions explicit and other operation amounts strictly positive;
DS-TX-009 requires a TopTx declaration whenever any SubTx declares an operation;
DS-TX-010 validates delegated contributions through exact body accounting and batch
funding; DS-TX-011 ties UTxO capacity deposit release authority to the output's spending
conditions, with no retained funder claim; DS-TX-012 permits zero application ADA and
empty application assets in store-backed outputs while retaining their full UTxO capacity
deposit requirement; DS-COLL-001 supports both collateral output variants and preserves
the existing validation trigger; DS-COLL-002 sends excess released collateral UTxO capacity
deposits to the fee pot and funds a UTxO capacity deposit shortfall from collateral coins;
DS-COLL-003 preserves the input-minus-return meaning of the optional total collateral
declaration; DS-COLL-004 derives the collateral Store change without a separate
declaration; DS-STORE-001 requires a solvent resulting ledger state; DS-STORE-002
records the deferred historical-pricing requirement; DS-STORE-003 allocates UTxO capacity
deposits using the existing output-size formula; DS-STORE-004 retains Conway outputs as
implicit and starts the new Store empty; DS-STORE-005 keeps UTxO entries, their stored
UTxO capacity deposit amounts and Store balance consistent; DS-STAKE-001 excludes Store
UTxO capacity deposits from stake and voting power for the current prototype. The following
design work remains:

- Clarify the additional DS-TX-007 settlement guarantee while preserving SubTx
  imbalance and fee contributions. The 10 ADA plus 2 ADA single-output example
  requires 12 ADA when there are no other flows; existing fields do not separately
  express a pre-release output amount or an intended export allowance.
- The concrete APIs and ledger-state encoding for the chosen live UTxO entries
  and the global DepositStore balance, including migration and state restoration.
- Plutus context compatibility across all supported versions, including the
  representation of store-backed outputs. This work is deferred under
  DS-PLUTUS-001.
- Historical pricing metadata, its retention and migration, and the accounting
  policy when `coinsPerUTxOByte` changes. These are deferred beyond the current
  constant-price scope.

The implication in DS-TX-001 is deliberately one-way: declaring an operation does not
require creating or spending a store-backed output, and its presence alone does not
prove sufficient funding or authority to release a UTxO capacity deposit.

## 9. Executable domain specification

Update this document alongside refinements to the executable specs, including their
rule descriptions, terminology and cases. Track implementation status and execution
results in the separate verification record. Explain the business
situation, expected outcome and reasoning for each test in plain language, and link to
the corresponding executable checks. Distinguish isolated validator checks from ledger
submissions so that readers can tell exactly what each test establishes. Use mathematical
symbols with semantic variable and predicate names, such as `subTx`, `topTx`,
`subTransactions` and `hasDeclaration`. Keep the plain-language explanation alongside
the formula.

The document and specs share the same domain language: UTxO capacity deposits,
allocation, release, net change, delegation, settlement and solvency. Module
boundaries follow those responsibilities. `prop` and `it` select how a rule is
verified; they do not define separate categories of domain rules. Keep the requirement
and expected outcomes visible in the spec. Ledger scenarios may use a table containing
the description, declarations, phase-2 outcome and expected decision. Properties receive
domain fixtures from generators and state their assertions directly; fixture construction
and ledger submission mechanics belong in the adapters.

An executable spec describes the intended behavior. Its existence alone does not
establish that the ledger implements the rule. The
[verification record](dijkstra-deposit-store-verification.md) tracks implementation and
execution separately. Construction and codec checks establish valid representations;
they do not establish enforcement of transaction accounting rules.

DS-STORE-002 repricing, DS-PLUTUS-001 context projection and the unresolved stronger
DS-TX-007 settlement guarantee remain deferred. Their absence from the executable
outline must not be interpreted as an agreed behavior.

### 9.1 Domain scenarios

Define the scenarios before implementing validators. Each scenario records:

1. **Initial state:** the live outputs, their allocated UTxO capacity deposits, Store balance and
   protocol parameters relevant to the rule.
2. **Submitted batch:** each body's inputs, outputs and declaration, including
   delegation and any contribution to TopTx fees.
3. **Expected decision:** acceptance or rejection for the identified rule.
4. **Expected effects:** consumed and created outputs and changes to Store and
   other affected pots. Rejection leaves the accepted ledger state unchanged.

Pair each negative case with an otherwise valid positive case. A test must not pass
because of an unrelated error in witnesses, inputs, fees or minimum coins. Test
preparation may repair those incidental requirements, but must preserve the declaration
or accounting defect being tested. Once predicate failures exist, assert the intended
failure, not merely that some rejection occurred.

Start with concrete examples, then generate amounts, output variants and body
combinations while retaining each scenario's preconditions. Expected outcomes come from
the rules and independent reference model, not the validator under test. Preserve
financially imbalanced SubTx and their contributions to TopTx fees in the valid
fixtures.

Transition conditions are part of the rule being checked. State properties say
whether they concern ordinary success, accepted phase-2 failure or rejection.
Collateral validation still applies whenever the existing redeemer trigger is met,
including when scripts succeed; this is distinct from applying collateral effects.
Likewise, TopTx settlement routing applies to the batch net-release branch, while
net allocation and explicit zero retain their own declaration semantics.

### 9.2 Ledger adapter boundary

The supporting `DepositStore/Adapter/` directory translates domain scenarios into ledger
fixtures and observations using the existing `ImpTest` helpers. The implemented DS-TX-009
adapters separate declaration data, generation, transaction construction, scenario execution
and assertions. The DS-TX-001 creation adapters add output shapes and body-specific
creation scenarios. `UTxO.hs` and `Ledger.hs` remain planned responsibilities; no empty
modules are needed before a scenario uses them.

| Adapter | Status and responsibility |
| --- | --- |
| [Transaction.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Adapter/Transaction.hs) | Builds declaration-only bodies with distinct fictitious inputs for validator properties, and funded implicit-output transactions for ledger scenarios. Fixture fixup preserves the requested declarations. Broader delegation and settlement fixtures remain to be added. |
| [Declarations/TopTx.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Adapter/Declarations/TopTx.hs) and [Declarations/SubTx.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Adapter/Declarations/SubTx.hs) | Build and enumerate declaration forms through qualified `TopTx` and `SubTx` names. These helpers describe fixture data, not expected validation results. |
| [Fixture/DeclarationDependency.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Adapter/Fixture/DeclarationDependency.hs) | Defines `Declarations` and generates declaration combinations, equal local allocation/release pairs, and all explicit SubTx forms. Generators preserve each property's preconditions. |
| [DeclarationScenarios.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Adapter/DeclarationScenarios.hs) | Registers each scenario-table row as a separate ledger test with fresh state. Prepares the requested phase-2 outcome and checks the declared acceptance or exact rejection. |
| [Fixture/OutputCreation.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Adapter/Fixture/OutputCreation.hs) | Defines own-output variants and batch declarations for DS-TX-001 creation. Generates empty and implicit-only sequences, store-backed outputs at every position, all-store-backed sequences and mixed sequences. Store-backed fixtures do not claim funded capacity deposits. |
| [OutputCreation.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Adapter/OutputCreation.hs) | Builds isolated creation-check bodies and registers ledger scenario rows. Fixup preserves supplied outputs and declarations, allowing only implicit TopTx change. Rejection asserts the exact body-specific failure and unchanged ledger state; acceptance controls use implicit outputs only. |
| `UTxO.hs` | Planned: prepare output variants, inputs, allocated deposit records and initial Store state. |
| `Ledger.hs` | Planned: submit batches or advance the ledger and expose the decision and resulting state when scenarios need this separate boundary. |
| [Assertions.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Adapter/Assertions.hs) | Implements ledger acceptance and exact DS-TX-009 rejection with unchanged ledger state. `conformsTo` compares the validator's complete result with an independently stated domain rule. |

Specs keep their domain assertions and named checks. Adapters handle the technical
details of constructing and exercising the ledger. Expected amounts and decisions
come from the domain rules and an independent reference model; adapters must not
derive them by invoking the validator under test or reading its resulting balance.
Fixture preparation must preserve intentional invalid declarations and accounting
defects. Introducing an adapter does not authorize repairing the condition that a
scenario is intended to reject.

### 9.3 DS-TX-009 - Declaration dependency examples

The [business cases and corresponding tests](#391-ds-tx-009-c01---declaration-dependency)
are explained alongside the rule in sections 3.9.1 to 3.9.6. They distinguish an absent declaration
from an explicit zero, cover cancellation and delegation, and preserve the declaration
requirement when phase 2 fails. The fixture check ensures those cases retain all SubTxs.

### 9.4 DS-TX-001 - Creation declaration examples

The [DS-TX-001 creation spec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationSpec.hs)
checks each body's own regular outputs. Within this domain rule, `Nominal cases` and
`Failure cases` distinguish the expected validation outcomes. Success and rejection
assertions are kept in separate properties.

The spec groups cases by domain behavior: created outputs, spent outputs, reference
inputs, collateral and declaration ownership. Each group contains its applicable
nominal or failure cases. Spent outputs and declaration ownership have nominal controls
beside their failure cases: TopTx and SubTx each spending a store-backed input with its
own declaration, and both active bodies each supplying their own declaration. These
controls describe the permitted behavior. Pair each failure with an otherwise valid
control by removing only the required declaration.
The universal declaration rule is separate because it covers
both outcomes. Cases stay in their domain groups regardless of implementation status.

Five nominal properties expect the creation presence check to succeed:

1. Every explicit TopTx and SubTx declaration passes creation presence, including zero
   and delegation; generated amounts and settlement indices do not establish validity.
2. Empty and implicit-only own-output sequences need no declaration.
3. A TopTx with no own outputs passes the creation presence check even when its nested
   SubTx creates store-backed outputs. DS-TX-009 remains a separate requirement.
4. The creation check excludes collateral return.
5. Reference and collateral input identifiers are not treated as created outputs.

Two failure properties expect rejection:

1. A missing own declaration is rejected when a store-backed output appears at any
   own-output position, for both TopTx and SubTx.
2. A declared SubTx cannot replace a missing declaration when TopTx creates its own
   store-backed output.

The properties compare the isolated validators with `Success ()` or
`Failure (MissingBodyUTxODepositDeclaration :| [])`. Successful presence checks do not
establish that deposit amounts, funding or settlement are correct. The input-identifier
property does not resolve referenced or collateral UTxOs or validate their separate rules.

The seven ledger scenarios use the same grouping: two nominal acceptance controls and
five failure cases expecting rejection.

| Creating body and own outputs | Declarations | Phase-2 outcome | Expected result |
| --- | --- | --- | --- |
| TopTx creates a store-backed output | TopTx absent | Valid | Reject with `MissingUTxODepositDeclaration` |
| SubTx creates a store-backed output | Both absent | Valid | Reject with `SubMissingUTxODepositDeclaration` |
| SubTx creates a store-backed output | TopTx explicit zero; SubTx absent | Valid | Reject with `SubMissingUTxODepositDeclaration` |
| TopTx creates only implicit outputs | TopTx absent | Valid | Accept |
| SubTx creates only implicit outputs | Both absent | Valid | Accept |
| TopTx creates a store-backed output | TopTx absent | Invalid | Reject with `MissingUTxODepositDeclaration` |
| SubTx creates a store-backed output | Both absent | Invalid | Reject with `SubMissingUTxODepositDeclaration` |

The ledger acceptance controls contain no store-backed outputs. Rejection scenarios
preserve the missing declaration and supplied output variants through preparation, assert
the exact failure, and compare ledger state immediately before and after submission.
Store-backed fixtures are submitted only for rejection, so fee and application-asset
balancing cannot be mistaken for funding a UTxO capacity deposit.

For subsequent DS-TX-001 scenarios, an explicit zero is a valid control only when the
body's UTxO capacity deposit change and the TopTx batch net change are actually zero. Do not
create new store-backed outputs with an unfunded zero declaration and describe that
batch as valid merely because it passes the presence check.

### 9.5 Business rules and executable specs

The links identify the owner of each rule in the executable outline. The descriptions
also specify the fixture and generator coverage required when the named checks are
implemented. A rule having a module is not evidence that all its cases are verified.

| Rule or invariant | Behavior to verify |
| --- | --- |
| [DS-TX-001](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationSpec.hs) | A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change. Removing its declaration from an otherwise valid case causes rejection; a parent or child declaration cannot substitute for it. Creation checks consider only the body's own regular outputs. Referencing an output alone does not trigger spending, and collateral has separate rules. Check both acceptance and rejection, including the phase-2 failure path. |
| [DS-TX-002](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/NettingSpec.hs) | Signed body contributions reconcile with the declared TopTx net change, including mixed net allocations and net releases. Switching a SubTx net allocation between local and delegated accounting in an otherwise valid adjusted batch moves the accounting amount between bodies without changing the net store change. |
| [DS-TX-003](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ExactAccountingSpec.hs) | Require each body's released UTxO capacity deposits plus its signed contribution to equal its newly allocated UTxO capacity deposits. Reject excess net allocations, insufficient net allocations, excess net releases and insufficient net releases, including a one-lovelace error and opposing errors that cancel in the batch total. Delegation preserves the originating body's exact contribution; TopTx's own contribution excludes all SubTx contributions. The declared batch net change equals the sum of actual UTxO capacity deposit changes. |
| [DS-TX-004](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ValueConservationSpec.hs) | Every accepted TopTx batch balances consumed and produced values with the net DepositStore term counted once. Generate imbalanced SubTx whose combined batch balances, and reject a final batch imbalance of one lovelace or any native asset. |
| [DS-TX-005](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/FinalReleaseSpec.hs) | A body spending store-backed outputs and creating none declares a release contribution equal to its released UTxO capacity deposits. Reject absent declarations and zero or incorrect own contributions; preserve the release contribution when another body's net allocation offsets the batch net change. A SubTx creating no outputs may explicitly delegate its release; it cannot select a local settlement output. |
| [DS-TX-006](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/TopTxSettlementSpec.hs) | Derive topTxNetUTxODepositChange from txTotalNetUTxODepositChange minus signed local SubTx contributions; delegated operations remain TopTx's responsibility. For net releases, require NoTopTxSettlement exactly when topTxNetRelease is zero, and a TopTx destination otherwise. Generate SubTx-only, TopTx-only and mixed settlement, including local net allocations that make topTxNetRelease exceed txTotalNetRelease and local net releases offset by TopTx net allocations. Count the net store release once. A batch net allocation or explicit zero does not require a TopTx settlement output even when the derived TopTx accounting portion is negative. |
| [DS-TX-007](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/SettlementOutputsSpec.hs) | Reject an index outside its owning body's outputs or an output containing less than its settlement amount. Accept exact coverage and additional funds when other rules hold. For a store-backed settlement output, count application ADA only: its external UTxO capacity deposit cannot cover a settlement shortfall. In a mixed settlement, check TopTx's share rather than the entire batch net release, and never credit the selected output twice. With 10 application ADA plus 2 ADA locally released, one implicit output and no other ADA flows, require 12 ADA. Preserve the alternative with output 10 ADA and a 2 ADA contribution to TopTx fees, subject to all other rules. Further settlement properties await clarification. |
| [DS-TX-008](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ExplicitZeroSpec.hs) | Explicit SubTx zero contributes no funds or delegation and remains distinct from absence. Reject zero, negative and out-of-range amounts for every nonzero operation through checked construction and both decoders. An explicit zero cannot bypass a required positive net allocation or net release. |
| [DS-TX-009](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs) | Any declared SubTx operation requires a TopTx declaration, including explicit zero. The requirement remains when SubTx allocations equal releases, resulting in a zero net amount, and whether those operations are accounted for locally or delegated to TopTx. Ledger scenarios check exact rejection when TopTx is absent and acceptance controls when it declares zero, including phase-2 failure; generated properties check presence across all declaration forms. These checks do not establish exact amounts or settlement validity. |
| [DS-TX-010](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DelegationSpec.hs) | Require delegated contributions to match the originating body's exact UTxO capacity deposit change, be accounted for by TopTx once, reconcile with the batch declaration, and be funded by a balanced batch. Reject omitted, duplicated or incorrectly signed contributions and unfunded declarations. Accept valid offsetting contributions and financially imbalanced SubTx when the complete batch satisfies all rules. |
| [DS-TX-011](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ReleaseAuthoritySpec.hs) | Exercise outputs funded by someone other than their authorized spender. On the successful ordinary spending path, require the existing key or script authorization and exact UTxO capacity deposit accounting, without a separate funder approval or Store witness. Reject unauthorized spending even with a correct release declaration. Cover local and explicitly delegated SubTx settlement; references alone release no UTxO capacity deposits. |
| [DS-TX-012](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ApplicationAssetsSpec.hs) | Generate store-backed outputs with zero ADA and native assets, empty application assets with a datum or reference script, and an address with no application assets, datum or script. Accept otherwise valid cases with exact UTxO capacity deposits and reject absent declarations or incorrect UTxO capacity deposit contributions. Include collateral returns under their separate settlement rules. Preserve all other output validation and implicit minimum-coin checks. |
| [DS-COLL-001](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ValidationSpec.hs) | Preserve the existing collateral trigger for redeemers in TopTx, a SubTx, or both. Store-backed outputs and Store declarations alone do not require collateral. Support both collateral output variants and preserve the existing independent checks on supplied inputs and outputs. When redeemers trigger collateral validation, reject underfunded collateral even if the scripts would succeed, and accept correctly funded collateral when the other rules hold. |
| [DS-COLL-002](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/AccountingSpec.hs) | On an accepted phase-2 failure, all excess released UTxO capacity deposits go to the fee pot and any shortfall is funded from collateral coins. Check the minimum fee using collateral coins after funding the return and additional UTxO capacity deposits; surplus is added on top. Reject a collateral coin fee below the minimum even when UTxO capacity deposit surplus makes the total fee credit sufficient. Independently verify ADA conservation, no direct treasury credit, and that store balance and required UTxO capacity deposit change by the same amount. Cover equal UTxO capacity deposits, surplus, shortfall, multiple inputs, absent returns, both output variants, and a one-lovelace funding deficit. Implicit collateral contributes its full output coins and releases zero Store deposits; an implicit return requires no Store allocation. A store-backed return may contain zero application ADA when its deposit and the minimum collateral fee are funded. Ordinary Store operations have no effect on this path; collateral settlement has no effect on success. |
| [DS-COLL-003](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TotalCollateralSpec.hs) | When collateral validation is active under DS-COLL-001, require every supplied total collateral amount to equal input coins minus return coins, regardless of UTxO capacity deposit surplus or shortfall. Reject a mismatch of one lovelace, including when the scripts would succeed. Derive UTxO capacity deposit funding and fee credit separately, and retain those checks when the optional declaration is absent. Include cases where the declared total differs from the fee credit because coins fund additional UTxO capacity deposits or released UTxO capacity deposits increase fees. |
| [DS-COLL-004](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TransitionSpec.hs) | Derive collateral Store changes from the resolved collateral inputs and return without a separate declaration. Holding collateral inputs, return, fee and policy fixed, ordinary DepositStore declarations cannot alter failure-path settlement. Verify that success applies ordinary Store operations only, accepted phase-2 failure applies collateral settlement only, and rejection applies neither. Check the actual UTxO entries and their allocated deposit records as well as the Store balance: failure consumes and replaces only collateral entries, while rejection preserves all three atomically. |
| [DS-STORE-001](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Store/SolvencySpec.hs) | Starting from a valid state, every accepted transition leaves the actual store balance at least equal to independently calculated outstanding UTxO capacity deposit obligations. Include epoch transitions under the current fixed pricing policy; repricing remains deferred. |
| DS-STORE-002 (deferred) | After a price change, recover each live output's original pricing basis independently of the current parameters. Generate increases, decreases, and outputs from multiple pricing periods; verify release accounting and solvency under the eventual parameter-change policy. |
| [DS-STORE-003](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Store/PricingSpec.hs) | Independently calculate each new store-backed output's UTxO capacity deposit as `coinsPerUTxOByte * (160 + serializedSize(output))`. Check regular outputs and collateral returns, optional datum and script fields, native assets, and CBOR amount-size boundaries. Allocating UTxO capacity deposits outside a fixed output must not change its output size; changing output contents requires a fresh size calculation. Spending releases the allocated amount, including when reserialization would change the size. Implicit outputs contribute zero to the DepositStore obligation. |
| [DS-STORE-004](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Store/ConwayTransitionSpec.hs) | Translate arbitrary valid Conway UTxOs with references and values preserved and every output remaining implicit. The new Store balance and UTxO capacity deposit obligation are both zero, with no funding transfer from other pots. Spending a translated implicit output releases no UTxO capacity deposits from the DepositStore; later creation of store-backed outputs must fund their exact UTxO capacity deposits. Exercise spending a translated implicit output to create a store-backed output: accept the exact declared and funded allocation and reject absent or inexact allocations. |
| [DS-STORE-005](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Store/LiveUTxOSpec.hs) | After every accepted transition, require every live store-backed UTxO entry to retain its allocated amount and those amounts to sum to totalUTxODeposits. Implicit entries have no DepositStore obligation. Exercise creation, consumption, reference-only use, successful execution and accepted phase-2 failure. Detect missing and orphan records, wrong allocated amounts and double releases. Preserve allocated amounts through ledger-state serialization, restoration and rollback. Rejected transitions must leave UTxO, records and Store balance unchanged. |
| DS-PLUTUS-001 (deferred) | Verify store-backed output context translation for every supported Plutus version under its existing feature restrictions, once the projection semantics are defined. |
| [DS-STAKE-001](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs) | Verify that implicit outputs contribute their full ADA and store-backed outputs only their application ADA under the existing eligibility, delegation and snapshot rules. Allocated UTxO capacity deposits and the Store balance contribute no additional stake or voting weight. Exercise ordinary allocations and releases, collateral left unapplied on ordinary success, and collateral-only effects on an accepted phase-2 failure. Preserve eligibility, delegation and snapshot timing. The global Store balance contributes no separate stake, while Store ADA remains included in monetary conservation checks. |
| Store accounting | After an accepted transition, the balance changes by exactly the applied net allocation minus the applied net release. Delegated settlement is counted once. |
| ADA conservation | Moving ADA between outputs and the store preserves total ADA across all ledger pots; required UTxO capacity deposits are never counted as a second balance. |
| Rejected transitions | Rejecting a batch leaves the previously accepted ledger state unchanged. An accepted transaction with failed phase-2 scripts is a separate case: verify the actual collateral effects under the agreed policy. |

Expected balances, UTxO capacity deposit obligations and settlement amounts must come from a
small reference model implementing the agreed rules independently of the ledger
validation helpers. Recalculate UTxO capacity deposits from the model UTxO and any retained
claims under the chosen pricing policy, rather than trusting a cached ledger obligation.
Determine expected store flows from the operations and settlement rules, rather than
inferring them from the implementation's resulting balance.

Generators must exercise both output variants, mixtures of them, TopTx and SubTx
declarations, explicit delegation, mixed net allocations and net releases with either
sign of net change, and batches containing financially imbalanced SubTx whose combined
accounting is valid. Do not silently require every SubTx to balance individually.

Include exact UTxO capacity deposit changes, declarations one lovelace above and below
the required amount, pre-existing store surplus, collateral UTxO capacity deposit
surplus, zero amounts where permitted, and both ends of the supported amount and
output-index ranges. Opposite declaration errors in different bodies must remain invalid
even when they cancel in the batch total. Include exact cancellation with
`TopTx.DeclaresZeroNetUTxODeposit` and explicit SubTx zero with
`SubTx.DeclaresZeroNetUTxODeposit`; distinguish both from absent fields. Verify positive
TopTx and SubTx operation amounts at both supported bounds and rejection of zero,
negative and overflow amounts through checked construction and both wire decoders.
Generate successful lifecycle sequences as well as invalid cases. Enforce coverage of
accepted cases so an implementation that rejects everything cannot satisfy the suite
merely by having no accepted insolvent states.

Conway initialization, fixed-policy epoch transitions and the agreed collateral
behavior belong to the current scope. Parameter changes and Plutus context projection
remain deferred until their policies are specified. Shrinking must retain the
dependencies and preconditions of the case under test, including any intended invalid
condition. Report the random seed and minimized counterexample for reproducible failures.

## 10. Code references

- [TopTx declaration domain API](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxODeposit/TopTx.hs)
- [SubTx declaration domain API](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxODeposit/SubTx.hs)
- [Transaction fields, operations and lenses](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxBody.hs)
- [Output variants and shared interfaces](../libs/cardano-ledger-core/src/Cardano/Ledger/Core.hs)
- [Dijkstra output representations](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxOut.hs)
- [Existing byte-based minimum-UTxO formula](../eras/babbage/impl/src/Cardano/Ledger/Babbage/TxOut.hs)
- [Serialized size measurement](../libs/cardano-ledger-binary/src/Cardano/Ledger/Binary/Decoding/Sized.hs)
- [TopTx UTXO rule](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Utxo.hs)
- [SubTx UTXO rule](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/SubUtxo.hs)
