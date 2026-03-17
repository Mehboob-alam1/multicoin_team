import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/mining_location.dart';
import '../services/btc_price_service.dart';
import '../services/comeback_bonus_service.dart';
import '../services/daily_boost_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/game_state_service.dart';
import '../services/goals_service.dart';
import '../services/login_streak_service.dart';
import '../services/lucky_spin_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/progression_service.dart';
import '../services/random_drop_service.dart';
import '../services/referral_service.dart';
import '../services/season_service.dart';
import '../services/weekly_challenge_service.dart';
import '../widgets/btc_price_chart.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/minimizable_native_ad.dart';
import '../theme/home_theme.dart';
import '../widgets/smart_banner_ad.dart';
import 'home_dashboard_content.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _D {
  // Backgrounds
  static const bg       = Color(0xFFF7F8FA);
  static const white    = Color(0xFFFFFFFF);

  // Borders
  static const border   = Color(0x12000000); // 0.07 alpha ≈ border-em
  static const borderSm = Color(0x0D000000); // subtler

  // Accents
  static const amber      = Color(0xFFF59E0B);
  static const amberBg    = Color(0xFFFFFBEB);
  static const amberBorder= Color(0x33F59E0B);
  static const amberDeep  = Color(0xFF92400E);

  static const green      = Color(0xFF10B981);
  static const greenBg    = Color(0xFFF0FDF6);
  static const greenDeep  = Color(0xFF065F46);

  static const blue       = Color(0xFF3B82F6);
  static const blueBg     = Color(0xFFEFF6FF);
  static const blueDeep   = Color(0xFF1D4ED8);

  static const purple     = Color(0xFF8B5CF6);
  static const purpleBg   = Color(0xFFF5F3FF);
  static const purpleDeep = Color(0xFF5B21B6);

  static const red        = Color(0xFFEF4444);
  static const redBg      = Color(0xFFFEF2F2);

  // Text
  static const text  = Color(0xFF0D0F12);
  static const sub   = Color(0xFF6B7280);
  static const hint  = Color(0xFFB0B7C3);

  // Radii
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r10 = BorderRadius.all(Radius.circular(10));
  static const r14 = BorderRadius.all(Radius.circular(14));
  static const r18 = BorderRadius.all(Radius.circular(18));
}

