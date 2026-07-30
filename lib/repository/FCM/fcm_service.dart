import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:luminar_std/main.dart';
import 'package:luminar_std/presentation/chat_list_screen/controller/chat_provider.dart';
import 'package:luminar_std/presentation/jobs_screen/job_detail_screen.dart';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'package:luminar_std/repository/jobs/model/job_notification_model.dart';
import 'package:provider/provider.dart';

/// Top-level background FCM handler — runs in an isolate (no BuildContext)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  LoggerUtils.info(
    'Background FCM message received\n'
    '  messageId: ${message.messageId}\n'
    '  notification.title: ${message.notification?.title}\n'
    '  notification.body: ${message.notification?.body}\n'
    '  data: ${jsonEncode(message.data)}',
    tag: 'FCM',
  );

  // For Android data-only messages that arrive in background/terminated state,
  // Firebase won't show a system notification automatically — we must do it here.
  // (If a `notification` key is present, Firebase already shows it using the
  //  android.notification.sound from the payload, so we skip to avoid duplicates.)
  if (Platform.isAndroid && message.notification == null) {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    const channel = AndroidNotificationChannel(
      'luminar_high_importance_channel',
      'Luminar Notifications',
      description: 'Luminar Student App Notifications',
      importance: Importance.high,
      playSound: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await plugin.show(
      id: message.hashCode,
      title: message.data['title'] as String? ?? 'Luminar',
      body: message.data['body'] as String? ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'luminar_high_importance_channel',
          'Luminar Notifications',
          channelDescription: 'Luminar Student App Notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: null,
    );
  }
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

  // Stores notification data received before the navigator is ready
  static Map<String, dynamic>? _pendingNavData;

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

    // To ensure sound plays reliably and customize foreground behavior,
    // we use flutter_local_notifications to show foreground notifications on BOTH platforms.
    // We disable the native FCM foreground alert for iOS to prevent duplicate notifications.
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false, // Turned off so flutter_local_notifications handles it
        badge: true,
        sound: false, // Turned off to avoid native double sound
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
      criticalAlert: true,
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
      requestCriticalPermission: true,
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
        final apnsToken = await _waitForAPNSToken();
        LoggerUtils.info('APNs Token: $apnsToken', tag: 'FCM');
        if (apnsToken == null) {
          // No APNs token (e.g. simulator without push support, or not yet
          // registered) — skip getToken() since it would just throw.
          return null;
        }
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

  /// On iOS, the APNs token is only available after the device finishes
  /// registering with Apple's push service, which can take a moment after
  /// launch. Poll briefly instead of failing on the first attempt.
  Future<String?> _waitForAPNSToken() async {
    for (var attempt = 0; attempt < 30; attempt++) {
      final token = await _messaging.getAPNSToken();
      if (token != null) return token;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    LoggerUtils.warning('APNs token unavailable after retries (no push support on this device?)', tag: 'FCM');
    return null;
  }

  Future<String?> getToken() => _getToken();

  /// Invalidates the local FCM instance token on logout — belt-and-suspenders
  /// alongside telling the backend to unregister it, so even if the backend
  /// call fails, this device can't keep receiving the previous account's
  /// pushes. A fresh token is generated automatically the next time
  /// something calls getToken() (e.g. the next login).
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      LoggerUtils.info('FCM token deleted (logout)', tag: 'FCM');
    } catch (e) {
      LoggerUtils.error('Error deleting FCM token: $e', tag: 'FCM');
    }
  }

  // ─── Message Handlers ─────────────────────────────────────────────────────

  /// Dumps every field of an incoming [RemoteMessage] so the full payload
  /// (notification + data + metadata) is visible while debugging FCM.
  void _logMessage(String label, RemoteMessage message) {
    final notification = message.notification;
    LoggerUtils.info(
      '$label\n'
      '  messageId: ${message.messageId}\n'
      '  from: ${message.from}\n'
      '  sentTime: ${message.sentTime}\n'
      '  ttl: ${message.ttl}\n'
      '  category: ${message.category}\n'
      '  collapseKey: ${message.collapseKey}\n'
      '  notification.title: ${notification?.title}\n'
      '  notification.body: ${notification?.body}\n'
      '  data: ${jsonEncode(message.data)}',
      tag: 'FCM',
    );
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      _logMessage('Foreground FCM message received', message);
      if (notification != null) {
        // We use flutter_local_notifications for BOTH platforms to force sound
        // in the foreground even if the backend payload misses it.
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
      _logMessage('FCM opened from background', message);
      AppUtils.isDeepLinking = true;
      // Use post-frame callback so the navigator is guaranteed to be mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(message.data);
      });
    });
  }

  Future<void> handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _logMessage('FCM opened from terminated', initialMessage);
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
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: payload,
    );
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  /// Call this from the home screen after the widget tree is ready.
  /// Executes any notification navigation that arrived before the navigator was mounted.
  void processPendingNavigation() {
    final data = _pendingNavData;
    if (data == null) return;
    _pendingNavData = null;
    LoggerUtils.info('Processing pending notification navigation', tag: 'FCM');
    _handleNotificationNavigation(data);
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final route = data['route'] as String?;

    LoggerUtils.info('Handling notification navigation: type=$type, route=$route', tag: 'FCM');

    // ─── Special Type: job_notification ──────────────────────────────────────
    if (type == 'job_notification' || type == 'job' || route == 'job' || route == 'jobs') {
      final jobUid = data['job_uid']?.toString();
      if (jobUid == null || jobUid.isEmpty) {
        AppUtils.isDeepLinking = false;
        return;
      }

      final context = navigatorKey.currentContext;
      if (context == null) {
        // Navigator not ready yet — park the data and let processPendingNavigation handle it
        _pendingNavData = data;
        LoggerUtils.warning('Job nav deferred: context not ready', tag: 'FCM');
        return;
      }

      final notification = JobNotification(
        uid: data['notification_uid']?.toString() ?? '',
        jobUid: jobUid,
        jobTitle: data['job_title']?.toString() ?? '',
        companyName: data['company_name']?.toString() ?? '',
        companyUid: data['company_uid']?.toString() ?? '',
        batchName: data['batch_name']?.toString() ?? '',
        isViewed: false,
        createdAt: DateTime.now(),
        timesShared: 0,
        application: JobApplication(hasApplication: false),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            jobUid: jobUid,
            notification: notification,
          ),
        ),
      );
      AppUtils.isDeepLinking = false;
      return;
    }

    // ─── Special Type: chat_message ──────────────────────────────────────────
    if (type == 'chat_message') {
      final chatUid = data['chat_uid'] as String?;
      if (chatUid != null) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          Provider.of<ChatProvider>(context, listen: false).navigateToChat(chatUid);
        } else {
          _pendingNavData = data;
          LoggerUtils.warning('Chat nav deferred: context not ready', tag: 'FCM');
          AppUtils.isDeepLinking = false;
        }
      } else {
        AppUtils.isDeepLinking = false;
      }
      return;
    }

    // ─── Route-based navigation ───────────────────────────────────────────────
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
