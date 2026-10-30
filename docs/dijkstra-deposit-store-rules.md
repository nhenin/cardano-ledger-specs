# Dijkstra DepositStore specification

This specification states the DepositStore business rules and the cases used to check
them. The rule chapters follow the executable suite’s domain groups and case order.
Short titles introduce each case; formulas state its contract. Semantic tags connect
each requirement to its test independently of section
numbering. The executable suite groups Transaction rules and Ledger effects;
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
                            <a href="#ds-tx-accounting-net-change-subtx-f09">2.1.2.1.1.18 F09 - Unspent outputs cannot increase a SubTx release</a><br>
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
                            <a href="#ds-tx-accounting-net-change-toptx-p02">2.1.2.1.2.2 P02 - Delegation preserves the transaction total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n01">2.1.2.1.2.3 N01 - TopTx and SubTxs contribute to the total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n02">2.1.2.1.2.4 N02 - TopTx's own change is derived from its total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n03">2.1.2.1.2.5 N03 - 5 ADA allocated, 3 ADA released</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n04">2.1.2.1.2.6 N04 - 3 ADA allocated, 5 ADA released</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n05">2.1.2.1.2.7 N05 - Nonzero body changes produce a zero total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f01">2.1.2.1.2.8 F01 - Standalone TopTx understates its net allocation by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f02">2.1.2.1.2.9 F02 - Standalone TopTx overstates its net allocation by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f03">2.1.2.1.2.10 F03 - Standalone TopTx understates its net release by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f04">2.1.2.1.2.11 F04 - Standalone TopTx overstates its net release by one lovelace</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f05">2.1.2.1.2.12 F05 - Explicit zero cannot replace a nonzero total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f06">2.1.2.1.2.13 F06 - A nonzero declaration cannot replace a zero total</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f07">2.1.2.1.2.14 F07 - TopTx declares the opposite direction</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n06">2.1.2.1.2.15 N06 - TopTx releases while SubTxs allocate</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n07">2.1.2.1.2.16 N07 - TopTx allocates while SubTxs release</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-n08">2.1.2.1.2.17 N08 - An exact total remains valid when phase 2 fails</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f08">2.1.2.1.2.18 F08 - An inexact total is rejected even when phase 2 fails</a><br>
                            <a href="#ds-tx-accounting-net-change-toptx-f09">2.1.2.1.2.19 F09 - A delegated change belongs in the total exactly once</a><br>
                          </dd>
                        </dl>
                      </details>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-accounting-attribution">2.1.2.2 Attribution</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-accounting-attribution-p01">2.1.2.2.1 P01 - Local and delegated contributions determine TopTx's share</a><br>
                      <a href="#ds-tx-accounting-attribution-p02">2.1.2.2.2 P02 - Delegation moves the signed contribution to TopTx</a><br>
                      <a href="#ds-tx-accounting-attribution-n01">2.1.2.2.3 N01 - Explicit zero adds no delegated contribution</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-accounting-balance">2.1.2.3 Balance</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-accounting-balance-p01">2.1.2.3.1 P01 - The transaction conserves value when phase 2 is valid</a><br>
                      <a href="#ds-tx-accounting-balance-p02">2.1.2.3.2 P02 - Complete balance determines acceptance</a><br>
                      <a href="#ds-tx-accounting-balance-n01">2.1.2.3.3 N01 - Fund a net allocation once</a><br>
                      <a href="#ds-tx-accounting-balance-n02">2.1.2.3.4 N02 - Use a net release once</a><br>
                      <a href="#ds-tx-accounting-balance-n03">2.1.2.3.5 N03 - One SubTx funds another</a><br>
                      <a href="#ds-tx-accounting-balance-n04">2.1.2.3.6 N04 - A SubTx funds TopTx fees</a><br>
                      <a href="#ds-tx-accounting-balance-f01">2.1.2.3.7 F01 - One-lovelace deficit or surplus</a><br>
                      <a href="#ds-tx-accounting-balance-f02">2.1.2.3.8 F02 - Native-asset quantity or identity mismatch</a><br>
                      <a href="#ds-tx-accounting-balance-f03">2.1.2.3.9 F03 - An exact delegated allocation lacks funding</a><br>
                      <a href="#ds-tx-accounting-balance-n05">2.1.2.3.10 N05 - Equal delegated allocations and releases</a><br>
                      <a href="#ds-tx-accounting-balance-n06">2.1.2.3.11 N06 - Ten input ADA plus two released ADA</a><br>
                      <a href="#ds-tx-accounting-balance-n07">2.1.2.3.12 N07 - Released ADA contributes to TopTx fees</a><br>
                      <a href="#ds-tx-accounting-balance-f04">2.1.2.3.13 F04 - Released ADA cannot disappear</a><br>
                      <a href="#ds-tx-accounting-balance-n08">2.1.2.3.14 N08 - Balanced proposal, failed phase 2</a><br>
                    </dd>
                  </dl>
                </details>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-authorization">2.1.3 Authorization</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-authorization-n01">2.1.3.1 N01 - Bob spends an output funded by Alice</a><br>
                <a href="#ds-tx-authorization-f01">2.1.3.2 F01 - Alice's signature cannot replace Bob's</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-settlement">2.1.4 Settlement</a></summary>
            <dl>
              <dd>
                <details>
                  <summary><a href="#ds-tx-settlement-designation">2.1.4.1 Designation</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-designation-p01">2.1.4.1.1 P01 - Designation follows TopTx's release share</a><br>
                      <a href="#ds-tx-settlement-designation-n01">2.1.4.1.2 N01 - SubTxs settle the entire release</a><br>
                      <a href="#ds-tx-settlement-designation-n02">2.1.4.1.3 N02 - Standalone TopTx settles its release</a><br>
                      <a href="#ds-tx-settlement-designation-n03">2.1.4.1.4 N03 - TopTx and SubTxs each settle a share</a><br>
                      <a href="#ds-tx-settlement-designation-n04">2.1.4.1.5 N04 - TopTx's share exceeds the transaction release</a><br>
                      <a href="#ds-tx-settlement-designation-f01">2.1.4.1.6 F01 - TopTx omits a required output</a><br>
                      <a href="#ds-tx-settlement-designation-f02">2.1.4.1.7 F02 - TopTx designates an unnecessary output</a><br>
                      <a href="#ds-tx-settlement-designation-n05">2.1.4.1.8 N05 - Net allocation, even though TopTx releases</a><br>
                      <a href="#ds-tx-settlement-designation-n06">2.1.4.1.9 N06 - Explicit-zero total, even though TopTx releases</a><br>
                      <a href="#ds-tx-settlement-designation-n07">2.1.4.1.10 N07 - Net release, while TopTx allocates</a><br>
                      <a href="#ds-tx-settlement-designation-n08">2.1.4.1.11 N08 - Valid designation when phase 2 fails</a><br>
                      <a href="#ds-tx-settlement-designation-f03">2.1.4.1.12 F03 - Invalid designation when phase 2 fails</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-settlement-output-index">2.1.4.2 Output index</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-output-index-p01">2.1.4.2.1 P01 - The index belongs to the declaring body</a><br>
                      <a href="#ds-tx-settlement-output-index-f01">2.1.4.2.2 F01 - The first missing own index is rejected</a><br>
                      <a href="#ds-tx-settlement-output-index-f02">2.1.4.2.3 F02 - A SubTx cannot select TopTx's output</a><br>
                      <a href="#ds-tx-settlement-output-index-f03">2.1.4.2.4 F03 - Collateral return is outside the ordinary output sequence</a><br>
                      <a href="#ds-tx-settlement-output-index-f04">2.1.4.2.5 F04 - A SubTx without outputs cannot settle locally</a><br>
                      <a href="#ds-tx-settlement-output-index-n01">2.1.4.2.6 N01 - The first and last own outputs are valid</a><br>
                      <a href="#ds-tx-settlement-output-index-f05">2.1.4.2.7 F05 - TopTx cannot select a SubTx's output</a><br>
                      <a href="#ds-tx-settlement-output-index-f06">2.1.4.2.8 F06 - A SubTx cannot select a sibling's output</a><br>
                      <a href="#ds-tx-settlement-output-index-n02">2.1.4.2.9 N02 - Valid output indices when phase 2 fails</a><br>
                      <a href="#ds-tx-settlement-output-index-f07">2.1.4.2.10 F07 - An invalid output index still fails when phase 2 fails</a><br>
                      <a href="#ds-tx-settlement-output-index-n03">2.1.4.2.11 N03 - A SubTx without outputs delegates its final release</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-settlement-output-coin">2.1.4.3 Output coin</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-output-coin-p01">2.1.4.3.1 P01 - Output ADA must cover the required share</a><br>
                      <a href="#ds-tx-settlement-output-coin-f01">2.1.4.3.2 F01 - Implicit output, one lovelace short</a><br>
                      <a href="#ds-tx-settlement-output-coin-n01">2.1.4.3.3 N01 - Implicit output, exact amount</a><br>
                      <a href="#ds-tx-settlement-output-coin-n02">2.1.4.3.4 N02 - Implicit output, extra ADA</a><br>
                      <a href="#ds-tx-settlement-output-coin-f02">2.1.4.3.5 F02 - An external deposit cannot fill the ADA shortfall</a><br>
                      <a href="#ds-tx-settlement-output-coin-n03">2.1.4.3.6 N03 - Store-backed output, exact application ADA</a><br>
                      <a href="#ds-tx-settlement-output-coin-n04">2.1.4.3.7 N04 - TopTx's share is smaller than the transaction release</a><br>
                      <a href="#ds-tx-settlement-output-coin-n05">2.1.4.3.8 N05 - Exact output ADA when phase 2 fails</a><br>
                      <a href="#ds-tx-settlement-output-coin-f03">2.1.4.3.9 F03 - One lovelace short when phase 2 fails</a><br>
                      <a href="#ds-tx-settlement-output-coin-f04">2.1.4.3.10 F04 - The transaction release is smaller than TopTx's share</a><br>
                    </dd>
                  </dl>
                </details>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-minimum-coin">2.1.5 Minimum coin</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-minimum-coin-n01">2.1.5.1 N01 - Native assets without ADA</a><br>
                <a href="#ds-tx-minimum-coin-n02">2.1.5.2 N02 - Datum or reference script without assets</a><br>
                <a href="#ds-tx-minimum-coin-n03">2.1.5.3 N03 - Address-only output</a><br>
                <a href="#ds-tx-minimum-coin-n04">2.1.5.4 N04 - Exact minimum for an implicit output</a><br>
                <a href="#ds-tx-minimum-coin-f01">2.1.5.5 F01 - Implicit output one lovelace short</a><br>
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
          <a href="#ds-collateral-existing-rules">Existing collateral rules</a><br>
          <details>
            <summary><a href="#ds-collateral-funding">2.2.1 Funding</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-funding-n01">2.2.1.1 N01 - Funded collateral</a><br>
                <a href="#ds-collateral-funding-f01">2.2.1.2 F01 - Underfunded collateral</a><br>
                <a href="#ds-collateral-funding-p02">2.2.1.3 P02 - Independent ordinary declarations</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-total">2.2.2 Total</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-total-n01">2.2.2.1 N01 - Absent or exact total</a><br>
                <a href="#ds-collateral-total-f01">2.2.2.2 F01 - Incorrect total</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-assets">2.2.3 Assets</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-assets-n01">2.2.3.1 N01 - Exact asset map</a><br>
                <a href="#ds-collateral-assets-f01">2.2.3.2 F01 - Missing or altered assets</a><br>
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
      <summary><a href="#ds-state-utxo">3.1 UTxO</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-utxo-n01">3.1.1 N01 - Ordinary execution</a><br>
          <a href="#ds-state-utxo-n02">3.1.2 N02 - Successful scripts leave collateral inactive</a><br>
          <a href="#ds-state-utxo-n03">3.1.3 N03 - Failed scripts select collateral</a><br>
          <a href="#ds-state-utxo-n04">3.1.4 N04 - Failed TopTx, inactive SubTxs</a><br>
          <a href="#ds-state-utxo-n05">3.1.5 N05 - One input, two consuming roles</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-store">3.2 Store</a></summary>
      <dl>
        <dd>
          <details>
            <summary><a href="#ds-state-allocations">3.2.1 Allocations</a></summary>
            <dl>
              <dd>
                <a href="#ds-state-allocations-p01">3.2.1.1 P01 - Ordinary records</a><br>
                <a href="#ds-state-allocations-p02">3.2.1.2 P02 - Collateral records</a><br>
                <a href="#ds-state-allocations-p03">3.2.1.3 P03 - Retained accepted size</a><br>
                <a href="#ds-state-allocations-n01">3.2.1.4 N01 - Zero-priced allocations still have records</a><br>
                <a href="#ds-state-allocations-p04">3.2.1.5 P04 - No ordinary records on failure</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-state-balance">3.2.2 Balance</a></summary>
            <dl>
              <dd>
                <a href="#ds-state-balance-p01">3.2.2.1 P01 - Ordinary transfer</a><br>
                <a href="#ds-state-balance-p02">3.2.2.2 P02 - Collateral transfer</a><br>
                <a href="#ds-state-balance-p03">3.2.2.3 P03 - Historical release after restoration</a><br>
                <a href="#ds-state-balance-p04">3.2.2.4 P04 - No ordinary transfer on failure</a><br>
                <a href="#ds-state-balance-p05">3.2.2.5 P05 - Refund mixed historical prices</a><br>
                <a href="#ds-state-balance-p06">3.2.2.6 P06 - Restore and refund a child output</a><br>
                <a href="#ds-state-balance-p07">3.2.2.7 P07 - Restore and refund a collateral return</a><br>
              </dd>
            </dl>
          </details>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-fees">3.3 Fees</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-fees-p01">3.3.1 P01 - Ordinary fee</a><br>
          <a href="#ds-state-fees-p02">3.3.2 P02 - Collateral fee</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-conservation">3.4 Conservation</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-conservation-n01">3.4.1 N01 - Count actual ADA once</a><br>
          <a href="#ds-state-conservation-n02">3.4.2 N02 - Ordinary conservation</a><br>
          <a href="#ds-state-conservation-n03">3.4.3 N03 - Collateral conservation</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-lifecycle">3.5 Lifecycle</a></summary>
      <dl>
        <dd>
          <details>
            <summary><a href="#ds-state-translation">3.5.1 Translation</a></summary>
            <dl>
              <dd>
                <a href="#ds-state-translation-n01">3.5.1.1 N01 - Introduce legacy allocations</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-state-epoch">3.5.2 Epoch</a></summary>
            <dl>
              <dd>
                <a href="#ds-state-epoch-n01">3.5.2.1 N01 - Retain the populated Store</a><br>
                <a href="#ds-state-epoch-n02">3.5.2.2 N02 - Activate the effective price</a><br>
              </dd>
            </dl>
          </details>
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

> **Keep each live output with its original deposit calculation; maintain their exact total.**

`UTxOStore` owns the `currentCalculation`, one map from `TxIn` to `Unspent (TxOut era)` and a
cached `totalDepositAmount`. Every allocation retains a sized output and a
`DepositCalculation`; the `TxOut` distinguishes legacy and Store-backed outputs.
For newly accepted outputs, the size is that of the complete accepted output,
including its variant encoding. It is retained explicitly because canonical
re-encoding can be shorter. Legacy outputs retain the supplied metadata too,
while their external deposit remains zero.

The store and its wrappers use record fields:

```haskell
data UTxOStore era = UTxOStore
  { currentCalculation :: !DepositCalculation
  , totalDepositAmount :: !DepositAmount
  , allocations :: !(IndexedUTxOs era)
  }

newtype DepositAmount = DepositAmount
  { toCoin :: Coin
  }

newtype IndexedUTxOs era = IndexedUTxOs
  { unIndexedUTxOs :: Map TxIn (Unspent (TxOut era))
  }

data Unspent output = Unspent
  { sizedOutput :: !(Sized output)
  , depositCalculation :: !DepositCalculation
  }
```

| Quantity | Meaning |
| --- | --- |
| `allocatedUTxODeposit(output)` | Creation-time price multiplied by `160 + acceptedSize`; zero for a legacy allocation. |
| `storeBalance` | Cached sum of the deposits calculated from the live allocations' historical metadata. |

$$
\text{storeBalance}
= \sum_{\text{output}\in\text{live store-backed outputs}}
\text{allocatedUTxODeposit(output)}
$$

Construct an allocation directly as
`Unspent {sizedOutput = acceptedOutput, depositCalculation = calculation}`,
preserving the accepted full-output size and explicit calculation. Construction is pure;
`mkUTxOStore` accepts a current calculation and historical `IndexedUTxOs`, preserves the entries and derives the cached total. Persisted metadata is checked during decoding.
`allocate` receives proposed `IndexedTxOs`, records the Store's `currentCalculation` on each new entry and adds their deposits; `release` removes
selected entries and subtracts their historical deposits. Both preserve exact
cached equality for a valid Store.
`Store.update body` composes these operations for one body's regular inputs and
outputs. The ledger invokes it separately for each successful SubTx and TopTx;
phase-2 failure uses the explicit collateral update instead.
Snapshot decoding validates both metadata and cached equality. The exported record
selectors also support direct record updates, whose callers must preserve the
relationship between the allocations and their total.
The cached total and allocation metadata describe the same ADA, counted once;
there is no unallocated Store surplus. Legacy outputs occupy the same map and
retain their existing minimum-ADA requirement, with no external deposit.

**Allocate** stores the new output with its accepted size and creation-time price.
**Release** removes the consumed allocation and makes its exact historical deposit
available. A release can fund a new allocation in the same transaction. A price
change affects new allocations; it does not reprice existing allocations.

**Activate** selects the calculation for future allocations. At an effective parameter
change, the ledger updates the current rate while preserving the selected formula version.
Existing entries and the cached total remain unchanged:

