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
            <summary><a href="#ds-tx-grammar">2.1.1 Grammar</a></summary>
            <dl>
              <dd>
                <details>
                  <summary><a href="#ds-tx-grammar-toptx">2.1.1.1 TopTx</a></summary>
                  <dl>
                    <dd>
                      <details>
                        <summary><a href="#ds-tx-grammar-toptx-amounts">2.1.1.1.1 Amounts</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-p01">2.1.1.1.1.1 P01 - Positive amounts survive encoding</a><br>
                            <a href="#ds-tx-grammar-f01">2.1.1.1.1.2 F01 - Zero operation amount</a><br>
                            <a href="#ds-tx-grammar-f12">2.1.1.1.1.3 F12 - Negative operation amount</a><br>
                            <a href="#ds-tx-grammar-f13">2.1.1.1.1.4 F13 - Overflowing operation amount</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-grammar-toptx-absence">2.1.1.1.2 Absence</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-n03">2.1.1.1.2.1 N03 - Absence remains distinct from zero</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-grammar-toptx-forms">2.1.1.1.3 Forms</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-n05">2.1.1.1.3.1 N05 - Every TopTx declaration form</a><br>
                            <a href="#ds-tx-grammar-f06">2.1.1.1.3.2 F06 - Funding request in TopTx</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-grammar-toptx-structure">2.1.1.1.4 Structure</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-f02">2.1.1.1.4.1 F02 - Malformed declarations</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-grammar-toptx-destinations">2.1.1.1.5 Destinations</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-f04">2.1.1.1.5.1 F04 - Malformed release settlements</a><br>
                            <a href="#ds-tx-grammar-f14">2.1.1.1.5.2 F14 - Negative output index</a><br>
                            <a href="#ds-tx-grammar-f15">2.1.1.1.5.3 F15 - Overflowing output index</a><br>
                          </dd>
                        </dl>
                      </details>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-grammar-subtx">2.1.1.2 SubTx</a></summary>
                  <dl>
                    <dd>
                      <details>
                        <summary><a href="#ds-tx-grammar-subtx-amounts">2.1.1.2.1 Amounts</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-p02">2.1.1.2.1.1 P02 - Positive amounts survive encoding</a><br>
                            <a href="#ds-tx-grammar-f07">2.1.1.2.1.2 F07 - Zero operation amount</a><br>
                            <a href="#ds-tx-grammar-f08">2.1.1.2.1.3 F08 - Negative operation amount</a><br>
                            <a href="#ds-tx-grammar-f09">2.1.1.2.1.4 F09 - Overflowing operation amount</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-grammar-subtx-absence">2.1.1.2.2 Absence</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-n04">2.1.1.2.2.1 N04 - Absence remains distinct from zero</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-grammar-subtx-forms">2.1.1.2.3 Forms</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-n06">2.1.1.2.3.1 N06 - Every SubTx declaration form</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-grammar-subtx-structure">2.1.1.2.4 Structure</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-f03">2.1.1.2.4.1 F03 - Malformed declarations</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-grammar-subtx-destinations">2.1.1.2.5 Destinations</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-grammar-f05">2.1.1.2.5.1 F05 - Malformed release targets</a><br>
                            <a href="#ds-tx-grammar-f10">2.1.1.2.5.2 F10 - Negative output index</a><br>
                            <a href="#ds-tx-grammar-f11">2.1.1.2.5.3 F11 - Overflowing output index</a><br>
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
            <summary><a href="#ds-tx-presence">2.1.2 Presence</a></summary>
            <dl>
              <dd>
                <details>
                  <summary><a href="#ds-tx-presence-activity">2.1.2.1 Activity</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-presence-activity-p01">2.1.2.1.1 P01 - Every active body declares</a><br>
                      <details>
                        <summary><a href="#ds-tx-presence-activity-creation">2.1.2.1.2 Creation</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-presence-activity-creation-n01">2.1.2.1.2.1 N01 - accepts every explicit TopTx and SubTx declaration for creation presence, including zero and delegation</a><br>
                            <a href="#ds-tx-presence-activity-creation-n02">2.1.2.1.2.2 N02 - accepts absent declarations for empty or implicit-only own outputs</a><br>
                            <a href="#ds-tx-presence-activity-creation-f01">2.1.2.1.2.3 F01 - rejects a missing own declaration when a store-backed output appears at any own-output position</a><br>
                            <a href="#ds-tx-presence-activity-creation-n03">2.1.2.1.2.4 N03 - accepts a TopTx creating only implicit outputs without a declaration</a><br>
                            <a href="#ds-tx-presence-activity-creation-n04">2.1.2.1.2.5 N04 - accepts a SubTx creating only implicit outputs without either body's declaration</a><br>
                            <a href="#ds-tx-presence-activity-creation-f02">2.1.2.1.2.6 F02 - rejects a TopTx creating a store-backed output without its own declaration</a><br>
                            <a href="#ds-tx-presence-activity-creation-f03">2.1.2.1.2.7 F03 - rejects a SubTx creating a store-backed output without its own declaration</a><br>
                            <a href="#ds-tx-presence-activity-creation-f04">2.1.2.1.2.8 F04 - rejects a TopTx creating a store-backed output without its own declaration even when phase 2 fails</a><br>
                            <a href="#ds-tx-presence-activity-creation-f05">2.1.2.1.2.9 F05 - rejects a SubTx creating a store-backed output without its own declaration even when phase 2 fails</a><br>
                            <a href="#ds-tx-presence-activity-creation-f06">2.1.2.1.2.10 F06 - rejects a missing own declaration when spending a translated implicit output to create store-backed outputs</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-presence-activity-spending">2.1.2.1.3 Spending</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-presence-activity-spending-n01">2.1.2.1.3.1 N01 - Standalone TopTx, any output form</a><br>
                            <a href="#ds-tx-presence-activity-spending-n02">2.1.2.1.3.2 N02 - Standalone TopTx, only implicit outputs</a><br>
                            <a href="#ds-tx-presence-activity-spending-n03">2.1.2.1.3.3 N03 - One SubTx releases its deposit into its own output</a><br>
                            <a href="#ds-tx-presence-activity-spending-f01">2.1.2.1.3.4 F01 - TopTx omits its required declaration</a><br>
                            <a href="#ds-tx-presence-activity-spending-f02">2.1.2.1.3.5 F02 - TopTx declares, but the spending SubTx does not</a><br>
                            <a href="#ds-tx-presence-activity-spending-n04">2.1.2.1.3.6 N04 - Phase 2 fails with valid declarations</a><br>
                            <a href="#ds-tx-presence-activity-spending-f03">2.1.2.1.3.7 F03 - Missing spending declaration in a phase-2-invalid proposal</a><br>
                            <a href="#ds-tx-presence-activity-spending-n05">2.1.2.1.3.8 N05 - Several SubTxs release their deposits</a><br>
                            <a href="#ds-tx-presence-activity-spending-f04">2.1.2.1.3.9 F04 - One spending SubTx omits its declaration</a><br>
                            <a href="#ds-tx-presence-activity-spending-n06">2.1.2.1.3.10 N06 - Only some SubTxs consume Store deposits</a><br>
                            <a href="#ds-tx-presence-activity-spending-n07">2.1.2.1.3.11 N07 - TopTx and several SubTxs release deposits</a><br>
                            <a href="#ds-tx-presence-activity-spending-n08">2.1.2.1.3.12 N08 - Phase 2 fails with several spending SubTxs</a><br>
                            <a href="#ds-tx-presence-activity-spending-f05">2.1.2.1.3.13 F05 - One SubTx declaration is missing in a phase-2-invalid proposal</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-presence-activity-scope">2.1.2.1.4 Scope</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-presence-activity-scope-n01">2.1.2.1.4.1 N01 - accepts an absent TopTx declaration for creation presence when only its nested SubTx creates store-backed outputs</a><br>
                            <a href="#ds-tx-presence-activity-scope-n02">2.1.2.1.4.2 N02 - accepts an absent declaration for creation presence when only collateral return is store-backed</a><br>
                            <a href="#ds-tx-presence-activity-scope-n03">2.1.2.1.4.3 N03 - accepts an absent declaration for creation presence with reference or collateral input identifiers alone</a><br>
                            <a href="#ds-tx-presence-activity-scope-f01">2.1.2.1.4.4 F01 - rejects a missing TopTx declaration for its own store-backed outputs even when its nested SubTx declares</a><br>
                            <a href="#ds-tx-presence-activity-scope-f02">2.1.2.1.4.5 F02 - rejects a creating SubTx's missing declaration even when TopTx explicitly declares zero</a><br>
                            <a href="#ds-tx-presence-activity-scope-n04">2.1.2.1.4.6 N04 - does not require a declaration merely for referencing a store-backed output</a><br>
                            <a href="#ds-tx-presence-activity-scope-n05">2.1.2.1.4.7 N05 - does not treat collateral inputs or collateral return as ordinary Store activity</a><br>
                            <a href="#ds-tx-presence-activity-scope-n06">2.1.2.1.4.8 N06 - accepts Store activity in both TopTx and SubTx when each provides its own declaration</a><br>
                            <a href="#ds-tx-presence-activity-scope-f03">2.1.2.1.4.9 F03 - rejects a missing TopTx spending declaration even when a SubTx declares</a><br>
                          </dd>
                        </dl>
                      </details>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-presence-dependency">2.1.2.2 Dependency</a></summary>
                  <dl>
                    <dd>
                      <details>
                        <summary><a href="#ds-tx-presence-dependency-c01">2.1.2.2.1 Declaration dependency</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-presence-dependency-c01-p01">2.1.2.2.1.1 P01 - SubTx declarations require TopTx's declaration</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-presence-dependency-c02">2.1.2.2.2 Absence and explicit zero</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-presence-dependency-c02-n01">2.1.2.2.2.1 N01 - accepts absent declarations at both levels</a><br>
                            <a href="#ds-tx-presence-dependency-c02-n02">2.1.2.2.2.2 N02 - accepts explicit zero at both levels</a><br>
                            <a href="#ds-tx-presence-dependency-c02-n03">2.1.2.2.2.3 N03 - accepts TopTx zero without a SubTx declaration</a><br>
                            <a href="#ds-tx-presence-dependency-c02-f01">2.1.2.2.2.4 F01 - rejects SubTx zero without a TopTx declaration</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-presence-dependency-c03">2.1.2.2.3 Equal allocations and releases</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-presence-dependency-c03-n01">2.1.2.2.3.1 N01 - passes declaration presence with TopTx declaring the zero net amount</a><br>
                            <a href="#ds-tx-presence-dependency-c03-f01">2.1.2.2.3.2 F01 - rejects an absent TopTx declaration despite the zero net amount</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-presence-dependency-c04">2.1.2.2.4 Local and delegated accounting</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-presence-dependency-c04-n01">2.1.2.2.4.1 N01 - passes declaration presence with TopTx zero for every explicit SubTx form</a><br>
                            <a href="#ds-tx-presence-dependency-c04-f01">2.1.2.2.4.2 F01 - rejects an absent TopTx declaration for every explicit SubTx form</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-presence-dependency-c05">2.1.2.2.5 Phase-2 failure</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-presence-dependency-c05-n01">2.1.2.2.5.1 N01 - accepts zero declarations at both levels on the phase-2 failure path</a><br>
                            <a href="#ds-tx-presence-dependency-c05-f01">2.1.2.2.5.2 F01 - rejects SubTx zero without a TopTx declaration on the phase-2 failure path</a><br>
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
            <summary><a href="#ds-tx-exactness">2.1.3 Exactness</a></summary>
            <dl>
              <dd>
                <details>
                  <summary><a href="#ds-tx-exactness-contribution">2.1.3.1 Contribution</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-exactness-contribution-p01">2.1.3.1.1 P01 - Each SubTx declares its exact contribution</a><br>
                      <a href="#ds-tx-exactness-contribution-n01">2.1.3.1.2 N01 - accepts a SubTx contribution equal to its allocated deposits minus its released deposits</a><br>
                      <a href="#ds-tx-exactness-contribution-f01">2.1.3.1.3 F01 - rejects a SubTx net allocation one lovelace below its required amount</a><br>
                      <a href="#ds-tx-exactness-contribution-f02">2.1.3.1.4 F02 - rejects a SubTx net allocation one lovelace above its required amount</a><br>
                      <a href="#ds-tx-exactness-contribution-f03">2.1.3.1.5 F03 - rejects a SubTx net release one lovelace below its required amount</a><br>
                      <a href="#ds-tx-exactness-contribution-f04">2.1.3.1.6 F04 - rejects a SubTx net release one lovelace above its required amount</a><br>
                      <a href="#ds-tx-exactness-contribution-f05">2.1.3.1.7 F05 - rejects opposing SubTx declaration errors even when they cancel in the batch total</a><br>
                      <a href="#ds-tx-exactness-contribution-n02">2.1.3.1.8 N02 - derives TopTx's own contribution by removing all SubTx contributions from its declared batch total</a><br>
                      <a href="#ds-tx-exactness-contribution-n03">2.1.3.1.9 N03 - accepts a SubTx explicit zero when its required own deposit change is zero</a><br>
                      <a href="#ds-tx-exactness-contribution-f06">2.1.3.1.10 F06 - rejects a SubTx explicit zero when its required own deposit change is positive</a><br>
                      <a href="#ds-tx-exactness-contribution-n04">2.1.3.1.11 N04 - checks a delegated net allocation against the requesting SubTx's exact net UTxO capacity deposit change</a><br>
                      <a href="#ds-tx-exactness-contribution-n05">2.1.3.1.12 N05 - checks a delegated net release against the originating SubTx's exact net UTxO capacity deposit change</a><br>
                      <a href="#ds-tx-exactness-contribution-n06">2.1.3.1.13 N06 - requires a SubTx net release when it spends store-backed outputs and creates only implicit outputs</a><br>
                      <a href="#ds-tx-exactness-contribution-f07">2.1.3.1.14 F07 - rejects a SubTx explicit zero when its required own deposit change is negative</a><br>
                      <a href="#ds-tx-exactness-contribution-n07">2.1.3.1.15 N07 - preserves a SubTx's declared net release when another body's allocation offsets it</a><br>
                      <a href="#ds-tx-exactness-contribution-n08">2.1.3.1.16 N08 - still requires the exact UTxO capacity deposit for an output with no application assets</a><br>
                      <a href="#ds-tx-exactness-contribution-n09">2.1.3.1.17 N09 - accepts spending a translated implicit output to create store-backed outputs with the exact declared allocation and batch funding</a><br>
                      <a href="#ds-tx-exactness-contribution-f08">2.1.3.1.18 F08 - rejects an inexact allocation when spending a translated implicit output to create store-backed outputs</a><br>
                      <a href="#ds-tx-exactness-contribution-f09">2.1.3.1.19 F09 - rejects an unrelated release from pre-existing Store surplus</a><br>
                      <a href="#ds-tx-exactness-contribution-f10">2.1.3.1.20 F10 - rejects a SubTx release when its required own deposit change is positive</a><br>
                      <a href="#ds-tx-exactness-contribution-f11">2.1.3.1.21 F11 - rejects a SubTx allocation when its required own deposit change is negative</a><br>
                      <a href="#ds-tx-exactness-contribution-n10">2.1.3.1.22 N10 - accepts exact SubTx contributions on the phase-2 failure path</a><br>
                      <a href="#ds-tx-exactness-contribution-f12">2.1.3.1.23 F12 - rejects an inexact SubTx contribution even when phase 2 fails</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-exactness-netting">2.1.3.2 Netting</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-exactness-netting-p01">2.1.3.2.1 P01 - TopTx declares the exact transaction total</a><br>
                      <a href="#ds-tx-exactness-netting-n01">2.1.3.2.2 N01 - includes both TopTx and SubTx UTxO capacity deposit changes in the declared total</a><br>
                      <a href="#ds-tx-exactness-netting-n02">2.1.3.2.3 N02 - nets a 5 ADA allocation and a 3 ADA release into a TopTx allocation of 2 ADA</a><br>
                      <a href="#ds-tx-exactness-netting-n03">2.1.3.2.4 N03 - nets a 3 ADA allocation and a 5 ADA release into a TopTx release of 2 ADA</a><br>
                      <a href="#ds-tx-exactness-netting-n04">2.1.3.2.5 N04 - uses TopTx explicit zero when nonzero body contributions cancel exactly</a><br>
                      <a href="#ds-tx-exactness-netting-f01">2.1.3.2.6 F01 - rejects a TopTx net allocation one lovelace below the required batch total</a><br>
                      <a href="#ds-tx-exactness-netting-f02">2.1.3.2.7 F02 - rejects a TopTx net allocation one lovelace above the required batch total</a><br>
                      <a href="#ds-tx-exactness-netting-f03">2.1.3.2.8 F03 - rejects a TopTx net release one lovelace below the required batch release</a><br>
                      <a href="#ds-tx-exactness-netting-f04">2.1.3.2.9 F04 - rejects a TopTx net release one lovelace above the required batch release</a><br>
                      <a href="#ds-tx-exactness-netting-f05">2.1.3.2.10 F05 - rejects TopTx explicit zero when the required batch total is nonzero</a><br>
                      <a href="#ds-tx-exactness-netting-f06">2.1.3.2.11 F06 - rejects a nonzero TopTx declaration when the required batch total is zero</a><br>
                      <a href="#ds-tx-exactness-netting-f07">2.1.3.2.12 F07 - rejects a TopTx declaration whose sign opposes the required batch total</a><br>
                      <a href="#ds-tx-exactness-netting-n05">2.1.3.2.13 N05 - accepts TopTx explicit zero when its own release is offset by SubTx allocations</a><br>
                      <a href="#ds-tx-exactness-netting-n06">2.1.3.2.14 N06 - accepts TopTx explicit zero when its own allocation is offset by SubTx releases</a><br>
                      <a href="#ds-tx-exactness-netting-n07">2.1.3.2.15 N07 - accepts an exact TopTx batch total on the phase-2 failure path</a><br>
                      <a href="#ds-tx-exactness-netting-f08">2.1.3.2.16 F08 - rejects an inexact TopTx batch total even when phase 2 fails</a><br>
                      <a href="#ds-tx-exactness-netting-f09">2.1.3.2.17 F09 - rejects a TopTx total that omits or double-counts a delegated contribution</a><br>
                    </dd>
                  </dl>
                </details>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-attribution">2.1.4 Attribution</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-attribution-p01">2.1.4.1 P01 - observed TopTx and local SubTx attribution matches the independent signed contribution projection</a><br>
                <a href="#ds-tx-attribution-p02">2.1.4.2 P02 - switching local and delegated accounting changes attribution by the signed contribution and preserves the required batch change</a><br>
                <a href="#ds-tx-attribution-n01">2.1.4.3 N01 - counts delegated funding once in TopTx accounting</a><br>
                <a href="#ds-tx-attribution-n02">2.1.4.4 N02 - keeps the same batch net change when a SubTx delegates funding of its net allocation</a><br>
                <a href="#ds-tx-attribution-n03">2.1.4.5 N03 - allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx</a><br>
                <a href="#ds-tx-attribution-n04">2.1.4.6 N04 - observes zero local and delegated amounts with no funding request for SubTx explicit zero</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-conservation">2.1.5 Conservation</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-conservation-p01">2.1.5.1 P01 - The transaction conserves value</a><br>
                <a href="#ds-tx-conservation-p02">2.1.5.2 P02 - with other rules satisfied, ledger acceptance agrees with batch conservation even when SubTxs are financially imbalanced</a><br>
                <a href="#ds-tx-conservation-n01">2.1.5.3 N01 - counts the net allocation once on the produced side</a><br>
                <a href="#ds-tx-conservation-n02">2.1.5.4 N02 - counts the net release once on the consumed side</a><br>
                <a href="#ds-tx-conservation-n03">2.1.5.5 N03 - accepts financially imbalanced SubTxs when the complete batch balances</a><br>
                <a href="#ds-tx-conservation-n04">2.1.5.6 N04 - preserves a SubTx's ability to contribute ADA to TopTx fees</a><br>
                <a href="#ds-tx-conservation-f01">2.1.5.7 F01 - rejects a batch imbalance of one lovelace</a><br>
                <a href="#ds-tx-conservation-f02">2.1.5.8 F02 - rejects a native-asset imbalance even when ADA balances</a><br>
                <a href="#ds-tx-conservation-f03">2.1.5.9 F03 - rejects a delegation request that the complete batch does not fund</a><br>
                <a href="#ds-tx-conservation-n05">2.1.5.10 N05 - accepts offsetting delegated operations in a financially balanced batch</a><br>
                <a href="#ds-tx-conservation-n06">2.1.5.11 N06 - requires an output of 12 ADA for 10 input ADA and a 2 ADA net release with no other ADA flows</a><br>
                <a href="#ds-tx-conservation-n07">2.1.5.12 N07 - allows an output of 10 ADA when the other 2 ADA contributes to TopTx fees</a><br>
                <a href="#ds-tx-conservation-f04">2.1.5.13 F04 - rejects a 10 ADA output for 10 input ADA and a 2 ADA release when all other batch flows stay fixed</a><br>
                <a href="#ds-tx-conservation-n08">2.1.5.14 N08 - accepts ordinary batch conservation on the phase-2 failure path</a><br>
                <a href="#ds-tx-conservation-f05">2.1.5.15 F05 - rejects an ordinary batch imbalance even when phase 2 fails</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-authorization">2.1.6 Authorization</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-authorization-n01">2.1.6.1 N01 - allows the authorized spender to release UTxO capacity deposits paid by another person</a><br>
                <a href="#ds-tx-authorization-n02">2.1.6.2 N02 - does not require a separate signature from the original UTxO capacity deposit funder</a><br>
                <a href="#ds-tx-authorization-f01">2.1.6.3 F01 - rejects spending by the original funder without the current spending authority even when the Store declaration is exact</a><br>
                <a href="#ds-tx-authorization-n03">2.1.6.4 N03 - gains no release authority merely by referencing a store-backed output</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-settlement">2.1.7 Settlement</a></summary>
            <dl>
              <dd>
                <details>
                  <summary><a href="#ds-tx-settlement-participation">2.1.7.1 Participation</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-participation-p01">2.1.7.1.1 P01 - TopTx settles its attributed release</a><br>
                      <a href="#ds-tx-settlement-participation-n01">2.1.7.1.2 N01 - requires NoTopTxSettlement when SubTxs settle the entire net release locally</a><br>
                      <a href="#ds-tx-settlement-participation-n02">2.1.7.1.3 N02 - requires a TopTx settlement output when the batch declares a net release and TopTx has a positive share</a><br>
                      <a href="#ds-tx-settlement-participation-n03">2.1.7.1.4 N03 - accepts a net release settled across TopTx and SubTx outputs</a><br>
                      <a href="#ds-tx-settlement-participation-n04">2.1.7.1.5 N04 - allows TopTx's settlement amount to exceed the batch net release when SubTxs account for net allocations locally</a><br>
                      <a href="#ds-tx-settlement-participation-f01">2.1.7.1.6 F01 - rejects NoTopTxSettlement when the batch declares a net release and TopTx has a positive share</a><br>
                      <a href="#ds-tx-settlement-participation-f02">2.1.7.1.7 F02 - rejects a TopTx settlement output when TopTx has no net release to settle</a><br>
                      <a href="#ds-tx-settlement-participation-n05">2.1.7.1.8 N05 - does not require a TopTx settlement output when the batch declares a net allocation</a><br>
                      <a href="#ds-tx-settlement-participation-n06">2.1.7.1.9 N06 - does not require a TopTx settlement output for an explicit-zero batch even when TopTx's derived accounting portion is negative</a><br>
                      <a href="#ds-tx-settlement-participation-n07">2.1.7.1.10 N07 - accepts NoTopTxSettlement when TopTx's attributed contribution is a net allocation</a><br>
                      <a href="#ds-tx-settlement-participation-n08">2.1.7.1.11 N08 - accepts correct release participation on the phase-2 failure path</a><br>
                      <a href="#ds-tx-settlement-participation-f03">2.1.7.1.12 F03 - rejects incorrect release participation even when phase 2 fails</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-settlement-destination">2.1.7.2 Destination</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-destination-p01">2.1.7.2.1 P01 - Settlement indices belong to their own body</a><br>
                      <a href="#ds-tx-settlement-destination-f01">2.1.7.2.2 F01 - rejects an index outside the declaring body's output sequence</a><br>
                      <a href="#ds-tx-settlement-destination-f02">2.1.7.2.3 F02 - does not resolve a SubTx settlement index against TopTx outputs</a><br>
                      <a href="#ds-tx-settlement-destination-f03">2.1.7.2.4 F03 - does not resolve a settlement index against collateral return</a><br>
                      <a href="#ds-tx-settlement-destination-f04">2.1.7.2.5 F04 - rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs</a><br>
                      <a href="#ds-tx-settlement-destination-n01">2.1.7.2.6 N01 - accepts the first and last own regular output as settlement destinations</a><br>
                      <a href="#ds-tx-settlement-destination-f05">2.1.7.2.7 F05 - does not resolve a TopTx settlement index against nested SubTx outputs</a><br>
                      <a href="#ds-tx-settlement-destination-f06">2.1.7.2.8 F06 - does not resolve a SubTx settlement index against a sibling SubTx's outputs</a><br>
                      <a href="#ds-tx-settlement-destination-n02">2.1.7.2.9 N02 - accepts valid ordinary settlement destinations on the phase-2 failure path</a><br>
                      <a href="#ds-tx-settlement-destination-f07">2.1.7.2.10 F07 - rejects an invalid ordinary settlement index even when phase 2 fails</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-settlement-coverage">2.1.7.3 Coverage</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-coverage-p01">2.1.7.3.1 P01 - Settlement outputs cover their release share</a><br>
                      <a href="#ds-tx-settlement-coverage-f01">2.1.7.3.2 F01 - rejects a settlement output containing less ADA than its settlement amount</a><br>
                      <a href="#ds-tx-settlement-coverage-n01">2.1.7.3.3 N01 - accepts a settlement output containing exactly its settlement amount</a><br>
                      <a href="#ds-tx-settlement-coverage-n02">2.1.7.3.4 N02 - accepts a settlement output containing the settlement amount and additional funds</a><br>
                      <a href="#ds-tx-settlement-coverage-f02">2.1.7.3.5 F02 - rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference</a><br>
                      <a href="#ds-tx-settlement-coverage-n03">2.1.7.3.6 N03 - accepts a store-backed settlement output with application ADA equal to the settlement amount</a><br>
                      <a href="#ds-tx-settlement-coverage-n04">2.1.7.3.7 N04 - checks TopTx's derived settlement amount rather than the entire batch net release</a><br>
                      <a href="#ds-tx-settlement-coverage-n05">2.1.7.3.8 N05 - accepts covered ordinary settlement outputs on the phase-2 failure path</a><br>
                      <a href="#ds-tx-settlement-coverage-f03">2.1.7.3.9 F03 - rejects insufficient ordinary settlement coverage even when phase 2 fails</a><br>
                      <a href="#ds-tx-settlement-coverage-f04">2.1.7.3.10 F04 - rejects a TopTx output that covers the batch release but not TopTx's larger attributed release</a><br>
                    </dd>
                  </dl>
                </details>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-application-assets">2.1.8 Application assets</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-application-assets-n01">2.1.8.1 N01 - accepts a store-backed output containing native assets and zero ADA</a><br>
                <a href="#ds-tx-application-assets-n02">2.1.8.2 N02 - accepts empty application assets with a datum or reference script</a><br>
                <a href="#ds-tx-application-assets-n03">2.1.8.3 N03 - accepts a store-backed output containing only an address</a><br>
                <a href="#ds-tx-application-assets-n04">2.1.8.4 N04 - accepts implicit outputs containing exactly their required minimum coin</a><br>
                <a href="#ds-tx-application-assets-f01">2.1.8.5 F01 - rejects implicit outputs one lovelace below their required minimum coin</a><br>
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

