# Dijkstra ledger rules for minimum-ADA and deposit-backed outputs

[Deposit declarations](declarations.md) · [Verification record](verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-deposit-store/README.md)

The *UTxO Deposit versus UTxO Minimum ADA* proposal describes two ways
to back an output's storage. A minimum-ADA output carries its reserve in its
own value. For a deposit-backed output, the ledger accounts for the deposit
separately. These rules specify how Dijkstra prices that backing, checks the
transaction's declaration and settles the change.

The declarations chapter covers TopTx and SubTx forms and when each body must
declare. Rule identifiers link each contract to its executable cases. The
verification record gives their implementation status and dated test results.

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
          <a href="#ds-pricing-p01">1.4.1 P01 - Price each created output</a><br>
          <a href="#ds-pricing-n01">1.4.2 N01 - Count distinct native assets</a><br>
          <a href="#ds-pricing-n02">1.4.3 N02 - Price an applied collateral return</a><br>
          <a href="#ds-pricing-n03">1.4.4 N03 - Measure datum and reference script payloads</a><br>
          <a href="#ds-pricing-n04">1.4.5 N04 - Vary the declaration independently</a><br>
          <a href="#ds-pricing-n05">1.4.6 N05 - Preserve the price across ADA encoding boundaries</a><br>
          <a href="#ds-pricing-n06">1.4.7 N06 - Keep a min-ADA reserve inside its output</a><br>
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
            <summary><a href="declarations.md#ds-tx-declarations">2.1.1 Declarations</a></summary>
            <dl>
              <dd>
                <details>
                  <summary><a id="ds-tx-grammar" name="ds-tx-grammar"></a><a id="ds-tx-declarations-grammar" name="ds-tx-declarations-grammar"></a><a id="2111-grammar" name="2111-grammar"></a><a id="ds-tx-grammar-n02" name="ds-tx-grammar-n02"></a><a id="ds-tx-declarations-grammar-n02" name="ds-tx-declarations-grammar-n02"></a><a href="declarations.md#ds-tx-declarations-grammar">2.1.1.1 Grammar</a></summary>
                  <dl>
                    <dd>
                      <details>
                        <summary><a id="ds-tx-grammar-toptx" name="ds-tx-grammar-toptx"></a><a id="ds-tx-declarations-grammar-toptx" name="ds-tx-declarations-grammar-toptx"></a><a id="21111-toptx" name="21111-toptx"></a><a href="declarations.md#ds-tx-declarations-grammar-toptx">2.1.1.1.1 TopTx</a></summary>
                        <dl>
                          <dd>
                            <details>
                              <summary><a id="ds-tx-grammar-amounts" name="ds-tx-grammar-amounts"></a><a id="ds-tx-declarations-grammar-amounts" name="ds-tx-declarations-grammar-amounts"></a><a id="ds-tx-grammar-toptx-amounts" name="ds-tx-grammar-toptx-amounts"></a><a id="ds-tx-declarations-grammar-toptx-amounts" name="ds-tx-declarations-grammar-toptx-amounts"></a><a href="declarations.md#ds-tx-declarations-grammar-toptx-amounts">2.1.1.1.1.1 Amounts</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-p01" name="ds-tx-grammar-p01"></a><a id="ds-tx-declarations-grammar-p01" name="ds-tx-declarations-grammar-p01"></a><a href="declarations.md#ds-tx-declarations-grammar-p01">2.1.1.1.1.1.1 P01 - Positive amounts survive encoding</a><br>
                                  <a id="ds-tx-grammar-f01" name="ds-tx-grammar-f01"></a><a id="ds-tx-declarations-grammar-f01" name="ds-tx-declarations-grammar-f01"></a><a href="declarations.md#ds-tx-declarations-grammar-f01">2.1.1.1.1.1.2 F01 - Zero operation amount</a><br>
                                  <a id="ds-tx-grammar-f12" name="ds-tx-grammar-f12"></a><a id="ds-tx-declarations-grammar-f12" name="ds-tx-declarations-grammar-f12"></a><a href="declarations.md#ds-tx-declarations-grammar-f12">2.1.1.1.1.1.3 F12 - Negative operation amount</a><br>
                                  <a id="ds-tx-grammar-f13" name="ds-tx-grammar-f13"></a><a id="ds-tx-declarations-grammar-f13" name="ds-tx-declarations-grammar-f13"></a><a href="declarations.md#ds-tx-declarations-grammar-f13">2.1.1.1.1.1.4 F13 - Overflowing operation amount</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-grammar-absence" name="ds-tx-grammar-absence"></a><a id="ds-tx-declarations-grammar-absence" name="ds-tx-declarations-grammar-absence"></a><a id="ds-tx-grammar-toptx-absence" name="ds-tx-grammar-toptx-absence"></a><a id="ds-tx-declarations-grammar-toptx-absence" name="ds-tx-declarations-grammar-toptx-absence"></a><a href="declarations.md#ds-tx-declarations-grammar-toptx-absence">2.1.1.1.1.2 Absence</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-n03" name="ds-tx-grammar-n03"></a><a id="ds-tx-declarations-grammar-n03" name="ds-tx-declarations-grammar-n03"></a><a href="declarations.md#ds-tx-declarations-grammar-n03">2.1.1.1.1.2.1 N03 - Absence remains distinct from zero</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-grammar-forms" name="ds-tx-grammar-forms"></a><a id="ds-tx-declarations-grammar-forms" name="ds-tx-declarations-grammar-forms"></a><a id="ds-tx-grammar-toptx-forms" name="ds-tx-grammar-toptx-forms"></a><a id="ds-tx-declarations-grammar-toptx-forms" name="ds-tx-declarations-grammar-toptx-forms"></a><a href="declarations.md#ds-tx-declarations-grammar-toptx-forms">2.1.1.1.1.3 Forms</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-n05" name="ds-tx-grammar-n05"></a><a id="ds-tx-declarations-grammar-n05" name="ds-tx-declarations-grammar-n05"></a><a href="declarations.md#ds-tx-declarations-grammar-n05">2.1.1.1.1.3.1 N05 - Every TopTx declaration form</a><br>
                                  <a id="ds-tx-grammar-f06" name="ds-tx-grammar-f06"></a><a id="ds-tx-declarations-grammar-f06" name="ds-tx-declarations-grammar-f06"></a><a href="declarations.md#ds-tx-declarations-grammar-f06">2.1.1.1.1.3.2 F06 - Funding request in TopTx</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-grammar-structure" name="ds-tx-grammar-structure"></a><a id="ds-tx-declarations-grammar-structure" name="ds-tx-declarations-grammar-structure"></a><a id="ds-tx-grammar-toptx-structure" name="ds-tx-grammar-toptx-structure"></a><a id="ds-tx-declarations-grammar-toptx-structure" name="ds-tx-declarations-grammar-toptx-structure"></a><a href="declarations.md#ds-tx-declarations-grammar-toptx-structure">2.1.1.1.1.4 Structure</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-f02" name="ds-tx-grammar-f02"></a><a id="ds-tx-declarations-grammar-f02" name="ds-tx-declarations-grammar-f02"></a><a href="declarations.md#ds-tx-declarations-grammar-f02">2.1.1.1.1.4.1 F02 - Malformed declarations</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-grammar-destinations" name="ds-tx-grammar-destinations"></a><a id="ds-tx-declarations-grammar-destinations" name="ds-tx-declarations-grammar-destinations"></a><a id="ds-tx-grammar-toptx-destinations" name="ds-tx-grammar-toptx-destinations"></a><a id="ds-tx-declarations-grammar-toptx-destinations" name="ds-tx-declarations-grammar-toptx-destinations"></a><a href="declarations.md#ds-tx-declarations-grammar-toptx-destinations">2.1.1.1.1.5 Destinations</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-f04" name="ds-tx-grammar-f04"></a><a id="ds-tx-declarations-grammar-f04" name="ds-tx-declarations-grammar-f04"></a><a href="declarations.md#ds-tx-declarations-grammar-f04">2.1.1.1.1.5.1 F04 - Malformed release settlements</a><br>
                                  <a id="ds-tx-grammar-f14" name="ds-tx-grammar-f14"></a><a id="ds-tx-declarations-grammar-f14" name="ds-tx-declarations-grammar-f14"></a><a href="declarations.md#ds-tx-declarations-grammar-f14">2.1.1.1.1.5.2 F14 - Negative output index</a><br>
                                  <a id="ds-tx-grammar-f15" name="ds-tx-grammar-f15"></a><a id="ds-tx-declarations-grammar-f15" name="ds-tx-declarations-grammar-f15"></a><a href="declarations.md#ds-tx-declarations-grammar-f15">2.1.1.1.1.5.3 F15 - Overflowing output index</a><br>
                                </dd>
                              </dl>
                            </details>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a id="ds-tx-grammar-subtx" name="ds-tx-grammar-subtx"></a><a id="ds-tx-declarations-grammar-subtx" name="ds-tx-declarations-grammar-subtx"></a><a id="21112-subtx" name="21112-subtx"></a><a href="declarations.md#ds-tx-declarations-grammar-subtx">2.1.1.1.2 SubTx</a></summary>
                        <dl>
                          <dd>
                            <details>
                              <summary><a id="ds-tx-grammar-subtx-amounts" name="ds-tx-grammar-subtx-amounts"></a><a id="ds-tx-declarations-grammar-subtx-amounts" name="ds-tx-declarations-grammar-subtx-amounts"></a><a href="declarations.md#ds-tx-declarations-grammar-subtx-amounts">2.1.1.1.2.1 Amounts</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-p02" name="ds-tx-grammar-p02"></a><a id="ds-tx-declarations-grammar-p02" name="ds-tx-declarations-grammar-p02"></a><a href="declarations.md#ds-tx-declarations-grammar-p02">2.1.1.1.2.1.1 P02 - Positive amounts survive encoding</a><br>
                                  <a id="ds-tx-grammar-f07" name="ds-tx-grammar-f07"></a><a id="ds-tx-declarations-grammar-f07" name="ds-tx-declarations-grammar-f07"></a><a href="declarations.md#ds-tx-declarations-grammar-f07">2.1.1.1.2.1.2 F07 - Zero operation amount</a><br>
                                  <a id="ds-tx-grammar-f08" name="ds-tx-grammar-f08"></a><a id="ds-tx-declarations-grammar-f08" name="ds-tx-declarations-grammar-f08"></a><a href="declarations.md#ds-tx-declarations-grammar-f08">2.1.1.1.2.1.3 F08 - Negative operation amount</a><br>
                                  <a id="ds-tx-grammar-f09" name="ds-tx-grammar-f09"></a><a id="ds-tx-declarations-grammar-f09" name="ds-tx-declarations-grammar-f09"></a><a href="declarations.md#ds-tx-declarations-grammar-f09">2.1.1.1.2.1.4 F09 - Overflowing operation amount</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-grammar-subtx-absence" name="ds-tx-grammar-subtx-absence"></a><a id="ds-tx-declarations-grammar-subtx-absence" name="ds-tx-declarations-grammar-subtx-absence"></a><a href="declarations.md#ds-tx-declarations-grammar-subtx-absence">2.1.1.1.2.2 Absence</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-n04" name="ds-tx-grammar-n04"></a><a id="ds-tx-declarations-grammar-n04" name="ds-tx-declarations-grammar-n04"></a><a href="declarations.md#ds-tx-declarations-grammar-n04">2.1.1.1.2.2.1 N04 - Absence remains distinct from zero</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-grammar-subtx-forms" name="ds-tx-grammar-subtx-forms"></a><a id="ds-tx-declarations-grammar-subtx-forms" name="ds-tx-declarations-grammar-subtx-forms"></a><a href="declarations.md#ds-tx-declarations-grammar-subtx-forms">2.1.1.1.2.3 Forms</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-n06" name="ds-tx-grammar-n06"></a><a id="ds-tx-declarations-grammar-n06" name="ds-tx-declarations-grammar-n06"></a><a href="declarations.md#ds-tx-declarations-grammar-n06">2.1.1.1.2.3.1 N06 - Every SubTx declaration form</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-grammar-subtx-structure" name="ds-tx-grammar-subtx-structure"></a><a id="ds-tx-declarations-grammar-subtx-structure" name="ds-tx-declarations-grammar-subtx-structure"></a><a href="declarations.md#ds-tx-declarations-grammar-subtx-structure">2.1.1.1.2.4 Structure</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-f03" name="ds-tx-grammar-f03"></a><a id="ds-tx-declarations-grammar-f03" name="ds-tx-declarations-grammar-f03"></a><a href="declarations.md#ds-tx-declarations-grammar-f03">2.1.1.1.2.4.1 F03 - Malformed declarations</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-grammar-subtx-destinations" name="ds-tx-grammar-subtx-destinations"></a><a id="ds-tx-declarations-grammar-subtx-destinations" name="ds-tx-declarations-grammar-subtx-destinations"></a><a href="declarations.md#ds-tx-declarations-grammar-subtx-destinations">2.1.1.1.2.5 Destinations</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-grammar-f05" name="ds-tx-grammar-f05"></a><a id="ds-tx-declarations-grammar-f05" name="ds-tx-declarations-grammar-f05"></a><a href="declarations.md#ds-tx-declarations-grammar-f05">2.1.1.1.2.5.1 F05 - Malformed release targets</a><br>
                                  <a id="ds-tx-grammar-f10" name="ds-tx-grammar-f10"></a><a id="ds-tx-declarations-grammar-f10" name="ds-tx-declarations-grammar-f10"></a><a href="declarations.md#ds-tx-declarations-grammar-f10">2.1.1.1.2.5.2 F10 - Negative output index</a><br>
                                  <a id="ds-tx-grammar-f11" name="ds-tx-grammar-f11"></a><a id="ds-tx-declarations-grammar-f11" name="ds-tx-declarations-grammar-f11"></a><a href="declarations.md#ds-tx-declarations-grammar-f11">2.1.1.1.2.5.3 F11 - Overflowing output index</a><br>
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
                  <summary><a id="ds-tx-presence" name="ds-tx-presence"></a><a id="ds-tx-required-declarations" name="ds-tx-required-declarations"></a><a id="ds-tx-declarations-requirements" name="ds-tx-declarations-requirements"></a><a id="2112-requirements" name="2112-requirements"></a><a href="declarations.md#ds-tx-declarations-requirements">2.1.1.2 Requirements</a></summary>
                  <dl>
                    <dd>
                      <details>
                        <summary><a id="ds-tx-presence-activity" name="ds-tx-presence-activity"></a><a id="ds-tx-presence-activity-scope" name="ds-tx-presence-activity-scope"></a><a id="ds-tx-presence-operations-scope" name="ds-tx-presence-operations-scope"></a><a id="ds-tx-presence-operations" name="ds-tx-presence-operations"></a><a id="ds-tx-required-declarations-operations" name="ds-tx-required-declarations-operations"></a><a id="ds-tx-declarations-requirements-operations" name="ds-tx-declarations-requirements-operations"></a><a id="21121-operations" name="21121-operations"></a><a href="declarations.md#ds-tx-declarations-requirements-operations">2.1.1.2.1 Operations</a></summary>
                        <dl>
                          <dd>
                            <a id="ds-tx-presence-activity-p01" name="ds-tx-presence-activity-p01"></a><a id="ds-tx-presence-operations-p01" name="ds-tx-presence-operations-p01"></a><a id="ds-tx-required-declarations-operations-p01" name="ds-tx-required-declarations-operations-p01"></a><a id="ds-tx-declarations-requirements-operations-p01" name="ds-tx-declarations-requirements-operations-p01"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-p01">2.1.1.2.1.1 P01 - Every body requiring a Store operation declares</a><br>
                            <details>
                              <summary><a id="ds-tx-presence-activity-creation" name="ds-tx-presence-activity-creation"></a><a id="ds-tx-presence-operations-allocation" name="ds-tx-presence-operations-allocation"></a><a id="ds-tx-required-declarations-operations-allocation" name="ds-tx-required-declarations-operations-allocation"></a><a id="ds-tx-declarations-requirements-operations-allocation" name="ds-tx-declarations-requirements-operations-allocation"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation">2.1.1.2.1.2 Allocation</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-presence-activity-creation-n01" name="ds-tx-presence-activity-creation-n01"></a><a id="ds-tx-presence-operations-allocation-n01" name="ds-tx-presence-operations-allocation-n01"></a><a id="ds-tx-required-declarations-operations-allocation-n01" name="ds-tx-required-declarations-operations-allocation-n01"></a><a id="ds-tx-declarations-requirements-operations-allocation-n01" name="ds-tx-declarations-requirements-operations-allocation-n01"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-n01">2.1.1.2.1.2.1 N01 - Every explicit declaration satisfies allocation presence</a><br>
                                  <a id="ds-tx-presence-activity-creation-n02" name="ds-tx-presence-activity-creation-n02"></a><a id="ds-tx-presence-operations-allocation-n02" name="ds-tx-presence-operations-allocation-n02"></a><a id="ds-tx-required-declarations-operations-allocation-n02" name="ds-tx-required-declarations-operations-allocation-n02"></a><a id="ds-tx-declarations-requirements-operations-allocation-n02" name="ds-tx-declarations-requirements-operations-allocation-n02"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-n02">2.1.1.2.1.2.2 N02 - Absence satisfies allocation presence for empty or implicit-only own outputs</a><br>
                                  <a id="ds-tx-presence-activity-creation-f01" name="ds-tx-presence-activity-creation-f01"></a><a id="ds-tx-presence-operations-allocation-f01" name="ds-tx-presence-operations-allocation-f01"></a><a id="ds-tx-required-declarations-operations-allocation-f01" name="ds-tx-required-declarations-operations-allocation-f01"></a><a id="ds-tx-declarations-requirements-operations-allocation-f01" name="ds-tx-declarations-requirements-operations-allocation-f01"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-f01">2.1.1.2.1.2.3 F01 - Missing declaration fails allocation presence at every own-output position</a><br>
                                  <a id="ds-tx-presence-activity-creation-n03" name="ds-tx-presence-activity-creation-n03"></a><a id="ds-tx-presence-operations-allocation-n03" name="ds-tx-presence-operations-allocation-n03"></a><a id="ds-tx-required-declarations-operations-allocation-n03" name="ds-tx-required-declarations-operations-allocation-n03"></a><a id="ds-tx-declarations-requirements-operations-allocation-n03" name="ds-tx-declarations-requirements-operations-allocation-n03"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-n03">2.1.1.2.1.2.4 N03 - accepts a TopTx creating only min-ADA outputs without a declaration</a><br>
                                  <a id="ds-tx-presence-activity-creation-n04" name="ds-tx-presence-activity-creation-n04"></a><a id="ds-tx-presence-operations-allocation-n04" name="ds-tx-presence-operations-allocation-n04"></a><a id="ds-tx-required-declarations-operations-allocation-n04" name="ds-tx-required-declarations-operations-allocation-n04"></a><a id="ds-tx-declarations-requirements-operations-allocation-n04" name="ds-tx-declarations-requirements-operations-allocation-n04"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-n04">2.1.1.2.1.2.5 N04 - accepts a SubTx creating only min-ADA outputs without either body's declaration</a><br>
                                  <a id="ds-tx-presence-activity-creation-n05" name="ds-tx-presence-activity-creation-n05"></a><a id="ds-tx-presence-operations-allocation-n05" name="ds-tx-presence-operations-allocation-n05"></a><a id="ds-tx-required-declarations-operations-allocation-n05" name="ds-tx-required-declarations-operations-allocation-n05"></a><a id="ds-tx-declarations-requirements-operations-allocation-n05" name="ds-tx-declarations-requirements-operations-allocation-n05"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-n05">2.1.1.2.1.2.6 N05 - Standalone TopTx, exact allocation declaration</a><br>
                                  <a id="ds-tx-presence-activity-creation-f02" name="ds-tx-presence-activity-creation-f02"></a><a id="ds-tx-presence-operations-allocation-f02" name="ds-tx-presence-operations-allocation-f02"></a><a id="ds-tx-required-declarations-operations-allocation-f02" name="ds-tx-required-declarations-operations-allocation-f02"></a><a id="ds-tx-declarations-requirements-operations-allocation-f02" name="ds-tx-declarations-requirements-operations-allocation-f02"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-f02">2.1.1.2.1.2.7 F02 - Standalone TopTx, allocation without a declaration</a><br>
                                  <a id="ds-tx-presence-activity-creation-f03" name="ds-tx-presence-activity-creation-f03"></a><a id="ds-tx-presence-operations-allocation-f03" name="ds-tx-presence-operations-allocation-f03"></a><a id="ds-tx-required-declarations-operations-allocation-f03" name="ds-tx-required-declarations-operations-allocation-f03"></a><a id="ds-tx-declarations-requirements-operations-allocation-f03" name="ds-tx-declarations-requirements-operations-allocation-f03"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-f03">2.1.1.2.1.2.8 F03 - rejects a SubTx creating a deposit-backed output without its own declaration</a><br>
                                  <a id="ds-tx-presence-activity-creation-f04" name="ds-tx-presence-activity-creation-f04"></a><a id="ds-tx-presence-operations-allocation-f04" name="ds-tx-presence-operations-allocation-f04"></a><a id="ds-tx-required-declarations-operations-allocation-f04" name="ds-tx-required-declarations-operations-allocation-f04"></a><a id="ds-tx-declarations-requirements-operations-allocation-f04" name="ds-tx-declarations-requirements-operations-allocation-f04"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-f04">2.1.1.2.1.2.9 F04 - rejects a TopTx creating a deposit-backed output without its own declaration even when phase 2 fails</a><br>
                                  <a id="ds-tx-presence-activity-creation-f05" name="ds-tx-presence-activity-creation-f05"></a><a id="ds-tx-presence-operations-allocation-f05" name="ds-tx-presence-operations-allocation-f05"></a><a id="ds-tx-required-declarations-operations-allocation-f05" name="ds-tx-required-declarations-operations-allocation-f05"></a><a id="ds-tx-declarations-requirements-operations-allocation-f05" name="ds-tx-declarations-requirements-operations-allocation-f05"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-f05">2.1.1.2.1.2.10 F05 - rejects a SubTx creating a deposit-backed output without its own declaration even when phase 2 fails</a><br>
                                  <a id="ds-tx-presence-activity-creation-f06" name="ds-tx-presence-activity-creation-f06"></a><a id="ds-tx-presence-operations-allocation-f06" name="ds-tx-presence-operations-allocation-f06"></a><a id="ds-tx-required-declarations-operations-allocation-f06" name="ds-tx-required-declarations-operations-allocation-f06"></a><a id="ds-tx-declarations-requirements-operations-allocation-f06" name="ds-tx-declarations-requirements-operations-allocation-f06"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-f06">2.1.1.2.1.2.11 F06 - rejects a missing own declaration when spending a translated min-ADA output to create deposit-backed outputs</a><br>
                                  <a id="ds-tx-presence-activity-scope-n01" name="ds-tx-presence-activity-scope-n01"></a><a id="ds-tx-presence-operations-scope-n01" name="ds-tx-presence-operations-scope-n01"></a><a id="ds-tx-presence-operations-allocation-n06" name="ds-tx-presence-operations-allocation-n06"></a><a id="ds-tx-required-declarations-operations-allocation-n06" name="ds-tx-required-declarations-operations-allocation-n06"></a><a id="ds-tx-declarations-requirements-operations-allocation-n06" name="ds-tx-declarations-requirements-operations-allocation-n06"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-n06">2.1.1.2.1.2.12 N06 - SubTx outputs do not trigger TopTx allocation presence</a><br>
                                  <a id="ds-tx-presence-activity-scope-n02" name="ds-tx-presence-activity-scope-n02"></a><a id="ds-tx-presence-operations-scope-n02" name="ds-tx-presence-operations-scope-n02"></a><a id="ds-tx-presence-operations-allocation-n07" name="ds-tx-presence-operations-allocation-n07"></a><a id="ds-tx-required-declarations-operations-allocation-n07" name="ds-tx-required-declarations-operations-allocation-n07"></a><a id="ds-tx-declarations-requirements-operations-allocation-n07" name="ds-tx-declarations-requirements-operations-allocation-n07"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-n07">2.1.1.2.1.2.13 N07 - Collateral return does not trigger allocation presence</a><br>
                                  <a id="ds-tx-presence-activity-scope-n03" name="ds-tx-presence-activity-scope-n03"></a><a id="ds-tx-presence-operations-scope-n03" name="ds-tx-presence-operations-scope-n03"></a><a id="ds-tx-presence-operations-allocation-n08" name="ds-tx-presence-operations-allocation-n08"></a><a id="ds-tx-required-declarations-operations-allocation-n08" name="ds-tx-required-declarations-operations-allocation-n08"></a><a id="ds-tx-declarations-requirements-operations-allocation-n08" name="ds-tx-declarations-requirements-operations-allocation-n08"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-n08">2.1.1.2.1.2.14 N08 - Reference and collateral input identifiers do not trigger allocation presence</a><br>
                                  <a id="ds-tx-presence-activity-scope-f01" name="ds-tx-presence-activity-scope-f01"></a><a id="ds-tx-presence-operations-scope-f01" name="ds-tx-presence-operations-scope-f01"></a><a id="ds-tx-presence-operations-allocation-f07" name="ds-tx-presence-operations-allocation-f07"></a><a id="ds-tx-required-declarations-operations-allocation-f07" name="ds-tx-required-declarations-operations-allocation-f07"></a><a id="ds-tx-declarations-requirements-operations-allocation-f07" name="ds-tx-declarations-requirements-operations-allocation-f07"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-f07">2.1.1.2.1.2.15 F07 - A SubTx declaration cannot satisfy TopTx allocation presence</a><br>
                                  <a id="ds-tx-presence-activity-scope-f02" name="ds-tx-presence-activity-scope-f02"></a><a id="ds-tx-presence-operations-scope-f02" name="ds-tx-presence-operations-scope-f02"></a><a id="ds-tx-presence-operations-allocation-f08" name="ds-tx-presence-operations-allocation-f08"></a><a id="ds-tx-required-declarations-operations-allocation-f08" name="ds-tx-required-declarations-operations-allocation-f08"></a><a id="ds-tx-declarations-requirements-operations-allocation-f08" name="ds-tx-declarations-requirements-operations-allocation-f08"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-f08">2.1.1.2.1.2.16 F08 - TopTx zero cannot satisfy its allocating SubTx's declaration requirement</a><br>
                                  <a id="ds-tx-presence-activity-scope-n06" name="ds-tx-presence-activity-scope-n06"></a><a id="ds-tx-presence-operations-scope-n06" name="ds-tx-presence-operations-scope-n06"></a><a id="ds-tx-presence-operations-allocation-n09" name="ds-tx-presence-operations-allocation-n09"></a><a id="ds-tx-required-declarations-operations-allocation-n09" name="ds-tx-required-declarations-operations-allocation-n09"></a><a id="ds-tx-declarations-requirements-operations-allocation-n09" name="ds-tx-declarations-requirements-operations-allocation-n09"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-allocation-n09">2.1.1.2.1.2.17 N09 - TopTx and SubTx allocate deposits, each with an exact declaration</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-presence-activity-spending" name="ds-tx-presence-activity-spending"></a><a id="ds-tx-presence-operations-release" name="ds-tx-presence-operations-release"></a><a id="ds-tx-required-declarations-operations-release" name="ds-tx-required-declarations-operations-release"></a><a id="ds-tx-declarations-requirements-operations-release" name="ds-tx-declarations-requirements-operations-release"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release">2.1.1.2.1.3 Release</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-presence-activity-spending-n01" name="ds-tx-presence-activity-spending-n01"></a><a id="ds-tx-presence-operations-release-n01" name="ds-tx-presence-operations-release-n01"></a><a id="ds-tx-required-declarations-operations-release-n01" name="ds-tx-required-declarations-operations-release-n01"></a><a id="ds-tx-declarations-requirements-operations-release-n01" name="ds-tx-declarations-requirements-operations-release-n01"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n01">2.1.1.2.1.3.1 N01 - Standalone TopTx, any output form</a><br>
                                  <a id="ds-tx-presence-activity-spending-n02" name="ds-tx-presence-activity-spending-n02"></a><a id="ds-tx-presence-operations-release-n02" name="ds-tx-presence-operations-release-n02"></a><a id="ds-tx-required-declarations-operations-release-n02" name="ds-tx-required-declarations-operations-release-n02"></a><a id="ds-tx-declarations-requirements-operations-release-n02" name="ds-tx-declarations-requirements-operations-release-n02"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n02">2.1.1.2.1.3.2 N02 - Standalone TopTx, only min-ADA outputs</a><br>
                                  <a id="ds-tx-presence-activity-spending-n03" name="ds-tx-presence-activity-spending-n03"></a><a id="ds-tx-presence-operations-release-n03" name="ds-tx-presence-operations-release-n03"></a><a id="ds-tx-required-declarations-operations-release-n03" name="ds-tx-required-declarations-operations-release-n03"></a><a id="ds-tx-declarations-requirements-operations-release-n03" name="ds-tx-declarations-requirements-operations-release-n03"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n03">2.1.1.2.1.3.3 N03 - One SubTx releases its deposit into its own output</a><br>
                                  <a id="ds-tx-presence-activity-spending-f01" name="ds-tx-presence-activity-spending-f01"></a><a id="ds-tx-presence-operations-release-f01" name="ds-tx-presence-operations-release-f01"></a><a id="ds-tx-required-declarations-operations-release-f01" name="ds-tx-required-declarations-operations-release-f01"></a><a id="ds-tx-declarations-requirements-operations-release-f01" name="ds-tx-declarations-requirements-operations-release-f01"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-f01">2.1.1.2.1.3.4 F01 - Standalone TopTx, release without its own declaration</a><br>
                                  <a id="ds-tx-presence-activity-spending-f02" name="ds-tx-presence-activity-spending-f02"></a><a id="ds-tx-presence-operations-release-f02" name="ds-tx-presence-operations-release-f02"></a><a id="ds-tx-required-declarations-operations-release-f02" name="ds-tx-required-declarations-operations-release-f02"></a><a id="ds-tx-declarations-requirements-operations-release-f02" name="ds-tx-declarations-requirements-operations-release-f02"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-f02">2.1.1.2.1.3.5 F02 - SubTx release without its own declaration, despite TopTx declaring</a><br>
                                  <a id="ds-tx-presence-activity-spending-n04" name="ds-tx-presence-activity-spending-n04"></a><a id="ds-tx-presence-operations-release-n04" name="ds-tx-presence-operations-release-n04"></a><a id="ds-tx-required-declarations-operations-release-n04" name="ds-tx-required-declarations-operations-release-n04"></a><a id="ds-tx-declarations-requirements-operations-release-n04" name="ds-tx-declarations-requirements-operations-release-n04"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n04">2.1.1.2.1.3.6 N04 - Phase 2 fails with valid declarations</a><br>
                                  <a id="ds-tx-presence-activity-spending-f03" name="ds-tx-presence-activity-spending-f03"></a><a id="ds-tx-presence-operations-release-f03" name="ds-tx-presence-operations-release-f03"></a><a id="ds-tx-required-declarations-operations-release-f03" name="ds-tx-required-declarations-operations-release-f03"></a><a id="ds-tx-declarations-requirements-operations-release-f03" name="ds-tx-declarations-requirements-operations-release-f03"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-f03">2.1.1.2.1.3.7 F03 - Missing release declaration in a phase-2-invalid proposal</a><br>
                                  <a id="ds-tx-presence-activity-spending-n05" name="ds-tx-presence-activity-spending-n05"></a><a id="ds-tx-presence-operations-release-n05" name="ds-tx-presence-operations-release-n05"></a><a id="ds-tx-required-declarations-operations-release-n05" name="ds-tx-required-declarations-operations-release-n05"></a><a id="ds-tx-declarations-requirements-operations-release-n05" name="ds-tx-declarations-requirements-operations-release-n05"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n05">2.1.1.2.1.3.8 N05 - Several SubTxs release their deposits</a><br>
                                  <a id="ds-tx-presence-activity-spending-f04" name="ds-tx-presence-activity-spending-f04"></a><a id="ds-tx-presence-operations-release-f04" name="ds-tx-presence-operations-release-f04"></a><a id="ds-tx-required-declarations-operations-release-f04" name="ds-tx-required-declarations-operations-release-f04"></a><a id="ds-tx-declarations-requirements-operations-release-f04" name="ds-tx-declarations-requirements-operations-release-f04"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-f04">2.1.1.2.1.3.9 F04 - One SubTx releasing deposits omits its declaration</a><br>
                                  <a id="ds-tx-presence-activity-spending-n06" name="ds-tx-presence-activity-spending-n06"></a><a id="ds-tx-presence-operations-release-n06" name="ds-tx-presence-operations-release-n06"></a><a id="ds-tx-required-declarations-operations-release-n06" name="ds-tx-required-declarations-operations-release-n06"></a><a id="ds-tx-declarations-requirements-operations-release-n06" name="ds-tx-declarations-requirements-operations-release-n06"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n06">2.1.1.2.1.3.10 N06 - Only some SubTxs release Store deposits</a><br>
                                  <a id="ds-tx-presence-activity-spending-n07" name="ds-tx-presence-activity-spending-n07"></a><a id="ds-tx-presence-operations-release-n07" name="ds-tx-presence-operations-release-n07"></a><a id="ds-tx-required-declarations-operations-release-n07" name="ds-tx-required-declarations-operations-release-n07"></a><a id="ds-tx-declarations-requirements-operations-release-n07" name="ds-tx-declarations-requirements-operations-release-n07"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n07">2.1.1.2.1.3.11 N07 - TopTx and several SubTxs release deposits</a><br>
                                  <a id="ds-tx-presence-activity-spending-n08" name="ds-tx-presence-activity-spending-n08"></a><a id="ds-tx-presence-operations-release-n08" name="ds-tx-presence-operations-release-n08"></a><a id="ds-tx-required-declarations-operations-release-n08" name="ds-tx-required-declarations-operations-release-n08"></a><a id="ds-tx-declarations-requirements-operations-release-n08" name="ds-tx-declarations-requirements-operations-release-n08"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n08">2.1.1.2.1.3.12 N08 - Phase 2 fails with several proposed SubTx releases</a><br>
                                  <a id="ds-tx-presence-activity-spending-f05" name="ds-tx-presence-activity-spending-f05"></a><a id="ds-tx-presence-operations-release-f05" name="ds-tx-presence-operations-release-f05"></a><a id="ds-tx-required-declarations-operations-release-f05" name="ds-tx-required-declarations-operations-release-f05"></a><a id="ds-tx-declarations-requirements-operations-release-f05" name="ds-tx-declarations-requirements-operations-release-f05"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-f05">2.1.1.2.1.3.13 F05 - One SubTx declaration is missing in a phase-2-invalid proposal</a><br>
                                  <a id="ds-tx-presence-activity-scope-n04" name="ds-tx-presence-activity-scope-n04"></a><a id="ds-tx-presence-operations-scope-n04" name="ds-tx-presence-operations-scope-n04"></a><a id="ds-tx-presence-operations-release-n09" name="ds-tx-presence-operations-release-n09"></a><a id="ds-tx-required-declarations-operations-release-n09" name="ds-tx-required-declarations-operations-release-n09"></a><a id="ds-tx-declarations-requirements-operations-release-n09" name="ds-tx-declarations-requirements-operations-release-n09"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n09">2.1.1.2.1.3.14 N09 - Standalone TopTx, reference-only Store access</a><br>
                                  <a id="ds-tx-presence-activity-scope-n05" name="ds-tx-presence-activity-scope-n05"></a><a id="ds-tx-presence-operations-scope-n05" name="ds-tx-presence-operations-scope-n05"></a><a id="ds-tx-presence-operations-release-n10" name="ds-tx-presence-operations-release-n10"></a><a id="ds-tx-required-declarations-operations-release-n10" name="ds-tx-required-declarations-operations-release-n10"></a><a id="ds-tx-declarations-requirements-operations-release-n10" name="ds-tx-declarations-requirements-operations-release-n10"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-n10">2.1.1.2.1.3.15 N10 - Standalone TopTx, collateral-only Store operations</a><br>
                                  <a id="ds-tx-presence-activity-scope-f03" name="ds-tx-presence-activity-scope-f03"></a><a id="ds-tx-presence-operations-scope-f03" name="ds-tx-presence-operations-scope-f03"></a><a id="ds-tx-presence-operations-release-f06" name="ds-tx-presence-operations-release-f06"></a><a id="ds-tx-required-declarations-operations-release-f06" name="ds-tx-required-declarations-operations-release-f06"></a><a id="ds-tx-declarations-requirements-operations-release-f06" name="ds-tx-declarations-requirements-operations-release-f06"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-release-f06">2.1.1.2.1.3.16 F06 - A SubTx declaration cannot satisfy TopTx release presence</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-presence-operations-zero-net-change" name="ds-tx-presence-operations-zero-net-change"></a><a id="ds-tx-required-declarations-operations-zero-net-change" name="ds-tx-required-declarations-operations-zero-net-change"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change" name="ds-tx-declarations-requirements-operations-zero-net-change"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change">2.1.1.2.1.4 Zero net change</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-presence-operations-zero-net-change-n01" name="ds-tx-presence-operations-zero-net-change-n01"></a><a id="ds-tx-required-declarations-operations-zero-net-change-n01" name="ds-tx-required-declarations-operations-zero-net-change-n01"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-n01" name="ds-tx-declarations-requirements-operations-zero-net-change-n01"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-n01">2.1.1.2.1.4.1 N01 - Standalone TopTx, equal allocations and releases with explicit zero</a><br>
                                  <a id="ds-tx-presence-operations-zero-net-change-f01" name="ds-tx-presence-operations-zero-net-change-f01"></a><a id="ds-tx-required-declarations-operations-zero-net-change-f01" name="ds-tx-required-declarations-operations-zero-net-change-f01"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-f01" name="ds-tx-declarations-requirements-operations-zero-net-change-f01"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-f01">2.1.1.2.1.4.2 F01 - Standalone TopTx, equal allocations and releases without a declaration</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-n02" name="ds-tx-required-declarations-operations-zero-net-change-n02"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-n02" name="ds-tx-declarations-requirements-operations-zero-net-change-n02"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-n02">2.1.1.2.1.4.3 N02 - One SubTx replaces its deposit with explicit zero</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-f02" name="ds-tx-required-declarations-operations-zero-net-change-f02"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-f02" name="ds-tx-declarations-requirements-operations-zero-net-change-f02"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-f02">2.1.1.2.1.4.4 F02 - One active SubTx omits its declaration</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-f03" name="ds-tx-required-declarations-operations-zero-net-change-f03"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-f03" name="ds-tx-declarations-requirements-operations-zero-net-change-f03"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-f03">2.1.1.2.1.4.5 F03 - TopTx omits the declaration required by its child</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-n03" name="ds-tx-required-declarations-operations-zero-net-change-n03"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-n03" name="ds-tx-declarations-requirements-operations-zero-net-change-n03"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-n03">2.1.1.2.1.4.6 N03 - Several SubTxs each replace their deposits</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-f04" name="ds-tx-required-declarations-operations-zero-net-change-f04"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-f04" name="ds-tx-declarations-requirements-operations-zero-net-change-f04"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-f04">2.1.1.2.1.4.7 F04 - One of several active SubTxs omits its declaration</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-n04" name="ds-tx-required-declarations-operations-zero-net-change-n04"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-n04" name="ds-tx-declarations-requirements-operations-zero-net-change-n04"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-n04">2.1.1.2.1.4.8 N04 - Only some SubTxs replace Store deposits</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-f05" name="ds-tx-required-declarations-operations-zero-net-change-f05"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-f05" name="ds-tx-declarations-requirements-operations-zero-net-change-f05"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-f05">2.1.1.2.1.4.9 F05 - One active SubTx omits its declaration among inactive siblings</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-n05" name="ds-tx-required-declarations-operations-zero-net-change-n05"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-n05" name="ds-tx-declarations-requirements-operations-zero-net-change-n05"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-n05">2.1.1.2.1.4.10 N05 - TopTx and several SubTxs each replace their deposits</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-f06" name="ds-tx-required-declarations-operations-zero-net-change-f06"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-f06" name="ds-tx-declarations-requirements-operations-zero-net-change-f06"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-f06">2.1.1.2.1.4.11 F06 - Active TopTx omits its own declaration</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-n06" name="ds-tx-required-declarations-operations-zero-net-change-n06"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-n06" name="ds-tx-declarations-requirements-operations-zero-net-change-n06"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-n06">2.1.1.2.1.4.12 N06 - Phase 2 fails with explicit zero at every active body</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-f07" name="ds-tx-required-declarations-operations-zero-net-change-f07"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-f07" name="ds-tx-declarations-requirements-operations-zero-net-change-f07"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-f07">2.1.1.2.1.4.13 F07 - One SubTx declaration is missing in a phase-2-invalid proposal</a><br>
                                  <a id="ds-tx-required-declarations-operations-zero-net-change-f08" name="ds-tx-required-declarations-operations-zero-net-change-f08"></a><a id="ds-tx-declarations-requirements-operations-zero-net-change-f08" name="ds-tx-declarations-requirements-operations-zero-net-change-f08"></a><a href="declarations.md#ds-tx-declarations-requirements-operations-zero-net-change-f08">2.1.1.2.1.4.14 F08 - TopTx's own declaration is missing in a phase-2-invalid proposal</a><br>
                                </dd>
                              </dl>
                            </details>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a id="ds-tx-presence-dependency" name="ds-tx-presence-dependency"></a><a id="ds-tx-presence-subtx-declarations" name="ds-tx-presence-subtx-declarations"></a><a id="ds-tx-required-declarations-subtx-declarations" name="ds-tx-required-declarations-subtx-declarations"></a><a id="ds-tx-declarations-requirements-subtx-declarations" name="ds-tx-declarations-requirements-subtx-declarations"></a><a id="21122-subtx-declarations" name="21122-subtx-declarations"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations">2.1.1.2.2 SubTx declarations</a></summary>
                        <dl>
                          <dd>
                            <details>
                              <summary><a id="ds-tx-presence-dependency-c01" name="ds-tx-presence-dependency-c01"></a><a id="ds-tx-presence-subtx-declarations-c01" name="ds-tx-presence-subtx-declarations-c01"></a><a id="ds-tx-required-declarations-subtx-declarations-c01" name="ds-tx-required-declarations-subtx-declarations-c01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c01" name="ds-tx-declarations-requirements-subtx-declarations-c01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c01">2.1.1.2.2.1 TopTx requirement</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-presence-dependency-c01-p01" name="ds-tx-presence-dependency-c01-p01"></a><a id="ds-tx-presence-subtx-declarations-c01-p01" name="ds-tx-presence-subtx-declarations-c01-p01"></a><a id="ds-tx-required-declarations-subtx-declarations-c01-p01" name="ds-tx-required-declarations-subtx-declarations-c01-p01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c01-p01" name="ds-tx-declarations-requirements-subtx-declarations-c01-p01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c01-p01">2.1.1.2.2.1.1 P01 - SubTx declarations require TopTx's declaration</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-presence-dependency-c02" name="ds-tx-presence-dependency-c02"></a><a id="ds-tx-presence-subtx-declarations-c02" name="ds-tx-presence-subtx-declarations-c02"></a><a id="ds-tx-required-declarations-subtx-declarations-c02" name="ds-tx-required-declarations-subtx-declarations-c02"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c02" name="ds-tx-declarations-requirements-subtx-declarations-c02"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c02">2.1.1.2.2.2 Absence and explicit zero</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-presence-dependency-c02-n01" name="ds-tx-presence-dependency-c02-n01"></a><a id="ds-tx-presence-subtx-declarations-c02-n01" name="ds-tx-presence-subtx-declarations-c02-n01"></a><a id="ds-tx-required-declarations-subtx-declarations-c02-n01" name="ds-tx-required-declarations-subtx-declarations-c02-n01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c02-n01" name="ds-tx-declarations-requirements-subtx-declarations-c02-n01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c02-n01">2.1.1.2.2.2.1 N01 - accepts absent declarations at both levels</a><br>
                                  <a id="ds-tx-presence-dependency-c02-n02" name="ds-tx-presence-dependency-c02-n02"></a><a id="ds-tx-presence-subtx-declarations-c02-n02" name="ds-tx-presence-subtx-declarations-c02-n02"></a><a id="ds-tx-required-declarations-subtx-declarations-c02-n02" name="ds-tx-required-declarations-subtx-declarations-c02-n02"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c02-n02" name="ds-tx-declarations-requirements-subtx-declarations-c02-n02"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c02-n02">2.1.1.2.2.2.2 N02 - accepts explicit zero at both levels</a><br>
                                  <a id="ds-tx-presence-dependency-c02-n03" name="ds-tx-presence-dependency-c02-n03"></a><a id="ds-tx-presence-subtx-declarations-c02-n03" name="ds-tx-presence-subtx-declarations-c02-n03"></a><a id="ds-tx-required-declarations-subtx-declarations-c02-n03" name="ds-tx-required-declarations-subtx-declarations-c02-n03"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c02-n03" name="ds-tx-declarations-requirements-subtx-declarations-c02-n03"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c02-n03">2.1.1.2.2.2.3 N03 - accepts TopTx zero without a SubTx declaration</a><br>
                                  <a id="ds-tx-presence-dependency-c02-f01" name="ds-tx-presence-dependency-c02-f01"></a><a id="ds-tx-presence-subtx-declarations-c02-f01" name="ds-tx-presence-subtx-declarations-c02-f01"></a><a id="ds-tx-required-declarations-subtx-declarations-c02-f01" name="ds-tx-required-declarations-subtx-declarations-c02-f01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c02-f01" name="ds-tx-declarations-requirements-subtx-declarations-c02-f01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c02-f01">2.1.1.2.2.2.4 F01 - rejects SubTx zero without a TopTx declaration</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-presence-dependency-c03" name="ds-tx-presence-dependency-c03"></a><a id="ds-tx-presence-subtx-declarations-c03" name="ds-tx-presence-subtx-declarations-c03"></a><a id="ds-tx-required-declarations-subtx-declarations-c03" name="ds-tx-required-declarations-subtx-declarations-c03"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c03" name="ds-tx-declarations-requirements-subtx-declarations-c03"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c03">2.1.1.2.2.3 Offsetting SubTx contributions</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-presence-dependency-c03-n01" name="ds-tx-presence-dependency-c03-n01"></a><a id="ds-tx-presence-subtx-declarations-c03-n01" name="ds-tx-presence-subtx-declarations-c03-n01"></a><a id="ds-tx-required-declarations-subtx-declarations-c03-n01" name="ds-tx-required-declarations-subtx-declarations-c03-n01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c03-n01" name="ds-tx-declarations-requirements-subtx-declarations-c03-n01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c03-n01">2.1.1.2.2.3.1 N01 - passes declaration presence with TopTx declaring the zero net amount</a><br>
                                  <a id="ds-tx-presence-dependency-c03-f01" name="ds-tx-presence-dependency-c03-f01"></a><a id="ds-tx-presence-subtx-declarations-c03-f01" name="ds-tx-presence-subtx-declarations-c03-f01"></a><a id="ds-tx-required-declarations-subtx-declarations-c03-f01" name="ds-tx-required-declarations-subtx-declarations-c03-f01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c03-f01" name="ds-tx-declarations-requirements-subtx-declarations-c03-f01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c03-f01">2.1.1.2.2.3.2 F01 - rejects an absent TopTx declaration despite the zero net amount</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-presence-dependency-c04" name="ds-tx-presence-dependency-c04"></a><a id="ds-tx-presence-subtx-declarations-c04" name="ds-tx-presence-subtx-declarations-c04"></a><a id="ds-tx-required-declarations-subtx-declarations-c04" name="ds-tx-required-declarations-subtx-declarations-c04"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c04" name="ds-tx-declarations-requirements-subtx-declarations-c04"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c04">2.1.1.2.2.4 Local and delegated accounting</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-presence-dependency-c04-n01" name="ds-tx-presence-dependency-c04-n01"></a><a id="ds-tx-presence-subtx-declarations-c04-n01" name="ds-tx-presence-subtx-declarations-c04-n01"></a><a id="ds-tx-required-declarations-subtx-declarations-c04-n01" name="ds-tx-required-declarations-subtx-declarations-c04-n01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c04-n01" name="ds-tx-declarations-requirements-subtx-declarations-c04-n01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c04-n01">2.1.1.2.2.4.1 N01 - passes declaration presence with TopTx zero for every explicit SubTx form</a><br>
                                  <a id="ds-tx-presence-dependency-c04-f01" name="ds-tx-presence-dependency-c04-f01"></a><a id="ds-tx-presence-subtx-declarations-c04-f01" name="ds-tx-presence-subtx-declarations-c04-f01"></a><a id="ds-tx-required-declarations-subtx-declarations-c04-f01" name="ds-tx-required-declarations-subtx-declarations-c04-f01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c04-f01" name="ds-tx-declarations-requirements-subtx-declarations-c04-f01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c04-f01">2.1.1.2.2.4.2 F01 - rejects an absent TopTx declaration for every explicit SubTx form</a><br>
                                </dd>
                              </dl>
                            </details>
                            <details>
                              <summary><a id="ds-tx-presence-dependency-c05" name="ds-tx-presence-dependency-c05"></a><a id="ds-tx-presence-subtx-declarations-c05" name="ds-tx-presence-subtx-declarations-c05"></a><a id="ds-tx-required-declarations-subtx-declarations-c05" name="ds-tx-required-declarations-subtx-declarations-c05"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c05" name="ds-tx-declarations-requirements-subtx-declarations-c05"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c05">2.1.1.2.2.5 Phase-2 failure</a></summary>
                              <dl>
                                <dd>
                                  <a id="ds-tx-presence-dependency-c05-n01" name="ds-tx-presence-dependency-c05-n01"></a><a id="ds-tx-presence-subtx-declarations-c05-n01" name="ds-tx-presence-subtx-declarations-c05-n01"></a><a id="ds-tx-required-declarations-subtx-declarations-c05-n01" name="ds-tx-required-declarations-subtx-declarations-c05-n01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c05-n01" name="ds-tx-declarations-requirements-subtx-declarations-c05-n01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c05-n01">2.1.1.2.2.5.1 N01 - accepts zero declarations at both levels on the phase-2 failure path</a><br>
                                  <a id="ds-tx-presence-dependency-c05-f01" name="ds-tx-presence-dependency-c05-f01"></a><a id="ds-tx-presence-subtx-declarations-c05-f01" name="ds-tx-presence-subtx-declarations-c05-f01"></a><a id="ds-tx-required-declarations-subtx-declarations-c05-f01" name="ds-tx-required-declarations-subtx-declarations-c05-f01"></a><a id="ds-tx-declarations-requirements-subtx-declarations-c05-f01" name="ds-tx-declarations-requirements-subtx-declarations-c05-f01"></a><a href="declarations.md#ds-tx-declarations-requirements-subtx-declarations-c05-f01">2.1.1.2.2.5.2 F01 - rejects SubTx zero without a TopTx declaration on the phase-2 failure path</a><br>
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
                            <a href="#ds-tx-accounting-net-change-subtx-n05">2.1.2.1.1.12 N05 - Released deposits, only min-ADA outputs</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f07">2.1.2.1.1.13 F07 - Explicit zero cannot replace a required release</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n06">2.1.2.1.1.14 N06 - Another body offsets the SubTx release</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n07">2.1.2.1.1.15 N07 - An output without application assets still requires a deposit</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-n08">2.1.2.1.1.16 N08 - A translated min-ADA input funds an exact allocation</a><br>
                            <a href="#ds-tx-accounting-net-change-subtx-f08">2.1.2.1.1.17 F08 - A translated min-ADA input does not excuse an inexact allocation</a><br>
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
                      <a href="#ds-tx-settlement-output-coin-f01">2.1.4.3.2 F01 - Min-ADA output, one lovelace short</a><br>
                      <a href="#ds-tx-settlement-output-coin-n01">2.1.4.3.3 N01 - Min-ADA output, exact amount</a><br>
                      <a href="#ds-tx-settlement-output-coin-n02">2.1.4.3.4 N02 - Min-ADA output, extra ADA</a><br>
                      <a href="#ds-tx-settlement-output-coin-f02">2.1.4.3.5 F02 - An external deposit cannot fill the ADA shortfall</a><br>
                      <a href="#ds-tx-settlement-output-coin-n03">2.1.4.3.6 N03 - Deposit-backed output, exact application ADA</a><br>
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
                <a href="#ds-tx-minimum-coin-n04">2.1.5.4 N04 - Exact minimum for a min-ADA output</a><br>
                <a href="#ds-tx-minimum-coin-f01">2.1.5.5 F01 - Min-ADA output one lovelace short</a><br>
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
                <a href="#ds-collateral-funding-p03">2.2.1.4 P03 - Min-ADA return at the active minimum</a><br>
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
                <a href="#ds-state-allocations-p03">3.2.1.3 P03 - Restore the historical deposit</a><br>
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
                <a href="#ds-state-balance-p08">3.2.2.8 P08 - Refund across formula versions</a><br>
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
          <a href="#ds-stake-n01">4.1.1 N01 - counts the full ADA in min-ADA outputs under the existing staking rules</a><br>
          <a href="#ds-stake-n02">4.1.2 N02 - counts only application ADA in deposit-backed outputs under the existing staking rules</a><br>
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
| Min-ADA (`MinAdaTxOut`) | Full output value | The existing minimum ADA remains inside that value. |
| Deposit-backed (`DepositBackedTxOut`) | Application assets: ADA and native assets | Recorded alongside the live UTxO entry and held externally in the DepositStore. |

