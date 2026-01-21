/**
 * Comprehensive exception system for GroupVAN SDK
 *
 * This file defines a hierarchy of exceptions that provide detailed error
 * information and enable proper error handling strategies.
 */

/**
 * Base exception for all GroupVAN SDK errors
 */
export class GroupVanException extends Error {
  /**
   * @param {string} message - Human-readable error message
   * @param {Object} [options] - Additional options
   * @param {Object} [options.context] - Optional additional context about the error
   * @param {Date} [options.timestamp] - Timestamp when the error occurred
   */
  constructor(message, { context = null, timestamp = null } = {}) {
    super(message);
    this.name = 'GroupVanException';
    this.context = context;
    this.timestamp = timestamp || new Date();
  }

  toString() {
    return `GroupVanException: ${this.message}`;
  }
}

/**
 * Network-related exceptions
 */
export class NetworkException extends GroupVanException {
  /**
   * @param {string} message - Error message
   * @param {Object} [options] - Additional options
   * @param {string} [options.endpoint] - The endpoint that was being accessed
   * @param {string} [options.method] - The HTTP method used
   * @param {Object} [options.context] - Optional additional context
   * @param {Date} [options.timestamp] - Timestamp when the error occurred
   */
  constructor(message, { endpoint = null, method = null, context = null, timestamp = null } = {}) {
    super(message, { context, timestamp });
    this.name = 'NetworkException';
    this.endpoint = endpoint;
    this.method = method;
  }

  toString() {
    return `NetworkException: ${this.message}${this.endpoint ? ` (endpoint: ${this.endpoint})` : ''}`;
  }
}

/**
 * HTTP response exceptions
 */
export class HttpException extends GroupVanException {
  /**
   * @param {string} message - Error message
   * @param {Object} options - Required options
   * @param {number} options.statusCode - HTTP status code
   * @param {string} options.endpoint - The endpoint that was being accessed
   * @param {string} options.method - The HTTP method used
   * @param {string} [options.responseBody] - Response body if available
   * @param {Object} [options.context] - Optional additional context
   * @param {Date} [options.timestamp] - Timestamp when the error occurred
   */
  constructor(message, { statusCode, endpoint, method, responseBody = null, context = null, timestamp = null }) {
    super(message, { context, timestamp });
    this.name = 'HttpException';
    this.statusCode = statusCode;
    this.endpoint = endpoint;
    this.method = method;
    this.responseBody = responseBody;
  }

  /**
   * Whether this is a client error (4xx)
   * @returns {boolean}
   */
  get isClientError() {
    return this.statusCode >= 400 && this.statusCode < 500;
  }

  /**
   * Whether this is a server error (5xx)
   * @returns {boolean}
   */
  get isServerError() {
    return this.statusCode >= 500;
  }

  /**
   * Whether this error is retryable
   * @returns {boolean}
   */
  get isRetryable() {
    return this.isServerError || this.statusCode === 429 || this.statusCode === 408;
  }

  toString() {
    return `HttpException: ${this.message} (Status: ${this.statusCode}, Method: ${this.method}, Endpoint: ${this.endpoint})`;
  }
}

/**
 * Types of authentication errors
 * @enum {string}
 */
export const AuthErrorType = {
  INVALID_TOKEN: 'invalidToken',
  EXPIRED_TOKEN: 'expiredToken',
  MISSING_TOKEN: 'missingToken',
  INSUFFICIENT_PERMISSIONS: 'insufficientPermissions',
  INVALID_CREDENTIALS: 'invalidCredentials',
  ACCOUNT_NOT_LINKED: 'accountNotLinked',
};

/**
 * Authentication and authorization exceptions
 */
export class AuthenticationException extends GroupVanException {
  /**
   * @param {string} message - Error message
   * @param {Object} options - Required options
   * @param {string} options.errorType - Type of authentication error from AuthErrorType
   * @param {Object} [options.context] - Optional additional context
   * @param {Date} [options.timestamp] - Timestamp when the error occurred
   */
  constructor(message, { errorType, context = null, timestamp = null }) {
    super(message, { context, timestamp });
    this.name = 'AuthenticationException';
    this.errorType = errorType;
  }

