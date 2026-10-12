import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

/// Remote Config ads (Android):
/// - `ads_enabled` master switch for every ad
/// - `ads_interstitial_enabled`, `ads_app_open_enabled`, `ads_native_enabled`,
///   `ads_banner_enabled`, `ads_rewarded_enabled` per slot
/// Ad unit IDs also come from Remote Config.
class AdRemoteConfigService extends ChangeNotifier {
  static const _adsEnabled = 'ads_enabled';
  static const _interstitialEnabled = 'ads_interstitial_enabled';
  static const _appOpenEnabled = 'ads_app_open_enabled';
  static const _nativeEnabled = 'ads_native_enabled';
  static const _bannerEnabled = 'ads_banner_enabled';
  static const _rewardedEnabled = 'ads_rewarded_enabled';
  static const _useCustomTab = 'use_custom_tab';
  static const _customTabUrl = 'custom_tab_url';
  static const _interstitialAdUnit = 'interstitial_ad_unit';
  static const _interstitialAdmanagerUnit = 'interstitial_admanager_unit';
  static const _rewardedAdUnit = 'rewarded_ad_unit';
  static const _rewardedAdmanagerUnit = 'rewarded_admanager_unit';
  static const _nativeAdUnit = 'native_ad_unit';
  static const _nativeAdmanagerUnit = 'native_admanager_unit';
  static const _admobAppOpenAndroid = 'admob_app_open_android';
  static const _admanagerAppOpen = 'admanager_app_open';
  static const _bannerAdUnit = 'banner_ad_unit';
  static const _bannerAdmanagerUnit = 'banner_admanager_unit';
  static const _facebookAppId = 'facebook_app_id';
  static const _facebookClientToken = 'facebook_client_token';
  static const _eventMiningMultiplier = 'event_mining_multiplier';
  static const _eventRigDiscount = 'event_rig_discount';
  static const _first24hBundleDiscountPercent = 'first_24h_bundle_discount_percent';

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Master switch. Defaults ON. Firebase BOOLEAN keys are created as `false`,
  /// which used to turn every ad off after fetch — that is treated as
  /// "uninitialized" unless a slot is explicitly true or units were customized.
  bool get adsEnabled {
    final master = _getBool(_adsEnabled);
    if (master) return true;
    if (_uninitializedAdFlags) return true;
    return false;
  }

  bool get interstitialEnabled =>
      adsEnabled && (_uninitializedAdFlags || _getBool(_interstitialEnabled));
  bool get appOpenEnabled =>
      adsEnabled && (_uninitializedAdFlags || _getBool(_appOpenEnabled));
  bool get nativeEnabled =>
      adsEnabled && (_uninitializedAdFlags || _getBool(_nativeEnabled));
  bool get bannerEnabled =>
      adsEnabled && (_uninitializedAdFlags || _getBool(_bannerEnabled));
  bool get rewardedEnabled =>
      adsEnabled && (_uninitializedAdFlags || _getBool(_rewardedEnabled));

  bool get _uninitializedAdFlags {
    final anySlotOn = _getBool(_interstitialEnabled) ||
        _getBool(_appOpenEnabled) ||
        _getBool(_nativeEnabled) ||
        _getBool(_bannerEnabled) ||
        _getBool(_rewardedEnabled);
    if (anySlotOn) return false;
    return bannerAdmobId == 'ca-app-pub-3940256099942544/6300978111';
  }
  /// When true, open [customTabUrl] in Chrome Custom Tabs instead of showing any ad.
  bool get useCustomTab => _getBool(_useCustomTab);
  /// URL used when [useCustomTab] is true.
  String get customTabUrl => _getString(_customTabUrl);

