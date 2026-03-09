import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// One-time "we missed you" bonus when user returns after 24-48h.
class ComebackBonusService extends ChangeNotifier {
  static const _lastOpenMsKey = 'comeback_last_open_ms';
  static const _claimedKey = 'comeback_claimed_ms';

  int? _lastOpenMs;
  int? _claimedMs;

  static const int hoursThreshold = 24;
  static const double bonusBtc = 0.00005;

  bool get canClaim {
    if (_lastOpenMs == null) return false;
    if (_claimedMs != null) return false;
    final elapsed = (DateTime.now().millisecondsSinceEpoch - _lastOpenMs!) / (1000 * 60 * 60);
    return elapsed >= hoursThreshold;
  }

  Future<void> load() async {
    await LocalFeatureStore.init();
    final last = LocalFeatureStore.get(_lastOpenMsKey);
    final claimed = LocalFeatureStore.get(_claimedKey);
    _lastOpenMs = last is int ? last : null;
    _claimedMs = claimed is int ? claimed : null;
    notifyListeners();
  }

  Future<void> recordOpen() async {
    await LocalFeatureStore.init();
    _lastOpenMs = DateTime.now().millisecondsSinceEpoch;
    await LocalFeatureStore.set(_lastOpenMsKey, _lastOpenMs!);
    notifyListeners();
  }

  Future<void> markClaimed() async {
    if (_claimedMs != null) return;
    await LocalFeatureStore.init();
    _claimedMs = DateTime.now().millisecondsSinceEpoch;
    await LocalFeatureStore.set(_claimedKey, _claimedMs!);
    notifyListeners();
  }
}
