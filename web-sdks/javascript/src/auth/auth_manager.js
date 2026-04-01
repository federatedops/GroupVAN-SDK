/**
 * JWT Authentication manager for GroupVAN SDK
 *
 * Handles login, token refresh, logout, and automatic token management.
 */

import { AuthenticationException, ConfigurationException, DataException, AuthErrorType } from '../core/exceptions.js';
import { GroupVanLogger } from '../logging.js';
import {
  LoginRequest,
  TokenResponse,
  RefreshTokenRequest,
  LogoutRequest,
  TokenClaims,
  AuthStatus,
} from './auth_models.js';
import { User } from '../models/auth.js';

/**
 * Token storage interface for different storage backends
 * @interface
 */
export class TokenStorage {
  /**
   * Store tokens securely
   * @param {Object} options
   * @param {string} options.accessToken
   * @param {string} options.refreshToken
   * @returns {Promise<void>}
   */
  async storeTokens({ accessToken, refreshToken }) {
    throw new Error('storeTokens() must be implemented');
  }

  /**
   * Retrieve stored tokens
   * @returns {Promise<{accessToken: string|null, refreshToken: string|null}>}
   */
  async getTokens() {
    throw new Error('getTokens() must be implemented');
  }

  /**
   * Clear stored tokens
   * @returns {Promise<void>}
   */
  async clearTokens() {
    throw new Error('clearTokens() must be implemented');
  }
}

/**
 * In-memory token storage (not recommended for production)
 */
export class MemoryTokenStorage extends TokenStorage {
  constructor() {
    super();
    this._accessToken = null;
    this._refreshToken = null;
  }

  async storeTokens({ accessToken, refreshToken }) {
    this._accessToken = accessToken;
    this._refreshToken = refreshToken;
  }

  async getTokens() {
    return {
      accessToken: this._accessToken,
      refreshToken: this._refreshToken,
    };
  }

  async clearTokens() {
    this._accessToken = null;
    this._refreshToken = null;
  }
}

/**
 * LocalStorage-based token storage (for web browsers)
 */
export class LocalStorageTokenStorage extends TokenStorage {
  constructor(prefix = 'groupvan') {
    super();
    this._accessTokenKey = `${prefix}_access_token`;
    this._refreshTokenKey = `${prefix}_refresh_token`;
  }

  async storeTokens({ accessToken, refreshToken }) {
    try {
      localStorage.setItem(this._accessTokenKey, accessToken);
      localStorage.setItem(this._refreshTokenKey, refreshToken);
    } catch (e) {
      throw new ConfigurationException(
        `Failed to store tokens: ${e.message}`,
        { context: { operation: 'storeTokens' } }
      );
    }
  }

  async getTokens() {
    try {
      return {
        accessToken: localStorage.getItem(this._accessTokenKey),
        refreshToken: localStorage.getItem(this._refreshTokenKey),
      };
    } catch (e) {
      return { accessToken: null, refreshToken: null };
    }
  }

  async clearTokens() {
    try {
      localStorage.removeItem(this._accessTokenKey);
      localStorage.removeItem(this._refreshTokenKey);
    } catch (e) {
      throw new ConfigurationException(
        `Failed to clear tokens: ${e.message}`,
        { context: { operation: 'clearTokens' } }
      );
    }
  }
}

/**
 * SessionStorage-based token storage (for web browsers, clears on tab close)
 */
export class SessionStorageTokenStorage extends TokenStorage {
  constructor(prefix = 'groupvan') {
    super();
    this._accessTokenKey = `${prefix}_access_token`;
    this._refreshTokenKey = `${prefix}_refresh_token`;
  }

  async storeTokens({ accessToken, refreshToken }) {
    try {
      sessionStorage.setItem(this._accessTokenKey, accessToken);
      sessionStorage.setItem(this._refreshTokenKey, refreshToken);
    } catch (e) {
      throw new ConfigurationException(
        `Failed to store tokens: ${e.message}`,
        { context: { operation: 'storeTokens' } }
      );
    }
  }

  async getTokens() {
    try {
      return {
        accessToken: sessionStorage.getItem(this._accessTokenKey),
        refreshToken: sessionStorage.getItem(this._refreshTokenKey),
      };
    } catch (e) {
      return { accessToken: null, refreshToken: null };
    }
  }

