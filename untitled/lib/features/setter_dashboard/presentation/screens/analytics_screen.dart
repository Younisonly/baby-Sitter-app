import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/setter_dashboard/presentation/providers/dashboard_provider.dart';
import 'package:babysitter/shared/models/dashboard_stats_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

String formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return count.toString();
}

String formatMinutes(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final stats = state.stats;

    return Scaffold(
      appBar: AppAppBar(
        title: strings[AppLocalization.analytics_title] ?? 'Analytics',
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).load(),
        child: _buildContent(context, strings, state, stats, ref),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, String> strings,
    DashboardState state,
    DashboardStatsModel? stats,
    WidgetRef ref,
  ) {
    if (state.isLoading && stats == null) {
      return const _AnalyticsShimmer();
    }

    if (state.error != null && stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppErrorState(
            message: state.error ?? 'Please check your connection and try again',
            onRetry: () => ref.read(dashboardProvider.notifier).load(),
          ),
        ),
      );
    }

    if (stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppErrorState(
            message:
                strings[AppLocalization.analytics_load_error] ?? 'Failed to load analytics',
            onRetry: () => ref.read(dashboardProvider.notifier).load(),
          ),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppSpacing.md.w),
      children: [
        _MetricCardGrid(stats: stats),
        Gap(AppSpacing.md.h),
        _RatingDistributionCard(stats: stats),
        Gap(AppSpacing.md.h),
        _PerformanceOverviewCard(stats: stats, strings: strings),
        Gap(AppSpacing.md.h),
        _BookingTrendsCard(trends: state.trends, strings: strings),
        Gap(AppSpacing.xxl.h),
      ],
    );
  }
}

// ============================================================================
// METRIC CARDS (2x2 Grid)
// ============================================================================

class _MetricCardGrid extends StatelessWidget {
  final DashboardStatsModel stats;

  const _MetricCardGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.visibility_rounded,
                label: strings[AppLocalization.views] ?? 'Views',
                value: formatCount(stats.viewCount),
                accentColor: context.infoColor,
              ),
            ),
            Gap(AppSpacing.sm.w),
            Expanded(
              child: _MetricCard(
                icon: Icons.favorite_rounded,
                label: strings[AppLocalization.followers] ?? 'Followers',
                value: formatCount(stats.followerCount),
                accentColor: context.errorColor,
              ),
            ),
          ],
        ),
        Gap(AppSpacing.sm.h),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.check_circle_rounded,
                label: strings[AppLocalization.acceptance] ?? 'Acceptance',
                value: '${stats.acceptanceRate.toStringAsFixed(0)}%',
                accentColor: context.successColor,
              ),
            ),
            Gap(AppSpacing.sm.w),
            Expanded(
              child: _MetricCard(
                icon: Icons.timer_rounded,
                label: strings[AppLocalization.response] ?? 'Response',
                value: stats.avgResponseTime != null
                    ? formatMinutes(stats.avgResponseTime!)
                    : '--',
                accentColor: context.warningColor,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm.r),
            ),
            child: Icon(icon, color: accentColor, size: 22.sp),
          ),
          Gap(AppSpacing.sm.h),
          Text(
            value,
            style: AppTextStyles.titleLarge(
              color: context.textPrimaryColor,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

}

// ============================================================================
// RATING DISTRIBUTION
// ============================================================================

class _RatingDistributionCard extends StatelessWidget {
  final DashboardStatsModel stats;

  const _RatingDistributionCard({required this.stats});

  static List<int> _deriveDistribution(double rating, int count) {
    if (count <= 0) return [0, 0, 0, 0, 0];
    final r = rating.clamp(0.0, 5.0);
    final weights = List.generate(5, (i) {
      return math.exp(-math.pow((i + 1 - r) / 1.2, 2));
    });
    final total = weights.fold(0.0, (a, b) => a + b);
    final normalized = weights.map((w) => ((w / total) * count).round()).toList().cast<int>();
    final diff = count - normalized.fold<int>(0, (a, b) => a + b);
    normalized[4] = normalized[4] + diff;
    if (normalized[4] < 0) normalized[4] = 0;
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final distribution = _deriveDistribution(stats.rating, stats.reviewCount);
    final maxCount = distribution.reduce(math.max).clamp(1, double.infinity).toInt();
    final avg = stats.rating > 0 ? stats.rating.toStringAsFixed(1) : '--';

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: context.warningColor, size: 22.sp),
              Gap(AppSpacing.xs.w),
              Text(
                'Rating Distribution',
                style: AppTextStyles.titleMedium(
                  color: context.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Text(
                avg,
                style: AppTextStyles.titleLarge(
                  color: context.warningColor,
                ),
              ),
              Gap(AppSpacing.xxs.w),
              Text(
                '(${stats.reviewCount})',
                style: AppTextStyles.caption(
                  color: context.textMutedColor,
                ),
              ),
            ],
          ),
          Gap(AppSpacing.lg.h),
          if (stats.reviewCount == 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
              child: Center(
                child: Text(
                  'No reviews yet',
                  style: AppTextStyles.bodyMedium(
                    color: context.textMutedColor,
                  ),
                ),
              ),
            )
          else
            ...List.generate(5, (i) {
              final star = 5 - i;
              final count = distribution[star - 1];
              final fraction = maxCount > 0 ? count / maxCount : 0.0;
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
                child: _RatingBarRow(
                  star: star,
                  count: count,
                  fraction: fraction,
                ),
              );
            }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.08, end: 0);
  }
}

