-- | Compose the presence domain sections.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.PresenceSpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Presence.ActivitySpec as Activity
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Presence.DependencySpec as Dependency

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-PRESENCE - Presence" $ do
  Activity.spec
  Dependency.spec
