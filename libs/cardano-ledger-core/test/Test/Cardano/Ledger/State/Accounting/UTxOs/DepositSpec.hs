{-# LANGUAGE TypeApplications #-}

module Test.Cardano.Ledger.State.Accounting.UTxOs.DepositSpec (spec) where

import Cardano.Ledger.BaseTypes (SlotNo (..))
import Cardano.Ledger.Binary (
  EncCBOR (encCBOR),
  allVersions,
  decodeFull,
  encodeListLen,
  encodeMapLen,
  encodeNull,
  encodeWord,
  serialize,
 )
import Cardano.Ledger.Coin (CoinPerByte (..), CompactForm (CompactCoin))
import Cardano.Ledger.State.Accounting.UTxOs.Deposit
import Data.Default (def)
import Data.Either (isLeft)
import qualified Data.Map.Strict as Map
import Data.Word (Word64)
import Test.Cardano.Ledger.Common
import Test.Cardano.Ledger.Core.Arbitrary ()

spec :: Spec
spec = describe "DepositFormulaHistory: allocation slot selects its historical formula" $ do
  it "default baseline = V1 at 4310 lovelace per byte, with no dated activation" $ do
    let expected = DepositFormulaV1 $ CoinPerByte $ CompactCoin 4310
        history = def :: DepositFormulaHistory
    (def :: DepositFormula) `shouldBe` expected
    history `shouldBe` mkDepositFormulaHistory expected
    initialFormula history `shouldBe` expected
    latestFormula history `shouldBe` expected
    formulaChanges history `shouldBe` Map.empty
    periods history `shouldBe` [DepositPeriod Nothing Nothing expected]
    forM_ [SlotNo 0, SlotNo maxBound] $ \slot ->
      formulaAt slot history `shouldBe` expected

  prop "no activations ⇒ the baseline applies at every slot" $ \slot pricing -> do
    let history = mkDepositFormulaHistory pricing
    initialFormula history `shouldBe` pricing
    formulaChanges history `shouldBe` Map.empty
    latestFormula history `shouldBe` pricing
    formulaAt slot history `shouldBe` pricing
    periods history `shouldBe` [DepositPeriod Nothing Nothing pricing]

  prop "first activation at any slot ⇒ baseline before it; new formula from it" $ \generatedSlot baseline next ->
    forM_ [SlotNo 0, generatedSlot, SlotNo maxBound] $ \slot -> do
      history <- expectJust $ appendFormula slot next $ mkDepositFormulaHistory baseline
      formulaChanges history `shouldBe` Map.singleton slot next
      formulaAt slot history `shouldBe` next
      latestFormula history `shouldBe` next
      initialFormula history `shouldBe` baseline
      periods history
        `shouldBe` [ DepositPeriod Nothing (Just slot) baseline
                   , DepositPeriod (Just slot) Nothing next
                   ]

  prop "zero-priced baseline remains explicit before the first activation" $ \next ->
    forAll (choose (1, maxBound :: Word64)) $ \start -> do
      let baseline = DepositFormulaV1 $ CoinPerByte $ CompactCoin 0
      history <- expectJust $ appendFormula (SlotNo start) next $ mkDepositFormulaHistory baseline
      formulaAt (SlotNo 0) history `shouldBe` baseline
      formulaAt (SlotNo $ start - 1) history `shouldBe` baseline
      formulaAt (SlotNo start) history `shouldBe` next

  prop "activation at b ⇒ b − 1 uses V1; b and b + 1 use V2" $ \oldRate newRate ->
    forAll (choose (1, maxBound - 1 :: Word64)) $ \boundary -> do
      let previousFormula = DepositFormulaV1 oldRate
          nextFormula = DepositFormulaV2 newRate
      history <-
        expectJust $
          appendFormula (SlotNo boundary) nextFormula $
            mkDepositFormulaHistory previousFormula
      formulaAt (SlotNo $ boundary - 1) history `shouldBe` previousFormula
      formulaAt (SlotNo boundary) history `shouldBe` nextFormula
      formulaAt (SlotNo $ boundary + 1) history `shouldBe` nextFormula
      periods history
        `shouldBe` [ DepositPeriod Nothing (Just $ SlotNo boundary) previousFormula
                   , DepositPeriod (Just $ SlotNo boundary) Nothing nextFormula
                   ]

  prop "A → B → A retains the baseline and both activations" $ \firstRate secondRate -> do
    let first = DepositFormulaV1 firstRate
        second = DepositFormulaV2 secondRate
    withSecond <- expectJust $ appendFormula (SlotNo 200) second $ mkDepositFormulaHistory first
    history <- expectJust $ appendFormula (SlotNo 300) first withSecond
    periods history
      `shouldBe` [ DepositPeriod Nothing (Just $ SlotNo 200) first
                 , DepositPeriod (Just $ SlotNo 200) (Just $ SlotNo 300) second
                 , DepositPeriod (Just $ SlotNo 300) Nothing first
                 ]
    formulaAt (SlotNo 199) history `shouldBe` first
    formulaAt (SlotNo 250) history `shouldBe` second
    formulaAt (SlotNo maxBound) history `shouldBe` first
    latestFormula history `shouldBe` first
    initialFormula withSecond `shouldBe` first
    initialFormula history `shouldBe` first

  prop "activation at or before the last activation ⇒ history cannot be rewritten" $ \first second ->
    forAll (choose (0, maxBound :: Word64)) $ \latest ->
      forAll (choose (0, latest)) $ \backdated -> do
        history <- expectJust $ appendFormula (SlotNo latest) second $ mkDepositFormulaHistory first
        appendFormula (SlotNo backdated) first history `shouldBe` Nothing
        appendFormula (SlotNo latest) second history `shouldBe` Nothing

  prop "new activation at b ⇒ every earlier slot retains its formula" $ \first second ->
    forAll (choose (1, maxBound :: Word64)) $ \boundary ->
      forAll (choose (0, boundary - 1)) $ \earlier -> do
        let previous = mkDepositFormulaHistory first
        updated <- expectJust $ appendFormula (SlotNo boundary) second previous
        formulaAt (SlotNo earlier) updated `shouldBe` formulaAt (SlotNo earlier) previous

  prop "CBOR preserves the baseline and ordered activations, including an empty activation map" $ \first second -> do
    changed <- expectJust $ appendFormula (SlotNo 200) second $ mkDepositFormulaHistory first
    repeated <- expectJust $ appendFormula (SlotNo maxBound) first changed
    forM_ [mkDepositFormulaHistory first, changed, repeated] $ \history ->
      forM_ allVersions $ \version ->
        decodeFull @DepositFormulaHistory version (serialize version history) `shouldBe` Right history

  prop "baseline with no activations encodes as [baseline, {}]" $ \baseline ->
    forM_ allVersions $ \version -> do
      let encoded = encodeListLen 2 <> encCBOR baseline <> encodeMapLen 0
      serialize version (mkDepositFormulaHistory baseline) `shouldBe` serialize version encoded
      decodeFull @DepositFormulaHistory version (serialize version encoded)
        `shouldBe` Right (mkDepositFormulaHistory baseline)

  prop "retired null and map-only histories ⇒ decoding rejected" $ \baseline ->
    forM_ allVersions $ \version ->
      forM_
        [encodeNull, encodeMapLen 0, encCBOR $ Map.singleton (SlotNo 100) (baseline :: DepositFormula)]
        $ \encoded ->
          decodeFull @DepositFormulaHistory version (serialize version encoded) `shouldSatisfy` isLeft

  prop "duplicate or descending activation slots ⇒ decoding rejected without losing entries" $ \baseline first second ->
    forM_ [SlotNo 100, SlotNo 99] $ \nextSlot ->
      forM_ allVersions $ \version -> do
        let encoded =
              encodeListLen 2
                <> encCBOR (baseline :: DepositFormula)
                <> encodeMapLen 2
                <> encCBOR (SlotNo 100)
                <> encCBOR (first :: DepositFormula)
                <> encCBOR nextSlot
                <> encCBOR (second :: DepositFormula)
        decodeFull @DepositFormulaHistory version (serialize version encoded) `shouldSatisfy` isLeft

  it "unknown formula version in the baseline or an activation ⇒ decoding rejected" $
    forM_ allVersions $ \version -> do
      let known = encCBOR $ DepositFormulaV1 $ CoinPerByte $ CompactCoin 4310
          unknown = encodeListLen 2 <> encodeWord 3 <> encCBOR (CoinPerByte $ CompactCoin 4310)
      forM_
        [ encodeListLen 2 <> unknown <> encodeMapLen 0
        , encodeListLen 2 <> known <> encodeMapLen 1 <> encCBOR (SlotNo 100) <> unknown
        ]
        $ \encoded -> decodeFull @DepositFormulaHistory version (serialize version encoded) `shouldSatisfy` isLeft
