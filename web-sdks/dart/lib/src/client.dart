/// GroupVAN SDK Client
///
/// Main client implementation with singleton pattern for global access.
/// Provides both direct client usage and elegant singleton initialization.
library client;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
import 'session/session_cubit.dart';

/// Configuration for the GroupVAN SDK client
@immutable
class GroupVanClientConfig {
  /// API base URL (defaults to staging)
  final String baseUrl;

  /// HTTP client configuration
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

  const GroupVanClientConfig({
    this.baseUrl = 'https://api.staging.groupvan.com',
    HttpClientConfig? httpClientConfig,
    this.tokenStorage,
    this.clientId,
    this.autoRefreshTokens = true,
    this.enableLogging = true,
    this.enableCaching = true,
  }) : httpClientConfig =
           httpClientConfig ??
           const HttpClientConfig(baseUrl: 'https://api.staging.groupvan.com');

  /// Create production configuration (uses secure storage by default)
  factory GroupVanClientConfig.production({
    TokenStorage? tokenStorage,
    String? clientId,
    bool autoRefreshTokens = true,
    bool enableLogging = false,
    bool enableCaching = true,
  }) {
    return GroupVanClientConfig(
      baseUrl: 'https://api.groupvan.com',
      httpClientConfig: const HttpClientConfig(
        baseUrl: 'https://api.groupvan.com',
        enableLogging: false,
      ),
      tokenStorage: tokenStorage ?? SecureTokenStorage.platformOptimized(),
      clientId: clientId,
      autoRefreshTokens: autoRefreshTokens,
      enableLogging: enableLogging,
      enableCaching: enableCaching,
    );
  }

