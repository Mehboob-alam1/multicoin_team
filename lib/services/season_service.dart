import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Seasons / battle pass: 4-6 week season with free track and optional paid track.
class SeasonService extends ChangeNotifier {
  static const _seasonIdKey = 'season_id';
  static const _xpKey = 'season_xp';
  static const _freeClaimedKey = 'season_free_claimed';
  static const _premiumUnlockedKey = 'season_premium_unlocked';

  int _seasonId = 1;
  int _xp = 0;
  List<int> _freeClaimed = [];
  bool _premiumUnlocked = false;

  static const int seasonDurationDays = 28;
  static const int xpPerSession = 10;
  static const int xpPerDailyClaim = 25;
  static const List<int> freeMilestones = [100, 300, 600, 1000, 1500];
  static const List<double> freeRewardsBtc = [0.00002, 0.00005, 0.0001, 0.00015, 0.0002];
  static const List<int> premiumMilestones = [200, 500, 900, 1400, 2000];
  static const List<double> premiumRewardsBtc = [0.00003, 0.00008, 0.00015, 0.00025, 0.0004];

  int get seasonId => _seasonId;
  int get xp => _xp;
  bool get premiumUnlocked => _premiumUnlocked;
  List<int> get freeClaimed => List.unmodifiable(_freeClaimed);

  int get currentMaxFreeMilestone {
    for (var i = freeMilestones.length - 1; i >= 0; i--) {
      if (_xp >= freeMilestones[i]) return freeMilestones[i];
    }
    return 0;
  }

  bool canClaimFree(int index) {
    if (index < 0 || index >= freeMilestones.length) return false;
    if (_freeClaimed.contains(freeMilestones[index])) return false;
    return _xp >= freeMilestones[index];
  }

  Future<void> load() async {
    await LocalFeatureStore.init();
    _seasonId = (LocalFeatureStore.get(_seasonIdKey, 1) as num).toInt();
    _xp = (LocalFeatureStore.get(_xpKey, 0) as num).toInt();
    final fc = LocalFeatureStore.get(_freeClaimedKey, <int>[]);
    _freeClaimed = fc is List ? fc.map((e) => (e as num).toInt()).toList() : [];
    _premiumUnlocked = LocalFeatureStore.get(_premiumUnlockedKey, false) == true;
    notifyListeners();
  }

  Future<void> addXp(int amount) async {
    _xp += amount;
    await LocalFeatureStore.set(_xpKey, _xp);
    notifyListeners();
  }

  Future<void> claimFreeReward(int milestoneIndex) async {
    if (milestoneIndex < 0 || milestoneIndex >= freeMilestones.length) return;
    final m = freeMilestones[milestoneIndex];
    if (!canClaimFree(milestoneIndex)) return;
    _freeClaimed = [..._freeClaimed, m];
    await LocalFeatureStore.set(_freeClaimedKey, _freeClaimed);
    notifyListeners();
  }

  Future<void> unlockPremium() async {
    _premiumUnlocked = true;
    await LocalFeatureStore.set(_premiumUnlockedKey, true);
    notifyListeners();
  }
}
