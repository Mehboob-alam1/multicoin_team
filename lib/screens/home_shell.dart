import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/shop_product.dart';
import '../services/ad_pacing_service.dart';
import '../services/ad_remote_config_service.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/daily_boost_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/event_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../services/leaderboard_service.dart';
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
import '../widgets/rate_app_dialog.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'mining_farm_screen.dart';
import 'shop_screen.dart';
import 'leaderboard_screen.dart';
import 'rewards_screen.dart';

// ─── Design tokens (mirrors dashboard) ───────────────────────────────────────
class _D {
  static const bg       = Color(0xFF080B12);
  static const surface  = Color(0xFF0E1420);
  static const card     = Color(0xFF121826);
  static const cardBord = Color(0xFF1E2A3A);
  static const gold     = Color(0xFFF5A623);
  static const electric = Color(0xFF00D4FF);
  static const green    = Color(0xFF00E5A0);
  static const textHi   = Color(0xFFF0F4FF);
  static const textMid  = Color(0xFF8899BB);
  static const textLow  = Color(0xFF3D4F6B);
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
  Timer? _timer;
  Timer? _syncTimer;
  DateTime? _lastLeaderboardPushAt;
  double _lastLeaderboardMined = 0;
  double _lastLeaderboardHash  = 0;

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
    game.load();
    context.read<ProgressionService>().load();
    context.read<DailyBoostService>().load();
    context.read<LuckySpinService>().load();
    context.read<AchievementService>().load();
    context.read<EventService>().load().then((_) => context.read<EventService>().refreshFromFirebase());
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
    context.read<AdRemoteConfigService>().load().then((_) {
      if (!mounted) return;
      context.read<SmartAdManager>().preloadRewarded();
      context.read<SmartAdManager>().preloadInterstitial();
      context.read<SmartAdManager>().preloadAppOpen();
    });
    if (user != null) {
      context.read<ReferralService>().load(user.uid);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final daily = context.read<DailyBoostService>();
      if (daily.canClaim) {
        _showDailyBoostDialog(daily);
      }
    });

    _maybeShowRateDialogLater();

    final iap = context.read<IapService>();
    iap.onPurchaseSuccess = (productId, isSubscription, durationDays) {
      if (isSubscription) {
        game.activatePremium(productId, durationDays);
      } else {
        if (game.hasPurchasedOneTime(productId)) return;
        final p = ShopProducts.oneTimeById(productId);
        if (p != null) {
          if (productId == 'boost_2x_1h') game.activateBoost1h();
          game.applyOneTimePurchase(
              productId: productId, btcAmount: p.btcAmount, rigId: p.rigId);
        }
      }
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
      game.applyExternalGameplayModifiers(
        eventMiningMultiplier:   events.miningMultiplier,
        dailyBoostMultiplier:    daily.miningMultiplier,
        efficiencyMultiplier:    energy.efficiencyMultiplier,
        locationCapacityBonus:   progression.locationCapacityBonus,
        rigDiscount:             events.rigDiscount,
      );
      energy.tickHeat(rigs: game.ownedRigIds.length, miningActive: true);
      progression.evaluateUnlocks(balanceBtc: game.btcBalance, hashRate: game.totalBtcPerMin);
      _evaluateAchievements(game, progression, achievements);
      game.updateTick();
    });

    _syncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (!mounted) return;
      final game = context.read<GameStateService>();
      game.syncToCloud();
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        final now = DateTime.now();
        final minedDelta = (game.lifetimeMinedBtc - _lastLeaderboardMined).abs();
        final hashDelta  = _lastLeaderboardHash == 0
            ? game.totalBtcPerMin
            : ((game.totalBtcPerMin - _lastLeaderboardHash).abs() / _lastLeaderboardHash);
        final timeDue = _lastLeaderboardPushAt == null ||
            now.difference(_lastLeaderboardPushAt!).inMinutes >= 10;
        if (timeDue || minedDelta >= 0.00005 || hashDelta >= 0.1) {
          context.read<LeaderboardService>().updateUser(
            uid:         user.uid,
            displayName: user.displayName ?? user.email ?? 'Miner',
            totalMined:  game.lifetimeMinedBtc,
            hashRate:    game.totalBtcPerMin,
            farmSize:    game.ownedRigIds.length,
          ).catchError((_) {});
          _lastLeaderboardPushAt = now;
          _lastLeaderboardMined  = game.lifetimeMinedBtc;
          _lastLeaderboardHash   = game.totalBtcPerMin;
        }
      }
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
      context.read<GameStateService>().applyIdleEarningsOnResume();
      context.read<AdRemoteConfigService>().load();
      final cfg   = context.read<AdRemoteConfigService>();
      final game  = context.read<GameStateService>();
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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      context.read<GameStateService>().saveAndClose();
      context.read<NotificationService>().scheduleEarningsReminder();
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
    if (!achievements.isClaimed('rigs_10') && game.ownedRigIds.length >= 10) {
      achievements.markClaimed('rigs_10');
      game.grantDirectBtc(0.00008);
    }
    if (!achievements.isClaimed('hours_100') && game.totalSessionsStarted >= 100) {
      achievements.markClaimed('hours_100');
      game.grantDirectBtc(0.00012);
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
            'CRYPTOMINER',
            style: TextStyle(
              color: _D.gold,
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 4,
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
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
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