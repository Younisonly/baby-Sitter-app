import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/models/booking_model.dart';

class BookingBookedSlots extends ConsumerWidget {
  final List<BookingModel> existingBookings;
  final DateTime selectedDate;

  const BookingBookedSlots({
    super.key,
    required this.existingBookings,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider).code;
    final strings = AppLocalization.get(locale);
    final dateBookings = existingBookings
        .where((b) =>
            b.date.year == selectedDate.year &&
            b.date.month == selectedDate.month &&
            b.date.day == selectedDate.day)
        .toList();
    if (dateBookings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.event_busy_rounded,
          title: strings[AppLocalization.booked_times] ?? 'Booked Times',
        ),
        SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.softPeach,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1)),
            ],
          ),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: dateBookings
                .map((b) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              blurRadius: 2,
                              offset: const Offset(0, 1)),
                        ],
                      ),
                      child: Text(TimeFormatter.formatTimeRange(b.startTime, b.endTime, locale),
                          style: AppTextStyles.labelSmall(
                              color: AppColors.warning)),
                    ))
                .toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.white),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.titleMedium(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
