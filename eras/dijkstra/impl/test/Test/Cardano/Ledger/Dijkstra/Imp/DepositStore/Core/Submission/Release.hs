{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Real funded Store allocations and transaction submission for release rules.
-- All source outputs and their deposits are established by ordinary transactions.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Release (
  ReleaseBody (..),
  ReleaseFixture (..),
  SignedReleaseTx (..),
  forAllStandaloneReleaseTx,
  forAllReferenceOnlyStoreTx,
  buildAndSignCollateralOnlyTx,
  forAllStandaloneZeroNetChangeTx,
  forAllSingleSubTxReleaseTx,
  forAllSubTxReleaseTx,
  forAllSubTxZeroNetChangeTx,
  buildAndSignTx,
  buildAndSignPhase2InvalidTx,
  buildAndSignStandaloneReleaseTx,
  preparePhase2InvalidSingleBodyRelease,
  readLedger,
  submitTx,
  isAccepted,
  isRejectedWith,
  fundSubTxReleaseScenario,
  removeSubTxReleaseDeclarationByInput,
  removeTopTxReleaseDeclaration,
  ordinarySpendingInputs,
  createdOrdinaryOutputs,
  buildTxSpendingStoreBackedOutput,
  fundReleaseScenario,
  checkPreservedReleaseFixture,
  ordinaryOutputInput,
  removeReleaseDeclaration,
  preparePhase2InvalidReleaseTx,
  submitTxAndExpectSuccess,
  submitTxAndExpectFailureContaining,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Plutus (SLanguage (..), hashPlutusScript)
import Cardano.Ledger.Shelley.LedgerState (
  UTxOState,
  curPParamsEpochStateL,
  esLStateL,
  lsUTxOStateL,
  nesEsL,
  utxosUtxo,
 )
import Cardano.Ledger.State (DepositStore (..), UTxO (..), depositStoreBalance)
import Cardano.Ledger.StrictlyPositiveCoin (StrictlyPositiveCoin, mkStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (Val ((<->)), inject)
import Data.Foldable (toList)
import qualified Data.Map.Strict as Map
import Data.Maybe (listToMaybe, maybeToList)
import Data.Maybe.Strict (StrictMaybe (..))
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, Property, forAll)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (recordedDepositStore)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (
  Declarations (..),
  subTxWithDepositDeclaration,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (isImplicitOutput)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release (
  createdOrdinaryOutputs,
  ordinarySpendingInputs,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release as Release
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as Children
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Standalone
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as Context
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  checkPreservedOutputsAndDeclarations,
  isAccepted,
  isRejectedWith,
  preparePhase2InvalidTx,
  removeTopTxDeclaration,
  submitTx,
  submitTxAndExpectFailureContaining,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest hiding (submitTx)
import qualified Test.Cardano.Ledger.Dijkstra.ImpTest as ImpTest
import Test.Cardano.Ledger.Imp.Common (
  expectJust,
  forM_,
  shouldBe,
 )
import Test.Cardano.Ledger.Plutus.Examples (alwaysFailsWithDatum, alwaysSucceedsWithDatum)

-- | Quantify over standalone scenarios, funding their sources on the real ledger
-- inside each isolated generated case. Give the spec the resulting context and an
-- undeclared release proposal; the callback supplies the declaration to test.
forAllStandaloneReleaseTx ::
  Gen Standalone.ReleaseScenario ->
  (Context.ReleaseTx -> ImpTestM DijkstraEra ()) ->
  Property
forAllStandaloneReleaseTx scenarios check =
  forAll scenarios $ \scenario -> do
    (ledgerState, unsignedTx) <- fundReleaseScenario scenario
    check $ Context.ReleaseTx ledgerState unsignedTx

-- | Fund a standalone scenario with equal positive allocations and releases.
-- Verify its premise before the spec supplies a declaration: priced allocations equal the
-- positive deposits recorded for consumed inputs. The sources are already funded;
-- the proposal has not been submitted.
forAllStandaloneZeroNetChangeTx ::
  Gen Standalone.ReleaseScenario ->
  (Context.ReleaseTx -> ImpTestM DijkstraEra ()) ->
  Property
forAllStandaloneZeroNetChangeTx scenarios check =
  forAllStandaloneReleaseTx scenarios $ \proposal -> do
    Context.allocatedDeposits proposal `shouldBe` Context.releasedDeposits proposal
    _ <- expectJust $ mkStrictlyPositiveCoin $ Context.releasedDeposits proposal
    check proposal

-- | Fund one source and its unrelated allocations inside each isolated generated
-- case. Give the spec the actual positive deposit and an undeclared parent with
-- one undeclared child, whose implicit output contains application ADA plus that
-- deposit. The callback supplies declarations before signing or submission.
forAllSingleSubTxReleaseTx ::
  Gen Children.SingleSourceScenario ->
  (StrictlyPositiveCoin -> Context.ReleaseTx -> ImpTestM DijkstraEra ()) ->
  Property
forAllSingleSubTxReleaseTx scenarios check =
  forAll scenarios $ \scenario -> do
    (ledgerState, sourceTx) <-
      fundReleaseScenario $
        Standalone.ReleaseScenario
          [Children.inputApplicationCoins scenario]
          (Children.unrelatedApplicationCoins scenario)
          Standalone.ImplicitOutputs
          []
    input <- expectJust $ Set.lookupMin (sourceTx ^. bodyTxL . inputsTxBodyL)
    recordedDeposit <-
      expectJust $ mkStrictlyPositiveCoin $ Standalone.releasedDeposits ledgerState sourceTx
    let subTx =
          subTxWithDepositDeclaration input SubTx.NoUTxODepositDeclaration
            & bodyTxL . outputsTxBodyL .~ (sourceTx ^. bodyTxL . outputsTxBodyL)
        proposal =
          mkTopTxWithSubTxs [subTx]
            & bodyTxL . netUTxODepositChangeTxBodyL .~ TopTx.NoUTxODepositDeclaration
    check recordedDeposit $ Context.ReleaseTx ledgerState proposal

-- | Fund every generated source and preserve child order, including implicit
-- sources and equal recorded amounts. TopTx and all SubTxs omit their declarations;
-- the spec supplies the operations and settlement targets before signing.
forAllSubTxReleaseTx ::
  Gen Children.ReleaseScenario ->
  (Context.ReleaseTx -> ImpTestM DijkstraEra ()) ->
  Property
forAllSubTxReleaseTx scenarios check =
  forAll scenarios $ \scenario -> fundSubTxReleaseScenario scenario >>= check

-- | Fund one or several SubTx sources, then recreate each body's exact source
-- outputs so its application ADA and output size stay unchanged. Verify equal
-- positive priced allocations and recorded releases independently for every
-- store-backed body, and zero allocations/releases for every implicit-only body.
-- TopTx and all children remain undeclared for the calling specification.
forAllSubTxZeroNetChangeTx ::
  Gen Children.ReleaseScenario ->
  (Context.ReleaseTx -> ImpTestM DijkstraEra ()) ->
  Property
forAllSubTxZeroNetChangeTx scenarios check =
  forAll scenarios $ \scenario -> do
    funded <- fundSubTxReleaseScenario scenario
    let ledgerState = Context.ledgerState funded
        tx = Context.unsignedTx funded
        children = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
    recreatedTopTx <- recreateFundedInputs ledgerState tx
    recreatedChildren <- traverse (recreateFundedInputs ledgerState) children
    let proposal =
          Context.ReleaseTx ledgerState $
            recreatedTopTx
              & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable recreatedChildren
        topAllocation = Standalone.allocatedDeposits ledgerState recreatedTopTx
        topRelease = Standalone.releasedDeposits ledgerState recreatedTopTx
        childOperations =
          zip3
            (Children.subTxSources scenario)
            (Children.allocatedDeposits proposal)
            (Children.releasedDeposits proposal)
    Children.count (Context.unsignedTx proposal) `shouldBe` length children
    topAllocation `shouldBe` topRelease
    case Children.topTxSource scenario of
      Nothing -> (topAllocation, topRelease) `shouldBe` (Coin 0, Coin 0)
      Just _ -> do
        _ <- expectJust $ mkStrictlyPositiveCoin topRelease
        pure ()
    forM_ childOperations $ \(source, allocated, released) -> do
      allocated `shouldBe` released
      case source of
        Children.StoreBackedSource _ -> do
          _ <- expectJust $ mkStrictlyPositiveCoin released
          pure ()
        Children.ImplicitSource _ -> (allocated, released) `shouldBe` (Coin 0, Coin 0)
    check proposal

-- | Recreate the body's own funded inputs as its ordinary outputs. Read the exact
-- TxOuts from the captured ledger, preserving application assets, address and
-- deposit form, while leaving inputs and declarations untouched.
recreateFundedInputs ::
  Standalone.LedgerState -> Tx l DijkstraEra -> ImpTestM DijkstraEra (Tx l DijkstraEra)
recreateFundedInputs ledgerState tx = do
  let sourceOutputs = unUTxO $ utxosUtxo $ Standalone.utxoState ledgerState
  outputs <-
    traverse (expectJust . (`Map.lookup` sourceOutputs)) $
      Set.toList (tx ^. bodyTxL . inputsTxBodyL)
  pure $ tx & bodyTxL . outputsTxBodyL .~ SSeq.fromList outputs

-- | Build fees and witnesses for the context's proposal without supplying or
-- repairing any declaration. Preserve each body's funded inputs and outputs.
buildAndSignTx :: Context.ReleaseTx -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignTx context =
  buildAndSignReleaseTx (Context.ledgerState context) (Context.unsignedTx context)

-- | Add a genuinely failing script and fresh implicit collateral, then finalize
-- fees and witnesses. Preserve the spec's declarations, ordinary source ownership
-- and outputs; the signed transaction explicitly declares phase 2 invalid.
buildAndSignPhase2InvalidTx ::
  Context.ReleaseTx -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignPhase2InvalidTx context = do
  signed <- preparePhase2InvalidReleaseTx $ Context.unsignedTx context
  checkPreservedReleaseProposal
    (Context.ledgerState context)
    (Context.unsignedTx context & isPhase2ValidTxL .~ Phase2Invalid)
    signed
  pure signed

-- | Establish generated inputs through a real funding transaction. Unrelated
-- allocations remain live. Return the actual ledger snapshot and an unsigned
-- proposal whose declaration is supplied visibly by the calling specification.
fundReleaseScenario ::
  Standalone.ReleaseScenario ->
  ImpTestM DijkstraEra (Standalone.LedgerState, Tx TopTx DijkstraEra)
fundReleaseScenario scenario = do
  modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 4_310)
  address <- freshKeyAddrNoPtr_
  pp <- getsNES $ nesEsL . curPParamsEpochStateL
  let outputs = Standalone.sourceOutputs address scenario
      allocation = foldMap (Standalone.outputDeposit pp) outputs
      fundingTx =
        Standalone.declareNetDeposit allocation $
          mkBasicTx mkBasicTxBody & bodyTxL . outputsTxBodyL .~ SSeq.fromList outputs
  before <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
  funded <- ImpTest.submitTx fundingTx
  after <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
  let fundingAllocations =
        Map.fromList
          [(txInAt index funded, Standalone.outputDeposit pp output) | (index, output) <- zip [0 ..] outputs]
      inputs =
        Set.fromList
          [txInAt index funded | index <- [0 .. length (Standalone.consumedApplicationAmounts scenario) - 1]]
      ledgerState = Standalone.LedgerState after pp
      spending = mkBasicTx mkBasicTxBody & bodyTxL . inputsTxBodyL .~ inputs
      released = Standalone.releasedDeposits ledgerState spending
      created = Standalone.createdOutputs address scenario released
  depositStoreBalance (recordedDepositStore after)
    `shouldBe` depositStoreBalance (recordedDepositStore before)
    <> allocation
  depositStoreAllocations (recordedDepositStore after)
    `shouldBe` Map.union fundingAllocations (depositStoreAllocations $ recordedDepositStore before)
  pure (ledgerState, spending & bodyTxL . outputsTxBodyL .~ SSeq.fromList created)

-- | Build and sign a standalone proposal without submitting it. Preserve its inputs,
-- declaration and supplied outputs while allowing implicit fee funding and change.
-- Recorded source deposits must remain unchanged; added inputs cannot release deposits.
-- Return the signed transaction without submitting it.
buildAndSignStandaloneReleaseTx ::
  Standalone.LedgerState ->
  Tx TopTx DijkstraEra ->
  ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignStandaloneReleaseTx ledgerState tx = do
  fixed <- buildAndSignReleaseTx ledgerState tx
  length (fixed ^. bodyTxL . subTransactionsTxBodyL) `shouldBe` 0
  pure fixed

-- | Preserve every body's original input ownership, declaration and outputs while
-- building fees and witnesses. Added ordinary inputs must be implicit; the live
-- source outputs and their recorded deposits must still match the funded context.
buildAndSignReleaseTx ::
  Standalone.LedgerState ->
  Tx TopTx DijkstraEra ->
  ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignReleaseTx ledgerState tx = do
  fixed <- fixupTx tx
  checkPreservedReleaseProposal ledgerState tx fixed
  pure fixed

-- | Keep the declared proposal intact through ordinary or phase-2 preparation.
-- Added implicit TopTx inputs may fund fees or supply the failing script. Each
-- SubTx retains its own inputs, and no original ordinary input becomes collateral.
-- The caller specifies the expected phase-2 flag in the original proposal.
checkPreservedReleaseProposal ::
  Standalone.LedgerState ->
  Tx TopTx DijkstraEra ->
  Tx TopTx DijkstraEra ->
  ImpTestM DijkstraEra ()
checkPreservedReleaseProposal ledgerState tx fixed = do
  checkPreservedOutputsAndDeclarations tx fixed
  fixed ^. bodyTxL . referenceInputsTxBodyL `shouldBe` (tx ^. bodyTxL . referenceInputsTxBodyL)
  let suppliedInputs = ordinarySpendingInputs tx
      suppliedBodyInputs =
        (tx ^. bodyTxL . inputsTxBodyL)
          : map (^. bodyTxL . inputsTxBodyL) (toList $ tx ^. bodyTxL . subTransactionsTxBodyL)
      fixedBodyInputs =
        (fixed ^. bodyTxL . inputsTxBodyL)
          : map (^. bodyTxL . inputsTxBodyL) (toList $ fixed ^. bodyTxL . subTransactionsTxBodyL)
  forM_ (zip suppliedBodyInputs fixedBodyInputs) $ \(expectedInputs, actualInputs) ->
    Set.intersection actualInputs suppliedInputs `shouldBe` expectedInputs
  drop 1 fixedBodyInputs `shouldBe` drop 1 suppliedBodyInputs
  Set.intersection suppliedInputs (fixed ^. bodyTxL . collateralInputsTxBodyL)
    `shouldBe` Set.empty
  checkAddedOrdinaryInputsUseImplicitDeposits tx fixed
  currentUTxOState <- readLedger
  Map.restrictKeys (unUTxO $ utxosUtxo currentUTxOState) suppliedInputs
    `shouldBe` Map.restrictKeys (unUTxO $ utxosUtxo $ Standalone.utxoState ledgerState) suppliedInputs
  Map.restrictKeys (depositStoreAllocations $ recordedDepositStore currentUTxOState) suppliedInputs
    `shouldBe` Map.restrictKeys
      (depositStoreAllocations $ recordedDepositStore $ Standalone.utxoState ledgerState)
      suppliedInputs

-- | Submit the declared transaction through the real ledger. Preparation may add
-- implicit fee funding and change, but preserves the supplied outputs/declaration.
-- Acceptance must consume exactly the recorded input allocations and create the
-- independently priced output records while retaining every unrelated allocation.
submitTxAndExpectSuccess ::
  Standalone.LedgerState -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitTxAndExpectSuccess ledgerState tx = do
  fixed <- buildAndSignStandaloneReleaseTx ledgerState tx
  previousUTxOState <- readLedger
  let before = recordedDepositStore previousUTxOState
      consumed = fixed ^. bodyTxL . inputsTxBodyL
      newAllocations =
        Map.fromList
          [ (txInAt index fixed, Standalone.outputDeposit (Standalone.protocolParameters ledgerState) output)
          | (index, output) <- zip [0 ..] (toList $ fixed ^. bodyTxL . outputsTxBodyL)
          , not $ isImplicitOutput output
          ]
      released = foldMap id $ Map.restrictKeys (depositStoreAllocations before) consumed
      retainedOutputs = Map.withoutKeys (unUTxO $ utxosUtxo previousUTxOState) consumed
  withNoFixup $ submitTx_ fixed
  afterState <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
  UTxO outputsAfter <- getUTxO
  let after = recordedDepositStore afterState
  depositStoreAllocations after
    `shouldBe` Map.union newAllocations (Map.withoutKeys (depositStoreAllocations before) consumed)
  depositStoreBalance after
    `shouldBe` (depositStoreBalance before <> foldMap id newAllocations)
    <-> released
  Map.restrictKeys outputsAfter consumed `shouldBe` Map.empty
  Map.restrictKeys outputsAfter (Map.keysSet retainedOutputs) `shouldBe` retainedOutputs
  forM_ (zip [0 ..] $ toList $ fixed ^. bodyTxL . outputsTxBodyL) $ \(index, output) ->
    Map.lookup (txInAt index fixed) outputsAfter `shouldBe` Just output

-- | Fund the optional TopTx source, one to five ordered SubTx sources and one unrelated Store
-- allocation through a real transaction. Each body proposes an implicit output
-- containing its source's application ADA plus recorded deposit. Every declaration
-- remains absent; the calling spec chooses the operations and settlement targets.
fundSubTxReleaseScenario ::
  Children.ReleaseScenario -> ImpTestM DijkstraEra Context.ReleaseTx
fundSubTxReleaseScenario scenario = do
  modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 4_310)
  address <- freshKeyAddrNoPtr_
  pp <- getsNES $ nesEsL . curPParamsEpochStateL
  let ownSources = map Children.StoreBackedSource $ maybeToList $ Children.topTxSource scenario
      childSources = Children.subTxSources scenario
      sources = ownSources <> childSources <> [Children.StoreBackedSource $ Coin 11_000_000]
      outputs = map (sourceOutput address) sources
      allocation = foldMap (Standalone.outputDeposit pp) outputs
      fundingTx =
        Standalone.declareNetDeposit allocation $
          mkBasicTx mkBasicTxBody & bodyTxL . outputsTxBodyL .~ SSeq.fromList outputs
  before <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
  funded <- ImpTest.submitTx fundingTx
  after <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
  let allocationRecords = depositStoreAllocations $ recordedDepositStore after
      fundedInputs = [txInAt index funded | index <- [0 .. length outputs - 1]]
      ownInput = listToMaybe $ take (length ownSources) fundedInputs
      childInputs = take (length childSources) $ drop (length ownSources) fundedInputs
      ownDeposit = foldMap (recordedInputDeposit allocationRecords) ownInput
      childDeposits = map (recordedInputDeposit allocationRecords) childInputs
      children = zipWith3 (subTxSettlingItsSource address) childSources childInputs childDeposits
      ownOutputs =
        [ mkBasicTxOutWithImplicitDeposit address $ inject $ amount <> ownDeposit
        | amount <- maybeToList $ Children.topTxSource scenario
        ]
      tx =
        mkTopTxWithSubTxs children
          & bodyTxL . inputsTxBodyL .~ Set.fromList (maybeToList ownInput)
          & bodyTxL . outputsTxBodyL .~ SSeq.fromList ownOutputs
          & bodyTxL . netUTxODepositChangeTxBodyL .~ TopTx.NoUTxODepositDeclaration
      fundingAllocations =
        Map.fromList
          [ (input, Standalone.outputDeposit pp output)
          | (input, output) <- zip fundedInputs outputs
          , not $ isImplicitOutput output
          ]
  depositStoreBalance (recordedDepositStore after)
    `shouldBe` depositStoreBalance (recordedDepositStore before)
    <> allocation
  allocationRecords
    `shouldBe` Map.union fundingAllocations (depositStoreAllocations $ recordedDepositStore before)
  let actualChildren = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
      capturedDeposits = zip childInputs childDeposits <> [(input, ownDeposit) | input <- maybeToList ownInput]
  length actualChildren `shouldBe` length childSources
  (length actualChildren >= 1 && length actualChildren <= 5) `shouldBe` True
  map (^. bodyTxL . inputsTxBodyL) actualChildren `shouldBe` map Set.singleton childInputs
  Set.size (Set.fromList childInputs) `shouldBe` length childInputs
  Set.intersection (Set.fromList $ maybeToList ownInput) (Set.fromList childInputs)
    `shouldBe` Set.empty
  all isImplicitOutput (createdOrdinaryOutputs tx) `shouldBe` True
  forM_ capturedDeposits $ \(input, deposit) -> do
    output <- impGetUTxO input
    Map.lookup input allocationRecords
      `shouldBe` if isImplicitOutput output then Nothing else Just deposit
    isImplicitOutput output `shouldBe` (deposit == Coin 0)
    (isImplicitOutput output || deposit > Coin 0) `shouldBe` True
  pure $ Context.ReleaseTx (Standalone.LedgerState after pp) tx

sourceOutput :: Addr -> Children.Source -> TxOut DijkstraEra
sourceOutput address (Children.StoreBackedSource amount) =
  mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets $ inject amount
sourceOutput address (Children.ImplicitSource amount) =
  mkBasicTxOutWithImplicitDeposit address $ inject amount

recordedInputDeposit :: Map.Map TxIn Coin -> TxIn -> Coin
recordedInputDeposit records input = Map.findWithDefault mempty input records

-- | Propose the source's application ADA plus its recorded deposit in output zero.
-- An implicit source contributes no deposit. Leave the child's declaration absent
-- so the spec explicitly chooses whether and where to declare a release.
subTxSettlingItsSource ::
  Addr -> Children.Source -> TxIn -> Coin -> Tx SubTx DijkstraEra
subTxSettlingItsSource address source input deposit =
  subTxWithDepositDeclaration input SubTx.NoUTxODepositDeclaration
    & bodyTxL . outputsTxBodyL
      .~ SSeq.singleton
        (mkBasicTxOutWithImplicitDeposit address $ inject $ Children.sourceApplicationCoins source <> deposit)

-- | Additional ordinary inputs across TopTx and every SubTx may fund fees, but
-- cannot introduce a Store release absent from the original release scenario.
checkAddedOrdinaryInputsUseImplicitDeposits ::
  Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
checkAddedOrdinaryInputsUseImplicitDeposits prepared submitted = do
  records <- depositStoreAllocations . recordedDepositStore <$> readLedger
  let addedInputs = ordinarySpendingInputs submitted `Set.difference` ordinarySpendingInputs prepared
  forM_ addedInputs $ \input -> do
    output <- impGetUTxO input
    isImplicitOutput output `shouldBe` True
    Map.lookup input records `shouldBe` Nothing

-- | Select one child by its distinct input, remove its declaration, then re-sign
-- that child and the parent. Sibling declarations and all outputs remain intact.
removeSubTxReleaseDeclarationByInput ::
  TxIn -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
removeSubTxReleaseDeclarationByInput input tx = do
  changed <- traverseSubTxs (removeSubTxReleaseDeclaration input) tx
  rederiveAddrTxWits changed

-- | The body that owns the store-backed ordinary spending input.
data ReleaseBody = TopTxReleasing | SubTxReleasing
  deriving (Eq, Show)

-- | A live store-backed input and the unsubmitted transaction that spends it.
-- Funding has already been submitted; no capacity allocation is invented or
-- injected into the ledger state.
data ReleaseFixture = ReleaseFixture
  { releaseBody :: ReleaseBody
  , spendingInput :: TxIn
  , sourceDeposit :: Coin
  , releaseTx :: Tx TopTx DijkstraEra
  }

-- | A signed transaction proposing a Store release with the source and settlement references needed
-- to observe its effects. The source and its deposit were funded on the real ledger;
-- amounts describe that live source, not an assumed outcome of submission.
data SignedReleaseTx = SignedReleaseTx
  { signedTx :: Tx TopTx DijkstraEra
  , sourceInput :: TxIn
  , settlementOutput :: TxIn
  , applicationCoins :: Coin
  , releasedDeposit :: Coin
  }

-- | Prepare either body proposing a release with a real failing script and disjoint collateral.
-- The caller supplies every declaration; ordinary source and settlement references
-- describe the proposal, without assuming that phase-2 failure executes it.
preparePhase2InvalidSingleBodyRelease ::
  ReleaseBody ->
  Children.SingleSourceScenario ->
  (StrictlyPositiveCoin -> Declarations) ->
  ImpTestM DijkstraEra SignedReleaseTx
preparePhase2InvalidSingleBodyRelease =
  prepareSingleBodyReleaseWith preparePhase2InvalidReleaseTx

-- | Fund one source, place the caller's declarations on its chosen body proposing a release,
-- and prepare the transaction without changing those declarations or submitting it.
prepareSingleBodyReleaseWith ::
  (Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)) ->
  ReleaseBody ->
  Children.SingleSourceScenario ->
  (StrictlyPositiveCoin -> Declarations) ->
  ImpTestM DijkstraEra SignedReleaseTx
prepareSingleBodyReleaseWith prepare owner scenario declarationsForDeposit = do
  (ledgerState, sourceTx) <-
    fundReleaseScenario $
      Standalone.ReleaseScenario
        [Children.inputApplicationCoins scenario]
        (Children.unrelatedApplicationCoins scenario)
        Standalone.ImplicitOutputs
        []
  input <- expectJust $ Set.lookupMin (sourceTx ^. bodyTxL . inputsTxBodyL)
  let deposit = Standalone.releasedDeposits ledgerState sourceTx
  recordedDeposit <- expectJust $ mkStrictlyPositiveCoin deposit
  let Declarations topDeclaration childDeclarations = declarationsForDeposit recordedDeposit
  proposal <- case owner of
    TopTxReleasing -> do
      length childDeclarations `shouldBe` 0
      pure $ sourceTx & bodyTxL . netUTxODepositChangeTxBodyL .~ topDeclaration
    SubTxReleasing -> do
      length childDeclarations `shouldBe` 1
      childDeclaration <- expectJust $ listToMaybe childDeclarations
      let subTx =
            subTxWithDepositDeclaration input childDeclaration
              & bodyTxL . outputsTxBodyL .~ (sourceTx ^. bodyTxL . outputsTxBodyL)
      pure $
        mkTopTxWithSubTxs [subTx]
          & bodyTxL . netUTxODepositChangeTxBodyL .~ topDeclaration
  let fixture = ReleaseFixture owner input deposit proposal
  preparedTx <- prepare $ releaseTx fixture
  checkPreservedReleaseFixture fixture preparedTx
  settlement <- ordinaryOutputInput fixture preparedTx
  source <- impGetUTxO $ spendingInput fixture
  pure $
    SignedReleaseTx
      { signedTx = preparedTx
      , sourceInput = spendingInput fixture
      , settlementOutput = settlement
      , applicationCoins = source ^. coinTxOutL
      , releasedDeposit = sourceDeposit fixture
      }

-- | Observe the actual UTxO and Store state at this point in the ledger test.
readLedger :: ImpTestM DijkstraEra (UTxOState DijkstraEra)
readLedger = getsNES $ nesEsL . esLStateL . lsUTxOStateL

-- | Allocate the source deposit by a real funding transaction, then consume the
-- output into an implicit settlement output containing application ADA plus the
-- entire recorded deposit. TopTx and local SubTx settlement use their own index 0.
buildTxSpendingStoreBackedOutput :: ReleaseBody -> ImpTestM DijkstraEra ReleaseFixture
buildTxSpendingStoreBackedOutput owner = do
  (ledgerState, topTx) <- fundSingleStoreBackedInput
  input <- expectJust $ Set.lookupMin (topTx ^. bodyTxL . inputsTxBodyL)
  let deposit@(Coin amount) = Standalone.releasedDeposits ledgerState topTx
      positiveDeposit = positiveAmount amount
      spending = case owner of
        TopTxReleasing -> Standalone.declareNetDeposit (Coin 0 <-> deposit) topTx
        SubTxReleasing ->
          let subTx =
                subTxWithDepositDeclaration
                  input
                  (SubTx.DeclaresNetUTxODepositRelease positiveDeposit $ SubTx.SubTxSettlementOutput $ TxIx 0)
                  & bodyTxL . outputsTxBodyL .~ (topTx ^. bodyTxL . outputsTxBodyL)
           in mkTopTxWithSubTxs [subTx]
                & bodyTxL . netUTxODepositChangeTxBodyL
                  .~ TopTx.DeclaresNetUTxODepositRelease positiveDeposit TopTx.NoTopTxSettlement
  pure $ ReleaseFixture owner input deposit spending

-- | Establish a live 10 ADA store-backed source and an unrelated 11 ADA source.
-- Return the ledger snapshot and an unsigned, undeclared proposal with an implicit
-- output containing the consumed source's application ADA plus its recorded deposit.
fundSingleStoreBackedInput ::
  ImpTestM DijkstraEra (Standalone.LedgerState, Tx TopTx DijkstraEra)
fundSingleStoreBackedInput =
  fundReleaseScenario $
    Standalone.ReleaseScenario [Coin 10_000_000] [Coin 11_000_000] Standalone.ImplicitOutputs []

-- | Fund disjoint implicit collateral of 10 ADA, returning 5 ADA and charging
-- 5 ADA as collateral fees. Add the real failing V4 script and finalize witnesses.
-- Supplying the collateral return explicitly lets the spec check both collateral
-- outputs and fees; the ordinary spending input is never used as collateral.
preparePhase2InvalidReleaseTx ::
  Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
preparePhase2InvalidReleaseTx tx = do
  address <- freshKeyAddrNoPtr_
  collateralInput <- sendCoinTo address $ Coin 10_000_000
  preparePhase2InvalidTx $
    tx
      & bodyTxL . collateralInputsTxBodyL .~ Set.singleton collateralInput
      & bodyTxL . totalCollateralTxBodyL .~ SJust (Coin 5_000_000)
      & bodyTxL . collateralReturnTxBodyL
        .~ SJust (mkBasicTxOutWithImplicitDeposit address $ inject $ Coin 5_000_000)

-- | Check that preparation has preserved the release scenario: the input is
-- still live and store-backed, belongs only to the intended ordinary body, and
-- cannot be masked by store-backed created outputs. Fixup may add funding inputs,
-- implicit TopTx change and disjoint collateral, but may not move the source input
-- or alter supplied declarations, outputs or recorded deposits. Added ordinary
-- inputs must be implicit and have no Store allocation. Call before submission.
checkPreservedReleaseFixture ::
  ReleaseFixture -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
checkPreservedReleaseFixture fixture submitted = do
  let prepared = releaseTx fixture & isPhase2ValidTxL .~ (submitted ^. isPhase2ValidTxL)
      input = spendingInput fixture
      preparedSubs = OMap.elems $ prepared ^. bodyTxL . subTransactionsTxBodyL
      submittedSubs = OMap.elems $ submitted ^. bodyTxL . subTransactionsTxBodyL
      topInputs = submitted ^. bodyTxL . inputsTxBodyL
      subInputs = map (^. bodyTxL . inputsTxBodyL) submittedSubs
      outputs =
        toList (submitted ^. bodyTxL . outputsTxBodyL)
          <> concatMap (toList . (^. bodyTxL . outputsTxBodyL)) submittedSubs
  checkPreservedOutputsAndDeclarations prepared submitted
  resolved <- impGetUTxO input
  isImplicitOutput resolved `shouldBe` False
  records <- depositStoreAllocations . recordedDepositStore <$> readLedger
  Map.lookup input records `shouldBe` Just (sourceDeposit fixture)
  all isImplicitOutput outputs `shouldBe` True
  Set.member input (submitted ^. bodyTxL . collateralInputsTxBodyL) `shouldBe` False
  Set.isSubsetOf (prepared ^. bodyTxL . inputsTxBodyL) topInputs `shouldBe` True
  forM_ (zip preparedSubs submittedSubs) $ \(before, after) ->
    Set.isSubsetOf (before ^. bodyTxL . inputsTxBodyL) (after ^. bodyTxL . inputsTxBodyL)
      `shouldBe` True
  case releaseBody fixture of
    TopTxReleasing -> do
      Set.member input topInputs `shouldBe` True
      any (Set.member input) subInputs `shouldBe` False
    SubTxReleasing -> do
      Set.member input topInputs `shouldBe` False
      length (filter (Set.member input) subInputs) `shouldBe` 1
  checkAddedOrdinaryInputsUseImplicitDeposits prepared submitted

-- | Identify the first ordinary output of the body proposing a release after preparation.
-- SubTx outputs use the SubTx's own transaction identifier. This only computes
-- the output reference; the spec checks whether execution created that output.
ordinaryOutputInput ::
  ReleaseFixture -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra TxIn
ordinaryOutputInput fixture tx = case releaseBody fixture of
  TopTxReleasing -> pure $ txInAt 0 tx
  SubTxReleasing -> do
    let subTxs = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
    length subTxs `shouldBe` 1
    txInAt 0 <$> expectJust (listToMaybe subTxs)

-- | Derive the rejection case from a prepared presence control by removing only
-- the body proposing a release's own declaration. Re-sign changed transaction bodies without
-- rerunning fixup, balancing, or script preparation. A SubTx rejection retains the
-- TopTx declaration so parent presence cannot conceal the missing child declaration.
removeReleaseDeclaration ::
  ReleaseFixture -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
removeReleaseDeclaration fixture tx = case releaseBody fixture of
  TopTxReleasing -> removeTopTxReleaseDeclaration tx
  SubTxReleasing -> do
    changed <- traverseSubTxs (removeSubTxReleaseDeclaration $ spendingInput fixture) tx
    rederiveAddrTxWits changed

-- | Remove only TopTx's declaration and re-sign its body without further fixup.
-- Child declarations and the prepared funding and settlement remain untouched.
removeTopTxReleaseDeclaration ::
  Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
removeTopTxReleaseDeclaration = removeTopTxDeclaration

-- | Re-sign only the SubTx owning this ordinary input after removing its declaration.
removeSubTxReleaseDeclaration ::
  TxIn -> Tx SubTx DijkstraEra -> ImpTestM DijkstraEra (Tx SubTx DijkstraEra)
removeSubTxReleaseDeclaration input tx
  | Set.member input (tx ^. bodyTxL . inputsTxBodyL) =
      rederiveAddrTxWits $
        tx & bodyTxL . subTxNetUTxODepositChangeTxBodyL .~ SubTx.NoUTxODepositDeclaration
  | otherwise = pure tx

-- | Fund live Store allocations, then reference every selected source without
-- consuming it. The ordinary proposal has no outputs or declarations; fixup may
-- add only implicit fee funding and change. Verify that all references have real
-- positive allocation records while ordinary allocation and release are both zero.
forAllReferenceOnlyStoreTx ::
  Gen Standalone.ReleaseScenario ->
  (Context.ReleaseTx -> ImpTestM DijkstraEra ()) ->
  Property
forAllReferenceOnlyStoreTx scenarios check =
  forAll scenarios $ \scenario -> do
    (ledgerState, sourceTx) <- fundReleaseScenario scenario
    let references = sourceTx ^. bodyTxL . inputsTxBodyL
        proposal =
          mkBasicTx mkBasicTxBody
            & bodyTxL . referenceInputsTxBodyL .~ references
        records = depositStoreAllocations $ recordedDepositStore $ Standalone.utxoState ledgerState
        context = Context.ReleaseTx ledgerState proposal
    Set.null references `shouldBe` False
    forM_ references $ \input -> do
      deposit <- expectJust $ Map.lookup input records
      _ <- expectJust $ mkStrictlyPositiveCoin deposit
      pure ()
    (Context.allocatedDeposits context, Context.releasedDeposits context) `shouldBe` (Coin 0, Coin 0)
    check context

-- | Fund the collateral source through an ordinary accepted transaction, then
-- construct a standalone proposal with the supplied declarations. Its ordinary
-- script input and fee funding are implicit; the selected Store operations occur
-- only in collateral. Exercise actual V4 success or failure as requested.
-- Babbage's inherited fixup only accepts an implicit collateral return, so install
-- the final return form afterward and re-sign without another fixup.
buildAndSignCollateralOnlyTx ::
  Release.CollateralScenario -> Declarations -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
buildAndSignCollateralOnlyTx scenario declarations = do
  modifyPParams $
    (ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 4_310))
      . (ppCollateralPercentageL .~ 150)
  address <- freshKeyAddrNoPtr_
  pp <- getsNES $ nesEsL . curPParamsEpochStateL
  let inputHasStoreDeposit = Release.collateralStoreOperations scenario /= Release.StoreBackedReturnOnly
      returnHasStoreDeposit = Release.collateralStoreOperations scenario /= Release.StoreBackedInputOnly
      inputOutput =
        sourceOutput address $
          if inputHasStoreDeposit
            then Children.StoreBackedSource $ Release.collateralInputCoins scenario
            else Children.ImplicitSource $ Release.collateralInputCoins scenario
      returnOutput =
        sourceOutput address $
          if returnHasStoreDeposit
            then Children.StoreBackedSource $ Release.collateralReturnCoins scenario
            else Children.ImplicitSource $ Release.collateralReturnCoins scenario
      preparationReturn =
        mkBasicTxOutWithImplicitDeposit address $ inject $ Release.collateralReturnCoins scenario
      allocation = Standalone.outputDeposit pp inputOutput
  fundingTx <-
    ImpTest.submitTx $
      Standalone.declareNetDeposit allocation $
        mkBasicTx mkBasicTxBody & bodyTxL . outputsTxBodyL .~ SSeq.singleton inputOutput
  let collateralInput = txInAt 0 fundingTx
      validity = Release.collateralPhase2Validity scenario
  scriptInput <- produceScript . hashPlutusScript $ case validity of
    Phase2Valid -> alwaysSucceedsWithDatum SPlutusV4
    Phase2Invalid -> alwaysFailsWithDatum SPlutusV4
  ledgerState <- (`Standalone.LedgerState` pp) <$> readLedger
  let proposal =
        mkBasicTx mkBasicTxBody
          & bodyTxL . inputsTxBodyL .~ Set.singleton scriptInput
          & bodyTxL . collateralInputsTxBodyL .~ Set.singleton collateralInput
          & bodyTxL . collateralReturnTxBodyL .~ SJust preparationReturn
          & bodyTxL . totalCollateralTxBodyL
            .~ SJust (Release.collateralInputCoins scenario <-> Release.collateralReturnCoins scenario)
      declared = Context.unsignedTx $ Context.addDeclaration declarations $ Context.ReleaseTx ledgerState proposal
  prepared <- fixupTx declared
  signed <-
    rederiveAddrTxWits $
      prepared
        & bodyTxL . collateralReturnTxBodyL .~ SJust returnOutput
        & isPhase2ValidTxL .~ validity
  checkPreservedReleaseProposal ledgerState (declared & isPhase2ValidTxL .~ validity) signed
  signed ^. bodyTxL . collateralInputsTxBodyL `shouldBe` Set.singleton collateralInput
  signed ^. bodyTxL . collateralReturnTxBodyL `shouldBe` SJust returnOutput
  signed
    ^. bodyTxL
      . totalCollateralTxBodyL
      `shouldBe` SJust (Release.collateralInputCoins scenario <-> Release.collateralReturnCoins scenario)
  let context = Context.ReleaseTx ledgerState signed
      records = depositStoreAllocations $ recordedDepositStore $ Standalone.utxoState ledgerState
  Map.lookup collateralInput records
    `shouldBe` if inputHasStoreDeposit then Just allocation else Nothing
  (Context.allocatedDeposits context, Context.releasedDeposits context) `shouldBe` (Coin 0, Coin 0)
  forM_ (ordinarySpendingInputs signed) $ \input -> do
    output <- impGetUTxO input
    isImplicitOutput output `shouldBe` True
  all isImplicitOutput (createdOrdinaryOutputs signed) `shouldBe` True
  pure signed
