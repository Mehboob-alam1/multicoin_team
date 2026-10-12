import 'dart:math' show pow;
import 'coin.dart';

class MiningRig {
  final String id;
  final String name;
  /// Legacy: BTC rate per min. Equals ratePerCoin['btc'] when BTC is supported.
  final double btcPerMin;
  final int level;
  final String assetName;
  /// Cost in primary currency (BTC). Uses exponential scaling for higher tiers.
  final double costBtc;
  /// Coins this rig can mine (e.g. ['btc'], ['btc','eth','sol']).
  final List<String> supportedCoins;
  /// Base rate (coins per min) per coin id. Keys must match [supportedCoins].
  final Map<String, double> ratePerCoin;
  /// Power draw (arbitrary units; used with EnergyCoolingService).
  final double powerConsumption;
  /// Heat generated (arbitrary units).
  final double heatGeneration;
  /// Max upgrade level (0 = no upgrades).
  final int upgradeLevels;
  /// Cost multiplier for next purchase of same type (exponential scaling).
  final double costScaling;

  const MiningRig({
    required this.id,
    required this.name,
    required this.btcPerMin,
    required this.level,
    required this.assetName,
    required this.costBtc,
    this.supportedCoins = const ['btc'],
    this.ratePerCoin = const {},
    this.powerConsumption = 1.0,
    this.heatGeneration = 1.0,
    this.upgradeLevels = 0,
    this.costScaling = 1.0,
  });

  /// Rate for a specific coin (coins per min). Primary (SOL) always uses [btcPerMin]
  /// so every rig participates in the Solana economy at the same relative ranking.
  double rateForCoin(String coinId) {
    if (coinId == Coins.primaryId) return btcPerMin;
    if (ratePerCoin.isNotEmpty && ratePerCoin.containsKey(coinId)) {
      return ratePerCoin[coinId]!;
    }
    if (coinId == 'btc') return btcPerMin;
    return 0;
  }

  bool supportsCoin(String coinId) =>
      coinId == Coins.primaryId || supportedCoins.contains(coinId);
}

/// Mining rigs: legacy (BTC-only) plus new multi-coin types. Exponential cost scaling for progression.
class MiningRigs {
  // —— Legacy (BTC-only, unchanged for save compatibility) ——
  static const laptop = MiningRig(
    id: 'laptop',
    name: 'Laptop miner',
    btcPerMin: 2.5e-8,
    level: 1,
    assetName: 'laptop',
    costBtc: 0,
    powerConsumption: 0.5,
    heatGeneration: 0.5,
  );
  static const gpuRig = MiningRig(
    id: 'gpu_rig',
    name: 'GPU rig',
    btcPerMin: 1.25e-7,
    level: 2,
    assetName: 'gpu_rig',
    costBtc: 0.00015,
    powerConsumption: 2.0,
    heatGeneration: 1.5,
  );
  static const miningRack = MiningRig(
    id: 'mining_rack',
    name: 'Mining rack',
    btcPerMin: 2.5e-7,
    level: 3,
    assetName: 'mining_rack',
    costBtc: 0.0005,
    powerConsumption: 5.0,
    heatGeneration: 3.0,
  );
  static const warehouseFarm = MiningRig(
    id: 'warehouse_farm',
    name: 'Warehouse farm',
    btcPerMin: 1.25e-6,
    level: 4,
    assetName: 'warehouse',
    costBtc: 0.002,
    powerConsumption: 15.0,
    heatGeneration: 8.0,
  );
  static const megaFacility = MiningRig(
    id: 'mega_facility',
    name: 'Mega mining facility',
    btcPerMin: 6.25e-6,
    level: 5,
    assetName: 'mega',
    costBtc: 0.01,
    powerConsumption: 40.0,
    heatGeneration: 20.0,
  );

  // —— New multi-coin rig types ——
  static const cpuMiner = MiningRig(
    id: 'cpu_miner',
    name: 'CPU Miner',
    btcPerMin: 1.5e-8,
    level: 1,
    assetName: 'laptop',
    costBtc: 0,
    supportedCoins: ['btc', 'eth', 'ltc', 'doge'],
    ratePerCoin: {'btc': 1.5e-8, 'eth': 8e-7, 'ltc': 4e-6, 'doge': 0.002},
    powerConsumption: 0.8,
    heatGeneration: 0.6,
    upgradeLevels: 3,
    costScaling: 1.5,
  );
  static const gamingGpuRig = MiningRig(
    id: 'gaming_gpu_rig',
    name: 'Gaming GPU Rig',
    btcPerMin: 2e-7,
    level: 2,
    assetName: 'gpu_rig',
    costBtc: 0.00025,
    supportedCoins: ['btc', 'eth', 'sol', 'ltc'],
    ratePerCoin: {'btc': 2e-7, 'eth': 1.2e-5, 'sol': 0.0008, 'ltc': 1.2e-5},
    powerConsumption: 3.0,
    heatGeneration: 2.5,
    upgradeLevels: 4,
    costScaling: 1.6,
  );
  static const gpuCluster = MiningRig(
    id: 'gpu_cluster',
    name: 'GPU Mining Cluster',
    btcPerMin: 8e-7,
    level: 3,
    assetName: 'mining_rack',
    costBtc: 0.001,
    supportedCoins: ['btc', 'eth', 'sol', 'ltc', 'doge'],
    ratePerCoin: {'btc': 8e-7, 'eth': 5e-5, 'sol': 0.003, 'ltc': 5e-5, 'doge': 0.08},
    powerConsumption: 12.0,
    heatGeneration: 10.0,
    upgradeLevels: 5,
    costScaling: 1.7,
  );
  static const asicBtcMiner = MiningRig(
    id: 'asic_btc',
    name: 'Solana Validator',
    btcPerMin: 5e-6,
    level: 4,
    assetName: 'warehouse',
    costBtc: 0.005,
    supportedCoins: ['btc'],
    ratePerCoin: {'btc': 5e-6},
    powerConsumption: 25.0,
    heatGeneration: 18.0,
    upgradeLevels: 4,
    costScaling: 1.8,
  );
  static const dataCenterRig = MiningRig(
    id: 'data_center_rig',
    name: 'Advanced Data Center Rig',
    btcPerMin: 2e-5,
    level: 5,
    assetName: 'mega',
    costBtc: 0.02,
    supportedCoins: ['btc', 'eth', 'sol', 'ltc', 'doge'],
    ratePerCoin: {'btc': 2e-5, 'eth': 0.0012, 'sol': 0.06, 'ltc': 0.0003, 'doge': 2.0},
    powerConsumption: 80.0,
    heatGeneration: 50.0,
    upgradeLevels: 5,
    costScaling: 2.0,
  );

  static const List<MiningRig> all = [
    laptop,
    gpuRig,
    miningRack,
    warehouseFarm,
    megaFacility,
    cpuMiner,
    gamingGpuRig,
    gpuCluster,
    asicBtcMiner,
    dataCenterRig,
  ];

  static MiningRig? byId(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Cost for the nth purchase of this rig (exponential scaling). First purchase = costBtc.
  static double costForCount(MiningRig rig, int alreadyOwned) {
    if (alreadyOwned <= 0) return rig.costBtc;
    return rig.costBtc * pow(rig.costScaling, alreadyOwned.clamp(0, 50).toDouble());
  }
}
