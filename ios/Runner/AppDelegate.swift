import Flutter
import UIKit
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // GeneratedPluginRegistrant must run first: registering the firebase_core
    // plugin is what triggers [FIRApp configure] natively. Touching
    // Messaging.messaging() before this leaves the singleton unconfigured —
    // it won't pick up the APNs token even after Firebase configures later.
    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self

    // Notification permission is requested from Dart (FCMService._requestPermission).
    // Requesting it here too would race the same system dialog and can leave
    // the authorization status stuck at .notDetermined.
    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Forward APNs token to Firebase Messaging
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
  }

  // Foreground notification presentation — flutter_local_notifications handles
  // the actual display, but we must return .sound here as a fallback so iOS
  // plays sound even if the Flutter plugin is slow to respond.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }
}