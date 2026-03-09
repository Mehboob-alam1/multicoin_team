# Multi-Currency Mining Simulator – Architecture

This document describes the multi-coin and rig extensions added on top of the existing idle mining app.

## Multi-Coin Support

- **Model:** `lib/models/coin.dart` – `Coin` (id, name, symbol, difficulty, baseMiningRate, marketPrice, volatilityFactor) and `Coins` registry (BTC, ETH, SOL, LTC, DOGE). Primary currency is BTC (rig costs, leaderboard).
- **PlayerData:** `coinBalances` and `lifetimeMinedByCoin` (Map<String, double>). Legacy `btcBalance` / `lifetimeMinedBtc` are kept in sync for backward compatibility and Firebase.
- **GameStateService:** 
  - `balance(coinId)`, `lifetimeMined(coinId)`, `totalRatePerCoin(coinId)`.
  - `btcBalance` and `lifetimeMinedBtc` are derived from primary coin.
  - Mining tick adds earned amounts per coin via `_addMinedToCoin`; primary balance is updated for costs (buy rig, upgrade farm).

## Mining Rigs

- **Model:** `lib/models/mining_rig.dart` – Each rig has `supportedCoins`, `ratePerCoin`, `powerConsumption`, `heatGeneration`, `upgradeLevels`, `costScaling`.
- **Legacy rigs:** laptop, gpu_rig, mining_rack, warehouse_farm, mega_facility (BTC-only, unchanged for save compatibility).
- **New rigs:** cpu_miner, gaming_gpu_rig, gpu_cluster, asic_btc, data_center_rig (multi-coin where applicable).
- **Cost:** `MiningRigs.costForCount(rig, alreadyOwned)` for exponential scaling; `GameStateService.rigCost(rig)` applies discount.

## Mining Engine

- **Per-coin rate:** `MiningEngine.effectiveRateForCoin(...)` uses difficulty and multipliers (farm, session, premium, boost, event, efficiency, prestige).
- **Formula:** `hash rate × efficiency × boosts × premium × event` with per-coin difficulty.

## Prestige & Events

- **PrestigeService:** `miningSpeedMultiplier` (+20%/level), `efficiencyMultiplier` (+15%/level), `rewardBonusMultiplier` (+10%/level). `permanentMultiplier` = speed × efficiency for mining.
- **EventService:** Event type constants `crypto_boom`, `gpu_efficiency`, `mining_rush`; multiplier and type come from Firestore/cache.

## Scalability

- New coins: add to `Coins.all` in `lib/models/coin.dart`.
- New rigs: add to `MiningRigs.all` with `supportedCoins` and `ratePerCoin`.
- No hard-coded coin logic in game loop; all coin iteration uses `Coins.all` and `rig.supportsCoin(coinId)` / `rig.rateForCoin(coinId)`.

## Backward Compatibility

- Existing saves without `coinBalances` / `lifetimeMinedByCoin` are migrated in `PlayerData.fromJson` from `btcBalance` / `lifetimeMinedBtc`.
- Leaderboard and Firebase sync still use `btcBalance` and `totalBtcPerMin` (primary currency).
- Background mining task updates both legacy fields and `coinBalances`/`lifetimeMinedByCoin` for primary coin.
