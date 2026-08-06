import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/features/notifications/data/notification_repository.dart';
import 'package:babysitter/core/utils/time_formatter.dart';
import 'package:babysitter/shared/models/notification_model.dart';

enum NotificationFilter {
  all,
  unread,
  booking,
  followers,
  review,
  security,
  support,
  subscription,
}

class PaginatedNotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final NotificationFilter activeFilter;
  final String searchQuery;
  final Set<String> selectedIds;
  final bool isSelectionMode;

  const PaginatedNotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.activeFilter = NotificationFilter.all,
    this.searchQuery = '',
    this.selectedIds = const {},
    this.isSelectionMode = false,
  });

  PaginatedNotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    NotificationFilter? activeFilter,
    String? searchQuery,
    Set<String>? selectedIds,
    bool? isSelectionMode,
  }) {
    return PaginatedNotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  Map<String, List<NotificationModel>> groupedByDate(String locale) {
    final groups = <String, List<NotificationModel>>{};

    for (final n in notifications) {
      final key = _dateGroupKey(n.createdAt, locale);
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(n);
    }

    return groups;
  }

  String _dateGroupKey(DateTime date, String locale) {
    return TimeFormatter.notificationGroupKey(date, locale);
  }
}

class PaginatedNotificationsNotifier
    extends StateNotifier<PaginatedNotificationsState> {
  final NotificationRepository _repository;
  final Ref _ref;

  PaginatedNotificationsNotifier(this._repository, this._ref)
      : super(const PaginatedNotificationsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final filterValue = _filterToString(state.activeFilter);
      final result = await _repository.getNotifications(
        page: 1,
        filter: filterValue,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      final filtered = result.items.where((n) => n.category != 'chat').toList();
      final count = filtered.where((n) => !n.isRead).length;
      _ref.read(appStateProvider.notifier).setUnreadNotifications(count);
      state = PaginatedNotificationsState(
        notifications: filtered,
        hasMore: result.pagination.hasMore,
        currentPage: result.pagination.currentPage,
        activeFilter: state.activeFilter,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final filterValue = _filterToString(state.activeFilter);
      final result = await _repository.getNotifications(
        page: nextPage,
        filter: filterValue,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      final moreFiltered = result.items.where((n) => n.category != 'chat').toList();
      state = state.copyWith(
        notifications: [...state.notifications, ...moreFiltered],
        isLoadingMore: false,
        hasMore: result.pagination.hasMore,
        currentPage: result.pagination.currentPage,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      _updateLocalUnread(markReadIds: {id});
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      final allIds = state.notifications.map((n) => n.id).toSet();
      _updateLocalUnread(markReadIds: allIds);
    } catch (_) {}
  }

  Future<void> markSelectedAsRead() async {
    if (state.selectedIds.isEmpty) return;
    final ids = Set<String>.from(state.selectedIds);
    try {
      await _repository.markMultipleAsRead(state.selectedIds.toList());
      state = state.copyWith(selectedIds: {}, isSelectionMode: false);
      _updateLocalUnread(markReadIds: ids);
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      final newIds = Set<String>.from(state.selectedIds)..remove(id);
      state = state.copyWith(
        notifications: state.notifications.where((n) => n.id != id).toList(),
        selectedIds: newIds,
        isSelectionMode: newIds.isNotEmpty,
      );
      _recalculateUnreadCount();
    } catch (_) {
      state = state.copyWith(selectedIds: {}, isSelectionMode: false);
    }
  }

  Future<void> deleteSelected() async {
    if (state.selectedIds.isEmpty) return;
    try {
      await _repository.deleteMultiple(state.selectedIds.toList());
      state = state.copyWith(
        notifications: state.notifications
            .where((n) => !state.selectedIds.contains(n.id))
            .toList(),
        selectedIds: {},
        isSelectionMode: false,
      );
      _recalculateUnreadCount();
    } catch (_) {
      state = state.copyWith(selectedIds: {}, isSelectionMode: false);
    }
  }

  void toggleSelection(String id) {
    final ids = Set<String>.from(state.selectedIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    state = state.copyWith(selectedIds: ids, isSelectionMode: ids.isNotEmpty);
  }

  void selectAll() {
    final ids = state.notifications.map((n) => n.id).toSet();
    state = state.copyWith(selectedIds: ids, isSelectionMode: ids.isNotEmpty);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {}, isSelectionMode: false);
  }

  void setFilter(NotificationFilter filter) {
    if (state.activeFilter == filter) return;
    state = PaginatedNotificationsState(
      activeFilter: filter,
      searchQuery: state.searchQuery,
    );
    load();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void search(String query) {
    state = PaginatedNotificationsState(
      activeFilter: state.activeFilter,
      searchQuery: query,
    );
    load();
  }

  void refresh() {
    state = PaginatedNotificationsState(
      activeFilter: state.activeFilter,
      searchQuery: state.searchQuery,
    );
    load();
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      _ref.read(appStateProvider.notifier).setUnreadNotifications(count);
    } catch (_) {}
  }

  void _updateLocalUnread({Set<String>? markReadIds}) {
    final updated = state.notifications.map((n) {
      if (markReadIds != null && markReadIds.contains(n.id)) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    final count = updated.where((n) => !n.isRead).length;
    _ref.read(appStateProvider.notifier).setUnreadNotifications(count);
    state = state.copyWith(notifications: updated);
  }

  void _recalculateUnreadCount() {
    final count = state.notifications.where((n) => !n.isRead).length;
    _ref.read(appStateProvider.notifier).setUnreadNotifications(count);
  }

  String _filterToString(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.all:
        return 'all';
      case NotificationFilter.unread:
        return 'unread';
      case NotificationFilter.booking:
        return 'booking';
      case NotificationFilter.followers:
        return 'followers';
      case NotificationFilter.review:
        return 'review';
      case NotificationFilter.security:
        return 'security';
      case NotificationFilter.support:
        return 'support';
      case NotificationFilter.subscription:
        return 'subscription';
    }
  }
}

final paginatedNotificationsProvider =
    StateNotifierProvider<PaginatedNotificationsNotifier,
        PaginatedNotificationsState>((ref) {
  return PaginatedNotificationsNotifier(
    ref.read(notificationRepositoryProvider),
    ref,
  );
});
