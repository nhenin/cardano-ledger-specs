# Dijkstra ledger rules for minimum-ADA and deposit-backed outputs

[Verification record](verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/README.md)

The *UTxO Deposit versus UTxO Minimum ADA* proposal describes two ways to back an output's storage. A minimum-ADA output carries its reserve in its own value. For a deposit-backed output, the ledger accounts for the deposit separately.

## How the documents fit together

The [domain model](chapters/domain-model.md) defines the amounts used by the [transaction rules](chapters/transaction-rules.md). A transaction's [deposit declaration](chapters/transaction-rules.md#ds-tx-declarations) is one part of those checks. [Ledger effects](chapters/ledger-effects.md) describes how the accepted outcome updates state, and [derived distributions](chapters/derived-distributions.md) describes how that state contributes to stake and voting power.

For example, an input with 1.6 ADA of embedded reserve can fund a new output requiring a 2 ADA external deposit. The [net-change rule](chapters/transaction-rules.md#ds-tx-accounting-net-change) requires `Allocate 0.4 ADA`, while the [Store balance](chapters/ledger-effects.md#ds-state-balance) increases by 2 ADA. [Appendix D](chapters/appendices.md#net-change-test-cases) lists the SubTx and TopTx exactness cases. The separate [verification record](verification.md#signed-backing-change-for-mixed-output-forms--24-november-2026) gives the test results for this mixed-output example and the [verification contents](verification.md#table-of-contents) list the other runs.

## Table of contents

Expand a heading to see its subsections and test cases. Select a section number to open the corresponding rule.

[Domain model](#1-domain-model) · [Transaction rules](#2-transaction-rules) · [Ledger effects](#3-ledger-effects) · [Derived distributions](#4-derived-distributions) · [Appendices](#appendices) · [Verification record](#verification-record)

<a id="1-domain-model" name="1-domain-model"></a>

<details open>
<summary><strong>1. Domain model</strong> · <a href="chapters/domain-model.md">Read chapter</a></summary>
<p>What does each form of output carry, what does the Store record, and how is the required deposit calculated?</p>
<ul>
  <li><a href="chapters/domain-model.md#section-1">1.1 Outputs</a></li>
  <li><a href="chapters/domain-model.md#section-1-1">1.2 DepositStore</a></li>
  <li><a href="chapters/domain-model.md#section-1-4">1.3 Transaction bodies</a></li>
  <li>
    <details>
      <summary><a href="chapters/domain-model.md#ds-pricing">1.4</a> Deposit calculation</summary>
      <ul>
        <li><a href="chapters/domain-model.md#ds-pricing-p01">1.4.1 P01 - Price each created output</a></li>
        <li><a href="chapters/domain-model.md#ds-pricing-n01">1.4.2 N01 - Count distinct native assets</a></li>
        <li><a href="chapters/domain-model.md#ds-pricing-n02">1.4.3 N02 - Price an applied collateral return</a></li>
        <li><a href="chapters/domain-model.md#ds-pricing-n03">1.4.4 N03 - Measure datum and reference script payloads</a></li>
        <li><a href="chapters/domain-model.md#ds-pricing-n04">1.4.5 N04 - Vary the declaration independently</a></li>
        <li><a href="chapters/domain-model.md#ds-pricing-n05">1.4.6 N05 - Preserve the price across ADA encoding boundaries</a></li>
        <li><a href="chapters/domain-model.md#ds-pricing-n06">1.4.7 N06 - Keep a min-ADA reserve inside its output</a></li>
      </ul>
    </details>
  </li>
</ul>
</details>

<a id="2-transaction-rules" name="2-transaction-rules"></a>

<details open>
<summary><strong>2. Transaction rules</strong> · <a href="chapters/transaction-rules.md">Read chapter</a></summary>
<p>What must TopTx and SubTx declare, who authorizes a release, and how does the ledger check accounting, settlement, minimum coin and collateral?</p>
<ul>
  <li>
    <details open>
      <summary><a href="chapters/transaction-rules.md#ds-tx">2.1</a> Tx</summary>
      <ul>
        <li>
          <details>
            <summary><a href="chapters/transaction-rules.md#ds-tx-declarations">2.1.1</a> TopTx and SubTx deposit declarations</summary>
            <ul>
              <li>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar">2.1.1.1</a> Grammar</summary>
                  <ul>
                    <li>
                      <details>
                        <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx">2.1.1.1.1</a> TopTx</summary>
                        <ul>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-amounts">2.1.1.1.1.1</a> Amounts</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-p01">2.1.1.1.1.1.1 P01 - Positive amounts survive encoding</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f01">2.1.1.1.1.1.2 F01 - Zero operation amount</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f12">2.1.1.1.1.1.3 F12 - Negative operation amount</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f13">2.1.1.1.1.1.4 F13 - Overflowing operation amount</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-absence">2.1.1.1.1.2</a> Absence</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-n03">2.1.1.1.1.2.1 N03 - Absence remains distinct from zero</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-forms">2.1.1.1.1.3</a> Forms</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-n05">2.1.1.1.1.3.1 N05 - Every TopTx declaration form</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f06">2.1.1.1.1.3.2 F06 - Funding request in TopTx</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-structure">2.1.1.1.1.4</a> Structure</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f02">2.1.1.1.1.4.1 F02 - Malformed declarations</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-toptx-destinations">2.1.1.1.1.5</a> Destinations</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f04">2.1.1.1.1.5.1 F04 - Malformed release settlements</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f14">2.1.1.1.1.5.2 F14 - Negative output index</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f15">2.1.1.1.1.5.3 F15 - Overflowing output index</a></li>
                              </ul>
                            </details>
                          </li>
                        </ul>
                      </details>
                    </li>
                    <li>
                      <details>
                        <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx">2.1.1.1.2</a> SubTx</summary>
                        <ul>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-amounts">2.1.1.1.2.1</a> Amounts</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-p02">2.1.1.1.2.1.1 P02 - Positive amounts survive encoding</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f07">2.1.1.1.2.1.2 F07 - Zero operation amount</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f08">2.1.1.1.2.1.3 F08 - Negative operation amount</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f09">2.1.1.1.2.1.4 F09 - Overflowing operation amount</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-absence">2.1.1.1.2.2</a> Absence</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-n04">2.1.1.1.2.2.1 N04 - Absence remains distinct from zero</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-forms">2.1.1.1.2.3</a> Forms</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-n06">2.1.1.1.2.3.1 N06 - Every SubTx declaration form</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-structure">2.1.1.1.2.4</a> Structure</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f03">2.1.1.1.2.4.1 F03 - Malformed declarations</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-subtx-destinations">2.1.1.1.2.5</a> Destinations</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f05">2.1.1.1.2.5.1 F05 - Malformed release targets</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f10">2.1.1.1.2.5.2 F10 - Negative output index</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-grammar-f11">2.1.1.1.2.5.3 F11 - Overflowing output index</a></li>
                              </ul>
                            </details>
                          </li>
                        </ul>
                      </details>
                    </li>
                  </ul>
                </details>
              </li>
              <li>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements">2.1.1.2</a> Requirements</summary>
                  <ul>
                    <li>
                      <details>
                        <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations">2.1.1.2.1</a> Operations</summary>
                        <ul>
                          <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-p01">2.1.1.2.1.1 P01 - Every body requiring a Store operation declares</a></li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation">2.1.1.2.1.2</a> Allocation</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n01">2.1.1.2.1.2.1 N01 - Every explicit declaration satisfies allocation presence</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n02">2.1.1.2.1.2.2 N02 - Absence satisfies allocation presence for empty or implicit-only own outputs</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f01">2.1.1.2.1.2.3 F01 - Missing declaration fails allocation presence at every own-output position</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n03">2.1.1.2.1.2.4 N03 - accepts a TopTx creating only min-ADA outputs without a declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n04">2.1.1.2.1.2.5 N04 - accepts a SubTx creating only min-ADA outputs without either body's declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n05">2.1.1.2.1.2.6 N05 - Standalone TopTx, exact allocation declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f02">2.1.1.2.1.2.7 F02 - Standalone TopTx, allocation without a declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f03">2.1.1.2.1.2.8 F03 - rejects a SubTx creating a deposit-backed output without its own declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f04">2.1.1.2.1.2.9 F04 - rejects a TopTx creating a deposit-backed output without its own declaration even when phase 2 fails</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f05">2.1.1.2.1.2.10 F05 - rejects a SubTx creating a deposit-backed output without its own declaration even when phase 2 fails</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f06">2.1.1.2.1.2.11 F06 - rejects a missing own declaration when spending a translated min-ADA output to create deposit-backed outputs</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n06">2.1.1.2.1.2.12 N06 - SubTx outputs do not trigger TopTx allocation presence</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n07">2.1.1.2.1.2.13 N07 - Collateral return does not trigger allocation presence</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n08">2.1.1.2.1.2.14 N08 - Reference and collateral input identifiers do not trigger allocation presence</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f07">2.1.1.2.1.2.15 F07 - A SubTx declaration cannot satisfy TopTx allocation presence</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-f08">2.1.1.2.1.2.16 F08 - TopTx zero cannot satisfy its allocating SubTx's declaration requirement</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-allocation-n09">2.1.1.2.1.2.17 N09 - TopTx and SubTx allocate deposits, each with an exact declaration</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release">2.1.1.2.1.3</a> Release</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n01">2.1.1.2.1.3.1 N01 - Standalone TopTx, any output form</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n02">2.1.1.2.1.3.2 N02 - Standalone TopTx, only min-ADA outputs</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n03">2.1.1.2.1.3.3 N03 - One SubTx releases its deposit into its own output</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f01">2.1.1.2.1.3.4 F01 - Standalone TopTx, release without its own declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f02">2.1.1.2.1.3.5 F02 - SubTx release without its own declaration, despite TopTx declaring</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n04">2.1.1.2.1.3.6 N04 - Phase 2 fails with valid declarations</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f03">2.1.1.2.1.3.7 F03 - Missing release declaration in a phase-2-invalid proposal</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n05">2.1.1.2.1.3.8 N05 - Several SubTxs release their deposits</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f04">2.1.1.2.1.3.9 F04 - One SubTx releasing deposits omits its declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n06">2.1.1.2.1.3.10 N06 - Only some SubTxs release Store deposits</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n07">2.1.1.2.1.3.11 N07 - TopTx and several SubTxs release deposits</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n08">2.1.1.2.1.3.12 N08 - Phase 2 fails with several proposed SubTx releases</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f05">2.1.1.2.1.3.13 F05 - One SubTx declaration is missing in a phase-2-invalid proposal</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n09">2.1.1.2.1.3.14 N09 - Standalone TopTx, reference-only Store access</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-n10">2.1.1.2.1.3.15 N10 - Standalone TopTx, collateral-only Store operations</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-release-f06">2.1.1.2.1.3.16 F06 - A SubTx declaration cannot satisfy TopTx release presence</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change">2.1.1.2.1.4</a> Zero net change</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n01">2.1.1.2.1.4.1 N01 - Standalone TopTx, equal allocations and releases with explicit zero</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f01">2.1.1.2.1.4.2 F01 - Standalone TopTx, equal allocations and releases without a declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n02">2.1.1.2.1.4.3 N02 - One SubTx replaces its deposit with explicit zero</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f02">2.1.1.2.1.4.4 F02 - One active SubTx omits its declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f03">2.1.1.2.1.4.5 F03 - TopTx omits the declaration required by its child</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n03">2.1.1.2.1.4.6 N03 - Several SubTxs each replace their deposits</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f04">2.1.1.2.1.4.7 F04 - One of several active SubTxs omits its declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n04">2.1.1.2.1.4.8 N04 - Only some SubTxs replace Store deposits</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f05">2.1.1.2.1.4.9 F05 - One active SubTx omits its declaration among inactive siblings</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n05">2.1.1.2.1.4.10 N05 - TopTx and several SubTxs each replace their deposits</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f06">2.1.1.2.1.4.11 F06 - Active TopTx omits its own declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-n06">2.1.1.2.1.4.12 N06 - Phase 2 fails with explicit zero at every active body</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f07">2.1.1.2.1.4.13 F07 - One SubTx declaration is missing in a phase-2-invalid proposal</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-operations-zero-net-change-f08">2.1.1.2.1.4.14 F08 - TopTx's own declaration is missing in a phase-2-invalid proposal</a></li>
                              </ul>
                            </details>
                          </li>
                        </ul>
                      </details>
                    </li>
                    <li>
                      <details>
                        <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations">2.1.1.2.2</a> SubTx declarations</summary>
                        <ul>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c01">2.1.1.2.2.1</a> TopTx requirement</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c01-p01">2.1.1.2.2.1.1 P01 - SubTx declarations require TopTx's declaration</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02">2.1.1.2.2.2</a> Absence and explicit zero</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-n01">2.1.1.2.2.2.1 N01 - accepts absent declarations at both levels</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-n02">2.1.1.2.2.2.2 N02 - accepts explicit zero at both levels</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-n03">2.1.1.2.2.2.3 N03 - accepts TopTx zero without a SubTx declaration</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c02-f01">2.1.1.2.2.2.4 F01 - rejects SubTx zero without a TopTx declaration</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c03">2.1.1.2.2.3</a> Offsetting SubTx contributions</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c03-n01">2.1.1.2.2.3.1 N01 - passes declaration presence with TopTx declaring the zero net amount</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c03-f01">2.1.1.2.2.3.2 F01 - rejects an absent TopTx declaration despite the zero net amount</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c04">2.1.1.2.2.4</a> Local and delegated accounting</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c04-n01">2.1.1.2.2.4.1 N01 - passes declaration presence with TopTx zero for every explicit SubTx form</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c04-f01">2.1.1.2.2.4.2 F01 - rejects an absent TopTx declaration for every explicit SubTx form</a></li>
                              </ul>
                            </details>
                          </li>
                          <li>
                            <details>
                              <summary><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c05">2.1.1.2.2.5</a> Phase-2 failure</summary>
                              <ul>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c05-n01">2.1.1.2.2.5.1 N01 - accepts zero declarations at both levels on the phase-2 failure path</a></li>
                                <li><a href="chapters/transaction-rules.md#ds-tx-declarations-requirements-subtx-declarations-c05-f01">2.1.1.2.2.5.2 F01 - rejects SubTx zero without a TopTx declaration on the phase-2 failure path</a></li>
                              </ul>
                            </details>
                          </li>
                        </ul>
                      </details>
                    </li>
                  </ul>
                </details>
              </li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/transaction-rules.md#ds-tx-accounting">2.1.2</a> Accounting</summary>
            <ul>
              <li>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-net-change">2.1.2.1</a> Net change</summary>
                  <ul>
                    <li>
                      <details>
                        <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-net-change-subtx">2.1.2.1.1</a> SubTx</summary>
                        <ul>
                          <li><a href="chapters/appendices.md#subtx-net-change-test-cases">Appendix D.1 SubTx net-change cases</a></li>
                        </ul>
                      </details>
                    </li>
                    <li>
                      <details>
                        <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-net-change-toptx">2.1.2.1.2</a> TopTx</summary>
                        <ul>
                          <li><a href="chapters/appendices.md#toptx-net-change-test-cases">Appendix D.2 TopTx net-change cases</a></li>
                        </ul>
                      </details>
                    </li>
                  </ul>
                </details>
              </li>
              <li>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-attribution">2.1.2.2</a> Attribution</summary>
                  <ul>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-attribution-p01">2.1.2.2.1 P01 - Local and delegated contributions determine TopTx's share</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-attribution-p02">2.1.2.2.2 P02 - Delegation moves the signed contribution to TopTx</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-attribution-n01">2.1.2.2.3 N01 - Explicit zero adds no delegated contribution</a></li>
                  </ul>
                </details>
              </li>
              <li>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-accounting-balance">2.1.2.3</a> Balance</summary>
                  <ul>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-p01">2.1.2.3.1 P01 - The transaction conserves value when phase 2 is valid</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-p02">2.1.2.3.2 P02 - Complete balance determines acceptance</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n01">2.1.2.3.3 N01 - Fund a net allocation once</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n02">2.1.2.3.4 N02 - Use a net release once</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n03">2.1.2.3.5 N03 - One SubTx funds another</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n04">2.1.2.3.6 N04 - A SubTx funds TopTx fees</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-f01">2.1.2.3.7 F01 - One-lovelace deficit or surplus</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-f02">2.1.2.3.8 F02 - Native-asset quantity or identity mismatch</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-f03">2.1.2.3.9 F03 - An exact delegated allocation lacks funding</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n05">2.1.2.3.10 N05 - Equal delegated allocations and releases</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n06">2.1.2.3.11 N06 - Ten input ADA plus two released ADA</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n07">2.1.2.3.12 N07 - Released ADA contributes to TopTx fees</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-f04">2.1.2.3.13 F04 - Released ADA cannot disappear</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-accounting-balance-n08">2.1.2.3.14 N08 - Balanced proposal, failed phase 2</a></li>
                  </ul>
                </details>
              </li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/transaction-rules.md#ds-tx-authorization">2.1.3</a> Authorization</summary>
            <ul>
              <li><a href="chapters/transaction-rules.md#ds-tx-authorization-n01">2.1.3.1 N01 - Bob spends an output funded by Alice</a></li>
              <li><a href="chapters/transaction-rules.md#ds-tx-authorization-f01">2.1.3.2 F01 - Alice's signature cannot replace Bob's</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/transaction-rules.md#ds-tx-settlement">2.1.4</a> Settlement</summary>
            <ul>
              <li>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-settlement-designation">2.1.4.1</a> Designation</summary>
                  <ul>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-p01">2.1.4.1.1 P01 - Designation follows TopTx's release share</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n01">2.1.4.1.2 N01 - SubTxs settle the entire release</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n02">2.1.4.1.3 N02 - Standalone TopTx settles its release</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n03">2.1.4.1.4 N03 - TopTx and SubTxs each settle a share</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n04">2.1.4.1.5 N04 - TopTx's share exceeds the transaction release</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-f01">2.1.4.1.6 F01 - TopTx omits a required output</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-f02">2.1.4.1.7 F02 - TopTx designates an unnecessary output</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n05">2.1.4.1.8 N05 - Net allocation, even though TopTx releases</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n06">2.1.4.1.9 N06 - Explicit-zero total, even though TopTx releases</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n07">2.1.4.1.10 N07 - Net release, while TopTx allocates</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-n08">2.1.4.1.11 N08 - Valid designation when phase 2 fails</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-designation-f03">2.1.4.1.12 F03 - Invalid designation when phase 2 fails</a></li>
                  </ul>
                </details>
              </li>
              <li>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index">2.1.4.2</a> Output index</summary>
                  <ul>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-p01">2.1.4.2.1 P01 - The index belongs to the declaring body</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f01">2.1.4.2.2 F01 - The first missing own index is rejected</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f02">2.1.4.2.3 F02 - A SubTx cannot select TopTx's output</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f03">2.1.4.2.4 F03 - Collateral return is outside the ordinary output sequence</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f04">2.1.4.2.5 F04 - A SubTx without outputs cannot settle locally</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-n01">2.1.4.2.6 N01 - The first and last own outputs are valid</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f05">2.1.4.2.7 F05 - TopTx cannot select a SubTx's output</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f06">2.1.4.2.8 F06 - A SubTx cannot select a sibling's output</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-n02">2.1.4.2.9 N02 - Valid output indices when phase 2 fails</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-f07">2.1.4.2.10 F07 - An invalid output index still fails when phase 2 fails</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-index-n03">2.1.4.2.11 N03 - A SubTx without outputs delegates its final release</a></li>
                  </ul>
                </details>
              </li>
              <li>
                <details>
                  <summary><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin">2.1.4.3</a> Output coin</summary>
                  <ul>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-p01">2.1.4.3.1 P01 - Output ADA must cover the required share</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-f01">2.1.4.3.2 F01 - Min-ADA output, one lovelace short</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n01">2.1.4.3.3 N01 - Min-ADA output, exact amount</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n02">2.1.4.3.4 N02 - Min-ADA output, extra ADA</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-f02">2.1.4.3.5 F02 - An external deposit cannot fill the ADA shortfall</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n03">2.1.4.3.6 N03 - Deposit-backed output, exact application ADA</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n04">2.1.4.3.7 N04 - TopTx's share is smaller than the transaction release</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-n05">2.1.4.3.8 N05 - Exact output ADA when phase 2 fails</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-f03">2.1.4.3.9 F03 - One lovelace short when phase 2 fails</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-tx-settlement-output-coin-f04">2.1.4.3.10 F04 - The transaction release is smaller than TopTx's share</a></li>
                  </ul>
                </details>
              </li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/transaction-rules.md#ds-tx-minimum-coin">2.1.5</a> Minimum coin</summary>
            <ul>
              <li><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-n01">2.1.5.1 N01 - Native assets without ADA</a></li>
              <li><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-n02">2.1.5.2 N02 - Datum or reference script without assets</a></li>
              <li><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-n03">2.1.5.3 N03 - Address-only output</a></li>
              <li><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-n04">2.1.5.4 N04 - Exact minimum for a min-ADA output</a></li>
              <li><a href="chapters/transaction-rules.md#ds-tx-minimum-coin-f01">2.1.5.5 F01 - Min-ADA output one lovelace short</a></li>
            </ul>
          </details>
        </li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary><a href="chapters/transaction-rules.md#ds-collateral">2.2</a> Collateral</summary>
      <ul>
        <li>
          <details>
            <summary>Existing collateral rules · <a href="chapters/transaction-rules.md#ds-collateral-existing-rules">Read section</a></summary>
            <ul>
              <li>
                <details>
                  <summary>Shared collateral regressions to add or extend</summary>
                  <ul>
                    <li><a href="chapters/transaction-rules.md#ds-collateral-scope-f01">Scope F01 - Only TopTx has redeemers and requires collateral</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-collateral-scope-f02">Scope F02 - Only a SubTx has redeemers and requires shared collateral</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-collateral-scope-f03">Scope F03 - Both TopTx and SubTx have redeemers and require shared collateral</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-collateral-scope-n02">Scope N02 - Skip funding and supplied-total checks when no body has redeemers</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-collateral-scope-f04">Scope F04 - Check collateral inputs, return and count even without redeemers</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-collateral-authorization-f01">Authorization F01 - Active collateral validation requires key-locked inputs</a></li>
                    <li><a href="chapters/transaction-rules.md#ds-collateral-authorization-f02">Authorization F02 - Each collateral payment key must witness the transaction</a></li>
                  </ul>
                </details>
              </li>
              <li><a href="chapters/transaction-rules.md#ds-collateral-store-activity-control">Existing control and remaining extension for Store activity without redeemers</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/transaction-rules.md#ds-collateral-funding">2.2.1</a> Funding</summary>
            <ul>
              <li><a href="chapters/transaction-rules.md#ds-collateral-funding-n01">2.2.1.1 N01 - Funded collateral</a></li>
              <li><a href="chapters/transaction-rules.md#ds-collateral-funding-f01">2.2.1.2 F01 - Underfunded collateral</a></li>
              <li><a href="chapters/transaction-rules.md#ds-collateral-funding-p02">2.2.1.3 P02 - Independent ordinary declarations</a></li>
              <li><a href="chapters/transaction-rules.md#ds-collateral-funding-p03">2.2.1.4 P03 - Min-ADA return at the active minimum</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/transaction-rules.md#ds-collateral-total">2.2.2</a> Total</summary>
            <ul>
              <li><a href="chapters/transaction-rules.md#ds-collateral-total-n01">2.2.2.1 N01 - Absent or exact total</a></li>
              <li><a href="chapters/transaction-rules.md#ds-collateral-total-f01">2.2.2.2 F01 - Incorrect total</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/transaction-rules.md#ds-collateral-assets">2.2.3</a> Assets</summary>
            <ul>
              <li><a href="chapters/transaction-rules.md#ds-collateral-assets-n01">2.2.3.1 N01 - Exact asset map</a></li>
              <li><a href="chapters/transaction-rules.md#ds-collateral-assets-f01">2.2.3.2 F01 - Missing or altered assets</a></li>
            </ul>
          </details>
        </li>
      </ul>
    </details>
  </li>
</ul>
</details>

<a id="3-ledger-effects" name="3-ledger-effects"></a>

<details open>
<summary><strong>3. Ledger effects</strong> · <a href="chapters/ledger-effects.md">Read chapter</a></summary>
<p>After validation, which inputs, outputs, deposits and fees change on ordinary success or on a phase-2 failure?</p>
<ul>
  <li>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-utxo">3.1</a> UTxO</summary>
      <ul>
        <li><a href="chapters/ledger-effects.md#ds-state-utxo-n01">3.1.1 N01 - Ordinary execution</a></li>
        <li><a href="chapters/ledger-effects.md#ds-state-utxo-n02">3.1.2 N02 - Successful scripts leave collateral inactive</a></li>
        <li><a href="chapters/ledger-effects.md#ds-state-utxo-n03">3.1.3 N03 - Failed scripts select collateral</a></li>
        <li><a href="chapters/ledger-effects.md#ds-state-utxo-n04">3.1.4 N04 - Failed TopTx, inactive SubTxs</a></li>
        <li><a href="chapters/ledger-effects.md#ds-state-utxo-n05">3.1.5 N05 - One input, two consuming roles</a></li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-store">3.2</a> Store</summary>
      <ul>
        <li>
          <details>
            <summary><a href="chapters/ledger-effects.md#ds-state-allocations">3.2.1</a> Allocations</summary>
            <ul>
              <li><a href="chapters/ledger-effects.md#ds-state-allocations-p01">3.2.1.1 P01 - Ordinary records</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-allocations-p02">3.2.1.2 P02 - Collateral records</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-allocations-p03">3.2.1.3 P03 - Restore the historical deposit</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-allocations-n01">3.2.1.4 N01 - Zero-priced allocations still have records</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-allocations-p04">3.2.1.5 P04 - No ordinary records on failure</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/ledger-effects.md#ds-state-balance">3.2.2</a> Balance</summary>
            <ul>
              <li><a href="chapters/ledger-effects.md#ds-state-balance-p01">3.2.2.1 P01 - Ordinary transfer</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-balance-p02">3.2.2.2 P02 - Collateral transfer</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-balance-p03">3.2.2.3 P03 - Historical release after restoration</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-balance-p04">3.2.2.4 P04 - No ordinary transfer on failure</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-balance-p05">3.2.2.5 P05 - Refund mixed historical prices</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-balance-p06">3.2.2.6 P06 - Restore and refund a child output</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-balance-p07">3.2.2.7 P07 - Restore and refund a collateral return</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-balance-p08">3.2.2.8 P08 - Refund across formula versions</a></li>
            </ul>
          </details>
        </li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-fees">3.3</a> Fees</summary>
      <ul>
        <li><a href="chapters/ledger-effects.md#ds-state-fees-p01">3.3.1 P01 - Ordinary fee</a></li>
        <li><a href="chapters/ledger-effects.md#ds-state-fees-p02">3.3.2 P02 - Collateral fee</a></li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-conservation">3.4</a> Conservation</summary>
      <ul>
        <li><a href="chapters/ledger-effects.md#ds-state-conservation-n01">3.4.1 N01 - Count actual ADA once</a></li>
        <li><a href="chapters/ledger-effects.md#ds-state-conservation-n02">3.4.2 N02 - Ordinary conservation</a></li>
        <li><a href="chapters/ledger-effects.md#ds-state-conservation-n03">3.4.3 N03 - Collateral conservation</a></li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary><a href="chapters/ledger-effects.md#ds-state-lifecycle">3.5</a> Lifecycle</summary>
      <ul>
        <li>
          <details>
            <summary><a href="chapters/ledger-effects.md#ds-state-translation">3.5.1</a> Translation</summary>
            <ul>
              <li><a href="chapters/ledger-effects.md#ds-state-translation-n01">3.5.1.1 N01 - Introduce legacy allocations</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/ledger-effects.md#ds-state-epoch">3.5.2</a> Epoch</summary>
            <ul>
              <li><a href="chapters/ledger-effects.md#ds-state-epoch-n01">3.5.2.1 N01 - Retain the populated Store</a></li>
              <li><a href="chapters/ledger-effects.md#ds-state-epoch-n02">3.5.2.2 N02 - Activate the effective price</a></li>
            </ul>
          </details>
        </li>
      </ul>
    </details>
  </li>
</ul>
</details>

<a id="4-derived-distributions" name="4-derived-distributions"></a>

<details open>
<summary><strong>4. Derived distributions</strong> · <a href="chapters/derived-distributions.md">Read chapter</a></summary>
<p>How do stake and voting power follow from the resulting ledger state?</p>
<ul>
  <li>
    <details>
      <summary><a href="chapters/derived-distributions.md#ds-stake">4.1</a> Stake</summary>
      <ul>
        <li><a href="chapters/derived-distributions.md#ds-stake-n01">4.1.1 N01 - counts the full ADA in min-ADA outputs under the existing staking rules</a></li>
        <li><a href="chapters/derived-distributions.md#ds-stake-n02">4.1.2 N02 - counts only application ADA in deposit-backed outputs under the existing staking rules</a></li>
        <li><a href="chapters/derived-distributions.md#ds-stake-n03">4.1.3 N03 - does not add the global Store balance to stake totals</a></li>
        <li><a href="chapters/derived-distributions.md#ds-stake-n04">4.1.4 N04 - Derive stake from applied allocations</a></li>
        <li><a href="chapters/derived-distributions.md#ds-stake-n05">4.1.5 N05 - Derive stake from applied releases</a></li>
        <li><a href="chapters/derived-distributions.md#ds-stake-n06">4.1.6 N06 - Ignore unapplied collateral</a></li>
        <li><a href="chapters/derived-distributions.md#ds-stake-n07">4.1.7 N07 - Derive stake from collateral on phase-2 failure</a></li>
        <li><a href="chapters/derived-distributions.md#ds-stake-n08">4.1.8 N08 - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects</a></li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary><a href="chapters/derived-distributions.md#ds-voting">4.2</a> Voting</summary>
      <ul>
        <li><a href="chapters/derived-distributions.md#ds-voting-n01">4.2.1 N01 - preserves the expected voting distribution from eligible funds while excluding allocated UTxO capacity deposits and Store balance</a></li>
      </ul>
    </details>
  </li>
</ul>
</details>

<a id="appendices" name="appendices"></a>

<details open>
<summary><strong>Appendices</strong> · <a href="chapters/appendices.md">Read appendices</a></summary>
<p>Where are the open design questions, tag migration, implementation references and detailed net-change test cases?</p>
<ul>
  <li>
    <details>
      <summary><a href="chapters/appendices.md#section-8">A.</a> Remaining design work</summary>
      <ul>
        <li><a href="chapters/appendices.md#ds-pricing-history">A.1 Historical pricing</a></li>
        <li><a href="chapters/appendices.md#ds-plutus-compatibility">A.2 Plutus compatibility</a></li>
        <li><a href="chapters/appendices.md#ds-tx-settlement-refinement">A.3 Local settlement</a></li>
        <li><a href="chapters/appendices.md#ds-state-representation">A.4 State representation</a></li>
      </ul>
    </details>
  </li>
  <li><a href="chapters/appendices.md#section-9">B. Tag migration</a></li>
  <li>
    <details>
      <summary><a href="chapters/appendices.md#section-10">C.</a> Code references</summary>
      <ul>
        <li><a href="chapters/appendices.md#declaration-api">C.1 Declaration API</a></li>
        <li><a href="chapters/appendices.md#transaction-body-fields">C.2 Transaction body fields</a></li>
        <li><a href="chapters/appendices.md#declaration-encoding">C.3 Declaration encoding</a></li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary><a href="chapters/appendices.md#net-change-test-cases">D.</a> Net-change test cases</summary>
      <ul>
        <li>
          <details>
            <summary><a href="chapters/appendices.md#subtx-net-change-test-cases">D.1</a> SubTx net-change cases</summary>
            <ul>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-p01">2.1.2.1.1.1 P01 - Each SubTx declares its own exact change</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n01">2.1.2.1.1.2 N01 - Exact own change, with any allocation and release combination</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f01">2.1.2.1.1.3 F01 - Net allocation understated by one lovelace</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f02">2.1.2.1.1.4 F02 - Net allocation overstated by one lovelace</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f03">2.1.2.1.1.5 F03 - Net release understated by one lovelace</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f04">2.1.2.1.1.6 F04 - Net release overstated by one lovelace</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f05">2.1.2.1.1.7 F05 - Opposing SubTx errors cancel in the total</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n02">2.1.2.1.1.8 N02 - Equal own allocations and releases, explicit zero</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f06">2.1.2.1.1.9 F06 - Explicit zero cannot replace a required allocation</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n03">2.1.2.1.1.10 N03 - Exact allocation requested from TopTx</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n04">2.1.2.1.1.11 N04 - Exact release delegated to TopTx</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n05">2.1.2.1.1.12 N05 - Released deposits, only min-ADA outputs</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f07">2.1.2.1.1.13 F07 - Explicit zero cannot replace a required release</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n06">2.1.2.1.1.14 N06 - Another body offsets the SubTx release</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n07">2.1.2.1.1.15 N07 - An output without application assets still requires a deposit</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n08">2.1.2.1.1.16 N08 - A translated min-ADA input funds an exact allocation</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f08">2.1.2.1.1.17 F08 - A translated min-ADA input does not excuse an inexact allocation</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f09">2.1.2.1.1.18 F09 - Unspent outputs cannot increase a SubTx release</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f10">2.1.2.1.1.19 F10 - A release cannot replace a required allocation</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f11">2.1.2.1.1.20 F11 - An allocation cannot replace a required release</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-n09">2.1.2.1.1.21 N09 - Exact SubTx declarations when phase 2 fails</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-subtx-f12">2.1.2.1.1.22 F12 - An inexact SubTx declaration still fails before the collateral outcome</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary><a href="chapters/appendices.md#toptx-net-change-test-cases">D.2</a> TopTx net-change cases</summary>
            <ul>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-p01">2.1.2.1.2.1 P01 - TopTx declares the exact transaction total</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-p02">2.1.2.1.2.2 P02 - Delegation preserves the transaction total</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n01">2.1.2.1.2.3 N01 - TopTx and SubTxs contribute to the total</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n02">2.1.2.1.2.4 N02 - TopTx's own change is derived from its total</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n03">2.1.2.1.2.5 N03 - 5 ADA allocated, 3 ADA released</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n04">2.1.2.1.2.6 N04 - 3 ADA allocated, 5 ADA released</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n05">2.1.2.1.2.7 N05 - Nonzero body changes produce a zero total</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f01">2.1.2.1.2.8 F01 - Standalone TopTx understates its net allocation by one lovelace</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f02">2.1.2.1.2.9 F02 - Standalone TopTx overstates its net allocation by one lovelace</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f03">2.1.2.1.2.10 F03 - Standalone TopTx understates its net release by one lovelace</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f04">2.1.2.1.2.11 F04 - Standalone TopTx overstates its net release by one lovelace</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f05">2.1.2.1.2.12 F05 - Explicit zero cannot replace a nonzero total</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f06">2.1.2.1.2.13 F06 - A nonzero declaration cannot replace a zero total</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f07">2.1.2.1.2.14 F07 - TopTx declares the opposite direction</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n06">2.1.2.1.2.15 N06 - TopTx releases while SubTxs allocate</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n07">2.1.2.1.2.16 N07 - TopTx allocates while SubTxs release</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-n08">2.1.2.1.2.17 N08 - An exact total remains valid when phase 2 fails</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f08">2.1.2.1.2.18 F08 - An inexact total is rejected even when phase 2 fails</a></li>
              <li><a href="chapters/appendices.md#ds-tx-accounting-net-change-toptx-f09">2.1.2.1.2.19 F09 - A delegated change belongs in the total exactly once</a></li>
            </ul>
          </details>
        </li>
      </ul>
    </details>
  </li>
</ul>
</details>

<a id="verification-record" name="verification-record"></a>

<details open>
<summary><strong>Verification record</strong> · <a href="verification.md">Read verification record</a></summary>
<p>Which rules have been tested, and what were the results at each checkpoint?</p>
<ul>
  <li><a href="verification.md#verification-baselines">Verification baselines</a></li>
  <li><a href="verification.md#current-implementation-status">Current implementation status</a></li>
  <li>
    <details>
      <summary>Test infrastructure and verification method · <a href="verification.md#test-infrastructure-and-verification-method">Read section</a></summary>
      <ul>
        <li><a href="verification.md#fixture-cardinality">Fixture cardinality</a></li>
      </ul>
    </details>
  </li>
  <li><a href="verification.md#historical-results">Historical results</a></li>
  <li>
    <details>
      <summary>November 2026</summary>
      <ul>
        <li>
          <details>
            <summary>24 November</summary>
            <ul>
              <li><a href="verification.md#signed-backing-change-for-mixed-output-forms--24-november-2026">Signed backing change for mixed output forms</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>10 November</summary>
            <ul>
              <li><a href="verification.md#output-variant-naming--10-november-2026">Output variant naming</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>8 November</summary>
            <ul>
              <li><a href="verification.md#wills-deposit-formula--8-november-2026">Will's deposit formula</a></li>
              <li><a href="verification.md#typed-deposit-calculation--8-november-2026">Typed deposit calculation</a></li>
              <li><a href="verification.md#active-formula-minimum-coin--8-november-2026">Active-formula minimum coin</a></li>
              <li><a href="verification.md#ci-fixtures--8-november-2026">CI fixtures</a></li>
              <li><a href="verification.md#remaining-suites-and-ci-seed--8-november-2026">Remaining suites and CI seed</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>6 November</summary>
            <ul>
              <li><a href="verification.md#deposit-formula-history-on-6-november-2026">Deposit formula history</a></li>
              <li><a href="verification.md#slot-based-deposit-history-on-6-november-2026">Slot-based deposit history</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>2 November</summary>
            <ul>
              <li>
                <details>
                  <summary>Store transaction projection · <a href="verification.md#store-transaction-projection-on-2-november-2026">Read section</a></summary>
                  <ul>
                    <li><a href="verification.md#public-store-interface-and-internals">Public Store interface and Internals</a></li>
                  </ul>
                </details>
              </li>
              <li><a href="verification.md#leios-integration-checkpoint-on-2-november-2026">Leios integration checkpoint</a></li>
            </ul>
          </details>
        </li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary>26–30 October 2026</summary>
      <ul>
        <li>
          <details>
            <summary>30 October</summary>
            <ul>
              <li><a href="verification.md#ledger-state-domains-on-30-october-2026">Ledger state domains</a></li>
              <li><a href="verification.md#stored-entries-in-output-events-on-30-october-2026">Stored entries in output events</a></li>
              <li><a href="verification.md#shared-body-update-on-30-october-2026">Shared body update</a></li>
              <li><a href="verification.md#store-body-updates-on-30-october-2026">Store body updates</a></li>
              <li><a href="verification.md#store-operation-cleanup-checkpoint-on-30-october-2026">Store operation cleanup checkpoint</a></li>
              <li><a href="verification.md#active-calculation-and-indexed-outputs-on-30-october-2026">Active calculation and indexed outputs</a></li>
              <li><a href="verification.md#output-map-interface-on-30-october-2026">Output map interface</a></li>
              <li>
                <details>
                  <summary>Allocation operations · <a href="verification.md#allocation-operations--30-october-2026">Read section</a></summary>
                  <ul>
                    <li><a href="verification.md#mary-translation-review">Mary translation review</a></li>
                  </ul>
                </details>
              </li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>29 October</summary>
            <ul>
              <li><a href="verification.md#allocation-based-read-contracts-on-29-october-2026">Allocation-based read contracts</a></li>
              <li><a href="verification.md#store-translations-and-composed-reads-on-29-october-2026">Store translations and composed reads</a></li>
              <li><a href="verification.md#direct-store-reads-on-29-october-2026">Direct Store reads</a></li>
              <li><a href="verification.md#shared-store-access-on-29-october-2026">Shared Store access</a></li>
              <li><a href="verification.md#allocation-reads-on-29-october-2026">Allocation reads</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>27 October</summary>
            <ul>
              <li><a href="verification.md#txout-module-extraction-on-27-october-2026">TxOut module extraction</a></li>
              <li><a href="verification.md#utxos-module-extraction-and-deposit-calculation-on-27-october-2026">UTxOs module extraction and deposit calculation</a></li>
              <li><a href="verification.md#pre-namespace-store-api-simplification-and-wrapper-module-on-27-october-2026">Pre-namespace Store API simplification and wrapper module</a></li>
              <li><a href="verification.md#unspent-field-naming-on-27-october-2026">Unspent field naming</a></li>
              <li><a href="verification.md#generic-unspent-metadata-at-52d2c835e-on-27-october-2026">Generic Unspent metadata at 52d2c835e</a></li>
              <li><a href="verification.md#pre-unspent-utxo-module-hierarchy-on-27-october-2026">Pre-Unspent UTxO module hierarchy</a></li>
              <li><a href="verification.md#pre-hierarchy-output-names-and-store-vocabulary-on-27-october-2026">Pre-hierarchy output names and Store vocabulary</a></li>
              <li><a href="verification.md#pre-vocabulary-storage-layout-on-27-october-2026">Pre-vocabulary storage layout</a></li>
              <li><a href="verification.md#pre-edit-style-cleanup-build-on-27-october-2026">Pre-edit style-cleanup build</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>26 October</summary>
            <ul>
              <li><a href="verification.md#depositstore-api-removal-and-record-fields-on-26-october-2026">DepositStore API removal and record fields</a></li>
              <li><a href="verification.md#verified-integration-checkpoint-on-26-october-2026">Verified integration checkpoint</a></li>
              <li><a href="verification.md#historical-map-only-store-revision-on-26-october-2026">Historical map-only Store revision</a></li>
            </ul>
          </details>
        </li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary>19–23 October 2026</summary>
      <ul>
        <li>
          <details>
            <summary>23 October</summary>
            <ul>
              <li><a href="verification.md#ledgereffects-implementation-on-23-october-2026">LedgerEffects implementation</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>20 October</summary>
            <ul>
              <li><a href="verification.md#ledgereffects-contracts-revised-on-20-october-2026">LedgerEffects contracts revised</a></li>
              <li><a href="verification.md#store-specific-collateral-implemented-on-20-october-2026">Store-specific collateral implemented</a></li>
              <li><a href="verification.md#initial-collateral-scope-alignment-on-20-october-2026">Initial collateral scope alignment</a></li>
              <li><a href="verification.md#minimum-coin-implemented-on-20-october-2026">Minimum coin implemented</a></li>
              <li><a href="verification.md#authorization-implemented-on-20-october-2026">Authorization implemented</a></li>
              <li><a href="verification.md#settlement-requirements-implemented-on-20-october-2026">Settlement requirements implemented</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>19 October</summary>
            <ul>
              <li><a href="verification.md#attribution-redistributed-and-implemented-on-19-october-2026">Attribution redistributed and implemented</a></li>
              <li><a href="verification.md#balance-implemented-on-19-october-2026">Balance implemented</a></li>
              <li><a href="verification.md#accounting-hierarchy-verified-on-19-october-2026">Accounting hierarchy</a></li>
              <li><a href="verification.md#declarations-grouping-verified-on-19-october-2026">Declarations grouping</a></li>
              <li>
                <details>
                  <summary>Accounting implementation · <a href="verification.md#accounting-implementation-verified-on-19-october-2026">Read section</a></summary>
                  <ul>
                    <li><a href="verification.md#subtx">SubTx exactness</a></li>
                    <li><a href="verification.md#toptx">TopTx exactness</a></li>
                    <li><a href="verification.md#regression">Regression checks</a></li>
                  </ul>
                </details>
              </li>
              <li><a href="verification.md#exactness-scope-and-contracts-verified-on-19-october-2026">Exactness scope and contracts</a></li>
              <li><a href="verification.md#operations-completion-verified-on-19-october-2026">Operations completion</a></li>
              <li><a href="verification.md#subtx-zero-net-change-verified-on-19-october-2026">SubTx zero net change</a></li>
              <li><a href="verification.md#required-declarations-rename-verified-on-19-october-2026">Required declarations rename</a></li>
              <li><a href="verification.md#presence-narrative-verified-on-19-october-2026">Presence narrative</a></li>
              <li><a href="verification.md#zero-net-change-verified-on-19-october-2026">Zero net change</a></li>
              <li><a href="verification.md#store-operations-vocabulary-verified-on-19-october-2026">Store operations vocabulary</a></li>
            </ul>
          </details>
        </li>
      </ul>
    </details>
  </li>
  <li>
    <details>
      <summary>9–16 October 2026</summary>
      <ul>
        <li>
          <details>
            <summary>16 October</summary>
            <ul>
              <li><a href="verification.md#standalone-allocation-pair-on-16-october-2026">Standalone allocation pair</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>15 October</summary>
            <ul>
              <li>
                <details>
                  <summary>Leios rebase verification · <a href="verification.md#leios-rebase-verification-on-15-october-2026">Read section</a></summary>
                  <ul>
                    <li><a href="verification.md#upstream-batch-script-failures">Upstream batch script failures</a></li>
                  </ul>
                </details>
              </li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>13 October</summary>
            <ul>
              <li><a href="verification.md#release-verification-on-13-october-2026">Release verification</a></li>
              <li><a href="verification.md#initial-recorded-depositstore-implementation-verified-on-13-october-2026">Initial recorded DepositStore implementation</a></li>
              <li><a href="verification.md#earlier-standalone-toptx-contract-split-on-13-october-2026">Earlier standalone TopTx contract split</a></li>
              <li><a href="verification.md#earlier-release-presence-run-on-13-october-2026">Earlier release-presence run</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>12 October</summary>
            <ul>
              <li><a href="verification.md#domain-support-consolidated-on-12-october-2026">Domain support consolidated</a></li>
              <li><a href="verification.md#typed-fixture-generators-verified-on-12-october-2026">Typed fixture generators</a></li>
              <li><a href="verification.md#decoder-input-generation-consolidated-on-12-october-2026">Decoder-input generation consolidated</a></li>
              <li><a href="verification.md#toptx-grammar-generators-verified-on-12-october-2026">TopTx grammar generators</a></li>
              <li><a href="verification.md#subtx-grammar-generators-verified-on-12-october-2026">SubTx grammar generators</a></li>
              <li><a href="verification.md#combined-codec-checks-verified-on-12-october-2026">Combined codec checks</a></li>
              <li><a href="verification.md#subtx-invalid-amount-cases-verified-on-12-october-2026">SubTx invalid-amount cases</a></li>
              <li><a href="verification.md#toptx-and-subtx-grammar-split-verified-on-12-october-2026">TopTx and SubTx Grammar split</a></li>
              <li><a href="verification.md#grammar-assertion-readability-verified-on-12-october-2026">Grammar assertion readability</a></li>
              <li><a href="verification.md#strictlypositivecoin-extraction-and-test-ownership-verified-on-12-october-2026">StrictlyPositiveCoin extraction and test ownership</a></li>
              <li><a href="verification.md#grammar-implementation-structure-verified-on-12-october-2026">Grammar implementation structure</a></li>
              <li><a href="verification.md#grammar-grouping-verification-on-12-october-2026">Grammar grouping verification</a></li>
              <li><a href="verification.md#scope-reduction-verification-on-12-october-2026">Scope reduction verification</a></li>
              <li><a href="verification.md#folder-alignment-verification-on-12-october-2026">Folder alignment verification</a></li>
              <li><a href="verification.md#coherence-verification-on-12-october-2026">Coherence verification</a></li>
              <li><a href="verification.md#earlier-structural-verification-on-12-october-2026">Earlier structural verification</a></li>
            </ul>
          </details>
        </li>
        <li>
          <details>
            <summary>9 October</summary>
            <ul>
              <li>
                <details>
                  <summary>Historical focused results · <a href="verification.md#historical-focused-results-recorded-on-9-october-2026">Read section</a></summary>
                  <ul>
                    <li><a href="verification.md#allocation-presence-evidence">Allocation presence evidence</a></li>
                    <li><a href="verification.md#dependency-evidence">Dependency evidence</a></li>
                  </ul>
                </details>
              </li>
            </ul>
          </details>
        </li>
      </ul>
    </details>
  </li>
</ul>
</details>
