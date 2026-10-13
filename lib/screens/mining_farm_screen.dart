import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/mining_economy.dart';
import '../models/mining_rig.dart';
import '../models/shop_product.dart';
import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_ad_slot.dart';

class _D {
  static const bg = Color(0xFF08080A);
  static const surface = Color(0xFF18181C);
  static const surfaceAlt = Color(0xFF111114);
  static const chip = Color(0xFF1C1C22);
  static const cardBord = Color(0x1FFFFFFF);
  static const hairline = Color(0x14FFFFFF);

  static const gold = Color(0xFF9945FF);
  static const goldText = Color(0xFFE9D5FF);
  static const goldBg = Color(0xFF1A1228);
  static const goldBdr = Color(0x669945FF);

  static const green = Color(0xFF14F195);
  static const greenText = Color(0xFFBBF7D0);
  static const greenBg = Color(0xFF0A2E22);
  static const greenBdr = Color(0x6614F195);

  static const electric = Color(0xFF38BDF8);
  static const electricBg = Color(0xFF0C1A24);
  static const electricBdr = Color(0xFF164E63);

  static const violet = Color(0xFFA78BFA);
  static const orange = Color(0xFFF97316);
  static const rose = Color(0xFFF43F5E);

  static const textHi = Color(0xFFF4F4F5);
  static const textMid = Color(0xFFA1A1AA);
  static const textLow = Color(0xFF71717A);
}

