/// GroupVAN SDK Client
///
/// Main client implementation with singleton pattern for global access.
/// Provides both direct client usage and elegant singleton initialization.
library client;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth/auth_manager.dart';
import 'auth/auth_models.dart' as auth_models;
import 'core/exceptions.dart';
import 'core/http_client.dart';
import 'core/response.dart';
import 'core/validation.dart';
import 'logging.dart';
import 'models/models.dart';

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

  GroupVanClientConfig({
    this.baseUrl = GroupVanDefaults.stagingBaseUrl,
    HttpClientConfig? httpClientConfig,
    this.tokenStorage,
    this.clientId,
    this.autoRefreshTokens = true,
    this.enableLogging = true,
    this.enableCaching = true,
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
  }) {
    return GroupVanClientConfig(
      baseUrl: baseUrl ?? GroupVanDefaults.productionBaseUrl,
      tokenStorage: tokenStorage ??
          (kIsWeb ? WebTokenStorage() : SecureTokenStorage.platformOptimized()),
      clientId: clientId,
      autoRefreshTokens: autoRefreshTokens,
      enableLogging: enableLogging,
      enableCaching: enableCaching,
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
  }) {
    return GroupVanClientConfig(
      baseUrl: baseUrl ?? GroupVanDefaults.stagingBaseUrl,
      tokenStorage: tokenStorage ??
          (kIsWeb ? WebTokenStorage() : SecureTokenStorage.platformOptimized()),
      clientId: clientId,
      autoRefreshTokens: autoRefreshTokens,
      enableLogging: enableLogging,
      enableCaching: enableCaching,
    );
  }
}

/// Apply asset data from a WebSocket message to a list of parts.
void _applyAssets(List<Part> parts, Map<String, dynamic> assets) {
  for (final part in parts) {
    final assetData = assets[part.id.toString()];
    if (assetData != null) {
      part.assets = Asset.fromJson(assetData as Map<String, dynamic>);
    }
  }
}

/// Apply pricing data from a WebSocket message to a list of parts.
/// Also extracts alternates (status_code 2), supercessions (status_code 3),
/// and equivalents (status_code 4) and nests them under their
/// original part matched by original_mfr + original_part.
///
/// When [isPrimary] is true, the pricing fields (comment, descriptions, etc.)
/// are used to build the part's pricing model — any locations accumulated from
/// earlier non-primary messages are preserved. When false, only locations are
/// appended to the existing pricing.
void _applyPricing(List<Part> parts, Map<String, dynamic> pricing, {required bool isPrimary}) {
  final partLookup = <String, Part>{};
  for (final part in parts) {
    partLookup['${part.mfrCode}_${part.partNumber}'] = part;
    final pricingData = pricing[part.id.toString()];
    if (pricingData != null) {
      final newPricing = ItemPricing.fromJson(pricingData as Map<String, dynamic>);
      if (isPrimary) {
        // Primary response owns the part-level fields; keep any locations
        // that arrived from earlier non-primary messages.
        if (part.pricing != null) {
          newPricing.locations.addAll(part.pricing!.locations);
        }
        part.pricing = newPricing;
      } else {
        if (part.pricing != null) {
          part.pricing!.locations.addAll(newPricing.locations);
        } else {
          // Primary hasn't arrived yet — store a blank shell with just locations.
          part.pricing = ItemPricing(
            comment: '',
            id: newPricing.id,
            locations: newPricing.locations,
            mfrCode: '',
            mfrDescription: '',
            partDescription: '',
            partNumber: '',
            statusCode: newPricing.statusCode,
          );
        }
      }
    }
  }
  for (final entry in pricing.entries) {
    final item = entry.value as Map<String, dynamic>;
    final statusCode = item['status_code'];
    if (statusCode == null ||
        statusCode == 1 ||
        item['original_part'] == null ||
        item['original_mfr'] == null) continue;
    final parentPart = partLookup['${item['original_mfr']}_${item['original_part']}'];
    if (parentPart == null) continue;

    // Select the correct list based on status_code
    final List<Part> targetList;
    switch (statusCode) {
      case 2:
        targetList = parentPart.alternates;
        break;
      case 3:
        targetList = parentPart.supercessions;
        break;
      case 4:
        targetList = parentPart.equivalents;
        break;
      default:
        continue;
    }

    final existing = targetList.where(
      (p) => p.mfrCode == item['mfr_code'] && p.partNumber == item['part_number'],
    );
    final newPricing = ItemPricing.fromJson(item);
    if (existing.isEmpty) {
      final pricing = isPrimary
          ? newPricing
          : ItemPricing(
              comment: '',
              id: newPricing.id,
              locations: newPricing.locations,
              mfrCode: '',
              mfrDescription: '',
              partDescription: '',
              partNumber: '',
              statusCode: newPricing.statusCode,
            );
      targetList.add(Part(
        id: 0,
        itemType: parentPart.itemType,
        sku: 0,
        rank: 0,
        tier: 0,
        mfrCode: item['mfr_code'],
        mfrName: '',
        partNumber: item['part_number'],
        buyersGuide: false,
        primaryImageExists: false,
        secondaryImageExists: false,
        documentExists: false,
        spinExists: false,
        attributeExists: false,
        interchange: false,
        applications: [],
        pricing: pricing,
      ));
    } else {
      final p = existing.first;
      if (isPrimary) {
        if (p.pricing != null) {
          newPricing.locations.addAll(p.pricing!.locations);
        }
        p.pricing = newPricing;
      } else {
        if (p.pricing != null) {
          p.pricing!.locations.addAll(newPricing.locations);
        } else {
          p.pricing = ItemPricing(
            comment: '',
            id: newPricing.id,
            locations: newPricing.locations,
            mfrCode: '',
            mfrDescription: '',
            partDescription: '',
            partNumber: '',
            statusCode: newPricing.statusCode,
          );
        }
      }
    }
  }
}

