-- | Compose the exactness domain sections.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.ExactnessSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Exactness.ContributionSpec as Contribution
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Exactness.NettingSpec as Netting

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-EXACTNESS - Exactness" $ do
  Contribution.spec
  Netting.spec
