{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableSuperClasses #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Cardano.Ledger.Dijkstra.UTxO (
  DijkstraEraUTxO (..),
  dijkstraConsumed,
  getDijkstraScriptsNeeded,
  getDijkstraScriptsProvided,
  getDijkstraSupplementalDataHashes,
  scriptsProvidedDijkstraStAnnTx,
  batchNonDistinctRefScriptsSize,
  localProducedValue,
) where

import Cardano.Ledger.Alonzo.Plutus.Context (CollectError)
import Cardano.Ledger.Alonzo.UTxO (
  AlonzoEraUTxO (..),
  AlonzoScriptsNeeded (..),
  getAlonzoScriptsHashesNeeded,
  zipAsIxItem,
 )
import Cardano.Ledger.Babbage.UTxO (
  getBabbageScriptsProvided,
  getBabbageSpendingDatum,
  getBabbageSupplementalDataHashes,
 )
import Cardano.Ledger.BaseTypes (inject)
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Conway.TxBody (conwayProposalsDeposits)
import Cardano.Ledger.Conway.UTxO (
  getConwayMinFeeTxUtxo,
  getConwayScriptsNeeded,
  getConwayWitsVKeyNeeded,
  txNonDistinctRefScriptsSize,
 )
import Cardano.Ledger.Credential (Credential, credScriptHash)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Era (DijkstraEra)
import Cardano.Ledger.Dijkstra.Rules.DepositStore.Accounting (declaredTopTxNetUTxODeposit)
import Cardano.Ledger.Dijkstra.Scripts (DijkstraEraScript (..))
import Cardano.Ledger.Dijkstra.State
import Cardano.Ledger.Dijkstra.Tx (DijkstraStAnnTx (..))
import Cardano.Ledger.Mary.UTxO (burnedMultiAssets, getConsumedMaryValue)
import Cardano.Ledger.Mary.Value (MaryValue (..))
import Cardano.Ledger.Plutus (Language, PlutusWithContext)
import Cardano.Ledger.TxOut (sumAllAssets)
import Data.Foldable (Foldable (..))
import Data.List.NonEmpty (NonEmpty)
import qualified Data.Map.Strict as Map
import Data.Maybe (catMaybes)
import Data.Monoid (Sum (..))
import qualified Data.OMap.Strict as OMap
import Data.Set (Set)
import Lens.Micro (SimpleGetter, to, (^.))
import Lens.Micro.Extras (view)

class AlonzoEraUTxO era => DijkstraEraUTxO era where
  subTransactionsStAnnTx :: StAnnTx TopTx era -> [StAnnTx SubTx era]
  plutusLegacyModeStAnnTxG :: SimpleGetter (StAnnTx TopTx era) Bool
  scriptsHashesNeededStAnnTx :: StAnnTx SubTx era -> Set ScriptHash

-- | Unlike `shelleyConsumed`, this function does not need access to `Accounts` to produce accurate
-- information about refunds, hence is this simplification. Note that using `shelleyConsumed` in
-- Dijkstra era onwards will produce the same result as this one.
dijkstraConsumed ::
  EraUTxO era =>
  PParams era ->
  Allocations era ->
  TxBody l era ->
  Value era
dijkstraConsumed pp = getConsumedValue pp (const Nothing)

getConsumedDijkstraValue ::
  forall era l.
  ( DijkstraEraTxBody era
  , EraUTxO era
  , Value era ~ MaryValue
  , STxLevel l era ~ STxBothLevels l era
  ) =>
  PParams era ->
  (Credential Staking -> Maybe Coin) ->
  Allocations era ->
  TxBody l era ->
  Value era
getConsumedDijkstraValue pp lookupStakingDeposit inputAllocations txBody =
  withBothTxLevels
    txBody
    ( \topTxBody ->
        txBodyConsumedValue topTxBody
          <> subTransactionsConsumedValue topTxBody
          <> inject (declaredDepositRelease topTxBody)
    )
    txBodyConsumedValue
  where
    txBodyConsumedValue :: forall m. TxBody m era -> Value era
    txBodyConsumedValue = getConsumedMaryValue pp lookupStakingDeposit inputAllocations
    subTransactionsConsumedValue topTxBody =
      foldMap'
        (getConsumedValue pp lookupStakingDeposit inputAllocations . view bodyTxL)
        (topTxBody ^. subTransactionsTxBodyL)

dijkstraProducedValue ::
  forall era.
  ( DijkstraEraTxBody era
  , EraUTxO era
  , Value era ~ MaryValue
  ) =>
  PParams era ->
  (KeyHash StakePool -> Bool) ->
  TxBody TopTx era ->
  MaryValue
