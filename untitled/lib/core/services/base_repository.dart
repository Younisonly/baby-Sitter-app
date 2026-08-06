import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/cache_service.dart';

class BaseRepository {
  BaseRepository._();

  /// Fetches a single model: API first, cache fallback on network error.
  static Future<T> fetchModel<T>({
    required Future<Map<String, dynamic>> Function() request,
    required String cacheKey,
    required T Function(Map<String, dynamic>) fromJson,
    Duration cacheDuration = CacheService.defaultExpiry,
  }) async {
    try {
      final data = await request();
      await CacheService.set(cacheKey, data, expiry: cacheDuration);
      return fromJson(data);
    } catch (e) {
      final cached = CacheService.get(cacheKey);
      if (cached is Map<String, dynamic>) {
        return fromJson(cached);
      }
      throw ErrorHandler.handle(e);
    }
  }

  /// Fetches a list of models: API first, cache fallback on network error.
  static Future<List<T>> fetchList<T>({
    required Future<List<Map<String, dynamic>>> Function() request,
    required String cacheKey,
    required T Function(Map<String, dynamic>) fromJson,
    Duration cacheDuration = CacheService.defaultExpiry,
  }) async {
    try {
      final data = await request();
      await CacheService.set(cacheKey, data, expiry: cacheDuration);
      return data.map(fromJson).toList();
    } catch (e) {
      final cached = CacheService.get(cacheKey);
      if (cached is List) {
        return cached
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw ErrorHandler.handle(e);
    }
  }

  /// Fetches raw Map data: API first, cache fallback on network error.
  static Future<Map<String, dynamic>> fetchMap({
    required Future<Map<String, dynamic>> Function() request,
    required String cacheKey,
    Duration cacheDuration = CacheService.defaultExpiry,
  }) async {
    try {
      final data = await request();
      await CacheService.set(cacheKey, data, expiry: cacheDuration);
      return data;
    } catch (e) {
      final cached = CacheService.get(cacheKey);
      if (cached is Map<String, dynamic>) {
        return cached;
      }
      throw ErrorHandler.handle(e);
    }
  }

  static Future<T> safeApiCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
