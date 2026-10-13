import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/mining_economy.dart';
import '../models/shop_product.dart';
import '../services/ad_pacing_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/analytics_service.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/comeback_bonus_service.dart';
import '../services/daily_boost_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/event_service.dart';
import '../services/game_state_service.dart';
import '../services/goals_service.dart';
import '../services/prestige_service.dart';
import '../services/season_service.dart';
import '../services/iap_service.dart';
import '../services/leaderboard_service.dart';
import '../services/mini_game_service.dart';
import '../services/login_streak_service.dart';
import '../services/lucky_spin_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../services/progression_service.dart';
import '../services/random_drop_service.dart';
import '../services/rate_app_service.dart';
import '../services/referral_service.dart';
import '../services/smart_ad_manager.dart';
import '../services/weekly_challenge_service.dart';
import '../services/withdrawal_service.dart';
import '../utils/smart_ads.dart';
import '../widgets/launch_offer_dialog.dart';
import '../widgets/rate_app_dialog.dart';
import '../widgets/remote_config_banner.dart';
import '../theme/app_theme.dart';
import '../theme/solana.dart';
import '../widgets/solana_widgets.dart';
import 'dashboard_screen.dart';
import 'mining_farm_screen.dart';
import 'shop_screen.dart';
import 'leaderboard_screen.dart';
import 'rewards_screen.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _D {
  static const bg       = Color(0xFF08080A);
  static const surface  = Color(0xFF18181C);
  static const card     = Color(0xFF18181C);
  static const cardBord = Color(0x1FFFFFFF);
  static const gold     = Color(0xFF9945FF); // Solana purple
  static const electric = Color(0xFF14F195);
  static const green    = Color(0xFF14F195); // Solana green
  static const textHi   = Color(0xFFF4F4F5);
  static const textMid  = Color(0xFFA1A1AA);
  static const textLow  = Color(0xFF71717A);

  // Glass
  static const glassBorder = Color(0x2DFFFFFF);
  static const glassFillTop = Color(0xE61F1F26);
  static const glassFillBot = Color(0xE6121216);

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
  Color color = _D.textHi,
  double? letterSpacing,
}) => GoogleFonts.spaceGrotesk(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: letterSpacing ?? -0.2,
);

TextStyle _mono({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _D.textHi,
}) => GoogleFonts.spaceMono(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: -0.3,
);

// ─── Nav item model ───────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color accent;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.accent,
  });
}

const _navItems = [
  _NavItem(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    label: 'Dashboard',
    accent: Color(0xFF9945FF),
  ),
  _NavItem(
    icon: Icons.warehouse_outlined,
    activeIcon: Icons.warehouse_rounded,
    label: 'Farm',
    accent: Color(0xFF14F195),
  ),
  _NavItem(
    icon: Icons.shopping_bag_outlined,
    activeIcon: Icons.shopping_bag_rounded,
    label: 'Shop',
    accent: Color(0xFF14F195),
  ),
  _NavItem(
    icon: Icons.leaderboard_outlined,
    activeIcon: Icons.leaderboard_rounded,
    label: 'Ranks',
    accent: Color(0xFF9945FF),
  ),
  _NavItem(
    icon: Icons.redeem_outlined,
    activeIcon: Icons.redeem_rounded,
    label: 'Rewards',
    accent: Color(0xFF14F195),
  ),
];

