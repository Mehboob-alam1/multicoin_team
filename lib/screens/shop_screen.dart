import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_product.dart';
import '../services/event_service.dart';
import '../services/game_state_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';
import '../widgets/minimizable_native_ad.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  static const bg       = Color(0xFFF7F8FA);
  static const surface  = Color(0xFFFFFFFF);
  static const card     = Color(0xFFFFFFFF);
  static const cardBord = Color(0xFFE2E8F0);
  static const gold     = Color(0xFFF59E0B);
  static const goldDark = Color(0xFFD97706);
  static const electric = Color(0xFF0EA5E9);
  static const green    = Color(0xFF22C55E);
  static const purple   = Color(0xFFA855F7);
  static const pink     = Color(0xFFEC4899);
  static const orange   = Color(0xFFF97316);
  static const textHi   = Color(0xFF0D0F12);
  static const textMid  = Color(0xFF6B7280);
  static const textLow  = Color(0xFF9CA3AF);
}

// ─── Tab model ────────────────────────────────────────────────────────────────
class _Tab {
  final String label;
  final IconData icon;
  final Color accent;
  const _Tab(this.label, this.icon, this.accent);
}

const _tabs = [
  _Tab('Rigs',     Icons.memory_rounded,              _D.electric),
  _Tab('One-time', Icons.card_giftcard_rounded,        _D.gold),
  _Tab('Premium',  Icons.workspace_premium_rounded,    _D.purple),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
  TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game   = context.watch<GameStateService>();
    final iap    = context.watch<IapService>();
    final events = context.watch<EventService>();
    final adCfg  = context.watch<AdRemoteConfigService>();

    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            // Ambient glows
            Positioned(
              top: -60,
              right: -80,
              child: _Blob(color: _D.gold.withValues(alpha: 0.06), size: 320),
            ),
            Positioned(
              bottom: 80,
              left: -60,
              child: _Blob(color: _D.purple.withValues(alpha: 0.05), size: 260),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── App bar ──────────────────────────────────────────
                  _ShopAppBar(game: game, iap: iap),

                  // ── Hero card ────────────────────────────────────────
                  _HeroCard(game: game),
                  const SizedBox(height: 4),

                  // ── Ad ───────────────────────────────────────────────
                  if (adCfg.adsActive)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: MinimizableNativeAd(title: 'Sponsored deal'),
                    ),

                  // ── Tab bar ──────────────────────────────────────────
                  _ShopTabBar(controller: _tabController),
                  const SizedBox(height: 4),

                  // ── Tab views ────────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _RigsTab(game: game, events: events),
                        _OneTimeTab(game: game, iap: iap, adCfg: adCfg),
                        _PremiumTab(game: game, iap: iap),
                      ],
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

// ─── App bar ──────────────────────────────────────────────────────────────────
class _ShopAppBar extends StatelessWidget {
  final GameStateService game;
  final IapService iap;
  const _ShopAppBar({required this.game, required this.iap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
    child: Row(children: [
      const Icon(Icons.shopping_bag_rounded, color: _D.gold, size: 20),
      const SizedBox(width: 10),
      const Text(
        'SHOP',
        style: TextStyle(
          color: _D.gold,
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 2.5,
        ),
      ),
      const Spacer(),
      // Balance pill
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _D.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _D.gold.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.currency_bitcoin, color: _D.gold, size: 14),
          const SizedBox(width: 4),
          Text(
            game.btcBalance.toStringAsFixed(4),
            style: const TextStyle(
              color: _D.gold,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ]),
      ),
      const SizedBox(width: 8),
      // Restore button
      GestureDetector(
        onTap: iap.loading ? null : () => iap.restorePurchases(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _D.cardBord,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.restore_rounded,
            color: iap.loading ? _D.textLow : _D.textMid,
            size: 18,
          ),
        ),
      ),
    ]),
  );
}

