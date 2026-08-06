import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/base_repository.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/shared/models/user_model.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(DioClient.dio);
});

final favoriteSittersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(favoriteRepositoryProvider).getFavorites();
});

class FavoriteRepository {
  FavoriteRepository(this._dio);

  final Dio _dio;

  static const _cacheKey = 'favorites';

  Future<List<UserModel>> getFavorites() async {
    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get('/favorites');
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        if (data is! List) return [];
        return data.whereType<Map<String, dynamic>>().toList();
      },
      cacheKey: _cacheKey,
      fromJson: UserModel.fromJson,
      cacheDuration: CacheService.shortExpiry,
    );
  }

  Future<void> saveFavorite(String sitterId) async {
    try {
      await _dio.post('/favorites/$sitterId');
      await CacheService.remove(_cacheKey);
      await CacheService.remove('sitter_$sitterId');
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> removeFavorite(String sitterId) async {
    try {
      await _dio.delete('/favorites/$sitterId');
      await CacheService.remove(_cacheKey);
      await CacheService.remove('sitter_$sitterId');
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }
}
