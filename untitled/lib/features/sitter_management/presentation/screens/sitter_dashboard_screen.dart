import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/features/sitter_management/data/sitter_management_providers.dart';
import 'package:babysitter/features/sitter_management/presentation/widgets/sitter_stat_card.dart';
import 'package:babysitter/features/sitter_management/presentation/widgets/sitter_shimmer.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/shared/models/user_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class SitterManagementDashboard extends ConsumerStatefulWidget {
  const SitterManagementDashboard({super.key});

  @override
  ConsumerState<SitterManagementDashboard> createState() => _SitterManagementDashboardState();
}

class _SitterManagementDashboardState extends ConsumerState<SitterManagementDashboard> {
  bool _checkedRole = false;

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final strings = AppLocalization.get(code);
    final authState = ref.watch(authProvider);

    if (!_checkedRole) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkedRole = true;
        if (authState.user?.role != UserRole.babysitter) {
          context.go(AppRoutes.parentHome);
        }
        setState(() {});
      });
      return Scaffold(
        appBar: AppBar(
          title: Text(strings[AppLocalization.sitter_management] ?? 'Management'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (authState.user?.role != UserRole.babysitter) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings[AppLocalization.sitter_management] ?? 'Management'),
        centerTitle: true,
      ),
      body: _DashboardBody(),
    );
  }
}

