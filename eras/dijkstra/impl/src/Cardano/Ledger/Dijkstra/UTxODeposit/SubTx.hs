{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternSynonyms #-}

-- | Explicit UTxO capacity deposit declarations for a sub-transaction.
-- Import qualified to distinguish these constructors from TopTx declarations.
module Cardano.Ledger.Dijkstra.UTxODeposit.SubTx (
  SubTxUTxODepositDeclaration (
    NoUTxODepositDeclaration,
    DeclaresZeroNetUTxODeposit,
    DeclaresNetUTxODepositAllocation,
    DeclaresNetUTxODepositRelease,
    RequestsUTxODepositFromTopTx
  ),
  hasUTxODepositDeclaration,
  declareUTxODepositChange,
  encodeKeyedUTxODepositDeclaration,
  SubTxNetUTxODepositChange (..),
  SubTxReleaseTarget (..),
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

-- | Absence requests neither an operation nor delegation. An explicit zero is
-- still a declaration and therefore requires a TopTx declaration.
newtype SubTxUTxODepositDeclaration
  = MkSubTxUTxODepositDeclaration (StrictMaybe SubTxNetUTxODepositChange)
  deriving stock (Eq, Generic)
  deriving newtype (NFData, NoThunks, ToJSON, FromJSON)

pattern NoUTxODepositDeclaration :: SubTxUTxODepositDeclaration
pattern NoUTxODepositDeclaration = MkSubTxUTxODepositDeclaration SNothing

pattern DeclaresZeroNetUTxODeposit :: SubTxUTxODepositDeclaration
pattern DeclaresZeroNetUTxODeposit = MkSubTxUTxODepositDeclaration (SJust SubTxNoUTxODepositChange)

pattern DeclaresNetUTxODepositAllocation :: PositiveCoin -> SubTxUTxODepositDeclaration
pattern DeclaresNetUTxODepositAllocation amount =
  MkSubTxUTxODepositDeclaration (SJust (SubTxAllocateUTxODeposit amount))

pattern DeclaresNetUTxODepositRelease ::
  PositiveCoin -> SubTxReleaseTarget -> SubTxUTxODepositDeclaration
pattern DeclaresNetUTxODepositRelease amount target =
  MkSubTxUTxODepositDeclaration (SJust (SubTxReleaseUTxODeposit amount target))

pattern RequestsUTxODepositFromTopTx :: PositiveCoin -> SubTxUTxODepositDeclaration
pattern RequestsUTxODepositFromTopTx amount =
  MkSubTxUTxODepositDeclaration (SJust (SubTxRequestUTxODepositFromTopTx amount))

{-# COMPLETE
  NoUTxODepositDeclaration
  , DeclaresZeroNetUTxODeposit
  , DeclaresNetUTxODepositAllocation
  , DeclaresNetUTxODepositRelease
  , RequestsUTxODepositFromTopTx
  #-}

instance Show SubTxUTxODepositDeclaration where
  showsPrec precedence = \case
    NoUTxODepositDeclaration -> showString "SubTx.NoUTxODepositDeclaration"
    DeclaresZeroNetUTxODeposit -> showString "SubTx.DeclaresZeroNetUTxODeposit"
    DeclaresNetUTxODepositAllocation amount ->
      showParen (precedence > 10) $
        showString "SubTx.DeclaresNetUTxODepositAllocation " . showsPrec 11 amount
    DeclaresNetUTxODepositRelease amount target ->
      showParen (precedence > 10) $
        showString "SubTx.DeclaresNetUTxODepositRelease "
          . showsPrec 11 amount
          . showChar ' '
          . showsPrec 11 target
    RequestsUTxODepositFromTopTx amount ->
      showParen (precedence > 10) $
        showString "SubTx.RequestsUTxODepositFromTopTx " . showsPrec 11 amount

-- | Explicit zero counts as a declaration.
hasUTxODepositDeclaration :: SubTxUTxODepositDeclaration -> Bool
hasUTxODepositDeclaration NoUTxODepositDeclaration = False
hasUTxODepositDeclaration _ = True

-- | Wrap a present wire payload without collapsing an explicit zero into absence.
declareUTxODepositChange :: SubTxNetUTxODepositChange -> SubTxUTxODepositDeclaration
declareUTxODepositChange = MkSubTxUTxODepositDeclaration . SJust

-- | Preserve the optional key and payload encoding without encoding the wrapper.
encodeKeyedUTxODepositDeclaration ::
  Word -> SubTxUTxODepositDeclaration -> Encode (Closed Sparse) SubTxUTxODepositDeclaration
encodeKeyedUTxODepositDeclaration key (MkSubTxUTxODepositDeclaration change) =
  MapE MkSubTxUTxODepositDeclaration $ encodeKeyedStrictMaybe key change

-- | Settle a net release in the sub-transaction's own output, or explicitly
-- request that the top-level transaction account for it. A local output's
-- coin value already includes the settlement amount.
data SubTxReleaseTarget
  = SubTxSettlementOutput !TxIx
  | DelegateToTopTx
  deriving (Eq, Show, Generic)

instance NFData SubTxReleaseTarget

instance NoThunks SubTxReleaseTarget

instance EncCBOR SubTxReleaseTarget where
  encCBOR =
    encode . \case
      SubTxSettlementOutput outputIndex -> Sum SubTxSettlementOutput 0 !> To outputIndex
      DelegateToTopTx -> Sum DelegateToTopTx 1

instance DecCBOR SubTxReleaseTarget where
  decCBOR = decode $ Summands "SubTxReleaseTarget" $ \case
    0 -> SumD SubTxSettlementOutput <! From
    1 -> SumD DelegateToTopTx
    tag -> Invalid tag

instance ToJSON SubTxReleaseTarget where
  toJSON = \case
    SubTxSettlementOutput outputIndex -> kindObjectValue "subTxSettlementOutput" ["outputIndex" .= outputIndex]
    DelegateToTopTx -> kindObjectValue "delegateToTopTx" []

instance FromJSON SubTxReleaseTarget where
  parseJSON = withObject "SubTxReleaseTarget" $ \fields ->
    (fields .: "kind" :: Parser String) >>= \case
      "subTxSettlementOutput" -> SubTxSettlementOutput . TxIx <$> fields .: "outputIndex"
      "delegateToTopTx" -> pure DelegateToTopTx
      kind -> fail $ "Unknown SubTxReleaseTarget kind: " <> kind

-- | The net UTxO capacity deposit change explicitly declared by a sub-transaction.
-- The sub-transaction supplies a positive amount even when it requests allocation
-- funding or delegates release accounting to TopTx.
-- 'SubTxNoUTxODepositChange' explicitly declares zero and requests no delegation.
-- Absence of this field requests neither an operation nor delegation.
data SubTxNetUTxODepositChange
  = SubTxNoUTxODepositChange
  | SubTxAllocateUTxODeposit !PositiveCoin
  | SubTxRequestUTxODepositFromTopTx !PositiveCoin
  | SubTxReleaseUTxODeposit !PositiveCoin !SubTxReleaseTarget
  deriving (Eq, Show, Generic)

instance NFData SubTxNetUTxODepositChange

instance NoThunks SubTxNetUTxODepositChange

instance EncCBOR SubTxNetUTxODepositChange where
  encCBOR =
    encode . \case
      SubTxNoUTxODepositChange -> Sum SubTxNoUTxODepositChange 3
      SubTxAllocateUTxODeposit amount -> Sum SubTxAllocateUTxODeposit 0 !> To amount
      SubTxRequestUTxODepositFromTopTx amount -> Sum SubTxRequestUTxODepositFromTopTx 2 !> To amount
      SubTxReleaseUTxODeposit amount target -> Sum SubTxReleaseUTxODeposit 1 !> To amount !> To target

instance DecCBOR SubTxNetUTxODepositChange where
  decCBOR = decode $ Summands "SubTxNetUTxODepositChange" $ \case
    0 -> SumD SubTxAllocateUTxODeposit <! From
    1 -> SumD SubTxReleaseUTxODeposit <! From <! From
    2 -> SumD SubTxRequestUTxODepositFromTopTx <! From
    3 -> SumD SubTxNoUTxODepositChange
    tag -> Invalid tag

instance ToJSON SubTxNetUTxODepositChange where
  toJSON = \case
    SubTxNoUTxODepositChange -> kindObjectValue "noChange" []
    SubTxAllocateUTxODeposit amount -> kindObjectValue "allocate" ["amount" .= amount]
    SubTxRequestUTxODepositFromTopTx amount -> kindObjectValue "requestUTxODepositFromTopTx" ["amount" .= amount]
    SubTxReleaseUTxODeposit amount target ->
      kindObjectValue "release" ["amount" .= amount, "target" .= target]

instance FromJSON SubTxNetUTxODepositChange where
  parseJSON = withObject "SubTxNetUTxODepositChange" $ \fields ->
    (fields .: "kind" :: Parser String) >>= \case
      "noChange" -> pure SubTxNoUTxODepositChange
      "allocate" -> SubTxAllocateUTxODeposit <$> fields .: "amount"
      "requestUTxODepositFromTopTx" -> SubTxRequestUTxODepositFromTopTx <$> fields .: "amount"
      "release" -> SubTxReleaseUTxODeposit <$> fields .: "amount" <*> fields .: "target"
      kind -> fail $ "Unknown SubTxNetUTxODepositChange kind: " <> kind
