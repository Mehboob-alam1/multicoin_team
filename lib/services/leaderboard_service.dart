import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _firestore = FirebaseFirestore.instance;
  static const _cacheKey = 'firestore_leaderboard_cache';

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

  Future<void> updateUser({
    required String uid,
    required String displayName,
    required double totalMined,
    required double hashRate,
    required int farmSize,
  }) async {
    await _firestore.collection('leaderboard').doc(uid).set({
      'displayName': displayName,
      'totalMined': totalMined,
      'hashRate': hashRate,
      'farmSize': farmSize,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> fetchTop() async {
    final snap = await _firestore.collection('leaderboard').limit(100).get();
    final list = snap.docs
        .map((d) => GlobalLeaderboardEntry(
              uid: d.id,
              name: (d.data()['displayName'] ?? 'Miner').toString(),
              totalMined: (d.data()['totalMined'] as num?)?.toDouble() ?? 0,
              hashRate: (d.data()['hashRate'] as num?)?.toDouble() ?? 0,
              farmSize: (d.data()['farmSize'] as num?)?.toInt() ?? 0,
            ))
        .toList();
    _cached = List.from(list);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_cached.map((e) => e.toJson()).toList()));
    notifyListeners();
  }
}

