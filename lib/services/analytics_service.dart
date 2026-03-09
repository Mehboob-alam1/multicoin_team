import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

import 'ad_remote_config_service.dart';

/// Central analytics: Firebase Analytics + Meta (Facebook) App Events.
/// Meta is initialized only when [AdRemoteConfigService] has facebook_app_id and facebook_client_token set.
class AnalyticsService extends ChangeNotifier {
  AnalyticsService(this._remoteConfig);

  final AdRemoteConfigService _remoteConfig;
  final FirebaseAnalytics _firebase = FirebaseAnalytics.instance;
  final FacebookAppEvents _meta = FacebookAppEvents();

  bool _metaInitialized = false;

  FirebaseAnalytics get firebase => _firebase;

  /// Call after Remote Config has been loaded (e.g. after AdRemoteConfigService.load()).
  /// Initializes Meta SDK only when facebook_app_id and facebook_client_token are set in Remote Config.
  Future<void> initFromRemoteConfig() async {
    if (_metaInitialized) return;
    if (!_remoteConfig.hasMetaCredentials) return;
    try {
      await _meta.setAutoLogAppEventsEnabled(true);
      await _meta.activateApp(applicationId: _remoteConfig.facebookAppId);
      _metaInitialized = true;
      debugPrint('AnalyticsService: Meta (Facebook) App Events initialized from Remote Config');
    } catch (e) {
      debugPrint('AnalyticsService: Meta init failed: $e');
    }
  }

  /// Set current screen for Firebase and optional Meta view content.
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _firebase.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (_) {}
    if (_metaInitialized) {
      try {
        await _meta.logViewContent(
          id: screenName,
          type: 'screen',
        );
      } catch (_) {}
    }
  }

  /// User started a mining session.
  Future<void> logSessionStart() async {
    try {
      await _firebase.logEvent(name: 'session_start');
    } catch (_) {}
    if (_metaInitialized) {
      try {
        await _meta.logEvent(name: 'StartSession', parameters: {'content_type': 'mining_session'});
      } catch (_) {}
    }
  }

  /// User completed registration (e.g. Google sign-in).
  Future<void> logCompletedRegistration({String? method}) async {
    try {
      await _firebase.logSignUp(signUpMethod: method ?? 'google');
    } catch (_) {}
    if (_metaInitialized) {
      try {
        await _meta.logCompletedRegistration(registrationMethod: method ?? 'Google');
      } catch (_) {}
    }
  }

  /// In-app purchase (IAP).
  Future<void> logPurchase({
    required double amount,
    required String currency,
    String? productId,
    String? transactionId,
  }) async {
    try {
      final items = productId != null
          ? [AnalyticsEventItem(itemId: productId, itemName: productId, price: amount)]
          : <AnalyticsEventItem>[];
      await _firebase.logPurchase(
        transactionId: transactionId ?? '',
        affiliation: 'btc_sim_iap',
        currency: currency,
        value: amount,
        tax: 0,
        shipping: 0,
        coupon: '',
        items: items,
      );
    } catch (_) {}
    if (_metaInitialized) {
      try {
        await _meta.logPurchase(amount: amount, currency: currency, parameters: {
          if (productId != null) 'content_id': productId,
          if (transactionId != null) 'order_id': transactionId,
        });
      } catch (_) {}
    }
  }

  /// User used the Lucky Spin.
  Future<void> logLuckySpin({String? rewardType}) async {
    try {
      await _firebase.logEvent(
        name: 'lucky_spin',
        parameters: rewardType != null ? {'reward_type': rewardType} : null,
      );
    } catch (_) {}
    if (_metaInitialized) {
      try {
        await _meta.logEvent(
          name: 'LuckySpin',
          parameters: rewardType != null ? {'reward_type': rewardType} : null,
        );
      } catch (_) {}
    }
  }

  /// User watched a rewarded ad.
  Future<void> logRewardedAdWatched({String? placement}) async {
    try {
      await _firebase.logEvent(
        name: 'rewarded_ad_watched',
        parameters: placement != null ? {'placement': placement} : null,
      );
    } catch (_) {}
    if (_metaInitialized) {
      try {
        await _meta.logAdImpression(adType: placement ?? 'rewarded');
      } catch (_) {}
    }
  }

  /// User opened withdrawal screen or requested withdrawal.
  Future<void> logWithdrawalIntent({bool? eligible}) async {
    try {
      await _firebase.logEvent(
        name: 'withdrawal_intent',
        parameters: eligible != null ? {'eligible': eligible} : null,
      );
    } catch (_) {}
    if (_metaInitialized) {
      try {
        await _meta.logEvent(
          name: 'WithdrawalIntent',
          parameters: eligible != null ? {'eligible': eligible} : null,
        );
      } catch (_) {}
    }
  }

  /// Custom event (Firebase + Meta).
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    try {
      await _firebase.logEvent(
        name: name,
        parameters: params?.map((k, v) => MapEntry(k, v.toString())),
      );
    } catch (_) {}
    if (_metaInitialized) {
      try {
        await _meta.logEvent(
          name: name,
          parameters: params?.map((k, v) => MapEntry(k, v)),
        );
      } catch (_) {}
    }
  }

  /// Set user ID for analytics (e.g. after login).
  Future<void> setUserId(String? uid) async {
    try {
      await _firebase.setUserId(id: uid);
    } catch (_) {}
    if (_metaInitialized && uid != null && uid.isNotEmpty) {
      try {
        await _meta.setUserID(uid);
      } catch (_) {}
    }
  }
}
