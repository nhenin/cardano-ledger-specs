module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.DeclarationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "Each body declares its own Store activity (DS-TX-001)" $ do
    prop "storeBackedActivity(body) ⇒ hasDeclaration(body)" storeActivityRequiresDeclaration
    it "rejects a TopTx creating a store-backed output without a declaration" creatingTopTxOutputRequiresDeclaration
    it "rejects a TopTx spending a store-backed input without a declaration" spendingTopTxInputRequiresDeclaration
    it "rejects a SubTx creating a store-backed output without its own declaration" creatingSubTxOutputRequiresDeclaration
    it "rejects a SubTx spending a store-backed input without its own declaration" spendingSubTxInputRequiresDeclaration
    it "does not let a TopTx declaration replace a missing SubTx declaration" topTxDeclarationCannotReplaceSubTxDeclaration
    it "does not let a SubTx declaration replace a missing TopTx declaration" subTxDeclarationCannotReplaceTopTxDeclaration
    it "accepts implicit-only bodies without Store declarations" implicitOnlyBodiesNeedNoDeclaration
    it "does not require a declaration merely for referencing a store-backed output" referenceInputsNeedNoDeclaration
    it "does not treat collateral inputs or collateral return as ordinary Store activity" collateralIsNotOrdinaryStoreActivity
{- FOURMOLU_ENABLE -}

storeActivityRequiresDeclaration :: Bool
storeActivityRequiresDeclaration = False

creatingTopTxOutputRequiresDeclaration :: Expectation
creatingTopTxOutputRequiresDeclaration = False `shouldBe` True

spendingTopTxInputRequiresDeclaration :: Expectation
spendingTopTxInputRequiresDeclaration = False `shouldBe` True

creatingSubTxOutputRequiresDeclaration :: Expectation
creatingSubTxOutputRequiresDeclaration = False `shouldBe` True

spendingSubTxInputRequiresDeclaration :: Expectation
spendingSubTxInputRequiresDeclaration = False `shouldBe` True

topTxDeclarationCannotReplaceSubTxDeclaration :: Expectation
topTxDeclarationCannotReplaceSubTxDeclaration = False `shouldBe` True

subTxDeclarationCannotReplaceTopTxDeclaration :: Expectation
subTxDeclarationCannotReplaceTopTxDeclaration = False `shouldBe` True

implicitOnlyBodiesNeedNoDeclaration :: Expectation
implicitOnlyBodiesNeedNoDeclaration = False `shouldBe` True

referenceInputsNeedNoDeclaration :: Expectation
referenceInputsNeedNoDeclaration = False `shouldBe` True

collateralIsNotOrdinaryStoreActivity :: Expectation
collateralIsNotOrdinaryStoreActivity = False `shouldBe` True
