-- | Compose the tx domain sections.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TxSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ApplicationAssetsSpec as ApplicationAssets
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.AttributionSpec as Attribution
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.AuthorizationSpec as Authorization
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ConservationSpec as Conservation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.ExactnessSpec as Exactness
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.GrammarSpec as Grammar
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.PresenceSpec as Presence
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.SettlementSpec as Settlement

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
