import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Prestige: reset progress for a permanent mining multiplier.
class PrestigeService extends ChangeNotifier {
  static const _levelKey = 'prestige_level';
  static const _tokensKey = 'prestige_tokens';

  int _level = 0;
  int _tokens = 0;

  int get level => _level;
  int get tokens => _tokens;
  /// Combined mining multiplier (speed × efficiency) for backward compatibility.
  double get permanentMultiplier => miningSpeedMultiplier * efficiencyMultiplier;
  /// +20% mining speed per prestige level.
  double get miningSpeedMultiplier => 1.0 + (level * 0.20);
  /// +15% efficiency per prestige level.
  double get efficiencyMultiplier => 1.0 + (level * 0.15);
  /// +10% reward bonuses (daily, milestones) per prestige level.
  double get rewardBonusMultiplier => 1.0 + (level * 0.10);
  static const double minBtcToPrestige = 0.001;
  static const int tokensPerPrestige = 1;

  Future<void> load() async {
    await LocalFeatureStore.init();
    _level = (LocalFeatureStore.get(_levelKey, 0) as num).toInt();
    _tokens = (LocalFeatureStore.get(_tokensKey, 0) as num).toInt();
    notifyListeners();
  }

  Future<void> performPrestige() async {
    await LocalFeatureStore.init();
    _level += 1;
    _tokens += tokensPerPrestige;
    await LocalFeatureStore.set(_levelKey, _level);
    await LocalFeatureStore.set(_tokensKey, _tokens);
    notifyListeners();
  }

  bool canPrestige(double lifetimeMinedBtc) => lifetimeMinedBtc >= minBtcToPrestige;
}
