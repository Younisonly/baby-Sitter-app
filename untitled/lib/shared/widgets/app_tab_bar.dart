import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_shadows.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_durations.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/theme_colors.dart';

// ============================================================================
// AppTabBar — Premium pill-style tab bar with modern gradient accent
// Integrates with TabController + TabBarView
// ============================================================================

class AppTabBar extends StatefulWidget {
  final TabController controller;
  final List<String> tabs;
  final double height;

  const AppTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.height = 48,
  });

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.controller.index;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
            : cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: List.generate(widget.tabs.length, (i) {
          final isSelected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                widget.controller.animateTo(i);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: AppDurations.fast,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            cs.primary,
                            cs.primary.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    widget.tabs[i],
                    style: AppTextStyles.bodySmall(
                      weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? cs.onPrimary
                          : cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================================
// AppSegmentedControl — Premium segmented control
// Smaller variant for inline use
// ============================================================================

class AppSegmentedControl extends StatefulWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 40,
  });

  @override
  State<AppSegmentedControl> createState() => _AppSegmentedControlState();

}

class _AppSegmentedControlState extends State<AppSegmentedControl> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(widget.options.length, (i) {
          final isSelected = i == widget.selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                widget.onChanged(i);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: AppDurations.fast,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? AppShadows.subtle : null,
                ),
                child: Center(
                  child: Text(
                    widget.options[i],
                    style: AppTextStyles.labelMedium(
                      weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? context.textPrimaryColor
                          : context.textMutedColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================================
// AppFilterChip — Premium dismissible filter chip
// For active filter tags with removal option
// ============================================================================

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDismiss;
  final VoidCallback? onDismiss;

  const AppFilterChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.showDismiss = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? context.primaryColor.withValues(alpha: 0.2)
                  : context.primaryColor.withValues(alpha: 0.1))
              : (isDark
                  ? context.theme.cardColor.withValues(alpha: 0.3)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.3)
                : context.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium(
                weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? context.primaryColor
                    : context.textSecondaryColor,
              ),
            ),
            if (showDismiss) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: context.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AppFilterChipGroup — Wraps multiple AppFilterChip in a Wrap layout
// Supports single or multi selection
// ============================================================================

class AppFilterChipGroup extends StatelessWidget {
  final List<String> options;
  final Set<int> selectedIndices;
  final ValueChanged<int> onSelected;
  final bool multiSelect;
  final double spacing;
  final double runSpacing;

  const AppFilterChipGroup({
    super.key,
    required this.options,
    required this.selectedIndices,
    required this.onSelected,
    this.multiSelect = false,
    this.spacing = AppSpacing.sm,
    this.runSpacing = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: List.generate(options.length, (i) {
        final isSelected = selectedIndices.contains(i);
        return AppFilterChip(
          label: options[i],
          isSelected: isSelected,
          onTap: () => onSelected(i),
        );
      }),
    );
  }
}

// ============================================================================
// AppAnalyticsFilter — Premium time period selector
// Horizontal scrollable pill buttons for analytics/statistics screens
// ============================================================================

class AppAnalyticsFilter extends StatefulWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AppAnalyticsFilter({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  State<AppAnalyticsFilter> createState() => _AppAnalyticsFilterState();
}

class _AppAnalyticsFilterState extends State<AppAnalyticsFilter> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: widget.options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final isSelected = i == widget.selectedIndex;
          return GestureDetector(
            onTap: () {
              widget.onChanged(i);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: isSelected
                      ? context.primaryColor
                      : context.dividerColor,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                widget.options[i],
                style: AppTextStyles.bodySmall(
                  weight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.textSecondaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// AppCategoryTab — Premium scrollable category selector
// Clean indicator bar for categories like "All", "Pets", "Childcare", etc.
// ============================================================================

class AppCategoryTab extends StatefulWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AppCategoryTab({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  State<AppCategoryTab> createState() => _AppCategoryTabState();
}

class _AppCategoryTabState extends State<AppCategoryTab> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: widget.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemBuilder: (_, i) {
          final isSelected = i == widget.selectedIndex;
          return GestureDetector(
            onTap: () {
              widget.onChanged(i);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                color: isSelected
                    ? context.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.categories[i],
                    style: AppTextStyles.bodySmall(
                      weight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? context.primaryColor
                          : context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: AppDurations.fast,
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 20 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
