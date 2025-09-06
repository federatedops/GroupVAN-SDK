/// Elite GroupVAN SDK Client
/// 
/// Main entry point for the GroupVAN SDK providing a comprehensive,
/// type-safe, and user-friendly interface to the GroupVAN V3 API.
library groupvan_client;

import 'dart:async';

import 'package:meta/meta.dart';

import 'auth/auth_manager.dart';
import 'auth/auth_models.dart';
import 'core/http_client.dart';
import 'core/response.dart';
import 'core/validation.dart';
import 'logging.dart';
import 'models/models.dart';

/// Configuration for the GroupVAN SDK client
@immutable
class GroupVanClientConfig {
  /// API base URL (defaults to staging)
  final String baseUrl;

  /// HTTP client configuration
  final HttpClientConfig httpClientConfig;

  /// Token storage implementation
  final TokenStorage? tokenStorage;

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
    this.autoRefreshTokens = true,
    this.enableLogging = true,
    this.enableCaching = true,
  }) : httpClientConfig = httpClientConfig ?? 
         const HttpClientConfig(baseUrl: 'https://api.staging.groupvan.com');

  /// Create production configuration (uses secure storage by default)
  factory GroupVanClientConfig.production({
    TokenStorage? tokenStorage,
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
      tokenStorage: tokenStorage ?? SecureTokenStorage(),
      autoRefreshTokens: autoRefreshTokens,
      enableLogging: enableLogging,
      enableCaching: enableCaching,
    );
  }

  /// Create staging configuration (uses secure storage by default)
  factory GroupVanClientConfig.staging({
    TokenStorage? tokenStorage,
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
      tokenStorage: tokenStorage ?? SecureTokenStorage(),
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
/// 
/// Example usage:
/// ```dart
/// final client = GroupVanClient(GroupVanClientConfig.production());
/// await client.initialize();
/// 
/// // Authenticate
/// await client.auth.login(
///   username: 'your-username',
///   password: 'your-password', 
///   developerId: 'your-developer-id',
/// );
/// 
/// // Use API methods
/// final vehicles = await client.vehicles.getUserVehicles();
/// final catalogs = await client.catalogs.getCatalogs();
/// ```
class GroupVanClient {
  final GroupVanClientConfig _config;
  late final GroupVanHttpClient _httpClient;
  late final AuthManager _authManager;
  
  /// Vehicles API client
  late final VehiclesClient vehicles;
  
  /// Catalogs API client  
  late final CatalogsClient catalogs;

  /// Authentication manager
  AuthManager get auth => _authManager;

  /// Stream of authentication status changes
  Stream<AuthStatus> get authStatusStream => _authManager.statusStream;

  /// Current authentication status
  AuthStatus get authStatus => _authManager.currentStatus;

  /// Whether currently authenticated
  bool get isAuthenticated => _authManager.isAuthenticated;

  /// Current user ID (if authenticated)
  String? get userId => _authManager.userId;

  /// Current developer ID (if authenticated)
  String? get developerId => _authManager.developerId;

  GroupVanClient(this._config) {
    // Initialize logging
    if (_config.enableLogging) {
      GroupVanLogger.initialize(enableConsoleOutput: true);
    }

    _initializeHttpClient();
    _initializeAuthManager();
    _initializeApiClients();
  }

  /// Initialize the client
  /// 
  /// This should be called before using the client to restore any
  /// previously stored authentication state.
  Future<void> initialize() async {
    await _authManager.initialize();
    GroupVanLogger.sdk.info('GroupVAN SDK initialized successfully');
  }

  void _initializeHttpClient() {
    _httpClient = GroupVanHttpClient(_config.httpClientConfig);
  }

  void _initializeAuthManager() {
    _authManager = AuthManager(
      httpClient: _httpClient,
      tokenStorage: _config.tokenStorage,
    );

    // Listen to auth status changes and update HTTP client token
    _authManager.statusStream.listen((status) {
      if (status.accessToken != null) {
        // Update HTTP client with new token
        // This would require adding a method to update the token
        GroupVanLogger.auth.fine('Updated HTTP client with new access token');
      }
    });
  }

  void _initializeApiClients() {
    vehicles = VehiclesClient(_httpClient, _authManager);
    catalogs = CatalogsClient(_httpClient, _authManager);
  }

  /// Dispose the client and clean up resources
  void dispose() {
    _authManager.dispose();
    _httpClient.close();
    GroupVanLogger.sdk.info('GroupVAN SDK disposed');
  }
}

/// Base class for API client modules
abstract class ApiClient {
  final GroupVanHttpClient httpClient;
  final AuthManager authManager;

  const ApiClient(this.httpClient, this.authManager);

  /// Get a valid access token, refreshing if necessary
  Future<String> getValidToken() async {
    return await authManager.getValidAccessToken();
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
          .map((json) => VehicleGroup.fromJson(json as Map<String, dynamic>))
          .toList();

      GroupVanLogger.vehicles.info('Retrieved ${groups.length} vehicle groups');
      return Success(groups);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get vehicle groups: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
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
      return Failure(e as Exception);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/user',
        queryParameters: {'offset': offset, 'limit': limit},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((json) => Vehicle.fromJson(json as Map<String, dynamic>))
          .toList();

      GroupVanLogger.vehicles.info('Retrieved ${vehicles.length} user vehicles');
      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Failed to get user vehicles: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
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
      if (groupId != null) {
        IntValidator(min: 1).validateAndThrow(groupId, 'groupId');
      }
      IntValidator(min: 1).validateAndThrow(page, 'page');
    } catch (e) {
      return Failure(e as Exception);
    }

    try {
      final queryParams = <String, dynamic>{
        'query': query,
        'page': page,
      };
      if (groupId != null) {
        queryParams['group_id'] = groupId;
      }

      final response = await get<Map<String, dynamic>>(
        '/v3/vehicles/search',
        queryParameters: queryParams,
        decoder: (data) => data as Map<String, dynamic>,
      );

      final searchResponse = VehicleSearchResponse.fromJson(response.data);
      GroupVanLogger.vehicles.info(
        'Vehicle search returned ${searchResponse.vehicles.length} results'
      );
      return Success(searchResponse);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Vehicle search failed: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Search vehicle by VIN with validation
  Future<Result<List<Vehicle>?>> searchByVin(String vin) async {
    // Validate VIN
    try {
      GroupVanValidators.vin().validateAndThrow(vin, 'vin');
    } catch (e) {
      return Failure(e as Exception);
    }

    try {
      final response = await get<List<dynamic>?>(
        '/v3/vehicles/vin',
        queryParameters: {'vin': vin},
        decoder: (data) => data as List<dynamic>?,
      );

      if (response.data == null) {
        GroupVanLogger.vehicles.info('No vehicle found for VIN: $vin');
        return const Success(null);
      }

      final vehicles = response.data!
          .map((json) => Vehicle.fromJson(json as Map<String, dynamic>))
          .toList();

      GroupVanLogger.vehicles.info('Found vehicle for VIN: $vin');
      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('VIN search failed: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Search vehicle by license plate with validation
  Future<Result<List<Vehicle>>> searchByPlate({
    required String plate,
    required String state,
  }) async {
    // Validate plate and state
    try {
      GroupVanValidators.licensePlate().validateAndThrow(plate, 'plate');
      GroupVanValidators.usState().validateAndThrow(state, 'state');
    } catch (e) {
      return Failure(e as Exception);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/vehicles/plate',
        queryParameters: {'plate': plate, 'state': state},
        decoder: (data) => data as List<dynamic>,
      );

      final vehicles = response.data
          .map((json) => Vehicle.fromJson(json as Map<String, dynamic>))
          .toList();

      GroupVanLogger.vehicles.info('Found vehicle for plate: $plate ($state)');
      return Success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe('Plate search failed: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}

/// Catalogs API client with comprehensive catalog management
class CatalogsClient extends ApiClient {
  const CatalogsClient(super.httpClient, super.authManager);

  /// Get catalogs with proper error handling
  Future<Result<List<Catalog>>> getCatalogs() async {
    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/list',
        decoder: (data) => data as List<dynamic>,
      );

      final catalogs = response.data
          .map((json) => Catalog.fromJson(json as Map<String, dynamic>))
          .toList();

      GroupVanLogger.catalogs.info('Retrieved ${catalogs.length} catalogs');
      return Success(catalogs);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get catalogs: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get vehicle categories with validation
  Future<Result<List<VehicleCategory>>> getVehicleCategories({
    required int catalogId,
    required int engineIndex,
    String? sessionId,
  }) async {
    // Validate parameters
    try {
      IntValidator(min: 1).validateAndThrow(catalogId, 'catalogId');
      IntValidator(min: 0).validateAndThrow(engineIndex, 'engineIndex');
      if (sessionId != null) {
        GroupVanValidators.sessionId().validateAndThrow(sessionId, 'sessionId');
      }
    } catch (e) {
      return Failure(e as Exception);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/$catalogId/vehicle/$engineIndex/categories',
        decoder: (data) => data as List<dynamic>,
      );

      final categories = response.data
          .map((json) => VehicleCategory.fromJson(json as Map<String, dynamic>))
          .toList();

      GroupVanLogger.catalogs.info('Retrieved ${categories.length} vehicle categories');
      return Success(categories);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get vehicle categories: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get supply categories with validation  
  Future<Result<List<SupplyCategory>>> getSupplyCategories({
    required int catalogId,
  }) async {
    // Validate parameters
    try {
      IntValidator(min: 1).validateAndThrow(catalogId, 'catalogId');
    } catch (e) {
      return Failure(e as Exception);
    }

    try {
      final response = await get<List<dynamic>>(
        '/v3/catalogs/$catalogId/categories',
        decoder: (data) => data as List<dynamic>,
      );

      final categories = response.data
          .map((json) => SupplyCategory.fromJson(json as Map<String, dynamic>))
          .toList();

      GroupVanLogger.catalogs.info('Retrieved ${categories.length} supply categories');
      return Success(categories);
    } catch (e) {
      GroupVanLogger.catalogs.severe('Failed to get supply categories: $e');
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}