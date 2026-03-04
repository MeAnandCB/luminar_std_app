/// AppStrings holds all static text values used across the app
/// This makes localization and refactoring much easier
class AppStrings {
  // App name
  static const String appName = "MyFlutterApp";

  // Login screen
  static const String loginTitle = "Login";
  static const String loginButton = "Sign In";
  static const String emailHint = "Enter your email";
  static const String passwordHint = "Enter your password";
  static const String forgotPassword = "Forgot Password?";

  // Home screen
  static const String homeTitle = "Home";
  static const String welcome = "Welcome";

  // Snackbar / messages
  static const String loginSuccess = "Login successful!";
  static const String loginFailed = "Login failed, try again.";

  // General errors
  static const String networkError = "Network error, please try again.";
  static const String unknownError = "Something went wrong.";

  // Add more strings here as your app grows
}