> **Identify each body's own activity and the complete transaction's total.**
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
[Netting](#ds-tx-exactness-netting) compares that supplied total with the required
total above. For each explicit SubTx declaration, [Contribution](#ds-tx-exactness-contribution)
compares `declaredSubTxNetUTxODepositChange(subTx)` with its required own change.
Never obtain the expected amounts from the declarations being checked.

| Body activity | Required own change | Correct declaration |
| --- | ---: | --- |
| TopTx releases 3 ADA | $-3$ ADA | Explicit zero, because the complete transaction nets to zero. |
| Its SubTx allocates 3 ADA | $+3$ ADA | An allocation of 3 ADA, locally accounted or explicitly delegated. |

TopTx's **accounting amount**, `topTxNetUTxODepositChange`, is the declared total
minus locally accounted SubTx contributions. It includes delegated contributions;
it is distinct from TopTx's own activity. [Attribution](#ds-tx-attribution) defines it.

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
| [Grammar](#ds-tx-grammar) | Is the declaration well formed? |
| [Presence](#ds-tx-presence) | Must this body declare a change? |
| [Exactness](#ds-tx-exactness) | Does the amount match the deposit obligation? |
| [Attribution](#ds-tx-attribution) | Which body accounts for the contribution? |
| [Conservation](#ds-tx-conservation) | Does the complete transaction balance? |
| [Authorization](#ds-tx-authorization) | Who may release the deposit? |
| [Settlement](#ds-tx-settlement) | Which output must contain the settlement amount? |
| [Application assets](#ds-tx-application-assets) | What value may the output contain? |

These rules validate the submitted ordinary transaction under a fixed pricing policy,
even when phase 2 will fail. Ordinary amount and settlement checks examine the
hypothetical ordinary transition; they do not apply it. Existing input resolution,
witness requirements and other ledger restrictions still apply.

| Check | Ordinary success | Accepted phase-2 failure |
| --- | --- | --- |
| Declaration presence, exact amounts and settlement terms | Required | Required |
| Whole-transaction financial conservation | Required | Required |
| Collateral funding and supplied total | Required when any body has redeemers | Required when any body has redeemers |
| Ordinary Store effects | Applied | Unapplied |
| Collateral Store effects | Unapplied | Applied |

An invalid declaration therefore rejects the transaction before either effect set
can be accepted. Phase-2 script failure itself is handled by the existing outcome
rules; it is not a waiver of these declaration checks. [Execution](#ds-state-execution)
owns state application and rejection atomicity.

<a id="ds-tx-grammar" name="ds-tx-grammar"></a>

#### 2.1.1 Grammar

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

[Presence](#ds-tx-presence) determines when a declaration is required.
[Exactness](#ds-tx-exactness) checks its amount.
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

The reusable `StrictlyPositiveCoin` type owns the positive-amount invariant;
[`StrictlyPositiveCoinSpec`](../libs/cardano-ledger-core/test/Test/Cardano/Ledger/StrictlyPositiveCoinSpec.hs)
tests its constructor and scalar codecs. Grammar checks the type's use **inside
declarations**, including rejection of raw external values that bypass construction.

TopTx and SubTx follow the same reading order:
**Amounts → Absence → Forms → Structure → Destinations**.
Case numbers restart within each category; each tag links to its executable check.

<a id="ds-tx-grammar-toptx" name="ds-tx-grammar-toptx"></a>

##### 2.1.1.1 TopTx

TopTx declares the transaction total. Its grammar permits explicit zero, allocation
or release; a funding request is a SubTx operation.

<a id="ds-tx-grammar-amounts" name="ds-tx-grammar-amounts"></a>

<a id="ds-tx-grammar-toptx-amounts" name="ds-tx-grammar-toptx-amounts"></a>

###### 2.1.1.1.1 Amounts

> **Allocation and release carry a strictly positive amount.**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-p01" name="ds-tx-grammar-p01"></a>**1. [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L36)** | **Positive amounts survive encoding.** A generated `StrictlyPositiveCoin` in every amount-bearing form. | Preserve the operation, amount and settlement through both codecs. |
| <a id="ds-tx-grammar-f01" name="ds-tx-grammar-f01"></a>**2. [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L40)** | **Zero operation amount.** Raw $\text{amount}=0$. | Reject decoding. Explicit zero has its own form. |
| <a id="ds-tx-grammar-f12" name="ds-tx-grammar-f12"></a>**3. [F12](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L43)** | **Negative operation amount.** Raw $\text{amount}=-1$. | Reject decoding: below the lower bound. |
| <a id="ds-tx-grammar-f13" name="ds-tx-grammar-f13"></a>**4. [F13](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L46)** | **Overflowing operation amount.** Raw $\text{amount}=2^{64}$. | Reject decoding without truncation or wrapping. |

Every generated set includes allocation, release without TopTx settlement, and
local release at indices $0$, $65535$ and one generated interior index. Thus each
amount is checked in **five declarations per codec**, with valid destinations.
The three rejection cases fix the amount at the stated boundary value while
varying the surrounding declaration. Explicit zero uses a separate form, not an
allocation or release of zero.

<a id="ds-tx-grammar-absence" name="ds-tx-grammar-absence"></a>

<a id="ds-tx-grammar-toptx-absence" name="ds-tx-grammar-toptx-absence"></a>

###### 2.1.1.1.2 Absence

> **Declaring zero is different from declaring nothing.**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-n03" name="ds-tx-grammar-n03"></a>**1. [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L51)** | **Absence remains distinct from zero.** Two otherwise identical complete bodies, differing only in their declaration. | Distinct encodings; decoding preserves each complete body. |

Both bodies share the same generated spending inputs, reference inputs and
auxiliary-data hash. Only the declaration differs:

$$
\begin{aligned}
\text{encode(absentBody)} &\ne \text{encode(explicitZeroBody)} \\
\text{decode(encode(absentBody))} &= \text{absentBody} \\
\text{decode(encode(explicitZeroBody))} &= \text{explicitZeroBody}
\end{aligned}
$$

This preserves the distinction needed by Presence without deciding whether either
body has declared enough for its Store activity.

<a id="ds-tx-grammar-forms" name="ds-tx-grammar-forms"></a>

<a id="ds-tx-grammar-toptx-forms" name="ds-tx-grammar-toptx-forms"></a>

###### 2.1.1.1.3 Forms

> **Preserve every TopTx form; keep funding requests specific to SubTx.**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-n05" name="ds-tx-grammar-n05"></a>**1. [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L58)** | **Every TopTx declaration form.** Explicit zero and all amount-bearing forms at both amount bounds. | Preserve each form, amount and settlement. |
| <a id="ds-tx-grammar-f06" name="ds-tx-grammar-f06"></a>**2. [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L62)** | **Funding request in TopTx.** A valid SubTx funding request is passed to the TopTx decoder. | SubTx preserves the request in both codecs; TopTx rejects its JSON representation. |

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

<a id="ds-tx-grammar-toptx-structure" name="ds-tx-grammar-toptx-structure"></a>

###### 2.1.1.1.4 Structure

> **A recognized operation must carry exactly its required CBOR fields, or all required JSON fields.**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-f02" name="ds-tx-grammar-f02"></a>**1. [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L68)** | **Malformed declarations.** Invalid containers, unknown operations, missing required fields or extra CBOR fields. | Reject each malformed input in its own format. |

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

<a id="ds-tx-grammar-toptx-destinations" name="ds-tx-grammar-toptx-destinations"></a>

###### 2.1.1.1.5 Destinations

> **A release names no TopTx settlement, or a representable own output index.**

| Valid form | Payload |
| --- | --- |
| `NoTopTxSettlement` | No index. |
| `TopTxSettlementOutput outputIndex` | $0\le\text{outputIndex}\le65535$. |

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-f04" name="ds-tx-grammar-f04"></a>**1. [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L73)** | **Malformed release settlements.** Wrong container, unknown form, missing local index or extra CBOR fields. | Reject decoding with otherwise valid indices. |
| <a id="ds-tx-grammar-f14" name="ds-tx-grammar-f14"></a>**2. [F14](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L76)** | **Negative output index.** Generated $\text{outputIndex}<0$, favouring $-1$. | Reject the local settlement in both codecs. |
| <a id="ds-tx-grammar-f15" name="ds-tx-grammar-f15"></a>**3. [F15](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/TopTxSpec.hs#L80)** | **Overflowing output index.** Generated $\text{outputIndex}>65535$, favouring $65536$. | Reject the settlement without truncation or wrapping. |

F04 covers six CBOR and five JSON structural defects per draw: invalid containers,
unknown forms, missing local indices and extra CBOR fields. Examples include CBOR
`[0,1]` (an index on the no-settlement form) and `[1]` (a local form without its
index). Any supplied local index remains within range.

F14 and F15 generate values throughout their respective invalid ranges, favouring
$-1$ and $65536$. Shrinking keeps a counterexample in the same invalid range.
[N05](#ds-tx-grammar-n05) supplies the valid $0$ and $65535$ controls.
[Settlement](#ds-tx-settlement-destination) separately checks that the index names
an existing output in TopTx.

<a id="ds-tx-grammar-subtx" name="ds-tx-grammar-subtx"></a>

##### 2.1.1.2 SubTx

A SubTx can declare zero, allocate locally, request funding from TopTx, or release
to its own output or TopTx. Encoding preserves which choice it made.

<a id="ds-tx-grammar-subtx-amounts" name="ds-tx-grammar-subtx-amounts"></a>

###### 2.1.1.2.1 Amounts

> **Allocation, funding requests and releases carry a strictly positive amount.**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-p02" name="ds-tx-grammar-p02"></a>**1. [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L33)** | **Positive amounts survive encoding.** A generated `StrictlyPositiveCoin` in every amount-bearing form. | Preserve the operation, amount and target through both codecs. |
| <a id="ds-tx-grammar-f07" name="ds-tx-grammar-f07"></a>**2. [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L37)** | **Zero operation amount.** Raw $\text{amount}=0$. | Reject decoding. An amount-bearing operation cannot stand in for explicit zero. |
| <a id="ds-tx-grammar-f08" name="ds-tx-grammar-f08"></a>**3. [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L40)** | **Negative operation amount.** Raw $\text{amount}=-1$. | Reject decoding: the amount is below the lower bound. |
| <a id="ds-tx-grammar-f09" name="ds-tx-grammar-f09"></a>**4. [F09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L43)** | **Overflowing operation amount.** Raw $\text{amount}=2^{64}$. | Reject decoding without truncation or wrapping. |

F07–F09 generate declaration payloads around the **fixed raw amount shown**;
they do not generate arbitrary negative or overflowing amounts. Each draw covers
six declarations per codec: allocation, request, delegated release, and local
release at $0$, $65535$ and a generated index in $1\ldots65534$.

<a id="ds-tx-grammar-subtx-absence" name="ds-tx-grammar-subtx-absence"></a>

###### 2.1.1.2.2 Absence

> **Declaring zero is different from declaring nothing.**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-n04" name="ds-tx-grammar-n04"></a>**1. [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L48)** | **Absence remains distinct from zero.** The same complete body, differing only in its declaration. | Distinct CBOR and JSON representations; decoding preserves each complete body. |

Both bodies share the same generated spending inputs, reference inputs and
auxiliary-data hash. Only the declaration differs:

$$
\begin{aligned}
\text{encode(absentBody)} &\ne \text{encode(explicitZeroBody)} \\
\text{decode(encode(absentBody))} &= \text{absentBody} \\
\text{decode(encode(explicitZeroBody))} &= \text{explicitZeroBody}
\end{aligned}
$$

This preserves the distinction needed by Presence without deciding whether either
body has declared enough for its Store activity.

<a id="ds-tx-grammar-subtx-forms" name="ds-tx-grammar-subtx-forms"></a>

###### 2.1.1.2.3 Forms

> **Preserve every SubTx form, including explicit funding requests.**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-n06" name="ds-tx-grammar-n06"></a>**1. [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L55)** | **Every SubTx declaration form.** Explicit zero and every amount-bearing form at both amount bounds. | Preserve each form, amount and target through both codecs. |

The amount bounds are $1$ and $2^{64}-1$. Local releases use $0$, $65535$ and a
generated interior index in $1\ldots65534$. Together with explicit zero, these
produce thirteen declarations per draw. P02 varies the amount across its valid
range; N06 always includes both bounds.

<a id="ds-tx-grammar-subtx-structure" name="ds-tx-grammar-subtx-structure"></a>

###### 2.1.1.2.4 Structure

> **A recognized operation must carry exactly its required CBOR fields, or all required JSON fields.**

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-f03" name="ds-tx-grammar-f03"></a>**1. [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L61)** | **Malformed declarations.** Invalid containers, unknown operations, missing required fields or extra CBOR fields. | Reject each malformed input in its own format. |

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

###### 2.1.1.2.5 Destinations

> **A release delegates to TopTx, or names a representable own output index.**

| Valid form | Payload |
| --- | --- |
| `DelegateToTopTx` | No local index. |
| `SubTxSettlementOutput outputIndex` | $0\le\text{outputIndex}\le65535$. |

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-tx-grammar-f05" name="ds-tx-grammar-f05"></a>**1. [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L66)** | **Malformed release targets.** Wrong container, unknown target, missing local index or extra CBOR fields. | Reject decoding with otherwise valid indices. |
| <a id="ds-tx-grammar-f10" name="ds-tx-grammar-f10"></a>**2. [F10](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L69)** | **Negative output index.** Generated $\text{outputIndex}<0$, favouring $-1$. | Reject a local target carrying that index in both codecs. |
| <a id="ds-tx-grammar-f11" name="ds-tx-grammar-f11"></a>**3. [F11](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Grammar/SubTxSpec.hs#L73)** | **Overflowing output index.** Generated $\text{outputIndex}>65535$, favouring $65536$. | Reject the target without truncation or wrapping. |

F05 covers six CBOR and five JSON structural defects per draw: invalid containers,
unknown forms, missing local indices and extra CBOR fields. Examples include CBOR
`[1,0]` (an index attached to delegation) and `[0]` (a local target without its
index). Any supplied local index remains within range.

F10 and F11 generate values throughout their respective invalid ranges, favouring
$-1$ and $65536$. Shrinking keeps a counterexample in the same invalid range.
[N06](#ds-tx-grammar-n06) supplies the valid $0$ and $65535$ controls.
[Settlement](#ds-tx-settlement-destination) separately checks that the index names
an existing output in this SubTx.

<a id="ds-tx-presence" name="ds-tx-presence"></a>

#### 2.1.2 Presence

> **Determine when a body must declare a change.**
>
> - **Activity:** its own use of the Store.
> - **Dependency:** a SubTx declaration requiring TopTx to declare.

Ordinary declaration, exactness, conservation, output and settlement validation applies on both phase-2 outcomes. Required ordinary amounts describe the hypothetical ordinary transition from the original UTxO. An accepted phase-2 failure applies collateral effects only; skipping ordinary effects does not skip these validators. Accepted ordinary release additionally requires its existing spending authorization. Ledger outcome and applied effects remain separate under State Execution.

<a id="ds-tx-presence-activity" name="ds-tx-presence-activity"></a>

##### 2.1.2.1 Activity

> **Require a declaration for the body’s own Store activity.**
>
> Creates or spends a store-backed output $\implies$ own declaration required.

**Decision:** Agreed.

A body creating or spending store-backed outputs must provide its own declaration field. TopTx declares the complete batch amount; SubTx declares its own contribution.

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
- `createsStoreBackedOutput(body)`: at least one element of `outputs(body)` has the
  `StoreBackedTxOut` constructor.
- `spendsStoreBackedOutput(body)`: at least one element of `spentOutputs(body)`
  has the `StoreBackedTxOut` constructor.

The required condition is:

$$
\begin{aligned}
&\text{createsStoreBackedOutput(body)} \lor \text{spendsStoreBackedOutput(body)} \\
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
DS-TX-EXACTNESS-CONTRIBUTION additionally requires a release
contribution when store-backed outputs are spent without creating any new store-backed
outputs.

**Presence decision table**

These results concern **DS-TX-PRESENCE-ACTIVITY only**. Passing this check does not establish that the
transaction satisfies funding, release, or other ledger rules.

| Own spent outputs | Own created outputs | Own operation field | Result for DS-TX-PRESENCE-ACTIVITY |
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
  DS-TX-EXACTNESS-CONTRIBUTION checks the requested amount, DS-TX-ATTRIBUTION assigns
  its accounting to TopTx, and DS-TX-CONSERVATION requires the complete batch to fund it.
- A TopTx whose own spent and created outputs are all implicit-deposit outputs
  and whose field is `TopTx.NoUTxODepositDeclaration`, containing a SubTx with store-backed outputs
  and an explicit operation, passes this check for both bodies. This says nothing
  about overall validity: DS-TX-PRESENCE-DEPENDENCY rejects the missing TopTx declaration.
- Creating store-backed outputs still requires a declaration when the net
  funding requirement is zero. An active SubTx with a zero required own change uses `SubTx.DeclaresZeroNetUTxODeposit`. TopTx uses `TopTx.DeclaresZeroNetUTxODeposit` when the complete required batch change is zero, regardless of its own contribution.

<a id="ds-tx-presence-activity-p01" name="ds-tx-presence-activity-p01"></a>

###### 2.1.2.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/ActivitySpec.hs#L18) - Every active body declares

$$
\begin{aligned}
\text{Accepted}\implies\forall\,\text{body}:\quad
&(\text{createsStoreBackedOutput(body)}\lor\text{spendsStoreBackedOutput(body)}) \\
&\implies\text{hasDeclaration(body)}
\end{aligned}
$$

For accepted transactions on either phase-2 outcome, every body creating or spending at least one store-backed ordinary output has its own declaration field. Inspect the hypothetical ordinary transition even when collateral effects are selected. TopTx declares the complete batch amount; parent or child fields cannot substitute for the required field. Exercise accepted cases at both body levels and outcomes so the invariant is not vacuous. The combined property is separate from the individual creation and spending cases below.

<a id="ds-tx-presence-activity-creation" name="ds-tx-presence-activity-creation"></a>

###### 2.1.2.1.2 Creation

> **Check declaration presence when the body creates outputs.**
>
> At least one own store-backed output $\implies$ declaration required, regardless of its position.

**Decision:** Agreed.

A body's own regular outputs trigger creation presence. Inspect every output,
including mixed sequences and every possible position of a store-backed output.
Any explicit declaration satisfies this presence predicate; amounts and targets
remain subject to their own rules.

An isolated validator returning `Success ()` establishes creation presence only.
The ledger acceptance controls here use implicit-only outputs. The missing-declaration
scenarios retain their store-backed outputs through preparation, check the exact
body-specific failure, and compare the ledger state immediately before and after rejection.
A phase-2-invalid marker does not bypass this requirement.

The implemented store-backed rejection fixtures currently isolate the specific presence failure; their builders balance application assets and fees but do not fund the unimplemented capacity-deposit transfer. They are not otherwise valid Store transactions. When amount and conservation enforcement is added, build an exact, funded accepted baseline before removing the field, or keep the check explicitly isolated. Retaining this current implementation boundary does not establish deposit accounting.

<a id="ds-tx-presence-activity-creation-n01" name="ds-tx-presence-activity-creation-n01"></a>

**2.1.2.1.2.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L41) - accepts every explicit TopTx and SubTx declaration for creation presence, including zero and delegation**

Every explicit declaration counts as present, including zero, allocation, release, and SubTx delegation. With store-backed own outputs, the isolated creation validator therefore returns Success (). This establishes presence only; it does not establish that the declared amount, funding, or settlement is correct.

<a id="ds-tx-presence-activity-creation-n02" name="ds-tx-presence-activity-creation-n02"></a>

**2.1.2.1.2.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L58) - accepts absent declarations for empty or implicit-only own outputs**

An empty or implicit-only own output sequence does not trigger the creation requirement: $\text{hasStoreBackedOwnOutput}=\text{False}$. The isolated TopTx and SubTx creation validators accept an absent declaration. Spending activity is checked separately.

<a id="ds-tx-presence-activity-creation-f01" name="ds-tx-presence-activity-creation-f01"></a>

**2.1.2.1.2.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L67) - rejects a missing own declaration when a store-backed output appears at any own-output position**

One store-backed own output is enough to require the body's declaration, wherever that output appears among implicit outputs. For TopTx and SubTx alike, storeBackedOwnOutput ∧ absentOwnDeclaration produces MissingBodyUTxODepositDeclaration in the isolated validator.

<a id="ds-tx-presence-activity-creation-n03" name="ds-tx-presence-activity-creation-n03"></a>

**2.1.2.1.2.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L77) - accepts a TopTx creating only implicit outputs without a declaration**

A TopTx creating only implicit outputs is accepted by the ledger without a Store declaration when its ordinary inputs, fees, and witnesses are valid. This is the full-ledger control for the TopTx creation rejection.

<a id="ds-tx-presence-activity-creation-n04" name="ds-tx-presence-activity-creation-n04"></a>

**2.1.2.1.2.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L81) - accepts a SubTx creating only implicit outputs without either body's declaration**

A SubTx creating only implicit outputs is accepted within a ledger transaction when neither level declares a Store operation. Ordinary transaction preparation supplies valid funding and witnesses; no Store allocation is created.

<a id="ds-tx-presence-activity-creation-f02" name="ds-tx-presence-activity-creation-f02"></a>

**2.1.2.1.2.6 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L85) - rejects a TopTx creating a store-backed output without its own declaration**

The ledger rejects a TopTx whose own ordinary outputs include a store-backed output while its declaration is absent. The expected failure is MissingUTxODepositDeclaration, and the rejected transaction leaves ledger state unchanged. Empty application assets do not remove the new output's capacity obligation.

<a id="ds-tx-presence-activity-creation-f03" name="ds-tx-presence-activity-creation-f03"></a>

**2.1.2.1.2.7 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L89) - rejects a SubTx creating a store-backed output without its own declaration**

The ledger rejects a SubTx that creates a store-backed own output without a SubTx declaration. The expected failure is SubMissingUTxODepositDeclaration, and rejection leaves ledger state unchanged. Declaration presence is required independently for the creating body.

<a id="ds-tx-presence-activity-creation-f04" name="ds-tx-presence-activity-creation-f04"></a>

**2.1.2.1.2.8 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L93) - rejects a TopTx creating a store-backed output without its own declaration even when phase 2 fails**

A real failing phase-2 script does not waive TopTx's structural declaration requirement. Even with the transaction marked phase-2 invalid, creating a store-backed own output without a declaration yields MissingUTxODepositDeclaration and leaves the ledger unchanged.

<a id="ds-tx-presence-activity-creation-f05" name="ds-tx-presence-activity-creation-f05"></a>

**2.1.2.1.2.9 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L97) - rejects a SubTx creating a store-backed output without its own declaration even when phase 2 fails**

A real phase-2 failure does not waive a creating SubTx's declaration requirement. The ledger still returns SubMissingUTxODepositDeclaration for the undeclared store-backed own output; the rejected transaction applies no state changes.

<a id="ds-tx-presence-activity-creation-f06" name="ds-tx-presence-activity-creation-f06"></a>

**2.1.2.1.2.10 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/CreationSpec.hs#L102) - rejects a missing own declaration when spending a translated implicit output to create store-backed outputs**

Start with an implicit output preserved by the Conway transition and create a store-backed output. Its historical origin does not waive the new output’s declaration requirement.

<a id="ds-tx-presence-activity-spending" name="ds-tx-presence-activity-spending"></a>

###### 2.1.2.1.3 Spending

> Every body consuming a store-backed output must declare its own deposit change.

$$
\forall\,\text{body}:\quad
\text{storeBackedInputs(body)}\ne\varnothing
\implies\text{hasDeclaration(body)}
$$

**Decision:** Agreed.

Apply the rule **independently to TopTx and every SubTx**, using each body's own
ordinary inputs resolved against the original UTxO.

| Store-backed inputs | Own declaration | Presence result |
| --- | --- | --- |
| Present | Absent | **Reject:** missing declaration. |
| Present | Present | **Pass presence.** Acceptance still requires exact amounts, valid settlement and all other ledger rules. |
| Absent | Either | **No spending-presence requirement.** [Creation](#ds-tx-presence-activity-creation) or [SubTx declaration dependency](#ds-tx-presence-dependency) may still require a declaration. |

Equivalently:

$$
\text{spendingPresenceValid(body)}
\iff \text{storeBackedInputs(body)}=\varnothing\lor\text{hasDeclaration(body)}
$$

**Explicit zero counts as a declaration.** Its amount must still be correct.
The presence rule applies on both phase-2 outcomes. Each scenario below states
the spending situation, the declaration supplied or omitted, and the resulting
acceptance or rejection.

**Spending an output** means consuming the live UTxO referenced by an ordinary
input. For a store-backed output, ordinary success removes both the output and
its recorded allocation. The released deposit contributes to the transaction's
funds; newly created store-backed outputs require new allocations.

Spending therefore does not necessarily mean a **net release**. The difference
between new allocations and released deposits can be positive, zero or negative.
The spending body must declare its contribution; TopTx declares the transaction total.

| Transaction outcome | Spending effect |
| --- | --- |
| Ordinary success | Consume ordinary inputs, release their recorded deposits and create the new outputs with their required allocations. |
| Accepted phase-2 failure | Apply only collateral effects. Ordinary inputs remain unless they are also designated as collateral. |
| Rejection | Preserve the complete ledger state, including collateral. |

| Notation | Meaning |
| --- | --- |
| $\text{body}$ | TopTx or one of its SubTxs, considered separately. |
| $\text{storeBackedInputs(body)}$ | Its own ordinary inputs resolving to store-backed outputs in the original UTxO. |
| $\text{hasDeclaration(body)}$ | That body explicitly declares a change, including explicit zero. |
| $\text{releasedDeposits(body)}$ | Sum of recorded deposits of its consumed store-backed outputs, proposed for ordinary release. |
| $\text{allocatedDeposits(body)}$ | Sum of required deposits of its newly created store-backed outputs. |
| $\text{declaredNetDeposit(body)}$ | The signed declaration: allocation positive, release negative, explicit zero equal to 0. TopTx declares the transaction total. |

Presence is required on **both phase-2 outcomes**, even when no new store-backed
output is created. A proposed ordinary release is applied only on ordinary success.

Acceptance cases satisfy all other ledger requirements, including exact amounts
and valid settlement. Rejection cases remove only the spending body's declaration
from a prepared valid control. Exactness separately checks the declared amounts.

N01 covers a standalone TopTx with any generated output form; N02 specializes it
to **only implicit outputs**. Source outputs are created by accepted funding
transactions. Their allocations are read from the resulting ledger state, so a
release always has a funded, recorded deposit behind it.

Each case also retains unrelated store-backed outputs. Acceptance must preserve
both those outputs and their allocation records. No test inserts an invented
allocation into the live ledger.

<a id="ds-tx-presence-activity-spending-n01" name="ds-tx-presence-activity-spending-n01"></a>

**2.1.2.1.3.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L68) - Standalone TopTx, any output form**

**Scenario**

| Body | Consumes | Creates |
| --- | --- | --- |
| TopTx only: $\text{subTxs}=\varnothing$ | Store-backed outputs: $\text{releasedDeposits}>0$ | Implicit outputs, store-backed outputs, or a mixture. |

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
| 0 ₳ | 2 ₳ | $0-2=-2$ ₳ | Release **2 ₳** into an eligible own settlement output. |

Fees and any additional allocation are funded separately. A release is accounted
for in its declared settlement output.

**Ledger effects**

| Accepted effect | Required result |
| --- | --- |
| Consumed inputs | Outputs and their allocation records are removed. |
| New store-backed outputs | Each receives its independently calculated allocation record. |
| New implicit outputs | No Store allocation record is created. |
| Unrelated outputs | Outputs and recorded amounts remain unchanged. |

$$
\text{Store balance after} = \text{Store balance before} + \text{declaredNetDeposit}
$$

<a id="ds-tx-presence-activity-spending-n02" name="ds-tx-presence-activity-spending-n02"></a>

**2.1.2.1.3.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L76) - Standalone TopTx, only implicit outputs**

No new Store allocation is required ($\text{allocatedDeposits}=0$),
so it declares the full release.

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

The settlement output contains $10 + 2 = 12$ ₳. The Store releases 2 ₳ once;
unspent outputs retain their recorded deposits. The otherwise valid transaction
must be accepted.

<a id="ds-tx-presence-activity-spending-n03" name="ds-tx-presence-activity-spending-n03"></a>

**2.1.2.1.3.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L91) - One SubTx releases its deposit into its own output**

TopTx has no Store activity of its own and declares the matching total. The SubTx consumes a store-backed output and creates only implicit outputs,
so the full recorded deposit is released. The two declarations account for
**one release**, received by the SubTx.

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
recorded Store deposit of $\text{deposit}$. With fees funded separately, its implicit
settlement output receives:

$$
\text{SubTx output coins} = 10\text{ ₳} + \text{deposit}
$$

| Body | Declaration |
| --- | --- |
| SubTx | Release the recorded deposit into its own output 0. |
| TopTx | Declare the same total net release with `NoTopTxSettlement`. |

TopTx declares the transaction total; SubTx settles this release locally. Acceptance
consumes the source, creates the SubTx output, removes the consumed allocation and
reduces the Store balance by exactly that deposit. Unrelated allocations remain.
This is the control for F02: the parent's declaration does not replace the child's.

<a id="ds-tx-presence-activity-spending-f01" name="ds-tx-presence-activity-spending-f01"></a>

**2.1.2.1.3.4 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L110) - TopTx omits its required declaration**

The ledger must reject with
`MissingUTxODepositDeclaration`, preserving the input, its recorded deposit and
the complete ledger state. This requirement holds even when every created output
is implicit.

$$
\begin{aligned}
&\text{subTxs}=\varnothing \land \text{releasedDeposits(topTx)}>0 \\
&\land\ \neg\text{hasDeclaration(topTx)} \\
&\implies \text{Rejected}\land\text{ledgerAfter}=\text{ledgerBefore}
\end{aligned}
$$

Removing the declared release can also break value conservation. Such additional
failures do not replace the required missing-declaration failure.

<a id="ds-tx-presence-activity-spending-f02" name="ds-tx-presence-activity-spending-f02"></a>

**2.1.2.1.3.5 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L119) - TopTx declares, but the spending SubTx does not**

The parent's declaration
cannot replace the child's. The ledger must reject with
`SubMissingUTxODepositDeclaration` and preserve the complete ledger state.
This is N03 with only the SubTx declaration removed; any additional accounting
failures do not replace the required presence failure.

$$
\begin{aligned}
&\text{subTxs}=\{\text{subTx}\}\land\text{releasedDeposits(subTx)}>0 \\
&\land\ \text{declaredNetDeposit(topTx)}=-\text{releasedDeposits(subTx)} \\
&\land\ \neg\text{hasDeclaration(subTx)} \\
&\implies \text{Rejected}\land\text{ledgerAfter}=\text{ledgerBefore}
\end{aligned}
$$

<a id="ds-tx-presence-activity-spending-n04" name="ds-tx-presence-activity-spending-n04"></a>

**2.1.2.1.3.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L128) - Phase 2 fails with valid declarations**

Only collateral effects apply. The proposed ordinary release is **not applied**.
Both variants create only implicit ordinary outputs: a standalone TopTx, or
one spending SubTx whose parent has no Store activity of its own.

$$
\begin{aligned}
&\text{releasedDeposits(body)}>0 \\
&\land\ \text{declaredNetDeposit(topTx)}=\text{declaredNetDeposit(body)}
=-\text{releasedDeposits(body)} \\
&\land\ \text{phase1Valid}\land\text{phase2Result}=\text{Failed} \\
&\land\ \text{declaredPhase2}=\text{Invalid} \\
&\implies \text{Accepted}\land\text{ordinaryEffects}=\varnothing
\end{aligned}
$$

Here the collateral inputs and return are implicit:

| Ordinary path remains unapplied | Collateral path executes |
| --- | --- |
| Store-backed input and its allocation remain unchanged. | Collateral inputs are consumed. |
| Proposed implicit settlement output is absent. | Implicit collateral return is created. |
| Store balance remains unchanged. | The collateral coin fee reaches the fee pot. |

The ordinary declaration is checked but its transfer is not applied. Here both
collateral inputs and return are implicit, so collateral causes no Store transfer.

<a id="ds-tx-presence-activity-spending-f03" name="ds-tx-presence-activity-spending-f03"></a>

**2.1.2.1.3.7 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L155) - Missing spending declaration in a phase-2-invalid proposal**

The entire transaction is rejected, including the collateral transition. TopTx's failures must include
`MissingUTxODepositDeclaration`; SubTx's must include
`SubMissingUTxODepositDeclaration`. Ledger state remains unchanged. Each case
removes only the spending declaration from its N04 scenario.

$$
\begin{aligned}
&\text{releasedDeposits(body)}>0\land\neg\text{hasDeclaration(body)} \\
&\land\ \text{phase2Script}=\text{AlwaysFails}\land\text{declaredPhase2}=\text{Invalid} \\
&\implies \text{Rejected}\land\text{ledgerAfter}=\text{ledgerBefore}
\end{aligned}
$$

A missing declaration rejects the proposal in phase 1. The failing script does
not exempt it from that check; the test does not require phase 2 to execute.

<a id="ds-tx-presence-activity-spending-n05" name="ds-tx-presence-activity-spending-n05"></a>

**2.1.2.1.3.8 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L173) - Several SubTxs release their deposits**

**Every spending SubTx declares its own release; TopTx declares their total.**
Generate two to five SubTxs with varying application ADA amounts. Each consumes
its own funded store-backed output and creates an implicit settlement output.
TopTx has no Store activity of its own and funds transaction fees separately.

All ordinary outputs are implicit, so no new Store allocation is required. For
each SubTx, its own settlement output receives its input's application ADA plus
the recorded deposit:

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

TopTx uses `NoTopTxSettlement`: each SubTx receives its own release. The parent
declaration accounts for those same releases; it does not release the deposits
again. Acceptance consumes every spending input, removes its allocation and
creates each SubTx's settlement output. Unrelated outputs and allocations remain.

<a id="ds-tx-presence-activity-spending-f04" name="ds-tx-presence-activity-spending-f04"></a>

**2.1.2.1.3.9 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L191) - One spending SubTx omits its declaration**

**One undeclared spending SubTx rejects the entire transaction.** Starting from
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
&\qquad\land\ \text{SubMissingUTxODepositDeclaration}\in\text{failures} \\
&\qquad\land\ \text{ledgerAfter}=\text{ledgerBefore}
\end{aligned}
$$

The parent's total and the other children's declarations cannot cover the
selected child's missing field. Rejection preserves every ordinary input,
allocation, balance and collateral entry. Additional accounting failures may
occur; the missing-declaration failure must still be present.

<a id="ds-tx-presence-activity-spending-n06" name="ds-tx-presence-activity-spending-n06"></a>

**2.1.2.1.3.10 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L212) - Only some SubTxs consume Store deposits**

**A spending SubTx does not impose its declaration requirement on its siblings.**
Mix SubTxs consuming store-backed outputs with SubTxs consuming only implicit
outputs, varying their positions. Both groups are nonempty; all created outputs
are implicit. The latter group has no Store activity and omits its declarations.

$$
\begin{aligned}
\text{spendingSubTxs} &= \{\text{subTx}\in\text{subTxs}\mid\text{storeBackedInputs(subTx)}\ne\varnothing\} \\
\text{implicitOnlySubTxs} &= \text{subTxs}\setminus\text{spendingSubTxs}
\end{aligned}
$$

| SubTx group | Own declaration | Own settlement |
| --- | --- | --- |
| $\text{spendingSubTxs}$ | Exact release of its recorded deposit. | Application ADA plus its released deposit. |
| $\text{implicitOnlySubTxs}$ | Absent. | Its application ADA, with no Store transfer. |

$$
\begin{aligned}
\text{spendingSubTxs} &\ne \varnothing \\
\text{implicitOnlySubTxs} &\ne \varnothing \\
\forall\,\text{subTx}\in\text{spendingSubTxs}:\quad
\text{declaredNetDeposit(subTx)} &= -\text{releasedDeposits(subTx)} \\
\forall\,\text{subTx}\in\text{implicitOnlySubTxs}:\quad
\text{hasDeclaration(subTx)} &= \text{False} \\
\text{declaredNetDeposit(topTx)} &= -\sum_{\text{subTx}\in\text{spendingSubTxs}}\text{releasedDeposits(subTx)} \\
&\Longrightarrow \text{Accepted}
\end{aligned}
$$

TopTx has no Store activity of its own and declares the exact total with
`NoTopTxSettlement`. The transaction must be accepted: declaration presence is
checked per body, and the inactive siblings need no declaration merely because
another SubTx releases a deposit. Every input and settlement follows its own
body; only the active inputs release Store allocations.

<a id="ds-tx-presence-activity-spending-n07" name="ds-tx-presence-activity-spending-n07"></a>

**2.1.2.1.3.11 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L235) - TopTx and several SubTxs release deposits**

