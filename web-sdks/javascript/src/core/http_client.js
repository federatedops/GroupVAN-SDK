/**
 * Professional HTTP client implementation using fetch
 *
 * Provides enterprise-grade HTTP functionality with interceptors,
 * retry logic, caching, and comprehensive error handling.
 */

import {
  NetworkException,
  HttpException,
  AuthenticationException,
  RateLimitException,
  AuthErrorType,
} from './exceptions.js';
import { GroupVanResponse, RequestMetadata, ResponseMetadata } from './response.js';
import { GroupVanLogger } from '../logging.js';

/**
 * Generate a UUID v4
 * @returns {string}
 */
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

/**
 * Configuration for the HTTP client
 */
export class HttpClientConfig {
  /**
   * @param {Object} options
   * @param {string} options.baseUrl - Base URL for API requests
   * @param {number} [options.timeoutMs=30000] - Default timeout for requests in milliseconds
   * @param {number} [options.connectTimeoutMs=10000] - Default timeout for connections
   * @param {number} [options.maxRetries=3] - Maximum number of retry attempts
   * @param {boolean} [options.enableLogging=true] - Enable request/response logging
   * @param {boolean} [options.enableCaching=true] - Enable caching
   * @param {number} [options.cacheDurationMs=300000] - Default cache duration (5 minutes)
   * @param {string} [options.token] - API token for authentication
   * @param {Object} [options.defaultHeaders={}] - Additional default headers
   */
  constructor({
    baseUrl,
    timeoutMs = 30000,
    connectTimeoutMs = 10000,
    maxRetries = 3,
    enableLogging = true,
    enableCaching = true,
    cacheDurationMs = 300000,
    token = null,
    defaultHeaders = {},
  }) {
    this.baseUrl = baseUrl;
    this.timeoutMs = timeoutMs;
    this.connectTimeoutMs = connectTimeoutMs;
    this.maxRetries = maxRetries;
    this.enableLogging = enableLogging;
    this.enableCaching = enableCaching;
    this.cacheDurationMs = cacheDurationMs;
    this.token = token;
    this.defaultHeaders = defaultHeaders;
  }

  /**
   * Create a copy with new values
   * @param {Partial<HttpClientConfig>} overrides
   * @returns {HttpClientConfig}
   */
  copyWith(overrides = {}) {
    return new HttpClientConfig({
      baseUrl: overrides.baseUrl ?? this.baseUrl,
      timeoutMs: overrides.timeoutMs ?? this.timeoutMs,
      connectTimeoutMs: overrides.connectTimeoutMs ?? this.connectTimeoutMs,
      maxRetries: overrides.maxRetries ?? this.maxRetries,
      enableLogging: overrides.enableLogging ?? this.enableLogging,
      enableCaching: overrides.enableCaching ?? this.enableCaching,
      cacheDurationMs: overrides.cacheDurationMs ?? this.cacheDurationMs,
      token: overrides.token ?? this.token,
      defaultHeaders: overrides.defaultHeaders ?? this.defaultHeaders,
    });
  }
}

/**
 * Simple in-memory cache
 */
class MemoryCache {
  constructor() {
    this._cache = new Map();
  }

  /**
   * @param {string} key
   * @param {*} value
   * @param {number} ttlMs - Time to live in milliseconds
   */
  set(key, value, ttlMs) {
    this._cache.set(key, {
      value,
      expiresAt: Date.now() + ttlMs,
    });
  }

  /**
   * @param {string} key
   * @returns {*|null}
   */
  get(key) {
    const entry = this._cache.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      this._cache.delete(key);
      return null;
    }
    return entry.value;
  }

  /**
   * @param {string} key
   */
  delete(key) {
    this._cache.delete(key);
  }

  clear() {
    this._cache.clear();
  }
}

/**
 * Professional HTTP client using fetch
 */
export class GroupVanHttpClient {
  /**
   * @param {HttpClientConfig} config
   */
  constructor(config) {
    this._config = config;
    this._cache = new MemoryCache();
    this._token = config.token;
  }

  /**
   * Get the base URL
   * @returns {string}
   */
  get baseUrl() {
    return this._config.baseUrl;
  }

  /**
   * Get the current origin (browser only)
   * @returns {string}
   */
  get origin() {
    if (typeof window !== 'undefined') {
      return window.location.origin;
    }
    return '';
  }

  /**
   * Update the authentication token
   * @param {string|null} token
   */
  updateToken(token) {
    this._token = token;
  }

  /**
   * Build headers for a request
   * @param {Object} [additionalHeaders={}]
   * @returns {Object}
   */
  _buildHeaders(additionalHeaders = {}) {
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...this._config.defaultHeaders,
      ...additionalHeaders,
    };

    if (this._token) {
      headers['Authorization'] = `Bearer ${this._token}`;
    }

