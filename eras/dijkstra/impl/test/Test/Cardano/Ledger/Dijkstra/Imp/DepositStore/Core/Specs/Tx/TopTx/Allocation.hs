{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

-- | Allocation scenarios with no Store deposits to release.
-- The spec supplies the declaration; preparation supplies implicit funding inputs.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx.Allocation (
  module Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx,
  AllocationScenario (..),
  AllocationBatchScenario (..),
  AllocationTx (..),
  standaloneTopTxAllocatingDeposits,
  topTxAndSubTxAllocatingDeposits,
  createdOutputs,
  allocatedDeposits,
  subTxAllocatedDeposits,
  addDeclaration,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.UTxOs.Deposit.TopTx
import Cardano.Ledger.Val (inject)
import qualified Data.OMap.Strict as OMap
import Lens.Micro
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger, shuffle, vectorOf)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration (Declarations (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Output (OutputVariant (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release (createdOrdinaryOutputs)
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.TopTx as TopTx

-- | Ordered output forms and their application ADA amounts. At least one output
-- is store-backed; the others may be implicit. There are no SubTxs.
newtype AllocationScenario = AllocationScenario [(OutputVariant, Coin)]
  deriving (Show)

-- | One TopTx and one SubTx each create at least one store-backed output.
-- Both output plans vary independently; all funding inputs remain implicit.
data AllocationBatchScenario = AllocationBatchScenario
  { topTxAllocation :: AllocationScenario
  , subTxAllocation :: AllocationScenario
  }
  deriving (Show)

-- | An undeclared or explicitly declared proposal with the pricing parameters
-- used to calculate its required allocations. Building supplies implicit inputs.
data AllocationTx = AllocationTx
  { protocolParameters :: PParams DijkstraEra
  , unsignedTx :: Tx TopTx DijkstraEra
  }
  deriving (Show)

-- | Generate one to five outputs, including at least one store-backed output.
-- Vary application amounts, store-backed counts and positions among implicit
-- outputs. The same scenarios support an exact declaration or its omission.
standaloneTopTxAllocatingDeposits :: Gen AllocationScenario
standaloneTopTxAllocatingDeposits = do
  outputCount <- chooseInt (1, 5)
  storeBackedCount <- chooseInt (1, outputCount)
  variants <-
    shuffle $
      replicate storeBackedCount StoreBackedOutput
        <> replicate (outputCount - storeBackedCount) ImplicitOutput
  amounts <- vectorOf outputCount $ Coin <$> chooseInteger (10_000_000, 20_000_000)
  pure $ AllocationScenario $ zip variants amounts

-- | Independently generate the parent's and child's own allocations, varying
-- application amounts and the number and position of store-backed outputs.
topTxAndSubTxAllocatingDeposits :: Gen AllocationBatchScenario
topTxAndSubTxAllocatingDeposits =
  AllocationBatchScenario <$> standaloneTopTxAllocatingDeposits <*> standaloneTopTxAllocatingDeposits

-- | Give each generated output a real key address without changing its form or
-- application amount. Store deposits remain external to these output values.
createdOutputs :: Addr -> AllocationScenario -> [TxOut DijkstraEra]
createdOutputs address (AllocationScenario outputs) = map (createdOutput address) outputs

createdOutput :: Addr -> (OutputVariant, Coin) -> TxOut DijkstraEra
createdOutput address (ImplicitOutput, amount) =
  mkBasicTxOutWithImplicitDeposit address $ inject amount
createdOutput address (StoreBackedOutput, amount) =
  mkBasicTxOutWithStoreBackedDeposit address $ ApplicationAssets $ inject amount

-- | Sum the independently priced deposits across TopTx and all SubTx outputs.
-- Implicit outputs contribute zero. This calculation does not inspect declarations.
allocatedDeposits :: AllocationTx -> Coin
allocatedDeposits proposal =
  foldMap (TopTx.outputDeposit $ protocolParameters proposal) $
    createdOrdinaryOutputs $
      unsignedTx proposal

-- | Required allocations for each ordered SubTx's own outputs. The parent total
-- includes these contributions; each child declares only its own contribution.
subTxAllocatedDeposits :: AllocationTx -> [Coin]
subTxAllocatedDeposits proposal =
  map
    (foldMap (TopTx.outputDeposit $ protocolParameters proposal) . (^. bodyTxL . outputsTxBodyL))
    (OMap.elems $ unsignedTx proposal ^. bodyTxL . subTransactionsTxBodyL)

-- | Attach exactly the supplied declarations, preserving every output and input.
-- A declaration-count mismatch is a fixture error, never a reason to drop a child.
addDeclaration :: Declarations -> AllocationTx -> AllocationTx
addDeclaration (Declarations declaration childDeclarations) proposal =
  let tx = unsignedTx proposal
      children = OMap.elems $ tx ^. bodyTxL . subTransactionsTxBodyL
      declaredChildren =
        zipWith
          (\childDeclaration child -> child & bodyTxL . subTxNetUTxODepositChangeTxBodyL .~ childDeclaration)
          childDeclarations
          children
   in if length children /= length childDeclarations
        then error "Allocation declarations require one declaration for every SubTx"
        else
          proposal
            { unsignedTx =
                tx
                  & bodyTxL . netUTxODepositChangeTxBodyL .~ declaration
                  & bodyTxL . subTransactionsTxBodyL .~ OMap.fromFoldable declaredChildren
            }
