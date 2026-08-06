import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/api_response.dart';
import 'package:babysitter/core/network/error_handler.dart';

import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/shared/models/user_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(DioClient.dio);
});

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  static const _cacheKey = 'admin_pending_sitters';

  Future<PaginatedList<UserModel>> getPendingSitters({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get('/admin/sitters/pending', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      final responseMap = response.data as Map<String, dynamic>? ?? {};
      final data = responseMap['data'];
      final items = data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(UserModel.fromJson)
              .toList()
          : <UserModel>[];
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
              .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
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

  Future<String> approveSitter(String userId) async {
    try {
      final response = await _dio.put('/admin/sitters/$userId/approve');
      final data = response.data as Map<String, dynamic>? ?? {};
      await CacheService.remove(_cacheKey);
      return data['message'] as String? ?? 'Sitter approved successfully.';
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<String> rejectSitter(String userId, String reason) async {
    try {
      final response = await _dio.put(
        '/admin/sitters/$userId/reject',
        data: {'reason': reason},
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      await CacheService.remove(_cacheKey);
      return data['message'] as String? ?? 'Sitter rejected.';
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }
}