    return headers;
  }

  /**
   * Make a GET request
   * @template T
   * @param {string} path
   * @param {Object} [options={}]
   * @param {Object} [options.queryParameters]
   * @param {Object} [options.headers]
   * @param {AbortSignal} [options.signal]
   * @param {function(*): T} [options.decoder]
   * @returns {Promise<GroupVanResponse<T>>}
   */
  async get(path, { queryParameters = null, headers = {}, signal = null, decoder = null } = {}) {
    return this._request('GET', path, { queryParameters, headers, signal, decoder });
  }

  /**
   * Make a POST request
   * @template T
   * @param {string} path
   * @param {Object} [options={}]
   * @param {*} [options.data]
   * @param {Object} [options.queryParameters]
   * @param {Object} [options.headers]
   * @param {AbortSignal} [options.signal]
   * @param {function(*): T} [options.decoder]
   * @returns {Promise<GroupVanResponse<T>>}
   */
  async post(path, { data = null, queryParameters = null, headers = {}, signal = null, decoder = null } = {}) {
    return this._request('POST', path, { data, queryParameters, headers, signal, decoder });
  }

  /**
   * Make a PUT request
   * @template T
   * @param {string} path
   * @param {Object} [options={}]
   * @param {*} [options.data]
   * @param {Object} [options.queryParameters]
   * @param {Object} [options.headers]
   * @param {AbortSignal} [options.signal]
   * @param {function(*): T} [options.decoder]
   * @returns {Promise<GroupVanResponse<T>>}
   */
  async put(path, { data = null, queryParameters = null, headers = {}, signal = null, decoder = null } = {}) {
    return this._request('PUT', path, { data, queryParameters, headers, signal, decoder });
  }

  /**
   * Make a PATCH request
   * @template T
   * @param {string} path
   * @param {Object} [options={}]
   * @param {*} [options.data]
   * @param {Object} [options.queryParameters]
   * @param {Object} [options.headers]
   * @param {AbortSignal} [options.signal]
   * @param {function(*): T} [options.decoder]
   * @returns {Promise<GroupVanResponse<T>>}
   */
  async patch(path, { data = null, queryParameters = null, headers = {}, signal = null, decoder = null } = {}) {
    return this._request('PATCH', path, { data, queryParameters, headers, signal, decoder });
  }

  /**
   * Make a DELETE request
   * @template T
   * @param {string} path
   * @param {Object} [options={}]
   * @param {*} [options.data]
   * @param {Object} [options.queryParameters]
   * @param {Object} [options.headers]
   * @param {AbortSignal} [options.signal]
   * @param {function(*): T} [options.decoder]
   * @returns {Promise<GroupVanResponse<T>>}
   */
  async delete(path, { data = null, queryParameters = null, headers = {}, signal = null, decoder = null } = {}) {
    return this._request('DELETE', path, { data, queryParameters, headers, signal, decoder });
  }

  /**
   * Internal request method with retry logic
   * @template T
   * @param {string} method
   * @param {string} path
   * @param {Object} options
   * @returns {Promise<GroupVanResponse<T>>}
   */
  async _request(method, path, { data = null, queryParameters = null, headers = {}, signal = null, decoder = null }) {
    const correlationId = generateUUID();
    const startTime = new Date();

    // Build URL
    let url = `${this._config.baseUrl}${path}`;
    if (queryParameters) {
      const params = new URLSearchParams();
      for (const [key, value] of Object.entries(queryParameters)) {
        if (value !== null && value !== undefined) {
          params.append(key, String(value));
        }
      }
      const queryString = params.toString();
      if (queryString) {
        url += `?${queryString}`;
      }
    }

    // Build headers
    const requestHeaders = this._buildHeaders(headers);
    requestHeaders['X-Correlation-ID'] = correlationId;

    // Log request
    if (this._config.enableLogging) {
      GroupVanLogger.apiClient.fine(`[${correlationId}] ${method} ${url}`);
      if (data) {
        GroupVanLogger.apiClient.finest(`[${correlationId}] Request body:`, data);
      }
    }

    // Retry loop
    let lastError = null;
    for (let attempt = 0; attempt <= this._config.maxRetries; attempt++) {
      try {
        // Create abort controller for timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this._config.timeoutMs);

        const fetchOptions = {
          method,
          headers: requestHeaders,
          signal: signal || controller.signal,
        };

        if (data !== null && ['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
          fetchOptions.body = JSON.stringify(data);
        }

        const response = await fetch(url, fetchOptions);
        clearTimeout(timeoutId);

        const endTime = new Date();
        const durationMs = endTime.getTime() - startTime.getTime();

        // Parse response
        let responseData;
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
          responseData = await response.json();
        } else {
          responseData = await response.text();
        }

        // Log response
        if (this._config.enableLogging) {
          GroupVanLogger.apiClient.fine(
            `[${correlationId}] Response: ${response.status} (${JSON.stringify(responseData).length} bytes)`
          );
        }

        // Check for errors
        if (!response.ok) {
          throw this._handleHttpError(response, responseData, url, method, correlationId);
        }

        // Decode data if decoder provided
        const decodedData = decoder ? decoder(responseData) : responseData;

        // Build response metadata
        const responseHeaders = {};
        response.headers.forEach((value, key) => {
          responseHeaders[key] = value;
        });

        return new GroupVanResponse({
          data: decodedData,
          statusCode: response.status,
          headers: responseHeaders,
          requestMetadata: new RequestMetadata({
            method,
            url,
            headers: requestHeaders,
            body: data,
            timestamp: startTime,
            timeout: this._config.timeoutMs,
            retryAttempt: attempt,
            correlationId,
          }),
          responseMetadata: new ResponseMetadata({
            timestamp: endTime,
            durationMs,
            sizeBytes: responseHeaders['content-length'] ? parseInt(responseHeaders['content-length']) : null,
            compressed: responseHeaders['content-encoding'] === 'gzip',
            encoding: responseHeaders['content-encoding'],
            server: responseHeaders['server'],
            correlationId,
          }),
          fromCache: false,
        });
      } catch (error) {
        lastError = error;

        // Don't retry if it's a non-retryable error
        if (error instanceof HttpException && !error.isRetryable) {
          throw error;
        }
        if (error instanceof AuthenticationException) {
          throw error;
        }

        // Check if we should retry
        if (attempt < this._config.maxRetries && this._shouldRetry(error)) {
          const delay = this._calculateRetryDelay(attempt);
          if (this._config.enableLogging) {
            GroupVanLogger.apiClient.info(
              `[${correlationId}] Retrying request ${attempt + 1}/${this._config.maxRetries} after ${delay}ms`
            );
          }
          await this._sleep(delay);
          continue;
        }

        throw error;
      }
    }

    throw lastError;
  }

  /**
   * Determine if an error is retryable
   * @param {Error} error
   * @returns {boolean}
   */
  _shouldRetry(error) {
    if (error.name === 'AbortError') {
      return true; // Timeout
    }
    if (error instanceof NetworkException) {
      return true;
    }
    if (error instanceof HttpException) {
      return error.isRetryable;
    }
    if (error instanceof RateLimitException) {
      return true;
    }
    return false;
  }

  /**
   * Calculate retry delay with exponential backoff
   * @param {number} attempt
   * @returns {number} Delay in milliseconds
   */
  _calculateRetryDelay(attempt) {
    const baseDelay = 1000;
    const multiplier = 2;
    return Math.round(baseDelay * Math.pow(multiplier, attempt));
  }

  /**
   * Sleep for a given duration
   * @param {number} ms
   * @returns {Promise<void>}
   */
  _sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Handle HTTP error responses
   * @param {Response} response
   * @param {*} responseData
   * @param {string} url
   * @param {string} method
   * @param {string} correlationId
   * @returns {Error}
   */
  _handleHttpError(response, responseData, url, method, correlationId) {
    const statusCode = response.status;
    const responseBody = typeof responseData === 'string' ? responseData : JSON.stringify(responseData);

    // Handle specific error types
    if (statusCode === 400 && responseData?.title === 'User not found') {
      const email = responseData?.detail?.split(' ')[1] || '';
      return new AuthenticationException(
        'FedLink account must be linked to sign in.',
        {
          errorType: AuthErrorType.ACCOUNT_NOT_LINKED,
          context: { correlationId, email },
        }
      );
    }

    if (statusCode === 401) {
      return new AuthenticationException(
        `Authentication failed: ${responseData?.message || 'Invalid token'}`,
        {
          errorType: AuthErrorType.INVALID_TOKEN,
          context: { correlationId },
        }
      );
    }

    if (statusCode === 403) {
      return new AuthenticationException(
        `Access forbidden: ${responseData?.message || 'Insufficient permissions'}`,
        {
          errorType: AuthErrorType.INSUFFICIENT_PERMISSIONS,
          context: { correlationId },
        }
      );
    }

    if (statusCode === 429) {
      const retryAfter = response.headers.get('retry-after');
      return new RateLimitException(
        `Rate limit exceeded`,
        {
          retryAfterSeconds: retryAfter ? parseInt(retryAfter) : null,
          context: { correlationId },
        }
      );
    }

    return new HttpException(
      responseData?.message || `HTTP error ${statusCode}`,
      {
        statusCode,
        endpoint: url,
        method,
        responseBody,
        context: { correlationId },
      }
    );
  }

  /**
   * Close the HTTP client and clear cache
   */
  close() {
    this._cache.clear();
  }
}
