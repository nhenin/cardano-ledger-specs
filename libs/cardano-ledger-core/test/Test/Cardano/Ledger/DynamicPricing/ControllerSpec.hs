{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Test.Cardano.Ledger.DynamicPricing.ControllerSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.DynamicPricing.Controller
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion (..))
import Cardano.Ledger.DynamicPricing.Pricing (
  InclusionPrice (..),
  mkInclusionPrices,
  optimistic,
  urgent,
 )
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
        caps = InclusionCapacities (BlockCapacity 1000) (BlockCapacity 1000)
        prices = reprice defaultControllerParams (InclusionPrice (Coin 44)) caps ps
    -- Urgent lane full (1000/1000) ⇒ ×1.0625 ⇒ 704→748. The optimistic lane is
    -- empty, so its price holds at the floor: an urgent flood no longer drags the
    -- optimistic price up (lane-only signal, not the aggregate).
    urgent prices `shouldBe` InclusionPrice (Coin 748)
    optimistic prices `shouldBe` InclusionPrice (Coin 44)

  it "reprice: an Optimistic-saturated block ratchets the optimistic lane up (it is dynamic)" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = recordTx Optimistic 1000 (Coin 0) mempty ps0
        caps = InclusionCapacities (BlockCapacity 1000) (BlockCapacity 1000)
        prices = reprice defaultControllerParams (InclusionPrice (Coin 44)) caps ps
    -- Optimistic lane full (1000/1000) ⇒ ×1.0625 ⇒ 44→46.75, which rounds
    -- to 47: the optimistic price is genuinely dynamic. It would be
    -- pinned at the floor if measured against a 2× RB endorser-block denominator
    -- it can never fill in Praos-only.
    optimistic prices `shouldBe` InclusionPrice (Coin 47)

  it "reprice: a certification round (optimistic bytes only) HOLDS the urgent price" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = recordTx Optimistic 1000 (Coin 0) mempty ps0
        caps = InclusionCapacities (BlockCapacity 1000) (BlockCapacity 1000)
        prices = reprice defaultControllerParams (InclusionPrice (Coin 44)) caps ps
    -- A certified endorser block is applied on its own: the round carries optimistic
    -- bytes and no urgent ones. Stepping the urgent lane here would read "my lane ran
    -- empty" and cut it a full step between two full ranking blocks — the sawtooth
    -- measured live under saturation. It must hold at its genesis rate instead.
    urgent prices `shouldBe` InclusionPrice (Coin (16 * 44))

  it "reprice: the discrimination floor lifts urgent when the optimistic lane climbs under it" $
    -- Urgent opens exactly on the floor (132 = 3 × 44) and holds, since the round
    -- carries no urgent bytes. The optimistic lane is full, so it steps 44 ⇒ ×1.0625
    -- ⇒ 47, and 3 × 47 = 141 now sits ABOVE the held urgent price. Publishing the
    -- pair as stepped would make the fast lane the cheap one; worse, `unsafePrices`
    -- calls `error` on such a pair, so a node would later crash decoding its own state.
    case mkInclusionPrices (InclusionPrice (Coin 132)) (InclusionPrice (Coin 44)) of
      Nothing -> expectationFailure "132 = 3 × 44 sits on the floor and must be publishable"
      Just startPrices -> do
        let ps0 = DynamicPricing startPrices emptyBlockUsage emptyPendingRefunds :: DynamicPricing ()
            ps = recordTx Optimistic 1000 (Coin 0) mempty ps0
            caps = InclusionCapacities (BlockCapacity 1000) (BlockCapacity 1000)
            prices = reprice defaultControllerParams (InclusionPrice (Coin 44)) caps ps
        optimistic prices `shouldBe` InclusionPrice (Coin 47)
        urgent prices `shouldBe` InclusionPrice (Coin 141)

  it "endOfBlock resets the usage counters" $ do
    let ps0 = initialPricingState :: DynamicPricing ()
        ps = recordTx Urgent 1000 (Coin 0) mempty ps0
        caps = InclusionCapacities (BlockCapacity 1000) (BlockCapacity 1000)
        ps' = endOfBlock defaultControllerParams (InclusionPrice (Coin 44)) caps ps
    blockUsage ps' `shouldBe` mempty
