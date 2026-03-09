import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mining_location.dart';
import '../services/btc_price_service.dart';
import '../services/daily_boost_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/game_state_service.dart';
import '../services/login_streak_service.dart';
import '../services/notification_service.dart';
import '../services/progression_service.dart';
import '../services/weekly_challenge_service.dart';
import '../services/goals_service.dart';
import '../services/season_service.dart';
import '../services/comeback_bonus_service.dart';
import '../services/referral_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/analytics_service.dart';
import '../services/random_drop_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/btc_price_chart.dart';
import '../widgets/minimizable_native_ad.dart';
import '../widgets/smart_banner_ad.dart';

// ─── Design tokens ──────────────────────────────────────────────────────────
class _D {
  static const bg        = Color(0xFF080B12);
  static const surface   = Color(0xFF0E1420);
  static const card      = Color(0xFF121826);
  static const cardBord  = Color(0xFF1E2A3A);
  static const gold      = Color(0xFFF5A623);
  static const goldSoft  = Color(0xFFFFD97D);
  static const electric  = Color(0xFF00D4FF);
  static const green     = Color(0xFF00E5A0);
  static const red       = Color(0xFFFF4D6A);
  static const purple    = Color(0xFFB06EFF);
  static const textHi    = Color(0xFFF0F4FF);
  static const textMid   = Color(0xFF8899BB);
  static const textLow   = Color(0xFF3D4F6B);

  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);
  static const r20 = Radius.circular(20);
  static const r24 = Radius.circular(24);

  static const fontDisplay = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
}