**TopTx can release its own deposit while its SubTxs release theirs locally.**
TopTx and each of at least two SubTxs consume their own store-backed outputs.
All created outputs are implicit; each body settles its own release into its own
output. Fees are funded separately.

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

| Body | Declared amount | Amount received by its own settlement output |
| --- | --- | --- |
| TopTx | Total release across TopTx and SubTxs. | Its own application ADA plus its own recorded deposit. |
| Each SubTx | Its own release. | Its own application ADA plus its own recorded deposit. |

TopTx names its own settlement output because it receives part of the total.
The parent's total does not send the children's releases to that output a second
time. Acceptance consumes all spending inputs and removes each allocation once,
while preserving unrelated outputs and deposits.

<a id="ds-tx-presence-activity-spending-n08" name="ds-tx-presence-activity-spending-n08"></a>

**2.1.2.1.3.12 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L256) - Phase 2 fails with several spending SubTxs**

**Valid declarations remain required when only collateral will execute.**
Prepare the several-SubTx releases from N05, add a genuinely failing Plutus V4
script, and mark the transaction phase-2 invalid. TopTx and every SubTx retain
their exact declarations and settlement outputs. The ordinary proposal remains
fully funded, but its releases must not be applied.

$$
\begin{aligned}
|\text{subTxs}| &\ge 2 \\
\forall\,\text{subTx}\in\text{subTxs}:\quad
\text{declaredNetDeposit(subTx)} &= -\text{releasedDeposits(subTx)} \\
\text{declaredNetDeposit(topTx)} &= -\sum_{\text{subTx}\in\text{subTxs}}\text{releasedDeposits(subTx)} \\
\text{phase1Valid} &= \text{True} \\
\text{declaredPhase2} &= \text{Invalid} \\
\text{phase2Result} &= \text{Failed} \\
&\Longrightarrow \text{Accepted} \\
\text{ordinaryEffects} &= \varnothing \\
\text{appliedEffects} &= \text{collateralEffects} \\
\text{StoreAfter} &= \text{StoreBefore}
\end{aligned}
$$