TextStyle _sg({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _D.textHi,
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

TextStyle _mono({
  double size = 13,
  FontWeight weight = FontWeight.w600,
  Color color = _D.textHi,
}) =>
    GoogleFonts.spaceMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.15,
    );

class _RigMeta {
  final IconData icon;
  final Color accent;
  final Color tint;
  final Color border;
  final String tier;
  const _RigMeta(this.icon, this.accent, this.tint, this.border, this.tier);
}

_RigMeta _metaForRig(String id) => switch (id) {
  'laptop' || 'cpu_miner' => const _RigMeta(
      Icons.laptop_mac_rounded, _D.textMid, _D.chip, _D.cardBord, 'Tier I'),
  'gpu_rig' || 'gaming_gpu_rig' => const _RigMeta(
      Icons.memory_rounded, _D.green, _D.greenBg, _D.greenBdr, 'Tier II'),
  'mining_rack' || 'gpu_cluster' => const _RigMeta(
      Icons.view_module_rounded, _D.electric, _D.electricBg, _D.electricBdr, 'Tier III'),
  'warehouse_farm' || 'asic_btc' => const _RigMeta(
      Icons.warehouse_rounded, _D.gold, _D.goldBg, _D.goldBdr, 'Tier IV'),
  'mega_facility' || 'data_center_rig' => const _RigMeta(
      Icons.auto_awesome_rounded, _D.violet, Color(0xFF1A1228), Color(0xFF4C1D95), 'Tier V'),
  _ => const _RigMeta(
      Icons.hardware_rounded, _D.textMid, _D.chip, _D.cardBord, ''),
};

double _nameSize(BuildContext context) =>
    (MediaQuery.sizeOf(context).width * 0.036).clamp(13.0, 16.0);

String _money(String raw) {
  final price = raw.trim();
  if (price.isEmpty) return '—';
  return RegExp(r'^[0-9]').hasMatch(price) ? '\$$price' : price;
}

String _rate(double value) {
  if (value == 0) return '0 SOL/min';
  if (value.abs() < 1e-7) return '${value.toStringAsExponential(2)} SOL/min';
  if (value < 0.01) return '${value.toStringAsFixed(8)} SOL/min';
  return '${value.toStringAsFixed(6)} SOL/min';
}

double _scaledRate(MiningRig rig) => rig.btcPerMin * MiningEconomy.outputScale;

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
  final rate = _scaledRate(rig);
  final perks = <String>[
    'Adds this validator permanently. You can own more than one of the same type.',
    'Farm tier multiplies every rig. Current multiplier ×${farmMiningMultiplier.toStringAsFixed(2)}.',
    'Base output ${_rate(rate)}.',
    'Power draw ${rig.powerConsumption.toStringAsFixed(1)} · heat ${rig.heatGeneration.toStringAsFixed(1)}.',
    if (rig.upgradeLevels > 0)
      'This rig can be upgraded up to ${rig.upgradeLevels} levels.',
  ];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom + 18;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Container(
            decoration: const BoxDecoration(
              color: Color(0xF2111114),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(top: BorderSide(color: Color(0x2EFFFFFF))),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 12, 22, bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _IconTile(meta: meta, size: 58, iconSize: 27),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rig.name, style: _sg(size: 20, weight: FontWeight.w700, letterSpacing: -0.4)),
                              const SizedBox(height: 3),
                              Text(
                                meta.tier.isEmpty ? 'Validator rig' : meta.tier,
                                style: _sg(size: 12, weight: FontWeight.w700, color: meta.accent),
                              ),
                              if (count > 0)
                                Text('Already owned ×$count', style: _sg(size: 12, color: _D.textMid)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if ((shopProduct?.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(shopProduct!.description, style: _sg(size: 13.5, color: _D.textMid, height: 1.45)),
                    ],
                    const SizedBox(height: 20),
                    Text('INCLUDED', style: _sg(size: 10, weight: FontWeight.w700, color: _D.textLow, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    ...perks.map(
                          (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 16, color: _D.green),
                            const SizedBox(width: 10),
                            Expanded(child: Text(line, style: _sg(size: 13.5, color: _D.textMid, height: 1.35))),
                          ],
                        ),
                      ),
                    ),
                    if (priceStrUsd != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _D.greenBg.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _D.greenBdr),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                storeHasLivePrice ? 'Google Play price' : 'Estimated price',
                                style: _sg(size: 12, color: _D.greenText),
                              ),
                            ),
                            Text(_money(priceStrUsd), style: _mono(size: 18, weight: FontWeight.w700, color: _D.green)),
                          ],
                        ),
                      ),
                    ],
                    if (isFull)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Farm is full. Upgrade the farm tier before adding another rig.',
                          style: _sg(size: 12.5, color: _D.orange, height: 1.35),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (onBuyWithUsd != null && !isFull)
                      _GradientButton(
                        label: priceStrUsd == null ? 'Buy with Google Play' : 'Buy ${_money(priceStrUsd)}',
                        icon: Icons.shopping_bag_outlined,
                        loading: iapLoading,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          onBuyWithUsd();
                        },
                      )
                    else if (!billingReady && !isFull && priceStrUsd != null)
                      Text(
                        'Billing is unavailable on this device.',
                        textAlign: TextAlign.center,
                        style: _sg(size: 12, color: _D.textLow),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Close', style: _sg(size: 13, weight: FontWeight.w600, color: _D.textMid)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      );
    },
  );
}

class MiningFarmScreen extends StatelessWidget {
  const MiningFarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final iap = context.watch<IapService>();
    final adCfg = context.watch<AdRemoteConfigService>();

    final counts = <String, int>{};
    for (final id in game.ownedRigIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }

