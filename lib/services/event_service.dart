import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'local_feature_store.dart';

class EventService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  static const _cacheKey = 'weekly_events_cache';

  bool _loading = false;
  String? _activeEventType;
  double _miningMultiplier = 1.0;
  double _rigDiscount = 0.0;

  bool get loading => _loading;
  String? get activeEventType => _activeEventType;
  double get miningMultiplier => _miningMultiplier;
  double get rigDiscount => _rigDiscount;

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
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }
}

