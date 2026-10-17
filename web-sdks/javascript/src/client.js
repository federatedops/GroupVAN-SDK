/**
 * GroupVAN SDK Client
 *
 * Main client implementation with singleton pattern for global access.
 * Provides both direct client usage and elegant singleton initialization.
 */

import { GroupVanHttpClient, HttpClientConfig } from './core/http_client.js';
import { AuthManager, LocalStorageTokenStorage, MemoryTokenStorage } from './auth/auth_manager.js';
import { GroupVanLogger, LogLevel } from './logging.js';
import { AuthenticationException, AuthErrorType, NetworkException, GroupVanException } from './core/exceptions.js';
import { Result } from './core/response.js';
import { GroupVanValidators } from './core/validation.js';

// Import models
import {
  VehicleGroup,
  VehicleSearchResponse,
  VehicleFilterResponse,
  Fleet,
  Vehicle,
} from './models/vehicles.js';
import {
  Catalog,
  VehicleCategory,
  SupplyCategory,
  ApplicationAsset,
  PartType,
} from './models/catalogs.js';
import { ProductListing } from './models/products/product_listing.js';
import { Part } from './models/products/part.js';
import { Asset } from './models/assets/asset.js';
import { ItemPricing } from './models/products/item_pricing.js';
import { Interchange } from './models/interchange/index.js';
import { CartResponse } from './models/cart/index.js';
import { OmniSearchResponse, VehicleAndPartType, MemberCategory } from './models/search/index.js';
import { ProductInfoResponse } from './models/product_info/index.js';
import { LocationDetails } from './models/user/index.js';

/**
 * Configuration for the GroupVAN SDK client
 */
export class GroupVanClientConfig {
  /**
   * @param {Object} options
   * @param {string} [options.baseUrl='https://api.staging.groupvan.com'] - API base URL
   * @param {HttpClientConfig} [options.httpClientConfig] - HTTP client configuration
   * @param {import('./auth/auth_manager.js').TokenStorage} [options.tokenStorage] - Token storage implementation
   * @param {string} [options.clientId] - Client ID for this SDK instance
   * @param {boolean} [options.autoRefreshTokens=true] - Enable automatic token refresh
   * @param {boolean} [options.enableLogging=true] - Enable request/response logging
   * @param {boolean} [options.enableCaching=true] - Enable caching
   */
  constructor({
    baseUrl = 'https://api.staging.groupvan.com',
    httpClientConfig = null,
    tokenStorage = null,
    clientId = null,
    autoRefreshTokens = true,
    enableLogging = true,
    enableCaching = true,
  } = {}) {
    this.baseUrl = baseUrl;
    this.httpClientConfig = httpClientConfig || new HttpClientConfig({
      baseUrl,
      enableLogging,
      enableCaching,
    });
    this.tokenStorage = tokenStorage;
    this.clientId = clientId;
    this.autoRefreshTokens = autoRefreshTokens;
    this.enableLogging = enableLogging;
    this.enableCaching = enableCaching;
  }

  /**
   * Create production configuration
   * @param {Object} [options]
   * @returns {GroupVanClientConfig}
   */
  static production(options = {}) {
    const baseUrl = 'https://api.groupvan.com';
    return new GroupVanClientConfig({
      baseUrl,
      httpClientConfig: new HttpClientConfig({
        baseUrl,
        enableLogging: false,
        ...options.httpClientConfig,
      }),
      tokenStorage: options.tokenStorage || (typeof window !== 'undefined' ? new LocalStorageTokenStorage() : new MemoryTokenStorage()),
      clientId: options.clientId,
      autoRefreshTokens: options.autoRefreshTokens ?? true,
      enableLogging: options.enableLogging ?? false,
      enableCaching: options.enableCaching ?? true,
    });
  }

  /**
   * Create staging configuration
   * @param {Object} [options]
   * @returns {GroupVanClientConfig}
   */
  static staging(options = {}) {
    const baseUrl = 'https://api.staging.groupvan.com';
    return new GroupVanClientConfig({
      baseUrl,
      httpClientConfig: new HttpClientConfig({
        baseUrl,
        enableLogging: true,
        ...options.httpClientConfig,
      }),
      tokenStorage: options.tokenStorage || (typeof window !== 'undefined' ? new LocalStorageTokenStorage() : new MemoryTokenStorage()),
      clientId: options.clientId,
      autoRefreshTokens: options.autoRefreshTokens ?? true,
      enableLogging: options.enableLogging ?? true,
      enableCaching: options.enableCaching ?? true,
    });
  }
}

