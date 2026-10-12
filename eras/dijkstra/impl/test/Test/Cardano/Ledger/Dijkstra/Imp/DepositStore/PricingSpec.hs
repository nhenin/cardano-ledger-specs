module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.PricingSpec (spec) where

import Test.Cardano.Ledger.Common (Expectation, Spec, describe, it, prop, shouldBe)

-- | New output obligations follow the accepted serialized size under the fixed pricing policy.
-- Executable backlog: assertions deliberately fail until ledger behavior is implemented.
-- Keep each requirement and its named check on one line.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec = describe "DS-PRICING - Pricing" $ do
  prop "DS-PRICING-P01 - ordinary success ⇒ newly recorded UTxO capacity deposit amounts equal coinsPerUTxOByte * (160 + acceptedSize) for store-backed outputs" acceptedSizePricing
  it "DS-PRICING-N01 - allocates each UTxO capacity deposit as coinsPerUTxOByte * (160 + accepted serialized output size)" allocatesDepositFromAcceptedSize
  it "DS-PRICING-N02 - uses the same UTxO capacity deposit formula for a store-backed collateral return" pricesCollateralReturnConsistently
  it "DS-PRICING-N03 - includes address, application assets, datum and reference script in the priced size" pricesAllOutputContents
  it "DS-PRICING-N04 - excludes the external UTxO capacity deposit amount and Store declaration from the priced output" excludesExternalDepositFromOutputSize
  it "DS-PRICING-N05 - handles CBOR size boundaries when an application coin amount changes" handlesCoinEncodingSizeBoundaries
  it "DS-PRICING-N06 - assigns no DepositStore obligation to implicit outputs" assignsNoStoreObligationToImplicitOutputs
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

assignsNoStoreObligationToImplicitOutputs :: Expectation
assignsNoStoreObligationToImplicitOutputs = False `shouldBe` True
