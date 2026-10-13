import 'dart:async';

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
  static const gold     = Color(0xFF9945FF);
  static const electric = Color(0xFF14F195);
  static const green    = Color(0xFF14F195);
  static const textHi   = Color(0xFFF4F4F5);
  static const textMid  = Color(0xFFA1A1AA);
  static const textLow  = Color(0xFF71717A);

  // Glass
  static const glassBorder = Color(0x2DFFFFFF);
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
    game.setDisplayName(user?.displayName ?? (user?.email ?? 'Miner'));
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
      final displayName = user.displayName ?? user.email ?? 'Miner';
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
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetAnimationDuration: const Duration(milliseconds: 300),
        insetAnimationCurve: Curves.easeOutBack,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xF218181C),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _D.glassBorder, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: _D.gold.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (ctx, val, _) => Transform.scale(
                      scale: val,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _D.gold.withOpacity(0.15),
                          border: Border.all(
                              color: _D.gold.withOpacity(0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: _D.gold.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: _D.gold, size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Daily Boost Ready',
                    style: _label(
                      size: 20,
                      weight: FontWeight.w700,
                      color: _D.textHi,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Claim your 2× mining speed boost for 30 minutes from the Dashboard.',
                    textAlign: TextAlign.center,
                    style: _label(
                      size: 13,
                      color: _D.textMid,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(children: [
                    Expanded(
                      child: _OutlineBtn(
                        label: 'Later',
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _GoldBtn(
                        label: 'Claim now',
                        onTap: () async {
                          await daily.claim();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ]),
                ],
              ),
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

    return Scaffold(
      backgroundColor: _D.bg,
      extendBody: false,
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < pages.length; i++)
            TickerMode(
              enabled: i == _index,
              child: RepaintBoundary(child: pages[i]),
            ),
        ],
      ),
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
      vsync: this, duration: const Duration(seconds: 2))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _D.bg,
    body: Stack(
      children: [
        const SolanaMeshBackground(intensity: 0.22),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, __) => SolanaMark(size: 84, pulse: _c.value),
              ),
              const SizedBox(height: 28),
              Text(
                'Solana Mining Tycoon',
                style: _label(
                  size: 22,
                  weight: FontWeight.w800,
                  color: _D.textHi,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Loading your validators…',
                style: _label(size: 13, color: _D.textMid),
              ),
              const SizedBox(height: 28),
              const SolanaShimmerBar(width: 160),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── Floating nav bar ─────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 14),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xF218181C),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _D.glassBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_navItems.length, (i) {
            return Expanded(
              child: _NavTile(
                item: _navItems[i],
                selected: currentIndex == i,
                onTap: () => onTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Nav tile ─────────────────────────────────────────────────────────────────
class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutBack,
  );

  @override
  void didUpdateWidget(_NavTile old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _c.forward(from: 0);
    }
    if (!widget.selected && old.selected) {
      _c.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.selected) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: widget.selected ? 24 : 0,
            height: 3.5,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.item.accent,
                  widget.item.accent.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(99),
              boxShadow: widget.selected
                  ? [
                BoxShadow(
                  color: widget.item.accent.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
          ),
          Transform.scale(
            scale: widget.selected ? 0.9 + 0.1 * _scale.value : 1.0,
            child: Icon(
              widget.selected ? widget.item.activeIcon : widget.item.icon,
              color: widget.selected ? widget.item.accent : _D.textLow,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: _label(
              size: 10,
              weight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: widget.selected ? widget.item.accent : _D.textLow,
              letterSpacing: widget.selected ? 0.6 : -0.1,
            ),
            child: Text(
              widget.item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Dialog buttons ───────────────────────────────────────────────────────────
class _GoldBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _GoldBtn({required this.label, required this.onTap});

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
    onTap: widget.onTap,
    child: Transform.scale(
      scale: _isPressed ? 0.95 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9945FF), Color(0xFF14F195)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9945FF).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: _label(
            size: 14,
            weight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
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
    child: Transform.scale(
      scale: _isPressed ? 0.95 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _D.surface.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _D.glassBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: _label(
            size: 14,
            weight: FontWeight.w700,
            color: _D.textMid,
            letterSpacing: -0.2,
          ),
        ),
      ),
    ),
  );
}