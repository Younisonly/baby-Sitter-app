import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/features/booking/presentation/helpers/booking_helpers.dart';

class BookingScheduleEvents extends StatelessWidget {
  final List<ScheduleEventData> scheduleEvents;
  final Map<String, String> strings;
  final VoidCallback onAddEvent;
  final ValueChanged<int> onRemoveEvent;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onPickEventTime;
  final void Function(int index, String activity)? onActivityChanged;

  const BookingScheduleEvents({
    super.key,
    required this.scheduleEvents,
    required this.strings,
    required this.onAddEvent,
    required this.onRemoveEvent,
    required this.onReorder,
    required this.onPickEventTime,
    this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            strings['schedule_hint'] ??
                'Plan your child\'s day \u2014 add activities with times',
            style: AppTextStyles.caption(color: AppColors.textHintLight),
          ),
        ),
        if (scheduleEvents.isEmpty)
          GestureDetector(
            onTap: onAddEvent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, 1)),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.event_note_rounded,
                      size: 36.sp, color: AppColors.textHintLight),
                  SizedBox(height: AppSpacing.sm),
                  Text(strings['no_events'] ?? 'No events added yet',
                      style: AppTextStyles.bodyMedium(
                          color: AppColors.textHintLight)),
                  SizedBox(height: 2.h),
                  Text(strings['add_event_hint'] ?? 'Tap to plan the day',
                      style: AppTextStyles.caption(
                          color: AppColors.textHintLight)),
                ],
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scheduleEvents.length + 1,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              if (index == scheduleEvents.length) {
                return Padding(
                  key: const ValueKey('add_button'),
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: onAddEvent,
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.06),
                              blurRadius: 2,
                              offset: const Offset(0, 1)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 18.sp, color: AppColors.white),
                          SizedBox(width: AppSpacing.xs),
                          Text(strings['add_event'] ?? 'Add Event',
                              style: AppTextStyles.labelLarge(
                                  color: AppColors.white)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final event = scheduleEvents[index];
              return _ScheduleEventTile(
                key: ValueKey('event_$index'),
                event: event,
                index: index,
                strings: strings,
                onPickEventTime: onPickEventTime,
                onRemoveEvent: onRemoveEvent,
                onActivityChanged: onActivityChanged,
              );
            },
          ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 350.ms);
  }
}

class _ScheduleEventTile extends StatefulWidget {
  final ScheduleEventData event;
  final int index;
  final Map<String, String> strings;
  final ValueChanged<int> onPickEventTime;
  final ValueChanged<int> onRemoveEvent;
  final void Function(int index, String activity)? onActivityChanged;

  const _ScheduleEventTile({
    super.key,
    required this.event,
    required this.index,
    required this.strings,
    required this.onPickEventTime,
    required this.onRemoveEvent,
    this.onActivityChanged,
  });

  @override
  State<_ScheduleEventTile> createState() => _ScheduleEventTileState();
}

class _ScheduleEventTileState extends State<_ScheduleEventTile> {
  late TextEditingController _activityController;

  @override
  void initState() {
    super.initState();
    _activityController = TextEditingController(text: widget.event.activity);
    _activityController.addListener(_onActivityChanged);
  }

  @override
  void didUpdateWidget(_ScheduleEventTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event.activity != oldWidget.event.activity &&
        widget.event.activity != _activityController.text) {
      _activityController.text = widget.event.activity;
    }
  }

  @override
  void dispose() {
    _activityController.removeListener(_onActivityChanged);
    _activityController.dispose();
    super.dispose();
  }

  void _onActivityChanged() {
    final text = _activityController.text;
    final valueChanged = text != widget.event.activity;
    if (valueChanged) {
      widget.onActivityChanged?.call(widget.index, text);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final event = widget.event;
    final index = widget.index;
    return Container(
      key: ValueKey('event_$index'),
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Icon(Icons.drag_handle_rounded,
                  color: AppColors.textHintLight, size: 20.sp),
            ),
          ),
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.strings['time'] ?? 'Time',
                    style: AppTextStyles.caption(
                        color: AppColors.textHintLight)),
                SizedBox(height: 4.h),
                GestureDetector(
                  onTap: () => widget.onPickEventTime(index),
                  child: Container(
                    height: 48.h,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 14.sp, color: AppColors.white),
                        SizedBox(width: 4.w),
                        Text(
                          event.timeOfDay != null
                              ? formatTime(event.timeOfDay!, locale: locale)
                              : 'HH:MM',
                          style: AppTextStyles.labelMedium(
                              color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.strings['activity_label'] ?? 'Activity',
                    style: AppTextStyles.caption(
                        color: AppColors.textHintLight)),
                SizedBox(height: 4.h),
                SizedBox(
                  height: 48.h,
                  child: TextField(
                    controller: _activityController,
                    decoration: InputDecoration(
                      hintText: widget.strings['event_hint'] ??
                          'Nap, stories, meal...',
                      hintStyle: AppTextStyles.bodySmall(
                          color: AppColors.textHintLight),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 12),
                    ),
                    style: AppTextStyles.bodyMedium(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Column(
            children: [
              SizedBox(height: 14.h),
              GestureDetector(
                onTap: () => widget.onRemoveEvent(index),
                child: Container(
                  width: 48.h,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18.sp, color: AppColors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
