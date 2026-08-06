import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:babysitter/core/storage/local_storage.dart';

class CacheService {
  CacheService._();

  static const String _boxName = 'cache';
  static const String _versionKey = '_cache_version';
  static const int _currentVersion = 2;
  static const Duration defaultExpiry = Duration(minutes: 30);
  static const Duration shortExpiry = Duration(minutes: 5);
  static const Duration longExpiry = Duration(hours: 2);

  static Box? get _box => _cacheBox;
  static Box? _cacheBox;

  static Future<void> init() async {
    _cacheBox = await Hive.openBox(_boxName);
    final storedVersion = _cacheBox?.get(_versionKey) as int?;
    if (storedVersion != _currentVersion) {
      await _cacheBox?.clear();
      await _cacheBox?.put(_versionKey, _currentVersion);
    }
  }

  static Future<void> set(
    String key,
    dynamic data, {
    Duration expiry = defaultExpiry,
  }) async {
    final cacheData = {
      'data': data,
      'expiresAt': DateTime.now().add(expiry).millisecondsSinceEpoch,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _box?.put(key, jsonEncode(cacheData));
  }

  static dynamic get(String key) {
    final raw = _box?.get(key);
    if (raw == null) return null;

    try {
      final cacheData = jsonDecode(raw as String) as Map<String, dynamic>;
      final expiresAt = cacheData['expiresAt'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        _box?.delete(key);
        return null;
      }
      return cacheData['data'];
    } catch (_) {
      _box?.delete(key);
      return null;
    }
  }

  static bool isCached(String key) {
    return get(key) != null;
  }

  static Future<void> remove(String key) async {
    await _box?.delete(key);
  }

  static Future<void> clear() async {
    await _box?.clear();
  }

  static int? getCachedAt(String key) {
    final raw = _box?.get(key);
    if (raw == null) return null;
    try {
      final cacheData = jsonDecode(raw as String) as Map<String, dynamic>;
      return cacheData['cachedAt'] as int?;
    } catch (_) {
      return null;
    }
  }

  static bool isExpired(String key) {
    final raw = _box?.get(key);
    if (raw == null) return true;
    try {
      final cacheData = jsonDecode(raw as String) as Map<String, dynamic>;
      final expiresAt = cacheData['expiresAt'] as int;
      return DateTime.now().millisecondsSinceEpoch > expiresAt;
    } catch (_) {
      return true;
    }
  }
}

extension CacheStorageExtension on LocalStorage {
  static Future<void> cacheData(String key, dynamic value) =>
      CacheService.set(key, value);

  static dynamic getCachedData(String key) => CacheService.get(key);

  static Future<void> removeCachedData(String key) =>
      CacheService.remove(key);

  static Future<void> clearCache() => CacheService.clear();
}
