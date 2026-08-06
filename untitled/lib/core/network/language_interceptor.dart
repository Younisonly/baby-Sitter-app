import 'package:dio/dio.dart';
import 'package:babysitter/core/storage/local_storage.dart';

class LanguageInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['Accept-Language'] = LocalStorage.getLanguageCodeSync();
    handler.next(options);
  }
}
