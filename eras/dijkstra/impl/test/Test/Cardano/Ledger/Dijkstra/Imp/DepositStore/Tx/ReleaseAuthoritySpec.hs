module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ReleaseAuthoritySpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Executable backlog: these checks deliberately fail until implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "Spending authority controls the release of UTxO capacity deposits (DS-TX-011)" $ do
    it "allows the authorized spender to release UTxO capacity deposits paid by another person" authorizedSpenderCanReleaseAnotherPersonsDeposit
    it "does not require a separate signature from the original UTxO capacity deposit funder" originalFunderSignatureIsNotRequired
    it "rejects unauthorized spending even when the Store declaration is exact" exactDeclarationDoesNotAuthorizeSpending
    it "does not release UTxO capacity deposits for a reference input" referenceInputDoesNotReleaseDeposit
{- FOURMOLU_ENABLE -}

authorizedSpenderCanReleaseAnotherPersonsDeposit :: Expectation
authorizedSpenderCanReleaseAnotherPersonsDeposit = False `shouldBe` True

originalFunderSignatureIsNotRequired :: Expectation
originalFunderSignatureIsNotRequired = False `shouldBe` True

exactDeclarationDoesNotAuthorizeSpending :: Expectation
exactDeclarationDoesNotAuthorizeSpending = False `shouldBe` True

referenceInputDoesNotReleaseDeposit :: Expectation
referenceInputDoesNotReleaseDeposit = False `shouldBe` True
