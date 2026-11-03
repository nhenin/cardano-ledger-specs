-- | Generated SubTx operation plans for accounting. Each unit becomes an
-- independently priced output or recorded input deposit in the funded fixture.
-- These plans contain no declarations; the specification supplies them.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.SubTx (
  anyOwnNetChange,
  declarationErrors,
  netAllocation,
  netRelease,
  releaseFromUnspentOutputs,
  twoAllocatingSubTxs,
  equalAllocationsAndReleases,
  onlyImplicitOutputs,
  releaseWithAnotherBodyAllocation,
  outputWithoutApplicationAssets,
  translatedImplicitInput,
) where

import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger, elements, oneof, vectorOf)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting (
  AccountingScenario (..),
  BodyOperations (..),
  bodyOperations,
  scenario,
 )

-- | One to four children independently allocate and release zero to four units.
-- TopTx has no own operations, so its declaration represents their exact total.
anyOwnNetChange :: Gen AccountingScenario
anyOwnNetChange = do
  childCount <- chooseInt (1, 4)
  children <- vectorOf childCount independentOperations
  scenario (bodyOperations 0 0) children

-- | Exact or one-lovelace-inexact declarations for each independently generated
-- child, with independent local/delegated forms. Offsets are independent, so
-- failures accumulate and may cancel in total.
declarationErrors :: Gen (AccountingScenario, [Integer], [Bool])
declarationErrors = do
  generated <- anyOwnNetChange
  errors <- vectorOf (length $ subOperations generated) $ elements [-1, 0, 1]
  delegated <- vectorOf (length $ subOperations generated) $ elements [False, True]
  pure (generated, errors, delegated)

-- | Generate both operation counts independently, including allocation only,
-- release only, mixed operations, positive zero-net operations and inactivity.
independentOperations :: Gen BodyOperations
independentOperations = bodyOperations <$> chooseInt (0, 4) <*> chooseInt (0, 4)

-- | One child requires a strictly positive net allocation. Some generated
-- children also release deposits; the generated difference is one to four units.
netAllocation :: Gen AccountingScenario
netAllocation = do
  releases <- chooseInt (0, 4)
  additionalAllocations <- chooseInt (1, 4)
  scenario (bodyOperations 0 0) [bodyOperations (releases + additionalAllocations) releases]

-- | One child requires a strictly negative net change, with a nonzero recorded
-- release. Some generated cases also allocate deposits in the same body.
netRelease :: Gen AccountingScenario
netRelease = do
  allocations <- chooseInt (0, 4)
  additionalReleases <- chooseInt (1, 4)
  scenario (bodyOperations 0 0) [bodyOperations allocations (allocations + additionalReleases)]

-- | One child has a negative or zero own net change. A separate funding plan
-- creates live deposits that its transaction will not consume. The claimed extra
-- release is positive and no greater than those unrelated recorded deposits.
releaseFromUnspentOutputs :: Gen (AccountingScenario, AccountingScenario, Integer)
releaseFromUnspentOutputs = do
  ownOperations <- oneof [netRelease, equalAllocationsAndReleases]
  unspentDepositCount <- chooseInt (1, 4)
  unrelatedFunding <- scenario (bodyOperations 0 unspentDepositCount) []
  unrelatedRelease <- chooseInteger (1, toInteger unspentDepositCount * 1000000)
  pure (ownOperations, unrelatedFunding, unrelatedRelease)

-- | Two distinct children both allocate. Their independently varied positive
-- changes remain positive after the specification adds opposite one-lovelace errors.
twoAllocatingSubTxs :: Gen AccountingScenario
twoAllocatingSubTxs = do
  first <- chooseInt (1, 4)
  second <- chooseInt (1, 4)
  scenario (bodyOperations 0 0) [bodyOperations first 0, bodyOperations second 0]

-- | One child has equal allocations and releases. Include no Store operations
-- as well as positive equal operations, so explicit zero is valid in both cases.
equalAllocationsAndReleases :: Gen AccountingScenario
equalAllocationsAndReleases = do
  units <- chooseInt (0, 4)
  scenario (bodyOperations 0 0) [bodyOperations units units]

-- | One child releases one to five recorded deposits and creates only implicit
-- outputs. No created output requires a new Store allocation.
onlyImplicitOutputs :: Gen AccountingScenario
onlyImplicitOutputs = do
  releases <- chooseInt (1, 5)
  scenario (bodyOperations 0 0) [bodyOperations 0 releases]

-- | A child releases while TopTx or a sibling allocates. Generate partial,
-- exactly equal and greater offsets; none changes the releasing child's own amount.
releaseWithAnotherBodyAllocation :: Gen AccountingScenario
releaseWithAnotherBodyAllocation = do
  releases <- chooseInt (2, 5)
  allocations <- elements [releases - 1, releases, releases + 1]
  parentAllocates <- elements [False, True]
  if parentAllocates
    then scenario (bodyOperations allocations 0) [bodyOperations 0 releases]
    else scenario (bodyOperations 0 0) [bodyOperations 0 releases, bodyOperations allocations 0]

-- | Exactly one created store-backed output has empty application assets.
-- Its address and encoded form still require a positive deposit.
outputWithoutApplicationAssets :: Gen AccountingScenario
outputWithoutApplicationAssets =
  scenario (bodyOperations 0 0) [(bodyOperations 1 0) {emptyApplicationAssets = True}]

-- | A single translated Conway implicit input funds one to five new Store
-- obligations. Translation is performed by the funding adapter, not simulated.
translatedImplicitInput :: Gen AccountingScenario
translatedImplicitInput = do
  allocations <- chooseInt (1, 5)
  scenario (bodyOperations 0 0) [(bodyOperations allocations 0) {sourceTranslation = True}]
