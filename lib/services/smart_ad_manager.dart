import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_remote_config_service.dart';

enum AdSlot { appOpen, native, rewarded, interstitial, banner }
enum AdProviderSource { admob, adx }

class _SlotIds {
  final String admob;
  final String adx;
  const _SlotIds({required this.admob, required this.adx});
}

class _AdUnitCatalog {
  static _SlotIds ids(AdSlot slot) {
    final isIOS = Platform.isIOS;
    switch (slot) {
      case AdSlot.banner:
        return _SlotIds(
          admob: isIOS ? 'ca-app-pub-3940256099942544/2934735716' : 'ca-app-pub-3940256099942544/6300978111',
          adx: '/21775744923/example/adaptive-banner',
        );
      case AdSlot.interstitial:
        return _SlotIds(
          admob: isIOS ? 'ca-app-pub-3940256099942544/4411468910' : 'ca-app-pub-3940256099942544/1033173712',
          adx: '/21775744923/example/interstitial',
        );
      case AdSlot.rewarded:
        return _SlotIds(
          admob: isIOS ? 'ca-app-pub-3940256099942544/1712485313' : 'ca-app-pub-3940256099942544/5224354917',
          adx: '/21775744923/example/rewarded',
        );
      case AdSlot.native:
        return _SlotIds(
          admob: isIOS ? 'ca-app-pub-3940256099942544/3986624511' : 'ca-app-pub-3940256099942544/2247696110',
          adx: '/21775744923/example/native',
        );
      case AdSlot.appOpen:
        return _SlotIds(
          admob: isIOS ? 'ca-app-pub-3940256099942544/5575463023' : 'ca-app-pub-3940256099942544/9257395921',
          adx: '/21775744923/example/app-open',
        );
    }
  }
}

class BannerHandle {
  final AdWithView ad;
  final AdProviderSource source;
  BannerHandle({required this.ad, required this.source});
  void dispose() => ad.dispose();
}

class SmartAdManager extends ChangeNotifier {
  SmartAdManager(this._config);

  final AdRemoteConfigService? _config;

  bool _loadingRewarded = false;
  String? _lastError;

  _SlotIds _getIds(AdSlot slot) {
    final fallback = _AdUnitCatalog.ids(slot);
    if (_config == null) return fallback;
    switch (slot) {
      case AdSlot.interstitial:
        return _SlotIds(
          admob: _config!.interstitialAdmobId.isNotEmpty ? _config!.interstitialAdmobId : fallback.admob,
          adx: _config!.interstitialAdxId.isNotEmpty ? _config!.interstitialAdxId : fallback.adx,
        );
      case AdSlot.rewarded:
        return _SlotIds(
          admob: _config!.rewardedAdmobId.isNotEmpty ? _config!.rewardedAdmobId : fallback.admob,
          adx: _config!.rewardedAdxId.isNotEmpty ? _config!.rewardedAdxId : fallback.adx,
        );
      case AdSlot.native:
        return _SlotIds(
          admob: _config!.nativeAdmobId.isNotEmpty ? _config!.nativeAdmobId : fallback.admob,
          adx: _config!.nativeAdxId.isNotEmpty ? _config!.nativeAdxId : fallback.adx,
        );
      case AdSlot.appOpen:
        return _SlotIds(
          admob: _config!.appOpenAdmobId.isNotEmpty ? _config!.appOpenAdmobId : fallback.admob,
          adx: _config!.appOpenAdxId.isNotEmpty ? _config!.appOpenAdxId : fallback.adx,
        );
      case AdSlot.banner:
        return _SlotIds(
          admob: _config!.bannerAdmobId.isNotEmpty ? _config!.bannerAdmobId : fallback.admob,
          adx: _config!.bannerAdxId.isNotEmpty ? _config!.bannerAdxId : fallback.adx,
        );
    }
  }

  RewardedAd? _rewardedAd;
  AdProviderSource? _rewardedSource;
  InterstitialAd? _interstitialAd;
  AdManagerInterstitialAd? _interstitialAdManager;
  AdProviderSource? _interstitialSource;
  AppOpenAd? _appOpenAd;
  AdProviderSource? _appOpenSource;

  bool get loadingRewarded => _loadingRewarded;
  String? get lastError => _lastError;

