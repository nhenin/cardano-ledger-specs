# Dijkstra DepositStore transaction rules

This document records the agreed transaction rules for the DepositStore prototype.
It is the reference for implementing ledger validation and writing acceptance tests.
Rules are added as their business meaning is agreed.

The rules below were agreed on 5 and 6 October 2026. The transaction interfaces and
codecs exist; enforcement of these rules in the ledger is **not implemented yet**.

## Transaction body scope

DS-TX-001 applies separately to each top-level transaction body and each
sub-transaction body:

| Body | Operation field | Own outputs |
| --- | --- | --- |
| `DijkstraTxBodyRaw TopTx era` | `dtbrDepositStoreChange` | `dtbrOutputs` |
| `DijkstraTxBodyRaw SubTx era` | `dstbrDepositStoreChange` | `dstbrOutputs` |

Both operation fields use `StrictMaybe`. `SNothing` declares no DepositStore
operation and requests no delegation. `SJust operation` explicitly declares the
operation carried by that body. The TopTx field declares the net change for the batch;
SubTx fields specify their contributions and where they are accounted for, as
defined in DS-TX-002.

For DS-TX-001, an output means the `TxOut` inside a `Sized` element of the body's
own output sequence. The cached size does not affect the check. A TopTx's own
outputs do not include its SubTx outputs. Spent outputs are obtained by resolving
the body's own spending inputs against the applicable UTxO. Reference inputs
do not consume outputs or release backing. Collateral inputs and collateral
return have separate rules under DS-COLL-001 and DS-COLL-002.

## Explicit declaration for store backed outputs

**Rule identifier:** `DS-TX-001`

**Decision:** Agreed

**Enforcement:** Pending

A transaction body that creates or spends at least one `StoreBackedTxOut`
**must** declare a DepositStore operation in its own operation field.

Define:

- `outputs(body)`: the body's own outputs, after removing the `Sized` wrapper.
- `spentOutputs(body)`: the outputs resolved from the body's own spending inputs.
- `change(body)`: the operation field for that body's level, as listed above.
- `hasStoreBackedOutput(body)`: at least one element of `outputs(body)` has the
  `StoreBackedTxOut` constructor.
- `spendsStoreBackedOutput(body)`: at least one element of `spentOutputs(body)`
  has the `StoreBackedTxOut` constructor.

The required condition is:

```text
hasStoreBackedOutput(body) OR spendsStoreBackedOutput(body)
    => change(body) /= SNothing
```

Equivalently:

```text
change(body) = SNothing
    => every element of outputs(body) and spentOutputs(body)
        is an ImplicitDepositTxOut
```

If either condition is true and `change(body)` is `SNothing`, reject the body.
The proposed predicate failure name is `MissingDepositStoreChange`; its
constructor and payload have not been implemented. DS-TX-005 additionally
requires a withdrawal contribution when store-backed outputs are spent without
creating any new store-backed outputs.

## Acceptance cases

These results concern **DS-TX-001 only**. Passing this check does not establish
that the transaction satisfies funding, withdrawal, or other ledger rules.

| Own spent outputs | Own created outputs | Own operation field | Result for DS-TX-001 |
| --- | --- | --- | --- |
| Only implicit-deposit outputs, or empty | Only implicit-deposit outputs, or empty | `SNothing` | Pass |
| At least one store-backed output | Only implicit-deposit outputs, or empty | `SNothing` | Reject |
| Any | At least one store-backed output | `SNothing` | Reject |
| Any | Any | `SJust operation` | Pass |

The same cases apply to TopTx and SubTx. In particular:

- A TopTx declaration does not replace a missing SubTx declaration. If the SubTx
  creates or spends a store-backed output with `SNothing`, reject that SubTx even
  when the TopTx declares an operation.
- A SubTx declaration does not replace a missing TopTx declaration either. If
  the TopTx creates or spends a store-backed output with `SNothing`, reject the
  TopTx even when its SubTx bodies declare operations.
- A SubTx that requests funding through `SubTxRequestDepositFromTopTx amount`
  has made an explicit declaration and passes this presence check. DS-TX-010
  separately validates that TopTx fulfils the request.
- A TopTx whose own spent and created outputs are all implicit-deposit outputs
  and whose field is `SNothing`, containing a SubTx with store-backed outputs
  and an explicit operation, passes this check for both bodies. This says nothing
  about overall validity: DS-TX-009 rejects the missing TopTx declaration.
- Creating store-backed outputs still requires a declaration when the net
  funding requirement is zero. TopTx expresses this with
  `SJust NoDepositStoreChange`; SubTx uses `SJust SubTxNoDepositStoreChange`
  under DS-TX-008.

## Batch net change and accounting responsibility

**Rule identifier:** `DS-TX-002`

**Decision:** Agreed

**Enforcement:** Pending

The TopTx DepositStore operation declares the net change for the entire batch:
total deposits minus total withdrawals, including the contributions of its SubTx
bodies. It is not an additional operation to add on top of those contributions.
The declared net change must match the batch's exact change in backing
obligations under DS-TX-003 and be funded under DS-TX-004.

Delegation changes where a SubTx contribution is accounted for:

- `SubTxNoDepositStoreChange`: explicitly declare zero contribution and no
  delegation request.
- `SubTxDepositToStore amount`: account for the deposit in the SubTx.
- `SubTxRequestDepositFromTopTx amount`: account for the deposit in the TopTx.
- `SubTxWithdrawFromStore amount (SubTxOutput index)`: account for the withdrawal
  in the SubTx and settle it in its named output.
- `SubTxWithdrawFromStore amount DelegateToTopTx`: account for the withdrawal
  in the TopTx; its settlement must satisfy DS-TX-006 and DS-TX-007.

Every contribution is included in the batch total regardless of delegation.
Changing its accounting location must not count the contribution again, remove
its backing obligation, or change the amount declared by the SubTx. A body can
have its operation accounted for locally without requiring its own inputs to
fund that operation independently. A SubTx may remain financially imbalanced;
TopTx must balance the complete batch, including its SubTx contributions.

Define `batchDeposits` and `batchWithdrawals` as the nonnegative totals of the
batch's deposit and withdrawal contributions, each counted once regardless of
delegation. Then:

```text
txTotalNetDeposit = batchDeposits - batchWithdrawals

topTxNetDeposit + sum(subTxLocalNetDeposits) = txTotalNetDeposit
```

`txTotalNetDeposit` is the signed net change declared by TopTx for the entire
transaction, including every SubTx. `topTxNetDeposit` is the portion handled
by TopTx, including delegated operations. `subTxLocalNetDeposits` contains only
contributions handled locally by SubTx bodies; DS-TX-006 gives the calculation.
These are signed accounting quantities: deposits are positive and withdrawals
negative. This notation does not require negative `Coin` amounts in the
transaction interface or additional declared amount fields.

The TopTx's accounting allocation can have a different sign from its declared
batch net change. For example, a local SubTx deposit of 5 ADA and a withdrawal
of 3 ADA delegated to TopTx allocate `+5` to SubTx and `-3` to TopTx, while TopTx
declares the batch's `DepositToStore 2`.

DS-TX-001 and DS-TX-009 determine when TopTx must declare a change. When present,
its declaration must represent the total as follows:

| Batch net change | TopTx declaration |
| --- | --- |
| Positive | `SJust (DepositToStore positiveAmount)` |
| Negative | `SJust (WithdrawFromStore positiveAmount settlement)` |
| Zero | `SJust NoDepositStoreChange` |

`positiveAmount` is the absolute value of the net change, represented by
`PositiveCoin`. This abstract type permits only 1 through 18446744073709551615
lovelace, matching the positive part of the CBOR `Coin` range. Its checked
constructor and CBOR/JSON decoders reject zero, negative and out-of-range amounts.