// ─── Main screen ─────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BtcPriceService>().fetchAll();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game            = context.watch<GameStateService>();
    final btcPrice        = context.watch<BtcPriceService>();
    final progression     = context.watch<ProgressionService>();
    final dailyBoost      = context.watch<DailyBoostService>();
    final drop            = context.watch<RandomDropService>();
    final energy          = context.watch<EnergyCoolingService>();
    final adCfg           = context.watch<AdRemoteConfigService>();
    final loginStreak     = context.watch<LoginStreakService>();
    final weeklyChallenge = context.watch<WeeklyChallengeService>();
    final goals           = context.watch<GoalsService>();
    final comeback        = context.watch<ComebackBonusService>();
    final referral        = context.watch<ReferralService>();
    final season          = context.watch<SeasonService>();
    final spin            = context.watch<LuckySpinService>();

    if (game.isLoaded) weeklyChallenge.load(game.totalSessionsStarted);

    final idle     = game.getIdleEarnedIfAny();
    final worthUsd = btcPrice.balanceWorthUsd(game.btcBalance);

    return Scaffold(
      backgroundColor: _D.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: _D.bg,
              surfaceTintColor: Colors.transparent,
              title: Row(children: [
                _LogoIcon(),
                const SizedBox(width: 9),
                Text(
                  'Mining Tycoon',
                  style: GoogleFonts.dmSans(
                    color: _D.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ]),
              actions: [
                if (game.syncInProgress)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _D.amber),
                    ),
                  ),
                _IconBtn(
                  icon: Icons.person_outline_rounded,
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                const SizedBox(width: 14),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Idle banner ───────────────────────────────────
                  if (idle != null && idle > 0) ...[
                    FadeSlideIn(child: _IdleBanner(idle: idle)),
                    const SizedBox(height: 12),
                  ],

                  // ── Balance hero ──────────────────────────────────
                  FadeSlideIn(
                    child: _BalanceHero(
                      btcBalance: game.btcBalance,
                      worthUsd: worthUsd,
                      btcPerMin: game.totalBtcPerMin,
                      isBoostActive: dailyBoost.isActive,
                      isSessionActive: game.isSessionActive,
                      sessionTimeLeft: game.sessionTimeLeft,
                      pulse: _pulseCtrl,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Mine CTA ──────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 50),
                    child: _MineCTA(
                      isActive: game.isSessionActive,
                      onTap: () => Navigator.pushNamed(context, '/farm'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Stats row 1: Rigs / Farm tier ─────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: _Row2(
                      left: _StatCard(
                        icon: Icons.memory_rounded,
                        iconBg: _D.blueBg,
                        iconColor: _D.blue,
                        label: 'Active rigs',
                        value: '${game.ownedRigIds.length}',
                      ),
                      right: _StatCard(
                        icon: Icons.factory_rounded,
                        iconBg: _D.amberBg,
                        iconColor: _D.amber,
                        label: 'Farm tier',
                        value: game.currentFarmTier.name,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Stats row 2: Lifetime / Rate ──────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: _Row2(
                      left: _StatCard(
                        icon: Icons.savings_rounded,
                        iconBg: _D.greenBg,
                        iconColor: _D.green,
                        label: 'Lifetime mined',
                        value: '${game.lifetimeMinedBtc.toStringAsFixed(4)} ₿',
                      ),
                      right: _StatCard(
                        icon: Icons.bolt_rounded,
                        iconBg: _D.purpleBg,
                        iconColor: _D.purple,
                        label: 'Rate / min',
                        value: '${game.totalBtcPerMin.toStringAsFixed(6)} ₿',
                        mono: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── BTC Market ─────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _SecHeader(title: 'BTC Market'),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 135),
                    child: HomeGraphCard(priceService: btcPrice),
                  ),
                  const SizedBox(height: 18),

                  // ── Quick actions ──────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: _SecHeader(title: 'Quick actions'),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 165),
                    child: _QuickActions(context: context),
                  ),
                  const SizedBox(height: 18),

                  // ── Bonuses & rewards ──────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 180),
                    child: _SecHeader(title: 'Bonuses & rewards'),
                  ),
                  const SizedBox(height: 10),

                  // Comeback (full-width if available)
                  if (comeback.canClaim) ...[
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 195),
                      child: _ComebackCard(comeback: comeback, game: game),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Row: Daily boost + Login streak
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 210),
                    child: _Row2(
                      left: _DailyBoostCard(dailyBoost: dailyBoost),
                      right: _LoginStreakCard(loginStreak: loginStreak, game: game),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Row: Weekly + Goals
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 225),
                    child: _Row2(
                      left: _WeeklyChallengeCard(weeklyChallenge: weeklyChallenge, game: game),
                      right: _GoalsCard(goals: goals, game: game),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Row: Spin + Referral
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: _Row2(
                      left: _SpinCard(spin: spin),
                      right: _ReferralCard(referral: referral),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Season (full-width)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 255),
                    child: _SeasonCard(season: season, game: game),
                  ),
                  const SizedBox(height: 18),

                  // ── Operations ─────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 270),
                    child: _SecHeader(title: 'Operations'),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 285),
                    child: _EnergyCard(energy: energy),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: _LocationsCard(progression: progression),
                  ),
                  const SizedBox(height: 18),

                  // ── Random drop ────────────────────────────────────
                  if (drop.isAvailable) ...[
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 315),
                      child: _SecHeader(title: 'Hidden drop'),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 330),
                      child: _DropCard(drop: drop, game: game),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Discover ───────────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 345),
                    child: _SecHeader(title: 'Discover'),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 360),
                    child: _NewsCard(),
                  ),
                  const SizedBox(height: 10),

                  if (adCfg.canShowWebsiteRedirect) ...[
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 375),
                      child: _WebsiteCard(adCfg: adCfg),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── How it works ───────────────────────────────────
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 390),
                    child: _SecHeader(title: 'How it works'),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 405),
                    child: const Column(children: [
                      HomeHowMiningWorksCard(),
                      SizedBox(height: 8),
                      HomeMiningRewardCard(),
                      SizedBox(height: 8),
                      HomeSecurityCard(),
                      SizedBox(height: 8),
                      HomeTransparencyCard(),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  FadeSlideIn(
                    delay: const Duration(milliseconds: 420),
                    child: const HomeTestimonialsCard(),
                  ),
                  const SizedBox(height: 16),

                  FadeSlideIn(
                    delay: const Duration(milliseconds: 435),
                    child: const HomeFaqCard(),
                  ),
                  const SizedBox(height: 16),

                  // ── Sponsor ad (white background) ────────────────────────────
                  if (adCfg.adsActive) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(HomeTheme.cardRadius),
                        color: HomeTheme.cardLight,
                        border: Border.all(color: HomeTheme.cardLightBorder),
                      ),
                      child: const Column(
                        children: [
                          MinimizableNativeAd(title: 'Sponsored offer'),
                          SizedBox(height: 10),
                          Center(child: SmartBannerAd()),
                        ],
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SecHeader extends StatelessWidget {
  final String title;
  const _SecHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title.toUpperCase(),
    style: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: _D.sub,
      letterSpacing: 0.6,
    ),
  );
}

