{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

-- | TopTx declarations used by the specifications: operation forms, generators
-- and raw decoder inputs. Generated samples retain every required form or defect;
-- local indices describe representation and do not require transaction outputs.
module Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.Tx.Declaration.TopTx (
  module Cardano.Ledger.Dijkstra.UTxODeposit.TopTx,
  allDeclarations,
  onlyExplicitDeclarations,
  localReleaseSettlementWithIndex,
  declarationsAtBounds,
  allDeclarationsWithAmount,
  absentAndExplicitZero,
  allDeclarationInputsWithAmount,
  declarationsWithInvalidStructure,
  releaseSettlementsWithInvalidStructure,
  negativeOutputIndex,
  overflowingOutputIndex,
) where

import Cardano.Ledger.BaseTypes (TxIx (..))
import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Dijkstra.Core
import Cardano.Ledger.Dijkstra.UTxODeposit.TopTx
import qualified Cardano.Ledger.Dijkstra.UTxODeposit.TopTx as TopTx
import Cardano.Ledger.StrictlyPositiveCoin (StrictlyPositiveCoin)
import qualified Data.Aeson as Aeson
import Data.Word (Word64)
import Lens.Micro ((&), (.~))
import Test.Cardano.Ledger.Binary.Plain.Golden (Enc (..))
import Test.Cardano.Ledger.Common (Gen, arbitrary, choose, chooseInteger, elements, listOf1)
import Test.Cardano.Ledger.Core.Arbitrary ()
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding (DecoderInputs (..))
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Encoding.CBOR (cborList)
import Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.OutputIndex (
  negativeOutputIndex,
  overflowingOutputIndex,
 )
import qualified Test.Cardano.Ledger.Dijkstra.Imp.DepositStore.Core.Specs.StrictlyPositiveCoin as StrictlyPositiveCoin

-- | All TopTx declaration forms for the supplied amount and settlement output
-- index: absence, explicit zero, net allocation, and net release with or without
-- TopTx settlement. These are validator fixtures, not necessarily valid batches.
allDeclarations :: StrictlyPositiveCoin -> TxIx -> [TopTxUTxODepositDeclaration]
allDeclarations amount outputIndex =
  NoUTxODepositDeclaration : onlyExplicitDeclarations amount outputIndex

-- | Every explicit TopTx declaration form, including zero but excluding absence.
onlyExplicitDeclarations :: StrictlyPositiveCoin -> TxIx -> [TopTxUTxODepositDeclaration]
onlyExplicitDeclarations amount outputIndex =
  [ DeclaresZeroNetUTxODeposit
  , DeclaresNetUTxODepositAllocation amount
  , DeclaresNetUTxODepositRelease amount NoTopTxSettlement
  , DeclaresNetUTxODepositRelease amount (TopTxSettlementOutput outputIndex)
  ]

-- | Encode a local release settlement using an unchecked integer index in both formats.
-- Valid indices are 0..65535. The spec supplies a generated index outside that
-- range; settlement decoding does not check whether the output exists in a body.
localReleaseSettlementWithIndex :: Integer -> DecoderInputs
localReleaseSettlementWithIndex outputIndex =
  DecoderInputs
    { cborInputs = [cborList [E @Int 1, E outputIndex]]
    , jsonInputs =
        [ Aeson.object
            [ "kind" Aeson..= ("topTxSettlementOutput" :: String)
            , "outputIndex" Aeson..= outputIndex
            ]
        ]
    }

-- | Every operation form at both positive amount bounds, including each
-- settlement form, both output-index bounds and a generated interior index.
declarationsAtBounds :: Gen [TopTx.NetUTxODepositChange]
declarationsAtBounds =
  case StrictlyPositiveCoin.positiveAmountBounds of
    (minimumAmount, maximumAmount) ->
      (TopTx.NoUTxODepositChange :) . concat
        <$> traverse
          (allDeclarationsWithAmount . StrictlyPositiveCoin.positiveAmount)
          [minimumAmount, maximumAmount]

-- | Put the supplied typed amount in every amount-bearing TopTx form.
-- Every draw includes both index bounds and varies one interior local index.
allDeclarationsWithAmount :: StrictlyPositiveCoin -> Gen [TopTx.NetUTxODepositChange]
allDeclarationsWithAmount amount = do
  outputIndex <- TxIx <$> choose (1, 65534)
  pure $
    TopTx.AllocateUTxODeposit amount
      : [ TopTx.ReleaseUTxODeposit amount settlement
        | settlement <-
            [ TopTx.NoTopTxSettlement
            , TopTx.TopTxSettlementOutput (TxIx 0)
            , TopTx.TopTxSettlementOutput maxBound
            , TopTx.TopTxSettlementOutput outputIndex
            ]
        ]

-- | Generate inputs, reference inputs and an auxiliary-data hash once, then
-- pair identical bodies differing only in their absent or explicit-zero declaration.
-- This isolates the declaration when the spec compares their encodings.
absentAndExplicitZero :: Gen (TxBody TopTx DijkstraEra, TxBody TopTx DijkstraEra)
absentAndExplicitZero = do
  inputs <- arbitrary
  referenceInputs <- arbitrary
  auxiliaryDataHash <- arbitrary
  let body =
        mkBasicTxBody @DijkstraEra @TopTx
          & inputsTxBodyL
          .~ inputs
          & referenceInputsTxBodyL
          .~ referenceInputs
          & auxDataHashTxBodyL
          .~ auxiliaryDataHash
  pure
    ( body & netUTxODepositChangeTxBodyL .~ TopTx.NoUTxODepositDeclaration
    , body & netUTxODepositChangeTxBodyL .~ TopTx.DeclaresZeroNetUTxODeposit
    )

-- | Generate every amount-bearing TopTx form with the supplied raw amount.
-- Each sample covers no TopTx settlement, both local index bounds and a generated
-- interior index. Only the amount may be invalid; surrounding fields stay valid.
-- CBOR and JSON inputs are assembled independently of declaration encoders.
allDeclarationInputsWithAmount :: Integer -> Gen DecoderInputs
allDeclarationInputsWithAmount amount = do
  outputIndex <- chooseInteger (1, 65534)
  pure
    DecoderInputs
      { cborInputs =
          cborList [E @Int 0, E amount]
            : [ cborList [E @Int 1, E amount, settlement]
              | settlement <-
                  cborList [E @Int 0]
                    : [cborList [E @Int 1, E index] | index <- [0, 65535, outputIndex]]
              ]
      , jsonInputs =
          Aeson.object ["kind" Aeson..= ("allocate" :: String), "amount" Aeson..= amount]
            : [ Aeson.object
                  [ "kind" Aeson..= ("release" :: String)
                  , "amount" Aeson..= amount
                  , "settlement" Aeson..= settlement
                  ]
              | settlement <-
                  Aeson.object ["kind" Aeson..= ("noTopTxSettlement" :: String)]
                    : [ Aeson.object
                          [ "kind" Aeson..= ("topTxSettlementOutput" :: String)
                          , "outputIndex" Aeson..= index
                          ]
                      | index <- [0, 65535, outputIndex]
                      ]
              ]
      }

-- | Each sample contains seven CBOR and seven JSON structural failures.
-- Valid CBOR declarations are @[0, amount]@, @[1, amount, settlement]@ and @[2]@.
-- Amounts and local indices here remain in range, so rejection tests the
-- structure rather than an unrelated numeric bound.
-- Additional JSON keys remain permitted and are not treated as defects.
declarationsWithInvalidStructure :: Gen DecoderInputs
declarationsWithInvalidStructure = do
  amount <- chooseInteger (1, toInteger (maxBound :: Word64))
  outputIndex <- chooseInteger (0, 65535)
  unknownTag <- chooseInteger (3, toInteger (maxBound :: Word64))
  unknownKind <- ("unknown:" <>) <$> arbitrary @String
  scalar <- arbitrary @Integer
  extraFields <- map (E @Integer) <$> listOf1 arbitrary
  settlement <-
    elements
      [ Aeson.object ["kind" Aeson..= ("noTopTxSettlement" :: String)]
      , Aeson.object
          ["kind" Aeson..= ("topTxSettlementOutput" :: String), "outputIndex" Aeson..= outputIndex]
      ]
  pure
    DecoderInputs
      { cborInputs =
          [ E scalar -- A declaration must be a tagged array, not a scalar.
          , cborList [] -- The operation tag is missing.
          , cborList [E @Int 0] -- Allocation is missing its amount.
          , cborList [E unknownTag, E amount] -- Only operation tags 0 through 2 are known.
          , cborList (E @Int 2 : extraFields) -- Explicit zero takes no fields.
          , cborList ([E @Int 0, E amount] <> extraFields) -- Allocation has extra fields.
          , cborList [E @Int 1, E amount] -- Release is missing its settlement.
          ]
      , jsonInputs =
          [ Aeson.Null -- A declaration must be an object, not null.
          , Aeson.toJSON scalar -- A number is not a declaration object.
          , Aeson.object [] -- The required kind is missing.
          , Aeson.object ["kind" Aeson..= ("allocate" :: String)] -- Allocation is missing its amount.
          , Aeson.object ["kind" Aeson..= ("release" :: String), "settlement" Aeson..= settlement] -- Release is missing its amount.
          , Aeson.object ["kind" Aeson..= ("release" :: String), "amount" Aeson..= amount] -- Release is missing its settlement.
          , Aeson.object ["kind" Aeson..= unknownKind] -- The prefix cannot name a recognized kind.
          ]
      }

-- | Each sample contains six CBOR and five JSON structural failures.
-- Valid CBOR settlements are @[0]@ for no TopTx settlement and @[1, outputIndex]@
-- for a local output. The local index remains in 0..65535 to isolate structure.
-- JSON requires a recognized kind and, for local settlement, an outputIndex;
-- additional object keys remain permitted.
releaseSettlementsWithInvalidStructure :: Gen DecoderInputs
releaseSettlementsWithInvalidStructure = do
  outputIndex <- chooseInteger (0, 65535)
  unknownTag <- chooseInteger (2, toInteger (maxBound :: Word64))
  unknownKind <- ("unknown:" <>) <$> arbitrary @String
  scalar <- arbitrary @Integer
  extraFields <- map (E @Integer) <$> listOf1 arbitrary
  pure
    DecoderInputs
      { cborInputs =
          [ E scalar -- A settlement must be a tagged array, not a scalar.
          , cborList [] -- The settlement tag is missing.
          , cborList [E unknownTag] -- Only settlement tags 0 and 1 are known.
          , cborList [E @Int 0, E outputIndex] -- No TopTx settlement takes no output index.
          , cborList [E @Int 1] -- Local settlement is missing its output index.
          , cborList ([E @Int 1, E outputIndex] <> extraFields) -- Local settlement has extra fields.
          ]
      , jsonInputs =
          [ Aeson.Null -- A settlement must be an object, not null.
          , Aeson.toJSON scalar -- A number is not a settlement object.
          , Aeson.object [] -- The required kind is missing.
          , Aeson.object ["kind" Aeson..= unknownKind] -- The prefix cannot name a recognized kind.
          , Aeson.object ["kind" Aeson..= ("topTxSettlementOutput" :: String)] -- Local settlement is missing its outputIndex.
          ]
      }