// ─── Main screen ────────────────────────────────────────────────────────────
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
    final game       = context.watch<GameStateService>();
    final btcPrice   = context.watch<BtcPriceService>();
    final progression= context.watch<ProgressionService>();
    final dailyBoost = context.watch<DailyBoostService>();
    final drop       = context.watch<RandomDropService>();
    final energy     = context.watch<EnergyCoolingService>();
    final adCfg      = context.watch<AdRemoteConfigService>();
    final loginStreak = context.watch<LoginStreakService>();
    final weeklyChallenge = context.watch<WeeklyChallengeService>();
    final goals = context.watch<GoalsService>();
    final comeback = context.watch<ComebackBonusService>();
    final referral = context.watch<ReferralService>();
    final season = context.watch<SeasonService>();
    if (game.isLoaded) weeklyChallenge.load(game.totalSessionsStarted);
    final idle       = game.getIdleEarnedIfAny();
    final worthUsd   = btcPrice.balanceWorthUsd(game.btcBalance);

    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _D.bg,
        body: Stack(
          children: [
            // ── Ambient background glow ──────────────────────────────────
            Positioned(
              top: -120,
              left: -80,
              child: _AmbientBlob(color: _D.gold.withValues(alpha: 0.07), size: 360),
            ),
            Positioned(
              top: 200,
              right: -100,
              child: _AmbientBlob(color: _D.electric.withValues(alpha: 0.05), size: 280),
            ),

            // ── Content ──────────────────────────────────────────────────
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App bar
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 0,
                    backgroundColor: _D.bg.withValues(alpha: 0.92),
                    surfaceTintColor: Colors.transparent,
                    title: Row(
                      children: [
                        _GoldBitcoinIcon(pulse: _pulseCtrl),
                        const SizedBox(width: 10),
                        Text(
                          'Bitcoin Mining',
                          style: _D.fontDisplay.copyWith(
                            fontSize: 16,
                            color: _D.gold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      if (game.syncInProgress)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _D.electric,
                            ),
                          ),
                        ),
                      if (game.lastSyncError != null && !game.syncInProgress)
                        Tooltip(
                          message: game.lastSyncError!,
                          child: const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                        ),
                      _AppBarBtn(
                        icon: Icons.person_outline_rounded,
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // ── Idle earnings banner ─────────────────────────
                        if (idle != null && idle > 0) ...[
                          _IdleBanner(idle: idle),
                          const SizedBox(height: 14),
                        ],

                        // ── Hero balance card ─────────────────────────────
                        _BalanceCard(
                          btcBalance: game.btcBalance,
                          worthUsd: worthUsd,
                          btcPerMin: game.totalBtcPerMin,
                          isBoostActive: game.isBoostActive,
                          isPremiumActive: game.isPremiumActive,
                          pulse: _pulseCtrl,
                        ),
                        const SizedBox(height: 14),

                        // ── Stats row ────────────────────────────────────
                        _StatsRow(game: game),
                        const SizedBox(height: 14),

                        // ── Mining session ───────────────────────────────
                        _MiningSessionCard(game: game),
                        const SizedBox(height: 14),

                        // ── Daily & weekly goals ──────────────────────────
                        _GoalsCard(goals: goals, game: game),
                        const SizedBox(height: 14),

                        // ── Come-back bonus ───────────────────────────────
                        if (comeback.canClaim) ...[
                          _ComebackCard(comeback: comeback, game: game),
                          const SizedBox(height: 14),
                        ],

                        // ── Refer-a-friend (prominent) ───────────────────
                        _ReferralPromoCard(referral: referral),
                        const SizedBox(height: 14),

                        // ── Season / battle pass ──────────────────────────
                        _SeasonCard(season: season, game: game),
                        const SizedBox(height: 14),

                        // ── Login streak (daily comeback) ─────────────────
                        _LoginStreakCard(loginStreak: loginStreak, game: game),
                        const SizedBox(height: 14),

                        // ── Weekly challenge ──────────────────────────────
                        _WeeklyChallengeCard(
                          weeklyChallenge: weeklyChallenge,
                          game: game,
                        ),
                        const SizedBox(height: 14),

                        // ── Daily boost ──────────────────────────────────
                        _DailyBoostCard(dailyBoost: dailyBoost),
                        const SizedBox(height: 14),

                        // ── Energy & cooling ─────────────────────────────
                        _EnergyCard(energy: energy),
                        const SizedBox(height: 14),

                        // ── Map progression ──────────────────────────────
                        _MapProgressionCard(progression: progression),
                        const SizedBox(height: 14),

                        // ── Random drop ──────────────────────────────────
                        if (drop.isAvailable) ...[
                          _DropCard(drop: drop, game: game),
                          const SizedBox(height: 14),
                        ],

                        // ── BTC price chart ──────────────────────────────
                        _ChartWrapper(),
                        const SizedBox(height: 14),

                        // ── BTC News (community / updates) ───────────────
                        _NewsCard(),
                        const SizedBox(height: 14),

                        // ── Website redirect ─────────────────────────────
                        if (adCfg.canShowWebsiteRedirect) ...[
                          _WebsiteCard(adCfg: adCfg),
                          const SizedBox(height: 14),
                        ],

                        // ── Ads ──────────────────────────────────────────
                        if (adCfg.adsActive) ...[
                          const MinimizableNativeAd(title: 'Sponsored offer'),
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

// ─── App bar icon button ──────────────────────────────────────────────────────
class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _D.cardBord,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _D.textMid, size: 18),
    ),
  );
}

// ─── Ambient blob ────────────────────────────────────────────────────────────
class _AmbientBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
    ),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: const SizedBox.shrink(),
    ),
  );
}

// ─── Gold bitcoin icon with pulse ────────────────────────────────────────────
class _GoldBitcoinIcon extends StatelessWidget {
  final AnimationController pulse;
  const _GoldBitcoinIcon({required this.pulse});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulse,
    builder: (_, __) => Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          _D.gold,
          _D.gold.withValues(alpha: 0.6 + 0.4 * pulse.value),
        ]),
        boxShadow: [
          BoxShadow(
            color: _D.gold.withValues(alpha: 0.3 + 0.3 * pulse.value),
            blurRadius: 12 + 8 * pulse.value,
          ),
        ],
      ),
      child: const Icon(Icons.currency_bitcoin, color: Colors.black, size: 16),
    ),
  );
}

// ─── Idle banner ─────────────────────────────────────────────────────────────
class _IdleBanner extends StatelessWidget {
  final double idle;
  const _IdleBanner({required this.idle});

