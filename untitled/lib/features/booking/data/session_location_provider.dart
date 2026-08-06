import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:babysitter/features/booking/data/session_provider.dart';

enum LocationTrackingState {
  inactive,
  requesting,
  active,
  disabled,
  stopped,
}

final sessionLocationProvider = StateNotifierProvider.family<SessionLocationNotifier, LocationTrackingState, String>(
  (ref, bookingId) {
    return SessionLocationNotifier(ref, bookingId);
  },
);

class SessionLocationNotifier extends StateNotifier<LocationTrackingState> {
  final Ref _ref;
  final String _bookingId;
  StreamSubscription<Position>? _positionSub;
  Timer? _retryTimer;
  bool _gotFirstFix = false;

  SessionLocationNotifier(this._ref, this._bookingId) : super(LocationTrackingState.inactive);

  Future<bool> hasLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> hasPermissionGranted() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  Future<void> startTracking() async {
    if (state == LocationTrackingState.active) return;

    state = LocationTrackingState.requesting;

    final gpsOn = await Geolocator.isLocationServiceEnabled();
    if (!gpsOn) {
      state = LocationTrackingState.disabled;
      return;
    }

    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      final result = await Permission.locationWhenInUse.request();
      if (!result.isGranted) {
        state = LocationTrackingState.disabled;
        return;
      }
    }

    // Notify backend that tracking has resumed (clear gps_ended_at)
    try {
      await _ref.read(sessionProvider(_bookingId).notifier).resumeTrackingOnBackend();
    } catch (_) {}

    _startListening();

    // Immediately get a position fix so there's data right away
    sendCurrentPosition();
  }

  void _startListening() {
    _positionSub?.cancel();
    _gotFirstFix = false;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen(
      (position) {
        if (!_gotFirstFix) {
          _gotFirstFix = true;
          state = LocationTrackingState.active;
        }
        _sendLocation(position);
      },
      onError: (error) {
        state = LocationTrackingState.disabled;
        _scheduleRetry();
      },
    );
  }

  void _sendLocation(Position position) {
    final sessionNotifier = _ref.read(sessionProvider(_bookingId).notifier);
    final speed = position.speed >= 0 ? position.speed : null;
    sessionNotifier.sendTracking(
      latitude: position.latitude,
      longitude: position.longitude,
      speed: speed,
    ).catchError((_) {});
  }

  /// Gets a single GPS position immediately and sends it to the backend.
  /// Returns true if position was obtained and sent, false on failure/timeout.
  Future<bool> sendCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _sendLocation(position);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (state == LocationTrackingState.disabled) {
        startTracking();
      }
    });
  }

  Future<void> openLocationSettings() async {
    await openAppSettings();
  }

  /// Re-checks GPS + permission and starts tracking if both are OK.
  /// Returns true if tracking started, false otherwise.
  Future<bool> recheck() async {
    final gpsOn = await Geolocator.isLocationServiceEnabled();
    if (!gpsOn) {
      state = LocationTrackingState.disabled;
      return false;
    }

    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      final result = await Permission.locationWhenInUse.request();
      if (!result.isGranted) {
        state = LocationTrackingState.disabled;
        return false;
      }
    }

    await _ref.read(sessionProvider(_bookingId).notifier).resumeTrackingOnBackend();
    _startListening();

    // Immediately get a position fix
    sendCurrentPosition();

    return true;
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _gotFirstFix = false;
    state = LocationTrackingState.stopped;
    // Notify backend that tracking stopped
    _ref.read(sessionProvider(_bookingId).notifier).stopTrackingOnBackend();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
