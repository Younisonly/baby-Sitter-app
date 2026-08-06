import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/shared/models/user_model.dart';

class BookingHero extends ConsumerWidget {
  final UserModel sitter;
  const BookingHero({super.key, required this.sitter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final profile = sitter.babysitterProfile;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
          AppSpacing.lg, AppSpacing.screenPadding, AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxxl),
          bottomRight: Radius.circular(AppRadius.xxxl),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                backgroundImage:
                    sitter.avatar != null && sitter.avatar!.isNotEmpty
                        ? NetworkImage(AppConfig.absoluteUrl(sitter.avatar!))
                        : null,
                child: sitter.avatar == null || sitter.avatar!.isEmpty
                    ? Icon(Icons.person_rounded,
                        size: 28.sp, color: AppColors.white)
                    : null,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sitter.name,
                        style:
                            AppTextStyles.titleLarge(color: AppColors.white)),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12.sp,
                            color: AppColors.white.withValues(alpha: 0.7)),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            sitter.location ??
                                (strings[AppLocalization.nearby_fallback] ??
                                    'Nearby'),
                            style: AppTextStyles.bodySmall(
                                color: AppColors.white.withValues(alpha: 0.7)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (profile != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 14.sp, color: AppColors.warning),
                      SizedBox(width: 4.w),
                      Text(
                        profile.rating.toStringAsFixed(1),
                        style:
                            AppTextStyles.labelMedium(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          if (profile != null)
            Row(
              children: [
                _HeroStat(
                  icon: Icons.attach_money_rounded,
                  value:
                      '﷼${profile.hourlyRate.toStringAsFixed(0)}${strings[AppLocalization.per_hour] ?? '/hr'}',
                  label: profile.includedChildren > 1
                      ? (strings[AppLocalization.up_to_kids]?.replaceAll(
                              '{count}', '${profile.includedChildren}') ??
                          'up to ${profile.includedChildren} kids')
                      : (strings[AppLocalization.per_child] ?? 'per child'),
                ),
                SizedBox(width: AppSpacing.md),
                _HeroStat(
                  icon: Icons.work_outline_rounded,
                  value:
                      '${profile.yearsExperience}+ ${strings[AppLocalization.years_short] ?? 'yrs'}',
                  label: strings[AppLocalization.experience] ?? 'experience',
                ),
                SizedBox(width: AppSpacing.md),
                _HeroStat(
                  icon: Icons.people_outline_rounded,
                  value: '${profile.completedBookings}',
                  label: strings[AppLocalization.bookings] ?? 'bookings',
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 18.sp, color: AppColors.white.withValues(alpha: 0.9)),
            SizedBox(height: 4.h),
            Text(value,
                style: AppTextStyles.labelMedium(
                    color: AppColors.white, weight: FontWeight.bold)),
            Text(label,
                style: AppTextStyles.caption(
                    color: AppColors.white.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}
