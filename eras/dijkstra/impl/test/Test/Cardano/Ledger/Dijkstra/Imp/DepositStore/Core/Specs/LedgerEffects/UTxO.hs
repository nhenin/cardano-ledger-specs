{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE PatternSynonyms #-}

-- | Input roles for real script transactions. These builders preserve the funded
-- collateral proposal and ordinary balance; they never apply a ledger transition.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.LedgerEffects.UTxO (
  withReferenceOnlyInput,
  withSharedOrdinaryInput,
) where

import Cardano.Ledger.Alonzo.TxWits (unRedeemersL)
import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Shelley.LedgerState (utxosUtxo)
import Cardano.Ledger.State (depositStoreAllocations, unUTxO)
import Cardano.Ledger.StrictlyPositiveCoin (mkStrictlyPositiveCoin)
import Data.Foldable (toList)
import qualified Data.Map.Strict as Map
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Collateral (Fixture (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (recordedDepositStore)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release (ordinarySpendingInputs)
import Test.Cardano.Ledger.Dijkstra.ImpTest (ImpTestM, fixupPPHash, rederiveAddrTxWits)
import Test.Cardano.Ledger.Imp.Common (expectJust)

-- | Reference a funded Store-backed output outside both consuming input sets.
-- Its full output and allocation must survive either script outcome.
withReferenceOnlyInput :: Fixture -> ImpTestM DijkstraEra Fixture
withReferenceOnlyInput fixture@Fixture {signedTx, previousUTxOState, collateralInputs} = do
  let recordedInputs = Map.keysSet . depositStoreAllocations $ recordedDepositStore previousUTxOState
  reference <-
    expectJust $
      Set.lookupMin $
        recordedInputs Set.\\ (ordinarySpendingInputs signedTx <> collateralInputs)
  signed <-
    rederiveAddrTxWits $
      signedTx & bodyTxL . referenceInputsTxBodyL %~ Set.insert reference
  pure fixture {signedTx = signed}

-- | Give one funded Store-backed collateral input an ordinary role as well.
-- Its application ADA and recorded deposit are returned through ordinary output
-- zero, with an exact ordinary release declaration. Existing redeemer purposes
-- are reindexed by their original input identity before recomputing signatures.
-- Both real script outcomes remain valid proposals: the selected path consumes
-- this shared source once; the inactive path does not consume it a second time.
withSharedOrdinaryInput :: Fixture -> ImpTestM DijkstraEra Fixture
withSharedOrdinaryInput fixture@Fixture {signedTx, previousUTxOState, collateralInputs} = do
  let records = depositStoreAllocations $ recordedDepositStore previousUTxOState
      sourceOutputs = unUTxO $ utxosUtxo previousUTxOState
      originalInputs = signedTx ^. bodyTxL . inputsTxBodyL
  sharedInput <- expectJust $ Set.lookupMin $ collateralInputs `Set.intersection` Map.keysSet records
  source <- expectJust $ Map.lookup sharedInput sourceOutputs
  recordedDeposit <- expectJust $ Map.lookup sharedInput records
  positiveDeposit <- expectJust $ mkStrictlyPositiveCoin recordedDeposit
  let inputs = Set.insert sharedInput originalInputs
      reindex (SpendingPurpose (AsIx index)) =
        SpendingPurpose . AsIx . fromIntegral . (`Set.findIndex` inputs) $
          Set.elemAt (fromIntegral index) originalInputs
      reindex purpose = purpose
      releasedCoins = (source ^. coinTxOutL) <> recordedDeposit
      proposal =
        signedTx
          & bodyTxL . inputsTxBodyL .~ inputs
          & bodyTxL . outputsTxBodyL
            %~ SSeq.fromList
              . zipWith
                ( \index output ->
                    if index == (0 :: Int) then output & coinTxOutL %~ (<> releasedCoins) else output
                )
                [0 ..]
              . toList
          & bodyTxL . netUTxODepositChangeTxBodyL
            .~ TopTx.DeclaresNetUTxODepositRelease positiveDeposit (TopTx.TopTxSettlementOutput $ TxIx 0)
          & witsTxL . rdmrsTxWitsL . unRedeemersL %~ Map.mapKeys reindex
  signed <- fixupPPHash proposal >>= rederiveAddrTxWits
  pure fixture {signedTx = signed}