/// Apply equivalents data from a WebSocket message to a list of parts.
void _applyEquivalents(List<Part> parts, Map<String, dynamic> equivalents) {
  for (final part in parts) {
    final eqList = equivalents[part.id.toString()];
    if (eqList == null) continue;
    for (final eq in eqList) {
      part.equivalents.add(Part(
        id: 0,
        itemType: part.itemType,
        sku: 0,
        rank: 0,
        tier: 0,
        mfrCode: eq['mfr_code'],
        mfrName: '',
        partNumber: eq['part_number'],
        buyersGuide: false,
        primaryImageExists: false,
        secondaryImageExists: false,
        documentExists: false,
        spinExists: false,
        attributeExists: false,
        interchange: false,
        applications: [],
      ));
    }
  }
}

/// Apply equivalent pricing data from a WebSocket message to a list of parts.
void _applyEquivalentPricing(List<Part> parts, Map<String, dynamic> eqPricing) {
  for (final part in parts) {
    for (final eq in part.equivalents) {
      final pricingData = eqPricing['${eq.mfrCode}_${eq.partNumber}'];
      if (pricingData != null) {
        eq.pricing = ItemPricing.fromJson(pricingData as Map<String, dynamic>);
      }
    }
  }
}

/// Single persistent WebSocket to `/v3/ws/stream` that multiplexes every
/// streaming feature (omni search, products search, products listing).
///
/// - Lazy-connects on first [ensureConnected].
/// - Authenticates via a first-frame `{type: auth, token}` and waits for
///   `{type: auth_ok}` before releasing queued sends.
/// - Re-authenticates in-band on [AuthManager] token rotation, so the
///   10-minute JWT never forces a reconnect.
/// - Dispatches inbound frames to a registered handler per logical stream.
class MultiplexedSocket {
  static const _authTimeout = Duration(seconds: 10);

  final GroupVanHttpClient _httpClient;
  final AuthManager _authManager;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  StreamSubscription<auth_models.AuthStatus>? _authSub;
  Completer<void>? _authReady;
  String? _authedToken;

  final Map<String, void Function(Map<String, dynamic>)> _handlers = {};

  MultiplexedSocket(this._httpClient, this._authManager) {
    _authSub = _authManager.statusStream.listen((status) {
      final token = status.accessToken;
      if (_channel == null || token == null || token == _authedToken) return;
      _sendRaw({'type': 're_auth', 'token': token});
      _authedToken = token;
    });
  }

  /// Register a handler for a logical stream type (e.g. `omni_search`).
  /// The handler is invoked for every inbound frame whose top-level keys
  /// match that stream type. Only one handler per type is active at a time.
  void registerHandler(
    String streamType,
    void Function(Map<String, dynamic>) handler,
  ) {
    _handlers[streamType] = handler;
  }

  void unregisterHandler(String streamType) {
    _handlers.remove(streamType);
  }

  /// Send a request frame. Ensures the socket is connected and authenticated
  /// before the payload goes out.
  Future<void> send(String type, Map<String, dynamic> payload) async {
    await ensureConnected();
    _sendRaw({'type': type, 'payload': payload});
  }

  /// Open and authenticate the socket if it isn't already. Safe to call
  /// repeatedly — subsequent calls return the cached ready future.
  Future<void> ensureConnected() async {
    if (_channel != null && _authReady != null) {
      return _authReady!.future;
    }

    final token = _authManager.currentStatus.accessToken;
    if (token == null) {
      throw AuthenticationException(
        'Not authenticated. Please call auth.login() first.',
        errorType: AuthErrorType.missingToken,
      );
    }

    final baseUri = Uri.parse(_httpClient.baseUrl);
    final wsUri = Uri(
      scheme: baseUri.scheme == 'http' ? 'ws' : 'wss',
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '/v3/ws/stream',
    );

    final channel = WebSocketChannel.connect(wsUri);
    _channel = channel;
    _authReady = Completer<void>();

    _channelSub = channel.stream.listen(
      _onMessage,
      onError: _onChannelError,
      onDone: _onChannelDone,
    );

    _sendRaw({'type': 'auth', 'token': token});
    _authedToken = token;

    return _authReady!.future.timeout(
      _authTimeout,
      onTimeout: () {
        final err = NetworkException(
          'Timed out waiting for WebSocket auth_ok frame.',
        );
        _failAndReset(err);
        throw err;
      },
    );
  }

  void _sendRaw(Map<String, dynamic> frame) {
    _channel?.sink.add(jsonEncode(frame));
  }

  void _onMessage(dynamic message) {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(message as String) as Map<String, dynamic>;
    } catch (e) {
      GroupVanLogger.sdk.severe('Failed to decode multiplex frame: $e');
      return;
    }

    final type = data['type'];

    if (type == 'auth_ok') {
      if (!(_authReady?.isCompleted ?? true)) _authReady!.complete();
      return;
    }

    if (data.containsKey('error')) {
      _failAndReset(_exceptionFromErrorFrame(data));
      return;
    }

