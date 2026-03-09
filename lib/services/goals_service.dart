import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Daily and weekly goals with BTC rewards. Resets daily/weekly.
class GoalsService extends ChangeNotifier {
  static const _dailyClaimKey = 'goals_daily_claimed';
  static const _weeklyClaimKey = 'goals_weekly_claimed';
  static const _dailyProgressKey = 'goals_daily_progress';
  static const _weeklyProgressKey = 'goals_weekly_progress';
  static const _lastDailyDayKey = 'goals_last_daily_day';
  static const _lastWeeklyWeekKey = 'goals_last_weekly_week';

  int _lastDailyDay = 0;
  int _lastWeeklyWeek = 0;
  double _dailyProgressBtc = 0;
  int _weeklyProgressSessions = 0;
  bool _dailyClaimed = false;
  bool _weeklyClaimed = false;

  static const double dailyTargetBtc = 0.0001;
  static const int weeklyTargetSessions = 5;
  static const double dailyRewardBtc = 0.00002;
  static const double weeklyRewardBtc = 0.00005;

  double get dailyProgressBtc => _dailyProgressBtc;
  int get weeklyProgressSessions => _weeklyProgressSessions;
  bool get dailyClaimed => _dailyClaimed;
  bool get weeklyClaimed => _weeklyClaimed;
  bool get canClaimDaily => !_dailyClaimed && _dailyProgressBtc >= dailyTargetBtc;
  bool get canClaimWeekly => !_weeklyClaimed && _weeklyProgressSessions >= weeklyTargetSessions;
  double get dailyProgressPercent => (_dailyProgressBtc / dailyTargetBtc).clamp(0.0, 1.0);
  double get weeklyProgressPercent => (weeklyTargetSessions > 0)
      ? (_weeklyProgressSessions / weeklyTargetSessions).clamp(0.0, 1.0)
      : 0.0;

  static int _epochDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
  static int _epochWeek(DateTime d) => _epochDay(d) ~/ 7;

  Future<void> load() async {
    await LocalFeatureStore.init();
    _lastDailyDay = (LocalFeatureStore.get(_lastDailyDayKey, 0) as num).toInt();
    _lastWeeklyWeek = (LocalFeatureStore.get(_lastWeeklyWeekKey, 0) as num).toInt();
    _dailyProgressBtc = (LocalFeatureStore.get(_dailyProgressKey, 0.0) as num).toDouble();
    _weeklyProgressSessions = (LocalFeatureStore.get(_weeklyProgressKey, 0) as num).toInt();
    _dailyClaimed = LocalFeatureStore.get(_dailyClaimKey, false) == true;
    _weeklyClaimed = LocalFeatureStore.get(_weeklyClaimKey, false) == true;
    final today = _epochDay(DateTime.now());
    final thisWeek = _epochWeek(DateTime.now());
    if (today != _lastDailyDay) {
      _dailyProgressBtc = 0;
      _dailyClaimed = false;
      _lastDailyDay = today;
      await LocalFeatureStore.set(_dailyProgressKey, 0);
      await LocalFeatureStore.set(_dailyClaimKey, false);
      await LocalFeatureStore.set(_lastDailyDayKey, today);
    }
    if (thisWeek != _lastWeeklyWeek) {
      _weeklyProgressSessions = 0;
      _weeklyClaimed = false;
      _lastWeeklyWeek = thisWeek;
      await LocalFeatureStore.set(_weeklyProgressKey, 0);
      await LocalFeatureStore.set(_weeklyClaimKey, false);
      await LocalFeatureStore.set(_lastWeeklyWeekKey, thisWeek);
    }
    notifyListeners();
  }

  Future<void> addDailyMined(double btc) async {
    if (_dailyClaimed) return;
    _dailyProgressBtc += btc;
    if (_dailyProgressBtc > dailyTargetBtc) _dailyProgressBtc = dailyTargetBtc;
    await LocalFeatureStore.set(_dailyProgressKey, _dailyProgressBtc);
    notifyListeners();
  }

  Future<void> addWeeklySession() async {
    if (_weeklyClaimed) return;
    _weeklyProgressSessions += 1;
    await LocalFeatureStore.set(_weeklyProgressKey, _weeklyProgressSessions);
    notifyListeners();
  }

  Future<void> claimDaily() async {
    if (!canClaimDaily) return;
    _dailyClaimed = true;
    await LocalFeatureStore.set(_dailyClaimKey, true);
    notifyListeners();
  }

  Future<void> claimWeekly() async {
    if (!canClaimWeekly) return;
    _weeklyClaimed = true;
    await LocalFeatureStore.set(_weeklyClaimKey, true);
    notifyListeners();
  }
}