  async clearTokens() {
    try {
      sessionStorage.removeItem(this._accessTokenKey);
      sessionStorage.removeItem(this._refreshTokenKey);
    } catch (e) {
      throw new ConfigurationException(
        `Failed to clear tokens: ${e.message}`,
        { context: { operation: 'clearTokens' } }
      );
    }
  }
}

/**
 * Secure token storage using Web Crypto API for encryption.
 * Similar to flutter_secure_storage, this encrypts tokens before storing.
 * Uses AES-GCM encryption with a key derived from a randomly generated secret.
 */
export class SecureTokenStorage extends TokenStorage {
  /**
   * @param {Object} [options]
   * @param {string} [options.prefix='groupvan'] - Storage key prefix
   * @param {Storage} [options.storage] - Storage backend (defaults to localStorage)
   */
  constructor(options = {}) {
    super();
    const { prefix = 'groupvan', storage = null } = options;
    this._prefix = prefix;
    this._accessTokenKey = `${prefix}_secure_access_token`;
    this._refreshTokenKey = `${prefix}_secure_refresh_token`;
    this._keyKey = `${prefix}_secure_key`;
    this._storage = storage;
    this._cryptoKey = null;
    this._initialized = false;
  }

  /**
   * Get the storage backend
   * @returns {Storage}
   */
  _getStorage() {
    if (this._storage) {
      return this._storage;
    }
    if (typeof localStorage !== 'undefined') {
      return localStorage;
    }
    throw new ConfigurationException(
      'SecureTokenStorage requires localStorage or a custom storage backend',
      { context: { operation: 'getStorage' } }
    );
  }

  /**
   * Check if Web Crypto API is available
   * @returns {boolean}
   */
  static isSupported() {
    return typeof crypto !== 'undefined' &&
           typeof crypto.subtle !== 'undefined' &&
           typeof crypto.getRandomValues !== 'undefined';
  }

  /**
   * Initialize the crypto key
   * @returns {Promise<void>}
   */
  async _initialize() {
    if (this._initialized) {
      return;
    }

    if (!SecureTokenStorage.isSupported()) {
      throw new ConfigurationException(
        'Web Crypto API is not available. SecureTokenStorage requires a secure context (HTTPS).',
        { context: { operation: 'initialize' } }
      );
    }

    try {
      const storage = this._getStorage();
      const existingKeyData = storage.getItem(this._keyKey);

      if (existingKeyData) {
        // Restore existing key
        const keyData = JSON.parse(existingKeyData);
        const rawKey = this._base64ToArrayBuffer(keyData.key);
        this._cryptoKey = await crypto.subtle.importKey(
          'raw',
          rawKey,
          { name: 'AES-GCM', length: 256 },
          false,
          ['encrypt', 'decrypt']
        );
      } else {
        // Generate new key
        this._cryptoKey = await crypto.subtle.generateKey(
          { name: 'AES-GCM', length: 256 },
          true,
          ['encrypt', 'decrypt']
        );

        // Export and store the key
        const exportedKey = await crypto.subtle.exportKey('raw', this._cryptoKey);
        const keyData = {
          key: this._arrayBufferToBase64(exportedKey),
          algorithm: 'AES-GCM',
          created: Date.now(),
        };
        storage.setItem(this._keyKey, JSON.stringify(keyData));
      }

      this._initialized = true;
    } catch (e) {
      throw new ConfigurationException(
        `Failed to initialize secure storage: ${e.message}`,
        { context: { operation: 'initialize', error: e.toString() } }
      );
    }
  }

