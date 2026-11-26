<a id="spec-appendices" name="spec-appendices"></a>

# Appendices

[Specification contents](../README.md#table-of-contents) · [← Derived distributions](derived-distributions.md) · [Verification record](../verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/chapters/appendices.md)

> **Keep open design questions and supporting references separate from the rule chapters.**

## Table of contents

<div>
<details>
  <summary><a href="#section-8">A. Remaining design work</a></summary>
  <dl>
    <dd>
      <a href="#ds-pricing-history">A.1 Historical pricing</a><br>
      <a href="#ds-plutus-compatibility">A.2 Plutus compatibility</a><br>
      <a href="#ds-tx-settlement-refinement">A.3 Local settlement</a><br>
      <a href="#ds-state-representation">A.4 State representation</a><br>
    </dd>
  </dl>
</details>
<a href="#section-9">B. Tag migration</a><br>
<details>
  <summary><a href="#section-10">C. Code references</a></summary>
  <dl>
    <dd>
      <a href="#declaration-api">C.1 Declaration API</a><br>
      <a href="#transaction-body-fields">C.2 Transaction body fields</a><br>
      <a href="#declaration-encoding">C.3 Declaration encoding</a><br>
    </dd>
  </dl>
</details>
<details>
  <summary><a href="#net-change-test-cases">D. Net-change test cases</a></summary>
  <dl>
    <dd>
      <a href="#subtx-net-change-test-cases">D.1 SubTx cases</a><br>
      <a href="#toptx-net-change-test-cases">D.2 TopTx cases</a>
    </dd>
  </dl>
</details>
</div>

<a id="section-8" name="section-8"></a>

## A. Remaining design work

> **Distinguish agreed requirements from unresolved design and implementation work.**
>
> The sections below identify what remains open without treating it as an implemented guarantee.

<a id="ds-pricing-history" name="ds-pricing-history"></a>

### A.1 Historical pricing

> **A recorded allocation keeps its original pricing interval after later activations.**

`DepositFormulaHistory` contains the fork's initial formula and ordered activations.
Each `Unspent` holds its output and allocation origin. The history is shared across
entries and persists even when the Store is empty.

| Allocation | Formula on refund | Reserve |
| --- | --- | --- |
| Imported min-ADA output | `initialFormula` | Capped by its ADA and held inside the output. |
| Dated min-ADA output | Formula active at its allocation slot | Capped by its ADA and held inside the output. |
| Dated deposit-backed output | Formula active at its allocation slot | Full calculated amount held in the Store. |

A parameter change records the current version with its new rate at the effective
epoch boundary. Activating experimental V2 records a new version and effective
slot. Both are prospective. The [two-output example](domain-model.md#ds-pricing) gives the exact
refunds before and at the activation slot.

A distinct future proposal to reprice existing entries would need to specify how
to fund or release the difference for each live output.

<a id="ds-plutus-compatibility" name="ds-plutus-compatibility"></a>

### A.2 Plutus compatibility

> **Define how deposit-backed outputs appear to each supported Plutus version.**
>
> Compatibility is the target; context projection and translation still require design and tests.

**Decision:** Target compatibility with all supported Plutus versions; context projection
and translation remain deferred.

The intended design supports deposit-backed outputs with Plutus V1, V2, V3 and V4, subject
to each version's existing feature restrictions. Store UTxO capacity deposits alone should
not impose a V4-only restriction.

The context translation and any exposure of DepositStore information remain to be
designed and tested. The current legacy translation paths contain `unexpected
DepositBackedTxOut` errors that must be addressed in that work. No context-value
projection or translation change is selected here.

<a id="ds-tx-settlement-refinement" name="ds-tx-settlement-refinement"></a>

### A.3 Local settlement

> **Determine any stronger guarantee needed beyond the destination’s minimum amount.**
>
> $`\text{Settlement output ADA} \ge \text{release amount}`$ does not establish the origin of its coins. SubTx fee contributions must remain possible.

**Decision:** Output-index and output-coin checks are agreed, as is existing SubTx
imbalance. The stronger settlement guarantee remains open.

A SubTx consuming 10 ADA of serialized value plus a 2 ADA external deposit can
create a 12 ADA min-ADA output. If the new embedded minimum is 2 ADA, the child
declares zero. It can also create a 10 ADA output and contribute 2 ADA to TopTx
fees. With every other flow fixed and no fee contribution, a 10 ADA output
leaves 2 ADA unaccounted for. [Balance N06–F04](transaction-rules.md#ds-tx-accounting-balance-n06)

SubTx ADA surplus must remain available to fund TopTx fees or other bodies, including
when the SubTx settles a net Store release locally. Choosing
`SubTx.DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput index)` must not
impose independent SubTx balance or prohibit net ADA exports. The proposed no-export
inequality $`\text{ordinaryProducedADA} \ge \text{ordinaryConsumedADA} + \text{amount}`$ is therefore not
adopted.

Using the body's actual signed external Store change, its ADA export is

```math
\text{netADAExport}
= \text{ordinaryConsumedADA} - \text{storeChange(body)} - \text{ordinaryProducedADA}
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

This open question does not change the agreed destination bound or the existing ability of a SubTx to contribute ADA to TopTx fees. No additional signed allocation field, export restriction or independent SubTx balance rule is selected here.

<a id="ds-state-representation" name="ds-state-representation"></a>

### A.4 State representation

> **Keep accepted outputs and allocation origins together; retain formula history in the Store.**

```text
LedgerState
├── lsAccountingState :: AccountingState
│   ├── asUTxOStore :: UTxOStore
│   │   ├── depositFormulaHistory :: DepositFormulaHistory
│   │   ├── totalDepositAmount :: DepositAmount
│   │   └── allocations :: IndexedUTxOs
│   │       └── TxIn → Unspent TxOut
│   │           ├── output
│   │           └── allocatedAt :: AllocatedAt
│   ├── asDeposited  — certificate and governance deposit pot
│   ├── asFees
│   ├── asInstantStake
│   └── asDonation
├── lsCertState :: CertState
└── lsGovState :: GovState
```

| Domain | Question answered |
| --- | --- |
| `AccountingState` | Which outputs, ADA pots and derived stake does the ledger hold? |
| `CertState` | Which accounts, delegations and registrations exist? |
| `GovState` | Which proposals, votes and protocol parameters govern the ledger? |

Certificate and governance records determine deposit obligations; accounting holds
those funds. The separately held output deposits remain inside `UTxOStore`.

```math
\text{asDeposited}
= \text{certificateObligations}(\text{lsCertState})
+ \text{governanceObligations}(\text{lsGovState})
```

Transaction rules thread `LedgerState` while updating the relevant domain.
The original certificate snapshot remains available when calculating refunds;
processing a certificate does not erase the information needed to account for it.
A phase-2 failure applies collateral effects without ordinary certificate or
governance effects. Existing nested CBOR and JSON ledger formats are preserved at
the serialization boundary; the in-memory model has three sibling states.

The shared modules follow those domains:

```text
Cardano.Ledger.State
├── Accounting              AccountingState and its field lenses
│   ├── InstantStake        Current output stake and its resolution against accounts
│   └── UTxOs               Store access
│       ├── Store
│       ├── IndexedUTxOs
│       ├── Unspent
│       └── Deposit
├── Certificates            EraCertState and registration state
│   ├── Account
│   └── StakePool
├── Governance              EraGov and protocol-parameter transitions
├── Epoch
│   ├── ChainAccount        Treasury and reserves
│   ├── SnapShots
│   ├── PoolDistr
│   └── LeiosCommittee      Consensus committee
└── Stake                   Shared stake value types
```

Era-specific certificate and instant-stake implementations use the same domain
names inside their era packages. Transaction queries (`EraUTxO`, consumed and
produced value, required scripts and witnesses) live in `Cardano.Ledger.UTxO`.

The collection types distinguish output inspection from recorded unspent entries:

| Type | Contents | Scope |
| --- | --- | --- |
| `IndexedTxOs` | `TxIn → Sized TxOut` | Proposed transaction outputs with their supplied sizes. |
| `IndexedUTxOs` | `TxIn → Unspent TxOut` | Recorded output payloads and allocation origins. Pricing resolves the formula from history. |

`allocations store` supplies the complete allocation state of that Store; selections
remain `IndexedUTxOs`. There is no additional `Allocations` wrapper. A body alone
cannot recover historical deposit parameters or establish which outputs remain unspent.

| Module under `Cardano.Ledger.State.Accounting.UTxOs` | Responsibility |
| --- | --- |
| [`Store`](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Store.hs) | Public transaction projection (`projectTx` returning `TxProjected`), construction, record queries and formula activation. |
| [`Store.Internals`](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Store/Internals.hs) | `projectValidTxBody`, `projectInvalidTxBody`, `allocate` and `release`; implementation used by ledger transitions and focused tests. |
| [`IndexedUTxOs`](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/IndexedUTxOs.hs) | Input lookup, selection, filtering, entry traversal and deposit totals. |
| [`Unspent`](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Unspent.hs) | One entry's accepted output and allocation origin; `toTxOut`, historical formula selection, `computeExternalDeposit` and entry codecs. |
| [`Deposit`](../../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Deposit.hs) | Versioned formula arithmetic over `NativeAssetCount`, `DatumBytes` and `ReferenceScriptBytes`; `DepositAmount`, history and half-open formula periods. |

Dijkstra owns output measurement and the migrated-output reserve view:

| Module under `Cardano.Ledger.Dijkstra.UTxOs` | Responsibility |
| --- | --- |
| [`Deposit.Formula`](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/Formula.hs) | Extract the three typed measures from a `TxOut` and call the core `computeDeposit`; return `DepositAmount`. |
| [`Unspent`](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Unspent.hs) | `computeDeposit` and `computeApplicationAssets` select the allocation-time formula and cap a migrated min-ADA reserve at its output ADA. |

The shared Store calls `getDepositTxOut` only for `DepositBackedTxOut`. Min-ADA entries
contribute zero to its external total. Earlier eras have no `DepositBackedTxOut` values and
need no implementation of Dijkstra's pricing rule.

[`Cardano.Ledger.TxOut.IndexedTxOs`](../../../libs/cardano-ledger-core/src/Cardano/Ledger/TxOut/IndexedTxOs.hs)
owns construction, indexing and selection of sized outputs. Each collection has its own
map operations; callers do not unwrap maps for ordinary lookups or selections.

**Queries retain complete entries.** Map operations belong to `IndexedUTxOs`:

```haskell
IndexedUTxOs.lookupUTxO input entries
IndexedUTxOs.restrictToInputs inputs entries
IndexedUTxOs.withoutInputs inputs entries
IndexedUTxOs.filterByTxOut predicate entries
IndexedUTxOs.sumDepositAmounts history entries
```

Selections preserve each entry's output payload and allocation origin.
`extractInputs` returns the remaining and extracted entries in one traversal.
`txOuts` supplies payloads for output-only arithmetic; `mapTxOuts` projects payloads
at external boundaries such as Plutus contexts, diagnostic maps and the formal model.
The block reference-script check reads the scripts on selected input payloads and
outputs proposed earlier in the block. It measures the scripts themselves.

`AccountingState`, `LedgerState`, `EpochState` and `NewEpochState` expose the complete
Store through `CanGetUTxOStore.utxoStoreG` and `CanSetUTxOStore.utxoStoreL`.
`EraUTxO`, validators and transaction annotations consume `IndexedUTxOs` directly.
They retain the original batch entries when validation needs inputs already consumed
by an earlier body. Current ledger state still determines whether an input is spendable.

Wallet queries `getIndexedUTxOs`, `getFilteredIndexedUTxOs` and
`getIndexedUTxOsSubset` return complete entries. Imp tests use `getUTxOStore`,
`getIndexedUTxOs` or `impGetUTxO` for one output.

**Body indexing and Store allocation are separate operations.**

```haskell
outputsTxBody :: EraTxBody era => TxBody l era -> IndexedTxOs era

data TxProjected era = TxProjected
  { updatedStore :: !(UTxOStore era)
  , consumedOutputs :: !(IndexedUTxOs era)
  , producedOutputs :: !(IndexedUTxOs era)
  }

projectTx :: EraTx era => SlotNo -> Tx TopTx era -> UTxOStore era -> TxProjected era

allocate ::
  EraTxOut era =>
  SlotNo -> IndexedTxOs era -> UTxOStore era -> UTxOStore era

activateNewFormula :: SlotNo -> DepositFormula -> UTxOStore era -> UTxOStore era
```

The body builder preserves bounded output-index enumeration and excludes collateral return.
Babbage, Conway and Dijkstra retain the body's original `Sized` values; earlier eras
construct canonical legacy sizes. No deposit formula is selected while inspecting a body.
`producedTxOuts` selects regular outputs or collateral return according to the phase-2 outcome,
without claiming ledger acceptance.

`allocate slot` records `AtSlot slot` when new outputs enter the Dijkstra Store.
Existing inputs retain their allocation origin; history resolves the original
formula for their refund. Migrated entries continue to use the baseline.
The transition is explicit:

```haskell
TxProjected {updatedStore, consumedOutputs, producedOutputs} =
  Store.projectTx slot tx previousStore

updatedInstantStake =
  updateInstantStake consumedOutputs producedOutputs previousInstantStake
```

`projectTx` selects the TopTx's regular or collateral effects. Each internal body
projection returns the same `TxProjected` record: consumed entries come from the
previous Store; produced entries come from the updated Store and exclude retained
colliding references. `updateInstantStake` belongs to `State.Accounting.InstantStake`
and uses these actual changes. The accounting rule installs both results and emits
`TxUTxODiff consumedOutputs producedOutputs`. The result's complete Store is not
included in that event. Its entries preserve the output payload and allocation origin.

`Store.Internals.projectValidTxBody` releases the body's regular inputs and allocates its regular outputs.
It neither validates the body nor traverses nested SubTxs. The ledger selects the
execution path; `Store.Internals.projectInvalidTxBody` releases only collateral inputs
and allocates only the collateral return on phase-2 failure. Initialization and other operations
without a body explicitly import `Store.Internals` to call `allocate` or `release`.

These operations maintain the invariant for a valid Store:

```math
\text{totalDepositAmount}(S)
= \sum_{u\in\text{allocations}(S)} \text{computeExternalDeposit}(\text{depositFormulaHistory}(S),u)
```

The `allocate` primitive preserves an existing entry and its historical deposit
when a proposal uses the same reference. Only new entries increase the cached total.
Releasing an absent input has no effect. Unaffected entries retain their metadata.
For both valid and collateral projections in every era, a retained entry takes
precedence over a proposed output with the same key, preserving the original
map-union behavior. References released by the projection may be allocated again.

**Legacy boundaries retain their formats.**

- Before Dijkstra, `IndexedUTxOs` retains the ordinary payload-map CBOR used by queries.
  `UTxOStore` uses MemPack inputs and output payloads, preserving ledger snapshot bytes
  and credential sharing. Decoding reconstructs canonical min-ADA entries marked
  `AtStoreMigration` with zero external deposits. These bytes contain no Store
  history: ordinary decoding supplies the default V1/4310 baseline; the optional
  `decodeUTxOStoreWithFormula` decoder accepts a different caller-supplied one.
  Neither recovers each output's original creation-era pricing.
- Dijkstra collections encode complete entries as `TxIn → [output, allocatedAt]`.
  The Store encodes `[depositFormulaHistory, cachedTotal, allocationMap]`; history is
  `[initialFormula, formulaChanges]`. Decoding validates change order and the
  external total.
  Its `EncCBOR` instance retains MemPack inputs and output payloads plus explicit metadata.
  Standalone Store encoding now uses this same snapshot format.
- The retired standalone Dijkstra `TxOutMap` payload encoding cannot represent complete
  entries. Its replacement has the complete-entry format. The previous two-field Store
  snapshot is rejected: its history cannot be recovered from individual entries,
  especially when the Store is empty. The former formula-bearing entry format
  is also distinct from the new `AllocatedAt` encoding.
- Before Dijkstra, legacy import builds `AtStoreMigration` entries with
  `IndexedUTxOs.fromMinAdaTxOuts`; Store construction receives either default or
  caller-supplied history. Earlier-era Store translations preserve source history; Conway
  canonical import retains the destination state's supplied history because its
  namespace contains outputs only. The Dijkstra fork initializes its baseline from
  the effective translated protocol parameters, with no dated changes. Future changes
  retain their actual activation slots. `mkUTxOStore history entries` restores complete entries
  with their payloads and allocation origins. No migration
  operation extracts reserve ADA from a min-ADA payload or creates an external credit.

Stake updates still fold output payloads directly. Address inspection and witness verification
remain in `Address` and `Keys.WitVKey`; neither belongs to the indexed collection.

<a id="section-9" name="section-9"></a>

## B. Tag migration

> **Connect historical identifiers to the current domain rules and cases.**
>
> Tags identify requirements; section numbers identify reading order.

Semantic tags follow the invariant’s module path. `N`, `F` and `P` identify nominal, rejection and universal cases; numbering restarts within each group. A property can have an `N` or `F` tag when it exercises only that outcome. Document section numbers describe reading order and are not protocol identifiers.

The old identifiers remain listed here for historical references. Several old rules mixed responsibilities, so their cases can now have different semantic prefixes.

Collateral transaction rules use seven generated contracts. Their applied effects
belong to the UTxO, Store, Fees and Conservation cases. Earlier case anchors remain
aliases at the contract that owns their scenario:

| Earlier collateral cases | Current owner |
| --- | --- |
| Funding nominal cases and P01; Settlement N01/N02 | [Funding N01](transaction-rules.md#ds-collateral-funding-n01) |
| Funding rejection cases | [Funding F01](transaction-rules.md#ds-collateral-funding-f01) |
| Settlement P01; Funding P02 | [Funding P02](transaction-rules.md#ds-collateral-funding-p02) |
| Scope N01; Funding N09 | [Existing Store activity control and explicit assertion gap](transaction-rules.md#ds-collateral-store-activity-control) |
| Other Scope cases; Authorization | [Shared collateral regressions](transaction-rules.md#ds-collateral-existing-rules) |
| Total nominal / rejection cases | [Total N01](transaction-rules.md#ds-collateral-total-n01) / [F01](transaction-rules.md#ds-collateral-total-f01) |
| Native-asset nominal / rejection cases from Conservation or Assets | [Assets N01](transaction-rules.md#ds-collateral-assets-n01) / [F01](transaction-rules.md#ds-collateral-assets-f01) |
| Surplus; earlier Fees cases | [Fees P01](ledger-effects.md#ds-state-fees-p01) / [P02](ledger-effects.md#ds-state-fees-p02) |
| Collateral Conservation N01/P01 | [State Conservation N03](ledger-effects.md#ds-state-conservation-n03) |

Ledger effects is grouped under UTxO, Store, Fees, Conservation and Lifecycle. Earlier case anchors remain beside the contract or scenario that
owns them; retired identifiers are not separate executable assertions:

| Earlier Ledger effects cases | Current owner |
| --- | --- |
| Execution P01, N01, N04 | [UTxO N01](ledger-effects.md#ds-state-utxo-n01) and [N02](ledger-effects.md#ds-state-utxo-n02): ordinary effects and inactive collateral. |
| Execution N02, N03 | [UTxO N03](ledger-effects.md#ds-state-utxo-n03): collateral effects; [N05](ledger-effects.md#ds-state-utxo-n05): overlapping input roles. |
| Execution F01, P02 | [Rejected submissions](ledger-effects.md#ds-state-execution-f01): no applied result; snapshot comparison would retest the submission adapter. |
| Allocations P01–P03, N01–N08 | [Allocations](ledger-effects.md#ds-state-allocations): ordinary/collateral records, historical refunds, zero-priced records and inactive ordinary operations after phase-2 failure. |
| Balance P01–P03, N01–N03; Solvency P01, N02 | [Balance](ledger-effects.md#ds-state-balance): ordinary/collateral transfers and historical releases; balance is the record sum. |
| Solvency N01, F01 | [Retired balance mismatch cases](ledger-effects.md#ds-state-solvency-n01): mismatched cached totals are rejected by checked construction and decoding. |
| Fees P01; Conservation N01 | Existing identities retained under [Fees](ledger-effects.md#ds-state-fees) and [Conservation](ledger-effects.md#ds-state-conservation). |
| Initialization N01–N03 | [Translation N01](ledger-effects.md#ds-state-translation-n01): actual Conway translation, preserving output payloads and existing monetary pots while introducing legacy allocations and zero external deposits. |
| Solvency N03 | [Epoch N01](ledger-effects.md#ds-state-epoch-n01): exact Store preservation through ordinary epochs. |
| Recovery N01 | [Existing binary round trips](ledger-effects.md#ds-state-recovery-n01); post-restoration records and releases belong to [Allocations P03](ledger-effects.md#ds-state-allocations-p03) and [Balance P03](ledger-effects.md#ds-state-balance-p03). |
| Recovery N02 | [Consensus rollback integration gap](ledger-effects.md#ds-state-recovery-n02). |

Declarations groups syntax and contextual obligations under one domain:

| Previous prefix | Current prefix |
| --- | --- |
| `DS-TX-GRAMMAR` | [DS-TX-DECLARATIONS-GRAMMAR](transaction-rules.md#ds-tx-declarations-grammar) |
| `DS-TX-REQUIRED-DECLARATIONS` | [DS-TX-DECLARATIONS-REQUIREMENTS](transaction-rules.md#ds-tx-declarations-requirements) |

Every category and case suffix is preserved. Previous Grammar and Required declarations
anchors remain valid; the new Declarations parent does not add or remove test cases.

The Requirements category and its Store-operation and SubTx-declaration groups use these current prefixes:

| Previous prefix | Current prefix |
| --- | --- |
| `DS-TX-PRESENCE` | [DS-TX-DECLARATIONS-REQUIREMENTS](transaction-rules.md#ds-tx-declarations-requirements) |
| `DS-TX-PRESENCE-OPERATIONS`, `DS-TX-PRESENCE-ACTIVITY` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](transaction-rules.md#ds-tx-declarations-requirements-operations) |
| `DS-TX-PRESENCE-OPERATIONS-ALLOCATION`, `DS-TX-PRESENCE-ACTIVITY-CREATION` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](transaction-rules.md#ds-tx-declarations-requirements-operations-allocation) |
| `DS-TX-PRESENCE-OPERATIONS-RELEASE`, `DS-TX-PRESENCE-ACTIVITY-SPENDING` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE](transaction-rules.md#ds-tx-declarations-requirements-operations-release) |
| `DS-TX-PRESENCE-OPERATIONS-ZERO-NET-CHANGE` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ZERO-NET-CHANGE](transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change) |
| `DS-TX-PRESENCE-ACTIVITY-SCOPE`, `DS-TX-PRESENCE-OPERATIONS-SCOPE` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](transaction-rules.md#ds-tx-declarations-requirements-operations), with cases assigned to Allocation or Release below. |
| `DS-TX-PRESENCE-SUBTX-DECLARATIONS`, `DS-TX-PRESENCE-DEPENDENCY` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations), preserving C01–C05 and every case suffix. |

Every previous `DS-TX-PRESENCE` rule and case anchor still resolves to the corresponding
Requirements section. Case order is unchanged within the new Declarations parent. The former
Scope group anchors open the Operations overview; each old Scope case anchor opens
its migrated case. Both the `ACTIVITY-SCOPE` and `OPERATIONS-SCOPE` prefixes follow
this mapping:

| Previous Scope case | Current case |
| --- | --- |
| `N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N06](transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n06) |
| `N02` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N07](transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n07) |
| `N03` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N08](transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n08) |
| `F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-F07](transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f07) |
| `F02` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-F08](transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f08) |
| `N06` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N09](transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n09) |
| `N04` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N09](transaction-rules.md#ds-tx-declarations-requirements-operations-release-n09) |
| `N05` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N10](transaction-rules.md#ds-tx-declarations-requirements-operations-release-n10) |
| `F03` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-F06](transaction-rules.md#ds-tx-declarations-requirements-operations-release-f06) |

Allocation and release identify gross Store operations; neither implies the
declaration's net sign. The former Scope N06 is now Allocation N09: both bodies
allocate deposits, neither releases one, and both declare exactly. The generated
ledger scenario prices each body's outputs independently and requires acceptance.

| Previous rule | Current responsibilities |
| --- | --- |
| `DS-TX-001` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE](transaction-rules.md#ds-tx-declarations-requirements-operations-release), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](transaction-rules.md#ds-tx-declarations-requirements-operations-allocation), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ZERO-NET-CHANGE](transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](transaction-rules.md#ds-tx-declarations-requirements-operations) |
| `DS-TX-002` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](transaction-rules.md#ds-tx-accounting-net-change-toptx), [DS-TX-ACCOUNTING-ATTRIBUTION](transaction-rules.md#ds-tx-accounting-attribution), [DS-TX-SETTLEMENT-DESIGNATION](transaction-rules.md#ds-tx-settlement-designation) |
| `DS-TX-003` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx), [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](transaction-rules.md#ds-tx-accounting-net-change-toptx) |
| `DS-TX-004` | [DS-TX-ACCOUNTING-BALANCE](transaction-rules.md#ds-tx-accounting-balance) |
| `DS-TX-005` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx), [DS-TX-ACCOUNTING-ATTRIBUTION](transaction-rules.md#ds-tx-accounting-attribution), [DS-TX-SETTLEMENT-OUTPUT-INDEX](transaction-rules.md#ds-tx-settlement-output-index) |
| `DS-TX-006` | [DS-TX-SETTLEMENT-DESIGNATION](transaction-rules.md#ds-tx-settlement-designation) |
| `DS-TX-007` | [DS-TX-ACCOUNTING-BALANCE](transaction-rules.md#ds-tx-accounting-balance), [DS-TX-SETTLEMENT-OUTPUT-INDEX](transaction-rules.md#ds-tx-settlement-output-index), [DS-TX-SETTLEMENT-OUTPUT-COIN](transaction-rules.md#ds-tx-settlement-output-coin), [DS-STATE-UTXO](ledger-effects.md#ds-state-utxo) |
| `DS-TX-008` | [DS-TX-DECLARATIONS-GRAMMAR](transaction-rules.md#ds-tx-declarations-grammar), [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx) |
| `DS-TX-009` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations) |
| `DS-TX-010` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx), [DS-TX-ACCOUNTING-ATTRIBUTION](transaction-rules.md#ds-tx-accounting-attribution), [DS-TX-ACCOUNTING-BALANCE](transaction-rules.md#ds-tx-accounting-balance) |
| `DS-TX-011` | [DS-TX-AUTHORIZATION](transaction-rules.md#ds-tx-authorization) |
| `DS-TX-012` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx), [DS-TX-MINIMUM-COIN](transaction-rules.md#ds-tx-minimum-coin) |
| `DS-TX-APPLICATION-ASSETS` | [DS-TX-MINIMUM-COIN](transaction-rules.md#ds-tx-minimum-coin); case suffixes are unchanged. |
| `DS-COLL-001` | [Shared collateral rules](transaction-rules.md#ds-collateral-existing-rules), [DS-COLLATERAL-FUNDING](transaction-rules.md#ds-collateral-funding), [DS-COLLATERAL-ASSETS](transaction-rules.md#ds-collateral-assets) |
| `DS-COLL-002` | [DS-COLLATERAL-FUNDING](transaction-rules.md#ds-collateral-funding), [DS-STATE-FEES](ledger-effects.md#ds-state-fees), [DS-STATE-CONSERVATION](ledger-effects.md#ds-state-conservation) |
| `DS-COLL-003` | [DS-COLLATERAL-FUNDING](transaction-rules.md#ds-collateral-funding), [DS-COLLATERAL-TOTAL](transaction-rules.md#ds-collateral-total) |
| `DS-COLL-004` | [DS-COLLATERAL-FUNDING](transaction-rules.md#ds-collateral-funding), [DS-STATE-UTXO](ledger-effects.md#ds-state-utxo), [DS-STATE-ALLOCATIONS](ledger-effects.md#ds-state-allocations), [DS-STATE-BALANCE](ledger-effects.md#ds-state-balance) |
| `DS-STORE-001` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx), [DS-STATE-ALLOCATIONS](ledger-effects.md#ds-state-allocations), [DS-STATE-BALANCE](ledger-effects.md#ds-state-balance) |
| `DS-STORE-002` | [DS-PRICING-HISTORY](#ds-pricing-history) |
| `DS-STORE-003` | [DS-PRICING](domain-model.md#ds-pricing), [DS-STATE-ALLOCATIONS](ledger-effects.md#ds-state-allocations) |
| `DS-STORE-004` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](transaction-rules.md#ds-tx-declarations-requirements-operations-allocation), [DS-STATE-ALLOCATIONS](ledger-effects.md#ds-state-allocations), [DS-STATE-TRANSLATION](ledger-effects.md#ds-state-translation) |
| `DS-STORE-005` | [DS-STATE-UTXO](ledger-effects.md#ds-state-utxo), [DS-STATE-ALLOCATIONS](ledger-effects.md#ds-state-allocations), [DS-STATE-RECOVERY](ledger-effects.md#ds-state-recovery) |
| `DS-PLUTUS-001` | [DS-PLUTUS-COMPATIBILITY](#ds-plutus-compatibility) |
| `DS-STAKE-001` | [DS-STATE-CONSERVATION](ledger-effects.md#ds-state-conservation), [DS-STAKE](derived-distributions.md#ds-stake), [DS-VOTING](derived-distributions.md#ds-voting) |

The former Attribution cases are now owned by the rule they establish. Shared
claims are checked once; every previous case anchor still resolves:

| Previous Attribution case | Current case |
| --- | --- |
| `P01`, `N01` | [Accounting Attribution P01](transaction-rules.md#ds-tx-accounting-attribution-p01): signed responsibility, including delegated funding exactly once |
| `P02` | [Accounting Attribution P02](transaction-rules.md#ds-tx-accounting-attribution-p02): signed responsibility shift; [Net change TopTx P02](#ds-tx-accounting-net-change-toptx-p02): unchanged total |
| `N02` | [Net change TopTx P02](#ds-tx-accounting-net-change-toptx-p02): allocation and release delegation preserve the total |
| `N03` | [Settlement Output index N03](transaction-rules.md#ds-tx-settlement-output-index-n03): delegate a final release without SubTx outputs |
| `N04` | [Accounting Attribution N01](transaction-rules.md#ds-tx-accounting-attribution-n01): explicit zero contributes no delegated amount |

Authorization now has one accepted control and its witness-only rejection:

| Previous Authorization case | Current responsibility |
| --- | --- |
| `N01`, `N02` | [Authorization N01](transaction-rules.md#ds-tx-authorization-n01): Bob signs; original funder Alice does not |
| `F01` | [Authorization F01](transaction-rules.md#ds-tx-authorization-f01): Alice cannot replace Bob's required witness |
| `N03` | [Release N09](transaction-rules.md#ds-tx-declarations-requirements-operations-release-n09): existing reference-only declaration case; an attempted release amount is an Accounting concern |

Settlement now names each check directly:

| Previous group | Current group |
| --- | --- |
| `DS-TX-SETTLEMENT-PARTICIPATION` | [Designation](transaction-rules.md#ds-tx-settlement-designation), retaining P01, N01–N08 and F01–F03 |
| `DS-TX-SETTLEMENT-DESTINATION` | [Output index](transaction-rules.md#ds-tx-settlement-output-index), retaining every suffix |
| `DS-TX-SETTLEMENT-COVERAGE` | [Output coin](transaction-rules.md#ds-tx-settlement-output-coin), retaining every suffix |

The intermediate Participation P02/P03/N10 cases now belong to Accounting Attribution
P01/P02/N01. Participation N09 is Output index N03. Their former anchors remain valid.

Accounting groups three responsibilities: Net change validates declared amounts;
Attribution assigns signed contributions; Balance checks ordinary financial
conservation. The following earlier migrations preserve every case suffix and anchor:

| Previous tag | Current tag |
| --- | --- |
| `DS-TX-ACCOUNTING-SUBTX` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx) |
| `DS-TX-ACCOUNTING-TOPTX` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](transaction-rules.md#ds-tx-accounting-net-change-toptx) |
| `DS-TX-CONSERVATION` | [DS-TX-ACCOUNTING-BALANCE](transaction-rules.md#ds-tx-accounting-balance) |

Net change identifies the declaration's scope directly. It replaces the former
Exactness domain; existing links remain valid through retained anchors:

| Previous tag | Current tag |
| --- | --- |
| `DS-TX-EXACTNESS` | [DS-TX-ACCOUNTING-NET-CHANGE](transaction-rules.md#ds-tx-accounting-net-change) |
| `DS-TX-EXACTNESS-SUBTX` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx) |
| `DS-TX-EXACTNESS-TOPTX` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](transaction-rules.md#ds-tx-accounting-net-change-toptx) |
| `DS-TX-EXACTNESS-CONTRIBUTION` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](transaction-rules.md#ds-tx-accounting-net-change-subtx) |
| `DS-TX-EXACTNESS-NETTING` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](transaction-rules.md#ds-tx-accounting-net-change-toptx) |
| `DS-TX-EXACTNESS-CONTRIBUTION-N02` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX-N02](#ds-tx-accounting-net-change-toptx-n02) — derive TopTx's own change from its declared total |

Within SubTx, former Contribution N03–N10 become N02–N09. Within TopTx, former
Netting N02–N07 become N03–N08. P/F suffixes and both former N01 identities keep their
numbers under the new scopes. All former anchors remain valid.

The accounting observation formerly registered as `DS-TX-GRAMMAR-N01` now lives at
[DS-TX-ACCOUNTING-ATTRIBUTION-N01](transaction-rules.md#ds-tx-accounting-attribution-n01). Its old anchor redirects to that case;
the primitive boundary check formerly registered as `DS-TX-GRAMMAR-N02` now belongs
to ledger-core's `StrictlyPositiveCoinSpec`. Grammar nominal identifiers therefore
begin at N03; neither retired identity is reassigned.
The former combined invalid-amount check keeps [F01](transaction-rules.md#ds-tx-declarations-grammar-f01) for TopTx
zero. Its remaining TopTx assertions use [F12](transaction-rules.md#ds-tx-declarations-grammar-f12) for negative
amounts and [F13](transaction-rules.md#ds-tx-declarations-grammar-f13) for overflowing amounts.
Its SubTx assertions are split into [F07](transaction-rules.md#ds-tx-declarations-grammar-f07) for zero,
[F08](transaction-rules.md#ds-tx-declarations-grammar-f08) for negative amounts and [F09](transaction-rules.md#ds-tx-declarations-grammar-f09) for
overflowing amounts; F07 retains the zero case from the former combined SubTx check.
The former combined SubTx target check keeps [F05](transaction-rules.md#ds-tx-declarations-grammar-f05) for invalid
structure. Its index range assertions now have separate tags:
[F10](transaction-rules.md#ds-tx-declarations-grammar-f10) for negative indices and [F11](transaction-rules.md#ds-tx-declarations-grammar-f11) for
indices above 65535. Similarly, the former combined TopTx settlement check keeps
[F04](transaction-rules.md#ds-tx-declarations-grammar-f04) for invalid structure; [F14](transaction-rules.md#ds-tx-declarations-grammar-f14) covers
negative indices and [F15](transaction-rules.md#ds-tx-declarations-grammar-f15) covers indices above 65535.
These checks concern decoding; output existence remains under
[DS-TX-SETTLEMENT-OUTPUT-INDEX](transaction-rules.md#ds-tx-settlement-output-index).

The previously individually tagged declaration-dependency cases map as follows:

| Previous case | Current case |
| --- | --- |
| `DS-TX-009-C01-P01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C01-P01](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c01-p01) |
| `DS-TX-009-C02-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-N01](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-n01) |
| `DS-TX-009-C02-N02` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-N02](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-n02) |
| `DS-TX-009-C02-N03` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-N03](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-n03) |
| `DS-TX-009-C02-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-F01](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-f01) |
| `DS-TX-009-C03-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C03-N01](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c03-n01) |
| `DS-TX-009-C03-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C03-F01](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c03-f01) |
| `DS-TX-009-C04-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C04-N01](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c04-n01) |
| `DS-TX-009-C04-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C04-F01](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c04-f01) |
| `DS-TX-009-C05-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C05-N01](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c05-n01) |
| `DS-TX-009-C05-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C05-F01](transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c05-f01) |
| `DS-TX-009-C06-P01` | [Technical fixture property](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/DepositStoreFixtureSpec.hs), outside the business specification |

