-- | Compose the tx domain sections.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.TxSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.ApplicationAssetsSpec as ApplicationAssets
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.AttributionSpec as Attribution
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.AuthorizationSpec as Authorization
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.ConservationSpec as Conservation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.ExactnessSpec as Exactness
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.GrammarSpec as Grammar
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.PresenceSpec as Presence
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.SettlementSpec as Settlement

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX - Tx" $ do
  Grammar.spec
  Presence.spec
  Exactness.spec
  Attribution.spec
  Conservation.spec
  Authorization.spec
  Settlement.spec
  ApplicationAssets.spec
