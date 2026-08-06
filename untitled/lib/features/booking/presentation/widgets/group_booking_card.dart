import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/booking_helpers.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';
import 'package:babysitter/shared/models/booking_model.dart';

class GroupBookingCard extends ConsumerStatefulWidget {
  final BookingGroupDisplayItem groupItem;

  const GroupBookingCard({super.key, required this.groupItem});

  @override
  ConsumerState<GroupBookingCard> createState() => _GroupBookingCardState();
}

class _GroupBookingCardState extends ConsumerState<GroupBookingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final item = widget.groupItem;
    final primary = item.primaryBooking;
    final statusColor = BookingHelpers.statusColor(primary.status);
    final name = item.sitter?.name ?? primary.customer?.name ?? 'Booking';
    final locale = ref.watch(languageProvider).code;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => context.push('/booking/${widget.groupItem.primaryBooking.id}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: AppShadows.of(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(strings, primary, statusColor, name, locale),
              const SizedBox(height: AppSpacing.sm),
              _buildDateRange(strings, item, locale),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoRow(item, strings, locale),
              if (_expanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Divider(color: context.dividerColor, height: 1),
                const SizedBox(height: AppSpacing.sm),
                ...item.children.where((b) => b.status != BookingStatus.cancelled).map((b) => _buildDayRow(b, strings, locale)),
                ..._buildCancelledSummary(item, strings, locale),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
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
              ),
            ],
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
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.date_range_rounded,
            size: 22,
            color: AppColors.primary,
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
                '${widget.groupItem.dayCount} ${strings['days'] ?? 'days'} • ${strings['multi_day_badge'] ?? 'Multi-Day'}',
                style: AppTextStyles.bodySmall(color: context.textMutedColor),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${widget.groupItem.totalAmount.toStringAsFixed(0)}',
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
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                _groupStatusText(widget.groupItem, strings),
                style: AppTextStyles.labelSmall(
                  color: statusColor,
                  weight: FontWeight.w600,
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
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, size: 15, color: AppColors.primary),
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

  Widget _buildInfoRow(
    BookingGroupDisplayItem item,
    Map<String, String> strings,
    String locale,
  ) {
    final primary = item.primaryBooking;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.isDark
            ? context.surfaceColor.withValues(alpha: 0.3)
            : context.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xxs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _infoChip(
            Icons.schedule_rounded,
            BookingHelpers.formatTimeRange(primary.startTime, primary.endTime, locale: locale),
            context,
          ),
          if (primary.childrenCount != null)
            _infoChip(
              Icons.people_outline,
              '${primary.childrenCount} ${strings['children'] ?? 'kids'}',
              context,
            ),
          if (primary.duration > 0)
            Text(
              '${primary.duration} ${primary.duration == 1 ? (strings['hour'] ?? 'hr') : (strings['hours'] ?? 'hrs')}',
              style: AppTextStyles.bodySmall(
                color: context.textMutedColor,
                weight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
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

  Widget _buildDayRow(BookingModel booking, Map<String, String> strings, String locale) {
    final isDayDone = booking.isDayDone;
    final isCancelled = booking.status == BookingStatus.cancelled;
    final displayStatus = isDayDone ? BookingStatus.completed : booking.status;
    final dayStatusColor = BookingHelpers.statusColor(displayStatus);
    final dayIcon = isDayDone ? Icons.check_circle_rounded : BookingHelpers.statusIcon(booking.status);
    final reasonText = isCancelled ? _cancellationReasonText(booking, strings) : null;
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: dayStatusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      dayIcon,
                      size: 16,
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
                            Text(
                              DateFormat('EEE, MMM d', locale).format(booking.date),
                              style: AppTextStyles.labelMedium(
                                weight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            if (isDayDone) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  strings['day_done'] ?? 'Done',
                                  style: AppTextStyles.labelSmall(
                                    color: AppColors.success,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          BookingHelpers.formatTimeRange(booking.startTime, booking.endTime, locale: locale),
                          style: AppTextStyles.caption(color: context.textMutedColor),
                        ),
                        if (reasonText != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 11, color: AppColors.error),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  reasonText,
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
                  Text(
                    '\$${booking.totalAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.labelMedium(
                      weight: FontWeight.w700,
                      color: dayStatusColor,
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

  Widget _infoChip(IconData icon, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.textMutedColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.bodySmall(color: context.textSecondaryColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  List<Widget> _buildCancelledSummary(BookingGroupDisplayItem item, Map<String, String> strings, String locale) {
    final cancelledDays = item.children.where((b) => b.status == BookingStatus.cancelled).toList();
    if (cancelledDays.isEmpty) return [];
    return cancelledDays.map((b) {
      final reason = _cancellationReasonText(b, strings);
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: InkWell(
          onTap: () => _showCancellationDialog(context, b, strings, locale),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 13, color: AppColors.error),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    '${DateFormat('MMM d', locale).format(b.date)} — $reason',
                    style: AppTextStyles.caption(color: AppColors.error, weight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.error.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  String _groupStatusText(BookingGroupDisplayItem item, Map<String, String> strings) {
    final allCompleted = item.children.every((b) => b.status == BookingStatus.completed);
    if (allCompleted) {
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
}