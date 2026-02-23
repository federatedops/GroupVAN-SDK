/// JWT Authentication manager for GroupVAN SDK
///
/// Handles login, token refresh, logout, and automatic token management.
/// Follows industry best practices for secure token handling.
library auth_manager;

import 'dart:async';
import 'dart:convert';

import 'package:web/web.dart';
import 'package:dio/dio.dart' show Options;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/exceptions.dart';
import '../core/http_client.dart';
import '../logging.dart';
import 'auth_models.dart';
import '../models/auth.dart' show User;

/// Token storage interface for different storage backends
///
/// On web, only the access token is stored client-side.
/// The refresh token is managed by the browser via HttpOnly cookies.
abstract class TokenStorage {
  /// Store access token
  Future<void> storeTokens({required String accessToken});

  /// Retrieve stored access token
  Future<Map<String, String?>> getTokens();

  /// Clear stored tokens
  Future<void> clearTokens();
}

/// In-memory token storage (not recommended for production)
class MemoryTokenStorage implements TokenStorage {
  String? _accessToken;

  @override
  Future<void> storeTokens({required String accessToken}) async {
    _accessToken = accessToken;
  }

  @override
  Future<Map<String, String?>> getTokens() async {
    return {'accessToken': _accessToken};
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
  }
}

/// Web token storage — in-memory only
///
/// The refresh token is managed by the browser as an HttpOnly cookie.
/// The access token (returned in the API response body) is held in
/// memory only for the Authorization header during the current session.
/// Nothing is written to localStorage, sessionStorage, or any other
/// JS-accessible persistence.
class WebTokenStorage implements TokenStorage {
  String? _accessToken;

  @override
  Future<void> storeTokens({required String accessToken}) async {
    _accessToken = accessToken;
  }

  @override
  Future<Map<String, String?>> getTokens() async {
    return {'accessToken': _accessToken};
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
  }
}

/// Secure token storage using flutter_secure_storage (for mobile/desktop)
class SecureTokenStorage implements TokenStorage {
  static const String _accessTokenKey = 'groupvan_access_token';

  final FlutterSecureStorage _secureStorage;

  /// Create secure token storage with optional custom storage instance
  SecureTokenStorage({
    FlutterSecureStorage? secureStorage,
    AndroidOptions? androidOptions,
    IOSOptions? iosOptions,
    LinuxOptions? linuxOptions,
    WindowsOptions? windowsOptions,
    WebOptions? webOptions,
    MacOsOptions? macOsOptions,
  }) : _secureStorage =
           secureStorage ??
           FlutterSecureStorage(
             aOptions:
                 androidOptions ??
                 const AndroidOptions(encryptedSharedPreferences: true),
             iOptions:
                 iosOptions ??
                 const IOSOptions(
                   accessibility:
                       KeychainAccessibility.first_unlock_this_device,
                 ),
             lOptions: linuxOptions ?? const LinuxOptions(),
             wOptions: windowsOptions ?? const WindowsOptions(),
             webOptions:
                 webOptions ??
                 const WebOptions(
                   dbName: 'groupvan_tokens_db',
                   publicKey: 'groupvan_storage_key',
                 ),
             mOptions: macOsOptions ?? const MacOsOptions(),
           );

  /// Create platform-optimized secure token storage
  /// Automatically configures best options for each platform
  factory SecureTokenStorage.platformOptimized() {
    return SecureTokenStorage(
      androidOptions: const AndroidOptions(encryptedSharedPreferences: true),
      iosOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  @override
  Future<void> storeTokens({required String accessToken}) async {
    try {
      GroupVanLogger.auth.warning(
        'DEBUG: SecureTokenStorage - Attempting to write access token to secure storage...',
      );
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      GroupVanLogger.auth.warning(
        'DEBUG: SecureTokenStorage - Access token written to secure storage successfully',
      );
    } catch (e) {
      GroupVanLogger.auth.severe(
        'DEBUG: SecureTokenStorage - Failed to store access token: $e',
      );
      throw ConfigurationException(
        'Failed to store access token securely: $e',
        context: {'operation': 'storeTokens'},
      );
    }
  }

  @override
  Future<Map<String, String?>> getTokens() async {
    try {
      GroupVanLogger.auth.warning(
        'DEBUG: SecureTokenStorage - Attempting to read access token from secure storage...',
      );

      final accessToken = await _secureStorage.read(key: _accessTokenKey);

      GroupVanLogger.auth.warning(
        'DEBUG: SecureTokenStorage - Retrieved accessToken=${accessToken?.substring(0, 10) ?? 'null'}...',
      );

      return {'accessToken': accessToken};
    } catch (e) {
      GroupVanLogger.auth.severe(
        'DEBUG: SecureTokenStorage - Failed to retrieve access token: $e',
      );
      return {'accessToken': null};
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _accessTokenKey);
    } catch (e) {
      throw ConfigurationException(
        'Failed to clear tokens from secure storage: $e',
        context: {'operation': 'clearTokens'},
      );
    }
  }

  /// Delete all stored data (use with caution)
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw ConfigurationException(
        'Failed to delete all secure storage data: $e',
        context: {'operation': 'deleteAll'},
      );
    }
  }
}

