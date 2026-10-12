# Dijkstra DepositStore specification

This specification states the DepositStore business rules and the cases used to check
them. The rule chapters follow the executable suite’s domain groups, case titles and reading
order. Semantic tags connect each requirement to its test independently of section
numbering. Implementation status and recorded runs belong in the
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
          <a href="#ds-pricing-p01">1.4.1 P01 - ordinary success ⇒ newly recorded UTxO capacity deposit amounts equal coinsPerUTxOByte * (160 + acceptedSize) for store-backed outputs</a><br>
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
                <a href="#ds-tx-grammar-n01">2.1.1.1 N01 - does not interpret an explicit SubTx zero as a delegation request</a><br>
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
                      <a href="#ds-tx-presence-activity-p01">2.1.2.1.1 P01 - A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change.</a><br>
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
                            <a href="#ds-tx-presence-activity-creation-f06">2.1.2.1.2.10 F06 - rejects a missing allocation declaration when spending a translated implicit output to create store-backed outputs</a><br>
                          </dd>
                        </dl>
                      </details>
                      <details>
                        <summary><a href="#ds-tx-presence-activity-spending">2.1.2.1.3 Spending</a></summary>
                        <dl>
                          <dd>
                            <a href="#ds-tx-presence-activity-spending-n01">2.1.2.1.3.1 N01 - accepts a TopTx spending a store-backed input with its own declaration</a><br>
                            <a href="#ds-tx-presence-activity-spending-n02">2.1.2.1.3.2 N02 - accepts a SubTx spending a store-backed input with its own declaration</a><br>
                            <a href="#ds-tx-presence-activity-spending-f01">2.1.2.1.3.3 F01 - rejects a TopTx spending a store-backed input without a declaration</a><br>
                            <a href="#ds-tx-presence-activity-spending-f02">2.1.2.1.3.4 F02 - rejects a SubTx spending a store-backed input without its own declaration</a><br>
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
                            <a href="#ds-tx-presence-activity-scope-f03">2.1.2.1.4.9 F03 - does not let a SubTx declaration replace a missing TopTx declaration</a><br>
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
                            <a href="#ds-tx-presence-dependency-c01-p01">2.1.2.2.1.1 P01 - any SubTx has a declaration ⇒ TopTx has a declaration</a><br>
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
                      <a href="#ds-tx-exactness-contribution-p01">2.1.3.1.1 P01 - ∀ s ∈ SubTxs: hasDeclaration(s) ⇒ declaredNetUTxODepositChange(s) = allocatedUTxODeposits(s) - releasedUTxODeposits(s)</a><br>
                      <a href="#ds-tx-exactness-contribution-n01">2.1.3.1.2 N01 - accepts a contribution equal to allocated UTxO capacity deposits minus released UTxO capacity deposits</a><br>
                      <a href="#ds-tx-exactness-contribution-f01">2.1.3.1.3 F01 - rejects a net allocation one lovelace below the required contribution</a><br>
                      <a href="#ds-tx-exactness-contribution-f02">2.1.3.1.4 F02 - rejects a net allocation one lovelace above the required contribution</a><br>
                      <a href="#ds-tx-exactness-contribution-f03">2.1.3.1.5 F03 - rejects a net release one lovelace below the required contribution</a><br>
                      <a href="#ds-tx-exactness-contribution-f04">2.1.3.1.6 F04 - rejects a net release one lovelace above the required contribution</a><br>
                      <a href="#ds-tx-exactness-contribution-f05">2.1.3.1.7 F05 - rejects opposing declaration errors even when they cancel in the batch total</a><br>
                      <a href="#ds-tx-exactness-contribution-n02">2.1.3.1.8 N02 - checks TopTx's own UTxO capacity deposit contribution separately from SubTx contributions</a><br>
                      <a href="#ds-tx-exactness-contribution-n03">2.1.3.1.9 N03 - accepts an explicit zero when the declared UTxO capacity deposit contribution is zero</a><br>
                      <a href="#ds-tx-exactness-contribution-f06">2.1.3.1.10 F06 - rejects an explicit zero when a net allocation must be funded</a><br>
                      <a href="#ds-tx-exactness-contribution-n04">2.1.3.1.11 N04 - checks a delegated net allocation against the requesting SubTx's exact net UTxO capacity deposit change</a><br>
                      <a href="#ds-tx-exactness-contribution-n05">2.1.3.1.12 N05 - checks a delegated net release against the originating SubTx's exact net UTxO capacity deposit change</a><br>
                      <a href="#ds-tx-exactness-contribution-n06">2.1.3.1.13 N06 - requires a net release when a body spends store-backed outputs and creates only implicit outputs</a><br>
                      <a href="#ds-tx-exactness-contribution-f07">2.1.3.1.14 F07 - rejects an explicit zero when that body must release UTxO capacity deposits</a><br>
                      <a href="#ds-tx-exactness-contribution-n07">2.1.3.1.15 N07 - preserves that body's net release even when another body's net allocation offsets it</a><br>
                      <a href="#ds-tx-exactness-contribution-n08">2.1.3.1.16 N08 - still requires the exact UTxO capacity deposit for an output with no application assets</a><br>
                      <a href="#ds-tx-exactness-contribution-n09">2.1.3.1.17 N09 - accepts spending a translated implicit output to create store-backed outputs with the exact declared allocation and batch funding</a><br>
                      <a href="#ds-tx-exactness-contribution-f08">2.1.3.1.18 F08 - rejects an inexact allocation when spending a translated implicit output to create store-backed outputs</a><br>
                      <a href="#ds-tx-exactness-contribution-f09">2.1.3.1.19 F09 - rejects an unrelated release from pre-existing Store surplus</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-exactness-netting">2.1.3.2 Netting</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-exactness-netting-p01">2.1.3.2.1 P01 - declared TopTx: declaredNetUTxODepositChange = Σ(netUTxODepositChange) over all bodies</a><br>
                      <a href="#ds-tx-exactness-netting-n01">2.1.3.2.2 N01 - includes both TopTx and SubTx UTxO capacity deposit changes in the declared total</a><br>
                      <a href="#ds-tx-exactness-netting-n02">2.1.3.2.3 N02 - nets a 5 ADA allocation and a 3 ADA release into AllocateUTxODeposit 2</a><br>
                      <a href="#ds-tx-exactness-netting-n03">2.1.3.2.4 N03 - nets a 3 ADA allocation and a 5 ADA release into ReleaseUTxODeposit 2</a><br>
                      <a href="#ds-tx-exactness-netting-n04">2.1.3.2.5 N04 - uses NoUTxODepositChange when allocations and releases cancel exactly</a><br>
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
                <a href="#ds-tx-attribution-p01">2.1.4.1 P01 - topTxNetUTxODepositChange + Σ(subTxLocalNetUTxODepositChanges) = txTotalNetUTxODepositChange</a><br>
                <a href="#ds-tx-attribution-p02">2.1.4.2 P02 - switching between local accounting and delegation preserves txTotalNetUTxODepositChange</a><br>
                <a href="#ds-tx-attribution-n01">2.1.4.3 N01 - counts delegated funding once in TopTx accounting</a><br>
                <a href="#ds-tx-attribution-n02">2.1.4.4 N02 - keeps the same batch net change when a SubTx delegates funding of its net allocation</a><br>
                <a href="#ds-tx-attribution-n03">2.1.4.5 N03 - allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-conservation">2.1.5 Conservation</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-conservation-p01">2.1.5.1 P01 - consumedValue + inject(max(0, -txTotalNetUTxODepositChange)) = producedValue + inject(max(0, txTotalNetUTxODepositChange))</a><br>
                <a href="#ds-tx-conservation-p02">2.1.5.2 P02 - ledger acceptance agrees with the model even when individual SubTxs are financially imbalanced</a><br>
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
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-tx-authorization">2.1.6 Authorization</a></summary>
            <dl>
              <dd>
                <a href="#ds-tx-authorization-n01">2.1.6.1 N01 - allows the authorized spender to release UTxO capacity deposits paid by another person</a><br>
                <a href="#ds-tx-authorization-n02">2.1.6.2 N02 - does not require a separate signature from the original UTxO capacity deposit funder</a><br>
                <a href="#ds-tx-authorization-f01">2.1.6.3 F01 - rejects unauthorized spending even when the Store declaration is exact</a><br>
                <a href="#ds-tx-authorization-n03">2.1.6.4 N03 - does not release UTxO capacity deposits for a reference input</a><br>
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
                      <a href="#ds-tx-settlement-participation-p01">2.1.7.1.1 P01 - for a batch net release: NoTopTxSettlement ⇔ topTxNetRelease = 0</a><br>
                      <a href="#ds-tx-settlement-participation-n01">2.1.7.1.2 N01 - requires NoTopTxSettlement when SubTxs settle the entire net release locally</a><br>
                      <a href="#ds-tx-settlement-participation-n02">2.1.7.1.3 N02 - requires a TopTx settlement output when the batch declares a net release and TopTx has a positive share</a><br>
                      <a href="#ds-tx-settlement-participation-n03">2.1.7.1.4 N03 - accepts a net release settled across TopTx and SubTx outputs</a><br>
                      <a href="#ds-tx-settlement-participation-n04">2.1.7.1.5 N04 - allows TopTx's settlement amount to exceed the batch net release when SubTxs fund net allocations locally</a><br>
                      <a href="#ds-tx-settlement-participation-f01">2.1.7.1.6 F01 - rejects NoTopTxSettlement when the batch declares a net release and TopTx has a positive share</a><br>
                      <a href="#ds-tx-settlement-participation-f02">2.1.7.1.7 F02 - rejects a TopTx settlement output when TopTx has no net release to settle</a><br>
                      <a href="#ds-tx-settlement-participation-n05">2.1.7.1.8 N05 - does not require a TopTx settlement output when the batch declares a net allocation</a><br>
                      <a href="#ds-tx-settlement-participation-n06">2.1.7.1.9 N06 - does not require a TopTx settlement output for an explicit-zero batch even when TopTx's derived accounting portion is negative</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-settlement-destination">2.1.7.2 Destination</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-destination-p01">2.1.7.2.1 P01 - each settlement output: 0 ≤ index &lt; length(ownOutputs)</a><br>
                      <a href="#ds-tx-settlement-destination-f01">2.1.7.2.2 F01 - rejects an index outside the declaring body's output sequence</a><br>
                      <a href="#ds-tx-settlement-destination-f02">2.1.7.2.3 F02 - does not resolve a SubTx settlement index against TopTx outputs</a><br>
                      <a href="#ds-tx-settlement-destination-f03">2.1.7.2.4 F03 - does not resolve a settlement index against collateral return</a><br>
                      <a href="#ds-tx-settlement-destination-f04">2.1.7.2.5 F04 - rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs</a><br>
                    </dd>
                  </dl>
                </details>
                <details>
                  <summary><a href="#ds-tx-settlement-coverage">2.1.7.3 Coverage</a></summary>
                  <dl>
                    <dd>
                      <a href="#ds-tx-settlement-coverage-p01">2.1.7.3.1 P01 - each settlement output: coin(ownOutputs[index]) ≥ settlementAmount</a><br>
                      <a href="#ds-tx-settlement-coverage-f01">2.1.7.3.2 F01 - rejects a settlement output containing less ADA than its settlement amount</a><br>
                      <a href="#ds-tx-settlement-coverage-n01">2.1.7.3.3 N01 - accepts a settlement output containing exactly its settlement amount</a><br>
                      <a href="#ds-tx-settlement-coverage-n02">2.1.7.3.4 N02 - accepts a settlement output containing the settlement amount and additional funds</a><br>
                      <a href="#ds-tx-settlement-coverage-f02">2.1.7.3.5 F02 - rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference</a><br>
                      <a href="#ds-tx-settlement-coverage-n03">2.1.7.3.6 N03 - accepts a store-backed settlement output with application ADA equal to the settlement amount</a><br>
                      <a href="#ds-tx-settlement-coverage-n04">2.1.7.3.7 N04 - checks TopTx's derived settlement amount rather than the entire batch net release</a><br>
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
                <a href="#ds-tx-application-assets-n04">2.1.8.4 N04 - preserves the minimum-coin requirement for implicit outputs</a><br>
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
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-authorization">2.2.2 Authorization</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-authorization-f01">2.2.2.1 F01 - rejects collateral inputs that fail the existing key-control checks</a><br>
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
                <a href="#ds-collateral-funding-p01">2.2.3.7 P01 - accepted phase-2 failure ⇒ collateralCoinFee ≥ ceil(txFee * collateralPercentage / 100)</a><br>
                <a href="#ds-collateral-funding-f03">2.2.3.8 F03 - rejects collateral whose minimum fee depends on released UTxO capacity deposit surplus</a><br>
                <a href="#ds-collateral-funding-f04">2.2.3.9 F04 - rejects a collateral return whose funding depends on released UTxO capacity deposit surplus</a><br>
                <a href="#ds-collateral-funding-f05">2.2.3.10 F05 - rejects a collateral funding shortfall of one lovelace</a><br>
                <a href="#ds-collateral-funding-n05">2.2.3.11 N05 - counts implicit collateral inputs' full ADA as coins and zero released Store deposits when mixed with store-backed inputs</a><br>
                <a href="#ds-collateral-funding-n06">2.2.3.12 N06 - allocates no Store deposit to an implicit collateral return even when consuming store-backed collateral inputs</a><br>
                <a href="#ds-collateral-funding-n07">2.2.3.13 N07 - accepts a store-backed collateral return with zero application ADA when its deposit and the minimum fee are funded</a><br>
                <a href="#ds-collateral-funding-f06">2.2.3.14 F06 - rejects underfunded collateral when the optional total is absent</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-surplus">2.2.4 Surplus</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-surplus-n01">2.2.4.1 N01 - credits excess released UTxO capacity deposits to fees rather than the treasury</a><br>
                <a href="#ds-collateral-surplus-p01">2.2.4.2 P01 - accepted phase-2 failure ⇒ feesAfter = feesBefore + collateralCoinFee + releasedUTxODepositFee</a><br>
                <a href="#ds-collateral-surplus-p02">2.2.4.3 P02 - accepted phase-2 failure ⇒ treasuryAfter = treasuryBefore</a><br>
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
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-settlement">2.2.6 Settlement</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-settlement-n01">2.2.6.1 N01 - derives Store changes from collateral inputs and return without a separate declaration</a><br>
                <a href="#ds-collateral-settlement-p01">2.2.6.2 P01 - does not let ordinary Store declarations change collateral settlement</a><br>
                <a href="#ds-collateral-settlement-n02">2.2.6.3 N02 - settles multiple collateral inputs with no return output</a><br>
              </dd>
            </dl>
          </details>
          <details>
            <summary><a href="#ds-collateral-conservation">2.2.7 Conservation</a></summary>
            <dl>
              <dd>
                <a href="#ds-collateral-conservation-n01">2.2.7.1 N01 - conserves ADA across collateral inputs, return, Store and fees</a><br>
                <a href="#ds-collateral-conservation-p01">2.2.7.2 P01 - accepted phase-2 failure ⇒ collateralInputCoins + releasedUTxODeposits = collateralReturnCoins + collateralReturnUTxODeposit + collateralFee</a><br>
                <a href="#ds-collateral-conservation-f01">2.2.7.3 F01 - rejects a collateral native-asset imbalance</a><br>
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
          <a href="#ds-state-execution-p01">3.1.1 P01 - ordinary success ⇒ utxoAfter = (utxoBefore without regularInputs) union newRegularOutputsWithUTxODeposits</a><br>
          <a href="#ds-state-execution-n01">3.1.2 N01 - applies ordinary Store operations and leaves collateral untouched on success</a><br>
          <a href="#ds-state-execution-n02">3.1.3 N02 - applies collateral settlement and no ordinary Store operations on an accepted phase-2 failure</a><br>
          <a href="#ds-state-execution-n03">3.1.4 N03 - consumes only collateral inputs and creates only the specified collateral return in the UTxO on an accepted phase-2 failure</a><br>
          <a href="#ds-state-execution-n04">3.1.5 N04 - does not credit the settlement amount to the selected output a second time</a><br>
          <a href="#ds-state-execution-f01">3.1.6 F01 - leaves the entire ledger state unchanged on rejection, including UTxO, allocated deposit records and Store balance</a><br>
          <a href="#ds-state-execution-p02">3.1.7 P02 - batch rejected ⇒ acceptedLedgerStateAfter = acceptedLedgerStateBefore</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-allocations">3.2 Allocations</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-allocations-p01">3.2.1 P01 - ordinary success ⇒ releasedUTxODeposits = Σ(allocatedUTxODeposit(utxo[input])) over consumed store-backed inputs</a><br>
          <a href="#ds-state-allocations-n01">3.2.2 N01 - records the allocated UTxO capacity deposit alongside each newly created store-backed output</a><br>
          <a href="#ds-state-allocations-n02">3.2.3 N02 - removes a spent output's UTxO capacity deposit record and releases its UTxO capacity deposit exactly once</a><br>
          <a href="#ds-state-allocations-n03">3.2.4 N03 - keeps UTxO capacity deposit records unchanged when outputs are only referenced</a><br>
          <a href="#ds-state-allocations-n04">3.2.5 N04 - keeps Σ(live allocated UTxO capacity deposits) equal to outstanding UTxO capacity deposit obligations</a><br>
          <a href="#ds-state-allocations-n05">3.2.6 N05 - does not leave missing or orphan UTxO capacity deposit records after accepted transitions</a><br>
          <a href="#ds-state-allocations-n06">3.2.7 N06 - releases the allocated UTxO capacity deposit even when reserialization would change the output size</a><br>
          <a href="#ds-state-allocations-n07">3.2.8 N07 - does not release UTxO capacity deposits from the DepositStore when a translated implicit output is spent</a><br>
          <a href="#ds-state-allocations-p02">3.2.9 P02 - ordinary success ⇒ totalUTxODepositsAfter = totalUTxODepositsBefore + txTotalNetUTxODepositChange</a><br>
          <a href="#ds-state-allocations-n08">3.2.10 N08 - removes consumed store-backed collateral records and records the return only when store-backed, preserving records outside collateral inputs on an accepted phase-2 failure</a><br>
          <a href="#ds-state-allocations-p03">3.2.11 P03 - accepted phase-2 failure ⇒ totalUTxODepositsAfter = totalUTxODepositsBefore + collateralReturnUTxODeposit - releasedUTxODeposits</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-balance">3.3 Balance</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-balance-p01">3.3.1 P01 - ordinary success ⇒ storeBalanceAfter = storeBalanceBefore + txTotalNetUTxODepositChange</a><br>
          <a href="#ds-state-balance-n01">3.3.2 N01 - changes the balance by exactly the applied allocations minus releases</a><br>
          <a href="#ds-state-balance-p02">3.3.3 P02 - accepted phase-2 failure ⇒ storeBalanceAfter = storeBalanceBefore + collateralReturnUTxODeposit - releasedUTxODeposits</a><br>
          <a href="#ds-state-balance-p03">3.3.4 P03 - ordinary success ⇒ storeBalanceAfter - totalUTxODepositsAfter = storeBalanceBefore - totalUTxODepositsBefore</a><br>
          <a href="#ds-state-balance-n02">3.3.5 N02 - preserves pre-existing Store surplus across accepted ordinary transactions</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-solvency">3.4 Solvency</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-solvency-p01">3.4.1 P01 - ordinary success ⇒ storeBalanceAfter ≥ totalUTxODepositsAfter ≥ 0</a><br>
          <a href="#ds-state-solvency-n01">3.4.2 N01 - keeps the Store balance at least equal to outstanding UTxO capacity deposit obligations</a><br>
          <a href="#ds-state-solvency-f01">3.4.3 F01 - rejects a transition that would leave the Store insolvent</a><br>
          <a href="#ds-state-solvency-n02">3.4.4 N02 - checks the accepted batch result without requiring each SubTx to balance independently</a><br>
          <a href="#ds-state-solvency-n03">3.4.5 N03 - fixed pricing and a solvent initial state ⇒ epoch transitions preserve Store solvency</a><br>
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
          <a href="#ds-state-initialization-n01">3.6.1 N01 - preserves existing output references and values and keeps those outputs implicit</a><br>
          <a href="#ds-state-initialization-n02">3.6.2 N02 - initializes Store balance and UTxO capacity deposit obligations to zero</a><br>
          <a href="#ds-state-initialization-n03">3.6.3 N03 - does not transfer funds from another ledger pot during initialization</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-state-recovery">3.7 Recovery</a></summary>
      <dl>
        <dd>
          <a href="#ds-state-recovery-n01">3.7.1 N01 - preserves allocated UTxO capacity deposits through state serialization and restoration</a><br>
          <a href="#ds-state-recovery-n02">3.7.2 N02 - restores outputs, UTxO capacity deposit records and Store balance together on rollback</a><br>
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
          <a href="#ds-stake-n04">4.1.4 N04 - ordinary success ⇒ a net allocation changes stake only through its applied ordinary UTxO effects</a><br>
          <a href="#ds-stake-n05">4.1.5 N05 - ordinary success ⇒ a net release changes stake only through its applied ordinary UTxO effects</a><br>
          <a href="#ds-stake-n06">4.1.6 N06 - ordinary success ⇒ unapplied collateral settlement and collateral return add no stake effects</a><br>
          <a href="#ds-stake-n07">4.1.7 N07 - accepted phase-2 failure ⇒ stake follows collateral consumption and return without effects from unapplied ordinary allocations, releases or outputs</a><br>
          <a href="#ds-stake-n08">4.1.8 N08 - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects</a><br>
        </dd>
      </dl>
    </details>
    <details>
      <summary><a href="#ds-voting">4.2 Voting</a></summary>
      <dl>
        <dd>
          <a href="#ds-voting-n01">4.2.1 N01 - does not count allocated UTxO capacity deposits or Store balance as additional voting power</a><br>
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
> Store balance = funds · Allocated deposits = obligations.