    for (final key in data.keys) {
      final handler = _handlerForKey(key);
      if (handler != null) {
        handler(data);
        return;
      }
    }
  }

  void Function(Map<String, dynamic>)? _handlerForKey(String key) {
    const omniKeys = {
      'member_categories',
      'part_types',
      'catalog_parts',
      'member_parts',
      'vehicles',
    };
    const productsSearchKeys = {'products'};
    const productsListingKeys = {'product_listings'};
    const sharedKeys = {'assets', 'pricing', 'equivalents', 'equivalent_pricing'};

    if (omniKeys.contains(key)) return _handlers['omni_search'];
    if (productsSearchKeys.contains(key)) return _handlers['products_search'];
    if (productsListingKeys.contains(key)) return _handlers['products_listing'];
    if (sharedKeys.contains(key)) {
      return _handlers['products_search'] ??
          _handlers['products_listing'] ??
          _handlers['omni_search'];
    }
    return null;
  }

  GroupVanException _exceptionFromErrorFrame(Map<String, dynamic> data) {
    final title = (data['error'] ?? '').toString();
    final detail = (data['detail'] ?? '').toString();
    final message = detail.isEmpty ? title : '$title: $detail';
    final lower = title.toLowerCase();
    if (lower.contains('token')) {
      final isExpired = lower.contains('expired');
      return AuthenticationException(
        message,
        errorType: isExpired
            ? AuthErrorType.expiredToken
            : AuthErrorType.invalidToken,
      );
    }
    return NetworkException('WebSocket error: $message');
  }

  void _onChannelError(Object error) {
    _failAndReset(error);
  }

  void _onChannelDone() {
    final closeCode = _channel?.closeCode;
    final closeReason = _channel?.closeReason ?? '';
    final Object error;
    if (closeCode == 1011 && closeReason.toLowerCase().contains('expired')) {
      error = AuthenticationException(
        'WebSocket closed by server: $closeReason',
        errorType: AuthErrorType.expiredToken,
      );
    } else {
      error = NetworkException(
        'WebSocket closed by server.'
        '${closeCode != null ? ' (code: $closeCode)' : ''}'
        '${closeReason.isNotEmpty ? ' $closeReason' : ''}',
      );
    }
    _failAndReset(error);
  }

  void _failAndReset(Object error) {
    _tearDown();
    if (error is AuthenticationException &&
        error.errorType == AuthErrorType.expiredToken) {
      // Don't fan the expired-token error out yet — try to refresh the
      // access token and reconnect silently. Handlers only see an error if
      // the refresh itself fails.
      unawaited(_recoverFromExpiredToken(error));
      return;
    }
    _surfaceError(error);
  }

  void _tearDown() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;
    _authReady = null;
    _authedToken = null;
  }

  void _surfaceError(Object error) {
    if (!(_authReady?.isCompleted ?? true)) {
      _authReady!.completeError(error);
    }
    for (final handler in _handlers.values) {
      try {
        handler({'__error': error});
      } catch (_) {}
    }
  }

  Future<void> _recoverFromExpiredToken(
    AuthenticationException original,
  ) async {
    try {
      await _authManager.refreshToken();
    } catch (_) {
      _surfaceError(original);
      return;
    }
    if (_handlers.isEmpty) {
      // No one is listening — don't eagerly reopen the socket. It will
      // lazily reconnect on the next send() via ensureConnected().
      return;
    }
    try {
      await ensureConnected();
    } catch (e) {
      _surfaceError(e);
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
    await _channelSub?.cancel();
    _channelSub = null;
    await _channel?.sink.close();
    _channel = null;
    _authReady = null;
    _handlers.clear();
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

/// Base API client with common functionality
abstract class ApiClient {
  final GroupVanHttpClient httpClient;
  final AuthManager authManager;

  const ApiClient(this.httpClient, this.authManager);

  /// Make an authenticated GET request
  Future<GroupVanResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
    Options? options,
  }) async {
    // Merge headers from options with auth header
    final headers = <String, dynamic>{
      'Authorization': 'Bearer ${authManager.currentStatus.accessToken}',
      ...?options?.headers,
    };

    return await httpClient.get<T>(
      path,
      queryParameters: queryParameters,
      decoder: decoder,
      options: Options(
        headers: headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        maxRedirects: options?.maxRedirects,
        persistentConnection: options?.persistentConnection,
        requestEncoder: options?.requestEncoder,
        responseDecoder: options?.responseDecoder,
        responseType: options?.responseType,
        validateStatus: options?.validateStatus,
      ),
    );
  }

  /// Make an authenticated POST request
  Future<GroupVanResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
    Options? options,
  }) async {
    // Merge headers from options with auth header
    final headers = <String, dynamic>{
      'Authorization': 'Bearer ${authManager.currentStatus.accessToken}',
      ...?options?.headers,
    };

    return await httpClient.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
      options: Options(
        headers: headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        maxRedirects: options?.maxRedirects,
        persistentConnection: options?.persistentConnection,
        requestEncoder: options?.requestEncoder,
        responseDecoder: options?.responseDecoder,
        responseType: options?.responseType,
        validateStatus: options?.validateStatus,
      ),
    );
  }

  /// Make an authenticated PATCH request
  Future<GroupVanResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
    Options? options,
  }) async {
    // Merge headers from options with auth header
    final headers = <String, dynamic>{
      'Authorization': 'Bearer ${authManager.currentStatus.accessToken}',
      ...?options?.headers,
    };

    return await httpClient.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
      options: Options(
        headers: headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        maxRedirects: options?.maxRedirects,
        persistentConnection: options?.persistentConnection,
        requestEncoder: options?.requestEncoder,
        responseDecoder: options?.responseDecoder,
        responseType: options?.responseType,
        validateStatus: options?.validateStatus,
      ),
    );
  }

  /// Make an authenticated DELETE request
  Future<GroupVanResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
    Options? options,
  }) async {
    final headers = <String, dynamic>{
      'Authorization': 'Bearer ${authManager.currentStatus.accessToken}',
      ...?options?.headers,
    };

    return await httpClient.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      decoder: decoder,
      options: Options(
        headers: headers,
        method: options?.method,
        sendTimeout: options?.sendTimeout,
        receiveTimeout: options?.receiveTimeout,
        extra: options?.extra,
        followRedirects: options?.followRedirects,
        maxRedirects: options?.maxRedirects,
        persistentConnection: options?.persistentConnection,
        requestEncoder: options?.requestEncoder,
        responseDecoder: options?.responseDecoder,
        responseType: options?.responseType,
        validateStatus: options?.validateStatus,
      ),
    );
  }
}

/// Vehicles API client with comprehensive vehicle management
class VehiclesClient extends ApiClient {
  const VehiclesClient(super.httpClient, super.authManager);

