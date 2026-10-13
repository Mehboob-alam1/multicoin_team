import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/mining_economy.dart';
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
import '../services/auth_service.dart';
import '../services/progression_service.dart';
import '../services/random_drop_service.dart';
import '../services/referral_service.dart';
import '../services/season_service.dart';
import '../services/weekly_challenge_service.dart';
import '../widgets/btc_price_chart.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/screen_ad_slot.dart';
import '../theme/app_theme.dart';
import '../theme/home_theme.dart';
import '../theme/solana.dart';
import '../widgets/app_brand_logo.dart';
import '../widgets/solana_widgets.dart';
import '../widgets/user_circle_avatar.dart';
import 'home_dashboard_content.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _T {
  // Backgrounds
  static const pageBg     = Color(0xFF08080A);
  static const surface    = Color(0xFF18181C);
  static const surfaceAlt = Color(0xFF111114);
  static const chipBg     = Color(0xFF1C1C22);
  static const cardTop    = Color(0xFF1D1D23);
  static const cardBot    = Color(0xFF131316);

  // Borders & Glass
  static const border      = Color(0x1FFFFFFF);
  static const borderSub   = Color(0x14FFFFFF);
  static const glassBorder = Color(0x2DFFFFFF);

  // Solana purple
  static const amber     = Color(0xFF9945FF);
  static const amberText = Color(0xFFE9D5FF);
  static const amberBg   = Color(0xFF1A1228);
  static const amberBdr  = Color(0x669945FF);

  // Solana green
  static const green     = Color(0xFF14F195);
  static const greenText = Color(0xFFBBF7D0);
  static const greenBg   = Color(0xFF0A2E22);
  static const greenBdr  = Color(0x6614F195);

  // Sky
  static const blue     = Color(0xFF38BDF8);
  static const blueText = Color(0xFFBAE6FD);
  static const blueBg   = Color(0xFF0C1A24);
  static const blueBdr  = Color(0xFF164E63);

  // Violet
  static const violet     = Color(0xFFA78BFA);
  static const violetText = Color(0xFFDDD6FE);
  static const violetBg   = Color(0xFF1A1228);
  static const violetBdr  = Color(0xFF4C1D95);

  // Rose
  static const rose    = Color(0xFFF43F5E);
  static const roseBg  = Color(0xFF3F1219);
  static const roseBdr = Color(0xFF881337);

  // Text
  static const ink      = Color(0xFFF4F4F5);
  static const inkMid   = Color(0xFFA1A1AA);
  static const inkFaint = Color(0xFF71717A);

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
  static const sec = 30.0;

  // Max content width (tablet / desktop)
  static const maxW = 1000.0;

  static const brand = LinearGradient(
    colors: [Color(0xFF9945FF), Color(0xFF14F195)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Typography ───────────────────────────────────────────────────────────────
TextStyle _label({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _T.ink,
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
  Color color = _T.ink,
}) => GoogleFonts.spaceMono(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: -0.3,
);

// ─── Reusable premium card ────────────────────────────────────────────────────
/// Soft gradient surface with hairline border. [accent] adds a tinted wash and
/// a coloured glow. (No real backdrop-blur: keeps long scrolling lists smooth.)
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color? accent;
  final bool glow;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = _T.r24,
    this.accent,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final a = accent;
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          if (a != null && glow)
            BoxShadow(
              color: a.withOpacity(0.20),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: const Color(0xFF9945FF).withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    colors: a == null
                        ? const [Color(0xF21F1F26), Color(0xE6121216)]
                        : [
                            Color.alphaBlend(a.withOpacity(0.16), const Color(0xF21F1F26)),
                            Color.alphaBlend(a.withOpacity(0.04), const Color(0xE6121216)),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: a == null ? _T.glassBorder : a.withOpacity(0.38),
                    width: 0.8,
                  ),
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
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0x38FFFFFF),
                        Color(0x00FFFFFF),
                      ],
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

/// Rounded icon tile used everywhere.
class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color, bg, border;
  final double size;
  final double iconSize;

  const _IconTile({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    this.size = 40,
    this.iconSize = 19,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.3),
      gradient: LinearGradient(
        colors: [Color.alphaBlend(color.withOpacity(0.22), bg), bg],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: border, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.18),
          blurRadius: 14,
          spreadRadius: -2,
        ),
      ],
    ),
    child: Icon(icon, color: color, size: iconSize),
  );
}

/// Animated gradient progress bar.
class _GradientBar extends StatelessWidget {
  final double value;
  final List<Color> colors;
  final double height;
  final Color? track;

