{-# LANGUAGE NumericUnderscores #-}

-- | Generated Store operation plans. One unit is one ADA of independently priced
-- allocation or recorded release; declarations are supplied visibly by each spec.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Accounting (
  BodyOperations (..),
  AccountingScenario (..),
  bodyOperations,
  scenario,
  arbitraryScenario,
  depositUnit,
) where

import Cardano.Ledger.Coin (Coin (..))
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger, vectorOf)

-- | Counts of new and consumed Store-backed outputs for one body. Each count
-- refers to distinct outputs, even when their deposit amounts are equal.
-- Translation applies to the body's separate implicit funding input.
data BodyOperations = BodyOperations
  { allocatedDepositUnits :: Int
  , releasedDepositUnits :: Int
  , sourceTranslation :: Bool
  , emptyApplicationAssets :: Bool
  }
  deriving (Eq, Show)

-- | Parent and ordered child operations, plus generous independently generated
-- application ADA. All bodies receive distinct funded inputs.
data AccountingScenario = AccountingScenario
  { topOperations :: BodyOperations
  , subOperations :: [BodyOperations]
  , applicationCoins :: Coin
  }
  deriving (Show)

-- | Request allocations and releases with ordinary Dijkstra implicit funding
-- and nonempty application ADA in newly created Store-backed outputs.
bodyOperations :: Int -> Int -> BodyOperations
bodyOperations allocated released = BodyOperations allocated released False False

-- | Generate application ADA while preserving the operation relationship chosen
-- by the spec. Counts determine the deposit amounts, never the declarations.
scenario :: BodyOperations -> [BodyOperations] -> Gen AccountingScenario
scenario top children = AccountingScenario top children . Coin <$> chooseInteger (200_000_000, 210_000_000)

-- | Independently vary allocations and releases for TopTx and one to four SubTxs.
-- Zero, positive and negative changes occur without filtering the generated data.
arbitraryScenario :: Gen AccountingScenario
arbitraryScenario = do
  childCount <- chooseInt (1, 4)
  top <- arbitraryBodyOperations
  children <- vectorOf childCount arbitraryBodyOperations
  scenario top children

-- | Independently choose zero through three recorded releases and new allocations.
arbitraryBodyOperations :: Gen BodyOperations
arbitraryBodyOperations = bodyOperations <$> chooseInt (0, 3) <*> chooseInt (0, 3)

-- | Every Store-backed output in these fixtures has a deposit of exactly one ADA.
depositUnit :: Coin
depositUnit = Coin 1_000_000
