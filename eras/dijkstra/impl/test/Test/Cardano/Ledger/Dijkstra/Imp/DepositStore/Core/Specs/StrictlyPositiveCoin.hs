-- | Checked amount construction and bounds shared by DepositStore fixtures.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin (
  positiveAmountBounds,
  positiveAmount,
) where

import Cardano.Ledger.Coin (Coin (..))
import Cardano.Ledger.StrictlyPositiveCoin (StrictlyPositiveCoin, mkStrictlyPositiveCoin)
import Data.Maybe (fromMaybe)
import Data.Word (Word64)

-- | Inclusive (minimum, maximum) amounts, in lovelace.
positiveAmountBounds :: (Integer, Integer)
positiveAmountBounds = (1, toInteger (maxBound :: Word64))

-- | Construct a known-valid fixture through the public checked constructor.
positiveAmount :: Integer -> StrictlyPositiveCoin
positiveAmount = fromMaybe (error "Invalid StrictlyPositiveCoin fixture amount") . mkStrictlyPositiveCoin . Coin
