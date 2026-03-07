import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm_tier.dart';
import '../models/mining_rig.dart';
import '../models/player_data.dart';
import 'firebase_sync_service.dart';

class GameStateService extends ChangeNotifier {
  GameStateService(this._firebaseSync);

  final FirebaseSyncService _firebaseSync;
  static const _key = 'btc_sim_player_data';
  static const _maxIdleMinutes = 8 * 60;
  static const _sessionMinutes = 30;
  static const _minRemoteSyncInterval = Duration(minutes: 5);

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
  double _eventMiningMultiplier = 1.0;
  double _dailyBoostMultiplier = 1.0;
  double _efficiencyMultiplier = 1.0;
  int _locationCapacityBonus = 0;
  double _rigDiscount = 0.0;

  bool get isLoaded => _loaded;
  PlayerData get data => _data;
  double get btcBalance => _data.btcBalance;
  List<String> get ownedRigIds => List.unmodifiable(_data.ownedRigIds);
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
  double get lifetimeMinedBtc => _data.lifetimeMinedBtc;
  int get totalSessionsStarted => _data.totalSessionsStarted;
  List<String> get claimedMilestones => List.unmodifiable(_data.claimedMilestones);

  FarmTier get currentFarmTier => FarmTiers.byLevel(_data.farmLevel);
  FarmTier? get nextFarmTier => FarmTiers.nextLevel(_data.farmLevel);
  int get rigCapacity => currentFarmTier.rigCapacity + _locationCapacityBonus;
  bool get canBuyMoreRigs => _data.ownedRigIds.length < rigCapacity;

  double get totalBtcPerMin {
    return _totalBtcPerMinWithSession(isSessionActive);
  }

  /// Rate in BTC/min. When [sessionActive] true, applies 1.25× session bonus.
  double _totalBtcPerMinWithSession(bool sessionActive) {
    double sum = 0;
    for (final id in _data.ownedRigIds) {
      final rig = MiningRigs.byId(id);
      if (rig != null) sum += rig.btcPerMin;
    }
    double mult = 1.0;
    mult *= currentFarmTier.miningMultiplier;
    mult *= _oneTimeMiningMultiplier();
    if (sessionActive) mult *= 1.25;
    if (isBoostActive) mult *= 2.0;
    if (isPremiumActive) mult *= 1.5;
    mult *= _eventMiningMultiplier;
    mult *= _dailyBoostMultiplier;
    mult *= _efficiencyMultiplier;
    return sum * mult;
  }

