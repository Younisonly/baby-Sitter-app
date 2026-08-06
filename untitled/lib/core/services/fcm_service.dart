import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:babysitter/core/services/app_provider.dart';
import 'package:babysitter/core/services/notification_localization_service.dart';
import 'package:babysitter/core/storage/local_storage.dart';
import 'package:babysitter/features/notifications/data/notification_repository.dart';
import 'package:babysitter/features/notifications/data/notification_settings_repository.dart';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(ref));

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final data = message.data;
  final type = data['type'] ?? '';
  final id = data['id'] ?? '';
  if (type.isNotEmpty) {
    await LocalStorage.setPendingDeepLink(type, id);
  }
}

class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;

  Future<void> init() async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        _messaging = FirebaseMessaging.instance;

        _localNotifications = FlutterLocalNotificationsPlugin();
        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        await _localNotifications!.initialize(
          const InitializationSettings(
            android: androidSettings,
            iOS: iosSettings,
          ),
          onDidReceiveNotificationResponse: _handleLocalNotificationTap,
        );

        await _createNotificationChannels();

        await _requestNotificationPermissionAndroid();

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        await _requestPermission();
        final token = await _messaging!.getToken();
        if (token != null) {
          await _saveToken(token);
        }

        _messaging!.onTokenRefresh.listen((t) async {
          try {
            await _saveToken(t);
          } catch (_) {
          }
        });

        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        final initialMessage =
            await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      } catch (_) {
      }
    }
  }

  Future<void> _createNotificationChannels() async {
    final android = _localNotifications?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      'bookings',
      'Booking Notifications',
      description: 'Booking confirmations, reminders, cancellations',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'chat',
      'Chat Messages',
      description: 'New messages, voice notes, images',
      importance: Importance.high,
      playSound: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'followers',
      'Followers',
      description: 'New followers, milestones',
      importance: Importance.defaultImportance,
      playSound: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'review',
      'Reviews',
      description: 'New reviews, replies',
      importance: Importance.defaultImportance,
      playSound: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'security',
      'Security Alerts',
      description: 'Login alerts, password changes',
      importance: Importance.high,
      playSound: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'support',
      'Support',
      description: 'Ticket replies and updates',
      importance: Importance.defaultImportance,
      playSound: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'system',
      'System Updates',
      description: 'App updates, policy changes',
      importance: Importance.defaultImportance,
      playSound: true,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'default',
      'General Notifications',
      description: 'Other notifications',
      importance: Importance.defaultImportance,
      playSound: true,
    ));
  }

  Future<void> _requestPermission() async {
    if (_messaging == null) return;

    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      await _messaging!.requestPermission();
    }
  }

  Future<void> _requestNotificationPermissionAndroid() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final android = _localNotifications?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        if (granted != true) {
          await android.requestNotificationsPermission();
        }
      }
    } catch (_) {
    }
  }

  Future<void> _saveToken(String token) async {
    await LocalStorage.setDeviceToken(token);
    try {
      final repo = _ref.read(notificationSettingsRepositoryProvider);
      await repo.registerDevice(deviceToken: token);
    } catch (_) {}
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (_localNotifications == null) return;
    try {
      final data = message.data;
      final type = data['type'] ?? 'default';
      final id = data['id'] ?? '';
      final notificationId = data['notification_id'] ?? '';
      final actionKey = data['action_key']?.toString();

      // Parse the replacements map sent by the backend so we can interpolate
      // template tokens client-side (e.g. {sitter_name}, {date}, {time}).
      Map<String, dynamic>? replacements;
      final dataJsonRaw = data['data_json'];
      if (dataJsonRaw != null && dataJsonRaw is String && dataJsonRaw.isNotEmpty) {
        try {
          final decoded = _decodeJson(dataJsonRaw);
          if (decoded is Map<String, dynamic>) {
            replacements = decoded;
          }
        } catch (_) {}
      }

      // Get the user's stored language preference for proper localization.
      final locale = await LocalStorage.getLanguageCode();

      // Raw title/body from FCM (backend's best-effort resolved string).
      final rawTitle = message.notification?.title ?? data['title'] ?? '';
      final rawBody  = message.notification?.body  ?? data['body']  ?? '';

      // Use the same localization engine as the in-app notification list.
      final localizedTitle = NotificationLocalizationService.resolveTitle(
        actionKey: actionKey,
        locale: locale,
        apiTitle: rawTitle,
        data: replacements,
      );
      final localizedBody = NotificationLocalizationService.resolveBody(
        actionKey: actionKey,
        locale: locale,
        apiBody: rawBody,
        data: replacements,
      );

      final displayTitle = localizedTitle.isNotEmpty ? localizedTitle : rawTitle;
      final displayBody  = localizedBody.isNotEmpty  ? localizedBody  : rawBody;

      final payload = '$type|$id|$notificationId';

      final androidDetails = AndroidNotificationDetails(
        _channelForType(type),
        _channelNameForType(type),
        channelDescription: '',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notifId = DateTime.now().millisecondsSinceEpoch % 100000;
      if (notifId == _lastNotifId) return;
      _lastNotifId = notifId;

      await _localNotifications!.show(
        notifId,
        displayTitle,
        displayBody,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (_) {}

    _refreshUnreadCount();
  }

  /// Decodes a JSON string using dart:convert.
  static dynamic _decodeJson(String raw) => jsonDecode(raw);

  int _lastNotifId = 0;

  void _handleLocalNotificationTap(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) return;
      final parts = payload.split('|');
      if (parts.length >= 2) {
        DeepLinkNavigation.handle(parts[0], parts[1]);
      }
    } catch (_) {
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      final type = data['type'] ?? '';
      final id = data['id'] ?? '';
      DeepLinkNavigation.handle(type, id);
    } catch (_) {
    }
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final repo = _ref.read(notificationRepositoryProvider);
      final count = await repo.getUnreadCount();
      final appState = _ref.read(appStateProvider.notifier);
      appState.setUnreadNotifications(count);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    if (_messaging == null) return null;
    try {
      return await _messaging!.getToken();
    } catch (_) {
      return null;
    }
  }

  String _channelForType(String type) {
    switch (type) {
      case 'booking':
        return 'bookings';
      case 'chat':
        return 'chat';
      case 'followers':
        return 'followers';
      case 'review':
        return 'review';
      case 'security':
        return 'security';
      case 'support':
        return 'support';
      case 'system':
        return 'system';
      default:
        return 'default';
    }
  }

  String _channelNameForType(String type) {
    switch (type) {
      case 'booking':
        return 'Booking Notifications';
      case 'chat':
        return 'Chat Messages';
      case 'followers':
        return 'Followers';
      case 'review':
        return 'Reviews';
      case 'security':
        return 'Security Alerts';
      case 'support':
        return 'Support';
      case 'system':
        return 'System Updates';
      default:
        return 'General Notifications';
    }
  }
}

class DeepLinkNavigation {
  DeepLinkNavigation._();

  static void Function(String? type, String? id)? _navigator;

  static void init(void Function(String? type, String? id) navigator) {
    _navigator = navigator;
  }

  static void handle(String? type, String? id) {
    _navigator?.call(type, id);
  }
}
