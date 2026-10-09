{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternSynonyms #-}

-- | Explicit UTxO capacity deposit declarations for the top-level transaction.
-- Import qualified to distinguish these constructors from SubTx declarations.
module Cardano.Ledger.Dijkstra.UTxODeposit.TopTx (
  TopTxUTxODepositDeclaration (
    NoUTxODepositDeclaration,
    DeclaresZeroNetUTxODeposit,
    DeclaresNetUTxODepositAllocation,
    DeclaresNetUTxODepositRelease
  ),
  hasUTxODepositDeclaration,
  declareUTxODepositChange,
  encodeKeyedUTxODepositDeclaration,
  NetUTxODepositChange (..),
  TopTxReleaseSettlement (..),
) where

import Cardano.Ledger.BaseTypes (StrictMaybe (..), TxIx (..), kindObjectValue)
import Cardano.Ledger.Binary (DecCBOR (..), EncCBOR (..))
import Cardano.Ledger.Binary.Coders
import Cardano.Ledger.Coin (PositiveCoin)
import Control.DeepSeq (NFData)
import Data.Aeson (FromJSON (..), ToJSON (..), withObject, (.:), (.=))
import Data.Aeson.Types (Parser)
import GHC.Generics (Generic)
import NoThunks.Class (NoThunks)

-- | Absence makes no declaration; an explicit zero still makes a declaration.
-- The underlying optional payload is exposed only through the codec accessors.
newtype TopTxUTxODepositDeclaration
  = MkTopTxUTxODepositDeclaration (StrictMaybe NetUTxODepositChange)
  deriving stock (Eq, Generic)
  deriving newtype (NFData, NoThunks, ToJSON, FromJSON)

pattern NoUTxODepositDeclaration :: TopTxUTxODepositDeclaration
pattern NoUTxODepositDeclaration = MkTopTxUTxODepositDeclaration SNothing

pattern DeclaresZeroNetUTxODeposit :: TopTxUTxODepositDeclaration
pattern DeclaresZeroNetUTxODeposit = MkTopTxUTxODepositDeclaration (SJust NoUTxODepositChange)

pattern DeclaresNetUTxODepositAllocation :: PositiveCoin -> TopTxUTxODepositDeclaration
pattern DeclaresNetUTxODepositAllocation amount =
  MkTopTxUTxODepositDeclaration (SJust (AllocateUTxODeposit amount))

pattern DeclaresNetUTxODepositRelease ::
  PositiveCoin -> TopTxReleaseSettlement -> TopTxUTxODepositDeclaration
pattern DeclaresNetUTxODepositRelease amount settlement =
  MkTopTxUTxODepositDeclaration (SJust (ReleaseUTxODeposit amount settlement))

{-# COMPLETE
  NoUTxODepositDeclaration
  , DeclaresZeroNetUTxODeposit
  , DeclaresNetUTxODepositAllocation
  , DeclaresNetUTxODepositRelease
  #-}

instance Show TopTxUTxODepositDeclaration where
  showsPrec precedence = \case
    NoUTxODepositDeclaration -> showString "TopTx.NoUTxODepositDeclaration"
    DeclaresZeroNetUTxODeposit -> showString "TopTx.DeclaresZeroNetUTxODeposit"
    DeclaresNetUTxODepositAllocation amount ->
      showParen (precedence > 10) $
        showString "TopTx.DeclaresNetUTxODepositAllocation " . showsPrec 11 amount
    DeclaresNetUTxODepositRelease amount settlement ->
      showParen (precedence > 10) $
        showString "TopTx.DeclaresNetUTxODepositRelease "
          . showsPrec 11 amount
          . showChar ' '
          . showsPrec 11 settlement

-- | Explicit zero counts as a declaration.
hasUTxODepositDeclaration :: TopTxUTxODepositDeclaration -> Bool
hasUTxODepositDeclaration NoUTxODepositDeclaration = False
hasUTxODepositDeclaration _ = True

-- | Wrap a present wire payload without collapsing an explicit zero into absence.
declareUTxODepositChange :: NetUTxODepositChange -> TopTxUTxODepositDeclaration
declareUTxODepositChange = MkTopTxUTxODepositDeclaration . SJust

-- | Preserve the optional key and payload encoding without encoding the wrapper.
encodeKeyedUTxODepositDeclaration ::
  Word -> TopTxUTxODepositDeclaration -> Encode (Closed Sparse) TopTxUTxODepositDeclaration
encodeKeyedUTxODepositDeclaration key (MkTopTxUTxODepositDeclaration change) =
  MapE MkTopTxUTxODepositDeclaration $ encodeKeyedStrictMaybe key change

-- | The net UTxO capacity deposit change for the entire transaction batch.
-- 'NoUTxODepositChange' explicitly declares zero; an absent field makes no declaration.
-- A net release separately declares whether TopTx receives a settlement amount;
-- SubTx settlement outputs remain in their own declarations.
data NetUTxODepositChange
  = NoUTxODepositChange
  | AllocateUTxODeposit !PositiveCoin
  | ReleaseUTxODeposit !PositiveCoin !TopTxReleaseSettlement
  deriving (Eq, Show, Generic)

instance NFData NetUTxODepositChange

instance NoThunks NetUTxODepositChange

instance EncCBOR NetUTxODepositChange where
  encCBOR =
    encode . \case
      NoUTxODepositChange -> Sum NoUTxODepositChange 2
      AllocateUTxODeposit amount -> Sum AllocateUTxODeposit 0 !> To amount
      ReleaseUTxODeposit amount settlement -> Sum ReleaseUTxODeposit 1 !> To amount !> To settlement

instance DecCBOR NetUTxODepositChange where
  decCBOR = decode $ Summands "NetUTxODepositChange" $ \case
    0 -> SumD AllocateUTxODeposit <! From
    1 -> SumD ReleaseUTxODeposit <! From <! From
    2 -> SumD NoUTxODepositChange
    tag -> Invalid tag

instance ToJSON NetUTxODepositChange where
  toJSON = \case
    NoUTxODepositChange -> kindObjectValue "noChange" []
    AllocateUTxODeposit amount -> kindObjectValue "allocate" ["amount" .= amount]
    ReleaseUTxODeposit amount settlement ->
      kindObjectValue "release" ["amount" .= amount, "settlement" .= settlement]

instance FromJSON NetUTxODepositChange where
  parseJSON = withObject "NetUTxODepositChange" $ \fields ->
    (fields .: "kind" :: Parser String) >>= \case
      "noChange" -> pure NoUTxODepositChange
      "allocate" -> AllocateUTxODeposit <$> fields .: "amount"
      "release" -> ReleaseUTxODeposit <$> fields .: "amount" <*> fields .: "settlement"
      kind -> fail $ "Unknown NetUTxODepositChange kind: " <> kind

-- | Whether TopTx receives a settlement amount from the batch's net release.
-- 'TopTxSettlementOutput' names a zero-based index into TopTx's own outputs and
-- permits simultaneous settlement in SubTx outputs. The selected output already
-- includes TopTx's settlement amount, which need not equal the batch's net release.
data TopTxReleaseSettlement
  = NoTopTxSettlement
  | TopTxSettlementOutput !TxIx
  deriving (Eq, Show, Generic)

instance NFData TopTxReleaseSettlement

instance NoThunks TopTxReleaseSettlement

instance EncCBOR TopTxReleaseSettlement where
  encCBOR =
    encode . \case
      NoTopTxSettlement -> Sum NoTopTxSettlement 0
      TopTxSettlementOutput outputIndex -> Sum TopTxSettlementOutput 1 !> To outputIndex

instance DecCBOR TopTxReleaseSettlement where
  decCBOR = decode $ Summands "TopTxReleaseSettlement" $ \case
    0 -> SumD NoTopTxSettlement
    1 -> SumD TopTxSettlementOutput <! From
    tag -> Invalid tag

instance ToJSON TopTxReleaseSettlement where
  toJSON = \case
    NoTopTxSettlement -> kindObjectValue "noTopTxSettlement" []
    TopTxSettlementOutput outputIndex ->
      kindObjectValue "topTxSettlementOutput" ["outputIndex" .= outputIndex]

instance FromJSON TopTxReleaseSettlement where
  parseJSON = withObject "TopTxReleaseSettlement" $ \fields ->
    (fields .: "kind" :: Parser String) >>= \case
      "noTopTxSettlement" -> pure NoTopTxSettlement
      "topTxSettlementOutput" -> TopTxSettlementOutput . TxIx <$> fields .: "outputIndex"
      kind -> fail $ "Unknown TopTxReleaseSettlement kind: " <> kind
