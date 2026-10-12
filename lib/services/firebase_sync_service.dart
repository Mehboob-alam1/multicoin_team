import 'package:firebase_database/firebase_database.dart';
import '../models/player_data.dart';

/// Firebase usage is kept low to control costs:
/// - Sync to cloud every 10 min (home_shell), min interval 12 min (game_state).
/// - Game state fetches from Firebase only once per app session.
/// - Leaderboard: RTDB only, 100 entries, 5 min cache (LeaderboardService.fetchTop).
/// - Events: Firestore refresh at most every 6 h (EventService).
/// - Referral: Firestore cache 24 h (ReferralService).
/// - Remote Config: fetch at most every 6 h in release.
class FirebaseSyncService {
  final _db = FirebaseDatabase.instance;
  static const _users = 'users';
  static const _leaderboard = 'leaderboard';
  static const _playerData = 'playerData';
  static const _purchases = 'purchases';
  static const _oneTime = 'oneTime';
  static const _subscription = 'subscription';
  static const _boostExpiryMs = 'boostExpiryMs';
  static const _googleHistory = 'googleHistory';
  static const _farmRigs = 'farmRigs';
  static const _iapCatalog = 'iapCatalog';

  /// Sync full player data to Firebase (merge with cloud).
  Future<void> syncPlayerData(String uid, PlayerData data, {String? displayName}) async {
    try {
      final ref = _db.ref('$_users/$uid/$_playerData');
      await ref.set(data.toJson());
      if (displayName != null && displayName.isNotEmpty) {
        await _db.ref('$_users/$uid/profile/displayName').set(displayName);
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Fetch player data from Firebase. Returns null if none or error.
  Future<PlayerData?> fetchPlayerData(String uid) async {
    try {
      final snap = await _db.ref('$_users/$uid/$_playerData').get();
      if (!snap.exists || snap.value == null) return null;
      final map = Map<String, dynamic>.from(snap.value as Map);
      return PlayerData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Update leaderboard entry for this user (call after balance/mining power change).
  Future<void> updateLeaderboard(
    String uid, {
    required String displayName,
    required double btcBalance,
    required double totalBtcPerMin,
  }) async {
    try {
      await _db.ref('$_leaderboard/entries/$uid').set({
        'displayName': displayName,
        'btcBalance': btcBalance,
        'totalBtcPerMin': totalBtcPerMin,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      rethrow;
    }
  }

  /// Get top entries by balance (descending). Returns list of [rank, displayName, btcBalance, totalBtcPerMin].
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 100}) async {
    try {
      final snap = await _db.ref('$_leaderboard/entries').orderByChild('btcBalance').limitToLast(100).get();
      if (!snap.exists || snap.value == null) return [];
      final map = snap.value as Map<dynamic, dynamic>;
      final list = map.entries
          .map((e) => LeaderboardEntry(
                uid: e.key as String,
                displayName: (e.value as Map)['displayName'] as String? ?? 'Unknown',
                btcBalance: ((e.value as Map)['btcBalance'] as num?)?.toDouble() ?? 0,
                totalBtcPerMin: ((e.value as Map)['totalBtcPerMin'] as num?)?.toDouble() ?? 0,
              ))
          .toList();
      list.sort((a, b) => b.btcBalance.compareTo(a.btcBalance));
      return list.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  /// Record one-time purchase entitlement (store in Firebase).
  Future<void> recordOneTimePurchase(String uid, String productId) async {
    try {
      await _db.ref('$_users/$uid/$_purchases/$_oneTime/$productId').set({
        'at': DateTime.now().millisecondsSinceEpoch,
        'googleProductId': productId,
        'source': 'google_play',
      });
    } catch (_) {
      rethrow;
    }
  }

  /// Full Google Play purchase record: entitlement + history (and farm line if a rig).
  Future<void> recordGooglePlayPurchase({
    required String uid,
    required String productId,
    required String category,
    required bool isSubscription,
    required bool isConsumable,
    DateTime? subscriptionExpiry,
    String? purchaseId,
    String? purchaseToken,
    String? rigId,
    String source = 'google_play',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = <String, dynamic>{
      'productId': productId,
      'googleProductId': productId,
      'category': category,
      'source': source,
      'at': now,
      if (purchaseId != null && purchaseId.isNotEmpty) 'orderId': purchaseId,
      if (purchaseToken != null && purchaseToken.isNotEmpty) 'purchaseToken': purchaseToken,
      if (rigId != null) 'rigId': rigId,
    };

    try {
      await _db.ref('$_users/$uid/$_purchases/$_googleHistory').push().set(payload);

      if (isSubscription && subscriptionExpiry != null) {
        await _db.ref('$_users/$uid/$_purchases/$_subscription').set({
          'planId': productId,
          'googleProductId': productId,
          'expiryMs': subscriptionExpiry.millisecondsSinceEpoch,
          'source': source,
          if (purchaseId != null) 'orderId': purchaseId,
          if (purchaseToken != null) 'purchaseToken': purchaseToken,
        });
        return;
      }

      if (isConsumable && category == 'farm_rig') {
        await _db.ref('$_users/$uid/$_purchases/$_farmRigs').push().set(payload);
      }

      if (!isConsumable || category == 'one_time') {
        await _db.ref('$_users/$uid/$_purchases/$_oneTime/$productId').set({
          'at': now,
          'googleProductId': productId,
          'source': source,
          if (purchaseId != null) 'lastOrderId': purchaseId,
        });
      }
    } catch (_) {
      rethrow;
    }
  }

  /// Record subscription (planId + expiry timestamp ms).
  Future<void> recordSubscription(String uid, String planId, DateTime expiry) async {
    try {
      await _db.ref('$_users/$uid/$_purchases/$_subscription').set({
        'planId': planId,
        'googleProductId': planId,
        'expiryMs': expiry.millisecondsSinceEpoch,
        'source': 'google_play',
      });
    } catch (_) {
      rethrow;
    }
  }

  /// Check if user has purchased one-time product.
  Future<bool> hasOneTimePurchase(String uid, String productId) async {
    try {
      final snap = await _db.ref('$_users/$uid/$_purchases/$_oneTime/$productId').get();
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  /// Get all one-time purchase IDs.
  Future<List<String>> getOneTimePurchases(String uid) async {
    try {
      final snap = await _db.ref('$_users/$uid/$_purchases/$_oneTime').get();
      if (!snap.exists || snap.value == null) return [];
      final map = snap.value as Map<dynamic, dynamic>;
      return map.keys.map((e) => e as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Record 2x boost expiry (e.g. 1 hour from now).
  Future<void> recordBoostExpiry(String uid, DateTime expiry) async {
    try {
      await _db.ref('$_users/$uid/$_purchases/$_boostExpiryMs').set(expiry.millisecondsSinceEpoch);
    } catch (_) {
      rethrow;
    }
  }

  /// Get boost expiry (null if none or expired).
  Future<DateTime?> getBoostExpiry(String uid) async {
    try {
      final snap = await _db.ref('$_users/$uid/$_purchases/$_boostExpiryMs').get();
      if (!snap.exists || snap.value == null) return null;
      final ms = (snap.value as num).toInt();
      final expiry = DateTime.fromMillisecondsSinceEpoch(ms);
      return expiry.isAfter(DateTime.now()) ? expiry : null;
    } catch (_) {
      return null;
    }
  }

  /// Get subscription expiry (null if none or expired).
  Future<DateTime?> getSubscriptionExpiry(String uid) async {
    try {
      final snap = await _db.ref('$_users/$uid/$_purchases/$_subscription').get();
      if (!snap.exists || snap.value == null) return null;
      final map = snap.value as Map<dynamic, dynamic>;
      final ms = (map['expiryMs'] as num?)?.toInt();
      if (ms == null) return null;
      final expiry = DateTime.fromMillisecondsSinceEpoch(ms);
      return expiry.isAfter(DateTime.now()) ? expiry : null;
    } catch (_) {
      return null;
    }
  }
}

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final double btcBalance;
  final double totalBtcPerMin;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.btcBalance,
    required this.totalBtcPerMin,
  });
}