// ─── Hero card ────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final GameStateService game;
  const _HeroCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final isPremium = game.isPremiumActive;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPremium
              ? _D.gold.withValues(alpha: 0.08)
              : _D.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPremium
                ? _D.gold.withValues(alpha: 0.35)
                : _D.cardBord,
          ),
        ),
        child: Row(children: [
          Icon(
            isPremium ? Icons.workspace_premium_rounded : Icons.trending_up_rounded,
            color: isPremium ? _D.gold : _D.electric,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isPremium ? 'Premium active — extend for more gains' : 'Grow faster with packs & premium',
              style: TextStyle(
                color: isPremium ? _D.gold : _D.textHi,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isPremium
                  ? 'Stack boosts and events on top of your 1.5× rate.'
                  : 'Starter packs and premium cut grind time significantly.',
              style: const TextStyle(color: _D.textMid, fontSize: 11),
            ),
          ])),
          if (isPremium) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _D.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _D.gold.withValues(alpha: 0.35)),
              ),
              child: const Text('ACTIVE',
                  style: TextStyle(color: _D.gold, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── Custom tab bar ───────────────────────────────────────────────────────────
class _ShopTabBar extends StatelessWidget {
  final TabController controller;
  const _ShopTabBar({required this.controller});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, __) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final t       = _tabs[i];
          final active  = controller.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? t.accent.withValues(alpha: 0.14) : _D.card,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: active ? t.accent.withValues(alpha: 0.5) : _D.cardBord,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Column(children: [
                  Icon(t.icon, color: active ? t.accent : _D.textLow, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    t.label,
                    style: TextStyle(
                      color: active ? t.accent : _D.textLow,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ]),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

// ─── Rigs tab ─────────────────────────────────────────────────────────────────
class _RigsTab extends StatelessWidget {
  final GameStateService game;
  final EventService events;
  const _RigsTab({required this.game, required this.events});

  @override
  Widget build(BuildContext context) => ListView(
    physics: const BouncingScrollPhysics(),
    padding: EdgeInsets.fromLTRB(AppTheme.pagePaddingH, 12, AppTheme.pagePaddingH, AppTheme.pageBottomPadding(context)),
    children: [
      // Sale banner
      if (events.rigDiscount > 0) ...[
        _SaleBanner(discount: events.rigDiscount),
        const SizedBox(height: 10),
      ],

      // Tip card
      _TipCard(
        icon:    Icons.auto_graph_rounded,
        accent:  _D.electric,
        text:    'Earlier rig upgrades snowball your BTC output. Upgrade your farm tier on the Mining Farm tab.',
      ),
      const SizedBox(height: 14),

      _SectionLabel(label: 'RIGS (USD ONLY)'),
      const SizedBox(height: 8),
      _TipCard(
        icon:    Icons.storefront_rounded,
        accent:  _D.green,
        text:    'Rigs are bought only on the Mining Farm tab (USD / Google Play), with live prices. This shop has packs, boosts, and other upgrades — not individual rigs.',
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/farm'),
          icon: const Icon(Icons.warehouse_rounded, size: 20),
          label: const Text('Open Mining Farm'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _D.gold,
            side: BorderSide(color: _D.gold.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ],
  );
}

// ─── One-time tab ─────────────────────────────────────────────────────────────
class _OneTimeTab extends StatelessWidget {
  final GameStateService game;
  final IapService iap;
  final AdRemoteConfigService adCfg;
  const _OneTimeTab({required this.game, required this.iap, required this.adCfg});

  @override
  Widget build(BuildContext context) => ListView(
    physics: const BouncingScrollPhysics(),
    padding: EdgeInsets.fromLTRB(AppTheme.pagePaddingH, 12, AppTheme.pagePaddingH, AppTheme.pageBottomPadding(context)),
    children: [
      if (iap.error != null) ...[
        _ErrorBanner(message: iap.error!),
        const SizedBox(height: 10),
      ],

      _TipCard(
        icon:   Icons.local_fire_department_rounded,
        accent: _D.gold,
        text:   'Permanent rate bonuses apply to all mining and stack with your farm, session, and premium.',
      ),
      const SizedBox(height: 14),

      _SectionLabel(label: 'PACKS'),
      if (adCfg.first24hBundleDiscountPercent > 0) ...[
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _D.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _D.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_rounded, color: _D.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                'Limited time: Starter pack ${adCfg.first24hBundleDiscountPercent}% off',
                style: const TextStyle(color: _D.gold, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 10),

      ...ShopProducts.shopPacks.map((product) {
        final purchased    = !ShopProducts.isConsumableGoogleProduct(product.id) &&
            game.hasPurchasedOneTime(product.id);
        final storeProduct = iap.getProduct(product.googleProductId);
        final priceStr     = storeProduct?.price ?? product.price;
        final canBuyBtc    = product.isBtcPrice &&
            game.btcBalance >= _parseBtcPrice(product.price);
        final playReady    = iap.isGoogleProductReady(product.googleProductId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _OneTimeCard(
            product:    product,
            priceStr:   priceStr,
            purchased:  purchased,
            canBuy:     product.isBtcPrice ? canBuyBtc : playReady,
            iapAvail:   playReady,
            onPurchase: () => _onPurchase(context, product),
          ),
        );
      }),
    ],
  );

  double _parseBtcPrice(String price) {
    final s = price.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(s) ?? 0;
  }

  Future<void> _onPurchase(BuildContext context, OneTimeProduct product) async {
    if (product.isBtcPrice) {
      const cost = 0.00005;
      if (!game.canSpendBtc(cost)) {
        _toast(context, 'Need 0.00005 BTC'); return;
      }
      await game.deductBtc(cost);
      await game.activateBoost1h();
      await game.applyOneTimePurchase(productId: product.id);
      if (context.mounted) _toast(context, '⚡ 2× Boost active for 1 hour!');
      return;
    }
    final success = await iap.buyProduct(product.googleProductId);
    if (context.mounted) {
      _toast(context, success
          ? 'Complete purchase in Google Play.'
          : (iap.error ?? 'Google Play product unavailable. Check Play Console IDs.'));
    }
  }
}

class _OneTimeCard extends StatelessWidget {
  final OneTimeProduct product;
  final String priceStr;
  final bool purchased;
  final bool canBuy;
  final bool iapAvail;
  final VoidCallback onPurchase;
  const _OneTimeCard({
    required this.product,
    required this.priceStr,
    required this.purchased,
    required this.canBuy,
    required this.iapAvail,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: purchased ? _D.green.withValues(alpha: 0.05) : _D.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: purchased ? _D.green.withValues(alpha: 0.25) : _D.cardBord,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(product.icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name,
                style: const TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(product.description,
                style: const TextStyle(color: _D.textMid, fontSize: 12)),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _D.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _D.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_money, color: _D.gold, size: 14),
                Text(
                  product.isBtcPrice ? priceStr : (priceStr.startsWith('\$') ? priceStr : '\$' + priceStr) + (priceStr.toUpperCase().contains('USD') ? '' : ' USD'),
                  style: const TextStyle(
                    color: _D.gold,
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _GoldBtn(
            label: purchased
                ? 'Owned'
                : product.isBtcPrice
                ? 'Buy with BTC'
                : (iapAvail ? 'Buy with Google Play' : 'Unavailable in Play'),
            enabled: !purchased && canBuy,
            onTap: onPurchase,
            showCheck: purchased,
          ),
        ),
      ]),
    ),
  );
}

// ─── Premium tab ──────────────────────────────────────────────────────────────
class _PremiumTab extends StatelessWidget {
  final GameStateService game;
  final IapService iap;
  const _PremiumTab({required this.game, required this.iap});

  @override
  Widget build(BuildContext context) {
    final isPremium = game.isPremiumActive;
    final expiry    = game.isPremiumActive ? _formatExpiry(game.premiumExpiry) : null;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(AppTheme.pagePaddingH, 12, AppTheme.pagePaddingH, AppTheme.pageBottomPadding(context)),
      children: [
        // Active badge
        if (isPremium) ...[
          _PremiumActiveBadge(expiry: expiry),
          const SizedBox(height: 14),
        ] else ...[
          _TipCard(
            icon:   Icons.workspace_premium_rounded,
            accent: _D.purple,
            text:   'Premium adds 1.5× to all mining (rigs × farm tier). Stacks with session bonus and 2× boosts.',
          ),
          const SizedBox(height: 14),
        ],

        _SectionLabel(label: 'PLANS'),
        const SizedBox(height: 10),

        ...ShopProducts.premiumPlans.map((plan) {
          final storeProduct = iap.getProduct(plan.googleProductId);
          final priceStr     = storeProduct?.price ?? plan.price;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PremiumPlanCard(
              plan:        plan,
              priceStr:    priceStr,
              isPremium:   isPremium,
              iapLoading:  iap.loading,
              iapAvail:    iap.isGoogleProductReady(plan.googleProductId),
              onSubscribe: () => _subscribe(context, plan),
            ),
          );
        }),
      ],
    );
  }

  String _formatExpiry(DateTime? e) =>
      e != null ? '${e.day}/${e.month}/${e.year}' : '';

  Future<void> _subscribe(BuildContext context, PremiumPlan plan) async {
    final success = await iap.buySubscription(plan.googleProductId);
    if (context.mounted) {
      _toast(context, success
          ? 'Complete in Google Play. Premium activates when the purchase finishes.'
          : (iap.error ?? 'Google Play subscription unavailable. Check Play Console IDs.'));
    }
  }
}

class _PremiumActiveBadge extends StatelessWidget {
  final String? expiry;
  const _PremiumActiveBadge({required this.expiry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1E1800), Color(0xFF120F00)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _D.gold.withValues(alpha: 0.4)),
      boxShadow: [BoxShadow(color: _D.gold.withValues(alpha: 0.12), blurRadius: 20)],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _D.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.workspace_premium_rounded, color: _D.gold, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Premium Active',
            style: TextStyle(color: _D.gold, fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 2),
        Text(
          '1.5× mining rate · No ads${expiry != null ? ' · Until $expiry' : ''}',
          style: const TextStyle(color: _D.textMid, fontSize: 12),
        ),
      ])),
    ]),
  );
}

