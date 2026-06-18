/// GroupVAN SDK Client
///
/// Main client implementation with singleton pattern for global access.
/// Provides both direct client usage and elegant singleton initialization.
library client;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'auth/auth_manager.dart';
import 'auth/auth_models.dart' as auth_models;
import 'clients/cart_client.dart';
import 'clients/catalogs_client.dart';
import 'clients/reports_client.dart';
import 'clients/search_client.dart';
import 'clients/user_client.dart';
import 'clients/vehicles_client.dart';
import 'clients/websocket.dart';
import 'core/exceptions.dart';
import 'core/http_client.dart';
import 'core/response.dart';
import 'logging.dart';
import 'models/models.dart';

// Re-export the domain clients so consumers importing this file (and the
// `groupvan.dart` barrel) keep seeing them as before the split.
export 'clients/base_client.dart' show ApiClient;
export 'clients/cart_client.dart' show CartClient, GroupVANCart;
export 'clients/catalogs_client.dart' show CatalogsClient, GroupVANCatalogs;
export 'clients/reports_client.dart' show ReportsClient, GroupVANReports;
export 'clients/search_client.dart' show SearchClient, GroupVANSearch;
export 'clients/user_client.dart' show UserClient, GroupVANUser;
export 'clients/vehicles_client.dart' show VehiclesClient, GroupVANVehicles;
export 'clients/websocket.dart' show MultiplexedSocket;

/// Default API base URLs for each environment
class GroupVanDefaults {
  GroupVanDefaults._();

  /// Production API base URL
  static const String productionBaseUrl = 'https://api.groupvan.com';

  /// Staging API base URL
  static const String stagingBaseUrl = 'https://api.staging.groupvan.com';
}

/// Configuration for the GroupVAN SDK client
class GroupVanClientConfig {
  /// API base URL — single source of truth for all HTTP and WebSocket requests.
  /// Defaults to [GroupVanDefaults.stagingBaseUrl].
  /// Override at initialization to target any environment.
  final String baseUrl;

  /// HTTP client configuration (timeouts, retries, caching, headers).
  /// The [baseUrl] on this config is always kept in sync with [GroupVanClientConfig.baseUrl].
  final HttpClientConfig httpClientConfig;

  /// Token storage implementation
  final TokenStorage? tokenStorage;

  /// Client ID for this SDK instance
  final String? clientId;

  /// Enable automatic token refresh
  final bool autoRefreshTokens;

  /// Enable request/response logging
  final bool enableLogging;

  /// Enable caching
  final bool enableCaching;

  /// Use the SSO authentication flow (`/auth/sso/*`).
  ///
  /// When true, the Google OAuth callback is completed via SSO session
  /// exchange. Required for [GroupVANAuth.signInWithSso] /
  /// [GroupVANAuth.signInWithGoogleSso] / [GroupVANAuth.signOutSso].
  final bool useSso;

  GroupVanClientConfig({
    this.baseUrl = GroupVanDefaults.stagingBaseUrl,
    HttpClientConfig? httpClientConfig,
    this.tokenStorage,
    this.clientId,
    this.autoRefreshTokens = true,
    this.enableLogging = true,
    this.enableCaching = true,
    this.useSso = false,
  }) : httpClientConfig =
           httpClientConfig?.copyWith(baseUrl: baseUrl) ??
           HttpClientConfig(baseUrl: baseUrl);

  /// Create production configuration
  /// Uses WebTokenStorage on web, SecureTokenStorage on mobile/desktop
  factory GroupVanClientConfig.production({
    String? baseUrl,
    TokenStorage? tokenStorage,
    String? clientId,
    bool autoRefreshTokens = true,
    bool enableLogging = false,
    bool enableCaching = true,
    bool useSso = false,
  }) {
    return GroupVanClientConfig(
      baseUrl: baseUrl ?? GroupVanDefaults.productionBaseUrl,
      tokenStorage: tokenStorage ??
          (kIsWeb ? WebTokenStorage() : SecureTokenStorage.platformOptimized()),
      clientId: clientId,
      autoRefreshTokens: autoRefreshTokens,
      enableLogging: enableLogging,
      enableCaching: enableCaching,
      useSso: useSso,
    );
  }

