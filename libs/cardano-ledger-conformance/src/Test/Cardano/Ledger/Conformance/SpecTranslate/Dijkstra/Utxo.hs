{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Test.Cardano.Ledger.Conformance.SpecTranslate.Dijkstra.Utxo () where

import Cardano.Ledger.Dijkstra (DijkstraEra)
import Cardano.Ledger.Shelley.LedgerState (AccountingState (..))
import Cardano.Ledger.State (
  allocations,
 )
import qualified MAlonzo.Code.Ledger.Dijkstra.Foreign.API as Agda
import Test.Cardano.Ledger.Conformance.SpecTranslate.Base (
  SpecTranslate (..),
 )
import Test.Cardano.Ledger.Conformance.SpecTranslate.Dijkstra.Base ()

instance SpecTranslate DijkstraEra (AccountingState DijkstraEra) where
  type SpecRep DijkstraEra (AccountingState DijkstraEra) = Agda.UTxOState

  toSpecRep AccountingState {..} =
    Agda.MkUTxOState
      <$> (toSpecRep . allocations $ asUTxOStore)
      <*> toSpecRep asFees
      <*> toSpecRep asDonation
