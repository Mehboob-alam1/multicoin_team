import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_product.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';

// ─── Design tokens (same as app) ───────────────────────────────────────────────
class _D {
  static const bg       = Color(0xFFF7F8FA);
  static const surface  = Color(0xFFFFFFFF);
  static const card     = Color(0xFFFFFFFF);
  static const cardBord = Color(0xFFE2E8F0);
  static const gold     = Color(0xFFF59E0B);
  static const electric = Color(0xFF0EA5E9);
  static const purple   = Color(0xFFA855F7);
  static const textHi   = Color(0xFF0D0F12);
  static const textMid  = Color(0xFF6B7280);
  static const textLow  = Color(0xFF9CA3AF);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      final game = context.read<GameStateService>();
      final user = auth.currentUser;
      if (user != null) {
        game.setUserId(user.uid);
        game.setDisplayName(user.displayName ?? user.email ?? 'Miner');
        game.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final iap  = context.watch<IapService>();

    return Scaffold(
      backgroundColor: _D.bg,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(color: _D.gold.withValues(alpha: 0.06), size: 320),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: _Blob(color: _D.purple.withValues(alpha: 0.05), size: 280),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Skip at top ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _goHome(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _D.textMid,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Skip', style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTheme.fontFamily,
                        )),
                      ),
                    ],
                  ),
                ),

                // ── Hero: encourage premium ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _D.purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _D.purple.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: _D.purple, size: 48),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Unlock your full mining power',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _D.textHi,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTheme.fontFamily,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Go Premium for 1.5× mining rate, exclusive rigs, no ads, and VIP badge. Start mining faster today.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _D.textMid,
                          fontSize: 14,
                          height: 1.4,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Plans list ──────────────────────────────────────────────
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      ...ShopProducts.premiumPlans.map((plan) {
                        final storeProduct = iap.getProduct(plan.id);
                        final priceStr     = storeProduct?.price ?? plan.price;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PlanCard(
                            plan: plan,
                            priceStr: priceStr,
                            iapLoading: iap.loading,
                            iapAvail: iap.available && storeProduct != null,
                            onSubscribe: () => _subscribe(context, plan),
                          ),
                        );
                      }),
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
    final game = context.read<GameStateService>();
    final useStore = iap.available && iap.getProduct(plan.id) != null;
    if (useStore) {
      final success = await iap.buySubscription(plan.id);
      if (!context.mounted) return;
      if (success) {
        _toast(context, 'Complete in the store. Premium activates when done.');
        _goHome(context);
      } else {
        _toast(context, iap.error ?? 'Purchase failed');
      }
      return;
    }
    await game.activatePremium(plan.id, plan.durationDays);
    if (context.mounted) {
      _toast(context, '⭐ ${plan.name} activated!');
      _goHome(context);
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

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final String priceStr;
  final bool iapLoading;
  final bool iapAvail;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.priceStr,
    required this.iapLoading,
    required this.iapAvail,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _D.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _D.cardBord),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _D.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: _D.purple.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: _D.purple, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          color: _D.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.description,
                        style: const TextStyle(color: _D.textMid, fontSize: 12, fontFamily: AppTheme.fontFamily),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _D.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _D.purple.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    priceStr,
                    style: const TextStyle(
                      color: _D.purple,
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (plan.benefits.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: plan.benefits.map((b) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _D.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _D.purple.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    b,
                    style: const TextStyle(
                      color: _D.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _SubscribeBtn(
                label: iapLoading ? 'Loading…' : (iapAvail ? 'Subscribe' : 'Claim'),
                onTap: onSubscribe,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscribeBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SubscribeBtn({required this.label, required this.onTap});

  @override
  State<_SubscribeBtn> createState() => _SubscribeBtnState();
}

class _SubscribeBtnState extends State<_SubscribeBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: _D.purple.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _D.purple.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: _D.purple.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: _D.purple, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: _D.purple,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