/// JWT Authentication Manager
///
/// Handles all authentication operations including:
/// - Login with username/password
/// - Automatic token refresh
/// - Token validation and expiration handling
/// - Secure token storage
/// - Authentication state management
class AuthManager {
  final GroupVanHttpClient _httpClient;
  final TokenStorage _tokenStorage;
  final StreamController<AuthStatus> _statusController;

  /// Current authentication status
  AuthStatus _currentStatus = const AuthStatus.unauthenticated();

  /// Timer for automatic token refresh
  Timer? _refreshTimer;

  /// Completer for ongoing refresh operations
  Completer<void>? _refreshCompleter;

  /// Stream of authentication status changes
  Stream<AuthStatus> get statusStream => Stream<AuthStatus>.multi((multi) {
    // Immediately provide the current status to new subscribers
    multi.add(_currentStatus);
    // Then forward any subsequent updates
    final sub = _statusController.stream.listen(
      multi.add,
      onError: multi.addError,
      onDone: multi.close,
      cancelOnError: false,
    );
    // Ensure subscription is cancelled when the listener is done
    multi.onCancel = () => sub.cancel();
  });

  /// Current authentication status
  AuthStatus get currentStatus => _currentStatus;

  /// Whether currently authenticated with valid tokens
  bool get isAuthenticated => _currentStatus.isAuthenticated;

  /// Current access token (if authenticated)
  String? get accessToken => _currentStatus.accessToken;

  /// Current user ID from token claims
  String? get userId => _currentStatus.claims?.userId;

  AuthManager({
    required GroupVanHttpClient httpClient,
    TokenStorage? tokenStorage,
  }) : _httpClient = httpClient,
       _tokenStorage = tokenStorage ?? MemoryTokenStorage(),
       _statusController = StreamController<AuthStatus>.broadcast() {
    // Emit initial state immediately so StreamBuilder doesn't wait
    _statusController.add(_currentStatus);
  }

  /// Initialize authentication manager
  ///
  /// Attempts to restore authentication state from stored tokens
  /// Gracefully handles errors and continues with unauthenticated state
  Future<void> initialize(String clientId) async {
    GroupVanLogger.auth.warning(
      'DEBUG: Starting authentication initialization...',
    );

    try {
      GroupVanLogger.auth.warning(
        'DEBUG: Attempting to retrieve stored tokens...',
      );
      final tokens = await _tokenStorage.getTokens();

      GroupVanLogger.auth.warning(
        'DEBUG: Token retrieval result - accessToken: ${tokens['accessToken']?.substring(0, 10) ?? 'null'}...',
      );

      if (tokens['accessToken'] != null) {
        GroupVanLogger.auth.warning(
          'DEBUG: Access token found, attempting to validate and restore...',
        );
        await _validateAndRestoreTokens(tokens['accessToken']!);
        GroupVanLogger.auth.warning(
          'DEBUG: Token validation and restoration completed',
        );
      } else {
        // No stored tokens, start with unauthenticated state
        GroupVanLogger.auth.warning(
          'DEBUG: No stored access token found, setting unauthenticated state',
        );

        final uri = Uri.parse(window.location.href);
        final code = uri.queryParameters['code'];
        final state = uri.queryParameters['state'];
        final provider = uri.queryParameters['provider'];
        if (code != null && state != null && provider != null) {
          await _handleProviderCallback(provider, code, state, clientId);
        } else {
          await _updateStatus(const AuthStatus.unauthenticated());
        }
      }
    } on AuthenticationException catch (e) {
      if (e.errorType == AuthErrorType.accountNotLinked) {}
      await _updateStatus(const AuthStatus.unauthenticated());
    } catch (e) {
      // Log warning but don't throw - gracefully continue as unauthenticated
      GroupVanLogger.auth.warning(
        'DEBUG: Failed to restore authentication state: $e',
      );
      //GroupVanLogger.auth.warning('DEBUG: Stack trace: ${StackTrace.current}');
      await _updateStatus(const AuthStatus.unauthenticated());
    }

    GroupVanLogger.auth.warning(
      'DEBUG: Authentication initialization completed with status: ${_currentStatus.state}',
    );
  }

