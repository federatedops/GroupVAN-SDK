import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' show CancelToken, Options;
import 'package:flutter_test/flutter_test.dart';
import 'package:groupvan/src/auth/auth_manager.dart';
import 'package:groupvan/src/auth/auth_models.dart';
import 'package:groupvan/src/core/exceptions.dart';
import 'package:groupvan/src/core/http_client.dart';
import 'package:groupvan/src/core/response.dart';

const _clientId = 'client-1';

/// Answers each path from [routes]; a throwing route simulates an error.
class FakeHttpClient implements GroupVanHttpClient {
  final routes = <String, FutureOr<Map<String, dynamic>> Function()>{};
  final calls = <String>[];
  final clientIdHeaders = <String, Object?>{};

  @override
  Future<GroupVanResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? decoder,
  }) async {
    calls.add(path);
    clientIdHeaders[path] = options?.headers?['gv-client-id'];
    final route = routes[path];
    if (route == null) throw StateError('Unexpected request to $path');
    final body = await route();
    final now = DateTime.now();
    return GroupVanResponse<T>(
      data: decoder != null ? decoder(body) : body as T,
      statusCode: 200,
      headers: const {},
      requestMetadata: RequestMetadata(
        method: 'POST',
        url: path,
        headers: const {},
        timestamp: now,
        timeout: Duration.zero,
        correlationId: 'test',
      ),
      responseMetadata: ResponseMetadata(
        timestamp: now,
        duration: Duration.zero,
        correlationId: 'test',
      ),
    );
  }

  @override
  void updateAuthToken(String? token) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _jwt(String jti, Duration expiresIn, {bool impersonation = false}) {
  String encode(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final claims = {
    'sub': '42',
    'iat': now,
    'exp': now + expiresIn.inSeconds,
    'jti': jti,
    if (impersonation) 'impersonation': true,
    if (impersonation) 'impersonator_id': '7',
  };
  return '${encode({'alg': 'none'})}.${encode(claims)}.sig';
}

Map<String, dynamic> _tokenBody(String accessToken) => {
  'access_token': accessToken,
  'expires_in': 3600,
  'token_type': 'Bearer',
  'user': {
    'id': 42,
    'email': 'user@example.com',
    'name': 'Test User',
    'created_at': '2026-01-01T00:00:00Z',
    'roles': <String>[],
    'has_identifix_access': false,
  },
};

Never _unauthorized(String endpoint) => throw AuthenticationException(
  '$endpoint rejected',
  errorType: AuthErrorType.invalidToken,
);

/// A signed-in [AuthManager] plus everything it emits and schedules afterwards.
class _Harness {
  final http = FakeHttpClient();
  final storage = MemoryTokenStorage();
  final statuses = <AuthStatus>[];
  final timers = <(Duration, Timer)>[];
  late final AuthManager auth;
  late final String initialToken;
  StreamSubscription<AuthStatus>? _sub;

  static Future<_Harness> signedIn({
    required bool useSso,
    bool impersonation = false,
  }) async {
    final h = _Harness();
    h.auth = AuthManager(
      httpClient: h.http,
      tokenStorage: h.storage,
      useSso: useSso,
    );
    h.initialToken = _jwt(
      'initial',
      const Duration(hours: 1),
      impersonation: impersonation,
    );
    h.http.routes['/auth/refresh'] = () => _tokenBody(h.initialToken);
    await h.run(() => h.auth.initialize(_clientId));
    expect(h.auth.accessToken, h.initialToken);

    h.http.calls.clear();
    h._sub = h.auth.statusStream.skip(1).listen(h.statuses.add);
    return h;
  }

  /// Runs [body] recording every timer it creates.
  Future<T> run<T>(Future<T> Function() body) => runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, f) {
        final timer = parent.createTimer(zone, duration, f);
        timers.add((duration, timer));
        return timer;
      },
    ),
  );

  Future<void> dispose() async {
    await _sub?.cancel();
    auth.dispose();
  }
}

