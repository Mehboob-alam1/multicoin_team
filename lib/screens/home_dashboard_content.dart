import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/btc_price_service.dart';
import '../services/game_state_service.dart';
import '../services/referral_service.dart';
import '../services/weekly_challenge_service.dart';
import '../services/lucky_spin_service.dart';
import '../theme/app_theme.dart';
import '../theme/home_theme.dart';
import '../theme/solana.dart';
import '../widgets/btc_price_chart.dart';
import '../widgets/solana_widgets.dart';

class _NoBlur extends StatelessWidget {
  const _NoBlur({required this.filter, required this.child, this.blendMode});
  final ImageFilter filter;
  final Widget child;
  final BlendMode? blendMode;
  @override
  Widget build(BuildContext context) => child;
}

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _HT {
  // Backgrounds
  static const pageBg     = Color(0xFF08080A);
  static const surface    = Color(0xFF18181C);
  static const surfaceAlt = Color(0xFF111114);
  static const chipBg     = Color(0xFF1C1C22);

  // Borders & Glass
  static const border     = Color(0x1FFFFFFF);
  static const borderSub  = Color(0x14FFFFFF);
  static const glassBorder = Color(0x2DFFFFFF);

  // Lime (primary)
  static const lime       = Color(0xFF14F195);
  static const limeText   = Color(0xFFBBF7D0);
  static const limeBg     = Color(0xFF0A2E22);
  static const limeBdr    = Color(0x6614F195);

  // Accent colors
  static const amber      = Color(0xFF9945FF);
  static const amberText  = Color(0xFFE9D5FF);
  static const amberBg    = Color(0xFF1A1228);
  static const amberBdr   = Color(0x669945FF);

  static const blue       = Color(0xFF38BDF8);
  static const blueText   = Color(0xFFBAE6FD);
  static const blueBg     = Color(0xFF0C1A24);
  static const blueBdr    = Color(0xFF164E63);

  static const violet     = Color(0xFFA78BFA);
  static const violetText = Color(0xFFDDD6FE);
  static const violetBg   = Color(0xFF1A1228);
  static const violetBdr  = Color(0xFF4C1D95);

  static const rose       = Color(0xFFF43F5E);
  static const roseBg     = Color(0xFF3F1219);
  static const roseBdr    = Color(0xFF881337);

  // Text
  static const ink        = Color(0xFFF4F4F5);
  static const inkMid     = Color(0xFFA1A1AA);
  static const inkFaint   = Color(0xFF71717A);

  // Radii
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r10 = BorderRadius.all(Radius.circular(10));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));
  static const r28 = BorderRadius.all(Radius.circular(28));

  // Spacing
  static const px  = 20.0;
  static const gap = 12.0;
  static const sec = 28.0;
}

// ─── Typography ───────────────────────────────────────────────────────────────
TextStyle _label({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _HT.ink,
  double? letterSpacing,
  double? height,
}) => GoogleFonts.spaceGrotesk(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: letterSpacing ?? -0.2,
  height: height,
);

TextStyle _mono({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _HT.ink,
}) => GoogleFonts.spaceMono(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: -0.3,
);

