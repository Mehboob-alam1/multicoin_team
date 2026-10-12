import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/smart_ad_manager.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const card     = Color(0xFF16161F);
  static const cardBord = Color(0xFF27272A);
  static const textLow  = Color(0xFF71717A);
}

class SmartBannerAd extends StatefulWidget {
  const SmartBannerAd({super.key});

  @override
  State<SmartBannerAd> createState() => _SmartBannerAdState();
}

class _SmartBannerAdState extends State<SmartBannerAd>
    with SingleTickerProviderStateMixin {
  BannerHandle? _handle;
  bool _loading = true;
  bool _loadStarted = false;

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted || !TickerMode.of(context)) return;
    _loadStarted = true;
    _load();
  }

  Future<void> _load() async {
    final cfg = context.read<AdRemoteConfigService>();
    final game = context.read<GameStateService>();
    if (game.isPremiumActive || !cfg.bannerEnabled) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final h = await context.read<SmartAdManager>().loadBanner(AdSize.banner);
    if (!mounted) {
      h?.dispose();
      return;
    }
    setState(() {
      _handle = h;
      _loading = false;
    });
    if (h != null) _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _handle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<GameStateService>().isPremiumActive;
    final cfg = context.watch<AdRemoteConfigService>();
    if (premium || !cfg.bannerEnabled) return const SizedBox.shrink();
    // Still loading — show slim shimmer placeholder
    if (_loading) return _BannerShimmer();

    // No ad available
    final h = _handle;
    if (h == null) return const SizedBox.shrink();

    // Ad ready — fade in
    return SizedBox(
      width: 320,
      height: 50,
      child: AdWidget(ad: h.ad),
    );
  }
}

// ─── Shimmer placeholder ──────────────────────────────────────────────────────
class _BannerShimmer extends StatefulWidget {
  @override
  State<_BannerShimmer> createState() => _BannerShimmerState();
}

class _BannerShimmerState extends State<_BannerShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 320,
      height: 50,
      decoration: BoxDecoration(
        color: Color.lerp(_D.card, _D.cardBord, _c.value * 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D.cardBord),
      ),
    ),
  );
}