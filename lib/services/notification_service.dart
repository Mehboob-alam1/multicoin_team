import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService extends ChangeNotifier {
  String? _token;
  String? get token => _token;

  static const _channelId = 'btc_sim_channel';
  static const _channelName = 'BTC Mining Simulator';

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _localInitialized = false;

  Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      _token = await messaging.getToken();
      notifyListeners();
    } catch (_) {}

    try {
      if (Platform.isAndroid) {
        final android = AndroidInitializationSettings('@mipmap/ic_launcher');
        final darwin = DarwinInitializationSettings();
        await _local.initialize(
          InitializationSettings(android: android, iOS: darwin),
        );
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              AndroidNotificationChannel(
                _channelId,
                _channelName,
                description: 'Mining session and app notifications',
                importance: Importance.defaultImportance,
              ),
            );
      } else if (Platform.isIOS) {
        final darwin = DarwinInitializationSettings();
        await _local.initialize(
          InitializationSettings(iOS: darwin),
        );
      }
      _localInitialized = true;
      try {
        tz_data.initializeTimeZones();
        if (tz.local.name == 'Unknown') tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    } catch (_) {}
  }

  static const _idSpinReminder = 10;
  static const _idEarningsReminder = 11;

  /// Schedule "Your Lucky Spin is ready!" for 24 hours from now. Call after user spins.
  Future<void> scheduleSpinReminder() async {
    if (!_localInitialized) return;
    try {
      await _local.cancel(_idSpinReminder);
      final when = tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));
      final android = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Mining session and app notifications',
      );
      final details = NotificationDetails(android: android);
      await _local.zonedSchedule(
        _idSpinReminder,
        'Your Lucky Spin is ready!',
        'Spin the wheel for a chance to win BTC, rigs, or boosts.',
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  /// Schedule "Come back and collect your earnings!" for 2 hours from now. Call when app goes to background.
  Future<void> scheduleEarningsReminder() async {
    if (!_localInitialized) return;
    try {
      await _local.cancel(_idEarningsReminder);
      final when = tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));
      final android = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Mining session and app notifications',
      );
      final details = NotificationDetails(android: android);
      await _local.zonedSchedule(
        _idEarningsReminder,
        'You\'re earning BTC!',
        'Come back to collect your mining earnings.',
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  /// Show a local notification when user starts a mining session.
  Future<void> showMiningSessionStarted() async {
    if (!_localInitialized) return;
    try {
      final android = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Mining session and app notifications',
      );
      final darwin = DarwinNotificationDetails();
      final details = NotificationDetails(android: android, iOS: darwin);
      await _local.show(
        1,
        'Mining started',
        'You\'re earning 1.25× BTC for 30 min. Mining continues in background!',
        details,
      );
    } catch (_) {}
  }
}
