// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required int id,
    @JsonKey(name: 'other_user') required ConversationOtherUser otherUser,
    @JsonKey(name: 'last_message') @Default(null) LastMessageData? lastMessage,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,
    @JsonKey(name: 'is_archived') @Default(false) bool isArchived,
    @JsonKey(name: 'archived_at') @Default(null) String? archivedAt,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);
}

@freezed
class ConversationOtherUser with _$ConversationOtherUser {
  const factory ConversationOtherUser({
    required int id,
    required String name,
    @Default(null) String? avatar,
    @Default('customer') String role,
    @JsonKey(name: 'is_active_sitter') @Default(false) bool isActiveSitter,
    @JsonKey(name: 'last_seen_at') @Default(null) String? lastSeenAt,
  }) = _ConversationOtherUser;

  factory ConversationOtherUser.fromJson(Map<String, dynamic> json) =>
      _$ConversationOtherUserFromJson(json);
}

@freezed
class LastMessageData with _$LastMessageData {
  const factory LastMessageData({
    required String content,
    @JsonKey(name: 'sender_id') required int senderId,
    @JsonKey(name: 'sender_name') @Default('') String senderName,
    @JsonKey(name: 'message_type') @Default('text') String messageType,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _LastMessageData;

  factory LastMessageData.fromJson(Map<String, dynamic> json) =>
      _$LastMessageDataFromJson(json);
}

enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType { text, image, voice, file, system }

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required int id,
    @JsonKey(name: 'conversation_id') required int conversationId,
    @JsonKey(name: 'sender_id') required int senderId,
    @JsonKey(name: 'sender_name') @Default('') String senderName,
    @Default('') String content,
    @Default('text') String type,
    @JsonKey(name: 'image_url') @Default(null) String? imageUrl,
    @JsonKey(name: 'read_at') @Default(null) String? readAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') @Default(null) String? updatedAt,
    @JsonKey(name: 'reply_to_id') @Default(null) int? replyToId,
    @JsonKey(name: 'message_type') @Default('text') String messageType,
    @Default(null) Map<String, dynamic>? metadata,
    @JsonKey(name: 'is_system') @Default(false) bool isSystem,
    @JsonKey(name: 'reply_to') @Default(null) MessageModel? replyTo,
    @Default([]) List<MessageReaction> reactions,
    @Default([]) List<MessageAttachment> attachments,
    @JsonKey(name: 'is_edited') @Default(false) bool isEdited,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(MessageStatus.sent)
    MessageStatus status,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false)
    bool isLocal,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(null)
    String? localId,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(0.0)
    double uploadProgress,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}

@freezed
class MessageReaction with _$MessageReaction {
  const factory MessageReaction({
    required int id,
    @JsonKey(name: 'message_id') required int messageId,
    @JsonKey(name: 'user_id') required int userId,
    required String reaction,
  }) = _MessageReaction;

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionFromJson(json);
}

@freezed
class MessageAttachment with _$MessageAttachment {
  const factory MessageAttachment({
    required int id,
    @JsonKey(name: 'message_id') required int messageId,
    @JsonKey(name: 'file_path') required String filePath,
    @JsonKey(name: 'file_url') @Default(null) String? fileUrl,
    @JsonKey(name: 'file_name') required String fileName,
    @JsonKey(name: 'file_size') required int fileSize,
    @JsonKey(name: 'mime_type') required String mimeType,
    @JsonKey(name: 'file_type') required String fileType,
  }) = _MessageAttachment;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      _$MessageAttachmentFromJson(json);
}
