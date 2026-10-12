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
import '../theme/app_theme.dart';
import '../theme/home_theme.dart';
import '../widgets/smart_banner_ad.dart';
import 'home_dashboard_content.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _T {
  // Backgrounds
  static const pageBg     = Color(0xFFF7F8FA);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFAFBFC);
  static const chipBg     = Color(0xFFF1F3F7);

  // Borders
  static const border     = Color(0xFFE8EBEF);
  static const borderSub  = Color(0xFFF0F2F6);

  // Amber / Gold
  static const amber      = Color(0xFFF59E0B);
  static const amberText  = Color(0xFF78350F);
  static const amberBg    = Color(0xFFFFFBEB);
  static const amberBdr   = Color(0xFFFDE68A);

  // Emerald
  static const green      = Color(0xFF10B981);
  static const greenText  = Color(0xFF064E3B);
  static const greenBg    = Color(0xFFF0FDF9);
  static const greenBdr   = Color(0xFFBBF7D0);

  // Sky
  static const blue       = Color(0xFF0EA5E9);
  static const blueText   = Color(0xFF0C4A6E);
  static const blueBg     = Color(0xFFF0F9FF);
  static const blueBdr    = Color(0xFFBAE6FD);

  // Violet
  static const violet     = Color(0xFF7C3AED);
  static const violetText = Color(0xFF4C1D95);
  static const violetBg   = Color(0xFFF5F3FF);
  static const violetBdr  = Color(0xFFDDD6FE);

  // Rose
  static const rose       = Color(0xFFEF4444);
  static const roseBg     = Color(0xFFFFF1F2);
  static const roseBdr    = Color(0xFFFECACA);

  // Text
  static const ink        = Color(0xFF0F1117);
  static const inkMid     = Color(0xFF6B7280);
  static const inkFaint   = Color(0xFFB8C0CC);

  // Radii
  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r10 = BorderRadius.all(Radius.circular(10));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));

  // Spacing
  static const px  = 20.0;  // horizontal page padding
  static const gap = 12.0;  // grid gap
  static const sec = 28.0;  // section spacing
}

// ─── Typography ───────────────────────────────────────────────────────────────
TextStyle _label({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _T.ink,
  double? letterSpacing,
  double? height,
}) => GoogleFonts.dmSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: letterSpacing,
  height: height,
);

TextStyle _mono({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _T.ink,
}) => GoogleFonts.jetBrainsMono(
  fontSize: size,
  fontWeight: weight,
  color: color,
);

// ─── Card decoration ──────────────────────────────────────────────────────────
BoxDecoration _card({
  Color? bg,
  Gradient? gradient,
  Color? border,
  BorderRadius? radius,
  List<BoxShadow>? shadows,
}) => BoxDecoration(
  color: gradient == null ? (bg ?? _T.surface) : null,
  gradient: gradient,
  borderRadius: radius ?? _T.r16,
  border: Border.all(color: border ?? _T.border, width: 0.75),
  boxShadow: shadows ?? const [
    BoxShadow(color: Color(0x07000000), blurRadius: 12, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x04000000), blurRadius: 3,  offset: Offset(0, 1)),
  ],
);

