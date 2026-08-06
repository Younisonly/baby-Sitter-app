import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/notifications/data/notification_settings_provider.dart';
import 'package:babysitter/shared/widgets/app_shimmer.dart';
import 'package:babysitter/shared/widgets/app_states.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationSettingsProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final state = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings[AppLocalization.notifications_settings] ??
            'Notification Settings'),
      ),
      body: _buildBody(strings, state, notifier),
    );
  }

  Widget _buildBody(
    Map<String, String> strings,
    NotificationSettingsState state,
    NotificationSettingsNotifier notifier,
  ) {
    if (state.isLoading) {
      return const _SettingsShimmer();
    }

    if (state.error != null) {
      return ErrorState(
        message: state.error!,
        onRetry: notifier.load,
      );
    }

    final settings = state.settings;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildSectionHeader(
          strings[AppLocalization.push_notifications] ?? 'Push Notifications',
          Icons.notifications_active_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildSwitchTile(
          title: strings[AppLocalization.push_notifications] ?? 'Push Notifications',
          subtitle: strings[AppLocalization.push_notifications_subtitle] ??
              'Receive push notifications on your device',
          value: settings.pushEnabled,
          onChanged: (v) => notifier.toggleCategory('push_enabled', v),
        ),
        _buildSwitchTile(
          title: strings[AppLocalization.in_app_notifications] ?? 'In-App Notifications',
          subtitle: strings[AppLocalization.in_app_subtitle] ??
              'Show notifications inside the app',
          value: settings.inAppEnabled,
          onChanged: (v) => notifier.toggleCategory('in_app_enabled', v),
        ),

        const SizedBox(height: AppSpacing.xl),
        _buildSectionHeader(
          strings[AppLocalization.notification_categories] ?? 'Notification Categories',
          Icons.category_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),

        _buildSwitchTile(
          title: strings[AppLocalization.bookings] ?? 'Bookings',
          subtitle: strings[AppLocalization.booking_notifications_subtitle] ??
              'Booking confirmations, reminders, cancellations',
          value: settings.bookingEnabled,
          onChanged: (v) => notifier.toggleCategory('booking_enabled', v),
          icon: Icons.event_available_rounded,
          iconColor: context.primaryColor,
        ),
        _buildSwitchTile(
          title: strings[AppLocalization.chat_messages] ?? 'Chat Messages',
          subtitle: strings[AppLocalization.chat_notifications_subtitle] ??
              'New messages, voice notes, images',
          value: settings.chatEnabled,
          onChanged: (v) => notifier.toggleCategory('chat_enabled', v),
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: context.infoColor,
        ),
        _buildSwitchTile(
          title: strings[AppLocalization.reviews] ?? 'Reviews',
          subtitle: strings[AppLocalization.review_notifications_subtitle] ??
              'New reviews, replies',
          value: settings.reviewEnabled,
          onChanged: (v) => notifier.toggleCategory('review_enabled', v),
          icon: Icons.star_outline_rounded,
          iconColor: context.warningColor,
        ),
        _buildSwitchTile(
          title: strings[AppLocalization.favorites] ?? 'Followers',
          subtitle: strings[AppLocalization.follower_notifications_subtitle] ??
              'New followers, milestones',
          value: settings.followersEnabled,
          onChanged: (v) => notifier.toggleCategory('followers_enabled', v),
          icon: Icons.people_outline_rounded,
          iconColor: context.infoColor,
        ),
        _buildSwitchTile(
          title: strings[AppLocalization.support] ?? 'Support',
          subtitle: strings[AppLocalization.support_notifications_subtitle] ??
              'Ticket replies and updates',
          value: settings.supportEnabled,
          onChanged: (v) => notifier.toggleCategory('support_enabled', v),
          icon: Icons.support_agent_rounded,
          iconColor: context.successColor,
        ),
        _buildSwitchTile(
          title: strings[AppLocalization.security_alerts] ?? 'Security Alerts',
          subtitle: strings[AppLocalization.security_notifications_subtitle] ??
              'Login alerts, password changes (cannot be disabled)',
          value: settings.securityEnabled,
          onChanged: null,
          icon: Icons.security_rounded,
          iconColor: context.errorColor,
          isDisabled: true,
        ),
        _buildSwitchTile(
          title: strings[AppLocalization.promotions] ?? 'Promotions',
          subtitle: strings[AppLocalization.promotion_notifications_subtitle] ??
              'Offers, discounts, announcements',
          value: settings.promotionEnabled,
          onChanged: (v) => notifier.toggleCategory('promotion_enabled', v),
          icon: Icons.discount_outlined,
          iconColor: context.infoColor,
        ),

        const SizedBox(height: AppSpacing.xl),
        _buildSectionHeader(
          strings[AppLocalization.quiet_hours] ?? 'Quiet Hours',
          Icons.bedtime_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildQuietHoursTile(strings, settings, notifier),

        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.textPrimaryColor),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.titleMedium(
            weight: FontWeight.w700,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool)? onChanged,
    IconData? icon,
    Color? iconColor,
    bool isDisabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: (iconColor ?? context.primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? context.primaryColor),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall(
                    weight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption(
                    color: context.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: isDisabled ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHoursTile(
    Map<String, String> strings,
    dynamic settings,
    NotificationSettingsNotifier notifier,
  ) {
    final hasQuietHours =
        settings.quietHoursStart != null && settings.quietHoursEnd != null;
    final label = hasQuietHours
        ? '${settings.quietHoursStart} - ${settings.quietHoursEnd}'
        : (strings[AppLocalization.not_set] ?? 'Not set');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.nightlight_round,
              size: 20,
              color: context.primaryColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings[AppLocalization.do_not_disturb] ?? 'Do Not Disturb',
                  style: AppTextStyles.titleSmall(
                    weight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.caption(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsShimmer extends StatelessWidget {
  const _SettingsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: List.generate(
        8,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              const AppShimmer(width: 44, height: 44, borderRadius: 8),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppShimmer(width: 150, height: 14),
                    const SizedBox(height: AppSpacing.sm),
                    const AppShimmer(width: 200, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
