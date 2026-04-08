import 'dart:io';

/// Global app configuration.
///
/// [hidePayments] is set once at startup based on the platform:
///   - iOS  → true   (App Store guidelines: hide all in-app payment UI)
///   - Android → false (show full payment flow)
///
/// Check this flag anywhere you need to conditionally show/hide
/// payment-related UI or skip payment navigation.
class AppConfig {
  AppConfig._();

  /// When true, all payment UI, payment cards, and payment navigation are hidden.
  static final bool hidePayments = Platform.isIOS;
}
