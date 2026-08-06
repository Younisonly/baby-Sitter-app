import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/services/base_repository.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/shared/models/city_model.dart';
import 'package:babysitter/shared/models/service_category_model.dart';
import 'package:babysitter/shared/models/special_skill_model.dart';
import 'package:babysitter/features/home/data/models/platform_statistic_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(DioClient.dio);
});

final serviceCategoriesProvider =
    FutureProvider<List<ServiceCategoryModel>>((ref) async {
  return ref.read(homeRepositoryProvider).getCategories();
});

final citiesProvider = FutureProvider<List<CityModel>>((ref) async {
  return ref.read(homeRepositoryProvider).getCities();
});

final specialSkillsProvider =
    FutureProvider<List<SpecialSkillModel>>((ref) async {
  return ref.read(homeRepositoryProvider).getSpecialSkills();
});

final platformStatisticsProvider =
    FutureProvider<List<PlatformStatisticModel>>((ref) async {
  return ref.read(homeRepositoryProvider).getPlatformStatistics();
});

class HomeRepository {
  HomeRepository(this._dio);

  final Dio _dio;

  static const _cacheKeyCategories = 'categories';
  static const _cacheKeyCities = 'cities';
  static const _cacheKeySkills = 'special_skills';
  static const _cacheKeyPlatformStats = 'platform_statistics';

  Future<List<ServiceCategoryModel>> getCategories() async {
    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get('/categories');
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        if (data is! List) return [];
        return data.whereType<Map<String, dynamic>>().toList();
      },
      cacheKey: _cacheKeyCategories,
      fromJson: ServiceCategoryModel.fromJson,
      cacheDuration: CacheService.longExpiry,
    );
  }

  Future<List<CityModel>> getCities() async {
    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get('/cities');
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        if (data is! List) return [];
        return data.whereType<Map<String, dynamic>>().toList();
      },
      cacheKey: _cacheKeyCities,
      fromJson: CityModel.fromJson,
      cacheDuration: CacheService.longExpiry,
    );
  }

  Future<List<SpecialSkillModel>> getSpecialSkills() async {
    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get('/special-skills');
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        if (data is! List) return [];
        return data.whereType<Map<String, dynamic>>().toList();
      },
      cacheKey: _cacheKeySkills,
      fromJson: SpecialSkillModel.fromJson,
      cacheDuration: CacheService.longExpiry,
    );
  }

  Future<List<PlatformStatisticModel>> getPlatformStatistics() async {
    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get('/platform-statistics');
        final data = response.data is Map<String, dynamic>
            ? (response.data as Map<String, dynamic>)['data']
            : response.data;
        if (data is! List) return [];
        return data.whereType<Map<String, dynamic>>().toList();
      },
      cacheKey: _cacheKeyPlatformStats,
      fromJson: PlatformStatisticModel.fromJson,
      cacheDuration: CacheService.longExpiry,
    );
  }
}
