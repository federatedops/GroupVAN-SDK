/**
 * Enhanced response system for GroupVAN SDK
 *
 * Provides comprehensive response handling with metadata, caching,
 * and type-safe data access.
 */

/**
 * Request metadata for debugging and monitoring
 */
export class RequestMetadata {
  /**
   * @param {Object} options
   * @param {string} options.method - HTTP method used
   * @param {string} options.url - Full request URL
   * @param {Object} options.headers - Request headers sent
   * @param {*} [options.body] - Request body if applicable
   * @param {Date} options.timestamp - Request timestamp
   * @param {number} options.timeout - Request timeout in milliseconds
   * @param {number} [options.retryAttempt=0] - Retry attempt number
   * @param {string} options.correlationId - Request correlation ID for tracing
   */
  constructor({ method, url, headers, body = null, timestamp, timeout, retryAttempt = 0, correlationId }) {
    this.method = method;
    this.url = url;
    this.headers = headers;
    this.body = body;
    this.timestamp = timestamp;
    this.timeout = timeout;
    this.retryAttempt = retryAttempt;
    this.correlationId = correlationId;
  }

  toString() {
    return `RequestMetadata(method: ${this.method}, url: ${this.url}, retry: ${this.retryAttempt}, correlation: ${this.correlationId})`;
  }
}

/**
 * Response metadata for debugging and monitoring
 */
export class ResponseMetadata {
  /**
   * @param {Object} options
   * @param {Date} options.timestamp - Response timestamp
   * @param {number} options.durationMs - Response processing duration in milliseconds
   * @param {number} [options.sizeBytes] - Response size in bytes
   * @param {boolean} [options.compressed=false] - Whether response was gzipped
   * @param {string} [options.encoding] - Response encoding
   * @param {string} [options.server] - Server information
   * @param {string} options.correlationId - Response correlation ID
   */
  constructor({ timestamp, durationMs, sizeBytes = null, compressed = false, encoding = null, server = null, correlationId }) {
    this.timestamp = timestamp;
    this.durationMs = durationMs;
    this.sizeBytes = sizeBytes;
    this.compressed = compressed;
    this.encoding = encoding;
    this.server = server;
    this.correlationId = correlationId;
  }

  toString() {
    return `ResponseMetadata(duration: ${this.durationMs}ms, size: ${this.sizeBytes ?? 'unknown'} bytes, correlation: ${this.correlationId})`;
  }
}

/**
 * Enhanced response wrapper with comprehensive metadata
 * @template T
 */
export class GroupVanResponse {
  /**
   * @param {Object} options
   * @param {T} options.data - The actual response data
   * @param {number} options.statusCode - HTTP status code
   * @param {Object} options.headers - Response headers
   * @param {RequestMetadata} options.requestMetadata - Request metadata
   * @param {ResponseMetadata} options.responseMetadata - Response metadata
   * @param {boolean} [options.fromCache=false] - Whether the response came from cache
   * @param {Date} [options.cacheTimestamp] - Cache timestamp if applicable
   */
  constructor({ data, statusCode, headers, requestMetadata, responseMetadata, fromCache = false, cacheTimestamp = null }) {
    this.data = data;
    this.statusCode = statusCode;
    this.headers = headers;
    this.requestMetadata = requestMetadata;
    this.responseMetadata = responseMetadata;
    this.fromCache = fromCache;
    this.cacheTimestamp = cacheTimestamp;
  }

  /**
   * Whether the response was successful (2xx status code)
   * @returns {boolean}
   */
  get isSuccessful() {
    return this.statusCode >= 200 && this.statusCode < 300;
  }

  /**
   * Whether the response was from cache
   * @returns {boolean}
   */
  get isCached() {
    return this.fromCache;
  }

  /**
   * Response age if cached (in milliseconds)
   * @returns {number|null}
   */
  get cacheAgeMs() {
    if (!this.cacheTimestamp) return null;
    return Date.now() - this.cacheTimestamp.getTime();
  }

  toString() {
    return `GroupVanResponse(status: ${this.statusCode}, cached: ${this.fromCache})`;
  }
}

/**
 * Paginated response wrapper
 * @template T
 * @extends {GroupVanResponse<T[]>}
 */
export class PaginatedResponse extends GroupVanResponse {
  /**
   * @param {Object} options
   * @param {T[]} options.data - The response data array
   * @param {number} options.statusCode - HTTP status code
   * @param {Object} options.headers - Response headers
   * @param {RequestMetadata} options.requestMetadata - Request metadata
   * @param {ResponseMetadata} options.responseMetadata - Response metadata
   * @param {number} options.page - Current page number
   * @param {number} options.limit - Items per page
   * @param {number} options.totalCount - Total number of items
   * @param {boolean} [options.fromCache=false] - Whether from cache
   * @param {Date} [options.cacheTimestamp] - Cache timestamp
   */
  constructor({ data, statusCode, headers, requestMetadata, responseMetadata, page, limit, totalCount, fromCache = false, cacheTimestamp = null }) {
    super({ data, statusCode, headers, requestMetadata, responseMetadata, fromCache, cacheTimestamp });
    this.page = page;
    this.limit = limit;
    this.totalCount = totalCount;
    this.totalPages = Math.ceil(totalCount / limit);
    this.hasNextPage = (page * limit) < totalCount;
    this.hasPreviousPage = page > 1;
  }

