{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

-- | Generated ordinary Store operations and independent ownership observations.
-- Presence follows output constructors, even when the priced deposit is zero.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Operations (
  BodyOperations (..),
  OperationsScenario (..),
  DeclarationOwner (..),
  independentBodyOperations,
  outputWithForm,
  requiredDeclarationOwners,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.State (UTxO (..))
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val (inject)
import qualified Data.Map.Strict as Map
import qualified Data.OMap.Strict as OMap
import qualified Data.Set as Set
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger, elements, vectorOf)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (OutputVariant (..))

-- | The input and output forms of one body, with equal application ADA on each
-- side. The four combinations express no operation, allocation, release or both.
data BodyOperations = BodyOperations
  { sourceForm :: OutputVariant
  , createdForm :: OutputVariant
  , applicationCoins :: Coin
  }
  deriving (Show)

-- | Each body independently chooses its own forms. Child ownership is preserved
-- by distinct funded input references, even when amounts and forms repeat.
data OperationsScenario = OperationsScenario
  { topTxOperations :: BodyOperations
  , subTxOperations :: [BodyOperations]
  }
  deriving (Show)

-- | Identify a body whose own ordinary operations require its declaration.
-- A SubTx is selected by its original unique funded input, not its position/hash.
data DeclarationOwner = TopTxBody | SubTxBody TxIn
  deriving (Eq, Show)

-- | Generate a parent and zero to four children. Each body's source and created
-- output independently use either deposit form; vary application ADA as well.
independentBodyOperations :: Gen OperationsScenario
independentBodyOperations = do
  top <- bodyOperations
  childCount <- chooseInt (0, 4)
  children <- vectorOf childCount bodyOperations
  pure $ OperationsScenario top children

-- | Select source and created output forms independently of declaration fields.
bodyOperations :: Gen BodyOperations
bodyOperations =
  BodyOperations
    <$> elements [ImplicitOutput, StoreBackedOutput]
    <*> elements [ImplicitOutput, StoreBackedOutput]
    <*> (Coin <$> chooseInteger (10_000_000, 20_000_000))

-- | Preserve application ADA while assigning the requested deposit representation.
outputWithForm :: Addr -> OutputVariant -> Coin -> TxOut DijkstraEra
outputWithForm address ImplicitOutput amount = mkBasicTxOutWithImplicitDeposit address $ inject amount
outputWithForm address StoreBackedOutput amount =
  mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets $ inject amount

-- | Inspect every body's own ordinary inputs and outputs against the captured
-- UTxO. A StoreBackedTxOut requires presence regardless of its recorded amount.
-- This oracle does not call production presence predicates or read declarations.
requiredDeclarationOwners :: UTxO DijkstraEra -> Tx TopTx DijkstraEra -> [DeclarationOwner]
requiredDeclarationOwners utxo tx =
  [TopTxBody | requiresDeclaration utxo tx]
    <> [ SubTxBody input
       | child <- OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
       , requiresDeclaration utxo child
       , let input = sourceInput child
       ]

-- | Every generated child owns exactly one funded input. Fail on a malformed
-- fixture rather than silently omitting an active child's declaration check.
sourceInput :: Tx SubTx DijkstraEra -> TxIn
sourceInput child = case Set.toList (child ^. bodyTxL . inputsTxBodyL) of
  [input] -> input
  _ -> error "An operations fixture SubTx must retain exactly one funded input"

-- | Store-backed ordinary input or output form triggers the body's obligation.
-- Reference inputs, collateral and nested children's outputs are excluded.
requiresDeclaration :: UTxO DijkstraEra -> Tx l DijkstraEra -> Bool
requiresDeclaration (UTxO outputs) tx =
  any isStoreBacked (tx ^. bodyTxL . outputsTxBodyL)
    || any isStoreBacked (Map.restrictKeys outputs $ tx ^. bodyTxL . inputsTxBodyL)

isStoreBacked :: TxOut DijkstraEra -> Bool
isStoreBacked (StoreBackedTxOut _) = True
isStoreBacked (ImplicitDepositTxOut _) = False
