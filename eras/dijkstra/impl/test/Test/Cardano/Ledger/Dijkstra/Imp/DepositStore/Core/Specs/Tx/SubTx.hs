{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

-- | Release scenarios for one or several SubTxs. These describe inputs to fund;
-- no live UTxO or deposit record is invented by a generator.
-- Releases describe the proposed ordinary transaction. Rejection and accepted
-- phase-2 failure do not apply these ordinary releases.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx (
  module Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx,
  Source (..),
  SingleSourceScenario (..),
  ReleaseScenario (..),
  oneSubTxReleasingDepositIntoOwnOutput,
  severalSubTxsReleasingDeposits,
  onlySomeSubTxsReleasingDeposits,
  topTxAndSeveralSubTxsReleasingDeposits,
  oneSubTxWithEqualAllocationsAndReleases,
  severalSubTxsWithEqualAllocationsAndReleases,
  onlySomeSubTxsWithEqualAllocationsAndReleases,
  topTxAndSubTxsWithEqualAllocationsAndReleases,
  sourceApplicationCoins,
  count,
  declarationsByInput,
  declaredNetDeposits,
  allocatedDeposits,
  releasedDeposits,
  spendingInputs,
  storeBackedInputs,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.UTxOs.Deposit.SubTx
import Cardano.Ledger.StrictlyPositiveCoin (unStrictlyPositiveCoin)
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (Val ((<->)))
import Data.Foldable (toList)
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger, elements, shuffle, vectorOf)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Store (
  liveOutputStore,
  recordedAmounts,
 )
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release (
  SingleSourceScenario (..),
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release as Release
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as TopTx
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Release as Context

-- | A source output's form determines whether consumption releases a Store deposit.
data Source = StoreBackedSource Coin | ImplicitSource Coin
  deriving (Eq, Show)

-- | Optional TopTx source, followed by the sources consumed by each SubTx in order.
-- Each child consumes one distinct funded occurrence, even when amounts repeat.
data ReleaseScenario = ReleaseScenario
  { topTxSource :: Maybe Coin
  , subTxSources :: [Source]
  }
  deriving (Show)

-- | One SubTx releases its deposit into its own output. Vary its source's
-- application ADA and one to three unrelated sources, each between 10 and 20 ADA.
-- TopTx has no own Store operations; the fixture creates only implicit outputs.
oneSubTxReleasingDepositIntoOwnOutput :: Gen SingleSourceScenario
oneSubTxReleasingDepositIntoOwnOutput = Release.oneBodyReleasingDepositIntoOwnOutput

-- | Several SubTxs release their deposits. Two to five children each consume a
-- distinct store-backed source; TopTx has no Store operations of its own. The fixture
-- creates only implicit ordinary outputs and proposes each child's local release.
-- Repeated application amounts exercise equal declarations at distinct inputs.
severalSubTxsReleasingDeposits :: Gen ReleaseScenario
severalSubTxsReleasingDeposits = do
  childCount <- chooseInt (2, 5)
  amounts <- sourceAmounts childCount
  pure $ ReleaseScenario Nothing $ map StoreBackedSource amounts

-- | Only some SubTxs release Store deposits. Among two to five children, mix at
-- least one store-backed and one implicit source, varying their positions. TopTx
-- has no Store operations; the fixture creates only implicit ordinary outputs, so
-- only children consuming store-backed outputs need a deposit declaration.
onlySomeSubTxsReleasingDeposits :: Gen ReleaseScenario
onlySomeSubTxsReleasingDeposits = do
  childCount <- chooseInt (2, 5)
  storeBackedCount <- chooseInt (1, childCount - 1)
  amounts <- sourceAmounts childCount
  sources <-
    shuffle $
      map StoreBackedSource (take storeBackedCount amounts)
        <> map ImplicitSource (drop storeBackedCount amounts)
  pure $ ReleaseScenario Nothing sources

-- | TopTx and several SubTxs release deposits. TopTx and each of two to five children
-- consume separate store-backed sources. The fixture creates only implicit ordinary
-- outputs: each body proposes its own local release, and TopTx declares their total.
topTxAndSeveralSubTxsReleasingDeposits :: Gen ReleaseScenario
topTxAndSeveralSubTxsReleasingDeposits = do
  scenario <- severalSubTxsReleasingDeposits
  amount <- applicationAmount
  pure $ scenario {topTxSource = Just amount}

-- | One SubTx consumes and recreates a store-backed source with equal positive
-- allocation and release. The zero-net fixture preserves the exact funded output
-- and verifies both amounts from output pricing and the source's Store record.
-- TopTx has no Store operations of its own.
oneSubTxWithEqualAllocationsAndReleases :: Gen ReleaseScenario
oneSubTxWithEqualAllocationsAndReleases = do
  amount <- applicationAmount
  pure $ ReleaseScenario Nothing [StoreBackedSource amount]

-- | Two to five SubTxs each consume and recreate their own store-backed source.
-- The zero-net fixture checks equal positive allocation and release separately
-- for every child, including children with repeated application amounts.
severalSubTxsWithEqualAllocationsAndReleases :: Gen ReleaseScenario
severalSubTxsWithEqualAllocationsAndReleases = severalSubTxsReleasingDeposits

-- | Mix active zero-net and inactive implicit-only children in varying positions.
-- Each active child consumes and recreates a store-backed source; each inactive
-- child consumes and recreates an implicit source, allocating and releasing zero.
onlySomeSubTxsWithEqualAllocationsAndReleases :: Gen ReleaseScenario
onlySomeSubTxsWithEqualAllocationsAndReleases = onlySomeSubTxsReleasingDeposits

-- | TopTx and two to five SubTxs each consume and recreate a distinct store-backed
-- source. The zero-net fixture verifies positive equal allocation and release for
-- TopTx's own operations and for every child's operations independently.
topTxAndSubTxsWithEqualAllocationsAndReleases :: Gen ReleaseScenario
topTxAndSubTxsWithEqualAllocationsAndReleases = topTxAndSeveralSubTxsReleasingDeposits

sourceApplicationCoins :: Source -> Coin
sourceApplicationCoins (StoreBackedSource amount) = amount
sourceApplicationCoins (ImplicitSource amount) = amount

sourceAmounts :: Int -> Gen [Coin]
sourceAmounts sourceCount = do
  repeatAmount <- elements [False, True]
  if repeatAmount
    then replicate sourceCount <$> applicationAmount
    else vectorOf sourceCount applicationAmount

applicationAmount :: Gen Coin
applicationAmount = Coin <$> chooseInteger (10_000_000, 20_000_000)

-- | Number of SubTx bodies carried by the transaction, including undeclared ones.
count :: Tx TopTx DijkstraEra -> Int
count tx = length (tx ^. bodyTxL . subTransactionsTxBodyL)

-- | Associate each child's ordinary inputs with that child's actual declaration.
-- Distinct inputs retain repeated declaration values, making ownership observable.
declarationsByInput :: Tx TopTx DijkstraEra -> Map.Map TxIn SubTxUTxODepositDeclaration
declarationsByInput tx =
  Map.fromList
    [ (input, subTx ^. bodyTxL . subTxNetUTxODepositChangeTxBodyL)
    | subTx <- toList (tx ^. bodyTxL . subTransactionsTxBodyL)
    , input <- Set.toList (subTx ^. bodyTxL . inputsTxBodyL)
    ]

-- | Signed declared amounts in child order. Absence remains distinct from zero.
-- Delegation preserves the declared amount's sign; this is not a contribution sum.
declaredNetDeposits :: Tx TopTx DijkstraEra -> [Maybe Coin]
declaredNetDeposits tx =
  map (declaredNetDeposit . (^. bodyTxL . subTxNetUTxODepositChangeTxBodyL)) $
    toList (tx ^. bodyTxL . subTransactionsTxBodyL)

-- | Read allocation as positive and release as negative, including delegated forms.
declaredNetDeposit :: SubTxUTxODepositDeclaration -> Maybe Coin
declaredNetDeposit NoUTxODepositDeclaration = Nothing
declaredNetDeposit DeclaresZeroNetUTxODeposit = Just mempty
declaredNetDeposit (DeclaresNetUTxODepositAllocation amount) = Just $ unStrictlyPositiveCoin amount
declaredNetDeposit (RequestsUTxODepositFromTopTx amount) = Just $ unStrictlyPositiveCoin amount
declaredNetDeposit (DeclaresNetUTxODepositRelease amount _) = Just $ Coin 0 <-> unStrictlyPositiveCoin amount

-- | Independently priced allocations for each SubTx in transaction order.
-- Implicit outputs allocate zero; declarations do not influence these amounts.
allocatedDeposits :: Context.ReleaseTx -> [Coin]
allocatedDeposits context =
  [ foldMap (TopTx.outputDeposit parameters) (subTx ^. bodyTxL . outputsTxBodyL)
  | subTx <- OMap.elems $ Context.unsignedTx context ^. bodyTxL . subTransactionsTxBodyL
  , let parameters = TopTx.protocolParameters $ Context.ledgerState context
  ]

-- | Recorded releases for each SubTx in transaction order. Implicit inputs have
-- no Store record and contribute zero. Repeated amounts remain separate entries;
-- declarations and unrelated Store allocations do not influence these amounts.
releasedDeposits :: Context.ReleaseTx -> [Coin]
releasedDeposits context =
  [ foldMap id $ Map.restrictKeys records (subTx ^. bodyTxL . inputsTxBodyL)
  | subTx <- OMap.elems $ Context.unsignedTx context ^. bodyTxL . subTransactionsTxBodyL
  , let records = recordedAmounts $ liveOutputStore $ TopTx.utxoState $ Context.ledgerState context
  ]

-- | Original ordinary input references, grouped in SubTx order. Each generated
-- spending SubTx owns one distinct source, so iterating this list tests every
-- child's declaration independently, including children with equal deposits.
spendingInputs :: Context.ReleaseTx -> [TxIn]
spendingInputs context =
  concatMap (Set.toList . (^. bodyTxL . inputsTxBodyL)) $
    OMap.elems $
      Context.unsignedTx context ^. bodyTxL . subTransactionsTxBodyL

-- | Child-owned ordinary inputs with actual Store allocation records, retaining
-- child order. Implicit inputs are excluded; declarations do not determine which
-- children are active, so an absent declaration cannot conceal a recorded release.
storeBackedInputs :: Context.ReleaseTx -> [TxIn]
storeBackedInputs context =
  let records = recordedAmounts $ liveOutputStore $ TopTx.utxoState $ Context.ledgerState context
   in filter (`Map.member` records) $ spendingInputs context
