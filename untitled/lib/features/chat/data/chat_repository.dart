import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/api_response.dart';
import 'package:babysitter/core/network/error_handler.dart';

import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/shared/models/chat_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(DioClient.dio);
});

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  static const _cacheKeyConversations = 'conversations';
  static const _cacheKeyMessages = 'messages_';

  Future<PaginatedList<ConversationModel>> getConversations({
    int page = 1,
    int perPage = 20,
    String? search,
    bool archived = false,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'archived': archived ? '1' : '0',
      };
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }
      final response = await _dio.get('/conversations', queryParameters: params);
      final map = response.data as Map<String, dynamic>? ?? {};
      final data = (map['data'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ConversationModel.fromJson)
              .toList() ??
          [];
      final pagination = PaginationInfo.fromLaravelMeta(
        map['meta'] as Map<String, dynamic>? ?? {},
      );

      if (page == 1) {
        await CacheService.set(_cacheKeyConversations, {
          'items': data.map((e) => e.toJson()).toList(),
          'pagination': {
            'current_page': pagination.currentPage,
            'last_page': pagination.lastPage,
            'per_page': pagination.perPage,
            'totalItems': pagination.totalItems,
          },
        }, expiry: CacheService.shortExpiry);
      }

      return PaginatedList(items: data, pagination: pagination);
    } catch (error) {
      if (page == 1) {
        final cached = CacheService.get(_cacheKeyConversations);
        if (cached is Map<String, dynamic>) {
          final items = (cached['items'] as List)
              .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
              .toList();
          final pag = cached['pagination'] as Map<String, dynamic>;
          return PaginatedList(
            items: items,
            pagination: PaginationInfo(
              currentPage: pag['current_page'] as int? ?? 1,
              lastPage: pag['last_page'] as int? ?? 1,
              perPage: pag['per_page'] as int? ?? 20,
              totalItems: pag['totalItems'] as int? ?? items.length,
            ),
          );
        }
      }
      throw ErrorHandler.handle(error);
    }
  }

  Future<ConversationModel> getConversation(int id) async {
    try {
      final response = await _dio.get('/conversations/$id');
      final data = (response.data as Map<String, dynamic>? ?? {})['data'];
      return ConversationModel.fromJson(data as Map<String, dynamic>);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<ConversationModel> startConversation(int otherUserId) async {
    try {
      final response = await _dio.post('/conversations', data: {
        'other_user_id': otherUserId,
      });
      final data = (response.data as Map<String, dynamic>? ?? {})['data'];
      await CacheService.remove(_cacheKeyConversations);
      return ConversationModel.fromJson(data as Map<String, dynamic>);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<PaginatedList<MessageModel>> getMessages(
    int conversationId, {
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final response = await _dio.get(
        '/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final map = response.data as Map<String, dynamic>? ?? {};
      final data = (map['data'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MessageModel.fromJson)
              .toList() ??
          [];
      final pagination = PaginationInfo.fromLaravelMeta(
        map['meta'] as Map<String, dynamic>? ?? {},
      );

      if (page == 1) {
        await CacheService.set('$_cacheKeyMessages$conversationId', {
          'items': data.map((e) => e.toJson()).toList(),
          'pagination': {
            'current_page': pagination.currentPage,
            'last_page': pagination.lastPage,
            'per_page': pagination.perPage,
            'totalItems': pagination.totalItems,
          },
        }, expiry: CacheService.shortExpiry);
      }

      return PaginatedList(items: data, pagination: pagination);
    } catch (error) {
      if (page == 1) {
        final cached = CacheService.get('$_cacheKeyMessages$conversationId');
        if (cached is Map<String, dynamic>) {
          final items = (cached['items'] as List)
              .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
              .toList();
          final pag = cached['pagination'] as Map<String, dynamic>;
          return PaginatedList(
            items: items,
            pagination: PaginationInfo(
              currentPage: pag['current_page'] as int? ?? 1,
              lastPage: pag['last_page'] as int? ?? 1,
              perPage: pag['per_page'] as int? ?? 20,
              totalItems: pag['totalItems'] as int? ?? items.length,
            ),
          );
        }
      }
      throw ErrorHandler.handle(error);
    }
  }

  Future<MessageModel> sendMessage(
    int conversationId, {
    required String content,
    String? messageType,
    int? replyToId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _dio.post(
        '/conversations/$conversationId/messages',
        data: {
          'content': content,
          if (messageType != null) 'message_type': messageType,
          if (replyToId != null) 'reply_to_id': replyToId,
          if (metadata != null) 'metadata': metadata,
        },
      );
      final data = (response.data as Map<String, dynamic>? ?? {})['data'];
      return MessageModel.fromJson(data as Map<String, dynamic>);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<MessageModel> sendImage(
    int conversationId, {
    required String filePath,
    int? replyToId,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
        if (replyToId != null) 'reply_to_id': replyToId,
      });
      final response = await _dio.post(
        '/conversations/$conversationId/messages/image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
      final data = (response.data as Map<String, dynamic>? ?? {})['data'];
      return MessageModel.fromJson(data as Map<String, dynamic>);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<MessageModel> sendVoice(
    int conversationId, {
    required String filePath,
    int durationSeconds = 0,
    int? replyToId,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'voice': await MultipartFile.fromFile(filePath),
        'duration': durationSeconds,
        'metadata': '{"duration": $durationSeconds}',
        if (replyToId != null) 'reply_to_id': replyToId,
      });
      final response = await _dio.post(
        '/conversations/$conversationId/messages/voice',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
      final data = (response.data as Map<String, dynamic>? ?? {})['data'];
      return MessageModel.fromJson(data as Map<String, dynamic>);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<MessageModel> sendFile(
    int conversationId, {
    required String filePath,
    required String fileName,
    int? replyToId,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (replyToId != null) 'reply_to_id': replyToId,
      });
      final response = await _dio.post(
        '/conversations/$conversationId/messages/file',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
      final data = (response.data as Map<String, dynamic>? ?? {})['data'];
      return MessageModel.fromJson(data as Map<String, dynamic>);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> addReaction(int conversationId, int messageId, String reaction) async {
    try {
      await _dio.post(
        '/conversations/$conversationId/messages/$messageId/reactions',
        data: {'reaction': reaction},
      );
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> removeReaction(int conversationId, int messageId) async {
    try {
      await _dio.delete(
        '/conversations/$conversationId/messages/$messageId/reactions',
      );
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<PaginatedList<MessageModel>> searchMessages(
    int conversationId, {
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/conversations/$conversationId/search',
        queryParameters: {'q': query, 'page': page, 'per_page': perPage},
      );
      final map = response.data as Map<String, dynamic>? ?? {};
      final data = (map['data'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MessageModel.fromJson)
              .toList() ??
          [];
      final pagination = PaginationInfo.fromLaravelMeta(
        map['meta'] as Map<String, dynamic>? ?? {},
      );
      return PaginatedList(items: data, pagination: pagination);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> markAsRead(int conversationId) async {
    try {
      await _dio.put('/conversations/$conversationId/read');
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<MessageModel> updateMessage(
    int conversationId,
    int messageId, {
    required String content,
  }) async {
    try {
      final response = await _dio.put(
        '/conversations/$conversationId/messages/$messageId',
        data: {'content': content},
      );
      final data = (response.data as Map<String, dynamic>? ?? {})['data'];
      return MessageModel.fromJson(data as Map<String, dynamic>);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> deleteMessage(int conversationId, int messageId) async {
    try {
      await _dio.delete('/conversations/$conversationId/messages/$messageId');
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> archiveConversation(int conversationId) async {
    try {
      await _dio.put('/conversations/$conversationId/archive');
      await CacheService.remove(_cacheKeyConversations);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> unarchiveConversation(int conversationId) async {
    try {
      await _dio.put('/conversations/$conversationId/unarchive');
      await CacheService.remove(_cacheKeyConversations);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> deleteConversation(int conversationId) async {
    try {
      await _dio.delete('/conversations/$conversationId');
      await CacheService.remove(_cacheKeyConversations);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }
}