// ─── Two-column helper ────────────────────────────────────────────────────────
class _Row2 extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _Row2({required this.left, required this.right});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 10),
      Expanded(child: right),
    ],
  );
}

// ─── Base card decoration ─────────────────────────────────────────────────────
BoxDecoration _cardDeco({Color? borderColor, BorderRadius? radius}) =>
    BoxDecoration(
      color: _D.white,
      borderRadius: radius ?? _D.r14,
      border: Border.all(color: borderColor ?? _D.border, width: 0.5),
    );

// ─── Logo icon ────────────────────────────────────────────────────────────────
class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: _D.amberBg,
      borderRadius: const BorderRadius.all(Radius.circular(9)),
      border: Border.all(color: _D.amberBorder, width: 0.5),
    ),
    child: const Icon(Icons.currency_bitcoin, color: _D.amber, size: 17),
  );
}

// ─── App bar icon button ──────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: const BorderRadius.all(Radius.circular(9)),
        border: Border.all(color: _D.border, width: 0.5),
      ),
      child: Icon(icon, color: _D.sub, size: 17),
    ),
  );
}

// ─── Idle banner ──────────────────────────────────────────────────────────────
class _IdleBanner extends StatelessWidget {
  final double idle;
  const _IdleBanner({required this.idle});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: _D.amberBg,
      borderRadius: _D.r10,
      border: Border.all(color: _D.amberBorder, width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _D.amber.withOpacity(0.15),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: const Icon(Icons.notifications_active_rounded, color: _D.amber, size: 15),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Welcome back!',
            style: GoogleFonts.dmSans(color: _D.amberDeep, fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Text(
            'Miners generated +${idle.toStringAsFixed(8)} BTC',
            style: GoogleFonts.dmSans(color: _D.amberDeep.withOpacity(0.7), fontSize: 11),
          ),
        ]),
      ),
      const Icon(Icons.chevron_right_rounded, color: _D.amber, size: 16),
    ]),
  );
}

// ─── Balance hero ─────────────────────────────────────────────────────────────
class _BalanceHero extends StatelessWidget {
  final double btcBalance;
  final double? worthUsd;
  final double btcPerMin;
  final bool isBoostActive;
  final bool isSessionActive;
  final Duration sessionTimeLeft;
  final AnimationController pulse;

