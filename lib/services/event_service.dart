import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';
import 'supabase_bootstrap.dart';

/// Limited-time mining events. Cached locally; refreshed from Supabase at most daily.
class EventService extends ChangeNotifier {
  static const _cacheKey = 'weekly_events_cache';

  static const String cryptoBoom = 'crypto_boom';
  static const String gpuEfficiency = 'gpu_efficiency';
  static const String miningRush = 'mining_rush';

  bool _loading = false;
  String? _activeEventType;
  double _miningMultiplier = 1.0;
  double _rigDiscount = 0.0;

  bool get loading => _loading;
  String? get activeEventType => _activeEventType;
  double get miningMultiplier => _miningMultiplier;
  double get rigDiscount => _rigDiscount;
  bool get isCryptoBoom => _activeEventType == cryptoBoom;
  bool get isGpuEfficiency => _activeEventType == gpuEfficiency;
  bool get isMiningRush => _activeEventType == miningRush;

  Future<void> load() async {
    await LocalFeatureStore.init();
    final cache = LocalFeatureStore.get(_cacheKey);
    if (cache is Map) {
      _activeEventType = cache['type']?.toString();
      _miningMultiplier = (cache['miningMultiplier'] as num?)?.toDouble() ?? 1.0;
      _rigDiscount = (cache['rigDiscount'] as num?)?.toDouble() ?? 0.0;
    }
    notifyListeners();
  }

  static const _lastRefreshKey = 'weekly_events_last_refresh_ms';
  static const _cacheMaxAge = Duration(hours: 24);

  Future<void> refreshFromFirebaseIfNeeded() async {
    final lastMs = LocalFeatureStore.get(_lastRefreshKey);
    final last = lastMs is int ? lastMs : null;
    if (last != null &&
        DateTime.now().millisecondsSinceEpoch - last < _cacheMaxAge.inMilliseconds) {
      return;
    }
    await refreshFromFirebase();
  }

  Future<void> refreshFromFirebase() async {
    final client = SupabaseBootstrap.client;
    if (client == null) return;
    _loading = true;
    notifyListeners();
    try {
      final row = await client.from('events').select().eq('id', 'active').maybeSingle();
      if (row != null) {
        _activeEventType = row['type']?.toString();
        _miningMultiplier = (row['mining_multiplier'] as num?)?.toDouble() ?? 1.0;
        _rigDiscount = (row['rig_discount'] as num?)?.toDouble() ?? 0.0;
        await LocalFeatureStore.set(_cacheKey, {
          'type': _activeEventType,
          'miningMultiplier': _miningMultiplier,
          'rigDiscount': _rigDiscount,
        });
        await LocalFeatureStore.set(
          _lastRefreshKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }
}