  /// Get vehicle groups with validation
  Future<Result<List<VehicleGroup>>> getVehicleGroups() async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/groups',
        decoder: (data) => data as List<dynamic>,
      );

      final groups = response.data
          .map((item) => VehicleGroup.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(groups);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get vehicle groups: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get vehicle groups: $e'),
      );
    }
  }

  /// Get user vehicles with pagination and validation
  Future<Result<List<Vehicle>>> getUserVehicles({
    int offset = 0,
    int limit = 20,
  }) async {
    // Validate pagination parameters
    try {
      GroupVanValidators.paginationOffset().validateAndThrow(offset, 'offset');
      GroupVanValidators.paginationLimit().validateAndThrow(limit, 'limit');
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/user',
        queryParameters: {'offset': offset, 'limit': limit},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get user vehicles: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get user vehicles: $e'),
      );
    }
  }

  /// Search vehicles with comprehensive validation
  Future<Result<VehicleSearchResponse>> searchVehicles({
    required String query,
    int? groupId,
    int page = 1,
  }) async {
    // Validate search parameters
    try {
      GroupVanValidators.searchQuery().validateAndThrow(query, 'query');
      if (page < 1) {
        throw ValidationException(
          'Page must be greater than 0',
          errors: [
            ValidationError(
              field: 'page',
              message: 'Page must be greater than 0',
              value: page,
              rule: 'min',
            ),
          ],
        );
      }
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final queryParams = <String, dynamic>{'query': query, 'page': page};

      if (groupId != null) {
        queryParams['group_id'] = groupId;
      }

      final response = await get<Map<String, dynamic>>(
        '/v3/vehicles/search',
        queryParameters: queryParams,
        decoder: (data) => data as Map<String, dynamic>,
      );

      final searchResponse = VehicleSearchResponse.fromJson(response.data);
      return Success(searchResponse);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Vehicle search failed: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Vehicle search failed: $e'),
      );
    }
  }

  /// Search by VIN with validation
  Future<Result<Vehicle?>> searchByVin(String vin) async {
    // Validate VIN format
    try {
      GroupVanValidators.vin().validateAndThrow(vin, 'vin');
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/vin',
        queryParameters: {'vin': vin},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles.firstOrNull);
    } catch (e) {
      GroupVanLogger.vehicles.severe('VIN search failed: $e');
      return Failure(
        e is GroupVanException ? e : NetworkException('VIN search failed: $e'),
      );
    }
  }

  /// Search by license plate with validation
  Future<Result<List<Vehicle>>> searchByPlate({
    required String plate,
    required String state,
  }) async {
    // Validate license plate parameters
    try {
      GroupVanValidators.licensePlate().validateAndThrow(plate, 'plate');
      GroupVanValidators.usState().validateAndThrow(state, 'state');
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/plate',
        queryParameters: {'plate': plate, 'state': state},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('License plate search failed: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('License plate search failed: $e'),
      );
    }
  }

  /// Filter vehicles with validation
  Future<Result<VehicleFilterResponse>> filterVehicles({
    required VehicleFilterRequest request,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/vehicles/filter',
        queryParameters: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      final filterResponse = VehicleFilterResponse.fromJson(response.data);
      return Success(filterResponse);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Vehicle filtering failed: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Vehicle filtering failed: $e'),
      );
    }
  }

  /// Get engine data with validation
  Future<Result<List<Vehicle>>> getEngines({
    required EngineSearchRequest request,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/engines',
        queryParameters: request.toJson(),
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get engine data: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get engine data: $e'),
      );
    }
  }

  /// Get user fleets
  Future<Result<List<Fleet>>> getFleets() async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/fleets',
        decoder: (data) => data as List<dynamic>,
      );

      final fleets = response.data
          .map((item) => Fleet.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(fleets);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get fleets: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get fleets: $e'),
      );
    }
  }

  /// Get fleet vehicles with validation
  Future<Result<List<Vehicle>>> getFleetVehicles({required int fleetId}) async {
    // Validate fleet ID
    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/fleets/$fleetId',
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get fleet vehicles: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get fleet vehicles: $e'),
      );
    }
  }

  /// Get account vehicles with pagination and validation
  Future<Result<List<Vehicle>>> getAccountVehicles({
    int offset = 0,
    int limit = 20,
  }) async {
    // Validate pagination parameters
    try {
      GroupVanValidators.paginationOffset().validateAndThrow(offset, 'offset');
      GroupVanValidators.paginationLimit().validateAndThrow(limit, 'limit');
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/account',
        queryParameters: {'offset': offset, 'limit': limit},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get account vehicles: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get account vehicles: $e'),
      );
    }
  }

  /// Get previously selected part types for a vehicle
  Future<Result<List<PartType>>> getPreviousPartTypes({
    required int vehicleIndex,
  }) async {

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/$vehicleIndex/part_types',
        decoder: (data) => data as List<dynamic>,
      );

      final partTypes = response.data
          .map((item) => PartType.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(partTypes);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get previous part types: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get previous part types: $e'),
      );
    }
  }

  /// Get vehicle swap data including compatible years and engines
  Future<Result<VehicleSwapResponse>> getSwapData({
    required VehicleSwapRequest request,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/vehicles/swap',
        queryParameters: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(VehicleSwapResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get vehicle swap data: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get vehicle swap data: $e'),
      );
    }
  }
}

/// Catalogs API client with comprehensive catalog management
class CatalogsClient extends ApiClient {
  final MultiplexedSocket _socket;

  CatalogsClient(super.httpClient, super.authManager, this._socket);

  /// Start a catalog products-listing session over the shared multiplex socket.
  ProductsListingSession startProductsListingSession() =>
      ProductsListingSession(_socket);