  /// Create staging configuration
  /// Uses WebTokenStorage on web, SecureTokenStorage on mobile/desktop
  factory GroupVanClientConfig.staging({
    String? baseUrl,
    TokenStorage? tokenStorage,
    String? clientId,
    bool autoRefreshTokens = true,
    bool enableLogging = true,
    bool enableCaching = true,
    bool useSso = false,
  }) {
    return GroupVanClientConfig(
      baseUrl: baseUrl ?? GroupVanDefaults.stagingBaseUrl,
      tokenStorage: tokenStorage ??
          (kIsWeb ? WebTokenStorage() : SecureTokenStorage.platformOptimized()),
      clientId: clientId,
      autoRefreshTokens: autoRefreshTokens,
      enableLogging: enableLogging,
      enableCaching: enableCaching,
      useSso: useSso,
    );
  }
}

/// Main GroupVAN SDK Client
///
/// Provides a comprehensive, type-safe interface to the GroupVAN V3 API with:
/// - Automatic JWT authentication and token refresh
/// - Input validation and error handling
/// - Response caching and metadata
/// - Retry logic with exponential backoff
/// - Professional logging and debugging
class GroupVanClient {
  final GroupVanClientConfig _config;
  late final GroupVanHttpClient _httpClient;
  late final AuthManager _authManager;
  late final MultiplexedSocket _multiplexedSocket;
  late final VehiclesClient _vehiclesClient;
  late final CatalogsClient _catalogsClient;
  late final ReportsClient _reportsClient;
  late final SearchClient _searchClient;
  late final CartClient _cartClient;
  late final UserClient _userClient;

  GroupVanClient(this._config);

  /// HTTP client instance
  GroupVanHttpClient get httpClient => _httpClient;

  /// Authentication manager
  AuthManager get auth => _authManager;

  /// Vehicles API client
  VehiclesClient get vehicles => _vehiclesClient;

  /// Catalogs API client
  CatalogsClient get catalogs => _catalogsClient;

  /// Reports API client
  ReportsClient get reports => _reportsClient;

  /// Search API client
  SearchClient get search => _searchClient;

  /// Cart API client
  CartClient get cart => _cartClient;

  /// User API client
  UserClient get user => _userClient;

  /// Current authentication status
  auth_models.AuthStatus get authStatus => _authManager.currentStatus;

  /// Current user ID (if authenticated)
  String? get userId => _authManager.currentStatus.claims?.userId;

  /// Current client ID from configuration
  String? get clientId => _config.clientId;

  /// Initialize the client
  ///
  /// This sets up the HTTP client, authentication manager, and API clients.
  /// Must be called before using any API methods.
  Future<void> initialize() async {
    // Initialize logger first if logging is enabled
    if (_config.enableLogging) {
      GroupVanLogger.initialize(level: Level.ALL, enableConsoleOutput: true);
    }

    GroupVanLogger.sdk.warning(
      'DEBUG: Starting GroupVAN SDK Client initialization...',
    );
    GroupVanLogger.sdk.warning(
      'DEBUG: Token storage type: ${_config.tokenStorage.runtimeType}',
    );

    // Initialize HTTP client
    _httpClient = GroupVanHttpClient(_config.httpClientConfig);
    GroupVanLogger.sdk.warning('DEBUG: HTTP client initialized');

    // Initialize authentication manager
    _authManager = AuthManager(
      httpClient: _httpClient,
      tokenStorage: _config.tokenStorage,
      useSso: _config.useSso,
    );
    GroupVanLogger.sdk.warning('DEBUG: Authentication manager created');

    // Single multiplexed WebSocket shared by the streaming API clients.
    _multiplexedSocket = MultiplexedSocket(httpClient, _authManager);

    // Initialize API clients
    _vehiclesClient = VehiclesClient(httpClient, _authManager);
    _catalogsClient = CatalogsClient(httpClient, _authManager, _multiplexedSocket);
    _reportsClient = ReportsClient(httpClient, _authManager);
    _searchClient = SearchClient(httpClient, _authManager, _multiplexedSocket);
    _cartClient = CartClient(httpClient, _authManager);
    _userClient = UserClient(httpClient, _authManager);
    GroupVanLogger.sdk.warning('DEBUG: API clients initialized');

    // Initialize authentication manager (restore tokens if available)
    GroupVanLogger.sdk.warning('DEBUG: Calling auth manager initialize...');
    await _authManager.initialize(clientId!);
    GroupVanLogger.sdk.warning('DEBUG: Auth manager initialization completed');

    GroupVanLogger.sdk.info('GroupVAN SDK Client initialized');
  }

