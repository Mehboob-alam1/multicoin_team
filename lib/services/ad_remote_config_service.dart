import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

/// Remote Config: one boolean to enable/disable all ads, one URL for custom tab.
/// Ad unit IDs come from Remote Config (same keys as in your Firebase template).
class AdRemoteConfigService extends ChangeNotifier {
  static const _adsEnabled = 'ads_enabled';
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

  /// Single boolean: when false, no ads and no custom tab.
  bool get adsEnabled => _getBool(_adsEnabled);
  /// When true, open [customTabUrl] in Chrome Custom Tabs instead of showing any ad.
  bool get useCustomTab => _getBool(_useCustomTab);
  /// URL used when [useCustomTab] is true.
  String get customTabUrl => _getString(_customTabUrl);

  bool _getBool(String key) {
    try {
      if (!_loaded) {
        final def = defaultParameters[key];
        if (def is bool) return def;
        return key == _adsEnabled;
      }
      try {
        if (_remoteConfig.getBool(key)) return true;
      } catch (_) {}
      final s = (_remoteConfig.getString(key) ?? '').toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      return false;
    } catch (_) {
      final def = defaultParameters[key];
      if (def is bool) return def;
      return key == _adsEnabled;
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
        _useCustomTab: true,
        _customTabUrl: 'https://example.com',
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
  bool get adsActive => adsEnabled && (useCustomTab ? customTabUrl.isNotEmpty : true);

  /// True when website redirect is enabled and URL is set (so we can show "Open website").
  bool get canShowWebsiteRedirect => useCustomTab && customTabUrl.isNotEmpty;
}
