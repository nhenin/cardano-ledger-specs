{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Construct output-creation fixtures and execute them against the ledger.
-- Full-ledger acceptance is exercised only with implicit-deposit outputs.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.OutputCreation (
  ExpectedSubmission (..),
  topTxBody,
  subTxBody,
  topTxBodyWithNestedOutputs,
  topTxBodyWithCollateralReturn,
  topTxBodyWithReferenceAndCollateralInputs,
  outputCreationScenarios,
) where

import Cardano.Ledger.BaseTypes (StrictMaybe (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (
  DijkstraLedgerPredFailure,
  DijkstraSubUtxoPredFailure,
  DijkstraUtxoPredFailure,
 )
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Plutus (SLanguage (..), hashPlutusScript)
import Cardano.Ledger.Shelley.LedgerState (esLStateL, nesEsL)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (inject)
import Data.Foldable (toList)
import Data.List.NonEmpty (NonEmpty (..))
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Spec, forM_, it)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Fixture.OutputCreation as Fixture
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (shouldBe, withImpInit)
import Test.Cardano.Ledger.Plutus.Examples (alwaysFailsWithDatum)

data ExpectedSubmission
  = Accepted
  | RejectedTopTx (DijkstraUtxoPredFailure DijkstraEra)
  | RejectedSubTx (DijkstraSubUtxoPredFailure DijkstraEra)

-- | Bodies for isolated validators. An explicit declaration is not a claim that
-- its amount, funding, or settlement satisfies any other DepositStore rule.
topTxBody :: Fixture.CreatedOutputs -> TopTx.TopTxUTxODepositDeclaration -> TxBody TopTx DijkstraEra
topTxBody outputs declaration =
  mkBasicTxBody
    & outputsTxBodyL .~ SSeq.fromList (createdOutputs outputs)
    & netUTxODepositChangeTxBodyL .~ declaration

subTxBody :: Fixture.CreatedOutputs -> SubTx.SubTxUTxODepositDeclaration -> TxBody SubTx DijkstraEra
subTxBody outputs declaration =
  mkBasicTxBody
    & outputsTxBodyL .~ SSeq.fromList (createdOutputs outputs)
    & subTxNetUTxODepositChangeTxBodyL .~ declaration

topTxBodyWithNestedOutputs ::
  Fixture.CreatedOutputs -> Fixture.CreatedOutputs -> TxBody TopTx DijkstraEra
topTxBodyWithNestedOutputs ownOutputs nestedOutputs =
  topTxBody ownOutputs TopTx.NoUTxODepositDeclaration
    & subTransactionsTxBodyL
      .~ OMap.fromFoldable [mkBasicTx $ subTxBody nestedOutputs SubTx.DeclaresZeroNetUTxODeposit]

topTxBodyWithCollateralReturn :: Addr -> TxBody TopTx DijkstraEra
topTxBodyWithCollateralReturn address =
  mkBasicTxBody
    & collateralReturnTxBodyL .~ SJust (outputAtAddress address Fixture.StoreBackedOutput)

-- | Input identifiers alone are not created outputs. Resolution and the rules
-- governing spent, referenced, or collateral UTxOs remain separate work.
topTxBodyWithReferenceAndCollateralInputs :: TxIn -> TxBody TopTx DijkstraEra
topTxBodyWithReferenceAndCollateralInputs input =
  mkBasicTxBody
    & referenceInputsTxBodyL .~ Set.singleton input
    & collateralInputsTxBodyL .~ Set.singleton input

createdOutputs :: Fixture.CreatedOutputs -> [TxOut DijkstraEra]
createdOutputs (Fixture.CreatedOutputs address variants) = map (outputAtAddress address) variants

outputAtAddress :: Addr -> Fixture.OutputVariant -> TxOut DijkstraEra
outputAtAddress address Fixture.ImplicitOutput =
  mkBasicTxOutWithImplicitDeposit address $ inject (Coin 2_000_000)
outputAtAddress address Fixture.StoreBackedOutput =
  mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets mempty

-- | Register one fresh ledger test per row. Store-backed fixtures are submitted
-- only for rejection; fee and application-asset balancing does not fund a capacity
-- deposit. Accepted controls contain only implicit-deposit outputs.
outputCreationScenarios :: [(String, Fixture.TxOutputs, IsPhase2Valid, ExpectedSubmission)] -> Spec
outputCreationScenarios scenarios =
  withImpInit @(LedgerSpec DijkstraEra) $
    forM_ scenarios $ \(requirement, outputs, phase2, expected) ->
      it requirement $ do
        prepared <- buildTxWithCreatedOutputs outputs
        fixed <- case phase2 of
          Phase2Valid -> fixupTx prepared
          Phase2Invalid -> preparePhase2InvalidTx prepared
        checkPreservedCreationFixture (prepared & isPhase2ValidTxL .~ phase2) fixed
        case expected of
          Accepted -> withNoFixup $ submitTx_ fixed
          RejectedTopTx failure -> submitPreparedRejection (injectFailure failure) fixed
          RejectedSubTx failure -> submitPreparedRejection (injectFailure failure) fixed

buildTxWithCreatedOutputs :: Fixture.TxOutputs -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildTxWithCreatedOutputs (Fixture.TxOutputs declaration variants subBodies) = do
  address <- freshKeyAddrNoPtr_
  subTxs <- traverse buildSubTx subBodies
  pure $
    mkBasicTx (topTxBody (Fixture.CreatedOutputs address variants) declaration)
      & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable subTxs

-- | Add a real failing V4 script before fixup, retaining every supplied output.
-- V4 avoids the legacy balancing SubTx. Set the phase-2 result only after fixup;
-- the resulting transaction must be submitted without another fixup.
preparePhase2InvalidTx :: Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
preparePhase2InvalidTx prepared = do
  failingInput <- produceScript . hashPlutusScript $ alwaysFailsWithDatum SPlutusV4
  fixed <- fixupTx $ prepared & bodyTxL . inputsTxBodyL %~ Set.insert failingInput
  pure $ fixed & isPhase2ValidTxL .~ Phase2Invalid

buildSubTx ::
  (SubTx.SubTxUTxODepositDeclaration, [Fixture.OutputVariant]) ->
  ImpTestM DijkstraEra (Tx SubTx DijkstraEra)
buildSubTx (declaration, variants) = do
  address <- freshKeyAddrNoPtr_
  input <- sendCoinTo address $ Coin 2_000_000
  pure $
    mkBasicTx (subTxBody (Fixture.CreatedOutputs address variants) declaration)
      & bodyTxL . inputsTxBodyL .~ Set.singleton input

-- | Fixup may append implicit TopTx change, but must retain all supplied outputs
-- exactly, including their constructors, and each body's own declaration.
checkPreservedCreationFixture ::
  Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
checkPreservedCreationFixture prepared submitted = do
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

isImplicitOutput :: TxOut DijkstraEra -> Bool
isImplicitOutput (ImplicitDepositTxOut _) = True
isImplicitOutput (StoreBackedTxOut _) = False

-- | Snapshot after all fixture funding and fixup. A rejected batch must leave
-- the full ledger state unchanged, including its UTxO and accounting state.
submitPreparedRejection ::
  DijkstraLedgerPredFailure DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitPreparedRejection expectedFailure fixed = do
  before <- getsNES $ nesEsL . esLStateL
  withNoFixup $ submitFailingTx fixed (expectedFailure :| [])
  after <- getsNES $ nesEsL . esLStateL
  after `shouldBe` before
