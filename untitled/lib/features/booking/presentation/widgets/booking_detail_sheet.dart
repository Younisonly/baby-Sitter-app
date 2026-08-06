import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/data/booking_provider.dart';
import 'package:babysitter/features/booking/data/booking_repository.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

Future<void> showBookingDetailSheet(
  BuildContext context,
  BookingModel booking,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BookingDetailSheet(booking: booking),
  );
}

class _BookingDetailSheet extends ConsumerStatefulWidget {
  final BookingModel booking;

  const _BookingDetailSheet({required this.booking});

  @override
  ConsumerState<_BookingDetailSheet> createState() =>
      _BookingDetailSheetState();
}

class _BookingDetailSheetState extends ConsumerState<_BookingDetailSheet> {
  bool _isCancelling = false;

  String _bookingTitle(BookingModel b) {
    return b.sitter?.name ?? b.customer?.name ?? 'Booking';
  }

  String _statusText(BookingStatus status, Map<String, String> strings) {
    switch (status) {
      case BookingStatus.pending:
        return strings[AppLocalization.pending] ?? 'Pending';
      case BookingStatus.confirmed:
        return strings[AppLocalization.confirmed] ?? 'Confirmed';
      case BookingStatus.inProgress:
        return strings[AppLocalization.in_progress] ?? 'In Progress';
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

  Color _statusColor(BookingStatus status) {
    switch (status) {
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

  bool get _canCancel {
    final status = widget.booking.status;
    return status == BookingStatus.pending ||
        status == BookingStatus.confirmed;
  }

  Future<void> _cancelWithConfirmation() async {
    final loc = AppLocalization.get(ref.read(languageProvider).code);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _CancelConfirmationSheet(booking: widget.booking),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    String? error;
    try {
      await ref.read(bookingActionProvider)(
        widget.booking.id,
        () => ref.read(bookingRepositoryProvider).cancelBooking(widget.booking.id),
      );
    } catch (e) {
      error = loc[AppLocalization.failed_to_cancel_booking] ?? 'Failed to cancel booking. Please try again.';
    }
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(
          context,
          loc[AppLocalization.booking_cancelled_successfully] ??
              'Booking cancelled successfully');
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider).code;
    final strings = AppLocalization.get(locale);
    final b = widget.booking;
    final statusColor = _statusColor(b.status);
    final isDark = context.isDark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        statusColor.withValues(alpha: 0.12),
                    child: Icon(
                      _statusIcon(b.status),
                      size: 28,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bookingTitle(b),
                          style: AppTextStyles.titleLarge(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          _statusText(b.status, strings),
                          style: AppTextStyles.bodyMedium(
                            color: statusColor,
                            weight: FontWeight.w600,
                          ),
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
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '﷼${b.totalAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.titleMedium(
                        color: statusColor,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceOverlayDark
                      : AppColors.primaryUltraLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    _detailRow(
                      Icons.calendar_today_rounded,
                      strings[AppLocalization.date] ?? 'Date',
                      _formatDate(b.date),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _detailRow(
                      Icons.schedule_rounded,
                      strings[AppLocalization.time] ?? 'Time',
                      TimeFormatter.formatTimeRange(b.startTime, b.endTime, locale),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _detailRow(
                      Icons.timer_outlined,
                      strings[AppLocalization.duration] ?? 'Duration',
                      '${b.duration} ${b.duration > 1 ? (strings['hours'] ?? 'hrs') : (strings['hour'] ?? 'hr')}',
                    ),
                    if (b.childrenCount != null) ...[
                      SizedBox(height: AppSpacing.sm),
                      _detailRow(
                        Icons.people_outline,
                        strings[AppLocalization.children] ?? 'Children',
                        '${b.childrenCount} ${strings['children'] ?? 'children'}',
                      ),
                    ],
                    if (b.address != null && b.address!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.sm),
                      _detailRow(
                        Icons.location_on_outlined,
                        strings[AppLocalization.address] ?? 'Address',
                        b.address!,
                      ),
                    ],
                  ],
                ),
              ),
              if (b.notes != null && b.notes!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceOverlayDark
                        : AppColors.primaryUltraLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings[AppLocalization.notes] ?? 'Notes',
                        style: AppTextStyles.labelLarge(
                          weight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      Text(
                        b.notes!,
                        style: AppTextStyles.bodyMedium(),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              if (b.cancellationReason != null &&
                  b.cancellationReason!.isNotEmpty) ...[
                SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings[AppLocalization.cancellation_reason] ??
                            'Cancellation Reason',
                        style: AppTextStyles.labelLarge(
                          color: AppColors.error,
                          weight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      Text(
                        b.cancellationReason!,
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.error,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.lg),
              AppButton(
                text: _isCancelling
                    ? (strings[AppLocalization.cancelling] ?? 'Cancelling...')
                    : (strings[AppLocalization.cancel_booking] ??
                        'Cancel Booking'),
                onPressed:
                    _canCancel && !_isCancelling ? _cancelWithConfirmation : null,
                variant: AppButtonVariant.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.textSecondary),
        SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.bodyMedium(
            color: context.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium(
              weight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
        return Icons.check_circle_outline;
      case BookingStatus.cancelled:
        return Icons.cancel_rounded;
      case BookingStatus.rejected:
        return Icons.block_rounded;
      case BookingStatus.expired:
        return Icons.timer_off_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final locale = ref.watch(languageProvider).code;
    return DateFormat('MMM d, yyyy', locale).format(date);
  }
}

class _CancelConfirmationSheet extends ConsumerStatefulWidget {
  final BookingModel booking;

  const _CancelConfirmationSheet({required this.booking});

  @override
  ConsumerState<_CancelConfirmationSheet> createState() =>
      _CancelConfirmationSheetState();
}

class _CancelConfirmationSheetState
    extends ConsumerState<_CancelConfirmationSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cancel_outlined,
                size: 48,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              strings[AppLocalization.cancel_booking] ?? 'Cancel Booking',
              style: AppTextStyles.titleLarge(
                weight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              strings[AppLocalization.cancel_booking_confirmation] ??
                  'Are you sure you want to cancel this booking?',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(
                color: context.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _reasonController,
              label: strings[AppLocalization.reason_optional] ??
                  'Reason (optional)',
              hint: strings[AppLocalization.cancellation_hint] ??
                  'Tell us why you\'re cancelling',
              maxLines: 3,
            ),
            SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: strings[AppLocalization.keep_booking] ??
                        'Keep Booking',
                    onPressed: () => Navigator.pop(context, false),
                    variant: AppButtonVariant.outlined,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    text: strings[AppLocalization.cancel] ?? 'Cancel',
                    onPressed: () =>
                        Navigator.pop(context, true),
                    variant: AppButtonVariant.danger,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