  /// Get available catalogs
  Future<Result<List<Catalog>>> getCatalogs() async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/list',
        decoder: (data) => data as List<dynamic>,
      );

      final catalogs = response.data
          .map((item) => Catalog.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(catalogs);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get catalogs: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get catalogs: $e'),
      );
    }
  }

  /// Get vehicle categories with validation
  Future<Result<List<VehicleCategory>>> getVehicleCategories({
    required int catalogId,
    required int engineIndex,
    bool? disableFilters,
  }) async {
    final queryParams = <String, dynamic>{};
    if (disableFilters != null) {
      queryParams['disable_filters'] = disableFilters;
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/$catalogId/vehicle/$engineIndex/categories',
        queryParameters: queryParams,
        decoder: (data) => data as List<dynamic>,
      );

      final categories = response.data
          .map((item) => VehicleCategory.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(categories);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get vehicle categories: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get vehicle categories: $e'),
      );
    }
  }

  /// Get supply categories with validation
  Future<Result<List<SupplyCategory>>> getSupplyCategories({
    required int catalogId,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/$catalogId/categories',
        decoder: (data) => data as List<dynamic>,
      );

      final categories = response.data
          .map((item) => SupplyCategory.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(categories);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get supply categories: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get supply categories: $e'),
      );
    }
  }

  /// Get application assets with validation
  Future<Result<List<ApplicationAsset>>> getApplicationAssets({
    required List<int> applicationIds,
    String? languageCode,
  }) async {
    // Validate application IDs
    try {
      if (applicationIds.isEmpty) {
        throw ValidationException(
          'Application IDs cannot be empty',
          errors: [
            ValidationError(
              field: 'application_ids',
              message: 'Application IDs cannot be empty',
              value: applicationIds,
              rule: 'required',
            ),
          ],
        );
      }
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final queryParams = <String, dynamic>{
        'application_ids': applicationIds.join(','),
      };

      if (languageCode != null) {
        queryParams['language_code'] = languageCode;
      }

      final response = await get<List<dynamic>>(
        '/v3/catalogs/application_assets',
        queryParameters: queryParams,
        decoder: (data) => data as List<dynamic>,
      );

      final assets = response.data
          .map(
            (item) => ApplicationAsset.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      return Success(assets);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get application assets: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get application assets: $e'),
      );
    }
  }

  Future<Result<List<Asset>>> getProductAssets({
    List<int>? catalogSkus,
    List<int>? memberSkus,
    bool primaryOnly = true,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catalogs/products/assets',
        data: {'catalog_skus': catalogSkus, 'member_skus': memberSkus, 'primary_only': primaryOnly},
      );
      final catalogAssets = response.data['catalog_assets'] as List<dynamic>;
      final assets = catalogAssets
          .map((item) => Asset.fromJson(item as Map<String, dynamic>))
          .toList();
      return Success(assets);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get product assets: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get product assets: $e'),
      );
    }
  }

  Future<Result<Interchange>> getInterchanges({
    required String partNumber,
    List<String>? brands,
    List<int>? partTypes,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catalogs/interchange',
        data: {
          'part_number': partNumber,
          'brands': brands,
          'part_types': partTypes,
        },
      );
      return Success(Interchange.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get interchange: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get interchange: $e'),
      );
    }
  }

  Future<Result<List<ItemPricing>>> getProductPricing({
    required ProductPricingRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/json/federated/v3_2/item_inquiry',
        data: {
          'items': request.products.asMap().entries.map((entry) => {
            'id': entry.key.toString(),
            'mfr_code': entry.value.mfrCode,
            'part_number': entry.value.partNumber,
          }).toList(),
        },
      );

      final items = (response.data['items'] as List<dynamic>)
          .map((item) => ItemPricing.fromJson(item as Map<String, dynamic>))
          .toList();
      return Success(items);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get product pricing: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get product pricing: $e'),
      );
    }
  }

  Future<Result<ProductInfoResponse>> getProductInfo({required int sku}) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/catalogs/product/info',
        queryParameters: {'sku': sku},
      );
      return Success(ProductInfoResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get product info: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get product info: $e'),
      );
    }
  }

  /// Get Identifix URL
  Future<Result<String>> getIdentifixUrl({required int vehicleIndex}) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/catalogs/identifix',
        queryParameters: {'vehicle_index': vehicleIndex},
        decoder: (data) => data as Map<String, dynamic>,
      );

      final url = response.data['identifix_login_url'];
      if (url is! String) {
        return Failure(
          NetworkException(
            'Invalid response format: identifix_login_url is not a string',
          ),
        );
      }
      return Success(url);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get Identifix URL: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get Identifix URL: $e'),
      );
    }
  }

  /// Get buyers guide for a part
  Future<Result<BuyersGuideResponse>> getBuyersGuide({
    required BuyersGuideRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catalogs/buyers_guide',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(BuyersGuideResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get buyers guide: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get buyers guide: $e'),
      );
    }
  }

  /// Get flat buyers guide for a part
  Future<Result<FlatBuyersGuideResponse>> getFlatBuyersGuide({
    required FlatBuyersGuideRequest request,
  }) async {
    try {
      final response = await post<List<dynamic>>(
        '/v3/catalogs/buyers_guide/flat',
        data: request.toJson(),
        decoder: (data) => data as List<dynamic>,
      );

      return Success(FlatBuyersGuideResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get flat buyers guide: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get flat buyers guide: $e'),
      );
    }
  }

  /// Get invoices via the v3.2 gateway
  Future<Result<InvoiceResponse>> getInvoices({
    required InvoiceRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/json/federated/v3_2/invoice',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(InvoiceResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get invoices: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get invoices: $e'),
      );
    }
  }

  /// Get statements via the v3.2 gateway
  Future<Result<StatementResponse>> getStatements({
    required StatementRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/json/federated/v3_2/statement',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(StatementResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get statements: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get statements: $e'),
      );
    }
  }

  /// Get PDF bytes from a link URL
  Future<Result<List<int>>> getPdfBytes({required String linkUrl}) async {
    try {
      final response = await get<List<dynamic>>(
        '/internal/catalog/pdf_bytes',
        queryParameters: {'link_url': linkUrl},
        decoder: (data) => data as List<dynamic>,
      );

      final bytes = response.data.cast<int>();
      return Success(bytes);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get PDF bytes: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get PDF bytes: $e'),
      );
    }
  }
}

/// Cart API client for cart item management
class CartClient extends ApiClient {

  const CartClient(super.httpClient, super.authManager);

  /// Add items to cart
  Future<Result<CartResponse>> addToCart({
    required AddToCartRequest request,
  }) async {

    try {
      final response = await patch<Map<String, dynamic>>(
        '/v3/cart/items/add',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(CartResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.cart.severe('Failed to add items to cart: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to add items to cart: $e'),
      );
    }
  }

  /// Remove items from cart
  Future<Result<CartResponse>> removeFromCart({
    required RemoveFromCartRequest request,
  }) async {

    try {
      final response = await patch<Map<String, dynamic>>(
        '/v3/cart/items/remove',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(CartResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.cart.severe('Failed to remove items from cart: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to remove items from cart: $e'),
      );
    }
  }

  /// Checkout a cart, placing orders for all items
  Future<Result<CheckoutResponse>> checkout({
    required CheckoutRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/cart/checkout',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(CheckoutResponse.fromJson(response.data, response.statusCode));
    } catch (e) {
      GroupVanLogger.cart.severe('Failed to checkout cart: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to checkout cart: $e'),
      );
    }
  }
}

class ReportsClient extends ApiClient {
  const ReportsClient(super.httpClient, super.authManager);

