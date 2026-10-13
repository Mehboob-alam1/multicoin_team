import '../models/player_data.dart';
import 'supabase_bootstrap.dart';

/// Cloud backup via **Supabase**. Firebase Auth uid is the row key.
/// Local SharedPreferences remains the source of truth.
class FirebaseSyncService {
  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<void> syncPlayerData(String uid, PlayerData data, {String? displayName}) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      await client.from('players').upsert({
        'uid': uid,
        if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
        'player_data': data.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<PlayerData?> fetchPlayerData(String uid) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client.from('players').select('player_data').eq('uid', uid).maybeSingle();
      if (row == null) return null;
      final map = _asMap(row['player_data']);
      if (map == null) return null;
      return PlayerData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateLeaderboard(
    String uid, {
    required String displayName,
    required double btcBalance,
    required double totalBtcPerMin,
    int farmSize = 0,
    String region = 'all',
    String flag = '',
  }) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      await client.from('leaderboard').upsert({
        'uid': uid,
        'display_name': displayName,
        'btc_balance': btcBalance,
        'total_btc_per_min': totalBtcPerMin,
        'farm_size': farmSize,
        'region': region,
        'flag': flag,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 100}) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final rows = await client
          .from('leaderboard')
          .select()
          .order('btc_balance', ascending: false)
          .limit(limit);
      return (rows as List)
          .map((e) {
            final v = _asMap(e) ?? {};
            return LeaderboardEntry(
              uid: v['uid'] as String? ?? '',
              displayName: v['display_name'] as String? ?? 'Unknown',
              btcBalance: (v['btc_balance'] as num?)?.toDouble() ?? 0,
              totalBtcPerMin: (v['total_btc_per_min'] as num?)?.toDouble() ?? 0,
              farmSize: (v['farm_size'] as num?)?.toInt() ?? 0,
              region: v['region'] as String? ?? 'all',
              flag: v['flag'] as String? ?? '',
            );
          })
          .where((e) => e.uid.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> recordOneTimePurchase(String uid, String productId) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      await client.from('purchases').insert({
        'uid': uid,
        'product_id': productId,
        'category': 'one_time',
        'source': 'google_play',
        'is_subscription': false,
        'is_consumable': false,
      });
      await _appendOneTime(uid, productId);
    } catch (_) {}
  }

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
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
    await client.from('purchases').insert({
      'uid': uid,
      'product_id': productId,
      'category': category,
      'source': source,
      'is_subscription': isSubscription,
      'is_consumable': isConsumable,
      if (purchaseId != null && purchaseId.isNotEmpty) 'order_id': purchaseId,
      if (purchaseToken != null && purchaseToken.isNotEmpty) 'purchase_token': purchaseToken,
      if (rigId != null) 'rig_id': rigId,
      if (subscriptionExpiry != null) 'expiry_ms': subscriptionExpiry.millisecondsSinceEpoch,
    });
    if (isSubscription && subscriptionExpiry != null) {
      await client.from('players').upsert({
        'uid': uid,
        'premium_expiry_ms': subscriptionExpiry.millisecondsSinceEpoch,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return;
    }
    if (!isConsumable || category == 'one_time') {
      await _appendOneTime(uid, productId);
    }
    } catch (_) {}
  }

  Future<void> recordSubscription(String uid, String planId, DateTime expiry) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
    await client.from('players').upsert({
      'uid': uid,
      'premium_expiry_ms': expiry.millisecondsSinceEpoch,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    await client.from('purchases').insert({
      'uid': uid,
      'product_id': planId,
      'category': 'premium',
      'source': 'google_play',
      'is_subscription': true,
      'is_consumable': false,
      'expiry_ms': expiry.millisecondsSinceEpoch,
    });
    } catch (_) {}
  }

  Future<bool> hasOneTimePurchase(String uid, String productId) async {
    final ids = await getOneTimePurchases(uid);
    return ids.contains(productId);
  }

  Future<List<String>> getOneTimePurchases(String uid) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return [];
    try {
      final row = await client
          .from('players')
          .select('one_time_products')
          .eq('uid', uid)
          .maybeSingle();
      final raw = row?['one_time_products'];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      final purchases = await client
          .from('purchases')
          .select('product_id')
          .eq('uid', uid)
          .eq('is_consumable', false)
          .eq('is_subscription', false);
      return (purchases as List)
          .map((e) => (e as Map)['product_id']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> recordBoostExpiry(String uid, DateTime expiry) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      await client.from('players').upsert({
        'uid': uid,
        'boost_expiry_ms': expiry.millisecondsSinceEpoch,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<DateTime?> getBoostExpiry(String uid) async {
    return _msToFutureDate(uid, 'boost_expiry_ms');
  }

  Future<DateTime?> getSubscriptionExpiry(String uid) async {
    return _msToFutureDate(uid, 'premium_expiry_ms');
  }

  Future<DateTime?> _msToFutureDate(String uid, String column) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return null;
    try {
      final row = await client.from('players').select(column).eq('uid', uid).maybeSingle();
      final ms = (row?[column] as num?)?.toInt();
      if (ms == null) return null;
      final expiry = DateTime.fromMillisecondsSinceEpoch(ms);
      return expiry.isAfter(DateTime.now()) ? expiry : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _appendOneTime(String uid, String productId) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    try {
      final existing = await getOneTimePurchases(uid);
      if (existing.contains(productId)) return;
      await client.from('players').upsert({
        'uid': uid,
        'one_time_products': [...existing, productId],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }
}

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final double btcBalance;
  final double totalBtcPerMin;
  final int farmSize;
  final String region;
  final String flag;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.btcBalance,
    required this.totalBtcPerMin,
    this.farmSize = 0,
    this.region = 'all',
    this.flag = '',
  });
}
