import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/smart_ad_manager.dart';
import 'google_test_ad.dart';

class _D {
  static const surface = Color(0xFF18181C);
  static const gold = Color(0xFF9945FF);
  static const goldText = Color(0xFFE9D5FF);
  static const goldBg = Color(0xFF1A1228);
  static const goldBdr = Color(0x669945FF);
  static const textHi = Color(0xFFF4F4F5);
  static const textMid = Color(0xFFA1A1AA);
  static const textLow = Color(0xFF71717A);
  static const line = Color(0x1FFFFFFF);
}

TextStyle _sg({
  double size = 13,
  FontWeight weight = FontWeight.w500,
  Color color = _D.textHi,
  double? spacing,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: 1.1,
    );

class MinimizableNativeAd extends StatefulWidget {
  final String title;
  final bool bannerFallback;
  const MinimizableNativeAd({
    super.key,
    this.title = 'Sponsored',
    this.bannerFallback = true,
  });

  @override
  State<MinimizableNativeAd> createState() => _MinimizableNativeAdState();
}

class _MinimizableNativeAdState extends State<MinimizableNativeAd>
    with SingleTickerProviderStateMixin {
  bool _minimized = false;
  bool _loading = true;
  bool _loadStarted = false;
  NativeAd? _nativeAd;

  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    if (!TickerMode.of(context)) return;
    _loadStarted = true;
    _load();
  }

  Future<void> _load({int attempt = 0}) async {
    final cfg = context.read<AdRemoteConfigService>();
    final game = context.read<GameStateService>();
    if (game.isPremiumActive || !cfg.nativeEnabled) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final manager = context.read<SmartAdManager>();
    final native = await manager.takeNative(factoryId: SmartAdManager.nativeFactoryId);
    if (!mounted) {
      native?.dispose();
      return;
    }
    if (native == null && attempt < 1) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      if (!TickerMode.of(context)) {
        _loadStarted = false;
        return;
      }
      await _load(attempt: attempt + 1);
      return;
    }
    setState(() {
      _nativeAd = native;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _expand.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _minimized = !_minimized);
    _minimized ? _expand.reverse() : _expand.forward();
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<GameStateService>().isPremiumActive;
    final cfg = context.watch<AdRemoteConfigService>();
    if (premium || !cfg.shouldShowSdkAds) return const SizedBox.shrink();
    if (_nativeAd == null) {
      if (widget.bannerFallback) {
        return const Center(child: GoogleTestBanner(large: true));
      }
      if (!_loading) return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _D.line, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: _D.goldBg,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: _D.goldBdr),
                      ),
                      child: Text('AD', style: _sg(size: 9, weight: FontWeight.w800, color: _D.goldText, spacing: 0.8)),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sg(size: 13, weight: FontWeight.w600, color: _D.textMid),
                      ),
                    ),
                    GestureDetector(
                      onTap: _loading ? null : _toggle,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: _loading ? 0.4 : 1,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: _D.line),
                          ),
                          child: AnimatedRotation(
                            turns: _minimized ? 0.5 : 0,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: const Icon(Icons.keyboard_arrow_up_rounded, color: _D.textHi, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 0.8, color: _D.line),
              if (_loading)
                const _LoadingPlaceholder()
              else if (!_minimized)
                SizedBox(
                  width: double.infinity,
                  height: 320,
                  child: Material(
                    color: _D.surface,
                    child: AdWidget(key: ObjectKey(_nativeAd), ad: _nativeAd!),
                  ),
                ),
            ],
          ),
    );
  }
}

class _LoadingPlaceholder extends StatefulWidget {
  const _LoadingPlaceholder();

  @override
  State<_LoadingPlaceholder> createState() => _LoadingPlaceholderState();
}

class _LoadingPlaceholderState extends State<_LoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        width: double.infinity,
        height: 78,
        color: Color.lerp(_D.surface, const Color(0xFF222228), _shimmer.value * 0.45),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: _D.gold.withValues(alpha: 0.45 + _shimmer.value * 0.4),
              ),
            ),
            const SizedBox(width: 9),
            Text('Loading offer', style: _sg(size: 12, color: _D.textLow)),
          ],
        ),
      ),
    );
  }
}