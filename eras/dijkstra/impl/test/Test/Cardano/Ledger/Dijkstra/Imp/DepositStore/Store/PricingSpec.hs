module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Store.PricingSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | Intentionally failing placeholders for the agreed DepositStore rules.
-- Replace each placeholder with a ledger check against independent expectations.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-STORE-003 - UTxO capacity deposits use the fixed policy and the accepted output size" $ do
  prop "ordinary success ⇒ newly recorded UTxO capacity deposit amounts equal coinsPerUTxOByte * (160 + acceptedSize) for store-backed outputs" acceptedSizePricing
  it "allocates each UTxO capacity deposit as coinsPerUTxOByte * (160 + accepted serialized output size)" allocatesDepositFromAcceptedSize
  it "uses the same UTxO capacity deposit formula for a store-backed collateral return" pricesCollateralReturnConsistently
  it "includes address, application assets, datum and reference script in the priced size" pricesAllOutputContents
  it "excludes the external UTxO capacity deposit amount and Store declaration from the priced output" excludesExternalDepositFromOutputSize
  it "handles CBOR size boundaries when an application coin amount changes" handlesCoinEncodingSizeBoundaries
  it "releases the allocated UTxO capacity deposit even when reserialization would change the output size" releasesRecordedDepositAfterReserialization
  it "assigns no DepositStore obligation to implicit outputs" assignsNoStoreObligationToImplicitOutputs
{- FOURMOLU_ENABLE -}

acceptedSizePricing :: Bool
acceptedSizePricing = False

allocatesDepositFromAcceptedSize :: Expectation
allocatesDepositFromAcceptedSize = False `shouldBe` True

pricesCollateralReturnConsistently :: Expectation
pricesCollateralReturnConsistently = False `shouldBe` True

pricesAllOutputContents :: Expectation
pricesAllOutputContents = False `shouldBe` True

excludesExternalDepositFromOutputSize :: Expectation
excludesExternalDepositFromOutputSize = False `shouldBe` True

handlesCoinEncodingSizeBoundaries :: Expectation
handlesCoinEncodingSizeBoundaries = False `shouldBe` True

releasesRecordedDepositAfterReserialization :: Expectation
releasesRecordedDepositAfterReserialization = False `shouldBe` True

assignsNoStoreObligationToImplicitOutputs :: Expectation
assignsNoStoreObligationToImplicitOutputs = False `shouldBe` True