| Quantity | Meaning |
| --- | --- |
| `storeBalance` | Actual ADA held in the DepositStore. |
| `allocatedUTxODeposit(output)` | Exact deposit recorded for an existing store-backed output. |
| `totalUTxODeposits(utxo)` | Sum of the deposits allocated to all live store-backed outputs. |

```text
totalUTxODeposits(utxo)
    = Σ allocatedUTxODeposit(output), over all live store-backed outputs
```

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
> Transaction = TopTx body + its SubTx bodies.

| Scope | Inputs and outputs | Declaration describes |
| --- | --- | --- |
| TopTx body | Its own regular inputs and outputs, excluding those of its SubTxs | The net deposit change of the complete transaction. |
| SubTx body | That SubTx's own regular inputs and outputs | Its net deposit contribution and whether accounting is local or delegated to TopTx. |
| Complete transaction | TopTx and every SubTx body, each counted once | The sum of all body contributions. |

Spent outputs are obtained by resolving the body's spending inputs against the
applicable UTxO. Reference inputs do not consume outputs or release deposits.
Collateral inputs and collateral return belong to the separate [Collateral](#ds-collateral)
path, outside these ordinary-activity quantities.

For each body:

```text
releasedUTxODeposits(body)
    = Σ recorded deposits of the body's consumed store-backed inputs

allocatedUTxODeposits(body)
    = Σ required deposits of the body's new store-backed outputs

netUTxODepositChange(body)
    = allocatedUTxODeposits(body) − releasedUTxODeposits(body)

txTotalNetUTxODepositChange
    = Σ netUTxODepositChange(body), over TopTx and all SubTx bodies
```

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

#### 1.4.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/PricingSpec.hs#L11) - ordinary success ⇒ newly recorded UTxO capacity deposit amounts equal coinsPerUTxOByte * (160 + acceptedSize) for store-backed outputs

Given accepted store-backed outputs under a fixed policy, independently calculate each allocation from its accepted serialized size and compare it with the ledger's recorded amount. The equation checks the price actually assigned, rather than comparing a pricing helper with itself.

<a id="ds-pricing-n01" name="ds-pricing-n01"></a>

#### 1.4.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/PricingSpec.hs#L12) - allocates each UTxO capacity deposit as coinsPerUTxOByte * (160 + accepted serialized output size)

Given a new store-backed output of known accepted size, expect its allocation to equal the byte price multiplied by that size plus 160. The external amount must fund the full storage requirement.

<a id="ds-pricing-n02" name="ds-pricing-n02"></a>

#### 1.4.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/PricingSpec.hs#L13) - uses the same UTxO capacity deposit formula for a store-backed collateral return

Given a store-backed collateral return, calculate its requirement from the same accepted-size formula used for an ordinary output. Its failure-path role changes when it is created, not the price of its storage.

<a id="ds-pricing-n03" name="ds-pricing-n03"></a>

#### 1.4.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/PricingSpec.hs#L14) - includes address, application assets, datum and reference script in the priced size

Given outputs with address, application assets, datum or reference-script contents, include the bytes and encoding overhead of every present component in the price. Optional contents can change the amount even when application ADA is unchanged.

<a id="ds-pricing-n04" name="ds-pricing-n04"></a>

#### 1.4.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/PricingSpec.hs#L15) - excludes the external UTxO capacity deposit amount and Store declaration from the priced output

Given finalized output contents, varying the external deposit accounting or body declaration must not add bytes to that output's priced size. Those amounts live outside the serialized output.

<a id="ds-pricing-n05" name="ds-pricing-n05"></a>

#### 1.4.6 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/PricingSpec.hs#L16) - handles CBOR size boundaries when an application coin amount changes

Given application coin amounts on opposite sides of a CBOR encoding-length boundary, price the resulting accepted output bytes in each case. A coin change can change storage size, so the previous output price cannot simply be reused.

<a id="ds-pricing-n06" name="ds-pricing-n06"></a>

#### 1.4.7 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/PricingSpec.hs#L17) - assigns no DepositStore obligation to implicit outputs

Given an implicit-deposit output, assign no external Store obligation. Its full coins remain in its value and its existing minimum-coin validation still applies.

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

Unless explicitly discussing collateral, these rules describe an ordinary successful
transaction under a fixed pricing policy. Existing ledger requirements still apply:
regular inputs exist in the original UTxO, cannot be spent twice, and new output
identifiers are fresh.

<a id="ds-tx-grammar" name="ds-tx-grammar"></a>

#### 2.1.1 Grammar

> **Define what can be declared.**
>
> Allocation, release or funding-request amount $> 0$ · Explicit zero has its own form.
> Presence determines whether a declaration is required; Exactness checks its amount.

**Decision:** Agreed.

SubTx declares zero contribution with its own explicit declaration pattern. All net allocations,
net releases and allocation-funding requests carry a strictly positive amount, including
releases delegated to TopTx:

| Explicit SubTx declaration | Amount and settlement |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | Zero, with no settlement target |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | `PositiveCoin`, accounted locally |
| `SubTx.RequestsUTxODepositFromTopTx amount` | `PositiveCoin`, funding delegated to TopTx |
| `SubTx.DeclaresNetUTxODepositRelease amount target` | `PositiveCoin` and a `SubTxReleaseTarget` |

`SubTx.DeclaresZeroNetUTxODeposit` contributes zero to both the SubTx's UTxO capacity
deposit contribution and its local accounting amount. It requests no delegation and has
no settlement output. It is distinct from `SubTx.NoUTxODepositDeclaration`: the latter
makes no declaration and fails DS-TX-PRESENCE-ACTIVITY when the SubTx creates or spends a store-backed
output.

For example, a SubTx spending and creating store-backed outputs with equal UTxO capacity
deposit obligations can explicitly declare zero, provided all other rules hold. This
does not bypass DS-TX-EXACTNESS-CONTRIBUTION exact accounting or DS-TX-EXACTNESS-CONTRIBUTION release when leaving
store-backed outputs. If either rule requires a nonzero contribution, an explicit zero
does not satisfy it.

`PositiveCoin` permits 1 through 18446744073709551615 lovelace, as for TopTx. Zero, negative and out-of-range operation amounts are invalid. In particular, zero cannot encode a net allocation, an allocation-funding
request or a net release.

The [encoding reference](#declaration-encoding) specifies the CBOR/JSON forms and links
to their codec checks. Presence, exactness and conservation determine whether an
expressed declaration is valid in its transaction.

<a id="ds-tx-grammar-n01" name="ds-tx-grammar-n01"></a>

##### 2.1.1.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/GrammarSpec.hs#L11) - does not interpret an explicit SubTx zero as a delegation request

Explicit zero expresses no contribution and no delegation request. Its presence can trigger TopTx’s declaration dependency without requesting funds or a settlement output.

<a id="ds-tx-presence" name="ds-tx-presence"></a>

#### 2.1.2 Presence

> **Determine when a body must declare a change.**
>
> - **Activity:** its own use of the Store.
> - **Dependency:** a SubTx declaration requiring TopTx to declare.

<a id="ds-tx-presence-activity" name="ds-tx-presence-activity"></a>

##### 2.1.2.1 Activity

> **Require a declaration for the body’s own Store activity.**
>
> Creates or spends a store-backed output $\implies$ own declaration required.

**Decision:** Agreed.

A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change.

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

```text
createsStoreBackedOutput(body) ∨ spendsStoreBackedOutput(body)
    ⇒ hasDeclaration(body)
```

Equivalently:

```text
NOT hasDeclaration(body)
    ⇒ every element of outputs(body) and spentOutputs(body)
        is an ImplicitDepositTxOut
```

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
  funding requirement is zero. TopTx expresses this with
  `TopTx.DeclaresZeroNetUTxODeposit`; SubTx uses `SubTx.DeclaresZeroNetUTxODeposit`
  under DS-TX-GRAMMAR.

<a id="ds-tx-presence-activity-p01" name="ds-tx-presence-activity-p01"></a>

###### 2.1.2.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/ActivitySpec.hs#L13) - A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change.

For every body, creating or spending at least one store-backed ordinary output requires an explicit declaration in that body: (hasStoreBackedOwnOutput ∨ spendsStoreBackedOutput) ⇒ hasOwnDeclaration. Parent or child declarations do not substitute for it. This universal creation-and-spending assertion remains a placeholder; implemented creation checks cover only its creation part.

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

<a id="ds-tx-presence-activity-creation-n01" name="ds-tx-presence-activity-creation-n01"></a>

**2.1.2.1.2.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L42) - accepts every explicit TopTx and SubTx declaration for creation presence, including zero and delegation**

Every explicit declaration counts as present, including zero, allocation, release, and SubTx delegation. With store-backed own outputs, the isolated creation validator therefore returns Success (). This establishes presence only; it does not establish that the declared amount, funding, or settlement is correct.

<a id="ds-tx-presence-activity-creation-n02" name="ds-tx-presence-activity-creation-n02"></a>

**2.1.2.1.2.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L59) - accepts absent declarations for empty or implicit-only own outputs**

An empty or implicit-only own output sequence does not trigger the creation requirement: hasStoreBackedOwnOutput = false. The isolated TopTx and SubTx creation validators accept an absent declaration. Spending activity is checked separately.

<a id="ds-tx-presence-activity-creation-f01" name="ds-tx-presence-activity-creation-f01"></a>

**2.1.2.1.2.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L68) - rejects a missing own declaration when a store-backed output appears at any own-output position**

One store-backed own output is enough to require the body's declaration, wherever that output appears among implicit outputs. For TopTx and SubTx alike, storeBackedOwnOutput ∧ absentOwnDeclaration produces MissingBodyUTxODepositDeclaration in the isolated validator.

