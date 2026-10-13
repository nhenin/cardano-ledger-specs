-- | Compose the activity domain sections.
--
-- Contract: for accepted transactions on either phase-2 outcome, inspect each
-- body's hypothetical ordinary inputs and outputs. Presence requires its own
-- field; TopTx's amount still declares the complete batch, not its own contribution.
-- Accepted-case coverage must include both outcomes and both body levels.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Presence.ActivitySpec (spec) where

import Test.Cardano.Ledger.Common (Spec, describe, prop)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Presence.Activity.CreationSpec as Creation
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Presence.Activity.ScopeSpec as Scope
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.TransactionRules.Tx.Presence.Activity.SpendingSpec as Spending

-- | Register the requirements in domain order.
spec :: Spec
spec = describe "DS-TX-PRESENCE-ACTIVITY - Activity" $ do
  prop
    "DS-TX-PRESENCE-ACTIVITY-P01 - accepted transaction ⇒ every body creating or spending store-backed outputs has its own declaration"
    storeActivityRequiresDeclaration
  Creation.spec
  Spending.spec
  Scope.spec

-- | accepted transaction ⇒ every body creating or spending store-backed outputs has its own declaration
-- Executable backlog: replace with a ledger check against independent expectations.
storeActivityRequiresDeclaration :: Bool
storeActivityRequiresDeclaration = False