  const _BalanceHero({
    required this.btcBalance,
    required this.worthUsd,
    required this.btcPerMin,
    required this.isBoostActive,
    required this.isSessionActive,
    required this.sessionTimeLeft,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final intPart = btcBalance.floor().toString();
    final decPart = '.${btcBalance.toStringAsFixed(8).split('.')[1]}';

    return Container(
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: _D.r18,
        border: Border.all(color: _D.border, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        // Subtle amber glow top-right
        Positioned(
          top: -50,
          right: -50,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _D.amber.withOpacity(0.05 + 0.03 * pulse.value),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _D.amberBg,
                      borderRadius: const BorderRadius.all(Radius.circular(7)),
                    ),
                    child: const Icon(Icons.currency_bitcoin, color: _D.amber, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BTC BALANCE',
                    style: GoogleFonts.dmSans(
                      color: _D.sub,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                ]),
                Row(children: [
                  if (isBoostActive) _Pill('2× BOOST', _D.amber, _D.amberBg, _D.amberDeep),
                  if (isBoostActive && isSessionActive) const SizedBox(width: 5),
                  if (isSessionActive) _Pill('MINING', _D.green, _D.greenBg, _D.greenDeep),
                ]),
              ],
            ),

            const SizedBox(height: 18),

            // Balance
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                intPart,
                style: GoogleFonts.dmMono(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: _D.text,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  decPart,
                  style: GoogleFonts.dmMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _D.amber,
                    height: 1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 7),
                child: Text(
                  'BTC',
                  style: GoogleFonts.dmSans(
                    color: _D.sub,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 4),
            Text(
              worthUsd != null ? '≈ \$${worthUsd!.toStringAsFixed(2)} USD' : '≈ — USD',
              style: GoogleFonts.dmSans(color: _D.sub, fontSize: 12),
            ),

            const SizedBox(height: 18),
            Container(height: 0.5, color: _D.border),
            const SizedBox(height: 14),

            // Footer: hashrate + timer
            Row(children: [
              _PulsingDot(),
              const SizedBox(width: 8),
              Text(
                '${btcPerMin.toStringAsFixed(8)} BTC/min',
                style: GoogleFonts.dmMono(
                  color: _D.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isSessionActive) ...[
                const Icon(Icons.timer_outlined, color: _D.sub, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${sessionTimeLeft.inMinutes}:${(sessionTimeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.dmMono(color: _D.sub, fontSize: 11),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color accent;
  final Color bg;
  final Color textColor;
  const _Pill(this.label, this.accent, this.bg, this.textColor);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      border: Border.all(color: accent.withOpacity(0.25), width: 0.5),
    ),
    child: Text(
      label,
      style: GoogleFonts.dmSans(
        color: textColor,
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat(reverse: true);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _D.green,
        boxShadow: [BoxShadow(
          color: _D.green.withOpacity(0.25 + 0.35 * _c.value),
          blurRadius: 4 + 4 * _c.value,
        )],
      ),
    ),
  );
}

// ─── Mine CTA ─────────────────────────────────────────────────────────────────
class _MineCTA extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _MineCTA({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg      = isActive ? _D.greenBg    : _D.amberBg;
    final fg      = isActive ? _D.greenDeep  : _D.amberDeep;
    final border  = isActive ? _D.green.withOpacity(0.2) : _D.amberBorder;
    final icon    = isActive ? Icons.bolt_rounded : Icons.play_arrow_rounded;
    final label   = isActive ? 'Session running — View farm' : 'Start mining session';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: _D.r14,
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, color: fg.withOpacity(0.4), size: 14),
        ]),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final bool mono;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _cardDeco(),
    child: Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: iconBg, borderRadius: _D.r10),
        child: Icon(icon, color: iconColor, size: 17),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: GoogleFonts.dmSans(color: _D.sub, fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: mono
              ? GoogleFonts.dmMono(color: _D.text, fontSize: 12, fontWeight: FontWeight.w500)
              : GoogleFonts.dmSans(color: _D.text, fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ])),
    ]),
  );
}

// ─── Quick actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final BuildContext context;
  const _QuickActions({required this.context});

