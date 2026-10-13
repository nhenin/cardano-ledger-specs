{-# LANGUAGE NumericUnderscores #-}

-- | Ordered spending scenarios for several SubTxs. These describe inputs to fund;
-- no live UTxO or deposit record is invented by a generator.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.SubTx (
  Source (..),
  SpendingScenario (..),
  severalConsumingDeposits,
  someConsumingDeposits,
  withTopTxConsumingDeposits,
  sourceApplicationCoins,
) where

import Cardano.Ledger.Coin (Coin (..))
import Test.Cardano.Ledger.Common (Gen, chooseInt, chooseInteger, elements, shuffle, vectorOf)

-- | A source output's form determines whether consumption releases a Store deposit.
data Source = StoreBackedSource Coin | ImplicitSource Coin
  deriving (Eq, Show)

-- | Optional TopTx source, followed by the sources consumed by each SubTx in order.
-- Each child consumes one distinct funded occurrence, even when amounts repeat.
data SpendingScenario = SpendingScenario
  { topTxSource :: Maybe Coin
  , subTxSources :: [Source]
  }
  deriving (Show)

-- | Two to five SubTxs each release their own recorded deposit locally. Repeated
-- application amounts deliberately exercise equal declarations at distinct inputs.
severalConsumingDeposits :: Gen SpendingScenario
severalConsumingDeposits = do
  count <- chooseInt (2, 5)
  amounts <- sourceAmounts count
  pure $ SpendingScenario Nothing $ map StoreBackedSource amounts

-- | Mix at least one store-backed and one implicit source, varying their positions.
-- Only children consuming store-backed outputs need a deposit declaration.
someConsumingDeposits :: Gen SpendingScenario
someConsumingDeposits = do
  count <- chooseInt (2, 5)
  storeBackedCount <- chooseInt (1, count - 1)
  amounts <- sourceAmounts count
  sources <-
    shuffle $
      map StoreBackedSource (take storeBackedCount amounts)
        <> map ImplicitSource (drop storeBackedCount amounts)
  pure $ SpendingScenario Nothing sources

-- | TopTx and at least two SubTxs consume separate store-backed sources. The parent
-- declares the total while each body settles its own released deposit locally.
withTopTxConsumingDeposits :: Gen SpendingScenario
withTopTxConsumingDeposits = do
  scenario <- severalConsumingDeposits
  amount <- applicationAmount
  pure $ scenario {topTxSource = Just amount}

sourceApplicationCoins :: Source -> Coin
sourceApplicationCoins (StoreBackedSource amount) = amount
sourceApplicationCoins (ImplicitSource amount) = amount

sourceAmounts :: Int -> Gen [Coin]
sourceAmounts count = do
  repeatAmount <- elements [False, True]
  if repeatAmount
    then replicate count <$> applicationAmount
    else vectorOf count applicationAmount

applicationAmount :: Gen Coin
applicationAmount = Coin <$> chooseInteger (10_000_000, 20_000_000)