  const _GradientBar({
    required this.value,
    required this.colors,
    this.height = 6,
    this.track,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: Container(
      height: height,
      color: track ?? Colors.white.withOpacity(0.07),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Responsive equal-height grid. Column count adapts to available width.
class _Grid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final int maxCols;

  const _Grid({
    required this.children,
    this.minItemWidth = 150,
    this.maxCols = 3,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      var cols = ((c.maxWidth + _T.gap) / (minItemWidth + _T.gap)).floor();
      cols = cols.clamp(1, maxCols);
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += cols) {
        final slice = children.skip(i).take(cols).toList();
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: _T.gap),
                Expanded(
                  child: j < slice.length ? slice[j] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ));
        if (i + cols < children.length) {
          rows.add(const SizedBox(height: _T.gap));
        }
      }
      return Column(children: rows);
    },
  );
}

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
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BtcPriceService>().fetchAll();
      final sessions = context.read<GameStateService>().totalSessionsStarted;
      context.read<WeeklyChallengeService>().load(sessions);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game            = context.read<GameStateService>();
    final auth            = context.watch<AuthService>();
    final userName        = auth.displayNameOf(auth.currentUser);
    final userPhoto       = auth.photoUrlOf(auth.currentUser);
    final btcPrice        = context.watch<BtcPriceService>();
    final progression     = context.watch<ProgressionService>();
    final dailyBoost      = context.watch<DailyBoostService>();
    final drop            = context.watch<RandomDropService>();
    final energy          = context.read<EnergyCoolingService>();
    final adCfg           = context.watch<AdRemoteConfigService>();
    final loginStreak     = context.watch<LoginStreakService>();
    final weeklyChallenge = context.watch<WeeklyChallengeService>();
    final goals           = context.watch<GoalsService>();
    final comeback        = context.watch<ComebackBonusService>();
    final referral        = context.watch<ReferralService>();
    final season          = context.watch<SeasonService>();
    final spin            = context.watch<LuckySpinService>();
    final premium         = context.select<GameStateService, bool>((g) => g.isPremiumActive);

    // Responsive side padding: centres content on large screens.
    final screenW = MediaQuery.sizeOf(context).width;
    final sidePad = screenW > _T.maxW + _T.px * 2
        ? (screenW - _T.maxW) / 2
        : (screenW < 360 ? 14.0 : _T.px);

    return Scaffold(
      backgroundColor: _T.pageBg,
      body: Stack(
        children: [
          // Ambient background glow
          Positioned(
            top: -140,
            right: -100,
            child: IgnorePointer(child: _Orb(color: _T.amber, size: 380, opacity: 0.16)),
          ),
          Positioned(
            top: 320,
            left: -160,
            child: IgnorePointer(child: _Orb(color: _T.green, size: 340, opacity: 0.07)),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: 400,
              slivers: [
                // ── App bar ──────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: _T.pageBg.withOpacity(0.94),
                  surfaceTintColor: Colors.transparent,
                  toolbarHeight: 72,
                  automaticallyImplyLeading: false,
                  titleSpacing: sidePad,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      color: _T.pageBg.withOpacity(0.94),
                      border: const Border(
                        bottom: BorderSide(color: _T.borderSub, width: 0.8),
                      ),
                    ),
                  ),
                  title: Row(children: [
                    _AppBarLogo(),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (r) => _T.brand.createShader(r),
                            child: Text('DASHBOARD',
                                style: _label(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.8,
                                )),
                          ),
                          const SizedBox(height: 2),
                          Text(userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _label(
                                  size: 19,
                                  weight: FontWeight.w700,
                                  letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                  ]),
                  actions: [
                    if (game.syncInProgress)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _T.amber),
                        ),
                      ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _T.brand,
                          boxShadow: [
                            BoxShadow(
                              color: _T.amber.withOpacity(0.35),
                              blurRadius: 14,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _T.pageBg,
                          ),
                          child: UserCircleAvatar(
                              name: userName, photoUrl: userPhoto, size: 38),
                        ),
                      ),
                    ),
                    SizedBox(width: sidePad),
                  ],
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      sidePad, 22, sidePad, AppTheme.pageBottomPadding(context)),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _LiveMiningBlock(pulse: _pulse),
                      if (!premium && adCfg.shouldShowSdkAds) ...[
                        const SizedBox(height: 16),
                        const ScreenAdSlot(title: 'Home offer'),
                      ],
                      const SizedBox(height: _T.sec),

                      // ── SOL Market ─────────────────────────────────────
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 120),
                        child: const _SectionHeader(label: 'SOL Market'),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 135),
                        child: _Card(
                          padding: const EdgeInsets.all(16),
                          child: HomeGraphCard(priceService: btcPrice),
                        ),
                      ),
                      const SizedBox(height: _T.sec),

                      // ── Quick actions ──────────────────────────────────
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: const _SectionHeader(label: 'Quick Actions'),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 165),
                        child: _QuickActionsRow(context: context),
                      ),
                      const SizedBox(height: _T.sec),

                      // ── Bonuses ────────────────────────────────────────
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: const _SectionHeader(label: 'Bonuses & Rewards'),
                      ),
                      const SizedBox(height: 14),

                      if (comeback.canClaim) ...[
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 195),
                          child: _ComebackBanner(comeback: comeback, game: game),
                        ),
                        const SizedBox(height: _T.gap),
                      ],

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 210),
                        child: _Grid(
                          minItemWidth: 150,
                          maxCols: 3,
                          children: [
                            _DailyBoostCard(dailyBoost: dailyBoost),
                            _LoginStreakCard(loginStreak: loginStreak, game: game),
                            _WeeklyChallengeCard(
                                weeklyChallenge: weeklyChallenge, game: game),
                            _GoalsCard(goals: goals, game: game),
                            _SpinCard(spin: spin),
                            _ReferralCard(referral: referral),
                          ],
                        ),
                      ),
                      const SizedBox(height: _T.gap),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 255),
                        child: _SeasonCard(season: season, game: game),
                      ),
                      const SizedBox(height: _T.sec),

                      // ── Operations ─────────────────────────────────────
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 270),
                        child: const _SectionHeader(label: 'Operations'),
                      ),
                      const SizedBox(height: 14),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 285),
                        child: _EnergyCard(energy: energy),
                      ),
                      const SizedBox(height: _T.gap),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: _LocationsCard(progression: progression),
                      ),
                      const SizedBox(height: _T.sec),

                      // ── Hidden drop ────────────────────────────────────
                      if (drop.isAvailable) ...[
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 315),
                          child: const _SectionHeader(label: 'Hidden Drop'),
                        ),
                        const SizedBox(height: 14),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 330),
                          child: _DropCard(drop: drop, game: game),
                        ),
                        const SizedBox(height: _T.sec),
                      ],

                      // ── Discover ───────────────────────────────────────
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 345),
                        child: const _SectionHeader(label: 'Discover'),
                      ),
                      const SizedBox(height: 14),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 360),
                        child: const _NewsCard(),
                      ),

                      if (adCfg.canShowWebsiteRedirect) ...[
                        const SizedBox(height: _T.gap),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 375),
                          child: _WebsiteCard(adCfg: adCfg),
                        ),
                      ],
                      const SizedBox(height: _T.sec),

                      // ── How it works ───────────────────────────────────
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 390),
                        child: const _SectionHeader(label: 'How It Works'),
                      ),
                      const SizedBox(height: 14),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 405),
                        child: const Column(children: [
                          HomeHowMiningWorksCard(),
                          SizedBox(height: 10),
                          HomeMiningRewardCard(),
                          SizedBox(height: 10),
                          HomeSecurityCard(),
                          SizedBox(height: 10),
                          HomeTransparencyCard(),
                        ]),
                      ),
                      const SizedBox(height: 18),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 420),
                        child: const HomeTestimonialsCard(),
                      ),
                      const SizedBox(height: 18),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 435),
                        child: const HomeFaqCard(),
                      ),
                    ]),
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

