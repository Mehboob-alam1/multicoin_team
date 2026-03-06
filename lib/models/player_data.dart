class PlayerData {
  static const Object _unset = Object();

  final double btcBalance;
  final List<String> ownedRigIds; // id dei rig posseduti (con quantità = ripetizioni)
  final int lastDailyRewardDay; // giorno calendario (epoch days) ultimo claim; 0 = mai
  final int dailyStreakCount; // 1-7, dove siamo nel ciclo daily
  final int farmLevel; // 1..N farm tiers
  final DateTime? miningSessionEndsAt; // active mining session end
  final double lifetimeMinedBtc; // total mined across time
  final int totalSessionsStarted;
  final List<String> claimedMilestones;
  final DateTime? lastClosedAt; // per calcolo idle

  const PlayerData({
    this.btcBalance = 0,
    this.ownedRigIds = const ['laptop'],
    this.lastDailyRewardDay = 0,
    this.dailyStreakCount = 0,
    this.farmLevel = 1,
    this.miningSessionEndsAt,
    this.lifetimeMinedBtc = 0,
    this.totalSessionsStarted = 0,
    this.claimedMilestones = const [],
    this.lastClosedAt,
  });

  PlayerData copyWith({
    double? btcBalance,
    List<String>? ownedRigIds,
    int? lastDailyRewardDay,
    int? dailyStreakCount,
    int? farmLevel,
    Object? miningSessionEndsAt = _unset,
    double? lifetimeMinedBtc,
    int? totalSessionsStarted,
    List<String>? claimedMilestones,
    Object? lastClosedAt = _unset,
  }) {
    return PlayerData(
      btcBalance: btcBalance ?? this.btcBalance,
      ownedRigIds: ownedRigIds ?? this.ownedRigIds,
      lastDailyRewardDay: lastDailyRewardDay ?? this.lastDailyRewardDay,
      dailyStreakCount: dailyStreakCount ?? this.dailyStreakCount,
      farmLevel: farmLevel ?? this.farmLevel,
      miningSessionEndsAt: identical(miningSessionEndsAt, _unset)
          ? this.miningSessionEndsAt
          : miningSessionEndsAt as DateTime?,
      lifetimeMinedBtc: lifetimeMinedBtc ?? this.lifetimeMinedBtc,
      totalSessionsStarted: totalSessionsStarted ?? this.totalSessionsStarted,
      claimedMilestones: claimedMilestones ?? this.claimedMilestones,
      lastClosedAt: identical(lastClosedAt, _unset)
          ? this.lastClosedAt
          : lastClosedAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
        'btcBalance': btcBalance,
        'ownedRigIds': ownedRigIds,
        'lastDailyRewardDay': lastDailyRewardDay,
        'dailyStreakCount': dailyStreakCount,
        'farmLevel': farmLevel,
        'miningSessionEndsAt': miningSessionEndsAt?.toIso8601String(),
        'lifetimeMinedBtc': lifetimeMinedBtc,
        'totalSessionsStarted': totalSessionsStarted,
        'claimedMilestones': claimedMilestones,
        'lastClosedAt': lastClosedAt?.toIso8601String(),
      };

  static PlayerData fromJson(Map<String, dynamic> json) {
    final list = json['ownedRigIds'];
    return PlayerData(
      btcBalance: (json['btcBalance'] as num?)?.toDouble() ?? 0,
      ownedRigIds: list is List ? list.map((e) => e.toString()).toList() : ['laptop'],
      lastDailyRewardDay: json['lastDailyRewardDay'] as int? ?? 0,
      dailyStreakCount: json['dailyStreakCount'] as int? ?? 0,
      farmLevel: json['farmLevel'] as int? ?? 1,
      miningSessionEndsAt: json['miningSessionEndsAt'] != null
          ? DateTime.tryParse(json['miningSessionEndsAt'] as String)
          : null,
      lifetimeMinedBtc: (json['lifetimeMinedBtc'] as num?)?.toDouble() ?? 0,
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
