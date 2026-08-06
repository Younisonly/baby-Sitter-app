import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/features/notifications/data/notification_settings_repository.dart';
import 'package:babysitter/shared/models/notification_settings_model.dart';

class NotificationSettingsState {
  final NotificationSettingsModel settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const NotificationSettingsState({
    this.settings = const NotificationSettingsModel(),
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  NotificationSettingsState copyWith({
    NotificationSettingsModel? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return NotificationSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  final NotificationSettingsRepository _repository;

  NotificationSettingsNotifier(this._repository)
      : super(const NotificationSettingsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final settings = await _repository.getSettings();
      state = NotificationSettingsState(settings: settings);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<void> updateSettings(Map<String, dynamic> updates) async {
    state = state.copyWith(isSaving: true, error: null);

    try {
      final settings = await _repository.updateSettings(updates);
      state = NotificationSettingsState(settings: settings);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<void> toggleCategory(String key, bool value) async {
    await updateSettings({key: value});
  }

  Future<void> registerDeviceToken(String token) async {
    try {
      await _repository.registerDevice(
        deviceToken: token,
        platform: 'android',
        appVersion: null,
        osVersion: null,
        deviceName: null,
      );
    } catch (_) {}
  }

  Future<void> unregisterDevice(String token) async {
    try {
      await _repository.unregisterDevice(token);
    } catch (_) {}
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier,
        NotificationSettingsState>((ref) {
  return NotificationSettingsNotifier(
    ref.read(notificationSettingsRepositoryProvider),
  );
});