<a id="ds-tx-presence-activity-creation-n03" name="ds-tx-presence-activity-creation-n03"></a>

**2.1.2.1.2.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L78) - accepts a TopTx creating only implicit outputs without a declaration**

A TopTx creating only implicit outputs is accepted by the ledger without a Store declaration when its ordinary inputs, fees, and witnesses are valid. This is the full-ledger control for the TopTx creation rejection.

<a id="ds-tx-presence-activity-creation-n04" name="ds-tx-presence-activity-creation-n04"></a>

**2.1.2.1.2.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L82) - accepts a SubTx creating only implicit outputs without either body's declaration**

A SubTx creating only implicit outputs is accepted within a ledger transaction when neither level declares a Store operation. Ordinary transaction preparation supplies valid funding and witnesses; no Store allocation is created.

<a id="ds-tx-presence-activity-creation-f02" name="ds-tx-presence-activity-creation-f02"></a>

**2.1.2.1.2.6 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L86) - rejects a TopTx creating a store-backed output without its own declaration**

The ledger rejects a TopTx whose own ordinary outputs include a store-backed output while its declaration is absent. The expected failure is MissingUTxODepositDeclaration, and the rejected transaction leaves ledger state unchanged. Empty application assets do not remove the new output's capacity obligation.

<a id="ds-tx-presence-activity-creation-f03" name="ds-tx-presence-activity-creation-f03"></a>

**2.1.2.1.2.7 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L90) - rejects a SubTx creating a store-backed output without its own declaration**

The ledger rejects a SubTx that creates a store-backed own output without a SubTx declaration. The expected failure is SubMissingUTxODepositDeclaration, and rejection leaves ledger state unchanged. Declaration presence is required independently for the creating body.

<a id="ds-tx-presence-activity-creation-f04" name="ds-tx-presence-activity-creation-f04"></a>

**2.1.2.1.2.8 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L94) - rejects a TopTx creating a store-backed output without its own declaration even when phase 2 fails**

A real failing phase-2 script does not waive TopTx's structural declaration requirement. Even with the transaction marked phase-2 invalid, creating a store-backed own output without a declaration yields MissingUTxODepositDeclaration and leaves the ledger unchanged.

<a id="ds-tx-presence-activity-creation-f05" name="ds-tx-presence-activity-creation-f05"></a>

**2.1.2.1.2.9 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L98) - rejects a SubTx creating a store-backed output without its own declaration even when phase 2 fails**

A real phase-2 failure does not waive a creating SubTx's declaration requirement. The ledger still returns SubMissingUTxODepositDeclaration for the undeclared store-backed own output; the rejected transaction applies no state changes.

<a id="ds-tx-presence-activity-creation-f06" name="ds-tx-presence-activity-creation-f06"></a>

**2.1.2.1.2.10 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/CreationSpec.hs#L103) - rejects a missing allocation declaration when spending a translated implicit output to create store-backed outputs**

Start with an implicit output preserved by the Conway transition and create a store-backed output. Its historical origin does not waive the new output’s declaration requirement.

<a id="ds-tx-presence-activity-spending" name="ds-tx-presence-activity-spending"></a>

###### 2.1.2.1.3 Spending

> **Check declaration presence when the body consumes outputs.**
>
> Spending a store-backed input releases its recorded deposit, even when no new store-backed output is created.

**Decision:** Agreed.

Resolve the body's own spending inputs against the live UTxO. Consuming a
store-backed output requires that body's declaration, even if it creates no new
store-backed output. Its signed amount must then account for the released deposit.
The acceptance controls must also satisfy exactness and every other ledger requirement.

<a id="ds-tx-presence-activity-spending-n01" name="ds-tx-presence-activity-spending-n01"></a>

**2.1.2.1.3.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/SpendingSpec.hs#L11) - accepts a TopTx spending a store-backed input with its own declaration**

TopTx consumes a store-backed input and supplies its own exact declaration. This is the positive control for removing that declaration while leaving its spending activity unchanged.

<a id="ds-tx-presence-activity-spending-n02" name="ds-tx-presence-activity-spending-n02"></a>

**2.1.2.1.3.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/SpendingSpec.hs#L12) - accepts a SubTx spending a store-backed input with its own declaration**

A SubTx consuming a store-backed input supplies its own declaration. Its TopTx dependency, amounts and remaining ledger requirements must also hold in the acceptance fixture.

<a id="ds-tx-presence-activity-spending-f01" name="ds-tx-presence-activity-spending-f01"></a>

**2.1.2.1.3.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/SpendingSpec.hs#L13) - rejects a TopTx spending a store-backed input without a declaration**

Keep the store-backed spending input and remove only TopTx’s declaration from an otherwise valid transaction. The release cannot become an undeclared Store operation.

<a id="ds-tx-presence-activity-spending-f02" name="ds-tx-presence-activity-spending-f02"></a>

**2.1.2.1.3.4 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/SpendingSpec.hs#L14) - rejects a SubTx spending a store-backed input without its own declaration**

The SubTx owns this spending activity. A declaration elsewhere in the transaction cannot replace its missing declaration.

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

**2.1.2.1.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs#L39) - accepts an absent TopTx declaration for creation presence when only its nested SubTx creates store-backed outputs**

Nested SubTx outputs are not TopTx's own outputs. The TopTx creation validator therefore accepts an absent TopTx declaration when only the explicitly declared SubTx creates store-backed outputs. This is isolated-validator success: the separate dependency rule still requires TopTx to declare when a SubTx declares.

<a id="ds-tx-presence-activity-scope-n02" name="ds-tx-presence-activity-scope-n02"></a>

**2.1.2.1.4.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs#L45) - accepts an absent declaration for creation presence when only collateral return is store-backed**

Collateral return is outside the body's ordinary created-output sequence. A store-backed collateral return alone does not trigger the creation-presence validator. This does not establish that the collateral return satisfies its separate declaration, funding, or settlement rules.

<a id="ds-tx-presence-activity-scope-n03" name="ds-tx-presence-activity-scope-n03"></a>

**2.1.2.1.4.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs#L47) - accepts an absent declaration for creation presence with reference or collateral input identifiers alone**

Reference and collateral input identifiers are not created outputs, so their presence alone does not trigger the creation-presence validator. This fixture does not resolve those identifiers to UTxOs and does not establish the complete reference-input or collateral rules.

<a id="ds-tx-presence-activity-scope-f01" name="ds-tx-presence-activity-scope-f01"></a>

**2.1.2.1.4.4 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs#L49) - rejects a missing TopTx declaration for its own store-backed outputs even when its nested SubTx declares**

A nested SubTx's explicit declaration cannot satisfy TopTx's own requirement. When TopTx creates store-backed own outputs and declares nothing, its isolated creation validator returns MissingBodyUTxODepositDeclaration even though the nested SubTx declares.

<a id="ds-tx-presence-activity-scope-f02" name="ds-tx-presence-activity-scope-f02"></a>

**2.1.2.1.4.5 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs#L56) - rejects a creating SubTx's missing declaration even when TopTx explicitly declares zero**

A TopTx declaration cannot substitute for its SubTx's missing declaration. The ledger rejects the creating SubTx with SubMissingUTxODepositDeclaration even when TopTx explicitly declares zero, and preserves ledger state. The parent's zero is not presented as funding a new Store obligation.

<a id="ds-tx-presence-activity-scope-n04" name="ds-tx-presence-activity-scope-n04"></a>

**2.1.2.1.4.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs#L61) - does not require a declaration merely for referencing a store-backed output**

Referencing a store-backed output neither consumes it nor releases its allocated deposit. Reference-only use therefore does not trigger ordinary declaration presence.

<a id="ds-tx-presence-activity-scope-n05" name="ds-tx-presence-activity-scope-n05"></a>

**2.1.2.1.4.7 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs#L62) - does not treat collateral inputs or collateral return as ordinary Store activity**

Collateral inputs and collateral return are evaluated by the separate collateral rules. Their presence alone must not be interpreted as ordinary body activity.

<a id="ds-tx-presence-activity-scope-n06" name="ds-tx-presence-activity-scope-n06"></a>

**2.1.2.1.4.8 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs#L63) - accepts Store activity in both TopTx and SubTx when each provides its own declaration**

Both bodies have Store activity and both declare it. Each declaration must meet its own presence obligation; the acceptance fixture also satisfies dependency and amount rules.

<a id="ds-tx-presence-activity-scope-f03" name="ds-tx-presence-activity-scope-f03"></a>

**2.1.2.1.4.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/Activity/ScopeSpec.hs#L64) - does not let a SubTx declaration replace a missing TopTx declaration**

TopTx has its own Store activity. Its SubTx’s declaration cannot stand in for the declaration missing from TopTx.

<a id="ds-tx-presence-dependency" name="ds-tx-presence-dependency"></a>

##### 2.1.2.2 Dependency

> **Require TopTx to acknowledge the total whenever a SubTx declares.**
>
> Any SubTx declaration $\implies$ TopTx declaration. The amount is checked separately.

**Decision:** Agreed.

**Executable spec:** [DependencySpec.hs](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs)

Categories, case titles and order match the executable spec. Each linked test ID
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

**2.1.2.2.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L60) - any SubTx has a declaration ⇒ TopTx has a declaration**

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

**2.1.2.2.2.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L65) - accepts absent declarations at both levels**

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

**2.1.2.2.2.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L69) - accepts explicit zero at both levels**

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

**2.1.2.2.2.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L73) - accepts TopTx zero without a SubTx declaration**

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

**2.1.2.2.2.4 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L77) - rejects SubTx zero without a TopTx declaration**

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
\mathrm{declaredNetContribution}(\mathit{subTx}) \\
&\qquad=\mathit{declaredAmount}-\mathit{declaredAmount}=0
\end{aligned}
$$

These properties validate declarations directly. They do not fund operations, construct
a settlement output or exercise a Store transfer. In the formulas below,
$\mathit{declaredAmount}\in\mathsf{PositiveCoin}$.

<a id="ds-tx-presence-dependency-c03-n01" name="ds-tx-presence-dependency-c03-n01"></a>

**2.1.2.2.3.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L83) - passes declaration presence with TopTx declaring the zero net amount**

$$
\begin{gathered}
\forall \mathit{declaredAmount}\in\mathsf{PositiveCoin}: \\
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

**2.1.2.2.3.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L86) - rejects an absent TopTx declaration despite the zero net amount**

$$
\begin{gathered}
\forall \mathit{declaredAmount}\in\mathsf{PositiveCoin}: \\
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

**2.1.2.2.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L91) - passes declaration presence with TopTx zero for every explicit SubTx form**

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

**2.1.2.2.4.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L97) - rejects an absent TopTx declaration for every explicit SubTx form**

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

**2.1.2.2.5.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L106) - accepts zero declarations at both levels on the phase-2 failure path**

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

**2.1.2.2.5.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Presence/DependencySpec.hs#L110) - rejects SubTx zero without a TopTx declaration on the phase-2 failure path**

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

Each TopTx and SubTx body must account exactly for its own change in UTxO capacity deposit
obligations. Reject both an excessive and an insufficient contribution, even when
another body's opposite error makes the batch total correct. This UTxO capacity deposit
accounting condition is separate from financial conservation: SubTx may be financially
imbalanced, but the completed TopTx batch must balance.

For each body, define:

- `releasedUTxODeposits(body)`: sum of allocated UTxO capacity deposits released by
  consuming that body's store-backed inputs under the agreed pricing and release
  policy. This is not the Store's global available balance.
- `allocatedUTxODeposits(body)`: UTxO capacity deposits required for that body's own newly created
  store-backed outputs.
- `declaredNetContribution(body)`: the signed contribution attributable to that
  body, with net allocations positive and net releases negative.

Require:

```text
releasedUTxODeposits(body) + declaredNetContribution(body)
    = allocatedUTxODeposits(body)
```

Equivalently, separating positive net allocations and net releases:

```text
releasedUTxODeposits(body) + declaredNetAllocation(body)
    = allocatedUTxODeposits(body) + declaredNetRelease(body)
```

Thus `declaredNetContribution(body)` must equal `allocatedUTxODeposits(body) -
releasedUTxODeposits(body)`. Positive differences require an exact net allocation,
negative differences require an exact net release, and zero requires a zero
contribution, subject to the declaration-presence rules.

For example, when a body releases no UTxO capacity deposits and creates outputs requiring 2
ADA, declaring a net allocation of 3 ADA is an accounting error. A net allocation of 1
ADA also fails; the correct contribution is exactly 2 ADA. The remaining transaction
funds may be placed in regular outputs under the financial balance rules.

For SubTx, use the declared contribution regardless of accounting delegation:

| SubTx declaration | Contribution for that SubTx's UTxO capacity deposit accounting |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | `0`; the exact UTxO capacity deposit accounting and release rules still apply |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | `+amount` |
| `SubTx.RequestsUTxODepositFromTopTx amount` | `+amount` |
| `SubTx.DeclaresNetUTxODepositRelease amount target` | `-amount`, for either target |
| `SubTx.NoUTxODepositDeclaration` | `0`; DS-TX-PRESENCE-ACTIVITY rejects absence if the body creates or spends any store-backed output |

For TopTx's own UTxO capacity deposit accounting, remove all SubTx contributions from the
declared batch net change, including contributions delegated to TopTx:

```text
declaredNetContribution(TopTx)
    = txTotalNetUTxODepositChange
        - sum(declaredNetContribution(subTx))
```

This is the contribution attributable to TopTx's own activity, not the financial amount
accounted for in TopTx, which also includes delegated contributions. Each declared
contribution is counted at its full amount. An allocation-funding request counts toward
the originating SubTx's declared UTxO capacity deposit contribution, but acceptance also
requires its funding to be fulfilled in the batch accounting. Passing this equality
alone does not establish financial balance or a valid settlement output. Summing the
exact body contributions gives the batch requirement:

```text
txTotalNetUTxODepositChange = sum(allocatedUTxODeposits(body) - releasedUTxODeposits(body))
```

The sum includes TopTx's own activity and every SubTx body exactly once, regardless of
delegation.

For example, SubTx A releases no UTxO capacity deposits, creates outputs requiring 3 ADA and
declares a net allocation of 5 ADA. SubTx B also releases none and creates outputs
requiring 3 ADA, but declares only 1 ADA. Both fail this exact accounting check. The
batch must be rejected even though the combined net allocation of 6 ADA equals the
combined requirement. Each SubTx must explicitly declare exactly 3 ADA, locally or
through a request to TopTx.

DS-PRICING defines the pricing formula and allocated UTxO capacity deposits for the current
scope. Voluntary excess net allocations through these operations are not permitted. The
current scope assumes a constant `coinsPerUTxOByte`; DS-PRICING-HISTORY records the agreed
historical-recoverability requirement and deferred handling of parameter changes.
Collateral has its own requirements under DS-COLLATERAL; DS-STATE-EXECUTION selects
when its effects apply.

When a body spends store-backed outputs and creates no new store-backed outputs, it must
explicitly account for a net release equal to the released UTxO capacity deposits. Omitting
the declaration or allocating a zero contribution to that body does not satisfy this
rule. Released UTxO capacity deposits must not silently remain in the store in this case.

```text
spendsStoreBackedOutput(body) AND NOT hasStoreBackedOutput(body)
    ⇒ declaredNetContribution(body) = -releasedUTxODeposits(body)
```

The released amount is the sum of UTxO capacity deposits allocated to the consumed
store-backed outputs under DS-PRICING. This rule does not grant access to unrelated
store surplus. It applies to bodies creating only implicit-deposit outputs, as well as
bodies creating no outputs; a release's target must still satisfy the settlement rules.

