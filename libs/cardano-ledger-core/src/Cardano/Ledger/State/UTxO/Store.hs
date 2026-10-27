{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
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
-- Checked construction, updates and decoding maintain the cached deposit total.
module Cardano.Ledger.State.UTxO.Store (
  -- * Model
  UTxOs (..),
  UTxOStore (totalDepositAmount, allocations),
  UnspentOutputDepositsAmount (unspentOutputDepositsAmount),
  Allocations (unAllocations),
  Unspent (..),
  DepositCalculation (..),
  OutputStoreError (..),

  -- * Access
  CanGetUTxOs (..),
  CanSetUTxOs (..),
  utxosUTxO,
  utxosTotalDeposit,

  -- * Operations
  emptyUTxOStore,
  allocationFromOutput,
  fromAllocations,
  calculateDeposit,
  allocationDeposit,
  refundForInputs,
  lookupAllocation,
  allocationOutput,
  applyAllocationDelta,

  -- * Legacy compatibility
  fromLegacyUTxO,
  fromLegacyAllocations,
  storeUTxO,
  fromLegacyUTxOs,
  fromLegacyAllocationStorage,
  applyLegacyOutputDelta,

  -- * Serialization
  encodeUTxOStore,
  encodeUTxOs,
) where

import Cardano.Ledger.Binary
import Cardano.Ledger.Binary.Coders
import Cardano.Ledger.Coin (Coin (..), CompactForm (CompactCoin))
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.State.UTxO.LegacyUTxOMap (UTxO (..))
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
import Lens.Micro (Lens', SimpleGetter)
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

-- Model

data UTxOStore era = UTxOStore
  { totalDepositAmount :: !UnspentOutputDepositsAmount
  , allocations :: !(Allocations era)
  }

newtype UnspentOutputDepositsAmount = UnspentOutputDepositsAmount
  { unspentOutputDepositsAmount :: Coin
  }
  deriving (Eq, Ord, Show, Generic, NFData, NoThunks)

newtype Allocations era = Allocations
  { unAllocations :: Map TxIn (Unspent (TxOut era))
  }

-- | An unspent value with its accepted size and deposit calculation.
-- The wrapped TxOut determines whether its deposit is separately held.
data Unspent output = Unspent
  { sizedOutput :: !(Sized output)
  , depositCalculation :: !DepositCalculation
  }
  deriving (Eq, Show, Generic)

-- | DepositCalculationV2 is reserved. It has no active pricing rule or accepted allocation encoding.
data DepositCalculation
  = DepositCalculationV1 !CoinPerByte
  | DepositCalculationV2 !CoinPerByte
  deriving (Eq, Ord, Show, Generic)

data OutputStoreError
  = NegativeOutputSize !Int64
  | UnsupportedDepositCalculation !Word
  | MissingHistoricalAllocation !TxIn
  | CachedDepositTotalMismatch !Coin !Coin
  deriving (Eq, Ord, Show, Generic)

-- | Earlier eras retain their existing UTxO representation and constant-time
-- projection. Dijkstra owns outputs and historical allocations in one store.
data UTxOs era
  = LegacyUTxOMap !(UTxO era)
  | UTxOs !(UTxOStore era)
  deriving (Generic)

-- Access

class CanGetUTxOs t where
  utxosG :: SimpleGetter (t era) (UTxOs era)
  default utxosG ::
    CanSetUTxOs t => SimpleGetter (t era) (UTxOs era)
  utxosG = utxosL
  {-# INLINE utxosG #-}

class CanGetUTxOs t => CanSetUTxOs t where
  utxosL :: Lens' (t era) (UTxOs era)

instance CanGetUTxOs UTxOs

instance CanSetUTxOs UTxOs where
  utxosL = id

utxosUTxO :: UTxOs era -> UTxO era
utxosUTxO (LegacyUTxOMap outputs) = outputs
utxosUTxO (UTxOs store) = storeUTxO store

-- | The separately held deposit total; application ADA remains in the outputs.
utxosTotalDeposit :: UTxOs era -> Coin
utxosTotalDeposit (LegacyUTxOMap _) = Coin 0
utxosTotalDeposit (UTxOs store) = unspentOutputDepositsAmount $ totalDepositAmount store

-- Operations

emptyUTxOStore :: UTxOStore era
emptyUTxOStore =
  UTxOStore
    { totalDepositAmount = UnspentOutputDepositsAmount {unspentOutputDepositsAmount = mempty}
    , allocations = Allocations {unAllocations = Map.empty}
    }

-- | Capture the FULL accepted output size and the calculation chosen at creation.
-- Both output forms retain these inputs. Legacy outputs carry no external
-- deposit; this conversion neither evaluates nor re-encodes the output.
allocationFromOutput :: DepositCalculation -> Sized (TxOut era) -> Unspent (TxOut era)
allocationFromOutput calculation output =
  Unspent {sizedOutput = output, depositCalculation = calculation}

-- | Calculate with historical parameters only. Convert to Integer before adding
-- the overhead so even an Int64 size cannot overflow the intermediate sum.
calculateDeposit :: DepositCalculation -> Int64 -> Either OutputStoreError Coin
calculateDeposit calculation size
  | size < 0 = Left $ NegativeOutputSize size
  | otherwise = case calculation of
      DepositCalculationV1 (CoinPerByte (CompactCoin rate)) ->
        Right $ Coin $ (160 + toInteger size) * toInteger rate
      DepositCalculationV2 _ -> Left $ UnsupportedDepositCalculation 2

allocationOutput :: Unspent (TxOut era) -> TxOut era
allocationOutput = sizedValue . sizedOutput

allocationDeposit :: Unspent (TxOut era) -> Either OutputStoreError Coin
allocationDeposit (Unspent (Sized output size) calculation) = do
  -- Validate metadata for both variants so every checked entry can be decoded.
  amount <- calculateDeposit calculation size
  pure $ case output of
    LegacyTxOut _ -> mempty
    NewTxOut _ -> amount

fromAllocations ::
  Map TxIn (Unspent (TxOut era)) -> Either OutputStoreError (UTxOStore era)
fromAllocations entries = do
  amount <- sumAllocationDeposits entries
  pure $
    UTxOStore
      { totalDepositAmount = UnspentOutputDepositsAmount {unspentOutputDepositsAmount = amount}
      , allocations = Allocations {unAllocations = entries}
      }

sumAllocationDeposits :: Map TxIn (Unspent (TxOut era)) -> Either OutputStoreError Coin
sumAllocationDeposits = foldlM add mempty
  where
    add total entry = do
      amount <- allocationDeposit entry
      let total' = total <> amount
      total' `seq` pure total'

lookupAllocation :: TxIn -> UTxOStore era -> Maybe (Unspent (TxOut era))
lookupAllocation input store = Map.lookup input $ unAllocations $ allocations store

refundForInputs :: Set TxIn -> UTxOStore era -> Either OutputStoreError Coin
refundForInputs inputs store =
  sumAllocationDeposits $ Map.restrictKeys (unAllocations $ allocations store) inputs

-- | Atomically remove consumed entries and insert complete accepted allocations.
-- New entries replace matching keys. Account for those replacements too, so the
-- cached total is correct even when this helper is used outside transaction rules.
-- Unaffected allocations retain their original size and calculation unchanged.
applyAllocationDelta ::
  Set TxIn ->
  Map TxIn (Unspent (TxOut era)) ->
  UTxOStore era ->
  Either OutputStoreError (UTxOStore era)
applyAllocationDelta consumed created previous = do
  removedAmount <- sumAllocationDeposits $ Map.restrictKeys previousEntries removedKeys
  createdAmount <- sumAllocationDeposits created
  let previousAmount = unspentOutputDepositsAmount $ totalDepositAmount previous
      newAmount = (previousAmount <-> removedAmount) <> createdAmount
      newEntries = Map.union created $ Map.withoutKeys previousEntries consumed
  pure $
    previous
      { totalDepositAmount = UnspentOutputDepositsAmount {unspentOutputDepositsAmount = newAmount}
      , allocations = Allocations {unAllocations = newEntries}
      }
  where
    previousEntries = unAllocations $ allocations previous
    removedKeys = consumed <> Map.keysSet created

-- Legacy compatibility

-- | This conversion is only for legacy outputs. It cannot reconstruct the
-- accepted size or historical rate of an existing store-backed output.
fromLegacyUTxO :: EraTxOut era => UTxO era -> Either OutputStoreError (UTxOStore era)
fromLegacyUTxO (UTxO outputs) =
  fromLegacyAllocations <$> Map.traverseWithKey legacyOutput outputs
  where
    legacyOutput input = \case
      LegacyTxOut output -> Right output
      NewTxOut _ -> Left $ MissingHistoricalAllocation input

-- | Provisional compatibility conversion while legacy migration is undecided.
-- Re-encoded size and V1 with a zero rate are NOT historical pricing inputs.
-- Legacy outputs contribute zero to the Store regardless of this metadata.
-- Outputs accepted in Dijkstra use 'allocationFromOutput' instead, preserving
-- their actual accepted size and the calculation in force at creation.
fromLegacyAllocations :: forall era. EraTxOut era => Map TxIn (LegacyTxOut era) -> UTxOStore era
fromLegacyAllocations outputs =
  UTxOStore
    { totalDepositAmount = UnspentOutputDepositsAmount {unspentOutputDepositsAmount = mempty}
    , allocations = Allocations {unAllocations = Map.map legacyOutput outputs}
    }
  where
    legacyOutput output =
      let sized = mkSized (eraProtVerLow @era) $ LegacyTxOut output
       in sizedSize sized `seq`
            Unspent
              { sizedOutput = sized
              , depositCalculation = DepositCalculationV1 $ CoinPerByte $ CompactCoin 0
              }

storeUTxO :: UTxOStore era -> UTxO era
storeUTxO = UTxO . Map.map allocationOutput . unAllocations . allocations

-- | Construct storage from outputs whose type proves they use implicit deposits.
-- Earlier eras keep the plain map; Dijkstra uses the provisional conversion above.
fromLegacyAllocationStorage ::
  forall era. EraTxOut era => Map.Map TxIn (LegacyTxOut era) -> UTxOs era
fromLegacyAllocationStorage outputs
  | eraProtVerLow @era >= natVersion @12 = UTxOs $ fromLegacyAllocations outputs
  | otherwise = LegacyUTxOMap $ UTxO $ Map.map LegacyTxOut outputs

-- | Initialize or translate outputs known to have legacy implicit deposits.
-- A store-backed output needs historical metadata and is rejected here.
fromLegacyUTxOs ::
  forall era. EraTxOut era => UTxO era -> Either OutputStoreError (UTxOs era)
fromLegacyUTxOs outputs
  | eraProtVerLow @era >= natVersion @12 = UTxOs <$> fromLegacyUTxO outputs
  | otherwise = Right $ LegacyUTxOMap outputs

-- | Apply an explicit legacy-output delta. Existing stored allocations retain
-- their metadata; newly inserted outputs must have implicit deposits.
applyLegacyOutputDelta ::
  EraTxOut era =>
  Set TxIn ->
  UTxO era ->
  UTxOs era ->
  Either OutputStoreError (UTxOs era)
applyLegacyOutputDelta consumed (UTxO created) (LegacyUTxOMap (UTxO previous)) =
  Right $ LegacyUTxOMap $ UTxO $ Map.union created $ Map.withoutKeys previous consumed
applyLegacyOutputDelta consumed created (UTxOs previous) = do
  newStore <- fromLegacyUTxO created
  UTxOs <$> applyAllocationDelta consumed (unAllocations $ allocations newStore) previous

-- Instances

instance Default (UTxOStore era) where
  def = emptyUTxOStore

instance NFData DepositCalculation

instance NoThunks DepositCalculation

instance NFData OutputStoreError

instance NoThunks OutputStoreError

instance NFData a => NFData (Unspent a)

deriving via
  InspectHeapNamed "Unspent" (Unspent a)
  instance
    NoThunks (Unspent a)

deriving instance Eq (TxOut era) => Eq (Allocations era)

deriving instance Show (TxOut era) => Show (Allocations era)

instance NFData (TxOut era) => NFData (Allocations era) where
  rnf = rnf . unAllocations

deriving via InspectHeapNamed "Allocations" (Allocations era) instance NoThunks (Allocations era)

deriving instance Eq (TxOut era) => Eq (UTxOStore era)

deriving instance Show (TxOut era) => Show (UTxOStore era)

instance NFData (TxOut era) => NFData (UTxOStore era) where
  rnf store = rnf (totalDepositAmount store) `seq` rnf (allocations store)

deriving via
  InspectHeapNamed "UTxOStore" (UTxOStore era)
  instance
    NoThunks (UTxOStore era)

deriving instance (Era era, Eq (TxOut era)) => Eq (UTxOs era)

deriving instance Show (TxOut era) => Show (UTxOs era)

instance (Era era, NFData (TxOut era)) => NFData (UTxOs era)

instance NoThunks (UTxO era) => NoThunks (UTxOs era)

instance Era era => Default (UTxOs era) where
  def
    | eraProtVerLow @era >= natVersion @12 = UTxOs emptyUTxOStore
    | otherwise = LegacyUTxOMap mempty

-- Serialization

instance ToJSON OutputStoreError

instance ToJSON DepositCalculation where
  toJSON = \case
    DepositCalculationV1 rate -> object ["version" .= (1 :: Word), "coinsPerByte" .= rate]
    DepositCalculationV2 rate -> object ["version" .= (2 :: Word), "coinsPerByte" .= rate]

instance ToJSON UnspentOutputDepositsAmount where
  toJSON = toJSON . unspentOutputDepositsAmount

instance ToJSON a => ToJSON (Unspent a) where
  toJSON (Unspent (Sized output size) calculation) =
    object
      [ "output" .= output
      , "acceptedSize" .= size
      , "calculation" .= calculation
      ]

instance ToJSON (TxOut era) => ToJSON (Allocations era) where
  toJSON = toJSON . unAllocations

instance ToJSON (TxOut era) => ToJSON (UTxOStore era) where
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

instance DecCBOR OutputStoreError where
  decCBOR = decode $ Summands "OutputStoreError" $ \case
    0 -> SumD NegativeOutputSize <! From
    1 -> SumD UnsupportedDepositCalculation <! From
    2 -> SumD MissingHistoricalAllocation <! From
    3 ->
      SumD (\supplied expected -> CachedDepositTotalMismatch (Coin supplied) (Coin expected))
        <! From
        <! From
    -- Tags 4 and 5 belonged to unused compatibility errors; do not reuse them.
    tag -> Invalid tag

instance EncCBOR a => EncCBOR (Unspent a) where
  encCBOR = encodeAllocationWith encCBOR

instance DecCBOR a => DecCBOR (Unspent a) where
  decCBOR = decodeUnspent decCBOR

instance DecShareCBOR a => DecShareCBOR (Unspent a) where
  type Share (Unspent a) = Share a
  decShareCBOR sharing = decodeUnspent $ decShareCBOR sharing

-- Preserve the recorded size explicitly: Sized's ordinary codec recalculates it.
decodeUnspent :: Decoder s a -> Decoder s (Unspent a)
decodeUnspent decodeOutput = decodeRecordNamed "Unspent" (const 3) $ do
  output <- decodeOutput
  size <- decCBOR
  calculation <- decCBOR
  _ <- either (fail . show) pure $ calculateDeposit calculation size
  pure $ Unspent (Sized output size) calculation

encodeAllocationWith :: (a -> Encoding) -> Unspent a -> Encoding
encodeAllocationWith encodeOutput (Unspent (Sized output size) calculation) =
  encodeListLen 3
    <> encodeOutput output
    <> encCBOR size
    <> encCBOR calculation

instance EraTxOut era => EncCBOR (UTxOStore era) where
  encCBOR = encodeStoreWith encCBOR encCBOR

instance EraTxOut era => DecCBOR (UTxOStore era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (UTxOStore era) where
  type Share (UTxOStore era) = Interns (Credential Staking)
  decShareCBOR credentials = decodeRecordNamed "UTxOStore" (const 2) $ do
    supplied <- Coin <$> decCBOR
    entries <- decodeMap decNoShareCBOR (decShareCBOR credentials)
    store <- either (fail . show) pure $ fromAllocations entries
    let expected = unspentOutputDepositsAmount $ totalDepositAmount store
    unless (supplied == expected) $ fail $ show $ CachedDepositTotalMismatch supplied expected
    pure store

instance EraTxOut era => ToCBOR (UTxOStore era) where
  toCBOR = toEraCBOR @era

instance EraTxOut era => FromCBOR (UTxOStore era) where
  fromCBOR = fromEraCBOR @era

-- | Ledger snapshots retain the usual MemPack output representation and encode
-- the original charged size separately. The ordinary Sized codec discards it.
encodeUTxOStore :: EraTxOut era => UTxOStore era -> Encoding
encodeUTxOStore = encodeStoreWith encodeMemPack encodeMemPack

encodeStoreWith ::
  (TxIn -> Encoding) ->
  (TxOut era -> Encoding) ->
  UTxOStore era ->
  Encoding
encodeStoreWith encodeInput encodeOutput store =
  encodeListLen 2
    <> encCBOR (unspentOutputDepositsAmount $ totalDepositAmount store)
    <> encodeMap encodeInput (encodeAllocationWith encodeOutput) (unAllocations $ allocations store)

instance ToJSON (TxOut era) => ToJSON (UTxOs era) where
  toJSON (LegacyUTxOMap outputs) = toJSON outputs
  toJSON (UTxOs store) = toJSON store

instance EraTxOut era => EncCBOR (UTxOs era) where
  encCBOR (LegacyUTxOMap outputs) = encCBOR outputs
  encCBOR (UTxOs store) = encCBOR store

instance EraTxOut era => DecCBOR (UTxOs era) where
  decCBOR = decNoShareCBOR

instance EraTxOut era => DecShareCBOR (UTxOs era) where
  type Share (UTxOs era) = Interns (Credential Staking)
  decShareCBOR credentials
    | eraProtVerLow @era >= natVersion @12 = UTxOs <$> decShareCBOR credentials
    | otherwise = LegacyUTxOMap <$> decShareCBOR credentials

-- | State snapshots preserve the historical pre-Dijkstra MemPack map bytes.
-- Dijkstra's store codec explicitly persists its cached total and allocations.
encodeUTxOs :: EraTxOut era => UTxOs era -> Encoding
encodeUTxOs (LegacyUTxOMap (UTxO outputs)) = encodeMap encodeMemPack encodeMemPack outputs
encodeUTxOs (UTxOs store) = encodeUTxOStore store
