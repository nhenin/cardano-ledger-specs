# Dijkstra DepositStore verification record

**Updated:** 23 October 2026

**Release presence baseline:** `8ac3c67f2`, with the working-tree changes verified below.

**Coherence revision baseline:** `f06c329e3`, with the working-tree changes verified below.

**Earlier structural baseline:** `1dd45a7a2`; the earlier results retain their original scope.

**Retained historical evidence:** recorded 9 October 2026 at code checkpoint `c8760684f`.

This record separates implementation progress and executed-test evidence from the
[DepositStore business specification](dijkstra-deposit-store-rules.md). Current rule
references use semantic tags matching the executable hierarchy. Numeric tags below
identify historical runs only; their original observations and dates remain distinct
from the new structural verification.

**Naming updated on 19 October:** `Operations/Allocation` and `Operations/Release`
replace `Activity/Creation` and `Activity/Spending`. References below use the current
module names and tags; dated observations and historical log paths are unchanged.
The dated regressions below verify the vocabulary change and the subsequent
presence reorganization. `ScopeSpec` is now distributed across `AllocationSpec`
and `ReleaseSpec`; `DependencySpec` is now `SubTxDeclarationsSpec`. Historical
group names in dated run summaries describe the hierarchy at the time of each run.


**Declarations grouping:** `Declarations/Grammar` checks valid representations;
`Declarations/Requirements` checks which bodies must declare. The latter replaces
`RequiredDeclarations` (previously `Presence`). Current tags use
`DS-TX-DECLARATIONS-GRAMMAR` and `DS-TX-DECLARATIONS-REQUIREMENTS`, preserving every
case suffix. Current module links follow this hierarchy. Dated run headings, commands,
counts and evidence paths retain their historical meaning. Predicate and validator
names that refer to field presence are unchanged.

**Accounting hierarchy:** `Accounting/NetChange/SubTxSpec` checks each SubTx's
own change; `Accounting/NetChange/TopTxSpec` checks the complete transaction total.
`Accounting/BalanceSpec` integrates the Store transfer into the complete value
balance when phase 2 is valid. It replaces the standalone transaction
`ConservationSpec`. NetChange checks apply on both phase-2 outcomes.
Current tags use `DS-TX-ACCOUNTING-NET-CHANGE-SUBTX`,
`DS-TX-ACCOUNTING-NET-CHANGE-TOPTX` and `DS-TX-ACCOUNTING-BALANCE`, retaining case
suffixes. Previous anchors remain valid. Dated verification sections retain the
names, counts and scope of their original runs; their source links point to the
current modules. The earlier `Accounting` suite of 40 properties is now NetChange.

**Settlement hierarchy:** `Settlement/DesignationSpec`, `OutputIndexSpec` and
`OutputCoinSpec` check the designation requirement, the declaring body's own output
index, and the selected output's application ADA. They replace Participation,
Destination and Coverage. All 33 settlement cases are implemented.

**Attribution placement:** `Accounting/AttributionSpec` now contains the three signed
responsibility checks. Total invariance remains in `Accounting/NetChange/TopTxSpec`;
no-output delegation belongs to `Settlement/OutputIndexSpec`. The standalone
`Tx/AttributionSpec` stays removed. Historical names below identify the original runs;
source links follow the current modules. Previous documentation anchors still resolve.

## Current implementation status

The [executable outline](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStoreSpec.hs)
registers **206 implemented business contracts**, with no pending LedgerEffects
entry: 80 Declarations (21 Grammar and 59 Requirements), 58 Accounting
(41 NetChange, three Attribution and 14 Balance), two Authorization, 33 Settlement,
five Minimum coin, seven Collateral and 21 Ledger-effects checks.
The 21 effects checks replace the earlier nine-contract outline; the eight
pending contracts are now implemented or refined into explicit observations.
The former rejection-snapshot placeholder is removed: the submission adapter
installs state only on success, so snapshot equality after rejection would retest
that adapter rather than establish a new DepositStore transition. Transaction-rule
rejection checks remain unchanged.

All 14 Balance properties submit real transactions
and pass 100 generated scenarios each. The 19 October zero-net-change suite
contains 14 generated ledger properties: standalone TopTx, one or several SubTxs,
active and inactive children, both body levels, and phase-2 failure. Each active
body independently allocates and releases the same positive amount. Explicit zero
is accepted; omitting a required declaration is rejected.
All 48 registered Operations cases now have implemented checks, including the
zero-price structural property, translated-output allocation, both-level allocation,
reference-only access, collateral-only operations and the parent's own release requirement.
The 16 October allocation change adds N05 and replaces
F02 with a generated rejection followed by its accepted control. Its targeted results
are recorded below. The 15 October rebase verification covered the preceding 242
examples: all 68 then-implemented checks passed; its 174 failing case IDs exactly
matched the deliberate placeholders.

**Conservation scope corrected on 19 October:** ordinary financial conservation is
required only when phase 2 is valid, matching the existing ledger guard.
`DS-TX-CONSERVATION-F05`, which demanded rejection for an ordinary imbalance on
phase-2 failure, has been removed. P01 and P02 now state the phase-2-valid
precondition. N08 remains an acceptance control; it does not establish conservation
enforcement on failure. At that checkpoint, all 14 retained Conservation cases
were placeholders; they are now implemented under Accounting/Balance as recorded
below. No production rule changed. The earlier build and dry-run confirmed
256 registered business cases, including those 14 placeholders; that check
established registration only. Formatting and all 14 source links were checked.
Historical local evidence:
`/private/tmp/ds-conservation-scope-build.log`,
`/private/tmp/ds-conservation-scope-inventory.log` and
`/private/tmp/ds-conservation-scope-audit.json`.

Production state now retains a Store balance and the exact allocation for each live
store-backed `TxIn`. Ordinary validation checks per-body contributions, the batch net
total and release destinations. Successful execution updates allocations once for the
complete transaction. Collateral execution derives its own allocation, release and fee
settlement. Store ADA is included once in the ledger total.

The current suite contains Transaction rules and Ledger effects only. Pricing, Stake
and Voting tests remain deferred. Grammar has 21 codec checks; the reusable positive
amount type has five independent ledger-core checks. One technical fixture property
remains outside the business specification. The old model-only release fixture checks
have been replaced by real ledger submissions.

