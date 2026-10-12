-- | Application assets requirements, retained as executable backlog until implemented.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ApplicationAssetsSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-APPLICATION-ASSETS - Application assets" $ do
    it "DS-TX-APPLICATION-ASSETS-N01 - accepts a store-backed output containing native assets and zero ADA" nativeAssetsNeedNoApplicationAda
    it "DS-TX-APPLICATION-ASSETS-N02 - accepts empty application assets with a datum or reference script" datumOrScriptAllowsEmptyApplicationAssets
    it "DS-TX-APPLICATION-ASSETS-N03 - accepts a store-backed output containing only an address" addressOnlyOutputIsAccepted
    it "DS-TX-APPLICATION-ASSETS-N04 - preserves the minimum-coin requirement for implicit outputs" implicitOutputsStillRequireMinimumCoin
{- FOURMOLU_ENABLE -}

-- | Accepts a store-backed output containing native assets and zero ADA
-- Executable backlog: replace with a ledger check against independent expectations.
nativeAssetsNeedNoApplicationAda :: Expectation
nativeAssetsNeedNoApplicationAda = False `shouldBe` True

-- | Accepts empty application assets with a datum or reference script
-- Executable backlog: replace with a ledger check against independent expectations.
datumOrScriptAllowsEmptyApplicationAssets :: Expectation
datumOrScriptAllowsEmptyApplicationAssets = False `shouldBe` True

-- | Accepts a store-backed output containing only an address
-- Executable backlog: replace with a ledger check against independent expectations.
addressOnlyOutputIsAccepted :: Expectation
addressOnlyOutputIsAccepted = False `shouldBe` True

-- | Preserves the minimum-coin requirement for implicit outputs
-- Executable backlog: replace with a ledger check against independent expectations.
implicitOutputsStillRequireMinimumCoin :: Expectation
implicitOutputsStillRequireMinimumCoin = False `shouldBe` True
