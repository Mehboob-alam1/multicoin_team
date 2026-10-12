import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_product.dart';
import '../theme/app_theme.dart';
import '../theme/solana.dart';
import '../widgets/solana_widgets.dart';
import '../services/auth_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';

class _D {
  static const bg       = Solana.bg;
  static const card     = Solana.surfaceRaised;
  static const cardBord = Solana.border;
  static const gold     = Solana.purple;
  static const goldDark = Color(0xFF7A2FE0);
  static const purple   = Solana.purple;
  static const textHi   = Solana.textHi;
  static const textMid  = Solana.textMid;
}

class PremiumOfferScreen extends StatefulWidget {
  const PremiumOfferScreen({super.key});

  static const String routeName = '/premium-offer';

  @override
  State<PremiumOfferScreen> createState() => _PremiumOfferScreenState();
}

class _PremiumOfferScreenState extends State<PremiumOfferScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      final game = context.read<GameStateService>();
      final iap = context.read<IapService>();
      final user = auth.currentUser;
      if (user != null) {
        game.setUserId(user.uid);
        game.setDisplayName(user.displayName ?? user.email ?? 'Miner');
        await game.load();
        if (!mounted) return;
        if (game.isPremiumActive) {
          _goHome(context);
          return;
        }
      }
      if (iap.products.isEmpty) iap.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IapService>();
    final yearly = ShopProducts.premiumPlans.firstWhere((p) => p.id == 'premium_yearly');
    final monthly = ShopProducts.premiumPlans.firstWhere((p) => p.id == 'premium_monthly');

    return Scaffold(
      backgroundColor: Solana.bg,
      body: Stack(
        children: [
          const SolanaMeshBackground(intensity: 0.24),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => _goHome(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _D.textMid,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    children: [
                      const Center(
                        child: SolanaMark(
                          size: 84,
                          icon: Icons.workspace_premium_rounded,
                          pulse: 0.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Mine 1.5× faster',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _D.textHi,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTheme.fontFamily,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose a plan to unlock full mining power.\nYou can skip and start for free.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _D.textMid,
                          fontSize: 14,
                          height: 1.4,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ...const [
                        _PerkRow(icon: Icons.speed_rounded, text: '1.5× mining on every rig'),
                        _PerkRow(icon: Icons.block_rounded, text: 'Remove all ads'),
                        _PerkRow(icon: Icons.memory_rounded, text: 'Exclusive premium rigs'),
                        _PerkRow(icon: Icons.verified_rounded, text: 'VIP badge on your profile'),
                      ],
                      const SizedBox(height: 20),
                      _PlanPickCard(
                        plan: yearly,
                        priceStr: iap.getProduct(yearly.googleProductId)?.price ?? yearly.price,
                        featured: true,
                        badge: 'BEST VALUE · SAVE 50%',
                        iapLoading: iap.loading,
                        playReady: iap.isGoogleProductReady(yearly.googleProductId),
                        onSubscribe: () => _subscribe(context, yearly),
                      ),
                      const SizedBox(height: 12),
                      _PlanPickCard(
                        plan: monthly,
                        priceStr: iap.getProduct(monthly.googleProductId)?.price ?? monthly.price,
                        featured: false,
                        badge: null,
                        iapLoading: iap.loading,
                        playReady: iap.isGoogleProductReady(monthly.googleProductId),
                        onSubscribe: () => _subscribe(context, monthly),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _goHome(context),
                        child: const Text(
                          'Continue without a plan',
                          style: TextStyle(
                            color: _D.textMid,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _subscribe(BuildContext context, PremiumPlan plan) async {
    final iap = context.read<IapService>();
    final success = await iap.buySubscription(plan.googleProductId);
    if (!context.mounted) return;
    if (success) {
      _toast(context, 'Complete in Google Play. Premium activates when the purchase finishes.');
    } else {
      _toast(context, iap.error ?? 'Google Play subscription unavailable. Check Play Console IDs.');
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _D.textHi, fontFamily: AppTheme.fontFamily)),
      backgroundColor: _D.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _D.cardBord),
      ),
    ));
  }
}

class _PerkRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PerkRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _D.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _D.goldDark, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _D.textHi,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Solana.green, size: 18),
        ],
      ),
    );
  }
}

class _PlanPickCard extends StatelessWidget {
  final PremiumPlan plan;
  final String priceStr;
  final bool featured;
  final String? badge;
  final bool iapLoading;
  final bool playReady;
  final VoidCallback onSubscribe;

  const _PlanPickCard({
    required this.plan,
    required this.priceStr,
    required this.featured,
    required this.badge,
    required this.iapLoading,
    required this.playReady,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final accent = featured ? _D.gold : _D.purple;
    return SolanaGlassCard(
      glow: featured,
      radius: 20,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: Solana.brandH,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          color: _D.textHi,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.description,
                        style: const TextStyle(
                          color: _D.textMid,
                          fontSize: 12,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  priceStr,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: featured
                      ? Solana.brandH
                      : const LinearGradient(colors: [Solana.purple, Color(0xFF7A2FE0)]),
                ),
                child: TextButton(
                  onPressed: (iapLoading || !playReady) ? null : onSubscribe,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    iapLoading
                        ? 'Loading Google Play…'
                        : !playReady
                        ? 'Unavailable in Play'
                        : (featured ? 'Start yearly' : 'Start monthly'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      fontFamily: AppTheme.fontFamily,
                    ),
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

