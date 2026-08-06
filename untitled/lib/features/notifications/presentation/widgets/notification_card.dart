import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_icons.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onMarkRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final iconData = _notificationIcon();
    final color = _notificationColor();
    final priorityColor = _priorityColor();
    final localizedTitle = notification.localizedTitle(locale);
    final localizedBody = notification.localizedBody(locale);

    return Dismissible(
      key: ValueKey('notif_${notification.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && onMarkRead != null) {
          onMarkRead!();
          return false;
        }
        if (direction == DismissDirection.endToStart && onDelete != null) {
          onDelete!();
          return false;
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(Icons.check_circle_outline, color: AppColors.info, size: 24.sp),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.error, size: 24.sp),
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.08)
                : notification.isRead
                    ? context.cardColor
                    : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: isSelected
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: context.isDark ? AppColors.white.withValues(alpha: 0.04) : AppColors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm, top: 4),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? color : context.textMutedColor,
                    size: 22.sp,
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(iconData, size: 22.sp, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizedTitle,
                            style: AppTextStyles.titleSmall(
                              weight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notification.priority == NotificationPriority.high ||
                            notification.priority == NotificationPriority.critical)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      localizedBody,
                      style: AppTextStyles.bodySmall(
                        color: context.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatRelativeTime(notification.createdAt, Localizations.localeOf(context).languageCode),
                      style: AppTextStyles.caption(
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color colorFromString(String? icon) {
    return switch (icon) {
      'booking' || 'calendar' || 'event_available' => AppColors.primary,
      'review' || 'star' || 'star_outline' => AppColors.warning,
      'followers' || 'heart' || 'favorite' || 'favorites' || 'people' =>
        AppColors.accent,
      'security' || 'shield' || 'lock' => AppColors.error,
      'support' || 'support_agent' || 'headset' || 'help' => AppColors.success,
      'subscription' || 'premium' || 'workspace_premium' || 'crown' || 'diamond' =>
        AppColors.accent,
      'system' || 'notification' || 'bell' || 'notifications' || 'info' =>
        AppColors.primary,
      'chat' || 'message' || 'messages' || 'chat_bubble' || 'mail' =>
        AppColors.info,
      'payment' || 'wallet' || 'payments' || 'money' || 'credit_card' || 'dollar' =>
        AppColors.success,
      'profile' || 'person' || 'user' || 'account' => AppColors.primary,
      'profile_verified' || 'verified' || 'check_circle' || 'check' || 'success' =>
        AppColors.success,
      'error' || 'warning' || 'alert' || 'danger' => AppColors.error,
      'time' || 'schedule' || 'clock' || 'date' => AppColors.primary,
      'location' || 'pin' || 'map' => AppColors.error,
      'settings' || 'gear' || 'config' => AppColors.primary,
      'document' || 'file' || 'description' => AppColors.primary,
      'report' || 'flag' => AppColors.warning,
      'email' || 'phone' || 'call' => AppColors.primary,
      'home' => AppColors.primary,
      'search' || 'filter' || 'sort' => AppColors.primary,
      'delete' || 'trash' => AppColors.error,
      'logout' => AppColors.error,
      _ => AppColors.primary,
    };
  }

  IconData _notificationIcon() {
    final resolved = AppIcons.resolve(notification.icon);
    if (resolved != Icons.help_outline_rounded) return resolved;
    return switch (notification.category) {
      'booking' => Icons.event_available_rounded,
      'review' => Icons.star_outline_rounded,
      'followers' => Icons.people_outline_rounded,
      'security' => Icons.security_rounded,
      'support' => Icons.support_agent_rounded,
      'subscription' => Icons.workspace_premium_outlined,
      'system' => Icons.info_outline_rounded,
      _ => Icons.notifications_none_rounded,
    };
  }

  Color _notificationColor() {
    if (notification.icon != null && notification.icon!.isNotEmpty) {
      return colorFromString(notification.icon);
    }
    return switch (notification.category) {
      'booking' => AppColors.primary,
      'review' => AppColors.warning,
      'followers' => AppColors.accent,
      'security' => AppColors.error,
      'support' => AppColors.success,
      'subscription' => AppColors.accent,
      'system' => AppColors.primary,
      _ => AppColors.primary,
    };
  }

  Color _priorityColor() {
    return switch (notification.priority) {
      NotificationPriority.critical => AppColors.error,
      NotificationPriority.high => AppColors.warning,
      NotificationPriority.normal => AppColors.info,
      NotificationPriority.low => AppColors.success,
    };
  }

  String _formatRelativeTime(DateTime dateTime, String locale) {
    return TimeFormatter.formatRelativeTime(dateTime, locale);
  }
}
