{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

-- | Generated settlement-output boundaries and balanced application-coin mutations.
-- Declarations belong to the specification. Every mutation moves the displaced ADA
-- to a distinct implicit TopTx output and preserves the selected output's Store price.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Settlement.OutputCoin (
  Body (..),
  Form (..),
  Scenario (..),
  implicitRelease,
  storeBackedRelease,
  anyRelease,
  smallerTopTxShare,
  largerTopTxShare,
  fund,
  outputIndex,
  requiredSettlement,
  childNetChange,
  selectedExternalDeposit,
  setOutputCoins,
  redistributeOutputCoins,
  validateOutputCoins,
  insufficientOutputFailure,
) where

import Cardano.Ledger.BaseTypes (TxIx (..), txIxToInt)
import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.Rules (
  DepositStoreAccountingFailure (..),
  validateSettlementOutput,
 )
import Cardano.Ledger.Val ((<->))
import Data.Foldable (toList)
import Data.List.NonEmpty (NonEmpty)
import Data.Maybe (listToMaybe)
import qualified Data.OMap.Strict as OMap
import qualified Data.Sequence.Strict as SSeq
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt, elements)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting as Accounting
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.Balance as Balance
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting.TopTx as Parent
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx as Children
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as Pricing
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release (ReleaseTx (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Accounting (
  fundAccountingScenario,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Submission.Balance (
  observeBalance,
  resignTx,
 )
import Test.Cardano.Ledger.Dijkstra.ImpTest (ImpTestM)
import Test.Cardano.Ledger.Imp.Common (expectJust, shouldBe)
import Validation (Validation)

-- | Owner of the selected ordinary output; every scenario has at most one child.
data Body = TopTxBody | SubTxBody deriving (Eq, Show)

-- | Application ADA is read identically from either output form. A Store-backed
-- output also creates an external deposit that cannot satisfy its application bound.
data Form = Implicit | StoreBacked deriving (Eq, Show)

-- | Operation counts determine exact required deposits independently of declarations.
data Scenario = Scenario
  { body :: Body
  , form :: Form
  , operations :: Accounting.AccountingScenario
  }
  deriving (Show)

-- | Either body releases deposits into implicit output zero. Required amounts
-- exceed the implicit minimum, including a one-lovelace deficit at the boundary.
implicitRelease :: Gen Scenario
implicitRelease = release Implicit

-- | Either body creates one Store-backed output while consuming more recorded
-- deposits. Output one is selected; output zero remains implicit funding/change.
storeBackedRelease :: Gen Scenario
storeBackedRelease = release StoreBacked

-- | Both body levels and both destination variants participate in generated cases.
anyRelease :: Gen Scenario
anyRelease = elements [Implicit, StoreBacked] >>= release

-- | Two to four ADA are released net. Independent funding varies transaction ids.
release :: Form -> Gen Scenario
release outputForm = do
  owner <- elements [TopTxBody, SubTxBody]
  released <- chooseInt (3, 5)
  let allocated = if outputForm == StoreBacked then 1 else 0
      releasing = Accounting.bodyOperations allocated released
  plan <- case owner of
    TopTxBody -> Accounting.scenario releasing []
    SubTxBody -> Accounting.scenario (Accounting.bodyOperations 0 0) [releasing]
  pure $ Scenario owner outputForm plan

-- | Both parent and child release locally. The parent's own positive share is
-- strictly smaller than the complete batch release declared by TopTx.
smallerTopTxShare :: Gen Scenario
smallerTopTxShare = do
  parent <- chooseInt (2, 4)
  child <- chooseInt (1, 3)
  Scenario TopTxBody Implicit
    <$> Accounting.scenario
      (Accounting.bodyOperations 0 parent)
      [Accounting.bodyOperations 0 child]

-- | Parent releases enough to fund a locally accounted child allocation, leaving
-- a positive batch release smaller than the parent's own settlement requirement.
largerTopTxShare :: Gen Scenario
largerTopTxShare = do
  batch <- chooseInt (2, 4)
  child <- chooseInt (1, 3)
  Scenario TopTxBody Implicit
    <$> Accounting.scenario
      (Accounting.bodyOperations 0 (batch + child))
      [Accounting.bodyOperations child 0]

-- | Fund actual Store records, then append a distinct implicit parent output for
-- redistribution. The original output zero and optional Store output one retain
-- their indices. All declarations remain absent for the calling specification.
fund :: Scenario -> ImpTestM DijkstraEra ReleaseTx
fund generated = do
  proposal <- fundAccountingScenario $ operations generated
  firstOutput <- expectJust . listToMaybe . toList $ unsignedTx proposal ^. bodyTxL . outputsTxBodyL
  let surplus = firstOutput & coinTxOutL .~ Coin 10_000_000
  pure
    proposal
      { unsignedTx = unsignedTx proposal & bodyTxL . outputsTxBodyL %~ (<> SSeq.singleton surplus)
      }

-- | The funded body has implicit output zero and, when requested, Store output one.
outputIndex :: Scenario -> TxIx
outputIndex generated = if form generated == Implicit then TxIx 0 else TxIx 1

-- | Independently required local release of the selected body, based on its own
-- new output prices and recorded input allocations. Child changes remain local.
requiredSettlement :: Scenario -> ReleaseTx -> Coin
requiredSettlement generated proposal =
  Coin 0 <-> case body generated of
    TopTxBody -> Parent.ownNetDeposit proposal
    SubTxBody -> childNetChange proposal

-- | Actual own net change of the sole child, or zero for a standalone parent.
childNetChange :: ReleaseTx -> Coin
childNetChange proposal =
  foldMap id $
    zipWith (<->) (Children.allocatedDeposits proposal) (Children.releasedDeposits proposal)

-- | Price the selected new output independently. Implicit outputs contribute zero.
selectedExternalDeposit :: Scenario -> ReleaseTx -> Coin
selectedExternalDeposit generated proposal =
  Pricing.outputDeposit (Pricing.protocolParameters $ ledgerState proposal) $
    selectedOutput generated $
      unsignedTx proposal

-- | Read the selected body's own output, rejecting fixture index mistakes.
selectedOutput :: Scenario -> Tx TopTx DijkstraEra -> TxOut DijkstraEra
selectedOutput generated tx =
  case drop (txIxToInt $ outputIndex generated) $ selectedOutputs generated tx of
    output : _ -> output
    [] -> error "OutputCoin fixture selects an absent output"

-- | Read own outputs without mixing parent and child output namespaces.
selectedOutputs :: Scenario -> Tx TopTx DijkstraEra -> [TxOut DijkstraEra]
selectedOutputs generated tx = case body generated of
  TopTxBody -> toList $ tx ^. bodyTxL . outputsTxBodyL
  SubTxBody -> toList $ onlyChild tx ^. bodyTxL . outputsTxBodyL

-- | The body-level cases require exactly one child when selecting SubTx.
onlyChild :: Tx TopTx DijkstraEra -> Tx SubTx DijkstraEra
onlyChild tx = case OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL of
  [child] -> child
  _ -> error "OutputCoin fixture requires exactly one SubTx"

-- | Change application ADA only. This pure operation is also used by the isolated
-- lower-bound property, which does not claim complete transaction validity.
setOutputCoins :: Scenario -> Coin -> Tx TopTx DijkstraEra -> Tx TopTx DijkstraEra
setOutputCoins generated supplied tx = case body generated of
  TopTxBody -> tx & bodyTxL . outputsTxBodyL %~ changeCoinsAt (outputIndex generated) supplied
  SubTxBody ->
    tx
      & bodyTxL
        . subTransactionsTxBodyL
        .~ OMap.fromFoldable
          [onlyChild tx & bodyTxL . outputsTxBodyL %~ changeCoinsAt (outputIndex generated) supplied]

-- | Replace the application ADA at one existing position; retain form and other assets.
changeCoinsAt ::
  TxIx -> Coin -> SSeq.StrictSeq (TxOut DijkstraEra) -> SSeq.StrictSeq (TxOut DijkstraEra)
changeCoinsAt index supplied outputs =
  SSeq.fromList
    [ if position == txIxToInt index then output & coinTxOutL .~ supplied else output
    | (position, output) <- zip [0 ..] $ toList outputs
    ]

-- | Move the selected output's surplus/deficit to a separate implicit TopTx output,
-- then re-sign without fee or value fixup. Check unchanged Store pricing and exact
-- complete balance so a negative case isolates the settlement bound.
redistributeOutputCoins ::
  Scenario -> ReleaseTx -> Coin -> Tx TopTx DijkstraEra -> ImpTestM DijkstraEra (Tx TopTx DijkstraEra)
redistributeOutputCoins generated proposal supplied tx = do
  let selected = selectedOutput generated tx
      displaced = (selected ^. coinTxOutL) <-> supplied
      recipient = length (toList $ unsignedTx proposal ^. bodyTxL . outputsTxBodyL) - 1
      updated =
        setOutputCoins generated supplied tx
          & bodyTxL
            . outputsTxBodyL
            %~ ( SSeq.fromList
                   . zipWith
                     (\position output -> if position == recipient then output & coinTxOutL <>~ displaced else output)
                     [0 ..]
                   . toList
               )
      parameters = Pricing.protocolParameters $ ledgerState proposal
  Pricing.outputDeposit parameters (selectedOutput generated updated)
    `shouldBe` Pricing.outputDeposit parameters selected
  signed <- resignTx updated
  observeBalance signed >>= \observed -> Balance.isBalanced observed `shouldBe` True
  pure signed

-- | Run the actual shared output lower-bound validator on the selected body.
-- The expected threshold comes from 'requiredSettlement', never this validator.
validateOutputCoins ::
  Scenario -> Coin -> Tx TopTx DijkstraEra -> Validation (NonEmpty DepositStoreAccountingFailure) ()
validateOutputCoins generated required tx = case body generated of
  TopTxBody -> validateSettlementOutput (tx ^. bodyTxL) (outputIndex generated) required
  SubTxBody -> validateSettlementOutput (onlyChild tx ^. bodyTxL) (outputIndex generated) required

-- | Exact ledger-facing lower-bound failure, including the final signed body id.
insufficientOutputFailure ::
  Scenario -> Coin -> Coin -> Tx TopTx DijkstraEra -> DepositStoreAccountingFailure
insufficientOutputFailure generated supplied required tx =
  InsufficientSettlementOutput
    ( case body generated of
        TopTxBody -> txIdTxBody $ tx ^. bodyTxL
        SubTxBody -> txIdTxBody $ onlyChild tx ^. bodyTxL
    )
    (outputIndex generated)
    supplied
    required
