import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';

class NotificationGroupHeader extends StatelessWidget {
  final String title;

  const NotificationGroupHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall(
              weight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Divider(color: context.dividerColor)),
        ],
      ),
    );
  }
}