  /**
   * Encrypt a value using AES-GCM
   * @param {string} plaintext
   * @returns {Promise<string>}
   */
  async _encrypt(plaintext) {
    await this._initialize();

    const iv = crypto.getRandomValues(new Uint8Array(12));
    const encodedData = new TextEncoder().encode(plaintext);

    const encryptedData = await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv },
      this._cryptoKey,
      encodedData
    );

    // Combine IV and encrypted data
    const combined = new Uint8Array(iv.length + encryptedData.byteLength);
    combined.set(iv);
    combined.set(new Uint8Array(encryptedData), iv.length);

    return this._arrayBufferToBase64(combined.buffer);
  }

  /**
   * Decrypt a value using AES-GCM
   * @param {string} ciphertext
   * @returns {Promise<string>}
   */
  async _decrypt(ciphertext) {
    await this._initialize();

    const combined = new Uint8Array(this._base64ToArrayBuffer(ciphertext));

    // Extract IV and encrypted data
    const iv = combined.slice(0, 12);
    const encryptedData = combined.slice(12);

    const decryptedData = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv },
      this._cryptoKey,
      encryptedData
    );

    return new TextDecoder().decode(decryptedData);
  }

  /**
   * Convert ArrayBuffer to base64 string
   * @param {ArrayBuffer} buffer
   * @returns {string}
   */
  _arrayBufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
  }

  /**
   * Convert base64 string to ArrayBuffer
   * @param {string} base64
   * @returns {ArrayBuffer}
   */
  _base64ToArrayBuffer(base64) {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
  }

  /**
   * Store tokens securely with encryption
   * @param {Object} options
   * @param {string} options.accessToken
   * @param {string} options.refreshToken
   * @returns {Promise<void>}
   */
  async storeTokens({ accessToken, refreshToken }) {
    try {
      const storage = this._getStorage();
      const encryptedAccessToken = await this._encrypt(accessToken);
      const encryptedRefreshToken = await this._encrypt(refreshToken);

      storage.setItem(this._accessTokenKey, encryptedAccessToken);
      storage.setItem(this._refreshTokenKey, encryptedRefreshToken);
    } catch (e) {
      throw new ConfigurationException(
        `Failed to store tokens securely: ${e.message}`,
        { context: { operation: 'storeTokens' } }
      );
    }
  }

  /**
   * Retrieve and decrypt stored tokens
   * @returns {Promise<{accessToken: string|null, refreshToken: string|null}>}
   */
  async getTokens() {
    try {
      const storage = this._getStorage();
      const encryptedAccessToken = storage.getItem(this._accessTokenKey);
      const encryptedRefreshToken = storage.getItem(this._refreshTokenKey);

      if (!encryptedAccessToken || !encryptedRefreshToken) {
        return { accessToken: null, refreshToken: null };
      }

      const accessToken = await this._decrypt(encryptedAccessToken);
      const refreshToken = await this._decrypt(encryptedRefreshToken);

      return { accessToken, refreshToken };
    } catch (e) {
      // If decryption fails, tokens may be corrupted - clear them
      GroupVanLogger.auth.warning(`Failed to decrypt tokens, clearing: ${e.message}`);
      await this.clearTokens();
      return { accessToken: null, refreshToken: null };
    }
  }

  /**
   * Clear stored tokens and optionally the encryption key
   * @param {Object} [options]
   * @param {boolean} [options.clearKey=false] - Also clear the encryption key
   * @returns {Promise<void>}
   */
  async clearTokens({ clearKey = false } = {}) {
    try {
      const storage = this._getStorage();
      storage.removeItem(this._accessTokenKey);
      storage.removeItem(this._refreshTokenKey);

      if (clearKey) {
        storage.removeItem(this._keyKey);
        this._cryptoKey = null;
        this._initialized = false;
      }
    } catch (e) {
      throw new ConfigurationException(
        `Failed to clear tokens: ${e.message}`,
        { context: { operation: 'clearTokens' } }
      );
    }
  }
}

/**
 * Simple event emitter for auth status changes
 */
class EventEmitter {
  constructor() {
    this._listeners = new Set();
  }

  subscribe(listener) {
    this._listeners.add(listener);
    return () => this._listeners.delete(listener);
  }

  emit(value) {
    for (const listener of this._listeners) {
      try {
        listener(value);
      } catch (e) {
        console.error('Error in auth status listener:', e);
      }
    }
  }
}

/**
 * JWT Authentication Manager
 */
export class AuthManager {
  /**
   * @param {Object} options
   * @param {import('../core/http_client.js').GroupVanHttpClient} options.httpClient
   * @param {TokenStorage} [options.tokenStorage]
   */
  constructor({ httpClient, tokenStorage = null }) {
    this._httpClient = httpClient;
    this._tokenStorage = tokenStorage || new MemoryTokenStorage();
    this._statusEmitter = new EventEmitter();
    this._currentStatus = AuthStatus.unauthenticated();
    this._refreshTimer = null;
    this._refreshPromise = null;

    // Emit initial state
    this._statusEmitter.emit(this._currentStatus);
  }

