# Dijkstra DepositStore verification record

**Updated:** 13 October 2026

**Spending presence baseline:** `8ac3c67f2`, with the working-tree changes verified below.

**Coherence revision baseline:** `f06c329e3`, with the working-tree changes verified below.

**Earlier structural baseline:** `1dd45a7a2`; the earlier results retain their original scope.

**Retained historical evidence:** recorded 9 October 2026 at code checkpoint `c8760684f`.

This record separates implementation progress and executed-test evidence from the
[DepositStore business specification](dijkstra-deposit-store-rules.md). Current rule
references use semantic tags matching the executable hierarchy. Numeric tags below
identify historical runs only; their original observations and dates remain distinct
from the new structural verification.

## Current implementation status

The [executable outline](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStoreSpec.hs)
registers **242 business examples: 68 implemented checks and 174 deliberate `False`
placeholders**. The implemented checks comprise 21 Grammar, 38 Presence, four Exactness
and five Collateral examples. This inventory adds six Spending properties to the previous
complete run's 236 examples; the complete suite has **not** been rerun since that addition.
The latest targeted Spending run passed all 13 examples with no failures or pending cases.
The earlier complete run passed all 62 then-implemented checks; each of its 174 failures
matched a deliberate placeholder.

Production state now retains a Store balance and the exact allocation for each live
store-backed `TxIn`. Ordinary validation checks per-body contributions, the batch net
total and release destinations. Successful execution updates allocations once for the
complete transaction. Collateral execution derives its own allocation, release and fee
settlement. Store ADA is included once in the ledger total.

The current suite contains Transaction rules and Ledger effects only. Pricing, Stake
and Voting tests remain deferred. Grammar has 21 codec checks; the reusable positive
amount type has five independent ledger-core checks. One technical fixture property
remains outside the business specification. The old model-only spending fixture checks
have been replaced by real ledger submissions.

