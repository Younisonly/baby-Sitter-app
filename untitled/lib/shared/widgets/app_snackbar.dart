import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';
import 'package:babysitter/core/localization/app_localization.dart';
enum SnackbarType { success, error, warning, info, loading }

class AppSnackbar {
  static Flushbar? _activeFlushbar;

  static void dismiss() {
    _activeFlushbar?.dismiss();
    _activeFlushbar = null;
  }

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    dismiss();
    final isDark = context.isDark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final locale = Localizations.localeOf(context).languageCode;
    final strings = AppLocalization.get(locale);
    
    final translatedMessage = strings[message] ?? message;
    final translatedTitle = title != null ? (strings[title] ?? title) : null;
    final translatedActionLabel = actionLabel != null ? (strings[actionLabel] ?? actionLabel) : null;

    final (Color color, Color bgColor, IconData icon) = _resolveTheme(type, isDark);

    _activeFlushbar = Flushbar(
      messageText: Row(
        children: [
          _SnackbarIcon(icon: icon, color: color, bgColor: bgColor, isDark: isDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (translatedTitle != null)
                  Text(
                    translatedTitle,
                    style: AppTextStyles.labelMedium(
                      weight: FontWeight.w600,
                      color: bgColor,
                    ),
                  ),
                Text(
                  translatedMessage,
                  style: AppTextStyles.bodySmall(color: bgColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        if (onAction != null && translatedActionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  translatedActionLabel,
                  style: AppTextStyles.labelMedium(
                    weight: FontWeight.w700,
                    color: bgColor,
                  ),
                ),
              ),
            ),
          if (onTap != null)
            Padding(
              padding: EdgeInsets.only(left: rtl ? 0 : AppSpacing.xs),
              child: Icon(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: bgColor,
                size: 18,
              ),
            ),
        ],
      ),
      backgroundColor: _resolveBg(type, isDark),
      borderRadius: BorderRadius.circular(AppRadius.snackbar),
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      duration: type == SnackbarType.loading ? const Duration(seconds: 30) : duration,
      flushbarPosition: FlushbarPosition.TOP,
      boxShadows: [
        BoxShadow(
          color: color.withValues(alpha: isDark ? 0.25 : 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      isDismissible: type != SnackbarType.loading,
      showProgressIndicator: type == SnackbarType.loading,
      progressIndicatorBackgroundColor: bgColor.withValues(alpha: 0.2),
      progressIndicatorValueColor: AlwaysStoppedAnimation<Color>(color),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) _activeFlushbar!.show(context);
    });
  }

  static (Color, Color, IconData) _resolveTheme(SnackbarType type, bool isDark) {
    return switch (type) {
      SnackbarType.success => (
        AppColors.success,
        isDark ? AppColors.successDark : AppColors.success,
        Icons.check_circle_rounded,
      ),
      SnackbarType.error => (
        AppColors.error,
        isDark ? AppColors.errorDark : AppColors.error,
        Icons.error_rounded,
      ),
      SnackbarType.warning => (
        AppColors.warning,
        isDark ? AppColors.warningDark : AppColors.warning,
        Icons.warning_rounded,
      ),
      SnackbarType.info => (
        AppColors.info,
        isDark ? AppColors.infoDark : AppColors.info,
        Icons.info_rounded,
      ),
      SnackbarType.loading => (
        AppColors.info,
        isDark ? AppColors.infoDark : AppColors.info,
        Icons.hourglass_top_rounded,
      ),
    };
  }

  static Color _resolveBg(SnackbarType type, bool isDark) {
    if (isDark) {
      return switch (type) {
        SnackbarType.success => const Color(0xFF052E16),
        SnackbarType.error => const Color(0xFF2D0A0A),
        SnackbarType.warning => const Color(0xFF2D1A00),
        SnackbarType.info => const Color(0xFF042A3D),
        SnackbarType.loading => const Color(0xFF042A3D),
      };
    }
    return AppColors.white;
  }

  static void success(BuildContext context, String message, {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackbarType.success, title: title, actionLabel: actionLabel, onAction: onAction);
  }

  static void error(BuildContext context, String message, {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackbarType.error, title: title, actionLabel: actionLabel, onAction: onAction);
  }

  static void warning(BuildContext context, String message, {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackbarType.warning, title: title, actionLabel: actionLabel, onAction: onAction);
  }

  static void info(BuildContext context, String message, {String? title, String? actionLabel, VoidCallback? onAction}) {
    show(context, message: message, type: SnackbarType.info, title: title, actionLabel: actionLabel, onAction: onAction);
  }

  static void loading(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: SnackbarType.loading, title: title);
  }

}

class _SnackbarIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isDark;

  const _SnackbarIcon({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Icon(icon, color: bgColor, size: 16),
    );
  }
}
