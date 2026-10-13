import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../models/shop_product.dart';
import '../services/ad_pacing_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/background_mining_task.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../services/smart_ad_manager.dart';
import '../utils/smart_ads.dart';
import '../widgets/app_brand_logo.dart';

class _D {
  static const bg = Color(0xFF08080A);
  static const gold = Color(0xFF9945FF);
  static const goldText = Color(0xFFE9D5FF);
  static const goldBdr = Color(0x669945FF);
  static const green = Color(0xFF14F195);
  static const textHi = Color(0xFFF4F4F5);
  static const textMid = Color(0xFFA1A1AA);
}

TextStyle _sg({
  double size = 14,
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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );

  late final Animation<double> _introCurve = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOutCubic,
  );

  late final Animation<double> _introScale = Tween<double>(begin: 0.92, end: 1)
      .animate(_introCurve);

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _boot();
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    final auth = context.read<AuthService>();
    final game = context.read<GameStateService>();
    final iap = context.read<IapService>();
    final analytics = context.read<AnalyticsService>();

    iap.onPurchaseSuccess = (delivery) {
      final product = ShopProducts.oneTimeById(delivery.productId);
      final plan = ShopProducts.planById(delivery.productId);
      final amountStr = product?.price ?? plan?.price ?? '';
      final amount = amountStr.startsWith('\$')
          ? (double.tryParse(amountStr.replaceFirst('\$', '').trim()) ?? 0)
          : 0.0;
      analytics.logPurchase(
        amount: amount,
        currency: 'USD',
        productId: delivery.productId,
        transactionId: delivery.purchaseId ?? '${DateTime.now().millisecondsSinceEpoch}',
      );
      game.fulfillGooglePlayPurchase(delivery);
    };
    iap.init();

    try {
      await Hive.initFlutter();
    } catch (_) {}
    unawaited(startBackgroundMining());

    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds init: $e');
    }

    final adCfg = context.read<AdRemoteConfigService>();
    final ads = context.read<SmartAdManager>();
    final pacing = context.read<AdPacingService>();

    try {
      await adCfg.load().timeout(const Duration(seconds: 3));
    } catch (_) {}
    unawaited(pacing.load());

    final user = auth.currentUser;
    if (user != null) {
      game.setUserId(user.uid);
      game.setDisplayName(auth.displayNameOf(user));
      try {
        await game.load();
      } catch (_) {}
    }

    if (defaultTargetPlatform == TargetPlatform.android &&
        !game.isPremiumActive &&
        adCfg.shouldShowSdkAds) {
      unawaited(ads.preloadAll());
      if (adCfg.appOpenEnabled) {
        try {
          await ads.preloadAppOpen().timeout(const Duration(seconds: 3));
        } catch (_) {}
        if (mounted) await SmartAds.maybeAppOpen(context);
      }
    }

    final elapsed = DateTime.now().difference(started);
    const minimum = Duration(milliseconds: 1200);
    if (elapsed < minimum) await Future.delayed(minimum - elapsed);
    if (!mounted) return;

    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (game.isPremiumActive) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/premium-offer');
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D.bg,
      body: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
          Positioned.fill(
            child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: FadeTransition(
                      opacity: _introCurve,
                      child: ScaleTransition(
                        scale: _introScale,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (_, __) => _LogoSlot(pulse: _pulse.value),
                            ),
                            const SizedBox(height: 34),
                            Text(
                              'SOLANA',
                              textAlign: TextAlign.center,
                              style: _sg(size: 12, weight: FontWeight.w700, color: _D.goldText, spacing: 5.4),
                            ),
                            const SizedBox(height: 8),
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (r) => const LinearGradient(
                                colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(r),
                              child: Text(
                                'Mining Tycoon',
                                textAlign: TextAlign.center,
                                style: _sg(size: 30, weight: FontWeight.w700, spacing: -0.9, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Warming up your validators',
                              textAlign: TextAlign.center,
                              style: _sg(size: 14, color: _D.textMid),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: const Color(0x2DFFFFFF), width: 0.8),
                              ),
                              child: Text(
                                'SYNCING NETWORK',
                                style: _sg(size: 10, weight: FontWeight.w700, color: _D.textMid, spacing: 1.6),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const _LoadingBar(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoSlot extends StatelessWidget {
  final double pulse;

  const _LogoSlot({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.0 + pulse * 0.03,
      child: const AppBrandLogo(size: 168, circular: true),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 132,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(99)),
          child: LinearProgressIndicator(
            minHeight: 4,
            backgroundColor: Colors.transparent,
            color: _D.gold,
          ),
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  const _MeshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void glow(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glow(Offset(size.width * 0.5, size.height * 0.42), 230, const Color(0x389945FF));
    glow(Offset(size.width * 0.22, size.height * 0.78), 170, const Color(0x2414F195));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}