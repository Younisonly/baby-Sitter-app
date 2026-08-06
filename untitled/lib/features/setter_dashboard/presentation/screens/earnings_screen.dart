import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/setter_dashboard/data/dashboard_repository.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

final earningsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return repo.getEarningsBreakdown();
});

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsProvider);
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return Scaffold(
      appBar: AppAppBar(
        title: strings[AppLocalization.earnings_title] ?? 'Earnings',
      ),
      body: earningsAsync.when(
        loading: () => const _EarningsShimmer(),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AppErrorState(
              message: ErrorHandler.handle(err).message,
              onRetry: () => ref.invalidate(earningsProvider),
            ),
          ),
        ),
        data: (data) => _buildContent(context, strings, data),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, String> strings,
    Map<String, dynamic> data,
  ) {
    final totalEarnings = data['totalEarnings'] as int? ?? 0;
    final completedEarnings = data['completedEarnings'] as int? ?? 0;
    final pendingEarnings = data['pendingEarnings'] as int? ?? 0;
    final baseEarnings = data['baseEarnings'] as int? ?? 0;
    final extraEarnings = data['extraEarnings'] as int? ?? 0;
    final specialNeedsEarnings = data['specialNeedsEarnings'] as int? ?? 0;
    final totalCompletedBookings = data['totalCompletedBookings'] as int? ?? 0;

    final platformFee = (totalEarnings * 0.1).round();
    final netEarnings = totalEarnings - platformFee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TotalEarningsCard(amount: totalEarnings),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _EarningBadge(
                  label: strings[AppLocalization.earnings_completed] ??
                      'Completed',
                  amount: completedEarnings,
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _EarningBadge(
                  label: strings[AppLocalization.earnings_pending] ?? 'Pending',
                  amount: pendingEarnings,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _SectionCard(
            title: strings[AppLocalization.earnings_breakdown] ??
                'Breakdown',
            children: [
              _BreakdownRow(
                label: strings[AppLocalization.earnings_base] ?? 'Base',
                amount: baseEarnings,
                color: AppColors.primary,
              ),
              Divider(height: 1, color: context.dividerColor),
              _BreakdownRow(
                label: strings[AppLocalization.earnings_extra] ?? 'Extra',
                amount: extraEarnings,
                color: AppColors.info,
              ),
              Divider(height: 1, color: context.dividerColor),
              _BreakdownRow(
                label: strings[AppLocalization.earnings_special_needs] ??
                    'Special Needs',
                amount: specialNeedsEarnings,
                color: AppColors.secondary,
              ),
              Divider(height: 1, color: context.dividerColor),
              _BreakdownRow(
                label: strings[AppLocalization.earnings_total] ?? 'Total',
                amount: totalEarnings,
                color: context.textPrimary,
                isTotal: true,
              ),
              Divider(height: 1, color: context.dividerColor),
              _BreakdownRow(
                label: strings[AppLocalization.earnings_platform_fee] ??
                    'Platform Fee (10%)',
                amount: -platformFee,
                color: AppColors.error,
              ),
              Divider(height: 1, color: context.dividerColor),
              _BreakdownRow(
                label: strings[AppLocalization.earnings_net] ?? 'Net',
                amount: netEarnings,
                color: AppColors.success,
                isTotal: true,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _SectionCard(
            title: strings[AppLocalization.earnings_stats_title] ??
                'Statistics',
            children: [
              _StatRow(
                label: strings[AppLocalization.completed_bookings] ?? 'Completed',
                value: totalCompletedBookings.toString(),
              ),
              Divider(height: 1, color: context.dividerColor),
              _StatRow(
                label: strings[AppLocalization.earnings_average] ??
                    'Avg per booking',
                value: totalCompletedBookings > 0
                    ? '﷼${(totalEarnings / totalCompletedBookings).round()}'
                    : '﷼0',
              ),
              Divider(height: 1, color: context.dividerColor),
              _StatRow(
                label: strings[AppLocalization.earnings_rate] ??
                    'Avg hourly rate',
                value: '﷼${((baseEarnings + extraEarnings) / (totalCompletedBookings > 0 ? totalCompletedBookings : 1) / 4).round()}',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _TotalEarningsCard extends StatelessWidget {
  final int amount;

  const _TotalEarningsCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Earnings',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.8),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '﷼${_formatAmount(amount)}',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toString();
  }
}

class _EarningBadge extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _EarningBadge({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            '﷼${_formatAmount(amount)}',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toString();
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final bool isTotal;

  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
                  color: isTotal ? context.textPrimary : context.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            amount < 0
                ? '-﷼${_formatAmount(-amount)}'
                : '﷼${_formatAmount(amount)}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: amount < 0 ? AppColors.error : context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toString();
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsShimmer extends StatelessWidget {
  const _EarningsShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            height: 140.h,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          Container(
            height: 280.h,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ],
      ),
    );
  }
}
