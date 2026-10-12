import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
import '../services/progression_service.dart';
import '../services/random_drop_service.dart';
import '../services/rate_app_service.dart';
import '../services/referral_service.dart';
import '../services/smart_ad_manager.dart';
import '../services/weekly_challenge_service.dart';
import '../services/withdrawal_service.dart';
import '../widgets/launch_offer_dialog.dart';
import '../widgets/rate_app_dialog.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'mining_farm_screen.dart';
import 'shop_screen.dart';
import 'leaderboard_screen.dart';
import 'rewards_screen.dart';

// ─── Design tokens (whitish theme) ───────────────────────────────────────────
class _D {
  static const bg       = Color(0xFFF7F8FA);
  static const surface  = Color(0xFFFFFFFF);
  static const card     = Color(0xFFFFFFFF);
  static const cardBord = Color(0xFFE2E8F0);
  static const gold     = Color(0xFFF59E0B);
  static const electric = Color(0xFF0EA5E9);
  static const green    = Color(0xFF22C55E);
  static const textHi   = Color(0xFF0D0F12);
  static const textMid  = Color(0xFF6B7280);
  static const textLow  = Color(0xFF9CA3AF);
}

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
    accent: _D.gold,
  ),
  _NavItem(
    icon: Icons.warehouse_outlined,
    activeIcon: Icons.warehouse_rounded,
    label: 'Farm',
    accent: _D.electric,
  ),
  _NavItem(
    icon: Icons.shopping_bag_outlined,
    activeIcon: Icons.shopping_bag_rounded,
    label: 'Shop',
    accent: _D.green,
  ),
  _NavItem(
    icon: Icons.leaderboard_outlined,
    activeIcon: Icons.leaderboard_rounded,
    label: 'Ranks',
    accent: Color(0xFFFF6B9D),
  ),
  _NavItem(
    icon: Icons.redeem_outlined,
    activeIcon: Icons.redeem_rounded,
    label: 'Rewards',
    accent: Color(0xFFB06EFF),
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
  Timer? _syncTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Transparent system nav bar so our custom bar bleeds edge-to-edge
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    final game = context.read<GameStateService>();
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    game.setUserId(user?.uid);
    game.setDisplayName(user?.displayName ?? (user?.email ?? 'Miner'));
    game.load().then((_) async {
      if (!mounted) return;
      await context.read<GameStateService>().applyIdleEarningsOnResume();
      // Leaderboard is updated via GameStateService.syncToCloud() (RTDB only) to reduce Firebase usage.
    });
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
    context.read<EventService>().load().then((_) => context.read<EventService>().refreshFromFirebaseIfNeeded());
    context.read<RandomDropService>().load();
    context.read<EnergyCoolingService>().load();
    context.read<LeaderboardService>().loadCache();
    context.read<WithdrawalService>().load();
    context.read<NotificationService>().init();
    context.read<LoginStreakService>().load().then((_) async {
      if (!mounted) return;
      await context.read<LoginStreakService>().recordLogin();
    });
    context.read<AdPacingService>().load();
    context.read<AdRemoteConfigService>().load().then((_) async {
      if (!mounted) return;
      await context.read<AnalyticsService>().initFromRemoteConfig();
      if (!mounted) return;
      context.read<AnalyticsService>().logScreenView('home');
      final uid = context.read<AuthService>().currentUser?.uid;
      if (uid != null) context.read<AnalyticsService>().setUserId(uid);
      context.read<SmartAdManager>().preloadRewarded();
      context.read<SmartAdManager>().preloadInterstitial();
      context.read<SmartAdManager>().preloadAppOpen();
    });
    if (user != null) {
      final displayName = user.displayName ?? user.email ?? 'Miner';
      context.read<ReferralService>().load(user.uid, displayName: displayName).then((_) async {
        if (!mounted) return;
        final referral = context.read<ReferralService>();
        final game = context.read<GameStateService>();
        final pending = await referral.consumePendingJoinBonuses();
        if (!mounted) return;
        if (pending > 0) {
          await game.grantDirectBtc(pending * ReferralService.inviterBonusBtc);
          if (!mounted) return;
          final btc = (pending * ReferralService.inviterBonusBtc).toStringAsFixed(8);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              pending == 1
                  ? 'A friend joined with your code — +$btc BTC'
                  : '$pending friends joined with your code — +$btc BTC',
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
            await referral.load(user.uid, displayName: displayName);
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
      final game        = context.read<GameStateService>();
      final progression = context.read<ProgressionService>();
      final daily       = context.read<DailyBoostService>();
      final events      = context.read<EventService>();
      final energy      = context.read<EnergyCoolingService>();
      final achievements= context.read<AchievementService>();
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
      final eventMult = adCfg.eventMiningMultiplier != 1.0 ? adCfg.eventMiningMultiplier : events.miningMultiplier;
      final eventDiscount = adCfg.eventRigDiscount > 0 ? adCfg.eventRigDiscount : events.rigDiscount;
      game.applyExternalGameplayModifiers(
        eventMiningMultiplier:   eventMult,
        dailyBoostMultiplier:    daily.miningMultiplier,
        efficiencyMultiplier:    energy.efficiencyMultiplier,
        locationCapacityBonus:   progression.locationCapacityBonus,
        rigDiscount:             eventDiscount,
        prestigeMultiplier:      prestige.permanentMultiplier,
      );
      final goals = context.read<GoalsService>();
      final prevBalance = _lastBalanceForGoals ?? game.btcBalance;
      _lastBalanceForGoals = game.btcBalance;
      if (game.btcBalance > prevBalance) goals.addDailyMined(game.btcBalance - prevBalance);
      energy.tickHeat(rigs: game.ownedRigIds.length, miningActive: true);
      progression.evaluateUnlocks(balanceBtc: game.btcBalance, hashRate: game.totalBtcPerMin);
      _evaluateAchievements(game, progression, achievements);
      game.updateTick();
    });

    // Sync to cloud less often to reduce Firebase usage and cost (RTDB only; leaderboard updated inside syncToCloud).
    _syncTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (!mounted) return;
      context.read<GameStateService>().syncToCloud();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final game = context.read<GameStateService>();
      game.load().then((_) {
        if (!mounted) return;
        context.read<GameStateService>().applyIdleEarningsOnResume();
      });
      context.read<AdRemoteConfigService>().load();
      final cfg   = context.read<AdRemoteConfigService>();
      final pacing= context.read<AdPacingService>();
      final ads   = context.read<SmartAdManager>();
      pacing.canShowAppOpen(completedSessions: game.totalSessionsStarted).then((canShow) async {
        if (!canShow || !mounted || !cfg.adsEnabled || !cfg.adsActive) return;
        if (cfg.useCustomTab && cfg.customTabUrl.isNotEmpty) return;
        try {
          final shown = await ads.showAppOpen();
          if (shown && mounted) await pacing.markAppOpenShown();
        } catch (_) {}
      });
    }
    // Save lastClosedAt as soon as app loses focus so background mining continues
    // after close/crash. Fire-and-forget so errors don't crash the app.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final game = context.read<GameStateService>();
      game.saveAndClose().catchError((_) {});
      if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _D.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _D.gold.withValues(alpha: 0.4), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _D.gold.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _D.gold.withValues(alpha: 0.15),
                      border: Border.all(color: _D.gold.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: _D.gold, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daily Boost Ready',
                    style: TextStyle(
                      color: _D.textHi,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Claim your 2× mining speed boost for 30 minutes from the Dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _D.textMid, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: _OutlineBtn(
                        label: 'Later',
                        onTap: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 12),
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
      ),
    );
  }

  void _maybeShowLaunchOffer() {
    Future.delayed(const Duration(milliseconds: 2200), () async {
      if (!mounted || _launchOfferShownThisSession) return;
      // Wait if another dialog (daily boost) is already up.
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
    final game = context.watch<GameStateService>();

    const pages = [
      DashboardScreen(),
      MiningFarmScreen(),
      ShopScreen(),
      LeaderboardScreen(),
      RewardsScreen(),
    ];

    if (!game.isLoaded) {
      return const _LoadingScreen();
    }

    return Scaffold(
      backgroundColor: _D.bg,
      extendBody: true, // content flows under the nav bar
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _index,
        onTap: _onTabTapped,
      ),
    );
  }

  void _evaluateAchievements(
      GameStateService game,
      ProgressionService progression,
      AchievementService achievements,
      ) {
    if (!achievements.isClaimed('first_miner') && game.ownedRigIds.isNotEmpty) {
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
    if (!achievements.isClaimed('sessions_10') && game.totalSessionsStarted >= 10) {
      achievements.markClaimed('sessions_10');
      game.grantDirectBtc(0.00004);
    }
    if (!achievements.isClaimed('hours_100') && game.totalSessionsStarted >= 100) {
      achievements.markClaimed('hours_100');
      game.grantDirectBtc(0.00012);
    }
    if (!achievements.isClaimed('lifetime_001') && game.lifetimeMinedBtc >= 0.001) {
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

    final cfg   = context.read<AdRemoteConfigService>();
    if (!cfg.adsEnabled && !(cfg.useCustomTab && cfg.customTabUrl.trim().isNotEmpty)) return;

    final game  = context.read<GameStateService>();
    final pacing= context.read<AdPacingService>();
    final ads   = context.read<SmartAdManager>();
    await pacing.registerNavigationTransition();
    final canShow = await pacing.shouldShowInterstitial(completedSessions: game.totalSessionsStarted);
    if (cfg.adsEnabled && canShow && mounted) {
      try {
        final shown = await ads.showInterstitial();
        if (shown && mounted) await pacing.markInterstitialShown();
      } catch (_) {}
    }
    if (cfg.useCustomTab && cfg.customTabUrl.trim().isNotEmpty && mounted) {
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
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat(reverse: true);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _D.bg,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing icon
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _D.gold,
                  _D.gold.withValues(alpha: 0.5 + 0.5 * _c.value),
                ]),
                boxShadow: [
                  BoxShadow(
                    color: _D.gold.withValues(alpha: 0.3 + 0.3 * _c.value),
                    blurRadius: 24 + 16 * _c.value,
                  ),
                ],
              ),
              child: const Icon(Icons.currency_bitcoin, color: Colors.black, size: 40),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Crypto Mining Tycoon',
            style: TextStyle(
              color: _D.gold,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Loading your mining farm…',
            style: TextStyle(color: _D.textMid, fontSize: 13),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                backgroundColor: _D.cardBord,
                valueColor: AlwaysStoppedAnimation(_D.gold),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.fromLTRB(AppTheme.pagePaddingH, 0, AppTheme.pagePaddingH, bottomInset + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius + 8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: AppTheme.bottomNavHeight,
            decoration: BoxDecoration(
              color: _D.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _D.cardBord, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
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
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.selected, required this.onTap});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<double> _scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);

  @override
  void didUpdateWidget(_NavTile old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _c.forward(from: 0);
    if (!widget.selected && old.selected) _c.reverse();
  }

  @override
  void initState() {
    super.initState();
    if (widget.selected) _c.value = 1;
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    behavior: HitTestBehavior.opaque,
    child: AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active indicator pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: widget.selected ? 36 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: widget.item.accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: widget.selected
                  ? [BoxShadow(
                color: widget.item.accent.withValues(alpha: 0.6),
                blurRadius: 8,
              )]
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
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: widget.selected ? widget.item.accent : _D.textLow,
              fontSize: 10,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.normal,
              letterSpacing: widget.selected ? 0.5 : 0,
            ),
            child: Text(widget.item.label),
          ),
        ],
      ),
    ),
  );
}

// ─── Dialog buttons ───────────────────────────────────────────────────────────
class _GoldBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GoldBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A623), Color(0xFFE08800)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _D.gold.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: _D.cardBord,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Later',
        style: TextStyle(
          color: _D.textMid,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ),
  );
}