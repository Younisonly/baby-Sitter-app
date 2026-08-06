import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/api_response.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/shared/models/chat_model.dart';
import 'package:babysitter/features/chat/data/chat_repository.dart';

final conversationsProvider =
    StateNotifierProvider.autoDispose<ConversationsNotifier, AsyncValue<PaginatedList<ConversationModel>>>((ref) {
  return ConversationsNotifier(ref.read(chatRepositoryProvider));
});

final conversationUnreadProvider = Provider<int>((ref) {
  final convState = ref.watch(conversationsProvider);
  return convState.whenOrNull(
        data: (data) => data.items.fold<int>(0, (sum, c) => sum + c.unreadCount),
      ) ??
      0;
});

class ConversationsNotifier extends StateNotifier<AsyncValue<PaginatedList<ConversationModel>>> {
  ConversationsNotifier(this._repository) : super(const AsyncLoading());

  final ChatRepository _repository;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _disposed = false;
  Timer? _pollTimer;
  bool _pollingPaused = false;
  String _searchQuery = '';
  bool _showArchived = false;

  bool get showArchived => _showArchived;
  String get searchQuery => _searchQuery;

  void startPolling() {
    _pollingPaused = false;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_pollingPaused) _silentRefresh();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void pausePolling() {
    _pollingPaused = true;
  }

  void resumePolling() {
    _pollingPaused = false;
  }

  Future<void> _silentRefresh() async {
    try {
      final result = await _repository.getConversations(page: 1);
      if (_disposed || _pollTimer == null) return;
      final existing = state.whenOrNull(data: (d) => d);
      if (existing != null) {
        final merged = _mergeConversations(existing.items, result.items);
        try {
          state = AsyncValue.data(existing.copyWith(items: merged));
        } catch (_) {}
      }
    } catch (_) {}
  }

  List<ConversationModel> _mergeConversations(
    List<ConversationModel> existing,
    List<ConversationModel> fresh,
  ) {
    final map = <int, ConversationModel>{};
    for (final c in existing) {
      map[c.id] = c;
    }
    for (final c in fresh) {
      map[c.id] = c;
    }
    final merged = map.values.toList();
    merged.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? a.createdAt;
      final bTime = b.lastMessage?.createdAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return merged;
  }

