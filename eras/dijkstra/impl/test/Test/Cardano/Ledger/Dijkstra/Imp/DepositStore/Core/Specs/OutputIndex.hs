-- | Output-index generators shared by TopTx and SubTx declaration grammar.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.OutputIndex (
  negativeOutputIndex,
  overflowingOutputIndex,
) where

import Test.Cardano.Ledger.Common (Gen, Positive (..), arbitrary, frequency)

-- | Include the first negative index frequently and vary the negative magnitude
-- without a fixed lower bound. Every result is below the Word16 minimum, 0.
negativeOutputIndex :: Gen Integer
negativeOutputIndex =
  frequency
    [ (1, pure (-1))
    , (3, negate . getPositive <$> arbitrary)
    ]

-- | Include the first overflowing index frequently and vary the excess without
-- a fixed upper bound. Every result exceeds the Word16 maximum, 65535.
overflowingOutputIndex :: Gen Integer
overflowingOutputIndex =
  frequency
    [ (1, pure 65536)
    , (3, (65535 +) . getPositive <$> arbitrary)
    ]