  Future<Result<void>> createReport({
    required Uint8List screenshot,
    String? message,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'screenshot': MultipartFile.fromBytes(
          screenshot,
          filename: 'screenshot.png',
        ),
        'message': message,
      });

      await post('/v3/reports/', data: formData);
      return const Success(null);
    } catch (e) {
      GroupVanLogger.reports.severe('Failed to create report: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to create report: $e'),
      );
    }
  }
}

class OmniSearchSession {
  static const _streamType = 'omni_search';

  final MultiplexedSocket _socket;
  final StreamController<OmniSearchResponse> _streamController;
  OmniSearchResponse _currentResponse;

  OmniSearchSession(this._socket)
    : _streamController = StreamController<OmniSearchResponse>.broadcast(),
      _currentResponse = OmniSearchResponse(
        partTypes: [],
        catalogParts: [],
        memberParts: [],
        vehicles: [],
        memberCategories: [],
      ) {
    _socket.registerHandler(_streamType, _handleFrame);
  }

  void _handleFrame(Map<String, dynamic> data) {
    if (data.containsKey('__error')) {
      _streamController.addError(data['__error'] as Object);
      return;
    }

    bool updated = false;

    if (data.containsKey('part_types')) {
      _currentResponse.partTypes.addAll(
        (data['part_types'] as List)
            .map((e) => PartType.fromJson(e as Map<String, dynamic>)),
      );
      updated = true;
    }
    if (data.containsKey('catalog_parts')) {
      _currentResponse.catalogParts.addAll(
        (data['catalog_parts'] as List)
            .map((e) => Part.fromJson(e as Map<String, dynamic>)),
      );
      updated = true;
    }
    if (data.containsKey('member_parts')) {
      _currentResponse.memberParts.addAll(
        (data['member_parts'] as List)
            .map((e) => Part.fromJson(e as Map<String, dynamic>)),
      );
      updated = true;
    }
    if (data.containsKey('vehicles')) {
      _currentResponse.vehicles.addAll(
        (data['vehicles'] as List)
            .map((e) => VehicleAndPartType.fromJson(e as Map<String, dynamic>)),
      );
      updated = true;
    }
    if (data.containsKey('member_categories')) {
      _currentResponse.memberCategories.addAll(
        (data['member_categories'] as List)
            .map((e) => MemberCategory.fromJson(e as Map<String, dynamic>)),
      );
      updated = true;
    }

    if (updated) _streamController.add(_currentResponse);
  }

  Stream<OmniSearchResponse> get stream => _streamController.stream;

  Future<void> search({
    required String query,
    int? vehicleIndex,
    bool? disableFilters,
  }) async {
    _currentResponse = OmniSearchResponse(
      partTypes: [],
      catalogParts: [],
      memberParts: [],
      vehicles: [],
      memberCategories: [],
    );
    _streamController.add(_currentResponse);

    final payload = <String, dynamic>{'query': query};
    if (vehicleIndex != null) payload['vehicle_index'] = vehicleIndex;
    if (disableFilters != null) payload['disable_filters'] = disableFilters;

    try {
      await _socket.send(_streamType, payload);
    } catch (e) {
      _streamController.addError(e);
    }
  }

  void dispose() {
    _socket.unregisterHandler(_streamType);
    _streamController.close();
  }
}

/// Session for streaming product search results. Fire [search] to issue a
/// query; results arrive on [stream]. Pricing is the last frame emitted
/// per request — callers can treat its arrival as "results complete."
class ProductsSearchSession {
  static const _streamType = 'products_search';

  final MultiplexedSocket _socket;
  final StreamController<List<Part>> _streamController;
  List<Part> _products;

  ProductsSearchSession(this._socket)
    : _streamController = StreamController<List<Part>>.broadcast(),
      _products = <Part>[] {
    _socket.registerHandler(_streamType, _handleFrame);
  }

  void _handleFrame(Map<String, dynamic> data) {
    if (data.containsKey('__error')) {
      _streamController.addError(data['__error'] as Object);
      return;
    }

    if (data.containsKey('products')) {
      for (final product in data['products']) {
        _products.add(Part.fromJson(product as Map<String, dynamic>));
      }
    } else if (data.containsKey('assets')) {
      _applyAssets(_products, data['assets'] as Map<String, dynamic>);
    } else if (data.containsKey('pricing')) {
      _applyPricing(
        _products,
        data['pricing'] as Map<String, dynamic>,
        isPrimary: data['is_primary'] == true,
      );
    } else if (data.containsKey('equivalents')) {
      _applyEquivalents(_products, data['equivalents'] as Map<String, dynamic>);
    } else if (data.containsKey('equivalent_pricing')) {
      _applyEquivalentPricing(
        _products,
        data['equivalent_pricing'] as Map<String, dynamic>,
      );
    }

    _streamController.add(_products);
  }

  Stream<List<Part>> get stream => _streamController.stream;

  Future<void> search({
    required String query,
    bool? disableFilters,
  }) async {
    _products = <Part>[];
    _streamController.add(_products);

    final payload = <String, dynamic>{'query': query};
    if (disableFilters != null) payload['disable_filters'] = disableFilters;

    try {
      await _socket.send(_streamType, payload);
    } catch (e) {
      _streamController.addError(e);
    }
  }

  void dispose() {
    _socket.unregisterHandler(_streamType);
    _streamController.close();
  }
}

/// Session for streaming catalog product listings. Fire [fetch] with a
/// [ProductListingRequest]; results arrive on [stream].
class ProductsListingSession {
  static const _streamType = 'products_listing';

  final MultiplexedSocket _socket;
  final StreamController<List<ProductListing>> _streamController;
  List<ProductListing> _listings;

  ProductsListingSession(this._socket)
    : _streamController = StreamController<List<ProductListing>>.broadcast(),
      _listings = <ProductListing>[] {
    _socket.registerHandler(_streamType, _handleFrame);
  }

