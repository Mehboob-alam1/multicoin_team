import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';

class _LaunchOffer {
  final String title;
  final String subtitle;
  final String cta;
  final String productId;
  final bool isSubscription;
  final IconData icon;
  final Color accent;
  final String fallbackPrice;
  final List<String> perks;

  const _LaunchOffer({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.productId,
    required this.isSubscription,
    required this.icon,
    required this.accent,
    required this.fallbackPrice,
    required this.perks,
  });
}

/// Random IAP offer shown once each time the app is opened.
class LaunchOfferDialog {
  static const _gold = Color(0xFFF59E0B);
  static const _purple = Color(0xFFA855F7);
  static const _green = Color(0xFF22C55E);
  static const _textHi = Color(0xFF0D0F12);
  static const _textMid = Color(0xFF6B7280);
  static const _card = Color(0xFFFFFFFF);
  static const _cardBord = Color(0xFFE2E8F0);

  static const _offers = <_LaunchOffer>[
    _LaunchOffer(
      title: 'Yearly Premium',
      subtitle: 'Best value — 1.5× mining all year, no ads, VIP badge.',
      cta: 'Go yearly',
      productId: 'premium_yearly',
      isSubscription: true,
      icon: Icons.workspace_premium_rounded,
      accent: _purple,
      fallbackPrice: r'$29.99',
      perks: ['1.5× mining', 'No ads', 'Save 50%'],
    ),
    _LaunchOffer(
      title: 'Premium Monthly',
      subtitle: 'Unlock 1.5× mining, exclusive rigs, and a VIP badge.',
      cta: 'Start premium',
      productId: 'premium_monthly',
      isSubscription: true,
      icon: Icons.star_rounded,
      accent: _purple,
      fallbackPrice: r'$4.99',
      perks: ['1.5× mining', 'Exclusive rigs', 'No ads'],
    ),
    _LaunchOffer(
      title: 'Starter Pack',
      subtitle: 'Jump ahead with BTC plus a GPU rig for your farm.',
      cta: 'Grab pack',
      productId: 'starter_pack',
      isSubscription: false,
      icon: Icons.inventory_2_rounded,
      accent: _gold,
      fallbackPrice: r'$1.99',
      perks: ['BTC bonus', '1× GPU rig'],
    ),
    _LaunchOffer(
      title: 'Mega Pack',
      subtitle: 'A bigger BTC drop plus a Mining rack — skip the grind.',
      cta: 'Get Mega Pack',
      productId: 'mega_pack',
      isSubscription: false,
      icon: Icons.diamond_rounded,
      accent: _gold,
      fallbackPrice: r'$9.99',
      perks: ['Larger BTC', '1× Mining rack'],
    ),
    _LaunchOffer(
      title: '2× Boost (1 hour)',
      subtitle: 'Double your mining rate right now for a full hour.',
      cta: 'Boost now',
      productId: 'boost_2x_1h',
      isSubscription: false,
      icon: Icons.bolt_rounded,
      accent: _green,
      fallbackPrice: r'$0.99',
      perks: ['2× rate', '1 hour'],
    ),
  ];

  static Future<void> show(BuildContext context) async {
    final game = context.read<GameStateService>();
    var pool = List<_LaunchOffer>.from(_offers);
    if (game.isPremiumActive) {
      pool = pool.where((o) => !o.isSubscription).toList();
    }
    if (pool.isEmpty) return;
    final offer = pool[Random().nextInt(pool.length)];

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _LaunchOfferBody(offer: offer),
    );
  }
}

class _LaunchOfferBody extends StatefulWidget {
  final _LaunchOffer offer;
  const _LaunchOfferBody({required this.offer});

  @override
  State<_LaunchOfferBody> createState() => _LaunchOfferBodyState();
}

class _LaunchOfferBodyState extends State<_LaunchOfferBody> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final iap = context.watch<IapService>();
    final offer = widget.offer;
    final store = iap.getProduct(offer.productId);
    final playReady = iap.isGoogleProductReady(offer.productId);
    final price = store?.price ?? offer.fallbackPrice;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            decoration: BoxDecoration(
              color: LaunchOfferDialog._card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: offer.accent.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: offer.accent.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: LaunchOfferDialog._textMid, size: 22),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: offer.accent.withValues(alpha: 0.12),
                    border: Border.all(color: offer.accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(offer.icon, color: offer.accent, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  'Limited offer',
                  style: TextStyle(
                    color: offer.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  offer.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LaunchOfferDialog._textHi,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: LaunchOfferDialog._textMid,
                    fontSize: 13,
                    height: 1.4,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: offer.perks
                      .map(
                        (p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: offer.accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              color: offer.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: (_busy || !playReady) ? null : () => _buy(iap),
                    style: FilledButton.styleFrom(
                      backgroundColor: offer.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            playReady ? '${offer.cta}  ·  $price' : 'Unavailable in Google Play',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: LaunchOfferDialog._textMid,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buy(IapService iap) async {
    setState(() => _busy = true);
    final offer = widget.offer;
    try {
      final ok = offer.isSubscription
          ? await iap.buySubscription(offer.productId)
          : await iap.buyProduct(offer.productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? 'Complete purchase in Google Play.' : (iap.error ?? 'Google Play product unavailable.'),
          style: const TextStyle(color: LaunchOfferDialog._textHi),
        ),
        backgroundColor: LaunchOfferDialog._card,
        behavior: SnackBarBehavior.floating,
      ));
      if (ok) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
