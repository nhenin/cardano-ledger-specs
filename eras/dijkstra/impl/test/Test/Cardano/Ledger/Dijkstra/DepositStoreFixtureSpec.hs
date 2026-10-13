-- | Verify generated fixture contracts independently of protocol enforcement.
module Test.Cardano.Ledger.Dijkstra.DepositStoreFixtureSpec (spec) where

import Cardano.Ledger.Dijkstra.Core (subTransactionsTxBodyL)
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (Spec, describe, prop, (===))
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration as Declaration

-- | Preserve declaration identity independently of protocol enforcement.
-- Spending scenarios are now verified through actual ledger submission.
{- FOURMOLU_DISABLE -}
spec :: Spec
spec =
  describe "DepositStore fixtures" $ do
    prop "preserves the number of SubTxs, including those with repeated declarations" $
      Declaration.forAllCases $ \declarations ->
        length (Declaration.declarationToTxBody declarations ^. subTransactionsTxBodyL) === length (Declaration.subTxDeclarations declarations)

{- FOURMOLU_ENABLE -}
