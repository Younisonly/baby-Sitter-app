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

class StepReviewWidget extends ConsumerWidget {
  final String sitterId;
  final dynamic sitter;
  final BookingFlowState flowState;
  final Map<String, String> strings;
  final Widget summaryCard;
  final Widget sitterCard;
  final Widget reviewWarnings;
  final Widget termsHint;

  const StepReviewWidget({
    super.key,
    required this.sitterId,
    required this.sitter,
    required this.flowState,
    required this.strings,
    required this.summaryCard,
    required this.sitterCard,
    required this.reviewWarnings,
    required this.termsHint,
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
            child: Icon(Icons.receipt_long_rounded, size: 32.sp, color: AppColors.primary),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            strings[AppLocalization.summary] ?? 'Review Booking',
            style: AppTextStyles.titleLarge(weight: FontWeight.w700, color: context.textPrimary),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            strings[AppLocalization.step_review_subtitle] ?? 'Please review your booking details',
            style: AppTextStyles.bodyMedium(color: context.textMuted),
          ),
          SizedBox(height: AppSpacing.lg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Column(
              children: [
                summaryCard,
                SizedBox(height: AppSpacing.md),
                BookingPricingCard(
                  sitter: sitter,
                  selectedDate: flowState.selectedDate,
                  startTime: flowState.startTime,
                  endTime: flowState.endTime,
                  childrenCount: flowState.childrenCount,
                  specialNeedsCount: flowState.specialNeedsCount,
                  scheduleEventsCount: flowState.scheduleEvents.length,
                  strings: strings,
                ),
                SizedBox(height: AppSpacing.md),
                sitterCard,
                SizedBox(height: AppSpacing.md),
                reviewWarnings,
                SizedBox(height: AppSpacing.md),
                termsHint,
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
