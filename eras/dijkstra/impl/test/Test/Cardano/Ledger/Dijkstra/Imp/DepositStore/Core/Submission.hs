{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Prepare and submit specification transactions to the test ledger.
-- Preserve each fixture's declarations and outputs across fixup. Submission
-- returns the ledger outcome for the spec to check; legacy combined rejection
-- helpers additionally compare ledger state before and after submission.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  submitTx,
  isAccepted,
  isRejectedWith,
  isRejectedOnlyWith,
  removeTopTxDeclaration,
  buildTxWithUTxODepositDeclarations,
  preparePhase2InvalidBatch,
  buildTxWithCreatedOutputs,
  preparePhase2InvalidTx,
  submitTxAndExpectSuccess,
  submitTxAndExpectRejection,
  submitPreparedTxAndExpectAcceptance,
  submitPreparedTxAndExpectRejection,
  submitPreparedRejection,
  submitTxAndExpectFailureContaining,
  checkPreservedOutputsAndDeclarations,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (DijkstraLedgerPredFailure, DijkstraUtxoPredFailure)
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Plutus (SLanguage (..), hashPlutusScript)
import Cardano.Ledger.Shelley.LedgerState (esLStateL, nesEsL)
import Data.Bifunctor (first)
import Data.Foldable (toList)
import Data.List.NonEmpty (NonEmpty (..))
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (
  subTxWithDepositDeclaration,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration as Declaration
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (
  isImplicitOutput,
  subTxBody,
  topTxBody,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output as Output
import Test.Cardano.Ledger.Dijkstra.ImpTest hiding (submitTx)
import Test.Cardano.Ledger.Imp.Common (
  expectLeftDeepExpr,
  expectRightDeepExpr_,
  shouldBe,
  shouldContainExpr,
 )
import Test.Cardano.Ledger.Plutus.Examples (alwaysFailsWithDatum)

-- | Submit the signed transaction exactly as supplied, without further fixup.
-- Return the ledger's rejection reasons or accepted transaction for the spec to
-- check. Submission itself does not require either outcome.
submitTx ::
  Tx TopTx DijkstraEra ->
  ImpTestM
    DijkstraEra
    (Either (NonEmpty (DijkstraLedgerPredFailure DijkstraEra)) (Tx TopTx DijkstraEra))
submitTx tx = first fst <$> withNoFixup (trySubmitTx tx)

-- | Require acceptance of an already submitted transaction. On rejection, report
-- the ledger's predicate failures; this assertion never submits the transaction.
isAccepted ::
  Either (NonEmpty (DijkstraLedgerPredFailure DijkstraEra)) (Tx TopTx DijkstraEra) ->
  ImpTestM DijkstraEra ()
isAccepted = expectRightDeepExpr_

-- | Require rejection for the supplied rule failure. Other failures may accompany
-- it, for example when an absent declaration also breaks ADA conservation.
-- An accepted transaction or a rejection without this reason fails the assertion.
isRejectedWith ::
  InjectRuleFailure "LEDGER" failure DijkstraEra =>
  failure DijkstraEra ->
  Either (NonEmpty (DijkstraLedgerPredFailure DijkstraEra)) (Tx TopTx DijkstraEra) ->
  ImpTestM DijkstraEra ()
isRejectedWith expected outcome = do
  failures <- expectLeftDeepExpr outcome
  toList failures `shouldContainExpr` [injectFailure @"LEDGER" expected]

-- | Require this single failure, with no additional predicate failures. Use for
-- scenarios that deliberately violate one rule while preserving all other rules.
isRejectedOnlyWith ::
  InjectRuleFailure "LEDGER" failure DijkstraEra =>
  failure DijkstraEra ->
  Either (NonEmpty (DijkstraLedgerPredFailure DijkstraEra)) (Tx TopTx DijkstraEra) ->
  ImpTestM DijkstraEra ()
isRejectedOnlyWith expected outcome = do
  failures <- expectLeftDeepExpr outcome
  failures `shouldBe` (injectFailure @"LEDGER" expected :| [])

-- | Remove only TopTx's declaration and re-sign without balancing again.
-- Inputs, outputs, fees and child declarations remain those of the signed control.
removeTopTxDeclaration ::
  Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
removeTopTxDeclaration tx =
  rederiveAddrTxWits $ tx & bodyTxL . netUTxODepositChangeTxBodyL .~ TopTx.NoUTxODepositDeclaration

-- | Build a test transaction from a UTxO capacity deposit declarations fixture,
-- with funded inputs for each SubTx.
--
-- For each supplied SubTx declaration:
--
-- * Submit a funding transaction that creates an implicit-deposit output of
--   one ADA at a fresh address in the test ledger.
-- * Build a SubTx that spends that output, initially creates no outputs, and
--   carries exactly the supplied declaration, including absence or explicit zero.
--
-- Put these SubTxs inside a TopTx carrying the supplied TopTx declaration.
-- Distinct funding inputs keep SubTxs distinct even when their declarations match.
-- An empty declaration list produces a TopTx without SubTxs.
--
-- Funding transactions are submitted here; the returned transaction is not. The test's
-- submission helper still needs to prepare its change, fees and witnesses while
-- preserving the declarations. This function neither validates nor repairs them,
-- so the caller can construct a transaction that the ledger is expected to reject.
buildTxWithUTxODepositDeclarations ::
  Declaration.Declarations ->
  ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildTxWithUTxODepositDeclarations (Declaration.Declarations topDeclaration subDeclarations) = do
  subTxs <- traverse fundedImplicitSubTx subDeclarations
  pure $ mkTopTxWithSubTxs subTxs & bodyTxL . netUTxODepositChangeTxBodyL .~ topDeclaration

-- | Fund an implicit input at a fresh address while retaining the exact declaration.
fundedImplicitSubTx ::
  SubTx.SubTxUTxODepositDeclaration -> ImpTestM DijkstraEra (Tx SubTx DijkstraEra)
fundedImplicitSubTx declaration = do
  address <- freshKeyAddr_
  input <- sendCoinTo address (Coin 1_000_000)
  pure $ subTxWithDepositDeclaration input declaration

-- | Exercise the phase-2 failure path with a real failing TopTx script.
-- Return each SubTx's funded input value to itself so legacy Plutus fixup does
-- not add a balancing SubTx. The returned batch must be submitted without fixup.
preparePhase2InvalidBatch ::
  Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
preparePhase2InvalidBatch batch = do
  balancedSubs <-
    traverse returnSubTxInputsToOutputs $ OMap.elems (batch ^. bodyTxL . subTransactionsTxBodyL)
  failingInput <- produceScript . hashPlutusScript $ alwaysFailsWithDatum SPlutusV3
  fixed <-
    fixupTx $
      batch
        & bodyTxL
          . subTransactionsTxBodyL
          .~ OMap.fromFoldable balancedSubs
        & bodyTxL
          . inputsTxBodyL
          .~ Set.singleton failingInput
  checkPreservedDeclarations batch fixed
  pure $ fixed & isPhase2ValidTxL .~ Phase2Invalid

-- | Return each funded input's output value to the same SubTx for legacy phase-2 preparation.
returnSubTxInputsToOutputs :: Tx SubTx DijkstraEra -> ImpTestM DijkstraEra (Tx SubTx DijkstraEra)
returnSubTxInputsToOutputs subTx = do
  outputs <- traverse impGetUTxO $ Set.toList (subTx ^. bodyTxL . inputsTxBodyL)
  pure $ subTx & bodyTxL . outputsTxBodyL .~ SSeq.fromList outputs

-- | Build the supplied own outputs and declarations, funding each distinct SubTx input.
buildTxWithCreatedOutputs :: Output.TxOutputs -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildTxWithCreatedOutputs (Output.TxOutputs declaration variants subBodies) = do
  address <- freshKeyAddrNoPtr_
  subTxs <- traverse buildSubTx subBodies
  pure $
    mkBasicTx (topTxBody (Output.CreatedOutputs address variants) declaration)
      & bodyTxL
        . subTransactionsTxBodyL
        .~ OMap.fromFoldable subTxs

-- | Add a real failing V4 script before fixup, retaining every supplied output.
-- V4 avoids the legacy balancing SubTx. Set the phase-2 result only after fixup;
-- the resulting transaction must be submitted without another fixup.
preparePhase2InvalidTx :: Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
preparePhase2InvalidTx prepared = do
  failingInput <- produceScript . hashPlutusScript $ alwaysFailsWithDatum SPlutusV4
  fixed <- fixupTx $ prepared & bodyTxL . inputsTxBodyL %~ Set.insert failingInput
  pure $ fixed & isPhase2ValidTxL .~ Phase2Invalid

-- | Fund a fresh implicit input and retain the SubTx's declared output variants.
buildSubTx ::
  (SubTx.SubTxUTxODepositDeclaration, [Output.OutputVariant]) ->
  ImpTestM DijkstraEra (Tx SubTx DijkstraEra)
buildSubTx (declaration, variants) = do
  address <- freshKeyAddrNoPtr_
  input <- sendCoinTo address $ Coin 2_000_000
  pure $
    mkBasicTx (subTxBody (Output.CreatedOutputs address variants) declaration)
      & bodyTxL
        . inputsTxBodyL
        .~ Set.singleton input

-- | Prepare and submit a transaction, including any SubTxs it contains, to the test
-- ledger, requiring acceptance.
-- Check that preparation preserves the declarations and implicit-output fixture.
-- An accepted transaction updates the test ledger state.
submitTxAndExpectSuccess :: Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitTxAndExpectSuccess batch = withPreservedDeclarations batch $ submitTx_ batch

-- | Capture the state after fixture funding and fixup, immediately before the
-- submitted batch. Funding transactions are not part of the rejection assertion.
submitTxAndExpectRejection ::
  DijkstraUtxoPredFailure DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitTxAndExpectRejection expectedFailure batch = do
  fixed <- fixupTx batch
  checkPreservedDeclarations batch fixed
  submitPreparedTxAndExpectRejection expectedFailure fixed

-- | Use a finalized batch as supplied, including its declared phase-2 outcome.
submitPreparedTxAndExpectAcceptance :: Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitPreparedTxAndExpectAcceptance batch = withNoFixup $ submitTxAndExpectSuccess batch

-- | Require the exact rejection and unchanged ledger state after fixture preparation.
submitPreparedTxAndExpectRejection ::
  DijkstraUtxoPredFailure DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitPreparedTxAndExpectRejection expectedFailure batch = do
  before <- getsNES $ nesEsL . esLStateL
  withNoFixup $
    withPreservedDeclarations batch $
      submitFailingTx
        batch
        (injectFailure expectedFailure :| [])
  after <- getsNES $ nesEsL . esLStateL
  after `shouldBe` before

-- | Snapshot after all fixture funding and fixup. A rejected batch must leave
-- the full ledger state unchanged, including its UTxO and accounting state.
submitPreparedRejection ::
  DijkstraLedgerPredFailure DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitPreparedRejection expectedFailure fixed = do
  before <- getsNES $ nesEsL . esLStateL
  withNoFixup $ submitFailingTx fixed (expectedFailure :| [])
  after <- getsNES $ nesEsL . esLStateL
  after `shouldBe` before

-- | Removing or changing a declaration can also break ADA conservation. Require
-- the intended rule failure among the accumulated failures, and preserve the full
-- ledger state, including every Store allocation and its balance.
submitTxAndExpectFailureContaining ::
  DijkstraLedgerPredFailure DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitTxAndExpectFailureContaining expectedFailure fixed = do
  before <- getsNES $ nesEsL . esLStateL
  withNoFixup $ submitFailingSubsetTx fixed (expectedFailure :| [])
  after <- getsNES $ nesEsL . esLStateL
  after `shouldBe` before

-- | Check the submitted shape after fixup, including the absence of Store operations.
withPreservedDeclarations ::
  Tx TopTx DijkstraEra -> ImpTestM DijkstraEra a -> ImpTestM DijkstraEra a
withPreservedDeclarations prepared = withPostFixup $ \submitted -> do
  checkPreservedDeclarations prepared submitted
  pure submitted

-- | Check declarations, SubTx count, implicit-only outputs, and phase-2 outcome after fixup.
checkPreservedDeclarations ::
  Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
checkPreservedDeclarations prepared submitted = do
  let preparedSubs = OMap.elems $ prepared ^. bodyTxL . subTransactionsTxBodyL
      submittedSubs = OMap.elems $ submitted ^. bodyTxL . subTransactionsTxBodyL
      allOutputs =
        toList (submitted ^. bodyTxL . outputsTxBodyL)
          <> concatMap (toList . (^. bodyTxL . outputsTxBodyL)) submittedSubs
  submitted
    ^. bodyTxL
      . netUTxODepositChangeTxBodyL
      `shouldBe` (prepared ^. bodyTxL . netUTxODepositChangeTxBodyL)
  length submittedSubs `shouldBe` length preparedSubs
  fmap subTxDepositDeclaration submittedSubs `shouldBe` fmap subTxDepositDeclaration preparedSubs
  all isImplicitOutput allOutputs `shouldBe` True
  submitted ^. isPhase2ValidTxL `shouldBe` (prepared ^. isPhase2ValidTxL)

-- | Read the declaration belonging to the supplied SubTx.
subTxDepositDeclaration :: Tx SubTx DijkstraEra -> SubTx.SubTxUTxODepositDeclaration
subTxDepositDeclaration tx = tx ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL

-- | Fixup may append implicit TopTx change, but must retain every supplied output
-- and each body's own declaration, including its phase-2 outcome.
checkPreservedOutputsAndDeclarations ::
  Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
checkPreservedOutputsAndDeclarations prepared submitted = do
  let preparedOutputs = toList $ prepared ^. bodyTxL . outputsTxBodyL
      submittedOutputs = toList $ submitted ^. bodyTxL . outputsTxBodyL
      preparedSubs = OMap.elems $ prepared ^. bodyTxL . subTransactionsTxBodyL
      submittedSubs = OMap.elems $ submitted ^. bodyTxL . subTransactionsTxBodyL
  take (length preparedOutputs) submittedOutputs `shouldBe` preparedOutputs
  all isImplicitOutput (drop (length preparedOutputs) submittedOutputs) `shouldBe` True
  submitted
    ^. bodyTxL
      . netUTxODepositChangeTxBodyL
      `shouldBe` (prepared ^. bodyTxL . netUTxODepositChangeTxBodyL)
  length submittedSubs `shouldBe` length preparedSubs
  map (^. bodyTxL . outputsTxBodyL) submittedSubs
    `shouldBe` map (^. bodyTxL . outputsTxBodyL) preparedSubs
  map (^. bodyTxL . subTxNetUTxODepositChangeTxBodyL) submittedSubs
    `shouldBe` map (^. bodyTxL . subTxNetUTxODepositChangeTxBodyL) preparedSubs
  submitted ^. isPhase2ValidTxL `shouldBe` (prepared ^. isPhase2ValidTxL)
