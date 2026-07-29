import 'package:shared_preferences/shared_preferences.dart';

/// Default values used until a tester overrides them on the Server settings
/// screen. Local-dev server address and key — update here or override
/// per-device in Server settings if the server address/key changes.
class AppConfigLap {
  static const _baseUrlKey = 'baseUrl';
  static const _apiKeyKey = 'apiKey';

  static const defaultBaseUrl = 'http://192.168.1.34:3001/api/mobile/laptops';
  static const defaultApiKey =
      '837f0e20dc153f386db373661e607c8030ce26de1ba3a79c';

  final String baseUrl;
  final String apiKey;

  const AppConfigLap({required this.baseUrl, required this.apiKey});

  bool get isConfigured => baseUrl.isNotEmpty && apiKey.isNotEmpty;

  static Future<AppConfigLap> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfigLap(
      baseUrl: prefs.getString(_baseUrlKey) ?? defaultBaseUrl,
      apiKey: prefs.getString(_apiKeyKey) ?? defaultApiKey,
    );
  }

  static Future<void> save({
    required String baseUrl,
    required String apiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, baseUrl);
    await prefs.setString(_apiKeyKey, apiKey);
  }
}
