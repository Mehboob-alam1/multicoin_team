import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_remote_config_service.dart';

enum AdSlot { appOpen, native, rewarded, interstitial, banner }

enum AdProviderSource { admob, adx }

class _SlotIds {
  final String admob;
  final String adx;
  const _SlotIds({required this.admob, required this.adx});
}

class _Attempt {
  final String id;
  final AdProviderSource source;
  const _Attempt(this.id, this.source);
}

class _AdUnitCatalog {
  static _SlotIds ids(AdSlot slot) {
    final isIOS = Platform.isIOS;
    switch (slot) {
      case AdSlot.banner:
        return _SlotIds(
          admob: isIOS
              ? 'ca-app-pub-3940256099942544/2934735716'
              : 'ca-app-pub-3940256099942544/6300978111',
          adx: '/21775744923/example/adaptive-banner',
        );
      case AdSlot.interstitial:
        return _SlotIds(
          admob: isIOS
              ? 'ca-app-pub-3940256099942544/4411468910'
              : 'ca-app-pub-3940256099942544/1033173712',
          adx: '/21775744923/example/interstitial',
        );
      case AdSlot.rewarded:
        return _SlotIds(
          admob: isIOS
              ? 'ca-app-pub-3940256099942544/1712485313'
              : 'ca-app-pub-3940256099942544/5224354917',
          adx: '/21775744923/example/rewarded',
        );
      case AdSlot.native:
        return _SlotIds(
          admob: isIOS
              ? 'ca-app-pub-3940256099942544/3986624511'
              : 'ca-app-pub-3940256099942544/2247696110',
          adx: '/21775744923/example/native',
        );
      case AdSlot.appOpen:
        return _SlotIds(
          admob: isIOS
              ? 'ca-app-pub-3940256099942544/5575463023'
              : 'ca-app-pub-3940256099942544/9257395921',
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

/// AdMob first, then AdX, then Google test AdMob — never skip a fill chance.
class SmartAdManager extends ChangeNotifier {
  SmartAdManager(this._config);

  static const nativeFactoryId = 'adFactoryMedium';

  final AdRemoteConfigService? _config;

  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;
  bool _loadingAppOpen = false;
  bool _preloadingAll = false;
  Future<void>? _interstitialLoadFuture;
  Future<void>? _appOpenLoadFuture;
  bool _showingFullscreen = false;
  String? _lastError;
  final List<NativeAd> _nativePool = [];
  final List<BannerHandle> _bannerPool = [];

  RewardedAd? _rewardedAd;
  AdProviderSource? _rewardedSource;
  InterstitialAd? _interstitialAd;
  AdManagerInterstitialAd? _interstitialAdManager;
  AdProviderSource? _interstitialSource;
  AppOpenAd? _appOpenAd;
  AdProviderSource? _appOpenSource;

  bool get loadingRewarded => _loadingRewarded;
  String? get lastError => _lastError;
  bool get interstitialReady =>
      _interstitialAd != null || _interstitialAdManager != null;
  bool get appOpenReady => _appOpenAd != null;
  bool get rewardedReady => _rewardedAd != null;
  bool get showingFullscreen => _showingFullscreen;

  static bool _usableAdUnit(String id) {
    final t = id.trim();
    if (t.isEmpty) return false;
    final lower = t.toLowerCase();
    if (lower == 'null' || lower.contains('your_ad')) return false;
    return t.startsWith('ca-app-pub-') || t.startsWith('/');
  }

  _SlotIds _remoteIds(AdSlot slot) {
    final fallback = _AdUnitCatalog.ids(slot);
    final cfg = _config;
    if (cfg == null) return fallback;
    switch (slot) {
      case AdSlot.interstitial:
        return _SlotIds(
          admob: cfg.interstitialAdmobId,
          adx: cfg.interstitialAdxId,
        );
      case AdSlot.rewarded:
        return _SlotIds(admob: cfg.rewardedAdmobId, adx: cfg.rewardedAdxId);
      case AdSlot.native:
        return _SlotIds(admob: cfg.nativeAdmobId, adx: cfg.nativeAdxId);
      case AdSlot.appOpen:
        return _SlotIds(admob: cfg.appOpenAdmobId, adx: cfg.appOpenAdxId);
      case AdSlot.banner:
        return _SlotIds(admob: cfg.bannerAdmobId, adx: cfg.bannerAdxId);
    }
  }

  /// 1) Remote AdMob  2) Remote AdX  3) Google test AdMob  4) catalog AdX
  List<_Attempt> _waterfall(AdSlot slot) {
    final remote = _remoteIds(slot);
    final catalog = _AdUnitCatalog.ids(slot);
    final seen = <String>{};
    final steps = <_Attempt>[];
    void add(String raw) {
      final id = raw.trim();
      if (!_usableAdUnit(id) || !seen.add(id)) return;
      steps.add(_Attempt(
        id,
        id.startsWith('/') ? AdProviderSource.adx : AdProviderSource.admob,
      ));
    }

    add(remote.admob);
    add(remote.adx);
    add(catalog.admob);
    add(catalog.adx);
    return steps;
  }

  Future<T?> _tryWaterfall<T>(
    AdSlot slot,
    Future<T?> Function(String id, AdProviderSource source) load,
  ) async {
    for (final step in _waterfall(slot)) {
      debugPrint('Ads try ${slot.name} ${step.source.name} ${step.id}');
      try {
        final ad = await load(step.id, step.source);
        if (ad != null) {
          debugPrint('Ads filled ${slot.name} via ${step.source.name}');
          return ad;
        }
      } catch (e) {
        debugPrint('Ads ${slot.name} ${step.source.name} threw: $e');
      }
    }
    debugPrint('Ads miss ${slot.name}');
    return null;
  }

  bool _slotOn(AdSlot slot) {
    if (!Platform.isAndroid) return false;
    final cfg = _config;
    if (cfg == null) return true;
    switch (slot) {
      case AdSlot.interstitial:
        return cfg.interstitialEnabled;
      case AdSlot.appOpen:
        return cfg.appOpenEnabled;
      case AdSlot.native:
        return cfg.nativeEnabled;
      case AdSlot.banner:
        return cfg.bannerEnabled;
      case AdSlot.rewarded:
        return cfg.rewardedEnabled;
    }
  }

  Future<void> preloadAll() async {
    if (_preloadingAll) return;
    _preloadingAll = true;
    try {
      if (_slotOn(AdSlot.appOpen)) await preloadAppOpen();
      await Future.wait([
        if (_slotOn(AdSlot.interstitial)) preloadInterstitial(),
        if (_slotOn(AdSlot.rewarded)) preloadRewarded(),
      ]);
      unawaited(Future.wait([
        if (_slotOn(AdSlot.native)) preloadNativePool(count: 1),
        if (_slotOn(AdSlot.banner)) preloadBannerPool(count: 1),
      ]));
    } catch (e) {
      debugPrint('Ad preloadAll: $e');
    }
    _preloadingAll = false;
    notifyListeners();
  }

  Future<void> preloadNativePool({int count = 1}) async {
    if (!_slotOn(AdSlot.native)) return;
    final needed = count - _nativePool.length;
    if (needed <= 0) return;
    final loaded = await Future.wait(
      List.generate(needed, (_) => loadNative(factoryId: nativeFactoryId)),
    );
    for (final ad in loaded) {
      if (ad != null) _nativePool.add(ad);
    }
  }

  Future<void> preloadBannerPool({int count = 1}) async {
    if (!_slotOn(AdSlot.banner)) return;
    final needed = count - _bannerPool.length;
    if (needed <= 0) return;
    for (var i = 0; i < needed; i++) {
      final handle = await loadBanner(AdSize.banner);
      if (handle != null) _bannerPool.add(handle);
    }
  }

  NativeAd? takeNativeIfReady() {
    if (_nativePool.isEmpty) return null;
    final ad = _nativePool.removeLast();
    unawaited(preloadNativePool(count: 1));
    return ad;
  }

  BannerHandle? takeBannerIfReady() {
    if (_bannerPool.isEmpty) return null;
    final handle = _bannerPool.removeLast();
    unawaited(preloadBannerPool(count: 1));
    return handle;
  }

  Future<NativeAd?> takeNative({String factoryId = nativeFactoryId}) async {
    return takeNativeIfReady() ?? loadNative(factoryId: factoryId);
  }

  Future<void> preloadRewarded() async {
    if (!_slotOn(AdSlot.rewarded)) return;
    if (_rewardedAd != null || _loadingRewarded) return;
    _loadingRewarded = true;
    _lastError = null;
    notifyListeners();
    final loaded = await _tryWaterfall<RewardedAd>(AdSlot.rewarded, _loadRewarded);
    _rewardedAd = loaded;
    if (loaded != null) {
      _rewardedSource = loaded.adUnitId.startsWith('/')
          ? AdProviderSource.adx
          : AdProviderSource.admob;
    }
    _loadingRewarded = false;
    notifyListeners();
  }

  Future<RewardedAd?> _loadRewarded(String id, AdProviderSource source) {
    final completer = Completer<RewardedAd?>();
    final callback = RewardedAdLoadCallback(
      onAdLoaded: (ad) {
        if (!completer.isCompleted) completer.complete(ad);
      },
      onAdFailedToLoad: (e) {
        debugPrint('Rewarded failed ($id): ${e.message}');
        _lastError = e.message;
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    if (source == AdProviderSource.adx) {
      RewardedAd.loadWithAdManagerAdRequest(
        adUnitId: id,
        adManagerRequest: const AdManagerAdRequest(),
        rewardedAdLoadCallback: callback,
      );
    } else {
      RewardedAd.load(
        adUnitId: id,
        request: const AdRequest(),
        rewardedAdLoadCallback: callback,
      );
    }
    return completer.future.timeout(const Duration(seconds: 8), onTimeout: () {
      if (!completer.isCompleted) completer.complete(null);
      return null;
    });
  }

  Future<bool> showRewarded({required VoidCallback onEarned}) async {
    if (!_slotOn(AdSlot.rewarded)) return false;
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
    final earned = await completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => false,
    );
    unawaited(preloadRewarded());
    return earned;
  }

  Future<void> preloadInterstitial() async {
    if (!_slotOn(AdSlot.interstitial)) return;
    if (_interstitialAd != null || _interstitialAdManager != null) return;
    if (_interstitialLoadFuture != null) {
      await _interstitialLoadFuture;
      return;
    }
    _interstitialLoadFuture = () async {
      _loadingInterstitial = true;
      await _tryWaterfall<Object>(AdSlot.interstitial, (id, source) async {
        if (source == AdProviderSource.adx) {
          final ad = await _loadAdxInterstitial(id);
          if (ad != null) {
            _interstitialAdManager = ad;
            _interstitialSource = AdProviderSource.adx;
          }
          return ad;
        }
        final ad = await _loadAdmobInterstitial(id);
        if (ad != null) {
          _interstitialAd = ad;
          _interstitialSource = AdProviderSource.admob;
        }
        return ad;
      });
      _loadingInterstitial = false;
      debugPrint('Interstitial ready=$interstitialReady source=$_interstitialSource');
    }();
    try {
      await _interstitialLoadFuture;
    } finally {
      _interstitialLoadFuture = null;
    }
  }

  Future<InterstitialAd?> _loadAdmobInterstitial(String id) {
    final completer = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (e) {
          debugPrint('Interstitial AdMob failed ($id): ${e.message}');
          _lastError = e.message;
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future.timeout(const Duration(seconds: 8), onTimeout: () {
      if (!completer.isCompleted) completer.complete(null);
      return null;
    });
  }

  Future<AdManagerInterstitialAd?> _loadAdxInterstitial(String id) {
    final completer = Completer<AdManagerInterstitialAd?>();
    AdManagerInterstitialAd.load(
      adUnitId: id,
      request: const AdManagerAdRequest(),
      adLoadCallback: AdManagerInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (e) {
          debugPrint('Interstitial AdX failed ($id): ${e.message}');
          _lastError = e.message;
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future.timeout(const Duration(seconds: 8), onTimeout: () {
      if (!completer.isCompleted) completer.complete(null);
      return null;
    });
  }

  Future<bool> showInterstitial() async {
    if (!_slotOn(AdSlot.interstitial)) return false;
    if (_showingFullscreen) return false;
    await preloadInterstitial();
    final admobAd = _interstitialAd;
    final adxAd = _interstitialAdManager;
    if (admobAd == null && adxAd == null) return false;
    final completer = Completer<bool>();
    _interstitialAd = null;
    _interstitialAdManager = null;
    _showingFullscreen = true;
    void onDismissed() {
      if (!completer.isCompleted) completer.complete(true);
    }

    void onFailed(String message) {
      _lastError = message;
      if (!completer.isCompleted) completer.complete(false);
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
    final shown = await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        debugPrint('Interstitial show timed out');
        return false;
      },
    );
    _showingFullscreen = false;
    unawaited(preloadInterstitial());
    return shown;
  }

  Future<BannerHandle?> loadBanner(AdSize size, {bool fallback = false}) async {
    if (!_slotOn(AdSlot.banner) && !fallback) return null;
    if (fallback && !(_config?.shouldShowSdkAds ?? true)) return null;
    return _tryWaterfall<BannerHandle>(
      AdSlot.banner,
      (id, source) => _loadBannerUnit(id, source, size),
    );
  }

  Future<BannerHandle?> _loadBannerUnit(
    String id,
    AdProviderSource source,
    AdSize size,
  ) {
    final completer = Completer<BannerHandle?>();
    if (source == AdProviderSource.adx) {
      AdManagerBannerAd(
        adUnitId: id,
        sizes: [size],
        request: const AdManagerAdRequest(),
        listener: AdManagerBannerAdListener(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) {
              completer.complete(
                BannerHandle(ad: ad as AdWithView, source: AdProviderSource.adx),
              );
            }
          },
          onAdFailedToLoad: (ad, e) {
            debugPrint('Banner AdX failed ($id): ${e.message}');
            ad.dispose();
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      ).load();
    } else {
      BannerAd(
        adUnitId: id,
        request: const AdRequest(),
        size: size,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) {
              completer.complete(
                BannerHandle(ad: ad as AdWithView, source: AdProviderSource.admob),
              );
            }
          },
          onAdFailedToLoad: (ad, e) {
            debugPrint('Banner AdMob failed ($id): ${e.message}');
            ad.dispose();
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      ).load();
    }
    return completer.future.timeout(const Duration(seconds: 8), onTimeout: () {
      if (!completer.isCompleted) completer.complete(null);
      return null;
    });
  }

  Future<void> preloadAppOpen() async {
    if (!_slotOn(AdSlot.appOpen)) return;
    if (_appOpenAd != null) return;
    if (_appOpenLoadFuture != null) {
      await _appOpenLoadFuture;
      return;
    }
    _appOpenLoadFuture = () async {
      _loadingAppOpen = true;
      final ad = await _tryWaterfall<AppOpenAd>(AdSlot.appOpen, _loadAppOpen);
      _appOpenAd = ad;
      if (ad != null) {
        _appOpenSource = ad.adUnitId.startsWith('/')
            ? AdProviderSource.adx
            : AdProviderSource.admob;
      }
      _loadingAppOpen = false;
      debugPrint('AppOpen ready=${ad != null} source=$_appOpenSource');
    }();
    try {
      await _appOpenLoadFuture;
    } finally {
      _appOpenLoadFuture = null;
    }
  }

  Future<AppOpenAd?> _loadAppOpen(String id, AdProviderSource source) {
    final completer = Completer<AppOpenAd?>();
    final callback = AppOpenAdLoadCallback(
      onAdLoaded: (ad) {
        if (!completer.isCompleted) completer.complete(ad);
      },
      onAdFailedToLoad: (e) {
        debugPrint('AppOpen failed ($id): ${e.message}');
        _lastError = e.message;
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    if (source == AdProviderSource.adx) {
      AppOpenAd.loadWithAdManagerAdRequest(
        adUnitId: id,
        adManagerAdRequest: const AdManagerAdRequest(),
        adLoadCallback: callback,
      );
    } else {
      AppOpenAd.load(
        adUnitId: id,
        request: const AdRequest(),
        adLoadCallback: callback,
      );
    }
    return completer.future.timeout(const Duration(seconds: 8), onTimeout: () {
      if (!completer.isCompleted) completer.complete(null);
      return null;
    });
  }

  Future<bool> showAppOpen() async {
    if (!_slotOn(AdSlot.appOpen)) return false;
    if (_showingFullscreen) return false;
    await preloadAppOpen();
    final ad = _appOpenAd;
    if (ad == null) return false;
    final completer = Completer<bool>();
    _appOpenAd = null;
    _showingFullscreen = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _lastError = e.message;
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    try {
      ad.show();
    } catch (e) {
      debugPrint('AppOpen show threw: $e');
      ad.dispose();
      _showingFullscreen = false;
      unawaited(preloadAppOpen());
      return false;
    }
    final shown = await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        debugPrint('AppOpen show timed out');
        return false;
      },
    );
    _showingFullscreen = false;
    unawaited(preloadAppOpen());
    return shown;
  }

  Future<NativeAd?> _loadNativeUnit(
    String id,
    AdProviderSource source, {
    required bool useTemplate,
    String factoryId = nativeFactoryId,
  }) {
    final completer = Completer<NativeAd?>();
    final style = useTemplate
        ? NativeTemplateStyle(
            templateType: TemplateType.medium,
            mainBackgroundColor: const Color(0xFF18181C),
            cornerRadius: 16,
            callToActionTextStyle: NativeTemplateTextStyle(
              textColor: Colors.white,
              backgroundColor: const Color(0xFF9945FF),
              style: NativeTemplateFontStyle.bold,
              size: 14.0,
            ),
            primaryTextStyle: NativeTemplateTextStyle(
              textColor: Colors.white,
              style: NativeTemplateFontStyle.bold,
              size: 16.0,
            ),
            secondaryTextStyle: NativeTemplateTextStyle(
              textColor: const Color(0xFFA1A1AA),
              size: 12.0,
            ),
            tertiaryTextStyle: NativeTemplateTextStyle(
              textColor: const Color(0xFFA1A1AA),
              size: 12.0,
            ),
          )
        : null;
    final listener = NativeAdListener(
      onAdLoaded: (loaded) {
        debugPrint('Native loaded ($id, ${source.name}, template=$useTemplate)');
        final native = loaded as NativeAd;
        if (!completer.isCompleted) {
          completer.complete(native);
        } else {
          native.dispose();
        }
      },
      onAdFailedToLoad: (failed, e) {
        debugPrint('Native failed ($id, ${source.name}): ${e.message}');
        _lastError = e.message;
        failed.dispose();
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    if (source == AdProviderSource.adx) {
      NativeAd.fromAdManagerRequest(
        adUnitId: id,
        factoryId: useTemplate ? null : factoryId,
        listener: listener,
        adManagerRequest: const AdManagerAdRequest(),
        nativeTemplateStyle: style,
      ).load();
    } else {
      NativeAd(
        adUnitId: id,
        factoryId: useTemplate ? null : factoryId,
        request: const AdRequest(),
        listener: listener,
        nativeTemplateStyle: style,
      ).load();
    }
    return completer.future.timeout(const Duration(seconds: 6), onTimeout: () {
      if (!completer.isCompleted) completer.complete(null);
      return null;
    });
  }

  Future<NativeAd?> loadNative({String factoryId = nativeFactoryId}) async {
    if (!_slotOn(AdSlot.native)) return null;
    return _tryWaterfall<NativeAd>(AdSlot.native, (id, source) async {
      var ad = await _loadNativeUnit(id, source, useTemplate: true);
      ad ??= await _loadNativeUnit(
        id,
        source,
        useTemplate: false,
        factoryId: factoryId,
      );
      return ad;
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _interstitialAdManager?.dispose();
    _appOpenAd?.dispose();
    for (final ad in _nativePool) {
      ad.dispose();
    }
    for (final banner in _bannerPool) {
      banner.dispose();
    }
    _nativePool.clear();
    _bannerPool.clear();
    super.dispose();
  }
}