  /// Clean up resources
  void dispose() {
    _multiplexedSocket.dispose();
    _authManager.dispose();
    GroupVanLogger.sdk.info('GroupVAN SDK Client disposed');
  }

  /// Ensure we have a valid authentication token
  Future<String> getValidToken() async {
    if (!_authManager.currentStatus.isAuthenticated) {
      throw AuthenticationException(
        'Not authenticated. Please call auth.login() first.',
        errorType: AuthErrorType.missingToken,
      );
    }

    // The AuthManager automatically handles token refresh
    return _authManager.currentStatus.accessToken!;
  }

  /// Make an authenticated GET request
  Future<GroupVanResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
  }) async {
    await getValidToken(); // Ensure we have a valid token
    return await httpClient.get<T>(
      path,
      queryParameters: queryParameters,
      decoder: decoder,
    );
  }

  /// Make an authenticated POST request
  Future<GroupVanResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
  }) async {
    await getValidToken(); // Ensure we have a valid token
    return await httpClient.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
    );
  }

  /// Make an authenticated PATCH request
  Future<GroupVanResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
  }) async {
    await getValidToken(); // Ensure we have a valid token
    return await httpClient.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
    );
  }
}

/// Main GroupVAN SDK class with singleton pattern for global access
class GroupVAN {
  static GroupVAN? _instance;
  late final GroupVanClient _client;
  bool _isInitialized = false;

  GroupVAN._();

  /// Get the singleton instance
  ///
  /// Throws [StateError] if not initialized
  static GroupVAN get instance {
    if (_instance == null || !_instance!._isInitialized) {
      throw StateError(
        'GroupVAN must be initialized before use. Call GroupVAN.initialize() first.',
      );
    }
    return _instance!;
  }

