class PlayerData {
  static const Object _unset = Object();

  /// Legacy single-currency balance (BTC). Kept for backward compatibility; also mirrored in [coinBalances]['btc'].
  final double btcBalance;
  /// Per-coin balances. Key = coin id (e.g. 'btc', 'eth'). Primary currency is 'btc'.
  final Map<String, double> coinBalances;
  final List<String> ownedRigIds;
  final int lastDailyRewardDay;
  final int dailyStreakCount;
  final int farmLevel;
  final DateTime? miningSessionEndsAt;
  final double lifetimeMinedBtc;
  /// Total mined per coin (key = coin id).
  final Map<String, double> lifetimeMinedByCoin;
  final int totalSessionsStarted;
  final List<String> claimedMilestones;
  final DateTime? lastClosedAt;

  const PlayerData({
    this.btcBalance = 0,
    this.coinBalances = const {},
    this.ownedRigIds = const ['laptop'],
    this.lastDailyRewardDay = 0,
    this.dailyStreakCount = 0,
    this.farmLevel = 1,
    this.miningSessionEndsAt,
    this.lifetimeMinedBtc = 0,
    this.lifetimeMinedByCoin = const {},
    this.totalSessionsStarted = 0,
    this.claimedMilestones = const [],
    this.lastClosedAt,
  });

  PlayerData copyWith({
    double? btcBalance,
    Map<String, double>? coinBalances,
    List<String>? ownedRigIds,
    int? lastDailyRewardDay,
    int? dailyStreakCount,
    int? farmLevel,
    Object? miningSessionEndsAt = _unset,
    double? lifetimeMinedBtc,
    Map<String, double>? lifetimeMinedByCoin,
    int? totalSessionsStarted,
    List<String>? claimedMilestones,
    Object? lastClosedAt = _unset,
  }) {
    return PlayerData(
      btcBalance: btcBalance ?? this.btcBalance,
      coinBalances: coinBalances ?? this.coinBalances,
      ownedRigIds: ownedRigIds ?? this.ownedRigIds,
      lastDailyRewardDay: lastDailyRewardDay ?? this.lastDailyRewardDay,
      dailyStreakCount: dailyStreakCount ?? this.dailyStreakCount,
      farmLevel: farmLevel ?? this.farmLevel,
      miningSessionEndsAt: identical(miningSessionEndsAt, _unset)
          ? this.miningSessionEndsAt
          : miningSessionEndsAt as DateTime?,
      lifetimeMinedBtc: lifetimeMinedBtc ?? this.lifetimeMinedBtc,
      lifetimeMinedByCoin: lifetimeMinedByCoin ?? this.lifetimeMinedByCoin,
      totalSessionsStarted: totalSessionsStarted ?? this.totalSessionsStarted,
      claimedMilestones: claimedMilestones ?? this.claimedMilestones,
      lastClosedAt: identical(lastClosedAt, _unset)
          ? this.lastClosedAt
          : lastClosedAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
        'btcBalance': btcBalance,
        'coinBalances': coinBalances.map((k, v) => MapEntry(k, v)),
        'ownedRigIds': ownedRigIds,
        'lastDailyRewardDay': lastDailyRewardDay,
        'dailyStreakCount': dailyStreakCount,
        'farmLevel': farmLevel,
        'miningSessionEndsAt': miningSessionEndsAt?.toIso8601String(),
        'lifetimeMinedBtc': lifetimeMinedBtc,
        'lifetimeMinedByCoin': lifetimeMinedByCoin.map((k, v) => MapEntry(k, v)),
        'totalSessionsStarted': totalSessionsStarted,
        'claimedMilestones': claimedMilestones,
        'lastClosedAt': lastClosedAt?.toIso8601String(),
      };

  static PlayerData fromJson(Map<String, dynamic> json) {
    final list = json['ownedRigIds'];
    final btcBal = (json['btcBalance'] as num?)?.toDouble() ?? 0;
    final lifeBtc = (json['lifetimeMinedBtc'] as num?)?.toDouble() ?? 0;
    Map<String, double> coins = {};
    if (json['coinBalances'] is Map) {
      for (final e in (json['coinBalances'] as Map).entries) {
        coins[e.key.toString()] = (e.value as num).toDouble();
      }
    }
    if (coins.isEmpty && btcBal > 0) coins['btc'] = btcBal;
    Map<String, double> lifeByCoin = {};
    if (json['lifetimeMinedByCoin'] is Map) {
      for (final e in (json['lifetimeMinedByCoin'] as Map).entries) {
        lifeByCoin[e.key.toString()] = (e.value as num).toDouble();
      }
    }
    if (lifeByCoin.isEmpty && lifeBtc > 0) lifeByCoin['btc'] = lifeBtc;
    return PlayerData(
      btcBalance: btcBal,
      coinBalances: coins,
      ownedRigIds: list is List ? list.map((e) => e.toString()).toList() : ['laptop'],
      lastDailyRewardDay: json['lastDailyRewardDay'] as int? ?? 0,
      dailyStreakCount: json['dailyStreakCount'] as int? ?? 0,
      farmLevel: json['farmLevel'] as int? ?? 1,
      miningSessionEndsAt: json['miningSessionEndsAt'] != null
          ? DateTime.tryParse(json['miningSessionEndsAt'] as String)
          : null,
      lifetimeMinedBtc: lifeBtc,
      lifetimeMinedByCoin: lifeByCoin,
      totalSessionsStarted: json['totalSessionsStarted'] as int? ?? 0,
      claimedMilestones: (json['claimedMilestones'] is List)
          ? (json['claimedMilestones'] as List).map((e) => e.toString()).toList()
          : const [],
      lastClosedAt: json['lastClosedAt'] != null
          ? DateTime.tryParse(json['lastClosedAt'] as String)
          : null,
    );
  }
}
