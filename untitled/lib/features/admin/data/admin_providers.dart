import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/features/admin/data/admin_repository.dart';
import 'package:babysitter/shared/models/user_model.dart';

class PendingSittersState {
  final List<UserModel> sitters;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const PendingSittersState({
    this.sitters = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  PendingSittersState copyWith({
    List<UserModel>? sitters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PendingSittersState(
      sitters: sitters ?? this.sitters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class PendingSittersNotifier extends StateNotifier<PendingSittersState> {
  final AdminRepository _repository;

  PendingSittersNotifier(this._repository) : super(const PendingSittersState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getPendingSitters(page: 1);
      state = PendingSittersState(
        sitters: result.items,
        hasMore: result.pagination.hasMore,
        currentPage: result.pagination.currentPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    try {
      final result = await _repository.getPendingSitters(page: nextPage);
      state = state.copyWith(
        sitters: [...state.sitters, ...result.items],
        isLoadingMore: false,
        hasMore: result.pagination.hasMore,
        currentPage: result.pagination.currentPage,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void refresh() {
    state = const PendingSittersState();
    load();
  }
}

final pendingSittersProvider =
    StateNotifierProvider<PendingSittersNotifier, PendingSittersState>((ref) {
  return PendingSittersNotifier(ref.read(adminRepositoryProvider));
});