<a id="section-10" name="section-10"></a>

## C. Code references

> **Locate the implementation entry points for each responsibility.**
>
> Declaration forms $`\longrightarrow`$ domain APIs · Validation $`\longrightarrow`$ ledger rules · Pricing $`\longrightarrow`$ asset count and payload lengths.

The executable suite mirrors the rule chapters:

| Chapter | Test modules under `DepositStore/` |
| --- | --- |
| Transaction rules | [`TransactionRulesSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRulesSpec.hs) composes `TransactionRules/Tx/` and `TransactionRules/Collateral/`. |
| Ledger effects | [`LedgerEffectsSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffectsSpec.hs) composes `UTxOSpec`, `Store/`, `FeesSpec`, `ConservationSpec` and `Lifecycle/`. |

[`DeclarationsSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/DeclarationsSpec.hs)
composes [`GrammarSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/GrammarSpec.hs)
and [`RequirementsSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/RequirementsSpec.hs).
Grammar checks valid representations; Requirements checks which bodies must declare.
Within `TransactionRules/Tx/Declarations/Requirements/Operations/`,
[`AllocationSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs)
and [`ReleaseSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs)
cover each gross operation and identify which operations belong to each body.
[`OperationsSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/OperationsSpec.hs)
checks the shared declaration requirement independently of deposit price: generated
Deposit-backed input and output forms still require declarations when their priced
amounts are zero. Accepted controls and one-field omissions exercise both body
levels, ordinary success and real phase-2 failure.
[`ZeroNetChangeSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs)
checks equal positive allocations and releases independently for each active
TopTx or SubTx, including mixed active/inactive children and proposals on the
phase-2 failure path. Its six nominal and eight rejection properties require
explicit zero at each active body and the parent declaration required by children.
[`SubTxDeclarationsSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs)
checks the TopTx field required by any explicit SubTx declaration, including
zero and offsetting contributions from two SubTxs.