    final capacityPct = game.rigCapacity > 0
        ? (game.ownedRigIds.length / game.rigCapacity).clamp(0.0, 1.0)
        : 0.0;
    final canUpgrade = game.nextFarmTier != null;
    final upgradeCost = canUpgrade ? MiningEconomy.toSol(game.nextFarmTier!.upgradeCostBtc) : 0.0;
    final canAffordUp = canUpgrade && game.btcBalance >= upgradeCost;

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
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: const Color(0xCC08080A),
                    surfaceTintColor: Colors.transparent,
                    toolbarHeight: 68,
                    flexibleSpace: const ColoredBox(color: Color(0xF208080A)),
                    title: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _D.goldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _D.goldBdr),
                          ),
                          child: const Icon(Icons.warehouse_rounded, color: _D.gold, size: 18),
                        ),
                        const SizedBox(width: 11),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (r) => const LinearGradient(
                                colors: [Color(0xFF9945FF), Color(0xFF14F195)],
                              ).createShader(r),
                              child: Text('Mining Farm', style: _sg(size: 16, weight: FontWeight.w700, letterSpacing: -0.3, color: Colors.white)),
                            ),
                            Text('VALIDATORS', style: _sg(size: 9, weight: FontWeight.w700, color: _D.gold, letterSpacing: 1.6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, AppTheme.pageBottomPadding(context)),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _FarmHero(
                          game: game,
                          capacityPct: capacityPct,
                          canUpgrade: canUpgrade,
                          canAfford: canAffordUp,
                          upgradeCost: upgradeCost,
                        ),
                        const SizedBox(height: 12),
                        _SessionBar(game: game),
                        const SizedBox(height: 12),
                        _StatsRow(game: game),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(color: _D.gold, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 10),
                            Text('AVAILABLE RIGS', style: _sg(size: 10, weight: FontWeight.w700, color: _D.textMid, letterSpacing: 1.5)),
                            const Spacer(),
                            Text('${counts.length} owned', style: _sg(size: 11, color: _D.textLow)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap a rig for details. Purchases open in Google Play.',
                          style: _sg(size: 12, color: _D.textLow, height: 1.35),
                        ),
                        const SizedBox(height: 14),
                        ...MiningRigs.all.map((rig) {
                          final product = ShopProducts.farmIapProductForRig(rig.id);
                          final storeProduct = product == null ? null : iap.getProduct(product.googleProductId);
                          final catalogPrice = product?.price ?? '';
                          final livePrice = storeProduct?.price ?? '';
                          final price = livePrice.isNotEmpty
                              ? livePrice
                              : (catalogPrice.isNotEmpty ? catalogPrice : null);
                          final canTryIap = product != null && game.canBuyMoreRigs && iap.available;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RigCard(
                              rig: rig,
                              count: counts[rig.id] ?? 0,
                              isFull: !game.canBuyMoreRigs,
                              priceStrUsd: price,
                              storeHasLivePrice: storeProduct != null,
                              iapLoading: iap.loading,
                              billingReady: iap.available,
                              shopProduct: product,
                              farmMiningMultiplier: game.currentFarmTier.miningMultiplier,
                              onBuyWithUsd: product != null && canTryIap
                                  ? () async {
                                HapticFeedback.lightImpact();
                                final pid = product.googleProductId;
                                if (iap.getProduct(pid) == null) await iap.loadProducts();
                                if (!context.mounted) return;
                                if (iap.getProduct(pid) == null) {
                                  _toast(
                                    context,
                                    iap.error ?? 'Could not load Google Play product "$pid". Create this ID in Play Console.',
                                  );
                                  return;
                                }
                                final ok = await iap.buyProduct(pid);
                                if (context.mounted) {
                                  _toast(context, ok ? 'Complete purchase in Google Play' : (iap.error ?? 'Purchase failed'));
                                }
                              }
                                  : null,
                            ),
                          );
                        }),
                        if (!game.canBuyMoreRigs) ...[
                          const SizedBox(height: 2),
                          const _CapacityWarning(),
                        ],
                        if (adCfg.shouldShowSdkAds && !game.isPremiumActive) ...[
                          const SizedBox(height: 16),
                          const ScreenAdSlot(title: 'Farm offer'),
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

class _SessionBar extends StatelessWidget {
  final GameStateService game;
  const _SessionBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final active = game.isSessionActive;
    final left = game.sessionTimeLeft;
    final mins = left.inMinutes;
    final secs = left.inSeconds % 60;
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        if (active) {
          await game.stopMiningSession();
        } else {
          await game.startMiningSession();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? _D.greenBg : _D.goldBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? _D.greenBdr : _D.goldBdr),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
              color: active ? _D.green : _D.gold,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    active ? 'Mining session live' : 'Start mining session',
                    style: _sg(size: 14, weight: FontWeight.w700, color: active ? _D.greenText : _D.goldText),
                  ),
                  Text(
                    active
                        ? '1.25× boost · ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} left · tap to stop'
                        : 'Earn 1.25× SOL for 30 minutes',
                    style: _sg(size: 11.5, color: _D.textMid),
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

class _FarmHero extends StatelessWidget {
  final GameStateService game;
  final double capacityPct;
  final bool canUpgrade;
  final bool canAfford;
  final double upgradeCost;

  const _FarmHero({
    required this.game,
    required this.capacityPct,
    required this.canUpgrade,
    required this.canAfford,
    required this.upgradeCost,
  });

  @override
  Widget build(BuildContext context) {
    final meter = capacityPct >= 1
        ? _D.rose
        : capacityPct > 0.72
        ? _D.orange
        : _D.gold;
    final shortfall = upgradeCost - game.btcBalance;

    return _Glass(
      radius: 28,
      tint: const Color(0xC01A1228),
      border: _D.goldBdr,
      glow: [
        BoxShadow(color: _D.gold.withValues(alpha: 0.16), blurRadius: 30, offset: const Offset(0, 12)),
      ],
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _D.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _D.goldBdr),
                ),
                child: Text('CURRENT TIER', style: _sg(size: 9, weight: FontWeight.w700, color: _D.goldText, letterSpacing: 1.1)),
              ),
              const Spacer(),
              if (game.isSessionActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: _D.greenBg,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _D.greenBdr),
                  ),
                  child: Text('LIVE', style: _sg(size: 9, weight: FontWeight.w800, color: _D.greenText, letterSpacing: 0.8)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(game.currentFarmTier.name, style: _sg(size: 28, weight: FontWeight.w700, letterSpacing: -0.8)),
          const SizedBox(height: 4),
          Text(
            'All rigs multiplied by ×${game.currentFarmTier.miningMultiplier.toStringAsFixed(2)}',
            style: _sg(size: 13, color: _D.textMid),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Capacity', style: _sg(size: 12, color: _D.textMid)),
              const Spacer(),
              Text(
                '${game.ownedRigIds.length} / ${game.rigCapacity}',
                style: _mono(size: 12, color: _D.textHi),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: capacityPct,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: meter,
            ),
          ),
          const SizedBox(height: 16),
          if (canUpgrade)
            _GradientButton(
              label: 'Upgrade · ${upgradeCost.toStringAsFixed(3)} SOL',
              icon: Icons.upgrade_rounded,
              enabled: canAfford,
              onTap: () async {
                HapticFeedback.mediumImpact();
                await game.upgradeFarm();
                if (context.mounted) _toast(context, 'Farm upgraded to ${game.currentFarmTier.name}');
              },
            )
          else
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: _D.gold, size: 16),
                const SizedBox(width: 7),
                Text('Maximum tier reached', style: _sg(size: 13, weight: FontWeight.w700, color: _D.goldText)),
              ],
            ),
          if (canUpgrade && !canAfford) ...[
            const SizedBox(height: 8),
            Text(
              'Need ${shortfall.toStringAsFixed(3)} more SOL',
              style: _sg(size: 12, color: _D.textLow),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final GameStateService game;
  const _StatsRow({required this.game});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.speed_rounded,
              label: 'Hash power',
              value: game.totalBtcPerMin.toStringAsFixed(8),
              unit: 'SOL/min',
              color: _D.green,
              tint: _D.greenBg,
              border: _D.greenBdr,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              icon: Icons.memory_rounded,
              label: 'Installed',
              value: '${game.ownedRigIds.length}',
              unit: 'rigs',
              color: _D.electric,
              tint: _D.electricBg,
              border: _D.electricBdr,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color tint;
  final Color border;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.tint,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: const EdgeInsets.all(15),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 132),
        child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 12),
            Text(label, style: _sg(size: 11, color: _D.textMid)),
            const SizedBox(height: 3),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: _mono(size: 13, color: color)),
            Text(unit, style: _sg(size: 10, color: _D.textLow)),
          ],
        ),
        ),
      ),
    );
  }
}

