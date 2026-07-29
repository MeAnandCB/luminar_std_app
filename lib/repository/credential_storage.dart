import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the "Remember me" login credentials in the platform secure
/// storage (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on
/// Android) so they survive logout and app restarts without sitting in
/// plaintext SharedPreferences.
class CredentialStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyIdentifier = 'remembered_identifier';
  static const _keyPassword = 'remembered_password';
  static const _keyRememberMe = 'remember_me';

  static Future<void> saveCredentials({
    required String identifier,
    required String password,
  }) async {
    await _storage.write(key: _keyIdentifier, value: identifier);
    await _storage.write(key: _keyPassword, value: password);
    await _storage.write(key: _keyRememberMe, value: 'true');
  }

  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keyIdentifier);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keyRememberMe);
  }

  static Future<bool> isRemembered() async {
    return (await _storage.read(key: _keyRememberMe)) == 'true';
  }

  static Future<String?> getIdentifier() =>
      _storage.read(key: _keyIdentifier);

  static Future<String?> getPassword() => _storage.read(key: _keyPassword);
}