/**
 * Base API client with common functionality
 */
class ApiClient {
  /**
   * @param {GroupVanHttpClient} httpClient
   * @param {AuthManager} authManager
   */
  constructor(httpClient, authManager) {
    this.httpClient = httpClient;
    this.authManager = authManager;
  }

  /**
   * Make an authenticated GET request
   * @template T
   * @param {string} path
   * @param {Object} [options]
   * @returns {Promise<import('./core/response.js').GroupVanResponse<T>>}
   */
  async get(path, options = {}) {
    const headers = {
      'Authorization': `Bearer ${this.authManager.currentStatus.accessToken}`,
      ...options.headers,
    };
    return this.httpClient.get(path, { ...options, headers });
  }

  /**
   * Make an authenticated POST request
   * @template T
   * @param {string} path
   * @param {Object} [options]
   * @returns {Promise<import('./core/response.js').GroupVanResponse<T>>}
   */
  async post(path, options = {}) {
    const headers = {
      'Authorization': `Bearer ${this.authManager.currentStatus.accessToken}`,
      ...options.headers,
    };
    return this.httpClient.post(path, { ...options, headers });
  }

  /**
   * Make an authenticated PATCH request
   * @template T
   * @param {string} path
   * @param {Object} [options]
   * @returns {Promise<import('./core/response.js').GroupVanResponse<T>>}
   */
  async patch(path, options = {}) {
    const headers = {
      'Authorization': `Bearer ${this.authManager.currentStatus.accessToken}`,
      ...options.headers,
    };
    return this.httpClient.patch(path, { ...options, headers });
  }

  /**
   * Make an authenticated DELETE request
   * @template T
   * @param {string} path
   * @param {Object} [options]
   * @returns {Promise<import('./core/response.js').GroupVanResponse<T>>}
   */
  async delete(path, options = {}) {
    const headers = {
      'Authorization': `Bearer ${this.authManager.currentStatus.accessToken}`,
      ...options.headers,
    };
    return this.httpClient.delete(path, { ...options, headers });
  }
}

/**
 * Vehicles API client
 */
