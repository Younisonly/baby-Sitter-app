import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats_model.freezed.dart';
part 'dashboard_stats_model.g.dart';

@freezed
class DashboardStatsModel with _$DashboardStatsModel {
  const factory DashboardStatsModel({
    @Default(0) int totalBookings,
    @Default(0) int completedBookings,
    @Default(0) int cancelledBookings,
    @Default(0) int totalEarnings,
    @Default(0) int baseEarnings,
    @Default(0) int extraEarnings,
    @Default(0) int specialNeedsEarnings,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default(false) bool isAvailable,
    @Default(0) int pendingRequests,
    @Default(0) int confirmedCount,
    @Default(0) int rejectedCount,
    @Default(0.0) double acceptanceRate,
    @Default(null) int? avgResponseTime,
    @Default(0) int viewCount,
    @Default(0) int followerCount,
  }) = _DashboardStatsModel;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsModelFromJson(json);
}

@freezed
class MonthlyTrend with _$MonthlyTrend {
  const factory MonthlyTrend({
    required String month,
    @Default(0) int bookings,
    @Default(0) int completed,
    @Default(0) int cancelled,
    @Default(0) int rejected,
    @Default(0) int revenue,
  }) = _MonthlyTrend;

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) =>
      _$MonthlyTrendFromJson(json);
}
