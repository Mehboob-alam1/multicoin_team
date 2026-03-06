class MiningLocation {
  final String id;
  final String name;
  final double unlockBtc;
  final double unlockHashRate;
  final int farmCapacityBonus;

  const MiningLocation({
    required this.id,
    required this.name,
    required this.unlockBtc,
    required this.unlockHashRate,
    required this.farmCapacityBonus,
  });
}

class MiningLocations {
  static const all = [
    MiningLocation(
      id: 'garage',
      name: 'Garage',
      unlockBtc: 0,
      unlockHashRate: 0,
      farmCapacityBonus: 0,
    ),
    MiningLocation(
      id: 'warehouse',
      name: 'Warehouse',
      unlockBtc: 0.0002,
      unlockHashRate: 0.0000002,
      farmCapacityBonus: 3,
    ),
    MiningLocation(
      id: 'factory',
      name: 'Factory',
      unlockBtc: 0.0008,
      unlockHashRate: 0.0000008,
      farmCapacityBonus: 8,
    ),
    MiningLocation(
      id: 'industrial_plant',
      name: 'Industrial Mining Plant',
      unlockBtc: 0.003,
      unlockHashRate: 0.000003,
      farmCapacityBonus: 18,
    ),
    MiningLocation(
      id: 'city_farm',
      name: 'City Mining Farm',
      unlockBtc: 0.01,
      unlockHashRate: 0.00001,
      farmCapacityBonus: 40,
    ),
  ];
}