For SubTx, the net-release contribution is declared with
`SubTx.DeclaresNetUTxODepositRelease amount target`, including explicit delegation when
TopTx accounts for it. For TopTx's own activity, the contribution is derived as in
DS-TX-EXACTNESS-CONTRIBUTION. The TopTx field continues to declare the entire batch's net change, so it may
declare a net allocation or explicit zero when other contributions offset the release.
This does not erase the body's net-release contribution.

For example, a SubTx releasing 3 ADA of UTxO capacity deposits and creating only
implicit-deposit outputs declares a net release of 3 ADA. If another SubTx contributes a
5 ADA net allocation and TopTx has no own contribution, TopTx declares
`TopTx.DeclaresNetUTxODepositAllocation 2`. The store receives 2 ADA net; no separate
payment for the gross release is required.

<a id="ds-tx-exactness-contribution-p01" name="ds-tx-exactness-contribution-p01"></a>

###### 2.1.3.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L11) - ∀ s ∈ SubTxs: hasDeclaration(s) ⇒ declaredNetUTxODepositChange(s) = allocatedUTxODeposits(s) - releasedUTxODeposits(s)

For every declared SubTx, compare its signed contribution with its own newly allocated deposits minus the recorded deposits released by its inputs. Delegation leaves this equality unchanged.

<a id="ds-tx-exactness-contribution-n01" name="ds-tx-exactness-contribution-n01"></a>

###### 2.1.3.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L12) - accepts a contribution equal to allocated UTxO capacity deposits minus released UTxO capacity deposits

The body supplies exactly the difference between new obligations and released allocations. Subject to the other rules, this is the positive control for under- and over-declaration.

<a id="ds-tx-exactness-contribution-f01" name="ds-tx-exactness-contribution-f01"></a>

###### 2.1.3.1.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L13) - rejects a net allocation one lovelace below the required contribution

Start from an exact net allocation and reduce the declaration by one lovelace. The resulting declaration must fail even if the overall Store remains solvent.

<a id="ds-tx-exactness-contribution-f02" name="ds-tx-exactness-contribution-f02"></a>

###### 2.1.3.1.4 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L14) - rejects a net allocation one lovelace above the required contribution

Increase an exact net allocation by one lovelace. Voluntary overpayment is an accounting error, not an additional refundable deposit.

<a id="ds-tx-exactness-contribution-f03" name="ds-tx-exactness-contribution-f03"></a>

###### 2.1.3.1.5 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L15) - rejects a net release one lovelace below the required contribution

Reduce the declared net release by one lovelace while keeping the consumed and created outputs fixed. The declaration no longer accounts exactly for the released obligation.

<a id="ds-tx-exactness-contribution-f04" name="ds-tx-exactness-contribution-f04"></a>

###### 2.1.3.1.6 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L16) - rejects a net release one lovelace above the required contribution

Increase the declared release by one lovelace. Available Store surplus does not authorize withdrawing more than the body actually releases.

<a id="ds-tx-exactness-contribution-f05" name="ds-tx-exactness-contribution-f05"></a>

###### 2.1.3.1.7 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L17) - rejects opposing declaration errors even when they cancel in the batch total

One body overstates its contribution while another understates by the same amount. Their total can be correct, but neither body’s exactness failure is repaired by that cancellation.

<a id="ds-tx-exactness-contribution-n02" name="ds-tx-exactness-contribution-n02"></a>

###### 2.1.3.1.8 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L18) - checks TopTx's own UTxO capacity deposit contribution separately from SubTx contributions

Derive TopTx’s own contribution by removing all SubTx contributions from the declared total, including delegated contributions. Compare the remainder with TopTx’s own input and output obligations.

<a id="ds-tx-exactness-contribution-n03" name="ds-tx-exactness-contribution-n03"></a>

###### 2.1.3.1.9 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L19) - accepts an explicit zero when the declared UTxO capacity deposit contribution is zero

When new allocations equal released deposits, explicit zero describes the contribution exactly. Any presence obligation is still met by this explicit declaration.

<a id="ds-tx-exactness-contribution-f06" name="ds-tx-exactness-contribution-f06"></a>

###### 2.1.3.1.10 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L20) - rejects an explicit zero when a net allocation must be funded

The body requires a positive additional allocation. An explicit-zero declaration establishes presence but fails the amount equality.

<a id="ds-tx-exactness-contribution-n04" name="ds-tx-exactness-contribution-n04"></a>

###### 2.1.3.1.11 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L21) - checks a delegated net allocation against the requesting SubTx's exact net UTxO capacity deposit change

A request to TopTx changes who accounts for the allocation. The requested positive amount must still equal the requesting SubTx’s allocations minus its releases.

<a id="ds-tx-exactness-contribution-n05" name="ds-tx-exactness-contribution-n05"></a>

###### 2.1.3.1.12 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L22) - checks a delegated net release against the originating SubTx's exact net UTxO capacity deposit change

Delegating the release does not permit releasing unrelated Store funds. Its amount must equal the originating SubTx’s releases minus its new allocations.

<a id="ds-tx-exactness-contribution-n06" name="ds-tx-exactness-contribution-n06"></a>

###### 2.1.3.1.13 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L23) - requires a net release when a body spends store-backed outputs and creates only implicit outputs

The body consumes store-backed inputs and creates only implicit outputs. Its new Store obligation is zero, so its contribution must release the exact recorded deposits consumed.

<a id="ds-tx-exactness-contribution-f07" name="ds-tx-exactness-contribution-f07"></a>

###### 2.1.3.1.14 [F07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L24) - rejects an explicit zero when that body must release UTxO capacity deposits

Consumed inputs release a positive amount and no new store-backed outputs absorb it. Explicit zero cannot silently retain those released obligations in the Store.

<a id="ds-tx-exactness-contribution-n07" name="ds-tx-exactness-contribution-n07"></a>

###### 2.1.3.1.15 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L25) - preserves that body's net release even when another body's net allocation offsets it

Another body’s allocation may offset this release in the transaction total. The releasing body still declares its own exact negative contribution.

<a id="ds-tx-exactness-contribution-n08" name="ds-tx-exactness-contribution-n08"></a>

###### 2.1.3.1.16 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L26) - still requires the exact UTxO capacity deposit for an output with no application assets

Removing all application assets does not remove the address, encoding overhead or fixed 160-byte charge. The declared contribution must still cover the exact required allocation.

<a id="ds-tx-exactness-contribution-n09" name="ds-tx-exactness-contribution-n09"></a>

###### 2.1.3.1.17 [N09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L27) - accepts spending a translated implicit output to create store-backed outputs with the exact declared allocation and batch funding

Coins from a translated implicit output can fund a new store-backed output. The new allocation is declared exactly; spending the implicit input releases no Store deposit.

<a id="ds-tx-exactness-contribution-f08" name="ds-tx-exactness-contribution-f08"></a>

###### 2.1.3.1.18 [F08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L28) - rejects an inexact allocation when spending a translated implicit output to create store-backed outputs

Use a translated implicit input to fund a new store-backed output, but change the required allocation amount. Era history does not relax exact contribution accounting.

<a id="ds-tx-exactness-contribution-f09" name="ds-tx-exactness-contribution-f09"></a>

###### 2.1.3.1.19 [F09](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/ContributionSpec.hs#L29) - rejects an unrelated release from pre-existing Store surplus

An existing Store surplus belongs to no additional deposit released by this body. Reject a declaration that tries to release that surplus even when the resulting Store would remain solvent.

<a id="ds-tx-exactness-netting" name="ds-tx-exactness-netting"></a>

##### 2.1.3.2 Netting

> **Combine all body contributions into one TopTx declaration.**
>
> $\mathrm{txTotalNetUTxODepositChange} = \sum_{\mathit{body}} \mathrm{netUTxODepositChange}(\mathit{body})$. Each contribution appears once.

**Decision:** Agreed.

TopTx declares one signed net change for the complete transaction, including its
own contribution and every SubTx contribution exactly once:

$$
\mathrm{txTotalNetUTxODepositChange}
= \sum_{\mathit{body}\in\mathrm{bodies}(\mathit{tx})}
\mathrm{netUTxODepositChange}(\mathit{body})
$$

Delegation leaves this total unchanged. It changes the body responsible for accounting
for a contribution under DS-TX-ATTRIBUTION. Per-body exactness remains mandatory even
when two errors cancel in this sum.

| Allocations | Releases | Net declaration | Applied Store change |
| --- | --- | --- | --- |
| 5 ADA | 3 ADA | Allocate 2 ADA | +2 ADA |
| 3 ADA | 5 ADA | Release 2 ADA | −2 ADA |
| 5 ADA | 5 ADA | Explicit zero | 0 ADA |

These examples use ADA for readability; interface amounts use lovelace. Presence
rules determine when an explicit declaration is required. Net zero does not turn an
explicit declaration into absence.

The declared total is the Store transfer for the transaction, not an additional
transfer to add to its SubTx contributions. A 3 ADA release delegated to TopTx can
offset a 5 ADA local allocation: the resulting Store transfer is a 2 ADA allocation,
with no separate 3 ADA payment from the Store.

<a id="ds-tx-exactness-netting-p01" name="ds-tx-exactness-netting-p01"></a>

###### 2.1.3.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/NettingSpec.hs#L11) - declared TopTx: declaredNetUTxODepositChange = Σ(netUTxODepositChange) over all bodies

Sum the signed changes from TopTx’s own activity and every SubTx exactly once. TopTx’s declared total must equal that sum regardless of delegation.

<a id="ds-tx-exactness-netting-n01" name="ds-tx-exactness-netting-n01"></a>

###### 2.1.3.2.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/NettingSpec.hs#L12) - includes both TopTx and SubTx UTxO capacity deposit changes in the declared total

TopTx can create and consume outputs of its own. Its declaration must include that contribution as well as its SubTx contributions.

<a id="ds-tx-exactness-netting-n02" name="ds-tx-exactness-netting-n02"></a>

###### 2.1.3.2.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/NettingSpec.hs#L13) - nets a 5 ADA allocation and a 3 ADA release into AllocateUTxODeposit 2

Allocating 5 ADA and releasing 3 ADA yields a single 2 ADA net allocation. Successful application increases the Store by 2 ADA; there is no separate 3 ADA gross payment.

<a id="ds-tx-exactness-netting-n03" name="ds-tx-exactness-netting-n03"></a>

###### 2.1.3.2.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/NettingSpec.hs#L14) - nets a 3 ADA allocation and a 5 ADA release into ReleaseUTxODeposit 2

Allocating 3 ADA and releasing 5 ADA yields a single 2 ADA net release. The settlement choice is checked separately from this total.

<a id="ds-tx-exactness-netting-n04" name="ds-tx-exactness-netting-n04"></a>

###### 2.1.3.2.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Exactness/NettingSpec.hs#L15) - uses NoUTxODepositChange when allocations and releases cancel exactly

Equal allocation and release contributions produce a zero net transfer. When a declaration is required, use the explicit-zero form rather than omit the field.

<a id="ds-tx-attribution" name="ds-tx-attribution"></a>

#### 2.1.4 Attribution

> **Determine which body accounts for a contribution.**
>
> Local SubTx operation $\longrightarrow$ SubTx · Delegated SubTx operation $\longrightarrow$ TopTx. The required amount and transaction total remain unchanged.

**Decision:** Agreed.

| SubTx declaration | Contribution attributed locally |
| --- | --- |
| Explicit zero | 0 |
| Local allocation of `amount` | +amount |
| Local release of `amount` | −amount |
| Allocation requested from TopTx | 0; TopTx accounts for it |
| Release delegated to TopTx | 0; TopTx accounts for it |
| Absent declaration | 0; presence requirements still apply |

```text
topTxNetUTxODepositChange
    = txTotalNetUTxODepositChange − Σ(subTxLocalNetUTxODepositChanges)
```

TopTx's attributed amount includes delegated contributions. Its **own** contribution
under DS-TX-EXACTNESS-CONTRIBUTION instead removes all SubTx contributions, including
delegated ones, from the total. These two quantities must not be confused.

With a 3 ADA SubTx allocation and a 2 ADA contribution from TopTx's own outputs:

| SubTx accounting | TopTx declares | Accounted in SubTx | Accounted in TopTx |
| --- | --- | --- | --- |
| Local | Allocate 5 ADA | 3 ADA | 2 ADA |
| Delegated | Allocate 5 ADA | 0 ADA | 5 ADA |

For allocation-only transactions this gives:

```text
txTotalNetUTxODepositChange
    = ownTopTxNetAllocation + Σ(localSubTxNetAllocations) + Σ(delegatedSubTxNetAllocations)
topTxNetUTxODepositChange
    = ownTopTxNetAllocation + Σ(delegatedSubTxNetAllocations)
```

Attribution can have a different sign from the transaction total: a local SubTx
allocation of 5 ADA and a delegated release of 3 ADA attribute +5 to SubTx and −3
to TopTx, while TopTx declares a net allocation of 2 ADA.

Local accounting does not require independent SubTx financial balance. Delegation
requests still require exact originating contributions, sufficient batch funding,
a TopTx declaration and valid settlement where applicable. Those predicates remain
in Exactness, Conservation, Presence and Settlement respectively.

<a id="ds-tx-attribution-p01" name="ds-tx-attribution-p01"></a>

##### 2.1.4.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AttributionSpec.hs#L11) - topTxNetUTxODepositChange + Σ(subTxLocalNetUTxODepositChanges) = txTotalNetUTxODepositChange

Add the amount attributed to TopTx to the contributions accounted locally by SubTx bodies. The sum must recover the transaction total without dropping or duplicating delegated contributions.

<a id="ds-tx-attribution-p02" name="ds-tx-attribution-p02"></a>

##### 2.1.4.2 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AttributionSpec.hs#L12) - switching between local accounting and delegation preserves txTotalNetUTxODepositChange

Switch only the accounting responsibility between a SubTx and TopTx. Its originating outputs and required deposit change remain identical, so the transaction total must remain identical.

<a id="ds-tx-attribution-n01" name="ds-tx-attribution-n01"></a>

##### 2.1.4.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AttributionSpec.hs#L13) - counts delegated funding once in TopTx accounting

A delegated request is already a contribution to the transaction total. Attribute it to TopTx without adding a second Store allocation for the same request.

<a id="ds-tx-attribution-n02" name="ds-tx-attribution-n02"></a>

##### 2.1.4.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AttributionSpec.hs#L14) - keeps the same batch net change when a SubTx delegates funding of its net allocation

Changing a SubTx allocation from local accounting to a TopTx request leaves the required Store transfer unchanged. Only the attribution changes.

<a id="ds-tx-attribution-n03" name="ds-tx-attribution-n03"></a>

##### 2.1.4.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AttributionSpec.hs#L15) - allows a SubTx spending its final store-backed inputs and creating no outputs to explicitly delegate the release to TopTx

A SubTx can consume its store-backed inputs without creating outputs and explicitly delegate its release. Settlement and batch funding are then handled according to TopTx attribution.

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

```text
txTotalNetRelease = max(0, -txTotalNetUTxODepositChange)

consumedValue(batch) + inject(txTotalNetRelease)
    = producedValue(batch) + inject(max(0, txTotalNetUTxODepositChange))
```

`txTotalNetUTxODepositChange` is positive for `TopTx.DeclaresNetUTxODepositAllocation`,
negative for `TopTx.DeclaresNetUTxODepositRelease`, and zero for
`TopTx.DeclaresZeroNetUTxODeposit`. `txTotalNetRelease` is the amount in TopTx's
`TopTx.DeclaresNetUTxODepositRelease`, or zero otherwise. Absence of a declaration is
subject to the separate presence and reconciliation rules.

Consumed and produced values include the complete batch's inputs, outputs and other
existing ledger terms, including fees and existing deposit/refund rules. The net store
amount is counted once, using TopTx's declaration; SubTx store contributions are not
added again. This equality preserves all assets, whereas DS-TX-EXACTNESS-CONTRIBUTION concerns exact ADA
UTxO capacity deposit accounting for each body.



