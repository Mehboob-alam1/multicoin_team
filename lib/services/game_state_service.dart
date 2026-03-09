import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin.dart';
import '../models/farm_tier.dart';
import '../models/mining_rig.dart';
import '../models/player_data.dart';
import '../game_engine/mining_engine.dart';
import 'background_mining_task.dart';
import 'firebase_sync_service.dart';

class GameStateService extends ChangeNotifier {
  GameStateService(this._firebaseSync);

  final FirebaseSyncService _firebaseSync;
  static const _key = 'btc_sim_player_data';
  static const _foregroundSnapshotKey = 'btc_sim_foreground_snapshot';
  static const _maxIdleMinutes = 8 * 60;
  static const _sessionMinutes = 30;
  static const _minRemoteSyncInterval = Duration(minutes: 12);

  PlayerData _data = const PlayerData();
  DateTime? _lastTick;
  String? _userId;
  String _displayName = 'Miner';
  bool _syncInProgress = false;
  bool _loaded = false;
  String? _lastSyncError;
  List<String> _purchasedOneTimeIds = [];
  DateTime? _premiumExpiry;
  DateTime? _boostExpiry;
  DateTime? _lastRemoteSyncAt;
  bool _remoteDirty = false;
  bool _fetchedRemoteThisSession = false;
  double _eventMiningMultiplier = 1.0;
  double _dailyBoostMultiplier = 1.0;
  double _efficiencyMultiplier = 1.0;
  double _prestigeMultiplier = 1.0;
  int _locationCapacityBonus = 0;
  double _rigDiscount = 0.0;

  bool get isLoaded => _loaded;
  PlayerData get data => _data;
  /// Primary currency balance (BTC). From [coinBalances] or legacy [btcBalance].
  double get btcBalance => _data.coinBalances[Coins.primaryId] ?? _data.btcBalance;
  List<String> get ownedRigIds => List.unmodifiable(_data.ownedRigIds);
  /// Balance for any coin (e.g. 'btc', 'eth').
  double balance(String coinId) => _data.coinBalances[coinId] ?? 0;
  /// Lifetime mined for any coin.
  double lifetimeMined(String coinId) => _data.lifetimeMinedByCoin[coinId] ?? 0;
  /// Total mining rate (coins per min) for a specific coin.
  double totalRatePerCoin(String coinId) => _totalRatePerCoinWithSession(coinId, isSessionActive);
  bool get syncInProgress => _syncInProgress;
  String? get lastSyncError => _lastSyncError;
  List<String> get purchasedOneTimeIds => List.unmodifiable(_purchasedOneTimeIds);
  bool get isPremiumActive => _premiumExpiry != null && _premiumExpiry!.isAfter(DateTime.now());
  DateTime? get premiumExpiry => _premiumExpiry;
  bool get isBoostActive => _boostExpiry != null && _boostExpiry!.isAfter(DateTime.now());
  bool get isSessionActive =>
      _data.miningSessionEndsAt != null && _data.miningSessionEndsAt!.isAfter(DateTime.now());
  Duration get sessionTimeLeft =>
      isSessionActive ? _data.miningSessionEndsAt!.difference(DateTime.now()) : Duration.zero;
  double get lifetimeMinedBtc => _data.lifetimeMinedByCoin[Coins.primaryId] ?? _data.lifetimeMinedBtc;
  int get totalSessionsStarted => _data.totalSessionsStarted;
  List<String> get claimedMilestones => List.unmodifiable(_data.claimedMilestones);

  FarmTier get currentFarmTier => FarmTiers.byLevel(_data.farmLevel);
  FarmTier? get nextFarmTier => FarmTiers.nextLevel(_data.farmLevel);
  int get rigCapacity => currentFarmTier.rigCapacity + _locationCapacityBonus;
  bool get canBuyMoreRigs => _data.ownedRigIds.length < rigCapacity;

  double get totalBtcPerMin {
    return _totalBtcPerMinWithSession(isSessionActive);
  }

