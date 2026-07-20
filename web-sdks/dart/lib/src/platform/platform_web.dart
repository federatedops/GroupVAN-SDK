import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

import 'platform_interface.dart';

GroupVanPlatform createPlatform() => WebPlatform();

class WebPlatform implements GroupVanPlatform {
  @override
  String? get origin => web.window.location.origin;

  @override
  Uri? get currentUrl => Uri.parse(web.window.location.href);

  @override
  void redirect(String url) => web.window.location.href = url;

  @override
  void configureDioCredentials(Dio dio) {
    // Enable withCredentials so the browser includes HttpOnly cookies
    // (refresh_token, gv_session) in cross-origin requests to *.groupvan.com
    dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
  }

  @override
  Future<void> clearCookies() async {}
}
