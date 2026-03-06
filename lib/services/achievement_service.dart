import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class AchievementDef {
  final String id;
  final String title;
  final String desc;
  final double rewardBtc;
  const AchievementDef(this.id, this.title, this.desc, this.rewardBtc);
}

class AchievementService extends ChangeNotifier {
  static const _claimedKey = 'achievements_claimed';
  List<String> _claimed = [];

  static const defs = [
    AchievementDef('first_miner', 'First Miner', 'Own your first rig', 0.00002),
    AchievementDef('btc_1', '1 BTC (sim goal)', 'Mine cumulative milestones', 0.0002),
    AchievementDef('rigs_10', '10 Rigs Built', 'Own 10 rigs', 0.00008),
    AchievementDef('hours_100', '100 Hours Mining', 'Run long mining sessions', 0.00012),
    AchievementDef('factory_unlock', 'Factory Unlocked', 'Unlock Factory location', 0.0001),
  ];

  List<String> get claimed => List.unmodifiable(_claimed);

  Future<void> load() async {
    await LocalFeatureStore.init();
    final raw = LocalFeatureStore.get(_claimedKey, const <String>[]);
    if (raw is List) _claimed = raw.map((e) => e.toString()).toList();
    notifyListeners();
  }

  bool isClaimed(String id) => _claimed.contains(id);

  Future<void> markClaimed(String id) async {
    if (_claimed.contains(id)) return;
    _claimed = [..._claimed, id];
    await LocalFeatureStore.set(_claimedKey, _claimed);
    notifyListeners();
  }
}

