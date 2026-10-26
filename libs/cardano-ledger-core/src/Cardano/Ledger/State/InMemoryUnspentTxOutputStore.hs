{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Accepted outputs together with the immutable inputs to their deposit calculation.
-- Constructors that could invalidate an allocation or its cached total are private.
module Cardano.Ledger.State.InMemoryUnspentTxOutputStore (
  InMemoryUnspentTxOutputStore,
  InMemoryOutputDepositAmount,
  Allocations,
  Allocation,
  DepositCalculation (..),
  OutputStoreError (..),
  totalDepositAmount,
  unInMemoryOutputDepositAmount,
  allocations,
  unAllocations,
  emptyInMemoryOutputStore,
  fromLegacyUTxO,
  fromLegacyAllocations,
  fromAllocations,
  mkLegacyAllocation,
  mkV1Allocation,
  calculateDeposit,
  allocationOutput,
  allocationSizedOutput,
  allocationCalculation,
  allocationDeposit,
  lookupAllocation,
  refundForInputs,
  applyAllocationDelta,
  storeUTxO,
  allocationDeposits,
  allocationDepositsForInputs,
  encodeInMemoryOutputStore,
) where

import Cardano.Ledger.Binary
import Cardano.Ledger.Binary.Coders
import Cardano.Ledger.Coin (Coin (..), CompactForm (CompactCoin))
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.State.UTxO (UTxO (..))
import Cardano.Ledger.TxIn (TxIn)
import Cardano.Ledger.Val ((<->))
import Control.DeepSeq (NFData (..))
import Control.Monad (unless)
import Data.Aeson (ToJSON (..), object, (.=))
import Data.Default (Default (def))
import Data.Foldable (foldlM)
import Data.Int (Int64)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import GHC.Generics (Generic)
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

-- | DepositCalculationV2 is reserved. It has no active pricing rule or accepted allocation encoding.
data DepositCalculation
  = DepositCalculationV1 !CoinPerByte
  | DepositCalculationV2 !CoinPerByte
  deriving (Eq, Ord, Show, Generic)

instance NFData DepositCalculation

instance NoThunks DepositCalculation

data OutputStoreError
  = NegativeOutputSize !Int64
  | UnsupportedDepositCalculation !Word
  | MissingHistoricalAllocation !TxIn
  | CachedDepositTotalMismatch !Coin !Coin
  | ExpectedStoredOutputs
  | ExpectedLegacyOutputs
  deriving (Eq, Ord, Show, Generic)

instance NFData OutputStoreError

instance NoThunks OutputStoreError

instance ToJSON OutputStoreError

-- The amount constructor is private: a store's total is obtained from its entries.
newtype InMemoryOutputDepositAmount = InMemoryOutputDepositAmount Coin
  deriving (Eq, Ord, Show, Generic, NFData, NoThunks)

data Allocation era
  = LegacyAllocation !(ImplicitDepositTxOut era)
  | Allocation !(Sized (StoreBackedTxOut era)) !DepositCalculation

newtype Allocations era = Allocations (Map TxIn (Allocation era))

-- These are positional internally so the exported accessors cannot be used as
-- record setters to replace one half of the invariant independently.
data InMemoryUnspentTxOutputStore era
  = InMemoryUnspentTxOutputStore
      !InMemoryOutputDepositAmount
      !(Allocations era)

totalDepositAmount :: InMemoryUnspentTxOutputStore era -> InMemoryOutputDepositAmount
totalDepositAmount (InMemoryUnspentTxOutputStore amount _) = amount

unInMemoryOutputDepositAmount :: InMemoryOutputDepositAmount -> Coin
unInMemoryOutputDepositAmount (InMemoryOutputDepositAmount amount) = amount

allocations :: InMemoryUnspentTxOutputStore era -> Allocations era
allocations (InMemoryUnspentTxOutputStore _ entries) = entries

unAllocations :: Allocations era -> Map TxIn (Allocation era)
unAllocations (Allocations entries) = entries

emptyInMemoryOutputStore :: InMemoryUnspentTxOutputStore era
emptyInMemoryOutputStore = InMemoryUnspentTxOutputStore (InMemoryOutputDepositAmount mempty) (Allocations Map.empty)

instance Default (InMemoryUnspentTxOutputStore era) where
  def = emptyInMemoryOutputStore

mkLegacyAllocation :: ImplicitDepositTxOut era -> Allocation era
mkLegacyAllocation = LegacyAllocation

-- | Capture the rate and the accepted size of the FULL output. Unwrapping the
-- store-backed payload must not re-encode it or remove its output-variant bytes.
mkV1Allocation :: CoinPerByte -> Sized (TxOut era) -> Either OutputStoreError (Allocation era)
mkV1Allocation rate (Sized output size) = do
  _ <- calculateDeposit (DepositCalculationV1 rate) size
  pure $ case output of
    ImplicitDepositTxOut implicit -> LegacyAllocation implicit
    StoreBackedTxOut backed -> Allocation (Sized backed size) (DepositCalculationV1 rate)

-- | Calculate with historical parameters only. Convert to Integer before adding
-- the overhead so even an Int64 size cannot overflow the intermediate sum.
calculateDeposit :: DepositCalculation -> Int64 -> Either OutputStoreError Coin
calculateDeposit calculation size
  | size < 0 = Left $ NegativeOutputSize size
  | otherwise = case calculation of
      DepositCalculationV1 (CoinPerByte (CompactCoin rate)) ->
        Right $ Coin $ (160 + toInteger size) * toInteger rate
      DepositCalculationV2 _ -> Left $ UnsupportedDepositCalculation 2

allocationOutput :: Allocation era -> TxOut era
allocationOutput = \case
  LegacyAllocation output -> ImplicitDepositTxOut output
  Allocation (Sized output _) _ -> StoreBackedTxOut output

allocationSizedOutput :: Allocation era -> Maybe (Sized (StoreBackedTxOut era))
allocationSizedOutput = \case
  LegacyAllocation _ -> Nothing
  Allocation output _ -> Just output

allocationCalculation :: Allocation era -> Maybe DepositCalculation
allocationCalculation = \case
  LegacyAllocation _ -> Nothing
  Allocation _ calculation -> Just calculation

allocationDeposit :: Allocation era -> Either OutputStoreError Coin
allocationDeposit = \case
  LegacyAllocation _ -> Right mempty
  Allocation (Sized _ size) calculation -> calculateDeposit calculation size

-- | This conversion is only for genuinely legacy outputs. It cannot reconstruct
-- the accepted size or historical rate of an existing store-backed output.
fromLegacyUTxO :: UTxO era -> Either OutputStoreError (InMemoryUnspentTxOutputStore era)
fromLegacyUTxO (UTxO outputs) = do
  entries <- Map.traverseWithKey convert outputs
  fromAllocations entries
  where
    convert input = \case
      ImplicitDepositTxOut output -> Right $ LegacyAllocation output
      StoreBackedTxOut _ -> Left $ MissingHistoricalAllocation input

-- | Promote known implicit outputs without introducing a deposit or needing a
-- current price. This total constructor is used at the Conway era boundary.
fromLegacyAllocations :: Map TxIn (ImplicitDepositTxOut era) -> InMemoryUnspentTxOutputStore era
fromLegacyAllocations outputs =
  InMemoryUnspentTxOutputStore
    (InMemoryOutputDepositAmount mempty)
    (Allocations $ Map.map LegacyAllocation outputs)

fromAllocations ::
  Map TxIn (Allocation era) -> Either OutputStoreError (InMemoryUnspentTxOutputStore era)
fromAllocations entries = do
  amount <- sumAllocationDeposits entries
  pure $ InMemoryUnspentTxOutputStore (InMemoryOutputDepositAmount amount) (Allocations entries)

sumAllocationDeposits :: Map TxIn (Allocation era) -> Either OutputStoreError Coin
sumAllocationDeposits = foldlM add mempty
  where
    add total entry = do
      amount <- allocationDeposit entry
      let total' = total <> amount
      total' `seq` pure total'

lookupAllocation :: TxIn -> InMemoryUnspentTxOutputStore era -> Maybe (Allocation era)
lookupAllocation input = Map.lookup input . unAllocations . allocations

refundForInputs :: Set TxIn -> InMemoryUnspentTxOutputStore era -> Either OutputStoreError Coin
refundForInputs inputs = sumAllocationDeposits . (`Map.restrictKeys` inputs) . unAllocations . allocations

-- | Atomically remove consumed entries and insert complete accepted allocations.
-- New entries replace matching keys. Account for those replacements too, so the
-- cached total is correct even when this helper is used outside transaction rules.
-- Unaffected allocations retain their original size and calculation unchanged.
applyAllocationDelta ::
  Set TxIn ->
  Map TxIn (Allocation era) ->
  InMemoryUnspentTxOutputStore era ->
  Either OutputStoreError (InMemoryUnspentTxOutputStore era)
applyAllocationDelta consumed created previous = do
  removedAmount <- sumAllocationDeposits $ Map.restrictKeys previousEntries removedKeys
  createdAmount <- sumAllocationDeposits created
  let previousAmount = unInMemoryOutputDepositAmount $ totalDepositAmount previous
      newAmount = (previousAmount <-> removedAmount) <> createdAmount
      newEntries = Map.union created $ Map.withoutKeys previousEntries consumed
  pure $ InMemoryUnspentTxOutputStore (InMemoryOutputDepositAmount newAmount) (Allocations newEntries)
  where
    previousEntries = unAllocations $ allocations previous
    removedKeys = consumed <> Map.keysSet created

storeUTxO :: InMemoryUnspentTxOutputStore era -> UTxO era
storeUTxO = UTxO . Map.map allocationOutput . unAllocations . allocations

-- | Read-only compatibility view. Legacy entries have no separate deposit;
-- a store-backed entry with zero price still has an allocation record.
allocationDeposits :: InMemoryUnspentTxOutputStore era -> Either OutputStoreError (Map TxIn Coin)
allocationDeposits = projectAllocationDeposits . unAllocations . allocations

-- | Restrict before evaluating deposits, so transaction validation need only
-- inspect its own inputs rather than traverse the entire live store.
allocationDepositsForInputs ::
  Set TxIn -> InMemoryUnspentTxOutputStore era -> Either OutputStoreError (Map TxIn Coin)
allocationDepositsForInputs inputs =
  projectAllocationDeposits . (`Map.restrictKeys` inputs) . unAllocations . allocations

projectAllocationDeposits :: Map TxIn (Allocation era) -> Either OutputStoreError (Map TxIn Coin)
projectAllocationDeposits = fmap Map.fromDistinctDescList . foldlM collect [] . Map.toList
  where
    collect accumulated (input, entry) = case entry of
      LegacyAllocation _ -> Right accumulated
      Allocation {} -> do
        amount <- allocationDeposit entry
        pure $ (input, amount) : accumulated

instance Eq (TxOut era) => Eq (Allocation era) where
  left == right =
    allocationOutput left == allocationOutput right
      && allocationMetadata left == allocationMetadata right

allocationMetadata :: Allocation era -> Maybe (Int64, DepositCalculation)
allocationMetadata = \case
  LegacyAllocation _ -> Nothing
  Allocation (Sized _ size) calculation -> Just (size, calculation)

instance Show (TxOut era) => Show (Allocation era) where
  showsPrec precedence entry =
    showParen (precedence > 10) $
      showString "Allocation "
        . showsPrec 11 (allocationOutput entry)
        . showChar ' '
        . showsPrec 11 (allocationMetadata entry)

instance NFData (TxOut era) => NFData (Allocation era) where
  rnf entry = rnf (allocationOutput entry) `seq` rnf (allocationMetadata entry)

deriving via InspectHeapNamed "Allocation" (Allocation era) instance NoThunks (Allocation era)

deriving instance Eq (TxOut era) => Eq (Allocations era)

deriving instance Show (TxOut era) => Show (Allocations era)

instance NFData (TxOut era) => NFData (Allocations era) where
  rnf (Allocations entries) = rnf entries

deriving via InspectHeapNamed "Allocations" (Allocations era) instance NoThunks (Allocations era)

deriving instance Eq (TxOut era) => Eq (InMemoryUnspentTxOutputStore era)

deriving instance Show (TxOut era) => Show (InMemoryUnspentTxOutputStore era)

instance NFData (TxOut era) => NFData (InMemoryUnspentTxOutputStore era) where
  rnf (InMemoryUnspentTxOutputStore amount entries) = rnf amount `seq` rnf entries

deriving via
  InspectHeapNamed "InMemoryUnspentTxOutputStore" (InMemoryUnspentTxOutputStore era)
  instance
    NoThunks (InMemoryUnspentTxOutputStore era)

instance ToJSON DepositCalculation where
  toJSON = \case
    DepositCalculationV1 rate -> object ["version" .= (1 :: Word), "coinsPerByte" .= rate]
    DepositCalculationV2 rate -> object ["version" .= (2 :: Word), "coinsPerByte" .= rate]

instance ToJSON InMemoryOutputDepositAmount where
  toJSON = toJSON . unInMemoryOutputDepositAmount

instance ToJSON (TxOut era) => ToJSON (Allocation era) where
  toJSON entry =
    object $
      ["output" .= allocationOutput entry]
        <> case allocationMetadata entry of
          Nothing -> []
          Just (size, calculation) -> ["acceptedSize" .= size, "calculation" .= calculation]

instance ToJSON (TxOut era) => ToJSON (Allocations era) where
  toJSON = toJSON . unAllocations

instance ToJSON (TxOut era) => ToJSON (InMemoryUnspentTxOutputStore era) where
  toJSON store = object ["totalDepositAmount" .= totalDepositAmount store, "allocations" .= allocations store]

instance EncCBOR DepositCalculation where
  encCBOR = \case
    DepositCalculationV1 rate -> encodeListLen 2 <> encodeWord 1 <> encCBOR rate
    DepositCalculationV2 rate -> encodeListLen 2 <> encodeWord 2 <> encCBOR rate

instance DecCBOR DepositCalculation where
  decCBOR = decodeRecordSum "DepositCalculation" $ \case
    1 -> do
      rate <- decCBOR
      pure (2, DepositCalculationV1 rate)
    version -> fail $ show $ UnsupportedDepositCalculation version

instance EncCBOR OutputStoreError where
  encCBOR =
    encode . \case
      NegativeOutputSize size -> Sum NegativeOutputSize 0 !> To size
      UnsupportedDepositCalculation version -> Sum UnsupportedDepositCalculation 1 !> To version
      MissingHistoricalAllocation input -> Sum MissingHistoricalAllocation 2 !> To input
      CachedDepositTotalMismatch supplied expected -> Sum CachedDepositTotalMismatch 3 !> To supplied !> To expected
      ExpectedStoredOutputs -> Sum ExpectedStoredOutputs 4
      ExpectedLegacyOutputs -> Sum ExpectedLegacyOutputs 5

instance DecCBOR OutputStoreError where
  decCBOR = decode $ Summands "OutputStoreError" $ \case
    0 -> SumD NegativeOutputSize <! From
    1 -> SumD UnsupportedDepositCalculation <! From
    2 -> SumD MissingHistoricalAllocation <! From
    3 ->
      SumD (\supplied expected -> CachedDepositTotalMismatch (Coin supplied) (Coin expected))
        <! From
        <! From
    4 -> SumD ExpectedStoredOutputs
    5 -> SumD ExpectedLegacyOutputs
    tag -> Invalid tag

instance EraTxOut era => EncCBOR (Allocation era) where
  encCBOR = encodeAllocationWith encCBOR

instance EraTxOut era => DecCBOR (Allocation era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (Allocation era) where
  type Share (Allocation era) = Interns (Credential Staking)
  decShareCBOR credentials = decodeRecordSum "Allocation" $ \case
    0 -> do
      output <- decShareCBOR credentials
      case output of
        ImplicitDepositTxOut implicit -> pure (2, LegacyAllocation implicit)
        StoreBackedTxOut _ -> fail "A legacy allocation requires an implicit-deposit output"
    1 -> do
      output <- decShareCBOR credentials
      size <- decCBOR
      calculation <- decCBOR
      _ <- either (fail . show) pure $ calculateDeposit calculation size
      case output of
        StoreBackedTxOut backed -> pure (4, Allocation (Sized backed size) calculation)
        ImplicitDepositTxOut _ -> fail "A priced allocation requires a store-backed output"
    tag -> invalidKey tag

encodeAllocationWith :: (TxOut era -> Encoding) -> Allocation era -> Encoding
encodeAllocationWith encodeOutput entry = case entry of
  LegacyAllocation _ -> encodeListLen 2 <> encodeWord 0 <> encodeOutput (allocationOutput entry)
  Allocation (Sized _ size) calculation ->
    encodeListLen 4
      <> encodeWord 1
      <> encodeOutput (allocationOutput entry)
      <> encCBOR size
      <> encCBOR calculation

instance EraTxOut era => EncCBOR (InMemoryUnspentTxOutputStore era) where
  encCBOR = encodeStoreWith encCBOR encCBOR

instance EraTxOut era => DecCBOR (InMemoryUnspentTxOutputStore era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (InMemoryUnspentTxOutputStore era) where
  type Share (InMemoryUnspentTxOutputStore era) = Interns (Credential Staking)
  decShareCBOR credentials = decodeRecordNamed "InMemoryUnspentTxOutputStore" (const 2) $ do
    supplied <- Coin <$> decCBOR
    entries <- decodeMap decNoShareCBOR (decShareCBOR credentials)
    store <- either (fail . show) pure $ fromAllocations entries
    let expected = unInMemoryOutputDepositAmount $ totalDepositAmount store
    unless (supplied == expected) $ fail $ show $ CachedDepositTotalMismatch supplied expected
    pure store

instance EraTxOut era => ToCBOR (InMemoryUnspentTxOutputStore era) where
  toCBOR = toEraCBOR @era

instance EraTxOut era => FromCBOR (InMemoryUnspentTxOutputStore era) where
  fromCBOR = fromEraCBOR @era

-- | Ledger snapshots retain the usual MemPack output representation and encode
-- the original charged size separately. The ordinary Sized codec discards it.
encodeInMemoryOutputStore :: EraTxOut era => InMemoryUnspentTxOutputStore era -> Encoding
encodeInMemoryOutputStore = encodeStoreWith encodeMemPack encodeMemPack

encodeStoreWith ::
  (TxIn -> Encoding) ->
  (TxOut era -> Encoding) ->
  InMemoryUnspentTxOutputStore era ->
  Encoding
encodeStoreWith encodeInput encodeOutput store =
  encodeListLen 2
    <> encCBOR (unInMemoryOutputDepositAmount $ totalDepositAmount store)
    <> encodeMap encodeInput (encodeAllocationWith encodeOutput) (unAllocations $ allocations store)