class _PremiumPlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final String priceStr;
  final bool isPremium;
  final bool iapLoading;
  final bool iapAvail;
  final VoidCallback onSubscribe;
  const _PremiumPlanCard({
    required this.plan,
    required this.priceStr,
    required this.isPremium,
    required this.iapLoading,
    required this.iapAvail,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _D.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _D.cardBord),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan.name,
                style: const TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(plan.description,
                style: const TextStyle(color: _D.textMid, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _D.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _D.purple.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_money, color: _D.purple, size: 14),
                Text(
                  (priceStr.startsWith('\$') ? priceStr : '\$' + priceStr) + (priceStr.toUpperCase().contains('USD') ? '' : ' USD') + (plan.period == 'month' ? '/mo' : '/yr'),
                  style: const TextStyle(
                    color: _D.purple,
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ]),

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
              child: Text(b, style: const TextStyle(color: _D.purple, fontSize: 11, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _PurpleBtn(
            label: iapLoading
                ? 'Loading…'
                : isPremium
                ? 'Extend'
                : (iapAvail ? 'Subscribe with Google Play' : 'Unavailable in Play'),
            onTap: onSubscribe,
          ),
        ),
      ]),
    ),
  );
}

// ─── Shared small components ──────────────────────────────────────────────────
class _SaleBanner extends StatelessWidget {
  final double discount;
  const _SaleBanner({required this.discount});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _D.orange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _D.orange.withValues(alpha: 0.35)),
    ),
    child: Row(children: [
      const Icon(Icons.local_offer_rounded, color: _D.orange, size: 18),
      const SizedBox(width: 8),
      Text(
        '${(discount * 100).toStringAsFixed(0)}% Rig Sale — Weekly event active!',
        style: const TextStyle(color: _D.orange, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ]),
  );
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String text;
  const _TipCard({required this.icon, required this.accent, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: accent.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Icon(icon, color: accent, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
          style: const TextStyle(color: _D.textMid, fontSize: 12))),
    ]),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
    ),
    child: Text(message, style: const TextStyle(color: Colors.orange, fontSize: 12)),
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: _D.textMid,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );
}