| Semantic responsibility and executable spec | Current implementation or verification |
| --- | --- |
| [DS-PRICING](dijkstra-deposit-store-rules.md#ds-pricing) | Pricing tests are deferred; the rules and seven examples remain documented. |
| [DS-TX-GRAMMAR](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/GrammarSpec.hs) | Twenty-one declaration checks are implemented in separate TopTx and SubTx modules: typed amount integration, absent versus zero, legal forms and malformed payloads. Both levels have separate zero, negative and overflowing amount cases, generated structural inputs, and properties for generated negative or overflowing release indices. The former zero-delegation accounting case belongs to Attribution N04 and remains a placeholder. |
| [DS-TX-PRESENCE-ACTIVITY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/ActivitySpec.hs) | The combined creation-or-spending invariant remains a placeholder; the implemented creation slice is separated below. |
| [DS-TX-PRESENCE-ACTIVITY-CREATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs) | Nine examples have implemented checks. The translated-input missing-declaration example remains a placeholder. |
| [DS-TX-PRESENCE-ACTIVITY-SPENDING](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs) | All 13 examples pass using real funded transactions. N01 generates all output forms; N02 specializes to implicit-only outputs. N05–N08 and F04/F05 add batches of two to five SubTxs, mixed active and inactive children, TopTx's own release, and both phase-2 outcomes. Acceptance observes recorded allocations, the Store balance and complete UTxO changes. Each omitted child declaration is tested separately; rejection preserves the complete ledger state and the unchanged valid control is then accepted. |
| [DS-TX-PRESENCE-ACTIVITY-SCOPE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs) | Five creation-scope examples have implemented checks. Four complete scope and ownership examples remain placeholders. |
| [DS-TX-PRESENCE-DEPENDENCY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs) | All 11 protocol examples have implemented checks. Fixture cardinality is verified separately under test infrastructure. |
| [DS-TX-EXACTNESS-CONTRIBUTION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs) | Exact per-body contributions, final releases, delegated contribution amounts and rejection of unrelated surplus releases remain placeholders. |
| [DS-TX-EXACTNESS-NETTING](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs) | F01–F04 submit generated standalone transactions with declarations one lovelace below or above the exact allocation/release. Other batch-netting examples remain placeholders. |
| [DS-TX-ATTRIBUTION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs) | Local and delegated responsibility checks remain placeholders, including the observed zero-accounting case migrated from Grammar N01. |
| [DS-TX-CONSERVATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs) | Production conservation includes the complete declared net transfer once. The dedicated conservation examples remain placeholders; Spending exercises actual funding and releases. |
| [DS-TX-AUTHORIZATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs) | Existing spending authorization applies; Store release integration examples remain placeholders. |
| [DS-TX-SETTLEMENT-PARTICIPATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs) | Production validation derives TopTx participation from the batch total and local SubTx contributions. Dedicated participation examples remain placeholders. |
| [DS-TX-SETTLEMENT-DESTINATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs) | Settlement index and owning-body checks remain placeholders. |
| [DS-TX-SETTLEMENT-COVERAGE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs) | Agreed destination coin bounds remain placeholders. The stronger settlement guarantee is still open. |
| [DS-TX-APPLICATION-ASSETS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs) | Store-backed outputs bypass implicit minimum-coin checks; the retained output-content examples remain placeholders. Exact deposit enforcement is tracked separately. |
| [DS-COLLATERAL-SCOPE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ScopeSpec.hs) | Collateral trigger examples remain placeholders. |
| [DS-COLLATERAL-AUTHORIZATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AuthorizationSpec.hs) | Preservation of collateral key-control checks remains a placeholder. |
| [DS-COLLATERAL-FUNDING](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs) | N04, F02, F03 and F05 submit real collateral transactions: additional return deposit funding, insufficient remaining coins, excluded released surplus, and a one-lovelace shortfall below a rounded-up minimum. Other examples remain placeholders. |
| [DS-COLLATERAL-SURPLUS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/SurplusSpec.hs) | N01 submits a real phase-2-invalid transaction and checks released surplus reaches fees, treasury is unchanged, and ordinary effects do not execute. P01/P02 remain placeholders. |
| [DS-COLLATERAL-TOTAL](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs) | Supplied total-collateral exactness examples remain placeholders. |
| [DS-COLLATERAL-SETTLEMENT](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/SettlementSpec.hs) | Derived collateral Store settlement examples remain placeholders. |
| [DS-COLLATERAL-CONSERVATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ConservationSpec.hs) | Collateral ADA and native-asset conservation examples remain placeholders. |
| [DS-STATE-EXECUTION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ExecutionSpec.hs) | Ordinary, accepted phase-2-failure and rejection effects remain placeholders. |
| [DS-STATE-ALLOCATIONS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs) | Production state records allocations by live output reference. Spending observes their creation, removal and preservation. The dedicated allocation examples remain placeholders. |
| [DS-STATE-BALANCE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/BalanceSpec.hs) | Ordinary and collateral execution update the Store balance. Spending and collateral tests observe these effects; dedicated balance examples remain placeholders. |
| [DS-STATE-SOLVENCY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/SolvencySpec.hs) | Production validation checks prospective solvency on both ordinary and collateral paths. Dedicated solvency and epoch examples remain placeholders. |
| [DS-STATE-CONSERVATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs) | The Store balance is included once in the ledger ADA total. The dedicated conservation property remains a placeholder. |
| [DS-STATE-INITIALIZATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/InitializationSpec.hs) | Conway translation initializes the Store empty. Dedicated initialization and pot-preservation examples remain placeholders. |
| [DS-STATE-RECOVERY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/RecoverySpec.hs) | Store and Dijkstra snapshot serialization retain balance and records; earlier-era snapshot encoding is preserved. Dedicated recovery examples remain placeholders. |
| [DS-STAKE](dijkstra-deposit-store-rules.md#ds-stake) | Stake tests are deferred; the rules and eight examples remain documented. |
| [DS-VOTING](dijkstra-deposit-store-rules.md#ds-voting) | Voting tests are deferred; the rule and one example remain documented. |

Historical pricing and parameter-change handling (`DS-PRICING-HISTORY`), Plutus context
projection, and the unresolved stronger settlement guarantee remain deferred. An agreed
rule awaiting an executable ledger check is distinct from a business question whose
semantics are still open. Representation and codec checks do not establish enforcement
of deposit accounting.

## Latest Spending verification on 13 October 2026

**Result:** 13 examples passed, zero failures. Elapsed time: **1.7767 seconds**;
CPU time: **2.5868 seconds**, excluding compilation. N01, N02 and the six new multi-SubTx properties each
passed **100 generated cases**.

All case identifiers below use the `DS-TX-PRESENCE-ACTIVITY-SPENDING-` prefix and follow
[SpendingSpec's registration order](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs).
The rules document uses concise human-readable headings; traceability follows the case
identifiers, reading order and source links, rather than literal equality with test titles.

| Case | Verified behavior | Generated cases | Reported duration |
| --- | --- | ---: | ---: |
| N01 | Standalone TopTx consumes recorded deposits and declares the exact net change across all output forms. | 100 | 226 ms |
| N02 | Standalone TopTx creates only implicit outputs and declares the full release. | 100 | 95 ms |
| N03 | One SubTx settles its release locally while TopTx declares the total. | — | 1 ms |
| F01 | TopTx's missing declaration is rejected without changing ledger state. | — | Not printed |
| F02 | A spending SubTx's missing declaration is rejected despite TopTx's declaration. | — | Not printed |
| N04 | Real phase-2 failure settles collateral while preserving ordinary inputs and Store allocations. | — | 3 ms |
| F03 | A missing spending declaration is rejected before any phase-2-failure effects can apply. | — | 3 ms |
| N05 | Several spending SubTxs declare their local releases; TopTx declares their exact sum. | 100 | 143 ms |
| F04 | Each child position is tested with only its declaration removed, followed by acceptance of the original control. | 100 | 350 ms |
| N06 | Spending children declare their releases; children with only implicit inputs omit their declarations. | 100 | 141 ms |
| N07 | TopTx and its children settle their own releases; TopTx declares the combined total once. | 100 | 152 ms |
| N08 | Several correctly declared spending SubTxs survive real phase-2 failure with collateral-only effects. | 100 | 212 ms |
| F05 | Each child position still requires its declaration on the phase-2-invalid path; the original control is accepted. | 100 | 443 ms |

The new generators produce two to five SubTxs with distinct funded inputs, including
repeated application amounts. N06 includes both Store-active and inactive children;
N07 adds TopTx's own positive recorded deposit. The new ordinary outputs are all implicit.
Preparation checks preserve child count, order, input ownership and declarations.

Successful ordinary submissions compare the complete UTxO and Store with the expected
consumption and releases, including preservation of unrelated allocations. N08 compares
the complete UTxO with collateral consumption and return only, checks the fee increase,
and requires an unchanged Store. F04/F05 remove each child's declaration from the same
valid transaction, preserve its siblings' and parent's declarations, and check unchanged
ledger state after every rejection before submitting that original valid transaction.

Only Spending was rerun for this extension. The current **242 / 68 / 174** inventory
means total examples / implemented checks / intentional placeholders; it is not a new
complete-suite result. Earlier build, regression and codec evidence below retains its
original scope.

Local evidence: `/private/tmp/ds-multi-spending-tests.log`. Durations are the values
printed by the runner; it did not print individual durations for F01 or F02.

To reproduce this run with individual timings, from the repository root after building:

```sh
dijkstra_test_binary="$(cabal --config-file=/private/tmp/ds-structure-cabal.config list-bin cardano-ledger-dijkstra:test:tests --offline)"
"$dijkstra_test_binary" \
  --match DS-TX-PRESENCE-ACTIVITY-SPENDING \
  --seed 739231514 --format=specdoc --times --print-cpu-time --no-color
```

The complete outline was enumerated with `--dry-run`: **242 registered examples**.
This checks registration without running their assertions. Documentation checks resolve
all **330 TOC links** and **242 case source links**, including the 13 Spending cases in
runtime order. Pandoc renders the **105 display-math blocks** without warnings.

## Initial recorded DepositStore implementation verified on 13 October 2026

SpendingSpec now submits real transactions. Funding creates each input's allocation;
release queries read those recorded amounts from `UTxOState`. No model state is installed,
and neither standalone acceptance property calls `pendingWith`.

| Check | Result | Evidence |
| --- | --- | --- |
| Spending N01 | Passed 100 generated cases | Standalone TopTx, all output forms, exact signed net declaration, real allocations and balance changes. |
| Spending N02 | Passed 100 generated cases | Implicit-only outputs receive consumed application ADA plus the full recorded release; fees are funded separately. |
| Spending N03/F01/F02/N04/F03 | All five passed | Local SubTx release, missing declarations, ordinary effects excluded on phase-2 failure, rejection leaves ledger state unchanged. |
| Exactness Netting F01–F04 | Passed 100 cases each | Allocation and release amounts one lovelace too low or too high are rejected with the exactness failure. |
| Collateral Funding N04/F02/F03/F05 | All four passed | Additional return deposit is funded before the coin minimum; released surplus cannot replace that minimum; rounded-up one-lovelace boundary is enforced. |
| Collateral Surplus N01 | Passed | Released surplus reaches fees; treasury and ordinary inputs remain unchanged. |
| Complete DepositStore outline | 62 passed; 174 intentional failures | No implemented check failed. |
| Technical declaration fixture | Passed 100 cases | Retains repeated SubTx occurrences. |
| Dijkstra era regressions | 152 examples; 0 failures; 2 existing pending | Existing ledger behavior outside the DepositStore outline. |
| Golden/codec checks | 125 examples; 0 failures | Includes negative signed DepositStore diagnostics. |
| Core DepositStore codec | Passed 100 cases | Balance and allocation map roundtrip. |
| Shelley state snapshots | Four properties passed, 100 cases each | UTxOState, EpochState and NewEpochState roundtrips; six-field pre-Dijkstra byte compatibility. |
| Dijkstra state snapshots | Three properties passed, 100 cases each | UTxOState, EpochState and NewEpochState retain the Store across serialization; generator maximum size 10. |

The prospective Store state is validated on both ordinary and collateral paths. The
chosen phase-2 outcome determines which transfer is applied. SubTx financial imbalance
remains permitted; TopTx declares the complete batch net amount exactly once.

The Dijkstra test target builds. The affected `cardano-ledger-test`,
`cardano-ledger-conformance`, `cardano-ledger-shelley-test`,
`cardano-ledger-shelley-ma-test`, `ledger-state` and `cardano-ledger-api` packages also
build with tests and benchmarks enabled. Compilation of the conformance target does
not establish Agda conformance for the new Store; that model has not been extended.

**Seed:** `739231514`. Reproduce the business run with:

```sh
cabal --config-file=/private/tmp/ds-structure-cabal.config build cardano-ledger-dijkstra:test:tests --offline --enable-tests --enable-benchmarks --jobs=2
dijkstra_test_binary="$(cabal list-bin cardano-ledger-dijkstra:test:tests --offline)"
"$dijkstra_test_binary" --match '/Dijkstra/Era-specific spec/DepositStore/' --seed 739231514 --format=specdoc
```

The snapshot runs select `--match UTxOState` and `--match EpochState` with
`--qc-max-size=10`, retaining 100 generated cases per property while bounding nested
governance state. An initial broader `State Types` run was interrupted and is not counted
as a completed verification run.

The complete outline deliberately returned failure for its 174 backlog placeholders.
At this checkpoint, `--match DS-TX-PRESENCE-ACTIVITY-SPENDING` selected seven completed
spending cases; the latest selection above contains 13.

At this checkpoint, all 236 document case titles, source links and reading order matched
runtime registration. The 324-entry TOC resolved to unique anchors, and Pandoc rendered
the mathematical expressions without warnings. Ctags were regenerated.

Local evidence: `/private/tmp/ds-store-build.log`,
`/private/tmp/ds-store-broad-build.log`, `/private/tmp/ds-store-business.log`,
`/private/tmp/ds-store-result-audit.json`, `/private/tmp/ds-store-regression.log`,
`/private/tmp/ds-store-golden.log`, `/private/tmp/ds-store-fixtures.log`,
`/private/tmp/ds-store-core-tests.log`, `/private/tmp/ds-store-shelley-state-tests.log`,
`/private/tmp/ds-store-utxostate-roundtrip.log` and `/private/tmp/ds-store-epochstate-roundtrip.log`.
These are run artifacts; the source specs and commands provide the reproducible inputs.

## Earlier standalone TopTx contract split on 13 October 2026

| Case | Generated scope | Expected declaration |
| --- | --- | --- |
| N01 | Implicit-only, store-backed-only or mixed outputs. | Newly allocated deposits minus released deposits; allocation, zero and release are covered. |
| N02 | Only implicit outputs. | Release all recorded deposits consumed by the transaction. |

Both cases have no SubTxs. The model prices store-backed outputs using the fixed
4310 lovelace-per-byte policy and their serialized size; unrelated unspent deposits
are excluded. N01 supplies any additional funding needed for outputs and allocations.
N02 returns application ADA plus the full release, with fees funded separately.

At this earlier checkpoint the state was a **test model**, not production `UTxOState`.
The submission adapter called `pendingWith` and submitted nothing. Neither acceptance
contract was reported as passing. The real implementation above supersedes this setup.

| Executed check | Result |
| --- | --- |
| Dijkstra test target build | Passed |
| SpendingSpec | 5 passed, 2 pending, 0 failures |
| General model fixture property | Passed 100 cases: 33% implicit-only, 28% store-backed-only, 39% mixed; 27% allocation, 24% zero, 49% release |
| Implicit-only model fixture property | Passed 100 generated cases |
| Existing declaration fixture property | Passed 100 generated cases |
| Complete DepositStore outline | 51 passed, 2 pending, 183 intentional `False` failures |

The fixture checks verify input resolution, positive allocation records, value
conservation, net declarations and funded release destinations. They establish model
consistency, not production ledger acceptance.

The former SubTx control is now N03; the phase-2 acceptance control is now N04.
Their logic is unchanged, as are F01, F02 and F03. Earlier results below retain their
original identifiers and scope.

**Seed:** `739231514`. Logs: `/private/tmp/ds-spending-split-build.log`,
`/private/tmp/ds-spending-split-tests.log`, `/private/tmp/ds-spending-split-fixtures.log`,
`/private/tmp/ds-spending-split-business.log`.

## Earlier spending-presence run on 13 October 2026

The initial six [SpendingSpec cases](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs)
executed against the ledger before N01 was strengthened. Both phase-2 cases exercise TopTx and SubTx,
giving eight spending paths across six registered examples.

| Case | Verified behavior | Result |
| --- | --- | --- |
| N01 | TopTx with its own declaration consumes the store-backed input and creates an implicit output with the same 10 ADA. | Passed |
| N02 | SubTx with its own declaration and TopTx's declaration consumes the input and creates its own implicit 10 ADA output. | Passed |
| F01 | Removing TopTx's declaration produces exactly `MissingUTxODepositDeclaration`; ledger state is unchanged. | Passed |
| F02 | Removing SubTx's declaration while retaining TopTx's produces exactly `SubMissingUTxODepositDeclaration`; ledger state is unchanged. | Passed |
| N03 | Both body levels accept real phase-2 failure: ordinary input retained, ordinary output absent, disjoint collateral consumed, return created and fees credited. | Passed |
| F03 | Both body levels still reject their missing declaration on the phase-2 failure path, preserving the entire ledger state. | Passed |

These are **presence-only controls**. Funding and spending explicitly declare zero;
the fixture conserves application ADA without inventing allocation metadata or Store
funding. This is not evidence that zero is the correct deposit amount for the
documented 10 + 2 → 12 ADA release example. That complete transition still requires
recorded allocations, exactness and Store accounting.

`validateTopTxSpendingInputsDeclaration` and `validateSubTxSpendingInputsDeclaration`
resolve only their body's ordinary inputs against the original UTxO. Their ledger
hooks run on both phase-2 outcomes and are not marked static. They reuse the existing
missing-own-declaration failures; `TxIn` and ledger state representations are unchanged.

**Build:** `cardano-ledger-dijkstra:test:tests` succeeded offline with tests and benchmarks enabled.
**Seed:** `739231514`.

| Executed suite | Examples | Failures | Pending |
| --- | ---: | ---: | ---: |
| SpendingSpec | 6 | 0 | 0 |
| Complete DepositStore outline | 235 | 183 deliberate placeholders | 0 |
| DijkstraEra Onwards ledger regressions | 152 | 0 | 2 |
| Golden tests | 124 | 0 | 0 |

All 52 implemented DepositStore checks passed. A source audit confirmed that each
of the other 183 failures still corresponds to a literal `False` placeholder.
Document titles, source links, tags, TOC targets and executable reading order were
checked together. No placeholder was skipped or changed to pending.

The direct golden-test invocation required
`cardano_ledger_dijkstra_datadir` to point at `eras/dijkstra/impl`. An initial run
without it used stale installed CBOR data and could not find two JSON files; all
124 golden tests passed with the repository data. No golden files were changed.

Logs: `/private/tmp/ds-spending-build.log`, `/private/tmp/ds-spending-tests.log`,
`/private/tmp/ds-spending-business.log`, `/private/tmp/ds-spending-ledger.log`,
`/private/tmp/ds-spending-golden-configured.log`.
The source/result audit is `/private/tmp/ds-spending-result-audit.json`.

## Domain support consolidated on 12 October 2026

The shared specification vocabulary now lives under `Core.Specs`, with domain-named
leaves: `Tx.Declaration`, `Tx.Declaration.TopTx`, `Tx.Declaration.SubTx`, `Tx.Output`,
`OutputIndex` and `StrictlyPositiveCoin`. Related generators, builders and predicates
stay together. `Core.Encoding` retains the combined CBOR/JSON observations;
`Core.Submission` contains ledger preparation, preservation and submission mechanics.
Its `Declaration` and `Output` modules register the respective scenario rows.

This replaces 23 support modules with 13. The specs retain their assertions, case
titles, identifiers and execution order. Source comparison confirms the moved
helper bodies are preserved apart from namespace changes. No ledger rules change.

The Dijkstra test target builds. With seed **739231514**, the complete DepositStore
suite runs **235 examples: 46 pass and 189 fail at their intentional `False`
placeholders**. The passing checks comprise **21 Grammar properties** and
**25 Presence checks**. The separate technical fixture check also passes.
Every reported failure was matched to its placeholder definition. Documentation
links, titles, anchors and case order match the source and runtime output.

Local evidence: `/private/tmp/ds-domain-modules-build.log`,
`/private/tmp/ds-domain-modules-tests.log`,
`/private/tmp/ds-domain-modules-fixture-tests.log` and
`/private/tmp/ds-domain-modules-result-audit.json`.

## Typed fixture generators verified on 12 October 2026

Both typed `Fixture.TopTx` and `Fixture.SubTx` modules now expose generators.
Amount-specific generation retains every declaration form and both index bounds,
adding an interior local index. Boundary generation still covers both positive
amount bounds and explicit zero. SubTx funding requests use generated strictly
positive amounts.

The absence checks generate spending inputs, reference inputs and an auxiliary-data
hash once, then compare two bodies differing only in their declaration. Both
bodies must round-trip and their encodings must differ. The shared index generator
module is now named `Fixture.OutputIndexGen`; imports, Cabal registration and
specification links follow that name.

The Dijkstra test target builds. All **21 Grammar properties pass 100 cases each**
with seed **739231514**. Case titles, source links and runtime order match the
specification. The remaining business checks were not rerun.

Local evidence: `/private/tmp/ds-typed-fixture-generators-build.log`,
`/private/tmp/ds-output-index-gen-build.log` and
`/private/tmp/ds-typed-fixture-generators-tests.log`.

## Decoder-input generation consolidated on 12 October 2026

TopTx and SubTx each expose one `DecoderInputsGen` module, replacing their separate
`DecoderInputs` and `Gen` modules. The amount helper now has type
`Integer -> Gen DecoderInputs`. Each generated set retains the supplied amount and
all declaration forms, covers both valid index bounds, and adds one local release
at a generated interior index. Every draw supplies five CBOR and five JSON inputs
for TopTx, or six of each for SubTx.

All six invalid-amount checks now use `prop` and `forAll`, with 0, −1 and 2⁶⁴ still
visible in the specs. Shared `DecoderInputs` stays in `Core.Encoding`; assertions
remain in the specs. No production rules or test identifiers changed.

The Dijkstra test target builds. All **21 Grammar checks pass**, including **100
samples for each of the 16 properties**, with seed **739231514**. Documentation
links, titles and test order match the source and execution. The remaining
business checks were not rerun.

Local evidence: `/private/tmp/ds-decoder-inputs-gen-build.log` and
`/private/tmp/ds-decoder-inputs-gen-tests.log`.

## TopTx grammar generators verified on 12 October 2026

TopTx now follows the same layout as SubTx. F01 checks zero amounts; F12 and F13
separately check negative and overflowing amounts. Each covers all four TopTx
amount-bearing forms through CBOR and JSON. F02 and F04 generate structural
failures, while F14 and F15 generate invalid local output indices. The common
index generators are shared between the two body levels; their settlement forms
remain separate.

The Dijkstra test target builds. All **21 Grammar checks pass: 11 TopTx and 10
SubTx**, with seed **739231514**. Each generated property passes **100 samples**.
Documentation titles, source links and test order match the executable spec.
The 189 intentional placeholders are unchanged; this focused run does not rerun
the remaining business checks.

Local evidence: `/private/tmp/ds-toptx-grammar-generators-build.log` and
`/private/tmp/ds-toptx-grammar-generators-tests.log`.

## SubTx grammar generators verified on 12 October 2026

F03 and F05 now generate invalid raw declarations and release targets. Each draw
contains every existing structural defect category, with varying amounts, unknown
tags and kinds, and extra CBOR fields. F10 and F11 separately generate negative
and overflowing local output indices, with shrinking that preserves the invalid
range. Assertions remain in `SubTxSpec`; the generators live in
`Adapter/Tx/Grammar/Fixture/SubTx/Gen.hs`.

The Dijkstra test target builds. All **17 Grammar checks pass**, including **100
samples each** for F03, F05, F10 and F11, with seed **739231514**. Both formats are
checked; CBOR runs at every supported Dijkstra version. Documentation titles,
source links and test order match the executable spec.

This focused run does not rerun the remaining business checks. Splitting target
rejections adds two examples; the 189 intentional placeholders remain unchanged.

Local evidence: `/private/tmp/ds-subtx-grammar-generators-build.log` and
`/private/tmp/ds-subtx-grammar-generators-tests.log`.

## Combined codec checks verified on 12 October 2026

[`Core.Encoding`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Encoding.hs)
combines the results of [`Encoding.CBOR`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Encoding/CBOR.hs)
and [`Encoding.JSON`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Encoding/JSON.hs).
Each shared assertion checks both formats in one call. The separate implementations
retain CBOR coverage at every supported Dijkstra version and annotated decoding for
transaction bodies. Checks specific to one format still name that format directly.
Independently constructed fixtures use `DecoderInputs`, with `cborInputs` and
`jsonInputs`; `decodeInputs` checks both collections in the shared assertion.
`allDeclarationsWithAmount` names the full set of amount-bearing forms at each
body level. SubTx `allDeclarationInputsWithAmount` supplies five CBOR and five JSON
inputs per amount: allocation, funding request, delegated release and local release
at indices 0 and 65535. F07–F09 reject invalid amounts in every one of these inputs.
Both body-level fixtures use `absent` and `explicitZero`. The shared
`encodingsEqual` returns each CBOR-version comparison and the JSON-value comparison
separately; `shouldAllBe False` requires different representations in both formats.
Raw declaration and destination inputs now live in the `TopTx/DecoderInputs.hs`
and `SubTx/DecoderInputs.hs` fixture submodules, imported as `TopTxInputs` and
`SubTxInputs`. Their parent modules retain typed declarations and body fixtures.
The structural rejection fixture is named `malformedDeclarations` at both levels.

The Dijkstra test target builds; all **15 Grammar checks pass** with seed
**739231514**. Case identifiers, assertions and business scope are preserved.
Local evidence after extracting decoder-input fixtures: `/private/tmp/ds-decoder-input-modules-build.log`
and `/private/tmp/ds-decoder-input-modules-tests.log`.

## SubTx invalid-amount cases verified on 12 October 2026

The former combined F07 is split into **F07: zero**, **F08: negative** and
**F09: overflow**, using raw amounts 0, −1 and 2⁶⁴ respectively. Each checks
allocation, funding request and release decoding through CBOR and JSON.

The Dijkstra test target builds; all **15 Grammar checks pass** with seed
**739231514**, including 100 generated cases for each amount-preservation property.
This focused run does not rerun the remaining business checks; the two additional
examples separate existing assertions. The 189 placeholders remain unchanged.

Local evidence: `/private/tmp/ds-subtx-amount-cases-build.log` and
`/private/tmp/ds-subtx-amount-cases-tests.log`.

## TopTx and SubTx Grammar split verified on 12 October 2026

`GrammarSpec` now aggregates
[TopTxSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs)
followed by
[SubTxSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs).
Both follow Amounts, Absence, Forms, Structure and Destinations, matching the document.
Assertions remain inline. The former combined F01 now checks TopTx; its existing
SubTx assertions live in F07. All other case identifiers are preserved.

The Dijkstra test target builds. All **seven TopTx checks and six SubTx checks pass**,
with 100 generated cases for each amount-preservation property. The business run
with seed **739231514** reports **227 examples: 38 passed and 189 intentional
placeholder failures**. The failed cases still contain their explicit `False`
implementations. Case titles, source links and runtime order match the specification;
the earlier shared-group anchors remain available.

Local evidence: `/private/tmp/ds-grammar-split-build.log`,
`/private/tmp/ds-grammar-split-business.log` and
`/private/tmp/ds-grammar-split-result-audit.json`.

## Grammar assertion readability verified on 12 October 2026

P01 now checks TopTx forms and P02 checks SubTx forms, each using an explicitly
typed `StrictlyPositiveCoin` parameter. F01 uses the generic `shouldAllSatisfy`
adapter with `isLeft` visible in the spec; each invalid-payload result is still
checked individually with its original failure diagnostics.

The Dijkstra test target builds. With seed **739231514**, all **12 Grammar checks
pass**, including 100 generated cases for each of P01 and P02. The full business
run reports **226 examples: 37 passed and 189 intentional placeholder failures**.
All failures still correspond to explicit `False` placeholders; case order, titles
and source links agree with the document.

Local evidence: `/private/tmp/ds-grammar-rejections-build.log`,
`/private/tmp/ds-grammar-rejections-business.log` and
`/private/tmp/ds-grammar-rejections-result-audit.json`.

## StrictlyPositiveCoin extraction and test ownership verified on 12 October 2026

The abstract type and its checked construction, accessor and codec instances now
live in [Cardano.Ledger.StrictlyPositiveCoin](../libs/cardano-ledger-core/src/Cardano/Ledger/StrictlyPositiveCoin.hs).
The constructor stays private. Construction accepts exactly 1 through 2⁶⁴ − 1
lovelace, and CBOR/JSON keep the numeric representation. Core and Dijkstra test
targets and the ledger API library build successfully.

| Responsibility | Executed result |
| --- | --- |
| [StrictlyPositiveCoinSpec](../libs/cardano-ledger-core/test/Test/Cardano/Ledger/StrictlyPositiveCoinSpec.hs), outside DepositStore | 5 passed: valid bounds, generated valid integers, invalid boundaries, generated nonpositive integers and generated overflow. The three properties each passed 100 cases. |
| Grammar | 11 passed. P01 preserves a generated typed amount through every declaration form; F01 rejects invalid raw amounts through both declaration codecs. Direct type assertions have moved to core. |
| Existing Presence checks | 25 passed: nine Creation, five Scope and eleven Dependency checks. |
| Declaration codec and Huddle checks | 90 passed, preserving the inline CBOR/JSON expectations and transaction-body integration checks. |
| Technical fixture cardinality | 1 passed with 100 generated cases. |

The business run contains **225 examples: 36 passed and 189 intentional placeholder
failures**. Every failing case still has its explicit `False` implementation; no
implemented check failed. All case titles, source links and runtime order match
the business document. Grammar N02 is retired to the core spec; P01 and F01 now
test declaration use of the amount type.

After simplifying P01 with the generic `shouldAllBe` adapter, the Dijkstra test
target rebuilt and all 11 Grammar checks passed again. The expected declaration
remains visible in the spec; the adapter only iterates equality assertions.

All runs use seed **739231514**. Local evidence:
`/private/tmp/ds-strictlypositivecoin-spec-build.log`,
`/private/tmp/ds-strictlypositivecoin-core-tests.log`,
`/private/tmp/ds-strictlypositivecoin-business.log`,
`/private/tmp/ds-strictlypositivecoin-codecs.log`,
`/private/tmp/ds-strictlypositivecoin-fixture.log`,
`/private/tmp/ds-strictlypositivecoin-result-audit.json`,
`/private/tmp/ds-grammar-readable-build.log` and
`/private/tmp/ds-grammar-readable-tests.log`.

## Grammar implementation structure verified on 12 October 2026

Each Grammar `it` or `prop` now contains its operation and expected result directly.
The former adapter containing complete test bodies has been replaced by codec
observations and reusable fixtures, with symmetric TopTx and SubTx fixture modules.
Adapters contain no assertions or expected-result rules.

All 12 Grammar case IDs, titles and their order are preserved, along with the numeric
boundaries, malformed payload matrices, annotated body decoding and cross-level
funding-request check. Independent raw-number decoding remains covered.

The test target builds. The business run with seed **739231514** passes all **12 Grammar
checks**, including 100 generated amount cases. The full result remains **37 passing
checks and 189 intentional placeholder failures**. Document titles, order and updated
source links match all 226 registered cases.

Local evidence: `/private/tmp/ds-grammar-inline-build.log`,
`/private/tmp/ds-grammar-inline-business.log` and
`/private/tmp/ds-grammar-inline-result-audit.json`.

StrictlyPositiveCoin bounds and checked fixture construction now live in
`Adapter/StrictlyPositiveCoin/Gen.hs`, shared by Grammar and both body-level fixture modules.
Bounds are represented as a `(minimum, maximum)` tuple; each caller explicitly checks
both endpoints. After these changes, the test target builds and all 12 Grammar checks pass again, including
100 generated amount cases (seed **739231514**). Local evidence:
`/private/tmp/ds-positivecoin-bounds-build.log` and `/private/tmp/ds-positivecoin-bounds-tests.log`.

## Grammar grouping verification on 12 October 2026

Grammar now presents five responsibilities in both `spec` and the business document:
Amounts, Absence, Forms, Structure and Destinations. Each `describe` label includes
its rule, making the same meaning visible in the source and test output. All 12 case IDs, descriptions
and assertions are retained; F06 now appears with Forms.

The Dijkstra test target builds successfully. With seed **739231514**, all **12 Grammar
checks pass**, including 100 generated amount round trips. The complete business suite
retains **37 passing checks and 189 deliberate placeholder failures**. Source links,
case order and the expanded TOC match the executable registrations.

Local evidence: `/private/tmp/ds-grammar-grouping-build.log`,
`/private/tmp/ds-grammar-grouping-business.log` and
`/private/tmp/ds-grammar-grouping-result-audit.json`.

## Scope reduction verification on 12 October 2026

Pricing, Stake and Voting have been removed from the executable suite and Cabal
registrations for now. Their 16 documented examples remain in the business specification,
with deferred-test notices. Transaction rules and Ledger effects retain their case IDs,
titles and order.

The Dijkstra test target builds successfully. The business selection below, with seed
**739231514**, runs **226 examples: 37 pass and 189 deliberately fail as placeholders**.
Every failed tag matches a placeholder body; no implemented check failed. All retained
source links and document/runtime case order were verified.

Local evidence: `/private/tmp/ds-scope-build.log`, `/private/tmp/ds-scope-business.log`
and `/private/tmp/ds-scope-result-audit.json`. Earlier runs below include the removed
specs and retain their original counts.

## Folder alignment verification on 12 October 2026

`TransactionRules/` now groups `Tx/` and `Collateral/`; `LedgerEffects/` contains the
seven state-effect specs directly. Their orchestration modules register the same cases
in the same order. Module names, imports, Cabal registrations and documentation links
follow the new paths. Adapters remain under `Adapter/`, and semantic tags are unchanged.

The Dijkstra test target builds with the command below. Repeating the business and
fixture selections with seed **739231514** gives **37 passing business checks**, the
same **205 intentional placeholder failures**, and **one passing fixture property**
with 100 generated cases. All 242 case IDs, titles, source links and reading order
still match the document. No assertion behavior changed during this folder move.

Local evidence: `/private/tmp/ds-folders-build.log`, `/private/tmp/ds-folders-business.log`,
`/private/tmp/ds-folders-fixture.log` and `/private/tmp/ds-folders-result-audit.json`.

## Coherence verification on 12 October 2026

The revision corrects declaration scope, separates required amounts from supplied
amounts, makes ordinary validation apply before either phase-2 outcome, and specifies
independent observations for the pending rules. It does not implement deposit accounting
or Store state transitions. No production ledger module changed.

The Dijkstra test target builds successfully with the command below. Moving grammar
checks into the test executable required declaring its direct `aeson` dependency.

```sh
cabal --config-file=/private/tmp/ds-structure-cabal.config build cardano-ledger-dijkstra:test:tests --offline --enable-tests --enable-benchmarks --jobs=2
```

Runs used seed **739231514**:

| Selection | Examples | Passed | Expected placeholder failures |
| --- | ---: | ---: | ---: |
| DepositStore business specification | 242 | 37 | 205 |
| Declaration codec goldens and Huddle checks | 90 | 90 | 0 |
| Technical fixture integrity | 1 | 1 | 0 |

The 37 implemented business checks comprise **12 Grammar, nine Creation, five Scope
and 11 Dependency checks**. The complete business run took 0.3519 seconds. Every one
of its 205 failed case tags was matched to a deliberate `False` or
``False `shouldBe` True`` body; no implemented case failed. The codec selection comprises
84 golden examples and six Huddle properties. The generated Grammar property and
technical fixture property each passed 100 cases.

```sh
dijkstra_test_binary="$(cabal list-bin cardano-ledger-dijkstra:test:tests --offline)"
"$dijkstra_test_binary" --match '/Dijkstra/Era-specific spec/DepositStore/' --seed 739231514 --format=specdoc
"$dijkstra_test_binary" --match 'UTxODepositChange' --skip '/DepositStore/' --seed 739231514 --format=specdoc
"$dijkstra_test_binary" --match '/Test infrastructure/DepositStore fixtures/' --seed 739231514 --format=specdoc
```

The first command deliberately returns failure while the backlog remains. The codec
command excludes DepositStore case titles containing the same type name; it selects
the retained encoding checks rather than pending accounting properties.

The document and runtime registrations agree in **all 242 case IDs, titles and reading
order**. Every source line link resolves to its matching registration. The TOC has
302 entries, 305 unique anchors (three historical aliases) and 44 collapsible groups,
each with an indented child container. Internal links resolve. Pandoc rendered the
complete document with MathML without warnings. The GitHub page was not published or
visually checked during this revision.

Local evidence: `/private/tmp/ds-coherence-build-final.log`,
`/private/tmp/ds-coherence-business.log`, `/private/tmp/ds-coherence-codec-only.log`,
`/private/tmp/ds-coherence-fixture.log`, `/private/tmp/ds-coherence-result-audit.json`
and `/private/tmp/ds-coherence-preview.html`. These temporary files are run artifacts;
the committed specs and commands are the reproducible inputs.

## Earlier structural verification on 12 October 2026

The final test target built successfully with:

```sh
cabal --config-file=/private/tmp/ds-structure-cabal.config build cardano-ledger-dijkstra:test:tests --offline --enable-tests --enable-benchmarks --jobs=2
```

The temporary configuration copies the existing Cabal configuration and redirects logs
and build summaries to `/private/tmp/ds-cabal-logs` for filesystem access. The build
completed with exit status 0; its log is `/private/tmp/ds-adapter-cleanup-build.log`.
On a shell with access to the usual Cabal logs, omit `--config-file`.

The final business and technical registrations were run separately with seed
**739231514**:

| Selection | Examples | Passed | Failures |
| --- | ---: | ---: | ---: |
| Business DepositStore specification | 189 | 25 | 164 deliberate placeholders |
| Test infrastructure / DepositStore fixtures | 1 | 1 | 0 |

The business run completed in 0.3558 seconds. Its 189 completed semantic case tags matched
the source registrations exactly once, and all 164 failed tags matched intentional
`False` or ``False `shouldBe` True`` bodies. The 25 implemented business checks passed:
nine Creation checks, five Scope checks and 11 Dependency checks. This remains an
expected failing backlog suite, not complete DepositStore enforcement.

The separate, untagged technical fixture-cardinality property passed 100 generated
cases. It is excluded from the business count. Reproduce the two selections with:

```sh
dijkstra_test_binary="$(cabal list-bin cardano-ledger-dijkstra:test:tests --offline)"
"$dijkstra_test_binary" --match '/Dijkstra/Era-specific spec/DepositStore/' --seed 739231514 --format=specdoc
"$dijkstra_test_binary" --match '/Test infrastructure/DepositStore fixtures/' --seed 739231514 --format=specdoc
```

Local run evidence is in `/private/tmp/ds-business-after-adapter-removal.log`,
`/private/tmp/ds-fixture-after-adapter-removal.log` and
`/private/tmp/ds-final-result-audit.json`. These temporary files are run artifacts,
not committed verification inputs. The additional codec, UTXO, SUBUTXO and LEDGER
selections recorded on 9 October below were not rerun for this change.

The document is grouped into Domain model, Transaction rules, Ledger effects and
Derived distributions, followed by appendices. Domain model now introduces Outputs,
DepositStore, Transaction bodies and Deposit calculation directly. API details live
in Appendix C; transaction validity and state transitions stay in their rule chapters.
Ledger effects directly contains the former State responsibilities.

The document-only checks preserve all 189 case titles, descriptions and source links.
All 249 TOC entries match their target titles in reading order; all 251 explicit
anchors are unique, including two aliases for relocated overviews. Each of the 44
collapsible groups indents its children. The deepest 34 case titles use numbered bold
text below H6 groups to stay within Markdown's heading levels.

All 72 mathematical expressions parse and render with KaTeX; the document also renders
through Pandoc. The IDE preview was checked with Deposit calculation expanded and with
Tx → Presence → Activity → Creation expanded down to the test links. Indentation is
visible at every level without extra bullets. A minimal nested-markup sample was also
preserved by GitHub's Markdown API. The repository's remote page has not been visually
checked for this update. These document changes do not rerun or alter the
test results above.

## Test infrastructure and verification method

`Adapter/` contains helper infrastructure, not business requirements or a business spec
group. Adapters translate domain scenarios into ledger fixtures and observations.
Fixtures state their preconditions; transaction builders preserve intentional invalid
amounts, missing declarations and wrong destinations. They may repair incidental
witness or fee requirements only when that leaves the condition under test unchanged.

Acceptance fixtures must satisfy the other ledger rules; rejection fixtures isolate the
condition being rejected and include a corresponding valid control. Preserve existing
SubTx contributions to TopTx fees when checking DepositStore conservation.

Scenario tables keep the description, domain input, phase-2 outcome and expected decision
visible in the executable spec. Each row gets fresh ledger state. Properties compare
observed results with independently expressed rules; an adapter must not manufacture
expected values by calling the production validator.

Calculate expected balances, obligations and settlement amounts with a small independent
reference model. Recalculate obligations from model UTxOs and their retained allocations
under the chosen policy instead of trusting a cached ledger obligation. Derive expected
Store flows from the declared operations and settlement rules, not from the ledger's
resulting balance.

Generators cover both output variants and mixtures, TopTx and SubTx declarations,
explicit delegation, either sign of mixed allocations and releases, and individually
imbalanced SubTxs whose complete batch balances. Include exact amounts, one-lovelace
errors in both directions, unrelated Store surplus, collateral deposit surplus,
permitted zero amounts and both ends of the supported amount and output-index ranges.
Opposing declaration errors must remain invalid even when their batch total cancels;
explicit zero remains different from absence. Exercise checked construction and both
wire decoders for positive-operation bounds, including zero, negative and overflow
rejections.

Include valid lifecycle sequences and enforce acceptance coverage so an implementation
that rejects everything cannot satisfy accepted-state invariants vacuously. Keep Conway
initialization, fixed-policy epoch transitions and agreed collateral behavior in scope;
repricing, Plutus projection and stronger local-settlement semantics remain deferred.
Shrinking must preserve dependencies, preconditions and the intended invalid condition.
Report the random seed and minimized counterexample to make failures reproducible.

Helpers are scoped under `Adapter/Tx/Presence/Creation` or
`Adapter/Tx/Presence/Dependency` when they have those fixture assumptions. The dependency
submission helpers preserve an implicit-only fixture; they are not generic Store-activity
builders. Shared declaration enumerators remain under `Adapter/Declarations`.
`Adapter/Tx/Grammar` checks constructors and production payload/body decoders without
funded ledger fixtures. Exact-byte goldens and independent body-decoder regressions
remain under Binary. Further Collateral and State adapters are introduced when their
scenarios need them.

Rejection comparisons capture the state after fixture funding and preparation, immediately
before submission. Fixture integrity checks verify test construction, not additional
protocol requirements.

### Fixture cardinality

The [technical property](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/DepositStoreFixtureSpec.hs)
constructs transaction bodies from generated declarations. SubTxs are occurrences in a
sequence, so two equal declarations must remain separate entries:

```text
constructedBody = declarationToTxBody(fixture)

length(subTransactions(constructedBody))
  = length(subTxDeclarations(fixture))
```

Deduplicating repeated declarations could silently change whether the declaration rule
is exercised as intended. The property checks requested and constructed counts across
generated fixtures; preservation of declaration contents and order would require
separate assertions. It is registered independently under `Test infrastructure` →
`DepositStore fixtures`, carries no domain `DS-*` tag, and is not included in the business case count.

## Historical focused results recorded on 9 October 2026

**Code checkpoint:** `c8760684f`.


These historical focused runs and retained regression results total **81 examples, zero failures**.
They do not represent a passing run of the entire DepositStore outline, whose
placeholder assertions deliberately fail.

| Run | Examples | Failures |
| --- | ---: | ---: |
| Historical DS-TX-001 creation (current Creation and Scope) | 14 | 0 |
| Historical DS-TX-009 declaration dependency (current Dependency and separate technical fixture) | 12 | 0 |
| Predicate-failure codec goldens: UTXO tags 24 and 25, SUBUTXO tag 11 | 3 | 0 |
| Dijkstra UTXO | 19 | 0 |
| Dijkstra SUBUTXO | 30 | 0 |
| Dijkstra LEDGER | 3 | 0 |
| **Total** | **81** | **0** |

### Creation presence evidence

**Historical rule identifier:** `DS-TX-001`.

The current homes are [DS-TX-PRESENCE-ACTIVITY-CREATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs)
and [DS-TX-PRESENCE-ACTIVITY-SCOPE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs).

Seven properties each passed 100 generated cases, and seven ledger scenarios passed.
The properties cover declaration presence across explicit forms and the body's own
regular-output scope. Nested SubTx outputs and collateral return do not become TopTx's
own regular outputs. The ledger scenarios use implicit-only acceptance controls and
reject missing TopTx or SubTx declarations on both phase-2 outcomes, checking the exact
failure and unchanged state after rejection.

The [declaration validators](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/DepositStore/Declaration.hs)
are `validateTopTxCreatedOutputsDeclaration` and
`validateSubTxCreatedOutputsDeclaration`. Their domain failure is
`MissingBodyUTxODepositDeclaration` in `DepositStoreOutputDeclarationFailure`.
Ledger integration exposes `MissingUTxODepositDeclaration` in UTXO (CBOR tag 25) and
`SubMissingUTxODepositDeclaration` in SUBUTXO (CBOR tag 11).

These checks establish creation-triggered declaration presence. They do not establish
correct deposit amounts, funding, settlement or Store state changes. The accepted
ledger controls do not create store-backed outputs; an isolated validator accepting
an explicit zero is not evidence that a Store allocation is funded.

### Dependency evidence

**Historical rule identifier:** `DS-TX-009`.

The 11 protocol checks now live in [DS-TX-PRESENCE-DEPENDENCY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs);
the separate fixture property now lives in [DepositStoreFixtureSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/DepositStoreFixtureSpec.hs).

Six ledger scenarios, five isolated-validator properties and one fixture-construction
property passed; each property passed 100 generated cases. The ledger scenarios use
absent or explicit-zero declarations, funded implicit outputs and no Store activity.
They include acceptance and exact rejection with a real failing script prepared for
the phase-2 failure path. Rejected submissions leave the pre-submission ledger state
unchanged. The isolated properties cover all declaration forms, including nonzero
operations; the fixture property checks that body construction retains the SubTx count.

`validateTopTxNetUTxODepositDeclaration` reports the domain failure
`MissingTopTxDeclaration`. The [TopTx UTXO rule](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Utxo.hs)
maps it to `MissingTopTxUTxODepositDeclaration`. The corresponding
[codec golden](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/GoldenSpec.hs)
also passed. This evidence establishes presence, not amount or settlement validity.

The existing [construction and codec tests](../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Binary/Golden.hs)
exercise declaration representations and positive amount bounds. That evidence is
separate from enforcement of the remaining transaction rules.

## Historical results

- An earlier Dijkstra ledger regression run recorded **598 examples, zero failures
  and two pending tests**. UTXO predicate-failure round trips also passed 100 generated
  cases. These are historical results, not a current full-suite proof for checkpoint
  `c8760684f` or the documentation edits.
- Before the DS-TX-001 creation validators and ledger hooks were enabled, the original
  **13-example RED run had seven expected failures**: two presence properties and five
  ledger scenarios expected rejection but received acceptance. Both implicit-only
  ledger acceptance controls passed. This earlier suite predates the implemented
  14-example creation slice and is retained as historical evidence of the missing checks.

Future verification records should name their code checkpoint and actual run results.
Business cases and required behavior remain in the business specification.
