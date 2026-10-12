# Dijkstra DepositStore verification record

**Updated:** 12 October 2026

**Verification baseline:** `1dd45a7a2`; the results below include the DepositStore structural reorganization committed with this record.

**Retained historical evidence:** recorded 9 October 2026 at code checkpoint `c8760684f`.

This record separates implementation progress and executed-test evidence from the
[DepositStore business specification](dijkstra-deposit-store-rules.md). Current rule
references use semantic tags matching the executable hierarchy. Numeric tags below
identify historical runs only; their original observations and dates remain distinct
from the new structural verification.

## Current implementation status

The reorganized [executable outline](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStoreSpec.hs)
registers **189 business examples: 25 implemented checks and 164 deliberately failing
placeholders**. A separate [technical fixture check](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/DepositStoreFixtureSpec.hs)
is registered under `Test infrastructure` → `DepositStore fixtures`, outside the business
specification and without a domain rule tag. Organizing, renaming and splitting assertions does not implement their
protocol behavior. Spending-triggered declaration presence, deposit amounts, funding,
settlement and Store state accounting remain pending.

The prior outline had 162 placeholders. Two composite requirements now have separate
assertions: collateral key control versus native-asset conservation, and preserving
Store surplus versus rejecting an unrelated surplus release. These splits account for
the increase to 164; no placeholder was skipped or marked pending.

| Semantic responsibility and executable spec | Current implementation or verification |
| --- | --- |
| [DS-PRICING](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/PricingSpec.hs) | Fixed-policy price enforcement and its examples remain deliberate placeholders. |
| [DS-TX-GRAMMAR](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/GrammarSpec.hs) | Declaration interfaces and amount bounds exist through checked construction and decoding. The ledger-level explicit-zero interpretation check remains a placeholder. |
| [DS-TX-PRESENCE-ACTIVITY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/ActivitySpec.hs) | The combined creation-or-spending invariant remains a placeholder; the implemented creation slice is separated below. |
| [DS-TX-PRESENCE-ACTIVITY-CREATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs) | Nine examples have implemented checks. The translated-input missing-declaration example remains a placeholder. |
| [DS-TX-PRESENCE-ACTIVITY-SPENDING](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/SpendingSpec.hs) | Four spending-triggered declaration examples remain placeholders. |
| [DS-TX-PRESENCE-ACTIVITY-SCOPE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs) | Five creation-scope examples have implemented checks. Four complete scope and ownership examples remain placeholders. |
| [DS-TX-PRESENCE-DEPENDENCY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs) | All 11 protocol examples have implemented checks. Fixture cardinality is verified separately under test infrastructure. |
| [DS-TX-EXACTNESS-CONTRIBUTION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs) | Exact per-body contributions, final releases, delegated contribution amounts and rejection of unrelated surplus releases remain placeholders. |
| [DS-TX-EXACTNESS-NETTING](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/NettingSpec.hs) | Exact batch net-change checks remain placeholders. |
| [DS-TX-ATTRIBUTION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AttributionSpec.hs) | Local and delegated responsibility checks remain placeholders. |
| [DS-TX-CONSERVATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs) | DepositStore integration into complete-batch financial conservation remains unverified; its examples are placeholders. |
| [DS-TX-AUTHORIZATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AuthorizationSpec.hs) | Existing spending authorization applies; Store release integration examples remain placeholders. |
| [DS-TX-SETTLEMENT-PARTICIPATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs) | TopTx settlement interface exists; ledger participation enforcement remains pending. |
| [DS-TX-SETTLEMENT-DESTINATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/DestinationSpec.hs) | Settlement index and owning-body checks remain placeholders. |
| [DS-TX-SETTLEMENT-COVERAGE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/CoverageSpec.hs) | Agreed destination coin bounds remain placeholders. The stronger settlement guarantee is still open. |
| [DS-TX-APPLICATION-ASSETS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ApplicationAssetsSpec.hs) | Store-backed outputs bypass implicit minimum-coin checks; the retained output-content examples remain placeholders. Exact deposit enforcement is tracked separately. |
| [DS-COLLATERAL-SCOPE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ScopeSpec.hs) | Collateral trigger examples remain placeholders. |
| [DS-COLLATERAL-AUTHORIZATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/AuthorizationSpec.hs) | Preservation of collateral key-control checks remains a placeholder. |
| [DS-COLLATERAL-FUNDING](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs) | Collateral funding, shortfall and minimum-fee examples remain placeholders under the fixed pricing policy. |
| [DS-COLLATERAL-SURPLUS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/SurplusSpec.hs) | Fee-pot destination and treasury exclusion checks remain placeholders. |
| [DS-COLLATERAL-TOTAL](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TotalSpec.hs) | Supplied total-collateral exactness examples remain placeholders. |
| [DS-COLLATERAL-SETTLEMENT](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/SettlementSpec.hs) | Derived collateral Store settlement examples remain placeholders. |
| [DS-COLLATERAL-CONSERVATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ConservationSpec.hs) | Collateral ADA and native-asset conservation examples remain placeholders. |
| [DS-STATE-EXECUTION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ExecutionSpec.hs) | Ordinary, accepted phase-2-failure and rejection effects remain placeholders. |
| [DS-STATE-ALLOCATIONS](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs) | Live output allocation records, release amounts and obligation changes remain placeholders. |
| [DS-STATE-BALANCE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/BalanceSpec.hs) | Actual Store balance movement and preservation of ordinary surplus remain placeholders. |
| [DS-STATE-SOLVENCY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/SolvencySpec.hs) | Resulting-state Store solvency and fixed-policy epoch examples remain placeholders. |
| [DS-STATE-CONSERVATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ConservationSpec.hs) | Including Store ADA once in total monetary conservation remains a placeholder. |
| [DS-STATE-INITIALIZATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/InitializationSpec.hs) | Implicit-output translation exists; Store initialization and pot-preservation examples remain placeholders. |
| [DS-STATE-RECOVERY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/RecoverySpec.hs) | Serialization, restoration and rollback examples remain placeholders. |
| [DS-STAKE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs) | Exclusion of Store deposits under existing staking rules remains unverified; all examples are placeholders. |
| [DS-VOTING](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/VotingSpec.hs) | Exclusion of Store deposits from voting weight remains a placeholder. |

Historical pricing and parameter-change handling (`DS-PRICING-HISTORY`), Plutus context
projection, and the unresolved stronger settlement guarantee remain deferred. An agreed
rule awaiting an executable ledger check is distinct from a business question whose
semantics are still open. Representation and codec checks do not establish enforcement
of deposit accounting.

## Verification on 12 October 2026

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
Further Collateral and State adapters are introduced when their scenarios need them.

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
`DepositStore fixtures`, carries no domain `DS-*` tag, and is not included in the 189
business cases.

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

The current homes are [DS-TX-PRESENCE-ACTIVITY-CREATION](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs)
and [DS-TX-PRESENCE-ACTIVITY-SCOPE](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs).

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

The 11 protocol checks now live in [DS-TX-PRESENCE-DEPENDENCY](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs);
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