  /**
   * Subscribe to authentication status changes
   * @param {function(AuthStatus): void} listener
   * @returns {function(): void} Unsubscribe function
   */
  onAuthStateChange(listener) {
    // Immediately provide current status
    listener(this._currentStatus);
    return this._statusEmitter.subscribe(listener);
  }

  /**
   * Current authentication status
   * @returns {AuthStatus}
   */
  get currentStatus() {
    return this._currentStatus;
  }

  /**
   * Whether currently authenticated with valid tokens
   * @returns {boolean}
   */
  get isAuthenticated() {
    return this._currentStatus.isAuthenticated;
  }

  /**
   * Current access token (if authenticated)
   * @returns {string|null}
   */
  get accessToken() {
    return this._currentStatus.accessToken;
  }

  /**
   * Current user ID from token claims
   * @returns {string|null}
   */
  get userId() {
    return this._currentStatus.claims?.userId || null;
  }

  /**
   * Initialize authentication manager
   * @param {string} clientId
   * @returns {Promise<void>}
   */
  async initialize(clientId) {
    GroupVanLogger.auth.warning('Starting authentication initialization...');

    try {
      const tokens = await this._tokenStorage.getTokens();

      if (tokens.accessToken && tokens.refreshToken) {
        GroupVanLogger.auth.warning('Both tokens found, attempting to validate and restore...');
        await this._validateAndRestoreTokens(tokens.accessToken, tokens.refreshToken);
      } else {
        // No stored tokens, check for OAuth callback
        if (typeof window !== 'undefined') {
          const url = new URL(window.location.href);
          const code = url.searchParams.get('code');
          const state = url.searchParams.get('state');
          const provider = url.searchParams.get('provider');

          if (code && state && provider) {
            await this._handleProviderCallback(provider, code, state, clientId);
          } else {
            await this._updateStatus(AuthStatus.unauthenticated());
          }
        } else {
          await this._updateStatus(AuthStatus.unauthenticated());
        }
      }
    } catch (e) {
      if (e instanceof AuthenticationException && e.errorType === AuthErrorType.ACCOUNT_NOT_LINKED) {
        // Let this propagate
      }
      GroupVanLogger.auth.warning(`Failed to restore authentication state: ${e}`);
      await this._updateStatus(AuthStatus.unauthenticated());
    }

    GroupVanLogger.auth.warning(`Authentication initialization completed with status: ${this._currentStatus.state}`);
  }

  /**
   * Login with email and password
   * @param {Object} options
   * @param {string} options.email
   * @param {string} options.password
   * @param {string} options.clientId
   * @returns {Promise<void>}
   */
  async login({ email, password, clientId }) {
    await this._updateStatus(AuthStatus.authenticating());

    try {
      const request = new LoginRequest({ email, password });

      const response = await this._httpClient.post('/auth/login', {
        data: request.toJson(),
        headers: { 'gv-client-id': clientId },
      });

      const user = User.fromJson(response.data.user);
      const tokenResponse = TokenResponse.fromJson(response.data);

      await this._handleTokenResponse(tokenResponse, user);
    } catch (e) {
      const error = `Login failed: ${e.toString()}`;
      GroupVanLogger.auth.severe(error);
      await this._updateStatus(AuthStatus.failed({ error }));
      throw e;
    }
  }

  /**
   * Initiate Google OAuth login (browser only)
   */
  loginWithGoogle() {
    if (typeof window !== 'undefined') {
      window.location.href = `${this._httpClient.baseUrl}/auth/google/login?catalog_uri=${this._httpClient.origin}`;
    }
  }

  /**
   * Handle OAuth provider callback
   * @param {string} provider
   * @param {string} code
   * @param {string} state
   * @param {string} clientId
   */
  async _handleProviderCallback(provider, code, state, clientId) {
    try {
      GroupVanLogger.auth.info(`Handling provider callback: ${provider}`);

      const response = await this._httpClient.get(
        `/auth/${provider}/callback`,
        {
          queryParameters: {
            code,
            state,
            catalog_uri: this._httpClient.origin,
          },
          headers: { 'gv-client-id': clientId },
        }
      );

      const user = User.fromJson(response.data.user);
      const tokenResponse = TokenResponse.fromJson(response.data);

      await this._handleTokenResponse(tokenResponse, user);
    } catch (e) {
      if (e instanceof AuthenticationException && e.errorType === AuthErrorType.ACCOUNT_NOT_LINKED) {
        const metadata = e.context || {};
        metadata.provider = provider;
        await this._updateStatus(AuthStatus.failed({ error: 'account_not_linked', metadata }));
        return;
      }
      GroupVanLogger.auth.severe(`Failed to handle provider callback: ${e}`);
      throw e;
    }
  }