// ─── Shell ────────────────────────────────────────────────────────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  int _snapshotTicks = 0;
  int _localSaveTicks = 0;
  double? _lastBalanceForGoals;
  bool _dailyBoostDialogShownThisSession = false;
  bool _launchOfferShownThisSession = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    final game = context.read<GameStateService>();
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    game.setUserId(user?.uid);
    game.setDisplayName(auth.displayNameOf(user));
    if (game.isLoaded) {
      unawaited(game.applyIdleEarningsOnResume());
    } else {
      game.load().then((_) async {
        if (!mounted) return;
        await context.read<GameStateService>().applyIdleEarningsOnResume();
      });
    }
    unawaited(context.read<SmartAdManager>().preloadAll());
    context.read<GoalsService>().load();
    context.read<ComebackBonusService>().load().then((_) async {
      if (!mounted) return;
      await context.read<ComebackBonusService>().recordOpen();
    });
    context.read<PrestigeService>().load();
    context.read<MiniGameService>().load();
    context.read<SeasonService>().load();
    context.read<ProgressionService>().load();
    context.read<DailyBoostService>().load().then((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_dailyBoostDialogShownThisSession) return;
        final daily = context.read<DailyBoostService>();
        if (daily.canClaim && !daily.hasShownDialogForCurrentDay) {
          _dailyBoostDialogShownThisSession = true;
          daily.recordDialogShownForCurrentDay();
          _showDailyBoostDialog(daily);
        }
      });
    });
    context.read<LuckySpinService>().load();
    context.read<AchievementService>().load();
    context.read<EventService>().load();
    context.read<RandomDropService>().load();
    context.read<EnergyCoolingService>().load();
    context.read<LeaderboardService>().loadCache();
    SoundService.instance.init();
    context.read<WithdrawalService>().load();
    context.read<NotificationService>().init().then((_) {
      if (!mounted) return;
      context.read<NotificationService>().bindUser(user?.uid);
    });
    game.onMiningStarted = () {
      if (!mounted) return;
      context.read<NotificationService>().showMiningSessionStarted();
    };
    game.onMiningStopped = () {
      if (!mounted) return;
      context.read<NotificationService>().showMiningSessionEnded();
    };
    context.read<LoginStreakService>().load().then((_) async {
      if (!mounted) return;
      await context.read<LoginStreakService>().recordLogin();
    });
    context.read<AdPacingService>().load();
    final adCfg = context.read<AdRemoteConfigService>();
    final adReady = adCfg.isLoaded ? Future.value() : adCfg.load();
    adReady.then((_) async {
      if (!mounted) return;
      await context.read<AnalyticsService>().initFromRemoteConfig();
      if (!mounted) return;
      context.read<AnalyticsService>().logScreenView('home');
      final uid = context.read<AuthService>().currentUser?.uid;
      if (uid != null) context.read<AnalyticsService>().setUserId(uid);
      unawaited(context.read<SmartAdManager>().preloadAll());
    });
    if (user != null) {
      final displayName = context.read<AuthService>().displayNameOf(user);
      context.read<ReferralService>().load(
        user.uid,
        displayName: displayName,
        signedIn: user.isAnonymous != true,
      ).then((_) async {
        if (!mounted) return;
        final referral = context.read<ReferralService>();
        final game = context.read<GameStateService>();
        if (user.isAnonymous == true) return;
        final pending = await referral.consumePendingJoinBonuses();
        if (!mounted) return;
        if (pending > 0) {
          await game.grantDirectBtc(pending * ReferralService.inviterBonusBtc);
          if (!mounted) return;
          final sol = MiningEconomy.toSol(pending * ReferralService.inviterBonusBtc)
              .toStringAsFixed(6);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              pending == 1
                  ? 'A friend joined with your code — +$sol SOL'
                  : '$pending friends joined with your code — +$sol SOL',
            ),
          ));
        }
        final queued = await referral.takeQueuedJoinCode();
        if (queued != null && queued.isNotEmpty) {
          final result = await referral.applyReferral(
            user.uid,
            queued,
            displayName: displayName,
          );
          if (result.ok) {
            await game.grantDirectBtc(ReferralService.welcomeBonusBtc);
            await referral.load(
              user.uid,
              displayName: displayName,
              signedIn: user.isAnonymous != true,
            );
          }
        }
      });
    }

    _maybeShowRateDialogLater();
    _maybeShowLaunchOffer();

    final iap = context.read<IapService>();
    final analytics = context.read<AnalyticsService>();
    iap.onPurchaseSuccess = (delivery) {
      final p = ShopProducts.oneTimeById(delivery.productId);
      final plan = ShopProducts.planById(delivery.productId);
      final amountStr = p?.price ?? plan?.price ?? '';
      final amount = amountStr.startsWith('\$')
          ? (double.tryParse(amountStr.replaceFirst('\$', '').trim()) ?? 0)
          : 0.0;
      analytics.logPurchase(
        amount: amount,
        currency: 'USD',
        productId: delivery.productId,
        transactionId: delivery.purchaseId ?? '${DateTime.now().millisecondsSinceEpoch}',
      );
      game.fulfillGooglePlayPurchase(delivery).then((_) {
        if (!mounted) return;
        if (delivery.productId == 'season_pass') {
          context.read<SeasonService>().unlockPremium();
        }
      });
    };
    iap.init();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final game = context.read<GameStateService>();
      final progression = context.read<ProgressionService>();
      final daily = context.read<DailyBoostService>();
      final events = context.read<EventService>();
      final energy = context.read<EnergyCoolingService>();
      final achievements = context.read<AchievementService>();
      _snapshotTicks++;
      if (_snapshotTicks >= 15) {
        _snapshotTicks = 0;
        game.saveForegroundSnapshot().catchError((_) {});
      }
      _localSaveTicks++;
      if (_localSaveTicks >= 30) {
        _localSaveTicks = 0;
        game.persistLocalOnly().catchError((_) {});
      }
      final prestige = context.read<PrestigeService>();
      final adCfg = context.read<AdRemoteConfigService>();
      final eventMult = adCfg.eventMiningMultiplier != 1.0
          ? adCfg.eventMiningMultiplier
          : events.miningMultiplier;
      final eventDiscount =
      adCfg.eventRigDiscount > 0 ? adCfg.eventRigDiscount : events.rigDiscount;
      game.applyExternalGameplayModifiers(
        eventMiningMultiplier: eventMult,
        dailyBoostMultiplier: daily.miningMultiplier,
        efficiencyMultiplier: energy.efficiencyMultiplier,
        locationCapacityBonus: progression.locationCapacityBonus,
        rigDiscount: eventDiscount,
        prestigeMultiplier: prestige.permanentMultiplier,
      );
      final goals = context.read<GoalsService>();
      final prevBalance = _lastBalanceForGoals ?? game.btcBalance;
      _lastBalanceForGoals = game.btcBalance;
      if (game.btcBalance > prevBalance) {
        goals.addDailyMined(game.btcBalance - prevBalance);
      }
      energy.tickHeat(rigs: game.ownedRigIds.length, miningActive: true);
      progression.evaluateUnlocks(
          balanceBtc: game.btcBalance, hashRate: game.totalBtcPerMin);
      _evaluateAchievements(game, progression, achievements);
      game.updateTick();
    });

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    try {
      context.read<GameStateService>().onMiningStarted = null;
      context.read<GameStateService>().onMiningStopped = null;
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final game = context.read<GameStateService>();
      if (game.isLoaded) {
        unawaited(game.applyIdleEarningsOnResume());
      } else {
        game.load().then((_) {
          if (!mounted) return;
          context.read<GameStateService>().applyIdleEarningsOnResume();
        });
      }
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final game = context.read<GameStateService>();
      game.saveAndClose().catchError((_) {});
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        context.read<NotificationService>().scheduleEarningsReminder();
        if (game.canClaimDaily) {
          context.read<NotificationService>().scheduleDailyRewardReminder();
        }
      }
    }
  }

  // ── Daily boost dialog ─────────────────────────────────────────────────────
  void _showDailyBoostDialog(DailyBoostService daily) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.62),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        insetAnimationDuration: const Duration(milliseconds: 300),
        insetAnimationCurve: Curves.easeOutBack,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _DailyBoostCard(
            onLater: () => Navigator.pop(ctx),
            onClaim: () async {
              await daily.claim();
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }

  void _maybeShowLaunchOffer() {
    Future.delayed(const Duration(milliseconds: 2200), () async {
      if (!mounted || _launchOfferShownThisSession) return;
      for (var i = 0; i < 12; i++) {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route != null && route.isCurrent) break;
        await Future.delayed(const Duration(milliseconds: 400));
      }
      if (!mounted || _launchOfferShownThisSession) return;
      _launchOfferShownThisSession = true;
      await LaunchOfferDialog.show(context);
    });
  }

  void _maybeShowRateDialogLater() {
    Future.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;
      final game = context.read<GameStateService>();
      final rateService = context.read<RateAppService>();
      final shouldShow = await rateService.shouldShowRateDialog(
        totalSessionsStarted: game.totalSessionsStarted,
      );
      if (!mounted || !shouldShow) return;
      await RateAppDialog.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<GameStateService, bool>((g) => g.isLoaded);

    const pages = [
      DashboardScreen(),
      MiningFarmScreen(),
      ShopScreen(),
      LeaderboardScreen(),
      RewardsScreen(),
    ];

    if (!loaded) {
      return const _LoadingScreen();
    }

    final stack = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < pages.length; i++)
          TickerMode(
            enabled: i == _index,
            child: RepaintBoundary(child: pages[i]),
          ),
      ],
    );

    // Responsive: tablets / landscape / desktop get a side rail,
    // phones get the floating glass bar.
    final wide = MediaQuery.sizeOf(context).width >= 840;

    if (wide) {
      return Scaffold(
        backgroundColor: _D.bg,
        body: Row(
          children: [
            _SideRail(currentIndex: _index, onTap: _onTabTapped),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: stack),
                  const RemoteConfigBanner(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _D.bg,
      extendBody: false,
      body: stack,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RemoteConfigBanner(),
          _FloatingNavBar(
            currentIndex: _index,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }

  void _evaluateAchievements(
      GameStateService game,
      ProgressionService progression,
      AchievementService achievements,
      ) {
    if (!achievements.isClaimed('first_miner') &&
        game.ownedRigIds.isNotEmpty) {
      achievements.markClaimed('first_miner');
      game.grantDirectBtc(0.00002);
    }
    if (!achievements.isClaimed('rigs_5') && game.ownedRigIds.length >= 5) {
      achievements.markClaimed('rigs_5');
      game.grantDirectBtc(0.00003);
    }
    if (!achievements.isClaimed('rigs_10') && game.ownedRigIds.length >= 10) {
      achievements.markClaimed('rigs_10');
      game.grantDirectBtc(0.00008);
    }
    if (!achievements.isClaimed('sessions_10') &&
        game.totalSessionsStarted >= 10) {
      achievements.markClaimed('sessions_10');
      game.grantDirectBtc(0.00004);
    }
    if (!achievements.isClaimed('hours_100') &&
        game.totalSessionsStarted >= 100) {
      achievements.markClaimed('hours_100');
      game.grantDirectBtc(0.00012);
    }
    if (!achievements.isClaimed('lifetime_001') &&
        game.lifetimeMinedBtc >= MiningEconomy.toSol(0.001)) {
      achievements.markClaimed('lifetime_001');
      game.grantDirectBtc(0.0001);
    }
    if (!achievements.isClaimed('factory_unlock') &&
        progression.unlockedLocations.contains('factory')) {
      achievements.markClaimed('factory_unlock');
      game.grantDirectBtc(0.0001);
    }
  }

  Future<void> _onTabTapped(int i) async {
    HapticFeedback.lightImpact();
    setState(() => _index = i);
    if (!mounted) return;

    final cfg = context.read<AdRemoteConfigService>();
    if (!context.read<SmartAdManager>().interstitialReady) {
      unawaited(context.read<SmartAdManager>().preloadInterstitial());
    } else {
      await SmartAds.maybeInterstitial(context);
    }
    if (cfg.canShowWebsiteRedirect && mounted) {
      try {
        await cfg.openCustomTab(cfg.customTabUrl.trim());
      } catch (_) {}
    }
  }
}

// ─── Loading screen ───────────────────────────────────────────────────────────
class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final markSize = (w * 0.22).clamp(76.0, 120.0);

    return Scaffold(
      backgroundColor: _D.bg,
      body: Stack(
        children: [
          const SolanaMeshBackground(intensity: 0.22),
          // Soft vignette for depth
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      _D.bg.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _c,
                        builder: (_, __) => SizedBox(
                          width: markSize * 2.1,
                          height: markSize * 2.1,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Breathing glow rings
                              for (var i = 0; i < 3; i++)
                                Container(
                                  width: markSize * (1.25 + i * 0.32) +
                                      _c.value * 10,
                                  height: markSize * (1.25 + i * 0.32) +
                                      _c.value * 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (i.isEven
                                          ? _D.gold
                                          : _D.green)
                                          .withOpacity(
                                          (0.20 - i * 0.05) *
                                              (0.6 + _c.value * 0.4)),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              Container(
                                width: markSize * 1.5,
                                height: markSize * 1.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _D.gold
                                          .withOpacity(0.18 + _c.value * 0.14),
                                      blurRadius: 60,
                                      spreadRadius: 4,
                                    ),
                                    BoxShadow(
                                      color: _D.green
                                          .withOpacity(0.08 + _c.value * 0.08),
                                      blurRadius: 80,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                              ),
                              SolanaMark(size: markSize, pulse: _c.value),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (r) => _D.brand.createShader(r),
                        child: Text(
                          'Solana Mining Tycoon',
                          textAlign: TextAlign.center,
                          style: _label(
                            size: 26,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Loading your validators…',
                        textAlign: TextAlign.center,
                        style: _label(size: 14, color: _D.textMid),
                      ),
                      const SizedBox(height: 32),
                      const SolanaShimmerBar(width: 180),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: _D.glassBorder, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _D.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SYNCING NETWORK',
                              style: _mono(
                                size: 10,
                                color: _D.textMid,
                                weight: FontWeight.w700,
                              ).copyWith(letterSpacing: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating glass nav bar (phones) ──────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final compact = mq.size.width < 360;
    final barHeight = compact ? 64.0 : 70.0;
    final accent = _navItems[currentIndex].accent;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          compact ? 12 : 18, 0, compact ? 12 : 18, mq.padding.bottom + 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.16),
                  blurRadius: 32,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_D.glassFillTop, _D.glassFillBot],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _D.glassBorder, width: 0.8),
                  ),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final tileW = c.maxWidth / _navItems.length;
                      return Stack(
                        children: [
                          // Sliding highlight pill
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                            left: currentIndex * tileW + 5,
                            top: 7,
                            bottom: 7,
                            width: tileW - 10,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 380),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(21),
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withOpacity(0.22),
                                    accent.withOpacity(0.07),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                border: Border.all(
                                  color: accent.withOpacity(0.35),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.20),
                                    blurRadius: 18,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(_navItems.length, (i) {
                              return Expanded(
                                child: _NavTile(
                                  item: _navItems[i],
                                  selected: currentIndex == i,
                                  compact: compact,
                                  onTap: () => onTap(i),
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav tile ─────────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            offset: selected ? const Offset(0, -0.06) : Offset.zero,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              scale: selected ? 1.12 : 1.0,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (r) => (selected
                    ? LinearGradient(
                  colors: [item.accent, item.accent.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : const LinearGradient(
                    colors: [_D.textLow, _D.textLow]))
                    .createShader(r),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  color: Colors.white,
                  size: compact ? 21 : 23,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: _label(
              size: compact ? 9.5 : 10.5,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? item.accent : _D.textLow,
              letterSpacing: selected ? 0.3 : -0.1,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Side rail (tablet / desktop) ─────────────────────────────────────────────
class _SideRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SideRail({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xF21F1F26), Color(0xE60B0B0D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          right: BorderSide(color: Color(0x2DFFFFFF), width: 0.8),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            SolanaMark(size: 42, pulse: 0),
            const SizedBox(height: 26),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(_navItems.length, (i) {
                    return _RailTile(
                      item: _navItems[i],
                      selected: currentIndex == i,
                      onTap: () => onTap(i),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _RailTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 72,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? LinearGradient(
            colors: [
              item.accent.withOpacity(0.22),
              item.accent.withOpacity(0.06),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
              : null,
          border: Border.all(
            color: selected
                ? item.accent.withOpacity(0.35)
                : Colors.transparent,
            width: 0.8,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: item.accent.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: -2,
            ),
          ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              color: selected ? item.accent : _D.textLow,
              size: 24,
            ),
            const SizedBox(height: 5),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _label(
                size: 10.5,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? item.accent : _D.textLow,
                letterSpacing: selected ? 0.3 : -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily boost card ─────────────────────────────────────────────────────────
class _DailyBoostCard extends StatelessWidget {
  final VoidCallback onLater;
  final Future<void> Function() onClaim;

  const _DailyBoostCard({required this.onLater, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xF51F1F26), Color(0xF5121216)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _D.glassBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: _D.gold.withOpacity(0.28),
                blurRadius: 60,
                spreadRadius: -6,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Ambient colour orbs
              Positioned(
                top: -70,
                left: -50,
                child: _orb(_D.gold, 190, 0.28),
              ),
              Positioned(
                bottom: -80,
                right: -50,
                child: _orb(_D.green, 190, 0.16),
              ),
              // Top highlight hairline
              Positioned(
                top: 0,
                left: 40,
                right: 40,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.35),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _HaloIcon(),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _D.green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: _D.green.withOpacity(0.35), width: 0.8),
                        ),
                        child: Text(
                          'DAILY REWARD',
                          style: _mono(
                            size: 10,
                            color: _D.green,
                            weight: FontWeight.w700,
                          ).copyWith(letterSpacing: 1.6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (r) => _D.brand.createShader(r),
                        child: Text(
                          'Daily Boost Ready',
                          textAlign: TextAlign.center,
                          style: _label(
                            size: 26,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Claim your 2× mining speed boost for 30 minutes from the Dashboard.',
                        textAlign: TextAlign.center,
                        style: _label(
                          size: 14,
                          color: _D.textMid,
                          letterSpacing: -0.2,
                        ).copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _StatChip(
                              icon: Icons.bolt_rounded,
                              text: '2× speed',
                              color: _D.gold),
                          _StatChip(
                              icon: Icons.timer_rounded,
                              text: '30 min',
                              color: _D.green),
                          _StatChip(
                              icon: Icons.card_giftcard_rounded,
                              text: 'Free',
                              color: _D.gold),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Row(children: [
                        Expanded(
                          flex: 4,
                          child: _OutlineBtn(
                            label: 'Later',
                            onTap: onLater,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: _GoldBtn(
                            label: 'Claim now',
                            icon: Icons.bolt_rounded,
                            onTap: () => onClaim(),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _orb(Color color, double size, double opacity) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    ),
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _D.glassBorder, width: 0.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: _label(
            size: 12.5,
            weight: FontWeight.w700,
            color: _D.textHi,
          ),
        ),
      ],
    ),
  );
}

// ─── Animated halo icon ───────────────────────────────────────────────────────
class _HaloIcon extends StatefulWidget {
  const _HaloIcon();

  @override
  State<_HaloIcon> createState() => _HaloIconState();
}

class _HaloIconState extends State<_HaloIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (ctx, val, child) =>
          Transform.scale(scale: val.clamp(0.0, 1.2), child: child),
      child: SizedBox(
        width: 120,
        height: 120,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = _c.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // Expanding ripple
                Container(
                  width: 76 + 44 * t,
                  height: 76 + 44 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _D.gold.withOpacity(0.35 * (1 - t)),
                      width: 1.5,
                    ),
                  ),
                ),
                // Core
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _D.gold.withOpacity(0.30),
                        _D.green.withOpacity(0.14),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.22), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _D.gold.withOpacity(0.35),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (r) => _D.brand.createShader(r),
                    child: const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 42),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Dialog buttons ───────────────────────────────────────────────────────────
class _GoldBtn extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _GoldBtn({required this.label, required this.onTap, this.icon});

  @override
  State<_GoldBtn> createState() => _GoldBtnState();
}

class _GoldBtnState extends State<_GoldBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _isPressed = true),
    onTapUp: (_) => setState(() => _isPressed = false),
    onTapCancel: () => setState(() => _isPressed = false),
    onTap: () {
      HapticFeedback.mediumImpact();
      widget.onTap();
    },
    child: AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: _D.brand,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9945FF)
                  .withOpacity(_isPressed ? 0.25 : 0.45),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF14F195).withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(6, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glossy top sheen
            Positioned(
              top: -15,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.22),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _label(
                        size: 15,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OutlineBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlineBtn({required this.label, required this.onTap});

  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _isPressed = true),
    onTapUp: (_) => setState(() => _isPressed = false),
    onTapCancel: () => setState(() => _isPressed = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_isPressed ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _D.glassBorder, width: 0.8),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _label(
            size: 15,
            weight: FontWeight.w600,
            color: _D.textMid,
            letterSpacing: -0.2,
          ),
        ),
      ),
    ),
  );
}