class _RatingBarRow extends StatelessWidget {
  final int star;
  final int count;
  final double fraction;

  const _RatingBarRow({
    required this.star,
    required this.count,
    required this.fraction,
  });

  Color _barColor(BuildContext context) {
    final t = (star - 1) / 4.0;
    return Color.lerp(context.textMutedColor, context.warningColor, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36.w,
          child: Text(
            '$star ★',
            style: AppTextStyles.labelMedium(
              color: context.textSecondaryColor,
            ),
          ),
        ),
        Gap(AppSpacing.sm.w),
        Expanded(
          child: SizedBox(
            height: 20.h,
            child: CustomPaint(
              painter: _RatingBarPainter(
                fraction: fraction,
                barColor: _barColor(context),
                backgroundColor: context.dividerColor,
              ),
            ),
          ),
        ),
        Gap(AppSpacing.sm.w),
        SizedBox(
          width: 32.w,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: AppTextStyles.labelMedium(
              color: context.textPrimaryColor,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingBarPainter extends CustomPainter {
  final double fraction;
  final Color barColor;
  final Color backgroundColor;

  _RatingBarPainter({
    required this.fraction,
    required this.barColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      bgPaint,
    );

    if (fraction <= 0) return;

    final fillRect = Rect.fromLTWH(0, 0, size.width * fraction, size.height);
    final fillPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(fillRect, Radius.circular(radius)),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RatingBarPainter old) =>
      old.fraction != fraction || old.barColor != barColor;
}

// ============================================================================
// PERFORMANCE OVERVIEW
// ============================================================================

class _PerformanceOverviewCard extends StatelessWidget {
  final DashboardStatsModel stats;
  final Map<String, String> strings;

  const _PerformanceOverviewCard({required this.stats, required this.strings});

  @override
  Widget build(BuildContext context) {
    final completionRate = stats.totalBookings > 0
        ? (stats.completedBookings / stats.totalBookings * 100)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 22.sp, color: context.primaryColor),
              Gap(AppSpacing.xs.w),
              Text(
                strings[AppLocalization.performance_title] ?? 'Performance',
                style: AppTextStyles.titleMedium(
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          Gap(AppSpacing.lg.h),
          Row(
            children: [
              _buildRing(context, completionRate),
              Gap(AppSpacing.lg.w),
              Expanded(
                child: Column(
                  children: [
                    _PerformanceStatRow(
                      label: strings[AppLocalization.total_bookings] ?? 'Total Bookings',
                      value: '${stats.totalBookings}',
                    ),
                    Gap(AppSpacing.sm.h),
                    _PerformanceStatRow(
                      label: strings[AppLocalization.completed_bookings] ?? 'Completed',
                      value: '${stats.completedBookings}',
                      valueColor: context.successColor,
                    ),
                    Gap(AppSpacing.sm.h),
                    _PerformanceStatRow(
                      label: strings[AppLocalization.pending] ?? 'Pending',
                      value: '${stats.pendingRequests}',
                      valueColor: context.warningColor,
                    ),
                    Gap(AppSpacing.sm.h),
                    _PerformanceStatRow(
                      label: strings[AppLocalization.total_earnings] ?? 'Earnings',
                      value: '﷼${_formatEarnings(stats.totalEarnings)}',
                      valueColor: context.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildRing(BuildContext context, double pct) {
    final color = pct >= 80
        ? context.successColor
        : pct >= 50
            ? context.warningColor
            : context.errorColor;

    return SizedBox(
      width: 90.w,
      height: 90.h,
      child: CustomPaint(
        painter: _RingProgressPainter(
          progress: (pct / 100).clamp(0.0, 1.0),
          color: color,
          backgroundColor: context.dividerColor.withValues(alpha: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: AppTextStyles.titleLarge(
                  color: context.textPrimaryColor,
                ),
              ),
              Text(
                'Rate',
                style: AppTextStyles.caption(
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEarnings(int cents) {
    final dollars = cents / 100;
    if (dollars >= 1000) return '${(dollars / 1000).toStringAsFixed(1)}k';
    return dollars.toStringAsFixed(0);
  }
}

class _PerformanceStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PerformanceStatRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall(
            color: context.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelLarge(
            color: valueColor ?? context.textPrimaryColor,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RingProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 12.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = backgroundColor;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter old) =>
      old.progress != progress || old.color != color;
}

// ============================================================================
// MONTHLY BOOKING TRENDS
// ============================================================================

class _BookingTrendsCard extends StatelessWidget {
  final List<MonthlyTrend> trends;
  final Map<String, String> strings;

  const _BookingTrendsCard({required this.trends, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 22.sp, color: context.primaryColor),
              Gap(AppSpacing.xs.w),
              Text(
                strings[AppLocalization.monthly_trends] ?? 'Monthly Trends',
                style: AppTextStyles.titleMedium(
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          Gap(AppSpacing.sm.h),
          _LegendRow(),
          Gap(AppSpacing.md.h),
          if (trends.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl.h),
              child: Center(
                child: Text(
                  strings[AppLocalization.no_data_yet] ?? 'No data yet',
                  style: AppTextStyles.bodyMedium(
                    color: context.textMutedColor,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200.h,
              child: CustomPaint(
                painter: _BookingBarChartPainter(
                  trends: trends,
                  bookingsColor: context.primaryColor.withValues(alpha: 0.75),
                  completedColor: context.successColor.withValues(alpha: 0.75),
                  cancelledColor: context.errorColor.withValues(alpha: 0.75),
                  gridColor: context.dividerColor,
                  textColor: context.textSecondaryColor,
                ),
                size: Size.infinite,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.08, end: 0);
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(Localizations.localeOf(context).languageCode);
    return Row(
      children: [
        _LegendItem(
          color: context.primaryColor.withValues(alpha: 0.75),
          label: strings[AppLocalization.bookings] ?? 'Bookings',
        ),
        Gap(AppSpacing.md.w),
        _LegendItem(
          color: context.successColor.withValues(alpha: 0.75),
          label: strings[AppLocalization.completed] ?? 'Completed',
        ),
        Gap(AppSpacing.md.w),
        _LegendItem(
          color: context.errorColor.withValues(alpha: 0.75),
          label: strings[AppLocalization.cancelled] ?? 'Cancelled',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10.w,
          height: 10.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        Gap(AppSpacing.xxs.w),
        Text(
          label,
          style: AppTextStyles.caption(
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

class _BookingBarChartPainter extends CustomPainter {
  final List<MonthlyTrend> trends;
  final Color bookingsColor;
  final Color completedColor;
  final Color cancelledColor;
  final Color gridColor;
  final Color textColor;

  _BookingBarChartPainter({
    required this.trends,
    required this.bookingsColor,
    required this.completedColor,
    required this.cancelledColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trends.isEmpty) return;

    final padding = 10.0;
    final bottomPadding = 30.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - bottomPadding;
    final groupWidth = chartWidth / trends.length;
    final barWidth = (groupWidth * 0.65) / 3;
    final groupPadding = groupWidth * 0.175;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(padding, chartHeight),
      Offset(size.width - padding, chartHeight),
      gridPaint,
    );

    final maxVal = trends.fold<int>(
      1,
      (max, t) => [max, t.bookings, t.completed, t.cancelled]
          .reduce(math.max),
    );

    final barRadius = Radius.circular(3.r);

    for (int i = 0; i < trends.length; i++) {
      final trend = trends[i];
      final x = padding + i * groupWidth + groupPadding;

      final bars = [
        (value: trend.bookings, color: bookingsColor),
        (value: trend.completed, color: completedColor),
        (value: trend.cancelled, color: cancelledColor),
      ];

      for (int b = 0; b < bars.length; b++) {
        final h = (bars[b].value / maxVal) * chartHeight;
        final rect = Rect.fromLTWH(
          x + b * barWidth,
          chartHeight - h,
          barWidth - 2,
          h,
        );
        final paint = Paint()
          ..color = bars[b].color
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: barRadius,
            topRight: barRadius,
          ),
          paint,
        );
      }

      final monthLabel = _shortMonth(trends[i].month);
      final textPainter = TextPainter(
        text: TextSpan(
          text: monthLabel,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + (groupWidth / 2) - (textPainter.width / 2),
          chartHeight + 8,
        ),
      );
    }
  }

  String _shortMonth(String ym) {
    final parts = ym.split('-');
    if (parts.length != 2) return ym;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'J', 'F', 'M', 'A', 'M', 'J',
      'J', 'A', 'S', 'O', 'N', 'D',
    ];
    return months[month - 1];
  }

  @override
  bool shouldRepaint(covariant _BookingBarChartPainter old) =>
      old.trends != trends;
}

// ============================================================================
// SHIMMER LOADING
// ============================================================================

class _AnalyticsShimmer extends StatelessWidget {
  const _AnalyticsShimmer();

  @override
  Widget build(BuildContext context) {
    final base = context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight;
    final highlight = context.isDark ? AppColors.skeletonHighlightDark : AppColors.skeletonHighlightLight;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.md.w),
        children: [
          _shimmerRow(context, 2),
          Gap(AppSpacing.sm.h),
          _shimmerRow(context, 2),
          Gap(AppSpacing.md.h),
          _shimmerCard(context, 240),
          Gap(AppSpacing.md.h),
          _shimmerCard(context, 180),
          Gap(AppSpacing.md.h),
          _shimmerCard(context, 260),
        ],
      ),
    );
  }

  Widget _shimmerRow(BuildContext context, int count) {
    return Row(
      children: List.generate(
        count,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i > 0 ? AppSpacing.sm.w : 0,
            ),
            child: _shimmerCard(context, 100),
          ),
        ),
      ),
    );
  }

  Widget _shimmerCard(BuildContext context, double height) {
    return Container(
      height: height.h,
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.skeletonBaseDark : AppColors.skeletonBaseLight,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
      ),
    );
  }
}
