/**
 * GroupVAN SDK for JavaScript
 *
 * A comprehensive client library for the GroupVAN V3 API.
 *
 * @example
 * // Initialize the SDK
 * import { GroupVAN } from '@groupvan/sdk';
 *
 * await GroupVAN.initialize({
 *   clientId: 'your-client-id',
 *   isProduction: false,
 * });
 *
 * // Login
 * await GroupVAN.client.auth.login({
 *   email: 'user@example.com',
 *   password: 'password',
 *   clientId: 'your-client-id',
 * });
 *
 * // Use API clients
 * const result = await GroupVAN.client.vehicles.getVehicleGroups();
 * if (result.isSuccess) {
 *   console.log(result.value);
 * }
 */

// Main client exports
export {
  GroupVAN,
  GroupVanClient,
  GroupVanClientConfig,
  VehiclesClient,
  CatalogsClient,
  CartClient,
  SearchClient,
  UserClient,
  ReportsClient,
} from './client.js';

// Core exports
export {
  GroupVanException,
  NetworkException,
  HttpException,
  AuthenticationException,
  ValidationException,
  ValidationError,
  ConfigurationException,
  RateLimitException,
  DataException,
  AuthErrorType,
} from './core/exceptions.js';

export {
  Validator,
  StringValidator,
  IntValidator,
  ListValidator,
  ObjectValidator,
  ValidationPatterns,
  GroupVanValidators,
} from './core/validation.js';

export {
  GroupVanResponse,
  PaginatedResponse,
  RequestMetadata,
  ResponseMetadata,
  ResponseBuilder,
  Result,
} from './core/response.js';

export {
  GroupVanHttpClient,
  HttpClientConfig,
} from './core/http_client.js';

// Auth exports
export {
  AuthManager,
  TokenStorage,
  MemoryTokenStorage,
  LocalStorageTokenStorage,
  SessionStorageTokenStorage,
  SecureTokenStorage,
} from './auth/auth_manager.js';

export {
  LoginRequest,
  TokenResponse,
  RefreshTokenRequest,
  LogoutRequest,
  TokenClaims,
  AuthState,
  AuthStatus,
} from './auth/auth_models.js';

// Logging exports
export {
  GroupVanLogger,
  LogLevel,
} from './logging.js';

// Constants exports
export {
  CountryCode,
  CountryDivisionCode,
  getAllDivisions,
  getDivisionByAbbreviation,
  getDivisionByName,
  getDivisionsByCountry,
} from './constants.js';

// Model exports
export * from './models/index.js';
