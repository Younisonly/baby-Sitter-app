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
import 'package:babysitter/shared/widgets/app_text_field.dart';

class StepChildrenWidget extends ConsumerWidget {
  final String sitterId;
  final dynamic sitter;
  final BookingFlowState flowState;
  final Map<String, String> strings;
  final TextEditingController specialCareController;
  final List<TextEditingController> nameControllers;
  final List<TextEditingController> ageControllers;
  final Widget validationMessage;

  const StepChildrenWidget({
    super.key,
    required this.sitterId,
    required this.sitter,
    required this.flowState,
    required this.strings,
    required this.specialCareController,
    required this.nameControllers,
    required this.ageControllers,
    required this.validationMessage,
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
            child: Icon(Icons.child_care_rounded, size: 32.sp, color: AppColors.primary),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            strings[AppLocalization.children] ?? 'Children',
            style: AppTextStyles.titleLarge(weight: FontWeight.w700, color: context.textPrimary),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            strings[AppLocalization.step_children_subtitle] ?? 'Tell us about the children',
            style: AppTextStyles.bodyMedium(color: context.textMuted),
          ),
          SizedBox(height: AppSpacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookingChildrenSelector(
                  sitter: sitter,
                  childrenCount: flowState.childrenCount,
                  specialNeedsCount: flowState.specialNeedsCount,
                  specialCareController: specialCareController,
                  strings: strings,
                  onChildrenCountChanged: (v) =>
                      ref.read(bookingFlowProvider(sitterId).notifier).setChildrenCount(v),
                  onSpecialNeedsCountChanged: (v) =>
                      ref.read(bookingFlowProvider(sitterId).notifier).setSpecialNeedsCount(v),
                  onSpecialCareToggled: (v) {
                    ref.read(bookingFlowProvider(sitterId).notifier).toggleSpecialCare(v);
                    if (!v) specialCareController.clear();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                if (flowState.childrenCount > 0) ...[
                  Text(
                    strings['children_details'] ?? 'Children Details (optional)',
                    style: AppTextStyles.titleSmall(weight: FontWeight.w600, color: context.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...List.generate(flowState.childrenCount, (i) {
                    final notifier = ref.read(bookingFlowProvider(sitterId).notifier);
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < flowState.childrenCount - 1 ? AppSpacing.md : 0),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: AppTextStyles.bodySmall(weight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 3,
                            child: AppTextField(
                              controller: i < nameControllers.length ? nameControllers[i] : null,
                              hint: strings['child_name_hint'] ?? 'Name',
                              onChanged: (v) => notifier.setChildName(i, v),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: AppTextField(
                              controller: i < ageControllers.length ? ageControllers[i] : null,
                              hint: strings['age'] ?? 'Age',
                              keyboardType: TextInputType.number,
                              onChanged: (v) => notifier.setChildAge(i, v),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                validationMessage,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
