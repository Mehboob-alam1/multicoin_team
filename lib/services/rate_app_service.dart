import 'dart:math';
import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Tracks when we last asked for rating and decides if we should show the rate dialog randomly.
class RateAppService extends ChangeNotifier {
  static const _keyLastShownMs = 'rate_dialog_last_shown_ms';
  static const _minSessionsBeforePrompt = 3;
  static const _minDaysBetweenPrompts = 14;
  static const _showChance = 0.15; // 15% chance when conditions met

  /// Returns true if we should show the rate dialog (random + cooldown + min sessions).
  Future<bool> shouldShowRateDialog({
    required int totalSessionsStarted,
  }) async {
    if (totalSessionsStarted < _minSessionsBeforePrompt) return false;
    await LocalFeatureStore.init();
    final lastMs = LocalFeatureStore.get(_keyLastShownMs);
    if (lastMs is int) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (DateTime.now().difference(last).inDays < _minDaysBetweenPrompts) {
        return false;
      }
    }
    return Random().nextDouble() < _showChance;
  }

  /// Call after user saw the rate dialog (whether they rated or dismissed).
  Future<void> markRateDialogShown() async {
    await LocalFeatureStore.init();
    await LocalFeatureStore.set(_keyLastShownMs, DateTime.now().millisecondsSinceEpoch);
  }
}
