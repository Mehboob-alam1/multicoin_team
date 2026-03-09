import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_sync_service.dart';

class GlobalLeaderboardEntry {
  final String uid;
  final String name;
  final double totalMined;
  final double hashRate;
  final int farmSize;
  const GlobalLeaderboardEntry({
    required this.uid,
    required this.name,
    required this.totalMined,
    required this.hashRate,
    required this.farmSize,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'totalMined': totalMined,
        'hashRate': hashRate,
        'farmSize': farmSize,
      };

  static GlobalLeaderboardEntry fromJson(Map<String, dynamic> m) => GlobalLeaderboardEntry(
        uid: m['uid'] as String,
        name: m['name'] as String,
        totalMined: (m['totalMined'] as num).toDouble(),
        hashRate: (m['hashRate'] as num).toDouble(),
        farmSize: (m['farmSize'] as num).toInt(),
      );
}

class LeaderboardService extends ChangeNotifier {
  LeaderboardService(this._firebaseSync);

  final FirebaseSyncService _firebaseSync;
  static const _cacheKey = 'leaderboard_cache';
  static const _cacheTimeKey = 'leaderboard_cache_time_ms';
  static const _cacheMaxAge = Duration(minutes: 5);

  List<GlobalLeaderboardEntry> _cached = [];
  List<GlobalLeaderboardEntry> get cached => List.unmodifiable(_cached);

  Future<void> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).cast<Map>();
    _cached = list.map((e) => GlobalLeaderboardEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    notifyListeners();
  }

  /// Fetches top entries from RTDB only. Uses cache if younger than [_cacheMaxAge] to reduce Firebase usage.
  Future<void> fetchTop() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheTimeMs = prefs.getInt(_cacheTimeKey);
    if (cacheTimeMs != null &&
        DateTime.now().millisecondsSinceEpoch - cacheTimeMs < _cacheMaxAge.inMilliseconds) {
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        try {
          final list = (jsonDecode(raw) as List).cast<Map>();
          _cached = list.map((e) => GlobalLeaderboardEntry.fromJson(Map<String, dynamic>.from(e))).toList();
          notifyListeners();
          return;
        } catch (_) {}
      }
    }
    final rtdbList = await _firebaseSync.getLeaderboard(limit: 100);
    _cached = rtdbList
        .map((e) => GlobalLeaderboardEntry(
              uid: e.uid,
              name: e.displayName,
              totalMined: e.btcBalance,
              hashRate: e.totalBtcPerMin,
              farmSize: 0,
            ))
        .toList();
    await prefs.setString(_cacheKey, jsonEncode(_cached.map((e) => e.toJson()).toList()));
    await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
  }
}

