import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/booking_helpers.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';

import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SitterBookingsScreen extends ConsumerStatefulWidget {
  const SitterBookingsScreen({super.key});

  @override
  ConsumerState<SitterBookingsScreen> createState() => _SitterBookingsScreenState();
}

class _SitterBookingsScreenState extends ConsumerState<SitterBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: sitterBookingsTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tab = sitterBookingsTabs[_tabController.index];
      if (!ref.read(_sitterTabProvider(tab)).hasLoaded) {
        ref.read(_sitterTabProvider(tab).notifier).loadTab();
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final tab = sitterBookingsTabs[_tabController.index];
      final tabState = ref.read(_sitterTabProvider(tab));
      if (!tabState.isLoading) {
        ref.read(_sitterTabProvider(tab).notifier).refreshTab();
      }
    }
  }

  StateNotifierProvider<TabBookingsNotifier, TabBookingsState>
      _sitterTabProvider(BookingsTab tab) {
    return switch (tab) {
      BookingsTab.pending => sitterPendingBookingsProvider,
      BookingsTab.confirmed => sitterConfirmedBookingsProvider,
      BookingsTab.inProgress => sitterInProgressBookingsProvider,
      BookingsTab.completed => sitterCompletedBookingsProvider,
      BookingsTab.cancelled => sitterCancelledBookingsProvider,
      BookingsTab.rejected => sitterRejectedBookingsProvider,
    };
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bookingsRefreshProvider, (prev, next) {
      if (prev != next) {
        final tab = sitterBookingsTabs[_tabController.index];
        if (mounted) ref.read(_sitterTabProvider(tab).notifier).refreshTab();
      }
    });
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final pendingState = ref.watch(sitterPendingBookingsProvider);
    final confirmedState = ref.watch(sitterConfirmedBookingsProvider);
    final inProgressState = ref.watch(sitterInProgressBookingsProvider);
    final completedState = ref.watch(sitterCompletedBookingsProvider);
    final cancelledState = ref.watch(sitterCancelledBookingsProvider);
    final rejectedState = ref.watch(sitterRejectedBookingsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: strings['sitter_bookings'] ?? 'Manage Bookings',
        showBackButton: true,
      ),
      body: Column(
        children: [
          _SitterTabBar(
            controller: _tabController,
            tabs: sitterBookingsTabs,
            counts: [
              pendingState.groupedBookings.length,
              confirmedState.groupedBookings.length,
              inProgressState.groupedBookings.length,
              completedState.groupedBookings.length,
              cancelledState.groupedBookings.length,
              rejectedState.groupedBookings.length,
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: sitterBookingsTabs.map((tab) {
                return _SitterTabList(tab: tab);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SitterTabBar extends ConsumerStatefulWidget {
  final TabController controller;
  final List<BookingsTab> tabs;
  final List<int> counts;

  const _SitterTabBar({
    required this.controller,
    required this.tabs,
    required this.counts,
  });

  @override
  ConsumerState<_SitterTabBar> createState() => _SitterTabBarState();
}

class _SitterTabBarState extends ConsumerState<_SitterTabBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.controller.index;
    widget.controller.addListener(_onIndexChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onIndexChanged);
    super.dispose();
  }

  void _onIndexChanged() {
    setState(() => _selectedIndex = widget.controller.index);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark
              ? context.surfaceColor.withValues(alpha: 0.5)
              : context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: context.dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: List.generate(widget.tabs.length, (i) {
            final isSelected = i == _selectedIndex;
            final tab = widget.tabs[i];
            final count = widget.counts[i];
            final color = _tabColor(tab);

            return Expanded(
              child: GestureDetector(
                onTap: () => widget.controller.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: isDark ? 0.2 : 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: color.withValues(alpha: 0.3), width: 1)
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _tabLabel(tab, strings),
                          style: AppTextStyles.labelSmall(
                            weight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? color
                                : context.textMutedColor,
                          ),
                          maxLines: 1,
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            constraints: const BoxConstraints(minWidth: 18),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : context.textMutedColor
                                      .withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: AppTextStyles.labelSmall(
                                color: isSelected
                                    ? Colors.white
                                    : context.textSecondaryColor,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Color _tabColor(BookingsTab tab) {
    switch (tab) {
      case BookingsTab.pending:
        return AppColors.warning;
      case BookingsTab.confirmed:
        return AppColors.success;
      case BookingsTab.inProgress:
        return AppColors.info;
      case BookingsTab.completed:
        return AppColors.info;
      case BookingsTab.cancelled:
        return AppColors.error;
      case BookingsTab.rejected:
        return AppColors.textMutedLight;
    }
  }

  String _tabLabel(BookingsTab tab, Map<String, String> strings) {
    switch (tab) {
      case BookingsTab.pending:
        return strings['pending_tab'] ?? 'Pending';
      case BookingsTab.confirmed:
        return strings['confirmed_tab'] ?? 'Confirmed';
      case BookingsTab.inProgress:
        return strings['in_progress'] ?? 'In Progress';
      case BookingsTab.completed:
        return strings['completed_tab'] ?? 'Completed';
      case BookingsTab.cancelled:
        return strings['cancelled_tab'] ?? 'Cancelled';
      case BookingsTab.rejected:
        return strings['rejected_tab'] ?? 'Rejected';
    }
  }
}

class _SitterTabList extends ConsumerStatefulWidget {
  final BookingsTab tab;

  const _SitterTabList({required this.tab});

  @override
  ConsumerState<_SitterTabList> createState() => _SitterTabListState();
}

class _SitterTabListState extends ConsumerState<_SitterTabList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  StateNotifierProvider<TabBookingsNotifier, TabBookingsState>
      _tabProvider() {
    return switch (widget.tab) {
      BookingsTab.pending => sitterPendingBookingsProvider,
      BookingsTab.confirmed => sitterConfirmedBookingsProvider,
      BookingsTab.inProgress => sitterInProgressBookingsProvider,
      BookingsTab.completed => sitterCompletedBookingsProvider,
      BookingsTab.cancelled => sitterCancelledBookingsProvider,
      BookingsTab.rejected => sitterRejectedBookingsProvider,
    };
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(_tabProvider().notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final state = ref.watch(_tabProvider());
    final items = state.groupedBookings;

    if (state.isLoading && state.bookings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView.separated(
          itemCount: 4,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, __) => const _ShimmerCard(),
        ),
      );
    }

    if (state.error != null && state.bookings.isEmpty) {
      return AppErrorState(
        title: strings['load_error_title'] ?? 'Something went wrong',
        message: state.error ??
            strings['load_error_message'] ??
            'Please check your connection and try again',
        onRetry: () => ref.read(_tabProvider().notifier).loadTab(),
      ).animate().fadeIn(duration: 300.ms);
    }

    if (items.isEmpty) {
      final empty = _emptyState(widget.tab, strings);
      return SingleChildScrollView(
        child: AppEmptyState(
          title: empty.title,
          subtitle: empty.subtitle,
          icon: empty.icon,
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(_tabProvider().notifier).loadTab(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount:
            1 + items.length + (state.hasMore && !state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const SizedBox(height: AppSpacing.sm);
          }
          final itemIndex = index - 1;
          if (itemIndex < items.length) {
            final item = items[itemIndex];
            if (item.isGroup) {
              return _SitterGroupBookingCard(groupItem: item)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: (index * 50).ms);
            }
            return _SitterBookingCard(booking: item.primaryBooking)
                .animate()
                .fadeIn(duration: 300.ms, delay: (index * 50).ms);
          }
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return const SizedBox(height: AppSpacing.xl);
        },
      ),
    );
  }

  _EmptyData _emptyState(BookingsTab tab, Map<String, String> strings) {
    switch (tab) {
      case BookingsTab.pending:
        return _EmptyData(
          title: strings['sitter_no_pending_bookings'] ?? 'No Pending Requests',
          subtitle: strings['sitter_no_pending_bookings_subtitle'] ??
              'You have no pending booking requests.',
          icon: Icon(Icons.schedule_rounded,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.pending)),
        );
      case BookingsTab.confirmed:
        return _EmptyData(
          title: strings['sitter_no_confirmed_bookings'] ?? 'No Confirmed Bookings',
          subtitle: strings['sitter_no_confirmed_bookings_subtitle'] ??
              'Your confirmed bookings will appear here.',
          icon: Icon(Icons.check_circle_outline,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.confirmed)),
        );
      case BookingsTab.completed:
        return _EmptyData(
          title: strings['sitter_no_completed_bookings'] ?? 'No Completed Bookings',
          subtitle: strings['sitter_no_completed_bookings_subtitle'] ??
              'Your completed bookings will appear here.',
          icon: Icon(Icons.history_rounded,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.completed)),
        );
      case BookingsTab.inProgress:
        return _EmptyData(
          title: strings['sitter_no_active_sessions'] ?? 'No Active Sessions',
          subtitle: strings['sitter_no_active_sessions_subtitle'] ??
              'All sessions completed for now.',
          icon: Icon(Icons.play_circle_outline,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.inProgress)),
        );
      case BookingsTab.cancelled:
        return _EmptyData(
          title: strings['sitter_no_cancelled_bookings'] ?? 'No Cancelled Bookings',
          subtitle: strings['sitter_no_cancelled_bookings_subtitle'] ??
              'You have no cancelled bookings.',
          icon: Icon(Icons.cancel_outlined,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.cancelled)),
        );
      case BookingsTab.rejected:
        return _EmptyData(
          title: strings['sitter_no_rejected_bookings'] ?? 'No Rejected Bookings',
          subtitle: strings['sitter_no_rejected_bookings_subtitle'] ??
              'You have not rejected any bookings.',
          icon: Icon(Icons.block_rounded,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.rejected)),
        );
    }
  }
}

class _EmptyData {
  final String title;
  final String subtitle;
  final Widget icon;
  const _EmptyData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _SitterBookingCard extends ConsumerWidget {
  final BookingModel booking;

  const _SitterBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final statusColor = BookingHelpers.statusColor(booking.status);
    final name = booking.customer?.name ?? 'Booking #${booking.id}';
    final locale = ref.watch(languageProvider).code;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push('/booking/${booking.id}'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        _statusIcon(booking.status),
                        size: 22,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.titleMedium(
                                weight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('MMM d, yyyy', locale).format(booking.date)} • ${TimeFormatter.formatTimeRange(booking.startTime, booking.endTime, locale)}',
                            style: AppTextStyles.bodySmall(
                              color: context.textMutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        _statusText(booking.status, strings),
                        style: AppTextStyles.labelSmall(
                          color: statusColor,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (booking.status == BookingStatus.confirmed && booking.sessionStatus == SessionStatus.pending) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: strings['start_booking'] ?? 'Start Execution',
                          onPressed: () => _startSession(context, ref, booking),
                          variant: AppButtonVariant.filled,
                          prefixIcon: const Icon(Icons.play_arrow_rounded, size: 18),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () => context.push('/chat?userId=${booking.customer?.id}&bookingId=${booking.id}'),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.textSecondaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(Icons.chat_bubble_outline_rounded, size: 20, color: context.textSecondaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (booking.isSessionActive) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 10, color: AppColors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            strings['session_active'] ?? 'Session Active',
                            style: AppTextStyles.bodySmall(
                              color: AppColors.success,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 32,
                          child: AppButton(
                            text: strings['view_session'] ?? 'View',
                            onPressed: () => _openSession(context, booking.id),
                            variant: AppButtonVariant.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (booking.cancellationReason != null &&
                    booking.status == BookingStatus.cancelled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoBanner(
                      message: booking.cancellationReason!,
                      color: AppColors.error),
                ],
                if (booking.rejectionReason != null &&
                    booking.status == BookingStatus.rejected) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoBanner(
                      message: booking.rejectionReason!,
                      color: AppColors.error),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.schedule_rounded;
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.inProgress:
        return Icons.play_circle_rounded;
      case BookingStatus.completed:
        return Icons.check_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
      case BookingStatus.rejected:
        return Icons.block_rounded;
      case BookingStatus.expired:
        return Icons.timer_off_rounded;
    }
  }

  String _statusText(BookingStatus status, Map<String, String> strings) {
    switch (status) {
      case BookingStatus.pending:
        return strings['pending'] ?? 'Pending';
      case BookingStatus.confirmed:
        return strings['confirmed'] ?? 'Confirmed';
      case BookingStatus.inProgress:
        return strings['in_progress'] ?? 'Active';
      case BookingStatus.completed:
        return strings['completed'] ?? 'Completed';
      case BookingStatus.cancelled:
        return strings['cancelled'] ?? 'Cancelled';
      case BookingStatus.rejected:
        return strings['rejected'] ?? 'Rejected';
      case BookingStatus.expired:
        return strings['expired'] ?? 'Expired';
    }
  }

  void _startSession(BuildContext context, WidgetRef ref, BookingModel booking) {
    context.push('/booking/${booking.id}/session');
  }

  void _openSession(BuildContext context, String bookingId) {
    context.push('/booking/$bookingId/session');
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  final Color color;

  const _InfoBanner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          AppShimmer(width: 48, height: 48, borderRadius: AppRadius.md),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: 140, height: 14, borderRadius: AppRadius.sm),
                const SizedBox(height: AppSpacing.xs),
                AppShimmer(width: 180, height: 12, borderRadius: AppRadius.sm),
                const SizedBox(height: AppSpacing.xxs),
                AppShimmer(width: 100, height: 12, borderRadius: AppRadius.sm),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppShimmer(width: 50, height: 14, borderRadius: AppRadius.sm),
              const SizedBox(height: 6),
              AppShimmer(width: 60, height: 20, borderRadius: AppRadius.full),
            ],
          ),
        ],
      ),
    );
  }
}