  /**
   * Link FedLink account
   * @param {Object} options
   * @param {string} options.email
   * @param {string} options.username
   * @param {string} options.password
   * @param {string} options.clientId
   * @param {boolean} [options.fromProvider=false]
   * @returns {Promise<void>}
   */
  async linkFedLinkAccount({ email, username, password, clientId, fromProvider = false }) {
    try {
      const response = await this._httpClient.post('/auth/migrate/email', {
        data: {
          email,
          username,
          password,
          from_provider: fromProvider,
        },
        headers: { 'gv-client-id': clientId },
      });

      if (!response.data.success) {
        throw new AuthenticationException(
          response.data.message,
          { errorType: AuthErrorType.INVALID_CREDENTIALS }
        );
      }
    } catch (e) {
      GroupVanLogger.auth.severe(`Failed to link FedLink account: ${e}`);
      throw e;
    }
  }

  /**
   * Handle token response after successful authentication
   * @param {TokenResponse} tokenResponse
   * @param {User} [user]
   */
  async _handleTokenResponse(tokenResponse, user = null) {
    GroupVanLogger.auth.warning('Storing tokens after successful login...');

    await this._tokenStorage.storeTokens({
      accessToken: tokenResponse.accessToken,
      refreshToken: tokenResponse.refreshToken,
    });

    // Update HTTP client token
    this._httpClient.updateToken(tokenResponse.accessToken);

    // Decode token claims
    const claims = this._decodeToken(tokenResponse.accessToken);

    await this._updateStatus(
      AuthStatus.authenticated({
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        claims,
        userInfo: user || this._currentStatus.userInfo,
      })
    );

    // Schedule automatic refresh
    this._scheduleTokenRefresh(claims);

    GroupVanLogger.auth.warning(`Successfully authenticated user: ${claims.userId}`);
  }

  /**
   * Refresh access token using refresh token
   * @returns {Promise<void>}
   */
  async refreshToken() {
    // Prevent concurrent refresh operations
    if (this._refreshPromise) {
      await this._refreshPromise;
      return;
    }

    this._refreshPromise = this._doRefreshToken();

    try {
      await this._refreshPromise;
    } finally {
      this._refreshPromise = null;
    }
  }

  async _doRefreshToken() {
    try {
      const currentTokens = await this._tokenStorage.getTokens();

      if (!currentTokens.refreshToken) {
        throw new AuthenticationException(
          'No refresh token available',
          { errorType: AuthErrorType.MISSING_TOKEN }
        );
      }

      const request = new RefreshTokenRequest({ refreshToken: currentTokens.refreshToken });

      const response = await this._httpClient.post('/auth/refresh', {
        data: request.toJson(),
      });

      const user = User.fromJson(response.data.user);
      const tokenResponse = TokenResponse.fromJson(response.data);

      await this._handleTokenResponse(tokenResponse, user);

      GroupVanLogger.auth.info('Successfully refreshed tokens');
    } catch (e) {
      const error = `Token refresh failed: ${e.toString()}`;
      GroupVanLogger.auth.severe(error);

      // If refresh fails, mark as expired and clear tokens
      await this._updateStatus(
        AuthStatus.expired({
          error,
          accessToken: this._currentStatus.accessToken,
          refreshToken: this._currentStatus.refreshToken,
          authenticatedAt: this._currentStatus.authenticatedAt,
          refreshedAt: this._currentStatus.refreshedAt,
        })
      );
      await this._tokenStorage.clearTokens();

      throw e;
    }
  }

