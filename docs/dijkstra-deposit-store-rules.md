# Dijkstra DepositStore specification

This specification states the DepositStore business rules and the cases used to check
them. The rule chapters follow the executable suite’s domain groups and case order.
Short titles introduce each case; formulas state its contract. Semantic tags connect
each requirement to its test independently of section
numbering. The current executable scope covers Transaction rules and Ledger effects;
Deposit calculation and Derived distributions remain documented for later tests.
Implementation status and recorded runs belong in the
[verification record](dijkstra-deposit-store-verification.md).

## Table of contents

Use the arrows to expand a domain, responsibility or case group. Select a title to jump
to it. The parent sections remain visible and follow the reading order:
**Domain model → Transaction rules → Ledger effects → Derived distributions**.
Appendices contain the open design questions and supporting references.

<dl>
  <dt><strong><a href="#domain-model">1. Domain model</a></strong></dt>
  <dd>
    <a href="#section-1">1.1 Outputs</a><br>
    <a href="#section-1-1">1.2 DepositStore</a><br>
    <a href="#section-1-4">1.3 Transaction bodies</a><br>
    <details>
      <summary><a href="#ds-pricing">1.4 Deposit calculation</a></summary>
      <dl>
        <dd>
          <a href="#ds-pricing-p01">1.4.1 P01 - Records the deposit priced from accepted bytes</a><br>
          <a href="#ds-pricing-n01">1.4.2 N01 - allocates each UTxO capacity deposit as coinsPerUTxOByte * (160 + accepted serialized output size)</a><br>
          <a href="#ds-pricing-n02">1.4.3 N02 - uses the same UTxO capacity deposit formula for a store-backed collateral return</a><br>
          <a href="#ds-pricing-n03">1.4.4 N03 - includes address, application assets, datum and reference script in the priced size</a><br>
          <a href="#ds-pricing-n04">1.4.5 N04 - excludes the external UTxO capacity deposit amount and Store declaration from the priced output</a><br>
          <a href="#ds-pricing-n05">1.4.6 N05 - handles CBOR size boundaries when an application coin amount changes</a><br>
          <a href="#ds-pricing-n06">1.4.7 N06 - assigns no DepositStore obligation to implicit outputs</a><br>
        </dd>
      </dl>
    </details>
  </dd>
</dl>

<dl>
  <dt><strong><a href="#transaction-rules">2. Transaction rules</a></strong></dt>
  <dd>
    <details>
      <summary><a href="#ds-tx">2.1 Tx</a></summary>
      <dl>
        <dd>
          <details>
            <summary><a href="#ds-tx-declarations">2.1.1 Declarations</a></summary>
            <dl>
              <dd>
                <details>
                  <summary><a href="#ds-tx-declarations-grammar">2.1.1.1 Grammar</a></summary>
                  <dl>
                    <dd>
                      <details>
                        <summary><a href="#ds-tx-declarations-grammar-toptx">2.1.1.1.1 TopTx</a></summary>
                        <dl>
                          <dd>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-toptx-amounts">2.1.1.1.1.1 Amounts</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-p01">2.1.1.1.1.1.1 P01 - Positive amounts survive encoding</a><br>
                                  <a href="#ds-tx-declarations-grammar-f01">2.1.1.1.1.1.2 F01 - Zero operation amount</a><br>
                                  <a href="#ds-tx-declarations-grammar-f12">2.1.1.1.1.1.3 F12 - Negative operation amount</a><br>
                                  <a href="#ds-tx-declarations-grammar-f13">2.1.1.1.1.1.4 F13 - Overflowing operation amount</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-toptx-absence">2.1.1.1.1.2 Absence</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-n03">2.1.1.1.1.2.1 N03 - Absence remains distinct from zero</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-toptx-forms">2.1.1.1.1.3 Forms</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-n05">2.1.1.1.1.3.1 N05 - Every TopTx declaration form</a><br>
                                  <a href="#ds-tx-declarations-grammar-f06">2.1.1.1.1.3.2 F06 - Funding request in TopTx</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-toptx-structure">2.1.1.1.1.4 Structure</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-f02">2.1.1.1.1.4.1 F02 - Malformed declarations</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-toptx-destinations">2.1.1.1.1.5 Destinations</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-f04">2.1.1.1.1.5.1 F04 - Malformed release settlements</a><br>
                                  <a href="#ds-tx-declarations-grammar-f14">2.1.1.1.1.5.2 F14 - Negative output index</a><br>
                                  <a href="#ds-tx-declarations-grammar-f15">2.1.1.1.1.5.3 F15 - Overflowing output index</a><br>
                                </dd>
                              </dl>
                            </details>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-declarations-grammar-subtx">2.1.1.1.2 SubTx</a></summary>
                        <dl>
                          <dd>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-subtx-amounts">2.1.1.1.2.1 Amounts</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-p02">2.1.1.1.2.1.1 P02 - Positive amounts survive encoding</a><br>
                                  <a href="#ds-tx-declarations-grammar-f07">2.1.1.1.2.1.2 F07 - Zero operation amount</a><br>
                                  <a href="#ds-tx-declarations-grammar-f08">2.1.1.1.2.1.3 F08 - Negative operation amount</a><br>
                                  <a href="#ds-tx-declarations-grammar-f09">2.1.1.1.2.1.4 F09 - Overflowing operation amount</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-subtx-absence">2.1.1.1.2.2 Absence</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-n04">2.1.1.1.2.2.1 N04 - Absence remains distinct from zero</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-subtx-forms">2.1.1.1.2.3 Forms</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-n06">2.1.1.1.2.3.1 N06 - Every SubTx declaration form</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-subtx-structure">2.1.1.1.2.4 Structure</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-f03">2.1.1.1.2.4.1 F03 - Malformed declarations</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-grammar-subtx-destinations">2.1.1.1.2.5 Destinations</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-grammar-f05">2.1.1.1.2.5.1 F05 - Malformed release targets</a><br>
                                  <a href="#ds-tx-declarations-grammar-f10">2.1.1.1.2.5.2 F10 - Negative output index</a><br>
                                  <a href="#ds-tx-declarations-grammar-f11">2.1.1.1.2.5.3 F11 - Overflowing output index</a><br>
                                </dd>
                              </dl>
                            </details>
                          </dd>
                        </dl>
                      </details>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-declarations-requirements">2.1.1.2 Requirements</a></summary>
                  <dl>
                    <dd>
                      <details>
                        <summary><a href="#ds-tx-declarations-requirements-operations">2.1.1.2.1 Operations</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-declarations-requirements-operations-p01">2.1.1.2.1.1 P01 - Every body requiring a Store operation declares</a><br>
                            <details>
                              <summary><a href="#ds-tx-declarations-requirements-operations-allocation">2.1.1.2.1.2 Allocation</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-n01">2.1.1.2.1.2.1 N01 - Every explicit declaration satisfies allocation presence</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-n02">2.1.1.2.1.2.2 N02 - Absence satisfies allocation presence for empty or implicit-only own outputs</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-f01">2.1.1.2.1.2.3 F01 - Missing declaration fails allocation presence at every own-output position</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-n03">2.1.1.2.1.2.4 N03 - accepts a TopTx creating only implicit outputs without a declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-n04">2.1.1.2.1.2.5 N04 - accepts a SubTx creating only implicit outputs without either body's declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-n05">2.1.1.2.1.2.6 N05 - Standalone TopTx, exact allocation declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-f02">2.1.1.2.1.2.7 F02 - Standalone TopTx, allocation without a declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-f03">2.1.1.2.1.2.8 F03 - rejects a SubTx creating a store-backed output without its own declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-f04">2.1.1.2.1.2.9 F04 - rejects a TopTx creating a store-backed output without its own declaration even when phase 2 fails</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-f05">2.1.1.2.1.2.10 F05 - rejects a SubTx creating a store-backed output without its own declaration even when phase 2 fails</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-f06">2.1.1.2.1.2.11 F06 - rejects a missing own declaration when spending a translated implicit output to create store-backed outputs</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-n06">2.1.1.2.1.2.12 N06 - SubTx outputs do not trigger TopTx allocation presence</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-n07">2.1.1.2.1.2.13 N07 - Collateral return does not trigger allocation presence</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-n08">2.1.1.2.1.2.14 N08 - Reference and collateral input identifiers do not trigger allocation presence</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-f07">2.1.1.2.1.2.15 F07 - A SubTx declaration cannot satisfy TopTx allocation presence</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-f08">2.1.1.2.1.2.16 F08 - TopTx zero cannot satisfy its allocating SubTx's declaration requirement</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-allocation-n09">2.1.1.2.1.2.17 N09 - TopTx and SubTx allocate deposits, each with an exact declaration</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-requirements-operations-release">2.1.1.2.1.3 Release</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n01">2.1.1.2.1.3.1 N01 - Standalone TopTx, any output form</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n02">2.1.1.2.1.3.2 N02 - Standalone TopTx, only implicit outputs</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n03">2.1.1.2.1.3.3 N03 - One SubTx releases its deposit into its own output</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-f01">2.1.1.2.1.3.4 F01 - Standalone TopTx, release without its own declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-f02">2.1.1.2.1.3.5 F02 - SubTx release without its own declaration, despite TopTx declaring</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n04">2.1.1.2.1.3.6 N04 - Phase 2 fails with valid declarations</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-f03">2.1.1.2.1.3.7 F03 - Missing release declaration in a phase-2-invalid proposal</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n05">2.1.1.2.1.3.8 N05 - Several SubTxs release their deposits</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-f04">2.1.1.2.1.3.9 F04 - One SubTx releasing deposits omits its declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n06">2.1.1.2.1.3.10 N06 - Only some SubTxs release Store deposits</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n07">2.1.1.2.1.3.11 N07 - TopTx and several SubTxs release deposits</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n08">2.1.1.2.1.3.12 N08 - Phase 2 fails with several proposed SubTx releases</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-f05">2.1.1.2.1.3.13 F05 - One SubTx declaration is missing in a phase-2-invalid proposal</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n09">2.1.1.2.1.3.14 N09 - Standalone TopTx, reference-only Store access</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-n10">2.1.1.2.1.3.15 N10 - Standalone TopTx, collateral-only Store operations</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-release-f06">2.1.1.2.1.3.16 F06 - A SubTx declaration cannot satisfy TopTx release presence</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-requirements-operations-zero-net-change">2.1.1.2.1.4 Zero net change</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-n01">2.1.1.2.1.4.1 N01 - Standalone TopTx, equal allocations and releases with explicit zero</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-f01">2.1.1.2.1.4.2 F01 - Standalone TopTx, equal allocations and releases without a declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-n02">2.1.1.2.1.4.3 N02 - One SubTx replaces its deposit with explicit zero</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-f02">2.1.1.2.1.4.4 F02 - One active SubTx omits its declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-f03">2.1.1.2.1.4.5 F03 - TopTx omits the declaration required by its child</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-n03">2.1.1.2.1.4.6 N03 - Several SubTxs each replace their deposits</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-f04">2.1.1.2.1.4.7 F04 - One of several active SubTxs omits its declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-n04">2.1.1.2.1.4.8 N04 - Only some SubTxs replace Store deposits</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-f05">2.1.1.2.1.4.9 F05 - One active SubTx omits its declaration among inactive siblings</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-n05">2.1.1.2.1.4.10 N05 - TopTx and several SubTxs each replace their deposits</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-f06">2.1.1.2.1.4.11 F06 - Active TopTx omits its own declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-n06">2.1.1.2.1.4.12 N06 - Phase 2 fails with explicit zero at every active body</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-f07">2.1.1.2.1.4.13 F07 - One SubTx declaration is missing in a phase-2-invalid proposal</a><br>
                                  <a href="#ds-tx-declarations-requirements-operations-zero-net-change-f08">2.1.1.2.1.4.14 F08 - TopTx's own declaration is missing in a phase-2-invalid proposal</a><br>
                                </dd>
                              </dl>
                            </details>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-declarations-requirements-subtx-declarations">2.1.1.2.2 SubTx declarations</a></summary>
                        <dl>
                          <dd>
                            <details>
                              <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c01">2.1.1.2.2.1 TopTx requirement</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c01-p01">2.1.1.2.2.1.1 P01 - SubTx declarations require TopTx's declaration</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c02">2.1.1.2.2.2 Absence and explicit zero</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c02-n01">2.1.1.2.2.2.1 N01 - accepts absent declarations at both levels</a><br>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c02-n02">2.1.1.2.2.2.2 N02 - accepts explicit zero at both levels</a><br>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c02-n03">2.1.1.2.2.2.3 N03 - accepts TopTx zero without a SubTx declaration</a><br>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c02-f01">2.1.1.2.2.2.4 F01 - rejects SubTx zero without a TopTx declaration</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c03">2.1.1.2.2.3 Offsetting SubTx contributions</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c03-n01">2.1.1.2.2.3.1 N01 - passes declaration presence with TopTx declaring the zero net amount</a><br>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c03-f01">2.1.1.2.2.3.2 F01 - rejects an absent TopTx declaration despite the zero net amount</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c04">2.1.1.2.2.4 Local and delegated accounting</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c04-n01">2.1.1.2.2.4.1 N01 - passes declaration presence with TopTx zero for every explicit SubTx form</a><br>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c04-f01">2.1.1.2.2.4.2 F01 - rejects an absent TopTx declaration for every explicit SubTx form</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c05">2.1.1.2.2.5 Phase-2 failure</a></summary>
                              <dl>
                                <dd>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c05-n01">2.1.1.2.2.5.1 N01 - accepts zero declarations at both levels on the phase-2 failure path</a><br>
                                  <a href="#ds-tx-declarations-requirements-subtx-declarations-c05-f01">2.1.1.2.2.5.2 F01 - rejects SubTx zero without a TopTx declaration on the phase-2 failure path</a><br>
                                </dd>
                              </dl>
                            </details>
                          </dd>
                        </dl>
                      </details>
                    </dd>
                  </dl>
                </details>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-accounting">2.1.2 Accounting</a></summary>
            <dl>
              <dd>
                <details>
                  <summary><a href="#ds-tx-accounting-net-change">2.1.2.1 Net change</a></summary>
                  <dl>
                    <dd>
                      <details>
                        <summary><a href="#ds-tx-accounting-net-change-subtx">2.1.2.1.1 SubTx</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-accounting-net-change-subtx-p01">2.1.2.1.1.1 P01 - Each SubTx declares its own exact change</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n01">2.1.2.1.1.2 N01 - Exact own change, with any allocation and release combination</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f01">2.1.2.1.1.3 F01 - Net allocation understated by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f02">2.1.2.1.1.4 F02 - Net allocation overstated by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f03">2.1.2.1.1.5 F03 - Net release understated by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f04">2.1.2.1.1.6 F04 - Net release overstated by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f05">2.1.2.1.1.7 F05 - Opposing SubTx errors cancel in the total</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n02">2.1.2.1.1.8 N02 - Equal own allocations and releases, explicit zero</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f06">2.1.2.1.1.9 F06 - Explicit zero cannot replace a required allocation</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n03">2.1.2.1.1.10 N03 - Exact allocation requested from TopTx</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n04">2.1.2.1.1.11 N04 - Exact release delegated to TopTx</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n05">2.1.2.1.1.12 N05 - Released deposits, only implicit outputs</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f07">2.1.2.1.1.13 F07 - Explicit zero cannot replace a required release</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n06">2.1.2.1.1.14 N06 - Another body offsets the SubTx release</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n07">2.1.2.1.1.15 N07 - An output without application assets still requires a deposit</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n08">2.1.2.1.1.16 N08 - A translated implicit input funds an exact allocation</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f08">2.1.2.1.1.17 F08 - A translated implicit input does not excuse an inexact allocation</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f09">2.1.2.1.1.18 F09 - Store surplus cannot increase a SubTx release</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f10">2.1.2.1.1.19 F10 - A release cannot replace a required allocation</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f11">2.1.2.1.1.20 F11 - An allocation cannot replace a required release</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n09">2.1.2.1.1.21 N09 - Exact SubTx declarations when phase 2 fails</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f12">2.1.2.1.1.22 F12 - An inexact SubTx declaration still fails before the collateral outcome</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-accounting-net-change-toptx">2.1.2.1.2 TopTx</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-accounting-net-change-toptx-p01">2.1.2.1.2.1 P01 - TopTx declares the exact transaction total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n01">2.1.2.1.2.2 N01 - TopTx and SubTxs contribute to the total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n02">2.1.2.1.2.3 N02 - TopTx's own change is derived from its total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n03">2.1.2.1.2.4 N03 - 5 ADA allocated, 3 ADA released</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n04">2.1.2.1.2.5 N04 - 3 ADA allocated, 5 ADA released</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n05">2.1.2.1.2.6 N05 - Nonzero body changes produce a zero total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f01">2.1.2.1.2.7 F01 - Standalone TopTx understates its net allocation by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f02">2.1.2.1.2.8 F02 - Standalone TopTx overstates its net allocation by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f03">2.1.2.1.2.9 F03 - Standalone TopTx understates its net release by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f04">2.1.2.1.2.10 F04 - Standalone TopTx overstates its net release by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f05">2.1.2.1.2.11 F05 - Explicit zero cannot replace a nonzero total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f06">2.1.2.1.2.12 F06 - A nonzero declaration cannot replace a zero total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f07">2.1.2.1.2.13 F07 - TopTx declares the opposite direction</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n06">2.1.2.1.2.14 N06 - TopTx releases while SubTxs allocate</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n07">2.1.2.1.2.15 N07 - TopTx allocates while SubTxs release</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n08">2.1.2.1.2.16 N08 - An exact total remains valid when phase 2 fails</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f08">2.1.2.1.2.17 F08 - An inexact total is rejected even when phase 2 fails</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f09">2.1.2.1.2.18 F09 - A delegated change belongs in the total exactly once</a><br>
                          </dd>
                        </dl>
                      </details>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-accounting-balance">2.1.2.2 Balance</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-accounting-balance-p01">2.1.2.2.1 P01 - The transaction conserves value when phase 2 is valid</a><br>
                      <a href="#ds-tx-accounting-balance-p02">2.1.2.2.2 P02 - Complete balance determines acceptance</a><br>
                      <a href="#ds-tx-accounting-balance-n01">2.1.2.2.3 N01 - Fund a net allocation once</a><br>
                      <a href="#ds-tx-accounting-balance-n02">2.1.2.2.4 N02 - Use a net release once</a><br>
                      <a href="#ds-tx-accounting-balance-n03">2.1.2.2.5 N03 - One SubTx funds another</a><br>
                      <a href="#ds-tx-accounting-balance-n04">2.1.2.2.6 N04 - A SubTx funds TopTx fees</a><br>
                      <a href="#ds-tx-accounting-balance-f01">2.1.2.2.7 F01 - One-lovelace deficit or surplus</a><br>
                      <a href="#ds-tx-accounting-balance-f02">2.1.2.2.8 F02 - Native-asset quantity or identity mismatch</a><br>
                      <a href="#ds-tx-accounting-balance-f03">2.1.2.2.9 F03 - An exact delegated allocation lacks funding</a><br>
                      <a href="#ds-tx-accounting-balance-n05">2.1.2.2.10 N05 - Equal delegated allocations and releases</a><br>
                      <a href="#ds-tx-accounting-balance-n06">2.1.2.2.11 N06 - Ten input ADA plus two released ADA</a><br>
                      <a href="#ds-tx-accounting-balance-n07">2.1.2.2.12 N07 - Released ADA contributes to TopTx fees</a><br>
                      <a href="#ds-tx-accounting-balance-f04">2.1.2.2.13 F04 - Released ADA cannot disappear</a><br>
                      <a href="#ds-tx-accounting-balance-n08">2.1.2.2.14 N08 - Balanced proposal, failed phase 2</a><br>
                    </dd>
                  </dl>
                </details>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-attribution">2.1.3 Attribution</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-attribution-p01">2.1.3.1 P01 - observed TopTx and local SubTx attribution matches the independent signed contribution projection</a><br>
                <a href="#ds-tx-attribution-p02">2.1.3.2 P02 - switching local and delegated accounting changes attribution by the signed contribution and preserves the required batch change</a><br>
                <a href="#ds-tx-attribution-n01">2.1.3.3 N01 - counts delegated funding once in TopTx accounting</a><br>
                <a href="#ds-tx-attribution-n02">2.1.3.4 N02 - keeps the same batch net change when a SubTx delegates funding of its net allocation</a><br>
                <a href="#ds-tx-attribution-n03">2.1.3.5 N03 - allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx</a><br>
                <a href="#ds-tx-attribution-n04">2.1.3.6 N04 - observes zero local and delegated amounts with no funding request for SubTx explicit zero</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-authorization">2.1.4 Authorization</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-authorization-n01">2.1.4.1 N01 - allows the authorized spender to release UTxO capacity deposits paid by another person</a><br>
                <a href="#ds-tx-authorization-n02">2.1.4.2 N02 - does not require a separate signature from the original UTxO capacity deposit funder</a><br>
                <a href="#ds-tx-authorization-f01">2.1.4.3 F01 - rejects spending by the original funder without the current spending authority even when the Store declaration is exact</a><br>
                <a href="#ds-tx-authorization-n03">2.1.4.4 N03 - gains no release authority merely by referencing a store-backed output</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-settlement">2.1.5 Settlement</a></summary>
            <dl>
              <dd>
                <details>
                  <summary><a href="#ds-tx-settlement-participation">2.1.5.1 Participation</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-participation-p01">2.1.5.1.1 P01 - TopTx settles its attributed release</a><br>
                      <a href="#ds-tx-settlement-participation-n01">2.1.5.1.2 N01 - requires NoTopTxSettlement when SubTxs settle the entire net release locally</a><br>
                      <a href="#ds-tx-settlement-participation-n02">2.1.5.1.3 N02 - requires a TopTx settlement output when the batch declares a net release and TopTx has a positive share</a><br>
                      <a href="#ds-tx-settlement-participation-n03">2.1.5.1.4 N03 - accepts a net release settled across TopTx and SubTx outputs</a><br>
                      <a href="#ds-tx-settlement-participation-n04">2.1.5.1.5 N04 - allows TopTx's settlement amount to exceed the batch net release when SubTxs account for net allocations locally</a><br>
                      <a href="#ds-tx-settlement-participation-f01">2.1.5.1.6 F01 - rejects NoTopTxSettlement when the batch declares a net release and TopTx has a positive share</a><br>
                      <a href="#ds-tx-settlement-participation-f02">2.1.5.1.7 F02 - rejects a TopTx settlement output when TopTx has no net release to settle</a><br>
                      <a href="#ds-tx-settlement-participation-n05">2.1.5.1.8 N05 - does not require a TopTx settlement output when the batch declares a net allocation</a><br>
                      <a href="#ds-tx-settlement-participation-n06">2.1.5.1.9 N06 - does not require a TopTx settlement output for an explicit-zero batch even when TopTx's derived accounting portion is negative</a><br>
                      <a href="#ds-tx-settlement-participation-n07">2.1.5.1.10 N07 - accepts NoTopTxSettlement when TopTx's attributed contribution is a net allocation</a><br>
                      <a href="#ds-tx-settlement-participation-n08">2.1.5.1.11 N08 - accepts correct release participation on the phase-2 failure path</a><br>
                      <a href="#ds-tx-settlement-participation-f03">2.1.5.1.12 F03 - rejects incorrect release participation even when phase 2 fails</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-settlement-destination">2.1.5.2 Destination</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-destination-p01">2.1.5.2.1 P01 - Settlement indices belong to their own body</a><br>
                      <a href="#ds-tx-settlement-destination-f01">2.1.5.2.2 F01 - rejects an index outside the declaring body's output sequence</a><br>
                      <a href="#ds-tx-settlement-destination-f02">2.1.5.2.3 F02 - does not resolve a SubTx settlement index against TopTx outputs</a><br>
                      <a href="#ds-tx-settlement-destination-f03">2.1.5.2.4 F03 - does not resolve a settlement index against collateral return</a><br>
                      <a href="#ds-tx-settlement-destination-f04">2.1.5.2.5 F04 - rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs</a><br>
                      <a href="#ds-tx-settlement-destination-n01">2.1.5.2.6 N01 - accepts the first and last own regular output as settlement destinations</a><br>
                      <a href="#ds-tx-settlement-destination-f05">2.1.5.2.7 F05 - does not resolve a TopTx settlement index against nested SubTx outputs</a><br>
                      <a href="#ds-tx-settlement-destination-f06">2.1.5.2.8 F06 - does not resolve a SubTx settlement index against a sibling SubTx's outputs</a><br>
                      <a href="#ds-tx-settlement-destination-n02">2.1.5.2.9 N02 - accepts valid ordinary settlement destinations on the phase-2 failure path</a><br>
                      <a href="#ds-tx-settlement-destination-f07">2.1.5.2.10 F07 - rejects an invalid ordinary settlement index even when phase 2 fails</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-settlement-coverage">2.1.5.3 Coverage</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-coverage-p01">2.1.5.3.1 P01 - Settlement outputs cover their release share</a><br>
                      <a href="#ds-tx-settlement-coverage-f01">2.1.5.3.2 F01 - rejects a settlement output containing less ADA than its settlement amount</a><br>
                      <a href="#ds-tx-settlement-coverage-n01">2.1.5.3.3 N01 - accepts a settlement output containing exactly its settlement amount</a><br>
                      <a href="#ds-tx-settlement-coverage-n02">2.1.5.3.4 N02 - accepts a settlement output containing the settlement amount and additional funds</a><br>
                      <a href="#ds-tx-settlement-coverage-f02">2.1.5.3.5 F02 - rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference</a><br>
                      <a href="#ds-tx-settlement-coverage-n03">2.1.5.3.6 N03 - accepts a store-backed settlement output with application ADA equal to the settlement amount</a><br>
                      <a href="#ds-tx-settlement-coverage-n04">2.1.5.3.7 N04 - checks TopTx's derived settlement amount rather than the entire batch net release</a><br>
                      <a href="#ds-tx-settlement-coverage-n05">2.1.5.3.8 N05 - accepts covered ordinary settlement outputs on the phase-2 failure path</a><br>
                      <a href="#ds-tx-settlement-coverage-f03">2.1.5.3.9 F03 - rejects insufficient ordinary settlement coverage even when phase 2 fails</a><br>
                      <a href="#ds-tx-settlement-coverage-f04">2.1.5.3.10 F04 - rejects a TopTx output that covers the batch release but not TopTx's larger attributed release</a><br>
                    </dd>
                  </dl>
                </details>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-application-assets">2.1.6 Application assets</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-application-assets-n01">2.1.6.1 N01 - accepts a store-backed output containing native assets and zero ADA</a><br>
                <a href="#ds-tx-application-assets-n02">2.1.6.2 N02 - accepts empty application assets with a datum or reference script</a><br>
                <a href="#ds-tx-application-assets-n03">2.1.6.3 N03 - accepts a store-backed output containing only an address</a><br>
                <a href="#ds-tx-application-assets-n04">2.1.6.4 N04 - accepts implicit outputs containing exactly their required minimum coin</a><br>
                <a href="#ds-tx-application-assets-f01">2.1.6.5 F01 - rejects implicit outputs one lovelace below their required minimum coin</a><br>
              </dd>
            </dl>
          </details>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-collateral">2.2 Collateral</a></summary>
      <dl>
        <dd>
          <details>
            <summary><a href="#ds-collateral-scope">2.2.1 Scope</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-scope-f01">2.2.1.1 F01 - rejects TopTx redeemers without collateral</a><br>
                <a href="#ds-collateral-scope-f02">2.2.1.2 F02 - rejects SubTx redeemers without collateral even when TopTx has none</a><br>
                <a href="#ds-collateral-scope-f03">2.2.1.3 F03 - rejects redeemers in both TopTx and SubTxs without collateral</a><br>
                <a href="#ds-collateral-scope-n01">2.2.1.4 N01 - does not require collateral merely because a transaction uses the DepositStore</a><br>
                <a href="#ds-collateral-scope-n02">2.2.1.5 N02 - does not apply redeemer-gated funding or supplied-total checks when no body has redeemers</a><br>
                <a href="#ds-collateral-scope-f04">2.2.1.6 F04 - rejects independently invalid collateral inputs or returns without redeemers</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-authorization">2.2.2 Authorization</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-authorization-f01">2.2.2.1 F01 - rejects a script-controlled collateral input when collateral validation applies</a><br>
                <a href="#ds-collateral-authorization-f02">2.2.2.2 F02 - rejects a key-controlled collateral input whose required payment-key witness is missing</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-funding">2.2.3 Funding</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-funding-f01">2.2.3.1 F01 - rejects insufficient collateral funding when redeemers trigger validation even if all scripts succeed</a><br>
                <a href="#ds-collateral-funding-n01">2.2.3.2 N01 - accepts a batch whose scripts succeed when its required collateral is fully funded and all other rules hold</a><br>
                <a href="#ds-collateral-funding-n02">2.2.3.3 N02 - accepts funded collateral with implicit or store-backed inputs and returns</a><br>
                <a href="#ds-collateral-funding-n03">2.2.3.4 N03 - reuses released UTxO capacity deposits when the collateral return requires the same amount</a><br>
                <a href="#ds-collateral-funding-n04">2.2.3.5 N04 - funds additional return UTxO capacity deposits from collateral coins</a><br>
                <a href="#ds-collateral-funding-f02">2.2.3.6 F02 - rejects collateral coins below the minimum fee after funding the return and additional UTxO capacity deposits</a><br>
                <a href="#ds-collateral-funding-p01">2.2.3.7 P01 - Collateral coins cover the minimum</a><br>
                <a href="#ds-collateral-funding-f03">2.2.3.8 F03 - rejects collateral whose minimum fee depends on released UTxO capacity deposit surplus</a><br>
                <a href="#ds-collateral-funding-f04">2.2.3.9 F04 - rejects a collateral return whose funding depends on released UTxO capacity deposit surplus</a><br>
                <a href="#ds-collateral-funding-f05">2.2.3.10 F05 - rejects collateral funding one lovelace below a rounded-up minimum fee</a><br>
                <a href="#ds-collateral-funding-n05">2.2.3.11 N05 - counts implicit collateral inputs' full ADA as coins and zero released Store deposits when mixed with store-backed inputs</a><br>
                <a href="#ds-collateral-funding-n06">2.2.3.12 N06 - requires zero Store deposit for an implicit collateral return even with store-backed collateral inputs</a><br>
                <a href="#ds-collateral-funding-n07">2.2.3.13 N07 - accepts a store-backed collateral return with zero application ADA when its deposit and the minimum fee are funded</a><br>
                <a href="#ds-collateral-funding-f06">2.2.3.14 F06 - rejects underfunded collateral when the optional total is absent</a><br>
                <a href="#ds-collateral-funding-n08">2.2.3.15 N08 - accepts collateral funding exactly at a rounded-up minimum fee</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-surplus">2.2.4 Surplus</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-surplus-n01">2.2.4.1 N01 - credits excess released UTxO capacity deposits to fees rather than the treasury</a><br>
                <a href="#ds-collateral-surplus-p01">2.2.4.2 P01 - Released surplus reaches fees</a><br>
                <a href="#ds-collateral-surplus-p02">2.2.4.3 P02 - Treasury remains unchanged</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-total">2.2.5 Total</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-total-n01">2.2.5.1 N01 - accepts a declared total equal to collateral input coins minus return coins</a><br>
                <a href="#ds-collateral-total-f01">2.2.5.2 F01 - rejects a declared total differing by one lovelace when collateral validation applies</a><br>
                <a href="#ds-collateral-total-f02">2.2.5.3 F02 - rejects an incorrect supplied total when redeemers trigger collateral validation even if all scripts succeed</a><br>
                <a href="#ds-collateral-total-n02">2.2.5.4 N02 - includes coins funding additional UTxO capacity deposits in the declared total</a><br>
                <a href="#ds-collateral-total-n03">2.2.5.5 N03 - excludes UTxO capacity deposits released from the Store from the declared total</a><br>
                <a href="#ds-collateral-total-n04">2.2.5.6 N04 - accepts an absent optional total when collateral validation applies and all collateral rules hold</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-settlement">2.2.6 Settlement</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-settlement-n01">2.2.6.1 N01 - derives Store changes from collateral inputs and return without a separate declaration</a><br>
                <a href="#ds-collateral-settlement-p01">2.2.6.2 P01 - derived collateral Store change is independent of ordinary Store declarations</a><br>
                <a href="#ds-collateral-settlement-n02">2.2.6.3 N02 - derives the released Store amount from multiple ADA-only collateral inputs with no return</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-conservation">2.2.7 Conservation</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-conservation-n01">2.2.7.1 N01 - conserves ADA for mixed collateral inputs when return storage needs an additional deposit</a><br>
                <a href="#ds-collateral-conservation-p01">2.2.7.2 P01 - Collateral settlement conserves ADA</a><br>
                <a href="#ds-collateral-conservation-f01">2.2.7.3 F01 - rejects missing, added or changed native assets in the collateral return</a><br>
                <a href="#ds-collateral-conservation-n02">2.2.7.4 N02 - accepts native-asset collateral when its return preserves every asset and quantity</a><br>
                <a href="#ds-collateral-conservation-f02">2.2.7.5 F02 - rejects token-bearing collateral when no return is specified</a><br>
              </dd>
            </dl>
          </details>
        </dd>
      </dl>
    </details>
  </dd>
</dl>

<dl>
  <dt><strong><a href="#ds-state">3. Ledger effects</a></strong></dt>
  <dd>
    <details>
      <summary><a href="#ds-state-execution">3.1 Execution</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-execution-p01">3.1.1 P01 - Apply ordinary UTxO effects</a><br>
          <a href="#ds-state-execution-n01">3.1.2 N01 - applies ordinary effects and no collateral effects on success, including when input roles overlap</a><br>
          <a href="#ds-state-execution-n02">3.1.3 N02 - applies collateral settlement and no ordinary Store operations on an accepted phase-2 failure</a><br>
          <a href="#ds-state-execution-n03">3.1.4 N03 - consumes only collateral inputs and creates only the specified collateral return in the UTxO on an accepted phase-2 failure</a><br>
          <a href="#ds-state-execution-n04">3.1.5 N04 - does not credit the settlement amount to the selected output a second time</a><br>
          <a href="#ds-state-execution-f01">3.1.6 F01 - leaves the entire ledger state unchanged when a later body rejects a batch after earlier SubTx processing</a><br>
          <a href="#ds-state-execution-p02">3.1.7 P02 - Preserve state on rejection</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-allocations">3.2 Allocations</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-allocations-p01">3.2.1 P01 - Release recorded input deposits</a><br>
          <a href="#ds-state-allocations-n01">3.2.2 N01 - records the allocated UTxO capacity deposit alongside each newly created store-backed output</a><br>
          <a href="#ds-state-allocations-n02">3.2.3 N02 - removes a spent output's UTxO capacity deposit record and releases its UTxO capacity deposit exactly once</a><br>
          <a href="#ds-state-allocations-n03">3.2.4 N03 - keeps UTxO capacity deposit records unchanged when outputs are only referenced</a><br>
          <a href="#ds-state-allocations-n04">3.2.5 N04 - Match live allocations to obligations</a><br>
          <a href="#ds-state-allocations-n05">3.2.6 N05 - does not leave missing or orphan UTxO capacity deposit records after accepted transitions</a><br>
          <a href="#ds-state-allocations-n06">3.2.7 N06 - releases the allocated UTxO capacity deposit even when reserialization would change the output size</a><br>
          <a href="#ds-state-allocations-n07">3.2.8 N07 - does not release UTxO capacity deposits from the DepositStore when a translated implicit output is spent</a><br>
          <a href="#ds-state-allocations-p02">3.2.9 P02 - Update obligations on ordinary success</a><br>
          <a href="#ds-state-allocations-n08">3.2.10 N08 - removes consumed store-backed collateral records and records the return only when store-backed, preserving records outside collateral inputs on an accepted phase-2 failure</a><br>
          <a href="#ds-state-allocations-p03">3.2.11 P03 - Update obligations on phase-2 failure</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-balance">3.3 Balance</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-balance-p01">3.3.1 P01 - Apply the declared net transfer</a><br>
          <a href="#ds-state-balance-n01">3.3.2 N01 - changes the balance by exactly the applied allocations minus releases</a><br>
          <a href="#ds-state-balance-p02">3.3.3 P02 - Apply collateral’s net transfer</a><br>
          <a href="#ds-state-balance-p03">3.3.4 P03 - Preserve Store surplus</a><br>
          <a href="#ds-state-balance-n02">3.3.5 N02 - preserves pre-existing Store surplus across ordinary success and accepted phase-2 failure</a><br>
          <a href="#ds-state-balance-n03">3.3.6 N03 - applies no ordinary Store transfer when every declaration is absent</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-solvency">3.4 Solvency</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-solvency-p01">3.4.1 P01 - Keep every accepted state solvent</a><br>
          <a href="#ds-state-solvency-n01">3.4.2 N01 - classifies proposed states at exact backing and one lovelace above as solvent</a><br>
          <a href="#ds-state-solvency-f01">3.4.3 F01 - classifies a proposed state one lovelace below its independently calculated obligations as insolvent</a><br>
          <a href="#ds-state-solvency-n02">3.4.4 N02 - observes Store backing in the completed batch result with local and delegated contributions</a><br>
          <a href="#ds-state-solvency-n03">3.4.5 N03 - Preserve solvency across epochs</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-conservation">3.5 Conservation</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-conservation-n01">3.5.1 N01 - still counts Store ADA in total monetary conservation</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-initialization">3.6 Initialization</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-initialization-n01">3.6.1 N01 - preserves existing output references, addresses, values, datums and reference scripts and keeps those outputs implicit</a><br>
          <a href="#ds-state-initialization-n02">3.6.2 N02 - initializes Store balance and UTxO capacity deposit obligations to zero</a><br>
          <a href="#ds-state-initialization-n03">3.6.3 N03 - does not transfer funds from another ledger pot during initialization</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-recovery">3.7 Recovery</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-recovery-n01">3.7.1 N01 - preserves the complete ledger state through serialization and restoration, including outputs, allocated records and Store surplus</a><br>
          <a href="#ds-state-recovery-n02">3.7.2 N02 - restores the complete prior ledger state on rollback after ordinary success or accepted phase-2 failure</a><br>
        </dd>
      </dl>
    </details>
  </dd>
</dl>

<dl>
  <dt><strong><a href="#derived-distributions">4. Derived distributions</a></strong></dt>
  <dd>
    <details>
      <summary><a href="#ds-stake">4.1 Stake</a></summary>
      <dl>
        <dd>
          <a href="#ds-stake-n01">4.1.1 N01 - counts the full ADA in implicit outputs under the existing staking rules</a><br>
          <a href="#ds-stake-n02">4.1.2 N02 - counts only application ADA in store-backed outputs under the existing staking rules</a><br>
          <a href="#ds-stake-n03">4.1.3 N03 - does not add the global Store balance to stake totals</a><br>
          <a href="#ds-stake-n04">4.1.4 N04 - Derive stake from applied allocations</a><br>
          <a href="#ds-stake-n05">4.1.5 N05 - Derive stake from applied releases</a><br>
          <a href="#ds-stake-n06">4.1.6 N06 - Ignore unapplied collateral</a><br>
          <a href="#ds-stake-n07">4.1.7 N07 - Derive stake from collateral on phase-2 failure</a><br>
          <a href="#ds-stake-n08">4.1.8 N08 - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-voting">4.2 Voting</a></summary>
      <dl>
        <dd>
          <a href="#ds-voting-n01">4.2.1 N01 - preserves the expected voting distribution from eligible funds while excluding allocated UTxO capacity deposits and Store balance</a><br>
        </dd>
      </dl>
    </details>
  </dd>
</dl>

<dl>
  <dt><strong><a href="#spec-appendices">Appendices</a></strong></dt>
  <dd>
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
  </dd>
</dl>

<a id="domain-model" name="domain-model"></a>

## 1. Domain model

> **Establish the vocabulary and determine the deposit required by each new output.**

<a id="section-1" name="section-1"></a>

### 1.1 Outputs

> **Distinguish the value carried by an output from its storage deposit.**

A **UTxO capacity deposit** is the ADA required for an output's storage capacity.
The two output variants carry that obligation differently:

| Output | Spendable value | UTxO capacity deposit |
| --- | --- | --- |
| Implicit-deposit | Full output value | The existing minimum ADA remains inside that value. |
| Store-backed | Application assets: ADA and native assets | Recorded alongside the live UTxO entry and held externally in the DepositStore. |

For a store-backed output, distinguish its **required deposit**, calculated when it is
created, from its **allocated deposit**, the exact recorded amount associated with the
live output. [Deposit calculation](#ds-pricing) defines the required amount;
[Allocations](#ds-state-allocations) defines how the ledger records and releases it.

Outputs are indexed occurrences. Equal output values at different indices represent
separate outputs and have separate allocated deposits when store-backed. The external
deposit metadata is outside the serialized output.

<a id="section-1-1" name="section-1-1"></a>

### 1.2 DepositStore

> **Separate the Store's actual ADA from the deposits allocated to live outputs.**
>
> $\text{Store balance}=\text{funds}$ · $\text{Allocated deposits}=\text{obligations}$.

| Quantity | Meaning |
| --- | --- |
| `storeBalance` | Actual ADA held in the DepositStore. |
| `allocatedUTxODeposit(output)` | Exact deposit recorded for an existing store-backed output. |
| `totalUTxODeposits(utxo)` | Sum of the deposits allocated to all live store-backed outputs. |

$$
\text{totalUTxODeposits(utxo)}
= \sum_{\text{output}\in\text{live store-backed outputs}}
\text{allocatedUTxODeposit(output)}
$$

The total is an obligation, not a second pot of coins. Implicit outputs contribute zero
to it while retaining their existing minimum-ADA requirement.

**Allocate** assigns a deposit to a newly created store-backed output.
**Release** frees a consumed output's recorded deposit. A release can offset a new
allocation in the same transaction without ADA leaving the Store.

[Ledger effects](#ds-state) specifies how these quantities change and the invariants
they must preserve, including [Solvency](#ds-state-solvency).

<a id="section-1-4" name="section-1-4"></a>

### 1.3 Transaction bodies

> **Identify each body's own operations and the complete transaction's total.**
>
> $\text{Transaction}=\text{TopTx body}+\text{its SubTx bodies}$.

| Scope | Inputs and outputs | Declaration describes |
| --- | --- | --- |
| TopTx body | Its own regular inputs and outputs, excluding those of its SubTxs | The net deposit change of the complete transaction. |
| SubTx body | That SubTx's own regular inputs and outputs | Its net deposit contribution and whether accounting is local or delegated to TopTx. |
| Complete transaction | TopTx and every SubTx body, each counted once | The sum of all body contributions. |

Spent outputs are obtained by resolving the body's spending inputs against the
applicable UTxO. Reference inputs do not consume outputs or release deposits.
Collateral inputs and collateral return belong to the separate [Collateral](#ds-collateral)
calculation. An input may also be an ordinary spending input; it is counted once in
that hypothetical ordinary calculation and once in the alternative collateral
calculation. [Execution](#ds-state-execution) applies only the selected outcome.

For each body:

$$
\begin{aligned}
\text{releasedUTxODeposits(body)}
&= \sum_{\text{input}\in\text{consumed store-backed inputs(body)}}
\text{recordedDeposit(input)} \\
\text{allocatedUTxODeposits(body)}
&= \sum_{\text{output}\in\text{new store-backed outputs(body)}}
\text{requiredDeposit(output)} \\
\text{requiredNetUTxODepositChange(body)}
&= \text{allocatedUTxODeposits(body)} - \text{releasedUTxODeposits(body)} \\
\text{requiredTxTotalNetUTxODepositChange}
&= \sum_{\text{body}\in\text{TopTx and all SubTx bodies}}
\text{requiredNetUTxODepositChange(body)}
\end{aligned}
$$

The declaration supplies a separate value, `declaredTxTotalNetUTxODepositChange`.
[TopTx accounting](#ds-tx-accounting-net-change-toptx) compares that supplied total with the required
total above. For each explicit SubTx declaration, [SubTx accounting](#ds-tx-accounting-net-change-subtx)
compares `declaredSubTxNetUTxODepositChange(subTx)` with its required own change.
Never obtain the expected amounts from the declarations being checked.

| Body operations | Required own change | Correct declaration |
| --- | ---: | --- |
| TopTx releases 3 ADA | $-3$ ADA | Explicit zero, because the complete transaction nets to zero. |
| Its SubTx allocates 3 ADA | $+3$ ADA | An allocation of 3 ADA, locally accounted or explicitly delegated. |

TopTx's **accounting amount**, `topTxNetUTxODepositChange`, is the declared total
minus locally accounted SubTx contributions. It includes delegated contributions;
it is distinct from TopTx's own operations. [Attribution](#ds-tx-attribution) defines it.

Net quantities are signed: positive means net allocation, negative means net release,
and zero means no net change. **An absent declaration has no declared value**; it is
not an explicit declaration of zero. `hasDeclaration(body)` distinguishes these cases
and is true for every explicit declaration, including zero.

A **settlement output** is the output designated to contain a release's settlement
amount. [Attribution](#ds-tx-attribution) determines the accounting responsibility;
[Settlement](#ds-tx-settlement) determines the destination and required amount.
The [body-field reference](#transaction-body-fields) maps these concepts to the API.

<a id="ds-pricing" name="ds-pricing"></a>

### 1.4 Deposit calculation

> **Scope:** These rules and examples remain documented; pricing tests are deferred.

> **Determine the deposit required by a new store-backed output.**
>
> Accepted serialized size $\longrightarrow$ required deposit in ADA.

**Decision:** Agreed for a fixed pricing policy.

Each newly created store-backed output requires the existing byte-based minimum-UTxO amount, held externally as its allocated UTxO capacity deposit:

$$
\mathrm{requiredUTxODeposit}(\mathrm{output})=\mathrm{coinsPerUTxOByte}\bigl(160+\mathrm{acceptedSize}(\mathrm{output})\bigr).
$$

`acceptedSize` is the size of the accepted serialized output under the existing CBOR-sized-output convention. It includes its address, application assets, datum, reference script and their encoding overhead. The fixed 160-byte overhead remains. The Store balance, external allocated amount and transaction body's Store declaration are outside the output and add no bytes to its priced size.

For finalized output contents and fixed parameters, the amount is determined. Moving that amount into the external Store does not add a deposit field to the output or require a size fixed point for that field. This does not remove iteration from transaction balancing: changing application ADA, assets, address, datum or script changes the output and requires pricing its resulting size again.

The same formula applies to ordinary store-backed outputs and a store-backed collateral return. A body's allocated amount is the sum for its own new store-backed outputs. Implicit-deposit outputs retain their existing minimum-coin validation and incur no DepositStore obligation.

Calculate the allocation from the accepted sized output before that information is discarded. Later release uses the recorded amount under `DS-STATE-ALLOCATIONS`; reserializing a decoded CBOR output need not reproduce its accepted size, even at a constant price. Parameter changes and the additional historical pricing basis are deferred under `DS-PRICING-HISTORY`.

<a id="ds-pricing-p01" name="ds-pricing-p01"></a>

#### 1.4.1 P01 - Records the deposit priced from accepted bytes

$$
\text{newRecordedDeposit(output)}
=\text{coinsPerUTxOByte}\cdot(160+\text{acceptedSize(output)})
$$

Under a fixed pricing policy, independently calculate each allocation from the accepted output bytes and compare it with the ledger's newly recorded amount. Cover ordinary TopTx and SubTx outputs and collateral returns created on accepted phase-2 failure. Require accepted executions with newly created store-backed outputs in each applicable category, rather than satisfying the property with implicit-only outputs or an unapplied collateral return. Include accepted encodings whose size differs from reserialization. The equation checks the price actually assigned, not a pricing helper against itself.

<a id="ds-pricing-n01" name="ds-pricing-n01"></a>

#### 1.4.2 N01 - allocates each UTxO capacity deposit as coinsPerUTxOByte * (160 + accepted serialized output size)

Given new store-backed outputs of independently known accepted sizes, expect each recorded allocation to equal the byte price multiplied by its size plus 160. Include equal-valued outputs at different indices: each occurrence incurs its own full storage requirement, even when its amount equals another output's amount.

<a id="ds-pricing-n02" name="ds-pricing-n02"></a>

#### 1.4.3 N02 - uses the same UTxO capacity deposit formula for a store-backed collateral return

Apply an accepted phase-2 failure that creates a store-backed collateral return and compare its recorded allocation with the same accepted-size formula used for an ordinary output. A return supplied on ordinary success is not created and provides no new allocation to observe. Outcome selection changes whether it is created, not the price of its storage.

<a id="ds-pricing-n03" name="ds-pricing-n03"></a>

#### 1.4.4 N03 - includes address, application assets, datum and reference script in the priced size

Vary address, application assets, datum and reference-script contents independently, including absent and present optional components. Measure their accepted bytes and encoding overhead independently and compare the assigned allocation. Optional contents can change the amount even when application ADA is unchanged; reserializing decoded contents is not the accepted-size oracle.

<a id="ds-pricing-n04" name="ds-pricing-n04"></a>

#### 1.4.5 N04 - excludes the external UTxO capacity deposit amount and Store declaration from the priced output

At the pricing boundary, hold finalized accepted output bytes fixed while varying surrounding external deposit accounting and body declarations. Those amounts must add no bytes to the priced output. This observation concerns the size used for pricing, not ledger acceptance of an inexact declaration; exact declaration checks remain a separate prerequisite.

<a id="ds-pricing-n05" name="ds-pricing-n05"></a>

#### 1.4.6 N05 - handles CBOR size boundaries when an application coin amount changes

Use application coin pairs 23/24, 255/256, 65535/65536 and 4294967295/4294967296 lovelace while holding other output contents fixed. Price the resulting accepted output bytes separately and compare the assigned deposits. A coin change can change storage size, so the previous price cannot simply be reused.

<a id="ds-pricing-n06" name="ds-pricing-n06"></a>

#### 1.4.7 N06 - assigns no DepositStore obligation to implicit outputs

Given implicit-deposit outputs alone and mixed with store-backed outputs, assign no external Store obligation or allocation record to the implicit occurrences. Their full coins remain in their value and existing minimum-coin validation still applies; removing the Store obligation is not an exemption from that validation.

<a id="transaction-rules" name="transaction-rules"></a>

## 2. Transaction rules

> **Validate ordinary operations and collateral terms.**
>
> Tx and Collateral define the two execution paths; Ledger effects determines which effects apply.

<a id="section-1-2" name="section-1-2"></a>
<a id="ds-tx" name="ds-tx"></a>

### 2.1 Tx

> **Define the requirements for ordinary Store operations.**
>
> Each responsibility answers a separate question; all applicable checks must hold.

| Responsibility | Question answered |
| --- | --- |
| [Declarations](#ds-tx-declarations) | Which forms are valid, and which bodies must declare? |
| [Accounting](#ds-tx-accounting) | Is the deposit change exact and the transaction funded? |
| [Attribution](#ds-tx-attribution) | Which body accounts for the contribution? |
| [Authorization](#ds-tx-authorization) | Who may release the deposit? |
| [Settlement](#ds-tx-settlement) | Which output must contain the settlement amount? |
| [Application assets](#ds-tx-application-assets) | What value may the output contain? |

These rules validate the submitted ordinary transaction under a fixed pricing policy.
Declaration, amount, output and settlement checks also apply when phase 2 fails: they
examine the hypothetical ordinary transition without applying it. Ordinary financial
conservation is required only when phase 2 is valid. Existing input resolution,
witness requirements and other ledger restrictions still apply.

| Check | Ordinary success | Accepted phase-2 failure |
| --- | --- | --- |
| Declaration presence, exact amounts and settlement terms | Required | Required |
| Whole-transaction financial conservation | Required | Not checked |
| Collateral funding and supplied total | Required when any body has redeemers | Required when any body has redeemers |
| Ordinary Store effects | Applied | Unapplied |
| Collateral Store effects | Unapplied | Applied |

An invalid declaration therefore rejects the transaction before either effect set
can be accepted. Phase-2 script failure itself is handled by the existing outcome
rules; it is not a waiver of these declaration checks. [Execution](#ds-state-execution)
owns state application and rejection atomicity.

<a id="ds-tx-declarations" name="ds-tx-declarations"></a>

#### 2.1.1 Declarations

> **Valid form → required field.**

| Responsibility | Question | Evidence needed |
| --- | --- | --- |
| [Grammar](#ds-tx-declarations-grammar) | Which declaration forms are valid? | The encoded declaration. |
| [Requirements](#ds-tx-declarations-requirements) | Which bodies must declare? | The body's Store operations and the SubTx declarations; resolved inputs for releases. |

**Absence is a valid representation.** A body that allocates or releases a deposit
must nevertheless declare. Grammar accepts the form; Requirements checks whether
it is allowed in that transaction. [Net change](#ds-tx-accounting-net-change) then checks
the declared amount.

<a id="ds-tx-grammar" name="ds-tx-grammar"></a>
<a id="ds-tx-declarations-grammar" name="ds-tx-declarations-grammar"></a>

##### 2.1.1.1 Grammar

> **Preserve valid declaration forms; reject malformed representations.**

**Decision:** Agreed.

Grammar reads the declaration itself. It needs no resolved inputs, outputs or Store
state. Its result is **decoded or rejected**; successful decoding alone does not
establish that a transaction may be submitted successfully.

| Responsibility | Rule |
| --- | --- |
| **Amounts** | $1\le\text{amount}\le 2^{64}-1$ lovelace for every amount-bearing operation. |
| **Absence** | $\text{Absent}\ne\text{ExplicitZero}$. Encoding must preserve the distinction. |
| **Forms** | Preserve the operation, amount and destination. Funding requests belong to SubTx. |
| **Structure** | Recognize the operation and require its fields. |
| **Destinations** | Recognize the destination form; a local index must satisfy $0\le\text{outputIndex}\le65535$. |

**Available forms**

| Declaration | TopTx | SubTx |
| --- | --- | --- |
| Absent | No declaration. | No declaration. |
| Explicit zero | Declare the transaction's total net change as zero. | Declare the body's own net contribution as zero. |
| Allocate | Positive amount. | Positive amount, accounted locally. |
| Request funding | Unavailable. | Positive amount, requested explicitly from TopTx. |
| Release | Positive amount with no own settlement, or an own output index. | Positive amount with delegation to TopTx, or an own output index. |

The [Requirements](#ds-tx-declarations-requirements) rules determine when a declaration is required.
[Net change](#ds-tx-accounting-net-change) checks its amount.
[Settlement](#ds-tx-settlement) checks participation, output existence and coverage.

**Encoding contract**

$$
\text{decode}(\text{encode}(\text{declaration}))=\text{declaration}
$$

Unless a case names one codec, its checks cover **CBOR and JSON**.

| Representation | Structural checks |
| --- | --- |
| CBOR | Known constructor tag and exact field count, at every supported Dijkstra version. |
| JSON | Known operation kind and required fields. Additional object keys are allowed. |

Whole-body cases also preserve the surrounding body fields. Wire tags and body
field 28 are detailed in the [encoding reference](#declaration-encoding).

<a id="ds-tx-grammar-n02" name="ds-tx-grammar-n02"></a>
<a id="ds-tx-declarations-grammar-n02" name="ds-tx-declarations-grammar-n02"></a>

The reusable `StrictlyPositiveCoin` type owns the positive-amount invariant;
[`StrictlyPositiveCoinSpec`](../libs/cardano-ledger-core/test/Test/Cardano/Ledger/StrictlyPositiveCoinSpec.hs)
tests its constructor and scalar codecs. Grammar checks the type's use **inside
declarations**, including rejection of raw external values that bypass construction.

TopTx and SubTx follow the same reading order:
**Amounts → Absence → Forms → Structure → Destinations**.
Case numbers restart within each category; each tag links to its executable check.

<a id="ds-tx-grammar-toptx" name="ds-tx-grammar-toptx"></a>
<a id="ds-tx-declarations-grammar-toptx" name="ds-tx-declarations-grammar-toptx"></a>

###### 2.1.1.1.1 TopTx

TopTx declares the transaction total. Its grammar permits explicit zero, allocation
or release; a funding request is a SubTx operation.

<a id="ds-tx-grammar-amounts" name="ds-tx-grammar-amounts"></a>
<a id="ds-tx-declarations-grammar-amounts" name="ds-tx-declarations-grammar-amounts"></a>

<a id="ds-tx-grammar-toptx-amounts" name="ds-tx-grammar-toptx-amounts"></a>
<a id="ds-tx-declarations-grammar-toptx-amounts" name="ds-tx-declarations-grammar-toptx-amounts"></a>

**2.1.1.1.1.1 Amounts**

> **Allocation and release carry a strictly positive amount.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-p01" name="ds-tx-grammar-p01"></a><a id="ds-tx-declarations-grammar-p01" name="ds-tx-declarations-grammar-p01"></a>**1.&nbsp;[P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L36)** | **Positive amounts survive encoding.** A generated `StrictlyPositiveCoin` in every amount-bearing form. | Preserve the operation, amount and settlement through both codecs. |
| <a id="ds-tx-grammar-f01" name="ds-tx-grammar-f01"></a><a id="ds-tx-declarations-grammar-f01" name="ds-tx-declarations-grammar-f01"></a>**2.&nbsp;[F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L40)** | **Zero operation amount.** Raw $\text{amount}=0$. | Reject decoding. Explicit zero has its own form. |
| <a id="ds-tx-grammar-f12" name="ds-tx-grammar-f12"></a><a id="ds-tx-declarations-grammar-f12" name="ds-tx-declarations-grammar-f12"></a>**3.&nbsp;[F12](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L43)** | **Negative operation amount.** Raw $\text{amount}=-1$. | Reject decoding: below the lower bound. |
| <a id="ds-tx-grammar-f13" name="ds-tx-grammar-f13"></a><a id="ds-tx-declarations-grammar-f13" name="ds-tx-declarations-grammar-f13"></a>**4.&nbsp;[F13](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L46)** | **Overflowing operation amount.** Raw $\text{amount}=2^{64}$. | Reject decoding without truncation or wrapping. |

Every generated set includes allocation, release without TopTx settlement, and
local release at indices $0$, $65535$ and one generated interior index. Thus each
amount is checked in **five declarations per codec**, with valid destinations.
The three rejection cases fix the amount at the stated boundary value while
varying the surrounding declaration. Explicit zero uses a separate form, not an
allocation or release of zero.

<a id="ds-tx-grammar-absence" name="ds-tx-grammar-absence"></a>
<a id="ds-tx-declarations-grammar-absence" name="ds-tx-declarations-grammar-absence"></a>

<a id="ds-tx-grammar-toptx-absence" name="ds-tx-grammar-toptx-absence"></a>
<a id="ds-tx-declarations-grammar-toptx-absence" name="ds-tx-declarations-grammar-toptx-absence"></a>

**2.1.1.1.1.2 Absence**

> **Declaring zero is different from declaring nothing.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-n03" name="ds-tx-grammar-n03"></a><a id="ds-tx-declarations-grammar-n03" name="ds-tx-declarations-grammar-n03"></a>**1.&nbsp;[N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L51)** | **Absence remains distinct from zero.** Two otherwise identical complete bodies, differing only in their declaration. | Distinct encodings; decoding preserves each complete body. |

Both bodies share the same generated spending inputs, reference inputs and
auxiliary-data hash. Only the declaration differs:

$$
\begin{aligned}
\text{encode(absentBody)} &\ne \text{encode(explicitZeroBody)} \\
\text{decode(encode(absentBody))} &= \text{absentBody} \\
\text{decode(encode(explicitZeroBody))} &= \text{explicitZeroBody}
\end{aligned}
$$

This preserves the distinction needed by Requirements without deciding whether either
body has declared enough for its Store operations.

<a id="ds-tx-grammar-forms" name="ds-tx-grammar-forms"></a>
<a id="ds-tx-declarations-grammar-forms" name="ds-tx-declarations-grammar-forms"></a>

<a id="ds-tx-grammar-toptx-forms" name="ds-tx-grammar-toptx-forms"></a>
<a id="ds-tx-declarations-grammar-toptx-forms" name="ds-tx-declarations-grammar-toptx-forms"></a>

**2.1.1.1.1.3 Forms**

> **Preserve every TopTx form; keep funding requests specific to SubTx.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-n05" name="ds-tx-grammar-n05"></a><a id="ds-tx-declarations-grammar-n05" name="ds-tx-declarations-grammar-n05"></a>**1.&nbsp;[N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L58)** | **Every TopTx declaration form.** Explicit zero and all amount-bearing forms at both amount bounds. | Preserve each form, amount and settlement. |
| <a id="ds-tx-grammar-f06" name="ds-tx-grammar-f06"></a><a id="ds-tx-declarations-grammar-f06" name="ds-tx-declarations-grammar-f06"></a>**2.&nbsp;[F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L62)** | **Funding request in TopTx.** A valid SubTx funding request is passed to the TopTx decoder. | SubTx preserves the request in both codecs; TopTx rejects its JSON representation. |

N05 includes explicit zero and every amount-bearing variant at **both** positive
bounds, $1$ and $2^{64}-1$: eleven declarations per draw. Release variants include
`NoTopTxSettlement` and `TopTxSettlementOutput` at indices $0$, $65535$ and a
generated interior index. No output needs to exist at those indices for decoding.

**Funding-request example**

| Input | SubTx decoder | TopTx decoder |
| --- | --- | --- |
| JSON `{"kind":"requestUTxODepositFromTopTx","amount":1}` | Decoded as a funding request. | Rejected: unavailable TopTx operation. |

F06 also round-trips the valid SubTx request through CBOR. Its cross-level rejection
assertion is specifically a **JSON** check.

<a id="ds-tx-grammar-structure" name="ds-tx-grammar-structure"></a>
<a id="ds-tx-declarations-grammar-structure" name="ds-tx-declarations-grammar-structure"></a>

<a id="ds-tx-grammar-toptx-structure" name="ds-tx-grammar-toptx-structure"></a>
<a id="ds-tx-declarations-grammar-toptx-structure" name="ds-tx-declarations-grammar-toptx-structure"></a>

**2.1.1.1.1.4 Structure**

> **A recognized operation must carry exactly its required CBOR fields, or all required JSON fields.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-f02" name="ds-tx-grammar-f02"></a><a id="ds-tx-declarations-grammar-f02" name="ds-tx-declarations-grammar-f02"></a>**1.&nbsp;[F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L68)** | **Malformed declarations.** Invalid containers, unknown operations, missing required fields or extra CBOR fields. | Reject each malformed input in its own format. |

**Representative invalid inputs**

| Defect | Example | Why it fails |
| --- | --- | --- |
| Wrong container or empty declaration | CBOR `0` or `[]`; JSON `null` or `{}`. | No complete operation is represented. |
| Unknown operation | JSON `{"kind":"unknown"}`. | The kind does not identify a TopTx operation. |
| Missing amount | CBOR `[0]`; JSON `{"kind":"allocate"}`. | Allocation requires an amount. Releases also require one. |
| Missing settlement | CBOR `[1,1]`. | Release carries both an amount and a settlement form. |
| Extra CBOR fields | `[2,0]` or `[0,1,0]`. | Explicit zero has no payload; allocation has only an amount. |

Every draw covers seven CBOR and seven JSON defects. Amounts and any supplied
valid fields remain well formed, isolating structure as the reason for rejection.
Extra JSON keys are permitted and are not among these defects.

<a id="ds-tx-grammar-destinations" name="ds-tx-grammar-destinations"></a>
<a id="ds-tx-declarations-grammar-destinations" name="ds-tx-declarations-grammar-destinations"></a>

<a id="ds-tx-grammar-toptx-destinations" name="ds-tx-grammar-toptx-destinations"></a>
<a id="ds-tx-declarations-grammar-toptx-destinations" name="ds-tx-declarations-grammar-toptx-destinations"></a>

**2.1.1.1.1.5 Destinations**

> **A release names no TopTx settlement, or a representable own output index.**

| Valid form | Payload |
| --- | --- |
| `NoTopTxSettlement` | No index. |
| `TopTxSettlementOutput outputIndex` | $0\le\text{outputIndex}\le65535$. |

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-f04" name="ds-tx-grammar-f04"></a><a id="ds-tx-declarations-grammar-f04" name="ds-tx-declarations-grammar-f04"></a>**1.&nbsp;[F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L73)** | **Malformed release settlements.** Wrong container, unknown form, missing local index or extra CBOR fields. | Reject decoding with otherwise valid indices. |
| <a id="ds-tx-grammar-f14" name="ds-tx-grammar-f14"></a><a id="ds-tx-declarations-grammar-f14" name="ds-tx-declarations-grammar-f14"></a>**2.&nbsp;[F14](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L76)** | **Negative output index.** Generated $\text{outputIndex}<0$, favouring $-1$. | Reject the local settlement in both codecs. |
| <a id="ds-tx-grammar-f15" name="ds-tx-grammar-f15"></a><a id="ds-tx-declarations-grammar-f15" name="ds-tx-declarations-grammar-f15"></a>**3.&nbsp;[F15](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L80)** | **Overflowing output index.** Generated $\text{outputIndex}>65535$, favouring $65536$. | Reject the settlement without truncation or wrapping. |

F04 covers six CBOR and five JSON structural defects per draw: invalid containers,
unknown forms, missing local indices and extra CBOR fields. Examples include CBOR
`[0,1]` (an index on the no-settlement form) and `[1]` (a local form without its
index). Any supplied local index remains within range.

F14 and F15 generate values throughout their respective invalid ranges, favouring
$-1$ and $65536$. Shrinking keeps a counterexample in the same invalid range.
[N05](#ds-tx-declarations-grammar-n05) supplies the valid $0$ and $65535$ controls.
[Settlement](#ds-tx-settlement-destination) separately checks that the index names
an existing output in TopTx.

<a id="ds-tx-grammar-subtx" name="ds-tx-grammar-subtx"></a>
<a id="ds-tx-declarations-grammar-subtx" name="ds-tx-declarations-grammar-subtx"></a>

###### 2.1.1.1.2 SubTx

A SubTx can declare zero, allocate locally, request funding from TopTx, or release
to its own output or TopTx. Encoding preserves which choice it made.

<a id="ds-tx-grammar-subtx-amounts" name="ds-tx-grammar-subtx-amounts"></a>
<a id="ds-tx-declarations-grammar-subtx-amounts" name="ds-tx-declarations-grammar-subtx-amounts"></a>

**2.1.1.1.2.1 Amounts**

> **Allocation, funding requests and releases carry a strictly positive amount.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-p02" name="ds-tx-grammar-p02"></a><a id="ds-tx-declarations-grammar-p02" name="ds-tx-declarations-grammar-p02"></a>**1.&nbsp;[P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L33)** | **Positive amounts survive encoding.** A generated `StrictlyPositiveCoin` in every amount-bearing form. | Preserve the operation, amount and target through both codecs. |
| <a id="ds-tx-grammar-f07" name="ds-tx-grammar-f07"></a><a id="ds-tx-declarations-grammar-f07" name="ds-tx-declarations-grammar-f07"></a>**2.&nbsp;[F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L37)** | **Zero operation amount.** Raw $\text{amount}=0$. | Reject decoding. An amount-bearing operation cannot stand in for explicit zero. |
| <a id="ds-tx-grammar-f08" name="ds-tx-grammar-f08"></a><a id="ds-tx-declarations-grammar-f08" name="ds-tx-declarations-grammar-f08"></a>**3.&nbsp;[F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L40)** | **Negative operation amount.** Raw $\text{amount}=-1$. | Reject decoding: the amount is below the lower bound. |
| <a id="ds-tx-grammar-f09" name="ds-tx-grammar-f09"></a><a id="ds-tx-declarations-grammar-f09" name="ds-tx-declarations-grammar-f09"></a>**4.&nbsp;[F09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L43)** | **Overflowing operation amount.** Raw $\text{amount}=2^{64}$. | Reject decoding without truncation or wrapping. |

F07–F09 generate declaration payloads around the **fixed raw amount shown**;
they do not generate arbitrary negative or overflowing amounts. Each draw covers
six declarations per codec: allocation, request, delegated release, and local
release at $0$, $65535$ and a generated index in $1\ldots65534$.

<a id="ds-tx-grammar-subtx-absence" name="ds-tx-grammar-subtx-absence"></a>
<a id="ds-tx-declarations-grammar-subtx-absence" name="ds-tx-declarations-grammar-subtx-absence"></a>

**2.1.1.1.2.2 Absence**

> **Declaring zero is different from declaring nothing.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-n04" name="ds-tx-grammar-n04"></a><a id="ds-tx-declarations-grammar-n04" name="ds-tx-declarations-grammar-n04"></a>**1.&nbsp;[N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L48)** | **Absence remains distinct from zero.** The same complete body, differing only in its declaration. | Distinct CBOR and JSON representations; decoding preserves each complete body. |

Both bodies share the same generated spending inputs, reference inputs and
auxiliary-data hash. Only the declaration differs:

$$
\begin{aligned}
\text{encode(absentBody)} &\ne \text{encode(explicitZeroBody)} \\
\text{decode(encode(absentBody))} &= \text{absentBody} \\
\text{decode(encode(explicitZeroBody))} &= \text{explicitZeroBody}
\end{aligned}
$$

This preserves the distinction needed by Requirements without deciding whether either
body has declared enough for its Store operations.

<a id="ds-tx-grammar-subtx-forms" name="ds-tx-grammar-subtx-forms"></a>
<a id="ds-tx-declarations-grammar-subtx-forms" name="ds-tx-declarations-grammar-subtx-forms"></a>

**2.1.1.1.2.3 Forms**

> **Preserve every SubTx form, including explicit funding requests.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-n06" name="ds-tx-grammar-n06"></a><a id="ds-tx-declarations-grammar-n06" name="ds-tx-declarations-grammar-n06"></a>**1.&nbsp;[N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L55)** | **Every SubTx declaration form.** Explicit zero and every amount-bearing form at both amount bounds. | Preserve each form, amount and target through both codecs. |

The amount bounds are $1$ and $2^{64}-1$. Local releases use $0$, $65535$ and a
generated interior index in $1\ldots65534$. Together with explicit zero, these
produce thirteen declarations per draw. P02 varies the amount across its valid
range; N06 always includes both bounds.

<a id="ds-tx-grammar-subtx-structure" name="ds-tx-grammar-subtx-structure"></a>
<a id="ds-tx-declarations-grammar-subtx-structure" name="ds-tx-declarations-grammar-subtx-structure"></a>

**2.1.1.1.2.4 Structure**

> **A recognized operation must carry exactly its required CBOR fields, or all required JSON fields.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-f03" name="ds-tx-grammar-f03"></a><a id="ds-tx-declarations-grammar-f03" name="ds-tx-declarations-grammar-f03"></a>**1.&nbsp;[F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L61)** | **Malformed declarations.** Invalid containers, unknown operations, missing required fields or extra CBOR fields. | Reject each malformed input in its own format. |

**Representative invalid inputs**

| Defect | Example | Why it fails |
| --- | --- | --- |
| Wrong container or empty declaration | CBOR `0` or `[]`; JSON `null` or `{}`. | No complete operation is represented. |
| Unknown operation | JSON `{"kind":"unknown"}`. | The kind does not identify a SubTx operation. |
| Missing amount | CBOR `[0]` or `[2]`. | Allocation and funding requests require an amount. Releases also require one. |
| Missing target | CBOR `[1,1]`; JSON `{"kind":"release","amount":1}`. | Release carries both an amount and a target. |
| Extra CBOR fields | `[3,0]`, `[0,1,0]` or `[2,1,0]`. | Explicit zero has no payload; allocation and funding request have only an amount. |

Every draw covers nine CBOR and eight JSON defects. Amounts and any supplied
valid fields remain well formed, isolating structure as the reason for rejection.
Extra JSON keys are permitted and are not among these defects.

<a id="ds-tx-grammar-subtx-destinations" name="ds-tx-grammar-subtx-destinations"></a>
<a id="ds-tx-declarations-grammar-subtx-destinations" name="ds-tx-declarations-grammar-subtx-destinations"></a>

**2.1.1.1.2.5 Destinations**

> **A release delegates to TopTx, or names a representable own output index.**

| Valid form | Payload |
| --- | --- |
| `DelegateToTopTx` | No local index. |
| `SubTxSettlementOutput outputIndex` | $0\le\text{outputIndex}\le65535$. |

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-f05" name="ds-tx-grammar-f05"></a><a id="ds-tx-declarations-grammar-f05" name="ds-tx-declarations-grammar-f05"></a>**1.&nbsp;[F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L66)** | **Malformed release targets.** Wrong container, unknown target, missing local index or extra CBOR fields. | Reject decoding with otherwise valid indices. |
| <a id="ds-tx-grammar-f10" name="ds-tx-grammar-f10"></a><a id="ds-tx-declarations-grammar-f10" name="ds-tx-declarations-grammar-f10"></a>**2.&nbsp;[F10](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L69)** | **Negative output index.** Generated $\text{outputIndex}<0$, favouring $-1$. | Reject a local target carrying that index in both codecs. |
| <a id="ds-tx-grammar-f11" name="ds-tx-grammar-f11"></a><a id="ds-tx-declarations-grammar-f11" name="ds-tx-declarations-grammar-f11"></a>**3.&nbsp;[F11](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L73)** | **Overflowing output index.** Generated $\text{outputIndex}>65535$, favouring $65536$. | Reject the target without truncation or wrapping. |

F05 covers six CBOR and five JSON structural defects per draw: invalid containers,
unknown forms, missing local indices and extra CBOR fields. Examples include CBOR
`[1,0]` (an index attached to delegation) and `[0]` (a local target without its
index). Any supplied local index remains within range.

F10 and F11 generate values throughout their respective invalid ranges, favouring
$-1$ and $65536$. Shrinking keeps a counterexample in the same invalid range.
[N06](#ds-tx-declarations-grammar-n06) supplies the valid $0$ and $65535$ controls.
[Settlement](#ds-tx-settlement-destination) separately checks that the index names
an existing output in this SubTx.

<a id="ds-tx-presence" name="ds-tx-presence"></a>
<a id="ds-tx-required-declarations" name="ds-tx-required-declarations"></a>
<a id="ds-tx-declarations-requirements" name="ds-tx-declarations-requirements"></a>

##### 2.1.1.2 Requirements

> **Determine which body must supply a declaration.**

| Trigger | Required field |
| --- | --- |
| A body's own ordinary Store allocation or release | That body's own declaration. Parent and child fields cannot substitute for it. |
| An explicit SubTx declaration, including zero | A TopTx declaration, even when TopTx has no own Store operations. |

$$
\begin{aligned}
\text{ownStoreOperations(body)} &\implies\text{hasDeclaration(body)} \\
\text{hasDeclaration(subTx)} &\implies\text{hasDeclaration(topTx)}
\end{aligned}
$$

**TopTx declares the complete transaction's net change; each SubTx declares its
own contribution.** These rules check that the required field exists.
[Net change](#ds-tx-accounting-net-change) checks the amount it declares.

Ordinary declaration, net change, output and settlement validation applies on both phase-2 outcomes. Required ordinary amounts describe the hypothetical ordinary transition from the original UTxO. Ordinary financial conservation is checked only when phase 2 is valid. An accepted phase-2 failure applies collateral effects only, while retaining the declaration, net change, output and settlement checks. Accepted ordinary release additionally requires its existing spending authorization. Ledger outcome and applied effects remain separate under State Execution.

<a id="ds-tx-presence-activity" name="ds-tx-presence-activity"></a>
<a id="ds-tx-presence-activity-scope" name="ds-tx-presence-activity-scope"></a>
<a id="ds-tx-presence-operations-scope" name="ds-tx-presence-operations-scope"></a>
<a id="ds-tx-presence-operations" name="ds-tx-presence-operations"></a>
<a id="ds-tx-required-declarations-operations" name="ds-tx-required-declarations-operations"></a>
<a id="ds-tx-declarations-requirements-operations" name="ds-tx-declarations-requirements-operations"></a>

###### 2.1.1.2.1 Operations

> **Require a declaration for the body’s own Store operations.**
>
> Allocation or release $\implies$ own declaration required.

**Decision:** Agreed.

A body requiring an allocation or releasing a recorded deposit must provide its
own declaration field. TopTx declares the complete batch amount; SubTx declares
its own contribution.

| Own regular operation | UTxO condition | Outside this body's operations |
| --- | --- | --- |
| **Allocation** | A newly created store-backed output needs a deposit recorded in the Store. | Collateral return and a child's outputs. |
| **Release** | A consumed store-backed output releases its recorded deposit. | Reference inputs, collateral inputs and a child's inputs. |

These are **gross operations**, before netting:

$$
\text{netDepositChange}=\text{allocatedDeposits}-\text{releasedDeposits}
$$

A body may require both operations, even when its net change is zero. The
allocation and release sections therefore overlap; they do not classify the
declaration's sign. [Zero net change](#ds-tx-declarations-requirements-operations-zero-net-change) makes
the equal, nonzero case explicit: zero net change still requires a declaration.
On an accepted phase-2 failure, these requirements describe
the hypothetical ordinary transition; only collateral effects execute.

This requirement applies separately to TopTx and each SubTx. An explicit zero is a
declaration; an absent declaration is not. The declared amount must also satisfy the
separate exact-accounting rules, including TopTx's declaration of the batch total.

Define:

- `outputs(body)`: the body's own outputs, after removing the `Sized` wrapper.
- `spentOutputs(body)`: the outputs resolved from the body's own spending inputs.
- `change(body)`: the declaration field for that body's level, listed in the
  [body-field reference](#transaction-body-fields).
- `hasDeclaration(body)`: whether that field explicitly declares an operation,
  including explicit zero.
- `requiresAllocation(body)`: at least one element of `outputs(body)` has the
  `StoreBackedTxOut` constructor.
- `releasesDeposits(body)`: at least one element of `spentOutputs(body)` has the
  `StoreBackedTxOut` constructor.

These predicates identify the output form, independently of the deposit price
or the signed net amount. Together they define the body's own Store operations:

$$
\begin{aligned}
\text{ownStoreOperations(body)}
&\iff\text{requiresAllocation(body)}\lor\text{releasesDeposits(body)} \\
\text{operationsPresenceSatisfied(body)}
&\iff\neg\text{ownStoreOperations(body)}\lor\text{hasDeclaration(body)}
\end{aligned}
$$

This boundary determines **which body must declare**. TopTx's declared amount
still includes every SubTx's contribution, and
[SubTx declarations](#ds-tx-declarations-requirements-subtx-declarations) can require its field
without any own Store operation.

The required condition is:

$$
\begin{aligned}
&\text{requiresAllocation(body)} \lor \text{releasesDeposits(body)} \\
&\qquad\implies \text{hasDeclaration(body)}
\end{aligned}
$$

Equivalently:

$$
\begin{aligned}
&\neg\text{hasDeclaration(body)} \\
&\qquad\implies
\forall\,\text{output}\in\text{outputs(body)}\cup\text{spentOutputs(body)}:\quad
\text{isImplicitDeposit(output)}
\end{aligned}
$$

Here $\text{isImplicitDeposit(output)}$ means that the output has the
`ImplicitDepositTxOut` constructor.

If either condition is true and `hasDeclaration(body)` is false, reject the body.
DS-TX-ACCOUNTING-NET-CHANGE-SUBTX additionally requires a release
contribution when store-backed outputs are spent without creating any new store-backed
outputs.

**Declaration requirement decision table**

These results concern **DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS only**. Passing this check does not establish that the
transaction satisfies funding, release, or other ledger rules.

| Own spent outputs | Own created outputs | Own operation field | Result for DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS |
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
  has made an explicit declaration and passes this presence check.
  DS-TX-ACCOUNTING-NET-CHANGE-SUBTX checks the requested amount, DS-TX-ATTRIBUTION assigns
  its accounting to TopTx, and DS-TX-ACCOUNTING-BALANCE requires the complete batch to fund it.
- A TopTx whose own spent and created outputs are all implicit-deposit outputs
  and whose field is `TopTx.NoUTxODepositDeclaration`, containing a SubTx with store-backed outputs
  and an explicit operation, passes this check for both bodies. This says nothing
  about overall validity: DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS rejects the missing TopTx declaration.
- Creating store-backed outputs still requires a declaration when the net
  funding requirement is zero. An active SubTx with a zero required own change uses `SubTx.DeclaresZeroNetUTxODeposit`. TopTx uses `TopTx.DeclaresZeroNetUTxODeposit` when the complete required batch change is zero, regardless of its own contribution.

<a id="ds-tx-presence-activity-p01" name="ds-tx-presence-activity-p01"></a>
<a id="ds-tx-presence-operations-p01" name="ds-tx-presence-operations-p01"></a>
<a id="ds-tx-required-declarations-operations-p01" name="ds-tx-required-declarations-operations-p01"></a>
<a id="ds-tx-declarations-requirements-operations-p01" name="ds-tx-declarations-requirements-operations-p01"></a>

**2.1.1.2.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/OperationsSpec.hs#L44) - Every body requiring a Store operation declares**

> **An operation requires a declaration even when its priced amount is zero.**

Generate TopTx and zero to four SubTxs. Each body's source and output forms vary
independently between implicit and store-backed. Resolve sources from the actual
funded UTxO; inspect each body's own proposed outputs.

$$
\begin{aligned}
&\text{Accepted}\implies\forall\,\text{body}: \\
&\quad\text{ownStoreOperations(body)}\implies\text{hasDeclaration(body)}
\end{aligned}
$$

The generated context deliberately sets the deposit price to zero. Output forms
still determine whether an allocation or release is proposed:

$$
\begin{aligned}
\text{depositPrice}&=0 \\
\text{allocatedDeposits(body)}&=\text{releasedDeposits(body)}=0 \\
\text{storeBackedOutput}&\ne\text{implicitOutput}
\end{aligned}
$$

| Submission | Expected result |
| --- | --- |
| Every body explicitly declares zero. | Accept the exact, funded control. |
| Remove an active TopTx's declaration; keep child declarations unchanged. | Reject with `MissingUTxODepositDeclaration`. |
| Remove one active SubTx's declaration; keep TopTx and sibling declarations unchanged. | Reject with `SubMissingUTxODepositDeclaration`. |

Try the omission separately for **every active body**, then accept the original
control. Repeat each generated scenario on the ordinary-success path and with a
real failing script marked phase-2 invalid; ordinary declaration requirements
apply on both paths. The independent operation
check uses output constructors, not a positive deposit amount or the production
validator. The positive-priced scenarios below complement this zero-price case.

<a id="ds-tx-presence-activity-creation" name="ds-tx-presence-activity-creation"></a>
<a id="ds-tx-presence-operations-allocation" name="ds-tx-presence-operations-allocation"></a>
<a id="ds-tx-required-declarations-operations-allocation" name="ds-tx-required-declarations-operations-allocation"></a>
<a id="ds-tx-declarations-requirements-operations-allocation" name="ds-tx-declarations-requirements-operations-allocation"></a>

**2.1.1.2.1.2 Allocation**

> **A body requiring a Store allocation must declare its own deposit change.**

$$
\forall\,\text{body}:\quad
\text{createdStoreBackedOutputs(body)}\ne\varnothing
\implies\text{hasDeclaration(body)}
$$

**Decision:** Agreed.

Here $\text{createdStoreBackedOutputs(body)}$ means the store-backed outputs in
that body's **own regular output sequence**. It excludes collateral return and,
for TopTx, its children's outputs. Inspect every own-output position, including
mixed sequences. Any explicit declaration satisfies allocation presence; amounts,
funding and settlement remain separate requirements.

| Cases | What they establish |
| --- | --- |
| N01, N02, F01 | Isolated allocation presence for TopTx and SubTx. Passing does not prove exact amounts or funding. |
| N03, N04 | Ledger acceptance with only implicit outputs and no declarations. |
| N05, F02 | A funded standalone allocation is accepted; removing only its declaration is rejected. |
| F03, F04, F05 | The required body-specific missing-declaration failure in the SubTx and phase-2 rejection fixtures. These are not paired with otherwise valid allocation controls. |
| F06 | A Conway output upgraded to an implicit Dijkstra output cannot waive the declaration required by new Store allocations; an exact control is accepted. |
| N06, N07, N08, F07 | Isolated TopTx allocation presence: only its own regular outputs trigger the requirement, and a child's declaration cannot supply its field. |
| F08 | A specific SubTx missing-declaration failure, even when TopTx declares zero. |
| N09 | Parent and child allocate with independently priced amounts; TopTx declares their combined allocation and SubTx its own. |

**N05 and F02 share this standalone context:**

$$
\begin{aligned}
&\text{subTxs}=\varnothing \\
&\land\ \text{spentStoreBackedOutputs(topTx)}=\varnothing \\
&\land\ \text{createdStoreBackedOutputs(topTx)}\ne\varnothing
\end{aligned}
$$

Only implicit inputs are spent, so no existing deposit is released. **Allocation
alone** requires the declaration. A phase-2-invalid marker does not bypass
allocation presence; F04 and F05 check that obligation separately.

<a id="ds-tx-presence-activity-creation-n01" name="ds-tx-presence-activity-creation-n01"></a>
<a id="ds-tx-presence-operations-allocation-n01" name="ds-tx-presence-operations-allocation-n01"></a>
<a id="ds-tx-required-declarations-operations-allocation-n01" name="ds-tx-required-declarations-operations-allocation-n01"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n01" name="ds-tx-declarations-requirements-operations-allocation-n01"></a>

**2.1.1.2.1.2.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L59) - Every explicit declaration satisfies allocation presence**

For both TopTx and SubTx, every explicit declaration counts as present: zero,
allocation, release and SubTx delegation. The isolated allocation-presence validator succeeds
for each form and each generated arrangement of store-backed own outputs.

$$
\begin{aligned}
&\text{createdStoreBackedOutputs(body)}\ne\varnothing \\
&\land\ \text{hasDeclaration(body)} \\
&\implies\text{AllocationPresenceSatisfied}
\end{aligned}
$$

This is **not ledger acceptance**. An explicit zero, for example, satisfies
presence even when the required allocation is positive; exactness must check it.

<a id="ds-tx-presence-activity-creation-n02" name="ds-tx-presence-activity-creation-n02"></a>
<a id="ds-tx-presence-operations-allocation-n02" name="ds-tx-presence-operations-allocation-n02"></a>
<a id="ds-tx-required-declarations-operations-allocation-n02" name="ds-tx-required-declarations-operations-allocation-n02"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n02" name="ds-tx-declarations-requirements-operations-allocation-n02"></a>

**2.1.1.2.1.2.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L76) - Absence satisfies allocation presence for empty or implicit-only own outputs**

An empty or implicit-only own output sequence introduces no allocation-presence
requirement. Both isolated validators succeed with an absent declaration.

$$
\begin{aligned}
&\text{createdStoreBackedOutputs(body)}=\varnothing \\
&\land\ \neg\text{hasDeclaration(body)} \\
&\implies\text{AllocationPresenceSatisfied}
\end{aligned}
$$

This says nothing about release or declaration dependency, which may still
require a declaration before the ledger can accept the transaction.

<a id="ds-tx-presence-activity-creation-f01" name="ds-tx-presence-activity-creation-f01"></a>
<a id="ds-tx-presence-operations-allocation-f01" name="ds-tx-presence-operations-allocation-f01"></a>
<a id="ds-tx-required-declarations-operations-allocation-f01" name="ds-tx-required-declarations-operations-allocation-f01"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f01" name="ds-tx-declarations-requirements-operations-allocation-f01"></a>

**2.1.1.2.1.2.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L85) - Missing declaration fails allocation presence at every own-output position**

One store-backed own output is enough to require a declaration, wherever it
appears among implicit outputs. The generated cases place it at every position
in each generated sequence and check both TopTx and SubTx.

$$
\begin{aligned}
&\text{createdStoreBackedOutputs(body)}\ne\varnothing \\
&\land\ \neg\text{hasDeclaration(body)} \\
&\implies\text{AllocationPresenceFails}
\end{aligned}
$$

The isolated validator must return `MissingBodyUTxODepositDeclaration`. No
transaction is submitted in this check.

<a id="ds-tx-presence-activity-creation-n03" name="ds-tx-presence-activity-creation-n03"></a>
<a id="ds-tx-presence-operations-allocation-n03" name="ds-tx-presence-operations-allocation-n03"></a>
<a id="ds-tx-required-declarations-operations-allocation-n03" name="ds-tx-required-declarations-operations-allocation-n03"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n03" name="ds-tx-declarations-requirements-operations-allocation-n03"></a>

**2.1.1.2.1.2.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L95) - accepts a TopTx creating only implicit outputs without a declaration**

A TopTx creating only implicit outputs is accepted by the ledger without a Store declaration when its ordinary inputs, fees, and witnesses are valid. Its outputs impose no allocation-presence requirement.

<a id="ds-tx-presence-activity-creation-n04" name="ds-tx-presence-activity-creation-n04"></a>
<a id="ds-tx-presence-operations-allocation-n04" name="ds-tx-presence-operations-allocation-n04"></a>
<a id="ds-tx-required-declarations-operations-allocation-n04" name="ds-tx-required-declarations-operations-allocation-n04"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n04" name="ds-tx-declarations-requirements-operations-allocation-n04"></a>

**2.1.1.2.1.2.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L99) - accepts a SubTx creating only implicit outputs without either body's declaration**

A SubTx creating only implicit outputs is accepted within a ledger transaction when neither level declares a Store operation. Ordinary transaction preparation supplies valid funding and witnesses; no Store allocation is created.

<a id="ds-tx-presence-activity-creation-n05" name="ds-tx-presence-activity-creation-n05"></a>
<a id="ds-tx-presence-operations-allocation-n05" name="ds-tx-presence-operations-allocation-n05"></a>
<a id="ds-tx-required-declarations-operations-allocation-n05" name="ds-tx-required-declarations-operations-allocation-n05"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n05" name="ds-tx-declarations-requirements-operations-allocation-n05"></a>

**2.1.1.2.1.2.6 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L114) - Standalone TopTx, exact allocation declaration**

**No existing deposit is released.** Generate one to five outputs with varying
application ADA, including at least one store-backed output. The sequence may be
entirely store-backed or mixed with implicit outputs. Every funding input is
implicit and has no Store allocation.

TopTx declares the full required allocation directly. The builder funds that
allocation, application outputs and fees, then supplies the witnesses. Under the
shared standalone context, with all other ledger rules satisfied:

$$
\text{declaredNetDeposit(topTx)}=\text{allocatedDeposits(topTx)}
\implies\text{Accepted}
$$

The allocation is computed from the created outputs, independently of the
declaration:

$$
\text{allocatedDeposits(topTx)}
=\sum_{\text{output}\in\text{createdStoreBackedOutputs(topTx)}}
\text{requiredDeposit(protocolParameters, output)}
$$

It uses serialized sizes and a positive deposit price. Implicit outputs
contribute zero; no SubTx declaration is supplied.

<a id="ds-tx-presence-activity-creation-f02" name="ds-tx-presence-activity-creation-f02"></a>
<a id="ds-tx-presence-operations-allocation-f02" name="ds-tx-presence-operations-allocation-f02"></a>
<a id="ds-tx-required-declarations-operations-allocation-f02" name="ds-tx-required-declarations-operations-allocation-f02"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f02" name="ds-tx-declarations-requirements-operations-allocation-f02"></a>

**2.1.1.2.1.2.7 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L130) - Standalone TopTx, allocation without a declaration**

Build and sign the exact allocation from [N05](#ds-tx-declarations-requirements-operations-allocation-n05),
then remove only TopTx's declaration and re-sign. Keep its funded inputs, proposed
outputs and fees unchanged; do not rebalance the mutated transaction.

$$
\neg\text{hasDeclaration(topTx)}
\implies\text{RejectedWith(MissingUTxODepositDeclaration)}
$$

Allocation is the reason a declaration is required: there is neither a recorded
deposit release nor a SubTx declaration dependency. Removing the allocation
declaration may also break conservation; that does not replace the required
missing-declaration failure. Finally, submit the unchanged, fully declared
transaction and require acceptance.

<a id="ds-tx-presence-activity-creation-f03" name="ds-tx-presence-activity-creation-f03"></a>
<a id="ds-tx-presence-operations-allocation-f03" name="ds-tx-presence-operations-allocation-f03"></a>
<a id="ds-tx-required-declarations-operations-allocation-f03" name="ds-tx-required-declarations-operations-allocation-f03"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f03" name="ds-tx-declarations-requirements-operations-allocation-f03"></a>

**2.1.1.2.1.2.8 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L145) - rejects a SubTx creating a store-backed output without its own declaration**

The ledger rejects a SubTx that creates a store-backed own output without a SubTx declaration. The expected failure is SubMissingUTxODepositDeclaration, and rejection leaves ledger state unchanged. Declaration presence is required independently for the creating body.

<a id="ds-tx-presence-activity-creation-f04" name="ds-tx-presence-activity-creation-f04"></a>
<a id="ds-tx-presence-operations-allocation-f04" name="ds-tx-presence-operations-allocation-f04"></a>
<a id="ds-tx-required-declarations-operations-allocation-f04" name="ds-tx-required-declarations-operations-allocation-f04"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f04" name="ds-tx-declarations-requirements-operations-allocation-f04"></a>

**2.1.1.2.1.2.9 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L149) - rejects a TopTx creating a store-backed output without its own declaration even when phase 2 fails**

A real failing phase-2 script does not waive TopTx's structural declaration requirement. Even with the transaction marked phase-2 invalid, creating a store-backed own output without a declaration yields MissingUTxODepositDeclaration and leaves the ledger unchanged.

<a id="ds-tx-presence-activity-creation-f05" name="ds-tx-presence-activity-creation-f05"></a>
<a id="ds-tx-presence-operations-allocation-f05" name="ds-tx-presence-operations-allocation-f05"></a>
<a id="ds-tx-required-declarations-operations-allocation-f05" name="ds-tx-required-declarations-operations-allocation-f05"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f05" name="ds-tx-declarations-requirements-operations-allocation-f05"></a>

**2.1.1.2.1.2.10 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L153) - rejects a SubTx creating a store-backed output without its own declaration even when phase 2 fails**

A real phase-2 failure does not waive a creating SubTx's declaration requirement. The ledger still returns SubMissingUTxODepositDeclaration for the undeclared store-backed own output; the rejected transaction applies no state changes.

<a id="ds-tx-presence-activity-creation-f06" name="ds-tx-presence-activity-creation-f06"></a>
<a id="ds-tx-presence-operations-allocation-f06" name="ds-tx-presence-operations-allocation-f06"></a>
<a id="ds-tx-required-declarations-operations-allocation-f06" name="ds-tx-required-declarations-operations-allocation-f06"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f06" name="ds-tx-declarations-requirements-operations-allocation-f06"></a>

**2.1.1.2.1.2.11 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L161) - rejects a missing own declaration when spending a translated implicit output to create store-backed outputs**

> **An implicit source does not remove the declaration required by a new Store allocation.**

Build a Conway output and apply the production output upgrade to Dijkstra. Fund
that translated output through an accepted transaction, then consume its real
`TxIn` to create one to five generated outputs, including at least one store-backed
output. Its address, value and implicit form are preserved; it has no Store record.

$$
\begin{aligned}
\text{releasedDeposits(topTx)}&=0 \\
\text{allocatedDeposits(topTx)}&>0 \\
\neg\text{hasDeclaration(topTx)}
&\implies\text{RejectedWith(MissingUTxODepositDeclaration)}
\end{aligned}
$$

Start with the signed exact-allocation control. Remove only TopTx's declaration
and re-sign: the modified proposal must be rejected for that missing field.
The original declared transaction must be accepted.

**Boundary:** this exercises the real Conway-to-Dijkstra **output conversion**
and subsequent ledger funding. It does not execute a complete hard-fork transition
of the ledger state.

<a id="ds-tx-presence-activity-scope-n01" name="ds-tx-presence-activity-scope-n01"></a>
<a id="ds-tx-presence-operations-scope-n01" name="ds-tx-presence-operations-scope-n01"></a>
<a id="ds-tx-presence-operations-allocation-n06" name="ds-tx-presence-operations-allocation-n06"></a>
<a id="ds-tx-required-declarations-operations-allocation-n06" name="ds-tx-required-declarations-operations-allocation-n06"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n06" name="ds-tx-declarations-requirements-operations-allocation-n06"></a>

**2.1.1.2.1.2.12 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L178) - SubTx outputs do not trigger TopTx allocation presence**

TopTx has no own outputs and no declaration. Its nested SubTx creates store-backed
outputs and explicitly declares zero. The isolated TopTx allocation-presence validator succeeds:
the child's outputs do not enter $\text{createdStoreBackedOutputs(topTx)}$.

This transaction is not established as acceptable. The child's explicit zero
triggers dependency, so the absent TopTx declaration fails that separate rule.
The child's amount is also outside this isolated check.

<a id="ds-tx-presence-activity-scope-n02" name="ds-tx-presence-activity-scope-n02"></a>
<a id="ds-tx-presence-operations-scope-n02" name="ds-tx-presence-operations-scope-n02"></a>
<a id="ds-tx-presence-operations-allocation-n07" name="ds-tx-presence-operations-allocation-n07"></a>
<a id="ds-tx-required-declarations-operations-allocation-n07" name="ds-tx-required-declarations-operations-allocation-n07"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n07" name="ds-tx-declarations-requirements-operations-allocation-n07"></a>

**2.1.1.2.1.2.13 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L188) - Collateral return does not trigger allocation presence**

TopTx has a store-backed collateral return, no regular outputs and no declaration.
The isolated allocation-presence validator succeeds because collateral return is outside
$\text{createdStoreBackedOutputs(topTx)}$. Its independent collateral funding and
validity requirements still apply.

<a id="ds-tx-presence-activity-scope-n03" name="ds-tx-presence-activity-scope-n03"></a>
<a id="ds-tx-presence-operations-scope-n03" name="ds-tx-presence-operations-scope-n03"></a>
<a id="ds-tx-presence-operations-allocation-n08" name="ds-tx-presence-operations-allocation-n08"></a>
<a id="ds-tx-required-declarations-operations-allocation-n08" name="ds-tx-required-declarations-operations-allocation-n08"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n08" name="ds-tx-declarations-requirements-operations-allocation-n08"></a>

**2.1.1.2.1.2.14 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L194) - Reference and collateral input identifiers do not trigger allocation presence**

Place the same arbitrary input identifier in both reference and collateral input
sets, with no regular outputs or declaration. The isolated allocation-presence validator
succeeds: neither field is a created output. The fixture does **not resolve the
identifier** or prove that it names a store-backed output or valid collateral.

<a id="ds-tx-presence-activity-scope-f01" name="ds-tx-presence-activity-scope-f01"></a>
<a id="ds-tx-presence-operations-scope-f01" name="ds-tx-presence-operations-scope-f01"></a>
<a id="ds-tx-presence-operations-allocation-f07" name="ds-tx-presence-operations-allocation-f07"></a>
<a id="ds-tx-required-declarations-operations-allocation-f07" name="ds-tx-required-declarations-operations-allocation-f07"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f07" name="ds-tx-declarations-requirements-operations-allocation-f07"></a>

**2.1.1.2.1.2.15 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L200) - A SubTx declaration cannot satisfy TopTx allocation presence**

TopTx creates store-backed own outputs but declares nothing. Its nested SubTx
also creates store-backed outputs and explicitly declares zero. The child's
declaration cannot supply TopTx's field: the isolated TopTx allocation-presence validator
returns `MissingBodyUTxODepositDeclaration`.

<a id="ds-tx-presence-activity-scope-f02" name="ds-tx-presence-activity-scope-f02"></a>
<a id="ds-tx-presence-operations-scope-f02" name="ds-tx-presence-operations-scope-f02"></a>
<a id="ds-tx-presence-operations-allocation-f08" name="ds-tx-presence-operations-allocation-f08"></a>
<a id="ds-tx-required-declarations-operations-allocation-f08" name="ds-tx-required-declarations-operations-allocation-f08"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f08" name="ds-tx-declarations-requirements-operations-allocation-f08"></a>

**2.1.1.2.1.2.16 [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L212) - TopTx zero cannot satisfy its allocating SubTx's declaration requirement**

TopTx explicitly declares zero while its SubTx creates a store-backed output and
omits its own declaration. The ledger rejection must include
`SubMissingUTxODepositDeclaration`.

$$
\begin{aligned}
&\text{createdStoreBackedOutputs(subTx)}\ne\varnothing \\
&\land\ \neg\text{hasDeclaration(subTx)} \\
&\land\ \text{declaredNetDeposit(topTx)}=0 \\
&\implies\text{RejectedWith(SubMissingUTxODepositDeclaration)}
\end{aligned}
$$

The parent's zero also fails exactness because a positive allocation is required.
This case requires the child's presence failure **among** the reported failures;
it does not start from an otherwise valid allocation control.

<a id="ds-tx-presence-activity-scope-n06" name="ds-tx-presence-activity-scope-n06"></a>
<a id="ds-tx-presence-operations-scope-n06" name="ds-tx-presence-operations-scope-n06"></a>
<a id="ds-tx-presence-operations-allocation-n09" name="ds-tx-presence-operations-allocation-n09"></a>
<a id="ds-tx-required-declarations-operations-allocation-n09" name="ds-tx-required-declarations-operations-allocation-n09"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n09" name="ds-tx-declarations-requirements-operations-allocation-n09"></a>

**2.1.1.2.1.2.17 [N09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L223) - TopTx and SubTx allocate deposits, each with an exact declaration**

> **SubTx declares its own allocation; TopTx declares the complete transaction allocation.**

TopTx and exactly one SubTx each create one to five generated outputs, with at
least one store-backed output per body. Their output forms, positions and
application amounts vary independently. Both spend only implicit inputs, so
neither releases a recorded deposit.

$$
\begin{aligned}
\text{allocatedDeposits(topTx)}&>0 \\
\text{allocatedDeposits(subTx)}&>0 \\
\text{releasedDeposits(topTx)}&=\text{releasedDeposits(subTx)}=0 \\
\text{declaredNetDeposit(subTx)}&=\text{allocatedDeposits(subTx)} \\
\text{declaredNetDeposit(topTx)}
&=\text{allocatedDeposits(topTx)}+\text{allocatedDeposits(subTx)}
\end{aligned}
$$

Price the two output sequences independently. Fund the child's application
outputs and own allocation from its implicit input; TopTx supplies the remaining
funding and fees. The transaction with these exact declarations must be accepted.

<a id="ds-tx-presence-activity-spending" name="ds-tx-presence-activity-spending"></a>
<a id="ds-tx-presence-operations-release" name="ds-tx-presence-operations-release"></a>
<a id="ds-tx-required-declarations-operations-release" name="ds-tx-required-declarations-operations-release"></a>
<a id="ds-tx-declarations-requirements-operations-release" name="ds-tx-declarations-requirements-operations-release"></a>

**2.1.1.2.1.3 Release**

> **A body releasing a recorded Store deposit must declare its own deposit change.**

$$
\forall\,\text{body}:\quad
\text{storeBackedInputs(body)}\ne\varnothing
\implies\text{hasDeclaration(body)}
$$

**Decision:** Agreed.

Apply the rule **independently to TopTx and every SubTx**, using each body's own
ordinary inputs resolved against the original UTxO. Reference inputs, collateral
inputs and a child's inputs do not count as this body's consumed outputs.

| Store-backed inputs | Own declaration | Declaration requirement result |
| --- | --- | --- |
| Present | Absent | **Reject:** missing declaration. |
| Present | Present | **Pass presence.** Acceptance still requires exact amounts, valid settlement and all other ledger rules. |
| Absent | Either | **No release-presence requirement.** [Allocation](#ds-tx-declarations-requirements-operations-allocation) or [SubTx declarations](#ds-tx-declarations-requirements-subtx-declarations) may still require a declaration. |

Equivalently:

$$
\text{releasePresenceValid(body)}
\iff \text{storeBackedInputs(body)}=\varnothing\lor\text{hasDeclaration(body)}
$$

**Explicit zero counts as a declaration.** Its amount must still be correct.
The presence rule applies on both phase-2 outcomes. Each scenario below states
the proposed release, the declaration supplied or omitted, and the resulting
acceptance or rejection.

**Releasing a deposit** means consuming its store-backed UTxO in the proposed
ordinary transition. The released amount is the deposit recorded for that source;
newly created store-backed outputs require separate allocations.

A **gross release** does not imply a **net release**. New allocations minus
recorded releases can be positive, zero or negative. The body declares its net
contribution; TopTx declares the transaction total.

These cases specify **transaction acceptance or rejection**, including the required
missing-declaration failure. Reference-only access and collateral-only operations
are accepted without an ordinary declaration; a child's declaration cannot replace
its parent's required field. [Ledger effects](#ds-state) specifies the resulting
state transitions: [Execution](#ds-state-execution),
[Allocations](#ds-state-allocations) and [Balance](#ds-state-balance).

| Notation | Meaning |
| --- | --- |
| $\text{body}$ | TopTx or one of its SubTxs, considered separately. |
| $\text{storeBackedInputs(body)}$ | Its own ordinary inputs resolving to store-backed outputs in the original UTxO. |
| $\text{hasDeclaration(body)}$ | That body explicitly declares a change, including explicit zero. |
| $\text{releasedDeposits(body)}$ | Sum of recorded deposits of its consumed store-backed outputs, proposed for ordinary release. |
| $\text{allocatedDeposits(body)}$ | Sum of required deposits of its newly created store-backed outputs. |
| $\text{declaredNetDeposit(body)}$ | The signed declaration: allocation positive, release negative, explicit zero equal to 0. TopTx declares the transaction total. |

A declaration is required on **both phase-2 outcomes**, even when no new store-backed
output is created.

Acceptance cases satisfy all other ledger requirements, including exact amounts
and valid settlement. Rejection cases omit a releasing body's required declaration
while retaining its source inputs and proposed settlement. They state whether the
omission is supplied during preparation or applied to a prepared valid control.
Net change separately checks the declared amounts.

N01 covers a standalone TopTx with any generated output form; N02 specializes it
to **only implicit outputs**. Source outputs are created by accepted funding
transactions. Their allocations are read from the resulting ledger state, so a
release always has a funded, recorded deposit behind it.

Scenarios may also include unrelated store-backed outputs; their deposits are
excluded from the proposed release. No test inserts an invented allocation into
the live ledger.

<a id="ds-tx-presence-activity-spending-n01" name="ds-tx-presence-activity-spending-n01"></a>
<a id="ds-tx-presence-operations-release-n01" name="ds-tx-presence-operations-release-n01"></a>
<a id="ds-tx-required-declarations-operations-release-n01" name="ds-tx-required-declarations-operations-release-n01"></a>
<a id="ds-tx-declarations-requirements-operations-release-n01" name="ds-tx-declarations-requirements-operations-release-n01"></a>

**2.1.1.2.1.3.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L61) - Standalone TopTx, any output form**

**Scenario**

| Body | Consumes | Creates |
| --- | --- | --- |
| TopTx only: $\text{subTxs}=\varnothing$ | Store-backed outputs: $\text{releasedDeposits}>0$ | Implicit outputs, store-backed outputs, or a mixture. |

Each generated proposal starts with **funded inputs and no TopTx declaration**.
Calculate its required net deposit, declare that amount, then build, sign and
submit the transaction. Preparation preserves the declaration supplied by the case.

**Calculation**

All amounts below belong to this TopTx. The two sums have separate scopes:

| Amount | Sum | Includes only |
| --- | --- | --- |
| $\text{allocatedDeposits}$ | $\displaystyle\sum_{\text{newOutput}}\text{requiredDeposit(newOutput)}$ | Newly created store-backed outputs. |
| $\text{releasedDeposits}$ | $\displaystyle\sum_{\text{input}}\text{recordedDeposit(input)}$ | Consumed store-backed inputs. |

New allocations use the [deposit calculation](#ds-pricing) with fixed protocol
parameters. Releases use the **recorded ledger amounts**. Implicit inputs release
no Store deposit; implicit outputs require no Store allocation. Existing outputs
left unspent are excluded.

**Expected result**

Under this scenario, with all other ledger rules satisfied:

$$
\begin{gathered}
\text{declaredNetDeposit}=\text{allocatedDeposits}-\text{releasedDeposits} \\
\Downarrow \\
\text{Accepted}
\end{gathered}
$$

**Examples** (illustrative totals in ADA):

| Allocate for new outputs | Release from consumed inputs | Exact net deposit | Required declaration |
| ---: | ---: | ---: | --- |
| 5 ₳ | 2 ₳ | $5-2=+3$ ₳ | Allocate **3 ₳**. |
| 2 ₳ | 2 ₳ | $2-2=0$ ₳ | Explicitly declare **zero**. |
| 0 ₳ | 2 ₳ | $0-2=-2$ ₳ | Release **2 ₳** into TopTx's own output 0. |

Fees and any additional allocation are funded separately. A release is accounted
for in its declared settlement output.

<a id="ds-tx-presence-activity-spending-n02" name="ds-tx-presence-activity-spending-n02"></a>
<a id="ds-tx-presence-operations-release-n02" name="ds-tx-presence-operations-release-n02"></a>
<a id="ds-tx-required-declarations-operations-release-n02" name="ds-tx-required-declarations-operations-release-n02"></a>
<a id="ds-tx-declarations-requirements-operations-release-n02" name="ds-tx-declarations-requirements-operations-release-n02"></a>

**2.1.1.2.1.3.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L84) - Standalone TopTx, only implicit outputs**

No new Store allocation is required ($\text{allocatedDeposits}=0$),
so TopTx directly declares a release of $\text{releasedDeposits}$ into its output 0.
The declaration carries the positive amount being released and represents
$\text{netDeposit}=-\text{releasedDeposits}$. Its SubTx declaration list is empty.
Build and sign that proposal, then require acceptance.

$$
\begin{aligned}
&\text{subTxs}=\varnothing \land \text{releasedDeposits}>0 \\
&\land\ \text{storeBackedOutputs}=\varnothing \\
&\land\ \text{declaredNetDeposit}=-\text{releasedDeposits} \\
&\implies \text{Accepted}
\end{aligned}
$$

**Example:** fees are funded separately and no other charges or transfers apply.

```text
Existing store-backed output
├── Application ADA:       10 ₳
└── Deposit in the Store:   2 ₳ (recorded separately)

Proposed TopTx without SubTxs
├── Spends that output
├── Creates no store-backed outputs
├── Declares a release of 2 ₳
└── Creates an implicit settlement output containing 12 ₳
```

The proposed settlement output contains $10 + 2 = 12$ ₳, accounting for the
application ADA and the declared release. The otherwise valid transaction must
be accepted.

<a id="ds-tx-presence-activity-spending-n03" name="ds-tx-presence-activity-spending-n03"></a>
<a id="ds-tx-presence-operations-release-n03" name="ds-tx-presence-operations-release-n03"></a>
<a id="ds-tx-required-declarations-operations-release-n03" name="ds-tx-required-declarations-operations-release-n03"></a>
<a id="ds-tx-declarations-requirements-operations-release-n03" name="ds-tx-declarations-requirements-operations-release-n03"></a>

**2.1.1.2.1.3.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L98) - One SubTx releases its deposit into its own output**

TopTx has no Store operations of its own and declares the matching total. The SubTx
proposes to consume a store-backed output and create only implicit outputs,
so it declares the full recorded deposit as a release. The two declarations
account for **one proposed release**, assigned to the SubTx.

Fund the generated source first, then supply both declarations together from the
**same positive deposit recorded for that input**. The SubTx names its own output 0;
TopTx declares the matching total with `NoTopTxSettlement`. None of this release
is assigned to TopTx. Build and sign that declared proposal, then require acceptance.

The source's application ADA and the unrelated live outputs may vary. The recorded
deposit always comes from the funded ledger state.

$$
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{releasedDeposits(subTx)}>0 \land \text{allocatedDeposits(subTx)}=0 \\
&\land\ \text{declaredNetDeposit(topTx)}=\text{declaredNetDeposit(subTx)}
=-\text{releasedDeposits(subTx)} \\
&\implies \text{Accepted}
\end{aligned}
$$

**Example:** the consumed output contains **10 ₳ of application ADA** and has a
recorded Store deposit of $\text{deposit}$. With fees funded separately, its proposed
implicit settlement output contains:

$$
\text{SubTx output coins} = 10\text{ ₳} + \text{deposit}
$$

| Body | Declaration |
| --- | --- |
| SubTx | Release the recorded deposit into its own output 0. |
| TopTx | Declare the same total net release with `NoTopTxSettlement`. |

This is the acceptance counterpart of [F02](#ds-tx-declarations-requirements-operations-release-f02).
F02 uses the same generated release scenario but supplies no SubTx declaration;
TopTx still declares the exact total.

<a id="ds-tx-presence-activity-spending-f01" name="ds-tx-presence-activity-spending-f01"></a>
<a id="ds-tx-presence-operations-release-f01" name="ds-tx-presence-operations-release-f01"></a>
<a id="ds-tx-required-declarations-operations-release-f01" name="ds-tx-required-declarations-operations-release-f01"></a>
<a id="ds-tx-declarations-requirements-operations-release-f01" name="ds-tx-declarations-requirements-operations-release-f01"></a>

**2.1.1.2.1.3.4 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L110) - Standalone TopTx, release without its own declaration**

**Scenario**

Generate a standalone transaction consuming one to five store-backed outputs,
as in [N02](#ds-tx-declarations-requirements-operations-release-n02). Declare its exact total release
into TopTx's output 0, then build and sign it. Remove only TopTx's declaration and
re-sign. The proposed inputs and outputs remain unchanged.

| Body | Consumes | Creates | Declaration |
| --- | --- | --- | --- |
| TopTx, with no SubTxs | One or more store-backed outputs with recorded deposits. | Only implicit outputs; the settlement output includes the complete proposed release. | Absent. |

**Expected result**

$$
\begin{aligned}
&\text{subTxs}=\varnothing \\
&\land\ \text{releasedDeposits(topTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=0 \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\implies \text{Rejected}
\end{aligned}
$$

Rejection must include `MissingUTxODepositDeclaration`.

**Why:** TopTx's own release requires its declaration. There are no SubTxs,
so [declaration dependency](#ds-tx-declarations-requirements-subtx-declarations) imposes no requirement.
Creating only implicit outputs also excludes allocation presence as the reason for
this missing-declaration failure.

Removing the declared release can additionally break accounting or value conservation.
Those failures do not replace the required release-presence failure.

<a id="ds-tx-presence-activity-spending-f02" name="ds-tx-presence-activity-spending-f02"></a>
<a id="ds-tx-presence-operations-release-f02" name="ds-tx-presence-operations-release-f02"></a>
<a id="ds-tx-required-declarations-operations-release-f02" name="ds-tx-required-declarations-operations-release-f02"></a>
<a id="ds-tx-declarations-requirements-operations-release-f02" name="ds-tx-declarations-requirements-operations-release-f02"></a>

**2.1.1.2.1.3.5 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L126) - SubTx release without its own declaration, despite TopTx declaring**

**Scenario**

Use [N03](#ds-tx-declarations-requirements-operations-release-n03)'s generated source input and implicit
settlement. Fund the source, then supply TopTx's exact recorded release and an
**absent SubTx declaration** together, before building and signing. The SubTx still
proposes to consume that source and receive its application ADA plus the recorded
deposit.

TopTx's fee and change are prepared for this declaration shape. The missing field
is part of the proposal from the outset; no declaration is removed after signing.

| Body | Own Store operations | Declaration |
| --- | --- | --- |
| TopTx | None. | Declares the full release with `NoTopTxSettlement`. |
| Its single SubTx | Consumes a store-backed output and creates only implicit outputs, including its settlement output. | Absent. |

**Expected result**

$$
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{releasedDeposits(subTx)}>0 \\
&\land\ \text{releasedDeposits(topTx)}=0 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{allocatedDeposits(subTx)}=0 \\
&\land\ \text{declaredNetDeposit(topTx)}=-\text{releasedDeposits(subTx)} \\
&\land\ \neg\text{hasDeclaration(subTx)} \\
&\implies \text{Rejected}
\end{aligned}
$$

Rejection must include `SubMissingUTxODepositDeclaration`. Additional accounting
failures may occur, but the missing declaration for its release must be reported.

**Why:** The SubTx's own release requires its own declaration. TopTx's declared
total cannot substitute for it. The parent declaration satisfies
[declaration dependency](#ds-tx-declarations-requirements-subtx-declarations); the missing field belongs
to the SubTx releasing deposits itself.

[SubTx declarations C02-N03](#ds-tx-declarations-requirements-subtx-declarations-c02-n03) accepts the same presence pattern
(TopTx present, SubTx absent) when there are **no Store operations**. Here the SubTx
spends a store-backed output, which introduces its own declaration requirement.

| Case | TopTx declaration | SubTx declaration | Source of the obligation |
| --- | --- | --- | --- |
| Release F01 | Absent. | No SubTx exists. | TopTx's own store-backed input. |
| Release F02 | Present. | Absent. | SubTx's own store-backed input. |
| [SubTx declarations C02-F01](#ds-tx-declarations-requirements-subtx-declarations-c02-f01) | Absent. | Explicit zero. | The SubTx declaration, even without Store operations. |

<a id="ds-tx-presence-activity-spending-n04" name="ds-tx-presence-activity-spending-n04"></a>
<a id="ds-tx-presence-operations-release-n04" name="ds-tx-presence-operations-release-n04"></a>
<a id="ds-tx-required-declarations-operations-release-n04" name="ds-tx-required-declarations-operations-release-n04"></a>
<a id="ds-tx-declarations-requirements-operations-release-n04" name="ds-tx-declarations-requirements-operations-release-n04"></a>

**2.1.1.2.1.3.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L139) - Phase 2 fails with valid declarations**

An otherwise valid release proposal remains acceptable when marked phase-2 invalid
and supplied with a script that fails.
For each generated single-source scenario, exercise both owners: a standalone
TopTx, then one SubTx releasing deposits whose parent has no Store operations of its own.
Both variants create only implicit ordinary outputs.

$$
\begin{aligned}
&\text{releasedDeposits(body)}>0 \\
&\land\ \text{declaredNetDeposit(topTx)}=\text{declaredNetDeposit(body)}
=-\text{releasedDeposits(body)} \\
&\land\ \text{phase1Valid}\land\text{phase2Result}=\text{Failed} \\
&\land\ \text{declaredPhase2}=\text{Invalid} \\
&\implies \text{Accepted}
\end{aligned}
$$

Both the collateral inputs and the proposed return are implicit. This case checks
acceptance with the required ordinary declarations; the resulting collateral
transition belongs to [Execution](#ds-state-execution).

<a id="ds-tx-presence-activity-spending-f03" name="ds-tx-presence-activity-spending-f03"></a>
<a id="ds-tx-presence-operations-release-f03" name="ds-tx-presence-operations-release-f03"></a>
<a id="ds-tx-required-declarations-operations-release-f03" name="ds-tx-required-declarations-operations-release-f03"></a>
<a id="ds-tx-declarations-requirements-operations-release-f03" name="ds-tx-declarations-requirements-operations-release-f03"></a>

**2.1.1.2.1.3.7 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L154) - Missing release declaration in a phase-2-invalid proposal**

The transaction is rejected. TopTx's failures must include
`MissingUTxODepositDeclaration`; SubTx's must include
`SubMissingUTxODepositDeclaration`. Each case
removes only the declaration for its release from its N04 scenario. Every generated
single-source scenario exercises both release owners.

$$
\begin{aligned}
&\text{releasedDeposits(body)}>0\land\neg\text{hasDeclaration(body)} \\
&\land\ \text{phase2Script}=\text{AlwaysFails}\land\text{declaredPhase2}=\text{Invalid} \\
&\implies \text{Rejected}
\end{aligned}
$$

A missing declaration rejects the proposal in phase 1. The failing script does
not exempt it from that check; the test does not require phase 2 to execute.

<a id="ds-tx-presence-activity-spending-n05" name="ds-tx-presence-activity-spending-n05"></a>
<a id="ds-tx-presence-operations-release-n05" name="ds-tx-presence-operations-release-n05"></a>
<a id="ds-tx-required-declarations-operations-release-n05" name="ds-tx-required-declarations-operations-release-n05"></a>
<a id="ds-tx-declarations-requirements-operations-release-n05" name="ds-tx-declarations-requirements-operations-release-n05"></a>

**2.1.1.2.1.3.8 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L180) - Several SubTxs release their deposits**

**Every SubTx releasing deposits declares its own release; TopTx declares their total.**
Generate two to five SubTxs with varying application ADA amounts. Each consumes
its own funded store-backed output and creates an implicit settlement output.
TopTx has no Store operations of its own and funds transaction fees separately.

All ordinary outputs are implicit, so no new Store allocation is required. Each
SubTx proposes its own settlement output containing its input's application ADA
plus the recorded deposit:

$$
\begin{aligned}
|\text{subTxs}| &\ge 2 \\
\forall\,\text{subTx}\in\text{subTxs}:\quad
\text{releasedDeposits(subTx)} &> 0 \\
\forall\,\text{subTx}\in\text{subTxs}:\quad
\text{declaredNetDeposit(subTx)} &= -\text{releasedDeposits(subTx)} \\
\forall\,\text{subTx}\in\text{subTxs}:\quad
\text{settlementCoins(subTx)} &= \text{inputApplicationCoins(subTx)} + \text{releasedDeposits(subTx)} \\
\text{declaredNetDeposit(topTx)} &= -\sum_{\text{subTx}\in\text{subTxs}}\text{releasedDeposits(subTx)} \\
&\Longrightarrow \text{Accepted}
\end{aligned}
$$

TopTx uses `NoTopTxSettlement`: each release is assigned to its SubTx's own output 0.
The parent declaration accounts for those same releases once. With every releasing
body declared and the remaining rules satisfied, the transaction is accepted.

<a id="ds-tx-presence-activity-spending-f04" name="ds-tx-presence-activity-spending-f04"></a>
<a id="ds-tx-presence-operations-release-f04" name="ds-tx-presence-operations-release-f04"></a>
<a id="ds-tx-required-declarations-operations-release-f04" name="ds-tx-required-declarations-operations-release-f04"></a>
<a id="ds-tx-declarations-requirements-operations-release-f04" name="ds-tx-declarations-requirements-operations-release-f04"></a>

**2.1.1.2.1.3.9 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L198) - One SubTx releasing deposits omits its declaration**

**One undeclared SubTx releasing deposits rejects the entire transaction.** Starting from
N05's funded proposal, remove exactly one SubTx declaration and re-sign. Repeat
for every position in the actual SubTx sequence. TopTx keeps the exact total;
all other SubTxs keep their exact local declarations.

```text
declared, declared, absent, declared, …
                  └── its store-backed input still requires a declaration
```

For each $\text{selectedSubTx}\in\text{subTxs}$, submit a separate proposal:

$$
\begin{aligned}
&|\text{subTxs}|\ge 2 \\
&\land\ \text{missingDeclarations}=\{\text{selectedSubTx}\} \\
&\land\ \text{declaredNetDeposit(topTx)}
=-\sum_{\text{subTx}\in\text{subTxs}}\text{releasedDeposits(subTx)} \\
&\land\ \forall\,\text{otherSubTx}\in\text{subTxs}\setminus\{\text{selectedSubTx}\}:\quad
\text{declaredNetDeposit(otherSubTx)}=-\text{releasedDeposits(otherSubTx)} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{SubMissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

The parent's total and the other children's declarations cannot cover the
selected child's missing field. Additional accounting failures may occur;
the missing-declaration failure must still be present.

After trying every child position, submit the unchanged, fully declared control.
It must be accepted.

<a id="ds-tx-presence-activity-spending-n06" name="ds-tx-presence-activity-spending-n06"></a>
<a id="ds-tx-presence-operations-release-n06" name="ds-tx-presence-operations-release-n06"></a>
<a id="ds-tx-required-declarations-operations-release-n06" name="ds-tx-required-declarations-operations-release-n06"></a>
<a id="ds-tx-declarations-requirements-operations-release-n06" name="ds-tx-declarations-requirements-operations-release-n06"></a>

**2.1.1.2.1.3.10 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L222) - Only some SubTxs release Store deposits**

**A SubTx releasing deposits does not impose its declaration requirement on its siblings.**
Mix SubTxs consuming store-backed outputs with SubTxs consuming only implicit
outputs, varying their positions. Both groups are nonempty; all created outputs
are implicit. The latter group has no Store operations and omits its declarations.

$$
\begin{aligned}
\text{releasingSubTxs} &= \{\text{subTx}\in\text{subTxs}\mid\text{storeBackedInputs(subTx)}\ne\varnothing\} \\
\text{implicitOnlySubTxs} &= \text{subTxs}\setminus\text{releasingSubTxs}
\end{aligned}
$$

| SubTx group | Own declaration | Own settlement |
| --- | --- | --- |
| $\text{releasingSubTxs}$ | Exact release of its recorded deposit. | Application ADA plus its released deposit. |
| $\text{implicitOnlySubTxs}$ | Absent. | Its application ADA, with no Store transfer. |

$$
\begin{aligned}
\text{releasingSubTxs} &\ne \varnothing \\
\text{implicitOnlySubTxs} &\ne \varnothing \\
\forall\,\text{subTx}\in\text{releasingSubTxs}:\quad
\text{declaredNetDeposit(subTx)} &= -\text{releasedDeposits(subTx)} \\
\forall\,\text{subTx}\in\text{implicitOnlySubTxs}:\quad
\text{hasDeclaration(subTx)} &= \text{False} \\
\text{declaredNetDeposit(topTx)} &= -\sum_{\text{subTx}\in\text{releasingSubTxs}}\text{releasedDeposits(subTx)} \\
&\Longrightarrow \text{Accepted}
\end{aligned}
$$

TopTx has no Store operations of its own and declares the exact total with
`NoTopTxSettlement`. The transaction must be accepted: declaration presence is
checked per body, and the inactive siblings need no declaration merely because
another SubTx proposes a release.

<a id="ds-tx-presence-activity-spending-n07" name="ds-tx-presence-activity-spending-n07"></a>
<a id="ds-tx-presence-operations-release-n07" name="ds-tx-presence-operations-release-n07"></a>
<a id="ds-tx-required-declarations-operations-release-n07" name="ds-tx-required-declarations-operations-release-n07"></a>
<a id="ds-tx-declarations-requirements-operations-release-n07" name="ds-tx-declarations-requirements-operations-release-n07"></a>

**2.1.1.2.1.3.11 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L243) - TopTx and several SubTxs release deposits**

**TopTx can release its own deposit while its SubTxs release theirs locally.**
TopTx and each of at least two SubTxs propose to consume their own store-backed
outputs. All proposed outputs are implicit; each body assigns its own release
to its own settlement output. Fees are funded separately.

$$
\begin{aligned}
|\text{subTxs}| &\ge 2 \\
\text{releasedDeposits(topTx)} &> 0 \\
\forall\,\text{subTx}\in\text{subTxs}:\quad
\text{releasedDeposits(subTx)} &> 0 \\
\text{declaredNetDeposit(topTx)} &= -\text{releasedDeposits(topTx)}
-\sum_{\text{subTx}\in\text{subTxs}}\text{releasedDeposits(subTx)} \\
\forall\,\text{subTx}\in\text{subTxs}:\quad
\text{declaredNetDeposit(subTx)} &= -\text{releasedDeposits(subTx)} \\
&\Longrightarrow \text{Accepted}
\end{aligned}
$$

| Body | Declared amount | Amount in its proposed settlement output |
| --- | --- | --- |
| TopTx | Total release across TopTx and SubTxs. | Its own application ADA plus its own recorded deposit. |
| Each SubTx | Its own release. | Its own application ADA plus its own recorded deposit. |

TopTx names its own output 0 because part of the total is assigned to it.
Each child's release remains assigned to that child's output 0. This valid mixed
participation must be accepted.

<a id="ds-tx-presence-activity-spending-n08" name="ds-tx-presence-activity-spending-n08"></a>
<a id="ds-tx-presence-operations-release-n08" name="ds-tx-presence-operations-release-n08"></a>
<a id="ds-tx-required-declarations-operations-release-n08" name="ds-tx-required-declarations-operations-release-n08"></a>
<a id="ds-tx-declarations-requirements-operations-release-n08" name="ds-tx-declarations-requirements-operations-release-n08"></a>

**2.1.1.2.1.3.12 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L261) - Phase 2 fails with several proposed SubTx releases**

**Valid declarations remain required on the phase-2 failure path.**
Prepare the several-SubTx releases from N05, add a genuinely failing Plutus V4
script, and mark the transaction phase-2 invalid. TopTx and every SubTx retain
their exact declarations and settlement outputs. The ordinary proposal remains
fully funded.

$$
\begin{aligned}
|\text{subTxs}| &\ge 2 \\
\forall\,\text{subTx}\in\text{subTxs}:\quad
\text{declaredNetDeposit(subTx)} &= -\text{releasedDeposits(subTx)} \\
\text{declaredNetDeposit(topTx)} &= -\sum_{\text{subTx}\in\text{subTxs}}\text{releasedDeposits(subTx)} \\
\text{phase1Valid} &= \text{True} \\
\text{declaredPhase2} &= \text{Invalid} \\
\text{phase2Result} &= \text{Failed} \\
&\Longrightarrow \text{Accepted}
\end{aligned}
$$

The transaction must be accepted. Separate implicit collateral and an implicit
return provide a valid failure-path proposal. Its ledger effects belong to
[Execution](#ds-state-execution).

<a id="ds-tx-presence-activity-spending-f05" name="ds-tx-presence-activity-spending-f05"></a>
<a id="ds-tx-presence-operations-release-f05" name="ds-tx-presence-operations-release-f05"></a>
<a id="ds-tx-required-declarations-operations-release-f05" name="ds-tx-required-declarations-operations-release-f05"></a>
<a id="ds-tx-declarations-requirements-operations-release-f05" name="ds-tx-declarations-requirements-operations-release-f05"></a>

**2.1.1.2.1.3.13 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L279) - One SubTx declaration is missing in a phase-2-invalid proposal**

**A phase-2-invalid proposal still needs every active body's declaration.**
From N08's prepared transaction, remove exactly one SubTx declaration and re-sign.
Repeat for every position, retaining TopTx's total, every other declaration, the
failing script and the phase-2-invalid flag.

For each $\text{selectedSubTx}\in\text{subTxs}$, submit a separate proposal:

$$
\begin{aligned}
&|\text{subTxs}|\ge 2 \\
&\land\ \text{phase2Script}=\text{AlwaysFails}\land\text{declaredPhase2}=\text{Invalid} \\
&\land\ \text{missingDeclarations}=\{\text{selectedSubTx}\} \\
&\land\ \text{declaredNetDeposit(topTx)}
=-\sum_{\text{subTx}\in\text{subTxs}}\text{releasedDeposits(subTx)} \\
&\land\ \forall\,\text{otherSubTx}\in\text{subTxs}\setminus\{\text{selectedSubTx}\}:\quad
\text{declaredNetDeposit(otherSubTx)}=-\text{releasedDeposits(otherSubTx)} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{SubMissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

Each submission must be rejected with `SubMissingUTxODepositDeclaration`, possibly
alongside other accounting failures. This case checks a proposal carrying a
failing script; it does not require phase 2 to be reached or executed.

After every missing-declaration variant is rejected, submit the unchanged,
fully declared control. It must be accepted on the phase-2 failure path.

<a id="ds-tx-presence-activity-scope-n04" name="ds-tx-presence-activity-scope-n04"></a>
<a id="ds-tx-presence-operations-scope-n04" name="ds-tx-presence-operations-scope-n04"></a>
<a id="ds-tx-presence-operations-release-n09" name="ds-tx-presence-operations-release-n09"></a>
<a id="ds-tx-required-declarations-operations-release-n09" name="ds-tx-required-declarations-operations-release-n09"></a>
<a id="ds-tx-declarations-requirements-operations-release-n09" name="ds-tx-declarations-requirements-operations-release-n09"></a>

**2.1.1.2.1.3.14 [N09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L303) - Standalone TopTx, reference-only Store access**

> **Referencing a Store-backed output does not release its deposit.**

Fund one to five Store-backed outputs and their positive allocations through a
real ledger transaction. TopTx references those live outputs without consuming
them. Its ordinary inputs and outputs are implicit, and it has no SubTxs.

$$
\begin{aligned}
\text{storeBackedReferenceInputs(topTx)}&\ne\varnothing \\
\text{ordinaryStoreBackedInputs(topTx)}&=\varnothing \\
\text{createdStoreBackedOutputs(topTx)}&=\varnothing \\
\neg\text{hasDeclaration(topTx)}&\implies\text{Accepted}
\end{aligned}
$$

Fees and witnesses are supplied while preserving the references and absent
declaration. The accepted submission establishes that these real Store records
do not require an ordinary release declaration.

<a id="ds-tx-presence-activity-scope-n05" name="ds-tx-presence-activity-scope-n05"></a>
<a id="ds-tx-presence-operations-scope-n05" name="ds-tx-presence-operations-scope-n05"></a>
<a id="ds-tx-presence-operations-release-n10" name="ds-tx-presence-operations-release-n10"></a>
<a id="ds-tx-required-declarations-operations-release-n10" name="ds-tx-required-declarations-operations-release-n10"></a>
<a id="ds-tx-declarations-requirements-operations-release-n10" name="ds-tx-declarations-requirements-operations-release-n10"></a>

**2.1.1.2.1.3.15 [N10](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L312) - Standalone TopTx, collateral-only Store operations**

> **Collateral has its own Store accounting; it does not require an ordinary declaration.**

Each generated pair of application amounts exercises all three placements:

| Collateral input | Collateral return |
| --- | --- |
| Store-backed | Implicit |
| Implicit | Store-backed |
| Store-backed | Store-backed |

Fund the input on the real ledger and supply sufficient collateral coins for the
return, any additional return deposit, and the minimum fee. Every placement runs
with a real successful script and a real failing script, with the corresponding
phase-2 validity flag.

$$
\begin{aligned}
\text{subTxs}&=\varnothing \\
\text{ordinaryStoreBackedInputs(topTx)}&=\varnothing \\
\text{createdStoreBackedOutputs(topTx)}&=\varnothing \\
\neg\text{hasDeclaration(topTx)}&\implies\text{Accepted}
\end{aligned}
$$

All ordinary inputs and outputs are implicit. The declaration remains absent on
both paths. Collateral Store operations execute only on the accepted phase-2
failure path; the ordinary declaration requirement remains unchanged.

<a id="ds-tx-presence-activity-scope-f03" name="ds-tx-presence-activity-scope-f03"></a>
<a id="ds-tx-presence-operations-scope-f03" name="ds-tx-presence-operations-scope-f03"></a>
<a id="ds-tx-presence-operations-release-f06" name="ds-tx-presence-operations-release-f06"></a>
<a id="ds-tx-required-declarations-operations-release-f06" name="ds-tx-required-declarations-operations-release-f06"></a>
<a id="ds-tx-declarations-requirements-operations-release-f06" name="ds-tx-declarations-requirements-operations-release-f06"></a>

**2.1.1.2.1.3.16 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L321) - A SubTx declaration cannot satisfy TopTx release presence**

> **A child's declaration cannot supply its releasing parent's field.**

TopTx and two to five SubTxs each consume a funded Store-backed output and create
an implicit settlement output. Each child declares its own release; TopTx declares
the combined release. Begin with this signed, otherwise valid control, then remove
only TopTx's declaration and re-sign.

$$
\begin{aligned}
&\text{releasedDeposits(topTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=0 \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}:\ \text{hasDeclaration(subTx)} \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\implies\text{RejectedWith(MissingUTxODepositDeclaration)}
\end{aligned}
$$

The failure must identify TopTx's **own release requirement**. The separate
SubTx-to-TopTx dependency may also fail, but `MissingTopTxUTxODepositDeclaration`
alone is insufficient here. Finally, submit the unchanged declared control and
require acceptance.

<a id="ds-tx-presence-operations-zero-net-change" name="ds-tx-presence-operations-zero-net-change"></a>
<a id="ds-tx-required-declarations-operations-zero-net-change" name="ds-tx-required-declarations-operations-zero-net-change"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change" name="ds-tx-declarations-requirements-operations-zero-net-change"></a>

**2.1.1.2.1.4 Zero net change**

> **Equal allocations and releases require an explicit zero declaration.**
>
> Zero net change does not mean that no Store operations occur.

These 14 properties cover six nominal cases and eight rejection cases. They
exercise a standalone TopTx, one or several SubTxs, a mixture of active and
inactive SubTxs, and a TopTx with Store operations alongside its children.
N06, F07 and F08 carry an actually failing TopTx Plutus V4 script and a
phase-2-invalid declaration; the other cases use the ordinary success path.
All unrelated ledger requirements are satisfied.

For each body, allocated deposits come from independently pricing its own
proposed outputs; released deposits come from its own consumed outputs' recorded
deposits in the actual UTxO. Every active body has equal positive amounts, while
an inactive body has zero allocation and release:

$$
\begin{aligned}
\forall\,\text{body}\in\text{activeBodies}:\quad
\text{allocatedDeposits(body)} &= \text{releasedDeposits(body)}>0 \\
\forall\,\text{body}\in\text{inactiveBodies}:\quad
\text{allocatedDeposits(body)} &= \text{releasedDeposits(body)}=0 \\
\text{activeSubTxs} &= \{\text{subTx}\in\text{subTxs}\mid\text{releasedDeposits(subTx)}>0\}
\end{aligned}
$$

Equality is checked independently for every active body. A zero batch total
alone is insufficient: every active body releases a positive deposit and
allocates the same amount itself. Inactive bodies consume and create only
implicit outputs. The active and inactive bodies partition TopTx and its actual
SubTx sequence. The active child set is determined from recorded deposits, not
from which children already have declarations.

**Illustrative deposit amounts:**

| Body | Released from consumed outputs | Allocated to new outputs | Net change | Required declaration |
| --- | ---: | ---: | ---: | --- |
| Standalone TopTx | 3 ₳ | 3 ₳ | 0 ₳ | `TopTx.DeclaresZeroNetUTxODeposit` |
| Active SubTx | 3 ₳ | 3 ₳ | 0 ₳ | `SubTx.DeclaresZeroNetUTxODeposit` |

These amounts illustrate the rule. Sources are created by real funding
transactions and looked up in the resulting UTxO. A replacement copies its
source `TxOut`, preserving the amount that is independently priced under the
unchanged deposit prices. Each child has one funded input and one replacement
output, including the implicit input/output pair of an inactive child. An
unrelated funded source remains outside the candidate transaction and does not
contribute to any body's release. Application ADA and fees are funded separately.

Every rejection variant starts from a fully prepared, signed control, removes
only the selected declaration and re-signs without running fixup. All other
declarations, inputs and outputs are retained, and the original control must be
accepted. The phase-2 cases retain their failing script, valid collateral and
invalidity declaration as well. These properties check acceptance and required
failures; they make no assertions about Store effects.

Explicit zero has no delegation, so these cases do not cover delegated nonzero
declarations. They also do not cover changing deposit prices or multiple inputs
per child. [Offsetting SubTx contributions](#ds-tx-declarations-requirements-subtx-declarations-c03)
separately checks one child's positive declaration cancelling another child's
negative declaration; neither child's own net change is zero in that case.

<a id="ds-tx-presence-operations-zero-net-change-n01" name="ds-tx-presence-operations-zero-net-change-n01"></a>
<a id="ds-tx-required-declarations-operations-zero-net-change-n01" name="ds-tx-required-declarations-operations-zero-net-change-n01"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n01" name="ds-tx-declarations-requirements-operations-zero-net-change-n01"></a>

**2.1.1.2.1.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L42) - Standalone TopTx, equal allocations and releases with explicit zero**

$$
\begin{aligned}
&\text{subTxs}=\varnothing \\
&\land\ \text{allocatedDeposits}=\text{releasedDeposits}>0 \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\implies\text{Accepted}
\end{aligned}
$$

Explicit zero describes the exact net change. The ledger accepts the transaction
even though both gross Store operations are nonzero.

<a id="ds-tx-presence-operations-zero-net-change-f01" name="ds-tx-presence-operations-zero-net-change-f01"></a>
<a id="ds-tx-required-declarations-operations-zero-net-change-f01" name="ds-tx-required-declarations-operations-zero-net-change-f01"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f01" name="ds-tx-declarations-requirements-operations-zero-net-change-f01"></a>

**2.1.1.2.1.4.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L53) - Standalone TopTx, equal allocations and releases without a declaration**

$$
\begin{aligned}
&\text{subTxs}=\varnothing \\
&\land\ \text{allocatedDeposits}=\text{releasedDeposits}>0 \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{MissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

Remove only the declaration from an otherwise valid explicit-zero transaction
and re-sign it. The ledger rejects the undeclared version; the original declared
control is accepted. The zero net amount cannot stand in for the required field.

This requirement comes from TopTx's **own operations**. N01 and F01 contain no
SubTxs. The following cases extend the same per-body requirement to batches;
[TopTx accounting](#ds-tx-accounting-net-change-toptx) checks the arithmetic of the total declaration.

<a id="ds-tx-required-declarations-operations-zero-net-change-n02" name="ds-tx-required-declarations-operations-zero-net-change-n02"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n02" name="ds-tx-declarations-requirements-operations-zero-net-change-n02"></a>

**2.1.1.2.1.4.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L72) - One SubTx replaces its deposit with explicit zero**

One SubTx consumes a funded store-backed output and proposes an identical
replacement. TopTx has no own Store operations. Both bodies explicitly declare
zero: the child acknowledges its own operations, and TopTx acknowledges the
child's declaration and the zero batch amount.

$$
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \text{declaration(subTx)}=\text{ExplicitZero} \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\implies\text{Accepted}
\end{aligned}
$$

<a id="ds-tx-required-declarations-operations-zero-net-change-f02" name="ds-tx-required-declarations-operations-zero-net-change-f02"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f02" name="ds-tx-declarations-requirements-operations-zero-net-change-f02"></a>

**2.1.1.2.1.4.4 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L83) - One active SubTx omits its declaration**

Remove only the child's declaration from N02's prepared transaction, retaining
TopTx's explicit zero. The child still proposes both gross operations.

$$
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \neg\text{hasDeclaration(subTx)} \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{SubMissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

TopTx's zero cannot satisfy the child's own requirement. After rejecting the
variant, submit the original control with both declarations; it must be accepted.

<a id="ds-tx-required-declarations-operations-zero-net-change-f03" name="ds-tx-required-declarations-operations-zero-net-change-f03"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f03" name="ds-tx-declarations-requirements-operations-zero-net-change-f03"></a>

**2.1.1.2.1.4.5 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L98) - TopTx omits the declaration required by its child**

Remove only TopTx's declaration from N02's prepared transaction. The child's
explicit zero remains present, and TopTx still has no Store operations of its own.

$$
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \text{declaration(subTx)}=\text{ExplicitZero} \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{MissingTopTxUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

The required failure identifies the parent declaration required by an explicit
SubTx declaration. The original control with both zeros must be accepted.

<a id="ds-tx-required-declarations-operations-zero-net-change-n03" name="ds-tx-required-declarations-operations-zero-net-change-n03"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n03" name="ds-tx-declarations-requirements-operations-zero-net-change-n03"></a>

**2.1.1.2.1.4.6 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L112) - Several SubTxs each replace their deposits**

Generate two to five SubTxs. Each consumes its own funded store-backed output
and proposes its own copied replacement, so each child's positive allocation
equals its own recorded release. TopTx has no own Store operations; all bodies
explicitly declare zero.

$$
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}: \\
&\qquad\text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{declaration(body)}=\text{ExplicitZero} \\
&\implies\text{Accepted}
\end{aligned}
$$

<a id="ds-tx-required-declarations-operations-zero-net-change-f04" name="ds-tx-required-declarations-operations-zero-net-change-f04"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f04" name="ds-tx-declarations-requirements-operations-zero-net-change-f04"></a>

**2.1.1.2.1.4.7 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L123) - One of several active SubTxs omits its declaration**

From N03's prepared transaction, remove each child's declaration in turn. Each
variant changes exactly one field; TopTx and every sibling retain explicit zero.
For every selected child $\text{omittedSubTx}\in\text{subTxs}$, submit a separate proposal:

$$
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}: \\
&\qquad\text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \neg\text{hasDeclaration(omittedSubTx)} \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}\setminus\{\text{omittedSubTx}\}: \\
&\qquad\text{declaration(subTx)}=\text{ExplicitZero} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{SubMissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

After every child position has been rejected, submit the original fully declared
control. It must be accepted.

<a id="ds-tx-required-declarations-operations-zero-net-change-n04" name="ds-tx-required-declarations-operations-zero-net-change-n04"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n04" name="ds-tx-declarations-requirements-operations-zero-net-change-n04"></a>

**2.1.1.2.1.4.8 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L138) - Only some SubTxs replace Store deposits**

Generate two to five SubTxs with a nonempty proper subset of active children,
varying their positions. Determine that subset from their inputs' recorded
deposits. Each active child replaces a positive Store deposit and declares zero.
Every remaining child consumes and replaces an implicit output, with zero
allocation and release and no declaration. TopTx has no own Store operations
and explicitly declares zero.

$$
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \varnothing\ne\text{activeSubTxs}\subsetneq\text{subTxs} \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \forall\,\text{subTx}\in\text{activeSubTxs}: \\
&\qquad\text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}\setminus\text{activeSubTxs}: \\
&\qquad\text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}=0 \\
&\qquad\land\ \neg\text{hasDeclaration(subTx)} \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\land\ \forall\,\text{subTx}\in\text{activeSubTxs}: \\
&\qquad\text{declaration(subTx)}=\text{ExplicitZero} \\
&\implies\text{Accepted}
\end{aligned}
$$

The active siblings impose no declaration requirement on an inactive child.

<a id="ds-tx-required-declarations-operations-zero-net-change-f05" name="ds-tx-required-declarations-operations-zero-net-change-f05"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f05" name="ds-tx-declarations-requirements-operations-zero-net-change-f05"></a>

**2.1.1.2.1.4.9 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L153) - One active SubTx omits its declaration among inactive siblings**

From N04's prepared transaction, remove each active child's declaration
separately. TopTx and the other active children retain zero; inactive siblings
keep their fields absent. For every selected active child $\text{omittedSubTx}\in\text{activeSubTxs}$:

$$
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \varnothing\ne\text{activeSubTxs}\subsetneq\text{subTxs} \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \forall\,\text{subTx}\in\text{activeSubTxs}: \\
&\qquad\text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}\setminus\text{activeSubTxs}: \\
&\qquad\text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}=0 \\
&\qquad\land\ \neg\text{hasDeclaration(subTx)} \\
&\land\ \neg\text{hasDeclaration(omittedSubTx)} \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\land\ \forall\,\text{subTx}\in\text{activeSubTxs}\setminus\{\text{omittedSubTx}\}: \\
&\qquad\text{declaration(subTx)}=\text{ExplicitZero} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{SubMissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

Only active positions are mutated. Once every such variant has been rejected,
the original control must be accepted with its inactive declarations still absent.

<a id="ds-tx-required-declarations-operations-zero-net-change-n05" name="ds-tx-required-declarations-operations-zero-net-change-n05"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n05" name="ds-tx-declarations-requirements-operations-zero-net-change-n05"></a>

**2.1.1.2.1.4.10 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L172) - TopTx and several SubTxs each replace their deposits**

TopTx and each of two to five children consume their own funded store-backed
source and propose a copied replacement. Every body independently has equal
positive allocations and releases. All declare explicit zero.

$$
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{allocatedDeposits(body)}=\text{releasedDeposits(body)}>0 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{declaration(body)}=\text{ExplicitZero} \\
&\implies\text{Accepted}
\end{aligned}
$$

TopTx's explicit zero satisfies both its own operations requirement and the
requirement arising from its children's declarations.

<a id="ds-tx-required-declarations-operations-zero-net-change-f06" name="ds-tx-required-declarations-operations-zero-net-change-f06"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f06" name="ds-tx-declarations-requirements-operations-zero-net-change-f06"></a>

**2.1.1.2.1.4.11 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L183) - Active TopTx omits its own declaration**

Remove only TopTx's declaration from N05's prepared transaction. Every child
retains its explicit zero, while TopTx still proposes its own positive gross
allocation and release.

$$
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{allocatedDeposits(body)}=\text{releasedDeposits(body)}>0 \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}: \\
&\qquad\text{declaration(subTx)}=\text{ExplicitZero} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{MissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

The required failure comes from TopTx's own Store operations. The child-to-parent
declaration rule may also fail, but that alone does not prove the own-operations
requirement. The original fully declared control must be accepted.

<a id="ds-tx-required-declarations-operations-zero-net-change-n06" name="ds-tx-required-declarations-operations-zero-net-change-n06"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n06" name="ds-tx-declarations-requirements-operations-zero-net-change-n06"></a>

**2.1.1.2.1.4.12 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L198) - Phase 2 fails with explicit zero at every active body**

Use N05's active TopTx and two to five active children, with explicit zero at
every body. Add an actually failing Plutus V4 script owned by TopTx, provide
proper collateral, and mark the transaction phase-2 invalid. The proposed
ordinary operations remain fully funded and satisfy the same per-body equality.

$$
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{allocatedDeposits(body)}=\text{releasedDeposits(body)}>0 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{declaration(body)}=\text{ExplicitZero} \\
&\land\ \text{phase1Valid} \\
&\land\ \text{declaredPhase2}=\text{Invalid} \\
&\land\ \text{phase2Result}=\text{Failed} \\
&\implies\text{Accepted}
\end{aligned}
$$

Acceptance exercises the phase-2 failure path with all declarations present.
Store effects belong to [Execution](#ds-state-execution).

<a id="ds-tx-required-declarations-operations-zero-net-change-f07" name="ds-tx-required-declarations-operations-zero-net-change-f07"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f07" name="ds-tx-declarations-requirements-operations-zero-net-change-f07"></a>

**2.1.1.2.1.4.13 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L210) - One SubTx declaration is missing in a phase-2-invalid proposal**

From N06's prepared transaction, remove each child's declaration in turn,
retaining TopTx's and every sibling's zero. Keep the failing V4 script,
collateral and phase-2-invalid declaration. For each selected child $\text{omittedSubTx}\in\text{subTxs}$:

$$
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{allocatedDeposits(body)}=\text{releasedDeposits(body)}>0 \\
&\land\ \text{topTxScript}=\text{AlwaysFailsV4} \\
&\land\ \text{declaredPhase2}=\text{Invalid} \\
&\land\ \neg\text{hasDeclaration(omittedSubTx)} \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}\setminus\{\text{omittedSubTx}\}: \\
&\qquad\text{declaration(subTx)}=\text{ExplicitZero} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{SubMissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

Every mutation must be rejected in phase 1; the failing script does not exempt
the child from declaring. The rejection does not require phase 2 to execute.
After testing every child, the original fully declared control must be accepted
on the phase-2 failure path.

<a id="ds-tx-required-declarations-operations-zero-net-change-f08" name="ds-tx-required-declarations-operations-zero-net-change-f08"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f08" name="ds-tx-declarations-requirements-operations-zero-net-change-f08"></a>

**2.1.1.2.1.4.14 [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L226) - TopTx's own declaration is missing in a phase-2-invalid proposal**

Remove only TopTx's declaration from N06's prepared transaction, retaining
every child's zero, the failing V4 script, collateral and invalidity declaration.

$$
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{allocatedDeposits(body)}=\text{releasedDeposits(body)}>0 \\
&\land\ \text{topTxScript}=\text{AlwaysFailsV4} \\
&\land\ \text{declaredPhase2}=\text{Invalid} \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}: \\
&\qquad\text{declaration(subTx)}=\text{ExplicitZero} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{MissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
$$

TopTx's own operations must produce `MissingUTxODepositDeclaration`, even if the
child-to-parent dependency also fails. The proposal is rejected in phase 1;
phase 2 need not execute. The original fully declared control must be accepted
on the phase-2 failure path.

<a id="ds-tx-presence-dependency" name="ds-tx-presence-dependency"></a>
<a id="ds-tx-presence-subtx-declarations" name="ds-tx-presence-subtx-declarations"></a>
<a id="ds-tx-required-declarations-subtx-declarations" name="ds-tx-required-declarations-subtx-declarations"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations" name="ds-tx-declarations-requirements-subtx-declarations"></a>

###### 2.1.1.2.2 SubTx declarations

> **A SubTx declaration requires a TopTx declaration.**
>
> Any explicit SubTx form, including zero, requires TopTx's field even without
> TopTx's own Store operations. The amount is checked separately.

**Decision:** Agreed.

**Executable spec:** [SubTxDeclarationsSpec.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs)

Categories, case identifiers and order match the executable spec. Short titles
introduce the cases; source links lead to their checks. Each linked test ID
completes its category tag: `N` for nominal cases, `F` for failures, and `P` for the
universal rule. Numbering restarts in each category.

**Reading the outcomes:** $\mathsf{TopTxRequirementSatisfied}$ and $\mathsf{MissingRequiredTopTxDeclaration}$ concern only
declaration presence. $\mathsf{Accepted}$ and $\mathsf{Rejected}$ describe submission
of the prepared transaction to the ledger. Exact amounts and Store accounting are
covered by DS-TX-ACCOUNTING-NET-CHANGE-TOPTX and DS-TX-ACCOUNTING-NET-CHANGE-SUBTX.

<a id="ds-tx-presence-dependency-c01" name="ds-tx-presence-dependency-c01"></a>
<a id="ds-tx-presence-subtx-declarations-c01" name="ds-tx-presence-subtx-declarations-c01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c01" name="ds-tx-required-declarations-subtx-declarations-c01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c01" name="ds-tx-declarations-requirements-subtx-declarations-c01"></a>

**2.1.1.2.2.1 TopTx requirement**

> **A declaring SubTx requires TopTx to declare.**
>
> SubTx declaration $\implies$ TopTx declaration; the converse is not required.

$\mathrm{hasDeclaration}(\mathit{body})$ means that the body explicitly declares
a UTxO capacity deposit change; $\mathrm{subTransactions}(\mathit{topTx})$ is its
sequence of SubTxs.

$$
\begin{aligned}
&\left(\exists \mathit{subTx}\in\mathrm{subTransactions}(\mathit{topTx}):
\mathrm{hasDeclaration}(\mathit{subTx})\right) \\
&\qquad\implies\mathrm{hasDeclaration}(\mathit{topTx})
\end{aligned}
$$

If every SubTx omits its declaration, DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS imposes no requirement on TopTx.
DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS may still require a declaration for TopTx's own Store operations.

<a id="ds-tx-presence-dependency-c01-p01" name="ds-tx-presence-dependency-c01-p01"></a>
<a id="ds-tx-presence-subtx-declarations-c01-p01" name="ds-tx-presence-subtx-declarations-c01-p01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c01-p01" name="ds-tx-required-declarations-subtx-declarations-c01-p01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c01-p01" name="ds-tx-declarations-requirements-subtx-declarations-c01-p01"></a>

**2.1.1.2.2.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L61) - SubTx declarations require TopTx's declaration**

Let $\mathrm{missingRequiredTopTxDeclaration}(\mathit{topTx})$ mean that the isolated validator
reports `MissingTopTxDeclaration`.

$$
\begin{aligned}
\mathrm{missingRequiredTopTxDeclaration}(\mathit{topTx})
\iff\bigl(&\neg\mathrm{hasDeclaration}(\mathit{topTx}) \\
&\land\exists \mathit{subTx}\in\mathrm{subTransactions}(\mathit{topTx}): \\
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

<a id="ds-tx-presence-dependency-c02" name="ds-tx-presence-dependency-c02"></a>
<a id="ds-tx-presence-subtx-declarations-c02" name="ds-tx-presence-subtx-declarations-c02"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c02" name="ds-tx-required-declarations-subtx-declarations-c02"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c02" name="ds-tx-declarations-requirements-subtx-declarations-c02"></a>

**2.1.1.2.2.2 Absence and explicit zero**

> **Distinguish saying nothing from declaring zero.**
>
> Absent $\ne$ Explicit zero. A SubTx's explicit zero requires TopTx to declare; absence alone does not.

**Situation:** TopTx and its single SubTx consume and create only implicit-deposit
outputs. There is no Store allocation or release. Each case submits a funded,
phase-2-valid transaction whose other ledger requirements are satisfied.

| TopTx declaration ↓ / SubTx declaration → | Absent | Explicit zero |
| --- | --- | --- |
| **Absent** | ✓ Accepted · N01 | ✗ Rejected · F01 |
| **Explicit zero** | ✓ Accepted · N03 | ✓ Accepted · N02 |

$\mathsf{Absent}$ means no declaration; $\mathsf{ExplicitZero}$ acknowledges a zero net
change. An explicit-zero SubTx still requires TopTx's declaration:

$$
\mathrm{declaresZero}(\mathit{body})
\implies\mathrm{hasDeclaration}(\mathit{body})
$$

<a id="ds-tx-presence-dependency-c02-n01" name="ds-tx-presence-dependency-c02-n01"></a>
<a id="ds-tx-presence-subtx-declarations-c02-n01" name="ds-tx-presence-subtx-declarations-c02-n01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c02-n01" name="ds-tx-required-declarations-subtx-declarations-c02-n01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c02-n01" name="ds-tx-declarations-requirements-subtx-declarations-c02-n01"></a>

**2.1.1.2.2.2.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L66) - accepts absent declarations at both levels**

$$
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\rbrace
\implies \mathsf{Accepted}
$$

**Why:** With no Store operations and no SubTx declaration, neither body needs to declare.

<a id="ds-tx-presence-dependency-c02-n02" name="ds-tx-presence-dependency-c02-n02"></a>
<a id="ds-tx-presence-subtx-declarations-c02-n02" name="ds-tx-presence-subtx-declarations-c02-n02"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c02-n02" name="ds-tx-required-declarations-subtx-declarations-c02-n02"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c02-n02" name="ds-tx-declarations-requirements-subtx-declarations-c02-n02"></a>

**2.1.1.2.2.2.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L70) - accepts explicit zero at both levels**

$$
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies \mathsf{Accepted}
$$

**Why:** The SubTx explicitly declares zero, and TopTx supplies the declaration it requires.

<a id="ds-tx-presence-dependency-c02-n03" name="ds-tx-presence-dependency-c02-n03"></a>
<a id="ds-tx-presence-subtx-declarations-c02-n03" name="ds-tx-presence-subtx-declarations-c02-n03"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c02-n03" name="ds-tx-required-declarations-subtx-declarations-c02-n03"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c02-n03" name="ds-tx-declarations-requirements-subtx-declarations-c02-n03"></a>

**2.1.1.2.2.2.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L74) - accepts TopTx zero without a SubTx declaration**

$$
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero} \\
\mathit{subTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\rbrace
\implies \mathsf{Accepted}
$$

**Why:** TopTx may declare independently; its declaration creates no obligation for the SubTx.

<a id="ds-tx-presence-dependency-c02-f01" name="ds-tx-presence-dependency-c02-f01"></a>
<a id="ds-tx-presence-subtx-declarations-c02-f01" name="ds-tx-presence-subtx-declarations-c02-f01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c02-f01" name="ds-tx-required-declarations-subtx-declarations-c02-f01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c02-f01" name="ds-tx-declarations-requirements-subtx-declarations-c02-f01"></a>

**2.1.1.2.2.2.4 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L78) - rejects SubTx zero without a TopTx declaration**

$$
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies \mathsf{Rejected}
$$

**Why:** Explicit zero is still a declaration, so the SubTx requires TopTx to declare.

**Expected failure:** `MissingTopTxUTxODepositDeclaration`.

**State invariant:**

$$
\mathit{ledgerStateAfterRejectedSubmit}=\mathit{ledgerStateBeforeSubmit}
$$

The comparison starts immediately before submission, after funding and preparation.

<a id="ds-tx-presence-dependency-c03" name="ds-tx-presence-dependency-c03"></a>
<a id="ds-tx-presence-subtx-declarations-c03" name="ds-tx-presence-subtx-declarations-c03"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c03" name="ds-tx-required-declarations-subtx-declarations-c03"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c03" name="ds-tx-declarations-requirements-subtx-declarations-c03"></a>

**2.1.1.2.2.3 Offsetting SubTx contributions**

> **Preserve declaration responsibility when amounts cancel.**
>
> Two SubTx contributions $+\text{amount}$ and $-\text{amount}$ sum to zero; both declarations still
> require TopTx to declare.

**Situation:** Two SubTxs declare local operations using the same generated strictly
positive amount: one declares an allocation, the other declares a release to output
index zero. Their declared contributions cancel; TopTx has no contribution of its
own. The requirement comes from **two explicit SubTx declarations**.
[Zero net change](#ds-tx-declarations-requirements-operations-zero-net-change) instead exercises a
TopTx or SubTx whose own gross allocations and releases are equal and positive,
including batches where every active body independently has zero net change.

$$
\begin{aligned}
&\sum_{\mathit{subTx}\in\mathrm{subTransactions}(\mathit{topTx})}
\mathrm{declaredSubTxNetUTxODepositChange}(\mathit{subTx}) \\
&\qquad=\mathit{declaredAmount}-\mathit{declaredAmount}=0
\end{aligned}
$$

These properties validate declarations directly. They do not fund operations, construct
a settlement output or exercise a Store transfer. In the formulas below,
$\mathit{declaredAmount}\in\mathsf{StrictlyPositiveCoin}$.

<a id="ds-tx-presence-dependency-c03-n01" name="ds-tx-presence-dependency-c03-n01"></a>
<a id="ds-tx-presence-subtx-declarations-c03-n01" name="ds-tx-presence-subtx-declarations-c03-n01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c03-n01" name="ds-tx-required-declarations-subtx-declarations-c03-n01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c03-n01" name="ds-tx-declarations-requirements-subtx-declarations-c03-n01"></a>

**2.1.1.2.2.3.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L86) - passes declaration presence with TopTx declaring the zero net amount**

$$
\begin{gathered}
\forall \mathit{declaredAmount}\in\mathsf{StrictlyPositiveCoin}: \\
\left.
\begin{aligned}
\mathit{declaredAllocation} &= \mathit{declaredAmount} \\
\mathit{declaredRelease} &= \mathit{declaredAmount} \\
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies\mathsf{TopTxRequirementSatisfied}
\end{gathered}
$$

**Why:** A zero net amount can be acknowledged explicitly. TopTx's zero declaration fulfils the
presence requirement for the two declaring SubTxs.

<a id="ds-tx-presence-dependency-c03-f01" name="ds-tx-presence-dependency-c03-f01"></a>
<a id="ds-tx-presence-subtx-declarations-c03-f01" name="ds-tx-presence-subtx-declarations-c03-f01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c03-f01" name="ds-tx-required-declarations-subtx-declarations-c03-f01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c03-f01" name="ds-tx-declarations-requirements-subtx-declarations-c03-f01"></a>

**2.1.1.2.2.3.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L89) - rejects an absent TopTx declaration despite the zero net amount**

$$
\begin{gathered}
\forall \mathit{declaredAmount}\in\mathsf{StrictlyPositiveCoin}: \\
\left.
\begin{aligned}
\mathit{declaredAllocation} &= \mathit{declaredAmount} \\
\mathit{declaredRelease} &= \mathit{declaredAmount} \\
\mathit{topTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\rbrace
\implies\mathsf{MissingRequiredTopTxDeclaration}
\end{gathered}
$$

**Why:** The amounts cancel, but the two declarations still exist. Their zero sum cannot
replace TopTx's explicit declaration.

**Expected failure:** `MissingTopTxDeclaration` from the isolated validator.

<a id="ds-tx-presence-dependency-c04" name="ds-tx-presence-dependency-c04"></a>
<a id="ds-tx-presence-subtx-declarations-c04" name="ds-tx-presence-subtx-declarations-c04"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c04" name="ds-tx-required-declarations-subtx-declarations-c04"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c04" name="ds-tx-declarations-requirements-subtx-declarations-c04"></a>

**2.1.1.2.2.4 Local and delegated accounting**

> **Every explicit SubTx form requires TopTx's declaration.**
>
> Local or delegated accounting $\implies$ the same TopTx declaration requirement.

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

<a id="ds-tx-presence-dependency-c04-n01" name="ds-tx-presence-dependency-c04-n01"></a>
<a id="ds-tx-presence-subtx-declarations-c04-n01" name="ds-tx-presence-subtx-declarations-c04-n01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c04-n01" name="ds-tx-required-declarations-subtx-declarations-c04-n01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c04-n01" name="ds-tx-declarations-requirements-subtx-declarations-c04-n01"></a>

**2.1.1.2.2.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L94) - passes declaration presence with TopTx zero for every explicit SubTx form**

$$
\begin{gathered}
\forall \mathit{subTxDeclaration}\in\mathit{explicitSubTxDeclarations}: \\
\left.
\begin{aligned}
\mathit{subTxDeclarations} &= [\mathit{subTxDeclaration}] \\
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies\mathsf{TopTxRequirementSatisfied}
\end{gathered}
$$

**Why:** Every explicit SubTx form finds the TopTx declaration it requires, regardless of where
the operation is accounted for.

<a id="ds-tx-presence-dependency-c04-f01" name="ds-tx-presence-dependency-c04-f01"></a>
<a id="ds-tx-presence-subtx-declarations-c04-f01" name="ds-tx-presence-subtx-declarations-c04-f01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c04-f01" name="ds-tx-required-declarations-subtx-declarations-c04-f01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c04-f01" name="ds-tx-declarations-requirements-subtx-declarations-c04-f01"></a>

**2.1.1.2.2.4.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L100) - rejects an absent TopTx declaration for every explicit SubTx form**

$$
\begin{gathered}
\forall \mathit{subTxDeclaration}\in\mathit{explicitSubTxDeclarations}: \\
\left.
\begin{aligned}
\mathit{subTxDeclarations} &= [\mathit{subTxDeclaration}] \\
\mathit{topTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\rbrace
\implies\mathsf{MissingRequiredTopTxDeclaration}
\end{gathered}
$$

**Why:** Neither local accounting nor delegation removes TopTx's declaration requirement. Every explicit form,
including zero, requires TopTx to declare.

**Expected failure:** `MissingTopTxDeclaration` for each individually checked form.

<a id="ds-tx-presence-dependency-c05" name="ds-tx-presence-dependency-c05"></a>
<a id="ds-tx-presence-subtx-declarations-c05" name="ds-tx-presence-subtx-declarations-c05"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c05" name="ds-tx-required-declarations-subtx-declarations-c05"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c05" name="ds-tx-declarations-requirements-subtx-declarations-c05"></a>

**2.1.1.2.2.5 Phase-2 failure**

> **TopTx's declaration is still required when phase 2 fails.**
>
> Failing scripts do not waive the TopTx declaration required by a SubTx.

**Situation:** The prepared transaction is marked phase-2 invalid and contains an
actual failing script plus collateral. Its single SubTx declares zero; neither body
has Store operations. Funding and preparation satisfy the other ledger requirements.

The cases submit the transaction to the ledger. They check TopTx's required declaration on
the failure path, without independently checking collateral arithmetic or requiring
script evaluation to precede declaration rejection.

<a id="ds-tx-presence-dependency-c05-n01" name="ds-tx-presence-dependency-c05-n01"></a>
<a id="ds-tx-presence-subtx-declarations-c05-n01" name="ds-tx-presence-subtx-declarations-c05-n01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c05-n01" name="ds-tx-required-declarations-subtx-declarations-c05-n01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c05-n01" name="ds-tx-declarations-requirements-subtx-declarations-c05-n01"></a>

**2.1.1.2.2.5.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L109) - accepts zero declarations at both levels on the phase-2 failure path**

$$
\left.
\begin{aligned}
\mathit{phase2Status} &= \mathsf{Invalid} \\
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies \mathsf{Accepted}
$$

**Why:** TopTx supplies the declaration required by its SubTx. The prepared transaction is accepted
on the phase-2 failure path, even though its script fails.

<a id="ds-tx-presence-dependency-c05-f01" name="ds-tx-presence-dependency-c05-f01"></a>
<a id="ds-tx-presence-subtx-declarations-c05-f01" name="ds-tx-presence-subtx-declarations-c05-f01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c05-f01" name="ds-tx-required-declarations-subtx-declarations-c05-f01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c05-f01" name="ds-tx-declarations-requirements-subtx-declarations-c05-f01"></a>

**2.1.1.2.2.5.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L113) - rejects SubTx zero without a TopTx declaration on the phase-2 failure path**

$$
\left.
\begin{aligned}
\mathit{phase2Status} &= \mathsf{Invalid} \\
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
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

<a id="ds-tx-accounting" name="ds-tx-accounting"></a>

#### 2.1.2 Accounting

> **Declare the exact Store transfer; fund the complete transaction.**

| Responsibility | Question | Phase-2 scope |
| --- | --- | --- |
| [Net change](#ds-tx-accounting-net-change) | Does each declaration state the required deposit change? | Valid or invalid |
| [Balance](#ds-tx-accounting-balance) | Do consumed and produced values balance, counting the Store transfer once? | Valid only |

An exact declaration identifies the Store transfer. The complete transaction must
also fund that transfer when its ordinary effects apply. Neither requirement
forces each SubTx to balance independently.

<a id="ds-tx-exactness" name="ds-tx-exactness"></a>
<a id="ds-tx-accounting-net-change" name="ds-tx-accounting-net-change"></a>

##### 2.1.2.1 Net change

> **Each declaration must describe the right amount for its scope.**

| Declaration | Amount it describes |
| --- | --- |
| **SubTx** | The change from that SubTx's own inputs and outputs. |
| **TopTx** | The complete transaction's change: its own plus every SubTx's. |

$$
\begin{aligned}
\mathrm{ownNetDeposit}(\mathit{body})
&=\mathrm{allocatedDeposits}(\mathit{body})-\mathrm{releasedDeposits}(\mathit{body}) \\
\mathrm{transactionNetDeposit}(\mathit{topTx})
&=\mathrm{ownNetDeposit}(\mathit{topTx}) \\
&\quad+\sum_{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx})}
\mathrm{ownNetDeposit}(\mathit{subTx})
\end{aligned}
$$

| Notation | Meaning |
| --- | --- |
| $\mathrm{allocatedDeposits}(\mathit{body})$ | [Price](#ds-pricing) the body's newly created store-backed outputs. |
| $\mathrm{releasedDeposits}(\mathit{body})$ | Read the recorded deposits of its consumed store-backed inputs. |
| $\mathrm{declaredNetDeposit}(\mathit{body})$ | The **signed** declared value: allocation $>0$, release $<0$, explicit zero $=0$. Absence has no declared value. |
| $1$ in amount comparisons | One lovelace. Example values labelled ADA are converted to lovelace. |

These short names refer to the same amounts as `requiredNetUTxODepositChange(body)`
and `requiredTxTotalNetUTxODepositChange` in the domain model. Derive them independently
of declarations. Reference inputs and collateral do not enter this ordinary calculation.

**Example, in ADA:**

| Body | Required own change | Required declaration |
| --- | ---: | ---: |
| TopTx | $+1$ | $+2$ — the transaction total |
| SubTx A | $+3$ | $+3$ |
| SubTx B | $-2$ | $-2$ |

$$
\mathrm{transactionNetDeposit}(\mathit{topTx})=1+3-2=2
$$

- With TopTx's own $+1$, SubTx declarations of $+4$ and $-3$ still produce the total $+2$, but **both SubTx amounts are wrong**.
- SubTx declarations of $+3$ and $-2$ are exact, but a TopTx declaration of $+5$ gives **the wrong transaction total**.

The sets used below are:

$$
\begin{aligned}
\mathrm{bodies}(\mathit{topTx})
&=\{\mathit{topTx}\}\cup\mathrm{subTxs}(\mathit{topTx}) \\
\mathrm{declaredSubTxs}(\mathit{topTx})
&=\{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx}):\mathrm{hasDeclaration}(\mathit{subTx})\}
\end{aligned}
$$

After Requirements, an undeclared SubTx has no Store operations and contributes
zero to the required total. It contributes no declared value to a sum of declarations.

**Reading the contracts.** Requirements, valid grammar and resolved inputs
are assumed. Accepted controls satisfy the other transaction rules. Rejection must
include the targeted exactness failure; a [Balance](#ds-tx-accounting-balance) failure alone is insufficient.
The same required ordinary amounts apply on both phase-2 outcomes; [Execution](#ds-state-execution)
selects the effects actually applied. Historical pricing changes remain deferred under
DS-PRICING-HISTORY.

<a id="ds-tx-exactness-contribution" name="ds-tx-exactness-contribution"></a>
<a id="ds-tx-exactness-subtx" name="ds-tx-exactness-subtx"></a>
<a id="ds-tx-accounting-subtx" name="ds-tx-accounting-subtx"></a>
<a id="ds-tx-accounting-net-change-subtx" name="ds-tx-accounting-net-change-subtx"></a>

###### 2.1.2.1.1 SubTx

> **Each SubTx declares its exact own change.**

$$
\mathrm{declaredNetDeposit}(\mathit{subTx})=\mathrm{ownNetDeposit}(\mathit{subTx})
$$

Keep TopTx's declaration equal to the independently required transaction total.
All other SubTx declarations remain exact; F05 deliberately changes two.
SubTx variables range over $\mathrm{declaredSubTxs}(\mathit{topTx})$;
$\mathit{otherBody}$ belongs to $\mathrm{bodies}(\mathit{topTx})$.
Delegating an allocation or release changes its accounting responsibility, while the
SubTx still declares its exact originating amount.

| SubTx declaration | Signed declared own change |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | $0$ |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | $+\mathit{amount}$ |
| `SubTx.RequestsUTxODepositFromTopTx amount` | $+\mathit{amount}$ |
| `SubTx.DeclaresNetUTxODepositRelease amount target` | $-\mathit{amount}$, for either target |

Explicit zero is valid only for a zero own change. Excess allocations, releases from
unrelated Store surplus and opposing declaration errors fail SubTx exactness even
when the transaction total is correct.

**Additional notation used by these cases:**

$$
\mathrm{declarationError}(\mathit{subTx})
=\mathrm{declaredNetDeposit}(\mathit{subTx})-\mathrm{ownNetDeposit}(\mathit{subTx})
$$

| Predicate or value | Meaning |
| --- | --- |
| $\mathrm{delegatesAllocation}(\mathit{subTx})$ | The declaration is `RequestsUTxODepositFromTopTx`. |
| $\mathrm{delegatesRelease}(\mathit{subTx})$ | The release target is `DelegateToTopTx`. |
| $\mathit{translatedImplicitInput}$ | A live input referencing an implicit output translated from the preceding era. |
| $\mathit{storeSurplus}$ | Store balance above the sum of its recorded allocations. |

For F01–F04, both the original and changed magnitudes remain representable. Positive
allocation amounts and release magnitudes are checked by Grammar; these cases test
exactness within that valid range.

<a id="ds-tx-exactness-contribution-p01" name="ds-tx-exactness-contribution-p01"></a>
<a id="ds-tx-exactness-subtx-p01" name="ds-tx-exactness-subtx-p01"></a>
<a id="ds-tx-accounting-subtx-p01" name="ds-tx-accounting-subtx-p01"></a>
<a id="ds-tx-accounting-net-change-subtx-p01" name="ds-tx-accounting-net-change-subtx-p01"></a>

**2.1.2.1.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L87) - Each SubTx declares its own exact change**

$$
\begin{aligned}
&\mathrm{subTxNetChangeValid}\iff \\
&\forall\,\mathit{subTx}\in\mathrm{declaredSubTxs}(\mathit{topTx}): \\
&\qquad\mathrm{declaredNetDeposit}(\mathit{subTx})=\mathrm{ownNetDeposit}(\mathit{subTx})
\end{aligned}
$$

Compare the isolated SubTx exactness result with independent input records and output prices; include exact and inexact declarations.

<a id="ds-tx-exactness-contribution-n01" name="ds-tx-exactness-contribution-n01"></a>
<a id="ds-tx-exactness-subtx-n01" name="ds-tx-exactness-subtx-n01"></a>
<a id="ds-tx-accounting-subtx-n01" name="ds-tx-accounting-subtx-n01"></a>
<a id="ds-tx-accounting-net-change-subtx-n01" name="ds-tx-accounting-net-change-subtx-n01"></a>

**2.1.2.1.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L123) - Exact own change, with any allocation and release combination**

$$
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{allocatedDeposits}(\mathit{subTx}) - \mathrm{releasedDeposits}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
$$

Exercise positive allocation, negative release and explicit zero with local accounting; N03/N04 cover the delegated forms.

<a id="ds-tx-exactness-contribution-f01" name="ds-tx-exactness-contribution-f01"></a>
<a id="ds-tx-exactness-subtx-f01" name="ds-tx-exactness-subtx-f01"></a>
<a id="ds-tx-accounting-subtx-f01" name="ds-tx-accounting-subtx-f01"></a>
<a id="ds-tx-accounting-net-change-subtx-f01" name="ds-tx-accounting-net-change-subtx-f01"></a>

**2.1.2.1.1.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L145) - Net allocation understated by one lovelace**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 1 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

The required allocation exceeds one lovelace so the mutated declaration remains a positive allocation.

<a id="ds-tx-exactness-contribution-f02" name="ds-tx-exactness-contribution-f02"></a>
<a id="ds-tx-exactness-subtx-f02" name="ds-tx-exactness-subtx-f02"></a>
<a id="ds-tx-accounting-subtx-f02" name="ds-tx-accounting-subtx-f02"></a>
<a id="ds-tx-accounting-net-change-subtx-f02" name="ds-tx-accounting-net-change-subtx-f02"></a>

**2.1.2.1.1.4 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L163) - Net allocation overstated by one lovelace**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) + 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

Keep the increased amount representable; this checks exactness rather than decoder overflow.

<a id="ds-tx-exactness-contribution-f03" name="ds-tx-exactness-contribution-f03"></a>
<a id="ds-tx-exactness-subtx-f03" name="ds-tx-exactness-subtx-f03"></a>
<a id="ds-tx-accounting-subtx-f03" name="ds-tx-accounting-subtx-f03"></a>
<a id="ds-tx-accounting-net-change-subtx-f03" name="ds-tx-accounting-net-change-subtx-f03"></a>

**2.1.2.1.1.5 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L181) - Net release understated by one lovelace**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < -1 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) + 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

Reducing the positive release magnitude increases its signed declaration; the required release exceeds one lovelace.

<a id="ds-tx-exactness-contribution-f04" name="ds-tx-exactness-contribution-f04"></a>
<a id="ds-tx-exactness-subtx-f04" name="ds-tx-exactness-subtx-f04"></a>
<a id="ds-tx-accounting-subtx-f04" name="ds-tx-accounting-subtx-f04"></a>
<a id="ds-tx-accounting-net-change-subtx-f04" name="ds-tx-accounting-net-change-subtx-f04"></a>

**2.1.2.1.1.6 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L199) - Net release overstated by one lovelace**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

Increasing the positive release magnitude decreases its signed declaration; keep the magnitude representable.

<a id="ds-tx-exactness-contribution-f05" name="ds-tx-exactness-contribution-f05"></a>
<a id="ds-tx-exactness-subtx-f05" name="ds-tx-exactness-subtx-f05"></a>
<a id="ds-tx-accounting-subtx-f05" name="ds-tx-accounting-subtx-f05"></a>
<a id="ds-tx-accounting-net-change-subtx-f05" name="ds-tx-accounting-net-change-subtx-f05"></a>

**2.1.2.1.1.7 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L217) - Opposing SubTx errors cancel in the total**

$$
\begin{aligned}
&\mathit{firstSubTx} \ne \mathit{secondSubTx} \\
&\land \mathrm{declarationError}(\mathit{firstSubTx}) = -\mathrm{declarationError}(\mathit{secondSubTx}) \ne 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

Both distinct SubTxs are in the transaction. Their errors cancel, but require a SubTx exactness failure.

<a id="ds-tx-exactness-contribution-n03" name="ds-tx-exactness-contribution-n03"></a>
<a id="ds-tx-exactness-subtx-n02" name="ds-tx-exactness-subtx-n02"></a>
<a id="ds-tx-accounting-subtx-n02" name="ds-tx-accounting-subtx-n02"></a>
<a id="ds-tx-accounting-net-change-subtx-n02" name="ds-tx-accounting-net-change-subtx-n02"></a>

**2.1.2.1.1.8 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L236) - Equal own allocations and releases, explicit zero**

$$
\begin{aligned}
&\mathrm{allocatedDeposits}(\mathit{subTx}) = \mathrm{releasedDeposits}(\mathit{subTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
$$

Use an explicit-zero declaration, including both zero operations and nonzero allocations equal to releases.

<a id="ds-tx-exactness-contribution-f06" name="ds-tx-exactness-contribution-f06"></a>
<a id="ds-tx-exactness-subtx-f06" name="ds-tx-exactness-subtx-f06"></a>
<a id="ds-tx-accounting-subtx-f06" name="ds-tx-accounting-subtx-f06"></a>
<a id="ds-tx-accounting-net-change-subtx-f06" name="ds-tx-accounting-net-change-subtx-f06"></a>

**2.1.2.1.1.9 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L245) - Explicit zero cannot replace a required allocation**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

The field is present as explicit zero; its amount is incorrect.

<a id="ds-tx-exactness-contribution-n04" name="ds-tx-exactness-contribution-n04"></a>
<a id="ds-tx-exactness-subtx-n03" name="ds-tx-exactness-subtx-n03"></a>
<a id="ds-tx-accounting-subtx-n03" name="ds-tx-accounting-subtx-n03"></a>
<a id="ds-tx-accounting-net-change-subtx-n03" name="ds-tx-accounting-net-change-subtx-n03"></a>

**2.1.2.1.1.10 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L263) - Exact allocation requested from TopTx**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{delegatesAllocation}(\mathit{subTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
$$

`RequestsUTxODepositFromTopTx` carries the requesting SubTx own net allocation, while TopTx declares the transaction total.

<a id="ds-tx-exactness-contribution-n05" name="ds-tx-exactness-contribution-n05"></a>
<a id="ds-tx-exactness-subtx-n04" name="ds-tx-exactness-subtx-n04"></a>
<a id="ds-tx-accounting-subtx-n04" name="ds-tx-accounting-subtx-n04"></a>
<a id="ds-tx-accounting-net-change-subtx-n04" name="ds-tx-accounting-net-change-subtx-n04"></a>

**2.1.2.1.1.11 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L275) - Exact release delegated to TopTx**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{delegatesRelease}(\mathit{subTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
$$

The release targets `DelegateToTopTx`; its magnitude remains exactly the originating SubTx own net release.

<a id="ds-tx-exactness-contribution-n06" name="ds-tx-exactness-contribution-n06"></a>
<a id="ds-tx-exactness-subtx-n05" name="ds-tx-exactness-subtx-n05"></a>
<a id="ds-tx-accounting-subtx-n05" name="ds-tx-accounting-subtx-n05"></a>
<a id="ds-tx-accounting-net-change-subtx-n05" name="ds-tx-accounting-net-change-subtx-n05"></a>

**2.1.2.1.1.12 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L287) - Released deposits, only implicit outputs**

$$
\begin{aligned}
&\mathrm{releasedDeposits}(\mathit{subTx}) > 0 \\
&\land \mathrm{storeBackedOutputs}(\mathit{subTx}) = \varnothing \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = -\mathrm{releasedDeposits}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
$$

Implicit outputs require no new Store allocation, so the declaration releases the complete recorded input deposit.

<a id="ds-tx-exactness-contribution-f07" name="ds-tx-exactness-contribution-f07"></a>
<a id="ds-tx-exactness-subtx-f07" name="ds-tx-exactness-subtx-f07"></a>
<a id="ds-tx-accounting-subtx-f07" name="ds-tx-accounting-subtx-f07"></a>
<a id="ds-tx-accounting-net-change-subtx-f07" name="ds-tx-accounting-net-change-subtx-f07"></a>

**2.1.2.1.1.13 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L299) - Explicit zero cannot replace a required release**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

The field is present as explicit zero; a negative own change still requires a release declaration.

<a id="ds-tx-exactness-contribution-n07" name="ds-tx-exactness-contribution-n07"></a>
<a id="ds-tx-exactness-subtx-n06" name="ds-tx-exactness-subtx-n06"></a>
<a id="ds-tx-accounting-subtx-n06" name="ds-tx-accounting-subtx-n06"></a>
<a id="ds-tx-accounting-net-change-subtx-n06" name="ds-tx-accounting-net-change-subtx-n06"></a>

**2.1.2.1.1.14 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L317) - Another body offsets the SubTx release**

$$
\begin{aligned}
&\mathit{otherBody} \ne \mathit{subTx} \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) < 0 < \mathrm{ownNetDeposit}(\mathit{otherBody}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
$$

The other body is TopTx or another SubTx. Cover partial, equal and greater offsets; none changes this SubTx own release.

<a id="ds-tx-exactness-contribution-n08" name="ds-tx-exactness-contribution-n08"></a>
<a id="ds-tx-exactness-subtx-n07" name="ds-tx-exactness-subtx-n07"></a>
<a id="ds-tx-accounting-subtx-n07" name="ds-tx-accounting-subtx-n07"></a>
<a id="ds-tx-accounting-net-change-subtx-n07" name="ds-tx-accounting-net-change-subtx-n07"></a>

**2.1.2.1.1.15 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L339) - An output without application assets still requires a deposit**

$$
\begin{aligned}
&\mathrm{storeBackedOutputs}(\mathit{subTx}) = \{\mathit{output}\} \\
&\land \mathrm{applicationAssets}(\mathit{output}) = \varnothing \\
&\land \mathrm{releasedDeposits}(\mathit{subTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{allocatedDeposits}(\mathit{subTx}) > 0 \\
&\implies \mathrm{accepted}
\end{aligned}
$$

The output still has an address and encoding overhead. Use positive pricing and declare the exact allocation.

<a id="ds-tx-exactness-contribution-n09" name="ds-tx-exactness-contribution-n09"></a>
<a id="ds-tx-exactness-subtx-n08" name="ds-tx-exactness-subtx-n08"></a>
<a id="ds-tx-accounting-subtx-n08" name="ds-tx-accounting-subtx-n08"></a>
<a id="ds-tx-accounting-net-change-subtx-n08" name="ds-tx-accounting-net-change-subtx-n08"></a>

**2.1.2.1.1.16 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L351) - A translated implicit input funds an exact allocation**

$$
\begin{aligned}
&\mathrm{ordinaryInputs}(\mathit{subTx}) = \{\mathit{translatedImplicitInput}\} \\
&\land \mathrm{storeBackedOutputs}(\mathit{subTx}) \ne \varnothing \\
&\land \mathrm{releasedDeposits}(\mathit{subTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{allocatedDeposits}(\mathit{subTx}) > 0 \\
&\implies \mathrm{accepted}
\end{aligned}
$$

The live input was translated from the previous era into an implicit output. Its coins fund new Store obligations, but it releases no Store deposit.

<a id="ds-tx-exactness-contribution-f08" name="ds-tx-exactness-contribution-f08"></a>
<a id="ds-tx-exactness-subtx-f08" name="ds-tx-exactness-subtx-f08"></a>
<a id="ds-tx-accounting-subtx-f08" name="ds-tx-accounting-subtx-f08"></a>
<a id="ds-tx-accounting-net-change-subtx-f08" name="ds-tx-accounting-net-change-subtx-f08"></a>

**2.1.2.1.1.17 [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L363) - A translated implicit input does not excuse an inexact allocation**

$$
\begin{aligned}
&\mathrm{ordinaryInputs}(\mathit{subTx}) = \{\mathit{translatedImplicitInput}\} \\
&\land \mathrm{storeBackedOutputs}(\mathit{subTx}) \ne \varnothing \\
&\land \mathrm{releasedDeposits}(\mathit{subTx}) = 0 \\
&\land \mathrm{allocatedDeposits}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) \ne \mathrm{allocatedDeposits}(\mathit{subTx}) \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

Use the N08 allocation scenario, changing only the positive SubTx declaration to a different representable amount.

<a id="ds-tx-exactness-contribution-f09" name="ds-tx-exactness-contribution-f09"></a>
<a id="ds-tx-exactness-subtx-f09" name="ds-tx-exactness-subtx-f09"></a>
<a id="ds-tx-accounting-subtx-f09" name="ds-tx-accounting-subtx-f09"></a>
<a id="ds-tx-accounting-net-change-subtx-f09" name="ds-tx-accounting-net-change-subtx-f09"></a>

**2.1.2.1.1.18 [F09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L381) - Store surplus cannot increase a SubTx release**

$$
\begin{aligned}
&0 < \mathit{unrelatedRelease} \le \mathit{storeSurplus} \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) \le 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - \mathit{unrelatedRelease} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

An additional release within the existing Store surplus can preserve solvency; it is still not released by this SubTx inputs.

<a id="ds-tx-exactness-contribution-f10" name="ds-tx-exactness-contribution-f10"></a>
<a id="ds-tx-exactness-subtx-f10" name="ds-tx-exactness-subtx-f10"></a>
<a id="ds-tx-accounting-subtx-f10" name="ds-tx-accounting-subtx-f10"></a>
<a id="ds-tx-accounting-net-change-subtx-f10" name="ds-tx-accounting-net-change-subtx-f10"></a>

**2.1.2.1.1.19 [F10](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L403) - A release cannot replace a required allocation**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) < 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

Exercise valid local and delegated release forms; their sign contradicts the independently required own change.

<a id="ds-tx-exactness-contribution-f11" name="ds-tx-exactness-contribution-f11"></a>
<a id="ds-tx-exactness-subtx-f11" name="ds-tx-exactness-subtx-f11"></a>
<a id="ds-tx-accounting-subtx-f11" name="ds-tx-accounting-subtx-f11"></a>
<a id="ds-tx-accounting-net-change-subtx-f11" name="ds-tx-accounting-net-change-subtx-f11"></a>

**2.1.2.1.1.20 [F11](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L422) - An allocation cannot replace a required release**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) > 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

Exercise a local allocation and a funding request to TopTx; neither can represent the required own release.

<a id="ds-tx-exactness-contribution-n10" name="ds-tx-exactness-contribution-n10"></a>
<a id="ds-tx-exactness-subtx-n09" name="ds-tx-exactness-subtx-n09"></a>
<a id="ds-tx-accounting-subtx-n09" name="ds-tx-accounting-subtx-n09"></a>
<a id="ds-tx-accounting-net-change-subtx-n09" name="ds-tx-accounting-net-change-subtx-n09"></a>

**2.1.2.1.1.21 [N09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L442) - Exact SubTx declarations when phase 2 fails**

$$
\begin{aligned}
&\mathrm{declaredSubTxs}(\mathit{topTx}) \ne \varnothing \\
&\land (\forall \mathit{subTx} \in \mathrm{declaredSubTxs}(\mathit{topTx}): \\
&\qquad\mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx})) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{accepted}
\end{aligned}
$$

Use a real failing script with otherwise valid declarations and transaction terms. Acceptance follows the collateral outcome, without ordinary Store effects.

<a id="ds-tx-exactness-contribution-f12" name="ds-tx-exactness-contribution-f12"></a>
<a id="ds-tx-exactness-subtx-f12" name="ds-tx-exactness-subtx-f12"></a>
<a id="ds-tx-accounting-subtx-f12" name="ds-tx-accounting-subtx-f12"></a>
<a id="ds-tx-accounting-net-change-subtx-f12" name="ds-tx-accounting-net-change-subtx-f12"></a>

**2.1.2.1.1.22 [F12](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L464) - An inexact SubTx declaration still fails before the collateral outcome**

$$
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{subTx}) \ne \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

Start from N09 failing-script controls and mutate a SubTx amount. The independently established script failure does not waive the earlier exactness check.

<a id="ds-tx-exactness-netting" name="ds-tx-exactness-netting"></a>
<a id="ds-tx-exactness-toptx" name="ds-tx-exactness-toptx"></a>
<a id="ds-tx-accounting-toptx" name="ds-tx-accounting-toptx"></a>
<a id="ds-tx-accounting-net-change-toptx" name="ds-tx-accounting-net-change-toptx"></a>

###### 2.1.2.1.2 TopTx

> **TopTx declares the exact total for the complete transaction.**

$$
\mathrm{declaredNetDeposit}(\mathit{topTx})=\mathrm{transactionNetDeposit}(\mathit{topTx})
$$

Keep every SubTx declaration exact. Include TopTx's own change and every SubTx change
once, including delegated operations. A sum over child declarations uses
`declaredSubTxs(topTx)`; undeclared children contribute no declared value.
The predicate $\mathrm{delegated}(\mathit{subTx})$ means a funding request to TopTx or
a release targeting `DelegateToTopTx`. Delegation affects [Attribution](#ds-tx-attribution),
while the transaction total remains unchanged.

| Total allocations | Total releases | TopTx declaration |
| --- | --- | --- |
| 5 ADA | 3 ADA | Allocate 2 ADA |
| 3 ADA | 5 ADA | Release 2 ADA |
| 5 ADA | 5 ADA | Explicit zero |

TopTx has no separate declaration for its own change. Derive it by subtracting **all**
declared SubTx changes from the declared total, as shown in N02. This differs from
`topTxNetUTxODepositChange` in Attribution, which retains delegated SubTx changes.

On ordinary success, the transaction total is applied once; SubTx amounts are already
included. Accepted phase-2 failure applies no ordinary Store transfer. Requirements
still decide whether the field is mandatory: net zero does not imply absence.

<a id="ds-tx-exactness-netting-p01" name="ds-tx-exactness-netting-p01"></a>
<a id="ds-tx-exactness-toptx-p01" name="ds-tx-exactness-toptx-p01"></a>
<a id="ds-tx-accounting-toptx-p01" name="ds-tx-accounting-toptx-p01"></a>
<a id="ds-tx-accounting-net-change-toptx-p01" name="ds-tx-accounting-net-change-toptx-p01"></a>

**2.1.2.1.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L70) - TopTx declares the exact transaction total**

$$
\begin{aligned}
&\mathrm{topTxNetChangeValid}(\mathit{topTx}) \\
&\iff \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx})
\end{aligned}
$$

Compare the isolated TopTx validator with independently computed deposits; this equivalence does not assert complete ledger acceptance.

<a id="ds-tx-exactness-netting-n01" name="ds-tx-exactness-netting-n01"></a>
<a id="ds-tx-exactness-toptx-n01" name="ds-tx-exactness-toptx-n01"></a>
<a id="ds-tx-accounting-toptx-n01" name="ds-tx-accounting-toptx-n01"></a>
<a id="ds-tx-accounting-net-change-toptx-n01" name="ds-tx-accounting-net-change-toptx-n01"></a>

**2.1.2.1.2.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L85) - TopTx and SubTxs contribute to the total**

$$
\begin{aligned}
&(\exists \mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{subTx}) \ne 0) \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
$$

Cover both zero and nonzero TopTx own changes alongside nonzero child changes. The declared total includes every own change exactly once.

<a id="ds-tx-exactness-contribution-n02" name="ds-tx-exactness-contribution-n02"></a>
<a id="ds-tx-exactness-toptx-n02" name="ds-tx-exactness-toptx-n02"></a>
<a id="ds-tx-accounting-toptx-n02" name="ds-tx-accounting-toptx-n02"></a>
<a id="ds-tx-accounting-net-change-toptx-n02" name="ds-tx-accounting-net-change-toptx-n02"></a>

**2.1.2.1.2.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L98) - TopTx's own change is derived from its total**

$$
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\implies \\
&\mathrm{declaredNetDeposit}(\mathit{topTx}) \\
&\quad-\sum_{\mathit{subTx}\in\mathrm{declaredSubTxs}(\mathit{topTx})}
\mathrm{declaredNetDeposit}(\mathit{subTx}) \\
&\qquad=\mathrm{ownNetDeposit}(\mathit{topTx})
\end{aligned}
$$

Subtract all present child declarations, including delegated operations. Children without declarations have no own Store operations. The result is a diagnostic, not another declaration field.

<a id="ds-tx-exactness-netting-n02" name="ds-tx-exactness-netting-n02"></a>
<a id="ds-tx-exactness-toptx-n03" name="ds-tx-exactness-toptx-n03"></a>
<a id="ds-tx-accounting-toptx-n03" name="ds-tx-accounting-toptx-n03"></a>
<a id="ds-tx-accounting-net-change-toptx-n03" name="ds-tx-accounting-net-change-toptx-n03"></a>

**2.1.2.1.2.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L111) - 5 ADA allocated, 3 ADA released**

$$
\begin{aligned}
&\sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{allocatedDeposits}(\mathit{body}) = 5 \,\mathrm{ADA} \\
&\land \sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{releasedDeposits}(\mathit{body}) = 3 \,\mathrm{ADA} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 2 \,\mathrm{ADA} \\
&\implies \mathrm{accepted}
\end{aligned}
$$

Both sums cover TopTx and all SubTxs; the transaction requires a net allocation of 2 ADA.

<a id="ds-tx-exactness-netting-n03" name="ds-tx-exactness-netting-n03"></a>
<a id="ds-tx-exactness-toptx-n04" name="ds-tx-exactness-toptx-n04"></a>
<a id="ds-tx-accounting-toptx-n04" name="ds-tx-accounting-toptx-n04"></a>
<a id="ds-tx-accounting-net-change-toptx-n04" name="ds-tx-accounting-net-change-toptx-n04"></a>

**2.1.2.1.2.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L122) - 3 ADA allocated, 5 ADA released**

$$
\begin{aligned}
&\sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{allocatedDeposits}(\mathit{body}) = 3 \,\mathrm{ADA} \\
&\land \sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{releasedDeposits}(\mathit{body}) = 5 \,\mathrm{ADA} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = -2 \,\mathrm{ADA} \\
&\implies \mathrm{accepted}
\end{aligned}
$$

Both sums cover TopTx and all SubTxs; the transaction releases 2 ADA net.

<a id="ds-tx-exactness-netting-n04" name="ds-tx-exactness-netting-n04"></a>
<a id="ds-tx-exactness-toptx-n05" name="ds-tx-exactness-toptx-n05"></a>
<a id="ds-tx-accounting-toptx-n05" name="ds-tx-accounting-toptx-n05"></a>
<a id="ds-tx-accounting-net-change-toptx-n05" name="ds-tx-accounting-net-change-toptx-n05"></a>

**2.1.2.1.2.6 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L134) - Nonzero body changes produce a zero total**

$$
\begin{aligned}
&(\exists \mathit{body} \in \mathrm{bodies}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{body}) \ne 0) \\
&\land \mathrm{transactionNetDeposit}(\mathit{topTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
$$

Allocating and releasing bodies offset each other. TopTx still supplies an explicit zero declaration.

<a id="ds-tx-exactness-netting-f01" name="ds-tx-exactness-netting-f01"></a>
<a id="ds-tx-exactness-toptx-f01" name="ds-tx-exactness-toptx-f01"></a>
<a id="ds-tx-accounting-toptx-f01" name="ds-tx-accounting-toptx-f01"></a>
<a id="ds-tx-accounting-net-change-toptx-f01" name="ds-tx-accounting-net-change-toptx-f01"></a>

**2.1.2.1.2.7 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L144) - Standalone TopTx understates its net allocation by one lovelace**

$$
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{transactionNetDeposit}(\mathit{topTx}) > 1 \,\mathrm{lovelace} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) - 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
$$

Create one more store-backed output than is consumed. Start from a valid control and alter only the signed declaration.

<a id="ds-tx-exactness-netting-f02" name="ds-tx-exactness-netting-f02"></a>
<a id="ds-tx-exactness-toptx-f02" name="ds-tx-exactness-toptx-f02"></a>
<a id="ds-tx-accounting-toptx-f02" name="ds-tx-accounting-toptx-f02"></a>
<a id="ds-tx-accounting-net-change-toptx-f02" name="ds-tx-accounting-net-change-toptx-f02"></a>

**2.1.2.1.2.8 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L156) - Standalone TopTx overstates its net allocation by one lovelace**

$$
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{transactionNetDeposit}(\mathit{topTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) + 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
$$

Use the same net-allocation generator and increase only the declaration by one lovelace.

<a id="ds-tx-exactness-netting-f03" name="ds-tx-exactness-netting-f03"></a>
<a id="ds-tx-exactness-toptx-f03" name="ds-tx-exactness-toptx-f03"></a>
<a id="ds-tx-accounting-toptx-f03" name="ds-tx-accounting-toptx-f03"></a>
<a id="ds-tx-accounting-net-change-toptx-f03" name="ds-tx-accounting-net-change-toptx-f03"></a>

**2.1.2.1.2.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L169) - Standalone TopTx understates its net release by one lovelace**

$$
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{allocatedDeposits}(\mathit{topTx}) = 0 \\
&\land \mathrm{releasedDeposits}(\mathit{topTx}) > 1 \,\mathrm{lovelace} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) + 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
$$

Only implicit outputs are created. Adding one to the negative declaration reduces the release magnitude.

<a id="ds-tx-exactness-netting-f04" name="ds-tx-exactness-netting-f04"></a>
<a id="ds-tx-exactness-toptx-f04" name="ds-tx-exactness-toptx-f04"></a>
<a id="ds-tx-accounting-toptx-f04" name="ds-tx-accounting-toptx-f04"></a>
<a id="ds-tx-accounting-net-change-toptx-f04" name="ds-tx-accounting-net-change-toptx-f04"></a>

**2.1.2.1.2.10 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L182) - Standalone TopTx overstates its net release by one lovelace**

$$
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{allocatedDeposits}(\mathit{topTx}) = 0 \\
&\land \mathrm{releasedDeposits}(\mathit{topTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) - 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
$$

Only implicit outputs are created. Subtracting one from the negative declaration increases the release magnitude.

<a id="ds-tx-exactness-netting-f05" name="ds-tx-exactness-netting-f05"></a>
<a id="ds-tx-exactness-toptx-f05" name="ds-tx-exactness-toptx-f05"></a>
<a id="ds-tx-accounting-toptx-f05" name="ds-tx-accounting-toptx-f05"></a>
<a id="ds-tx-accounting-net-change-toptx-f05" name="ds-tx-accounting-net-change-toptx-f05"></a>

**2.1.2.1.2.11 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L194) - Explicit zero cannot replace a nonzero total**

$$
\begin{aligned}
&\mathrm{transactionNetDeposit}(\mathit{topTx}) \ne 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
$$

Cover both a required net allocation and a required net release.

<a id="ds-tx-exactness-netting-f06" name="ds-tx-exactness-netting-f06"></a>
<a id="ds-tx-exactness-toptx-f06" name="ds-tx-exactness-toptx-f06"></a>
<a id="ds-tx-accounting-toptx-f06" name="ds-tx-accounting-toptx-f06"></a>
<a id="ds-tx-accounting-net-change-toptx-f06" name="ds-tx-accounting-net-change-toptx-f06"></a>

**2.1.2.1.2.12 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L210) - A nonzero declaration cannot replace a zero total**

$$
\begin{aligned}
&\mathrm{transactionNetDeposit}(\mathit{topTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) \ne 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
$$

Cover both an allocation declaration and a release declaration when the transaction total is zero.

<a id="ds-tx-exactness-netting-f07" name="ds-tx-exactness-netting-f07"></a>
<a id="ds-tx-exactness-toptx-f07" name="ds-tx-exactness-toptx-f07"></a>
<a id="ds-tx-accounting-toptx-f07" name="ds-tx-accounting-toptx-f07"></a>
<a id="ds-tx-accounting-net-change-toptx-f07" name="ds-tx-accounting-net-change-toptx-f07"></a>

**2.1.2.1.2.13 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L225) - TopTx declares the opposite direction**

$$
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) \times \mathrm{transactionNetDeposit}(\mathit{topTx}) < 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
$$

A required allocation cannot be declared as a release, or a required release as an allocation.

<a id="ds-tx-exactness-netting-n05" name="ds-tx-exactness-netting-n05"></a>
<a id="ds-tx-exactness-toptx-n06" name="ds-tx-exactness-toptx-n06"></a>
<a id="ds-tx-accounting-toptx-n06" name="ds-tx-accounting-toptx-n06"></a>
<a id="ds-tx-accounting-net-change-toptx-n06" name="ds-tx-accounting-net-change-toptx-n06"></a>

**2.1.2.1.2.14 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L244) - TopTx releases while SubTxs allocate**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{topTx}) < 0 \\
&\land (\forall \mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{subTx}) \ge 0) \\
&\land \sum_{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx})} \mathrm{ownNetDeposit}(\mathit{subTx}) = -\mathrm{ownNetDeposit}(\mathit{topTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
$$

The child allocations exactly offset the parent release. TopTx declares the transaction total, not its own negative change.

<a id="ds-tx-exactness-netting-n06" name="ds-tx-exactness-netting-n06"></a>
<a id="ds-tx-exactness-toptx-n07" name="ds-tx-exactness-toptx-n07"></a>
<a id="ds-tx-accounting-toptx-n07" name="ds-tx-accounting-toptx-n07"></a>
<a id="ds-tx-accounting-net-change-toptx-n07" name="ds-tx-accounting-net-change-toptx-n07"></a>

**2.1.2.1.2.15 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L254) - TopTx allocates while SubTxs release**

$$
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{topTx}) > 0 \\
&\land (\forall \mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{subTx}) \le 0) \\
&\land \sum_{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx})} \mathrm{ownNetDeposit}(\mathit{subTx}) = -\mathrm{ownNetDeposit}(\mathit{topTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
$$

The child releases exactly offset the parent allocation. TopTx declares the transaction total, not its own positive change.

<a id="ds-tx-exactness-netting-n07" name="ds-tx-exactness-netting-n07"></a>
<a id="ds-tx-exactness-toptx-n08" name="ds-tx-exactness-toptx-n08"></a>
<a id="ds-tx-accounting-toptx-n08" name="ds-tx-accounting-toptx-n08"></a>
<a id="ds-tx-accounting-net-change-toptx-n08" name="ds-tx-accounting-net-change-toptx-n08"></a>

**2.1.2.1.2.16 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L264) - An exact total remains valid when phase 2 fails**

$$
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{accepted}
\end{aligned}
$$

The failing script matches the declared outcome. Net change still uses proposed ordinary deposits; collateral execution is a separate rule.

<a id="ds-tx-exactness-netting-f08" name="ds-tx-exactness-netting-f08"></a>
<a id="ds-tx-exactness-toptx-f08" name="ds-tx-exactness-toptx-f08"></a>
<a id="ds-tx-accounting-toptx-f08" name="ds-tx-accounting-toptx-f08"></a>
<a id="ds-tx-accounting-net-change-toptx-f08" name="ds-tx-accounting-net-change-toptx-f08"></a>

**2.1.2.1.2.17 [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L276) - An inexact total is rejected even when phase 2 fails**

$$
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) \ne \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
$$

A failing script does not waive deposit exactness. The script matches the declared outcome; rejection must include the TopTx exactness failure.

<a id="ds-tx-exactness-netting-f09" name="ds-tx-exactness-netting-f09"></a>
<a id="ds-tx-exactness-toptx-f09" name="ds-tx-exactness-toptx-f09"></a>
<a id="ds-tx-accounting-toptx-f09" name="ds-tx-accounting-toptx-f09"></a>
<a id="ds-tx-accounting-net-change-toptx-f09" name="ds-tx-accounting-net-change-toptx-f09"></a>

**2.1.2.1.2.18 [F09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L293) - A delegated change belongs in the total exactly once**

$$
\begin{aligned}
&\mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}) \\
&\land \mathrm{delegated}(\mathit{subTx}) \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) \ne 0 \\
&\land\mathrm{declaredNetDeposit}(\mathit{topTx})\in\{ \\
&\qquad\mathrm{transactionNetDeposit}(\mathit{topTx})-\mathrm{ownNetDeposit}(\mathit{subTx}), \\
&\qquad\mathrm{transactionNetDeposit}(\mathit{topTx})+\mathrm{ownNetDeposit}(\mathit{subTx})\} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
$$

Omitting or adding a second copy of a delegated child change makes the total inexact; delegation changes responsibility, not the counted amount.

<a id="ds-tx-conservation" name="ds-tx-conservation"></a>
<a id="ds-tx-accounting-balance" name="ds-tx-accounting-balance"></a>

##### 2.1.2.2 Balance

> **Require the complete transaction to balance when phase 2 is valid.**
>
> All consumed value $=$ all produced value, including the net Store transfer once. Individual SubTxs may remain financially imbalanced.

**Decision:** Agreed.

| Phase-2 outcome | Ordinary financial conservation | Applied effects |
| --- | --- | --- |
| Valid | Required | Ordinary transaction |
| Invalid | Not checked | Collateral only |

**Common premises.** Declarations are exact and every non-balance requirement is
satisfied. Phase 2 is valid except in N08. Each mutation starts from an independently
balanced control; only the stated outputs or fee change. Inputs and declarations
remain fixed. Unqualified coin amounts are in lovelace.

| Notation | Meaning |
| --- | --- |
| $\text{inputValue}$ | Sum of application values in all ordinary inputs of TopTx and its SubTxs. |
| $\text{outputValue}$ | Sum of their proposed ordinary output values. |
| $\text{fees}$ | TopTx's fee. |
| $\text{declaredNetDeposit}$ | TopTx's explicit signed total: allocation $>0$, release $<0$, zero $=0$. |
| $\text{inputCoins(body)}$, $\text{outputCoins(body)}$ | Application ADA in that body's own inputs or outputs. |
| $\Delta$ | Change from the independently balanced control. |
| $\text{outputAdjustment}$ | Change to TopTx's implicit output zero. |
| $\text{feeContribution(subTx)}$ | Application ADA redirected from the child's output into an increased TopTx fee; not a declaration field. |

**The Store transfer enters the equation once.** `inject` adds ADA without
changing native assets:

$$
\begin{aligned}
\text{consumedValue}
&=\text{inputValue}+\text{inject}(\max(0,-\text{declaredNetDeposit})) \\
\text{producedValue}
&=\text{outputValue}+\text{inject}(\text{fees}+\max(0,\text{declaredNetDeposit})) \\
\text{transactionBalance}
&=\text{consumedValue}-\text{producedValue}
\end{aligned}
$$

$\text{transactionBalance}$ retains all asset identities and quantities. Its ADA
and native-asset components are $\text{adaBalance}$ and
$\text{nativeAssetBalance}$; zero means no remaining difference in that component.
TopTx's total already includes every SubTx contribution. Adding those contributions
again would duplicate the Store transfer. An absent declaration has no declared
value: an all-absent transaction has no Store term, rather than an explicit zero.

[Net change](#ds-tx-accounting-net-change) separately establishes that declarations
match the required deposit changes on both phase-2 outcomes. The balance equation
here applies only when phase 2 is valid. On phase-2 failure, the ordinary proposal
remains unapplied; [Collateral conservation](#ds-collateral-conservation) governs
the applied settlement, and [Execution](#ds-state-execution) selects the effects.

**Fixture scope.** Inputs are actually funded. The proposals contain ordinary
application inputs and outputs, TopTx fees and Store transfers. They contain no
certificates, withdrawals, mint, governance proposals, treasury donations or direct
deposits.

Native assets used by P01 and F02 are minted in a separate accepted funding
transaction. Their proposed spending transaction does not mint. The independent
observer resolves every ordinary input from the ledger and sums application
values, outputs, fees and the declared Store term directly. It does not call the
production consumed/produced-value helpers. Additional ledger flows would require
extending this observer before adding them to these fixtures.

The ordinary cases use key witnesses in normal mode. N08 adds a genuinely failing
phase-2 script with valid collateral. These fixtures do not exercise legacy-mode
balance restrictions.

**Isolate financial balance.** Every declaration remains exact. Start with a
proposal independently balanced after fee preparation; change only implicit
application outputs or the fee, then re-sign without rerunning value fixup. The
changed output cannot alter the Store allocation. Rejection must include
`ValueNotConservedUTxO` with the independently computed consumed and produced
values, and each rejection scenario also submits its balanced acceptance control.

**The concrete release example.** N06, N07 and F04 hold every other batch flow
fixed. TopTx funds its base fee separately; the child has one input, one implicit
output, no new allocation and no other financial flow. For these cases, the
transaction equation reduces to:

$$
\text{inputCoins(subTx)}+\text{releasedDeposits(subTx)}
=\text{outputCoins(subTx)}+\text{feeContribution(subTx)}
$$

This reduction follows from the fixed surrounding transaction; it is not a new
requirement that all SubTxs balance independently.

| Child's application input | Recorded Store release | Child's only output | Export to TopTx fees | Outcome |
| --- | --- | --- | --- | --- |
| $10$ ADA | $2$ ADA | $12$ ADA | $0$ ADA | Accepted |
| $10$ ADA | $2$ ADA | $10$ ADA | $2$ ADA | Accepted |
| $10$ ADA | $2$ ADA | $10$ ADA | $0$ ADA | Rejected: $2$ ADA unaccounted for |

The $2$ ADA release is the deposit recorded for the actual store-backed input.
Only the stated output and fee contribution vary between rows. The existing
settlement bound remains mandatory; stronger local-settlement guarantees remain
open under DS-TX-SETTLEMENT-REFINEMENT.

<a id="ds-tx-conservation-p01" name="ds-tx-conservation-p01"></a>
<a id="ds-tx-accounting-balance-p01" name="ds-tx-accounting-balance-p01"></a>

###### 2.1.2.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L72) - The transaction conserves value when phase 2 is valid

$$
\begin{aligned}
&\text{phase2Valid}\land\text{Accepted} \\
&\implies\text{inputValue}+\text{inject}(\max(0,-\text{declaredNetDeposit})) \\
&\qquad=\text{outputValue}+\text{inject}(\text{fees}+\max(0,\text{declaredNetDeposit}))
\end{aligned}
$$

Generate TopTx with one to four SubTxs, combining allocations and recorded releases.
Supply exact declarations and a real token-bearing input with a matching output.
Require ledger acceptance, then compare the independently observed full values.
The equation covers ADA and native assets while the Store term changes only ADA.

<a id="ds-tx-conservation-p02" name="ds-tx-conservation-p02"></a>
<a id="ds-tx-accounting-balance-p02" name="ds-tx-accounting-balance-p02"></a>

###### 2.1.2.2.2 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L96) - Complete balance determines acceptance

$$
\begin{aligned}
&\text{phase2Valid}\land\text{transfer}>0 \\
&\land\text{outputAdjustment}\in\{-1,0,1\} \\
&\implies(\text{Accepted}\iff\text{transactionBalance}=0)
\end{aligned}
$$

First move a positive amount from one SubTx's implicit output to another's.
The two child imbalances offset. For each generated transaction, also adjust one
TopTx implicit output by $-1$, $0$ and $+1$ lovelace, leaving fees and declarations
unchanged.

The independent value equation determines the expected ledger decision. Both
nonzero adjustments must produce its exact mismatch; the zero adjustment must be
accepted despite the SubTxs' individual financial imbalances.

<a id="ds-tx-conservation-n01" name="ds-tx-conservation-n01"></a>
<a id="ds-tx-accounting-balance-n01" name="ds-tx-accounting-balance-n01"></a>

###### 2.1.2.2.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L117) - Fund a net allocation once

$$
\begin{aligned}
&\text{declaredNetDeposit}>0 \\
&\land\text{outputAdjustment}\in\{-\text{declaredNetDeposit},0,\text{declaredNetDeposit}\} \\
&\implies(\text{Accepted}\iff\text{outputAdjustment}=0)
\end{aligned}
$$

TopTx and its SubTx each allocate a positive deposit. Keep their exact
declarations, then compare the balanced transaction with two changes to TopTx's
implicit output:

| Application output change | Financial interpretation | Expected result |
| --- | --- | --- |
| $0$ | Fund the declared total once. | Accepted |
| $+\text{declaredNetDeposit}$ | Spend the allocation again as application ADA. | Rejected |
| $-\text{declaredNetDeposit}$ | Charge the allocation twice, leaving an unaccounted surplus. | Rejected |

Neither mutation changes the declared amount or any store-backed output. The
ledger must count the whole declared allocation once, including its child share.

<a id="ds-tx-conservation-n02" name="ds-tx-conservation-n02"></a>
<a id="ds-tx-accounting-balance-n02" name="ds-tx-accounting-balance-n02"></a>

###### 2.1.2.2.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L137) - Use a net release once

$$
\begin{aligned}
&\text{declaredNetDeposit}<0 \\
&\land\text{outputAdjustment}\in\{-\text{declaredNetDeposit},0,\text{declaredNetDeposit}\} \\
&\implies(\text{Accepted}\iff\text{outputAdjustment}=0)
\end{aligned}
$$

TopTx and its SubTx each release recorded deposits. Keep their exact
declarations and compare these uses of the complete net release:

| Application output change | Financial interpretation | Expected result |
| --- | --- | --- |
| $0$ | Use the declared release once. | Accepted |
| $-\text{declaredNetDeposit}$ | Spend a second copy of the release. | Rejected |
| $+\text{declaredNetDeposit}$ | Leave the release unaccounted for. | Rejected |

The changes affect only TopTx's implicit output. Counting SubTx releases again
would credit value already present in the declared transaction total.

<a id="ds-tx-conservation-n03" name="ds-tx-conservation-n03"></a>
<a id="ds-tx-accounting-balance-n03" name="ds-tx-accounting-balance-n03"></a>

###### 2.1.2.2.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L155) - One SubTx funds another

$$
\begin{aligned}
&\text{transfer}>0 \\
&\land\Delta\text{outputCoins}(\text{subTx}_{0})=-\text{transfer} \\
&\land\Delta\text{outputCoins}(\text{subTx}_{1})=\text{transfer} \\
&\implies\text{Accepted}
\end{aligned}
$$

Begin with a balanced control containing two SubTxs that allocate deposits.
Move a generated positive amount from the first child's implicit output to the
second's, keeping the complete output value, declarations and fee unchanged.

Accept the transaction. A surplus in one body may fund another; exact local deposit
declarations do not require independently balanced SubTx finances.

<a id="ds-tx-conservation-n04" name="ds-tx-conservation-n04"></a>
<a id="ds-tx-accounting-balance-n04" name="ds-tx-accounting-balance-n04"></a>

###### 2.1.2.2.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L168) - A SubTx funds TopTx fees

$$
\begin{aligned}
&\text{contribution}>0 \\
&\land\Delta\text{outputCoins(subTx)}=-\text{contribution} \\
&\land\Delta\text{fees}=\text{contribution} \\
&\implies\text{Accepted}
\end{aligned}
$$

TopTx and its SubTx allocate deposits with exact declarations. Redirect a
generated positive amount from the child's implicit output into TopTx's fee.

Accept the transaction: total produced value is unchanged. The child may fund a
parent fee without changing either body's deposit declaration.

<a id="ds-tx-conservation-f01" name="ds-tx-conservation-f01"></a>
<a id="ds-tx-accounting-balance-f01" name="ds-tx-accounting-balance-f01"></a>

###### 2.1.2.2.7 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L181) - One-lovelace deficit or surplus

$$
\Delta\text{outputCoins(topTx)}\in\{-1,1\}
\implies\text{Rejected}
$$

Starting from an exactly declared, funded allocation transaction, change only
TopTx's implicit output by one lovelace in each direction.

The increase creates a deficit; the decrease leaves a surplus. Require
`ValueNotConservedUTxO` for both, then accept the unchanged balanced control.
Exact deposit declarations excuse neither mismatch.

<a id="ds-tx-conservation-f02" name="ds-tx-conservation-f02"></a>
<a id="ds-tx-accounting-balance-f02" name="ds-tx-accounting-balance-f02"></a>

###### 2.1.2.2.8 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L199) - Native-asset quantity or identity mismatch

$$
\text{adaBalance}=0\land\text{nativeAssetBalance}\ne0
\implies\text{Rejected}
$$

Spend a genuinely funded native asset without minting in the proposal. Keep
ADA, the exact Store declarations and the fee unchanged, then mutate only the
token-bearing implicit output:

| Mutation | Why it fails |
| --- | --- |
| Remove the input's token quantity. | Consumed tokens have no destination. |
| Add another copy of that quantity. | The proposal creates tokens without minting. |
| Keep quantity and policy, change the asset name. | One asset disappears while a different asset appears. |

Each variant must produce the independently calculated full-value mismatch; the
original token-preserving proposal must be accepted. An ADA balance cannot
compensate for a different native-asset identity or quantity.

<a id="ds-tx-conservation-f03" name="ds-tx-conservation-f03"></a>
<a id="ds-tx-accounting-balance-f03" name="ds-tx-accounting-balance-f03"></a>

###### 2.1.2.2.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L219) - An exact delegated allocation lacks funding

$$
\begin{aligned}
&\text{requestedAllocation}>0 \\
&\land\Delta\text{outputCoins(topTx)}=\text{requestedAllocation} \\
&\implies\text{Rejected}
\end{aligned}
$$

A single SubTx requests a positive allocation from TopTx; TopTx has no own
Store operation and declares that same exact total. From its balanced control,
increase TopTx's implicit output by the requested allocation.

The request remains exact, but its funds are also promised to an application
output. Require the financial mismatch, then accept the original funded request.
Delegation assigns responsibility; it does not supply additional ADA.

<a id="ds-tx-conservation-n05" name="ds-tx-conservation-n05"></a>
<a id="ds-tx-accounting-balance-n05" name="ds-tx-accounting-balance-n05"></a>

###### 2.1.2.2.10 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L234) - Equal delegated allocations and releases

$$
\begin{aligned}
&\text{requestedAllocation}=\text{delegatedRelease}>0 \\
&\land\text{declaredNetDeposit}=0\land\text{transactionBalance}=0 \\
&\implies\text{Accepted}
\end{aligned}
$$

One SubTx requests an allocation from TopTx; another delegates an equal
recorded release to TopTx. The parent has no own Store operation.

With both child declarations explicit and the complete transaction funded, accept
TopTx's explicit-zero total. The two Store operations exist, but their combined
transfer adds no ADA to either side of the transaction balance.

<a id="ds-tx-conservation-n06" name="ds-tx-conservation-n06"></a>
<a id="ds-tx-accounting-balance-n06" name="ds-tx-accounting-balance-n06"></a>

###### 2.1.2.2.11 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L246) - Ten input ADA plus two released ADA

$$
\begin{aligned}
&\text{inputCoins(subTx)}=10\text{ ADA} \\
&\land\text{releasedDeposits(subTx)}=2\text{ ADA} \\
&\land\text{outputCoins(subTx)}=12\text{ ADA} \\
&\land\text{feeContribution(subTx)}=0 \\
&\implies\text{Accepted}
\end{aligned}
$$

Fund one actual store-backed input containing $10$ ADA of application value
and a recorded $2$ ADA deposit. Its SubTx consumes that input and creates one
implicit output. It declares the $2$ ADA release into its own output; TopTx declares
the same total with `NoTopTxSettlement`.

Accept the transaction. TopTx's separate generated funding pays its base fee, so
no fee or additional child input changes this example. This fixed child scenario
does not impose independent SubTx balance on the other cases.

<a id="ds-tx-conservation-n07" name="ds-tx-conservation-n07"></a>
<a id="ds-tx-accounting-balance-n07" name="ds-tx-accounting-balance-n07"></a>

###### 2.1.2.2.12 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L255) - Released ADA contributes to TopTx fees

$$
\begin{aligned}
&\text{inputCoins(subTx)}=10\text{ ADA} \\
&\land\text{releasedDeposits(subTx)}=2\text{ ADA} \\
&\land\text{outputCoins(subTx)}=10\text{ ADA} \\
&\land\text{feeContribution(subTx)}=2\text{ ADA} \\
&\implies\text{Accepted}
\end{aligned}
$$

Use N06's same $10$ ADA input and $2$ ADA recorded release. Reduce the child's
implicit output from $12$ ADA to $10$ ADA and increase TopTx's fee by exactly
$2$ ADA, preserving every other flow.

Accept the transaction. The release is fully accounted for through the smaller
child output and the explicit fee contribution; its declaration remains unchanged.

<a id="ds-tx-conservation-f04" name="ds-tx-conservation-f04"></a>
<a id="ds-tx-accounting-balance-f04" name="ds-tx-accounting-balance-f04"></a>

###### 2.1.2.2.13 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L265) - Released ADA cannot disappear

$$
\begin{aligned}
&\text{inputCoins(subTx)}=10\text{ ADA} \\
&\land\text{releasedDeposits(subTx)}=2\text{ ADA} \\
&\land\text{outputCoins(subTx)}=10\text{ ADA} \\
&\land\text{feeContribution(subTx)}=0 \\
&\implies\text{Rejected}
\end{aligned}
$$

Start with N06's balanced transaction and reduce only the child's implicit
output from $12$ ADA to $10$ ADA. Keep TopTx's fee, every other output and all
inputs and declarations fixed.

Require the independent financial mismatch, then accept the original $12$ ADA
control. N07 is accepted because it accounts for this difference in the fee;
this variant leaves the same $2$ ADA without a destination.

<a id="ds-tx-conservation-n08" name="ds-tx-conservation-n08"></a>
<a id="ds-tx-accounting-balance-n08" name="ds-tx-accounting-balance-n08"></a>

###### 2.1.2.2.14 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L280) - Balanced proposal, failed phase 2

$$
\text{phase2Invalid}\land\text{transactionBalance}=0
\implies\text{Accepted}
$$

Generate recorded releases for both TopTx and its SubTx, with exact declarations
and an independently balanced ordinary proposal. Add a genuinely failing phase-2
script, declare the invalid outcome and supply valid collateral. Expect acceptance
through the collateral outcome.

This is an acceptance control: a balanced ordinary proposal may accompany accepted
phase-2 failure. It does not establish that ordinary balance is checked on this
path. [Execution](#ds-state-execution) determines the applied effects.

<a id="ds-tx-attribution" name="ds-tx-attribution"></a>

#### 2.1.3 Attribution

> **Determine which body accounts for a contribution.**
>
> Local SubTx operation $\longrightarrow$ SubTx · Delegated SubTx operation $\longrightarrow$ TopTx. The required amount and transaction total remain unchanged.

**Decision:** Agreed.

| SubTx declaration | Contribution attributed locally |
| --- | --- |
| Explicit zero | $0$ |
| Local allocation of $\text{amount}$ | $+\text{amount}$ |
| Local release of $\text{amount}$ | $-\text{amount}$ |
| Allocation requested from TopTx | $0$; TopTx accounts for it |
| Release delegated to TopTx | $0$; TopTx accounts for it |
| Absent declaration | No operation, contributing $0$ to local accounting; this is not a declared zero |

For an explicit TopTx declaration:

$$
\begin{aligned}
\text{topTxNetUTxODepositChange}
&=\text{declaredTxTotalNetUTxODepositChange} \\
&\quad-\sum_{\text{contribution}\in\text{subTxLocalNetUTxODepositChanges}}
\text{contribution}
\end{aligned}
$$

TopTx's attributed amount includes delegated contributions. Its **own** contribution
derived under DS-TX-ACCOUNTING-NET-CHANGE-TOPTX removes all declared SubTx contributions,
including delegated ones, from the declared batch total. The independently required
own amount comes from its input records and new outputs. These quantities agree only
under the corresponding exactness checks and must remain distinct in test oracles.

With a 3 ADA SubTx allocation and a 2 ADA contribution from TopTx's own outputs:

| SubTx accounting | TopTx declares | Accounted in SubTx | Accounted in TopTx |
| --- | --- | --- | --- |
| Local | Allocate 5 ADA | 3 ADA | 2 ADA |
| Delegated | Allocate 5 ADA | 0 ADA | 5 ADA |

For allocation-only transactions this gives:

$$
\begin{aligned}
\text{declaredTxTotalNetUTxODepositChange}
&=\text{ownTopTxNetAllocation} \\
&\quad+\sum_{\text{allocation}\in\text{localSubTxNetAllocations}}\text{allocation} \\
&\quad+\sum_{\text{allocation}\in\text{delegatedSubTxNetAllocations}}\text{allocation} \\
\text{topTxNetUTxODepositChange}
&=\text{ownTopTxNetAllocation}
+\sum_{\text{allocation}\in\text{delegatedSubTxNetAllocations}}\text{allocation}
\end{aligned}
$$

Attribution can have a different sign from the transaction total: a local SubTx
allocation of 5 ADA and a delegated release of 3 ADA attribute $+5$ to SubTx and $-3$
to TopTx, while TopTx declares a net allocation of 2 ADA.

Local accounting does not require independent SubTx financial balance. Delegation
requests still require exact originating contributions, sufficient batch funding,
a TopTx declaration and valid settlement where applicable. Those predicates remain
in Net change, Balance, Requirements and Settlement respectively.

<a id="ds-tx-attribution-p01" name="ds-tx-attribution-p01"></a>

##### 2.1.3.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L18) - observed TopTx and local SubTx attribution matches the independent signed contribution projection

Compare actual production attribution with an independently written declaration-form projection: local allocation/release maps to $+\text{amount}$/$-\text{amount}$, delegation and explicit zero map to zero locally. TopTx retains its own contribution plus delegated contributions. The resulting sum recovers the declared total; do not calculate both sides from the same subtraction and test only that tautology.

<a id="ds-tx-attribution-p02" name="ds-tx-attribution-p02"></a>

##### 2.1.3.2 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L19) - switching local and delegated accounting changes attribution by the signed contribution and preserves the required batch change

For both allocation and release, switch the SubTx accounting mode while keeping the originating Store operations fixed. Check the observed signed attribution shift and unchanged required batch total. This does not promise unchanged ledger acceptance if the new responsibility requires a different settlement selector or coverage.

<a id="ds-tx-attribution-n01" name="ds-tx-attribution-n01"></a>

##### 2.1.3.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L20) - counts delegated funding once in TopTx accounting

A delegated request is already a contribution to the transaction total. Attribute it to TopTx without adding a second Store allocation for the same request.

<a id="ds-tx-attribution-n02" name="ds-tx-attribution-n02"></a>

##### 2.1.3.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L21) - keeps the same batch net change when a SubTx delegates funding of its net allocation

Changing a SubTx allocation from local accounting to a TopTx request leaves the required Store transfer unchanged. Only the attribution changes.

<a id="ds-tx-attribution-n03" name="ds-tx-attribution-n03"></a>

##### 2.1.3.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L22) - allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx

A SubTx can consume its store-backed inputs without creating outputs and explicitly delegate its release. Settlement and batch funding are then handled according to TopTx attribution.

<a id="ds-tx-grammar-n01" name="ds-tx-grammar-n01"></a>
<a id="ds-tx-declarations-grammar-n01" name="ds-tx-declarations-grammar-n01"></a>
<a id="ds-tx-attribution-n04" name="ds-tx-attribution-n04"></a>

##### 2.1.3.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L23) - observes zero local and delegated amounts with no funding request for SubTx explicit zero

Give a SubTx an explicit-zero declaration and observe the production accounting result: zero local contribution, zero delegated contribution and no funding request. Use an otherwise valid zero-change fixture. Recognizing or round-tripping the zero constructor alone does not establish this attribution behavior; declaration representation belongs to Grammar.

<a id="ds-tx-authorization" name="ds-tx-authorization"></a>

#### 2.1.4 Authorization

> **Determine who may release an output’s allocated deposit.**
>
> Release authority follows spending authority, rather than the identity of the original deposit funder.

**Decision:** Agreed.

On the ordinary successful spending path, the authority to release an output's allocated
UTxO capacity deposit follows that output's spending conditions. Satisfy its existing key or
script authorization; no separate DepositStore release credential or witness is
required. Funding the original deposit gives the funder no retained refund claim or
additional approval right.

Released UTxO capacity deposits participate in exact accounting under DS-TX-ACCOUNTING-NET-CHANGE. A body whose
released UTxO capacity deposits exceed its newly allocated UTxO capacity deposits has a release
contribution. SubTx declares its own contribution; TopTx declares the net change for the
complete batch. Batch netting and settlement still follow DS-TX-ACCOUNTING-NET-CHANGE-TOPTX, DS-TX-SETTLEMENT-PARTICIPATION and
DS-TX-SETTLEMENT; release does not imply an extra gross Store release.

For example, Alice funds a UTxO capacity deposit of 2 ADA for a store-backed output
controlled by Bob. If Bob validly spends it without creating replacement store-backed
outputs, its body must account for a 2 ADA release contribution. Alice's approval is not
required, and the settlement destination need not be Alice.

A SubTx authorizes delegated release through its explicit `DelegateToTopTx` target.
TopTx handles settlement under the existing netting rules; the SubTx does not select a
final TopTx output index. Ordinary spending authorization cannot be replaced by a
declaration or by referencing an output. Collateral consumption follows its separate
authorization and settlement rules under DS-COLLATERAL-AUTHORIZATION and
DS-COLLATERAL-SETTLEMENT.

<a id="ds-tx-authorization-n01" name="ds-tx-authorization-n01"></a>

##### 2.1.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L11) - allows the authorized spender to release UTxO capacity deposits paid by another person

Alice funds an output controlled by Bob; Bob later spends it with exact deposit accounting and valid settlement. Observe release under Bob's spending authority despite Alice having supplied the original funds.

<a id="ds-tx-authorization-n02" name="ds-tx-authorization-n02"></a>

##### 2.1.4.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L12) - does not require a separate signature from the original UTxO capacity deposit funder

Use the same two-party lifecycle but explicitly inspect the final witness set: Bob's required witness is present and Alice's is absent. Acceptance proves that no separate original-funder approval is required.

<a id="ds-tx-authorization-f01" name="ds-tx-authorization-f01"></a>

##### 2.1.4.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L13) - rejects spending by the original funder without the current spending authority even when the Store declaration is exact

From the otherwise valid two-party control, supply Alice's witness and omit Bob's required spending witness. Assert the existing authorization failure despite exact ordinary deposit declarations and valid settlement.

<a id="ds-tx-authorization-n03" name="ds-tx-authorization-n03"></a>

##### 2.1.4.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L14) - gains no release authority merely by referencing a store-backed output

Referencing Alice/Bob's output gives the referencing body no authority to claim its associated deposit. A reference-only fixture is accepted without that release; an attempted release cannot become authorized by adding the reference. Requirements owns whether a field is needed, and State Allocations owns preservation of the live record.

<a id="ds-tx-settlement" name="ds-tx-settlement"></a>

#### 2.1.5 Settlement

> **Determine which output must contain a release amount.**
>
> Participation $\longrightarrow$ destination $\longrightarrow$ coverage. Settlement uses the accounting result without adding another Store transfer.

<a id="ds-tx-settlement-participation" name="ds-tx-settlement-participation"></a>

##### 2.1.5.1 Participation

> **Determine whether a net-release transaction needs a TopTx settlement output.**
>
> TopTx’s accounted release share, rather than the complete transaction’s net release, determines its participation.

**Decision:** Agreed.

A net release declares the batch amount and, separately, whether TopTx receives a share:

```haskell
TopTx.DeclaresNetUTxODepositRelease amount settlement
```

Here `amount` has type `StrictlyPositiveCoin`, and the settlement choices remain:

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

The operation's amount always remains the entire batch's net release under DS-TX-ACCOUNTING-NET-CHANGE-TOPTX. It
is not an additional payment or a second credit to SubTx outputs. Offsetting net
allocations participate in the net calculation, so the declared amount need not equal
the gross sum of local SubTx releases.

Derive the TopTx amounts from the signed total and the SubTx declarations:

$$
\begin{aligned}
\text{txTotalNetRelease}
&=\max(0,-\text{declaredTxTotalNetUTxODepositChange}) \\
\text{topTxNetUTxODepositChange}
&=\text{declaredTxTotalNetUTxODepositChange} \\
&\quad-\sum_{\text{contribution}\in\text{subTxLocalNetUTxODepositChanges}}
\text{contribution} \\
\text{topTxNetRelease}&=\max(0,-\text{topTxNetUTxODepositChange})
\end{aligned}
$$

Each SubTx contributes the following signed amount to
`subTxLocalNetUTxODepositChanges`:

| SubTx declaration | Local net UTxO capacity deposit change |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | $0$; no delegation |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | $+\text{amount}$ |
| `SubTx.DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput index)` | $-\text{amount}$ |
| `SubTx.RequestsUTxODepositFromTopTx amount` | $0$; TopTx handles the net allocation |
| `SubTx.DeclaresNetUTxODepositRelease amount DelegateToTopTx` | $0$; TopTx handles the net release |
| `SubTx.NoUTxODepositDeclaration` | $0$; declaration requirements still apply |

Delegated contributions are already included in `declaredTxTotalNetUTxODepositChange`. Do
not subtract them as local contributions: they remain TopTx's responsibility. These
amounts are derived; no additional TopTx amount field is required. Unlike TopTx's own
UTxO capacity deposit contribution derived in DS-TX-ACCOUNTING-NET-CHANGE-TOPTX, `topTxNetUTxODepositChange` includes
delegated operations.

For a net-release transaction ($\text{declaredTxTotalNetUTxODepositChange}<0$), require:

| Derived TopTx amount | Required settlement |
| --- | --- |
| $\text{topTxNetRelease}=0$ | `NoTopTxSettlement` |
| $\text{topTxNetRelease}>0$ | `TopTxSettlementOutput index`, with the selected output containing at least $\text{topTxNetRelease}$ |

`txTotalNetRelease` is the net ADA amount transferred from the Store for the entire
transaction. `topTxNetRelease` is the amount to settle in TopTx's selected output. Net
allocations accounted for locally by SubTx bodies can make the latter larger than the former.
For example, a local SubTx net allocation of 3 ADA and TopTx's own release contribution
of 5 ADA give:

$$
\begin{aligned}
\text{declaredTxTotalNetUTxODepositChange}&=-2 \\
\text{txTotalNetRelease}&=2 \\
\text{topTxNetUTxODepositChange}&=-2-3=-5 \\
\text{topTxNetRelease}&=5
\end{aligned}
$$

TopTx declares `TopTx.DeclaresNetUTxODepositRelease 2 (TopTxSettlementOutput index)`.
The selected output must contain at least 5 ADA even though the net Store release
is 2 ADA. The remaining value must be funded within the balanced batch; local
accounting does not establish which body supplied those coins. Conversely, a
local SubTx net release of 5 ADA and a TopTx net allocation contribution of 3 ADA give
$\text{topTxNetUTxODepositChange}=3$ and $\text{topTxNetRelease}=0$; the declaration is
`TopTx.DeclaresNetUTxODepositRelease 2 NoTopTxSettlement`.

This settlement requirement applies to the `TopTx.DeclaresNetUTxODepositRelease` branch.
A net allocation or explicit zero still follows DS-TX-ACCOUNTING-NET-CHANGE-TOPTX and does not introduce a TopTx
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

<a id="ds-tx-settlement-participation-p01" name="ds-tx-settlement-participation-p01"></a>

###### 2.1.5.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L17) - TopTx settles its attributed release

$$
\text{PassesParticipation}
\iff(\text{usesNoTopTxSettlement}\iff\text{topTxNetRelease}=0)
$$

For exact net-release declarations, compare the isolated participation validator with the required selector derived independently from signed local contributions. $\text{topTxNetRelease}=0$ includes zero and positive attributed TopTx changes. A positive release share requires a selected TopTx output; destination and coverage are separate checks.

<a id="ds-tx-settlement-participation-n01" name="ds-tx-settlement-participation-n01"></a>

###### 2.1.5.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L18) - requires NoTopTxSettlement when SubTxs settle the entire net release locally

SubTx bodies settle the entire release locally, leaving no release share attributed to TopTx. The declaration therefore uses NoTopTxSettlement.

<a id="ds-tx-settlement-participation-n02" name="ds-tx-settlement-participation-n02"></a>

###### 2.1.5.1.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L19) - requires a TopTx settlement output when the batch declares a net release and TopTx has a positive share

The net-release transaction leaves a positive TopTx share. TopTx must identify the output that covers it.

<a id="ds-tx-settlement-participation-n03" name="ds-tx-settlement-participation-n03"></a>

###### 2.1.5.1.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L20) - accepts a net release settled across TopTx and SubTx outputs

One transaction can settle part of its release in SubTx outputs and the remainder in TopTx. Each destination must cover its own share.

<a id="ds-tx-settlement-participation-n04" name="ds-tx-settlement-participation-n04"></a>

###### 2.1.5.1.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L21) - allows TopTx's settlement amount to exceed the batch net release when SubTxs account for net allocations locally

A local SubTx allocation of 3 ADA can combine with TopTx’s 5 ADA release contribution. The Store releases only 2 ADA net, while the TopTx output must cover its derived 5 ADA share.

<a id="ds-tx-settlement-participation-f01" name="ds-tx-settlement-participation-f01"></a>

###### 2.1.5.1.6 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L22) - rejects NoTopTxSettlement when the batch declares a net release and TopTx has a positive share

A positive derived TopTx share remains after local SubTx accounting. NoTopTxSettlement would leave that share without its required destination.

<a id="ds-tx-settlement-participation-f02" name="ds-tx-settlement-participation-f02"></a>

###### 2.1.5.1.7 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L23) - rejects a TopTx settlement output when TopTx has no net release to settle

TopTx has no release share in this net-release transaction. Its declaration must use NoTopTxSettlement rather than designate an unnecessary output.

<a id="ds-tx-settlement-participation-n05" name="ds-tx-settlement-participation-n05"></a>

###### 2.1.5.1.8 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L24) - does not require a TopTx settlement output when the batch declares a net allocation

The transaction declares a net allocation, so its TopTx declaration has no release-settlement output. A delegated release can be absorbed by other allocations without a separate Store payment.

<a id="ds-tx-settlement-participation-n06" name="ds-tx-settlement-participation-n06"></a>

###### 2.1.5.1.9 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L25) - does not require a TopTx settlement output for an explicit-zero batch even when TopTx's derived accounting portion is negative

The transaction declares explicit zero. Even if the signed portion attributed to TopTx is negative, the net-release-only settlement selector is not introduced into this declaration form.

<a id="ds-tx-settlement-participation-n07" name="ds-tx-settlement-participation-n07"></a>

###### 2.1.5.1.10 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L26) - accepts NoTopTxSettlement when TopTx's attributed contribution is a net allocation

A local SubTx release of 5 ADA offsets TopTx's own allocation of 3 ADA: the batch declares a release of 2 ADA, TopTx attribution is $+3$ ADA, and $\text{topTxNetRelease}=0$. Accept NoTopTxSettlement; do not require attributed TopTx change itself to equal zero.

<a id="ds-tx-settlement-participation-n08" name="ds-tx-settlement-participation-n08"></a>

###### 2.1.5.1.11 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L27) - accepts correct release participation on the phase-2 failure path

Use both permitted participation branches with exact ordinary declarations and actual phase-2 failure. Their selectors are validated even though ordinary settlement outputs are not applied.

<a id="ds-tx-settlement-participation-f03" name="ds-tx-settlement-participation-f03"></a>

###### 2.1.5.1.12 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L28) - rejects incorrect release participation even when phase 2 fails

From N08 controls, omit a required TopTx selector or supply one when no TopTx release is attributed. Assert participation failure on the phase-2 failure path.

<a id="ds-tx-settlement-destination" name="ds-tx-settlement-destination"></a>

##### 2.1.5.2 Destination

> **Resolve the settlement index within the owning body’s regular outputs.**
>
> Valid index $\ne$ sufficient ADA. Coverage checks the selected output’s amount.

**Decision:** Agreed.

A settlement index selects an existing regular output in the body that owns the
index. For `SubTxSettlementOutput`, resolve it in that SubTx; for
`TopTxSettlementOutput`, resolve it in TopTx.

$$
0 \le \mathit{outputIndex} < |\mathrm{ownOutputs}(\mathit{body})|
$$

An input, another body's output and collateral return are outside this sequence.
A SubTx with no outputs has no valid local settlement index. It can explicitly
delegate its release, subject to the remaining requirements.

The selected output must separately satisfy DS-TX-SETTLEMENT-COVERAGE. Successful
index resolution does not establish sufficient ADA or financial balance.

<a id="ds-tx-settlement-destination-p01" name="ds-tx-settlement-destination-p01"></a>

###### 2.1.5.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L17) - Settlement indices belong to their own body

$$
\begin{aligned}
\text{PassesDestination}\iff\forall\,\text{selectedDestination}:\quad\\
0\le\text{selectedIndex}<\text{length(own regular outputs)}
\end{aligned}
$$

With otherwise valid participation, compare isolated index validation against $0\le\text{index}<\text{length(own regular outputs)}$ for both body levels. Include valid boundaries and invalid indices; being in range in another sequence is insufficient. Generate selected-output observations independently of production index resolution.

<a id="ds-tx-settlement-destination-f01" name="ds-tx-settlement-destination-f01"></a>

###### 2.1.5.2.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L18) - rejects an index outside the declaring body's output sequence

Use a settlement index beyond the owning body’s output sequence. The ledger must reject rather than ignore the destination or choose a replacement.

<a id="ds-tx-settlement-destination-f02" name="ds-tx-settlement-destination-f02"></a>

###### 2.1.5.2.3 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L19) - does not resolve a SubTx settlement index against TopTx outputs

A SubTx index is interpreted locally. An output with the same index in TopTx cannot satisfy that local target.

<a id="ds-tx-settlement-destination-f03" name="ds-tx-settlement-destination-f03"></a>

###### 2.1.5.2.4 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L20) - does not resolve a settlement index against collateral return

Collateral return is not an ordinary output in the settlement index space. Its value cannot repair an invalid ordinary target.

<a id="ds-tx-settlement-destination-f04" name="ds-tx-settlement-destination-f04"></a>

###### 2.1.5.2.5 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L21) - rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs

A local index cannot identify an output in an empty sequence. The transaction must reject this target rather than resolve it against another body’s outputs.

<a id="ds-tx-settlement-destination-n01" name="ds-tx-settlement-destination-n01"></a>

###### 2.1.5.2.6 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L22) - accepts the first and last own regular output as settlement destinations

For TopTx and SubTx separately, select index zero and the final valid index in an otherwise valid fixture. Resolve the selected output from its owning body; other output sequences do not affect validity.

<a id="ds-tx-settlement-destination-f05" name="ds-tx-settlement-destination-f05"></a>

###### 2.1.5.2.7 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L23) - does not resolve a TopTx settlement index against nested SubTx outputs

Choose an index outside TopTx's own outputs but inside a nested or concatenated output sequence. Reject it even when a SubTx output could cover the settlement amount.

<a id="ds-tx-settlement-destination-f06" name="ds-tx-settlement-destination-f06"></a>

###### 2.1.5.2.8 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L24) - does not resolve a SubTx settlement index against a sibling SubTx's outputs

Choose an index outside the declaring SubTx's own outputs but valid in a sibling. Sibling outputs cannot satisfy the declaring body's destination requirement.

<a id="ds-tx-settlement-destination-n02" name="ds-tx-settlement-destination-n02"></a>

###### 2.1.5.2.9 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L25) - accepts valid ordinary settlement destinations on the phase-2 failure path

Use correct own-output indices at both body levels in an otherwise valid transaction with actual phase-2 failure. Ordinary destination validation succeeds before collateral-only execution.

<a id="ds-tx-settlement-destination-f07" name="ds-tx-settlement-destination-f07"></a>

###### 2.1.5.2.10 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L26) - rejects an invalid ordinary settlement index even when phase 2 fails

Replace a valid N02 index with the first out-of-bounds index and assert the destination failure. Unapplied ordinary outputs do not excuse an invalid selector.

<a id="ds-tx-settlement-coverage" name="ds-tx-settlement-coverage"></a>

##### 2.1.5.3 Coverage

> **Require the selected output to contain its settlement amount.**
>
> Available output ADA $\ge$ settlement amount. External deposits do not count toward this bound.

**Decision:** Agreed.

Each designated output must contain at least its allocated settlement amount:

$$
\mathrm{applicationADA}(\mathit{settlementOutput})
\ge \mathrm{settlementAmount}(\mathit{body})
$$

Here `applicationADA` reads the full output ADA for an implicit output, and only
application ADA for a store-backed output, excluding its external deposit.

For a local SubTx release, use its declared amount. For TopTx, use the derived
`topTxNetRelease`, which can differ from the complete transaction's net release.
For a 5 ADA release settled as 3 ADA in SubTx and 2 ADA in TopTx, the selected TopTx
output needs at least 2 ADA: both 2 ADA and 4 ADA satisfy coverage; 1 ADA does not.

The output may contain additional funds. A store-backed output's external deposit
cannot satisfy this bound: only its application ADA is available in the output.
The output already contains the settlement amount; applying the transaction must
not credit it a second time under DS-STATE-EXECUTION.

Coverage is a lower bound, not an independent SubTx balance requirement. Fee exports
remain permitted under DS-TX-ACCOUNTING-BALANCE. The stronger local-settlement guarantee
remains a separate open question under DS-TX-SETTLEMENT-REFINEMENT.

<a id="ds-tx-settlement-coverage-p01" name="ds-tx-settlement-coverage-p01"></a>

###### 2.1.5.3.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L18) - Settlement outputs cover their release share

$$
\begin{aligned}
\text{PassesCoverage}\iff\forall\,\text{selectedOutput}:\quad\\
\text{applicationADA(selectedOutput)}\ge\text{settlementAmount(selectedOutput)}
\end{aligned}
$$

With valid participation and indices, compare the isolated coverage validator against independently derived settlement amounts and selected application ADA. Generate equality, surplus and shortfall for both body levels and output variants. Preserve batch conservation in ledger shortfall cases by accounting for the removed ADA elsewhere.

<a id="ds-tx-settlement-coverage-f01" name="ds-tx-settlement-coverage-f01"></a>

###### 2.1.5.3.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L19) - rejects a settlement output containing less ADA than its settlement amount

The selected output exists but contains less ADA than its allocated settlement amount. Valid index resolution alone is insufficient.

<a id="ds-tx-settlement-coverage-n01" name="ds-tx-settlement-coverage-n01"></a>

###### 2.1.5.3.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L20) - accepts a settlement output containing exactly its settlement amount

The selected output contains exactly its settlement share. Equality satisfies the coverage lower bound.

<a id="ds-tx-settlement-coverage-n02" name="ds-tx-settlement-coverage-n02"></a>

###### 2.1.5.3.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L21) - accepts a settlement output containing the settlement amount and additional funds

The selected output contains its settlement amount plus other funds. The rule is a lower bound and does not require equality.

<a id="ds-tx-settlement-coverage-f02" name="ds-tx-settlement-coverage-f02"></a>

###### 2.1.5.3.5 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L22) - rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference

The selected store-backed output’s application ADA is too small. Its externally held capacity deposit is unavailable to cover that settlement shortfall.

<a id="ds-tx-settlement-coverage-n03" name="ds-tx-settlement-coverage-n03"></a>

###### 2.1.5.3.6 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L23) - accepts a store-backed settlement output with application ADA equal to the settlement amount

A store-backed output’s application ADA equals its settlement amount. Its separately allocated capacity deposit neither increases nor reduces this coverage.

<a id="ds-tx-settlement-coverage-n04" name="ds-tx-settlement-coverage-n04"></a>

###### 2.1.5.3.7 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L24) - checks TopTx's derived settlement amount rather than the entire batch net release

Cover both directions: batch release 5 ADA with TopTx share 2 ADA accepts a 2 ADA TopTx output; batch release 2 ADA with TopTx share 5 ADA requires a 5 ADA TopTx output. F04 supplies the negative counterpart for confusing the smaller batch amount with the larger share.

<a id="ds-tx-settlement-coverage-n05" name="ds-tx-settlement-coverage-n05"></a>

###### 2.1.5.3.8 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L25) - accepts covered ordinary settlement outputs on the phase-2 failure path

With exact declarations and valid selectors, provide the required application ADA in selected outputs at both body levels. An actual phase-2 failure selects collateral effects after this ordinary check passes.

<a id="ds-tx-settlement-coverage-f03" name="ds-tx-settlement-coverage-f03"></a>

###### 2.1.5.3.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L26) - rejects insufficient ordinary settlement coverage even when phase 2 fails

Reduce a selected ordinary output below its independently required settlement amount in an N05 fixture, accounting for the removed ADA elsewhere to preserve conservation. Assert coverage failure despite phase-2 invalidity.

<a id="ds-tx-settlement-coverage-f04" name="ds-tx-settlement-coverage-f04"></a>

###### 2.1.5.3.10 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L27) - rejects a TopTx output that covers the batch release but not TopTx's larger attributed release

Use the local $+3$ ADA SubTx allocation and $-5$ ADA TopTx contribution: batch release is 2 ADA, but TopTx coverage requires 5 ADA. An output containing 2 ADA fails even though it covers the entire batch net release; keep conservation valid with the remaining ADA elsewhere.

<a id="ds-tx-application-assets" name="ds-tx-application-assets"></a>

#### 2.1.6 Application assets

> **Separate an output’s spendable value from its external storage deposit.**
>
> A store-backed output may contain zero application ADA; it still requires its full deposit.

**Decision:** Agreed.

A store-backed output may contain zero application ADA, including any of these cases:

- Native assets with no ADA.
- No application assets, with a datum or reference script.
- No application assets, datum or reference script, retaining its address.

Each output still requires the full allocated UTxO capacity deposit calculated under
DS-PRICING. Empty application assets do not make an output free to store: its address,
encoding and fixed overhead still enter the size-based formula. Creating it remains
subject to the explicit declaration and exact accounting requirements of DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS and
DS-TX-ACCOUNTING-NET-CHANGE-SUBTX.

This permission does not relax other output validation, including nonnegative asset
amounts, size limits or address validity. Implicit-deposit outputs retain their existing
minimum-coin requirements. A store-backed collateral return may also have zero
application value, provided the collateral funding and settlement rules hold; the
externally held UTxO capacity deposits do not count as its application coins.

<a id="ds-tx-application-assets-n01" name="ds-tx-application-assets-n01"></a>

##### 2.1.6.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L17) - accepts a store-backed output containing native assets and zero ADA

The output carries native assets but no application ADA. Its storage is paid through an exact external deposit, so an implicit minimum-ADA condition must not be imposed on its application value.

<a id="ds-tx-application-assets-n02" name="ds-tx-application-assets-n02"></a>

##### 2.1.6.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L18) - accepts empty application assets with a datum or reference script

Exercise datum-only and reference-script-only outputs as separate fixture cases, each with empty application assets. Their full accepted encodings determine their exact external deposits; output admissibility remains separate from pricing.

<a id="ds-tx-application-assets-n03" name="ds-tx-application-assets-n03"></a>

##### 2.1.6.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L19) - accepts a store-backed output containing only an address

Even an address-only output occupies priced storage. Empty application assets are permitted when its deposit and the remaining transaction requirements are satisfied.

<a id="ds-tx-application-assets-n04" name="ds-tx-application-assets-n04"></a>

##### 2.1.6.4 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L20) - accepts implicit outputs containing exactly their required minimum coin

For TopTx and SubTx separately, use an implicit output with exactly the minimum ADA required by its accepted size. Acceptance is the control for F01's one-lovelace shortfall; the store-backed exemption must not weaken implicit-output validation.

<a id="ds-tx-application-assets-f01" name="ds-tx-application-assets-f01"></a>

##### 2.1.6.5 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L21) - rejects implicit outputs one lovelace below their required minimum coin

At both body levels, reduce the exact-minimum implicit output of N04 by one lovelace and place that lovelace in another valid implicit output to preserve batch conservation. Assert the existing minimum-coin failure; the store-backed exemption must not reach implicit outputs.

<a id="ds-collateral" name="ds-collateral"></a>

### 2.2 Collateral

> **Validate collateral terms and derive the phase-2 failure settlement.**
>
> Validation may be required even when scripts succeed. State Execution determines whether collateral effects apply.

Both `ImplicitDepositTxOut` and `StoreBackedTxOut` are supported for collateral inputs and the collateral return. Representation, mixed input sets and absent returns are fixture axes across the responsibilities below. No separate collateral DepositStore declaration is introduced.

| Responsibility | Question answered |
| --- | --- |
| [Scope](#ds-collateral-scope) | When is collateral required? |
| [Authorization](#ds-collateral-authorization) | Are the inputs authorized for collateral use? |
| [Funding](#ds-collateral-funding) | Can collateral cover the return, deposit and minimum fee? |
| [Surplus](#ds-collateral-surplus) | Where do excess released deposits go? |
| [Total](#ds-collateral-total) | Is the optional declared total correct? |
| [Settlement](#ds-collateral-settlement) | What Store change follows from the inputs and return? |
| [Conservation](#ds-collateral-conservation) | Is all consumed value accounted for? |

<a id="ds-collateral-scope" name="ds-collateral-scope"></a>

#### 2.2.1 Scope

> **Determine when collateral validation is required.**
>
> Redeemers in TopTx or any SubTx trigger the requirement. Store operations alone do not.

**Decision:** Agreed. Redeemer presence activates the existing batch collateral requirement, independently of whether the scripts would succeed.

Require collateral and run the existing batch collateral validation whenever TopTx or any SubTx contains redeemers. The deposit funding, minimum collateral fee and supplied-total checks in `DS-COLLATERAL-FUNDING` and `DS-COLLATERAL-TOTAL` use this same scope. So do the existing key-locked eligibility and native-asset collateral checks. Store-backed outputs or ordinary DepositStore declarations alone do not activate the requirement.

Required payment-key witnesses, input resolution, return-output validity and the collateral-input count retain their existing independent checks. With no redeemers anywhere, do not run the gated funding or supplied-total comparison merely because collateral fields are supplied; still enforce those independent requirements. `DS-COLLATERAL-AUTHORIZATION` owns missing-witness rejection.

Validation scope and applied effects are different responsibilities. A batch whose scripts would succeed can still be rejected for invalid collateral. Ordinary success applies ordinary spending and Store operations without applying collateral-path effects; an accepted phase-2 failure applies collateral consumption and its specified return instead. `DS-STATE-EXECUTION` owns that selection and the requirement that rejection leave the accepted ledger state unchanged. The cases below remain deliberate executable placeholders, not evidence that these requirements have been implemented.

<a id="ds-collateral-scope-f01" name="ds-collateral-scope-f01"></a>

##### 2.2.1.1 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ScopeSpec.hs#L13) - rejects TopTx redeemers without collateral

Given real, correctly witnessed phase-2 scripts with redeemers only in TopTx and no collateral inputs, expect `NoCollateralInputs`. The requirement follows the redeemer's presence, not whether the script would ultimately succeed. Use a funded-collateral control and isolate the intended failure from missing scripts, bad redeemer indices or witness failures. An insufficient-collateral failure may also accompany empty collateral; this case does not require an exclusive singleton failure list.

<a id="ds-collateral-scope-f02" name="ds-collateral-scope-f02"></a>

##### 2.2.1.2 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ScopeSpec.hs#L14) - rejects SubTx redeemers without collateral even when TopTx has none

Given a correctly indexed redeemer only in a SubTx, omit collateral from the containing batch. Expect `NoCollateralInputs`, with otherwise valid scripts, witnesses and ordinary declarations and a funded-collateral acceptance control. Examining TopTx alone would miss the active requirement. Exercise both possible script outcomes; the trigger does not depend on the phase-2 result.

<a id="ds-collateral-scope-f03" name="ds-collateral-scope-f03"></a>

##### 2.2.1.3 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ScopeSpec.hs#L15) - rejects redeemers in both TopTx and SubTxs without collateral

Given real scripts with redeemers in TopTx and in one or more SubTxs, omit collateral while satisfying unrelated rules. Expect `NoCollateralInputs`; the presence of both locations cannot bypass the shared collateral requirement. This completes the location truth table and catches an incorrect exclusive-or trigger.

<a id="ds-collateral-scope-n01" name="ds-collateral-scope-n01"></a>

##### 2.2.1.4 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ScopeSpec.hs#L16) - does not require collateral merely because a transaction uses the DepositStore

Given otherwise valid ordinary Store operations with no redeemers anywhere in the batch, omit collateral. Its absence must not cause collateral rejection merely because outputs are store-backed or a body declares a Store operation.

<a id="ds-collateral-scope-n02" name="ds-collateral-scope-n02"></a>

##### 2.2.1.5 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ScopeSpec.hs#L17) - does not apply redeemer-gated funding or supplied-total checks when no body has redeemers

With no redeemers in TopTx or any SubTx, supply resolved collateral and a valid return while satisfying all independently applicable rules. Separately make the potential collateral coin fee too small, make the optional total unequal to input coins minus return coins, and combine those two conditions. Expect ordinary acceptance because these comparisons are redeemer-gated. The collateral fields do not activate their own trigger, and State Execution owns their unapplied effects on success.

<a id="ds-collateral-scope-f04" name="ds-collateral-scope-f04"></a>

##### 2.2.1.6 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ScopeSpec.hs#L18) - rejects independently invalid collateral inputs or returns without redeemers

With no redeemers anywhere, separately supply an unresolved collateral input, an implicit collateral return below its existing minimum, or more collateral inputs than the permitted count. Keep the ordinary transaction and all other collateral conditions valid and include a valid control for each row. Expect the respective existing input-resolution, output-minimum or collateral-count rejection. Skipping the redeemer-gated checks does not bypass these independently required checks; missing payment-key witnesses are covered by Authorization F02.

<a id="ds-collateral-authorization" name="ds-collateral-authorization"></a>

#### 2.2.2 Authorization

> **Preserve key-locked eligibility and required payment-key witnesses for collateral inputs.**
>
> Both output variants need the same authority; funding or a Store declaration cannot replace it.

**Decision:** Agreed. Collateral inputs retain the existing eligibility and witness requirements when their output representation changes. When collateral validation is active, the input must be key-locked; a valid script witness does not make a script-controlled input eligible. Separately, a key-controlled collateral input needs its required payment-key witness even when no redeemer activates collateral validation. Deposit funding and ordinary DepositStore declarations replace neither requirement.

Exercise implicit and store-backed collateral as fixture variants under the same existing authorization rules. Every rejection has a corresponding fully signed, key-controlled acceptance control. Keep ordinary input witnesses valid and use a separate collateral input, so a missing witness is attributable to collateral. `DS-COLLATERAL-CONSERVATION` separately owns native-asset conservation, while `DS-COLLATERAL-SCOPE` preserves the established validation trigger and independently applied checks.

<a id="ds-collateral-authorization-f01" name="ds-collateral-authorization-f01"></a>

##### 2.2.2.1 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AuthorizationSpec.hs#L13) - rejects a script-controlled collateral input when collateral validation applies

With redeemers activating collateral validation, supply otherwise funded collateral at a script-controlled address, using both output representations. Use the same script for an ordinary script purpose so its supplied witness is required and not extraneous. Expect `ScriptsNotPaidUTxO` even when that script would succeed. A correct capacity-deposit calculation or ordinary Store declaration cannot make that input eligible. Use a key-controlled, correctly witnessed input as the acceptance control and exercise both phase-2 outcomes.

<a id="ds-collateral-authorization-f02" name="ds-collateral-authorization-f02"></a>

##### 2.2.2.2 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AuthorizationSpec.hs#L14) - rejects a key-controlled collateral input whose required payment-key witness is missing

Use a separate, key-controlled collateral input whose payment key is not needed by any ordinary input, with otherwise valid funding and output requirements. Omit only that required payment-key witness and expect `MissingVKeyWitnessesUTXOW`. Exercise implicit and store-backed collateral, both phase-2 outcomes when redeemers are present, and an ordinary transaction with no redeemers. Restoring the correct witness must produce an accepted control. The redeemer trigger does not waive the independently required witness.

<a id="ds-collateral-funding" name="ds-collateral-funding"></a>

#### 2.2.3 Funding

> **Require collateral coins to cover the return, additional deposit and minimum fee.**
>
> Released deposits cover the return’s deposit first. Their surplus cannot fund the minimum fee or enlarge the return.

**Decision:** Agreed for a fixed pricing policy. Collateral coins must cover the specified return, any additional UTxO capacity deposit and the minimum collateral fee. Released capacity deposits first cover the return's deposit; their excess cannot fund the minimum fee or increase the signed return.

Use these quantities, derived from resolved collateral inputs and the specified return:

| Quantity | Meaning |
| --- | --- |
| `collateralInputCoins` | Sum of collateral output coins: the full ADA of each implicit input and only application ADA of each store-backed input. |
| `collateralReturnCoins` | Return output coins, or zero if no return is specified. |
| `releasedUTxODeposits` | Sum of allocated capacity deposits released by consumed store-backed inputs. Each implicit input contributes zero. |
| `collateralReturnUTxODeposit` | Capacity deposit for a store-backed return under `DS-PRICING`; zero for an absent or implicit return. |

An implicit minimum is already included in that output's coins; it must not also be counted as a released Store deposit. A fixed policy does not imply equal input and return deposits: their chargeable sizes can differ.

$$
\begin{aligned}
\mathrm{additionalUTxODeposit}
&=\max\left(0,\mathrm{collateralReturnUTxODeposit}-\mathrm{releasedUTxODeposits}\right) \\
\mathrm{collateralCoinFee}
&=\mathrm{collateralInputCoins}-\mathrm{collateralReturnCoins}-\mathrm{additionalUTxODeposit} \\
\mathrm{minimumCollateralFee}
&=\left\lceil\frac{\mathrm{txFee}\cdot\mathrm{collateralPercentage}}{100}\right\rceil \\
\mathrm{collateralCoinFee}&\geq\mathrm{minimumCollateralFee}
\end{aligned}
$$

All amounts in the following examples are ADA, with a minimum collateral fee of 1 ADA. The fee-credit column includes the released surplus defined in `DS-COLLATERAL-SURPLUS`; a sufficient fee credit does not establish sufficient coin funding.

| Input coins | Return coins | Released deposit | Return deposit | Additional deposit | Released surplus | Fee credit | Funding result |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 5 | 3 | 2 | 1 | 0 | 1 | 3 | Funded |
| 5 | 3 | 1 | 2 | 1 | 0 | 1 | Funded |
| 5 | 4 | 1 | 2 | 1 | 0 | 0 | Reject |
| 5 | 5 | 2 | 1 | 0 | 1 | 1 | Reject: coin fee below minimum |

The signed transaction must already contain enough funding. The ledger cannot reduce the specified return or select extra inputs to repair a shortfall. Funded collateral still has to satisfy every other applicable rule, including native-asset conservation and the existing implicit minimum when the return uses that variant. A store-backed return may contain zero application ADA when its external deposit and the minimum fee are funded; that deposit is not application value.

These checks apply whenever `DS-COLLATERAL-SCOPE` activates collateral validation, even if scripts would succeed or the optional total is absent. On ordinary success the amounts describe the collateral terms that were validated, not transfers that were applied. Accepted failure-path fixtures use a real failing script and the matching phase-2-invalid marker.

Output variants, mixed inputs and absent returns are fixture axes within these requirements, not separate validation rules. Funding owns required amounts and the resulting acceptance or rejection; State owns applied Store balances and allocation records. Repricing after parameter changes remains deferred.

<a id="ds-collateral-funding-f01" name="ds-collateral-funding-f01"></a>

##### 2.2.3.1 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L42) - rejects insufficient collateral funding when redeemers trigger validation even if all scripts succeed

Given redeemers whose scripts would all succeed, make the collateral coins insufficient for the return, additional deposit and minimum fee. Expect collateral validation to reject the batch before script success could excuse that deficit.

<a id="ds-collateral-funding-n01" name="ds-collateral-funding-n01"></a>

##### 2.2.3.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L43) - accepts a batch whose scripts succeed when its required collateral is fully funded and all other rules hold

Given successful scripts and collateral that covers the signed return, any additional deposit and the minimum fee, expect acceptance when all other rules hold. `DS-STATE-EXECUTION` separately requires the accepted ordinary path to leave collateral-path effects unapplied.

<a id="ds-collateral-funding-n02" name="ds-collateral-funding-n02"></a>

##### 2.2.3.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L44) - accepts funded collateral with implicit or store-backed inputs and returns

Construct otherwise valid funded collateral using pure implicit, pure store-backed and mixed input sets, paired with an implicit return, a store-backed return or no return. Expect acceptance for each applicable combination and both script outcomes. No-return acceptance fixtures are ADA-only; token-bearing acceptance is specified under `DS-COLLATERAL-CONSERVATION-N02`. Retain each variant's output and witness checks rather than treating representation as an eligibility restriction.

<a id="ds-collateral-funding-n03" name="ds-collateral-funding-n03"></a>

##### 2.2.3.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L45) - reuses released UTxO capacity deposits when the collateral return requires the same amount

Given a return whose required capacity deposit equals the deposits released by consumed collateral, expect no additional coin-funded deposit and no released-deposit surplus. Reusing that released amount must leave the collateral coins available for the return coins and independently required fee.

<a id="ds-collateral-funding-n04" name="ds-collateral-funding-n04"></a>

##### 2.2.3.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L47) - funds additional return UTxO capacity deposits from collateral coins

Use the second funded row of the funding table, where the return requires more capacity deposit than the inputs release. Expect collateral coins to cover exactly that positive difference, leaving the required minimum coin fee after the signed return is funded.

<a id="ds-collateral-funding-f02" name="ds-collateral-funding-f02"></a>

##### 2.2.3.6 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L67) - rejects collateral coins below the minimum fee after funding the return and additional UTxO capacity deposits

Use the third row of the funding table: paying the return and additional deposit leaves no coin fee. Expect rejection even though those two obligations are covered; the ledger cannot repair the deficit by changing the return or choosing another input.

<a id="ds-collateral-funding-p01" name="ds-collateral-funding-p01"></a>

##### 2.2.3.7 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L73) - Collateral coins cover the minimum

$$
\begin{aligned}
&\text{Accepted}\land\text{redeemers}\ne\varnothing\\
&\implies\text{collateralCoinFee}\ge
\lceil\text{txFee}\cdot\text{collateralPercentage}/100\rceil
\end{aligned}
$$

For every accepted batch with redeemers in any body, independently subtract the specified return coins and positive deposit shortfall from the input coins. The remainder must meet the ceiling of the transaction fee times the collateral percentage; adding released-deposit surplus must not alter that comparison. Cover both successful scripts and accepted phase-2 failure, with acceptance coverage in each outcome. On success inspect the validated collateral terms, without asserting that collateral effects were applied. Batches without redeemers are outside this implication.

<a id="ds-collateral-funding-f03" name="ds-collateral-funding-f03"></a>

##### 2.2.3.8 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L75) - rejects collateral whose minimum fee depends on released UTxO capacity deposit surplus

In the fourth funding-table row, the released surplus would credit 1 ADA to fees while the collateral coin fee is zero. ADA still balances as $5+2=5+1+1$, but the 1 ADA minimum must be funded by coins, so expect rejection.

<a id="ds-collateral-funding-f04" name="ds-collateral-funding-f04"></a>

##### 2.2.3.9 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L84) - rejects a collateral return whose funding depends on released UTxO capacity deposit surplus

Given released-deposit surplus, enlarge the signed return so it is affordable only if that surplus is treated as return funding. For example, 5 ADA of input coins, 6 ADA of return coins, 3 ADA of released deposits and a 1 ADA return deposit could balance with a 1 ADA aggregate fee, but the independently computed coin fee is negative. Omit the optional total in this fixture so its nonnegative field cannot introduce a second mismatch. Expect funding rejection: released surplus cannot supply return coins. Use a smaller, fully funded signed return as the acceptance control.

<a id="ds-collateral-funding-f05" name="ds-collateral-funding-f05"></a>

##### 2.2.3.10 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L86) - rejects collateral funding one lovelace below a rounded-up minimum fee

Choose a ledger-valid transaction fee and collateral percentage whose product is not divisible by 100; an odd lovelace fee at 150 percent gives a fractional result. Begin with a coin fee exactly equal to its independently calculated ceiling, then reduce collateral input coins by one lovelace while holding the specified return, required deposits and transaction fee fixed. Keep the optional total absent or correctly updated. Expect funding rejection for the resulting floor amount, with no rounding tolerance or repair of the transaction. `DS-COLLATERAL-FUNDING-N08` owns acceptance at the same ceiling boundary.

<a id="ds-collateral-funding-n05" name="ds-collateral-funding-n05"></a>

##### 2.2.3.11 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L95) - counts implicit collateral inputs' full ADA as coins and zero released Store deposits when mixed with store-backed inputs

Given a mixture of implicit and store-backed collateral inputs, count an implicit input's entire ADA in `collateralInputCoins` and none in `releasedUTxODeposits`. Expect funding to use only the allocated deposits of the store-backed inputs, preventing an implicit minimum from becoming a second source of funds.

<a id="ds-collateral-funding-n06" name="ds-collateral-funding-n06"></a>

##### 2.2.3.12 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L96) - requires zero Store deposit for an implicit collateral return even with store-backed collateral inputs

Given store-backed collateral inputs and an implicit return, expect the return's required Store deposit to be zero while counting its full ADA as return coins. This is an observation of the funding requirement, not an assertion about applied allocation records. The return must still satisfy its existing implicit minimum, and any released deposits follow `DS-COLLATERAL-SURPLUS`; State Allocations owns the absence of a return Store record.

<a id="ds-collateral-funding-n07" name="ds-collateral-funding-n07"></a>

##### 2.2.3.13 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L97) - accepts a store-backed collateral return with zero application ADA when its deposit and the minimum fee are funded

Given a store-backed return with zero application ADA, provide enough collateral to fund its full size-based deposit and the minimum collateral fee. Expect acceptance when the other rules hold: the deposit remains external to application value, and zero application ADA does not waive its storage cost.

<a id="ds-collateral-funding-f06" name="ds-collateral-funding-f06"></a>

##### 2.2.3.14 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L98) - rejects underfunded collateral when the optional total is absent

Given active collateral validation and an absent optional total, provide underfunded collateral. Expect rejection from the funding rule after the total is derived from inputs and return; omitting a declaration cannot supply the missing coins.

<a id="ds-collateral-funding-n08" name="ds-collateral-funding-n08"></a>

##### 2.2.3.15 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L99) - accepts collateral funding exactly at a rounded-up minimum fee

Use the same ledger-valid fee and percentage as F05, whose product divided by 100 has a fractional lovelace. After funding the specified return and any additional capacity deposit, leave exactly the independently calculated ceiling as the coin fee. Expect acceptance with all other rules satisfied, for successful scripts and an accepted phase-2 failure. No extra lovelace beyond that ceiling is required. Together with F05 this distinguishes the exact ceiling from both floor rounding and an overly strict lower bound.

<a id="ds-collateral-surplus" name="ds-collateral-surplus"></a>

#### 2.2.4 Surplus

> **Send excess released collateral deposits to fees on an accepted phase-2 failure.**
>
> Released excess $\longrightarrow$ fee pot. Unrelated surplus already held in the Store remains untouched.

**Decision:** Agreed for a fixed pricing policy. After released collateral capacity deposits cover the return's required deposit, all excess goes to the fee pot on an accepted phase-2 failure. It does not directly credit the treasury, fund a larger collateral return or reduce the independently funded minimum in `DS-COLLATERAL-FUNDING`.

$$
\begin{aligned}
\mathrm{releasedUTxODepositFee}
&=\max\left(0,\mathrm{releasedUTxODeposits}-\mathrm{collateralReturnUTxODeposit}\right) \\
\mathrm{collateralFee}
&=\mathrm{collateralCoinFee}+\mathrm{releasedUTxODepositFee} \\
\mathrm{feesAfter}
&=\mathrm{feesBefore}+\mathrm{collateralFee} \\
\mathrm{treasuryAfter}&=\mathrm{treasuryBefore}
\end{aligned}
$$

Only excess released by the consumed collateral inputs is transferred. An unrelated surplus already held in the Store is untouched; `DS-STATE-BALANCE` owns the applied Store balance and preserved solvency margin. No collateral transfer occurs on ordinary success, as specified by `DS-STATE-EXECUTION`.

<a id="ds-collateral-surplus-n01" name="ds-collateral-surplus-n01"></a>

##### 2.2.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/SurplusSpec.hs#L43) - credits excess released UTxO capacity deposits to fees rather than the treasury

Use the first funded row of the funding table, where released capacity deposits exceed the return's requirement. On an accepted phase-2 failure, expect the entire excess to join the coin fee in the fee pot, with no direct treasury credit.

<a id="ds-collateral-surplus-p01" name="ds-collateral-surplus-p01"></a>

##### 2.2.4.2 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/SurplusSpec.hs#L78) - Released surplus reaches fees

$$
\begin{aligned}
&\text{Accepted phase-2 failure}\\
&\implies\text{feesAfter}=\text{feesBefore}+\text{collateralCoinFee}+\text{releasedUTxODepositFee}
\end{aligned}
$$

For every accepted phase-2 failure, calculate the coin fee and positive released-deposit surplus independently from the collateral fixture. Compare their sum with the actual fee-pot increase, so omitted surplus or an unrelated Store surplus cannot be hidden by a model-only identity.

<a id="ds-collateral-surplus-p02" name="ds-collateral-surplus-p02"></a>

##### 2.2.4.3 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/SurplusSpec.hs#L79) - Treasury remains unchanged

$$
\text{Accepted phase-2 failure}\implies\text{treasuryAfter}=\text{treasuryBefore}
$$

Capture the treasury immediately before applying an accepted phase-2 failure. Expect exactly the same treasury afterward, even when collateral releases excess capacity deposits; their direct destination is the fee pot.

<a id="ds-collateral-total" name="ds-collateral-total"></a>

#### 2.2.5 Total

> **Check the optional declared total against the coins taken from collateral.**
>
> Declared total $=$ input coins $-$ return coins. Released Store deposits are excluded; additional deposits funded from input coins are included.

**Decision:** Agreed. The existing optional `dtbrTotalCollateral` declares coins taken from collateral inputs after subtracting the specified return. It includes additional deposits funded from those coins and excludes capacity deposits released from the Store; it is not a declaration of the eventual fee credit.

Within the validation scope of `DS-COLLATERAL-SCOPE`, enforce:

$$
\begin{aligned}
\mathrm{computedTotalCollateral}
&=\mathrm{collateralInputCoins}-\mathrm{collateralReturnCoins} \\
\mathrm{dtbrTotalCollateral}=\mathrm{SJust}(\mathrm{amount})
&\Longrightarrow\mathrm{amount}=\mathrm{computedTotalCollateral} \\
\mathrm{collateralCoinFee}
&=\mathrm{computedTotalCollateral}-\mathrm{additionalUTxODeposit} \\
\mathrm{collateralFee}
&=\mathrm{collateralCoinFee}+\mathrm{releasedUTxODepositFee}
\end{aligned}
$$

For example, input coins of 5 ADA and a return of 2 ADA require a declared total of 3 ADA. A 1 ADA deposit shortfall leaves 2 ADA for the collateral coin fee; if there is released-deposit surplus instead, that surplus increases the fee credit separately under `DS-COLLATERAL-SURPLUS`.

Reject every supplied amount that differs from the computed total, including when scripts would succeed. If the field is absent, derive the total from the inputs and return and omit only the supplied-value comparison. `DS-COLLATERAL-TOTAL-N04` owns valid omission. Absence does not bypass deposit funding or the minimum fee: `DS-COLLATERAL-FUNDING-F06` owns that rejection, and other applicable collateral validation requirements remain in force. Acceptance fixtures cover both script outcomes while satisfying all other collateral and ordinary validation requirements.

<a id="ds-collateral-total-n01" name="ds-collateral-total-n01"></a>

##### 2.2.5.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L13) - accepts a declared total equal to collateral input coins minus return coins

Given input coins and a specified return, supply exactly their difference as the optional total and satisfy all other collateral rules. Expect no total-mismatch rejection; the 5 ADA input and 2 ADA return example requires 3 ADA regardless of the separate deposit adjustment.

<a id="ds-collateral-total-f01" name="ds-collateral-total-f01"></a>

##### 2.2.5.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L14) - rejects a declared total differing by one lovelace when collateral validation applies

With collateral validation active and funding otherwise correct, supply a total one lovelace away from the input-minus-return amount. Expect rejection for either direction of error; adequate collateral funding does not make an inexact declaration acceptable.

<a id="ds-collateral-total-f02" name="ds-collateral-total-f02"></a>

##### 2.2.5.3 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L15) - rejects an incorrect supplied total when redeemers trigger collateral validation even if all scripts succeed

Given redeemers whose scripts would succeed and otherwise valid collateral, supply an incorrect total. Expect rejection under the same equality used on the failure path, because script outcome does not change the validation scope.

<a id="ds-collateral-total-n02" name="ds-collateral-total-n02"></a>

##### 2.2.5.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L16) - includes coins funding additional UTxO capacity deposits in the declared total

In the 5 ADA input and 2 ADA return example, require an additional capacity deposit of 1 ADA. Expect a declared total of 3 ADA while only 2 ADA remains as the coin fee, demonstrating that the coins allocated to the Store remain part of the total.

<a id="ds-collateral-total-n03" name="ds-collateral-total-n03"></a>

##### 2.2.5.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L17) - excludes UTxO capacity deposits released from the Store from the declared total

Given excess capacity deposits released from the Store, hold collateral input and return coins fixed. Expect the declared total to remain their difference even though the surplus increases the eventual fee credit; the externally held deposit was never part of the input coins.

<a id="ds-collateral-total-n04" name="ds-collateral-total-n04"></a>

##### 2.2.5.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L18) - accepts an absent optional total when collateral validation applies and all collateral rules hold

With redeemers activating validation, omit the optional total and supply otherwise valid collateral. Expect acceptance with successful scripts and with a real accepted phase-2 failure. Include a funded store-backed return with additional deposit funding, a released-deposit surplus, and a valid no-return case; implicit returns retain their existing minimum. Derive input coins minus return coins internally without requiring the sender to supply it. Funding F06 separately proves that omission cannot waive funding.

<a id="ds-collateral-settlement" name="ds-collateral-settlement"></a>

#### 2.2.6 Settlement

> **Derive the collateral Store change from consumed inputs and the specified return.**
>
> Required return deposit $-$ released input deposits $=$ Store change. No separate collateral declaration is needed.

**Decision:** Agreed. The ledger derives collateral Store settlement from resolved collateral inputs and the specified return, using the allocated and required deposit amounts in `DS-COLLATERAL-FUNDING`:

$$
\mathrm{collateralStoreChange}
=\mathrm{collateralReturnUTxODeposit}-\mathrm{releasedUTxODeposits}
$$

A positive change increases the Store balance; a negative change decreases it. There is no separate collateral DepositStore operation field. The optional total retains its input-minus-return meaning under `DS-COLLATERAL-TOTAL` and does not declare this Store change.

Holding collateral inputs, return, fee and pricing policy fixed, ordinary TopTx and SubTx Store declarations cannot change the derived collateral settlement. Full-ledger comparisons must vary independently valid ordinary transactions: declarations still undergo their own validation, even when their effects will not be applied. Adjust accompanying ordinary inputs, outputs and declarations consistently without changing the fixed collateral terms.

Ordinary release destinations and output creation cannot be applied unchanged to a phase-2 failure: settlement uses only the collateral effects selected by `DS-STATE-EXECUTION`. Success applies ordinary effects; an accepted phase-2 failure applies collateral effects; rejection applies neither and preserves the accepted ledger state atomically.

`DS-STATE-BALANCE` checks the resulting Store balance against the derived change. `DS-STATE-ALLOCATIONS` checks consumed collateral records, the return's record when store-backed, preserved unrelated records and the matching change in outstanding deposit obligations. These state assertions are separate from deriving the settlement amount.

<a id="ds-collateral-settlement-n01" name="ds-collateral-settlement-n01"></a>

##### 2.2.6.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/SettlementSpec.hs#L14) - derives Store changes from collateral inputs and return without a separate declaration

Given resolved collateral inputs and a specified return, provide no separate collateral Store operation declaration. Expect the derived change to equal the return's required deposit minus the allocated deposits released by those inputs; the existing optional total does not replace or encode this derivation.

<a id="ds-collateral-settlement-p01" name="ds-collateral-settlement-p01"></a>

##### 2.2.6.2 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/SettlementSpec.hs#L15) - derived collateral Store change is independent of ordinary Store declarations

Generate paired cases with collateral inputs, return, fee and pricing policy fixed while varying ordinary TopTx and SubTx Store declarations. Expect the derived Store change to remain identical. For full-ledger observations, make each ordinary variant independently valid and fund any associated ordinary output changes consistently; an invalid ordinary declaration may reject the transaction and is not a counterexample to this derivation property. Inspect the derived amount here. State Execution separately checks that unapplied ordinary operations cannot fund or redirect the selected collateral effects.

<a id="ds-collateral-settlement-n02" name="ds-collateral-settlement-n02"></a>

##### 2.2.6.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/SettlementSpec.hs#L16) - derives the released Store amount from multiple ADA-only collateral inputs with no return

Given several ADA-only collateral inputs and no return output, use an otherwise valid, funded fixture containing implicit and store-backed inputs. The required return deposit is zero, so expect the derived Store change to equal the negative sum of allocated deposits from only the store-backed inputs. Implicit input coins do not create a Store release. Funding owns the independent minimum, Surplus owns the actual fee credit, and State owns applied record removal and balance changes. Token-bearing inputs without a return are rejected under `DS-COLLATERAL-CONSERVATION-F02`.

<a id="ds-collateral-conservation" name="ds-collateral-conservation"></a>

#### 2.2.7 Conservation

> **Account for all value consumed by collateral settlement.**
>
> $\text{Input coins}+\text{released deposits}=\text{return coins}+\text{return deposit}+\text{fees}$. Native assets must also be conserved.

**Decision:** Agreed. An accepted collateral settlement must conserve ADA across collateral outputs, the Store and the fee pot:

$$
\begin{aligned}
&\mathrm{collateralInputCoins}+\mathrm{releasedUTxODeposits} \\
&\qquad=\mathrm{collateralReturnCoins}+\mathrm{collateralReturnUTxODeposit}+\mathrm{collateralFee}
\end{aligned}
$$

The ADA variables include only effects actually applied after an accepted phase-2 failure. Store-held capacity deposits must not be counted again as output coins. Use independently obtained fixture inputs and observed applied effects; a formula evaluated entirely inside the reference model does not establish conservation.

Native-asset collateral validation has a different observation scope: whenever the redeemer trigger is active, every asset and quantity in the collateral inputs must appear exactly in the return, regardless of the eventual script outcome. Both output variants permit token-bearing collateral when this equality holds. With no return, every collateral input must be ADA-only. Correct ADA funding cannot excuse missing, added or changed native assets; conversely, the presence of native assets alone must not cause rejection.

Conservation does not determine fee destination, prove adequate minimum funding or validate a supplied total. Those obligations remain in `DS-COLLATERAL-SURPLUS`, `DS-COLLATERAL-FUNDING` and `DS-COLLATERAL-TOTAL`. `DS-STATE-CONSERVATION` owns conservation across the whole ledger, while `DS-STATE-EXECUTION` excludes unapplied ordinary effects and preserves rejected state.

<a id="ds-collateral-conservation-n01" name="ds-collateral-conservation-n01"></a>

##### 2.2.7.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ConservationSpec.hs#L13) - conserves ADA for mixed collateral inputs when return storage needs an additional deposit

Use the deposit-shortfall funding example with mixed collateral inputs: 2 ADA in an implicit input plus 3 ADA of application coins in a store-backed input with a 1 ADA recorded deposit, and a store-backed return containing 3 ADA with a 2 ADA required deposit. With a 1 ADA minimum, require acceptance of the real phase-2 failure. Compare independently known input amounts with the applied return, return deposit and fee increase: $5+1=3+2+1$. This concrete regression catches counting implicit minimum ADA as an external deposit or counting the store-backed deposit twice; P01 supplies the broader generated coverage.

<a id="ds-collateral-conservation-p01" name="ds-collateral-conservation-p01"></a>

##### 2.2.7.2 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ConservationSpec.hs#L14) - Collateral settlement conserves ADA

$$
\begin{aligned}
&\text{Accepted phase-2 failure}\\
&\implies\text{collateralInputCoins}+\text{releasedUTxODeposits}\\
&\qquad=\text{collateralReturnCoins}+\text{collateralReturnUTxODeposit}+\text{collateralFee}
\end{aligned}
$$

Across accepted phase-2 failures, obtain expected input coins and allocated deposits independently from the fixture, then compare them with the actually applied return, deposit and fee effects. Equality must hold for surplus, equal deposits, shortfall, mixed input variants and absent returns; the fourth funding-table row shows why this equality alone cannot justify acceptance.

<a id="ds-collateral-conservation-f01" name="ds-collateral-conservation-f01"></a>

##### 2.2.7.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ConservationSpec.hs#L15) - rejects missing, added or changed native assets in the collateral return

Begin with the balanced token-bearing acceptance control from N02, then separately remove an asset, add an asset absent from all inputs, or change an existing quantity. Keep return-output validity, deposit pricing, coin funding, optional total and witnesses correct after each mutation so the asset mismatch is the intended failure. Expect `CollateralContainsNonADA` for both output variants and for successful scripts as well as a real failing phase-2 script. A sufficient ADA fee or released deposit cannot compensate for any native-asset imbalance.

<a id="ds-collateral-conservation-n02" name="ds-collateral-conservation-n02"></a>

##### 2.2.7.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ConservationSpec.hs#L16) - accepts native-asset collateral when its return preserves every asset and quantity

Use multiple collateral inputs carrying native assets and return their exact aggregate asset map, including every policy, asset name and quantity. Keep ADA funding, authority and the optional total valid. Expect acceptance for implicit and store-backed inputs and returns, including mixed inputs and a funded store-backed return with zero application ADA. Exercise successful scripts and accepted phase-2 failure. The former checks validation without applying the return; the latter permits observing that all collateral assets were actually returned. This is the valid control for F01 and rules out an implementation that rejects all token-bearing collateral.

<a id="ds-collateral-conservation-f02" name="ds-collateral-conservation-f02"></a>

##### 2.2.7.5 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/ConservationSpec.hs#L17) - rejects token-bearing collateral when no return is specified

Use otherwise authorized and sufficiently funded collateral containing at least one native asset, but omit the return entirely. Expect `CollateralContainsNonADA` under active collateral validation, for both script outcomes and both input representations. No ordinary output or unapplied ordinary mint or burn can supply the missing collateral return. Replacing the fixture with ADA-only collateral gives the valid no-return control owned by Settlement N02; returning all assets gives N02's token-bearing control.

<a id="section-1-3" name="section-1-3"></a>
<a id="ds-state" name="ds-state"></a>

## 3. Ledger effects

> **Check the ledger state produced by each execution outcome.**
>
> Correct declarations must lead to correct state updates. Recorded obligations and actual Store ADA remain distinct.

| Responsibility | Question answered |
| --- | --- |
| [Execution](#ds-state-execution) | Which effects apply? |
| [Allocations](#ds-state-allocations) | Which deposit belongs to each live output? |
| [Balance](#ds-state-balance) | How much actual ADA enters or leaves the Store? |
| [Solvency](#ds-state-solvency) | Does Store ADA cover the outstanding deposits? |
| [Conservation](#ds-state-conservation) | Is total ledger ADA preserved? |
| [Initialization](#ds-state-initialization) | What state does the upgrade establish? |
| [Recovery](#ds-state-recovery) | Do restoration and rollback preserve consistent state? |

<a id="ds-state-execution" name="ds-state-execution"></a>

### 3.1 Execution

> **Select which effects may change the ledger.**
>
> Ordinary success applies ordinary effects; accepted phase-2 failure applies collateral effects; rejection applies neither.

**Decision:** Agreed.

Apply only the effects selected by the transaction's ledger outcome. An accepted transaction whose phase-2 scripts fail is distinct from a rejected transaction:

| Outcome | Ordinary inputs, outputs and Store operations | Collateral inputs, return and derived settlement |
| --- | --- | --- |
| Ordinary success | Applied | Unapplied |
| Accepted phase-2 failure | Unapplied | Applied |
| Rejection | Unapplied | Unapplied |

Collateral validation can still be required before ordinary success; this table determines which effects are applied, not when collateral must be supplied. `DS-COLLATERAL-SCOPE` defines that requirement and `DS-COLLATERAL-SETTLEMENT` derives its Store adjustment.

For an ordinary successful batch, include the regular effects of TopTx and every SubTx:

$$
\begin{aligned}
\text{utxoAfter}
&= \text{removeInputs}(\text{utxoBefore},\text{regularInputs}) \\
&\quad \cup \text{newRegularOutputsWithUTxODeposits}
\end{aligned}
$$

On an accepted phase-2 failure, consume only collateral inputs and create only the specified collateral return. Ordinary and collateral input roles need not be disjoint: a shared input is consumed once through the selected outcome. On ordinary success, inputs used only as collateral remain live; on accepted phase-2 failure, ordinary inputs outside the collateral set remain live. Branch selection does not promise preservation of an input also consumed in the applied role.

UTxO entries, their allocated amounts and the Store balance must settle atomically for the chosen outcome. A rejected batch preserves the entire previously accepted ledger state, including all three; no partially applied result is an accepted state.

A selected settlement output already contains its settlement amount in the submitted transaction. Applying the accepted transaction does not add that amount again. Exact contribution, destination and conservation checks remain separate prerequisites.

<a id="ds-state-execution-p01" name="ds-state-execution-p01"></a>

#### 3.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ExecutionSpec.hs#L11) - Apply ordinary UTxO effects

$$
\text{ordinary success} \implies
\text{UTxO after} =
\left(\text{UTxO before} \setminus \text{ordinary inputs}\right)
\cup \text{created ordinary outputs}
$$

Given an accepted ordinary batch, remove the regular inputs consumed by TopTx and its SubTxs and add their new regular outputs with allocated-deposit metadata. Compare the resulting ledger UTxO with that independently constructed result.

<a id="ds-state-execution-n01" name="ds-state-execution-n01"></a>

#### 3.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ExecutionSpec.hs#L12) - applies ordinary effects and no collateral effects on success, including when input roles overlap

Given an ordinary successful transaction that also supplies collateral, apply its ordinary Store operations without applying collateral settlement or creating the collateral return. Include a key-controlled input shared by ordinary spending and collateral: consume it as an ordinary input and release its recorded deposit once. Inputs used only as collateral remain live. Supplying or validating collateral creates no additional effects.

<a id="ds-state-execution-n02" name="ds-state-execution-n02"></a>

#### 3.1.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ExecutionSpec.hs#L13) - applies collateral settlement and no ordinary Store operations on an accepted phase-2 failure

Given an accepted phase-2 failure with ordinary Store declarations, apply the derived collateral settlement and no ordinary Store operations. Ordinary declarations remain subject to validation, but cannot contribute funds to, or change, the applied collateral effects.

<a id="ds-state-execution-n03" name="ds-state-execution-n03"></a>

#### 3.1.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ExecutionSpec.hs#L14) - consumes only collateral inputs and creates only the specified collateral return in the UTxO on an accepted phase-2 failure

Given an accepted phase-2 failure, remove only the collateral inputs and create only the specified collateral return. Include a key-controlled input shared by ordinary spending and collateral: consume it once as collateral. Ordinary inputs outside the collateral set remain live and ordinary outputs are not created. Cover absent, implicit and store-backed returns.

<a id="ds-state-execution-n04" name="ds-state-execution-n04"></a>

#### 3.1.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ExecutionSpec.hs#L15) - does not credit the settlement amount to the selected output a second time

Given an accepted release whose selected output already includes its settlement amount, create that output with the submitted value. Adding another settlement credit during application would count the release twice.

<a id="ds-state-execution-f01" name="ds-state-execution-f01"></a>

#### 3.1.6 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ExecutionSpec.hs#L16) - leaves the entire ledger state unchanged when a later body rejects a batch after earlier SubTx processing

Start with an accepted control batch containing multiple bodies. Make a later body invalid after an earlier SubTx can contribute candidate effects. Compare the complete accepted ledger state before submission and after rejection, including UTxO entries, allocated records, Store balance, other monetary pots and derived distributions. No earlier candidate effect may survive rejection.

<a id="ds-state-execution-p02" name="ds-state-execution-p02"></a>

#### 3.1.7 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ExecutionSpec.hs#L17) - Preserve state on rejection

$$
\text{transaction rejected} \implies
\text{ledger state after} = \text{ledger state before}
$$

Across rejected batches, require the resulting accepted ledger state to equal the prior accepted state. This invariant distinguishes rejection from an accepted phase-2 failure, which legitimately applies collateral effects.

<a id="ds-state-allocations" name="ds-state-allocations"></a>

### 3.2 Allocations

> **Track the deposit attached to each live store-backed output.**
>
> Creation records it; consumption releases it exactly once; reference use leaves it unchanged.

**Decision:** Agreed.

Every live store-backed output retains exactly one recoverable allocated UTxO capacity deposit amount associated with its `TxIn`. Every live allocated amount is nonnegative. Treat `utxoDepositRecords` as a logical map; its domain is exactly the live store-backed UTxO, and its sum is the outstanding obligation:

$$
\begin{aligned}
&\text{keys}(\text{utxoDepositRecords}(\text{state})) \\
&\quad = \{\,\text{txIn} \mid
  \text{UTxO}(\text{state})[\text{txIn}]\text{ is store-backed}\,\}
\end{aligned}
$$

$$
\text{totalUTxODeposits}(\text{utxo}(\text{state}))
= \sum_{\text{txIn}\in\text{keys}(\text{utxoDepositRecords}(\text{state}))}
  \text{utxoDepositRecords}(\text{state})[\text{txIn}]
$$

Creating a store-backed output establishes its amount using `DS-PRICING`. Consuming it releases that allocated amount exactly once and removes its record. Reference inputs leave the amount unchanged and release nothing. Implicit outputs, including outputs preserved by the Conway upgrade, have no Store obligation and release no Store deposit when consumed.

The ledger retains the allocation map and its funding in `UTxOState`:

```haskell
data DepositStore = DepositStore
  { depositStoreBalance :: Coin
  , depositStoreAllocations :: Map TxIn Coin
  }
```

A `TxIn` identifies both the live output and its allocation record. The output
remains in the UTxO map; the recorded deposit remains in the Store map. These two
maps must describe the same live store-backed occurrences. Neither the transaction
output encoding nor the `TxIn` identifier gains a deposit field.

Release uses the retained amount, not a later serialization of the output.
Dijkstra ledger-state serialization preserves the Store balance and allocation map;
Conway-to-Dijkstra initialization starts with an empty Store. The recorded amount
supports exact release at fixed prices. Additional historical-pricing information
remains under [Historical pricing](#ds-pricing-history).

The applied outcome determines which records change. Ordinary success updates records for regular inputs and new ordinary outputs. Accepted phase-2 failure updates only consumed collateral records and a store-backed return, leaving unrelated records untouched. Their obligation deltas are:

**Ordinary success:**

$$
\text{obligationsAfter}
= \text{obligationsBefore} + \text{requiredTxTotalNetUTxODepositChange}
$$

**Accepted phase-2 failure:**

$$
\begin{aligned}
\text{obligationsAfter}
&= \text{obligationsBefore} \\
&\quad + \text{collateralReturnUTxODeposit} - \text{releasedUTxODeposits}
\end{aligned}
$$

Check the records against the independently observed live UTxO and expected amounts. Comparing two totals derived from the same unchecked records would not detect missing or incorrect allocations. `DS-STATE-EXECUTION` governs atomic application; `DS-STATE-RECOVERY` governs preservation through serialization and rollback.

<a id="ds-state-allocations-p01" name="ds-state-allocations-p01"></a>

#### 3.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L11) - Release recorded input deposits

$$
\text{ordinary success} \implies
\text{released deposits} =
\sum_{\text{input}\,\in\,\text{consumed store-backed inputs}}
\text{recorded deposit(input)}
$$

Given an ordinary successful spend, sum the recorded allocated amounts on the consumed store-backed inputs and compare that sum with the released amount. Use the input records, not current output repricing or the Store's global available balance.

<a id="ds-state-allocations-n01" name="ds-state-allocations-n01"></a>

#### 3.2.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L12) - records the allocated UTxO capacity deposit alongside each newly created store-backed output

Given newly created store-backed outputs, compare the allocation attached to each independently identified output reference with its accepted allocation. Include equal-valued outputs at distinct indices and outputs in different bodies: each occurrence must retain its own record. The association supplies that output's later release amount.

<a id="ds-state-allocations-n02" name="ds-state-allocations-n02"></a>

#### 3.2.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L13) - removes a spent output's UTxO capacity deposit record and releases its UTxO capacity deposit exactly once

Consume a store-backed output in an accepted transaction and expect its allocated amount to be released once and its record to disappear with the spent entry. Attempt a second spend and require rejection without another release. A surviving record or a second release would no longer correspond to a live obligation.

<a id="ds-state-allocations-n03" name="ds-state-allocations-n03"></a>

#### 3.2.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L14) - keeps UTxO capacity deposit records unchanged when outputs are only referenced

Given a live store-backed output used only as a reference input, retain its allocated record unchanged. Referencing does not consume the output or release its obligation.

<a id="ds-state-allocations-n04" name="ds-state-allocations-n04"></a>

#### 3.2.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L15) - Match live allocations to obligations

$$
\text{outstanding obligations} =
\sum_{\text{input}\,\in\,\text{live store-backed inputs}}
\text{recorded deposit(input)}
$$

Given an accepted state, sum the independently identified live store-backed allocations and compare with its outstanding deposit obligations. The obligation total describes those live outputs, rather than extra money in the Store.

<a id="ds-state-allocations-n05" name="ds-state-allocations-n05"></a>

#### 3.2.6 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L16) - does not leave missing or orphan UTxO capacity deposit records after accepted transitions

Across ordinary success and accepted phase-2 failure, compare record keys and per-reference amounts with an independent lifecycle model of the resulting live UTxO. Include equal-valued outputs at distinct indices. Every live store-backed occurrence must have one recoverable amount, and no record may remain for a nonexistent or implicit output.

<a id="ds-state-allocations-n06" name="ds-state-allocations-n06"></a>

#### 3.2.7 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L17) - releases the allocated UTxO capacity deposit even when reserialization would change the output size

Given an output whose accepted CBOR size differs from a later reserialization, spend it and expect the originally allocated amount to be released. Recomputing its price from the new encoding would change an existing obligation incorrectly.

<a id="ds-state-allocations-n07" name="ds-state-allocations-n07"></a>

#### 3.2.8 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L18) - does not release UTxO capacity deposits from the DepositStore when a translated implicit output is spent

Given an implicit output preserved by the Conway upgrade, spend it without releasing a deposit from the Store. Its full value was retained in the output and no external allocation was established during initialization.

<a id="ds-state-allocations-p02" name="ds-state-allocations-p02"></a>

#### 3.2.9 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L19) - Update obligations on ordinary success

$$
\text{ordinary success} \implies
\text{obligations after} = \text{obligations before}
+ \text{required transaction net deposit}
$$

Given an ordinary successful batch, calculate the change in live allocated amounts from consumed and created outputs. Expect that change to equal the batch net deposit change, with every body included once.

<a id="ds-state-allocations-n08" name="ds-state-allocations-n08"></a>

#### 3.2.10 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L20) - removes consumed store-backed collateral records and records the return only when store-backed, preserving records outside collateral inputs on an accepted phase-2 failure

Given an accepted phase-2 failure, remove records for consumed store-backed collateral and create a return record only if the return is store-backed. Cover mixed collateral variants and absent, implicit and store-backed returns. Include an input shared with ordinary spending and remove its record once. Preserve all records outside the collateral inputs because ordinary spending effects were not applied.

<a id="ds-state-allocations-p03" name="ds-state-allocations-p03"></a>

#### 3.2.11 [P03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/AllocationsSpec.hs#L21) - Update obligations on phase-2 failure

$$
\begin{aligned}
\text{accepted phase-2 failure} \implies\quad
\text{obligations after} &= \text{obligations before} \\
&\quad + \text{collateral return deposit} \\
&\quad - \text{released collateral deposits}
\end{aligned}
$$

Given an accepted phase-2 failure, expect outstanding obligations to change by the return's allocated deposit minus the recorded deposits released from collateral. The equation must describe the resulting live records, independently of ordinary declarations.

<a id="ds-state-balance" name="ds-state-balance"></a>

### 3.3 Balance

> **Apply each Store transfer exactly once to its actual ADA balance.**
>
> This checks the balance change. Solvency separately checks whether the resulting balance covers all obligations.

**Decision:** Agreed.

The Store balance is actual ADA. Change it by the transfers actually applied, counting each allocation and release once:

$$
\begin{aligned}
\text{storeBalanceAfter}
&= \text{storeBalanceBefore} \\
&\quad + \text{netAllocationApplied} - \text{netReleaseApplied}
\end{aligned}
$$

A SubTx request for funding from TopTx contributes nothing to the balance until its funding is settled. SubTx contributions, including delegated contributions, are already included in the TopTx batch net change; they are not extra transfers to add on top. Under ordinary success with an explicit TopTx declaration:

$$
\text{storeBalanceAfter}
= \text{storeBalanceBefore} + \text{declaredTxTotalNetUTxODepositChange}
$$

If every declaration is absent, ordinary acceptance requires no Store operations.
The actual transfer is zero; absence still has no declared numeric value.

Under accepted phase-2 failure, ordinary declarations are unapplied, and the balance instead follows the collateral return allocation minus released collateral deposits:

$$
\begin{aligned}
\text{storeBalanceAfter}
&= \text{storeBalanceBefore} \\
&\quad + \text{collateralReturnUTxODeposit} - \text{releasedUTxODeposits}
\end{aligned}
$$

Under the fixed pricing policy, the applied balance and obligation changes are equal on both accepted outcomes. Ordinary success uses the explicit $\text{declaredTxTotalNetUTxODepositChange}$ when present, or no transfer when all declarations are absent; accepted phase-2 failure uses $\text{collateralReturnUTxODeposit} - \text{releasedUTxODeposits}$. Consequently:

$$
\text{storeBalanceAfter} - \text{obligationsAfter}
= \text{storeBalanceBefore} - \text{obligationsBefore}
$$

This preserves any pre-existing surplus; it does not assume that every initial or migrated state has zero surplus. Nor does it turn unrelated surplus into a refund claim: exact contributions still restrict a release to the body's actual change in allocated deposits. That rejection belongs to [Net change](#ds-tx-accounting-net-change): SubTx checks each own change and TopTx checks the transaction total. Solvency and total ADA conservation are separately checked under `DS-STATE-SOLVENCY` and `DS-STATE-CONSERVATION`.

<a id="ds-state-balance-p01" name="ds-state-balance-p01"></a>

#### 3.3.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/BalanceSpec.hs#L11) - Apply the declared net transfer

$$
\begin{aligned}
\text{ordinary success} \land \text{TopTx has a declaration}
\implies\quad
\text{Store balance after} &= \text{Store balance before} \\
&\quad + \text{declared transaction net deposit}
\end{aligned}
$$

Given an ordinary successful batch with an explicit TopTx declaration, compare the actual Store balance before and after application. Its change must equal the supplied total, already checked against independently derived obligations by Net change, without adding SubTx contributions again.

<a id="ds-state-balance-n01" name="ds-state-balance-n01"></a>

#### 3.3.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/BalanceSpec.hs#L12) - changes the balance by exactly the applied allocations minus releases

Given applied allocations and releases, expect the Store balance to change by their exact signed difference. Unapplied requests or duplicate contribution credits must not alter the actual pot.

<a id="ds-state-balance-p02" name="ds-state-balance-p02"></a>

#### 3.3.3 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/BalanceSpec.hs#L13) - Apply collateral’s net transfer

$$
\begin{aligned}
\text{accepted phase-2 failure} \implies\quad
\text{Store balance after} &= \text{Store balance before} \\
&\quad + \text{collateral return deposit} \\
&\quad - \text{released collateral deposits}
\end{aligned}
$$

Given an accepted phase-2 failure, expect the Store balance to increase by the collateral return allocation and decrease by released collateral deposits. Ordinary declared operations supply no additional balance movement on this path.

<a id="ds-state-balance-p03" name="ds-state-balance-p03"></a>

#### 3.3.4 [P03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/BalanceSpec.hs#L14) - Preserve Store surplus

$$
\begin{aligned}
\text{fixed pricing} \land \text{accepted execution} \implies\quad
&\text{Store balance after} - \text{obligations after} \\
&\qquad = \text{Store balance before} - \text{obligations before}
\end{aligned}
$$

Given a fixed pricing policy, measure Store balance minus independently retained live obligations before and after ordinary success and accepted phase-2 failure. Exact matching changes preserve the difference on each outcome, including a zero net change.

<a id="ds-state-balance-n02" name="ds-state-balance-n02"></a>

#### 3.3.5 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/BalanceSpec.hs#L15) - preserves pre-existing Store surplus across ordinary success and accepted phase-2 failure

Given a solvent initial state with a positive Store surplus, exercise allocations, releases and zero net changes under ordinary success and accepted phase-2 failure. Derive the actual balance and live obligations independently and require the same surplus afterward. This check does not grant permission to release unrelated Store surplus.

<a id="ds-state-balance-n03" name="ds-state-balance-n03"></a>

#### 3.3.6 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/BalanceSpec.hs#L16) - applies no ordinary Store transfer when every declaration is absent

Submit an otherwise valid, implicit-only ordinary transaction with every declaration absent. The actual Store balance and live allocation records must remain unchanged. Zero transfer is an observed effect here; it does not turn an absent field into an explicit declaration of zero.

<a id="ds-state-solvency" name="ds-state-solvency"></a>

### 3.4 Solvency

> **Keep enough Store ADA to cover every live allocated deposit.**
>
> $\text{Store balance} \ge \text{outstanding deposits} \ge 0$. Surplus is permitted; exact accounting still applies.

**Decision:** Agreed; parameter-change handling remains deferred under `DS-PRICING-HISTORY`.

Every accepted state must have enough actual Store ADA to cover the allocated deposits of all live store-backed outputs:

$$
\text{storeBalance}(\text{state})
\ge \text{totalUTxODeposits}(\text{utxo}(\text{state})) \ge 0
$$

The right-hand amount is an obligation, not another monetary pot. Solvency permits a nonzero surplus; it does not require the two amounts to be equal. The accepted-state property compares the actual ledger balance with obligations calculated from independently retained live allocations. Its independent proposed-state oracle combines the expected applied transfer with the resulting model UTxO obligations:

$$
\begin{aligned}
&\text{storeBalanceBefore} + \text{netAllocationApplied} - \text{netReleaseApplied} \\
&\quad \ge \text{totalUTxODeposits}(\text{utxoAfter})
\end{aligned}
$$

For a batch, observe Store backing in the completed TopTx and SubTx result, including local and delegated contributions. Temporary intermediate accounting is not an accepted ledger state. `DS-TX-ACCOUNTING-BALANCE` owns whether financially imbalanced SubTxs form an acceptable batch; a solvency observation checks the resulting Store balance and obligations rather than repeating that acceptance assertion. On accepted phase-2 failure, only applied collateral effects can supply funding; ordinary declarations that were not applied cannot do so.

The invariant applies throughout the accepted lifecycle: initialization and Conway-to-Dijkstra translation, ordinary execution, collateral processing, fixed-policy epochs, state restoration and rollback. Generate valid sequences and require accepted examples for each outcome so rejection of every transaction cannot satisfy the invariant vacuously. The present executable scope assumes a fixed pricing policy. The eventual parameter-change policy must also preserve solvency, but these tests do not establish that future behavior.

For independently calculated $\text{obligations} > 0$, the proposed-state invariant has these one-lovelace boundaries:

| Proposed Store balance | Proposed obligations | Invariant result |
| --- | --- | --- |
| $\text{obligations} - 1\text{ lovelace}$ | $\text{obligations}$ | False |
| $\text{obligations}$ | $\text{obligations}$ | True |
| $\text{obligations} + 1\text{ lovelace}$ | $\text{obligations}$ | True |

These are boundary checks for the independent state oracle, not transaction acceptance examples. Passing the inequality does not establish exact contributions, authorize a release or validate settlement. An excessive release still fails Net change (SubTx or TopTx), even if the proposed balance would remain solvent.

From a solvent initial state, every exact accepted ordinary or collateral transition changes balance and obligations by the same signed amount. Its margin therefore cannot become negative under the fixed policy. F01 specifies the false boundary of the proposed-state invariant independently of ledger acceptance; it does not claim a separately reachable ledger rejection. Do not invent a transaction, submit a corrupted initial state or add a production solvency validator merely to make that case pass. P01 is the requirement that observed accepted ledger states satisfy the independently calculated invariant.

<a id="ds-state-solvency-p01" name="ds-state-solvency-p01"></a>

#### 3.4.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/SolvencySpec.hs#L12) - Keep every accepted state solvent

$$
\begin{aligned}
\text{fixed pricing} \land \text{solvent initial state}
\implies\quad
&\forall\,\text{state}\in\text{accepted lifecycle states}: \\
&\text{Store balance(state)} \geq \text{obligations(state)} \geq 0
\end{aligned}
$$

Given a solvent initial state and fixed pricing, follow accepted lifecycle states through ordinary success, accepted phase-2 failure, initialization, epoch processing, restoration and rollback. Compare the actual Store pot with independently retained live allocations at each observation. Require a nonnegative obligation total fully covered by that pot, without assuming zero surplus, and require accepted coverage for every applicable outcome.

<a id="ds-state-solvency-n01" name="ds-state-solvency-n01"></a>

#### 3.4.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/SolvencySpec.hs#L13) - classifies proposed states at exact backing and one lovelace above as solvent

Construct proposed-state oracle controls with independently calculated $\text{obligations}$ and balances $\text{obligations}$ and $\text{obligations} + 1\text{ lovelace}$. Require the invariant to classify both as solvent; also cover the empty Store. These controls establish the boundary of the independent expectation and do not themselves establish ledger acceptance.

<a id="ds-state-solvency-f01" name="ds-state-solvency-f01"></a>

#### 3.4.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/SolvencySpec.hs#L14) - classifies a proposed state one lovelace below its independently calculated obligations as insolvent

Construct a proposed result with $\text{obligations} > 0$, independently calculated from its model live allocations, and a Store balance of $\text{obligations} - 1\text{ lovelace}$. Require the proposed-state invariant to be false, with N01 providing adjacent true controls. This is the independent oracle boundary, not an assertion that an otherwise valid transaction reaches the result or that the ledger exposes a separate solvency failure.

<a id="ds-state-solvency-n02" name="ds-state-solvency-n02"></a>

#### 3.4.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/SolvencySpec.hs#L15) - observes Store backing in the completed batch result with local and delegated contributions

Given an accepted batch with local and delegated contributions, compare the completed Store balance with independently retained live obligations. Include mixed allocations and releases and SubTxs that need not balance independently. Assert the backing relation in the resulting state; batch financial acceptance is checked under `DS-TX-ACCOUNTING-BALANCE`.

<a id="ds-state-solvency-n03" name="ds-state-solvency-n03"></a>

#### 3.4.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/SolvencySpec.hs#L16) - Preserve solvency across epochs

$$
\begin{aligned}
\text{fixed pricing} \land \text{solvent state before epoch}
\implies\quad
&\text{Store balance after epoch} \\
&\qquad \geq \text{obligations after epoch} \geq 0
\end{aligned}
$$

Given a solvent initial state and unchanged pricing, advance through epoch processing and check backing in the accepted result. This establishes the fixed-policy invariant, not the deferred behavior of a price change.

<a id="ds-state-conservation" name="ds-state-conservation"></a>

### 3.5 Conservation

> **Preserve total ADA across outputs and ledger pots after applying a transaction.**
>
> Count actual Store ADA once. Allocation records describe obligations, not a second monetary balance.

**Decision:** Agreed.

Moving ADA between output values and the Store preserves the total ADA across ledger pots. Count the Store's actual balance once in that total. A live output's recorded allocated amount describes the Store's obligation and must not be counted as a second monetary balance.

For this purpose an implicit output contributes its full output ADA, and a store-backed output contributes its application ADA. Store ADA remains monetary ADA even though it contributes no stake or voting power under `DS-STAKE` and `DS-VOTING`.

This is an assertion about the applied ledger state across all relevant pots. `DS-TX-ACCOUNTING-BALANCE` separately checks the complete ordinary batch's consumed and produced values, while `DS-COLLATERAL-CONSERVATION` checks the collateral settlement equation. Satisfying an equation before application does not by itself prove that the state update preserves total ADA.

<a id="ds-state-conservation-n01" name="ds-state-conservation-n01"></a>

#### 3.5.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L11) - still counts Store ADA in total monetary conservation

Compare all affected monetary pots before and after ordinary success and accepted phase-2 failure, including Store states with positive surplus. Independently sum output ADA and the relevant ledger pots, observing fees and other applied charges or refunds. Include actual Store ADA exactly once and live allocation records zero times. Do not obtain the expected total by calling the ledger's total helper or omit Store ADA because it has no stake or voting weight.

<a id="ds-state-initialization" name="ds-state-initialization"></a>

### 3.6 Initialization

> **Establish the Store’s initial state at the Conway-to-Dijkstra upgrade.**
>
> Existing outputs remain implicit; $\text{Store balance} = \text{outstanding deposits} = 0$. No existing pot funds initialization.

**Decision:** Agreed.

At the Conway-to-Dijkstra upgrade, preserve every existing output reference and full semantic output payload: address, ADA and native-asset value, datum and reference script under the existing era translation. Every such output remains an implicit-deposit output. Do not automatically convert it to a store-backed output or extract its implicit minimum ADA into the new Store.

Initialize:

$$
\begin{aligned}
\text{storeBalance} &= 0 \\
\text{totalUTxODeposits} &= 0 \\
\text{utxoDepositRecords} &= \varnothing
\end{aligned}
$$

The upgrade takes no funding from existing ledger pots. Subsequent transactions can introduce store-backed outputs through the normal declaration, exact contribution and batch-funding rules; being funded by a translated output gives no exemption. Their presence and exactness cases live under the corresponding Tx responsibilities. Spending a translated implicit output itself releases no Store deposit, as checked under `DS-STATE-ALLOCATIONS`.

Collateral return creation remains governed by the collateral failure-path rules. This initial upgrade creates no historical store-backed outputs whose pricing basis must be migrated; later historical-pricing requirements are deferred under `DS-PRICING-HISTORY`.

<a id="ds-state-initialization-n01" name="ds-state-initialization-n01"></a>

#### 3.6.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/InitializationSpec.hs#L11) - preserves existing output references, addresses, values, datums and reference scripts and keeps those outputs implicit

Given a valid Conway UTxO, translate it to Dijkstra with the same references and semantic addresses, ADA, native assets, datums and reference scripts, keeping every output implicit. Include present and absent optional payloads and equal-valued outputs at distinct references. The upgrade must neither rewrite ownership or spending conditions nor extract implicit deposits.

<a id="ds-state-initialization-n02" name="ds-state-initialization-n02"></a>

#### 3.6.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/InitializationSpec.hs#L12) - initializes Store balance and UTxO capacity deposit obligations to zero

Given the Conway-to-Dijkstra upgrade, expect zero Store balance, zero outstanding obligations and an empty allocation-record domain. Existing outputs require no external allocation because they remain implicit.

<a id="ds-state-initialization-n03" name="ds-state-initialization-n03"></a>

#### 3.6.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/InitializationSpec.hs#L13) - does not transfer funds from another ledger pot during initialization

Given the upgrade, compare existing monetary pots before and after Store initialization. No transfer from those pots is needed to create an empty Store.

<a id="ds-state-recovery" name="ds-state-recovery"></a>

### 3.7 Recovery

> **Preserve accepted state through serialization, restoration and rollback.**
>
> Outputs, allocation records and Store balance must remain consistent; recorded deposits are retained without repricing.

**Decision:** Agreed; precise ledger-state APIs and encodings remain implementation work.

Ledger-state serialization, snapshots and restoration must preserve the complete semantic ledger state, including outputs, each live store-backed output's allocated amount, the actual Store balance and any surplus. Compare relevant monetary pots and derived distributions as well as the UTxO and its records. Recovering state must preserve accepted amounts; it must not reprice outputs from decoded contents or current protocol parameters. This metadata belongs to ledger state, without adding fields to the transaction output or changing its `TxIn` reference.

Rollback after either ordinary success or accepted phase-2 failure must restore the complete prior semantic ledger state, including the UTxO, allocated-deposit records, actual Store balance, other monetary pots and derived distributions. Restoring only some components could leave missing obligations, orphan records or a mismatched Store. Require equality with the prior state, not merely a newly solvent result, and verify that replaying the same transition reproduces its first result.

This preservation requirement is already agreed at fixed prices. It does not choose the additional historical pricing representation or repricing policy deferred under `DS-PRICING-HISTORY`.

<a id="ds-state-recovery-n01" name="ds-state-recovery-n01"></a>

#### 3.7.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/RecoverySpec.hs#L11) - preserves the complete ledger state through serialization and restoration, including outputs, allocated records and Store surplus

Serialize and restore a complete state containing mixed output variants, distinct retained allocations and nonzero Store surplus. Compare the restored semantic ledger state with the original, including outputs, records, actual balance, other pots and derived distributions. Then spend a restored output whose accepted CBOR size differs from its later reserialization and observe release of the retained amount. Preserving record values alone is insufficient if the Store balance or output payload changed.

<a id="ds-state-recovery-n02" name="ds-state-recovery-n02"></a>

#### 3.7.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/RecoverySpec.hs#L12) - restores the complete prior ledger state on rollback after ordinary success or accepted phase-2 failure

For ordinary success and accepted phase-2 failure separately, record the complete prior ledger state, apply the transition and roll it back. Require exact semantic restoration, including outputs, records, Store balance, other pots and derived distributions. Replay the transition and compare its accepted result with the original result to detect lost allocation information.

<a id="derived-distributions" name="derived-distributions"></a>

## 4. Derived distributions

> **Scope:** These rules and examples remain documented; stake and voting tests are deferred.

> **Determine stake and voting power from the resulting ledger under their existing rules.**

<a id="ds-stake" name="ds-stake"></a>

### 4.1 Stake

> **Determine which output ADA contributes under the existing staking rules.**
>
> Implicit output: full ADA · Store-backed output: application ADA · External deposit: no additional stake.

**Decision:** Exclude DepositStore UTxO capacity deposits from stake for the current prototype.

Apply the existing staking eligibility and delegation rules to the output's ADA contribution:

$$
\text{stakeContribution}(\text{output}) =
\begin{cases}
\text{full ADA in output} & \text{if output is implicit} \\
\text{application ADA in output} & \text{if output is store-backed}
\end{cases}
$$

An eligible implicit output containing 10 ADA therefore contributes 10 ADA. A store-backed output containing 8 application ADA with a 2 ADA allocated deposit contributes only 8 ADA where otherwise eligible. Do not attribute its external allocated deposit to its staking credential or add the global Store balance separately to stake totals.

An allocation or release affects stake through the outputs and other existing stake updates actually applied. It creates no independent Store attribution. Ordinary success leaves collateral settlement and collateral return unapplied; accepted phase-2 failure derives stake effects from collateral consumption and return, without applying ordinary outputs or ordinary Store operations.

Existing registration, eligibility, delegation and snapshot timing remain in force. A contribution amount is not a claim that every output currently participates in stake. The exclusion also does not remove Store ADA from monetary conservation under `DS-STATE-CONSERVATION`. Voting weight is checked separately under `DS-VOTING`.

<a id="ds-stake-n01" name="ds-stake-n01"></a>

#### 4.1.1 N01 - counts the full ADA in implicit outputs under the existing staking rules

Given an implicit output eligible under the existing staking rules, use its full output ADA as its stake contribution. Keeping the legacy minimum inside that value does not create an external amount to subtract.

<a id="ds-stake-n02" name="ds-stake-n02"></a>

#### 4.1.2 N02 - counts only application ADA in store-backed outputs under the existing staking rules

Given an eligible store-backed output, count its application ADA and exclude its externally allocated deposit. For 8 application ADA and a 2 ADA deposit, the contribution base is 8 ADA.

<a id="ds-stake-n03" name="ds-stake-n03"></a>

#### 4.1.3 N03 - does not add the global Store balance to stake totals

Given a nonzero global Store balance, do not add that pot separately to stake totals or assign it to output credentials. Only otherwise eligible output ADA follows the existing stake rules.

<a id="ds-stake-n04" name="ds-stake-n04"></a>

#### 4.1.4 N04 - Derive stake from applied allocations

$$
\begin{aligned}
\text{ordinary success} \land \text{net allocation}>0
\implies\quad
\text{stake effects}
&= \text{existing stake rules}(\text{applied ordinary UTxO effects})
\end{aligned}
$$

Given an ordinary successful allocation, derive stake effects from the ordinary outputs and existing stake updates actually applied. Funding the external deposit creates no separate credited stake.

<a id="ds-stake-n05" name="ds-stake-n05"></a>

#### 4.1.5 N05 - Derive stake from applied releases

$$
\begin{aligned}
\text{ordinary success} \land \text{net release}>0
\implies\quad
\text{stake effects}
&= \text{existing stake rules}(\text{applied ordinary UTxO effects})
\end{aligned}
$$

Given an ordinary successful release, derive stake effects from the resulting ordinary outputs under existing eligibility rules. The released amount does not create an additional Store attribution beside those effects.

<a id="ds-stake-n06" name="ds-stake-n06"></a>

#### 4.1.6 N06 - Ignore unapplied collateral

$$
\text{ordinary success} \implies
\text{additional stake effects from collateral} = 0
$$

Given ordinary success with supplied collateral and a possible return, do not apply additional stake effects from collateral settlement or that return. Include an input shared with ordinary spending: its ordinary consumption affects stake once, while inputs used only as collateral remain live.

<a id="ds-stake-n07" name="ds-stake-n07"></a>

#### 4.1.7 N07 - Derive stake from collateral on phase-2 failure

$$
\begin{aligned}
\text{accepted phase-2 failure} \implies\quad
\text{stake effects}
&= \text{existing stake rules}(\text{applied collateral UTxO effects}) \\
\text{stake effects from unapplied ordinary activity} &= 0
\end{aligned}
$$

Given an accepted phase-2 failure, compare the resulting stake distribution with the independently selected collateral consumption and return effects under existing rules. Cover absent, implicit and store-backed returns and an input shared with ordinary spending. Unapplied ordinary outputs, allocations and releases add no stake effects.

<a id="ds-stake-n08" name="ds-stake-n08"></a>

#### 4.1.8 N08 - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects

Given allocation, release or collateral effects, observe positive eligible stake alongside ineligible credentials and distinct delegation destinations before and after the existing snapshot boundary. Compare the expected distribution under unchanged registration, eligibility, delegation and timing rules. Excluding external deposits must neither remove eligible application ADA nor create eligibility or apply a snapshot early.

<a id="ds-voting" name="ds-voting"></a>

### 4.2 Voting

> **Exclude external deposits from additional voting power.**
>
> Application ADA follows existing eligibility rules. Store ADA remains part of monetary conservation, but adds no voting weight.

**Decision:** Exclude DepositStore UTxO capacity deposits from voting power for the current prototype.

ADA held in the Store creates no additional voting weight. Do not attribute a store-backed output's allocated deposit to its credential or count the global Store balance separately in voting distributions. The application ADA remaining in outputs continues through existing eligibility, delegation and snapshot rules.

This concerns the resulting voting distribution, separately from the stake observations in `DS-STAKE`. The excluded Store ADA still exists in the monetary total checked by `DS-STATE-CONSERVATION`.

<a id="ds-voting-n01" name="ds-voting-n01"></a>

#### 4.2.1 N01 - preserves the expected voting distribution from eligible funds while excluding allocated UTxO capacity deposits and Store balance

Compare the complete resulting voting distribution with an independent expectation under existing eligibility, delegation and snapshot rules. Include positive eligible implicit-output ADA and store-backed application ADA, other existing eligible funds, ineligible and differently delegated controls, nonzero allocated deposits and a positive Store surplus. Observe ordinary success and accepted phase-2 failure before and after the existing snapshot boundary. Neither records nor the global Store balance add weight, while eligible funds retain their expected weight; an all-zero distribution must fail the positive controls.

<a id="spec-appendices" name="spec-appendices"></a>

## Appendices

> **Keep open design questions and supporting references separate from the rule chapters.**

<a id="section-8" name="section-8"></a>

### A. Remaining design work

> **Distinguish agreed requirements from unresolved design and implementation work.**
>
> The sections below identify what remains open without treating it as an implemented guarantee.

<a id="ds-pricing-history" name="ds-pricing-history"></a>

#### A.1 Historical pricing

> **Preserve the basis of an output’s original deposit when pricing parameters change.**
>
> Current scope: fixed pricing. Future work: historical pricing information and a policy for price changes.

**Decision:** Historical pricing must be recoverable; handling parameter changes is deferred.

The current increment assumes that `coinsPerUTxOByte` does not change. It does not yet
handle pricing changes over time. This restriction does not remove the future
requirement to account correctly for outputs created under different parameter values.

For each live store-backed output, the ledger must eventually be able to recover the
pricing basis used when its UTxO capacity deposit was established, including the applicable
`coinsPerUTxOByte` value and any relevant pricing formula or chargeable-size definition.
The current protocol parameters alone cannot recover that historical basis after the
price changes. Do not silently recompute an old output's historically allocated UTxO capacity
deposit using the latest price.

For illustration, DS-PRICING charges 260 bytes for an output whose serialized size is
100 bytes, including the fixed 160-byte overhead. At a hypothetical price of 4 lovelace
per byte, its allocated UTxO capacity deposit is 1040 lovelace. A later price of 6 would give
1560 lovelace for that same size; it does not establish that 1560 lovelace was
originally allocated to the output.

Live UTxO entries retain the allocated UTxO capacity deposit amount under DS-STATE-ALLOCATIONS. The
representation of any additional historical pricing information remains undecided: it
could retain the applicable parameter directly or a pricing reference with enough
history to recover it. Its retention policy remains to be designed; this requirement
does not mandate adding a field to the serialized transaction `TxOut`. Era translation
must preserve the pricing basis of any existing store-backed outputs. The
Conway-to-Dijkstra transition introduces no such outputs under DS-STATE-INITIALIZATION.

DS-TX-ACCOUNTING-NET-CHANGE requires exact UTxO capacity deposit accounting and rejects voluntary excess net
allocations, so these operations create no separate overpayment refund claims. Whether
an explicit repricing transition is permitted remains a separate decision. The solvency
rule must eventually cover parameter changes under that policy; constant-price tests
alone will not establish this.

<a id="ds-plutus-compatibility" name="ds-plutus-compatibility"></a>

#### A.2 Plutus compatibility

> **Define how store-backed outputs appear to each supported Plutus version.**
>
> Compatibility is the target; context projection and translation still require design and tests.

**Decision:** Target compatibility with all supported Plutus versions; context projection
and translation remain deferred.

The intended design supports store-backed outputs with Plutus V1, V2, V3 and V4, subject
to each version's existing feature restrictions. Store UTxO capacity deposits alone should
not impose a V4-only restriction.

The context translation and any exposure of DepositStore information remain to be
designed and tested. The current legacy translation paths contain `unexpected
StoreBackedTxOut` errors that must be addressed in that work. No context-value
projection or translation change is selected here.

<a id="ds-tx-settlement-refinement" name="ds-tx-settlement-refinement"></a>

#### A.3 Local settlement

> **Determine any stronger guarantee needed beyond the destination’s minimum amount.**
>
> $\text{Settlement output ADA} \ge \text{release amount}$ does not establish the origin of its coins. SubTx fee contributions must remain possible.

**Decision:** Destination checks and existing SubTx imbalance are agreed; the stronger
settlement guarantee remains open.

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
inequality $\text{ordinaryProducedADA} \ge \text{ordinaryConsumedADA} + \text{amount}$ is therefore not
adopted.

For a local release, the accounting identity can be expressed as:

$$
\text{netADAExport}
= \text{ordinaryConsumedADA} + \text{amount} - \text{ordinaryProducedADA}
$$

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

#### A.4 State representation

> **Retain each accepted allocation with the ledger state.**
>
> `UTxOState` contains the Store balance and a $\text{TxIn} \mapsto \text{Coin}$ allocation map.

**Decision:** Use a separate allocation map inside `DepositStore`. Keep `TxIn`
and the serialized transaction output unchanged.

[Allocations](#ds-state-allocations) defines the required correspondence between
records and live outputs. Dijkstra state encoding retains these records and the
Store balance; initialization from Conway supplies an empty Store without moving
coins from another pot. Historical pricing metadata and policy changes remain
separate design work under [Historical pricing](#ds-pricing-history).

<a id="section-9" name="section-9"></a>

### B. Tag migration

> **Connect historical identifiers to the current domain rules and cases.**
>
> Tags identify requirements; section numbers identify reading order.

Semantic tags follow the invariant’s module path. `N`, `F` and `P` identify nominal, rejection and universal cases; numbering restarts within each group. A property can have an `N` or `F` tag when it exercises only that outcome. Document section numbers describe reading order and are not protocol identifiers.

The old identifiers remain listed here for historical references. Several old rules mixed responsibilities, so their cases can now have different semantic prefixes.

Declarations groups syntax and contextual obligations under one domain:

| Previous prefix | Current prefix |
| --- | --- |
| `DS-TX-GRAMMAR` | [DS-TX-DECLARATIONS-GRAMMAR](#ds-tx-declarations-grammar) |
| `DS-TX-REQUIRED-DECLARATIONS` | [DS-TX-DECLARATIONS-REQUIREMENTS](#ds-tx-declarations-requirements) |

Every category and case suffix is preserved. Previous Grammar and Required declarations
anchors remain valid; the new Declarations parent does not add or remove test cases.

The Requirements category and its Store-operation and SubTx-declaration groups use these current prefixes:

| Previous prefix | Current prefix |
| --- | --- |
| `DS-TX-PRESENCE` | [DS-TX-DECLARATIONS-REQUIREMENTS](#ds-tx-declarations-requirements) |
| `DS-TX-PRESENCE-OPERATIONS`, `DS-TX-PRESENCE-ACTIVITY` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](#ds-tx-declarations-requirements-operations) |
| `DS-TX-PRESENCE-OPERATIONS-ALLOCATION`, `DS-TX-PRESENCE-ACTIVITY-CREATION` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](#ds-tx-declarations-requirements-operations-allocation) |
| `DS-TX-PRESENCE-OPERATIONS-RELEASE`, `DS-TX-PRESENCE-ACTIVITY-SPENDING` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE](#ds-tx-declarations-requirements-operations-release) |
| `DS-TX-PRESENCE-OPERATIONS-ZERO-NET-CHANGE` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ZERO-NET-CHANGE](#ds-tx-declarations-requirements-operations-zero-net-change) |
| `DS-TX-PRESENCE-ACTIVITY-SCOPE`, `DS-TX-PRESENCE-OPERATIONS-SCOPE` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](#ds-tx-declarations-requirements-operations), with cases assigned to Allocation or Release below. |
| `DS-TX-PRESENCE-SUBTX-DECLARATIONS`, `DS-TX-PRESENCE-DEPENDENCY` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS](#ds-tx-declarations-requirements-subtx-declarations), preserving C01–C05 and every case suffix. |

Every previous `DS-TX-PRESENCE` rule and case anchor still resolves to the corresponding
Requirements section. Case order is unchanged within the new Declarations parent. The former
Scope group anchors open the Operations overview; each old Scope case anchor opens
its migrated case. Both the `ACTIVITY-SCOPE` and `OPERATIONS-SCOPE` prefixes follow
this mapping:

| Previous Scope case | Current case |
| --- | --- |
| `N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N06](#ds-tx-declarations-requirements-operations-allocation-n06) |
| `N02` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N07](#ds-tx-declarations-requirements-operations-allocation-n07) |
| `N03` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N08](#ds-tx-declarations-requirements-operations-allocation-n08) |
| `F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-F07](#ds-tx-declarations-requirements-operations-allocation-f07) |
| `F02` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-F08](#ds-tx-declarations-requirements-operations-allocation-f08) |
| `N06` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N09](#ds-tx-declarations-requirements-operations-allocation-n09) |
| `N04` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N09](#ds-tx-declarations-requirements-operations-release-n09) |
| `N05` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N10](#ds-tx-declarations-requirements-operations-release-n10) |
| `F03` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-F06](#ds-tx-declarations-requirements-operations-release-f06) |

Allocation and release identify gross Store operations; neither implies the
declaration's net sign. The former Scope N06 is now Allocation N09: both bodies
allocate deposits, neither releases one, and both declare exactly. The generated
ledger scenario prices each body's outputs independently and requires acceptance.

| Previous rule | Current responsibilities |
| --- | --- |
| `DS-TX-001` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE](#ds-tx-declarations-requirements-operations-release), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](#ds-tx-declarations-requirements-operations-allocation), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ZERO-NET-CHANGE](#ds-tx-declarations-requirements-operations-zero-net-change), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](#ds-tx-declarations-requirements-operations) |
| `DS-TX-002` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](#ds-tx-accounting-net-change-toptx), [DS-TX-ATTRIBUTION](#ds-tx-attribution), [DS-TX-SETTLEMENT-PARTICIPATION](#ds-tx-settlement-participation) |
| `DS-TX-003` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](#ds-tx-accounting-net-change-toptx) |
| `DS-TX-004` | [DS-TX-ACCOUNTING-BALANCE](#ds-tx-accounting-balance) |
| `DS-TX-005` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-ATTRIBUTION](#ds-tx-attribution), [DS-TX-SETTLEMENT-DESTINATION](#ds-tx-settlement-destination) |
| `DS-TX-006` | [DS-TX-SETTLEMENT-PARTICIPATION](#ds-tx-settlement-participation) |
| `DS-TX-007` | [DS-TX-ACCOUNTING-BALANCE](#ds-tx-accounting-balance), [DS-TX-SETTLEMENT-DESTINATION](#ds-tx-settlement-destination), [DS-TX-SETTLEMENT-COVERAGE](#ds-tx-settlement-coverage), [DS-STATE-EXECUTION](#ds-state-execution) |
| `DS-TX-008` | [DS-TX-DECLARATIONS-GRAMMAR](#ds-tx-declarations-grammar), [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx) |
| `DS-TX-009` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS](#ds-tx-declarations-requirements-subtx-declarations) |
| `DS-TX-010` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-ATTRIBUTION](#ds-tx-attribution), [DS-TX-ACCOUNTING-BALANCE](#ds-tx-accounting-balance) |
| `DS-TX-011` | [DS-TX-AUTHORIZATION](#ds-tx-authorization) |
| `DS-TX-012` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-APPLICATION-ASSETS](#ds-tx-application-assets) |
| `DS-COLL-001` | [DS-COLLATERAL-SCOPE](#ds-collateral-scope), [DS-COLLATERAL-AUTHORIZATION](#ds-collateral-authorization), [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-COLLATERAL-CONSERVATION](#ds-collateral-conservation) |
| `DS-COLL-002` | [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-COLLATERAL-SURPLUS](#ds-collateral-surplus), [DS-COLLATERAL-SETTLEMENT](#ds-collateral-settlement), [DS-COLLATERAL-CONSERVATION](#ds-collateral-conservation) |
| `DS-COLL-003` | [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-COLLATERAL-TOTAL](#ds-collateral-total) |
| `DS-COLL-004` | [DS-COLLATERAL-SETTLEMENT](#ds-collateral-settlement), [DS-STATE-EXECUTION](#ds-state-execution), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-BALANCE](#ds-state-balance) |
| `DS-STORE-001` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-BALANCE](#ds-state-balance), [DS-STATE-SOLVENCY](#ds-state-solvency) |
| `DS-STORE-002` | [DS-PRICING-HISTORY](#ds-pricing-history) |
| `DS-STORE-003` | [DS-PRICING](#ds-pricing), [DS-STATE-ALLOCATIONS](#ds-state-allocations) |
| `DS-STORE-004` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](#ds-tx-declarations-requirements-operations-allocation), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-INITIALIZATION](#ds-state-initialization) |
| `DS-STORE-005` | [DS-STATE-EXECUTION](#ds-state-execution), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-RECOVERY](#ds-state-recovery) |
| `DS-PLUTUS-001` | [DS-PLUTUS-COMPATIBILITY](#ds-plutus-compatibility) |
| `DS-STAKE-001` | [DS-STATE-CONSERVATION](#ds-state-conservation), [DS-STAKE](#ds-stake), [DS-VOTING](#ds-voting) |

Accounting now groups two responsibilities: Net change validates the declared
amounts; Balance checks ordinary financial conservation. Every case suffix is
preserved, and the previous anchors remain valid:

| Previous tag | Current tag |
| --- | --- |
| `DS-TX-ACCOUNTING-SUBTX` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx) |
| `DS-TX-ACCOUNTING-TOPTX` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](#ds-tx-accounting-net-change-toptx) |
| `DS-TX-CONSERVATION` | [DS-TX-ACCOUNTING-BALANCE](#ds-tx-accounting-balance) |

Net change identifies the declaration's scope directly. It replaces the former
Exactness domain; existing links remain valid through retained anchors:

| Previous tag | Current tag |
| --- | --- |
| `DS-TX-EXACTNESS` | [DS-TX-ACCOUNTING-NET-CHANGE](#ds-tx-accounting-net-change) |
| `DS-TX-EXACTNESS-SUBTX` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx) |
| `DS-TX-EXACTNESS-TOPTX` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](#ds-tx-accounting-net-change-toptx) |
| `DS-TX-EXACTNESS-CONTRIBUTION` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx) |
| `DS-TX-EXACTNESS-NETTING` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](#ds-tx-accounting-net-change-toptx) |
| `DS-TX-EXACTNESS-CONTRIBUTION-N02` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX-N02](#ds-tx-accounting-net-change-toptx-n02) — derive TopTx's own change from its declared total |

Within SubTx, former Contribution N03–N10 become N02–N09. Within TopTx, former
Netting N02–N07 become N03–N08. P/F suffixes and both former N01 identities keep their
numbers under the new scopes. All former anchors remain valid.

The accounting observation formerly registered as `DS-TX-GRAMMAR-N01` now lives at
[DS-TX-ATTRIBUTION-N04](#ds-tx-attribution-n04). Its old anchor redirects to that case;
the primitive boundary check formerly registered as `DS-TX-GRAMMAR-N02` now belongs
to ledger-core's `StrictlyPositiveCoinSpec`. Grammar nominal identifiers therefore
begin at N03; neither retired identity is reassigned.
The former combined invalid-amount check keeps [F01](#ds-tx-declarations-grammar-f01) for TopTx
zero. Its remaining TopTx assertions use [F12](#ds-tx-declarations-grammar-f12) for negative
amounts and [F13](#ds-tx-declarations-grammar-f13) for overflowing amounts.
Its SubTx assertions are split into [F07](#ds-tx-declarations-grammar-f07) for zero,
[F08](#ds-tx-declarations-grammar-f08) for negative amounts and [F09](#ds-tx-declarations-grammar-f09) for
overflowing amounts; F07 retains the zero case from the former combined SubTx check.
The former combined SubTx target check keeps [F05](#ds-tx-declarations-grammar-f05) for invalid
structure. Its index range assertions now have separate tags:
[F10](#ds-tx-declarations-grammar-f10) for negative indices and [F11](#ds-tx-declarations-grammar-f11) for
indices above 65535. Similarly, the former combined TopTx settlement check keeps
[F04](#ds-tx-declarations-grammar-f04) for invalid structure; [F14](#ds-tx-declarations-grammar-f14) covers
negative indices and [F15](#ds-tx-declarations-grammar-f15) covers indices above 65535.
These checks concern decoding; output existence remains under
[DS-TX-SETTLEMENT-DESTINATION](#ds-tx-settlement-destination).

The previously individually tagged declaration-dependency cases map as follows:

| Previous case | Current case |
| --- | --- |
| `DS-TX-009-C01-P01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C01-P01](#ds-tx-declarations-requirements-subtx-declarations-c01-p01) |
| `DS-TX-009-C02-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-N01](#ds-tx-declarations-requirements-subtx-declarations-c02-n01) |
| `DS-TX-009-C02-N02` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-N02](#ds-tx-declarations-requirements-subtx-declarations-c02-n02) |
| `DS-TX-009-C02-N03` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-N03](#ds-tx-declarations-requirements-subtx-declarations-c02-n03) |
| `DS-TX-009-C02-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-F01](#ds-tx-declarations-requirements-subtx-declarations-c02-f01) |
| `DS-TX-009-C03-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C03-N01](#ds-tx-declarations-requirements-subtx-declarations-c03-n01) |
| `DS-TX-009-C03-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C03-F01](#ds-tx-declarations-requirements-subtx-declarations-c03-f01) |
| `DS-TX-009-C04-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C04-N01](#ds-tx-declarations-requirements-subtx-declarations-c04-n01) |
| `DS-TX-009-C04-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C04-F01](#ds-tx-declarations-requirements-subtx-declarations-c04-f01) |
| `DS-TX-009-C05-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C05-N01](#ds-tx-declarations-requirements-subtx-declarations-c05-n01) |
| `DS-TX-009-C05-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C05-F01](#ds-tx-declarations-requirements-subtx-declarations-c05-f01) |
| `DS-TX-009-C06-P01` | [Technical fixture property](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/DepositStoreFixtureSpec.hs), outside the business specification |

<a id="section-10" name="section-10"></a>

### C. Code references

> **Locate the implementation entry points for each responsibility.**
>
> Declaration forms $\longrightarrow$ domain APIs · Validation $\longrightarrow$ ledger rules · Pricing $\longrightarrow$ output size.

The executable suite mirrors the rule chapters:

| Chapter | Test modules under `DepositStore/` |
| --- | --- |
| Transaction rules | [`TransactionRulesSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRulesSpec.hs) composes `TransactionRules/Tx/` and `TransactionRules/Collateral/`. |
| Ledger effects | [`LedgerEffectsSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffectsSpec.hs) composes `LedgerEffects/` directly. |

[`DeclarationsSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/DeclarationsSpec.hs)
composes [`GrammarSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/GrammarSpec.hs)
and [`RequirementsSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/RequirementsSpec.hs).
Grammar checks valid representations; Requirements checks which bodies must declare.
Within `TransactionRules/Tx/Declarations/Requirements/Operations/`,
[`AllocationSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs)
and [`ReleaseSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs)
cover each gross operation and identify which operations belong to each body.
[`OperationsSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/OperationsSpec.hs)
checks the shared declaration requirement independently of deposit price: generated
Store-backed input and output forms still require declarations when their priced
amounts are zero. Accepted controls and one-field omissions exercise both body
levels, ordinary success and real phase-2 failure.
[`ZeroNetChangeSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs)
checks equal positive allocations and releases independently for each active
TopTx or SubTx, including mixed active/inactive children and proposals on the
phase-2 failure path. Its six nominal and eight rejection properties require
explicit zero at each active body and the parent declaration required by children.
[`SubTxDeclarationsSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs)
checks the TopTx field required by any explicit SubTx declaration, including
zero and offsetting contributions from two SubTxs.

[`AccountingSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AccountingSpec.hs)
composes [`NetChangeSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChangeSpec.hs)
and [`BalanceSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs).
Net change checks each SubTx's own amount and TopTx's complete transaction total.
Balance checks the complete transaction's financial conservation when phase 2 is valid.

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
| `Specs.Tx.TopTx.Allocation` | Generate standalone allocations with at least one store-backed output; calculate their allocation and attach the supplied declaration. |
| `Specs.Tx.TopTx.Release` | Keep TopTx and its optional SubTxs with their funded ledger context; calculate the complete transaction's net deposit and apply the supplied declarations. |
| `Specs.Tx.SubTx` | Generate release and equal-allocation-and-release scenarios; expose each child's `allocatedDeposits`, recorded release and `storeBackedInputs` in transaction order, and identify declarations by source input. |
| `Specs.OutputIndex` / `StrictlyPositiveCoin` | Provide shared index generators and checked amount fixtures. |
| `Specs.Assertions` | Apply a supplied expectation to one or more observations. |
| `Encoding` | Observe CBOR and JSON behavior together, with a separate implementation for each format. |
| `Submission` | Fund and prepare ledger transactions, preserve fixtures through fixup, submit and check ledger outcomes. Its declaration and output modules register the scenario rows. |
| `Submission.Allocation` | Fund application outputs, declarations and fees from implicit inputs; preserve the allocation proposal while signing it or removing its declaration. |
| `Submission.Operations` | Fund distinct sources at zero deposit price, verify their real output forms and Store records, and return an undeclared proposal preserving each body's ownership and application ADA. |
| `Submission.Release` | Fund generated release or reference sources, preserve proposals while signing, and prepare collateral-only scenarios with actual script success or failure. |
| `Submission.Collateral` | Prepare transactions with collateral whose deposits and failure-path transfers can be observed by the specifications. |

These fixture entry points fund each generated scenario, then pass a proposal
with **no declarations** to the case:

| Fixture entry point | What the case receives |
| --- | --- |
| `fundOperations` | A parent and zero to four children with independent source/output forms, each owning a distinct funded input. Store-backed sources have a recorded zero deposit; implicit sources have no record. |
| `forAllReferenceOnlyStoreTx` | A standalone TopTx referencing real positive Store allocations, with no ordinary Store operations. |
| `forAllStandaloneReleaseTx` | A standalone TopTx with its funded ledger context. |
| `forAllSingleSubTxReleaseTx` | A TopTx with one SubTx, its funded context and the source's recorded positive deposit. |
| `forAllSubTxReleaseTx` | A TopTx with several SubTxs and their funded ledger context. |
| `forAllStandaloneZeroNetChangeTx` | A funded standalone TopTx with independently checked equal positive allocations and recorded releases. |
| `forAllSubTxZeroNetChangeTx` | A funded TopTx and its SubTxs, with independently checked equal positive allocations and recorded releases for every active body, and zero amounts for inactive bodies. |

`TopTx.netDeposit` computes allocations minus recorded releases across **TopTx and
all its SubTxs**. `TopTx.releasedDeposits` returns their total recorded release;
`SubTx.releasedDeposits` returns one amount per child in transaction order, including
zero for children consuming only implicit sources.

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

- [TopTx declaration domain API](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxODeposit/TopTx.hs)
- [SubTx declaration domain API](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxODeposit/SubTx.hs)
- [Transaction fields, operations and lenses](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxBody.hs)
- [Output variants and shared interfaces](../libs/cardano-ledger-core/src/Cardano/Ledger/Core.hs)
- [Dijkstra output representations](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxOut.hs)
- [Existing byte-based minimum-UTxO formula](../eras/babbage/impl/src/Cardano/Ledger/Babbage/TxOut.hs)
- [Serialized size measurement](../libs/cardano-ledger-binary/src/Cardano/Ledger/Binary/Decoding/Sized.hs)
- [TopTx UTXO rule](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Utxo.hs)
- [SubTx UTXO rule](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/SubUtxo.hs)

<a id="declaration-api" name="declaration-api"></a>

#### C.1 Declaration API

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

Nonzero amounts use the abstract `StrictlyPositiveCoin` type from
[`Cardano.Ledger.StrictlyPositiveCoin`](../libs/cardano-ledger-core/src/Cardano/Ledger/StrictlyPositiveCoin.hs).
`mkStrictlyPositiveCoin :: Coin -> Maybe StrictlyPositiveCoin` accepts exactly
$1 \le \mathit{amount} \le 2^{64}-1$ lovelace; `unStrictlyPositiveCoin` returns the
underlying `Coin`. The constructor stays private, and CBOR/JSON encode the amount
as a number.

<a id="transaction-body-fields" name="transaction-body-fields"></a>

#### C.2 Transaction body fields

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
under DS-COLLATERAL-SCOPE and DS-COLLATERAL-FUNDING.

<a id="declaration-encoding" name="declaration-encoding"></a>

#### C.3 Declaration encoding

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

[Grammar](#ds-tx-declarations-grammar) owns declaration forms and declaration decoder rejection,
including enforcement of `StrictlyPositiveCoin` amounts. The type's construction
and scalar codecs belong to ledger-core's `StrictlyPositiveCoinSpec`.
The [declaration codec specification](../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Binary/Golden.hs)
retains independent exact-byte/JSON goldens, historical field omission and malformed
payload checks through both transaction-body decoders.
These representation checks establish which forms can be expressed. Requirements,
exactness and conservation determine whether an expressed declaration is valid in its transaction.

[`Declaration/TopTx.hs`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Specs/Tx/Declaration/TopTx.hs)
and [`Declaration/SubTx.hs`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Specs/Tx/Declaration/SubTx.hs)
provide typed declarations, paired bodies and independent raw decoder inputs for
the same declaration domain. `allDeclarationsWithAmount` and
`allDeclarationInputsWithAmount` retain every operation form and both index bounds
while varying a valid interior index. `declarationsAtBounds` also retains both
amount bounds and explicit zero. `absentAndExplicitZero` generates paired bodies
differing only in declaration presence; SubTx also generates positive funding
requests. Structural input generators cover every defect category in each draw.

These modules also construct raw local destinations for the generated index
properties and their shrunk counterexamples.

[`OutputIndex.hs`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Specs/OutputIndex.hs)
provides shared negative and overflowing index generators. The specs preserve
those ranges while shrinking. [`Encoding.hs`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Encoding.hs)
combines CBOR and JSON observations; each format has its own implementation.