`NoDepositStoreChange` encodes as CBOR `[2]` and JSON `{"kind":"noChange"}`.
Existing deposit and withdrawal tags remain `0` and `1`, respectively.
`DepositToStore 0` and `WithdrawFromStore 0 settlement` are no longer valid forms.
An absent field (`SNothing`) remains distinct from an explicit zero declaration;
it fails DS-TX-001 when TopTx creates or spends store-backed outputs. The interface expresses
this distinction; the ledger must still enforce DS-TX-001 and reconcile the net
amount with the batch's contributions.

For example, a batch depositing 5 ADA and withdrawing 3 ADA declares
`DepositToStore 2`. On successful settlement, the store balance increases by
2 ADA. Reversing those amounts requires `WithdrawFromStore 2 settlement` and
decreases the store balance by 2 ADA. The settlement choice describes TopTx's
participation as defined in DS-TX-006. These examples use ADA for readability; code amounts are in
lovelace.

Netting determines the store's balance change. It does not remove the obligation
to validate individual declarations, fulfil delegation requests, or authorize
withdrawal contributions. A withdrawal delegated to TopTx can offset deposits
without causing a separate withdrawal from the store. In the 5 ADA deposit and
3 ADA delegated withdrawal example, TopTx deposits only 2 ADA; it does not also
withdraw 3 ADA. No additional TopTx withdrawal destination is needed in this case.
The TopTx output index applies when the net operation is `WithdrawFromStore`.
With equal deposits and withdrawals, TopTx declares `NoDepositStoreChange` and
the net store transfer is zero.

For a batch containing deposits only, the accounting amounts must reconcile as:

```text
topTxNetDeposit + sum(subTxLocalNetDeposits) = txTotalNetDeposit
```

`topTxNetDeposit` includes deposits delegated to TopTx and its own
contribution. It does not include deposits already accounted for in SubTx.
All terms in this deposit-only equation are nonnegative. The equation describes
accounting allocation; it is not sufficient on its own to validate backing or
delegation requests.

The TopTx can also create its own store-backed outputs and contribute a deposit
for them. For a deposit-only batch, the total can therefore be expressed as:

```text
txTotalNetDeposit
    = ownTopTxDeposit + sum(localSubTxDeposits) + sum(delegatedSubTxDeposits)

topTxNetDeposit
    = ownTopTxDeposit + sum(delegatedSubTxDeposits)
```

`ownTopTxDeposit` is the contribution attributable to TopTx's own activity; it
is not a separate field in the current interface. Its required amount is subject
to the backing and release policy. It need not be zero.

For example, one SubTx contributes 3 ADA and TopTx's own store-backed outputs
require an additional contribution of 2 ADA. There are no withdrawals:

| SubTx declaration | TopTx declaration | Accounted in SubTx | Accounted in TopTx | Total deposited into store |
| --- | --- | --- | --- | --- |
| `SubTxDepositToStore 3` | `DepositToStore 5` | 3 | 2 | 5 |
| `SubTxRequestDepositFromTopTx 3` | `DepositToStore 5` | 0 | 5 | 5 |

These examples use ADA amounts for readability. `Coin` amounts in the code are
denominated in lovelace. The store receives 5 ADA in either case. If TopTx's own
contribution were zero, the total would instead be 3 ADA in both cases.
These credits assume successful settlement of the batch. The same once-only
accounting requirement applies to withdrawals.

DS-TX-006 distinguishes TopTx settlement participation while allowing mixed
TopTx and SubTx destinations. DS-TX-007 validates the selected output and its
coin amount, using the derived TopTx amount defined in DS-TX-006.

## Exact backing accounting for each body

**Rule identifier:** `DS-TX-003`

**Decision:** Agreed

**Enforcement:** Pending

Each TopTx and SubTx body must account exactly for its own change in backing
obligations. Reject both an excessive and an insufficient contribution, even
when another body's opposite error makes the batch total correct. This backing
accounting condition is separate from financial conservation: SubTx may be
financially imbalanced, but the completed TopTx batch must balance.

For each body, define:

- `releasedBacking(body)`: backing released by spending that body's inputs,
  under the agreed pricing and release policy. This is not the store's global
  available balance.
- `createdBacking(body)`: backing required for that body's own newly created
  store-backed outputs.
- `declaredNetContribution(body)`: the signed contribution attributable to that
  body, with deposits positive and withdrawals negative.

Require:

```text
releasedBacking(body) + declaredNetContribution(body)
    = createdBacking(body)
```

Equivalently, separating positive deposits and withdrawals:

```text
releasedBacking(body) + declaredDeposit(body)
    = createdBacking(body) + declaredWithdrawal(body)
```

Thus `declaredNetContribution(body)` must equal
`createdBacking(body) - releasedBacking(body)`. Positive differences require
an exact deposit, negative differences require an exact withdrawal, and zero
requires a zero contribution, subject to the declaration-presence rules.

For example, when a body releases no backing and creates outputs requiring
2 ADA, declaring a deposit of 3 ADA is an accounting error. A deposit of 1 ADA
also fails; the correct contribution is exactly 2 ADA. The remaining transaction
funds may be assigned to regular outputs under the financial balance rules.

For SubTx, use the declared contribution regardless of accounting delegation:

| SubTx declaration | Contribution for that SubTx's backing accounting |
| --- | --- |
| `SubTxNoDepositStoreChange` | `0`; the exact backing and withdrawal rules still apply |
| `SubTxDepositToStore amount` | `+amount` |
| `SubTxRequestDepositFromTopTx amount` | `+amount` |
| `SubTxWithdrawFromStore amount target` | `-amount`, for either target |
| `SNothing` | `0`; DS-TX-001 rejects absence if the body creates or spends any store-backed output |

For TopTx's own backing accounting, remove all SubTx contributions from the declared batch
net change, including contributions delegated to TopTx:

```text
declaredNetContribution(TopTx)
    = txTotalNetDeposit
        - sum(declaredNetContribution(subTx))
```

This is the contribution attributable to TopTx's own activity, not the financial
amount accounted for in TopTx, which also includes delegated contributions.
Each declared contribution is counted at its full amount. A deposit request
counts toward the originating SubTx's declared backing contribution, but acceptance also
requires its funding to be fulfilled in the batch accounting. Passing this
equality alone does not establish financial balance or a valid withdrawal
destination. Summing the exact body contributions gives the batch requirement:

```text
txTotalNetDeposit = sum(createdBacking(body) - releasedBacking(body))
```

The sum includes TopTx's own activity and every SubTx body exactly once,
regardless of delegation.

For example, SubTx A releases no backing, creates outputs requiring 3 ADA and
declares a deposit of 5 ADA. SubTx B also releases none and creates outputs
requiring 3 ADA, but declares only 1 ADA. Both fail this exact accounting check.
The batch must be rejected even though the combined deposit of 6 ADA equals
the combined requirement. Each SubTx must explicitly declare exactly 3 ADA,
locally or through a request to TopTx.

DS-STORE-003 defines the pricing formula and assigned backing for the current
scope. Voluntary over-deposits through these operations are not permitted.
The current scope assumes a constant `coinsPerUTxOByte`;
DS-STORE-002 records the deferred requirement to retain historical pricing.
Collateral effects follow DS-COLL-001 through DS-COLL-004.

## Financial balance of TopTx

**Rule identifier:** `DS-TX-004`

**Decision:** Agreed

**Enforcement:** DepositStore integration pending

TopTx must balance the complete batch. SubTx may be individually imbalanced;
their contributions must be included in the final conservation check.

Expressing the existing consumed and produced values before adding the new
DepositStore term, require:

```text
txTotalNetWithdrawal = max(0, -txTotalNetDeposit)

consumedValue(batch) + inject(txTotalNetWithdrawal)
    = producedValue(batch) + inject(max(0, txTotalNetDeposit))
```

