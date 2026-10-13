{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

-- | Real funded Store allocations and transaction submission for spending rules.
-- All source outputs and their deposits are established by ordinary transactions.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Spending (
  SpendingBody (..),
  SpendingFixture (..),
  SubTxSpendingFixture (..),
  fundSubTxSpendingScenario,
  checkPreservedSubTxSpendingFixture,
  removeSubTxSpendingDeclarationByInput,
  ordinarySpendingInputs,
  createdOrdinaryOutputs,
  buildTxSpendingStoreBackedOutput,
  fundSpendingScenario,
  checkPreservedSpendingFixture,
  ordinaryOutputInput,
  removeSpendingDeclaration,
  preparePhase2InvalidSpendingTx,
  submitTxAndExpectSuccess,
  submitTxAndExpectFailureContaining,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Shelley.LedgerState (
  curPParamsEpochStateL,
  esLStateL,
  lsUTxOStateL,
  nesEsL,
  utxosDepositStore,
  utxosUtxo,
 )
import Cardano.Ledger.State (DepositStore (..), UTxO (..))
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
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (
  subTxWithDepositDeclaration,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (isImplicitOutput)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as Children
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Standalone
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission (
  checkPreservedCreationFixture,
  preparePhase2InvalidTx,
  submitTxAndExpectFailureContaining,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest
import Test.Cardano.Ledger.Imp.Common (expectJust, forM_, shouldBe)

-- | Establish generated inputs through a real funding transaction. Unrelated
-- allocations remain live. Return the actual ledger snapshot and an unsigned
-- proposal whose declaration is supplied visibly by the calling specification.
fundSpendingScenario ::
  Standalone.SpendingScenario ->
  ImpTestM DijkstraEra (Standalone.LedgerState, Tx TopTx DijkstraEra)
fundSpendingScenario scenario = do
  modifyPParams $ ppCoinsPerUTxOByteL .~ CoinPerByte (CompactCoin 4_310)
  address <- freshKeyAddrNoPtr_
  pp <- getsNES $ nesEsL . curPParamsEpochStateL
  let outputs = Standalone.sourceOutputs address scenario
      allocation = foldMap (Standalone.outputDeposit pp) outputs
      fundingTx =
        Standalone.declareNetDeposit allocation $
          mkBasicTx mkBasicTxBody & bodyTxL . outputsTxBodyL .~ SSeq.fromList outputs
  before <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
  funded <- submitTx fundingTx
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
  depositStoreBalance (utxosDepositStore after)
    `shouldBe` depositStoreBalance (utxosDepositStore before)
    <> allocation
  depositStoreAllocations (utxosDepositStore after)
    `shouldBe` Map.union fundingAllocations (depositStoreAllocations $ utxosDepositStore before)
  pure (ledgerState, spending & bodyTxL . outputsTxBodyL .~ SSeq.fromList created)

-- | Submit the declared transaction through the real ledger. Preparation may add
-- implicit fee funding and change, but preserves the supplied outputs/declaration.
-- Acceptance must consume exactly the recorded input allocations and create the
-- independently priced output records while retaining every unrelated allocation.
submitTxAndExpectSuccess ::
  Standalone.LedgerState -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
submitTxAndExpectSuccess ledgerState tx = do
  fixed <- fixupTx tx
  length (fixed ^. bodyTxL . subTransactionsTxBodyL) `shouldBe` 0
  fixed
    ^. bodyTxL . netUTxODepositChangeTxBodyL `shouldBe` tx
    ^. bodyTxL . netUTxODepositChangeTxBodyL
  take (length $ tx ^. bodyTxL . outputsTxBodyL) (toList $ fixed ^. bodyTxL . outputsTxBodyL)
    `shouldBe` toList (tx ^. bodyTxL . outputsTxBodyL)
  let before = utxosDepositStore $ Standalone.utxoState ledgerState
      consumed = fixed ^. bodyTxL . inputsTxBodyL
      newAllocations =
        Map.fromList
          [ (txInAt index fixed, Standalone.outputDeposit (Standalone.protocolParameters ledgerState) output)
          | (index, output) <- zip [0 ..] (toList $ fixed ^. bodyTxL . outputsTxBodyL)
          , not $ isImplicitOutput output
          ]
      released = foldMap id $ Map.restrictKeys (depositStoreAllocations before) consumed
      retainedOutputs = Map.withoutKeys (unUTxO $ utxosUtxo $ Standalone.utxoState ledgerState) consumed
  withNoFixup $ submitTx_ fixed
  afterState <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
  UTxO outputsAfter <- getUTxO
  let after = utxosDepositStore afterState
  depositStoreAllocations after
    `shouldBe` Map.union newAllocations (Map.withoutKeys (depositStoreAllocations before) consumed)
  depositStoreBalance after
    `shouldBe` (depositStoreBalance before <> foldMap id newAllocations)
    <-> released
  Map.restrictKeys outputsAfter consumed `shouldBe` Map.empty
  Map.restrictKeys outputsAfter (Map.keysSet retainedOutputs) `shouldBe` retainedOutputs
  forM_ (zip [0 ..] $ toList $ fixed ^. bodyTxL . outputsTxBodyL) $ \(index, output) ->
    Map.lookup (txInAt index fixed) outputsAfter `shouldBe` Just output

-- | Ordered sources and actual recorded deposits for a transaction with several
-- SubTxs. Zero entries correspond to implicit child inputs without Store records.
-- References remain distinct even when output values and declarations repeat.
data SubTxSpendingFixture = SubTxSpendingFixture
  { subTxSpendingTx :: Tx TopTx DijkstraEra
  , subTxSpendingInputs :: [TxIn]
  , subTxRecordedDeposits :: [Coin]
  , topTxSpendingInput :: Maybe TxIn
  , topTxRecordedDeposit :: Coin
  , allSpentDepositInputs :: Set.Set TxIn
  }

-- | Submit the source outputs and their exact allocation before constructing the
-- proposed batch. Children settle their own recorded releases locally; the parent
-- declares the total and settles only its optional own release. An unrelated
-- store-backed source stays live throughout the scenario.
fundSubTxSpendingScenario ::
  Children.SpendingScenario -> ImpTestM DijkstraEra SubTxSpendingFixture
fundSubTxSpendingScenario scenario = do
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
  funded <- submitTx fundingTx
  after <- getsNES $ nesEsL . esLStateL . lsUTxOStateL
  let allocationRecords = depositStoreAllocations $ utxosDepositStore after
      fundedInputs = [txInAt index funded | index <- [0 .. length outputs - 1]]
      ownInput = listToMaybe $ take (length ownSources) fundedInputs
      childInputs = take (length childSources) $ drop (length ownSources) fundedInputs
      ownDeposit = foldMap (recordedInputDeposit allocationRecords) ownInput
      childDeposits = map (recordedInputDeposit allocationRecords) childInputs
      Coin totalRelease = ownDeposit <> foldMap id childDeposits
      children = zipWith3 (subTxSettlingItsSource address) childSources childInputs childDeposits
      ownOutputs =
        [ mkBasicTxOutWithImplicitDeposit address $ inject $ amount <> ownDeposit
        | amount <- maybeToList $ Children.topTxSource scenario
        ]
      parentSettlement = case ownInput of
        Nothing -> TopTx.NoTopTxSettlement
        Just _ -> TopTx.TopTxSettlementOutput $ TxIx 0
      tx =
        mkTopTxWithSubTxs children
          & bodyTxL . inputsTxBodyL .~ Set.fromList (maybeToList ownInput)
          & bodyTxL . outputsTxBodyL .~ SSeq.fromList ownOutputs
          & bodyTxL . netUTxODepositChangeTxBodyL
            .~ TopTx.DeclaresNetUTxODepositRelease (positiveAmount totalRelease) parentSettlement
      spentSources = maybeToList ownInput <> childInputs
      spentDepositInputs = Map.keysSet $ Map.restrictKeys allocationRecords $ Set.fromList spentSources
      fundingAllocations =
        Map.fromList
          [ (input, Standalone.outputDeposit pp output)
          | (input, output) <- zip fundedInputs outputs
          , not $ isImplicitOutput output
          ]
  depositStoreBalance (utxosDepositStore after)
    `shouldBe` depositStoreBalance (utxosDepositStore before)
    <> allocation
  allocationRecords
    `shouldBe` Map.union fundingAllocations (depositStoreAllocations $ utxosDepositStore before)
  let fixture = SubTxSpendingFixture tx childInputs childDeposits ownInput ownDeposit spentDepositInputs
  checkPreservedSubTxSpendingFixture fixture tx
  pure fixture

sourceOutput :: Addr -> Children.Source -> TxOut DijkstraEra
sourceOutput address (Children.StoreBackedSource amount) =
  mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets $ inject amount
sourceOutput address (Children.ImplicitSource amount) =
  mkBasicTxOutWithImplicitDeposit address $ inject amount

recordedInputDeposit :: Map.Map TxIn Coin -> TxIn -> Coin
recordedInputDeposit records input = Map.findWithDefault mempty input records

-- | No record means no release for an implicit source. A store-backed source's
-- positive record is released into the child's own first output.
subTxSettlingItsSource ::
  Addr -> Children.Source -> TxIn -> Coin -> Tx SubTx DijkstraEra
subTxSettlingItsSource address source input deposit =
  subTxWithDepositDeclaration input (localReleaseDeclaration deposit)
    & bodyTxL . outputsTxBodyL
      .~ SSeq.singleton
        (mkBasicTxOutWithImplicitDeposit address $ inject $ Children.sourceApplicationCoins source <> deposit)

localReleaseDeclaration :: Coin -> SubTx.SubTxUTxODepositDeclaration
localReleaseDeclaration (Coin 0) = SubTx.NoUTxODepositDeclaration
localReleaseDeclaration (Coin amount) =
  SubTx.DeclaresNetUTxODepositRelease (positiveAmount amount) $ SubTx.SubTxSettlementOutput $ TxIx 0

-- | Preparation retains child count, order, input ownership, declarations and
-- implicit settlement outputs. The original live inputs and their recorded
-- allocations must still exist; this check never repairs the transaction.
checkPreservedSubTxSpendingFixture ::
  SubTxSpendingFixture -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
checkPreservedSubTxSpendingFixture fixture submitted = do
  let prepared = subTxSpendingTx fixture & isPhase2ValidTxL .~ (submitted ^. isPhase2ValidTxL)
      children = OMap.elems $ submitted ^. bodyTxL . subTransactionsTxBodyL
      childInputs = subTxSpendingInputs fixture
      topInputs = submitted ^. bodyTxL . inputsTxBodyL
      expectedTopInputs = Set.fromList $ maybeToList $ topTxSpendingInput fixture
      capturedDeposits =
        zip childInputs (subTxRecordedDeposits fixture)
          <> [(input, topTxRecordedDeposit fixture) | input <- maybeToList $ topTxSpendingInput fixture]
  checkPreservedCreationFixture prepared submitted
  length children `shouldBe` length childInputs
  (length children >= 2) `shouldBe` True
  map (^. bodyTxL . inputsTxBodyL) children `shouldBe` map Set.singleton childInputs
  map (^. bodyTxL . subTxNetUTxODepositChangeTxBodyL) children
    `shouldBe` map localReleaseDeclaration (subTxRecordedDeposits fixture)
  Set.size (Set.fromList childInputs) `shouldBe` length childInputs
  Set.intersection topInputs (Set.fromList childInputs) `shouldBe` Set.empty
  Set.isSubsetOf expectedTopInputs topInputs `shouldBe` True
  all isImplicitOutput (createdOrdinaryOutputs submitted) `shouldBe` True
  Set.intersection
    (Set.fromList $ map fst capturedDeposits)
    (submitted ^. bodyTxL . collateralInputsTxBodyL)
    `shouldBe` Set.empty
  store <- utxosDepositStore <$> getsNES (nesEsL . esLStateL . lsUTxOStateL)
  forM_ capturedDeposits $ \(input, deposit) -> do
    output <- impGetUTxO input
    Map.lookup input (depositStoreAllocations store)
      `shouldBe` if isImplicitOutput output then Nothing else Just deposit
    isImplicitOutput output `shouldBe` (deposit == Coin 0)
    (isImplicitOutput output || deposit > Coin 0) `shouldBe` True

-- | Select one child by its distinct input, remove its declaration, then re-sign
-- that child and the parent. Sibling declarations and all outputs remain intact.
removeSubTxSpendingDeclarationByInput ::
  TxIn -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
removeSubTxSpendingDeclarationByInput input tx = do
  changed <- traverseSubTxs (removeSubTxSpendingDeclaration input) tx
  rederiveAddrTxWits changed

-- | Ordinary inputs across all bodies. Reference and collateral inputs are excluded.
ordinarySpendingInputs :: Tx TopTx DijkstraEra -> Set.Set TxIn
ordinarySpendingInputs tx =
  (tx ^. bodyTxL . inputsTxBodyL)
    <> foldMap (^. bodyTxL . inputsTxBodyL) (tx ^. bodyTxL . subTransactionsTxBodyL)

-- | Every ordinary output indexed by the identifier of the body that creates it.
-- SubTx outputs use the child transaction identifier, not the parent identifier.
createdOrdinaryOutputs :: Tx TopTx DijkstraEra -> Map.Map TxIn (TxOut DijkstraEra)
createdOrdinaryOutputs tx =
  ordinaryBodyOutputs tx
    <> foldMap ordinaryBodyOutputs (tx ^. bodyTxL . subTransactionsTxBodyL)

ordinaryBodyOutputs :: Tx l DijkstraEra -> Map.Map TxIn (TxOut DijkstraEra)
ordinaryBodyOutputs tx =
  Map.fromList $
    zipWith (\index output -> (txInAt index tx, output)) [0 ..] $
      toList $
        tx ^. bodyTxL . outputsTxBodyL

-- | The body that owns the store-backed ordinary spending input.
data SpendingBody = TopTxSpending | SubTxSpending
  deriving (Eq, Show)

-- | A live store-backed input and the unsubmitted transaction that spends it.
-- Funding has already been submitted; no capacity allocation is invented or
-- injected into the ledger state.
data SpendingFixture = SpendingFixture
  { spendingBody :: SpendingBody
  , spendingInput :: TxIn
  , spendingDeposit :: Coin
  , spendingTx :: Tx TopTx DijkstraEra
  }

-- | Allocate the source deposit by a real funding transaction, then consume the
-- output into an implicit settlement output containing application ADA plus the
-- entire recorded deposit. TopTx and local SubTx settlement use their own index 0.
buildTxSpendingStoreBackedOutput :: SpendingBody -> ImpTestM DijkstraEra SpendingFixture
buildTxSpendingStoreBackedOutput owner = do
  let scenario = Standalone.SpendingScenario [Coin 10_000_000] [Coin 11_000_000] Standalone.ImplicitOutputs []
  (ledgerState, topTx) <- fundSpendingScenario scenario
  input <- expectJust $ Set.lookupMin (topTx ^. bodyTxL . inputsTxBodyL)
  let deposit@(Coin amount) = Standalone.releasedDeposits ledgerState topTx
      positiveDeposit = positiveAmount amount
      spending = case owner of
        TopTxSpending -> Standalone.declareNetDeposit (Coin 0 <-> deposit) topTx
        SubTxSpending ->
          let subTx =
                subTxWithDepositDeclaration
                  input
                  (SubTx.DeclaresNetUTxODepositRelease positiveDeposit $ SubTx.SubTxSettlementOutput $ TxIx 0)
                  & bodyTxL . outputsTxBodyL .~ (topTx ^. bodyTxL . outputsTxBodyL)
           in mkTopTxWithSubTxs [subTx]
                & bodyTxL . netUTxODepositChangeTxBodyL
                  .~ TopTx.DeclaresNetUTxODepositRelease positiveDeposit TopTx.NoTopTxSettlement
  pure $ SpendingFixture owner input deposit spending

-- | Fund disjoint implicit collateral of 10 ADA, returning 5 ADA and charging
-- 5 ADA as collateral fees. Add the real failing V4 script and finalize witnesses.
-- Supplying the collateral return explicitly lets the spec check both collateral
-- outputs and fees; the ordinary spending input is never used as collateral.
preparePhase2InvalidSpendingTx ::
  Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
preparePhase2InvalidSpendingTx tx = do
  address <- freshKeyAddrNoPtr_
  collateralInput <- sendCoinTo address $ Coin 10_000_000
  preparePhase2InvalidTx $
    tx
      & bodyTxL . collateralInputsTxBodyL .~ Set.singleton collateralInput
      & bodyTxL . totalCollateralTxBodyL .~ SJust (Coin 5_000_000)
      & bodyTxL . collateralReturnTxBodyL
        .~ SJust (mkBasicTxOutWithImplicitDeposit address $ inject $ Coin 5_000_000)

-- | Check that preparation has preserved the spending scenario: the input is
-- still live and store-backed, belongs only to the intended ordinary body, and
-- cannot be masked by store-backed created outputs. Fixup may add funding inputs,
-- implicit TopTx change and disjoint collateral, but may not move the source input
-- or alter supplied declarations or outputs. Call before submitting the transaction.
checkPreservedSpendingFixture ::
  SpendingFixture -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra ()
checkPreservedSpendingFixture fixture submitted = do
  let prepared = spendingTx fixture & isPhase2ValidTxL .~ (submitted ^. isPhase2ValidTxL)
      input = spendingInput fixture
      preparedSubs = OMap.elems $ prepared ^. bodyTxL . subTransactionsTxBodyL
      submittedSubs = OMap.elems $ submitted ^. bodyTxL . subTransactionsTxBodyL
      topInputs = submitted ^. bodyTxL . inputsTxBodyL
      subInputs = map (^. bodyTxL . inputsTxBodyL) submittedSubs
      outputs =
        toList (submitted ^. bodyTxL . outputsTxBodyL)
          <> concatMap (toList . (^. bodyTxL . outputsTxBodyL)) submittedSubs
  checkPreservedCreationFixture prepared submitted
  resolved <- impGetUTxO input
  isImplicitOutput resolved `shouldBe` False
  all isImplicitOutput outputs `shouldBe` True
  Set.member input (submitted ^. bodyTxL . collateralInputsTxBodyL) `shouldBe` False
  Set.isSubsetOf (prepared ^. bodyTxL . inputsTxBodyL) topInputs `shouldBe` True
  forM_ (zip preparedSubs submittedSubs) $ \(before, after) ->
    Set.isSubsetOf (before ^. bodyTxL . inputsTxBodyL) (after ^. bodyTxL . inputsTxBodyL)
      `shouldBe` True
  case spendingBody fixture of
    TopTxSpending -> do
      Set.member input topInputs `shouldBe` True
      any (Set.member input) subInputs `shouldBe` False
    SubTxSpending -> do
      Set.member input topInputs `shouldBe` False
      length (filter (Set.member input) subInputs) `shouldBe` 1

-- | Identify the first ordinary output of the spending body after preparation.
-- SubTx outputs use the SubTx's own transaction identifier. This only computes
-- the output reference; the spec checks whether execution created that output.
ordinaryOutputInput ::
  SpendingFixture -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra TxIn
ordinaryOutputInput fixture tx = case spendingBody fixture of
  TopTxSpending -> pure $ txInAt 0 tx
  SubTxSpending -> do
    let subTxs = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
    length subTxs `shouldBe` 1
    txInAt 0 <$> expectJust (listToMaybe subTxs)

-- | Derive the rejection case from a prepared presence control by removing only
-- the spending body's own declaration. Re-sign changed transaction bodies without
-- rerunning fixup, balancing, or script preparation. A SubTx rejection retains the
-- TopTx declaration so parent presence cannot conceal the missing child declaration.
removeSpendingDeclaration ::
  SpendingFixture -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
removeSpendingDeclaration fixture tx = case spendingBody fixture of
  TopTxSpending ->
    rederiveAddrTxWits $ tx & bodyTxL . netUTxODepositChangeTxBodyL .~ TopTx.NoUTxODepositDeclaration
  SubTxSpending -> do
    changed <- traverseSubTxs (removeSubTxSpendingDeclaration $ spendingInput fixture) tx
    rederiveAddrTxWits changed

-- | Re-sign only the SubTx owning this ordinary input after removing its declaration.
removeSubTxSpendingDeclaration ::
  TxIn -> Tx SubTx DijkstraEra -> ImpTestM DijkstraEra (Tx SubTx DijkstraEra)
removeSubTxSpendingDeclaration input tx
  | Set.member input (tx ^. bodyTxL . inputsTxBodyL) =
      rederiveAddrTxWits $
        tx & bodyTxL . subTxNetUTxODepositChangeTxBodyL .~ SubTx.NoUTxODepositDeclaration
  | otherwise = pure tx
