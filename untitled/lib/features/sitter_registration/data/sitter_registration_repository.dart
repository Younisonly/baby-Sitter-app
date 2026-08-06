import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';

final sitterRegistrationRepositoryProvider =
    Provider<SitterRegistrationRepository>((_) => SitterRegistrationRepository());

class SitterRegistrationRepository {
  Future<Map<String, dynamic>> getStatus() async {
    final response = await DioClient.dio.get('/auth/sitter-registration/status');
    return response.data;
  }

  Future<Map<String, dynamic>> startDraft() async {
    final response = await DioClient.dio.post('/auth/sitter-registration/start');
    return response.data;
  }

  Future<Map<String, dynamic>> discardDraft() async {
    final response = await DioClient.dio.delete('/auth/sitter-registration/draft');
    return response.data;
  }

  Future<Map<String, dynamic>> saveStep(int step, Map<String, dynamic> data) async {
    final response = await DioClient.dio.post(
      '/auth/sitter-registration/step/$step',
      data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> submit() async {
    final response = await DioClient.dio.post('/auth/sitter-registration/submit');
    return response.data;
  }
}
