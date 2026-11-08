{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Deposit amounts, versioned formulas and the history that selects them.
module Cardano.Ledger.State.Accounting.UTxOs.Deposit (
  -- * Formula
  DepositFormula (..),
  DepositAmount (..),
  computeDeposit,

  -- * Output measurements
  NativeAssetCount (..),
  DatumBytes (..),
  ReferenceScriptBytes (..),

  -- * History
  DepositFormulaHistory (..),
  DepositPeriod (..),
  mkDepositFormulaHistory,
  appendFormula,
  formulaAt,
  latestFormula,
  periods,
) where

import Cardano.Ledger.BaseTypes (SlotNo (..))
import Cardano.Ledger.Binary (
  DecCBOR (..),
  EncCBOR (..),
  decodeMapContents,
  decodeRecordNamed,
  decodeRecordSum,
  encodeListLen,
  encodeWord,
 )
import Cardano.Ledger.Coin (Coin (..), CoinPerByte (..), CompactForm (CompactCoin))
import Control.DeepSeq (NFData)
import Control.Monad (foldM, guard)
import Data.Aeson (ToJSON (..), object, (.=))
import qualified Data.Bifunctor
import Data.Default (Default (..))
import Data.Function ((&))
import qualified Data.Map.Strict as Map
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)
import Numeric.Natural (Natural)

-- | A capacity deposit amount. The output variant determines whether the amount
-- is included in its ADA or held separately in the Store.
newtype DepositAmount = DepositAmount
  { toCoin :: Coin
  }
  deriving (Eq, Ord, Show, Generic, NFData, NoThunks)

instance ToJSON DepositAmount where
  toJSON = toJSON . toCoin

-- | Number of distinct native assets (policy, asset name), excluding ADA.
newtype NativeAssetCount = NativeAssetCount Natural
  deriving (Eq, Ord, Show)

-- | Datum payload bytes, or hash bytes for a datum hash. Absence contributes zero.
newtype DatumBytes = DatumBytes Natural
  deriving (Eq, Ord, Show)

-- | Reference-script payload bytes, excluding enclosing output fields.
newtype ReferenceScriptBytes = ReferenceScriptBytes Natural
  deriving (Eq, Ord, Show)

-- | Each version carries the pricing parameters recorded at allocation.
-- V1 prices 250 base bytes and 74 bytes per native asset.
-- V2 experiments with 260 and 80; both include datum and reference script bytes.
data DepositFormula
  = DepositFormulaV1 !CoinPerByte
  | DepositFormulaV2 !CoinPerByte
  deriving (Eq, Ord, Show, Generic)

-- | Compute the deposit from the output's domain measurements.
-- V1: @p * (250 + 74*N + D + R)@.
-- V2: @p * (260 + 80*N + D + R)@, for the formula-evolution experiment.
-- Natural and Integer arithmetic preserves the amount without machine overflow.
-- Legacy reserve capping belongs to the output query, not to the formula.
computeDeposit ::
  DepositFormula ->
  NativeAssetCount ->
  DatumBytes ->
  ReferenceScriptBytes ->
  DepositAmount
computeDeposit pricing (NativeAssetCount n) (DatumBytes d) (ReferenceScriptBytes r) =
  DepositAmount . Coin $ case pricing of
    DepositFormulaV1 (CoinPerByte (CompactCoin rate)) ->
      toInteger rate * toInteger (250 + 74 * n + d + r)
    DepositFormulaV2 (CoinPerByte (CompactCoin rate)) ->
      toInteger rate * toInteger (260 + 80 * n + d + r)

-- | Default baseline: V1 at 4,310 lovelace per byte, the mainnet parameter
-- verified on 6 November 2026. This is a fixed protocol choice for this model;
-- later price changes belong in 'formulaChanges', not in this default.
instance Default DepositFormula where
  def = DepositFormulaV1 . CoinPerByte $ CompactCoin 4310

-- | A baseline formula and its dated changes. The baseline permanently prices
-- migrated outputs and covers dated allocations before the first change.
-- Every allocation has a formula, including when no changes are recorded.
-- This history starts with the prototype's common initial formula; it does not
-- reconstruct pre-fork prices or require a dated migration boundary.
data DepositFormulaHistory = DepositFormulaHistory
  { initialFormula :: !DepositFormula
  , formulaChanges :: !(Map.Map SlotNo DepositFormula)
  }
  deriving (Eq, Show, Generic)

