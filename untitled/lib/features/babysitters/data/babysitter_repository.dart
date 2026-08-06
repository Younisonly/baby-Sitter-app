import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/api_response.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/base_repository.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/shared/models/review_model.dart';
import 'package:babysitter/shared/models/user_model.dart';

final babysitterRepositoryProvider = Provider<BabysitterRepository>((ref) {
  return BabysitterRepository(DioClient.dio);
});

final featuredSittersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(babysitterRepositoryProvider).getSitters(
        sort: 'featured',
        perPage: 8,
      );
});

final topRatedSittersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(babysitterRepositoryProvider).getSitters(
        sort: 'top_rated',
        perPage: 6,
      );
});

final nearbySittersProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(babysitterRepositoryProvider).getSitters(
        sort: 'nearest',
        perPage: 9,
      );
});

final sitterDetailsProvider =
    FutureProvider.family<UserModel, String>((ref, id) async {
  return ref.read(babysitterRepositoryProvider).getSitter(id);
});

class BabysitterRepository {
  BabysitterRepository(this._dio);

  final Dio _dio;

  static const _cacheKeyFeatured = 'sitters_featured';
  static const _cacheKeyTopRated = 'sitters_top_rated';
  static const _cacheKeyPrefixSearch = 'sitters_search_';
  static const _cacheKeyPrefixDetail = 'sitter_';

  Future<List<UserModel>> getSitters({
    String? sort,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? city,
    bool? emergency,
    bool? overnight,
    Set<String>? skills,
    int page = 1,
    int perPage = 20,
  }) async {
    final isFeatured = sort == 'featured' && page == 1 && perPage == 8;
    final isTopRated = sort == 'top_rated' && page == 1 && perPage == 6;
    final isNearby = sort == 'nearest' && page == 1 && perPage == 9;

    String cacheKey;
    if (isFeatured) {
      cacheKey = _cacheKeyFeatured;
    } else if (isTopRated) {
      cacheKey = _cacheKeyTopRated;
    } else {
      cacheKey = '$_cacheKeyPrefixSearch${sort}_${category}_${search}_${page}_$perPage';
    }

    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get(
          '/sitters',
          queryParameters: {
            'page': page,
            'per_page': perPage,
            if (sort != null) 'sort': sort,
            if (category != null) 'category': category,
            if (search != null && search.isNotEmpty) 'search': search,
            if (minPrice != null && minPrice > 0) 'min_price': minPrice,
            if (maxPrice != null && maxPrice < 500) 'max_price': maxPrice,
            if (minRating != null && minRating > 0) 'min_rating': minRating,
            if (city != null) 'city': city,
            if (emergency == true) 'emergency': '1',
            if (overnight == true) 'overnight': '1',
            if (skills != null && skills.isNotEmpty) 'skills': skills.join(','),
          },
        );

        final items = _extractList(response.data);
        return items;
      },
      cacheKey: cacheKey,
      fromJson: UserModel.fromJson,
      cacheDuration: isFeatured || isTopRated ? CacheService.defaultExpiry : CacheService.shortExpiry,
    );
  }

  Future<PaginatedList<UserModel>> getSittersPaginated({
    String? sort,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? city,
    bool? emergency,
    bool? overnight,
    Set<String>? skills,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/sitters',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (sort != null) 'sort': sort,
          if (category != null) 'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
          if (minPrice != null && minPrice > 0) 'min_price': minPrice,
          if (maxPrice != null && maxPrice < 500) 'max_price': maxPrice,
          if (minRating != null && minRating > 0) 'min_rating': minRating,
          if (city != null) 'city': city,
          if (emergency == true) 'emergency': '1',
          if (overnight == true) 'overnight': '1',
          if (skills != null && skills.isNotEmpty) 'skills': skills.join(','),
        },
      );

      final responseMap = response.data as Map<String, dynamic>? ?? {};
      final rawItems = _extractList(responseMap);
      final pagination = PaginationInfo.fromLaravelMeta(
        responseMap['meta'] as Map<String, dynamic>? ?? {},
      );
      final items = rawItems.map(UserModel.fromJson).toList();

      if (page == 1) {
        final cacheKey = _paginationCacheKey(sort, category, search, minPrice, maxPrice, minRating, city, emergency, overnight, skills);
        await CacheService.set(cacheKey, {
          'items': rawItems,
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
        final cacheKey = _paginationCacheKey(sort, category, search, minPrice, maxPrice, minRating, city, emergency, overnight, skills);
        final cached = CacheService.get(cacheKey);
        if (cached is Map<String, dynamic>) {
          final rawCached = (cached['items'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          final cachedItems = rawCached.map(UserModel.fromJson).toList();
          final pag = cached['pagination'] as Map<String, dynamic>?;
          return PaginatedList(
            items: cachedItems,
            pagination: PaginationInfo(
              currentPage: pag?['current_page'] as int? ?? 1,
              lastPage: pag?['last_page'] as int? ?? 1,
              perPage: pag?['per_page'] as int? ?? perPage,
              totalItems: pag?['totalItems'] as int? ?? cachedItems.length,
            ),
          );
        }
      }
      throw ErrorHandler.handle(error);
    }
  }

  String _paginationCacheKey(
    String? sort,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? city,
    bool? emergency,
    bool? overnight,
    Set<String>? skills,
  ) {
    return 'sitters_p1_${sort}_${category}_${search}_${minPrice}_${maxPrice}_${minRating}_${city}_${emergency}_${overnight}_${skills?.join(",")}';
  }

  Future<UserModel> getSitter(String id) async {
    return BaseRepository.fetchModel(
      request: () async {
        final response = await _dio.get('/sitters/$id');
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final payload = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        if (payload['avatar'] is String) {
          payload['avatar'] = AppConfig.absoluteUrl(payload['avatar'] as String);
        }
        return payload;
      },
      cacheKey: '$_cacheKeyPrefixDetail$id',
      fromJson: UserModel.fromJson,
    );
  }

  Future<List<ReviewModel>> getSitterReviews(String sitterId) async {
    return BaseRepository.fetchList(
      request: () async {
        final response = await _dio.get(
          '/sitters/$sitterId/reviews',
          queryParameters: {'per_page': 20},
        );
        final items = _extractList(response.data);
        return items;
      },
      cacheKey: 'sitter_reviews_$sitterId',
      fromJson: ReviewModel.fromJson,
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    if (responseData is List) {
      return responseData.cast<Map<String, dynamic>>();
    }

    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
    }

    return const [];
  }
}
