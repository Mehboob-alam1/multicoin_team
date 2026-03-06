import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class DailyBoostService extends ChangeNotifier {
  static const _lastClaimKey = 'daily_boost_last_claim_ms';
  static const _activeUntilKey = 'daily_boost_active_until_ms';

  DateTime? _lastClaimAt;
  DateTime? _activeUntil;

  DateTime? get lastClaimAt => _lastClaimAt;
  DateTime? get activeUntil => _activeUntil;
  bool get isActive => _activeUntil != null && _activeUntil!.isAfter(DateTime.now());
  bool get canClaim {
    if (_lastClaimAt == null) return true;
    return DateTime.now().difference(_lastClaimAt!).inHours >= 24;
  }

  Future<void> load() async {
    await LocalFeatureStore.init();
    final lastMs = LocalFeatureStore.get(_lastClaimKey);
    final untilMs = LocalFeatureStore.get(_activeUntilKey);
    if (lastMs is int) _lastClaimAt = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (untilMs is int) _activeUntil = DateTime.fromMillisecondsSinceEpoch(untilMs);
    notifyListeners();
  }

  Future<bool> claim() async {
    if (!canClaim) return false;
    _lastClaimAt = DateTime.now();
    _activeUntil = DateTime.now().add(const Duration(minutes: 30));
    await LocalFeatureStore.set(_lastClaimKey, _lastClaimAt!.millisecondsSinceEpoch);
    await LocalFeatureStore.set(_activeUntilKey, _activeUntil!.millisecondsSinceEpoch);
    notifyListeners();
    return true;
  }

  double get miningMultiplier => isActive ? 2.0 : 1.0;
}

