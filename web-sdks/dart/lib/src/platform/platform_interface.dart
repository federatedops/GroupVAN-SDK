import 'package:dio/dio.dart';

/// Platform-specific behavior the SDK depends on.
///
/// Web relies on the browser (window.location, HttpOnly cookies sent via
/// withCredentials); io platforms (mobile/desktop) replicate the cookie
/// behavior with a persistent cookie jar and have no page URL to read.
abstract class GroupVanPlatform {
  /// Current page origin, or null where there is no page (io).
  String? get origin;

  /// Current page URL, or null where there is no page (io).
  Uri? get currentUrl;

  /// Navigate the browser to [url]. Throws [UnsupportedError] on io.
  void redirect(String url);

  /// Configure [dio] so auth cookies (refresh_token, gv_session) are sent:
  /// withCredentials on web, a shared persistent cookie jar on io.
  void configureDioCredentials(Dio dio);

  /// Delete locally persisted cookies (no-op on web — the server clears
  /// browser cookies via Set-Cookie).
  Future<void> clearCookies();
}
