import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await DioClient.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      'device_name': 'mobile_app',
    });
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? role,
    String? nationalId,
    String channel = 'email',
  }) async {
    final response = await DioClient.dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': password,
      if (role != null) 'role': role,
      if (nationalId != null) 'national_id': nationalId,
      'channel': channel,
    });
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> verifyOtp(String otp, String? otpToken) async {
    final response = await DioClient.dio.post('/auth/verify-otp', data: {
      'otp': otp,
      'otp_token': otpToken,
      'device_name': 'mobile_app',
    });
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> forgotPassword({
    String? email,
    String? phone,
  }) async {
    final response = await DioClient.dio.post('/auth/forgot-password', data: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
    return _extractData(response.data);
  }

  Future<void> resetPassword({
    required String otpToken,
    required String otp,
    required String password,
  }) async {
    await DioClient.dio.post('/auth/reset-password', data: {
      'otp_token': otpToken,
      'otp': otp,
      'password': password,
      'password_confirmation': password,
    });
  }

  Future<Map<String, dynamic>> requestLoginOtp({
    String? email,
    String? phone,
    String? channel,
  }) async {
    final response = await DioClient.dio.post('/auth/request-login-otp', data: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (channel != null) 'channel': channel,
    });
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> verifyLoginOtp(
    String otp,
    String? otpToken,
  ) async {
    final response = await DioClient.dio.post('/auth/verify-login-otp', data: {
      'otp': otp,
      'otp_token': otpToken,
      'device_name': 'mobile_app',
    });
    return _extractData(response.data);
  }

  Future<void> logout() async {
    await DioClient.dio.post('/auth/logout');
  }

  Future<void> deleteAccount() async {
    await DioClient.dio.delete('/auth/account');
  }

  Future<void> removeSitterAccount(String password) async {
    await DioClient.dio.delete('/auth/sitter-account', data: {
      'password': password,
    });
  }

  Future<Map<String, dynamic>> loadUser() async {
    final response = await DioClient.dio.get('/auth/me');
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await DioClient.dio.patch('/auth/profile', data: data);
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> sendUpdateOtp({
    String? email,
    String? phone,
  }) async {
    final response = await DioClient.dio.post('/auth/send-update-otp', data: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    });
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> verifyUpdateOtp({
    required String otp,
    required String otpToken,
  }) async {
    final response = await DioClient.dio.post('/auth/verify-update-otp', data: {
      'otp': otp,
      'otp_token': otpToken,
    });
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> getAvailableRoles() async {
    final response = await DioClient.dio.get('/auth/roles');
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> becomeSitter(String nationalId) async {
    final response = await DioClient.dio.post('/auth/become-sitter', data: {
      'national_id': nationalId,
    });
    return _extractData(response.data);
  }

  Future<Map<String, dynamic>> socialLogin(
    String provider,
    String idToken,
  ) async {
    final response = await DioClient.dio.post('/auth/social', data: {
      'provider': provider,
      'id_token': idToken,
      'device_name': 'mobile_app',
    });
    return _extractData(response.data);
  }

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];
      if (data is Map<String, dynamic>) return data;
      return responseData;
    }
    return <String, dynamic>{};
  }
}
