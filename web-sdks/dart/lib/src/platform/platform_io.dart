import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'platform_interface.dart';
import 'secure_cookie_storage.dart';

GroupVanPlatform createPlatform() => IoPlatform();

class IoPlatform implements GroupVanPlatform {
  /// One shared jar so every Dio instance (including RetryInterceptor's
  /// fresh retry Dio) sees the same refresh_token / gv_session cookies.
  final PersistCookieJar _jar = PersistCookieJar(
    storage: SecureCookieStorage(),
  );

  @override
  String? get origin => null;

  @override
  Uri? get currentUrl => null;

  @override
  void redirect(String url) => throw UnsupportedError(
    'Google sign-in via browser redirect is not supported on this platform',
  );

  @override
  void configureDioCredentials(Dio dio) {
    dio.interceptors.add(CookieManager(_jar));
  }

  @override
  Future<void> clearCookies() => _jar.deleteAll();
}