  /// Initialize GroupVAN SDK
  ///
  /// This must be called before using any GroupVAN functionality.
  /// Returns the same instance on subsequent calls.
  static Future<GroupVAN> initialize({
    /// API base URL — override to target any environment.
    /// Defaults to production or staging URL based on [isProduction].
    String? baseUrl,

    /// Client ID for this SDK instance
    String? clientId,

    /// Enable request/response logging (default: false for production)
    bool? enableLogging,

    /// Enable response caching (default: true)
    bool? enableCaching,

    /// Enable automatic token refresh (default: true)
    bool? autoRefreshTokens,

    /// Custom token storage implementation
    TokenStorage? tokenStorage,

    /// HTTP client configuration (baseUrl will be overridden by [baseUrl] if both provided)
    HttpClientConfig? httpClientConfig,

    /// Whether this is a production environment
    bool isProduction = true,

    /// Use the SSO authentication flow (`/auth/sso/*`). Required for
    /// [GroupVANAuth.signInWithSso] / [GroupVANAuth.signInWithGoogleSso] /
    /// [GroupVANAuth.signOutSso].
    bool useSso = false,
  }) async {
    // Return existing instance if already initialized
    if (_instance?._isInitialized == true) {
      return _instance!;
    }

    _instance = GroupVAN._();

    // Create configuration based on environment, passing baseUrl through
    // so the factory + constructor keep httpClientConfig.baseUrl in sync.
    final config = isProduction
        ? GroupVanClientConfig.production(
            baseUrl: baseUrl,
            tokenStorage: tokenStorage,
            clientId: clientId,
            autoRefreshTokens: autoRefreshTokens ?? true,
            enableLogging: enableLogging ?? false,
            enableCaching: enableCaching ?? true,
            useSso: useSso,
          )
        : GroupVanClientConfig.staging(
            baseUrl: baseUrl,
            tokenStorage: tokenStorage,
            clientId: clientId,
            autoRefreshTokens: autoRefreshTokens ?? true,
            enableLogging: enableLogging ?? true,
            enableCaching: enableCaching ?? true,
            useSso: useSso,
          );

    // Initialize client
    _instance!._client = GroupVanClient(config);
    await _instance!._client.initialize();
    _instance!._isInitialized = true;

    GroupVanLogger.sdk.info('GroupVAN SDK initialized successfully');
    return _instance!;
  }

  /// Convenient client access for extraction (like Supabase pattern)
  GroupVANClient get client => GroupVANClient._(_client);

  /// Quick access to authentication (deprecated - use client.auth instead)
  GroupVANAuth get auth => GroupVANAuth._(_client.auth, _client);

  /// Quick access to vehicles API (deprecated - use client.vehicles instead)
  GroupVANVehicles get vehicles => GroupVANVehicles(_client.vehicles);

  /// Quick access to catalogs API (deprecated - use client.catalogs instead)
  GroupVANCatalogs get catalogs => GroupVANCatalogs(_client.catalogs);

  /// Quick access to cart API (deprecated - use client.cart instead)
  GroupVANCart get cart => GroupVANCart(_client.cart);

  /// Quick access to reports API (deprecated - use client.reports instead)
  GroupVANReports get reports => GroupVANReports(_client.reports);

  /// Quick access to search API (deprecated - use client.search instead)
  GroupVANSearch get search => GroupVANSearch(_client.search);

  /// Quick access to user API (deprecated - use client.user instead)
  GroupVANUser get user => GroupVANUser(_client.user);

  /// Check if SDK is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose the SDK and clean up resources
  static Future<void> dispose() async {
    if (_instance?._isInitialized == true) {
      _instance!._client.dispose();
      _instance!._isInitialized = false;
    }
    _instance = null;
  }
}

/// Namespaced authentication methods with clean API design
class GroupVANAuth {
  final AuthManager _authManager;
  final GroupVanClient _client;

  const GroupVANAuth._(this._authManager, this._client);

  /// Authenticate with an externally-minted access token (e.g. a Service Pro
  /// catalog "punchout" token from a trusted server-side exchange).
  ///
  /// Marks the session authenticated without a cookie-based refresh; see
  /// [AuthManager.setSession]. Returns the resulting auth status.
  Future<auth_models.AuthStatus> setSession({
    required String accessToken,
  }) async {
    await _authManager.setSession(accessToken: accessToken);
    return _authManager.currentStatus;
  }

  /// Sign in with username and password
  Future<auth_models.AuthStatus> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final clientId = _client.clientId;
    if (clientId == null) {
      throw StateError(
        'Client ID not configured. Please initialize GroupVAN SDK with a clientId.',
      );
    }

