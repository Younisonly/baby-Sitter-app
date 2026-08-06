import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/features/booking/data/booking_flow_notifier.dart';
import 'package:babysitter/features/booking/presentation/widgets/widgets.dart';

class StepAdditionalWidget extends ConsumerWidget {
  final String sitterId;
  final BookingFlowState flowState;
  final Map<String, String> strings;
  final TextEditingController notesController;
  final Widget notesCharCount;
  final Widget validationMessage;
  final void Function(int) onPickEventTime;

  const StepAdditionalWidget({
    super.key,
    required this.sitterId,
    required this.flowState,
    required this.strings,
    required this.notesController,
    required this.notesCharCount,
    required this.validationMessage,
    required this.onPickEventTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        children: [
          SizedBox(height: AppSpacing.md),
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notes_rounded, size: 32.sp, color: AppColors.primary),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            strings[AppLocalization.additional_info] ?? 'Additional Information',
            style: AppTextStyles.titleLarge(weight: FontWeight.w700, color: context.textPrimary),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            strings[AppLocalization.step_additional_subtitle] ?? 'Optional details to help the sitter',
            style: AppTextStyles.bodyMedium(color: context.textMuted),
          ),
          SizedBox(height: AppSpacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16.sp, color: AppColors.primary),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      strings[AppLocalization.schedule] ?? 'Daily Schedule',
                      style: AppTextStyles.titleSmall(weight: FontWeight.w600, color: context.textPrimary),
                    ),
                    Spacer(),
                    Text(
                      '(${strings[AppLocalization.optional] ?? 'Optional'})',
                      style: AppTextStyles.caption(color: context.textMuted),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                BookingScheduleEvents(
                  scheduleEvents: flowState.scheduleEvents,
                  strings: strings,
                  onAddEvent: () => ref.read(bookingFlowProvider(sitterId).notifier).addScheduleEvent(),
                  onRemoveEvent: (index) => ref.read(bookingFlowProvider(sitterId).notifier).removeScheduleEvent(index),
                  onReorder: (oldIndex, newIndex) => ref.read(bookingFlowProvider(sitterId).notifier).reorderScheduleEvents(oldIndex, newIndex),
                  onPickEventTime: (index) => onPickEventTime(index),
                  onActivityChanged: (index, activity) =>
                      ref.read(bookingFlowProvider(sitterId).notifier).updateScheduleEventActivity(index, activity),
                ),
                SizedBox(height: AppSpacing.sectionSpacing),
                Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 16.sp, color: AppColors.primary),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      strings[AppLocalization.notes] ?? 'Notes',
                      style: AppTextStyles.titleSmall(weight: FontWeight.w600, color: context.textPrimary),
                    ),
                    Spacer(),
                    Text(
                      '(${strings[AppLocalization.optional] ?? 'Optional'})',
                      style: AppTextStyles.caption(color: context.textMuted),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                BookingNotesField(
                  controller: notesController,
                  strings: strings,
                  onChanged: (v) => ref.read(bookingFlowProvider(sitterId).notifier).validateNotes(v),
                ),
                notesCharCount,
                validationMessage,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
