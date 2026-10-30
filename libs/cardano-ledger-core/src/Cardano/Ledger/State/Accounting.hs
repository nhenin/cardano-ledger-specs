{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Value held by the ledger and its output-derived stake index.
module Cardano.Ledger.State.Accounting (
  AccountingState (..),
  asUTxOStoreL,
  asDepositedL,
  asFeesL,
  asInstantStakeL,
  asDonationL,
) where

import Cardano.Ledger.BaseTypes (KeyValuePairs (..), ToKeyValuePairs (..))
import Cardano.Ledger.Binary (
  DecCBOR (decCBOR),
  DecShareCBOR (..),
  EncCBOR (encCBOR),
  Interns,
  decodeRecordNamed,
  encodeListLen,
 )
import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core (EraTxOut, KeyRole (Staking))
import Cardano.Ledger.Credential (Credential)
import Cardano.Ledger.State.Accounting.InstantStake
import Cardano.Ledger.State.Accounting.UTxOs (CanGetUTxOStore (..), CanSetUTxOStore (..))
import Cardano.Ledger.State.Accounting.UTxOs.Store (UTxOStore, encodeUTxOStore)
import Control.DeepSeq (NFData)
import Data.Aeson (ToJSON, (.=))
import Data.Default (Default (def))
import GHC.Generics (Generic)
import Lens.Micro (Lens', lens)
import NoThunks.Class (NoThunks)

-- | Value held by the ledger and the stake index derived from its outputs.
-- Certificate obligations and governance records are held separately; only their
-- collected deposits are held here.
data AccountingState era = AccountingState
  { asUTxOStore :: !(UTxOStore era)
  -- ^ Accepted outputs and their separately held output deposits.
  , asDeposited :: !Coin
  -- ^ Certificate and governance deposits; their obligations live in those states.
  , asFees :: !Coin
  -- ^ Collected transaction fees.
  , asInstantStake :: !(InstantStake era)
  -- ^ Cached stake derived from the current outputs.
  , asDonation :: !Coin
  -- ^ Donations awaiting transfer to the treasury at the epoch boundary.
  }
  deriving (Generic)

instance CanGetUTxOStore AccountingState

instance CanSetUTxOStore AccountingState where
  utxoStoreL = asUTxOStoreL
  {-# INLINE utxoStoreL #-}

instance CanGetInstantStake AccountingState

instance CanSetInstantStake AccountingState where
  instantStakeL = asInstantStakeL
  {-# INLINE instantStakeL #-}

instance (EraTxOut era, NFData (InstantStake era)) => NFData (AccountingState era)

deriving stock instance (EraTxOut era, Show (InstantStake era)) => Show (AccountingState era)

deriving stock instance (EraTxOut era, Eq (InstantStake era)) => Eq (AccountingState era)

instance NoThunks (InstantStake era) => NoThunks (AccountingState era)

instance (EraTxOut era, EraStake era) => EncCBOR (AccountingState era) where
  encCBOR AccountingState {..} =
    encodeListLen 5
      <> encodeUTxOStore asUTxOStore
      <> encCBOR asDeposited
      <> encCBOR asFees
      <> encCBOR asInstantStake
      <> encCBOR asDonation

instance (EraTxOut era, EraStake era) => DecShareCBOR (AccountingState era) where
  type Share (AccountingState era) = Interns (Credential Staking)
  decShareCBOR credentials =
    decodeRecordNamed "AccountingState" (const 5) $ do
      asUTxOStore <- decShareCBOR credentials
      asDeposited <- decCBOR
      asFees <- decCBOR
      asInstantStake <- decShareCBOR credentials
      asDonation <- decCBOR
      pure AccountingState {..}

deriving via
  KeyValuePairs (AccountingState era)
  instance
    (EraTxOut era, EraStake era) => ToJSON (AccountingState era)

instance (EraTxOut era, EraStake era) => ToKeyValuePairs (AccountingState era) where
  toKeyValuePairs AccountingState {..} =
    [ "outputStorage" .= asUTxOStore
    , "deposited" .= asDeposited
    , "fees" .= asFees
    , "stake" .= asInstantStake
    , "donation" .= asDonation
    ]

instance EraStake era => Default (AccountingState era) where
  def = AccountingState def mempty mempty mempty mempty

-- Field lenses

asDepositedL :: Lens' (AccountingState era) Coin
asDepositedL = lens asDeposited (\state deposited -> state {asDeposited = deposited})

asFeesL :: Lens' (AccountingState era) Coin
asFeesL = lens asFees (\state fees -> state {asFees = fees})

asUTxOStoreL :: Lens' (AccountingState era) (UTxOStore era)
asUTxOStoreL = lens asUTxOStore (\state store -> state {asUTxOStore = store})
{-# INLINE asUTxOStoreL #-}

asInstantStakeL :: Lens' (AccountingState era) (InstantStake era)
asInstantStakeL = lens asInstantStake (\state stake -> state {asInstantStake = stake})

asDonationL :: Lens' (AccountingState era) Coin
asDonationL = lens asDonation (\state donation -> state {asDonation = donation})
