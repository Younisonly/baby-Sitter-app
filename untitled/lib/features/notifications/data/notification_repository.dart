import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/api_response.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/shared/models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(DioClient.dio);
});

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  static const _cacheKey = 'notifications';

  Future<PaginatedList<NotificationModel>> getNotifications({
    int page = 1,
    int perPage = 20,
    String? filter,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (filter != null && filter != 'all') params['filter'] = filter;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _dio.get('/notifications', queryParameters: params);
      final responseMap = response.data as Map<String, dynamic>? ?? {};
      final data = responseMap['data'];
      final items = data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(NotificationModel.fromJson)
              .toList()
          : <NotificationModel>[];
      final pagination = PaginationInfo.fromLaravelMeta(
        responseMap['meta'] as Map<String, dynamic>? ?? {},
      );

      if (page == 1) {
        await CacheService.set(_cacheKey, {
          'items': items.map((e) => e.toJson()).toList(),
          'pagination': {
            'current_page': pagination.currentPage,
            'last_page': pagination.lastPage,
            'per_page': pagination.perPage,
            'totalItems': pagination.totalItems,
          },
        }, expiry: CacheService.shortExpiry);
      }

      return PaginatedList(items: items, pagination: pagination);
    } catch (error) {
      if (page == 1) {
        final cached = CacheService.get(_cacheKey);
        if (cached is Map<String, dynamic>) {
          final items = (cached['items'] as List)
              .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList();
          final pag = cached['pagination'] as Map<String, dynamic>;
          return PaginatedList(
            items: items,
            pagination: PaginationInfo(
              currentPage: pag['current_page'] as int? ?? 1,
              lastPage: pag['last_page'] as int? ?? 1,
              perPage: pag['per_page'] as int? ?? 20,
              totalItems: pag['totalItems'] as int? ?? items.length,
            ),
          );
        }
      }
      throw ErrorHandler.handle(error);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      final data = response.data as Map<String, dynamic>? ?? {};
      return (data['data']?['count'] as int?) ?? 0;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> markMultipleAsRead(List<String> ids) async {
    try {
      await _dio.patch('/notifications/read-multiple', data: {
        'ids': ids.map((e) => int.tryParse(e) ?? 0).toList(),
      });
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete('/notifications/$id');
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> deleteMultiple(List<String> ids) async {
    try {
      await _dio.delete('/notifications/delete-multiple', data: {
        'ids': ids.map((e) => int.tryParse(e) ?? 0).toList(),
      });
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }
}