  /// Rate in BTC/min (primary currency). When [sessionActive] true, applies 1.25× session bonus.
  double _totalBtcPerMinWithSession(bool sessionActive) {
    return _totalRatePerCoinWithSession(Coins.primaryId, sessionActive);
  }

  /// Per-coin rate (coins/min). Uses MiningEngine with difficulty and all multipliers.
  double _totalRatePerCoinWithSession(String coinId, bool sessionActive) {
    final coin = Coins.byId(coinId);
    if (coin == null) return 0;
    double sum = 0;
    for (final id in _data.ownedRigIds) {
      final rig = MiningRigs.byId(id);
      if (rig == null || !rig.supportsCoin(coinId)) continue;
      final baseRate = rig.rateForCoin(coinId);
      if (baseRate <= 0) continue;
      sum += MiningEngine.effectiveRateForCoin(
        baseRateForCoin: baseRate,
        difficulty: coin.difficulty,
        farmMultiplier: currentFarmTier.miningMultiplier,
        sessionMultiplier: sessionActive ? 1.25 : 1.0,
        premiumMultiplier: isPremiumActive ? 1.5 : 1.0,
        boostMultiplier: isBoostActive ? 2.0 : 1.0,
        eventMultiplier: _eventMiningMultiplier,
        efficiencyMultiplier: _efficiencyMultiplier,
        prestigeSpeedMultiplier: _prestigeMultiplier,
      );
    }
    return sum * _oneTimeMiningMultiplier() * _dailyBoostMultiplier;
  }

  void applyExternalGameplayModifiers({
    required double eventMiningMultiplier,
    required double dailyBoostMultiplier,
    required double efficiencyMultiplier,
    required int locationCapacityBonus,
    double rigDiscount = 0.0,
    double prestigeMultiplier = 1.0,
  }) {
    final changed = _eventMiningMultiplier != eventMiningMultiplier ||
        _dailyBoostMultiplier != dailyBoostMultiplier ||
        _efficiencyMultiplier != efficiencyMultiplier ||
        _locationCapacityBonus != locationCapacityBonus ||
        _rigDiscount != rigDiscount ||
        _prestigeMultiplier != prestigeMultiplier;
    _eventMiningMultiplier = eventMiningMultiplier;
    _dailyBoostMultiplier = dailyBoostMultiplier;
    _efficiencyMultiplier = efficiencyMultiplier;
    _locationCapacityBonus = locationCapacityBonus;
    _rigDiscount = rigDiscount;
    _prestigeMultiplier = prestigeMultiplier;
    if (changed) notifyListeners();
  }

  double _oneTimeMiningMultiplier() {
    double m = 1.0;
    if (_purchasedOneTimeIds.contains('starter_pack')) m *= 1.05;
    if (_purchasedOneTimeIds.contains('satoshi_pack')) m *= 1.03;
    if (_purchasedOneTimeIds.contains('mega_pack')) m *= 1.15;
    return m;
  }

  int get currentDayForDaily {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
  }

  bool get canClaimDaily => _data.lastDailyRewardDay < currentDayForDaily;

  int get nextDailyStreakDay {
    if (_data.lastDailyRewardDay == 0) return 1;
    final today = currentDayForDaily;
    final last = _data.lastDailyRewardDay;
    if (today == last) return 0;
    if (today == last + 1) return (_data.dailyStreakCount % 7) + 1;
    return 1;
  }