`txTotalNetDeposit` is positive for `DepositToStore`, negative for
`WithdrawFromStore`, and zero for `NoDepositStoreChange`.
`txTotalNetWithdrawal` is the amount in TopTx's `WithdrawFromStore`, or zero
otherwise. Absence of a declaration is subject to the separate presence and
reconciliation rules.

Consumed and produced values include the complete batch's inputs, outputs and
other existing ledger terms, including fees and existing deposit/refund rules.
The net store amount is counted once, using TopTx's declaration; SubTx store
contributions are not added again. This equality preserves all assets, whereas
DS-TX-003 concerns exact ADA backing accounting for each body.

## Withdrawal when leaving store backed outputs

**Rule identifier:** `DS-TX-005`

**Decision:** Agreed

**Enforcement:** Pending

When a body spends store-backed outputs and creates no new store-backed outputs,
it must explicitly account for withdrawal of the released backing. Omitting the
declaration or assigning a zero contribution to that body does not satisfy this
rule. Released backing must not silently remain in the store in this case.

```text
spendsStoreBackedOutput(body) AND NOT hasStoreBackedOutput(body)
    => declaredNetContribution(body) = -releasedBacking(body)
```

The released amount is the backing assigned to the consumed store-backed
outputs under DS-STORE-003. This rule does not grant access to unrelated store surplus.
It applies to bodies creating only implicit-deposit outputs, as well as bodies
creating no outputs; a withdrawal's target must still satisfy the settlement
rules.

For SubTx, the withdrawal contribution is declared with
`SubTxWithdrawFromStore amount target`, including explicit delegation when TopTx
accounts for it. For TopTx's own activity, the contribution is derived as in
DS-TX-003. The TopTx field continues to declare the entire batch's net change,
so it may declare a deposit or explicit zero when other contributions offset
the withdrawal. This does not erase the body's withdrawal contribution.

For example, a SubTx releasing 3 ADA of backing and creating only implicit-deposit
outputs declares a withdrawal of 3 ADA. If another SubTx contributes a 5 ADA
deposit and TopTx has no own contribution, TopTx declares `DepositToStore 2`.
The store receives 2 ADA net; no separate gross TopTx withdrawal is required.

## TopTx participation in withdrawal settlement

**Rule identifier:** `DS-TX-006`

**Decision:** Agreed

**Interface:** Implemented

**Enforcement:** Pending

A net withdrawal declares the batch amount and, separately, whether TopTx
receives a share:

```haskell
WithdrawFromStore !PositiveCoin !TopTxWithdrawalSettlement

data TopTxWithdrawalSettlement
  = NoTopTxWithdrawal
  | TopTxWithdrawalTo !TxIx
```

`NoTopTxWithdrawal` means that no withdrawal remains to be settled in TopTx's
outputs after reconciling the contributions. Destinations are already declared
by the corresponding `SubTxWithdrawFromStore amount (SubTxOutput index)`
operations. This does not mean zero batch withdrawal: the amount is positive.
It must not leave an outstanding TopTx settlement requirement unfulfilled.

`TopTxWithdrawalTo index` names a zero-based index into TopTx's own outputs.
It permits both TopTx-only settlement and mixed settlement in TopTx and SubTx
outputs. The selected TopTx output already includes TopTx's share. That share
is determined from the accounting; it is not automatically the entire amount
in `WithdrawFromStore`.

The operation's amount always remains the entire batch's net withdrawal under
DS-TX-002. It is not an additional payment or a second credit to SubTx outputs.
Offsetting deposits participate in the net calculation, so the declared amount
need not equal the gross sum of local SubTx withdrawals.

Derive the TopTx amounts from the signed total and the SubTx declarations:

```text
txTotalNetWithdrawal = max(0, -txTotalNetDeposit)

topTxNetDeposit = txTotalNetDeposit - sum(subTxLocalNetDeposits)
topTxNetWithdrawal = max(0, -topTxNetDeposit)
```

Each SubTx contributes the following signed amount to `subTxLocalNetDeposits`:

| SubTx declaration | Local net deposit |
| --- | --- |
| `SubTxNoDepositStoreChange` | `0`; no delegation |
| `SubTxDepositToStore amount` | `+amount` |
| `SubTxWithdrawFromStore amount (SubTxOutput index)` | `-amount` |
| `SubTxRequestDepositFromTopTx amount` | `0`; TopTx handles the deposit |
| `SubTxWithdrawFromStore amount DelegateToTopTx` | `0`; TopTx handles the withdrawal |
| `SNothing` | `0`; declaration requirements still apply |

Delegated contributions are already included in `txTotalNetDeposit`. Do not
subtract them as local contributions: they remain TopTx's responsibility.
These amounts are derived; no additional TopTx amount field is required.
Unlike TopTx's own backing contribution in DS-TX-003, `topTxNetDeposit` includes
delegated operations.

For a net-withdrawal transaction (`txTotalNetDeposit < 0`), require:

| Derived TopTx amount | Required settlement |
| --- | --- |
| `topTxNetWithdrawal == 0` | `NoTopTxWithdrawal` |
| `topTxNetWithdrawal > 0` | `TopTxWithdrawalTo index`, with the selected output containing at least `topTxNetWithdrawal` |

`txTotalNetWithdrawal` is the amount actually withdrawn from the store for the
entire transaction. `topTxNetWithdrawal` is the amount to settle in TopTx's
selected output. Deposits supplied locally by SubTx bodies can make the latter
larger than the former. For example, a local SubTx deposit of 3 ADA and TopTx's
own withdrawal contribution of 5 ADA give:

```text
txTotalNetDeposit = -2
txTotalNetWithdrawal = 2
topTxNetDeposit = -2 - 3 = -5
topTxNetWithdrawal = 5
```

TopTx declares `WithdrawFromStore 2 (TopTxWithdrawalTo index)`. The selected
output contains at least 5 ADA: 3 ADA supplied by the SubTx and 2 ADA from the
store. These funds are included in the batch conservation check once.
Conversely, a local SubTx withdrawal of 5 ADA and a TopTx deposit contribution
of 3 ADA give `topTxNetDeposit = 3` and `topTxNetWithdrawal = 0`; the declaration
is `WithdrawFromStore 2 NoTopTxWithdrawal`.

This settlement requirement applies to the `WithdrawFromStore` branch. A net
deposit or explicit zero still follows DS-TX-002 and does not introduce a TopTx
withdrawal destination merely because its derived accounting portion is negative.

For example, with no offsetting deposits:

| Local SubTx withdrawals | TopTx share | TopTx declaration |
| --- | --- | --- |
| 3 ADA | 0 | `WithdrawFromStore 3 NoTopTxWithdrawal` |
| 0 | 2 ADA | `WithdrawFromStore 2 (TopTxWithdrawalTo index)` |
| 3 ADA | 2 ADA | `WithdrawFromStore 5 (TopTxWithdrawalTo index)` |

These amounts are in ADA for readability. Each SubTx retains its own declared
amount and destination. In the mixed example, 5 ADA leaves the store in total:
3 ADA is assigned to SubTx outputs and 2 ADA to the selected TopTx output.

CBOR encodes the settlement as `[0]` for `NoTopTxWithdrawal` or `[1, index]`
for `TopTxWithdrawalTo index`. A withdrawal is now `[1, amount, settlement]`,
replacing the previous prototype's bare index. JSON uses a `settlement` object
with kind `noTopTxWithdrawal`, or kind `topTxOutput` and an `outputIndex` field.
The interface expresses these cases. DS-TX-007 specifies output validation;
implementing the calculation and ledger enforcement remains pending.

## Withdrawal destination validation

**Rule identifier:** `DS-TX-007`

**Decision:** Agreed

**Enforcement:** Pending

Each declared withdrawal destination must refer to an existing output in the
body that owns the index. Its coin value must be at least the withdrawal share
allocated to that destination. The output may also contain other funds.

```text
0 <= index < length(outputs(body))
coin(outputs(body)[index]) >= allocatedWithdrawalShare(body, index)
```