// ─── Buttons ──────────────────────────────────────────────────────────────────
class _BuyBtn extends StatefulWidget {
  final bool canBuy;
  final bool isFull;
  final VoidCallback onTap;
  const _BuyBtn({required this.canBuy, required this.isFull, required this.onTap});

  @override
  State<_BuyBtn> createState() => _BuyBtnState();
}

class _BuyBtnState extends State<_BuyBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    final label = widget.isFull ? 'Full' : 'Buy';
    return GestureDetector(
      onTapDown: widget.canBuy ? (_) => setState(() => _p = true) : null,
      onTapUp: widget.canBuy ? (_) { setState(() => _p = false); widget.onTap(); } : null,
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: widget.canBuy
                ? const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE08800)])
                : null,
            color: widget.canBuy ? null : _D.cardBord,
            borderRadius: BorderRadius.circular(9),
            boxShadow: widget.canBuy
                ? [BoxShadow(color: _D.gold.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                color: widget.canBuy ? Colors.black : _D.textLow,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              )),
        ),
      ),
    );
  }
}

class _GoldBtn extends StatefulWidget {
  final String label;
  final bool enabled;
  final bool showCheck;
  final VoidCallback onTap;
  const _GoldBtn({required this.label, required this.enabled, required this.onTap, this.showCheck = false});

