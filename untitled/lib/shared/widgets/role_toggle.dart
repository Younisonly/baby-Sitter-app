import 'package:flutter/material.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/extensions/extensions.dart';

class RoleToggle extends StatelessWidget {
  final bool isSitterSelected;
  final ValueChanged<bool> onToggle;
  final String? parentLabel;
  final String? sitterLabel;

  const RoleToggle({
    super.key,
    required this.isSitterSelected,
    required this.onToggle,
    this.parentLabel,
    this.sitterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: context.isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleTab(
              isSelected: !isSitterSelected,
              icon: Icons.family_restroom_rounded,
              label: parentLabel ?? 'Parent',
              selectedColor: context.primaryColor,
              onTap: () => onToggle(false),
            ),
          ),
          Container(width: 1, height: 28, color: context.dividerColor),
          Expanded(
            child: _ToggleTab(
              isSelected: isSitterSelected,
              icon: Icons.work_rounded,
              label: sitterLabel ?? 'Sitter',
              selectedColor: AppColors.secondary,
              onTap: () => onToggle(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? selectedColor : context.textMutedColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? selectedColor : context.textMutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