  @override
  Widget build(BuildContext ctx) {
    final items = [
      (Icons.account_balance_wallet_outlined, 'Wallet',   _D.blue,   _D.blueBg,   '/profile'),
      (Icons.payments_outlined,               'Withdraw', _D.green,  _D.greenBg,  '/profile'),
      (Icons.group_add_outlined,              'Invite',   _D.purple, _D.purpleBg, '/profile'),
      (Icons.show_chart_rounded,              'Stats',    _D.amber,  _D.amberBg,  '/farm'),
    ];

    return Row(
      children: List.generate(items.length, (i) {
        final a = items[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, a.$5),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: _cardDeco(),
                child: Column(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: a.$4, borderRadius: _D.r8),
                    child: Icon(a.$1, color: a.$3, size: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.$2,
                    style: GoogleFonts.dmSans(
                      color: _D.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Comeback card ────────────────────────────────────────────────────────────
class _ComebackCard extends StatelessWidget {
  final ComebackBonusService comeback;
  final GameStateService game;
  const _ComebackCard({required this.comeback, required this.game});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDeco(borderColor: _D.amberBorder),
    child: Row(children: [
      const Text('👋', style: TextStyle(fontSize: 26)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back!',
            style: GoogleFonts.dmSans(color: _D.text, fontWeight: FontWeight.w600, fontSize: 14)),
        Text(
          '+${ComebackBonusService.bonusBtc.toStringAsFixed(5)} BTC waiting for you',
          style: GoogleFonts.dmSans(color: _D.amberDeep, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ])),
      _ChipBtn(
        label: 'Claim',
        color: _D.amberDeep,
        bg: _D.amberBg,
        borderColor: _D.amberBorder,
        onTap: () async {
          await game.grantDirectBtc(ComebackBonusService.bonusBtc);
          await comeback.markClaimed();
          if (context.mounted) _toast(context, '🎁 Welcome back bonus claimed!');
        },
      ),
    ]),
  );
}

// ─── Shared bonus mini card ───────────────────────────────────────────────────
class _BonusMini extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeBg;
  final Color? badgeText;
  final double? progress;
  final Color? progressColor;
  final VoidCallback? onTap;

  const _BonusMini({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    this.badgeBg,
    this.badgeText,
    this.progress,
    this.progressColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = badge != null && onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDeco(
          borderColor: hasAction ? (badgeColor ?? _D.amber).withOpacity(0.3) : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: iconBg, borderRadius: _D.r8),
              child: Icon(icon, color: iconColor, size: 15),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg ?? _D.amberBg,
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  border: Border.all(
                    color: (badgeColor ?? _D.amber).withOpacity(0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.dmSans(
                    color: badgeText ?? _D.amberDeep,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.dmSans(color: _D.text, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(color: _D.sub, fontSize: 11),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(2)),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: _D.borderSm,
                valueColor: AlwaysStoppedAnimation(progressColor ?? _D.amber),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── Concrete bonus cards ─────────────────────────────────────────────────────
class _DailyBoostCard extends StatelessWidget {
  final DailyBoostService dailyBoost;
  const _DailyBoostCard({required this.dailyBoost});

  @override
  Widget build(BuildContext context) {
    final can = dailyBoost.canClaim;
    return _BonusMini(
      icon: Icons.bolt_rounded,
      iconColor: _D.amber,
      iconBg: _D.amberBg,
      title: 'Daily boost',
      subtitle: can ? '2× speed ready!' : 'Resets in 24h',
      badge: can ? 'READY' : null,
      badgeColor: _D.amber,
      badgeBg: _D.amberBg,
      badgeText: _D.amberDeep,
      onTap: can
          ? () async {
        final ok = await dailyBoost.claim();
        if (ok && context.mounted) _toast(context, '⚡ 2× boost activated!');
      }
          : null,
    );
  }
}

class _LoginStreakCard extends StatelessWidget {
  final LoginStreakService loginStreak;
  final GameStateService game;
  const _LoginStreakCard({required this.loginStreak, required this.game});

  @override
  Widget build(BuildContext context) {
    final days = loginStreak.streakDays;
    final can  = loginStreak.canClaimStreak3 || loginStreak.canClaimStreak7;
    return _BonusMini(
      icon: Icons.local_fire_department_rounded,
      iconColor: _D.red,
      iconBg: _D.redBg,
      title: 'Login streak',
      subtitle: days == 0 ? 'Come back tomorrow' : '$days day${days == 1 ? '' : 's'} 🔥',
      badge: can ? 'CLAIM' : null,
      badgeColor: _D.green,
      badgeBg: _D.greenBg,
      badgeText: _D.greenDeep,
      onTap: can
          ? () async {
        if (loginStreak.canClaimStreak7) {
          await game.grantDirectBtc(0.00003);
          await loginStreak.markStreak7Claimed();
          if (context.mounted) _toast(context, '🔥 7-day reward!');
        } else {
          await game.grantDirectBtc(0.00001);
          await loginStreak.markStreak3Claimed();
          if (context.mounted) _toast(context, '🔥 3-day reward!');
        }
      }
          : null,
    );
  }
}

class _WeeklyChallengeCard extends StatelessWidget {
  final WeeklyChallengeService weeklyChallenge;
  final GameStateService game;
  const _WeeklyChallengeCard({required this.weeklyChallenge, required this.game});

  @override
  Widget build(BuildContext context) {
    final progress = weeklyChallenge.progressThisWeek(game.totalSessionsStarted);
    final can      = weeklyChallenge.canClaim(game.totalSessionsStarted);
    return _BonusMini(
      icon: Icons.emoji_events_rounded,
      iconColor: _D.purple,
      iconBg: _D.purpleBg,
      title: 'Weekly',
      subtitle: '$progress/${WeeklyChallengeService.targetSessions} sessions',
      badge: can ? 'CLAIM' : '${progress}/${WeeklyChallengeService.targetSessions}',
      badgeColor: can ? _D.green : _D.purple,
      badgeBg: can ? _D.greenBg : _D.purpleBg,
      badgeText: can ? _D.greenDeep : _D.purpleDeep,
      progress: progress / WeeklyChallengeService.targetSessions,
      progressColor: _D.purple,
      onTap: can
          ? () async {
        await game.grantDirectBtc(WeeklyChallengeService.rewardBtc);
        await weeklyChallenge.markClaimed();
        if (context.mounted) _toast(context, '🏆 Weekly reward!');
      }
          : null,
    );
  }
}

class _GoalsCard extends StatelessWidget {
  final GoalsService goals;
  final GameStateService game;
  const _GoalsCard({required this.goals, required this.game});

  @override
  Widget build(BuildContext context) {
    final can = goals.canClaimDaily || goals.canClaimWeekly;
    return _BonusMini(
      icon: Icons.flag_rounded,
      iconColor: _D.blue,
      iconBg: _D.blueBg,
      title: 'Daily goals',
      subtitle: '${(goals.dailyProgressPercent * 100).toStringAsFixed(0)}% mined',
      badge: can ? 'CLAIM' : '${(goals.dailyProgressPercent * 100).toStringAsFixed(0)}%',
      badgeColor: can ? _D.green : _D.blue,
      badgeBg: can ? _D.greenBg : _D.blueBg,
      badgeText: can ? _D.greenDeep : _D.blueDeep,
      progress: goals.dailyProgressPercent,
      progressColor: _D.blue,
      onTap: can
          ? () async {
        if (goals.canClaimDaily) {
          await game.grantDirectBtc(GoalsService.dailyRewardBtc);
          await goals.claimDaily();
          if (context.mounted) _toast(context, '🎯 Daily goal reward!');
        }
      }
          : null,
    );
  }
}

class _SpinCard extends StatelessWidget {
  final LuckySpinService spin;
  const _SpinCard({required this.spin});

  @override
  Widget build(BuildContext context) => _BonusMini(
    icon: Icons.casino_outlined,
    iconColor: _D.purple,
    iconBg: _D.purpleBg,
    title: 'Lucky spin',
    subtitle: 'Try your luck',
    badge: 'SPIN',
    badgeColor: _D.purple,
    badgeBg: _D.purpleBg,
    badgeText: _D.purpleDeep,
    onTap: () => Navigator.pushNamed(context, '/spin'),
  );
}

class _ReferralCard extends StatelessWidget {
  final ReferralService referral;
  const _ReferralCard({required this.referral});

  @override
  Widget build(BuildContext context) => _BonusMini(
    icon: Icons.people_outline_rounded,
    iconColor: _D.green,
    iconBg: _D.greenBg,
    title: 'Referrals',
    subtitle: '${referral.friends} friends joined',
    badge: 'INVITE',
    badgeColor: _D.green,
    badgeBg: _D.greenBg,
    badgeText: _D.greenDeep,
    onTap: () => Navigator.pushNamed(context, '/profile'),
  );
}

// ─── Season card ──────────────────────────────────────────────────────────────
class _SeasonCard extends StatelessWidget {
  final SeasonService season;
  final GameStateService game;
  const _SeasonCard({required this.season, required this.game});

  @override
  Widget build(BuildContext context) {
    final next = SeasonService.freeMilestones
        .firstWhere((m) => m > season.xp, orElse: () => SeasonService.freeMilestones.last);
    final progress = (season.xp / next).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _D.amberBg, borderRadius: _D.r10),
            child: const Icon(Icons.emoji_events_rounded, color: _D.amber, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Season ${season.seasonId}',
              style: GoogleFonts.dmSans(color: _D.text, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              '${season.xp} / $next XP',
              style: GoogleFonts.dmSans(color: _D.sub, fontSize: 11),
            ),
          ])),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.dmSans(color: _D.amber, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(3)),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: _D.borderSm,
            valueColor: const AlwaysStoppedAnimation(_D.amber),
          ),
        ),
        // Claimable rewards
        ...List.generate(SeasonService.freeMilestones.length, (i) {
          if (!season.canClaimFree(i)) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _ChipBtn(
              label: '${SeasonService.freeMilestones[i]} XP → +${SeasonService.freeRewardsBtc[i].toStringAsFixed(5)} BTC',
              color: _D.amberDeep,
              bg: _D.amberBg,
              borderColor: _D.amberBorder,
              onTap: () async {
                await game.grantDirectBtc(SeasonService.freeRewardsBtc[i]);
                await season.claimFreeReward(i);
                if (context.mounted) _toast(context, '🏆 Season reward!');
              },
            ),
          );
        }),
      ]),
    );
  }
}

// ─── Energy card ──────────────────────────────────────────────────────────────
class _EnergyCard extends StatelessWidget {
  final EnergyCoolingService energy;
  const _EnergyCard({required this.energy});

