import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class AdPacingService extends ChangeNotifier {
  static const _lastInterstitialMsKey = 'ads_last_interstitial_ms';
  static const _lastAppOpenMsKey = 'ads_last_app_open_ms';
  static const _lastRewardedMsKey = 'ads_last_rewarded_ms';
  static const _dailyDateKey = 'ads_daily_date';
  static const _dailyInterstitialCountKey = 'ads_daily_interstitial_count';
  static const _dailyAppOpenCountKey = 'ads_daily_app_open_count';
  static const _navTransitionsKey = 'ads_nav_transitions';

  static const _interstitialCooldown = Duration(minutes: 8);
  static const _appOpenCooldown = Duration(minutes: 20);
  static const _rewardedCooldown = Duration(seconds: 45);
  static const _maxInterstitialPerDay = 8;
  static const _maxAppOpenPerDay = 4;
  static const _interstitialEveryNTransitions = 3;

  DateTime? _lastInterstitialAt;
  DateTime? _lastAppOpenAt;
  DateTime? _lastRewardedAt;
  int _dailyInterstitialCount = 0;
  int _dailyAppOpenCount = 0;
  int _navTransitions = 0;
  String _dailyDate = '';

  int get dailyInterstitialCount => _dailyInterstitialCount;
  int get dailyAppOpenCount => _dailyAppOpenCount;
  DateTime? get lastRewardedAt => _lastRewardedAt;

  Future<void> load() async {
    await LocalFeatureStore.init();
    _dailyDate = LocalFeatureStore.get(_dailyDateKey, _todayKey()).toString();
    _dailyInterstitialCount = (LocalFeatureStore.get(_dailyInterstitialCountKey, 0) as num).toInt();
    _dailyAppOpenCount = (LocalFeatureStore.get(_dailyAppOpenCountKey, 0) as num).toInt();
    _navTransitions = (LocalFeatureStore.get(_navTransitionsKey, 0) as num).toInt();
    final interMs = LocalFeatureStore.get(_lastInterstitialMsKey);
    final openMs = LocalFeatureStore.get(_lastAppOpenMsKey);
    final rewardMs = LocalFeatureStore.get(_lastRewardedMsKey);
    if (interMs is int) _lastInterstitialAt = DateTime.fromMillisecondsSinceEpoch(interMs);
    if (openMs is int) _lastAppOpenAt = DateTime.fromMillisecondsSinceEpoch(openMs);
    if (rewardMs is int) _lastRewardedAt = DateTime.fromMillisecondsSinceEpoch(rewardMs);
    await _rolloverIfNeeded();
    notifyListeners();
  }

  Future<void> registerNavigationTransition() async {
    _navTransitions += 1;
    await LocalFeatureStore.set(_navTransitionsKey, _navTransitions);
  }

  Future<bool> shouldShowInterstitial({required int completedSessions}) async {
    await _rolloverIfNeeded();
    if (completedSessions < 1) return false; // No intrusive ads before first completed session.
    if (_dailyInterstitialCount >= _maxInterstitialPerDay) return false;
    if (_navTransitions < _interstitialEveryNTransitions) return false;
    if (_lastInterstitialAt != null &&
        DateTime.now().difference(_lastInterstitialAt!) < _interstitialCooldown) {
      return false;
    }
    return true;
  }

  Future<void> markInterstitialShown() async {
    _lastInterstitialAt = DateTime.now();
    _dailyInterstitialCount += 1;
    _navTransitions = 0;
    await LocalFeatureStore.set(_lastInterstitialMsKey, _lastInterstitialAt!.millisecondsSinceEpoch);
    await LocalFeatureStore.set(_dailyInterstitialCountKey, _dailyInterstitialCount);
    await LocalFeatureStore.set(_navTransitionsKey, _navTransitions);
    notifyListeners();
  }

  Future<bool> canShowAppOpen({required int completedSessions}) async {
    await _rolloverIfNeeded();
    if (completedSessions < 1) return false;
    if (_dailyAppOpenCount >= _maxAppOpenPerDay) return false;
    if (_lastAppOpenAt != null &&
        DateTime.now().difference(_lastAppOpenAt!) < _appOpenCooldown) {
      return false;
    }
    return true;
  }

  Future<void> markAppOpenShown() async {
    _lastAppOpenAt = DateTime.now();
    _dailyAppOpenCount += 1;
    await LocalFeatureStore.set(_lastAppOpenMsKey, _lastAppOpenAt!.millisecondsSinceEpoch);
    await LocalFeatureStore.set(_dailyAppOpenCountKey, _dailyAppOpenCount);
    notifyListeners();
  }

  Future<bool> canShowRewarded() async {
    if (_lastRewardedAt == null) return true;
    return DateTime.now().difference(_lastRewardedAt!) >= _rewardedCooldown;
  }

  Duration rewardedCooldownLeft() {
    if (_lastRewardedAt == null) return Duration.zero;
    final left = _rewardedCooldown - DateTime.now().difference(_lastRewardedAt!);
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> markRewardedShown() async {
    _lastRewardedAt = DateTime.now();
    await LocalFeatureStore.set(_lastRewardedMsKey, _lastRewardedAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> _rolloverIfNeeded() async {
    final today = _todayKey();
    if (_dailyDate == today) return;
    _dailyDate = today;
    _dailyInterstitialCount = 0;
    _dailyAppOpenCount = 0;
    _navTransitions = 0;
    await LocalFeatureStore.set(_dailyDateKey, _dailyDate);
    await LocalFeatureStore.set(_dailyInterstitialCountKey, _dailyInterstitialCount);
    await LocalFeatureStore.set(_dailyAppOpenCountKey, _dailyAppOpenCount);
    await LocalFeatureStore.set(_navTransitionsKey, _navTransitions);
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }
}

