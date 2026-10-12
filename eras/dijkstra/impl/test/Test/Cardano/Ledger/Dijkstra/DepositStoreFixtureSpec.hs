-- | Verify declaration-fixture identity independently of protocol requirements.
module Test.Cardano.Ledger.Dijkstra.DepositStoreFixtureSpec (spec) where

import Cardano.Ledger.Dijkstra.Core (subTransactionsTxBodyL)
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (Spec, describe, prop, (===))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Dependency.Fixture as Fixture
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Dependency.Transaction (
  declarationToTxBody,
 )

-- | Ensure OMap construction retains distinct SubTxs even with repeated declarations.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DepositStore fixtures" $
    prop "preserves the number of SubTxs, including those with repeated declarations" $
      Fixture.forAllCases $ \declarations ->
        length (declarationToTxBody declarations ^. subTransactionsTxBodyL) === length (Fixture.subTxDeclarations declarations)
{- FOURMOLU_ENABLE -}