export class VehiclesClient extends ApiClient {
  /**
   * Get vehicle groups
   * @returns {Promise<Result<VehicleGroup[]>>}
   */
  async getVehicleGroups() {
    try {
      const response = await this.get('/v3/vehicles/groups');
      const groups = response.data.map(item => VehicleGroup.fromJson(item));
      return Result.success(groups);
    } catch (e) {
      GroupVanLogger.vehicles.severe(`Failed to get vehicle groups: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get vehicle groups: ${e}`));
    }
  }

  /**
   * Get user vehicles with pagination
   * @param {Object} [options]
   * @param {number} [options.offset=0]
   * @param {number} [options.limit=20]
   * @returns {Promise<Result<Vehicle[]>>}
   */
  async getUserVehicles({ offset = 0, limit = 20 } = {}) {
    try {
      GroupVanValidators.paginationOffset().validateAndThrow(offset, 'offset');
      GroupVanValidators.paginationLimit().validateAndThrow(limit, 'limit');
    } catch (e) {
      return Result.failure(e);
    }

    try {
      const response = await this.get('/v3/vehicles/user', {
        queryParameters: { offset, limit },
      });
      const vehicles = response.data.map(item => Vehicle.fromJson(item));
      return Result.success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe(`Failed to get user vehicles: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get user vehicles: ${e}`));
    }
  }

  /**
   * Search vehicles
   * @param {Object} options
   * @param {string} options.query
   * @param {number} [options.groupId]
   * @param {number} [options.page=1]
   * @returns {Promise<Result<VehicleSearchResponse>>}
   */
  async searchVehicles({ query, groupId = null, page = 1 }) {
    try {
      GroupVanValidators.searchQuery().validateAndThrow(query, 'query');
    } catch (e) {
      return Result.failure(e);
    }

    try {
      const queryParams = { query, page };
      if (groupId !== null) queryParams.group_id = groupId;

      const response = await this.get('/v3/vehicles/search', {
        queryParameters: queryParams,
      });
      return Result.success(VehicleSearchResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.vehicles.severe(`Vehicle search failed: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Vehicle search failed: ${e}`));
    }
  }

  /**
   * Search by VIN
   * @param {string} vin
   * @returns {Promise<Result<Vehicle|null>>}
   */
  async searchByVin(vin) {
    try {
      GroupVanValidators.vin().validateAndThrow(vin, 'vin');
    } catch (e) {
      return Result.failure(e);
    }

    try {
      const response = await this.get('/v3/vehicles/vin', {
        queryParameters: { vin },
      });
      const vehicles = response.data.map(item => Vehicle.fromJson(item));
      return Result.success(vehicles[0] || null);
    } catch (e) {
      GroupVanLogger.vehicles.severe(`VIN search failed: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`VIN search failed: ${e}`));
    }
  }

  /**
   * Search by license plate
   * @param {Object} options
   * @param {string} options.plate
   * @param {string} options.state
   * @returns {Promise<Result<Vehicle[]>>}
   */
  async searchByPlate({ plate, state }) {
    try {
      GroupVanValidators.licensePlate().validateAndThrow(plate, 'plate');
      GroupVanValidators.usState().validateAndThrow(state, 'state');
    } catch (e) {
      return Result.failure(e);
    }

    try {
      const response = await this.get('/v3/vehicles/plate', {
        queryParameters: { plate, state },
      });
      const vehicles = response.data.map(item => Vehicle.fromJson(item));
      return Result.success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe(`License plate search failed: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`License plate search failed: ${e}`));
    }
  }

  /**
   * Filter vehicles
   * @param {import('./models/vehicles.js').VehicleFilterRequest} request
   * @returns {Promise<Result<VehicleFilterResponse>>}
   */
  async filterVehicles(request) {
    try {
      const response = await this.get('/v3/vehicles/filter', {
        queryParameters: request.toJson(),
      });
      return Result.success(VehicleFilterResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.vehicles.severe(`Vehicle filtering failed: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Vehicle filtering failed: ${e}`));
    }
  }

  /**
   * Get engines
   * @param {import('./models/vehicles.js').EngineSearchRequest} request
   * @returns {Promise<Result<Vehicle[]>>}
   */
  async getEngines(request) {
    try {
      const response = await this.get('/v3/vehicles/engines', {
        queryParameters: request.toJson(),
      });
      const vehicles = response.data.map(item => Vehicle.fromJson(item));
      return Result.success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe(`Failed to get engine data: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get engine data: ${e}`));
    }
  }

  /**
   * Get fleets
   * @returns {Promise<Result<Fleet[]>>}
   */
  async getFleets() {
    try {
      const response = await this.get('/v3/vehicles/fleets');
      const fleets = response.data.map(item => Fleet.fromJson(item));
      return Result.success(fleets);
    } catch (e) {
      GroupVanLogger.vehicles.severe(`Failed to get fleets: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get fleets: ${e}`));
    }
  }

  /**
   * Get fleet vehicles
   * @param {number} fleetId
   * @returns {Promise<Result<Vehicle[]>>}
   */
  async getFleetVehicles(fleetId) {
    try {
      const response = await this.get(`/v3/vehicles/fleets/${fleetId}`);
      const vehicles = response.data.map(item => Vehicle.fromJson(item));
      return Result.success(vehicles);
    } catch (e) {
      GroupVanLogger.vehicles.severe(`Failed to get fleet vehicles: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get fleet vehicles: ${e}`));
    }
  }

  /**
   * Get previous part types for a vehicle
   * @param {number} vehicleIndex
   * @returns {Promise<Result<PartType[]>>}
   */
  async getPreviousPartTypes(vehicleIndex) {
    try {
      const response = await this.get(`/v3/vehicles/${vehicleIndex}/part_types`);
      const partTypes = response.data.map(item => PartType.fromJson(item));
      return Result.success(partTypes);
    } catch (e) {
      GroupVanLogger.vehicles.severe(`Failed to get previous part types: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get previous part types: ${e}`));
    }
  }
}

/**
 * Catalogs API client
 */
