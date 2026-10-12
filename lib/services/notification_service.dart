import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../data/test_miners.dart';

class NotificationService extends ChangeNotifier {
  String? _token;
  String? get token => _token;

  static const _channelId = 'btc_sim_channel';
  static const _channelName = 'Solana Mining Tycoon';
  static const _miningChannelId = 'mining_alerts';
  static const _miningChannelName = 'Mining alerts';

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _localInitialized = false;
  bool _fcmBound = false;

  Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _token = await messaging.getToken();
      messaging.onTokenRefresh.listen((t) {
        _token = t;
        notifyListeners();
      });
      await messaging.subscribeToTopic('all_miners');
      final region = TestMiners.regionFromCountryCode(
        PlatformDispatcher.instance.locale.countryCode,
      );
      if (region != 'all') {
        await messaging.subscribeToTopic('miners_$region');
      }
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      notifyListeners();
    } catch (_) {}

    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _local.initialize(
        const InitializationSettings(android: android, iOS: darwin),
      );
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Mining session and app notifications',
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _miningChannelId,
          _miningChannelName,
          description: 'Alerts when mining starts or stops',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
      _localInitialized = true;
      try {
        tz_data.initializeTimeZones();
        if (tz.local.name == 'Unknown') tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> bindUser(String? uid) async {
    if (uid == null || uid.isEmpty || _token == null || _token!.isEmpty) return;
    if (_fcmBound) return;
    _fcmBound = true;
    try {
      final region = TestMiners.regionFromCountryCode(
        PlatformDispatcher.instance.locale.countryCode,
      );
      await FirebaseDatabase.instance.ref('users/$uid/fcm').set({
        'token': _token,
        'region': region,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _show(
      id: 80,
      title: n.title ?? 'Solana Mining Tycoon',
      body: n.body ?? '',
      mining: true,
    );
  }

  static const _idSpinReminder = 10;
  static const _idEarningsReminder = 11;
  static const _idDailyRewardReminder = 12;
  static const _idBoostReminder = 13;
  static const _idMiningStarted = 1;
  static const _idMiningStopped = 2;

  Future<void> scheduleSpinReminder() async {
    if (!_localInitialized) return;
    try {
      await _local.cancel(_idSpinReminder);
      final when = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));
      await _local.zonedSchedule(
        _idSpinReminder,
        'Your Lucky Spin is ready!',
        'Spin the wheel for a chance to win SOL, rigs, or boosts.',
        when,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> scheduleEarningsReminder() async {
    if (!_localInitialized) return;
    try {
      await _local.cancel(_idEarningsReminder);
      final when = tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));
      await _local.zonedSchedule(
        _idEarningsReminder,
        'You\'re earning SOL!',
        'Come back to collect your mining earnings.',
        when,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> scheduleDailyRewardReminder() async {
    if (!_localInitialized) return;
    try {
      await _local.cancel(_idDailyRewardReminder);
      final when = tz.TZDateTime.now(tz.local).add(const Duration(hours: 20));
      await _local.zonedSchedule(
        _idDailyRewardReminder,
        'Daily reward ready!',
        'Claim your daily SOL and keep your streak.',
        when,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> scheduleBoostReminder(Duration inDuration) async {
    if (!_localInitialized) return;
    try {
      await _local.cancel(_idBoostReminder);
      final when = tz.TZDateTime.now(tz.local).add(inDuration);
      await _local.zonedSchedule(
        _idBoostReminder,
        'Mining boost',
        'Your 2× boost is available again.',
        when,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> showMiningSessionStarted() async {
    await _show(
      id: _idMiningStarted,
      title: 'Mining started',
      body: 'Your validators are live. Earning 1.25× SOL for 30 minutes — mining continues in the background.',
      mining: true,
    );
  }

  Future<void> showMiningSessionEnded() async {
    await _show(
      id: _idMiningStopped,
      title: 'Mining session ended',
      body: 'Your 30-minute boost finished. Start another session to earn 1.25× again.',
      mining: true,
    );
  }

  NotificationDetails _details({bool mining = false}) {
    final channelId = mining ? _miningChannelId : _channelId;
    final channelName = mining ? _miningChannelName : _channelName;
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: mining
          ? 'Alerts when mining starts or stops'
          : 'Mining session and app notifications',
      importance: mining ? Importance.high : Importance.defaultImportance,
      priority: mining ? Priority.high : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    return NotificationDetails(android: android, iOS: darwin);
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    bool mining = false,
  }) async {
    if (!_localInitialized) return;
    try {
      await _local.show(id, title, body, _details(mining: mining));
    } catch (_) {}
  }
}
