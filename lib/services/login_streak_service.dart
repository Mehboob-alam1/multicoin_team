import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Tracks consecutive login days and gives rewards at 3 and 7 days to encourage daily return.
class LoginStreakService extends ChangeNotifier {
  static const _lastLoginDayKey = 'login_streak_last_day';
  static const _streakDaysKey = 'login_streak_days';
  static const _claimed3Key = 'login_streak_claimed_3';
  static const _claimed7Key = 'login_streak_claimed_7';

  int? _lastLoginDay;
  int _streakDays = 0;
  bool _claimed3 = false;
  bool _claimed7 = false;

  int get streakDays => _streakDays;
  bool get canClaimStreak3 => _streakDays >= 3 && !_claimed3;
  bool get canClaimStreak7 => _streakDays >= 7 && !_claimed7;

  static int _epochDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);

  Future<void> load() async {
    await LocalFeatureStore.init();
    _lastLoginDay = LocalFeatureStore.get(_lastLoginDayKey) as int?;
    _streakDays = (LocalFeatureStore.get(_streakDaysKey, 0) as num).toInt();
    _claimed3 = LocalFeatureStore.get(_claimed3Key, false) == true;
    _claimed7 = LocalFeatureStore.get(_claimed7Key, false) == true;
    notifyListeners();
  }

  /// Call on app open (e.g. HomeShell init). Updates streak based on last login day.
  Future<void> recordLogin() async {
    await LocalFeatureStore.init();
    final today = _epochDay(DateTime.now());
    if (_lastLoginDay == null) {
      _streakDays = 1;
    } else if (today == _lastLoginDay) {
      return; // already recorded today
    } else if (today == _lastLoginDay! + 1) {
      _streakDays += 1;
    } else {
      _streakDays = 1;
      _claimed3 = false;
      _claimed7 = false;
      await LocalFeatureStore.set(_claimed3Key, false);
      await LocalFeatureStore.set(_claimed7Key, false);
    }
    _lastLoginDay = today;
    await LocalFeatureStore.set(_lastLoginDayKey, today);
    await LocalFeatureStore.set(_streakDaysKey, _streakDays);
    notifyListeners();
  }

  Future<void> markStreak3Claimed() async {
    _claimed3 = true;
    await LocalFeatureStore.set(_claimed3Key, true);
    notifyListeners();
  }

  Future<void> markStreak7Claimed() async {
    _claimed7 = true;
    await LocalFeatureStore.set(_claimed7Key, true);
    notifyListeners();
  }
}
