{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE TypeApplications #-}

-- | Generated standalone transaction scenarios and queries over real ledger snapshots.
-- Scenarios describe amounts and output forms. Submission fixtures establish their
-- inputs through ordinary ledger transactions before any release is calculated.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx (
  module Cardano.Ledger.Dijkstra.UTxODeposit.TopTx,
  SpendingScenario (..),
  OutputForms (..),
  LedgerState (..),
  withoutSubTxsConsumingDeposits,
  withoutSubTxsConsumingDepositsCreatingOnlyImplicitOutputs,
  withoutSubTxsConsumingDepositsRequiringNetAllocation,
  sourceOutputs,
  createdOutputs,
  outputDeposit,
  allocatedDeposits,
  releasedDeposits,
  declareNetDeposit,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Binary (Sized (sizedSize), mkSized)
import Cardano.Ledger.Coin (Coin (..), CompactForm (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.UTxODeposit.TopTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.Shelley.LedgerState (UTxOState, utxosDepositStore)
import Cardano.Ledger.State (DepositStore (..))
import Cardano.Ledger.Val (inject)
import qualified Data.Map.Strict as Map
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger, elements, vectorOf)
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
data SpendingScenario = SpendingScenario
  { consumedApplicationAmounts :: [Coin]
  , unrelatedApplicationAmounts :: [Coin]
  , outputForms :: OutputForms
  , createdApplicationAmounts :: [Coin]
  }
  deriving (Show)

data OutputForms = ImplicitOutputs | StoreBackedOutputs | MixedOutputs
  deriving (Eq, Show)

-- | Exercise implicit-only, store-backed-only and mixed outputs. Relative input
-- and output counts exercise net releases, zero and allocations under fixed pricing.
withoutSubTxsConsumingDeposits :: Gen SpendingScenario
withoutSubTxsConsumingDeposits =
  elements [ImplicitOutputs, StoreBackedOutputs, MixedOutputs] >>= standaloneTopTx

-- | Consume at least one recorded deposit and create one implicit output receiving
-- application ADA plus the released deposit. Ordinary fixup funds fees separately.
withoutSubTxsConsumingDepositsCreatingOnlyImplicitOutputs :: Gen SpendingScenario
withoutSubTxsConsumingDepositsCreatingOnlyImplicitOutputs = standaloneTopTx ImplicitOutputs

-- | More new store-backed outputs than consumed ones require a net allocation
-- under the fixed policy and equal-width application amounts of these scenarios.
withoutSubTxsConsumingDepositsRequiringNetAllocation :: Gen SpendingScenario
withoutSubTxsConsumingDepositsRequiringNetAllocation = do
  scenario <- standaloneTopTx StoreBackedOutputs
  amounts <- vectorOf (length (consumedApplicationAmounts scenario) + 1) applicationAmount
  pure $ scenario {createdApplicationAmounts = amounts}

standaloneTopTx :: OutputForms -> Gen SpendingScenario
standaloneTopTx forms = do
  spentCount <- chooseInt (1, 5)
  unspentCount <- chooseInt (1, 3)
  createdCount <- elements [max 1 (spentCount - 1), spentCount, spentCount + 1]
  consumed <- vectorOf spentCount applicationAmount
  unrelated <- vectorOf unspentCount applicationAmount
  created <- vectorOf createdCount applicationAmount
  pure $ SpendingScenario consumed unrelated forms created

applicationAmount :: Gen Coin
applicationAmount = Coin <$> chooseInteger (10_000_000, 20_000_000)

-- | Funding creates both consumed and unrelated outputs. Their ordering lets the
-- adapter retain unrelated inputs as a check against releasing the entire Store.
sourceOutputs :: Addr -> SpendingScenario -> [TxOut DijkstraEra]
sourceOutputs address scenario =
  map (storeBackedOutput address) $
    consumedApplicationAmounts scenario <> unrelatedApplicationAmounts scenario

-- | Output zero can receive the complete release. Other shapes retain a generous
-- application balance; normal funding supplies any shortfall without changing the
-- generated outputs or deposit declaration.
createdOutputs :: Addr -> SpendingScenario -> Coin -> [TxOut DijkstraEra]
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
outputDeposit _ (ImplicitDepositTxOut _) = mempty
outputDeposit pp output@(StoreBackedTxOut _) =
  case pp ^. ppCoinsPerUTxOByteL of
    CoinPerByte (CompactCoin price) ->
      Coin $ toInteger price * (160 + toInteger (sizedSize $ mkSized (eraProtVerLow @DijkstraEra) output))

allocatedDeposits :: LedgerState -> Tx TopTx DijkstraEra -> Coin
allocatedDeposits ledgerState topTx =
  foldMap (outputDeposit $ protocolParameters ledgerState) $ topTx ^. bodyTxL . outputsTxBodyL

-- | Read only records belonging to this transaction's ordinary inputs.
releasedDeposits :: LedgerState -> Tx TopTx DijkstraEra -> Coin
releasedDeposits ledgerState topTx =
  foldMap id $
    Map.restrictKeys
      (depositStoreAllocations $ utxosDepositStore $ utxoState ledgerState)
      (topTx ^. bodyTxL . inputsTxBodyL)

-- | Preserve the supplied signed amount: positive allocates, zero declares zero,
-- and negative releases its magnitude into the first output.
declareNetDeposit :: Coin -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
declareNetDeposit (Coin netAmount) topTx =
  topTx & bodyTxL . netUTxODepositChangeTxBodyL .~ netDepositDeclaration netAmount

netDepositDeclaration :: Integer -> TopTx.TopTxUTxODepositDeclaration
netDepositDeclaration netAmount
  | netAmount > 0 = TopTx.DeclaresNetUTxODepositAllocation $ positiveAmount netAmount
  | netAmount < 0 =
      TopTx.DeclaresNetUTxODepositRelease
        (positiveAmount $ negate netAmount)
        (TopTx.TopTxSettlementOutput $ TxIx 0)
  | otherwise = TopTx.DeclaresZeroNetUTxODeposit