  toString() {
    return `PaginatedResponse(status: ${this.statusCode}, page: ${this.page}/${this.totalPages}, items: ${this.data.length}/${this.totalCount})`;
  }
}

/**
 * Response builder for creating responses with proper metadata
 * @template T
 */
export class ResponseBuilder {
  constructor() {
    this._data = null;
    this._statusCode = null;
    this._headers = null;
    this._requestMetadata = null;
    this._responseMetadata = null;
    this._fromCache = false;
    this._cacheTimestamp = null;
  }

  /**
   * @param {T} data
   * @returns {ResponseBuilder<T>}
   */
  data(data) {
    this._data = data;
    return this;
  }

  /**
   * @param {number} statusCode
   * @returns {ResponseBuilder<T>}
   */
  statusCode(statusCode) {
    this._statusCode = statusCode;
    return this;
  }

  /**
   * @param {Object} headers
   * @returns {ResponseBuilder<T>}
   */
  headers(headers) {
    this._headers = headers;
    return this;
  }

  /**
   * @param {RequestMetadata} metadata
   * @returns {ResponseBuilder<T>}
   */
  requestMetadata(metadata) {
    this._requestMetadata = metadata;
    return this;
  }

  /**
   * @param {ResponseMetadata} metadata
   * @returns {ResponseBuilder<T>}
   */
  responseMetadata(metadata) {
    this._responseMetadata = metadata;
    return this;
  }

  /**
   * @param {boolean} cached
   * @param {Date} [timestamp]
   * @returns {ResponseBuilder<T>}
   */
  fromCache(cached, timestamp = null) {
    this._fromCache = cached;
    this._cacheTimestamp = timestamp;
    return this;
  }

  /**
   * @returns {GroupVanResponse<T>}
   * @throws {Error} If required data is missing
   */
  build() {
    if (
      this._data === null ||
      this._statusCode === null ||
      this._headers === null ||
      this._requestMetadata === null ||
      this._responseMetadata === null
    ) {
      throw new Error('Missing required response data');
    }

    return new GroupVanResponse({
      data: this._data,
      statusCode: this._statusCode,
      headers: this._headers,
      requestMetadata: this._requestMetadata,
      responseMetadata: this._responseMetadata,
      fromCache: this._fromCache,
      cacheTimestamp: this._cacheTimestamp,
    });
  }
}

/**
 * Result type for operations that may fail
 * @template T
 */
export class Result {
  /**
   * @param {boolean} isSuccess
   * @param {T} [value]
   * @param {Error} [error]
   */
  constructor(isSuccess, value = null, error = null) {
    this._isSuccess = isSuccess;
    this._value = value;
    this._error = error;
  }

  /**
   * Create a success result
   * @template T
   * @param {T} value
   * @returns {Result<T>}
   */
  static success(value) {
    return new Result(true, value, null);
  }

  /**
   * Create a failure result
   * @template T
   * @param {Error} error
   * @returns {Result<T>}
   */
  static failure(error) {
    return new Result(false, null, error);
  }

  /**
   * Whether this result is successful
   * @returns {boolean}
   */
  get isSuccess() {
    return this._isSuccess;
  }

  /**
   * Whether this result is a failure
   * @returns {boolean}
   */
  get isFailure() {
    return !this._isSuccess;
  }

  /**
   * Get the success value (throws if failure)
   * @returns {T}
   * @throws {Error} If result is a failure
   */
  get value() {
    if (!this._isSuccess) {
      throw new Error('Cannot get value from failure result');
    }
    return this._value;
  }

  /**
   * Get the error (throws if success)
   * @returns {Error}
   * @throws {Error} If result is a success
   */
  get error() {
    if (this._isSuccess) {
      throw new Error('Cannot get error from success result');
    }
    return this._error;
  }

  /**
   * Get the value or null if failure
   * @returns {T|null}
   */
  getOrNull() {
    return this._isSuccess ? this._value : null;
  }

  /**
   * Get the value or a default if failure
   * @param {T} defaultValue
   * @returns {T}
   */
  getOrDefault(defaultValue) {
    return this._isSuccess ? this._value : defaultValue;
  }

  /**
   * Transform success value
   * @template U
   * @param {function(T): U} transform
   * @returns {Result<U>}
   */
  map(transform) {
    if (this._isSuccess) {
      return Result.success(transform(this._value));
    }
    return Result.failure(this._error);
  }

  /**
   * Transform error
   * @param {function(Error): Error} transform
   * @returns {Result<T>}
   */
  mapError(transform) {
    if (!this._isSuccess) {
      return Result.failure(transform(this._error));
    }
    return Result.success(this._value);
  }

  /**
   * Handle both success and failure cases
   * @template U
   * @param {function(Error): U} onFailure
   * @param {function(T): U} onSuccess
   * @returns {U}
   */
  fold(onFailure, onSuccess) {
    if (this._isSuccess) {
      return onSuccess(this._value);
    }
    return onFailure(this._error);
  }

  toString() {
    if (this._isSuccess) {
      return `Success(${this._value})`;
    }
    return `Failure(${this._error})`;
  }
}