export class CatalogsClient extends ApiClient {
  /**
   * Get available catalogs
   * @returns {Promise<Result<Catalog[]>>}
   */
  async getCatalogs() {
    try {
      const response = await this.get('/v3/catalogs/list');
      const catalogs = response.data.map(item => Catalog.fromJson(item));
      return Result.success(catalogs);
    } catch (e) {
      GroupVanLogger.catalogs.severe(`Failed to get catalogs: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get catalogs: ${e}`));
    }
  }

  /**
   * Get vehicle categories
   * @param {Object} options
   * @param {number} options.catalogId
   * @param {number} options.engineIndex
   * @param {boolean} [options.disableFilters]
   * @returns {Promise<Result<VehicleCategory[]>>}
   */
  async getVehicleCategories({ catalogId, engineIndex, disableFilters = null }) {
    try {
      const queryParams = {};
      if (disableFilters !== null) queryParams.disable_filters = disableFilters;

      const response = await this.get(`/v3/catalogs/${catalogId}/vehicle/${engineIndex}/categories`, {
        queryParameters: queryParams,
      });
      const categories = response.data.map(item => VehicleCategory.fromJson(item));
      return Result.success(categories);
    } catch (e) {
      GroupVanLogger.catalogs.severe(`Failed to get vehicle categories: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get vehicle categories: ${e}`));
    }
  }

  /**
   * Get supply categories
   * @param {number} catalogId
   * @returns {Promise<Result<SupplyCategory[]>>}
   */
  async getSupplyCategories(catalogId) {
    try {
      const response = await this.get(`/v3/catalogs/${catalogId}/categories`);
      const categories = response.data.map(item => SupplyCategory.fromJson(item));
      return Result.success(categories);
    } catch (e) {
      GroupVanLogger.catalogs.severe(`Failed to get supply categories: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get supply categories: ${e}`));
    }
  }

  /**
   * Get application assets
   * @param {Object} options
   * @param {number[]} options.applicationIds
   * @param {string} [options.languageCode]
   * @returns {Promise<Result<ApplicationAsset[]>>}
   */
  async getApplicationAssets({ applicationIds, languageCode = null }) {
    try {
      const queryParams = { application_ids: applicationIds.join(',') };
      if (languageCode) queryParams.language_code = languageCode;

      const response = await this.get('/v3/catalogs/application_assets', {
        queryParameters: queryParams,
      });
      const assets = response.data.map(item => ApplicationAsset.fromJson(item));
      return Result.success(assets);
    } catch (e) {
      GroupVanLogger.catalogs.severe(`Failed to get application assets: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get application assets: ${e}`));
    }
  }

  /**
   * Get product assets
   * @param {Object} options
   * @param {number[]} [options.catalogSkus]
   * @param {number[]} [options.memberSkus]
   * @returns {Promise<Result<Asset[]>>}
   */
  async getProductAssets({ catalogSkus = null, memberSkus = null } = {}) {
    try {
      const response = await this.post('/v3/catalogs/products/assets', {
        data: { catalog_skus: catalogSkus, member_skus: memberSkus },
      });
      const assets = (response.data.catalog_assets || []).map(item => Asset.fromJson(item));
      return Result.success(assets);
    } catch (e) {
      GroupVanLogger.catalogs.severe(`Failed to get product assets: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get product assets: ${e}`));
    }
  }

  /**
   * Get interchanges
   * @param {Object} options
   * @param {string} options.partNumber
   * @param {string[]} [options.brands]
   * @param {number[]} [options.partTypes]
   * @returns {Promise<Result<Interchange>>}
   */
  async getInterchanges({ partNumber, brands = null, partTypes = null }) {
    try {
      const response = await this.post('/v3/catalogs/interchange', {
        data: { part_number: partNumber, brands, part_types: partTypes },
      });
      return Result.success(Interchange.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe(`Failed to get interchange: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get interchange: ${e}`));
    }
  }

  /**
   * Get product info
   * @param {number} sku
   * @returns {Promise<Result<ProductInfoResponse>>}
   */
  async getProductInfo(sku) {
    try {
      const response = await this.get('/v3/catalogs/product/info', {
        queryParameters: { sku },
      });
      return Result.success(ProductInfoResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.catalogs.severe(`Failed to get product info: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get product info: ${e}`));
    }
  }

  /**
   * Get Identifix URL
   * @param {number} vehicleIndex
   * @returns {Promise<Result<string>>}
   */
  async getIdentifixUrl(vehicleIndex) {
    try {
      const response = await this.get('/v3/catalogs/identifix', {
        queryParameters: { vehicle_index: vehicleIndex },
      });
      return Result.success(response.data.identifix_login_url);
    } catch (e) {
      GroupVanLogger.catalogs.severe(`Failed to get Identifix URL: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get Identifix URL: ${e}`));
    }
  }
}

