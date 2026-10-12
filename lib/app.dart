import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/ad_remote_config_service.dart';
import 'services/analytics_service.dart';
import 'services/ad_pacing_service.dart';
import 'services/achievement_service.dart';
import 'services/auth_service.dart';
import 'services/btc_price_service.dart';
import 'services/daily_boost_service.dart';
import 'services/energy_cooling_service.dart';
import 'services/event_service.dart';
import 'services/firebase_sync_service.dart';
import 'services/game_state_service.dart';
import 'services/iap_service.dart';
import 'services/leaderboard_service.dart';
import 'services/login_streak_service.dart';
import 'services/lucky_spin_service.dart';
import 'services/notification_service.dart';
import 'services/progression_service.dart';
import 'services/random_drop_service.dart';
import 'services/referral_service.dart';
import 'services/smart_ad_manager.dart';
import 'services/rate_app_service.dart';
import 'services/weekly_challenge_service.dart';
import 'services/withdrawal_service.dart';
import 'services/goals_service.dart';
import 'services/comeback_bonus_service.dart';
import 'services/prestige_service.dart';
import 'services/mini_game_service.dart';
import 'services/season_service.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/premium_offer_screen.dart';
import 'screens/home_shell.dart';
import 'screens/profile_screen.dart';
import 'screens/lucky_spin_screen.dart';
import 'screens/news_screen.dart';
import 'screens/mini_game_screen.dart';
import 'screens/mining_farm_screen.dart';
import 'screens/shop_screen.dart';

class BtcSimApp extends StatelessWidget {
  const BtcSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => FirebaseSyncService()),
        ChangeNotifierProvider(create: (_) => BtcPriceService()),
        ChangeNotifierProvider(create: (_) => IapService()),
        ChangeNotifierProvider(create: (_) => AdRemoteConfigService()),
        ChangeNotifierProvider(create: (ctx) => AnalyticsService(ctx.read<AdRemoteConfigService>())),
        ChangeNotifierProvider(create: (ctx) => SmartAdManager(ctx.read<AdRemoteConfigService>())),
        ChangeNotifierProvider(create: (_) => AdPacingService()),
        ChangeNotifierProvider(create: (_) => ProgressionService()),
        ChangeNotifierProvider(create: (_) => DailyBoostService()),
        ChangeNotifierProvider(create: (_) => LoginStreakService()),
        ChangeNotifierProvider(create: (_) => LuckySpinService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => AchievementService()),
        ChangeNotifierProvider(create: (_) => EventService()),
        ChangeNotifierProvider(create: (_) => RandomDropService()),
        ChangeNotifierProvider(create: (_) => EnergyCoolingService()),
        ChangeNotifierProvider(create: (ctx) => LeaderboardService(ctx.read<FirebaseSyncService>())),
        ChangeNotifierProvider(create: (_) => ReferralService()),
        ChangeNotifierProvider(create: (_) => WeeklyChallengeService()),
        ChangeNotifierProvider(create: (_) => WithdrawalService()),
        ChangeNotifierProvider(create: (_) => RateAppService()),
        ChangeNotifierProvider(create: (_) => GoalsService()),
        ChangeNotifierProvider(create: (_) => ComebackBonusService()),
        ChangeNotifierProvider(create: (_) => PrestigeService()),
        ChangeNotifierProvider(create: (_) => MiniGameService()),
        ChangeNotifierProvider(create: (_) => SeasonService()),
        ChangeNotifierProvider(create: (ctx) => GameStateService(ctx.read<FirebaseSyncService>())),
      ],
      child: MaterialApp(
        title: 'Crypto Mining Tycoon',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (ctx) => const SplashScreen(),
          '/login': (ctx) => const LoginScreen(),
          '/premium-offer': (ctx) => const PremiumOfferScreen(),
          '/home': (ctx) => const HomeShell(),
          '/profile': (ctx) => const ProfileScreen(),
          '/lucky-spin': (ctx) => const LuckySpinScreen(),
          '/news': (ctx) => const NewsScreen(),
          '/mini-game': (ctx) => const MiniGameScreen(),
          '/farm': (ctx) => const MiningFarmScreen(),
          '/shop': (ctx) => const ShopScreen(),
        },
      ),
    );
  }
}