For `SubTxWithdrawFromStore amount (SubTxOutput index)`, resolve the index in
that SubTx's own output sequence and use `amount` as its allocated share.
For `TopTxWithdrawalTo index`, resolve the index in TopTx's own output sequence
and use `topTxNetWithdrawal` derived in DS-TX-006, not automatically
the batch's entire net withdrawal amount. Neither index refers to an input,
another body's outputs, or collateral return.

The selected output already includes the allocated coins. Applying the
transaction must not add the amount to the output a second time. This check
does not replace financial conservation, exact backing accounting or withdrawal
authorization under DS-TX-011. `NoTopTxWithdrawal` has no TopTx index to validate;
DS-TX-006 still requires no outstanding TopTx settlement share.

For example, with a batch net withdrawal of 5 ADA split as 3 ADA in a SubTx and
2 ADA in TopTx, the selected TopTx output must contain at least 2 ADA. An output
containing 2 ADA or 4 ADA passes this amount check; an output containing 1 ADA
or a missing output fails. The selected SubTx output must contain at least
its own declared 3 ADA.

## Explicit zero contribution and positive SubTx amounts

**Rule identifier:** `DS-TX-008`

**Decision:** Agreed

**Interface:** Implemented

**Enforcement:** Amount bounds enforced by construction and decoding; ledger rules pending

SubTx declares zero contribution with its own explicit constructor. All
deposits, withdrawals and deposit-funding requests carry a strictly positive
amount, including withdrawals delegated to TopTx:

```haskell
data DepositStoreSubTxChange
  = SubTxNoDepositStoreChange
  | SubTxDepositToStore !PositiveCoin
  | SubTxRequestDepositFromTopTx !PositiveCoin
  | SubTxWithdrawFromStore !PositiveCoin !SubTxWithdrawalTarget
```

`SubTxNoDepositStoreChange` contributes zero to both the SubTx's backing
contribution and its local accounting amount. It requests no delegation and
has no withdrawal destination. It is distinct from `SNothing`: the latter
makes no declaration and fails DS-TX-001 when the SubTx creates or spends a
store-backed output.

For example, a SubTx spending and creating store-backed outputs with equal
backing obligations can explicitly declare zero, provided all other rules
hold. This does not bypass DS-TX-003 exact accounting or DS-TX-005 withdrawal when
leaving store-backed outputs. If either rule requires a nonzero contribution,
an explicit zero does not satisfy it.

`PositiveCoin` permits 1 through 18446744073709551615 lovelace, as for TopTx.
Checked construction and CBOR/JSON decoding reject zero, negative and
out-of-range operation amounts. In particular, zero cannot encode a deposit,
a funding request or a withdrawal.

The explicit zero encodes as CBOR `[3]` and JSON `{"kind":"noChange"}`.
Existing SubTx tags remain `0` for a deposit, `1` for a withdrawal and `2` for
a funding request. Previously accepted zero-amount operation encodings now
fail decoding; an explicit zero must use the new constructor.

## TopTx declaration required by a SubTx declaration

**Rule identifier:** `DS-TX-009`

**Decision:** Agreed

**Enforcement:** Pending

If any SubTx declares a DepositStore operation, TopTx must explicitly declare
the entire transaction's net DepositStore change. This applies whether the
SubTx operation is local, delegated, or explicitly zero, and whether or not
TopTx creates or spends any store-backed outputs of its own.

```text
any(change(subTx) /= SNothing for subTx in subTxs(topTx))
    => change(topTx) /= SNothing
```

TopTx's declaration represents `txTotalNetDeposit` under DS-TX-002. The
declarations are not additional transfers: each contribution is counted once.
The presence of a TopTx declaration does not establish that its amount or
settlement is correct; the other accounting and validation rules still apply.

For example, assuming zero contribution from TopTx's own activity:

| SubTx declarations | Required TopTx declaration |
| --- | --- |
| One `SubTxNoDepositStoreChange` | `SJust NoDepositStoreChange` |
| A local deposit of 3 ADA and a local withdrawal of 3 ADA | `SJust NoDepositStoreChange` |
| One deposit of 3 ADA, local or requested from TopTx | `SJust (DepositToStore 3)` |

These amounts are in ADA for readability. `SNothing` fails in each example,
including when all operations are handled locally and their contributions
cancel. If no SubTx declares an operation, this rule imposes no presence
requirement; DS-TX-001 still applies to TopTx's own spent and created outputs.

## Validation of delegated SubTx contributions

**Rule identifier:** `DS-TX-010`

**Decision:** Agreed

**Enforcement:** Pending

Validate delegation through the originating SubTx's exact backing accounting
and the completed batch's financial accounting:

1. The SubTx's declared contribution must equal its own backing change under
   DS-TX-003, regardless of delegation.
2. A delegated contribution is accounted for by TopTx exactly once. It is
   excluded from `subTxLocalNetDeposits` and included in `topTxNetDeposit` under
   DS-TX-002 and DS-TX-006.
3. TopTx must declare the entire batch's exact net change, including every
   SubTx contribution, under DS-TX-002, DS-TX-003 and DS-TX-009.
4. The complete batch must fund that net change and balance under DS-TX-004.
   Withdrawal settlement must also satisfy DS-TX-006 and DS-TX-007.

For example, a SubTx requesting a deposit of 3 ADA, with no other Store
activity in the batch, requires `DepositToStore 3` in TopTx. Reject
`DepositToStore 2`, even if the Store already has surplus funds. A correct
declaration also fails if the batch does not provide the required funds.

An opposing valid contribution may offset a delegated request in the batch
net change; this does not cancel its originating body's exact accounting
obligation. Each contribution must be included once, with the correct sign.

This validation adds neither an independent financial-balance requirement for
SubTx nor an additional declaration field. Local and delegated contributions
remain subject to the same exact backing rule; delegation determines their
accounting location within the batch.

## Withdrawal authority follows the backed output

**Rule identifier:** `DS-TX-011`

**Decision:** Agreed

**Enforcement:** Existing spending authorization applies; Store integration pending

On the ordinary successful spending path, the authority to release an output's
assigned backing follows that output's spending conditions. Satisfy its existing
key or script authorization; no separate DepositStore withdrawal credential or
witness is required. Funding the original deposit gives the funder no retained
refund claim or additional approval right.

Released backing participates in exact accounting under DS-TX-003. A body whose
released backing exceeds its created backing has a withdrawal contribution.
SubTx declares its own contribution; TopTx declares the net change for the
complete batch. Batch netting and settlement still follow DS-TX-002, DS-TX-006
and DS-TX-007; release does not imply an extra gross Store withdrawal.

For example, Alice funds 2 ADA of backing for a store-backed output controlled
by Bob. If Bob validly spends it without creating replacement store-backed
outputs, its body must account for a 2 ADA withdrawal contribution. Alice's
approval is not required, and the settlement destination need not be Alice.

A SubTx authorizes delegated withdrawal through its explicit `DelegateToTopTx`
target. TopTx handles settlement under the existing netting rules; the SubTx
does not select a final TopTx output index. Ordinary spending authorization
cannot be replaced by a declaration or by referencing an output. Collateral
consumption follows its separate authorization and settlement rules under
DS-COLL-001 through DS-COLL-004.

## Zero application ADA and empty application assets

**Rule identifier:** `DS-TX-012`

**Decision:** Agreed

**Verification:** Store-backed outputs bypass implicit minimum-coin checks;
backing enforcement and property tests pending

A store-backed output may contain zero application ADA, including any of these
cases:

- Native assets with no ADA.
- No application assets, with a datum or reference script.
- No application assets, datum or reference script, retaining its address.

Each output still requires the full assigned backing calculated under
DS-STORE-003. Empty application assets do not make an output free to store:
its address, encoding and fixed overhead still enter the size-based formula.
Creating it remains subject to the explicit declaration and exact accounting
requirements of DS-TX-001 and DS-TX-003.