A local release does not prohibit a SubTx from exporting ADA to fund TopTx fees
or another body. The derived accounting quantity is:

```text
netADAExport = ordinaryConsumedADA + localRelease - ordinaryProducedADA
```

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

##### 2.1.5.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L11) - consumedValue + inject(max(0, -txTotalNetUTxODepositChange)) = producedValue + inject(max(0, txTotalNetUTxODepositChange))

Compare the complete consumed and produced values, adding the signed Store transfer once on the appropriate side. This equality applies to ADA and native assets.

<a id="ds-tx-conservation-p02" name="ds-tx-conservation-p02"></a>

##### 2.1.5.2 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L12) - ledger acceptance agrees with the model even when individual SubTxs are financially imbalanced

Generate individually imbalanced SubTx bodies whose combined transaction can balance. Acceptance must agree with the whole-transaction model rather than require each SubTx to fund itself.

<a id="ds-tx-conservation-n01" name="ds-tx-conservation-n01"></a>

##### 2.1.5.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L13) - counts the net allocation once on the produced side

A positive net Store allocation is part of produced value. SubTx contributions already included in the TopTx total must not be added again.

<a id="ds-tx-conservation-n02" name="ds-tx-conservation-n02"></a>

##### 2.1.5.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L14) - counts the net release once on the consumed side

A net release supplies consumed value to the transaction. Adding both the TopTx total and its SubTx release contributions would create an erroneous second credit.

<a id="ds-tx-conservation-n03" name="ds-tx-conservation-n03"></a>

##### 2.1.5.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L15) - accepts financially imbalanced SubTxs when the complete batch balances

A surplus in one body can fund another body. This remains valid when all declaration requirements and the complete transaction equality hold.

<a id="ds-tx-conservation-n04" name="ds-tx-conservation-n04"></a>

##### 2.1.5.6 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L16) - preserves a SubTx's ability to contribute ADA to TopTx fees

Preserve the existing ability of SubTx application ADA to contribute to TopTx fees. DepositStore accounting must not introduce an independent balance constraint for each SubTx.

<a id="ds-tx-conservation-f01" name="ds-tx-conservation-f01"></a>

##### 2.1.5.7 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L17) - rejects a batch imbalance of one lovelace

Change one ADA term by one lovelace in an otherwise balanced transaction. Exact deposit declarations do not excuse the resulting financial imbalance.

<a id="ds-tx-conservation-f02" name="ds-tx-conservation-f02"></a>

##### 2.1.5.8 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L18) - rejects a native-asset imbalance even when ADA balances

Keep ADA balanced while introducing a native-asset mismatch. DepositStore transfers concern ADA and cannot fund or erase a native-asset discrepancy.

<a id="ds-tx-conservation-f03" name="ds-tx-conservation-f03"></a>

##### 2.1.5.9 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L19) - rejects a delegation request that the complete batch does not fund

A request can have the correct amount and attribution while the complete transaction lacks funds. Conservation must reject that shortfall.

<a id="ds-tx-conservation-n05" name="ds-tx-conservation-n05"></a>

##### 2.1.5.10 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L20) - accepts offsetting delegated operations in a financially balanced batch

Delegated allocations and releases can offset each other. Acceptance depends on exact declarations and the complete transaction balance, not a demand that every SubTx balance independently.

<a id="ds-tx-conservation-n06" name="ds-tx-conservation-n06"></a>

##### 2.1.5.11 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L21) - requires an output of 12 ADA for 10 input ADA and a 2 ADA net release with no other ADA flows

With 10 ADA consumed, a 2 ADA release, one output and no other ADA terms or exports, conservation fixes that output at 12 ADA. This example does not impose independent SubTx balance in other scenarios.

<a id="ds-tx-conservation-n07" name="ds-tx-conservation-n07"></a>

##### 2.1.5.12 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ConservationSpec.hs#L22) - allows an output of 10 ADA when the other 2 ADA contributes to TopTx fees

The same 10 ADA input and 2 ADA release can produce a 10 ADA output while exporting 2 ADA to TopTx fees. The complete transaction must account for that export.

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

Released UTxO capacity deposits participate in exact accounting under DS-TX-EXACTNESS-CONTRIBUTION. A body whose
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

##### 2.1.6.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AuthorizationSpec.hs#L11) - allows the authorized spender to release UTxO capacity deposits paid by another person

The output’s spending credential controls its associated deposit. A person who paid the original deposit retains no separate claim when another authorized person spends the output.

<a id="ds-tx-authorization-n02" name="ds-tx-authorization-n02"></a>

##### 2.1.6.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AuthorizationSpec.hs#L12) - does not require a separate signature from the original UTxO capacity deposit funder

Satisfy the output’s existing spending conditions. No additional witness from the original deposit funder is required.

<a id="ds-tx-authorization-f01" name="ds-tx-authorization-f01"></a>

##### 2.1.6.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AuthorizationSpec.hs#L13) - rejects unauthorized spending even when the Store declaration is exact

A numerically exact Store declaration cannot replace the witnesses required to spend the output. Preserve the authorization failure despite correct accounting.

<a id="ds-tx-authorization-n03" name="ds-tx-authorization-n03"></a>

##### 2.1.6.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/AuthorizationSpec.hs#L14) - does not release UTxO capacity deposits for a reference input

A reference makes an output available without spending it. Its deposit remains allocated to the live output.

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

Here `amount` has type `PositiveCoin`, and the settlement choices remain:

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

```text
txTotalNetRelease = max(0, -txTotalNetUTxODepositChange)

topTxNetUTxODepositChange = txTotalNetUTxODepositChange - sum(subTxLocalNetUTxODepositChanges)
topTxNetRelease = max(0, -topTxNetUTxODepositChange)
```

Each SubTx contributes the following signed amount to
`subTxLocalNetUTxODepositChanges`:

| SubTx declaration | Local net UTxO capacity deposit change |
| --- | --- |
| `SubTx.DeclaresZeroNetUTxODeposit` | `0`; no delegation |
| `SubTx.DeclaresNetUTxODepositAllocation amount` | `+amount` |
| `SubTx.DeclaresNetUTxODepositRelease amount (SubTxSettlementOutput index)` | `-amount` |
| `SubTx.RequestsUTxODepositFromTopTx amount` | `0`; TopTx handles the net allocation |
| `SubTx.DeclaresNetUTxODepositRelease amount DelegateToTopTx` | `0`; TopTx handles the net release |
| `SubTx.NoUTxODepositDeclaration` | `0`; declaration requirements still apply |

Delegated contributions are already included in `txTotalNetUTxODepositChange`. Do
not subtract them as local contributions: they remain TopTx's responsibility. These
amounts are derived; no additional TopTx amount field is required. Unlike TopTx's own
UTxO capacity deposit contribution in DS-TX-EXACTNESS-CONTRIBUTION, `topTxNetUTxODepositChange` includes
delegated operations.

For a net-release transaction (`txTotalNetUTxODepositChange < 0`), require:

| Derived TopTx amount | Required settlement |
| --- | --- |
| `topTxNetRelease == 0` | `NoTopTxSettlement` |
| `topTxNetRelease > 0` | `TopTxSettlementOutput index`, with the selected output containing at least `topTxNetRelease` |

`txTotalNetRelease` is the net ADA amount transferred from the Store for the entire
transaction. `topTxNetRelease` is the amount to settle in TopTx's selected output. Net
allocations funded locally by SubTx bodies can make the latter larger than the former.
For example, a local SubTx net allocation of 3 ADA and TopTx's own release contribution
of 5 ADA give:

```text
txTotalNetUTxODepositChange = -2
txTotalNetRelease = 2
topTxNetUTxODepositChange = -2 - 3 = -5
topTxNetRelease = 5
```

TopTx declares `TopTx.DeclaresNetUTxODepositRelease 2 (TopTxSettlementOutput index)`.
The selected output contains at least 5 ADA: 3 ADA supplied by the SubTx and 2 ADA from
the store. These funds are included in the batch conservation check once. Conversely, a
local SubTx net release of 5 ADA and a TopTx net allocation contribution of 3 ADA give
`topTxNetUTxODepositChange = 3` and `topTxNetRelease = 0`; the declaration is
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

###### 2.1.7.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs#L11) - for a batch net release: NoTopTxSettlement ⇔ topTxNetRelease = 0

Within the net-release declaration branch, a zero derived TopTx release share requires no TopTx destination. A positive share requires a selected TopTx output.

<a id="ds-tx-settlement-participation-n01" name="ds-tx-settlement-participation-n01"></a>

###### 2.1.7.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs#L12) - requires NoTopTxSettlement when SubTxs settle the entire net release locally

SubTx bodies settle the entire release locally, leaving no release share attributed to TopTx. The declaration therefore uses NoTopTxSettlement.

<a id="ds-tx-settlement-participation-n02" name="ds-tx-settlement-participation-n02"></a>

###### 2.1.7.1.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs#L13) - requires a TopTx settlement output when the batch declares a net release and TopTx has a positive share

The net-release transaction leaves a positive TopTx share. TopTx must identify the output that covers it.

<a id="ds-tx-settlement-participation-n03" name="ds-tx-settlement-participation-n03"></a>

###### 2.1.7.1.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs#L14) - accepts a net release settled across TopTx and SubTx outputs

One transaction can settle part of its release in SubTx outputs and the remainder in TopTx. Each destination must cover its own share.

<a id="ds-tx-settlement-participation-n04" name="ds-tx-settlement-participation-n04"></a>

###### 2.1.7.1.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs#L15) - allows TopTx's settlement amount to exceed the batch net release when SubTxs fund net allocations locally

A local SubTx allocation of 3 ADA can combine with TopTx’s 5 ADA release contribution. The Store releases only 2 ADA net, while the TopTx output must cover its derived 5 ADA share.

<a id="ds-tx-settlement-participation-f01" name="ds-tx-settlement-participation-f01"></a>

###### 2.1.7.1.6 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs#L16) - rejects NoTopTxSettlement when the batch declares a net release and TopTx has a positive share

A positive derived TopTx share remains after local SubTx accounting. NoTopTxSettlement would leave that share without its required destination.

<a id="ds-tx-settlement-participation-f02" name="ds-tx-settlement-participation-f02"></a>

###### 2.1.7.1.7 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs#L17) - rejects a TopTx settlement output when TopTx has no net release to settle

TopTx has no release share in this net-release transaction. Its declaration must use NoTopTxSettlement rather than designate an unnecessary output.

<a id="ds-tx-settlement-participation-n05" name="ds-tx-settlement-participation-n05"></a>

###### 2.1.7.1.8 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs#L18) - does not require a TopTx settlement output when the batch declares a net allocation

The transaction declares a net allocation, so its TopTx declaration has no release-settlement output. A delegated release can be absorbed by other allocations without a separate Store payment.

<a id="ds-tx-settlement-participation-n06" name="ds-tx-settlement-participation-n06"></a>

###### 2.1.7.1.9 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/ParticipationSpec.hs#L19) - does not require a TopTx settlement output for an explicit-zero batch even when TopTx's derived accounting portion is negative

The transaction declares explicit zero. Even if the signed portion attributed to TopTx is negative, the net-release-only settlement selector is not introduced into this declaration form.

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

###### 2.1.7.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/DestinationSpec.hs#L11) - each settlement output: 0 ≤ index < length(ownOutputs)

Every selected index must lie within the declaring body’s regular output sequence. Being in range in a different sequence is insufficient.

<a id="ds-tx-settlement-destination-f01" name="ds-tx-settlement-destination-f01"></a>

###### 2.1.7.2.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/DestinationSpec.hs#L12) - rejects an index outside the declaring body's output sequence

Use a settlement index beyond the owning body’s output sequence. The ledger must reject rather than ignore the destination or choose a replacement.

<a id="ds-tx-settlement-destination-f02" name="ds-tx-settlement-destination-f02"></a>

###### 2.1.7.2.3 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/DestinationSpec.hs#L13) - does not resolve a SubTx settlement index against TopTx outputs

A SubTx index is interpreted locally. An output with the same index in TopTx cannot satisfy that local target.

<a id="ds-tx-settlement-destination-f03" name="ds-tx-settlement-destination-f03"></a>

###### 2.1.7.2.4 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/DestinationSpec.hs#L14) - does not resolve a settlement index against collateral return

Collateral return is not an ordinary output in the settlement index space. Its value cannot repair an invalid ordinary target.

<a id="ds-tx-settlement-destination-f04" name="ds-tx-settlement-destination-f04"></a>

###### 2.1.7.2.5 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/DestinationSpec.hs#L15) - rejects a local settlement target when a SubTx spends its final store-backed inputs and creates no outputs

A local index cannot identify an output in an empty sequence. The transaction must reject this target rather than resolve it against another body’s outputs.

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

###### 2.1.7.3.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/CoverageSpec.hs#L11) - each settlement output: coin(ownOutputs[index]) ≥ settlementAmount

Compare the selected output’s available application ADA with its own settlement share. An exact amount or surplus passes this bound; a shortfall fails.

<a id="ds-tx-settlement-coverage-f01" name="ds-tx-settlement-coverage-f01"></a>

###### 2.1.7.3.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/CoverageSpec.hs#L12) - rejects a settlement output containing less ADA than its settlement amount

The selected output exists but contains less ADA than its allocated settlement amount. Valid index resolution alone is insufficient.

<a id="ds-tx-settlement-coverage-n01" name="ds-tx-settlement-coverage-n01"></a>

###### 2.1.7.3.3 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/CoverageSpec.hs#L13) - accepts a settlement output containing exactly its settlement amount

The selected output contains exactly its settlement share. Equality satisfies the coverage lower bound.

<a id="ds-tx-settlement-coverage-n02" name="ds-tx-settlement-coverage-n02"></a>

###### 2.1.7.3.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/CoverageSpec.hs#L14) - accepts a settlement output containing the settlement amount and additional funds

The selected output contains its settlement amount plus other funds. The rule is a lower bound and does not require equality.

<a id="ds-tx-settlement-coverage-f02" name="ds-tx-settlement-coverage-f02"></a>

###### 2.1.7.3.5 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/CoverageSpec.hs#L15) - rejects a store-backed settlement output with insufficient application ADA even when its external UTxO capacity deposit would cover the difference

The selected store-backed output’s application ADA is too small. Its externally held capacity deposit is unavailable to cover that settlement shortfall.

<a id="ds-tx-settlement-coverage-n03" name="ds-tx-settlement-coverage-n03"></a>

###### 2.1.7.3.6 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/CoverageSpec.hs#L16) - accepts a store-backed settlement output with application ADA equal to the settlement amount

A store-backed output’s application ADA equals its settlement amount. Its separately allocated capacity deposit neither increases nor reduces this coverage.

<a id="ds-tx-settlement-coverage-n04" name="ds-tx-settlement-coverage-n04"></a>

###### 2.1.7.3.7 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/Settlement/CoverageSpec.hs#L17) - checks TopTx's derived settlement amount rather than the entire batch net release

Use the portion attributed to TopTx after local SubTx accounting. The complete transaction’s net release can be smaller or larger than the share selected here.

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

##### 2.1.8.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ApplicationAssetsSpec.hs#L11) - accepts a store-backed output containing native assets and zero ADA

The output carries native assets but no application ADA. Its storage is paid through an exact external deposit, so an implicit minimum-ADA condition must not be imposed on its application value.

<a id="ds-tx-application-assets-n02" name="ds-tx-application-assets-n02"></a>

##### 2.1.8.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ApplicationAssetsSpec.hs#L12) - accepts empty application assets with a datum or reference script

An output with no application assets can still carry a datum or reference script. Its full accepted encoding determines the required external deposit.