[`AccountingSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AccountingSpec.hs)
composes [`NetChangeSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChangeSpec.hs)
and [`BalanceSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs).
Net change checks each SubTx's own amount and TopTx's complete transaction total.
Balance checks the complete transaction's financial conservation when phase 2 is valid.

[`CollateralSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/CollateralSpec.hs)
composes `FundingSpec`, `TotalSpec` and `AssetsSpec`. Existing input resolution,
witnesses, fee percentages and total-field checks are linked in
[Existing collateral rules](transaction-rules.md#ds-collateral-existing-rules).
The Ledger effects modules follow their state observations:

```text
LedgerEffects/
├── UTxOSpec.hs
├── Store/
│   ├── AllocationsSpec.hs
│   └── BalanceSpec.hs
├── FeesSpec.hs
├── ConservationSpec.hs
└── Lifecycle/
    ├── TranslationSpec.hs
    └── EpochSpec.hs
```

[`UTxOSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs)
owns the exact UTxO transition selected by the accepted outcome.
[`AllocationsSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs)
owns retained records; [`BalanceSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs)
checks the change in the sum of records. [`FeesSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs)
checks ordinary and collateral fee credits and unchanged treasury. The map and
Store assertions formerly embedded there now belong to UTxO and Store specs. [`ConservationSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs)
compares independent actual-pot sums with the production total including donations.

[`TranslationSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/TranslationSpec.hs)
corresponds to [full-state translation](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Translation.hs#L103),
[UTxO/Store translation](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Translation.hs#L217)
and [min-ADA output upgrade](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxOut.hs#L216).
[`EpochSpec`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs)
observes the Store preserved by [ordinary epoch processing](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Epoch.hs#L218).
Existing codec coverage and the rollback integration gap are linked under
[Lifecycle](ledger-effects.md#ds-state-recovery).

`Core.Specs` provides the domain vocabulary and fixtures shared by the executable
specifications. Domain-named modules keep related generators, builders and
predicates together:

```text
Core/
├── Specs/
│   ├── Tx/
│   │   ├── Declaration.hs
│   │   ├── Declaration/
│   │   │   ├── TopTx.hs
│   │   │   └── SubTx.hs
│   │   ├── Operations.hs
│   │   ├── Output.hs
│   │   ├── Release.hs
│   │   ├── TopTx.hs
│   │   ├── TopTx/
│   │   │   ├── Allocation.hs
│   │   │   └── Release.hs
│   │   └── SubTx.hs
│   ├── LedgerEffects.hs
│   ├── LedgerEffects/
│   │   ├── ADA.hs
│   │   └── UTxO.hs
│   ├── Lifecycle.hs
│   ├── Collateral.hs
│   ├── OutputIndex.hs
│   ├── StrictlyPositiveCoin.hs
│   └── Assertions.hs
├── Encoding.hs
├── Encoding/
│   ├── CBOR.hs
│   └── JSON.hs
├── Submission.hs
└── Submission/
    ├── Collateral.hs
    ├── Allocation.hs
    ├── Declaration.hs
    ├── Operations.hs
    ├── Output.hs
    └── Release.hs
```

| Module family | Responsibility |
| --- | --- |
| `Specs.Tx.Declaration` | Describe ordered TopTx/SubTx declarations; generate combinations, construct bodies, and provide the independent dependency expectation, isolated-validator adapter and expected failure. |
| `Specs.Tx.Declaration.TopTx` / `SubTx` | Provide each body's declaration forms, generators, raw decoder fixtures and declaration predicates. |
| `Specs.Tx.Operations` | Generate independent input/output forms per body; identify required declarations from each body's actual resolved inputs and own outputs, without consulting amounts, declarations or production presence validators. |
| `Specs.Tx.Output` | Describe and construct own-output arrangements for the specifications. |
| `Specs.Tx.Release` | Generate release sources and collateral-only scenarios; identify proposed ordinary inputs and outputs while excluding references and collateral. |
| `Specs.Tx.TopTx` | Generate standalone output arrangements, read recorded releases, calculate proposed allocations and express TopTx declarations. |
| `Specs.Tx.TopTx.Allocation` | Generate standalone allocations with at least one deposit-backed output; calculate their allocation and attach the supplied declaration. |
| `Specs.Tx.TopTx.Release` | Keep TopTx and its optional SubTxs with their funded ledger context; calculate the complete transaction's net deposit and apply the supplied declarations. |
| `Specs.Tx.SubTx` | Generate release and equal-allocation-and-release scenarios; expose each child's `allocatedDeposits`, recorded release and `depositBackedInputs` in transaction order, and identify declarations by source input. |
| `Specs.OutputIndex` / `StrictlyPositiveCoin` | Provide shared index generators and checked amount fixtures. |
| `Specs.LedgerEffects` | Fund and sign valid ordinary, delegated or phase-2-invalid scenarios; preserve real noncanonical body bytes and restore UTxO-state snapshots. Expected state changes remain in the specs. |
| `Specs.LedgerEffects.ADA` | Sum actual monetary pots independently of the production ADA-total projection. |
| `Specs.LedgerEffects.UTxO` | Prepare reference-only and overlapping ordinary/collateral input roles while preserving valid signatures and script pointers. |
| `Specs.Lifecycle` | Generate Conway translation states and funded Store scenarios for actual epoch transitions. |
| `Specs.Assertions` | Apply a supplied expectation to one or more observations. |
| `Encoding` | Observe CBOR and JSON behavior together, with a separate implementation for each format. |
| `Submission` | Fund and prepare ledger transactions, preserve fixtures through fixup, submit and check ledger outcomes. Its declaration and output modules register the scenario rows. |
| `Submission.Allocation` | Fund application outputs, declarations and fees from min-ADA inputs; preserve the allocation proposal while signing it or removing its declaration. |
| `Submission.Operations` | Fund distinct sources at zero deposit price, verify their real output forms and Store records, and return an undeclared proposal preserving each body's ownership and application ADA. |
| `Submission.Release` | Fund generated release or reference sources, preserve proposals while signing, and prepare collateral-only scenarios with actual script success or failure. |
| `Submission.Collateral` | Prepare transactions with collateral whose deposits and failure-path transfers can be observed by the specifications. |

These fixture entry points fund each generated scenario, then pass a proposal
with **no declarations** to the case:

| Fixture entry point | What the case receives |
| --- | --- |
| `fundOperations` | A parent and zero to four children with independent source/output forms, each owning a distinct funded input. Deposit-backed sources have a recorded zero deposit; min-ADA sources have no record. |
| `forAllReferenceOnlyStoreTx` | A standalone TopTx referencing real positive Store allocations, with no ordinary Store operations. |
| `forAllStandaloneReleaseTx` | A standalone TopTx with its funded ledger context. |
| `forAllSingleSubTxReleaseTx` | A TopTx with one SubTx, its funded context and the source's recorded positive deposit. |
| `forAllSubTxReleaseTx` | A TopTx with several SubTxs and their funded ledger context. |
| `forAllStandaloneZeroNetChangeTx` | A funded standalone TopTx with independently checked equal positive allocations and recorded releases. |
| `forAllSubTxZeroNetChangeTx` | A funded TopTx and its SubTxs, with independently checked equal positive allocations and recorded releases for every active body, and zero amounts for inactive bodies. |

`TopTx.netDeposit` sums the signed backing change of both output forms across
**TopTx and all its SubTxs**. `TopTx.releasedDeposits` returns their total external
deposit release. `SubTx.releasedDeposits` returns one amount per child in transaction order, including
zero for children consuming only min-ADA sources.

`ReleaseSpec` constructs `Declarations` directly: N01 chooses allocation, explicit zero
or release from the signed net amount; N02 names its release and output 0 directly.
The SubTx cases show each child's local release and TopTx's total together. N06
explicitly leaves children with no Store operations undeclared. These choices stay
visible in the tests. `TopTx.addDeclaration` applies the supplied TopTx declaration
and exactly one per child, preserving the rest of the proposal.

`buildAndSignTx` prepares and signs every body while preserving the supplied
declarations, inputs and outputs. `buildAndSignPhase2InvalidTx` also supplies a
failing script and valid collateral, preserving the ordinary declarations and
settlements. `submitTx` submits that signed transaction
without further fixup and returns the ledger outcome. `isAccepted`
checks acceptance. `isRejectedWith` requires the specified failure among the
ledger's rejection reasons; additional failures are allowed. Both assertions report
the actual outcome when it does not match the expectation.

```haskell
buildAndSignTx declaredTx >>= submitTx >>= isAccepted

submitTx txWithoutTopTxDeclaration
  >>= isRejectedWith (MissingUTxODepositDeclaration @DijkstraEra)
```

The executable specs retain the rule, generated inputs and expected outcome.
Production domain types remain in the ledger modules. A pure helper may move there
when it acquires a protocol responsibility; generators and independent test
expectations remain specification support.

- [TopTx declaration domain API](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/TopTx.hs)
- [SubTx declaration domain API](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/SubTx.hs)
- [Transaction fields, operations and lenses](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxBody.hs)
- [Output variants and shared interfaces](../../../libs/cardano-ledger-core/src/Cardano/Ledger/TxOut.hs)
- [Dijkstra output representations](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxOut.hs)
- [Dijkstra active-formula minimum-coin validation](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/DepositStore/MinimumCoin.hs)
- [Earlier-era byte-based minimum-coin rule](../../../eras/babbage/impl/src/Cardano/Ledger/Babbage/TxOut.hs)
- [Serialized size measurement for proposed outputs](../../../libs/cardano-ledger-binary/src/Cardano/Ledger/Binary/Decoding/Sized.hs)
- [TopTx UTXO rule](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Utxo.hs)
- [SubTx UTXO rule](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/SubUtxo.hs)

<a id="declaration-api" name="declaration-api"></a>

### C.1 Declaration API

The API uses `UTxODeposit` for the domain term **UTxO capacity deposit**. Domain code
uses two qualified modules:

```haskell
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx as SubTx
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
| TopTx settlement designation | `NoTopTxSettlement` or `TopTxSettlementOutput index` |
| SubTx contribution declaration | `SubTx.SubTxUTxODepositDeclaration` |
| No SubTx declaration | `SubTx.NoUTxODepositDeclaration` |
| SubTx net allocation, accounted locally | `SubTx.DeclaresNetUTxODepositAllocation amount` |
| SubTx net allocation, funding delegated to TopTx | `SubTx.RequestsUTxODepositFromTopTx amount` |
| SubTx net release and settlement | `SubTx.DeclaresNetUTxODepositRelease amount target` |
| SubTx explicit zero | `SubTx.DeclaresZeroNetUTxODeposit` |
| SubTx settlement destination | `SubTxSettlementOutput index` or `DelegateToTopTx` |

Nonzero amounts use the abstract `StrictlyPositiveCoin` type from
[`Cardano.Ledger.StrictlyPositiveCoin`](../../../libs/cardano-ledger-core/src/Cardano/Ledger/StrictlyPositiveCoin.hs).
`mkStrictlyPositiveCoin :: Coin -> Maybe StrictlyPositiveCoin` accepts exactly
$`1 \le \mathit{amount} \le 2^{64}-1`$ lovelace; `unStrictlyPositiveCoin` returns the
underlying `Coin`. The constructor stays private, and CBOR/JSON encode the amount
as a number.

<a id="transaction-body-fields" name="transaction-body-fields"></a>

### C.2 Transaction body fields

DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS applies separately to each top-level transaction body and each sub-transaction
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
specify their contributions and where they are accounted for, as defined in DS-TX-ACCOUNTING-NET-CHANGE-TOPTX.

In body-generic tables, `NoUTxODepositDeclaration` means the qualified pattern for
that body's level. `hasDeclaration(body)` is false for that pattern and true for every
explicit declaration, including `DeclaresZeroNetUTxODeposit`.

For DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS, an output means the `TxOut` inside a `Sized` element of the body's own
output sequence. The cached size does not affect the check. A TopTx's own outputs do not
include its SubTx outputs. Spent outputs are obtained by resolving the body's own
spending inputs against the applicable UTxO. Reference inputs do not consume outputs or
release UTxO capacity deposits. Collateral inputs and collateral return have separate rules
under the [shared collateral rules](transaction-rules.md#ds-collateral-existing-rules) and [Funding](transaction-rules.md#ds-collateral-funding).

<a id="declaration-encoding" name="declaration-encoding"></a>

### C.3 Declaration encoding

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
tags and encoded bytes are unchanged. `DepositBackedTxOut` remains the output variant
name.

Checked construction and CBOR/JSON decoding reject zero, negative and out-of-range
operation amounts.

The SubTx explicit zero encodes as CBOR `[3]` and JSON `{"kind":"noChange"}`. Existing SubTx
tags remain `0` for a net allocation, `1` for a net release and `2` for a funding
request. Previously accepted zero-amount operation encodings now fail decoding; an
explicit zero must use the explicit-zero form.

TopTx uses the same distinction between absence and explicit zero. Its zero form
encodes as CBOR `[2]`; allocation and release retain tags `0` and `1`. A release
carries a settlement choice: `[0]` for `NoTopTxSettlement`, or `[1, index]` for
`TopTxSettlementOutput index`. The complete release encoding is `[1, amount, settlement]`.
JSON uses a `settlement` object with `kind` `noTopTxSettlement` or
`topTxSettlementOutput` and its `outputIndex`.

[Grammar](transaction-rules.md#ds-tx-declarations-grammar) owns declaration forms and declaration decoder rejection,
including enforcement of `StrictlyPositiveCoin` amounts. The type's construction
and scalar codecs belong to ledger-core's `StrictlyPositiveCoinSpec`.
The [declaration codec specification](../../../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Binary/Golden.hs)
retains independent exact-byte/JSON goldens, historical field omission and malformed
payload checks through both transaction-body decoders.
These representation checks establish which forms can be expressed. Requirements,
exactness and conservation determine whether an expressed declaration is valid in its transaction.

[`Declaration/TopTx.hs`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Specs/Tx/Declaration/TopTx.hs)
and [`Declaration/SubTx.hs`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Specs/Tx/Declaration/SubTx.hs)
provide typed declarations, paired bodies and independent raw decoder inputs for
the same declaration domain. `allDeclarationsWithAmount` and
`allDeclarationInputsWithAmount` retain every operation form and both index bounds
while varying a valid interior index. `declarationsAtBounds` also retains both
amount bounds and explicit zero. `absentAndExplicitZero` generates paired bodies
differing only in declaration presence; SubTx also generates positive funding
requests. Structural input generators cover every defect category in each draw.

These modules also construct raw local destinations for the generated index
properties and their shrunk counterexamples.

[`OutputIndex.hs`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Specs/OutputIndex.hs)
provides shared negative and overflowing index generators. The specs preserve
those ranges while shrinking. [`Encoding.hs`](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Encoding.hs)
combines CBOR and JSON observations; each format has its own implementation.

<a id="net-change-test-cases" name="net-change-test-cases"></a>

## D. Net-change test cases

These cases check the [net-change rules](transaction-rules.md#ds-tx-accounting-net-change) against the amounts declared by each SubTx and by the TopTx for the batch. Case numbers follow §2.1.2.1 and link to the corresponding executable tests.

<a id="subtx-net-change-test-cases" name="subtx-net-change-test-cases"></a>

### D.1 SubTx net-change cases

[§2.1.2.1.1 SubTx net-change rule](transaction-rules.md#ds-tx-accounting-net-change-subtx)

<details>
<summary>Find a SubTx case by identifier or name</summary>

- [P01 — Each SubTx declares its own exact change](#ds-tx-accounting-net-change-subtx-p01)
- [N01 — Exact own change, with any allocation and release combination](#ds-tx-accounting-net-change-subtx-n01)
- [F01 — Net allocation understated by one lovelace](#ds-tx-accounting-net-change-subtx-f01)
- [F02 — Net allocation overstated by one lovelace](#ds-tx-accounting-net-change-subtx-f02)
- [F03 — Net release understated by one lovelace](#ds-tx-accounting-net-change-subtx-f03)
- [F04 — Net release overstated by one lovelace](#ds-tx-accounting-net-change-subtx-f04)
- [F05 — Opposing SubTx errors cancel in the total](#ds-tx-accounting-net-change-subtx-f05)
- [N02 — Equal own allocations and releases, explicit zero](#ds-tx-accounting-net-change-subtx-n02)
- [F06 — Explicit zero cannot replace a required allocation](#ds-tx-accounting-net-change-subtx-f06)
- [N03 — Exact allocation requested from TopTx](#ds-tx-accounting-net-change-subtx-n03)
- [N04 — Exact release delegated to TopTx](#ds-tx-accounting-net-change-subtx-n04)
- [N05 — Released deposits, only min-ADA outputs](#ds-tx-accounting-net-change-subtx-n05)
- [F07 — Explicit zero cannot replace a required release](#ds-tx-accounting-net-change-subtx-f07)
- [N06 — Another body offsets the SubTx release](#ds-tx-accounting-net-change-subtx-n06)
- [N07 — An output without application assets still requires a deposit](#ds-tx-accounting-net-change-subtx-n07)
- [N08 — A translated min-ADA input funds an exact allocation](#ds-tx-accounting-net-change-subtx-n08)
- [F08 — A translated min-ADA input does not excuse an inexact allocation](#ds-tx-accounting-net-change-subtx-f08)
- [F09 — Unspent outputs cannot increase a SubTx release](#ds-tx-accounting-net-change-subtx-f09)
- [F10 — A release cannot replace a required allocation](#ds-tx-accounting-net-change-subtx-f10)
- [F11 — An allocation cannot replace a required release](#ds-tx-accounting-net-change-subtx-f11)
- [N09 — Exact SubTx declarations when phase 2 fails](#ds-tx-accounting-net-change-subtx-n09)
- [F12 — An inexact SubTx declaration still fails before the collateral outcome](#ds-tx-accounting-net-change-subtx-f12)

</details>

<a id="ds-tx-exactness-contribution-p01" name="ds-tx-exactness-contribution-p01"></a>
<a id="ds-tx-exactness-subtx-p01" name="ds-tx-exactness-subtx-p01"></a>
<a id="ds-tx-accounting-subtx-p01" name="ds-tx-accounting-subtx-p01"></a>
<a id="ds-tx-accounting-net-change-subtx-p01" name="ds-tx-accounting-net-change-subtx-p01"></a>

**2.1.2.1.1.1 [P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L90) - Each SubTx declares its own exact change**

```math
\begin{aligned}
&\mathrm{subTxNetChangeValid}\iff \\
&\forall\,\mathit{subTx}\in\mathrm{declaredSubTxs}(\mathit{topTx}): \\
&\qquad\mathrm{declaredNetDeposit}(\mathit{subTx})=\mathrm{ownNetDeposit}(\mathit{subTx})
\end{aligned}
```

Compare the isolated SubTx exactness result with independent input records and output prices; include exact and inexact declarations.

<a id="ds-tx-exactness-contribution-n01" name="ds-tx-exactness-contribution-n01"></a>
<a id="ds-tx-exactness-subtx-n01" name="ds-tx-exactness-subtx-n01"></a>
<a id="ds-tx-accounting-subtx-n01" name="ds-tx-accounting-subtx-n01"></a>
<a id="ds-tx-accounting-net-change-subtx-n01" name="ds-tx-accounting-net-change-subtx-n01"></a>

**2.1.2.1.1.2 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L126) - Exact own change, with any allocation and release combination**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{allocatedDeposits}(\mathit{subTx}) - \mathrm{releasedDeposits}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

Exercise positive allocation, negative release and explicit zero with local accounting; N03/N04 cover the delegated forms.

<a id="ds-tx-exactness-contribution-f01" name="ds-tx-exactness-contribution-f01"></a>
<a id="ds-tx-exactness-subtx-f01" name="ds-tx-exactness-subtx-f01"></a>
<a id="ds-tx-accounting-subtx-f01" name="ds-tx-accounting-subtx-f01"></a>
<a id="ds-tx-accounting-net-change-subtx-f01" name="ds-tx-accounting-net-change-subtx-f01"></a>

**2.1.2.1.1.3 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L148) - Net allocation understated by one lovelace**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 1 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

The required allocation exceeds one lovelace so the mutated declaration remains a positive allocation.

<a id="ds-tx-exactness-contribution-f02" name="ds-tx-exactness-contribution-f02"></a>
<a id="ds-tx-exactness-subtx-f02" name="ds-tx-exactness-subtx-f02"></a>
<a id="ds-tx-accounting-subtx-f02" name="ds-tx-accounting-subtx-f02"></a>
<a id="ds-tx-accounting-net-change-subtx-f02" name="ds-tx-accounting-net-change-subtx-f02"></a>

**2.1.2.1.1.4 [F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L166) - Net allocation overstated by one lovelace**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) + 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Keep the increased amount representable; this checks exactness rather than decoder overflow.

<a id="ds-tx-exactness-contribution-f03" name="ds-tx-exactness-contribution-f03"></a>
<a id="ds-tx-exactness-subtx-f03" name="ds-tx-exactness-subtx-f03"></a>
<a id="ds-tx-accounting-subtx-f03" name="ds-tx-accounting-subtx-f03"></a>
<a id="ds-tx-accounting-net-change-subtx-f03" name="ds-tx-accounting-net-change-subtx-f03"></a>

**2.1.2.1.1.5 [F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L184) - Net release understated by one lovelace**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < -1 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) + 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Reducing the positive release magnitude increases its signed declaration; the required release exceeds one lovelace.

<a id="ds-tx-exactness-contribution-f04" name="ds-tx-exactness-contribution-f04"></a>
<a id="ds-tx-exactness-subtx-f04" name="ds-tx-exactness-subtx-f04"></a>
<a id="ds-tx-accounting-subtx-f04" name="ds-tx-accounting-subtx-f04"></a>
<a id="ds-tx-accounting-net-change-subtx-f04" name="ds-tx-accounting-net-change-subtx-f04"></a>

**2.1.2.1.1.6 [F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L202) - Net release overstated by one lovelace**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Increasing the positive release magnitude decreases its signed declaration; keep the magnitude representable.

<a id="ds-tx-exactness-contribution-f05" name="ds-tx-exactness-contribution-f05"></a>
<a id="ds-tx-exactness-subtx-f05" name="ds-tx-exactness-subtx-f05"></a>
<a id="ds-tx-accounting-subtx-f05" name="ds-tx-accounting-subtx-f05"></a>
<a id="ds-tx-accounting-net-change-subtx-f05" name="ds-tx-accounting-net-change-subtx-f05"></a>

**2.1.2.1.1.7 [F05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L220) - Opposing SubTx errors cancel in the total**

```math
\begin{aligned}
&\mathit{firstSubTx} \ne \mathit{secondSubTx} \\
&\land \mathrm{declarationError}(\mathit{firstSubTx}) = -\mathrm{declarationError}(\mathit{secondSubTx}) \ne 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Both distinct SubTxs are in the transaction. Their errors cancel, but require a SubTx exactness failure.

<a id="ds-tx-exactness-contribution-n03" name="ds-tx-exactness-contribution-n03"></a>
<a id="ds-tx-exactness-subtx-n02" name="ds-tx-exactness-subtx-n02"></a>
<a id="ds-tx-accounting-subtx-n02" name="ds-tx-accounting-subtx-n02"></a>
<a id="ds-tx-accounting-net-change-subtx-n02" name="ds-tx-accounting-net-change-subtx-n02"></a>

**2.1.2.1.1.8 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L239) - Equal own allocations and releases, explicit zero**

```math
\begin{aligned}
&\mathrm{allocatedDeposits}(\mathit{subTx}) = \mathrm{releasedDeposits}(\mathit{subTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

Use an explicit-zero declaration, including both zero operations and nonzero allocations equal to releases.

<a id="ds-tx-exactness-contribution-f06" name="ds-tx-exactness-contribution-f06"></a>
<a id="ds-tx-exactness-subtx-f06" name="ds-tx-exactness-subtx-f06"></a>
<a id="ds-tx-accounting-subtx-f06" name="ds-tx-accounting-subtx-f06"></a>
<a id="ds-tx-accounting-net-change-subtx-f06" name="ds-tx-accounting-net-change-subtx-f06"></a>

**2.1.2.1.1.9 [F06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L248) - Explicit zero cannot replace a required allocation**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

The field is present as explicit zero; its amount is incorrect.

<a id="ds-tx-exactness-contribution-n04" name="ds-tx-exactness-contribution-n04"></a>
<a id="ds-tx-exactness-subtx-n03" name="ds-tx-exactness-subtx-n03"></a>
<a id="ds-tx-accounting-subtx-n03" name="ds-tx-accounting-subtx-n03"></a>
<a id="ds-tx-accounting-net-change-subtx-n03" name="ds-tx-accounting-net-change-subtx-n03"></a>

**2.1.2.1.1.10 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L266) - Exact allocation requested from TopTx**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{delegatesAllocation}(\mathit{subTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

`RequestsUTxODepositFromTopTx` carries the requesting SubTx own net allocation, while TopTx declares the transaction total.

<a id="ds-tx-exactness-contribution-n05" name="ds-tx-exactness-contribution-n05"></a>
<a id="ds-tx-exactness-subtx-n04" name="ds-tx-exactness-subtx-n04"></a>
<a id="ds-tx-accounting-subtx-n04" name="ds-tx-accounting-subtx-n04"></a>
<a id="ds-tx-accounting-net-change-subtx-n04" name="ds-tx-accounting-net-change-subtx-n04"></a>

**2.1.2.1.1.11 [N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L278) - Exact release delegated to TopTx**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{delegatesRelease}(\mathit{subTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

The release targets `DelegateToTopTx`; its magnitude remains exactly the originating SubTx own net release.

<a id="ds-tx-exactness-contribution-n06" name="ds-tx-exactness-contribution-n06"></a>
<a id="ds-tx-exactness-subtx-n05" name="ds-tx-exactness-subtx-n05"></a>
<a id="ds-tx-accounting-subtx-n05" name="ds-tx-accounting-subtx-n05"></a>
<a id="ds-tx-accounting-net-change-subtx-n05" name="ds-tx-accounting-net-change-subtx-n05"></a>

**2.1.2.1.1.12 [N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L290) - Released deposits, only min-ADA outputs**

```math
\begin{aligned}
&\mathrm{releasedDeposits}(\mathit{subTx}) > 0 \\
&\land \mathrm{depositBackedOutputs}(\mathit{subTx}) = \varnothing \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = -\mathrm{releasedDeposits}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

The fixture pairs its min-ADA outputs with inputs carrying equal embedded backing.
The signed release therefore equals the historical external deposits consumed.

<a id="ds-tx-exactness-contribution-f07" name="ds-tx-exactness-contribution-f07"></a>
<a id="ds-tx-exactness-subtx-f07" name="ds-tx-exactness-subtx-f07"></a>
<a id="ds-tx-accounting-subtx-f07" name="ds-tx-accounting-subtx-f07"></a>
<a id="ds-tx-accounting-net-change-subtx-f07" name="ds-tx-accounting-net-change-subtx-f07"></a>

**2.1.2.1.1.13 [F07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L302) - Explicit zero cannot replace a required release**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

The field is present as explicit zero; a negative own change still requires a release declaration.

<a id="ds-tx-exactness-contribution-n07" name="ds-tx-exactness-contribution-n07"></a>
<a id="ds-tx-exactness-subtx-n06" name="ds-tx-exactness-subtx-n06"></a>
<a id="ds-tx-accounting-subtx-n06" name="ds-tx-accounting-subtx-n06"></a>
<a id="ds-tx-accounting-net-change-subtx-n06" name="ds-tx-accounting-net-change-subtx-n06"></a>

**2.1.2.1.1.14 [N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L320) - Another body offsets the SubTx release**

```math
\begin{aligned}
&\mathit{otherBody} \ne \mathit{subTx} \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) < 0 < \mathrm{ownNetDeposit}(\mathit{otherBody}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

The other body is TopTx or another SubTx. Cover partial, equal and greater offsets; none changes this SubTx own release.

<a id="ds-tx-exactness-contribution-n08" name="ds-tx-exactness-contribution-n08"></a>
<a id="ds-tx-exactness-subtx-n07" name="ds-tx-exactness-subtx-n07"></a>
<a id="ds-tx-accounting-subtx-n07" name="ds-tx-accounting-subtx-n07"></a>
<a id="ds-tx-accounting-net-change-subtx-n07" name="ds-tx-accounting-net-change-subtx-n07"></a>

**2.1.2.1.1.15 [N07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L342) - An output without application assets still requires a deposit**

```math
\begin{aligned}
&\mathrm{depositBackedOutputs}(\mathit{subTx}) = \{\mathit{output}\} \\
&\land \mathrm{applicationAssets}(\mathit{output}) = \varnothing \\
&\land \mathrm{releasedDeposits}(\mathit{subTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{allocatedDeposits}(\mathit{subTx}) > 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

The formula charges its base even when the application value is empty. Use a positive rate and declare the exact allocation.

<a id="ds-tx-exactness-contribution-n09" name="ds-tx-exactness-contribution-n09"></a>
<a id="ds-tx-exactness-subtx-n08" name="ds-tx-exactness-subtx-n08"></a>
<a id="ds-tx-accounting-subtx-n08" name="ds-tx-accounting-subtx-n08"></a>
<a id="ds-tx-accounting-net-change-subtx-n08" name="ds-tx-accounting-net-change-subtx-n08"></a>

**2.1.2.1.1.16 [N08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L354) - A translated min-ADA input funds an exact allocation**

```math
\begin{aligned}
&\mathrm{ordinaryInputs}(\mathit{subTx}) = \{\mathit{translatedImplicitInput}\} \\
&\land \mathrm{depositBackedOutputs}(\mathit{subTx}) \ne \varnothing \\
&\land \mathrm{releasedDeposits}(\mathit{subTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{allocatedDeposits}(\mathit{subTx}) > 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

The translated input funds the external obligations. Its credited min-ADA
reserve cancels the reserve of the fixture's min-ADA change output.

<a id="ds-tx-exactness-contribution-f08" name="ds-tx-exactness-contribution-f08"></a>
<a id="ds-tx-exactness-subtx-f08" name="ds-tx-exactness-subtx-f08"></a>
<a id="ds-tx-accounting-subtx-f08" name="ds-tx-accounting-subtx-f08"></a>
<a id="ds-tx-accounting-net-change-subtx-f08" name="ds-tx-accounting-net-change-subtx-f08"></a>

**2.1.2.1.1.17 [F08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L366) - A translated min-ADA input does not excuse an inexact allocation**

```math
\begin{aligned}
&\mathrm{ordinaryInputs}(\mathit{subTx}) = \{\mathit{translatedImplicitInput}\} \\
&\land \mathrm{depositBackedOutputs}(\mathit{subTx}) \ne \varnothing \\
&\land \mathrm{releasedDeposits}(\mathit{subTx}) = 0 \\
&\land \mathrm{allocatedDeposits}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) \ne \mathrm{allocatedDeposits}(\mathit{subTx}) \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Use the N08 allocation scenario, changing only the positive SubTx declaration to a different representable amount.

<a id="ds-tx-exactness-contribution-f09" name="ds-tx-exactness-contribution-f09"></a>
<a id="ds-tx-exactness-subtx-f09" name="ds-tx-exactness-subtx-f09"></a>
<a id="ds-tx-accounting-subtx-f09" name="ds-tx-accounting-subtx-f09"></a>
<a id="ds-tx-accounting-net-change-subtx-f09" name="ds-tx-accounting-net-change-subtx-f09"></a>

**2.1.2.1.1.18 [F09](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L385) - Unspent outputs cannot increase a SubTx release**

```math
\begin{aligned}
&\mathit{unspentInputs}\cap\mathit{consumedInputs}=\varnothing \\
&\land 0 < \mathit{unrelatedRelease} \le \mathrm{recordedDeposits}(\mathit{unspentInputs}) \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) \le 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - \mathit{unrelatedRelease} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Fund one to four separate Deposit-backed outputs and leave them unspent. Their
recorded deposits are not available to this SubTx: increasing the declared release
by part of that amount fails exactness. The unchanged declaration remains accepted.

<a id="ds-tx-exactness-contribution-f10" name="ds-tx-exactness-contribution-f10"></a>
<a id="ds-tx-exactness-subtx-f10" name="ds-tx-exactness-subtx-f10"></a>
<a id="ds-tx-accounting-subtx-f10" name="ds-tx-accounting-subtx-f10"></a>
<a id="ds-tx-accounting-net-change-subtx-f10" name="ds-tx-accounting-net-change-subtx-f10"></a>

**2.1.2.1.1.19 [F10](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L410) - A release cannot replace a required allocation**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) < 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Exercise valid local and delegated release forms; their sign contradicts the independently required own change.

<a id="ds-tx-exactness-contribution-f11" name="ds-tx-exactness-contribution-f11"></a>
<a id="ds-tx-exactness-subtx-f11" name="ds-tx-exactness-subtx-f11"></a>
<a id="ds-tx-accounting-subtx-f11" name="ds-tx-accounting-subtx-f11"></a>
<a id="ds-tx-accounting-net-change-subtx-f11" name="ds-tx-accounting-net-change-subtx-f11"></a>

**2.1.2.1.1.20 [F11](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L429) - An allocation cannot replace a required release**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) > 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Exercise a local allocation and a funding request to TopTx; neither can represent the required own release.

<a id="ds-tx-exactness-contribution-n10" name="ds-tx-exactness-contribution-n10"></a>
<a id="ds-tx-exactness-subtx-n09" name="ds-tx-exactness-subtx-n09"></a>
<a id="ds-tx-accounting-subtx-n09" name="ds-tx-accounting-subtx-n09"></a>
<a id="ds-tx-accounting-net-change-subtx-n09" name="ds-tx-accounting-net-change-subtx-n09"></a>

**2.1.2.1.1.21 [N09](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L449) - Exact SubTx declarations when phase 2 fails**

```math
\begin{aligned}
&\mathrm{declaredSubTxs}(\mathit{topTx}) \ne \varnothing \\
&\land (\forall \mathit{subTx} \in \mathrm{declaredSubTxs}(\mathit{topTx}): \\
&\qquad\mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx})) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{accepted}
\end{aligned}
```

Use a real failing script with otherwise valid declarations and transaction terms. Acceptance follows the collateral outcome, without ordinary Store effects.

<a id="ds-tx-exactness-contribution-f12" name="ds-tx-exactness-contribution-f12"></a>
<a id="ds-tx-exactness-subtx-f12" name="ds-tx-exactness-subtx-f12"></a>
<a id="ds-tx-accounting-subtx-f12" name="ds-tx-accounting-subtx-f12"></a>
<a id="ds-tx-accounting-net-change-subtx-f12" name="ds-tx-accounting-net-change-subtx-f12"></a>

**2.1.2.1.1.22 [F12](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L471) - An inexact SubTx declaration still fails before the collateral outcome**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{subTx}) \ne \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Start from N09 failing-script controls and mutate a SubTx amount. The independently established script failure does not waive the earlier exactness check.

<a id="toptx-net-change-test-cases" name="toptx-net-change-test-cases"></a>

### D.2 TopTx net-change cases

[§2.1.2.1.2 TopTx net-change rule](transaction-rules.md#ds-tx-accounting-net-change-toptx)

<details>
<summary>Find a TopTx case by identifier or name</summary>

- [P01 — TopTx declares the exact transaction total](#ds-tx-accounting-net-change-toptx-p01)
- [P02 — Delegation preserves the transaction total](#ds-tx-accounting-net-change-toptx-p02)
- [N01 — TopTx and SubTxs contribute to the total](#ds-tx-accounting-net-change-toptx-n01)
- [N02 — TopTx's own change is derived from its total](#ds-tx-accounting-net-change-toptx-n02)
- [N03 — 5 ADA allocated, 3 ADA released](#ds-tx-accounting-net-change-toptx-n03)
- [N04 — 3 ADA allocated, 5 ADA released](#ds-tx-accounting-net-change-toptx-n04)
- [N05 — Nonzero body changes produce a zero total](#ds-tx-accounting-net-change-toptx-n05)
- [F01 — Standalone TopTx understates its net allocation by one lovelace](#ds-tx-accounting-net-change-toptx-f01)
- [F02 — Standalone TopTx overstates its net allocation by one lovelace](#ds-tx-accounting-net-change-toptx-f02)
- [F03 — Standalone TopTx understates its net release by one lovelace](#ds-tx-accounting-net-change-toptx-f03)
- [F04 — Standalone TopTx overstates its net release by one lovelace](#ds-tx-accounting-net-change-toptx-f04)
- [F05 — Explicit zero cannot replace a nonzero total](#ds-tx-accounting-net-change-toptx-f05)
- [F06 — A nonzero declaration cannot replace a zero total](#ds-tx-accounting-net-change-toptx-f06)
- [F07 — TopTx declares the opposite direction](#ds-tx-accounting-net-change-toptx-f07)
- [N06 — TopTx releases while SubTxs allocate](#ds-tx-accounting-net-change-toptx-n06)
- [N07 — TopTx allocates while SubTxs release](#ds-tx-accounting-net-change-toptx-n07)
- [N08 — An exact total remains valid when phase 2 fails](#ds-tx-accounting-net-change-toptx-n08)
- [F08 — An inexact total is rejected even when phase 2 fails](#ds-tx-accounting-net-change-toptx-f08)
- [F09 — A delegated change belongs in the total exactly once](#ds-tx-accounting-net-change-toptx-f09)

</details>

<a id="ds-tx-exactness-netting-p01" name="ds-tx-exactness-netting-p01"></a>
<a id="ds-tx-exactness-toptx-p01" name="ds-tx-exactness-toptx-p01"></a>
<a id="ds-tx-accounting-toptx-p01" name="ds-tx-accounting-toptx-p01"></a>
<a id="ds-tx-accounting-net-change-toptx-p01" name="ds-tx-accounting-net-change-toptx-p01"></a>

**2.1.2.1.2.1 [P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L72) - TopTx declares the exact transaction total**

```math
\begin{aligned}
&\mathrm{topTxNetChangeValid}(\mathit{topTx}) \\
&\iff \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx})
\end{aligned}
```

Compare the isolated TopTx validator with independently computed deposits; this equivalence does not assert complete ledger acceptance.

<a id="ds-tx-attribution-n02" name="ds-tx-attribution-n02"></a>
<a id="ds-tx-accounting-net-change-toptx-p02" name="ds-tx-accounting-net-change-toptx-p02"></a>

**2.1.2.1.2.2 [P02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L90) - Delegation preserves the transaction total**

```math
\begin{aligned}
&\text{sameStoreOperations(localTx, delegatedTx)} \\
&\implies\text{requiredNetDeposit(localTx)}=\text{requiredNetDeposit(delegatedTx)} \\
&\qquad\land\text{Accepted(localTx)}\land\text{Accepted(delegatedTx)}
\end{aligned}
```

For both an allocating child and a releasing child, build two valid transactions
with the same originating Store operations: one accounts locally, the other delegates
to TopTx. The independent expected total comes from priced outputs and recorded input
deposits. Both transactions declare that total exactly once and are accepted.

| Change in the SubTx declaration | Effect on the transaction total |
| --- | --- |
| Local allocation → funding requested from TopTx | None |
| Local release → release delegated to TopTx | None |

Each version is funded and signed separately, with settlement selectors and output
coverage appropriate to its accounting mode. Acceptance does not mean those fields
can remain unchanged. [Attribution P02](transaction-rules.md#ds-tx-accounting-attribution-p02) checks
which body assumes the signed contribution.

<a id="ds-tx-exactness-netting-n01" name="ds-tx-exactness-netting-n01"></a>
<a id="ds-tx-exactness-toptx-n01" name="ds-tx-exactness-toptx-n01"></a>
<a id="ds-tx-accounting-toptx-n01" name="ds-tx-accounting-toptx-n01"></a>
<a id="ds-tx-accounting-net-change-toptx-n01" name="ds-tx-accounting-net-change-toptx-n01"></a>

**2.1.2.1.2.3 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L122) - TopTx and SubTxs contribute to the total**

```math
\begin{aligned}
&(\exists \mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{subTx}) \ne 0) \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

Cover both zero and nonzero TopTx own changes alongside nonzero child changes. The declared total includes every own change exactly once.

<a id="ds-tx-exactness-contribution-n02" name="ds-tx-exactness-contribution-n02"></a>
<a id="ds-tx-exactness-toptx-n02" name="ds-tx-exactness-toptx-n02"></a>
<a id="ds-tx-accounting-toptx-n02" name="ds-tx-accounting-toptx-n02"></a>
<a id="ds-tx-accounting-net-change-toptx-n02" name="ds-tx-accounting-net-change-toptx-n02"></a>

**2.1.2.1.2.4 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L135) - TopTx's own change is derived from its total**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\implies \\
&\mathrm{declaredNetDeposit}(\mathit{topTx}) \\
&\quad-\sum_{\mathit{subTx}\in\mathrm{declaredSubTxs}(\mathit{topTx})}
\mathrm{declaredNetDeposit}(\mathit{subTx}) \\
&\qquad=\mathrm{ownNetDeposit}(\mathit{topTx})
\end{aligned}
```

In this fixture every undeclared child has zero net embedded backing. Subtracting
all present child declarations, including delegated operations, therefore recovers
the parent's own backing change.

<a id="ds-tx-exactness-netting-n02" name="ds-tx-exactness-netting-n02"></a>
<a id="ds-tx-exactness-toptx-n03" name="ds-tx-exactness-toptx-n03"></a>
<a id="ds-tx-accounting-toptx-n03" name="ds-tx-accounting-toptx-n03"></a>
<a id="ds-tx-accounting-net-change-toptx-n03" name="ds-tx-accounting-net-change-toptx-n03"></a>

**2.1.2.1.2.5 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L148) - 5 ADA allocated, 3 ADA released**

```math
\begin{aligned}
&\sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{allocatedDeposits}(\mathit{body}) = 5 \,\mathrm{ADA} \\
&\land \sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{releasedDeposits}(\mathit{body}) = 3 \,\mathrm{ADA} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 2 \,\mathrm{ADA} \\
&\implies \mathrm{accepted}
\end{aligned}
```

Both sums cover TopTx and all SubTxs; the transaction requires a net allocation of 2 ADA.

<a id="ds-tx-exactness-netting-n03" name="ds-tx-exactness-netting-n03"></a>
<a id="ds-tx-exactness-toptx-n04" name="ds-tx-exactness-toptx-n04"></a>
<a id="ds-tx-accounting-toptx-n04" name="ds-tx-accounting-toptx-n04"></a>
<a id="ds-tx-accounting-net-change-toptx-n04" name="ds-tx-accounting-net-change-toptx-n04"></a>

**2.1.2.1.2.6 [N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L159) - 3 ADA allocated, 5 ADA released**

```math
\begin{aligned}
&\sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{allocatedDeposits}(\mathit{body}) = 3 \,\mathrm{ADA} \\
&\land \sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{releasedDeposits}(\mathit{body}) = 5 \,\mathrm{ADA} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = -2 \,\mathrm{ADA} \\
&\implies \mathrm{accepted}
\end{aligned}
```

Both sums cover TopTx and all SubTxs; the transaction releases 2 ADA net.

<a id="ds-tx-exactness-netting-n04" name="ds-tx-exactness-netting-n04"></a>
<a id="ds-tx-exactness-toptx-n05" name="ds-tx-exactness-toptx-n05"></a>
<a id="ds-tx-accounting-toptx-n05" name="ds-tx-accounting-toptx-n05"></a>
<a id="ds-tx-accounting-net-change-toptx-n05" name="ds-tx-accounting-net-change-toptx-n05"></a>

**2.1.2.1.2.7 [N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L171) - Nonzero body changes produce a zero total**

```math
\begin{aligned}
&(\exists \mathit{body} \in \mathrm{bodies}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{body}) \ne 0) \\
&\land \mathrm{transactionNetDeposit}(\mathit{topTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

Allocating and releasing bodies offset each other. TopTx still supplies an explicit zero declaration.

<a id="ds-tx-exactness-netting-f01" name="ds-tx-exactness-netting-f01"></a>
<a id="ds-tx-exactness-toptx-f01" name="ds-tx-exactness-toptx-f01"></a>
<a id="ds-tx-accounting-toptx-f01" name="ds-tx-accounting-toptx-f01"></a>
<a id="ds-tx-accounting-net-change-toptx-f01" name="ds-tx-accounting-net-change-toptx-f01"></a>

**2.1.2.1.2.8 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L181) - Standalone TopTx understates its net allocation by one lovelace**

```math
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{transactionNetDeposit}(\mathit{topTx}) > 1 \,\mathrm{lovelace} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) - 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Create one more deposit-backed output than is consumed. Start from a valid control and alter only the signed declaration.

<a id="ds-tx-exactness-netting-f02" name="ds-tx-exactness-netting-f02"></a>
<a id="ds-tx-exactness-toptx-f02" name="ds-tx-exactness-toptx-f02"></a>
<a id="ds-tx-accounting-toptx-f02" name="ds-tx-accounting-toptx-f02"></a>
<a id="ds-tx-accounting-net-change-toptx-f02" name="ds-tx-accounting-net-change-toptx-f02"></a>

**2.1.2.1.2.9 [F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L193) - Standalone TopTx overstates its net allocation by one lovelace**

```math
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{transactionNetDeposit}(\mathit{topTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) + 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Use the same net-allocation generator and increase only the declaration by one lovelace.

<a id="ds-tx-exactness-netting-f03" name="ds-tx-exactness-netting-f03"></a>
<a id="ds-tx-exactness-toptx-f03" name="ds-tx-exactness-toptx-f03"></a>
<a id="ds-tx-accounting-toptx-f03" name="ds-tx-accounting-toptx-f03"></a>
<a id="ds-tx-accounting-net-change-toptx-f03" name="ds-tx-accounting-net-change-toptx-f03"></a>

**2.1.2.1.2.10 [F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L206) - Standalone TopTx understates its net release by one lovelace**

```math
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{allocatedDeposits}(\mathit{topTx}) = 0 \\
&\land \mathrm{releasedDeposits}(\mathit{topTx}) > 1 \,\mathrm{lovelace} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) + 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Only min-ADA outputs are created. Adding one to the negative declaration reduces the release magnitude.

<a id="ds-tx-exactness-netting-f04" name="ds-tx-exactness-netting-f04"></a>
<a id="ds-tx-exactness-toptx-f04" name="ds-tx-exactness-toptx-f04"></a>
<a id="ds-tx-accounting-toptx-f04" name="ds-tx-accounting-toptx-f04"></a>
<a id="ds-tx-accounting-net-change-toptx-f04" name="ds-tx-accounting-net-change-toptx-f04"></a>

**2.1.2.1.2.11 [F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L219) - Standalone TopTx overstates its net release by one lovelace**

```math
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{allocatedDeposits}(\mathit{topTx}) = 0 \\
&\land \mathrm{releasedDeposits}(\mathit{topTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) - 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Only min-ADA outputs are created. Subtracting one from the negative declaration increases the release magnitude.

<a id="ds-tx-exactness-netting-f05" name="ds-tx-exactness-netting-f05"></a>
<a id="ds-tx-exactness-toptx-f05" name="ds-tx-exactness-toptx-f05"></a>
<a id="ds-tx-accounting-toptx-f05" name="ds-tx-accounting-toptx-f05"></a>
<a id="ds-tx-accounting-net-change-toptx-f05" name="ds-tx-accounting-net-change-toptx-f05"></a>

**2.1.2.1.2.12 [F05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L231) - Explicit zero cannot replace a nonzero total**

```math
\begin{aligned}
&\mathrm{transactionNetDeposit}(\mathit{topTx}) \ne 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Cover both a required net allocation and a required net release.

<a id="ds-tx-exactness-netting-f06" name="ds-tx-exactness-netting-f06"></a>
<a id="ds-tx-exactness-toptx-f06" name="ds-tx-exactness-toptx-f06"></a>
<a id="ds-tx-accounting-toptx-f06" name="ds-tx-accounting-toptx-f06"></a>
<a id="ds-tx-accounting-net-change-toptx-f06" name="ds-tx-accounting-net-change-toptx-f06"></a>

**2.1.2.1.2.13 [F06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L247) - A nonzero declaration cannot replace a zero total**

```math
\begin{aligned}
&\mathrm{transactionNetDeposit}(\mathit{topTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) \ne 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Cover both an allocation declaration and a release declaration when the transaction total is zero.

<a id="ds-tx-exactness-netting-f07" name="ds-tx-exactness-netting-f07"></a>
<a id="ds-tx-exactness-toptx-f07" name="ds-tx-exactness-toptx-f07"></a>
<a id="ds-tx-accounting-toptx-f07" name="ds-tx-accounting-toptx-f07"></a>
<a id="ds-tx-accounting-net-change-toptx-f07" name="ds-tx-accounting-net-change-toptx-f07"></a>

**2.1.2.1.2.14 [F07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L262) - TopTx declares the opposite direction**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) \times \mathrm{transactionNetDeposit}(\mathit{topTx}) < 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

A required allocation cannot be declared as a release, or a required release as an allocation.

<a id="ds-tx-exactness-netting-n05" name="ds-tx-exactness-netting-n05"></a>
<a id="ds-tx-exactness-toptx-n06" name="ds-tx-exactness-toptx-n06"></a>
<a id="ds-tx-accounting-toptx-n06" name="ds-tx-accounting-toptx-n06"></a>
<a id="ds-tx-accounting-net-change-toptx-n06" name="ds-tx-accounting-net-change-toptx-n06"></a>

**2.1.2.1.2.15 [N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L281) - TopTx releases while SubTxs allocate**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{topTx}) < 0 \\
&\land (\forall \mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{subTx}) \ge 0) \\
&\land \sum_{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx})} \mathrm{ownNetDeposit}(\mathit{subTx}) = -\mathrm{ownNetDeposit}(\mathit{topTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

The child allocations exactly offset the parent release. TopTx declares the transaction total, not its own negative change.

<a id="ds-tx-exactness-netting-n06" name="ds-tx-exactness-netting-n06"></a>
<a id="ds-tx-exactness-toptx-n07" name="ds-tx-exactness-toptx-n07"></a>
<a id="ds-tx-accounting-toptx-n07" name="ds-tx-accounting-toptx-n07"></a>
<a id="ds-tx-accounting-net-change-toptx-n07" name="ds-tx-accounting-net-change-toptx-n07"></a>

**2.1.2.1.2.16 [N07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L291) - TopTx allocates while SubTxs release**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{topTx}) > 0 \\
&\land (\forall \mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{subTx}) \le 0) \\
&\land \sum_{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx})} \mathrm{ownNetDeposit}(\mathit{subTx}) = -\mathrm{ownNetDeposit}(\mathit{topTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

The child releases exactly offset the parent allocation. TopTx declares the transaction total, not its own positive change.

<a id="ds-tx-exactness-netting-n07" name="ds-tx-exactness-netting-n07"></a>
<a id="ds-tx-exactness-toptx-n08" name="ds-tx-exactness-toptx-n08"></a>
<a id="ds-tx-accounting-toptx-n08" name="ds-tx-accounting-toptx-n08"></a>
<a id="ds-tx-accounting-net-change-toptx-n08" name="ds-tx-accounting-net-change-toptx-n08"></a>

**2.1.2.1.2.17 [N08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L301) - An exact total remains valid when phase 2 fails**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{accepted}
\end{aligned}
```

The failing script matches the declared outcome. Net change still uses proposed ordinary deposits; collateral execution is a separate rule.

<a id="ds-tx-exactness-netting-f08" name="ds-tx-exactness-netting-f08"></a>
<a id="ds-tx-exactness-toptx-f08" name="ds-tx-exactness-toptx-f08"></a>
<a id="ds-tx-accounting-toptx-f08" name="ds-tx-accounting-toptx-f08"></a>
<a id="ds-tx-accounting-net-change-toptx-f08" name="ds-tx-accounting-net-change-toptx-f08"></a>

**2.1.2.1.2.18 [F08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L313) - An inexact total is rejected even when phase 2 fails**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) \ne \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

A failing script does not waive deposit exactness. The script matches the declared outcome; rejection must include the TopTx exactness failure.

<a id="ds-tx-exactness-netting-f09" name="ds-tx-exactness-netting-f09"></a>
<a id="ds-tx-exactness-toptx-f09" name="ds-tx-exactness-toptx-f09"></a>
<a id="ds-tx-accounting-toptx-f09" name="ds-tx-accounting-toptx-f09"></a>
<a id="ds-tx-accounting-net-change-toptx-f09" name="ds-tx-accounting-net-change-toptx-f09"></a>

**2.1.2.1.2.19 [F09](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L330) - A delegated change belongs in the total exactly once**

```math
\begin{aligned}
&\mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}) \\
&\land \mathrm{delegated}(\mathit{subTx}) \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) \ne 0 \\
&\land\mathrm{declaredNetDeposit}(\mathit{topTx})\in\{ \\
&\qquad\mathrm{transactionNetDeposit}(\mathit{topTx})-\mathrm{ownNetDeposit}(\mathit{subTx}), \\
&\qquad\mathrm{transactionNetDeposit}(\mathit{topTx})+\mathrm{ownNetDeposit}(\mathit{subTx})\} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Omitting or adding a second copy of a delegated child change makes the total inexact; delegation changes responsibility, not the counted amount.
