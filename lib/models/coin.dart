/// Represents a mineable cryptocurrency in the game.
/// Designed to be data-driven so new coins can be added with minimal code.
class Coin {
  final String id;
  final String name;
  final String symbol;
  /// Relative mining difficulty (higher = slower base rate). Used in rate formulas.
  final double difficulty;
  /// Base mining rate (coins per min) at difficulty 1.0. Actual rate = baseMiningRate / difficulty * multipliers.
  final double baseMiningRate;
  /// USD price for display and value calculations.
  final double marketPrice;
  /// 0.0–1.0; affects variance in displayed value over time (future use).
  final double volatilityFactor;

  const Coin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.difficulty,
    required this.baseMiningRate,
    required this.marketPrice,
    this.volatilityFactor = 0.1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'symbol': symbol,
        'difficulty': difficulty,
        'baseMiningRate': baseMiningRate,
        'marketPrice': marketPrice,
        'volatilityFactor': volatilityFactor,
      };

  static Coin fromJson(Map<String, dynamic> m) => Coin(
        id: m['id'] as String,
        name: m['name'] as String,
        symbol: m['symbol'] as String,
        difficulty: (m['difficulty'] as num).toDouble(),
        baseMiningRate: (m['baseMiningRate'] as num).toDouble(),
        marketPrice: (m['marketPrice'] as num).toDouble(),
        volatilityFactor: (m['volatilityFactor'] as num?)?.toDouble() ?? 0.1,
      );
}

/// Registry of all supported coins. Add new entries here for scalability.
class Coins {
  static const btc = Coin(
    id: 'btc',
    name: 'Bitcoin',
    symbol: 'BTC',
    difficulty: 1.0,
    baseMiningRate: 2.5e-8,
    marketPrice: 97000,
    volatilityFactor: 0.08,
  );
  static const eth = Coin(
    id: 'eth',
    name: 'Ethereum',
    symbol: 'ETH',
    difficulty: 0.6,
    baseMiningRate: 1.2e-6,
    marketPrice: 3500,
    volatilityFactor: 0.12,
  );
  static const sol = Coin(
    id: 'sol',
    name: 'Solana',
    symbol: 'SOL',
    difficulty: 0.4,
    baseMiningRate: 0.002,
    marketPrice: 220,
    volatilityFactor: 0.15,
  );
  static const ltc = Coin(
    id: 'ltc',
    name: 'Litecoin',
    symbol: 'LTC',
    difficulty: 0.35,
    baseMiningRate: 8e-6,
    marketPrice: 95,
    volatilityFactor: 0.1,
  );
  static const doge = Coin(
    id: 'doge',
    name: 'Dogecoin',
    symbol: 'DOGE',
    difficulty: 0.2,
    baseMiningRate: 0.05,
    marketPrice: 0.38,
    volatilityFactor: 0.2,
  );

  static const List<Coin> all = [btc, eth, sol, ltc, doge];

  static Coin? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Primary currency used for rig purchases and legacy balance display.
  static const String primaryId = 'btc';
}
