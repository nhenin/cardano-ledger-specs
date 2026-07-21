{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.Cardano.Ledger.DynamicPricing.ControllerSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Plutus.ExUnits (ExUnits (..))
import Cardano.Ledger.DynamicPricing.Controller
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion (..), InclusionDelivery (..))
import Cardano.Ledger.DynamicPricing.Pricing (
  InclusionPrice (..),
  InclusionPrices (..),
 )
import Cardano.Ledger.DynamicPricing.Signal (emptyPricingSignals)
import Cardano.Ledger.DynamicPricing.State (
  BlockCapacity (..),
  DynamicPricing (..),
  InclusionCapacities (..),
  defaultControllerParams,
  emptyBlockUsage,
  emptyPendingRefunds,
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

-- Byte-sized test capacities; roomy ex-units caps so byte ratios dominate.
testCaps :: InclusionCapacities
testCaps =
  InclusionCapacities
    (BlockCapacity 1000)
    (BlockCapacity 1000)
    (ExUnits 1_000_000 1_000_000)
    (ExUnits 1_000_000 1_000_000)

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

  it "shipped calibration (target 1/2, D 16): a full block raises the price 6.25%" $
    -- 320 × 17/16 = 340 exactly — no half-to-even rounding in the headline case.
    stepPrice (params 16 (1 % 2)) noFloor (Utilisation 1) (InclusionPrice (Coin 320))
      `shouldBe` InclusionPrice (Coin 340)

  it "shipped calibration: an empty block cuts the price 6.25% but the floor holds" $
    stepPrice (params 16 (1 % 2)) (InclusionPrice (Coin 44)) (Utilisation 0) (InclusionPrice (Coin 44))
      `shouldBe` InclusionPrice (Coin 44)

  it "reprice: an Urgent-saturated block ratchets only the urgent lane (optimistic holds)" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = recordTx Urgent 1000 (Coin 0) mempty ps0
        (prices, _) = reprice defaultControllerParams (InclusionPrice (Coin 44)) testCaps ps
    -- Urgent lane full (1000/1000) ⇒ ×1.0625 ⇒ 88→93.5, which rounds
    -- half-to-even to 94. The optimistic lane's sample is zero, so its price
    -- steps down and the floor holds: an urgent flood no longer drags the
    -- optimistic price up (lane-only signal, not the aggregate).
    urgent prices `shouldBe` InclusionPrice (Coin 94)
    optimistic prices `shouldBe` InclusionPrice (Coin 44)

  it "reprice: a certified Optimistic-saturated block ratchets the optimistic lane up" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = (recordTx Optimistic 1000 (Coin 0) mempty ps0) {blockDelivery = Certified}
        (prices, _) = reprice defaultControllerParams (InclusionPrice (Coin 44)) testCaps ps
    -- Optimistic lane full (1000/1000) ⇒ ×1.0625 ⇒ 44→46.75, which rounds
    -- to 47: the optimistic price is genuinely dynamic. It would be
    -- pinned at the floor if measured against a 2× RB endorser-block denominator
    -- it can never fill in Praos-only.
    optimistic prices `shouldBe` InclusionPrice (Coin 47)

  it "reprice: a certification round reads the reservation as idle — urgent steps down" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = (recordTx Optimistic 1000 (Coin 0) mempty ps0) {blockDelivery = Certified}
        (prices, _) = reprice defaultControllerParams (InclusionPrice (Coin 44)) testCaps ps
    -- A certified endorser block carries an urgent sample too: its urgent
    -- traffic against the RESERVATION capacity (the CIP's rule). Disjoint
    -- lanes make that sample zero, so from a fresh window the urgent price
    -- steps down: 88 × 15/16 = 82.5, banker's-rounded to 82. Under real
    -- load the five-sample window dilutes this (see the next case) — the
    -- window is the CIP's answer to the certification sawtooth, not a hold.
    urgent prices `shouldBe` InclusionPrice (Coin 82)

  it "reprice: the five-sample window dilutes a certification round between full blocks" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        floorPrice = InclusionPrice (Coin 44)
        -- a full ranking block first...
        rbRound = recordTx Urgent 1000 (Coin 0) mempty ps0
        afterRb = endOfBlock defaultControllerParams floorPrice testCaps rbRound
        -- ...then a certification round: the urgent window now reads
        -- (1000 + 0) / (1000 + 1000) = the half-full target, so the urgent
        -- price HOLDS at 94 instead of taking a full step down.
        certRound = (recordTx Optimistic 1000 (Coin 0) mempty afterRb) {blockDelivery = Certified}
        (prices, _) = reprice defaultControllerParams floorPrice testCaps certRound
    urgent prices `shouldBe` InclusionPrice (Coin 94)

  it "reprice: a temporary quote crossing is published as stepped (no cross-lane floor)" $ do
    -- Urgent sits at the lane floor (44): its zero sample steps it down and
    -- the floor holds it. The optimistic lane is full, so it steps 44 ⇒
    -- ×1.0625 ⇒ 47 and CROSSES the urgent price. The CIP's recommended
    -- construction permits this state: the controllers are independent,
    -- nothing lifts or clamps either lane.
    let startPrices = InclusionPrices (InclusionPrice (Coin 44)) (InclusionPrice (Coin 44))
        ps0 =
          DynamicPricing startPrices emptyBlockUsage emptyPendingRefunds emptyPricingSignals Certified ::
            DynamicPricing ()
        ps = recordTx Optimistic 1000 (Coin 0) mempty ps0
        (prices, _) = reprice defaultControllerParams (InclusionPrice (Coin 44)) testCaps ps
    optimistic prices `shouldBe` InclusionPrice (Coin 47)
    urgent prices `shouldBe` InclusionPrice (Coin 44)

  it "endOfBlock resets the usage counters" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = recordTx Urgent 1000 (Coin 0) mempty ps0
        ps' = endOfBlock defaultControllerParams (InclusionPrice (Coin 44)) testCaps ps
    blockUsage ps' `shouldBe` mempty
