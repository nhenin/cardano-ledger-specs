# Dijkstra DepositStore transaction rules

This document records the agreed transaction rules for the DepositStore prototype.
It is the reference for implementing ledger validation and writing acceptance tests.
Rules are added as their business meaning is agreed.

The rules below were agreed on 5 October 2026. The transaction interfaces and
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
return have a separate policy that remains to be specified.

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
  has made an explicit declaration and passes this presence check. Whether the
  TopTx fulfils the request requires a separate rule.
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
The declared net change must still be validated against the batch's operations,
backing obligations and funds.

Delegation changes where a SubTx contribution is accounted for:

- `SubTxNoDepositStoreChange`: explicitly declare zero contribution and no
  delegation request.
- `SubTxDepositToStore amount`: account for the deposit in the SubTx.
- `SubTxRequestDepositFromTopTx amount`: account for the deposit in the TopTx.
- `SubTxWithdrawFromStore amount (SubTxOutput index)`: account for the withdrawal
  in the SubTx and settle it in its named output.
- `SubTxWithdrawFromStore amount DelegateToTopTx`: account for the withdrawal
  in the TopTx; its destination must satisfy the eventual settlement rule.

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

## Backing coverage for each body

**Rule identifier:** `DS-TX-003`

**Decision:** Agreed

**Enforcement:** Pending

Each TopTx and SubTx body must cover its own backing obligations. Released
backing or excess contributions from another body cannot implicitly cover a
deficit. This coverage condition is separate from financial conservation:
SubTx may be financially imbalanced, but the completed TopTx batch must balance.

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
    >= createdBacking(body)
```

Equivalently, separating positive deposits and withdrawals:

```text
releasedBacking(body) + declaredDeposit(body)
    >= createdBacking(body) + declaredWithdrawal(body)
```

For SubTx, use the declared contribution regardless of accounting delegation:

| SubTx declaration | Contribution for that SubTx's coverage |
| --- | --- |
| `SubTxNoDepositStoreChange` | `0`; the coverage and withdrawal rules still apply |
| `SubTxDepositToStore amount` | `+amount` |
| `SubTxRequestDepositFromTopTx amount` | `+amount` |
| `SubTxWithdrawFromStore amount target` | `-amount`, for either target |
| `SNothing` | `0`; DS-TX-001 rejects absence if the body creates or spends any store-backed output |

For TopTx's own coverage, remove all SubTx contributions from the declared batch
net change, including contributions delegated to TopTx:

```text
declaredNetContribution(TopTx)
    = txTotalNetDeposit
        - sum(declaredNetContribution(subTx))
