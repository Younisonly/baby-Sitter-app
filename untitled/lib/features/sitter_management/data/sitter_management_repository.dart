import 'package:dio/dio.dart';
import 'package:babysitter/core/services/base_repository.dart';
import 'package:babysitter/core/services/cache_service.dart';

class SitterManagementRepository {
  final Dio _dio;
  SitterManagementRepository(this._dio);

  static const _cacheKeyStats = 'sitter_mgmt_stats';
  static const _cacheKeyBookings = 'sitter_mgmt_bookings';
  static const _cacheKeyEarnings = 'sitter_mgmt_earnings';

  Future<Map<String, dynamic>> fetchStats() async {
    return BaseRepository.fetchMap(
      request: () async {
        final response = await _dio.get('/dashboard/stats');
        return response.data['data'] ?? {};
      },
      cacheKey: _cacheKeyStats,
    );
  }

  Future<List<dynamic>> fetchRecentBookings() async {
    try {
      final response = await _dio.get('/dashboard/recent-requests');
      final data = response.data['data'] ?? [];
      await CacheService.set(_cacheKeyBookings, data, expiry: CacheService.defaultExpiry);
      return data as List;
    } catch (e) {
      final cached = CacheService.get(_cacheKeyBookings);
      if (cached is List) return cached;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchEarnings({int year = 2026}) async {
    return BaseRepository.fetchMap(
      request: () async {
        final response = await _dio.get('/dashboard/earnings-breakdown');
        return response.data['data'] ?? {};
      },
      cacheKey: _cacheKeyEarnings,
    );
  }

  Future<bool> toggleAvailability() async {
    final response = await _dio.patch('/dashboard/availability');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    await CacheService.remove(_cacheKeyStats);
    return data['isAvailable'] as bool? ?? false;
  }
}