  void setUserId(String? id) {
    if (_userId != id) _fetchedRemoteThisSession = false;
    _userId = id;
  }
  void setDisplayName(String? name) {
    if (name != null && name.isNotEmpty) _displayName = name;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userId != null ? '${_key}_$_userId' : _key;

    // Start from default so each user is isolated; never carry over another user's data.
    _data = const PlayerData();

    // Load local data for this user (key is per-user). Skip for null userId so guest always starts from 0.
    bool hadLocalData = false;
    if (_userId != null) {
      final raw = prefs.getString(key);
      if (raw != null) {
        hadLocalData = true;
        try {
          _data = PlayerData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        } catch (_) {}
      }
    }

    // For logged-in user: fetch remote only once per app session to reduce Firebase usage.
    // If no local data (e.g. fresh install), do NOT use remote so user always starts from 0.
    if (_userId != null && !_fetchedRemoteThisSession) {
      _fetchedRemoteThisSession = true;
      final remote = await _firebaseSync.fetchPlayerData(_userId!);
      if (remote != null && hadLocalData) {
        final localData = _data;
        _data = remote;
        // Never lose mining balance: take max of local vs remote per coin.
        final mergedCoins = Map<String, double>.from(_data.coinBalances);
        for (final e in localData.coinBalances.entries) {
          final cur = mergedCoins[e.key] ?? 0;
          if (e.value > cur) mergedCoins[e.key] = e.value;
        }
        final mergedLife = Map<String, double>.from(_data.lifetimeMinedByCoin);
        for (final e in localData.lifetimeMinedByCoin.entries) {
          final cur = mergedLife[e.key] ?? 0;
          if (e.value > cur) mergedLife[e.key] = e.value;
        }
        final btcBal = mergedCoins[Coins.primaryId] ?? _data.btcBalance;
        final lifeBtc = mergedLife[Coins.primaryId] ?? _data.lifetimeMinedBtc;
        _data = _data.copyWith(
          coinBalances: mergedCoins,
          lifetimeMinedByCoin: mergedLife,
          btcBalance: btcBal,
          lifetimeMinedBtc: lifeBtc,
        );
      }
      final oneTime = await _firebaseSync.getOneTimePurchases(_userId!);
      _purchasedOneTimeIds = oneTime;
      _premiumExpiry = await _firebaseSync.getSubscriptionExpiry(_userId!);
      _boostExpiry = await _loadBoostExpiry();
    }

    _lastTick = DateTime.now();
    if (_data.miningSessionEndsAt != null &&
        _data.miningSessionEndsAt!.isBefore(DateTime.now())) {
      _data = _data.copyWith(miningSessionEndsAt: null);
    }
    _applyIdleEarnings();
    if (_userId != null) await _applyIdleFromForegroundSnapshotIfNeeded(prefs, key);
    await _persist(forceRemote: false, markDirty: false);
    _loaded = true;
    notifyListeners();
  }

  /// If app was killed without lifecycle (e.g. force-close), we may have a
  /// foreground snapshot but no lastClosedAt in player data. Apply idle from it.
  Future<void> _applyIdleFromForegroundSnapshotIfNeeded(SharedPreferences prefs, String dataKey) async {
    if (_data.lastClosedAt != null) return;
    final raw = prefs.getString(_foregroundSnapshotKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if ((map['dataKey'] as String?) != dataKey) return;
      final closedStr = map['lastClosedAt'] as String?;
      final closed = closedStr != null ? DateTime.tryParse(closedStr) : null;
      if (closed == null) return;
      final rateWith = (map['rateWithSession'] as num?)?.toDouble();
      final rateWithout = (map['rateWithoutSession'] as num?)?.toDouble();
      if (rateWith == null || rateWithout == null) return;
      final sessionEndsAtStr = map['sessionEndsAt'] as String?;
      final sessionEndsAt = sessionEndsAtStr != null ? DateTime.tryParse(sessionEndsAtStr) : null;
      final now = DateTime.now();
      final minutesAway = now.difference(closed).inMinutes.clamp(0, _maxIdleMinutes);
      if (minutesAway <= 0) {
        await prefs.remove(_foregroundSnapshotKey);
        return;
      }
      double earned;
      if (sessionEndsAt != null && sessionEndsAt.isAfter(closed)) {
        final minSession = minutesAway.clamp(0, sessionEndsAt.difference(closed).inMinutes);
        final minNormal = minutesAway - minSession;
        earned = rateWith * minSession + rateWithout * minNormal;
      } else {
        earned = rateWithout * minutesAway;
      }
      if (earned > 0) {
        _data = _addMinedToCoin(_data, Coins.primaryId, earned);
      }
      await prefs.remove(_foregroundSnapshotKey);
    } catch (_) {}
  }

  Future<DateTime?> _loadBoostExpiry() async {
    if (_userId == null) return null;
    return _firebaseSync.getBoostExpiry(_userId!);
  }