/**
 * Cart API client
 */
export class CartClient extends ApiClient {
  /**
   * Add items to cart
   * @param {import('./models/cart/index.js').AddToCartRequest} request
   * @returns {Promise<Result<CartResponse>>}
   */
  async addToCart(request) {
    try {
      const response = await this.patch('/v3/cart/items/add', {
        data: request.toJson(),
      });
      return Result.success(CartResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.cart.severe(`Failed to add items to cart: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to add items to cart: ${e}`));
    }
  }

  /**
   * Remove items from cart
   * @param {import('./models/cart/index.js').RemoveFromCartRequest} request
   * @returns {Promise<Result<CartResponse>>}
   */
  async removeFromCart(request) {
    try {
      const response = await this.patch('/v3/cart/items/remove', {
        data: request.toJson(),
      });
      return Result.success(CartResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.cart.severe(`Failed to remove items from cart: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to remove items from cart: ${e}`));
    }
  }
}

/**
 * Search API client
 */
export class SearchClient extends ApiClient {
  /**
   * Get VIN data
   * @param {string} vin
   * @returns {Promise<Result<Object>>}
   */
  async vinData(vin) {
    try {
      const response = await this.get('/v3/search/vin', {
        queryParameters: { vin },
      });
      return Result.success(response.data);
    } catch (e) {
      GroupVanLogger.search.severe(`Failed to get VIN data: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get VIN data: ${e}`));
    }
  }
}

/**
 * User API client
 */
export class UserClient extends ApiClient {
  /**
   * Get location details
   * @param {string} locationId
   * @returns {Promise<Result<LocationDetails>>}
   */
  async getLocationDetails(locationId) {
    try {
      const response = await this.get(`/v3/user/location/${locationId}`);
      return Result.success(LocationDetails.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.user.severe(`Failed to get location details: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to get location details: ${e}`));
    }
  }
}

/**
 * Reports API client
 */
