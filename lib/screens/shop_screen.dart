import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/mining_economy.dart';
import '../models/shop_product.dart';
import '../services/ad_remote_config_service.dart';
import '../services/event_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_ad_slot.dart';

class _D {
  static const bg = Color(0xFF08080A);
  static const surface = Color(0xFF18181C);
  static const gold = Color(0xFF9945FF);
  static const goldText = Color(0xFFE9D5FF);
  static const goldBg = Color(0xFF1A1228);
  static const goldBdr = Color(0x669945FF);
  static const green = Color(0xFF14F195);
  static const greenBg = Color(0xFF0A2E22);
  static const greenBdr = Color(0x6614F195);
  static const electric = Color(0xFF38BDF8);
  static const electricBg = Color(0xFF0C1A24);
  static const electricBdr = Color(0xFF164E63);
  static const violet = Color(0xFFA78BFA);
  static const orange = Color(0xFFF97316);
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

TextStyle _mono({
  double size = 13,
  FontWeight weight = FontWeight.w700,
  Color color = _D.textHi,
}) =>
    GoogleFonts.spaceMono(fontSize: size, fontWeight: weight, color: color, height: 1.1, letterSpacing: -0.3);

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final iap = context.watch<IapService>();
    final events = context.watch<EventService>();
    final adCfg = context.watch<AdRemoteConfigService>();

    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MeshPainter())),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: AppTheme.pageScroll,
                slivers: [
                  SliverToBoxAdapter(child: _ShopAppBar(game: game, iap: iap)),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      AppTheme.pageBottomPadding(context),
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _OneTimeSection(game: game, iap: iap, adCfg: adCfg),
                        const SizedBox(height: 28),
                        _PremiumSection(game: game, iap: iap),
                        const SizedBox(height: 28),
                        _RigsSection(game: game, events: events),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopAppBar extends StatelessWidget {
  final GameStateService game;
  final IapService iap;

  const _ShopAppBar({required this.game, required this.iap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _D.goldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _D.goldBdr),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: _D.gold, size: 18),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                ).createShader(r),
                child: Text('Shop', style: _sg(size: 16, weight: FontWeight.w700, spacing: -0.3, color: Colors.white)),
              ),
              Text('UPGRADES', style: _sg(size: 9, weight: FontWeight.w700, color: _D.gold, spacing: 1.6)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: _D.goldBg,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: _D.goldBdr),
            ),
            child: Row(
              children: [
                const Icon(Icons.hexagon_rounded, color: _D.gold, size: 13),
                const SizedBox(width: 5),
                Text(game.btcBalance.toStringAsFixed(4), style: _mono(size: 12, color: _D.goldText)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoundButton(
            icon: Icons.restore_rounded,
            enabled: !iap.loading,
            onTap: iap.loading ? null : () => iap.restorePurchases(),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final GameStateService game;
  const _HeroCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final premium = game.isPremiumActive;
    return _Glass(
      tint: premium ? const Color(0xC01A1228) : const Color(0xB318181C),
      border: premium ? _D.goldBdr : _D.line,
      child: Row(
        children: [
          _IconTile(
            icon: premium ? Icons.workspace_premium_rounded : Icons.trending_up_rounded,
            color: premium ? _D.gold : _D.electric,
            tint: premium ? _D.goldBg : _D.electricBg,
            border: premium ? _D.goldBdr : _D.electricBdr,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  premium ? 'Premium is active' : 'Grow faster with packs',
                  style: _sg(size: 14.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  premium
                      ? 'Stack boosts and events on your 1.5× rate.'
                      : 'Packs and premium cut the grind significantly.',
                  style: _sg(size: 12, color: _D.textMid, height: 1.3),
                ),
              ],
            ),
          ),
          if (premium) ...[
            const SizedBox(width: 8),
            Text('ACTIVE', style: _sg(size: 9, weight: FontWeight.w800, color: _D.goldText, spacing: 0.8)),
          ],
        ],
      ),
    );
  }
}

class _RigsSection extends StatelessWidget {
  final GameStateService game;
  final EventService events;

  const _RigsSection({required this.game, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (events.rigDiscount > 0) ...[
          _Notice(
            icon: Icons.local_offer_rounded,
            color: _D.orange,
            text: '${(events.rigDiscount * 100).toStringAsFixed(0)}% rig sale is active this week.',
          ),
          const SizedBox(height: 12),
        ],
        const _Notice(
          icon: Icons.auto_graph_rounded,
          color: _D.electric,
          text: 'Earlier rig upgrades snowball your SOL output. Upgrade the farm tier from Mining Farm.',
        ),
        const SizedBox(height: 18),
        const _SectionLabel('Rigs'),
        const SizedBox(height: 12),
        const _Notice(
          icon: Icons.storefront_rounded,
          color: _D.green,
          text: 'Individual rigs are purchased only on Mining Farm with Google Play. This shop has packs, boosts, and premium.',
        ),
        const SizedBox(height: 16),
        _GradientButton(
          label: 'Open Mining Farm',
          icon: Icons.warehouse_rounded,
          onTap: () => Navigator.pushNamed(context, '/farm'),
        ),
      ],
    );
  }
}

