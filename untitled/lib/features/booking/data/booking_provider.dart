import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/features/booking/data/booking_repository.dart';
import 'package:babysitter/features/booking/data/session_repository.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/shared/models/booking_model.dart';
enum BookingsTab { pending, confirmed, inProgress, completed, cancelled, rejected }

const customerBookingsTabs = [
  BookingsTab.pending,
  BookingsTab.confirmed,
  BookingsTab.inProgress,
  BookingsTab.completed,
  BookingsTab.cancelled,
];

const sitterBookingsTabs = [
  BookingsTab.pending,
  BookingsTab.confirmed,
  BookingsTab.inProgress,
  BookingsTab.completed,
  BookingsTab.cancelled,
  BookingsTab.rejected,
];

class TabBookingsState {
  final List<BookingModel> bookings;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final String? error;
  final bool hasLoaded;

  const TabBookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalCount = 0,
    this.error,
    this.hasLoaded = false,
  });

  List<BookingGroupDisplayItem> get groupedBookings => groupBookings(bookings);

  TabBookingsState copyWith({
    List<BookingModel>? bookings,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    String? error,
    bool? hasLoaded,
  }) {
    return TabBookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class TabBookingsNotifier extends StateNotifier<TabBookingsState> {
  final BookingRepository _repository;
  final BookingsTab _tab;
  final String _role;

  TabBookingsNotifier(this._repository, this._tab, {String role = 'customer'})
      : _role = role,
        super(const TabBookingsState());

  String get _statusFilter => _tab.name;
  String get _apiStatusFilter => 
      _tab == BookingsTab.inProgress ? 'in_progress' : _tab.name;

  Future<void> loadTab() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getBookingsPaginated(page: 1, status: _apiStatusFilter, role: _role);
      state = TabBookingsState(
        bookings: result.items,
        hasMore: result.pagination.hasMore,
        currentPage: result.pagination.currentPage,
        totalCount: result.pagination.total,
        hasLoaded: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHandler.handle(e).message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getBookingsPaginated(page: state.currentPage + 1, status: _apiStatusFilter, role: _role);
      state = state.copyWith(
        bookings: [...state.bookings, ...result.items],
        isLoadingMore: false,
        hasMore: result.pagination.hasMore,
        currentPage: result.pagination.currentPage,
        totalCount: result.pagination.total,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void updateBooking(BookingModel updated) {
    final exists = state.bookings.any((b) => b.id == updated.id);
    final matchesTab = (updated.status.name == _statusFilter);

    if (exists && !matchesTab) {
      state = state.copyWith(
        bookings: [...state.bookings.where((b) => b.id != updated.id)],
        totalCount: (state.totalCount - 1).clamp(0, double.infinity).toInt(),
      );
    } else if (!exists && matchesTab) {
      state = state.copyWith(
        bookings: [updated, ...state.bookings],
        totalCount: state.totalCount + 1,
      );
    } else if (exists && matchesTab) {
      state = state.copyWith(
        bookings: [...state.bookings.map((b) => b.id == updated.id ? updated : b)],
      );
    }

    if (updated.bookingGroupId != null && !matchesTab) {
      final siblings = state.bookings
          .where((b) => b.bookingGroupId == updated.bookingGroupId && b.id != updated.id)
          .toList();
      if (siblings.isNotEmpty) {
        final siblingIds = siblings.map((b) => b.id).toSet();
        state = state.copyWith(
          bookings: [...state.bookings.where((b) => !siblingIds.contains(b.id))],
          totalCount: (state.totalCount - siblingIds.length).clamp(0, double.infinity).toInt(),
        );
      }
    }
  }

  void refreshTab() {
    loadTab();
  }
}

final pendingBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.pending);
});

final confirmedBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.confirmed);
});

final inProgressBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.inProgress);
});

final completedBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.completed);
});

final cancelledBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.cancelled);
});

final sitterPendingBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.pending, role: 'sitter');
});

final sitterConfirmedBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.confirmed, role: 'sitter');
});

final sitterInProgressBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.inProgress, role: 'sitter');
});

final sitterCompletedBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.completed, role: 'sitter');
});

final sitterCancelledBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.cancelled, role: 'sitter');
});

final sitterRejectedBookingsProvider =
    StateNotifierProvider<TabBookingsNotifier, TabBookingsState>((ref) {
  return TabBookingsNotifier(ref.read(bookingRepositoryProvider), BookingsTab.rejected, role: 'sitter');
});

final bookingsRefreshProvider = StateProvider<int>((ref) => 0);

final bookingActionProvider =
    Provider<Future<void> Function(String bookingId, Future<BookingModel> Function() action)>((ref) {
  return (bookingId, action) async {
    try {
      final updated = await action();
      for (final provider in [
        pendingBookingsProvider,
        confirmedBookingsProvider,
        inProgressBookingsProvider,
        completedBookingsProvider,
        cancelledBookingsProvider,
        sitterPendingBookingsProvider,
        sitterConfirmedBookingsProvider,
        sitterInProgressBookingsProvider,
        sitterCompletedBookingsProvider,
        sitterCancelledBookingsProvider,
        sitterRejectedBookingsProvider,
      ]) {
        ref.read(provider.notifier).updateBooking(updated);
      }
      ref.invalidate(bookingDetailProvider(bookingId));
      ref.invalidate(activeSessionProvider);
      ref.read(bookingsRefreshProvider.notifier).state++;
    } catch (e) {
      rethrow;
    }
  };
});

final bookingDetailProvider = FutureProvider.family<BookingModel, String>((ref, id) async {
  return ref.read(bookingRepositoryProvider).getBooking(id);
});

final bookingTimelineProvider = FutureProvider.family<List<TimelineEvent>, String>((ref, id) async {
  return ref.read(bookingRepositoryProvider).getTimeline(id);
});

final bookingGroupProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, groupId) async {
  return ref.read(bookingRepositoryProvider).getBookingGroup(groupId);
});

final pendingSessionSnackProvider = StateProvider<String?>((ref) => null);

final lastLocationRefreshProvider = StateProvider.family<DateTime?, String>(
  (ref, bookingId) => null,
);

final latestTrackingProvider = FutureProvider.family<LocationPoint?, String>((ref, bookingId) async {
  final repo = ref.read(sessionRepositoryProvider);
  final data = await repo.getTracking(bookingId, limit: 1);
  return data.tracking.isNotEmpty ? data.tracking.first : data.latest;
});

final activeSessionProvider = FutureProvider.autoDispose<BookingModel?>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return null;
  return ref.read(sessionRepositoryProvider).getActiveSession();
});
