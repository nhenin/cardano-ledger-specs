{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE ConstrainedClassMethods #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilyDependencies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}

-- | Transaction outputs, their era-specific interfaces and collection queries.
module Cardano.Ledger.TxOut (
  TxOut (..),
  NoNewTxOut,
  EraTxOut (..),
  EraLegacyTxOut (..),
  EraNewTxOut (..),
  Value,
  Assets (..),
  ApplicationAssets (..),
  mkBasicTxOutWithImplicitDeposit,
  mkBasicTxOutWithStoreBackedDeposit,
  mkCoinTxOut,
  bootAddrTxOutF,
  sumAllAssets,
  sumAllValue,
  sumAllApplicationAssets,
  sumAllCoin,
  areAllAdaOnly,
) where

import Cardano.Ledger.Address (
  Addr (..),
  BootstrapAddress,
  CompactAddr,
  compactAddr,
  decompactAddr,
  isBootstrapCompactAddr,
 )
import Cardano.Ledger.BaseTypes (ProtVer (..))
import Cardano.Ledger.Binary (
  DecCBOR,
  DecShareCBOR (Share),
  EncCBOR,
  Interns,
  Sized (sizedValue),
  mkSized,
 )
import Cardano.Ledger.Coin (Coin, CompactForm (CompactCoin))
import Cardano.Ledger.Compactible (Compactible (..))
import Cardano.Ledger.Core.Era (AtLeastEra, Era (PreviousEra))
import Cardano.Ledger.Core.PParams (EraPParams, PParams, ppProtocolVersionL)
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.Hashes (KeyRole (Staking))
import Cardano.Ledger.Val (Val (..), inject)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON, ToJSON)
import Data.Coerce (coerce)
import Data.Foldable (foldMap')
import Data.Kind (Type)
import Data.Maybe (fromMaybe)
import Data.MemPack (MemPack)
import Data.Monoid (Sum (..))
import GHC.Stack (HasCallStack)
import Lens.Micro
import NoThunks.Class (NoThunks)

-- | An output whose capacity deposit is included in its value or held in a
-- separate deposit store. Each era defines the representation of both variants.
data TxOut era
  = LegacyTxOut !(LegacyTxOut era)
  | NewTxOut !(NewTxOut era)

-- | Uninhabited representation for eras that do not support store-backed outputs.
data NoNewTxOut era

-- | Both output interfaces and the operations shared by their variants.
class
  ( EraLegacyTxOut era
  , EraNewTxOut era
  , FromJSON (TxOut era)
  , ToJSON (TxOut era)
  , DecCBOR (Value era)
  , DecCBOR (CompactForm (Value era))
  , MemPack (CompactForm (Value era))
  , EncCBOR (Value era)
  , EncCBOR (TxOut era)
  , DecCBOR (TxOut era)
  , DecShareCBOR (TxOut era)
  , Share (TxOut era) ~ Interns (Credential Staking)
  , NoThunks (TxOut era)
  , NFData (TxOut era)
  , Show (TxOut era)
  , Eq (TxOut era)
  , Ord (TxOut era)
  , MemPack (TxOut era)
  ) =>
  EraTxOut era
  where
  -- | An output whose value includes its implicit capacity deposit.
  type LegacyTxOut era = (r :: Type) | r -> era

  -- | An output whose capacity deposit is held in a separate deposit store.
  type NewTxOut era = (r :: Type) | r -> era

  {-# MINIMAL upgradeTxOut, addrEitherTxOutL #-}

  -- | Every era, except Shelley, must be able to upgrade a `TxOut` from a previous era.
  upgradeTxOut :: EraTxOut (PreviousEra era) => TxOut (PreviousEra era) -> TxOut era

  addrTxOutL :: Lens' (TxOut era) Addr
  addrTxOutL =
    lens
      ( \txOut -> case txOut ^. addrEitherTxOutL of
          Left addr -> addr
          Right cAddr -> decompactAddr cAddr
      )
      (\txOut addr -> txOut & addrEitherTxOutL .~ Left addr)
  {-# INLINE addrTxOutL #-}

  compactAddrTxOutL :: Lens' (TxOut era) CompactAddr
  compactAddrTxOutL =
    lens
      ( \txOut -> case txOut ^. addrEitherTxOutL of
          Left addr -> compactAddr addr
          Right cAddr -> cAddr
      )
      (\txOut cAddr -> txOut & addrEitherTxOutL .~ Right cAddr)
  {-# INLINE compactAddrTxOutL #-}

  -- | Lens for getting and setting in TxOut either an address or its compact
  -- version by doing the least amount of work.
  --
  -- The utility of this function comes from the fact that TxOut usually stores
  -- the address in either one of two forms: compacted or unpacked. In order to
  -- avoid extroneous conversions in `getTxOutAddr` and `getTxOutCompactAddr` we
  -- can define just this functionality. Also sometimes it is crucial to know at
  -- the callsite which form of address we have readily available without any
  -- conversions (eg. searching millions of TxOuts for a particular address)
  addrEitherTxOutL :: Lens' (TxOut era) (Either Addr CompactAddr)

  -- | Read or replace the ADA held in either output variant, including any
  -- implicit deposit. Deposits held in the separate store are outside this lens.
  coinTxOutL :: HasCallStack => Lens' (TxOut era) Coin
  coinTxOutL =
    lens
      ( \case
          LegacyTxOut txOut ->
            case txOut ^. valueEitherTxOutL of
              Left value -> coin value
              Right compactValue -> fromCompact (coinCompact compactValue)
          NewTxOut txOut ->
            case txOut ^. applicationAssetsTxOutL of
              ApplicationAssets assets -> coin assets
      )
      ( \output amount -> case output of
          LegacyTxOut txOut ->
            LegacyTxOut $
              case txOut ^. valueEitherTxOutL of
                Left value -> txOut & valueTxOutL .~ modifyCoin (const amount) value
                Right compactValue ->
                  txOut & compactValueTxOutL .~ modifyCompactCoin (const (toCompactPartial amount)) compactValue
          NewTxOut txOut ->
            NewTxOut $
              case txOut ^. applicationAssetsTxOutL of
                ApplicationAssets assets ->
                  txOut & applicationAssetsTxOutL .~ ApplicationAssets (modifyCoin (const amount) assets)
      )
  {-# INLINE coinTxOutL #-}

  -- | Read or replace the same ADA amount in its compact representation.
  compactCoinTxOutL :: HasCallStack => Lens' (TxOut era) (CompactForm Coin)
  compactCoinTxOutL =
    lens
      (toCompactPartial . (^. coinTxOutL))
      (\txOut compactCoin -> txOut & coinTxOutL .~ fromCompact compactCoin)
  {-# INLINE compactCoinTxOutL #-}

  -- | Check whether either output variant contains ADA only.
  isAdaOnlyTxOutF :: SimpleGetter (TxOut era) Bool
  isAdaOnlyTxOutF = to $ \case
    LegacyTxOut txOut ->
      case txOut ^. valueEitherTxOutL of
        Left value -> isAdaOnly value
        Right compactValue -> isAdaOnlyCompact compactValue
    NewTxOut txOut ->
      isAdaOnly (coerce (txOut ^. applicationAssetsTxOutL) :: Value era)
  {-# INLINE isAdaOnlyTxOutF #-}

-- | Construct and inspect outputs whose value includes an implicit capacity deposit.
class
  ( EraPParams era
  , Val (Value era)
  , EncCBOR (LegacyTxOut era)
  ) =>
  EraLegacyTxOut era
  where
  {-# MINIMAL
    mkBasicLegacyTxOut
    , valueEitherTxOutL
    , (getMinCoinSizedTxOut | getMinCoinTxOut)
    #-}

  mkBasicLegacyTxOut :: HasCallStack => Addr -> Value era -> LegacyTxOut era

  valueTxOutL :: Lens' (LegacyTxOut era) (Value era)
  valueTxOutL =
    lens
      ( \txOut -> case txOut ^. valueEitherTxOutL of
          Left value -> value
          Right cValue -> fromCompact cValue
      )
      (\txOut value -> txOut & valueEitherTxOutL .~ Left value)
  {-# INLINE valueTxOutL #-}

  compactValueTxOutL :: HasCallStack => Lens' (LegacyTxOut era) (CompactForm (Value era))
  compactValueTxOutL =
    lens
      ( \txOut -> case txOut ^. valueEitherTxOutL of
          Left value -> toCompactPartial value
          Right cValue -> cValue
      )
      (\txOut cValue -> txOut & valueEitherTxOutL .~ Right cValue)
  {-# INLINE compactValueTxOutL #-}

  -- | Read or replace the value, including its implicit deposit, in either
  -- its unpacked or compact representation.
  valueEitherTxOutL :: Lens' (LegacyTxOut era) (Either (Value era) (CompactForm (Value era)))

  -- | Produce the minimum lovelace that a given transaction output must
  -- contain. Information about the size of the TxOut is required in some eras.
  -- Use `getMinCoinTxOut` if you don't have the size readily available to you.
  getMinCoinSizedTxOut :: PParams era -> Sized (LegacyTxOut era) -> Coin
  getMinCoinSizedTxOut pp = getMinCoinTxOut pp . sizedValue

  -- | Same as `getMinCoinSizedTxOut`, except information about the size of
  -- TxOut will be computed by serializing the TxOut. If the size turns out to
  -- be not needed, then serialization will have no overhead, since it is
  -- computed lazily.
  getMinCoinTxOut :: PParams era -> LegacyTxOut era -> Coin
  getMinCoinTxOut pp txOut =
    let ProtVer version _ = pp ^. ppProtocolVersionL
     in getMinCoinSizedTxOut pp (mkSized version txOut)

-- | Construct and inspect outputs whose capacity deposit is held in a separate
-- store. Their value contains application assets only.
class EraNewTxOut era where
  {-# MINIMAL mkBasicNewTxOut, applicationAssetsTxOutL #-}

  -- | Construct an output from an address and its application assets, from Dijkstra onwards.
  mkBasicNewTxOut ::
    (HasCallStack, AtLeastEra "Dijkstra" era) =>
    Addr ->
    ApplicationAssets era ->
    NewTxOut era

  -- | Read or replace application assets without accessing the deposit store.
  applicationAssetsTxOutL :: Lens' (NewTxOut era) (ApplicationAssets era)

-- | Construct a transaction output whose value includes its implicit deposit.
mkBasicTxOutWithImplicitDeposit ::
  (EraLegacyTxOut era, HasCallStack) =>
  Addr ->
  Value era ->
  TxOut era
mkBasicTxOutWithImplicitDeposit address =
  LegacyTxOut . mkBasicLegacyTxOut address

-- | Construct a transaction output whose capacity deposit is held in a separate store.
mkBasicTxOutWithStoreBackedDeposit ::
  (EraNewTxOut era, AtLeastEra "Dijkstra" era, HasCallStack) =>
  Addr ->
  ApplicationAssets era ->
  TxOut era
mkBasicTxOutWithStoreBackedDeposit address =
  NewTxOut . mkBasicNewTxOut address

bootAddrTxOutF ::
  EraTxOut era => SimpleGetter (TxOut era) (Maybe BootstrapAddress)
bootAddrTxOutF = to $ \txOut ->
  case txOut ^. addrEitherTxOutL of
    Left (AddrBootstrap bootstrapAddr) -> Just bootstrapAddr
    Right cAddr
      | isBootstrapCompactAddr cAddr -> do
          AddrBootstrap bootstrapAddr <- Just (decompactAddr cAddr)
          Just bootstrapAddr
    _ -> Nothing
{-# INLINE bootAddrTxOutF #-}

toCompactPartial :: (HasCallStack, Val a) => a -> CompactForm a
toCompactPartial v =
  fromMaybe (error $ "Illegal value in TxOut: " <> show v) $ toCompact v

-- | Construct an ADA-only output whose coin includes its implicit deposit.
mkCoinTxOut :: EraLegacyTxOut era => Addr -> Coin -> LegacyTxOut era
mkCoinTxOut addr = mkBasicLegacyTxOut addr . inject

-- | A value is something which quantifies a transaction output.
type family Value era :: Type

-- | Assets that may include an implicit capacity deposit.
newtype Assets era = Assets {unAssets :: Value era}

deriving newtype instance NFData (Value era) => NFData (Assets era)

deriving newtype instance Semigroup (Value era) => Semigroup (Assets era)

deriving newtype instance Monoid (Value era) => Monoid (Assets era)

-- | Application assets, excluding the capacity deposit held in a separate store.
newtype ApplicationAssets era = ApplicationAssets {unApplicationAssets :: (Value era)}

deriving newtype instance Eq (Value era) => Eq (ApplicationAssets era)

deriving newtype instance Ord (Value era) => Ord (ApplicationAssets era)

deriving stock instance Show (Value era) => Show (ApplicationAssets era)

deriving newtype instance NFData (Value era) => NFData (ApplicationAssets era)

deriving newtype instance Semigroup (Value era) => Semigroup (ApplicationAssets era)

deriving newtype instance Monoid (Value era) => Monoid (ApplicationAssets era)

-- | Sum the assets held in outputs. Implicit deposits remain included;
-- deposits held in the separate store are not part of this balance.
sumAllAssets ::
  (EraTxOut era, Foldable f) => f (TxOut era) -> Assets era
sumAllAssets = foldMap' $ \case
  LegacyTxOut txOut -> Assets (txOut ^. valueTxOutL)
  NewTxOut txOut -> coerce (txOut ^. applicationAssetsTxOutL)
{-# INLINE sumAllAssets #-}

-- | Sum the value held in legacy outputs.
sumAllValue ::
  (EraLegacyTxOut era, Foldable f) => f (LegacyTxOut era) -> Value era
sumAllValue = foldMap' (^. valueTxOutL)
{-# INLINE sumAllValue #-}

-- | Sum the application assets of store-backed outputs.
sumAllApplicationAssets ::
  (EraNewTxOut era, Monoid (ApplicationAssets era), Foldable f) =>
  f (NewTxOut era) -> ApplicationAssets era
sumAllApplicationAssets = foldMap' (^. applicationAssetsTxOutL)
{-# INLINE sumAllApplicationAssets #-}

-- | Sum the ADA held in outputs.
--
-- /Warning/ - Care should be taken since it is susceptible to integer overflow, therefore make sure
-- this function is not applied to unvalidated 'TxOut's.
sumAllCoin :: (EraTxOut era, Foldable f) => f (TxOut era) -> Coin
sumAllCoin = fromCompact . CompactCoin . getSum . foldMap' getCoinWord64
  where
    getCoinWord64 txOut =
      case txOut ^. compactCoinTxOutL of
        CompactCoin w64 -> Sum w64
{-# INLINE sumAllCoin #-}

-- | Check that every output contains only ADA, without non-ADA assets.
areAllAdaOnly :: (EraTxOut era, Foldable f) => f (TxOut era) -> Bool
areAllAdaOnly = all (^. isAdaOnlyTxOutF)
{-# INLINE areAllAdaOnly #-}
