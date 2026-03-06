class MiningEngine {
  static double effectiveRate({
    required double baseRatePerMin,
    required double farmMultiplier,
    required double sessionMultiplier,
    required double premiumMultiplier,
    required double boostMultiplier,
    required double eventMultiplier,
    required double efficiencyMultiplier,
  }) {
    return baseRatePerMin *
        farmMultiplier *
        sessionMultiplier *
        premiumMultiplier *
        boostMultiplier *
        eventMultiplier *
        efficiencyMultiplier;
  }
}

