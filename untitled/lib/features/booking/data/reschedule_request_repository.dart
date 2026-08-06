import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/services/base_repository.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/shared/models/reschedule_request_model.dart';

final rescheduleRequestRepositoryProvider = Provider<RescheduleRequestRepository>((ref) {
  return RescheduleRequestRepository(DioClient.dio);
});

class RescheduleRequestRepository {
  RescheduleRequestRepository(this._dio);

  final Dio _dio;

  static const _cacheKeyList = 'reschedule_requests';
  static const _cacheKeyDetail = 'reschedule_request_';

  Map<String, dynamic> _extractData(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return (raw['data'] ?? raw) as Map<String, dynamic>;
    }
    return {};
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is Map<String, dynamic> && raw['data'] is List) {
      return (raw['data'] as List)
          .cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<RescheduleRequestModel>> getRescheduleRequests({int page = 1, int perPage = 20}) async {
    if (page == 1) {
      return BaseRepository.fetchList(
        request: () async {
          final response = await _dio.get('/reschedule-requests', queryParameters: {'page': page, 'per_page': perPage});
          return _extractList(response.data);
        },
        cacheKey: _cacheKeyList,
        fromJson: RescheduleRequestModel.fromJson,
        cacheDuration: CacheService.shortExpiry,
      );
    }
    final response = await _dio.get('/reschedule-requests', queryParameters: {'page': page, 'per_page': perPage});
    return _extractList(response.data).map((e) => RescheduleRequestModel.fromJson(e)).toList();
  }

  Future<RescheduleRequestModel> createRescheduleRequest(
    String bookingId, {
    required DateTime proposedDate,
    required String proposedStartTime,
    required String proposedEndTime,
    String? reason,
  }) async {
    final response = await _dio.post('/bookings/$bookingId/reschedule-requests', data: {
      'proposed_date': proposedDate.toIso8601String().split('T').first,
      'proposed_start_time': proposedStartTime,
      'proposed_end_time': proposedEndTime,
      'reason': reason,
    });
    await CacheService.remove(_cacheKeyList);
    return RescheduleRequestModel.fromJson(_extractData(response.data));
  }

  Future<RescheduleRequestModel> getRescheduleRequest(int id) async {
    return BaseRepository.fetchModel(
      request: () async {
        final response = await _dio.get('/reschedule-requests/$id');
        return _extractData(response.data);
      },
      cacheKey: '$_cacheKeyDetail$id',
      fromJson: RescheduleRequestModel.fromJson,
    );
  }

  Future<RescheduleRequestModel> acceptRescheduleRequest(int id) async {
    final response = await _dio.put('/reschedule-requests/$id/accept');
    await CacheService.remove(_cacheKeyList);
    return RescheduleRequestModel.fromJson(_extractData(response.data));
  }

  Future<RescheduleRequestModel> rejectRescheduleRequest(int id, {String? reason}) async {
    final response = await _dio.put('/reschedule-requests/$id/reject', data: {'reason': reason});
    await CacheService.remove(_cacheKeyList);
    return RescheduleRequestModel.fromJson(_extractData(response.data));
  }

  Future<RescheduleRequestModel> counterRescheduleRequest(
    int id, {
    required DateTime counterDate,
    required String counterStartTime,
    required String counterEndTime,
    String? counterReason,
  }) async {
    final response = await _dio.put('/reschedule-requests/$id/counter', data: {
      'counter_date': counterDate.toIso8601String().split('T').first,
      'counter_start_time': counterStartTime,
      'counter_end_time': counterEndTime,
      'counter_reason': counterReason,
    });
    await CacheService.remove(_cacheKeyList);
    return RescheduleRequestModel.fromJson(_extractData(response.data));
  }

  Future<void> cancelRescheduleRequest(int id) async {
    await _dio.put('/reschedule-requests/$id/cancel');
    await CacheService.remove(_cacheKeyList);
  }
}
