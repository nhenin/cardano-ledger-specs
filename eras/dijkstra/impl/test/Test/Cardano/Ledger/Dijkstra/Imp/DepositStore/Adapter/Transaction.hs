{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Transaction (
  declarationToTxBody,
  buildTxWithUTxODepositDeclarations,
  preparePhase2InvalidBatch,
  checkPreservedDeclarations,
  withPreservedDeclarations,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import Cardano.Ledger.Plutus (SLanguage (..), hashPlutusScript)
import Cardano.Ledger.TxIn (TxId (..), TxIn (..))
import Data.Foldable (toList)
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Core.Utils (mkDummySafeHash)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Fixture.DeclarationDependency as Fixture
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (shouldBe)
import Test.Cardano.Ledger.Plutus.Examples (alwaysFailsWithDatum)

-- | Convert a declarations fixture into a body for the declaration-only checker.
-- Distinct inputs prevent OMap from merging SubTxs. This does not claim financial validity.
declarationToTxBody :: Fixture.Declarations -> TxBody TopTx DijkstraEra
declarationToTxBody (Fixture.Declarations topDeclaration subDeclarations) =
  mkTopTxWithSubTxs (zipWith declarationOnlySubTx [0 ..] subDeclarations)
    ^. bodyTxL
    & netUTxODepositChangeTxBodyL .~ topDeclaration

declarationOnlySubTx :: Int -> SubTx.SubTxUTxODepositDeclaration -> Tx SubTx DijkstraEra
declarationOnlySubTx index =
  subTxWithDepositDeclaration (TxIn (TxId $ mkDummySafeHash index) (TxIx 0))

subTxWithDepositDeclaration :: TxIn -> SubTx.SubTxUTxODepositDeclaration -> Tx SubTx DijkstraEra
subTxWithDepositDeclaration input declaration =
  mkBasicTx $
    mkBasicTxBody
      & inputsTxBodyL .~ Set.singleton input
      & subTxNetUTxODepositChangeTxBodyL .~ declaration

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
  Fixture.Declarations ->
  ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildTxWithUTxODepositDeclarations (Fixture.Declarations topDeclaration subDeclarations) = do
  subTxs <- traverse fundedImplicitSubTx subDeclarations
  pure $ mkTopTxWithSubTxs subTxs & bodyTxL . netUTxODepositChangeTxBodyL .~ topDeclaration

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
        & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable balancedSubs
        & bodyTxL . inputsTxBodyL .~ Set.singleton failingInput
  checkPreservedDeclarations batch fixed
  pure $ fixed & isPhase2ValidTxL .~ Phase2Invalid

returnSubTxInputsToOutputs :: Tx SubTx DijkstraEra -> ImpTestM DijkstraEra (Tx SubTx DijkstraEra)
returnSubTxInputsToOutputs subTx = do
  outputs <- traverse impGetUTxO $ Set.toList (subTx ^. bodyTxL . inputsTxBodyL)
  pure $ subTx & bodyTxL . outputsTxBodyL .~ SSeq.fromList outputs

-- | Check the submitted shape after fixup, including the absence of Store activity.
withPreservedDeclarations ::
  Tx TopTx DijkstraEra -> ImpTestM DijkstraEra a -> ImpTestM DijkstraEra a
withPreservedDeclarations prepared = withPostFixup $ \submitted -> do
  checkPreservedDeclarations prepared submitted
  pure submitted

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

subTxDepositDeclaration :: Tx SubTx DijkstraEra -> SubTx.SubTxUTxODepositDeclaration
subTxDepositDeclaration tx = tx ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL

isImplicitOutput :: TxOut DijkstraEra -> Bool
isImplicitOutput (ImplicitDepositTxOut _) = True
isImplicitOutput (StoreBackedTxOut _) = False
