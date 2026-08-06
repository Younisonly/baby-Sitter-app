import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';

class RoleSwitcher extends ConsumerWidget {
  const RoleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(roleManagerProvider);
    final currentRole = roleState.activeRole;
    final strings = AppLocalization.get(ref.watch(languageProvider).code);

    return PopupMenuButton<AppRole>(
      onSelected: (role) async {
        if (role == currentRole) return;
        await ref.read(roleManagerProvider.notifier).switchTo(role);
        if (!context.mounted) return;
        switch (role) {
          case AppRole.parent:
            context.go(AppRoutes.parentHome);
          case AppRole.sitter:
            context.go(AppRoutes.sitterDashboard);
          case AppRole.visitor:
            context.go(AppRoutes.visitorHome);
        }
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        if (currentRole != AppRole.parent)
          PopupMenuItem(
            value: AppRole.parent,
            child: _RoleOption(
              icon: Icons.family_restroom_rounded,
              title: strings['parent_mode'] ?? 'Parent Mode',
              subtitle: strings['parent_mode_desc'] ?? 'Find and book sitters',
            ),
          ),
        if (currentRole != AppRole.sitter)
          PopupMenuItem(
            value: AppRole.sitter,
            child: _RoleOption(
              icon: Icons.work_rounded,
              title: strings['sitter_mode'] ?? 'Sitter Mode',
              subtitle: strings['sitter_mode_desc'] ?? 'Manage your business',
            ),
          ),
        if (currentRole != AppRole.visitor)
          PopupMenuItem(
            value: AppRole.visitor,
            child: _RoleOption(
              icon: Icons.visibility_rounded,
              title: strings['visitor_mode'] ?? 'Visitor Mode',
              subtitle: strings['visitor_mode_desc'] ?? 'Browse as guest',
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _roleColor(currentRole).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _roleColor(currentRole).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _roleIcon(currentRole),
              size: 16,
              color: _roleColor(currentRole),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _roleLabel(currentRole, strings),
              style: AppTextStyles.labelSmall(
                color: _roleColor(currentRole),
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: _roleColor(currentRole),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(AppRole role) {
    switch (role) {
      case AppRole.parent:
        return const Color(0xFF667eea);
      case AppRole.sitter:
        return const Color(0xFFf5576c);
      case AppRole.visitor:
        return Colors.grey;
    }
  }

  IconData _roleIcon(AppRole role) {
    switch (role) {
      case AppRole.parent:
        return Icons.family_restroom_rounded;
      case AppRole.sitter:
        return Icons.work_rounded;
      case AppRole.visitor:
        return Icons.visibility_rounded;
    }
  }

  String _roleLabel(AppRole role, Map<String, String> strings) {
    switch (role) {
      case AppRole.parent:
        return strings['parent'] ?? 'Parent';
      case AppRole.sitter:
        return strings['sitter'] ?? 'Sitter';
      case AppRole.visitor:
        return strings['visitor'] ?? 'Visitor';
    }
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: context.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: context.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
