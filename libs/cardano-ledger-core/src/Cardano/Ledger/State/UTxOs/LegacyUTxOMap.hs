{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

module Cardano.Ledger.State.UTxOs.LegacyUTxOMap (
  -- * Primitives
  UTxO (..),

  -- * Functions
  txins,
  txinLookup,
  txInsFilter,
  txouts,
  sumUTxO,
  sumCoinUTxO,
  verifyWitVKey,
  getScriptHash,
) where

import Cardano.Ledger.Binary (
  DecCBOR (..),
  DecShareCBOR (Share, decShareCBOR),
  EncCBOR (..),
  FromCBOR (..),
  Interns,
  ToCBOR (..),
  decNoShareCBOR,
  decodeMap,
 )
import Cardano.Ledger.Coin (Coin)
import Cardano.Ledger.Core
import Cardano.Ledger.Credential (Credential (..))
import Cardano.Ledger.Keys (verifySignedDSIGN)
import Cardano.Ledger.Keys.WitVKey (WitVKey (..))
import Cardano.Ledger.TxIn (TxIn (..))
import Cardano.Ledger.TxOut (sumAllAssets, sumAllCoin)
import Control.DeepSeq (NFData)
import Control.Monad ((<$!>))
import Data.Aeson (ToJSON)
import Data.Coerce (coerce)
import Data.Default (Default)
import Data.Foldable (toList)
import qualified Data.Map.Strict as Map
import Data.Set (Set)
import GHC.Generics (Generic)
import Lens.Micro ((^.))
import NoThunks.Class (NoThunks (..))
import Quiet (Quiet (Quiet))

-- ===============================================

-- | The unspent transaction outputs.
newtype UTxO era = UTxO {unUTxO :: Map.Map TxIn (TxOut era)}
  deriving (Default, Generic, Semigroup)

instance (Era era, EncCBOR (TxOut era)) => ToCBOR (UTxO era) where
  toCBOR = toEraCBOR @era

instance
  (Era era, DecShareCBOR (TxOut era), Share (TxOut era) ~ Interns (Credential Staking)) =>
  FromCBOR (UTxO era)
  where
  fromCBOR = fromEraCBOR @era

deriving instance NoThunks (TxOut era) => NoThunks (UTxO era)

deriving instance (Era era, NFData (TxOut era)) => NFData (UTxO era)

deriving newtype instance (Era era, Eq (TxOut era)) => Eq (UTxO era)

deriving newtype instance Era era => Monoid (UTxO era)

deriving newtype instance (Era era, EncCBOR (TxOut era)) => EncCBOR (UTxO era)

instance
  (Era era, DecShareCBOR (TxOut era), Share (TxOut era) ~ Interns (Credential Staking)) =>
  DecCBOR (UTxO era)
  where
  decCBOR = decNoShareCBOR

instance
  ( DecShareCBOR (TxOut era)
  , Share (TxOut era) ~ Interns (Credential Staking)
  ) =>
  DecShareCBOR (UTxO era)
  where
  type Share (UTxO era) = Interns (Credential Staking)
  decShareCBOR credsInterns =
    UTxO <$!> decodeMap decNoShareCBOR (decShareCBOR credsInterns)

deriving via
  Quiet (UTxO era)
  instance
    Show (TxOut era) => Show (UTxO era)

deriving newtype instance ToJSON (TxOut era) => ToJSON (UTxO era)

-- | Compute the UTxO inputs of a transaction.
-- txins has the same problems as txouts, see notes below.
txins ::
  EraTxBody era =>
  TxBody t era ->
  Set TxIn
txins = (^. inputsTxBodyL)

-- | Compute the transaction outputs of a transaction.
txouts ::
  forall era l.
  EraTxBody era =>
  TxBody l era ->
  UTxO era
txouts txBody =
  UTxO $
    Map.fromList
      [ (TxIn transId idx, out)
      | (out, idx) <- zip (toList $ txBody ^. outputsTxBodyL) [minBound ..]
      ]
  where
    transId = txIdTxBody txBody

-- | Lookup a txin for a given UTxO collection
txinLookup ::
  TxIn ->
  UTxO era ->
  Maybe (TxOut era)
txinLookup txin (UTxO utxo') = Map.lookup txin utxo'

-- | Filter out TxIn's from the `UTxO` map
txInsFilter ::
  -- | Source `UTxO`
  UTxO era ->
  -- | Which of the `TxIn`s you would like to keep.
  Set TxIn ->
  UTxO era
txInsFilter (UTxO utxo') txIns = UTxO (utxo' `Map.restrictKeys` txIns)

-- | Verify a transaction body witness
verifyWitVKey ::
  Hash HASH EraIndependentTxBody ->
  WitVKey kr ->
  Bool
verifyWitVKey txbodyHash (WitVKey vkey sig) = verifySignedDSIGN vkey txbodyHash (coerce sig)
{-# INLINE verifyWitVKey #-}

-- | Determine the total balance contained in the UTxO.
sumUTxO :: EraTxOut era => UTxO era -> Assets era
sumUTxO = sumAllAssets . unUTxO
{-# INLINE sumUTxO #-}

-- | Determine the total ADA balance contained in the UTxO without summing its
-- non-ADA assets.
--
-- /Warning/ - This function cannot be applied to an untrusted `UTxO`, since it is susceptible to
-- overflow
sumCoinUTxO :: EraTxOut era => UTxO era -> Coin
sumCoinUTxO = sumAllCoin . unUTxO
{-# INLINE sumCoinUTxO #-}

-- | Extract script hash from value address with script.
getScriptHash :: Addr -> Maybe ScriptHash
getScriptHash (Addr _ (ScriptHashObj hs) _) = Just hs
getScriptHash _ = Nothing
