# Dijkstra DepositStore verification record

**Recorded:** 9 October 2026

**Code checkpoint:** `c8760684f`

This record separates implementation progress and test evidence from the
[DepositStore business specification](dijkstra-deposit-store-rules.md). The results
below were recorded earlier and carried forward when the documentation was separated.
No tests were rerun for these documentation edits. Statuses describe this checkpoint;
an agreed rule is not necessarily implemented or verified.

## Implementation status by rule

The transaction declaration interfaces and codecs exist. The ledger implements
DS-TX-009 declaration presence and the creation part of DS-TX-001. Spending-triggered
declaration presence, deposit amounts, funding and Store state accounting remain
pending. The [executable outline](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStoreSpec.hs)
assembles 21 rule modules; a module's presence does not establish its rule's correctness.

| Rule and executable spec | Business decision | Implementation or verification at this checkpoint |
| --- | --- | --- |
| [DS-TX-001](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationSpec.hs) | Agreed | Creation presence enforced for each body's own regular outputs; 14 focused examples passed. Spending-triggered validation and nine full-rule assertions remain pending. |
| [DS-TX-002](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/NettingSpec.hs) | Agreed | Batch net-change accounting enforcement pending. |
| [DS-TX-003](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ExactAccountingSpec.hs) | Agreed | Exact per-body deposit accounting enforcement pending. |
| [DS-TX-004](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ValueConservationSpec.hs) | Agreed | DepositStore integration into TopTx financial balance pending. |
| [DS-TX-005](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/FinalReleaseSpec.hs) | Agreed | Release enforcement when leaving store-backed outputs pending. |
| [DS-TX-006](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/TopTxSettlementSpec.hs) | Agreed | TopTx settlement interface implemented; ledger enforcement pending. |
| [DS-TX-007](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/SettlementOutputsSpec.hs) | Destination checks and existing SubTx imbalance preserved; stronger settlement semantics open | Enforcement pending. The stronger settlement guarantee remains deferred until clarified. |
| [DS-TX-008](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ExplicitZeroSpec.hs) | Agreed | Interface implemented; amount bounds enforced by construction and decoding. Ledger rules pending. |
| [DS-TX-009](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DeclarationDependencySpec.hs) | Agreed | Declaration presence enforced in TopTx UTXO; all 12 focused examples passed. No placeholders in this spec. |
| [DS-TX-010](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/DelegationSpec.hs) | Agreed | Delegated-contribution validation pending. |
| [DS-TX-011](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ReleaseAuthoritySpec.hs) | Agreed | Existing spending authorization applies; Store integration pending. |
| [DS-TX-012](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ApplicationAssetsSpec.hs) | Agreed | Store-backed outputs bypass implicit minimum-coin checks. Deposit enforcement and property tests pending. |
| [DS-COLL-001](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ValidationSpec.hs) | Both output variants must be supported | Enforcement pending. |
| [DS-COLL-002](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/AccountingSpec.hs) | Agreed for a fixed pricing policy | Collateral deposit surplus/shortfall enforcement pending. |
| [DS-COLL-003](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TotalCollateralSpec.hs) | Agreed | Total-collateral declaration enforcement pending. |
| [DS-COLL-004](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TransitionSpec.hs) | Agreed | Derived collateral Store settlement enforcement pending. |
| [DS-STORE-001](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Store/SolvencySpec.hs) | Agreed | Store solvency enforcement pending. |
| DS-STORE-002 | Historical pricing must be recoverable; parameter-change handling deferred | Implementation pending; repricing verification deferred. |
| [DS-STORE-003](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Store/PricingSpec.hs) | Agreed for a fixed pricing policy | Output-size-based deposit enforcement pending. |
| [DS-STORE-004](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Store/ConwayTransitionSpec.hs) | Agreed | Implicit-output translation exists; DepositStore state initialization pending. |
| [DS-STORE-005](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Store/LiveUTxOSpec.hs) | Agreed | Consistency enforcement for live UTxOs, retained deposit amounts and Store balance pending. |
| DS-PLUTUS-001 | Compatibility with all supported Plutus versions is the target | Context projection implementation and verification deferred. |
| [DS-STAKE-001](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs) | Exclude Store capacity deposits from stake and voting weight in the current prototype | Verification pending. |

The remaining **162 assertions deliberately fail as placeholders**, including nine
under DS-TX-001. Those nine include nominal controls for TopTx spending, SubTx spending
and both active bodies supplying their own declarations. The missing generators,
independent reference model and ledger scenarios still need implementation. Deferred
pricing, Plutus projection and stronger settlement semantics are distinct from agreed
rules awaiting implementation.

## Recorded focused results

These focused runs and retained regression results total **81 examples, zero failures**.
They do not represent a passing run of the entire DepositStore outline, whose
placeholder assertions deliberately fail.

| Run | Examples | Failures |
| --- | ---: | ---: |
| DS-TX-001 creation | 14 | 0 |
| DS-TX-009 declaration dependency | 12 | 0 |
| Predicate-failure codec goldens: UTXO tags 24 and 25, SUBUTXO tag 11 | 3 | 0 |
| Dijkstra UTXO | 19 | 0 |
| Dijkstra SUBUTXO | 30 | 0 |
| Dijkstra LEDGER | 3 | 0 |
| **Total** | **81** | **0** |

### DS-TX-001 creation evidence

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

### DS-TX-009 dependency evidence

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