This permission does not relax other output validation, including nonnegative
asset amounts, size limits or address validity. Implicit-deposit outputs retain
their existing minimum-coin requirements. A store-backed collateral return may
also have zero application value, provided the collateral funding and settlement
rules hold; the externally held backing does not count as its application coins.

## Both output variants supported for collateral

**Rule identifier:** `DS-COLL-001`

**Decision:** Both variants must be supported

**Enforcement:** Pending

Collateral inputs and collateral return must support both
`ImplicitDepositTxOut` and `StoreBackedTxOut`, subject to the applicable
collateral validation rules. Restricting collateral to implicit-deposit outputs
is not the intended first-version behavior.

Preserve the existing collateral validation trigger: require collateral and
run `validateBatchCollateral` when TopTx or any SubTx contains redeemers. The
backing funding, minimum collateral fee and supplied `totalCollateral` checks
use this same scope. Store-backed outputs or DepositStore declarations alone
do not introduce a collateral requirement. Existing checks on supplied inputs
and outputs that run independently of this trigger continue to apply.

On the phase-2 failure path, the effects applied to the UTxO are collateral
consumption and collateral return, rather than ordinary spending and output
creation. Store-backed collateral consumption can release backing; a
store-backed collateral return requires backing. Their accounting must preserve
ADA and DepositStore solvency using the effects actually applied.

The ordinary DepositStore declaration and its regular-output withdrawal targets
cannot simply be applied unchanged on this path. DS-COLL-002 specifies the
funding and destination of the collateral backing adjustment. Whether that
adjustment increases or decreases the store is derived under DS-COLL-004;
there is no separate collateral DepositStore declaration.

## Collateral backing surplus and shortfall

**Rule identifier:** `DS-COLL-002`

**Decision:** Agreed for a fixed pricing policy

**Enforcement:** Pending

On an accepted phase-2 failure, use the backing released by consumed store-backed
collateral to cover the backing required by the collateral return. Transfer all
excess released backing to the fee pot. Fund any shortfall from the collateral
inputs' coins, while still covering the required collateral fee.

Define:

- `releasedBacking`: the backing assigned to the consumed store-backed
  collateral inputs. Implicit-deposit inputs contribute zero to this amount.
- `requiredBacking`: the backing required by a store-backed collateral return
  under the fixed policy. An absent or implicit-deposit return contributes zero.
- `collateralInputCoins`: the sum of the collateral inputs' output coins.
- `collateralReturnCoins`: the return output's coins, or zero when absent.

Output coins include the whole ADA value of an implicit-deposit output and the
application ADA of a store-backed output. Any implicit minimum is already part
of those coins; do not also count it as backing released from the DepositStore.
A fixed pricing policy does not imply equal input and return backing: their
chargeable sizes or other priced characteristics may differ.

```text
additionalDeposit = max 0 (requiredBacking - releasedBacking)
releasedBackingFee = max 0 (releasedBacking - requiredBacking)

collateralCoinFee = collateralInputCoins - collateralReturnCoins - additionalDeposit
collateralFee = collateralCoinFee + releasedBackingFee
minimumCollateralFee = ceil(txFee * collateralPercentage / 100)

collateralCoinFee >= minimumCollateralFee
```

Collateral coins must cover the minimum fee after funding the return and any
additional deposit. All excess released backing is added to the fee pot on top
of that independently funded minimum; it cannot satisfy or reduce the minimum
collateral requirement. Released backing surplus cannot instead finance a
larger return.

The following conservation equation must hold:

```text
collateralInputCoins + releasedBacking
    = collateralReturnCoins + requiredBacking + collateralFee
```

On settlement, the DepositStore balance and its backing obligation both change
by `requiredBacking - releasedBacking`, and the fee pot receives `collateralFee`.
This collateral settlement does not credit the treasury directly. It preserves
the existing solvency margin and total ADA. Only the excess backing released by
these collateral inputs is transferred; an unrelated surplus already in the
store is untouched.

These transfers are separate from the successful execution path. Ordinary
DepositStore declarations and ordinary output creation are not applied on this
failure path. Conversely, collateral settlement is not applied on success.

For example, using ADA units and a minimum collateral fee of 1 ADA:

| Input coins | Return coins | Released backing | Required backing | Additional deposit | Released backing fee | Collateral fee | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 5 | 3 | 2 | 1 | 0 | 1 | 3 | Funded |
| 5 | 3 | 1 | 2 | 1 | 0 | 1 | Funded |
| 5 | 4 | 1 | 2 | 1 | 0 | 0 | Reject |
| 5 | 5 | 2 | 1 | 0 | 1 | 1 | Reject: collateral coin fee below minimum |

The transaction must already specify enough collateral coins to fund its return
and any additional backing, with the remaining coins covering the minimum
collateral fee. Excess released backing is added to the fee pot. The ledger
cannot reduce the signed return amount or select extra inputs to repair a shortfall;
such a transaction fails collateral validation. A funded case still has to
satisfy the other collateral rules, including native-asset conservation and
the implicit minimum when the return uses that variant.

DS-COLL-003 specifies the meaning and validation of `totalCollateral` with this
backing adjustment. DS-COLL-004 requires the adjustment to be derived without
a separate declaration. Parameter changes remain deferred under DS-STORE-002.

## Total collateral declaration

**Rule identifier:** `DS-COLL-003`

**Decision:** Agreed

**Enforcement:** Pending

When supplied, `dtbrTotalCollateral` declares the coins taken from the collateral
outputs after subtracting the specified collateral return. It includes any
additional deposit funded from those coins and excludes backing released from
the DepositStore.

Enforce the following equality within the collateral validation scope defined
in DS-COLL-001:

```text
computedTotalCollateral = collateralInputCoins - collateralReturnCoins

dtbrTotalCollateral = SJust amount
    => amount = computedTotalCollateral

collateralCoinFee = computedTotalCollateral - additionalDeposit
collateralFee = collateralCoinFee + releasedBackingFee

collateralCoinFee >= minimumCollateralFee
```

Reject a supplied amount that differs from the computed total. If the optional
field is absent, derive the total from the collateral inputs and return; absence
does not bypass backing funding or the minimum collateral fee check. Other
collateral validation requirements continue to apply.

For example, 5 ADA of input coins and a 2 ADA return require a supplied
`totalCollateral` of 3 ADA. If the backing shortfall is 1 ADA, 2 ADA remains
for the collateral coin fee. Excess released backing, when present instead,
is added separately to the fee credit under DS-COLL-002.

This rule retains the existing optional field and its input-minus-return
relationship. The collateral DepositStore adjustment is derived under
DS-COLL-004.

## Derived collateral DepositStore settlement

**Rule identifier:** `DS-COLL-004`

**Decision:** Agreed

**Enforcement:** Pending

The ledger derives the collateral DepositStore change from the resolved
collateral inputs and the specified collateral return, using the backing
amounts defined in DS-COLL-002:

```text
collateralStoreChange = requiredBacking - releasedBacking
```

A positive result increases the store balance; a negative result decreases it.
No separate collateral DepositStore operation field is required. The existing
optional `dtbrTotalCollateral` retains its meaning under DS-COLL-003.

On successful execution, apply the ordinary DepositStore operations; collateral
inputs remain unspent and the collateral return is not created. On an accepted
phase-2 failure, apply only the derived collateral settlement under DS-COLL-002;
ordinary TopTx and SubTx DepositStore operations have no effect on that path.
Reject collateral that cannot fund the derived settlement and required fee,
without changing ledger state.

## DepositStore solvency

**Rule identifier:** `DS-STORE-001`

**Decision:** Agreed

**Enforcement:** Pending

Every accepted ledger state must have enough ADA in the DepositStore to cover
its outstanding obligations.

For a ledger state `state`, define:

