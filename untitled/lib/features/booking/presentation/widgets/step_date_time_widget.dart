import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/features/booking/data/booking_flow_notifier.dart';
import 'package:babysitter/features/booking/presentation/widgets/widgets.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';
import 'package:babysitter/shared/models/models.dart';


class StepDateTimeWidget extends ConsumerWidget {
  final String sitterId;
  final dynamic sitter;
  final BookingFlowState flowState;
  final Map<String, String> strings;
  final void Function(DateTime) onDateSelected;
  final Widget guidanceWidget;
  final Widget dateSummaryWidget;
  final Widget validationMessage;
  final Widget? topBanner;
  final Set<String> selectedDateKeys;
  final Map<String, PerDateTimeOverride> perDateTimes;
  final void Function(String dateKey, TimeOfDay start, TimeOfDay end) onSetPerDateTime;
  final void Function(String dateKey) onClearPerDateTime;

  const StepDateTimeWidget({
    super.key,
    required this.sitterId,
    required this.sitter,
    required this.flowState,
    required this.strings,
    required this.onDateSelected,
    required this.guidanceWidget,
    required this.dateSummaryWidget,
    required this.validationMessage,
    this.topBanner,
    required this.selectedDateKeys,
    required this.perDateTimes,
    required this.onSetPerDateTime,
    required this.onClearPerDateTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = sitter.babysitterProfile?.availability ?? [];
    final notifier = ref.read(bookingFlowProvider(sitterId).notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topBanner != null) topBanner!,
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookingDatePicker(
                  selectedDate: flowState.selectedDate,
                  selectedDateKeys: selectedDateKeys,
                  availability: availability,
                  existingBookings: flowState.existingBookings,
                  excludeBookingId: flowState.editBookingId,
                  onDateSelected: onDateSelected,
                ),
                SizedBox(height: AppSpacing.sm),
                guidanceWidget,
                SizedBox(height: AppSpacing.md),
                dateSummaryWidget,
                SizedBox(height: AppSpacing.sectionSpacing),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 16.sp, color: AppColors.primary),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      strings[AppLocalization.pick_time] ?? 'Select Time',
                      style: AppTextStyles.titleSmall(weight: FontWeight.w600, color: context.textPrimary),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                BookingTimePicker(
                  selectedDate: flowState.selectedDate,
                  availability: availability,
                  existingBookings: flowState.existingBookings,
                  excludeBookingId: flowState.editBookingId,
                  startTime: flowState.startTime,
                  endTime: flowState.endTime,
                  isLoading: flowState.isLoadingBookings,
                  isRebook: flowState.isRebook,
                  timeAvailabilityMsg: flowState.timeAvailabilityMsg,
                  onPickStart: (time) {
                    notifier.setStartTime(time);
                    final end = flowState.endTime;
                    if (end != null) {
                      notifier.setEndTime(end);
                      final ranges = availableTimeRangesForDate(
                        flowState.selectedDate,
                        availability,
                        flowState.existingBookings,
                        excludeBookingId: flowState.editBookingId,
                      );
                      notifier.validateSpanAgainstRanges(ranges);
                    }
                  },
                  onPickEnd: (time) {
                    notifier.setEndTime(time);
                    final ranges = availableTimeRangesForDate(
                      flowState.selectedDate,
                      availability,
                      flowState.existingBookings,
                      excludeBookingId: flowState.editBookingId,
                    );
                    notifier.validateSpanAgainstRanges(ranges);
                  },
                  onClearTimes: () => notifier.clearTimes(),
                ),
                validationMessage,
                if (selectedDateKeys.length > 1) ...[
                  SizedBox(height: AppSpacing.sectionSpacing),
                  _buildDefaultTimeCard(context),
                  SizedBox(height: AppSpacing.sm),
                  Divider(color: context.dividerColor, height: 1),
                  SizedBox(height: AppSpacing.sm),
                  _PerDateOverridePanel(
                    selectedDateKeys: selectedDateKeys,
                    perDateTimes: perDateTimes,
                    onSetPerDateTime: onSetPerDateTime,
                    onClearPerDateTime: onClearPerDateTime,
                    strings: strings,
                    defaultStartTime: flowState.startTime,
                    defaultEndTime: flowState.endTime,
                    availability: availability,
                    existingBookings: flowState.existingBookings,
                    excludeBookingId: flowState.editBookingId,
                  ).animate().fadeIn(),
                ],
                SizedBox(height: AppSpacing.sectionSpacing),
                BookingBookedSlots(
                  existingBookings: flowState.existingBookings,
                  selectedDate: flowState.selectedDate,
                ),
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultTimeCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.access_time_rounded, size: 18.sp, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings[AppLocalization.per_date_time_title] ?? 'Default Time',
                  style: AppTextStyles.titleSmall(weight: FontWeight.w600, color: context.textPrimary),
                ),
                SizedBox(height: 2.h),
                Text(
                  strings[AppLocalization.per_date_time_hint] ?? 'Applies to all selected dates',
                  style: AppTextStyles.caption(color: context.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerDateOverridePanel extends StatefulWidget {
  final Set<String> selectedDateKeys;
  final Map<String, PerDateTimeOverride> perDateTimes;
  final void Function(String dateKey, TimeOfDay start, TimeOfDay end) onSetPerDateTime;
  final void Function(String dateKey) onClearPerDateTime;
  final Map<String, String> strings;
  final TimeOfDay? defaultStartTime;
  final TimeOfDay? defaultEndTime;
  final List<AvailabilitySlot> availability;
  final List<BookingModel> existingBookings;
  final String? excludeBookingId;

  const _PerDateOverridePanel({
    required this.selectedDateKeys,
    required this.perDateTimes,
    required this.onSetPerDateTime,
    required this.onClearPerDateTime,
    required this.strings,
    required this.defaultStartTime,
    required this.defaultEndTime,
    required this.availability,
    required this.existingBookings,
    this.excludeBookingId,
  });

  @override
  State<_PerDateOverridePanel> createState() => _PerDateOverridePanelState();
}

class _PerDateOverridePanelState extends State<_PerDateOverridePanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final overrideCount =
        widget.selectedDateKeys.where((k) => widget.perDateTimes.containsKey(k)).length;
    final countStr = widget.selectedDateKeys.length.toString();
    final title = (widget.strings[AppLocalization.dates_count] ?? '{count} days')
        .replaceAll('{count}', countStr);

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 16.sp, color: AppColors.primary),
                SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium(
                    weight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: overrideCount > 0
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : context.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    countStr,
                    style: AppTextStyles.labelSmall(
                      color: overrideCount > 0 ? AppColors.primary : context.textMuted,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20.sp,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              children: widget.selectedDateKeys.map((dateKey) {
                final override = widget.perDateTimes[dateKey];
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PerDateCard(
                    dateKey: dateKey,
                    timeOverride: override,
                    strings: widget.strings,
                    defaultStartTime: widget.defaultStartTime,
                    defaultEndTime: widget.defaultEndTime,
                    onSetPerDateTime: widget.onSetPerDateTime,
                    onClearPerDateTime: widget.onClearPerDateTime,
                    availability: widget.availability,
                    existingBookings: widget.existingBookings,
                    excludeBookingId: widget.excludeBookingId,
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}

String _formatTimeMinutes(int minutes, String locale) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final time = DateTime(2000, 1, 1, h, m);
  try {
    return DateFormat.jm(locale).format(time);
  } catch (_) {
    return DateFormat.jm().format(time);
  }
}

class _PerDateCard extends StatelessWidget {
  final String dateKey;
  final PerDateTimeOverride? timeOverride;
  final Map<String, String> strings;
  final TimeOfDay? defaultStartTime;
  final TimeOfDay? defaultEndTime;
  final void Function(String dateKey, TimeOfDay start, TimeOfDay end) onSetPerDateTime;
  final void Function(String dateKey) onClearPerDateTime;
  final List<AvailabilitySlot> availability;
  final List<BookingModel> existingBookings;
  final String? excludeBookingId;

  const _PerDateCard({
    required this.dateKey,
    required this.timeOverride,
    required this.strings,
    required this.defaultStartTime,
    required this.defaultEndTime,
    required this.onSetPerDateTime,
    required this.onClearPerDateTime,
    required this.availability,
    required this.existingBookings,
    this.excludeBookingId,
  });

  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final initial = isStart
        ? (timeOverride?.startTime ?? defaultStartTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (timeOverride?.endTime ?? defaultEndTime ?? const TimeOfDay(hour: 17, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final currentOverride = timeOverride;
      final start = isStart ? picked : (currentOverride?.startTime ?? defaultStartTime);
      final end = isStart ? (currentOverride?.endTime ?? defaultEndTime) : picked;
      if (start != null && end != null) {
        onSetPerDateTime(dateKey, start, end);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = _parseDateKey(dateKey);
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat('EEEE, MMM d, yyyy', locale).format(date);
    final hasOverride = timeOverride != null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 90));

    final dayStatus = calendarDayStatusForDate(
      date, availability, existingBookings, today, maxDate,
      excludeBookingId: excludeBookingId,
    );
    final isUnavailable = dayStatus == DayStatus.fullyBooked || dayStatus == DayStatus.nonWorking;
    final isAvailable = dayStatus == DayStatus.available || dayStatus == DayStatus.partiallyBooked;

    final ranges = isAvailable
        ? availableTimeRangesForDate(
            date, availability, existingBookings,
            excludeBookingId: excludeBookingId,
          )
        : <TimeRange>[];

    final effectiveStartTime = timeOverride?.startTime ?? defaultStartTime;
    final effectiveEndTime = timeOverride?.endTime ?? defaultEndTime;

    final timeFits = effectiveStartTime != null && effectiveEndTime != null && ranges.isNotEmpty
        ? ranges.any((r) =>
            timeToMinutes(effectiveStartTime) >= r.startMinutes &&
            timeToMinutes(effectiveEndTime) <= r.endMinutes)
        : !isAvailable;

    final needsOverride = isAvailable && !timeFits;

    Color cardBg;
    Color borderColor;
    double borderAlpha;
    String? statusIconLabel;
    IconData statusIcon;
    Color statusIconColor;

    if (needsOverride) {
      cardBg = AppColors.warning.withValues(alpha: 0.05);
      borderColor = AppColors.warning;
      borderAlpha = 0.4;
      statusIcon = Icons.access_time_rounded;
      statusIconColor = AppColors.warning;
      statusIconLabel = strings[AppLocalization.default_time_unavailable] ?? 'Adjust Time';
    } else if (isUnavailable) {
      cardBg = context.dividerColor.withValues(alpha: 0.15);
      borderColor = context.dividerColor;
      borderAlpha = 0.6;
      statusIcon = Icons.block_rounded;
      statusIconColor = context.textMutedColor;
    } else if (hasOverride) {
      cardBg = context.cardColor;
      borderColor = AppColors.primary;
      borderAlpha = 0.25;
      statusIcon = Icons.tune_rounded;
      statusIconColor = AppColors.primary;
    } else {
      cardBg = context.cardColor;
      borderColor = AppColors.success;
      borderAlpha = 0.2;
      statusIcon = Icons.check_circle_rounded;
      statusIconColor = AppColors.success;
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: borderColor.withValues(alpha: borderAlpha),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                size: 18.sp,
                color: statusIconColor,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: AppTextStyles.labelLarge(
                            weight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        if (effectiveStartTime != null && effectiveEndTime != null)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                              '${formatTime(effectiveStartTime, locale: locale)} – ${formatTime(effectiveEndTime, locale: locale)}',
                              style: AppTextStyles.caption(
                                color: needsOverride ? AppColors.warning : context.textMuted,
                                weight: needsOverride ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        if (needsOverride && statusIconLabel != null)
                          Text(
                            statusIconLabel,
                            style: AppTextStyles.caption(
                              color: AppColors.warning,
                              weight: FontWeight.w600,
                            ),
                          ),
                        if (needsOverride)
                          const SizedBox(height: 2),
                      ],
                    ),
              ),
              if (hasOverride)
                SizedBox(
                  width: 32.w,
                  height: 32.w,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.close_rounded, size: 16.sp, color: context.textMuted),
                    onPressed: () => onClearPerDateTime(dateKey),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TimeChip(
                  label: strings[AppLocalization.start_time] ?? 'Start Time',
                  time: timeOverride?.startTime ?? defaultStartTime,
                  onTap: () => _pickTime(context, isStart: true),
                  isUnavailable: isUnavailable,
                  needsAttention: needsOverride,
                  locale: locale,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TimeChip(
                  label: strings[AppLocalization.end_time] ?? 'End Time',
                  time: timeOverride?.endTime ?? defaultEndTime,
                  onTap: () => _pickTime(context, isStart: false),
                  isUnavailable: isUnavailable,
                  needsAttention: needsOverride,
                  locale: locale,
                ),
              ),
            ],
          ),
          if (needsOverride) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: AppColors.warning.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              strings[AppLocalization.calendar_available_slots] ?? 'Available Slots',
              style: AppTextStyles.overline(color: AppColors.warning, weight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...ranges.map((r) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatTimeMinutes(r.startMinutes, locale)} – ${_formatTimeMinutes(r.endMinutes, locale)}',
                        style: AppTextStyles.caption(
                          color: context.textPrimary,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (!hasOverride && isUnavailable && !needsOverride)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                strings[AppLocalization.calendar_no_slots] ?? 'No slots available for this date.',
                style: AppTextStyles.caption(color: context.textMutedColor),
              ),
            ),
          if (!hasOverride && !isAvailable && !isUnavailable && !needsOverride)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                strings[AppLocalization.tap_to_select] ?? 'Tap to select',
                style: AppTextStyles.caption(color: context.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final bool isUnavailable;
  final bool needsAttention;
  final String locale;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.onTap,
    this.isUnavailable = false,
    this.needsAttention = false,
    this.locale = 'en',
  });

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    double bgAlpha;
    double borderAlpha;

    if (needsAttention) {
      chipColor = AppColors.warning;
      bgAlpha = 0.1;
      borderAlpha = 0.5;
    } else if (isUnavailable) {
      chipColor = context.textMutedColor;
      bgAlpha = 0.06;
      borderAlpha = 0.2;
    } else {
      chipColor = AppColors.primary;
      bgAlpha = 0.08;
      borderAlpha = 0.2;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: chipColor.withValues(alpha: borderAlpha)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (needsAttention) ...[
                  Icon(Icons.edit_rounded, size: 11.sp, color: chipColor),
                  SizedBox(width: 3.w),
                ],
                Text(
                  label,
                  style: AppTextStyles.overline(color: needsAttention ? chipColor : context.textMuted),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              time != null ? formatTime(time!, locale: locale) : '--:--',
              style: AppTextStyles.labelLarge(
                weight: FontWeight.w600,
                color: chipColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