  bool _getBool(String key) {
    final def = defaultParameters[key];
    final fallback = def is bool ? def : def == 'true' || key != _useCustomTab;
    try {
      if (!_loaded) return fallback;
      final value = _remoteConfig.getValue(key);
      final s = value.asString().trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes' || s == 'on') return true;
      if (s == 'false' || s == '0' || s == 'no' || s == 'off') {
        if (value.source == ValueSource.valueRemote) return false;
        return fallback;
      }
      if (s.isEmpty) return fallback;
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  String _getString(String key) {
    try {
      if (!_loaded) {
        final def = defaultParameters[key];
        if (def is String) return def.trim();
        return '';
      }
      final s = _remoteConfig.getString(key);
      return (s ?? '').trim();
    } catch (_) {
      final def = defaultParameters[key];
      if (def is String) return def.trim();
      return '';
    }
  }

  /// Ad unit IDs from Remote Config (empty = use test ID in SmartAdManager).
  String get interstitialAdmobId => _getString(_interstitialAdUnit);
  String get interstitialAdxId => _getString(_interstitialAdmanagerUnit);
  String get rewardedAdmobId => _getString(_rewardedAdUnit);
  String get rewardedAdxId => _getString(_rewardedAdmanagerUnit);
  String get nativeAdmobId => _getString(_nativeAdUnit);
  String get nativeAdxId => _getString(_nativeAdmanagerUnit);
  String get appOpenAdmobId => _getString(_admobAppOpenAndroid);
  String get appOpenAdxId => _getString(_admanagerAppOpen);
  String get bannerAdmobId => _getString(_bannerAdUnit);
  String get bannerAdxId => _getString(_bannerAdmanagerUnit);

  /// Facebook App ID for Meta (Facebook) analytics / marketing. Set in Remote Config.
  String get facebookAppId => _getString(_facebookAppId);
  /// Facebook Client Token for Meta SDK. Set in Remote Config.
  String get facebookClientToken => _getString(_facebookClientToken);
  /// True when both Facebook credentials are set (Meta events will be sent).
  bool get hasMetaCredentials =>
      facebookAppId.trim().isNotEmpty && facebookClientToken.trim().isNotEmpty;

  double get eventMiningMultiplier {
    final s = _getString(_eventMiningMultiplier);
    return double.tryParse(s) ?? 1.0;
  }
  double get eventRigDiscount {
    final s = _getString(_eventRigDiscount);
    return double.tryParse(s) ?? 0.0;
  }
  int get first24hBundleDiscountPercent {
    final s = _getString(_first24hBundleDiscountPercent);
    return int.tryParse(s) ?? 0;
  }

  static Map<String, Object> get defaultParameters => {
        _adsEnabled: true,
        _interstitialEnabled: true,
        _appOpenEnabled: true,
        _nativeEnabled: true,
        _bannerEnabled: true,
        _rewardedEnabled: true,
        _useCustomTab: false,
        _customTabUrl: '',
        _interstitialAdUnit: 'ca-app-pub-3940256099942544/1033173712',
        _interstitialAdmanagerUnit: 'ca-app-pub-3940256099942544/1033173712',
        _rewardedAdUnit: 'ca-app-pub-3940256099942544/5224354917',
        _rewardedAdmanagerUnit: 'ca-app-pub-3940256099942544/5224354917',
        _nativeAdUnit: 'ca-app-pub-3940256099942544/2247696110',
        _nativeAdmanagerUnit: 'ca-app-pub-3940256099942544/2247696110',
        _admobAppOpenAndroid: 'ca-app-pub-3940256099942544/9257395921',
        _admanagerAppOpen: 'ca-app-pub-3940256099942544/9257395921',
        _bannerAdUnit: 'ca-app-pub-3940256099942544/6300978111',
        _bannerAdmanagerUnit: '/21775744923/example/adaptive-banner',
        _facebookAppId: '',
        _facebookClientToken: '',
        _eventMiningMultiplier: '1.0',
        _eventRigDiscount: '0.0',
        _first24hBundleDiscountPercent: '0',
      };

  Future<void> load() async {
    try {
      await _remoteConfig.setDefaults(defaultParameters);
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 6),
      ));
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('AdRemoteConfigService load error: $e');
    }
    _loaded = true;
    debugPrint(
      'Ads RC raw enabled=${_getBool(_adsEnabled)} '
      'inter=${_getBool(_interstitialEnabled)} open=${_getBool(_appOpenEnabled)} '
      'native=${_getBool(_nativeEnabled)} banner=${_getBool(_bannerEnabled)} '
      'rewarded=${_getBool(_rewardedEnabled)} uninitialized=$_uninitializedAdFlags',
    );
    debugPrint(
      'Ads RC using adsEnabled=$adsEnabled interstitial=$interstitialEnabled '
      'appOpen=$appOpenEnabled native=$nativeEnabled banner=$bannerEnabled '
      'rewarded=$rewardedEnabled bannerId=$bannerAdmobId',
    );
    notifyListeners();
  }

  Future<bool> openCustomTab(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    try {
      await launchUrl(
        uri,
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: const Color(0xFF1E1E1E),
          ),
          shareState: CustomTabsShareState.on,
        ),
        safariVCOptions: SafariViewControllerOptions(
          preferredBarTintColor: const Color(0xFF1E1E1E),
          preferredControlTintColor: const Color(0xFFFFFFFF),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('AdRemoteConfigService openCustomTab error: $e');
      return false;
    }
  }

  /// Whether to show anything (ad or custom tab) for any slot.
  bool get adsActive => adsEnabled && (canShowWebsiteRedirect || shouldShowSdkAds);

  /// True when website redirect is enabled and URL is a real destination.
  bool get canShowWebsiteRedirect {
    if (!useCustomTab) return false;
    final url = customTabUrl.trim();
    if (url.isEmpty) return false;
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.isNotEmpty && host != 'example.com' && host != 'www.example.com';
  }

  /// True when the master switch is on. Per-slot flags still apply.
  bool get shouldShowSdkAds => adsEnabled;
}