dijkstraProducedValue pp isRegPoolId topTxBody =
  localProducedValue pp topTxBody
    <> foldMap' (localProducedValue pp . (^. bodyTxL)) subTxs
    <> inject (topTxBody ^. feeTxBodyL)
    <> inject (getTotalDepositsTxCerts pp isRegPoolId batchTxCerts)
    <> inject (declaredDepositAllocation topTxBody)
  where
    -- add all values that are produced by both top and sub-transactions
    -- Certs are excluded, since they need to be processed separately
    -- while maintaining the state through all of the certs of a transactions.
    batchTxCerts =
      foldMap' (^. bodyTxL . certsTxBodyL) subTxs
        <> (topTxBody ^. certsTxBodyL)
    subTxs = topTxBody ^. subTransactionsTxBodyL

-- | A batch releases Store ADA once, through TopTx's total declaration.
-- Exactness is validated independently against the recorded input deposits.
declaredDepositRelease :: DijkstraEraTxBody era => TxBody TopTx era -> Coin
declaredDepositRelease txBody =
  case declaredTopTxNetUTxODeposit (txBody ^. netUTxODepositChangeTxBodyL) of
    Coin amount -> Coin $ max 0 (negate amount)

-- | The batch's net allocation is produced into the Store, not into a TxOut.
declaredDepositAllocation :: DijkstraEraTxBody era => TxBody TopTx era -> Coin
declaredDepositAllocation txBody =
  case declaredTopTxNetUTxODeposit (txBody ^. netUTxODepositChangeTxBodyL) of
    Coin amount -> Coin $ max 0 amount

-- | Produced value that is local to a single transaction body, that is, the part
-- that can be summed independently for each body in a batch.
-- Excludes fees and certificate deposits, which are accounted for once per
-- batch.
localProducedValue ::
  ( DijkstraEraTxBody era
  , Value era ~ MaryValue
  ) =>
  PParams era ->
  TxBody l era ->
  MaryValue
localProducedValue pp txBody =
  unAssets (sumAllAssets (txBody ^. outputsTxBodyL))
    <> inject (txBody ^. treasuryDonationTxBodyL)
    <> inject (conwayProposalsDeposits pp txBody)
    <> burnedMultiAssets txBody
    <> inject (fold (unDirectDeposits (txBody ^. directDepositsTxBodyL)))

instance EraUTxO DijkstraEra where
  type ScriptsNeeded DijkstraEra = AlonzoScriptsNeeded DijkstraEra

  getConsumedValue = getConsumedDijkstraValue

  getProducedValue = dijkstraProducedValue

  getScriptsProvided = getDijkstraScriptsProvided

  getScriptsNeeded = getDijkstraScriptsNeeded

  getScriptsHashesNeeded = getAlonzoScriptsHashesNeeded

  getWitsVKeyNeeded _ = getConwayWitsVKeyNeeded

  getMinFeeTxUtxo = getConwayMinFeeTxUtxo

-- | Like 'getBabbageScriptsProvided', but for 'TopTx' also aggregates
-- scripts from all subtransactions.
getDijkstraScriptsProvided ::
  ( EraTx era
  , DijkstraEraTxBody era
  , STxLevel l era ~ STxBothLevels l era
  ) =>
  Allocations era ->
  Tx l era ->
  ScriptsProvided era
getDijkstraScriptsProvided inputAllocations tx =
  withBothTxLevels
    tx
    ( \topTx ->
        ScriptsProvided $
          Map.unions $
            unScriptsProvided (getBabbageScriptsProvided inputAllocations topTx)
              : [ unScriptsProvided (getBabbageScriptsProvided inputAllocations subTx)
                | subTx <- OMap.elems (topTx ^. bodyTxL . subTransactionsTxBodyL)
                ]
    )
    (getBabbageScriptsProvided inputAllocations)

getDijkstraScriptsNeeded ::
  (DijkstraEraTxBody era, DijkstraEraScript era) =>
  Allocations era -> TxBody l era -> AlonzoScriptsNeeded era
getDijkstraScriptsNeeded inputAllocations txb =
  getConwayScriptsNeeded inputAllocations txb
    <> guardingScriptsNeeded
  where
    guardingScriptsNeeded = AlonzoScriptsNeeded $
      catMaybes $
        zipAsIxItem (txb ^. guardsTxBodyL) $
          \(AsIxItem idx cred) -> (\sh -> (GuardingPurpose (AsIxItem idx sh), sh)) <$> credScriptHash cred

instance AlonzoEraUTxO DijkstraEra where
  getSupplementalDataHashes = getDijkstraSupplementalDataHashes

  getSpendingDatum = getBabbageSpendingDatum

  scriptsProvidedStAnnTx = scriptsProvidedDijkstraStAnnTx

  scriptsNeededStAnnTx = scriptsNeededDijkstraStAnnTx

  plutusScriptsWithContextStAnnTx = plutusScriptsWithContextDijkstraStAnnTx

  plutusLanguagesUsedStAnnTx = plutusLanguagesUsedDijkstraStAnnTx

