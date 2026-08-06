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
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/features/booking/data/booking_helpers.dart';
import 'package:babysitter/shared/models/booking_model.dart';

class BookingCard extends ConsumerWidget {
  final BookingModel booking;

  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings =
        AppLocalization.get(ref.watch(languageProvider).code);
    final isDark = context.isDark;
    final statusColor = BookingHelpers.statusColor(booking.status);
    final name = booking.sitter?.name ??
        booking.customer?.name ??
        'Booking #${booking.id}';
    final locale = ref.watch(languageProvider).code;
    final isMultiDay = booking.isMultiDay;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
          onTap: () {
            context.push('/booking/${booking.id}');
          },
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
              boxShadow: AppShadows.of(context),
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
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        BookingHelpers.statusIcon(booking.status),
                        size: 22,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.titleMedium(
                                weight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 11,
                                  color: context.textMutedColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  DateFormat('MMM d, yyyy', locale)
                                      .format(booking.date),
                                  style: AppTextStyles.bodySmall(
                                      color: context.textMutedColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isMultiDay) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.date_range_rounded,
                                    size: 11,
                                    color: AppColors.primary),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${booking.totalAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.titleSmall(
                            weight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppRadius.full),
                          ),
                          child: Text(
                            _statusText(booking.status, strings),
                            style: AppTextStyles.labelSmall(
                              color: statusColor,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isMultiDay) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.full),
                            ),
                            child: Text(
                              strings['multi_day_badge'] ?? 'Multi-Day',
                              style: AppTextStyles.labelSmall(
                                color: AppColors.primary,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (booking.isSessionActive) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6,
                                    color: AppColors.success),
                                const SizedBox(width: 3),
                                Text(
                                  strings['session_active'] ??
                                      'Live',
                                  style: AppTextStyles.labelSmall(
                                    color: AppColors.success,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark
                        ? context.surfaceColor
                            .withValues(alpha: 0.3)
                        : context.surfaceColor
                            .withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _infoChip(
                          Icons.schedule_rounded,
                          BookingHelpers.formatTimeRange(booking.startTime, booking.endTime, locale: locale),
                          context),
                      if (booking.childrenCount != null)
                        _infoChip(
                            Icons.people_outline,
                            '${booking.childrenCount} ${strings['children'] ?? 'kids'}',
                            context),
                      if (booking.duration > 0)
                        Text(
                          '${booking.duration} ${booking.duration == 1 ? (strings['hour'] ?? 'hr') : (strings['hours'] ?? 'hrs')}',
                          style: AppTextStyles.bodySmall(
                            color: context.textMutedColor,
                            weight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                _ReasonBanner(booking: booking, strings: strings),
                Row(
                  children: [
                    Text(
                      '#${booking.id}',
                      style: AppTextStyles.labelSmall(
                          color: context.textMutedColor),
                    ),
                    const Spacer(),
                    if (booking.updatedAt != null)
                      Text(
                        '${strings['last_updated'] ?? 'Updated'}: ${_formatDateTime(booking.updatedAt!, locale)}',
                        style: AppTextStyles.labelSmall(
                            color: context.textMutedColor),
                        maxLines: 1,
                      ),
                  ],
                ),
              ],
            ),
          ),
      ),
    );
  }

  Widget _infoChip(
      IconData icon, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.textMutedColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.bodySmall(
              color: context.textSecondaryColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _statusText(
      BookingStatus status, Map<String, String> strings) {
    return strings[BookingHelpers.statusLocalizationKey(status)] ??
        status.name;
  }

  String _formatDateTime(DateTime dt, String locale) {
    return '${DateFormat('MMM d', locale).format(dt)} • ${TimeFormatter.formatTimeString('${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}', locale)}';
  }
}

class _ReasonBanner extends StatelessWidget {
  final BookingModel booking;
  final Map<String, String> strings;

  const _ReasonBanner({required this.booking, required this.strings});

  @override
  Widget build(BuildContext context) {
    final isPastDue = booking.isPastDue && booking.status == BookingStatus.pending;

    if (isPastDue) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.textMutedLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_off_rounded,
                  size: 14, color: AppColors.textMutedLight),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  strings['expired_reason_label'] ??
                      'Expired — booking time has passed',
                  style: AppTextStyles.caption(
                    color: AppColors.textMutedLight,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (booking.status == BookingStatus.cancelled && booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${strings['cancelled_reason_label'] ?? 'Cancelled'}: ${booking.cancellationReason!}',
                  style: AppTextStyles.caption(
                    color: AppColors.error,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (booking.status == BookingStatus.rejected && booking.rejectionReason != null && booking.rejectionReason!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${strings['rejected_reason_label'] ?? 'Rejected'}: ${booking.rejectionReason!}',
                  style: AppTextStyles.caption(
                    color: AppColors.error,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
