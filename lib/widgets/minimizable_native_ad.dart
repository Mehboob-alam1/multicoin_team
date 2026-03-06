import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/smart_ad_manager.dart';
import '../theme/app_theme.dart';

/// Medium-size minimizable ad block.
/// - Tries Native ad first (requires platform factoryId setup).
/// - Falls back to medium rectangle banner (300x250) if native is unavailable.
class MinimizableNativeAd extends StatefulWidget {
  final String title;
  const MinimizableNativeAd({super.key, this.title = 'Sponsored'});

  @override
  State<MinimizableNativeAd> createState() => _MinimizableNativeAdState();
}

class _MinimizableNativeAdState extends State<MinimizableNativeAd> {
  bool _minimized = false;
  bool _loading = true;
  NativeAd? _nativeAd;
  BannerHandle? _fallbackBanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final manager = context.read<SmartAdManager>();
    final native = await manager.loadNative(factoryId: 'adFactoryMedium');
    if (!mounted) {
      native?.dispose();
      return;
    }
    if (native != null) {
      setState(() {
        _nativeAd = native;
        _loading = false;
      });
      return;
    }
    final banner = await manager.loadBanner(AdSize.mediumRectangle);
    if (!mounted) {
      banner?.dispose();
      return;
    }
    setState(() {
      _fallbackBanner = banner;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _fallbackBanner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Card(
        child: SizedBox(
          height: 72,
          child: Center(
            child: Text(
              'Loading ad...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
          ),
        ),
      );
    }
    if (_nativeAd == null && _fallbackBanner == null) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppTheme.surfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.campaign, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  tooltip: _minimized ? 'Expand ad' : 'Minimize ad',
                  onPressed: () => setState(() => _minimized = !_minimized),
                  icon: Icon(_minimized ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up),
                ),
              ],
            ),
          ),
          if (!_minimized)
            SizedBox(
              width: 300,
              height: 250,
              child: AdWidget(ad: _nativeAd ?? _fallbackBanner!.ad),
            ),
        ],
      ),
    );
  }
}

