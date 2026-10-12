import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/mining_economy.dart';
import '../models/mining_rig.dart';
import '../models/shop_product.dart';
import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../widgets/minimizable_native_ad.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_banner_ad.dart';

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
  static const orange   = Color(0xFFF97316);
  static const textHi   = Color(0xFF0D0F12);
  static const textMid  = Color(0xFF6B7280);
  static const textLow  = Color(0xFF9CA3AF);
}

// ─── Rig visual metadata ──────────────────────────────────────────────────────
class _RigMeta {
  final IconData icon;
  final Color accent;
  final String tier;
  const _RigMeta(this.icon, this.accent, this.tier);
}

_RigMeta _metaForRig(String id) => switch (id) {
  'laptop'          => const _RigMeta(Icons.laptop_rounded,       Color(0xFF8899BB), 'Tier I'),
  'gpu_rig'         => const _RigMeta(Icons.memory_rounded,        _D.green,          'Tier II'),
  'mining_rack'     => const _RigMeta(Icons.view_module_rounded,   _D.electric,       'Tier III'),
  'warehouse_farm'  => const _RigMeta(Icons.warehouse_rounded,     _D.gold,           'Tier IV'),
  'mega_facility'   => const _RigMeta(Icons.auto_awesome_rounded,  Color(0xFFB06EFF), 'Tier V'),
  'cpu_miner'       => const _RigMeta(Icons.memory_rounded,        Color(0xFF8899BB), 'Tier I'),
  'gaming_gpu_rig'  => const _RigMeta(Icons.sports_esports_rounded, _D.green,       'Tier II'),
  'gpu_cluster'     => const _RigMeta(Icons.hub_rounded,           _D.electric,       'Tier III'),
  'asic_btc'        => const _RigMeta(Icons.flash_on_rounded,      _D.gold,           'Tier IV'),
  'data_center_rig' => const _RigMeta(Icons.dns_rounded,           Color(0xFFB06EFF), 'Tier V'),
  _                 => const _RigMeta(Icons.hardware_rounded,      _D.textMid,        ''),
};

/// Scales farm card type so long rig names stay fully visible on narrow screens.
double _rigNameSize(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return (w * 0.031).clamp(11.0, 13.0);
}

double _rigMetaSize(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return (w * 0.023).clamp(8.0, 10.0);
}

String _formatMiningRateLine(String coinId, double rate) {
  final sym = coinId.toUpperCase();
  if (rate == 0) return '$sym —';
  if (rate.abs() < 1e-7) return '$sym ${rate.toStringAsExponential(2)}/min';
  if (rate < 0.01) return '$sym ${rate.toStringAsFixed(8)}/min';
  return '$sym ${rate.toStringAsFixed(6)}/min';
}

