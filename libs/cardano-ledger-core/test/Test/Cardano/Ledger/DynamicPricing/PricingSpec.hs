{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.Cardano.Ledger.DynamicPricing.PricingSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion (..))
import Cardano.Ledger.DynamicPricing.Pricing (
  InclusionPrice (..),
  mkInclusionPrices,
  optimistic,
  priceDiscriminationFloor,
  priceOf,
  urgent,
 )
import Data.Maybe (isJust)
import Test.Cardano.Ledger.Common

-- Rates are exact lovelace per byte; no floating point.
genPrice :: Gen InclusionPrice
genPrice = InclusionPrice . Coin <$> choose (0, 1_000_000_000)

-- A pair the protocol is allowed to publish: urgent sits at or above the floor
-- multiple of optimistic.
genPublishablePair :: Gen (InclusionPrice, InclusionPrice)
genPublishablePair = do
  patient <- choose (0, 1_000_000)
  premium <- choose (0, 1_000_000)
  pure
    ( InclusionPrice (Coin (priceDiscriminationFloor * patient + premium))
    , InclusionPrice (Coin patient)
    )

spec :: Spec
spec = describe "DynamicPricing.Pricing" $ do
  describe "mkInclusionPrices" $ do
    prop "publishes exactly when urgent covers the floor multiple of optimistic" $
      forAll genPrice $ \fast@(InclusionPrice (Coin f)) ->
        forAll genPrice $ \patient@(InclusionPrice (Coin p)) ->
          isJust (mkInclusionPrices fast patient)
            === (f >= priceDiscriminationFloor * p)

    it "refuses a pair in which the fast lane is not dearer than the patient one" $
      -- 100 < 3 × 60. Publishing this would invert the premium the mechanism sells:
      -- urgency would cost less than patience.
      mkInclusionPrices (InclusionPrice (Coin 100)) (InclusionPrice (Coin 60))
        `shouldBe` Nothing

    it "publishes a pair sitting exactly on the floor" $
      -- The floor is inclusive: next to a 44 lovelace/byte patient rate, 132 = 3 × 44
      -- is the cheapest urgent rate the protocol may publish.
      (urgent <$> mkInclusionPrices (InclusionPrice (Coin 132)) (InclusionPrice (Coin 44)))
        `shouldBe` Just (InclusionPrice (Coin 132))

  describe "priceOf" $
    prop "reads back the rate published for each inclusion strategy" $
      forAll genPublishablePair $ \(fast, patient) ->
        case mkInclusionPrices fast patient of
          Nothing -> counterexample "the generator produced an unpublishable pair" False
          Just prices ->
            priceOf Urgent prices === fast
              .&&. priceOf Optimistic prices === patient
              .&&. priceOf Urgent prices === urgent prices
              .&&. priceOf Optimistic prices === optimistic prices