<a id="ds-tx-application-assets-n03" name="ds-tx-application-assets-n03"></a>

##### 2.1.8.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ApplicationAssetsSpec.hs#L13) - accepts a store-backed output containing only an address

Even an address-only output occupies priced storage. Empty application assets are permitted when its deposit and the remaining transaction requirements are satisfied.

<a id="ds-tx-application-assets-n04" name="ds-tx-application-assets-n04"></a>

##### 2.1.8.4 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Tx/ApplicationAssetsSpec.hs#L14) - preserves the minimum-coin requirement for implicit outputs

The new permission applies to store-backed outputs. An implicit output continues to carry its minimum ADA inside its value.

<a id="ds-collateral" name="ds-collateral"></a>

### 2.2 Collateral

> **Validate collateral terms and derive the phase-2 failure settlement.**
>
> Validation may be required even when scripts succeed. State Execution determines whether collateral effects apply.

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

**Decision:** Agreed. Both `ImplicitDepositTxOut` and `StoreBackedTxOut` must be supported for collateral inputs and the collateral return; the first version is not restricted to implicit outputs.

Require collateral and run the existing batch collateral validation whenever TopTx or any SubTx contains redeemers. The deposit funding, minimum collateral fee and supplied-total checks in `DS-COLLATERAL-FUNDING` and `DS-COLLATERAL-TOTAL` use this same scope. Store-backed outputs or ordinary DepositStore declarations alone do not activate the requirement. Existing checks on supplied inputs and outputs that run independently of this trigger continue to apply.

Validation scope and applied effects are different responsibilities. A batch whose scripts would succeed can still be rejected for invalid collateral. Ordinary success applies ordinary spending and Store operations while leaving collateral untouched; an accepted phase-2 failure applies collateral consumption and its specified return instead. `DS-STATE-EXECUTION` owns that selection and the requirement that rejection leave the accepted ledger state unchanged. The cases below remain deliberate executable placeholders, not evidence that these requirements have been implemented.

<a id="ds-collateral-scope-f01" name="ds-collateral-scope-f01"></a>

##### 2.2.1.1 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ScopeSpec.hs#L11) - rejects TopTx redeemers without collateral

Given redeemers in TopTx and no collateral inputs, expect rejection even if every SubTx is free of redeemers. The requirement follows the redeemer's presence, not whether the script would ultimately succeed.

<a id="ds-collateral-scope-f02" name="ds-collateral-scope-f02"></a>

##### 2.2.1.2 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ScopeSpec.hs#L12) - rejects SubTx redeemers without collateral even when TopTx has none

Given a redeemer only in a SubTx, omit collateral from the containing batch. Expect rejection: examining TopTx alone would miss an active collateral requirement.

<a id="ds-collateral-scope-f03" name="ds-collateral-scope-f03"></a>

##### 2.2.1.3 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ScopeSpec.hs#L13) - rejects redeemers in both TopTx and SubTxs without collateral

Given redeemers in TopTx and in one or more SubTxs, omit collateral while satisfying unrelated rules. Expect the batch to be rejected; the presence of both locations cannot bypass the shared collateral requirement.

<a id="ds-collateral-scope-n01" name="ds-collateral-scope-n01"></a>

##### 2.2.1.4 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ScopeSpec.hs#L14) - does not require collateral merely because a transaction uses the DepositStore

Given otherwise valid ordinary Store activity with no redeemers anywhere in the batch, omit collateral. Its absence must not cause collateral rejection merely because outputs are store-backed or a body declares a Store operation.

<a id="ds-collateral-authorization" name="ds-collateral-authorization"></a>

#### 2.2.2 Authorization

> **Preserve the existing key-control requirements for collateral inputs.**
>
> Both output variants need the same authority; funding or a Store declaration cannot replace it.

**Decision:** Agreed. Collateral inputs retain the existing key-control requirements when their output representation changes. Deposit funding does not provide spending authority, and an ordinary DepositStore declaration cannot authorize an otherwise ineligible collateral input.

Exercise implicit and store-backed collateral as fixture variants under the same existing authorization rules. `DS-COLLATERAL-CONSERVATION` separately owns native-asset conservation, while `DS-COLLATERAL-SCOPE` preserves the established validation trigger and independently applied checks.

<a id="ds-collateral-authorization-f01" name="ds-collateral-authorization-f01"></a>

##### 2.2.2.1 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/AuthorizationSpec.hs#L11) - rejects collateral inputs that fail the existing key-control checks

Given otherwise funded collateral, supply an input that violates the existing key-control checks. Expect rejection under those checks; a store-backed representation or correct capacity-deposit accounting cannot authorize its consumption.

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

These checks apply whenever `DS-COLLATERAL-SCOPE` activates collateral validation, even if scripts would succeed or the optional total is absent. Output variants, mixed inputs and absent returns are fixture axes within these requirements, not separate validation rules. Repricing after parameter changes remains deferred.

<a id="ds-collateral-funding-f01" name="ds-collateral-funding-f01"></a>

##### 2.2.3.1 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L13) - rejects insufficient collateral funding when redeemers trigger validation even if all scripts succeed

Given redeemers whose scripts would all succeed, make the collateral coins insufficient for the return, additional deposit and minimum fee. Expect collateral validation to reject the batch before script success could excuse that deficit.

<a id="ds-collateral-funding-n01" name="ds-collateral-funding-n01"></a>

##### 2.2.3.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L14) - accepts a batch whose scripts succeed when its required collateral is fully funded and all other rules hold

Given successful scripts and collateral that covers the signed return, any additional deposit and the minimum fee, expect acceptance when all other rules hold. `DS-STATE-EXECUTION` separately requires the accepted ordinary path to leave the collateral inputs and return unapplied.

<a id="ds-collateral-funding-n02" name="ds-collateral-funding-n02"></a>

##### 2.2.3.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L15) - accepts funded collateral with implicit or store-backed inputs and returns

Construct otherwise valid funded collateral using implicit and store-backed inputs and returns, including mixed input sets. Expect acceptance for each applicable combination; retain each variant's existing output checks rather than treating its representation as an eligibility restriction.

<a id="ds-collateral-funding-n03" name="ds-collateral-funding-n03"></a>

##### 2.2.3.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L16) - reuses released UTxO capacity deposits when the collateral return requires the same amount

Given a return whose required capacity deposit equals the deposits released by consumed collateral, expect no additional coin-funded deposit and no released-deposit surplus. Reusing that released amount must leave the collateral coins available for the return coins and independently required fee.

<a id="ds-collateral-funding-n04" name="ds-collateral-funding-n04"></a>

##### 2.2.3.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L17) - funds additional return UTxO capacity deposits from collateral coins

Use the second funded row of the funding table, where the return requires more capacity deposit than the inputs release. Expect collateral coins to cover exactly that positive difference, leaving the required minimum coin fee after the signed return is funded.

<a id="ds-collateral-funding-f02" name="ds-collateral-funding-f02"></a>

##### 2.2.3.6 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L18) - rejects collateral coins below the minimum fee after funding the return and additional UTxO capacity deposits

Use the third row of the funding table: paying the return and additional deposit leaves no coin fee. Expect rejection even though those two obligations are covered; the ledger cannot repair the deficit by changing the return or choosing another input.

<a id="ds-collateral-funding-p01" name="ds-collateral-funding-p01"></a>

##### 2.2.3.7 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L19) - accepted phase-2 failure ⇒ collateralCoinFee ≥ ceil(txFee * collateralPercentage / 100)

For every accepted phase-2 failure, independently subtract the specified return coins and positive deposit shortfall from the input coins. The remainder must meet the ceiling of the transaction fee times the collateral percentage; adding released-deposit surplus must not alter that comparison.

<a id="ds-collateral-funding-f03" name="ds-collateral-funding-f03"></a>

##### 2.2.3.8 [F03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L20) - rejects collateral whose minimum fee depends on released UTxO capacity deposit surplus

In the fourth funding-table row, the released surplus would credit 1 ADA to fees while the collateral coin fee is zero. ADA still balances as 5 + 2 = 5 + 1 + 1, but the 1 ADA minimum must be funded by coins, so expect rejection.

<a id="ds-collateral-funding-f04" name="ds-collateral-funding-f04"></a>

##### 2.2.3.9 [F04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L21) - rejects a collateral return whose funding depends on released UTxO capacity deposit surplus

Given released-deposit surplus, enlarge the signed return so it is affordable only if that surplus is treated as return funding. Expect rejection even if total ADA could balance: all released surplus is reserved for the fee pot after the return's capacity deposit is covered.

<a id="ds-collateral-funding-f05" name="ds-collateral-funding-f05"></a>

##### 2.2.3.10 [F05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L22) - rejects a collateral funding shortfall of one lovelace

Begin at the exact funding boundary, then reduce the collateral input coins by one lovelace while holding the signed return, required deposits and minimum fee fixed. Expect rejection for that one-lovelace deficit, with no rounding tolerance or adjustment of the transaction.

<a id="ds-collateral-funding-n05" name="ds-collateral-funding-n05"></a>

##### 2.2.3.11 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L23) - counts implicit collateral inputs' full ADA as coins and zero released Store deposits when mixed with store-backed inputs

Given a mixture of implicit and store-backed collateral inputs, count an implicit input's entire ADA in `collateralInputCoins` and none in `releasedUTxODeposits`. Expect funding to use only the allocated deposits of the store-backed inputs, preventing an implicit minimum from becoming a second source of funds.

<a id="ds-collateral-funding-n06" name="ds-collateral-funding-n06"></a>

##### 2.2.3.12 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L24) - allocates no Store deposit to an implicit collateral return even when consuming store-backed collateral inputs

Given store-backed collateral inputs and an implicit return, set the return's Store deposit requirement to zero while counting its full ADA as return coins. Expect no additional Store allocation; the return still has to satisfy its existing implicit minimum and the released deposits follow `DS-COLLATERAL-SURPLUS`.

<a id="ds-collateral-funding-n07" name="ds-collateral-funding-n07"></a>

##### 2.2.3.13 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L25) - accepts a store-backed collateral return with zero application ADA when its deposit and the minimum fee are funded

Given a store-backed return with zero application ADA, provide enough collateral to fund its full size-based deposit and the minimum collateral fee. Expect acceptance when the other rules hold: the deposit remains external to application value, and zero application ADA does not waive its storage cost.

<a id="ds-collateral-funding-f06" name="ds-collateral-funding-f06"></a>

##### 2.2.3.14 [F06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/FundingSpec.hs#L26) - rejects underfunded collateral when the optional total is absent

Given active collateral validation and an absent optional total, provide underfunded collateral. Expect rejection from the funding rule after the total is derived from inputs and return; omitting a declaration cannot supply the missing coins.

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

##### 2.2.4.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/SurplusSpec.hs#L11) - credits excess released UTxO capacity deposits to fees rather than the treasury

Use the first funded row of the funding table, where released capacity deposits exceed the return's requirement. On an accepted phase-2 failure, expect the entire excess to join the coin fee in the fee pot, with no direct treasury credit.

<a id="ds-collateral-surplus-p01" name="ds-collateral-surplus-p01"></a>

##### 2.2.4.2 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/SurplusSpec.hs#L12) - accepted phase-2 failure ⇒ feesAfter = feesBefore + collateralCoinFee + releasedUTxODepositFee

For every accepted phase-2 failure, calculate the coin fee and positive released-deposit surplus independently from the collateral fixture. Compare their sum with the actual fee-pot increase, so omitted surplus or an unrelated Store surplus cannot be hidden by a model-only identity.

<a id="ds-collateral-surplus-p02" name="ds-collateral-surplus-p02"></a>

##### 2.2.4.3 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/SurplusSpec.hs#L13) - accepted phase-2 failure ⇒ treasuryAfter = treasuryBefore

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

Reject every supplied amount that differs from the computed total, including when scripts would succeed. If the field is absent, derive the total from the inputs and return; absence does not bypass deposit funding or the minimum fee. `DS-COLLATERAL-FUNDING-F06` owns that funding rejection, and other applicable collateral validation requirements remain in force.

<a id="ds-collateral-total-n01" name="ds-collateral-total-n01"></a>

##### 2.2.5.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TotalSpec.hs#L11) - accepts a declared total equal to collateral input coins minus return coins

Given input coins and a specified return, supply exactly their difference as the optional total and satisfy all other collateral rules. Expect no total-mismatch rejection; the 5 ADA input and 2 ADA return example requires 3 ADA regardless of the separate deposit adjustment.

<a id="ds-collateral-total-f01" name="ds-collateral-total-f01"></a>

##### 2.2.5.2 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TotalSpec.hs#L12) - rejects a declared total differing by one lovelace when collateral validation applies

With collateral validation active and funding otherwise correct, supply a total one lovelace away from the input-minus-return amount. Expect rejection for either direction of error; adequate collateral funding does not make an inexact declaration acceptable.

<a id="ds-collateral-total-f02" name="ds-collateral-total-f02"></a>

##### 2.2.5.3 [F02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TotalSpec.hs#L13) - rejects an incorrect supplied total when redeemers trigger collateral validation even if all scripts succeed

Given redeemers whose scripts would succeed and otherwise valid collateral, supply an incorrect total. Expect rejection under the same equality used on the failure path, because script outcome does not change the validation scope.

<a id="ds-collateral-total-n02" name="ds-collateral-total-n02"></a>

##### 2.2.5.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TotalSpec.hs#L14) - includes coins funding additional UTxO capacity deposits in the declared total

In the 5 ADA input and 2 ADA return example, require an additional capacity deposit of 1 ADA. Expect a declared total of 3 ADA while only 2 ADA remains as the coin fee, demonstrating that the coins allocated to the Store remain part of the total.

<a id="ds-collateral-total-n03" name="ds-collateral-total-n03"></a>

##### 2.2.5.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/TotalSpec.hs#L15) - excludes UTxO capacity deposits released from the Store from the declared total

Given excess capacity deposits released from the Store, hold collateral input and return coins fixed. Expect the declared total to remain their difference even though the surplus increases the eventual fee credit; the externally held deposit was never part of the input coins.

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

Holding collateral inputs, return, fee and pricing policy fixed, ordinary TopTx and SubTx Store declarations cannot change collateral settlement. Ordinary release destinations and output creation cannot be applied unchanged to a phase-2 failure: settlement uses only the collateral effects actually selected by `DS-STATE-EXECUTION`. Success applies ordinary effects; an accepted phase-2 failure applies collateral effects; rejection applies neither and preserves the accepted ledger state atomically.

`DS-STATE-BALANCE` checks the resulting Store balance against the derived change. `DS-STATE-ALLOCATIONS` checks consumed collateral records, the return's record when store-backed, preserved unrelated records and the matching change in outstanding deposit obligations. These state assertions are separate from deriving the settlement amount.

<a id="ds-collateral-settlement-n01" name="ds-collateral-settlement-n01"></a>

##### 2.2.6.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/SettlementSpec.hs#L12) - derives Store changes from collateral inputs and return without a separate declaration

Given resolved collateral inputs and a specified return, provide no separate collateral Store operation declaration. Expect the derived change to equal the return's required deposit minus the allocated deposits released by those inputs; the existing optional total does not replace or encode this derivation.

<a id="ds-collateral-settlement-p01" name="ds-collateral-settlement-p01"></a>

##### 2.2.6.2 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/SettlementSpec.hs#L13) - does not let ordinary Store declarations change collateral settlement

Hold collateral inputs, return, fee and pricing policy fixed while varying ordinary TopTx and SubTx Store declarations. Expect the derived collateral settlement to remain identical; an ordinary declaration that is not applied on this path cannot fund or redirect its effects.

<a id="ds-collateral-settlement-n02" name="ds-collateral-settlement-n02"></a>

##### 2.2.6.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/SettlementSpec.hs#L14) - settles multiple collateral inputs with no return output

