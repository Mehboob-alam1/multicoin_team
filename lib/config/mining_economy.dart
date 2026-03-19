/// Global tuning for how fast players earn cryptocurrency from rigs.
///
/// All rig base rates ([MiningRig.btcPerMin] and [MiningRig.ratePerCoin]) are
/// multiplied by [outputScale] inside [GameStateService] when computing live
/// mining output. Upgrade costs and IAP prices are unchanged.
///
/// Design target (approximate):
///   - "Free" baseline = default **one laptop** rig, farm tier 1, no premium,
///     no one-time pack multipliers, mining session off, no 2× boost, heat in
///     the safe zone (efficiency 1.0), prestige/event/daily at 1.0.
///   - At a **reference BTC spot ~ USD 100k**, continuous mining should need
///     on the order of **~2–3 months** to reach **~USD 100** worth of BTC from
///     that baseline alone (slower, less "idle game inflation").
///
/// Live USD time varies with real BTC price (CoinGecko) and with sessions,
/// premium, packs, farm upgrades, more rigs, heat, events, etc.
class MiningEconomy {
  MiningEconomy._();

  /// Multiply every rig's effective base rate (coins/min) before difficulty
  /// and multipliers. Lower = slower free progression, more "real" grind.
  static const double outputScale = 0.33;
}
