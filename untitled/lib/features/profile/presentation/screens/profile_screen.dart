import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_image_types.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_sizes.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final user = ref.watch(authProvider).user;
    final unreadCount = ref.watch(appStateProvider).unreadNotifications;
    final roleState = ref.watch(roleManagerProvider);
    final isSitter = roleState.isSitter;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: AppSpacing.lg),
              _ProfileHeader(
                avatarUrl: user?.avatar,
                name: user?.name ?? 'User',
                email: user?.email ?? '',
                phone: user?.phone ?? '',
              ),
              if (!isSitter && !roleState.hasMultipleRoles)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                  child: _BecomeSitterCard(
                    strings: strings,
                    onTap: () => context.push(AppRoutes.becomeSitter),
                  ),
                ),
              if (roleState.hasMultipleRoles)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: _RoleBadge(
                    isSitter: isSitter,
                    strings: strings,
                    onSwitchRole: () {
                      final isTargetSitter = !isSitter;
                      final roleIcon = isTargetSitter ? Icons.badge_rounded : Icons.family_restroom_rounded;
                      final confirmLabel = isTargetSitter
                          ? (strings[AppLocalization.switch_to_sitter] ?? 'Switch to Sitter')
                          : (strings[AppLocalization.switch_to_parent] ?? 'Switch to Parent');
                      AppDialog.show(
                        context: context,
                        icon: roleIcon,
                        title: strings['switch_role_title'] ?? 'Switch Role',
                        content: isTargetSitter
                            ? (strings[AppLocalization.switch_role_confirm_sitter] ?? 'Switch to Sitter mode?')
                            : (strings[AppLocalization.switch_role_confirm_parent] ?? 'Switch to Parent mode?'),
                        confirmText: confirmLabel,
                        cancelText: strings['cancel'] ?? 'Cancel',
                        onConfirm: () {
                          if (isTargetSitter) {
                            ref.read(roleManagerProvider.notifier).switchToSitter();
                            context.go(AppRoutes.sitterDashboard);
                          } else {
                            ref.read(roleManagerProvider.notifier).switchToParent();
                            context.go(AppRoutes.parentHome);
                          }
                        },
                      );
                    },
                  ),
                ),
              SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    _ProfileSection(
                      title: strings[AppLocalization.account] ?? 'Account',
                      children: [
                        _ProfileTile(
                          icon: Icons.person_outline,
                          title: strings[AppLocalization.edit_profile] ??
                              'Edit Profile',
                          onTap: () => context.push(AppRoutes.editProfile),
                        ),
                        _ProfileTile(
                          icon: Icons.favorite_border,
                          title:
                              strings[AppLocalization.favorites] ?? 'Favorites',
                          onTap: () => context.pushNamed(AppRoutes.favorites),
                        ),
                        _ProfileTile(
                          icon: Icons.payment_outlined,
                          title: strings[AppLocalization.payment_methods] ??
                              'Payment Methods',
                          onTap: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _ProfileSection(
                      title: strings[AppLocalization.settings] ?? 'Settings',
                      children: [
                        _ProfileTile(
                          icon: Icons.notifications_none,
                          title:
                              strings[AppLocalization.notifications] ??
                                  'Notifications',
                          leadingWidget: unreadCount > 0
                              ? Badge(
                                  label: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : '$unreadCount',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.notifications_none,
                                    size: AppSizes.iconSize22,
                                    color: context.textSecondary,
                                  ),
                                )
                              : null,
                          onTap: () => context.push(AppRoutes.notifications),
                        ),
                        _ProfileTile(
                          icon: Icons.tune_rounded,
                          title:
                              strings[AppLocalization.settings] ??
                                  'Settings',
                          onTap: () => context.push(AppRoutes.settings),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    SizedBox(height: AppSpacing.xl),
                    Text(
                      (strings[AppLocalization.app_version] ?? 'v{version}')
                          .replaceAll('{version}', '1.0.0'),
                      style: AppTextStyles.caption(),
                    ),
                    SizedBox(height: AppSpacing.lg),
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

class _ProfileHeader extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String email;
  final String phone;

  const _ProfileHeader({
    this.avatarUrl,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasEmail = email.isNotEmpty;
    final hasPhone = phone.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.08),
            cs.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: AppImagePreview.canPreview(avatarUrl)
                  ? () => AppImagePreview.show(context, avatarUrl, name: name)
                  : null,
              child: ClipOval(
                child: AppNetworkImage(
                  imageUrl: avatarUrl,
                  width: 80,
                  height: 80,
                  imageType: AppImageType.avatar,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: AppTextStyles.titleLarge(
              weight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          if (hasEmail || hasPhone) ...[
            const SizedBox(height: AppSpacing.xxs),
            if (hasEmail)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  email,
                  style: AppTextStyles.bodyMedium(color: context.textSecondaryColor),
                ),
              ),
            if (hasPhone)
              Text(
                phone,
                style: AppTextStyles.bodySmall(color: context.textMutedColor),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _ProfileSection({
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title!,
              style: AppTextStyles.titleSmall(
                color: context.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: children
                .expand(
                  (child) => [
                    child,
                    Divider(
                      height: 1,
                      indent: AppSpacing.lg,
                      endIndent: AppSpacing.lg,
                    ),
                  ],
                )
                .toList()
              ..removeLast(),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? leadingWidget;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.leadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leadingWidget ??
          Icon(
            icon,
            size: AppSizes.iconSize22,
            color: context.textSecondary,
          ),
      title: Text(
        title,
        style: AppTextStyles.titleMedium(
          color: context.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: AppSizes.iconSize20,
        color: context.textMuted,
      ),
      onTap: onTap,
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isSitter;
  final Map<String, String> strings;
  final VoidCallback onSwitchRole;

  const _RoleBadge({
    required this.isSitter,
    required this.strings,
    required this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: (isSitter ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isSitter ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSitter ? Icons.work_rounded : Icons.family_restroom_rounded,
            size: 18,
            color: isSitter ? AppColors.secondary : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isSitter
                  ? (strings[AppLocalization.current_mode_sitter] ?? 'Current Mode: Sitter')
                  : (strings[AppLocalization.current_mode_parent] ?? 'Current Mode: Parent'),
              style: AppTextStyles.titleSmall(
                weight: FontWeight.w600,
                color: isSitter ? AppColors.secondary : AppColors.primary,
              ),
            ),
          ),
          InkWell(
            onTap: onSwitchRole,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 16,
                      color: isSitter ? AppColors.secondary : AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    strings[AppLocalization.switch_role] ?? 'Switch',
                    style: AppTextStyles.labelSmall(
                      color: isSitter ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BecomeSitterCard extends StatelessWidget {
  final Map<String, String> strings;
  final VoidCallback onTap;

  const _BecomeSitterCard({
    required this.strings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.badge_rounded,
              size: 22,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings[AppLocalization.become_sitter_action] ?? 'Become a Sitter',
                  style: AppTextStyles.titleSmall(
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  strings[AppLocalization.create_sitter_profile_desc] ?? 'Create your sitter profile, set your rates, and start earning',
                  style: AppTextStyles.caption(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings[AppLocalization.get_started] ?? 'Start',
                        style: AppTextStyles.labelSmall(
                          color: Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
