import 'dart:math';
import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class RandomDropService extends ChangeNotifier {
  static const _nextDropKey = 'random_drop_next_ms';
  final Random _random = Random();
  DateTime? _nextDropAt;

  DateTime? get nextDropAt => _nextDropAt;
  bool get isAvailable => _nextDropAt != null && DateTime.now().isAfter(_nextDropAt!);

  Future<void> load() async {
    await LocalFeatureStore.init();
    final ms = LocalFeatureStore.get(_nextDropKey);
    if (ms is int) {
      _nextDropAt = DateTime.fromMillisecondsSinceEpoch(ms);
    } else {
      await scheduleNext();
    }
    notifyListeners();
  }

  Future<void> scheduleNext() async {
    final hours = 2 + _random.nextInt(4); // 2-5h
    _nextDropAt = DateTime.now().add(Duration(hours: hours));
    await LocalFeatureStore.set(_nextDropKey, _nextDropAt!.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<double?> collect() async {
    if (!isAvailable) return null;
    final reward = 0.00002 + (_random.nextDouble() * 0.00008);
    await scheduleNext();
    return reward;
  }
}

