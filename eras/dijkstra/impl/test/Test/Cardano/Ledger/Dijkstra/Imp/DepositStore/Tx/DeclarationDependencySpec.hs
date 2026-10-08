module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.DeclarationDependencySpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "A SubTx declaration requires a TopTx declaration (DS-TX-009)" $ do
    prop "any SubTx has a declaration ⇒ TopTx has a declaration" subTxDeclarationRequiresTopTxDeclaration
    it "accepts absent declarations on both levels when there is no Store activity" noStoreActivityAllowsAbsentDeclarations
    it "rejects a SubTx zero declaration when TopTx declares nothing" subTxZeroRequiresTopTxDeclaration
    it "accepts zero declarations on both levels when there is no Store activity" noStoreActivityAllowsZeroDeclarations
    it "accepts a TopTx zero declaration without SubTx declarations when there is no Store activity" topTxZeroDoesNotRequireSubTxDeclarations
    it "still requires TopTx's declaration when local SubTx contributions cancel" offsettingSubTxChangesStillRequireTopTxDeclaration
    it "requires TopTx's declaration for both local and delegated SubTx operations" localAndDelegatedOperationsRequireTopTxDeclaration
{- FOURMOLU_ENABLE -}

subTxDeclarationRequiresTopTxDeclaration :: Bool
subTxDeclarationRequiresTopTxDeclaration = False

noStoreActivityAllowsAbsentDeclarations :: Expectation
noStoreActivityAllowsAbsentDeclarations = False `shouldBe` True

subTxZeroRequiresTopTxDeclaration :: Expectation
subTxZeroRequiresTopTxDeclaration = False `shouldBe` True

noStoreActivityAllowsZeroDeclarations :: Expectation
noStoreActivityAllowsZeroDeclarations = False `shouldBe` True

topTxZeroDoesNotRequireSubTxDeclarations :: Expectation
topTxZeroDoesNotRequireSubTxDeclarations = False `shouldBe` True

offsettingSubTxChangesStillRequireTopTxDeclaration :: Expectation
offsettingSubTxChangesStillRequireTopTxDeclaration = False `shouldBe` True

localAndDelegatedOperationsRequireTopTxDeclaration :: Expectation
localAndDelegatedOperationsRequireTopTxDeclaration = False `shouldBe` True
