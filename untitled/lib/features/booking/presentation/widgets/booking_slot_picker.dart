import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/shared/widgets/widgets.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/models/user_model.dart';

class BookingTimePicker extends ConsumerWidget {
  final DateTime selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<AvailabilitySlot> availability;
  final List<BookingModel> existingBookings;
  final bool isLoading;
  final bool isRebook;
  final String? timeAvailabilityMsg;
  final String? excludeBookingId;
  final ValueChanged<TimeOfDay> onPickStart;
  final ValueChanged<TimeOfDay> onPickEnd;
  final VoidCallback? onClearTimes;

  const BookingTimePicker({
    super.key,
    required this.selectedDate,
    required this.availability,
    required this.existingBookings,
    this.startTime,
    this.endTime,
    this.isLoading = false,
    this.isRebook = false,
    this.timeAvailabilityMsg,
    this.excludeBookingId,
    required this.onPickStart,
    required this.onPickEnd,
    this.onClearTimes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider).code;
    final strings = AppLocalization.get(locale);
    final ranges = availableTimeRangesForDate(selectedDate, availability, existingBookings, excludeBookingId: excludeBookingId);

    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (ranges.isEmpty) {
      return _buildEmptyState(context, strings);
    }

    final availMsg = timeAvailabilityMsg;
    final hasAvailabilityIssue = availMsg != null && availMsg.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAvailabilityIssue)
          _buildUnavailableTimeCard(context, strings, onClearTimes: onClearTimes)
        else
          _buildRangesIndicator(context, strings, locale, ranges),
        SizedBox(height: AppSpacing.md),
        if (hasAvailabilityIssue) ...[
          Row(
            children: [
              Expanded(
                  child: _buildTimePickerRow(
                    context,
                    strings,
                    locale: locale,
                    label: strings[AppLocalization.start_time] ?? 'Start Time',
                    icon: Icons.play_arrow_rounded,
                    time: startTime,
                    hasConflict: true,
                    onTap: () => _pickTime(context, strings, ranges, isStart: true),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildTimePickerRow(
                    context,
                    strings,
                    locale: locale,
                    label: strings[AppLocalization.end_time] ?? 'End Time',
                    icon: Icons.stop_rounded,
                    time: endTime,
                    hasConflict: true,
                    onTap: startTime == null
                        ? null
                        : () => _pickTime(context, strings, ranges, isStart: false),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerRow(
                    context,
                    strings,
                    locale: locale,
                    label: strings[AppLocalization.start_time] ?? 'Start Time',
                    icon: Icons.play_arrow_rounded,
                    time: startTime,
                    onTap: () => _pickTime(context, strings, ranges, isStart: true),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildTimePickerRow(
                    context,
                    strings,
                    locale: locale,
                    label: strings[AppLocalization.end_time] ?? 'End Time',
                    icon: Icons.stop_rounded,
                    time: endTime,
                    onTap: startTime == null
                        ? null
                        : () => _pickTime(context, strings, ranges, isStart: false),
                  ),
              ),
            ],
          ),
          if (startTime != null && endTime != null) ...[
            SizedBox(height: AppSpacing.sm),
            _buildSelectedSummary(context, strings, locale: locale),
          ],
        ],
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildRangesIndicator(
    BuildContext context,
    Map<String, String> strings,
    String locale,
    List<TimeRange> ranges,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: AppSpacing.xs),
              Text(
                strings[AppLocalization.calendar_available_slots] ?? 'Available Times',
                style: AppTextStyles.labelMedium(
                  weight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ...ranges.map((r) => _rangeChip(context, r, locale)),
        ],
      ),
    );
  }

  Widget _rangeChip(BuildContext context, TimeRange range, String locale) {
    final startTime = '${(range.startMinutes ~/ 60).toString().padLeft(2, '0')}:${(range.startMinutes % 60).toString().padLeft(2, '0')}';
    final endTime = '${(range.endMinutes ~/ 60).toString().padLeft(2, '0')}:${(range.endMinutes % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: AppColors.success),
          SizedBox(width: 6),
          Text(
            TimeFormatter.formatTimeRange(startTime, endTime, locale),
            style: AppTextStyles.caption(color: context.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerRow(
    BuildContext context,
    Map<String, String> strings, {
    required String locale,
    required String label,
    required IconData icon,
    required TimeOfDay? time,
    required VoidCallback? onTap,
    bool hasConflict = false,
  }) {
    final hasTime = time != null;
    final isDisabled = onTap == null;
    final conflictColor = AppColors.error;
    final normalColor = hasTime ? AppColors.success : (isDisabled ? context.textMuted : AppColors.primary);

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: hasConflict
              ? conflictColor.withValues(alpha: 0.06)
              : (hasTime
                  ? AppColors.success.withValues(alpha: 0.06)
                  : context.cardColor),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasConflict
                ? conflictColor.withValues(alpha: 0.3)
                : (hasTime
                    ? AppColors.success.withValues(alpha: 0.3)
                    : (isDisabled
                        ? context.borderColor.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.3))),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hasConflict
                    ? conflictColor.withValues(alpha: 0.12)
                    : (hasTime
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                hasConflict ? Icons.warning_amber_rounded : (hasTime ? Icons.check_rounded : icon),
                size: 16,
                color: hasConflict ? conflictColor : normalColor,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption(
                      color: isDisabled ? context.textMuted : context.textPrimary,
                    ),
                  ),
                  Text(
                    hasTime ? formatTime(time, locale: locale) : (strings[AppLocalization.tap_to_select] ?? 'Tap to select'),
                    style: AppTextStyles.titleSmall(
                      weight: FontWeight.w600,
                      color: hasConflict ? conflictColor : (hasTime ? AppColors.success : (isDisabled ? context.textMuted : context.textPrimary)),
                    ),
                  ),
                ],
              ),
            ),
            if (hasTime)
              GestureDetector(
                onTap: onClearTimes,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                ),
              ),
            if (!hasTime && !isDisabled)
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSummary(BuildContext context, Map<String, String> strings, {required String locale}) {
    final dur = durationHours(startTime, endTime);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatTime(startTime!, locale: locale)} - ${formatTime(endTime!, locale: locale)}',
                  style: AppTextStyles.titleSmall(weight: FontWeight.w700, color: context.textPrimary),
                ),
                if (dur > 0)
                  Text(
                    '$dur ${dur == 1 ? strings[AppLocalization.hour] ?? 'hour' : strings[AppLocalization.hours] ?? 'hours'}',
                    style: AppTextStyles.caption(color: AppColors.success),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Checking availability...',
              style: AppTextStyles.caption(color: context.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Map<String, String> strings) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.block_rounded, size: 24, color: AppColors.error.withValues(alpha: 0.6)),
          SizedBox(height: AppSpacing.sm),
          Text(
            strings[AppLocalization.calendar_no_slots] ?? 'No available time slots.',
            style: AppTextStyles.bodySmall(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableTimeCard(
    BuildContext context,
    Map<String, String> strings, {
    VoidCallback? onClearTimes,
  }) {
    final msg = timeAvailabilityMsg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  strings[AppLocalization.time_unavailable] ?? 'Time Not Available',
                  style: AppTextStyles.labelMedium(
                    weight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          if (msg != null && msg.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                msg,
                style: AppTextStyles.bodySmall(color: context.textPrimary),
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.warning),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isRebook && onClearTimes != null
                        ? (strings[AppLocalization.rebook_time_not_available] ??
                            'The pre-filled time from your previous booking is no longer available. Pick a new time from the options below or choose a different date.')
                        : (strings[AppLocalization.edit_and_resubmit] ??
                            'Clear the current time and pick from available slots below, or choose a different date.'),
                    style: AppTextStyles.caption(color: context.textMuted),
                  ),
                ),
              ],
            ),
          ),
          if (onClearTimes != null) ...[
            SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onClearTimes,
                icon: Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                label: Text(
                  strings[AppLocalization.pick_new_time] ?? 'Pick a New Time',
                  style: AppTextStyles.labelSmall(weight: FontWeight.w600, color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    Map<String, String> strings,
    List<TimeRange> ranges, {
    required bool isStart,
  }) async {
    final initial = isStart
        ? (startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (endTime ?? const TimeOfDay(hour: 17, minute: 0));

    final picked = await showTimePicker(
      context: Navigator.of(context).context,
      initialTime: initial,
    );

    if (picked == null || !context.mounted) return;

    final pickedMins = picked.hour * 60 + picked.minute;

    if (isStart) {
      final isValid = ranges.any((r) =>
          pickedMins >= r.startMinutes && pickedMins < r.endMinutes);
      if (!isValid) {
        _showSnackBar(
          context,
          strings[AppLocalization.time_unavailable] ?? 'Selected time is not within available hours.',
        );
        return;
      }
      onPickStart(picked);
    } else {
      final startMins = startTime!.hour * 60 + startTime!.minute;
      final isValid = ranges.any((r) =>
          pickedMins > startMins &&
          pickedMins <= r.endMinutes &&
          startMins >= r.startMinutes &&
          pickedMins - startMins >= 60);
      if (!isValid) {
        final durationValid = pickedMins - startMins >= 60;
        final withinAnyRange = ranges.any((r) => pickedMins <= r.endMinutes && pickedMins > r.startMinutes);
        String msg;
        if (!durationValid) {
          msg = strings[AppLocalization.booking_min_1hour] ?? 'Minimum booking duration is 1 hour.';
        } else if (withinAnyRange) {
          msg = strings[AppLocalization.time_unavailable] ?? 'The selected time range spans across a booked period. Please choose a continuous available time slot.';
        } else {
          msg = strings[AppLocalization.time_unavailable] ?? 'Selected time is not within available hours.';
        }
        _showSnackBar(context, msg);
        return;
      }
      onPickEnd(picked);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    AppSnackbar.warning(context, message);
  }
}
