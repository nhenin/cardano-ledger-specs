<a id="ds-tx-declarations" name="ds-tx-declarations"></a>

<a id="211-declarations" name="211-declarations"></a>

# 2.1.1 TopTx and SubTx deposit declarations

This chapter of [Dijkstra ledger rules for minimum-ADA and deposit-backed outputs](README.md#ds-tx) defines the declaration forms and when each transaction body must use them.

> **Valid form → required field.**

| Responsibility | Question | Evidence needed |
| --- | --- | --- |
| [Grammar](#ds-tx-declarations-grammar) | Which declaration forms are valid? | The encoded declaration. |
| [Requirements](#ds-tx-declarations-requirements) | Which bodies must declare? | The body's Store operations and the SubTx declarations; resolved inputs for releases. |

**Absence is a valid representation.** A body that allocates or releases a deposit
must nevertheless declare. Grammar accepts the form; Requirements checks whether
it is allowed in that transaction. [Net change](README.md#ds-tx-accounting-net-change) then checks
the declared amount.

<a id="ds-tx-grammar" name="ds-tx-grammar"></a>
<a id="ds-tx-declarations-grammar" name="ds-tx-declarations-grammar"></a>

## 2.1.1.1 Grammar

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
[Net change](README.md#ds-tx-accounting-net-change) checks its amount.
[Settlement](README.md#ds-tx-settlement) checks participation, output existence and coverage.

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
field 28 are detailed in the [encoding reference](README.md#declaration-encoding).

<a id="ds-tx-grammar-n02" name="ds-tx-grammar-n02"></a>
<a id="ds-tx-declarations-grammar-n02" name="ds-tx-declarations-grammar-n02"></a>

The reusable `StrictlyPositiveCoin` type owns the positive-amount invariant;
[`StrictlyPositiveCoinSpec`](../../libs/cardano-ledger-core/test/Test/Cardano/Ledger/StrictlyPositiveCoinSpec.hs)
tests its constructor and scalar codecs. Grammar checks the type's use **inside
declarations**, including rejection of raw external values that bypass construction.

TopTx and SubTx follow the same reading order:
**Amounts → Absence → Forms → Structure → Destinations**.
Case numbers restart within each category; each tag links to its executable check.

<a id="ds-tx-grammar-toptx" name="ds-tx-grammar-toptx"></a>
<a id="ds-tx-declarations-grammar-toptx" name="ds-tx-declarations-grammar-toptx"></a>

### 2.1.1.1.1 TopTx

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
| <a id="ds-tx-grammar-p01" name="ds-tx-grammar-p01"></a><a id="ds-tx-declarations-grammar-p01" name="ds-tx-declarations-grammar-p01"></a>**1.&nbsp;[P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L36)** | **Positive amounts survive encoding.** A generated `StrictlyPositiveCoin` in every amount-bearing form. | Preserve the operation, amount and settlement through both codecs. |
| <a id="ds-tx-grammar-f01" name="ds-tx-grammar-f01"></a><a id="ds-tx-declarations-grammar-f01" name="ds-tx-declarations-grammar-f01"></a>**2.&nbsp;[F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L40)** | **Zero operation amount.** Raw $`\text{amount}=0`$. | Reject decoding. Explicit zero has its own form. |
| <a id="ds-tx-grammar-f12" name="ds-tx-grammar-f12"></a><a id="ds-tx-declarations-grammar-f12" name="ds-tx-declarations-grammar-f12"></a>**3.&nbsp;[F12](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L43)** | **Negative operation amount.** Raw $`\text{amount}=-1`$. | Reject decoding: below the lower bound. |
| <a id="ds-tx-grammar-f13" name="ds-tx-grammar-f13"></a><a id="ds-tx-declarations-grammar-f13" name="ds-tx-declarations-grammar-f13"></a>**4.&nbsp;[F13](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L46)** | **Overflowing operation amount.** Raw $`\text{amount}=2^{64}`$. | Reject decoding without truncation or wrapping. |

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
| <a id="ds-tx-grammar-n03" name="ds-tx-grammar-n03"></a><a id="ds-tx-declarations-grammar-n03" name="ds-tx-declarations-grammar-n03"></a>**1.&nbsp;[N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L51)** | **Absence remains distinct from zero.** Two otherwise identical complete bodies, differing only in their declaration. | Distinct encodings; decoding preserves each complete body. |

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
| <a id="ds-tx-grammar-n05" name="ds-tx-grammar-n05"></a><a id="ds-tx-declarations-grammar-n05" name="ds-tx-declarations-grammar-n05"></a>**1.&nbsp;[N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L58)** | **Every TopTx declaration form.** Explicit zero and all amount-bearing forms at both amount bounds. | Preserve each form, amount and settlement. |
| <a id="ds-tx-grammar-f06" name="ds-tx-grammar-f06"></a><a id="ds-tx-declarations-grammar-f06" name="ds-tx-declarations-grammar-f06"></a>**2.&nbsp;[F06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L62)** | **Funding request in TopTx.** A valid SubTx funding request is passed to the TopTx decoder. | SubTx preserves the request in both codecs; TopTx rejects its JSON representation. |

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
| <a id="ds-tx-grammar-f02" name="ds-tx-grammar-f02"></a><a id="ds-tx-declarations-grammar-f02" name="ds-tx-declarations-grammar-f02"></a>**1.&nbsp;[F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L68)** | **Malformed declarations.** Invalid containers, unknown operations, missing required fields or extra CBOR fields. | Reject each malformed input in its own format. |

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
| <a id="ds-tx-grammar-f04" name="ds-tx-grammar-f04"></a><a id="ds-tx-declarations-grammar-f04" name="ds-tx-declarations-grammar-f04"></a>**1.&nbsp;[F04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L73)** | **Malformed release settlements.** Wrong container, unknown form, missing local index or extra CBOR fields. | Reject decoding with otherwise valid indices. |
| <a id="ds-tx-grammar-f14" name="ds-tx-grammar-f14"></a><a id="ds-tx-declarations-grammar-f14" name="ds-tx-declarations-grammar-f14"></a>**2.&nbsp;[F14](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L76)** | **Negative output index.** Generated $`\text{outputIndex}\lt 0`$, favouring $`-1`$. | Reject the local settlement in both codecs. |
| <a id="ds-tx-grammar-f15" name="ds-tx-grammar-f15"></a><a id="ds-tx-declarations-grammar-f15" name="ds-tx-declarations-grammar-f15"></a>**3.&nbsp;[F15](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/TopTxSpec.hs#L80)** | **Overflowing output index.** Generated $`\text{outputIndex}\gt 65535`$, favouring $`65536`$. | Reject the settlement without truncation or wrapping. |

F04 covers six CBOR and five JSON structural defects per draw: invalid containers,
unknown forms, missing local indices and extra CBOR fields. Examples include CBOR
`[0,1]` (an index on the no-settlement form) and `[1]` (a local form without its
index). Any supplied local index remains within range.

F14 and F15 generate values throughout their respective invalid ranges, favouring
$`-1`$ and $`65536`$. Shrinking keeps a counterexample in the same invalid range.
[N05](#ds-tx-declarations-grammar-n05) supplies the valid $`0`$ and $`65535`$ controls.
[Settlement](README.md#ds-tx-settlement-output-index) separately checks that the index names
an existing output in TopTx.

<a id="ds-tx-grammar-subtx" name="ds-tx-grammar-subtx"></a>
<a id="ds-tx-declarations-grammar-subtx" name="ds-tx-declarations-grammar-subtx"></a>

### 2.1.1.1.2 SubTx

A SubTx can declare zero, allocate locally, request funding from TopTx, or release
to its own output or TopTx. Encoding preserves which choice it made.

<a id="ds-tx-grammar-subtx-amounts" name="ds-tx-grammar-subtx-amounts"></a>
<a id="ds-tx-declarations-grammar-subtx-amounts" name="ds-tx-declarations-grammar-subtx-amounts"></a>

**2.1.1.1.2.1 Amounts**

> **Allocation, funding requests and releases carry a strictly positive amount.**

| Case | Scenario | Expected result |
| :---: | --- | --- |
| <a id="ds-tx-grammar-p02" name="ds-tx-grammar-p02"></a><a id="ds-tx-declarations-grammar-p02" name="ds-tx-declarations-grammar-p02"></a>**1.&nbsp;[P02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L33)** | **Positive amounts survive encoding.** A generated `StrictlyPositiveCoin` in every amount-bearing form. | Preserve the operation, amount and target through both codecs. |
| <a id="ds-tx-grammar-f07" name="ds-tx-grammar-f07"></a><a id="ds-tx-declarations-grammar-f07" name="ds-tx-declarations-grammar-f07"></a>**2.&nbsp;[F07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L37)** | **Zero operation amount.** Raw $`\text{amount}=0`$. | Reject decoding. An amount-bearing operation cannot stand in for explicit zero. |
| <a id="ds-tx-grammar-f08" name="ds-tx-grammar-f08"></a><a id="ds-tx-declarations-grammar-f08" name="ds-tx-declarations-grammar-f08"></a>**3.&nbsp;[F08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L40)** | **Negative operation amount.** Raw $`\text{amount}=-1`$. | Reject decoding: the amount is below the lower bound. |
| <a id="ds-tx-grammar-f09" name="ds-tx-grammar-f09"></a><a id="ds-tx-declarations-grammar-f09" name="ds-tx-declarations-grammar-f09"></a>**4.&nbsp;[F09](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L43)** | **Overflowing operation amount.** Raw $`\text{amount}=2^{64}`$. | Reject decoding without truncation or wrapping. |

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
| <a id="ds-tx-grammar-n04" name="ds-tx-grammar-n04"></a><a id="ds-tx-declarations-grammar-n04" name="ds-tx-declarations-grammar-n04"></a>**1.&nbsp;[N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L48)** | **Absence remains distinct from zero.** The same complete body, differing only in its declaration. | Distinct CBOR and JSON representations; decoding preserves each complete body. |

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
| <a id="ds-tx-grammar-n06" name="ds-tx-grammar-n06"></a><a id="ds-tx-declarations-grammar-n06" name="ds-tx-declarations-grammar-n06"></a>**1.&nbsp;[N06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L55)** | **Every SubTx declaration form.** Explicit zero and every amount-bearing form at both amount bounds. | Preserve each form, amount and target through both codecs. |

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
| <a id="ds-tx-grammar-f03" name="ds-tx-grammar-f03"></a><a id="ds-tx-declarations-grammar-f03" name="ds-tx-declarations-grammar-f03"></a>**1.&nbsp;[F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L61)** | **Malformed declarations.** Invalid containers, unknown operations, missing required fields or extra CBOR fields. | Reject each malformed input in its own format. |

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
| <a id="ds-tx-grammar-f05" name="ds-tx-grammar-f05"></a><a id="ds-tx-declarations-grammar-f05" name="ds-tx-declarations-grammar-f05"></a>**1.&nbsp;[F05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L66)** | **Malformed release targets.** Wrong container, unknown target, missing local index or extra CBOR fields. | Reject decoding with otherwise valid indices. |
| <a id="ds-tx-grammar-f10" name="ds-tx-grammar-f10"></a><a id="ds-tx-declarations-grammar-f10" name="ds-tx-declarations-grammar-f10"></a>**2.&nbsp;[F10](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L69)** | **Negative output index.** Generated $`\text{outputIndex}\lt 0`$, favouring $`-1`$. | Reject a local target carrying that index in both codecs. |
| <a id="ds-tx-grammar-f11" name="ds-tx-grammar-f11"></a><a id="ds-tx-declarations-grammar-f11" name="ds-tx-declarations-grammar-f11"></a>**3.&nbsp;[F11](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Grammar/SubTxSpec.hs#L73)** | **Overflowing output index.** Generated $`\text{outputIndex}\gt 65535`$, favouring $`65536`$. | Reject the target without truncation or wrapping. |

F05 covers six CBOR and five JSON structural defects per draw: invalid containers,
unknown forms, missing local indices and extra CBOR fields. Examples include CBOR
`[1,0]` (an index attached to delegation) and `[0]` (a local target without its
index). Any supplied local index remains within range.

F10 and F11 generate values throughout their respective invalid ranges, favouring
$`-1`$ and $`65536`$. Shrinking keeps a counterexample in the same invalid range.
[N06](#ds-tx-declarations-grammar-n06) supplies the valid $`0`$ and $`65535`$ controls.
[Settlement](README.md#ds-tx-settlement-output-index) separately checks that the index names
an existing output in this SubTx.

<a id="ds-tx-presence" name="ds-tx-presence"></a>
<a id="ds-tx-required-declarations" name="ds-tx-required-declarations"></a>
<a id="ds-tx-declarations-requirements" name="ds-tx-declarations-requirements"></a>

## 2.1.1.2 Requirements

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
[Net change](README.md#ds-tx-accounting-net-change) checks the amount it declares.

Ordinary declaration, net change, output and settlement validation applies on both phase-2 outcomes. Required ordinary amounts describe the hypothetical ordinary transition from the original UTxO. Ordinary financial conservation is checked only when phase 2 is valid. An accepted phase-2 failure applies collateral effects only, while retaining the declaration, net change, output and settlement checks. Accepted ordinary release additionally requires its existing spending authorization. Ledger outcome and applied effects remain separate under State Execution.

<a id="ds-tx-presence-activity" name="ds-tx-presence-activity"></a>
<a id="ds-tx-presence-activity-scope" name="ds-tx-presence-activity-scope"></a>
<a id="ds-tx-presence-operations-scope" name="ds-tx-presence-operations-scope"></a>
<a id="ds-tx-presence-operations" name="ds-tx-presence-operations"></a>
<a id="ds-tx-required-declarations-operations" name="ds-tx-required-declarations-operations"></a>
<a id="ds-tx-declarations-requirements-operations" name="ds-tx-declarations-requirements-operations"></a>

### 2.1.1.2.1 Operations

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
[Net change](README.md#ds-tx-accounting-net-change) defines both contributions.

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
  [body-field reference](README.md#transaction-body-fields).
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

**2.1.1.2.1.1 [P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/OperationsSpec.hs#L44) - Every body requiring a Store operation declares**

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

**2.1.1.2.1.2.1 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L59) - Every explicit declaration satisfies allocation presence**

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

**2.1.1.2.1.2.2 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L76) - Absence satisfies allocation presence for empty or implicit-only own outputs**

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

**2.1.1.2.1.2.3 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L85) - Missing declaration fails allocation presence at every own-output position**

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

**2.1.1.2.1.2.4 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L95) - accepts a TopTx creating only min-ADA outputs without a declaration**

A TopTx creating only min-ADA outputs is accepted by the ledger without a Store declaration when its ordinary inputs, fees, and witnesses are valid. Its outputs impose no allocation-presence requirement.

<a id="ds-tx-presence-activity-creation-n04" name="ds-tx-presence-activity-creation-n04"></a>
<a id="ds-tx-presence-operations-allocation-n04" name="ds-tx-presence-operations-allocation-n04"></a>
<a id="ds-tx-required-declarations-operations-allocation-n04" name="ds-tx-required-declarations-operations-allocation-n04"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n04" name="ds-tx-declarations-requirements-operations-allocation-n04"></a>

**2.1.1.2.1.2.5 [N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L99) - accepts a SubTx creating only min-ADA outputs without either body's declaration**

A SubTx creating only min-ADA outputs is accepted within a ledger transaction when neither level declares a Store operation. Ordinary transaction preparation supplies valid funding and witnesses; no Store allocation is created.

<a id="ds-tx-presence-activity-creation-n05" name="ds-tx-presence-activity-creation-n05"></a>
<a id="ds-tx-presence-operations-allocation-n05" name="ds-tx-presence-operations-allocation-n05"></a>
<a id="ds-tx-required-declarations-operations-allocation-n05" name="ds-tx-required-declarations-operations-allocation-n05"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n05" name="ds-tx-declarations-requirements-operations-allocation-n05"></a>

**2.1.1.2.1.2.6 [N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L114) - Standalone TopTx, exact allocation declaration**

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

**2.1.1.2.1.2.7 [F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L130) - Standalone TopTx, allocation without a declaration**

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

**2.1.1.2.1.2.8 [F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L145) - rejects a SubTx creating a deposit-backed output without its own declaration**

The ledger rejects a SubTx that creates a deposit-backed own output without a SubTx declaration. The expected failure is SubMissingUTxODepositDeclaration, and rejection leaves ledger state unchanged. Declaration presence is required independently for the creating body.

<a id="ds-tx-presence-activity-creation-f04" name="ds-tx-presence-activity-creation-f04"></a>
<a id="ds-tx-presence-operations-allocation-f04" name="ds-tx-presence-operations-allocation-f04"></a>
<a id="ds-tx-required-declarations-operations-allocation-f04" name="ds-tx-required-declarations-operations-allocation-f04"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f04" name="ds-tx-declarations-requirements-operations-allocation-f04"></a>

**2.1.1.2.1.2.9 [F04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L149) - rejects a TopTx creating a deposit-backed output without its own declaration even when phase 2 fails**

A real failing phase-2 script does not waive TopTx's structural declaration requirement. Even with the transaction marked phase-2 invalid, creating a deposit-backed own output without a declaration yields MissingUTxODepositDeclaration and leaves the ledger unchanged.

<a id="ds-tx-presence-activity-creation-f05" name="ds-tx-presence-activity-creation-f05"></a>
<a id="ds-tx-presence-operations-allocation-f05" name="ds-tx-presence-operations-allocation-f05"></a>
<a id="ds-tx-required-declarations-operations-allocation-f05" name="ds-tx-required-declarations-operations-allocation-f05"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f05" name="ds-tx-declarations-requirements-operations-allocation-f05"></a>

**2.1.1.2.1.2.10 [F05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L153) - rejects a SubTx creating a deposit-backed output without its own declaration even when phase 2 fails**

A real phase-2 failure does not waive a creating SubTx's declaration requirement. The ledger still returns SubMissingUTxODepositDeclaration for the undeclared deposit-backed own output; the rejected transaction applies no state changes.

<a id="ds-tx-presence-activity-creation-f06" name="ds-tx-presence-activity-creation-f06"></a>
<a id="ds-tx-presence-operations-allocation-f06" name="ds-tx-presence-operations-allocation-f06"></a>
<a id="ds-tx-required-declarations-operations-allocation-f06" name="ds-tx-required-declarations-operations-allocation-f06"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f06" name="ds-tx-declarations-requirements-operations-allocation-f06"></a>

**2.1.1.2.1.2.11 [F06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L161) - rejects a missing own declaration when spending a translated min-ADA output to create deposit-backed outputs**

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

**2.1.1.2.1.2.12 [N06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L178) - SubTx outputs do not trigger TopTx allocation presence**

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

**2.1.1.2.1.2.13 [N07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L188) - Collateral return does not trigger allocation presence**

TopTx has a deposit-backed collateral return, no regular outputs and no declaration.
The isolated allocation-presence validator succeeds because collateral return is outside
$`\text{createdDepositBackedOutputs(topTx)}`$. Its independent collateral funding and
validity requirements still apply.

<a id="ds-tx-presence-activity-scope-n03" name="ds-tx-presence-activity-scope-n03"></a>
<a id="ds-tx-presence-operations-scope-n03" name="ds-tx-presence-operations-scope-n03"></a>
<a id="ds-tx-presence-operations-allocation-n08" name="ds-tx-presence-operations-allocation-n08"></a>
<a id="ds-tx-required-declarations-operations-allocation-n08" name="ds-tx-required-declarations-operations-allocation-n08"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-n08" name="ds-tx-declarations-requirements-operations-allocation-n08"></a>

**2.1.1.2.1.2.14 [N08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L194) - Reference and collateral input identifiers do not trigger allocation presence**

Place the same arbitrary input identifier in both reference and collateral input
sets, with no regular outputs or declaration. The isolated allocation-presence validator
succeeds: neither field is a created output. The fixture does **not resolve the
identifier** or prove that it names a deposit-backed output or valid collateral.

<a id="ds-tx-presence-activity-scope-f01" name="ds-tx-presence-activity-scope-f01"></a>
<a id="ds-tx-presence-operations-scope-f01" name="ds-tx-presence-operations-scope-f01"></a>
<a id="ds-tx-presence-operations-allocation-f07" name="ds-tx-presence-operations-allocation-f07"></a>
<a id="ds-tx-required-declarations-operations-allocation-f07" name="ds-tx-required-declarations-operations-allocation-f07"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f07" name="ds-tx-declarations-requirements-operations-allocation-f07"></a>

**2.1.1.2.1.2.15 [F07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L200) - A SubTx declaration cannot satisfy TopTx allocation presence**

TopTx creates deposit-backed own outputs but declares nothing. Its nested SubTx
also creates deposit-backed outputs and explicitly declares zero. The child's
declaration cannot supply TopTx's field: the isolated TopTx allocation-presence validator
returns `MissingBodyUTxODepositDeclaration`.

<a id="ds-tx-presence-activity-scope-f02" name="ds-tx-presence-activity-scope-f02"></a>
<a id="ds-tx-presence-operations-scope-f02" name="ds-tx-presence-operations-scope-f02"></a>
<a id="ds-tx-presence-operations-allocation-f08" name="ds-tx-presence-operations-allocation-f08"></a>
<a id="ds-tx-required-declarations-operations-allocation-f08" name="ds-tx-required-declarations-operations-allocation-f08"></a>
<a id="ds-tx-declarations-requirements-operations-allocation-f08" name="ds-tx-declarations-requirements-operations-allocation-f08"></a>

**2.1.1.2.1.2.16 [F08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L212) - TopTx zero cannot satisfy its allocating SubTx's declaration requirement**

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

**2.1.1.2.1.2.17 [N09](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/AllocationSpec.hs#L223) - TopTx and SubTx allocate deposits, each with an exact declaration**

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
its parent's required field. [Ledger effects](README.md#ds-state) specifies the resulting
state transitions: [Execution](README.md#ds-state-execution),
[Allocations](README.md#ds-state-allocations) and [Balance](README.md#ds-state-balance).

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

**2.1.1.2.1.3.1 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L61) - Standalone TopTx, any output form**

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

New allocations use the [deposit calculation](README.md#ds-pricing) with fixed protocol
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

**2.1.1.2.1.3.2 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L84) - Standalone TopTx, only min-ADA outputs**

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

**2.1.1.2.1.3.3 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L98) - One SubTx releases its deposit into its own output**

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

**2.1.1.2.1.3.4 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L110) - Standalone TopTx, release without its own declaration**

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

**2.1.1.2.1.3.5 [F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L126) - SubTx release without its own declaration, despite TopTx declaring**

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

**2.1.1.2.1.3.6 [N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L139) - Phase 2 fails with valid declarations**

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
transition belongs to [Execution](README.md#ds-state-execution).

<a id="ds-tx-presence-activity-spending-f03" name="ds-tx-presence-activity-spending-f03"></a>
<a id="ds-tx-presence-operations-release-f03" name="ds-tx-presence-operations-release-f03"></a>
<a id="ds-tx-required-declarations-operations-release-f03" name="ds-tx-required-declarations-operations-release-f03"></a>
<a id="ds-tx-declarations-requirements-operations-release-f03" name="ds-tx-declarations-requirements-operations-release-f03"></a>

**2.1.1.2.1.3.7 [F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L154) - Missing release declaration in a phase-2-invalid proposal**

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

**2.1.1.2.1.3.8 [N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L180) - Several SubTxs release their deposits**

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

**2.1.1.2.1.3.9 [F04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L198) - One SubTx releasing deposits omits its declaration**

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

**2.1.1.2.1.3.10 [N06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L222) - Only some SubTxs release Store deposits**

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

**2.1.1.2.1.3.11 [N07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L243) - TopTx and several SubTxs release deposits**

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

**2.1.1.2.1.3.12 [N08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L261) - Phase 2 fails with several proposed SubTx releases**

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
[Execution](README.md#ds-state-execution).

<a id="ds-tx-presence-activity-spending-f05" name="ds-tx-presence-activity-spending-f05"></a>
<a id="ds-tx-presence-operations-release-f05" name="ds-tx-presence-operations-release-f05"></a>
<a id="ds-tx-required-declarations-operations-release-f05" name="ds-tx-required-declarations-operations-release-f05"></a>
<a id="ds-tx-declarations-requirements-operations-release-f05" name="ds-tx-declarations-requirements-operations-release-f05"></a>

**2.1.1.2.1.3.13 [F05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L279) - One SubTx declaration is missing in a phase-2-invalid proposal**

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

**2.1.1.2.1.3.14 [N09](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L303) - Standalone TopTx, reference-only Store access**

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

**2.1.1.2.1.3.15 [N10](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L312) - Standalone TopTx, collateral-only Store operations**

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

**2.1.1.2.1.3.16 [F06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ReleaseSpec.hs#L321) - A SubTx declaration cannot satisfy TopTx release presence**

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

**2.1.1.2.1.4.1 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L42) - Standalone TopTx, equal allocations and releases with explicit zero**

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

**2.1.1.2.1.4.2 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L53) - Standalone TopTx, equal allocations and releases without a declaration**

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
[TopTx accounting](README.md#ds-tx-accounting-net-change-toptx) checks the arithmetic of the total declaration.

<a id="ds-tx-required-declarations-operations-zero-net-change-n02" name="ds-tx-required-declarations-operations-zero-net-change-n02"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-n02" name="ds-tx-declarations-requirements-operations-zero-net-change-n02"></a>

**2.1.1.2.1.4.3 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L72) - One SubTx replaces its deposit with explicit zero**

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

**2.1.1.2.1.4.4 [F02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L83) - One active SubTx omits its declaration**

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

**2.1.1.2.1.4.5 [F03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L98) - TopTx omits the declaration required by its child**

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

**2.1.1.2.1.4.6 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L112) - Several SubTxs each replace their deposits**

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

**2.1.1.2.1.4.7 [F04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L123) - One of several active SubTxs omits its declaration**

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

**2.1.1.2.1.4.8 [N04](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L138) - Only some SubTxs replace Store deposits**

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

**2.1.1.2.1.4.9 [F05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L153) - One active SubTx omits its declaration among inactive siblings**

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

**2.1.1.2.1.4.10 [N05](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L172) - TopTx and several SubTxs each replace their deposits**

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

**2.1.1.2.1.4.11 [F06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L183) - Active TopTx omits its own declaration**

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

**2.1.1.2.1.4.12 [N06](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L198) - Phase 2 fails with explicit zero at every active body**

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
Store effects belong to [Execution](README.md#ds-state-execution).

<a id="ds-tx-required-declarations-operations-zero-net-change-f07" name="ds-tx-required-declarations-operations-zero-net-change-f07"></a>
<a id="ds-tx-declarations-requirements-operations-zero-net-change-f07" name="ds-tx-declarations-requirements-operations-zero-net-change-f07"></a>

**2.1.1.2.1.4.13 [F07](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L210) - One SubTx declaration is missing in a phase-2-invalid proposal**

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

**2.1.1.2.1.4.14 [F08](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/Operations/ZeroNetChangeSpec.hs#L226) - TopTx's own declaration is missing in a phase-2-invalid proposal**

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

### 2.1.1.2.2 SubTx declarations

> **A SubTx declaration requires a TopTx declaration.**
>
> Any explicit SubTx form, including zero, requires TopTx's field even without
> TopTx's own Store operations. The amount is checked separately.

**Decision:** Agreed.

**Executable spec:** [SubTxDeclarationsSpec.hs](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs)

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

**2.1.1.2.2.1.1 [P01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L61) - SubTx declarations require TopTx's declaration**

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

**2.1.1.2.2.2.1 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L66) - accepts absent declarations at both levels**

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

**2.1.1.2.2.2.2 [N02](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L70) - accepts explicit zero at both levels**

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

**2.1.1.2.2.2.3 [N03](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L74) - accepts TopTx zero without a SubTx declaration**

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

**2.1.1.2.2.2.4 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L78) - rejects SubTx zero without a TopTx declaration**

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

**2.1.1.2.2.3.1 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L86) - passes declaration presence with TopTx declaring the zero net amount**

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

**2.1.1.2.2.3.2 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L89) - rejects an absent TopTx declaration despite the zero net amount**

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

**2.1.1.2.2.4.1 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L94) - passes declaration presence with TopTx zero for every explicit SubTx form**

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

**2.1.1.2.2.4.2 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L100) - rejects an absent TopTx declaration for every explicit SubTx form**

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

**2.1.1.2.2.5.1 [N01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L109) - accepts zero declarations at both levels on the phase-2 failure path**

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

**2.1.1.2.2.5.2 [F01](../../eras/dijkstra/impl/test/Test/Cardano/Ledger/Dijkstra/Imp/DepositStore/TransactionRules/Tx/Declarations/Requirements/SubTxDeclarationsSpec.hs#L113) - rejects SubTx zero without a TopTx declaration on the phase-2 failure path**

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
