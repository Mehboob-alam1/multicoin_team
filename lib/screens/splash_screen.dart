import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_product.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    final auth = context.read<AuthService>();
    final game = context.read<GameStateService>();
    final iap = context.read<IapService>();

    final analytics = context.read<AnalyticsService>();
    iap.onPurchaseSuccess = (delivery) {
      final p = ShopProducts.oneTimeById(delivery.productId);
      final plan = ShopProducts.planById(delivery.productId);
      final amountStr = p?.price ?? plan?.price ?? '';
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

    final user = auth.currentUser;
    if (user != null) {
      game.setUserId(user.uid);
      game.setDisplayName(user.displayName ?? user.email ?? 'Miner');
      try {
        await game.load();
      } catch (_) {}
    }

    final elapsed = DateTime.now().difference(started);
    const minShow = Duration(milliseconds: 1700);
    if (elapsed < minShow) {
      await Future.delayed(minShow - elapsed);
    }
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
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _Glow(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), size: 340),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: _Glow(color: const Color(0xFFA855F7).withValues(alpha: 0.10), size: 300),
          ),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulse, _spin]),
              builder: (_, __) {
                final scale = 0.92 + (_pulse.value * 0.08);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: _spin.value * math.pi * 2 * 0.04,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.currency_bitcoin_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'CRYPTO MINING TYCOON',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 2.4,
                        color: Color(0xFF0D0F12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Warming up your farm…',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: const Color(0xFF6B7280).withValues(alpha: 0.95),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
