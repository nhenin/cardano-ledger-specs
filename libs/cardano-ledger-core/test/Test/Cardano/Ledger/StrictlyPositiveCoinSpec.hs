{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.StrictlyPositiveCoinSpec (spec) where

import Cardano.Ledger.Binary (allVersions, decodeFull, serialize)
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.StrictlyPositiveCoin (
  StrictlyPositiveCoin,
  mkStrictlyPositiveCoin,
  unStrictlyPositiveCoin,
 )
import qualified Data.Aeson as Aeson
import Data.Either (isLeft)
import Data.Word (Word64)
import Test.Cardano.Ledger.Common

spec :: Spec
spec = describe "StrictlyPositiveCoin" $ do
  let maximumAmount = toInteger (maxBound :: Word64)

  it "accepts 1 and 2^64 - 1 lovelace and preserves both through CBOR and JSON" $
    forM_ [1, maximumAmount] $ \amount -> do
      positive <- expectJust $ mkStrictlyPositiveCoin (Coin amount)
      unStrictlyPositiveCoin positive `shouldBe` Coin amount
      forM_ allVersions $ \version -> do
        decodeFull @StrictlyPositiveCoin version (serialize version amount) `shouldBe` Right positive
        decodeFull @StrictlyPositiveCoin version (serialize version positive) `shouldBe` Right positive
      Aeson.eitherDecode @StrictlyPositiveCoin (Aeson.encode amount) `shouldBe` Right positive
      Aeson.eitherDecode @StrictlyPositiveCoin (Aeson.encode positive) `shouldBe` Right positive

  prop "constructs and preserves generated amounts from 1 through 2^64 - 1" $
    forAll (chooseInteger (1, maximumAmount)) $ \amount -> do
      positive <- expectJust $ mkStrictlyPositiveCoin (Coin amount)
      unStrictlyPositiveCoin positive `shouldBe` Coin amount
      forM_ allVersions $ \version -> do
        decodeFull @StrictlyPositiveCoin version (serialize version amount) `shouldBe` Right positive
        decodeFull @StrictlyPositiveCoin version (serialize version positive) `shouldBe` Right positive
      Aeson.eitherDecode @StrictlyPositiveCoin (Aeson.encode amount) `shouldBe` Right positive
      Aeson.eitherDecode @StrictlyPositiveCoin (Aeson.encode positive) `shouldBe` Right positive

  it "rejects -1, zero and 2^64 in construction and both decoders" $
    forM_ [-1, 0, maximumAmount + 1] $ \amount -> do
      mkStrictlyPositiveCoin (Coin amount) `shouldBe` Nothing
      forM_ allVersions $ \version ->
        decodeFull @StrictlyPositiveCoin version (serialize version amount) `shouldSatisfy` isLeft
      Aeson.eitherDecode @StrictlyPositiveCoin (Aeson.encode amount) `shouldSatisfy` isLeft

  prop "rejects generated zero or negative amounts in construction and both decoders" $
    forAll (negate . getNonNegative <$> arbitrary @(NonNegative Integer)) $ \amount -> do
      mkStrictlyPositiveCoin (Coin amount) `shouldBe` Nothing
      forM_ allVersions $ \version ->
        decodeFull @StrictlyPositiveCoin version (serialize version amount) `shouldSatisfy` isLeft
      Aeson.eitherDecode @StrictlyPositiveCoin (Aeson.encode amount) `shouldSatisfy` isLeft

  prop "rejects generated amounts above 2^64 - 1 in construction and both decoders" $
    forAll ((maximumAmount + 1 +) . getNonNegative <$> arbitrary @(NonNegative Integer)) $ \amount -> do
      mkStrictlyPositiveCoin (Coin amount) `shouldBe` Nothing
      forM_ allVersions $ \version ->
        decodeFull @StrictlyPositiveCoin version (serialize version amount) `shouldSatisfy` isLeft
      Aeson.eitherDecode @StrictlyPositiveCoin (Aeson.encode amount) `shouldSatisfy` isLeft
