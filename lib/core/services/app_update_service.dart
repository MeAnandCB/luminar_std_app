import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  static const String _androidPackageId = 'com.luminartechnolab.studentapp';
  static const String _iosBundleId = 'com.luminartechnolab.studentapp';
  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.luminartechnolab.studentapp';
  static const String _iosStoreUrl =
      'https://apps.apple.com/in/app/luminar-technolab/id6482295579';

  static String get storeUrl =>
      Platform.isIOS ? _iosStoreUrl : _androidStoreUrl;

  static Future<String?>? _pendingCheck;

  /// Returns the store version string if an update is available, null otherwise.
  /// The underlying network check is memoized so concurrent callers (e.g. the
  /// splash screen and the app-wide update dialog) share a single request.
  static Future<String?> checkForUpdate() {
    return _pendingCheck ??= _performCheck();
  }

  static Future<String?> _performCheck() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final storeVersion = Platform.isIOS
          ? await _fetchIosVersion()
          : await _fetchAndroidVersion();

      if (storeVersion == null) return null;

      if (_isNewer(storeVersion, currentVersion)) return storeVersion;
    } catch (_) {}
    return null;
  }

  static Future<String?> _fetchIosVersion() async {
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=$_iosBundleId',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['version'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _fetchAndroidVersion() async {
    try {
      final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$_androidPackageId&hl=en',
      );
      final response = await http.get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Google Play encodes version in JSON blobs inside the HTML
        final patterns = [
          RegExp(r'\[\[\["(\d+\.\d+\.\d+)"\]\]'),
          RegExp(r'"softwareVersion":"(\d+\.\d+\.\d+)"'),
          RegExp(r'Current Version.*?(\d+\.\d+\.\d+)'),
        ];
        for (final re in patterns) {
          final m = re.firstMatch(response.body);
          if (m != null) return m.group(1);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Returns true if [storeVer] is strictly newer than [currentVer].
  static bool _isNewer(String storeVer, String currentVer) {
    final store = _parse(storeVer);
    final current = _parse(currentVer);
    for (int i = 0; i < 3; i++) {
      if (store[i] > current[i]) return true;
      if (store[i] < current[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String v) {
    final parts = v.split('.');
    return List.generate(3, (i) => i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0);
  }
}
