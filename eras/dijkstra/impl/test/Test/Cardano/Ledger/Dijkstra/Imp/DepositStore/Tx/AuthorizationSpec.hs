-- | Authorization requirements, retained as executable backlog until implemented.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.AuthorizationSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, shouldBe)

-- | Keep each mathematical requirement beside its named example.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DS-TX-AUTHORIZATION - Authorization" $ do
    it "DS-TX-AUTHORIZATION-N01 - allows the authorized spender to release UTxO capacity deposits paid by another person" authorizedSpenderCanReleaseAnotherPersonsDeposit
    it "DS-TX-AUTHORIZATION-N02 - does not require a separate signature from the original UTxO capacity deposit funder" originalFunderSignatureIsNotRequired
    it "DS-TX-AUTHORIZATION-F01 - rejects unauthorized spending even when the Store declaration is exact" exactDeclarationDoesNotAuthorizeSpending
    it "DS-TX-AUTHORIZATION-N03 - does not release UTxO capacity deposits for a reference input" referenceInputDoesNotReleaseDeposit
{- FOURMOLU_ENABLE -}

-- | Allows the authorized spender to release UTxO capacity deposits paid by another person
-- Executable backlog: replace with a ledger check against independent expectations.
authorizedSpenderCanReleaseAnotherPersonsDeposit :: Expectation
authorizedSpenderCanReleaseAnotherPersonsDeposit = False `shouldBe` True

-- | Does not require a separate signature from the original UTxO capacity deposit funder
-- Executable backlog: replace with a ledger check against independent expectations.
originalFunderSignatureIsNotRequired :: Expectation
originalFunderSignatureIsNotRequired = False `shouldBe` True

-- | Rejects unauthorized spending even when the Store declaration is exact
-- Executable backlog: replace with a ledger check against independent expectations.
exactDeclarationDoesNotAuthorizeSpending :: Expectation
exactDeclarationDoesNotAuthorizeSpending = False `shouldBe` True

-- | Does not release UTxO capacity deposits for a reference input
-- Executable backlog: replace with a ledger check against independent expectations.
referenceInputDoesNotReleaseDeposit :: Expectation
referenceInputDoesNotReleaseDeposit = False `shouldBe` True
