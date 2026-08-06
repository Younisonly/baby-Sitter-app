import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/features/sitter_management/data/sitter_management_repository.dart';
import 'package:babysitter/shared/models/dashboard_stats_model.dart';

final sitterManagementRepositoryProvider = Provider<SitterManagementRepository>((ref) {
  return SitterManagementRepository(DioClient.dio);
});

final sitterStatsProvider = FutureProvider<SitterStats>((ref) async {
  final data = await ref.read(sitterManagementRepositoryProvider).fetchStats();
  return SitterStats.fromStats(DashboardStatsModel.fromJson(data));
});

final sitterRecentBookingsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(sitterManagementRepositoryProvider).fetchRecentBookings();
});

class SitterStats {
  final int totalBookings;
  final int completedBookings;
  final double totalEarnings;
  final double rating;
  final int reviewCount;
  final int pendingRequests;
  final int confirmedCount;
  final bool isAvailable;
  final double acceptanceRate;

  const SitterStats({
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.totalEarnings = 0.0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.pendingRequests = 0,
    this.confirmedCount = 0,
    this.isAvailable = false,
    this.acceptanceRate = 0.0,
  });

  factory SitterStats.fromStats(DashboardStatsModel stats) {
    return SitterStats(
      totalBookings: stats.totalBookings,
      completedBookings: stats.completedBookings,
      totalEarnings: stats.totalEarnings.toDouble(),
      rating: stats.rating,
      reviewCount: stats.reviewCount,
      pendingRequests: stats.pendingRequests,
      confirmedCount: stats.confirmedCount,
      isAvailable: stats.isAvailable,
      acceptanceRate: stats.acceptanceRate,
    );
  }
}
