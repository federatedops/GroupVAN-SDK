/// JWT Authentication manager for GroupVAN SDK
/// 
/// Handles login, token refresh, logout, and automatic token management.
/// Follows industry best practices for secure token handling.
library auth_manager;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/exceptions.dart';
import '../core/http_client.dart';
import '../logging.dart';
import 'auth_models.dart';

/// Token storage interface for different storage backends
abstract class TokenStorage {
  /// Store tokens securely
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Retrieve stored tokens
  Future<Map<String, String?>> getTokens();

  /// Clear stored tokens
  Future<void> clearTokens();
}

/// In-memory token storage (not recommended for production)
class MemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<Map<String, String?>> getTokens() async {
    return {
      'accessToken': _accessToken,
      'refreshToken': _refreshToken,
    };
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

/// Secure token storage using flutter_secure_storage (recommended for production)
class SecureTokenStorage implements TokenStorage {
  static const String _accessTokenKey = 'groupvan_access_token';
  static const String _refreshTokenKey = 'groupvan_refresh_token';
  
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
  }) : _secureStorage = secureStorage ?? FlutterSecureStorage(
         aOptions: androidOptions ?? const AndroidOptions(
           encryptedSharedPreferences: true,
         ),
         iOptions: iosOptions ?? const IOSOptions(
           accessibility: KeychainAccessibility.first_unlock_this_device,
         ),
         lOptions: linuxOptions ?? const LinuxOptions(),
         wOptions: windowsOptions ?? const WindowsOptions(),
         webOptions: webOptions ?? const WebOptions(),
         mOptions: macOsOptions ?? const MacOsOptions(),
       );

  @override
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: accessToken),
        _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      ]);
    } catch (e) {
      throw ConfigurationException(
        'Failed to store tokens securely: $e',
        context: {'operation': 'storeTokens'},
      );
    }
  }

  @override
  Future<Map<String, String?>> getTokens() async {
    try {
      final results = await Future.wait([
        _secureStorage.read(key: _accessTokenKey),
        _secureStorage.read(key: _refreshTokenKey),
      ]);
      
      return {
        'accessToken': results[0],
        'refreshToken': results[1],
      };
    } catch (e) {
      throw ConfigurationException(
        'Failed to retrieve tokens from secure storage: $e',
        context: {'operation': 'getTokens'},
      );
    }
  }

  @override
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
      ]);
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
  Stream<AuthStatus> get statusStream => _statusController.stream;

  /// Current authentication status
  AuthStatus get currentStatus => _currentStatus;

  /// Whether currently authenticated with valid tokens
  bool get isAuthenticated => _currentStatus.isAuthenticated;

  /// Current access token (if authenticated)
  String? get accessToken => _currentStatus.accessToken;

  /// Current user ID from token claims
  String? get userId => _currentStatus.claims?.userId;

  /// Current developer ID from token claims
  String? get developerId => _currentStatus.claims?.developerId;

  AuthManager({
    required GroupVanHttpClient httpClient,
    TokenStorage? tokenStorage,
  })  : _httpClient = httpClient,
        _tokenStorage = tokenStorage ?? MemoryTokenStorage(),
        _statusController = StreamController<AuthStatus>.broadcast();

  /// Initialize authentication manager
  /// 
  /// Attempts to restore authentication state from stored tokens
  Future<void> initialize() async {
    try {
      final tokens = await _tokenStorage.getTokens();
      if (tokens['accessToken'] != null && tokens['refreshToken'] != null) {
        await _validateAndRestoreTokens(
          tokens['accessToken']!,
          tokens['refreshToken']!,
        );
      }
    } catch (e) {
      GroupVanLogger.auth.warning('Failed to restore authentication state: $e');
      await _updateStatus(const AuthStatus.unauthenticated());
    }
  }

  /// Authenticate with username and password
  Future<void> login({
    required String username,
    required String password,
    required String developerId,
  }) async {
    await _updateStatus(const AuthStatus.authenticating());

    try {
      final request = LoginRequest(
        username: username,
        password: password,
        developerId: developerId,
      );

      final response = await _httpClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      final tokenResponse = TokenResponse.fromJson(response.data);
      
      // Store tokens securely
      await _tokenStorage.storeTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );

      // Update authentication status
      final claims = _decodeToken(tokenResponse.accessToken);
      await _updateStatus(AuthStatus.authenticated(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        claims: claims,
      ));

      // Schedule automatic refresh
      _scheduleTokenRefresh(claims);

      GroupVanLogger.auth.info('Successfully authenticated user: ${claims.userId}');
    } catch (e) {
      final error = 'Login failed: ${e.toString()}';
      GroupVanLogger.auth.severe(error);
      await _updateStatus(AuthStatus.failed(error: error));
      rethrow;
    }
  }

  /// Refresh access token using refresh token
  Future<void> refreshToken() async {
    // Prevent concurrent refresh operations
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return;
    }

    _refreshCompleter = Completer<void>();

    try {
      final currentTokens = await _tokenStorage.getTokens();
      if (currentTokens['refreshToken'] == null) {
        throw AuthenticationException(
          'No refresh token available',
          errorType: AuthErrorType.missingToken,
        );
      }

      await _updateStatus(_currentStatus.copyWith(state: AuthState.refreshing));

      final request = RefreshTokenRequest(refreshToken: currentTokens['refreshToken']!);
      
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      final tokenResponse = TokenResponse.fromJson(response.data);
      
      // Store new tokens
      await _tokenStorage.storeTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );

      // Update authentication status
      final claims = _decodeToken(tokenResponse.accessToken);
      await _updateStatus(AuthStatus.authenticated(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        claims: claims,
      ));

      // Reschedule automatic refresh
      _scheduleTokenRefresh(claims);

      GroupVanLogger.auth.info('Successfully refreshed tokens');
      _refreshCompleter!.complete();
    } catch (e) {
      final error = 'Token refresh failed: ${e.toString()}';
      GroupVanLogger.auth.severe(error);
      
      // If refresh fails, mark as expired and clear tokens
      await _updateStatus(AuthStatus.expired(
        error: error,
        accessToken: _currentStatus.accessToken!,
        refreshToken: _currentStatus.refreshToken!,
        authenticatedAt: _currentStatus.authenticatedAt!,
        refreshedAt: _currentStatus.refreshedAt,
      ));
      await _tokenStorage.clearTokens();
      
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Logout and clear all authentication state
  Future<void> logout() async {
    try {
      final currentTokens = await _tokenStorage.getTokens();
      if (currentTokens['refreshToken'] != null) {
        // Notify server to blacklist tokens
        final request = LogoutRequest(refreshToken: currentTokens['refreshToken']!);
        await _httpClient.post<Map<String, dynamic>>(
          '/auth/logout',
          data: request.toJson(),
          decoder: (data) => data as Map<String, dynamic>,
        );
      }
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
  Future<void> _validateAndRestoreTokens(String accessToken, String refreshToken) async {
    try {
      final claims = _decodeToken(accessToken);
      
      // Check if token is expired
      if (claims.isExpired) {
        // Try to refresh
        await _tokenStorage.storeTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await this.refreshToken();
      } else {
        // Token is still valid
        await _updateStatus(AuthStatus.authenticated(
          accessToken: accessToken,
          refreshToken: refreshToken,
          claims: claims,
        ));
        _scheduleTokenRefresh(claims);
      }
    } catch (e) {
      GroupVanLogger.auth.warning('Token validation failed: $e');
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
    final refreshTime = claims.timeUntilExpiration - const Duration(minutes: 2);
    
    if (refreshTime.inMilliseconds > 0) {
      _refreshTimer = Timer(refreshTime, () async {
        try {
          await refreshToken();
        } catch (e) {
          GroupVanLogger.auth.severe('Automatic token refresh failed: $e');
        }
      });
      
      GroupVanLogger.auth.fine(
        'Scheduled token refresh in ${refreshTime.inMinutes} minutes'
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