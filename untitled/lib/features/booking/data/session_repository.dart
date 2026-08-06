import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/error_handler.dart';
import 'package:babysitter/shared/models/booking_model.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(DioClient.dio);
});

class SessionRepository {
  SessionRepository(this._dio);

  final Dio _dio;

  Future<QrCodeResponse> generateStartQr(String bookingId) async {
    try {
      final response = await _dio.post('/sessions/$bookingId/generate-start-qr');
      final data = response.data['data'] as Map<String, dynamic>;
      return QrCodeResponse.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<BookingModel> scanStartQr({
    required String qrToken,
    String? notes,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final body = <String, dynamic>{'qr_token': qrToken};
      if (notes != null) body['notes'] = notes;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (address != null) body['address'] = address;

      final response = await _dio.post('/sessions/scan-start', data: body);
      final data = response.data['data'] as Map<String, dynamic>;
      return BookingModel.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<QrCodeResponse> generateEndQr(String bookingId) async {
    try {
      final response = await _dio.post('/sessions/$bookingId/generate-end-qr');
      final data = response.data['data'] as Map<String, dynamic>;
      return QrCodeResponse.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<BookingModel> scanEndQr({required String qrToken}) async {
    try {
      final response = await _dio.post('/sessions/scan-end', data: {
        'qr_token': qrToken,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return BookingModel.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> stopTrackingOnBackend(String bookingId) async {
    try {
      await _dio.post('/sessions/$bookingId/tracking/stop');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> resumeTrackingOnBackend(String bookingId) async {
    try {
      await _dio.post('/sessions/$bookingId/tracking/resume');
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> sendTracking({
    required String bookingId,
    required double latitude,
    required double longitude,
    String? address,
    double? speed,
    int? battery,
  }) async {
    try {
      await _dio.post('/sessions/$bookingId/tracking', data: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (speed != null) 'speed': speed,
        if (battery != null) 'battery': battery,
      });
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<TrackingData> getTracking(String bookingId, {int limit = 100, String? since}) async {
    try {
      final query = <String, dynamic>{'limit': limit};
      if (since != null) query['since'] = since;

      final response = await _dio.get('/sessions/$bookingId/tracking', queryParameters: query);
      final data = response.data['data'] as Map<String, dynamic>;
      return TrackingData.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<LocationPoint> refreshTracking(String bookingId) async {
    try {
      final response = await _dio.post('/sessions/$bookingId/tracking/refresh');
      final data = response.data['data'] as Map<String, dynamic>;
      return LocationPoint.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<SessionStatusResponse> getSessionStatus(String bookingId) async {
    try {
      final response = await _dio.get('/sessions/$bookingId/status');
      final data = response.data['data'] as Map<String, dynamic>;
      return SessionStatusResponse.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<BookingModel?> getActiveSession() async {
    try {
      final response = await _dio.get('/sessions/active');
      final data = response.data['data'];
      if (data == null) return null;
      return BookingModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<BookingModel> forceStop({
    required String bookingId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post('/sessions/$bookingId/force-stop', data: {
        'reason': reason,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return BookingModel.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