  void _handleFrame(Map<String, dynamic> data) {
    if (data.containsKey('__error')) {
      _streamController.addError(data['__error'] as Object);
      return;
    }

    if (data.containsKey('product_listings')) {
      for (final listing in data['product_listings']) {
        _listings.add(
          ProductListing.fromJson(listing as Map<String, dynamic>),
        );
      }
    } else {
      final allParts = _listings.expand((l) => l.parts).toList();
      if (data.containsKey('assets')) {
        _applyAssets(allParts, data['assets'] as Map<String, dynamic>);
      } else if (data.containsKey('pricing')) {
        _applyPricing(
          allParts,
          data['pricing'] as Map<String, dynamic>,
          isPrimary: data['is_primary'] == true,
        );
      } else if (data.containsKey('equivalents')) {
        _applyEquivalents(allParts, data['equivalents'] as Map<String, dynamic>);
      } else if (data.containsKey('equivalent_pricing')) {
        _applyEquivalentPricing(
          allParts,
          data['equivalent_pricing'] as Map<String, dynamic>,
        );
      }
    }

    _streamController.add(_listings);
  }

  Stream<List<ProductListing>> get stream => _streamController.stream;

  Future<void> fetch({required ProductListingRequest request}) async {
    _listings = <ProductListing>[];
    _streamController.add(_listings);

    try {
      await _socket.send(_streamType, request.toJson());
    } catch (e) {
      _streamController.addError(e);
    }
  }

  void dispose() {
    _socket.unregisterHandler(_streamType);
    _streamController.close();
  }
}

/// Search API client for omni search functionality
class SearchClient extends ApiClient {
  final MultiplexedSocket _socket;

  SearchClient(super.httpClient, super.authManager, this._socket);

  /// Start a persistent omni search session over the shared multiplex socket.
  OmniSearchSession startOmniSearchSession() => OmniSearchSession(_socket);

  /// Start a products search session over the shared multiplex socket.
  ProductsSearchSession startProductsSearchSession() =>
      ProductsSearchSession(_socket);

  /// Get VIN data
  Future<Result<List<Map<String, String>>>> vinData(String vin) async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/search/vin',
        queryParameters: {'vin': vin},
        decoder: (data) => data as List<dynamic>,
      );

      final vinData = response.data
          .map((item) {
            final map = item as Map<String, dynamic>;
            return {
              'display': map['display']?.toString() ?? '',
              'value': map['value']?.toString() ?? '',
            };
          })
          .toList();

      return Success(vinData);
    } catch (e) {
      GroupVanLogger.sdk.severe('VIN data search failed: $e');
      return Failure(
        e is GroupVanException ? e : NetworkException('VIN data search failed: $e'),
      );
    }
  }

}

/// User API client
class UserClient extends ApiClient {
  const UserClient(super.httpClient, super.authManager);

