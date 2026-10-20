{-# LANGUAGE DataKinds #-}

-- | A release delegated to TopTx when a SubTx creates no outputs.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Settlement (
  finalInputsWithoutOutputs,
  withoutSubTxOutputs,
) where

import Cardano.Ledger.Dijkstra.Core
import qualified Data.OMap.Strict as OMap
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting (
  AccountingScenario,
  bodyOperations,
  scenario,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))

-- | One child consumes one to three existing Store-backed outputs and allocates
-- nothing. Its complete output sequence is removed before declaration and signing.
-- TopTx has no Store operations of its own and receives the resulting ordinary value.
finalInputsWithoutOutputs :: Gen AccountingScenario
finalInputsWithoutOutputs = do
  released <- chooseInt (1, 3)
  scenario (bodyOperations 0 0) [bodyOperations 0 released]

-- | Remove every child output before signing. Inputs and declarations are
-- preserved; this models closing the child's final Store-backed outputs. The
-- normal transaction builder balances the complete transaction at TopTx level.
withoutSubTxOutputs :: ReleaseTx -> ReleaseTx
withoutSubTxOutputs proposal =
  proposal
    { unsignedTx =
        unsignedTx proposal
          & bodyTxL . subTransactionsTxBodyL
            %~ (OMap.fromFoldable . map (bodyTxL . outputsTxBodyL .~ mempty) . OMap.elems)
    }