class _DashboardBody extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final strings = AppLocalization.get(code);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final profile = user?.babysitterProfile;

    final statsAsync = ref.watch(sitterStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sitterStatsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          if (user != null && user.registrationStatus != RegistrationStatus.verified)
            _StatusBanner(strings: strings, user: user),
          _AvailabilityCard(
            strings: strings,
            profile: profile,
            user: user,
            isDark: isDark,
            onToggle: _toggleAvailability,
          ),
          const Gap(AppSpacing.lg),
          _SectionHeader(title: strings['quick_actions'] ?? 'Quick Actions'),
          const Gap(AppSpacing.md),
          _QuickActionsGrid(strings: strings, isDark: isDark),
          const Gap(AppSpacing.sectionSpacing),
          statsAsync.when(
            data: (stats) => _StatsGrid(stats: stats, strings: strings),
            loading: () => const SitterDashboardShimmer(),
            error: (_, __) => _StatsError(strings: strings),
          ),
          const Gap(AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability() async {
    try {
      final repo = ref.read(sitterManagementRepositoryProvider);
      await repo.toggleAvailability();
      ref.invalidate(sitterStatsProvider);
      await ref.read(authProvider.notifier).loadUser();
    } catch (_) {}
  }
}

class _AvailabilityCard extends StatelessWidget {
  final Map<String, String> strings;
  final BabysitterProfile? profile;
  final UserModel? user;
  final bool isDark;
  final VoidCallback onToggle;

  const _AvailabilityCard({
    required this.strings,
    required this.profile,
    required this.user,
    required this.isDark,
    required this.onToggle,
  });

  String _todayHours(String locale) {
    if (profile?.availability == null || profile!.availability.isEmpty) {
      return strings['no_schedule_set'] ?? 'No schedule set';
    }
    final today = DateTime.now().weekday;
    final dayIndex = today == DateTime.sunday ? 0 : today;
    final slots = profile!.availability.where((s) => s.dayOfWeek == dayIndex).toList();
    if (slots.isEmpty) return strings['day_off'] ?? 'Day off';
    return slots.map((s) => TimeFormatter.formatTimeRange(s.startTime, s.endTime, locale)).join(', ');
  }

  Future<void> _confirmTurnOff(
    BuildContext context,
    VoidCallback onToggle,
    Map<String, String> strings,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.bottomSheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gap(AppSpacing.xl),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pause_circle_outline_rounded,
                  size: 32,
                  color: AppColors.warning,
                ),
              ),
              Gap(AppSpacing.lg),
              Text(
                strings['turn_off_availability'] ?? 'Turn off availability?',
                style: AppTextStyles.titleLarge(
                  color: context.textPrimaryColor,
                  weight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(AppSpacing.sm),
              Text(
                strings['turn_off_description'] ??
                    "Your profile will be hidden from search. You won't receive new booking requests until you turn it back on.",
                style: AppTextStyles.bodyMedium(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: strings['keep_available'] ?? 'Keep Available',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  Gap(AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: strings['turn_off'] ?? 'Turn Off',
                      variant: AppButtonVariant.danger,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      onToggle();
      AppSnackbar.info(
        context,
        strings['availability_off'] ?? "You're now hidden from search",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = profile?.isAvailable ?? false;
    final locale = Localizations.localeOf(context).languageCode;
    final schedule = _todayHours(locale);
    final isScheduleSet = profile?.availability != null && profile!.availability.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAvailable
              ? [AppColors.primary, AppColors.primaryLight]
              : [AppColors.textSecondaryLight, AppColors.textMutedLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? AppColors.primary : AppColors.textMutedLight).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                isAvailable ? Icons.wifi_tethering_rounded : Icons.cloud_off_rounded,
                size: 24,
                color: AppColors.white,
              ),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAvailable ? AppColors.success : AppColors.textMutedLight,
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      Flexible(
                        child: Text(
                          isAvailable
                              ? (strings['available_for_bookings'] ?? 'Available for Bookings')
                              : (strings['unavailable'] ?? 'Unavailable'),
                          style: AppTextStyles.titleSmall(
                            weight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.xxs),
                  Text(
                    isScheduleSet ? '${strings['today'] ?? 'Today'}: $schedule' : schedule,
                    style: AppTextStyles.caption(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: isAvailable,
                onChanged: (_) {
                  if (isAvailable) {
                    _confirmTurnOff(context, onToggle, strings);
                  } else {
                    onToggle();
                    AppSnackbar.success(
                      context,
                      strings['now_available'] ?? "You're now available for bookings",
                    );
                  }
                },
                activeColor: AppColors.white,
                activeTrackColor: AppColors.white.withValues(alpha: 0.4),
                inactiveThumbColor: AppColors.white,
                inactiveTrackColor: AppColors.white.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Map<String, String> strings;
  final UserModel user;

  const _StatusBanner({required this.strings, required this.user});

  @override
  Widget build(BuildContext context) {
    final status = user.registrationStatus;
    String message;
    IconData icon;
    Color color;

    switch (status) {
      case RegistrationStatus.submitted:
      case RegistrationStatus.underReview:
        message = strings['sitter_pending_approval'] ??
            'Your profile is pending admin approval.';
        icon = Icons.hourglass_top_rounded;
        color = AppColors.warning;
      case RegistrationStatus.rejected:
        message = strings[AppLocalization.profile_rejected_message] ??
            'Your profile was not approved. Please contact support.';
        icon = Icons.cancel_outlined;
        color = AppColors.error;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: AppTextStyles.bodySmall(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final SitterStats stats;
  final Map<String, String> strings;

  const _StatsGrid({required this.stats, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SitterStatCard(
                label: strings[AppLocalization.total_bookings] ?? 'Total Bookings',
                value: '${stats.totalBookings}',
                icon: Icons.calendar_today_rounded,
                color: AppColors.primary,
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: SitterStatCard(
                label: strings[AppLocalization.completed] ?? 'Completed',
                value: '${stats.completedBookings}',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SitterStatCard(
                label: strings[AppLocalization.earnings] ?? 'Earnings',
                value: 'SAR ${stats.totalEarnings.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.accent,
              ),
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: SitterStatCard(
                label: strings[AppLocalization.rating] ?? 'Rating',
                value: stats.rating > 0
                    ? stats.rating.toStringAsFixed(1)
                    : '--',
                valueSuffix: stats.rating > 0
                    ? '(${stats.reviewCount} ${strings[AppLocalization.reviews] ?? 'reviews'})'
                    : null,
                icon: Icons.star_rounded,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsError extends StatelessWidget {
  final Map<String, String> strings;

  const _StatsError({required this.strings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: AppColors.error.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error.withValues(alpha: 0.6)),
            const Gap(AppSpacing.sm),
            Text(
              strings[AppLocalization.failed_load_stats] ?? 'Could not load stats',
              style: AppTextStyles.bodyMedium(),
            ),
            Text(
              strings[AppLocalization.pull_refresh_retry] ?? 'Pull down to retry',
              style: AppTextStyles.caption(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleLarge(weight: FontWeight.bold),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final Map<String, String> strings;
  final bool isDark;

  const _QuickActionsGrid({required this.strings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.calendar_month_rounded,
        title: strings[AppLocalization.bookings] ?? 'Bookings',
        color: AppColors.primary,
        route: AppRoutes.sitterBookings,
      ),
      _ActionItem(
        icon: Icons.account_balance_wallet_rounded,
        title: strings[AppLocalization.earnings_title] ?? 'Earnings',
        color: AppColors.accent,
        route: AppRoutes.earnings,
      ),
      _ActionItem(
        icon: Icons.analytics_rounded,
        title: strings[AppLocalization.analytics_title] ?? 'Analytics',
        color: AppColors.success,
        route: AppRoutes.analytics,
      ),
      _ActionItem(
        icon: Icons.star_rounded,
        title: strings[AppLocalization.reviews] ?? 'Reviews',
        color: AppColors.warning,
        route: AppRoutes.sitterReviews,
      ),
      _ActionItem(
        icon: Icons.person_rounded,
        title: strings[AppLocalization.profile] ?? 'Profile',
        route: AppRoutes.editSitterProfile,
        color: AppColors.secondary,
      ),
      _ActionItem(
        icon: Icons.favorite_outline_rounded,
        title: strings[AppLocalization.followers] ?? 'Followers',
        color: AppColors.error,
        route: AppRoutes.followers,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: actions.length,
      itemBuilder: (_, index) => _ActionCard(item: actions[index]),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final Color color;
  final String route;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.route,
  });
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;

  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceOverlayDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.white : AppColors.black).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(item.icon, size: 24, color: item.color),
              ),
              const Gap(AppSpacing.sm),
              Text(
                item.title,
                style: AppTextStyles.titleSmall(weight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