  /**
   * Logout and clear all authentication state
   * @returns {Promise<void>}
   */
  async logout() {
    try {
      const currentTokens = await this._tokenStorage.getTokens();

      if (currentTokens.refreshToken) {
        const request = new LogoutRequest({ refreshToken: currentTokens.refreshToken });

        await this._httpClient.post('/auth/logout', {
          data: request.toJson(),
          headers: {
            'Authorization': `Bearer ${currentTokens.accessToken}`,
          },
        });
      }
    } catch (e) {
      GroupVanLogger.auth.warning(`Logout request failed: ${e}`);
      // Continue with local cleanup even if server request fails
    }

    // Clear local state
    await this._clearAuthenticationState();
    GroupVanLogger.auth.info('Successfully logged out');
  }

  /**
   * Get current valid access token, refreshing if necessary
   * @returns {Promise<string>}
   */
  async getValidAccessToken() {
    // Check if we need to refresh the token
    if (this._currentStatus.needsRefresh) {
      await this.refreshToken();
    }

    if (!this.isAuthenticated || !this._currentStatus.accessToken) {
      throw new AuthenticationException(
        'No valid access token available',
        { errorType: AuthErrorType.MISSING_TOKEN }
      );
    }

    return this._currentStatus.accessToken;
  }

  /**
   * Validate and restore tokens from storage
   * @param {string} accessToken
   * @param {string} refreshToken
   */
  async _validateAndRestoreTokens(accessToken, refreshToken) {
    try {
      GroupVanLogger.auth.warning('Decoding access token...');
      const claims = this._decodeToken(accessToken);

      GroupVanLogger.auth.warning(
        `Token claims - userId: ${claims.userId}, expiration: ${new Date(claims.expiration * 1000)}, isExpired: ${claims.isExpired}`
      );

      await this._tokenStorage.storeTokens({ accessToken, refreshToken });
      this._httpClient.updateToken(accessToken);

      // Always refresh on restore to get fresh tokens
      await this.refreshToken();

      GroupVanLogger.auth.warning('Token refresh completed');
    } catch (e) {
      GroupVanLogger.auth.warning(`Token validation failed: ${e}`);
      await this._clearAuthenticationState();
      throw e;
    }
  }

  /**
   * Decode JWT token claims
   * @param {string} token
   * @returns {TokenClaims}
   */
  _decodeToken(token) {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) {
        throw new Error('Invalid JWT format');
      }

      // Decode the payload (second part)
      let payload = parts[1];

      // Add padding if needed for base64 decoding
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      // Handle URL-safe base64
      payload = payload.replace(/-/g, '+').replace(/_/g, '/');

      const decoded = atob(payload);
      const jsonData = JSON.parse(decoded);

      return TokenClaims.fromJson(jsonData);
    } catch (e) {
      throw new DataException(
        `Failed to decode JWT token: ${e.toString()}`,
        { dataType: 'JWT', originalData: token }
      );
    }
  }

  /**
   * Schedule automatic token refresh
   * @param {TokenClaims} claims
   */
  _scheduleTokenRefresh(claims) {
    if (this._refreshTimer) {
      clearTimeout(this._refreshTimer);
    }

    // Schedule refresh 2 minutes before expiration
    const timeUntilExpiration = claims.timeUntilExpirationMs;
    const refreshBuffer = 2 * 60 * 1000; // 2 minutes
    const refreshTime = timeUntilExpiration - refreshBuffer;

    if (refreshTime > 0) {
      this._refreshTimer = setTimeout(async () => {
        try {
          GroupVanLogger.auth.info('Attempting to refresh token');
          await this.refreshToken();
        } catch (e) {
          GroupVanLogger.auth.severe(`Automatic token refresh failed: ${e}`);
        }
      }, refreshTime);

      GroupVanLogger.auth.fine(`Scheduled token refresh in ${Math.round(refreshTime / 60000)} minutes`);
    }
  }

  /**
   * Update authentication status and notify listeners
   * @param {AuthStatus} newStatus
   */
  async _updateStatus(newStatus) {
    this._currentStatus = newStatus;
    this._statusEmitter.emit(newStatus);
  }

  /**
   * Clear all authentication state
   */
  async _clearAuthenticationState() {
    if (this._refreshTimer) {
      clearTimeout(this._refreshTimer);
      this._refreshTimer = null;
    }
    await this._tokenStorage.clearTokens();
    this._httpClient.updateToken(null);
    await this._updateStatus(AuthStatus.unauthenticated());
  }

  /**
   * Dispose resources
   */
  dispose() {
    if (this._refreshTimer) {
      clearTimeout(this._refreshTimer);
    }
  }
}
