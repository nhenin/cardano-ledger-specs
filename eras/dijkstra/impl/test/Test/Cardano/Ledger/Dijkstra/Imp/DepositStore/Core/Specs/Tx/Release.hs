{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NumericUnderscores #-}

-- | Release scenarios and transaction input/output observations.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Release (
  SingleSourceScenario (..),
  CollateralScenario (..),
  CollateralStoreOperations (..),
  collateralOnlyStoreOperations,
  oneBodyReleasingDepositIntoOwnOutput,
  ordinarySpendingInputs,
  createdOrdinaryOutputs,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.TxIn (TxIn)
import Data.Foldable (toList)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Lens.Micro ((^.))
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger, vectorOf)
import Test.Cardano.Ledger.Core.Utils (txInAt)

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

-- | One store-backed source and unrelated sources that remain live.
-- Real funding determines their recorded deposits; the generator supplies only ADA.
data SingleSourceScenario = SingleSourceScenario
  { inputApplicationCoins :: Coin
  , unrelatedApplicationCoins :: [Coin]
  }
  deriving (Show)

-- | One body proposes a release into its own implicit output. Vary its source's
-- application ADA and one to three unrelated sources, each between 10 and 20 ADA.
-- The caller chooses TopTx or SubTx; generation applies no ledger effects.
oneBodyReleasingDepositIntoOwnOutput :: Gen SingleSourceScenario
oneBodyReleasingDepositIntoOwnOutput = do
  inputAmount <- applicationAmount
  unrelatedCount <- chooseInt (1, 3)
  unrelatedAmounts <- vectorOf unrelatedCount applicationAmount
  pure $ SingleSourceScenario inputAmount unrelatedAmounts

applicationAmount :: Gen Coin
applicationAmount = Coin <$> chooseInteger (10_000_000, 20_000_000)

-- | Which collateral fields carry Store deposits. Every variant excludes Store
-- operations from ordinary inputs and outputs.
data CollateralStoreOperations
  = StoreBackedInputOnly
  | StoreBackedReturnOnly
  | StoreBackedInputAndReturn
  deriving (Eq, Show)

-- | A collateral-only proposal. Application amounts are separate from any
-- recorded or newly priced deposit. The script's actual result matches its flag.
data CollateralScenario = CollateralScenario
  { collateralInputCoins :: Coin
  , collateralReturnCoins :: Coin
  , collateralStoreOperations :: CollateralStoreOperations
  , collateralPhase2Validity :: IsPhase2Valid
  }
  deriving (Show)

-- | Generate application amounts, then exercise every Store placement on both
-- real script paths. At least five ADA remain to cover extra return storage and
-- the collateral minimum; this property tests declaration scope, not fee bounds.
collateralOnlyStoreOperations :: Gen [CollateralScenario]
collateralOnlyStoreOperations = do
  inputCoins <- Coin <$> chooseInteger (13_000_000, 20_000_000)
  returnCoins <- Coin <$> chooseInteger (5_000_000, 8_000_000)
  pure
    [ CollateralScenario inputCoins returnCoins operations validity
    | operations <- [StoreBackedInputOnly, StoreBackedReturnOnly, StoreBackedInputAndReturn]
    , validity <- [Phase2Valid, Phase2Invalid]
    ]