class _SitterGroupBookingCard extends ConsumerStatefulWidget {
  final BookingGroupDisplayItem groupItem;

  const _SitterGroupBookingCard({required this.groupItem});

  @override
  ConsumerState<_SitterGroupBookingCard> createState() =>
      _SitterGroupBookingCardState();
}

class _SitterGroupBookingCardState extends ConsumerState<_SitterGroupBookingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final item = widget.groupItem;
    final primary = item.primaryBooking;
    final statusColor = BookingHelpers.statusColor(primary.status);
    final name = item.customer?.name ?? 'Booking #${primary.id}';
    final locale = ref.watch(languageProvider).code;
    final anySessionActive = item.children.any((c) => c.isSessionActive);
    final firstStartable = item.children.cast<BookingModel?>().firstWhere(
      (c) => c!.status == BookingStatus.confirmed && c.sessionStatus == SessionStatus.pending,
      orElse: () => null,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.push('/booking/${primary.id}'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(strings, primary, statusColor, name, locale),
                const SizedBox(height: AppSpacing.md),
                _buildDateRange(strings, item, locale),
                if (!anySessionActive && firstStartable != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildActions(strings, ref, firstStartable),
                ],
                if (anySessionActive || primary.isSessionActive) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildSessionBanner(strings),
                ],
                if (primary.cancellationReason != null &&
                    primary.status == BookingStatus.cancelled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoBanner(
                      message: primary.cancellationReason!,
                      color: AppColors.error),
                ],
                if (primary.rejectionReason != null &&
                    primary.status == BookingStatus.rejected) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoBanner(
                      message: primary.rejectionReason!,
                      color: AppColors.error),
                ],
                if (_expanded) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Divider(color: context.dividerColor, height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  ...item.children.map((b) =>
                      _buildDayRow(b, strings, locale)),
                ],
                const SizedBox(height: AppSpacing.sm),
                _buildFooter(strings, primary, item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    Map<String, String> strings,
    BookingModel primary,
    Color statusColor,
    String name,
    String locale,
  ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            _statusIcon(primary.status),
            size: 22,
            color: statusColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.titleMedium(weight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.dayCount} ${strings['days'] ?? 'days'}',
                style: AppTextStyles.bodySmall(color: context.textMutedColor),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${item.totalAmount.toStringAsFixed(0)}',
              style: AppTextStyles.titleSmall(
                weight: FontWeight.w700,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                _groupStatusText(strings),
                style: AppTextStyles.labelSmall(
                  color: statusColor,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRange(
    Map<String, String> strings,
    BookingGroupDisplayItem item,
    String locale,
  ) {
    final firstStr = DateFormat('MMM d', locale).format(item.firstDate);
    final lastStr = DateFormat('MMM d, yyyy', locale).format(item.lastDate);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: statusColor(primary.status).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, size: 15,
              color: statusColor(primary.status)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$firstStr – $lastStr',
            style: AppTextStyles.labelMedium(
              weight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color statusColor(BookingStatus status) =>
      BookingHelpers.statusColor(status);

  Widget _buildActions(Map<String, String> strings, WidgetRef ref, BookingModel target) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: strings['start_booking'] ?? 'Start Execution',
            onPressed: () => _startSession(context, ref, target),
            variant: AppButtonVariant.filled,
            prefixIcon: const Icon(Icons.play_arrow_rounded, size: 18),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => _openChat(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.textSecondaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  size: 20, color: context.textSecondaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionBanner(Map<String, String> strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 10,
              color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              strings['session_active'] ?? 'Session Active',
              style: AppTextStyles.bodySmall(
                color: AppColors.success,
                weight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: AppButton(
              text: strings['view_session'] ?? 'View',
              onPressed: () => _openSession(context),
              variant: AppButtonVariant.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    Map<String, String> strings,
    BookingModel primary,
    BookingGroupDisplayItem item,
  ) {
    return Row(
      children: [
        Text(
          '#${primary.id}',
          style: AppTextStyles.labelSmall(color: context.textMutedColor),
        ),
        const Spacer(),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _expanded
                      ? (strings[AppLocalization.hide_details] ?? 'Hide Details')
                      : (strings[AppLocalization.view_details] ?? 'View Details'),
                  style: AppTextStyles.labelSmall(
                    color: AppColors.primary,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(BookingModel booking,
      Map<String, String> strings, String locale) {
    final isDayDone = booking.isDayDone;
    final isCancelled = booking.status == BookingStatus.cancelled;
    final displayStatus = isDayDone ? BookingStatus.completed : booking.status;
    final dayStatusColor = BookingHelpers.statusColor(displayStatus);
    final dayIcon = BookingHelpers.statusIcon(displayStatus);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: () {
          if (isCancelled && booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty) {
            _showCancellationDialog(context, booking, strings, locale);
          } else {
            context.push('/booking/${booking.id}');
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDayDone
                ? AppColors.success.withValues(alpha: 0.05)
                : context.surfaceColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isDayDone
                  ? AppColors.success.withValues(alpha: 0.2)
                  : context.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dayStatusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      dayIcon,
                      size: 20,
                      color: dayStatusColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                DateFormat('EEE, MMM d', locale)
                                    .format(booking.date),
                                style: AppTextStyles.labelMedium(
                                  weight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: dayStatusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                strings[BookingHelpers.statusLocalizationKey(displayStatus)] ?? displayStatus.name,
                                style: AppTextStyles.labelSmall(
                                  color: dayStatusColor,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 12, color: context.textMutedColor),
                            const SizedBox(width: 3),
                            Text(
                              BookingHelpers.formatTimeRange(
                                  booking.startTime, booking.endTime,
                                  locale: locale),
                              style: AppTextStyles.caption(
                                  color: context.textMutedColor),
                            ),
                          ],
                        ),
                        if (isCancelled && booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 11, color: AppColors.error),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  _cancellationReasonText(booking, strings),
                                  style: AppTextStyles.caption(color: AppColors.error, weight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(BookingStatus status) {
    return BookingHelpers.statusIcon(status);
  }

  String _groupStatusText(Map<String, String> strings) {
    final allDone = item.children.every((b) => b.isDayDone);
    if (allDone) {
      return strings['completed'] ?? 'Completed';
    }
    final dayDoneCount = item.children.where((b) => b.isDayDone).length;
    final cancelled = item.children.where((b) => b.status == BookingStatus.cancelled).length;
    if (cancelled > 0 && dayDoneCount > 0) {
      return strings['partially_cancelled'] ?? 'Partially Cancelled';
    }
    if (dayDoneCount > 0) {
      return '$dayDoneCount/${item.children.length} ${strings['days_done'] ?? 'days done'}';
    }
    final primary = item.primaryBooking;
    return strings[BookingHelpers.statusLocalizationKey(primary.status)] ?? primary.status.name;
  }

  void _startSession(BuildContext context, WidgetRef ref, [BookingModel? target]) {
    final id = target?.id ?? primary.id;
    context.push('/booking/$id/session');
  }

  void _openSession(BuildContext context) {
    context.push('/booking/${primary.id}/session');
  }

  void _openChat(BuildContext context) {
    final customerId = item.customer?.id;
    if (customerId != null) {
      context.push(
          '/chat?userId=$customerId&bookingId=${primary.id}');
    }
  }

  String _cancellationReasonText(BookingModel booking, Map<String, String> strings) {
    final reason = booking.cancellationReason;
    if (reason == null || reason.isEmpty) {
      return strings['cancelled_reason_label'] ?? 'Cancelled';
    }
    if (reason.contains('date has passed') || reason.contains('past their date')) {
      return strings['reason_date_passed'] ?? 'Date expired';
    }
    if (reason.contains('availability conflict')) {
      return strings['reason_availability_conflict'] ?? 'Sitter unavailable';
    }
    if (reason.contains('customer') || reason.contains('parent')) {
      return strings['reason_cancelled_by_customer'] ?? 'Cancelled by customer';
    }
    if (reason.contains('admin')) {
      return strings['reason_admin_cancel'] ?? 'Admin force cancel';
    }
    return reason;
  }

  void _showCancellationDialog(BuildContext context, BookingModel booking, Map<String, String> strings, String locale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.error, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text(
              strings['cancellation_reason'] ?? 'Cancellation Reason',
              style: AppTextStyles.titleMedium(weight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, MMM d, yyyy', locale).format(booking.date),
              style: AppTextStyles.labelMedium(color: context.textMutedColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              booking.cancellationReason ?? strings['cancelled_reason_label'] ?? 'Cancelled',
              style: AppTextStyles.bodyMedium(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              strings['close'] ?? 'Close',
              style: AppTextStyles.labelMedium(color: AppColors.primary, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  BookingModel get primary => widget.groupItem.primaryBooking;
  BookingGroupDisplayItem get item => widget.groupItem;
}
