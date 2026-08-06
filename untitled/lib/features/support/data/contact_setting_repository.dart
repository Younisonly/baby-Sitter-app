import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/shared/models/contact_setting_model.dart';

final contactSettingRepositoryProvider =
    Provider<ContactSettingRepository>((ref) {
  return ContactSettingRepository();
});

class ContactSettingRepository {
  static const _cacheKey = 'contact_settings';

  Future<ContactSettingModel?> getContactSettings(
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = CacheService.get(_cacheKey);
      if (cached != null) {
        return ContactSettingModel.fromJson(cached as Map<String, dynamic>);
      }
    }

    try {
      final response = await DioClient.dio.get('/contact-settings');
      final data = response.data['data'] as Map<String, dynamic>;
      final settings = ContactSettingModel.fromJson(data);
      await CacheService.set(_cacheKey, data);
      return settings;
    } catch (e) {
      final cached = CacheService.get(_cacheKey);
      if (cached != null) {
        return ContactSettingModel.fromJson(cached as Map<String, dynamic>);
      }
      throw ErrorHandler.handle(e);
    }
  }
}
