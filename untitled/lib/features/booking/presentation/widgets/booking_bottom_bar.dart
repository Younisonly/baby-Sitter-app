import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class BookingBottomBar extends StatelessWidget {
  final double total;
  final bool isSubmitting;
  final bool isStartTimeNull;
  final Map<String, String> strings;
  final VoidCallback onConfirm;

  const BookingBottomBar({
    super.key,
    required this.total,
    required this.isSubmitting,
    required this.isStartTimeNull,
    required this.strings,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
          AppSpacing.sm, AppSpacing.screenPadding, AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings['total'] ?? 'Total',
                      style: AppTextStyles.caption(
                          color: context.textMuted)),
                  TweenAnimationBuilder<double>(
                    duration: 400.ms,
                    tween: Tween<double>(begin: 0.0, end: total),
                    builder: (context, value, _) => Text(
                      '﷼${value.toStringAsFixed(0)}',
                      style: AppTextStyles.headlineMedium(
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: AppButton(
                text: strings['confirm_booking'] ?? 'Confirm Booking',
                isLoading: isSubmitting,
                onPressed:
                    isSubmitting || isStartTimeNull ? null : onConfirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
