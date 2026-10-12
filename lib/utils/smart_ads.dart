import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ad_pacing_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/smart_ad_manager.dart';

class AdRouteObserver extends NavigatorObserver {
  AdRouteObserver(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _onScreen(route, isFirst: previousRoute == null);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _onScreen(newRoute, isFirst: false);
  }

  void _onScreen(Route<dynamic> route, {required bool isFirst}) {
    if (route is! PageRoute) return;
    final name = route.settings.name;
    if (isFirst ||
        name == '/' ||
        name == '/privacy' ||
        name == '/terms' ||
        name == '/premium-offer') {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      await SmartAds.maybeInterstitial(ctx);
    });
  }
}

class SmartAds {
  SmartAds._();

  static DateTime? _lastFullscreenAt;
  static bool _interstitialInFlight = false;
  static bool _appOpenInFlight = false;

  static void markLaunchAppOpenPending() {}

  static bool _allowed(BuildContext context, {required bool slot}) {
    try {
      if (context.read<GameStateService>().isPremiumActive) return false;
    } catch (_) {}
    return slot;
  }

  static bool _tooSoon({Duration gap = const Duration(seconds: 8)}) {
    final last = _lastFullscreenAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < gap;
  }

  static Future<void> maybeInterstitial(BuildContext context) async {
    if (!context.mounted) return;
    final cfg = context.read<AdRemoteConfigService>();
    if (!_allowed(context, slot: cfg.interstitialEnabled)) return;
    if (_interstitialInFlight || _appOpenInFlight) return;
    if (_tooSoon()) return;
    final ads = context.read<SmartAdManager>();
    if (ads.showingFullscreen) return;

    AdPacingService? pacing;
    try {
      pacing = context.read<AdPacingService>();
    } catch (_) {}
    if (pacing != null) {
      await pacing.registerNavigationTransition();
      if (!context.mounted) return;
      final sessions = context.read<GameStateService>().totalSessionsStarted;
      if (!await pacing.shouldShowInterstitial(completedSessions: sessions)) {
        return;
      }
    }

    if (!ads.interstitialReady) {
      unawaited(ads.preloadInterstitial());
      return;
    }

    _interstitialInFlight = true;
    try {
      final shown = await ads.showInterstitial();
      debugPrint('SmartAds interstitial shown=$shown error=${ads.lastError}');
      if (shown) {
        _lastFullscreenAt = DateTime.now();
        await pacing?.markInterstitialShown();
      }
    } catch (e) {
      debugPrint('SmartAds interstitial: $e');
    } finally {
      _interstitialInFlight = false;
    }
  }

  static Future<void> maybeAppOpen(BuildContext context) async {
    if (_appOpenInFlight || !context.mounted) return;
    final cfg = context.read<AdRemoteConfigService>();
    if (!_allowed(context, slot: cfg.appOpenEnabled)) return;
    if (_interstitialInFlight) return;
    if (_tooSoon()) return;
    final ads = context.read<SmartAdManager>();
    if (ads.showingFullscreen) return;

    AdPacingService? pacing;
    try {
      pacing = context.read<AdPacingService>();
    } catch (_) {}
    if (pacing != null && context.mounted) {
      final sessions = context.read<GameStateService>().totalSessionsStarted;
      if (!await pacing.canShowAppOpen(completedSessions: sessions)) return;
    }

    _appOpenInFlight = true;
    try {
      final shown = await ads.showAppOpen();
      debugPrint('SmartAds appOpen shown=$shown error=${ads.lastError}');
      if (shown) {
        _lastFullscreenAt = DateTime.now();
        await pacing?.markAppOpenShown();
      }
    } catch (e) {
      debugPrint('SmartAds appOpen: $e');
    } finally {
      _appOpenInFlight = false;
    }
  }
}