    await _authManager.login(
      email: email,
      password: password,
      clientId: clientId,
    );
    return _authManager.currentStatus;
  }

  /// Sign in with OTP (Future implementation)
  Future<auth_models.AuthStatus> signInWithOtp({
    String? email,
    String? phone,
    required String clientId,
  }) async {
    // TODO: Implement OTP authentication
    throw UnimplementedError(
      'OTP authentication will be implemented in future versions',
    );
  }

  /// Sign in with Apple ID (Future implementation)
  Future<auth_models.AuthStatus> signInWithApple({
    required String clientId,
  }) async {
    // TODO: Implement Apple Sign-In
    throw UnimplementedError(
      'Apple Sign-In will be implemented in future versions',
    );
  }

  /// Sign in with Google (Future implementation)
  void signInWithGoogle() {
    _authManager.loginWithGoogle();
  }

  /// Sign in via SSO with email and password.
  ///
  /// Establishes a shared SSO session in addition to this client's tokens,
  /// enabling single sign-on and cascade logout across GroupVAN clients.
  /// Requires the SDK to be initialized with `useSso: true`.
  Future<auth_models.AuthStatus> signInWithSso({
    required String email,
    required String password,
  }) async {
    final clientId = _client.clientId;
    if (clientId == null) {
      throw StateError(
        'Client ID not configured. Please initialize GroupVAN SDK with a clientId.',
      );
    }

    await _authManager.ssoLogin(
      email: email,
      password: password,
      clientId: clientId,
    );
    return _authManager.currentStatus;
  }

  /// Begin the SSO Google sign-in flow (browser redirect).
  ///
  /// On return, the SDK completes the flow by exchanging the SSO session for
  /// this client's tokens. Requires the SDK to be initialized with
  /// `useSso: true`.
  void signInWithGoogleSso() {
    _authManager.ssoLoginWithGoogle();
  }

  Future<auth_models.AuthStatus> linkFedLinkAccount({
    required String email,
    required String username,
    required String password,
  }) async {
    final clientId = _client.clientId;
    if (clientId == null) {
      throw StateError(
        'Client ID not configured. Please initialize GroupVAN SDK with a clientId.',
      );
    }
    await _authManager.linkFedLinkAccount(
      clientId: clientId,
      email: email,
      username: username,
      password: password,
    );
    return _authManager.currentStatus;
  }

  Future<auth_models.AuthStatus> linkFedLinkAccountWithProvider({
    required String username,
    required String password,
  }) async {
    final clientId = _client.clientId;
    if (clientId == null) {
      throw StateError(
        'Client ID not configured. Please initialize GroupVAN SDK with a clientId.',
      );
    }
    final metadata = _authManager.currentStatus.metadata;
    final provider = metadata?['provider'];
    final email = metadata?['email'];
    if (provider == null || email == null) {
      return _authManager.currentStatus;
    }

    await _authManager.linkFedLinkAccount(
      email: email,
      username: username,
      password: password,
      clientId: clientId,
      fromProvider: true,
    );

    switch (provider) {
      case 'google':
        _authManager.loginWithGoogle();
        break;
      default:
        throw Exception('Provider not supported');
    }

    return _authManager.currentStatus;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _authManager.logout();
  }

  /// Sign out of the SSO session.
  ///
  /// Cascades the logout across all GroupVAN clients sharing the SSO session.
  Future<void> signOutSso() async {
    await _authManager.ssoLogout();
  }

  /// Refresh the current session
  Future<auth_models.AuthStatus> refreshSession() async {
    await _authManager.refreshToken();
    return _authManager.currentStatus;
  }

  /// Get current user information
  User? get currentUser {
    final status = _authManager.currentStatus;
    if (!status.isAuthenticated) {
      return null;
    }

    return status.userInfo;
  }

  /// Stream of authentication state changes
  Stream<AuthState> get onAuthStateChange {
    // The underlying statusStream now emits the current auth status immediately
    // to new subscribers, so listeners receive an initial value without waiting.
    return _authManager.statusStream.map(
      (status) => AuthState._fromStatus(status, clientId: _client.clientId),
    );
  }

  /// Current authentication session
  AuthSession? get currentSession {
    final status = _authManager.currentStatus;
    if (!status.isAuthenticated) return null;

    return AuthSession.fromAuthStatus(status, clientId: _client.clientId);
  }
}