// ─── Ambient orb ──────────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _Orb({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
      ),
    ),
  );
}

// ─── Live mining block ────────────────────────────────────────────────────────
class _LiveMiningBlock extends StatelessWidget {
  const _LiveMiningBlock({required this.pulse});
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final btcPrice = context.watch<BtcPriceService>();
    final dailyBoost = context.watch<DailyBoostService>();
    final idle = game.getIdleEarnedIfAny();
    final worthUsd = btcPrice.balanceWorthUsd(game.btcBalance);
    return Column(
      children: [
        if (idle != null && idle > 0) ...[
          _IdleBanner(idle: idle),
          const SizedBox(height: 16),
        ],
        _BalanceHero(
          btcBalance: game.btcBalance,
          worthUsd: worthUsd,
          btcPerMin: game.totalBtcPerMin,
          isBoostActive: dailyBoost.isActive,
          isSessionActive: game.isSessionActive,
          sessionTimeLeft: game.sessionTimeLeft,
          pulse: pulse,
        ),
        SizedBox(height: AppTheme.cardSpacing + 4),
        _MineCTA(
          isActive: game.isSessionActive,
          onTap: () async {
            if (!game.isSessionActive) {
              await game.startMiningSession();
            }
            if (context.mounted) Navigator.pushNamed(context, '/farm');
          },
        ),
        const SizedBox(height: 22),
        _Grid(
          minItemWidth: 150,
          maxCols: 4,
          children: [
            _StatCard(
              icon: Icons.memory_rounded,
              iconColor: _T.blue,
              iconBg: _T.blueBg,
              iconBdr: _T.blueBdr,
              label: 'Active rigs',
              value: '${game.ownedRigIds.length}',
            ),
            _StatCard(
              icon: Icons.factory_rounded,
              iconColor: _T.amber,
              iconBg: _T.amberBg,
              iconBdr: _T.amberBdr,
              label: 'Farm tier',
              value: game.currentFarmTier.name,
            ),
            _StatCard(
              icon: Icons.savings_rounded,
              iconColor: _T.green,
              iconBg: _T.greenBg,
              iconBdr: _T.greenBdr,
              label: 'Lifetime mined',
              value: '${game.lifetimeMinedBtc.toStringAsFixed(4)} SOL',
            ),
            _StatCard(
              icon: Icons.bolt_rounded,
              iconColor: _T.violet,
              iconBg: _T.violetBg,
              iconBdr: _T.violetBdr,
              label: 'Rate / min',
              value: '${game.totalBtcPerMin.toStringAsFixed(6)} SOL',
            ),
          ],
        ),
      ],
    );
  }
}

