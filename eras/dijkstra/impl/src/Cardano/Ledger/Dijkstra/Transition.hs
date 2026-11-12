{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Cardano.Ledger.Dijkstra.Transition (
  TransitionConfig (..),
  seatInitialLeiosCommittee,
) where

import Cardano.Ledger.Alonzo.Transition (AlonzoEraTransition)
import Cardano.Ledger.Babbage.Core (ppCoinsPerUTxOByteL)
import Cardano.Ledger.Conway
import Cardano.Ledger.Conway.Transition (
  ConwayEraTransition,
  conwayInjectIntoTestState,
 )
import Cardano.Ledger.Dijkstra.Era
import Cardano.Ledger.Dijkstra.Genesis
import Cardano.Ledger.Dijkstra.PParams (ppLeiosCommitteeSizeL)
import Cardano.Ledger.Dijkstra.Rules.Snap (kesMaxKeyAgeEpochs)
import Cardano.Ledger.Dijkstra.Translation ()
import Cardano.Ledger.Shelley.Genesis (ShelleyGenesis (..))
import Cardano.Ledger.Shelley.LedgerState (
  NewEpochState,
  curPParamsEpochStateL,
  esLStateL,
  esSnapshotsL,
  lsCertStateL,
  nesELL,
  nesEsL,
 )
import Cardano.Ledger.Shelley.Transition
import Cardano.Ledger.State (
  DepositFormula (..),
  certPStateL,
  mkEmptyUTxOStore,
  mkGoSnapShot,
  mkMarkSnapShot,
  mkSetSnapShot,
  msSnapShotL,
  populateVRFKeyHashes,
  ssStakeGoL,
  ssStakeMarkL,
  ssStakeSetL,
 )
import Cardano.Ledger.State.Accounting.UTxOs.Deposit (mkDepositFormulaHistory)
import GHC.Generics
import Lens.Micro
import NoThunks.Class (NoThunks (..))

instance EraTransition DijkstraEra where
  data TransitionConfig DijkstraEra = DijkstraTransitionConfig
    { dtcDijkstraGenesis :: !DijkstraGenesis
    , dtcConwayTransitionConfig :: !(TransitionConfig ConwayEra)
    }
    deriving (Show, Eq, Generic)

  mkTransitionConfig = DijkstraTransitionConfig

  -- A chain initialized directly in Dijkstra begins its history at genesis.
  initialUTxOStore pp =
    mkEmptyUTxOStore . mkDepositFormulaHistory $ DepositFormulaV1 (pp ^. ppCoinsPerUTxOByteL)

  -- Genesis registrations bypass POOL, so restore their tracked VRF key hashes.
  -- Fund injection preserves the Store's initialized history and existing origins.
  injectIntoTestState hasFS cfg =
    fmap
      ( seatInitialLeiosCommittee cfg
          . (nesEsL . esLStateL . lsCertStateL . certPStateL %~ populateVRFKeyHashes)
      )
      . conwayInjectIntoTestState hasFS cfg

  tcPreviousEraConfigL =
    lens dtcConwayTransitionConfig (\dtc pc -> dtc {dtcConwayTransitionConfig = pc})

  tcTranslationContextL =
    lens dtcDijkstraGenesis (\dtc ag -> dtc {dtcDijkstraGenesis = ag})

instance AlonzoEraTransition DijkstraEra

-- | Seat the Leios committee (CIP-0164) on the initial stake snapshots.
--
-- Genesis never runs SNAP, and the snapshots it produces come from era-generic
-- code that has no way to reach @leiosCommitteeSize@, so they carry an empty
-- committee. Rebuild the mark snapshot here with the real epoch, committee size
-- and maximum voting key age, which also selects its committee, and seed the
-- @set@\/@go@ snapshots from it, just like 'resetStakeDistribution' did with the
-- mark snapshot that did not yet know about the committee.
seatInitialLeiosCommittee ::
  TransitionConfig DijkstraEra -> NewEpochState DijkstraEra -> NewEpochState DijkstraEra
seatInitialLeiosCommittee cfg nes =
  nes
    & nesEsL . esSnapshotsL . ssStakeMarkL .~ markSnapShot
    & nesEsL . esSnapshotsL . ssStakeSetL .~ setSnapShot
    & nesEsL . esSnapshotsL . ssStakeGoL .~ mkGoSnapShot setSnapShot
  where
    genesis = cfg ^. tcShelleyGenesisL
    maxKeyAge =
      kesMaxKeyAgeEpochs
        (sgMaxKESEvolutions genesis)
        (sgSlotsPerKESPeriod genesis)
        (sgEpochLength genesis)
    markSnapShot =
      mkMarkSnapShot
        (nes ^. nesEsL . esSnapshotsL . ssStakeMarkL . msSnapShotL)
        (nes ^. nesELL)
        (nes ^. nesEsL . curPParamsEpochStateL . ppLeiosCommitteeSizeL)
        maxKeyAge
    setSnapShot = mkSetSnapShot markSnapShot

instance ConwayEraTransition DijkstraEra

instance NoThunks (TransitionConfig DijkstraEra)