class _OneTimeSection extends StatelessWidget {
  final GameStateService game;
  final IapService iap;
  final AdRemoteConfigService adCfg;

  const _OneTimeSection({required this.game, required this.iap, required this.adCfg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (iap.error != null) ...[
          _Notice(icon: Icons.error_outline_rounded, color: _D.orange, text: iap.error!),
          const SizedBox(height: 12),
        ],
        const _Notice(
          icon: Icons.local_fire_department_rounded,
          color: _D.gold,
          text: 'Permanent rate bonuses apply to all mining and stack with farm, session, and premium.',
        ),
        const SizedBox(height: 18),
        const _SectionLabel('Packs'),
        if (adCfg.first24hBundleDiscountPercent > 0) ...[
          const SizedBox(height: 12),
          _Notice(
            icon: Icons.local_offer_rounded,
            color: _D.gold,
            text: 'Limited time: Starter pack ${adCfg.first24hBundleDiscountPercent}% off',
          ),
        ],
        const SizedBox(height: 12),
        ..._packCardsWithAds(context),
      ],
    );
  }

  List<Widget> _packCardsWithAds(BuildContext context) {
    final packs = ShopProducts.shopPacks;
    final showAds = adCfg.shouldShowSdkAds && !game.isPremiumActive;
    final out = <Widget>[];
    var shownBanner = false;
    for (var i = 0; i < packs.length; i++) {
      out.add(_packCard(context, packs[i]));
      if (showAds && i == 1) {
        out.add(const SizedBox(height: 4));
        out.add(const ScreenAdSlot(
          title: 'Shop native',
          bannerFallback: false,
        ));
        out.add(const SizedBox(height: 12));
      }
      if (showAds && i == 4) {
        out.add(const SizedBox(height: 4));
        out.add(const ScreenAdSlot(
          title: 'Shop banner',
          allowNative: false,
        ));
        out.add(const SizedBox(height: 12));
        shownBanner = true;
      }
    }
    if (showAds && !shownBanner) {
      out.add(const SizedBox(height: 4));
      out.add(const ScreenAdSlot(
        title: 'Shop banner',
        allowNative: false,
      ));
    }
    return out;
  }

  Widget _packCard(BuildContext context, OneTimeProduct product) {
    final purchased = !ShopProducts.isConsumableGoogleProduct(product.id) && game.hasPurchasedOneTime(product.id);
    final storeProduct = iap.getProduct(product.googleProductId);
    final price = storeProduct?.price ?? product.price;
    final playReady = iap.isGoogleProductReady(product.googleProductId);
    final canBuy = product.isBtcPrice ? game.btcBalance >= _parseBtcPrice(product.price) : playReady;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _OneTimeCard(
        product: product,
        price: price,
        purchased: purchased,
        canBuy: canBuy,
        playReady: playReady,
        onPurchase: () => _purchase(context, product),
      ),
    );
  }

  double _parseBtcPrice(String price) => double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

  Future<void> _purchase(BuildContext context, OneTimeProduct product) async {
    if (product.isBtcPrice) {
      final cost = MiningEconomy.toSol(0.00005);
      if (!game.canSpendBtc(cost)) {
        _toast(context, 'Need ${cost.toStringAsFixed(4)} SOL');
        return;
      }
      await game.deductBtc(cost);
      await game.activateBoost1h();
      await game.applyOneTimePurchase(productId: product.id);
      if (context.mounted) _toast(context, '2× boost active for 1 hour');
      return;
    }
    final success = await iap.buyProduct(product.googleProductId);
    if (context.mounted) {
      _toast(
        context,
        success ? 'Complete purchase in Google Play.' : (iap.error ?? 'Google Play product unavailable. Check Play Console IDs.'),
      );
    }
  }
}

class _OneTimeCard extends StatelessWidget {
  final OneTimeProduct product;
  final String price;
  final bool purchased;
  final bool canBuy;
  final bool playReady;
  final VoidCallback onPurchase;

