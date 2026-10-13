import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/smart_ad_manager.dart';

/// Loads one in-feed ad for the visible screen only:
/// native from the splash pool if ready, otherwise a banner.
class ScreenAdSlot extends StatefulWidget {
  const ScreenAdSlot({
    super.key,
    this.title = 'Sponsored',
    this.bannerFallback = true,
    this.allowNative = true,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final bool bannerFallback;
  final bool allowNative;
  final EdgeInsetsGeometry padding;

  @override
  State<ScreenAdSlot> createState() => _ScreenAdSlotState();
}

class _ScreenAdSlotState extends State<ScreenAdSlot> {
  NativeAd? _native;
  BannerHandle? _banner;
  bool _started = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    if (!TickerMode.of(context)) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final cfg = context.read<AdRemoteConfigService>();
    final game = context.read<GameStateService>();
    final ads = context.read<SmartAdManager>();
    if (game.isPremiumActive ||
        !cfg.shouldShowSdkAds ||
        defaultTargetPlatform != TargetPlatform.android) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    if (widget.allowNative && cfg.nativeEnabled) {
      final pooled = ads.takeNativeIfReady();
      if (pooled != null && mounted) {
        setState(() => _native = pooled);
        return;
      }
    }

    if (cfg.bannerEnabled || widget.bannerFallback) {
      final pooledBanner = ads.takeBannerIfReady();
      if (pooledBanner != null && mounted) {
        setState(() => _banner = pooledBanner);
        return;
      }
      final banner = await ads.loadBanner(
        AdSize.banner,
        fallback: widget.bannerFallback,
      );
      if (!mounted) {
        banner?.dispose();
        return;
      }
      if (banner != null) {
        setState(() => _banner = banner);
        return;
      }
    }

    if (mounted) setState(() => _failed = true);
  }

  @override
  void dispose() {
    _native?.dispose();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<GameStateService>().isPremiumActive;
    final cfg = context.watch<AdRemoteConfigService>();
    if (premium ||
        !cfg.shouldShowSdkAds ||
        _failed ||
        defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    Widget child;
    if (_native != null) {
      child = SizedBox(
        width: double.infinity,
        height: 320,
        child: Material(
          color: const Color(0xFF18181C),
          child: AdWidget(ad: _native!),
        ),
      );
    } else if (_banner != null) {
      child = Material(
        color: const Color(0xFF18181C),
        child: SizedBox(
          width: 320,
          height: 50,
          child: AdWidget(ad: _banner!.ad),
        ),
      );
    } else if (!_started) {
      return const SizedBox.shrink();
    } else {
      child = const SizedBox(width: 320, height: 50);
    }

    return Padding(
      padding: widget.padding,
      child: Center(child: RepaintBoundary(child: child)),
    );
  }
}