/// Convenient client interface for extraction and reuse (like Supabase pattern)
@immutable
class GroupVANClient {
  final GroupVanClient _client;

  const GroupVANClient._(this._client);

  /// Authentication methods
  GroupVANAuth get auth => GroupVANAuth._(_client.auth, _client);

  /// Vehicle operations
  GroupVANVehicles get vehicles => GroupVANVehicles(_client.vehicles);

  /// Catalog operations
  GroupVANCatalogs get catalogs => GroupVANCatalogs(_client.catalogs);

  /// Cart operations
  GroupVANCart get cart => GroupVANCart(_client.cart);

  /// Reports operations
  GroupVANReports get reports => GroupVANReports(_client.reports);

  /// Search operations
  GroupVANSearch get search => GroupVANSearch(_client.search);

  /// User operations
  GroupVANUser get user => GroupVANUser(_client.user);
}

/// Authentication user information
@immutable
class AuthUser {
  final String userId;
  final String? clientId;
  final String? member;

  const AuthUser({required this.userId, this.clientId, this.member});

  factory AuthUser.fromClaims(
    auth_models.TokenClaims claims, {
    String? clientId,
  }) => AuthUser(
    userId: claims.userId,
    clientId: clientId,
    member: claims.member,
  );

  @override
  String toString() => 'AuthUser(userId: $userId, clientId: $clientId)';
}

/// Authentication session information
///
/// Note: refreshToken is no longer exposed. It is managed by the browser
/// via HttpOnly cookies on web platforms.
@immutable
class AuthSession {
  final String accessToken;
  final DateTime? expiresAt;
  final User user;

  const AuthSession({
    required this.accessToken,
    this.expiresAt,
    required this.user,
  });

  factory AuthSession.fromAuthStatus(
    auth_models.AuthStatus status, {
    String? clientId,
  }) => AuthSession(
    accessToken: status.accessToken!,
    expiresAt: status.claims != null
        ? DateTime.fromMillisecondsSinceEpoch(status.claims!.expiration * 1000)
        : null,
    user: status.userInfo!,
  );

  /// Whether the session is expired
  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;

  @override
  String toString() => 'AuthSession(user: ${user.id}, expiresAt: $expiresAt)';
}

/// Authentication state change events
enum AuthChangeEvent {
  signedIn,
  signedOut,
  tokenRefreshed,
  error,
  passwordRecovery,
}

/// Authentication state for stream listening
@immutable
class AuthState {
  final AuthChangeEvent event;
  final User? user;
  final AuthSession? session;
  final String? error;
  final Map<String, dynamic>? errorDetails;

  const AuthState._(
    this.event,
    this.user,
    this.session, {
    this.error,
    this.errorDetails,
  });

  factory AuthState._fromStatus(
    auth_models.AuthStatus status, {
    String? clientId,
  }) {
    User? user;
    AuthSession? session;

    if (status.isAuthenticated && status.userInfo != null) {
      user = status.userInfo;
      session = AuthSession.fromAuthStatus(status, clientId: clientId);
    }

    AuthChangeEvent event;
    switch (status.state) {
      case auth_models.AuthState.authenticated:
        event = AuthChangeEvent.signedIn;
        break;
      case auth_models.AuthState.unauthenticated:
        event = AuthChangeEvent.signedOut;
        break;
      case auth_models.AuthState.refreshing:
        event = AuthChangeEvent.tokenRefreshed;
        break;
      case auth_models.AuthState.failed:
        event = AuthChangeEvent.error;
        break;
      default:
        event = AuthChangeEvent.signedOut;
    }

    return AuthState._(
      event,
      user,
      session,
      error: status.error,
      errorDetails: status.metadata,
    );
  }

  @override
  String toString() => 'AuthState(event: $event, user: $user, error: $error)';
}
