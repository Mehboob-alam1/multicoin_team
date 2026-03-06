import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService extends ChangeNotifier {
  String? _token;
  String? get token => _token;

  Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      _token = await messaging.getToken();
      notifyListeners();
    } catch (_) {}
  }
}