  void updateLocalUnread(int conversationId) {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return;
    final items = existing.items.map((c) {
      if (c.id == conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    state = AsyncValue.data(existing.copyWith(items: items));
  }

  void updateConversationLastMessage(int conversationId, MessageModel sent) {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return;
    final items = existing.items.map((c) {
      if (c.id != conversationId) return c;
      final lastMsg = LastMessageData(
        content: sent.content,
        senderId: sent.senderId,
        senderName: sent.senderName,
        messageType: sent.messageType,
        createdAt: sent.createdAt,
      );
      return c.copyWith(lastMessage: lastMsg);
    }).toList();
    items.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? a.createdAt;
      final bTime = b.lastMessage?.createdAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    state = AsyncValue.data(existing.copyWith(items: items));
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }

  Future<void> loadConversations({bool refresh = false}) async {
    if (_disposed) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
      state = const AsyncLoading();
    }
    if (!_hasMore) return;
    if (state.whenOrNull(data: (_) => true) == null) {
      state = const AsyncLoading();
    }
    final result = await AsyncValue.guard(
      () => _repository.getConversations(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        archived: _showArchived,
      ),
    );
    if (_disposed) return;
    state = result;
    final data = state.whenOrNull(data: (d) => d);
    if (data != null) _hasMore = data.pagination.hasMore;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _disposed) return;
    _isLoadingMore = true;
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) {
      _isLoadingMore = false;
      return;
    }
    try {
      final more = await AsyncValue.guard(
        () => _repository.getConversations(
          page: _currentPage + 1,
          search: _searchQuery.isEmpty ? null : _searchQuery,
          archived: _showArchived,
        ),
      );
      if (_disposed) return;
      final newData = more.whenOrNull(data: (d) => d);
      if (newData != null) {
        _currentPage++;
        _hasMore = newData.pagination.hasMore;
        state = AsyncValue.data(existing.copyWith(
          items: [...existing.items, ...newData.items],
        ));
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadConversations(refresh: true);
  }

  void setShowArchived(bool value) {
    _showArchived = value;
    loadConversations(refresh: true);
  }

  Future<void> archiveConversation(int id) async {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return;
    state = AsyncValue.data(existing.copyWith(
      items: existing.items.where((c) => c.id != id).toList(),
    ));
    await _repository.archiveConversation(id);
  }

  Future<void> unarchiveConversation(int id) async {
    if (_showArchived) {
      final existing = state.whenOrNull(data: (d) => d);
      if (existing == null) return;
      state = AsyncValue.data(existing.copyWith(
        items: existing.items.where((c) => c.id != id).toList(),
      ));
    }
    await _repository.unarchiveConversation(id);
    if (!_showArchived) await loadConversations(refresh: true);
  }

  Future<void> deleteConversation(int id) async {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return;
    state = AsyncValue.data(existing.copyWith(
      items: existing.items.where((c) => c.id != id).toList(),
    ));
    await _repository.deleteConversation(id);
  }
}

class MessagesNotifier extends StateNotifier<AsyncValue<PaginatedList<MessageModel>>> {
  MessagesNotifier(this._repository, this._userId, this._onMessageSent) : super(const AsyncLoading());

  final ChatRepository _repository;
  final int _userId;
  final void Function(int conversationId, MessageModel sent) _onMessageSent;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _disposed = false;
  Timer? _pollTimer;
  String _localIdCounter = '0';

  void startPolling(int conversationId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) => _silentRefresh(conversationId));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _silentRefresh(int conversationId) async {
    try {
      final result = await _repository.getMessages(conversationId, page: 1);
      if (_disposed || _pollTimer == null) return;
      final existing = state.whenOrNull(data: (d) => d);
      if (existing != null) {
        final merged = _mergeMessages(existing.items, result.items);
        final withStatus = merged.map((m) {
          if (m.senderId == _userId && m.readAt != null && m.status != MessageStatus.read) {
            return m.copyWith(status: MessageStatus.read);
          }
          return m;
        }).toList();
        try {
          state = AsyncValue.data(existing.copyWith(items: withStatus));
        } catch (_) {}
      }
    } catch (_) {}
  }

  List<MessageModel> _mergeMessages(
    List<MessageModel> existing,
    List<MessageModel> fresh,
  ) {
    final serverIds = <int>{};
    for (final m in fresh) {
      if (m.id > 0) serverIds.add(m.id);
    }

    final keptLocals = <MessageModel>{};
    for (final m in existing) {
      if (m.isLocal && !serverIds.contains(m.id)) {
        keptLocals.add(m);
      }
    }

    final merged = [...fresh, ...keptLocals];
    merged.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;
      return bTime.compareTo(aTime);
    });
    return merged;
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }

  Future<void> loadMessages(int conversationId, {bool refresh = false}) async {
    if (_disposed) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
      state = const AsyncLoading();
    }
    final result = await AsyncValue.guard(() => _repository.getMessages(conversationId, page: _currentPage));
    if (_disposed) return;
    final data = result.whenOrNull(data: (d) => d);
    if (data != null) {
      state = AsyncValue.data(data.copyWith(items: _applyReadStatus(data.items)));
      _hasMore = data.pagination.hasMore;
    } else {
      state = result;
    }
  }

  Future<void> refreshNow(int conversationId) async {
    if (_disposed) return;
    _currentPage = 1;
    _hasMore = true;
    final result = await AsyncValue.guard(() => _repository.getMessages(conversationId, page: 1));
    if (_disposed) return;
    final data = result.whenOrNull(data: (d) => d);
    if (data != null) {
      final existing = state.whenOrNull(data: (d) => d);
      if (existing != null) {
        final merged = _mergeMessages(existing.items, data.items);
        final withStatus = merged.map((m) {
          if (m.senderId == _userId && m.readAt != null && m.status != MessageStatus.read) {
            return m.copyWith(status: MessageStatus.read);
          }
          return m;
        }).toList();
        try { state = AsyncValue.data(existing.copyWith(items: withStatus)); } catch (_) {}
      } else {
        state = AsyncValue.data(data.copyWith(items: _applyReadStatus(data.items)));
        _hasMore = data.pagination.hasMore;
      }
    }
  }

  Future<void> loadMore(int conversationId) async {
    if (!_hasMore || _isLoadingMore || _disposed) return;
    _isLoadingMore = true;
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) {
      _isLoadingMore = false;
      return;
    }
    try {
      final more = await AsyncValue.guard(() => _repository.getMessages(conversationId, page: _currentPage + 1));
      if (_disposed) return;
      final newData = more.whenOrNull(data: (d) => d);
      if (newData != null) {
        _currentPage++;
        _hasMore = newData.pagination.hasMore;
        state = AsyncValue.data(existing.copyWith(
          items: _applyReadStatus([...existing.items, ...newData.items]),
        ));
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  List<MessageModel> _applyReadStatus(List<MessageModel> items) {
    return items.map((m) {
      if (m.senderId == _userId && m.readAt != null && m.status != MessageStatus.read) {
        return m.copyWith(status: MessageStatus.read);
      }
      return m;
    }).toList();
  }

  Future<bool> sendMessage(int conversationId, String content, {int? replyToId}) async {
    content = content.trim();
    if (content.isEmpty) return false;
    final counter = _nextLocalId();
    final localIdStr = 'local_$counter';
    final localMsg = MessageModel(
      id: -int.parse(counter),
      conversationId: conversationId,
      senderId: 0,
      senderName: '',
      content: content,
      type: 'text',
      messageType: 'text',
      createdAt: DateTime.now().toIso8601String(),
      status: MessageStatus.sending,
      isLocal: true,
      localId: localIdStr,
      replyToId: replyToId,
    );
    _addLocalMessage(localMsg);
    try {
      final sent = await _repository.sendMessage(
        conversationId,
        content: content,
        messageType: 'text',
        replyToId: replyToId,
      );
      _replaceLocalMessage(conversationId, localIdStr, sent.copyWith(status: MessageStatus.sent));
      _onMessageSent(conversationId, sent);
      return true;
    } catch (_) {
      _updateMessageStatus(conversationId, localIdStr, MessageStatus.failed);
      return false;
    }
  }

  Future<bool> sendImageMessage(
    int conversationId, {
    required String filePath,
    int? replyToId,
  }) async {
    final counter = _nextLocalId();
    final localIdStr = 'local_$counter';
    final localMsg = MessageModel(
      id: -int.parse(counter),
      conversationId: conversationId,
      senderId: 0,
      senderName: '',
      content: '[Image]',
      type: 'image',
      messageType: 'image',
      createdAt: DateTime.now().toIso8601String(),
      status: MessageStatus.sending,
      isLocal: true,
      localId: localIdStr,
      replyToId: replyToId,
      metadata: {'filePath': filePath},
    );
    _addLocalMessage(localMsg);
    try {
      final sent = await _repository.sendImage(
        conversationId,
        filePath: filePath,
        replyToId: replyToId,
        onSendProgress: (sent, total) {
          if (total > 0) {
            _updateUploadProgress(localIdStr, sent / total);
          }
        },
      );
      _replaceLocalMessage(conversationId, localIdStr, sent.copyWith(status: MessageStatus.sent, uploadProgress: 1.0));
      _onMessageSent(conversationId, sent);
      return true;
    } catch (_) {
      _updateMessageStatus(conversationId, localIdStr, MessageStatus.failed);
      return false;
    }
  }

  Future<bool> sendVoiceMessage(
    int conversationId, {
    required String filePath,
    required int durationSeconds,
    int? replyToId,
  }) async {
    final counter = _nextLocalId();
    final localIdStr = 'local_$counter';
    final localMsg = MessageModel(
      id: -int.parse(counter),
      conversationId: conversationId,
      senderId: 0,
      senderName: '',
      content: '[Voice message]',
      type: 'voice',
      messageType: 'voice',
      createdAt: DateTime.now().toIso8601String(),
      status: MessageStatus.sending,
      isLocal: true,
      localId: localIdStr,
      replyToId: replyToId,
      metadata: {'duration': durationSeconds, 'filePath': filePath},
    );
    _addLocalMessage(localMsg);
    try {
      final sent = await _repository.sendVoice(
        conversationId,
        filePath: filePath,
        durationSeconds: durationSeconds,
        replyToId: replyToId,
        onSendProgress: (sent, total) {
          if (total > 0) _updateUploadProgress(localIdStr, sent / total);
        },
      );
      _replaceLocalMessage(conversationId, localIdStr, sent.copyWith(status: MessageStatus.sent, uploadProgress: 1.0));
      _onMessageSent(conversationId, sent);
      return true;
    } catch (_) {
      _updateMessageStatus(conversationId, localIdStr, MessageStatus.failed);
      return false;
    }
  }

  Future<bool> sendFileMessage(
    int conversationId, {
    required String filePath,
    required String fileName,
    int? replyToId,
  }) async {
    final counter = _nextLocalId();
    final localIdStr = 'local_$counter';
    final localMsg = MessageModel(
      id: -int.parse(counter),
      conversationId: conversationId,
      senderId: 0,
      senderName: '',
      content: fileName,
      type: 'file',
      messageType: 'file',
      createdAt: DateTime.now().toIso8601String(),
      status: MessageStatus.sending,
      isLocal: true,
      localId: localIdStr,
      replyToId: replyToId,
      metadata: {'fileName': fileName, 'filePath': filePath},
    );
    _addLocalMessage(localMsg);
    try {
      final sent = await _repository.sendFile(
        conversationId,
        filePath: filePath,
        fileName: fileName,
        replyToId: replyToId,
        onSendProgress: (sent, total) {
          if (total > 0) _updateUploadProgress(localIdStr, sent / total);
        },
      );
      _replaceLocalMessage(conversationId, localIdStr, sent.copyWith(status: MessageStatus.sent, uploadProgress: 1.0));
      return true;
    } catch (_) {
      _updateMessageStatus(conversationId, localIdStr, MessageStatus.failed);
      return false;
    }
  }

  Future<bool> retryMessage(int conversationId, String localId) async {
    _updateMessageStatus(conversationId, localId, MessageStatus.sending);
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return false;
    final msg = existing.items.where((m) => m.localId == localId).firstOrNull;
    if (msg == null) return false;
    try {
      MessageModel sent;
      if (msg.messageType == 'image') {
        final path = (msg.metadata?['filePath'] as String?) ?? msg.content;
        sent = await _repository.sendImage(conversationId, filePath: path);
      } else if (msg.messageType == 'voice') {
        final path = (msg.metadata?['filePath'] as String?) ?? msg.content;
        final duration = (msg.metadata?['duration'] as int?) ?? 0;
        sent = await _repository.sendVoice(conversationId, filePath: path, durationSeconds: duration);
      } else if (msg.messageType == 'file') {
        final path = (msg.metadata?['filePath'] as String?) ?? msg.content;
        final fileName = (msg.metadata?['fileName'] as String?) ?? 'file';
        sent = await _repository.sendFile(conversationId, filePath: path, fileName: fileName);
      } else {
        sent = await _repository.sendMessage(conversationId, content: msg.content, replyToId: msg.replyToId);
      }
      _replaceLocalMessage(conversationId, localId, sent.copyWith(status: MessageStatus.sent));
      _onMessageSent(conversationId, sent);
      return true;
    } catch (_) {
      _updateMessageStatus(conversationId, localId, MessageStatus.failed);
      return false;
    }
  }

  void _addLocalMessage(MessageModel msg) {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) {
      state = AsyncValue.data(PaginatedList(items: [msg], pagination: PaginationInfo(currentPage: 1, lastPage: 1, totalItems: 1, perPage: 30)));
      return;
    }
    state = AsyncValue.data(existing.copyWith(items: [msg, ...existing.items]));
  }

  void _replaceLocalMessage(int conversationId, String localId, MessageModel sent) {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return;
    final items = existing.items.map((m) {
      if (m.localId == localId) return sent;
      return m;
    }).toList();
    state = AsyncValue.data(existing.copyWith(items: items));
  }

  void _updateMessageStatus(int conversationId, String localId, MessageStatus status) {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return;
    final items = existing.items.map((m) {
      if (m.localId == localId) return m.copyWith(status: status);
      return m;
    }).toList();
    try { state = AsyncValue.data(existing.copyWith(items: items)); } catch (_) {}
  }

  void toggleLocalReaction(int messageId, String reaction) {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return;
    final items = existing.items.map((m) {
      if (m.id != messageId) return m;
      final hasIt = m.reactions.any((r) => r.reaction == reaction);
      if (hasIt) {
        return m.copyWith(reactions: m.reactions.where((r) => r.reaction != reaction).toList());
      }
      return m.copyWith(reactions: [
        ...m.reactions,
        MessageReaction(id: 0, messageId: messageId, userId: 0, reaction: reaction),
      ]);
    }).toList();
    try { state = AsyncValue.data(existing.copyWith(items: items)); } catch (_) {}
  }

  void _updateUploadProgress(String localId, double progress) {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return;
    final items = existing.items.map((m) {
      if (m.localId == localId) return m.copyWith(uploadProgress: progress);
      return m;
    }).toList();
    state = AsyncValue.data(existing.copyWith(items: items));
  }

  String _nextLocalId() {
    _localIdCounter = (int.parse(_localIdCounter) + 1).toString();
    return _localIdCounter;
  }

  void deleteMessage(int conversationId, int messageId, String? localId) {
    final existing = state.whenOrNull(data: (d) => d);
    if (existing == null) return;
    final items = existing.items.map((m) {
      if ((localId != null && m.localId == localId) || m.id == messageId) {
        return m.copyWith(
          type: 'deleted',
          content: '[deleted]',
          status: MessageStatus.sent,
          attachments: [],
          reactions: [],
          replyTo: null,
        );
      }
      return m;
    }).toList();
    state = AsyncValue.data(existing.copyWith(items: items));
  }

  Future<bool> editMessage(int conversationId, int messageId, String newContent) async {
    try {
      final updated = await _repository.updateMessage(conversationId, messageId, content: newContent);
      final existing = state.whenOrNull(data: (d) => d);
      if (existing == null || _disposed) return false;
      final items = existing.items.map((m) {
        if (m.id == messageId) return updated.copyWith(status: MessageStatus.sent);
        return m;
      }).toList();
      state = AsyncValue.data(existing.copyWith(items: items));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteFromServer(int conversationId, int messageId) async {
    try {
      await _repository.deleteMessage(conversationId, messageId);
      final existing = state.whenOrNull(data: (d) => d);
      if (existing == null || _disposed) return false;
      final items = existing.items.where((m) => m.id != messageId).toList();
      state = AsyncValue.data(existing.copyWith(items: items));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markAsRead(int conversationId) async {
    await _repository.markAsRead(conversationId);
  }
}

final messagesProvider = StateNotifierProvider.autoDispose.family<
    MessagesNotifier, AsyncValue<PaginatedList<MessageModel>>, int>(
  (ref, conversationId) {
    final userId = int.tryParse(ref.watch(authProvider).user?.id ?? '') ?? 0;
    return MessagesNotifier(
      ref.read(chatRepositoryProvider),
      userId,
      (convId, sent) {
        ref.read(conversationsProvider.notifier).updateConversationLastMessage(convId, sent);
      },
    );
  },
);

final typingIndicatorProvider = StateProvider.family<bool, int>((ref, conversationId) => false);

// Selection state for multi-select

class SelectionState {
  final Set<int> selectedIds;
  final bool isSelecting;

  const SelectionState({
    this.selectedIds = const {},
    this.isSelecting = false,
  });

  SelectionState copyWith({Set<int>? selectedIds, bool? isSelecting}) {
    return SelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelecting: isSelecting ?? this.isSelecting,
    );
  }
}

final selectionProvider = StateNotifierProvider.family<SelectionNotifier, SelectionState, int>(
  (ref, conversationId) => SelectionNotifier(),
);

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(const SelectionState());

  void toggleSelection(int messageId) {
    final ids = Set<int>.from(state.selectedIds);
    if (ids.contains(messageId)) {
      ids.remove(messageId);
    } else {
      ids.add(messageId);
    }
    if (ids.isEmpty) {
      state = const SelectionState();
    } else {
      state = SelectionState(selectedIds: ids, isSelecting: true);
    }
  }

  void clearSelection() {
    state = const SelectionState();
  }

  void enterSelectionMode(int messageId) {
    state = SelectionState(selectedIds: {messageId}, isSelecting: true);
  }
}