  @override
  Widget build(BuildContext context) {
    final t = (energy.heat / 100).clamp(0.0, 1.0);
    final heatColor = Color.lerp(_D.green, _D.red, t)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: heatColor.withOpacity(0.1),
            borderRadius: _D.r10,
          ),
          child: Icon(Icons.thermostat_rounded, color: heatColor, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Energy & cooling',
            style: GoogleFonts.dmSans(color: _D.text, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(2)),
            child: LinearProgressIndicator(
              value: t,
              minHeight: 4,
              backgroundColor: _D.borderSm,
              valueColor: AlwaysStoppedAnimation(heatColor),
            ),
          ),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${energy.heat.toStringAsFixed(0)}°',
            style: GoogleFonts.dmMono(color: heatColor, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text(
            '×${energy.efficiencyMultiplier.toStringAsFixed(2)}',
            style: GoogleFonts.dmMono(color: _D.sub, fontSize: 11),
          ),
        ]),
      ]),
    );
  }
}

// ─── Locations card ───────────────────────────────────────────────────────────
class _LocationsCard extends StatelessWidget {
  final ProgressionService progression;
  const _LocationsCard({required this.progression});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDeco(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: _D.blueBg, borderRadius: _D.r8),
          child: const Icon(Icons.map_outlined, color: _D.blue, size: 15),
        ),
        const SizedBox(width: 10),
        Text(
          'Mining locations',
          style: GoogleFonts.dmSans(color: _D.text, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ]),
      const SizedBox(height: 12),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: MiningLocations.all.map((loc) {
          final on = progression.unlockedLocations.contains(loc.id);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: on ? _D.blueBg : _D.bg,
              borderRadius: _D.r8,
              border: Border.all(
                color: on ? _D.blue.withOpacity(0.25) : _D.border,
                width: 0.5,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (on) ...[
                const Icon(Icons.check_circle_rounded, color: _D.blue, size: 11),
                const SizedBox(width: 4),
              ],
              Text(
                loc.name,
                style: GoogleFonts.dmSans(
                  color: on ? _D.blueDeep : _D.sub,
                  fontSize: 11,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    ]),
  );
}

// ─── Drop card ────────────────────────────────────────────────────────────────
class _DropCard extends StatelessWidget {
  final RandomDropService drop;
  final GameStateService game;
  const _DropCard({required this.drop, required this.game});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _D.amberBg,
      borderRadius: _D.r14,
      border: Border.all(color: _D.amberBorder, width: 0.5),
    ),
    child: Row(children: [
      const Text('✨', style: TextStyle(fontSize: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Hidden crypto block!',
          style: GoogleFonts.dmSans(color: _D.amberDeep, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        Text(
          'Tap to collect bonus BTC',
          style: GoogleFonts.dmSans(color: _D.sub, fontSize: 11),
        ),
      ])),
      _ChipBtn(
        label: 'Collect',
        color: _D.amberDeep,
        bg: _D.amber.withOpacity(0.15),
        borderColor: _D.amberBorder,
        onTap: () async {
          final bonus = await drop.collect();
          if (bonus != null) await game.grantDirectBtc(bonus);
          if (context.mounted) {
            _toast(context, '+${(bonus ?? 0).toStringAsFixed(6)} BTC collected!');
          }
        },
      ),
    ]),
  );
}

