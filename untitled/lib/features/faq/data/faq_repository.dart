import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/shared/models/faq_model.dart';

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  return FaqRepository();
});

class FaqRepository {
  static const _cacheKey = 'faqs';

  Future<List<FaqModel>> getFaqs({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = CacheService.get(_cacheKey);
      if (cached != null) {
        return (cached as List)
            .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    try {
      final response = await DioClient.dio.get('/faqs');
      final data = response.data['data'] as List;
      final faqs = data
          .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
          .toList();
      await CacheService.set(_cacheKey, data);
      return faqs;
    } catch (e) {
      final cached = CacheService.get(_cacheKey);
      if (cached != null) {
        return (cached as List)
            .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw ErrorHandler.handle(e);
    }
  }
}