$$
\begin{aligned}
S' &= \text{activateNewCalculation}(c,S) \\
\text{currentCalculation}(S') &= c \\
\text{allocations}(S') &= \text{allocations}(S) \\
\text{totalDepositAmount}(S') &= \text{totalDepositAmount}(S)
\end{aligned}
$$

Accounting queries read the retained allocations directly. `Unspent.depositAmount`
calculates one historical deposit and `allocatedDepositTotalAmount` sums selected input refunds.
The amount reads are pure:

```haskell
Unspent.depositAmount :: Unspent (TxOut era) -> Coin
sumDepositAmounts :: IndexedUTxOs era -> DepositAmount
allocatedDepositTotalAmount :: Set TxIn -> IndexedUTxOs era -> DepositAmount
```

Entry decoding rejects negative persisted sizes. Store operations rely on measured
output sizes. `lookupUTxO`, `allocatedDepositTotalAmount` and
`sumDepositAmounts` operate on `IndexedUTxOs era`; callers supply the Store's
`allocations` field and use `toCoin` explicitly when Coin arithmetic is needed.
Store construction consumes the aggregate `DepositAmount` directly.
Consumers read `sizedOutput` and `depositCalculation`;
the wrapped `TxOut` retains its `LegacyTxOut` or `NewTxOut` constructor.
`emptyUTxOStore` creates the empty
store, and `encodeUTxOStore` is the snapshot encoder.
Store-backed allocations remain present even when priced at zero. Earlier eras keep their legacy encodings and zero separately held deposits.
`DepositCalculationV2` is accepted with the same provisional formula as V1.
Genesis and translation initialize V1; rate updates preserve an already selected V1 or V2.
Unknown encoded calculation versions are rejected.

Legacy imports that lack accepted metadata currently use `mkSized` at the era's
lowest protocol version and `DepositCalculationV1` with a zero byte price. These
are provisional compatibility values, not recovered historical size or policy.
This does not represent the historical minimum-ADA formula used for a legacy
output: those formulas and their parameters changed between eras. Legacy history
representation remains an unresolved design issue; the compatibility value must
not be interpreted as a recovered creation policy. This fallback does not apply
to Store-backed outputs whose supplied metadata is available.

[Ledger effects](#ds-state) specifies the resulting allocations and exact cached total.

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
it is distinct from TopTx's own operations. [Attribution](#ds-tx-accounting-attribution) defines it.

Net quantities are signed: positive means net allocation, negative means net release,
and zero means no net change. **An absent declaration has no declared value**; it is
not an explicit declaration of zero. `hasDeclaration(body)` distinguishes these cases
and is true for every explicit declaration, including zero.

A **settlement output** is the output designated to contain a release's settlement
amount. [Settlement](#ds-tx-settlement) determines TopTx’s responsibility, the
destination and required amount.
The [body-field reference](#transaction-body-fields) maps these concepts to the API.

<a id="ds-pricing" name="ds-pricing"></a>

### 1.4 Deposit calculation

> **Scope:** The full pricing matrix below remains deferred. Historical size/rate retention, zero pricing and invalid metadata have focused codec and ledger regression checks.

> **Determine the deposit required by a new store-backed output.**
>
> Accepted serialized size $\longrightarrow$ required deposit in ADA.

**Decision:** V1 uses the existing fixed formula with the price recorded at allocation creation.

Each newly created store-backed output requires the existing byte-based minimum-UTxO amount, held externally as its allocated UTxO capacity deposit:

$$
\mathrm{requiredUTxODeposit}(\mathrm{output})=\mathrm{coinsPerUTxOByte}\bigl(160+\mathrm{acceptedSize}(\mathrm{output})\bigr).
$$

`acceptedSize` is the size of the accepted serialized output under the existing CBOR-sized-output convention. It includes its address, application assets, datum, reference script and their encoding overhead. The fixed 160-byte overhead remains. The Store balance, external allocated amount and transaction body's Store declaration are outside the output and add no bytes to its priced size.

For finalized output contents and fixed parameters, the amount is determined. Moving that amount into the external Store does not add a deposit field to the output or require a size fixed point for that field. This does not remove iteration from transaction balancing: changing application ADA, assets, address, datum or script changes the output and requires pricing its resulting size again.

The same formula applies to ordinary store-backed outputs and a store-backed collateral return. A body's allocated amount is the sum for its own new store-backed outputs. Implicit-deposit outputs retain their existing minimum-coin validation and incur no DepositStore obligation.

Capture the accepted sized output and the applicable price in its allocation. Later release calculates the historical amount from that immutable metadata under `DS-STATE-ALLOCATIONS`; reserializing a decoded CBOR output need not reproduce its accepted size, even at a constant price. Parameter changes leave existing records unchanged under `DS-PRICING-HISTORY`.

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
| [Accounting](#ds-tx-accounting) | Is the change exact, correctly attributed and funded? |
| [Authorization](#ds-tx-authorization) | Who may release the deposit? |
| [Settlement](#ds-tx-settlement) | Is the required output designated, in range and sufficiently funded? |
| [Minimum coin](#ds-tx-minimum-coin) | Must the output retain ADA to cover its storage? |

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
[Settlement](#ds-tx-settlement-output-index) separately checks that the index names
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
[Settlement](#ds-tx-settlement-output-index) separately checks that the index names
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
  `NewTxOut` constructor.
- `releasesDeposits(body)`: at least one element of `spentOutputs(body)` has the
  `NewTxOut` constructor.

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
`LegacyTxOut` constructor.

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
  DS-TX-ACCOUNTING-NET-CHANGE-SUBTX checks the requested amount, DS-TX-ACCOUNTING-ATTRIBUTION assigns
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

> **State the exact change, assign each contribution, and balance the transaction.**

| Responsibility | Question | Phase-2 scope |
| --- | --- | --- |
| [Net change](#ds-tx-accounting-net-change) | Does each declaration state the required deposit change? | Valid or invalid |
| [Attribution](#ds-tx-accounting-attribution) | Which signed contributions belong to TopTx or SubTx? | Derived on either path |
| [Balance](#ds-tx-accounting-balance) | Do consumed and produced values balance, counting the Store transfer once? | Valid only |

Exact declarations identify the Store transfer. Attribution assigns its signed
contributions to bodies; it does not add another transfer. The complete transaction
must balance when its ordinary effects apply. No step requires each SubTx to balance
independently.

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
unspent outputs and opposing declaration errors fail SubTx exactness even
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
| $\mathit{unspentInputs}$ | References to live Store-backed outputs that this transaction does not consume. |
| $\mathrm{recordedDeposits}(\mathit{unspentInputs})$ | Sum of their recorded deposits. |

For F01–F04, both the original and changed magnitudes remain representable. Positive
allocation amounts and release magnitudes are checked by Grammar; these cases test
exactness within that valid range.

<a id="ds-tx-exactness-contribution-p01" name="ds-tx-exactness-contribution-p01"></a>
<a id="ds-tx-exactness-subtx-p01" name="ds-tx-exactness-subtx-p01"></a>
<a id="ds-tx-accounting-subtx-p01" name="ds-tx-accounting-subtx-p01"></a>
<a id="ds-tx-accounting-net-change-subtx-p01" name="ds-tx-accounting-net-change-subtx-p01"></a>

**2.1.2.1.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L90) - Each SubTx declares its own exact change**

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

**2.1.2.1.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L126) - Exact own change, with any allocation and release combination**

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

**2.1.2.1.1.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L148) - Net allocation understated by one lovelace**

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

**2.1.2.1.1.4 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L166) - Net allocation overstated by one lovelace**

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

**2.1.2.1.1.5 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L184) - Net release understated by one lovelace**

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

**2.1.2.1.1.6 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L202) - Net release overstated by one lovelace**

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

**2.1.2.1.1.7 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L220) - Opposing SubTx errors cancel in the total**

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

**2.1.2.1.1.8 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L239) - Equal own allocations and releases, explicit zero**

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

**2.1.2.1.1.9 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L248) - Explicit zero cannot replace a required allocation**

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

**2.1.2.1.1.10 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L266) - Exact allocation requested from TopTx**

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

**2.1.2.1.1.11 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L278) - Exact release delegated to TopTx**

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

**2.1.2.1.1.12 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L290) - Released deposits, only implicit outputs**

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

**2.1.2.1.1.13 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L302) - Explicit zero cannot replace a required release**

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

**2.1.2.1.1.14 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L320) - Another body offsets the SubTx release**

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

**2.1.2.1.1.15 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L342) - An output without application assets still requires a deposit**

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

**2.1.2.1.1.16 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L354) - A translated implicit input funds an exact allocation**

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

**2.1.2.1.1.17 [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L366) - A translated implicit input does not excuse an inexact allocation**

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

**2.1.2.1.1.18 [F09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L385) - Unspent outputs cannot increase a SubTx release**

$$
\begin{aligned}
&\mathit{unspentInputs}\cap\mathit{consumedInputs}=\varnothing \\
&\land 0 < \mathit{unrelatedRelease} \le \mathrm{recordedDeposits}(\mathit{unspentInputs}) \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) \le 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - \mathit{unrelatedRelease} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
$$

Fund one to four separate Store-backed outputs and leave them unspent. Their
recorded deposits are not available to this SubTx: increasing the declared release
by part of that amount fails exactness. The unchanged declaration remains accepted.

<a id="ds-tx-exactness-contribution-f10" name="ds-tx-exactness-contribution-f10"></a>
<a id="ds-tx-exactness-subtx-f10" name="ds-tx-exactness-subtx-f10"></a>
<a id="ds-tx-accounting-subtx-f10" name="ds-tx-accounting-subtx-f10"></a>
<a id="ds-tx-accounting-net-change-subtx-f10" name="ds-tx-accounting-net-change-subtx-f10"></a>

**2.1.2.1.1.19 [F10](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L410) - A release cannot replace a required allocation**

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

**2.1.2.1.1.20 [F11](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L429) - An allocation cannot replace a required release**

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

**2.1.2.1.1.21 [N09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L449) - Exact SubTx declarations when phase 2 fails**

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

**2.1.2.1.1.22 [F12](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L471) - An inexact SubTx declaration still fails before the collateral outcome**

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
a release targeting `DelegateToTopTx`. Delegation affects [Attribution](#ds-tx-accounting-attribution),
while the transaction total remains unchanged.

| Total allocations | Total releases | TopTx declaration |
| --- | --- | --- |
| 5 ADA | 3 ADA | Allocate 2 ADA |
| 3 ADA | 5 ADA | Release 2 ADA |
| 5 ADA | 5 ADA | Explicit zero |

TopTx has no separate declaration for its own change. Derive it by subtracting **all**
declared SubTx changes from the declared total, as shown in N02. This differs from
`topTxNetUTxODepositChange` in [Attribution](#ds-tx-accounting-attribution), which retains delegated SubTx changes.

On ordinary success, the transaction total is applied once; SubTx amounts are already
included. Accepted phase-2 failure applies no ordinary Store transfer. Requirements
still decide whether the field is mandatory: net zero does not imply absence.

<a id="ds-tx-exactness-netting-p01" name="ds-tx-exactness-netting-p01"></a>
<a id="ds-tx-exactness-toptx-p01" name="ds-tx-exactness-toptx-p01"></a>
<a id="ds-tx-accounting-toptx-p01" name="ds-tx-accounting-toptx-p01"></a>
<a id="ds-tx-accounting-net-change-toptx-p01" name="ds-tx-accounting-net-change-toptx-p01"></a>

**2.1.2.1.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L72) - TopTx declares the exact transaction total**

$$
\begin{aligned}
&\mathrm{topTxNetChangeValid}(\mathit{topTx}) \\
&\iff \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx})
\end{aligned}
$$

Compare the isolated TopTx validator with independently computed deposits; this equivalence does not assert complete ledger acceptance.

<a id="ds-tx-attribution-n02" name="ds-tx-attribution-n02"></a>
<a id="ds-tx-accounting-net-change-toptx-p02" name="ds-tx-accounting-net-change-toptx-p02"></a>

**2.1.2.1.2.2 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L90) - Delegation preserves the transaction total**

$$
\begin{aligned}
&\text{sameStoreOperations(localTx, delegatedTx)} \\
&\implies\text{requiredNetDeposit(localTx)}=\text{requiredNetDeposit(delegatedTx)} \\
&\qquad\land\text{Accepted(localTx)}\land\text{Accepted(delegatedTx)}
\end{aligned}
$$

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
can remain unchanged. [Attribution P02](#ds-tx-accounting-attribution-p02) checks
which body assumes the signed contribution.

<a id="ds-tx-exactness-netting-n01" name="ds-tx-exactness-netting-n01"></a>
<a id="ds-tx-exactness-toptx-n01" name="ds-tx-exactness-toptx-n01"></a>
<a id="ds-tx-accounting-toptx-n01" name="ds-tx-accounting-toptx-n01"></a>
<a id="ds-tx-accounting-net-change-toptx-n01" name="ds-tx-accounting-net-change-toptx-n01"></a>

**2.1.2.1.2.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L122) - TopTx and SubTxs contribute to the total**

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

**2.1.2.1.2.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L135) - TopTx's own change is derived from its total**

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

**2.1.2.1.2.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L148) - 5 ADA allocated, 3 ADA released**

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

**2.1.2.1.2.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L159) - 3 ADA allocated, 5 ADA released**

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

**2.1.2.1.2.7 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L171) - Nonzero body changes produce a zero total**

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

**2.1.2.1.2.8 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L181) - Standalone TopTx understates its net allocation by one lovelace**

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

**2.1.2.1.2.9 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L193) - Standalone TopTx overstates its net allocation by one lovelace**

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

**2.1.2.1.2.10 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L206) - Standalone TopTx understates its net release by one lovelace**

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

**2.1.2.1.2.11 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L219) - Standalone TopTx overstates its net release by one lovelace**

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

**2.1.2.1.2.12 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L231) - Explicit zero cannot replace a nonzero total**

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

**2.1.2.1.2.13 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L247) - A nonzero declaration cannot replace a zero total**

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

**2.1.2.1.2.14 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L262) - TopTx declares the opposite direction**

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

**2.1.2.1.2.15 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L281) - TopTx releases while SubTxs allocate**

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

**2.1.2.1.2.16 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L291) - TopTx allocates while SubTxs release**

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

**2.1.2.1.2.17 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L301) - An exact total remains valid when phase 2 fails**

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

**2.1.2.1.2.18 [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L313) - An inexact total is rejected even when phase 2 fails**

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

**2.1.2.1.2.19 [F09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L330) - A delegated change belongs in the total exactly once**

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

<a id="ds-tx-attribution" name="ds-tx-attribution"></a>
<a id="ds-tx-accounting-attribution" name="ds-tx-accounting-attribution"></a>

##### 2.1.2.2 Attribution

> **Determine which body accounts for each signed contribution.**
>
> Local operations remain with SubTx; delegated operations belong to TopTx.
> This changes responsibility, never the complete transaction's net amount.

| SubTx declaration | Originating change | Accounted in SubTx | Accounted in TopTx |
| --- | ---: | ---: | ---: |
| Local allocation | $+\text{amount}$ | $+\text{amount}$ | $0$ |
| Local release | $-\text{amount}$ | $-\text{amount}$ | $0$ |
| Allocation requested from TopTx | $+\text{amount}$ | $0$ | $+\text{amount}$ |
| Release delegated to TopTx | $-\text{amount}$ | $0$ | $-\text{amount}$ |
| Explicit zero | $0$ | $0$ | $0$ |
| Absent declaration | No declared operation | $0$ | $0$ |

An absent declaration is not explicit zero; declaration requirements still apply.
A delegated contribution is already included in the transaction total. It changes
who accounts for that amount, without adding a second Store transfer.

$$
\begin{aligned}
\text{topTxNetUTxODepositChange}
&=\text{declaredTxTotalNetUTxODepositChange} \\
&\quad-\sum_{\text{subTx}\in\text{subTxs}}
  \text{locallyAccountedChange(subTx)}
\end{aligned}
$$

This is TopTx's **attributed amount**, including delegated child contributions.
Its **own change** comes only from its recorded inputs and newly priced outputs.
For exact declarations, the same responsibility can therefore be derived
independently as:

$$
\text{topTxNetUTxODepositChange}
=\text{ownNetDeposit(topTx)}
+\sum_{\text{subTx}\in\text{delegatingSubTxs}}
  \text{ownNetDeposit(subTx)}
$$

Example: TopTx allocates 2 ADA and its SubTx allocates 3 ADA.

| SubTx declaration | TopTx declares | Accounted in SubTx | Accounted in TopTx |
| --- | --- | ---: | ---: |
| Local allocation | Allocate 5 ADA | $+3$ ADA | $+2$ ADA |
| Funding requested from TopTx | Allocate 5 ADA | $0$ ADA | $+5$ ADA |

