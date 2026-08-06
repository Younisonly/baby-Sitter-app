import 'package:dio/dio.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/shared/models/language_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) => DioClient.dio);

final languagesProvider = FutureProvider<List<LanguageModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/languages');
  final data = response.data['data'] as List;
  return data.map((json) => LanguageModel.fromJson(json as Map<String, dynamic>)).toList();
});
