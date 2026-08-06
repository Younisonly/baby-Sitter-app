import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/shared/models/notification_settings_model.dart';

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
  return NotificationSettingsRepository(DioClient.dio);
});

class NotificationSettingsRepository {
  NotificationSettingsRepository(this._dio);

  final Dio _dio;

  Future<NotificationSettingsModel> getSettings() async {
    try {
      final response = await _dio.get('/notification-settings');
      final data = response.data as Map<String, dynamic>? ?? {};
      final settingsData = data['data'] as Map<String, dynamic>? ?? {};
      return NotificationSettingsModel.fromJson(settingsData);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<NotificationSettingsModel> updateSettings(
      Map<String, dynamic> settings) async {
    try {
      final response = await _dio.put('/notification-settings', data: settings);
      final data = response.data as Map<String, dynamic>? ?? {};
      final settingsData = data['data'] as Map<String, dynamic>? ?? {};
      return NotificationSettingsModel.fromJson(settingsData);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> registerDevice({
    required String deviceToken,
    String? platform,
    String? appVersion,
    String? osVersion,
    String? deviceName,
  }) async {
    try {
      await _dio.post('/devices', data: {
        'device_token': deviceToken,
        'platform': platform,
        'app_version': appVersion,
        'os_version': osVersion,
        'device_name': deviceName,
      });
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> unregisterDevice(String deviceToken) async {
    try {
      await _dio.delete('/devices', data: {
        'device_token': deviceToken,
      });
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }
}