  void applyExternalGameplayModifiers({
    required double eventMiningMultiplier,
    required double dailyBoostMultiplier,
    required double efficiencyMultiplier,
    required int locationCapacityBonus,
    double rigDiscount = 0.0,
  }) {
    final changed = _eventMiningMultiplier != eventMiningMultiplier ||
        _dailyBoostMultiplier != dailyBoostMultiplier ||
        _efficiencyMultiplier != efficiencyMultiplier ||
        _locationCapacityBonus != locationCapacityBonus ||
        _rigDiscount != rigDiscount;
    _eventMiningMultiplier = eventMiningMultiplier;
    _dailyBoostMultiplier = dailyBoostMultiplier;
    _efficiencyMultiplier = efficiencyMultiplier;
    _locationCapacityBonus = locationCapacityBonus;
    _rigDiscount = rigDiscount;
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

  void setUserId(String? id) => _userId = id;
  void setDisplayName(String? name) {
    if (name != null && name.isNotEmpty) _displayName = name;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userId != null ? '${_key}_$_userId' : _key;

    if (_userId != null) {
      final remote = await _firebaseSync.fetchPlayerData(_userId!);
      if (remote != null) _data = remote;
      final oneTime = await _firebaseSync.getOneTimePurchases(_userId!);
      _purchasedOneTimeIds = oneTime;
      _premiumExpiry = await _firebaseSync.getSubscriptionExpiry(_userId!);
      _boostExpiry = await _loadBoostExpiry();
    }

    if (_data.ownedRigIds.isEmpty) {
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          _data = PlayerData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        } catch (_) {}
      }
      if (_data.ownedRigIds.isEmpty) _data = const PlayerData();
    } else {
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          final local = PlayerData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
          if (local.lastClosedAt != null) _data = _data.copyWith(lastClosedAt: local.lastClosedAt);
        } catch (_) {}
      }
    }

    _lastTick = DateTime.now();
    if (_data.miningSessionEndsAt != null &&
        _data.miningSessionEndsAt!.isBefore(DateTime.now())) {
      _data = _data.copyWith(miningSessionEndsAt: null);
    }
    _applyIdleEarnings();
    await _persist(forceRemote: false, markDirty: false);
    _loaded = true;
    notifyListeners();
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
      _data = _data.copyWith(
        btcBalance: _data.btcBalance + earned,
        lifetimeMinedBtc: _data.lifetimeMinedBtc + earned,
        lastClosedAt: null,
      );
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
      _data = _data.copyWith(
        btcBalance: _data.btcBalance + earned,
        lifetimeMinedBtc: _data.lifetimeMinedBtc + earned,
        lastClosedAt: null,
      );
      await _persist(forceRemote: false, markDirty: true);
      notifyListeners();
    } else {
      _data = _data.copyWith(lastClosedAt: null);
      await _persist(forceRemote: false, markDirty: false);
      notifyListeners();
    }
  }

  Future<void> _persist({bool forceRemote = false, bool markDirty = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _userId != null ? '${_key}_$_userId' : _key;
    await prefs.setString(key, jsonEncode(_data.toJson()));

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
          btcBalance: _data.btcBalance,
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

  Future<void> saveAndClose() async {
    _data = _data.copyWith(lastClosedAt: DateTime.now());
    await _persist(forceRemote: true);
  }

  /// Sync current state to local storage and Firebase (without setting lastClosedAt).
  Future<void> syncToCloud() async {
    await _persist(forceRemote: false, markDirty: false);
  }

  double rigCost(MiningRig rig) => rig.costBtc * (1 - _rigDiscount.clamp(0.0, 0.9));

  Future<void> buyRig(MiningRig rig) async {
    final cost = rigCost(rig);
    if (_data.btcBalance < cost) return;
    if (!canBuyMoreRigs) return;
    _data = _data.copyWith(
      btcBalance: _data.btcBalance - cost,
      ownedRigIds: [..._data.ownedRigIds, rig.id],
    );
    await _persist();
    notifyListeners();
  }

  bool canAfford(MiningRig rig) => _data.btcBalance >= rigCost(rig);

  bool canSpendBtc(double amount) => _data.btcBalance >= amount;

  Future<void> deductBtc(double amount) async {
    if (_data.btcBalance < amount) return;
    _data = _data.copyWith(btcBalance: _data.btcBalance - amount);
    await _persist();
    notifyListeners();
  }

  Future<void> grantDirectBtc(double amount) async {
    if (amount <= 0) return;
    _data = _data.copyWith(
      btcBalance: _data.btcBalance + amount,
      lifetimeMinedBtc: _data.lifetimeMinedBtc + amount,
    );
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
    double newBtc = _data.btcBalance;
    if (btc != null && btc > 0) newBtc += btc;
    List<String> newRigs = List.from(_data.ownedRigIds);
    if (rigId != null) newRigs.add(rigId);
    _data = _data.copyWith(
      btcBalance: newBtc,
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
        return _data.lifetimeMinedBtc >= 0.0005;
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
    _data = _data.copyWith(
      btcBalance: _data.btcBalance + rewardBtc,
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
    double newBtc = _data.btcBalance;
    if (btcAmount != null && btcAmount > 0) newBtc += btcAmount;
    List<String> newRigs = List.from(_data.ownedRigIds);
    if (rigId != null) newRigs.add(rigId);
    _data = _data.copyWith(btcBalance: newBtc, ownedRigIds: newRigs);
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
    if (_data.btcBalance < next.upgradeCostBtc) return;
    _data = _data.copyWith(
      btcBalance: _data.btcBalance - next.upgradeCostBtc,
      farmLevel: next.level,
    );
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
    double newBtc = _data.btcBalance + btc;
    List<String> newRigs = List.from(_data.ownedRigIds);
    if (rigId != null) newRigs.add(rigId);
    _data = _data.copyWith(btcBalance: newBtc, ownedRigIds: newRigs);
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
      final earned = totalBtcPerMin * mins;
      _data = _data.copyWith(
        btcBalance: _data.btcBalance + earned,
        lifetimeMinedBtc: _data.lifetimeMinedBtc + earned,
      );
    }
    _lastTick = now;
    notifyListeners();
  }
}
