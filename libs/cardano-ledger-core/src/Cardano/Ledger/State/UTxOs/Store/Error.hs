{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Validation errors shared by allocation metadata and the store.
module Cardano.Ledger.State.UTxOs.Store.Error (
  OutputStoreError (..),
) where

import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..))
import Cardano.Ledger.Binary.Coders
import Cardano.Ledger.TxIn (TxIn)
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON)
import Data.Int (Int64)
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

data OutputStoreError
  = NegativeOutputSize !Int64
  | MissingHistoricalAllocation !TxIn
  deriving (Eq, Ord, Show, Generic)

instance NFData OutputStoreError

instance NoThunks OutputStoreError

instance ToJSON OutputStoreError

instance EncCBOR OutputStoreError where
  encCBOR =
    encode . \case
      NegativeOutputSize size -> Sum NegativeOutputSize 0 !> To size
      MissingHistoricalAllocation input -> Sum MissingHistoricalAllocation 2 !> To input

instance DecCBOR OutputStoreError where
  decCBOR = decode $ Summands "OutputStoreError" $ \case
    0 -> SumD NegativeOutputSize <! From
    2 -> SumD MissingHistoricalAllocation <! From
    -- Retired error tags 1, 3, 4 and 5 must not be reused.
    tag -> Invalid tag
