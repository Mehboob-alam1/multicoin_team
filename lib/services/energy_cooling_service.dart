import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class EnergyCoolingService extends ChangeNotifier {
  static const _heatKey = 'heat_level';
  static const _coolingKey = 'cooling_level';
  static const _powerKey = 'power_level';
  static const _solarKey = 'solar_level';

  double _heat = 0.0; // 0..100
  int _cooling = 1;
  int _power = 1;
  int _solar = 0;

  double get heat => _heat;
  int get coolingLevel => _cooling;
  int get powerLevel => _power;
  int get solarLevel => _solar;

  Future<void> load() async {
    await LocalFeatureStore.init();
    _heat = (LocalFeatureStore.get(_heatKey, 0.0) as num).toDouble();
    _cooling = (LocalFeatureStore.get(_coolingKey, 1) as num).toInt();
    _power = (LocalFeatureStore.get(_powerKey, 1) as num).toInt();
    _solar = (LocalFeatureStore.get(_solarKey, 0) as num).toInt();
    notifyListeners();
  }

  int _heatPersistTicks = 0;

  Future<void> tickHeat({required int rigs, required bool miningActive}) async {
    final prev = _heat;
    if (miningActive) {
      _heat += (rigs * 0.03) + 0.08;
      _heat -= (_cooling * 0.12) + (_solar * 0.03);
    } else {
      _heat -= 0.35 + (_cooling * 0.05);
    }
    if (_heat < 0) _heat = 0;
    if (_heat > 100) _heat = 100;
    _heatPersistTicks++;
    if (_heatPersistTicks >= 15) {
      _heatPersistTicks = 0;
      await LocalFeatureStore.set(_heatKey, _heat);
    }
    if ((_heat - prev).abs() >= 0.4) notifyListeners();
  }

  double get efficiencyMultiplier {
    final safe = 55 + (_cooling * 2) + (_power * 2);
    if (_heat <= safe) return 1.0;
    final overflow = (_heat - safe).clamp(0, 40);
    return (1.0 - (overflow / 100)).clamp(0.6, 1.0);
  }

  Future<void> upgradeCooling() async {
    _cooling += 1;
    await LocalFeatureStore.set(_coolingKey, _cooling);
    notifyListeners();
  }

  Future<void> upgradePower() async {
    _power += 1;
    await LocalFeatureStore.set(_powerKey, _power);
    notifyListeners();
  }

  Future<void> upgradeSolar() async {
    _solar += 1;
    await LocalFeatureStore.set(_solarKey, _solar);
    notifyListeners();
  }
}

