import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Withdrawal tasks, in order:
/// 1) watch 10 rewarded ads
/// 2) reach $100 USD in SOL
/// 3) buy the unlock pack (only after $100)
class WithdrawalService extends ChangeNotifier {
  static const _unlockedKey = 'withdrawal_unlocked';
  static const _unlockAdsKey = 'withdrawal_unlock_ads_watched';

  static const String unlockProductId = 'withdraw_unlock';
  static const String unlockPriceLabel = '\$4.99';

  bool _unlocked = false;
  int _unlockAdsWatched = 0;

  bool get withdrawalUnlocked => _unlocked;
  int get unlockAdsWatched => _unlockAdsWatched;

  static const int rewardedAdsRequired = 10;
  static const double minWithdrawalUsd = 100.0;

  bool get adsComplete => _unlockAdsWatched >= rewardedAdsRequired;

  bool minBalanceReached(double? worthUsd) =>
      worthUsd != null && worthUsd >= minWithdrawalUsd;

  /// 1 = ads, 2 = reach $100, 3 = buy unlock, 4 = request withdrawal.
  int currentStep({
    required bool purchasedUnlock,
    required double? worthUsd,
  }) {
    if (!adsComplete) return 1;
    if (!minBalanceReached(worthUsd)) return 2;
    if (!purchasedUnlock) return 3;
    return 4;
  }

  Future<void> load() async {
    await LocalFeatureStore.init();
    _unlocked = LocalFeatureStore.get(_unlockedKey, false) == true;
    _unlockAdsWatched =
        (LocalFeatureStore.get(_unlockAdsKey, 0) as num?)?.toInt() ?? 0;
    notifyListeners();
  }

  void recheckUnlock({
    required bool purchasedUnlock,
    required double? worthUsd,
  }) {
    final newUnlocked =
        adsComplete && minBalanceReached(worthUsd) && purchasedUnlock;
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

  Future<void> recordUnlockAdWatched() async {
    if (_unlockAdsWatched >= rewardedAdsRequired) return;
    _unlockAdsWatched += 1;
    await LocalFeatureStore.set(_unlockAdsKey, _unlockAdsWatched);
    notifyListeners();
  }

  double minBtcForWithdrawal(double usdPerBtc) {
    if (usdPerBtc <= 0) return 0;
    return minWithdrawalUsd / usdPerBtc;
  }
}
