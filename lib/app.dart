import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
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
import 'services/lucky_spin_service.dart';
import 'services/notification_service.dart';
import 'services/progression_service.dart';
import 'services/random_drop_service.dart';
import 'services/referral_service.dart';
import 'services/smart_ad_manager.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/profile_screen.dart';

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
        ChangeNotifierProvider(create: (_) => SmartAdManager()),
        ChangeNotifierProvider(create: (_) => AdPacingService()),
        ChangeNotifierProvider(create: (_) => ProgressionService()),
        ChangeNotifierProvider(create: (_) => DailyBoostService()),
        ChangeNotifierProvider(create: (_) => LuckySpinService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => AchievementService()),
        ChangeNotifierProvider(create: (_) => EventService()),
        ChangeNotifierProvider(create: (_) => RandomDropService()),
        ChangeNotifierProvider(create: (_) => EnergyCoolingService()),
        ChangeNotifierProvider(create: (_) => LeaderboardService()),
        ChangeNotifierProvider(create: (_) => ReferralService()),
        ChangeNotifierProvider(create: (ctx) => GameStateService(ctx.read<FirebaseSyncService>())),
      ],
      child: MaterialApp(
        title: 'BTC Mining Simulator',
        theme: AppTheme.dark,
        initialRoute: '/',
        routes: {
          '/': _authWrapper,
          '/login': (ctx) => const LoginScreen(),
          '/home': (ctx) => const HomeShell(),
          '/profile': (ctx) => const ProfileScreen(),
        },
      ),
    );
  }

  Widget _authWrapper(BuildContext context) {
    return Consumer<AuthService>(
      builder: (_, auth, __) {
        if (auth.currentUser != null) {
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}