For a deposit-backed output, distinguish its **required deposit**, calculated when it is
created, from its **allocated deposit**, the exact recorded amount associated with the
live output. [Deposit calculation](#ds-pricing) defines the required amount;
[Allocations](#ds-state-allocations) defines how the ledger records and releases it.

Outputs are indexed occurrences. Equal output values at different indices represent
separate outputs and have separate allocated deposits when deposit-backed. The external
deposit metadata is outside the serialized output.

<a id="section-1-1" name="section-1-1"></a>

### 1.2 DepositStore

> **Retain the output and its allocation origin. The origin selects the formula for its refund.**

```haskell
data UTxOStore era = UTxOStore
  { depositFormulaHistory :: !DepositFormulaHistory
  , totalDepositAmount :: !DepositAmount
  , allocations :: !(IndexedUTxOs era)
  }

newtype DepositAmount = DepositAmount {toCoin :: Coin}

newtype IndexedUTxOs era = IndexedUTxOs
  { unIndexedUTxOs :: Map TxIn (Unspent (TxOut era))
  }

data Unspent output = Unspent
  { output :: !output
  , allocatedAt :: !AllocatedAt
  }

data AllocatedAt
  = AtStoreMigration
  | AtSlot !SlotNo

data DepositFormulaHistory = DepositFormulaHistory
  { initialFormula :: !DepositFormula
  , formulaChanges :: !(Map SlotNo DepositFormula)
  }
```

An accepted output enters the Store as `Unspent output (AtSlot slot)`.
The fork imports each translated min-ADA output as `Unspent output AtStoreMigration`.
The output provides the asset, datum and script measurements for [Deposit calculation](#ds-pricing).

**History always has a baseline.** `mkDepositFormulaHistory baseline` starts with no dated
changes. The default is V1 at **4310 lovelace per byte**, with no dated changes;
`Default UTxOStore` uses this history and empty allocations. `initialFormula`
prices imported entries permanently and all dated entries preceding the first change.
Each subsequent change retains its formula and parameters over $`[s_i,s_{i+1})`$; the final interval has no upper bound.

**Prototype migration uses one initial formula.** Imported outputs and new outputs
allocated before the first change use the same baseline. This history records
changes introduced after the fork; it does not reconstruct pre-fork pricing or
require a migration slot. Later activations affect newly allocated outputs while
existing entries retain their allocation-time formula.

| Allocation | Formula retained |
| --- | --- |
| Imported at migration | `initialFormula = DepositFormulaV1 rateA` |
| New, before the first change | `DepositFormulaV1 rateA` |
| New, after a parameter change | `DepositFormulaV1 rateB` |
| New, after a formula-version change | `DepositFormulaV2 rateC` |

V1 prices a base of 250 bytes plus 74 bytes per distinct native asset. The experimental
V2 changes these coefficients to 260 and 80. Both add the datum and reference script
payload lengths and multiply by their recorded rate.

Let $`f_b`$ be the baseline formula and $`(s_i,f_i)`$ the ordered changes:

```math
H(s)=
\begin{cases}
f_b & \text{if no change starts at or before }s \\
f_j & j=\max\{i\mid s_i\leq s\}
\end{cases}
```

| Allocation origin | Formula $`F_H(u)`$ |
| --- | --- |
| `AtStoreMigration` | The baseline $`f_b`$, including after later changes. |
| `AtSlot slot` | $`H(\text{slot})`$: the latest applicable change, otherwise the baseline. |

`formulaAt`, `latestFormula` and the Store's derived `currentFormula`
return a formula directly. `periods` includes the baseline interval with
`fromInclusive = Nothing`; the last interval has `untilExclusive = Nothing`.

**The output variant determines where the reserve is held.** Let $`C(u)`$ be the
output ADA and $`P(u)=F_H(u)(\text{output}(u))`$ its calculated deposit.

| View | `MinAdaTxOut` | `DepositBackedTxOut` |
| --- | --- | --- |
| `computeDeposit` | $`\min(C(u),P(u))`$ | $`P(u)`$ |
| Application ADA | $`C(u)-\min(C(u),P(u))`$ | $`C(u)`$ |
| `computeExternalDeposit` | $`0`$ | $`P(u)`$ |
| Stored output payload | Unchanged; reserve remains included | Unchanged; deposit is external |

Native assets are preserved in both application views. When a min-ADA output cannot
cover the calculated reserve, its application ADA is zero. This is a **view**, not
a transfer or payload rewrite. Spending that output still provides its complete
value; its reserve must never be credited a second time.

```math
\text{totalDepositAmount}(S)
= \sum_{u\in\text{allocations}(S)}
\text{computeExternalDeposit}(\text{depositFormulaHistory}(S),u)
```

The cached total contains only separately held deposits. Min-ADA reserves remain
inside output ADA; there is no unallocated Store surplus.

**Builder queries use explicit history and return values directly.** Every
allocation resolves either the baseline or a dated change. The reserve query returns
`DepositAmount`; use `toCoin` when combining it with output ADA:

```haskell
-- Dijkstra builder queries, shown specialized to the active era.
computeDeposit ::
  DepositFormulaHistory -> Unspent (TxOut DijkstraEra) -> DepositAmount

computeApplicationAssets ::
  DepositFormulaHistory -> Unspent (TxOut DijkstraEra) -> ApplicationAssets DijkstraEra

-- The shared Store sums only separately held deposits.
computeExternalDeposit ::
  EraDepositBackedTxOut era => DepositFormulaHistory -> Unspent (TxOut era) -> Coin

-- Resolve many inputs against the same history.
depositFor = computeDeposit (depositFormulaHistory store)
depositFor entry
```

`mkUTxOStore history entries` preserves output payloads and allocation origins and
derives the external total. `sumDepositAmounts history entries` and
`allocatedDepositTotalAmount history inputs entries` return `DepositAmount`;
use `toCoin` explicitly for Coin arithmetic.

| Operation | Contract |
| --- | --- |
| `allocate slot outputs` | Keep occupied references and record each new output with `allocatedAt = AtSlot slot`. |
| `release inputs` | Remove selected entries and debit their historical **external** deposits. |
| `appendFormula slot formula` | Add the first dated change or one strictly after the latest; reject replacement or insertion into existing periods. |
| `activateNewFormula slot formula` | Append without repricing existing entries; reject V2 → V1. Rates may increase or decrease within either version. Reapplying the latest formula is a no-op. |

Activation preserves existing entries and the cached total. Effective parameter
changes use the **actual epoch boundary slot**, even when the first transaction
arrives later. TopTx, its SubTxs and any collateral return record their ledger slot.

Formula activation only moves forward in version:

```math
\mathrm{version}(F_{\mathrm{next}}) \geq \mathrm{version}(F_{\mathrm{active}})
```

Existing V1 allocations still use V1 for their refunds after V2 becomes active.

```haskell
Store.projectTx slot tx previousStore
Store.Internals.projectValidTxBody slot body previousStore
Store.Internals.projectInvalidTxBody slot body previousStore
```

Each projection returns `TxProjected {updatedStore, consumedOutputs, producedOutputs}`.
Regular and collateral paths report actual Store changes; retained colliding
references are not produced again. Stake updates use those same entries. The ledger
selects SubTx execution and controls event emission.

**Migration initializes the baseline.** `mkDepositFormulaHistory formula` records V1
with the effective translated protocol parameters as `initialFormula`; dated
changes start empty. Imported entries retain the translated output and `AtStoreMigration`. Their baseline-priced reserve remains embedded
and capped by existing ADA. No creation slot is invented or recovered. Later changes
do not reprice these entries; the external total starts at zero.

Test-network initial funds also enter as `AtStoreMigration`. Injection preserves
the supplied Store's complete history and existing entries, including when dated
changes begin at a nonzero slot. A network started directly in Dijkstra begins
with V1 at its effective genesis rate and no dated changes.

**Persistence preserves the pricing inputs.** History encodes
`[initialFormula, formulaChanges]`; Dijkstra entries encode
`[output, allocatedAt]`; the Store encodes
`[depositFormulaHistory, cachedTotal, allocationMap]`. Decoding validates entry shape, activation order, formula versions and the cached total. Prior
per-entry formula and nullable/history-map schemas are not this format.

Before Dijkstra, existing payload-only formats remain unchanged. They preserve no
Store history or original creation dates. Ordinary legacy decoding uses the default
V1/4310 history. `Store.decodeUTxOStoreWithFormula baseline credentials` allows
a caller to override that baseline. Dijkstra snapshots remain self-contained and
retain their persisted history. The assigned legacy baseline is a model policy,
not recovery of each output's original minimum deposit.

Empty Stores retain their baseline and dated changes. Zero-priced new outputs still receive allocation records.

[Ledger effects](#ds-state) specifies the resulting allocations and exact cached total.

<a id="section-1-4" name="section-1-4"></a>

### 1.3 Transaction bodies

> **Identify each body's own operations and the complete transaction's total.**
>
> $`\text{Transaction}=\text{TopTx body}+\text{its SubTx bodies}`$.

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

```math
\begin{aligned}
\text{releasedUTxODeposits(body)}
&= \sum_{\text{input}\in\text{consumed deposit-backed inputs(body)}}
\text{recordedDeposit(input)} \\
\text{allocatedUTxODeposits(body)}
&= \sum_{\text{output}\in\text{new deposit-backed outputs(body)}}
\text{requiredDeposit(output)} \\
\text{storeChange(body)}
&= \text{allocatedUTxODeposits(body)} - \text{releasedUTxODeposits(body)} \\
\text{requiredNetUTxODepositChange(body)}
&= \text{storeChange(body)} + \text{newEmbeddedMinima(body)} - \text{creditedEmbeddedReserves(body)} \\
\text{requiredTxTotalNetUTxODepositChange}
&= \sum_{\text{body}\in\text{TopTx and all SubTx bodies}}
\text{requiredNetUTxODepositChange(body)}
\end{aligned}
```

Each new min-ADA output contributes its full minimum under the active formula.
Each consumed min-ADA input contributes its historical minimum capped at its
serialized ADA. Imported inputs use the fork's initial formula. Dated inputs use
the formula in effect at allocation. The external deposits use the same creation
and historical prices, respectively, with the full historical deposit released.

The declaration supplies a separate value, `declaredTxTotalNetUTxODepositChange`.
[TopTx accounting](#ds-tx-accounting-net-change-toptx) compares that supplied total with the required
total above. For each explicit SubTx declaration, [SubTx accounting](#ds-tx-accounting-net-change-subtx)
compares `declaredSubTxNetUTxODepositChange(subTx)` with its required own change.
Never obtain the expected amounts from the declarations being checked.

| Body operations | Required own change | Correct declaration |
| --- | ---: | --- |
| TopTx releases 3 ADA | $`-3`$ ADA | Explicit zero, because the complete transaction nets to zero. |
| Its SubTx allocates 3 ADA | $`+3`$ ADA | An allocation of 3 ADA, locally accounted or explicitly delegated. |

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

**At the Dijkstra fork and at direct Dijkstra genesis, V1 is the initial formula.**
Dijkstra evaluates both output forms, including migrated `MinAdaTxOut`s. Earlier-era
pricing rules stay unchanged; they do not implement this formula.
The rate $`p`$ is the effective `coinsPerUTxOByte`, in lovelace per byte. For an output $`o`$:

```math
\begin{aligned}
F_{1,p}(o) &= p\,(250 + 74N(o) + D(o) + R(o)) \\
F_{2,p}(o) &= p\,(260 + 80N(o) + D(o) + R(o))
\end{aligned}
```

| Component | Measurement |
| --- | --- |
| $`N(o)`$ | Number of distinct native assets. Each pair of policy ID and asset name counts once, regardless of quantity. ADA contributes zero. |
| $`D(o)`$ | No datum: zero. Datum hash: length of the hash in bytes. Inline datum: length of its original payload in bytes. |
| $`R(o)`$ | No reference script: zero. Otherwise, the original byte length of the underlying native or Plutus script. |

**The formula takes typed measures.** `NativeAssetCount`, `DatumBytes` and
`ReferenceScriptBytes` each wrap `Natural`. The core calculation depends on these
nonnegative quantities, without knowing an output representation:

```haskell
computeDeposit ::
  DepositFormula ->
  NativeAssetCount ->
  DatumBytes ->
  ReferenceScriptBytes ->
  DepositAmount
```

Dijkstra's `Deposit.Formula.computeDeposit` extracts those measures from a `TxOut`
and calls this core function. `Unspent.computeDeposit` additionally selects the
historical formula and caps a min-ADA reserve. Both return `DepositAmount`;
`getDepositTxOut` and `computeExternalDeposit` expose `Coin` through `toCoin`
at the shared Store boundary.

The lengths count payload bytes. Address length, application ADA and the outer CBOR
envelopes of the datum, script and output contribute no term. Transaction bodies
still retain their `Sized` outputs for serialization; neither Dijkstra deposit
pricing nor its [minimum-coin check](#ds-tx-minimum-coin) uses that total size.

The Store holds the full computed amount externally for each created `DepositBackedTxOut`.
For a `MinAdaTxOut`, its embedded reserve is capped at the output's ADA.
The [allocation origin](#section-1-1) selects the formula and rate on refund.

**Experiment.** Two otherwise identical Deposit-backed outputs contain two distinct
native assets, no datum and no reference script. At $`p=4310`$, their deposits depend
on which side of the V2 activation slot $`s`$ they were allocated.

| Allocation slot | Price at allocation | Refund when spent after $`s`$ |
| --- | ---: | ---: |
| Before $`s`$ (V1) | $`4310(250+74\cdot2)=1{,}715{,}380`$ lovelace | 1,715,380 lovelace |
| At $`s`$ (V2) | $`4310(260+80\cdot2)=1{,}810{,}200`$ lovelace | 1,810,200 lovelace |

The [live-ledger experiment](#ds-state-balance-p08) accepts these outputs, restores their snapshot and spends both under V2. The refund remains the sum of their historical deposits.

The following cases describe the pricing contract across ordinary outputs and collateral.

<a id="ds-pricing-p01" name="ds-pricing-p01"></a>

#### 1.4.1 P01 - Price each created output

For each newly created Deposit-backed reference, compute $`N`$, $`D`$ and $`R`$ from its
output. Compare the independently calculated $`F_{v,p}(o)`$ with the allocation read
from the ledger. Include TopTx, SubTx and an applied collateral return.

<a id="ds-pricing-n01" name="ds-pricing-n01"></a>

#### 1.4.2 N01 - Count distinct native assets

Under V1, increasing a token's quantity leaves the deposit unchanged. Adding a new
asset name under the same policy increases it by $`74p`$. The same asset name under
a different policy is also a distinct asset. Under V2 each additional asset costs $`80p`$.

<a id="ds-pricing-n02" name="ds-pricing-n02"></a>

#### 1.4.3 N02 - Price an applied collateral return

An accepted phase-2 failure creating a Deposit-backed collateral return allocates
$`F_{v,p}(o)`$ for its output. The same output under the same formula and rate costs
the same on the ordinary path.

<a id="ds-pricing-n03" name="ds-pricing-n03"></a>

#### 1.4.4 N03 - Measure datum and reference script payloads

For fixed assets and rate, a datum hash of 32 bytes adds $`32p`$. An inline datum
of $`d`$ bytes adds $`dp`$. Adding a reference script of $`r`$ bytes adds another $`rp`$.
Exercise absent payloads, native scripts and Plutus scripts.

<a id="ds-pricing-n04" name="ds-pricing-n04"></a>

#### 1.4.5 N04 - Vary the declaration independently

Hold the output and formula fixed and vary the surrounding body declaration. The
required deposit stays fixed. Accounting compares the declared amount with that
independently calculated requirement.

<a id="ds-pricing-n05" name="ds-pricing-n05"></a>

#### 1.4.6 N05 - Preserve the price across ADA encoding boundaries

For two Deposit-backed outputs with identical $`N,D,R`$, change application ADA from
23 to 24 lovelace. Their coin encodings differ in length, but both incur the same
external deposit. The same reasoning applies to a change in address length.

<a id="ds-pricing-n06" name="ds-pricing-n06"></a>

#### 1.4.7 N06 - Keep a min-ADA reserve inside its output

An existing `MinAdaTxOut` with $`C`$ lovelace contributes zero to the external total.
Its reserve is $`\min(C,F_{v,p}(o))`$, selected from its allocation history, and its
application ADA is the remainder. A newly proposed `MinAdaTxOut` is also allowed,
but must contain at least the full deposit under the Store's **current** formula.
The historical reserve cap does not relax admission of a new output.

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
| [Declarations](declarations.md#ds-tx-declarations) | Which forms are valid, and which bodies must declare? |
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

[Declaration grammar](declarations.md#ds-tx-declarations-grammar) defines the valid forms.
[Declaration requirements](declarations.md#ds-tx-declarations-requirements) specify which bodies must declare.

<a id="ds-tx-accounting" name="ds-tx-accounting"></a>

#### 2.1.2 Accounting

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

##### 2.1.2.1 Net change

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
| $`\mathrm{allocatedDeposits}(\mathit{body})`$ | [Price](#ds-pricing) the body's newly created deposit-backed outputs. |
| $`\mathrm{releasedDeposits}(\mathit{body})`$ | Read the recorded deposits of its consumed deposit-backed inputs. |
| $`\mathrm{declaredNetDeposit}(\mathit{body})`$ | The **signed** declared value: allocation $`\gt 0`$, release $`\lt 0`$, explicit zero $`=0`$. Absence has no declared value. |
| $`1`$ in amount comparisons | One lovelace. Example values labelled ADA are converted to lovelace. |

The builder and ledger derive these amounts from ordinary inputs resolved in the
original UTxO and the proposed regular outputs. Fee funding and change count on
the same terms. Reference inputs and collateral have separate rules.

These three ledger cases compare the signed declaration with the actual change
in external ADA. Each case also rejects the external-only amount when declared
by TopTx or SubTx. [Mixed-output regression tests](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/MixedBackingSpec.hs) and [verification results](verification.md#signed-backing-change-for-mixed-output-forms--24-november-2026).

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
external operations. See [Execution](#ds-state-execution) and [Historical pricing](#ds-pricing-history).

<a id="ds-tx-exactness-contribution" name="ds-tx-exactness-contribution"></a>
<a id="ds-tx-exactness-subtx" name="ds-tx-exactness-subtx"></a>
<a id="ds-tx-accounting-subtx" name="ds-tx-accounting-subtx"></a>
<a id="ds-tx-accounting-net-change-subtx" name="ds-tx-accounting-net-change-subtx"></a>

###### 2.1.2.1.1 SubTx

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

<a id="ds-tx-exactness-contribution-p01" name="ds-tx-exactness-contribution-p01"></a>
<a id="ds-tx-exactness-subtx-p01" name="ds-tx-exactness-subtx-p01"></a>
<a id="ds-tx-accounting-subtx-p01" name="ds-tx-accounting-subtx-p01"></a>
<a id="ds-tx-accounting-net-change-subtx-p01" name="ds-tx-accounting-net-change-subtx-p01"></a>

**2.1.2.1.1.1 [P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L90) - Each SubTx declares its own exact change**

```math
\begin{aligned}
&\mathrm{subTxNetChangeValid}\iff \\
&\forall\,\mathit{subTx}\in\mathrm{declaredSubTxs}(\mathit{topTx}): \\
&\qquad\mathrm{declaredNetDeposit}(\mathit{subTx})=\mathrm{ownNetDeposit}(\mathit{subTx})
\end{aligned}
```

Compare the isolated SubTx exactness result with independent input records and output prices; include exact and inexact declarations.

<a id="ds-tx-exactness-contribution-n01" name="ds-tx-exactness-contribution-n01"></a>
<a id="ds-tx-exactness-subtx-n01" name="ds-tx-exactness-subtx-n01"></a>
<a id="ds-tx-accounting-subtx-n01" name="ds-tx-accounting-subtx-n01"></a>
<a id="ds-tx-accounting-net-change-subtx-n01" name="ds-tx-accounting-net-change-subtx-n01"></a>

**2.1.2.1.1.2 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L126) - Exact own change, with any allocation and release combination**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{allocatedDeposits}(\mathit{subTx}) - \mathrm{releasedDeposits}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

Exercise positive allocation, negative release and explicit zero with local accounting; N03/N04 cover the delegated forms.

<a id="ds-tx-exactness-contribution-f01" name="ds-tx-exactness-contribution-f01"></a>
<a id="ds-tx-exactness-subtx-f01" name="ds-tx-exactness-subtx-f01"></a>
<a id="ds-tx-accounting-subtx-f01" name="ds-tx-accounting-subtx-f01"></a>
<a id="ds-tx-accounting-net-change-subtx-f01" name="ds-tx-accounting-net-change-subtx-f01"></a>

**2.1.2.1.1.3 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L148) - Net allocation understated by one lovelace**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 1 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

The required allocation exceeds one lovelace so the mutated declaration remains a positive allocation.

<a id="ds-tx-exactness-contribution-f02" name="ds-tx-exactness-contribution-f02"></a>
<a id="ds-tx-exactness-subtx-f02" name="ds-tx-exactness-subtx-f02"></a>
<a id="ds-tx-accounting-subtx-f02" name="ds-tx-accounting-subtx-f02"></a>
<a id="ds-tx-accounting-net-change-subtx-f02" name="ds-tx-accounting-net-change-subtx-f02"></a>

**2.1.2.1.1.4 [F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L166) - Net allocation overstated by one lovelace**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) + 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Keep the increased amount representable; this checks exactness rather than decoder overflow.

<a id="ds-tx-exactness-contribution-f03" name="ds-tx-exactness-contribution-f03"></a>
<a id="ds-tx-exactness-subtx-f03" name="ds-tx-exactness-subtx-f03"></a>
<a id="ds-tx-accounting-subtx-f03" name="ds-tx-accounting-subtx-f03"></a>
<a id="ds-tx-accounting-net-change-subtx-f03" name="ds-tx-accounting-net-change-subtx-f03"></a>

**2.1.2.1.1.5 [F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L184) - Net release understated by one lovelace**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < -1 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) + 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Reducing the positive release magnitude increases its signed declaration; the required release exceeds one lovelace.

<a id="ds-tx-exactness-contribution-f04" name="ds-tx-exactness-contribution-f04"></a>
<a id="ds-tx-exactness-subtx-f04" name="ds-tx-exactness-subtx-f04"></a>
<a id="ds-tx-accounting-subtx-f04" name="ds-tx-accounting-subtx-f04"></a>
<a id="ds-tx-accounting-net-change-subtx-f04" name="ds-tx-accounting-net-change-subtx-f04"></a>

**2.1.2.1.1.6 [F04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L202) - Net release overstated by one lovelace**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - 1 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Increasing the positive release magnitude decreases its signed declaration; keep the magnitude representable.

<a id="ds-tx-exactness-contribution-f05" name="ds-tx-exactness-contribution-f05"></a>
<a id="ds-tx-exactness-subtx-f05" name="ds-tx-exactness-subtx-f05"></a>
<a id="ds-tx-accounting-subtx-f05" name="ds-tx-accounting-subtx-f05"></a>
<a id="ds-tx-accounting-net-change-subtx-f05" name="ds-tx-accounting-net-change-subtx-f05"></a>

**2.1.2.1.1.7 [F05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L220) - Opposing SubTx errors cancel in the total**

```math
\begin{aligned}
&\mathit{firstSubTx} \ne \mathit{secondSubTx} \\
&\land \mathrm{declarationError}(\mathit{firstSubTx}) = -\mathrm{declarationError}(\mathit{secondSubTx}) \ne 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Both distinct SubTxs are in the transaction. Their errors cancel, but require a SubTx exactness failure.

<a id="ds-tx-exactness-contribution-n03" name="ds-tx-exactness-contribution-n03"></a>
<a id="ds-tx-exactness-subtx-n02" name="ds-tx-exactness-subtx-n02"></a>
<a id="ds-tx-accounting-subtx-n02" name="ds-tx-accounting-subtx-n02"></a>
<a id="ds-tx-accounting-net-change-subtx-n02" name="ds-tx-accounting-net-change-subtx-n02"></a>

**2.1.2.1.1.8 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L239) - Equal own allocations and releases, explicit zero**

```math
\begin{aligned}
&\mathrm{allocatedDeposits}(\mathit{subTx}) = \mathrm{releasedDeposits}(\mathit{subTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

Use an explicit-zero declaration, including both zero operations and nonzero allocations equal to releases.

<a id="ds-tx-exactness-contribution-f06" name="ds-tx-exactness-contribution-f06"></a>
<a id="ds-tx-exactness-subtx-f06" name="ds-tx-exactness-subtx-f06"></a>
<a id="ds-tx-accounting-subtx-f06" name="ds-tx-accounting-subtx-f06"></a>
<a id="ds-tx-accounting-net-change-subtx-f06" name="ds-tx-accounting-net-change-subtx-f06"></a>

**2.1.2.1.1.9 [F06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L248) - Explicit zero cannot replace a required allocation**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

The field is present as explicit zero; its amount is incorrect.

<a id="ds-tx-exactness-contribution-n04" name="ds-tx-exactness-contribution-n04"></a>
<a id="ds-tx-exactness-subtx-n03" name="ds-tx-exactness-subtx-n03"></a>
<a id="ds-tx-accounting-subtx-n03" name="ds-tx-accounting-subtx-n03"></a>
<a id="ds-tx-accounting-net-change-subtx-n03" name="ds-tx-accounting-net-change-subtx-n03"></a>

**2.1.2.1.1.10 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L266) - Exact allocation requested from TopTx**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{delegatesAllocation}(\mathit{subTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

`RequestsUTxODepositFromTopTx` carries the requesting SubTx own net allocation, while TopTx declares the transaction total.

<a id="ds-tx-exactness-contribution-n05" name="ds-tx-exactness-contribution-n05"></a>
<a id="ds-tx-exactness-subtx-n04" name="ds-tx-exactness-subtx-n04"></a>
<a id="ds-tx-accounting-subtx-n04" name="ds-tx-accounting-subtx-n04"></a>
<a id="ds-tx-accounting-net-change-subtx-n04" name="ds-tx-accounting-net-change-subtx-n04"></a>

**2.1.2.1.1.11 [N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L278) - Exact release delegated to TopTx**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{delegatesRelease}(\mathit{subTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

The release targets `DelegateToTopTx`; its magnitude remains exactly the originating SubTx own net release.

<a id="ds-tx-exactness-contribution-n06" name="ds-tx-exactness-contribution-n06"></a>
<a id="ds-tx-exactness-subtx-n05" name="ds-tx-exactness-subtx-n05"></a>
<a id="ds-tx-accounting-subtx-n05" name="ds-tx-accounting-subtx-n05"></a>
<a id="ds-tx-accounting-net-change-subtx-n05" name="ds-tx-accounting-net-change-subtx-n05"></a>

**2.1.2.1.1.12 [N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L290) - Released deposits, only min-ADA outputs**

```math
\begin{aligned}
&\mathrm{releasedDeposits}(\mathit{subTx}) > 0 \\
&\land \mathrm{depositBackedOutputs}(\mathit{subTx}) = \varnothing \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = -\mathrm{releasedDeposits}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

The fixture pairs its min-ADA outputs with inputs carrying equal embedded backing.
The signed release therefore equals the historical external deposits consumed.

<a id="ds-tx-exactness-contribution-f07" name="ds-tx-exactness-contribution-f07"></a>
<a id="ds-tx-exactness-subtx-f07" name="ds-tx-exactness-subtx-f07"></a>
<a id="ds-tx-accounting-subtx-f07" name="ds-tx-accounting-subtx-f07"></a>
<a id="ds-tx-accounting-net-change-subtx-f07" name="ds-tx-accounting-net-change-subtx-f07"></a>

**2.1.2.1.1.13 [F07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L302) - Explicit zero cannot replace a required release**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

The field is present as explicit zero; a negative own change still requires a release declaration.

<a id="ds-tx-exactness-contribution-n07" name="ds-tx-exactness-contribution-n07"></a>
<a id="ds-tx-exactness-subtx-n06" name="ds-tx-exactness-subtx-n06"></a>
<a id="ds-tx-accounting-subtx-n06" name="ds-tx-accounting-subtx-n06"></a>
<a id="ds-tx-accounting-net-change-subtx-n06" name="ds-tx-accounting-net-change-subtx-n06"></a>

**2.1.2.1.1.14 [N06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L320) - Another body offsets the SubTx release**

```math
\begin{aligned}
&\mathit{otherBody} \ne \mathit{subTx} \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) < 0 < \mathrm{ownNetDeposit}(\mathit{otherBody}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

The other body is TopTx or another SubTx. Cover partial, equal and greater offsets; none changes this SubTx own release.

<a id="ds-tx-exactness-contribution-n08" name="ds-tx-exactness-contribution-n08"></a>
<a id="ds-tx-exactness-subtx-n07" name="ds-tx-exactness-subtx-n07"></a>
<a id="ds-tx-accounting-subtx-n07" name="ds-tx-accounting-subtx-n07"></a>
<a id="ds-tx-accounting-net-change-subtx-n07" name="ds-tx-accounting-net-change-subtx-n07"></a>

**2.1.2.1.1.15 [N07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L342) - An output without application assets still requires a deposit**

```math
\begin{aligned}
&\mathrm{depositBackedOutputs}(\mathit{subTx}) = \{\mathit{output}\} \\
&\land \mathrm{applicationAssets}(\mathit{output}) = \varnothing \\
&\land \mathrm{releasedDeposits}(\mathit{subTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{allocatedDeposits}(\mathit{subTx}) > 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

The formula charges its base even when the application value is empty. Use a positive rate and declare the exact allocation.

<a id="ds-tx-exactness-contribution-n09" name="ds-tx-exactness-contribution-n09"></a>
<a id="ds-tx-exactness-subtx-n08" name="ds-tx-exactness-subtx-n08"></a>
<a id="ds-tx-accounting-subtx-n08" name="ds-tx-accounting-subtx-n08"></a>
<a id="ds-tx-accounting-net-change-subtx-n08" name="ds-tx-accounting-net-change-subtx-n08"></a>

**2.1.2.1.1.16 [N08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L354) - A translated min-ADA input funds an exact allocation**

```math
\begin{aligned}
&\mathrm{ordinaryInputs}(\mathit{subTx}) = \{\mathit{translatedImplicitInput}\} \\
&\land \mathrm{depositBackedOutputs}(\mathit{subTx}) \ne \varnothing \\
&\land \mathrm{releasedDeposits}(\mathit{subTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{allocatedDeposits}(\mathit{subTx}) > 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

The translated input funds the external obligations. Its credited min-ADA
reserve cancels the reserve of the fixture's min-ADA change output.

<a id="ds-tx-exactness-contribution-f08" name="ds-tx-exactness-contribution-f08"></a>
<a id="ds-tx-exactness-subtx-f08" name="ds-tx-exactness-subtx-f08"></a>
<a id="ds-tx-accounting-subtx-f08" name="ds-tx-accounting-subtx-f08"></a>
<a id="ds-tx-accounting-net-change-subtx-f08" name="ds-tx-accounting-net-change-subtx-f08"></a>

**2.1.2.1.1.17 [F08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L366) - A translated min-ADA input does not excuse an inexact allocation**

```math
\begin{aligned}
&\mathrm{ordinaryInputs}(\mathit{subTx}) = \{\mathit{translatedImplicitInput}\} \\
&\land \mathrm{depositBackedOutputs}(\mathit{subTx}) \ne \varnothing \\
&\land \mathrm{releasedDeposits}(\mathit{subTx}) = 0 \\
&\land \mathrm{allocatedDeposits}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) \ne \mathrm{allocatedDeposits}(\mathit{subTx}) \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Use the N08 allocation scenario, changing only the positive SubTx declaration to a different representable amount.

<a id="ds-tx-exactness-contribution-f09" name="ds-tx-exactness-contribution-f09"></a>
<a id="ds-tx-exactness-subtx-f09" name="ds-tx-exactness-subtx-f09"></a>
<a id="ds-tx-accounting-subtx-f09" name="ds-tx-accounting-subtx-f09"></a>
<a id="ds-tx-accounting-net-change-subtx-f09" name="ds-tx-accounting-net-change-subtx-f09"></a>

**2.1.2.1.1.18 [F09](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L385) - Unspent outputs cannot increase a SubTx release**

```math
\begin{aligned}
&\mathit{unspentInputs}\cap\mathit{consumedInputs}=\varnothing \\
&\land 0 < \mathit{unrelatedRelease} \le \mathrm{recordedDeposits}(\mathit{unspentInputs}) \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) \le 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx}) - \mathit{unrelatedRelease} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Fund one to four separate Deposit-backed outputs and leave them unspent. Their
recorded deposits are not available to this SubTx: increasing the declared release
by part of that amount fails exactness. The unchanged declaration remains accepted.

<a id="ds-tx-exactness-contribution-f10" name="ds-tx-exactness-contribution-f10"></a>
<a id="ds-tx-exactness-subtx-f10" name="ds-tx-exactness-subtx-f10"></a>
<a id="ds-tx-accounting-subtx-f10" name="ds-tx-accounting-subtx-f10"></a>
<a id="ds-tx-accounting-net-change-subtx-f10" name="ds-tx-accounting-net-change-subtx-f10"></a>

**2.1.2.1.1.19 [F10](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L410) - A release cannot replace a required allocation**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) < 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Exercise valid local and delegated release forms; their sign contradicts the independently required own change.

<a id="ds-tx-exactness-contribution-f11" name="ds-tx-exactness-contribution-f11"></a>
<a id="ds-tx-exactness-subtx-f11" name="ds-tx-exactness-subtx-f11"></a>
<a id="ds-tx-accounting-subtx-f11" name="ds-tx-accounting-subtx-f11"></a>
<a id="ds-tx-accounting-net-change-subtx-f11" name="ds-tx-accounting-net-change-subtx-f11"></a>

**2.1.2.1.1.20 [F11](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L429) - An allocation cannot replace a required release**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{subTx}) < 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{subTx}) > 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Exercise a local allocation and a funding request to TopTx; neither can represent the required own release.

<a id="ds-tx-exactness-contribution-n10" name="ds-tx-exactness-contribution-n10"></a>
<a id="ds-tx-exactness-subtx-n09" name="ds-tx-exactness-subtx-n09"></a>
<a id="ds-tx-accounting-subtx-n09" name="ds-tx-accounting-subtx-n09"></a>
<a id="ds-tx-accounting-net-change-subtx-n09" name="ds-tx-accounting-net-change-subtx-n09"></a>

**2.1.2.1.1.21 [N09](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L449) - Exact SubTx declarations when phase 2 fails**

```math
\begin{aligned}
&\mathrm{declaredSubTxs}(\mathit{topTx}) \ne \varnothing \\
&\land (\forall \mathit{subTx} \in \mathrm{declaredSubTxs}(\mathit{topTx}): \\
&\qquad\mathrm{declaredNetDeposit}(\mathit{subTx}) = \mathrm{ownNetDeposit}(\mathit{subTx})) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{accepted}
\end{aligned}
```

Use a real failing script with otherwise valid declarations and transaction terms. Acceptance follows the collateral outcome, without ordinary Store effects.

<a id="ds-tx-exactness-contribution-f12" name="ds-tx-exactness-contribution-f12"></a>
<a id="ds-tx-exactness-subtx-f12" name="ds-tx-exactness-subtx-f12"></a>
<a id="ds-tx-accounting-subtx-f12" name="ds-tx-accounting-subtx-f12"></a>
<a id="ds-tx-accounting-net-change-subtx-f12" name="ds-tx-accounting-net-change-subtx-f12"></a>

**2.1.2.1.1.22 [F12](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/SubTxSpec.hs#L471) - An inexact SubTx declaration still fails before the collateral outcome**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{subTx}) \ne \mathrm{ownNetDeposit}(\mathit{subTx}) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactSubTxDepositChange})
\end{aligned}
```

Start from N09 failing-script controls and mutate a SubTx amount. The independently established script failure does not waive the earlier exactness check.

<a id="ds-tx-exactness-netting" name="ds-tx-exactness-netting"></a>
<a id="ds-tx-exactness-toptx" name="ds-tx-exactness-toptx"></a>
<a id="ds-tx-accounting-toptx" name="ds-tx-accounting-toptx"></a>
<a id="ds-tx-accounting-net-change-toptx" name="ds-tx-accounting-net-change-toptx"></a>

###### 2.1.2.1.2 TopTx

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
apply. [Requirements](declarations.md#ds-tx-declarations-requirements) determines field presence.

<a id="ds-tx-exactness-netting-p01" name="ds-tx-exactness-netting-p01"></a>
<a id="ds-tx-exactness-toptx-p01" name="ds-tx-exactness-toptx-p01"></a>
<a id="ds-tx-accounting-toptx-p01" name="ds-tx-accounting-toptx-p01"></a>
<a id="ds-tx-accounting-net-change-toptx-p01" name="ds-tx-accounting-net-change-toptx-p01"></a>

**2.1.2.1.2.1 [P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L72) - TopTx declares the exact transaction total**

```math
\begin{aligned}
&\mathrm{topTxNetChangeValid}(\mathit{topTx}) \\
&\iff \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx})
\end{aligned}
```

Compare the isolated TopTx validator with independently computed deposits; this equivalence does not assert complete ledger acceptance.

<a id="ds-tx-attribution-n02" name="ds-tx-attribution-n02"></a>
<a id="ds-tx-accounting-net-change-toptx-p02" name="ds-tx-accounting-net-change-toptx-p02"></a>

**2.1.2.1.2.2 [P02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L90) - Delegation preserves the transaction total**

```math
\begin{aligned}
&\text{sameStoreOperations(localTx, delegatedTx)} \\
&\implies\text{requiredNetDeposit(localTx)}=\text{requiredNetDeposit(delegatedTx)} \\
&\qquad\land\text{Accepted(localTx)}\land\text{Accepted(delegatedTx)}
\end{aligned}
```

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

**2.1.2.1.2.3 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L122) - TopTx and SubTxs contribute to the total**

```math
\begin{aligned}
&(\exists \mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{subTx}) \ne 0) \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\implies \mathrm{accepted}
\end{aligned}
```

Cover both zero and nonzero TopTx own changes alongside nonzero child changes. The declared total includes every own change exactly once.

<a id="ds-tx-exactness-contribution-n02" name="ds-tx-exactness-contribution-n02"></a>
<a id="ds-tx-exactness-toptx-n02" name="ds-tx-exactness-toptx-n02"></a>
<a id="ds-tx-accounting-toptx-n02" name="ds-tx-accounting-toptx-n02"></a>
<a id="ds-tx-accounting-net-change-toptx-n02" name="ds-tx-accounting-net-change-toptx-n02"></a>

**2.1.2.1.2.4 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L135) - TopTx's own change is derived from its total**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\implies \\
&\mathrm{declaredNetDeposit}(\mathit{topTx}) \\
&\quad-\sum_{\mathit{subTx}\in\mathrm{declaredSubTxs}(\mathit{topTx})}
\mathrm{declaredNetDeposit}(\mathit{subTx}) \\
&\qquad=\mathrm{ownNetDeposit}(\mathit{topTx})
\end{aligned}
```

In this fixture every undeclared child has zero net embedded backing. Subtracting
all present child declarations, including delegated operations, therefore recovers
the parent's own backing change.

<a id="ds-tx-exactness-netting-n02" name="ds-tx-exactness-netting-n02"></a>
<a id="ds-tx-exactness-toptx-n03" name="ds-tx-exactness-toptx-n03"></a>
<a id="ds-tx-accounting-toptx-n03" name="ds-tx-accounting-toptx-n03"></a>
<a id="ds-tx-accounting-net-change-toptx-n03" name="ds-tx-accounting-net-change-toptx-n03"></a>

**2.1.2.1.2.5 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L148) - 5 ADA allocated, 3 ADA released**

```math
\begin{aligned}
&\sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{allocatedDeposits}(\mathit{body}) = 5 \,\mathrm{ADA} \\
&\land \sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{releasedDeposits}(\mathit{body}) = 3 \,\mathrm{ADA} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 2 \,\mathrm{ADA} \\
&\implies \mathrm{accepted}
\end{aligned}
```

Both sums cover TopTx and all SubTxs; the transaction requires a net allocation of 2 ADA.

<a id="ds-tx-exactness-netting-n03" name="ds-tx-exactness-netting-n03"></a>
<a id="ds-tx-exactness-toptx-n04" name="ds-tx-exactness-toptx-n04"></a>
<a id="ds-tx-accounting-toptx-n04" name="ds-tx-accounting-toptx-n04"></a>
<a id="ds-tx-accounting-net-change-toptx-n04" name="ds-tx-accounting-net-change-toptx-n04"></a>

**2.1.2.1.2.6 [N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L159) - 3 ADA allocated, 5 ADA released**

```math
\begin{aligned}
&\sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{allocatedDeposits}(\mathit{body}) = 3 \,\mathrm{ADA} \\
&\land \sum_{\mathit{body}\in\mathrm{bodies}(\mathit{topTx})} \mathrm{releasedDeposits}(\mathit{body}) = 5 \,\mathrm{ADA} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = -2 \,\mathrm{ADA} \\
&\implies \mathrm{accepted}
\end{aligned}
```

Both sums cover TopTx and all SubTxs; the transaction releases 2 ADA net.

<a id="ds-tx-exactness-netting-n04" name="ds-tx-exactness-netting-n04"></a>
<a id="ds-tx-exactness-toptx-n05" name="ds-tx-exactness-toptx-n05"></a>
<a id="ds-tx-accounting-toptx-n05" name="ds-tx-accounting-toptx-n05"></a>
<a id="ds-tx-accounting-net-change-toptx-n05" name="ds-tx-accounting-net-change-toptx-n05"></a>

**2.1.2.1.2.7 [N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L171) - Nonzero body changes produce a zero total**

```math
\begin{aligned}
&(\exists \mathit{body} \in \mathrm{bodies}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{body}) \ne 0) \\
&\land \mathrm{transactionNetDeposit}(\mathit{topTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

Allocating and releasing bodies offset each other. TopTx still supplies an explicit zero declaration.

<a id="ds-tx-exactness-netting-f01" name="ds-tx-exactness-netting-f01"></a>
<a id="ds-tx-exactness-toptx-f01" name="ds-tx-exactness-toptx-f01"></a>
<a id="ds-tx-accounting-toptx-f01" name="ds-tx-accounting-toptx-f01"></a>
<a id="ds-tx-accounting-net-change-toptx-f01" name="ds-tx-accounting-net-change-toptx-f01"></a>

**2.1.2.1.2.8 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L181) - Standalone TopTx understates its net allocation by one lovelace**

```math
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{transactionNetDeposit}(\mathit{topTx}) > 1 \,\mathrm{lovelace} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) - 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Create one more deposit-backed output than is consumed. Start from a valid control and alter only the signed declaration.

<a id="ds-tx-exactness-netting-f02" name="ds-tx-exactness-netting-f02"></a>
<a id="ds-tx-exactness-toptx-f02" name="ds-tx-exactness-toptx-f02"></a>
<a id="ds-tx-accounting-toptx-f02" name="ds-tx-accounting-toptx-f02"></a>
<a id="ds-tx-accounting-net-change-toptx-f02" name="ds-tx-accounting-net-change-toptx-f02"></a>

**2.1.2.1.2.9 [F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L193) - Standalone TopTx overstates its net allocation by one lovelace**

```math
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{transactionNetDeposit}(\mathit{topTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) + 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Use the same net-allocation generator and increase only the declaration by one lovelace.

<a id="ds-tx-exactness-netting-f03" name="ds-tx-exactness-netting-f03"></a>
<a id="ds-tx-exactness-toptx-f03" name="ds-tx-exactness-toptx-f03"></a>
<a id="ds-tx-accounting-toptx-f03" name="ds-tx-accounting-toptx-f03"></a>
<a id="ds-tx-accounting-net-change-toptx-f03" name="ds-tx-accounting-net-change-toptx-f03"></a>

**2.1.2.1.2.10 [F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L206) - Standalone TopTx understates its net release by one lovelace**

```math
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{allocatedDeposits}(\mathit{topTx}) = 0 \\
&\land \mathrm{releasedDeposits}(\mathit{topTx}) > 1 \,\mathrm{lovelace} \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) + 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Only min-ADA outputs are created. Adding one to the negative declaration reduces the release magnitude.

<a id="ds-tx-exactness-netting-f04" name="ds-tx-exactness-netting-f04"></a>
<a id="ds-tx-exactness-toptx-f04" name="ds-tx-exactness-toptx-f04"></a>
<a id="ds-tx-accounting-toptx-f04" name="ds-tx-accounting-toptx-f04"></a>
<a id="ds-tx-accounting-net-change-toptx-f04" name="ds-tx-accounting-net-change-toptx-f04"></a>

**2.1.2.1.2.11 [F04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L219) - Standalone TopTx overstates its net release by one lovelace**

```math
\begin{aligned}
&\mathrm{subTxs}(\mathit{topTx}) = \varnothing \\
&\land \mathrm{allocatedDeposits}(\mathit{topTx}) = 0 \\
&\land \mathrm{releasedDeposits}(\mathit{topTx}) > 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) - 1 \,\mathrm{lovelace} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Only min-ADA outputs are created. Subtracting one from the negative declaration increases the release magnitude.

<a id="ds-tx-exactness-netting-f05" name="ds-tx-exactness-netting-f05"></a>
<a id="ds-tx-exactness-toptx-f05" name="ds-tx-exactness-toptx-f05"></a>
<a id="ds-tx-accounting-toptx-f05" name="ds-tx-accounting-toptx-f05"></a>
<a id="ds-tx-accounting-net-change-toptx-f05" name="ds-tx-accounting-net-change-toptx-f05"></a>

**2.1.2.1.2.12 [F05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L231) - Explicit zero cannot replace a nonzero total**

```math
\begin{aligned}
&\mathrm{transactionNetDeposit}(\mathit{topTx}) \ne 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Cover both a required net allocation and a required net release.

<a id="ds-tx-exactness-netting-f06" name="ds-tx-exactness-netting-f06"></a>
<a id="ds-tx-exactness-toptx-f06" name="ds-tx-exactness-toptx-f06"></a>
<a id="ds-tx-accounting-toptx-f06" name="ds-tx-accounting-toptx-f06"></a>
<a id="ds-tx-accounting-net-change-toptx-f06" name="ds-tx-accounting-net-change-toptx-f06"></a>

**2.1.2.1.2.13 [F06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L247) - A nonzero declaration cannot replace a zero total**

```math
\begin{aligned}
&\mathrm{transactionNetDeposit}(\mathit{topTx}) = 0 \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) \ne 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

Cover both an allocation declaration and a release declaration when the transaction total is zero.

<a id="ds-tx-exactness-netting-f07" name="ds-tx-exactness-netting-f07"></a>
<a id="ds-tx-exactness-toptx-f07" name="ds-tx-exactness-toptx-f07"></a>
<a id="ds-tx-accounting-toptx-f07" name="ds-tx-accounting-toptx-f07"></a>
<a id="ds-tx-accounting-net-change-toptx-f07" name="ds-tx-accounting-net-change-toptx-f07"></a>

**2.1.2.1.2.14 [F07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L262) - TopTx declares the opposite direction**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) \times \mathrm{transactionNetDeposit}(\mathit{topTx}) < 0 \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

A required allocation cannot be declared as a release, or a required release as an allocation.

<a id="ds-tx-exactness-netting-n05" name="ds-tx-exactness-netting-n05"></a>
<a id="ds-tx-exactness-toptx-n06" name="ds-tx-exactness-toptx-n06"></a>
<a id="ds-tx-accounting-toptx-n06" name="ds-tx-accounting-toptx-n06"></a>
<a id="ds-tx-accounting-net-change-toptx-n06" name="ds-tx-accounting-net-change-toptx-n06"></a>

**2.1.2.1.2.15 [N06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L281) - TopTx releases while SubTxs allocate**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{topTx}) < 0 \\
&\land (\forall \mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{subTx}) \ge 0) \\
&\land \sum_{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx})} \mathrm{ownNetDeposit}(\mathit{subTx}) = -\mathrm{ownNetDeposit}(\mathit{topTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

The child allocations exactly offset the parent release. TopTx declares the transaction total, not its own negative change.

<a id="ds-tx-exactness-netting-n06" name="ds-tx-exactness-netting-n06"></a>
<a id="ds-tx-exactness-toptx-n07" name="ds-tx-exactness-toptx-n07"></a>
<a id="ds-tx-accounting-toptx-n07" name="ds-tx-accounting-toptx-n07"></a>
<a id="ds-tx-accounting-net-change-toptx-n07" name="ds-tx-accounting-net-change-toptx-n07"></a>

**2.1.2.1.2.16 [N07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L291) - TopTx allocates while SubTxs release**

```math
\begin{aligned}
&\mathrm{ownNetDeposit}(\mathit{topTx}) > 0 \\
&\land (\forall \mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}): \mathrm{ownNetDeposit}(\mathit{subTx}) \le 0) \\
&\land \sum_{\mathit{subTx}\in\mathrm{subTxs}(\mathit{topTx})} \mathrm{ownNetDeposit}(\mathit{subTx}) = -\mathrm{ownNetDeposit}(\mathit{topTx}) \\
&\land \mathrm{declaredNetDeposit}(\mathit{topTx}) = 0 \\
&\implies \mathrm{accepted}
\end{aligned}
```

The child releases exactly offset the parent allocation. TopTx declares the transaction total, not its own positive change.

<a id="ds-tx-exactness-netting-n07" name="ds-tx-exactness-netting-n07"></a>
<a id="ds-tx-exactness-toptx-n08" name="ds-tx-exactness-toptx-n08"></a>
<a id="ds-tx-accounting-toptx-n08" name="ds-tx-accounting-toptx-n08"></a>
<a id="ds-tx-accounting-net-change-toptx-n08" name="ds-tx-accounting-net-change-toptx-n08"></a>

**2.1.2.1.2.17 [N08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L301) - An exact total remains valid when phase 2 fails**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) = \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{accepted}
\end{aligned}
```

The failing script matches the declared outcome. Net change still uses proposed ordinary deposits; collateral execution is a separate rule.

<a id="ds-tx-exactness-netting-f08" name="ds-tx-exactness-netting-f08"></a>
<a id="ds-tx-exactness-toptx-f08" name="ds-tx-exactness-toptx-f08"></a>
<a id="ds-tx-accounting-toptx-f08" name="ds-tx-accounting-toptx-f08"></a>
<a id="ds-tx-accounting-net-change-toptx-f08" name="ds-tx-accounting-net-change-toptx-f08"></a>

**2.1.2.1.2.18 [F08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L313) - An inexact total is rejected even when phase 2 fails**

```math
\begin{aligned}
&\mathrm{declaredNetDeposit}(\mathit{topTx}) \ne \mathrm{transactionNetDeposit}(\mathit{topTx}) \\
&\land \mathit{phase2Result} = \mathsf{Failed} \\
&\land \mathit{declaredPhase2} = \mathsf{Invalid} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

A failing script does not waive deposit exactness. The script matches the declared outcome; rejection must include the TopTx exactness failure.

<a id="ds-tx-exactness-netting-f09" name="ds-tx-exactness-netting-f09"></a>
<a id="ds-tx-exactness-toptx-f09" name="ds-tx-exactness-toptx-f09"></a>
<a id="ds-tx-accounting-toptx-f09" name="ds-tx-accounting-toptx-f09"></a>
<a id="ds-tx-accounting-net-change-toptx-f09" name="ds-tx-accounting-net-change-toptx-f09"></a>

**2.1.2.1.2.19 [F09](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChange/TopTxSpec.hs#L330) - A delegated change belongs in the total exactly once**

```math
\begin{aligned}
&\mathit{subTx} \in \mathrm{subTxs}(\mathit{topTx}) \\
&\land \mathrm{delegated}(\mathit{subTx}) \\
&\land \mathrm{ownNetDeposit}(\mathit{subTx}) \ne 0 \\
&\land\mathrm{declaredNetDeposit}(\mathit{topTx})\in\{ \\
&\qquad\mathrm{transactionNetDeposit}(\mathit{topTx})-\mathrm{ownNetDeposit}(\mathit{subTx}), \\
&\qquad\mathrm{transactionNetDeposit}(\mathit{topTx})+\mathrm{ownNetDeposit}(\mathit{subTx})\} \\
&\implies \mathrm{rejectedWith}(\mathsf{InexactTopTxDepositChange})
\end{aligned}
```

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

###### 2.1.2.2.1 [P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L39) - Local and delegated contributions determine TopTx's share

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

###### 2.1.2.2.2 [P02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L67) - Delegation moves the signed contribution to TopTx

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

The [Net change property](#ds-tx-accounting-net-change-toptx-p02) checks that the
transaction total stays unchanged. This property checks the responsibility shift.
It does not promise acceptance with unchanged selectors or outputs: moving a release
may require a different settlement destination or greater coverage.

<a id="ds-tx-grammar-n01" name="ds-tx-grammar-n01"></a>
<a id="ds-tx-declarations-grammar-n01" name="ds-tx-declarations-grammar-n01"></a>
<a id="ds-tx-attribution-n04" name="ds-tx-attribution-n04"></a>
<a id="ds-tx-settlement-participation-n10" name="ds-tx-settlement-participation-n10"></a>
<a id="ds-tx-accounting-attribution-n01" name="ds-tx-accounting-attribution-n01"></a>

###### 2.1.2.2.3 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/AttributionSpec.hs#L98) - Explicit zero adds no delegated contribution

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
declaration, as specified under [Zero net change](declarations.md#ds-tx-declarations-requirements-operations-zero-net-change).

<a id="ds-tx-conservation" name="ds-tx-conservation"></a>
<a id="ds-tx-accounting-balance" name="ds-tx-accounting-balance"></a>

##### 2.1.2.3 Balance

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

**The concrete release example.** N06, N07 and F04 hold every other batch flow
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
vary between rows.

<a id="ds-tx-conservation-p01" name="ds-tx-conservation-p01"></a>
<a id="ds-tx-accounting-balance-p01" name="ds-tx-accounting-balance-p01"></a>

###### 2.1.2.3.1 [P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L72) - The transaction conserves value when phase 2 is valid

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

###### 2.1.2.3.2 [P02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L96) - Complete balance determines acceptance

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

###### 2.1.2.3.3 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L117) - Fund a net allocation once

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

###### 2.1.2.3.4 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L137) - Use a net release once

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

###### 2.1.2.3.5 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L155) - One SubTx funds another

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

###### 2.1.2.3.6 [N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L168) - A SubTx funds TopTx fees

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

###### 2.1.2.3.7 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L181) - One-lovelace deficit or surplus

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

###### 2.1.2.3.8 [F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L199) - Native-asset quantity or identity mismatch

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

###### 2.1.2.3.9 [F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L219) - An exact delegated allocation lacks funding

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

###### 2.1.2.3.10 [N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L234) - Equal delegated allocations and releases

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

###### 2.1.2.3.11 [N06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L246) - Ten input ADA plus two released ADA

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

###### 2.1.2.3.12 [N07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L255) - Released ADA contributes to TopTx fees

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

###### 2.1.2.3.13 [F04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L265) - Released ADA cannot disappear

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

###### 2.1.2.3.14 [N08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs#L280) - Balanced proposal, failed phase 2

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
path. [Execution](#ds-state-execution) determines the applied effects.

<a id="ds-tx-authorization" name="ds-tx-authorization"></a>

#### 2.1.3 Authorization

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

##### 2.1.3.1 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L51) - Bob spends an output funded by Alice

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

##### 2.1.3.2 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AuthorizationSpec.hs#L73) - Alice's signature cannot replace Bob's

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

**Related rule — reference-only access.** [Release N09](declarations.md#ds-tx-declarations-requirements-operations-release-n09)
already checks that referencing live deposit-backed outputs does not require a release
declaration. A reference does not consume the output or release its deposit. Declaring
an amount released from reference inputs would be an inexact [Accounting](#ds-tx-accounting-net-change)
claim, not a missing spending-witness failure. It is not an additional Authorization
test.

<a id="ds-tx-settlement" name="ds-tx-settlement"></a>

#### 2.1.4 Settlement

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

##### 2.1.4.1 Designation

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

###### 2.1.4.1.1 [P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L47) - Designation follows TopTx's release share

```math
\text{totalChange}<0
\implies(\text{designationValid}\iff(\text{hasTopTxOutput}\iff\text{topTxChange}<0))
```

For each generated net-release proposal, check both designation choices and both local and delegated child releases. Compare the isolated validator with an expectation derived from recorded input deposits and priced outputs, independently of production attribution.

<a id="ds-tx-settlement-participation-n01" name="ds-tx-settlement-participation-n01"></a>
<a id="ds-tx-settlement-designation-n01" name="ds-tx-settlement-designation-n01"></a>

###### 2.1.4.1.2 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L69) - SubTxs settle the entire release

```math
\text{totalChange}<0\land\text{topTxChange}=0\land\text{noTopTxOutput}
\implies\text{Accepted}
```

Every SubTx settles its release locally. TopTx has no remaining release share, so its exact total declaration uses `NoTopTxSettlement`.

<a id="ds-tx-settlement-participation-n02" name="ds-tx-settlement-participation-n02"></a>
<a id="ds-tx-settlement-designation-n02" name="ds-tx-settlement-designation-n02"></a>

###### 2.1.4.1.3 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L82) - Standalone TopTx settles its release

```math
\text{totalChange}<0\land\text{topTxChange}<0\land\text{hasTopTxOutput}
\implies\text{Accepted}
```

A standalone TopTx releases deposits and designates one of its outputs. With no SubTx contribution, its attributed share is the complete transaction release.

<a id="ds-tx-settlement-participation-n03" name="ds-tx-settlement-participation-n03"></a>
<a id="ds-tx-settlement-designation-n03" name="ds-tx-settlement-designation-n03"></a>

###### 2.1.4.1.4 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L93) - TopTx and SubTxs each settle a share

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

###### 2.1.4.1.5 [N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L106) - TopTx's share exceeds the transaction release

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

###### 2.1.4.1.6 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L120) - TopTx omits a required output

```math
\begin{aligned}
&\text{totalChange}<0\land\text{topTxChange}<0\land\text{noTopTxOutput} \\
&\implies\text{RejectedWith(MissingTopTxSettlement)}
\end{aligned}
```

Keep the total exact and the transaction funded, but use `NoTopTxSettlement` despite TopTx having a positive release share. Require the missing-designation failure.

<a id="ds-tx-settlement-participation-f02" name="ds-tx-settlement-participation-f02"></a>
<a id="ds-tx-settlement-designation-f02" name="ds-tx-settlement-designation-f02"></a>

###### 2.1.4.1.7 [F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L131) - TopTx designates an unnecessary output

```math
\begin{aligned}
&\text{totalChange}<0\land\text{topTxChange}=0\land\text{hasTopTxOutput} \\
&\implies\text{RejectedWith(UnexpectedTopTxSettlement)}
\end{aligned}
```

All releases are settled locally by SubTxs. An additional TopTx designation is rejected, even though its index and output coin would otherwise be valid.

<a id="ds-tx-settlement-participation-n05" name="ds-tx-settlement-participation-n05"></a>
<a id="ds-tx-settlement-designation-n05" name="ds-tx-settlement-designation-n05"></a>

###### 2.1.4.1.8 [N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L144) - Net allocation, even though TopTx releases

```math
\text{totalChange}>0\land\text{topTxChange}<0\land\text{noTopTxOutput}
\implies\text{Accepted}
```

Local SubTx allocations exceed TopTx’s release. The complete transaction declares an allocation, whose grammar has no settlement designation. A negative TopTx share does not introduce one.

<a id="ds-tx-settlement-participation-n06" name="ds-tx-settlement-participation-n06"></a>
<a id="ds-tx-settlement-designation-n06" name="ds-tx-settlement-designation-n06"></a>

###### 2.1.4.1.9 [N06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L157) - Explicit-zero total, even though TopTx releases

```math
\text{totalChange}=0\land\text{topTxChange}<0\land\text{noTopTxOutput}
\implies\text{Accepted}
```

Local SubTx allocations exactly offset TopTx’s release. TopTx declares explicit zero; that declaration has no designation field.

<a id="ds-tx-settlement-participation-n07" name="ds-tx-settlement-participation-n07"></a>
<a id="ds-tx-settlement-designation-n07" name="ds-tx-settlement-designation-n07"></a>

###### 2.1.4.1.10 [N07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L170) - Net release, while TopTx allocates

```math
\text{totalChange}<0\land\text{topTxChange}>0\land\text{noTopTxOutput}
\implies\text{Accepted}
```

Local SubTx releases exceed TopTx’s allocation. The complete transaction releases deposits, but TopTx has no release share. Accept `NoTopTxSettlement`; zero and positive attributed changes both permit it.

<a id="ds-tx-settlement-participation-n08" name="ds-tx-settlement-participation-n08"></a>
<a id="ds-tx-settlement-designation-n08" name="ds-tx-settlement-designation-n08"></a>

###### 2.1.4.1.11 [N08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L183) - Valid designation when phase 2 fails

```math
\text{phase2Invalid}\land\text{totalChange}<0\land\text{designationValid}
\implies\text{Accepted}
```

Use both valid choices with an actual failing script: designate a TopTx output when it has a release share, and use `NoTopTxSettlement` when the SubTxs settle the complete release locally. The ordinary designation is validated before collateral-only execution.

<a id="ds-tx-settlement-participation-f03" name="ds-tx-settlement-participation-f03"></a>
<a id="ds-tx-settlement-designation-f03" name="ds-tx-settlement-designation-f03"></a>

###### 2.1.4.1.12 [F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/DesignationSpec.hs#L199) - Invalid designation when phase 2 fails

```math
\text{phase2Invalid}\land\text{totalChange}<0\land\neg\text{designationValid}
\implies\text{Rejected}
```

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
[Grammar](declarations.md#ds-tx-declarations-grammar); these tests check whether the indexed output
exists. [Output coin](#ds-tx-settlement-output-coin) checks the separate ADA bound.

<a id="ds-tx-settlement-destination-p01" name="ds-tx-settlement-destination-p01"></a>
<a id="ds-tx-settlement-output-index-p01" name="ds-tx-settlement-output-index-p01"></a>

###### 2.1.4.2.1 [P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L60) - The index belongs to the declaring body

```math
\begin{aligned}
&\text{outputCoins}\ge\text{requiredRelease} \\
&\implies(\text{indexValid(body,index)}\iff0\le\text{index}<|\text{ownOutputs(body)}|)
\end{aligned}
```

Generate ordinary output sequences, including an empty sequence. For TopTx and SubTx separately, compare the isolated validator with the sequence-length predicate at the first, last and out-of-range positions. Existing outputs have sufficient ADA, so only index membership can fail.

<a id="ds-tx-settlement-destination-f01" name="ds-tx-settlement-destination-f01"></a>
<a id="ds-tx-settlement-output-index-f01" name="ds-tx-settlement-output-index-f01"></a>

###### 2.1.4.2.2 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L77) - The first missing own index is rejected

```math
\text{index}=|\text{ownOutputs(body)}|
\implies\text{RejectedWith(InvalidSettlementOutput)}
```

Starting from a valid proposal, select the index immediately after the final output. Test TopTx and each SubTx separately, require the exact index failure, then accept the unchanged control.

<a id="ds-tx-settlement-destination-f02" name="ds-tx-settlement-destination-f02"></a>
<a id="ds-tx-settlement-output-index-f02" name="ds-tx-settlement-output-index-f02"></a>

###### 2.1.4.2.3 [F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L100) - A SubTx cannot select TopTx's output

```math
\begin{aligned}
&|\text{ownOutputs(subTx)}|\le\text{index}<|\text{ownOutputs(topTx)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(subTx))}
\end{aligned}
```

Give TopTx one more output than its SubTx. The child selects the index that exists only in TopTx. The ledger rejects the child’s target; the parent’s larger sequence cannot satisfy it.

<a id="ds-tx-settlement-destination-f03" name="ds-tx-settlement-destination-f03"></a>
<a id="ds-tx-settlement-output-index-f03" name="ds-tx-settlement-output-index-f03"></a>

###### 2.1.4.2.4 [F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L121) - Collateral return is outside the ordinary output sequence

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

###### 2.1.4.2.5 [F04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L142) - A SubTx without outputs cannot settle locally

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

###### 2.1.4.2.6 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L161) - The first and last own outputs are valid

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

###### 2.1.4.2.7 [F05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L175) - TopTx cannot select a SubTx's output

```math
\begin{aligned}
&|\text{ownOutputs(topTx)}|\le\text{index}<|\text{ownOutputs(subTx)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(topTx))}
\end{aligned}
```

Give a nested SubTx one more output than TopTx. The index exists in the child but not in TopTx, so a TopTx designation using it is rejected.

<a id="ds-tx-settlement-destination-f06" name="ds-tx-settlement-destination-f06"></a>
<a id="ds-tx-settlement-output-index-f06" name="ds-tx-settlement-output-index-f06"></a>

###### 2.1.4.2.8 [F06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L194) - A SubTx cannot select a sibling's output

```math
\begin{aligned}
&|\text{ownOutputs(subTx)}|\le\text{index}<|\text{ownOutputs(sibling)}| \\
&\implies\text{RejectedWith(InvalidSettlementOutput(subTx))}
\end{aligned}
```

Give the sibling one more output than the declaring SubTx. Both children release deposits, but each owns a separate output sequence. The declaring child cannot borrow the sibling’s longer sequence.

<a id="ds-tx-settlement-destination-n02" name="ds-tx-settlement-destination-n02"></a>
<a id="ds-tx-settlement-output-index-n02" name="ds-tx-settlement-output-index-n02"></a>

###### 2.1.4.2.9 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L215) - Valid output indices when phase 2 fails

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

###### 2.1.4.2.10 [F07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L229) - An invalid output index still fails when phase 2 fails

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

###### 2.1.4.2.11 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputIndexSpec.hs#L253) - A SubTx without outputs delegates its final release

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
<a id="ds-tx-settlement-output-coin" name="ds-tx-settlement-output-coin"></a>

##### 2.1.4.3 Output coin

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

###### 2.1.4.3.1 [P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L43) - Output ADA must cover the required share

```math
\text{passesOutputCoinValidation}
\iff\text{serializedADA(selectedOutput)}\ge\text{requiredSettlement(body)}
```

Compare the isolated output-coin validator with the independent lower-bound predicate. Generate exact amounts, surplus and shortfall for TopTx and SubTx, using both min-ADA and deposit-backed outputs. This equivalence concerns output coin only.

<a id="ds-tx-settlement-coverage-f01" name="ds-tx-settlement-coverage-f01"></a>
<a id="ds-tx-settlement-output-coin-f01" name="ds-tx-settlement-output-coin-f01"></a>

###### 2.1.4.3.2 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L56) - Min-ADA output, one lovelace short

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

###### 2.1.4.3.3 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L77) - Min-ADA output, exact amount

```math
\text{implicit(selectedOutput)}
\land\text{serializedADA(selectedOutput)}=\text{requiredSettlement(body)}
\implies\text{Accepted}
```

Exact equality is sufficient. Test the boundary for TopTx and for a SubTx settling locally.

<a id="ds-tx-settlement-coverage-n02" name="ds-tx-settlement-coverage-n02"></a>
<a id="ds-tx-settlement-output-coin-n02" name="ds-tx-settlement-output-coin-n02"></a>

###### 2.1.4.3.4 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L97) - Min-ADA output, extra ADA

```math
\text{implicit(selectedOutput)}
\land\text{serializedADA(selectedOutput)}>\text{requiredSettlement(body)}
\implies\text{Accepted}
```

The selected min-ADA output may contain additional ADA. Its coin value need not equal the required share.

<a id="ds-tx-settlement-coverage-f02" name="ds-tx-settlement-coverage-f02"></a>
<a id="ds-tx-settlement-output-coin-f02" name="ds-tx-settlement-output-coin-f02"></a>

###### 2.1.4.3.5 [F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L117) - An external deposit cannot fill the ADA shortfall

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

###### 2.1.4.3.6 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L140) - Deposit-backed output, exact application ADA

```math
\text{depositBacked(selectedOutput)}
\land\text{serializedADA(selectedOutput)}=\text{requiredSettlement(body)}
\implies\text{Accepted}
```

Allocate the external deposit independently and place exactly the required settlement amount in the output’s application ADA. The separate deposit does not increase or reduce the bound.

<a id="ds-tx-settlement-coverage-n04" name="ds-tx-settlement-coverage-n04"></a>
<a id="ds-tx-settlement-output-coin-n04" name="ds-tx-settlement-output-coin-n04"></a>

###### 2.1.4.3.7 [N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L161) - TopTx's share is smaller than the transaction release

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

###### 2.1.4.3.8 [N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L177) - Exact output ADA when phase 2 fails

```math
\text{phase2Invalid}
\land\text{serializedADA(selectedOutput)}=\text{requiredSettlement(body)}
\implies\text{Accepted}
```

Use a real failing script with exactly the required coin in the designated ordinary output. Its proposed output-coin check passes before the collateral outcome, although ordinary outputs are not applied.

<a id="ds-tx-settlement-coverage-f03" name="ds-tx-settlement-coverage-f03"></a>
<a id="ds-tx-settlement-output-coin-f03" name="ds-tx-settlement-output-coin-f03"></a>

###### 2.1.4.3.9 [F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L197) - One lovelace short when phase 2 fails

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

###### 2.1.4.3.10 [F04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Settlement/OutputCoinSpec.hs#L219) - The transaction release is smaller than TopTx's share

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

#### 2.1.5 Minimum coin

> **Both output forms use the active deposit formula; only the funding location differs.**

Let $`F_S`$ be the Store's current [deposit formula](#ds-pricing). For each proposed
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
[allocation declaration](declarations.md#ds-tx-declarations-requirements-operations-allocation),
[exact deposit accounting](#ds-tx-accounting-net-change-subtx), and other output constraints.

TopTx and SubTx validation read `currentFormula` from the Store, so the bound
changes after a V2 activation. The parameter-only `getMinCoinTxOut` and
`getMinCoinSizedTxOut` helpers use V1 at the supplied `coinsPerUTxOByte`; they
cannot select V2 without Store history. Builders needing the active bound use:

```haskell
toCoin $ Formula.computeDeposit (Store.currentFormula store) proposedMinAdaOutput
```

Here `Formula` is [`Dijkstra.UTxOs.Deposit.Formula`](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/Formula.hs).
Earlier eras retain their existing minimum-coin rules.

**Common premises:** valid addresses, nonnegative assets, exact declarations and fully
funded transactions. Each generated sample exercises both TopTx and SubTx outputs,
with successful phase 2 and with a real failing script. On the latter path,
**Accepted** means that the ledger accepts the collateral outcome; ordinary outputs
are checked but not created.

<a id="ds-tx-application-assets-n01" name="ds-tx-application-assets-n01"></a>
<a id="ds-tx-minimum-coin-n01" name="ds-tx-minimum-coin-n01"></a>

##### 2.1.5.1 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L47) - Native assets without ADA

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

##### 2.1.5.2 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L61) - Datum or reference script without assets

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

##### 2.1.5.3 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L75) - Address-only output

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

##### 2.1.5.4 [N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L89) - Exact minimum for a min-ADA output

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

##### 2.1.5.5 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L99) - Min-ADA output one lovelace short

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

### 2.2 Collateral

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

Applied allocation records and balances belong to [Ledger effects](#ds-state).
[Fees](#ds-state-fees) owns released-deposit surplus;
[Conservation](#ds-state-conservation) checks the resulting monetary total.

<a id="ds-collateral-existing-rules" name="ds-collateral-existing-rules"></a>
<a id="ds-collateral-scope" name="ds-collateral-scope"></a>
<a id="221-scope" name="221-scope"></a>
<a id="ds-collateral-authorization" name="ds-collateral-authorization"></a>
<a id="222-authorization" name="222-authorization"></a>

**Existing collateral rules**

The [Dijkstra Imp suite](../../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Imp.hs#L38)
inherits the [Conway](../../eras/conway/impl/testlib/Test/Cardano/Ledger/Conway/Imp.hs#L55),
[Babbage](../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp.hs#L36)
and [Alonzo](../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp.hs#L31)
suites. These are shared tests executed with Dijkstra, not tests to duplicate under
DepositStore. Their collateral fixtures use min-ADA outputs; Deposit-backed
integration remains a separate coverage obligation.

| Contract | Existing executable reference | Scope of that evidence |
| --- | --- | --- |
| Every collateral input resolves to an unspent output | Alonzo UTXO: [unknown input](../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxoSpec.hs#L47), [already spent](../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxoSpec.hs#L57) | Rejects bad references in Dijkstra too. |
| Collateral covers the fee percentage, even if scripts succeed | Alonzo UTXO: [insufficient collateral](../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxoSpec.hs#L92) | Existing percentage and ceiling rule; no external deposits. |
| Each collateral payment key supplies its witness | Alonzo UTXOW: [missing collateral witness](../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Imp/UtxowSpec/Invalid.hs#L205) | Missing witness for a min-ADA input. |
| A supplied total equals input coins minus return coins | Babbage UTXOS: [incorrect collateral total](../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp/UtxosSpec.hs#L155) | Mismatch rejected with successful scripts; min-ADA return. |
| Phase-2 failure can return collateral without a supplied total | Babbage UTXOW: [use a collateral output](../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp/UtxowSpec/Invalid.hs#L125) | Accepted failure-path min-ADA return; omission is incidental coverage. |
| Return-output validity is checked without redeemers | Dijkstra UTXO: [pointer address in collateral return](../../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Imp/UtxoSpec.hs#L54) | Rejects an invalid address; does not cover the minimum-coin or input-count boundaries. |

These links establish test ownership and registration, not a new passing run.
`disableInConformanceIt` retains the implementation check while disabling its
[conformance comparison](../../eras/shelley/impl/testlib/Test/Cardano/Ledger/Shelley/ImpTest.hs#L852).
Recorded executions remain in the [verification record](verification.md).

The shared trigger is (`subTxRedeemers` is the union of all children’s redeemers):

```math
\left(\mathit{topTxRedeemers}\ne\varnothing\ \lor\ \mathit{subTxRedeemers}\ne\varnothing\right)
\implies \mathit{collateralInputs}\ne\varnothing
```

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
| <a id="ds-collateral-scope-f01" name="ds-collateral-scope-f01"></a><a id="2211-f01---rejects-toptx-redeemers-without-collateral" name="2211-f01---rejects-toptx-redeemers-without-collateral"></a>TopTx alone has redeemers $`\implies`$ collateral is required. | A real, correctly witnessed TopTx script without collateral must produce `NoCollateralInputs`; include a funded control and both script outcomes. Empty collateral may also produce a funding failure. |
| <a id="ds-collateral-scope-f02" name="ds-collateral-scope-f02"></a><a id="2212-f02---rejects-subtx-redeemers-without-collateral-even-when-toptx-has-none" name="2212-f02---rejects-subtx-redeemers-without-collateral-even-when-toptx-has-none"></a>Only a SubTx has redeemers $`\implies`$ shared collateral is required. | Use a correctly indexed child redeemer with no parent redeemers; require `NoCollateralInputs`, with a funded control and both script outcomes. |
| <a id="ds-collateral-scope-f03" name="ds-collateral-scope-f03"></a><a id="2213-f03---rejects-redeemers-in-both-toptx-and-subtxs-without-collateral" name="2213-f03---rejects-redeemers-in-both-toptx-and-subtxs-without-collateral"></a>Both levels have redeemers $`\implies`$ shared collateral is required. | The combined case must also produce `NoCollateralInputs`; having both locations cannot cancel the trigger. |
| <a id="ds-collateral-scope-n02" name="ds-collateral-scope-n02"></a><a id="2215-n02---does-not-apply-redeemer-gated-funding-or-supplied-total-checks-when-no-body-has-redeemers" name="2215-n02---does-not-apply-redeemer-gated-funding-or-supplied-total-checks-when-no-body-has-redeemers"></a>No body has redeemers $`\implies`$ skip gated funding and supplied-total comparisons. | Supply resolved inputs and a valid return; independently underfund the potential fee, mismatch the total, then combine both. Other rules still hold; ordinary acceptance is expected. |
| <a id="ds-collateral-scope-f04" name="ds-collateral-scope-f04"></a><a id="2216-f04---rejects-independently-invalid-collateral-inputs-or-returns-without-redeemers" name="2216-f04---rejects-independently-invalid-collateral-inputs-or-returns-without-redeemers"></a>No redeemers does not waive independent input, return or count checks. | Unknown-input coverage exists above. Add a min-ADA return one lovelace below minimum and too many collateral inputs, each with a valid control. |
| <a id="ds-collateral-authorization-f01" name="ds-collateral-authorization-f01"></a><a id="2221-f01---rejects-a-script-controlled-collateral-input-when-collateral-validation-applies" name="2221-f01---rejects-a-script-controlled-collateral-input-when-collateral-validation-applies"></a>Active collateral validation $`\implies`$ inputs are key-locked. | Reject script-controlled collateral with `ScriptsNotPaidUTxO` for both output forms and script outcomes, even with a valid script witness. Use that script for an ordinary purpose too, so its witness is not extraneous. The control uses a signed key-controlled input. |
| <a id="ds-collateral-authorization-f02" name="ds-collateral-authorization-f02"></a><a id="2222-f02---rejects-a-key-controlled-collateral-input-whose-required-payment-key-witness-is-missing" name="2222-f02---rejects-a-key-controlled-collateral-input-whose-required-payment-key-witness-is-missing"></a>Every collateral payment key must witness the transaction. | Extend the existing witness case to Deposit-backed inputs, both script outcomes and the no-redeemer path. Remove only a collateral key witness that no ordinary input needs; restoring it must accept. |

<a id="ds-collateral-scope-n01" name="ds-collateral-scope-n01"></a><a id="2214-n01---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore" name="2214-n01---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore"></a><a id="ds-collateral-funding-n09" name="ds-collateral-funding-n09"></a><a id="22116-n09---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore" name="22116-n09---does-not-require-collateral-merely-because-a-transaction-uses-the-depositstore"></a><a id="ds-collateral-store-activity-control" name="ds-collateral-store-activity-control"></a>

The successful path of [Minimum coin N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/MinimumCoinSpec.hs#L75)
already accepts an address-only Deposit-backed output with its allocation declared.
It is the existing control for Store activity without redeemers. **Remaining
extension:** explicitly assert empty redeemers and empty collateral inputs in that
prepared transaction; acceptance alone does not prove both fields are absent.
Deposit-backed fixture extensions should reuse the shared rule cases. The existing Babbage
[return fixup](../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/ImpTest.hs#L92)
currently rejects `DepositBackedTxOut`, so inherited implicit fixtures do not supply
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
| <a id="2232-n01---accepts-a-batch-whose-scripts-succeed-when-its-required-collateral-is-fully-funded-and-all-other-rules-hold" name="2232-n01---accepts-a-batch-whose-scripts-succeed-when-its-required-collateral-is-fully-funded-and-all-other-rules-hold"></a><a id="ds-collateral-funding-n01" name="ds-collateral-funding-n01"></a><a id="2212-n01---accepts-a-fully-funded-store-backed-return-when-all-scripts-succeed" name="2212-n01---accepts-a-fully-funded-store-backed-return-when-all-scripts-succeed"></a><a id="2233-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns" name="2233-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns"></a><a id="ds-collateral-funding-n02" name="ds-collateral-funding-n02"></a><a id="2213-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns" name="2213-n02---accepts-funded-collateral-with-implicit-or-store-backed-inputs-and-returns"></a><a id="2234-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount" name="2234-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount"></a><a id="ds-collateral-funding-n03" name="ds-collateral-funding-n03"></a><a id="2214-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount" name="2214-n03---reuses-released-utxo-capacity-deposits-when-the-collateral-return-requires-the-same-amount"></a><a id="2235-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins" name="2235-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins"></a><a id="ds-collateral-funding-n04" name="ds-collateral-funding-n04"></a><a id="2215-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins" name="2215-n04---funds-additional-return-utxo-capacity-deposits-from-collateral-coins"></a><a id="2237-p01---collateral-coins-cover-the-minimum" name="2237-p01---collateral-coins-cover-the-minimum"></a><a id="ds-collateral-funding-p01" name="ds-collateral-funding-p01"></a><a id="2217-p01---collateral-coins-cover-the-minimum" name="2217-p01---collateral-coins-cover-the-minimum"></a><a id="22311-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs" name="22311-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs"></a><a id="ds-collateral-funding-n05" name="ds-collateral-funding-n05"></a><a id="22111-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs" name="22111-n05---counts-implicit-collateral-inputs-full-ada-as-coins-and-zero-released-store-deposits-when-mixed-with-store-backed-inputs"></a><a id="22312-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs" name="22312-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs"></a><a id="ds-collateral-funding-n06" name="ds-collateral-funding-n06"></a><a id="22112-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs" name="22112-n06---requires-zero-store-deposit-for-an-implicit-collateral-return-even-with-store-backed-collateral-inputs"></a><a id="22313-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded" name="22313-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded"></a><a id="ds-collateral-funding-n07" name="ds-collateral-funding-n07"></a><a id="22113-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded" name="22113-n07---accepts-a-store-backed-collateral-return-with-zero-application-ada-when-its-deposit-and-the-minimum-fee-are-funded"></a><a id="22315-n08---accepts-collateral-funding-exactly-at-a-rounded-up-minimum-fee" name="22315-n08---accepts-collateral-funding-exactly-at-a-rounded-up-minimum-fee"></a><a id="ds-collateral-funding-n08" name="ds-collateral-funding-n08"></a><a id="22115-n08---accepts-the-exact-rounded-up-minimum-fee-after-funding-the-returns-additional-deposit" name="22115-n08---accepts-the-exact-rounded-up-minimum-fee-after-funding-the-returns-additional-deposit"></a><a id="ds-collateral-settlement-n01" name="ds-collateral-settlement-n01"></a><a id="2261-n01---derives-store-changes-from-collateral-inputs-and-return-without-a-separate-declaration" name="2261-n01---derives-store-changes-from-collateral-inputs-and-return-without-a-separate-declaration"></a><a id="ds-collateral-funding-n10" name="ds-collateral-funding-n10"></a><a id="22117-n10---derives-deposit-funding-from-collateral-inputs-and-return-without-a-separate-declaration" name="22117-n10---derives-deposit-funding-from-collateral-inputs-and-return-without-a-separate-declaration"></a><a id="ds-collateral-settlement-n02" name="ds-collateral-settlement-n02"></a><a id="2263-n02---derives-the-released-store-amount-from-multiple-ada-only-collateral-inputs-with-no-return" name="2263-n02---derives-the-released-store-amount-from-multiple-ada-only-collateral-inputs-with-no-return"></a><a id="ds-collateral-funding-n11" name="ds-collateral-funding-n11"></a><a id="22119-n11---derives-released-deposits-from-mixed-ada-only-collateral-inputs-with-no-return" name="22119-n11---derives-released-deposits-from-mixed-ada-only-collateral-inputs-with-no-return"></a>**1.&nbsp;[N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L56)** | **Funded collateral.** Cover the return, any positive deposit shortfall and the rounded-up minimum; include exact equality. | Accept with successful scripts or an accepted phase-2 failure. |
| <a id="2231-f01---rejects-insufficient-collateral-funding-when-redeemers-trigger-validation-even-if-all-scripts-succeed" name="2231-f01---rejects-insufficient-collateral-funding-when-redeemers-trigger-validation-even-if-all-scripts-succeed"></a><a id="ds-collateral-funding-f01" name="ds-collateral-funding-f01"></a><a id="2211-f01---rejects-an-underfunded-store-backed-return-even-when-all-scripts-succeed" name="2211-f01---rejects-an-underfunded-store-backed-return-even-when-all-scripts-succeed"></a><a id="2236-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits" name="2236-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits"></a><a id="ds-collateral-funding-f02" name="ds-collateral-funding-f02"></a><a id="2216-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits" name="2216-f02---rejects-collateral-coins-below-the-minimum-fee-after-funding-the-return-and-additional-utxo-capacity-deposits"></a><a id="2238-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus" name="2238-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="ds-collateral-funding-f03" name="ds-collateral-funding-f03"></a><a id="2218-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus" name="2218-f03---rejects-collateral-whose-minimum-fee-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="2239-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus" name="2239-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="ds-collateral-funding-f04" name="ds-collateral-funding-f04"></a><a id="2219-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus" name="2219-f04---rejects-a-collateral-return-whose-funding-depends-on-released-utxo-capacity-deposit-surplus"></a><a id="22310-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee" name="22310-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee"></a><a id="ds-collateral-funding-f05" name="ds-collateral-funding-f05"></a><a id="22110-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee" name="22110-f05---rejects-collateral-funding-one-lovelace-below-a-rounded-up-minimum-fee"></a><a id="22314-f06---rejects-underfunded-collateral-when-the-optional-total-is-absent" name="22314-f06---rejects-underfunded-collateral-when-the-optional-total-is-absent"></a><a id="ds-collateral-funding-f06" name="ds-collateral-funding-f06"></a><a id="22114-f06---rejects-an-underfunded-store-backed-return-when-the-optional-total-is-absent" name="22114-f06---rejects-an-underfunded-store-backed-return-when-the-optional-total-is-absent"></a>**2.&nbsp;[F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L78)** | **Underfunded collateral.** Set the coin fee below the minimum, including one lovelace below the ceiling, an absent total, an oversized return and no-return Store inputs carrying zero application ADA. | Reject only with `InsufficientCollateral`; funded controls accept. |
| <a id="ds-collateral-settlement-p01" name="ds-collateral-settlement-p01"></a><a id="2262-p01---derived-collateral-store-change-is-independent-of-ordinary-store-declarations" name="2262-p01---derived-collateral-store-change-is-independent-of-ordinary-store-declarations"></a><a id="ds-collateral-funding-p02" name="ds-collateral-funding-p02"></a><a id="22118-p02---ordinary-declarations-do-not-change-collateral-deposit-funding" name="22118-p02---ordinary-declarations-do-not-change-collateral-deposit-funding"></a>**3.&nbsp;[P02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L128)** | **Independent ordinary declarations.** Keep collateral inputs, return, fee and prices fixed; vary ordinary declaration forms in the isolated calculation. | The released deposits, return deposit and additional funding stay unchanged. |
| <a id="ds-collateral-funding-p03" name="ds-collateral-funding-p03"></a>**4.&nbsp;[P03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/FundingSpec.hs#L152)** | **Min-ADA return at the active minimum.** Activate V1 or V2 after funding the collateral input. Vary the return's inline datum size; preserve the input's historical release and re-sign each proposal. | Exact current-formula ADA accepts; one lovelace below rejects only with `BabbageOutputTooSmallUTxO`. |

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

#### 2.2.2 Total

> **The optional total describes coins taken from collateral.**
>
> It includes coins funding an additional deposit and excludes deposits released from the Store.

The inherited [incorrect-total test](../../eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Imp/UtxosSpec.hs#L155)
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
| <a id="2251-n01---accepts-a-declared-total-equal-to-collateral-input-coins-minus-return-coins" name="2251-n01---accepts-a-declared-total-equal-to-collateral-input-coins-minus-return-coins"></a><a id="ds-collateral-total-n01" name="ds-collateral-total-n01"></a><a id="2221-n01---accepts-input-coins-minus-return-coins-as-the-total-with-store-allocations-or-releases" name="2221-n01---accepts-input-coins-minus-return-coins-as-the-total-with-store-allocations-or-releases"></a><a id="2254-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total" name="2254-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total"></a><a id="ds-collateral-total-n02" name="ds-collateral-total-n02"></a><a id="2224-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total" name="2224-n02---includes-coins-funding-additional-utxo-capacity-deposits-in-the-declared-total"></a><a id="2255-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total" name="2255-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total"></a><a id="ds-collateral-total-n03" name="ds-collateral-total-n03"></a><a id="2225-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total" name="2225-n03---excludes-utxo-capacity-deposits-released-from-the-store-from-the-declared-total"></a><a id="2256-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold" name="2256-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold"></a><a id="ds-collateral-total-n04" name="ds-collateral-total-n04"></a><a id="2226-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold" name="2226-n04---accepts-an-absent-optional-total-when-collateral-validation-applies-and-all-collateral-rules-hold"></a>**1.&nbsp;[N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L31)** | **Absent or exact total.** Omit the field or supply input coins minus return coins, with additional deposit funding, released surplus or no return. | Accept for either script outcome; absence skips only the comparison. |
| <a id="2252-f01---rejects-a-declared-total-differing-by-one-lovelace-when-collateral-validation-applies" name="2252-f01---rejects-a-declared-total-differing-by-one-lovelace-when-collateral-validation-applies"></a><a id="ds-collateral-total-f01" name="ds-collateral-total-f01"></a><a id="2222-f01---rejects-a-total-differing-by-one-lovelace-with-store-allocations-or-releases" name="2222-f01---rejects-a-total-differing-by-one-lovelace-with-store-allocations-or-releases"></a><a id="2253-f02---rejects-an-incorrect-supplied-total-when-redeemers-trigger-collateral-validation-even-if-all-scripts-succeed" name="2253-f02---rejects-an-incorrect-supplied-total-when-redeemers-trigger-collateral-validation-even-if-all-scripts-succeed"></a><a id="ds-collateral-total-f02" name="ds-collateral-total-f02"></a><a id="2223-f02---rejects-an-incorrect-total-with-store-allocations-or-releases-even-when-all-scripts-succeed" name="2223-f02---rejects-an-incorrect-total-with-store-allocations-or-releases-even-when-all-scripts-succeed"></a>**2.&nbsp;[F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/TotalSpec.hs#L43)** | **Incorrect total.** Supply a total one lovelace above or below the expected value while keeping Store funding correct. | Reject only with `IncorrectTotalCollateralField`, even when scripts succeed; the exact-total control accepts. |

Absence is distinct from a supplied zero: zero is valid only when it equals the expected total. [Funding F01](#ds-collateral-funding-f01) independently rejects a funding deficit when the field is absent.

<a id="ds-collateral-assets" name="ds-collateral-assets"></a>

#### 2.2.3 Assets

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
[`validateCollateralAssets`](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/DepositStore/Collateral.hs)
with a Deposit-backed input or return, including mixed inputs and both return forms.
Funding, output validity, witnesses and optional totals remain correct. Exercise
successful scripts and genuine phase-2 failure. The current generator mints one
policy and one token name, with a variable quantity repeated across the selected
inputs. Mixed-policy or distinct-token input maps remain an extension.

| Case | Scenario | Expected result |
| --- | --- | --- |
| <a id="ds-collateral-conservation-n02" name="ds-collateral-conservation-n02"></a><a id="2274-n02---accepts-native-asset-collateral-when-its-return-preserves-every-asset-and-quantity" name="2274-n02---accepts-native-asset-collateral-when-its-return-preserves-every-asset-and-quantity"></a><a id="ds-collateral-assets-n01" name="ds-collateral-assets-n01"></a><a id="2232-n01---accepts-matching-native-assets-when-collateral-inputs-or-return-are-store-backed" name="2232-n01---accepts-matching-native-assets-when-collateral-inputs-or-return-are-store-backed"></a>**1.&nbsp;[N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AssetsSpec.hs#L35)** | **Exact asset map.** Return every input policy, asset name and quantity; include a funded Deposit-backed return with zero application ADA. | Accept for both output forms and script outcomes. |
| <a id="ds-collateral-conservation-f01" name="ds-collateral-conservation-f01"></a><a id="2273-f01---rejects-missing-added-or-changed-native-assets-in-the-collateral-return" name="2273-f01---rejects-missing-added-or-changed-native-assets-in-the-collateral-return"></a><a id="ds-collateral-assets-f01" name="ds-collateral-assets-f01"></a><a id="2231-f01---rejects-missing-added-or-changed-native-assets-when-collateral-inputs-or-return-are-store-backed" name="2231-f01---rejects-missing-added-or-changed-native-assets-when-collateral-inputs-or-return-are-store-backed"></a><a id="ds-collateral-conservation-f02" name="ds-collateral-conservation-f02"></a><a id="2275-f02---rejects-token-bearing-collateral-when-no-return-is-specified" name="2275-f02---rejects-token-bearing-collateral-when-no-return-is-specified"></a><a id="ds-collateral-assets-f02" name="ds-collateral-assets-f02"></a><a id="2233-f02---rejects-token-bearing-store-backed-collateral-when-no-return-is-specified" name="2233-f02---rejects-token-bearing-store-backed-collateral-when-no-return-is-specified"></a>**2.&nbsp;[F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Collateral/AssetsSpec.hs#L48)** | **Missing or altered assets.** Remove an asset, add an absent asset, alter a quantity, or omit the return for token-bearing collateral. | Reject only with `CollateralContainsNonADA`; the unchanged asset-map control accepts. |

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
| [Store / Allocations](#ds-state-allocations) | Exact allocation map for live Deposit-backed outputs. |
| [Store / Balance](#ds-state-balance) | Change in the sum of recorded deposits. |
| [Fees](#ds-state-fees) | Fee credit and unchanged treasury. |
| [Conservation](#ds-state-conservation) | Correct ADA total and its preservation. |
| [Lifecycle](#ds-state-lifecycle) | Era translation and ordinary epoch boundaries. |

The accepted outcome selects the inputs and outputs used by all these observations:

| Outcome | $`\mathit{consumedInputs}`$ | $`\mathit{createdOutputs}`$ |
| --- | --- | --- |
| Ordinary success | Ordinary inputs of TopTx and every SubTx. | Their signed ordinary outputs, each under its own body's identifier and output index. |
| Accepted phase-2 failure | Collateral inputs. | The signed collateral return, when present. |

Settlement ADA is already included in the signed output. Reference-only and
unrelated inputs remain unchanged; an input used in both consuming roles is
consumed once through the selected path. Tests assert acceptance before checking
these effects. Executed counts and timings belong to the [verification record](verification.md).

<a id="ds-state-execution" name="ds-state-execution"></a><a id="ds-state-utxo" name="ds-state-utxo"></a>

### 3.1 UTxO

> **Apply exactly the selected inputs and signed outputs.**

```math
\mathit{utxoAfter}
=(\mathit{utxoBefore}\setminus\mathit{consumedInputs})
\cup\mathit{createdOutputs}
```

Here, subtraction removes map entries by input reference; union inserts the
selected outputs without changing their payloads.

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-utxo-n01" name="ds-state-utxo-n01"></a>**1.&nbsp;[N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L34)** | **Ordinary execution.** Standalone and multi-SubTx transactions allocate, release or replace deposits. Compare the entire resulting UTxO with the ordinary-input/output equation. |
| <a id="ds-state-utxo-n02" name="ds-state-utxo-n02"></a>**2.&nbsp;[N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L48)** | **Successful scripts leave collateral inactive.** Generate collateral proposals with absent, implicit or Deposit-backed returns. Only ordinary outputs are created; collateral-only and reference-only inputs survive. |
| <a id="ds-state-utxo-n03" name="ds-state-utxo-n03"></a>**3.&nbsp;[N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L62)** | **Failed scripts select collateral.** Submit a genuine phase-2 failure. Only collateral inputs disappear and only the collateral return is created; ordinary and reference-only inputs survive. |
| <a id="ds-state-utxo-n04" name="ds-state-utxo-n04"></a>**4.&nbsp;[N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L77)** | **Failed TopTx, inactive SubTxs.** A real failing TopTx script selects collateral even when several children propose allocations and releases. Compare the complete UTxO: none of those ordinary effects is applied. |
| <a id="ds-state-utxo-n05" name="ds-state-utxo-n05"></a>**5.&nbsp;[N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs#L95)** | **One input, two consuming roles.** A Deposit-backed input belongs to both ordinary and collateral sets. Exercise both actual script outcomes and compare the complete UTxO against the selected path; consume the shared input once. |

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

`UTxOStore` owns `depositFormulaHistory`, one indexed map of `Unspent (TxOut era)` and a
checked cached `totalDepositAmount`. Each entry retains its output and allocation origin (`AtStoreMigration` or `AtSlot slot`). History resolves its
formula as described in [DepositStore](#section-1-1). Output references and
allocations share one map; the cached total counts only separately held ADA.

<a id="ds-state-allocations" name="ds-state-allocations"></a><a id="ds-state-store-allocations" name="ds-state-store-allocations"></a>

<a id="ds-state-allocations-n04" name="ds-state-allocations-n04"></a><a id="ds-state-allocations-n05" name="ds-state-allocations-n05"></a><a id="ds-state-allocations-n02" name="ds-state-allocations-n02"></a><a id="ds-state-allocations-n03" name="ds-state-allocations-n03"></a><a id="ds-state-allocations-n06" name="ds-state-allocations-n06"></a><a id="ds-state-allocations-n07" name="ds-state-allocations-n07"></a><a id="ds-state-allocations-n08" name="ds-state-allocations-n08"></a>

#### 3.2.1 Allocations

> **Retain one allocation for each live Deposit-backed output.**

Here, $`\mathit{recordsBefore}`$ is mathematical notation for the deposits calculated from retained creation-time metadata, not a separate ledger type or stored map. The owning allocation map also contains min-ADA outputs, whose external deposit is zero.
Construct $`\mathit{newAllocations}`$ only for Deposit-backed outputs in
$`\mathit{createdOutputs}`$, priced from their contents and allocation-time formulas under
[Deposit calculation](#ds-pricing). Min-ADA outputs have no external-deposit record in this view; their legacy allocations remain in the owning map. A Deposit-backed output priced at zero still has a deposit record. For either accepted outcome:

```math
\begin{aligned}
\mathit{recordsAfter}
&=(\mathit{recordsBefore}\setminus\mathit{consumedInputs})
  \cup\mathit{newAllocations} \\
\mathit{keys}(\mathit{recordsAfter})
&=\{\,\mathit{outputRef}\mid\mathit{utxoAfter}[\mathit{outputRef}]\text{ is Deposit-backed}\,\} \\
\mathit{recordsAfter}[\mathit{outputRef}]&\geq0
\quad\text{for every recorded }\mathit{outputRef}
\end{aligned}
```

Compare the actual map with this independently constructed map, and its domain
with the actual resulting UTxO. Equality between two sums of the same unchecked
map would miss missing, misplaced or incorrectly priced records. A consistent
starting state has this exact domain and nonnegative recorded amounts.
[Balance](#ds-state-balance) checks the resulting ADA change against independently
calculated allocations and retained releases.

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-allocations-p01" name="ds-state-allocations-p01"></a>**1.&nbsp;[P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L75)** | **Ordinary records.** Derive records from signed Deposit-backed outputs, remove consumed references, then compare the complete map and its domain with the resulting UTxO. Cover local and delegated multi-SubTx activity and equal-valued outputs at distinct references. |
| <a id="ds-state-allocations-p02" name="ds-state-allocations-p02"></a>**2.&nbsp;[P02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L96)** | **Collateral records.** Generate mixed input forms and absent, implicit or Deposit-backed returns. Real script success removes only ordinary records, including shared ordinary/collateral inputs. Real failure removes only collateral records and adds the Deposit-backed return; reference-only records survive. |
| <a id="ds-state-allocations-p03" name="ds-state-allocations-p03"></a>**3.&nbsp;[P03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L121)** | **Restore the historical deposit.** Submit a noncanonical CBOR output whose accepted encoding is one byte longer than its canonical encoding. Restore the serialized state, activate V2 and double the byte price, then reference the output: its payload, allocation origin and V1 deposit are unchanged. Spending it removes precisely that record. |
| <a id="ds-state-allocations-n01" name="ds-state-allocations-n01"></a>**4.&nbsp;[N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L166)** | **Zero-priced allocations still have records.** Spend translated min-ADA sources and create Deposit-backed outputs in TopTx and SubTx at a zero byte price. Record each new reference with amount zero; min-ADA sources never acquire allocation records. |
| <a id="ds-state-allocations-p04" name="ds-state-allocations-p04"></a>**5.&nbsp;[P04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs#L190)** | **No ordinary records on failure.** A real failing TopTx script has several children proposing Store allocations and releases. With implicit-only collateral, the entire allocation map remains unchanged. |

Historical release **amounts** are checked separately by [Balance P03](#ds-state-balance-p03).

<a id="ds-state-balance" name="ds-state-balance"></a><a id="ds-state-store-balance" name="ds-state-store-balance"></a>

#### 3.2.2 Balance

> **The Store balance changes by newly allocated deposits minus recorded releases.**

Derive the transfer from new allocations and retained consumed records:

```math
\begin{aligned}
\mathit{releasedDeposits}
&=\sum_{\mathit{input}\in\mathit{consumedInputs}\cap\mathit{keys}(\mathit{recordsBefore})}
  \mathit{recordsBefore}[\mathit{input}] \\
\mathit{storeBalanceAfter}
&=\mathit{storeBalanceBefore}+\sum\mathit{newAllocations}
  -\mathit{releasedDeposits}
\end{aligned}
```

On ordinary success, the Store balance changes by the actual external deposits
created minus those consumed, across TopTx and all SubTxs. Embedded reserves
enter the signed declaration and travel in serialized output values. On accepted
phase-2 failure, only collateral allocations and releases affect the Store.

<a id="ds-state-balance-n02" name="ds-state-balance-n02"></a>
For every Store, its cached balance must equal the sum calculated from its historical records:

```math
\mathit{storeBalance}=\sum\mathit{records}
```

The transfer assertion compares the observed amount with independently calculated
allocations and releases. Separate assertions recompute the total from each output’s
asset count, datum and script, using the version and rate selected by its origin.
[Historical pricing](#ds-pricing-history) keeps the original refund for each allocation.

<a id="ds-state-balance-n01" name="ds-state-balance-n01"></a><a id="ds-state-balance-n03" name="ds-state-balance-n03"></a>

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-balance-p01" name="ds-state-balance-p01"></a>**1.&nbsp;[P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L61)** | **Ordinary transfer.** Measure new deposits from signed outputs and releases from the consumed records. The sum of the resulting records changes by their difference, including multi-SubTx local/delegated funding and zero net replacement. |
| <a id="ds-state-balance-p02" name="ds-state-balance-p02"></a>**2.&nbsp;[P02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L82)** | **Collateral transfer.** Successful scripts release only ordinary records, including inputs shared with collateral. Failed scripts apply only the return deposit minus recorded collateral releases; deposits of all unspent outputs remain recorded. |
| <a id="ds-state-balance-p03" name="ds-state-balance-p03"></a>**3.&nbsp;[P03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L103)** | **Historical release after restoration.** Create an allocation from genuinely noncanonical accepted bytes, restore the state and change the price. Spending the output reduces the Store by the original allocation, not a newly calculated deposit. |
| <a id="ds-state-balance-p04" name="ds-state-balance-p04"></a>**4.&nbsp;[P04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L127)** | **No ordinary transfer on failure.** The same failing-parent, multi-SubTx scenarios use implicit-only collateral. The Store balance remains unchanged despite their ordinary declarations. |
| <a id="ds-state-balance-p05" name="ds-state-balance-p05"></a>**5.&nbsp;[P05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L141)** | **Mixed historical prices.** Accept two noncanonical outputs at different prices, restore their state and consume both while creating a replacement at a third price. The balance changes by the current new deposit minus both historical deposits. Retained metadata and cache totals are checked independently. |
| <a id="ds-state-balance-p06" name="ds-state-balance-p06"></a>**6.&nbsp;[P06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L175)** | **Child output history.** Accept a noncanonical SubTx output, restore its allocation and change the price. A later spend of the child's own reference releases exactly its original contribution. |
| <a id="ds-state-balance-p07" name="ds-state-balance-p07"></a>**7.&nbsp;[P07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L198)** | **Collateral-return history.** Accept a real script failure with a noncanonical Deposit-backed return. Restore that applied allocation, change the price and spend the return; its contents and allocation-time formula determine the refund. |
| <a id="ds-state-balance-p08" name="ds-state-balance-p08"></a>**8.&nbsp;[P08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs#L227)** | **Across formula versions.** Accept identical two-asset outputs before and after V2 activation, restore the state and spend both together. Each refunds its allocation-time formula: $`\text{refund}=F_{1,p}(o)+F_{2,p}(o)`$. |

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

```math
\begin{aligned}
\mathit{additionalDeposit}&=\max(0,\mathit{returnDeposit}-\mathit{releasedDeposits})\\
\mathit{releasedSurplus}&=\max(0,\mathit{releasedDeposits}-\mathit{returnDeposit})\\
\mathit{collateralCoinFee}&=\mathit{inputCoins}-\mathit{returnCoins}-\mathit{additionalDeposit}
\end{aligned}
```

| Accepted outcome | $`\mathit{feesAfter}-\mathit{feesBefore}`$ |
| --- | --- |
| Ordinary success | $`\mathit{txFee}`$ |
| Phase-2 failure | $`\mathit{collateralCoinFee}+\mathit{releasedSurplus}`$ |

Both paths preserve the treasury:
$`\mathit{treasuryAfter}=\mathit{treasuryBefore}`$.

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-fees-p01" name="ds-state-fees-p01"></a>**1.&nbsp;[P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs#L29)** | **Ordinary fee.** Local and delegated ordinary Store operations, plus real successful scripts with collateral proposals, credit only the declared transaction fee. |
| <a id="ds-state-fees-p02" name="ds-state-fees-p02"></a>**2.&nbsp;[P02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs#L53)** | **Collateral fee.** Real failing scripts credit the application-coin fee plus unused recorded deposits. Cover absent returns, mixed inputs, deposit shortfall/equality/surplus and a changed byte price. |

The input/return funding constraints belong to [Funding](#ds-collateral-funding).
[Allocations](#ds-state-allocations) and [Balance](#ds-state-balance) observe the
corresponding Store effects; these fee tests observe only fees and treasury.

<a id="ds-state-conservation" name="ds-state-conservation"></a><a id="35-conservation" name="35-conservation"></a>

### 3.4 Conservation

> **Count every actual ADA pot, including the whole Store balance, exactly once.**

Start from a valid ledger state and submit an accepted transaction. Read each
actual pot independently from the observed state. Min-ADA outputs
contribute their full coin; Deposit-backed outputs contribute application coin.
The deposited pot is `utxosDeposited`, backing certificate/governance deposits.
Sum allocation records once as `storeBalance`; do not add their total a second time.

```math
\begin{aligned}
\mathit{actualAda}
&=\mathit{outputAda}+\mathit{storeBalance}+\mathit{fees}
  +\mathit{deposited}\\
&\quad+\mathit{rewards}+\mathit{treasury}+\mathit{reserves}
  +\mathit{donations}
\end{aligned}
```

```math
\begin{aligned}
\mathit{actualAdaAfter}&=\mathit{actualAdaBefore} \\
\mathit{totalAdaES}(\mathit{state})+\mathit{donations}(\mathit{state})&=\mathit{actualAda}(\mathit{state})
\quad\text{for }\mathit{state}\in\{\mathit{before},\mathit{after}\}
\end{aligned}
```

The second equation checks the [production total](../../eras/shelley/impl/src/Cardano/Ledger/Shelley/AdaPots.hs#L99)
against the independent sum: `totalAdaES` includes Store balance but excludes the
donation pot. Its certificate/governance obligation projection agrees with the
deposited pot in a consistent valid state. Use positive recorded deposits so the
comparison detects either omission or double counting of Store ADA, and nonzero
donations so that pot cannot be silently omitted.

<a id="ds-collateral-conservation" name="ds-collateral-conservation"></a><a id="227-conservation" name="227-conservation"></a><a id="ds-collateral-conservation-n01" name="ds-collateral-conservation-n01"></a><a id="2271-n01---conserves-ada-for-mixed-collateral-inputs-when-return-storage-needs-an-additional-deposit" name="2271-n01---conserves-ada-for-mixed-collateral-inputs-when-return-storage-needs-an-additional-deposit"></a><a id="ds-collateral-conservation-p01" name="ds-collateral-conservation-p01"></a><a id="2272-p01---collateral-settlement-conserves-ada" name="2272-p01---collateral-settlement-conserves-ada"></a><a id="351-n01---still-counts-store-ada-in-total-monetary-conservation" name="351-n01---still-counts-store-ada-in-total-monetary-conservation"></a>

| Case | Scenario and observation |
| --- | --- |
| <a id="ds-state-conservation-n01" name="ds-state-conservation-n01"></a>**1.&nbsp;[N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L38)** | **Count actual ADA once.** Use positive allocation records and nonzero donations. Before and after an accepted transaction, compare the production total plus donations with the independent sum of actual pots. |
| <a id="ds-state-conservation-n02" name="ds-state-conservation-n02"></a>**2.&nbsp;[N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L60)** | **Ordinary conservation.** Compare independent actual-ADA sums immediately before and after accepted standalone and multi-SubTx transactions, with local or delegated funding. |
| <a id="ds-state-conservation-n03" name="ds-state-conservation-n03"></a>**3.&nbsp;[N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs#L72)** | **Collateral conservation.** Repeat that comparison around real accepted phase-2 failures: mixed inputs, absent returns, and return deposits smaller than, equal to or greater than the recorded releases. |

For collateral, the same accounting projects to
$`\mathit{collateralInputCoins}+\mathit{releasedDeposits} =\mathit{returnCoins}+\mathit{returnDeposit}+\mathit{collateralFee}`$.
Its funding prerequisites belong to [Funding](#ds-collateral-funding); this
contract observes the actual applied state.

<a id="ds-state-lifecycle" name="ds-state-lifecycle"></a>

### 3.5 Lifecycle

Translation establishes legacy allocations with zero external deposits. Ordinary epoch processing preserves an
existing allocation map and therefore its derived balance. Effective parameter changes
update only the formula for future allocations.

<a id="ds-state-initialization" name="ds-state-initialization"></a><a id="36-initialization" name="36-initialization"></a><a id="ds-state-translation" name="ds-state-translation"></a>

#### 3.5.1 Translation

> **Preserve Conway outputs and existing pots while introducing legacy allocations with zero external deposits.**

```math
\begin{aligned}
\mathit{outputReferencesAfter}&=\mathit{outputReferencesBefore} \\
\mathit{outputPayloadsAfter}&=\mathit{outputPayloadsBefore} \\
\mathit{recordsAfter}&=\varnothing \\
\mathit{existingMonetaryPotsAfter}&=\mathit{existingMonetaryPotsBefore}
\end{aligned}
```

Every translated output is min-ADA and has a legacy allocation in the owning map.
Here `recordsAfter` denotes the empty external-deposit view; the cached total is zero.
Migration initializes V1 from the effective translated protocol parameters with
`mkDepositFormulaHistory formula`, leaving dated changes empty. Each imported entry
is marked `AtStoreMigration`. Its translated output and this permanent baseline
determine its embedded reserve. Its reserve is capped by its existing ADA, and remains inside that value.
Preserve each output’s semantic address, value, datum
and reference script under era translation; do not extract its implicit minimum
coin. Translate a complete Conway `NewEpochState`, then compare these fields with
their Conway values: output references and payloads; treasury, reserves, fees,
deposited ADA and donations; each account's rewards and deposit. This checks the
Store introduction and its preservation boundary, rather than equality of every
field across two different era types.

| Case | Contract | Scenario axes |
| --- | --- | --- |
| <a id="ds-state-translation-n01" name="ds-state-translation-n01"></a><a id="ds-state-initialization-n01" name="ds-state-initialization-n01"></a><a id="361-n01---preserves-existing-output-references-addresses-values-datums-and-reference-scripts-and-keeps-those-outputs-implicit" name="361-n01---preserves-existing-output-references-addresses-values-datums-and-reference-scripts-and-keeps-those-outputs-implicit"></a><a id="ds-state-initialization-n02" name="ds-state-initialization-n02"></a><a id="362-n02---initializes-store-balance-and-utxo-capacity-deposit-obligations-to-zero" name="362-n02---initializes-store-balance-and-utxo-capacity-deposit-obligations-to-zero"></a><a id="ds-state-initialization-n03" name="ds-state-initialization-n03"></a><a id="363-n03---does-not-transfer-funds-from-another-ledger-pot-during-initialization" name="363-n03---does-not-transfer-funds-from-another-ledger-pot-during-initialization"></a>**1.&nbsp;[N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/TranslationSpec.hs#L38)** | **Introduce legacy allocations.** Apply the real era translation; compare the listed fields independently with their source values, require one legacy allocation per output and assert a zero cached total and empty external-deposit view. | Each generated pair has zero and distinct positive pots. Ten outputs cover absent/hash/inline datums × absent/native/Plutus reference scripts, plus identical payloads at distinct indices. Compare full asset values, datum semantics and script identity. |

<a id="ds-state-epoch" name="ds-state-epoch"></a>

#### 3.5.2 Epoch

> **Preserve historical deposits; activate effective parameters for future allocations.**

```math
\mathit{recordsAfter}=\mathit{recordsBefore}
\implies \mathit{storeBalanceAfter}=\mathit{storeBalanceBefore}
```

| Case | Contract | Scenario axes |
| --- | --- | --- |
| <a id="ds-state-epoch-n01" name="ds-state-epoch-n01"></a><a id="ds-state-solvency-n03" name="ds-state-solvency-n03"></a><a id="345-n03---preserve-solvency-across-epochs" name="345-n03---preserve-solvency-across-epochs"></a>**1.&nbsp;[N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs#L37)** | **Retain the populated Store.** Cross actual epoch boundaries and compare the complete allocation map. | Fund one to five live allocations through an accepted transaction and cross two successive boundaries. Verify each epoch advanced and protocol parameters stayed unchanged; the cached balance and all historical metadata are preserved. |
| <a id="ds-state-epoch-n02" name="ds-state-epoch-n02"></a>**2.&nbsp;[N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs#L59)** | **Activate the effective price.** A scheduled parameter update changes the current rate without repricing live entries. | Cross real epoch boundaries with V1 and V2 selected. Compare the effective parameters, current formula, complete allocation map and cached total. |

For N02, $`V`$ is the selected formula version, $`r'`$ the newly effective byte price,
and $`s'`$ the first slot of the epoch where the update becomes effective. Append
$`(s',V(r'))`$ to history; entries allocated earlier retain their earlier formula:

```math
\begin{aligned}
\text{currentFormulaAfter} &= V(r') \\
\text{allocationsAfter} &= \text{allocationsBefore} \\
\text{totalDepositAmountAfter} &= \text{totalDepositAmountBefore}
\end{aligned}
```

<a id="ds-state-recovery" name="ds-state-recovery"></a><a id="37-recovery" name="37-recovery"></a><a id="ds-state-recovery-n01" name="ds-state-recovery-n01"></a><a id="371-n01---preserves-the-complete-ledger-state-through-serialization-and-restoration-including-outputs-allocated-records-and-store-surplus" name="371-n01---preserves-the-complete-ledger-state-through-serialization-and-restoration-including-outputs-allocated-records-and-store-surplus"></a>
**Existing codec coverage.** Dijkstra's [test entry point](../../eras/dijkstra/impl/test/Main.hs#L51)
registers the [Conway common](../../eras/conway/impl/testlib/Test/Cardano/Ledger/Conway/Binary/RoundTrip.hs#L27)
→ [Alonzo](../../eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Binary/RoundTrip.hs#L35)
→ [Shelley state round trips](../../eras/shelley/impl/testlib/Test/Cardano/Ledger/Shelley/Binary/RoundTrip.hs#L66),
including `AccountingState`, `LedgerState`, `EpochState` and `NewEpochState`. The [state generator](../../eras/shelley/impl/testlib/Test/Cardano/Ledger/Shelley/Arbitrary.hs#L205)
includes an arbitrary Dijkstra Store, and the [output generator](../../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Arbitrary.hs#L68)
includes both output forms. This existing serialization coverage stays in the
binary suite. [Allocations P03](#ds-state-allocations-p03) additionally submits an
output whose accepted CBOR is one byte longer than its canonical encoding, then
restores the serialized `AccountingState` and doubles the price. A reference-only
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
> Min-ADA output: full ADA · Deposit-backed output: application ADA · External deposit: no additional stake.

**Decision:** Exclude DepositStore UTxO capacity deposits from stake for the current prototype.

Apply the existing staking eligibility and delegation rules to the output's ADA contribution:

```math
\text{stakeContribution}(\text{output}) =
\begin{cases}
\text{full ADA in output} & \text{if output is implicit} \\
\text{application ADA in output} & \text{if output is deposit-backed}
\end{cases}
```

An eligible min-ADA output containing 10 ADA therefore contributes 10 ADA. A deposit-backed output containing 8 application ADA with a 2 ADA allocated deposit contributes only 8 ADA where otherwise eligible. Do not attribute its external allocated deposit to its staking credential or add the global Store balance separately to stake totals.

An allocation or release affects stake through the outputs and other existing stake updates actually applied. It creates no independent Store attribution. Ordinary success leaves collateral settlement and collateral return unapplied; accepted phase-2 failure derives stake effects from collateral consumption and return, without applying ordinary outputs or ordinary Store operations.

Existing registration, eligibility, delegation and snapshot timing remain in force. A contribution amount is not a claim that every output currently participates in stake. The exclusion also does not remove Store ADA from monetary conservation under `DS-STATE-CONSERVATION`. Voting weight is checked separately under `DS-VOTING`.

<a id="ds-stake-n01" name="ds-stake-n01"></a>

#### 4.1.1 N01 - counts the full ADA in min-ADA outputs under the existing staking rules

Given a min-ADA output eligible under the existing staking rules, use its full output ADA as its stake contribution. Keeping the legacy minimum inside that value does not create an external amount to subtract.

<a id="ds-stake-n02" name="ds-stake-n02"></a>

#### 4.1.2 N02 - counts only application ADA in deposit-backed outputs under the existing staking rules

Given an eligible deposit-backed output, count its application ADA and exclude its externally allocated deposit. For 8 application ADA and a 2 ADA deposit, the contribution base is 8 ADA.

<a id="ds-stake-n03" name="ds-stake-n03"></a>

#### 4.1.3 N03 - does not add the global Store balance to stake totals

Given a nonzero global Store balance, do not add that pot separately to stake totals or assign it to output credentials. Only otherwise eligible output ADA follows the existing stake rules.

<a id="ds-stake-n04" name="ds-stake-n04"></a>

#### 4.1.4 N04 - Derive stake from applied allocations

```math
\begin{aligned}
\text{ordinary success} \land \text{net allocation}>0
\implies\quad
\text{stake effects}
&= \text{existing stake rules}(\text{applied ordinary UTxO effects})
\end{aligned}
```

Given an ordinary successful allocation, derive stake effects from the ordinary outputs and existing stake updates actually applied. Funding the external deposit creates no separate credited stake.

<a id="ds-stake-n05" name="ds-stake-n05"></a>

#### 4.1.5 N05 - Derive stake from applied releases

```math
\begin{aligned}
\text{ordinary success} \land \text{net release}>0
\implies\quad
\text{stake effects}
&= \text{existing stake rules}(\text{applied ordinary UTxO effects})
\end{aligned}
```

Given an ordinary successful release, derive stake effects from the resulting ordinary outputs under existing eligibility rules. The released amount does not create an additional Store attribution beside those effects.

<a id="ds-stake-n06" name="ds-stake-n06"></a>

#### 4.1.6 N06 - Ignore unapplied collateral

```math
\text{ordinary success} \implies
\text{additional stake effects from collateral} = 0
```

Given ordinary success with supplied collateral and a possible return, do not apply additional stake effects from collateral settlement or that return. Include an input shared with ordinary spending: its ordinary consumption affects stake once, while inputs used only as collateral remain live.

<a id="ds-stake-n07" name="ds-stake-n07"></a>

#### 4.1.7 N07 - Derive stake from collateral on phase-2 failure

```math
\begin{aligned}
\text{accepted phase-2 failure} \implies\quad
\text{stake effects}
&= \text{existing stake rules}(\text{applied collateral UTxO effects}) \\
\text{stake effects from unapplied ordinary activity} &= 0
\end{aligned}
```

Given an accepted phase-2 failure, compare the resulting stake distribution with the independently selected collateral consumption and return effects under existing rules. Cover absent, min-ADA and deposit-backed returns and an input shared with ordinary spending. Unapplied ordinary outputs, allocations and releases add no stake effects.

<a id="ds-stake-n08" name="ds-stake-n08"></a>

#### 4.1.8 N08 - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects

Given allocation, release or collateral effects, observe positive eligible stake alongside ineligible credentials and distinct delegation destinations before and after the existing snapshot boundary. Compare the expected distribution under unchanged registration, eligibility, delegation and timing rules. Excluding external deposits must neither remove eligible application ADA nor create eligibility or apply a snapshot early.

<a id="ds-voting" name="ds-voting"></a>

### 4.2 Voting

> **Exclude external deposits from additional voting power.**
>
> Application ADA follows existing eligibility rules. Store ADA remains part of monetary conservation, but adds no voting weight.

**Decision:** Exclude DepositStore UTxO capacity deposits from voting power for the current prototype.

ADA held in the Store creates no additional voting weight. Do not attribute a deposit-backed output's allocated deposit to its credential or count the global Store balance separately in voting distributions. The application ADA remaining in outputs continues through existing eligibility, delegation and snapshot rules.

This concerns the resulting voting distribution, separately from the stake observations in `DS-STAKE`. The excluded Store ADA still exists in the monetary total checked by `DS-STATE-CONSERVATION`.

<a id="ds-voting-n01" name="ds-voting-n01"></a>

#### 4.2.1 N01 - preserves the expected voting distribution from eligible funds while excluding allocated UTxO capacity deposits and Store balance

Compare the complete resulting voting distribution with an independent expectation under existing eligibility, delegation and snapshot rules. Include positive eligible min-ADA output ADA and deposit-backed application ADA, other existing eligible funds, ineligible and differently delegated controls, nonzero recorded deposits across multiple live outputs. Observe ordinary success and accepted phase-2 failure before and after the existing snapshot boundary. Neither records nor the global Store balance add weight, while eligible funds retain their expected weight; an all-zero distribution must fail the positive controls.

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

> **A recorded allocation keeps its original pricing interval after later activations.**

`DepositFormulaHistory` contains the fork's initial formula and ordered activations.
Each `Unspent` holds its output and allocation origin. The history is shared across
entries and persists even when the Store is empty.

| Allocation | Formula on refund | Reserve |
| --- | --- | --- |
| Imported min-ADA output | `initialFormula` | Capped by its ADA and held inside the output. |
| Dated min-ADA output | Formula active at its allocation slot | Capped by its ADA and held inside the output. |
| Dated deposit-backed output | Formula active at its allocation slot | Full calculated amount held in the Store. |

A parameter change records the current version with its new rate at the effective
epoch boundary. Activating experimental V2 records a new version and effective
slot. Both are prospective. The [two-output example](#ds-pricing) gives the exact
refunds before and at the activation slot.

A distinct future proposal to reprice existing entries would need to specify how
to fund or release the difference for each live output.

<a id="ds-plutus-compatibility" name="ds-plutus-compatibility"></a>

#### A.2 Plutus compatibility

> **Define how deposit-backed outputs appear to each supported Plutus version.**
>
> Compatibility is the target; context projection and translation still require design and tests.

**Decision:** Target compatibility with all supported Plutus versions; context projection
and translation remain deferred.

The intended design supports deposit-backed outputs with Plutus V1, V2, V3 and V4, subject
to each version's existing feature restrictions. Store UTxO capacity deposits alone should
not impose a V4-only restriction.

The context translation and any exposure of DepositStore information remain to be
designed and tested. The current legacy translation paths contain `unexpected
DepositBackedTxOut` errors that must be addressed in that work. No context-value
projection or translation change is selected here.

<a id="ds-tx-settlement-refinement" name="ds-tx-settlement-refinement"></a>

#### A.3 Local settlement

> **Determine any stronger guarantee needed beyond the destination’s minimum amount.**
>
> $`\text{Settlement output ADA} \ge \text{release amount}`$ does not establish the origin of its coins. SubTx fee contributions must remain possible.

**Decision:** Output-index and output-coin checks are agreed, as is existing SubTx
imbalance. The stronger settlement guarantee remains open.

A SubTx consuming 10 ADA of serialized value plus a 2 ADA external deposit can
create a 12 ADA min-ADA output. If the new embedded minimum is 2 ADA, the child
declares zero. It can also create a 10 ADA output and contribute 2 ADA to TopTx
fees. With every other flow fixed and no fee contribution, a 10 ADA output
leaves 2 ADA unaccounted for. [Balance N06–F04](#ds-tx-accounting-balance-n06)

SubTx ADA surplus must remain available to fund TopTx fees or other bodies, including
when the SubTx settles a net Store release locally. Choosing
`SubTx.DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput index)` must not
impose independent SubTx balance or prohibit net ADA exports. The proposed no-export
inequality $`\text{ordinaryProducedADA} \ge \text{ordinaryConsumedADA} + \text{amount}`$ is therefore not
adopted.

Using the body's actual signed external Store change, its ADA export is

```math
\text{netADAExport}
= \text{ordinaryConsumedADA} - \text{storeChange(body)} - \text{ordinaryProducedADA}
```

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

> **Keep accepted outputs and allocation origins together; retain formula history in the Store.**

```text
LedgerState
├── lsAccountingState :: AccountingState
│   ├── asUTxOStore :: UTxOStore
│   │   ├── depositFormulaHistory :: DepositFormulaHistory
│   │   ├── totalDepositAmount :: DepositAmount
│   │   └── allocations :: IndexedUTxOs
│   │       └── TxIn → Unspent TxOut
│   │           ├── output
│   │           └── allocatedAt :: AllocatedAt
│   ├── asDeposited  — certificate and governance deposit pot
│   ├── asFees
│   ├── asInstantStake
│   └── asDonation
├── lsCertState :: CertState
└── lsGovState :: GovState
```

| Domain | Question answered |
| --- | --- |
| `AccountingState` | Which outputs, ADA pots and derived stake does the ledger hold? |
| `CertState` | Which accounts, delegations and registrations exist? |
| `GovState` | Which proposals, votes and protocol parameters govern the ledger? |

Certificate and governance records determine deposit obligations; accounting holds
those funds. The separately held output deposits remain inside `UTxOStore`.

```math
\text{asDeposited}
= \text{certificateObligations}(\text{lsCertState})
+ \text{governanceObligations}(\text{lsGovState})
```

Transaction rules thread `LedgerState` while updating the relevant domain.
The original certificate snapshot remains available when calculating refunds;
processing a certificate does not erase the information needed to account for it.
A phase-2 failure applies collateral effects without ordinary certificate or
governance effects. Existing nested CBOR and JSON ledger formats are preserved at
the serialization boundary; the in-memory model has three sibling states.

The shared modules follow those domains:

```text
Cardano.Ledger.State
├── Accounting              AccountingState and its field lenses
│   ├── InstantStake        Current output stake and its resolution against accounts
│   └── UTxOs               Store access
│       ├── Store
│       ├── IndexedUTxOs
│       ├── Unspent
│       └── Deposit
├── Certificates            EraCertState and registration state
│   ├── Account
│   └── StakePool
├── Governance              EraGov and protocol-parameter transitions
├── Epoch
│   ├── ChainAccount        Treasury and reserves
│   ├── SnapShots
│   ├── PoolDistr
│   └── LeiosCommittee      Consensus committee
└── Stake                   Shared stake value types
```

Era-specific certificate and instant-stake implementations use the same domain
names inside their era packages. Transaction queries (`EraUTxO`, consumed and
produced value, required scripts and witnesses) live in `Cardano.Ledger.UTxO`.

The collection types distinguish output inspection from recorded unspent entries:

| Type | Contents | Scope |
| --- | --- | --- |
| `IndexedTxOs` | `TxIn → Sized TxOut` | Proposed transaction outputs with their supplied sizes. |
| `IndexedUTxOs` | `TxIn → Unspent TxOut` | Recorded output payloads and allocation origins. Pricing resolves the formula from history. |

`allocations store` supplies the complete allocation state of that Store; selections
remain `IndexedUTxOs`. There is no additional `Allocations` wrapper. A body alone
cannot recover historical deposit parameters or establish which outputs remain unspent.

| Module under `Cardano.Ledger.State.Accounting.UTxOs` | Responsibility |
| --- | --- |
| [`Store`](../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Store.hs) | Public transaction projection (`projectTx` returning `TxProjected`), construction, record queries and formula activation. |
| [`Store.Internals`](../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Store/Internals.hs) | `projectValidTxBody`, `projectInvalidTxBody`, `allocate` and `release`; implementation used by ledger transitions and focused tests. |
| [`IndexedUTxOs`](../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/IndexedUTxOs.hs) | Input lookup, selection, filtering, entry traversal and deposit totals. |
| [`Unspent`](../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Unspent.hs) | One entry's accepted output and allocation origin; `toTxOut`, historical formula selection, `computeExternalDeposit` and entry codecs. |
| [`Deposit`](../../libs/cardano-ledger-core/src/Cardano/Ledger/State/Accounting/UTxOs/Deposit.hs) | Versioned formula arithmetic over `NativeAssetCount`, `DatumBytes` and `ReferenceScriptBytes`; `DepositAmount`, history and half-open formula periods. |

Dijkstra owns output measurement and the migrated-output reserve view:

| Module under `Cardano.Ledger.Dijkstra.UTxOs` | Responsibility |
| --- | --- |
| [`Deposit.Formula`](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/Formula.hs) | Extract the three typed measures from a `TxOut` and call the core `computeDeposit`; return `DepositAmount`. |
| [`Unspent`](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Unspent.hs) | `computeDeposit` and `computeApplicationAssets` select the allocation-time formula and cap a migrated min-ADA reserve at its output ADA. |

The shared Store calls `getDepositTxOut` only for `DepositBackedTxOut`. Min-ADA entries
contribute zero to its external total. Earlier eras have no `DepositBackedTxOut` values and
need no implementation of Dijkstra's pricing rule.

[`Cardano.Ledger.TxOut.IndexedTxOs`](../../libs/cardano-ledger-core/src/Cardano/Ledger/TxOut/IndexedTxOs.hs)
owns construction, indexing and selection of sized outputs. Each collection has its own
map operations; callers do not unwrap maps for ordinary lookups or selections.

**Queries retain complete entries.** Map operations belong to `IndexedUTxOs`:

```haskell
IndexedUTxOs.lookupUTxO input entries
IndexedUTxOs.restrictToInputs inputs entries
IndexedUTxOs.withoutInputs inputs entries
IndexedUTxOs.filterByTxOut predicate entries
IndexedUTxOs.sumDepositAmounts history entries
```

Selections preserve each entry's output payload and allocation origin.
`extractInputs` returns the remaining and extracted entries in one traversal.
`txOuts` supplies payloads for output-only arithmetic; `mapTxOuts` projects payloads
at external boundaries such as Plutus contexts, diagnostic maps and the formal model.
The block reference-script check reads the scripts on selected input payloads and
outputs proposed earlier in the block. It measures the scripts themselves.

`AccountingState`, `LedgerState`, `EpochState` and `NewEpochState` expose the complete
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

data TxProjected era = TxProjected
  { updatedStore :: !(UTxOStore era)
  , consumedOutputs :: !(IndexedUTxOs era)
  , producedOutputs :: !(IndexedUTxOs era)
  }

projectTx :: EraTx era => SlotNo -> Tx TopTx era -> UTxOStore era -> TxProjected era

allocate ::
  EraTxOut era =>
  SlotNo -> IndexedTxOs era -> UTxOStore era -> UTxOStore era

activateNewFormula :: SlotNo -> DepositFormula -> UTxOStore era -> UTxOStore era
```

The body builder preserves bounded output-index enumeration and excludes collateral return.
Babbage, Conway and Dijkstra retain the body's original `Sized` values; earlier eras
construct canonical legacy sizes. No deposit formula is selected while inspecting a body.
`producedTxOuts` selects regular outputs or collateral return according to the phase-2 outcome,
without claiming ledger acceptance.

`allocate slot` records `AtSlot slot` when new outputs enter the Dijkstra Store.
Existing inputs retain their allocation origin; history resolves the original
formula for their refund. Migrated entries continue to use the baseline.
The transition is explicit:

```haskell
TxProjected {updatedStore, consumedOutputs, producedOutputs} =
  Store.projectTx slot tx previousStore

updatedInstantStake =
  updateInstantStake consumedOutputs producedOutputs previousInstantStake
```

`projectTx` selects the TopTx's regular or collateral effects. Each internal body
projection returns the same `TxProjected` record: consumed entries come from the
previous Store; produced entries come from the updated Store and exclude retained
colliding references. `updateInstantStake` belongs to `State.Accounting.InstantStake`
and uses these actual changes. The accounting rule installs both results and emits
`TxUTxODiff consumedOutputs producedOutputs`. The result's complete Store is not
included in that event. Its entries preserve the output payload and allocation origin.

`Store.Internals.projectValidTxBody` releases the body's regular inputs and allocates its regular outputs.
It neither validates the body nor traverses nested SubTxs. The ledger selects the
execution path; `Store.Internals.projectInvalidTxBody` releases only collateral inputs
and allocates only the collateral return on phase-2 failure. Initialization and other operations
without a body explicitly import `Store.Internals` to call `allocate` or `release`.

These operations maintain the invariant for a valid Store:

```math
\text{totalDepositAmount}(S)
= \sum_{u\in\text{allocations}(S)} \text{computeExternalDeposit}(\text{depositFormulaHistory}(S),u)
```

The `allocate` primitive preserves an existing entry and its historical deposit
when a proposal uses the same reference. Only new entries increase the cached total.
Releasing an absent input has no effect. Unaffected entries retain their metadata.
For both valid and collateral projections in every era, a retained entry takes
precedence over a proposed output with the same key, preserving the original
map-union behavior. References released by the projection may be allocated again.

**Legacy boundaries retain their formats.**

- Before Dijkstra, `IndexedUTxOs` retains the ordinary payload-map CBOR used by queries.
  `UTxOStore` uses MemPack inputs and output payloads, preserving ledger snapshot bytes
  and credential sharing. Decoding reconstructs canonical min-ADA entries marked
  `AtStoreMigration` with zero external deposits. These bytes contain no Store
  history: ordinary decoding supplies the default V1/4310 baseline; the optional
  `decodeUTxOStoreWithFormula` decoder accepts a different caller-supplied one.
  Neither recovers each output's original creation-era pricing.
- Dijkstra collections encode complete entries as `TxIn → [output, allocatedAt]`.
  The Store encodes `[depositFormulaHistory, cachedTotal, allocationMap]`; history is
  `[initialFormula, formulaChanges]`. Decoding validates change order and the
  external total.
  Its `EncCBOR` instance retains MemPack inputs and output payloads plus explicit metadata.
  Standalone Store encoding now uses this same snapshot format.
- The retired standalone Dijkstra `TxOutMap` payload encoding cannot represent complete
  entries. Its replacement has the complete-entry format. The previous two-field Store
  snapshot is rejected: its history cannot be recovered from individual entries,
  especially when the Store is empty. The former formula-bearing entry format
  is also distinct from the new `AllocatedAt` encoding.
- Before Dijkstra, legacy import builds `AtStoreMigration` entries with
  `IndexedUTxOs.fromMinAdaTxOuts`; Store construction receives either default or
  caller-supplied history. Earlier-era Store translations preserve source history; Conway
  canonical import retains the destination state's supplied history because its
  namespace contains outputs only. The Dijkstra fork initializes its baseline from
  the effective translated protocol parameters, with no dated changes. Future changes
  retain their actual activation slots. `mkUTxOStore history entries` restores complete entries
  with their payloads and allocation origins. No migration
  operation extracts reserve ADA from a min-ADA payload or creates an external credit.

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
| Allocations P01–P03, N01–N08 | [Allocations](#ds-state-allocations): ordinary/collateral records, historical refunds, zero-priced records and inactive ordinary operations after phase-2 failure. |
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
| `DS-TX-GRAMMAR` | [DS-TX-DECLARATIONS-GRAMMAR](declarations.md#ds-tx-declarations-grammar) |
| `DS-TX-REQUIRED-DECLARATIONS` | [DS-TX-DECLARATIONS-REQUIREMENTS](declarations.md#ds-tx-declarations-requirements) |

Every category and case suffix is preserved. Previous Grammar and Required declarations
anchors remain valid; the new Declarations parent does not add or remove test cases.

The Requirements category and its Store-operation and SubTx-declaration groups use these current prefixes:

| Previous prefix | Current prefix |
| --- | --- |
| `DS-TX-PRESENCE` | [DS-TX-DECLARATIONS-REQUIREMENTS](declarations.md#ds-tx-declarations-requirements) |
| `DS-TX-PRESENCE-OPERATIONS`, `DS-TX-PRESENCE-ACTIVITY` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](declarations.md#ds-tx-declarations-requirements-operations) |
| `DS-TX-PRESENCE-OPERATIONS-ALLOCATION`, `DS-TX-PRESENCE-ACTIVITY-CREATION` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](declarations.md#ds-tx-declarations-requirements-operations-allocation) |
| `DS-TX-PRESENCE-OPERATIONS-RELEASE`, `DS-TX-PRESENCE-ACTIVITY-SPENDING` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE](declarations.md#ds-tx-declarations-requirements-operations-release) |
| `DS-TX-PRESENCE-OPERATIONS-ZERO-NET-CHANGE` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ZERO-NET-CHANGE](declarations.md#ds-tx-declarations-requirements-operations-zero-net-change) |
| `DS-TX-PRESENCE-ACTIVITY-SCOPE`, `DS-TX-PRESENCE-OPERATIONS-SCOPE` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](declarations.md#ds-tx-declarations-requirements-operations), with cases assigned to Allocation or Release below. |
| `DS-TX-PRESENCE-SUBTX-DECLARATIONS`, `DS-TX-PRESENCE-DEPENDENCY` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS](declarations.md#ds-tx-declarations-requirements-subtx-declarations), preserving C01–C05 and every case suffix. |

Every previous `DS-TX-PRESENCE` rule and case anchor still resolves to the corresponding
Requirements section. Case order is unchanged within the new Declarations parent. The former
Scope group anchors open the Operations overview; each old Scope case anchor opens
its migrated case. Both the `ACTIVITY-SCOPE` and `OPERATIONS-SCOPE` prefixes follow
this mapping:

| Previous Scope case | Current case |
| --- | --- |
| `N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N06](declarations.md#ds-tx-declarations-requirements-operations-allocation-n06) |
| `N02` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N07](declarations.md#ds-tx-declarations-requirements-operations-allocation-n07) |
| `N03` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N08](declarations.md#ds-tx-declarations-requirements-operations-allocation-n08) |
| `F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-F07](declarations.md#ds-tx-declarations-requirements-operations-allocation-f07) |
| `F02` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-F08](declarations.md#ds-tx-declarations-requirements-operations-allocation-f08) |
| `N06` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION-N09](declarations.md#ds-tx-declarations-requirements-operations-allocation-n09) |
| `N04` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N09](declarations.md#ds-tx-declarations-requirements-operations-release-n09) |
| `N05` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-N10](declarations.md#ds-tx-declarations-requirements-operations-release-n10) |
| `F03` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE-F06](declarations.md#ds-tx-declarations-requirements-operations-release-f06) |

Allocation and release identify gross Store operations; neither implies the
declaration's net sign. The former Scope N06 is now Allocation N09: both bodies
allocate deposits, neither releases one, and both declare exactly. The generated
ledger scenario prices each body's outputs independently and requires acceptance.

| Previous rule | Current responsibilities |
| --- | --- |
| `DS-TX-001` | [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-RELEASE](declarations.md#ds-tx-declarations-requirements-operations-release), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](declarations.md#ds-tx-declarations-requirements-operations-allocation), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ZERO-NET-CHANGE](declarations.md#ds-tx-declarations-requirements-operations-zero-net-change), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS](declarations.md#ds-tx-declarations-requirements-operations) |
| `DS-TX-002` | [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](#ds-tx-accounting-net-change-toptx), [DS-TX-ACCOUNTING-ATTRIBUTION](#ds-tx-accounting-attribution), [DS-TX-SETTLEMENT-DESIGNATION](#ds-tx-settlement-designation) |
| `DS-TX-003` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-ACCOUNTING-NET-CHANGE-TOPTX](#ds-tx-accounting-net-change-toptx) |
| `DS-TX-004` | [DS-TX-ACCOUNTING-BALANCE](#ds-tx-accounting-balance) |
| `DS-TX-005` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-ACCOUNTING-ATTRIBUTION](#ds-tx-accounting-attribution), [DS-TX-SETTLEMENT-OUTPUT-INDEX](#ds-tx-settlement-output-index) |
| `DS-TX-006` | [DS-TX-SETTLEMENT-DESIGNATION](#ds-tx-settlement-designation) |
| `DS-TX-007` | [DS-TX-ACCOUNTING-BALANCE](#ds-tx-accounting-balance), [DS-TX-SETTLEMENT-OUTPUT-INDEX](#ds-tx-settlement-output-index), [DS-TX-SETTLEMENT-OUTPUT-COIN](#ds-tx-settlement-output-coin), [DS-STATE-UTXO](#ds-state-utxo) |
| `DS-TX-008` | [DS-TX-DECLARATIONS-GRAMMAR](declarations.md#ds-tx-declarations-grammar), [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx) |
| `DS-TX-009` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS](declarations.md#ds-tx-declarations-requirements-subtx-declarations) |
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
| `DS-STORE-004` | [DS-TX-ACCOUNTING-NET-CHANGE-SUBTX](#ds-tx-accounting-net-change-subtx), [DS-TX-DECLARATIONS-REQUIREMENTS-OPERATIONS-ALLOCATION](declarations.md#ds-tx-declarations-requirements-operations-allocation), [DS-STATE-ALLOCATIONS](#ds-state-allocations), [DS-STATE-TRANSLATION](#ds-state-translation) |
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
| `N03` | [Release N09](declarations.md#ds-tx-declarations-requirements-operations-release-n09): existing reference-only declaration case; an attempted release amount is an Accounting concern |

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
The former combined invalid-amount check keeps [F01](declarations.md#ds-tx-declarations-grammar-f01) for TopTx
zero. Its remaining TopTx assertions use [F12](declarations.md#ds-tx-declarations-grammar-f12) for negative
amounts and [F13](declarations.md#ds-tx-declarations-grammar-f13) for overflowing amounts.
Its SubTx assertions are split into [F07](declarations.md#ds-tx-declarations-grammar-f07) for zero,
[F08](declarations.md#ds-tx-declarations-grammar-f08) for negative amounts and [F09](declarations.md#ds-tx-declarations-grammar-f09) for
overflowing amounts; F07 retains the zero case from the former combined SubTx check.
The former combined SubTx target check keeps [F05](declarations.md#ds-tx-declarations-grammar-f05) for invalid
structure. Its index range assertions now have separate tags:
[F10](declarations.md#ds-tx-declarations-grammar-f10) for negative indices and [F11](declarations.md#ds-tx-declarations-grammar-f11) for
indices above 65535. Similarly, the former combined TopTx settlement check keeps
[F04](declarations.md#ds-tx-declarations-grammar-f04) for invalid structure; [F14](declarations.md#ds-tx-declarations-grammar-f14) covers
negative indices and [F15](declarations.md#ds-tx-declarations-grammar-f15) covers indices above 65535.
These checks concern decoding; output existence remains under
[DS-TX-SETTLEMENT-OUTPUT-INDEX](#ds-tx-settlement-output-index).

The previously individually tagged declaration-dependency cases map as follows:

| Previous case | Current case |
| --- | --- |
| `DS-TX-009-C01-P01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C01-P01](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c01-p01) |
| `DS-TX-009-C02-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-N01](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c02-n01) |
| `DS-TX-009-C02-N02` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-N02](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c02-n02) |
| `DS-TX-009-C02-N03` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-N03](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c02-n03) |
| `DS-TX-009-C02-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C02-F01](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c02-f01) |
| `DS-TX-009-C03-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C03-N01](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c03-n01) |
| `DS-TX-009-C03-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C03-F01](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c03-f01) |
| `DS-TX-009-C04-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C04-N01](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c04-n01) |
| `DS-TX-009-C04-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C04-F01](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c04-f01) |
| `DS-TX-009-C05-N01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C05-N01](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c05-n01) |
| `DS-TX-009-C05-F01` | [DS-TX-DECLARATIONS-REQUIREMENTS-SUBTX-DECLARATIONS-C05-F01](declarations.md#ds-tx-declarations-requirements-subtx-declarations-c05-f01) |
| `DS-TX-009-C06-P01` | [Technical fixture property](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/DepositStoreFixtureSpec.hs), outside the business specification |

<a id="section-10" name="section-10"></a>

### C. Code references

> **Locate the implementation entry points for each responsibility.**
>
> Declaration forms $`\longrightarrow`$ domain APIs · Validation $`\longrightarrow`$ ledger rules · Pricing $`\longrightarrow`$ asset count and payload lengths.

The executable suite mirrors the rule chapters:

| Chapter | Test modules under `DepositStore/` |
| --- | --- |
| Transaction rules | [`TransactionRulesSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRulesSpec.hs) composes `TransactionRules/Tx/` and `TransactionRules/Collateral/`. |
| Ledger effects | [`LedgerEffectsSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffectsSpec.hs) composes `UTxOSpec`, `Store/`, `FeesSpec`, `ConservationSpec` and `Lifecycle/`. |

[`DeclarationsSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/DeclarationsSpec.hs)
composes [`GrammarSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/GrammarSpec.hs)
and [`RequirementsSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/RequirementsSpec.hs).
Grammar checks valid representations; Requirements checks which bodies must declare.
Within `TransactionRules/Tx/Declarations/Requirements/Operations/`,
[`AllocationSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs)
and [`ReleaseSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs)
cover each gross operation and identify which operations belong to each body.
[`OperationsSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/OperationsSpec.hs)
checks the shared declaration requirement independently of deposit price: generated
Deposit-backed input and output forms still require declarations when their priced
amounts are zero. Accepted controls and one-field omissions exercise both body
levels, ordinary success and real phase-2 failure.
[`ZeroNetChangeSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs)
checks equal positive allocations and releases independently for each active
TopTx or SubTx, including mixed active/inactive children and proposals on the
phase-2 failure path. Its six nominal and eight rejection properties require
explicit zero at each active body and the parent declaration required by children.
[`SubTxDeclarationsSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs)
checks the TopTx field required by any explicit SubTx declaration, including
zero and offsetting contributions from two SubTxs.

[`AccountingSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/AccountingSpec.hs)
composes [`NetChangeSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/NetChangeSpec.hs)
and [`BalanceSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Accounting/BalanceSpec.hs).
Net change checks each SubTx's own amount and TopTx's complete transaction total.
Balance checks the complete transaction's financial conservation when phase 2 is valid.

[`CollateralSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/CollateralSpec.hs)
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

[`UTxOSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/UTxOSpec.hs)
owns the exact UTxO transition selected by the accepted outcome.
[`AllocationsSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/AllocationsSpec.hs)
owns retained records; [`BalanceSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Store/BalanceSpec.hs)
checks the change in the sum of records. [`FeesSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/FeesSpec.hs)
checks ordinary and collateral fee credits and unchanged treasury. The map and
Store assertions formerly embedded there now belong to UTxO and Store specs. [`ConservationSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/ConservationSpec.hs)
compares independent actual-pot sums with the production total including donations.

[`TranslationSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/TranslationSpec.hs)
corresponds to [full-state translation](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Translation.hs#L103),
[UTxO/Store translation](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Translation.hs#L217)
and [min-ADA output upgrade](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxOut.hs#L216).
[`EpochSpec`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/LedgerEffects/Lifecycle/EpochSpec.hs)
observes the Store preserved by [ordinary epoch processing](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Epoch.hs#L218).
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
| `Specs.Tx.TopTx.Allocation` | Generate standalone allocations with at least one deposit-backed output; calculate their allocation and attach the supplied declaration. |
| `Specs.Tx.TopTx.Release` | Keep TopTx and its optional SubTxs with their funded ledger context; calculate the complete transaction's net deposit and apply the supplied declarations. |
| `Specs.Tx.SubTx` | Generate release and equal-allocation-and-release scenarios; expose each child's `allocatedDeposits`, recorded release and `depositBackedInputs` in transaction order, and identify declarations by source input. |
| `Specs.OutputIndex` / `StrictlyPositiveCoin` | Provide shared index generators and checked amount fixtures. |
| `Specs.LedgerEffects` | Fund and sign valid ordinary, delegated or phase-2-invalid scenarios; preserve real noncanonical body bytes and restore UTxO-state snapshots. Expected state changes remain in the specs. |
| `Specs.LedgerEffects.ADA` | Sum actual monetary pots independently of the production ADA-total projection. |
| `Specs.LedgerEffects.UTxO` | Prepare reference-only and overlapping ordinary/collateral input roles while preserving valid signatures and script pointers. |
| `Specs.Lifecycle` | Generate Conway translation states and funded Store scenarios for actual epoch transitions. |
| `Specs.Assertions` | Apply a supplied expectation to one or more observations. |
| `Encoding` | Observe CBOR and JSON behavior together, with a separate implementation for each format. |
| `Submission` | Fund and prepare ledger transactions, preserve fixtures through fixup, submit and check ledger outcomes. Its declaration and output modules register the scenario rows. |
| `Submission.Allocation` | Fund application outputs, declarations and fees from min-ADA inputs; preserve the allocation proposal while signing it or removing its declaration. |
| `Submission.Operations` | Fund distinct sources at zero deposit price, verify their real output forms and Store records, and return an undeclared proposal preserving each body's ownership and application ADA. |
| `Submission.Release` | Fund generated release or reference sources, preserve proposals while signing, and prepare collateral-only scenarios with actual script success or failure. |
| `Submission.Collateral` | Prepare transactions with collateral whose deposits and failure-path transfers can be observed by the specifications. |

These fixture entry points fund each generated scenario, then pass a proposal
with **no declarations** to the case:

| Fixture entry point | What the case receives |
| --- | --- |
| `fundOperations` | A parent and zero to four children with independent source/output forms, each owning a distinct funded input. Deposit-backed sources have a recorded zero deposit; min-ADA sources have no record. |
| `forAllReferenceOnlyStoreTx` | A standalone TopTx referencing real positive Store allocations, with no ordinary Store operations. |
| `forAllStandaloneReleaseTx` | A standalone TopTx with its funded ledger context. |
| `forAllSingleSubTxReleaseTx` | A TopTx with one SubTx, its funded context and the source's recorded positive deposit. |
| `forAllSubTxReleaseTx` | A TopTx with several SubTxs and their funded ledger context. |
| `forAllStandaloneZeroNetChangeTx` | A funded standalone TopTx with independently checked equal positive allocations and recorded releases. |
| `forAllSubTxZeroNetChangeTx` | A funded TopTx and its SubTxs, with independently checked equal positive allocations and recorded releases for every active body, and zero amounts for inactive bodies. |

`TopTx.netDeposit` sums the signed backing change of both output forms across
**TopTx and all its SubTxs**. `TopTx.releasedDeposits` returns their total external
deposit release. `SubTx.releasedDeposits` returns one amount per child in transaction order, including
zero for children consuming only min-ADA sources.

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

- [TopTx declaration domain API](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/TopTx.hs)
- [SubTx declaration domain API](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/UTxOs/Deposit/SubTx.hs)
- [Transaction fields, operations and lenses](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxBody.hs)
- [Output variants and shared interfaces](../../libs/cardano-ledger-core/src/Cardano/Ledger/TxOut.hs)
- [Dijkstra output representations](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxOut.hs)
- [Dijkstra active-formula minimum-coin validation](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/DepositStore/MinimumCoin.hs)
- [Earlier-era byte-based minimum-coin rule](../../eras/babbage/impl/src/Cardano/Ledger/Babbage/TxOut.hs)
- [Serialized size measurement for proposed outputs](../../libs/cardano-ledger-binary/src/Cardano/Ledger/Binary/Decoding/Sized.hs)
- [TopTx UTXO rule](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Utxo.hs)
- [SubTx UTXO rule](../../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/SubUtxo.hs)

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
[`Cardano.Ledger.StrictlyPositiveCoin`](../../libs/cardano-ledger-core/src/Cardano/Ledger/StrictlyPositiveCoin.hs).
`mkStrictlyPositiveCoin :: Coin -> Maybe StrictlyPositiveCoin` accepts exactly
$`1 \le \mathit{amount} \le 2^{64}-1`$ lovelace; `unStrictlyPositiveCoin` returns the
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
tags and encoded bytes are unchanged. `DepositBackedTxOut` remains the output variant
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

[Grammar](declarations.md#ds-tx-declarations-grammar) owns declaration forms and declaration decoder rejection,
including enforcement of `StrictlyPositiveCoin` amounts. The type's construction
and scalar codecs belong to ledger-core's `StrictlyPositiveCoinSpec`.
The [declaration codec specification](../../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Binary/Golden.hs)
retains independent exact-byte/JSON goldens, historical field omission and malformed
payload checks through both transaction-body decoders.
These representation checks establish which forms can be expressed. Requirements,
exactness and conservation determine whether an expressed declaration is valid in its transaction.

[`Declaration/TopTx.hs`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Specs/Tx/Declaration/TopTx.hs)
and [`Declaration/SubTx.hs`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Specs/Tx/Declaration/SubTx.hs)
provide typed declarations, paired bodies and independent raw decoder inputs for
the same declaration domain. `allDeclarationsWithAmount` and
`allDeclarationInputsWithAmount` retain every operation form and both index bounds
while varying a valid interior index. `declarationsAtBounds` also retains both
amount bounds and explicit zero. `absentAndExplicitZero` generates paired bodies
differing only in declaration presence; SubTx also generates positive funding
requests. Structural input generators cover every defect category in each draw.

These modules also construct raw local destinations for the generated index
properties and their shrunk counterexamples.

[`OutputIndex.hs`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Specs/OutputIndex.hs)
provides shared negative and overflowing index generators. The specs preserve
those ranges while shrinking. [`Encoding.hs`](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Core/Encoding.hs)
combines CBOR and JSON observations; each format has its own implementation.
