import 'dart:async';

class AuthEventService {
  AuthEventService._();
  static final AuthEventService instance = AuthEventService._();

  final _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get unauthorizedStream => _unauthorizedController.stream;

  void emitUnauthorized() {
    _unauthorizedController.add(null);
  }

  void dispose() {
    _unauthorizedController.close();
  }
}
