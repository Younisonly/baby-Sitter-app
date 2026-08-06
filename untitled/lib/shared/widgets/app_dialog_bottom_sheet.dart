import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/shared/widgets/app_button.dart';

void showLoginSheet(BuildContext context, {String? message}) {
  final strings = AppLocalization.get(
    Localizations.localeOf(context).languageCode,
  );
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.primaryGradient),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded, size: 40, color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            strings[AppLocalization.login_required] ?? 'Login Required',
            style: AppTextStyles.titleLarge(weight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message ??
                (strings[AppLocalization.login_to_access] ??
                    'Please login to access this feature'),
            style: AppTextStyles.bodyMedium(
              color: context.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: strings[AppLocalization.login] ?? 'Login',
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.login);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: strings[AppLocalization.create_account] ?? 'Create Account',
              variant: AppButtonVariant.outlined,
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.register);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: context.textSecondaryColor,
            ),
            child: Text(
              strings[AppLocalization.continue_browsing] ?? 'Continue Browsing',
            ),
          ),
        ],
      ),
    ),
  );
}

Future<T?> showAppModalSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
        boxShadow: AppShadows.dialog,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: child,
      ),
    ),
  );
}

class AppDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    IconData? icon,
  }) async {
    final effectiveIcon = icon ?? (isDestructive ? Icons.warning_rounded : null);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        actionsPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        backgroundColor: ctx.cardColor,
        content: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (effectiveIcon != null) ...[
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: isDestructive
                        ? LinearGradient(colors: [
                            AppColors.error,
                            AppColors.error.withValues(alpha: 0.8),
                          ], begin: Alignment.topLeft, end: Alignment.bottomRight)
                        : const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(effectiveIcon, size: 32, color: AppColors.white),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                title,
                style: AppTextStyles.titleLarge(
                  weight: FontWeight.bold,
                  color: ctx.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                content,
                style: AppTextStyles.bodyMedium(
                  color: ctx.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: confirmText,
                  onPressed: () {
                    final cb = onConfirm;
                    Navigator.pop(ctx);
                    Future.microtask(cb);
                  },
                  variant: isDestructive ? AppButtonVariant.danger : AppButtonVariant.filled,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: cancelText,
                  onPressed: () {
                    Navigator.pop(ctx);
                    final cb = onCancel;
                    if (cb != null) Future.microtask(cb);
                  },
                  variant: AppButtonVariant.outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final IconData? icon;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = icon ?? (isDestructive ? Icons.warning_rounded : null);
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      backgroundColor: context.cardColor,
      content: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (effectiveIcon != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: isDestructive
                      ? LinearGradient(colors: [
                          AppColors.error,
                          AppColors.error.withValues(alpha: 0.8),
                        ], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : const LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                ),
                child: Icon(effectiveIcon, size: 32, color: AppColors.white),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              title,
              style: AppTextStyles.titleLarge(
                weight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodyMedium(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: confirmLabel,
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                variant: isDestructive ? AppButtonVariant.danger : AppButtonVariant.filled,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: cancelLabel,
                onPressed: () => Navigator.pop(context),
                variant: AppButtonVariant.outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
