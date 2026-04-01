import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/main.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:provider/provider.dart';

/// Top-level background FCM handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  LoggerUtils.info('Background FCM: ${message.notification?.title} | Data: ${message.data}', tag: 'FCM');
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

  bool _isInitialized = false;

  // ─── Public Init ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) {
      LoggerUtils.info('FCM already initialized, skipping.', tag: 'FCM');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _initLocalNotifications();
    await _getToken();

    _messaging.onTokenRefresh.listen((newToken) {
      LoggerUtils.info('FCM Token Refreshed: $newToken', tag: 'FCM');
      // TODO: Send updated token to your backend
    });

    // Handle iOS foreground behavior:
    // We set alert/sound to false here because we manually show a local notification
    // via _handleForegroundMessages. This prevents the "double notification" issue on iOS.
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
    }

    _handleForegroundMessages();
    _handleBackgroundToOpenMessages();

    _isInitialized = true;
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
        try {
          if (response.payload != null) {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationNavigation(data);
          }
        } catch (e) {
          LoggerUtils.error('Error parsing notification payload: $e', tag: 'FCM');
          // Fallback for old simple string routes
          _handleNotificationNavigation({'route': response.payload});
        }
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
      final notification = message.notification;
      LoggerUtils.info('Foreground FCM: ${notification?.title} | Data: ${message.data}', tag: 'FCM');
      if (notification != null) {
        _showLocalNotification(
          id: message.hashCode,
          title: notification.title ?? 'Luminar',
          body: notification.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  void _handleBackgroundToOpenMessages() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LoggerUtils.info('FCM opened from background | Data: ${message.data}', tag: 'FCM');
      AppUtils.isDeepLinking = true;
      _handleNotificationNavigation(message.data);
    });
  }

  Future<void> handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      LoggerUtils.info('FCM opened from terminated | Data: ${initialMessage.data}', tag: 'FCM');
      AppUtils.isDeepLinking = true;
      await Future.delayed(const Duration(seconds: 1));
      _handleNotificationNavigation(initialMessage.data);
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

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final route = data['route'] as String?;

    LoggerUtils.info('Handling notification navigation: type=$type, route=$route', tag: 'FCM');

    // ─── Special Type: chat_message ──────────────────────────────────────────
    if (type == 'chat_message') {
      final chatUid = data['chat_uid'] as String?;
      if (chatUid != null) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          Provider.of<ChatProvider>(context, listen: false).navigateToChat(chatUid);
        } else {
          LoggerUtils.warning('Cannot navigate to chat: context is null', tag: 'FCM');
          AppUtils.isDeepLinking = false;
        }
      } else {
        AppUtils.isDeepLinking = false;
      }
      return;
    }

    // ─── Route-based navigation (existing logic) ──────────────────────────────
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