  void _applyIdleEarnings() {
    final closed = _data.lastClosedAt;
    if (closed == null) return;
    final now = DateTime.now();
    final diff = now.difference(closed);
    final minutes = diff.inMinutes.clamp(0, _maxIdleMinutes);
    final baseRate = totalBtcPerMin;
    final earned = baseRate * minutes;
    if (earned > 0) {
      _data = _addMinedToCoin(_data, Coins.primaryId, earned);
      _data = _data.copyWith(lastClosedAt: null);
    }
  }

  double? getIdleEarnedIfAny() {
    final closed = _data.lastClosedAt;
    if (closed == null) return null;
    final now = DateTime.now();
    final diff = now.difference(closed);
    final minutes = diff.inMinutes.clamp(0, _maxIdleMinutes);
    return totalBtcPerMin * minutes;
  }

  /// Call when app resumes from background. Applies mining earnings for time away (capped at _maxIdleMinutes).
  /// Session does not end when app is closed: earnings use 1.25× for the portion of absence while session was still active.
  Future<void> applyIdleEarningsOnResume() async {
    final closed = _data.lastClosedAt;
    if (closed == null) return;
    final now = DateTime.now();
    final minutesAway = now.difference(closed).inMinutes.clamp(0, _maxIdleMinutes);
    final sessionEndsAt = _data.miningSessionEndsAt;

    double earned = 0;
    if (sessionEndsAt != null && sessionEndsAt.isAfter(closed)) {
      final minutesSessionActive = minutesAway.clamp(0, sessionEndsAt.difference(closed).inMinutes);
      final minutesNormal = minutesAway - minutesSessionActive;
      final rateWithSession = _totalBtcPerMinWithSession(true);
      final rateWithoutSession = _totalBtcPerMinWithSession(false);
      earned = rateWithSession * minutesSessionActive + rateWithoutSession * minutesNormal;
    } else {
      earned = _totalBtcPerMinWithSession(false) * minutesAway;
    }

    if (earned > 0) {
      _data = _addMinedToCoin(_data, Coins.primaryId, earned);
      _data = _data.copyWith(lastClosedAt: null);
      await _persist(forceRemote: false, markDirty: true);
      notifyListeners();
    } else {
      _data = _data.copyWith(lastClosedAt: null);
      await _persist(forceRemote: false, markDirty: false);
      notifyListeners();
    }
  }

  /// Writes current state (including balance) to local storage only. Use to avoid losing progress if app is killed.
  Future<void> persistLocalOnly() async {
    await _persistLocalOnlyImpl();
  }

