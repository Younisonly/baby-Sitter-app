import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/notifications/data/notification_provider.dart';

class NotificationFilterBar extends ConsumerWidget {
  final ScrollPhysics? physics;

  const NotificationFilterBar({super.key, this.physics});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalization.get(ref.watch(languageProvider).code);
    final activeFilter = ref.watch(paginatedNotificationsProvider).activeFilter;

    final filters = [
      _FilterItem(NotificationFilter.all, strings[AppLocalization.all] ?? 'All'),
      _FilterItem(NotificationFilter.unread, strings[AppLocalization.unread] ?? 'Unread'),
      _FilterItem(NotificationFilter.booking, strings[AppLocalization.bookings] ?? 'Bookings'),
      _FilterItem(NotificationFilter.followers, strings[AppLocalization.favorites] ?? 'Followers'),
      _FilterItem(NotificationFilter.review, strings[AppLocalization.reviews] ?? 'Reviews'),
      _FilterItem(NotificationFilter.security, strings[AppLocalization.security_alerts] ?? 'Security'),
      _FilterItem(NotificationFilter.support, strings[AppLocalization.support] ?? 'Support'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        physics: physics ?? const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = filters[index];
          final isActive = activeFilter == item.filter;

          return GestureDetector(
            onTap: () {
              ref
                  .read(paginatedNotificationsProvider.notifier)
                  .setFilter(item.filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? context.primaryColor
                    : context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? context.primaryColor
                      : context.dividerColor,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  item.label,
                  style: AppTextStyles.labelMedium(
                    color: isActive
                        ? Colors.white
                        : context.textPrimaryColor,
                    weight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterItem {
  final NotificationFilter filter;
  final String label;

  const _FilterItem(this.filter, this.label);
}
