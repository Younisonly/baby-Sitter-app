import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/constants/app_config.dart';
import 'package:babysitter/core/network/dio_client.dart';

final imageUploadRepositoryProvider = Provider<ImageUploadRepository>((ref) {
  return ImageUploadRepository(DioClient.dio);
});

class ImageUploadRepository {
  ImageUploadRepository(this._dio);
  final Dio _dio;

  Future<String> uploadImage({
    required String filePath,
    String folder = 'images',
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
      'folder': folder,
    });
    final response = await _dio.post('/uploads/image', data: formData);
    return _absoluteUrl(response.data['data']['url'] as String);
  }

  Future<String> uploadAvatar({required String filePath}) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/uploads/avatar', data: formData);
    return _absoluteUrl(response.data['data']['url'] as String);
  }

  String _absoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/storage/')) {
      return '${AppConfig.storageHost}$path';
    }
    return '${AppConfig.storageHost}/storage/$path';
  }
}