Local accounting does not require independent SubTx financial balance.
[Net change](#ds-tx-accounting-net-change) checks exact amounts;
[Balance](#ds-tx-accounting-balance) checks complete transaction funding.

<a id="ds-tx-attribution-p01" name="ds-tx-attribution-p01"></a>
<a id="ds-tx-attribution-n01" name="ds-tx-attribution-n01"></a>
<a id="ds-tx-settlement-participation-p02" name="ds-tx-settlement-participation-p02"></a>
<a id="ds-tx-accounting-attribution-p01" name="ds-tx-accounting-attribution-p01"></a>

###### 2.1.2.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L39) - Local and delegated contributions determine TopTx's share

$$
\begin{aligned}
\text{attributedTopTxChange}
  &=\text{ownTopTxChange}+\sum\text{delegatedSubTxChanges} \\
\text{localSubTxChanges}&=\text{expectedLocalChanges}
\end{aligned}
$$

Generate all six declaration forms from the table above. Observe production
accounting and compare it with independently measured input deposits and output
allocations. Local allocations contribute positively, local releases negatively;
requests and delegated releases remain in TopTx's share **exactly once**. Include
positive, zero and negative transaction totals, and TopTx's own nonzero operations.

This is an isolated accounting property. It establishes the signed responsibilities
used by settlement; it does not assert that a selector or destination is valid.

<a id="ds-tx-attribution-p02" name="ds-tx-attribution-p02"></a>
<a id="ds-tx-settlement-participation-p03" name="ds-tx-settlement-participation-p03"></a>
<a id="ds-tx-accounting-attribution-p02" name="ds-tx-accounting-attribution-p02"></a>

###### 2.1.2.2.2 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L67) - Delegation moves the signed contribution to TopTx

Keep the Store operations fixed and change one SubTx declaration from local to
delegated accounting. Here $\Delta$ means **delegated result minus local result**.

$$
\begin{aligned}
\text{local}\longrightarrow\text{delegated}
\implies\quad
&\Delta\text{localSubTxChange}=-\text{originatingChange} \\
&\land\Delta\text{attributedTopTxChange}=\text{originatingChange}
\end{aligned}
$$

| Originating SubTx change | Change in SubTx accounting | Change in TopTx accounting |
| --- | ---: | ---: |
| Allocation of 3 ADA | $-3$ ADA | $+3$ ADA |
| Release of 3 ADA | $+3$ ADA | $-3$ ADA |

The [Net change property](#ds-tx-accounting-net-change-toptx-p02) checks that the
transaction total stays unchanged. This property checks the responsibility shift.
It does not promise acceptance with unchanged selectors or outputs: moving a release
may require a different settlement destination or greater coverage.

<a id="ds-tx-grammar-n01" name="ds-tx-grammar-n01"></a>
<a id="ds-tx-declarations-grammar-n01" name="ds-tx-declarations-grammar-n01"></a>
<a id="ds-tx-attribution-n04" name="ds-tx-attribution-n04"></a>
<a id="ds-tx-settlement-participation-n10" name="ds-tx-settlement-participation-n10"></a>
<a id="ds-tx-accounting-attribution-n01" name="ds-tx-accounting-attribution-n01"></a>

###### 2.1.2.2.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L98) - Explicit zero adds no delegated contribution

$$
\begin{aligned}
&\text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)} \\
&\land\text{declaresExplicitZero(subTx)} \\
&\implies\text{originatingChange}=\text{localChange}=\text{delegatedChange}=0
\end{aligned}
$$

| SubTx operations | Declaration | Contribution to TopTx's share |
| --- | --- | ---: |
| No allocation or release | Explicit zero | $0$ |
| Equal positive allocations and releases | Explicit zero | $0$ |

Observe production accounting for both cases and submit otherwise valid transactions.
Explicit zero neither requests funding nor delegates a release; TopTx's attributed
amount remains its own contribution. Equal positive operations still require a
declaration, as specified under [Zero net change](#ds-tx-declarations-requirements-operations-zero-net-change).

<a id="ds-tx-conservation" name="ds-tx-conservation"></a>
<a id="ds-tx-accounting-balance" name="ds-tx-accounting-balance"></a>

##### 2.1.2.3 Balance

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
remains unapplied; [Ledger conservation](#ds-state-conservation) governs
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

###### 2.1.2.3.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L72) - The transaction conserves value when phase 2 is valid

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

###### 2.1.2.3.2 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L96) - Complete balance determines acceptance

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

###### 2.1.2.3.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L117) - Fund a net allocation once

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

###### 2.1.2.3.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L137) - Use a net release once

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

###### 2.1.2.3.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L155) - One SubTx funds another

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

###### 2.1.2.3.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L168) - A SubTx funds TopTx fees

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

###### 2.1.2.3.7 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L181) - One-lovelace deficit or surplus

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

###### 2.1.2.3.8 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L199) - Native-asset quantity or identity mismatch

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

###### 2.1.2.3.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L219) - An exact delegated allocation lacks funding

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

###### 2.1.2.3.10 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L234) - Equal delegated allocations and releases

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

###### 2.1.2.3.11 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L246) - Ten input ADA plus two released ADA

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

###### 2.1.2.3.12 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L255) - Released ADA contributes to TopTx fees

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

###### 2.1.2.3.13 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L265) - Released ADA cannot disappear

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

###### 2.1.2.3.14 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L280) - Balanced proposal, failed phase 2

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

<a id="ds-tx-authorization" name="ds-tx-authorization"></a>

#### 2.1.3 Authorization

> **Spending authority also authorizes release of the input's recorded deposit.**
>
> Funding a deposit gives no separate approval right over its later release.

**Decision:** Agreed.

| Role | Example | Required in the later spending transaction? |
| --- | --- | --- |
| Original deposit funder | Alice pays for a store-backed output controlled by Bob | Alice's signature is not required |
| Current spending authority | Bob's key controls that output | Bob's spending signature is required |

```text
Alice funds the store-backed output
  ├── spending key: Bob
  └── deposit recorded in the Store
            ↓
A later transaction consumes that output
  ├── Bob's valid signature, no Alice signature → accepted
  └── Alice's valid signature, no Bob signature → rejected
```

The release still needs exact [Accounting](#ds-tx-accounting) and valid
[Settlement](#ds-tx-settlement). A declaration or a settlement designation cannot
replace the input's spending witness. No separate DepositStore credential is added.

**Test conditions:** Alice and Bob have distinct keys. The consumed input is
key-controlled, its positive recorded deposit was funded by Alice, and accounting,
settlement and the remaining transaction requirements are valid. Phase 2 succeeds.
Both tests exercise all three placements in each generated sample:

| Consuming body | Release handling |
| --- | --- |
| Standalone TopTx | TopTx designates its settlement output |
| SubTx | SubTx designates its own settlement output |
| SubTx | SubTx delegates the release to TopTx |

$\text{spendingSignatures(body)}$ identifies the keys signing the body that consumes
the input; $\text{transactionSignatures(tx)}$ includes signatures across TopTx and its
SubTxs. These cases exercise ordinary successful spending. Collateral authority
belongs to the [shared collateral authorization rules](#ds-collateral-existing-rules).

<a id="ds-tx-authorization-n02" name="ds-tx-authorization-n02"></a>
<a id="ds-tx-authorization-n01" name="ds-tx-authorization-n01"></a>

##### 2.1.3.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L51) - Bob spends an output funded by Alice

$$
\begin{aligned}
&\text{depositFunder(input)}=\text{Alice} \\
&\land\text{spendingKey(input)}=\text{Bob} \\
&\land\text{Bob}\in\text{spendingSignatures(body)} \\
&\land\text{Alice}\notin\text{transactionSignatures(tx)} \\
&\implies\text{Accepted}
\end{aligned}
$$

Create and fund the output in an earlier ledger transaction. In the later spending
transaction, inspect the final witness set: Bob's spending signature is present;
Alice's is absent. Submit that signed transaction and expect acceptance. This single
case establishes both Bob's authority and the absence of an original-funder approval
requirement.

<a id="ds-tx-authorization-f01" name="ds-tx-authorization-f01"></a>

##### 2.1.3.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L73) - Alice's signature cannot replace Bob's

$$
\begin{aligned}
&\text{depositFunder(input)}=\text{Alice} \\
&\land\text{spendingKey(input)}=\text{Bob} \\
&\land\text{Alice}\in\text{spendingSignatures(body)} \\
&\land\text{Bob}\notin\text{spendingSignatures(body)} \\
&\implies\text{RejectedWith(missingSpendingWitness(body,Bob))}
\end{aligned}
$$

Keep the valid control's inputs, declarations, settlement and amounts unchanged.
Replace Bob's spending signature with a valid Alice signature for the same spending
body. Require only the existing missing-key-witness failure for Bob, then submit the
original control and require acceptance.

| Consuming body | Exact expected failure |
| --- | --- |
| TopTx | `MissingVKeyWitnessesUTXOW`, containing only Bob's key hash |
| SubTx | `SubMissingVKeyWitnessesUTXOW`, containing only Bob's key hash |

Alice's signature is valid cryptographically; it fails to supply the authority
required by the consumed output. In a SubTx case, re-sign the enclosing TopTx after
changing the child witnesses so that the parent's signature remains valid.

<a id="ds-tx-authorization-n03" name="ds-tx-authorization-n03"></a>

**Related rule — reference-only access.** [Release N09](#ds-tx-declarations-requirements-operations-release-n09)
already checks that referencing live store-backed outputs does not require a release
declaration. A reference does not consume the output or release its deposit. Declaring
an amount released from reference inputs would be an inexact [Accounting](#ds-tx-accounting-net-change)
claim, not a missing spending-witness failure. It is not an additional Authorization
test.

<a id="ds-tx-settlement" name="ds-tx-settlement"></a>

#### 2.1.4 Settlement

> **Determine which output must contain a release amount.**
>
> Designation $\longrightarrow$ output index $\longrightarrow$ output coin.
> Settlement uses the accounting result without adding another Store transfer.

| Check | Question |
| --- | --- |
| [Designation](#ds-tx-settlement-designation) | Must TopTx designate a settlement output? |
| [Output index](#ds-tx-settlement-output-index) | Does the selected index exist in the declaring body's own outputs? |
| [Output coin](#ds-tx-settlement-output-coin) | Does that output contain at least the required application ADA? |

<a id="ds-tx-settlement-participation" name="ds-tx-settlement-participation"></a>
<a id="ds-tx-settlement-designation" name="ds-tx-settlement-designation"></a>

##### 2.1.4.1 Designation

> **Determine whether TopTx must designate a settlement output.**
>
> Use its signed share from [Attribution](#ds-tx-accounting-attribution).
> Only a net-release declaration carries a TopTx settlement designation.

**Decision:** Agreed.

**When does TopTx need a settlement output?**

| Notation | Meaning |
| --- | --- |
| $\text{totalChange}$ | Signed net deposit change for TopTx and all SubTxs. |
| $\text{topTxChange}$ | TopTx's attributed change: its own operations plus delegated child changes. |
| $\text{hasTopTxOutput}$ | The declaration uses `TopTxSettlementOutput index`. |
| $\text{noTopTxOutput}$ | A release uses `NoTopTxSettlement`, or the declaration has no designation field. |

Only a net-release declaration carries this choice:

```haskell
TopTx.DeclaresNetUTxODepositRelease amount settlement

-- amount :: StrictlyPositiveCoin is the entire transaction's net release.
data TopTxReleaseSettlement
  = NoTopTxSettlement
  | TopTxSettlementOutput !TxIx
```

$$
\text{totalChange}<0
\implies
(\text{hasTopTxOutput}\iff\text{topTxChange}<0)
$$

| Transaction change | TopTx attributed change | Required declaration form |
| --- | --- | --- |
| Net release | Negative: TopTx has a release share | Release with `TopTxSettlementOutput index` |
| Net release | Zero or positive: TopTx has no release share | Release with `NoTopTxSettlement` |
| Net allocation | Any sign | Allocation; no designation field |
| Zero | Any sign | Explicit zero; no designation field |

`NoTopTxSettlement` does **not** mean zero transaction release: the SubTxs may settle
it locally. The declared release amount remains the whole transaction's net change.
TopTx's designated output is checked against its attributed share instead.

These exact net-release examples use ADA:

| Local SubTx change | TopTx attributed change | Transaction release | TopTx designation |
| ---: | ---: | ---: | --- |
| $-5$ | $0$ | 5 | None |
| $-3$ | $-2$ | 5 | Required; share is 2 |
| $+3$ | $-5$ | 2 | Required; share is 5 |
| $-5$ | $+3$ | 2 | None |

[Output index](#ds-tx-settlement-output-index) resolves the designated output within
TopTx's own outputs; [Output coin](#ds-tx-settlement-output-coin) checks its ADA.
Neither changes the transaction's net Store transfer.

**Test conditions:** Amounts are exact, designated indices resolve, outputs contain
sufficient ADA and the transaction is otherwise valid. Phase-2 cases contain a real
failing script and valid collateral. These conditions isolate designation itself.

<a id="ds-tx-settlement-participation-p01" name="ds-tx-settlement-participation-p01"></a>
<a id="ds-tx-settlement-designation-p01" name="ds-tx-settlement-designation-p01"></a>

###### 2.1.4.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L47) - Designation follows TopTx's release share

$$
\text{totalChange}<0
\implies(\text{designationValid}\iff(\text{hasTopTxOutput}\iff\text{topTxChange}<0))
$$

For each generated net-release proposal, check both designation choices and both local and delegated child releases. Compare the isolated validator with an expectation derived from recorded input deposits and priced outputs, independently of production attribution.

<a id="ds-tx-settlement-participation-n01" name="ds-tx-settlement-participation-n01"></a>
<a id="ds-tx-settlement-designation-n01" name="ds-tx-settlement-designation-n01"></a>

###### 2.1.4.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L69) - SubTxs settle the entire release

$$
\text{totalChange}<0\land\text{topTxChange}=0\land\text{noTopTxOutput}
\implies\text{Accepted}
$$

Every SubTx settles its release locally. TopTx has no remaining release share, so its exact total declaration uses `NoTopTxSettlement`.

<a id="ds-tx-settlement-participation-n02" name="ds-tx-settlement-participation-n02"></a>
<a id="ds-tx-settlement-designation-n02" name="ds-tx-settlement-designation-n02"></a>

###### 2.1.4.1.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L82) - Standalone TopTx settles its release

$$
\text{totalChange}<0\land\text{topTxChange}<0\land\text{hasTopTxOutput}
\implies\text{Accepted}
$$

A standalone TopTx releases deposits and designates one of its outputs. With no SubTx contribution, its attributed share is the complete transaction release.

<a id="ds-tx-settlement-participation-n03" name="ds-tx-settlement-participation-n03"></a>
<a id="ds-tx-settlement-designation-n03" name="ds-tx-settlement-designation-n03"></a>

###### 2.1.4.1.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L93) - TopTx and SubTxs each settle a share

$$
\begin{aligned}
&\text{topTxChange}<0 \\
&\land(\forall\,\text{subTx}\in\text{subTxs}:\text{localChange(subTx)}<0) \\
&\land\text{allRequiredOutputsDesignated} \\
&\implies\text{Accepted}
\end{aligned}
$$

Generate releases in TopTx and several SubTxs. Each child designates its own output; TopTx designates an output for its remaining share. The total declaration includes all releases once.

<a id="ds-tx-settlement-participation-n04" name="ds-tx-settlement-participation-n04"></a>
<a id="ds-tx-settlement-designation-n04" name="ds-tx-settlement-designation-n04"></a>

###### 2.1.4.1.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L106) - TopTx's share exceeds the transaction release

$$
\begin{aligned}
&\text{totalChange}<0\land\text{localSubTxChange}>0 \\
&\implies\text{requiredTopTxOutputADA}>-\text{totalChange} \\
&\qquad\land\text{Accepted}
\end{aligned}
$$

A local child allocation reduces the transaction release without reducing TopTx’s own release share. For example, $+3$ ADA in SubTx and $-5$ ADA in TopTx produce a release of 2 ADA. TopTx still designates a sufficiently funded output for its 5 ADA share.

<a id="ds-tx-settlement-participation-f01" name="ds-tx-settlement-participation-f01"></a>
<a id="ds-tx-settlement-designation-f01" name="ds-tx-settlement-designation-f01"></a>

###### 2.1.4.1.6 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L120) - TopTx omits a required output

$$
\begin{aligned}
&\text{totalChange}<0\land\text{topTxChange}<0\land\text{noTopTxOutput} \\
&\implies\text{RejectedWith(MissingTopTxSettlement)}
\end{aligned}
$$

Keep the total exact and the transaction funded, but use `NoTopTxSettlement` despite TopTx having a positive release share. Require the missing-designation failure.

<a id="ds-tx-settlement-participation-f02" name="ds-tx-settlement-participation-f02"></a>
<a id="ds-tx-settlement-designation-f02" name="ds-tx-settlement-designation-f02"></a>

###### 2.1.4.1.7 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L131) - TopTx designates an unnecessary output

$$
\begin{aligned}
&\text{totalChange}<0\land\text{topTxChange}=0\land\text{hasTopTxOutput} \\
&\implies\text{RejectedWith(UnexpectedTopTxSettlement)}
\end{aligned}
$$

All releases are settled locally by SubTxs. An additional TopTx designation is rejected, even though its index and output coin would otherwise be valid.

<a id="ds-tx-settlement-participation-n05" name="ds-tx-settlement-participation-n05"></a>
<a id="ds-tx-settlement-designation-n05" name="ds-tx-settlement-designation-n05"></a>

###### 2.1.4.1.8 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L144) - Net allocation, even though TopTx releases

$$
\text{totalChange}>0\land\text{topTxChange}<0\land\text{noTopTxOutput}
\implies\text{Accepted}
$$

Local SubTx allocations exceed TopTx’s release. The complete transaction declares an allocation, whose grammar has no settlement designation. A negative TopTx share does not introduce one.

<a id="ds-tx-settlement-participation-n06" name="ds-tx-settlement-participation-n06"></a>
<a id="ds-tx-settlement-designation-n06" name="ds-tx-settlement-designation-n06"></a>

###### 2.1.4.1.9 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L157) - Explicit-zero total, even though TopTx releases

$$
\text{totalChange}=0\land\text{topTxChange}<0\land\text{noTopTxOutput}
\implies\text{Accepted}
$$

Local SubTx allocations exactly offset TopTx’s release. TopTx declares explicit zero; that declaration has no designation field.

<a id="ds-tx-settlement-participation-n07" name="ds-tx-settlement-participation-n07"></a>
<a id="ds-tx-settlement-designation-n07" name="ds-tx-settlement-designation-n07"></a>

###### 2.1.4.1.10 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L170) - Net release, while TopTx allocates

$$
\text{totalChange}<0\land\text{topTxChange}>0\land\text{noTopTxOutput}
\implies\text{Accepted}
$$

Local SubTx releases exceed TopTx’s allocation. The complete transaction releases deposits, but TopTx has no release share. Accept `NoTopTxSettlement`; zero and positive attributed changes both permit it.

<a id="ds-tx-settlement-participation-n08" name="ds-tx-settlement-participation-n08"></a>
<a id="ds-tx-settlement-designation-n08" name="ds-tx-settlement-designation-n08"></a>

###### 2.1.4.1.11 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L183) - Valid designation when phase 2 fails

$$
\text{phase2Invalid}\land\text{totalChange}<0\land\text{designationValid}
\implies\text{Accepted}
$$

Use both valid choices with an actual failing script: designate a TopTx output when it has a release share, and use `NoTopTxSettlement` when the SubTxs settle the complete release locally. The ordinary designation is validated before collateral-only execution.

<a id="ds-tx-settlement-participation-f03" name="ds-tx-settlement-participation-f03"></a>
<a id="ds-tx-settlement-designation-f03" name="ds-tx-settlement-designation-f03"></a>

###### 2.1.4.1.12 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L199) - Invalid designation when phase 2 fails

$$
\text{phase2Invalid}\land\text{totalChange}<0\land\neg\text{designationValid}
\implies\text{Rejected}
$$

From the valid phase-2-invalid controls, omit a required TopTx designation or supply one when TopTx has no release share. Require `MissingTopTxSettlement` or `UnexpectedTopTxSettlement`, respectively.

<a id="ds-tx-settlement-destination" name="ds-tx-settlement-destination"></a>
<a id="ds-tx-settlement-output-index" name="ds-tx-settlement-output-index"></a>

##### 2.1.4.2 Output index

> **Resolve the index in the declaring body's own regular outputs.**
>
> Another body's output or collateral return cannot satisfy that index.

**Decision:** Agreed.

| Declaration | Sequence used to resolve its index |
| --- | --- |
| `TopTxSettlementOutput index` | TopTx's own regular outputs |
| `SubTxSettlementOutput index` | That SubTx's own regular outputs |
| `DelegateToTopTx` | No local SubTx index; TopTx handles settlement |

$$
0\le\text{index}<|\text{ownOutputs(body)}|
$$

```text
TopTx outputs     [0, 1, 2]
SubTx A outputs   [0, 1]
SubTx B outputs   [0, 1, 2]

SubTx A selects 2 → rejected
  TopTx's output 2 and SubTx B's output 2 do not belong to A.
```

Collateral return has its own role and does not extend the regular output sequence.
A SubTx with no outputs has no valid local index. It can explicitly delegate its
release to TopTx instead.

**Test conditions:** Declarations and designations are correct, selected existing
outputs have enough ADA, and transactions are funded. Negative cases change the
index while preserving those conditions. The primitive index range belongs to
[Grammar](#ds-tx-declarations-grammar); these tests check whether the indexed output
exists. [Output coin](#ds-tx-settlement-output-coin) checks the separate ADA bound.

<a id="ds-tx-settlement-destination-p01" name="ds-tx-settlement-destination-p01"></a>
<a id="ds-tx-settlement-output-index-p01" name="ds-tx-settlement-output-index-p01"></a>

###### 2.1.4.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L60) - The index belongs to the declaring body

$$
\begin{aligned}
&\text{outputCoins}\ge\text{requiredRelease} \\
&\implies(\text{indexValid(body,index)}\iff0\le\text{index}<|\text{ownOutputs(body)}|)
\end{aligned}
$$

Generate ordinary output sequences, including an empty sequence. For TopTx and SubTx separately, compare the isolated validator with the sequence-length predicate at the first, last and out-of-range positions. Existing outputs have sufficient ADA, so only index membership can fail.

<a id="ds-tx-settlement-destination-f01" name="ds-tx-settlement-destination-f01"></a>
<a id="ds-tx-settlement-output-index-f01" name="ds-tx-settlement-output-index-f01"></a>

###### 2.1.4.2.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L77) - The first missing own index is rejected

$$
\text{index}=|\text{ownOutputs(body)}|
\implies\text{RejectedWith(InvalidSettlementOutput)}
$$

Starting from a valid proposal, select the index immediately after the final output. Test TopTx and each SubTx separately, require the exact index failure, then accept the unchanged control.

<a id="ds-tx-settlement-destination-f02" name="ds-tx-settlement-destination-f02"></a>
<a id="ds-tx-settlement-output-index-f02" name="ds-tx-settlement-output-index-f02"></a>

###### 2.1.4.2.3 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L100) - A SubTx cannot select TopTx's output

$$
\begin{aligned}
&|\text{ownOutputs(subTx)}|\le\text{index}<|\text{ownOutputs(topTx)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(subTx))}
\end{aligned}
$$

Give TopTx one more output than its SubTx. The child selects the index that exists only in TopTx. The ledger rejects the child’s target; the parent’s larger sequence cannot satisfy it.

<a id="ds-tx-settlement-destination-f03" name="ds-tx-settlement-destination-f03"></a>
<a id="ds-tx-settlement-output-index-f03" name="ds-tx-settlement-output-index-f03"></a>

###### 2.1.4.2.4 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L121) - Collateral return is outside the ordinary output sequence

$$
\begin{aligned}
&\text{collateralReturn}\ne\varnothing \\
&\land\text{index}=|\text{ownOutputs(topTx)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(topTx))}
\end{aligned}
$$

Use a genuinely phase-2-invalid transaction with collateral return. Select the index immediately after TopTx’s regular outputs, where collateral return receives its output reference. Reject that ordinary settlement target, then accept the control with a valid regular-output index.

<a id="ds-tx-settlement-destination-f04" name="ds-tx-settlement-destination-f04"></a>
<a id="ds-tx-settlement-output-index-f04" name="ds-tx-settlement-output-index-f04"></a>

###### 2.1.4.2.5 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L142) - A SubTx without outputs cannot settle locally

$$
\begin{aligned}
&\text{ownOutputs(subTx)}=\varnothing \\
&\land\text{releasedDeposits(subTx)}>0\land\text{localIndex}=0 \\
&\implies\text{RejectedWith(InvalidSettlementOutput(subTx))}
\end{aligned}
$$

Start with a valid delegated final release. Replace delegation with local output zero, and remove TopTx’s now-unnecessary designation. The child has no output zero: reject precisely that index. The delegated control remains accepted.

<a id="ds-tx-settlement-destination-n01" name="ds-tx-settlement-destination-n01"></a>
<a id="ds-tx-settlement-output-index-n01" name="ds-tx-settlement-output-index-n01"></a>

###### 2.1.4.2.6 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L161) - The first and last own outputs are valid

$$
\begin{aligned}
&|\text{ownOutputs(body)}|>0 \\
&\land\text{index}\in\{0,|\text{ownOutputs(body)}|-1\} \\
&\implies\text{Accepted}
\end{aligned}
$$

At both body levels, designate the first output and then the last output. Each choice uses fresh funded inputs and sufficient output coin.

<a id="ds-tx-settlement-destination-f05" name="ds-tx-settlement-destination-f05"></a>
<a id="ds-tx-settlement-output-index-f05" name="ds-tx-settlement-output-index-f05"></a>

###### 2.1.4.2.7 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L175) - TopTx cannot select a SubTx's output

$$
\begin{aligned}
&|\text{ownOutputs(topTx)}|\le\text{index}<|\text{ownOutputs(subTx)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(topTx))}
\end{aligned}
$$

Give a nested SubTx one more output than TopTx. The index exists in the child but not in TopTx, so a TopTx designation using it is rejected.

<a id="ds-tx-settlement-destination-f06" name="ds-tx-settlement-destination-f06"></a>
<a id="ds-tx-settlement-output-index-f06" name="ds-tx-settlement-output-index-f06"></a>

###### 2.1.4.2.8 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L194) - A SubTx cannot select a sibling's output

$$
\begin{aligned}
&|\text{ownOutputs(subTx)}|\le\text{index}<|\text{ownOutputs(sibling)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(subTx))}
\end{aligned}
$$

Give the sibling one more output than the declaring SubTx. Both children release deposits, but each owns a separate output sequence. The declaring child cannot borrow the sibling’s longer sequence.

<a id="ds-tx-settlement-destination-n02" name="ds-tx-settlement-destination-n02"></a>
<a id="ds-tx-settlement-output-index-n02" name="ds-tx-settlement-output-index-n02"></a>

###### 2.1.4.2.9 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L215) - Valid output indices when phase 2 fails

$$
\begin{aligned}
&\text{phase2Invalid} \\
&\land(\forall\,\text{body}:0\le\text{selectedIndex(body)}<|\text{ownOutputs(body)}|) \\
&\implies\text{Accepted}
\end{aligned}
$$

Use a real failing script and designate the final own regular output at both body levels. The ordinary indices are validated even though the collateral outcome does not create those ordinary outputs.

<a id="ds-tx-settlement-destination-f07" name="ds-tx-settlement-destination-f07"></a>
<a id="ds-tx-settlement-output-index-f07" name="ds-tx-settlement-output-index-f07"></a>

###### 2.1.4.2.10 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L229) - An invalid output index still fails when phase 2 fails

$$
\begin{aligned}
&\text{phase2Invalid}\land\text{selectedIndex(body)}=|\text{ownOutputs(body)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput)}
\end{aligned}
$$

From a valid phase-2-invalid control, replace one index with the first out-of-range index. Exercise TopTx and each SubTx separately while keeping collateral valid. The invalid outcome flag does not waive ordinary index validation.

<a id="ds-tx-attribution-n03" name="ds-tx-attribution-n03"></a>
<a id="ds-tx-settlement-participation-n09" name="ds-tx-settlement-participation-n09"></a>
<a id="ds-tx-settlement-output-index-n03" name="ds-tx-settlement-output-index-n03"></a>

###### 2.1.4.2.11 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L253) - A SubTx without outputs delegates its final release

$$
\begin{aligned}
&\text{ownOutputs(subTx)}=\varnothing \\
&\land\text{releasedDeposits(subTx)}>0 \\
&\land\text{delegatesReleaseToTopTx(subTx)} \\
&\implies\text{Accepted}
\end{aligned}
$$

The SubTx spends its final store-backed inputs and creates no replacement output. Its exact release declaration uses `DelegateToTopTx`; there is no local index to resolve. TopTx declares the exact total and designates a sufficiently funded output of its own. The signed transaction is accepted, and its SubTx output sequence is checked to remain empty.

<a id="ds-tx-settlement-coverage" name="ds-tx-settlement-coverage"></a>
<a id="ds-tx-settlement-output-coin" name="ds-tx-settlement-output-coin"></a>

##### 2.1.4.3 Output coin

> **Check the ADA already present in the selected output.**
>
> $\text{applicationADA(selectedOutput)}\ge\text{requiredSettlement(body)}$.
> External deposits do not count toward this bound.

**Decision:** Agreed.

Assume the required designation is present and its index resolves to an existing
output. This rule then compares two amounts:

| Amount | TopTx | SubTx settling locally |
| --- | --- | --- |
| Required settlement | $\max(0,-\text{attributedTopTxChange})$ | The SubTx's declared release |
| Available coin | Application ADA in the selected TopTx output | Application ADA in the selected SubTx output |

For an implicit output, application ADA is its full coin value. For a store-backed
output, the external deposit remains separate from application ADA.

Example: TopTx's required share is 2 ADA.

| Selected output | Application ADA | External deposit | Result |
| --- | ---: | ---: | --- |
| Implicit | 2 ADA | — | Accepted |
| Implicit | 4 ADA | — | Accepted |
| Store-backed | 2 ADA | 1 ADA | Accepted |
| Store-backed | 1 ADA | 1 ADA | Rejected |

The last row still lacks one application ADA. The external deposit cannot fill the
shortfall. TopTx's required share may be smaller or larger than the transaction's
net Store release; compare against the **share**, not the transaction total.

This is a lower bound on the final output coin. It does not identify where those
coins came from, require independent SubTx balance or prevent SubTx fee exports.
The stronger local-settlement guarantee remains open in [A.3](#ds-tx-settlement-refinement).

**Test conditions:** Declarations, designations and indices are valid. Ledger cases
preserve complete transaction balance, including rejection cases; a shortfall in
the selected output is moved to another output. Both body levels are exercised.
Phase-2 cases use a real failing script and valid collateral. One unit in a boundary
comparison means one lovelace.

<a id="ds-tx-settlement-coverage-p01" name="ds-tx-settlement-coverage-p01"></a>
<a id="ds-tx-settlement-output-coin-p01" name="ds-tx-settlement-output-coin-p01"></a>

###### 2.1.4.3.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L43) - Output ADA must cover the required share

$$
\text{passesOutputCoinValidation}
\iff\text{applicationADA(selectedOutput)}\ge\text{requiredSettlement(body)}
$$

Compare the isolated output-coin validator with the independent lower-bound predicate. Generate exact amounts, surplus and shortfall for TopTx and SubTx, using both implicit and store-backed outputs. This equivalence concerns output coin only.

<a id="ds-tx-settlement-coverage-f01" name="ds-tx-settlement-coverage-f01"></a>
<a id="ds-tx-settlement-output-coin-f01" name="ds-tx-settlement-output-coin-f01"></a>

###### 2.1.4.3.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L56) - Implicit output, one lovelace short

$$
\begin{aligned}
&\text{implicit(selectedOutput)} \\
&\land\text{applicationADA(selectedOutput)}=\text{requiredSettlement(body)}-1 \\
&\implies\text{RejectedWith(InsufficientSettlementOutput)}
\end{aligned}
$$

The index exists and all declarations are exact. Move one lovelace from the designated implicit output to another output, then require the output-coin failure.

<a id="ds-tx-settlement-coverage-n01" name="ds-tx-settlement-coverage-n01"></a>
<a id="ds-tx-settlement-output-coin-n01" name="ds-tx-settlement-output-coin-n01"></a>

###### 2.1.4.3.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L77) - Implicit output, exact amount

$$
\text{implicit(selectedOutput)}
\land\text{applicationADA(selectedOutput)}=\text{requiredSettlement(body)}
\implies\text{Accepted}
$$

Exact equality is sufficient. Test the boundary for TopTx and for a SubTx settling locally.

<a id="ds-tx-settlement-coverage-n02" name="ds-tx-settlement-coverage-n02"></a>
<a id="ds-tx-settlement-output-coin-n02" name="ds-tx-settlement-output-coin-n02"></a>

###### 2.1.4.3.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L97) - Implicit output, extra ADA

$$
\text{implicit(selectedOutput)}
\land\text{applicationADA(selectedOutput)}>\text{requiredSettlement(body)}
\implies\text{Accepted}
$$

The selected implicit output may contain additional ADA. Its coin value need not equal the required share.

<a id="ds-tx-settlement-coverage-f02" name="ds-tx-settlement-coverage-f02"></a>
<a id="ds-tx-settlement-output-coin-f02" name="ds-tx-settlement-output-coin-f02"></a>

###### 2.1.4.3.5 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L117) - An external deposit cannot fill the ADA shortfall

$$
\begin{aligned}
&\text{storeBacked(selectedOutput)} \\
&\land\text{applicationADA(selectedOutput)}=\text{requiredSettlement(body)}-1 \\
&\land\text{applicationADA(selectedOutput)}+\text{externalDeposit(selectedOutput)}
  \ge\text{requiredSettlement(body)} \\
&\implies\text{RejectedWith(InsufficientSettlementOutput)}
\end{aligned}
$$

Select a store-backed output whose application ADA is one lovelace short. Even though adding its external deposit would exceed the required amount, the ledger rejects the application-ADA shortfall.

<a id="ds-tx-settlement-coverage-n03" name="ds-tx-settlement-coverage-n03"></a>
<a id="ds-tx-settlement-output-coin-n03" name="ds-tx-settlement-output-coin-n03"></a>

###### 2.1.4.3.6 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L140) - Store-backed output, exact application ADA

$$
\text{storeBacked(selectedOutput)}
\land\text{applicationADA(selectedOutput)}=\text{requiredSettlement(body)}
\implies\text{Accepted}
$$

Allocate the external deposit independently and place exactly the required settlement amount in the output’s application ADA. The separate deposit does not increase or reduce the bound.

<a id="ds-tx-settlement-coverage-n04" name="ds-tx-settlement-coverage-n04"></a>
<a id="ds-tx-settlement-output-coin-n04" name="ds-tx-settlement-output-coin-n04"></a>

###### 2.1.4.3.7 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L161) - TopTx's share is smaller than the transaction release

$$
\begin{aligned}
&0<\text{topTxSettlement}<\text{transactionRelease} \\
&\land\text{applicationADA(selectedTopTxOutput)}=\text{topTxSettlement} \\
&\implies\text{Accepted}
\end{aligned}
$$

For example, the transaction releases 5 ADA: a SubTx settles 3 ADA locally and TopTx settles 2 ADA. A selected TopTx output containing 2 ADA is sufficient; it need not contain all 5 ADA.

<a id="ds-tx-settlement-coverage-n05" name="ds-tx-settlement-coverage-n05"></a>
<a id="ds-tx-settlement-output-coin-n05" name="ds-tx-settlement-output-coin-n05"></a>

###### 2.1.4.3.8 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L177) - Exact output ADA when phase 2 fails

$$
\text{phase2Invalid}
\land\text{applicationADA(selectedOutput)}=\text{requiredSettlement(body)}
\implies\text{Accepted}
$$

Use a real failing script with exactly the required coin in the designated ordinary output. Its proposed output-coin check passes before the collateral outcome, although ordinary outputs are not applied.

<a id="ds-tx-settlement-coverage-f03" name="ds-tx-settlement-coverage-f03"></a>
<a id="ds-tx-settlement-output-coin-f03" name="ds-tx-settlement-output-coin-f03"></a>

###### 2.1.4.3.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L197) - One lovelace short when phase 2 fails

$$
\begin{aligned}
&\text{phase2Invalid} \\
&\land\text{applicationADA(selectedOutput)}=\text{requiredSettlement(body)}-1 \\
&\implies\text{RejectedWith(InsufficientSettlementOutput)}
\end{aligned}
$$

From the valid phase-2-invalid controls, move one lovelace out of the selected output. The declared invalid script outcome does not excuse insufficient ordinary output coin.

<a id="ds-tx-settlement-coverage-f04" name="ds-tx-settlement-coverage-f04"></a>
<a id="ds-tx-settlement-output-coin-f04" name="ds-tx-settlement-output-coin-f04"></a>

###### 2.1.4.3.10 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L219) - The transaction release is smaller than TopTx's share

$$
\begin{aligned}
&\text{transactionRelease}<\text{topTxSettlement} \\
&\land\text{applicationADA(selectedTopTxOutput)}=\text{transactionRelease} \\
&\implies\text{RejectedWith(InsufficientSettlementOutput)}
\end{aligned}
$$

A SubTx allocation of 3 ADA and a TopTx release of 5 ADA produce a transaction release of 2 ADA. A TopTx output containing only 2 ADA fails: its required share is 5 ADA. Put the other 3 ADA elsewhere so the rejection isolates the selected output’s shortfall.

<a id="ds-tx-application-assets" name="ds-tx-application-assets"></a>
<a id="ds-tx-minimum-coin" name="ds-tx-minimum-coin"></a>

#### 2.1.5 Minimum coin

> **A Store-backed output pays for storage externally; an implicit output retains its minimum ADA.**

| Output form | Storage cost | Application ADA |
| --- | --- | --- |
| Store-backed | Fully funded external deposit, with an exact declaration | May be zero |
| Implicit | Existing minimum coin retained in the output | At least the required minimum |

For an implicit output, the existing byte-based minimum is:

$$
\text{minimumCoin(output)}
=\text{coinsPerUTxOByte}\times\bigl(160+\text{acceptedSize(output)}\bigr)
$$

`acceptedSize(output)` is the encoded size of the submitted output, including its coin.
The Store-backed exemption changes where storage is paid; it does not waive the
[allocation declaration](#ds-tx-declarations-requirements-operations-allocation),
[exact deposit accounting](#ds-tx-accounting-net-change-subtx), or other output constraints.

**Common premises:** valid addresses, nonnegative assets, exact declarations and fully
funded transactions. Each generated sample exercises both TopTx and SubTx outputs,
with successful phase 2 and with a real failing script. On the latter path,
**Accepted** means that the ledger accepts the collateral outcome; ordinary outputs
are checked but not created.

<a id="ds-tx-application-assets-n01" name="ds-tx-application-assets-n01"></a>
<a id="ds-tx-minimum-coin-n01" name="ds-tx-minimum-coin-n01"></a>

##### 2.1.5.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L47) - Native assets without ADA

$$
\begin{aligned}
&\text{storeBacked(output)} \\
&\land\text{nativeAssets(output)}\neq\varnothing
\land\text{applicationADA(output)}=0 \\
&\implies\text{Accepted}
\end{aligned}
$$

The output carries tokens and zero lovelace. Its full deposit is funded externally,
so it needs no application ADA to pay for storage.

<a id="ds-tx-application-assets-n02" name="ds-tx-application-assets-n02"></a>
<a id="ds-tx-minimum-coin-n02" name="ds-tx-minimum-coin-n02"></a>

##### 2.1.5.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L61) - Datum or reference script without assets

$$
\begin{aligned}
&\text{storeBacked(output)}\land\text{applicationAssets(output)}=\varnothing \\
&\land\text{payload(output)}\in\{\text{datumOnly},\text{referenceScriptOnly}\} \\
&\implies\text{Accepted}
\end{aligned}
$$

Exercise both payload forms in every sample. Neither output carries ADA or tokens;
the datum or script bytes still contribute to its fully funded external deposit.

<a id="ds-tx-application-assets-n03" name="ds-tx-application-assets-n03"></a>
<a id="ds-tx-minimum-coin-n03" name="ds-tx-minimum-coin-n03"></a>

##### 2.1.5.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L75) - Address-only output

$$
\text{storeBacked(output)}\land\text{addressOnly(output)}
\implies\text{Accepted}
$$

Here, address-only means:

$$
\begin{aligned}
\text{addressOnly(output)}\iff{}&\text{applicationAssets(output)}=\varnothing \\
&\land\neg\text{hasDatum(output)}\land\neg\text{hasReferenceScript(output)}
\end{aligned}
$$

The output retains its address and required encoding fields. It still occupies
storage and requires its full deposit; mandatory fields are not removed.

<a id="ds-tx-application-assets-n04" name="ds-tx-application-assets-n04"></a>
<a id="ds-tx-minimum-coin-n04" name="ds-tx-minimum-coin-n04"></a>

##### 2.1.5.4 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L89) - Exact minimum for an implicit output

$$
\begin{aligned}
&\text{implicit(output)} \\
&\land\text{outputADA(output)}=\text{minimumCoin(output)} \\
&\implies\text{Accepted}
\end{aligned}
$$

The existing minimum is inclusive. Price the final encoded output independently,
then submit it with exactly that amount. This is the accepted control for F01.

<a id="ds-tx-application-assets-f01" name="ds-tx-application-assets-f01"></a>
<a id="ds-tx-minimum-coin-f01" name="ds-tx-minimum-coin-f01"></a>

##### 2.1.5.5 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L98) - Implicit output one lovelace short

$$
\begin{aligned}
&\text{implicit(output)} \\
&\land\text{outputADA(output)}=\text{minimumCoin(output)}-1 \\
&\implies\text{Rejected}
\end{aligned}
$$

Move one lovelace from the exact-minimum output into another valid output, preserving
financial balance and the coin's encoded width. Check the shortfall against the
submitted output's encoded size. The ledger must reject only the owner body's
existing minimum-coin failure, identifying that output and its required amount:

| Output owner | Expected failure |
| --- | --- |
| TopTx | `BabbageOutputTooSmallUTxO` |
| SubTx | `SubBabbageOutputTooSmallUTxO` |

Submit the original exact-minimum transaction afterward and require acceptance,
confirming that the one-lovelace shortfall caused the rejection.

<a id="ds-collateral" name="ds-collateral"></a>

### 2.2 Collateral

> **Use the existing collateral fields; account for the deposits held outside outputs.**
>
> `TxOut era` already expresses implicit and store-backed inputs and returns. No separate collateral Store declaration is needed.

TopTx supplies the shared set of collateral inputs, at most one collateral return,
and an optional total. Inputs remain `TxIn` references: the ledger resolves each
output and its recorded deposit. SubTxs use this same collateral arrangement.

| Store responsibility | Question answered |
| --- | --- |
| [Funding](#ds-collateral-funding) | Do input coins cover the return, additional deposit and minimum fee? |
| [Total](#ds-collateral-total) | Does the optional total exclude released deposits and include coin-funded deposits? |
| [Assets](#ds-collateral-assets) | Are native assets preserved across both output representations? |

Applied allocation records and balances belong to [Ledger effects](#ds-state).
[Fees](#ds-state-fees) owns released-deposit surplus;
[Conservation](#ds-state-conservation) checks the resulting monetary total.

<a id="ds-collateral-existing-rules" name="ds-collateral-existing-rules"></a>
<a id="ds-collateral-scope" name="ds-collateral-scope"></a>
<a id="221-scope" name="221-scope"></a>
<a id="ds-collateral-authorization" name="ds-collateral-authorization"></a>
<a id="222-authorization" name="222-authorization"></a>

**Existing collateral rules**

The [Dijkstra Imp suite](../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Imp.hs#L38)
inherits the [Conway](../eras/conway/impl/testlib/Test/Cardano/Ledger/Conway/Imp.hs#L55),
[Babbage](../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp.hs#L36)
and [Alonzo](../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp.hs#L31)
suites. These are shared tests executed with Dijkstra, not tests to duplicate under
DepositStore. Their collateral fixtures use implicit outputs; Store-backed
integration remains a separate coverage obligation.

| Contract | Existing executable reference | Scope of that evidence |
| --- | --- | --- |
| Every collateral input resolves to an unspent output | Alonzo UTXO: [unknown input](../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxoSpec.hs#L47), [already spent](../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxoSpec.hs#L57) | Rejects bad references in Dijkstra too. |
| Collateral covers the fee percentage, even if scripts succeed | Alonzo UTXO: [insufficient collateral](../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxoSpec.hs#L92) | Existing percentage and ceiling rule; no external deposits. |
| Each collateral payment key supplies its witness | Alonzo UTXOW: [missing collateral witness](../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxowSpec/Invalid.hs#L205) | Missing witness for an implicit input. |
| A supplied total equals input coins minus return coins | Babbage UTXOS: [incorrect collateral total](../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp/UtxosSpec.hs#L155) | Mismatch rejected with successful scripts; implicit return. |
| Phase-2 failure can return collateral without a supplied total | Babbage UTXOW: [use a collateral output](../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp/UtxowSpec/Invalid.hs#L125) | Accepted failure-path implicit return; omission is incidental coverage. |
| Return-output validity is checked without redeemers | Dijkstra UTXO: [pointer address in collateral return](../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Imp/UtxoSpec.hs#L54) | Rejects an invalid address; does not cover the minimum-coin or input-count boundaries. |

These links establish test ownership and registration, not a new passing run.
`disableInConformanceIt` retains the implementation check while disabling its
[conformance comparison](../eras/shelley/impl/testlib/Test/Cardano/Ledger/Shelley/ImpTest.hs#L852).
Recorded executions remain in the [verification record](dijkstra-deposit-store-verification.md).

The shared trigger is (`subTxRedeemers` is the union of all children’s redeemers):

$$
\left(\mathit{topTxRedeemers}\ne\varnothing\ \lor\ \mathit{subTxRedeemers}\ne\varnothing\right)
\implies \mathit{collateralInputs}\ne\varnothing
$$

It activates funding, supplied-total, key-locked eligibility and native-asset
checks. Input resolution, payment-key witnesses, return-output validity and the
input-count limit remain independently required. Script success does not waive
validation; [Execution](#ds-state-execution) determines which effects apply.

**Shared regressions still to add or extend**

The contracts below remain required regressions in the shared collateral suites.
The inherited references above do not establish these missing cases.
Each regression keeps unrelated inputs, declarations, script purposes and witnesses
valid, and includes an accepted control.

| Contract | Missing regression |
| --- | --- |
| <a id="ds-collateral-scope-f01" name="ds-collateral-scope-f01"></a><a id="2211-f01---rejects-toptx-redeemers-without-collateral" name="2211-f01---rejects-toptx-redeemers-without-collateral"></a>TopTx alone has redeemers $\implies$ collateral is required. | A real, correctly witnessed TopTx script without collateral must produce `NoCollateralInputs`; include a funded control and both script outcomes. Empty collateral may also produce a funding failure. |
| <a id="ds-collateral-scope-f02" name="ds-collateral-scope-f02"></a><a id="2212-f02---rejects-subtx-redeemers-without-collateral-even-when-toptx-has-none" name="2212-f02---rejects-subtx-redeemers-without-collateral-even-when-toptx-has-none"></a>Only a SubTx has redeemers $\implies$ shared collateral is required. | Use a correctly indexed child redeemer with no parent redeemers; require `NoCollateralInputs`, with a funded control and both script outcomes. |
| <a id="ds-collateral-scope-f03" name="ds-collateral-scope-f03"></a><a id="2213-f03---rejects-redeemers-in-both-toptx-and-subtxs-without-collateral" name="2213-f03---rejects-redeemers-in-both-toptx-and-subtxs-without-collateral"></a>Both levels have redeemers $\implies$ shared collateral is required. | The combined case must also produce `NoCollateralInputs`; having both locations cannot cancel the trigger. |
| <a id="ds-collateral-scope-n02" name="ds-collateral-scope-n02"></a><a id="2215-n02---does-not-apply-redeemer-gated-funding-or-supplied-total-checks-when-no-body-has-redeemers" name="2215-n02---does-not-apply-redeemer-gated-funding-or-supplied-total-checks-when-no-body-has-redeemers"></a>No body has redeemers $\implies$ skip gated funding and supplied-total comparisons. | Supply resolved inputs and a valid return; independently underfund the potential fee, mismatch the total, then combine both. Other rules still hold; ordinary acceptance is expected. |
| <a id="ds-collateral-scope-f04" name="ds-collateral-scope-f04"></a><a id="2216-f04---rejects-independently-invalid-collateral-inputs-or-returns-without-redeemers" name="2216-f04---rejects-independently-invalid-collateral-inputs-or-returns-without-redeemers"></a>No redeemers does not waive independent input, return or count checks. | Unknown-input coverage exists above. Add an implicit return one lovelace below minimum and too many collateral inputs, each with a valid control. |
| <a id="ds-collateral-authorization-f01" name="ds-collateral-authorization-f01"></a><a id="2221-f01---rejects-a-script-controlled-collateral-input-when-collateral-validation-applies" name="2221-f01---rejects-a-script-controlled-collateral-input-when-collateral-validation-applies"></a>Active collateral validation $\implies$ inputs are key-locked. | Reject script-controlled collateral with `ScriptsNotPaidUTxO` for both output forms and script outcomes, even with a valid script witness. Use that script for an ordinary purpose too, so its witness is not extraneous. The control uses a signed key-controlled input. |
| <a id="ds-collateral-authorization-f02" name="ds-collateral-authorization-f02"></a><a id="2222-f02---rejects-a-key-controlled-collateral-input-whose-required-payment-key-witness-is-missing" name="2222-f02---rejects-a-key-controlled-collateral-input-whose-required-payment-key-witness-is-missing"></a>Every collateral payment key must witness the transaction. | Extend the existing witness case to Store-backed inputs, both script outcomes and the no-redeemer path. Remove only a collateral key witness that no ordinary input needs; restoring it must accept. |

<a id="ds-collateral-scope-n01" name="ds-collateral-scope-n01"></a><a id="2214-n01---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore" name="2214-n01---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore"></a><a id="ds-collateral-funding-n09" name="ds-collateral-funding-n09"></a><a id="22116-n09---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore" name="22116-n09---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore"></a><a id="ds-collateral-store-activity-control" name="ds-collateral-store-activity-control"></a>

The successful path of [Minimum coin N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L75)
already accepts an address-only Store-backed output with its allocation declared.
It is the existing control for Store activity without redeemers. **Remaining
extension:** explicitly assert empty redeemers and empty collateral inputs in that
prepared transaction; acceptance alone does not prove both fields are absent.
Store-backed fixture extensions should reuse the shared rule cases. The existing Babbage
[return fixup](../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/ImpTest.hs#L92)
currently rejects `NewTxOut`, so inherited implicit fixtures do not supply
that extension automatically.

<a id="ds-collateral-funding" name="ds-collateral-funding"></a>
<a id="223-funding" name="223-funding"></a>
<a id="ds-collateral-settlement" name="ds-collateral-settlement"></a>
<a id="226-settlement" name="226-settlement"></a>

#### 2.2.1 Funding

> **Input coins fund the return, any deposit shortfall and the minimum fee.**
>
> Released deposits cover the return’s deposit first. Their surplus cannot pay the minimum fee or enlarge the return.

The [shared redeemer trigger](#ds-collateral-existing-rules) activates these checks,
including when scripts succeed. Acceptance and rejection cases keep unrelated
collateral and ordinary rules valid. P02 isolates the collateral calculation.

| Quantity | Meaning |
| --- | --- |
| $\mathit{inputCoins}$ | Full ADA of implicit collateral inputs plus application ADA of Store-backed inputs. |
| $\mathit{returnCoins}$ | ADA in the specified collateral return; zero when absent. |
| $\mathit{releasedDeposits}$ | Recorded deposits belonging to Store-backed collateral inputs; implicit inputs contribute zero. |
| $\mathit{returnDeposit}$ | Deposit priced from the submitted Store-backed return; zero for an absent or implicit return. |

$$
\begin{aligned}
\mathit{additionalDeposit}&=\max(0,\mathit{returnDeposit}-\mathit{releasedDeposits})\\
\mathit{coinFee}&=\mathit{inputCoins}-\mathit{returnCoins}-\mathit{additionalDeposit}\\
\mathit{minimumFee}&=\left\lceil\frac{\mathit{txFee}\cdot\mathit{collateralPercentage}}{100}\right\rceil
\end{aligned}
$$

$$
\mathit{coinFee}\ge\mathit{minimumFee}
\quad\Longleftrightarrow\quad\text{Funding accepted}
$$

The ledger derives these amounts from collateral inputs and return; no collateral
Store declaration is supplied. The same terms determine
$\mathit{storeChange}=\mathit{returnDeposit}-\mathit{releasedDeposits}$.
[Ledger effects](#ds-state) checks application of that change.

**Example — 1 ADA minimum fee**

| Input coins | Return coins | Released deposit | Return deposit | Additional deposit | Coin fee | Funding |
| ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 5 | 3 | 1 | 2 | 1 | 1 | Accept |
| 5 | 4 | 1 | 2 | 1 | 0 | Reject |
| 5 | 5 | 2 | 1 | 0 | 0 | Reject, despite 1 ADA released surplus |

The last row conserves ADA once surplus reaches fees, but still fails the
independently funded minimum. [Fees](#ds-state-fees) owns that surplus destination.

**Generated cases**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="2232-n01---accepts-a-batch-whose-scripts-succeed-when-its-required-collateral-is-fully-funded-and-all-other-rules-hold" name="2232-n01---accepts-a-batch-whose-scripts-succeed-when-its-required-collateral-is-fully-funded-and-all-other-rules-hold"></a><a id="ds-collateral-funding-n01" name="ds-collateral-funding-n01"></a><a id="2212-n01---accepts-a-fully-funded-store-backed-return-when-all-scripts-succeed" name="2212-n01---accepts-a-fully-funded-store-backed-return-when-all-scripts-succeed"></a><a id="2233-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns" name="2233-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns"></a><a id="ds-collateral-funding-n02" name="ds-collateral-funding-n02"></a><a id="2213-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns" name="2213-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns"></a><a id="2234-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount" name="2234-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount"></a><a id="ds-collateral-funding-n03" name="ds-collateral-funding-n03"></a><a id="2214-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount" name="2214-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount"></a><a id="2235-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins" name="2235-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins"></a><a id="ds-collateral-funding-n04" name="ds-collateral-funding-n04"></a><a id="2215-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins" name="2215-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins"></a><a id="2237-p01---collateral-coins-cover-the-minimum" name="2237-p01---collateral-coins-cover-the-minimum"></a><a id="ds-collateral-funding-p01" name="ds-collateral-funding-p01"></a><a id="2217-p01---collateral-coins-cover-the-minimum" name="2217-p01---collateral-coins-cover-the-minimum"></a><a id="22311-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs" name="22311-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs"></a><a id="ds-collateral-funding-n05" name="ds-collateral-funding-n05"></a><a id="22111-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs" name="22111-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs"></a><a id="22312-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs" name="22312-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs"></a><a id="ds-collateral-funding-n06" name="ds-collateral-funding-n06"></a><a id="22112-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs" name="22112-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs"></a><a id="22313-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded" name="22313-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded"></a><a id="ds-collateral-funding-n07" name="ds-collateral-funding-n07"></a><a id="22113-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded" name="22113-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded"></a><a id="22315-n08---accepts-collateral-funding-exactly-at-a-rounded-up-minimum-fee" name="22315-n08---accepts-collateral-funding-exactly-at-a-rounded-up-minimum-fee"></a><a id="ds-collateral-funding-n08" name="ds-collateral-funding-n08"></a><a id="22115-n08---accepts-the-exact-rounded-up-minimum-fee-after-funding-the-returns-additional-deposit" name="22115-n08---accepts-the-exact-rounded-up-minimum-fee-after-funding-the-returns-additional-deposit"></a><a id="ds-collateral-settlement-n01" name="ds-collateral-settlement-n01"></a><a id="2261-n01---derives-store-changes-from-collateral-inputs-and-return-without-a-separate-declaration" name="2261-n01---derives-store-changes-from-collateral-inputs-and-return-without-a-separate-declaration"></a><a id="ds-collateral-funding-n10" name="ds-collateral-funding-n10"></a><a id="22117-n10---derives-deposit-funding-from-collateral-inputs-and-return-without-a-separate-declaration" name="22117-n10---derives-deposit-funding-from-collateral-inputs-and-return-without-a-separate-declaration"></a><a id="ds-collateral-settlement-n02" name="ds-collateral-settlement-n02"></a><a id="2263-n02---derives-the-released-store-amount-from-multiple-ada-only-collateral-inputs-with-no-return" name="2263-n02---derives-the-released-store-amount-from-multiple-ada-only-collateral-inputs-with-no-return"></a><a id="ds-collateral-funding-n11" name="ds-collateral-funding-n11"></a><a id="22119-n11---derives-released-deposits-from-mixed-ada-only-collateral-inputs-with-no-return" name="22119-n11---derives-released-deposits-from-mixed-ada-only-collateral-inputs-with-no-return"></a>**1.&nbsp;[N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L46)** | **Funded collateral.** Cover the return, any positive deposit shortfall and the rounded-up minimum; include exact equality. | Accept with successful scripts or an accepted phase-2 failure. |
| <a id="2231-f01---rejects-insufficient-collateral-funding-when-redeemers-trigger-validation-even-if-all-scripts-succeed" name="2231-f01---rejects-insufficient-collateral-funding-when-redeemers-trigger-validation-even-if-all-scripts-succeed"></a><a id="ds-collateral-funding-f01" name="ds-collateral-funding-f01"></a><a id="2211-f01---rejects-an-underfunded-store-backed-return-even-when-all-scripts-succeed" name="2211-f01---rejects-an-underfunded-store-backed-return-even-when-all-scripts-succeed"></a><a id="2236-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits" name="2236-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits"></a><a id="ds-collateral-funding-f02" name="ds-collateral-funding-f02"></a><a id="2216-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits" name="2216-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits"></a><a id="2238-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus" name="2238-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="ds-collateral-funding-f03" name="ds-collateral-funding-f03"></a><a id="2218-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus" name="2218-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="2239-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus" name="2239-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="ds-collateral-funding-f04" name="ds-collateral-funding-f04"></a><a id="2219-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus" name="2219-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="22310-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee" name="22310-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee"></a><a id="ds-collateral-funding-f05" name="ds-collateral-funding-f05"></a><a id="22110-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee" name="22110-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee"></a><a id="22314-f06---rejects-underfunded-collateral-when-the-optional-total-is-absent" name="22314-f06---rejects-underfunded-collateral-when-the-optional-total-is-absent"></a><a id="ds-collateral-funding-f06" name="ds-collateral-funding-f06"></a><a id="22114-f06---rejects-an-underfunded-store-backed-return-when-the-optional-total-is-absent" name="22114-f06---rejects-an-underfunded-store-backed-return-when-the-optional-total-is-absent"></a>**2.&nbsp;[F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L68)** | **Underfunded collateral.** Set the coin fee below the minimum, including one lovelace below the ceiling, an absent total, an oversized return and no-return Store inputs carrying zero application ADA. | Reject only with `InsufficientCollateral`; funded controls accept. |
| <a id="ds-collateral-settlement-p01" name="ds-collateral-settlement-p01"></a><a id="2262-p01---derived-collateral-store-change-is-independent-of-ordinary-store-declarations" name="2262-p01---derived-collateral-store-change-is-independent-of-ordinary-store-declarations"></a><a id="ds-collateral-funding-p02" name="ds-collateral-funding-p02"></a><a id="22118-p02---ordinary-declarations-do-not-change-collateral-deposit-funding" name="22118-p02---ordinary-declarations-do-not-change-collateral-deposit-funding"></a>**3.&nbsp;[P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L118)** | **Independent ordinary declarations.** Keep collateral inputs, return, fee and prices fixed; vary ordinary declaration forms in the isolated calculation. | The released deposits, return deposit and additional funding stay unchanged. |

P02 observes only the collateral calculation; its arbitrary ordinary declarations
are not submitted as ledger transactions.

The generated coverage distinguishes:

| Axis | Conditions exercised |
| --- | --- |
| Output representation | Implicit and Store-backed inputs and returns, mixed input sets, absent return. Count implicit ADA once and release only recorded Store deposits. |
| Deposit relationship | Return deposit greater than, equal to or less than released deposits; no extra funding for equality, no Store deposit for an implicit return. |
| Recorded amount | Fund a Store-backed source at twice the current byte price, then lower the parameter before constructing the collateral proposal. Release the recorded amount; price the return at the current parameter. |
| Fee boundary | Exact rounded-up minimum, a funded margin and one lovelace below; a fractional-lovelace product distinguishes ceiling from floor. |
| Released excess | Cannot fund the minimum or a larger signed return; deposits of unspent outputs remain unavailable. |
| Zero application ADA | A Store-backed return may contain zero ADA when its external deposit and fee are funded. |
| Absent fields | An absent total does not waive funding. With no return, accept funded ADA-only mixed inputs; reject all-Store inputs with zero application ADA even when their recorded deposits exceed the minimum fee. Test both an absent total and an exact zero total. |
| Script outcome | Successful scripts and genuine phase-2 failure use the same funding requirement. |

The inherited implicit-only tests provide the baseline. Each generated scenario
includes Store activity so that the external-deposit adjustment is exercised.
The changed-price fixture checks recorded-amount release only; it does not define
a governance, epoch-processing or historical-repricing policy.

<a id="ds-collateral-total" name="ds-collateral-total"></a>
<a id="225-total" name="225-total"></a>

#### 2.2.2 Total

> **The optional total describes coins taken from collateral.**
>
> It includes coins funding an additional deposit and excludes deposits released from the Store.

The inherited [incorrect-total test](../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp/UtxosSpec.hs#L155)
owns the generic comparison. These generated cases exercise it with Store
allocations or releases, keeping funding and other rules valid:

$$
\mathit{expectedTotal}=\mathit{inputCoins}-\mathit{returnCoins}
$$

$$
\begin{aligned}
&\mathit{declaredTotal}\in\{\mathsf{Absent},\mathsf{Present}(\mathit{expectedTotal})\}\\
&\Longleftrightarrow\text{Total accepted}
\end{aligned}
$$

For 5 ADA of input coins and a 2 ADA return, the total is 3 ADA. Funding a 1 ADA
additional deposit leaves 2 ADA for the coin fee. Released-deposit surplus can
increase the eventual fee credit without changing this declared total.

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="2251-n01---accepts-a-declared-total-equal-to-collateral-input-coins-minus-return-coins" name="2251-n01---accepts-a-declared-total-equal-to-collateral-input-coins-minus-return-coins"></a><a id="ds-collateral-total-n01" name="ds-collateral-total-n01"></a><a id="2221-n01---accepts-input-coins-minus-return-coins-as-the-total-with-store-allocations-or-releases" name="2221-n01---accepts-input-coins-minus-return-coins-as-the-total-with-store-allocations-or-releases"></a><a id="2254-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total" name="2254-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total"></a><a id="ds-collateral-total-n02" name="ds-collateral-total-n02"></a><a id="2224-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total" name="2224-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total"></a><a id="2255-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total" name="2255-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total"></a><a id="ds-collateral-total-n03" name="ds-collateral-total-n03"></a><a id="2225-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total" name="2225-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total"></a><a id="2256-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold" name="2256-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold"></a><a id="ds-collateral-total-n04" name="ds-collateral-total-n04"></a><a id="2226-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold" name="2226-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold"></a>**1.&nbsp;[N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L31)** | **Absent or exact total.** Omit the field or supply input coins minus return coins, with additional deposit funding, released surplus or no return. | Accept for either script outcome; absence skips only the comparison. |
| <a id="2252-f01---rejects-a-declared-total-differing-by-one-lovelace-when-collateral-validation-applies" name="2252-f01---rejects-a-declared-total-differing-by-one-lovelace-when-collateral-validation-applies"></a><a id="ds-collateral-total-f01" name="ds-collateral-total-f01"></a><a id="2222-f01---rejects-a-total-differing-by-one-lovelace-with-store-allocations-or-releases" name="2222-f01---rejects-a-total-differing-by-one-lovelace-with-store-allocations-or-releases"></a><a id="2253-f02---rejects-an-incorrect-supplied-total-when-redeemers-trigger-collateral-validation-even-if-all-scripts-succeed" name="2253-f02---rejects-an-incorrect-supplied-total-when-redeemers-trigger-collateral-validation-even-if-all-scripts-succeed"></a><a id="ds-collateral-total-f02" name="ds-collateral-total-f02"></a><a id="2223-f02---rejects-an-incorrect-total-with-store-allocations-or-releases-even-when-all-scripts-succeed" name="2223-f02---rejects-an-incorrect-total-with-store-allocations-or-releases-even-when-all-scripts-succeed"></a>**2.&nbsp;[F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L43)** | **Incorrect total.** Supply a total one lovelace above or below the expected value while keeping Store funding correct. | Reject only with `IncorrectTotalCollateralField`, even when scripts succeed; the exact-total control accepts. |

Absence is distinct from a supplied zero: zero is valid only when it equals the expected total. [Funding F01](#ds-collateral-funding-f01) independently rejects a funding deficit when the field is absent.

<a id="ds-collateral-assets" name="ds-collateral-assets"></a>

#### 2.2.3 Assets

> **Return every collateral native asset with its exact quantity.**
>
> The Store holds ADA; deposit funding cannot compensate for a missing application token.

When the [redeemer trigger](#ds-collateral-existing-rules) is active:

$$
\mathit{nativeAssets}(\mathit{collateralInputs})
=\mathit{nativeAssets}(\mathit{collateralReturn})
\quad\Longleftrightarrow\quad\text{Assets accepted}
$$

An absent return contributes the empty asset map. These cases exercise
[`validateCollateralAssets`](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/DepositStore/Collateral.hs)
with a Store-backed input or return, including mixed inputs and both return forms.
Funding, output validity, witnesses and optional totals remain correct. Exercise
successful scripts and genuine phase-2 failure. The current generator mints one
policy and one token name, with a variable quantity repeated across the selected
inputs. Mixed-policy or distinct-token input maps remain an extension.

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-collateral-conservation-n02" name="ds-collateral-conservation-n02"></a><a id="2274-n02---accepts-native-asset-collateral-when-its-return-preserves-every-asset-and-quantity" name="2274-n02---accepts-native-asset-collateral-when-its-return-preserves-every-asset-and-quantity"></a><a id="ds-collateral-assets-n01" name="ds-collateral-assets-n01"></a><a id="2232-n01---accepts-matching-native-assets-when-collateral-inputs-or-return-are-store-backed" name="2232-n01---accepts-matching-native-assets-when-collateral-inputs-or-return-are-store-backed"></a>**1.&nbsp;[N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AssetsSpec.hs#L35)** | **Exact asset map.** Return every input policy, asset name and quantity; include a funded Store-backed return with zero application ADA. | Accept for both output forms and script outcomes. |
| <a id="ds-collateral-conservation-f01" name="ds-collateral-conservation-f01"></a><a id="2273-f01---rejects-missing-added-or-changed-native-assets-in-the-collateral-return" name="2273-f01---rejects-missing-added-or-changed-native-assets-in-the-collateral-return"></a><a id="ds-collateral-assets-f01" name="ds-collateral-assets-f01"></a><a id="2231-f01---rejects-missing-added-or-changed-native-assets-when-collateral-inputs-or-return-are-store-backed" name="2231-f01---rejects-missing-added-or-changed-native-assets-when-collateral-inputs-or-return-are-store-backed"></a><a id="ds-collateral-conservation-f02" name="ds-collateral-conservation-f02"></a><a id="2275-f02---rejects-token-bearing-collateral-when-no-return-is-specified" name="2275-f02---rejects-token-bearing-collateral-when-no-return-is-specified"></a><a id="ds-collateral-assets-f02" name="ds-collateral-assets-f02"></a><a id="2233-f02---rejects-token-bearing-store-backed-collateral-when-no-return-is-specified" name="2233-f02---rejects-token-bearing-store-backed-collateral-when-no-return-is-specified"></a>**2.&nbsp;[F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AssetsSpec.hs#L48)** | **Missing or altered assets.** Remove an asset, add an absent asset, alter a quantity, or omit the return for token-bearing collateral. | Reject only with `CollateralContainsNonADA`; the unchanged asset-map control accepts. |

[Funding N01](#ds-collateral-funding-n01) supplies the ADA-only no-return acceptance
control. Ordinary outputs and unapplied minting cannot supply missing collateral assets.

<a id="section-1-3" name="section-1-3"></a><a id="ds-state" name="ds-state"></a>

<a id="ds-state-execution-p01" name="ds-state-execution-p01"></a><a id="ds-state-execution-n01" name="ds-state-execution-n01"></a><a id="ds-state-execution-n04" name="ds-state-execution-n04"></a><a id="ds-state-execution-n02" name="ds-state-execution-n02"></a><a id="ds-state-execution-n03" name="ds-state-execution-n03"></a>

## 3. Ledger effects

> **Observe the state produced by an accepted transaction.**
>
> Transaction rules decide validity. Ledger effects checks the resulting UTxO,
> Store records and monetary pots; Lifecycle checks translation and epoch boundaries.

| Responsibility | Observation |
| --- | --- |
| [UTxO](#ds-state-utxo) | Exact consumed and created output references. |
| [Store / Allocations](#ds-state-allocations) | Exact allocation map for live Store-backed outputs. |
| [Store / Balance](#ds-state-balance) | Change in the sum of recorded deposits. |
| [Fees](#ds-state-fees) | Fee credit and unchanged treasury. |
| [Conservation](#ds-state-conservation) | Correct ADA total and its preservation. |
| [Lifecycle](#ds-state-lifecycle) | Era translation and ordinary epoch boundaries. |

The accepted outcome selects the inputs and outputs used by all these observations:

| Outcome | $\mathit{consumedInputs}$ | $\mathit{createdOutputs}$ |
| --- | --- | --- |
| Ordinary success | Ordinary inputs of TopTx and every SubTx. | Their signed ordinary outputs, each under its own body's identifier and output index. |
| Accepted phase-2 failure | Collateral inputs. | The signed collateral return, when present. |

Settlement ADA is already included in the signed output. Reference-only and
unrelated inputs remain unchanged; an input used in both consuming roles is
consumed once through the selected path. Tests assert acceptance before checking
these effects. Executed counts and timings belong to the [verification record](dijkstra-deposit-store-verification.md).

<a id="ds-state-execution" name="ds-state-execution"></a><a id="ds-state-utxo" name="ds-state-utxo"></a>

### 3.1 UTxO

> **Apply exactly the selected inputs and signed outputs.**

$$
\mathit{utxoAfter}
=(\mathit{utxoBefore}\setminus\mathit{consumedInputs})
\cup\mathit{createdOutputs}
$$

Here, subtraction removes map entries by input reference; union inserts the
selected outputs without changing their payloads.

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-utxo-n01" name="ds-state-utxo-n01"></a>**1.&nbsp;[N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L34)** | **Ordinary execution.** Standalone and multi-SubTx transactions allocate, release or replace deposits. Compare the entire resulting UTxO with the ordinary-input/output equation. |
| <a id="ds-state-utxo-n02" name="ds-state-utxo-n02"></a>**2.&nbsp;[N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L48)** | **Successful scripts leave collateral inactive.** Generate collateral proposals with absent, implicit or Store-backed returns. Only ordinary outputs are created; collateral-only and reference-only inputs survive. |
| <a id="ds-state-utxo-n03" name="ds-state-utxo-n03"></a>**3.&nbsp;[N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L62)** | **Failed scripts select collateral.** Submit a genuine phase-2 failure. Only collateral inputs disappear and only the collateral return is created; ordinary and reference-only inputs survive. |
| <a id="ds-state-utxo-n04" name="ds-state-utxo-n04"></a>**4.&nbsp;[N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L77)** | **Failed TopTx, inactive SubTxs.** A real failing TopTx script selects collateral even when several children propose allocations and releases. Compare the complete UTxO: none of those ordinary effects is applied. |
| <a id="ds-state-utxo-n05" name="ds-state-utxo-n05"></a>**5.&nbsp;[N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L95)** | **One input, two consuming roles.** A Store-backed input belongs to both ordinary and collateral sets. Exercise both actual script outcomes and compare the complete UTxO against the selected path; consume the shared input once. |

<a id="ds-state-execution-f01" name="ds-state-execution-f01"></a>

<a id="ds-state-execution-p02" name="ds-state-execution-p02"></a>

**Rejected submissions.** A rejected transaction produces no new accepted state.
The submission adapter installs a state only on success, so comparing its snapshots
after rejection would mainly retest that adapter. Rejection assertions remain in
Transaction rules; this section measures applied effects. Likewise, these failing
scripts execute at TopTx: they do not claim to test propagation of a failing
SubTx script through the upstream batch evaluator.

<a id="ds-state-store" name="ds-state-store"></a>

### 3.2 Store

`UTxOStore` owns the `currentCalculation`, one indexed map of `Unspent (TxOut era)`
and a checked cached `totalDepositAmount`. Each allocation owns its output, size
and historical calculation.
Accepted outputs retain their supplied metadata; legacy imports use the provisional
compatibility metadata described in [DepositStore](#section-1-1). Output references and allocations
therefore share one map; the cached total represents the Store ADA, counted once.

<a id="ds-state-allocations" name="ds-state-allocations"></a><a id="ds-state-store-allocations" name="ds-state-store-allocations"></a>

<a id="ds-state-allocations-n04" name="ds-state-allocations-n04"></a><a id="ds-state-allocations-n05" name="ds-state-allocations-n05"></a><a id="ds-state-allocations-n02" name="ds-state-allocations-n02"></a><a id="ds-state-allocations-n03" name="ds-state-allocations-n03"></a><a id="ds-state-allocations-n06" name="ds-state-allocations-n06"></a><a id="ds-state-allocations-n07" name="ds-state-allocations-n07"></a><a id="ds-state-allocations-n08" name="ds-state-allocations-n08"></a>

#### 3.2.1 Allocations

> **Retain one allocation for each live Store-backed output.**

Here, $\mathit{recordsBefore}$ is mathematical notation for the deposits calculated from retained creation-time metadata, not a separate ledger type or stored map. The owning allocation map also contains legacy outputs, whose external deposit is zero.
Construct $\mathit{newAllocations}$ only for Store-backed outputs in
$\mathit{createdOutputs}$, priced from their accepted serialized sizes under
[Deposit calculation](#ds-pricing). Implicit outputs have no external-deposit record in this view; their legacy allocations remain in the owning map. A Store-backed output priced at zero still has a deposit record. For either accepted outcome:

$$
\begin{aligned}
\mathit{recordsAfter}
&=(\mathit{recordsBefore}\setminus\mathit{consumedInputs})
  \cup\mathit{newAllocations} \\
\mathit{keys}(\mathit{recordsAfter})
&=\{\,\mathit{outputRef}\mid\mathit{utxoAfter}[\mathit{outputRef}]\text{ is Store-backed}\,\} \\
\mathit{recordsAfter}[\mathit{outputRef}]&\geq0
\quad\text{for every recorded }\mathit{outputRef}
\end{aligned}
$$

Compare the actual map with this independently constructed map, and its domain
with the actual resulting UTxO. Equality between two sums of the same unchecked
map would miss missing, misplaced or incorrectly priced records. A consistent
starting state has this exact domain and nonnegative recorded amounts.
[Balance](#ds-state-balance) checks the resulting ADA change against independently
calculated allocations and retained releases.

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-allocations-p01" name="ds-state-allocations-p01"></a>**1.&nbsp;[P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L72)** | **Ordinary records.** Derive records from signed Store-backed outputs, remove consumed references, then compare the complete map and its domain with the resulting UTxO. Cover local and delegated multi-SubTx activity and equal-valued outputs at distinct references. |
| <a id="ds-state-allocations-p02" name="ds-state-allocations-p02"></a>**2.&nbsp;[P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L93)** | **Collateral records.** Generate mixed input forms and absent, implicit or Store-backed returns. Real script success removes only ordinary records, including shared ordinary/collateral inputs. Real failure removes only collateral records and adds the Store-backed return; reference-only records survive. |
| <a id="ds-state-allocations-p03" name="ds-state-allocations-p03"></a>**3.&nbsp;[P03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L118)** | **Retained accepted size.** Submit a noncanonical CBOR output whose accepted encoding is one byte longer than its canonical encoding. Restore the serialized UTxO state, double the byte price and reference the output: its creation record is unchanged. Spending it removes precisely that record. |
| <a id="ds-state-allocations-n01" name="ds-state-allocations-n01"></a>**4.&nbsp;[N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L162)** | **Zero-priced allocations still have records.** Spend translated implicit sources and create Store-backed outputs in TopTx and SubTx at a zero byte price. Record each new reference with amount zero; implicit sources never acquire allocation records. |
| <a id="ds-state-allocations-p04" name="ds-state-allocations-p04"></a>**5.&nbsp;[P04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L186)** | **No ordinary records on failure.** A real failing TopTx script has several children proposing Store allocations and releases. With implicit-only collateral, the entire allocation map remains unchanged. |

Historical release **amounts** are checked separately by [Balance P03](#ds-state-balance-p03).

<a id="ds-state-balance" name="ds-state-balance"></a><a id="ds-state-store-balance" name="ds-state-store-balance"></a>

#### 3.2.2 Balance

> **The Store balance changes by newly allocated deposits minus recorded releases.**

Derive the transfer from new allocations and retained consumed records:

$$
\begin{aligned}
\mathit{releasedDeposits}
&=\sum_{\mathit{input}\in\mathit{consumedInputs}\cap\mathit{keys}(\mathit{recordsBefore})}
  \mathit{recordsBefore}[\mathit{input}] \\
\mathit{storeBalanceAfter}
&=\mathit{storeBalanceBefore}+\sum\mathit{newAllocations}
  -\mathit{releasedDeposits}
\end{aligned}
$$

On ordinary success, the balance change equals the validated TopTx total; every SubTx is already
included, whether funded locally or through TopTx. Accepted phase-2 failure uses
only collateral allocations and releases. Exact declarations describe this
validated transfer; applying them again would duplicate its movement of ADA.

<a id="ds-state-balance-n02" name="ds-state-balance-n02"></a>
For every Store, its cached balance must equal the sum calculated from its historical records:

$$
\mathit{storeBalance}=\sum\mathit{records}
$$

The transfer assertion compares the observed amount with independently calculated
allocations and releases. Separate assertions recompute the total from each stored
accepted size and creation price, without trusting the cached total or calling the
production pricing function. Old records retain their creation amounts; new allocations
use the applicable price. This introduces no new pricing mechanism. Historical
repricing policy remains a separate [design question](#ds-pricing-history).

<a id="ds-state-balance-n01" name="ds-state-balance-n01"></a><a id="ds-state-balance-n03" name="ds-state-balance-n03"></a>

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-balance-p01" name="ds-state-balance-p01"></a>**1.&nbsp;[P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L48)** | **Ordinary transfer.** Measure new deposits from signed outputs and releases from the consumed records. The sum of the resulting records changes by their difference, including multi-SubTx local/delegated funding and zero net replacement. |
| <a id="ds-state-balance-p02" name="ds-state-balance-p02"></a>**2.&nbsp;[P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L69)** | **Collateral transfer.** Successful scripts release only ordinary records, including inputs shared with collateral. Failed scripts apply only the return deposit minus recorded collateral releases; deposits of all unspent outputs remain recorded. |
| <a id="ds-state-balance-p03" name="ds-state-balance-p03"></a>**3.&nbsp;[P03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L90)** | **Historical release after restoration.** Create an allocation from genuinely noncanonical accepted bytes, restore the state and change the price. Spending the output reduces the Store by the original allocation, not a newly calculated deposit. |
| <a id="ds-state-balance-p04" name="ds-state-balance-p04"></a>**4.&nbsp;[P04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L114)** | **No ordinary transfer on failure.** The same failing-parent, multi-SubTx scenarios use implicit-only collateral. The Store balance remains unchanged despite their ordinary declarations. |
| <a id="ds-state-balance-p05" name="ds-state-balance-p05"></a>**5.&nbsp;[P05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L128)** | **Mixed historical prices.** Accept two noncanonical outputs at different prices, restore their state and consume both while creating a replacement at a third price. The balance changes by the current new deposit minus both historical deposits. Retained metadata and cache totals are checked independently. |
| <a id="ds-state-balance-p06" name="ds-state-balance-p06"></a>**6.&nbsp;[P06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L164)** | **Child output history.** Accept a noncanonical SubTx output, restore its allocation and change the price. A later spend of the child's own reference releases exactly its original contribution. |
| <a id="ds-state-balance-p07" name="ds-state-balance-p07"></a>**7.&nbsp;[P07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L187)** | **Collateral-return history.** Accept a real script failure with a noncanonical Store-backed return. Restore that applied allocation, change the price and spend the return; its original accepted size and creation price determine the refund. |

<a id="ds-state-solvency" name="ds-state-solvency"></a><a id="34-solvency" name="34-solvency"></a><a id="ds-state-solvency-p01" name="ds-state-solvency-p01"></a><a id="341-p01---keep-every-accepted-state-solvent" name="341-p01---keep-every-accepted-state-solvent"></a><a id="ds-state-solvency-n02" name="ds-state-solvency-n02"></a><a id="344-n02---observes-store-backing-in-the-completed-batch-result-with-local-and-delegated-contributions" name="344-n02---observes-store-backing-in-the-completed-batch-result-with-local-and-delegated-contributions"></a>
**Exact cache invariant.** The former solvency comparison is replaced by equality:
`mkUTxOStore` establishes the cached total, `allocate` and `release` preserve it for a valid store, and decoding rejects a total that differs from the historical record sum. Raw allocation construction is separate from these checks. Direct record updates must preserve the same equality.
The nonnegative-record and live-output correspondence requirements remain in
[Allocations](#ds-state-allocations).

<a id="ds-state-solvency-n01" name="ds-state-solvency-n01"></a><a id="342-n01---classifies-proposed-states-at-exact-backing-and-one-lovelace-above-as-solvent" name="342-n01---classifies-proposed-states-at-exact-backing-and-one-lovelace-above-as-solvent"></a><a id="ds-state-solvency-f01" name="ds-state-solvency-f01"></a><a id="343-f01---classifies-a-proposed-state-one-lovelace-below-its-independently-calculated-obligations-as-insolvent" name="343-f01---classifies-a-proposed-state-one-lovelace-below-its-independently-calculated-obligations-as-insolvent"></a>
The former below/exact/above-backing cases are retired. Their independently varied
balance is not a valid Store: cached-total mismatch is now covered by codec rejection, rather than permitting surplus or a separate insolvency state. These anchors remain for older links.

<a id="ds-collateral-surplus" name="ds-collateral-surplus"></a>
<a id="224-surplus" name="224-surplus"></a>
<a id="ds-state-fees" name="ds-state-fees"></a>
<a id="38-fees" name="38-fees"></a>

<a id="ds-collateral-surplus-n01" name="ds-collateral-surplus-n01"></a><a id="2241-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury" name="2241-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury"></a><a id="ds-state-fees-n01" name="ds-state-fees-n01"></a><a id="381-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury" name="381-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury"></a><a id="341-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury" name="341-n01---credits-excess-released-utxo-capacity-deposits-to-fees-rather-than-the-treasury"></a><a id="ds-collateral-surplus-p01" name="ds-collateral-surplus-p01"></a><a id="2242-p01---released-surplus-reaches-fees" name="2242-p01---released-surplus-reaches-fees"></a><a id="382-p01---released-surplus-reaches-fees" name="382-p01---released-surplus-reaches-fees"></a><a id="342-p01---released-surplus-reaches-fees" name="342-p01---released-surplus-reaches-fees"></a><a id="ds-collateral-surplus-p02" name="ds-collateral-surplus-p02"></a><a id="2243-p02---treasury-remains-unchanged" name="2243-p02---treasury-remains-unchanged"></a><a id="383-p02---treasury-remains-unchanged" name="383-p02---treasury-remains-unchanged"></a><a id="343-p02---treasury-remains-unchanged" name="343-p02---treasury-remains-unchanged"></a>

### 3.3 Fees

> **Credit the fee selected by the actual execution path.**

$$
\begin{aligned}
\mathit{additionalDeposit}&=\max(0,\mathit{returnDeposit}-\mathit{releasedDeposits})\\
\mathit{releasedSurplus}&=\max(0,\mathit{releasedDeposits}-\mathit{returnDeposit})\\
\mathit{collateralCoinFee}&=\mathit{inputCoins}-\mathit{returnCoins}-\mathit{additionalDeposit}
\end{aligned}
$$

| Accepted outcome | $\mathit{feesAfter}-\mathit{feesBefore}$ |
| --- | --- |
| Ordinary success | $\mathit{txFee}$ |
| Phase-2 failure | $\mathit{collateralCoinFee}+\mathit{releasedSurplus}$ |

Both paths preserve the treasury:
$\mathit{treasuryAfter}=\mathit{treasuryBefore}$.

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-fees-p01" name="ds-state-fees-p01"></a>**1.&nbsp;[P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs#L29)** | **Ordinary fee.** Local and delegated ordinary Store operations, plus real successful scripts with collateral proposals, credit only the declared transaction fee. |
| <a id="ds-state-fees-p02" name="ds-state-fees-p02"></a>**2.&nbsp;[P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs#L53)** | **Collateral fee.** Real failing scripts credit the application-coin fee plus unused recorded deposits. Cover absent returns, mixed inputs, deposit shortfall/equality/surplus and a changed byte price. |

The input/return funding constraints belong to [Funding](#ds-collateral-funding).
[Allocations](#ds-state-allocations) and [Balance](#ds-state-balance) observe the
corresponding Store effects; these fee tests observe only fees and treasury.

<a id="ds-state-conservation" name="ds-state-conservation"></a><a id="35-conservation" name="35-conservation"></a>

### 3.4 Conservation

> **Count every actual ADA pot, including the whole Store balance, exactly once.**

Start from a valid ledger state and submit an accepted transaction. Read each
actual pot independently from the observed state. Implicit outputs
contribute their full coin; Store-backed outputs contribute application coin.
The deposited pot is `utxosDeposited`, backing certificate/governance deposits.
Sum allocation records once as `storeBalance`; do not add their total a second time.

$$
\begin{aligned}
\mathit{actualAda}
&=\mathit{outputAda}+\mathit{storeBalance}+\mathit{fees}
  +\mathit{deposited}\\
&\quad+\mathit{rewards}+\mathit{treasury}+\mathit{reserves}
  +\mathit{donations}
\end{aligned}
$$

$$
\begin{aligned}
\mathit{actualAdaAfter}&=\mathit{actualAdaBefore} \\
\mathit{totalAdaES}(\mathit{state})+\mathit{donations}(\mathit{state})&=\mathit{actualAda}(\mathit{state})
\quad\text{for }\mathit{state}\in\{\mathit{before},\mathit{after}\}
\end{aligned}
$$

The second equation checks the [production total](../eras/shelley/impl/src/Cardano/Ledger/Shelley/AdaPots.hs#L99)
against the independent sum: `totalAdaES` includes Store balance but excludes the
donation pot. Its certificate/governance obligation projection agrees with the
deposited pot in a consistent valid state. Use positive recorded deposits so the
comparison detects either omission or double counting of Store ADA, and nonzero
donations so that pot cannot be silently omitted.

<a id="ds-collateral-conservation" name="ds-collateral-conservation"></a><a id="227-conservation" name="227-conservation"></a><a id="ds-collateral-conservation-n01" name="ds-collateral-conservation-n01"></a><a id="2271-n01---conserves-ada-for-mixed-collateral-inputs-when-return-storage-needs-an-additional-deposit" name="2271-n01---conserves-ada-for-mixed-collateral-inputs-when-return-storage-needs-an-additional-deposit"></a><a id="ds-collateral-conservation-p01" name="ds-collateral-conservation-p01"></a><a id="2272-p01---collateral-settlement-conserves-ada" name="2272-p01---collateral-settlement-conserves-ada"></a><a id="351-n01---still-counts-store-ada-in-total-monetary-conservation" name="351-n01---still-counts-store-ada-in-total-monetary-conservation"></a>

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-conservation-n01" name="ds-state-conservation-n01"></a>**1.&nbsp;[N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L38)** | **Count actual ADA once.** Use positive allocation records and nonzero donations. Before and after an accepted transaction, compare the production total plus donations with the independent sum of actual pots. |
| <a id="ds-state-conservation-n02" name="ds-state-conservation-n02"></a>**2.&nbsp;[N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L60)** | **Ordinary conservation.** Compare independent actual-ADA sums immediately before and after accepted standalone and multi-SubTx transactions, with local or delegated funding. |
| <a id="ds-state-conservation-n03" name="ds-state-conservation-n03"></a>**3.&nbsp;[N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L72)** | **Collateral conservation.** Repeat that comparison around real accepted phase-2 failures: mixed inputs, absent returns, and return deposits smaller than, equal to or greater than the recorded releases. |

For collateral, the same accounting projects to
$\mathit{collateralInputCoins}+\mathit{releasedDeposits}
=\mathit{returnCoins}+\mathit{returnDeposit}+\mathit{collateralFee}$.
Its funding prerequisites belong to [Funding](#ds-collateral-funding); this
contract observes the actual applied state.

<a id="ds-state-lifecycle" name="ds-state-lifecycle"></a>

### 3.5 Lifecycle

Translation establishes legacy allocations with zero external deposits. Ordinary epoch processing preserves an
existing allocation map and therefore its derived balance. Effective parameter changes
update only the calculation for future allocations.

<a id="ds-state-initialization" name="ds-state-initialization"></a><a id="36-initialization" name="36-initialization"></a><a id="ds-state-translation" name="ds-state-translation"></a>

#### 3.5.1 Translation

> **Preserve Conway outputs and existing pots while introducing legacy allocations with zero external deposits.**

$$
\begin{aligned}
\mathit{outputReferencesAfter}&=\mathit{outputReferencesBefore} \\
\mathit{outputPayloadsAfter}&=\mathit{outputPayloadsBefore} \\
\mathit{recordsAfter}&=\varnothing \\
\mathit{existingMonetaryPotsAfter}&=\mathit{existingMonetaryPotsBefore}
\end{aligned}
$$

Every translated output is implicit and has a legacy allocation in the owning map.
Here `recordsAfter` denotes the empty external-deposit view; the cached total is zero.
The Store's `currentCalculation` starts at V1 with the translated effective byte price.
The current import path supplies provisional metadata using `mkSized` at the era's
lowest protocol version and a zero-rate V1 calculation. It does not recover the
output's original accepted size or historical policy; migration design is deferred.
Preserve each output’s semantic address, value, datum
and reference script under era translation; do not extract its implicit minimum
coin. Translate a complete Conway `NewEpochState`, then compare these fields with
their Conway values: output references and payloads; treasury, reserves, fees,
deposited ADA and donations; each account's rewards and deposit. This checks the
Store introduction and its preservation boundary, rather than equality of every
field across two different era types.

| Case | Contract | Scenario axes |
| --- | --- | --- |
| <a id="ds-state-translation-n01" name="ds-state-translation-n01"></a><a id="ds-state-initialization-n01" name="ds-state-initialization-n01"></a><a id="361-n01---preserves-existing-output-references-addresses-values-datums-and-reference-scripts-and-keeps-those-outputs-implicit" name="361-n01---preserves-existing-output-references-addresses-values-datums-and-reference-scripts-and-keeps-those-outputs-implicit"></a><a id="ds-state-initialization-n02" name="ds-state-initialization-n02"></a><a id="362-n02---initializes-store-balance-and-utxo-capacity-deposit-obligations-to-zero" name="362-n02---initializes-store-balance-and-utxo-capacity-deposit-obligations-to-zero"></a><a id="ds-state-initialization-n03" name="ds-state-initialization-n03"></a><a id="363-n03---does-not-transfer-funds-from-another-ledger-pot-during-initialization" name="363-n03---does-not-transfer-funds-from-another-ledger-pot-during-initialization"></a>**1.&nbsp;[N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/TranslationSpec.hs#L39)** | **Introduce legacy allocations.** Apply the real era translation; compare the listed fields independently with their source values, require one legacy allocation per output and assert a zero cached total and empty external-deposit view. | Each generated pair has zero and distinct positive pots. Ten outputs cover absent/hash/inline datums × absent/native/Plutus reference scripts, plus identical payloads at distinct indices. Compare full asset values, datum semantics and script identity. |

<a id="ds-state-epoch" name="ds-state-epoch"></a>

#### 3.5.2 Epoch

> **Preserve historical deposits; activate effective parameters for future allocations.**

$$
\mathit{recordsAfter}=\mathit{recordsBefore}
\implies \mathit{storeBalanceAfter}=\mathit{storeBalanceBefore}
$$

| Case | Contract | Scenario axes |
| --- | --- | --- |
| <a id="ds-state-epoch-n01" name="ds-state-epoch-n01"></a><a id="ds-state-solvency-n03" name="ds-state-solvency-n03"></a><a id="345-n03---preserve-solvency-across-epochs" name="345-n03---preserve-solvency-across-epochs"></a>**1.&nbsp;[N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs#L27)** | **Retain the populated Store.** Cross actual epoch boundaries and compare the complete allocation map. | Fund one to five live allocations through an accepted transaction and cross two successive boundaries. Verify each epoch advanced and protocol parameters stayed unchanged; the cached balance and all historical metadata are preserved. |
| <a id="ds-state-epoch-n02" name="ds-state-epoch-n02"></a>**2.&nbsp;[N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs#L48)** | **Activate the effective price.** A scheduled parameter update changes the current rate without repricing live entries. | Cross real epoch boundaries with V1 and V2 selected. Compare the effective parameters, current calculation, complete allocation map and cached total. |

For N02, $V$ is the selected formula version and $r'$ the newly effective byte price:

$$
\begin{aligned}
\text{currentCalculationAfter} &= V(r') \\
\text{allocationsAfter} &= \text{allocationsBefore} \\
\text{totalDepositAmountAfter} &= \text{totalDepositAmountBefore}
\end{aligned}
$$

<a id="ds-state-recovery" name="ds-state-recovery"></a><a id="37-recovery" name="37-recovery"></a><a id="ds-state-recovery-n01" name="ds-state-recovery-n01"></a><a id="371-n01---preserves-the-complete-ledger-state-through-serialization-and-restoration-including-outputs-allocated-records-and-store-surplus" name="371-n01---preserves-the-complete-ledger-state-through-serialization-and-restoration-including-outputs-allocated-records-and-store-surplus"></a>
**Existing codec coverage.** Dijkstra's [test entry point](../eras/dijkstra/impl/test/Main.hs#L51)
registers the [Conway common](../eras/conway/impl/testlib/Test/Cardano/Ledger/Conway/Binary/RoundTrip.hs#L27)
→ [Alonzo](../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Binary/RoundTrip.hs#L35)
→ [Shelley state round trips](../eras/shelley/impl/testlib/Test/Cardano/Ledger/Shelley/Binary/RoundTrip.hs#L66),
including `UTxOState`, `EpochState` and `NewEpochState`. The [state generator](../eras/shelley/impl/testlib/Test/Cardano/Ledger/Shelley/Arbitrary.hs#L205)
includes an arbitrary Dijkstra Store, and the [output generator](../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Arbitrary.hs#L68)
includes both output forms. This existing serialization coverage stays in the
binary suite. [Allocations P03](#ds-state-allocations-p03) additionally submits an
output whose accepted CBOR is one byte longer than its canonical encoding, then
restores the serialized `UTxOState` and doubles the price. A reference-only
transaction must retain its original record; spending must remove that record.
[Balance P03](#ds-state-balance-p03) checks that the actual Store debit equals the
recorded creation deposit.

<a id="ds-state-recovery-n02" name="ds-state-recovery-n02"></a><a id="372-n02---restores-the-complete-prior-ledger-state-on-rollback-after-ordinary-success-or-accepted-phase-2-failure" name="372-n02---restores-the-complete-prior-ledger-state-on-rollback-after-ordinary-success-or-accepted-phase-2-failure"></a>
**Rollback integration gap.** This ledger package exposes no rollback operation
for a LedgerEffects case to exercise. Consensus integration must restore the
complete prior semantic state after either accepted outcome, then replay the
transition to reproduce its result. Codec equality does not establish rollback
coverage; the former Recovery N02 remains this explicit integration requirement.

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

Compare the complete resulting voting distribution with an independent expectation under existing eligibility, delegation and snapshot rules. Include positive eligible implicit-output ADA and store-backed application ADA, other existing eligible funds, ineligible and differently delegated controls, nonzero recorded deposits across multiple live outputs. Observe ordinary success and accepted phase-2 failure before and after the existing snapshot boundary. Neither records nor the global Store balance add weight, while eligible funds retain their expected weight; an all-zero distribution must fail the positive controls.

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

**Decision:** Every Store-backed allocation retains its accepted full-output size
and explicit `DepositCalculation`. Production creates `DepositCalculationV1 CoinPerByte`.
The V1 formula is
`creationCoinPerByte × (160 + acceptedSize)`. Refunds use this metadata directly,
including after a state snapshot is restored. The current price applies only to new
outputs. No policy history or policy index is needed for this design.

For example, an output accepted at 100 bytes and 4 lovelace per byte contributes
1040 lovelace. A later price of 6 does not change that contribution or its refund.
Noncanonical accepted encodings can be longer than canonical re-encoding; the
snapshot therefore stores the accepted size separately from the output payload.

The calculation module exposes a pure function and an explicit size type:

```haskell
newtype ByteSize = ByteSize {unByteSize :: Int64}

calculateDeposit :: DepositCalculation -> ByteSize -> Coin
```

`DepositCalculationV2 CoinPerByte` provisionally uses the same formula as V1:
`(160 + size) × rate`. Codecs and checked Store operations accept both versions;
unknown encoded versions, such as 3, are rejected. Negative sizes are rejected by
checked Store insertion and entry decoding, rather than by `calculateDeposit`.
Production still selects V1. No parameter-driven version selection or historical
policy migration is introduced by this provisional V2 parity.

Conway translation creates only legacy allocations, with zero external deposit.
Their current import metadata is provisional: `mkSized` at the era's lowest
protocol version and a zero-rate V1 calculation, not recovered history. Newly
accepted legacy outputs instead retain their supplied size and calculation.
An existing Store-backed output without its original size and price cannot be
converted by guessing these values from current parameters or canonical bytes.
Earlier experimental Dijkstra snapshots are rejected under [State representation](#ds-state-representation).

Explicit repricing remains outside this implementation. Such a transition would
need to specify changes to historical records and the corresponding ADA transfers
together. Exact net declarations still disallow voluntary excess allocations.

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
NewTxOut` errors that must be addressed in that work. No context-value
projection or translation change is selected here.

<a id="ds-tx-settlement-refinement" name="ds-tx-settlement-refinement"></a>

#### A.3 Local settlement

> **Determine any stronger guarantee needed beyond the destination’s minimum amount.**
>
> $\text{Settlement output ADA} \ge \text{release amount}$ does not establish the origin of its coins. SubTx fee contributions must remain possible.

**Decision:** Output-index and output-coin checks are agreed, as is existing SubTx
imbalance. The stronger settlement guarantee remains open.

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

> **Keep accepted outputs, sizes and historical calculations together.**

```text
UTxOState
└── utxosUTxOStore :: UTxOStore
    ├── currentCalculation :: DepositCalculation
    ├── totalDepositAmount :: DepositAmount
    └── allocations :: IndexedUTxOs
        └── TxIn → Unspent TxOut
            ├── sizedOutput
            └── depositCalculation
```

The collection types distinguish output inspection from recorded unspent entries:

| Type | Contents | Scope |
| --- | --- | --- |
| `IndexedTxOs` | `TxIn → Sized TxOut` | Proposed outputs or an explicit output-only view; no historical calculation. |
| `IndexedUTxOs` | `TxIn → Unspent TxOut` | Recorded outputs with their historical size and calculation. |

`allocations store` supplies the complete allocation state of that Store; selections
remain `IndexedUTxOs`. There is no additional `Allocations` wrapper. A body alone
cannot recover historical deposit parameters or establish which outputs remain unspent.

| Module under `Cardano.Ledger.State.UTxOs` | Responsibility |
| --- | --- |
| [`Store`](../libs/cardano-ledger-core/src/Cardano/Ledger/State/UTxOs/Store.hs) | `activateNewCalculation`, `allocate`, `release`, checked construction and the cached total. |
| [`IndexedUTxOs`](../libs/cardano-ledger-core/src/Cardano/Ledger/State/UTxOs/IndexedUTxOs.hs) | Input lookup, selection, filtering, entry traversal and deposit totals. |
| [`Unspent`](../libs/cardano-ledger-core/src/Cardano/Ledger/State/UTxOs/Unspent.hs) | One entry's accepted output, original size and calculation; `toTxOut`, `depositAmount` and entry codecs. |
| [`Deposit`](../libs/cardano-ledger-core/src/Cardano/Ledger/State/UTxOs/Deposit.hs) | `DepositAmount`, `ByteSize`, `DepositCalculation` and `calculateDeposit`. |
| [`Store.Error`](../libs/cardano-ledger-core/src/Cardano/Ledger/State/UTxOs/Store/Error.hs) | Invalid incoming size or missing historical metadata. |

[`Cardano.Ledger.TxOut.IndexedTxOs`](../libs/cardano-ledger-core/src/Cardano/Ledger/TxOut/IndexedTxOs.hs)
owns construction, indexing and selection of sized outputs. Each collection has its own
map operations; callers do not unwrap maps for ordinary lookups or selections.

**Queries retain complete entries.** Map operations belong to `IndexedUTxOs`:

```haskell
IndexedUTxOs.lookupUTxO input entries
IndexedUTxOs.restrictToInputs inputs entries
IndexedUTxOs.withoutInputs inputs entries
IndexedUTxOs.filterByTxOut predicate entries
IndexedUTxOs.sumDepositAmounts entries
```

Selections preserve each entry's accepted size and historical calculation.
`extractInputs` returns the remaining and extracted entries in one traversal.
`txOuts` supplies payloads for output-only arithmetic; `mapTxOuts` projects payloads
at external boundaries such as Plutus contexts, diagnostic maps and the formal model.
These projections do not replace the stored entries. `toIndexedTxOs` explicitly retains
outputs and recorded sizes while dropping historical calculations. The block reference-script
check uses this view after selecting its relevant stored inputs, then combines it with
outputs proposed earlier in the block. Deposit accounting never uses this projection.

`UTxOState`, `LedgerState`, `EpochState` and `NewEpochState` expose the complete
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

update :: EraTxBody era => TxBody l era -> UTxOStore era -> UTxOStore era

allocate ::
  EraTxOut era =>
  IndexedTxOs era -> UTxOStore era -> UTxOStore era

activateNewCalculation :: DepositCalculation -> UTxOStore era -> UTxOStore era
```

The body builder preserves bounded output-index enumeration and excludes collateral return.
Babbage, Conway and Dijkstra retain the body's original `Sized` values; earlier eras
construct canonical legacy sizes. No pricing calculation is attached while inspecting a body.
`producedTxOuts` selects regular outputs or collateral return according to the phase-2 outcome,
without claiming ledger acceptance.

`allocate` records `currentCalculation` when new outputs enter the Store. Existing
inputs are resolved through the previous Store and retain their own historical calculation.
The transition is explicit:

```haskell
Store.update body previousStore
```

`update` releases the body's regular inputs and allocates its regular outputs.
It neither validates the body nor traverses nested SubTxs. The ledger selects the
execution path; collateral failure continues to release only collateral inputs
and allocate only the collateral return. Initialization and other operations
without a body may still call `allocate` or `release` directly.

These operations maintain the invariant for a valid Store:

$$
\text{totalDepositAmount}(S)
= \sum_{u\in\text{allocations}(S)} \text{depositAmount}(u)
$$

Replacing an existing input subtracts its previous deposit before adding the replacement.
Releasing an absent input has no effect. Unaffected entries retain their metadata.

**Legacy boundaries retain their formats.**

- Before Dijkstra, collection and Store codecs retain the existing payload-map bytes
  and credential sharing. Decoding reconstructs canonical legacy metadata with zero
  separately held deposits; this is not recovered historical pricing.
- Dijkstra collections encode complete entries as `TxIn → [output, acceptedSize, calculation]`.
  The Store encodes `[currentCalculation, cachedTotal, allocationMap]` and validates the total.
  Snapshot encoding continues to retain MemPack output payloads plus explicit metadata.
- The retired standalone Dijkstra `TxOutMap` payload encoding cannot represent complete
  entries. Its replacement has the complete-entry format. The previous two-field Store
  snapshot is rejected: its active policy cannot be recovered from historical entries,
  especially when the Store is empty.
- `fromLegacyAllocations` accepts only typed legacy outputs. Complete stored entries
  are restored with `mkUTxOStore`, preserving their recorded size and calculation.
  Era translations retain their legacy output translators and introduce no new ADA transfers.

Stake updates still fold output payloads directly. Address inspection and witness verification
remain in `Address` and `Keys.WitVKey`; neither belongs to the indexed collection.

<a id="section-9" name="section-9"></a>

### B. Tag migration

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
| Funding nominal cases and P01; Settlement N01/N02 | [Funding N01](#ds-collateral-funding-n01) |
| Funding rejection cases | [Funding F01](#ds-collateral-funding-f01) |
| Settlement P01; Funding P02 | [Funding P02](#ds-collateral-funding-p02) |
| Scope N01; Funding N09 | [Existing Store activity control and explicit assertion gap](#ds-collateral-store-activity-control) |
| Other Scope cases; Authorization | [Shared collateral regressions](#ds-collateral-existing-rules) |
| Total nominal / rejection cases | [Total N01](#ds-collateral-total-n01) / [F01](#ds-collateral-total-f01) |
| Native-asset nominal / rejection cases from Conservation or Assets | [Assets N01](#ds-collateral-assets-n01) / [F01](#ds-collateral-assets-f01) |
| Surplus; earlier Fees cases | [Fees P01](#ds-state-fees-p01) / [P02](#ds-state-fees-p02) |
| Collateral Conservation N01/P01 | [State Conservation N03](#ds-state-conservation-n03) |

Ledger effects is grouped under UTxO, Store, Fees, Conservation and Lifecycle. Earlier case anchors remain beside the contract or scenario that
owns them; retired identifiers are not separate executable assertions:

| Earlier Ledger effects cases | Current owner |
| --- | --- |
| Execution P01, N01, N04 | [UTxO N01](#ds-state-utxo-n01) and [N02](#ds-state-utxo-n02): ordinary effects and inactive collateral. |
| Execution N02, N03 | [UTxO N03](#ds-state-utxo-n03): collateral effects; [N05](#ds-state-utxo-n05): overlapping input roles. |
| Execution F01, P02 | [Rejected submissions](#ds-state-execution-f01): no applied result; snapshot comparison would retest the submission adapter. |
| Allocations P01–P03, N01–N08 | [Allocations](#ds-state-allocations): ordinary/collateral records, retained accepted size, zero-priced records and inactive ordinary operations after phase-2 failure. |
| Balance P01–P03, N01–N03; Solvency P01, N02 | [Balance](#ds-state-balance): ordinary/collateral transfers and historical releases; balance is the record sum. |
| Solvency N01, F01 | [Retired balance mismatch cases](#ds-state-solvency-n01): mismatched cached totals are rejected by checked construction and decoding. |
| Fees P01; Conservation N01 | Existing identities retained under [Fees](#ds-state-fees) and [Conservation](#ds-state-conservation). |
| Initialization N01–N03 | [Translation N01](#ds-state-translation-n01): actual Conway translation, preserving output payloads and existing monetary pots while introducing legacy allocations and zero external deposits. |
| Solvency N03 | [Epoch N01](#ds-state-epoch-n01): exact Store preservation through ordinary epochs. |
| Recovery N01 | [Existing binary round trips](#ds-state-recovery-n01); post-restoration records and releases belong to [Allocations P03](#ds-state-allocations-p03) and [Balance P03](#ds-state-balance-p03). |
| Recovery N02 | [Consensus rollback integration gap](#ds-state-recovery-n02). |

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
| `DS-TX-002` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](#ds-tx-accounting-net-change-toptx), [DS-TX-ACCOUNTING-ATTRIBUTION](#ds-tx-accounting-attribution), [DS-TX-SETTLEMENT-DESIGNATION](#ds-tx-settlement-designation) |
| `DS-TX-003` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](#ds-tx-accounting-net-change-toptx) |
| `DS-TX-004` | [DS-TX-ACCOUNTING-BALANCE](#ds-tx-accounting-balance) |
| `DS-TX-005` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-ACCOUNTING-ATTRIBUTION](#ds-tx-accounting-attribution), [DS-TX-SETTLEMENT-OUTPUT-INDEX](#ds-tx-settlement-output-index) |
| `DS-TX-006` | [DS-TX-SETTLEMENT-DESIGNATION](#ds-tx-settlement-designation) |
| `DS-TX-007` | [DS-TX-ACCOUNTING-BALANCE](#ds-tx-accounting-balance), [DS-TX-SETTLEMENT-OUTPUT-INDEX](#ds-tx-settlement-output-index), [DS-TX-SETTLEMENT-OUTPUT-COIN](#ds-tx-settlement-output-coin), [DS-STATE-UTXO](#ds-state-utxo) |
| `DS-TX-008` | [DS-TX-DECLARATIONS-GRAMMAR](#ds-tx-declarations-grammar), [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx) |
| `DS-TX-009` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS](#ds-tx-declarations-requirements-subtx-declarations) |
| `DS-TX-010` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-ACCOUNTING-ATTRIBUTION](#ds-tx-accounting-attribution), [DS-TX-ACCOUNTING-BALANCE](#ds-tx-accounting-balance) |
| `DS-TX-011` | [DS-TX-AUTHORIZATION](#ds-tx-authorization) |
| `DS-TX-012` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-MINIMUM-COIN](#ds-tx-minimum-coin) |
| `DS-TX-APPLICATION-ASSETS` | [DS-TX-MINIMUM-COIN](#ds-tx-minimum-coin); case suffixes are unchanged. |
| `DS-COLL-001` | [Shared collateral rules](#ds-collateral-existing-rules), [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-COLLATERAL-ASSETS](#ds-collateral-assets) |
| `DS-COLL-002` | [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-STATE-FEES](#ds-state-fees), [DS-STATE-CONSERVATION](#ds-state-conservation) |
| `DS-COLL-003` | [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-COLLATERAL-TOTAL](#ds-collateral-total) |
| `DS-COLL-004` | [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-STATE-UTXO](#ds-state-utxo), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-BALANCE](#ds-state-balance) |
| `DS-STORE-001` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-BALANCE](#ds-state-balance) |
| `DS-STORE-002` | [DS-PRICING-HISTORY](#ds-pricing-history) |
| `DS-STORE-003` | [DS-PRICING](#ds-pricing), [DS-STATE-ALLOCATIONS](#ds-state-allocations) |
| `DS-STORE-004` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](#ds-tx-declarations-requirements-operations-allocation), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-TRANSLATION](#ds-state-translation) |
| `DS-STORE-005` | [DS-STATE-UTXO](#ds-state-utxo), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-RECOVERY](#ds-state-recovery) |
| `DS-PLUTUS-001` | [DS-PLUTUS-COMPATIBILITY](#ds-plutus-compatibility) |
| `DS-STAKE-001` | [DS-STATE-CONSERVATION](#ds-state-conservation), [DS-STAKE](#ds-stake), [DS-VOTING](#ds-voting) |

The former Attribution cases are now owned by the rule they establish. Shared
claims are checked once; every previous case anchor still resolves:

| Previous Attribution case | Current case |
| --- | --- |
| `P01`, `N01` | [Accounting Attribution P01](#ds-tx-accounting-attribution-p01): signed responsibility, including delegated funding exactly once |
| `P02` | [Accounting Attribution P02](#ds-tx-accounting-attribution-p02): signed responsibility shift; [Net change TopTx P02](#ds-tx-accounting-net-change-toptx-p02): unchanged total |
| `N02` | [Net change TopTx P02](#ds-tx-accounting-net-change-toptx-p02): allocation and release delegation preserve the total |
| `N03` | [Settlement Output index N03](#ds-tx-settlement-output-index-n03): delegate a final release without SubTx outputs |
| `N04` | [Accounting Attribution N01](#ds-tx-accounting-attribution-n01): explicit zero contributes no delegated amount |

Authorization now has one accepted control and its witness-only rejection:

| Previous Authorization case | Current responsibility |
| --- | --- |
| `N01`, `N02` | [Authorization N01](#ds-tx-authorization-n01): Bob signs; original funder Alice does not |
| `F01` | [Authorization F01](#ds-tx-authorization-f01): Alice cannot replace Bob's required witness |
| `N03` | [Release N09](#ds-tx-declarations-requirements-operations-release-n09): existing reference-only declaration case; an attempted release amount is an Accounting concern |

Settlement now names each check directly:

| Previous group | Current group |
| --- | --- |
| `DS-TX-SETTLEMENT-PARTICIPATION` | [Designation](#ds-tx-settlement-designation), retaining P01, N01–N08 and F01–F03 |
| `DS-TX-SETTLEMENT-DESTINATION` | [Output index](#ds-tx-settlement-output-index), retaining every suffix |
| `DS-TX-SETTLEMENT-COVERAGE` | [Output coin](#ds-tx-settlement-output-coin), retaining every suffix |

The intermediate Participation P02/P03/N10 cases now belong to Accounting Attribution
P01/P02/N01. Participation N09 is Output index N03. Their former anchors remain valid.

Accounting groups three responsibilities: Net change validates declared amounts;
Attribution assigns signed contributions; Balance checks ordinary financial
conservation. The following earlier migrations preserve every case suffix and anchor:

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
[DS-TX-ACCOUNTING-ATTRIBUTION-N01](#ds-tx-accounting-attribution-n01). Its old anchor redirects to that case;
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
[DS-TX-SETTLEMENT-OUTPUT-INDEX](#ds-tx-settlement-output-index).

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
| Ledger effects | [`LedgerEffectsSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffectsSpec.hs) composes `UTxOSpec`, `Store/`, `FeesSpec`, `ConservationSpec` and `Lifecycle/`. |

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

[`CollateralSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/CollateralSpec.hs)
composes `FundingSpec`, `TotalSpec` and `AssetsSpec`. Existing input resolution,
witnesses, fee percentages and total-field checks are linked in
[Existing collateral rules](#ds-collateral-existing-rules).
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

[`UTxOSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs)
owns the exact UTxO transition selected by the accepted outcome.
[`AllocationsSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs)
owns retained records; [`BalanceSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs)
checks the change in the sum of records. [`FeesSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs)
checks ordinary and collateral fee credits and unchanged treasury. The map and
Store assertions formerly embedded there now belong to UTxO and Store specs. [`ConservationSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs)
compares independent actual-pot sums with the production total including donations.

[`TranslationSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/TranslationSpec.hs)
corresponds to [full-state translation](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Translation.hs#L103),
[UTxO/Store translation](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Translation.hs#L217)
and [implicit output upgrade](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxOut.hs#L216).
[`EpochSpec`](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs)
observes the Store preserved by [ordinary epoch processing](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Epoch.hs#L218).
Existing codec coverage and the rollback integration gap are linked under
[Lifecycle](#ds-state-recovery).

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
| `Specs.Tx.TopTx.Allocation` | Generate standalone allocations with at least one store-backed output; calculate their allocation and attach the supplied declaration. |
| `Specs.Tx.TopTx.Release` | Keep TopTx and its optional SubTxs with their funded ledger context; calculate the complete transaction's net deposit and apply the supplied declarations. |
| `Specs.Tx.SubTx` | Generate release and equal-allocation-and-release scenarios; expose each child's `allocatedDeposits`, recorded release and `storeBackedInputs` in transaction order, and identify declarations by source input. |
| `Specs.OutputIndex` / `StrictlyPositiveCoin` | Provide shared index generators and checked amount fixtures. |
| `Specs.LedgerEffects` | Fund and sign valid ordinary, delegated or phase-2-invalid scenarios; preserve real noncanonical body bytes and restore UTxO-state snapshots. Expected state changes remain in the specs. |
| `Specs.LedgerEffects.ADA` | Sum actual monetary pots independently of the production ADA-total projection. |
| `Specs.LedgerEffects.UTxO` | Prepare reference-only and overlapping ordinary/collateral input roles while preserving valid signatures and script pointers. |
| `Specs.Lifecycle` | Generate Conway translation states and funded Store scenarios for actual epoch transitions. |
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

- [TopTx declaration domain API](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/TopTx.hs)
- [SubTx declaration domain API](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/SubTx.hs)
- [Transaction fields, operations and lenses](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxBody.hs)
- [Output variants and shared interfaces](../libs/cardano-ledger-core/src/Cardano/Ledger/TxOut.hs)
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
under the [shared collateral rules](#ds-collateral-existing-rules) and [Funding](#ds-collateral-funding).

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
tags and encoded bytes are unchanged. `NewTxOut` remains the output variant
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
