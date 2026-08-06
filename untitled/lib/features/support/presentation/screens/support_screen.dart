import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/support/data/contact_setting_provider.dart';
import 'package:babysitter/shared/models/contact_setting_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(contactSettingProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final state = ref.watch(contactSettingProvider);

    return Scaffold(
      appBar: AppAppBar(title: strings[AppLocalization.contact_support]),
      body: _buildBody(strings, state),
    );
  }

  Widget _buildBody(Map<String, String> strings, ContactSettingState state) {
    switch (state.status) {
      case ContactSettingStatus.initial:
      case ContactSettingStatus.loading:
        return const _SupportShimmer();
      case ContactSettingStatus.error:
        return ErrorState(
          title:
              strings[AppLocalization.support_help_title] ?? 'Failed to load',
          message:
              state.error ?? 'Please check your connection and try again',
          onRetry: () => ref.read(contactSettingProvider.notifier).load(),
        );
      case ContactSettingStatus.success:
        final settings = state.settings;
        if (settings == null) {
          return ErrorState(
            title: strings[AppLocalization.no_contact_info] ?? 'No contact information',
            message: 'Contact settings are not available.',
            onRetry: () => ref.read(contactSettingProvider.notifier).load(),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(contactSettingProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildHeader(strings),
              const SizedBox(height: AppSpacing.lg),
              _buildContactList(strings, settings),
            ],
          ),
        );
    }
  }

  Widget _buildHeader(Map<String, String> strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Icon(Icons.headset_mic_rounded, size: 56.sp, color: Colors.white),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings[AppLocalization.support_help_title] ?? 'How can we help?',
            style: AppTextStyles.headlineMedium(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings[AppLocalization.support_help_subtitle] ??
                'Contact us through any of the channels below',
            style: AppTextStyles.bodyMedium(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(
      Map<String, String> strings, ContactSettingModel settings) {
    final contacts = _buildContactItems(strings, settings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: contacts
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ContactCard(
                icon: c.icon,
                label: c.label,
                value: c.value,
                showValue: c.showValue,
                color: c.color,
                onTap: c.onTap,
                copyValue: c.copyValue,
                copyMessage: strings[AppLocalization.support_copied] ?? 'Copied!',
              ),
            ),
          )
          .toList(),
    );
  }

  List<_ContactItem> _buildContactItems(
      Map<String, String> strings, ContactSettingModel settings) {
    return [
      if (settings.email != null)
        _ContactItem(
          icon: Icons.mail_rounded,
          label: strings[AppLocalization.support_email] ?? 'Email',
          value: settings.email!,
          showValue: true,
          copyValue: settings.email!,
          color: const Color(0xFF6366F1),
          onTap: () => _launch('mailto:${settings.email}'),
        ),
      if (settings.phone != null)
        _ContactItem(
          icon: Icons.phone_rounded,
          label: strings[AppLocalization.support_phone] ?? 'Phone',
          value: settings.phone!,
          showValue: true,
          copyValue: settings.phone!,
          color: const Color(0xFF22C55E),
          onTap: () => _launch('tel:${settings.phone}'),
        ),
      if (settings.whatsapp != null)
        _ContactItem(
          icon: Icons.chat_bubble_rounded,
          label: strings[AppLocalization.support_whatsapp] ?? 'WhatsApp',
          value: settings.whatsapp!,
          showValue: false,
          copyValue: settings.whatsapp!,
          color: const Color(0xFF25D366),
          onTap: () => _launch(settings.whatsapp!),
        ),
      if (settings.facebook != null)
        _ContactItem(
          icon: Icons.facebook_rounded,
          label: strings[AppLocalization.support_facebook] ?? 'Facebook',
          value: settings.facebook!,
          showValue: false,
          copyValue: settings.facebook!,
          color: const Color(0xFF1877F2),
          onTap: () => _launch(settings.facebook!),
        ),
      if (settings.instagram != null)
        _ContactItem(
          icon: Icons.photo_camera_rounded,
          label: strings[AppLocalization.support_instagram] ?? 'Instagram',
          value: settings.instagram!,
          showValue: false,
          copyValue: settings.instagram!,
          color: const Color(0xFFE4405F),
          onTap: () => _launch(settings.instagram!),
        ),
      if (settings.x != null)
        _ContactItem(
          icon: Icons.alternate_email_rounded,
          label: strings[AppLocalization.support_x] ?? 'X',
          value: settings.x!,
          showValue: false,
          copyValue: settings.x!,
          color: const Color(0xFF1DA1F2),
          onTap: () => _launch(settings.x!),
        ),
      if (settings.website != null)
        _ContactItem(
          icon: Icons.language_rounded,
          label: strings[AppLocalization.support_website] ?? 'Website',
          value: settings.website!,
          showValue: false,
          copyValue: settings.website!,
          color: const Color(0xFF8B5CF6),
          onTap: () => _launch(settings.website!),
        ),
    ];
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}

class _ContactItem {
  final IconData icon;
  final String label;
  final String value;
  final bool showValue;
  final String copyValue;
  final Color color;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.showValue,
    required this.copyValue,
    required this.color,
    required this.onTap,
  });
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showValue;
  final Color color;
  final VoidCallback onTap;
  final String copyValue;
  final String copyMessage;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.showValue,
    required this.color,
    required this.onTap,
    required this.copyValue,
    required this.copyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.titleMedium(
                          weight: FontWeight.w600,
                        ),
                      ),
                      if (showValue) ...[
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: AppTextStyles.caption(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: copyValue));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(copyMessage),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.dividerColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportShimmer extends StatelessWidget {
  const _SupportShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const AppShimmer(
          width: double.infinity,
          height: 180,
          borderRadius: AppRadius.xl,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppShimmer(
          width: double.infinity,
          height: 80,
          borderRadius: AppRadius.lg,
        ),
        const SizedBox(height: AppSpacing.sm),
        const AppShimmer(
          width: double.infinity,
          height: 80,
          borderRadius: AppRadius.lg,
        ),
        const SizedBox(height: AppSpacing.sm),
        const AppShimmer(
          width: double.infinity,
          height: 80,
          borderRadius: AppRadius.lg,
        ),
        const SizedBox(height: AppSpacing.sm),
        const AppShimmer(
          width: double.infinity,
          height: 80,
          borderRadius: AppRadius.lg,
        ),
      ],
    );
  }
}
