-- | Compose the exactness domain sections.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ExactnessSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Exactness.ContributionSpec as Contribution
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Exactness.NettingSpec as Netting

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-EXACTNESS - Exactness" $ do
  Contribution.spec
  Netting.spec