Given several collateral inputs and no return output, sum all input coins and the allocated deposits of only the store-backed inputs. Return coins and required return deposit are both zero, so the derived Store change releases those deposits and the fee credit consists of the input coins plus released deposits, subject to the independent minimum funding rule.

<a id="ds-collateral-conservation" name="ds-collateral-conservation"></a>

#### 2.2.7 Conservation

> **Account for all value consumed by collateral settlement.**
>
> Input coins + released deposits $=$ return coins + return deposit + fees. Native assets must also be conserved.

**Decision:** Agreed. An accepted collateral settlement must conserve ADA across collateral outputs, the Store and the fee pot:

$$
\begin{aligned}
&\mathrm{collateralInputCoins}+\mathrm{releasedUTxODeposits} \\
&\qquad=\mathrm{collateralReturnCoins}+\mathrm{collateralReturnUTxODeposit}+\mathrm{collateralFee}
\end{aligned}
$$

The variables include only effects actually applied after an accepted phase-2 failure. Store-held capacity deposits must not be counted again as output coins. The existing native-asset conservation checks also continue to apply for both output variants; correct ADA funding cannot excuse a native-asset imbalance.

Conservation does not determine fee destination, prove adequate minimum funding or validate a supplied total. Those obligations remain in `DS-COLLATERAL-SURPLUS`, `DS-COLLATERAL-FUNDING` and `DS-COLLATERAL-TOTAL`. `DS-STATE-CONSERVATION` owns conservation across the whole ledger, while `DS-STATE-EXECUTION` excludes unapplied ordinary effects and preserves rejected state.

<a id="ds-collateral-conservation-n01" name="ds-collateral-conservation-n01"></a>

##### 2.2.7.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ConservationSpec.hs#L11) - conserves ADA across collateral inputs, return, Store and fees

After an accepted phase-2 failure, compare the collateral ADA removed from outputs and the Store with the return ADA, its capacity deposit and the actual fee increase. Expect equality without counting external deposits a second time as output value.

<a id="ds-collateral-conservation-p01" name="ds-collateral-conservation-p01"></a>

##### 2.2.7.2 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ConservationSpec.hs#L12) - accepted phase-2 failure ⇒ collateralInputCoins + releasedUTxODeposits = collateralReturnCoins + collateralReturnUTxODeposit + collateralFee

Across accepted phase-2 failures, obtain expected input coins and allocated deposits independently from the fixture, then compare them with the actually applied return, deposit and fee effects. Equality must hold for surplus, equal deposits, shortfall, mixed input variants and absent returns; the fourth funding-table row shows why this equality alone cannot justify acceptance.

<a id="ds-collateral-conservation-f01" name="ds-collateral-conservation-f01"></a>

##### 2.2.7.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/Collateral/ConservationSpec.hs#L13) - rejects a collateral native-asset imbalance

Given collateral whose ADA accounting is otherwise valid, introduce a native-asset imbalance between collateral inputs and the specified return. Expect rejection under the existing native-asset checks; neither released deposits nor a sufficient ADA fee can compensate for a missing asset.

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

```text
utxoAfter = (utxoBefore without regularInputs)
              union newRegularOutputsWithUTxODeposits
```

On an accepted phase-2 failure, consume only collateral inputs and create only the specified collateral return. UTxO entries, their allocated amounts and the Store balance must settle atomically for the chosen outcome. A rejected batch preserves the entire previously accepted ledger state, including all three; no partially applied result is an accepted state.

A selected settlement output already contains its settlement amount in the submitted transaction. Applying the accepted transaction does not add that amount again. Exact contribution, destination and conservation checks remain separate prerequisites.

<a id="ds-state-execution-p01" name="ds-state-execution-p01"></a>

#### 3.1.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ExecutionSpec.hs#L11) - ordinary success ⇒ utxoAfter = (utxoBefore without regularInputs) union newRegularOutputsWithUTxODeposits

Given an accepted ordinary batch, remove the regular inputs consumed by TopTx and its SubTxs and add their new regular outputs with allocated-deposit metadata. Compare the resulting ledger UTxO with that independently constructed result.

<a id="ds-state-execution-n01" name="ds-state-execution-n01"></a>

#### 3.1.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ExecutionSpec.hs#L12) - applies ordinary Store operations and leaves collateral untouched on success

Given an ordinary successful transaction that also supplies collateral, apply its ordinary Store operations while leaving collateral inputs and return unapplied. Supplying or validating collateral does not cause its settlement on success.

<a id="ds-state-execution-n02" name="ds-state-execution-n02"></a>

#### 3.1.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ExecutionSpec.hs#L13) - applies collateral settlement and no ordinary Store operations on an accepted phase-2 failure

Given an accepted phase-2 failure with ordinary Store declarations, apply the derived collateral settlement and no ordinary Store operations. The declared ordinary funding or release cannot influence an outcome on which it is unapplied.

<a id="ds-state-execution-n03" name="ds-state-execution-n03"></a>

#### 3.1.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ExecutionSpec.hs#L14) - consumes only collateral inputs and creates only the specified collateral return in the UTxO on an accepted phase-2 failure

Given an accepted phase-2 failure, remove only the collateral inputs and create only the specified collateral return. Ordinary regular inputs remain live and ordinary outputs are not created.

<a id="ds-state-execution-n04" name="ds-state-execution-n04"></a>

#### 3.1.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ExecutionSpec.hs#L15) - does not credit the settlement amount to the selected output a second time

Given an accepted release whose selected output already includes its settlement amount, create that output with the submitted value. Adding another settlement credit during application would count the release twice.

<a id="ds-state-execution-f01" name="ds-state-execution-f01"></a>

#### 3.1.6 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ExecutionSpec.hs#L16) - leaves the entire ledger state unchanged on rejection, including UTxO, allocated deposit records and Store balance

Given a batch rejected by the ledger, compare the complete state before submission and after rejection. UTxO entries, allocated records and Store balance must remain unchanged together, even if validation considered possible effects.

<a id="ds-state-execution-p02" name="ds-state-execution-p02"></a>

#### 3.1.7 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ExecutionSpec.hs#L17) - batch rejected ⇒ acceptedLedgerStateAfter = acceptedLedgerStateBefore

Across rejected batches, require the resulting accepted ledger state to equal the prior accepted state. This invariant distinguishes rejection from an accepted phase-2 failure, which legitimately applies collateral effects.

<a id="ds-state-allocations" name="ds-state-allocations"></a>

### 3.2 Allocations

> **Track the deposit attached to each live store-backed output.**
>
> Creation records it; consumption releases it exactly once; reference use leaves it unchanged.

**Decision:** Agreed.

Every live store-backed output retains exactly one recoverable allocated UTxO capacity deposit amount associated with its `TxIn`. Every live allocated amount is nonnegative. Treat `utxoDepositRecords` as a logical map; its domain is exactly the live store-backed UTxO, and its sum is the outstanding obligation:

```text
keys(utxoDepositRecords(state))
  = { txIn | output(UTxO(state)[txIn]) is StoreBackedTxOut }

totalUTxODeposits(utxo(state))
  = sum(values(utxoDepositRecords(state)))
```

Creating a store-backed output establishes its amount using `DS-PRICING`. Consuming it releases that allocated amount exactly once and removes its record. Reference inputs leave the amount unchanged and release nothing. Implicit outputs, including outputs preserved by the Conway upgrade, have no Store obligation and release no Store deposit when consumed.

The conceptual representation keeps this metadata alongside the live output:

```haskell
data UTxOEntry era
  = ImplicitDepositEntry !(ImplicitDepositTxOut era)
  | StoreBackedEntry !(StoreBackedTxOut era) !Coin
    -- Coin is the allocated UTxO capacity deposit.

newtype UTxO era =
  UTxO { unUTxO :: Map TxIn (UTxOEntry era) }
```

This records the domain relationship; the precise era APIs and ledger-state encoding remain implementation work. No additional field is required in the serialized transaction output or in `TxIn` itself. Recover the accepted allocation from retained information rather than recomputing it from a later serialization. The stored amount supports exact release at fixed prices; it does not settle the additional historical-pricing questions under `DS-PRICING-HISTORY`.

The applied outcome determines which records change. Ordinary success updates records for regular inputs and new ordinary outputs. Accepted phase-2 failure updates only consumed collateral records and a store-backed return, leaving unrelated records untouched. Their obligation deltas are:

```text
ordinary success:
  obligationsAfter = obligationsBefore + txTotalNetUTxODepositChange

accepted phase-2 failure:
  obligationsAfter = obligationsBefore
                       + collateralReturnUTxODeposit
                       - releasedUTxODeposits
```

Check the records against the independently observed live UTxO and expected amounts. Comparing two totals derived from the same unchecked records would not detect missing or incorrect allocations. `DS-STATE-EXECUTION` governs atomic application; `DS-STATE-RECOVERY` governs preservation through serialization and rollback.

<a id="ds-state-allocations-p01" name="ds-state-allocations-p01"></a>

#### 3.2.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L11) - ordinary success ⇒ releasedUTxODeposits = Σ(allocatedUTxODeposit(utxo[input])) over consumed store-backed inputs

Given an ordinary successful spend, sum the recorded allocated amounts on the consumed store-backed inputs and compare that sum with the released amount. Use the input records, not current output repricing or the Store's global available balance.

<a id="ds-state-allocations-n01" name="ds-state-allocations-n01"></a>

#### 3.2.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L12) - records the allocated UTxO capacity deposit alongside each newly created store-backed output

Given a newly created store-backed output, expect its live UTxO entry to retain the allocation determined when it was accepted. That association supplies the later release amount.

<a id="ds-state-allocations-n02" name="ds-state-allocations-n02"></a>

#### 3.2.3 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L13) - removes a spent output's UTxO capacity deposit record and releases its UTxO capacity deposit exactly once

Given a consumed store-backed output, expect its allocated amount to be released once and its record to disappear with the spent entry. A surviving record or a second release would no longer correspond to a live obligation.

<a id="ds-state-allocations-n03" name="ds-state-allocations-n03"></a>

#### 3.2.4 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L14) - keeps UTxO capacity deposit records unchanged when outputs are only referenced

Given a live store-backed output used only as a reference input, retain its allocated record unchanged. Referencing does not consume the output or release its obligation.

<a id="ds-state-allocations-n04" name="ds-state-allocations-n04"></a>

#### 3.2.5 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L15) - keeps Σ(live allocated UTxO capacity deposits) equal to outstanding UTxO capacity deposit obligations

Given an accepted state, sum the independently identified live store-backed allocations and compare with its outstanding deposit obligations. The obligation total describes those live outputs, rather than extra money in the Store.

<a id="ds-state-allocations-n05" name="ds-state-allocations-n05"></a>

#### 3.2.6 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L16) - does not leave missing or orphan UTxO capacity deposit records after accepted transitions

Given an accepted transition, compare record keys with the resulting live store-backed output references. Every such output must have one recoverable amount, and no record may remain for a nonexistent or implicit output.

<a id="ds-state-allocations-n06" name="ds-state-allocations-n06"></a>

#### 3.2.7 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L17) - releases the allocated UTxO capacity deposit even when reserialization would change the output size

Given an output whose accepted CBOR size differs from a later reserialization, spend it and expect the originally allocated amount to be released. Recomputing its price from the new encoding would change an existing obligation incorrectly.

<a id="ds-state-allocations-n07" name="ds-state-allocations-n07"></a>

#### 3.2.8 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L18) - does not release UTxO capacity deposits from the DepositStore when a translated implicit output is spent

Given an implicit output preserved by the Conway upgrade, spend it without releasing a deposit from the Store. Its full value was retained in the output and no external allocation was established during initialization.

<a id="ds-state-allocations-p02" name="ds-state-allocations-p02"></a>

#### 3.2.9 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L19) - ordinary success ⇒ totalUTxODepositsAfter = totalUTxODepositsBefore + txTotalNetUTxODepositChange

Given an ordinary successful batch, calculate the change in live allocated amounts from consumed and created outputs. Expect that change to equal the batch net deposit change, with every body included once.

<a id="ds-state-allocations-n08" name="ds-state-allocations-n08"></a>

#### 3.2.10 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L20) - removes consumed store-backed collateral records and records the return only when store-backed, preserving records outside collateral inputs on an accepted phase-2 failure

Given an accepted phase-2 failure, remove records for consumed store-backed collateral and create a return record only if the return is store-backed. Preserve records outside the collateral inputs because ordinary spending effects were not applied.

<a id="ds-state-allocations-p03" name="ds-state-allocations-p03"></a>

#### 3.2.11 [P03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/AllocationsSpec.hs#L21) - accepted phase-2 failure ⇒ totalUTxODepositsAfter = totalUTxODepositsBefore + collateralReturnUTxODeposit - releasedUTxODeposits

Given an accepted phase-2 failure, expect outstanding obligations to change by the return's allocated deposit minus the recorded deposits released from collateral. The equation must describe the resulting live records, independently of ordinary declarations.

<a id="ds-state-balance" name="ds-state-balance"></a>

### 3.3 Balance

> **Apply each Store transfer exactly once to its actual ADA balance.**
>
> This checks the balance change. Solvency separately checks whether the resulting balance covers all obligations.

**Decision:** Agreed.

The Store balance is actual ADA. Change it by the transfers actually applied, counting each allocation and release once:

```text
storeBalanceAfter = storeBalanceBefore
                      + netAllocationApplied - netReleaseApplied
```

A TopTx funding request contributes nothing to the balance until its funding is settled. SubTx contributions, including delegated contributions, are already included in the TopTx batch net change; they are not extra transfers to add on top. Under ordinary success:

```text
storeBalanceAfter = storeBalanceBefore + txTotalNetUTxODepositChange
```

Under accepted phase-2 failure, ordinary declarations are unapplied, and the balance instead follows the collateral return allocation minus released collateral deposits:

```text
storeBalanceAfter = storeBalanceBefore
                      + collateralReturnUTxODeposit - releasedUTxODeposits
```

For an ordinary successful batch under the fixed pricing policy, exact deposit contributions make the balance and outstanding obligations change by the same amount. Consequently:

```text
storeBalanceAfter - obligationsAfter
  = storeBalanceBefore - obligationsBefore
```

This preserves any pre-existing surplus; it does not assume that every initial or migrated state has zero surplus. Nor does it turn unrelated surplus into a refund claim: exact contributions still restrict a release to the body's actual change in allocated deposits. That rejection belongs to `DS-TX-EXACTNESS-CONTRIBUTION`. Solvency and total ADA conservation are separately checked under `DS-STATE-SOLVENCY` and `DS-STATE-CONSERVATION`.

<a id="ds-state-balance-p01" name="ds-state-balance-p01"></a>

#### 3.3.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/BalanceSpec.hs#L11) - ordinary success ⇒ storeBalanceAfter = storeBalanceBefore + txTotalNetUTxODepositChange

Given an ordinary successful batch, compare the actual Store balance before and after application. Its change must equal the complete batch net deposit change, without adding SubTx contributions again.

<a id="ds-state-balance-n01" name="ds-state-balance-n01"></a>

#### 3.3.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/BalanceSpec.hs#L12) - changes the balance by exactly the applied allocations minus releases

Given applied allocations and releases, expect the Store balance to change by their exact signed difference. Unapplied requests or duplicate contribution credits must not alter the actual pot.

<a id="ds-state-balance-p02" name="ds-state-balance-p02"></a>

#### 3.3.3 [P02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/BalanceSpec.hs#L13) - accepted phase-2 failure ⇒ storeBalanceAfter = storeBalanceBefore + collateralReturnUTxODeposit - releasedUTxODeposits

Given an accepted phase-2 failure, expect the Store balance to increase by the collateral return allocation and decrease by released collateral deposits. Ordinary declared operations supply no additional balance movement on this path.