class _RigCard extends StatelessWidget {
  final MiningRig rig;
  final int count;
  final bool isFull;
  final String? priceStrUsd;
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
    required this.priceStrUsd,
    required this.storeHasLivePrice,
    required this.iapLoading,
    required this.billingReady,
    required this.shopProduct,
    required this.farmMiningMultiplier,
    required this.onBuyWithUsd,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _metaForRig(rig.id);
    return _Glass(
      tint: count > 0 ? meta.tint.withValues(alpha: 0.78) : const Color(0xB318181C),
      border: count > 0 ? meta.border : _D.cardBord,
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
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
              child: Row(
                children: [
                  _IconTile(meta: meta, badge: count > 0 ? '×$count' : null),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rig.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _sg(size: _nameSize(context), weight: FontWeight.w700, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 3),
                        Text(meta.tier.isEmpty ? 'Validator' : meta.tier, style: _sg(size: 11, weight: FontWeight.w700, color: meta.accent)),
                        const SizedBox(height: 5),
                        Text(_rate(_scaledRate(rig)), maxLines: 1, overflow: TextOverflow.ellipsis, style: _mono(size: 10.5, color: _D.textMid)),
                        const SizedBox(height: 2),
                        Text(
                          'Power ${rig.powerConsumption.toStringAsFixed(0)} · Heat ${rig.heatGeneration.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _sg(size: 10.5, color: _D.textLow),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _BuyCluster(
            price: priceStrUsd,
            isFull: isFull,
            loading: iapLoading,
            billingReady: billingReady,
            storeHasLivePrice: storeHasLivePrice,
            onBuy: onBuyWithUsd,
          ),
        ],
      ),
    );
  }
}

