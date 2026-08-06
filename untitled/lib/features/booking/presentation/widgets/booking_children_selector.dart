import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/shared/models/user_model.dart';

class BookingChildrenSelector extends StatelessWidget {
  final UserModel sitter;
  final int childrenCount;
  final int specialNeedsCount;
  final TextEditingController specialCareController;
  final Map<String, String> strings;
  final ValueChanged<int> onChildrenCountChanged;
  final ValueChanged<int> onSpecialNeedsCountChanged;
  final ValueChanged<bool> onSpecialCareToggled;

  const BookingChildrenSelector({
    super.key,
    required this.sitter,
    required this.childrenCount,
    required this.specialNeedsCount,
    required this.specialCareController,
    required this.strings,
    required this.onChildrenCountChanged,
    required this.onSpecialNeedsCountChanged,
    required this.onSpecialCareToggled,
  });

  @override
  Widget build(BuildContext context) {
    final profile = sitter.babysitterProfile;
    final extraChildFee = profile?.extraChildFee ?? 0;
    final specialNeedsRate = profile?.specialNeedsRate ?? 0;
    final includedChildren = profile?.includedChildren ?? 1;
    final absoluteMax = profile?.absoluteMaxChildren ?? 12;
    final hardMax = absoluteMax;
    final isOverIncluded = childrenCount > includedChildren;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.child_care_rounded,
                      size: 18.sp, color: AppColors.primary),
                  SizedBox(width: AppSpacing.sm),
                  Text(strings['children'] ?? 'Children',
                      style: AppTextStyles.titleSmall()),
                  const Spacer(),
                  _Stepper(
                    value: childrenCount,
                    min: 1,
                    max: hardMax,
                    onChanged: onChildrenCountChanged,
                    warning: isOverIncluded
                        ? '${childrenCount - includedChildren} beyond included'
                        : null,
                  ),
                ],
              ),

              if (extraChildFee > 0 &&
                  childrenCount > (profile?.includedChildren ?? 1))
                Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: [
                      SizedBox(width: 34.w),
                      Text(
                        '+${childrenCount - (profile?.includedChildren ?? 1)} extra × ﷼${extraChildFee.toStringAsFixed(0)}/hr',
                        style:
                            AppTextStyles.caption(color: AppColors.warning),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: specialNeedsCount > 0,
                      activeColor: AppColors.error,
                      onChanged: (v) {
                        onSpecialCareToggled(v == true);
                      },
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                      strings['special_care_checkbox'] ??
                          'These children need special care',
                      style: AppTextStyles.bodyMedium()),
                ],
              ),
              if (specialNeedsCount > 0) ...[
                SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.healing_rounded,
                              size: 16.sp, color: AppColors.error),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                                strings['special_care_label'] ??
                                    'Special care kids',
                                style: AppTextStyles.titleSmall()),
                          ),
                          _Stepper(
                            value: specialNeedsCount,
                            min: 1,
                            max: childrenCount,
                            onChanged: onSpecialNeedsCountChanged,
                          ),
                        ],
                      ),
                      if (specialNeedsRate > 0)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h, left: 26.w),
                          child: Text(
                            '﷼${specialNeedsRate.toStringAsFixed(0)}/hr per child',
                            style: AppTextStyles.caption(
                                color: context.textMuted),
                          ),
                        ),
                      SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: specialCareController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: strings['special_care_why'] ??
                              'Why? Allergies, medical needs, behavior...',
                          hintStyle: AppTextStyles.bodySmall(
                              color: context.textMuted),
                          border: InputBorder.none,
                          isDense: false,
                          contentPadding:
                              const EdgeInsets.fromLTRB(4, 6, 0, 2),
                        ),
                        style: AppTextStyles.bodyMedium(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? warning;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.dividerColor.withValues(alpha: 0.3),
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(AppRadius.lg),
          bottomStart: Radius.circular(AppRadius.lg),
          topEnd: Radius.circular(AppRadius.lg),
          bottomEnd: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: value > min ? () => onChanged(value - 1) : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value > min ? AppColors.primary : Colors.transparent,
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(AppRadius.lg),
                  bottomStart: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Icon(Icons.remove_rounded,
                  size: 18.sp,
                  color:
                      value > min ? AppColors.white : context.textMuted),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('$value',
                    style: AppTextStyles.titleMedium(weight: FontWeight.bold)),
              ),
              if (warning != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: 2,
                  ),
                  child: Text(
                    warning!,
                    style: AppTextStyles.caption(
                      color: AppColors.warning,
                      weight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: value < max ? () => onChanged(value + 1) : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value < max ? AppColors.primary : Colors.transparent,
                borderRadius: const BorderRadiusDirectional.only(
                  topEnd: Radius.circular(AppRadius.lg),
                  bottomEnd: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Icon(Icons.add_rounded,
                  size: 18.sp,
                  color:
                      value < max ? AppColors.white : context.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