The submission is accepted. Every ordinary spending input and allocation remains;
none of the proposed ordinary settlement outputs is created. Separate implicit
collateral funds the failure path:

```text
Implicit collateral input: 10 ₳
├── Implicit collateral return: 5 ₳
└── Fee pot increase:           5 ₳
```

The collateral input is consumed and its return is created. Since both are
implicit, this collateral transition makes no Store transfer.

<a id="ds-tx-presence-activity-spending-f05" name="ds-tx-presence-activity-spending-f05"></a>

**2.1.2.1.3.13 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/SpendingSpec.hs#L278) - One SubTx declaration is missing in a phase-2-invalid proposal**

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
&\qquad\land\ \text{SubMissingUTxODepositDeclaration}\in\text{failures} \\
&\qquad\land\ \text{ledgerAfter}=\text{ledgerBefore}
\end{aligned}
$$

Each submission must be rejected, including its collateral transition: collateral
inputs remain live, no collateral return is created, and fees do not increase.
Ordinary inputs and Store allocations also remain unchanged. The required
presence failure may accompany other accounting failures. This case tests
rejection of a proposal carrying a failing script; it does not claim that phase 2
was reached or executed.

<a id="ds-tx-presence-activity-scope" name="ds-tx-presence-activity-scope"></a>

###### 2.1.2.1.4 Scope

> **Keep each activity check within its own body and transaction path.**
>
> Nested outputs, reference inputs and collateral do not become TopTx’s own ordinary activity.

**Decision:** Agreed.

Presence belongs to each body separately. A parent declaration cannot substitute
for its child's declaration, and a child cannot supply its parent's declaration.
TopTx's own activity excludes nested SubTx outputs. The separate dependency rule
can nevertheless require TopTx to declare when a SubTx does.

Reference inputs do not consume deposits. Collateral inputs and collateral return
belong to the collateral path, so they do not become ordinary Store activity.
A creation-only check on input identifiers does not resolve those inputs or prove
that their separate spending or collateral rules are satisfied.

<a id="ds-tx-presence-activity-scope-n01" name="ds-tx-presence-activity-scope-n01"></a>

**2.1.2.1.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs#L38) - accepts an absent TopTx declaration for creation presence when only its nested SubTx creates store-backed outputs**

Nested SubTx outputs are not TopTx's own outputs. The TopTx creation validator therefore accepts an absent TopTx declaration when only the explicitly declared SubTx creates store-backed outputs. This is isolated-validator success: the separate dependency rule still requires TopTx to declare when a SubTx declares.

<a id="ds-tx-presence-activity-scope-n02" name="ds-tx-presence-activity-scope-n02"></a>

**2.1.2.1.4.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs#L44) - accepts an absent declaration for creation presence when only collateral return is store-backed**

Collateral return is outside the body's ordinary created-output sequence. A store-backed collateral return alone does not trigger the creation-presence validator. This does not establish that the collateral return satisfies its separate funding or settlement rules; it has no ordinary Store declaration field.

<a id="ds-tx-presence-activity-scope-n03" name="ds-tx-presence-activity-scope-n03"></a>

**2.1.2.1.4.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs#L46) - accepts an absent declaration for creation presence with reference or collateral input identifiers alone**

Reference and collateral input identifiers are not created outputs, so their presence alone does not trigger the creation-presence validator. This fixture does not resolve those identifiers to UTxOs and does not establish the complete reference-input or collateral rules.

<a id="ds-tx-presence-activity-scope-f01" name="ds-tx-presence-activity-scope-f01"></a>

**2.1.2.1.4.4 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs#L48) - rejects a missing TopTx declaration for its own store-backed outputs even when its nested SubTx declares**

A nested SubTx's explicit declaration cannot satisfy TopTx's own requirement. When TopTx creates store-backed own outputs and declares nothing, its isolated creation validator returns MissingBodyUTxODepositDeclaration even though the nested SubTx declares.

<a id="ds-tx-presence-activity-scope-f02" name="ds-tx-presence-activity-scope-f02"></a>

**2.1.2.1.4.5 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs#L55) - rejects a creating SubTx's missing declaration even when TopTx explicitly declares zero**

A TopTx declaration cannot substitute for its SubTx's missing declaration. Rejection must include `SubMissingUTxODepositDeclaration` and preserve the complete ledger state. TopTx's explicit zero also fails exactness because the new store-backed output requires a positive allocation; this independent failure does not replace the child's presence failure.

<a id="ds-tx-presence-activity-scope-n04" name="ds-tx-presence-activity-scope-n04"></a>

**2.1.2.1.4.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs#L60) - does not require a declaration merely for referencing a store-backed output**

Referencing a store-backed output neither consumes it nor releases its allocated deposit. Reference-only use therefore does not trigger ordinary declaration presence.

<a id="ds-tx-presence-activity-scope-n05" name="ds-tx-presence-activity-scope-n05"></a>

**2.1.2.1.4.7 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs#L61) - does not treat collateral inputs or collateral return as ordinary Store activity**

Collateral inputs and collateral return are evaluated by the separate collateral rules. Their presence alone must not be interpreted as ordinary body activity.

<a id="ds-tx-presence-activity-scope-n06" name="ds-tx-presence-activity-scope-n06"></a>

**2.1.2.1.4.8 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs#L62) - accepts Store activity in both TopTx and SubTx when each provides its own declaration**

Both bodies have Store activity and both declare it. Each declaration must meet its own presence obligation; the acceptance fixture also satisfies dependency and amount rules.

<a id="ds-tx-presence-activity-scope-f03" name="ds-tx-presence-activity-scope-f03"></a>