// ─── App bar logo ─────────────────────────────────────────────────────────────
class _AppBarLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: _T.amber.withOpacity(0.35),
          blurRadius: 16,
          spreadRadius: -2,
        ),
      ],
    ),
    child: const AppBrandLogo(size: 42, circular: true),
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
        width: 3,
        height: 16,
        margin: const EdgeInsets.only(right: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_T.amber, _T.green],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: _T.amber.withOpacity(0.45),
              blurRadius: 8,
            )
          ],
        ),
      ),
      Text(
        label.toUpperCase(),
        style: _label(
          size: 11.5,
          weight: FontWeight.w700,
          color: _T.ink,
          letterSpacing: 1.6,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x26FFFFFF), Color(0x00FFFFFF)],
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── Idle banner ──────────────────────────────────────────────────────────────
class _IdleBanner extends StatelessWidget {
  final double idle;
  const _IdleBanner({required this.idle});

  @override
  Widget build(BuildContext context) => _Card(
    accent: _T.amber,
    glow: true,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      const _IconTile(
        icon: Icons.notifications_active_rounded,
        color: _T.amber,
        bg: _T.amberBg,
        border: _T.amberBdr,
        size: 40,
        iconSize: 19,
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back!',
                style: _label(
                    size: 14.5, weight: FontWeight.w700, color: _T.amberText)),
            const SizedBox(height: 2),
            Text('Miners earned +${idle.toStringAsFixed(8)} SOL while away',
                style: _label(size: 12, color: _T.inkMid, height: 1.35)),
          ],
        ),
      ),
      const SizedBox(width: 6),
      Icon(Icons.chevron_right_rounded,
          color: _T.amber.withOpacity(0.5), size: 20),
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
    final decPart = '.${btcBalance.toStringAsFixed(12).split('.')[1]}';
    final narrow = MediaQuery.sizeOf(context).width < 360;

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: _T.r28,
          gradient: Solana.brand,
          boxShadow: [
            BoxShadow(
              color: _T.amber.withOpacity(0.22 + 0.12 * pulse.value),
              blurRadius: 44,
              spreadRadius: -6,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: _T.green.withOpacity(0.08 + 0.05 * pulse.value),
              blurRadius: 60,
              spreadRadius: -10,
              offset: const Offset(-10, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(1.5),
        child: child,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: Solana.cardWash,
          borderRadius: BorderRadius.all(Radius.circular(26.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // Ambient glows
          Positioned(
            top: -110,
            right: -90,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => _Orb(
                color: _T.amber,
                size: 300,
                opacity: 0.14 + 0.08 * pulse.value,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _Orb(color: _T.green, size: 280, opacity: 0.08),
          ),

          // Dot texture
          Positioned.fill(child: CustomPaint(painter: _DotTexture())),

          Padding(
            padding: EdgeInsets.all(narrow ? 20 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const _IconTile(
                          icon: Icons.hexagon_rounded,
                          color: _T.amber,
                          bg: _T.amberBg,
                          border: _T.amberBdr,
                          size: 34,
                          iconSize: 17,
                        ),
                        const SizedBox(width: 11),
                        Flexible(
                          child: Text('SOL BALANCE',
                              overflow: TextOverflow.ellipsis,
                              style: _label(
                                size: 11,
                                weight: FontWeight.w700,
                                color: _T.inkMid,
                                letterSpacing: 1.8,
                              )),
                        ),
                      ]),
                    ),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      if (isBoostActive)
                        _StatusPill(
                          label: '2× BOOST',
                          color: _T.amber,
                          bg: _T.amberBg,
                          border: _T.amberBdr,
                          textColor: _T.amberText,
                        ),
                      if (isBoostActive && isSessionActive)
                        const SizedBox(width: 7),
                      if (isSessionActive)
                        _StatusPill(
                          label: 'LIVE',
                          color: _T.green,
                          bg: _T.greenBg,
                          border: _T.greenBdr,
                          textColor: _T.greenText,
                          dot: true,
                        ),
                    ]),
                  ],
                ),

                const SizedBox(height: 26),

                // Balance display
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        intPart,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: _T.ink,
                          height: 1.0,
                          letterSpacing: -2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Text(
                          decPart,
                          style: GoogleFonts.spaceMono(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: _T.amber,
                            height: 1.0,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9, left: 10),
                        child: Text('SOL',
                            style: _label(
                              size: 14,
                              weight: FontWeight.w700,
                              color: _T.inkMid,
                              letterSpacing: 1,
                            )),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _T.border, width: 0.8),
                  ),
                  child: Text(
                    worthUsd != null
                        ? '≈ \$${worthUsd!.toStringAsFixed(2)} USD'
                        : '≈ — USD',
                    style: _label(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: _T.inkMid),
                  ),
                ),

                const SizedBox(height: 22),
                Container(
                  height: 0.8,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0x33FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Footer row
                Row(children: [
                  _PulseDot(),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      '${btcPerMin.toStringAsFixed(8)} SOL/min',
                      overflow: TextOverflow.ellipsis,
                      style: _mono(
                        size: 12,
                        weight: FontWeight.w500,
                        color: _T.green,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSessionActive) ...[
                    const Icon(Icons.timer_outlined,
                        color: _T.inkFaint, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${sessionTimeLeft.inMinutes}:${(sessionTimeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: _mono(size: 12.5, color: _T.ink),
                    ),
                  ],
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Dot texture painter ──────────────────────────────────────────────────────
class _DotTexture extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.035);
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
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
  final bool dot;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
    required this.textColor,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: border, width: 0.8),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.22), blurRadius: 12, spreadRadius: -2),
      ],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (dot) ...[
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
      ],
      Text(
        label,
        style: _label(
          size: 9.5,
          weight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.9,
        ),
      ),
    ]),
  );
}

