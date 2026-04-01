import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/main.dart';

/// Top-level background FCM handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  LoggerUtils.info('Background FCM: ${message.notification?.title}', tag: 'FCM');
}

/// Top-level local notification background tap handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  LoggerUtils.info('Background notification tapped: ${response.payload}', tag: 'FCM');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'luminar_high_importance_channel',
    'Luminar Notifications',
    description: 'Luminar Student App Notifications',
    importance: Importance.high,
  );

  // ─── Public Init ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _initLocalNotifications();
    await _getToken();

    _messaging.onTokenRefresh.listen((newToken) {
      LoggerUtils.info('FCM Token Refreshed: $newToken', tag: 'FCM');
      // TODO: Send updated token to your backend
    });

    // Added for iOS foreground support
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    }

    _handleForegroundMessages();
    _handleBackgroundToOpenMessages();
    await _handleTerminatedStateMessage();
  }

  // ─── Permission ───────────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    LoggerUtils.info('FCM Permission: ${settings.authorizationStatus}', tag: 'FCM');
  }

  // ─── Local Notifications Setup ────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        LoggerUtils.info('Notification tapped: ${response.payload}', tag: 'FCM');
        _handleNotificationNavigation(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create Android high-importance channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // ─── Token ────────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        LoggerUtils.info('APNs Token: $apnsToken', tag: 'FCM');
      }

      final String? token = await _messaging.getToken();
      LoggerUtils.info('FCM Token: $token', tag: 'FCM');

      // TODO: Send this token to your Luminar backend API
      // Example: await ApiService.updateFCMToken(token);

      return token;
    } catch (e) {
      LoggerUtils.error('Error getting FCM token: $e', tag: 'FCM');
      return null;
    }
  }

  Future<String?> getToken() => _getToken();

  // ─── Message Handlers ─────────────────────────────────────────────────────

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LoggerUtils.info('Foreground FCM: ${message.notification?.title}', tag: 'FCM');
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          id: message.hashCode,
          title: notification.title ?? 'Luminar',
          body: notification.body ?? '',
          payload: message.data.toString(),
        );
      }
    });
  }

  void _handleBackgroundToOpenMessages() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LoggerUtils.info('FCM opened from background: ${message.data}', tag: 'FCM');
      _handleNotificationNavigation(message.data['route'] as String?);
    });
  }

  Future<void> _handleTerminatedStateMessage() async {
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      LoggerUtils.info('FCM opened from terminated: ${initialMessage.data}', tag: 'FCM');
      await Future.delayed(const Duration(seconds: 1));
      _handleNotificationNavigation(initialMessage.data['route'] as String?);
    }
  }

  // ─── Show Local Notification ──────────────────────────────────────────────

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: payload,
    );
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _handleNotificationNavigation(String? route) {
    if (route == null) return;

    switch (route) {
      case 'live_class':
        navigatorKey.currentState?.pushNamed('/live_class');
        break;
      case 'chat':
        navigatorKey.currentState?.pushNamed('/chat');
        break;
      default:
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }
}