export class ReportsClient extends ApiClient {
  /**
   * Create a report
   * @param {Object} options
   * @param {Blob|ArrayBuffer} options.screenshot
   * @param {string} [options.message]
   * @returns {Promise<Result<void>>}
   */
  async createReport({ screenshot, message = null }) {
    try {
      const formData = new FormData();
      formData.append('screenshot', screenshot, 'screenshot.png');
      if (message) formData.append('message', message);

      await this.post('/v3/reports/', {
        data: formData,
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
      return Result.success(null);
    } catch (e) {
      GroupVanLogger.reports.severe(`Failed to create report: ${e}`);
      return Result.failure(e instanceof GroupVanException ? e : new NetworkException(`Failed to create report: ${e}`));
    }
  }
}

/**
 * Main GroupVAN SDK Client
 */
export class GroupVanClient {
  /**
   * @param {GroupVanClientConfig} config
   */
  constructor(config) {
    this._config = config;
    this._httpClient = null;
    this._authManager = null;
    this._vehiclesClient = null;
    this._catalogsClient = null;
    this._reportsClient = null;
    this._searchClient = null;
    this._cartClient = null;
    this._userClient = null;
  }

  /** @returns {GroupVanHttpClient} */
  get httpClient() { return this._httpClient; }

  /** @returns {AuthManager} */
  get auth() { return this._authManager; }

  /** @returns {VehiclesClient} */
  get vehicles() { return this._vehiclesClient; }

  /** @returns {CatalogsClient} */
  get catalogs() { return this._catalogsClient; }

  /** @returns {ReportsClient} */
  get reports() { return this._reportsClient; }

  /** @returns {SearchClient} */
  get search() { return this._searchClient; }

  /** @returns {CartClient} */
  get cart() { return this._cartClient; }

  /** @returns {UserClient} */
  get user() { return this._userClient; }

  /** @returns {import('./auth/auth_models.js').AuthStatus} */
  get authStatus() { return this._authManager?.currentStatus; }

  /** @returns {string|null} */
  get userId() { return this._authManager?.currentStatus?.claims?.userId || null; }

  /** @returns {string|null} */
  get clientId() { return this._config.clientId; }

  /**
   * Initialize the client
   * @returns {Promise<void>}
   */
  async initialize() {
    // Initialize logger if logging is enabled
    if (this._config.enableLogging) {
      GroupVanLogger.initialize({ level: LogLevel.ALL, enableConsoleOutput: true });
    }

    GroupVanLogger.sdk.warning('Starting GroupVAN SDK Client initialization...');

    // Initialize HTTP client
    this._httpClient = new GroupVanHttpClient(this._config.httpClientConfig);
    GroupVanLogger.sdk.warning('HTTP client initialized');

    // Initialize authentication manager
    this._authManager = new AuthManager({
      httpClient: this._httpClient,
      tokenStorage: this._config.tokenStorage,
    });
    GroupVanLogger.sdk.warning('Authentication manager created');

    // Initialize API clients
    this._vehiclesClient = new VehiclesClient(this._httpClient, this._authManager);
    this._catalogsClient = new CatalogsClient(this._httpClient, this._authManager);
    this._reportsClient = new ReportsClient(this._httpClient, this._authManager);
    this._searchClient = new SearchClient(this._httpClient, this._authManager);
    this._cartClient = new CartClient(this._httpClient, this._authManager);
    this._userClient = new UserClient(this._httpClient, this._authManager);
    GroupVanLogger.sdk.warning('API clients initialized');

    // Initialize authentication manager (restore tokens if available)
    GroupVanLogger.sdk.warning('Calling auth manager initialize...');
    await this._authManager.initialize(this._config.clientId);
    GroupVanLogger.sdk.warning('Auth manager initialization completed');

    GroupVanLogger.sdk.info('GroupVAN SDK Client initialized');
  }

  /**
   * Clean up resources
   */
  dispose() {
    this._authManager?.dispose();
    GroupVanLogger.sdk.info('GroupVAN SDK Client disposed');
  }

  /**
   * Ensure we have a valid authentication token
   * @returns {Promise<string>}
   */
  async getValidToken() {
    if (!this._authManager?.currentStatus?.isAuthenticated) {
      throw new AuthenticationException(
        'Not authenticated. Please call auth.login() first.',
        { errorType: AuthErrorType.MISSING_TOKEN }
      );
    }
    return this._authManager.currentStatus.accessToken;
  }
}

/**
 * Global GroupVAN singleton instance
 */
let _instance = null;

/**
 * GroupVAN SDK singleton access
 */
export const GroupVAN = {
  /**
   * Initialize the GroupVAN SDK
   * @param {Object} options
   * @param {string} options.clientId - Required client ID
   * @param {boolean} [options.isProduction=false] - Use production environment
   * @param {GroupVanClientConfig} [options.config] - Custom configuration
   * @returns {Promise<GroupVanClient>}
   */
  async initialize({ clientId, isProduction = false, config = null }) {
    if (_instance) {
      GroupVanLogger.sdk.warning('GroupVAN SDK already initialized, returning existing instance');
      return _instance;
    }

    const finalConfig = config || (isProduction
      ? GroupVanClientConfig.production({ clientId })
      : GroupVanClientConfig.staging({ clientId }));

    // Ensure clientId is set
    finalConfig.clientId = clientId;

    _instance = new GroupVanClient(finalConfig);
    await _instance.initialize();

    return _instance;
  },

  /**
   * Get the singleton instance
   * @returns {GroupVanClient}
   */
  get instance() {
    if (!_instance) {
      throw new Error('GroupVAN SDK not initialized. Call GroupVAN.initialize() first.');
    }
    return _instance;
  },

  /**
   * Get the client (shortcut for instance)
   * @returns {GroupVanClient}
   */
  get client() {
    return this.instance;
  },

  /**
   * Dispose the singleton instance
   */
  dispose() {
    if (_instance) {
      _instance.dispose();
      _instance = null;
    }
  },
};
