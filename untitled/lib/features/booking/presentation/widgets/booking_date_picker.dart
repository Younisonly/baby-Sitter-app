import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:intl/intl.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';
import 'package:babysitter/shared/models/booking_model.dart';
import 'package:babysitter/shared/models/user_model.dart';

class BookingDatePicker extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final Set<String> selectedDateKeys;
  final List<AvailabilitySlot> availability;
  final List<BookingModel> existingBookings;
  final String? excludeBookingId;
  final ValueChanged<DateTime> onDateSelected;

  const BookingDatePicker({
    super.key,
    required this.selectedDate,
    this.selectedDateKeys = const {},
    required this.availability,
    required this.existingBookings,
    this.excludeBookingId,
    required this.onDateSelected,
  });

  @override
  ConsumerState<BookingDatePicker> createState() => _BookingDatePickerState();
}

class _BookingDatePickerState extends ConsumerState<BookingDatePicker> {
  late int _currentYear;
  late int _currentMonth;
  late CalendarMonthData _monthData;
  late DateTime _today;
  late DateTime _maxDate;

  @override
  void initState() {
    super.initState();
    _initDates();
    _buildMonth();
  }

  @override
  void didUpdateWidget(BookingDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.selectedDateKeys != widget.selectedDateKeys ||
        oldWidget.availability != widget.availability ||
        oldWidget.existingBookings != widget.existingBookings) {
      _buildMonth();
    }
  }

  void _initDates() {
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _maxDate = _today.add(Duration(days: 90));
    _currentYear = widget.selectedDate.year;
    _currentMonth = widget.selectedDate.month;
  }

  void _buildMonth() {
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _maxDate = _today.add(Duration(days: 90));
    _monthData = buildCalendarMonth(
      _currentYear,
      _currentMonth,
      widget.selectedDate,
      widget.availability,
      widget.existingBookings,
      _today,
      _maxDate,
      excludeBookingId: widget.excludeBookingId,
      selectedDateKeys: widget.selectedDateKeys,
    );
  }

  void _goToPreviousMonth() {
    if (_currentMonth == 1) {
      setState(() {
        _currentYear--;
        _currentMonth = 12;
        _buildMonth();
      });
    } else {
      setState(() {
        _currentMonth--;
        _buildMonth();
      });
    }
  }

  void _goToNextMonth() {
    if (_currentMonth == 12) {
      setState(() {
        _currentYear++;
        _currentMonth = 1;
        _buildMonth();
      });
    } else {
      setState(() {
        _currentMonth++;
        _buildMonth();
      });
    }
  }

  bool get _canGoNext {
    final next = _currentMonth == 12
        ? DateTime(_currentYear + 1, 1, 1)
        : DateTime(_currentYear, _currentMonth + 1, 1);
    return !next.isAfter(_maxDate);
  }

  bool get _canGoPrevious {
    final prev = _currentMonth == 1
        ? DateTime(_currentYear - 1, 12, 1)
        : DateTime(_currentYear, _currentMonth - 1, 1);
    return !prev.isBefore(DateTime(_today.year, _today.month, 1));
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.selectedDateKeys.length;
    return Column(
      key: ValueKey('$_currentYear-$_currentMonth'),
      children: [
        _buildHeader(context),
        SizedBox(height: AppSpacing.sm),
        _buildWeekdayRow(context),
        SizedBox(height: AppSpacing.xs),
        _buildDayGrid(context),
        SizedBox(height: AppSpacing.sm),
        if (count > 1) _buildSelectionChip(context, count),
        SizedBox(height: AppSpacing.sm),
        _buildLegend(context),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSelectionChip(BuildContext context, int count) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    return AnimatedSwitcher(
      duration: 250.ms,
      child: Container(
        key: ValueKey('days-$count'),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, size: 14.sp, color: AppColors.primary),
            SizedBox(width: 4.w),
            Text(
              strings[AppLocalization.days_selected]?.replaceAll('{count}', '$count') ??
                  '$count days selected',
              style: AppTextStyles.labelMedium(
                weight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _canGoPrevious ? _goToPreviousMonth : null,
            child: AnimatedOpacity(
              opacity: _canGoPrevious ? 1.0 : 0.3,
              duration: 200.ms,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _canGoPrevious
                      ? context.cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: context.borderColor.withValues(alpha: _canGoPrevious ? 1.0 : 0.3),
                  ),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 22.sp,
                  color: context.textPrimary.withValues(alpha: _canGoPrevious ? 1.0 : 0.3),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: 250.ms,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Column(
              key: ValueKey('$_currentYear-$_currentMonth'),
              children: [
                Text(
                  _monthData.monthName,
                  style: AppTextStyles.titleLarge(
                    weight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$_currentYear',
                  style: AppTextStyles.bodySmall(
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _canGoNext ? _goToNextMonth : null,
            child: AnimatedOpacity(
              opacity: _canGoNext ? 1.0 : 0.3,
              duration: 200.ms,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _canGoNext
                      ? context.cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: context.borderColor.withValues(alpha: _canGoNext ? 1.0 : 0.3),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 22.sp,
                  color: context.textPrimary.withValues(alpha: _canGoNext ? 1.0 : 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow(BuildContext context) {
    final locale = ref.watch(languageProvider).code;
    return Row(
      children: List.generate(7, (index) {
        return Expanded(
          child: Center(
            child: Text(
              DateFormat('E', locale).format(DateTime(2024, 1, 6 + index)),
              style: AppTextStyles.labelSmall(
                weight: FontWeight.w600,
                color: context.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayGrid(BuildContext context) {
    return AnimatedSwitcher(
      duration: 300.ms,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey('grid-$_currentYear-$_currentMonth'),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
        ),
        padding: EdgeInsets.all(AppSpacing.xs),
        child: Column(
          children: [
            for (int row = 0; row < 6; row++)
              Padding(
                padding: EdgeInsets.only(bottom: row < 5 ? 2.h : 0),
                child: Row(
                  children: [
                    for (int col = 0; col < 7; col++)
                      Expanded(child: _buildDayCell(context, row * 7 + col)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(BuildContext context, int index) {
    if (index >= _monthData.days.length) return const SizedBox.shrink();

    final dayInfo = _monthData.days[index];
    final isCurrentMonth =
        dayInfo.date.month == _currentMonth && dayInfo.date.year == _currentYear;
    if (!isCurrentMonth) {
      return _buildOutOfRangeCell(context, dayInfo);
    }

    if (dayInfo.isSelected) {
      return _buildSelectedCell(context, dayInfo);
    }
    if (dayInfo.isToday) {
      return _buildTodayCell(context, dayInfo);
    }

    switch (dayInfo.status) {
      case DayStatus.fullyBooked:
        return _buildFullyBookedCell(context, dayInfo);
      case DayStatus.nonWorking:
        return _buildClosedCell(context, dayInfo);
      case DayStatus.past:
        return _buildPastCell(context, dayInfo);
      case DayStatus.outOfRange:
        return _buildOutOfRangeCell(context, dayInfo);
      case DayStatus.partiallyBooked:
        return _buildPartiallyBookedCell(context, dayInfo);
      case DayStatus.available:
        return _buildAvailableCell(context, dayInfo);
    }
  }

  Widget _buildAvailableCell(BuildContext context, CalendarDayInfo dayInfo) {
    return _cellWrapper(
      context,
      dayInfo,
      child: _cellContent(dayInfo, context.textPrimary, FontWeight.w600),
    );
  }

  Widget _buildSelectedCell(BuildContext context, CalendarDayInfo dayInfo) {
    final isPrimary = widget.selectedDateKeys.length > 1 &&
        isSameDay(dayInfo.date, widget.selectedDate);
    return _cellWrapper(
      context,
      dayInfo,
      onTap: dayInfo.isSelectable ? () => widget.onDateSelected(dayInfo.date) : null,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: 250.ms,
        child: Column(
          key: ValueKey('selected-${dayInfo.date.day}-${dayInfo.isSelected}-$isPrimary'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${dayInfo.date.day}',
              style: AppTextStyles.labelMedium(
                weight: FontWeight.w800,
                color: AppColors.white,
              ),
            ),
            if (isPrimary)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Container(
                  width: 16.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            if (!isPrimary && widget.selectedDateKeys.length > 1)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Container(
                  width: 12.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.85, 0.85),
      end: const Offset(1, 1),
      duration: 350.ms,
      curve: Curves.elasticOut,
    );
  }

  Widget _buildTodayCell(BuildContext context, CalendarDayInfo dayInfo) {
    return _cellWrapper(
      context,
      dayInfo,
      onTap: dayInfo.isSelectable ? () => widget.onDateSelected(dayInfo.date) : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${dayInfo.date.day}',
            style: AppTextStyles.labelMedium(
              weight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                AppLocalization.get(ref.watch(languageProvider).code)[AppLocalization.calendar_today] ?? 'Today',
                style: AppTextStyles.caption(
                  weight: FontWeight.w600,
                  color: AppColors.primary,
                ).copyWith(fontSize: 7.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartiallyBookedCell(BuildContext context, CalendarDayInfo dayInfo) {
    final capacityFraction = dayInfo.totalAvailableMinutes > 0
        ? dayInfo.remainingCapacityMinutes / dayInfo.totalAvailableMinutes
        : 0.0;
    final capColor = capacityFraction > 0.5
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    final remainingH = (dayInfo.remainingCapacityMinutes / 60).ceil();
    final totalH = (dayInfo.totalAvailableMinutes / 60).ceil();
    final pct = totalH > 0 ? (remainingH * 100 ~/ totalH) : 0;

    return _cellWrapper(
      context,
      dayInfo,
      onTap: dayInfo.isSelectable ? () => widget.onDateSelected(dayInfo.date) : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: capColor.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${dayInfo.date.day}',
                style: AppTextStyles.labelMedium(
                  weight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 18.w,
                      height: 2.h,
                      decoration: BoxDecoration(
                        color: context.dividerColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: pct / 100.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: capColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: -2.h,
            right: -2.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: capColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: capColor.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
              child: Text(
                '$remainingH/$totalH',
                style: AppTextStyles.caption(
                  weight: FontWeight.w800,
                  color: capColor,
                ).copyWith(fontSize: 6.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullyBookedCell(BuildContext context, CalendarDayInfo dayInfo) {
    return _cellWrapper(
      context,
      dayInfo,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${dayInfo.date.day}',
            style: AppTextStyles.labelMedium(
              weight: FontWeight.w500,
              color: AppColors.error.withValues(alpha: 0.6),
            ).copyWith(decoration: TextDecoration.lineThrough),
          ),
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Icon(
              Icons.block_rounded,
              size: 11.sp,
              color: AppColors.error.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedCell(BuildContext context, CalendarDayInfo dayInfo) {
    return _cellWrapper(
      context,
      dayInfo,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${dayInfo.date.day}',
            style: AppTextStyles.labelMedium(
              weight: FontWeight.w400,
              color: context.textMuted.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Container(
              width: 14.w,
              height: 2.h,
              decoration: BoxDecoration(
                color: AppColors.textHintLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastCell(BuildContext context, CalendarDayInfo dayInfo) {
    return _cellWrapper(
      context,
      dayInfo,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 10.sp,
            color: context.textMuted.withValues(alpha: 0.25),
          ),
          SizedBox(height: 1.h),
          Text(
            '${dayInfo.date.day}',
            style: AppTextStyles.labelMedium(
              weight: FontWeight.w300,
              color: context.textMuted.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutOfRangeCell(BuildContext context, CalendarDayInfo dayInfo) {
    return _cellWrapper(
      context,
      dayInfo,
      child: Center(
        child: Text(
          '${dayInfo.date.day}',
          style: AppTextStyles.labelMedium(
            weight: FontWeight.w300,
            color: context.textMuted.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  Widget _cellWrapper(
    BuildContext context,
    CalendarDayInfo dayInfo, {
    VoidCallback? onTap,
    Decoration? decoration,
    required Widget child,
  }) {
    final isCurrentMonth =
        dayInfo.date.month == _currentMonth && dayInfo.date.year == _currentYear;
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: (onTap ?? (dayInfo.isSelectable && isCurrentMonth
            ? () => widget.onDateSelected(dayInfo.date)
            : null)),
        child: AnimatedContainer(
          duration: 250.ms,
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.all(1.5.w),
          decoration: decoration ?? BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _cellContent(CalendarDayInfo dayInfo, Color textColor, FontWeight weight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${dayInfo.date.day}',
          style: AppTextStyles.labelMedium(
            weight: weight,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final legendItems = [
      _legendItem(context, AppColors.primary,
          strings[AppLocalization.calendar_selected] ?? 'Selected'),
      _legendItem(context, AppColors.primary.withValues(alpha: 0.5),
          strings[AppLocalization.calendar_today] ?? 'Today'),
      _legendItem(context, const Color(0xFFF59E0B),
          strings[AppLocalization.calendar_limited] ?? 'Limited'),
      _legendItem(context, AppColors.error,
          strings[AppLocalization.calendar_fully_booked] ?? 'Full'),
      _legendItem(context, AppColors.textHintLight,
          strings[AppLocalization.calendar_closed] ?? 'Closed'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        alignment: WrapAlignment.center,
        children: legendItems,
      ),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.labelSmall(
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
