import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/shared/models/user_model.dart';

final sitterProfileRepositoryProvider =
    Provider<SitterProfileRepository>((ref) {
  return SitterProfileRepository(DioClient.dio);
});

final sitterProfileUpdateProvider =
    StateNotifierProvider<SitterProfileUpdateNotifier, AsyncValue<UserModel?>>(
        (ref) {
  return SitterProfileUpdateNotifier(ref);
});

class SitterProfileRepository {
  SitterProfileRepository(this._dio);

  final Dio _dio;

  Future<UserModel> update(Map<String, dynamic> data) async {
    final response = await _dio.patch('/auth/sitter-profile', data: data);
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final userData = body['data'];
      if (userData is Map<String, dynamic>) {
        return UserModel.fromJson(userData);
      }
    }
    throw Exception('Unexpected response format');
  }
}

class SitterProfileUpdateNotifier
    extends StateNotifier<AsyncValue<UserModel?>> {
  SitterProfileUpdateNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<UserModel?> update(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(sitterProfileRepositoryProvider);
      final user = await repo.update(data);
      state = AsyncData(user);
      return user;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  void clear() => state = const AsyncData(null);
}