  @override
  Widget build(BuildContext context) => _GlassCard(
    borderColor: _D.gold.withValues(alpha: 0.4),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _D.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_active_rounded,
              color: _D.gold, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back!',
                  style: TextStyle(
                      color: _D.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(
                'Miners generated +${idle.toStringAsFixed(8)} BTC',
                style: const TextStyle(color: _D.textMid, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── Hero balance card ───────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double btcBalance;
  final double? worthUsd;
  final double btcPerMin;
  final bool isBoostActive;
  final bool isPremiumActive;
  final AnimationController pulse;

  const _BalanceCard({
    required this.btcBalance,
    required this.worthUsd,
    required this.btcPerMin,
    required this.isBoostActive,
    required this.isPremiumActive,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final parts = btcBalance.toStringAsFixed(8).split('.');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2235), Color(0xFF0F1520)],
        ),
        border: Border.all(color: _D.cardBord, width: 1),
        boxShadow: [
          BoxShadow(
            color: _D.gold.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner decoration
          Positioned(
            top: -20,
            right: -20,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _D.gold.withValues(alpha: 0.08 + 0.04 * pulse.value),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BTC BALANCE',
                        style: TextStyle(
                            color: _D.textMid,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600)),
                    if (isBoostActive || isPremiumActive)
                      Row(children: [
                        if (isBoostActive)
                          _Pill(label: '2× BOOST', color: _D.electric),
                        if (isBoostActive && isPremiumActive)
                          const SizedBox(width: 6),
                        if (isPremiumActive)
                          _Pill(label: 'PREMIUM', color: _D.gold),
                      ]),
                  ],
                ),
                const SizedBox(height: 16),

                // Balance — mono digits, large
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      parts[0],
                      style: _D.fontDisplay.copyWith(
                        fontSize: 44,
                        color: _D.textHi,
                        height: 1,
                      ),
                    ),
                    Text(
                      '.${parts[1]}',
                      style: _D.fontDisplay.copyWith(
                        fontSize: 26,
                        color: _D.gold,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (worthUsd != null)
                  Text(
                    '≈ \$${worthUsd!.toStringAsFixed(2)} USD',
                    style: const TextStyle(color: _D.textMid, fontSize: 13),
                  ),

                const SizedBox(height: 20),
                const Divider(color: _D.cardBord, height: 1),
                const SizedBox(height: 16),

                // Hashrate row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SpeedDot(),
                    const SizedBox(width: 8),
                    Text(
                      '${btcPerMin.toStringAsFixed(8)} BTC/min',
                      style: _D.fontDisplay.copyWith(
                        fontSize: 13,
                        color: _D.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedDot extends StatefulWidget {
  @override
  State<_SpeedDot> createState() => _SpeedDotState();
}

class _SpeedDotState extends State<_SpeedDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 1))
    ..repeat(reverse: true);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _D.green,
        boxShadow: [
          BoxShadow(
            color: _D.green.withValues(alpha: 0.4 + 0.4 * _c.value),
            blurRadius: 6 + 6 * _c.value,
          ),
        ],
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
  );
}

// ─── Stats row ───────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final GameStateService game;
  const _StatsRow({required this.game});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _StatTile(
          icon: Icons.memory_rounded,
          label: 'Active rigs',
          value: '${game.ownedRigIds.length}',
          accent: _D.electric,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatTile(
          icon: Icons.factory_rounded,
          label: 'Farm tier',
          value: game.currentFarmTier.name,
          accent: _D.gold,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatTile(
          icon: Icons.savings_rounded,
          label: 'Lifetime',
          value: '${game.lifetimeMinedBtc.toStringAsFixed(4)} ₿',
          accent: _D.green,
        ),
      ),
    ],
  );
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const _StatTile({required this.icon, required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    decoration: BoxDecoration(
      color: _D.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _D.cardBord, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                fontFamily: AppTheme.fontFamily)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _D.textMid, fontSize: 11)),
      ],
    ),
  );
}