  Future<void> login({
    required String email,
    required String password,
    required String clientId,
  }) async {
    await _updateStatus(const AuthStatus.authenticating());

    try {
      final request = LoginRequest(email: email, password: password);

      final response = await _httpClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
        options: Options(headers: {'gv-client-id': clientId}),
      );

      final user = User.fromJson(response.data['user']);
      final tokenResponse = TokenResponse.fromJson(response.data);

      await _handleTokenResponse(tokenResponse, user: user);
    } catch (e) {
      final error = 'Login failed: ${e.toString()}';
      GroupVanLogger.auth.severe(error);
      await _updateStatus(AuthStatus.failed(error: error));
      rethrow;
    }
  }

  void loginWithGoogle() {
    window.location.href =
        '${_httpClient.baseUrl}/auth/google/login?catalog_uri=${_httpClient.origin}';
  }

  Future<void> _handleProviderCallback(
    String provider,
    String code,
    String state,
    String clientId,
  ) async {
    try {
      GroupVanLogger.auth.info('DEBUG: Handling provider callback: $provider');
      final response = await _httpClient.get<Map<String, dynamic>>(
        '/auth/$provider/callback?code=$code&state=$state&catalog_uri=${_httpClient.origin}',
        options: Options(headers: {'gv-client-id': clientId}),
      );
      final user = User.fromJson(response.data['user']);
      final tokenResponse = TokenResponse.fromJson(response.data);
      await _handleTokenResponse(tokenResponse, user: user);
    } on AuthenticationException catch (e) {
      if (e.errorType == AuthErrorType.accountNotLinked) {
        final metadata = e.context;
        metadata?['provider'] = provider;
        await _updateStatus(
          AuthStatus.failed(error: 'account_not_linked', metadata: metadata),
        );
        return;
      }
      rethrow;
    } catch (e) {
      GroupVanLogger.auth.severe('Failed to handle provider callback: $e');
      rethrow;
    }
  }

  Future<void> linkFedLinkAccount({
    required String email,
    required String username,
    required String password,
    required String clientId,
    bool fromProvider = false,
  }) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/auth/migrate/email',
        data: {
          'email': email,
          'username': username,
          'password': password,
          'from_provider': fromProvider,
        },
        options: Options(headers: {'gv-client-id': clientId}),
      );
      if (!response.data['success']) {
        throw AuthenticationException(
          response.data['message'],
          errorType: AuthErrorType.invalidCredentials,
        );
      }
    } catch (e) {
      GroupVanLogger.auth.severe('Failed to link FedLink account: $e');
      rethrow;
    }
  }

  Future<void> _handleTokenResponse(
    TokenResponse tokenResponse, {
    User? user,
  }) async {
    GroupVanLogger.auth.warning(
      'DEBUG: Storing access token after successful login...',
    );
    await _tokenStorage.storeTokens(accessToken: tokenResponse.accessToken);
    GroupVanLogger.auth.warning('DEBUG: Access token stored successfully');

    // Update authentication status
    final claims = _decodeToken(tokenResponse.accessToken);
    await _updateStatus(
      AuthStatus.authenticated(
        accessToken: tokenResponse.accessToken,
        claims: claims,
        userInfo: user ?? _currentStatus.userInfo,
      ),
    );
    // Schedule automatic refresh
    _scheduleTokenRefresh(claims);
    GroupVanLogger.auth.warning(
      'DEBUG: Successfully authenticated user: ${claims.userId}',
    );
  }

  /// Refresh access token
  ///
  /// On web, the browser automatically sends the refresh_token HttpOnly cookie.
  /// The server responds with a new access token (and updates the cookie).
  Future<void> refreshToken() async {
    // Prevent concurrent refresh operations
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return;
    }

    _refreshCompleter = Completer<void>();

    try {
      // POST with empty body — browser sends refresh_token cookie automatically
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        decoder: (data) => data as Map<String, dynamic>,
      );

      final user = User.fromJson(response.data['user']);
      final tokenResponse = TokenResponse.fromJson(response.data);

      await _handleTokenResponse(tokenResponse, user: user);

      GroupVanLogger.auth.info('Successfully refreshed access token');
      _refreshCompleter!.complete();
    } catch (e) {
      final error = 'Token refresh failed: ${e.toString()}';
      GroupVanLogger.auth.severe(error);

      // If refresh fails, mark as expired and clear tokens
      if (_currentStatus.accessToken != null &&
          _currentStatus.authenticatedAt != null) {
        await _updateStatus(
          AuthStatus.expired(
            error: error,
            accessToken: _currentStatus.accessToken!,
            authenticatedAt: _currentStatus.authenticatedAt!,
            refreshedAt: _currentStatus.refreshedAt,
          ),
        );
      }
      await _tokenStorage.clearTokens();

      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Logout and clear all authentication state
  ///
  /// Browser sends refresh_token cookie automatically.
  /// Server blacklists tokens and clears the cookie via Set-Cookie with max-age=0.
  Future<void> logout() async {
    try {
      final currentTokens = await _tokenStorage.getTokens();
      // POST with no body — browser sends refresh_token cookie automatically
      await _httpClient.post<Map<String, dynamic>>(
        '/auth/logout',
        decoder: (data) => data as Map<String, dynamic>,
        options: Options(
          headers: {
            if (currentTokens['accessToken'] != null)
              'Authorization': 'Bearer ${currentTokens['accessToken']}',
          },
        ),
      );
    } catch (e) {
      GroupVanLogger.auth.warning('Logout request failed: $e');
      // Continue with local cleanup even if server request fails
    }

    // Clear local state
    await _clearAuthenticationState();
    GroupVanLogger.auth.info('Successfully logged out');
  }

  /// Get current valid access token, refreshing if necessary
  Future<String> getValidAccessToken() async {
    // Check if we need to refresh the token
    if (_currentStatus.needsRefresh) {
      await refreshToken();
    }

    if (!isAuthenticated || _currentStatus.accessToken == null) {
      throw AuthenticationException(
        'No valid access token available',
        errorType: AuthErrorType.missingToken,
      );
    }

    return _currentStatus.accessToken!;
  }

  /// Validate and restore tokens from storage
  ///
  /// On web, only the access token is stored locally.
  /// Attempts a refresh to get a fresh access token (browser sends cookie).
  Future<void> _validateAndRestoreTokens(String accessToken) async {
    try {
      GroupVanLogger.auth.warning('DEBUG: Decoding access token...');
      final claims = _decodeToken(accessToken);

      GroupVanLogger.auth.warning(
        'DEBUG: Token claims - userId: ${claims.userId}, expiration: ${DateTime.fromMillisecondsSinceEpoch(claims.expiration * 1000)}, isExpired: ${claims.isExpired}',
      );

      await _tokenStorage.storeTokens(accessToken: accessToken);
      await this.refreshToken();
      GroupVanLogger.auth.warning('DEBUG: Token refresh completed');
    } catch (e) {
      GroupVanLogger.auth.warning('DEBUG: Token validation failed: $e');
      GroupVanLogger.auth.warning(
        'DEBUG: Clearing authentication state due to validation failure',
      );
      await _clearAuthenticationState();
    }
  }

  /// Decode JWT token claims
  TokenClaims _decodeToken(String token) {
    try {
      // JWT has format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException('Invalid JWT format');
      }

      // Decode the payload (second part)
      var payload = parts[1];

      // Add padding if needed for base64 decoding
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = base64.decode(payload);
      final jsonString = utf8.decode(decoded);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return TokenClaims.fromJson(jsonData);
    } catch (e) {
      throw DataException(
        'Failed to decode JWT token: ${e.toString()}',
        dataType: 'JWT',
        originalData: token,
      );
    }
  }

  /// Schedule automatic token refresh
  void _scheduleTokenRefresh(TokenClaims claims) {
    _refreshTimer?.cancel();

    // Schedule refresh 2 minutes before expiration
    final timeUntilExpiration = claims.timeUntilExpiration;
    const refreshBuffer = Duration(minutes: 2);
    final refreshTime = Duration(
      milliseconds:
          timeUntilExpiration.inMilliseconds - refreshBuffer.inMilliseconds,
    );
    if (refreshTime.inMilliseconds > 0) {
      _refreshTimer = Timer(refreshTime, () async {
        try {
          GroupVanLogger.auth.info('Attempting to refresh token');
          await refreshToken();
        } catch (e) {
          GroupVanLogger.auth.severe('Automatic token refresh failed: $e');
        }
      });

      GroupVanLogger.auth.fine(
        'Scheduled token refresh in ${refreshTime.inMinutes} minutes',
      );
    }
  }

  /// Update authentication status and notify listeners
  Future<void> _updateStatus(AuthStatus newStatus) async {
    _currentStatus = newStatus;
    _statusController.add(newStatus);
  }

  /// Clear all authentication state
  Future<void> _clearAuthenticationState() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _tokenStorage.clearTokens();
    await _updateStatus(const AuthStatus.unauthenticated());
  }

  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    _statusController.close();
  }
}
