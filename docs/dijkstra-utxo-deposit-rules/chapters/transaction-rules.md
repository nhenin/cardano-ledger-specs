<a id="transaction-rules" name="transaction-rules"></a>

# 2. Transaction rules

[Specification contents](../README.md#table-of-contents) · [← Domain model](domain-model.md) · [Ledger effects →](ledger-effects.md) · [Verification record](../verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/chapters/transaction-rules.md)

> **Validate ordinary operations and collateral terms.**
>
> Tx and Collateral define the two execution paths; Ledger effects determines which effects apply.

## Table of contents

The ordinary transaction rules cover declarations, accounting, authorization, settlement and minimum coin. The collateral rules apply to the shared inputs and return. Expand each group to find its individual cases. [Appendix B](appendices.md#net-change-conformance-cases) lists the expected result and executable test for each net-change case.

<ul type="none"><li>
<details open>
  <summary><a href="#ds-tx">2.1 Tx</a></summary>
  <div><ul type="none"><li>
      <details>
        <summary><a href="#ds-tx-declarations">2.1.1 Declarations</a></summary>
        <div><ul type="none"><li>
            <details>
              <summary><a href="#ds-tx-declarations-grammar">2.1.1.1 Grammar</a></summary>
              <div><ul type="none"><li>
                  <details>
                    <summary><a href="#ds-tx-declarations-grammar-toptx">2.1.1.1.1 TopTx</a></summary>
                    <div><ul type="none"><li>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-toptx-amounts">2.1.1.1.1.1 Amounts</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-p01">2.1.1.1.1.1.1 P01 - Positive amounts survive encoding</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f01">2.1.1.1.1.1.2 F01 - Zero operation amount</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f12">2.1.1.1.1.1.3 F12 - Negative operation amount</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f13">2.1.1.1.1.1.4 F13 - Overflowing operation amount</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-toptx-absence">2.1.1.1.1.2 Absence</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-n03">2.1.1.1.1.2.1 N03 - Absence remains distinct from zero</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-toptx-forms">2.1.1.1.1.3 Forms</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-n05">2.1.1.1.1.3.1 N05 - Every TopTx declaration form</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f06">2.1.1.1.1.3.2 F06 - Funding request in TopTx</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-toptx-structure">2.1.1.1.1.4 Structure</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f02">2.1.1.1.1.4.1 F02 - Malformed declarations</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-toptx-destinations">2.1.1.1.1.5 Destinations</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f04">2.1.1.1.1.5.1 F04 - Malformed release settlements</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f14">2.1.1.1.1.5.2 F14 - Negative output index</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f15">2.1.1.1.1.5.3 F15 - Overflowing output index</a></div>
                          </li></ul></div>
                        </details>
                    </li></ul></div>
                  </details>
                  <details>
                    <summary><a href="#ds-tx-declarations-grammar-subtx">2.1.1.1.2 SubTx</a></summary>
                    <div><ul type="none"><li>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-subtx-amounts">2.1.1.1.2.1 Amounts</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-p02">2.1.1.1.2.1.1 P02 - Positive amounts survive encoding</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f07">2.1.1.1.2.1.2 F07 - Zero operation amount</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f08">2.1.1.1.2.1.3 F08 - Negative operation amount</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f09">2.1.1.1.2.1.4 F09 - Overflowing operation amount</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-subtx-absence">2.1.1.1.2.2 Absence</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-n04">2.1.1.1.2.2.1 N04 - Absence remains distinct from zero</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-subtx-forms">2.1.1.1.2.3 Forms</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-n06">2.1.1.1.2.3.1 N06 - Every SubTx declaration form</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-subtx-structure">2.1.1.1.2.4 Structure</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f03">2.1.1.1.2.4.1 F03 - Malformed declarations</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-grammar-subtx-destinations">2.1.1.1.2.5 Destinations</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f05">2.1.1.1.2.5.1 F05 - Malformed release targets</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f10">2.1.1.1.2.5.2 F10 - Negative output index</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-grammar-f11">2.1.1.1.2.5.3 F11 - Overflowing output index</a></div>
                          </li></ul></div>
                        </details>
                    </li></ul></div>
                  </details>
              </li></ul></div>
            </details>
            <details>
              <summary><a href="#ds-tx-declarations-requirements">2.1.1.2 Requirements</a></summary>
              <div><ul type="none"><li>
                  <details>
                    <summary><a href="#ds-tx-declarations-requirements-operations">2.1.1.2.1 Operations</a></summary>
                    <div><ul type="none"><li>
                        <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-p01">2.1.1.2.1.1 P01 - Every body requiring a Store operation declares</a></div>
                        <details>
                          <summary><a href="#ds-tx-declarations-requirements-operations-allocation">2.1.1.2.1.2 Allocation</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-n01">2.1.1.2.1.2.1 N01 - Every explicit declaration satisfies allocation presence</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-n02">2.1.1.2.1.2.2 N02 - Absence satisfies allocation presence for empty or implicit-only own outputs</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-f01">2.1.1.2.1.2.3 F01 - Missing declaration fails allocation presence at every own-output position</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-n03">2.1.1.2.1.2.4 N03 - accepts a TopTx creating only min-ADA outputs without a declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-n04">2.1.1.2.1.2.5 N04 - accepts a SubTx creating only min-ADA outputs without either body's declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-n05">2.1.1.2.1.2.6 N05 - Standalone TopTx, exact allocation declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-f02">2.1.1.2.1.2.7 F02 - Standalone TopTx, allocation without a declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-f03">2.1.1.2.1.2.8 F03 - rejects a SubTx creating a deposit-backed output without its own declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-f04">2.1.1.2.1.2.9 F04 - rejects a TopTx creating a deposit-backed output without its own declaration even when phase 2 fails</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-f05">2.1.1.2.1.2.10 F05 - rejects a SubTx creating a deposit-backed output without its own declaration even when phase 2 fails</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-f06">2.1.1.2.1.2.11 F06 - rejects a missing own declaration when spending a translated min-ADA output to create deposit-backed outputs</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-n06">2.1.1.2.1.2.12 N06 - SubTx outputs do not trigger TopTx allocation presence</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-n07">2.1.1.2.1.2.13 N07 - Collateral return does not trigger allocation presence</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-n08">2.1.1.2.1.2.14 N08 - Reference and collateral input identifiers do not trigger allocation presence</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-f07">2.1.1.2.1.2.15 F07 - A SubTx declaration cannot satisfy TopTx allocation presence</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-f08">2.1.1.2.1.2.16 F08 - TopTx zero cannot satisfy its allocating SubTx's declaration requirement</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-allocation-n09">2.1.1.2.1.2.17 N09 - TopTx and SubTx allocate deposits, each with an exact declaration</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-requirements-operations-release">2.1.1.2.1.3 Release</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n01">2.1.1.2.1.3.1 N01 - Standalone TopTx, any output form</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n02">2.1.1.2.1.3.2 N02 - Standalone TopTx, only min-ADA outputs</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n03">2.1.1.2.1.3.3 N03 - One SubTx releases its deposit into its own output</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-f01">2.1.1.2.1.3.4 F01 - Standalone TopTx, release without its own declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-f02">2.1.1.2.1.3.5 F02 - SubTx release without its own declaration, despite TopTx declaring</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n04">2.1.1.2.1.3.6 N04 - Phase 2 fails with valid declarations</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-f03">2.1.1.2.1.3.7 F03 - Missing release declaration in a phase-2-invalid proposal</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n05">2.1.1.2.1.3.8 N05 - Several SubTxs release their deposits</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-f04">2.1.1.2.1.3.9 F04 - One SubTx releasing deposits omits its declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n06">2.1.1.2.1.3.10 N06 - Only some SubTxs release Store deposits</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n07">2.1.1.2.1.3.11 N07 - TopTx and several SubTxs release deposits</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n08">2.1.1.2.1.3.12 N08 - Phase 2 fails with several proposed SubTx releases</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-f05">2.1.1.2.1.3.13 F05 - One SubTx declaration is missing in a phase-2-invalid proposal</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n09">2.1.1.2.1.3.14 N09 - Standalone TopTx, reference-only Store access</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-n10">2.1.1.2.1.3.15 N10 - Standalone TopTx, collateral-only Store operations</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-release-f06">2.1.1.2.1.3.16 F06 - A SubTx declaration cannot satisfy TopTx release presence</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-requirements-operations-zero-net-change">2.1.1.2.1.4 Zero net change</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-n01">2.1.1.2.1.4.1 N01 - Standalone TopTx, equal allocations and releases with explicit zero</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-f01">2.1.1.2.1.4.2 F01 - Standalone TopTx, equal allocations and releases without a declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-n02">2.1.1.2.1.4.3 N02 - One SubTx replaces its deposit with explicit zero</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-f02">2.1.1.2.1.4.4 F02 - One active SubTx omits its declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-f03">2.1.1.2.1.4.5 F03 - TopTx omits the declaration required by its child</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-n03">2.1.1.2.1.4.6 N03 - Several SubTxs each replace their deposits</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-f04">2.1.1.2.1.4.7 F04 - One of several active SubTxs omits its declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-n04">2.1.1.2.1.4.8 N04 - Only some SubTxs replace Store deposits</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-f05">2.1.1.2.1.4.9 F05 - One active SubTx omits its declaration among inactive siblings</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-n05">2.1.1.2.1.4.10 N05 - TopTx and several SubTxs each replace their deposits</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-f06">2.1.1.2.1.4.11 F06 - Active TopTx omits its own declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-n06">2.1.1.2.1.4.12 N06 - Phase 2 fails with explicit zero at every active body</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-f07">2.1.1.2.1.4.13 F07 - One SubTx declaration is missing in a phase-2-invalid proposal</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-operations-zero-net-change-f08">2.1.1.2.1.4.14 F08 - TopTx's own declaration is missing in a phase-2-invalid proposal</a></div>
                          </li></ul></div>
                        </details>
                    </li></ul></div>
                  </details>
                  <details>
                    <summary><a href="#ds-tx-declarations-requirements-subtx-declarations">2.1.1.2.2 SubTx declarations</a></summary>
                    <div><ul type="none"><li>
                        <details>
                          <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c01">2.1.1.2.2.1 TopTx requirement</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c01-p01">2.1.1.2.2.1.1 P01 - SubTx declarations require TopTx's declaration</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c02">2.1.1.2.2.2 Absence and explicit zero</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c02-n01">2.1.1.2.2.2.1 N01 - accepts absent declarations at both levels</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c02-n02">2.1.1.2.2.2.2 N02 - accepts explicit zero at both levels</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c02-n03">2.1.1.2.2.2.3 N03 - accepts TopTx zero without a SubTx declaration</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c02-f01">2.1.1.2.2.2.4 F01 - rejects SubTx zero without a TopTx declaration</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c03">2.1.1.2.2.3 Offsetting SubTx contributions</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c03-n01">2.1.1.2.2.3.1 N01 - passes declaration presence with TopTx declaring the zero net amount</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c03-f01">2.1.1.2.2.3.2 F01 - rejects an absent TopTx declaration despite the zero net amount</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c04">2.1.1.2.2.4 Local and delegated accounting</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c04-n01">2.1.1.2.2.4.1 N01 - passes declaration presence with TopTx zero for every explicit SubTx form</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c04-f01">2.1.1.2.2.4.2 F01 - rejects an absent TopTx declaration for every explicit SubTx form</a></div>
                          </li></ul></div>
                        </details>
                        <details>
                          <summary><a href="#ds-tx-declarations-requirements-subtx-declarations-c05">2.1.1.2.2.5 Phase-2 failure</a></summary>
                          <div><ul type="none"><li>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c05-n01">2.1.1.2.2.5.1 N01 - accepts zero declarations at both levels on the phase-2 failure path</a></div>
                              <div>•&numsp;<a href="#ds-tx-declarations-requirements-subtx-declarations-c05-f01">2.1.1.2.2.5.2 F01 - rejects SubTx zero without a TopTx declaration on the phase-2 failure path</a></div>
                          </li></ul></div>
                        </details>
                    </li></ul></div>
                  </details>
              </li></ul></div>
            </details>
        </li></ul></div>
      </details>
      <details>
        <summary><a href="#ds-tx-accounting">2.1.2 Accounting</a></summary>
        <div><ul type="none"><li>
            <details>
              <summary><a href="#ds-tx-accounting-net-change">2.1.2.1 Net change</a></summary>
              <div><ul type="none"><li>
                  <details>
                    <summary><a href="#ds-tx-accounting-net-change-subtx">2.1.2.1.1 SubTx</a></summary>
                    <div><ul type="none"><li>
                        <div>•&numsp;<a href="appendices.md#subtx-net-change-test-cases">SubTx conformance cases and tests</a></div>
                    </li></ul></div>
                  </details>
                  <details>
                    <summary><a href="#ds-tx-accounting-net-change-toptx">2.1.2.1.2 TopTx</a></summary>
                    <div><ul type="none"><li>
                        <div>•&numsp;<a href="appendices.md#toptx-net-change-test-cases">TopTx conformance cases and tests</a></div>
                    </li></ul></div>
                  </details>
              </li></ul></div>
            </details>
            <details>
              <summary><a href="#ds-tx-accounting-attribution">2.1.2.2 Attribution</a></summary>
              <div><ul type="none"><li>
                  <div>•&numsp;<a href="#ds-tx-accounting-attribution-p01">2.1.2.2.1 P01 - Local and delegated contributions determine TopTx's share</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-attribution-p02">2.1.2.2.2 P02 - Delegation moves the signed contribution to TopTx</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-attribution-n01">2.1.2.2.3 N01 - Explicit zero adds no delegated contribution</a></div>
              </li></ul></div>
            </details>
            <details>
              <summary><a href="#ds-tx-accounting-balance">2.1.2.3 Balance</a></summary>
              <div><ul type="none"><li>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-p01">2.1.2.3.1 P01 - The transaction conserves value when phase 2 is valid</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-p02">2.1.2.3.2 P02 - Complete balance determines acceptance</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-n01">2.1.2.3.3 N01 - Fund a net allocation once</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-n02">2.1.2.3.4 N02 - Use a net release once</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-n03">2.1.2.3.5 N03 - One SubTx funds another</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-n04">2.1.2.3.6 N04 - A SubTx funds TopTx fees</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-f01">2.1.2.3.7 F01 - One-lovelace deficit or surplus</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-f02">2.1.2.3.8 F02 - Native-asset quantity or identity mismatch</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-f03">2.1.2.3.9 F03 - An exact delegated allocation lacks funding</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-n05">2.1.2.3.10 N05 - Equal delegated allocations and releases</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-n06">2.1.2.3.11 N06 - Ten input ADA plus two released ADA</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-n07">2.1.2.3.12 N07 - Released ADA contributes to TopTx fees</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-f04">2.1.2.3.13 F04 - Released ADA cannot disappear</a></div>
                  <div>•&numsp;<a href="#ds-tx-accounting-balance-n08">2.1.2.3.14 N08 - Balanced proposal, failed phase 2</a></div>
              </li></ul></div>
            </details>
        </li></ul></div>
      </details>
      <details>
        <summary><a href="#ds-tx-authorization">2.1.3 Authorization</a></summary>
        <div><ul type="none"><li>
            <div>•&numsp;<a href="#ds-tx-authorization-n01">2.1.3.1 N01 - Bob spends an output funded by Alice</a></div>
            <div>•&numsp;<a href="#ds-tx-authorization-f01">2.1.3.2 F01 - Alice's signature cannot replace Bob's</a></div>
        </li></ul></div>
      </details>
      <details>
        <summary><a href="#ds-tx-settlement">2.1.4 Settlement</a></summary>
        <div><ul type="none"><li>
            <details>
              <summary><a href="#ds-tx-settlement-designation">2.1.4.1 Designation</a></summary>
              <div><ul type="none"><li>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-p01">2.1.4.1.1 P01 - Designation follows TopTx's release share</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-n01">2.1.4.1.2 N01 - SubTxs settle the entire release</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-n02">2.1.4.1.3 N02 - Standalone TopTx settles its release</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-n03">2.1.4.1.4 N03 - TopTx and SubTxs each settle a share</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-n04">2.1.4.1.5 N04 - TopTx's share exceeds the transaction release</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-f01">2.1.4.1.6 F01 - TopTx omits a required output</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-f02">2.1.4.1.7 F02 - TopTx designates an unnecessary output</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-n05">2.1.4.1.8 N05 - Net allocation, even though TopTx releases</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-n06">2.1.4.1.9 N06 - Explicit-zero total, even though TopTx releases</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-n07">2.1.4.1.10 N07 - Net release, while TopTx allocates</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-n08">2.1.4.1.11 N08 - Valid designation when phase 2 fails</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-designation-f03">2.1.4.1.12 F03 - Invalid designation when phase 2 fails</a></div>
              </li></ul></div>
            </details>
            <details>
              <summary><a href="#ds-tx-settlement-output-index">2.1.4.2 Output index</a></summary>
              <div><ul type="none"><li>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-p01">2.1.4.2.1 P01 - The index belongs to the declaring body</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-f01">2.1.4.2.2 F01 - The first missing own index is rejected</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-f02">2.1.4.2.3 F02 - A SubTx cannot select TopTx's output</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-f03">2.1.4.2.4 F03 - Collateral return is outside the ordinary output sequence</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-f04">2.1.4.2.5 F04 - A SubTx without outputs cannot settle locally</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-n01">2.1.4.2.6 N01 - The first and last own outputs are valid</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-f05">2.1.4.2.7 F05 - TopTx cannot select a SubTx's output</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-f06">2.1.4.2.8 F06 - A SubTx cannot select a sibling's output</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-n02">2.1.4.2.9 N02 - Valid output indices when phase 2 fails</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-f07">2.1.4.2.10 F07 - An invalid output index still fails when phase 2 fails</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-index-n03">2.1.4.2.11 N03 - A SubTx without outputs delegates its final release</a></div>
              </li></ul></div>
            </details>
            <details>
              <summary><a href="#ds-tx-settlement-output-coin">2.1.4.3 Output coin</a></summary>
              <div><ul type="none"><li>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-p01">2.1.4.3.1 P01 - Output ADA must cover the required share</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-f01">2.1.4.3.2 F01 - Min-ADA output, one lovelace short</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-n01">2.1.4.3.3 N01 - Min-ADA output, exact amount</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-n02">2.1.4.3.4 N02 - Min-ADA output, extra ADA</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-f02">2.1.4.3.5 F02 - An external deposit cannot fill the ADA shortfall</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-n03">2.1.4.3.6 N03 - Deposit-backed output, exact application ADA</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-n04">2.1.4.3.7 N04 - TopTx's share is smaller than the transaction release</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-n05">2.1.4.3.8 N05 - Exact output ADA when phase 2 fails</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-f03">2.1.4.3.9 F03 - One lovelace short when phase 2 fails</a></div>
                  <div>•&numsp;<a href="#ds-tx-settlement-output-coin-f04">2.1.4.3.10 F04 - The transaction release is smaller than TopTx's share</a></div>
              </li></ul></div>
            </details>
        </li></ul></div>
      </details>
      <details>
        <summary><a href="#ds-tx-minimum-coin">2.1.5 Minimum coin</a></summary>
        <div><ul type="none"><li>
            <div>•&numsp;<a href="#ds-tx-minimum-coin-n01">2.1.5.1 N01 - Native assets without ADA</a></div>
            <div>•&numsp;<a href="#ds-tx-minimum-coin-n02">2.1.5.2 N02 - Datum or reference script without assets</a></div>
            <div>•&numsp;<a href="#ds-tx-minimum-coin-n03">2.1.5.3 N03 - Address-only output</a></div>
            <div>•&numsp;<a href="#ds-tx-minimum-coin-n04">2.1.5.4 N04 - Exact minimum for a min-ADA output</a></div>
            <div>•&numsp;<a href="#ds-tx-minimum-coin-f01">2.1.5.5 F01 - Min-ADA output one lovelace short</a></div>
        </li></ul></div>
      </details>
  </li></ul></div>
</details>
<details open>
  <summary><a href="#ds-collateral">2.2 Collateral</a></summary>
  <div><ul type="none"><li>
      <div>•&numsp;<a href="#ds-collateral-existing-rules">Existing collateral rules</a></div>
      <details>
        <summary><a href="#ds-collateral-funding">2.2.1 Funding</a></summary>
        <div><ul type="none"><li>
            <div>•&numsp;<a href="#ds-collateral-funding-n01">2.2.1.1 N01 - Funded collateral</a></div>
            <div>•&numsp;<a href="#ds-collateral-funding-f01">2.2.1.2 F01 - Underfunded collateral</a></div>
            <div>•&numsp;<a href="#ds-collateral-funding-p02">2.2.1.3 P02 - Independent ordinary declarations</a></div>
            <div>•&numsp;<a href="#ds-collateral-funding-p03">2.2.1.4 P03 - Min-ADA return at the active minimum</a></div>
        </li></ul></div>
      </details>
      <details>
        <summary><a href="#ds-collateral-total">2.2.2 Total</a></summary>
        <div><ul type="none"><li>
            <div>•&numsp;<a href="#ds-collateral-total-n01">2.2.2.1 N01 - Absent or exact total</a></div>
            <div>•&numsp;<a href="#ds-collateral-total-f01">2.2.2.2 F01 - Incorrect total</a></div>
        </li></ul></div>
      </details>
      <details>
        <summary><a href="#ds-collateral-assets">2.2.3 Assets</a></summary>
        <div><ul type="none"><li>
            <div>•&numsp;<a href="#ds-collateral-assets-n01">2.2.3.1 N01 - Exact asset map</a></div>
            <div>•&numsp;<a href="#ds-collateral-assets-f01">2.2.3.2 F01 - Missing or altered assets</a></div>
        </li></ul></div>
      </details>
  </li></ul></div>
</details>
</li></ul>

<a id="section-1-2" name="section-1-2"></a>
<a id="ds-tx" name="ds-tx"></a>

## 2.1 Tx

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
rules; it is not a waiver of these declaration checks. [Execution](ledger-effects.md#ds-state-execution)
owns state application and rejection atomicity.

<a id="ds-tx-declarations" name="ds-tx-declarations"></a>

<a id="211-declarations" name="211-declarations"></a>

<a id="211-toptx-and-subtx-deposit-declarations-in-dijkstra" name="211-toptx-and-subtx-deposit-declarations-in-dijkstra"></a>

### 2.1.1 TopTx and SubTx deposit declarations

TopTx and SubTx bodies can carry the declaration forms defined below. The requirements determine when each body must declare.

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

#### 2.1.1.1 Grammar

> **Preserve valid declaration forms; reject malformed representations.**

**Decision:** Agreed.

Grammar reads the declaration itself. It needs no resolved inputs, outputs or Store
state. Its result is **decoded or rejected**; successful decoding alone does not
establish that a transaction may be submitted successfully.

| Responsibility | Rule |
| --- | --- |
| **Amounts** | $`1\le\text{amount}\le 2^{64}-1`$ lovelace for every amount-bearing operation. |
| **Absence** | $`\text{Absent}\ne\text{ExplicitZero}`$. Encoding must preserve the distinction. |
| **Forms** | Preserve the operation, amount and destination. Funding requests belong to SubTx. |
| **Structure** | Recognize the operation and require its fields. |
| **Destinations** | Recognize the destination form; a local index must satisfy $`0\le\text{outputIndex}\le65535`$. |

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

```math
\text{decode}(\text{encode}(\text{declaration}))=\text{declaration}
```

Unless a case names one codec, its checks cover **CBOR and JSON**.

| Representation | Structural checks |
| --- | --- |
| CBOR | Known constructor tag and exact field count, at every supported Dijkstra version. |
| JSON | Known operation kind and required fields. Additional object keys are allowed. |

Whole-body cases also preserve the surrounding body fields. Wire tags and body
field 28 are detailed in the [encoding reference](appendices.md#declaration-encoding).

<a id="ds-tx-grammar-n02" name="ds-tx-grammar-n02"></a>
<a id="ds-tx-declarations-grammar-n02" name="ds-tx-declarations-grammar-n02"></a>

The reusable `StrictlyPositiveCoin` type owns the positive-amount invariant;
[`StrictlyPositiveCoinSpec`](../../../libs/cardano-ledger-core/test/Test/Cardano/Ledger/StrictlyPositiveCoinSpec.hs)
tests its constructor and scalar codecs. Grammar checks the type's use **inside
declarations**, including rejection of raw external values that bypass construction.

TopTx and SubTx follow the same reading order:
**Amounts → Absence → Forms → Structure → Destinations**.
Case numbers restart within each category; each tag links to its executable check.

<a id="ds-tx-grammar-toptx" name="ds-tx-grammar-toptx"></a>
<a id="ds-tx-declarations-grammar-toptx" name="ds-tx-declarations-grammar-toptx"></a>

##### 2.1.1.1.1 TopTx

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
| <a id="ds-tx-grammar-p01" name="ds-tx-grammar-p01"></a><a id="ds-tx-declarations-grammar-p01" name="ds-tx-declarations-grammar-p01"></a>**1.&nbsp;[P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L36)** | **Positive amounts survive encoding.** A generated `StrictlyPositiveCoin` in every amount-bearing form. | Preserve the operation, amount and settlement through both codecs. |
| <a id="ds-tx-grammar-f01" name="ds-tx-grammar-f01"></a><a id="ds-tx-declarations-grammar-f01" name="ds-tx-declarations-grammar-f01"></a>**2.&nbsp;[F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L40)** | **Zero operation amount.** Raw $`\text{amount}=0`$. | Reject decoding. Explicit zero has its own form. |
| <a id="ds-tx-grammar-f12" name="ds-tx-grammar-f12"></a><a id="ds-tx-declarations-grammar-f12" name="ds-tx-declarations-grammar-f12"></a>**3.&nbsp;[F12](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L43)** | **Negative operation amount.** Raw $`\text{amount}=-1`$. | Reject decoding: below the lower bound. |
| <a id="ds-tx-grammar-f13" name="ds-tx-grammar-f13"></a><a id="ds-tx-declarations-grammar-f13" name="ds-tx-declarations-grammar-f13"></a>**4.&nbsp;[F13](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L46)** | **Overflowing operation amount.** Raw $`\text{amount}=2^{64}`$. | Reject decoding without truncation or wrapping. |

Every generated set includes allocation, release without TopTx settlement, and
local release at indices $`0`$, $`65535`$ and one generated interior index. Thus each
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
| <a id="ds-tx-grammar-n03" name="ds-tx-grammar-n03"></a><a id="ds-tx-declarations-grammar-n03" name="ds-tx-declarations-grammar-n03"></a>**1.&nbsp;[N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L51)** | **Absence remains distinct from zero.** Two otherwise identical complete bodies, differing only in their declaration. | Distinct encodings; decoding preserves each complete body. |

Both bodies share the same generated spending inputs, reference inputs and
auxiliary-data hash. Only the declaration differs:

```math
\begin{aligned}
\text{encode(absentBody)} &\ne \text{encode(explicitZeroBody)} \\
\text{decode(encode(absentBody))} &= \text{absentBody} \\
\text{decode(encode(explicitZeroBody))} &= \text{explicitZeroBody}
\end{aligned}
```

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
| <a id="ds-tx-grammar-n05" name="ds-tx-grammar-n05"></a><a id="ds-tx-declarations-grammar-n05" name="ds-tx-declarations-grammar-n05"></a>**1.&nbsp;[N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L58)** | **Every TopTx declaration form.** Explicit zero and all amount-bearing forms at both amount bounds. | Preserve each form, amount and settlement. |
| <a id="ds-tx-grammar-f06" name="ds-tx-grammar-f06"></a><a id="ds-tx-declarations-grammar-f06" name="ds-tx-declarations-grammar-f06"></a>**2.&nbsp;[F06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L62)** | **Funding request in TopTx.** A valid SubTx funding request is passed to the TopTx decoder. | SubTx preserves the request in both codecs; TopTx rejects its JSON representation. |

N05 includes explicit zero and every amount-bearing variant at **both** positive
bounds, $`1`$ and $`2^{64}-1`$: eleven declarations per draw. Release variants include
`NoTopTxSettlement` and `TopTxSettlementOutput` at indices $`0`$, $`65535`$ and a
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
| <a id="ds-tx-grammar-f02" name="ds-tx-grammar-f02"></a><a id="ds-tx-declarations-grammar-f02" name="ds-tx-declarations-grammar-f02"></a>**1.&nbsp;[F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L68)** | **Malformed declarations.** Invalid containers, unknown operations, missing required fields or extra CBOR fields. | Reject each malformed input in its own format. |

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
| `TopTxSettlementOutput outputIndex` | $`0\le\text{outputIndex}\le65535`$. |

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-f04" name="ds-tx-grammar-f04"></a><a id="ds-tx-declarations-grammar-f04" name="ds-tx-declarations-grammar-f04"></a>**1.&nbsp;[F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L73)** | **Malformed release settlements.** Wrong container, unknown form, missing local index or extra CBOR fields. | Reject decoding with otherwise valid indices. |
| <a id="ds-tx-grammar-f14" name="ds-tx-grammar-f14"></a><a id="ds-tx-declarations-grammar-f14" name="ds-tx-declarations-grammar-f14"></a>**2.&nbsp;[F14](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L76)** | **Negative output index.** Generated $`\text{outputIndex}\lt 0`$, favouring $`-1`$. | Reject the local settlement in both codecs. |
| <a id="ds-tx-grammar-f15" name="ds-tx-grammar-f15"></a><a id="ds-tx-declarations-grammar-f15" name="ds-tx-declarations-grammar-f15"></a>**3.&nbsp;[F15](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L80)** | **Overflowing output index.** Generated $`\text{outputIndex}\gt 65535`$, favouring $`65536`$. | Reject the settlement without truncation or wrapping. |

F04 covers six CBOR and five JSON structural defects per draw: invalid containers,
unknown forms, missing local indices and extra CBOR fields. Examples include CBOR
`[0,1]` (an index on the no-settlement form) and `[1]` (a local form without its
index). Any supplied local index remains within range.

F14 and F15 generate values throughout their respective invalid ranges, favouring
$`-1`$ and $`65536`$. Shrinking keeps a counterexample in the same invalid range.
[N05](#ds-tx-declarations-grammar-n05) supplies the valid $`0`$ and $`65535`$ controls.
[Settlement](#ds-tx-settlement-output-index) separately checks that the index names
an existing output in TopTx.

<a id="ds-tx-grammar-subtx" name="ds-tx-grammar-subtx"></a>
<a id="ds-tx-declarations-grammar-subtx" name="ds-tx-declarations-grammar-subtx"></a>

##### 2.1.1.1.2 SubTx

A SubTx can declare zero, allocate locally, request funding from TopTx, or release
to its own output or TopTx. Encoding preserves which choice it made.

<a id="ds-tx-grammar-subtx-amounts" name="ds-tx-grammar-subtx-amounts"></a>
<a id="ds-tx-declarations-grammar-subtx-amounts" name="ds-tx-declarations-grammar-subtx-amounts"></a>

**2.1.1.1.2.1 Amounts**

> **Allocation, funding requests and releases carry a strictly positive amount.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-p02" name="ds-tx-grammar-p02"></a><a id="ds-tx-declarations-grammar-p02" name="ds-tx-declarations-grammar-p02"></a>**1.&nbsp;[P02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L33)** | **Positive amounts survive encoding.** A generated `StrictlyPositiveCoin` in every amount-bearing form. | Preserve the operation, amount and target through both codecs. |
| <a id="ds-tx-grammar-f07" name="ds-tx-grammar-f07"></a><a id="ds-tx-declarations-grammar-f07" name="ds-tx-declarations-grammar-f07"></a>**2.&nbsp;[F07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L37)** | **Zero operation amount.** Raw $`\text{amount}=0`$. | Reject decoding. An amount-bearing operation cannot stand in for explicit zero. |
| <a id="ds-tx-grammar-f08" name="ds-tx-grammar-f08"></a><a id="ds-tx-declarations-grammar-f08" name="ds-tx-declarations-grammar-f08"></a>**3.&nbsp;[F08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L40)** | **Negative operation amount.** Raw $`\text{amount}=-1`$. | Reject decoding: the amount is below the lower bound. |
| <a id="ds-tx-grammar-f09" name="ds-tx-grammar-f09"></a><a id="ds-tx-declarations-grammar-f09" name="ds-tx-declarations-grammar-f09"></a>**4.&nbsp;[F09](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L43)** | **Overflowing operation amount.** Raw $`\text{amount}=2^{64}`$. | Reject decoding without truncation or wrapping. |

F07–F09 generate declaration payloads around the **fixed raw amount shown**;
they do not generate arbitrary negative or overflowing amounts. Each draw covers
six declarations per codec: allocation, request, delegated release, and local
release at $`0`$, $`65535`$ and a generated index in $`1\ldots65534`$.

<a id="ds-tx-grammar-subtx-absence" name="ds-tx-grammar-subtx-absence"></a>
<a id="ds-tx-declarations-grammar-subtx-absence" name="ds-tx-declarations-grammar-subtx-absence"></a>

**2.1.1.1.2.2 Absence**

> **Declaring zero is different from declaring nothing.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-n04" name="ds-tx-grammar-n04"></a><a id="ds-tx-declarations-grammar-n04" name="ds-tx-declarations-grammar-n04"></a>**1.&nbsp;[N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L48)** | **Absence remains distinct from zero.** The same complete body, differing only in its declaration. | Distinct CBOR and JSON representations; decoding preserves each complete body. |

Both bodies share the same generated spending inputs, reference inputs and
auxiliary-data hash. Only the declaration differs:

```math
\begin{aligned}
\text{encode(absentBody)} &\ne \text{encode(explicitZeroBody)} \\
\text{decode(encode(absentBody))} &= \text{absentBody} \\
\text{decode(encode(explicitZeroBody))} &= \text{explicitZeroBody}
\end{aligned}
```

This preserves the distinction needed by Requirements without deciding whether either
body has declared enough for its Store operations.

<a id="ds-tx-grammar-subtx-forms" name="ds-tx-grammar-subtx-forms"></a>
<a id="ds-tx-declarations-grammar-subtx-forms" name="ds-tx-declarations-grammar-subtx-forms"></a>

**2.1.1.1.2.3 Forms**

> **Preserve every SubTx form, including explicit funding requests.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-n06" name="ds-tx-grammar-n06"></a><a id="ds-tx-declarations-grammar-n06" name="ds-tx-declarations-grammar-n06"></a>**1.&nbsp;[N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L55)** | **Every SubTx declaration form.** Explicit zero and every amount-bearing form at both amount bounds. | Preserve each form, amount and target through both codecs. |

The amount bounds are $`1`$ and $`2^{64}-1`$. Local releases use $`0`$, $`65535`$ and a
generated interior index in $`1\ldots65534`$. Together with explicit zero, these
produce thirteen declarations per draw. P02 varies the amount across its valid
range; N06 always includes both bounds.

<a id="ds-tx-grammar-subtx-structure" name="ds-tx-grammar-subtx-structure"></a>
<a id="ds-tx-declarations-grammar-subtx-structure" name="ds-tx-declarations-grammar-subtx-structure"></a>

**2.1.1.1.2.4 Structure**

> **A recognized operation must carry exactly its required CBOR fields, or all required JSON fields.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-f03" name="ds-tx-grammar-f03"></a><a id="ds-tx-declarations-grammar-f03" name="ds-tx-declarations-grammar-f03"></a>**1.&nbsp;[F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L61)** | **Malformed declarations.** Invalid containers, unknown operations, missing required fields or extra CBOR fields. | Reject each malformed input in its own format. |

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
| `SubTxSettlementOutput outputIndex` | $`0\le\text{outputIndex}\le65535`$. |

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-f05" name="ds-tx-grammar-f05"></a><a id="ds-tx-declarations-grammar-f05" name="ds-tx-declarations-grammar-f05"></a>**1.&nbsp;[F05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L66)** | **Malformed release targets.** Wrong container, unknown target, missing local index or extra CBOR fields. | Reject decoding with otherwise valid indices. |
| <a id="ds-tx-grammar-f10" name="ds-tx-grammar-f10"></a><a id="ds-tx-declarations-grammar-f10" name="ds-tx-declarations-grammar-f10"></a>**2.&nbsp;[F10](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L69)** | **Negative output index.** Generated $`\text{outputIndex}\lt 0`$, favouring $`-1`$. | Reject a local target carrying that index in both codecs. |
| <a id="ds-tx-grammar-f11" name="ds-tx-grammar-f11"></a><a id="ds-tx-declarations-grammar-f11" name="ds-tx-declarations-grammar-f11"></a>**3.&nbsp;[F11](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L73)** | **Overflowing output index.** Generated $`\text{outputIndex}\gt 65535`$, favouring $`65536`$. | Reject the target without truncation or wrapping. |

F05 covers six CBOR and five JSON structural defects per draw: invalid containers,
unknown forms, missing local indices and extra CBOR fields. Examples include CBOR
`[1,0]` (an index attached to delegation) and `[0]` (a local target without its
index). Any supplied local index remains within range.

F10 and F11 generate values throughout their respective invalid ranges, favouring
$`-1`$ and $`65536`$. Shrinking keeps a counterexample in the same invalid range.
[N06](#ds-tx-declarations-grammar-n06) supplies the valid $`0`$ and $`65535`$ controls.
[Settlement](#ds-tx-settlement-output-index) separately checks that the index names
an existing output in this SubTx.

<a id="ds-tx-presence" name="ds-tx-presence"></a>
<a id="ds-tx-required-declarations" name="ds-tx-required-declarations"></a>
<a id="ds-tx-declarations-requirements" name="ds-tx-declarations-requirements"></a>

#### 2.1.1.2 Requirements

> **Determine which body must supply a declaration.**

| Trigger | Required field |
| --- | --- |
| A body's own ordinary Store allocation or release | That body's own declaration. Parent and child fields cannot substitute for it. |
| An explicit SubTx declaration, including zero | A TopTx declaration, even when TopTx has no own Store operations. |

```math
\begin{aligned}
\text{ownStoreOperations(body)} &\implies\text{hasDeclaration(body)} \\
\text{hasDeclaration(subTx)} &\implies\text{hasDeclaration(topTx)}
\end{aligned}
```

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

##### 2.1.1.2.1 Operations

> **Require a declaration for the body’s own Store operations.**
>
> Allocation or release $`\implies`$ own declaration required.

**Decision:** Agreed.

A body requiring an allocation or releasing a recorded deposit must provide its
own declaration field. TopTx declares the complete batch amount; SubTx declares
its own contribution.

| Own regular operation | UTxO condition | Outside this body's operations |
| --- | --- | --- |
| **Allocation** | A newly created deposit-backed output needs a deposit recorded in the Store. | Collateral return and a child's outputs. |
| **Release** | A consumed deposit-backed output releases its recorded deposit. | Reference inputs, collateral inputs and a child's inputs. |

These gross external operations determine declaration presence. An explicit declaration
also counts the minimum-ADA reserves of the body's ordinary inputs and outputs.
[Net change](#ds-tx-accounting-net-change) defines both contributions.

A body may require both operations, even when its signed backing change is zero.
The zero-change fixtures match equal, nonzero external allocations and releases
while preserving embedded backing. [Zero net change](#ds-tx-declarations-requirements-operations-zero-net-change)
On an accepted phase-2 failure, these requirements describe
the hypothetical ordinary transition; only collateral effects execute.

This requirement applies separately to TopTx and each SubTx. An explicit zero is a
declaration; an absent declaration is not. The declared amount must also satisfy the
separate exact-accounting rules, including TopTx's declaration of the batch total.

Define:

- `outputs(body)`: the body's own outputs, after removing the `Sized` wrapper.
- `spentOutputs(body)`: the outputs resolved from the body's own spending inputs.
- `change(body)`: the declaration field for that body's level, listed in the
  [body-field reference](appendices.md#transaction-body-fields).
- `hasDeclaration(body)`: whether that field explicitly declares an operation,
  including explicit zero.
- `requiresAllocation(body)`: at least one element of `outputs(body)` has the
  `DepositBackedTxOut` constructor.
- `releasesDeposits(body)`: at least one element of `spentOutputs(body)` has the
  `DepositBackedTxOut` constructor.

These predicates identify the output form, independently of the deposit price
or the signed net amount. Together they define the body's own Store operations:

```math
\begin{aligned}
\text{ownStoreOperations(body)}
&\iff\text{requiresAllocation(body)}\lor\text{releasesDeposits(body)} \\
\text{operationsPresenceSatisfied(body)}
&\iff\neg\text{ownStoreOperations(body)}\lor\text{hasDeclaration(body)}
\end{aligned}
```

This boundary determines **which body must declare**. TopTx's declared amount
still includes every SubTx's contribution, and
[SubTx declarations](#ds-tx-declarations-requirements-subtx-declarations) can require its field
without any own Store operation.

The required condition is:

```math
\begin{aligned}
&\text{requiresAllocation(body)} \lor \text{releasesDeposits(body)} \\
&\qquad\implies \text{hasDeclaration(body)}
\end{aligned}
```

Equivalently:

```math
\begin{aligned}
&\neg\text{hasDeclaration(body)} \\
&\qquad\implies
\forall\,\text{output}\in\text{outputs(body)}\cup\text{spentOutputs(body)}:\quad
\text{isImplicitDeposit(output)}
\end{aligned}
```

Here $`\text{isImplicitDeposit(output)}`$ means that the output has the
`MinAdaTxOut` constructor.

If either condition is true and `hasDeclaration(body)` is false, reject the body.
DS-TX-ACCOUNTING-NET-CHANGE-SUBTX additionally requires a release
contribution when deposit-backed outputs are spent without creating any new deposit-backed
outputs.

**Declaration requirement decision table**

These results concern **DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS only**. Passing this check does not establish that the
transaction satisfies funding, release, or other ledger rules.

| Own spent outputs | Own created outputs | Own operation field | Result for DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS |
| --- | --- | --- | --- |
| Only min-ADA outputs, or empty | Only min-ADA outputs, or empty | `NoUTxODepositDeclaration` | Pass |
| At least one deposit-backed output | Only min-ADA outputs, or empty | `NoUTxODepositDeclaration` | Reject |
| Any | At least one deposit-backed output | `NoUTxODepositDeclaration` | Reject |
| Any | Any | Explicit declaration, including zero | Pass |

The same cases apply to TopTx and SubTx. In particular:

- A TopTx declaration does not replace a missing SubTx declaration. If the SubTx
  creates or spends a deposit-backed output with `SubTx.NoUTxODepositDeclaration`, reject that SubTx even
  when the TopTx declares an operation.
- A SubTx declaration does not replace a missing TopTx declaration either. If
  the TopTx creates or spends a deposit-backed output with `TopTx.NoUTxODepositDeclaration`, reject the
  TopTx even when its SubTx bodies declare operations.
- A SubTx that requests funding through `SubTx.RequestsUTxODepositFromTopTx amount`
  has made an explicit declaration and passes this presence check.
  DS-TX-ACCOUNTING-NET-CHANGE-SUBTX checks the requested amount, DS-TX-ACCOUNTING-ATTRIBUTION assigns
  its accounting to TopTx, and DS-TX-ACCOUNTING-BALANCE requires the complete batch to fund it.
- A TopTx whose own spent and created outputs are all min-ADA outputs
  and whose field is `TopTx.NoUTxODepositDeclaration`, containing a SubTx with deposit-backed outputs
  and an explicit operation, passes this check for both bodies. This says nothing
  about overall validity: DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS rejects the missing TopTx declaration.
- Creating deposit-backed outputs still requires a declaration when the net
  funding requirement is zero. An active SubTx with a zero required own change uses `SubTx.DeclaresZeroNetUTxODeposit`. TopTx uses `TopTx.DeclaresZeroNetUTxODeposit` when the complete required batch change is zero, regardless of its own contribution.

<a id="ds-tx-presence-activity-p01" name="ds-tx-presence-activity-p01"></a>
<a id="ds-tx-presence-operations-p01" name="ds-tx-presence-operations-p01"></a>
<a id="ds-tx-required-declarations-operations-p01" name="ds-tx-required-declarations-operations-p01"></a>
<a id="ds-tx-declarations-requirements-operations-p01" name="ds-tx-declarations-requirements-operations-p01"></a>

**2.1.1.2.1.1 [P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/OperationsSpec.hs#L44) - Every body requiring a Store operation declares**

> **An operation requires a declaration even when its priced amount is zero.**

Generate TopTx and zero to four SubTxs. Each body's source and output forms vary
independently between min-ADA and deposit-backed. Resolve sources from the actual
funded UTxO; inspect each body's own proposed outputs.

```math
\begin{aligned}
&\text{Accepted}\implies\forall\,\text{body}: \\
&\quad\text{ownStoreOperations(body)}\implies\text{hasDeclaration(body)}
\end{aligned}
```

The generated context deliberately sets the deposit price to zero. Output forms
still determine whether an allocation or release is proposed:

```math
\begin{aligned}
\text{depositPrice}&=0 \\
\text{allocatedDeposits(body)}&=\text{releasedDeposits(body)}=0 \\
\text{depositBackedOutput}&\ne\text{implicitOutput}
\end{aligned}
```

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

```math
\forall\,\text{body}:\quad
\text{createdDepositBackedOutputs(body)}\ne\varnothing
\implies\text{hasDeclaration(body)}
```

**Decision:** Agreed.

Here $`\text{createdDepositBackedOutputs(body)}`$ means the deposit-backed outputs in
that body's **own regular output sequence**. It excludes collateral return and,
for TopTx, its children's outputs. Inspect every own-output position, including
mixed sequences. Any explicit declaration satisfies allocation presence; amounts,
funding and settlement remain separate requirements.

| Cases | What they establish |
| --- | --- |
| N01, N02, F01 | Isolated allocation presence for TopTx and SubTx. Passing does not prove exact amounts or funding. |
| N03, N04 | Ledger acceptance with only min-ADA outputs and no declarations. |
| N05, F02 | A funded standalone allocation is accepted; removing only its declaration is rejected. |
| F03, F04, F05 | The required body-specific missing-declaration failure in the SubTx and phase-2 rejection fixtures. These are not paired with otherwise valid allocation controls. |
| F06 | A Conway output upgraded to a min-ADA Dijkstra output cannot waive the declaration required by new Store allocations; an exact control is accepted. |
| N06, N07, N08, F07 | Isolated TopTx allocation presence: only its own regular outputs trigger the requirement, and a child's declaration cannot supply its field. |
| F08 | A specific SubTx missing-declaration failure, even when TopTx declares zero. |
| N09 | Parent and child allocate with independently priced amounts; TopTx declares their combined allocation and SubTx its own. |

**N05 and F02 share this standalone context:**

```math
\begin{aligned}
&\text{subTxs}=\varnothing \\
&\land\ \text{spentDepositBackedOutputs(topTx)}=\varnothing \\
&\land\ \text{createdDepositBackedOutputs(topTx)}\ne\varnothing
\end{aligned}
```

Only min-ADA inputs are spent, so no existing deposit is released. **Allocation
alone** requires the declaration. A phase-2-invalid marker does not bypass
allocation presence; F04 and F05 check that obligation separately.

<a id="ds-tx-presence-activity-creation-n01" name="ds-tx-presence-activity-creation-n01"></a>
<a id="ds-tx-presence-operations-allocation-n01" name="ds-tx-presence-operations-allocation-n01"></a>
<a id="ds-tx-required-declarations-operations-allocation-n01" name="ds-tx-required-declarations-operations-allocation-n01"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n01" name="ds-tx-declarations-requirements-operations-allocation-n01"></a>

**2.1.1.2.1.2.1 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L59) - Every explicit declaration satisfies allocation presence**

For both TopTx and SubTx, every explicit declaration counts as present: zero,
allocation, release and SubTx delegation. The isolated allocation-presence validator succeeds
for each form and each generated arrangement of deposit-backed own outputs.

```math
\begin{aligned}
&\text{createdDepositBackedOutputs(body)}\ne\varnothing \\
&\land\ \text{hasDeclaration(body)} \\
&\implies\text{AllocationPresenceSatisfied}
\end{aligned}
```

This is **not ledger acceptance**. An explicit zero, for example, satisfies
presence even when the required allocation is positive; exactness must check it.

<a id="ds-tx-presence-activity-creation-n02" name="ds-tx-presence-activity-creation-n02"></a>
<a id="ds-tx-presence-operations-allocation-n02" name="ds-tx-presence-operations-allocation-n02"></a>
<a id="ds-tx-required-declarations-operations-allocation-n02" name="ds-tx-required-declarations-operations-allocation-n02"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n02" name="ds-tx-declarations-requirements-operations-allocation-n02"></a>

**2.1.1.2.1.2.2 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L76) - Absence satisfies allocation presence for empty or implicit-only own outputs**

An empty or implicit-only own output sequence introduces no allocation-presence
requirement. Both isolated validators succeed with an absent declaration.

```math
\begin{aligned}
&\text{createdDepositBackedOutputs(body)}=\varnothing \\
&\land\ \neg\text{hasDeclaration(body)} \\
&\implies\text{AllocationPresenceSatisfied}
\end{aligned}
```

This says nothing about release or declaration dependency, which may still
require a declaration before the ledger can accept the transaction.

<a id="ds-tx-presence-activity-creation-f01" name="ds-tx-presence-activity-creation-f01"></a>
<a id="ds-tx-presence-operations-allocation-f01" name="ds-tx-presence-operations-allocation-f01"></a>
<a id="ds-tx-required-declarations-operations-allocation-f01" name="ds-tx-required-declarations-operations-allocation-f01"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f01" name="ds-tx-declarations-requirements-operations-allocation-f01"></a>

**2.1.1.2.1.2.3 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L85) - Missing declaration fails allocation presence at every own-output position**

One deposit-backed own output is enough to require a declaration, wherever it
appears among min-ADA outputs. The generated cases place it at every position
in each generated sequence and check both TopTx and SubTx.

```math
\begin{aligned}
&\text{createdDepositBackedOutputs(body)}\ne\varnothing \\
&\land\ \neg\text{hasDeclaration(body)} \\
&\implies\text{AllocationPresenceFails}
\end{aligned}
```

The isolated validator must return `MissingBodyUTxODepositDeclaration`. No
transaction is submitted in this check.

<a id="ds-tx-presence-activity-creation-n03" name="ds-tx-presence-activity-creation-n03"></a>
<a id="ds-tx-presence-operations-allocation-n03" name="ds-tx-presence-operations-allocation-n03"></a>
<a id="ds-tx-required-declarations-operations-allocation-n03" name="ds-tx-required-declarations-operations-allocation-n03"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n03" name="ds-tx-declarations-requirements-operations-allocation-n03"></a>

**2.1.1.2.1.2.4 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L95) - accepts a TopTx creating only min-ADA outputs without a declaration**

A TopTx creating only min-ADA outputs is accepted by the ledger without a Store declaration when its ordinary inputs, fees, and witnesses are valid. Its outputs impose no allocation-presence requirement.

<a id="ds-tx-presence-activity-creation-n04" name="ds-tx-presence-activity-creation-n04"></a>
<a id="ds-tx-presence-operations-allocation-n04" name="ds-tx-presence-operations-allocation-n04"></a>
<a id="ds-tx-required-declarations-operations-allocation-n04" name="ds-tx-required-declarations-operations-allocation-n04"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n04" name="ds-tx-declarations-requirements-operations-allocation-n04"></a>

**2.1.1.2.1.2.5 [N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L99) - accepts a SubTx creating only min-ADA outputs without either body's declaration**

A SubTx creating only min-ADA outputs is accepted within a ledger transaction when neither level declares a Store operation. Ordinary transaction preparation supplies valid funding and witnesses; no Store allocation is created.

<a id="ds-tx-presence-activity-creation-n05" name="ds-tx-presence-activity-creation-n05"></a>
<a id="ds-tx-presence-operations-allocation-n05" name="ds-tx-presence-operations-allocation-n05"></a>
<a id="ds-tx-required-declarations-operations-allocation-n05" name="ds-tx-required-declarations-operations-allocation-n05"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n05" name="ds-tx-declarations-requirements-operations-allocation-n05"></a>

**2.1.1.2.1.2.6 [N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L114) - Standalone TopTx, exact allocation declaration**

Generate one to five outputs with varying application ADA and at least one
deposit-backed output. Each proposed output counts toward the signed declaration.
The fee input and its change carry equal minimum-ADA reserves, so they cancel.
In this standalone fixture,

```math
\text{declaredNetDeposit(topTx)}
=\sum_{o\in\text{generatedOutputs}}\text{currentFormula}(o).
```

The builder must fund the full external deposits and the serialized output values,
including ADA held in min-ADA outputs, along with the fee. The correctly declared,
funded and signed proposal is accepted.

<a id="ds-tx-presence-activity-creation-f02" name="ds-tx-presence-activity-creation-f02"></a>
<a id="ds-tx-presence-operations-allocation-f02" name="ds-tx-presence-operations-allocation-f02"></a>
<a id="ds-tx-required-declarations-operations-allocation-f02" name="ds-tx-required-declarations-operations-allocation-f02"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f02" name="ds-tx-declarations-requirements-operations-allocation-f02"></a>

**2.1.1.2.1.2.7 [F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L130) - Standalone TopTx, allocation without a declaration**

Build and sign the exact allocation from [N05](#ds-tx-declarations-requirements-operations-allocation-n05),
then remove only TopTx's declaration and re-sign. Keep its funded inputs, proposed
outputs and fees unchanged; do not rebalance the mutated transaction.

```math
\neg\text{hasDeclaration(topTx)}
\implies\text{RejectedWith(MissingUTxODepositDeclaration)}
```

Creation of a deposit-backed output requires the declaration. Removing the
field preserves the actual external movement and submitted values. Require the
missing-declaration failure, then submit the fully declared control and require
acceptance.

<a id="ds-tx-presence-activity-creation-f03" name="ds-tx-presence-activity-creation-f03"></a>
<a id="ds-tx-presence-operations-allocation-f03" name="ds-tx-presence-operations-allocation-f03"></a>
<a id="ds-tx-required-declarations-operations-allocation-f03" name="ds-tx-required-declarations-operations-allocation-f03"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f03" name="ds-tx-declarations-requirements-operations-allocation-f03"></a>

**2.1.1.2.1.2.8 [F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L145) - rejects a SubTx creating a deposit-backed output without its own declaration**

The ledger rejects a SubTx that creates a deposit-backed own output without a SubTx declaration. The expected failure is SubMissingUTxODepositDeclaration, and rejection leaves ledger state unchanged. Declaration presence is required independently for the creating body.

<a id="ds-tx-presence-activity-creation-f04" name="ds-tx-presence-activity-creation-f04"></a>
<a id="ds-tx-presence-operations-allocation-f04" name="ds-tx-presence-operations-allocation-f04"></a>
<a id="ds-tx-required-declarations-operations-allocation-f04" name="ds-tx-required-declarations-operations-allocation-f04"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f04" name="ds-tx-declarations-requirements-operations-allocation-f04"></a>

**2.1.1.2.1.2.9 [F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L149) - rejects a TopTx creating a deposit-backed output without its own declaration even when phase 2 fails**

A real failing phase-2 script does not waive TopTx's structural declaration requirement. Even with the transaction marked phase-2 invalid, creating a deposit-backed own output without a declaration yields MissingUTxODepositDeclaration and leaves the ledger unchanged.

<a id="ds-tx-presence-activity-creation-f05" name="ds-tx-presence-activity-creation-f05"></a>
<a id="ds-tx-presence-operations-allocation-f05" name="ds-tx-presence-operations-allocation-f05"></a>
<a id="ds-tx-required-declarations-operations-allocation-f05" name="ds-tx-required-declarations-operations-allocation-f05"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f05" name="ds-tx-declarations-requirements-operations-allocation-f05"></a>

**2.1.1.2.1.2.10 [F05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L153) - rejects a SubTx creating a deposit-backed output without its own declaration even when phase 2 fails**

A real phase-2 failure does not waive a creating SubTx's declaration requirement. The ledger still returns SubMissingUTxODepositDeclaration for the undeclared deposit-backed own output; the rejected transaction applies no state changes.

<a id="ds-tx-presence-activity-creation-f06" name="ds-tx-presence-activity-creation-f06"></a>
<a id="ds-tx-presence-operations-allocation-f06" name="ds-tx-presence-operations-allocation-f06"></a>
<a id="ds-tx-required-declarations-operations-allocation-f06" name="ds-tx-required-declarations-operations-allocation-f06"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f06" name="ds-tx-declarations-requirements-operations-allocation-f06"></a>

**2.1.1.2.1.2.11 [F06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L161) - rejects a missing own declaration when spending a translated min-ADA output to create deposit-backed outputs**

> **A min-ADA source does not remove the declaration required by a new Store allocation.**

Build a Conway output and apply the production output upgrade to Dijkstra. Fund
that translated output through an accepted transaction, then consume its real
`TxIn` to create one to five generated outputs, including at least one deposit-backed
output. Its address, value and min-ADA form are preserved. The exact declaration
credits its historical reserve up to the ADA it contains.

```math
\begin{aligned}
\text{releasedDeposits(topTx)}&=0 \\
\text{allocatedDeposits(topTx)}&>0 \\
\neg\text{hasDeclaration(topTx)}
&\implies\text{RejectedWith(MissingUTxODepositDeclaration)}
\end{aligned}
```

Start with the signed control declaring the exact backing change. Remove only TopTx's declaration
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

**2.1.1.2.1.2.12 [N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L178) - SubTx outputs do not trigger TopTx allocation presence**

TopTx has no own outputs and no declaration. Its nested SubTx creates deposit-backed
outputs and explicitly declares zero. The isolated TopTx allocation-presence validator succeeds:
the child's outputs do not enter $`\text{createdDepositBackedOutputs(topTx)}`$.

This transaction is not established as acceptable. The child's explicit zero
triggers dependency, so the absent TopTx declaration fails that separate rule.
The child's amount is also outside this isolated check.

<a id="ds-tx-presence-activity-scope-n02" name="ds-tx-presence-activity-scope-n02"></a>
<a id="ds-tx-presence-operations-scope-n02" name="ds-tx-presence-operations-scope-n02"></a>
<a id="ds-tx-presence-operations-allocation-n07" name="ds-tx-presence-operations-allocation-n07"></a>
<a id="ds-tx-required-declarations-operations-allocation-n07" name="ds-tx-required-declarations-operations-allocation-n07"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n07" name="ds-tx-declarations-requirements-operations-allocation-n07"></a>

**2.1.1.2.1.2.13 [N07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L188) - Collateral return does not trigger allocation presence**

TopTx has a deposit-backed collateral return, no regular outputs and no declaration.
The isolated allocation-presence validator succeeds because collateral return is outside
$`\text{createdDepositBackedOutputs(topTx)}`$. Its independent collateral funding and
validity requirements still apply.

<a id="ds-tx-presence-activity-scope-n03" name="ds-tx-presence-activity-scope-n03"></a>
<a id="ds-tx-presence-operations-scope-n03" name="ds-tx-presence-operations-scope-n03"></a>
<a id="ds-tx-presence-operations-allocation-n08" name="ds-tx-presence-operations-allocation-n08"></a>
<a id="ds-tx-required-declarations-operations-allocation-n08" name="ds-tx-required-declarations-operations-allocation-n08"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n08" name="ds-tx-declarations-requirements-operations-allocation-n08"></a>

**2.1.1.2.1.2.14 [N08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L194) - Reference and collateral input identifiers do not trigger allocation presence**

Place the same arbitrary input identifier in both reference and collateral input
sets, with no regular outputs or declaration. The isolated allocation-presence validator
succeeds: neither field is a created output. The fixture does **not resolve the
identifier** or prove that it names a deposit-backed output or valid collateral.

<a id="ds-tx-presence-activity-scope-f01" name="ds-tx-presence-activity-scope-f01"></a>
<a id="ds-tx-presence-operations-scope-f01" name="ds-tx-presence-operations-scope-f01"></a>
<a id="ds-tx-presence-operations-allocation-f07" name="ds-tx-presence-operations-allocation-f07"></a>
<a id="ds-tx-required-declarations-operations-allocation-f07" name="ds-tx-required-declarations-operations-allocation-f07"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f07" name="ds-tx-declarations-requirements-operations-allocation-f07"></a>

**2.1.1.2.1.2.15 [F07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L200) - A SubTx declaration cannot satisfy TopTx allocation presence**

TopTx creates deposit-backed own outputs but declares nothing. Its nested SubTx
also creates deposit-backed outputs and explicitly declares zero. The child's
declaration cannot supply TopTx's field: the isolated TopTx allocation-presence validator
returns `MissingBodyUTxODepositDeclaration`.

<a id="ds-tx-presence-activity-scope-f02" name="ds-tx-presence-activity-scope-f02"></a>
<a id="ds-tx-presence-operations-scope-f02" name="ds-tx-presence-operations-scope-f02"></a>
<a id="ds-tx-presence-operations-allocation-f08" name="ds-tx-presence-operations-allocation-f08"></a>
<a id="ds-tx-required-declarations-operations-allocation-f08" name="ds-tx-required-declarations-operations-allocation-f08"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f08" name="ds-tx-declarations-requirements-operations-allocation-f08"></a>

**2.1.1.2.1.2.16 [F08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L212) - TopTx zero cannot satisfy its allocating SubTx's declaration requirement**

TopTx explicitly declares zero while its SubTx creates a deposit-backed output and
omits its own declaration. The ledger rejection must include
`SubMissingUTxODepositDeclaration`.

```math
\begin{aligned}
&\text{createdDepositBackedOutputs(subTx)}\ne\varnothing \\
&\land\ \neg\text{hasDeclaration(subTx)} \\
&\land\ \text{declaredNetDeposit(topTx)}=0 \\
&\implies\text{RejectedWith(SubMissingUTxODepositDeclaration)}
\end{aligned}
```

The parent's zero also fails exactness because a positive allocation is required.
This case requires the child's presence failure **among** the reported failures;
it does not start from an otherwise valid allocation control.

<a id="ds-tx-presence-activity-scope-n06" name="ds-tx-presence-activity-scope-n06"></a>
<a id="ds-tx-presence-operations-scope-n06" name="ds-tx-presence-operations-scope-n06"></a>
<a id="ds-tx-presence-operations-allocation-n09" name="ds-tx-presence-operations-allocation-n09"></a>
<a id="ds-tx-required-declarations-operations-allocation-n09" name="ds-tx-required-declarations-operations-allocation-n09"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n09" name="ds-tx-declarations-requirements-operations-allocation-n09"></a>

**2.1.1.2.1.2.17 [N09](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L223) - TopTx and SubTx allocate deposits, each with an exact declaration**

> **SubTx declares its own allocation; TopTx declares the complete transaction allocation.**

TopTx and exactly one SubTx each create one to five generated outputs, with at
least one deposit-backed output per body. Their output forms, positions and
application amounts vary independently. Both spend only min-ADA inputs, so
neither releases a recorded deposit.

```math
\begin{aligned}
\text{allocatedDeposits(topTx)}&>0 \\
\text{allocatedDeposits(subTx)}&>0 \\
\text{releasedDeposits(topTx)}&=\text{releasedDeposits(subTx)}=0 \\
\text{declaredNetDeposit(subTx)}&=\text{ownNetDeposit(subTx)} \\
\text{declaredNetDeposit(topTx)}
&=\text{ownNetDeposit(topTx)}+\text{ownNetDeposit(subTx)}
\end{aligned}
```

Price both output forms in each body and credit the historical backing of its inputs.
The child's min-ADA input funds its serialized outputs and external deposits.
TopTx supplies the remaining funding and the fee. The transaction with these exact declarations must be accepted.

<a id="ds-tx-presence-activity-spending" name="ds-tx-presence-activity-spending"></a>
<a id="ds-tx-presence-operations-release" name="ds-tx-presence-operations-release"></a>
<a id="ds-tx-required-declarations-operations-release" name="ds-tx-required-declarations-operations-release"></a>
<a id="ds-tx-declarations-requirements-operations-release" name="ds-tx-declarations-requirements-operations-release"></a>

**2.1.1.2.1.3 Release**

> **A body releasing a recorded Store deposit must declare its own deposit change.**

```math
\forall\,\text{body}:\quad
\text{depositBackedInputs(body)}\ne\varnothing
\implies\text{hasDeclaration(body)}
```

**Decision:** Agreed.

Apply the rule **independently to TopTx and every SubTx**, using each body's own
ordinary inputs resolved against the original UTxO. Reference inputs, collateral
inputs and a child's inputs do not count as this body's consumed outputs.

| Deposit-backed inputs | Own declaration | Declaration requirement result |
| --- | --- | --- |
| Present | Absent | **Reject:** missing declaration. |
| Present | Present | **Pass presence.** Acceptance still requires exact amounts, valid settlement and all other ledger rules. |
| Absent | Either | **No release-presence requirement.** [Allocation](#ds-tx-declarations-requirements-operations-allocation) or [SubTx declarations](#ds-tx-declarations-requirements-subtx-declarations) may still require a declaration. |

Equivalently:

```math
\text{releasePresenceValid(body)}
\iff \text{depositBackedInputs(body)}=\varnothing\lor\text{hasDeclaration(body)}
```

**Explicit zero counts as a declaration.** Its amount must still be correct.
The presence rule applies on both phase-2 outcomes. Each scenario below states
the proposed release, the declaration supplied or omitted, and the resulting
acceptance or rejection.

**Releasing a deposit** means consuming its deposit-backed UTxO in the proposed
ordinary transition. The released amount is the deposit recorded for that source;
newly created deposit-backed outputs require separate allocations.

The signed change also includes any increase or decrease in embedded reserves.
A body consuming a deposit-backed input may therefore declare an allocation, a
release or zero. TopTx declares the total across all bodies.

These cases specify **transaction acceptance or rejection**, including the required
missing-declaration failure. Reference-only access and collateral-only operations
are accepted without an ordinary declaration; a child's declaration cannot replace
its parent's required field. [Ledger effects](ledger-effects.md#ds-state) specifies the resulting
state transitions: [Execution](ledger-effects.md#ds-state-execution),
[Allocations](ledger-effects.md#ds-state-allocations) and [Balance](ledger-effects.md#ds-state-balance).

| Notation | Meaning |
| --- | --- |
| $`\text{body}`$ | TopTx or one of its SubTxs, considered separately. |
| $`\text{depositBackedInputs(body)}`$ | Its own ordinary inputs resolving to deposit-backed outputs in the original UTxO. |
| $`\text{hasDeclaration(body)}`$ | That body explicitly declares a change, including explicit zero. |
| $`\text{releasedDeposits(body)}`$ | Sum of recorded deposits of its consumed deposit-backed outputs, proposed for ordinary release. |
| $`\text{allocatedDeposits(body)}`$ | Sum of required deposits of its newly created deposit-backed outputs. |
| $`\text{declaredNetDeposit(body)}`$ | The signed declaration: allocation positive, release negative, explicit zero equal to 0. TopTx declares the transaction total. |

A declaration is required on **both phase-2 outcomes**, even when no new deposit-backed
output is created.

Acceptance cases satisfy all other ledger requirements, including exact amounts
and valid settlement. Rejection cases omit a releasing body's required declaration
while retaining its source inputs and proposed settlement. They state whether the
omission is supplied during preparation or applied to a prepared valid control.
Net change separately checks the declared amounts.

N01 covers a standalone TopTx with any generated output form; N02 specializes it
to **only min-ADA outputs**. Source outputs are created by accepted funding
transactions. Their allocations are read from the resulting ledger state, so a
release always has a funded, recorded deposit behind it.

Scenarios may also include unrelated deposit-backed outputs; their deposits are
excluded from the proposed release. No test inserts an invented allocation into
the live ledger.

<a id="ds-tx-presence-activity-spending-n01" name="ds-tx-presence-activity-spending-n01"></a>
<a id="ds-tx-presence-operations-release-n01" name="ds-tx-presence-operations-release-n01"></a>
<a id="ds-tx-required-declarations-operations-release-n01" name="ds-tx-required-declarations-operations-release-n01"></a>
<a id="ds-tx-declarations-requirements-operations-release-n01" name="ds-tx-declarations-requirements-operations-release-n01"></a>

**2.1.1.2.1.3.1 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L61) - Standalone TopTx, any output form**

**Scenario**

| Body | Consumes | Creates |
| --- | --- | --- |
| TopTx only: $`\text{subTxs}=\varnothing`$ | Deposit-backed outputs: $`\text{releasedDeposits}\gt 0`$ | Min-ADA outputs, deposit-backed outputs, or a mixture. |

Each generated proposal starts with **funded inputs and no TopTx declaration**.
Calculate its required net deposit, declare that amount, then build, sign and
submit the transaction. Preparation preserves the declaration supplied by the case.

**Calculation**

All amounts below belong to this TopTx. The two sums have separate scopes:

| Amount | Sum | Includes only |
| --- | --- | --- |
| $`\text{allocatedDeposits}`$ | $`\displaystyle\sum_{\text{newOutput}}\text{requiredDeposit(newOutput)}`$ | Newly created deposit-backed outputs. |
| $`\text{releasedDeposits}`$ | $`\displaystyle\sum_{\text{input}}\text{recordedDeposit(input)}`$ | Consumed deposit-backed inputs. |

New allocations use the [deposit calculation](domain-model.md#ds-pricing) with fixed protocol
parameters. Releases use the historical prices of the consumed deposit-backed
inputs. The release fixtures pair each new min-ADA output with a funded input of
equal embedded reserve. Embedded backing therefore cancels in the formulas below.

**Expected result**

Under this scenario, with all other ledger rules satisfied:

```math
\begin{gathered}
\text{declaredNetDeposit}=\text{allocatedDeposits}-\text{releasedDeposits} \\
\Downarrow \\
\text{Accepted}
\end{gathered}
```

**Examples** (illustrative totals in ADA):

| Allocate for new outputs | Release from consumed inputs | Exact net deposit | Required declaration |
| ---: | ---: | ---: | --- |
| 5 ₳ | 2 ₳ | $`5-2=+3`$ ₳ | Allocate **3 ₳**. |
| 2 ₳ | 2 ₳ | $`2-2=0`$ ₳ | Explicitly declare **zero**. |
| 0 ₳ | 2 ₳ | $`0-2=-2`$ ₳ | Release **2 ₳** into TopTx's own output 0. |

Fees and any additional allocation are funded separately. A release is accounted
for in its declared settlement output.

<a id="ds-tx-presence-activity-spending-n02" name="ds-tx-presence-activity-spending-n02"></a>
<a id="ds-tx-presence-operations-release-n02" name="ds-tx-presence-operations-release-n02"></a>
<a id="ds-tx-required-declarations-operations-release-n02" name="ds-tx-required-declarations-operations-release-n02"></a>
<a id="ds-tx-declarations-requirements-operations-release-n02" name="ds-tx-declarations-requirements-operations-release-n02"></a>

**2.1.1.2.1.3.2 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L84) - Standalone TopTx, only min-ADA outputs**

No new Store allocation is required ($`\text{allocatedDeposits}=0`$),
and the matched min-ADA reserves cancel, so TopTx declares a release of $`\text{releasedDeposits}`$ into its output 0.
The declaration carries the positive amount being released and represents
$`\text{netDeposit}=-\text{releasedDeposits}`$. Its SubTx declaration list is empty.
Build and sign that proposal, then require acceptance.

```math
\begin{aligned}
&\text{subTxs}=\varnothing \land \text{releasedDeposits}>0 \\
&\land\ \text{depositBackedOutputs}=\varnothing \\
&\land\ \text{declaredNetDeposit}=-\text{releasedDeposits} \\
&\implies \text{Accepted}
\end{aligned}
```

**Example:** fees are funded separately and no other charges or transfers apply.

```text
Existing deposit-backed output
├── Application ADA:       10 ₳
└── Deposit in the Store:   2 ₳ (recorded separately)

Proposed TopTx without SubTxs
├── Spends that output
├── Creates no deposit-backed outputs
├── Declares a release of 2 ₳
└── Creates a min-ADA settlement output containing 12 ₳
```

The proposed settlement output contains $`10 + 2 = 12`$ ₳, accounting for the
application ADA and the declared release. The otherwise valid transaction must
be accepted.

<a id="ds-tx-presence-activity-spending-n03" name="ds-tx-presence-activity-spending-n03"></a>
<a id="ds-tx-presence-operations-release-n03" name="ds-tx-presence-operations-release-n03"></a>
<a id="ds-tx-required-declarations-operations-release-n03" name="ds-tx-required-declarations-operations-release-n03"></a>
<a id="ds-tx-declarations-requirements-operations-release-n03" name="ds-tx-declarations-requirements-operations-release-n03"></a>

**2.1.1.2.1.3.3 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L98) - One SubTx releases its deposit into its own output**

TopTx has no Store operations of its own and declares the matching total. The SubTx
proposes to consume a deposit-backed output and create only min-ADA outputs,
so it declares the full recorded deposit as a release. The two declarations
account for **one proposed release**, assigned to the SubTx.

Fund the generated source first, then supply both declarations together from the
**same positive deposit recorded for that input**. The SubTx names its own output 0;
TopTx declares the matching total with `NoTopTxSettlement`. None of this release
is assigned to TopTx. Build and sign that declared proposal, then require acceptance.

The source's application ADA and the unrelated live outputs may vary. The recorded
deposit always comes from the funded ledger state.

```math
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{releasedDeposits(subTx)}>0 \land \text{allocatedDeposits(subTx)}=0 \\
&\land\ \text{declaredNetDeposit(topTx)}=\text{declaredNetDeposit(subTx)}
=-\text{releasedDeposits(subTx)} \\
&\implies \text{Accepted}
\end{aligned}
```

**Example:** the consumed output contains **10 ₳ of application ADA** and has a
recorded Store deposit of $`\text{deposit}`$. With fees funded separately, its proposed
min-ADA settlement output contains:

```math
\text{SubTx output coins} = 10\text{ ₳} + \text{deposit}
```

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

**2.1.1.2.1.3.4 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L110) - Standalone TopTx, release without its own declaration**

**Scenario**

Generate a standalone transaction consuming one to five deposit-backed outputs,
as in [N02](#ds-tx-declarations-requirements-operations-release-n02). Declare its exact total release
into TopTx's output 0, then build and sign it. Remove only TopTx's declaration and
re-sign. The proposed inputs and outputs remain unchanged.

| Body | Consumes | Creates | Declaration |
| --- | --- | --- | --- |
| TopTx, with no SubTxs | One or more deposit-backed outputs with recorded deposits. | Only min-ADA outputs; the settlement output includes the complete proposed release. | Absent. |

**Expected result**

```math
\begin{aligned}
&\text{subTxs}=\varnothing \\
&\land\ \text{releasedDeposits(topTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=0 \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\implies \text{Rejected}
\end{aligned}
```

Rejection must include `MissingUTxODepositDeclaration`.

**Why:** TopTx's own release requires its declaration. There are no SubTxs,
so [declaration dependency](#ds-tx-declarations-requirements-subtx-declarations) imposes no requirement.
Creating only min-ADA outputs also excludes allocation presence as the reason for
this missing-declaration failure.

Removing the declared release can additionally break accounting or value conservation.
Those failures do not replace the required release-presence failure.

<a id="ds-tx-presence-activity-spending-f02" name="ds-tx-presence-activity-spending-f02"></a>
<a id="ds-tx-presence-operations-release-f02" name="ds-tx-presence-operations-release-f02"></a>
<a id="ds-tx-required-declarations-operations-release-f02" name="ds-tx-required-declarations-operations-release-f02"></a>
<a id="ds-tx-declarations-requirements-operations-release-f02" name="ds-tx-declarations-requirements-operations-release-f02"></a>

**2.1.1.2.1.3.5 [F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L126) - SubTx release without its own declaration, despite TopTx declaring**

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
| Its single SubTx | Consumes a deposit-backed output and creates only min-ADA outputs, including its settlement output. | Absent. |

**Expected result**

```math
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{releasedDeposits(subTx)}>0 \\
&\land\ \text{releasedDeposits(topTx)}=0 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{allocatedDeposits(subTx)}=0 \\
&\land\ \text{declaredNetDeposit(topTx)}=-\text{releasedDeposits(subTx)} \\
&\land\ \neg\text{hasDeclaration(subTx)} \\
&\implies \text{Rejected}
\end{aligned}
```

Rejection must include `SubMissingUTxODepositDeclaration`. Additional accounting
failures may occur, but the missing declaration for its release must be reported.

**Why:** The SubTx's own release requires its own declaration. TopTx's declared
total cannot substitute for it. The parent declaration satisfies
[declaration dependency](#ds-tx-declarations-requirements-subtx-declarations); the missing field belongs
to the SubTx releasing deposits itself.

[SubTx declarations C02-N03](#ds-tx-declarations-requirements-subtx-declarations-c02-n03) accepts the same presence pattern
(TopTx present, SubTx absent) when there are **no Store operations**. Here the SubTx
spends a deposit-backed output, which introduces its own declaration requirement.

| Case | TopTx declaration | SubTx declaration | Source of the obligation |
| --- | --- | --- | --- |
| Release F01 | Absent. | No SubTx exists. | TopTx's own deposit-backed input. |
| Release F02 | Present. | Absent. | SubTx's own deposit-backed input. |
| [SubTx declarations C02-F01](#ds-tx-declarations-requirements-subtx-declarations-c02-f01) | Absent. | Explicit zero. | The SubTx declaration, even without Store operations. |

<a id="ds-tx-presence-activity-spending-n04" name="ds-tx-presence-activity-spending-n04"></a>
<a id="ds-tx-presence-operations-release-n04" name="ds-tx-presence-operations-release-n04"></a>
<a id="ds-tx-required-declarations-operations-release-n04" name="ds-tx-required-declarations-operations-release-n04"></a>
<a id="ds-tx-declarations-requirements-operations-release-n04" name="ds-tx-declarations-requirements-operations-release-n04"></a>

**2.1.1.2.1.3.6 [N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L139) - Phase 2 fails with valid declarations**

An otherwise valid release proposal remains acceptable when marked phase-2 invalid
and supplied with a script that fails.
For each generated single-source scenario, exercise both owners: a standalone
TopTx, then one SubTx releasing deposits whose parent has no Store operations of its own.
Both variants create only implicit ordinary outputs.

```math
\begin{aligned}
&\text{releasedDeposits(body)}>0 \\
&\land\ \text{declaredNetDeposit(topTx)}=\text{declaredNetDeposit(body)}
=-\text{releasedDeposits(body)} \\
&\land\ \text{phase1Valid}\land\text{phase2Result}=\text{Failed} \\
&\land\ \text{declaredPhase2}=\text{Invalid} \\
&\implies \text{Accepted}
\end{aligned}
```

Both the collateral inputs and the proposed return are implicit. This case checks
acceptance with the required ordinary declarations; the resulting collateral
transition belongs to [Execution](ledger-effects.md#ds-state-execution).

<a id="ds-tx-presence-activity-spending-f03" name="ds-tx-presence-activity-spending-f03"></a>
<a id="ds-tx-presence-operations-release-f03" name="ds-tx-presence-operations-release-f03"></a>
<a id="ds-tx-required-declarations-operations-release-f03" name="ds-tx-required-declarations-operations-release-f03"></a>
<a id="ds-tx-declarations-requirements-operations-release-f03" name="ds-tx-declarations-requirements-operations-release-f03"></a>

**2.1.1.2.1.3.7 [F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L154) - Missing release declaration in a phase-2-invalid proposal**

The transaction is rejected. TopTx's failures must include
`MissingUTxODepositDeclaration`; SubTx's must include
`SubMissingUTxODepositDeclaration`. Each case
removes only the declaration for its release from its N04 scenario. Every generated
single-source scenario exercises both release owners.

```math
\begin{aligned}
&\text{releasedDeposits(body)}>0\land\neg\text{hasDeclaration(body)} \\
&\land\ \text{phase2Script}=\text{AlwaysFails}\land\text{declaredPhase2}=\text{Invalid} \\
&\implies \text{Rejected}
\end{aligned}
```

A missing declaration rejects the proposal in phase 1. The failing script does
not exempt it from that check; the test does not require phase 2 to execute.

<a id="ds-tx-presence-activity-spending-n05" name="ds-tx-presence-activity-spending-n05"></a>
<a id="ds-tx-presence-operations-release-n05" name="ds-tx-presence-operations-release-n05"></a>
<a id="ds-tx-required-declarations-operations-release-n05" name="ds-tx-required-declarations-operations-release-n05"></a>
<a id="ds-tx-declarations-requirements-operations-release-n05" name="ds-tx-declarations-requirements-operations-release-n05"></a>

**2.1.1.2.1.3.8 [N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L180) - Several SubTxs release their deposits**

**Every SubTx releasing deposits declares its own release; TopTx declares their total.**
Generate two to five SubTxs with varying application ADA amounts. Each consumes
its own funded deposit-backed output and creates a min-ADA settlement output.
TopTx has no Store operations of its own and funds transaction fees separately.

All ordinary outputs are implicit, so no new Store allocation is required. Each
SubTx proposes its own settlement output containing its input's application ADA
plus the recorded deposit:

```math
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
```

TopTx uses `NoTopTxSettlement`: each release is assigned to its SubTx's own output 0.
The parent declaration accounts for those same releases once. With every releasing
body declared and the remaining rules satisfied, the transaction is accepted.

<a id="ds-tx-presence-activity-spending-f04" name="ds-tx-presence-activity-spending-f04"></a>
<a id="ds-tx-presence-operations-release-f04" name="ds-tx-presence-operations-release-f04"></a>
<a id="ds-tx-required-declarations-operations-release-f04" name="ds-tx-required-declarations-operations-release-f04"></a>
<a id="ds-tx-declarations-requirements-operations-release-f04" name="ds-tx-declarations-requirements-operations-release-f04"></a>

**2.1.1.2.1.3.9 [F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L198) - One SubTx releasing deposits omits its declaration**

**One undeclared SubTx releasing deposits rejects the entire transaction.** Starting from
N05's funded proposal, remove exactly one SubTx declaration and re-sign. Repeat
for every position in the actual SubTx sequence. TopTx keeps the exact total;
all other SubTxs keep their exact local declarations.

```text
declared, declared, absent, declared, …
                  └── its deposit-backed input still requires a declaration
```

For each $`\text{selectedSubTx}\in\text{subTxs}`$, submit a separate proposal:

```math
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
```

The parent's total and the other children's declarations cannot cover the
selected child's missing field. Additional accounting failures may occur;
the missing-declaration failure must still be present.

After trying every child position, submit the unchanged, fully declared control.
It must be accepted.

<a id="ds-tx-presence-activity-spending-n06" name="ds-tx-presence-activity-spending-n06"></a>
<a id="ds-tx-presence-operations-release-n06" name="ds-tx-presence-operations-release-n06"></a>
<a id="ds-tx-required-declarations-operations-release-n06" name="ds-tx-required-declarations-operations-release-n06"></a>
<a id="ds-tx-declarations-requirements-operations-release-n06" name="ds-tx-declarations-requirements-operations-release-n06"></a>

**2.1.1.2.1.3.10 [N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L222) - Only some SubTxs release Store deposits**

**A SubTx releasing deposits does not impose its declaration requirement on its siblings.**
Mix SubTxs consuming deposit-backed outputs with SubTxs consuming only min-ADA
outputs, varying their positions. Both groups are nonempty; all created outputs
are implicit. The latter group has no Store operations and omits its declarations.

```math
\begin{aligned}
\text{releasingSubTxs} &= \{\text{subTx}\in\text{subTxs}\mid\text{depositBackedInputs(subTx)}\ne\varnothing\} \\
\text{implicitOnlySubTxs} &= \text{subTxs}\setminus\text{releasingSubTxs}
\end{aligned}
```

| SubTx group | Own declaration | Own settlement |
| --- | --- | --- |
| $`\text{releasingSubTxs}`$ | Exact release of its recorded deposit. | Application ADA plus its released deposit. |
| $`\text{implicitOnlySubTxs}`$ | Absent. | Its application ADA, with no Store transfer. |

```math
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
```

TopTx has no Store operations of its own and declares the exact total with
`NoTopTxSettlement`. The transaction must be accepted: declaration presence is
checked per body, and the inactive siblings need no declaration merely because
another SubTx proposes a release.

<a id="ds-tx-presence-activity-spending-n07" name="ds-tx-presence-activity-spending-n07"></a>
<a id="ds-tx-presence-operations-release-n07" name="ds-tx-presence-operations-release-n07"></a>
<a id="ds-tx-required-declarations-operations-release-n07" name="ds-tx-required-declarations-operations-release-n07"></a>
<a id="ds-tx-declarations-requirements-operations-release-n07" name="ds-tx-declarations-requirements-operations-release-n07"></a>

**2.1.1.2.1.3.11 [N07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L243) - TopTx and several SubTxs release deposits**

**TopTx can release its own deposit while its SubTxs release theirs locally.**
TopTx and each of at least two SubTxs propose to consume their own deposit-backed
outputs. All proposed outputs are implicit; each body assigns its own release
to its own settlement output. Fees are funded separately.

```math
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
```

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

**2.1.1.2.1.3.12 [N08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L261) - Phase 2 fails with several proposed SubTx releases**

**Valid declarations remain required on the phase-2 failure path.**
Prepare the several-SubTx releases from N05, add a genuinely failing Plutus V4
script, and mark the transaction phase-2 invalid. TopTx and every SubTx retain
their exact declarations and settlement outputs. The ordinary proposal remains
fully funded.

```math
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
```

The transaction must be accepted. Separate min-ADA collateral and a min-ADA
return provide a valid failure-path proposal. Its ledger effects belong to
[Execution](ledger-effects.md#ds-state-execution).

<a id="ds-tx-presence-activity-spending-f05" name="ds-tx-presence-activity-spending-f05"></a>
<a id="ds-tx-presence-operations-release-f05" name="ds-tx-presence-operations-release-f05"></a>
<a id="ds-tx-required-declarations-operations-release-f05" name="ds-tx-required-declarations-operations-release-f05"></a>
<a id="ds-tx-declarations-requirements-operations-release-f05" name="ds-tx-declarations-requirements-operations-release-f05"></a>

**2.1.1.2.1.3.13 [F05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L279) - One SubTx declaration is missing in a phase-2-invalid proposal**

**A phase-2-invalid proposal still needs every active body's declaration.**
From N08's prepared transaction, remove exactly one SubTx declaration and re-sign.
Repeat for every position, retaining TopTx's total, every other declaration, the
failing script and the phase-2-invalid flag.

For each $`\text{selectedSubTx}\in\text{subTxs}`$, submit a separate proposal:

```math
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
```

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

**2.1.1.2.1.3.14 [N09](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L303) - Standalone TopTx, reference-only Store access**

> **Referencing a Deposit-backed output does not release its deposit.**

Fund one to five Deposit-backed outputs and their positive allocations through a
real ledger transaction. TopTx references those live outputs without consuming
them. Its ordinary inputs and outputs are implicit, and it has no SubTxs.

```math
\begin{aligned}
\text{depositBackedReferenceInputs(topTx)}&\ne\varnothing \\
\text{ordinaryDepositBackedInputs(topTx)}&=\varnothing \\
\text{createdDepositBackedOutputs(topTx)}&=\varnothing \\
\neg\text{hasDeclaration(topTx)}&\implies\text{Accepted}
\end{aligned}
```

Fees and witnesses are supplied while preserving the references and absent
declaration. The accepted submission establishes that these real Store records
do not require an ordinary release declaration.

<a id="ds-tx-presence-activity-scope-n05" name="ds-tx-presence-activity-scope-n05"></a>
<a id="ds-tx-presence-operations-scope-n05" name="ds-tx-presence-operations-scope-n05"></a>
<a id="ds-tx-presence-operations-release-n10" name="ds-tx-presence-operations-release-n10"></a>
<a id="ds-tx-required-declarations-operations-release-n10" name="ds-tx-required-declarations-operations-release-n10"></a>
<a id="ds-tx-declarations-requirements-operations-release-n10" name="ds-tx-declarations-requirements-operations-release-n10"></a>

**2.1.1.2.1.3.15 [N10](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L312) - Standalone TopTx, collateral-only Store operations**

> **Collateral has its own Store accounting; it does not require an ordinary declaration.**

Each generated pair of application amounts exercises all three placements:

| Collateral input | Collateral return |
| --- | --- |
| Deposit-backed | Implicit |
| Implicit | Deposit-backed |
| Deposit-backed | Deposit-backed |

Fund the input on the real ledger and supply sufficient collateral coins for the
return, any additional return deposit, and the minimum fee. Every placement runs
with a real successful script and a real failing script, with the corresponding
phase-2 validity flag.

```math
\begin{aligned}
\text{subTxs}&=\varnothing \\
\text{ordinaryDepositBackedInputs(topTx)}&=\varnothing \\
\text{createdDepositBackedOutputs(topTx)}&=\varnothing \\
\neg\text{hasDeclaration(topTx)}&\implies\text{Accepted}
\end{aligned}
```

All ordinary inputs and outputs are implicit. The declaration remains absent on
both paths. Collateral Store operations execute only on the accepted phase-2
failure path; the ordinary declaration requirement remains unchanged.

<a id="ds-tx-presence-activity-scope-f03" name="ds-tx-presence-activity-scope-f03"></a>
<a id="ds-tx-presence-operations-scope-f03" name="ds-tx-presence-operations-scope-f03"></a>
<a id="ds-tx-presence-operations-release-f06" name="ds-tx-presence-operations-release-f06"></a>
<a id="ds-tx-required-declarations-operations-release-f06" name="ds-tx-required-declarations-operations-release-f06"></a>
<a id="ds-tx-declarations-requirements-operations-release-f06" name="ds-tx-declarations-requirements-operations-release-f06"></a>

**2.1.1.2.1.3.16 [F06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L321) - A SubTx declaration cannot satisfy TopTx release presence**

> **A child's declaration cannot supply its releasing parent's field.**

TopTx and two to five SubTxs each consume a funded Deposit-backed output and create
a min-ADA settlement output. Each child declares its own release; TopTx declares
the combined release. Begin with this signed, otherwise valid control, then remove
only TopTx's declaration and re-sign.

```math
\begin{aligned}
&\text{releasedDeposits(topTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=0 \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}:\ \text{hasDeclaration(subTx)} \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\implies\text{RejectedWith(MissingUTxODepositDeclaration)}
\end{aligned}
```

The failure must identify TopTx's **own release requirement**. The separate
SubTx-to-TopTx dependency may also fail, but `MissingTopTxUTxODepositDeclaration`
alone is insufficient here. Finally, submit the unchanged declared control and
require acceptance.

<a id="ds-tx-presence-operations-zero-net-change" name="ds-tx-presence-operations-zero-net-change"></a>
<a id="ds-tx-required-declarations-operations-zero-net-change" name="ds-tx-required-declarations-operations-zero-net-change"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change" name="ds-tx-declarations-requirements-operations-zero-net-change"></a>

**2.1.1.2.1.4 Zero net change**

> **A body with Store operations and equal total input and output backing declares zero.**
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

```math
\begin{aligned}
\forall\,\text{body}\in\text{activeBodies}:\quad
\text{allocatedDeposits(body)} &= \text{releasedDeposits(body)}>0 \\
\forall\,\text{body}\in\text{inactiveBodies}:\quad
\text{allocatedDeposits(body)} &= \text{releasedDeposits(body)}=0 \\
\text{activeSubTxs} &= \{\text{subTx}\in\text{subTxs}\mid\text{releasedDeposits(subTx)}>0\}
\end{aligned}
```

These fixtures also preserve each body's embedded reserves, making the signed
backing change zero. Equality is checked independently for every active body. A zero batch total
alone is insufficient: every active body releases a positive deposit and
allocates the same amount itself. Inactive bodies consume and create only
min-ADA outputs. The active and inactive bodies partition TopTx and its actual
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
output, including the min-ADA input/output pair of an inactive child. An
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

**2.1.1.2.1.4.1 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L42) - Standalone TopTx, equal allocations and releases with explicit zero**

```math
\begin{aligned}
&\text{subTxs}=\varnothing \\
&\land\ \text{allocatedDeposits}=\text{releasedDeposits}>0 \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\implies\text{Accepted}
\end{aligned}
```

Explicit zero describes the exact net change. The ledger accepts the transaction
even though both gross Store operations are nonzero.

<a id="ds-tx-presence-operations-zero-net-change-f01" name="ds-tx-presence-operations-zero-net-change-f01"></a>
<a id="ds-tx-required-declarations-operations-zero-net-change-f01" name="ds-tx-required-declarations-operations-zero-net-change-f01"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f01" name="ds-tx-declarations-requirements-operations-zero-net-change-f01"></a>

**2.1.1.2.1.4.2 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L53) - Standalone TopTx, equal allocations and releases without a declaration**

```math
\begin{aligned}
&\text{subTxs}=\varnothing \\
&\land\ \text{allocatedDeposits}=\text{releasedDeposits}>0 \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{MissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
```

Remove only the declaration from an otherwise valid explicit-zero transaction
and re-sign it. The ledger rejects the undeclared version; the original declared
control is accepted. The zero net amount cannot stand in for the required field.

This requirement comes from TopTx's **own operations**. N01 and F01 contain no
SubTxs. The following cases extend the same per-body requirement to batches;
[TopTx accounting](#ds-tx-accounting-net-change-toptx) checks the arithmetic of the total declaration.

<a id="ds-tx-required-declarations-operations-zero-net-change-n02" name="ds-tx-required-declarations-operations-zero-net-change-n02"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n02" name="ds-tx-declarations-requirements-operations-zero-net-change-n02"></a>

**2.1.1.2.1.4.3 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L72) - One SubTx replaces its deposit with explicit zero**

One SubTx consumes a funded deposit-backed output and proposes an identical
replacement. TopTx has no own Store operations. Both bodies explicitly declare
zero: the child acknowledges its own operations, and TopTx acknowledges the
child's declaration and the zero batch amount.

```math
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \text{declaration(subTx)}=\text{ExplicitZero} \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\implies\text{Accepted}
\end{aligned}
```

<a id="ds-tx-required-declarations-operations-zero-net-change-f02" name="ds-tx-required-declarations-operations-zero-net-change-f02"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f02" name="ds-tx-declarations-requirements-operations-zero-net-change-f02"></a>

**2.1.1.2.1.4.4 [F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L83) - One active SubTx omits its declaration**

Remove only the child's declaration from N02's prepared transaction, retaining
TopTx's explicit zero. The child still proposes both gross operations.

```math
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \neg\text{hasDeclaration(subTx)} \\
&\land\ \text{declaration(topTx)}=\text{ExplicitZero} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{SubMissingUTxODepositDeclaration}\in\text{failures}
\end{aligned}
```

TopTx's zero cannot satisfy the child's own requirement. After rejecting the
variant, submit the original control with both declarations; it must be accepted.

<a id="ds-tx-required-declarations-operations-zero-net-change-f03" name="ds-tx-required-declarations-operations-zero-net-change-f03"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f03" name="ds-tx-declarations-requirements-operations-zero-net-change-f03"></a>

**2.1.1.2.1.4.5 [F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L98) - TopTx omits the declaration required by its child**

Remove only TopTx's declaration from N02's prepared transaction. The child's
explicit zero remains present, and TopTx still has no Store operations of its own.

```math
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\} \\
&\land\ \text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \text{declaration(subTx)}=\text{ExplicitZero} \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\implies\text{Rejected} \\
&\qquad\land\ \text{MissingTopTxUTxODepositDeclaration}\in\text{failures}
\end{aligned}
```

The required failure identifies the parent declaration required by an explicit
SubTx declaration. The original control with both zeros must be accepted.

<a id="ds-tx-required-declarations-operations-zero-net-change-n03" name="ds-tx-required-declarations-operations-zero-net-change-n03"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n03" name="ds-tx-declarations-requirements-operations-zero-net-change-n03"></a>

**2.1.1.2.1.4.6 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L112) - Several SubTxs each replace their deposits**

Generate two to five SubTxs. Each consumes its own funded deposit-backed output
and proposes its own copied replacement, so each child's positive allocation
equals its own recorded release. TopTx has no own Store operations; all bodies
explicitly declare zero.

```math
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \text{allocatedDeposits(topTx)}=\text{releasedDeposits(topTx)}=0 \\
&\land\ \forall\,\text{subTx}\in\text{subTxs}: \\
&\qquad\text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)}>0 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{declaration(body)}=\text{ExplicitZero} \\
&\implies\text{Accepted}
\end{aligned}
```

<a id="ds-tx-required-declarations-operations-zero-net-change-f04" name="ds-tx-required-declarations-operations-zero-net-change-f04"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f04" name="ds-tx-declarations-requirements-operations-zero-net-change-f04"></a>

**2.1.1.2.1.4.7 [F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L123) - One of several active SubTxs omits its declaration**

From N03's prepared transaction, remove each child's declaration in turn. Each
variant changes exactly one field; TopTx and every sibling retain explicit zero.
For every selected child $`\text{omittedSubTx}\in\text{subTxs}`$, submit a separate proposal:

```math
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
```

After every child position has been rejected, submit the original fully declared
control. It must be accepted.

<a id="ds-tx-required-declarations-operations-zero-net-change-n04" name="ds-tx-required-declarations-operations-zero-net-change-n04"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n04" name="ds-tx-declarations-requirements-operations-zero-net-change-n04"></a>

**2.1.1.2.1.4.8 [N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L138) - Only some SubTxs replace Store deposits**

Generate two to five SubTxs with a nonempty proper subset of active children,
varying their positions. Determine that subset from their inputs' recorded
deposits. Each active child replaces a positive Store deposit and declares zero.
Every remaining child consumes and replaces a min-ADA output, with zero
allocation and release and no declaration. TopTx has no own Store operations
and explicitly declares zero.

```math
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
```

The active siblings impose no declaration requirement on an inactive child.

<a id="ds-tx-required-declarations-operations-zero-net-change-f05" name="ds-tx-required-declarations-operations-zero-net-change-f05"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f05" name="ds-tx-declarations-requirements-operations-zero-net-change-f05"></a>

**2.1.1.2.1.4.9 [F05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L153) - One active SubTx omits its declaration among inactive siblings**

From N04's prepared transaction, remove each active child's declaration
separately. TopTx and the other active children retain zero; inactive siblings
keep their fields absent. For every selected active child $`\text{omittedSubTx}\in\text{activeSubTxs}`$:

```math
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
```

Only active positions are mutated. Once every such variant has been rejected,
the original control must be accepted with its inactive declarations still absent.

<a id="ds-tx-required-declarations-operations-zero-net-change-n05" name="ds-tx-required-declarations-operations-zero-net-change-n05"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n05" name="ds-tx-declarations-requirements-operations-zero-net-change-n05"></a>

**2.1.1.2.1.4.10 [N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L172) - TopTx and several SubTxs each replace their deposits**

TopTx and each of two to five children consume their own funded deposit-backed
source and propose a copied replacement. Every body independently has equal
positive allocations and releases. All declare explicit zero.

```math
\begin{aligned}
&2\le |\text{subTxs}|\le5 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{allocatedDeposits(body)}=\text{releasedDeposits(body)}>0 \\
&\land\ \forall\,\text{body}\in\{\text{topTx}\}\cup\text{subTxs}: \\
&\qquad\text{declaration(body)}=\text{ExplicitZero} \\
&\implies\text{Accepted}
\end{aligned}
```

TopTx's explicit zero satisfies both its own operations requirement and the
requirement arising from its children's declarations.

<a id="ds-tx-required-declarations-operations-zero-net-change-f06" name="ds-tx-required-declarations-operations-zero-net-change-f06"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f06" name="ds-tx-declarations-requirements-operations-zero-net-change-f06"></a>

**2.1.1.2.1.4.11 [F06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L183) - Active TopTx omits its own declaration**

Remove only TopTx's declaration from N05's prepared transaction. Every child
retains its explicit zero, while TopTx still proposes its own positive gross
allocation and release.

```math
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
```

The required failure comes from TopTx's own Store operations. The child-to-parent
declaration rule may also fail, but that alone does not prove the own-operations
requirement. The original fully declared control must be accepted.

<a id="ds-tx-required-declarations-operations-zero-net-change-n06" name="ds-tx-required-declarations-operations-zero-net-change-n06"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n06" name="ds-tx-declarations-requirements-operations-zero-net-change-n06"></a>

**2.1.1.2.1.4.12 [N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L198) - Phase 2 fails with explicit zero at every active body**

Use N05's active TopTx and two to five active children, with explicit zero at
every body. Add an actually failing Plutus V4 script owned by TopTx, provide
proper collateral, and mark the transaction phase-2 invalid. The proposed
ordinary operations remain fully funded and satisfy the same per-body equality.

```math
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
```

Acceptance exercises the phase-2 failure path with all declarations present.
Store effects belong to [Execution](ledger-effects.md#ds-state-execution).

<a id="ds-tx-required-declarations-operations-zero-net-change-f07" name="ds-tx-required-declarations-operations-zero-net-change-f07"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f07" name="ds-tx-declarations-requirements-operations-zero-net-change-f07"></a>

**2.1.1.2.1.4.13 [F07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L210) - One SubTx declaration is missing in a phase-2-invalid proposal**

From N06's prepared transaction, remove each child's declaration in turn,
retaining TopTx's and every sibling's zero. Keep the failing V4 script,
collateral and phase-2-invalid declaration. For each selected child $`\text{omittedSubTx}\in\text{subTxs}`$:

```math
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
```

Every mutation must be rejected in phase 1; the failing script does not exempt
the child from declaring. The rejection does not require phase 2 to execute.
After testing every child, the original fully declared control must be accepted
on the phase-2 failure path.

<a id="ds-tx-required-declarations-operations-zero-net-change-f08" name="ds-tx-required-declarations-operations-zero-net-change-f08"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f08" name="ds-tx-declarations-requirements-operations-zero-net-change-f08"></a>

**2.1.1.2.1.4.14 [F08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L226) - TopTx's own declaration is missing in a phase-2-invalid proposal**

Remove only TopTx's declaration from N06's prepared transaction, retaining
every child's zero, the failing V4 script, collateral and invalidity declaration.

```math
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
```

TopTx's own operations must produce `MissingUTxODepositDeclaration`, even if the
child-to-parent dependency also fails. The proposal is rejected in phase 1;
phase 2 need not execute. The original fully declared control must be accepted
on the phase-2 failure path.

<a id="ds-tx-presence-dependency" name="ds-tx-presence-dependency"></a>
<a id="ds-tx-presence-subtx-declarations" name="ds-tx-presence-subtx-declarations"></a>
<a id="ds-tx-required-declarations-subtx-declarations" name="ds-tx-required-declarations-subtx-declarations"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations" name="ds-tx-declarations-requirements-subtx-declarations"></a>

##### 2.1.1.2.2 SubTx declarations

> **A SubTx declaration requires a TopTx declaration.**
>
> Any explicit SubTx form, including zero, requires TopTx's field even without
> TopTx's own Store operations. The amount is checked separately.

**Decision:** Agreed.

**Executable spec:** [SubTxDeclarationsSpec.hs](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs)

Categories, case identifiers and order match the executable spec. Short titles
introduce the cases; source links lead to their checks. Each linked test ID
completes its category tag: `N` for nominal cases, `F` for failures, and `P` for the
universal rule. Numbering restarts in each category.

**Reading the outcomes:** $`\mathsf{TopTxRequirementSatisfied}`$ and $`\mathsf{MissingRequiredTopTxDeclaration}`$ concern only
declaration presence. $`\mathsf{Accepted}`$ and $`\mathsf{Rejected}`$ describe submission
of the prepared transaction to the ledger. Exact amounts and Store accounting are
covered by DS-TX-ACCOUNTING-NET-CHANGE-TOPTX and DS-TX-ACCOUNTING-NET-CHANGE-SUBTX.

<a id="ds-tx-presence-dependency-c01" name="ds-tx-presence-dependency-c01"></a>
<a id="ds-tx-presence-subtx-declarations-c01" name="ds-tx-presence-subtx-declarations-c01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c01" name="ds-tx-required-declarations-subtx-declarations-c01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c01" name="ds-tx-declarations-requirements-subtx-declarations-c01"></a>

**2.1.1.2.2.1 TopTx requirement**

> **A declaring SubTx requires TopTx to declare.**
>
> SubTx declaration $`\implies`$ TopTx declaration; the converse is not required.

$`\mathrm{hasDeclaration}(\mathit{body})`$ means that the body explicitly declares
a UTxO capacity deposit change; $`\mathrm{subTransactions}(\mathit{topTx})`$ is its
sequence of SubTxs.

```math
\begin{aligned}
&\left(\exists \mathit{subTx}\in\mathrm{subTransactions}(\mathit{topTx}):
\mathrm{hasDeclaration}(\mathit{subTx})\right) \\
&\qquad\implies\mathrm{hasDeclaration}(\mathit{topTx})
\end{aligned}
```

If every SubTx omits its declaration, DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS imposes no requirement on TopTx.
DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS may still require a declaration for TopTx's own Store operations.

<a id="ds-tx-presence-dependency-c01-p01" name="ds-tx-presence-dependency-c01-p01"></a>
<a id="ds-tx-presence-subtx-declarations-c01-p01" name="ds-tx-presence-subtx-declarations-c01-p01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c01-p01" name="ds-tx-required-declarations-subtx-declarations-c01-p01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c01-p01" name="ds-tx-declarations-requirements-subtx-declarations-c01-p01"></a>

**2.1.1.2.2.1.1 [P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L61) - SubTx declarations require TopTx's declaration**

Let $`\mathrm{missingRequiredTopTxDeclaration}(\mathit{topTx})`$ mean that the isolated validator
reports `MissingTopTxDeclaration`.

```math
\begin{aligned}
\mathrm{missingRequiredTopTxDeclaration}(\mathit{topTx})
\iff\bigl(&\neg\mathrm{hasDeclaration}(\mathit{topTx}) \\
&\land\exists \mathit{subTx}\in\mathrm{subTransactions}(\mathit{topTx}): \\
&\qquad\mathrm{hasDeclaration}(\mathit{subTx})\bigr)
\end{aligned}
```

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
> Absent $`\ne`$ Explicit zero. A SubTx's explicit zero requires TopTx to declare; absence alone does not.

**Situation:** TopTx and its single SubTx consume and create only min-ADA
outputs. There is no Store allocation or release. Each case submits a funded,
phase-2-valid transaction whose other ledger requirements are satisfied.

| TopTx declaration ↓ / SubTx declaration → | Absent | Explicit zero |
| --- | --- | --- |
| **Absent** | ✓ Accepted · N01 | ✗ Rejected · F01 |
| **Explicit zero** | ✓ Accepted · N03 | ✓ Accepted · N02 |

$`\mathsf{Absent}`$ means no declaration; $`\mathsf{ExplicitZero}`$ acknowledges a zero net
change. An explicit-zero SubTx still requires TopTx's declaration:

```math
\mathrm{declaresZero}(\mathit{body})
\implies\mathrm{hasDeclaration}(\mathit{body})
```

<a id="ds-tx-presence-dependency-c02-n01" name="ds-tx-presence-dependency-c02-n01"></a>
<a id="ds-tx-presence-subtx-declarations-c02-n01" name="ds-tx-presence-subtx-declarations-c02-n01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c02-n01" name="ds-tx-required-declarations-subtx-declarations-c02-n01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c02-n01" name="ds-tx-declarations-requirements-subtx-declarations-c02-n01"></a>

**2.1.1.2.2.2.1 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L66) - accepts absent declarations at both levels**

```math
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\rbrace
\implies \mathsf{Accepted}
```

**Why:** With no Store operations and no SubTx declaration, neither body needs to declare.

<a id="ds-tx-presence-dependency-c02-n02" name="ds-tx-presence-dependency-c02-n02"></a>
<a id="ds-tx-presence-subtx-declarations-c02-n02" name="ds-tx-presence-subtx-declarations-c02-n02"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c02-n02" name="ds-tx-required-declarations-subtx-declarations-c02-n02"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c02-n02" name="ds-tx-declarations-requirements-subtx-declarations-c02-n02"></a>

**2.1.1.2.2.2.2 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L70) - accepts explicit zero at both levels**

```math
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies \mathsf{Accepted}
```

**Why:** The SubTx explicitly declares zero, and TopTx supplies the declaration it requires.

<a id="ds-tx-presence-dependency-c02-n03" name="ds-tx-presence-dependency-c02-n03"></a>
<a id="ds-tx-presence-subtx-declarations-c02-n03" name="ds-tx-presence-subtx-declarations-c02-n03"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c02-n03" name="ds-tx-required-declarations-subtx-declarations-c02-n03"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c02-n03" name="ds-tx-declarations-requirements-subtx-declarations-c02-n03"></a>

**2.1.1.2.2.2.3 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L74) - accepts TopTx zero without a SubTx declaration**

```math
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero} \\
\mathit{subTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\rbrace
\implies \mathsf{Accepted}
```

**Why:** TopTx may declare independently; its declaration creates no obligation for the SubTx.

<a id="ds-tx-presence-dependency-c02-f01" name="ds-tx-presence-dependency-c02-f01"></a>
<a id="ds-tx-presence-subtx-declarations-c02-f01" name="ds-tx-presence-subtx-declarations-c02-f01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c02-f01" name="ds-tx-required-declarations-subtx-declarations-c02-f01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c02-f01" name="ds-tx-declarations-requirements-subtx-declarations-c02-f01"></a>

**2.1.1.2.2.2.4 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L78) - rejects SubTx zero without a TopTx declaration**

```math
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies \mathsf{Rejected}
```

**Why:** Explicit zero is still a declaration, so the SubTx requires TopTx to declare.

**Expected failure:** `MissingTopTxUTxODepositDeclaration`.

**State invariant:**

```math
\mathit{ledgerStateAfterRejectedSubmit}=\mathit{ledgerStateBeforeSubmit}
```

The comparison starts immediately before submission, after funding and preparation.

<a id="ds-tx-presence-dependency-c03" name="ds-tx-presence-dependency-c03"></a>
<a id="ds-tx-presence-subtx-declarations-c03" name="ds-tx-presence-subtx-declarations-c03"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c03" name="ds-tx-required-declarations-subtx-declarations-c03"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c03" name="ds-tx-declarations-requirements-subtx-declarations-c03"></a>

**2.1.1.2.2.3 Offsetting SubTx contributions**

> **Preserve declaration responsibility when amounts cancel.**
>
> Two SubTx contributions $`+\text{amount}`$ and $`-\text{amount}`$ sum to zero; both declarations still
> require TopTx to declare.

**Situation:** Two SubTxs declare local operations using the same generated strictly
positive amount: one declares an allocation, the other declares a release to output
index zero. Their declared contributions cancel; TopTx has no contribution of its
own. The requirement comes from **two explicit SubTx declarations**.
[Zero net change](#ds-tx-declarations-requirements-operations-zero-net-change) instead exercises a
TopTx or SubTx whose own gross allocations and releases are equal and positive,
including batches where every active body independently has zero net change.

```math
\begin{aligned}
&\sum_{\mathit{subTx}\in\mathrm{subTransactions}(\mathit{topTx})}
\mathrm{declaredSubTxNetUTxODepositChange}(\mathit{subTx}) \\
&\qquad=\mathit{declaredAmount}-\mathit{declaredAmount}=0
\end{aligned}
```

These properties validate declarations directly. They do not fund operations, construct
a settlement output or exercise a Store transfer. In the formulas below,
$`\mathit{declaredAmount}\in\mathsf{StrictlyPositiveCoin}`$.

<a id="ds-tx-presence-dependency-c03-n01" name="ds-tx-presence-dependency-c03-n01"></a>
<a id="ds-tx-presence-subtx-declarations-c03-n01" name="ds-tx-presence-subtx-declarations-c03-n01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c03-n01" name="ds-tx-required-declarations-subtx-declarations-c03-n01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c03-n01" name="ds-tx-declarations-requirements-subtx-declarations-c03-n01"></a>

**2.1.1.2.2.3.1 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L86) - passes declaration presence with TopTx declaring the zero net amount**

```math
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
```

**Why:** A zero net amount can be acknowledged explicitly. TopTx's zero declaration fulfils the
presence requirement for the two declaring SubTxs.

<a id="ds-tx-presence-dependency-c03-f01" name="ds-tx-presence-dependency-c03-f01"></a>
<a id="ds-tx-presence-subtx-declarations-c03-f01" name="ds-tx-presence-subtx-declarations-c03-f01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c03-f01" name="ds-tx-required-declarations-subtx-declarations-c03-f01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c03-f01" name="ds-tx-declarations-requirements-subtx-declarations-c03-f01"></a>

**2.1.1.2.2.3.2 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L89) - rejects an absent TopTx declaration despite the zero net amount**

```math
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
```

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
> Local or delegated accounting $`\implies`$ the same TopTx declaration requirement.

**Situation:** Each generated sample provides all five explicit SubTx declaration
forms, using a strictly positive amount and a settlement output index where needed.
Call this collection $`\mathit{explicitSubTxDeclarations}`$:

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

**2.1.1.2.2.4.1 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L94) - passes declaration presence with TopTx zero for every explicit SubTx form**

```math
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
```

**Why:** Every explicit SubTx form finds the TopTx declaration it requires, regardless of where
the operation is accounted for.

<a id="ds-tx-presence-dependency-c04-f01" name="ds-tx-presence-dependency-c04-f01"></a>
<a id="ds-tx-presence-subtx-declarations-c04-f01" name="ds-tx-presence-subtx-declarations-c04-f01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c04-f01" name="ds-tx-required-declarations-subtx-declarations-c04-f01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c04-f01" name="ds-tx-declarations-requirements-subtx-declarations-c04-f01"></a>

**2.1.1.2.2.4.2 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L100) - rejects an absent TopTx declaration for every explicit SubTx form**

```math
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
```

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

**2.1.1.2.2.5.1 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L109) - accepts zero declarations at both levels on the phase-2 failure path**

```math
\left.
\begin{aligned}
\mathit{phase2Status} &= \mathsf{Invalid} \\
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies \mathsf{Accepted}
```

**Why:** TopTx supplies the declaration required by its SubTx. The prepared transaction is accepted
on the phase-2 failure path, even though its script fails.

<a id="ds-tx-presence-dependency-c05-f01" name="ds-tx-presence-dependency-c05-f01"></a>
<a id="ds-tx-presence-subtx-declarations-c05-f01" name="ds-tx-presence-subtx-declarations-c05-f01"></a>
<a id="ds-tx-required-declarations-subtx-declarations-c05-f01" name="ds-tx-required-declarations-subtx-declarations-c05-f01"></a>
<a id="ds-tx-declarations-requirements-subtx-declarations-c05-f01" name="ds-tx-declarations-requirements-subtx-declarations-c05-f01"></a>

**2.1.1.2.2.5.2 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L113) - rejects SubTx zero without a TopTx declaration on the phase-2 failure path**

```math
\left.
\begin{aligned}
\mathit{phase2Status} &= \mathsf{Invalid} \\
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies \mathsf{Rejected}
```

**Why:** Marking the transaction phase-2 invalid does not waive the TopTx declaration
required by its SubTx.

**Expected failure:** `MissingTopTxUTxODepositDeclaration`.

**State invariant:**

```math
\mathit{ledgerStateAfterRejectedSubmit}=\mathit{ledgerStateBeforeSubmit}
```

The comparison starts immediately before submission, after funding and preparation.

<a id="ds-tx-accounting" name="ds-tx-accounting"></a>

### 2.1.2 Accounting

> **State the exact change, assign each contribution, and balance the transaction.**

| Responsibility | Question | Phase-2 scope |
| --- | --- | --- |
| [Net change](#ds-tx-accounting-net-change) | Does each declaration state the required deposit change? | Valid or invalid |
| [Attribution](#ds-tx-accounting-attribution) | Which signed contributions belong to TopTx or SubTx? | Derived on either path |
| [Balance](#ds-tx-accounting-balance) | Do consumed and produced values balance, counting the Store transfer once? | Valid only |

Declarations measure the change in total backing across both output forms.
Attribution assigns that signed change to bodies for settlement. Financial
balance counts the actual external deposits entering or leaving the Store and
the serialized values of all ordinary inputs and outputs.

<a id="ds-tx-exactness" name="ds-tx-exactness"></a>
<a id="ds-tx-accounting-net-change" name="ds-tx-accounting-net-change"></a>

#### 2.1.2.1 Net change

> **Each declaration must describe the right amount for its scope.**

| Declaration | Amount it describes |
| --- | --- |
| **SubTx** | The change from that SubTx's own inputs and outputs. |
| **TopTx** | The complete transaction's change: its own plus every SubTx's. |

```math
\begin{aligned}
\mathrm{ownNetDeposit}(b)
&=\sum_{o\in\mathrm{outputs}(b)}\mathrm{currentFormula}(o)
  -\sum_{i\in\mathrm{inputs}(b)}\mathrm{creditedBacking}(i) \\
\mathrm{transactionNetDeposit}(\mathit{topTx})
&=\mathrm{ownNetDeposit}(\mathit{topTx}) \\
&\quad+\sum_{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx})}
\mathrm{ownNetDeposit}(\mathit{subTx})
\end{aligned}
```

| Notation | Meaning |
| --- | --- |
| $`\mathrm{currentFormula}(o)`$ | Required backing at creation. A min-ADA output must contain this minimum in its value. A deposit-backed output requires this amount in the Store. |
| $`\mathrm{creditedBacking}(i)`$ | For a deposit-backed input, the full historical deposit. For a min-ADA input, the lesser of the historical price and the ADA in the input. Imported inputs use the initial formula. Dated inputs use the formula at allocation. |
| $`\mathrm{allocatedDeposits}(\mathit{body})`$ | [Price](domain-model.md#ds-pricing) the body's newly created deposit-backed outputs. |
| $`\mathrm{releasedDeposits}(\mathit{body})`$ | Read the recorded deposits of its consumed deposit-backed inputs. |
| $`\mathrm{declaredNetDeposit}(\mathit{body})`$ | The **signed** declared value: allocation $`\gt 0`$, release $`\lt 0`$, explicit zero $`=0`$. Absence has no declared value. |
| $`1`$ in amount comparisons | One lovelace. Example values labelled ADA are converted to lovelace. |

The builder and ledger derive these amounts from ordinary inputs resolved in the
original UTxO and the proposed regular outputs. Fee funding and change count on
the same terms. Reference inputs and collateral have separate rules.

These three ledger cases compare the signed declaration with the actual change
in external ADA. Each case also rejects the external-only amount when declared
by TopTx or SubTx. [Mixed-output regression tests](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/MixedBackingSpec.hs) and [verification results](../verification.md#signed-backing-change-for-mixed-output-forms--24-november-2026).

| Consumed backing | Required output backing | Exact declaration | Change in Store ADA |
| --- | --- | --- | ---: |
| 1.6 ADA embedded at allocation | 2 ADA external | Allocate 0.4 ADA | +2 ADA |
| Imported min-ADA input holding 2 ADA with a historical minimum of 3 ADA | 3 ADA external | Allocate 1 ADA | +3 ADA |
| 2 ADA external | 2 ADA embedded | Explicit zero | −2 ADA |

**Example, in ADA:**

| Body | Required own change | Required declaration |
| --- | ---: | ---: |
| TopTx | $`+1`$ | $`+2`$ — the transaction total |
| SubTx A | $`+3`$ | $`+3`$ |
| SubTx B | $`-2`$ | $`-2`$ |

```math
\mathrm{transactionNetDeposit}(\mathit{topTx})=1+3-2=2
```

- With TopTx's own $`+1`$, SubTx declarations of $`+4`$ and $`-3`$ still produce the total $`+2`$, but **both SubTx amounts are wrong**.
- SubTx declarations of $`+3`$ and $`-2`$ are exact, but a TopTx declaration of $`+5`$ gives **the wrong transaction total**.

The sets used below are:

```math
\begin{aligned}
\mathrm{bodies}(\mathit{topTx})
&=\{\mathit{topTx}\}\cup\mathrm{subTxs}(\mathit{topTx}) \\
\mathrm{declaredSubTxs}(\mathit{topTx})
&=\{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx}):\mathrm{hasDeclaration}(\mathit{subTx})\}
\end{aligned}
```

A SubTx with only min-ADA inputs and outputs may omit its declaration. Its
computed backing change still enters any required TopTx total. An undeclared
child has no locally declared share.

**Reading the contracts.** Requirements, valid grammar and resolved inputs
are assumed. Accepted controls satisfy the other transaction rules. Rejection must
include the targeted exactness failure; a [Balance](#ds-tx-accounting-balance) failure alone is insufficient.
The same required ordinary amounts apply on both phase-2 outcomes. The generated
net-change cases below match embedded input and output backing when isolating
external operations. See [Execution](ledger-effects.md#ds-state-execution) and [Historical pricing](domain-model.md#ds-pricing-history).

<a id="ds-tx-exactness-contribution" name="ds-tx-exactness-contribution"></a>
<a id="ds-tx-exactness-subtx" name="ds-tx-exactness-subtx"></a>
<a id="ds-tx-accounting-subtx" name="ds-tx-accounting-subtx"></a>
<a id="ds-tx-accounting-net-change-subtx" name="ds-tx-accounting-net-change-subtx"></a>

##### 2.1.2.1.1 SubTx

> **Each SubTx declares its exact own change.**

```math
\mathrm{declaredNetDeposit}(\mathit{subTx})=\mathrm{ownNetDeposit}(\mathit{subTx})
```

Keep TopTx's declaration equal to the independently required transaction total.
All other SubTx declarations remain exact; F05 deliberately changes two.
SubTx variables range over $`\mathrm{declaredSubTxs}(\mathit{topTx})`$;
$`\mathit{otherBody}`$ belongs to $`\mathrm{bodies}(\mathit{topTx})`$.
Delegating an allocation or release changes its accounting responsibility, while the
SubTx still declares its exact originating amount.

| SubTx declaration | Signed declared own change |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | $`0`$ |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | $`+\mathit{amount}`$ |
| `SubTx.RequestsUTxODepositFromTopTx amount` | $`+\mathit{amount}`$ |
| `SubTx.DeclaresNetUTxODepositRelease amount target` | $`-\mathit{amount}`$, for either target |

Explicit zero is valid only for a zero own change. Excess allocations, releases from
unspent outputs and opposing declaration errors fail SubTx exactness even
when the transaction total is correct.

**Additional notation used by these cases:**

```math
\mathrm{declarationError}(\mathit{subTx})
=\mathrm{declaredNetDeposit}(\mathit{subTx})-\mathrm{ownNetDeposit}(\mathit{subTx})
```

| Predicate or value | Meaning |
| --- | --- |
| $`\mathrm{delegatesAllocation}(\mathit{subTx})`$ | The declaration is `RequestsUTxODepositFromTopTx`. |
| $`\mathrm{delegatesRelease}(\mathit{subTx})`$ | The release target is `DelegateToTopTx`. |
| $`\mathit{translatedImplicitInput}`$ | A live input referencing a min-ADA output translated from the preceding era. |
| $`\mathit{unspentInputs}`$ | References to live Deposit-backed outputs that this transaction does not consume. |
| $`\mathrm{recordedDeposits}(\mathit{unspentInputs})`$ | Sum of their recorded deposits. |

For F01–F04, both the original and changed magnitudes remain representable. Positive
allocation amounts and release magnitudes are checked by Grammar; these cases test
exactness within that valid range.

[SubTx conformance cases and tests](appendices.md#subtx-net-change-test-cases)

<a id="ds-tx-exactness-netting" name="ds-tx-exactness-netting"></a>
<a id="ds-tx-exactness-toptx" name="ds-tx-exactness-toptx"></a>
<a id="ds-tx-accounting-toptx" name="ds-tx-accounting-toptx"></a>
<a id="ds-tx-accounting-net-change-toptx" name="ds-tx-accounting-net-change-toptx"></a>

##### 2.1.2.1.2 TopTx

> **TopTx declares the exact total for the complete transaction.**

```math
\mathrm{declaredNetDeposit}(\mathit{topTx})=\mathrm{transactionNetDeposit}(\mathit{topTx})
```

Keep every SubTx declaration exact. Include TopTx's own change and every SubTx change
once, including delegated operations. A sum over child declarations uses
`declaredSubTxs(topTx)`; undeclared children contribute no declared value.
The predicate $`\mathrm{delegated}(\mathit{subTx})`$ means a funding request to TopTx or
a release targeting `DelegateToTopTx`. Delegation affects [Attribution](#ds-tx-accounting-attribution),
while the transaction total remains unchanged.

| Total allocations | Total releases | TopTx declaration |
| --- | --- | --- |
| 5 ADA | 3 ADA | Allocate 2 ADA |
| 3 ADA | 5 ADA | Release 2 ADA |
| 5 ADA | 5 ADA | Explicit zero |

To recover TopTx's own change, subtract every child's computed backing change
from the batch total, including any undeclared min-ADA-only children.
[Attribution](#ds-tx-accounting-attribution) derives the share for TopTx settlement.

On ordinary success, the Store receives external output deposits and pays out
external input deposits. On accepted phase-2 failure, only collateral effects
apply. [Requirements](#ds-tx-declarations-requirements) determines field presence.

[TopTx conformance cases and tests](appendices.md#toptx-net-change-test-cases)

<a id="ds-tx-attribution" name="ds-tx-attribution"></a>
<a id="ds-tx-accounting-attribution" name="ds-tx-accounting-attribution"></a>

#### 2.1.2.2 Attribution

> **Determine which body accounts for each signed contribution.**
>
> Local operations remain with SubTx; delegated operations belong to TopTx.
> This changes responsibility, never the complete transaction's net amount.

| SubTx declaration | Originating change | Accounted in SubTx | Accounted in TopTx |
| --- | ---: | ---: | ---: |
| Local allocation | $`+\text{amount}`$ | $`+\text{amount}`$ | $`0`$ |
| Local release | $`-\text{amount}`$ | $`-\text{amount}`$ | $`0`$ |
| Allocation requested from TopTx | $`+\text{amount}`$ | $`0`$ | $`+\text{amount}`$ |
| Release delegated to TopTx | $`-\text{amount}`$ | $`0`$ | $`-\text{amount}`$ |
| Explicit zero | $`0`$ | $`0`$ | $`0`$ |
| Absent declaration (min-ADA only) | Computed embedded backing change | $`0`$ | Full computed change |

An absent declaration is not explicit zero; declaration requirements still apply.
A delegated contribution is already included in the transaction total. It changes
who accounts for that amount, without adding a second Store transfer.

```math
\begin{aligned}
\text{topTxNetUTxODepositChange}
&=\text{declaredTxTotalNetUTxODepositChange} \\
&\quad-\sum_{\text{subTx}\in\text{subTxs}}
  \text{locallyAccountedChange(subTx)}
\end{aligned}
```

TopTx retains its own signed change, all delegated changes, and the computed
backing of undeclared children. For exact declarations,

```math
\text{topTxNetUTxODepositChange}
=\text{ownNetDeposit(topTx)}
+\sum_{\text{subTx}\in\text{delegatingSubTxs}}
  \text{ownNetDeposit(subTx)}
+\sum_{\text{subTx}\in\text{undeclaredSubTxs}}
  \text{ownNetDeposit(subTx)}
```

Example: TopTx allocates 2 ADA and its SubTx allocates 3 ADA.

| SubTx declaration | TopTx declares | Accounted in SubTx | Accounted in TopTx |
| --- | --- | ---: | ---: |
| Local allocation | Allocate 5 ADA | $`+3`$ ADA | $`+2`$ ADA |
| Funding requested from TopTx | Allocate 5 ADA | $`0`$ ADA | $`+5`$ ADA |

Local accounting does not require independent SubTx financial balance.
[Net change](#ds-tx-accounting-net-change) checks exact amounts;
[Balance](#ds-tx-accounting-balance) checks complete transaction funding.

<a id="ds-tx-attribution-p01" name="ds-tx-attribution-p01"></a>
<a id="ds-tx-attribution-n01" name="ds-tx-attribution-n01"></a>
<a id="ds-tx-settlement-participation-p02" name="ds-tx-settlement-participation-p02"></a>
<a id="ds-tx-accounting-attribution-p01" name="ds-tx-accounting-attribution-p01"></a>

##### 2.1.2.2.1 [P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L39) - Local and delegated contributions determine TopTx's share

```math
\begin{aligned}
\text{attributedTopTxChange}
  &=\text{ownTopTxChange}+\sum\text{delegatedSubTxChanges} \\
\text{localSubTxChanges}&=\text{expectedLocalChanges}
\end{aligned}
```

The undeclared children in P01 preserve embedded backing. Generate all six
declaration forms from the table above. Observe production
accounting and compare it with independently measured input deposits and output
allocations. Local allocations contribute positively, local releases negatively;
requests and delegated releases remain in TopTx's share **exactly once**. Include
positive, zero and negative transaction totals, and TopTx's own nonzero operations.

This is an isolated accounting property. It establishes the signed responsibilities
used by settlement; it does not assert that a selector or destination is valid.

<a id="ds-tx-attribution-p02" name="ds-tx-attribution-p02"></a>
<a id="ds-tx-settlement-participation-p03" name="ds-tx-settlement-participation-p03"></a>
<a id="ds-tx-accounting-attribution-p02" name="ds-tx-accounting-attribution-p02"></a>

##### 2.1.2.2.2 [P02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L67) - Delegation moves the signed contribution to TopTx

Keep the Store operations fixed and change one SubTx declaration from local to
delegated accounting. Here $`\Delta`$ means **delegated result minus local result**.

```math
\begin{aligned}
\text{local}\longrightarrow\text{delegated}
\implies\quad
&\Delta\text{localSubTxChange}=-\text{originatingChange} \\
&\land\Delta\text{attributedTopTxChange}=\text{originatingChange}
\end{aligned}
```

| Originating SubTx change | Change in SubTx accounting | Change in TopTx accounting |
| --- | ---: | ---: |
| Allocation of 3 ADA | $`-3`$ ADA | $`+3`$ ADA |
| Release of 3 ADA | $`+3`$ ADA | $`-3`$ ADA |

The [Net change property](appendices.md#ds-tx-accounting-net-change-toptx-p02) checks that the
transaction total stays unchanged. This property checks the responsibility shift.
It does not promise acceptance with unchanged selectors or outputs: moving a release
may require a different settlement destination or greater coverage.

<a id="ds-tx-grammar-n01" name="ds-tx-grammar-n01"></a>
<a id="ds-tx-declarations-grammar-n01" name="ds-tx-declarations-grammar-n01"></a>
<a id="ds-tx-attribution-n04" name="ds-tx-attribution-n04"></a>
<a id="ds-tx-settlement-participation-n10" name="ds-tx-settlement-participation-n10"></a>
<a id="ds-tx-accounting-attribution-n01" name="ds-tx-accounting-attribution-n01"></a>

##### 2.1.2.2.3 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L98) - Explicit zero adds no delegated contribution

```math
\begin{aligned}
&\text{allocatedDeposits(subTx)}=\text{releasedDeposits(subTx)} \\
&\land\text{declaresExplicitZero(subTx)} \\
&\implies\text{originatingChange}=\text{localChange}=\text{delegatedChange}=0
\end{aligned}
```

| SubTx operations | Declaration | Contribution to TopTx's share |
| --- | --- | ---: |
| No allocation or release | Explicit zero | $`0`$ |
| Equal positive allocations and releases | Explicit zero | $`0`$ |

Observe production accounting for both cases and submit otherwise valid transactions.
Explicit zero neither requests funding nor delegates a release; TopTx's attributed
amount remains its own contribution. Equal positive operations still require a
declaration, as specified under [Zero net change](#ds-tx-declarations-requirements-operations-zero-net-change).

<a id="ds-tx-conservation" name="ds-tx-conservation"></a>
<a id="ds-tx-accounting-balance" name="ds-tx-accounting-balance"></a>

#### 2.1.2.3 Balance

> **Require the complete transaction to balance when phase 2 is valid.**
>
> All consumed value $`=`$ all produced value, including the net Store transfer once. Individual SubTxs may remain financially imbalanced.

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
| $`\text{inputValue}`$ | Sum of serialized values of all ordinary inputs across TopTx and its SubTxs, including embedded min-ADA. |
| $`\text{outputValue}`$ | Sum of their proposed regular output values, also including embedded min-ADA. |
| $`\text{storeChange}`$ | External deposits of newly created deposit-backed outputs minus historical deposits of consumed deposit-backed inputs, across all bodies. |
| $`\text{fees}`$ | TopTx's fee. |
| $`\text{declaredNetDeposit}`$ | TopTx's explicit signed total: allocation $`\gt 0`$, release $`\lt 0`$, zero $`=0`$. |
| $`\text{inputCoins(body)}`$, $`\text{outputCoins(body)}`$ | Serialized ADA in that body's own inputs or outputs. |
| $`\Delta`$ | Change from the independently balanced control. |
| $`\text{outputAdjustment}`$ | Change to TopTx's min-ADA output zero. |
| $`\text{feeContribution(subTx)}`$ | Application ADA redirected from the child's output into an increased TopTx fee; not a declaration field. |

**The Store transfer enters the equation once.** `inject` adds ADA without
changing native assets:

```math
\begin{aligned}
\text{consumedValue}
&=\text{inputValue}+\text{inject}(\max(0,-\text{storeChange})) \\
\text{producedValue}
&=\text{outputValue}+\text{inject}(\text{fees}+\max(0,\text{storeChange})) \\
\text{transactionBalance}
&=\text{consumedValue}-\text{producedValue}
\end{aligned}
```

$`\text{transactionBalance}`$ retains all asset identities and quantities. Its ADA
and native-asset components are $`\text{adaBalance}`$ and
$`\text{nativeAssetBalance}`$; zero means no remaining difference in that component.
Each body contributes its actual external movement once. Embedded reserves already
travel in the input and output values. A batch can therefore have an explicit zero
declaration and a nonzero Store transfer.

The ADA a SubTx contributes to the rest of a successful batch can be derived from
its signed body and the ledger state. Here $`\text{storeChange(subTx)}`$ is the
change in external deposits for that SubTx alone.

```math
\text{netADAExport(subTx)}
= \text{ordinaryConsumedADA} - \text{storeChange(subTx)} - \text{ordinaryProducedADA}
```

Ordinary consumed ADA includes regular input coins, withdrawals and certificate
refunds. Ordinary produced ADA includes regular output coins, certificate and
proposal deposits, treasury donations and direct account deposits. Attribute
certificate effects in batch processing order. The separate Store term accounts
for external deposits. TopTx pays the batch fee. A positive result leaves ADA for
that fee or another body. A negative result draws ADA from the batch.

[Net change](#ds-tx-accounting-net-change) separately establishes that declarations
match the required deposit changes on both phase-2 outcomes. The balance equation
here applies only when phase 2 is valid. On phase-2 failure, the ordinary proposal
remains unapplied; [Ledger conservation](ledger-effects.md#ds-state-conservation) governs
the applied settlement, and [Execution](ledger-effects.md#ds-state-execution) selects the effects.

**Fixture scope.** Inputs are actually funded. The proposals contain ordinary
application inputs and outputs, TopTx fees and Store transfers. They contain no
certificates, withdrawals, mint, governance proposals, treasury donations or direct
deposits.

Native assets used by P01 and F02 are minted in a separate accepted funding
transaction. Their proposed spending transaction does not mint. The independent
observer resolves every ordinary input from the ledger and independently sums
serialized values, fees and actual external deposits. It does not call the
production consumed/produced-value helpers. Additional ledger flows would require
extending this observer before adding them to these fixtures.

The ordinary cases use key witnesses in normal mode. N08 adds a genuinely failing
phase-2 script with valid collateral. These fixtures do not exercise legacy-mode
balance restrictions. A separate mixed-output test covers the legacy TopTx
self-balance check. TopTx funds its own external movement plus explicitly
requested child allocations, less explicitly delegated child releases. A child
that converts 1.6 ADA of embedded reserve to 2 ADA of external backing can
request 0.4 ADA from the parent. Its own serialized input supplies the other
1.6 ADA.

**Isolate financial balance.** Every declaration remains exact. Start with a
proposal independently balanced after fee preparation; change only implicit
application outputs or the fee, then re-sign without rerunning value fixup. The
changed output cannot alter the Store allocation. Rejection must include
`ValueNotConservedUTxO` with the independently computed consumed and produced
values, and each rejection scenario also submits its balanced acceptance control.

**An external release with zero net backing change.** N06, N07 and F04 hold every other batch flow
fixed. TopTx funds its base fee separately; the child has one input, one min-ADA
output requiring 2 ADA of embedded backing and no other financial flow. For these cases, the
transaction equation reduces to:

```math
\text{inputCoins(subTx)}+\text{releasedDeposits(subTx)}
=\text{outputCoins(subTx)}+\text{feeContribution(subTx)}
```

This reduction follows from the fixed surrounding transaction; it is not a new
requirement that all SubTxs balance independently.

| Child's application input | Recorded Store release | Child's only output | Export to TopTx fees | Outcome |
| --- | --- | --- | --- | --- |
| $`10`$ ADA | $`2`$ ADA | $`12`$ ADA | $`0`$ ADA | Accepted |
| $`10`$ ADA | $`2`$ ADA | $`10`$ ADA | $`2`$ ADA | Accepted |
| $`10`$ ADA | $`2`$ ADA | $`10`$ ADA | $`0`$ ADA | Rejected: $`2`$ ADA unaccounted for |

The $`2`$ ADA release is the deposit recorded for the actual deposit-backed input.
The replacement min-ADA output requires 2 ADA of embedded backing, so TopTx and
SubTx both declare zero. Only the serialized output ADA and the fee contribution
vary between rows. For the destination check on a declared release, see
[Local settlement](#ds-tx-settlement-output-coin).

<a id="ds-tx-conservation-p01" name="ds-tx-conservation-p01"></a>
<a id="ds-tx-accounting-balance-p01" name="ds-tx-accounting-balance-p01"></a>

##### 2.1.2.3.1 [P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L72) - The transaction conserves value when phase 2 is valid

```math
\begin{aligned}
&\text{phase2Valid}\land\text{Accepted} \\
&\implies\text{inputValue}+\text{inject}(\max(0,-\text{storeChange})) \\
&\qquad=\text{outputValue}+\text{inject}(\text{fees}+\max(0,\text{storeChange}))
\end{aligned}
```

Generate TopTx with one to four SubTxs, combining allocations and recorded releases.
Supply exact declarations and a real token-bearing input with a matching output.
Require ledger acceptance, then compare the independently observed full values.
The equation covers ADA and native assets while the Store term changes only ADA.

<a id="ds-tx-conservation-p02" name="ds-tx-conservation-p02"></a>
<a id="ds-tx-accounting-balance-p02" name="ds-tx-accounting-balance-p02"></a>

##### 2.1.2.3.2 [P02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L96) - Complete balance determines acceptance

```math
\begin{aligned}
&\text{phase2Valid}\land\text{transfer}>0 \\
&\land\text{outputAdjustment}\in\{-1,0,1\} \\
&\implies(\text{Accepted}\iff\text{transactionBalance}=0)
\end{aligned}
```

First move a positive amount from one SubTx's min-ADA output to another's.
The two child imbalances offset. For each generated transaction, also adjust one
TopTx min-ADA output by $`-1`$, $`0`$ and $`+1`$ lovelace, leaving fees and declarations
unchanged.

The independent value equation determines the expected ledger decision. Both
nonzero adjustments must produce its exact mismatch; the zero adjustment must be
accepted despite the SubTxs' individual financial imbalances.

<a id="ds-tx-conservation-n01" name="ds-tx-conservation-n01"></a>
<a id="ds-tx-accounting-balance-n01" name="ds-tx-accounting-balance-n01"></a>

##### 2.1.2.3.3 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L117) - Fund a net allocation once

```math
\begin{aligned}
&\text{declaredNetDeposit}>0 \\
&\land\text{outputAdjustment}\in\{-\text{declaredNetDeposit},0,\text{declaredNetDeposit}\} \\
&\implies(\text{Accepted}\iff\text{outputAdjustment}=0)
\end{aligned}
```

TopTx and its SubTx each allocate a positive deposit. Keep their exact
declarations, then compare the balanced transaction with two changes to TopTx's
min-ADA output:

| Application output change | Financial interpretation | Expected result |
| --- | --- | --- |
| $`0`$ | Fund the declared total once. | Accepted |
| $`+\text{declaredNetDeposit}`$ | Spend the allocation again as application ADA. | Rejected |
| $`-\text{declaredNetDeposit}`$ | Charge the allocation twice, leaving an unaccounted surplus. | Rejected |

The matched embedded backing in this fixture makes the exact declared allocation
equal to the external transfer. Neither mutation changes a deposit or a reserve.

<a id="ds-tx-conservation-n02" name="ds-tx-conservation-n02"></a>
<a id="ds-tx-accounting-balance-n02" name="ds-tx-accounting-balance-n02"></a>

##### 2.1.2.3.4 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L137) - Use a net release once

```math
\begin{aligned}
&\text{declaredNetDeposit}<0 \\
&\land\text{outputAdjustment}\in\{-\text{declaredNetDeposit},0,\text{declaredNetDeposit}\} \\
&\implies(\text{Accepted}\iff\text{outputAdjustment}=0)
\end{aligned}
```

TopTx and its SubTx each release recorded deposits. Keep their exact
declarations and compare these uses of the complete net release:

| Application output change | Financial interpretation | Expected result |
| --- | --- | --- |
| $`0`$ | Use the declared release once. | Accepted |
| $`-\text{declaredNetDeposit}`$ | Spend a second copy of the release. | Rejected |
| $`+\text{declaredNetDeposit}`$ | Leave the release unaccounted for. | Rejected |

The changes affect only TopTx's min-ADA output. The matched embedded backing in
this fixture makes the declared release equal to the actual Store payout.

<a id="ds-tx-conservation-n03" name="ds-tx-conservation-n03"></a>
<a id="ds-tx-accounting-balance-n03" name="ds-tx-accounting-balance-n03"></a>

##### 2.1.2.3.5 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L155) - One SubTx funds another

```math
\begin{aligned}
&\text{transfer}>0 \\
&\land\Delta\text{outputCoins}(\text{subTx}_{0})=-\text{transfer} \\
&\land\Delta\text{outputCoins}(\text{subTx}_{1})=\text{transfer} \\
&\implies\text{Accepted}
\end{aligned}
```

Begin with a balanced control containing two SubTxs that allocate deposits.
Move a generated positive amount from the first child's min-ADA output to the
second's, keeping the complete output value, declarations and fee unchanged.

Accept the transaction. A surplus in one body may fund another; exact local deposit
declarations do not require independently balanced SubTx finances.

<a id="ds-tx-conservation-n04" name="ds-tx-conservation-n04"></a>
<a id="ds-tx-accounting-balance-n04" name="ds-tx-accounting-balance-n04"></a>

##### 2.1.2.3.6 [N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L168) - A SubTx funds TopTx fees

```math
\begin{aligned}
&\text{contribution}>0 \\
&\land\Delta\text{outputCoins(subTx)}=-\text{contribution} \\
&\land\Delta\text{fees}=\text{contribution} \\
&\implies\text{Accepted}
\end{aligned}
```

TopTx and its SubTx allocate deposits with exact declarations. Redirect a
generated positive amount from the child's min-ADA output into TopTx's fee.

Accept the transaction: total produced value is unchanged. The child may fund a
parent fee without changing either body's deposit declaration.

<a id="ds-tx-conservation-f01" name="ds-tx-conservation-f01"></a>
<a id="ds-tx-accounting-balance-f01" name="ds-tx-accounting-balance-f01"></a>

##### 2.1.2.3.7 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L181) - One-lovelace deficit or surplus

```math
\Delta\text{outputCoins(topTx)}\in\{-1,1\}
\implies\text{Rejected}
```

Starting from an exactly declared, funded allocation transaction, change only
TopTx's min-ADA output by one lovelace in each direction.

The increase creates a deficit; the decrease leaves a surplus. Require
`ValueNotConservedUTxO` for both, then accept the unchanged balanced control.
Exact deposit declarations excuse neither mismatch.

<a id="ds-tx-conservation-f02" name="ds-tx-conservation-f02"></a>
<a id="ds-tx-accounting-balance-f02" name="ds-tx-accounting-balance-f02"></a>

##### 2.1.2.3.8 [F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L199) - Native-asset quantity or identity mismatch

```math
\text{adaBalance}=0\land\text{nativeAssetBalance}\ne0
\implies\text{Rejected}
```

Spend a genuinely funded native asset without minting in the proposal. Keep
ADA, the exact Store declarations and the fee unchanged, then mutate only the
token-bearing min-ADA output:

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

##### 2.1.2.3.9 [F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L219) - An exact delegated allocation lacks funding

```math
\begin{aligned}
&\text{requestedAllocation}>0 \\
&\land\Delta\text{outputCoins(topTx)}=\text{requestedAllocation} \\
&\implies\text{Rejected}
\end{aligned}
```

A single SubTx requests a positive allocation from TopTx; TopTx has no own
Store operation and declares that same exact total. From its balanced control,
increase TopTx's min-ADA output by the requested allocation.

The request remains exact, but its funds are also promised to an application
output. Require the financial mismatch, then accept the original funded request.
Delegation assigns responsibility; it does not supply additional ADA.

<a id="ds-tx-conservation-n05" name="ds-tx-conservation-n05"></a>
<a id="ds-tx-accounting-balance-n05" name="ds-tx-accounting-balance-n05"></a>

##### 2.1.2.3.10 [N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L234) - Equal delegated allocations and releases

```math
\begin{aligned}
&\text{requestedAllocation}=\text{delegatedRelease}>0 \\
&\land\text{declaredNetDeposit}=0\land\text{transactionBalance}=0 \\
&\implies\text{Accepted}
\end{aligned}
```

One SubTx requests an allocation from TopTx; another delegates an equal
recorded release to TopTx. The parent has no own Store operation.

With both child declarations explicit and the complete transaction funded, accept
TopTx's explicit-zero total. The two Store operations exist, but their combined
transfer adds no ADA to either side of the transaction balance.

<a id="ds-tx-conservation-n06" name="ds-tx-conservation-n06"></a>
<a id="ds-tx-accounting-balance-n06" name="ds-tx-accounting-balance-n06"></a>

##### 2.1.2.3.11 [N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L246) - Ten input ADA plus two released ADA

```math
\begin{aligned}
&\text{inputCoins(subTx)}=10\text{ ADA} \\
&\land\text{releasedDeposits(subTx)}=2\text{ ADA} \\
&\land\text{outputCoins(subTx)}=12\text{ ADA} \\
&\land\text{feeContribution(subTx)}=0 \\
&\implies\text{Accepted}
\end{aligned}
```

Fund one actual deposit-backed input containing $`10`$ ADA of application value
and a recorded $`2`$ ADA deposit. Its SubTx consumes that input and creates one
min-ADA output requiring $`2`$ ADA of embedded backing. The child and parent
explicitly declare zero. The Store pays out $`2`$ ADA, giving the child $`12`$ ADA
of serialized output value.

Accept the transaction. TopTx's separate generated funding pays its base fee, so
no fee or additional child input changes this example. This fixed child scenario
does not impose independent SubTx balance on the other cases.

<a id="ds-tx-conservation-n07" name="ds-tx-conservation-n07"></a>
<a id="ds-tx-accounting-balance-n07" name="ds-tx-accounting-balance-n07"></a>

##### 2.1.2.3.12 [N07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L255) - Released ADA contributes to TopTx fees

```math
\begin{aligned}
&\text{inputCoins(subTx)}=10\text{ ADA} \\
&\land\text{releasedDeposits(subTx)}=2\text{ ADA} \\
&\land\text{outputCoins(subTx)}=10\text{ ADA} \\
&\land\text{feeContribution(subTx)}=2\text{ ADA} \\
&\implies\text{Accepted}
\end{aligned}
```

Use N06's same $`10`$ ADA input and $`2`$ ADA recorded release. Reduce the child's
min-ADA output from $`12`$ ADA to $`10`$ ADA and increase TopTx's fee by exactly
$`2`$ ADA, preserving every other flow.

Accept the transaction. The release is fully accounted for through the smaller
child output and the explicit fee contribution. Both declarations remain zero.

<a id="ds-tx-conservation-f04" name="ds-tx-conservation-f04"></a>
<a id="ds-tx-accounting-balance-f04" name="ds-tx-accounting-balance-f04"></a>

##### 2.1.2.3.13 [F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L265) - Released ADA cannot disappear

```math
\begin{aligned}
&\text{inputCoins(subTx)}=10\text{ ADA} \\
&\land\text{releasedDeposits(subTx)}=2\text{ ADA} \\
&\land\text{outputCoins(subTx)}=10\text{ ADA} \\
&\land\text{feeContribution(subTx)}=0 \\
&\implies\text{Rejected}
\end{aligned}
```

Start with N06's balanced transaction and reduce only the child's min-ADA
output from $`12`$ ADA to $`10`$ ADA. Keep TopTx's fee, every other output and all
inputs and declarations fixed.

Require the independent financial mismatch, then accept the original $`12`$ ADA
control. N07 is accepted because it accounts for this difference in the fee;
this variant leaves the same $`2`$ ADA without a destination.

<a id="ds-tx-conservation-n08" name="ds-tx-conservation-n08"></a>
<a id="ds-tx-accounting-balance-n08" name="ds-tx-accounting-balance-n08"></a>

##### 2.1.2.3.14 [N08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L280) - Balanced proposal, failed phase 2

```math
\text{phase2Invalid}\land\text{transactionBalance}=0
\implies\text{Accepted}
```

Generate recorded releases for both TopTx and its SubTx, with exact declarations
and an independently balanced ordinary proposal. Add a genuinely failing phase-2
script, declare the invalid outcome and supply valid collateral. Expect acceptance
through the collateral outcome.

This is an acceptance control: a balanced ordinary proposal may accompany accepted
phase-2 failure. It does not establish that ordinary balance is checked on this
path. [Execution](ledger-effects.md#ds-state-execution) determines the applied effects.

<a id="ds-tx-authorization" name="ds-tx-authorization"></a>

### 2.1.3 Authorization

> **Spending authority also authorizes release of the input's recorded deposit.**
>
> Funding a deposit gives no separate approval right over its later release.

**Decision:** Agreed.

| Role | Example | Required in the later spending transaction? |
| --- | --- | --- |
| Original deposit funder | Alice pays for a deposit-backed output controlled by Bob | Alice's signature is not required |
| Current spending authority | Bob's key controls that output | Bob's spending signature is required |

```text
Alice funds the deposit-backed output
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

$`\text{spendingSignatures(body)}`$ identifies the keys signing the body that consumes
the input; $`\text{transactionSignatures(tx)}`$ includes signatures across TopTx and its
SubTxs. These cases exercise ordinary successful spending. Collateral authority
belongs to the [shared collateral authorization rules](#ds-collateral-existing-rules).

<a id="ds-tx-authorization-n02" name="ds-tx-authorization-n02"></a>
<a id="ds-tx-authorization-n01" name="ds-tx-authorization-n01"></a>

#### 2.1.3.1 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L51) - Bob spends an output funded by Alice

```math
\begin{aligned}
&\text{depositFunder(input)}=\text{Alice} \\
&\land\text{spendingKey(input)}=\text{Bob} \\
&\land\text{Bob}\in\text{spendingSignatures(body)} \\
&\land\text{Alice}\notin\text{transactionSignatures(tx)} \\
&\implies\text{Accepted}
\end{aligned}
```

Create and fund the output in an earlier ledger transaction. In the later spending
transaction, inspect the final witness set: Bob's spending signature is present;
Alice's is absent. Submit that signed transaction and expect acceptance. This single
case establishes both Bob's authority and the absence of an original-funder approval
requirement.

<a id="ds-tx-authorization-f01" name="ds-tx-authorization-f01"></a>

#### 2.1.3.2 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L73) - Alice's signature cannot replace Bob's

```math
\begin{aligned}
&\text{depositFunder(input)}=\text{Alice} \\
&\land\text{spendingKey(input)}=\text{Bob} \\
&\land\text{Alice}\in\text{spendingSignatures(body)} \\
&\land\text{Bob}\notin\text{spendingSignatures(body)} \\
&\implies\text{RejectedWith(missingSpendingWitness(body,Bob))}
\end{aligned}
```

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
already checks that referencing live deposit-backed outputs does not require a release
declaration. A reference does not consume the output or release its deposit. Declaring
an amount released from reference inputs would be an inexact [Accounting](#ds-tx-accounting-net-change)
claim, not a missing spending-witness failure. It is not an additional Authorization
test.

<a id="ds-tx-settlement" name="ds-tx-settlement"></a>

### 2.1.4 Settlement

> **Determine which output must contain a release amount.**
>
> Designation $`\longrightarrow`$ output index $`\longrightarrow`$ output coin.
> Settlement uses the accounting result without adding another Store transfer.

| Check | Question |
| --- | --- |
| [Designation](#ds-tx-settlement-designation) | Must TopTx designate a settlement output? |
| [Output index](#ds-tx-settlement-output-index) | Does the selected index exist in the declaring body's own outputs? |
| [Output coin](#ds-tx-settlement-output-coin) | Does that output contain the required ADA in its serialized value? |

<a id="ds-tx-settlement-participation" name="ds-tx-settlement-participation"></a>
<a id="ds-tx-settlement-designation" name="ds-tx-settlement-designation"></a>

#### 2.1.4.1 Designation

> **Determine whether TopTx must designate a settlement output.**
>
> Use its signed share from [Attribution](#ds-tx-accounting-attribution).
> Only a net-release declaration carries a TopTx settlement designation.

**Decision:** Agreed.

**When does TopTx need a settlement output?**

| Notation | Meaning |
| --- | --- |
| $`\text{totalChange}`$ | Signed net deposit change for TopTx and all SubTxs. |
| $`\text{topTxChange}`$ | Batch backing change minus all locally declared SubTx shares. |
| $`\text{hasTopTxOutput}`$ | The declaration uses `TopTxSettlementOutput index`. |
| $`\text{noTopTxOutput}`$ | A release uses `NoTopTxSettlement`, or the declaration has no designation field. |

Only a net-release declaration carries this choice:

```haskell
TopTx.DeclaresNetUTxODepositRelease amount settlement

-- amount :: StrictlyPositiveCoin is the entire transaction's net release.
data TopTxReleaseSettlement
  = NoTopTxSettlement
  | TopTxSettlementOutput !TxIx
```

```math
\text{totalChange}<0
\implies
(\text{hasTopTxOutput}\iff\text{topTxChange}<0)
```

| Transaction change | TopTx attributed change | Required declaration form |
| --- | --- | --- |
| Net release | Negative: TopTx has a release share | Release with `TopTxSettlementOutput index` |
| Net release | Zero or positive: TopTx has no release share | Release with `NoTopTxSettlement` |
| Net allocation | Any sign | Allocation; no designation field |
| Zero | Any sign | Explicit zero; no designation field |

`NoTopTxSettlement` does **not** mean zero transaction release: the SubTxs may settle
it locally. The declared release amount remains the whole transaction's net change.
The designated TopTx output must cover the magnitude of its attributed release.
An undeclared min-ADA-only child can contribute a release to the batch. If the
batch and the parent share are both negative, TopTx must designate an output.

These exact net-release examples use ADA:

| Local SubTx change | TopTx attributed change | Transaction release | TopTx designation |
| ---: | ---: | ---: | --- |
| $`-5`$ | $`0`$ | 5 | None |
| $`-3`$ | $`-2`$ | 5 | Required; share is 2 |
| $`+3`$ | $`-5`$ | 2 | Required; share is 5 |
| $`-5`$ | $`+3`$ | 2 | None |

[Output index](#ds-tx-settlement-output-index) resolves the designated output within
TopTx's own outputs; [Output coin](#ds-tx-settlement-output-coin) checks its ADA.
Neither changes the transaction's net Store transfer.

**Test conditions:** Amounts are exact, designated indices resolve, outputs contain
sufficient ADA and the transaction is otherwise valid. Phase-2 cases contain a real
failing script and valid collateral. These conditions isolate designation itself.

<a id="ds-tx-settlement-participation-p01" name="ds-tx-settlement-participation-p01"></a>
<a id="ds-tx-settlement-designation-p01" name="ds-tx-settlement-designation-p01"></a>

##### 2.1.4.1.1 [P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L47) - Designation follows TopTx's release share

```math
\text{totalChange}<0
\implies(\text{designationValid}\iff(\text{hasTopTxOutput}\iff\text{topTxChange}<0))
```

For each generated net-release proposal, check both designation choices and both local and delegated child releases. Compare the isolated validator with an expectation derived from recorded input deposits and priced outputs, independently of production attribution.

<a id="ds-tx-settlement-participation-n01" name="ds-tx-settlement-participation-n01"></a>
<a id="ds-tx-settlement-designation-n01" name="ds-tx-settlement-designation-n01"></a>

##### 2.1.4.1.2 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L69) - SubTxs settle the entire release

```math
\text{totalChange}<0\land\text{topTxChange}=0\land\text{noTopTxOutput}
\implies\text{Accepted}
```

Every SubTx settles its release locally. TopTx has no remaining release share, so its exact total declaration uses `NoTopTxSettlement`.

<a id="ds-tx-settlement-participation-n02" name="ds-tx-settlement-participation-n02"></a>
<a id="ds-tx-settlement-designation-n02" name="ds-tx-settlement-designation-n02"></a>

##### 2.1.4.1.3 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L82) - Standalone TopTx settles its release

```math
\text{totalChange}<0\land\text{topTxChange}<0\land\text{hasTopTxOutput}
\implies\text{Accepted}
```

A standalone TopTx releases deposits and designates one of its outputs. With no SubTx contribution, its attributed share is the complete transaction release.

<a id="ds-tx-settlement-participation-n03" name="ds-tx-settlement-participation-n03"></a>
<a id="ds-tx-settlement-designation-n03" name="ds-tx-settlement-designation-n03"></a>

##### 2.1.4.1.4 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L93) - TopTx and SubTxs each settle a share

```math
\begin{aligned}
&\text{topTxChange}<0 \\
&\land(\forall\,\text{subTx}\in\text{subTxs}:\text{localChange(subTx)}<0) \\
&\land\text{allRequiredOutputsDesignated} \\
&\implies\text{Accepted}
\end{aligned}
```

Generate releases in TopTx and several SubTxs. Each child designates its own output; TopTx designates an output for its remaining share. The total declaration includes all releases once.

<a id="ds-tx-settlement-participation-n04" name="ds-tx-settlement-participation-n04"></a>
<a id="ds-tx-settlement-designation-n04" name="ds-tx-settlement-designation-n04"></a>

##### 2.1.4.1.5 [N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L106) - TopTx's share exceeds the transaction release

```math
\begin{aligned}
&\text{totalChange}<0\land\text{localSubTxChange}>0 \\
&\implies\text{requiredTopTxOutputADA}>-\text{totalChange} \\
&\qquad\land\text{Accepted}
\end{aligned}
```

A local child allocation reduces the transaction release without reducing TopTx’s own release share. For example, $`+3`$ ADA in SubTx and $`-5`$ ADA in TopTx produce a release of 2 ADA. TopTx still designates a sufficiently funded output for its 5 ADA share.

<a id="ds-tx-settlement-participation-f01" name="ds-tx-settlement-participation-f01"></a>
<a id="ds-tx-settlement-designation-f01" name="ds-tx-settlement-designation-f01"></a>

##### 2.1.4.1.6 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L120) - TopTx omits a required output

```math
\begin{aligned}
&\text{totalChange}<0\land\text{topTxChange}<0\land\text{noTopTxOutput} \\
&\implies\text{RejectedWith(MissingTopTxSettlement)}
\end{aligned}
```

Keep the total exact and the transaction funded, but use `NoTopTxSettlement` despite TopTx having a positive release share. Require the missing-designation failure.

<a id="ds-tx-settlement-participation-f02" name="ds-tx-settlement-participation-f02"></a>
<a id="ds-tx-settlement-designation-f02" name="ds-tx-settlement-designation-f02"></a>

##### 2.1.4.1.7 [F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L131) - TopTx designates an unnecessary output

```math
\begin{aligned}
&\text{totalChange}<0\land\text{topTxChange}=0\land\text{hasTopTxOutput} \\
&\implies\text{RejectedWith(UnexpectedTopTxSettlement)}
\end{aligned}
```

All releases are settled locally by SubTxs. An additional TopTx designation is rejected, even though its index and output coin would otherwise be valid.

<a id="ds-tx-settlement-participation-n05" name="ds-tx-settlement-participation-n05"></a>
<a id="ds-tx-settlement-designation-n05" name="ds-tx-settlement-designation-n05"></a>

##### 2.1.4.1.8 [N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L144) - Net allocation, even though TopTx releases

```math
\text{totalChange}>0\land\text{topTxChange}<0\land\text{noTopTxOutput}
\implies\text{Accepted}
```

Local SubTx allocations exceed TopTx’s release. The complete transaction declares an allocation, whose grammar has no settlement designation. A negative TopTx share does not introduce one.

<a id="ds-tx-settlement-participation-n06" name="ds-tx-settlement-participation-n06"></a>
<a id="ds-tx-settlement-designation-n06" name="ds-tx-settlement-designation-n06"></a>

##### 2.1.4.1.9 [N06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L157) - Explicit-zero total, even though TopTx releases

```math
\text{totalChange}=0\land\text{topTxChange}<0\land\text{noTopTxOutput}
\implies\text{Accepted}
```

Local SubTx allocations exactly offset TopTx’s release. TopTx declares explicit zero; that declaration has no designation field.

<a id="ds-tx-settlement-participation-n07" name="ds-tx-settlement-participation-n07"></a>
<a id="ds-tx-settlement-designation-n07" name="ds-tx-settlement-designation-n07"></a>

##### 2.1.4.1.10 [N07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L170) - Net release, while TopTx allocates

```math
\text{totalChange}<0\land\text{topTxChange}>0\land\text{noTopTxOutput}
\implies\text{Accepted}
```

Local SubTx releases exceed TopTx’s allocation. The complete transaction releases deposits, but TopTx has no release share. Accept `NoTopTxSettlement`; zero and positive attributed changes both permit it.

<a id="ds-tx-settlement-participation-n08" name="ds-tx-settlement-participation-n08"></a>
<a id="ds-tx-settlement-designation-n08" name="ds-tx-settlement-designation-n08"></a>

##### 2.1.4.1.11 [N08](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L183) - Valid designation when phase 2 fails

```math
\text{phase2Invalid}\land\text{totalChange}<0\land\text{designationValid}
\implies\text{Accepted}
```

Use both valid choices with an actual failing script: designate a TopTx output when it has a release share, and use `NoTopTxSettlement` when the SubTxs settle the complete release locally. The ordinary designation is validated before collateral-only execution.

<a id="ds-tx-settlement-participation-f03" name="ds-tx-settlement-participation-f03"></a>
<a id="ds-tx-settlement-designation-f03" name="ds-tx-settlement-designation-f03"></a>

##### 2.1.4.1.12 [F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L199) - Invalid designation when phase 2 fails

```math
\text{phase2Invalid}\land\text{totalChange}<0\land\neg\text{designationValid}
\implies\text{Rejected}
```

From the valid phase-2-invalid controls, omit a required TopTx designation or supply one when TopTx has no release share. Require `MissingTopTxSettlement` or `UnexpectedTopTxSettlement`, respectively.

<a id="ds-tx-settlement-destination" name="ds-tx-settlement-destination"></a>
<a id="ds-tx-settlement-output-index" name="ds-tx-settlement-output-index"></a>

#### 2.1.4.2 Output index

> **Resolve the index in the declaring body's own regular outputs.**
>
> Another body's output or collateral return cannot satisfy that index.

**Decision:** Agreed.

| Declaration | Sequence used to resolve its index |
| --- | --- |
| `TopTxSettlementOutput index` | TopTx's own regular outputs |
| `SubTxSettlementOutput index` | That SubTx's own regular outputs |
| `DelegateToTopTx` | No local SubTx index; TopTx handles settlement |

```math
0\le\text{index}<|\text{ownOutputs(body)}|
```

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

##### 2.1.4.2.1 [P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L60) - The index belongs to the declaring body

```math
\begin{aligned}
&\text{outputCoins}\ge\text{requiredRelease} \\
&\implies(\text{indexValid(body,index)}\iff0\le\text{index}<|\text{ownOutputs(body)}|)
\end{aligned}
```

Generate ordinary output sequences, including an empty sequence. For TopTx and SubTx separately, compare the isolated validator with the sequence-length predicate at the first, last and out-of-range positions. Existing outputs have sufficient ADA, so only index membership can fail.

<a id="ds-tx-settlement-destination-f01" name="ds-tx-settlement-destination-f01"></a>
<a id="ds-tx-settlement-output-index-f01" name="ds-tx-settlement-output-index-f01"></a>

##### 2.1.4.2.2 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L77) - The first missing own index is rejected

```math
\text{index}=|\text{ownOutputs(body)}|
\implies\text{RejectedWith(InvalidSettlementOutput)}
```

Starting from a valid proposal, select the index immediately after the final output. Test TopTx and each SubTx separately, require the exact index failure, then accept the unchanged control.

<a id="ds-tx-settlement-destination-f02" name="ds-tx-settlement-destination-f02"></a>
<a id="ds-tx-settlement-output-index-f02" name="ds-tx-settlement-output-index-f02"></a>

##### 2.1.4.2.3 [F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L100) - A SubTx cannot select TopTx's output

```math
\begin{aligned}
&|\text{ownOutputs(subTx)}|\le\text{index}<|\text{ownOutputs(topTx)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(subTx))}
\end{aligned}
```

Give TopTx one more output than its SubTx. The child selects the index that exists only in TopTx. The ledger rejects the child’s target; the parent’s larger sequence cannot satisfy it.

<a id="ds-tx-settlement-destination-f03" name="ds-tx-settlement-destination-f03"></a>
<a id="ds-tx-settlement-output-index-f03" name="ds-tx-settlement-output-index-f03"></a>

##### 2.1.4.2.4 [F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L121) - Collateral return is outside the ordinary output sequence

```math
\begin{aligned}
&\text{collateralReturn}\ne\varnothing \\
&\land\text{index}=|\text{ownOutputs(topTx)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(topTx))}
\end{aligned}
```

Use a genuinely phase-2-invalid transaction with collateral return. Select the index immediately after TopTx’s regular outputs, where collateral return receives its output reference. Reject that ordinary settlement target, then accept the control with a valid regular-output index.

<a id="ds-tx-settlement-destination-f04" name="ds-tx-settlement-destination-f04"></a>
<a id="ds-tx-settlement-output-index-f04" name="ds-tx-settlement-output-index-f04"></a>

##### 2.1.4.2.5 [F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L142) - A SubTx without outputs cannot settle locally

```math
\begin{aligned}
&\text{ownOutputs(subTx)}=\varnothing \\
&\land\text{releasedDeposits(subTx)}>0\land\text{localIndex}=0 \\
&\implies\text{RejectedWith(InvalidSettlementOutput(subTx))}
\end{aligned}
```

Start with a valid delegated final release. Replace delegation with local output zero, and remove TopTx’s now-unnecessary designation. The child has no output zero: reject precisely that index. The delegated control remains accepted.

<a id="ds-tx-settlement-destination-n01" name="ds-tx-settlement-destination-n01"></a>
<a id="ds-tx-settlement-output-index-n01" name="ds-tx-settlement-output-index-n01"></a>

##### 2.1.4.2.6 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L161) - The first and last own outputs are valid

```math
\begin{aligned}
&|\text{ownOutputs(body)}|>0 \\
&\land\text{index}\in\{0,|\text{ownOutputs(body)}|-1\} \\
&\implies\text{Accepted}
\end{aligned}
```

At both body levels, designate the first output and then the last output. Each choice uses fresh funded inputs and sufficient output coin.

<a id="ds-tx-settlement-destination-f05" name="ds-tx-settlement-destination-f05"></a>
<a id="ds-tx-settlement-output-index-f05" name="ds-tx-settlement-output-index-f05"></a>

##### 2.1.4.2.7 [F05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L175) - TopTx cannot select a SubTx's output

```math
\begin{aligned}
&|\text{ownOutputs(topTx)}|\le\text{index}<|\text{ownOutputs(subTx)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(topTx))}
\end{aligned}
```

Give a nested SubTx one more output than TopTx. The index exists in the child but not in TopTx, so a TopTx designation using it is rejected.

<a id="ds-tx-settlement-destination-f06" name="ds-tx-settlement-destination-f06"></a>
<a id="ds-tx-settlement-output-index-f06" name="ds-tx-settlement-output-index-f06"></a>

##### 2.1.4.2.8 [F06](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L194) - A SubTx cannot select a sibling's output

```math
\begin{aligned}
&|\text{ownOutputs(subTx)}|\le\text{index}<|\text{ownOutputs(sibling)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(subTx))}
\end{aligned}
```

Give the sibling one more output than the declaring SubTx. Both children release deposits, but each owns a separate output sequence. The declaring child cannot borrow the sibling’s longer sequence.

<a id="ds-tx-settlement-destination-n02" name="ds-tx-settlement-destination-n02"></a>
<a id="ds-tx-settlement-output-index-n02" name="ds-tx-settlement-output-index-n02"></a>

##### 2.1.4.2.9 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L215) - Valid output indices when phase 2 fails

```math
\begin{aligned}
&\text{phase2Invalid} \\
&\land(\forall\,\text{body}:0\le\text{selectedIndex(body)}<|\text{ownOutputs(body)}|) \\
&\implies\text{Accepted}
\end{aligned}
```

Use a real failing script and designate the final own regular output at both body levels. The ordinary indices are validated even though the collateral outcome does not create those ordinary outputs.

<a id="ds-tx-settlement-destination-f07" name="ds-tx-settlement-destination-f07"></a>
<a id="ds-tx-settlement-output-index-f07" name="ds-tx-settlement-output-index-f07"></a>

##### 2.1.4.2.10 [F07](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L229) - An invalid output index still fails when phase 2 fails

```math
\begin{aligned}
&\text{phase2Invalid}\land\text{selectedIndex(body)}=|\text{ownOutputs(body)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput)}
\end{aligned}
```

From a valid phase-2-invalid control, replace one index with the first out-of-range index. Exercise TopTx and each SubTx separately while keeping collateral valid. The invalid outcome flag does not waive ordinary index validation.

<a id="ds-tx-attribution-n03" name="ds-tx-attribution-n03"></a>
<a id="ds-tx-settlement-participation-n09" name="ds-tx-settlement-participation-n09"></a>
<a id="ds-tx-settlement-output-index-n03" name="ds-tx-settlement-output-index-n03"></a>

##### 2.1.4.2.11 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L253) - A SubTx without outputs delegates its final release

```math
\begin{aligned}
&\text{ownOutputs(subTx)}=\varnothing \\
&\land\text{releasedDeposits(subTx)}>0 \\
&\land\text{delegatesReleaseToTopTx(subTx)} \\
&\implies\text{Accepted}
\end{aligned}
```

The SubTx spends its final deposit-backed inputs and creates no replacement output. Its exact release declaration uses `DelegateToTopTx`; there is no local index to resolve. TopTx declares the exact total and designates a sufficiently funded output of its own. The signed transaction is accepted, and its SubTx output sequence is checked to remain empty.

<a id="ds-tx-settlement-coverage" name="ds-tx-settlement-coverage"></a>
<a id="ds-tx-settlement-refinement" name="ds-tx-settlement-refinement"></a>
<a id="ds-tx-settlement-output-coin" name="ds-tx-settlement-output-coin"></a>

#### 2.1.4.3 Output coin

> **Check the ADA already present in the selected output.**
>
> $`\text{serializedADA(selectedOutput)}\ge\text{requiredSettlement(body)}`$.
> External deposits do not count toward this bound.

**Decision:** Agreed.

Assume the required designation is present and its index resolves to an existing
output. This rule then compares two amounts:

| Amount | TopTx | SubTx settling locally |
| --- | --- | --- |
| Required settlement | $`\max(0,-\text{attributedTopTxChange})`$ | The SubTx's declared release |
| Available coin | Serialized ADA in the selected TopTx output | Serialized ADA in the selected SubTx output |

The selected min-ADA output contributes its full serialized coin value, including
its embedded reserve. A deposit-backed output contributes its application ADA.
Its externally held deposit stays in the Store.

Example: TopTx's required share is 2 ADA.

| Selected output | Serialized ADA | External deposit | Result |
| --- | ---: | ---: | --- |
| Implicit | 2 ADA | — | Accepted |
| Implicit | 4 ADA | — | Accepted |
| Deposit-backed | 2 ADA | 1 ADA | Accepted |
| Deposit-backed | 1 ADA | 1 ADA | Rejected |

The last row still lacks one application ADA. The external deposit cannot fill the
shortfall. TopTx's required share may be smaller or larger than the transaction's
net backing release. The selected output must cover the **share**.

For a local release, the SubTx author signs the destination output and its final
value. The ledger verifies that the declared release equals the SubTx's net
release and that the selected output contains at least that amount in ADA.
The signed output already includes the refund. The [batch balance](#ds-tx-accounting-balance)
allows the author to contribute any remaining surplus to TopTx fees or another body.

For example, a SubTx spends two deposit-backed inputs carrying 10 ADA in total
application value and 4 ADA in total external deposits. It creates one
deposit-backed output requiring 2 ADA of external deposit. With no other SubTx
flows, it declares a 2 ADA release to that output. Signing an output of 12 ADA
returns all available application ADA to the recipient. Signing an output of
10 ADA leaves 2 ADA available to the batch. Both outputs satisfy the 2 ADA
settlement bound.

**Test conditions:** Declarations, designations and indices are valid. Ledger cases
preserve complete transaction balance, including rejection cases; a shortfall in
the selected output is moved to another output. Both body levels are exercised.
Phase-2 cases use a real failing script and valid collateral. One unit in a boundary
comparison means one lovelace.

<a id="ds-tx-settlement-coverage-p01" name="ds-tx-settlement-coverage-p01"></a>
<a id="ds-tx-settlement-output-coin-p01" name="ds-tx-settlement-output-coin-p01"></a>

##### 2.1.4.3.1 [P01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L43) - Output ADA must cover the required share

```math
\text{passesOutputCoinValidation}
\iff\text{serializedADA(selectedOutput)}\ge\text{requiredSettlement(body)}
```

Compare the isolated output-coin validator with the independent lower-bound predicate. Generate exact amounts, surplus and shortfall for TopTx and SubTx, using both min-ADA and deposit-backed outputs. This equivalence concerns output coin only.

<a id="ds-tx-settlement-coverage-f01" name="ds-tx-settlement-coverage-f01"></a>
<a id="ds-tx-settlement-output-coin-f01" name="ds-tx-settlement-output-coin-f01"></a>

##### 2.1.4.3.2 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L56) - Min-ADA output, one lovelace short

```math
\begin{aligned}
&\text{implicit(selectedOutput)} \\
&\land\text{serializedADA(selectedOutput)}=\text{requiredSettlement(body)}-1 \\
&\implies\text{RejectedWith(InsufficientSettlementOutput)}
\end{aligned}
```

The index exists and all declarations are exact. Move one lovelace from the designated min-ADA output to another output, then require the output-coin failure.

<a id="ds-tx-settlement-coverage-n01" name="ds-tx-settlement-coverage-n01"></a>
<a id="ds-tx-settlement-output-coin-n01" name="ds-tx-settlement-output-coin-n01"></a>

##### 2.1.4.3.3 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L77) - Min-ADA output, exact amount

```math
\text{implicit(selectedOutput)}
\land\text{serializedADA(selectedOutput)}=\text{requiredSettlement(body)}
\implies\text{Accepted}
```

Exact equality is sufficient. Test the boundary for TopTx and for a SubTx settling locally.

<a id="ds-tx-settlement-coverage-n02" name="ds-tx-settlement-coverage-n02"></a>
<a id="ds-tx-settlement-output-coin-n02" name="ds-tx-settlement-output-coin-n02"></a>

##### 2.1.4.3.4 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L97) - Min-ADA output, extra ADA

```math
\text{implicit(selectedOutput)}
\land\text{serializedADA(selectedOutput)}>\text{requiredSettlement(body)}
\implies\text{Accepted}
```

The selected min-ADA output may contain additional ADA. Its coin value need not equal the required share.

<a id="ds-tx-settlement-coverage-f02" name="ds-tx-settlement-coverage-f02"></a>
<a id="ds-tx-settlement-output-coin-f02" name="ds-tx-settlement-output-coin-f02"></a>

##### 2.1.4.3.5 [F02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L117) - An external deposit cannot fill the ADA shortfall

```math
\begin{aligned}
&\text{depositBacked(selectedOutput)} \\
&\land\text{serializedADA(selectedOutput)}=\text{requiredSettlement(body)}-1 \\
&\land\text{serializedADA(selectedOutput)}+\text{externalDeposit(selectedOutput)}
  \ge\text{requiredSettlement(body)} \\
&\implies\text{RejectedWith(InsufficientSettlementOutput)}
\end{aligned}
```

Select a deposit-backed output whose application ADA is one lovelace short. Even though adding its external deposit would exceed the required amount, the ledger rejects the application-ADA shortfall.

<a id="ds-tx-settlement-coverage-n03" name="ds-tx-settlement-coverage-n03"></a>
<a id="ds-tx-settlement-output-coin-n03" name="ds-tx-settlement-output-coin-n03"></a>

##### 2.1.4.3.6 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L140) - Deposit-backed output, exact application ADA

```math
\text{depositBacked(selectedOutput)}
\land\text{serializedADA(selectedOutput)}=\text{requiredSettlement(body)}
\implies\text{Accepted}
```

Allocate the external deposit independently and place exactly the required settlement amount in the output’s application ADA. The separate deposit does not increase or reduce the bound.

<a id="ds-tx-settlement-coverage-n04" name="ds-tx-settlement-coverage-n04"></a>
<a id="ds-tx-settlement-output-coin-n04" name="ds-tx-settlement-output-coin-n04"></a>

##### 2.1.4.3.7 [N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L161) - TopTx's share is smaller than the transaction release

```math
\begin{aligned}
&0<\text{topTxSettlement}<\text{transactionRelease} \\
&\land\text{serializedADA(selectedTopTxOutput)}=\text{topTxSettlement} \\
&\implies\text{Accepted}
\end{aligned}
```

For example, the transaction releases 5 ADA: a SubTx settles 3 ADA locally and TopTx settles 2 ADA. A selected TopTx output containing 2 ADA is sufficient; it need not contain all 5 ADA.

<a id="ds-tx-settlement-coverage-n05" name="ds-tx-settlement-coverage-n05"></a>
<a id="ds-tx-settlement-output-coin-n05" name="ds-tx-settlement-output-coin-n05"></a>

##### 2.1.4.3.8 [N05](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L177) - Exact output ADA when phase 2 fails

```math
\text{phase2Invalid}
\land\text{serializedADA(selectedOutput)}=\text{requiredSettlement(body)}
\implies\text{Accepted}
```

Use a real failing script with exactly the required coin in the designated ordinary output. Its proposed output-coin check passes before the collateral outcome, although ordinary outputs are not applied.

<a id="ds-tx-settlement-coverage-f03" name="ds-tx-settlement-coverage-f03"></a>
<a id="ds-tx-settlement-output-coin-f03" name="ds-tx-settlement-output-coin-f03"></a>

##### 2.1.4.3.9 [F03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L197) - One lovelace short when phase 2 fails

```math
\begin{aligned}
&\text{phase2Invalid} \\
&\land\text{serializedADA(selectedOutput)}=\text{requiredSettlement(body)}-1 \\
&\implies\text{RejectedWith(InsufficientSettlementOutput)}
\end{aligned}
```

From the valid phase-2-invalid controls, move one lovelace out of the selected output. The declared invalid script outcome does not excuse insufficient ordinary output coin.

<a id="ds-tx-settlement-coverage-f04" name="ds-tx-settlement-coverage-f04"></a>
<a id="ds-tx-settlement-output-coin-f04" name="ds-tx-settlement-output-coin-f04"></a>

##### 2.1.4.3.10 [F04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L219) - The transaction release is smaller than TopTx's share

```math
\begin{aligned}
&\text{transactionRelease}<\text{topTxSettlement} \\
&\land\text{serializedADA(selectedTopTxOutput)}=\text{transactionRelease} \\
&\implies\text{RejectedWith(InsufficientSettlementOutput)}
\end{aligned}
```

A SubTx allocation of 3 ADA and a TopTx release of 5 ADA produce a transaction release of 2 ADA. A TopTx output containing only 2 ADA fails: its required share is 5 ADA. Put the other 3 ADA elsewhere so the rejection isolates the selected output’s shortfall.

<a id="ds-tx-application-assets" name="ds-tx-application-assets"></a>
<a id="ds-tx-minimum-coin" name="ds-tx-minimum-coin"></a>

### 2.1.5 Minimum coin

> **Both output forms use the active deposit formula; only the funding location differs.**

Let $`F_S`$ be the Store's current [deposit formula](domain-model.md#ds-pricing). For each proposed
output $`o`$, including a min-ADA collateral return:

```math
\text{minimumCoin}_S(o)=
\begin{cases}
F_S(o) & \text{if }o\text{ is a MinAdaTxOut} \\
0 & \text{if }o\text{ is a DepositBackedTxOut}
\end{cases}
```

| Output form | Deposit funding | Minimum output ADA |
| --- | --- | --- |
| `MinAdaTxOut` | Inside the output | $`F_S(o)`$ |
| `DepositBackedTxOut` | External Store deposit of $`F_S(o)`$ | $`0`$ |

A newly proposed min-ADA output must satisfy $`\text{outputADA}(o)\geq F_S(o)`$.
This requirement is **uncapped**. The capped historical reserve of an existing or
migrated entry is a consumption query, not the test for admitting a new output.
`DepositBackedTxOut` still requires its
[allocation declaration](#ds-tx-declarations-requirements-operations-allocation),
[exact deposit accounting](#ds-tx-accounting-net-change-subtx), and other output constraints.

TopTx and SubTx validation read `currentFormula` from the Store, so the bound
changes after a V2 activation. The parameter-only `getMinCoinTxOut` and
`getMinCoinSizedTxOut` helpers use V1 at the supplied `coinsPerUTxOByte`; they
cannot select V2 without Store history. Builders needing the active bound use:

```haskell
toCoin $ Formula.computeDeposit (Store.currentFormula store) proposedMinAdaOutput
```

Here `Formula` is [`Dijkstra.UTxOs.Deposit.Formula`](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/Formula.hs).
Earlier eras retain their existing minimum-coin rules.

**Common premises:** valid addresses, nonnegative assets, exact declarations and fully
funded transactions. Each generated sample exercises both TopTx and SubTx outputs,
with successful phase 2 and with a real failing script. On the latter path,
**Accepted** means that the ledger accepts the collateral outcome; ordinary outputs
are checked but not created.

<a id="ds-tx-application-assets-n01" name="ds-tx-application-assets-n01"></a>
<a id="ds-tx-minimum-coin-n01" name="ds-tx-minimum-coin-n01"></a>

#### 2.1.5.1 [N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L47) - Native assets without ADA

```math
\begin{aligned}
&\text{depositBacked(output)} \\
&\land\text{nativeAssets(output)}\neq\varnothing
\land\text{applicationADA(output)}=0 \\
&\implies\text{Accepted}
\end{aligned}
```

The output carries tokens and zero lovelace. Its full deposit is funded externally,
so it needs no application ADA to pay for storage.

<a id="ds-tx-application-assets-n02" name="ds-tx-application-assets-n02"></a>
<a id="ds-tx-minimum-coin-n02" name="ds-tx-minimum-coin-n02"></a>

#### 2.1.5.2 [N02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L61) - Datum or reference script without assets

```math
\begin{aligned}
&\text{depositBacked(output)}\land\text{applicationAssets(output)}=\varnothing \\
&\land\text{payload(output)}\in\{\text{datumOnly},\text{referenceScriptOnly}\} \\
&\implies\text{Accepted}
\end{aligned}
```

Exercise both payload forms in every sample. Neither output carries ADA or tokens;
the datum or script bytes still contribute to its fully funded external deposit.

<a id="ds-tx-application-assets-n03" name="ds-tx-application-assets-n03"></a>
<a id="ds-tx-minimum-coin-n03" name="ds-tx-minimum-coin-n03"></a>

#### 2.1.5.3 [N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L75) - Address-only output

```math
\text{depositBacked(output)}\land\text{addressOnly(output)}
\implies\text{Accepted}
```

Here, address-only means:

```math
\begin{aligned}
\text{addressOnly(output)}\iff{}&\text{applicationAssets(output)}=\varnothing \\
&\land\neg\text{hasDatum(output)}\land\neg\text{hasReferenceScript(output)}
\end{aligned}
```

The output retains its address and required encoding fields. It still occupies
storage and requires its full deposit; mandatory fields are not removed.

<a id="ds-tx-application-assets-n04" name="ds-tx-application-assets-n04"></a>
<a id="ds-tx-minimum-coin-n04" name="ds-tx-minimum-coin-n04"></a>

#### 2.1.5.4 [N04](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L89) - Exact minimum for a min-ADA output

```math
\begin{aligned}
&\text{implicit(output)} \\
&\land\text{outputADA(output)}=\text{minimumCoin(output)} \\
&\implies\text{Accepted}
\end{aligned}
```

The active-formula minimum is inclusive. Count the output's assets and payload
bytes independently, then submit it with exactly that amount. This is the accepted
control for F01.

<a id="ds-tx-application-assets-f01" name="ds-tx-application-assets-f01"></a>
<a id="ds-tx-minimum-coin-f01" name="ds-tx-minimum-coin-f01"></a>

#### 2.1.5.5 [F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L99) - Min-ADA output one lovelace short

```math
\begin{aligned}
&\text{implicit(output)} \\
&\land\text{outputADA(output)}=\text{minimumCoin(output)}-1 \\
&\implies\text{Rejected}
\end{aligned}
```

Move one lovelace from the exact-minimum output into another valid output,
preserving financial balance. Its assets, datum and script are unchanged, so the
active-formula bound is unchanged. The ledger must reject only the owner body's
existing minimum-coin failure, identifying that output and its required amount:

| Output owner | Expected failure |
| --- | --- |
| TopTx | `BabbageOutputTooSmallUTxO` |
| SubTx | `SubBabbageOutputTooSmallUTxO` |

Submit the original exact-minimum transaction afterward and require acceptance,
confirming that the one-lovelace shortfall caused the rejection.

<a id="ds-collateral" name="ds-collateral"></a>

## 2.2 Collateral

> **Use the existing collateral fields; account for the deposits held outside outputs.**
>
> `TxOut era` already expresses min-ADA and deposit-backed inputs and returns. No separate collateral Store declaration is needed.

TopTx supplies the shared set of collateral inputs, at most one collateral return,
and an optional total. Inputs remain `TxIn` references: the ledger resolves each
output and its recorded deposit. SubTxs use this same collateral arrangement.

| Store responsibility | Question answered |
| --- | --- |
| [Funding](#ds-collateral-funding) | Do input coins cover the return, additional deposit and minimum fee? |
| [Total](#ds-collateral-total) | Does the optional total exclude released deposits and include coin-funded deposits? |
| [Assets](#ds-collateral-assets) | Are native assets preserved across both output representations? |

Applied allocation records and balances belong to [Ledger effects](ledger-effects.md#ds-state).
[Fees](ledger-effects.md#ds-state-fees) owns released-deposit surplus;
[Conservation](ledger-effects.md#ds-state-conservation) checks the resulting monetary total.

<a id="ds-collateral-existing-rules" name="ds-collateral-existing-rules"></a>
<a id="ds-collateral-scope" name="ds-collateral-scope"></a>
<a id="221-scope" name="221-scope"></a>
<a id="ds-collateral-authorization" name="ds-collateral-authorization"></a>
<a id="222-authorization" name="222-authorization"></a>

**Existing collateral rules**

The [Dijkstra Imp suite](../../../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Imp.hs#L38)
inherits the [Conway](../../../eras/conway/impl/testlib/Test/Cardano/Ledger/Conway/Imp.hs#L55),
[Babbage](../../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp.hs#L36)
and [Alonzo](../../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp.hs#L31)
suites. These are shared tests executed with Dijkstra, not tests to duplicate under
DepositStore. Their collateral fixtures use min-ADA outputs; Deposit-backed
integration remains a separate coverage obligation.

| Contract | Existing executable reference | Scope of that evidence |
| --- | --- | --- |
| Every collateral input resolves to an unspent output | Alonzo UTXO: [unknown input](../../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxoSpec.hs#L47), [already spent](../../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxoSpec.hs#L57) | Rejects bad references in Dijkstra too. |
| Collateral covers the fee percentage, even if scripts succeed | Alonzo UTXO: [insufficient collateral](../../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxoSpec.hs#L92) | Existing percentage and ceiling rule; no external deposits. |
| Each collateral payment key supplies its witness | Alonzo UTXOW: [missing collateral witness](../../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxowSpec/Invalid.hs#L205) | Missing witness for a min-ADA input. |
| A supplied total equals input coins minus return coins | Babbage UTXOS: [incorrect collateral total](../../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp/UtxosSpec.hs#L155) | Mismatch rejected with successful scripts; min-ADA return. |
| Phase-2 failure can return collateral without a supplied total | Babbage UTXOW: [use a collateral output](../../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp/UtxowSpec/Invalid.hs#L125) | Accepted failure-path min-ADA return; omission is incidental coverage. |
| Return-output validity is checked without redeemers | Dijkstra UTXO: [pointer address in collateral return](../../../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Imp/UtxoSpec.hs#L54) | Rejects an invalid address; does not cover the minimum-coin or input-count boundaries. |

These links establish test ownership and registration, not a new passing run.
`disableInConformanceIt` retains the implementation check while disabling its
[conformance comparison](../../../eras/shelley/impl/testlib/Test/Cardano/Ledger/Shelley/ImpTest.hs#L852).
Recorded executions remain in the [verification record](../verification.md).

The shared trigger is (`subTxRedeemers` is the union of all children’s redeemers):

```math
\left(\mathit{topTxRedeemers}\ne\varnothing\ \lor\ \mathit{subTxRedeemers}\ne\varnothing\right)
\implies \mathit{collateralInputs}\ne\varnothing
```

It activates funding, supplied-total, key-locked eligibility and native-asset
checks. Input resolution, payment-key witnesses, return-output validity and the
input-count limit remain independently required. Script success does not waive
validation; [Execution](ledger-effects.md#ds-state-execution) determines which effects apply.

**Shared regressions still to add or extend**

The contracts below remain required regressions in the shared collateral suites.
The inherited references above do not establish these missing cases.
Each regression keeps unrelated inputs, declarations, script purposes and witnesses
valid, and includes an accepted control.

| Contract | Missing regression |
| --- | --- |
| <a id="ds-collateral-scope-f01" name="ds-collateral-scope-f01"></a><a id="2211-f01---rejects-toptx-redeemers-without-collateral" name="2211-f01---rejects-toptx-redeemers-without-collateral"></a>TopTx alone has redeemers $`\implies`$ collateral is required. | A real, correctly witnessed TopTx script without collateral must produce `NoCollateralInputs`; include a funded control and both script outcomes. Empty collateral may also produce a funding failure. |
| <a id="ds-collateral-scope-f02" name="ds-collateral-scope-f02"></a><a id="2212-f02---rejects-subtx-redeemers-without-collateral-even-when-toptx-has-none" name="2212-f02---rejects-subtx-redeemers-without-collateral-even-when-toptx-has-none"></a>Only a SubTx has redeemers $`\implies`$ shared collateral is required. | Use a correctly indexed child redeemer with no parent redeemers; require `NoCollateralInputs`, with a funded control and both script outcomes. |
| <a id="ds-collateral-scope-f03" name="ds-collateral-scope-f03"></a><a id="2213-f03---rejects-redeemers-in-both-toptx-and-subtxs-without-collateral" name="2213-f03---rejects-redeemers-in-both-toptx-and-subtxs-without-collateral"></a>Both levels have redeemers $`\implies`$ shared collateral is required. | The combined case must also produce `NoCollateralInputs`; having both locations cannot cancel the trigger. |
| <a id="ds-collateral-scope-n02" name="ds-collateral-scope-n02"></a><a id="2215-n02---does-not-apply-redeemer-gated-funding-or-supplied-total-checks-when-no-body-has-redeemers" name="2215-n02---does-not-apply-redeemer-gated-funding-or-supplied-total-checks-when-no-body-has-redeemers"></a>No body has redeemers $`\implies`$ skip gated funding and supplied-total comparisons. | Supply resolved inputs and a valid return; independently underfund the potential fee, mismatch the total, then combine both. Other rules still hold; ordinary acceptance is expected. |
| <a id="ds-collateral-scope-f04" name="ds-collateral-scope-f04"></a><a id="2216-f04---rejects-independently-invalid-collateral-inputs-or-returns-without-redeemers" name="2216-f04---rejects-independently-invalid-collateral-inputs-or-returns-without-redeemers"></a>No redeemers does not waive independent input, return or count checks. | Unknown-input coverage exists above. Add a min-ADA return one lovelace below minimum and too many collateral inputs, each with a valid control. |
| <a id="ds-collateral-authorization-f01" name="ds-collateral-authorization-f01"></a><a id="2221-f01---rejects-a-script-controlled-collateral-input-when-collateral-validation-applies" name="2221-f01---rejects-a-script-controlled-collateral-input-when-collateral-validation-applies"></a>Active collateral validation $`\implies`$ inputs are key-locked. | Reject script-controlled collateral with `ScriptsNotPaidUTxO` for both output forms and script outcomes, even with a valid script witness. Use that script for an ordinary purpose too, so its witness is not extraneous. The control uses a signed key-controlled input. |
| <a id="ds-collateral-authorization-f02" name="ds-collateral-authorization-f02"></a><a id="2222-f02---rejects-a-key-controlled-collateral-input-whose-required-payment-key-witness-is-missing" name="2222-f02---rejects-a-key-controlled-collateral-input-whose-required-payment-key-witness-is-missing"></a>Every collateral payment key must witness the transaction. | Extend the existing witness case to Deposit-backed inputs, both script outcomes and the no-redeemer path. Remove only a collateral key witness that no ordinary input needs; restoring it must accept. |

<a id="ds-collateral-scope-n01" name="ds-collateral-scope-n01"></a><a id="2214-n01---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore" name="2214-n01---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore"></a><a id="ds-collateral-funding-n09" name="ds-collateral-funding-n09"></a><a id="22116-n09---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore" name="22116-n09---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore"></a><a id="ds-collateral-store-activity-control" name="ds-collateral-store-activity-control"></a>

The successful path of [Minimum coin N03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L75)
already accepts an address-only Deposit-backed output with its allocation declared.
It is the existing control for Store activity without redeemers. **Remaining
extension:** explicitly assert empty redeemers and empty collateral inputs in that
prepared transaction; acceptance alone does not prove both fields are absent.
Deposit-backed fixture extensions should reuse the shared rule cases. The existing Babbage
[return fixup](../../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/ImpTest.hs#L92)
currently rejects `DepositBackedTxOut`, so inherited implicit fixtures do not supply
that extension automatically.

<a id="ds-collateral-funding" name="ds-collateral-funding"></a>
<a id="223-funding" name="223-funding"></a>
<a id="ds-collateral-settlement" name="ds-collateral-settlement"></a>
<a id="226-settlement" name="226-settlement"></a>

### 2.2.1 Funding

> **Input coins fund the return, any deposit shortfall and the minimum fee.**
>
> Released deposits cover the return’s deposit first. Their surplus cannot pay the minimum fee or enlarge the return.

The [shared redeemer trigger](#ds-collateral-existing-rules) activates these checks,
including when scripts succeed. Acceptance and rejection cases keep unrelated
collateral and ordinary rules valid. P02 isolates the collateral calculation.

| Quantity | Meaning |
| --- | --- |
| $`\mathit{inputCoins}`$ | Full ADA of min-ADA collateral inputs plus application ADA of Deposit-backed inputs. |
| $`\mathit{returnCoins}`$ | ADA in the specified collateral return; zero when absent. |
| $`\mathit{releasedDeposits}`$ | Recorded deposits belonging to Deposit-backed collateral inputs; min-ADA inputs contribute zero. |
| $`\mathit{returnDeposit}`$ | Deposit priced from the submitted Deposit-backed return; zero for an absent or min-ADA return. |

```math
\begin{aligned}
\mathit{additionalDeposit}&=\max(0,\mathit{returnDeposit}-\mathit{releasedDeposits})\\
\mathit{coinFee}&=\mathit{inputCoins}-\mathit{returnCoins}-\mathit{additionalDeposit}\\
\mathit{minimumFee}&=\left\lceil\frac{\mathit{txFee}\cdot\mathit{collateralPercentage}}{100}\right\rceil
\end{aligned}
```

```math
\mathit{coinFee}\ge\mathit{minimumFee}
\quad\Longleftrightarrow\quad\text{Funding accepted}
```

The ledger derives these amounts from collateral inputs and return; no collateral
Store declaration is supplied. The same terms determine
$`\mathit{storeChange}=\mathit{returnDeposit}-\mathit{releasedDeposits}`$.
[Ledger effects](ledger-effects.md#ds-state) checks application of that change.

**Example — 1 ADA minimum fee**

| Input coins | Return coins | Released deposit | Return deposit | Additional deposit | Coin fee | Funding |
| ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 5 | 3 | 1 | 2 | 1 | 1 | Accept |
| 5 | 4 | 1 | 2 | 1 | 0 | Reject |
| 5 | 5 | 2 | 1 | 0 | 0 | Reject, despite 1 ADA released surplus |

The last row conserves ADA once surplus reaches fees, but still fails the
independently funded minimum. [Fees](ledger-effects.md#ds-state-fees) owns that surplus destination.

**Generated cases**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="2232-n01---accepts-a-batch-whose-scripts-succeed-when-its-required-collateral-is-fully-funded-and-all-other-rules-hold" name="2232-n01---accepts-a-batch-whose-scripts-succeed-when-its-required-collateral-is-fully-funded-and-all-other-rules-hold"></a><a id="ds-collateral-funding-n01" name="ds-collateral-funding-n01"></a><a id="2212-n01---accepts-a-fully-funded-store-backed-return-when-all-scripts-succeed" name="2212-n01---accepts-a-fully-funded-store-backed-return-when-all-scripts-succeed"></a><a id="2233-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns" name="2233-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns"></a><a id="ds-collateral-funding-n02" name="ds-collateral-funding-n02"></a><a id="2213-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns" name="2213-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns"></a><a id="2234-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount" name="2234-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount"></a><a id="ds-collateral-funding-n03" name="ds-collateral-funding-n03"></a><a id="2214-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount" name="2214-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount"></a><a id="2235-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins" name="2235-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins"></a><a id="ds-collateral-funding-n04" name="ds-collateral-funding-n04"></a><a id="2215-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins" name="2215-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins"></a><a id="2237-p01---collateral-coins-cover-the-minimum" name="2237-p01---collateral-coins-cover-the-minimum"></a><a id="ds-collateral-funding-p01" name="ds-collateral-funding-p01"></a><a id="2217-p01---collateral-coins-cover-the-minimum" name="2217-p01---collateral-coins-cover-the-minimum"></a><a id="22311-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs" name="22311-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs"></a><a id="ds-collateral-funding-n05" name="ds-collateral-funding-n05"></a><a id="22111-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs" name="22111-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs"></a><a id="22312-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs" name="22312-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs"></a><a id="ds-collateral-funding-n06" name="ds-collateral-funding-n06"></a><a id="22112-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs" name="22112-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs"></a><a id="22313-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded" name="22313-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded"></a><a id="ds-collateral-funding-n07" name="ds-collateral-funding-n07"></a><a id="22113-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded" name="22113-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded"></a><a id="22315-n08---accepts-collateral-funding-exactly-at-a-rounded-up-minimum-fee" name="22315-n08---accepts-collateral-funding-exactly-at-a-rounded-up-minimum-fee"></a><a id="ds-collateral-funding-n08" name="ds-collateral-funding-n08"></a><a id="22115-n08---accepts-the-exact-rounded-up-minimum-fee-after-funding-the-returns-additional-deposit" name="22115-n08---accepts-the-exact-rounded-up-minimum-fee-after-funding-the-returns-additional-deposit"></a><a id="ds-collateral-settlement-n01" name="ds-collateral-settlement-n01"></a><a id="2261-n01---derives-store-changes-from-collateral-inputs-and-return-without-a-separate-declaration" name="2261-n01---derives-store-changes-from-collateral-inputs-and-return-without-a-separate-declaration"></a><a id="ds-collateral-funding-n10" name="ds-collateral-funding-n10"></a><a id="22117-n10---derives-deposit-funding-from-collateral-inputs-and-return-without-a-separate-declaration" name="22117-n10---derives-deposit-funding-from-collateral-inputs-and-return-without-a-separate-declaration"></a><a id="ds-collateral-settlement-n02" name="ds-collateral-settlement-n02"></a><a id="2263-n02---derives-the-released-store-amount-from-multiple-ada-only-collateral-inputs-with-no-return" name="2263-n02---derives-the-released-store-amount-from-multiple-ada-only-collateral-inputs-with-no-return"></a><a id="ds-collateral-funding-n11" name="ds-collateral-funding-n11"></a><a id="22119-n11---derives-released-deposits-from-mixed-ada-only-collateral-inputs-with-no-return" name="22119-n11---derives-released-deposits-from-mixed-ada-only-collateral-inputs-with-no-return"></a>**1.&nbsp;[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L56)** | **Funded collateral.** Cover the return, any positive deposit shortfall and the rounded-up minimum; include exact equality. | Accept with successful scripts or an accepted phase-2 failure. |
| <a id="2231-f01---rejects-insufficient-collateral-funding-when-redeemers-trigger-validation-even-if-all-scripts-succeed" name="2231-f01---rejects-insufficient-collateral-funding-when-redeemers-trigger-validation-even-if-all-scripts-succeed"></a><a id="ds-collateral-funding-f01" name="ds-collateral-funding-f01"></a><a id="2211-f01---rejects-an-underfunded-store-backed-return-even-when-all-scripts-succeed" name="2211-f01---rejects-an-underfunded-store-backed-return-even-when-all-scripts-succeed"></a><a id="2236-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits" name="2236-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits"></a><a id="ds-collateral-funding-f02" name="ds-collateral-funding-f02"></a><a id="2216-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits" name="2216-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits"></a><a id="2238-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus" name="2238-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="ds-collateral-funding-f03" name="ds-collateral-funding-f03"></a><a id="2218-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus" name="2218-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="2239-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus" name="2239-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="ds-collateral-funding-f04" name="ds-collateral-funding-f04"></a><a id="2219-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus" name="2219-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="22310-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee" name="22310-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee"></a><a id="ds-collateral-funding-f05" name="ds-collateral-funding-f05"></a><a id="22110-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee" name="22110-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee"></a><a id="22314-f06---rejects-underfunded-collateral-when-the-optional-total-is-absent" name="22314-f06---rejects-underfunded-collateral-when-the-optional-total-is-absent"></a><a id="ds-collateral-funding-f06" name="ds-collateral-funding-f06"></a><a id="22114-f06---rejects-an-underfunded-store-backed-return-when-the-optional-total-is-absent" name="22114-f06---rejects-an-underfunded-store-backed-return-when-the-optional-total-is-absent"></a>**2.&nbsp;[F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L78)** | **Underfunded collateral.** Set the coin fee below the minimum, including one lovelace below the ceiling, an absent total, an oversized return and no-return Store inputs carrying zero application ADA. | Reject only with `InsufficientCollateral`; funded controls accept. |
| <a id="ds-collateral-settlement-p01" name="ds-collateral-settlement-p01"></a><a id="2262-p01---derived-collateral-store-change-is-independent-of-ordinary-store-declarations" name="2262-p01---derived-collateral-store-change-is-independent-of-ordinary-store-declarations"></a><a id="ds-collateral-funding-p02" name="ds-collateral-funding-p02"></a><a id="22118-p02---ordinary-declarations-do-not-change-collateral-deposit-funding" name="22118-p02---ordinary-declarations-do-not-change-collateral-deposit-funding"></a>**3.&nbsp;[P02](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L128)** | **Independent ordinary declarations.** Keep collateral inputs, return, fee and prices fixed; vary ordinary declaration forms in the isolated calculation. | The released deposits, return deposit and additional funding stay unchanged. |
| <a id="ds-collateral-funding-p03" name="ds-collateral-funding-p03"></a>**4.&nbsp;[P03](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L152)** | **Min-ADA return at the active minimum.** Activate V1 or V2 after funding the collateral input. Vary the return's inline datum size; preserve the input's historical release and re-sign each proposal. | Exact current-formula ADA accepts; one lovelace below rejects only with `BabbageOutputTooSmallUTxO`. |

P02 observes only the collateral calculation; its arbitrary ordinary declarations
are not submitted as ledger transactions.

For P03, let $`r`$ be the proposed min-ADA return and $`F_S`$ the active formula:

```math
\begin{aligned}
\text{outputADA}(r)=F_S(r) &\implies \text{Accepted} \\
\text{outputADA}(r)=F_S(r)-1 &\implies \text{Rejected}
\end{aligned}
```

The fixture triggers a real phase-2 failure. Each mutation adjusts the supplied
collateral total consistently, so the rejection isolates the return's uncapped
[minimum-coin requirement](#ds-tx-minimum-coin).

The generated coverage distinguishes:

| Axis | Conditions exercised |
| --- | --- |
| Output representation | Min-ADA and deposit-backed inputs and returns, mixed input sets, absent return. Count implicit ADA once and release only recorded Store deposits. |
| Deposit relationship | Return deposit greater than, equal to or less than released deposits; no extra funding for equality, no Store deposit for a min-ADA return. |
| Recorded amount | Fund a Deposit-backed source at twice the current byte price, then lower the parameter before constructing the collateral proposal. Release the recorded amount; price the return at the current parameter. |
| Fee boundary | Exact rounded-up minimum, a funded margin and one lovelace below; a fractional-lovelace product distinguishes ceiling from floor. |
| Released excess | Cannot fund the minimum or a larger signed return; deposits of unspent outputs remain unavailable. |
| Zero application ADA | A Deposit-backed return may contain zero ADA when its external deposit and fee are funded. |
| Absent fields | An absent total does not waive funding. With no return, accept funded ADA-only mixed inputs; reject all-Store inputs with zero application ADA even when their recorded deposits exceed the minimum fee. Test both an absent total and an exact zero total. |
| Script outcome | Successful scripts and genuine phase-2 failure use the same funding requirement. |

The inherited implicit-only tests provide the baseline. Each generated scenario
includes Store activity so that the external-deposit adjustment is exercised.
The changed-price fixture checks recorded-amount release only; it does not define
a governance, epoch-processing or historical-repricing policy.

<a id="ds-collateral-total" name="ds-collateral-total"></a>
<a id="225-total" name="225-total"></a>

### 2.2.2 Total

> **The optional total describes coins taken from collateral.**
>
> It includes coins funding an additional deposit and excludes deposits released from the Store.

The inherited [incorrect-total test](../../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp/UtxosSpec.hs#L155)
owns the generic comparison. These generated cases exercise it with Store
allocations or releases, keeping funding and other rules valid:

```math
\mathit{expectedTotal}=\mathit{inputCoins}-\mathit{returnCoins}
```

```math
\begin{aligned}
&\mathit{declaredTotal}\in\{\mathsf{Absent},\mathsf{Present}(\mathit{expectedTotal})\}\\
&\Longleftrightarrow\text{Total accepted}
\end{aligned}
```

For 5 ADA of input coins and a 2 ADA return, the total is 3 ADA. Funding a 1 ADA
additional deposit leaves 2 ADA for the coin fee. Released-deposit surplus can
increase the eventual fee credit without changing this declared total.

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="2251-n01---accepts-a-declared-total-equal-to-collateral-input-coins-minus-return-coins" name="2251-n01---accepts-a-declared-total-equal-to-collateral-input-coins-minus-return-coins"></a><a id="ds-collateral-total-n01" name="ds-collateral-total-n01"></a><a id="2221-n01---accepts-input-coins-minus-return-coins-as-the-total-with-store-allocations-or-releases" name="2221-n01---accepts-input-coins-minus-return-coins-as-the-total-with-store-allocations-or-releases"></a><a id="2254-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total" name="2254-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total"></a><a id="ds-collateral-total-n02" name="ds-collateral-total-n02"></a><a id="2224-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total" name="2224-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total"></a><a id="2255-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total" name="2255-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total"></a><a id="ds-collateral-total-n03" name="ds-collateral-total-n03"></a><a id="2225-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total" name="2225-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total"></a><a id="2256-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold" name="2256-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold"></a><a id="ds-collateral-total-n04" name="ds-collateral-total-n04"></a><a id="2226-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold" name="2226-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold"></a>**1.&nbsp;[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L31)** | **Absent or exact total.** Omit the field or supply input coins minus return coins, with additional deposit funding, released surplus or no return. | Accept for either script outcome; absence skips only the comparison. |
| <a id="2252-f01---rejects-a-declared-total-differing-by-one-lovelace-when-collateral-validation-applies" name="2252-f01---rejects-a-declared-total-differing-by-one-lovelace-when-collateral-validation-applies"></a><a id="ds-collateral-total-f01" name="ds-collateral-total-f01"></a><a id="2222-f01---rejects-a-total-differing-by-one-lovelace-with-store-allocations-or-releases" name="2222-f01---rejects-a-total-differing-by-one-lovelace-with-store-allocations-or-releases"></a><a id="2253-f02---rejects-an-incorrect-supplied-total-when-redeemers-trigger-collateral-validation-even-if-all-scripts-succeed" name="2253-f02---rejects-an-incorrect-supplied-total-when-redeemers-trigger-collateral-validation-even-if-all-scripts-succeed"></a><a id="ds-collateral-total-f02" name="ds-collateral-total-f02"></a><a id="2223-f02---rejects-an-incorrect-total-with-store-allocations-or-releases-even-when-all-scripts-succeed" name="2223-f02---rejects-an-incorrect-total-with-store-allocations-or-releases-even-when-all-scripts-succeed"></a>**2.&nbsp;[F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L43)** | **Incorrect total.** Supply a total one lovelace above or below the expected value while keeping Store funding correct. | Reject only with `IncorrectTotalCollateralField`, even when scripts succeed; the exact-total control accepts. |

Absence is distinct from a supplied zero: zero is valid only when it equals the expected total. [Funding F01](#ds-collateral-funding-f01) independently rejects a funding deficit when the field is absent.

<a id="ds-collateral-assets" name="ds-collateral-assets"></a>

### 2.2.3 Assets

> **Return every collateral native asset with its exact quantity.**
>
> The Store holds ADA; deposit funding cannot compensate for a missing application token.

When the [redeemer trigger](#ds-collateral-existing-rules) is active:

```math
\mathit{nativeAssets}(\mathit{collateralInputs})
=\mathit{nativeAssets}(\mathit{collateralReturn})
\quad\Longleftrightarrow\quad\text{Assets accepted}
```

An absent return contributes the empty asset map. These cases exercise
[`validateCollateralAssets`](../../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/DepositStore/Collateral.hs)
with a Deposit-backed input or return, including mixed inputs and both return forms.
Funding, output validity, witnesses and optional totals remain correct. Exercise
successful scripts and genuine phase-2 failure. The current generator mints one
policy and one token name, with a variable quantity repeated across the selected
inputs. Mixed-policy or distinct-token input maps remain an extension.

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-collateral-conservation-n02" name="ds-collateral-conservation-n02"></a><a id="2274-n02---accepts-native-asset-collateral-when-its-return-preserves-every-asset-and-quantity" name="2274-n02---accepts-native-asset-collateral-when-its-return-preserves-every-asset-and-quantity"></a><a id="ds-collateral-assets-n01" name="ds-collateral-assets-n01"></a><a id="2232-n01---accepts-matching-native-assets-when-collateral-inputs-or-return-are-store-backed" name="2232-n01---accepts-matching-native-assets-when-collateral-inputs-or-return-are-store-backed"></a>**1.&nbsp;[N01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AssetsSpec.hs#L35)** | **Exact asset map.** Return every input policy, asset name and quantity; include a funded Deposit-backed return with zero application ADA. | Accept for both output forms and script outcomes. |
| <a id="ds-collateral-conservation-f01" name="ds-collateral-conservation-f01"></a><a id="2273-f01---rejects-missing-added-or-changed-native-assets-in-the-collateral-return" name="2273-f01---rejects-missing-added-or-changed-native-assets-in-the-collateral-return"></a><a id="ds-collateral-assets-f01" name="ds-collateral-assets-f01"></a><a id="2231-f01---rejects-missing-added-or-changed-native-assets-when-collateral-inputs-or-return-are-store-backed" name="2231-f01---rejects-missing-added-or-changed-native-assets-when-collateral-inputs-or-return-are-store-backed"></a><a id="ds-collateral-conservation-f02" name="ds-collateral-conservation-f02"></a><a id="2275-f02---rejects-token-bearing-collateral-when-no-return-is-specified" name="2275-f02---rejects-token-bearing-collateral-when-no-return-is-specified"></a><a id="ds-collateral-assets-f02" name="ds-collateral-assets-f02"></a><a id="2233-f02---rejects-token-bearing-store-backed-collateral-when-no-return-is-specified" name="2233-f02---rejects-token-bearing-store-backed-collateral-when-no-return-is-specified"></a>**2.&nbsp;[F01](../../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AssetsSpec.hs#L48)** | **Missing or altered assets.** Remove an asset, add an absent asset, alter a quantity, or omit the return for token-bearing collateral. | Reject only with `CollateralContainsNonADA`; the unchanged asset-map control accepts. |

[Funding N01](#ds-collateral-funding-n01) supplies the ADA-only no-return acceptance
control. Ordinary outputs and unapplied minting cannot supply missing collateral assets.
