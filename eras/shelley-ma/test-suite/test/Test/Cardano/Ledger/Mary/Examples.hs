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
import Cardano.Ledger.Shelley.LedgerState (LedgerState (..), UTxOState (..), smartUTxOState)
import qualified Cardano.Ledger.Shelley.Rules as Shelley
import Cardano.Ledger.State (UTxO (..))
import qualified Cardano.Ledger.State as Store
import qualified Cardano.Ledger.State.UTxOs.Allocations as Allocations
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
  Either (NonEmpty (PredicateFailure (Shelley.LEDGER MaryEra))) (UTxO MaryEra)
ignoreAllButUTxO =
  fmap
    ( \( LedgerState
           ( UTxOState
               ((UTxO . Allocations.toTxOutMap . Store.allocations) -> utxo)
               _
               _
               _
               _
               _
             )
           _
         ) -> utxo
    )

testMaryNoDelegLEDGER ::
  HasCallStack =>
  UTxO MaryEra ->
  Tx TopTx MaryEra ->
  LedgerEnv MaryEra ->
  Either (NonEmpty (PredicateFailure (Shelley.LEDGER MaryEra))) (UTxO MaryEra) ->
  Assertion
testMaryNoDelegLEDGER utxo tx env (Right expectedUTxO) = do
  checkTrace @(Shelley.LEDGER MaryEra) runShelleyBase env $
    pure (LedgerState (smartUTxOState (ledgerPp env) utxo (Coin 0) (Coin 0) def mempty) def)
      .- tx
      .->> expectedSt'
  where
    txFee = tx ^. bodyTxL . feeTxBodyL
    expectedSt' = LedgerState (smartUTxOState (ledgerPp env) expectedUTxO (Coin 0) txFee def mempty) def
testMaryNoDelegLEDGER utxo tx env predicateFailure@(Left _) = do
  let st =
        runShelleyBase $
          applySTSTest @(Shelley.LEDGER MaryEra)
            ( TRC
                ( env
                , LedgerState (smartUTxOState (ledgerPp env) utxo (Coin 0) (Coin 0) def mempty) def
                , tx
                )
            )
  ignoreAllButUTxO st @?= predicateFailure
