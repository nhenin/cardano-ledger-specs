{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | State fixtures for era translation and epoch boundaries. Translation inputs
-- are generated states, not transaction submissions; live Store fixtures are
-- funded through accepted transactions by the existing accounting adapter.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Lifecycle (
  conwayStates,
  populatedStore,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Conway (ConwayEra)
import Cardano.Ledger.Conway.State (ConwayAccountState (..), ConwayAccounts (..))
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Plutus (Datum (..))
import Cardano.Ledger.Shelley.LedgerState
import Cardano.Ledger.State
import Cardano.Ledger.TxIn (TxIn (..))
import qualified Data.Map.Strict as Map
import Data.Maybe.Strict (StrictMaybe (..))
import Lens.Micro
import Test.Cardano.Ledger.Alonzo.Arbitrary (genPlutusScript)
import Test.Cardano.Ledger.Common (Gen, arbitrary, chooseInt, chooseInteger, resize)
import Test.Cardano.Ledger.Conway.Arbitrary ()
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting as Accounting

-- | Every generated pair contains zero and distinct positive monetary pots.
-- Each UTxO contains all datum/reference-script combinations and two identical
-- outputs at different indices, so translation must preserve payloads and keys.
conwayStates :: Gen [NewEpochState ConwayEra]
conwayStates = do
  previousState <- resize 3 arbitrary
  output <- resize 4 $ arbitrary @(TxOut ConwayEra)
  inputId <- arbitrary
  datumHash <- arbitrary
  inlineDatum <- resize 3 arbitrary
  nativeScript <- fromNativeScript <$> resize 3 (arbitrary @(NativeScript ConwayEra))
  plutusScript <- fromPlutusScript <$> (arbitrary >>= genPlutusScript @ConwayEra)
  credential <- arbitrary
  amount <- chooseInteger (1, 1_000_000_000)
  let outputs =
        [ output & datumTxOutL .~ datum & referenceScriptTxOutL .~ script
        | datum <- [NoDatum, DatumHash datumHash, Datum inlineDatum]
        , script <- [SNothing, SJust nativeScript, SJust plutusScript]
        ]
      outputMap =
        Map.fromList $
          zipWith (\index txOut -> (TxIn inputId $ TxIx index, txOut)) [0 ..] (head outputs : outputs)
      utxoStateL = nesEsL . esLStateL . lsUTxOStateL
      accountStatesL = nesEsL . esLStateL . lsCertStateL . certDStateL . accountsL
      withPots factor =
        previousState
          & utxoStateL . utxosOutputStorageL .~ LegacyOutputs (UTxO outputMap)
          & treasuryL .~ Coin (factor * amount)
          & reservesL .~ Coin (factor * (amount + 1))
          & utxoStateL . utxosDepositedL .~ Coin (factor * (amount + 2))
          & utxoStateL . utxosFeesL .~ Coin (factor * (amount + 3))
          & utxoStateL . utxosDonationL .~ Coin (factor * (amount + 4))
          & accountStatesL
            .~ ConwayAccounts
              ( Map.singleton credential $
                  ConwayAccountState
                    (CompactCoin $ fromInteger $ factor * (amount + 5))
                    (CompactCoin $ fromInteger $ factor * (amount + 6))
                    Nothing
                    Nothing
              )
  pure [withPots 0, withPots 1]

-- | Funding establishes one to five live allocation records through an accepted
-- transaction. The generated proposal is left unsubmitted, so those records remain live.
populatedStore :: Gen Accounting.AccountingScenario
populatedStore = do
  allocationCount <- chooseInt (1, 5)
  Accounting.scenario (Accounting.bodyOperations 0 allocationCount) []
