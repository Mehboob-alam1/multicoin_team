class MiningRig {
  final String id;
  final String name;
  final double btcPerMin;
  final int level;
  final String assetName; // es. 'laptop', 'gpu_rig', ...
  final double costBtc;

  const MiningRig({
    required this.id,
    required this.name,
    required this.btcPerMin,
    required this.level,
    required this.assetName,
    required this.costBtc,
  });
}

/// Mining rates calibrated so ~1 month of play ≈ $100 worth of BTC at current price.
/// 30 days = 43,200 min; target 0.00103 BTC/month ≈ $100 @ ~$97k.
class MiningRigs {
  static const laptop = MiningRig(
    id: 'laptop',
    name: 'Laptop miner',
    btcPerMin: 2.5e-8, // ~$97 in 30 days if only this
    level: 1,
    assetName: 'laptop',
    costBtc: 0,
  );
  static const gpuRig = MiningRig(
    id: 'gpu_rig',
    name: 'GPU rig',
    btcPerMin: 1.25e-7,
    level: 2,
    assetName: 'gpu_rig',
    costBtc: 0.00015,
  );
  static const miningRack = MiningRig(
    id: 'mining_rack',
    name: 'Mining rack',
    btcPerMin: 2.5e-7,
    level: 3,
    assetName: 'mining_rack',
    costBtc: 0.0005,
  );
  static const warehouseFarm = MiningRig(
    id: 'warehouse_farm',
    name: 'Warehouse farm',
    btcPerMin: 1.25e-6,
    level: 4,
    assetName: 'warehouse',
    costBtc: 0.002,
  );
  static const megaFacility = MiningRig(
    id: 'mega_facility',
    name: 'Mega mining facility',
    btcPerMin: 6.25e-6,
    level: 5,
    assetName: 'mega',
    costBtc: 0.01,
  );

  static const List<MiningRig> all = [
    laptop,
    gpuRig,
    miningRack,
    warehouseFarm,
    megaFacility,
  ];

  static MiningRig? byId(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
