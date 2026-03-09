import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

/// Limited-time mining events (Crypto Boom, GPU Efficiency, Mining Rush).
/// Event type and multiplier come from Firestore weekly_events/active or cache.
class EventService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  static const _cacheKey = 'weekly_events_cache';

  /// Event type ids for UI/analytics: crypto_boom, gpu_efficiency, mining_rush.
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
  static const _cacheMaxAge = Duration(hours: 6);

  /// Refresh from Firestore only if cache is older than [_cacheMaxAge] to reduce Firebase reads.
  Future<void> refreshFromFirebaseIfNeeded() async {
    final lastMs = LocalFeatureStore.get(_lastRefreshKey);
    final last = lastMs is int ? lastMs as int? : null;
    if (last != null && DateTime.now().millisecondsSinceEpoch - last < _cacheMaxAge.inMilliseconds) {
      return;
    }
    await refreshFromFirebase();
  }

  Future<void> refreshFromFirebase() async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await _firestore.collection('weekly_events').doc('active').get();
      if (snap.exists) {
        final d = snap.data() ?? {};
        _activeEventType = d['type']?.toString();
        _miningMultiplier = (d['miningMultiplier'] as num?)?.toDouble() ?? 1.0;
        _rigDiscount = (d['rigDiscount'] as num?)?.toDouble() ?? 0.0;
        await LocalFeatureStore.set(_cacheKey, {
          'type': _activeEventType,
          'miningMultiplier': _miningMultiplier,
          'rigDiscount': _rigDiscount,
        });
        await LocalFeatureStore.set(_lastRefreshKey, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }
}

