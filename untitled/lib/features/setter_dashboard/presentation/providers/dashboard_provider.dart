import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/models/dashboard_stats_model.dart';
import 'package:babysitter/features/setter_dashboard/data/dashboard_repository.dart';

class DashboardState {
  final DashboardStatsModel? stats;
  final List<BookingModel> recentRequests;
  final List<MonthlyTrend> trends;
  final bool isLoading;
  final String? error;
  final bool isTogglingAvailability;

  const DashboardState({
    this.stats,
    this.recentRequests = const [],
    this.trends = const [],
    this.isLoading = false,
    this.error,
    this.isTogglingAvailability = false,
  });

  DashboardState copyWith({
    DashboardStatsModel? stats,
    List<BookingModel>? recentRequests,
    List<MonthlyTrend>? trends,
    bool? isLoading,
    String? error,
    bool? isTogglingAvailability,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      recentRequests: recentRequests ?? this.recentRequests,
      trends: trends ?? this.trends,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTogglingAvailability:
          isTogglingAvailability ?? this.isTogglingAvailability,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(const DashboardState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    DashboardStatsModel? stats;
    List<BookingModel> requests = [];
    List<MonthlyTrend> trends = [];

    try {
      stats = await _repository.getStats();
    } catch (_) {}

    try {
      requests = await _repository.getRecentRequests();
    } catch (_) {}

    try {
      trends = await _repository.getTrends();
    } catch (_) {}

    if (stats != null) {
      state = DashboardState(
        stats: stats,
        recentRequests: requests,
        trends: trends,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard.',
      );
    }
  }

  Future<void> toggleAvailability() async {
    if (state.stats == null) return;
    state = state.copyWith(isTogglingAvailability: true);

    try {
      final newAvailability = await _repository.toggleAvailability();
      state = state.copyWith(
        stats: state.stats!.copyWith(isAvailable: newAvailability),
        isTogglingAvailability: false,
      );
    } catch (e) {
      state = state.copyWith(isTogglingAvailability: false);
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.read(dashboardRepositoryProvider));
});
