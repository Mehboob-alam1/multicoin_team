import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mining_rig.dart';
import '../services/ad_remote_config_service.dart';
import '../services/game_state_service.dart';
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
  _                 => const _RigMeta(Icons.hardware_rounded,      _D.textMid,        ''),
};

// ─── Screen ───────────────────────────────────────────────────────────────────
class MiningFarmScreen extends StatelessWidget {
  const MiningFarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game  = context.watch<GameStateService>();
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            Text(
                              'AVAILABLE RIGS',
                              style: TextStyle(
                                color: _D.textMid,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ]),
                        ),

                        // ── Rig cards ──────────────────────────────────
                        ...MiningRigs.all.map((rig) {
                          final count  = counts[rig.id] ?? 0;
                          final cost   = game.rigCost(rig);
                          final canBuy = rig.costBtc > 0 &&
                              game.canAfford(rig) &&
                              game.canBuyMoreRigs;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RigCard(
                              rig:     rig,
                              count:   count,
                              cost:    cost,
                              canBuy:  canBuy,
                              isFull:  !game.canBuyMoreRigs,
                              onBuy: () async {
                                await game.buyRig(rig);
                                if (context.mounted) {
                                  _toast(context, '${rig.name} added to farm');
                                }
                              },
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
                'Mining multiplier ×${game.currentFarmTier.miningMultiplier.toStringAsFixed(2)}',
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

// ─── Rig card ─────────────────────────────────────────────────────────────────
class _RigCard extends StatelessWidget {
  final MiningRig rig;
  final int count;
  final double cost;
  final bool canBuy;
  final bool isFull;
  final VoidCallback onBuy;

  const _RigCard({
    required this.rig,
    required this.count,
    required this.cost,
    required this.canBuy,
    required this.isFull,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final meta     = _metaForRig(rig.id);
    final isStarter = rig.costBtc <= 0;

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
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: meta.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: meta.accent.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Icon(meta.icon, color: meta.accent, size: 22),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        rig.name,
                        style: const TextStyle(
                          color: _D.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (meta.tier.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: meta.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          meta.tier,
                          style: TextStyle(
                            color: meta.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.bolt_rounded, color: meta.accent, size: 12),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${rig.btcPerMin} BTC/min',
                        style: TextStyle(
                          color: meta.accent,
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isStarter) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.currency_bitcoin, color: _D.textMid, size: 12),
                      Flexible(
                        child: Text(
                          cost.toStringAsFixed(6),
                          style: const TextStyle(
                            color: _D.textMid,
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right side: count badge + buy btn
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
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
                if (isStarter)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _D.cardBord,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Starter',
                      style: TextStyle(color: _D.textLow, fontSize: 11),
                    ),
                  )
                else
                  _BuyBtn(
                    canBuy: canBuy,
                    isFull: isFull,
                    onTap: onBuy,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Buy button ───────────────────────────────────────────────────────────────
class _BuyBtn extends StatefulWidget {
  final bool canBuy;
  final bool isFull;
  final VoidCallback onTap;
  const _BuyBtn({required this.canBuy, required this.isFull, required this.onTap});

  @override
  State<_BuyBtn> createState() => _BuyBtnState();
}

class _BuyBtnState extends State<_BuyBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.isFull ? 'Full' : 'Buy';
    return GestureDetector(
      onTapDown: widget.canBuy ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.canBuy ? (_) { setState(() => _pressed = false); widget.onTap(); } : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.canBuy
                ? const LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFE08800)])
                : null,
            color: widget.canBuy ? null : _D.cardBord,
            borderRadius: BorderRadius.circular(9),
            boxShadow: widget.canBuy
                ? [BoxShadow(
              color: _D.gold.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: widget.canBuy ? Colors.black : _D.textLow,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
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