// ─── Mining session card ──────────────────────────────────────────────────────
class _MiningSessionCard extends StatelessWidget {
  final GameStateService game;
  const _MiningSessionCard({required this.game});

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _D.electric.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.timer_outlined, color: _D.electric, size: 18),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mining Session',
                  style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                game.isSessionActive
                    ? 'Active · ${game.sessionTimeLeft.inMinutes}m left · +1.25× bonus'
                    : 'Inactive · Start for hash bonus',
                style: const TextStyle(color: _D.textMid, fontSize: 11),
              ),
            ]),
            const Spacer(),
            if (game.isSessionActive)
              _Pill(label: 'LIVE', color: _D.green),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _PrimaryBtn(
            label: game.isSessionActive ? 'Session running…' : 'Start 30-min session',
            icon: Icons.play_arrow_rounded,
            disabled: game.isSessionActive,
            onTap: () async {
              await game.startMiningSession();
              if (context.mounted) {
                context.read<GoalsService>().addWeeklySession();
                context.read<SeasonService>().addXp(SeasonService.xpPerSession);
                context.read<AnalyticsService>().logSessionStart();
                context.read<NotificationService>().showMiningSessionStarted();
                _toast(context, '⚡ Mining session started (30 min)');
              }
            },
          ),
        ),
      ],
    ),
  );
}

