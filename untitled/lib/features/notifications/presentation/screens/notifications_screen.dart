import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_icons.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/routing/app_routes.dart';
import 'package:babysitter/core/services/deep_link_service.dart';
import 'package:babysitter/core/services/notification_localization_service.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/notifications/data/notification_provider.dart';
import 'package:babysitter/features/notifications/presentation/widgets/widgets.dart';
import 'package:babysitter/shared/models/notification_model.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(
      () => ref.read(paginatedNotificationsProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedNotificationsProvider.notifier).loadMore();
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    final notifier = ref.read(paginatedNotificationsProvider.notifier);
    final state = ref.read(paginatedNotificationsProvider);

    if (state.isSelectionMode) {
      notifier.toggleSelection(notification.id);
      return;
    }

    if (!notification.isRead) {
      notifier.markAsRead(notification.id);
    }

    _showNotificationDetail(notification);
  }

  void _showNotificationDetail(NotificationModel notification) {
    final locale = ref.read(languageProvider).code;
    final iconData = AppIcons.resolve(notification.icon, fallback: _cardIcon(notification.category));
    final color = _cardColor(notification.category);
    final localizedTitle = notification.localizedTitle(locale);
    final localizedBody = notification.localizedBody(locale);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final strings = AppLocalization.get(locale);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl,
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.12),
                      color.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(iconData, size: 28, color: color),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            NotificationLocalizationService.resolveCategory(
                              locale,
                              notification.category,
                            ),
                            style: AppTextStyles.caption(
                              color: color,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            localizedTitle,
                            style: AppTextStyles.titleMedium(
                              weight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (notification.priority == NotificationPriority.high ||
                        notification.priority == NotificationPriority.critical)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.error,
                              AppColors.error.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          strings['urgent'] ?? 'Urgent',
                          style: AppTextStyles.caption(
                            color: AppColors.white,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (localizedBody.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  localizedBody,
                  style: AppTextStyles.bodyMedium(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: context.textMutedColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatDetailTime(notification.createdAt, locale),
                    style: AppTextStyles.caption(
                      color: context.textMutedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _primaryAction(notification: notification, ctx: ctx, strings: strings),
              if (_hasSecondaryAction(notification)) ...[
                const SizedBox(height: AppSpacing.sm),
                _secondaryAction(notification: notification, ctx: ctx, strings: strings),
              ],
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _openLink('https://babysitter.app/terms'),
                      child: Text(
                        strings['terms'] ?? 'Terms',
                        style: AppTextStyles.caption(
                          color: AppColors.primary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: context.dividerColor,
                    ),
                    GestureDetector(
                      onTap: () => _openLink('https://babysitter.app/privacy'),
                      child: Text(
                        strings['privacy_policy'] ?? 'Privacy Policy',
                        style: AppTextStyles.caption(
                          color: AppColors.primary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _hasSecondaryAction(NotificationModel n) {
    final dt = n.deepLinkType;
    if (dt != null) {
      return dt == 'booking' || dt == 'payment' || dt == 'subscription' || dt == 'security';
    }
    final cat = n.category;
    return cat == 'booking' || cat == 'payment' || cat == 'subscription';
  }

  Widget _primaryAction({
    required NotificationModel notification,
    required BuildContext ctx,
    required Map<String, String> strings,
  }) {
    final label = _primaryLabel(notification, strings);
    final icon = _primaryIcon(notification);
    if (label == null) return const SizedBox.shrink();

    final type = notification.deepLinkType ?? notification.category;
    final id = notification.deepLinkId;

    final role = ref.read(roleManagerProvider).activeRole;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: AppButton(
        text: label,
        prefixIcon: Icon(icon, size: 18),
        onPressed: () {
          Navigator.pop(ctx);
          DeepLinkService.navigateFromContext(context, type, id, role: role);
        },
        variant: AppButtonVariant.tonal,
        height: 48,
        fontSize: 13,
      ),
    );
  }

  String? _primaryLabel(NotificationModel n, Map<String, String> strings) {
    final dt = n.deepLinkType;
    if (dt != null) {
      switch (dt) {
        case 'booking': return strings['view_booking'] ?? 'View Booking';
        case 'review': return strings['view_review'] ?? 'View Review';
        case 'followers': return strings['view_profile'] ?? 'View Profile';
        case 'support': return strings['contact_support'] ?? 'Contact Support';
        case 'payment': return strings['view_payment'] ?? 'View Payment';
        case 'subscription': return strings['view_subscription'] ?? 'View Subscription';
        case 'settings': return strings['open_settings'] ?? 'Open Settings';
        case 'security': return strings['security_settings'] ?? 'Security Settings';
      }
    }
    switch (n.category) {
      case 'booking': return strings['view_booking'] ?? 'View Booking';
      case 'review': return strings['view_review'] ?? 'View Review';
      case 'followers': return strings['view_profile'] ?? 'View Profile';
      case 'support': return strings['contact_support'] ?? 'Contact Support';
      case 'security': return strings['security_settings'] ?? 'Security Settings';
      default: return null;
    }
  }

  IconData _primaryIcon(NotificationModel n) {
    final dt = n.deepLinkType;
    if (dt != null) {
      switch (dt) {
        case 'booking': return Icons.event_available_rounded;
        case 'review': return Icons.star_rounded;
        case 'followers': return Icons.person_rounded;
        case 'support': return Icons.support_agent_rounded;
        case 'payment': return Icons.payment_rounded;
        case 'subscription': return Icons.workspace_premium_rounded;
        case 'settings': return Icons.settings_rounded;
        case 'security': return Icons.shield_rounded;
      }
    }
    switch (n.category) {
      case 'booking': return Icons.event_available_rounded;
      case 'review': return Icons.star_rounded;
      case 'followers': return Icons.person_rounded;
      case 'support': return Icons.support_agent_rounded;
      case 'security': return Icons.shield_rounded;
      default: return Icons.arrow_forward_rounded;
    }
  }

  Widget _secondaryAction({
    required NotificationModel notification,
    required BuildContext ctx,
    required Map<String, String> strings,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: AppButton(
        text: strings['contact_support'] ?? 'Contact Support',
        prefixIcon: const Icon(Icons.support_agent_rounded, size: 18),
        onPressed: () {
          Navigator.pop(ctx);
          context.push(AppRoutes.support);
        },
        variant: AppButtonVariant.outlined,
        height: 48,
        fontSize: 13,
      ),
    );
  }

  IconData _cardIcon(String category) {
    return AppIcons.resolve(category, fallback: Icons.notifications_none_rounded);
  }

  Color _cardColor(String category) {
    switch (category) {
      case 'booking': return AppColors.primary;
      case 'review': return AppColors.warning;
      case 'followers': return AppColors.accent;
      case 'security': return AppColors.error;
      case 'support': return AppColors.success;
      case 'subscription': return AppColors.accent;
      case 'system': return AppColors.primary;
      default: return AppColors.primary;
    }
  }

  String _formatDetailTime(DateTime dateTime, String locale) {
    return TimeFormatter.formatDetailTime(dateTime.toIso8601String(), locale);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider).code;
    final strings = AppLocalization.get(locale);
    final state = ref.watch(paginatedNotificationsProvider);
    final notifier = ref.read(paginatedNotificationsProvider.notifier);

    return Scaffold(
      appBar: AppAppBar(
        title: strings[AppLocalization.notifications] ?? 'Notifications',
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => setState(() => _showSearch = true),
            ),
          if (!_showSearch && state.notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                switch (value) {
                  case 'read_all':
                    notifier.markAllAsRead();
                    break;
                  case 'select':
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(strings[AppLocalization.mark_all_read] ?? 'Mark All Read'),
                    ],
                  ),
                ),
              ],
            ),
          if (_showSearch)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _showSearch = false;
                  _searchController.clear();
                });
                notifier.search('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppTextField(
                controller: _searchController,
                hint: strings[AppLocalization.search_notifications] ??
                    'Search notifications...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                onChanged: (value) {
                  notifier.setSearchQuery(value);
                },
                onSubmitted: (value) {
                  notifier.search(value);
                },
              ),
            ),
          NotificationFilterBar(),
          if (state.isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: NotificationBulkActions(),
            ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: _buildBody(strings, state, notifier, locale),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    Map<String, String> strings,
    PaginatedNotificationsState state,
    PaginatedNotificationsNotifier notifier,
    String locale,
  ) {
    if (state.isLoading) {
      return const _NotificationShimmer();
    }

    if (state.error != null && state.notifications.isEmpty) {
      return ErrorState(
        message: state.error ?? 'Please check your connection and try again',
        onRetry: notifier.load,
      );
    }

    if (state.notifications.isEmpty) {
      return EmptyState(
        title: state.searchQuery.isNotEmpty
            ? (strings[AppLocalization.no_results] ?? 'No results found')
            : (strings[AppLocalization.no_notifications] ??
                'No notifications yet'),
        subtitle: state.searchQuery.isNotEmpty
            ? (strings[AppLocalization.try_different_search] ??
                'Try a different search term')
            : (strings[AppLocalization.all_caught_up] ??
                "You're all caught up!"),
        icon: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
          child: Icon(
            state.searchQuery.isNotEmpty
                ? Icons.search_off_rounded
                : Icons.notifications_none_rounded,
            size: 40,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final grouped = state.groupedByDate(locale);
    final groupOrder = locale == 'ar'
        ? ['اليوم', 'أمس', 'هذا الأسبوع', 'سابقاً']
        : ['Today', 'Yesterday', 'This Week', 'Earlier'];
    final displayGroups =
        groupOrder.where((g) => grouped.containsKey(g)).toList();

    return RefreshIndicator(
      onRefresh: () async => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
            .copyWith(bottom: AppSpacing.xxxl),
        itemCount: _totalItemCount(grouped, displayGroups, state.hasMore),
        itemBuilder: (context, index) {
          int offset = 0;
          for (final group in displayGroups) {
            if (index == offset) {
              return NotificationGroupHeader(title: _groupTitle(group, strings));
            }
            offset++;
            final items = grouped[group]!;
            final itemIndex = index - offset;
            if (itemIndex < items.length) {
              final notification = items[itemIndex];
              return NotificationCard(
                notification: notification,
                isSelected: state.selectedIds.contains(notification.id),
                isSelectionMode: state.isSelectionMode,
                onTap: () => _handleNotificationTap(notification),
                onLongPress: () {
                  notifier.toggleSelection(notification.id);
                },
                onMarkRead: () => notifier.markAsRead(notification.id),
                onDelete: () => notifier.deleteNotification(notification.id),
              );
            }
            offset += items.length;
          }

          if (state.hasMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  int _totalItemCount(
    Map<String, List<NotificationModel>> grouped,
    List<String> displayGroups,
    bool hasMore,
  ) {
    int count = 0;
    for (final group in displayGroups) {
      count++; // header
      count += grouped[group]!.length; // items
    }
    if (hasMore) count++;
    return count;
  }

  String _groupTitle(String group, Map<String, String> strings) {
    // Map internal group keys to localized display labels.
    // Internal keys are always in English (set by TimeFormatter.notificationGroupKey).
    return switch (group) {
      'Today'     => strings['today']     ?? group,
      'Yesterday' => strings['yesterday'] ?? group,
      'This Week' => strings['this_week'] ?? group,
      'Earlier'   => strings['earlier']   ?? group,
      // Arabic fallback — TimeFormatter may return Arabic strings directly.
      'اليوم'      => strings['today']     ?? group,
      'أمس'        => strings['yesterday'] ?? group,
      'هذا الأسبوع' => strings['this_week'] ?? group,
      'سابقاً'     => strings['earlier']   ?? group,
      _           => group,
    };
  }
}

class _NotificationShimmer extends StatelessWidget {
  const _NotificationShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppShimmer(width: 44, height: 44, borderRadius: 10),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppShimmer(width: 180, height: 14),
                  const SizedBox(height: AppSpacing.sm),
                  const AppShimmer(width: double.infinity, height: 12),
                  const SizedBox(height: AppSpacing.xs),
                  const AppShimmer(width: 60, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
