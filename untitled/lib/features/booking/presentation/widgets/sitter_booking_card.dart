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
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/features/booking/data/booking_helpers.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/features/booking/data/booking_repository.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class SitterBookingCard extends ConsumerWidget {
  final BookingModel booking;

  const SitterBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings =
        AppLocalization.get(ref.watch(languageProvider).code);
    final locale = ref.watch(languageProvider).code;
    final statusColor = BookingHelpers.statusColor(booking.status);
    final name = booking.customer?.name ??
        'Customer #${booking.id}';
    final performAction = ref.read(bookingActionProvider);
    final repo = ref.read(bookingRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        type: MaterialType.transparency,
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
                              Flexible(
                                child: Text(
                                  '${DateFormat('MMM d, yyyy', locale).format(booking.date)} • ${TimeFormatter.formatTimeRange(booking.startTime, booking.endTime, locale)}',
                                  style: AppTextStyles.bodySmall(
                                    color: context.textMutedColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (booking.isMultiDay) ...[
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
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
                if (booking.status == BookingStatus.pending) ...[
                  const SizedBox(height: AppSpacing.xxs),
                ],
                if (booking.status == BookingStatus.confirmed) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: strings['mark_completed'] ?? 'Mark Completed',
                          onPressed: () => _completeBooking(context, ref, performAction, repo),
                          variant: AppButtonVariant.filled,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        text: strings[AppLocalization.chat] ?? 'Chat',
                        onPressed: () => _openChat(context),
                        variant: AppButtonVariant.outlined,
                      ),
                    ],
                  ),
                ],
                if (booking.status == BookingStatus.cancelled &&
                    booking.cancellationReason != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoBanner(
                    message: booking.cancellationReason!,
                    color: AppColors.error,
                  ),
                ],
                if (booking.status == BookingStatus.rejected &&
                    booking.rejectionReason != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InfoBanner(
                    message: booking.rejectionReason!,
                    color: AppColors.error,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 12, color: context.textMutedColor),
                    const SizedBox(width: 4),
                    Text(
                      '#${booking.id}',
                      style: AppTextStyles.labelSmall(
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusText(BookingStatus status, Map<String, String> strings) {
    switch (status) {
      case BookingStatus.pending:
        return strings[AppLocalization.pending] ?? 'Pending';
      case BookingStatus.confirmed:
        return strings[AppLocalization.confirmed] ?? 'Confirmed';
      case BookingStatus.completed:
        return strings[AppLocalization.completed] ?? 'Completed';
      case BookingStatus.cancelled:
        return strings[AppLocalization.cancelled] ?? 'Cancelled';
      case BookingStatus.rejected:
        return strings[AppLocalization.rejected] ?? 'Rejected';
      case BookingStatus.expired:
        return strings[AppLocalization.expired] ?? 'Expired';
      case BookingStatus.inProgress:
        return strings[AppLocalization.in_progress] ?? 'In Progress';
    }
  }

  Future<void> _completeBooking(BuildContext context, WidgetRef ref,
      Function performAction, BookingRepository repo) async {
    await performAction(booking.id, () async {
      return repo.completeBooking(booking.id);
    });
  }

  void _openChat(BuildContext context) {
    final customerId = booking.customer?.id;
    if (customerId != null) {
      context.push('${AppRoutes.chat}?userId=$customerId&bookingId=${booking.id}');
    }
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

