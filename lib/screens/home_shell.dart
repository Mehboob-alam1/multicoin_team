import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shop_product.dart';
import '../services/ad_pacing_service.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/daily_boost_service.dart';
import '../services/energy_cooling_service.dart';
import '../services/event_service.dart';
import '../services/game_state_service.dart';
import '../services/iap_service.dart';
import '../services/leaderboard_service.dart';
import '../services/lucky_spin_service.dart';
import '../services/notification_service.dart';
import '../services/progression_service.dart';
import '../services/random_drop_service.dart';
import '../services/referral_service.dart';
import '../services/smart_ad_manager.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'mining_farm_screen.dart';
import 'shop_screen.dart';
import 'leaderboard_screen.dart';
import 'rewards_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _timer;
  DateTime? _lastLeaderboardPushAt;
  double _lastLeaderboardMined = 0;
  double _lastLeaderboardHash = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    context.read<NotificationService>().init();
    context.read<AdPacingService>().load();
    if (user != null) {
      context.read<ReferralService>().load(user.uid);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final daily = context.read<DailyBoostService>();
      if (daily.canClaim) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Daily boost ready'),
            content: const Text('Claim your 2x mining speed boost for 30 minutes from the Dashboard.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
              FilledButton(
                onPressed: () async {
                  await daily.claim();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Claim now'),
              ),
            ],
          ),
        );
      }
    });
    final iap = context.read<IapService>();
    iap.onPurchaseSuccess = (productId, isSubscription, durationDays) {
      if (isSubscription) {
        game.activatePremium(productId, durationDays);
      } else {
        if (game.hasPurchasedOneTime(productId)) return;
        final p = ShopProducts.oneTimeById(productId);
        if (p != null) {
          if (productId == 'boost_2x_1h') game.activateBoost1h();
          game.applyOneTimePurchase(productId: productId, btcAmount: p.btcAmount, rigId: p.rigId);
        }
      }
    };
    iap.init();
    context.read<SmartAdManager>().preloadRewarded();
    context.read<SmartAdManager>().preloadInterstitial();
    context.read<SmartAdManager>().preloadAppOpen();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final game = context.read<GameStateService>();
      final progression = context.read<ProgressionService>();
      final daily = context.read<DailyBoostService>();
      final events = context.read<EventService>();
      final energy = context.read<EnergyCoolingService>();
      final achievements = context.read<AchievementService>();
      game.applyExternalGameplayModifiers(
        eventMiningMultiplier: events.miningMultiplier,
        dailyBoostMultiplier: daily.miningMultiplier,
        efficiencyMultiplier: energy.efficiencyMultiplier,
        locationCapacityBonus: progression.locationCapacityBonus,
        rigDiscount: events.rigDiscount,
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
        final hashDelta = (_lastLeaderboardHash == 0)
            ? game.totalBtcPerMin
            : ((game.totalBtcPerMin - _lastLeaderboardHash).abs() / _lastLeaderboardHash);
        final timeDue = _lastLeaderboardPushAt == null ||
            now.difference(_lastLeaderboardPushAt!).inMinutes >= 10;
        final changedEnough = minedDelta >= 0.00005 || hashDelta >= 0.1;
        if (timeDue || changedEnough) {
          context.read<LeaderboardService>().updateUser(
            uid: user.uid,
            displayName: user.displayName ?? user.email ?? 'Miner',
            totalMined: game.lifetimeMinedBtc,
            hashRate: game.totalBtcPerMin,
            farmSize: game.ownedRigIds.length,
          ).catchError((_) {});
          _lastLeaderboardPushAt = now;
          _lastLeaderboardMined = game.lifetimeMinedBtc;
          _lastLeaderboardHash = game.totalBtcPerMin;
        }
      }
    });
  }

  Timer? _syncTimer;

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
      final pacing = context.read<AdPacingService>();
      final ads = context.read<SmartAdManager>();
      pacing.canShowAppOpen(completedSessions: game.totalSessionsCompleted).then((canShow) async {
        if (!canShow || !mounted) return;
        final shown = await ads.showAppOpen();
        if (shown) {
          await pacing.markAppOpenShown();
        }
      });
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      context.read<GameStateService>().saveAndClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameStateService>();
    final pages = [
      const DashboardScreen(),
      const MiningFarmScreen(),
      const ShopScreen(),
      const LeaderboardScreen(),
      const RewardsScreen(),
    ];
    return Scaffold(
      body: game.isLoaded
          ? IndexedStack(
              index: _index,
              children: pages,
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Loading your mining farm...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
      bottomNavigationBar: game.isLoaded
          ? BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.warehouse), label: 'Farm'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewards'),
        ],
      )
          : null,
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
    setState(() => _index = i);
    final game = context.read<GameStateService>();
    final pacing = context.read<AdPacingService>();
    final ads = context.read<SmartAdManager>();
    await pacing.registerNavigationTransition();
    final canShow = await pacing.shouldShowInterstitial(
      completedSessions: game.totalSessionsCompleted,
    );
    if (!canShow || !mounted) return;
    final shown = await ads.showInterstitial();
    if (shown) {
      await pacing.markInterstitialShown();
    }
  }
}
