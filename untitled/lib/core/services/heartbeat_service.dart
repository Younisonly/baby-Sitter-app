import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:babysitter/core/network/dio_client.dart';

class HeartbeatService {
  Timer? _timer;
  bool _isActive = false;

  static const _interval = Duration(seconds: 60);

  void start() {
    if (_isActive) return;
    _isActive = true;
    _send();
    _timer = Timer.periodic(_interval, (_) => _send());
  }

  void stop() {
    _isActive = false;
    _timer?.cancel();
    _timer = null;
  }

  void onLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _send();
      _timer?.cancel();
      _timer = Timer.periodic(_interval, (_) => _send());
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _send() async {
    try {
      await DioClient.dio.post('/heartbeat');
    } catch (_) {}
  }
}
