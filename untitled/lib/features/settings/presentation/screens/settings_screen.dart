import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/notifications/data/notification_settings_provider.dart';
import 'package:babysitter/shared/models/notification_settings_model.dart';
import 'package:babysitter/shared/models/user_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.isAuthenticated;
    final user = authState.user;
    final isSitter = user?.role == UserRole.babysitter;
    final notifState = ref.watch(notificationSettingsProvider);
    final notifNotifier = ref.read(notificationSettingsProvider.notifier);
    final settings = notifState.settings;

    return Scaffold(
      appBar: AppAppBar(
        title: strings[AppLocalization.settings] ?? 'Settings',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
        ),
        children: [
          _SectionHeader(
            icon: Icons.palette_outlined,
            title: strings[AppLocalization.appearance] ?? 'Appearance',
            subtitle: strings[AppLocalization.customize_experience] ??
                'Customize your experience',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildAppearanceCard(strings, themeMode, language),

          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
            icon: Icons.notifications_outlined,
            title: strings[AppLocalization.notifications] ?? 'Notifications',
            subtitle: strings[AppLocalization.notification_preferences] ??
                'Notification Preferences',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildNotificationsCard(strings, notifState, notifNotifier, settings, isSitter, isLoggedIn),

          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
            icon: Icons.info_outline,
            title: strings[AppLocalization.information] ?? 'Information',
            subtitle: strings[AppLocalization.legal_and_support] ??
                'Legal and support',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoCard(strings),

          const SizedBox(height: AppSpacing.xl),
          if (isLoggedIn) ...[
            _SectionHeader(
              icon: Icons.account_circle_outlined,
              title: strings[AppLocalization.account] ?? 'Account',
              subtitle: strings[AppLocalization.manage_account] ??
                  'Manage your account',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildAccountCard(strings),
          ] else ...[
            _buildLoginPromptCard(strings),
          ],
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(
    Map<String, String> strings,
    ThemeMode themeMode,
    AppLanguage language,
  ) {
    return _SettingsCard(
      child: Column(
        children: [
          _ThemeSelector(themeMode: themeMode, strings: strings, onChanged: (mode) {
            ref.read(themeProvider.notifier).setTheme(mode);
          }),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _LanguageSelector(language: language, strings: strings, onChanged: (code) {
            ref.read(languageProvider.notifier).setLanguage(code);
          }),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(
    Map<String, String> strings,
    NotificationSettingsState notifState,
    NotificationSettingsNotifier notifNotifier,
    NotificationSettingsModel settings,
    bool isSitter,
    bool isLoggedIn,
  ) {
    if (notifState.isLoading) {
      return _SettingsCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (notifState.error != null) {
      if (!isLoggedIn) {
        return _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.primaryGradient),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 28,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings[AppLocalization.login_required] ?? 'Login Required',
                  style: AppTextStyles.titleMedium(weight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  strings[AppLocalization.login_to_access] ??
                      'Please login to access this feature',
                  style: AppTextStyles.caption(color: context.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => showLoginSheet(context),
                  child: Text(
                    strings[AppLocalization.retry] ?? 'Retry',
                    style: AppTextStyles.labelLarge(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return _SettingsCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 24, color: context.textSecondaryColor),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  notifState.error!,
                  style: AppTextStyles.caption(color: context.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => notifNotifier.load(),
                  child: Text(strings[AppLocalization.retry] ?? 'Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _SettingsCard(
      child: Column(
        children: [
          _NotifToggle(
            icon: Icons.notifications_active_rounded,
            title: strings[AppLocalization.push_notifications] ?? 'Push Notifications',
            subtitle: strings[AppLocalization.push_notifications_subtitle] ??
                'Receive push notifications on your device',
            value: settings.pushEnabled,
            color: AppColors.primary,
            onChanged: (v) => notifNotifier.toggleCategory('push_enabled', v),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _NotifToggle(
            icon: Icons.notifications_rounded,
            title: strings[AppLocalization.in_app_notifications] ?? 'In-App Notifications',
            subtitle: strings[AppLocalization.in_app_subtitle] ??
                'Show notifications inside the app',
            value: settings.inAppEnabled,
            color: context.infoColor,
            onChanged: (v) => notifNotifier.toggleCategory('in_app_enabled', v),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _NotifToggle(
            icon: Icons.event_available_rounded,
            title: strings[AppLocalization.bookings] ?? 'Bookings',
            subtitle: strings[AppLocalization.booking_notifications_subtitle] ??
                'Booking confirmations, reminders, cancellations',
            value: settings.bookingEnabled,
            color: AppColors.primary,
            onChanged: (v) => notifNotifier.toggleCategory('booking_enabled', v),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _NotifToggle(
            icon: Icons.chat_bubble_outline_rounded,
            title: strings[AppLocalization.chat_messages] ?? 'Chat Messages',
            subtitle: strings[AppLocalization.chat_notifications_subtitle] ??
                'New messages, voice notes, images',
            value: settings.chatEnabled,
            color: context.infoColor,
            onChanged: (v) => notifNotifier.toggleCategory('chat_enabled', v),
          ),
          if (isSitter) ...[
            Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
            _NotifToggle(
              icon: Icons.star_outline_rounded,
              title: strings[AppLocalization.reviews] ?? 'Reviews',
              subtitle: strings[AppLocalization.review_notifications_subtitle] ??
                  'New reviews, replies',
              value: settings.reviewEnabled,
              color: context.warningColor,
              onChanged: (v) => notifNotifier.toggleCategory('review_enabled', v),
            ),
          ],
          if (isSitter) ...[
            Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
            _NotifToggle(
              icon: Icons.people_outline_rounded,
              title: strings[AppLocalization.favorites] ?? 'Followers',
              subtitle: strings[AppLocalization.follower_notifications_subtitle] ??
                  'New followers, milestones',
              value: settings.followersEnabled,
              color: context.infoColor,
              onChanged: (v) => notifNotifier.toggleCategory('followers_enabled', v),
            ),
          ],
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _NotifToggle(
            icon: Icons.support_agent_rounded,
            title: strings[AppLocalization.support] ?? 'Support',
            subtitle: strings[AppLocalization.support_notifications_subtitle] ??
                'Ticket replies and updates',
            value: settings.supportEnabled,
            color: context.successColor,
            onChanged: (v) => notifNotifier.toggleCategory('support_enabled', v),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _NotifToggle(
            icon: Icons.security_rounded,
            title: strings[AppLocalization.security_alerts] ?? 'Security Alerts',
            subtitle: strings[AppLocalization.security_notifications_subtitle] ??
                'Login alerts, password changes (cannot be disabled)',
            value: settings.securityEnabled,
            color: context.errorColor,
            onChanged: null,
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _NotifToggle(
            icon: Icons.discount_outlined,
            title: strings[AppLocalization.promotions] ?? 'Promotions',
            subtitle: strings[AppLocalization.promotion_notifications_subtitle] ??
                'Offers, discounts, announcements',
            value: settings.promotionEnabled,
            color: AppColors.primary,
            onChanged: (v) => notifNotifier.toggleCategory('promotion_enabled', v),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, String> strings) {
    return _SettingsCard(
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.description_outlined,
            title: strings[AppLocalization.terms_conditions] ?? 'Terms & Conditions',
            subtitle: strings[AppLocalization.review_terms] ?? 'Review our terms',
            onTap: () => context.push(AppRoutes.terms),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _SettingsTile(
            icon: Icons.security_outlined,
            title: strings[AppLocalization.privacy_policy] ?? 'Privacy Policy',
            subtitle: strings[AppLocalization.how_we_handle_data] ?? 'How we handle your data',
            onTap: () => context.push(AppRoutes.privacy),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _SettingsTile(
            icon: Icons.help_outline,
            title: strings[AppLocalization.support_faq] ?? 'FAQ',
            subtitle: strings[AppLocalization.faq] ?? 'Frequently asked questions',
            onTap: () => context.push(AppRoutes.faq),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _SettingsTile(
            icon: Icons.headset_mic,
            title: strings[AppLocalization.contact_support] ?? 'Contact Support',
            subtitle: strings[AppLocalization.get_help] ?? 'Get help when you need it',
            onTap: () => context.push(AppRoutes.support),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _SettingsTile(
            icon: Icons.info_outline,
            title: strings[AppLocalization.about_app] ?? 'About App',
            subtitle: (strings[AppLocalization.version] ?? 'Version {version}')
                .replaceAll('{version}', '1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Map<String, String> strings) {
    return _SettingsCard(
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.logout,
            title: strings[AppLocalization.logout] ?? 'Logout',
            subtitle: strings[AppLocalization.sign_out_of_account] ?? 'Sign out of your account',
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: () => _showLogoutDialog(strings),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: strings[AppLocalization.delete_account] ?? 'Delete Account',
            subtitle: strings[AppLocalization.permanently_remove_data] ?? 'Permanently remove your data',
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: () => _showDeleteDialog(strings),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(Map<String, String> strings) {
    AppDialog.show(
      context: context,
      title: strings[AppLocalization.logout_title] ?? 'Logout',
      content: strings[AppLocalization.logout_body] ?? 'Are you sure you want to logout?',
      confirmText: strings[AppLocalization.logout] ?? 'Logout',
      cancelText: strings[AppLocalization.cancel] ?? 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        await ref.read(authProvider.notifier).logout();
      },
    );
  }

  void _showDeleteDialog(Map<String, String> strings) {
    AppDialog.show(
      context: context,
      title: strings[AppLocalization.delete_account_title] ?? 'Delete Account',
      content: strings[AppLocalization.delete_account_body] ?? 'This action cannot be undone. All your data will be permanently deleted.',
      confirmText: strings[AppLocalization.delete] ?? 'Delete',
      cancelText: strings[AppLocalization.cancel] ?? 'Cancel',
      isDestructive: true,
      onConfirm: () async {
        await ref.read(authProvider.notifier).deleteAccount();
      },
    );
  }

  Widget _buildLoginPromptCard(Map<String, String> strings) {
    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppColors.primaryGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 36,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              strings[AppLocalization.login_required] ?? 'Login Required',
              style: AppTextStyles.titleLarge(
                weight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              strings[AppLocalization.login_to_access] ??
                  'Please login to access this feature',
              style: AppTextStyles.bodyMedium(
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              width: double.infinity,
              text: strings[AppLocalization.login] ?? 'Login',
              onPressed: () => showLoginSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(icon, size: 20, color: context.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTextStyles.titleSmall(
            weight: FontWeight.w700,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.dividerColor.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final void Function(bool)? onChanged;

  const _NotifToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
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
          if (onChanged != null)
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
            )
          else
            Icon(Icons.lock_outline, size: 16, color: context.textHint),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode themeMode;
  final Map<String, String> strings;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeSelector({
    required this.themeMode,
    required this.strings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dark_mode_outlined,
                    size: 20, color: AppColors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings[AppLocalization.theme] ?? 'Theme',
                style: AppTextStyles.titleSmall(
                  weight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _ThemeOption(
                icon: Icons.brightness_auto_rounded,
                label: strings[AppLocalization.theme_system] ?? 'System',
                isSelected: themeMode == ThemeMode.system,
                onTap: () => onChanged(ThemeMode.system),
              ),
              SizedBox(width: AppSpacing.sm),
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: strings[AppLocalization.theme_light] ?? 'Light',
                isSelected: themeMode == ThemeMode.light,
                onTap: () => onChanged(ThemeMode.light),
              ),
              SizedBox(width: AppSpacing.sm),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: strings[AppLocalization.theme_dark] ?? 'Dark',
                isSelected: themeMode == ThemeMode.dark,
                onTap: () => onChanged(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : context.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? null
                : Border.all(
                    color: context.dividerColor,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 26,
                color: isSelected
                    ? AppColors.white
                    : (context.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelMedium(
                  weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.white
                      : (context.textPrimaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final AppLanguage language;
  final Map<String, String> strings;
  final ValueChanged<String> onChanged;

  const _LanguageSelector({
    required this.language,
    required this.strings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.language,
                    size: 20, color: AppColors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings[AppLocalization.language] ?? 'Language',
                style: AppTextStyles.titleSmall(
                  weight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _LangOption(
                code: 'en',
                name: 'English',
                isSelected: language.code == 'en',
                flag: '🇺🇸',
                onTap: () => onChanged('en'),
              ),
              SizedBox(width: AppSpacing.sm),
              _LangOption(
                code: 'ar',
                name: 'العربية',
                isSelected: language.code == 'ar',
                flag: '🇸🇦',
                onTap: () => onChanged('ar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code;
  final String name;
  final bool isSelected;
  final String flag;
  final VoidCallback onTap;

  const _LangOption({
    required this.code,
    required this.name,
    required this.isSelected,
    required this.flag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : context.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? null
                : Border.all(
                    color: context.dividerColor,
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(flag, style: TextStyle(fontSize: 28.sp)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                name,
                style: AppTextStyles.bodySmall(
                  weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.white
                      : (context.textPrimaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall(
                        weight: FontWeight.w500,
                        color: textColor ?? context.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption(
                          color: context.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: context.textHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
