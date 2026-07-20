import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// cookie_jar [Storage] backed by flutter_secure_storage, so auth cookies
/// (refresh_token, gv_session) are encrypted at rest instead of written to
/// a plaintext file.
class SecureCookieStorage implements Storage {
  static const String _prefix = 'groupvan_cookies.';

  final FlutterSecureStorage _secureStorage;

  SecureCookieStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => _secureStorage.read(key: '$_prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _secureStorage.write(key: '$_prefix$key', value: value);

  @override
  Future<void> delete(String key) =>
      _secureStorage.delete(key: '$_prefix$key');

  @override
  Future<void> deleteAll(List<String> keys) async {
    // Delete every stored cookie entry, not just the passed keys.
    final all = await _secureStorage.readAll();
    for (final key in all.keys.where((k) => k.startsWith(_prefix))) {
      await _secureStorage.delete(key: key);
    }
  }
}