// ─── News card ────────────────────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  const _NewsCard();

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/news'),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: _D.amberBg, borderRadius: _D.r10),
          child: const Icon(Icons.article_outlined, color: _D.amber, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Latest Bitcoin news',
            style: GoogleFonts.dmSans(color: _D.text, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            'Stay updated on crypto markets',
            style: GoogleFonts.dmSans(color: _D.sub, fontSize: 11),
          ),
        ])),
        const Icon(Icons.chevron_right_rounded, color: _D.hint, size: 18),
      ]),
    ),
  );
}

// ─── Website card ─────────────────────────────────────────────────────────────
class _WebsiteCard extends StatelessWidget {
  final AdRemoteConfigService adCfg;
  const _WebsiteCard({required this.adCfg});

  @override
  Widget build(BuildContext context) {
    final url     = adCfg.customTabUrl;
    final display = url.length > 38 ? '${url.substring(0, 38)}…' : url;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: _D.blueBg, borderRadius: _D.r10),
          child: const Icon(Icons.open_in_browser_rounded, color: _D.blue, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Open website',
            style: GoogleFonts.dmSans(color: _D.text, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            display,
            style: GoogleFonts.dmSans(color: _D.sub, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ])),
        const SizedBox(width: 10),
        _ChipBtn(
          label: 'Open',
          color: _D.blueDeep,
          bg: _D.blueBg,
          borderColor: _D.blue.withOpacity(0.25),
          onTap: () => adCfg.openCustomTab(url),
        ),
      ]),
    );
  }
}

// ─── Chip button ──────────────────────────────────────────────────────────────
class _ChipBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final Color borderColor;
  final VoidCallback onTap;

  const _ChipBtn({
    required this.label,
    required this.color,
    required this.bg,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: _D.r8,
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ),
  );
}

// ─── Toast ────────────────────────────────────────────────────────────────────
void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: GoogleFonts.dmSans(color: _D.text, fontWeight: FontWeight.w500, fontSize: 13),
      ),
      backgroundColor: _D.white,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _D.border, width: 0.5),
      ),
      margin: const EdgeInsets.all(16),
      elevation: 2,
    ),
  );
}