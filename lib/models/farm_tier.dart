class FarmTier {
  final int level;
  final String name;
  final int rigCapacity;
  final double upgradeCostBtc;
  final double miningMultiplier;

  const FarmTier({
    required this.level,
    required this.name,
    required this.rigCapacity,
    required this.upgradeCostBtc,
    required this.miningMultiplier,
  });
}

class FarmTiers {
  static const tier1 = FarmTier(
    level: 1,
    name: 'Garage Farm',
    rigCapacity: 4,
    upgradeCostBtc: 0,
    miningMultiplier: 1.0,
  );
  static const tier2 = FarmTier(
    level: 2,
    name: 'Warehouse Farm',
    rigCapacity: 12,
    upgradeCostBtc: 0.0003,
    miningMultiplier: 1.1,
  );
  static const tier3 = FarmTier(
    level: 3,
    name: 'Industrial Farm',
    rigCapacity: 30,
    upgradeCostBtc: 0.0012,
    miningMultiplier: 1.25,
  );
  static const tier4 = FarmTier(
    level: 4,
    name: 'Mega Facility',
    rigCapacity: 80,
    upgradeCostBtc: 0.006,
    miningMultiplier: 1.5,
  );

  static const all = [tier1, tier2, tier3, tier4];

  static FarmTier byLevel(int level) {
    return all.firstWhere(
      (e) => e.level == level,
      orElse: () => tier1,
    );
  }

  static FarmTier? nextLevel(int level) {
    final idx = all.indexWhere((e) => e.level == level);
    if (idx < 0 || idx + 1 >= all.length) return null;
    return all[idx + 1];
  }
}