  /// Get location details
  Future<Result<LocationDetails>> getLocationDetails(String locationId) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/user/$locationId/details',
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(LocationDetails.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.sdk.severe('Failed to get location details: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get location details: $e'),
      );
    }
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
          )
        : GroupVanClientConfig.staging(
            baseUrl: baseUrl,
            tokenStorage: tokenStorage,
            clientId: clientId,
            autoRefreshTokens: autoRefreshTokens ?? true,
            enableLogging: enableLogging ?? true,
            enableCaching: enableCaching ?? true,
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
  GroupVANVehicles get vehicles => GroupVANVehicles._(_client.vehicles);

  /// Quick access to catalogs API (deprecated - use client.catalogs instead)
  GroupVANCatalogs get catalogs => GroupVANCatalogs._(_client.catalogs);

  /// Quick access to cart API (deprecated - use client.cart instead)
  GroupVANCart get cart => GroupVANCart._(_client.cart);

  /// Quick access to reports API (deprecated - use client.reports instead)
  GroupVANReports get reports => GroupVANReports._(_client.reports);

  /// Quick access to search API (deprecated - use client.search instead)
  GroupVANSearch get search => GroupVANSearch._(_client.search);

  /// Quick access to user API (deprecated - use client.user instead)
  GroupVANUser get user => GroupVANUser._(_client.user);

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

/// Namespaced vehicles API
class GroupVANVehicles {
  final VehiclesClient _client;

  const GroupVANVehicles._(this._client);

  /// Get user vehicles
  Future<List<Vehicle>> getUserVehicles({
    int offset = 0,
    int limit = 20,
  }) async {
    final result = await _client.getUserVehicles(offset: offset, limit: limit);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Search vehicles
  Future<VehicleSearchResponse> search({
    required String query,
    int? groupId,
    int page = 1,
  }) async {
    final result = await _client.searchVehicles(
      query: query,
      groupId: groupId,
      page: page,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Search by VIN
  Future<Vehicle?> searchByVin(String vin) async {
    final result = await _client.searchByVin(vin);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Search by license plate
  Future<List<Vehicle>> searchByPlate({
    required String plate,
    required String state,
  }) async {
    final result = await _client.searchByPlate(plate: plate, state: state);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get vehicle groups
  Future<List<VehicleGroup>> getGroups() async {
    final result = await _client.getVehicleGroups();
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Filter vehicles
  Future<VehicleFilterResponse> filter({
    required VehicleFilterRequest request,
  }) async {
    Result<VehicleFilterResponse> result = await _client.filterVehicles(
      request: request,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get engines
  Future<List<Vehicle>> getEngines({
    required EngineSearchRequest request,
  }) async {
    final result = await _client.getEngines(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get fleets
  Future<List<Fleet>> getFleets() async {
    final result = await _client.getFleets();
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get fleet vehicles
  Future<List<Vehicle>> getFleetVehicles({required int fleetId}) async {
    final result = await _client.getFleetVehicles(fleetId: fleetId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get account vehicles
  Future<List<Vehicle>> getAccountVehicles({
    int offset = 0,
    int limit = 20,
  }) async {
    final result = await _client.getAccountVehicles(
      offset: offset,
      limit: limit,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get previously selected part types for a vehicle
  Future<List<PartType>> getPreviousPartTypes({
    required int vehicleIndex,
  }) async {
    final result = await _client.getPreviousPartTypes(
      vehicleIndex: vehicleIndex,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get vehicle swap data including compatible years and engines
  ///
  /// Returns compatible years and vehicle/engine options for swapping
  /// a vehicle at the given index. Optionally filter by a specific year.
  Future<VehicleSwapResponse> getSwapData({
    required int vehicleIndex,
    int? year,
  }) async {
    final result = await _client.getSwapData(
      request: VehicleSwapRequest(vehicleIndex: vehicleIndex, year: year),
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}

/// Namespaced catalogs API
class GroupVANCatalogs {
  final CatalogsClient _client;

  const GroupVANCatalogs._(this._client);

  /// Get available catalogs
  Future<List<Catalog>> getCatalogs() async {
    final result = await _client.getCatalogs();
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get vehicle categories
  Future<List<VehicleCategory>> getVehicleCategories({
    required int catalogId,
    required int engineIndex,
    bool? disableFilters,
  }) async {
    final result = await _client.getVehicleCategories(
      catalogId: catalogId,
      engineIndex: engineIndex,
      disableFilters: disableFilters,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get supply categories
  Future<List<SupplyCategory>> getSupplyCategories({
    required int catalogId,
  }) async {
    final result = await _client.getSupplyCategories(catalogId: catalogId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get application assets
  Future<List<ApplicationAsset>> getApplicationAssets({
    required List<int> applicationIds,
    String? languageCode,
  }) async {
    final result = await _client.getApplicationAssets(
      applicationIds: applicationIds,
      languageCode: languageCode,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Start a catalog products-listing session over the shared multiplex socket.
  ///
  /// Returns a [ProductsListingSession] that can be used to issue multiple
  /// listing requests over the single SDK WebSocket. Call [dispose] when done.
  ProductsListingSession startProductsListingSession() =>
      _client.startProductsListingSession();

  Future<List<Asset>> getProductAssets({
    List<int>? catalogSkus,
    List<int>? memberSkus,
    bool primaryOnly = true
  }) async {
    final result = await _client.getProductAssets(
      catalogSkus: catalogSkus,
      memberSkus: memberSkus,
      primaryOnly: primaryOnly,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  Future<Interchange> getInterchanges({
    required String partNumber,
    List<String>? brands,
    List<int>? partTypes,
  }) async {
    final result = await _client.getInterchanges(
      partNumber: partNumber,
      brands: brands,
      partTypes: partTypes,
    );
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  Future<List<ItemPricing>> getProductPricing({
    required ProductPricingRequest request,
  }) async {
    final result = await _client.getProductPricing(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  Future<ProductInfoResponse> getProductInfo({required int sku}) async {
    final result = await _client.getProductInfo(sku: sku);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get Identifix URL
  Future<String> getIdentifixUrl(int vehicleIndex) async {
    final result = await _client.getIdentifixUrl(vehicleIndex: vehicleIndex);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get buyers guide for a part
  Future<BuyersGuideResponse> getBuyersGuide({
    required BuyersGuideRequest request,
  }) async {
    final result = await _client.getBuyersGuide(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  Future<FlatBuyersGuideResponse> getFlatBuyersGuide({
    required FlatBuyersGuideRequest request,
  }) async {
    final result = await _client.getFlatBuyersGuide(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get invoices via the v3.2 gateway
  Future<InvoiceResponse> getInvoices({
    required InvoiceRequest request,
  }) async {
    final result = await _client.getInvoices(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get statements via the v3.2 gateway
  Future<StatementResponse> getStatements({
    required StatementRequest request,
  }) async {
    final result = await _client.getStatements(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get PDF bytes from a link URL
  Future<List<int>> getPdfBytes({required String linkUrl}) async {
    final result = await _client.getPdfBytes(linkUrl: linkUrl);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}

/// Namespaced cart API
class GroupVANCart {
  final CartClient _client;

  const GroupVANCart._(this._client);

  /// Add items to cart
  Future<CartResponse> addToCart(AddToCartRequest request) async {
    final result = await _client.addToCart(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Remove items from cart
  Future<CartResponse> removeFromCart(RemoveFromCartRequest request) async {
    final result = await _client.removeFromCart(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Checkout a cart, placing orders for all items
  Future<CheckoutResponse> checkout(CheckoutRequest request) async {
    final result = await _client.checkout(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}

/// Namespaced reports API
class GroupVANReports {
  final ReportsClient _client;

  const GroupVANReports._(this._client);

  Future<void> createReport({required Uint8List screenshot, String? message}) =>
      _client.createReport(screenshot: screenshot, message: message);
}

/// Namespaced search API
class GroupVANSearch {
  final SearchClient _client;

  const GroupVANSearch._(this._client);

  /// Start a persistent omni search session
  ///
  /// Returns an [OmniSearchSession] that can be used to perform multiple searches
  /// over a single WebSocket connection. Remember to call [dispose] on the session
  /// when you are done.
  OmniSearchSession startSession() => _client.startOmniSearchSession();

  /// Get VIN data
  Future<List<Map<String, String>>> vinData(String vin) async {
    final result = await _client.vinData(vin);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Start a products search session over the shared multiplex socket.
  ///
  /// Returns a [ProductsSearchSession] that exposes a long-lived [Stream]
  /// of results. Call `search(...)` to issue a query, `dispose()` when done.
  ProductsSearchSession startProductsSearchSession() =>
      _client.startProductsSearchSession();
}

/// Namespaced user API
class GroupVANUser {
  final UserClient _client;

  const GroupVANUser._(this._client);

  /// Get location details
  Future<LocationDetails> getLocationDetails(String locationId) async {
    final result = await _client.getLocationDetails(locationId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
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
  GroupVANVehicles get vehicles => GroupVANVehicles._(_client.vehicles);

  /// Catalog operations
  GroupVANCatalogs get catalogs => GroupVANCatalogs._(_client.catalogs);

  /// Cart operations
  GroupVANCart get cart => GroupVANCart._(_client.cart);

  /// Reports operations
  GroupVANReports get reports => GroupVANReports._(_client.reports);

  /// Search operations
  GroupVANSearch get search => GroupVANSearch._(_client.search);

  /// User operations
  GroupVANUser get user => GroupVANUser._(_client.user);
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