- `storeBalance(state)`: the actual ADA held in the DepositStore.
- `requiredBacking(state)`: the total backing obligation for the live
  store-backed outputs, under the agreed pricing and release policy.
  Implicit-deposit outputs do not impose obligations on this store.

The invariant is:

```text
storeBalance(state) >= requiredBacking(state) >= 0
```

Both quantities are denominated in ADA. `requiredBacking` is an obligation,
not another balance to add to the ledger's total ADA. DS-STORE-003 defines the
backing assigned under the fixed policy; DS-STORE-002 covers the deferred
historical information needed when parameters change.

For a transition from `before` to `after`:

```text
storeBalance(after)
    = storeBalance(before) + depositsApplied - withdrawalsApplied

storeBalance(before) + depositsApplied - withdrawalsApplied
    >= requiredBacking(after)
```

`depositsApplied` and `withdrawalsApplied` are nonnegative amounts actually
settled by that transition, each counted once. A request for TopTx funding does
not increase the balance until the funding is settled. The full amount of an
actual transfer is counted; DS-TX-003 requires the declared net transfer to match
the exact change in backing obligations.
Under DS-TX-002, SubTx accounting amounts are contributions within the TopTx
net change, not additional transfers to add to it. When the batch's declared
operations settle successfully:

```text
depositsApplied - withdrawalsApplied = txTotalNetDeposit

txTotalNetDeposit = requiredBacking(after) - requiredBacking(before)
```

For a successful batch under the fixed policy, store balance and required
backing therefore change by the same amount. This preserves any existing
solvency margin; it does not replace the global solvency inequality with an
assumption that every initial or migrated state has zero margin.

For a transaction batch, the resulting state includes both TopTx and SubTx
effects. The batch must not be accepted with insufficient backing. This invariant
does not require each SubTx to balance financially on its own. Any temporary
accounting used while processing SubTx before TopTx must not be exposed as an
accepted ledger state or treated as proof that a SubTx is independently valid.

The invariant also applies to accepted states after initialization, era
translation, epoch and parameter changes, and collateral processing. On script
failure, the check must use the effects actually applied; declared operations
that were not applied cannot contribute funding. Both collateral output variants
must be supported under DS-COLL-001, with the fixed-policy settlement described
by DS-COLL-002.

For example, starting with a store balance of 10 ADA:

| Deposits applied | Withdrawals applied | Backing required after | Balance after | Result for DS-STORE-001 |
| --- | --- | --- | --- | --- |
| 0 | 1 | 9 | 9 | Pass |
| 0 | 2 | 9 | 8 | Reject |
| 0 | 2 | 6 | 8 | Pass |
| 3 | 0 | 12 | 13 | Pass |

These results establish solvency only. A passing resulting state does not show
that a transaction satisfies DS-TX-003: reject any deposit or withdrawal that
does not match the exact change from its prior backing obligations. These
examples do not authorize withdrawing unrelated surplus or validate a target.

## Historical pricing for output backing

**Rule identifier:** `DS-STORE-002`

**Decision:** Historical pricing must be recoverable; handling parameter changes is deferred

**Implementation:** Pending

The current increment assumes that `coinsPerUTxOByte` does not change. It does
not yet handle pricing changes over time. This restriction does not remove the
future requirement to account correctly for outputs created under different
parameter values.

For each live store-backed output, the ledger must eventually be able to recover
the pricing basis used when its backing was established, including the applicable
`coinsPerUTxOByte` value and any relevant pricing formula or chargeable-size
definition. The current protocol parameters alone cannot recover
that historical basis after the price changes. Do not silently recompute an
old output's historically assigned backing using the latest price.

For illustration, DS-STORE-003 charges 260 bytes for an output whose serialized
size is 100 bytes, including the fixed 160-byte overhead. At a hypothetical
price of 4 lovelace per byte, its assigned backing is 1040 lovelace. A later
price of 6 would give 1560 lovelace for that same size; it does not establish
that 1560 lovelace was originally assigned to the output.

Live UTxO entries retain the assigned backing amount under DS-STORE-005. The
representation of any additional historical pricing information remains
undecided: it could retain the applicable parameter directly or a pricing
reference with enough history to recover it. Its retention policy remains to be
designed; this requirement does not mandate adding a field to the serialized
transaction `TxOut`. Era translation must preserve the pricing basis of any
existing store-backed outputs. The
Conway-to-Dijkstra transition introduces no such outputs under DS-STORE-004.

DS-TX-003 requires exact backing accounting and rejects voluntary excess
deposits, so these operations create no separate overpayment refund claims.
Whether an explicit repricing transition is permitted remains a separate
decision. The solvency rule must eventually cover parameter changes under that
policy; constant-price tests alone will not establish this.

## Backing calculated from output size

**Rule identifier:** `DS-STORE-003`

**Decision:** Agreed for a fixed pricing policy

**Enforcement:** Pending

Retain the existing byte-based minimum-UTxO formula for the backing assigned to
each newly created store-backed output:

```text
requiredBacking(output)
    = coinsPerUTxOByte * (160 + serializedSize(output))
```

`serializedSize(output)` uses the existing CBOR-sized-output convention. It
includes the address, application assets, datum, reference script and their
encoding overhead, as present in the output. The fixed 160-byte overhead is
retained. The DepositStore balance and the body's DepositStore declaration are
outside the output and do not add bytes to its serialized size.

For a finalized output and fixed parameters, the backing amount is determined.
Assigning that backing in the external store does not change the output's
serialized size, so it does not require adding a deposit field and recalculating
that field's encoding contribution. Transaction construction can still change
the output itself: changing application ADA, assets, address, datum or script
requires using the size of the resulting output. This rule does not assert
that overall transaction balancing requires no iteration.

Use this formula for both regular store-backed outputs and a store-backed
collateral return. Sum the assigned amounts of a body's own new store-backed
outputs to obtain `createdBacking(body)`. Spending a store-backed output releases
its assigned backing; recover that stored amount from the resolved live UTxO
entry under DS-STORE-005.

The charged size is the size measured when accepting the output. CBOR encoding
is not canonical, so reserializing a decoded output later need not reproduce
that size. Recover the assigned backing from retained information, such as its
amount or original charged size, even while the price remains constant.

Implicit-deposit outputs retain their existing minimum-coin validation and
contribute no backing obligation to the DepositStore. Parameter changes remain
deferred under DS-STORE-002; DS-STORE-004 defines Conway-to-Dijkstra initialization.

## DepositStore initialization at the Conway transition

**Rule identifier:** `DS-STORE-004`

**Decision:** Agreed

**Implementation:** Implicit output translation exists; DepositStore state initialization pending

When transitioning from Conway to Dijkstra, retain every existing UTxO as an
implicit-deposit output with its full ADA and native-asset value. Do not
automatically convert outputs into store-backed outputs or extract their
implicit minimum into the DepositStore.

Initialize the new DepositStore with:

```text
storeBalance = 0
requiredBacking = 0
```

Existing ledger pots are not used to fund the new Store during this transition.
Subsequent transactions introduce store-backed outputs and fund their backing
under DS-TX-003 and DS-TX-004. Spending an existing implicit-deposit output
releases no Store backing; its coins can fund the deposit required by newly
created store-backed outputs through normal transaction accounting. Collateral
return creation follows DS-COLL-002 through DS-COLL-004 on the failure path.

## Consistency of UTxO backing records

**Rule identifier:** `DS-STORE-005`

**Decision:** Agreed

**Enforcement:** Pending

Every live store-backed UTxO must have exactly one recoverable assigned backing
amount associated with its `TxIn`. The logical set of Store backing records
must match the live store-backed outputs:

```text
keys(backingRecords(state))
    = { txIn | output(UTxO(state)[txIn]) is StoreBackedTxOut }

requiredBacking(state) = sum(assignedBacking(record) for record in backingRecords(state))
```