  toString() {
    return `AuthenticationException: ${this.message} (Type: ${this.errorType})`;
  }
}

/**
 * Individual validation error
 */
export class ValidationError {
  /**
   * @param {Object} options
   * @param {string} options.field - Field name that failed validation
   * @param {string} options.message - Error message
   * @param {*} [options.value] - The invalid value
   * @param {string} [options.rule] - Validation rule that failed
   */
  constructor({ field, message, value = null, rule = null }) {
    this.field = field;
    this.message = message;
    this.value = value;
    this.rule = rule;
  }

  toString() {
    return `${this.field}: ${this.message}`;
  }
}

/**
 * Validation exceptions for user input
 */
export class ValidationException extends GroupVanException {
  /**
   * @param {string} message - Error message
   * @param {Object} options - Required options
   * @param {ValidationError[]} options.errors - List of validation errors
   * @param {Object} [options.context] - Optional additional context
   * @param {Date} [options.timestamp] - Timestamp when the error occurred
   */
  constructor(message, { errors, context = null, timestamp = null }) {
    super(message, { context, timestamp });
    this.name = 'ValidationException';
    this.errors = errors;
  }

  /**
   * Get all error messages
   * @returns {string[]}
   */
  get errorMessages() {
    return this.errors.map(e => e.message);
  }

  toString() {
    return `ValidationException: ${this.message} (${this.errors.length} errors)`;
  }
}

/**
 * Configuration exceptions
 */
export class ConfigurationException extends GroupVanException {
  /**
   * @param {string} message - Error message
   * @param {Object} [options] - Additional options
   * @param {string} [options.configKey] - Configuration key that caused the error
   * @param {Object} [options.context] - Optional additional context
   * @param {Date} [options.timestamp] - Timestamp when the error occurred
   */
  constructor(message, { configKey = null, context = null, timestamp = null } = {}) {
    super(message, { context, timestamp });
    this.name = 'ConfigurationException';
    this.configKey = configKey;
  }

  toString() {
    return `ConfigurationException: ${this.message}${this.configKey ? ` (key: ${this.configKey})` : ''}`;
  }
}

/**
 * Rate limiting exceptions
 */
export class RateLimitException extends GroupVanException {
  /**
   * @param {string} message - Error message
   * @param {Object} [options] - Additional options
   * @param {number} [options.retryAfterSeconds] - Number of seconds until retry is allowed
   * @param {number} [options.windowMs] - Current rate limit window in milliseconds
   * @param {number} [options.limit] - Number of requests allowed in window
   * @param {Object} [options.context] - Optional additional context
   * @param {Date} [options.timestamp] - Timestamp when the error occurred
   */
  constructor(message, { retryAfterSeconds = null, windowMs = null, limit = null, context = null, timestamp = null } = {}) {
    super(message, { context, timestamp });
    this.name = 'RateLimitException';
    this.retryAfterSeconds = retryAfterSeconds;
    this.windowMs = windowMs;
    this.limit = limit;
  }

  toString() {
    return `RateLimitException: ${this.message}${this.retryAfterSeconds ? ` (retry after: ${this.retryAfterSeconds}s)` : ''}`;
  }
}

/**
 * Data parsing exceptions
 */
export class DataException extends GroupVanException {
  /**
   * @param {string} message - Error message
   * @param {Object} [options] - Additional options
   * @param {string} [options.dataType] - Type of data that failed to parse
   * @param {*} [options.originalData] - Original data that caused the error
   * @param {Object} [options.context] - Optional additional context
   * @param {Date} [options.timestamp] - Timestamp when the error occurred
   */
  constructor(message, { dataType = null, originalData = null, context = null, timestamp = null } = {}) {
    super(message, { context, timestamp });
    this.name = 'DataException';
    this.dataType = dataType;
    this.originalData = originalData;
  }

  toString() {
    return `DataException: ${this.message}${this.dataType ? ` (type: ${this.dataType})` : ''}`;
  }
}
