import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Withdrawal is unlocked by completing tasks + watching rewarded ads.
/// Minimum withdrawal: $100 worth of BTC.
class WithdrawalService extends ChangeNotifier {
  static const _unlockedKey = 'withdrawal_unlocked';

  bool _unlocked = false;
  bool get withdrawalUnlocked => _unlocked;

  static const int sessionsRequired = 5;
  static const int rewardedAdsRequired = 3;
  static const double minBtcToUnlock = 0.001;
  static const double minWithdrawalUsd = 100.0;

  Future<void> load() async {
    await LocalFeatureStore.init();
    _unlocked = LocalFeatureStore.get(_unlockedKey, false) == true;
    notifyListeners();
  }

  /// Call from UI when displaying to re-evaluate unlock state. Sync so safe to call from build.
  /// Only notifies when value changes to avoid rebuild loops.
  void recheckUnlock({
    required int totalSessionsStarted,
    required int rewardedAdsWatched,
    required double btcBalance,
  }) {
    final newUnlocked = totalSessionsStarted >= sessionsRequired &&
        rewardedAdsWatched >= rewardedAdsRequired &&
        btcBalance >= minBtcToUnlock;
    final wasUnlocked = _unlocked;
    if (newUnlocked) {
      if (!_unlocked) {
        _unlocked = true;
        LocalFeatureStore.set(_unlockedKey, true);
      }
    } else if (!wasUnlocked) {
      _unlocked = false;
    }
    if (wasUnlocked != _unlocked) notifyListeners();
  }

  bool meetsSessions(int totalSessionsStarted) =>
      totalSessionsStarted >= sessionsRequired;
  bool meetsRewardedAds(int rewardedAdsWatched) =>
      rewardedAdsWatched >= rewardedAdsRequired;
  bool meetsMinBtc(double btcBalance) => btcBalance >= minBtcToUnlock;

  /// Minimum BTC needed for withdrawal when price is [usdPerBtc].
  double minBtcForWithdrawal(double usdPerBtc) {
    if (usdPerBtc <= 0) return 0;
    return minWithdrawalUsd / usdPerBtc;
  }
}
