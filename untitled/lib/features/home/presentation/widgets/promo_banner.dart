import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';

class PromoBanner extends ConsumerWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.accentDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Text(strings[AppLocalization.limited_offer] ?? 'Limited Offer',
                      style: AppTextStyles.labelSmall(
                          color: AppColors.white, weight: FontWeight.w600)),
                ),
                SizedBox(height: AppSpacing.sm),
                Text('20% ${strings[AppLocalization.off] ?? 'OFF'}',
                    style: AppTextStyles.displayMedium(color: AppColors.white)),
                Text(strings[AppLocalization.first_booking] ?? 'First Booking',
                    style: AppTextStyles.titleMedium(
                        color: AppColors.white.withValues(alpha: 0.9))),
                SizedBox(height: AppSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Text(strings[AppLocalization.claim_now] ?? 'Claim Now',
                      style: AppTextStyles.labelMedium(
                          color: AppColors.accent, weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.full)),
            child: Icon(Icons.child_care_rounded,
                size: 56.sp, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
