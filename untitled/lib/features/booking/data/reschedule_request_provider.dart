import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/features/booking/data/reschedule_request_repository.dart';
import 'package:babysitter/shared/models/reschedule_request_model.dart';

class RescheduleRequestsState {
  final List<RescheduleRequestModel> requests;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const RescheduleRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  RescheduleRequestsState copyWith({
    List<RescheduleRequestModel>? requests,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return RescheduleRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

final rescheduleRequestsProvider =
    StateNotifierProvider.autoDispose<RescheduleRequestsNotifier, RescheduleRequestsState>((ref) {
  final repository = ref.read(rescheduleRequestRepositoryProvider);
  return RescheduleRequestsNotifier(repository);
});

class RescheduleRequestsNotifier extends StateNotifier<RescheduleRequestsState> {
  final RescheduleRequestRepository _repository;

  RescheduleRequestsNotifier(this._repository) : super(const RescheduleRequestsState());

  Future<void> loadRequests() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final requests = await _repository.getRescheduleRequests(page: 1);
      state = RescheduleRequestsState(requests: requests, hasMore: requests.length >= 20);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHandler.handle(e).message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final requests = await _repository.getRescheduleRequests(page: nextPage);
      state = state.copyWith(
        requests: [...state.requests, ...requests],
        isLoadingMore: false,
        hasMore: requests.length >= 20,
        currentPage: nextPage,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<RescheduleRequestModel?> createRequest({
    required String bookingId,
    required DateTime proposedDate,
    required String proposedStartTime,
    required String proposedEndTime,
    String? reason,
  }) async {
    try {
      final request = await _repository.createRescheduleRequest(
        bookingId,
        proposedDate: proposedDate,
        proposedStartTime: proposedStartTime,
        proposedEndTime: proposedEndTime,
        reason: reason,
      );
      state = state.copyWith(requests: [request, ...state.requests]);
      return request;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> acceptRequest(int id) async {
    try {
      final updated = await _repository.acceptRescheduleRequest(id);
      _replaceRequest(updated);
      return true;
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.handle(e).message);
      return false;
    }
  }

  Future<bool> rejectRequest(int id, {String? reason}) async {
    try {
      final updated = await _repository.rejectRescheduleRequest(id, reason: reason);
      _replaceRequest(updated);
      return true;
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.handle(e).message);
      return false;
    }
  }

  Future<RescheduleRequestModel?> counterRequest(
    int id, {
    required DateTime counterDate,
    required String counterStartTime,
    required String counterEndTime,
    String? counterReason,
  }) async {
    try {
      final updated = await _repository.counterRescheduleRequest(
        id,
        counterDate: counterDate,
        counterStartTime: counterStartTime,
        counterEndTime: counterEndTime,
        counterReason: counterReason,
      );
      _replaceRequest(updated);
      return updated;
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> cancelRequest(int id) async {
    try {
      await _repository.cancelRescheduleRequest(id);
      state = state.copyWith(
        requests: state.requests.where((r) => r.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: ErrorHandler.handle(e).message);
      return false;
    }
  }

  void _replaceRequest(RescheduleRequestModel updated) {
    state = state.copyWith(
      requests: state.requests.map((r) => r.id == updated.id ? updated : r).toList(),
    );
  }
}
