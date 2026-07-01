{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.Cardano.Ledger.DynamicPricing.ControllerSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.DynamicPricing.Controller
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion (..))
import Cardano.Ledger.DynamicPricing.Pricing (InclusionPrice (..), optimistic, urgent)
import Cardano.Ledger.DynamicPricing.State (
  BlockCapacity (..),
  DynamicPricing (..),
  InclusionCapacities (..),
  defaultControllerParams,
  endOfBlock,
  initialPricingState,
  recordTx,
  reprice,
 )
import Data.Ratio ((%))
import Test.Cardano.Ledger.Common

-- A controller with the given max-change denominator and target.
params :: Int -> Rational -> ControllerParams
params d t = ControllerParams (TargetUtilisation t) (MaxChangeDenominator d)

noFloor :: InclusionPrice
noFloor = InclusionPrice (Coin 0)

-- Generators kept inline and exact (no floating point).
genD :: Gen Int
genD = choose (1, 16)

genTarget :: Gen Rational
genTarget = (% 100) <$> choose (1, 99)

genUtil :: Gen Rational
genUtil = (% 100) <$> choose (0, 200)

genPrice :: Gen InclusionPrice
genPrice = InclusionPrice . Coin <$> choose (0, 1_000_000_000)

spec :: Spec
spec = describe "DynamicPricing.Controller" $ do
  prop "at target, the price does not move" $
    forAll genD $ \d ->
      forAll genTarget $ \t ->
        forAll genPrice $ \price ->
          stepPrice (params d t) noFloor (Utilisation t) price === price

  prop "above target the price rises (or holds), below target it falls" $
    forAll genD $ \d ->
      forAll genTarget $ \t ->
        forAll genUtil $ \u ->
          forAll genPrice $ \price ->
            let moved = stepPrice (params d t) noFloor (Utilisation u) price
             in if u >= t
                  then moved >= price
                  else moved <= price

  prop "one step never moves the price by more than 1/D" $
    forAll genD $ \d ->
      forAll genTarget $ \t ->
        forAll genUtil $ \u ->
          forAll genPrice $ \price@(InclusionPrice (Coin p)) ->
            let InclusionPrice (Coin moved) = stepPrice (params d t) noFloor (Utilisation u) price
                up = round (fromInteger p * (1 + 1 % toInteger d)) :: Integer
                down = round (fromInteger p * (1 - 1 % toInteger d)) :: Integer
             in moved <= up && moved >= down

  prop "the result never drops below the floor" $
    forAll genD $ \d ->
      forAll genTarget $ \t ->
        forAll genUtil $ \u ->
          forAll genPrice $ \floorPrice ->
            forAll genPrice $ \price ->
              stepPrice (params d t) floorPrice (Utilisation u) price >= floorPrice

  it "winner calibration (target 1/2, D 4): a full block raises the price 25%" $
    stepPrice (params 4 (1 % 2)) noFloor (Utilisation 1) (InclusionPrice (Coin 100))
      `shouldBe` InclusionPrice (Coin 125)

  it "winner calibration: an empty block cuts the price 25% but the floor holds" $
    stepPrice (params 4 (1 % 2)) (InclusionPrice (Coin 44)) (Utilisation 0) (InclusionPrice (Coin 44))
      `shouldBe` InclusionPrice (Coin 44)

  it "reprice: an Urgent-saturated block ratchets only the urgent lane (optimistic holds)" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = recordTx Urgent 1000 (Coin 0) mempty ps0
        caps = InclusionCapacities (BlockCapacity 1000) (BlockCapacity 1000)
        prices = reprice defaultControllerParams (InclusionPrice (Coin 44)) caps ps
    -- Urgent lane full (1000/1000) ⇒ ×1.25 ⇒ 704→880. The optimistic lane is
    -- empty, so its price holds at the floor: an urgent flood no longer drags the
    -- optimistic price up (lane-only signal, not the aggregate).
    urgent prices `shouldBe` InclusionPrice (Coin 880)
    optimistic prices `shouldBe` InclusionPrice (Coin 44)

  it "reprice: an Optimistic-saturated block ratchets the optimistic lane up (it is dynamic)" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = recordTx Optimistic 1000 (Coin 0) mempty ps0
        caps = InclusionCapacities (BlockCapacity 1000) (BlockCapacity 1000)
        prices = reprice defaultControllerParams (InclusionPrice (Coin 44)) caps ps
    -- Optimistic lane full (1000/1000) ⇒ ×1.25 ⇒ 44→55: the optimistic price is
    -- genuinely dynamic. It would be pinned at the floor if measured against a
    -- 2× RB endorser-block denominator it can never fill in Praos-only.
    optimistic prices `shouldBe` InclusionPrice (Coin 55)

  it "endOfBlock resets the usage counters" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = recordTx Urgent 1000 (Coin 0) mempty ps0
        caps = InclusionCapacities (BlockCapacity 1000) (BlockCapacity 1000)
        ps' = endOfBlock defaultControllerParams (InclusionPrice (Coin 44)) caps ps
    blockUsage ps' `shouldBe` mempty