**2.1.2.1.4.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/Activity/ScopeSpec.hs#L63) - rejects a missing TopTx spending declaration even when a SubTx declares**

TopTx spends a store-backed input and creates no store-backed output, while a SubTx declares. Isolate the TopTx spending-presence validator: its field is still required. A complete-ledger check must identify the spending-presence failure, because the independent dependency rule also rejects a missing TopTx field.

<a id="ds-tx-presence-dependency" name="ds-tx-presence-dependency"></a>

##### 2.1.2.2 Dependency

> **Require TopTx to acknowledge the total whenever a SubTx declares.**
>
> Any SubTx declaration $\implies$ TopTx declaration. The amount is checked separately.

**Decision:** Agreed.

**Executable spec:** [DependencySpec.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs)

Categories, case identifiers and order match the executable spec. Short titles
introduce the cases; source links lead to their checks. Each linked test ID
completes its category tag: `N` for nominal cases, `F` for failures, and `P` for the
universal rule. Numbering restarts in each category.

**Reading the outcomes:** $\mathsf{PassesDependency}$ and $\mathsf{FailsDependency}$ concern only
declaration presence. $\mathsf{Accepted}$ and $\mathsf{Rejected}$ describe submission
of the prepared transaction to the ledger. Exact amounts and Store accounting are
covered by DS-TX-EXACTNESS-NETTING and DS-TX-EXACTNESS-CONTRIBUTION.

<a id="ds-tx-presence-dependency-c01" name="ds-tx-presence-dependency-c01"></a>

###### 2.1.2.2.1 Declaration dependency

> **Establish the direction of the dependency.**
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

If every SubTx omits its declaration, DS-TX-PRESENCE-DEPENDENCY imposes no requirement on TopTx.
DS-TX-PRESENCE-ACTIVITY may still require a declaration for TopTx's own Store activity.

<a id="ds-tx-presence-dependency-c01-p01" name="ds-tx-presence-dependency-c01-p01"></a>

**2.1.2.2.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L58) - SubTx declarations require TopTx's declaration**

Let $\mathrm{rejectsDependency}(\mathit{topTx})$ mean that the isolated validator
reports `MissingTopTxDeclaration`.

$$
\begin{aligned}
\mathrm{rejectsDependency}(\mathit{topTx})
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

###### 2.1.2.2.2 Absence and explicit zero

> **Distinguish saying nothing from declaring zero.**
>
> Absent $\ne$ Explicit zero. Explicit zero triggers dependency; absence alone does not.

**Situation:** TopTx and its single SubTx consume and create only implicit-deposit
outputs. There is no Store allocation or release. Each case submits a funded,
phase-2-valid transaction whose other ledger requirements are satisfied.

| TopTx declaration ↓ / SubTx declaration → | Absent | Explicit zero |
| --- | --- | --- |
| **Absent** | ✓ Accepted · N01 | ✗ Rejected · F01 |
| **Explicit zero** | ✓ Accepted · N03 | ✓ Accepted · N02 |

$\mathsf{Absent}$ means no declaration; $\mathsf{ExplicitZero}$ acknowledges a zero net
change. The latter still triggers the dependency:

$$
\mathrm{declaresZero}(\mathit{body})
\implies\mathrm{hasDeclaration}(\mathit{body})
$$

<a id="ds-tx-presence-dependency-c02-n01" name="ds-tx-presence-dependency-c02-n01"></a>

**2.1.2.2.2.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L63) - accepts absent declarations at both levels**

$$
\left.
\begin{aligned}
\mathit{topTxDeclaration} &= \mathsf{Absent} \\
\mathit{subTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\rbrace
\implies \mathsf{Accepted}
$$

**Why:** With no Store activity and no SubTx declaration, neither body needs to declare.

<a id="ds-tx-presence-dependency-c02-n02" name="ds-tx-presence-dependency-c02-n02"></a>

**2.1.2.2.2.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L67) - accepts explicit zero at both levels**

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

**2.1.2.2.2.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L71) - accepts TopTx zero without a SubTx declaration**

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

**2.1.2.2.2.4 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L75) - rejects SubTx zero without a TopTx declaration**

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

###### 2.1.2.2.3 Equal allocations and releases

> **Preserve declaration responsibility when amounts cancel.**
>
> Allocations $=$ releases $\implies$ net amount $= 0$, not absence of a declaration obligation.

**Situation:** Two SubTxs declare local operations using the same generated strictly
positive amount: one allocates it, the other releases it to output index zero. Their
declared contributions cancel; TopTx has no contribution of its own.

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

**2.1.2.2.3.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L81) - passes declaration presence with TopTx declaring the zero net amount**

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
\implies\mathsf{PassesDependency}
\end{gathered}
$$

**Why:** A zero net amount can be acknowledged explicitly. TopTx's zero declaration fulfils the
presence requirement for the two declaring SubTxs.

<a id="ds-tx-presence-dependency-c03-f01" name="ds-tx-presence-dependency-c03-f01"></a>

**2.1.2.2.3.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L84) - rejects an absent TopTx declaration despite the zero net amount**

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
\implies\mathsf{FailsDependency}
\end{gathered}
$$

**Why:** The amounts cancel, but the two declarations still exist. Their zero sum cannot
replace TopTx's explicit declaration.

**Expected failure:** `MissingTopTxDeclaration` from the isolated validator.

<a id="ds-tx-presence-dependency-c04" name="ds-tx-presence-dependency-c04"></a>

###### 2.1.2.2.4 Local and delegated accounting

> **Apply the same dependency to every explicit SubTx form.**
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

**2.1.2.2.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L89) - passes declaration presence with TopTx zero for every explicit SubTx form**

$$
\begin{gathered}
\forall \mathit{subTxDeclaration}\in\mathit{explicitSubTxDeclarations}: \\
\left.
\begin{aligned}
\mathit{subTxDeclarations} &= [\mathit{subTxDeclaration}] \\
\mathit{topTxDeclaration} &= \mathsf{ExplicitZero}
\end{aligned}
\right\rbrace
\implies\mathsf{PassesDependency}
\end{gathered}
$$

**Why:** Every explicit SubTx form finds the TopTx declaration it requires, regardless of where
the operation is accounted for.

<a id="ds-tx-presence-dependency-c04-f01" name="ds-tx-presence-dependency-c04-f01"></a>

**2.1.2.2.4.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L95) - rejects an absent TopTx declaration for every explicit SubTx form**

$$
\begin{gathered}
\forall \mathit{subTxDeclaration}\in\mathit{explicitSubTxDeclarations}: \\
\left.
\begin{aligned}
\mathit{subTxDeclarations} &= [\mathit{subTxDeclaration}] \\
\mathit{topTxDeclaration} &= \mathsf{Absent}
\end{aligned}
\right\rbrace
\implies\mathsf{FailsDependency}
\end{gathered}
$$

**Why:** Neither local accounting nor delegation removes the dependency. Every explicit form,
including zero, requires TopTx to declare.

**Expected failure:** `MissingTopTxDeclaration` for each individually checked form.

<a id="ds-tx-presence-dependency-c05" name="ds-tx-presence-dependency-c05"></a>

###### 2.1.2.2.5 Phase-2 failure

> **Preserve declaration dependency on the phase-2 failure path.**
>
> Failing scripts do not waive the TopTx declaration required by a SubTx.

**Situation:** The prepared transaction is marked phase-2 invalid and contains an
actual failing script plus collateral. Its single SubTx declares zero; neither body
has Store activity. Funding and preparation satisfy the other ledger requirements.

The cases submit the transaction to the ledger. They check declaration dependency on
the failure path, without independently checking collateral arithmetic or requiring
script evaluation to precede declaration rejection.

<a id="ds-tx-presence-dependency-c05-n01" name="ds-tx-presence-dependency-c05-n01"></a>

**2.1.2.2.5.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L104) - accepts zero declarations at both levels on the phase-2 failure path**

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

**Why:** Both declarations satisfy the dependency. The prepared transaction is accepted
on the phase-2 failure path, even though its script fails.

<a id="ds-tx-presence-dependency-c05-f01" name="ds-tx-presence-dependency-c05-f01"></a>

**2.1.2.2.5.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Presence/DependencySpec.hs#L108) - rejects SubTx zero without a TopTx declaration on the phase-2 failure path**

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

<a id="ds-tx-exactness" name="ds-tx-exactness"></a>

#### 2.1.3 Exactness

> **Check that declared amounts match deposit obligations.**
>
> - **Contribution:** the amount required by each body.
> - **Netting:** the total declared by TopTx.
>
> Conservation separately checks the complete transaction’s financial balance.

<a id="ds-tx-exactness-contribution" name="ds-tx-exactness-contribution"></a>

##### 2.1.3.1 Contribution

> **Check the deposit change caused by each body’s own inputs and outputs.**
>
> Required contribution $=$ new allocations $-$ released deposits. Delegation leaves this amount unchanged.

**Decision:** Agreed.

Required own changes are independent of declarations and delegation:

$$
\begin{aligned}
\text{requiredNetUTxODepositChange(body)}
&=\text{allocatedUTxODeposits(body)}-\text{releasedUTxODeposits(body)} \\
\text{requiredTxTotalNetUTxODepositChange}
&=\sum_{\text{body}\in\text{TopTx and all SubTx bodies}}
\text{requiredNetUTxODepositChange(body)}
\end{aligned}
$$

Read released deposits from the records of that body's consumed store-backed inputs.
Price newly created store-backed outputs under DS-PRICING. Reference inputs and
collateral are outside this ordinary calculation. These are required amounts for the
hypothetical ordinary transition on either phase-2 outcome; they do not assert that
ordinary effects are applied when phase 2 fails.

For each explicitly declared SubTx, require:

$$
\text{declaredSubTxNetUTxODepositChange(subTx)}
=\text{requiredNetUTxODepositChange(subTx)}
$$

| SubTx declaration | Signed declared own contribution |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | $0$ |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | $+\text{amount}$ |
| `SubTx.RequestsUTxODepositFromTopTx amount` | $+\text{amount}$ |
| `SubTx.DeclaresNetUTxODepositRelease amount target` | $-\text{amount}$, for either target |
| `SubTx.NoUTxODepositDeclaration` | No declared value; Presence permits this only without ordinary Store activity |

Allocation and release magnitudes must be exact, including delegated operations.
Voluntary excess allocations and withdrawals of unrelated Store surplus are invalid.
Two incorrect SubTx declarations remain invalid even when their errors cancel in the
batch total: requirements of $+3$ and $+3$ cannot be declared as $+5$ and $+1$.

TopTx has no separate own-contribution declaration. When explicit, its field supplies
`declaredTxTotalNetUTxODepositChange`, checked under Netting against the independently
required batch total. An own-contribution diagnostic can be derived as:

$$
\begin{aligned}
\text{derivedDeclaredTopTxOwnContribution}
&=\text{declaredTxTotalNetUTxODepositChange} \\
&\quad-\sum_{\text{subTx}\in\text{declared SubTxs}}
\text{declaredSubTxNetUTxODepositChange(subTx)}
\end{aligned}
$$

An absent SubTx contributes no declared value to this sum; after Presence, it has no
Store activity and its independently required change is zero. Remove **all** declared
SubTx contributions, including delegated ones, to derive TopTx's own contribution.
This differs from `topTxNetUTxODepositChange` in Attribution, which retains delegated
contributions. Once SubTx contributions are exact, comparing this diagnostic with
TopTx's required own change is equivalent to checking the TopTx batch total. It is
not another independent amount field or validation responsibility.

A SubTx consuming store-backed outputs and creating no new store-backed outputs has
a negative required own change equal to its released recorded deposits. It must declare
that exact release, including an explicit delegation target if it creates no local
settlement output. An explicit zero cannot replace a required negative **SubTx** change.
TopTx may legitimately declare an allocation or explicit zero while its own required
change is negative, because its declaration describes the whole batch.

For example, a SubTx releasing 3 ADA and another allocating 5 ADA, with no TopTx own
change, require a TopTx allocation declaration of 2 ADA. A TopTx own release of 3 ADA
and SubTx allocations of 3 ADA instead require TopTx explicit zero. Netting these
contributions does not erase their originating required changes or require a second
gross Store transfer.

**Executable contract:** Compare the isolated contribution validator with an independent
expected predicate while presence and required input/output data are valid. Derive
expectations from the input allocation records and accepted output sizes, not production
accounting helpers. Include local and delegated exact, zero, wrong-sign and off-by-one
amounts. Full-ledger failures preserve financial balance or identify the contribution
failure specifically; an unrelated conservation rejection does not prove exactness.
The same ordinary validation applies on both phase-2 outcomes. Actual Store effects
belong to State Execution. The current pricing policy is fixed; historical parameter
changes remain deferred under DS-PRICING-HISTORY.

<a id="ds-tx-exactness-contribution-p01" name="ds-tx-exactness-contribution-p01"></a>

###### 2.1.3.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L19) - Each SubTx declares its exact contribution

$$
\begin{aligned}
\text{PassesContribution}\iff\forall\,\text{subTx}\in\text{declared SubTxs}:\quad\\
\text{declaredSubTxNetUTxODepositChange(subTx)}
=\text{requiredNetUTxODepositChange(subTx)}
\end{aligned}
$$

With presence and input/output resolution satisfied, compare the isolated contribution validator's complete result with the independent equality for every declared SubTx. Generate both matching and mismatching amounts. Delegation does not change the required originating amount.

<a id="ds-tx-exactness-contribution-n01" name="ds-tx-exactness-contribution-n01"></a>

###### 2.1.3.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L20) - accepts a SubTx contribution equal to its allocated deposits minus its released deposits

The SubTx declares exactly its new obligations minus released input allocations. Exercise local and delegated allocation/release forms; these are valid controls for the corresponding amount mutations.

<a id="ds-tx-exactness-contribution-f01" name="ds-tx-exactness-contribution-f01"></a>

###### 2.1.3.1.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L21) - rejects a SubTx net allocation one lovelace below its required amount

Start from an exact net allocation and reduce the declaration by one lovelace. The resulting declaration must fail even if the overall Store remains solvent.

<a id="ds-tx-exactness-contribution-f02" name="ds-tx-exactness-contribution-f02"></a>

###### 2.1.3.1.4 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L22) - rejects a SubTx net allocation one lovelace above its required amount

Increase an exact net allocation by one lovelace. Voluntary overpayment is an accounting error, not an additional refundable deposit.

<a id="ds-tx-exactness-contribution-f03" name="ds-tx-exactness-contribution-f03"></a>

###### 2.1.3.1.5 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L23) - rejects a SubTx net release one lovelace below its required amount

Reduce the declared net release by one lovelace while keeping the consumed and created outputs fixed. The declaration no longer accounts exactly for the released obligation.

<a id="ds-tx-exactness-contribution-f04" name="ds-tx-exactness-contribution-f04"></a>

###### 2.1.3.1.6 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L24) - rejects a SubTx net release one lovelace above its required amount

Increase the declared release by one lovelace. Available Store surplus does not authorize withdrawing more than the body actually releases.

<a id="ds-tx-exactness-contribution-f05" name="ds-tx-exactness-contribution-f05"></a>

###### 2.1.3.1.7 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L25) - rejects opposing SubTx declaration errors even when they cancel in the batch total

One SubTx overstates its contribution while another understates by the same amount. Keep the TopTx batch total and overall financial balance correct. Neither SubTx exactness error is repaired by their cancellation.

<a id="ds-tx-exactness-contribution-n02" name="ds-tx-exactness-contribution-n02"></a>

###### 2.1.3.1.8 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L26) - derives TopTx's own contribution by removing all SubTx contributions from its declared batch total

Derive TopTx's own contribution by removing every declared SubTx contribution, including delegation, from the declared batch total. Compare it with TopTx's independently required own change. This diagnostic cross-checks Netting and SubTx exactness; it does not introduce an additional TopTx declaration.

<a id="ds-tx-exactness-contribution-n03" name="ds-tx-exactness-contribution-n03"></a>

###### 2.1.3.1.9 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L27) - accepts a SubTx explicit zero when its required own deposit change is zero

When a SubTx's new allocations equal its released recorded deposits, SubTx explicit zero is exact and satisfies presence. TopTx explicit zero instead depends on the complete batch total and is covered under Netting.

<a id="ds-tx-exactness-contribution-f06" name="ds-tx-exactness-contribution-f06"></a>

###### 2.1.3.1.10 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L28) - rejects a SubTx explicit zero when its required own deposit change is positive

The SubTx has a positive required own change. Its explicit-zero declaration satisfies presence but fails contribution equality, independently of how the batch is funded.

<a id="ds-tx-exactness-contribution-n04" name="ds-tx-exactness-contribution-n04"></a>

###### 2.1.3.1.11 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L29) - checks a delegated net allocation against the requesting SubTx's exact net UTxO capacity deposit change

A request to TopTx changes who accounts for the allocation. The requested positive amount must still equal the requesting SubTx’s allocations minus its releases.

<a id="ds-tx-exactness-contribution-n05" name="ds-tx-exactness-contribution-n05"></a>

###### 2.1.3.1.12 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L30) - checks a delegated net release against the originating SubTx's exact net UTxO capacity deposit change

Delegating the release does not permit releasing unrelated Store funds. Its amount must equal the originating SubTx’s releases minus its new allocations.

<a id="ds-tx-exactness-contribution-n06" name="ds-tx-exactness-contribution-n06"></a>

###### 2.1.3.1.13 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L31) - requires a SubTx net release when it spends store-backed outputs and creates only implicit outputs

The SubTx consumes store-backed inputs and creates only implicit outputs. Its new Store obligation is zero, so it declares the exact negative required own change. Its target must still satisfy settlement.

<a id="ds-tx-exactness-contribution-f07" name="ds-tx-exactness-contribution-f07"></a>

###### 2.1.3.1.14 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L32) - rejects a SubTx explicit zero when its required own deposit change is negative

The SubTx's inputs release a positive recorded amount and it creates no new store-backed outputs. SubTx explicit zero cannot replace this required negative own change. TopTx may still declare zero when other contributions offset it.

<a id="ds-tx-exactness-contribution-n07" name="ds-tx-exactness-contribution-n07"></a>

###### 2.1.3.1.15 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L33) - preserves a SubTx's declared net release when another body's allocation offsets it