```

This is the contribution attributable to TopTx's own activity, not the financial
amount accounted for in TopTx, which also includes delegated contributions.
Each declared contribution is counted at its full amount. A deposit request
counts toward the originating SubTx's declared coverage, but acceptance also
requires its funding to be fulfilled in the batch accounting. Passing this
inequality alone does not establish funding or authorize a withdrawal.

For example, SubTx A releases no backing, creates outputs requiring 3 ADA and
declares a deposit of 5 ADA. SubTx B also releases none and creates outputs
requiring 3 ADA, but declares only 1 ADA. A passes this coverage check; B fails.
The batch must be rejected even though the combined deposit of 6 ADA covers
the combined requirement. B must explicitly declare a sufficient contribution,
locally or through a request to TopTx.

The calculation of backing amounts and the policy for excess backing remain
to be specified. The current scope assumes a constant `coinsPerUTxOByte`;
DS-STORE-002 records the deferred requirement to retain historical pricing.
Collateral effects remain a separate policy decision.

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
DS-TX-003 concerns ADA backing coverage for each body.

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

The released amount is calculated under the pricing and release policy still
to be specified. This rule does not grant access to unrelated store surplus.
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
does not replace financial conservation, backing coverage or withdrawal
authorization. `NoTopTxWithdrawal` has no TopTx index to validate; DS-TX-006
still requires no outstanding TopTx settlement share.

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
hold. This does not bypass DS-TX-003 coverage or DS-TX-005 withdrawal when
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

## DepositStore solvency

**Rule identifier:** `DS-STORE-001`

**Decision:** Agreed

**Enforcement:** Pending

Every accepted ledger state must have enough ADA in the DepositStore to cover
its outstanding obligations.

For a ledger state `state`, define:

- `storeBalance(state)`: the actual ADA held in the DepositStore.
- `requiredBacking(state)`: the total backing obligation for the live
  store-backed outputs, under the agreed pricing and release policy. If that
  policy retains additional refundable claims, those obligations must also be
  covered. Implicit-deposit outputs do not impose obligations on this store.

The invariant is:

```text
storeBalance(state) >= requiredBacking(state) >= 0
```

Both quantities are denominated in ADA. `requiredBacking` is an obligation,
not another balance to add to the ledger's total ADA. Its calculation and any
historical information needed to honour withdrawal rights remain to be specified.

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
actual transfer is counted, even if a smaller deposit would cover the shortfall.
Under DS-TX-002, SubTx accounting amounts are contributions within the TopTx
net change, not additional transfers to add to it. When the batch's declared
operations settle successfully:

```text
depositsApplied - withdrawalsApplied = txTotalNetDeposit
```

For a transaction batch, the resulting state includes both TopTx and SubTx
effects. The batch must not be accepted with insufficient backing. This invariant
does not require each SubTx to balance financially on its own. Any temporary
accounting used while processing SubTx before TopTx must not be exposed as an
accepted ledger state or treated as proof that a SubTx is independently valid.

The invariant also applies to accepted states after initialization, era
translation, epoch and parameter changes, and collateral processing. On script
failure, the check must use the effects actually applied; declared operations
that were not applied cannot contribute funding. The treatment of store-backed
collateral remains an open policy decision.

For example, starting with a store balance of 10 ADA:

| Deposits applied | Withdrawals applied | Backing required after | Balance after | Result for DS-STORE-001 |
| --- | --- | --- | --- | --- |
| 0 | 1 | 9 | 9 | Pass |
| 0 | 2 | 9 | 8 | Reject |
| 0 | 2 | 6 | 8 | Pass |
| 3 | 0 | 12 | 13 | Pass |

These results establish solvency only. They do not grant permission to withdraw
an available surplus or establish that a declared withdrawal target is valid.

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

For illustration, under a byte-based formula, 100 chargeable bytes priced at
4 lovelace per byte correspond to 400 lovelace of backing. A later price of
6 would produce 600 lovelace for the same chargeable size; it does not establish
that 600 lovelace was originally assigned to that output. These numbers do not
select the pricing formula or determine the refund entitlement.

The representation remains undecided: it could retain the applicable parameter
directly or retain a pricing reference with enough history to recover it. This
requirement does not mandate adding a field to the serialized `TxOut`; the ledger
metadata location and retention policy remain to be designed. Era translation
must also define the pricing basis assigned to migrated outputs.

Historical required backing is distinct from any excess deposit contributed to
the store. Surplus ownership, refund entitlement, and whether an explicit
repricing transition is permitted remain separate decisions. The solvency rule
must eventually cover parameter changes under that policy; constant-price tests
alone will not establish this.

## Decisions still required

DS-TX-001 requires an explicit declaration; DS-TX-002 assigns the batch net change
to TopTx and accounts for each contribution once; DS-TX-003 requires coverage
for each body's backing obligations; DS-TX-004 requires TopTx batch financial
balance; DS-TX-005 requires withdrawal accounting when leaving store-backed
outputs; DS-TX-006 derives TopTx's settlement amount and allows mixed withdrawal
settlement; DS-TX-007 requires valid destinations containing their allocated
shares; DS-TX-008 makes zero SubTx contributions explicit and other operation
amounts strictly positive; DS-TX-009 requires a TopTx declaration whenever any
SubTx declares an operation; DS-STORE-001 requires a solvent resulting ledger state; DS-STORE-002
records the deferred historical-pricing requirement. The following decisions
are still required:

- The required amount, capacity pricing, or permitted surplus.
- Withdrawal entitlement and the calculation of released backing.
- How to verify each delegation request is fulfilled.
- The treatment of store-backed collateral inputs and collateral return.
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
| DS-TX-003 | Every accepted body covers its own created backing with its released backing and declared contribution. Reject a body short by one lovelace even if another body has surplus backing. Delegation preserves the originating body's coverage contribution; TopTx's own contribution excludes all SubTx contributions. |
| DS-TX-004 | Every accepted TopTx batch balances consumed and produced values with the net DepositStore term counted once. Generate imbalanced SubTx whose combined batch balances, and reject a final batch imbalance of one lovelace or any native asset. |
| DS-TX-005 | A body spending store-backed outputs and creating none declares a withdrawal contribution equal to its released backing. Reject absent declarations and zero or incorrect own contributions; preserve the withdrawal contribution when another body's deposit offsets the batch net change. |
| DS-TX-006 | Derive topTxNetDeposit from txTotalNetDeposit minus signed local SubTx contributions; delegated operations remain TopTx's responsibility. For net withdrawals, require NoTopTxWithdrawal exactly when topTxNetWithdrawal is zero, and a TopTx destination otherwise. Generate SubTx-only, TopTx-only and mixed settlement, including local deposits that make topTxNetWithdrawal exceed txTotalNetWithdrawal and local withdrawals offset by TopTx deposits. Count the net store withdrawal once. |
| DS-TX-007 | Reject an index outside its owning body's outputs or an output containing less than its allocated share. Accept exact coverage and additional funds when other rules hold. In a mixed settlement, check TopTx's share rather than the entire batch withdrawal, and never credit the selected output twice. |
| DS-TX-008 | Explicit SubTx zero contributes no funds or delegation and remains distinct from absence. Reject zero, negative and out-of-range amounts for every nonzero operation through checked construction and both decoders. An explicit zero cannot bypass a required positive deposit or withdrawal. |
| DS-TX-009 | Any declared SubTx operation requires a TopTx declaration, including explicit zero and cancelling local contributions. Removing only TopTx's declaration from an otherwise valid such batch causes rejection; switching between local and delegated SubTx accounting does not remove this requirement. |
| DS-STORE-001 | Starting from a valid state, every accepted transition leaves the actual store balance at least equal to independently calculated outstanding backing obligations. |
| DS-STORE-002 (deferred) | After a price change, recover each live output's original pricing basis independently of the current parameters. Generate increases, decreases, and outputs from multiple pricing periods; verify release accounting and solvency under the eventual parameter-change policy. |
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

Include exact coverage, a deficit of one lovelace, surplus backing, zero amounts
where permitted, and both ends of the supported amount and output-index ranges.
Include exact cancellation with `SJust NoDepositStoreChange` and explicit SubTx
zero with `SJust SubTxNoDepositStoreChange`; distinguish both from absent fields.
Verify positive TopTx and SubTx operation
amounts at both supported bounds and rejection of zero, negative and overflow
amounts through checked construction and both wire decoders.
Generate successful lifecycle sequences as well as invalid cases. Enforce
coverage of accepted cases so an implementation that rejects everything cannot
satisfy the suite merely by having no accepted insolvent states.

As the corresponding policies are agreed, extend the model and generators to
cover withdrawal rights, target selection, parameter changes, era translation,
epoch transitions and collateral. Shrinking must retain the dependencies and
preconditions of the case under test, including any intended invalid condition.
Report the random seed and minimized counterexample for reproducible failures.

## Code references

- [Transaction fields, operations and lenses](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxBody.hs)
- [Output variants and shared interfaces](../libs/cardano-ledger-core/src/Cardano/Ledger/Core.hs)
- [Dijkstra output representations](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/TxOut.hs)
- [TopTx UTXO rule](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/Utxo.hs)
- [SubTx UTXO rule](../eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/SubUtxo.hs)
