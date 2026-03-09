import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Simple mini-games for bonus BTC (e.g. tap coin 10 times in 5 sec). Limited plays per day.
class MiniGameService extends ChangeNotifier {
  static const _lastPlayDayKey = 'minigame_last_play_day';
  static const _playsTodayKey = 'minigame_plays_today';

  int _lastPlayDay = 0;
  int _playsToday = 0;

  static const int maxPlaysPerDay = 3;
  static const int tapTarget = 10;
  static const int tapTimeSec = 5;
  static const double rewardBtc = 0.00002;

  int get playsToday => _playsToday;
  int get playsLeft => (maxPlaysPerDay - _playsToday).clamp(0, maxPlaysPerDay);
  bool get canPlay => playsLeft > 0;

  static int _epochDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);

  Future<void> load() async {
    await LocalFeatureStore.init();
    final today = _epochDay(DateTime.now());
    _lastPlayDay = (LocalFeatureStore.get(_lastPlayDayKey, 0) as num).toInt();
    if (today != _lastPlayDay) {
      _playsToday = 0;
      _lastPlayDay = today;
      await LocalFeatureStore.set(_lastPlayDayKey, today);
      await LocalFeatureStore.set(_playsTodayKey, 0);
    } else {
      _playsToday = (LocalFeatureStore.get(_playsTodayKey, 0) as num).toInt();
    }
    notifyListeners();
  }

  /// Returns true if the player won (reached tap target in time). Call after game ends.
  Future<bool> recordPlay({required int taps, required int elapsedMs}) async {
    if (!canPlay) return false;
    await LocalFeatureStore.init();
    final today = _epochDay(DateTime.now());
    if (today != _lastPlayDay) {
      _playsToday = 0;
      _lastPlayDay = today;
    }
    _playsToday += 1;
    await LocalFeatureStore.set(_lastPlayDayKey, _lastPlayDay);
    await LocalFeatureStore.set(_playsTodayKey, _playsToday);
    notifyListeners();
    final won = taps >= tapTarget && elapsedMs <= tapTimeSec * 1000;
    return won;
  }
}
