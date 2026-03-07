import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Weekly challenge: complete N mining sessions this week for a reward. Resets every week.
class WeeklyChallengeService extends ChangeNotifier {
  static const _weekKey = 'weekly_challenge_week';
  static const _sessionsAtWeekStartKey = 'weekly_challenge_sessions_start';
  static const _claimedKey = 'weekly_challenge_claimed';
  static const targetSessions = 5;
  static const rewardBtc = 0.00002;

  String _currentWeek = '';
  int _sessionsAtWeekStart = 0;
  bool _claimed = false;

  int get sessionsAtWeekStart => _sessionsAtWeekStart;
  bool get claimed => _claimed;

  /// Progress this week = totalSessions - sessionsAtWeekStart (capped by target).
  int progressThisWeek(int totalSessionsStarted) {
    final p = totalSessionsStarted - _sessionsAtWeekStart;
    return p.clamp(0, targetSessions);
  }

  bool isComplete(int totalSessionsStarted) =>
      progressThisWeek(totalSessionsStarted) >= targetSessions;

  bool canClaim(int totalSessionsStarted) =>
      isComplete(totalSessionsStarted) && !_claimed;

  static String _weekId(DateTime d) {
    final start = DateTime(d.year, d.month, d.day);
    final weekStart = start.subtract(Duration(days: start.weekday % 7));
    return '${weekStart.year}-${weekStart.month}-${weekStart.day}';
  }

  Future<void> load(int totalSessionsStarted) async {
    await LocalFeatureStore.init();
    _currentWeek = LocalFeatureStore.get(_weekKey, '').toString();
    _sessionsAtWeekStart = (LocalFeatureStore.get(_sessionsAtWeekStartKey, 0) as num).toInt();
    _claimed = LocalFeatureStore.get(_claimedKey, false) == true;
    final week = _weekId(DateTime.now());
    if (week != _currentWeek) {
      _currentWeek = week;
      _sessionsAtWeekStart = totalSessionsStarted;
      _claimed = false;
      await LocalFeatureStore.set(_weekKey, week);
      await LocalFeatureStore.set(_sessionsAtWeekStartKey, _sessionsAtWeekStart);
      await LocalFeatureStore.set(_claimedKey, false);
    }
    notifyListeners();
  }

  Future<void> syncSessionsStart(int totalSessionsStarted) async {
    final week = _weekId(DateTime.now());
    if (week != _currentWeek) {
      _currentWeek = week;
      _sessionsAtWeekStart = totalSessionsStarted;
      _claimed = false;
      await LocalFeatureStore.set(_weekKey, week);
      await LocalFeatureStore.set(_sessionsAtWeekStartKey, _sessionsAtWeekStart);
      await LocalFeatureStore.set(_claimedKey, false);
    }
    notifyListeners();
  }

  Future<void> markClaimed() async {
    _claimed = true;
    await LocalFeatureStore.set(_claimedKey, true);
    notifyListeners();
  }
}
