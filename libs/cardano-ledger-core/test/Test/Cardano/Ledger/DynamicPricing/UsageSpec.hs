{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.DynamicPricing.UsageSpec (spec) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.DynamicPricing.InclusionStrategy (Inclusion (..))
import Cardano.Ledger.DynamicPricing.Pricing (TxSizeInBytes (..))
import Cardano.Ledger.DynamicPricing.Refunds (
  PendingRefunds,
  drainRefunds,
  emptyPendingRefunds,
  pendingRefundsFromMap,
  recordPendingRefund,
 )
import Cardano.Ledger.DynamicPricing.Usage (
  BlockUsage,
  InclusionUsage (..),
  emptyBlockUsage,
  recordInclusionUsage,
  usageOf,
 )
import Cardano.Ledger.Keys (KeyRole (Staking))
import Cardano.Ledger.Plutus.ExUnits (ExUnits (..))
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Test.Cardano.Ledger.Common
import Test.Cardano.Ledger.Core.Arbitrary ()

spec :: Spec
spec = describe "DynamicPricing domain modules" $ do
  describe "usageOf" $ do
    it "returns zero usage for an absent inclusion strategy" $
      usageOf Urgent emptyBlockUsage `shouldBe` mempty

  describe "recordInclusionUsage" $ do
    prop "accumulates usage for the declared inclusion strategy" $
      forAll genUsage $ \usage ->
        forAll genUsage $ \moreUsage ->
          let recorded =
                recordUsage Urgent usage $
                  recordUsage Urgent moreUsage emptyBlockUsage
           in usageOf Urgent recorded === usage <> moreUsage

    prop "does not affect the other inclusion strategy" $
      forAll genUsage $ \usage ->
        let recorded = recordUsage Urgent usage emptyBlockUsage
         in usageOf Optimistic recorded === mempty

  describe "recordPendingRefund" $ do
    prop "accumulates multiple refunds for one credential" $
      \(cred :: Credential Staking) amount moreAmount ->
        let refunds =
              recordPendingRefund cred amount $
                recordPendingRefund cred moreAmount emptyPendingRefunds
         in pendingRefundsMap refunds === Map.singleton cred (amount <> moreAmount)

  describe "drainRefunds" $ do
    prop "returns all pending refunds and resets the domain value" $
      \(refunds :: Map (Credential Staking) Coin) ->
        let (drained, emptyRefunds) = drainRefunds (pendingRefundsFromMap refunds)
         in drained === refunds .&&. pendingRefundsMap emptyRefunds === Map.empty

recordUsage :: Inclusion -> InclusionUsage -> BlockUsage -> BlockUsage
recordUsage strategy (InclusionUsage bytes fees exUnits) =
  recordInclusionUsage strategy bytes fees exUnits

pendingRefundsMap :: PendingRefunds -> Map (Credential Staking) Coin
pendingRefundsMap refunds =
  fst (drainRefunds refunds)

genUsage :: Gen InclusionUsage
genUsage =
  InclusionUsage
    <$> (TxSizeInBytes <$> choose (0, 1_000_000))
    <*> (Coin <$> choose (0, 1_000_000_000))
    <*> genExUnits

genExUnits :: Gen ExUnits
genExUnits =
  ExUnits
    <$> genNatural
    <*> genNatural
  where
    genNatural = fromInteger <$> choose (0, 1_000_000)
