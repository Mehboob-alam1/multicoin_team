import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/background_mining_task.dart';

/// FCM background handler (must be top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Workmanager dispatcher: runs when background mining task is due.
@pragma('vm:entry-point')
void _workmanagerDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _backgroundMiningTaskName) {
      await backgroundMiningCallback();
    }
    return true;
  });
}

const String _backgroundMiningTaskName = 'btc_background_mining';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Workmanager().initialize(_workmanagerDispatcher);
  try {
    await Hive.initFlutter();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await MobileAds.instance.initialize();
    // FCM: foreground messages (optional - token is obtained in NotificationService.init())
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // App in foreground: you can show in-app banner or rely on system tray when app is in background
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // User tapped notification - can navigate to a specific screen from message.data
    });
  } catch (e) {
    runApp(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
      body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
            Text(
                    'Configure Firebase',
                    style: ThemeData.dark().textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Run: dart run flutterfire configure\n'
                    'Then add google-services.json (Android) and GoogleService-Info.plist (iOS).',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  await Workmanager().registerPeriodicTask(
    _backgroundMiningTaskName,
    _backgroundMiningTaskName,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 1),
  );
  runApp(const BtcSimApp());
}
