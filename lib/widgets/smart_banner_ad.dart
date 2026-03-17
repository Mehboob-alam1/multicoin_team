import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/smart_ad_manager.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const card     = Color(0xFFFFFFFF);
  static const cardBord = Color(0xFFE2E8F0);
  static const textLow  = Color(0xFF9CA3AF);
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

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final h = await context.read<SmartAdManager>().loadBanner(AdSize.banner);
      if (!mounted) { h?.dispose(); return; }
      setState(() { _handle = h; _loading = false; });
      if (h != null) _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _handle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Still loading — show slim shimmer placeholder
    if (_loading) return _BannerShimmer();

    // No ad available
    final h = _handle;
    if (h == null) return const SizedBox.shrink();

    // Ad ready — fade in
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        width: 320,
        height: 50,
        decoration: BoxDecoration(
          color: _D.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _D.cardBord),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            AdWidget(ad: h.ad),
            // Subtle "AD" label pinned top-right so it's always visible
            Positioned(
              top: 3,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _D.cardBord,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(
                    color: _D.textLow,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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