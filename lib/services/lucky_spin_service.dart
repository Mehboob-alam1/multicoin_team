import 'dart:math';
import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class SpinResult {
  final String type;
  final double btc;
  final String? rigId;
  final Duration? boost;
  final String label;

  const SpinResult({
    required this.type,
    required this.label,
    this.btc = 0,
    this.rigId,
    this.boost,
  });
}

class LuckySpinService extends ChangeNotifier {
  static const _lastSpinKey = 'lucky_spin_last_ms';
  DateTime? _lastSpinAt;
  final Random _random = Random();

  DateTime? get lastSpinAt => _lastSpinAt;
  bool get canSpin {
    if (_lastSpinAt == null) return true;
    return DateTime.now().difference(_lastSpinAt!).inHours >= 24;
  }

  Future<void> load() async {
    await LocalFeatureStore.init();
    final ms = LocalFeatureStore.get(_lastSpinKey);
    if (ms is int) _lastSpinAt = DateTime.fromMillisecondsSinceEpoch(ms);
    notifyListeners();
  }

  Future<SpinResult?> spin() async {
    if (!canSpin) return null;
    _lastSpinAt = DateTime.now();
    await LocalFeatureStore.set(_lastSpinKey, _lastSpinAt!.millisecondsSinceEpoch);
    notifyListeners();

    final roll = _random.nextInt(100);
    if (roll < 35) {
      return const SpinResult(type: 'btc_small', label: 'BTC bonus', btc: 0.00003);
    }
    if (roll < 60) {
      return const SpinResult(type: 'btc_big', label: 'Big BTC bonus', btc: 0.00012);
    }
    if (roll < 78) {
      return const SpinResult(type: 'boost', label: 'Mining boost', boost: Duration(minutes: 20));
    }
    if (roll < 92) {
      return const SpinResult(type: 'gpu', label: 'Free GPU rig', rigId: 'gpu_rig');
    }
    return const SpinResult(type: 'rare', label: 'Rare miner', rigId: 'mining_rack');
  }
}