/// Bottom sheet: perks when buying this rig (tap card on Mining Farm).
void _showRigPerksSheet(
  BuildContext context, {
  required MiningRig rig,
  required _RigMeta meta,
  required int count,
  required bool isFull,
  required String? priceStrUsd,
  required bool storeHasLivePrice,
  required bool billingReady,
  required bool iapLoading,
  required VoidCallback? onBuyWithUsd,
  required double farmMiningMultiplier,
  OneTimeProduct? shopProduct,
}) {
  final perks = <String>[
    'Adds 1× this rig to your farm permanently (you can own many of the same type).',
    'Your farm tier multiplies all rigs — currently ×${farmMiningMultiplier.toStringAsFixed(2)} mining.',
    if (rig.supportedCoins.length <= 1 || rig.ratePerCoin.isEmpty)
      'Base output: ${_formatMiningRateLine('btc', rig.btcPerMin * MiningEconomy.outputScale)}'
    else
      'Multi-coin base rates (before farm multiplier):',
    ...() {
      if (rig.ratePerCoin.isEmpty) return <String>[];
      return rig.supportedCoins
          .map((c) => _formatMiningRateLine(c, rig.rateForCoin(c) * MiningEconomy.outputScale))
          .toList();
    }(),
    'Power draw ${rig.powerConsumption.toStringAsFixed(1)} · Heat ${rig.heatGeneration.toStringAsFixed(1)} (energy & cooling).',
    if (rig.upgradeLevels > 0)
      'This rig type can reach up to ${rig.upgradeLevels} upgrade levels over time.',
  ];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _D.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom + AppTheme.pageBottomPadding(ctx);
      return Padding(
        padding: EdgeInsets.fromLTRB(AppTheme.pagePaddingH, 12, AppTheme.pagePaddingH, bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _D.cardBord,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: meta.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: meta.accent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(meta.icon, color: meta.accent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rig.name,
                          style: const TextStyle(
                            color: _D.textHi,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        if (meta.tier.isNotEmpty)
                          Text(
                            meta.tier,
                            style: TextStyle(color: meta.accent, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        if (count > 0)
                          Text(
                            'You already own ×$count',
                            style: const TextStyle(color: _D.textMid, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if ((shopProduct?.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  shopProduct!.description,
                  style: const TextStyle(color: _D.textMid, fontSize: 13, height: 1.35),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'What you get',
                style: TextStyle(
                  color: _D.textHi,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              ...perks.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(Icons.check_circle_rounded, size: 16, color: _D.green),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(color: _D.textMid, fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (priceStrUsd != null) ...[
                const SizedBox(height: 8),
                Text(
                  storeHasLivePrice ? 'Price (Google Play)' : 'Estimated price',
                  style: const TextStyle(color: _D.textLow, fontSize: 11),
                ),
                Text(
                  priceStrUsd.startsWith('\$') ? priceStrUsd : '\$$priceStrUsd',
                  style: const TextStyle(
                    color: _D.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
              if (isFull)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Farm is at capacity — upgrade farm tier to add more rigs.',
                    style: TextStyle(color: _D.orange.withValues(alpha: 0.9), fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              if (onBuyWithUsd != null && !isFull)
                FilledButton.icon(
                  onPressed: iapLoading
                      ? null
                      : () {
                          Navigator.of(ctx).pop();
                          onBuyWithUsd();
                        },
                  icon: iapLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.shopping_cart_outlined, size: 20),
                  label: Text(
                    priceStrUsd == null
                        ? 'Buy with Google Play'
                        : 'Buy ${priceStrUsd.startsWith(r'$') ? priceStrUsd : '${r'$'}$priceStrUsd'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _D.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else if (!billingReady && !isFull && priceStrUsd != null)
                Text(
                  'Billing unavailable — check Google Play on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _D.textLow, fontSize: 12),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class MiningFarmScreen extends StatelessWidget {
  const MiningFarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game  = context.watch<GameStateService>();
    final iap   = context.watch<IapService>();
    final adCfg = context.watch<AdRemoteConfigService>();

    final counts = <String, int>{};
    for (final id in game.ownedRigIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }

    final capacityPct = game.rigCapacity > 0
        ? (game.ownedRigIds.length / game.rigCapacity).clamp(0.0, 1.0)
        : 0.0;
    final canUpgrade  = game.nextFarmTier != null;
    final canAffordUp = canUpgrade &&
        game.btcBalance >= game.nextFarmTier!.upgradeCostBtc;

    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            // Ambient glow
            Positioned(
              top: -60,
              right: -80,
              child: _Blob(color: _D.gold.withValues(alpha: 0.06), size: 320),
            ),
            Positioned(
              bottom: 80,
              left: -60,
              child: _Blob(color: _D.electric.withValues(alpha: 0.04), size: 260),
            ),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── App bar ────────────────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: _D.bg.withValues(alpha: 0.92),
                    surfaceTintColor: Colors.transparent,
                    title: Row(children: [
                      const Icon(Icons.warehouse_rounded, color: _D.gold, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'MINING FARM',
                        style: TextStyle(
                          color: _D.gold,
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ]),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(AppTheme.pagePaddingH, 8, AppTheme.pagePaddingH, AppTheme.pageBottomPadding(context)),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // ── Farm tier card ─────────────────────────────
                        _FarmTierCard(
                          game:         game,
                          capacityPct:  capacityPct,
                          canUpgrade:   canUpgrade,
                          canAffordUp:  canAffordUp,
                          context:      context,
                        ),
                        const SizedBox(height: 12),

                        // ── Stats row ──────────────────────────────────
                        _StatsRow(game: game),
                        const SizedBox(height: 20),

                        // ── Section label ──────────────────────────────
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AVAILABLE RIGS',
                                style: TextStyle(
                                  color: _D.textMid,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Buy rigs here with USD (Google Play). Prices update when the store loads.',
                                style: TextStyle(color: _D.textLow, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Rig cards (IAP USD only — no BTC) ─────────
                        ...MiningRigs.all.map((rig) {
                          final count   = counts[rig.id] ?? 0;
                          final product = ShopProducts.farmIapProductForRig(rig.id);
                          final storeProduct = product != null
                              ? iap.getProduct(product.googleProductId)
                              : null;
                          final catalogPrice = product?.price ?? '';
                          final livePrice = storeProduct?.price ?? '';
                          final priceStrUsd = livePrice.isNotEmpty
                              ? livePrice
                              : (catalogPrice.isNotEmpty ? catalogPrice : null);
                          final canTryIap = product != null &&
                              game.canBuyMoreRigs &&
                              iap.available;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RigCard(
                              rig:            rig,
                              count:          count,
                              isFull:         !game.canBuyMoreRigs,
                              priceStrUsd:    priceStrUsd,
                              storeHasLivePrice: storeProduct != null,
                              iapLoading:     iap.loading,
                              billingReady:   iap.available,
                              shopProduct:    product,
                              farmMiningMultiplier: game.currentFarmTier.miningMultiplier,
                              onBuyWithUsd:   product != null && canTryIap
                                  ? () async {
                                      final pid = product.googleProductId;
                                      if (iap.getProduct(pid) == null) {
                                        await iap.loadProducts();
                                      }
                                      if (!context.mounted) return;
                                      if (iap.getProduct(pid) == null) {
                                        _toast(
                                          context,
                                          iap.error ??
                                              'Could not load Google Play product "$pid". Create this ID in Play Console.',
                                        );
                                        return;
                                      }
                                      final ok = await iap.buyProduct(pid);
                                      if (context.mounted) {
                                        _toast(
                                          context,
                                          ok
                                              ? 'Complete purchase in Google Play'
                                              : (iap.error ?? 'Purchase failed'),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          );
                        }),

                        // ── Capacity warning ───────────────────────────
                        if (!game.canBuyMoreRigs) ...[
                          const SizedBox(height: 4),
                          _CapacityWarning(),
                          const SizedBox(height: 8),
                        ],

                        // ── Ads ────────────────────────────────────────
                        if (adCfg.adsActive) ...[
                          const SizedBox(height: 8),
                          const MinimizableNativeAd(title: 'Sponsored'),
                          const SizedBox(height: 10),
                          const Center(child: SmartBannerAd()),
                        ],
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

// ─── Farm tier card ───────────────────────────────────────────────────────────
class _FarmTierCard extends StatelessWidget {
  final GameStateService game;
  final double capacityPct;
  final bool canUpgrade;
  final bool canAffordUp;
  final BuildContext context;

  const _FarmTierCard({
    required this.game,
    required this.capacityPct,
    required this.canUpgrade,
    required this.canAffordUp,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) => Container(
    decoration: BoxDecoration(
      color: _D.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _D.cardBord, width: 1),
      boxShadow: [
        BoxShadow(
          color: _D.gold.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Stack(
      children: [
        // Corner glow
        Positioned(
          top: -20,
          right: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _D.gold.withValues(alpha: 0.07),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tier badge + name
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _D.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _D.gold.withValues(alpha: 0.35)),
                  ),
                  child: const Text(
                    'CURRENT TIER',
                    style: TextStyle(
                      color: _D.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  game.currentFarmTier.name,
                  style: const TextStyle(
                    color: _D.textHi,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                'Mining multiplier ×${game.currentFarmTier.miningMultiplier.toStringAsFixed(2)} (applies to all rigs)',
                style: const TextStyle(color: _D.textMid, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Capacity bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Capacity',
                      style: TextStyle(color: _D.textMid, fontSize: 12)),
                  Text(
                    '${game.ownedRigIds.length} / ${game.rigCapacity} rigs',
                    style: const TextStyle(
                      color: _D.textHi,
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: capacityPct,
                  minHeight: 6,
                  backgroundColor: _D.cardBord,
                  valueColor: AlwaysStoppedAnimation(
                    capacityPct >= 1.0 ? _D.orange : _D.gold,
                  ),
                ),
              ),

              // Upgrade button
              if (canUpgrade) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _UpgradeBtn(
                    cost:       game.nextFarmTier!.upgradeCostBtc,
                    canAfford:  canAffordUp,
                    onTap: () async {
                      await game.upgradeFarm();
                      if (context.mounted) {
                        _toast(context,
                            '🏭 Farm upgraded to ${game.currentFarmTier.name}');
                      }
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                const Row(children: [
                  Icon(Icons.workspace_premium_rounded, color: _D.gold, size: 14),
                  SizedBox(width: 6),
                  Text('Maximum tier reached',
                      style: TextStyle(color: _D.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── Stats row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final GameStateService game;
  const _StatsRow({required this.game});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _StatTile(
          icon:   Icons.speed_rounded,
          label:  'Hash Power',
          value:  '${game.totalBtcPerMin.toStringAsFixed(8)}',
          unit:   'BTC/min',
          accent: _D.green,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatTile(
          icon:   Icons.memory_rounded,
          label:  'Total Rigs',
          value:  '${game.ownedRigIds.length}',
          unit:   'units',
          accent: _D.electric,
        ),
      ),
    ],
  );
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accent;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _D.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _D.cardBord),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: accent, size: 18),
      const SizedBox(height: 10),
      Text(
        value,
        style: TextStyle(
          color: accent,
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      Text(unit, style: const TextStyle(color: _D.textMid, fontSize: 11)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _D.textLow, fontSize: 11)),
    ]),
  );
}

// ─── Rig card (IAP USD only) ─────────────────────────────────────────────────
class _RigCard extends StatelessWidget {
  final MiningRig rig;
  final int count;
  final bool isFull;
  final String? priceStrUsd;
  /// Play Billing returned a price for this SKU.
  final bool storeHasLivePrice;
  final bool iapLoading;
  final bool billingReady;
  final OneTimeProduct? shopProduct;
  final double farmMiningMultiplier;
  final VoidCallback? onBuyWithUsd;

  const _RigCard({
    required this.rig,
    required this.count,
    required this.isFull,
    this.priceStrUsd,
    required this.storeHasLivePrice,
    required this.iapLoading,
    required this.billingReady,
    this.shopProduct,
    required this.farmMiningMultiplier,
    this.onBuyWithUsd,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _metaForRig(rig.id);

    return Container(
      decoration: BoxDecoration(
        color: count > 0
            ? meta.accent.withValues(alpha: 0.05)
            : _D.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: count > 0
              ? meta.accent.withValues(alpha: 0.25)
              : _D.cardBord,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Tappable: open perks (buy button is outside this gesture)
            Expanded(
              child: GestureDetector(
                onTap: () => _showRigPerksSheet(
                  context,
                  rig: rig,
                  meta: meta,
                  count: count,
                  isFull: isFull,
                  priceStrUsd: priceStrUsd,
                  storeHasLivePrice: storeHasLivePrice,
                  billingReady: billingReady,
                  iapLoading: iapLoading,
                  onBuyWithUsd: onBuyWithUsd,
                  farmMiningMultiplier: farmMiningMultiplier,
                  shopProduct: shopProduct,
                ),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: meta.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: meta.accent.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(meta.icon, color: meta.accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      rig.name,
                      maxLines: 1,
                      style: TextStyle(
                        color: _D.textHi,
                        fontWeight: FontWeight.w700,
                        fontSize: _rigNameSize(context),
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (meta.tier.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: meta.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        meta.tier,
                        style: TextStyle(
                          color: meta.accent,
                          fontSize: _rigMetaSize(context),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: meta.accent, size: 11),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${(rig.btcPerMin * MiningEconomy.outputScale)} BTC/min',
                          style: TextStyle(
                            color: meta.accent,
                            fontFamily: AppTheme.fontFamily,
                            fontSize: _rigMetaSize(context) + 1,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _D.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'USD',
                          style: TextStyle(
                            color: _D.green,
                            fontSize: _rigMetaSize(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),

            const SizedBox(width: 8),

            // Right: count + IAP (USD) only — flexible width to avoid Row overflow
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                if (count > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: meta.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: meta.accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '×$count',
                      style: TextStyle(
                        color: meta.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                if (isFull)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      'Farm full',
                      style: const TextStyle(color: _D.textLow, fontSize: 11),
                    ),
                  )
                else if (priceStrUsd == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text('—', style: TextStyle(color: _D.textLow, fontSize: 11)),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!billingReady)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Billing unavailable',
                            style: TextStyle(color: _D.textLow, fontSize: 10),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      SizedBox(
                        height: 36,
                        child: onBuyWithUsd != null
                            ? FilledButton.icon(
                                onPressed: (isFull || iapLoading) ? null : onBuyWithUsd,
                                icon: iapLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.shopping_cart_outlined, size: 16),
                                label: Text(
                                  priceStrUsd!.startsWith('\$') ? priceStrUsd! : '\$$priceStrUsd',
                                  style: TextStyle(fontSize: _rigNameSize(context), fontWeight: FontWeight.w700),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _D.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                                label: Text(
                                  priceStrUsd!.startsWith('\$') ? priceStrUsd! : '\$$priceStrUsd',
                                  style: TextStyle(fontSize: _rigNameSize(context), fontWeight: FontWeight.w700),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _D.green.withValues(alpha: 0.45),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                      ),
                      if (!storeHasLivePrice && billingReady && !isFull && onBuyWithUsd != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Estimated — opens Google Play',
                            style: TextStyle(color: _D.textLow, fontSize: 9),
                            textAlign: TextAlign.end,
                          ),
                        ),
                    ],
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

// ─── Upgrade button ───────────────────────────────────────────────────────────
class _UpgradeBtn extends StatefulWidget {
  final double cost;
  final bool canAfford;
  final VoidCallback onTap;
  const _UpgradeBtn({required this.cost, required this.canAfford, required this.onTap});

  @override
  State<_UpgradeBtn> createState() => _UpgradeBtnState();
}

class _UpgradeBtnState extends State<_UpgradeBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.canAfford ? (_) => setState(() => _pressed = true) : null,
    onTapUp: widget.canAfford ? (_) { setState(() => _pressed = false); widget.onTap(); } : null,
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: widget.canAfford
              ? const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE08800)])
              : null,
          color: widget.canAfford ? null : _D.cardBord,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.canAfford
              ? [BoxShadow(
            color: _D.gold.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )]
              : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            Icons.upgrade_rounded,
            color: widget.canAfford ? Colors.black : _D.textLow,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Upgrade farm  ·  ${widget.cost} BTC',
            style: TextStyle(
              color: widget.canAfford ? Colors.black : _D.textLow,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ]),
      ),
    ),
  );
}

// ─── Capacity warning ─────────────────────────────────────────────────────────
class _CapacityWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _D.orange.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _D.orange.withValues(alpha: 0.3)),
    ),
    child: const Row(children: [
      Icon(Icons.warning_amber_rounded, color: _D.orange, size: 16),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          'Farm capacity reached — upgrade to add more rigs.',
          style: TextStyle(color: _D.orange, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    ]),
  );
}

// ─── Shared ───────────────────────────────────────────────────────────────────
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