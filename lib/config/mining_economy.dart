/// Global tuning for how fast players earn cryptocurrency from rigs.
///
/// All rig base rates ([MiningRig.btcPerMin] and [MiningRig.ratePerCoin]) are
/// multiplied by [outputScale] inside [GameStateService] when computing live
/// mining output. Upgrade costs and IAP prices are unchanged.
///
/// Design target (reference SOL spot ~ USD 200):
///   A **fully loaded** farm — one of every rig, max farm tier (×1.5), Premium
///   (×1.5), and all permanent shop pack multipliers — mining continuously
///   should take about **one month** to reach **~USD 100** of SOL (the
///   withdrawal minimum). Temporary 2× boosts / daily boosts can go a bit
///   above that. Free / starter setups stay much slower.
class MiningEconomy {
  MiningEconomy._();

  /// Convert BTC-era coin amounts (grants, costs, thresholds) to SOL units
  /// so USD value stays similar at ~$200 SOL vs ~$100k BTC.
  static const double unitScale = 500.0;

  /// Multiply every rig's effective base rate (coins/min) before difficulty
  /// and multipliers. Calibrated so maxed setup ≈ $100 / 30 days at $200 SOL.
  static const double outputScale = 0.00011 * unitScale;

  static double toSol(double legacyBtcAmount) => legacyBtcAmount * unitScale;
}
