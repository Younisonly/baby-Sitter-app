import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/base_repository.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/models/dashboard_stats_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(DioClient.dio);
});

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  static const _cacheKeyStats = 'dashboard_stats';
  static const _cacheKeyRequests = 'dashboard_recent_requests';
  static const _cacheKeyTrends = 'dashboard_trends';
  static const _cacheKeyEarnings = 'dashboard_earnings';

  Future<DashboardStatsModel> getStats() async {
    return BaseRepository.fetchModel(
      request: () async {
        final response = await _dio.get('/dashboard/stats');
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        return data as Map<String, dynamic>;
      },
      cacheKey: _cacheKeyStats,
      fromJson: DashboardStatsModel.fromJson,
    );
  }

  Future<List<BookingModel>> getRecentRequests() async {
    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get('/dashboard/recent-requests');
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        if (data is! List) return [];
        return data.whereType<Map<String, dynamic>>().toList();
      },
      cacheKey: _cacheKeyRequests,
      fromJson: BookingModel.fromJson,
    );
  }

  Future<List<MonthlyTrend>> getTrends({int months = 12}) async {
    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get('/dashboard/analytics/trends', queryParameters: {
          'months': months,
        });
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        final monthlyData = data['monthlyData'] as List? ?? [];
        return monthlyData.whereType<Map<String, dynamic>>().toList();
      },
      cacheKey: _cacheKeyTrends,
      fromJson: MonthlyTrend.fromJson,
    );
  }

  Future<bool> toggleAvailability() async {
    try {
      final response = await _dio.patch('/dashboard/availability');
      final data = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['data']
          : response.data;
      final available = data['is_available'] as bool;
      await CacheService.remove(_cacheKeyStats);
      return available;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<Map<String, dynamic>> getEarningsBreakdown() async {
    return BaseRepository.fetchMap(
      request: () async {
        final response = await _dio.get('/dashboard/earnings-breakdown');
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        return data as Map<String, dynamic>;
      },
      cacheKey: _cacheKeyEarnings,
    );
  }
}
