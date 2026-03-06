import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Rewarded ad unit IDs. Replace with your own from AdMob for release.
class AdUnits {
  static String get rewarded {
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return 'ca-app-pub-3940256099942544/5224354917';
  }
}

/// Loads and shows rewarded ads; notifies when user earned reward.
class AdRewardService extends ChangeNotifier {
  RewardedAd? _ad;
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Callback when user completed the ad and earned reward. Parameter = reward type to grant.
  void Function(String rewardType)? onUserEarnedReward;

  Future<void> loadAd() async {
    if (_ad != null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    await RewardedAd.load(
      adUnitId: AdUnits.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _ad = null;
              _error = err.message;
              notifyListeners();
            },
          );
          _loading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          _error = err.message;
          _loading = false;
          notifyListeners();
        },
      ),
    );
  }

  /// Show ad. When user earns reward, onUserEarnedReward(rewardType) is called. Returns true if reward was earned.
  Future<bool> show(String rewardType) async {
    if (_ad == null) await loadAd();
    if (_ad == null) return false;
    final completer = Completer<bool>();
    final ad = _ad!;
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!completer.isCompleted) completer.complete(false);
        _loading = false;
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        if (!completer.isCompleted) completer.complete(false);
        _error = err.message;
        _loading = false;
        notifyListeners();
      },
    );
    ad.show(
      onUserEarnedReward: (a, item) {
        onUserEarnedReward?.call(rewardType);
        if (!completer.isCompleted) completer.complete(true);
      },
    );
    _loading = true;
    notifyListeners();
    return completer.future;
  }
}
