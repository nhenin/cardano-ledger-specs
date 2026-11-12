-- | Store-specific collateral validation. Existing generic coverage is inherited
-- from UTXO/UTXOW; remaining generic gaps are tracked in the rules document.
-- Applied effects belong to LedgerEffects.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.CollateralSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.AssetsSpec as Assets
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.FundingSpec as Funding
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Collateral.TotalSpec as Total

spec :: Spec
spec = describe "Collateral" $ do
  Funding.spec
  Total.spec
  Assets.spec
