import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/features/support/data/contact_setting_repository.dart';
import 'package:babysitter/shared/models/contact_setting_model.dart';

enum ContactSettingStatus { initial, loading, error, success }

class ContactSettingState {
  final ContactSettingStatus status;
  final ContactSettingModel? settings;
  final String? error;

  const ContactSettingState({
    this.status = ContactSettingStatus.initial,
    this.settings,
    this.error,
  });

  ContactSettingState copyWith({
    ContactSettingStatus? status,
    ContactSettingModel? settings,
    String? error,
  }) {
    return ContactSettingState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      error: error,
    );
  }
}

class ContactSettingNotifier extends StateNotifier<ContactSettingState> {
  final ContactSettingRepository _repository;

  ContactSettingNotifier(this._repository) : super(const ContactSettingState());

  Future<void> load() async {
    state = state.copyWith(status: ContactSettingStatus.loading, error: null);
    try {
      final settings = await _repository.getContactSettings(
        forceRefresh: true,
      );
      state = ContactSettingState(
        status: ContactSettingStatus.success,
        settings: settings,
      );
    } catch (e) {
      state = ContactSettingState(
        status: ContactSettingStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final settings = await _repository.getContactSettings(
        forceRefresh: true,
      );
      state = ContactSettingState(
        status: ContactSettingStatus.success,
        settings: settings,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final contactSettingProvider =
    StateNotifierProvider<ContactSettingNotifier, ContactSettingState>((ref) {
  return ContactSettingNotifier(
    ref.watch(contactSettingRepositoryProvider),
  );
});
