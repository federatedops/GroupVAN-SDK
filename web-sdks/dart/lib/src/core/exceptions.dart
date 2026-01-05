/// Comprehensive exception system for GroupVAN SDK
///
/// This file defines a hierarchy of exceptions that provide detailed error
/// information and enable proper error handling strategies.
library exceptions;

/// Base exception for all GroupVAN SDK errors
abstract class GroupVanException implements Exception {
  /// Human-readable error message
  final String message;

  /// Optional additional context about the error
  final Map<String, dynamic>? context;

  /// Timestamp when the error occurred
  final DateTime timestamp;

  GroupVanException(this.message, {this.context, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'GroupVanException: $message';
}

/// Network-related exceptions
class NetworkException extends GroupVanException {
  /// The endpoint that was being accessed
  final String? endpoint;

  /// The HTTP method used
  final String? method;

  NetworkException(
    super.message, {
    this.endpoint,
    this.method,
    super.context,
    super.timestamp,
  });

  @override
  String toString() =>
      'NetworkException: $message${endpoint != null ? ' (endpoint: $endpoint)' : ''}';
}

/// HTTP response exceptions
class HttpException extends GroupVanException {
  /// HTTP status code
  final int statusCode;

  /// The endpoint that was being accessed
  final String endpoint;

  /// The HTTP method used
  final String method;

  /// Response body if available
  final String? responseBody;

  HttpException(
    super.message, {
    required this.statusCode,
    required this.endpoint,
    required this.method,
    this.responseBody,
    super.context,
    super.timestamp,
  });

  /// Whether this is a client error (4xx)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Whether this is a server error (5xx)
  bool get isServerError => statusCode >= 500;

  /// Whether this error is retryable
  bool get isRetryable =>
      isServerError || statusCode == 429 || statusCode == 408;

  @override
  String toString() =>
      'HttpException: $message (Status: $statusCode, Method: $method, Endpoint: $endpoint)';
}

/// Authentication and authorization exceptions
class AuthenticationException extends GroupVanException {
  /// Type of authentication error
  final AuthErrorType errorType;

  AuthenticationException(
    super.message, {
    required this.errorType,
    super.context,
    super.timestamp,
  });

  @override
  String toString() => 'AuthenticationException: $message (Type: $errorType)';
}

/// Types of authentication errors
enum AuthErrorType {
  invalidToken,
  expiredToken,
  missingToken,
  insufficientPermissions,
  invalidCredentials,
  accountNotLinked,
}

/// Validation exceptions for user input
class ValidationException extends GroupVanException {
  /// List of validation errors
  final List<ValidationError> errors;

  ValidationException(
    super.message, {
    required this.errors,
    super.context,
    super.timestamp,
  });

  /// Get all error messages
  List<String> get errorMessages => errors.map((e) => e.message).toList();

  @override
  String toString() =>
      'ValidationException: $message (${errors.length} errors)';
}

/// Individual validation error
class ValidationError {
  /// Field name that failed validation
  final String field;

  /// Error message
  final String message;

  /// The invalid value
  final dynamic value;

  /// Validation rule that failed
  final String? rule;

  const ValidationError({
    required this.field,
    required this.message,
    this.value,
    this.rule,
  });

  @override
  String toString() => '$field: $message';
}

/// Configuration exceptions
class ConfigurationException extends GroupVanException {
  /// Configuration key that caused the error
  final String? configKey;

  ConfigurationException(
    super.message, {
    this.configKey,
    super.context,
    super.timestamp,
  });

  @override
  String toString() =>
      'ConfigurationException: $message${configKey != null ? ' (key: $configKey)' : ''}';
}

/// Rate limiting exceptions
class RateLimitException extends GroupVanException {
  /// Number of seconds until retry is allowed
  final int? retryAfterSeconds;

  /// Current rate limit window
  final Duration? window;

  /// Number of requests allowed in window
  final int? limit;

  RateLimitException(
    super.message, {
    this.retryAfterSeconds,
    this.window,
    this.limit,
    super.context,
    super.timestamp,
  });

  @override
  String toString() =>
      'RateLimitException: $message${retryAfterSeconds != null ? ' (retry after: ${retryAfterSeconds}s)' : ''}';
}

/// Data parsing exceptions
class DataException extends GroupVanException {
  /// Type of data that failed to parse
  final String? dataType;

  /// Original data that caused the error
  final dynamic originalData;

  DataException(
    super.message, {
    this.dataType,
    this.originalData,
    super.context,
    super.timestamp,
  });

  @override
  String toString() =>
      'DataException: $message${dataType != null ? ' (type: $dataType)' : ''}';
}

