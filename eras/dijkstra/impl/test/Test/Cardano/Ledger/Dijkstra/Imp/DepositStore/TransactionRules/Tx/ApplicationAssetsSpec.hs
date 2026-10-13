-- | Application assets requirements, retained as executable backlog until implemented.
--
-- Contract: use otherwise valid transactions with exact declared deposits and
-- batch funding. Cover both body levels; distinguish output admissibility from
-- deposit pricing. Datum-only and reference-script-only are separate cases within
-- N02. Implicit minimum-coin controls cover equality and one lovelace below it.
-- Output validation applies on both phase-2 outcomes.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.ApplicationAssetsSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-APPLICATION-ASSETS - Application assets" $ do
    it "DS-TX-APPLICATION-ASSETS-N01 - accepts a store-backed output containing native assets and zero ADA" nativeAssetsNeedNoApplicationAda
    it "DS-TX-APPLICATION-ASSETS-N02 - accepts empty application assets with a datum or reference script" datumOrScriptAllowsEmptyApplicationAssets
    it "DS-TX-APPLICATION-ASSETS-N03 - accepts a store-backed output containing only an address" addressOnlyOutputIsAccepted
    it "DS-TX-APPLICATION-ASSETS-N04 - accepts implicit outputs containing exactly their required minimum coin" implicitOutputsStillRequireMinimumCoin
    it "DS-TX-APPLICATION-ASSETS-F01 - rejects implicit outputs one lovelace below their required minimum coin" implicitOutputsBelowMinimumAreRejected
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

-- | Accepts implicit outputs containing exactly their required minimum coin
-- Executable backlog: replace with a ledger check against independent expectations.
implicitOutputsStillRequireMinimumCoin :: Expectation
implicitOutputsStillRequireMinimumCoin = False `shouldBe` True

-- | Rejects implicit outputs one lovelace below their required minimum coin
-- Executable backlog: replace with a ledger check against independent expectations.
implicitOutputsBelowMinimumAreRejected :: Expectation
implicitOutputsBelowMinimumAreRejected = False `shouldBe` True
