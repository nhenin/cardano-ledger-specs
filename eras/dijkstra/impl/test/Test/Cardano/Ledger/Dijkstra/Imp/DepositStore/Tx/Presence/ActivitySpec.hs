-- | Compose the activity domain sections.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Presence.ActivitySpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe, prop)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Presence.Activity.CreationSpec as Creation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Presence.Activity.ScopeSpec as Scope
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Tx.Presence.Activity.SpendingSpec as Spending

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-PRESENCE-ACTIVITY - Activity" $ do
  prop
    "DS-TX-PRESENCE-ACTIVITY-P01 - A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change."
    storeActivityRequiresDeclaration
  Creation.spec
  Spending.spec
  Scope.spec

-- | A body creating or spending store-backed outputs must declare its own UTxO capacity deposit change.
-- Executable backlog: replace with a ledger check against independent expectations.
storeActivityRequiresDeclaration :: Bool
storeActivityRequiresDeclaration = False
