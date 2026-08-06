import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/booking_helpers.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/features/booking/presentation/widgets/booking_card.dart';
import 'package:babysitter/features/booking/presentation/widgets/group_booking_card.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    BookingsTab.pending,
    BookingsTab.confirmed,
    BookingsTab.inProgress,
    BookingsTab.completed,
    BookingsTab.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tab = _tabs[_tabController.index];
      if (!ref.read(_tabProvider(tab)).hasLoaded) {
        ref.read(_tabProvider(tab).notifier).loadTab();
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final tab = _tabs[_tabController.index];
      final tabState = ref.read(_tabProvider(tab));
      if (!tabState.isLoading) {
        ref.read(_tabProvider(tab).notifier).refreshTab();
      }
    }
  }

  StateNotifierProvider<TabBookingsNotifier, TabBookingsState>
      _tabProvider(BookingsTab tab) {
    return switch (tab) {
      BookingsTab.pending => pendingBookingsProvider,
      BookingsTab.confirmed => confirmedBookingsProvider,
      BookingsTab.inProgress => inProgressBookingsProvider,
      BookingsTab.completed => completedBookingsProvider,
      BookingsTab.cancelled => cancelledBookingsProvider,
      BookingsTab.rejected => cancelledBookingsProvider,
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
        final tab = _tabs[_tabController.index];
        if (mounted) ref.read(_tabProvider(tab).notifier).refreshTab();
      }
    });
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final pendingState = ref.watch(pendingBookingsProvider);
    final confirmedState = ref.watch(confirmedBookingsProvider);
    final inProgressState = ref.watch(inProgressBookingsProvider);
    final completedState = ref.watch(completedBookingsProvider);
    final cancelledState = ref.watch(cancelledBookingsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: strings['bookings'] ?? 'Bookings',
        showBackButton: false,
      ),
      body: Column(
        children: [
          _TabBar(
            controller: _tabController,
            tabs: _tabs,
            counts: [
              pendingState.groupedBookings.length,
              confirmedState.groupedBookings.length,
              inProgressState.groupedBookings.length,
              completedState.groupedBookings.length,
              cancelledState.groupedBookings.length,
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: _tabs.map((tab) => _TabList(tab: tab)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends ConsumerStatefulWidget {
  final TabController controller;
  final List<BookingsTab> tabs;
  final List<int> counts;

  const _TabBar({
    required this.controller,
    required this.tabs,
    required this.counts,
  });

  @override
  ConsumerState<_TabBar> createState() => _TabBarState();
}

class _TabBarState extends ConsumerState<_TabBar> {
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
            final color = BookingHelpers.statusColor(
              tab == BookingsTab.pending
                  ? BookingStatus.pending
                  : tab == BookingsTab.confirmed
                      ? BookingStatus.confirmed
                      : tab == BookingsTab.inProgress
                          ? BookingStatus.inProgress
                          : tab == BookingsTab.completed
                              ? BookingStatus.completed
                              : BookingStatus.cancelled,
            );

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

class _TabList extends ConsumerStatefulWidget {
  final BookingsTab tab;

  const _TabList({required this.tab});

  @override
  ConsumerState<_TabList> createState() => _TabListState();
}

class _TabListState extends ConsumerState<_TabList> {
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
      BookingsTab.pending => pendingBookingsProvider,
      BookingsTab.confirmed => confirmedBookingsProvider,
      BookingsTab.inProgress => inProgressBookingsProvider,
      BookingsTab.completed => completedBookingsProvider,
      BookingsTab.cancelled => cancelledBookingsProvider,
      BookingsTab.rejected => cancelledBookingsProvider,
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
          actionLabel: empty.actionLabel,
          onAction: empty.onAction,
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
              return GroupBookingCard(
                groupItem: item,
              ).animate().fadeIn(
                    duration: 300.ms,
                    delay: (index * 50).ms,
                  );
            }
            return BookingCard(
              booking: item.primaryBooking,
            ).animate().fadeIn(
                  duration: 300.ms,
                  delay: (index * 50).ms,
                );
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
          title: strings['no_pending_bookings'] ?? 'No pending bookings',
          subtitle: strings['no_pending_bookings_subtitle'] ??
              'You have no bookings awaiting confirmation.',
          icon: Icon(Icons.schedule_rounded,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.pending)),
          actionLabel: strings['book_sitter'] ?? 'Book a Sitter',
          onAction: () => context.go(AppRoutes.parentSearch),
        );
      case BookingsTab.confirmed:
        return _EmptyData(
          title: strings['no_confirmed_bookings'] ?? 'No confirmed bookings',
          subtitle: strings['no_confirmed_bookings_subtitle'] ??
              'Your confirmed bookings will appear here.',
          icon: Icon(Icons.check_circle_outline,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.confirmed)),
        );
      case BookingsTab.completed:
        return _EmptyData(
          title: strings['no_completed_bookings'] ?? 'No completed bookings',
          subtitle: strings['no_completed_bookings_subtitle'] ??
              'Your completed bookings will appear here.',
          icon: Icon(Icons.history_rounded,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.completed)),
          actionLabel: strings['book_sitter'] ?? 'Book a Sitter',
          onAction: () => context.go(AppRoutes.parentSearch),
        );
      case BookingsTab.inProgress:
        return _EmptyData(
          title: strings['no_active_sessions'] ?? 'No active sessions',
          subtitle: strings['no_active_sessions_subtitle'] ??
              'All sessions completed for now.',
          icon: Icon(Icons.play_circle_outline,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.inProgress)),
        );
      case BookingsTab.cancelled:
        return _EmptyData(
          title: strings['no_cancelled_bookings'] ?? 'No cancelled bookings',
          subtitle: strings['no_cancelled_bookings_subtitle'] ??
              'You have no cancelled bookings.',
          icon: Icon(Icons.cancel_outlined,
              size: 44,
              color: BookingHelpers.statusColor(BookingStatus.cancelled)),
        );
      case BookingsTab.rejected:
        return _EmptyData(
          title: strings['no_rejected_bookings'] ?? 'No rejected bookings',
          subtitle: strings['no_rejected_bookings_subtitle'] ??
              'You have no rejected bookings.',
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
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });
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
