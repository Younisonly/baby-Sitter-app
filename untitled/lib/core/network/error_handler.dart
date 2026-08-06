import 'package:dio/dio.dart';
import 'package:babysitter/core/localization/app_localization.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic data;

  AppException({
    required this.message,
    this.code,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppException(
            message: AppLocalization.connection_timeout,
            code: 'TIMEOUT',
          );
        case DioExceptionType.badResponse:
          return _handleHttpError(error.response);
        case DioExceptionType.cancel:
          return AppException(
            message: AppLocalization.request_cancelled,
            code: 'CANCELLED',
          );
        case DioExceptionType.connectionError:
          return AppException(
            message: AppLocalization.no_internet_connection,
            code: 'CONNECTION_ERROR',
          );
        default:
          return AppException(
            message: AppLocalization.unexpected_error,
            code: 'UNKNOWN',
          );
      }
    }
    if (error is AppException) {
      return error;
    }
    if (error is TypeError) {
      return AppException(
        message: AppLocalization.processing_error,
        code: 'TYPE_ERROR',
      );
    }
    return AppException(
      message: AppLocalization.unexpected_error,
      code: 'UNKNOWN',
    );
  }

  static AppException _handleHttpError(Response? response) {
    if (response == null) {
      return AppException(
        message: AppLocalization.no_response,
        code: 'NO_RESPONSE',
      );
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String message;

    if (data is Map && data['message'] != null) {
      final rawMessage = data['message'].toString();
      message = _mapBackendMessage(rawMessage);
    } else {
      message = _getDefaultMessage(statusCode);
    }

    if (statusCode == 422 && data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      final parts = <String>[];
      for (final msgs in errors.values) {
        if (msgs is List) {
          for (final m in msgs.whereType<String>()) {
            parts.add(_mapBackendMessage(m));
          }
        }
      }
      if (parts.isNotEmpty) {
        message = '${parts.length > 1 ? '• ' : ''}${parts.join('\n• ')}';
      }
    }

    return AppException(
      message: message,
      code: data?['code']?.toString(),
      statusCode: statusCode,
      data: data,
    );
  }

  /// Maps well-known backend English messages to localization keys.
  /// The localization key is later looked up by AppSnackbar to display
  /// the translated string. Unrecognized messages pass through as-is.
  static String _mapBackendMessage(String raw) {
    final normalized = raw.trim().toLowerCase();

    // Auth errors
    if (normalized.contains('credentials are incorrect') ||
        normalized.contains('invalid credentials') ||
        normalized.contains('wrong password') ||
        normalized.contains('password is incorrect') ||
        normalized.contains('these credentials do not match')) {
      return AppLocalization.invalid_credentials;
    }
    if (normalized.contains('unauthenticated')) {
      return AppLocalization.unauthorized;
    }
    if (normalized.contains('account is suspended') ||
        normalized.contains('account suspended')) {
      return AppLocalization.account_suspended;
    }
    if (normalized.contains('not verified yet') ||
        normalized.contains('not verified') ||
        normalized.contains('account is not verified')) {
      return AppLocalization.account_unverified;
    }
    if (normalized.contains('too many') || normalized.contains('throttl')) {
      return AppLocalization.too_many_requests;
    }

    // Business logic
    if (normalized.contains('cannot book yourself')) {
      return AppLocalization.cannot_book_yourself;
    }
    if (normalized.contains('cannot follow yourself')) {
      return AppLocalization.cannot_follow_yourself;
    }
    if (normalized.contains('you cannot accept your own request')) {
      return AppLocalization.cannot_accept_own;
    }
    if (normalized.contains('this request is no longer open')) {
      return AppLocalization.request_already_closed;
    }

    // HTTP errors
    if (normalized.contains('not found') ||
        normalized.contains('no query results')) {
      return AppLocalization.resource_not_found;
    }
    if (normalized.contains('unauthorized') ||
        normalized.contains('forbidden') ||
        normalized.contains('do not have permission')) {
      return AppLocalization.access_denied;
    }
    if (normalized.contains('server error') ||
        normalized.contains('internal server')) {
      return AppLocalization.internal_server_error;
    }
    if (normalized.contains('service unavailable')) {
      return AppLocalization.service_unavailable;
    }
    if (normalized.contains('no internet') ||
        (normalized.contains('network') &&
            normalized.contains('unavailable'))) {
      return AppLocalization.no_internet_connection;
    }

    // Password validation
    if (normalized.contains('uppercase') ||
        normalized.contains('lowercase') ||
        normalized.contains('mixed case') ||
        normalized.contains('must contain at least one uppercase') ||
        normalized.contains('must contain at least one lowercase')) {
      return AppLocalization.password_mixed_case;
    }
    if (normalized.contains('password') &&
        (normalized.contains('at least') || normalized.contains('minimum')) &&
        normalized.contains('character')) {
      return AppLocalization.password_too_short;
    }
    if (normalized.contains('password') && normalized.contains('number')) {
      return AppLocalization.password_needs_number;
    }
    if (normalized.contains('password') && normalized.contains('symbol')) {
      return AppLocalization.password_needs_symbol;
    }
    if (normalized.contains('password') && normalized.contains('letter')) {
      return AppLocalization.password_needs_letter;
    }
    if (normalized.contains('confirmation') &&
        normalized.contains('does not match')) {
      return AppLocalization.password_confirmation_mismatch;
    }

    // Field validation
    if (normalized.contains('email') && normalized.contains('taken') ||
        normalized.contains('email') && normalized.contains('already')) {
      return AppLocalization.email_already_taken;
    }
    if (normalized.contains('phone') && normalized.contains('taken') ||
        normalized.contains('phone') && normalized.contains('already')) {
      return AppLocalization.phone_already_taken;
    }
    if (normalized.contains('is required')) {
      return AppLocalization.field_required;
    }
    if (normalized.contains('must be a valid email')) {
      return AppLocalization.invalid_email;
    }
    if (normalized.contains('national id') && normalized.contains('required')) {
      return AppLocalization.national_id_required;
    }
    if (normalized.contains('national id') && normalized.contains('taken')) {
      return AppLocalization.national_id_taken;
    }

    // Return raw message if no mapping found — displayed as-is by snackbar
    return raw;
  }

  static String _getDefaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return AppLocalization.bad_request;
      case 401:
        return AppLocalization.unauthorized;
      case 403:
        return AppLocalization.access_denied;
      case 404:
        return AppLocalization.resource_not_found;
      case 409:
        return AppLocalization.conflict;
      case 422:
        return AppLocalization.validation_error;
      case 429:
        return AppLocalization.too_many_requests;
      case 500:
        return AppLocalization.internal_server_error;
      case 502:
        return AppLocalization.bad_gateway;
      case 503:
        return AppLocalization.service_unavailable;
      default:
        return AppLocalization.general_error;
    }
  }
}

