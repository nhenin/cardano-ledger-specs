{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Generated standalone transaction scenarios and queries over real ledger snapshots.
-- Scenarios describe amounts and output forms. Submission fixtures establish their
-- inputs through ordinary ledger transactions before any release is calculated.
-- Proposed releases take effect only if ordinary ledger execution succeeds.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx (
  module Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx,
  ReleaseScenario (..),
  OutputForms (..),
  LedgerState (..),
  standaloneTopTxAnyOutputForm,
  standaloneTopTxOnlyImplicitOutputs,
  standaloneTopTxWithEqualAllocationsAndReleases,
  standaloneTopTxRequiringNetAllocation,
  sourceOutputs,
  createdOutputs,
  outputDeposit,
  sizedOutputDeposit,
  allocatedDeposits,
  releasedDeposits,
  createdAllocations,
  declaration,
  declaredNetDeposit,
  declareNetDeposit,
  netDepositDeclaration,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Binary (Sized (..), mkSized)
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx
import qualified Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx as TopTx
import Cardano.Ledger.Shelley.LedgerState (UTxOState)
import Cardano.Ledger.StrictlyPositiveCoin (unStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (Val ((<->)), inject)
import Data.Foldable (toList)
import qualified Data.Map.Strict as Map
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger, elements, vectorOf)
import Test.Cardano.Ledger.Core.Utils (txInAt)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  liveOutputStore,
  recordedAmounts,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmount,
 )

-- | The UTxO state and protocol parameters read after real fixture funding.
-- This snapshot is never installed into the ledger or used to bypass a transition.
data LedgerState = LedgerState
  { utxoState :: UTxOState DijkstraEra
  , protocolParameters :: PParams DijkstraEra
  }
  deriving (Show)

-- | Application amounts for consumed and unrelated store-backed outputs, followed
-- by the output forms of the proposed transaction. Input references and witnesses
-- are supplied only after funding succeeds on the actual ledger.
data ReleaseScenario = ReleaseScenario
  { consumedApplicationAmounts :: [Coin]
  , unrelatedApplicationAmounts :: [Coin]
  , outputForms :: OutputForms
  , createdApplicationAmounts :: [Coin]
  }
  deriving (Show)

data OutputForms = ImplicitOutputs | StoreBackedOutputs | MixedOutputs
  deriving (Eq, Show)

-- | Standalone TopTx, any output form. Consumes at least one store-backed output
-- and creates implicit-only, store-backed-only or mixed outputs. Relative input
-- and output counts exercise net releases, zero and allocations under fixed pricing.
standaloneTopTxAnyOutputForm :: Gen ReleaseScenario
standaloneTopTxAnyOutputForm =
  elements [ImplicitOutputs, StoreBackedOutputs, MixedOutputs] >>= standaloneTopTx

-- | Standalone TopTx, only implicit outputs. Consume at least one store-backed
-- output and propose one implicit output receiving application ADA plus the full
-- recorded release. Ordinary fixup funds fees separately.
standaloneTopTxOnlyImplicitOutputs :: Gen ReleaseScenario
standaloneTopTxOnlyImplicitOutputs = standaloneTopTx ImplicitOutputs

-- | Standalone TopTx, equal nonzero allocations and releases. Consume one to five
-- store-backed outputs and create the same number, optionally alongside an implicit
-- output. Application amounts share the same CBOR width, so equal counts under the
-- unchanged price give equal deposits. Submission support checks the actual totals
-- against recorded source deposits before the spec supplies its declaration.
standaloneTopTxWithEqualAllocationsAndReleases :: Gen ReleaseScenario
standaloneTopTxWithEqualAllocationsAndReleases = do
  scenario <- elements [StoreBackedOutputs, MixedOutputs] >>= standaloneTopTx
  amounts <- vectorOf (length $ consumedApplicationAmounts scenario) applicationAmount
  pure $ scenario {createdApplicationAmounts = amounts}

-- | Standalone TopTx requiring a net allocation. Consume at least one store-backed
-- output and create one more store-backed output than is consumed. The fixed policy
-- and equal-width application amounts make the new allocation exceed the release.
standaloneTopTxRequiringNetAllocation :: Gen ReleaseScenario
standaloneTopTxRequiringNetAllocation = do
  scenario <- standaloneTopTx StoreBackedOutputs
  amounts <- vectorOf (length (consumedApplicationAmounts scenario) + 1) applicationAmount
  pure $ scenario {createdApplicationAmounts = amounts}

standaloneTopTx :: OutputForms -> Gen ReleaseScenario
standaloneTopTx forms = do
  spentCount <- chooseInt (1, 5)
  unspentCount <- chooseInt (1, 3)
  createdCount <- elements [max 1 (spentCount - 1), spentCount, spentCount + 1]
  consumed <- vectorOf spentCount applicationAmount
  unrelated <- vectorOf unspentCount applicationAmount
  created <- vectorOf createdCount applicationAmount
  pure $ ReleaseScenario consumed unrelated forms created

applicationAmount :: Gen Coin
applicationAmount = Coin <$> chooseInteger (10_000_000, 20_000_000)

-- | Funding creates both consumed and unrelated outputs. Their ordering lets the
-- adapter retain unrelated inputs as a check against releasing the entire Store.
sourceOutputs :: Addr -> ReleaseScenario -> [TxOut DijkstraEra]
sourceOutputs address scenario =
  map (storeBackedOutput address) $
    consumedApplicationAmounts scenario <> unrelatedApplicationAmounts scenario

-- | Output zero can receive the complete release. Other shapes retain a generous
-- application balance; normal funding supplies any shortfall without changing the
-- generated outputs or deposit declaration.
createdOutputs :: Addr -> ReleaseScenario -> Coin -> [TxOut DijkstraEra]
createdOutputs address scenario released = case outputForms scenario of
  ImplicitOutputs ->
    [ mkBasicTxOutWithImplicitDeposit address $
        inject $
          foldMap id (consumedApplicationAmounts scenario) <> released
    ]
  StoreBackedOutputs -> case map (storeBackedOutput address) (createdApplicationAmounts scenario) of
    output : outputs -> (output & coinTxOutL .~ Coin 200_000_000) : outputs
    [] -> error "A store-backed scenario must create a settlement output"
  MixedOutputs ->
    mkBasicTxOutWithImplicitDeposit address (inject $ Coin 200_000_000)
      : map (storeBackedOutput address) (createdApplicationAmounts scenario)

storeBackedOutput :: Addr -> Coin -> TxOut DijkstraEra
storeBackedOutput address = mkBasicTxOutWithStoreBackedDeposit address . ApplicationAssets . inject

-- | Independent specification formula for the current fixed policy. Only the
-- serialized store-backed output is priced; external allocations are excluded.
outputDeposit :: PParams DijkstraEra -> TxOut DijkstraEra -> Coin
outputDeposit pp = sizedOutputDeposit pp . mkSized (eraProtVerLow @DijkstraEra)

-- | Accepted bodies already carry the size charged by the protocol. Use it
-- directly: canonical re-encoding can be shorter than the submitted output.
sizedOutputDeposit :: PParams DijkstraEra -> Sized (TxOut DijkstraEra) -> Coin
sizedOutputDeposit _ (Sized (LegacyTxOut _) _) = mempty
sizedOutputDeposit pp (Sized (NewTxOut _) acceptedBytes) =
  case pp ^. ppCoinsPerUTxOByteL of
    CoinPerByte (CompactCoin price) ->
      Coin $ toInteger price * (160 + toInteger acceptedBytes)

allocatedDeposits :: LedgerState -> Tx TopTx DijkstraEra -> Coin
allocatedDeposits ledgerState topTx =
  foldMap (sizedOutputDeposit $ protocolParameters ledgerState) $
    topTx ^. bodyTxL . sizedOutputsTxBodyL

-- | Read only records belonging to this transaction's ordinary inputs.
releasedDeposits :: LedgerState -> Tx TopTx DijkstraEra -> Coin
releasedDeposits ledgerState topTx =
  foldMap id $
    Map.restrictKeys
      (recordedAmounts $ liveOutputStore $ utxoState ledgerState)
      (topTx ^. bodyTxL . inputsTxBodyL)

-- | Price every created store-backed ordinary output independently of the Store
-- transition. Each output is keyed by its own body's final transaction identifier;
-- implicit outputs and collateral returns allocate nothing on the ordinary path.
createdAllocations :: LedgerState -> Tx TopTx DijkstraEra -> Map.Map TxIn Coin
createdAllocations ledgerState topTx =
  createdBodyAllocations (protocolParameters ledgerState) topTx
    <> foldMap
      (createdBodyAllocations $ protocolParameters ledgerState)
      (topTx ^. bodyTxL . subTransactionsTxBodyL)

createdBodyAllocations :: PParams DijkstraEra -> Tx l DijkstraEra -> Map.Map TxIn Coin
createdBodyAllocations parameters tx =
  Map.fromList
    [ (txInAt index tx, sizedOutputDeposit parameters output)
    | (index, output@(Sized (NewTxOut _) _)) <-
        zip [0 ..] $ toList $ tx ^. bodyTxL . sizedOutputsTxBodyL
    ]

-- | The declaration supplied by TopTx, without deriving or repairing its amount.
declaration :: Tx TopTx DijkstraEra -> TopTx.TopTxUTxODepositDeclaration
declaration topTx = topTx ^. bodyTxL . netUTxODepositChangeTxBodyL

-- | Read the declared signed amount: allocation is positive and release negative.
-- Absence is 'Nothing'; an explicit zero remains 'Just' zero.
declaredNetDeposit :: Tx TopTx DijkstraEra -> Maybe Coin
declaredNetDeposit topTx = case declaration topTx of
  TopTx.NoUTxODepositDeclaration -> Nothing
  TopTx.DeclaresZeroNetUTxODeposit -> Just mempty
  TopTx.DeclaresNetUTxODepositAllocation amount -> Just $ unStrictlyPositiveCoin amount
  TopTx.DeclaresNetUTxODepositRelease amount _ -> Just $ Coin 0 <-> unStrictlyPositiveCoin amount

-- | Preserve the supplied signed amount: positive allocates, zero declares zero,
-- and negative releases its magnitude into the first output.
declareNetDeposit :: Coin -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
declareNetDeposit netAmount topTx =
  topTx & bodyTxL . netUTxODepositChangeTxBodyL .~ netDepositDeclaration netAmount

-- | Construct a declaration from a signed net amount: positive allocates, zero
-- explicitly declares zero, and negative releases its positive magnitude into
-- TopTx's output zero. The caller supplies the amount; this does not calculate it.
netDepositDeclaration :: Coin -> TopTx.TopTxUTxODepositDeclaration
netDepositDeclaration (Coin netAmount)
  | netAmount > 0 = TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount netAmount
  | netAmount < 0 =
      TopTx.DeclaresNetUTxODepositRelease
        (positiveAmount $ negate netAmount)
        (TopTx.TopTxSettlementOutput $ TxIx 0)
  | otherwise = TopTx.DeclaresZeroNetUTxODeposit
