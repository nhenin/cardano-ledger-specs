{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Unspent outputs and the metadata retained for their deposit formula.
module Cardano.Ledger.State.Accounting.UTxOs.Unspent (
  AllocatedAt (..),
  Unspent (..),
  toTxOut,
  allocationFormula,
  computeExternalDeposit,
  encodeWith,
  fromLegacyTxOut,
) where

import Cardano.Ledger.BaseTypes (SlotNo)
import Cardano.Ledger.Binary (
  DecCBOR (..),
  DecShareCBOR (..),
  Decoder,
  EncCBOR (..),
  Encoding,
  decodeRecordNamed,
  decodeRecordSum,
  encodeListLen,
  encodeWord,
 )
import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (
  DepositFormula,
  DepositFormulaHistory (initialFormula),
  formulaAt,
 )
import Cardano.Ledger.TxOut (
  EraNewTxOut (..),
  EraTxOut (LegacyTxOut),
  TxOut (..),
 )
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON (..), object, (.=))
import GHC.Generics (Generic)
import NoThunks.Class (InspectHeapNamed (..), NoThunks)

-- | The first Store migration or a subsequent dated allocation. Migration
-- entries permanently use the history's initial formula; no original
-- creation date is invented for outputs imported from a legacy representation.
data AllocatedAt
  = AtStoreMigration
  | AtSlot !SlotNo
  deriving (Eq, Ord, Show, Generic)

-- | An accepted output and the origin that selects its deposit formula.
data Unspent output = Unspent
  { output :: !output
  , allocatedAt :: !AllocatedAt
  }
  deriving (Eq, Show, Generic)

-- | Import an output whose legacy encoding contains neither a creation slot
-- nor pricing metadata. The migration marker resolves the initial Store formula;
-- earlier-era payload codecs continue to contain no new metadata.
fromLegacyTxOut :: LegacyTxOut era -> Unspent (TxOut era)
fromLegacyTxOut txOut = Unspent (LegacyTxOut txOut) AtStoreMigration

toTxOut :: Unspent (TxOut era) -> TxOut era
toTxOut = output

-- | The contribution to the separately held Store total. A legacy reserve is
-- already included in its output and must never be credited a second time.
-- Only eras supporting new outputs implement their deposit formula.
computeExternalDeposit :: EraNewTxOut era => DepositFormulaHistory -> Unspent (TxOut era) -> Coin
computeExternalDeposit history (Unspent txOut origin) = case txOut of
  LegacyTxOut _ -> mempty
  NewTxOut newOutput -> getDepositNewTxOut (allocationFormula history origin) newOutput

-- | Resolve the migration baseline or the interval containing a dated allocation.
allocationFormula :: DepositFormulaHistory -> AllocatedAt -> DepositFormula
allocationFormula history origin = case origin of
  AtStoreMigration -> initialFormula history
  AtSlot slot -> formulaAt slot history

instance NFData AllocatedAt

instance NoThunks AllocatedAt

instance ToJSON AllocatedAt where
  toJSON origin = case origin of
    AtStoreMigration -> object ["kind" .= ("atStoreMigration" :: String)]
    AtSlot slot -> object ["kind" .= ("atSlot" :: String), "slot" .= slot]

instance EncCBOR AllocatedAt where
  encCBOR origin = case origin of
    AtStoreMigration -> encodeListLen 1 <> encodeWord 0
    -- Tags 1 and 2 belonged to retired per-entry formula encodings.
    AtSlot slot -> encodeListLen 2 <> encodeWord 3 <> encCBOR slot

instance DecCBOR AllocatedAt where
  decCBOR = decodeRecordSum "AllocatedAt" $ \tag -> case tag of
    0 -> pure (1, AtStoreMigration)
    3 -> (\slot -> (2, AtSlot slot)) <$> decCBOR
    _ -> fail $ "AllocatedAt: unknown allocation origin " <> show tag

instance NFData a => NFData (Unspent a)

deriving via
  InspectHeapNamed "Unspent" (Unspent a)
  instance
    NoThunks (Unspent a)

instance ToJSON a => ToJSON (Unspent a) where
  toJSON (Unspent value origin) =
    object ["output" .= value, "allocatedAt" .= origin]

instance EncCBOR a => EncCBOR (Unspent a) where
  encCBOR = encodeWith encCBOR

instance DecCBOR a => DecCBOR (Unspent a) where
  decCBOR = decodeUnspent decCBOR

instance DecShareCBOR a => DecShareCBOR (Unspent a) where
  type Share (Unspent a) = Share a
  decShareCBOR sharing = decodeUnspent $ decShareCBOR sharing

decodeUnspent :: Decoder s a -> Decoder s (Unspent a)
decodeUnspent decodeOutput =
  decodeRecordNamed "Unspent" (const 2) $
    Unspent <$> decodeOutput <*> decCBOR

encodeWith :: (a -> Encoding) -> Unspent a -> Encoding
encodeWith encodeOutput (Unspent value origin) =
  encodeListLen 2 <> encodeOutput value <> encCBOR origin