  const _OneTimeCard({
    required this.product,
    required this.price,
    required this.purchased,
    required this.canBuy,
    required this.playReady,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final label = purchased
        ? 'Owned'
        : product.isBtcPrice
        ? 'Buy with SOL'
        : (playReady ? 'Buy with Google Play' : 'Unavailable in Play');
    return _Glass(
      tint: purchased ? const Color(0xC00A2E22) : const Color(0xB318181C),
      border: purchased ? _D.greenBdr : _D.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(product.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: _sg(size: 16, weight: FontWeight.w700, spacing: -0.2)),
                    const SizedBox(height: 3),
                    Text(product.description, style: _sg(size: 12.5, color: _D.textMid, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                product.isBtcPrice ? price : _usd(price),
                style: _mono(size: 12, color: _D.goldText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GradientButton(
            label: label,
            icon: purchased ? Icons.check_circle_rounded : Icons.shopping_bag_outlined,
            enabled: !purchased && canBuy,
            onTap: onPurchase,
          ),
        ],
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  final GameStateService game;
  final IapService iap;

  const _PremiumSection({required this.game, required this.iap});

  @override
  Widget build(BuildContext context) {
    final premium = game.isPremiumActive;
    final expiry = game.premiumExpiry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (premium)
          _Glass(
            tint: const Color(0xC01A1228),
            border: _D.goldBdr,
            child: Row(
              children: [
                const _IconTile(icon: Icons.workspace_premium_rounded, color: _D.gold, tint: _D.goldBg, border: _D.goldBdr),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Premium active', style: _sg(size: 16, weight: FontWeight.w700, color: _D.goldText)),
                      const SizedBox(height: 3),
                      Text(
                        '1.5× mining · No ads${expiry == null ? '' : ' · Until ${expiry.day}/${expiry.month}/${expiry.year}'}',
                        style: _sg(size: 12, color: _D.textMid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          const _Notice(
            icon: Icons.workspace_premium_rounded,
            color: _D.violet,
            text: 'Premium adds 1.5× to all mining. It stacks with the session bonus and 2× boosts.',
          ),
        const SizedBox(height: 18),
        const _SectionLabel('Plans'),
        const SizedBox(height: 12),
        ...ShopProducts.premiumPlans.map((plan) {
          final store = iap.getProduct(plan.googleProductId);
          final price = store?.price ?? plan.price;
          final featured = plan.period != 'month';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PremiumPlanCard(
              plan: plan,
              price: price,
              featured: featured,
              premium: premium,
              loading: iap.loading,
              ready: iap.isGoogleProductReady(plan.googleProductId),
              onSubscribe: () => _subscribe(context, plan),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _subscribe(BuildContext context, PremiumPlan plan) async {
    final success = await iap.buySubscription(plan.googleProductId);
    if (!context.mounted) return;
    _toast(
      context,
      success
          ? 'Complete in Google Play. Premium activates when the purchase finishes.'
          : (iap.error ?? 'Google Play subscription unavailable. Check Play Console IDs.'),
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final String price;
  final bool featured;
  final bool premium;
  final bool loading;
  final bool ready;
  final VoidCallback onSubscribe;

  const _PremiumPlanCard({
    required this.plan,
    required this.price,
    required this.featured,
    required this.premium,
    required this.loading,
    required this.ready,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final suffix = plan.period == 'month' ? '/mo' : '/yr';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _IconTile(icon: Icons.workspace_premium_rounded, color: _D.violet, tint: Color(0xFF1A1228), border: Color(0xFF4C1D95)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: _sg(size: 16, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(plan.description, style: _sg(size: 12, color: _D.textMid, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(_usd(price, suffix: suffix), style: _mono(size: 12, color: featured ? _D.goldText : _D.violet)),
          ],
        ),
        if (plan.benefits.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final benefit in plan.benefits)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _D.violet.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _D.violet.withValues(alpha: 0.24)),
                  ),
                  child: Text(benefit, style: _sg(size: 11, weight: FontWeight.w600, color: _D.violet)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _GradientButton(
          label: loading ? 'Loading…' : premium ? 'Extend' : (ready ? 'Subscribe with Google Play' : 'Unavailable in Play'),
          icon: Icons.star_rounded,
          enabled: !loading,
          onTap: onSubscribe,
        ),
      ],
    );

    if (!featured) return _Glass(child: content);
    return Container(
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
      ),
      child: _Glass(radius: 23, tint: const Color(0xE6111114), border: Colors.transparent, child: content),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Notice({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _sg(size: 12.5, color: _D.textMid, height: 1.35))),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: _D.gold, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label.toUpperCase(), style: _sg(size: 10, weight: FontWeight.w700, color: _D.textMid, spacing: 1.5)),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color tint;
  final Color border;

  const _IconTile({required this.icon, required this.color, required this.tint, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(13), border: Border.all(color: border)),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _RoundButton({required this.icon, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xB318181C),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _D.line),
          ),
          child: Icon(icon, color: _D.textMid, size: 18),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _GradientButton({required this.label, required this.icon, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.42,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _sg(size: 13.5, weight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color tint;
  final Color border;

  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.radius = 24,
    this.tint = const Color(0xF21F1F26),
    this.border = _D.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9945FF).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tint.withValues(alpha: 0.96), const Color(0xE6121216)],
                ),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border, width: 0.8),
              ),
              child: child,
            ),
            const Positioned(
              top: 0,
              left: 18,
              right: 18,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x00FFFFFF), Color(0x38FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                  child: SizedBox(height: 1),
                ),
              ),
            ),
          ],
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
        Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glow(Offset(size.width * 0.9, 10), 180, const Color(0x349945FF));
    glow(Offset(-10, size.height * 0.72), 170, const Color(0x2238BDF8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _usd(String raw, {String suffix = ''}) {
  final priced = raw.startsWith('\$') ? raw : '\$$raw';
  return priced + (raw.toUpperCase().contains('USD') ? '' : ' USD') + suffix;
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: _sg(size: 13, weight: FontWeight.w600)),
      backgroundColor: _D.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: _D.line)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(primary: _D.gold, surface: _D.surface),
);