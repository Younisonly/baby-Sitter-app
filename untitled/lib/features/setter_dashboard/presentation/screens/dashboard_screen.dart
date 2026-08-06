import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/features/setter_dashboard/presentation/providers/dashboard_provider.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(dashboardProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return Scaffold(
      appBar: AppAppBar(title: strings[AppLocalization.sitter_dashboard]),
      body: _buildBody(state, strings),
    );
  }

  Widget _buildBody(DashboardState state, Map<String, String> strings) {
    if (state.isLoading && state.stats == null) {
      return const _DashboardShimmer();
    }

    if (state.error != null && state.stats == null) {
      return ErrorState(
        title: strings[AppLocalization.something_went_wrong] ??
            'Something went wrong',
        message: state.error ?? 'Please check your connection and try again',
        onRetry: () => ref.read(dashboardProvider.notifier).load(),
      );
    }

    final stats = state.stats!;

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvailabilityToggle(
              isAvailable: stats.isAvailable,
              isToggling: state.isTogglingAvailability,
              onToggle: () =>
                  ref.read(dashboardProvider.notifier).toggleAvailability(),
              strings: strings,
            ),
            SizedBox(height: AppSpacing.md),
            _RescheduleActionCard(strings: strings),
            SizedBox(height: AppSpacing.sm),
            _AnalyticsActionCard(strings: strings),
            SizedBox(height: AppSpacing.sm),
            _EarningsActionCard(strings: strings),
            SizedBox(height: AppSpacing.sm),
            _ReviewsActionCard(strings: strings),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                StatCard(
                  label: strings[AppLocalization.total_bookings] ?? 'Total',
                  value: '${stats.totalBookings}',
                  icon: Icons.event,
                  color: AppColors.primary,
                ).expanded(),
                SizedBox(width: AppSpacing.md),
                StatCard(
                  label:
                      strings[AppLocalization.completed_bookings] ?? 'Done',
                  value: '${stats.completedBookings}',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ).expanded(),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                StatCard(
                  label:
                      strings[AppLocalization.total_earnings] ?? 'Earnings',
                  value: '﷼${stats.totalEarnings}',
                  icon: Icons.attach_money,
                  color: AppColors.accent,
                ).expanded(),
                SizedBox(width: AppSpacing.md),
                StatCard(
                  label: strings[AppLocalization.rating] ?? 'Rating',
                  value: stats.rating.toStringAsFixed(1),
                  icon: Icons.star,
                  color: AppColors.warning,
                ).expanded(),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title:
                  strings[AppLocalization.booking_requests] ?? 'Requests',
              actionText: strings[AppLocalization.see_all] ?? 'See All',
              onAction: () {},
            ),
            SizedBox(height: AppSpacing.md),
            if (state.recentRequests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text(
                    strings[AppLocalization.no_bookings] ?? 'No bookings yet',
                    style: AppTextStyles.bodyMedium(
                      color: context.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.recentRequests.length,
                separatorBuilder: (_, __) => SizedBox(
                  height: AppSpacing.md,
                ),
                itemBuilder: (_, index) => _BookingRequestCard(
                  booking: state.recentRequests[index],
                  strings: strings,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  final bool isAvailable;
  final bool isToggling;
  final VoidCallback onToggle;
  final Map<String, String> strings;

  const _AvailabilityToggle({
    required this.isAvailable,
    required this.isToggling,
    required this.onToggle,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAvailable
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
              : [
                  context.textMuted,
                  context.textMuted.withValues(alpha: 0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAvailable
                    ? (strings[AppLocalization.you_are_available] ??
                        'You are Available')
                    : (strings[AppLocalization.you_are_offline] ??
                        'You are Offline'),
                style: AppTextStyles.headlineSmall(color: AppColors.white),
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                isAvailable
                    ? (strings[AppLocalization.you_will_receive_requests] ??
                        'You will receive booking requests')
                    : (strings[AppLocalization.turn_on_to_receive] ??
                        'Turn on to receive requests'),
                style: AppTextStyles.bodyMedium(
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Switch(
            value: isAvailable,
            onChanged: isToggling ? null : (_) => onToggle(),
            activeColor: AppColors.white,
            activeTrackColor: AppColors.white.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _BookingRequestCard extends ConsumerWidget {
  final BookingModel booking;
  final Map<String, String> strings;

  const _BookingRequestCard({
    required this.booking,
    required this.strings,
  });

  String _formatDateTime(String locale) {
    final date = booking.date;
    return '${DateFormat('MMM d, yyyy', locale).format(date)} • ${TimeFormatter.formatTimeRange(booking.startTime, booking.endTime, locale)}';
  }

  String _getInitials() {
    final name = booking.customer?.name;
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _statusColor() {
    switch (booking.status) {
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
        return AppColors.success;
      case BookingStatus.completed:
        return AppColors.info;
      case BookingStatus.cancelled:
        return AppColors.error;
      case BookingStatus.rejected:
        return AppColors.error;
      case BookingStatus.expired:
        return AppColors.textMutedLight;
    }
  }

  String _statusText() {
    switch (booking.status) {
      case BookingStatus.pending:
        return strings[AppLocalization.pending] ?? 'Pending';
      case BookingStatus.confirmed:
      case BookingStatus.inProgress:
        return strings[AppLocalization.confirmed] ?? 'Confirmed';
      case BookingStatus.completed:
        return strings[AppLocalization.completed] ?? 'Completed';
      case BookingStatus.cancelled:
        return strings[AppLocalization.cancelled] ?? 'Cancelled';
      case BookingStatus.rejected:
        return strings[AppLocalization.rejected] ?? 'Rejected';
      case BookingStatus.expired:
        return strings[AppLocalization.expired] ?? 'Expired';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryUltraLight,
                child: Text(
                  _getInitials(),
                  style: AppTextStyles.titleMedium(
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customer?.name ??
                          (strings[AppLocalization.unknown] ?? 'Unknown'),
                      style: AppTextStyles.titleMedium(),
                    ),
                      Text(
                        _formatDateTime(
                            ref.watch(languageProvider).code),
                      style: AppTextStyles.bodySmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _statusText(),
                  style: AppTextStyles.labelSmall(
                    color: _statusColor(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppButton(
                text: strings[AppLocalization.decline] ?? 'Decline',
                onPressed: null,
                variant: AppButtonVariant.outlined,
              ).expanded(),
              SizedBox(width: AppSpacing.md),
              AppButton(
                text: strings[AppLocalization.accept] ?? 'Accept',
                onPressed: null,
              ).expanded(),
            ],
          ),
        ],
      ),
    );
  }
}

class _RescheduleActionCard extends StatelessWidget {
  final Map<String, String> strings;

  const _RescheduleActionCard({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.date_range, color: AppColors.accent),
        ),
        title: Text(
          strings[AppLocalization.reschedule_requests] ?? 'Reschedule Requests',
          style: AppTextStyles.titleMedium(),
        ),
        subtitle: Text(
          strings[AppLocalization.no_reschedule_requests_subtitle] ?? 'View and manage reschedule requests',
          style: AppTextStyles.bodySmall(color: context.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.rescheduleRequests),
      ),
    );
  }
}

class _AnalyticsActionCard extends StatelessWidget {
  final Map<String, String> strings;

  const _AnalyticsActionCard({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.analytics_outlined, color: AppColors.info),
        ),
        title: Text(
          strings[AppLocalization.analytics_title] ?? 'Analytics',
          style: AppTextStyles.titleMedium(),
        ),
        subtitle: Text(
          strings[AppLocalization.performance_title] ?? 'Performance metrics & trends',
          style: AppTextStyles.bodySmall(color: context.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.analytics),
      ),
    );
  }
}

class _EarningsActionCard extends StatelessWidget {
  final Map<String, String> strings;

  const _EarningsActionCard({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.success),
        ),
        title: Text(
          strings[AppLocalization.earnings_title] ?? 'Earnings',
          style: AppTextStyles.titleMedium(),
        ),
        subtitle: Text(
          strings[AppLocalization.earnings_breakdown] ?? 'View your earnings breakdown',
          style: AppTextStyles.bodySmall(color: context.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.earnings),
      ),
    );
  }
}

class _ReviewsActionCard extends StatelessWidget {
  final Map<String, String> strings;

  const _ReviewsActionCard({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.star_outline, color: AppColors.warning),
        ),
        title: Text(
          strings[AppLocalization.reviews] ?? 'Reviews',
          style: AppTextStyles.titleMedium(),
        ),
        subtitle: Text(
          strings[AppLocalization.reply_to_review] ?? 'View and reply to reviews',
          style: AppTextStyles.bodySmall(color: context.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.sitterReviews),
      ),
    );
  }
}

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight;
    final highlightColor =
        isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _shimmerBlock(context, height: 80),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _shimmerBlock(context, height: 100).expanded(),
                SizedBox(width: AppSpacing.md),
                _shimmerBlock(context, height: 100).expanded(),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _shimmerBlock(context, height: 100).expanded(),
                SizedBox(width: AppSpacing.md),
                _shimmerBlock(context, height: 100).expanded(),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            _shimmerBlock(context, height: 20, width: 120),
            SizedBox(height: AppSpacing.md),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _shimmerBlock(context, height: 110),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBlock(BuildContext context, {required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}