| Semantic responsibility and executable spec | Current implementation or verification |
| --- | --- |
| [DS-PRICING](dijkstra-deposit-store-rules.md#ds-pricing) | Pricing tests are deferred; the rules and seven examples remain documented. |
| [DS-TX-DECLARATIONS-GRAMMAR](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/GrammarSpec.hs) | Twenty-one declaration checks are implemented in separate TopTx and SubTx modules: typed amount integration, absent versus zero, legal forms and malformed payloads. Both levels have separate zero, negative and overflowing amount cases, generated structural inputs, and properties for generated negative or overflowing release indices. The former zero-delegation accounting case is implemented as Accounting Attribution N01, covering active and inactive explicit-zero children. |
| [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/OperationsSpec.hs) | P01 generates independent input/output deposit forms for TopTx and zero to four SubTxs at zero deposit price. It checks each active body's omitted declaration against its own ledger failure, then accepts the declared control, on ordinary success and real phase-2 failure paths. Activity is derived from actual input/output forms, independently of production predicates and amounts. |
| [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs) | All 17 checks pass. N05/F02 cover standalone allocation and omission; N06–N08/F07–F08 retain the own-output scope checks. F06 uses production Conway-to-Dijkstra output conversion followed by real funding, then rejects omission and accepts its declared control. N09 accepts independent parent/child allocations with exact local and aggregate declarations. |
| [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs) | All 16 properties pass 100 generated scenarios each. N09 adds real Store-backed reference inputs; N10 exercises all three collateral Store placements with actual script success and failure; F06 requires TopTx's own missing-declaration failure despite its children's declarations. Other cases cover standalone and multi-child releases, inactive children, TopTx's release and phase-2 failure. Assertions check submission outcomes; Store effects belong to Ledger effects. |
| [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ZERO-NET-CHANGE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs) | All 14 ledger properties pass 100 generated cases each. Positive recorded releases equal independently priced allocations for each active body. Coverage includes standalone TopTx, one or several SubTxs, inactive siblings, both body levels and phase-2-invalid transactions. Each omission variant requires the responsible body's failure; the original fully declared control is accepted. |
| [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs) | All 11 protocol examples have implemented checks. Fixture cardinality is verified separately under test infrastructure. |
| [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs) | All 22 properties pass 100 generated scenarios each. Each SubTx declares its own allocations minus recorded releases. Coverage includes local/delegated operations, cancelling errors, translated implicit inputs, empty application assets, unrelated Store surplus, wrong signs and real phase-2 failure. Every rejection checks the specific child failure and then accepts its valid control. |
| [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs) | All 19 properties pass 100 generated scenarios each. TopTx declares the complete transaction total, counting every child once. P02 adds local/delegated total invariance with both allocation and release in every sample, followed by accepted ledger submissions for both modes. Coverage includes the derived own-change identity, measured 5/3 ADA examples, inter-body offsets, one-lovelace errors, wrong signs, delegated omission/double counting and real phase-2 failure. Every rejection is followed by its accepted control. |
| [DS-TX-ACCOUNTING-ATTRIBUTION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs) | All three generated properties pass. Independent originating changes establish each local or delegated share, delegation transfers the signed responsibility, and active/inactive explicit zero contributes zero. |
| [DS-TX-ACCOUNTING-BALANCE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs) | All 14 properties pass 100 generated scenarios each. Real ledger submissions cover the complete value equation, Store transfer counted once, cross-child funding, fee contributions, delegated operations, one-lovelace and native-asset mismatches, and the 10 + 2 ADA examples. N08 accepts a balanced proposal with genuine phase-2 failure; it does not impose ordinary balance on that path. |
| [DS-TX-AUTHORIZATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs) | Both generated properties pass. Alice alone funds Bob’s Store-backed output; Bob later spends it with no Alice signature. Replacing Bob’s witness with a valid Alice witness produces exactly the consuming body’s missing-key-witness failure, followed by acceptance of the valid control. Every sample covers standalone TopTx, local SubTx settlement and delegated SubTx settlement. |
| [DS-TX-SETTLEMENT-DESIGNATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs) | All 12 generated properties pass. Exact net releases require a TopTx output precisely when its attributed change is negative. Allocation and explicit-zero totals have no designation field. Both correct and incorrect designation branches are exercised with genuine phase-2 failure. |
| [DS-TX-SETTLEMENT-OUTPUT-INDEX](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs) | All 11 generated properties pass. Indices resolve only within the declaring body’s regular outputs, including first/last boundaries, empty child outputs, foreign parent/child/sibling sequences and collateral return. Ledger rejections require exactly the intended failure and then accept the unchanged control. |
| [DS-TX-SETTLEMENT-OUTPUT-COIN](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs) | All ten generated properties pass. Application ADA must cover the required share; external Store deposits cannot satisfy this bound. Boundary mutations preserve global balance and Store pricing. Both body levels, output forms and phase-2 outcomes are covered. Stronger refund-provenance guarantees remain open in A.3. |
| [DS-TX-MINIMUM-COIN](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs) | All five generated properties pass. Each sample covers both body levels and ordinary success or actual phase-2 failure. Fully funded Store outputs accept native assets with zero ADA, datum-only, reference-script-only and address-only content. Implicit outputs retain the independently priced minimum; one lovelace below produces exactly the owner’s minimum-coin failure, then the unchanged control is accepted. |
| [Inherited collateral rules](dijkstra-deposit-store-rules.md#ds-collateral-existing-rules) | Existing UTXO/UTXOW checks are linked individually. Five generic scope requirements and two authorization requirements remain explicit coverage gaps or incomplete Store-backed extensions; they are no longer counted as DepositStore executable placeholders. |
| [DS-COLLATERAL-FUNDING](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs) | All three generated contracts pass: accept sufficient application-coin funding, reject deficits despite released Store surplus, and derive collateral funding independently of ordinary declarations. Each sample covers nine input/return configurations on both real script outcomes. F01 also rejects zero application coins without a return, despite ample released deposits. P02 is an isolated calculation, not ledger acceptance. |
| [DS-COLLATERAL-TOTAL](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs) | Both generated contracts pass: an absent or exact input-minus-return total accepts; either one-lovelace mismatch rejects with exactly IncorrectTotalCollateralField. Store funding, surplus and absent-return cases run with both script outcomes. |
| [DS-COLLATERAL-ASSETS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AssetsSpec.hs) | Both generated contracts pass: preserve the exact native-asset map across implicit and Store-backed output forms; reject missing, extra, changed or unreturned assets. Funded Store returns also accept tokens with zero application ADA. Rejected variants retain sufficient deposit and fee funding. |
| [DS-STATE-UTXO](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs) | Five generated checks observe exact ordinary and collateral UTxO maps, successful and failing real scripts, reference-only inputs, inactive multi-SubTx operations on failure and overlapping ordinary/collateral input roles. |
| [DS-STATE-ALLOCATIONS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs) | Five generated checks observe complete ordinary/collateral allocation maps and their UTxO domains, retained noncanonical accepted sizes after state restoration and price changes, zero-price records from translated implicit sources, and inactive ordinary records on phase-2 failure. |
| [DS-STATE-BALANCE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs) | Four generated checks observe exact ordinary/collateral Store transfers with zero or positive surplus, release of the original noncanonical-byte allocation after restoration/repricing, and no ordinary transfer on phase-2 failure. Shared input roles consume their selected allocation once. |
| [DS-STATE-FEES](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs) | Two properties observe ordinary transaction fees and collateral coin fees plus released-deposit surplus, with unchanged treasury. The original Store and UTxO assertions now belong to their dedicated effects specs. |
| [DS-STATE-SOLVENCY](dijkstra-deposit-store-rules.md#ds-state-solvency) | The former lifecycle and invented-oracle checks are consolidated into Store consistency and balance. Production validateDepositStoreSolvency boundary tests remain an explicit separate validation gap; no rejection from an otherwise valid solvent state is fabricated. |
| [DS-STATE-CONSERVATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs) | Three independent-pot properties check correct counting (positive records, unallocated Store surplus and donations), ordinary conservation with local/delegated SubTxs, and collateral conservation after genuine script failure. |
| [DS-STATE-TRANSLATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/TranslationSpec.hs) | One generated property runs full Conway NewEpochState translation. It compares exact output references and semantic fields, existing monetary pots and account balances/deposits, and verifies an empty Store. It does not claim complete NewEpochState equality. |
| [DS-STATE-EPOCH](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs) | One generated property funds live Store records and crosses two actual ordinary epoch boundaries, first with exact backing then positive surplus. It checks the exact Store pair, epoch increment and unchanged parameters. |
| [DS-STATE-RECOVERY](dijkstra-deposit-store-rules.md#ds-state-recovery) | Inherited binary round trips cover Dijkstra UTxOState, EpochState and NewEpochState. Allocations P03 and Balance P03 additionally restore a reachable UTxOState and spend its retained noncanonical-byte allocation after repricing. Consensus rollback remains outside this ledger API. |
| [DS-STAKE](dijkstra-deposit-store-rules.md#ds-stake) | Stake tests are deferred; the rules and eight examples remain documented. |
| [DS-VOTING](dijkstra-deposit-store-rules.md#ds-voting) | Voting tests are deferred; the rule and one example remain documented. |

Historical pricing and parameter-change handling (`DS-PRICING-HISTORY`), Plutus context
projection, and the unresolved stronger settlement guarantee remain deferred. An agreed
rule awaiting an executable ledger check is distinct from a business question whose
semantics are still open. Representation and codec checks do not establish enforcement
of deposit accounting.

## LedgerEffects implementation on 23 October 2026

The revised hierarchy implements 21 generated effects checks:

| Responsibility | Checks | Observation |
| --- | ---: | --- |
| UTxO | 5 | Exact selected map, inactive ordinary/collateral paths, reference-only inputs and shared input roles. |
| Store / Allocations | 5 | Ordinary/collateral records, retained accepted sizes after restoration, zero-price records and inactive ordinary operations. |
| Store / Balance | 4 | Exact transfers, zero/positive surplus, historical release after restoration and inactive ordinary operations. |
| Fees | 2 | Ordinary fee or collateral fee plus released surplus; treasury unchanged. |
| Conservation | 3 | Correct actual-ADA counting, ordinary conservation and collateral conservation. |
| Lifecycle | 2 | Conway translation and two actual epoch transitions with exact backing then positive surplus. |

Each effect assertion follows a successful submission. Expected maps are derived
from the signed transaction and retained records, without calling production Store
update helpers. Translation compares semantic output fields and actual monetary
pots from generated Conway states; it does not assert full state equality.

The noncanonical-byte test exposed a production decoder defect: ordinary outputs
and collateral returns were decoded through unsized lenses, recalculating their
sizes from canonical encoding. A valid indefinite output map is one byte longer
than its canonical encoding, so the decoder understated its required allocation.
Both transaction levels and collateral returns now decode through sized raw
lenses, preserving the accepted byte count. Encoding is unchanged. Three focused
binary regressions cover those locations independently of the ledger fixtures.

The former rejection snapshot placeholder is not counted as implemented coverage.
`trySubmitTx` installs a new state only after success; a snapshot comparison after
rejection would mostly retest that helper. Consensus rollback and upstream
SubTx-script failure propagation remain outside these effects assertions.

| Verification | Result |
| --- | --- |
| Dijkstra test executable | Builds successfully with the decoder correction and all new specs. |
| Full DepositStore stream, seed `739231514` | **206 examples, 0 failures, no pending cases**; all 21 LedgerEffects properties pass 100 generated samples each. |
| Full-stream execution time | **266.7483 s** wall time; **444.3352 s** CPU time. |
| LedgerEffects execution time | **214.745 s**, summing the individual test durations in the full-stream run. |
| Accepted output-size regressions | **3 examples, 0 failures**, 100 samples each; **0.0174 s** wall time, **0.0291 s** CPU time. Both production and independent plain decoders are exercised. |
| Existing transaction round trips | **5 examples, 0 failures**, 100 samples each with `--qc-max-size=10`; **44.4036 s** wall time, **85.1395 s** CPU time. Covers `TxOut` and both annotating/plain `TxBody` and `Tx` decoders. |
| Formatting | All 17 changed or added Haskell files pass Fourmolu; `git diff --check` passes. |
| Documentation | All 21 LedgerEffects case anchors and chapter-3 source links checked; internal anchors, expand nesting and math delimiters checked. |

The four longest properties are Allocations P03 (**56.158 s**), Balance P03
(**56.567 s**), Translation N01 (**35.184 s**) and Epoch N01 (**38.552 s**).
These durations include 100 generated samples per property. The full log retains
each test's duration. Ctags were regenerated after the final code changes.

Compatibility checks target the existing `TxOut`, `TxBody` and `Tx` round trips,
using 100 samples with `--qc-max-size=10`. Earlier broad and default-size attempts
were interrupted during expensive state/body generation; neither is recorded as
a completed regression suite. The full DepositStore run and the new focused
decoder regressions use the default QuickCheck size.

Commands use `--seed 739231514 --format=specdoc --times --print-cpu-time --no-color`:

```sh
cabal build cardano-ledger-dijkstra:test:tests --offline --enable-tests --enable-benchmarks --jobs=2
tests --match '/Dijkstra/Era-specific spec/DepositStore/' --seed 739231514 --format=specdoc --times --print-cpu-time --no-color
tests --match '/Dijkstra/Era-specific spec/TxBody accepted output sizes/' --seed 739231514 --format=specdoc --times --print-cpu-time --no-color
tests --match '/Dijkstra/Era-specific spec/RoundTrip/Core Type Families/Tx' --qc-max-size=10 --seed 739231514 --format=specdoc --times --print-cpu-time --no-color
```

Here `tests` is the built executable at
`dist-newstyle/build/aarch64-osx/ghc-9.6.7/cardano-ledger-dijkstra-0.5.0.0/t/tests/build/tests/tests`.

Local evidence:

- Build: `/private/tmp/ds-ledger-effects-implementation-build8.log`
- Full DepositStore stream: `/private/tmp/ds-ledger-effects-implementation-full.log`
- Accepted output-size regressions: `/private/tmp/ds-ledger-effects-implementation-binary.log`
- Existing transaction round trips: `/private/tmp/ds-ledger-effects-implementation-tx-roundtrip-size10.log`
- Formatting: `/private/tmp/ds-ledger-effects-final-format.log`
- Ctags: `/private/tmp/ds-ledger-effects-final-tags.log`

## LedgerEffects contracts revised on 20 October 2026

This is a **specification and structure revision**. It introduces no new passing
behavioral test and changes no production rule or transaction-rule assertion.
The existing Fees property and its collateral UTxO/Store assertions remain intact.

| Responsibility | Current contracts | Implementation |
| --- | ---: | --- |
| Execution | 3 | Pending ordinary effects, collateral effects and rejected-state atomicity. |
| Store / Allocations | 1 | Pending independent record-map and live-output consistency observations. |
| Store / Balance | 1 | Pending exact pot transfer and preserved surplus. |
| Fees | 1 | Existing implemented property retained. |
| Conservation | 1 | Pending independent actual-pot total and production total projection. |
| Lifecycle / Translation | 1 | Pending complete Conway state migration. |
| Lifecycle / Epoch | 1 | Pending populated-Store preservation at an ordinary epoch boundary. |

The former **36 LedgerEffects entries** (one implemented, 35 fabricated failures)
become **nine contracts** (one implemented, eight pending). The full executable
outline therefore changes from 221 to 194 entries; its 186 implemented checks are
unchanged. `pendingWith` reports the missing observation honestly. These entries
are neither passing tests nor evidence of ledger defects.

Creation/removal, equal outputs at distinct references, unrelated and reference-only
outputs, overlapping input roles, local/delegated batches, zero-net changes, historic
recorded amounts and positive Store surplus remain scenario dimensions under the
exact transitions. No requirement is considered implemented merely by consolidation.

The rules document retains former anchors with a migration table. Generic snapshot
round trips refer to the inherited executable tests. The real defensive solvency
validator still needs focused boundary coverage, identified separately from accepted
ledger effects. Consensus rollback needs an owning integration/API before a test
can claim to exercise it.

| Verification | Result |
| --- | --- |
| Dijkstra test executable | Builds successfully after the module moves. |
| Full DepositStore stream, seed `739231514` | **194 examples, 0 failures, 8 pending**: all 186 implemented checks pass. |
| Execution time | **51.6269 s** wall time; 77.3002 s CPU time. |
| LedgerEffects rerun after clarifying Conservation's valid-state precondition | **9 examples, 0 failures, 8 pending**, in 2.3830 s wall time. |
| Documentation | Prior explicit anchors retained; internal links, file links and case source lines checked. |

The executable was run with `--times --print-cpu-time`; the log includes individual
test durations. Ctags were regenerated after the module moves.

Local evidence:

- Build: `/private/tmp/ds-ledger-effects-structure-build.log`
- Final rebuild: `/private/tmp/ds-ledger-effects-final-build.log`
- Test run: `/private/tmp/ds-ledger-effects-structure-regression.log`
- Final LedgerEffects run: `/private/tmp/ds-ledger-effects-final-contracts.log`
- Ctags: `/private/tmp/ds-ledger-effects-structure-tags.log`

## Store-specific collateral implemented on 20 October 2026

**Eight generated contracts pass, 100 samples per contract.** The mathematical
contract is visible in each test; the rules document uses matching formulas and
compact case tables. Existing inherited collateral tests remain unchanged and
are linked with their outstanding fixture extensions.

| Responsibility | Implemented contracts | Generated coverage |
| --- | ---: | --- |
| Funding | 3 | Allocate, reuse, release a surplus, mixed inputs, no return, zero-ADA Store return, exact fee boundaries and independence from ordinary declarations. |
| Optional total | 2 | Absent/exact total accepted; both one-lovelace mismatch directions rejected. |
| Native assets | 2 | Exact map, zero-ADA Store return, missing/extra/changed tokens and omitted return. |
| Fee effects | 1 | Both execution outcomes; exact fees, treasury, Store balance, allocation records and UTxO effects. |

Each funding sample covers **nine configurations × two real script outcomes**.
Native-asset samples cover five input/return combinations × two outcomes. Prices,
payload sizes, application coins and token quantities vary. A changed-price source
confirms that released deposits come from retained records, while new returns use
the current price; this does not implement epoch/governance repricing policy.
Funding F01 adds an unfunded no-return proposal with zero application coins and
ample recorded deposits, requiring exactly the existing funding failure.

The full regression retains **178 passing Tx examples** and the eight implemented
collateral-related contracts. The **35 remaining failures exactly match existing
LedgerEffects placeholders**; there is no unexpected failure. Input-role overlap,
positive unallocated Store surplus, initialization, recovery and the general state
lifecycle remain separate unfinished contracts. No inherited test or production
rule changed in this implementation.

The earlier “roughly 35 seconds” referred to **full-suite execution duration**.
Timing is execution evidence, not a test count or per-test delay.

**Full regression:** 221 examples, 186 pass, 35 known placeholders fail;
52.2257 s wall / 77.8274 s CPU. Each of the eight implemented contracts passes
100 generated samples. Seed: `739231514`.

After adding the no-return rejection branch, the affected Funding F01 property
was rerun: 100 samples pass, zero failures; 3.6963 s wall / 5.6486 s CPU.
Other executable contracts were unchanged. Compilation and formatting pass;
ctags are regenerated. The link audit preserves all 782 earlier explicit anchors
and verifies all eight current case links.

Local evidence:
`/private/tmp/ds-collateral-implementation-build.log`,
`/private/tmp/ds-collateral-implementation-regression.log`,
`/private/tmp/ds-collateral-implementation-regression-audit.json`,
`/private/tmp/ds-collateral-implementation-funding-final.log`,
`/private/tmp/ds-collateral-implementation-doc-audit.json` and
`/private/tmp/ds-collateral-implementation-tags.log`.

## Initial collateral scope alignment on 20 October 2026

The following records the earlier reorganization, before the eight contracts above
were implemented. Its counts and evidence describe that historical checkpoint.

This is a **coverage reorganization**, not new rule implementation. Existing
`TxOut` forms already express implicit and Store-backed collateral; no new
collateral declaration or production rule is introduced.

| Responsibility | Current owner | Coverage |
| --- | --- | --- |
| Existing collateral rules | [Inherited tests and gaps](dijkstra-deposit-store-rules.md#ds-collateral-existing-rules) | Direct source links distinguish inherited implementation tests from missing generic cases and Store-backed fixture extensions. |
| Deposit funding | [FundingSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs) | 19 examples: four implemented, 15 placeholders. Includes derivation from inputs/return and the no-redeemer Store control. |
| Optional total | [TotalSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs) | Six placeholders covering the existing input-minus-return equality in the presence of Store allocations/releases. |
| Native assets | [AssetsSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AssetsSpec.hs) | Three placeholders for the asset projection over Store-backed outputs. |
| Fee effects | [FeesSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs) | One existing implemented scenario, two placeholders moved from Surplus. |
| ADA conservation | [ConservationSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs) | Existing state contract includes the former mixed-collateral shortfall scenario and the collateral conservation equation. Still unimplemented. |

The registered count changes from **253 to 244**, with **183 implemented checks
unchanged** and **70 → 61 placeholders**. Seven generic requirements move to the
explicit documentation backlog; two collateral conservation placeholders merge
into the existing state conservation contract. **None of these nine removed
placeholders represents a newly passing test.** All five previously implemented
collateral checks remain: four in Funding, one moved to Fees.

Inherited tests are registered through Dijkstra → Conway → Babbage → Alonzo.
Their old fixtures primarily use implicit outputs. This inventory establishes
where coverage lives; it does not establish Store-backed compatibility or a fresh
passing result for the inherited suites. See the linked coverage table for the
remaining extensions.

**Regression:** 244 examples; **183 pass**, **61 deliberate placeholders fail**.
The failure-ID set exactly matches the preceding run after the documented moves
and consolidations; **no unexpected failures**. All 178 Tx examples and all five
previously implemented collateral scenarios pass. **32.5161 s wall / 45.6595 s CPU**;
seed `739231514`. Formatting and compilation pass; ctags are regenerated.

Local evidence: `/private/tmp/ds-collateral-scope-build.log`,
`/private/tmp/ds-collateral-scope-regression.log`,
`/private/tmp/ds-collateral-scope-regression-audit.json` and
`/private/tmp/ds-collateral-scope-tags.log`.

All 31 affected case links match the executable order and source IDs. All 782
previous explicit rule anchors are preserved; internal targets and linked files
resolve. Link audit: `/private/tmp/ds-collateral-scope-doc-audit.json`.

## Minimum coin implemented on 20 October 2026

**5 / 5 properties pass**, with 100 generated samples each. `MinimumCoinSpec`
replaces `ApplicationAssetsSpec`; the five case suffixes stay unchanged under
`DS-TX-MINIMUM-COIN`. Previous documentation anchors remain aliases.

| Case | Contract | Generated samples | Time |
| --- | --- | --- | --- |
| [DS-TX-MINIMUM-COIN-N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L47) | Native assets without ADA | Pass · 100 | 804 ms |
| [DS-TX-MINIMUM-COIN-N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L61) | Datum-only and reference-script-only outputs without assets | Pass · 100 | 1063 ms |
| [DS-TX-MINIMUM-COIN-N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L75) | Address-only Store output | Pass · 100 | 548 ms |
| [DS-TX-MINIMUM-COIN-N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L89) | Implicit output at its exact minimum | Pass · 100 | 506 ms |
| [DS-TX-MINIMUM-COIN-F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L98) | Implicit output one lovelace below its minimum | Pass · 100 | 645 ms |

Every sample covers **TopTx and SubTx × ordinary success and actual phase-2 failure**:
400 scenarios per property. N02 separately covers datum-only and reference-script-only
outputs in each sample: 800 scenarios. Total: **2,400 scenarios**. Prices, datum sizes,
application funding and native-asset quantities vary. Tokens are minted in an earlier
accepted transaction; every Store-backed output has an independently priced, fully
funded allocation explicitly declared in the spec.

For implicit outputs, solve `coin = coinsPerUTxOByte × (160 + encodedSize(output))`
using the final coin's encoded width. F01 moves one lovelace to a separate output,
re-signs without fixup and verifies that the required minimum, fee and encoded size
are unchanged. It requires exactly `BabbageOutputTooSmallUTxO` for TopTx or
`SubBabbageOutputTooSmallUTxO` for SubTx, including the submitted output and its minimum.
The original exact-minimum transaction is accepted afterward.

On the invalid phase-2 path, a genuinely failing V4 script and valid disjoint collateral
establish the real outcome. Ordinary outputs are validated but not created. Ordinary
success controls use key-controlled inputs; they do not claim successful script coverage.

**Focused run:** 5 examples, 0 failures; **3.5701 s wall / 5.3672 s CPU**.

**Full DepositStore run:** 253 examples; **183 passing**, **70 deliberate placeholders
failing**; **29.3928 s wall / 41.7483 s CPU**. The failure-ID set is exactly
the preceding 75 placeholders minus the five Application assets placeholders.
All **178 Tx examples** now pass; the remaining placeholders belong to Collateral
and Ledger effects. No unexpected failure occurred. Seed: `739231514`.

Build and formatting pass. Existing production output rules already enforce this
contract; no production rule changed. Rules, TOC, mathematical notation, source links
and semantic tags are aligned; ctags are regenerated.

Local evidence: `/private/tmp/ds-minimum-coin-build.log`,
`/private/tmp/ds-minimum-coin-targeted.log`,
`/private/tmp/ds-minimum-coin-regression.log`, and
`/private/tmp/ds-minimum-coin-regression-audit.json`.

## Authorization implemented on 20 October 2026

Two generated properties establish that the consumed output's spending authority
also authorizes its deposit release. Alice funds Bob's Store-backed output through
a real accepted transaction; a separate unrelated input supplies later fee funding.
The proposal has exact declarations, valid settlement and complete financial balance.

| Case | Contract | Generated samples | Time |
| --- | --- | --- | --- |
| [DS-TX-AUTHORIZATION-N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L51) | Bob spends without any Alice signature | Pass · 100 | 599 ms |
| [DS-TX-AUTHORIZATION-F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L73) | Alice’s valid signature cannot replace Bob’s; the original control is accepted | Pass · 100 | 497 ms |

Each sample exercises **all three forms**: standalone TopTx, a SubTx settling into
its own output, and a SubTx delegating its release to TopTx. That is **300 scenarios
per property**, with generated application amounts and deposit prices.

F01 requires exactly `MissingVKeyWitnessesUTXOW` for TopTx or
`SubMissingVKeyWitnessesUTXOW` for SubTx, containing only Bob's key hash. The replacement
witness signs the unchanged consuming body. A child-witness change re-signs only
its enclosing TopTx; the original inputs, amounts, declarations and settlement
remain unchanged. Witness count, transaction size and fee are preserved.

**Scope:** ordinary spending of key-controlled inputs with successful phase 2.
These properties do not exercise script authorization or collateral authorization.
Former N02 is incorporated into N01; former N03 is a cross-reference to the existing
reference-only Release N09 case. This consolidates four placeholders into two
implemented contracts; no new accounting case is claimed.

**Focused run:** 2 examples, 0 failures; **1.0976 s wall / 1.6789 s CPU**.

**Full DepositStore run:** 253 examples; **178 passing**, **75 deliberate placeholders
failing**; **28.1546 s wall / 39.3486 s CPU**. The failure-ID set equals the previous
79 placeholders minus the four replaced Authorization placeholders. No unexpected
failures or missing expected placeholder failures occurred. Seed: `739231514`.

Build and formatting passed. Authorization uses the existing spending-witness rules;
this implementation adds no production authorization rule. The business cases,
mathematical premises and source links are aligned in the rules document.

Local evidence: `/private/tmp/ds-authorization-build.log`,
`/private/tmp/ds-authorization-targeted.log`,
`/private/tmp/ds-authorization-regression.log`, and
`/private/tmp/ds-authorization-regression-audit.json`.

## Settlement requirements implemented on 20 October 2026

**33 / 33 settlement properties pass, with 100 generated scenarios each.** The
three relocated Accounting/Attribution properties also pass 100 scenarios each.
Baseline: `1d2aa2e3ff62cd7e0fd60c403811287f98335773` plus the current working tree.

| Module | Passing properties | Wall time | CPU time |
| --- | ---: | ---: | ---: |
| [Settlement/DesignationSpec.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs) | 12 / 12 | 2.3546 s | 3.3907 s |
| [Settlement/OutputIndexSpec.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs) | 11 / 11 | 2.9831 s | 4.2280 s |
| [Settlement/OutputCoinSpec.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs) | 10 / 10 | 1.8218 s | 2.6074 s |
| [Accounting/AttributionSpec.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs) | 3 / 3 | 0.5676 s | 0.8908 s |

The properties use real funding and ledger submissions, except the isolated
Designation P01, OutputIndex P01 and OutputCoin P01 boundary oracles and the two
Accounting attribution projections. Rejection cases require exactly the expected
settlement failure, not merely a failure somewhere in the transaction.

Output-coin mutations redistribute application ADA into another implicit output,
retain the Store-backed output's price and verify independent complete value balance.
This isolates the lower bound from accounting. It does not establish where an output's
fungible ADA originated. Phase-2 cases contain actual failing scripts and valid
collateral; they do not impose ordinary balance as a new phase-2-failure rule.

Production validation behavior is unchanged. Existing designation and output checks
are exported for isolated properties; the signed attribution expression extracted in
the preceding work remains shared by settlement and legacy balance.

All per-case times below cover 100 generated scenarios, including any funding,
signing and submission. They are test timings, not per-transaction benchmarks.
Seed: `739231514`.

| Module | Case | Contract | Time |
| --- | --- | --- | ---: |
| Designation | [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L47) | Designation follows TopTx's release share | 278 ms |
| Designation | [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L69) | SubTxs settle the entire release | 150 ms |
| Designation | [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L82) | Standalone TopTx settles its release | 113 ms |
| Designation | [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L93) | TopTx and SubTxs each settle a share | 156 ms |
| Designation | [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L106) | TopTx's share exceeds the transaction release | 139 ms |
| Designation | [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L120) | TopTx omits a required output | 108 ms |
| Designation | [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L131) | TopTx designates an unnecessary output | 149 ms |
| Designation | [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L144) | Net allocation, even though TopTx releases | 136 ms |
| Designation | [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L157) | Explicit-zero total, even though TopTx releases | 139 ms |
| Designation | [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L170) | Net release, while TopTx allocates | 140 ms |
| Designation | [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L183) | Valid designation when phase 2 fails | 420 ms |
| Designation | [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L199) | Invalid designation when phase 2 fails | 420 ms |
| OutputIndex | [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L59) | The index belongs to the declaring body | 217 ms |
| OutputIndex | [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L76) | The first missing own index is rejected | 325 ms |
| OutputIndex | [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L99) | A SubTx cannot select TopTx's output | 237 ms |
| OutputIndex | [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L120) | Collateral return is outside the ordinary output sequence | 336 ms |
| OutputIndex | [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L141) | A SubTx without outputs cannot settle locally | 172 ms |
| OutputIndex | [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L160) | The first and last own outputs are valid | 347 ms |
| OutputIndex | [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L174) | TopTx cannot select a SubTx's output | 234 ms |
| OutputIndex | [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L193) | A SubTx cannot select a sibling's output | 236 ms |
| OutputIndex | [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L214) | Valid output indices when phase 2 fails | 293 ms |
| OutputIndex | [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L228) | An invalid output index still fails when phase 2 fails | 450 ms |
| OutputIndex | [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L252) | A SubTx without outputs delegates its final release | 129 ms |
| OutputCoin | [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L43) | Output ADA must cover the required share | 266 ms |
| OutputCoin | [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L56) | Implicit output, one lovelace short | 143 ms |
| OutputCoin | [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L77) | Implicit output, exact amount | 148 ms |
| OutputCoin | [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L97) | Implicit output, extra ADA | 145 ms |
| OutputCoin | [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L117) | An external deposit cannot fill the ADA shortfall | 156 ms |
| OutputCoin | [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L140) | Store-backed output, exact application ADA | 156 ms |
| OutputCoin | [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L161) | TopTx's share is smaller than the transaction release | 165 ms |
| OutputCoin | [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L177) | Exact output ADA when phase 2 fails | 248 ms |
| OutputCoin | [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L197) | One lovelace short when phase 2 fails | 233 ms |
| OutputCoin | [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L219) | The transaction release is smaller than TopTx's share | 158 ms |
| Attribution | [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L39) | Local and delegated contributions determine TopTx's share | 284 ms |
| Attribution | [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L67) | Delegation moves the signed contribution to TopTx | 121 ms |
| Attribution | [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L98) | Explicit zero adds no delegated contribution | 161 ms |

**Full DepositStore regression:** 255 examples in 23.8771 s wall time /
33.9850 s CPU time. **176 implemented checks pass; 79 deliberate
placeholders fail.** The failures are exactly the previous 111 placeholders minus
the 32 settlement placeholders implemented here. No previously implemented test
regressed; no Settlement placeholders remain.

The rules document, executable order, tags and source links are aligned. Previous
anchors remain available. Formatting passes; ctags are regenerated.

Evidence:

- Build: `/private/tmp/ds-settlement-build.log`
- Targeted runs and per-test timings: `/private/tmp/ds-settlement-targeted-audit.json`
- Full suite: `/private/tmp/ds-settlement-regression.log`
- Regression comparison: `/private/tmp/ds-settlement-regression-audit.json`
- Documentation audit: `/private/tmp/ds-settlement-rules-audit.json`

## Attribution redistributed and implemented on 19 October 2026

**5 / 5 properties pass, with 100 generated scenarios each.** They preserve the six
old contracts without duplicating allocation-only total invariance. The implementation
baseline is `1d2aa2e3ff62cd7e0fd60c403811287f98335773` plus this working-tree change.

| Current test | Previous contract | Check | Result · scenarios | Time |
| --- | --- | --- | --- | ---: |
| [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX-P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L90) | Attribution P02 (total), N02 | Delegation preserves the required total; allocation and release, both modes accepted | Pass · 100 | 0.6703 s |
| [DS-TX-SETTLEMENT-PARTICIPATION-P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L39) | Attribution P01, N01 | Every declaration form has the independently expected local and TopTx shares | Pass · 100 | 0.2908 s |
| [DS-TX-SETTLEMENT-PARTICIPATION-P03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L67) | Attribution P02 (responsibility) | Local → delegated moves each signed contribution from SubTx to TopTx | Pass · 100 | 0.3038 s |
| [DS-TX-SETTLEMENT-PARTICIPATION-N09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L252) | Attribution N03 | A SubTx creates no outputs and delegates its final Store release; accepted | Pass · 100 | 0.3255 s |
| [DS-TX-SETTLEMENT-PARTICIPATION-N10](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L98) | Attribution N04 | Active and inactive explicit zero contribute zero locally and to TopTx; accepted | Pass · 100 | 0.3633 s |

Each time is the complete property run, including funding and its 100 scenarios.
Seed: `739231514`. The two delegation properties exercise allocation and release in
every generated sample. The per-form projection exercises all six declaration forms
in every sample, with independently varying amounts and TopTx operations.

P02/P03 in Participation compare actual production accounting observations with
independent expectations derived from priced outputs and recorded input deposits.
They isolate responsibility; they do not claim full ledger acceptance. The other
three properties submit real transactions. Preparation preserves the empty SubTx
output sequence in N09.

The previously duplicated TopTx attribution expression is now shared by settlement
validation and legacy self-balance through `attributedTopTxNetUTxODeposit`. Its
arithmetic and validation guards are unchanged. Tests observe that production
function rather than reconstructing the observed result in a test helper.

**Full DepositStore regression:** 255 examples in
20.3411 s wall time / 28.4566 s CPU time.
**144 implemented checks pass; 111 deliberate placeholders fail.** The failures
are exactly the previous 117 placeholders minus the six removed Attribution
placeholders. No previously implemented check regressed. The twelve existing
Participation selector cases remain unimplemented.

The business document, collapsible TOC, test order, numbering and source links are
aligned. All 731 previous anchors are retained. Formatting passes and ctags are
regenerated.

Evidence:

- Build: `/private/tmp/ds-attribution-build.log`
- Targeted results: `/private/tmp/ds-attribution-targeted-audit.json`
- Full regression: `/private/tmp/ds-attribution-regression.log`
- Result audit: `/private/tmp/ds-attribution-regression-audit.json`
- Documentation audit: `/private/tmp/ds-attribution-rules-audit.json`

## Balance implemented on 19 October 2026

**14 / 14 properties pass; no Balance placeholders remain.** Each property runs
100 generated scenarios. Negative variants require `ValueNotConservedUTxO` with
independently computed consumed and produced values, then accept the original
balanced control. All declarations remain exact, and mutations are re-signed
without another balancing fixup.

| Test | Contract exercised | Result · generated scenarios | Time |
| --- | --- | --- | ---: |
| [DS-TX-ACCOUNTING-BALANCE-P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L72) | Complete equation, including real native assets | Pass · 100 | 435 ms |
| [DS-TX-ACCOUNTING-BALANCE-P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L96) | Acceptance follows complete balance despite child imbalances | Pass · 100 | 276 ms |
| [DS-TX-ACCOUNTING-BALANCE-N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L117) | Net allocation funded exactly once | Pass · 100 | 217 ms |
| [DS-TX-ACCOUNTING-BALANCE-N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L137) | Net release available exactly once | Pass · 100 | 207 ms |
| [DS-TX-ACCOUNTING-BALANCE-N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L155) | One SubTx funds another | Pass · 100 | 176 ms |
| [DS-TX-ACCOUNTING-BALANCE-N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L168) | A SubTx contributes application ADA to TopTx fees | Pass · 100 | 157 ms |
| [DS-TX-ACCOUNTING-BALANCE-F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L181) | One-lovelace surplus and deficit rejected | Pass · 100 | 218 ms |
| [DS-TX-ACCOUNTING-BALANCE-F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L199) | Missing, extra and renamed native assets rejected | Pass · 100 | 336 ms |
| [DS-TX-ACCOUNTING-BALANCE-F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L219) | Exact delegated request without financial funding rejected | Pass · 100 | 181 ms |
| [DS-TX-ACCOUNTING-BALANCE-N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L234) | Equal delegated allocation and release accepted | Pass · 100 | 168 ms |
| [DS-TX-ACCOUNTING-BALANCE-N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L246) | 10 application ADA + 2 released ADA → 12 ADA output | Pass · 100 | 127 ms |
| [DS-TX-ACCOUNTING-BALANCE-N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L255) | 10 ADA output + 2 ADA fee contribution accepted | Pass · 100 | 139 ms |
| [DS-TX-ACCOUNTING-BALANCE-F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L265) | 10 ADA output without accounting for the 2 ADA release rejected | Pass · 100 | 156 ms |
| [DS-TX-ACCOUNTING-BALANCE-N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L280) | Balanced proposal with actual phase-2 failure accepted | Pass · 100 | 236 ms |

**Targeted run:** 3.0401 s wall time / 4.2442 s CPU time, seed `739231514`.
Times in the table cover all 100 scenarios of each property, including funding,
witness preparation and submissions. They are suite timings, not per-transaction
benchmarks.

**Full DepositStore regression:** 256 examples in 17.1658 s wall time /
24.3980 s CPU time. **139 implemented checks pass; 117 deliberate placeholders
fail.** The failure IDs are exactly the preceding 131 placeholders minus the
14 newly implemented Balance cases. No previously implemented check regressed.

The independent observer covers application inputs and outputs, native assets,
TopTx fees and the explicit Store total. Fixtures exclude certificates,
withdrawals, mint/burn, governance proposals, donations and direct deposits;
native assets are minted in a separate accepted funding transaction. N08 is an
acceptance control for genuine phase-2 failure, not a new conservation requirement
on that path. No production rule changed.

The executable descriptions now use mathematical implications with shared
notation and short human comments. The business document retains short headings,
formulas and the matching examples in the same order. Supporting functions remain
under `Core/Specs/Tx/Accounting/Balance` and `Core/Submission/Balance`.

Evidence:

- Build: `/private/tmp/ds-balance-final-build.log`
- Targeted run: `/private/tmp/ds-balance-tests.log`
- Full regression: `/private/tmp/ds-balance-regression.log`
- Result audit: `/private/tmp/ds-balance-regression-audit.json`
- Rules audit: `/private/tmp/ds-balance-rules-audit.json`

## Accounting hierarchy verified on 19 October 2026

This earlier checkpoint predates Balance implementation. Its counts are retained
as historical evidence; the completed Balance run is recorded immediately above.

`AccountingSpec` now registers `NetChangeSpec`, followed by `BalanceSpec`.
NetChange contains SubTx own-change checks and TopTx complete-total checks.
Balance replaces the former standalone transaction Conservation section and now
precedes Attribution. Collateral and ledger-state conservation remain separate.

| Accounting responsibility | Passing | Remaining placeholders |
| --- | ---: | ---: |
| NetChange / SubTx | 22 | 0 |
| NetChange / TopTx | 18 | 0 |
| Balance | 0 | 14 |
| **Total** | **40** | **14** |

All 40 NetChange properties pass **100 generated scenarios each**. The complete
DepositStore run reports **256 examples: 125 pass and 131 deliberate placeholders
fail**, in **15.0397 s wall time / 21.4217 s CPU time**, with seed `739231514`.
After normalizing the renamed tags and excluding the previously retired Conservation
F05, the case identities and failure set match the preceding complete run.
**No implemented check regressed.**

The moved cases retain their assertions and generators. Isolated amount predicates
and helpers now say `NetChange`; they do not claim to validate the broader Accounting
domain. NetChange applies on both phase-2 outcomes. Balance remains restricted to
valid phase 2, with N08 retained as an acceptance control for the failure path.
No production rule changed.

Compilation and formatting pass; ctags are regenerated. The Markdown, collapsible
TOC, numbering and source links follow the executable hierarchy, preserving previous
anchors. Dated results below keep their original scope.

Evidence:

- Build: `/private/tmp/ds-accounting-hierarchy-build.log`
- Full regression: `/private/tmp/ds-accounting-hierarchy-regression.log`
- Result audit: `/private/tmp/ds-accounting-hierarchy-regression-audit.json`
- Unchanged assertion audit: `/private/tmp/ds-accounting-hierarchy-code-audit.json`
- Documentation audit: `/private/tmp/ds-accounting-hierarchy-rules-audit.json`

## Declarations grouping verified on 19 October 2026

`Tx/DeclarationsSpec` now registers `Declarations/Grammar` followed by
`Declarations/Requirements`. Accounting follows Declarations. Case suffixes,
registration order, generators and assertions are unchanged.

| Declarations responsibility | Passing | Remaining placeholders |
| --- | ---: | ---: |
| Grammar | 21 | 0 |
| Requirements | 59 | 0 |
| **Total** | **80** | **0** |

The complete DepositStore run reports **257 examples: 125 pass and 132 deliberate
placeholders fail**, in **15.2643 s wall time / 21.6586 s CPU time**, with seed
`739231514`. The failing case IDs exactly match the preceding Accounting run.
Normalizing the renamed prefixes also preserves all 257 case identities and their
execution order. **No implemented check regressed.**

The Markdown hierarchy, numbering, source links and collapsible TOC follow the same
groups. Previous anchors remain valid, and mathematical contracts are unchanged.
Compilation and formatting checks pass; ctags are regenerated.

Evidence:

- Build: `/private/tmp/ds-declarations-grouping-build.log`
- Full regression: `/private/tmp/ds-declarations-grouping-regression.log`
- Case audit: `/private/tmp/ds-declarations-grouping-regression-audit.json`
- Documentation audit: `/private/tmp/ds-declarations-grouping-docs-audit.json`

## Accounting implementation verified on 19 October 2026

**40/40 properties pass**, with **100 generated scenarios per property**.
The targeted run took **7.2337 s wall time / 10.1195 s CPU time**, using seed
`739231514`.

| Module | Passing | Remaining placeholders |
| --- | ---: | ---: |
| SubTx | 22 | 0 |
| TopTx | 18 | 0 |

P01 in each module compares the isolated production amount validator with an
independent oracle. The other 38 properties submit transactions to the ledger.
Every failure case checks the specific accounting failure and subsequently accepts
its original valid control using the same inputs. TopTx N02 also derives its own
change from the actual signed parent and child declarations.

New scenarios create their sources through accepted funding transactions. Each
Store-backed source/output has a measured one-ADA deposit, with generated operation
counts and application ADA. Required allocations use an independent price formula;
required releases use the recorded input allocations. N03/N04 in TopTx measure
actual 5 ADA / 3 ADA totals. Translation cases exercise output conversion followed
by funding; they do not simulate a full hard-fork transition. Surplus fixtures move
ADA from reserves to the Store. Phase-2 cases use an actually failing script.

The production SubTx amount check was extracted from the existing accounting
validator, preserving its use in ledger validation. Both isolated amount validators
are exposed through the existing rules module.

All rows below passed 100 scenarios. Times are for the whole property, not one scenario.

### SubTx

| Case | Contract | Time |
| --- | --- | ---: |
| [P01](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-p01) | Each SubTx declares its own exact change | 280 ms |
| [N01](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-n01) | Exact own change, with any allocation and release combination | 186 ms |
| [F01](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f01) | Net allocation understated by one lovelace | 177 ms |
| [F02](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f02) | Net allocation overstated by one lovelace | 181 ms |
| [F03](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f03) | Net release understated by one lovelace | 180 ms |
| [F04](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f04) | Net release overstated by one lovelace | 181 ms |
| [F05](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f05) | Opposing SubTx errors cancel in the total | 244 ms |
| [N02](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-n02) | Equal own allocations and releases, explicit zero | 132 ms |
| [F06](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f06) | Explicit zero cannot replace a required allocation | 179 ms |
| [N03](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-n03) | Exact allocation requested from TopTx | 140 ms |
| [N04](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-n04) | Exact release delegated to TopTx | 139 ms |
| [N05](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-n05) | Released deposits, only implicit outputs | 125 ms |
| [F07](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f07) | Explicit zero cannot replace a required release | 189 ms |
| [N06](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-n06) | Another body offsets the SubTx release | 148 ms |
| [N07](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-n07) | An output without application assets still requires a deposit | 129 ms |
| [N08](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-n08) | A translated implicit input funds an exact allocation | 138 ms |
| [F08](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f08) | A translated implicit input does not excuse an inexact allocation | 158 ms |
| [F09](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f09) | Store surplus cannot increase a SubTx release | 179 ms |
| [F10](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f10) | A release cannot replace a required allocation | 182 ms |
| [F11](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f11) | An allocation cannot replace a required release | 179 ms |
| [N09](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-n09) | Exact SubTx declarations when phase 2 fails | 267 ms |
| [F12](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-subtx-f12) | An inexact SubTx declaration still fails before the collateral outcome | 443 ms |

### TopTx

| Case | Contract | Time |
| --- | --- | ---: |
| [P01](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-p01) | TopTx declares the exact transaction total | 95 ms |
| [N01](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-n01) | TopTx and SubTxs contribute to the total | 151 ms |
| [N02](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-n02) | TopTx's own change is derived from its total | 257 ms |
| [N03](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-n03) | 5 ADA allocated, 3 ADA released | 166 ms |
| [N04](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-n04) | 3 ADA allocated, 5 ADA released | 159 ms |
| [N05](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-n05) | Nonzero body changes produce a zero total | 157 ms |
| [F01](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-f01) | Standalone TopTx understates its net allocation by one lovelace | 136 ms |
| [F02](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-f02) | Standalone TopTx overstates its net allocation by one lovelace | 140 ms |
| [F03](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-f03) | Standalone TopTx understates its net release by one lovelace | 141 ms |
| [F04](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-f04) | Standalone TopTx overstates its net release by one lovelace | 127 ms |
| [F05](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-f05) | Explicit zero cannot replace a nonzero total | 152 ms |
| [F06](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-f06) | A nonzero declaration cannot replace a zero total | 235 ms |
| [F07](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-f07) | TopTx declares the opposite direction | 158 ms |
| [N06](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-n06) | TopTx releases while SubTxs allocate | 167 ms |
| [N07](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-n07) | TopTx allocates while SubTxs release | 168 ms |
| [N08](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-n08) | An exact total remains valid when phase 2 fails | 207 ms |
| [F08](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-f08) | An inexact total is rejected even when phase 2 fails | 244 ms |
| [F09](dijkstra-deposit-store-rules.md#ds-tx-accounting-net-change-toptx-f09) | A delegated change belongs in the total exactly once | 192 ms |

### Regression

The complete DepositStore run reports **257 examples: 125 pass and 132 deliberate
placeholders fail**, in **14.8294 s wall time / 21.1905 s CPU time**. Compared with
the previous run, exactly the 36 newly implemented Accounting cases disappear from
the failure set. **No implemented check regressed.**

The remaining placeholders belong to other transaction responsibilities, collateral
and ledger effects; Accounting has none. The business specification keeps the same
40-case reading order, with updated source links and retained historical anchors.
The Cabal build and formatting checks pass; ctags are regenerated.

Evidence:

- Build: `/private/tmp/ds-accounting-build-3.log`
- Targeted properties: `/private/tmp/ds-accounting-targeted.log`
- Full DepositStore regression: `/private/tmp/ds-accounting-business-regression.log`
- Source-link audit: `/private/tmp/ds-accounting-links.json`

## Exactness scope and contracts verified on 19 October 2026

`Accounting/SubTxSpec` checks each SubTx's own net change; `Accounting/TopTxSpec`
checks the complete transaction total. All 40 cases retain their behavior after
migration. Each now has a short human description, a signed mathematical contract
and the same explanation in the business specification. The TopTx own-change
diagnostic moved from the former Contribution N02 to TopTx N02.

| Exactness module | Implemented checks passing | Deliberate placeholders | Total |
| --- | ---: | ---: | ---: |
| SubTx | 0 | 22 | 22 |
| TopTx | 4 | 14 | 18 |

The four implemented property bodies are unchanged. Each passed 100 generated cases:

| TopTx case | Declaration mutation | Time |
| --- | --- | ---: |
| F01 | Net allocation understated by one lovelace | 121 ms |
| F02 | Net allocation overstated by one lovelace | 109 ms |
| F03 | Net release understated by one lovelace | 106 ms |
| F04 | Net release overstated by one lovelace | 112 ms |

The complete DepositStore run registered **257 examples: 89 passed, 168 deliberate
placeholders failed**, in **9.1290 s wall time / 12.7818 s CPU time**, with seed
`739231514`. After applying the documented tag migration, the failing case IDs
exactly match the preceding Operations-completion run; no implemented check regressed.
The executable and Markdown case order, titles, formulas and source links agree.
The Cabal build and Fourmolu checks passed; ctags were regenerated.

Evidence:

- Build: `/private/tmp/ds-exactness-formulas-build.log`
- Tests: `/private/tmp/ds-exactness-formulas-business-tests.log`
- Tag mapping: `/private/tmp/ds-exactness-tag-mapping.json`
- Navigation: `/private/tmp/ds-exactness-formulas-tags.log`

## Operations completion verified on 19 October 2026

All six remaining Operations placeholders now submit generated transactions to
the real ledger. The existing case IDs and document order are unchanged.

| Newly implemented case | Coverage | Generated scenarios | Targeted time |
| --- | --- | ---: | ---: |
| Operations P01 | Independent source/output forms per body at zero deposit price; omit every active body's field; accept declared control. Ordinary success and real phase-2 failure per scenario. | 100 | 735 ms |
| Allocation F06 | Production Conway output conversion, accepted funding, omitted declaration rejected, original control accepted. | 100 | 124 ms |
| Allocation N09 | TopTx and one SubTx allocate from implicit inputs; exact child contribution and aggregate parent declaration accepted. | 100 | 115 ms |
| Release N09 | One to five funded Store-backed reference inputs; absent ordinary declaration accepted. | 100 | 89 ms |
| Release N10 | Store-backed collateral input only, return only, or both; each placement with actual script success and failure. | 100 × 6 submissions | 737 ms |
| Release F06 | TopTx and children release deposits; omitted parent field rejected for its own operations, original control accepted. | 100 | 193 ms |

P01 resolves each body's own ordinary inputs against the captured UTxO and
inspects its own proposed output constructors. Funded Store-backed sources retain
zero-valued Store records; implicit sources have none. The oracle never infers
activity from a nonzero amount or calls the production presence predicate.
Every omission variant requires the responsible body's specific failure, so a
child-to-parent dependency failure alone cannot make the test pass.

Allocation F06 tests **output conversion followed by funding**, not a full
hard-fork state transition. P01 complements the positive-price scenarios; its
zero-price context deliberately isolates structural presence from accounting.

| Required declarations group | Passed | Remaining placeholders |
| --- | ---: | ---: |
| Operations P01 | 1 | 0 |
| Allocation | 17 | 0 |
| Release | 16 | 0 |
| Zero net change | 14 | 0 |
| SubTx declarations | 11 | 0 |
| **Total** | **59** | **0** |

The targeted Required declarations run passed **59 examples in 7.7679 s**
(11.3110 s CPU), including all **48 Operations cases**. The full DepositStore
regression ran **257 examples in 8.4298 s** (12.2270 s CPU): **89 passed and 168
existing placeholders failed**. Compared with the preceding run, exactly the six
implemented case IDs disappear from the failure set; **zero unexpected failures**.
Seed: `739231514`.

The pure declaration expectation, isolated-validator adapter and expected failure
now live in `Core.Specs.Tx.Declaration`. `SubTxDeclarationsSpec` retains its business
expressions and assertions; its 11 checks pass in the targeted run above.
Build, formatting and source/document link checks pass; ctags were regenerated.

Evidence: `/private/tmp/ds-operations-completion-build.log`,
`/private/tmp/ds-operations-completion-tests.log`,
`/private/tmp/ds-operations-completion-business-tests.log` and
`/private/tmp/ds-operations-completion-result-audit.json`.

## SubTx zero net change verified on 19 October 2026

Twelve new properties extend the standalone pair to real SubTx Store operations.
The funding helper records each source deposit through the ledger, then recreates
that source as an output owned by the same body. Before the spec adds declarations,
it independently checks **allocated deposits = recorded released deposits > 0**
for every active body. Inactive children have neither operation.

Each rejection removes one declaration from a signed valid control, re-signs
without fixup, and checks the specific missing-declaration failure. The unchanged
control is then accepted. Multi-child failures exercise every active child position.

| Case | Scenario and result | Generated cases | Targeted time |
| --- | --- | ---: | ---: |
| N01 | Standalone TopTx with explicit zero is accepted. | 100 | 298 ms |
| F01 | Standalone TopTx without its declaration is rejected. | 100 | 131 ms |
| N02 | One zero-net SubTx and TopTx both declare zero; accepted. | 100 | 121 ms |
| F02 | The active child omits its declaration; rejected with `SubMissingUTxODepositDeclaration`. | 100 | 140 ms |
| F03 | TopTx has no own operations but omits its field despite the child's zero; rejected with `MissingTopTxUTxODepositDeclaration`. | 100 | 141 ms |
| N03 | Two to five children each have positive operations with zero net change; all declare zero and are accepted. | 100 | 156 ms |
| F04 | Each active child's declaration is omitted in turn; every variant is rejected. | 100 | 368 ms |
| N04 | Only active children declare zero; implicit-only siblings remain undeclared; accepted. | 100 | 155 ms |
| F05 | Each active child omits its field among inactive siblings; rejected. | 100 | 287 ms |
| N05 | TopTx and every child independently have zero net change and declare zero; accepted. | 100 | 171 ms |
| F06 | Active TopTx omits its field; rejected with its own `MissingUTxODepositDeclaration`. | 100 | 226 ms |
| N06 | Actual script failure, valid collateral and explicit zero at every active body; accepted as phase-2-invalid. | 100 | 288 ms |
| F07 | Each child's field is omitted from that phase-2-invalid proposal; rejected. | 100 | 501 ms |
| F08 | TopTx's field is omitted from that phase-2-invalid proposal; rejected with its own missing-declaration failure. | 100 | 293 ms |

The targeted run passed **14 properties in 3.2845 s** (4.5923 s CPU), with
**100 generated scenarios per property**. The phase-2 cases use a failing TopTx
Plutus V4 script. The omitted-declaration variants are rejected in phase 1;
their accepted controls exercise the actual phase-2 failure path.

The full DepositStore regression ran **257 examples in 6.2133 s** (8.9750 s CPU):
**83 passed; the same 174 existing placeholders failed; zero unexpected failures**.
The failing IDs exactly match the preceding Required declarations run.
Required declarations now contains **53 passing cases and six placeholders**.
Seed: `739231514`. Build and formatting checks pass; ctags were regenerated.

Scope: each active SubTx has one funded store-backed input and one recreated
output, under unchanged deposit prices. These tests check submission outcomes;
they do not claim multiple-input-per-child, price-change or Store-effect coverage.

For the targeted command, use
`--match DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE` with
`--seed 739231514 --format=specdoc --times --print-cpu-time`.

Evidence: `/private/tmp/ds-subtx-zero-net-change-build.log`,
`/private/tmp/ds-subtx-zero-net-change-tests.log`,
`/private/tmp/ds-subtx-zero-net-change-business-tests.log` and
`/private/tmp/ds-subtx-zero-net-change-result-audit.json`.

## Required declarations rename verified on 19 October 2026

`RequiredDeclarationsSpec` now introduces **When a body must declare its deposit
change**. The folder, composer, imports, Cabal registration, semantic tags and
business-document navigation use `RequiredDeclarations` and
`DS-TX-REQUIRED-DECLARATIONS`. Validator names for checking field presence remain
unchanged. Assertions and all 245 business case positions are unchanged after
mapping the tag prefix.

Build succeeded. The complete DepositStore run took **3.9538 s** (5.8137 s CPU):
**71 passed; 174 existing placeholders failed; zero unexpected failures**.
Within Required declarations, **41 cases passed and six placeholders remain**.
Seed: `739231514`.

All 47 Required declarations cases retain matching source/document order.
The document preserves its 407 prior anchors and adds 58 current anchors;
all 504 internal links resolve. Source links, formatting and ctags were refreshed.

Evidence: `/private/tmp/ds-required-declarations-build.log`,
`/private/tmp/ds-required-declarations-business-tests.log`,
`/private/tmp/ds-required-declarations-case-mapping.json` and
`/private/tmp/ds-required-declarations-result-audit.json`.

## Presence narrative verified on 19 October 2026

Declaration presence now follows two obligations: each body proposing Store
operations supplies its own declaration field; an explicit SubTx declaration
also requires TopTx to declare. TopTx's amount still describes the complete
transaction, while each SubTx describes its own contribution.

`ScopeSpec` has been removed. All nine examples remain, with the following IDs;
old document anchors still resolve to their new locations.

| Former Scope case | Current case | Responsibility |
| --- | --- | --- |
| N01 | Allocation N06 | SubTx outputs are not TopTx's own outputs. |
| N02 | Allocation N07 | Collateral return is outside ordinary allocation presence. |
| N03 | Allocation N08 | Input identifiers are not created outputs; no UTxO lookup is exercised. |
| F01 | Allocation F07 | A child's declaration cannot supply the allocating parent's field. |
| F02 | Allocation F08 | A parent's declaration cannot supply the allocating child's field. |
| N06 | Allocation N09 | Both bodies allocate without releases; each declares, with TopTx declaring the total. |
| N04 | Release N09 | Reference access does not consume the deposit. |
| N05 | Release N10 | Collateral operations do not require an ordinary declaration. |
| F03 | Release F06 | A child's declaration cannot supply the releasing parent's field. |

The former generic N06 placeholder is now an explicit both-body allocation
scenario. Existing Release N07 covers TopTx and SubTxs releasing deposits.
`DependencySpec` is now `SubTxDeclarationsSpec`, tagged
`DS-TX-REQUIRED-DECLARATIONS-SUBTX-DECLARATIONS`. Its C03 group names **offsetting SubTx
contributions**, distinguishing two declaring children from the standalone
body in `ZeroNetChangeSpec`.

| Presence section | Passed | Remaining placeholders |
| --- | ---: | --- |
| Combined operations invariant | 0 | P01 |
| Allocation | 15 | F06, N09 |
| Release | 13 | N09, N10, F06 |
| Zero net change | 2 | None |
| SubTx declarations | 11 | None |
| **Total** | **41** | **6** |

Build succeeded. The full DepositStore run executed **245 examples in 4.0823 s**
(6.0417 s CPU): **71 passed; 174 existing placeholders failed**. After applying the
case-ID migration, failures match the prior placeholder inventory exactly:
**zero unexpected failures**. Seed: `739231514`. Use the full-suite command in the
vocabulary verification below to reproduce this run.

All 47 Presence cases have the same reading order in source and documentation.
The 502 internal specification links resolve across 407 unique explicit anchors;
source links were refreshed. Formatting checks pass and ctags were regenerated.
Evidence: `/private/tmp/ds-presence-narrative-build.log`,
`/private/tmp/ds-presence-narrative-business-tests.log`,
`/private/tmp/ds-presence-narrative-tag-mapping.json` and
`/private/tmp/ds-presence-narrative-result-audit.json`.

## Zero net change verified on 19 October 2026

`ZeroNetChangeSpec` makes **zero net change ≠ no Store operations** explicit.
Both properties submit standalone TopTxs. Before declaration construction, support
checks that recorded released deposits are positive and equal the independently
priced allocations. Generated outputs include store-backed-only and mixed forms.

| Case | Ledger result | Generated cases | Targeted time |
| --- | --- | ---: | ---: |
| N01 | Explicit zero accepted. | 100 | 299 ms |
| F01 | Missing declaration rejected; original declared control accepted. | 100 | 133 ms |

The targeted run passed **2 examples in 0.4338 s** (0.6911 s CPU). The complete
DepositStore regression ran **245 examples in 4.2772 s** (6.0974 s CPU): **71 passed;
174 existing placeholders failed**. Failing case IDs match the prior placeholder
inventory exactly; there are **zero unexpected failures**. Seed: `739231514`.

Build and checks used the same commands as the vocabulary verification below;
for the targeted run, use `--match DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-ZERO-NET-CHANGE`.
Evidence: `/private/tmp/ds-zero-net-change-build.log`,
`/private/tmp/ds-zero-net-change-tests.log`,
`/private/tmp/ds-zero-net-change-business-tests.log` and
`/private/tmp/ds-zero-net-change-result-audit.json`.

The 36 Operations cases have the same reading order in the executable specs and
the business document. All 492 internal specification links resolve. This pair
covers the ordinary path for a standalone TopTx; it does not establish SubTx or
phase-2-failure coverage for equal allocations and releases.

## Store operations vocabulary verified on 19 October 2026

The Dijkstra test target builds with `Operations/Allocation`, `Operations/Release`
and `Operations/Scope`, including their renamed Core support and production presence
validators. Validation conditions, failure constructors and assertions are unchanged.

The complete DepositStore run executed **243 examples in 3.7568 s** (5.3762 s CPU):
**69 passed; 174 failed at existing `False` placeholders**. The failing case IDs
match the source placeholder inventory exactly: **zero unexpected failures**.

| Operations section | Passed | Remaining placeholders |
| --- | ---: | --- |
| Combined invariant | 0 | P01 |
| Allocation | 10 | F06 |
| Release | 13 | None |
| Scope | 5 | N04, N05, N06, F03 |

All 13 Release properties passed 100 generated cases each. Their measured times,
in executable reading order, were:

| Case | Time |
| --- | ---: |
| N01 | 103 ms |
| N02 | 102 ms |
| N03 | 105 ms |
| F01 | 105 ms |
| F02 | 108 ms |
| N04 | 343 ms |
| F03 | 340 ms |
| N05 | 143 ms |
| F04 | 329 ms |
| N06 | 141 ms |
| N07 | 158 ms |
| N08 | 210 ms |
| F05 | 446 ms |

Seed: `739231514`. Reproduce from a `nix develop` shell:

```sh
cabal build cardano-ledger-dijkstra:test:tests --offline --enable-tests --enable-benchmarks --jobs=2
dijkstra_test_binary="$(cabal list-bin cardano-ledger-dijkstra:test:tests --offline)"
"$dijkstra_test_binary" --match '/Dijkstra/Era-specific spec/DepositStore/' \
  --seed 739231514 --format=specdoc --times --print-cpu-time --no-color
```

The test command exits with status 1 while the deliberate placeholders remain.
Evidence: `/private/tmp/ds-store-operations-build-final.log`,
`/private/tmp/ds-store-operations-business-tests.log` and
`/private/tmp/ds-store-operations-result-audit.json`.

The 34 Operations cases have the same reading order in code and documentation.
All 485 internal specification links resolve; source line references were refreshed,
38 former rule/case anchors remain usable, formatting checks pass and ctags were
regenerated.

## Standalone allocation pair on 16 October 2026

The declaration DSL remains visible in `AllocationSpec`. Generated transactions create
one to five outputs, with at least one store-backed output and varying application
amounts and output positions. Preparation preserves those outputs and uses only
implicit inputs without recorded Store allocations.

| Check | Result | Wall time |
| --- | --- | --- |
| Allocation N05: declare the exact allocation | 100 generated cases passed | 79 ms |
| Allocation F02: remove the declaration, then submit the original control | 100 generated cases passed | 95 ms |
| Complete AllocationSpec | 10 passed; F06 remains the deliberate translated-input placeholder | 0.3994 s |
| ReleaseSpec regression after sharing submission matchers | 13 properties passed, 100 generated cases each | 3.4546 s |

F02 requires `MissingUTxODepositDeclaration` among the ledger failures. It removes
only the declaration from a funded, signed transaction and re-signs without
rebalancing. Submitting the original transaction afterwards must succeed. The tests
assert submission outcomes; they do not add Store-effect assertions.

Both runs used seed `739231514`, `--format=specdoc --times --print-cpu-time --no-color`.
CPU time was 0.6032 s for Allocation and 4.7863 s for Release. The Dijkstra test target
build and formatting checks passed. No full-suite rerun was performed for this pair.

## Leios rebase verification on 15 October 2026

Rebased onto `origin/leios-prototype` at `8a15ddc07ef35868aef459af3ae71445c9beae94`.
The updated dependency pins are retained. Compatibility adjustments preserve the new
input getter, snapshot constructors and phase-2 conservation guard, restore the original
UTxO binding needed by SubTx deposit validation, and adapt new output-constructor calls.

The Dijkstra test target, ledger-core and Shelley test targets, ledger API and ledger-state
libraries all build with tests and benchmarks enabled.

| Check | Result | Wall time |
| --- | --- | ---: |
| Complete DepositStore outline | **68 implemented checks passed**; all 174 failures match the previous deliberate placeholders by case ID. | 2.8709 s |
| Declaration fixture | Passed 100 generated cases. | 0.1300 s |
| Dijkstra golden/codec checks | 128 passed, including `hashTx` and predicate failures. | 0.6407 s |
| TxInfo | 41 passed. | 0.0628 s |
| CDDL/Huddle | 115 passed initially; one generator exhausted its discard allowance, then passed 100 cases with the allowance raised from 10 to 20. | 49.8328 s + 0.0879 s retry |
| StrictlyPositiveCoin | All five checks passed. | 0.0073 s |
| DepositStore codec | Passed 100 generated cases. | 0.0595 s |
| Shelley UTxOState | Roundtrip and six-field encoding compatibility each passed 100 cases. | 0.0441 s |
| Dijkstra UTxOState | Passed 100 generated cases, maximum size 10. | 218.4197 s |
| Dijkstra EpochState and NewEpochState | Both passed 10 cases, maximum size 3. | 46.4823 s |
| Upstream Dijkstra regressions | **238 passed; 27 failed** in the batch script checks described below. | 11.5674 s |

These are observed run times, not benchmarks; some checks ran concurrently with compilation
or other checks. All runs used seed `739231514`. The initial EpochState run was stopped
before completion and is not counted; the smaller completed run is reported explicitly.
The first direct golden invocation lacked Cabal's data-directory environment variable;
the table reports the rerun against the repository's existing golden files.

### Upstream batch script failures

The 27 failures exercise behavior deliberately removed by upstream commit
[`d93c65469`](https://github.com/IntersectMBO/cardano-ledger/commit/d93c654699c8f10c883a625168f65dd387abc695),
which was already our pre-rebase base. Its commit message records an ungated consensus
change and defers restoration until protocol-version gating is available:

- 26 cases expect TopTx to evaluate or collect errors from child Plutus scripts.
- One case expects the execution-unit limit to include child budgets. Its fixture also
  expects explicitly supplied child budgets to survive fixup.

The relevant upstream behavior and assertions are unchanged by this rebase. This
attribution comes from source comparison and the original implementation/revert history;
pristine upstream was not separately built and executed. These failures are distinct
from the 174 intentional DepositStore placeholders. The overall suite is **not green**.

Run evidence is in `/private/tmp/leios-rebase-20261015/`, including `build.log`,
`support-build.log`, `deposit-store-tests.log`, `deposit-store-audit.json`,
`dijkstra-regressions.log` and the individual codec/state logs. Direct execution of the
Dijkstra binary uses `cardano_ledger_dijkstra_datadir="$PWD/eras/dijkstra/impl"` for
golden files. The CDDL retry uses `--qc-max-discard=20`; assertions are unchanged.

## Release verification on 13 October 2026

**Result:** 13 examples passed, zero failures. Elapsed time: **1.7767 seconds**;
CPU time: **2.5868 seconds**, excluding compilation. N01, N02 and the six new multi-SubTx properties each
passed **100 generated cases**.

All case identifiers below use the `DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-RELEASE-` prefix and follow
[ReleaseSpec's registration order](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs).
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

Only Release was rerun for this extension. The current **242 / 68 / 174** inventory
means total examples / implemented checks / intentional placeholders; it is not a new
complete-suite result. Earlier build, regression and codec evidence below retains its
original scope.

Local evidence: `/private/tmp/ds-multi-spending-tests.log`. Durations are the values
printed by the runner; it did not print individual durations for F01 or F02.

To run the current Release cases with individual timings and the same seed, from
the repository root after building:

```sh
dijkstra_test_binary="$(cabal --config-file=/private/tmp/ds-structure-cabal.config list-bin cardano-ledger-dijkstra:test:tests --offline)"
"$dijkstra_test_binary" \
  --match DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-RELEASE \
  --seed 739231514 --format=specdoc --times --print-cpu-time --no-color
```

The complete outline was enumerated with `--dry-run`: **242 registered examples**.
This checks registration without running their assertions. Documentation checks resolve
all **330 TOC links** and **242 case source links**, including the 13 Release cases in
runtime order. After the Grammar presentation update, its **21 cases** remain linked
in the same order through numbered table rows. Pandoc renders the **102 display-math
blocks** without warnings. These documentation checks do not rerun the tests.

## Initial recorded DepositStore implementation verified on 13 October 2026

ReleaseSpec now submits real transactions. Funding creates each input's allocation;
release queries read those recorded amounts from `UTxOState`. No model state is installed,
and neither standalone acceptance property calls `pendingWith`.

| Check | Result | Evidence |
| --- | --- | --- |
| Release N01 | Passed 100 generated cases | Standalone TopTx, all output forms, exact signed net declaration, real allocations and balance changes. |
| Release N02 | Passed 100 generated cases | Implicit-only outputs receive consumed application ADA plus the full recorded release; fees are funded separately. |
| Release N03/F01/F02/N04/F03 | All five passed | Local SubTx release, missing declarations, ordinary effects excluded on phase-2 failure, rejection leaves ledger state unchanged. |
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
At this checkpoint, `--match DS-TX-REQUIRED-DECLARATIONS-OPERATIONS-RELEASE` selected seven completed
release cases; the latest selection above contains 13.

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
| ReleaseSpec | 5 passed, 2 pending, 0 failures |
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

## Earlier release-presence run on 13 October 2026

The initial six [ReleaseSpec cases](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs)
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

`validateTopTxReleaseDeclarationPresence` and `validateSubTxReleaseDeclarationPresence`
resolve only their body's ordinary inputs against the original UTxO. Their ledger
hooks run on both phase-2 outcomes and are not marked static. They reuse the existing
missing-own-declaration failures; `TxIn` and ledger state representations are unchanged.

**Build:** `cardano-ledger-dijkstra:test:tests` succeeded offline with tests and benchmarks enabled.
**Seed:** `739231514`.

| Executed suite | Examples | Failures | Pending |
| --- | ---: | ---: | ---: |
| ReleaseSpec | 6 | 0 | 0 |
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
`Adapter/Tx/Declarations/Grammar/Fixture/SubTx/Gen.hs`.

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
[TopTxSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs)
followed by
[SubTxSpec](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs).
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
| Existing Presence checks | 25 passed: nine Allocation, five Scope and eleven Dependency checks. |
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

The 37 implemented business checks comprise **12 Grammar, nine Allocation, five Scope
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
nine Allocation checks, five Scope checks and 11 Dependency checks. This remains an
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
Tx → Presence → Operations → Allocation expanded down to the test links. Indentation is
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
| Historical DS-TX-001 creation (current Allocation) | 14 | 0 |
| Historical DS-TX-009 declaration dependency (current SubTxDeclarations and separate technical fixture) | 12 | 0 |
| Predicate-failure codec goldens: UTXO tags 24 and 25, SUBUTXO tag 11 | 3 | 0 |
| Dijkstra UTXO | 19 | 0 |
| Dijkstra SUBUTXO | 30 | 0 |
| Dijkstra LEDGER | 3 | 0 |
| **Total** | **81** | **0** |

### Allocation presence evidence

**Historical rule identifier:** `DS-TX-001`.

These checks now live in [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs)
including its cases for own outputs and required declaration fields.

Seven properties each passed 100 generated cases, and seven ledger scenarios passed.
The properties cover declaration presence across explicit forms and the body's own
regular-output scope. Nested SubTx outputs and collateral return do not become TopTx's
own regular outputs. The ledger scenarios use implicit-only acceptance controls and
reject missing TopTx or SubTx declarations on both phase-2 outcomes, checking the exact
failure and unchanged state after rejection.

The [declaration validators](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/DepositStore/Declaration.hs)
are `validateTopTxAllocationDeclarationPresence` and
`validateSubTxAllocationDeclarationPresence`. Their domain failure is
`MissingBodyUTxODepositDeclaration` in `DepositStoreOutputDeclarationFailure`.
Ledger integration exposes `MissingUTxODepositDeclaration` in UTXO (CBOR tag 25) and
`SubMissingUTxODepositDeclaration` in SUBUTXO (CBOR tag 11).

These checks establish allocation-triggered declaration presence. They do not establish
correct deposit amounts, funding, settlement or Store state changes. The accepted
ledger controls do not create store-backed outputs; an isolated validator accepting
an explicit zero is not evidence that a Store allocation is funded.

### Dependency evidence

**Historical rule identifier:** `DS-TX-009`.

The 11 protocol checks now live in [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs);
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
- Before the DS-TX-001 allocation-presence validators and ledger hooks were enabled, the original
  **13-example RED run had seven expected failures**: two presence properties and five
  ledger scenarios expected rejection but received acceptance. Both implicit-only
  ledger acceptance controls passed. This earlier suite predates the implemented
  14-example creation slice and is retained as historical evidence of the missing checks.

Future verification records should name their code checkpoint and actual run results.
Business cases and required behavior remain in the business specification.
