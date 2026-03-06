import 'package:flutter/foundation.dart';
import '../models/mining_location.dart';
import 'local_feature_store.dart';

class ProgressionService extends ChangeNotifier {
  static const _key = 'unlocked_locations';
  List<String> _unlocked = ['garage'];

  List<String> get unlockedLocations => List.unmodifiable(_unlocked);

  int get locationCapacityBonus {
    int sum = 0;
    for (final loc in MiningLocations.all) {
      if (_unlocked.contains(loc.id)) sum += loc.farmCapacityBonus;
    }
    return sum;
  }

  Future<void> load() async {
    await LocalFeatureStore.init();
    final raw = LocalFeatureStore.get(_key, ['garage']);
    if (raw is List) {
      _unlocked = raw.map((e) => e.toString()).toList();
    }
    notifyListeners();
  }

  Future<void> evaluateUnlocks({
    required double balanceBtc,
    required double hashRate,
  }) async {
    bool changed = false;
    for (final loc in MiningLocations.all) {
      if (_unlocked.contains(loc.id)) continue;
      if (balanceBtc >= loc.unlockBtc || hashRate >= loc.unlockHashRate) {
        _unlocked = [..._unlocked, loc.id];
        changed = true;
      }
    }
    if (changed) {
      await LocalFeatureStore.set(_key, _unlocked);
      notifyListeners();
    }
  }
}

