import 'package:hive_flutter/hive_flutter.dart';

class LocalFeatureStore {
  static const _boxName = 'feature_state';
  static Box<dynamic>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  static dynamic get(String key, [dynamic defaultValue]) {
    return _box?.get(key, defaultValue: defaultValue) ?? defaultValue;
  }

  static Future<void> set(String key, dynamic value) async {
    await _box?.put(key, value);
  }
}

