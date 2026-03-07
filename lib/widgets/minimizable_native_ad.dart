import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/smart_ad_manager.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const card     = Color(0xFF121826);
  static const cardBord = Color(0xFF1E2A3A);
  static const gold     = Color(0xFFF5A623);
  static const textMid  = Color(0xFF8899BB);
  static const textLow  = Color(0xFF3D4F6B);
}

/// Medium-size minimizable ad block.
/// - Tries Native ad first (requires platform factoryId setup).
/// - Falls back to medium rectangle banner (300×250) if native is unavailable.
class MinimizableNativeAd extends StatefulWidget {
  final String title;
  const MinimizableNativeAd({super.key, this.title = 'Sponsored'});

  @override
  State<MinimizableNativeAd> createState() => _MinimizableNativeAdState();
}

class _MinimizableNativeAdState extends State<MinimizableNativeAd>
    with SingleTickerProviderStateMixin {
  bool _minimized = false;
  bool _loading   = true;
  NativeAd?      _nativeAd;
  BannerHandle?  _fallbackBanner;

  late final AnimationController _expandCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1.0, // starts expanded
  );
  late final Animation<double> _expandAnim = CurvedAnimation(
    parent: _expandCtrl,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final manager = context.read<SmartAdManager>();
    final native  = await manager.loadNative(factoryId: 'adFactoryMedium');
    if (!mounted) { native?.dispose(); return; }
    if (native != null) {
      setState(() { _nativeAd = native; _loading = false; });
      return;
    }
    final banner = await manager.loadBanner(AdSize.mediumRectangle);
    if (!mounted) { banner?.dispose(); return; }
    setState(() { _fallbackBanner = banner; _loading = false; });
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    _nativeAd?.dispose();
    _fallbackBanner?.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _minimized = !_minimized);
    if (_minimized) {
      _expandCtrl.reverse();
    } else {
      _expandCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to show yet
    if (!_loading && _nativeAd == null && _fallbackBanner == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: _D.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.cardBord),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              // Ad badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _D.textLow.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(
                    color: _D.textLow,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  color: _D.textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Minimize toggle
              GestureDetector(
                onTap: _loading ? null : _toggle,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _D.cardBord,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedRotation(
                    turns: _minimized ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: _D.textMid,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ]),
          ),

          // ── Divider ────────────────────────────────────────────────────────
          Container(height: 1, color: _D.cardBord),

          // ── Ad body (animated collapse) ────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            axisAlignment: -1,
            child: _loading
                ? _LoadingPlaceholder()
                : SizedBox(
              width: 300,
              height: 250,
              child: AdWidget(ad: _nativeAd ?? _fallbackBanner!.ad),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading placeholder ──────────────────────────────────────────────────────
class _LoadingPlaceholder extends StatefulWidget {
  @override
  State<_LoadingPlaceholder> createState() => _LoadingPlaceholderState();
}

class _LoadingPlaceholderState extends State<_LoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() { _shimmer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _shimmer,
    builder: (_, __) => Container(
      width: double.infinity,
      height: 72,
      color: Color.lerp(
        _D.card,
        _D.cardBord,
        _shimmer.value * 0.5,
      ),
      child: Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: _D.textLow.withValues(alpha: 0.5 + 0.5 * _shimmer.value),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Loading…',
            style: TextStyle(color: _D.textLow, fontSize: 11),
          ),
        ]),
      ),
    ),
  );
}