// ─── Pulse dot ────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _T.green,
        boxShadow: [
          BoxShadow(
            color: _T.green.withOpacity(0.25 + 0.35 * _c.value),
            blurRadius: 6 + 8 * _c.value,
            spreadRadius: _c.value * 0.8,
          )
        ],
      ),
    ),
  );
}

// ─── Mine CTA ─────────────────────────────────────────────────────────────────
class _MineCTA extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _MineCTA({required this.isActive, required this.onTap});

  @override
  State<_MineCTA> createState() => _MineCTAState();
}

class _MineCTAState extends State<_MineCTA> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: _T.r20,
            gradient: active
                ? LinearGradient(
              colors: [
                Color.alphaBlend(_T.green.withOpacity(0.18), _T.cardTop),
                Color.alphaBlend(_T.green.withOpacity(0.05), _T.cardBot),
              ],
            )
                : _T.brand,
            border: Border.all(
              color: active ? _T.greenBdr : Colors.white.withOpacity(0.22),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: (active ? _T.green : _T.amber)
                    .withOpacity(_isPressed ? 0.18 : 0.38),
                blurRadius: 26,
                spreadRadius: -4,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? _T.green.withOpacity(0.16)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: active
                        ? _T.green.withOpacity(0.35)
                        : Colors.white.withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  active ? Icons.bolt_rounded : Icons.play_arrow_rounded,
                  color: active ? _T.green : Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  active ? 'Session running — View farm' : 'Start mining session',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _label(
                    size: 15.5,
                    weight: FontWeight.w700,
                    color: active ? _T.greenText : Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                color: (active ? _T.green : Colors.white).withOpacity(0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg, iconBdr;
  final String label, value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.iconBdr,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => _Card(
    padding: const EdgeInsets.all(13),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(children: [
      _IconTile(
        icon: icon,
        color: iconColor,
        bg: iconBg,
        border: iconBdr,
        size: 38,
        iconSize: 18,
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _label(
                    size: 11, color: _T.inkMid, weight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              value,
              style: _label(size: 13.5, weight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ]),
    ),
  );
}

// ─── Quick actions row ────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final BuildContext context;

  const _QuickActionsRow({required this.context});

  @override
  Widget build(BuildContext ctx) {
    final items = [
      (Icons.account_balance_wallet_outlined, 'Wallet', _T.blue, _T.blueBg,
      _T.blueBdr, '/profile'),
      (Icons.payments_outlined, 'Withdraw', _T.green, _T.greenBg, _T.greenBdr,
      '/profile'),
      (Icons.group_add_outlined, 'Invite', _T.violet, _T.violetBg,
      _T.violetBdr, '/profile'),
      (Icons.show_chart_rounded, 'Stats', _T.amber, _T.amberBg, _T.amberBdr,
      '/farm'),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < items.length - 1 ? _T.gap : 0),
              child: _PressScale(
                onTap: () => Navigator.pushNamed(context, item.$6),
                child: _Card(
                  radius: _T.r20,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _IconTile(
                        icon: item.$1,
                        color: item.$3,
                        bg: item.$4,
                        border: item.$5,
                        size: 44,
                        iconSize: 20,
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _label(size: 12, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Tap target with a subtle press-scale.
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressScale({required this.child, this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
    onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
    onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _down ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

// ─── Comeback banner ──────────────────────────────────────────────────────────
class _ComebackBanner extends StatelessWidget {
  final ComebackBonusService comeback;
  final GameStateService game;

  const _ComebackBanner({required this.comeback, required this.game});

  @override
  Widget build(BuildContext context) => _Card(
    accent: _T.amber,
    glow: true,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    child: Row(children: [
      const Text('👋', style: TextStyle(fontSize: 30)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back!',
                style: _label(
                    size: 15.5, weight: FontWeight.w700, color: _T.amberText)),
            const SizedBox(height: 2),
            Text(
              '+${MiningEconomy.toSol(ComebackBonusService.bonusBtc).toStringAsFixed(4)} SOL waiting for you',
              style: _label(size: 12.5, weight: FontWeight.w500, color: _T.inkMid),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      _ActionChip(
        label: 'Claim',
        textColor: Colors.white,
        bg: _T.amber.withOpacity(0.14),
        border: _T.amberBdr,
        filled: true,
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
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.iconBdr,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeBg,
    this.badgeBdr,
    this.badgeTextColor,
    this.progress,
    this.progressColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = badge != null && onTap != null;

    return _PressScale(
      onTap: onTap,
      child: _Card(
        accent: isActive ? iconColor : null,
        glow: isActive,
        padding: const EdgeInsets.all(15),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 148),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _IconTile(
                    icon: icon,
                    color: iconColor,
                    bg: iconBg,
                    border: iconBdr,
                    size: 38,
                    iconSize: 18,
                  ),
                  if (badge != null)
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg ?? _T.amberBg,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: badgeBdr ?? _T.amberBdr, width: 0.8),
                        ),
                        child: Text(
                          badge!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _label(
                            size: 9.5,
                            weight: FontWeight.w700,
                            color: badgeTextColor ?? _T.amberText,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 38, height: 22),
                ],
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _label(size: 14.5, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 32,
                    child: Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _label(
                            size: 12,
                            color: _T.inkMid,
                            weight: FontWeight.w500,
                            height: 1.3)),
                  ),
                  const SizedBox(height: 12),
                  if (progress != null)
                    _GradientBar(
                      value: progress!,
                      height: 4.5,
                      colors: [
                        (progressColor ?? _T.amber).withOpacity(0.6),
                        progressColor ?? _T.amber,
                      ],
                    )
                  else
                    const SizedBox(height: 4.5),
                ],
              ),
            ],
          ),
        ),
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
      iconColor: _T.amber,
      iconBg: _T.amberBg,
      iconBdr: _T.amberBdr,
      title: 'Daily boost',
      subtitle: ready ? '2× speed ready!' : 'Resets in 24h',
      badge: ready ? 'READY' : null,
      badgeBg: _T.amberBg,
      badgeBdr: _T.amberBdr,
      badgeTextColor: _T.amberText,
      onTap: ready
          ? () async {
        final ok = await dailyBoost.claim();
        if (ok && context.mounted) _showToast(context, '⚡ 2× boost activated!');
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
    final can = loginStreak.canClaimStreak3 || loginStreak.canClaimStreak7;

    return _BonusMini(
      icon: Icons.local_fire_department_rounded,
      iconColor: _T.rose,
      iconBg: _T.roseBg,
      iconBdr: _T.roseBdr,
      title: 'Login streak',
      subtitle: days == 0 ? 'Come back tomorrow' : '$days day${days == 1 ? '' : 's'} 🔥',
      badge: can ? 'CLAIM' : null,
      badgeBg: _T.greenBg,
      badgeBdr: _T.greenBdr,
      badgeTextColor: _T.greenText,
      onTap: can
          ? () async {
        if (loginStreak.canClaimStreak7) {
          await game.grantDirectBtc(0.00003);
          await loginStreak.markStreak7Claimed();
          if (context.mounted) _showToast(context, '🔥 7-day reward!');
        } else {
          await game.grantDirectBtc(0.00001);
          await loginStreak.markStreak3Claimed();
          if (context.mounted) _showToast(context, '🔥 3-day reward!');
        }
      }
          : null,
    );
  }
}

class _WeeklyChallengeCard extends StatelessWidget {
  final WeeklyChallengeService weeklyChallenge;
  final GameStateService game;

  const _WeeklyChallengeCard(
      {required this.weeklyChallenge, required this.game});

  @override
  Widget build(BuildContext context) {
    final prog = weeklyChallenge.progressThisWeek(game.totalSessionsStarted);
    final can = weeklyChallenge.canClaim(game.totalSessionsStarted);

    return _BonusMini(
      icon: Icons.emoji_events_rounded,
      iconColor: _T.violet,
      iconBg: _T.violetBg,
      iconBdr: _T.violetBdr,
      title: 'Weekly',
      subtitle: '$prog/${WeeklyChallengeService.targetSessions} sessions',
      badge: can ? 'CLAIM' : '$prog/${WeeklyChallengeService.targetSessions}',
      badgeBg: can ? _T.greenBg : _T.violetBg,
      badgeBdr: can ? _T.greenBdr : _T.violetBdr,
      badgeTextColor: can ? _T.greenText : _T.violetText,
      progress: prog / WeeklyChallengeService.targetSessions,
      progressColor: _T.violet,
      onTap: can
          ? () async {
        await game.grantDirectBtc(WeeklyChallengeService.rewardBtc);
        await weeklyChallenge.markClaimed();
        if (context.mounted) _showToast(context, '🏆 Weekly reward!');
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
      iconColor: _T.blue,
      iconBg: _T.blueBg,
      iconBdr: _T.blueBdr,
      title: 'Daily goals',
      subtitle: '${(goals.dailyProgressPercent * 100).toStringAsFixed(0)}% mined',
      badge: can
          ? 'CLAIM'
          : '${(goals.dailyProgressPercent * 100).toStringAsFixed(0)}%',
      badgeBg: can ? _T.greenBg : _T.blueBg,
      badgeBdr: can ? _T.greenBdr : _T.blueBdr,
      badgeTextColor: can ? _T.greenText : _T.blueText,
      progress: goals.dailyProgressPercent,
      progressColor: _T.blue,
      onTap: can
          ? () async {
        if (goals.canClaimDaily) {
          await game.grantDirectBtc(GoalsService.dailyRewardBtc);
          await goals.claimDaily();
          if (context.mounted) _showToast(context, '🎯 Daily goal reward!');
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
    iconColor: _T.violet,
    iconBg: _T.violetBg,
    iconBdr: _T.violetBdr,
    title: 'Lucky spin',
    subtitle: 'Try your luck',
    badge: 'SPIN',
    badgeBg: _T.violetBg,
    badgeBdr: _T.violetBdr,
    badgeTextColor: _T.violetText,
    onTap: () => Navigator.pushNamed(context, '/spin'),
  );
}

class _ReferralCard extends StatelessWidget {
  final ReferralService referral;

  const _ReferralCard({required this.referral});

  @override
  Widget build(BuildContext context) => _BonusMini(
    icon: Icons.people_outline_rounded,
    iconColor: _T.green,
    iconBg: _T.greenBg,
    iconBdr: _T.greenBdr,
    title: 'Referrals',
    subtitle: '${referral.friends} friends joined',
    badge: 'INVITE',
    badgeBg: _T.greenBg,
    badgeBdr: _T.greenBdr,
    badgeTextColor: _T.greenText,
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
    final next = SeasonService.freeMilestones.firstWhere((m) => m > season.xp,
        orElse: () => SeasonService.freeMilestones.last);
    final progress = (season.xp / next).clamp(0.0, 1.0);

    return _Card(
      accent: _T.amber,
      glow: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _IconTile(
              icon: Icons.emoji_events_rounded,
              color: _T.amber,
              bg: _T.amberBg,
              border: _T.amberBdr,
              size: 48,
              iconSize: 23,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Season ${season.seasonId}',
                      style: _label(size: 16, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${season.xp} / $next XP',
                      style: _label(size: 12.5, color: _T.inkMid)),
                ],
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => _T.brand.createShader(r),
              child: Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: _label(
                    size: 24,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  )),
            ),
          ]),
          const SizedBox(height: 18),
          _GradientBar(
            value: progress,
            height: 8,
            colors: const [_T.amber, _T.green],
          ),
          ...List.generate(SeasonService.freeMilestones.length, (i) {
            if (!season.canClaimFree(i)) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _ActionChip(
                label:
                '${SeasonService.freeMilestones[i]} XP → +${MiningEconomy.toSol(SeasonService.freeRewardsBtc[i]).toStringAsFixed(4)} SOL',
                textColor: Colors.white,
                bg: _T.amber.withOpacity(0.12),
                border: _T.amberBdr,
                filled: true,
                onTap: () async {
                  await game.grantDirectBtc(SeasonService.freeRewardsBtc[i]);
                  await season.claimFreeReward(i);
                  if (context.mounted) _showToast(context, '🏆 Season reward!');
                },
              ),
            );
          }),
        ],
      ),
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

    return _Card(
      accent: heatColor,
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: heatColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: heatColor.withOpacity(0.35), width: 0.8),
            boxShadow: [
              BoxShadow(
                  color: heatColor.withOpacity(0.2),
                  blurRadius: 14,
                  spreadRadius: -2),
            ],
          ),
          child: Icon(Icons.thermostat_rounded, color: heatColor, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Energy & cooling',
                  style: _label(size: 14.5, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              _GradientBar(
                value: t,
                height: 6,
                colors: [_T.green, heatColor],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${energy.heat.toStringAsFixed(0)}°',
                style: _mono(
                  size: 24,
                  weight: FontWeight.w700,
                  color: heatColor,
                )),
            const SizedBox(height: 2),
            Text('×${energy.efficiencyMultiplier.toStringAsFixed(2)}',
                style: _mono(size: 12, color: _T.inkMid)),
          ],
        ),
      ]),
    );
  }
}

// ─── Locations card ───────────────────────────────────────────────────────────
class _LocationsCard extends StatelessWidget {
  final ProgressionService progression;

  const _LocationsCard({required this.progression});

  @override
  Widget build(BuildContext context) => _Card(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const _IconTile(
            icon: Icons.map_outlined,
            color: _T.blue,
            bg: _T.blueBg,
            border: _T.blueBdr,
            size: 38,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Text('Mining locations',
              style: _label(size: 14.5, weight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MiningLocations.all.map((loc) {
            final on = progression.unlockedLocations.contains(loc.id);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: on ? _T.blueBg : _T.chipBg,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: on ? _T.blueBdr : _T.borderSub,
                  width: 0.8,
                ),
                boxShadow: on
                    ? [
                  BoxShadow(
                      color: _T.blue.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: -2)
                ]
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  on ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                  color: on ? _T.blue : _T.inkFaint,
                  size: 13,
                ),
                const SizedBox(width: 6),
                Text(
                  loc.name,
                  style: _label(
                    size: 12,
                    weight: on ? FontWeight.w600 : FontWeight.w500,
                    color: on ? _T.blueText : _T.inkMid,
                  ),
                ),
              ]),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// ─── Drop card ────────────────────────────────────────────────────────────────
class _DropCard extends StatelessWidget {
  final RandomDropService drop;
  final GameStateService game;

  const _DropCard({required this.drop, required this.game});

  @override
  Widget build(BuildContext context) => _Card(
    accent: _T.amber,
    glow: true,
    padding: const EdgeInsets.all(18),
    child: Row(children: [
      const Text('✨', style: TextStyle(fontSize: 30)),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hidden crypto block!',
                style: _label(
                    size: 15.5, weight: FontWeight.w700, color: _T.amberText)),
            const SizedBox(height: 2),
            Text('Tap to collect bonus SOL',
                style: _label(size: 12.5, color: _T.inkMid)),
          ],
        ),
      ),
      const SizedBox(width: 12),
      _ActionChip(
        label: 'Collect',
        textColor: Colors.white,
        bg: _T.amber.withOpacity(0.14),
        border: _T.amberBdr,
        filled: true,
        onTap: () async {
          final bonus = await drop.collect();
          if (bonus != null) await game.grantDirectBtc(bonus);
          if (context.mounted) {
            _showToast(context,
                '+${MiningEconomy.toSol(bonus ?? 0).toStringAsFixed(6)} SOL collected!');
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
  Widget build(BuildContext context) => _PressScale(
    onTap: () => Navigator.pushNamed(context, '/news'),
    child: _Card(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        const _IconTile(
          icon: Icons.article_outlined,
          color: _T.amber,
          bg: _T.amberBg,
          border: _T.amberBdr,
          size: 46,
          iconSize: 20,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Latest Solana news',
                  style: _label(size: 14.5, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text('Stay updated on the Solana network',
                  style: _label(size: 12, color: _T.inkMid)),
            ],
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: _T.border, width: 0.8),
          ),
          child: const Icon(Icons.chevron_right_rounded,
              color: _T.inkMid, size: 19),
        ),
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
    final url = adCfg.customTabUrl;
    final display = url.length > 36 ? '${url.substring(0, 36)}…' : url;

    return _Card(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        const _IconTile(
          icon: Icons.open_in_browser_rounded,
          color: _T.blue,
          bg: _T.blueBg,
          border: _T.blueBdr,
          size: 46,
          iconSize: 20,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Open website',
                  style: _label(size: 14.5, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(display,
                  style: _label(size: 12, color: _T.inkMid),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 11),
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
  final bool filled; // brand-gradient style
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.textColor,
    required this.bg,
    required this.border,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => _PressScale(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: filled ? _T.brand : null,
        color: filled ? null : bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? Colors.white.withOpacity(0.2) : border,
          width: 0.8,
        ),
        boxShadow: filled
            ? [
          BoxShadow(
            color: _T.amber.withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          )
        ]
            : null,
      ),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _label(
            size: 13,
            weight: FontWeight.w700,
            color: textColor,
          )),
    ),
  );
}

// ─── Toast ────────────────────────────────────────────────────────────────────
void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: _label(size: 14, weight: FontWeight.w600, color: _T.ink),
      ),
      backgroundColor: _T.cardTop,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _T.amber.withOpacity(0.4), width: 0.8),
      ),
      margin: const EdgeInsets.all(18),
      elevation: 8,
    ),
  );
}