class _BuyCluster extends StatelessWidget {
  final String? price;
  final bool isFull;
  final bool loading;
  final bool billingReady;
  final bool storeHasLivePrice;
  final VoidCallback? onBuy;

  const _BuyCluster({
    required this.price,
    required this.isFull,
    required this.loading,
    required this.billingReady,
    required this.storeHasLivePrice,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    if (isFull) return Text('Full', style: _sg(size: 12, weight: FontWeight.w700, color: _D.orange));
    if (price == null) return Text('—', style: _sg(size: 12, color: _D.textLow));

    final enabled = onBuy != null && !loading;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: enabled ? onBuy : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: enabled || loading ? 1 : 0.45,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_money(price!), style: _sg(size: 12.5, weight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            !billingReady
                ? 'Unavailable'
                : storeHasLivePrice
                ? 'Play Store'
                : 'Estimated',
            style: _sg(size: 9, color: _D.textLow),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final _RigMeta meta;
  final double size;
  final double iconSize;
  final String? badge;

  const _IconTile({
    required this.meta,
    this.size = 48,
    this.iconSize = 22,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: meta.tint,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: meta.border),
          ),
          child: Icon(meta.icon, color: meta.accent, size: iconSize),
        ),
        if (badge != null)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: meta.accent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(badge!, style: _sg(size: 8, weight: FontWeight.w800, color: Colors.black)),
            ),
          ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: active ? 1 : 0.42,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF9945FF), Color(0xFF14F195)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [BoxShadow(color: _D.gold.withValues(alpha: 0.24), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: loading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _sg(size: 14, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapacityWarning extends StatelessWidget {
  const _CapacityWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _D.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _D.orange.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _D.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Farm capacity reached. Upgrade the tier to install more rigs.',
              style: _sg(size: 12.5, weight: FontWeight.w600, color: _D.orange, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final Color? border;
  final List<BoxShadow>? glow;

  const _Glass({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 24,
    this.tint,
    this.border,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow ??
            [
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
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tint ?? const Color(0xF21F1F26),
                      const Color(0xE6121216),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: border ?? const Color(0x2DFFFFFF), width: 0.8),
                ),
              ),
            ),
            Padding(
              padding: padding,
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
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    glow(Offset(size.width * 0.92, 30), 190, const Color(0x389945FF));
    glow(Offset(-10, size.height * 0.34), 170, const Color(0x2414F195));
    glow(Offset(size.width * 0.45, size.height * 0.78), 210, const Color(0x1838BDF8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: _sg(size: 13, weight: FontWeight.w600)),
      backgroundColor: _D.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _D.cardBord),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}

ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(primary: _D.gold, surface: _D.surfaceAlt),
);