getDijkstraSupplementalDataHashes ::
  ( EraTx era
  , DijkstraEraTxBody era
  , STxLevel l era ~ STxBothLevels l era
  ) =>
  Allocations era ->
  TxBody l era ->
  Set DataHash
getDijkstraSupplementalDataHashes inputAllocations txBody =
  withBothTxLevels
    txBody
    ( \topTxBody ->
        getBabbageSupplementalDataHashes inputAllocations topTxBody
          <> foldMap'
            (getBabbageSupplementalDataHashes inputAllocations . view bodyTxL)
            (topTxBody ^. subTransactionsTxBodyL)
    )
    (getBabbageSupplementalDataHashes inputAllocations)

scriptsProvidedDijkstraStAnnTx ::
  ( EraTxLevel era
  , STxLevel l era ~ STxBothLevels l era
  , STxLevel SubTx era ~ STxBothLevels SubTx era
  , STxLevel TopTx era ~ STxBothLevels TopTx era
  ) =>
  DijkstraStAnnTx l era -> ScriptsProvided era
scriptsProvidedDijkstraStAnnTx stAnnTx =
  withBothTxLevels
    stAnnTx
    (\DijkstraStAnnTopTx {dsattScriptsProvided} -> dsattScriptsProvided)
    (\DijkstraStAnnSubTx {dsastScriptsProvided} -> dsastScriptsProvided)

scriptsNeededDijkstraStAnnTx ::
  ( EraTxLevel era
  , STxLevel l era ~ STxBothLevels l era
  , STxLevel SubTx era ~ STxBothLevels SubTx era
  , STxLevel TopTx era ~ STxBothLevels TopTx era
  ) =>
  DijkstraStAnnTx l era -> ScriptsNeeded era
scriptsNeededDijkstraStAnnTx stAnnTx =
  withBothTxLevels
    stAnnTx
    (\DijkstraStAnnTopTx {dsattScriptsNeeded} -> dsattScriptsNeeded)
    (\DijkstraStAnnSubTx {dsastScriptsNeeded} -> dsastScriptsNeeded)

plutusScriptsWithContextDijkstraStAnnTx ::
  ( EraTxLevel era
  , STxLevel l era ~ STxBothLevels l era
  , STxLevel SubTx era ~ STxBothLevels SubTx era
  , STxLevel TopTx era ~ STxBothLevels TopTx era
  ) =>
  DijkstraStAnnTx l era ->
  Either (NonEmpty (CollectError era)) [PlutusWithContext]
plutusScriptsWithContextDijkstraStAnnTx stAnnTx =
  withBothTxLevels
    stAnnTx
    (\DijkstraStAnnTopTx {dsattPlutusScriptsWithContext} -> dsattPlutusScriptsWithContext)
    (\DijkstraStAnnSubTx {dsastPlutusScriptsWithContext} -> dsastPlutusScriptsWithContext)

plutusLanguagesUsedDijkstraStAnnTx ::
  ( EraTxLevel era
  , STxLevel l era ~ STxBothLevels l era
  , STxLevel SubTx era ~ STxBothLevels SubTx era
  , STxLevel TopTx era ~ STxBothLevels TopTx era
  ) =>
  DijkstraStAnnTx l era -> Set Language
plutusLanguagesUsedDijkstraStAnnTx stAnnTx =
  withBothTxLevels
    stAnnTx
    (\DijkstraStAnnTopTx {dsattPlutusLanguagesUsed} -> dsattPlutusLanguagesUsed)
    (\DijkstraStAnnSubTx {dsastPlutusLanguagesUsed} -> dsastPlutusLanguagesUsed)

instance DijkstraEraUTxO DijkstraEra where
  subTransactionsStAnnTx = subTransactionsDijkstraStAnnTx
  plutusLegacyModeStAnnTxG = to (\DijkstraStAnnTopTx {dsattPlutusLegacyMode} -> dsattPlutusLegacyMode)
  scriptsHashesNeededStAnnTx = dsastScriptsHashesNeeded

subTransactionsDijkstraStAnnTx ::
  DijkstraStAnnTx TopTx era -> [DijkstraStAnnTx SubTx era]
subTransactionsDijkstraStAnnTx DijkstraStAnnTopTx {dsattSubTransactions} = dsattSubTransactions

-- | Total size of reference scripts across a top-level transaction and all its subtransactions.
batchNonDistinctRefScriptsSize ::
  ( EraTx era
  , DijkstraEraTxBody era
  ) =>
  Allocations era ->
  Tx TopTx era ->
  Int
batchNonDistinctRefScriptsSize inputAllocations tx =
  txNonDistinctRefScriptsSize inputAllocations tx
    + getSum
      ( foldMap'
          (Sum . txNonDistinctRefScriptsSize inputAllocations)
          (tx ^. bodyTxL . subTransactionsTxBodyL)
      )
