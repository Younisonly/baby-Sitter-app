import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/api_response.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/chat/data/chat_repository.dart';
import 'package:babysitter/features/chat/presentation/providers/chat_provider.dart';
import 'package:babysitter/features/chat/presentation/screens/conversation_detail_screen.dart';
import 'package:babysitter/features/chat/presentation/helpers/time_helpers.dart';
import 'package:babysitter/shared/models/chat_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';
import 'dart:async';

class ChatScreen extends ConsumerStatefulWidget {
  final String? initialConversationId;
  final String? initialUserId;
  final String? bookingId;

  const ChatScreen({super.key, this.initialConversationId, this.initialUserId, this.bookingId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  ConversationsNotifier? _convNotifier;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _convNotifier = ref.read(conversationsProvider.notifier);
      _convNotifier!.loadConversations();
      _convNotifier!.startPolling();

      final rawConversationId = widget.initialConversationId;
      if (rawConversationId != null && rawConversationId.isNotEmpty) {
        final conversationId = int.tryParse(rawConversationId);
        if (conversationId == null) return;
        _openConversation(conversationId);
        return;
      }

      final rawUserId = widget.initialUserId;
      if (rawUserId != null && rawUserId.isNotEmpty) {
        final userId = int.tryParse(rawUserId);
        if (userId == null) return;
        _startConversation(userId);
      }
    });
  }

  Future<void> _openConversation(int conversationId) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conversation = await repo.getConversation(conversationId);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailScreen(conversation: conversation),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final strings = AppLocalization.get(ref.read(languageProvider).code);
        AppSnackbar.error(context, strings['chat_load_failed'] ?? 'Could not open conversation');
      }
    }
  }

  Future<void> _startConversation(int userId) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conversation = await repo.startConversation(userId);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailScreen(conversation: conversation),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final strings = AppLocalization.get(ref.read(languageProvider).code);
        AppSnackbar.error(context, strings['chat_create_failed'] ?? 'Could not start conversation');
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _convNotifier?.stopPolling();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200.h) {
      ref.read(conversationsProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(conversationsProvider.notifier).setSearchQuery(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider).code;
    final strings = AppLocalization.get(locale);
    final conversationsAsync = ref.watch(conversationsProvider);

    return AppScaffold(
      title: strings[AppLocalization.chat] ?? 'Messages',
      showBackButton: false,
      showMenuButton: false,
      body: Column(
        children: [
          _buildSearchBar(strings),
          _buildTabBar(strings),
          Expanded(
            child: conversationsAsync.when(
              loading: () => _buildShimmer(),
              error: (error, _) => _buildError(strings),
              data: (data) {
                if (data.items.isEmpty) return _buildEmpty(strings);
                return _buildList(strings, data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Map<String, String> strings) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md.w,
        AppSpacing.xs.h,
        AppSpacing.md.w,
        0,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: strings['search_conversations'] ?? 'Search conversations...',
          prefixIcon: Icon(Icons.search_rounded, size: 20.w),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18.w),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: context.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md.w,
            vertical: AppSpacing.sm.h,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(Map<String, String> strings) {
    final notifier = ref.read(conversationsProvider.notifier);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          _TabChip(
            label: strings['all'] ?? 'All',
            selected: !notifier.showArchived,
            onTap: () => notifier.setShowArchived(false),
          ),
          SizedBox(width: AppSpacing.sm.w),
          _TabChip(
            label: strings['archived'] ?? 'Archived',
            selected: notifier.showArchived,
            onTap: () => notifier.setShowArchived(true),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.md.w),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md.h),
        child: Row(
          children: [
            AppShimmer(
              width: 38.w,
              height: 38.w,
              borderRadius: AppRadius.full,
              isCircular: true,
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(
                    width: 120.w,
                    height: 14.h,
                    borderRadius: AppRadius.sm,
                  ),
                  SizedBox(height: AppSpacing.xs.h),
                  AppShimmer(
                    width: double.infinity,
                    height: 12.h,
                    borderRadius: AppRadius.sm,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            AppShimmer(
              width: 36.w,
              height: 12.h,
              borderRadius: AppRadius.sm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Map<String, String> strings) {
    return AppErrorState(
      title: strings[AppLocalization.something_went_wrong] ?? 'Something went wrong',
      message: strings[AppLocalization.load_error_desc] ??
          'Please check your connection and try again.',
      onRetry: () =>
          ref.read(conversationsProvider.notifier).loadConversations(refresh: true),
    );
  }

  Widget _buildEmpty(Map<String, String> strings) {
    return AppEmptyState(
      title: strings[AppLocalization.no_messages_yet] ?? 'No Messages Yet',
      subtitle: strings[AppLocalization.no_messages_subtitle] ??
          'Your conversations with babysitters will appear here.',
      icon: Icon(
        Icons.chat_bubble_outline_rounded,
        size: 40.w,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildList(
    Map<String, String> strings,
    PaginatedList<ConversationModel> data,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(conversationsProvider.notifier)
            .loadConversations(refresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(AppSpacing.md.w),
        itemCount: data.items.length + (data.pagination.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= data.items.length) {
            return Padding(
              padding: EdgeInsets.all(AppSpacing.md.h),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _ConversationTile(
            conversation: data.items[index],
            onArchive: () => _handleArchive(data.items[index]),
            onUnarchive: () => _handleUnarchive(data.items[index]),
            onDelete: () => _handleDelete(data.items[index]),
          ).animate().fadeIn(duration: 400.ms);
        },
      ),
    );
  }

  void _handleArchive(ConversationModel conversation) {
    ref.read(conversationsProvider.notifier).archiveConversation(conversation.id);
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    AppSnackbar.success(
      context,
      strings['conversation_archived'] ?? 'Conversation archived',
    );
  }

  void _handleUnarchive(ConversationModel conversation) {
    ref.read(conversationsProvider.notifier).unarchiveConversation(conversation.id);
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    AppSnackbar.success(
      context,
      strings['conversation_unarchived'] ?? 'Conversation unarchived',
    );
  }

  void _handleDelete(ConversationModel conversation) {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings['delete_conversation'] ?? 'Delete Conversation'),
        content: Text(
          strings['delete_conversation_confirm'] ??
              'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings[AppLocalization.cancel] ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(conversationsProvider.notifier)
                  .deleteConversation(conversation.id);
              AppSnackbar.success(
                context,
                strings['conversation_deleted'] ?? 'Conversation deleted',
              );
            },
            child: Text(strings[AppLocalization.delete] ?? 'Delete'),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.xs.h,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall(
            color: selected ? AppColors.white : AppColors.primary,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final ConversationModel conversation;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final VoidCallback? onDelete;

  const _ConversationTile({
    required this.conversation,
    this.onArchive,
    this.onUnarchive,
    this.onDelete,
  });

  Widget _buildLeading(BuildContext context) {
    final avatarUrl = conversation.otherUser.avatar;
    final name = conversation.otherUser.name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isInactive = !conversation.otherUser.isActiveSitter;

    Widget avatar;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatar = GestureDetector(
        onTap: AppImagePreview.canPreview(avatarUrl)
            ? () => AppImagePreview.show(context, avatarUrl, name: name)
            : null,
        child: ClipOval(
          child: AppNetworkImage(
            imageUrl: avatarUrl,
            width: 38.w,
            height: 38.w,
            borderRadius: 0,
          ),
        ),
      );
    } else {
      avatar = CircleAvatar(
        radius: 19.r,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          initial,
          style: AppTextStyles.titleSmall(
            color: AppColors.primary,
            weight: FontWeight.w600,
          ),
        ),
      );
    }

    if (isInactive) {
      return Stack(
        children: [
          Opacity(opacity: 0.5, child: avatar),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: context.cardColor, width: 1.5),
              ),
              child: Icon(Icons.block_rounded, size: 9.w, color: AppColors.white),
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  Widget _buildTrailing(BuildContext context, String locale) {
    final time = conversation.lastMessage?.createdAt ?? conversation.createdAt;
    final timeStr = formatConversationTime(time, locale);
    final unreadCount = conversation.unreadCount;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: AppTextStyles.caption(color: context.textMuted),
        ),
        if (unreadCount > 0) ...[
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: AppTextStyles.caption(
                color: AppColors.white,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _messagePreview(LastMessageData? msg) {
    if (msg == null) return '';
    switch (msg.messageType) {
      case 'image':
        return '\u{1F4F7} [Image]';
      case 'voice':
        return '\u{1F3A4} [Voice message]';
      case 'file':
        return '\u{1F4CE} [File]';
      case 'system':
        return msg.content;
      default:
        return msg.content.length > 50
            ? '${msg.content.substring(0, 50)}...'
            : msg.content;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMsg = conversation.lastMessage;
    final preview = _messagePreview(lastMsg);
    final isSystem = lastMsg?.messageType == 'system';

    final locale = ref.watch(languageProvider).code;
    final strings = AppLocalization.get(locale);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ConversationDetailScreen(conversation: conversation),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (conversation.isArchived)
                  ListTile(
                    leading: const Icon(Icons.unarchive_rounded),
                    title: Text(
                      strings['unarchive'] ?? 'Unarchive',
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onUnarchive?.call();
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.archive_rounded),
                    title: Text(
                      strings['archive'] ?? 'Archive',
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onArchive?.call();
                    },
                  ),
                ListTile(
                  leading: Icon(
                    Icons.delete_rounded,
                    color: AppColors.error,
                  ),
                  title: Text(
                    strings[AppLocalization.delete] ?? 'Delete',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onDelete?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs.w,
          vertical: AppSpacing.xs.h,
        ),
        child: Row(
          children: [
            _buildLeading(context),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conversation.otherUser.name,
                      style: AppTextStyles.titleSmall(
                        weight: FontWeight.w600,
                        color: conversation.otherUser.isActiveSitter
                            ? context.textPrimary
                            : context.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    if (!conversation.otherUser.isActiveSitter)
                      Row(
                        children: [
                          Icon(Icons.block_rounded,
                              size: 12.sp, color: AppColors.error),
                          SizedBox(width: 4.w),
                          Text(
                            strings['sitter_account_inactive'] ??
                                'Account inactive',
                            style: AppTextStyles.caption(
                              color: AppColors.error,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        preview,
                        style: AppTextStyles.bodySmall(
                          color: context.textMuted,
                        ).copyWith(
                          fontStyle: isSystem ? FontStyle.italic : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppSpacing.xs.w),
            _buildTrailing(context, locale),
          ],
        ),
      ),
    );
  }
}
