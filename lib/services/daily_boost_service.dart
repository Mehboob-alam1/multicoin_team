import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class DailyBoostService extends ChangeNotifier {
  static const _lastClaimKey = 'daily_boost_last_claim_ms';
  static const _activeUntilKey = 'daily_boost_active_until_ms';
  static const _dialogShownForDayKey = 'daily_boost_dialog_shown_day';

  DateTime? _lastClaimAt;
  DateTime? _activeUntil;
  int _dialogShownForDay = 0;

  DateTime? get lastClaimAt => _lastClaimAt;
  DateTime? get activeUntil => _activeUntil;
  bool get isActive => _activeUntil != null && _activeUntil!.isAfter(DateTime.now());
  bool get canClaim {
    if (_lastClaimAt == null) return true;
    return DateTime.now().difference(_lastClaimAt!).inHours >= 24;
  }

  /// True if we already showed the claim dialog today (so we don't show on every launch).
  bool get hasShownDialogForCurrentDay {
    final today = DateTime.now().day + DateTime.now().month * 100 + DateTime.now().year * 10000;
    return _dialogShownForDay == today;
  }

  Future<void> recordDialogShownForCurrentDay() async {
    final today = DateTime.now().day + DateTime.now().month * 100 + DateTime.now().year * 10000;
    _dialogShownForDay = today;
    await LocalFeatureStore.set(_dialogShownForDayKey, today);
    notifyListeners();
  }

  Future<void> load() async {
    await LocalFeatureStore.init();
    final lastMs = LocalFeatureStore.get(_lastClaimKey);
    final untilMs = LocalFeatureStore.get(_activeUntilKey);
    final day = LocalFeatureStore.get(_dialogShownForDayKey);
    if (lastMs is int) _lastClaimAt = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (untilMs is int) _activeUntil = DateTime.fromMillisecondsSinceEpoch(untilMs);
    if (day is int) _dialogShownForDay = day;
    notifyListeners();
  }

  Future<bool> claim() async {
    if (!canClaim) return false;
    _lastClaimAt = DateTime.now();
    _activeUntil = DateTime.now().add(const Duration(minutes: 30));
    await LocalFeatureStore.set(_lastClaimKey, _lastClaimAt!.millisecondsSinceEpoch);
    await LocalFeatureStore.set(_activeUntilKey, _activeUntil!.millisecondsSinceEpoch);
    notifyListeners();
    return true;
  }

  double get miningMultiplier => isActive ? 2.0 : 1.0;
}