  @override
  State<_GoldBtn> createState() => _GoldBtnState();
}

class _GoldBtnState extends State<_GoldBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.enabled ? (_) => setState(() => _p = true) : null,
    onTapUp: widget.enabled ? (_) { setState(() => _p = false); widget.onTap(); } : null,
    onTapCancel: () => setState(() => _p = false),
    child: AnimatedScale(
      scale: _p ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: widget.enabled
              ? const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE08800)])
              : null,
          color: widget.enabled ? null : _D.cardBord,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.enabled
              ? [BoxShadow(color: _D.gold.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (widget.showCheck) ...[
            const Icon(Icons.check_circle_rounded, color: _D.green, size: 16),
            const SizedBox(width: 6),
          ],
          Text(widget.label,
              style: TextStyle(
                color: widget.enabled ? Colors.black : _D.textLow,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              )),
        ]),
      ),
    ),
  );
}

class _PurpleBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PurpleBtn({required this.label, required this.onTap});

  @override
  State<_PurpleBtn> createState() => _PurpleBtnState();
}

class _PurpleBtnState extends State<_PurpleBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _p = true),
    onTapUp: (_) { setState(() => _p = false); widget.onTap(); },
    onTapCancel: () => setState(() => _p = false),
    child: AnimatedScale(
      scale: _p ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _D.purple.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _D.purple.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: _D.purple.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star_rounded, color: _D.purple, size: 16),
          const SizedBox(width: 6),
          Text(widget.label,
              style: const TextStyle(color: _D.purple, fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      ),
    ),
  );
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: const SizedBox.shrink(),
    ),
  );
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: _D.textHi)),
    backgroundColor: _D.card,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: _D.cardBord),
    ),
  ));
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: AppTheme.fontFamily,
  textTheme: AppTheme.darkTextTheme,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(primary: _D.gold, surface: _D.surface),
);