// ─── Main screen ──────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BtcPriceService>().fetchAll();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
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
      backgroundColor: _T.pageBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── App bar ────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: _T.pageBg,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 64,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  color: _T.pageBg,
                  border: Border(
                    bottom: BorderSide(color: _T.border, width: 0.75),
                  ),
                ),
              ),
              title: Row(children: [
                _AppBarLogo(),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mining Tycoon', style: _label(size: 16, weight: FontWeight.w700, letterSpacing: -0.3)),
                    const SizedBox(height: 1),
                    Text('DASHBOARD', style: _label(size: 9, weight: FontWeight.w600, color: _T.amber, letterSpacing: 1.8)),
                  ],
                ),
              ]),
              actions: [
                if (game.syncInProgress)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: _T.amber),
                    ),
                  ),
                _AppBarAction(
                  icon: Icons.person_outline_rounded,
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                const SizedBox(width: _T.px),
              ],
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(_T.px, 20, _T.px, AppTheme.pageBottomPadding(context)),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // ── Idle banner ──────────────────────────────────────────
                if (idle != null && idle > 0) ...[
                  FadeSlideIn(child: _IdleBanner(idle: idle)),
                  const SizedBox(height: 16),
                ],

                // ── Balance hero ─────────────────────────────────────────
                FadeSlideIn(
                  child: _BalanceHero(
                    btcBalance: game.btcBalance,
                    worthUsd: worthUsd,
                    btcPerMin: game.totalBtcPerMin,
                    isBoostActive: dailyBoost.isActive,
                    isSessionActive: game.isSessionActive,
                    sessionTimeLeft: game.sessionTimeLeft,
                    pulse: _pulse,
                  ),
                ),
                SizedBox(height: AppTheme.cardSpacing),

                // ── Mine CTA ─────────────────────────────────────────────
                FadeSlideIn(
                  delay: const Duration(milliseconds: 50),
                  child: _MineCTA(
                    isActive: game.isSessionActive,
                    onTap: () => Navigator.pushNamed(context, '/farm'),
                  ),
                ),
                SizedBox(height: AppTheme.sectionSpacing),

                // ── Stats row 1 ──────────────────────────────────────────
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Row(children: [
                    Expanded(child: _StatCard(
                      icon: Icons.memory_rounded,
                      iconColor: _T.blue, iconBg: _T.blueBg, iconBdr: _T.blueBdr,
                      label: 'Active rigs', value: '${game.ownedRigIds.length}',
                    )),
                    const SizedBox(width: _T.gap),
                    Expanded(child: _StatCard(
                      icon: Icons.factory_rounded,
                      iconColor: _T.amber, iconBg: _T.amberBg, iconBdr: _T.amberBdr,
                      label: 'Farm tier', value: game.currentFarmTier.name,
                    )),
                  ]),
                ),
                const SizedBox(height: _T.gap),

                // ── Stats row 2 ──────────────────────────────────────────
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Row(children: [
                    Expanded(child: _StatCard(
                      icon: Icons.savings_rounded,
                      iconColor: _T.green, iconBg: _T.greenBg, iconBdr: _T.greenBdr,
                      label: 'Lifetime mined',
                      value: '${game.lifetimeMinedBtc.toStringAsFixed(4)} ₿',
                    )),
                    const SizedBox(width: _T.gap),
                    Expanded(child: _StatCard(
                      icon: Icons.bolt_rounded,
                      iconColor: _T.violet, iconBg: _T.violetBg, iconBdr: _T.violetBdr,
                      label: 'Rate / min',
                      value: '${game.totalBtcPerMin.toStringAsFixed(6)} ₿',
                      mono: true,
                    )),
                  ]),
                ),
                const SizedBox(height: _T.sec),

                // ── BTC Market ───────────────────────────────────────────
                FadeSlideIn(delay: const Duration(milliseconds: 120), child: const _SectionHeader(label: 'BTC Market')),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 135),
                  child: Container(decoration: _card(), child: HomeGraphCard(priceService: btcPrice)),
                ),
                const SizedBox(height: _T.sec),

                // ── Quick actions ────────────────────────────────────────
                FadeSlideIn(delay: const Duration(milliseconds: 150), child: const _SectionHeader(label: 'Quick Actions')),
                const SizedBox(height: 12),
                FadeSlideIn(delay: const Duration(milliseconds: 165), child: _QuickActionsRow(context: context)),
                const SizedBox(height: _T.sec),

                // ── Bonuses ──────────────────────────────────────────────
                FadeSlideIn(delay: const Duration(milliseconds: 180), child: const _SectionHeader(label: 'Bonuses & Rewards')),
                const SizedBox(height: 12),

                if (comeback.canClaim) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 195),
                    child: _ComebackBanner(comeback: comeback, game: game),
                  ),
                  const SizedBox(height: _T.gap),
                ],

                FadeSlideIn(
                  delay: const Duration(milliseconds: 210),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _DailyBoostCard(dailyBoost: dailyBoost)),
                    const SizedBox(width: _T.gap),
                    Expanded(child: _LoginStreakCard(loginStreak: loginStreak, game: game)),
                  ]),
                ),
                const SizedBox(height: _T.gap),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 225),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _WeeklyChallengeCard(weeklyChallenge: weeklyChallenge, game: game)),
                    const SizedBox(width: _T.gap),
                    Expanded(child: _GoalsCard(goals: goals, game: game)),
                  ]),
                ),
                const SizedBox(height: _T.gap),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _SpinCard(spin: spin)),
                    const SizedBox(width: _T.gap),
                    Expanded(child: _ReferralCard(referral: referral)),
                  ]),
                ),
                const SizedBox(height: _T.gap),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 255),
                  child: _SeasonCard(season: season, game: game),
                ),
                const SizedBox(height: _T.sec),

                // ── Operations ───────────────────────────────────────────
                FadeSlideIn(delay: const Duration(milliseconds: 270), child: const _SectionHeader(label: 'Operations')),
                const SizedBox(height: 12),
                FadeSlideIn(delay: const Duration(milliseconds: 285), child: _EnergyCard(energy: energy)),
                const SizedBox(height: _T.gap),
                FadeSlideIn(delay: const Duration(milliseconds: 300), child: _LocationsCard(progression: progression)),
                const SizedBox(height: _T.sec),

                // ── Hidden drop ──────────────────────────────────────────
                if (drop.isAvailable) ...[
                  FadeSlideIn(delay: const Duration(milliseconds: 315), child: const _SectionHeader(label: 'Hidden Drop')),
                  const SizedBox(height: 12),
                  FadeSlideIn(delay: const Duration(milliseconds: 330), child: _DropCard(drop: drop, game: game)),
                  const SizedBox(height: _T.sec),
                ],

                // ── Discover ─────────────────────────────────────────────
                FadeSlideIn(delay: const Duration(milliseconds: 345), child: const _SectionHeader(label: 'Discover')),
                const SizedBox(height: 12),
                FadeSlideIn(delay: const Duration(milliseconds: 360), child: const _NewsCard()),

                if (adCfg.canShowWebsiteRedirect) ...[
                  const SizedBox(height: _T.gap),
                  FadeSlideIn(delay: const Duration(milliseconds: 375), child: _WebsiteCard(adCfg: adCfg)),
                ],
                const SizedBox(height: _T.sec),

                // ── How it works ─────────────────────────────────────────
                FadeSlideIn(delay: const Duration(milliseconds: 390), child: const _SectionHeader(label: 'How It Works')),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 405),
                  child: const Column(children: [
                    HomeHowMiningWorksCard(), SizedBox(height: 8),
                    HomeMiningRewardCard(),   SizedBox(height: 8),
                    HomeSecurityCard(),       SizedBox(height: 8),
                    HomeTransparencyCard(),
                  ]),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(delay: const Duration(milliseconds: 420), child: const HomeTestimonialsCard()),
                const SizedBox(height: 16),
                FadeSlideIn(delay: const Duration(milliseconds: 435), child: const HomeFaqCard()),
                const SizedBox(height: 16),

                // ── Ad ───────────────────────────────────────────────────
                if (adCfg.adsActive)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _card(border: _T.amberBdr),
                    child: const Column(children: [
                      MinimizableNativeAd(title: 'Sponsored offer'),
                      SizedBox(height: 10),
                      Center(child: SmartBannerAd()),
                    ]),
                  ),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App bar logo ─────────────────────────────────────────────────────────────
