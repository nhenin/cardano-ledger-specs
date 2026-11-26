# Dijkstra ledger rules for minimum-ADA and deposit-backed outputs

[Verification record](verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/README.md)

The *UTxO Deposit versus UTxO Minimum ADA* proposal describes two ways to back an output's storage. A minimum-ADA output carries its reserve in its own value. For a deposit-backed output, the ledger accounts for the deposit separately.

## How the documents fit together

The [domain model](chapters/domain-model.md) defines the amounts used by the [transaction rules](chapters/transaction-rules.md). A transaction's [deposit declaration](chapters/transaction-rules.md#ds-tx-declarations) is one part of those checks. [Ledger effects](chapters/ledger-effects.md) describes how the accepted outcome updates state, and [derived distributions](chapters/derived-distributions.md) describes how that state contributes to stake and voting power.

For example, an input with 1.6 ADA of embedded reserve can fund a new output requiring a 2 ADA external deposit. The [net-change rule](chapters/transaction-rules.md#ds-tx-accounting-net-change) requires `Allocate 0.4 ADA`, while the [Store balance](chapters/ledger-effects.md#ds-state-balance) increases by 2 ADA. [Appendix D](chapters/appendices.md#net-change-test-cases) lists the SubTx and TopTx exactness cases. The separate [verification record](verification.md#signed-backing-change-for-mixed-output-forms--24-november-2026) gives the test results for this mixed-output example and the [verification contents](verification.md#table-of-contents) list the other runs.

## Table of contents

| Chapter | Scope |
| --- | --- |
| [1. Domain model](#1-domain-model) | Output forms, Store records and deposit calculation |
| [2. Transaction rules](#2-transaction-rules) | TopTx and SubTx declarations, accounting, authorization, settlement, minimum coin and collateral |
| [3. Ledger effects](#3-ledger-effects) | Changes to UTxOs, Store allocations and fees on success or phase-2 failure |
| [4. Derived distributions](#4-derived-distributions) | Stake and voting power |
| [Appendices](#appendices) | Open design questions, tag migration, code references and net-change test cases |
| [Verification record](#verification-record) | Test coverage and results by date |

<a id="1-domain-model" name="1-domain-model"></a>

<details open>
  <summary><strong><a href="chapters/domain-model.md">1. Domain model</a></strong></summary>
  <dl><dd>
    <div><a href="chapters/domain-model.md#section-1">1.1 Outputs</a></div>
    <div><a href="chapters/domain-model.md#section-1-1">1.2 DepositStore</a></div>
    <div><a href="chapters/domain-model.md#section-1-4">1.3 Transaction bodies</a></div>
    <details>
      <summary><a href="chapters/domain-model.md#ds-pricing">1.4 Deposit calculation</a></summary>
      <dl><dd>
        <div><a href="chapters/domain-model.md#ds-pricing-p01">1.4.1 P01 - Price each created output</a></div>
        <div><a href="chapters/domain-model.md#ds-pricing-n01">1.4.2 N01 - Count distinct native assets</a></div>
        <div><a href="chapters/domain-model.md#ds-pricing-n02">1.4.3 N02 - Price an applied collateral return</a></div>
        <div><a href="chapters/domain-model.md#ds-pricing-n03">1.4.4 N03 - Measure datum and reference script payloads</a></div>
        <div><a href="chapters/domain-model.md#ds-pricing-n04">1.4.5 N04 - Vary the declaration independently</a></div>
        <div><a href="chapters/domain-model.md#ds-pricing-n05">1.4.6 N05 - Preserve the price across ADA encoding boundaries</a></div>
        <div><a href="chapters/domain-model.md#ds-pricing-n06">1.4.7 N06 - Keep a min-ADA reserve inside its output</a></div>
      </dd></dl>
    </details>
  </dd></dl>
</details>

<a id="2-transaction-rules" name="2-transaction-rules"></a>

<details open>
  <summary><strong><a href="chapters/transaction-rules.md">2. Transaction rules</a></strong></summary>
  <dl><dd>
    <details open>
      <summary><a href="chapters/transaction-rules.md#ds-tx">2.1 Tx</a></summary>
      <dl><dd>
        <details>
          <summary><a href="chapters/transaction-rules.md#ds-tx-declarations">2.1.1 TopTx and SubTx deposit declarations</a></summary>
          <dl><dd>
            <details>
              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar">2.1.1.1 Grammar</a></summary>
              <dl><dd>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx">2.1.1.1.1 TopTx</a></summary>
                  <dl><dd>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-amounts">2.1.1.1.1.1 Amounts</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-p01">2.1.1.1.1.1.1 P01 - Positive amounts survive encoding</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f01">2.1.1.1.1.1.2 F01 - Zero operation amount</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f12">2.1.1.1.1.1.3 F12 - Negative operation amount</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f13">2.1.1.1.1.1.4 F13 - Overflowing operation amount</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-absence">2.1.1.1.1.2 Absence</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-n03">2.1.1.1.1.2.1 N03 - Absence remains distinct from zero</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-forms">2.1.1.1.1.3 Forms</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-n05">2.1.1.1.1.3.1 N05 - Every TopTx declaration form</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f06">2.1.1.1.1.3.2 F06 - Funding request in TopTx</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-structure">2.1.1.1.1.4 Structure</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f02">2.1.1.1.1.4.1 F02 - Malformed declarations</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-destinations">2.1.1.1.1.5 Destinations</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f04">2.1.1.1.1.5.1 F04 - Malformed release settlements</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f14">2.1.1.1.1.5.2 F14 - Negative output index</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f15">2.1.1.1.1.5.3 F15 - Overflowing output index</a></div>
                      </dd></dl>
                    </details>
                  </dd></dl>
                </details>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx">2.1.1.1.2 SubTx</a></summary>
                  <dl><dd>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-amounts">2.1.1.1.2.1 Amounts</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-p02">2.1.1.1.2.1.1 P02 - Positive amounts survive encoding</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f07">2.1.1.1.2.1.2 F07 - Zero operation amount</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f08">2.1.1.1.2.1.3 F08 - Negative operation amount</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f09">2.1.1.1.2.1.4 F09 - Overflowing operation amount</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-absence">2.1.1.1.2.2 Absence</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-n04">2.1.1.1.2.2.1 N04 - Absence remains distinct from zero</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-forms">2.1.1.1.2.3 Forms</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-n06">2.1.1.1.2.3.1 N06 - Every SubTx declaration form</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-structure">2.1.1.1.2.4 Structure</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f03">2.1.1.1.2.4.1 F03 - Malformed declarations</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-destinations">2.1.1.1.2.5 Destinations</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f05">2.1.1.1.2.5.1 F05 - Malformed release targets</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f10">2.1.1.1.2.5.2 F10 - Negative output index</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f11">2.1.1.1.2.5.3 F11 - Overflowing output index</a></div>
                      </dd></dl>
                    </details>
                  </dd></dl>
                </details>
              </dd></dl>
            </details>
            <details>
              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements">2.1.1.2 Requirements</a></summary>
              <dl><dd>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations">2.1.1.2.1 Operations</a></summary>
                  <dl><dd>
                    <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-p01">2.1.1.2.1.1 P01 - Every body requiring a Store operation declares</a></div>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation">2.1.1.2.1.2 Allocation</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n01">2.1.1.2.1.2.1 N01 - Every explicit declaration satisfies allocation presence</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n02">2.1.1.2.1.2.2 N02 - Absence satisfies allocation presence for empty or implicit-only own outputs</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f01">2.1.1.2.1.2.3 F01 - Missing declaration fails allocation presence at every own-output position</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n03">2.1.1.2.1.2.4 N03 - accepts a TopTx creating only min-ADA outputs without a declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n04">2.1.1.2.1.2.5 N04 - accepts a SubTx creating only min-ADA outputs without either body's declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n05">2.1.1.2.1.2.6 N05 - Standalone TopTx, exact allocation declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f02">2.1.1.2.1.2.7 F02 - Standalone TopTx, allocation without a declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f03">2.1.1.2.1.2.8 F03 - rejects a SubTx creating a deposit-backed output without its own declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f04">2.1.1.2.1.2.9 F04 - rejects a TopTx creating a deposit-backed output without its own declaration even when phase 2 fails</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f05">2.1.1.2.1.2.10 F05 - rejects a SubTx creating a deposit-backed output without its own declaration even when phase 2 fails</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f06">2.1.1.2.1.2.11 F06 - rejects a missing own declaration when spending a translated min-ADA output to create deposit-backed outputs</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n06">2.1.1.2.1.2.12 N06 - SubTx outputs do not trigger TopTx allocation presence</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n07">2.1.1.2.1.2.13 N07 - Collateral return does not trigger allocation presence</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n08">2.1.1.2.1.2.14 N08 - Reference and collateral input identifiers do not trigger allocation presence</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f07">2.1.1.2.1.2.15 F07 - A SubTx declaration cannot satisfy TopTx allocation presence</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f08">2.1.1.2.1.2.16 F08 - TopTx zero cannot satisfy its allocating SubTx's declaration requirement</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n09">2.1.1.2.1.2.17 N09 - TopTx and SubTx allocate deposits, each with an exact declaration</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release">2.1.1.2.1.3 Release</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n01">2.1.1.2.1.3.1 N01 - Standalone TopTx, any output form</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n02">2.1.1.2.1.3.2 N02 - Standalone TopTx, only min-ADA outputs</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n03">2.1.1.2.1.3.3 N03 - One SubTx releases its deposit into its own output</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f01">2.1.1.2.1.3.4 F01 - Standalone TopTx, release without its own declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f02">2.1.1.2.1.3.5 F02 - SubTx release without its own declaration, despite TopTx declaring</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n04">2.1.1.2.1.3.6 N04 - Phase 2 fails with valid declarations</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f03">2.1.1.2.1.3.7 F03 - Missing release declaration in a phase-2-invalid proposal</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n05">2.1.1.2.1.3.8 N05 - Several SubTxs release their deposits</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f04">2.1.1.2.1.3.9 F04 - One SubTx releasing deposits omits its declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n06">2.1.1.2.1.3.10 N06 - Only some SubTxs release Store deposits</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n07">2.1.1.2.1.3.11 N07 - TopTx and several SubTxs release deposits</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n08">2.1.1.2.1.3.12 N08 - Phase 2 fails with several proposed SubTx releases</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f05">2.1.1.2.1.3.13 F05 - One SubTx declaration is missing in a phase-2-invalid proposal</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n09">2.1.1.2.1.3.14 N09 - Standalone TopTx, reference-only Store access</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n10">2.1.1.2.1.3.15 N10 - Standalone TopTx, collateral-only Store operations</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f06">2.1.1.2.1.3.16 F06 - A SubTx declaration cannot satisfy TopTx release presence</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change">2.1.1.2.1.4 Zero net change</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n01">2.1.1.2.1.4.1 N01 - Standalone TopTx, equal allocations and releases with explicit zero</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f01">2.1.1.2.1.4.2 F01 - Standalone TopTx, equal allocations and releases without a declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n02">2.1.1.2.1.4.3 N02 - One SubTx replaces its deposit with explicit zero</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f02">2.1.1.2.1.4.4 F02 - One active SubTx omits its declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f03">2.1.1.2.1.4.5 F03 - TopTx omits the declaration required by its child</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n03">2.1.1.2.1.4.6 N03 - Several SubTxs each replace their deposits</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f04">2.1.1.2.1.4.7 F04 - One of several active SubTxs omits its declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n04">2.1.1.2.1.4.8 N04 - Only some SubTxs replace Store deposits</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f05">2.1.1.2.1.4.9 F05 - One active SubTx omits its declaration among inactive siblings</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n05">2.1.1.2.1.4.10 N05 - TopTx and several SubTxs each replace their deposits</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f06">2.1.1.2.1.4.11 F06 - Active TopTx omits its own declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n06">2.1.1.2.1.4.12 N06 - Phase 2 fails with explicit zero at every active body</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f07">2.1.1.2.1.4.13 F07 - One SubTx declaration is missing in a phase-2-invalid proposal</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f08">2.1.1.2.1.4.14 F08 - TopTx's own declaration is missing in a phase-2-invalid proposal</a></div>
                      </dd></dl>
                    </details>
                  </dd></dl>
                </details>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations">2.1.1.2.2 SubTx declarations</a></summary>
                  <dl><dd>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c01">2.1.1.2.2.1 TopTx requirement</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c01-p01">2.1.1.2.2.1.1 P01 - SubTx declarations require TopTx's declaration</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02">2.1.1.2.2.2 Absence and explicit zero</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-n01">2.1.1.2.2.2.1 N01 - accepts absent declarations at both levels</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-n02">2.1.1.2.2.2.2 N02 - accepts explicit zero at both levels</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-n03">2.1.1.2.2.2.3 N03 - accepts TopTx zero without a SubTx declaration</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-f01">2.1.1.2.2.2.4 F01 - rejects SubTx zero without a TopTx declaration</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c03">2.1.1.2.2.3 Offsetting SubTx contributions</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c03-n01">2.1.1.2.2.3.1 N01 - passes declaration presence with TopTx declaring the zero net amount</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c03-f01">2.1.1.2.2.3.2 F01 - rejects an absent TopTx declaration despite the zero net amount</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c04">2.1.1.2.2.4 Local and delegated accounting</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c04-n01">2.1.1.2.2.4.1 N01 - passes declaration presence with TopTx zero for every explicit SubTx form</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c04-f01">2.1.1.2.2.4.2 F01 - rejects an absent TopTx declaration for every explicit SubTx form</a></div>
                      </dd></dl>
                    </details>
                    <details>
                      <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c05">2.1.1.2.2.5 Phase-2 failure</a></summary>
                      <dl><dd>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c05-n01">2.1.1.2.2.5.1 N01 - accepts zero declarations at both levels on the phase-2 failure path</a></div>
                        <div><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c05-f01">2.1.1.2.2.5.2 F01 - rejects SubTx zero without a TopTx declaration on the phase-2 failure path</a></div>
                      </dd></dl>
                    </details>
                  </dd></dl>
                </details>
              </dd></dl>
            </details>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/transaction-rules.md#ds-tx-accounting">2.1.2 Accounting</a></summary>
          <dl><dd>
            <details>
              <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-net-change">2.1.2.1 Net change</a></summary>
              <dl><dd>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-net-change-subtx">2.1.2.1.1 SubTx</a></summary>
                  <dl><dd>
                    <div><a href="chapters/appendices.md#subtx-net-change-test-cases">Appendix D.1 SubTx net-change cases</a></div>
                  </dd></dl>
                </details>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-net-change-toptx">2.1.2.1.2 TopTx</a></summary>
                  <dl><dd>
                    <div><a href="chapters/appendices.md#toptx-net-change-test-cases">Appendix D.2 TopTx net-change cases</a></div>
                  </dd></dl>
                </details>
              </dd></dl>
            </details>
            <details>
              <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-attribution">2.1.2.2 Attribution</a></summary>
              <dl><dd>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-attribution-p01">2.1.2.2.1 P01 - Local and delegated contributions determine TopTx's share</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-attribution-p02">2.1.2.2.2 P02 - Delegation moves the signed contribution to TopTx</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-attribution-n01">2.1.2.2.3 N01 - Explicit zero adds no delegated contribution</a></div>
              </dd></dl>
            </details>
            <details>
              <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-balance">2.1.2.3 Balance</a></summary>
              <dl><dd>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-p01">2.1.2.3.1 P01 - The transaction conserves value when phase 2 is valid</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-p02">2.1.2.3.2 P02 - Complete balance determines acceptance</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n01">2.1.2.3.3 N01 - Fund a net allocation once</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n02">2.1.2.3.4 N02 - Use a net release once</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n03">2.1.2.3.5 N03 - One SubTx funds another</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n04">2.1.2.3.6 N04 - A SubTx funds TopTx fees</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-f01">2.1.2.3.7 F01 - One-lovelace deficit or surplus</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-f02">2.1.2.3.8 F02 - Native-asset quantity or identity mismatch</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-f03">2.1.2.3.9 F03 - An exact delegated allocation lacks funding</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n05">2.1.2.3.10 N05 - Equal delegated allocations and releases</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n06">2.1.2.3.11 N06 - Ten input ADA plus two released ADA</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n07">2.1.2.3.12 N07 - Released ADA contributes to TopTx fees</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-f04">2.1.2.3.13 F04 - Released ADA cannot disappear</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n08">2.1.2.3.14 N08 - Balanced proposal, failed phase 2</a></div>
              </dd></dl>
            </details>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/transaction-rules.md#ds-tx-authorization">2.1.3 Authorization</a></summary>
          <dl><dd>
            <div><a href="chapters/transaction-rules.md#ds-tx-authorization-n01">2.1.3.1 N01 - Bob spends an output funded by Alice</a></div>
            <div><a href="chapters/transaction-rules.md#ds-tx-authorization-f01">2.1.3.2 F01 - Alice's signature cannot replace Bob's</a></div>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/transaction-rules.md#ds-tx-settlement">2.1.4 Settlement</a></summary>
          <dl><dd>
            <details>
              <summary><a href="chapters/transaction-rules.md#ds-tx-settlement-designation">2.1.4.1 Designation</a></summary>
              <dl><dd>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-p01">2.1.4.1.1 P01 - Designation follows TopTx's release share</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n01">2.1.4.1.2 N01 - SubTxs settle the entire release</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n02">2.1.4.1.3 N02 - Standalone TopTx settles its release</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n03">2.1.4.1.4 N03 - TopTx and SubTxs each settle a share</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n04">2.1.4.1.5 N04 - TopTx's share exceeds the transaction release</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-f01">2.1.4.1.6 F01 - TopTx omits a required output</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-f02">2.1.4.1.7 F02 - TopTx designates an unnecessary output</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n05">2.1.4.1.8 N05 - Net allocation, even though TopTx releases</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n06">2.1.4.1.9 N06 - Explicit-zero total, even though TopTx releases</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n07">2.1.4.1.10 N07 - Net release, while TopTx allocates</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n08">2.1.4.1.11 N08 - Valid designation when phase 2 fails</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-f03">2.1.4.1.12 F03 - Invalid designation when phase 2 fails</a></div>
              </dd></dl>
            </details>
            <details>
              <summary><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index">2.1.4.2 Output index</a></summary>
              <dl><dd>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-p01">2.1.4.2.1 P01 - The index belongs to the declaring body</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f01">2.1.4.2.2 F01 - The first missing own index is rejected</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f02">2.1.4.2.3 F02 - A SubTx cannot select TopTx's output</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f03">2.1.4.2.4 F03 - Collateral return is outside the ordinary output sequence</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f04">2.1.4.2.5 F04 - A SubTx without outputs cannot settle locally</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-n01">2.1.4.2.6 N01 - The first and last own outputs are valid</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f05">2.1.4.2.7 F05 - TopTx cannot select a SubTx's output</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f06">2.1.4.2.8 F06 - A SubTx cannot select a sibling's output</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-n02">2.1.4.2.9 N02 - Valid output indices when phase 2 fails</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f07">2.1.4.2.10 F07 - An invalid output index still fails when phase 2 fails</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-n03">2.1.4.2.11 N03 - A SubTx without outputs delegates its final release</a></div>
              </dd></dl>
            </details>
            <details>
              <summary><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin">2.1.4.3 Output coin</a></summary>
              <dl><dd>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-p01">2.1.4.3.1 P01 - Output ADA must cover the required share</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-f01">2.1.4.3.2 F01 - Min-ADA output, one lovelace short</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n01">2.1.4.3.3 N01 - Min-ADA output, exact amount</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n02">2.1.4.3.4 N02 - Min-ADA output, extra ADA</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-f02">2.1.4.3.5 F02 - An external deposit cannot fill the ADA shortfall</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n03">2.1.4.3.6 N03 - Deposit-backed output, exact application ADA</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n04">2.1.4.3.7 N04 - TopTx's share is smaller than the transaction release</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n05">2.1.4.3.8 N05 - Exact output ADA when phase 2 fails</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-f03">2.1.4.3.9 F03 - One lovelace short when phase 2 fails</a></div>
                <div><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-f04">2.1.4.3.10 F04 - The transaction release is smaller than TopTx's share</a></div>
              </dd></dl>
            </details>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/transaction-rules.md#ds-tx-minimum-coin">2.1.5 Minimum coin</a></summary>
          <dl><dd>
            <div><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-n01">2.1.5.1 N01 - Native assets without ADA</a></div>
            <div><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-n02">2.1.5.2 N02 - Datum or reference script without assets</a></div>
            <div><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-n03">2.1.5.3 N03 - Address-only output</a></div>
            <div><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-n04">2.1.5.4 N04 - Exact minimum for a min-ADA output</a></div>
            <div><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-f01">2.1.5.5 F01 - Min-ADA output one lovelace short</a></div>
          </dd></dl>
        </details>
      </dd></dl>
    </details>
    <details>
      <summary><a href="chapters/transaction-rules.md#ds-collateral">2.2 Collateral</a></summary>
      <dl><dd>
        <details>
          <summary><a href="chapters/transaction-rules.md#ds-collateral-existing-rules">Existing collateral rules</a></summary>
          <dl><dd>
            <details>
              <summary>Shared collateral regressions to add or extend</summary>
              <dl><dd>
                <div><a href="chapters/transaction-rules.md#ds-collateral-scope-f01">Scope F01 - Only TopTx has redeemers and requires collateral</a></div>
                <div><a href="chapters/transaction-rules.md#ds-collateral-scope-f02">Scope F02 - Only a SubTx has redeemers and requires shared collateral</a></div>
                <div><a href="chapters/transaction-rules.md#ds-collateral-scope-f03">Scope F03 - Both TopTx and SubTx have redeemers and require shared collateral</a></div>
                <div><a href="chapters/transaction-rules.md#ds-collateral-scope-n02">Scope N02 - Skip funding and supplied-total checks when no body has redeemers</a></div>
                <div><a href="chapters/transaction-rules.md#ds-collateral-scope-f04">Scope F04 - Check collateral inputs, return and count even without redeemers</a></div>
                <div><a href="chapters/transaction-rules.md#ds-collateral-authorization-f01">Authorization F01 - Active collateral validation requires key-locked inputs</a></div>
                <div><a href="chapters/transaction-rules.md#ds-collateral-authorization-f02">Authorization F02 - Each collateral payment key must witness the transaction</a></div>
              </dd></dl>
            </details>
            <div><a href="chapters/transaction-rules.md#ds-collateral-store-activity-control">Existing control and remaining extension for Store activity without redeemers</a></div>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/transaction-rules.md#ds-collateral-funding">2.2.1 Funding</a></summary>
          <dl><dd>
            <div><a href="chapters/transaction-rules.md#ds-collateral-funding-n01">2.2.1.1 N01 - Funded collateral</a></div>
            <div><a href="chapters/transaction-rules.md#ds-collateral-funding-f01">2.2.1.2 F01 - Underfunded collateral</a></div>
            <div><a href="chapters/transaction-rules.md#ds-collateral-funding-p02">2.2.1.3 P02 - Independent ordinary declarations</a></div>
            <div><a href="chapters/transaction-rules.md#ds-collateral-funding-p03">2.2.1.4 P03 - Min-ADA return at the active minimum</a></div>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/transaction-rules.md#ds-collateral-total">2.2.2 Total</a></summary>
          <dl><dd>
            <div><a href="chapters/transaction-rules.md#ds-collateral-total-n01">2.2.2.1 N01 - Absent or exact total</a></div>
            <div><a href="chapters/transaction-rules.md#ds-collateral-total-f01">2.2.2.2 F01 - Incorrect total</a></div>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/transaction-rules.md#ds-collateral-assets">2.2.3 Assets</a></summary>
          <dl><dd>
            <div><a href="chapters/transaction-rules.md#ds-collateral-assets-n01">2.2.3.1 N01 - Exact asset map</a></div>
            <div><a href="chapters/transaction-rules.md#ds-collateral-assets-f01">2.2.3.2 F01 - Missing or altered assets</a></div>
          </dd></dl>
        </details>
      </dd></dl>
    </details>
  </dd></dl>
</details>

<a id="3-ledger-effects" name="3-ledger-effects"></a>

<details open>
  <summary><strong><a href="chapters/ledger-effects.md">3. Ledger effects</a></strong></summary>
  <dl><dd>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-utxo">3.1 UTxO</a></summary>
      <dl><dd>
        <div><a href="chapters/ledger-effects.md#ds-state-utxo-n01">3.1.1 N01 - Ordinary execution</a></div>
        <div><a href="chapters/ledger-effects.md#ds-state-utxo-n02">3.1.2 N02 - Successful scripts leave collateral inactive</a></div>
        <div><a href="chapters/ledger-effects.md#ds-state-utxo-n03">3.1.3 N03 - Failed scripts select collateral</a></div>
        <div><a href="chapters/ledger-effects.md#ds-state-utxo-n04">3.1.4 N04 - Failed TopTx, inactive SubTxs</a></div>
        <div><a href="chapters/ledger-effects.md#ds-state-utxo-n05">3.1.5 N05 - One input, two consuming roles</a></div>
      </dd></dl>
    </details>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-store">3.2 Store</a></summary>
      <dl><dd>
        <details>
          <summary><a href="chapters/ledger-effects.md#ds-state-allocations">3.2.1 Allocations</a></summary>
          <dl><dd>
            <div><a href="chapters/ledger-effects.md#ds-state-allocations-p01">3.2.1.1 P01 - Ordinary records</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-allocations-p02">3.2.1.2 P02 - Collateral records</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-allocations-p03">3.2.1.3 P03 - Restore the historical deposit</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-allocations-n01">3.2.1.4 N01 - Zero-priced allocations still have records</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-allocations-p04">3.2.1.5 P04 - No ordinary records on failure</a></div>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/ledger-effects.md#ds-state-balance">3.2.2 Balance</a></summary>
          <dl><dd>
            <div><a href="chapters/ledger-effects.md#ds-state-balance-p01">3.2.2.1 P01 - Ordinary transfer</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-balance-p02">3.2.2.2 P02 - Collateral transfer</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-balance-p03">3.2.2.3 P03 - Historical release after restoration</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-balance-p04">3.2.2.4 P04 - No ordinary transfer on failure</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-balance-p05">3.2.2.5 P05 - Refund mixed historical prices</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-balance-p06">3.2.2.6 P06 - Restore and refund a child output</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-balance-p07">3.2.2.7 P07 - Restore and refund a collateral return</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-balance-p08">3.2.2.8 P08 - Refund across formula versions</a></div>
          </dd></dl>
        </details>
      </dd></dl>
    </details>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-fees">3.3 Fees</a></summary>
      <dl><dd>
        <div><a href="chapters/ledger-effects.md#ds-state-fees-p01">3.3.1 P01 - Ordinary fee</a></div>
        <div><a href="chapters/ledger-effects.md#ds-state-fees-p02">3.3.2 P02 - Collateral fee</a></div>
      </dd></dl>
    </details>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-conservation">3.4 Conservation</a></summary>
      <dl><dd>
        <div><a href="chapters/ledger-effects.md#ds-state-conservation-n01">3.4.1 N01 - Count actual ADA once</a></div>
        <div><a href="chapters/ledger-effects.md#ds-state-conservation-n02">3.4.2 N02 - Ordinary conservation</a></div>
        <div><a href="chapters/ledger-effects.md#ds-state-conservation-n03">3.4.3 N03 - Collateral conservation</a></div>
      </dd></dl>
    </details>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-lifecycle">3.5 Lifecycle</a></summary>
      <dl><dd>
        <details>
          <summary><a href="chapters/ledger-effects.md#ds-state-translation">3.5.1 Translation</a></summary>
          <dl><dd>
            <div><a href="chapters/ledger-effects.md#ds-state-translation-n01">3.5.1.1 N01 - Introduce legacy allocations</a></div>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/ledger-effects.md#ds-state-epoch">3.5.2 Epoch</a></summary>
          <dl><dd>
            <div><a href="chapters/ledger-effects.md#ds-state-epoch-n01">3.5.2.1 N01 - Retain the populated Store</a></div>
            <div><a href="chapters/ledger-effects.md#ds-state-epoch-n02">3.5.2.2 N02 - Activate the effective price</a></div>
          </dd></dl>
        </details>
      </dd></dl>
    </details>
  </dd></dl>
</details>

<a id="4-derived-distributions" name="4-derived-distributions"></a>

<details open>
  <summary><strong><a href="chapters/derived-distributions.md">4. Derived distributions</a></strong></summary>
  <dl><dd>
    <details>
      <summary><a href="chapters/derived-distributions.md#ds-stake">4.1 Stake</a></summary>
      <dl><dd>
        <div><a href="chapters/derived-distributions.md#ds-stake-n01">4.1.1 N01 - counts the full ADA in min-ADA outputs under the existing staking rules</a></div>
        <div><a href="chapters/derived-distributions.md#ds-stake-n02">4.1.2 N02 - counts only application ADA in deposit-backed outputs under the existing staking rules</a></div>
        <div><a href="chapters/derived-distributions.md#ds-stake-n03">4.1.3 N03 - does not add the global Store balance to stake totals</a></div>
        <div><a href="chapters/derived-distributions.md#ds-stake-n04">4.1.4 N04 - Derive stake from applied allocations</a></div>
        <div><a href="chapters/derived-distributions.md#ds-stake-n05">4.1.5 N05 - Derive stake from applied releases</a></div>
        <div><a href="chapters/derived-distributions.md#ds-stake-n06">4.1.6 N06 - Ignore unapplied collateral</a></div>
        <div><a href="chapters/derived-distributions.md#ds-stake-n07">4.1.7 N07 - Derive stake from collateral on phase-2 failure</a></div>
        <div><a href="chapters/derived-distributions.md#ds-stake-n08">4.1.8 N08 - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects</a></div>
      </dd></dl>
    </details>
    <details>
      <summary><a href="chapters/derived-distributions.md#ds-voting">4.2 Voting</a></summary>
      <dl><dd>
        <div><a href="chapters/derived-distributions.md#ds-voting-n01">4.2.1 N01 - preserves the expected voting distribution from eligible funds while excluding allocated UTxO capacity deposits and Store balance</a></div>
      </dd></dl>
    </details>
  </dd></dl>
</details>

<a id="appendices" name="appendices"></a>

<details open>
  <summary><strong><a href="chapters/appendices.md">Appendices</a></strong></summary>
  <dl><dd>
    <details>
      <summary><a href="chapters/appendices.md#section-8">A. Remaining design work</a></summary>
      <dl><dd>
        <div><a href="chapters/appendices.md#ds-pricing-history">A.1 Historical pricing</a></div>
        <div><a href="chapters/appendices.md#ds-plutus-compatibility">A.2 Plutus compatibility</a></div>
        <div><a href="chapters/appendices.md#ds-tx-settlement-refinement">A.3 Local settlement</a></div>
        <div><a href="chapters/appendices.md#ds-state-representation">A.4 State representation</a></div>
      </dd></dl>
    </details>
    <div><a href="chapters/appendices.md#section-9">B. Tag migration</a></div>
    <details>
      <summary><a href="chapters/appendices.md#section-10">C. Code references</a></summary>
      <dl><dd>
        <div><a href="chapters/appendices.md#declaration-api">C.1 Declaration API</a></div>
        <div><a href="chapters/appendices.md#transaction-body-fields">C.2 Transaction body fields</a></div>
        <div><a href="chapters/appendices.md#declaration-encoding">C.3 Declaration encoding</a></div>
      </dd></dl>
    </details>
    <details>
      <summary><a href="chapters/appendices.md#net-change-test-cases">D. Net-change test cases</a></summary>
      <dl><dd>
        <details>
          <summary><a href="chapters/appendices.md#subtx-net-change-test-cases">D.1 SubTx net-change cases</a></summary>
          <dl><dd>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-p01">2.1.2.1.1.1 P01 - Each SubTx declares its own exact change</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n01">2.1.2.1.1.2 N01 - Exact own change, with any allocation and release combination</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f01">2.1.2.1.1.3 F01 - Net allocation understated by one lovelace</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f02">2.1.2.1.1.4 F02 - Net allocation overstated by one lovelace</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f03">2.1.2.1.1.5 F03 - Net release understated by one lovelace</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f04">2.1.2.1.1.6 F04 - Net release overstated by one lovelace</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f05">2.1.2.1.1.7 F05 - Opposing SubTx errors cancel in the total</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n02">2.1.2.1.1.8 N02 - Equal own allocations and releases, explicit zero</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f06">2.1.2.1.1.9 F06 - Explicit zero cannot replace a required allocation</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n03">2.1.2.1.1.10 N03 - Exact allocation requested from TopTx</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n04">2.1.2.1.1.11 N04 - Exact release delegated to TopTx</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n05">2.1.2.1.1.12 N05 - Released deposits, only min-ADA outputs</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f07">2.1.2.1.1.13 F07 - Explicit zero cannot replace a required release</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n06">2.1.2.1.1.14 N06 - Another body offsets the SubTx release</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n07">2.1.2.1.1.15 N07 - An output without application assets still requires a deposit</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n08">2.1.2.1.1.16 N08 - A translated min-ADA input funds an exact allocation</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f08">2.1.2.1.1.17 F08 - A translated min-ADA input does not excuse an inexact allocation</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f09">2.1.2.1.1.18 F09 - Unspent outputs cannot increase a SubTx release</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f10">2.1.2.1.1.19 F10 - A release cannot replace a required allocation</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f11">2.1.2.1.1.20 F11 - An allocation cannot replace a required release</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n09">2.1.2.1.1.21 N09 - Exact SubTx declarations when phase 2 fails</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f12">2.1.2.1.1.22 F12 - An inexact SubTx declaration still fails before the collateral outcome</a></div>
          </dd></dl>
        </details>
        <details>
          <summary><a href="chapters/appendices.md#toptx-net-change-test-cases">D.2 TopTx net-change cases</a></summary>
          <dl><dd>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-p01">2.1.2.1.2.1 P01 - TopTx declares the exact transaction total</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-p02">2.1.2.1.2.2 P02 - Delegation preserves the transaction total</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n01">2.1.2.1.2.3 N01 - TopTx and SubTxs contribute to the total</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n02">2.1.2.1.2.4 N02 - TopTx's own change is derived from its total</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n03">2.1.2.1.2.5 N03 - 5 ADA allocated, 3 ADA released</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n04">2.1.2.1.2.6 N04 - 3 ADA allocated, 5 ADA released</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n05">2.1.2.1.2.7 N05 - Nonzero body changes produce a zero total</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f01">2.1.2.1.2.8 F01 - Standalone TopTx understates its net allocation by one lovelace</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f02">2.1.2.1.2.9 F02 - Standalone TopTx overstates its net allocation by one lovelace</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f03">2.1.2.1.2.10 F03 - Standalone TopTx understates its net release by one lovelace</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f04">2.1.2.1.2.11 F04 - Standalone TopTx overstates its net release by one lovelace</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f05">2.1.2.1.2.12 F05 - Explicit zero cannot replace a nonzero total</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f06">2.1.2.1.2.13 F06 - A nonzero declaration cannot replace a zero total</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f07">2.1.2.1.2.14 F07 - TopTx declares the opposite direction</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n06">2.1.2.1.2.15 N06 - TopTx releases while SubTxs allocate</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n07">2.1.2.1.2.16 N07 - TopTx allocates while SubTxs release</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n08">2.1.2.1.2.17 N08 - An exact total remains valid when phase 2 fails</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f08">2.1.2.1.2.18 F08 - An inexact total is rejected even when phase 2 fails</a></div>
            <div><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f09">2.1.2.1.2.19 F09 - A delegated change belongs in the total exactly once</a></div>
          </dd></dl>
        </details>
      </dd></dl>
    </details>
  </dd></dl>
</details>

<a id="verification-record" name="verification-record"></a>

**[Verification record](verification.md)**
