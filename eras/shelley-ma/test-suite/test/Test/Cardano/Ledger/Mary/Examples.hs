{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ViewPatterns #-}

module Test.Cardano.Ledger.Mary.Examples (
  testMaryNoDelegLEDGER,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Mary (MaryEra)
import Cardano.Ledger.Shelley.API (LedgerEnv (..))
import Cardano.Ledger.Shelley.Core
import Cardano.Ledger.Shelley.LedgerState (
  AccountingState (..),
  LedgerState (..),
  smartAccountingState,
 )
import qualified Cardano.Ledger.Shelley.Rules as Shelley
import qualified Cardano.Ledger.State as Store
import Control.State.Transition.Extended hiding (Assertion)
import Data.Default (def)
import Data.List.NonEmpty (NonEmpty)
import GHC.Stack
import Lens.Micro
import Test.Cardano.Ledger.Mary.TreeDiff ()
import Test.Cardano.Ledger.Shelley.Utils (applySTSTest, runShelleyBase)
import Test.Control.State.Transition.Trace (checkTrace, (.-), (.->>))
import Test.Tasty.HUnit (Assertion, (@?=))

ignoreAllButUTxO ::
  Either (NonEmpty (PredicateFailure (Shelley.LEDGER MaryEra))) (LedgerState MaryEra) ->
  Either (NonEmpty (PredicateFailure (Shelley.LEDGER MaryEra))) (IndexedUTxOs MaryEra)
ignoreAllButUTxO = fmap (Store.allocations . asUTxOStore . lsAccountingState)

testMaryNoDelegLEDGER ::
  HasCallStack =>
  IndexedUTxOs MaryEra ->
  Tx TopTx MaryEra ->
  LedgerEnv MaryEra ->
  Either (NonEmpty (PredicateFailure (Shelley.LEDGER MaryEra))) (IndexedUTxOs MaryEra) ->
  Assertion
testMaryNoDelegLEDGER utxo tx env (Right expectedUTxO) = do
  checkTrace @(Shelley.LEDGER MaryEra) runShelleyBase env $
    pure (LedgerState (smartAccountingState (ledgerPp env) utxo (Coin 0) (Coin 0) mempty) def def)
      .- tx
      .->> expectedSt'
  where
    txFee = tx ^. bodyTxL . feeTxBodyL
    expectedSt' = LedgerState (smartAccountingState (ledgerPp env) expectedUTxO (Coin 0) txFee mempty) def def
testMaryNoDelegLEDGER utxo tx env predicateFailure@(Left _) = do
  let st =
        runShelleyBase $
          applySTSTest @(Shelley.LEDGER MaryEra)
            ( TRC
                ( env
                , LedgerState (smartAccountingState (ledgerPp env) utxo (Coin 0) (Coin 0) mempty) def def
                , tx
                )
            )
  ignoreAllButUTxO st @?= predicateFailure
