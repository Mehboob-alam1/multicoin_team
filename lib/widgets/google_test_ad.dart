import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/smart_ad_manager.dart';

/// In-feed banner using the AdMob → AdX → test waterfall.
class GoogleTestBanner extends StatefulWidget {
  const GoogleTestBanner({super.key, this.large = false});

  final bool large;

  @override
  State<GoogleTestBanner> createState() => _GoogleTestBannerState();
}

class _GoogleTestBannerState extends State<GoogleTestBanner> {
  BannerHandle? _handle;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    if (!TickerMode.of(context)) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (!mounted) return;
    final cfg = context.read<AdRemoteConfigService>();
    if (!cfg.shouldShowSdkAds ||
        defaultTargetPlatform != TargetPlatform.android) {
      setState(() => _failed = true);
      return;
    }
    final size = widget.large ? AdSize.mediumRectangle : AdSize.banner;
    final ads = context.read<SmartAdManager>();
    final handle = ads.takeBannerIfReady() ??
        await ads.loadBanner(size, fallback: true);
    if (!mounted) {
      handle?.dispose();
      return;
    }
    if (handle == null) {
      setState(() => _failed = true);
      return;
    }
    setState(() => _handle = handle);
  }

  @override
  void dispose() {
    _handle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<GameStateService>().isPremiumActive;
    final cfg = context.watch<AdRemoteConfigService>();
    if (premium || !cfg.shouldShowSdkAds || _failed) {
      return const SizedBox.shrink();
    }
    final w = widget.large ? 300.0 : 320.0;
    final h = widget.large ? 250.0 : 50.0;
    final handle = _handle;
    if (handle == null) return SizedBox(width: w, height: h);
    return SizedBox(
      width: w,
      height: h,
      child: AdWidget(ad: handle.ad),
    );
  }
}
