import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';

/// 320x50 AdMob banner from Remote Config `banner_ad_unit`.
class RemoteConfigBanner extends StatefulWidget {
  const RemoteConfigBanner({super.key});

  static const double height = 50;
  static const _testId = 'ca-app-pub-3940256099942544/6300978111';

  @override
  State<RemoteConfigBanner> createState() => _RemoteConfigBannerState();
}

class _RemoteConfigBannerState extends State<RemoteConfigBanner> {
  BannerAd? _ad;
  bool _ready = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  void _load({bool useTest = false}) {
    if (!mounted) return;
    final cfg = context.read<AdRemoteConfigService>();
    final game = context.read<GameStateService>();
    if (game.isPremiumActive || !cfg.shouldShowSdkAds) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    var id = useTest ? RemoteConfigBanner._testId : cfg.bannerAdmobId.trim();
    if (!id.startsWith('ca-app-pub-')) id = RemoteConfigBanner._testId;
    debugPrint('AdMob banner requesting $id');

    _ad?.dispose();
    final ad = BannerAd(
      adUnitId: id,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          debugPrint('AdMob banner loaded $id');
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() {
            _ad = loaded as BannerAd;
            _ready = true;
          });
        },
        onAdFailedToLoad: (failed, error) {
          debugPrint('AdMob banner failed ($id): ${error.message} (${error.code})');
          failed.dispose();
          if (_ad == failed) _ad = null;
          if (!mounted) return;
          if (!useTest && id != RemoteConfigBanner._testId) {
            _load(useTest: true);
            return;
          }
          setState(() => _ready = false);
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<GameStateService>().isPremiumActive;
    final cfg = context.watch<AdRemoteConfigService>();
    if (premium || !cfg.shouldShowSdkAds) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFF111114),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          width: double.infinity,
          height: RemoteConfigBanner.height,
          child: Center(
            child: _ready && _ad != null
                ? SizedBox(
                    width: 320,
                    height: 50,
                    child: AdWidget(ad: _ad!),
                  )
                : const SizedBox(width: 320, height: 50),
          ),
        ),
      ),
    );
  }
}
