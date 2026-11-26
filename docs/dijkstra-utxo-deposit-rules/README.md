# Dijkstra ledger rules for minimum-ADA and deposit-backed outputs

[Verification record](verification.md) · [CIP draft](https://github.com/input-output-hk/arc-cardano-minutxo-alternatives/blob/codex/cip-output-coexistence/CIP-%3F%3F%3F%3F/README.md) · [Latest version of this page](https://github.com/nhenin/cardano-ledger-specs/blob/v2-minutxo/docs/dijkstra-utxo-deposit-rules/README.md)

The *UTxO Deposit versus UTxO Minimum ADA* proposal describes two ways to back an output's storage. A minimum-ADA output carries its reserve in its own value. For a deposit-backed output, the ledger accounts for the deposit separately.

## Table of contents

| Chapter | Question it answers |
| --- | --- |
| [1. Domain model](chapters/domain-model.md) | What does each form of output carry, what does the Store record, and how is the required deposit calculated? |
| [2. Transaction rules](chapters/transaction-rules.md) | What must TopTx and SubTx declare, who authorizes a release, and how does the ledger check accounting, settlement, minimum coin and collateral? |
| [3. Ledger effects](chapters/ledger-effects.md) | After validation, which inputs, outputs, deposits and fees change on ordinary success or on a phase-2 failure? |
| [4. Derived distributions](chapters/derived-distributions.md) | How do stake and voting power follow from the resulting ledger state? |
| [Appendices](chapters/appendices.md) | Where are the open design questions, tag migration, implementation references and detailed net-change test cases? |

## How the documents fit together

The [domain model](chapters/domain-model.md) defines the amounts used by the [transaction rules](chapters/transaction-rules.md). A transaction's [deposit declaration](chapters/transaction-rules.md#ds-tx-declarations) is one part of those checks. [Ledger effects](chapters/ledger-effects.md) describes how the accepted outcome updates state, and [derived distributions](chapters/derived-distributions.md) describes how that state contributes to stake and voting power.

For example, an input with 1.6 ADA of embedded reserve can fund a new output requiring a 2 ADA external deposit. The [net-change rule](chapters/transaction-rules.md#ds-tx-accounting-net-change) requires `Allocate 0.4 ADA`, while the [Store balance](chapters/ledger-effects.md#ds-state-balance) increases by 2 ADA. [Appendix D](chapters/appendices.md#net-change-test-cases) lists the SubTx and TopTx exactness cases. The separate [verification record](verification.md#signed-backing-change-for-mixed-output-forms--24-november-2026) gives the test results for this mixed-output example and the [verification contents](verification.md#table-of-contents) list the other runs.
