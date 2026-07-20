{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.Cardano.Ledger.DynamicPricing.PricingSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion (..))
import Cardano.Ledger.DynamicPricing.Pricing (
  InclusionPrice (..),
  InclusionPrices (..),
  priceOf,
 )
import Test.Cardano.Ledger.Common

-- Rates are exact lovelace per byte; no floating point.
genPrice :: Gen InclusionPrice
genPrice = InclusionPrice . Coin <$> choose (0, 1_000_000_000)

spec :: Spec
spec = describe "DynamicPricing.Pricing" $ do
  describe "InclusionPrices" $
    it "publishes any pair — the lanes are independent, crossings permitted" $
      -- No cross-lane floor (the CIP's recommended construction): a fast
      -- lane cheaper than the patient one is a permitted controller state,
      -- not an invariant violation.
      urgent (InclusionPrices (InclusionPrice (Coin 100)) (InclusionPrice (Coin 60)))
        `shouldBe` InclusionPrice (Coin 100)

  describe "priceOf" $
    prop "reads back the rate published for each inclusion strategy" $
      forAll genPrice $ \fast ->
        forAll genPrice $ \patient ->
          let prices = InclusionPrices fast patient
           in priceOf Urgent prices === fast
                .&&. priceOf Optimistic prices === patient
                .&&. priceOf Urgent prices === urgent prices
                .&&. priceOf Optimistic prices === optimistic prices
