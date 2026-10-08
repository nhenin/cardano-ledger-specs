module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ApplicationAssetsSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "Application assets may be empty when the UTxO capacity deposit is funded (DS-TX-012)" $ do
    it "accepts a store-backed output containing native assets and zero ADA" nativeAssetsNeedNoApplicationAda
    it "accepts empty application assets with a datum or reference script" datumOrScriptAllowsEmptyApplicationAssets
    it "accepts a store-backed output containing only an address" addressOnlyOutputIsAccepted
    it "still requires the exact UTxO capacity deposit for an output with no application assets" emptyApplicationAssetsStillRequireExactDeposit
    it "preserves the minimum-coin requirement for implicit outputs" implicitOutputsStillRequireMinimumCoin
{- FOURMOLU_ENABLE -}

nativeAssetsNeedNoApplicationAda :: Expectation
nativeAssetsNeedNoApplicationAda = False `shouldBe` True

datumOrScriptAllowsEmptyApplicationAssets :: Expectation
datumOrScriptAllowsEmptyApplicationAssets = False `shouldBe` True

addressOnlyOutputIsAccepted :: Expectation
addressOnlyOutputIsAccepted = False `shouldBe` True

emptyApplicationAssetsStillRequireExactDeposit :: Expectation
emptyApplicationAssetsStillRequireExactDeposit = False `shouldBe` True

implicitOutputsStillRequireMinimumCoin :: Expectation
implicitOutputsStillRequireMinimumCoin = False `shouldBe` True
