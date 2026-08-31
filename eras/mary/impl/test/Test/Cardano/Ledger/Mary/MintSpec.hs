{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.Mary.MintSpec (spec) where

import Cardano.Ledger.Core (TxLevel (TopTx), mkBasicTxBody)
import Cardano.Ledger.Mary (MaryEra)
import Cardano.Ledger.Mary.Mint
import Cardano.Ledger.Mary.TxBody
import Cardano.Ledger.Mary.Value (AssetName, MultiAsset (..), PolicyID, flattenMultiAsset, policies)
import Data.Group (Group (invert))
import qualified Data.Map.Strict as Map
import Lens.Micro ((&), (.~), (^.))
import Test.Cardano.Ledger.Common
import Test.Cardano.Ledger.Mary.Arbitrary ()

spec :: Spec
spec = describe "MintDelta" $ do
  prop "separates minted and burned quantities" $ \(multiAsset :: MultiAsset) ->
    let delta = MintDelta multiAsset
        minted = unMintedAssets (mintedAssets delta)
        burned = unBurnedAssets (burnedAssets delta)
     in do
          all ((> 0) . third) (flattenMultiAsset minted) `shouldBe` True
          all ((> 0) . third) (flattenMultiAsset burned) `shouldBe` True
          minted <> invert burned `shouldBe` multiAsset

  prop "drops zero quantities from both projections" $ \(policy :: PolicyID) (assetName :: AssetName) ->
    let delta = MintDelta (MultiAsset (Map.singleton policy (Map.singleton assetName 0)))
     in do
          flattenMultiAsset (unMintedAssets (mintedAssets delta)) `shouldBe` []
          flattenMultiAsset (unBurnedAssets (burnedAssets delta)) `shouldBe` []

  prop "transaction-body views preserve the existing mint lens" $ \(multiAsset :: MultiAsset) ->
    let delta = MintDelta multiAsset
        txBody = mkBasicTxBody @MaryEra @TopTx & mintDeltaTxBodyL .~ delta
     in do
          txBody ^. mintTxBodyL `shouldBe` multiAsset
          unMintDelta (txBody ^. mintDeltaTxBodyL) `shouldBe` multiAsset
          txBody ^. mintedAssetsTxBodyF `shouldBe` mintedAssets delta
          txBody ^. burnedAssetsTxBodyF `shouldBe` burnedAssets delta
          txBody ^. mintPoliciesTxBodyF `shouldBe` policies multiAsset
          txBody ^. mintedTxBodyF `shouldBe` policies multiAsset

third :: (a, b, c) -> c
third (_, _, c) = c