class _AppBarLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
      color: _T.amberBg,
      borderRadius: _T.r12,
      border: Border.all(color: _T.amberBdr, width: 0.75),
      boxShadow: [BoxShadow(color: _T.amber.withOpacity(0.16), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: const Icon(Icons.currency_bitcoin, color: _T.amber, size: 19),
  );
}

// ─── App bar action button ────────────────────────────────────────────────────
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: _T.r12,
        border: Border.all(color: _T.border, width: 0.75),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, color: _T.inkMid, size: 17),
    ),
  );
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 3, height: 14,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(color: _T.amber, borderRadius: BorderRadius.circular(2)),
      ),
      Text(
        label.toUpperCase(),
        style: _label(size: 10, weight: FontWeight.w700, color: _T.inkMid, letterSpacing: 1.5),
      ),
    ],
  );
}

// ─── Idle banner ──────────────────────────────────────────────────────────────
class _IdleBanner extends StatelessWidget {
  final double idle;
  const _IdleBanner({required this.idle});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: _card(
      bg: _T.amberBg, border: _T.amberBdr, radius: _T.r16,
      shadows: [BoxShadow(color: _T.amber.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _T.amber.withOpacity(0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.notifications_active_rounded, color: _T.amber, size: 17),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back!', style: _label(size: 13, weight: FontWeight.w700, color: _T.amberText)),
        const SizedBox(height: 2),
        Text('Miners earned +${idle.toStringAsFixed(8)} BTC while away', style: _label(size: 11, color: _T.amber)),
      ])),
      const SizedBox(width: 4),
      Icon(Icons.chevron_right_rounded, color: _T.amber.withOpacity(0.5), size: 18),
    ]),
  );
}

