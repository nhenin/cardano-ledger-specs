{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}

-- | DepositStore checks at the two transaction levels.
module Cardano.Ledger.Dijkstra.Rules.DepositStore (
  validateSubTx,
  validateTopTx,
) where

import qualified Cardano.Ledger.Alonzo.Rules as Alonzo
import qualified Cardano.Ledger.Babbage.Rules as Babbage
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules.DepositStore.Accounting (
  DepositStoreAccountingFailure,
  validateOrdinaryDepositStore,
 )
import Cardano.Ledger.Dijkstra.Rules.DepositStore.Collateral (validateBatchCollateral)
import Cardano.Ledger.Dijkstra.Rules.DepositStore.Declaration
import Cardano.Ledger.Dijkstra.Rules.DepositStore.MinimumCoin (validateMinimumCoin)
import Cardano.Ledger.Rules.ValidationMode (Inject (inject), lblStatic, runTest)
import Cardano.Ledger.State (DepositFormula, UTxOStore, allocations, currentFormula)
import Control.State.Transition.Extended (Rule, validate, validateTrans, validateTransLabeled)
import Data.List.NonEmpty (NonEmpty ((:|)))
import Lens.Micro ((^.))

-- | Check a SubTx's own declaration and outputs. TopTx checks the signed
-- amount and the release destination when it validates the complete batch.
validateSubTx ::
  ( DijkstraEraTxBody era
  , Inject DepositStoreOutputDeclarationFailure (EraRuleFailure "SUBUTXO" era)
  , InjectRuleFailure "SUBUTXO" Babbage.BabbageUtxoPredFailure era
  ) =>
  DepositFormula -> IndexedUTxOs era -> TxBody SubTx era -> Rule (EraRule "SUBUTXO" era) ctx ()
validateSubTx formula originalAllocations body = do
  -- The signed body alone shows whether the child creates a deposit-backed
  -- output. Such an output requires a declaration even when the net is zero.
  validateTransLabeled inject (lblStatic :| []) $ validateSubTxAllocationDeclarationPresence body
  -- Resolve ordinary spending inputs as they stood before the first SubTx.
  -- Spending a deposit-backed input also requires the child's own declaration.
  validateTrans inject $ validateSubTxReleaseDeclarationPresence originalAllocations body
  -- Each new minimum-ADA output must carry the full minimum at the active price.
  runTest $ validateMinimumCoin formula body

-- | Check the ordinary proposal against the Store at the start of the batch,
-- even when phase 2 fails and only collateral effects will be applied.
validateTopTx ::
  ( AlonzoEraTx era
  , DijkstraEraTxBody era
  , Inject DepositStoreOutputDeclarationFailure (EraRuleFailure "UTXO" era)
  , Inject DepositStoreDeclarationFailure (EraRuleFailure "UTXO" era)
  , Inject DepositStoreAccountingFailure (EraRuleFailure "UTXO" era)
  , InjectRuleFailure "UTXO" Babbage.BabbageUtxoPredFailure era
  , InjectRuleFailure "UTXO" Alonzo.AlonzoUtxoPredFailure era
  ) =>
  PParams era -> UTxOStore era -> Tx TopTx era -> Rule (EraRule "UTXO" era) ctx ()
validateTopTx pp originalStore tx = do
  let body = tx ^. bodyTxL
  -- Creating a deposit-backed output in TopTx requires its own declaration.
  validateTransLabeled inject (lblStatic :| []) $ validateTopTxAllocationDeclarationPresence body
  -- A declaration in any child, including explicit zero, requires TopTx
  -- to declare the batch total. Both presence checks use only the signed body.
  validateTransLabeled inject (lblStatic :| []) $ validateTopTxNetUTxODepositDeclaration body
  -- Spending a deposit-backed input requires a declaration whatever its sign.
  -- The original allocations identify which of TopTx's ordinary inputs use that form.
  validateTrans inject $ validateTopTxReleaseDeclarationPresence (allocations originalStore) body
  -- Check each declared child's net and the batch total using active output backing
  -- minus historical input backing. A minimum-ADA input credits at most its own ADA.
  -- Each designated settlement output must cover its assigned release.
  validateTrans inject $ validateOrdinaryDepositStore originalStore body
  -- Redeemers in TopTx or any child trigger the batch's collateral funding check.
  validate $ validateBatchCollateral pp tx originalStore
  -- The active minimum also applies to a minimum-ADA collateral return.
  runTest $ validateMinimumCoin (currentFormula originalStore) body
