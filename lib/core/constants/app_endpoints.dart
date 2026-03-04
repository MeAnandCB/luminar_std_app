class AppEndpoints {
  static const String baseUrl = String.fromEnvironment('BASE_URL'); // or dotenv
  static const String login = '/login';
  static const String register = '/register';
  static const String fetchUsers = '/users';
}
