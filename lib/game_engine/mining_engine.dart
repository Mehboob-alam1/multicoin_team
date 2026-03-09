/// Central mining math: hash rate × efficiency × boosts × premium × event.
/// Supports per-coin rates and difficulty. Use for both single-coin (legacy) and multi-coin.
class MiningEngine {
  /// Effective rate (coins per min) from base rate and all multipliers.
  static double effectiveRate({
    required double baseRatePerMin,
    required double farmMultiplier,
    required double sessionMultiplier,
    required double premiumMultiplier,
    required double boostMultiplier,
    required double eventMultiplier,
    required double efficiencyMultiplier,
    double difficultyMultiplier = 1.0,
    double prestigeSpeedMultiplier = 1.0,
  }) {
    return baseRatePerMin *
        (1.0 / difficultyMultiplier.clamp(0.1, 10.0)) *
        farmMultiplier *
        sessionMultiplier *
        premiumMultiplier *
        boostMultiplier *
        eventMultiplier *
        efficiencyMultiplier *
        prestigeSpeedMultiplier;
  }

  /// Per-coin effective rate. [baseRateForCoin] is the rig's rate for that coin (before difficulty).
  static double effectiveRateForCoin({
    required double baseRateForCoin,
    required double difficulty,
    required double farmMultiplier,
    required double sessionMultiplier,
    required double premiumMultiplier,
    required double boostMultiplier,
    required double eventMultiplier,
    required double efficiencyMultiplier,
    double prestigeSpeedMultiplier = 1.0,
    double difficultyOverTime = 1.0,
  }) {
    final difficultyMult = (difficulty * difficultyOverTime).clamp(0.1, 10.0);
    return baseRateForCoin *
        (1.0 / difficultyMult) *
        farmMultiplier *
        sessionMultiplier *
        premiumMultiplier *
        boostMultiplier *
        eventMultiplier *
        efficiencyMultiplier *
        prestigeSpeedMultiplier;
  }
}

