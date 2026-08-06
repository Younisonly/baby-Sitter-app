import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/features/faq/data/faq_repository.dart';
import 'package:babysitter/shared/models/faq_model.dart';

enum FaqStateStatus { initial, loading, error, success }

class FaqState {
  final FaqStateStatus status;
  final List<FaqModel> faqs;
  final String? error;

  const FaqState({
    this.status = FaqStateStatus.initial,
    this.faqs = const [],
    this.error,
  });

  FaqState copyWith({
    FaqStateStatus? status,
    List<FaqModel>? faqs,
    String? error,
  }) {
    return FaqState(
      status: status ?? this.status,
      faqs: faqs ?? this.faqs,
      error: error,
    );
  }
}

class FaqNotifier extends StateNotifier<FaqState> {
  final FaqRepository _repository;

  FaqNotifier(this._repository) : super(const FaqState());

  Future<void> load() async {
    state = state.copyWith(status: FaqStateStatus.loading, error: null);
    try {
      final faqs = await _repository.getFaqs(forceRefresh: true);
      state = FaqState(status: FaqStateStatus.success, faqs: faqs);
    } catch (e) {
      state = FaqState(
        status: FaqStateStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final faqs = await _repository.getFaqs(forceRefresh: true);
      state = FaqState(status: FaqStateStatus.success, faqs: faqs);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }
}

final faqProvider = StateNotifierProvider<FaqNotifier, FaqState>((ref) {
  return FaqNotifier(ref.watch(faqRepositoryProvider));
});