  /// Create staging configuration (uses secure storage by default)
  factory GroupVanClientConfig.staging({
    TokenStorage? tokenStorage,
    String? clientId,
    bool autoRefreshTokens = true,
    bool enableLogging = true,
    bool enableCaching = true,
  }) {
    return GroupVanClientConfig(
      baseUrl: 'https://api.staging.groupvan.com',
      httpClientConfig: const HttpClientConfig(
        baseUrl: 'https://api.staging.groupvan.com',
        enableLogging: true,
      ),
      tokenStorage: tokenStorage ?? SecureTokenStorage.platformOptimized(),
      clientId: clientId,
      autoRefreshTokens: autoRefreshTokens,
      enableLogging: enableLogging,
      enableCaching: enableCaching,
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
  late final SessionCubit _sessionCubit;
  late final VehiclesClient _vehiclesClient;
  late final CatalogsClient _catalogsClient;
  late final ReportsClient _reportsClient;
  late final SearchClient _searchClient;

  GroupVanClient(this._config);

  /// HTTP client instance
  GroupVanHttpClient get httpClient => _httpClient;

  /// Authentication manager
  AuthManager get auth => _authManager;

  /// Session manager
  SessionCubit get session => _sessionCubit;

  /// Current session ID (if available)
  String? get currentSessionId => _sessionCubit.currentSessionId;

  /// Vehicles API client
  VehiclesClient get vehicles => _vehiclesClient;

  /// Catalogs API client
  CatalogsClient get catalogs => _catalogsClient;

  /// Reports API client
  ReportsClient get reports => _reportsClient;

  /// Search API client
  SearchClient get search => _searchClient;

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

    // Initialize session cubit
    _sessionCubit = SessionCubit();
    GroupVanLogger.sdk.warning('DEBUG: Session manager initialized');

    // Initialize API clients
    _vehiclesClient = VehiclesClient(httpClient, _authManager, _sessionCubit);
    _catalogsClient = CatalogsClient(httpClient, _authManager, _sessionCubit);
    _reportsClient = ReportsClient(httpClient, _authManager);
    _searchClient = SearchClient(httpClient, _authManager, _sessionCubit);
    GroupVanLogger.sdk.warning('DEBUG: API clients initialized');

    // Initialize authentication manager (restore tokens if available)
    GroupVanLogger.sdk.warning('DEBUG: Calling auth manager initialize...');
    await _authManager.initialize(clientId!);
    GroupVanLogger.sdk.warning('DEBUG: Auth manager initialization completed');

    GroupVanLogger.sdk.info('GroupVAN SDK Client initialized');
  }

  /// Clean up resources
  void dispose() {
    _authManager.dispose();
    _sessionCubit.close();
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
}

/// Vehicles API client with comprehensive vehicle management
class VehiclesClient extends ApiClient {
  final SessionCubit _sessionCubit;

  const VehiclesClient(super.httpClient, super.authManager, this._sessionCubit);

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

      // Store session ID if present
      if (response.sessionId != null) {
        _sessionCubit.updateSession(response.sessionId!);
      }

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

      // Store session ID if present
      if (response.sessionId != null) {
        _sessionCubit.updateSession(response.sessionId!);
      }

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

      // Store session ID if present
      if (response.sessionId != null) {
        _sessionCubit.updateSession(response.sessionId!);
      }

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

      // Store session ID if present
      if (response.sessionId != null) {
        _sessionCubit.updateSession(response.sessionId!);
      }

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

      // Store session ID if present
      if (response.sessionId != null) {
        _sessionCubit.updateSession(response.sessionId!);
      }

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

      // Store session ID if present
      if (response.sessionId != null) {
        _sessionCubit.updateSession(response.sessionId!);
      }

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
}

/// Catalogs API client with comprehensive catalog management
class CatalogsClient extends ApiClient {
  final SessionCubit _sessionCubit;

  const CatalogsClient(super.httpClient, super.authManager, this._sessionCubit);

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
    String? sessionId,
    bool? disableFilters,
  }) async {
    // Use provided sessionId or get from cubit
    final effectiveSessionId = sessionId ?? _sessionCubit.currentSessionId;
    final queryParams = <String, dynamic>{};
    if (disableFilters != null) {
      queryParams['disable_filters'] = disableFilters;
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/$catalogId/vehicle/$engineIndex/categories',
        queryParameters: queryParams,
        decoder: (data) => data as List<dynamic>,
        options: effectiveSessionId != null
            ? Options(
                headers: {
                  'Authorization':
                      'Bearer ${authManager.currentStatus.accessToken}',
                  'gv-session-id': effectiveSessionId,
                },
              )
            : null,
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

  /// Get cart details with validation
  Future<Result<List<CartItem>>> getCart({required String cartId}) async {
    // Validate cart ID
    try {
      if (cartId.trim().isEmpty) {
        throw ValidationException(
          'Cart ID cannot be empty',
          errors: [
            ValidationError(
              field: 'cart_id',
              message: 'Cart ID cannot be empty',
              value: cartId,
              rule: 'required',
            ),
          ],
        );
      }
    } catch (e) {
      return Failure(e as ValidationException);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/cart/$cartId',
        decoder: (data) => data as List<dynamic>,
      );

      final cartItems = response.data
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(cartItems);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get cart: $e');
      return Failure(
        e is GroupVanException ? e : NetworkException('Failed to get cart: $e'),
      );
    }
  }

  /// Get product listings with validation
  Stream<List<ProductListing>> getProducts({
    required ProductListingRequest request,
    String? sessionId,
  }) async* {
    WebSocketChannel? channel;

    final effectiveSessionId = sessionId ?? _sessionCubit.currentSessionId;
    final baseUri = Uri.parse(httpClient.baseUrl);
    final wsUri = Uri(
      scheme: 'wss',
      host: baseUri.host,
      path: '/v3/catalogs/products',
      queryParameters: {
        'token': authManager.currentStatus.accessToken,
        if (effectiveSessionId != null) 'session_id': effectiveSessionId,
      },
    );

    try {
      channel = WebSocketChannel.connect(wsUri);

      channel.sink.add(jsonEncode(request.toJson()));

      List<ProductListing> products = [];

      await for (final message in channel.stream) {
        final data = jsonDecode(message);
        if (data.containsKey('product_listings')) {
          for (final product in data['product_listings']) {
            products.add(ProductListing.fromJson(product));
          }
          yield products;
        } else if (data.containsKey('assets')) {
          final assets = data['assets'];
          for (final product in products) {
            for (final part in product.parts) {
              part.assets = Asset.fromJson(assets[part.sku.toString()]);
            }
          }
          yield products;
        } else if (data.containsKey('pricing')) {
          final pricing = data['pricing'];
          for (final product in products) {
            for (final part in product.parts) {
              part.pricing = ItemPricing.fromJson(pricing[part.sku.toString()]);
            }
          }
          yield products;
        }
      }
    } catch (e, stackTrace) {
      GroupVanLogger.catalogs.severe('Failed to stream products: $e');
      Error.throwWithStackTrace(
        NetworkException('Failed to stream products: $e'),
        stackTrace,
      );
    } finally {
      await channel?.sink.close();
    }
  }

  Future<Result<List<Asset>>> getProductAssets({
    required List<int> skus,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/catalogs/products/assets',
        data: {'catalog_skus': skus},
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

  Future<Result<List<ItemPricing>>> getItemPricing({
    required List<ItemPricingRequest> items,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/json/federated/v3_1/item_inquiry',
        data: items.map((item) => item.toJson()).toList(),
        decoder: (data) => data as Map<String, dynamic>,
      );
      return Success(
        response.data.entries
            .map((item) => ItemPricing.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get item pricing: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get item pricing: $e'),
      );
    }
  }

  Future<Result<ProductInfoResponse>> getProductInfo({required int sku}) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/v3/catalogs/products/info',
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

/// Search API client for omni search functionality
class SearchClient extends ApiClient {
  final SessionCubit _sessionCubit;

  const SearchClient(super.httpClient, super.authManager, this._sessionCubit);

  /// Perform omni search with optional vehicle context
  Future<Result<OmniSearchResponse>> omni({
    required String query,
    int? vehicleIndex,
    bool? disableFilters,
  }) async {
    final sessionId = _sessionCubit.currentSessionId;

    try {
      final queryParams = <String, dynamic>{'query': query};

      if (vehicleIndex != null) {
        queryParams['vehicle_index'] = vehicleIndex;
      }
      if (disableFilters != null) {
        queryParams['disable_filters'] = disableFilters;
      }

      final response = await get<Map<String, dynamic>>(
        '/v3/search/omni',
        queryParameters: queryParams,
        decoder: (data) => data as Map<String, dynamic>,
        options: sessionId != null
            ? Options(headers: {'gv-session-id': sessionId})
            : null,
      );

      // Store session ID if present
      if (response.sessionId != null) {
        _sessionCubit.updateSession(response.sessionId!);
      }

      final searchResponse = OmniSearchResponse.fromJson(response.data);
      return Success(searchResponse);
    } catch (e) {
      GroupVanLogger.sdk.severe('Omni search failed: $e');
      return Failure(
        e is GroupVanException ? e : NetworkException('Omni search failed: $e'),
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
    /// API base URL (defaults to production)
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

    /// HTTP client configuration
    HttpClientConfig? httpClientConfig,

    /// Whether this is a production environment
    bool isProduction = true,
  }) async {
    // Return existing instance if already initialized
    if (_instance?._isInitialized == true) {
      return _instance!;
    }

    _instance = GroupVAN._();

    // Create configuration based on environment
    final config = isProduction
        ? GroupVanClientConfig.production(
            tokenStorage: tokenStorage,
            clientId: clientId,
            autoRefreshTokens: autoRefreshTokens ?? true,
            enableLogging: enableLogging ?? false,
            enableCaching: enableCaching ?? true,
          )
        : GroupVanClientConfig.staging(
            tokenStorage: tokenStorage,
            clientId: clientId,
            autoRefreshTokens: autoRefreshTokens ?? true,
            enableLogging: enableLogging ?? true,
            enableCaching: enableCaching ?? true,
          );

    // Override base URL if provided
    final finalConfig = baseUrl != null || httpClientConfig != null
        ? GroupVanClientConfig(
            baseUrl:
                baseUrl ??
                (isProduction
                    ? 'https://api.groupvan.com'
                    : 'https://api.staging.groupvan.com'),
            httpClientConfig:
                httpClientConfig ??
                HttpClientConfig(
                  baseUrl:
                      baseUrl ??
                      (isProduction
                          ? 'https://api.groupvan.com'
                          : 'https://api.staging.groupvan.com'),
                  enableLogging: enableLogging ?? !isProduction,
                  enableCaching: enableCaching ?? true,
                ),
            tokenStorage: tokenStorage,
            clientId: clientId,
            autoRefreshTokens: autoRefreshTokens ?? true,
            enableLogging: enableLogging ?? !isProduction,
            enableCaching: enableCaching ?? true,
          )
        : config;

    // Initialize client
    _instance!._client = GroupVanClient(finalConfig);
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

  /// Quick access to reports API (deprecated - use client.reports instead)
  GroupVANReports get reports => GroupVANReports._(_client.reports);

  /// Quick access to search API (deprecated - use client.search instead)
  GroupVANSearch get search => GroupVANSearch._(_client.search);

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
    String? sessionId,
    bool? disableFilters,
  }) async {
    final result = await _client.getVehicleCategories(
      catalogId: catalogId,
      engineIndex: engineIndex,
      sessionId: sessionId,
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

  /// Get cart details
  Future<List<CartItem>> getCart({required String cartId}) async {
    final result = await _client.getCart(cartId: cartId);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Get product listings
  Stream<List<ProductListing>> getProducts({
    required ProductListingRequest request,
    String? sessionId,
  }) {
    return _client.getProducts(request: request, sessionId: sessionId);
  }

  Future<List<Asset>> getProductAssets({required List<int> skus}) async {
    final result = await _client.getProductAssets(skus: skus);
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

  Future<Map<String, ItemPricing>> getItemPricing({
    required List<ItemPricingRequest> items,
  }) async {
    final result = await _client.getItemPricing(items: items);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    Map<String, ItemPricing> pricing = {};
    for (var item in result.value) {
      pricing[item.id] = item;
    }
    return pricing;
  }

  Future<ProductInfoResponse> getProductInfo({required int sku}) async {
    final result = await _client.getProductInfo(sku: sku);
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

  /// Perform omni search
  Future<OmniSearchResponse> omni({
    required String query,
    int? vehicleIndex,
    bool? disableFilters,
  }) async {
    final result = await _client.omni(
      query: query,
      vehicleIndex: vehicleIndex,
      disableFilters: disableFilters,
    );
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

  /// Reports operations
  GroupVANReports get reports => GroupVANReports._(_client.reports);

  /// Search operations
  GroupVANSearch get search => GroupVANSearch._(_client.search);
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
@immutable
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final User user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
    required this.user,
  });

  factory AuthSession.fromAuthStatus(
    auth_models.AuthStatus status, {
    String? clientId,
  }) => AuthSession(
    accessToken: status.accessToken!,
    refreshToken: status.refreshToken!,
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
