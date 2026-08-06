import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/constants/app_colors.dart';
import 'package:babysitter/core/constants/app_radius.dart';
import 'package:babysitter/core/constants/app_spacing.dart';
import 'package:babysitter/core/constants/app_text_styles.dart';
import 'package:babysitter/core/extensions/extensions.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/api_response.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/features/chat/presentation/providers/chat_provider.dart';
import 'package:babysitter/features/chat/data/chat_repository.dart';
import 'package:babysitter/features/chat/presentation/helpers/time_helpers.dart';
import 'package:babysitter/features/chat/presentation/widgets/voice_preview_sheet.dart';
import 'package:babysitter/shared/models/chat_model.dart';
import 'package:babysitter/shared/widgets/widgets.dart';

class ConversationDetailScreen extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const ConversationDetailScreen({super.key, required this.conversation});

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _searchController = TextEditingController();
  int? _replyToId;
  int? _editingMessageId;
  bool _showScrollToBottom = false;
  bool _isSearching = false;
  String _searchQuery = '';
  MessagesNotifier? _messagesNotifier;
  int? _highlightMessageId;
  late final SelectionNotifier _selectionNotifier;

  // Recording state
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  String? _lastSeenAt;
  Timer? _onlineTimer;

  int get _convId => widget.conversation.id;

  @override
  void initState() {
    super.initState();
    _lastSeenAt = widget.conversation.otherUser.lastSeenAt;
    _selectionNotifier = ref.read(selectionProvider(_convId).notifier);
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);
    _searchController.addListener(_onSearchChanged);
    _onlineTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _messagesNotifier = ref.read(messagesProvider(_convId).notifier);
      await _messagesNotifier!.loadMessages(_convId);
      await _messagesNotifier!.markAsRead(_convId);
      if (!mounted) return;
      await _messagesNotifier!.refreshNow(_convId);
      _messagesNotifier!.startPolling(_convId);
      ref.read(conversationsProvider.notifier).updateLocalUnread(_convId);
    });
  }

  @override
  void dispose() {
    _selectionNotifier.clearSelection();
    _messagesNotifier?.stopPolling();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _recordingTimer?.cancel();
    _onlineTimer?.cancel();
    _audioRecorder.dispose();
    _replyToId = null;
    _editingMessageId = null;
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    final nearTop = pos.pixels >= pos.maxScrollExtent - 200;
    if (nearTop) {
      ref.read(messagesProvider(_convId).notifier).loadMore(_convId);
    }
    final isAtBottom = pos.pixels <= 50;
    if (isAtBottom != !_showScrollToBottom) {
      setState(() => _showScrollToBottom = !isAtBottom);
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  void _scrollToBottom() {
    _scrollController.animateTo(0,
        duration: 200.ms, curve: Curves.easeOut);
  }

  Future<void> _scrollToMessage(int messageId) async {
    final data = ref.read(messagesProvider(_convId)).valueOrNull;
    if (data == null) return;
    int idx = data.items.indexWhere((m) => m.id == messageId);
    if (idx < 0) {
      // Message not in current page — try loading more pages
      final notifier = ref.read(messagesProvider(_convId).notifier);
      for (int attempt = 0; attempt < 5; attempt++) {
        await notifier.loadMore(_convId);
        final updated = ref.read(messagesProvider(_convId)).valueOrNull;
        if (updated == null) break;
        idx = updated.items.indexWhere((m) => m.id == messageId);
        if (idx >= 0) {
          final targetScroll = (updated.items.length - 1 - idx) * 72.0;
          _scrollController.animateTo(
            targetScroll.clamp(0, _scrollController.position.maxScrollExtent),
            duration: 350.ms,
            curve: Curves.easeOut,
          );
          break;
        }
        final hasMore = updated.pagination.hasMore;
        if (!hasMore) break;
      }
      if (idx < 0) return;
    } else {
      final targetScroll = (data.items.length - 1 - idx) * 72.0;
      _scrollController.animateTo(
        targetScroll.clamp(0, _scrollController.position.maxScrollExtent),
        duration: 350.ms,
        curve: Curves.easeOut,
      );
    }
    setState(() => _highlightMessageId = messageId);
    Future.delayed(2.seconds, () {
      if (mounted && _highlightMessageId == messageId) {
        setState(() => _highlightMessageId = null);
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
    if (!_isSearching) _focusNode.requestFocus();
  }

  void _sendMessage() {
    if (!widget.conversation.otherUser.isActiveSitter) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_editingMessageId != null) {
      final msgId = _editingMessageId!;
      _editingMessageId = null;
      _messageController.clear();
      ref.read(messagesProvider(_convId).notifier)
          .editMessage(_convId, msgId, text);
      return;
    }

    final replyId = _replyToId;
    _replyToId = null;
    _messageController.clear();
    ref.read(messagesProvider(_convId).notifier)
        .sendMessage(_convId, text, replyToId: replyId);
    Future.microtask(_scrollToBottom);
  }

  void _setReply(int? messageId) {
    if (_editingMessageId != null) return;
    setState(() => _replyToId = messageId);
    _focusNode.requestFocus();
  }

  void _startEdit(MessageModel message) {
    setState(() {
      _editingMessageId = message.id;
      _replyToId = null;
    });
    _messageController.text = message.content;
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
    });
    _messageController.clear();
    _focusNode.unfocus();
  }

  void _cancelReply() {
    setState(() => _replyToId = null);
  }

  bool _canEdit(MessageModel message) {
    if (message.type != 'text') return false;
    if (message.isLocal) return false;
    if (message.status == MessageStatus.failed) return false;
    final createdAt = DateTime.tryParse(message.createdAt);
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt).inMinutes < 30;
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      final strings = AppLocalization.get(ref.read(languageProvider).code);
      context.showInfoSnackBar(
        strings[AppLocalization.message_copied] ?? 'Message copied to clipboard.',
      );
    }
  }

  void _toggleReaction(MessageModel message) {
    final hasHeart = message.reactions.any((r) => r.reaction == '❤️');
    final repo = ref.read(chatRepositoryProvider);
    if (hasHeart) {
      repo.removeReaction(_convId, message.id);
    } else {
      repo.addReaction(_convId, message.id, '❤️');
    }
    ref.read(messagesProvider(_convId).notifier).toggleLocalReaction(message.id, '❤️');
  }

  void _copySelectedMessages(Set<int> ids) {
    final data = ref.read(messagesProvider(_convId)).valueOrNull;
    if (data == null) return;
    final texts = data.items
        .where((m) => ids.contains(m.id))
        .map((m) => m.content)
        .where((c) => c.isNotEmpty)
        .join('\n\n');
    if (texts.isEmpty) return;
    Clipboard.setData(ClipboardData(text: texts));
    ref.read(selectionProvider(_convId).notifier).clearSelection();
    if (mounted) {
      final strings = AppLocalization.get(ref.read(languageProvider).code);
      context.showInfoSnackBar(
        strings[AppLocalization.message_copied] ?? 'Message copied to clipboard.',
      );
    }
  }

  Future<void> _deleteSelectedMessages(Set<int> ids) async {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          ids.length == 1
              ? (strings[AppLocalization.delete_confirm_title] ?? 'Delete Message')
              : 'Delete ${ids.length} messages',
        ),
        content: Text(strings[AppLocalization.delete_confirm_body] ?? 'Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings[AppLocalization.cancel] ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              strings[AppLocalization.delete_message] ?? 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final notifier = ref.read(messagesProvider(_convId).notifier);
    for (final id in ids) {
      notifier.deleteMessage(_convId, id, null);
      notifier.deleteFromServer(_convId, id);
    }
    ref.read(selectionProvider(_convId).notifier).clearSelection();
  }

  // Selection actions are in the app bar — no bottom sheet needed

  Widget _actionTile(IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : context.textPrimary),
      title: Text(label,
        style: AppTextStyles.bodyMedium(
          color: isDestructive ? AppColors.error : context.textPrimary,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  // Search helpers

  List<MessageModel> _filterMessages(List<MessageModel> items) {
    if (_searchQuery.isEmpty) return items;
    return items.where((m) {
      if (m.isSystem) return false;
      return m.content.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // More menu (three dots)

  void _showMoreMenu() {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionTile(
                Icons.person_outline_rounded,
                strings[AppLocalization.view_profile] ?? 'View Profile',
                () {
                  Navigator.pop(ctx);
                  context.push('/sitter/${widget.conversation.otherUser.id}');
                },
              ),
              _actionTile(
                Icons.block_rounded,
                strings[AppLocalization.block_user] ?? 'Block User',
                () {
                  Navigator.pop(ctx);
                  _confirmBlockUser(strings);
                },
                isDestructive: true,
              ),
              _actionTile(
                Icons.delete_sweep_outlined,
                strings[AppLocalization.clear_chat] ?? 'Clear Chat',
                () {
                  Navigator.pop(ctx);
                  _confirmClearChat(strings);
                },
                isDestructive: true,
              ),
              _actionTile(
                Icons.outlined_flag_rounded,
                strings[AppLocalization.report_message] ?? 'Report',
                () {
                  Navigator.pop(ctx);
                  context.showInfoSnackBar(
                    strings[AppLocalization.report_message] ?? 'Report',
                  );
                },
                isDestructive: true,
              ),
              // Bottom safe area spacing
              SizedBox(height: MediaQuery.of(ctx).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmBlockUser(Map<String, String> strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(strings[AppLocalization.block_user] ?? 'Block User'),
        content: Text(strings[AppLocalization.confirm_block_user] ?? 'Are you sure you want to block this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings[AppLocalization.cancel] ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.showInfoSnackBar(strings[AppLocalization.user_blocked] ?? 'User blocked');
            },
            child: Text(
              strings[AppLocalization.block_user] ?? 'Block',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearChat(Map<String, String> strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(strings[AppLocalization.clear_chat] ?? 'Clear Chat'),
        content: Text(strings[AppLocalization.clear_chat] ?? 'Clear Chat'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings[AppLocalization.cancel] ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.showInfoSnackBar(strings[AppLocalization.chat_cleared] ?? 'Chat cleared');
            },
            child: Text(
              strings[AppLocalization.clear_chat] ?? 'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // Image picker (gallery)

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final notifier = (_messagesNotifier ?? ref.read(messagesProvider(_convId).notifier))!;
      await notifier.sendImageMessage(_convId, filePath: picked.path);
      Future.microtask(_scrollToBottom);
    } catch (e) {
      if (mounted) {
        final s = AppLocalization.get(ref.read(languageProvider).code);
        context.showInfoSnackBar(s[AppLocalization.failed_to_pick_image] ?? 'Failed to pick image. Please try again.');
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final notifier = (_messagesNotifier ?? ref.read(messagesProvider(_convId).notifier))!;
      await notifier.sendImageMessage(_convId, filePath: picked.path);
      Future.microtask(_scrollToBottom);
    } catch (e) {
      if (mounted) {
        final s = AppLocalization.get(ref.read(languageProvider).code);
        context.showInfoSnackBar(s[AppLocalization.failed_to_capture_image] ?? 'Failed to capture image. Please try again.');
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.first;
      final filePath = file.path;
      if (filePath == null) return;
      final fileName = file.name;
      final notifier = (_messagesNotifier ?? ref.read(messagesProvider(_convId).notifier))!;
      await notifier.sendFileMessage(
        _convId,
        filePath: filePath,
        fileName: fileName,
      );
      Future.microtask(_scrollToBottom);
    } catch (e) {
      if (mounted) {
        final s = AppLocalization.get(ref.read(languageProvider).code);
        context.showInfoSnackBar(s[AppLocalization.failed_to_pick_file] ?? 'Failed to pick file. Please try again.');
      }
    }
  }

  void _pickContact() {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(strings[AppLocalization.contact] ?? 'Share Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: strings[AppLocalization.full_name] ?? 'Full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.sm.h),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: strings[AppLocalization.phone_number] ?? 'Phone number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings[AppLocalization.cancel] ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                context.showInfoSnackBar(strings[AppLocalization.please_enter_name_phone] ?? 'Please enter name and phone number.');
                return;
              }
              Navigator.pop(ctx);
              final contactText = '\uD83D\uDCC7 $name\n\uD83D\uDCDE $phone';
              ref.read(messagesProvider(_convId).notifier)
                  .sendMessage(_convId, contactText);
              Future.microtask(_scrollToBottom);
            },
            child: Text(strings[AppLocalization.confirm] ?? 'Share'),
          ),
        ],
      ),
    );
  }

  // Voice recording

  Future<void> _startRecording() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (mounted) {
          final s = AppLocalization.get(ref.read(languageProvider).code);
          context.showInfoSnackBar(s[AppLocalization.microphone_permission_required] ?? 'Microphone permission is required to record voice messages.');
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final uuid = const Uuid().v4();
      final path = '${dir.path}/voice_$uuid.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        }
      });
    } catch (e) {
      if (mounted) {
        final s = AppLocalization.get(ref.read(languageProvider).code);
        context.showInfoSnackBar(s[AppLocalization.failed_to_start_recording] ?? 'Failed to start recording. Please try again.');
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      final path = await _audioRecorder.stop();
      if (!mounted) return;
      final dur = _recordingDuration;
      setState(() {
        _isRecording = false;
      });
      if (path == null || dur.inSeconds < 1) {
        if (path != null) File(path).delete().ignore();
        return;
      }
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: false,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        builder: (_) => VoicePreviewSheet(
          filePath: path,
          durationSeconds: dur.inSeconds,
        ),
      );
      if (!mounted || confirmed != true) {
        if (confirmed == null) File(path).delete().ignore();
        return;
      }
      final notifier = (_messagesNotifier ?? ref.read(messagesProvider(_convId).notifier))!;
      await notifier.sendVoiceMessage(
        _convId,
        filePath: path,
        durationSeconds: dur.inSeconds,
      );
      Future.microtask(_scrollToBottom);
    } catch (e) {
      if (mounted) {
        final s = AppLocalization.get(ref.read(languageProvider).code);
        context.showInfoSnackBar(s[AppLocalization.failed_to_send_voice] ?? 'Failed to send voice message. Please try again.');
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      await _audioRecorder.cancel();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  // Attachment sheet

  void _showAttachmentSheet() {
    final strings = AppLocalization.get(ref.read(languageProvider).code);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: AppSpacing.md.h, bottom: AppSpacing.lg.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 90.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _AttachmentTile(
                      icon: Icons.photo_library_rounded,
                      label: strings[AppLocalization.photo_library] ?? 'Photos',
                      color: AppColors.primary,
                      onTap: () { Navigator.pop(ctx); _pickFromGallery(); },
                    ),
                    _AttachmentTile(
                      icon: Icons.camera_alt_rounded,
                      label: strings[AppLocalization.camera] ?? 'Camera',
                      color: const Color(0xFFF97316),
                      onTap: () { Navigator.pop(ctx); _pickFromCamera(); },
                    ),
                    _AttachmentTile(
                      icon: Icons.description_rounded,
                      label: strings[AppLocalization.document] ?? 'Document',
                      color: const Color(0xFF3B82F6),
                      onTap: () { Navigator.pop(ctx); _pickDocument(); },
                    ),
                    _AttachmentTile(
                      icon: Icons.mic_rounded,
                      label: strings[AppLocalization.voice] ?? 'Voice',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(ctx);
                        _startRecording();
                      },
                    ),
                    _AttachmentTile(
                      icon: Icons.person_rounded,
                      label: strings[AppLocalization.contact] ?? 'Contact',
                      color: const Color(0xFF14B8A6),
                      onTap: () { Navigator.pop(ctx); _pickContact(); },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(_convId));
    final locale = ref.watch(languageProvider).code;
    final strings = AppLocalization.get(locale);
    final convData = ref.watch(conversationsProvider).valueOrNull;
    final updatedConv = convData?.items.where((c) => c.id == _convId).firstOrNull;
    if (updatedConv != null && updatedConv.otherUser.lastSeenAt != _lastSeenAt) {
      _lastSeenAt = updatedConv.otherUser.lastSeenAt;
    }
    final otherUser = widget.conversation.otherUser;
    final hasText = _messageController.text.trim().isNotEmpty;
    final selState = ref.watch(selectionProvider(_convId));

    return Scaffold(
      appBar: _isSearching
          ? _buildSearchAppBar(context, strings)
          : _buildHeader(context, strings, otherUser, selState),
      body: Column(
        children: [
          if (!otherUser.isActiveSitter)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h),
              color: AppColors.error.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(Icons.block_rounded, size: 16.sp, color: AppColors.error),
                  SizedBox(width: AppSpacing.sm.w),
                  Expanded(
                    child: Text(
                      strings[AppLocalization.sitter_account_inactive] ?? 'This account is no longer a babysitter',
                      style: AppTextStyles.caption(color: AppColors.error, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                CustomPaint(
                  painter: _ChatWallpaperPainter(isDark: context.isDarkMode),
                  size: Size.infinite,
                ),
                messagesAsync.when(
                  data: (data) {
                    final filtered = _searchQuery.isNotEmpty
                        ? _filterMessages(data.items)
                        : data.items;
                    if (filtered.isEmpty) {
                      return _searchQuery.isNotEmpty
                          ? _buildNoSearchResults(context, strings)
                          : _buildEmptyState(context, strings);
                    }
                    return _buildMessageList(context, strings,
                        data.copyWith(items: filtered));
                  },
                  loading: () => _buildLoadingState(context),
                  error: (_, __) => _buildErrorState(context, strings),
                ),
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 80,
                    right: 16,
                    child: _buildScrollToBottomButton(),
                  ),
              ],
            ),
          ),
          // Reply preview attached directly above input bar
          if (_replyToId != null && !selState.isSelecting && otherUser.isActiveSitter)
            _buildReplyPreview(strings),
          if (_editingMessageId != null && !selState.isSelecting && otherUser.isActiveSitter)
            _buildEditPreview(strings),
          if (!otherUser.isActiveSitter)
            _buildInactiveBar(strings)
          else if (_isRecording) _buildRecordingBar(strings)
          else _buildInputBar(strings, hasText, selState.isSelecting),
        ],
      ),
    );
  }

  String _lastSeenText(String lastSeenAt, Map<String, String> strings) {
    final dt = DateTime.tryParse(lastSeenAt);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return strings['online'] ?? 'Online';
    if (diff.inMinutes < 60) return '${strings['last_seen'] ?? 'Last seen'} ${diff.inMinutes} ${strings['min_ago'] ?? 'min ago'}';
    if (diff.inHours < 24) return '${strings['last_seen'] ?? 'Last seen'} ${diff.inHours} ${strings['hours_ago'] ?? 'h ago'}';
    if (diff.inDays < 7) return '${strings['last_seen'] ?? 'Last seen'} ${diff.inDays} ${strings['days_ago'] ?? 'd ago'}';
    return '${strings['last_seen'] ?? 'Last seen'} ${DateFormat('MMM d').format(dt)}';
  }

  PreferredSizeWidget _buildHeader(
    BuildContext context,
    Map<String, String> strings,
    ConversationOtherUser otherUser,
    SelectionState selState,
  ) {
    if (selState.isSelecting) {
      final ids = selState.selectedIds;
      final isSingle = ids.length == 1;
      return _buildSelectionAppBar(context, strings, ids, isSingle);
    }

    return PreferredSize(
      preferredSize: Size.fromHeight(56.h),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(color: context.dividerColor, width: 0.5),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, size: 22),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                SizedBox(width: AppSpacing.xxs.w),
                _UserAvatar(name: otherUser.name, avatar: otherUser.avatar, size: 36),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        otherUser.name,
                        style: AppTextStyles.titleSmall(
                          weight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_lastSeenAt != null)
                        Text(
                          _lastSeenText(_lastSeenAt!, strings),
                          style: AppTextStyles.caption(
                            color: context.textMutedColor,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search_rounded, size: 20),
                  onPressed: _toggleSearch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, size: 20),
                  onPressed: _showMoreMenu,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Minimal, elegant selection app bar — no colored backgrounds, compact icons
  PreferredSizeWidget _buildSelectionAppBar(
    BuildContext context,
    Map<String, String> strings,
    Set<int> ids,
    bool isSingle,
  ) {
    final firstId = ids.firstOrNull;
    MessageModel? firstMsg;

    // Only fetch for single selection (multi doesn't need individual msg data)
    if (isSingle && firstId != null) {
      final data = ref.read(messagesProvider(_convId)).valueOrNull;
      firstMsg = data?.items.where((m) => m.id == firstId).firstOrNull;
    }

    final isMe = firstMsg != null && firstMsg.senderId != widget.conversation.otherUser.id;
    final canEdit = isSingle && firstMsg != null && firstMsg.type == 'text' && isMe && _canEdit(firstMsg);

    return PreferredSize(
      preferredSize: Size.fromHeight(56.h),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(color: context.dividerColor, width: 0.5),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 22),
                  onPressed: () => ref.read(selectionProvider(_convId).notifier).clearSelection(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                SizedBox(width: AppSpacing.xxs.w),
                Expanded(
                  child: Text(
                    '${ids.length} selected',
                    style: AppTextStyles.titleSmall(
                      color: context.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                // Single selection actions
                if (isSingle && firstMsg != null) ...[
                  _SelectionAction(
                    icon: Icons.reply_rounded,
                    onTap: () {
                      _setReply(firstMsg!.id);
                      ref.read(selectionProvider(_convId).notifier).clearSelection();
                    },
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  _SelectionAction(
                    icon: Icons.copy_rounded,
                    onTap: () {
                      _copyMessage(firstMsg!.content);
                      ref.read(selectionProvider(_convId).notifier).clearSelection();
                    },
                  ),
                  if (canEdit) ...[
                    SizedBox(width: AppSpacing.xs.w),
                    _SelectionAction(
                      icon: Icons.edit_rounded,
                      onTap: () {
                        _startEdit(firstMsg!);
                        ref.read(selectionProvider(_convId).notifier).clearSelection();
                      },
                    ),
                  ],
                  SizedBox(width: AppSpacing.xs.w),
                  _SelectionAction(
                    icon: Icons.delete_outline_rounded,
                    isDestructive: true,
                    onTap: () {
                      _deleteSelectedMessages(ids);
                    },
                  ),
                  if (firstMsg.senderId == widget.conversation.otherUser.id) ...[
                    SizedBox(width: AppSpacing.xs.w),
                    _SelectionAction(
                      icon: Icons.outlined_flag_rounded,
                      isDestructive: true,
                      onTap: () {
                        // Report message
                        ref.read(selectionProvider(_convId).notifier).clearSelection();
                      },
                    ),
                  ],
                  if (firstMsg.status == MessageStatus.failed && firstMsg.senderId != widget.conversation.otherUser.id) ...[
                    SizedBox(width: AppSpacing.xs.w),
                    _SelectionAction(
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        final msg = firstMsg!;
                        if (msg.localId != null) {
                          ref.read(messagesProvider(_convId).notifier)
                              .retryMessage(_convId, msg.localId!);
                        }
                        ref.read(selectionProvider(_convId).notifier).clearSelection();
                      },
                    ),
                  ],
                ],
                // Multi selection actions
                if (!isSingle) ...[
                  _SelectionAction(
                    icon: Icons.copy_rounded,
                    onTap: () => _copySelectedMessages(ids),
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  _SelectionAction(
                    icon: Icons.delete_outline_rounded,
                    isDestructive: true,
                    onTap: () => _deleteSelectedMessages(ids),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar(
    BuildContext context,
    Map<String, String> strings,
  ) {
    return PreferredSize(
      preferredSize: Size.fromHeight(56.h),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(color: context.dividerColor, width: 0.5),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, size: 22),
                  onPressed: _toggleSearch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                SizedBox(width: AppSpacing.xxs.w),
                Expanded(
                  child: Container(
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: context.borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: strings[AppLocalization.search_messages] ?? 'Search messages',
                        hintStyle: AppTextStyles.bodyMedium(color: context.textMuted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md.w,
                          vertical: AppSpacing.sm.h,
                        ),
                        isDense: true,
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 20, color: context.textMuted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(Icons.close_rounded,
                                      size: 18, color: context.textMuted),
                                ),
                              )
                            : null,
                      ),
                      style: AppTextStyles.bodyMedium(color: context.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(
      BuildContext context, Map<String, String> strings) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.borderColor.withValues(alpha: 0.3),
              ),
              child: Icon(Icons.search_off_rounded, size: 36,
                  color: context.textMuted),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              '${strings[AppLocalization.no_results_for] ?? 'No results for'} "$_searchQuery"',
              style: AppTextStyles.titleMedium(color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(Map<String, String> strings) {
    final existing = ref.watch(messagesProvider(_convId)).valueOrNull;
    final replyMsg = existing?.items.where((m) => m.id == _replyToId).firstOrNull;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.md.w, AppSpacing.sm.h, AppSpacing.sm.w, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: replyMsg != null ? () => _scrollToMessage(replyMsg.id) : null,
            child: Container(width: 3, height: 36, color: AppColors.primary,
                margin: EdgeInsets.only(right: AppSpacing.sm.w)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: replyMsg != null ? () => _scrollToMessage(replyMsg.id) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replyMsg != null && replyMsg.senderName.isNotEmpty
                        ? replyMsg.senderName
                        : (strings[AppLocalization.replying_to] ?? 'Replying to'),
                    style: AppTextStyles.caption(color: AppColors.primary, weight: FontWeight.w600),
                  ),
                  Text(
                    replyMsg != null ? _replyPreviewText(replyMsg) : '...',
                    style: AppTextStyles.caption(color: context.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.borderColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(Icons.close_rounded, size: 16, color: context.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPreview(Map<String, String> strings) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.md.w, AppSpacing.sm.h, AppSpacing.sm.w, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, color: AppColors.info,
              margin: EdgeInsets.only(right: AppSpacing.sm.w)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    strings[AppLocalization.editing_message] ?? 'Editing message',
                  style: AppTextStyles.caption(color: AppColors.info, weight: FontWeight.w600),
                ),
                Text(
                  _messageController.text.isNotEmpty
                      ? _messageController.text
                      : '...',
                  style: AppTextStyles.caption(color: context.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cancelEdit,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.borderColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(Icons.close_rounded, size: 16, color: context.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  String _replyPreviewText(MessageModel msg) {
    if (msg.type == 'deleted' || msg.content == '[deleted]') return 'This message was deleted';
    if (msg.type == 'image') return '[${AppLocalization.image_label}]';
    if (msg.type == 'voice') return '[${AppLocalization.voice_message}]';
    if (msg.type == 'file') return '[${AppLocalization.file_label}]';
    return msg.content;
  }

  bool _shouldGroupWithNext(List<MessageModel> items, int index) {
    if (index >= items.length - 1) return false;
    final curr = items[index];
    final next = items[index + 1];
    if (curr.isSystem || next.isSystem) return false;
    if (curr.senderId != next.senderId) return false;
    final currTime = DateTime.tryParse(curr.createdAt);
    final nextTime = DateTime.tryParse(next.createdAt);
    if (currTime == null || nextTime == null) return false;
    return nextTime.difference(currTime).inMinutes < 5;
  }

  Widget _buildMessageList(
    BuildContext context,
    Map<String, String> strings,
    PaginatedList<MessageModel> data,
  ) {
    final locale = ref.read(languageProvider).code;
    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: RefreshIndicator(
        onRefresh: () => ref.read(messagesProvider(_convId).notifier)
            .loadMessages(_convId, refresh: true),
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: AppSpacing.sm.w,
            right: AppSpacing.sm.w,
            top: AppSpacing.sm.h,
            bottom: AppSpacing.sm.h,
          ),
          reverse: true,
          itemCount: data.items.length + (data.pagination.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= data.items.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
                child: const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final message = data.items[index];
            final isMe = !message.isSystem &&
                message.senderId != widget.conversation.otherUser.id;
            final showDateDivider = _shouldShowDateDivider(data.items, index);
            final isGrouped = _shouldGroupWithNext(data.items, index);
            final isHighlighted = _highlightMessageId == message.id;

            return Column(
              children: [
                if (showDateDivider) _buildDateDivider(context, strings, message.createdAt, locale),
                _MessageBubble(
                  message: message,
                  isMe: isMe,
                  conversationId: _convId,
                  isGrouped: isGrouped,
                  isHighlighted: isHighlighted,
                  onRetry: () {
                    if (message.localId != null) {
                      ref.read(messagesProvider(_convId).notifier)
                          .retryMessage(_convId, message.localId!);
                    }
                  },
                  onLongPress: () {
                    ref.read(selectionProvider(_convId).notifier).enterSelectionMode(message.id);
                    HapticFeedback.mediumImpact();
                  },
                  onReply: () => _setReply(message.id),
                  onReplyTap: message.replyToId != null ? () => _scrollToMessage(message.replyToId!) : null,
                  onDoubleTap: () {
                    if (!message.isSystem && !message.isLocal) {
                      _toggleReaction(message);
                    }
                  },
                ).animate().fadeIn(
                  duration: 250.ms,
                  delay: (index.clamp(0, 10) * 20).ms,
                ).slideY(begin: 0.15, end: 0, duration: 250.ms, curve: Curves.easeOut),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _shouldShowDateDivider(List<MessageModel> items, int index) {
    if (index >= items.length - 1) return true;
    final curr = DateTime.tryParse(items[index].createdAt);
    final next = DateTime.tryParse(items[index + 1].createdAt);
    if (curr == null || next == null) return false;
    return curr.day != next.day || curr.month != next.month || curr.year != next.year;
  }

  Widget _buildDateDivider(BuildContext context, Map<String, String> strings, String dateStr, String locale) {
    final date = DateTime.tryParse(dateStr);
    final label = date != null ? formatConversationTime(dateStr, locale) : dateStr;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption(color: context.textMuted, weight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return GestureDetector(
      onTap: _scrollToBottom,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.white, size: 22),
      ),
    );
  }

  Widget _buildRecordingBar(Map<String, String> strings) {
    final minutes = _recordingDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _recordingDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final timerText = '$minutes:$seconds';

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm.w, AppSpacing.sm.h, AppSpacing.sm.w,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? AppSpacing.sm.h : AppSpacing.lg.h,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _cancelRecording,
            icon: Icon(Icons.close_rounded, color: context.textMuted, size: 22.sp),
            tooltip: 'Cancel',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 4),
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Icon(Icons.mic_rounded, size: 20, color: AppColors.primary),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: AnimatedContainer(
              duration: 200.ms,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Text(
            timerText,
            style: AppTextStyles.labelMedium(
              color: context.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: IconButton(
              onPressed: _stopRecording,
              icon: Icon(Icons.stop_rounded, size: 20, color: AppColors.white),
              tooltip: 'Stop recording',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveBar(Map<String, String> strings) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md.w, AppSpacing.sm.h, AppSpacing.md.w,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? AppSpacing.sm.h : AppSpacing.lg.h,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.block_rounded, size: 16.sp, color: AppColors.error),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              strings[AppLocalization.chat_read_only] ?? 'This conversation is now read-only',
              style: AppTextStyles.bodySmall(color: context.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(Map<String, String> strings, bool hasText, bool isSelecting) {
    if (isSelecting) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm.w, AppSpacing.xs.h, AppSpacing.xs.w,
        MediaQuery.of(context).viewInsets.bottom > 0
            ? AppSpacing.sm.h : AppSpacing.lg.h,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.dividerColor, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _showAttachmentSheet,
            icon: Icon(Icons.add_circle_outline_rounded, color: context.textPrimary, size: 24.sp),
            tooltip: 'Attach',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          SizedBox(width: AppSpacing.xxs.w),
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 120.h),
              decoration: BoxDecoration(
                color: context.borderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      maxLines: null,
                      maxLength: 5000,
                      maxLengthEnforcement: MaxLengthEnforcement.none,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _editingMessageId != null
                            ? 'Edit message...'
                            : (strings[AppLocalization.type_message] ?? 'Type a message...'),
                        hintStyle: AppTextStyles.bodyMedium(color: context.textMuted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md.w,
                          vertical: AppSpacing.sm.h,
                        ),
                        isDense: true,
                      ),
                      style: AppTextStyles.bodyMedium(color: context.textPrimary),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  if (_editingMessageId == null && !hasText)
                    IconButton(
                      onPressed: _startRecording,
                      icon: Icon(Icons.mic_rounded,
                          color: context.textPrimary, size: 22.sp),
                      tooltip: strings[AppLocalization.voice_message] ?? 'Voice',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                ],
              ),
            ),
          ),
          if (hasText || _editingMessageId != null) ...[
            SizedBox(width: AppSpacing.xxs.w),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: Icon(_editingMessageId != null
                    ? Icons.check_rounded
                    : Icons.send_rounded,
                    size: 18, color: AppColors.white),
                tooltip: strings[AppLocalization.send_message] ?? 'Send',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Map<String, String> strings) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.chat_bubble_outline_rounded, size: 36,
                  color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              strings[AppLocalization.chat_empty_title] ?? 'No Messages Yet',
              style: AppTextStyles.titleMedium(color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xs.h),
            Text(
              strings[AppLocalization.chat_empty_subtitle] ?? 'Send a message to start the conversation.',
              style: AppTextStyles.bodyMedium(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scaleY(begin: 0.95, end: 1);
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h),
      reverse: true,
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
        child: Row(
          mainAxisAlignment: i.isEven ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (i.isEven) const Spacer(flex: 2),
            AppShimmer(
              width: i.isEven ? 180.w : 160.w,
              height: 48.h,
              borderRadius: AppRadius.md,
            ),
            if (i.isOdd) const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Map<String, String> strings) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.error),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              strings[AppLocalization.chat_loading_error] ?? 'Failed to load messages.',
              style: AppTextStyles.titleMedium(color: context.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xs.h),
            Text(
              strings[AppLocalization.chat_loading_error_desc] ?? 'Please check your connection and try again.',
              style: AppTextStyles.bodyMedium(color: context.textMuted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppButton(
              text: strings[AppLocalization.retry] ?? 'Retry',
              variant: AppButtonVariant.outlined,
              prefixIcon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: () {
                ref.read(messagesProvider(_convId).notifier)
                    .loadMessages(_convId, refresh: true);
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scaleY(begin: 0.95, end: 1);
  }
}

// Helper classes

class _SelectionAction extends StatelessWidget {
  final IconData icon;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SelectionAction({
    required this.icon,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : context.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: context.borderColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
      child: GestureDetector(
        onTap: onTap,
          child: SizedBox(
            height: 78,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 26, color: color),
                ),
                SizedBox(height: AppSpacing.xs.h),
                SizedBox(
                  width: 60.w,
                  child: Text(
                    label,
                    style: AppTextStyles.caption(
                      color: context.textPrimary,
                      weight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final String? avatar;
  final double size;

  const _UserAvatar({required this.name, this.avatar, this.size = 36});

  @override
  Widget build(BuildContext context) {
    if (avatar != null && avatar!.isNotEmpty) {
      return GestureDetector(
        onTap: AppImagePreview.canPreview(avatar)
            ? () => AppImagePreview.show(context, avatar, name: name)
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: AppNetworkImage(
            imageUrl: avatar, width: size, height: size,
            borderRadius: AppRadius.full,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AppTextStyles.labelMedium(color: AppColors.white, weight: FontWeight.w700),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final int conversationId;
  final bool isGrouped;
  final bool isHighlighted;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final VoidCallback? onReplyTap;
  final VoidCallback? onDoubleTap;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.conversationId,
    this.isGrouped = false,
    this.isHighlighted = false,
    this.onRetry,
    this.onLongPress,
    this.onReply,
    this.onReplyTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.isSystem || message.type == 'system') {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h, horizontal: AppSpacing.lg.w),
        child: Text(
          message.content,
          style: AppTextStyles.caption(color: context.textMuted).copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    final locale = ref.watch(languageProvider).code;
    final time = formatRelativeTime(message.createdAt, locale);
    final selState = ref.watch(selectionProvider(conversationId));
    final isSelected = selState.selectedIds.contains(message.id);

    return Padding(
      padding: EdgeInsets.only(top: isGrouped ? 2.h : AppSpacing.sm.h),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _SwipeToReply(
            onReply: selState.isSelecting ? null : onReply,
            child: GestureDetector(
              onLongPress: onLongPress,
              onTap: () {
                if (selState.isSelecting) {
                  ref.read(selectionProvider(conversationId).notifier)
                      .toggleSelection(message.id);
                  return;
                }
                if (message.status == MessageStatus.failed) {
                  onRetry?.call();
                }
              },
              onDoubleTap: selState.isSelecting ? null : onDoubleTap,
              child: AnimatedContainer(
                duration: 200.ms,
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : (isHighlighted
                          ? AppColors.info.withValues(alpha: 0.12)
                          : Colors.transparent),
                ),
                padding: EdgeInsets.all(isSelected || isHighlighted ? 4 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selState.isSelecting)
                      Padding(
                        padding: EdgeInsets.only(
                          left: isMe ? 0 : AppSpacing.xs.w,
                          right: isMe ? AppSpacing.xs.w : 0,
                        ),
                        child: Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : context.textMuted,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check_rounded, size: 14, color: AppColors.white)
                              : null,
                        ),
                      ),
                    Flexible(
                      child: _MessageContent(
                        message: message,
                        isMe: isMe,
                        time: time,
                        status: message.status,
                        onRetry: onRetry,
                        onLongPress: null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.reactions.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 2.h, left: isMe ? AppSpacing.lg.w : 0, right: isMe ? 0 : AppSpacing.lg.w),
              child: _buildReactions(context),
            ),
        ],
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: message.reactions.map((r) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.w),
            child: Text(r.reaction, style: AppTextStyles.caption()),
          )).toList(),
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String time;
  final MessageStatus status;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;

  const _MessageContent({
    required this.message,
    required this.isMe,
    required this.time,
    required this.status,
    this.onRetry,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleted = message.type == 'deleted' || message.content == '[deleted]';
    if (isDeleted) {
      // WhatsApp-style deleted message: keep bubble, show muted "This message was deleted"
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: context.screenWidth * 0.7),
          padding: message.replyTo != null
              ? EdgeInsets.only(top: AppSpacing.sm.h, bottom: AppSpacing.sm.h)
              : EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h + 4),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? AppRadius.md : AppRadius.xs),
              topRight: Radius.circular(isMe ? AppRadius.xs : AppRadius.md),
              bottomLeft: Radius.circular(AppRadius.md),
              bottomRight: Radius.circular(AppRadius.md),
            ),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.replyTo != null)
                Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm.w, right: AppSpacing.sm.w, bottom: AppSpacing.xs.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 2, height: 14, color: AppColors.primary.withValues(alpha: 0.5)),
                      SizedBox(width: AppSpacing.xs.w),
                      Expanded(
                        child: Text(
                          message.replyTo!.senderName.isNotEmpty
                              ? message.replyTo!.senderName
                              : 'Previous message',
                          style: AppTextStyles.caption(color: AppColors.primary.withValues(alpha: 0.6), weight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: AppSpacing.sm.w),
                  Icon(Icons.info_outline_rounded, size: 14, color: context.textMuted.withValues(alpha: 0.6)),
                  SizedBox(width: AppSpacing.xs.w),
                  Text(
                    'This message was deleted',
                    style: AppTextStyles.bodyMedium(
                      color: context.textMuted.withValues(alpha: 0.7),
                    ).copyWith(fontStyle: FontStyle.italic, decoration: TextDecoration.none),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                ],
              ),
              if (isMe) ...[
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: AppTextStyles.overline(
                          color: context.textMuted.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: context.screenWidth * 0.78),
        padding: message.type == 'image'
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h),
        decoration: message.type == 'image'
            ? null
            : BoxDecoration(
                color: isMe ? AppColors.primary : context.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? AppRadius.md : AppRadius.xs),
                  topRight: Radius.circular(isMe ? AppRadius.xs : AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.md),
                  bottomRight: Radius.circular(AppRadius.md),
                ),
                border: isMe ? null : Border.all(color: context.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview INSIDE bubble (right side for me, left for other)
            if (message.replyTo != null)
              _buildInlineReplyPreview(context),
            _buildContent(context),
            if (message.type != 'image') ...[
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMe) ...[
                    _MessageStatusIcon(status: status, isMe: false),
                    SizedBox(width: 3.w),
                  ],
                  if (message.isEdited)
                    Padding(
                      padding: EdgeInsets.only(right: 3.w),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'edited',
                            style: AppTextStyles.overline(
                              color: isMe
                                  ? AppColors.white.withValues(alpha: 0.5)
                                  : context.textMuted,
                            ).copyWith(letterSpacing: 0.3),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: Container(
                              width: 2, height: 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isMe
                                    ? AppColors.white.withValues(alpha: 0.3)
                                    : context.textMuted.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    time,
                    style: AppTextStyles.overline(
                      color: isMe
                          ? AppColors.white.withValues(alpha: 0.7)
                          : context.textMuted,
                    ).copyWith(letterSpacing: 0.2),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineReplyPreview(BuildContext context) {
    final replyTo = message.replyTo!;
    final isDeleted = replyTo.type == 'deleted' || replyTo.content == '[deleted]';
    return GestureDetector(
      onTap: null, // handled by parent onReplyTap
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.xs.h),
        constraints: BoxConstraints(maxWidth: context.screenWidth * 0.65),
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.white.withValues(alpha: 0.15)
              : context.borderColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDeleted
                  ? 'Deleted message'
                  : (replyTo.senderName.isNotEmpty ? replyTo.senderName : 'Previous message'),
              style: AppTextStyles.labelSmall(
                color: isMe
                    ? AppColors.white.withValues(alpha: 0.8)
                    : AppColors.primary,
                weight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isDeleted) ...[
              SizedBox(height: 2.h),
              Text(
                _replyContentPreview(replyTo),
                style: AppTextStyles.caption(
                  color: isMe ? AppColors.white.withValues(alpha: 0.7) : context.textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              SizedBox(height: 2.h),
              Text(
                'This message was deleted',
                style: AppTextStyles.caption(
                  color: isMe
                      ? AppColors.white.withValues(alpha: 0.5)
                      : context.textMuted.withValues(alpha: 0.6),
                ).copyWith(fontStyle: FontStyle.italic),
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _replyContentPreview(MessageModel msg) {
    if (msg.type == 'image') return '[Image]';
    if (msg.type == 'voice') return '[Voice message]';
    if (msg.type == 'file') return '[File]';
    return msg.content;
  }

  Widget _buildContent(BuildContext context) {
    switch (message.type) {
      case 'image':
        return _ImageContent(message: message, isMe: isMe, time: time, status: status);
      case 'voice':
        return _VoiceContent(message: message, isMe: isMe);
      case 'file':
        return _FileContent(message: message, isMe: isMe);
      default:
        return Text(
          message.content,
          style: AppTextStyles.bodyMedium(
            color: isMe ? AppColors.white : context.textPrimary,
          ).copyWith(height: 1.4),
        );
    }
  }
}

class _MessageStatusIcon extends StatelessWidget {
  final MessageStatus status;
  final bool isMe;

  const _MessageStatusIcon({required this.status, required this.isMe});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time_rounded, size: 13, color: AppColors.white.withValues(alpha: 0.45));
      case MessageStatus.sent:
        return Icon(Icons.check_rounded, size: 13, color: AppColors.white.withValues(alpha: 0.55));
      case MessageStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 13, color: AppColors.white.withValues(alpha: 0.7));
      case MessageStatus.read:
        return Icon(Icons.done_all_rounded, size: 13, color: AppColors.white);
      case MessageStatus.failed:
        return GestureDetector(
          onTap: () {},
          child: Icon(Icons.error_outline_rounded, size: 13, color: AppColors.error),
        );
    }
  }
}

class _ImageContent extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final String time;
  final MessageStatus status;

  const _ImageContent({
    required this.message,
    required this.isMe,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? rawUrl = message.imageUrl;
    if (rawUrl != null && !rawUrl.startsWith('http')) {
      rawUrl = AppConfig.storageHost + rawUrl;
    }
    final imageUrl = rawUrl ??
        message.attachments.firstOrNull?.fileUrl ??
        (() {
      final fp = message.attachments.firstOrNull?.filePath;
      return fp != null ? AppConfig.storageUrl(fp) : null;
    })();
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 200, height: 200,
        decoration: BoxDecoration(
          color: context.borderColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 40, color: context.textMuted),
            SizedBox(height: AppSpacing.xs.h),
            Text('No image', style: AppTextStyles.caption(color: context.textMuted)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullscreen(context, imageUrl),
      child: Container(
        width: 220, height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
            if (message.status == MessageStatus.failed)
              Container(
                color: AppColors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Icon(Icons.error_outline_rounded, size: 36, color: AppColors.white),
                ),
              ),
            Positioned(
              bottom: 4, right: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMe) ...[
                      _MessageStatusIcon(status: status, isMe: false),
                      SizedBox(width: 3.w),
                    ],
                    if (message.isEdited)
                      Padding(
                        padding: EdgeInsets.only(right: 3.w),
                        child: Text('edited',
                          style: AppTextStyles.overline(color: AppColors.white.withValues(alpha: 0.7))),
                      ),
                    Text(time,
                      style: AppTextStyles.overline(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.black,
          appBar: AppBar(
            backgroundColor: AppColors.black,
            iconTheme: const IconThemeData(color: AppColors.white),
            elevation: 0,
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: AppNetworkImage(
                imageUrl: url,
                width: context.screenWidth,
                height: context.screenHeight * 0.75,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceContent extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isMe;

  const _VoiceContent({required this.message, required this.isMe});

  @override
  ConsumerState<_VoiceContent> createState() => _VoiceContentState();
}

class _VoiceContentState extends ConsumerState<_VoiceContent> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _hasError = false;
  bool _isCompleted = false;
  Duration _position = Duration.zero;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isCompleted = true;
            _position = Duration.zero;
          });
        }
      }
      if (mounted) setState(() => _isLoading = state == PlayerState.playing && _position == Duration.zero);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSource());
  }

  @override
  void didUpdateWidget(_VoiceContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.message.id;
    final newId = widget.message.id;
    final oldAtt = oldWidget.message.attachments;
    final newAtt = widget.message.attachments;
    if (oldId != newId || oldAtt != newAtt) {
      _position = Duration.zero;
      _isPlaying = false;
      _hasError = false;
      _isCompleted = false;
      _player.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) => _initSource());
    }
  }

  String get _audioUrl {
    final fileUrl = widget.message.attachments.firstOrNull?.fileUrl;
    if (fileUrl != null && fileUrl.isNotEmpty) {
      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) return fileUrl;
      if (fileUrl.startsWith('storage/')) return '${AppConfig.storageHost}/$fileUrl';
      return AppConfig.storageUrl(fileUrl);
    }

    final fp = widget.message.attachments.firstOrNull?.filePath;
    if (fp != null && fp.isNotEmpty) {
      if (fp.startsWith('http://') || fp.startsWith('https://')) return fp;
      if (fp.startsWith('storage/')) return '${AppConfig.storageHost}/$fp';
      return AppConfig.storageUrl(fp);
    }

    final localPath = widget.message.metadata?['filePath'] as String?;
    if (localPath != null && localPath.isNotEmpty) {
      if (localPath.startsWith('http://') || localPath.startsWith('https://')) return localPath;
      if (localPath.startsWith('/')) return localPath;
    }
    return '';
  }

  Future<void> _initSource() async {
    final url = _audioUrl;
    if (url.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }
    try {
      setState(() => _isLoading = true);
      if (url.startsWith('http://') || url.startsWith('https://')) {
        await _player.setSourceUrl(url);
      } else {
        await _player.setSourceDeviceFile(url);
      }
      if (mounted) {
        setState(() {
          _hasError = false;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_hasError || _isLoading) return;
    if (_isPlaying) {
      _player.pause();
      setState(() => _isPlaying = false);
    } else {
      final url = _audioUrl;
      if (url.isEmpty) { setState(() => _hasError = true); return; }
      try {
        if (_isCompleted && _position == Duration.zero) {
          _isCompleted = false;
        }
        if (_position >= const Duration(seconds: 1)) {
          _player.resume();
        } else {
          if (url.startsWith('http://') || url.startsWith('https://')) {
            _player.play(UrlSource(url));
          } else {
            _player.play(DeviceFileSource(url));
          }
        }
        setState(() => _isPlaying = true);
      } catch (_) {
        setState(() => _hasError = true);
      }
    }
  }

  void _seekTo(double value) {
    final total = _totalDuration;
    if (total <= 0) return;
    final pos = Duration(seconds: (value * total).round());
    _player.seek(pos);
    setState(() => _position = pos);
  }

  int get _totalDuration {
    final md = widget.message.metadata?['duration'] as int?;
    if (md != null && md > 0) return md;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = _totalDuration;
    final positionSec = _position.inSeconds;
    final remaining = (totalSeconds - positionSec).clamp(0, totalSeconds);
    final remStr = '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';
    final progress = totalSeconds > 0 ? (positionSec / totalSeconds) : 0.0;

    final bgColor = widget.isMe
        ? AppColors.white.withValues(alpha: 0.2)
        : AppColors.primary.withValues(alpha: 0.1);
    final fgColor = widget.isMe ? AppColors.white : AppColors.primary;

    if (_hasError) {
      return GestureDetector(
        onTap: () {
          setState(() => _hasError = false);
          _initSource();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
            SizedBox(width: 6.w),
            Text('Voice unavailable',
              style: AppTextStyles.caption(color: AppColors.error)),
            SizedBox(width: 4.w),
            Icon(Icons.refresh_rounded, size: 16, color: AppColors.error),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
            child: _isLoading
                ? SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20, color: fgColor,
                  ),
          ),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTapDown: (_) {},
              child: SizedBox(
                width: 100.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                      activeTrackColor: fgColor,
                      inactiveTrackColor: widget.isMe
                          ? AppColors.white.withValues(alpha: 0.3)
                          : context.borderColor,
                      thumbColor: fgColor,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: _seekTo,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(remStr,
                  style: AppTextStyles.caption(
                    color: widget.isMe ? AppColors.white.withValues(alpha: 0.7) : context.textMuted,
                  ).copyWith(letterSpacing: 0.3),
                ),
                if (widget.message.isEdited) ...[
                  SizedBox(width: 4.w),
                  Container(
                    width: 2, height: 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isMe
                          ? AppColors.white.withValues(alpha: 0.3)
                          : context.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text('edited',
                    style: AppTextStyles.caption(
                      color: widget.isMe ? AppColors.white.withValues(alpha: 0.5) : context.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _FileContent extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _FileContent({required this.message, required this.isMe});

  String get _fileUrl {
    final fileUrl = message.attachments.firstOrNull?.fileUrl;
    if (fileUrl != null && fileUrl.isNotEmpty) {
      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) return fileUrl;
      if (fileUrl.startsWith('storage/')) return '${AppConfig.storageHost}/$fileUrl';
      return AppConfig.storageUrl(fileUrl);
    }
    final fp = message.attachments.firstOrNull?.filePath;
    if (fp == null) return '';
    if (fp.startsWith('http://') || fp.startsWith('https://')) return fp;
    if (fp.startsWith('storage/')) return '${AppConfig.storageHost}/$fp';
    return AppConfig.storageUrl(fp);
  }

  Future<void> _openFile(BuildContext context) async {
    final url = _fileUrl;
    if (url.isEmpty) {
      if (context.mounted) {
        final s = AppLocalization.get(Localizations.localeOf(context).languageCode);
        context.showInfoSnackBar(s[AppLocalization.file_not_available] ?? 'File not available.');
      }
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        final s = AppLocalization.get(Localizations.localeOf(context).languageCode);
        context.showInfoSnackBar(s[AppLocalization.could_not_open_file] ?? 'Could not open file.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = message.attachments.firstOrNull;
    final fileName = attachment?.fileName ?? message.content;
    final fileSize = attachment?.fileSize ?? 0;
    return GestureDetector(
      onTap: () => _openFile(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isMe ? AppColors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.insert_drive_file_outlined, size: 22,
                color: isMe ? AppColors.white : AppColors.primary),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                  style: AppTextStyles.labelSmall(
                    color: isMe ? AppColors.white : context.textPrimary,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                if (fileSize > 0) ...[
                  SizedBox(height: 2.h),
                  Text(_formatFileSize(fileSize),
                    style: AppTextStyles.caption(
                      color: isMe ? AppColors.white.withValues(alpha: 0.7) : context.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Icon(Icons.open_in_new_rounded, size: 18,
              color: isMe ? AppColors.white.withValues(alpha: 0.7) : AppColors.primary),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback? onReply;

  const _SwipeToReply({required this.child, this.onReply});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _dragMet = false;
  static const double _maxDrag = 60;
  static const double _threshold = 0.5; // fraction of maxDrag to trigger reply

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _cancel() {
    _dragMet = false;
    _ctrl.animateTo(0,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onReply == null) return widget.child;

    return GestureDetector(
      onHorizontalDragStart: (d) {
        // Only activate within the first 20px from the left edge
        if (d.localPosition.dx > 20) return;
        _dragMet = false;
        _ctrl.value = 0;
      },
      onHorizontalDragUpdate: (d) {
        final delta = d.delta.dx;
        if (delta < 0) return; // Only rightward swipe
        final fraction = _ctrl.value + (delta / _maxDrag);
        _ctrl.value = fraction.clamp(0.0, 1.0);
        if (!_dragMet && _ctrl.value > _threshold) _dragMet = true;
      },
      onHorizontalDragEnd: (_) {
        if (_dragMet) widget.onReply?.call();
        _cancel();
      },
      onHorizontalDragCancel: _cancel,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final fraction = _ctrl.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (fraction > 0.08)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: (fraction / 0.5).clamp(0.0, 1.0),
                    child: Container(
                      width: 48,
                      alignment: AlignmentDirectional.centerStart,
                      padding: EdgeInsetsDirectional.only(start: AppSpacing.sm.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: fraction * 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.reply_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(_maxDrag * fraction, 0),
                child: child!,
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _ChatWallpaperPainter extends CustomPainter {
  final bool isDark;
  _ChatWallpaperPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.025);
    final spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ChatWallpaperPainter old) => old.isDark != isDark;
}
