import 'package:dio/dio.dart';

class DedupeInterceptor extends Interceptor {
  final Set<String> _inflightRequests = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'GET') {
      handler.next(options);
      return;
    }
    final key = '${options.method}:${options.path}';
    if (_inflightRequests.contains(key)) {
      handler.reject(
        DioException(requestOptions: options, error: 'Duplicate request: $key'),
        true,
      );
      return;
    }
    _inflightRequests.add(key);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _removeKey(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _removeKey(err.requestOptions);
    handler.next(err);
  }

  void _removeKey(RequestOptions options) {
    if (options.method == 'GET') return;
    final key = '${options.method}:${options.path}';
    _inflightRequests.remove(key);
  }
}