  /// Writes only to SharedPreferences (no Firebase). Use when app goes to
  /// background so the save completes before the process may be killed.
  Future<void> _persistLocalOnlyImpl() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userId != null ? '${_key}_$_userId' : _key;
    await prefs.setString(key, jsonEncode(_data.toJson()));
  }

  Future<void> _persist({bool forceRemote = false, bool markDirty = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userId != null ? '${_key}_$_userId' : _key;
    await prefs.setString(key, jsonEncode(_data.toJson())); // always write local first

    if (_userId != null) {
      if (markDirty) _remoteDirty = true;
      if (!forceRemote && !_remoteDirty) return;
      final now = DateTime.now();
      final shouldSync = forceRemote ||
          _lastRemoteSyncAt == null ||
          now.difference(_lastRemoteSyncAt!) >= _minRemoteSyncInterval;
      if (!shouldSync) return;

      _syncInProgress = true;
      _lastSyncError = null;
      notifyListeners();
      try {
        await _firebaseSync.syncPlayerData(_userId!, _data, displayName: _displayName);
        await _firebaseSync.updateLeaderboard(
          _userId!,
          displayName: _displayName,
          btcBalance: btcBalance,
          totalBtcPerMin: totalBtcPerMin,
        );
        _lastRemoteSyncAt = now;
        _remoteDirty = false;
      } catch (e) {
        _lastSyncError = e.toString();
      }
      _syncInProgress = false;
      notifyListeners();
    }
  }

  /// Call when app goes to background. Saves lastClosedAt so mining continues
  /// when you reopen (idle earnings applied on resume). Does only fast local
  /// writes first so the process can finish before the OS kills it; Firebase
  /// sync runs in the background.
  Future<void> saveAndClose() async {
    final closedAt = DateTime.now();
    _data = _data.copyWith(lastClosedAt: closedAt);
    final key = _userId != null ? '${_key}_$_userId' : _key;
    // 1) Local-only save so lastClosedAt is on disk immediately (no Firebase wait).
    await _persistLocalOnlyImpl();
    // 2) Idle rates for background task (optional).
    try {
      await persistIdleRatesForBackground(
        dataKey: key,
        lastClosedAt: closedAt,
        rateWithSession: _totalBtcPerMinWithSession(true),
        rateWithoutSession: _totalBtcPerMinWithSession(false),
        sessionEndsAt: _data.miningSessionEndsAt,
      );
    } catch (_) {}
    // 3) Firebase sync in background; don't block so lifecycle callback returns fast.
    if (_userId != null) {
      _remoteDirty = true;
      _persist(forceRemote: true).catchError((_) {});
    }
  }

  /// Sync current state to local storage and Firebase so balance is never lost.
  /// Call periodically (e.g. every few minutes) to keep cloud in sync.
  Future<void> syncToCloud() async {
    await _persist(forceRemote: true, markDirty: true);
  }

  /// Saves a snapshot of "last seen in foreground" so if the app is killed
  /// without lifecycle (e.g. force-close), we can still apply idle on next open.
  Future<void> saveForegroundSnapshot() async {
    final key = _userId != null ? '${_key}_$_userId' : _key;
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{
      'dataKey': key,
      'lastClosedAt': DateTime.now().toIso8601String(),
      'rateWithSession': _totalBtcPerMinWithSession(true),
      'rateWithoutSession': _totalBtcPerMinWithSession(false),
    };
    if (_data.miningSessionEndsAt != null) {
      map['sessionEndsAt'] = _data.miningSessionEndsAt!.toIso8601String();
    }
    await prefs.setString(_foregroundSnapshotKey, jsonEncode(map));
  }

  /// Cost for next [rig] (exponential scaling by how many already owned).
  double rigCost(MiningRig rig) {
    final count = _data.ownedRigIds.where((id) => id == rig.id).length;
    return MiningRigs.costForCount(rig, count) * (1 - _rigDiscount.clamp(0.0, 0.9));
  }

  Future<void> buyRig(MiningRig rig) async {
    final cost = rigCost(rig);
    final primary = btcBalance;
    if (primary < cost) return;
    if (!canBuyMoreRigs) return;
    _data = _updatePrimaryBalance(_data, -cost);
    _data = _data.copyWith(ownedRigIds: [..._data.ownedRigIds, rig.id]);
    await _persist();
    notifyListeners();
  }

  bool canAfford(MiningRig rig) => btcBalance >= rigCost(rig);

  bool canSpendBtc(double amount) => btcBalance >= amount;

  /// Updates primary (BTC) balance in [data]. Keeps [coinBalances] and [btcBalance] in sync.
  PlayerData _updatePrimaryBalance(PlayerData data, double delta) {
    final cur = data.coinBalances[Coins.primaryId] ?? data.btcBalance;
    final next = (cur + delta).clamp(0.0, double.infinity);
    final newCoins = Map<String, double>.from(data.coinBalances)..[Coins.primaryId] = next;
    return data.copyWith(btcBalance: next, coinBalances: newCoins);
  }

  /// Adds [amount] of [coinId] to balance and lifetime mined; syncs primary if btc.
  PlayerData _addMinedToCoin(PlayerData data, String coinId, double amount) {
    final newCoins = Map<String, double>.from(data.coinBalances);
    newCoins[coinId] = (newCoins[coinId] ?? 0) + amount;
    final newLife = Map<String, double>.from(data.lifetimeMinedByCoin);
    newLife[coinId] = (newLife[coinId] ?? 0) + amount;
    double newBtc = data.btcBalance;
    double newLifeBtc = data.lifetimeMinedBtc;
    if (coinId == Coins.primaryId) {
      newBtc = newCoins[coinId]!;
      newLifeBtc = newLife[coinId]!;
    }
    return data.copyWith(
      coinBalances: newCoins,
      lifetimeMinedByCoin: newLife,
      btcBalance: newBtc,
      lifetimeMinedBtc: newLifeBtc,
    );
  }

  Future<void> deductBtc(double amount) async {
    if (btcBalance < amount) return;
    _data = _updatePrimaryBalance(_data, -amount);
    await _persist();
    notifyListeners();
  }

  Future<void> grantDirectBtc(double amount) async {
    if (amount <= 0) return;
    _data = _addMinedToCoin(_data, Coins.primaryId, amount);
    await _persist();
    notifyListeners();
  }

  Future<void> grantRig(String rigId) async {
    _data = _data.copyWith(ownedRigIds: [..._data.ownedRigIds, rigId]);
    await _persist();
    notifyListeners();
  }

  bool hasPurchasedOneTime(String productId) => _purchasedOneTimeIds.contains(productId);

  double? dailyRewardBtc(int day) {
    switch (day) {
      case 1: return 2e-6;
      case 2: return 5e-6;
      case 3: return 0;
      case 4: return 1e-5;
      case 5: return 2e-5;
      case 6: return 5e-5;
      case 7: return 0;
      default: return null;
    }
  }

  String? dailyRewardRigId(int day) {
    if (day == 3) return 'gpu_rig';
    if (day == 7) return 'mining_rack';
    return null;
  }

  Future<void> claimDailyReward(int day) async {
    if (day < 1 || day > 7) return;
    final btc = dailyRewardBtc(day);
    final rigId = dailyRewardRigId(day);
    if (btc != null && btc > 0) _data = _addMinedToCoin(_data, Coins.primaryId, btc);
    List<String> newRigs = List.from(_data.ownedRigIds);
    if (rigId != null) newRigs.add(rigId);
    _data = _data.copyWith(
      ownedRigIds: newRigs,
      lastDailyRewardDay: currentDayForDaily,
      dailyStreakCount: day,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> claimDaily() async {
    if (!canClaimDaily) return;
    final day = nextDailyStreakDay;
    if (day < 1 || day > 7) return;
    await claimDailyReward(day);
  }

  bool canClaimMilestone(String id) {
    if (_data.claimedMilestones.contains(id)) return false;
    switch (id) {
      case 'sessions_5':
        return _data.totalSessionsStarted >= 5;
      case 'sessions_20':
        return _data.totalSessionsStarted >= 20;
      case 'lifetime_0005':
        return lifetimeMinedBtc >= 0.0005;
      default:
        return false;
    }
  }

  Future<void> claimMilestone(String id) async {
    if (!canClaimMilestone(id)) return;
    double rewardBtc = 0;
    String? rewardRig;
    switch (id) {
      case 'sessions_5':
        rewardBtc = 0.00005;
        break;
      case 'sessions_20':
        rewardRig = 'mining_rack';
        break;
      case 'lifetime_0005':
        rewardBtc = 0.0001;
        break;
      default:
        return;
    }
    final newClaimed = [..._data.claimedMilestones, id];
    final newRigs = [..._data.ownedRigIds, if (rewardRig != null) rewardRig];
    if (rewardBtc > 0) _data = _addMinedToCoin(_data, Coins.primaryId, rewardBtc);
    _data = _data.copyWith(
      ownedRigIds: newRigs,
      claimedMilestones: newClaimed,
    );
    await _persist();
    notifyListeners();
  }

  /// One-time product purchased (IAP or BTC). Apply effect and record in Firebase (or local only if guest).
  Future<void> applyOneTimePurchase({
    required String productId,
    double? btcAmount,
    String? rigId,
  }) async {
    if (_userId != null) {
      await _firebaseSync.recordOneTimePurchase(_userId!, productId);
      _purchasedOneTimeIds = await _firebaseSync.getOneTimePurchases(_userId!);
    } else {
      if (_purchasedOneTimeIds.contains(productId)) return;
      _purchasedOneTimeIds = [..._purchasedOneTimeIds, productId];
    }
    if (btcAmount != null && btcAmount > 0) _data = _addMinedToCoin(_data, Coins.primaryId, btcAmount);
    List<String> newRigs = List.from(_data.ownedRigIds);
    if (rigId != null) newRigs.add(rigId);
    _data = _data.copyWith(ownedRigIds: newRigs);
    await _persist();
    notifyListeners();
  }

  Future<void> activateBoost({Duration duration = const Duration(hours: 1)}) async {
    final expiry = DateTime.now().add(duration);
    if (_userId != null) await _firebaseSync.recordBoostExpiry(_userId!, expiry);
    _boostExpiry = expiry;
    await _persist();
    notifyListeners();
  }

  /// Activate 2x boost for 1 hour. Stored in Firebase when logged in.
  Future<void> activateBoost1h() async {
    await activateBoost(duration: const Duration(hours: 1));
  }

  Future<void> startMiningSession() async {
    if (isSessionActive) return;
    _data = _data.copyWith(
      miningSessionEndsAt: DateTime.now().add(const Duration(minutes: _sessionMinutes)),
      totalSessionsStarted: _data.totalSessionsStarted + 1,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> upgradeFarm() async {
    final next = nextFarmTier;
    if (next == null) return;
    if (btcBalance < next.upgradeCostBtc) return;
    _data = _updatePrimaryBalance(_data, -next.upgradeCostBtc);
    _data = _data.copyWith(farmLevel: next.level);
    await _persist();
    notifyListeners();
  }

  /// Subscribe to premium — one plan at a time. Extends from current expiry if already premium.
  Future<void> activatePremium(String planId, int durationDays) async {
    final now = DateTime.now();
    final base = (_premiumExpiry != null && _premiumExpiry!.isAfter(now))
        ? _premiumExpiry!
        : now;
    final expiry = base.add(Duration(days: durationDays));
    if (_userId != null) {
      await _firebaseSync.recordSubscription(_userId!, planId, expiry);
    }
    _premiumExpiry = expiry;
    await _persist();
    notifyListeners();
  }

  /// Grant reward from watching a rewarded ad. Types: small_btc, medium_btc, boost_15m, gpu_rig.
  Future<void> grantAdReward(String type) async {
    double btc = 0;
    String? rigId;
    Duration? boostDuration;
    switch (type) {
      case 'small_btc':
        btc = 1e-5;
        break;
      case 'medium_btc':
        btc = 5e-5;
        break;
      case 'large_btc':
        btc = 1e-4;
        break;
      case 'boost_15m':
        boostDuration = const Duration(minutes: 15);
        break;
      case 'gpu_rig':
        rigId = 'gpu_rig';
        break;
      default:
        return;
    }
    if (btc > 0) _data = _addMinedToCoin(_data, Coins.primaryId, btc);
    List<String> newRigs = List.from(_data.ownedRigIds);
    if (rigId != null) newRigs.add(rigId);
    _data = _data.copyWith(ownedRigIds: newRigs);
    if (boostDuration != null && _userId != null) {
      final expiry = DateTime.now().add(boostDuration);
      await _firebaseSync.recordBoostExpiry(_userId!, expiry);
      _boostExpiry = expiry;
    } else if (boostDuration != null) {
      _boostExpiry = DateTime.now().add(boostDuration);
    }
    await _persist();
    notifyListeners();
  }

  void updateTick() => tick();

  void tick() {
    final now = DateTime.now();
    if (_data.miningSessionEndsAt != null && _data.miningSessionEndsAt!.isBefore(now)) {
      _data = _data.copyWith(miningSessionEndsAt: null);
    }
    if (_lastTick != null) {
      final diff = now.difference(_lastTick!);
      final mins = diff.inMilliseconds / 60000;
      for (final coin in Coins.all) {
        final rate = _totalRatePerCoinWithSession(coin.id, isSessionActive);
        final earned = rate * mins;
        if (earned > 0) _data = _addMinedToCoin(_data, coin.id, earned);
      }
    }
    _lastTick = now;
    notifyListeners();
  }
}
