{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

-- | Construct creation-presence inputs and prepare output-preserving ledger transactions.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Transaction (
  topTxBody,
  subTxBody,
  topTxBodyWithNestedOutputs,
  topTxBodyWithCollateralReturn,
  topTxBodyWithReferenceAndCollateralInputs,
  buildTxWithCreatedOutputs,
  preparePhase2InvalidTx,
) where

import Cardano.Ledger.BaseTypes (StrictMaybe (..))
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Plutus (SLanguage (..), hashPlutusScript)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (inject)
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Tx.Presence.Creation.Fixture as Fixture
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Plutus.Examples (alwaysFailsWithDatum)

-- | Construct a TopTx's own outputs and declaration for an isolated presence check.
topTxBody :: Fixture.CreatedOutputs -> TopTx.TopTxUTxODepositDeclaration -> TxBody TopTx DijkstraEra
topTxBody outputs declaration =
  mkBasicTxBody
    & outputsTxBodyL
      .~ SSeq.fromList (createdOutputs outputs)
    & netUTxODepositChangeTxBodyL
      .~ declaration

-- | Construct a SubTx's own outputs and declaration without claiming financial validity.
subTxBody :: Fixture.CreatedOutputs -> SubTx.SubTxUTxODepositDeclaration -> TxBody SubTx DijkstraEra
subTxBody outputs declaration =
  mkBasicTxBody
    & outputsTxBodyL
      .~ SSeq.fromList (createdOutputs outputs)
    & subTxNetUTxODepositChangeTxBodyL
      .~ declaration

-- | Keep TopTx's own outputs distinct from the explicitly declared nested SubTx outputs.
topTxBodyWithNestedOutputs ::
  Fixture.CreatedOutputs -> Fixture.CreatedOutputs -> TxBody TopTx DijkstraEra
topTxBodyWithNestedOutputs ownOutputs nestedOutputs =
  topTxBody ownOutputs TopTx.NoUTxODepositDeclaration
    & subTransactionsTxBodyL
      .~ OMap.fromFoldable [mkBasicTx $ subTxBody nestedOutputs SubTx.DeclaresZeroNetUTxODeposit]

-- | Place a store-backed output only in collateral return, outside ordinary created outputs.
topTxBodyWithCollateralReturn :: Addr -> TxBody TopTx DijkstraEra
topTxBodyWithCollateralReturn address =
  mkBasicTxBody
    & collateralReturnTxBodyL
      .~ SJust (outputAtAddress address Fixture.StoreBackedOutput)

-- | Input identifiers alone are not created outputs. Resolution and the rules
-- governing spent, referenced, or collateral UTxOs remain separate work.
topTxBodyWithReferenceAndCollateralInputs :: TxIn -> TxBody TopTx DijkstraEra
topTxBodyWithReferenceAndCollateralInputs input =
  mkBasicTxBody
    & referenceInputsTxBodyL
      .~ Set.singleton input
    & collateralInputsTxBodyL
      .~ Set.singleton input

-- | Interpret the fixture's ordered output variants at its supplied address.
createdOutputs :: Fixture.CreatedOutputs -> [TxOut DijkstraEra]
createdOutputs (Fixture.CreatedOutputs address variants) = map (outputAtAddress address) variants

-- | Give implicit outputs ordinary ADA; store-backed outputs carry empty application assets.
outputAtAddress :: Addr -> Fixture.OutputVariant -> TxOut DijkstraEra
outputAtAddress address Fixture.ImplicitOutput =
  mkBasicTxOutWithImplicitDeposit address $ inject (Coin 2_000_000)
outputAtAddress address Fixture.StoreBackedOutput =
  mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets mempty

-- | Build the supplied own outputs and declarations, funding each distinct SubTx input.
buildTxWithCreatedOutputs :: Fixture.TxOutputs -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildTxWithCreatedOutputs (Fixture.TxOutputs declaration variants subBodies) = do
  address <- freshKeyAddrNoPtr_
  subTxs <- traverse buildSubTx subBodies
  pure $
    mkBasicTx (topTxBody (Fixture.CreatedOutputs address variants) declaration)
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
  (SubTx.SubTxUTxODepositDeclaration, [Fixture.OutputVariant]) ->
  ImpTestM DijkstraEra (Tx SubTx DijkstraEra)
buildSubTx (declaration, variants) = do
  address <- freshKeyAddrNoPtr_
  input <- sendCoinTo address $ Coin 2_000_000
  pure $
    mkBasicTx (subTxBody (Fixture.CreatedOutputs address variants) declaration)
      & bodyTxL
        . inputsTxBodyL
        .~ Set.singleton input