Another body's allocation offsets the releasing SubTx in the required batch total. The SubTx still declares its own exact negative contribution, while TopTx declares the resulting batch allocation, release or explicit zero.

<a id="ds-tx-exactness-contribution-n08" name="ds-tx-exactness-contribution-n08"></a>

###### 2.1.3.1.16 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L34) - still requires the exact UTxO capacity deposit for an output with no application assets

Removing all application assets does not remove the address, encoding overhead or fixed 160-byte charge. The declared contribution must still cover the exact required allocation.

<a id="ds-tx-exactness-contribution-n09" name="ds-tx-exactness-contribution-n09"></a>

###### 2.1.3.1.17 [N09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L35) - accepts spending a translated implicit output to create store-backed outputs with the exact declared allocation and batch funding

Coins from a translated implicit output can fund a new store-backed output. The new allocation is declared exactly; spending the implicit input releases no Store deposit.

<a id="ds-tx-exactness-contribution-f08" name="ds-tx-exactness-contribution-f08"></a>

###### 2.1.3.1.18 [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L36) - rejects an inexact allocation when spending a translated implicit output to create store-backed outputs

Use a translated implicit input to fund a new store-backed output, but change the required allocation amount. Era history does not relax exact contribution accounting.

<a id="ds-tx-exactness-contribution-f09" name="ds-tx-exactness-contribution-f09"></a>

###### 2.1.3.1.19 [F09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L37) - rejects an unrelated release from pre-existing Store surplus

An existing Store surplus belongs to no additional deposit released by this body. Reject a declaration that tries to release that surplus even when the resulting Store would remain solvent.

<a id="ds-tx-exactness-contribution-f10" name="ds-tx-exactness-contribution-f10"></a>

###### 2.1.3.1.20 [F10](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L38) - rejects a SubTx release when its required own deposit change is positive

Keep a positive independently required SubTx change and supply a release declaration. Exercise local and delegated forms with all unrelated checks satisfied; reject the sign error.

<a id="ds-tx-exactness-contribution-f11" name="ds-tx-exactness-contribution-f11"></a>

###### 2.1.3.1.21 [F11](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L39) - rejects a SubTx allocation when its required own deposit change is negative

Keep a negative independently required SubTx change and supply a local allocation or funding request. Correct magnitude does not repair the wrong sign.

<a id="ds-tx-exactness-contribution-n10" name="ds-tx-exactness-contribution-n10"></a>

###### 2.1.3.1.22 [N10](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L40) - accepts exact SubTx contributions on the phase-2 failure path

Use exact local and delegated amounts with otherwise valid ordinary terms and actual phase-2 failure. Ordinary validation passes even though State Execution applies only collateral effects.

<a id="ds-tx-exactness-contribution-f12" name="ds-tx-exactness-contribution-f12"></a>

###### 2.1.3.1.23 [F12](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/ContributionSpec.hs#L41) - rejects an inexact SubTx contribution even when phase 2 fails

Mutate a SubTx contribution in the N10 controls and assert the contribution failure. Requirements are derived from the hypothetical ordinary transition; unapplied ordinary effects do not waive validation.

<a id="ds-tx-exactness-netting" name="ds-tx-exactness-netting"></a>

##### 2.1.3.2 Netting

> **Combine all body contributions into one TopTx declaration.**
>
> Declared batch change $=$ independently required batch change. Each body appears once.

**Decision:** Agreed.

TopTx supplies `declaredTxTotalNetUTxODepositChange` for the complete transaction. Independently derive `requiredTxTotalNetUTxODepositChange` from every body's own input allocation records and new output obligations, and require equality:

$$
\mathrm{declaredTxTotalNetUTxODepositChange}
= \mathrm{requiredTxTotalNetUTxODepositChange}
= \sum_{\mathit{body}\in\mathrm{bodies}(\mathit{tx})}
\mathrm{requiredNetUTxODepositChange}(\mathit{body})
$$

Delegation leaves this total unchanged. It changes the body responsible for accounting
for a contribution under DS-TX-ATTRIBUTION. SubTx contribution exactness remains mandatory even
when two errors cancel in this sum. Netting owns the TopTx total check; a derived
TopTx own-contribution equality is a diagnostic consequence, not another declaration.

| Allocations | Releases | Net declaration | Store change on ordinary success |
| --- | --- | --- | --- |
| 5 ADA | 3 ADA | Allocate 2 ADA | $+2$ ADA |
| 3 ADA | 5 ADA | Release 2 ADA | −2 ADA |
| 5 ADA | 5 ADA | Explicit zero | 0 ADA |

These examples use ADA for readability; interface amounts use lovelace. Presence
rules determine when an explicit declaration is required. Net zero does not turn an
explicit declaration into absence.

On ordinary success, the declared total is the Store transfer for the transaction, not an additional
transfer to add to its SubTx contributions. Accepted phase-2 failure applies no ordinary transfer. A 3 ADA release delegated to TopTx can
offset a 5 ADA local allocation: the resulting Store transfer is a 2 ADA allocation,
with no separate 3 ADA payment from the Store.

<a id="ds-tx-exactness-netting-p01" name="ds-tx-exactness-netting-p01"></a>

###### 2.1.3.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L32) - TopTx declares the exact transaction total

$$
\begin{aligned}
\text{PassesNetting}\iff\quad\\
\text{declaredTxTotalNetUTxODepositChange}
=\text{requiredTxTotalNetUTxODepositChange}
\end{aligned}
$$

For an explicit TopTx field and exact SubTx contributions, compare the isolated netting validator with $\text{declaredTxTotalNetUTxODepositChange}=\text{requiredTxTotalNetUTxODepositChange}$. Independently sum TopTx's and every SubTx's required own changes, including delegated contributions once; generate both exact and invalid supplied totals.

<a id="ds-tx-exactness-netting-n01" name="ds-tx-exactness-netting-n01"></a>

###### 2.1.3.2.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L33) - includes both TopTx and SubTx UTxO capacity deposit changes in the declared total

Cover a nonzero TopTx own change combined with SubTx changes, and zero TopTx own change with a nonzero SubTx total. In both, TopTx declares the required batch total, regardless of local or delegated accounting.

<a id="ds-tx-exactness-netting-n02" name="ds-tx-exactness-netting-n02"></a>

###### 2.1.3.2.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L34) - nets a 5 ADA allocation and a 3 ADA release into a TopTx allocation of 2 ADA

Allocating 5 ADA and releasing 3 ADA yields a single 2 ADA net allocation. Successful application increases the Store by 2 ADA; there is no separate 3 ADA gross payment.

<a id="ds-tx-exactness-netting-n03" name="ds-tx-exactness-netting-n03"></a>

###### 2.1.3.2.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L35) - nets a 3 ADA allocation and a 5 ADA release into a TopTx release of 2 ADA

Allocating 3 ADA and releasing 5 ADA yields a single 2 ADA net release. The settlement choice is checked separately from this total.

<a id="ds-tx-exactness-netting-n04" name="ds-tx-exactness-netting-n04"></a>

###### 2.1.3.2.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L36) - uses TopTx explicit zero when nonzero body contributions cancel exactly

Equal allocation and release contributions produce a zero net transfer. When a declaration is required, use the explicit-zero form rather than omit the field.

<a id="ds-tx-exactness-netting-f01" name="ds-tx-exactness-netting-f01"></a>

###### 2.1.3.2.6 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L37) - rejects a TopTx net allocation one lovelace below the required batch total

Generate a TopTx without SubTxs that consumes recorded deposits but requires more
new allocation than it releases. Prepare its exact, funded declaration, then reduce
that declared allocation by one lovelace and re-sign:

$$
\text{declared net deposit} = \text{required net deposit} - 1\text{ lovelace}
$$

Rejection must include `InexactTopTxDepositChange`; an additional conservation
failure cannot stand in for it. The complete ledger state remains unchanged.

<a id="ds-tx-exactness-netting-f02" name="ds-tx-exactness-netting-f02"></a>

###### 2.1.3.2.7 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L45) - rejects a TopTx net allocation one lovelace above the required batch total

Use the same funded standalone allocation shape as F01, but increase the declaration
by one lovelace. Require `InexactTopTxDepositChange` and unchanged ledger state.
Voluntary extra Store funding is not an exact declaration.

<a id="ds-tx-exactness-netting-f03" name="ds-tx-exactness-netting-f03"></a>

###### 2.1.3.2.8 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L53) - rejects a TopTx net release one lovelace below the required batch release

Generate a TopTx without SubTxs that consumes recorded deposits and creates only
implicit outputs. Prepare its exact release, then reduce the released magnitude by
one lovelace. Its signed declaration is therefore one lovelace greater than required.
Require `InexactTopTxDepositChange`, independently of any conservation failure, and
preserve the complete ledger state.

<a id="ds-tx-exactness-netting-f04" name="ds-tx-exactness-netting-f04"></a>

###### 2.1.3.2.9 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L61) - rejects a TopTx net release one lovelace above the required batch release

Use the implicit-only output shape of F03, but increase the released magnitude by
one lovelace. Its signed declaration is one lovelace smaller than required. Require
`InexactTopTxDepositChange` and unchanged ledger state: funds associated with
unrelated outputs cannot justify the extra release.

<a id="ds-tx-exactness-netting-f05" name="ds-tx-exactness-netting-f05"></a>

###### 2.1.3.2.10 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L69) - rejects TopTx explicit zero when the required batch total is nonzero

Exercise required positive and negative batch totals while all SubTx declarations remain exact. TopTx explicit zero satisfies presence but fails netting.

<a id="ds-tx-exactness-netting-f06" name="ds-tx-exactness-netting-f06"></a>

###### 2.1.3.2.11 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L70) - rejects a nonzero TopTx declaration when the required batch total is zero

Use exact offsetting body contributions and attempt both a positive allocation and a negative release declaration. The required batch declaration is explicit zero.

<a id="ds-tx-exactness-netting-f07" name="ds-tx-exactness-netting-f07"></a>

###### 2.1.3.2.12 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L71) - rejects a TopTx declaration whose sign opposes the required batch total

Exercise both sign reversals with exact SubTx declarations. TopTx must declare the signed batch total, not its own or its attributed amount.

<a id="ds-tx-exactness-netting-n05" name="ds-tx-exactness-netting-n05"></a>

###### 2.1.3.2.13 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L72) - accepts TopTx explicit zero when its own release is offset by SubTx allocations

TopTx releases 3 ADA through its own inputs while exact SubTx allocations contribute 3 ADA. TopTx declares zero; its derived own contribution remains -3 ADA. No TopTx settlement selector is introduced into explicit zero.

<a id="ds-tx-exactness-netting-n06" name="ds-tx-exactness-netting-n06"></a>

###### 2.1.3.2.14 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L73) - accepts TopTx explicit zero when its own allocation is offset by SubTx releases

TopTx's own required change is $+3$ ADA and exact SubTx releases sum to $-3$ ADA. TopTx declares zero while SubTx release targets still satisfy their applicable settlement rules.

<a id="ds-tx-exactness-netting-n07" name="ds-tx-exactness-netting-n07"></a>

###### 2.1.3.2.15 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L74) - accepts an exact TopTx batch total on the phase-2 failure path

Keep the hypothetical ordinary deposit changes and all declarations exact in an otherwise valid transaction with actual phase-2 failure. Accept the collateral outcome without applying the ordinary Store transfer.

<a id="ds-tx-exactness-netting-f08" name="ds-tx-exactness-netting-f08"></a>

###### 2.1.3.2.16 [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L75) - rejects an inexact TopTx batch total even when phase 2 fails

Mutate only the total under test from an N07 control, preserving other checks or asserting the specific netting failure. Ordinary netting validation precedes outcome-specific execution.

<a id="ds-tx-exactness-netting-f09" name="ds-tx-exactness-netting-f09"></a>

###### 2.1.3.2.17 [F09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Exactness/NettingSpec.hs#L76) - rejects a TopTx total that omits or double-counts a delegated contribution

Use exact delegated allocation and release declarations in separate cases. Omit that originating contribution from the TopTx total, then count it twice; both supplied totals must fail the independent sum of required body changes.

<a id="ds-tx-attribution" name="ds-tx-attribution"></a>

#### 2.1.4 Attribution

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
derived under DS-TX-EXACTNESS-CONTRIBUTION removes all declared SubTx contributions,
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
in Exactness, Conservation, Presence and Settlement respectively.

<a id="ds-tx-attribution-p01" name="ds-tx-attribution-p01"></a>

##### 2.1.4.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L18) - observed TopTx and local SubTx attribution matches the independent signed contribution projection

Compare actual production attribution with an independently written declaration-form projection: local allocation/release maps to $+\text{amount}$/$-\text{amount}$, delegation and explicit zero map to zero locally. TopTx retains its own contribution plus delegated contributions. The resulting sum recovers the declared total; do not calculate both sides from the same subtraction and test only that tautology.

<a id="ds-tx-attribution-p02" name="ds-tx-attribution-p02"></a>

##### 2.1.4.2 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L19) - switching local and delegated accounting changes attribution by the signed contribution and preserves the required batch change

For both allocation and release, switch the SubTx accounting mode while keeping originating activity fixed. Check the observed signed attribution shift and unchanged required batch total. This does not promise unchanged ledger acceptance if the new responsibility requires a different settlement selector or coverage.

<a id="ds-tx-attribution-n01" name="ds-tx-attribution-n01"></a>

##### 2.1.4.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L20) - counts delegated funding once in TopTx accounting

A delegated request is already a contribution to the transaction total. Attribute it to TopTx without adding a second Store allocation for the same request.

<a id="ds-tx-attribution-n02" name="ds-tx-attribution-n02"></a>

##### 2.1.4.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L21) - keeps the same batch net change when a SubTx delegates funding of its net allocation

Changing a SubTx allocation from local accounting to a TopTx request leaves the required Store transfer unchanged. Only the attribution changes.

<a id="ds-tx-attribution-n03" name="ds-tx-attribution-n03"></a>

##### 2.1.4.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L22) - allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx

A SubTx can consume its store-backed inputs without creating outputs and explicitly delegate its release. Settlement and batch funding are then handled according to TopTx attribution.

<a id="ds-tx-grammar-n01" name="ds-tx-grammar-n01"></a>
<a id="ds-tx-attribution-n04" name="ds-tx-attribution-n04"></a>

##### 2.1.4.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AttributionSpec.hs#L23) - observes zero local and delegated amounts with no funding request for SubTx explicit zero

Give a SubTx an explicit-zero declaration and observe the production accounting result: zero local contribution, zero delegated contribution and no funding request. Use an otherwise valid zero-change fixture. Recognizing or round-tripping the zero constructor alone does not establish this attribution behavior; declaration representation belongs to Grammar.

<a id="ds-tx-conservation" name="ds-tx-conservation"></a>

#### 2.1.5 Conservation

> **Require the complete transaction to balance.**
>
> All consumed value $=$ all produced value, including the net Store transfer once. Individual SubTxs may remain financially imbalanced.

**Decision:** Agreed.

TopTx must balance the complete batch. SubTx may be individually imbalanced; their
contributions must be included in the final conservation check.

Expressing the existing consumed and produced values before adding the new DepositStore
term, require (`inject` adds only ADA):

$$
\text{txTotalNetRelease}=\max(0,-\text{declaredTxTotalNetUTxODepositChange})
$$

$$
\begin{aligned}
&\text{consumedValue(batch)}+\text{inject}(\text{txTotalNetRelease}) \\
&\qquad=\text{producedValue(batch)}
+\text{inject}(\max(0,\text{declaredTxTotalNetUTxODepositChange}))
\end{aligned}
$$

`declaredTxTotalNetUTxODepositChange` is positive for `TopTx.DeclaresNetUTxODepositAllocation`,
negative for `TopTx.DeclaresNetUTxODepositRelease`, and zero for
`TopTx.DeclaresZeroNetUTxODeposit`. `txTotalNetRelease` is the amount in TopTx's
`TopTx.DeclaresNetUTxODepositRelease`, or zero otherwise. An absent declaration has no declared value. If all declarations are absent, Presence requires no ordinary Store activity, so no Store term is added and existing $\text{consumedValue}=\text{producedValue}$ applies. This accounting identity does not turn absence into explicit zero.

Exactness separately establishes that the supplied total equals `requiredTxTotalNetUTxODepositChange`. These ordinary validation equations apply on both phase-2 outcomes, using hypothetical ordinary effects; State Execution selects the effects actually applied.

Consumed and produced values include the complete batch's inputs, outputs and other
existing ledger terms, including fees and existing deposit/refund rules. The net store
amount is counted once, using TopTx's declaration; SubTx store contributions are not
added again. This equality preserves all assets, whereas DS-TX-EXACTNESS-CONTRIBUTION concerns exact ADA
UTxO capacity deposit accounting for each body.



A local release does not prohibit a SubTx from exporting ADA to fund TopTx fees
or another body. The derived accounting quantity is:

$$
\text{netADAExport}
=\text{ordinaryConsumedADA}+\text{localRelease}-\text{ordinaryProducedADA}
$$

Positive values contribute ADA to the rest of the transaction; negative values receive
funding. This is not an additional field or an independent SubTx balance constraint.

| SubTx input ADA | Local release | Only output | Net ADA export |
| --- | --- | --- | --- |
| 10 | 2 | 12 | 0 |
| 10 | 2 | 10 | 2, for example to TopTx fees |

Without exports or other ADA terms, the output must contain 12 ADA. An output of 10
ADA is compatible with conservation only if the remaining 2 ADA is accounted for
elsewhere in the complete transaction.

Ordinary amounts exclude DepositStore transfers. Consumed ADA includes regular input
coins, account withdrawals and applicable refunds. Produced ADA includes regular output
coins, certificate and proposal deposits, treasury donations and direct account deposits.
Attribute certificate effects in their actual batch processing order. TopTx fees are not
a SubTx charge in this calculation. The existing destination bound remains mandatory;
stronger local-settlement guarantees remain open under DS-TX-SETTLEMENT-REFINEMENT.

<a id="ds-tx-conservation-p01" name="ds-tx-conservation-p01"></a>

##### 2.1.5.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L19) - The transaction conserves value