  Future<void> preloadRewarded() async {
    if (_rewardedAd != null || _loadingRewarded) return;
    _loadingRewarded = true;
    _lastError = null;
    notifyListeners();
    final ids = _getIds(AdSlot.rewarded);
    final completer = Completer<void>();
    RewardedAd? admobAd;
    RewardedAd? adxAd;
    bool resolved = false;
    int failed = 0;

    void resolveWinner(RewardedAd ad, AdProviderSource source) {
      if (resolved) {
        ad.dispose();
        return;
      }
      resolved = true;
      _rewardedAd = ad;
      _rewardedSource = source;
      if (source == AdProviderSource.admob) {
        adxAd?.dispose();
      } else {
        admobAd?.dispose();
      }
      _loadingRewarded = false;
      notifyListeners();
      if (!completer.isCompleted) completer.complete();
    }

    RewardedAd.load(
      adUnitId: ids.admob,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          admobAd = ad;
          resolveWinner(ad, AdProviderSource.admob);
        },
        onAdFailedToLoad: (e) {
          failed++;
          if (failed >= 2 && !resolved) {
            _loadingRewarded = false;
            _lastError = e.message;
            notifyListeners();
            if (!completer.isCompleted) completer.complete();
          }
        },
      ),
    );

    RewardedAd.loadWithAdManagerAdRequest(
      adUnitId: ids.adx,
      adManagerRequest: const AdManagerAdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          adxAd = ad;
          resolveWinner(ad, AdProviderSource.adx);
        },
        onAdFailedToLoad: (e) {
          failed++;
          if (failed >= 2 && !resolved) {
            _loadingRewarded = false;
            _lastError = e.message;
            notifyListeners();
            if (!completer.isCompleted) completer.complete();
          }
        },
      ),
    );

    await completer.future;
  }

  Future<bool> showRewarded({required VoidCallback onEarned}) async {
    await preloadRewarded();
    final ad = _rewardedAd;
    if (ad == null) return false;
    final completer = Completer<bool>();
    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        _lastError = err.message;
        a.dispose();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(
      onUserEarnedReward: (adWithoutView, rewardItem) {
        onEarned();
        if (!completer.isCompleted) completer.complete(true);
      },
    );
    final earned = await completer.future;
    unawaited(preloadRewarded());
    return earned;
  }

  Future<void> preloadInterstitial() async {
    if (_interstitialAd != null || _interstitialAdManager != null) return;
    final ids = _getIds(AdSlot.interstitial);
    final completer = Completer<void>();
    InterstitialAd? admobAd;
    AdManagerInterstitialAd? adxAd;
    bool resolved = false;
    int failed = 0;

    void resolveWinner(AdProviderSource source) {
      if (resolved) return;
      resolved = true;
      if (source == AdProviderSource.admob) {
        _interstitialAd = admobAd;
        adxAd?.dispose();
      } else {
        _interstitialAdManager = adxAd;
        admobAd?.dispose();
      }
      _interstitialSource = source;
      if (!completer.isCompleted) completer.complete();
    }

    InterstitialAd.load(
      adUnitId: ids.admob,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          admobAd = ad;
          if (resolved) {
            ad.dispose();
            return;
          }
          resolveWinner(AdProviderSource.admob);
        },
        onAdFailedToLoad: (e) {
          failed++;
          if (failed >= 2 && !resolved && !completer.isCompleted) completer.complete();
        },
      ),
    );

    AdManagerInterstitialAd.load(
      adUnitId: ids.adx,
      request: const AdManagerAdRequest(),
      adLoadCallback: AdManagerInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          adxAd = ad;
          if (resolved) {
            ad.dispose();
            return;
          }
          resolveWinner(AdProviderSource.adx);
        },
        onAdFailedToLoad: (e) {
          failed++;
          if (failed >= 2 && !resolved && !completer.isCompleted) completer.complete();
        },
      ),
    );

    await completer.future;
  }

  Future<bool> showInterstitial() async {
    await preloadInterstitial();
    final admobAd = _interstitialAd;
    final adxAd = _interstitialAdManager;
    if (admobAd == null && adxAd == null) return false;
    final completer = Completer<bool>();
    _interstitialAd = null;
    _interstitialAdManager = null;
    void onDismissed() {
      completer.complete(true);
    }
    void onFailed(String message) {
      _lastError = message;
      completer.complete(false);
    }
    if (admobAd != null) {
      admobAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          onDismissed();
        },
        onAdFailedToShowFullScreenContent: (a, e) {
          a.dispose();
          onFailed(e.message);
        },
      );
      admobAd.show();
    } else {
      adxAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          onDismissed();
        },
        onAdFailedToShowFullScreenContent: (a, e) {
          a.dispose();
          onFailed(e.message);
        },
      );
      adxAd.show();
    }
    final shown = await completer.future;
    unawaited(preloadInterstitial());
    return shown;
  }

  Future<BannerHandle?> loadBanner(AdSize size) async {
    final ids = _getIds(AdSlot.banner);
    final completer = Completer<BannerHandle?>();
    BannerAd? admob;
    AdManagerBannerAd? adx;
    bool resolved = false;
    int failed = 0;

    void resolveWinner(AdWithView ad, AdProviderSource source) {
      if (resolved) {
        ad.dispose();
        return;
      }
      resolved = true;
      if (source == AdProviderSource.admob) {
        adx?.dispose();
      } else {
        admob?.dispose();
      }
      completer.complete(BannerHandle(ad: ad, source: source));
    }

    admob = BannerAd(
      adUnitId: ids.admob,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) => resolveWinner(ad as AdWithView, AdProviderSource.admob),
        onAdFailedToLoad: (ad, e) {
          ad.dispose();
          failed++;
          if (failed >= 2 && !resolved && !completer.isCompleted) completer.complete(null);
        },
      ),
    )..load();

    adx = AdManagerBannerAd(
      adUnitId: ids.adx,
      request: const AdManagerAdRequest(),
      sizes: [size],
      listener: AdManagerBannerAdListener(
        onAdLoaded: (ad) => resolveWinner(ad as AdWithView, AdProviderSource.adx),
        onAdFailedToLoad: (ad, e) {
          ad.dispose();
          failed++;
          if (failed >= 2 && !resolved && !completer.isCompleted) completer.complete(null);
        },
      ),
    )..load();

    return completer.future;
  }

  Future<void> preloadAppOpen() async {
    if (_appOpenAd != null) return;
    final ids = _getIds(AdSlot.appOpen);
    final completer = Completer<void>();
    AppOpenAd? admobAd;
    AppOpenAd? adxAd;
    bool resolved = false;
    int failed = 0;

    void resolveWinner(AppOpenAd ad, AdProviderSource source) {
      if (resolved) {
        ad.dispose();
        return;
      }
      resolved = true;
      _appOpenAd = ad;
      _appOpenSource = source;
      if (source == AdProviderSource.admob) {
        adxAd?.dispose();
      } else {
        admobAd?.dispose();
      }
      if (!completer.isCompleted) completer.complete();
    }

    AppOpenAd.load(
      adUnitId: ids.admob,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          admobAd = ad;
          resolveWinner(ad, AdProviderSource.admob);
        },
        onAdFailedToLoad: (e) {
          failed++;
          if (failed >= 2 && !resolved && !completer.isCompleted) completer.complete();
        },
      ),
    );

    AppOpenAd.loadWithAdManagerAdRequest(
      adUnitId: ids.adx,
      adManagerAdRequest: const AdManagerAdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          adxAd = ad;
          resolveWinner(ad, AdProviderSource.adx);
        },
        onAdFailedToLoad: (e) {
          failed++;
          if (failed >= 2 && !resolved && !completer.isCompleted) completer.complete();
        },
      ),
    );

    await completer.future;
  }

  Future<bool> showAppOpen() async {
    await preloadAppOpen();
    final ad = _appOpenAd;
    if (ad == null) return false;
    final completer = Completer<bool>();
    _appOpenAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _lastError = e.message;
        completer.complete(false);
      },
    );
    ad.show();
    final shown = await completer.future;
    unawaited(preloadAppOpen());
    return shown;
  }

  Future<NativeAd?> loadNative({required String factoryId}) async {
    final ids = _getIds(AdSlot.native);
    final completer = Completer<NativeAd?>();
    NativeAd? admob;
    NativeAd? adx;
    bool resolved = false;
    int failed = 0;

    void resolveWinner(NativeAd ad, AdProviderSource source) {
      if (resolved) {
        ad.dispose();
        return;
      }
      resolved = true;
      if (source == AdProviderSource.admob) {
        adx?.dispose();
      } else {
        admob?.dispose();
      }
      completer.complete(ad);
    }

    admob = NativeAd(
      adUnitId: ids.admob,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => resolveWinner(ad as NativeAd, AdProviderSource.admob),
        onAdFailedToLoad: (ad, e) {
          ad.dispose();
          failed++;
          if (failed >= 2 && !resolved && !completer.isCompleted) completer.complete(null);
        },
      ),
    )..load();

    adx = NativeAd.fromAdManagerRequest(
      adUnitId: ids.adx,
      factoryId: factoryId,
      adManagerRequest: const AdManagerAdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => resolveWinner(ad as NativeAd, AdProviderSource.adx),
        onAdFailedToLoad: (ad, e) {
          ad.dispose();
          failed++;
          if (failed >= 2 && !resolved && !completer.isCompleted) completer.complete(null);
        },
      ),
    )..load();

    return completer.future;
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _interstitialAdManager?.dispose();
    _appOpenAd?.dispose();
    super.dispose();
  }
}