// ─── Daily & weekly goals card ────────────────────────────────────────────────
class _GoalsCard extends StatelessWidget {
  final GoalsService goals;
  final GameStateService game;
  const _GoalsCard({required this.goals, required this.game});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderColor: _D.electric.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _D.electric.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded, color: _D.electric, size: 22),
              ),
              const SizedBox(width: 14),
              const Text(
                'Daily & weekly goals',
                style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Daily: mine ${GoalsService.dailyTargetBtc.toStringAsFixed(4)} BTC · ${(goals.dailyProgressPercent * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: _D.textMid, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Weekly: ${goals.weeklyProgressSessions}/${GoalsService.weeklyTargetSessions} sessions',
            style: const TextStyle(color: _D.textMid, fontSize: 12),
          ),
          if (goals.canClaimDaily || goals.canClaimWeekly) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (goals.canClaimDaily)
                  _SmallRewardChip(
                    label: 'Claim daily +${GoalsService.dailyRewardBtc.toStringAsFixed(5)} BTC',
                    onTap: () async {
                      await game.grantDirectBtc(GoalsService.dailyRewardBtc);
                      await goals.claimDaily();
                      if (context.mounted) _toast(context, '🎯 Daily goal reward!');
                    },
                  ),
                if (goals.canClaimWeekly)
                  _SmallRewardChip(
                    label: 'Claim weekly +${GoalsService.weeklyRewardBtc.toStringAsFixed(5)} BTC',
                    onTap: () async {
                      await game.grantDirectBtc(GoalsService.weeklyRewardBtc);
                      await goals.claimWeekly();
                      if (context.mounted) _toast(context, '🎯 Weekly goal reward!');
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Come-back bonus card ─────────────────────────────────────────────────────
class _ComebackCard extends StatelessWidget {
  final ComebackBonusService comeback;
  final GameStateService game;
  const _ComebackCard({required this.comeback, required this.game});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderColor: _D.gold.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waving_hand_rounded, color: _D.gold, size: 24),
              const SizedBox(width: 12),
              const Text(
                'We missed you!',
                style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Claim your welcome-back bonus: +${ComebackBonusService.bonusBtc.toStringAsFixed(5)} BTC',
            style: const TextStyle(color: _D.textMid, fontSize: 12),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _PrimaryBtn(
              label: 'Claim bonus',
              icon: Icons.card_giftcard_rounded,
              onTap: () async {
                await game.grantDirectBtc(ComebackBonusService.bonusBtc);
                await comeback.markClaimed();
                if (context.mounted) _toast(context, '🎁 Welcome back!');
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Referral promo card (invite friends) ──────────────────────────────────────
class _ReferralPromoCard extends StatelessWidget {
  final ReferralService referral;
  const _ReferralPromoCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    final friends = referral.friends;
    final code = referral.myCode ?? '------';
    return _GlassCard(
      borderColor: _D.purple.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _D.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_rounded, color: _D.purple, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invite friends',
                    style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    '$friends invited · Code: $code',
                    style: const TextStyle(color: _D.textMid, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Get BTC & rigs when friends join. Share your code from Profile.',
            style: TextStyle(color: _D.textLow, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Season / battle pass card ─────────────────────────────────────────────────
class _SeasonCard extends StatelessWidget {
  final SeasonService season;
  final GameStateService game;
  const _SeasonCard({required this.season, required this.game});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderColor: _D.gold.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: _D.gold, size: 22),
              const SizedBox(width: 10),
              Text(
                'Season ${season.seasonId}',
                style: const TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${season.xp} XP · Complete sessions & dailies for rewards',
            style: const TextStyle(color: _D.textMid, fontSize: 12),
          ),
          if (SeasonService.freeMilestones.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(SeasonService.freeMilestones.length, (i) {
                final canClaim = season.canClaimFree(i);
                if (!canClaim && season.xp < SeasonService.freeMilestones[i]) return const SizedBox.shrink();
                return _SmallRewardChip(
                  label: '${SeasonService.freeMilestones[i]} XP: +${SeasonService.freeRewardsBtc[i].toStringAsFixed(5)} BTC',
                  onTap: canClaim
                      ? () async {
                          await game.grantDirectBtc(SeasonService.freeRewardsBtc[i]);
                          await season.claimFreeReward(i);
                          if (context.mounted) _toast(context, '🏆 Season reward!');
                        }
                      : () {},
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Login streak card (daily comeback) ───────────────────────────────────────
class _LoginStreakCard extends StatelessWidget {
  final LoginStreakService loginStreak;
  final GameStateService game;
  const _LoginStreakCard({required this.loginStreak, required this.game});

  @override
  Widget build(BuildContext context) {
    final days = loginStreak.streakDays;
    return _GlassCard(
      borderColor: days >= 3 ? _D.green.withValues(alpha: 0.35) : _D.cardBord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _D.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: _D.green, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Login streak',
                    style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    days == 0 ? 'Open the app tomorrow to start!' : '$days day${days == 1 ? '' : 's'} in a row',
                    style: const TextStyle(color: _D.textMid, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (days >= 3) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (loginStreak.canClaimStreak3)
                  _SmallRewardChip(
                    label: '3 days: +0.00001 BTC',
                    onTap: () async {
                      await game.grantDirectBtc(0.00001);
                      await loginStreak.markStreak3Claimed();
                      if (context.mounted) _toast(context, '🔥 3-day streak reward!');
                    },
                  ),
                if (loginStreak.canClaimStreak7)
                  _SmallRewardChip(
                    label: '7 days: +0.00003 BTC',
                    onTap: () async {
                      await game.grantDirectBtc(0.00003);
                      await loginStreak.markStreak7Claimed();
                      if (context.mounted) _toast(context, '🔥 7-day streak reward!');
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallRewardChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SmallRewardChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _D.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _D.green.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: const TextStyle(color: _D.green, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Weekly challenge card ────────────────────────────────────────────────────
class _WeeklyChallengeCard extends StatelessWidget {
  final WeeklyChallengeService weeklyChallenge;
  final GameStateService game;
  const _WeeklyChallengeCard({required this.weeklyChallenge, required this.game});

  @override
  Widget build(BuildContext context) {
    final progress = weeklyChallenge.progressThisWeek(game.totalSessionsStarted);
    final complete = weeklyChallenge.isComplete(game.totalSessionsStarted);
    final canClaim = weeklyChallenge.canClaim(game.totalSessionsStarted);
    return _GlassCard(
      borderColor: complete ? _D.electric.withValues(alpha: 0.35) : _D.cardBord,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _D.electric.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: _D.electric, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly challenge',
                  style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '$progress/${WeeklyChallengeService.targetSessions} sessions this week · +${WeeklyChallengeService.rewardBtc.toStringAsFixed(5)} BTC',
                  style: const TextStyle(color: _D.textMid, fontSize: 12),
                ),
              ],
            ),
          ),
          if (canClaim)
            _PrimaryBtn(
              label: 'Claim',
              compact: true,
              onTap: () async {
                await game.grantDirectBtc(WeeklyChallengeService.rewardBtc);
                await weeklyChallenge.markClaimed();
                if (context.mounted) _toast(context, '🏆 Weekly challenge reward!');
              },
            )
          else if (complete)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.check_circle_rounded, color: _D.green, size: 22),
            ),
        ],
      ),
    );
  }
}

// ─── Daily boost card ─────────────────────────────────────────────────────────
class _DailyBoostCard extends StatelessWidget {
  final DailyBoostService dailyBoost;
  const _DailyBoostCard({required this.dailyBoost});

  @override
  Widget build(BuildContext context) {
    final until = dailyBoost.activeUntil;
    return _GlassCard(
      borderColor: dailyBoost.canClaim
          ? _D.gold.withValues(alpha: 0.35)
          : _D.cardBord,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _D.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: _D.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Daily Boost',
                  style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                dailyBoost.canClaim
                    ? '2× speed · 30 minutes — Available now!'
                    : dailyBoost.isActive && until != null
                    ? 'Active until ${until.hour.toString().padLeft(2, '0')}:${until.minute.toString().padLeft(2, '0')}'
                    : 'Resets every 24 hours',
                style: const TextStyle(color: _D.textMid, fontSize: 12),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          _PrimaryBtn(
            label: 'Claim',
            compact: true,
            disabled: !dailyBoost.canClaim,
            onTap: () async {
              final ok = await dailyBoost.claim();
              if (ok && context.mounted) {
                _toast(context, '⚡ Daily boost activated: 2× for 30m');
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Energy & cooling card ────────────────────────────────────────────────────
class _EnergyCard extends StatelessWidget {
  final EnergyCoolingService energy;
  const _EnergyCard({required this.energy});

  @override
  Widget build(BuildContext context) {
    final heat = energy.heat.clamp(0.0, 100.0) / 100.0;
    final heatColor = Color.lerp(_D.green, _D.red, heat)!;
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: heatColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.thermostat_rounded, color: heatColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Energy & Cooling',
                style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              'Efficiency ×${energy.efficiencyMultiplier.toStringAsFixed(2)}',
              style: const TextStyle(color: _D.textMid, fontSize: 12),
            ),
          ]),
          const Spacer(),
          Text(
            '${energy.heat.toStringAsFixed(1)}°',
            style: TextStyle(
                color: heatColor,
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
        ]),
        const SizedBox(height: 14),
        // Heat bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: heat,
            minHeight: 6,
            backgroundColor: _D.cardBord,
            valueColor: AlwaysStoppedAnimation(heatColor),
          ),
        ),
      ]),
    );
  }
}

// ─── Map progression card ─────────────────────────────────────────────────────
class _MapProgressionCard extends StatelessWidget {
  final ProgressionService progression;
  const _MapProgressionCard({required this.progression});

  @override
  Widget build(BuildContext context) => _GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.map_outlined, color: _D.electric, size: 18),
        SizedBox(width: 10),
        Text('Mining Locations',
            style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: MiningLocations.all.map((loc) {
          final unlocked = progression.unlockedLocations.contains(loc.id);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: unlocked
                  ? _D.electric.withValues(alpha: 0.12)
                  : _D.cardBord.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: unlocked
                    ? _D.electric.withValues(alpha: 0.35)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (unlocked)
                const Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Icon(Icons.check_circle_rounded,
                      color: _D.electric, size: 12),
                ),
              Text(
                loc.name,
                style: TextStyle(
                  color: unlocked ? _D.electric : _D.textLow,
                  fontSize: 12,
                  fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    ]),
  );
}

// ─── Random drop card ─────────────────────────────────────────────────────────
class _DropCard extends StatelessWidget {
  final RandomDropService drop;
  final GameStateService game;
  const _DropCard({required this.drop, required this.game});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [
          _D.gold.withValues(alpha: 0.18),
          _D.gold.withValues(alpha: 0.06),
        ],
      ),
      border: Border.all(color: _D.gold.withValues(alpha: 0.4), width: 1),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.auto_awesome_rounded, color: _D.gold, size: 28),
      title: const Text('Hidden crypto block!',
          style: TextStyle(
              color: _D.goldSoft, fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: const Text('Tap to collect bonus BTC',
          style: TextStyle(color: _D.textMid, fontSize: 12)),
      trailing: _PrimaryBtn(
        label: 'Collect',
        compact: true,
        onTap: () async {
          final bonus = await drop.collect();
          if (bonus != null) await game.grantDirectBtc(bonus);
          if (context.mounted) {
            _toast(context, '+${(bonus ?? 0).toStringAsFixed(6)} BTC collected!');
          }
        },
      ),
    ),
  );
}

// ─── Chart wrapper ────────────────────────────────────────────────────────────
class _ChartWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _GlassCard(
    padding: EdgeInsets.zero,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(children: [
          Icon(Icons.show_chart_rounded, color: _D.gold, size: 18),
          SizedBox(width: 10),
          Text('BTC Price',
              style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      const BtcPriceChart(),
      const SizedBox(height: 4),
    ]),
  );
}

// ─── News card (community / BTC updates) ─────────────────────────────────────
class _NewsCard extends StatelessWidget {
  const _NewsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderColor: _D.gold.withValues(alpha: 0.25),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/news'),
        borderRadius: BorderRadius.circular(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _D.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.article_rounded, color: _D.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latest BTC News',
                  style: TextStyle(
                    color: _D.textHi,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Read about Bitcoin and crypto updates',
                  style: TextStyle(
                    color: _D.textMid,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: _D.textLow, size: 14),
        ]),
      ),
    );
  }
}

// ─── Website redirect card ────────────────────────────────────────────────────
class _WebsiteCard extends StatelessWidget {
  final AdRemoteConfigService adCfg;
  const _WebsiteCard({required this.adCfg});

  @override
  Widget build(BuildContext context) {
    final url = adCfg.customTabUrl;
    final display = url.length > 48 ? '${url.substring(0, 48)}…' : url;
    return _GlassCard(
      borderColor: _D.electric.withValues(alpha: 0.25),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _D.electric.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.open_in_browser_rounded, color: _D.electric, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Open website',
              style: TextStyle(color: _D.textHi, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(display,
              style: const TextStyle(color: _D.textMid, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 10),
        _PrimaryBtn(
          label: 'Open',
          compact: true,
          onTap: () => adCfg.openCustomTab(url),
        ),
      ]),
    );
  }
}

// ─── Shared components ────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsets? padding;
  const _GlassCard({required this.child, this.borderColor, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _D.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? _D.cardBord, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: padding ?? const EdgeInsets.all(16),
    child: child,
  );
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool disabled;
  final bool compact;

  const _PrimaryBtn({
    required this.label,
    this.icon,
    this.onTap,
    this.disabled = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effective = disabled ? null : onTap;
    return GestureDetector(
      onTap: effective,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : const LinearGradient(
            colors: [Color(0xFFF5A623), Color(0xFFE08800)],
          ),
          color: disabled ? _D.cardBord : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: disabled
              ? null
              : [
            BoxShadow(
              color: _D.gold.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: disabled ? _D.textMid : Colors.black),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: disabled ? _D.textMid : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: _D.textHi)),
      backgroundColor: _D.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _D.cardBord)),
    ),
  );
}

// ─── Theme ───────────────────────────────────────────────────────────────────
ThemeData _darkTheme() => ThemeData(
  brightness: Brightness.dark,
  fontFamily: AppTheme.fontFamily,
  textTheme: AppTheme.darkTextTheme,
  scaffoldBackgroundColor: _D.bg,
  colorScheme: const ColorScheme.dark(
    primary: _D.gold,
    surface: _D.surface,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: GoogleFonts.spaceGrotesk(
      color: _D.textHi,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  ),
  cardTheme: const CardThemeData(color: _D.card, elevation: 0),
);