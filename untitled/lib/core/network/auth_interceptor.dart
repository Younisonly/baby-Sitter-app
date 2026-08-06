import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:babysitter/core/constants/app_constants.dart';
import 'package:babysitter/core/services/auth_event_service.dart';
import 'package:babysitter/core/storage/local_storage.dart';

class AuthInterceptor extends Interceptor {
  String? _cachedToken;

  Future<void> _loadToken() async {
    _cachedToken ??= await LocalStorage.getAccessToken();
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _loadToken().then((_) {
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $_cachedToken';
      }
      handler.next(options);
    }).catchError((_) {
      handler.next(options);
    });
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _cachedToken = null;
      unawaited(LocalStorage.logout());
      AuthEventService.instance.emitUnauthorized();
    }
    super.onError(err, handler);
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = AppConstants.maxRetries,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final currentRetries = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
    if (_shouldRetry(err) && currentRetries < maxRetries) {
      final retryCount = currentRetries + 1;
      err.requestOptions.extra['retryCount'] = retryCount;

      final delay = Duration(milliseconds: (500 * (1 << (retryCount - 1)) + (Random().nextInt(500))));
      await Future.delayed(delay);

      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {}
    }
    super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