<a id="ds-state-balance-p03" name="ds-state-balance-p03"></a>

#### 3.3.4 [P03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/BalanceSpec.hs#L14) - ordinary success ⇒ storeBalanceAfter - totalUTxODepositsAfter = storeBalanceBefore - totalUTxODepositsBefore

Given a fixed pricing policy and an ordinary successful batch, measure Store balance minus live obligations before and after. Exact matching changes to those quantities preserve the difference.

<a id="ds-state-balance-n02" name="ds-state-balance-n02"></a>

#### 3.3.5 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/BalanceSpec.hs#L15) - preserves pre-existing Store surplus across accepted ordinary transactions

Given a solvent initial state with a positive Store surplus, apply an ordinary transaction with exact deposit contributions. The same surplus must remain afterward; this check does not grant permission to release it.

<a id="ds-state-solvency" name="ds-state-solvency"></a>

### 3.4 Solvency

> **Keep enough Store ADA to cover every live allocated deposit.**
>
> Store balance $\ge$ outstanding deposits $\ge 0$. Surplus is permitted; exact accounting still applies.

**Decision:** Agreed; parameter-change handling remains deferred under `DS-PRICING-HISTORY`.

Every accepted state must have enough actual Store ADA to cover the allocated deposits of all live store-backed outputs:

$$
\mathrm{storeBalance}(s) \geq \mathrm{totalUTxODeposits}(\mathrm{utxo}(s)) \geq 0.
$$

The right-hand amount is an obligation, not another monetary pot. Solvency permits a nonzero surplus; it does not require the two amounts to be equal. Combine the actual applied transfer with the resulting UTxO obligations when checking a proposed transition:

```text
storeBalanceBefore + netAllocationApplied - netReleaseApplied
  >= totalUTxODeposits(utxoAfter)
```

For a batch, inspect the completed TopTx and SubTx result. Temporary intermediate accounting is not an accepted ledger state and does not impose an independent financial-balance requirement on each SubTx. On accepted phase-2 failure, only applied collateral effects can supply funding; ordinary declarations that were not applied cannot do so.

The invariant applies to accepted states after initialization, era translation, epochs and collateral processing. The present executable scope assumes a fixed pricing policy. The eventual parameter-change policy must also preserve solvency, but these tests do not establish that future behavior.

Starting from a Store balance of 10 ADA, the following proposed after-states illustrate only the inequality:

| Allocation applied | Release applied | Obligations after | Balance after | Solvency predicate |
| --- | --- | --- | --- | --- |
| 0 | 1 | 9 | 9 | Pass |
| 0 | 2 | 9 | 8 | Reject |
| 0 | 2 | 6 | 8 | Pass |
| 3 | 0 | 12 | 13 | Pass |

These rows are not complete valid transaction examples. Passing solvency does not establish an exact change from the prior obligations, authorize an unrelated release, or validate settlement. A transaction with an excessive release must still fail exact contribution checks even if its resulting Store remains solvent. Conversely, from a solvent initial state, exact equal changes to balance and obligations already preserve its margin; an isolated solvency rejection must be distinguished from a ledger rejection caused by an earlier accounting failure.

<a id="ds-state-solvency-p01" name="ds-state-solvency-p01"></a>

#### 3.4.1 [P01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/SolvencySpec.hs#L11) - ordinary success ⇒ storeBalanceAfter ≥ totalUTxODepositsAfter ≥ 0

Given an accepted ordinary result, compare the actual Store pot with independently calculated live obligations. Require a nonnegative obligation total fully covered by that pot, without assuming zero surplus.

<a id="ds-state-solvency-n01" name="ds-state-solvency-n01"></a>

#### 3.4.2 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/SolvencySpec.hs#L12) - keeps the Store balance at least equal to outstanding UTxO capacity deposit obligations

Given a state whose Store balance equals or exceeds its live obligations, the solvency predicate must accept that backing level. Other transaction rules still determine whether the route to that state is valid.

<a id="ds-state-solvency-f01" name="ds-state-solvency-f01"></a>

#### 3.4.3 [F01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/SolvencySpec.hs#L13) - rejects a transition that would leave the Store insolvent

Given a proposed result whose Store balance is below its independently calculated live obligations, require rejection of that result. Distinguish a direct solvency check from a full-ledger case rejected earlier for an inexact contribution.

<a id="ds-state-solvency-n02" name="ds-state-solvency-n02"></a>

#### 3.4.4 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/SolvencySpec.hs#L14) - checks the accepted batch result without requiring each SubTx to balance independently

Given SubTxs that are not independently financially balanced, evaluate Store backing on the completed batch result. Temporary intermediate amounts must not introduce a separate SubTx financial-balance requirement.

<a id="ds-state-solvency-n03" name="ds-state-solvency-n03"></a>

#### 3.4.5 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/SolvencySpec.hs#L15) - fixed pricing and a solvent initial state ⇒ epoch transitions preserve Store solvency

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

#### 3.5.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/ConservationSpec.hs#L11) - still counts Store ADA in total monetary conservation

Given ledger states before and after moving ADA into or out of the Store, include its actual balance once in the total across monetary pots. Do not add the live allocated amounts again, and do not omit Store ADA merely because it has no stake or voting weight.

<a id="ds-state-initialization" name="ds-state-initialization"></a>

### 3.6 Initialization

> **Establish the Store’s initial state at the Conway-to-Dijkstra upgrade.**
>
> Existing outputs remain implicit; Store balance $=$ outstanding deposits $= 0$. No existing pot funds initialization.

**Decision:** Agreed.

At the Conway-to-Dijkstra upgrade, preserve every existing output reference and its full ADA and native-asset value. Every such output remains an implicit-deposit output. Do not automatically convert it to a store-backed output or extract its implicit minimum ADA into the new Store.

Initialize:

```text
storeBalance = 0
totalUTxODeposits = 0
```

The upgrade takes no funding from existing ledger pots. Subsequent transactions can introduce store-backed outputs through the normal declaration, exact contribution and batch-funding rules; being funded by a translated output gives no exemption. Their presence and exactness cases live under the corresponding Tx responsibilities. Spending a translated implicit output itself releases no Store deposit, as checked under `DS-STATE-ALLOCATIONS`.

Collateral return creation remains governed by the collateral failure-path rules. This initial upgrade creates no historical store-backed outputs whose pricing basis must be migrated; later historical-pricing requirements are deferred under `DS-PRICING-HISTORY`.

<a id="ds-state-initialization-n01" name="ds-state-initialization-n01"></a>

#### 3.6.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/InitializationSpec.hs#L11) - preserves existing output references and values and keeps those outputs implicit

Given a valid Conway UTxO, translate it to Dijkstra with the same references, ADA and native assets, keeping every output implicit. The upgrade must neither rewrite output ownership references nor extract implicit deposits.

<a id="ds-state-initialization-n02" name="ds-state-initialization-n02"></a>

#### 3.6.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/InitializationSpec.hs#L12) - initializes Store balance and UTxO capacity deposit obligations to zero

Given the Conway-to-Dijkstra upgrade, expect both the new Store balance and its outstanding obligations to be zero. Existing outputs require no external allocation because they remain implicit.

<a id="ds-state-initialization-n03" name="ds-state-initialization-n03"></a>

#### 3.6.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/InitializationSpec.hs#L13) - does not transfer funds from another ledger pot during initialization

Given the upgrade, compare existing monetary pots before and after Store initialization. No transfer from those pots is needed to create an empty Store.

<a id="ds-state-recovery" name="ds-state-recovery"></a>

### 3.7 Recovery

> **Preserve accepted state through serialization, restoration and rollback.**
>
> Outputs + allocation records + Store balance must remain consistent; recorded deposits are retained without repricing.

**Decision:** Agreed; precise ledger-state APIs and encodings remain implementation work.

Preserve each live store-backed output's allocated amount in ledger-state serialization and snapshots. Recovering state must preserve that accepted amount; it must not reprice the output from its decoded contents or current protocol parameters. This metadata belongs to ledger state, without adding fields to the transaction output or changing its `TxIn` reference.

Rollback must restore the UTxO, its allocated-deposit records and the actual Store balance together. Restoring only the output values or only the balance could leave missing obligations, orphan records or a mismatched Store. The recovered state must have the same relationships established by `DS-STATE-ALLOCATIONS` and `DS-STATE-BALANCE`.

This preservation requirement is already agreed at fixed prices. It does not choose the additional historical pricing representation or repricing policy deferred under `DS-PRICING-HISTORY`.

<a id="ds-state-recovery-n01" name="ds-state-recovery-n01"></a>

#### 3.7.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/RecoverySpec.hs#L11) - preserves allocated UTxO capacity deposits through state serialization and restoration

Given state containing live store-backed outputs, serialize and restore it with their allocated amounts preserved. Restoration must recover the accepted obligations rather than recompute them from a new output serialization.

<a id="ds-state-recovery-n02" name="ds-state-recovery-n02"></a>

#### 3.7.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/State/RecoverySpec.hs#L12) - restores outputs, UTxO capacity deposit records and Store balance together on rollback

Given a state update followed by rollback, restore the previous outputs, allocated records and Store balance as one consistent state. Restoring only some components could leave unmatched obligations or an incorrect actual pot.

<a id="derived-distributions" name="derived-distributions"></a>

## 4. Derived distributions

> **Determine stake and voting power from the resulting ledger under their existing rules.**

<a id="ds-stake" name="ds-stake"></a>

### 4.1 Stake

> **Determine which output ADA contributes under the existing staking rules.**
>
> Implicit output: full ADA · Store-backed output: application ADA · External deposit: no additional stake.

**Decision:** Exclude DepositStore UTxO capacity deposits from stake for the current prototype.

Apply the existing staking eligibility and delegation rules to the output's ADA contribution:

```text
stakeContribution(ImplicitDepositTxOut output) = full ADA in output
stakeContribution(StoreBackedTxOut output) = application ADA in output
```

An eligible implicit output containing 10 ADA therefore contributes 10 ADA. A store-backed output containing 8 application ADA with a 2 ADA allocated deposit contributes only 8 ADA where otherwise eligible. Do not attribute its external allocated deposit to its staking credential or add the global Store balance separately to stake totals.

An allocation or release affects stake through the outputs and other existing stake updates actually applied. It creates no independent Store attribution. Ordinary success leaves collateral settlement and collateral return unapplied; accepted phase-2 failure derives stake effects from collateral consumption and return, without applying ordinary outputs or ordinary Store operations.

Existing registration, eligibility, delegation and snapshot timing remain in force. A contribution amount is not a claim that every output currently participates in stake. The exclusion also does not remove Store ADA from monetary conservation under `DS-STATE-CONSERVATION`. Voting weight is checked separately under `DS-VOTING`.

<a id="ds-stake-n01" name="ds-stake-n01"></a>

#### 4.1.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs#L11) - counts the full ADA in implicit outputs under the existing staking rules

Given an implicit output eligible under the existing staking rules, use its full output ADA as its stake contribution. Keeping the legacy minimum inside that value does not create an external amount to subtract.

<a id="ds-stake-n02" name="ds-stake-n02"></a>

#### 4.1.2 [N02](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs#L12) - counts only application ADA in store-backed outputs under the existing staking rules

Given an eligible store-backed output, count its application ADA and exclude its externally allocated deposit. For 8 application ADA and a 2 ADA deposit, the contribution base is 8 ADA.

<a id="ds-stake-n03" name="ds-stake-n03"></a>

#### 4.1.3 [N03](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs#L13) - does not add the global Store balance to stake totals

Given a nonzero global Store balance, do not add that pot separately to stake totals or assign it to output credentials. Only otherwise eligible output ADA follows the existing stake rules.

<a id="ds-stake-n04" name="ds-stake-n04"></a>

#### 4.1.4 [N04](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs#L14) - ordinary success ⇒ a net allocation changes stake only through its applied ordinary UTxO effects

Given an ordinary successful allocation, derive stake effects from the ordinary outputs and existing stake updates actually applied. Funding the external deposit creates no separate credited stake.

<a id="ds-stake-n05" name="ds-stake-n05"></a>

#### 4.1.5 [N05](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs#L15) - ordinary success ⇒ a net release changes stake only through its applied ordinary UTxO effects

Given an ordinary successful release, derive stake effects from the resulting ordinary outputs under existing eligibility rules. The released amount does not create an additional Store attribution beside those effects.

<a id="ds-stake-n06" name="ds-stake-n06"></a>

#### 4.1.6 [N06](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs#L16) - ordinary success ⇒ unapplied collateral settlement and collateral return add no stake effects

Given ordinary success with supplied collateral and a possible return, do not apply stake effects from collateral consumption or that return. Those collateral effects remain unapplied on this outcome.

<a id="ds-stake-n07" name="ds-stake-n07"></a>

#### 4.1.7 [N07](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs#L17) - accepted phase-2 failure ⇒ stake follows collateral consumption and return without effects from unapplied ordinary allocations, releases or outputs

Given an accepted phase-2 failure, update stake only for collateral consumption and return under the existing rules. Unapplied ordinary outputs, allocations and releases must not affect the resulting stake distribution.

<a id="ds-stake-n08" name="ds-stake-n08"></a>

#### 4.1.8 [N08](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/StakeSpec.hs#L18) - preserves existing staking eligibility, delegation and snapshot timing after allocation, release and collateral effects

Given allocation, release or collateral effects, retain existing registration, eligibility, delegation and snapshot timing. Excluding external deposits changes the ADA contribution base without creating new eligibility or applying a snapshot early.

<a id="ds-voting" name="ds-voting"></a>

### 4.2 Voting

> **Exclude external deposits from additional voting power.**
>
> Application ADA follows existing eligibility rules. Store ADA remains part of monetary conservation, but adds no voting weight.

**Decision:** Exclude DepositStore UTxO capacity deposits from voting power for the current prototype.

ADA held in the Store creates no additional voting weight. Do not attribute a store-backed output's allocated deposit to its credential or count the global Store balance separately in voting distributions. The application ADA remaining in outputs continues through existing eligibility, delegation and snapshot rules.

This concerns the resulting voting distribution, separately from the stake observations in `DS-STAKE`. The excluded Store ADA still exists in the monetary total checked by `DS-STATE-CONSERVATION`.

<a id="ds-voting-n01" name="ds-voting-n01"></a>

#### 4.2.1 [N01](../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/VotingSpec.hs#L11) - does not count allocated UTxO capacity deposits or Store balance as additional voting power

Given outputs with allocated deposits and a nonzero Store pot, derive voting weight using the existing eligible funds and distribution rules. Neither the recorded allocations nor the global balance may be added as extra voting power.

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

DS-TX-EXACTNESS-CONTRIBUTION requires exact UTxO capacity deposit accounting and rejects voluntary excess net
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
> Settlement output ADA $\ge$ release amount does not establish the origin of its coins. SubTx fee contributions must remain possible.

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
inequality `ordinaryProducedADA ≥ ordinaryConsumedADA + amount` is therefore not
adopted.

For a local release, the accounting identity can be expressed as:

```text
netADAExport = ordinaryConsumedADA + amount - ordinaryProducedADA
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

> **Choose concrete types, encodings and migration for the agreed logical state.**
>
> The representation must preserve allocation records, Store balance and recovery semantics.

**Decision:** Logical allocation records are agreed; concrete representation and migration
remain implementation work.

The live-entry concept is agreed under DS-STATE-ALLOCATIONS. The concrete APIs, era-specific ledger-state encoding and migration still require implementation. These details must preserve the specified initialization, recorded amounts and recovery behavior.

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

Construction and CBOR/JSON bounds are also covered by the existing
[declaration codec specification](../eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Binary/Golden.hs).
These representation checks establish which forms can be expressed. Presence,
exactness and conservation determine whether an expressed declaration is valid in its transaction.