// ─── Balance hero card ────────────────────────────────────────────────────────
class _BalanceHero extends StatelessWidget {
  final double btcBalance;
  final double? worthUsd;
  final double btcPerMin;
  final bool isBoostActive, isSessionActive;
  final Duration sessionTimeLeft;
  final AnimationController pulse;

  const _BalanceHero({
    required this.btcBalance, required this.worthUsd, required this.btcPerMin,
    required this.isBoostActive, required this.isSessionActive,
    required this.sessionTimeLeft, required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final intPart = btcBalance.floor().toString();
    final decPart = '.${btcBalance.toStringAsFixed(12).split('.')[1]}';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.6, 1.0],
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFDF7), Color(0xFFFDF8ED)],
        ),
        borderRadius: _T.r24,
        border: Border.all(color: _T.amberBdr, width: 0.75),
        boxShadow: [
          BoxShadow(color: _T.amber.withOpacity(0.1),    blurRadius: 32, offset: const Offset(0, 10)),
          const BoxShadow(color: Color(0x07000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        // Ambient glow
        Positioned(
          top: -80, right: -80,
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _T.amber.withOpacity(0.05 + 0.04 * pulse.value),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),
        // Dot texture
        Positioned.fill(child: CustomPaint(painter: _DotTexture())),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header row
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: _T.amberBg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _T.amberBdr, width: 0.75),
                  ),
                  child: const Icon(Icons.currency_bitcoin, color: _T.amber, size: 15),
                ),
                const SizedBox(width: 10),
                Text('BTC BALANCE', style: _label(size: 10, weight: FontWeight.w600, color: _T.inkMid, letterSpacing: 1.6)),
              ]),
              Row(children: [
                if (isBoostActive)
                  _StatusPill(label: '2× BOOST', color: _T.amber, bg: _T.amberBg, border: _T.amberBdr, textColor: _T.amberText),
                if (isBoostActive && isSessionActive) const SizedBox(width: 6),
                if (isSessionActive)
                  _StatusPill(label: 'LIVE', color: _T.green, bg: _T.greenBg, border: _T.greenBdr, textColor: _T.greenText),
              ]),
            ]),

            const SizedBox(height: 26),

            // Balance display (12 decimal places)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  intPart,
                  style: GoogleFonts.dmSans(
                    fontSize: 44, fontWeight: FontWeight.w700,
                    color: _T.ink, height: 1.0, letterSpacing: -1.6,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    decPart,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15, fontWeight: FontWeight.w500,
                      color: _T.amber, height: 1.0, letterSpacing: -0.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8),
                  child: Text('BTC', style: _label(size: 12, weight: FontWeight.w600, color: _T.inkMid, letterSpacing: 1.0)),
                ),
              ]),
            ),

            const SizedBox(height: 5),
            Text(
              worthUsd != null ? '≈ \$${worthUsd!.toStringAsFixed(2)} USD' : '≈ — USD',
              style: _label(size: 12, color: _T.inkMid),
            ),

            const SizedBox(height: 22),
            Container(height: 0.75, color: _T.borderSub),
            const SizedBox(height: 18),

            // Footer row
            Row(children: [
              _PulseDot(),
              const SizedBox(width: 8),
              Text(
                '${btcPerMin.toStringAsFixed(8)} BTC/min',
                style: _mono(size: 11, weight: FontWeight.w500, color: _T.green),
              ),
              const Spacer(),
              if (isSessionActive) ...[
                Icon(Icons.timer_outlined, color: _T.inkFaint, size: 12),
                const SizedBox(width: 5),
                Text(
                  '${sessionTimeLeft.inMinutes}:${(sessionTimeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: _mono(size: 11, color: _T.inkMid),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ─── Dot texture painter ──────────────────────────────────────────────────────
class _DotTexture extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF000000).withOpacity(0.022);
    const step = 18.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── Status pill ──────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color, bg, border, textColor;
  const _StatusPill({required this.label, required this.color, required this.bg, required this.border, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: border, width: 0.75),
    ),
    child: Text(label, style: _label(size: 8, weight: FontWeight.w700, color: textColor, letterSpacing: 0.9)),
  );
}

// ─── Pulse dot ────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 7, height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _T.green,
        boxShadow: [BoxShadow(
          color: _T.green.withOpacity(0.2 + 0.4 * _c.value),
          blurRadius: 4 + 6 * _c.value,
          spreadRadius: _c.value * 0.5,
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
    final bg     = isActive ? _T.greenBg   : _T.amberBg;
    final border = isActive ? _T.greenBdr  : _T.amberBdr;
    final ic     = isActive ? _T.green     : _T.amber;
    final tc     = isActive ? _T.greenText : _T.amberText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: _T.r16,
          border: Border.all(color: border, width: 0.75),
          boxShadow: [BoxShadow(color: ic.withOpacity(0.09), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: ic.withOpacity(0.13),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(isActive ? Icons.bolt_rounded : Icons.play_arrow_rounded, color: ic, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            isActive ? 'Session running — View farm' : 'Start mining session',
            style: _label(size: 14, weight: FontWeight.w600, color: tc, letterSpacing: -0.1),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, color: ic.withOpacity(0.4), size: 15),
        ]),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg, iconBdr;
  final String label, value;
  final bool mono;

  const _StatCard({
    required this.icon, required this.iconColor, required this.iconBg,
    required this.iconBdr, required this.label, required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _card(),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: iconBdr, width: 0.75),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: _label(size: 11, color: _T.inkMid)),
        const SizedBox(height: 4),
        Text(
          value,
          style: mono ? _mono(size: 12, weight: FontWeight.w600) : _label(size: 13, weight: FontWeight.w700),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
      ])),
    ]),
  );
}

