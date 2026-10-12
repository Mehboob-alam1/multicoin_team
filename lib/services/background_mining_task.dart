import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/player_data.dart';

const backgroundMiningTaskName = 'btc_background_mining';

@pragma('vm:entry-point')
void workmanagerDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == backgroundMiningTaskName) {
      await backgroundMiningCallback();
    }
    return true;
  });
}

Future<void> startBackgroundMining() async {
  await Workmanager().initialize(workmanagerDispatcher);
  await Workmanager().registerPeriodicTask(
    backgroundMiningTaskName,
    backgroundMiningTaskName,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 1),
  );
}

/// Keys must match GameStateService storage.
const String _playerDataKeyPrefix = 'btc_sim_player_data';
const String _idleRatesKey = 'btc_sim_idle_rates';
const int _maxIdleMinutes = 8 * 60;

/// Called by Workmanager when the periodic task runs. Applies idle mining
/// earnings using rates and lastClosedAt persisted by GameStateService.saveAndClose().
@pragma('vm:entry-point')
Future<void> backgroundMiningCallback() async {
  final prefs = await SharedPreferences.getInstance();
  final ratesJson = prefs.getString(_idleRatesKey);
  if (ratesJson == null || ratesJson.isEmpty) return;

  Map<String, dynamic> rates;
  try {
    rates = jsonDecode(ratesJson) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  final dataKey = rates['dataKey'] as String?;
  final lastClosedStr = rates['lastClosedAt'] as String?;
  final rateWithSession = (rates['rateWithSession'] as num?)?.toDouble();
  final rateWithoutSession = (rates['rateWithoutSession'] as num?)?.toDouble();
  final sessionEndsAtStr = rates['sessionEndsAt'] as String?;

  if (dataKey == null ||
      dataKey.isEmpty ||
      lastClosedStr == null ||
      rateWithSession == null ||
      rateWithoutSession == null) {
    await prefs.remove(_idleRatesKey);
    return;
  }

  final closed = DateTime.tryParse(lastClosedStr);
  if (closed == null) {
    await prefs.remove(_idleRatesKey);
    return;
  }

  final now = DateTime.now();
  final minutesAway = now.difference(closed).inMinutes.clamp(0, _maxIdleMinutes);
  if (minutesAway <= 0) {
    await prefs.remove(_idleRatesKey);
    return;
  }

  final sessionEndsAt =
      sessionEndsAtStr != null ? DateTime.tryParse(sessionEndsAtStr) : null;

  double earned;
  if (sessionEndsAt != null && sessionEndsAt.isAfter(closed)) {
    final minutesSessionActive =
        minutesAway.clamp(0, sessionEndsAt.difference(closed).inMinutes);
    final minutesNormal = minutesAway - minutesSessionActive;
    earned =
        rateWithSession * minutesSessionActive + rateWithoutSession * minutesNormal;
  } else {
    earned = rateWithoutSession * minutesAway;
  }

  if (earned <= 0) {
    await prefs.remove(_idleRatesKey);
    final dataStr = prefs.getString(dataKey);
    if (dataStr != null) {
      try {
        final data = PlayerData.fromJson(
            jsonDecode(dataStr) as Map<String, dynamic>);
        final updated = data.copyWith(lastClosedAt: null);
        await prefs.setString(dataKey, jsonEncode(updated.toJson()));
      } catch (_) {}
    }
    return;
  }

  final dataStr = prefs.getString(dataKey);
  if (dataStr == null) {
    await prefs.remove(_idleRatesKey);
    return;
  }

  PlayerData data;
  try {
    data = PlayerData.fromJson(jsonDecode(dataStr) as Map<String, dynamic>);
  } catch (_) {
    await prefs.remove(_idleRatesKey);
    return;
  }

  const primaryId = 'sol';
  final curBtc = data.coinBalances[primaryId] ?? data.btcBalance;
  final curLifeBtc = data.lifetimeMinedByCoin[primaryId] ?? data.lifetimeMinedBtc;
  final newCoins = Map<String, double>.from(data.coinBalances)..[primaryId] = curBtc + earned;
  final newLife = Map<String, double>.from(data.lifetimeMinedByCoin)..[primaryId] = curLifeBtc + earned;
  final updated = data.copyWith(
    btcBalance: curBtc + earned,
    lifetimeMinedBtc: curLifeBtc + earned,
    coinBalances: newCoins,
    lifetimeMinedByCoin: newLife,
    lastClosedAt: null,
  );
  await prefs.setString(dataKey, jsonEncode(updated.toJson()));
  await prefs.remove(_idleRatesKey);
}

/// Persist idle rates so the background task can apply earnings. Call from
/// GameStateService.saveAndClose() with the same prefs key used for player data.
Future<void> persistIdleRatesForBackground({
  required String dataKey,
  required DateTime lastClosedAt,
  required double rateWithSession,
  required double rateWithoutSession,
  DateTime? sessionEndsAt,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final map = <String, dynamic>{
    'dataKey': dataKey,
    'lastClosedAt': lastClosedAt.toIso8601String(),
    'rateWithSession': rateWithSession,
    'rateWithoutSession': rateWithoutSession,
  };
  if (sessionEndsAt != null) {
    map['sessionEndsAt'] = sessionEndsAt.toIso8601String();
  }
  await prefs.setString(_idleRatesKey, jsonEncode(map));
}
