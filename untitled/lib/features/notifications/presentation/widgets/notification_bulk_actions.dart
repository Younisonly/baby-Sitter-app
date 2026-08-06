import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/notifications/data/notification_provider.dart';

class NotificationBulkActions extends ConsumerWidget {
  const NotificationBulkActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final state = ref.watch(paginatedNotificationsProvider);
    final notifier = ref.read(paginatedNotificationsProvider.notifier);

    if (!state.isSelectionMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: notifier.clearSelection,
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${state.selectedIds.length}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: notifier.markSelectedAsRead,
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: Text(
              strings[AppLocalization.mark_read] ?? 'Read',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton.icon(
            onPressed: notifier.deleteSelected,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(
              strings[AppLocalization.delete] ?? 'Delete',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (state.selectedIds.length < state.notifications.length) ...[
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: notifier.selectAll,
              child: Text(
                strings[AppLocalization.select_all] ?? 'All',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