// ─── Quick actions row ────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final BuildContext context;
  const _QuickActionsRow({required this.context});

  @override
  Widget build(BuildContext ctx) {
    final items = [
      (Icons.account_balance_wallet_outlined, 'Wallet',   _T.blue,   _T.blueBg,   _T.blueBdr,   '/profile'),
      (Icons.payments_outlined,               'Withdraw', _T.green,  _T.greenBg,  _T.greenBdr,  '/profile'),
      (Icons.group_add_outlined,              'Invite',   _T.violet, _T.violetBg, _T.violetBdr, '/profile'),
      (Icons.show_chart_rounded,              'Stats',    _T.amber,  _T.amberBg,  _T.amberBdr,  '/farm'),
    ];
    return Row(
      children: List.generate(items.length, (i) {
        final item = items[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < items.length - 1 ? _T.gap : 0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, item.$6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: _card(radius: _T.r16),
                child: Column(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: item.$4,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: item.$5, width: 0.75),
                    ),
                    child: Icon(item.$1, color: item.$3, size: 17),
                  ),
                  const SizedBox(height: 10),
                  Text(item.$2, style: _label(size: 11, weight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Comeback banner ──────────────────────────────────────────────────────────
class _ComebackBanner extends StatelessWidget {
  final ComebackBonusService comeback;
  final GameStateService game;
  const _ComebackBanner({required this.comeback, required this.game});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: _card(
      bg: _T.amberBg, border: _T.amberBdr,
      shadows: [BoxShadow(color: _T.amber.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 6))],
    ),
    child: Row(children: [
      const Text('👋', style: TextStyle(fontSize: 26)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back!', style: _label(size: 14, weight: FontWeight.w700, color: _T.amberText)),
        const SizedBox(height: 2),
        Text('+${ComebackBonusService.bonusBtc.toStringAsFixed(5)} BTC waiting for you',
            style: _label(size: 12, weight: FontWeight.w500, color: _T.amber)),
      ])),
      const SizedBox(width: 12),
      _ActionChip(
        label: 'Claim',
        textColor: _T.amberText,
        bg: _T.amber.withOpacity(0.12),
        border: _T.amberBdr,
        onTap: () async {
          await game.grantDirectBtc(ComebackBonusService.bonusBtc);
          await comeback.markClaimed();
          if (context.mounted) _showToast(context, '🎁 Welcome back bonus claimed!');
        },
      ),
    ]),
  );
}

// ─── Bonus mini card ──────────────────────────────────────────────────────────
class _BonusMini extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg, iconBdr;
  final String title, subtitle;
  final String? badge;
  final Color? badgeBg, badgeBdr, badgeTextColor;
  final double? progress;
  final Color? progressColor;
  final VoidCallback? onTap;

  const _BonusMini({
    required this.icon, required this.iconColor, required this.iconBg, required this.iconBdr,
    required this.title, required this.subtitle,
    this.badge, this.badgeBg, this.badgeBdr, this.badgeTextColor,
    this.progress, this.progressColor, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = badge != null && onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: _card(border: isActive ? (badgeBdr ?? _T.amberBdr) : _T.border),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconBdr, width: 0.75),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg ?? _T.amberBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeBdr ?? _T.amberBdr, width: 0.75),
                ),
                child: Text(badge!, style: _label(
                  size: 8, weight: FontWeight.w700,
                  color: badgeTextColor ?? _T.amberText, letterSpacing: 0.6,
                )),
              ),
          ]),
          const SizedBox(height: 12),
          Text(title, style: _label(size: 13, weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(subtitle, style: _label(size: 11, color: _T.inkMid)),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: _T.chipBg,
                valueColor: AlwaysStoppedAnimation(progressColor ?? _T.amber),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── Individual bonus cards ───────────────────────────────────────────────────
class _DailyBoostCard extends StatelessWidget {
  final DailyBoostService dailyBoost;
  const _DailyBoostCard({required this.dailyBoost});

  @override
  Widget build(BuildContext context) {
    final ready = dailyBoost.canClaim;
    return _BonusMini(
      icon: Icons.bolt_rounded,
      iconColor: _T.amber, iconBg: _T.amberBg, iconBdr: _T.amberBdr,
      title: 'Daily boost', subtitle: ready ? '2× speed ready!' : 'Resets in 24h',
      badge: ready ? 'READY' : null,
      badgeBg: _T.amberBg, badgeBdr: _T.amberBdr, badgeTextColor: _T.amberText,
      onTap: ready ? () async {
        final ok = await dailyBoost.claim();
        if (ok && context.mounted) _showToast(context, '⚡ 2× boost activated!');
      } : null,
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
    final can = loginStreak.canClaimStreak3 || loginStreak.canClaimStreak7;
    return _BonusMini(
      icon: Icons.local_fire_department_rounded,
      iconColor: _T.rose, iconBg: _T.roseBg, iconBdr: _T.roseBdr,
      title: 'Login streak',
      subtitle: days == 0 ? 'Come back tomorrow' : '$days day${days == 1 ? '' : 's'} 🔥',
      badge: can ? 'CLAIM' : null,
      badgeBg: _T.greenBg, badgeBdr: _T.greenBdr, badgeTextColor: _T.greenText,
      onTap: can ? () async {
        if (loginStreak.canClaimStreak7) {
          await game.grantDirectBtc(0.00003);
          await loginStreak.markStreak7Claimed();
          if (context.mounted) _showToast(context, '🔥 7-day reward!');
        } else {
          await game.grantDirectBtc(0.00001);
          await loginStreak.markStreak3Claimed();
          if (context.mounted) _showToast(context, '🔥 3-day reward!');
        }
      } : null,
    );
  }
}

class _WeeklyChallengeCard extends StatelessWidget {
  final WeeklyChallengeService weeklyChallenge;
  final GameStateService game;
  const _WeeklyChallengeCard({required this.weeklyChallenge, required this.game});

  @override
  Widget build(BuildContext context) {
    final prog = weeklyChallenge.progressThisWeek(game.totalSessionsStarted);
    final can  = weeklyChallenge.canClaim(game.totalSessionsStarted);
    return _BonusMini(
      icon: Icons.emoji_events_rounded,
      iconColor: _T.violet, iconBg: _T.violetBg, iconBdr: _T.violetBdr,
      title: 'Weekly',
      subtitle: '$prog/${WeeklyChallengeService.targetSessions} sessions',
      badge: can ? 'CLAIM' : '$prog/${WeeklyChallengeService.targetSessions}',
      badgeBg: can ? _T.greenBg : _T.violetBg,
      badgeBdr: can ? _T.greenBdr : _T.violetBdr,
      badgeTextColor: can ? _T.greenText : _T.violetText,
      progress: prog / WeeklyChallengeService.targetSessions,
      progressColor: _T.violet,
      onTap: can ? () async {
        await game.grantDirectBtc(WeeklyChallengeService.rewardBtc);
        await weeklyChallenge.markClaimed();
        if (context.mounted) _showToast(context, '🏆 Weekly reward!');
      } : null,
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
      iconColor: _T.blue, iconBg: _T.blueBg, iconBdr: _T.blueBdr,
      title: 'Daily goals',
      subtitle: '${(goals.dailyProgressPercent * 100).toStringAsFixed(0)}% mined',
      badge: can ? 'CLAIM' : '${(goals.dailyProgressPercent * 100).toStringAsFixed(0)}%',
      badgeBg: can ? _T.greenBg : _T.blueBg,
      badgeBdr: can ? _T.greenBdr : _T.blueBdr,
      badgeTextColor: can ? _T.greenText : _T.blueText,
      progress: goals.dailyProgressPercent, progressColor: _T.blue,
      onTap: can ? () async {
        if (goals.canClaimDaily) {
          await game.grantDirectBtc(GoalsService.dailyRewardBtc);
          await goals.claimDaily();
          if (context.mounted) _showToast(context, '🎯 Daily goal reward!');
        }
      } : null,
    );
  }
}

class _SpinCard extends StatelessWidget {
  final LuckySpinService spin;
  const _SpinCard({required this.spin});

  @override
  Widget build(BuildContext context) => _BonusMini(
    icon: Icons.casino_outlined,
    iconColor: _T.violet, iconBg: _T.violetBg, iconBdr: _T.violetBdr,
    title: 'Lucky spin', subtitle: 'Try your luck',
    badge: 'SPIN', badgeBg: _T.violetBg, badgeBdr: _T.violetBdr, badgeTextColor: _T.violetText,
    onTap: () => Navigator.pushNamed(context, '/spin'),
  );
}

class _ReferralCard extends StatelessWidget {
  final ReferralService referral;
  const _ReferralCard({required this.referral});

  @override
  Widget build(BuildContext context) => _BonusMini(
    icon: Icons.people_outline_rounded,
    iconColor: _T.green, iconBg: _T.greenBg, iconBdr: _T.greenBdr,
    title: 'Referrals', subtitle: '${referral.friends} friends joined',
    badge: 'INVITE', badgeBg: _T.greenBg, badgeBdr: _T.greenBdr, badgeTextColor: _T.greenText,
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
      padding: const EdgeInsets.all(20),
      decoration: _card(
        bg: _T.amberBg, border: _T.amberBdr,
        shadows: [BoxShadow(color: _T.amber.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _T.amber.withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.amberBdr, width: 0.75),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: _T.amber, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Season ${season.seasonId}', style: _label(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${season.xp} / $next XP', style: _label(size: 12, color: _T.inkMid)),
          ])),
          Text('${(progress * 100).toStringAsFixed(0)}%',
              style: _label(size: 18, weight: FontWeight.w700, color: _T.amber)),
        ]),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress, minHeight: 6,
            backgroundColor: _T.amber.withOpacity(0.14),
            valueColor: const AlwaysStoppedAnimation(_T.amber),
          ),
        ),
        ...List.generate(SeasonService.freeMilestones.length, (i) {
          if (!season.canClaimFree(i)) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _ActionChip(
              label: '${SeasonService.freeMilestones[i]} XP → +${SeasonService.freeRewardsBtc[i].toStringAsFixed(5)} BTC',
              textColor: _T.amberText,
              bg: _T.amber.withOpacity(0.1),
              border: _T.amberBdr,
              onTap: () async {
                await game.grantDirectBtc(SeasonService.freeRewardsBtc[i]);
                await season.claimFreeReward(i);
                if (context.mounted) _showToast(context, '🏆 Season reward!');
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
    final heatColor = Color.lerp(_T.green, _T.rose, t)!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: heatColor.withOpacity(0.09),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: heatColor.withOpacity(0.22), width: 0.75),
          ),
          child: Icon(Icons.thermostat_rounded, color: heatColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Energy & cooling', style: _label(size: 13, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: t, minHeight: 4,
              backgroundColor: _T.chipBg,
              valueColor: AlwaysStoppedAnimation(heatColor),
            ),
          ),
        ])),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${energy.heat.toStringAsFixed(0)}°',
              style: _mono(size: 22, weight: FontWeight.w600, color: heatColor)),
          const SizedBox(height: 2),
          Text('×${energy.efficiencyMultiplier.toStringAsFixed(2)}',
              style: _mono(size: 11, color: _T.inkMid)),
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
    padding: const EdgeInsets.all(18),
    decoration: _card(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _T.blueBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _T.blueBdr, width: 0.75),
          ),
          child: const Icon(Icons.map_outlined, color: _T.blue, size: 16),
        ),
        const SizedBox(width: 11),
        Text('Mining locations', style: _label(size: 13, weight: FontWeight.w600)),
      ]),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: MiningLocations.all.map((loc) {
          final on = progression.unlockedLocations.contains(loc.id);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: on ? _T.blueBg : _T.chipBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: on ? _T.blueBdr : _T.borderSub, width: 0.75),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (on) ...[
                const Icon(Icons.check_circle_rounded, color: _T.blue, size: 12),
                const SizedBox(width: 5),
              ],
              Text(loc.name, style: _label(
                size: 12,
                weight: on ? FontWeight.w600 : FontWeight.w400,
                color: on ? _T.blueText : _T.inkMid,
              )),
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
    padding: const EdgeInsets.all(18),
    decoration: _card(
      bg: _T.amberBg, border: _T.amberBdr,
      shadows: [BoxShadow(color: _T.amber.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 5))],
    ),
    child: Row(children: [
      const Text('✨', style: TextStyle(fontSize: 26)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hidden crypto block!', style: _label(size: 14, weight: FontWeight.w700, color: _T.amberText)),
        const SizedBox(height: 2),
        Text('Tap to collect bonus BTC', style: _label(size: 12, color: _T.inkMid)),
      ])),
      const SizedBox(width: 12),
      _ActionChip(
        label: 'Collect',
        textColor: _T.amberText,
        bg: _T.amber.withOpacity(0.12),
        border: _T.amberBdr,
        onTap: () async {
          final bonus = await drop.collect();
          if (bonus != null) await game.grantDirectBtc(bonus);
          if (context.mounted)
            _showToast(context, '+${(bonus ?? 0).toStringAsFixed(6)} BTC collected!');
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
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _T.amberBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.amberBdr, width: 0.75),
          ),
          child: const Icon(Icons.article_outlined, color: _T.amber, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Latest Bitcoin news', style: _label(size: 13, weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('Stay updated on crypto markets', style: _label(size: 11, color: _T.inkMid)),
        ])),
        Icon(Icons.chevron_right_rounded, color: _T.inkFaint, size: 20),
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
    final display = url.length > 36 ? '${url.substring(0, 36)}…' : url;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: _T.blueBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _T.blueBdr, width: 0.75),
          ),
          child: const Icon(Icons.open_in_browser_rounded, color: _T.blue, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Open website', style: _label(size: 13, weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(display, style: _label(size: 11, color: _T.inkMid),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 10),
        _ActionChip(
          label: 'Open',
          textColor: _T.blueText,
          bg: _T.blueBg,
          border: _T.blueBdr,
          onTap: () => adCfg.openCustomTab(url),
        ),
      ]),
    );
  }
}

// ─── Action chip ──────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final String label;
  final Color textColor, bg, border;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label, required this.textColor,
    required this.bg, required this.border, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 0.75),
      ),
      child: Text(label, style: _label(size: 12, weight: FontWeight.w700, color: textColor)),
    ),
  );
}

// ─── Toast ────────────────────────────────────────────────────────────────────
void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: _label(size: 13, weight: FontWeight.w500, color: _T.ink)),
      backgroundColor: _T.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _T.border, width: 0.75),
      ),
      margin: const EdgeInsets.all(16),
      elevation: 4,
    ),
  );
}