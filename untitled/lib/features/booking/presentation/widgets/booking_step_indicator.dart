import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';

final List<_StepData> _steps = [
  _StepData(icon: Icons.calendar_today_rounded, key: 'step_date_time'),
  _StepData(icon: Icons.child_care_rounded, key: 'step_children'),
  _StepData(icon: Icons.notes_rounded, key: 'step_additional'),
  _StepData(icon: Icons.receipt_long_rounded, key: 'step_review'),
];

class _StepData {
  final IconData icon;
  final String key;
  const _StepData({required this.icon, required this.key});
}

class BookingStepIndicator extends ConsumerWidget {
  final int currentStep; // 0–3

  const BookingStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) return _buildConnector(context, index ~/ 2);
          final stepIndex = index ~/ 2;
          return _buildStep(context, stepIndex, strings);
        }),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int index, Map<String, String> strings) {
    final isActive = index == currentStep;
    final isCompleted = index < currentStep;
    final color = isCompleted || isActive ? AppColors.primary : context.textMuted.withValues(alpha: 0.4);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary
                  : isActive
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: isActive ? 2 : 1.5,
              ),
            ),
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 18.sp, color: AppColors.white)
                : Icon(_steps[index].icon, size: 16.sp, color: color),
          ).animate(target: isActive ? 1 : 0).shimmer(
            duration: 1500.ms,
            delay: 500.ms,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          SizedBox(height: 4.h),
          Text(
            strings[_steps[index].key] ?? '',
            style: AppTextStyles.labelSmall(
              color: isCompleted || isActive ? AppColors.primary : context.textMuted.withValues(alpha: 0.4),
              weight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(BuildContext context, int index) {
    final isCompleted = index < currentStep;
    return Container(
      width: 24.w,
      height: 2,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primary
            : context.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
      margin: EdgeInsets.only(bottom: 18.h),
    );
  }
}