// ─── Glassmorphism Container ──────────────────────────────────────────────────
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? radius;
  final double opacity;
  final Color? tintColor;
  final List<BoxShadow>? shadows;

  const _GlassContainer({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius,
    this.opacity = 0.08,
    this.tintColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: tintColor?.withOpacity(0.82) ?? _HT.surface.withOpacity(0.82),
            borderRadius: radius ?? _HT.r20,
            border: Border.all(color: _HT.glassBorder, width: 0.8),
            boxShadow: shadows ?? [
              BoxShadow(
                color: Colors.white.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: padding,
          child: child,
    );
  }
}

// ─── Balance hero: SOL balance, USD below, BTC price + arrow on right ─────────
class HomeBalanceHero extends StatelessWidget {
  final double btcBalance;
  final double? worthUsd;
  final BtcPriceService priceService;

  const HomeBalanceHero({
    super.key,
    required this.btcBalance,
    this.worthUsd,
    required this.priceService,
  });

  @override
  Widget build(BuildContext context) {
    final price = priceService.priceUsd;
    final change24h = priceService.priceChange24h;
    final isUp = priceService.isPriceUp;
    final parts = btcBalance.toStringAsFixed(12).split('.');

    return ClipRRect(
      borderRadius: _HT.r28,
      child: _NoBlur(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: _HT.r28,
            gradient: Solana.brand,
            boxShadow: [
              BoxShadow(
                color: _HT.lime.withOpacity(0.25),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: _HT.lime.withOpacity(0.08),
                blurRadius: 80,
                offset: const Offset(-20, -20),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: Container(
            decoration: const BoxDecoration(
              gradient: Solana.cardWash,
              borderRadius: BorderRadius.all(Radius.circular(27)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOL MINING BALANCE',
                          style: _label(
                            size: 11,
                            weight: FontWeight.w600,
                            color: _HT.inkMid,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                parts[0],
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  color: _HT.lime,
                                  height: 1.0,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              Text(
                                '.${parts[1]}',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _HT.lime,
                                  height: 1.2,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8, left: 8),
                                child: Text(
                                  'SOL',
                                  style: _label(
                                    size: 13,
                                    weight: FontWeight.w600,
                                    color: _HT.inkMid,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 14,
                              color: _HT.inkMid,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              worthUsd != null
                                  ? '≈ ${worthUsd!.toStringAsFixed(2)} USD'
                                  : '≈ — USD',
                              style: _label(size: 13, color: _HT.inkMid),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _PriceBox(
                    price: price,
                    change24h: change24h,
                    isUp: isUp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Price Box Component ───────────────────────────────────────────────────────
class _PriceBox extends StatelessWidget {
  final double? price;
  final double? change24h;
  final bool isUp;

  const _PriceBox({
    required this.price,
    required this.change24h,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _HT.r16,
      child: _NoBlur(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: _HT.lime.withOpacity(0.1),
            borderRadius: _HT.r16,
            border: Border.all(color: _HT.limeBdr, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SOL PRICE',
                style: _label(
                  size: 9,
                  weight: FontWeight.w700,
                  color: _HT.inkMid,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              if (price != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_money, size: 14, color: _HT.lime),
                    Text(
                      price!.toStringAsFixed(0),
                      style: _mono(
                        size: 15,
                        weight: FontWeight.w700,
                        color: _HT.lime,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isUp
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      color: isUp ? _HT.lime : _HT.rose,
                      size: 26,
                    ),
                  ],
                ),
                if (change24h != null)
                  Text(
                    '${change24h! >= 0 ? '+' : ''}${change24h!.toStringAsFixed(2)}% 24h',
                    style: _label(
                      size: 10,
                      weight: FontWeight.w600,
                      color: isUp ? _HT.lime : _HT.rose,
                    ),
                  ),
              ] else
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _HT.lime,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Three vertical cards: Difficulty, Network, Reward ───────────────────────
class HomeThreeStatsRow extends StatelessWidget {
  const HomeThreeStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HomeMiniCard(
            title: 'Cluster',
            value: 'Mainnet',
            icon: Icons.tune_rounded,
            color: _HT.blue,
            bg: _HT.blueBg,
            bdr: _HT.blueBdr,
          ),
        ),
        const SizedBox(width: _HT.gap),
        Expanded(
          child: _HomeMiniCard(
            title: 'Network',
            value: 'Solana',
            icon: Icons.lan_rounded,
            color: _HT.lime,
            bg: _HT.limeBg,
            bdr: _HT.limeBdr,
          ),
        ),
        const SizedBox(width: _HT.gap),
        Expanded(
          child: _HomeMiniCard(
            title: 'Reward',
            value: 'SOL',
            icon: Icons.emoji_events_rounded,
            color: _HT.violet,
            bg: _HT.violetBg,
            bdr: _HT.violetBdr,
          ),
        ),
      ],
    );
  }
}

class _HomeMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color, bg, bdr;

  const _HomeMiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.bdr,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      radius: _HT.r20,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: _HT.r12,
              border: Border.all(color: bdr, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: _label(size: 11, color: _HT.inkMid, weight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: _label(
              size: 13,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Graph card: BTC chart with 24h, 1d, 3d, 7d and low/high/vol ─────────────
class HomeGraphCard extends StatefulWidget {
  final BtcPriceService priceService;

  const HomeGraphCard({super.key, required this.priceService});

  @override
  State<HomeGraphCard> createState() => _HomeGraphCardState();
}

class _HomeGraphCardState extends State<HomeGraphCard> {
  int _selectedTab = 1; // 0: 24H, 1: 7D

  @override
  Widget build(BuildContext context) {
    final high = widget.priceService.high24h;
    final low = widget.priceService.low24h;
    final vol = widget.priceService.volume24h;

    return _GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SOL Price',
                style: _label(
                  size: 18,
                  weight: FontWeight.w700,
                  color: _HT.ink,
                ),
              ),
              Row(
                children: [
                  _GraphChip(
                    label: '24H',
                    active: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  const SizedBox(width: 8),
                  _GraphChip(
                    label: '7D',
                    active: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: 160, child: BtcPriceChart()),
          const SizedBox(height: 14),
          Row(
            children: [
              if (low != null)
                _GraphStat(
                  label: 'Low',
                  value: '\$${low.toStringAsFixed(0)}',
                ),
              if (low != null && high != null) const SizedBox(width: 18),
              if (high != null)
                _GraphStat(
                  label: 'High',
                  value: '\$${high.toStringAsFixed(0)}',
                ),
              if (high != null && vol != null) const SizedBox(width: 18),
              if (vol != null) _GraphStat(label: 'Vol', value: _formatVol(vol)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatVol(double v) {
    if (v >= 1e12) return '\$${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    return '\$${v.toStringAsFixed(0)}';
  }
}

class _GraphChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _GraphChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? _HT.lime.withOpacity(0.15)
              : _HT.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? _HT.limeBdr : _HT.borderSub,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: _label(
            size: 11,
            weight: FontWeight.w600,
            color: active ? _HT.lime : _HT.inkMid,
          ),
        ),
      ),
    );
  }
}

class _GraphStat extends StatelessWidget {
  final String label;
  final String value;

  const _GraphStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _label(size: 11, color: _HT.inkMid, weight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: _mono(size: 13, weight: FontWeight.w600, color: _HT.ink),
        ),
      ],
    );
  }
}

// ─── Mining CTA button ───────────────────────────────────────────────────────
class HomeMiningButton extends StatefulWidget {
  final VoidCallback onTap;

  const HomeMiningButton({super.key, required this.onTap});

  @override
  State<HomeMiningButton> createState() => _HomeMiningButtonState();
}

class _HomeMiningButtonState extends State<HomeMiningButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _isPressed ? 0.96 : 1.0,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ClipRRect(
            borderRadius: _HT.r20,
            child: _NoBlur(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: _HT.lime.withOpacity(0.15),
                  borderRadius: _HT.r20,
                  border: Border.all(color: _HT.limeBdr, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _HT.lime.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _HT.lime.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _HT.lime.withOpacity(0.3), width: 0.8),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: _HT.lime,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Start Mining',
                      style: _label(
                        size: 16,
                        weight: FontWeight.w700,
                        color: _HT.lime,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: _HT.lime.withOpacity(0.4),
                      size: 16,
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
}

// ─── Hashrate & Est. monthly cards ───────────────────────────────────────────
class HomeHashrateCards extends StatelessWidget {
  final GameStateService game;

  const HomeHashrateCards({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final ratePerHr = game.totalBtcPerMin * 60;
    final estMonthly = ratePerHr * 24 * 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _HomeStatCard(
                title: 'Hashrate',
                value: '${(game.totalBtcPerMin * 60).toStringAsFixed(6)} SOL/hr',
                icon: Icons.speed_rounded,
                color: _HT.lime,
                bg: _HT.limeBg,
                bdr: _HT.limeBdr,
              ),
            ),
            const SizedBox(width: _HT.gap),
            Expanded(
              child: _HomeStatCard(
                title: 'Est. monthly',
                value: '${estMonthly.toStringAsFixed(6)} SOL',
                icon: Icons.calendar_month_rounded,
                color: _HT.blue,
                bg: _HT.blueBg,
                bdr: _HT.blueBdr,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'From your rigs × farm tier × active session/premium/boost',
          style: _label(size: 11, color: _HT.inkMid, weight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color, bg, bdr;

  const _HomeStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.bdr,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: _HT.r12,
              border: Border.all(color: bdr, width: 0.8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: _label(size: 12, color: _HT.inkMid, weight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: _mono(size: 13, weight: FontWeight.w600, color: _HT.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Earnings card ──────────────────────────────────────────────────────────
class HomeEarningsCard extends StatelessWidget {
  final GameStateService game;

  const HomeEarningsCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total earned',
                style: _label(size: 13, color: _HT.inkMid, weight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                '${game.lifetimeMinedBtc.toStringAsFixed(6)} SOL',
                style: _label(
                  size: 22,
                  weight: FontWeight.w700,
                  color: _HT.lime,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _HT.lime.withOpacity(0.12),
              borderRadius: _HT.r16,
              border: Border.all(color: _HT.limeBdr, width: 0.8),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: _HT.lime,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upgrade mining power button → Shop ──────────────────────────────────────
class HomeUpgradeButton extends StatefulWidget {
  const HomeUpgradeButton({super.key});

  @override
  State<HomeUpgradeButton> createState() => _HomeUpgradeButtonState();
}

class _HomeUpgradeButtonState extends State<HomeUpgradeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => Navigator.pushNamed(context, '/shop'),
      child: Transform.scale(
        scale: _isPressed ? 0.96 : 1.0,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ClipRRect(
            borderRadius: _HT.r20,
            child: _NoBlur(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: _HT.surface.withOpacity(0.08),
                  borderRadius: _HT.r20,
                  border: Border.all(color: _HT.lime, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _HT.lime.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: _HT.lime,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Upgrade mining power',
                      style: _label(
                        size: 15,
                        weight: FontWeight.w700,
                        color: _HT.lime,
                        letterSpacing: -0.2,
                      ),
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
}

// ─── Grid: Lucky Spin + Referral (row 1), Challenges (row 2) ──────────────────
class HomeSpinReferralChallengesGrid extends StatelessWidget {
  final LuckySpinService spin;
  final ReferralService referral;
  final WeeklyChallengeService weekly;

  const HomeSpinReferralChallengesGrid({
    super.key,
    required this.spin,
    required this.referral,
    required this.weekly,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HomeFeatureCard(
                icon: Icons.casino_rounded,
                title: 'Lucky Spin',
                subtitle: spin.canSpin ? 'Spin for rewards!' : 'Next spin in 24h',
                onTap: () => Navigator.pushNamed(context, '/lucky-spin'),
                color: _HT.lime,
                bg: _HT.limeBg,
                bdr: _HT.limeBdr,
                compact: true,
              ),
            ),
            const SizedBox(width: _HT.gap),
            Expanded(
              child: _HomeFeatureCard(
                icon: Icons.group_add_rounded,
                title: 'Referral',
                subtitle: '${referral.friends} friends',
                onTap: () => Navigator.pushNamed(context, '/profile'),
                color: _HT.lime,
                bg: _HT.limeBg,
                bdr: _HT.limeBdr,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: _HT.gap),
        _HomeFeatureCard(
          icon: Icons.emoji_events_rounded,
          title: 'Weekly challenge',
          subtitle: 'Complete sessions for rewards',
          onTap: () => Navigator.pushNamed(context, '/profile'),
          color: _HT.violet,
          bg: _HT.violetBg,
          bdr: _HT.violetBdr,
          compact: false,
        ),
      ],
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color, bg, bdr;
  final bool compact;

  const _HomeFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    required this.bg,
    required this.bdr,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 14.0 : 16.0;
    final iconSize = compact ? 20.0 : 24.0;
    final titleSize = compact ? 13.0 : 14.0;
    final subtitleSize = compact ? 11.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: _GlassContainer(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 9 : 11),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: _HT.r12,
                border: Border.all(color: bdr, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            SizedBox(width: compact ? 11 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: _label(
                      size: titleSize,
                      weight: FontWeight.w700,
                      color: _HT.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _label(
                      size: subtitleSize,
                      color: _HT.inkMid,
                      weight: FontWeight.w500,
                    ),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: _HT.inkFaint,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── How SOL mining works (text card) ───────────────────────────────────────
class HomeHowMiningWorksCard extends StatelessWidget {
  const HomeHowMiningWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _HT.blue.withOpacity(0.12),
                  borderRadius: _HT.r12,
                  border: Border.all(color: _HT.blueBdr, width: 0.8),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: _HT.blue, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'How SOL mining works',
                style: _label(
                  size: 16,
                  weight: FontWeight.w700,
                  color: _HT.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            'Solana validators secure the network by producing and confirming blocks. Your simulated validator farm earns SOL over time from staking-style rewards.',
            style: _label(
              size: 13,
              color: _HT.inkMid,
              height: 1.5,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mining reward card ─────────────────────────────────────────────────────
class HomeMiningRewardCard extends StatelessWidget {
  const HomeMiningRewardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomeIconTitleCard(
      icon: Icons.card_giftcard_rounded,
      color: _HT.lime,
      bg: _HT.limeBg,
      bdr: _HT.limeBdr,
      title: 'Mining reward',
      body:
      'Earn SOL as your validators run. Upgrade rigs and boost your rate in the Shop.',
    );
  }
}

// ─── Security first card ────────────────────────────────────────────────────
class HomeSecurityCard extends StatelessWidget {
  const HomeSecurityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomeIconTitleCard(
      icon: Icons.security_rounded,
      color: _HT.blue,
      bg: _HT.blueBg,
      bdr: _HT.blueBdr,
      title: 'Security first',
      body: 'Your balance is stored securely. We never store private keys.',
    );
  }
}

// ─── Transparency and trust card ────────────────────────────────────────────
class HomeTransparencyCard extends StatelessWidget {
  const HomeTransparencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomeIconTitleCard(
      icon: Icons.verified_user_rounded,
      color: _HT.amber,
      bg: _HT.amberBg,
      bdr: _HT.amberBdr,
      title: 'Transparency & trust',
      body:
      'Real-time SOL price from CoinGecko. Clear stats and no hidden fees.',
    );
  }
}

class _HomeIconTitleCard extends StatelessWidget {
  final IconData icon;
  final Color color, bg, bdr;
  final String title;
  final String body;

  const _HomeIconTitleCard({
    required this.icon,
    required this.color,
    required this.bg,
    required this.bdr,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: _HT.r12,
              border: Border.all(color: bdr, width: 0.8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _label(
                    size: 15,
                    weight: FontWeight.w700,
                    color: _HT.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: _label(
                    size: 12,
                    color: _HT.inkMid,
                    height: 1.4,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Testimonials / reviews horizontal scroll ───────────────────────────────
class HomeTestimonialsCard extends StatelessWidget {
  const HomeTestimonialsCard({super.key});

  static const _items = [
    _Testimonial('Hiroshi Tanaka', '🇯🇵', 'Japan', 5,
        'Started a session and watched SOL tick up all day. The farm upgrades feel worth it.'),
    _Testimonial('Mei Lin', '🇨🇳', 'China', 5,
        'Clean Solana look, real prices, and the lucky spin actually dropped a rig. Addictive.'),
    _Testimonial('Min-jun Park', '🇰🇷', 'South Korea', 5,
        'Referral code worked on first try. Friend joined and we both got the bonus.'),
    _Testimonial('Priya Sharma', '🇮🇳', 'India', 5,
        'Earned my first 0.5 SOL in a week. Daily rewards keep me coming back.'),
    _Testimonial('Arjun Patel', '🇮🇳', 'India', 4,
        'Hash rate jumped after two GPU rigs. Would love even more farm tiers.'),
    _Testimonial('Nguyen Tran', '🇻🇳', 'Vietnam', 5,
        'Mining session notification is handy. I start it, close the app, collect later.'),
    _Testimonial('Putri Wulandari', '🇮🇩', 'Indonesia', 5,
        'Guest to Google link saved my progress. Feels safe to keep mining.'),
    _Testimonial('Kai Tan', '🇸🇬', 'Singapore', 5,
        'Leaderboard is competitive. Climbing after I stacked validators.'),
    _Testimonial('Lukas Müller', '🇩🇪', 'Germany', 5,
        'Best idle miner I have tried. Boost + session combo is clearly explained.'),
    _Testimonial('Sofia Rossi', '🇮🇹', 'Italy', 5,
        'UI is gorgeous. Purple-green Solana theme, not another generic crypto clone.'),
    _Testimonial('Pierre Dubois', '🇫🇷', 'France', 4,
        'Price chart matches CoinGecko. Nice to see SOL, not fake numbers.'),
    _Testimonial('Anna Kowalska', '🇵🇱', 'Poland', 5,
        'Claimed the daily streak and a GPU rig on day 3. Fair rewards.'),
    _Testimonial('James Walker', '🇬🇧', 'United Kingdom', 5,
        'Upgraded rigs and doubled my rate. Shop purchases went through Play Billing.'),
    _Testimonial('Ingrid Berg', '🇸🇪', 'Sweden', 5,
        'Runs quietly in the background. Comeback bonus was a nice surprise.'),
    _Testimonial('Lucía García', '🇪🇸', 'Spain', 4,
        'Challenges and ads are paced, not spammy. Premium is optional, which I like.'),
    _Testimonial('Jordan Hale', '🇺🇸', 'United States', 5,
        'Hit the leaderboard after a week. The 1.25× session is the move.'),
    _Testimonial('Carlos Mendoza', '🇲🇽', 'Mexico', 5,
        'Invited two friends, claimed the 1-friend reward instantly. Smooth.'),
    _Testimonial('Sofia Alves', '🇧🇷', 'Brazil', 5,
        'Spin, tap challenge, then mine. Always something to do in a minute.'),
    _Testimonial('Emma Roy', '🇨🇦', 'Canada', 4,
        'Withdrawal tasks are clear. I know exactly what is left to unlock.'),
    _Testimonial('Amara Okafor', '🇳🇬', 'Nigeria', 5,
        'Finally an idle game that feels modern. SOL balance updates every second.'),
    _Testimonial('Kwame Boateng', '🇬🇭', 'Ghana', 5,
        'Shared my code and watched friends show up on the invite list.'),
    _Testimonial('Omar Hassan', '🇦🇪', 'UAE', 5,
        'Premium removed ads and the farm still mines overnight. Perfect.'),
    _Testimonial('Yasmin Farouk', '🇪🇬', 'Egypt', 5,
        'First miner achievement popped with a sound. Little details matter.'),
    _Testimonial('Liam Crowe', '🇦🇺', 'Australia', 5,
        'Notifications when mining starts actually show up. Easy to trust.'),
    _Testimonial('Hana Reid', '🇳🇿', 'New Zealand', 4,
        'Love the global board. Fun seeing miners from Asia and Europe above me.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Reviews',
            style: _label(
              size: 18,
              weight: FontWeight.w700,
              color: _HT.ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            'Miners from Asia, Europe, and around the world',
            style: _label(size: 12, color: _HT.inkMid, weight: FontWeight.w500),
          ),
        ),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = _items[i];
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.78,
                child: _GlassContainer(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (s) => Icon(
                              s < t.stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: s < t.stars
                                  ? const Color(0xFFFBBF24)
                                  : _HT.inkFaint,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            t.flag,
                            style: const TextStyle(fontSize: 16, height: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.quote,
                        style: _label(
                          size: 13,
                          color: _HT.ink,
                          height: 1.4,
                          weight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        t.author,
                        style: _label(
                          size: 13,
                          color: _HT.ink,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.place,
                        style: _label(
                          size: 11,
                          color: _HT.inkMid,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Testimonial {
  final String author;
  final String flag;
  final String place;
  final int stars;
  final String quote;

  const _Testimonial(this.author, this.flag, this.place, this.stars, this.quote);
}

// ─── FAQ card ──────────────────────────────────────────────────────────────
class HomeFaqCard extends StatefulWidget {
  const HomeFaqCard({super.key});

  static const _faqs = [
    _Faq('What is Solana staking?',
        'Validators secure Solana by producing and confirming blocks. Simulated staking earns you SOL over time.'),
    _Faq('How do I earn more SOL?',
        'Upgrade your validator rigs in the Shop and complete sessions. Higher hash power = more SOL per hour.'),
    _Faq('Is my balance real?',
        'This app simulates mining. Your in-app balance is for fun; withdraw options may apply in-app only.'),
    _Faq('Where does the price come from?',
        'We use CoinGecko API for real-time SOL/USD price.'),
  ];

  @override
  State<HomeFaqCard> createState() => _HomeFaqCardState();
}

class _HomeFaqCardState extends State<HomeFaqCard> {
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _HT.violet.withOpacity(0.12),
                  borderRadius: _HT.r12,
                  border: Border.all(color: _HT.violetBdr, width: 0.8),
                ),
                child: const Icon(Icons.help_outline_rounded,
                    color: _HT.violet, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'FAQ',
                style: _label(
                  size: 18,
                  weight: FontWeight.w700,
                  color: _HT.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ✅ Use widget.HomeFaqCard._faqs instead
          ...HomeFaqCard._faqs.asMap().entries.map((e) {
            final faq = e.value;
            final idx = e.key;
            final isExpanded = _expanded == idx;
            final isLast = idx == HomeFaqCard._faqs.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _expanded = isExpanded ? null : idx),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? _HT.violet.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: _HT.r12,
                    border: Border.all(
                      color: isExpanded
                          ? _HT.violetBdr
                          : _HT.borderSub,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              faq.q,
                              style: _label(
                                size: 13,
                                weight: FontWeight.w700,
                                color: _HT.ink,
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: _HT.violet,
                            size: 20,
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 9),
                        Text(
                          faq.a,
                          style: _label(
                            size: 12,
                            color: _HT.inkMid,
                            height: 1.4,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(), // ✅ Convert to list
        ],
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;

  const _Faq(this.q, this.a);
}