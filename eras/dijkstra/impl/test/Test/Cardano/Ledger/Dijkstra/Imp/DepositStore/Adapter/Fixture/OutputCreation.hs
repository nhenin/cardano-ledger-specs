-- | Output shapes for the creation part of DS-TX-001. Store-backed outputs
-- describe a presence-check input, not a funded capacity deposit allocation.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Adapter.Fixture.OutputCreation (
  OutputVariant (..),
  CreatedOutputs (..),
  TxOutputs (..),
  storeBackedOutputCases,
  implicitOutputCases,
) where

import Cardano.Ledger.Address (Addr)
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.SubTx as SubTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Test.Cardano.Ledger.Common (Gen, arbitrary, chooseInt, elements, vectorOf)
import Test.Cardano.Ledger.Core.Arbitrary ()

data OutputVariant = ImplicitOutput | StoreBackedOutput
  deriving (Eq, Show)

data CreatedOutputs = CreatedOutputs
  { outputAddress :: Addr
  , outputVariants :: [OutputVariant]
  }
  deriving (Show)

-- | A TopTx's declaration and own outputs, followed by each SubTx's declaration
-- and own outputs. An empty SubTx list means the batch has no SubTxs.
data TxOutputs
  = TxOutputs
      TopTx.TopTxUTxODepositDeclaration
      [OutputVariant]
      [(SubTx.SubTxUTxODepositDeclaration, [OutputVariant])]
  deriving (Show)

-- | Every sample includes a single store-backed output at each position among
-- implicit outputs, an entirely store-backed sequence, and a random mixture
-- containing at least one store-backed output. Vary the address and length.
storeBackedOutputCases :: Gen [CreatedOutputs]
storeBackedOutputCases = do
  address <- arbitrary
  count <- chooseInt (1, 5)
  mixture <- vectorOf count $ elements [ImplicitOutput, StoreBackedOutput]
  pure $
    [ CreatedOutputs address $
        replicate position ImplicitOutput
          <> [StoreBackedOutput]
          <> replicate (count - position - 1) ImplicitOutput
    | position <- [0 .. count - 1]
    ]
      <> [ CreatedOutputs address (replicate count StoreBackedOutput)
         , CreatedOutputs address (StoreBackedOutput : mixture)
         ]

-- | Cover empty output sequences as well as nonempty implicit-only sequences.
implicitOutputCases :: Gen [CreatedOutputs]
implicitOutputCases = do
  address <- arbitrary
  count <- chooseInt (1, 5)
  pure [CreatedOutputs address [], CreatedOutputs address (replicate count ImplicitOutput)]
