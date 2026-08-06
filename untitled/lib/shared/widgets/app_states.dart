import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/shared/widgets/app_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? icon;
  final String? imagePath;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.imagePath,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      subtitle: subtitle,
      icon: icon,
      lottieAsset: imagePath,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class ErrorState extends ConsumerWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final Widget? icon;

  const ErrorState({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    return AppErrorState(
      title: title ?? strings[AppLocalization.something_went_wrong] ?? 'Something went wrong',
      message: message,
      onRetry: onRetry,
      icon: icon,
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lottieAsset;
  final Widget? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.lottieAsset,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (lottieAsset != null)
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    lottieAsset!,
                    fit: BoxFit.contain,
                  ),
                )
              else if (icon != null)
                icon!
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.primaryColor.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: context.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTextStyles.headlineMedium(
                  color: context.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class AppErrorState extends ConsumerWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final Widget? icon;
  final String? lottieAsset;

  const AppErrorState({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.icon,
    this.lottieAsset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final errorTitle = title ?? strings[AppLocalization.something_went_wrong] ?? 'Something went wrong';
    final retryText = strings[AppLocalization.retry] ?? 'Try Again';

    final errorIcon = icon ??
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.errorColor.withValues(alpha: 0.08),
          ),
          child: Icon(
            Icons.cloud_off_rounded,
            size: 44,
            color: context.errorColor,
          ),
        );

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (lottieAsset != null)
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Lottie.asset(
                    lottieAsset!,
                    fit: BoxFit.contain,
                  ),
                )
              else
                errorIcon,
              const SizedBox(height: AppSpacing.lg + 4),
              Text(
                errorTitle,
                style: AppTextStyles.headlineMedium(
                  color: context.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                strings[message] ?? message,
                style: AppTextStyles.bodyMedium(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: retryText,
                  onPressed: onRetry,
                  variant: AppButtonVariant.outlined,
                  prefixIcon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class AppOfflineState extends ConsumerWidget {
  final String? title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const AppOfflineState({
    super.key,
    this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final offlineTitle = title ?? strings[AppLocalization.no_internet_connection] ?? 'No Internet Connection';
    final offlineMessage = (message != null ? (strings[message] ?? message) : null) ?? strings[AppLocalization.load_error_desc] ?? 'Please check your connection and try again.';
    final retryText = retryLabel ?? strings[AppLocalization.retry] ?? 'Retry';

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.textMutedColor.withValues(alpha: 0.08),
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 44,
                  color: context.textMutedColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg + 4),
              Text(
                offlineTitle,
                style: AppTextStyles.headlineMedium(
                  color: context.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                offlineMessage,
                style: AppTextStyles.bodyMedium(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: retryText,
                  onPressed: onRetry,
                  variant: AppButtonVariant.outlined,
                  prefixIcon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scaleY(begin: 0.95, end: 1);
  }
}