Creating a store-backed output establishes its backing record using
DS-STORE-003. Consuming that output releases the assigned amount exactly once
and removes the record. Reference inputs leave the record unchanged and release
no backing. Implicit-deposit outputs have no Store backing obligation.

UTxO changes, backing records and the Store balance must settle atomically.
On success, update the records for the ordinary effects actually applied.
On an accepted phase-2 failure, update only those for the collateral effects.
Rejecting a transaction leaves all three unchanged. No accepted state may have
a missing record, an orphan record or a backing amount released twice.

Store the assigned backing alongside the output in its live UTxO entry, keyed
by `TxIn`. An implicit entry has no Store backing; a store-backed entry retains
exactly one assigned amount. The conceptual representation is:

```haskell
data UTxOEntry era
  = ImplicitDepositEntry !(ImplicitDepositTxOut era)
  | StoreBackedEntry !(StoreBackedTxOut era) !Coin
    -- Coin is the assigned backing.

newtype UTxO era =
  UTxO { unUTxO :: Map TxIn (UTxOEntry era) }
```

Calculate the amount from the accepted sized output before its charged size is
discarded. Keep it in ledger-state serialization and snapshots so restoring or
rolling back state preserves the assigned amount. This is ledger-state metadata;
transaction output contents and the `TxIn` reference need no additional field.

The global Store balance holds the actual ADA. Entry amounts record its backing
obligations and must not be counted again as monetary balances or stake.
Recording the assigned amount supports exact release accounting; the additional
historical-pricing work under DS-STORE-002 remains deferred. The precise API and
state encoding for each era remain implementation work.

## Plutus compatibility

**Rule identifier:** `DS-PLUTUS-001`

**Decision:** Target compatibility with all supported Plutus versions

**Implementation:** Deferred

The intended design supports store-backed outputs with Plutus V1, V2, V3 and
V4, subject to each version's existing feature restrictions. Store backing
alone should not impose a V4-only restriction.

The context translation and any exposure of DepositStore information remain
to be designed and tested. The current legacy translation paths contain
`unexpected StoreBackedTxOut` errors that must be addressed in that work.
No context-value projection or translation change is selected here.

## Stake and voting power

**Rule identifier:** `DS-STAKE-001`

**Decision:** Exclude DepositStore backing for the current prototype

**Verification:** Pending

ADA held in the DepositStore contributes neither stake nor voting power. Do not
attribute an output's assigned backing to its staking credential or count the
Store balance separately in stake or voting distributions.

Before applying the existing staking eligibility and delegation rules, the
output's ADA contribution is:

```text
stakeContribution(ImplicitDepositTxOut output) = full ADA in output
stakeContribution(StoreBackedTxOut output) = application ADA in output
```

An implicit output containing 10 ADA therefore contributes 10 ADA where eligible.
A store-backed output containing 8 ADA with 2 ADA of assigned backing contributes
only 8 ADA. Existing registration, delegation and snapshot timing still apply.

Deposits and withdrawals affect stake through the actual resulting outputs and
the existing stake update rules; they do not create a separate Store attribution.
Excluding backing from stake and voting power does not exclude it from ledger
balances or ADA conservation. The Store remains an ADA pot under DS-STORE-001.

## Remaining design work

DS-TX-001 requires an explicit declaration; DS-TX-002 assigns the batch net change
to TopTx and accounts for each contribution once; DS-TX-003 requires exact
accounting for each body's backing obligations; DS-TX-004 requires TopTx batch financial
balance; DS-TX-005 requires withdrawal accounting when leaving store-backed
outputs; DS-TX-006 derives TopTx's settlement amount and allows mixed withdrawal
settlement; DS-TX-007 requires valid destinations containing their allocated
shares; DS-TX-008 makes zero SubTx contributions explicit and other operation
amounts strictly positive; DS-TX-009 requires a TopTx declaration whenever any
SubTx declares an operation; DS-TX-010 validates delegated contributions through
exact body accounting and batch funding; DS-TX-011 ties backing release authority
to the output's spending conditions, with no retained funder claim;
DS-TX-012 permits zero application ADA and empty application assets in
store-backed outputs while retaining their full backing requirement;
DS-COLL-001 supports both collateral output variants and preserves the existing
validation trigger; DS-COLL-002 sends excess released collateral backing to the fee pot
and funds a backing shortfall from collateral coins; DS-COLL-003 preserves the
input-minus-return meaning of the optional total collateral declaration;
DS-COLL-004 derives the collateral Store change without a separate declaration;
DS-STORE-001 requires a solvent resulting ledger state; DS-STORE-002
records the deferred historical-pricing requirement; DS-STORE-003 assigns
backing using the existing output-size formula; DS-STORE-004 retains Conway
outputs as implicit and starts the new Store empty; DS-STORE-005 keeps UTxO
entries, their stored backing amounts and Store balance consistent;
DS-STAKE-001 excludes Store backing from stake and voting power for the current
prototype. The following design work remains:

- The concrete APIs and ledger-state encoding for the chosen live UTxO entries
  and the global DepositStore balance, including migration and state restoration.
- Plutus context compatibility across all supported versions, including the
  representation of store-backed outputs. This work is deferred under
  DS-PLUTUS-001.
- Historical pricing metadata, its retention and migration, and the accounting
  policy when `coinsPerUTxOByte` changes. These are deferred beyond the current
  constant-price scope.

The implication in DS-TX-001 is deliberately one-way: declaring an operation
does not require creating or spending a store-backed output, and its presence
alone does not prove sufficient funding or permission to withdraw.

## Property based verification

**Status:** Planned. These properties are acceptance requirements for the future
ledger implementation; they have not been implemented or run yet.

Use generated transaction bodies, batches and sequences of ledger transitions
to test the rules, alongside the concrete acceptance cases above.