$$
\begin{aligned}
&\text{Accepted}\land\text{hasDeclaration(topTx)}\\
&\implies\text{consumedValue}+\text{inject}(\max(0,-\text{declaredTxTotalNetUTxODepositChange}))\\
&\qquad=\text{producedValue}+\text{inject}(\max(0,\text{declaredTxTotalNetUTxODepositChange}))
\end{aligned}
$$

For accepted transactions with an explicit TopTx declaration on either phase-2 outcome, independently compare complete ordinary consumed and produced values, adding the declared signed Store term once. This is validation of the hypothetical ordinary batch, not a claim that its effects apply on phase-2 failure. Include accepted coverage for both outcomes and every asset; do not derive the expected values using production conservation helpers.

<a id="ds-tx-conservation-p02" name="ds-tx-conservation-p02"></a>

##### 2.1.5.2 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L20) - with other rules satisfied, ledger acceptance agrees with batch conservation even when SubTxs are financially imbalanced

Generate balanced and imbalanced complete batches with individually imbalanced SubTxs, keeping all other requirements valid, including existing legacy-mode restrictions. Ledger acceptance must agree with independent whole-batch conservation; no new SubTx balance constraint is introduced.

<a id="ds-tx-conservation-n01" name="ds-tx-conservation-n01"></a>

##### 2.1.5.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L21) - counts the net allocation once on the produced side

A positive net Store allocation is part of produced value. SubTx contributions already included in the TopTx total must not be added again.

<a id="ds-tx-conservation-n02" name="ds-tx-conservation-n02"></a>

##### 2.1.5.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L22) - counts the net release once on the consumed side

A net release supplies consumed value to the transaction. Adding both the TopTx total and its SubTx release contributions would create an erroneous second credit.

<a id="ds-tx-conservation-n03" name="ds-tx-conservation-n03"></a>

##### 2.1.5.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L23) - accepts financially imbalanced SubTxs when the complete batch balances

A surplus in one body can fund another body. This remains valid when all declaration requirements and the complete transaction equality hold.

<a id="ds-tx-conservation-n04" name="ds-tx-conservation-n04"></a>

##### 2.1.5.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L24) - preserves a SubTx's ability to contribute ADA to TopTx fees

Preserve the existing ability of SubTx application ADA to contribute to TopTx fees. DepositStore accounting must not introduce an independent balance constraint for each SubTx.

<a id="ds-tx-conservation-f01" name="ds-tx-conservation-f01"></a>

##### 2.1.5.7 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L25) - rejects a batch imbalance of one lovelace

Change one ADA term by one lovelace in an otherwise balanced transaction. Exact deposit declarations do not excuse the resulting financial imbalance.

<a id="ds-tx-conservation-f02" name="ds-tx-conservation-f02"></a>

##### 2.1.5.8 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L26) - rejects a native-asset imbalance even when ADA balances

Keep ADA balanced while introducing a native-asset mismatch. DepositStore transfers concern ADA and cannot fund or erase a native-asset discrepancy.

<a id="ds-tx-conservation-f03" name="ds-tx-conservation-f03"></a>

##### 2.1.5.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L27) - rejects a delegation request that the complete batch does not fund

A request can have the correct amount and attribution while the complete transaction lacks funds. Conservation must reject that shortfall.

<a id="ds-tx-conservation-n05" name="ds-tx-conservation-n05"></a>

##### 2.1.5.10 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L28) - accepts offsetting delegated operations in a financially balanced batch

Delegated allocations and releases can offset each other. Acceptance depends on exact declarations and the complete transaction balance, not a demand that every SubTx balance independently.

<a id="ds-tx-conservation-n06" name="ds-tx-conservation-n06"></a>

##### 2.1.5.11 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L29) - requires an output of 12 ADA for 10 input ADA and a 2 ADA net release with no other ADA flows

With 10 ADA consumed, a 2 ADA release, one output and no other ADA terms or exports, conservation fixes that output at 12 ADA. This example does not impose independent SubTx balance in other scenarios.

<a id="ds-tx-conservation-n07" name="ds-tx-conservation-n07"></a>

##### 2.1.5.12 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L30) - allows an output of 10 ADA when the other 2 ADA contributes to TopTx fees

The same 10 ADA input and 2 ADA release can produce a 10 ADA output while exporting 2 ADA to TopTx fees. The complete transaction must account for that export.

<a id="ds-tx-conservation-f04" name="ds-tx-conservation-f04"></a>

##### 2.1.5.13 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L31) - rejects a 10 ADA output for 10 input ADA and a 2 ADA release when all other batch flows stay fixed

Begin with N06's balanced batch and reduce the SubTx output from 12 ADA to 10 ADA while leaving every other output, fee, source and charge unchanged. Reject the resulting 2 ADA batch imbalance. This does not prohibit exports that are actually accounted elsewhere, as in N07.

<a id="ds-tx-conservation-n08" name="ds-tx-conservation-n08"></a>

##### 2.1.5.14 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L32) - accepts ordinary batch conservation on the phase-2 failure path

An actual failing phase-2 script does not prevent a transaction with valid hypothetical ordinary conservation from taking the collateral outcome. State Execution determines its applied effects separately.

<a id="ds-tx-conservation-f05" name="ds-tx-conservation-f05"></a>

##### 2.1.5.15 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ConservationSpec.hs#L33) - rejects an ordinary batch imbalance even when phase 2 fails

Keep exact declarations, valid settlement and valid collateral while introducing an ordinary batch imbalance. Assert the ordinary conservation failure even though the transaction is marked phase-2 invalid.

<a id="ds-tx-authorization" name="ds-tx-authorization"></a>

#### 2.1.6 Authorization

> **Determine who may release an output’s allocated deposit.**
>
> Release authority follows spending authority, rather than the identity of the original deposit funder.

**Decision:** Agreed.

On the ordinary successful spending path, the authority to release an output's allocated
UTxO capacity deposit follows that output's spending conditions. Satisfy its existing key or
script authorization; no separate DepositStore release credential or witness is
required. Funding the original deposit gives the funder no retained refund claim or
additional approval right.

Released UTxO capacity deposits participate in exact accounting under DS-TX-EXACTNESS. A body whose
released UTxO capacity deposits exceed its newly allocated UTxO capacity deposits has a release
contribution. SubTx declares its own contribution; TopTx declares the net change for the
complete batch. Batch netting and settlement still follow DS-TX-EXACTNESS-NETTING, DS-TX-SETTLEMENT-PARTICIPATION and
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

##### 2.1.6.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L11) - allows the authorized spender to release UTxO capacity deposits paid by another person

Alice funds an output controlled by Bob; Bob later spends it with exact deposit accounting and valid settlement. Observe release under Bob's spending authority despite Alice having supplied the original funds.

<a id="ds-tx-authorization-n02" name="ds-tx-authorization-n02"></a>

##### 2.1.6.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L12) - does not require a separate signature from the original UTxO capacity deposit funder

Use the same two-party lifecycle but explicitly inspect the final witness set: Bob's required witness is present and Alice's is absent. Acceptance proves that no separate original-funder approval is required.

<a id="ds-tx-authorization-f01" name="ds-tx-authorization-f01"></a>

##### 2.1.6.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L13) - rejects spending by the original funder without the current spending authority even when the Store declaration is exact

From the otherwise valid two-party control, supply Alice's witness and omit Bob's required spending witness. Assert the existing authorization failure despite exact ordinary deposit declarations and valid settlement.

<a id="ds-tx-authorization-n03" name="ds-tx-authorization-n03"></a>

##### 2.1.6.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L14) - gains no release authority merely by referencing a store-backed output

Referencing Alice/Bob's output gives the referencing body no authority to claim its associated deposit. A reference-only fixture is accepted without that release; an attempted release cannot become authorized by adding the reference. Presence owns whether a field is needed, and State Allocations owns preservation of the live record.

<a id="ds-tx-settlement" name="ds-tx-settlement"></a>

#### 2.1.7 Settlement

> **Determine which output must contain a release amount.**
>
> Participation $\longrightarrow$ destination $\longrightarrow$ coverage. Settlement uses the accounting result without adding another Store transfer.

<a id="ds-tx-settlement-participation" name="ds-tx-settlement-participation"></a>

##### 2.1.7.1 Participation

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

The operation's amount always remains the entire batch's net release under DS-TX-EXACTNESS-NETTING. It
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
UTxO capacity deposit contribution in DS-TX-EXACTNESS-CONTRIBUTION, `topTxNetUTxODepositChange` includes
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
A net allocation or explicit zero still follows DS-TX-EXACTNESS-NETTING and does not introduce a TopTx
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

###### 2.1.7.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L17) - TopTx settles its attributed release

$$
\text{PassesParticipation}
\iff(\text{usesNoTopTxSettlement}\iff\text{topTxNetRelease}=0)
$$

For exact net-release declarations, compare the isolated participation validator with the required selector derived independently from signed local contributions. $\text{topTxNetRelease}=0$ includes zero and positive attributed TopTx changes. A positive release share requires a selected TopTx output; destination and coverage are separate checks.

<a id="ds-tx-settlement-participation-n01" name="ds-tx-settlement-participation-n01"></a>

###### 2.1.7.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L18) - requires NoTopTxSettlement when SubTxs settle the entire net release locally

SubTx bodies settle the entire release locally, leaving no release share attributed to TopTx. The declaration therefore uses NoTopTxSettlement.

<a id="ds-tx-settlement-participation-n02" name="ds-tx-settlement-participation-n02"></a>

###### 2.1.7.1.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L19) - requires a TopTx settlement output when the batch declares a net release and TopTx has a positive share

The net-release transaction leaves a positive TopTx share. TopTx must identify the output that covers it.

<a id="ds-tx-settlement-participation-n03" name="ds-tx-settlement-participation-n03"></a>

###### 2.1.7.1.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L20) - accepts a net release settled across TopTx and SubTx outputs

One transaction can settle part of its release in SubTx outputs and the remainder in TopTx. Each destination must cover its own share.

<a id="ds-tx-settlement-participation-n04" name="ds-tx-settlement-participation-n04"></a>

###### 2.1.7.1.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L21) - allows TopTx's settlement amount to exceed the batch net release when SubTxs account for net allocations locally

A local SubTx allocation of 3 ADA can combine with TopTx’s 5 ADA release contribution. The Store releases only 2 ADA net, while the TopTx output must cover its derived 5 ADA share.

<a id="ds-tx-settlement-participation-f01" name="ds-tx-settlement-participation-f01"></a>

###### 2.1.7.1.6 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L22) - rejects NoTopTxSettlement when the batch declares a net release and TopTx has a positive share

A positive derived TopTx share remains after local SubTx accounting. NoTopTxSettlement would leave that share without its required destination.

<a id="ds-tx-settlement-participation-f02" name="ds-tx-settlement-participation-f02"></a>

###### 2.1.7.1.7 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L23) - rejects a TopTx settlement output when TopTx has no net release to settle

TopTx has no release share in this net-release transaction. Its declaration must use NoTopTxSettlement rather than designate an unnecessary output.

<a id="ds-tx-settlement-participation-n05" name="ds-tx-settlement-participation-n05"></a>

###### 2.1.7.1.8 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L24) - does not require a TopTx settlement output when the batch declares a net allocation

The transaction declares a net allocation, so its TopTx declaration has no release-settlement output. A delegated release can be absorbed by other allocations without a separate Store payment.

<a id="ds-tx-settlement-participation-n06" name="ds-tx-settlement-participation-n06"></a>

###### 2.1.7.1.9 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L25) - does not require a TopTx settlement output for an explicit-zero batch even when TopTx's derived accounting portion is negative

The transaction declares explicit zero. Even if the signed portion attributed to TopTx is negative, the net-release-only settlement selector is not introduced into this declaration form.

<a id="ds-tx-settlement-participation-n07" name="ds-tx-settlement-participation-n07"></a>

###### 2.1.7.1.10 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L26) - accepts NoTopTxSettlement when TopTx's attributed contribution is a net allocation

A local SubTx release of 5 ADA offsets TopTx's own allocation of 3 ADA: the batch declares a release of 2 ADA, TopTx attribution is $+3$ ADA, and $\text{topTxNetRelease}=0$. Accept NoTopTxSettlement; do not require attributed TopTx change itself to equal zero.

<a id="ds-tx-settlement-participation-n08" name="ds-tx-settlement-participation-n08"></a>

###### 2.1.7.1.11 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L27) - accepts correct release participation on the phase-2 failure path

Use both permitted participation branches with exact ordinary declarations and actual phase-2 failure. Their selectors are validated even though ordinary settlement outputs are not applied.

<a id="ds-tx-settlement-participation-f03" name="ds-tx-settlement-participation-f03"></a>

###### 2.1.7.1.12 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/ParticipationSpec.hs#L28) - rejects incorrect release participation even when phase 2 fails

From N08 controls, omit a required TopTx selector or supply one when no TopTx release is attributed. Assert participation failure on the phase-2 failure path.

<a id="ds-tx-settlement-destination" name="ds-tx-settlement-destination"></a>

##### 2.1.7.2 Destination

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

###### 2.1.7.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L17) - Settlement indices belong to their own body

$$
\begin{aligned}
\text{PassesDestination}\iff\forall\,\text{selectedDestination}:\quad\\
0\le\text{selectedIndex}<\text{length(own regular outputs)}
\end{aligned}
$$

With otherwise valid participation, compare isolated index validation against $0\le\text{index}<\text{length(own regular outputs)}$ for both body levels. Include valid boundaries and invalid indices; being in range in another sequence is insufficient. Generate selected-output observations independently of production index resolution.

<a id="ds-tx-settlement-destination-f01" name="ds-tx-settlement-destination-f01"></a>

###### 2.1.7.2.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L18) - rejects an index outside the declaring body's output sequence

Use a settlement index beyond the owning body’s output sequence. The ledger must reject rather than ignore the destination or choose a replacement.

<a id="ds-tx-settlement-destination-f02" name="ds-tx-settlement-destination-f02"></a>

###### 2.1.7.2.3 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L19) - does not resolve a SubTx settlement index against TopTx outputs

A SubTx index is interpreted locally. An output with the same index in TopTx cannot satisfy that local target.

<a id="ds-tx-settlement-destination-f03" name="ds-tx-settlement-destination-f03"></a>

###### 2.1.7.2.4 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L20) - does not resolve a settlement index against collateral return

Collateral return is not an ordinary output in the settlement index space. Its value cannot repair an invalid ordinary target.

<a id="ds-tx-settlement-destination-f04" name="ds-tx-settlement-destination-f04"></a>

###### 2.1.7.2.5 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L21) - rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs

A local index cannot identify an output in an empty sequence. The transaction must reject this target rather than resolve it against another body’s outputs.

<a id="ds-tx-settlement-destination-n01" name="ds-tx-settlement-destination-n01"></a>

###### 2.1.7.2.6 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L22) - accepts the first and last own regular output as settlement destinations

For TopTx and SubTx separately, select index zero and the final valid index in an otherwise valid fixture. Resolve the selected output from its owning body; other output sequences do not affect validity.

<a id="ds-tx-settlement-destination-f05" name="ds-tx-settlement-destination-f05"></a>

###### 2.1.7.2.7 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L23) - does not resolve a TopTx settlement index against nested SubTx outputs

Choose an index outside TopTx's own outputs but inside a nested or concatenated output sequence. Reject it even when a SubTx output could cover the settlement amount.

<a id="ds-tx-settlement-destination-f06" name="ds-tx-settlement-destination-f06"></a>

###### 2.1.7.2.8 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L24) - does not resolve a SubTx settlement index against a sibling SubTx's outputs

Choose an index outside the declaring SubTx's own outputs but valid in a sibling. Sibling outputs cannot satisfy the declaring body's destination requirement.

<a id="ds-tx-settlement-destination-n02" name="ds-tx-settlement-destination-n02"></a>

###### 2.1.7.2.9 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L25) - accepts valid ordinary settlement destinations on the phase-2 failure path

Use correct own-output indices at both body levels in an otherwise valid transaction with actual phase-2 failure. Ordinary destination validation succeeds before collateral-only execution.

<a id="ds-tx-settlement-destination-f07" name="ds-tx-settlement-destination-f07"></a>

###### 2.1.7.2.10 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DestinationSpec.hs#L26) - rejects an invalid ordinary settlement index even when phase 2 fails

Replace a valid N02 index with the first out-of-bounds index and assert the destination failure. Unapplied ordinary outputs do not excuse an invalid selector.

<a id="ds-tx-settlement-coverage" name="ds-tx-settlement-coverage"></a>

##### 2.1.7.3 Coverage

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
remain permitted under DS-TX-CONSERVATION. The stronger local-settlement guarantee
remains a separate open question under DS-TX-SETTLEMENT-REFINEMENT.

<a id="ds-tx-settlement-coverage-p01" name="ds-tx-settlement-coverage-p01"></a>

###### 2.1.7.3.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L18) - Settlement outputs cover their release share

$$
\begin{aligned}
\text{PassesCoverage}\iff\forall\,\text{selectedOutput}:\quad\\
\text{applicationADA(selectedOutput)}\ge\text{settlementAmount(selectedOutput)}
\end{aligned}
$$

With valid participation and indices, compare the isolated coverage validator against independently derived settlement amounts and selected application ADA. Generate equality, surplus and shortfall for both body levels and output variants. Preserve batch conservation in ledger shortfall cases by accounting for the removed ADA elsewhere.

<a id="ds-tx-settlement-coverage-f01" name="ds-tx-settlement-coverage-f01"></a>

###### 2.1.7.3.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L19) - rejects a settlement output containing less ADA than its settlement amount

The selected output exists but contains less ADA than its allocated settlement amount. Valid index resolution alone is insufficient.

<a id="ds-tx-settlement-coverage-n01" name="ds-tx-settlement-coverage-n01"></a>

###### 2.1.7.3.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L20) - accepts a settlement output containing exactly its settlement amount

The selected output contains exactly its settlement share. Equality satisfies the coverage lower bound.

<a id="ds-tx-settlement-coverage-n02" name="ds-tx-settlement-coverage-n02"></a>

###### 2.1.7.3.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L21) - accepts a settlement output containing the settlement amount and additional funds

The selected output contains its settlement amount plus other funds. The rule is a lower bound and does not require equality.

<a id="ds-tx-settlement-coverage-f02" name="ds-tx-settlement-coverage-f02"></a>

