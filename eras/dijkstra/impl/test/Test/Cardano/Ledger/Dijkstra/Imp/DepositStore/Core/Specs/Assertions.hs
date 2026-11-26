-- | Assertions shared across independent domain specifications.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Assertions (
  conformsTo,
  shouldAllBe,
  shouldAllSatisfy,
) where

import GHC.Stack (HasCallStack)
import Test.Cardano.Ledger.Common (Expectation, Property, forM_, shouldBe, shouldSatisfy, (===))

-- | Compare implementation and independent domain rule on the same fixture,
-- including the complete validation failure when rejected.
conformsTo ::
  (Eq result, Show result) => (input -> result) -> (input -> result) -> input -> Property
conformsTo implementation rule input = implementation input === rule input

-- | Compare every observed result with the expectation supplied by the spec.
shouldAllBe :: (HasCallStack, Eq value, Show value) => [value] -> value -> Expectation
shouldAllBe actual expected = forM_ actual (`shouldBe` expected)

-- | Check every observed result against the predicate supplied by the spec.
shouldAllSatisfy :: (HasCallStack, Show value) => [value] -> (value -> Bool) -> Expectation
shouldAllSatisfy actual predicate = forM_ actual (`shouldSatisfy` predicate)