| Rule or invariant | Property to verify |
| --- | --- |
| DS-TX-001 | Every accepted body creating or spending store-backed outputs has its own declaration. Removing that declaration from an otherwise valid case causes rejection; a parent or child declaration cannot substitute for it. Referencing an output alone does not trigger the spending condition. |
| DS-TX-002 | Signed body contributions reconcile with the declared TopTx net change, including mixed deposits and withdrawals. Switching a SubTx deposit between local and delegated accounting in an otherwise valid adjusted batch moves the accounting amount between bodies without changing the net store change. |
| DS-TX-003 | Require each body's released backing plus its signed contribution to equal its created backing. Reject over-deposits, under-deposits, over-withdrawals and under-withdrawals, including a one-lovelace error and opposing errors that cancel in the batch total. Delegation preserves the originating body's exact contribution; TopTx's own contribution excludes all SubTx contributions. The declared batch net change equals the sum of actual backing changes. |
| DS-TX-004 | Every accepted TopTx batch balances consumed and produced values with the net DepositStore term counted once. Generate imbalanced SubTx whose combined batch balances, and reject a final batch imbalance of one lovelace or any native asset. |
| DS-TX-005 | A body spending store-backed outputs and creating none declares a withdrawal contribution equal to its released backing. Reject absent declarations and zero or incorrect own contributions; preserve the withdrawal contribution when another body's deposit offsets the batch net change. |
| DS-TX-006 | Derive topTxNetDeposit from txTotalNetDeposit minus signed local SubTx contributions; delegated operations remain TopTx's responsibility. For net withdrawals, require NoTopTxWithdrawal exactly when topTxNetWithdrawal is zero, and a TopTx destination otherwise. Generate SubTx-only, TopTx-only and mixed settlement, including local deposits that make topTxNetWithdrawal exceed txTotalNetWithdrawal and local withdrawals offset by TopTx deposits. Count the net store withdrawal once. |
| DS-TX-007 | Reject an index outside its owning body's outputs or an output containing less than its allocated share. Accept exact coverage and additional funds when other rules hold. In a mixed settlement, check TopTx's share rather than the entire batch withdrawal, and never credit the selected output twice. |
| DS-TX-008 | Explicit SubTx zero contributes no funds or delegation and remains distinct from absence. Reject zero, negative and out-of-range amounts for every nonzero operation through checked construction and both decoders. An explicit zero cannot bypass a required positive deposit or withdrawal. |
| DS-TX-009 | Any declared SubTx operation requires a TopTx declaration, including explicit zero and cancelling local contributions. Removing only TopTx's declaration from an otherwise valid such batch causes rejection; switching between local and delegated SubTx accounting does not remove this requirement. |
| DS-TX-010 | Require delegated contributions to match the originating body's exact backing change, be accounted for by TopTx once, reconcile with the batch declaration, and be funded by a balanced batch. Reject omitted, duplicated or incorrectly signed contributions and unfunded declarations. Accept valid offsetting contributions and financially imbalanced SubTx when the complete batch satisfies all rules. |
| DS-TX-011 | Exercise outputs funded by someone other than their authorized spender. On the successful ordinary spending path, require the existing key or script authorization and exact backing accounting, without a separate funder approval or Store witness. Reject unauthorized spending even with a correct withdrawal declaration. Cover local and explicitly delegated SubTx settlement; references alone release no backing. |
| DS-TX-012 | Generate store-backed outputs with zero ADA and native assets, empty application assets with a datum or reference script, and an address with no application assets, datum or script. Accept otherwise valid cases with exact backing and reject absent declarations or incorrect backing contributions. Include collateral returns under their separate settlement rules. Preserve all other output validation and implicit minimum-coin checks. |
| DS-COLL-001 | Preserve the existing collateral trigger for redeemers in TopTx, a SubTx, or both. Store-backed outputs and Store declarations alone do not require collateral. Support both collateral output variants and preserve the existing independent checks on supplied inputs and outputs. |
| DS-COLL-002 | On an accepted phase-2 failure, all excess released backing goes to the fee pot and any shortfall is funded from collateral coins. Check the minimum fee using collateral coins after funding the return and additional backing; surplus is added on top. Reject a collateral coin fee below the minimum even when backing surplus makes the total fee credit sufficient. Independently verify ADA conservation, no direct treasury credit, and that store balance and required backing change by the same amount. Cover equal backing, surplus, shortfall, multiple inputs, absent returns, both output variants, and a one-lovelace funding deficit. Ordinary Store operations have no effect on this path; collateral settlement has no effect on success. |
| DS-COLL-003 | When collateral validation is active under DS-COLL-001, require every supplied total collateral amount to equal input coins minus return coins, regardless of backing surplus or shortfall. Reject a mismatch of one lovelace. Derive backing funding and fee credit separately, and retain those checks when the optional declaration is absent. Include cases where the declared total differs from the fee credit because coins fund additional backing or released backing increases fees. |
| DS-COLL-004 | Derive collateral Store changes from the resolved collateral inputs and return without a separate declaration. Holding collateral inputs, return, fee and policy fixed, ordinary DepositStore declarations cannot alter failure-path settlement. Verify that success applies ordinary Store operations only, accepted phase-2 failure applies collateral settlement only, and rejection applies neither. |
| DS-STORE-001 | Starting from a valid state, every accepted transition leaves the actual store balance at least equal to independently calculated outstanding backing obligations. |
| DS-STORE-002 (deferred) | After a price change, recover each live output's original pricing basis independently of the current parameters. Generate increases, decreases, and outputs from multiple pricing periods; verify release accounting and solvency under the eventual parameter-change policy. |
| DS-STORE-003 | Independently calculate each new store-backed output's backing as `coinsPerUTxOByte * (160 + serializedSize(output))`. Check regular outputs and collateral returns, optional datum and script fields, native assets, and CBOR amount-size boundaries. Assigning backing outside a fixed output must not change its output size; changing output contents requires a fresh size calculation. Spending releases the assigned amount, including when reserialization would change the size. Implicit outputs contribute zero Store backing. |
| DS-STORE-004 | Translate arbitrary valid Conway UTxOs with references and values preserved and every output remaining implicit. The new Store balance and backing obligation are both zero, with no funding transfer from other pots. Spending a translated implicit output releases no Store backing; later creation of store-backed outputs must fund their exact backing. |
| DS-STORE-005 | After every accepted transition, require every live store-backed UTxO entry to retain its assigned amount and those amounts to sum to requiredBacking. Implicit entries have no Store backing. Exercise creation, consumption, reference-only use, successful execution and accepted phase-2 failure. Detect missing and orphan records, wrong assigned amounts and double releases. Preserve assigned amounts through ledger-state serialization, restoration and rollback. Rejected transitions must leave UTxO, records and Store balance unchanged. |
| DS-PLUTUS-001 (deferred) | Verify store-backed output context translation for every supported Plutus version under its existing feature restrictions, once the projection semantics are defined. |
| DS-STAKE-001 | Verify that implicit outputs contribute their full ADA and store-backed outputs only their application ADA under the existing eligibility, delegation and snapshot rules. Assigned backing and the Store balance contribute no additional stake or voting weight. Exercise deposits, withdrawals and the actually applied collateral effects, while retaining Store ADA in monetary conservation checks. |
| Store accounting | After an accepted transition, the balance changes by exactly the applied deposits minus the applied withdrawals. Delegated settlement is counted once. |
| ADA conservation | Moving ADA between outputs and the store preserves total ADA across all ledger pots; required backing is never counted as a second balance. |
| Rejected transitions | Rejecting a batch leaves the previously accepted ledger state unchanged. An accepted transaction with failed phase-2 scripts is a separate case: verify the actual collateral effects under the agreed policy. |

Expected balances, backing obligations and settlement amounts must come from a
small reference model implementing the agreed rules independently of the ledger
validation helpers. Recalculate backing from the model UTxO and any retained
claims under the chosen pricing policy, rather than trusting a cached ledger
obligation. Determine expected store flows from the operations and settlement
rules, rather than inferring them from the implementation's resulting balance.

Generators must exercise both output variants, mixtures of them, TopTx and SubTx
declarations, explicit delegation, mixed deposits and withdrawals with either
sign of net change, and batches containing financially imbalanced
SubTx whose combined accounting is valid. Do not silently require every SubTx
to balance individually.

Include exact backing changes, declarations one lovelace above and below the
required amount, pre-existing store surplus, collateral backing surplus, zero
amounts where permitted, and both ends of the supported amount and output-index
ranges. Opposite declaration errors in different bodies must remain invalid
even when they cancel in the batch total.
Include exact cancellation with `SJust NoDepositStoreChange` and explicit SubTx
zero with `SJust SubTxNoDepositStoreChange`; distinguish both from absent fields.
Verify positive TopTx and SubTx operation
amounts at both supported bounds and rejection of zero, negative and overflow
amounts through checked construction and both wire decoders.
Generate successful lifecycle sequences as well as invalid cases. Enforce
coverage of accepted cases so an implementation that rejects everything cannot
satisfy the suite merely by having no accepted insolvent states.

As the corresponding policies are agreed, extend the model and generators to
cover parameter changes, era translation,
epoch transitions and collateral. Shrinking must retain the dependencies and
preconditions of the case under test, including any intended invalid condition.
Report the random seed and minimized counterexample for reproducible failures.

## Code references

- [Transaction fields, operations and lenses](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxBody.hs)
- [Output variants and shared interfaces](../libs/cardano-ledger-core/src/Cardano/Ledger/Core.hs)
- [Dijkstra output representations](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxOut.hs)
- [Existing byte-based minimum-UTxO formula](../eras/babbage/impl/src/Cardano/Ledger/Babbage/TxOut.hs)
- [Serialized size measurement](../libs/cardano-ledger-binary/src/Cardano/Ledger/Binary/Decoding/Sized.hs)
- [TopTx UTXO rule](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Utxo.hs)
- [SubTx UTXO rule](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/SubUtxo.hs)