###### 2.1.7.3.5 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L22) - rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference

The selected store-backed output’s application ADA is too small. Its externally held capacity deposit is unavailable to cover that settlement shortfall.

<a id="ds-tx-settlement-coverage-n03" name="ds-tx-settlement-coverage-n03"></a>

###### 2.1.7.3.6 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L23) - accepts a store-backed settlement output with application ADA equal to the settlement amount

A store-backed output’s application ADA equals its settlement amount. Its separately allocated capacity deposit neither increases nor reduces this coverage.

<a id="ds-tx-settlement-coverage-n04" name="ds-tx-settlement-coverage-n04"></a>

###### 2.1.7.3.7 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L24) - checks TopTx's derived settlement amount rather than the entire batch net release

Cover both directions: batch release 5 ADA with TopTx share 2 ADA accepts a 2 ADA TopTx output; batch release 2 ADA with TopTx share 5 ADA requires a 5 ADA TopTx output. F04 supplies the negative counterpart for confusing the smaller batch amount with the larger share.

<a id="ds-tx-settlement-coverage-n05" name="ds-tx-settlement-coverage-n05"></a>

###### 2.1.7.3.8 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L25) - accepts covered ordinary settlement outputs on the phase-2 failure path

With exact declarations and valid selectors, provide the required application ADA in selected outputs at both body levels. An actual phase-2 failure selects collateral effects after this ordinary check passes.

<a id="ds-tx-settlement-coverage-f03" name="ds-tx-settlement-coverage-f03"></a>

###### 2.1.7.3.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L26) - rejects insufficient ordinary settlement coverage even when phase 2 fails

Reduce a selected ordinary output below its independently required settlement amount in an N05 fixture, accounting for the removed ADA elsewhere to preserve conservation. Assert coverage failure despite phase-2 invalidity.

<a id="ds-tx-settlement-coverage-f04" name="ds-tx-settlement-coverage-f04"></a>

###### 2.1.7.3.10 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/CoverageSpec.hs#L27) - rejects a TopTx output that covers the batch release but not TopTx's larger attributed release

Use the local $+3$ ADA SubTx allocation and $-5$ ADA TopTx contribution: batch release is 2 ADA, but TopTx coverage requires 5 ADA. An output containing 2 ADA fails even though it covers the entire batch net release; keep conservation valid with the remaining ADA elsewhere.

<a id="ds-tx-application-assets" name="ds-tx-application-assets"></a>

#### 2.1.8 Application assets

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
subject to the explicit declaration and exact accounting requirements of DS-TX-PRESENCE-ACTIVITY and
DS-TX-EXACTNESS-CONTRIBUTION.

This permission does not relax other output validation, including nonnegative asset
amounts, size limits or address validity. Implicit-deposit outputs retain their existing
minimum-coin requirements. A store-backed collateral return may also have zero
application value, provided the collateral funding and settlement rules hold; the
externally held UTxO capacity deposits do not count as its application coins.

<a id="ds-tx-application-assets-n01" name="ds-tx-application-assets-n01"></a>

##### 2.1.8.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L17) - accepts a store-backed output containing native assets and zero ADA

The output carries native assets but no application ADA. Its storage is paid through an exact external deposit, so an implicit minimum-ADA condition must not be imposed on its application value.

<a id="ds-tx-application-assets-n02" name="ds-tx-application-assets-n02"></a>

##### 2.1.8.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L18) - accepts empty application assets with a datum or reference script

Exercise datum-only and reference-script-only outputs as separate fixture cases, each with empty application assets. Their full accepted encodings determine their exact external deposits; output admissibility remains separate from pricing.

<a id="ds-tx-application-assets-n03" name="ds-tx-application-assets-n03"></a>

##### 2.1.8.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L19) - accepts a store-backed output containing only an address

Even an address-only output occupies priced storage. Empty application assets are permitted when its deposit and the remaining transaction requirements are satisfied.

<a id="ds-tx-application-assets-n04" name="ds-tx-application-assets-n04"></a>

##### 2.1.8.4 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L20) - accepts implicit outputs containing exactly their required minimum coin

For TopTx and SubTx separately, use an implicit output with exactly the minimum ADA required by its accepted size. Acceptance is the control for F01's one-lovelace shortfall; the store-backed exemption must not weaken implicit-output validation.

<a id="ds-tx-application-assets-f01" name="ds-tx-application-assets-f01"></a>

##### 2.1.8.5 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/ApplicationAssetsSpec.hs#L21) - rejects implicit outputs one lovelace below their required minimum coin

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
> Redeemers in TopTx or any SubTx trigger the requirement. Store activity alone does not.

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

Given otherwise valid ordinary Store activity with no redeemers anywhere in the batch, omit collateral. Its absence must not cause collateral rejection merely because outputs are store-backed or a body declares a Store operation.

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

If every declaration is absent, ordinary acceptance requires no Store activity.
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

This preserves any pre-existing surplus; it does not assume that every initial or migrated state has zero surplus. Nor does it turn unrelated surplus into a refund claim: exact contributions still restrict a release to the body's actual change in allocated deposits. That rejection belongs to [Exactness](#ds-tx-exactness): Contribution checks SubTx amounts and Netting checks the TopTx total. Solvency and total ADA conservation are separately checked under `DS-STATE-SOLVENCY` and `DS-STATE-CONSERVATION`.

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

Given an ordinary successful batch with an explicit TopTx declaration, compare the actual Store balance before and after application. Its change must equal the supplied total, already checked against independently derived obligations by Exactness, without adding SubTx contributions again.

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

For a batch, observe Store backing in the completed TopTx and SubTx result, including local and delegated contributions. Temporary intermediate accounting is not an accepted ledger state. `DS-TX-CONSERVATION` owns whether financially imbalanced SubTxs form an acceptable batch; a solvency observation checks the resulting Store balance and obligations rather than repeating that acceptance assertion. On accepted phase-2 failure, only applied collateral effects can supply funding; ordinary declarations that were not applied cannot do so.

The invariant applies throughout the accepted lifecycle: initialization and Conway-to-Dijkstra translation, ordinary execution, collateral processing, fixed-policy epochs, state restoration and rollback. Generate valid sequences and require accepted examples for each outcome so rejection of every transaction cannot satisfy the invariant vacuously. The present executable scope assumes a fixed pricing policy. The eventual parameter-change policy must also preserve solvency, but these tests do not establish that future behavior.

For independently calculated $\text{obligations} > 0$, the proposed-state invariant has these one-lovelace boundaries:

| Proposed Store balance | Proposed obligations | Invariant result |
| --- | --- | --- |
| $\text{obligations} - 1\text{ lovelace}$ | $\text{obligations}$ | False |
| $\text{obligations}$ | $\text{obligations}$ | True |
| $\text{obligations} + 1\text{ lovelace}$ | $\text{obligations}$ | True |

These are boundary checks for the independent state oracle, not transaction acceptance examples. Passing the inequality does not establish exact contributions, authorize a release or validate settlement. An excessive release still fails Exactness (SubTx Contribution or TopTx Netting), even if the proposed balance would remain solvent.

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

Given an accepted batch with local and delegated contributions, compare the completed Store balance with independently retained live obligations. Include mixed allocations and releases and SubTxs that need not balance independently. Assert the backing relation in the resulting state; batch financial acceptance is checked under `DS-TX-CONSERVATION`.

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

This is an assertion about the applied ledger state across all relevant pots. `DS-TX-CONSERVATION` separately checks the complete ordinary batch's consumed and produced values, while `DS-COLLATERAL-CONSERVATION` checks the collateral settlement equation. Satisfying an equation before application does not by itself prove that the state update preserves total ADA.

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

DS-TX-EXACTNESS requires exact UTxO capacity deposit accounting and rejects voluntary excess net
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

| Previous rule | Current responsibilities |
| --- | --- |
| `DS-TX-001` | [DS-TX-PRESENCE-ACTIVITY-SPENDING](#ds-tx-presence-activity-spending), [DS-TX-PRESENCE-ACTIVITY-CREATION](#ds-tx-presence-activity-creation), [DS-TX-PRESENCE-ACTIVITY-SCOPE](#ds-tx-presence-activity-scope), [DS-TX-PRESENCE-ACTIVITY](#ds-tx-presence-activity) |
| `DS-TX-002` | [DS-TX-EXACTNESS-NETTING](#ds-tx-exactness-netting), [DS-TX-ATTRIBUTION](#ds-tx-attribution), [DS-TX-SETTLEMENT-PARTICIPATION](#ds-tx-settlement-participation) |
| `DS-TX-003` | [DS-TX-EXACTNESS-CONTRIBUTION](#ds-tx-exactness-contribution) |
| `DS-TX-004` | [DS-TX-CONSERVATION](#ds-tx-conservation) |
| `DS-TX-005` | [DS-TX-EXACTNESS-CONTRIBUTION](#ds-tx-exactness-contribution), [DS-TX-ATTRIBUTION](#ds-tx-attribution), [DS-TX-SETTLEMENT-DESTINATION](#ds-tx-settlement-destination) |
| `DS-TX-006` | [DS-TX-SETTLEMENT-PARTICIPATION](#ds-tx-settlement-participation) |
| `DS-TX-007` | [DS-TX-CONSERVATION](#ds-tx-conservation), [DS-TX-SETTLEMENT-DESTINATION](#ds-tx-settlement-destination), [DS-TX-SETTLEMENT-COVERAGE](#ds-tx-settlement-coverage), [DS-STATE-EXECUTION](#ds-state-execution) |
| `DS-TX-008` | [DS-TX-GRAMMAR](#ds-tx-grammar), [DS-TX-EXACTNESS-CONTRIBUTION](#ds-tx-exactness-contribution) |
| `DS-TX-009` | [DS-TX-PRESENCE-DEPENDENCY](#ds-tx-presence-dependency) |
| `DS-TX-010` | [DS-TX-EXACTNESS-CONTRIBUTION](#ds-tx-exactness-contribution), [DS-TX-ATTRIBUTION](#ds-tx-attribution), [DS-TX-CONSERVATION](#ds-tx-conservation) |
| `DS-TX-011` | [DS-TX-AUTHORIZATION](#ds-tx-authorization) |
| `DS-TX-012` | [DS-TX-EXACTNESS-CONTRIBUTION](#ds-tx-exactness-contribution), [DS-TX-APPLICATION-ASSETS](#ds-tx-application-assets) |
| `DS-COLL-001` | [DS-COLLATERAL-SCOPE](#ds-collateral-scope), [DS-COLLATERAL-AUTHORIZATION](#ds-collateral-authorization), [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-COLLATERAL-CONSERVATION](#ds-collateral-conservation) |
| `DS-COLL-002` | [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-COLLATERAL-SURPLUS](#ds-collateral-surplus), [DS-COLLATERAL-SETTLEMENT](#ds-collateral-settlement), [DS-COLLATERAL-CONSERVATION](#ds-collateral-conservation) |
| `DS-COLL-003` | [DS-COLLATERAL-FUNDING](#ds-collateral-funding), [DS-COLLATERAL-TOTAL](#ds-collateral-total) |
| `DS-COLL-004` | [DS-COLLATERAL-SETTLEMENT](#ds-collateral-settlement), [DS-STATE-EXECUTION](#ds-state-execution), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-BALANCE](#ds-state-balance) |
| `DS-STORE-001` | [DS-TX-EXACTNESS-CONTRIBUTION](#ds-tx-exactness-contribution), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-BALANCE](#ds-state-balance), [DS-STATE-SOLVENCY](#ds-state-solvency) |
| `DS-STORE-002` | [DS-PRICING-HISTORY](#ds-pricing-history) |
| `DS-STORE-003` | [DS-PRICING](#ds-pricing), [DS-STATE-ALLOCATIONS](#ds-state-allocations) |
| `DS-STORE-004` | [DS-TX-EXACTNESS-CONTRIBUTION](#ds-tx-exactness-contribution), [DS-TX-PRESENCE-ACTIVITY-CREATION](#ds-tx-presence-activity-creation), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-INITIALIZATION](#ds-state-initialization) |
| `DS-STORE-005` | [DS-STATE-EXECUTION](#ds-state-execution), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-RECOVERY](#ds-state-recovery) |
| `DS-PLUTUS-001` | [DS-PLUTUS-COMPATIBILITY](#ds-plutus-compatibility) |
| `DS-STAKE-001` | [DS-STATE-CONSERVATION](#ds-state-conservation), [DS-STAKE](#ds-stake), [DS-VOTING](#ds-voting) |

The accounting observation formerly registered as `DS-TX-GRAMMAR-N01` now lives at
[DS-TX-ATTRIBUTION-N04](#ds-tx-attribution-n04). Its old anchor redirects to that case;
the primitive boundary check formerly registered as `DS-TX-GRAMMAR-N02` now belongs
to ledger-core's `StrictlyPositiveCoinSpec`. Grammar nominal identifiers therefore
begin at N03; neither retired identity is reassigned.
The former combined invalid-amount check keeps [F01](#ds-tx-grammar-f01) for TopTx
zero. Its remaining TopTx assertions use [F12](#ds-tx-grammar-f12) for negative
amounts and [F13](#ds-tx-grammar-f13) for overflowing amounts.
Its SubTx assertions are split into [F07](#ds-tx-grammar-f07) for zero,
[F08](#ds-tx-grammar-f08) for negative amounts and [F09](#ds-tx-grammar-f09) for
overflowing amounts; F07 retains the zero case from the former combined SubTx check.
The former combined SubTx target check keeps [F05](#ds-tx-grammar-f05) for invalid
structure. Its index range assertions now have separate tags:
[F10](#ds-tx-grammar-f10) for negative indices and [F11](#ds-tx-grammar-f11) for
indices above 65535. Similarly, the former combined TopTx settlement check keeps
[F04](#ds-tx-grammar-f04) for invalid structure; [F14](#ds-tx-grammar-f14) covers
negative indices and [F15](#ds-tx-grammar-f15) covers indices above 65535.
These checks concern decoding; output existence remains under
[DS-TX-SETTLEMENT-DESTINATION](#ds-tx-settlement-destination).

The previously individually tagged declaration-dependency cases map as follows:

| Previous case | Current case |
| --- | --- |
| `DS-TX-009-C01-P01` | [DS-TX-PRESENCE-DEPENDENCY-C01-P01](#ds-tx-presence-dependency-c01-p01) |
| `DS-TX-009-C02-N01` | [DS-TX-PRESENCE-DEPENDENCY-C02-N01](#ds-tx-presence-dependency-c02-n01) |
| `DS-TX-009-C02-N02` | [DS-TX-PRESENCE-DEPENDENCY-C02-N02](#ds-tx-presence-dependency-c02-n02) |
| `DS-TX-009-C02-N03` | [DS-TX-PRESENCE-DEPENDENCY-C02-N03](#ds-tx-presence-dependency-c02-n03) |
| `DS-TX-009-C02-F01` | [DS-TX-PRESENCE-DEPENDENCY-C02-F01](#ds-tx-presence-dependency-c02-f01) |
| `DS-TX-009-C03-N01` | [DS-TX-PRESENCE-DEPENDENCY-C03-N01](#ds-tx-presence-dependency-c03-n01) |
| `DS-TX-009-C03-F01` | [DS-TX-PRESENCE-DEPENDENCY-C03-F01](#ds-tx-presence-dependency-c03-f01) |
| `DS-TX-009-C04-N01` | [DS-TX-PRESENCE-DEPENDENCY-C04-N01](#ds-tx-presence-dependency-c04-n01) |
| `DS-TX-009-C04-F01` | [DS-TX-PRESENCE-DEPENDENCY-C04-F01](#ds-tx-presence-dependency-c04-f01) |
| `DS-TX-009-C05-N01` | [DS-TX-PRESENCE-DEPENDENCY-C05-N01](#ds-tx-presence-dependency-c05-n01) |
| `DS-TX-009-C05-F01` | [DS-TX-PRESENCE-DEPENDENCY-C05-F01](#ds-tx-presence-dependency-c05-f01) |
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
│   │   └── Output.hs
│   ├── OutputIndex.hs
│   ├── StrictlyPositiveCoin.hs
│   └── Assertions.hs
├── Encoding.hs
├── Encoding/
│   ├── CBOR.hs
│   └── JSON.hs
├── Submission.hs
└── Submission/
    ├── Declaration.hs
    └── Output.hs
```

| Module family | Responsibility |
| --- | --- |
| `Specs.Tx.Declaration` | Describe a TopTx's declarations and its ordered SubTx declarations; construct bodies and generate declaration combinations. |
| `Specs.Tx.Declaration.TopTx` / `SubTx` | Provide each body's declaration forms, generators, raw decoder fixtures and declaration predicates. |
| `Specs.Tx.Output` | Describe and construct own-output arrangements for the specifications. |
| `Specs.OutputIndex` / `StrictlyPositiveCoin` | Provide shared index generators and checked amount fixtures. |
| `Specs.Assertions` | Apply a supplied expectation to one or more observations. |
| `Encoding` | Observe CBOR and JSON behavior together, with a separate implementation for each format. |
| `Submission` | Fund and prepare ledger transactions, preserve fixtures through fixup, submit and check ledger outcomes. Its declaration and output modules register the scenario rows. |

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

DS-TX-PRESENCE-ACTIVITY applies separately to each top-level transaction body and each sub-transaction
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
specify their contributions and where they are accounted for, as defined in DS-TX-EXACTNESS-NETTING.

In body-generic tables, `NoUTxODepositDeclaration` means the qualified pattern for
that body's level. `hasDeclaration(body)` is false for that pattern and true for every
explicit declaration, including `DeclaresZeroNetUTxODeposit`.

For DS-TX-PRESENCE-ACTIVITY, an output means the `TxOut` inside a `Sized` element of the body's own
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

[Grammar](#ds-tx-grammar) owns declaration forms and declaration decoder rejection,
including enforcement of `StrictlyPositiveCoin` amounts. The type's construction
and scalar codecs belong to ledger-core's `StrictlyPositiveCoinSpec`.
The [declaration codec specification](../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Binary/Golden.hs)
retains independent exact-byte/JSON goldens, historical field omission and malformed
payload checks through both transaction-body decoders.
These representation checks establish which forms can be expressed. Presence,
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
