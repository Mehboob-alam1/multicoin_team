import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/game_state_service.dart';
import '../services/iap_service.dart';

class _D {
  static const surface = Color(0xFF18181C);
  static const gold = Color(0xFF9945FF);
  static const goldText = Color(0xFFE9D5FF);
  static const goldBg = Color(0xFF1A1228);
  static const goldBdr = Color(0x669945FF);
  static const green = Color(0xFF14F195);
  static const greenText = Color(0xFFBBF7D0);
  static const greenBg = Color(0xFF0A2E22);
  static const greenBdr = Color(0x6614F195);
  static const violet = Color(0xFFA78BFA);
  static const textHi = Color(0xFFF4F4F5);
  static const textMid = Color(0xFFA1A1AA);
  static const textLow = Color(0xFF71717A);
  static const line = Color(0x1FFFFFFF);
}

TextStyle _sg({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _D.textHi,
  double? spacing,
  double? height,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );

class _LaunchOffer {
  final String title;
  final String subtitle;
  final String cta;
  final String productId;
  final bool isSubscription;
  final IconData icon;
  final Color accent;
  final Color tint;
  final Color border;
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
    required this.tint,
    required this.border,
    required this.fallbackPrice,
    required this.perks,
  });
}

class LaunchOfferDialog {
  static const _offers = <_LaunchOffer>[
    _LaunchOffer(
      title: 'Yearly Premium',
      subtitle: 'Best value — 1.5× mining all year, no ads, VIP badge.',
      cta: 'Go yearly',
      productId: 'premium_yearly',
      isSubscription: true,
      icon: Icons.workspace_premium_rounded,
      accent: _D.violet,
      tint: _D.goldBg,
      border: Color(0xFF4C1D95),
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
      accent: _D.violet,
      tint: _D.goldBg,
      border: Color(0xFF4C1D95),
      fallbackPrice: r'$4.99',
      perks: ['1.5× mining', 'Exclusive rigs', 'No ads'],
    ),
    _LaunchOffer(
      title: 'Starter Pack',
      subtitle: 'Jump ahead with SOL plus a GPU rig for your farm.',
      cta: 'Grab pack',
      productId: 'starter_pack',
      isSubscription: false,
      icon: Icons.inventory_2_rounded,
      accent: _D.gold,
      tint: _D.goldBg,
      border: _D.goldBdr,
      fallbackPrice: r'$1.99',
      perks: ['SOL bonus', '1× GPU rig'],
    ),
    _LaunchOffer(
      title: 'Mega Pack',
      subtitle: 'A bigger SOL drop plus a Mining rack — skip the grind.',
      cta: 'Get Mega Pack',
      productId: 'mega_pack',
      isSubscription: false,
      icon: Icons.diamond_rounded,
      accent: _D.gold,
      tint: _D.goldBg,
      border: _D.goldBdr,
      fallbackPrice: r'$9.99',
      perks: ['Larger SOL', '1× Mining rack'],
    ),
    _LaunchOffer(
      title: '2× Boost (1 hour)',
      subtitle: 'Double your mining rate right now for a full hour.',
      cta: 'Boost now',
      productId: 'boost_2x_1h',
      isSubscription: false,
      icon: Icons.bolt_rounded,
      accent: _D.green,
      tint: _D.greenBg,
      border: _D.greenBdr,
      fallbackPrice: r'$0.99',
      perks: ['2× rate', '1 hour'],
    ),
  ];

  static Future<void> show(BuildContext context) async {
    final game = context.read<GameStateService>();
    var pool = List<_LaunchOffer>.from(_offers);
    if (game.isPremiumActive) {
      pool = pool.where((offer) => !offer.isSubscription).toList();
    }
    if (pool.isEmpty) return;

    final offer = pool[Random().nextInt(pool.length)];
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (_) => _LaunchOfferBody(offer: offer),
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
    final ready = iap.isGoogleProductReady(offer.productId);
    final price = store?.price ?? offer.fallbackPrice;
    final width = min(MediaQuery.sizeOf(context).width - 36, 390.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                decoration: BoxDecoration(
                  color: const Color(0xF0111114),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: offer.border.withValues(alpha: 0.75)),
                  boxShadow: [
                    BoxShadow(
                      color: offer.accent.withValues(alpha: 0.16),
                      blurRadius: 34,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _CloseButton(onTap: () => Navigator.pop(context)),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: offer.tint,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: offer.border),
                      ),
                      child: Icon(offer.icon, color: offer.accent, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LIMITED OFFER',
                      textAlign: TextAlign.center,
                      style: _sg(size: 10, weight: FontWeight.w700, color: offer.accent, spacing: 1.6),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      offer.title,
                      textAlign: TextAlign.center,
                      style: _sg(size: 24, weight: FontWeight.w700, spacing: -0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer.subtitle,
                      textAlign: TextAlign.center,
                      style: _sg(size: 13.5, color: _D.textMid, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final perk in offer.perks)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: offer.accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: offer.accent.withValues(alpha: 0.24)),
                            ),
                            child: Text(perk, style: _sg(size: 11, weight: FontWeight.w700, color: offer.accent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: (_busy || !ready) ? null : () => _buy(iap),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: ready ? 1 : 0.45,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _busy
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : Text(
                            ready ? '${offer.cta} · $price' : 'Unavailable in Google Play',
                            textAlign: TextAlign.center,
                            style: _sg(size: 14.5, weight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: Text('Skip for now', style: _sg(size: 13, weight: FontWeight.w600, color: _D.textMid)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _buy(IapService iap) async {
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    final offer = widget.offer;
    try {
      final ok = offer.isSubscription
          ? await iap.buySubscription(offer.productId)
          : await iap.buyProduct(offer.productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Complete purchase in Google Play.' : (iap.error ?? 'Google Play product unavailable.'),
            style: _sg(size: 13, weight: FontWeight.w600),
          ),
          backgroundColor: _D.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _D.line),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      if (ok) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _D.line),
        ),
        child: const Icon(Icons.close_rounded, color: _D.textLow, size: 17),
      ),
    );
  }
}