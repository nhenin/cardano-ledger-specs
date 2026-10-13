-- | Compose the settlement domain sections.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.SettlementSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.CoverageSpec as Coverage
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.DestinationSpec as Destination
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Settlement.ParticipationSpec as Participation

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-SETTLEMENT - Settlement" $ do
  Participation.spec
  Destination.spec
  Coverage.spec