void main() {
  group('AuthManager.refreshToken', () {
    late _Harness h;

    tearDown(() => h.dispose());

    test(
      'with SSO, falls back to the SSO exchange when the refresh is rejected',
      () async {
        h = await _Harness.signedIn(useSso: true);
        final ssoToken = _jwt('sso', const Duration(minutes: 30));
        h.http.routes['/auth/refresh'] = () => _unauthorized('refresh');
        h.http.routes['/auth/sso/exchange'] = () => _tokenBody(ssoToken);

        await h.run(() => h.auth.refreshToken());
        await pumpEventQueue();

        expect(h.http.calls, ['/auth/refresh', '/auth/sso/exchange']);
        expect(h.http.clientIdHeaders['/auth/sso/exchange'], _clientId);
        expect(h.auth.accessToken, ssoToken);
        expect((await h.storage.getTokens())['accessToken'], ssoToken);
        // Straight to the new session: no authenticating (signedOut) or failed.
        expect(h.statuses.map((s) => s.state), [AuthState.authenticated]);
        expect(h.statuses.single.accessToken, ssoToken);

        // The initial session's timer is replaced by one for the new token.
        expect(h.timers, hasLength(2));
        final (initialDelay, initialTimer) = h.timers.first;
        final (ssoDelay, ssoTimer) = h.timers.last;
        expect(initialDelay, greaterThan(const Duration(minutes: 57)));
        expect(initialTimer.isActive, isFalse);
        expect(ssoDelay, greaterThan(const Duration(minutes: 27)));
        expect(ssoDelay, lessThanOrEqualTo(const Duration(minutes: 28)));
        expect(ssoTimer.isActive, isTrue);
      },
    );

    test(
      'with SSO, fails exactly as before when the exchange also fails',
      () async {
        h = await _Harness.signedIn(useSso: true);
        final before = h.auth.currentStatus;
        h.http.routes['/auth/refresh'] = () => _unauthorized('refresh');
        h.http.routes['/auth/sso/exchange'] = () => _unauthorized('exchange');

        await expectLater(
          h.auth.refreshToken(),
          throwsA(
            isA<AuthenticationException>().having(
              (e) => e.message,
              'message',
              'refresh rejected',
            ),
          ),
        );
        await pumpEventQueue();

        expect(h.http.calls, ['/auth/refresh', '/auth/sso/exchange']);
        expect(h.statuses.map((s) => s.state), [AuthState.expired]);
        final expired = h.statuses.single;
        expect(expired.accessToken, before.accessToken);
        expect(expired.authenticatedAt, before.authenticatedAt);
        expect(expired.error, contains('Token refresh failed'));
        expect(expired.error, contains('refresh rejected'));
        expect((await h.storage.getTokens())['accessToken'], isNull);
      },
    );

    test('without SSO, a rejected refresh does not try the exchange', () async {
      h = await _Harness.signedIn(useSso: false);
      h.http.routes['/auth/refresh'] = () => _unauthorized('refresh');
      h.http.routes['/auth/sso/exchange'] = () =>
          _tokenBody(_jwt('sso', const Duration(minutes: 30)));

      await expectLater(
        h.auth.refreshToken(),
        throwsA(isA<AuthenticationException>()),
      );
      await pumpEventQueue();

      expect(h.http.calls, ['/auth/refresh']);
      expect(h.statuses.map((s) => s.state), [AuthState.expired]);
      expect((await h.storage.getTokens())['accessToken'], isNull);
    });

    test(
      'with SSO, an impersonated session is not swapped for the actor\'s',
      () async {
        h = await _Harness.signedIn(useSso: true, impersonation: true);
        h.http.routes['/auth/refresh'] = () => _unauthorized('refresh');
        h.http.routes['/auth/sso/exchange'] = () =>
            _tokenBody(_jwt('sso', const Duration(minutes: 30)));

        await expectLater(
          h.auth.refreshToken(),
          throwsA(isA<AuthenticationException>()),
        );
        await pumpEventQueue();

        expect(h.http.calls, ['/auth/refresh']);
        expect(h.statuses.map((s) => s.state), [AuthState.expired]);
      },
    );

    test('concurrent callers share one refresh and one exchange', () async {
      h = await _Harness.signedIn(useSso: true);
      final ssoToken = _jwt('sso', const Duration(minutes: 30));
      final release = Completer<void>();
      h.http.routes['/auth/refresh'] = () async {
        await release.future;
        _unauthorized('refresh');
      };
      h.http.routes['/auth/sso/exchange'] = () => _tokenBody(ssoToken);

      final first = h.auth.refreshToken();
      final second = h.auth.refreshToken();
      await pumpEventQueue();
      release.complete();
      await Future.wait([first, second]);
      await pumpEventQueue();

      expect(h.http.calls, ['/auth/refresh', '/auth/sso/exchange']);
      expect(h.auth.accessToken, ssoToken);
      expect(h.statuses.map((s) => s.state), [AuthState.authenticated]);
    });
  });

  group('AuthManager.initialize', () {
    test(
      'with SSO, a rejected refresh runs the SSO exchange once, as before',
      () async {
        final http = FakeHttpClient();
        final auth = AuthManager(httpClient: http, useSso: true);
        final statuses = <AuthStatus>[];
        final sub = auth.statusStream.skip(1).listen(statuses.add);
        final ssoToken = _jwt('sso', const Duration(minutes: 30));
        http.routes['/auth/refresh'] = () => _unauthorized('refresh');
        http.routes['/auth/sso/exchange'] = () => _tokenBody(ssoToken);

        await auth.initialize(_clientId);
        await pumpEventQueue();

        expect(http.calls, ['/auth/refresh', '/auth/sso/exchange']);
        expect(auth.accessToken, ssoToken);
        expect(statuses.map((s) => s.state), [
          AuthState.authenticating,
          AuthState.authenticated,
        ]);

        await sub.cancel();
        auth.dispose();
      },
    );
  });
}