-- | The formula effective over @[fromInclusive, untilExclusive)@.
-- 'Nothing' marks the baseline's open lower bound or the final open upper bound.
data DepositPeriod = DepositPeriod
  { fromInclusive :: !(Maybe SlotNo)
  , untilExclusive :: !(Maybe SlotNo)
  , formula :: !DepositFormula
  }
  deriving (Eq, Show, Generic)

-- | Start with an explicitly supplied baseline and no dated changes.
mkDepositFormulaHistory :: DepositFormula -> DepositFormulaHistory
mkDepositFormulaHistory baseline =
  DepositFormulaHistory {initialFormula = baseline, formulaChanges = Map.empty}

instance Default DepositFormulaHistory where
  def = mkDepositFormulaHistory def

-- | Add a strictly later activation. Never overwrite or insert into historical
-- periods, even when the proposed formula equals an earlier formula.
-- The first change may occur at any slot; the baseline is never replaced.
appendFormula ::
  SlotNo -> DepositFormula -> DepositFormulaHistory -> Maybe DepositFormulaHistory
appendFormula slot pricing history = do
  guard $ maybe True ((slot >) . fst) . Map.lookupMax . formulaChanges $ history
  pure history {formulaChanges = Map.insert slot pricing $ formulaChanges history}

-- | Use the latest change at or before this slot, otherwise the baseline.
formulaAt :: SlotNo -> DepositFormulaHistory -> DepositFormula
formulaAt slot history =
  (maybe (initialFormula history) snd . Map.lookupLE slot . formulaChanges) $ history

-- | The latest dated formula, or the baseline when there are no changes.
latestFormula :: DepositFormulaHistory -> DepositFormula
latestFormula history =
  (maybe (initialFormula history) snd . Map.lookupMax . formulaChanges) $ history

-- | Read the complete history as contiguous, half-open periods.
periods :: DepositFormulaHistory -> [DepositPeriod]
periods history =
  Map.toAscList (formulaChanges history)
    & \activations ->
      zipWith
        ( \(start, price) end ->
            DepositPeriod {fromInclusive = start, untilExclusive = end, formula = price}
        )
        ((Nothing, initialFormula history) : map (Data.Bifunctor.first Just) activations)
        (map (Just . fst) activations <> [Nothing])

instance NFData DepositFormulaHistory

instance NoThunks DepositFormulaHistory

instance NFData DepositPeriod

instance NoThunks DepositPeriod

instance ToJSON DepositFormulaHistory where
  toJSON history =
    object
      [ "initialFormula" .= initialFormula history
      , "formulaChanges" .= Map.mapKeysMonotonic (\(SlotNo slot) -> slot) (formulaChanges history)
      ]

instance ToJSON DepositPeriod where
  toJSON period =
    object
      [ "fromInclusive" .= fromInclusive period
      , "untilExclusive" .= untilExclusive period
      , "formula" .= formula period
      ]

instance EncCBOR DepositFormulaHistory where
  encCBOR history =
    encodeListLen 2 <> encCBOR (initialFormula history) <> encCBOR (formulaChanges history)

-- Validate activation order before building the map: decoding through Map alone
-- could otherwise discard duplicate slots and silently rewrite historical prices.
instance DecCBOR DepositFormulaHistory where
  decCBOR = decodeRecordNamed "DepositFormulaHistory" (const 2) $ do
    baseline <- decCBOR
    activations <- decodeMapContents $ (,) <$> decCBOR <*> decCBOR
    foldM
      ( \history (slot, pricing) ->
          maybe
            (fail "DepositFormulaHistory: activation slots must be strictly increasing")
            pure
            (appendFormula slot pricing history)
      )
      (mkDepositFormulaHistory baseline)
      activations

instance NFData DepositFormula

instance NoThunks DepositFormula

instance ToJSON DepositFormula where
  toJSON = \case
    DepositFormulaV1 rate -> object ["version" .= (1 :: Word), "coinsPerByte" .= rate]
    DepositFormulaV2 rate -> object ["version" .= (2 :: Word), "coinsPerByte" .= rate]

instance EncCBOR DepositFormula where
  encCBOR = \case
    DepositFormulaV1 rate -> encodeListLen 2 <> encodeWord 1 <> encCBOR rate
    DepositFormulaV2 rate -> encodeListLen 2 <> encodeWord 2 <> encCBOR rate

instance DecCBOR DepositFormula where
  decCBOR = decodeRecordSum "DepositFormula" $ \case
    1 -> do
      rate <- decCBOR
      pure (2, DepositFormulaV1 rate)
    2 -> do
      rate <- decCBOR
      pure (2, DepositFormulaV2 rate)
    version -> fail $ "Unknown DepositFormula version: " <> show version
