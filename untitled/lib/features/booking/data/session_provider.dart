import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/features/booking/data/session_repository.dart';
import 'package:babysitter/shared/models/booking_model.dart';

final sessionProvider = StateNotifierProvider.family<SessionNotifier, AsyncValue<SessionStatusResponse?>, String>((ref, bookingId) {
  final repo = ref.read(sessionRepositoryProvider);
  return SessionNotifier(repo, bookingId);
});

class SessionNotifier extends StateNotifier<AsyncValue<SessionStatusResponse?>> {
  final SessionRepository _repo;
  final String _bookingId;
  Timer? _pollTimer;

  SessionNotifier(this._repo, this._bookingId) : super(const AsyncValue.data(null));

  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _refreshStatus());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _repo.getSessionStatus(_bookingId);
      state = AsyncValue.data(status);
    } catch (_) {}
  }

  Future<QrCodeResponse> generateStartQr() async {
    final qr = await _repo.generateStartQr(_bookingId);
    await _refreshStatus();
    return qr;
  }

  Future<QrCodeResponse> generateEndQr() async {
    final qr = await _repo.generateEndQr(_bookingId);
    await _refreshStatus();
    return qr;
  }

  Future<BookingModel> scanStartQr({
    required String qrToken,
    String? notes,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final booking = await _repo.scanStartQr(
      qrToken: qrToken,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    await _refreshStatus();
    return booking;
  }

  Future<BookingModel> scanEndQr({required String qrToken}) async {
    final booking = await _repo.scanEndQr(qrToken: qrToken);
    await _refreshStatus();
    return booking;
  }

  Future<void> stopTrackingOnBackend() async {
    await _repo.stopTrackingOnBackend(_bookingId);
    await _refreshStatus();
  }

  Future<void> resumeTrackingOnBackend() async {
    await _repo.resumeTrackingOnBackend(_bookingId);
    await _refreshStatus();
  }

  Future<void> sendTracking({
    required double latitude,
    required double longitude,
    String? address,
    double? speed,
    int? battery,
  }) async {
    await _repo.sendTracking(
      bookingId: _bookingId,
      latitude: latitude,
      longitude: longitude,
      address: address,
      speed: speed,
      battery: battery,
    );
  }

  Future<TrackingData> getTracking({int limit = 100}) async {
    return _repo.getTracking(_bookingId, limit: limit);
  }

  Future<void> refreshStatus() => _refreshStatus();

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
