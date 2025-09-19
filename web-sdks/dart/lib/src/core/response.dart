/// Enhanced response system for GroupVAN SDK
///
/// Provides comprehensive response handling with metadata, caching,
/// and type-safe data access following Flutter/Dart best practices.
library response;

/// Enhanced response wrapper with comprehensive metadata
class GroupVanResponse<T> {
  /// The actual response data
  final T data;

  /// HTTP status code
  final int statusCode;

  /// Response headers
  final Map<String, String> headers;

  /// Request metadata
  final RequestMetadata requestMetadata;

  /// Response metadata
  final ResponseMetadata responseMetadata;

  /// Session ID if present
  final String? sessionId;

  /// Whether the response came from cache
  final bool fromCache;

  /// Cache timestamp if applicable
  final DateTime? cacheTimestamp;

  GroupVanResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.requestMetadata,
    required this.responseMetadata,
    this.sessionId,
    this.fromCache = false,
    this.cacheTimestamp,
  });

  /// Whether the response was successful (2xx status code)
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  /// Whether the response was from cache
  bool get isCached => fromCache;

  /// Response age if cached
  Duration? get cacheAge {
    if (cacheTimestamp == null) return null;
    return DateTime.now().difference(cacheTimestamp!);
  }

  /// Create a copy with different data
  GroupVanResponse<U> copyWith<U>({
    U? data,
    int? statusCode,
    Map<String, String>? headers,
    RequestMetadata? requestMetadata,
    ResponseMetadata? responseMetadata,
    String? sessionId,
    bool? fromCache,
    DateTime? cacheTimestamp,
  }) {
    return GroupVanResponse<U>(
      data: data ?? this.data as U,
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      requestMetadata: requestMetadata ?? this.requestMetadata,
      responseMetadata: responseMetadata ?? this.responseMetadata,
      sessionId: sessionId ?? this.sessionId,
      fromCache: fromCache ?? this.fromCache,
      cacheTimestamp: cacheTimestamp ?? this.cacheTimestamp,
    );
  }

  @override
  String toString() {
    return 'GroupVanResponse<$T>(status: $statusCode, cached: $fromCache, session: $sessionId)';
  }
}

/// Request metadata for debugging and monitoring
class RequestMetadata {
  /// HTTP method used
  final String method;

  /// Full request URL
  final String url;

  /// Request headers sent
  final Map<String, String> headers;

  /// Request body if applicable
  final dynamic body;

  /// Request timestamp
  final DateTime timestamp;

  /// Request timeout duration
  final Duration timeout;

  /// Retry attempt number (0 for first attempt)
  final int retryAttempt;

  /// Request correlation ID for tracing
  final String correlationId;

  RequestMetadata({
    required this.method,
    required this.url,
    required this.headers,
    this.body,
    required this.timestamp,
    required this.timeout,
    this.retryAttempt = 0,
    required this.correlationId,
  });

  @override
  String toString() {
    return 'RequestMetadata(method: $method, url: $url, retry: $retryAttempt, correlation: $correlationId)';
  }
}

/// Response metadata for debugging and monitoring
class ResponseMetadata {
  /// Response timestamp
  final DateTime timestamp;

  /// Response processing duration
  final Duration duration;

  /// Response size in bytes
  final int? sizeBytes;

  /// Whether response was gzipped
  final bool compressed;

  /// Response encoding
  final String? encoding;

  /// Server information
  final String? server;

  /// Response correlation ID
  final String correlationId;

  ResponseMetadata({
    required this.timestamp,
    required this.duration,
    this.sizeBytes,
    this.compressed = false,
    this.encoding,
    this.server,
    required this.correlationId,
  });

  @override
  String toString() {
    return 'ResponseMetadata(duration: ${duration.inMilliseconds}ms, size: ${sizeBytes ?? 'unknown'} bytes, correlation: $correlationId)';
  }
}

/// Paginated response wrapper
class PaginatedResponse<T> extends GroupVanResponse<List<T>> {
  /// Current page number
  final int page;

  /// Items per page
  final int limit;

  /// Total number of items
  final int totalCount;

  /// Total number of pages
  final int totalPages;

  /// Whether there are more pages
  final bool hasNextPage;

  /// Whether there are previous pages
  final bool hasPreviousPage;

  PaginatedResponse({
    required super.data,
    required super.statusCode,
    required super.headers,
    required super.requestMetadata,
    required super.responseMetadata,
    super.sessionId,
    super.fromCache,
    super.cacheTimestamp,
    required this.page,
    required this.limit,
    required this.totalCount,
  }) : totalPages = (totalCount / limit).ceil(),
       hasNextPage = (page * limit) < totalCount,
       hasPreviousPage = page > 1;

  @override
  String toString() {
    return 'PaginatedResponse<$T>(status: $statusCode, page: $page/$totalPages, items: ${data.length}/$totalCount)';
  }
}

/// Response builder for creating responses with proper metadata
class ResponseBuilder<T> {
  T? _data;
  int? _statusCode;
  Map<String, String>? _headers;
  RequestMetadata? _requestMetadata;
  ResponseMetadata? _responseMetadata;
  String? _sessionId;
  bool _fromCache = false;
  DateTime? _cacheTimestamp;

  ResponseBuilder<T> data(T data) {
    _data = data;
    return this;
  }

  ResponseBuilder<T> statusCode(int statusCode) {
    _statusCode = statusCode;
    return this;
  }

  ResponseBuilder<T> headers(Map<String, String> headers) {
    _headers = headers;
    return this;
  }

  ResponseBuilder<T> requestMetadata(RequestMetadata metadata) {
    _requestMetadata = metadata;
    return this;
  }

  ResponseBuilder<T> responseMetadata(ResponseMetadata metadata) {
    _responseMetadata = metadata;
    return this;
  }

  ResponseBuilder<T> sessionId(String? sessionId) {
    _sessionId = sessionId;
    return this;
  }

  ResponseBuilder<T> fromCache(bool cached, [DateTime? timestamp]) {
    _fromCache = cached;
    _cacheTimestamp = timestamp;
    return this;
  }

  GroupVanResponse<T> build() {
    if (_data == null ||
        _statusCode == null ||
        _headers == null ||
        _requestMetadata == null ||
        _responseMetadata == null) {
      throw StateError('Missing required response data');
    }

    return GroupVanResponse<T>(
      data: _data as T,
      statusCode: _statusCode!,
      headers: _headers!,
      requestMetadata: _requestMetadata!,
      responseMetadata: _responseMetadata!,
      sessionId: _sessionId,
      fromCache: _fromCache,
      cacheTimestamp: _cacheTimestamp,
    );
  }
}

/// Result type for operations that may fail
sealed class Result<T> {
  const Result();

  /// Whether this result is successful
  bool get isSuccess => this is Success<T>;

  /// Whether this result is a failure
  bool get isFailure => this is Failure<T>;

  /// Get the success value (throws if failure)
  T get value {
    return switch (this) {
      Success<T>(value: final value) => value,
      Failure<T>() => throw StateError('Cannot get value from failure result'),
    };
  }

  /// Get the error (throws if success)
  Exception get error {
    return switch (this) {
      Success<T>() => throw StateError('Cannot get error from success result'),
      Failure<T>(error: final error) => error,
    };
  }

  /// Transform success value
  Result<U> map<U>(U Function(T value) transform) {
    return switch (this) {
      Success<T>(value: final value) => Success(transform(value)),
      Failure<T>(error: final error) => Failure(error),
    };
  }

  /// Transform error
  Result<T> mapError(Exception Function(Exception error) transform) {
    return switch (this) {
      Success<T>(value: final value) => Success(value),
      Failure<T>(error: final error) => Failure(transform(error)),
    };
  }

  /// Handle both success and failure cases
  U fold<U>(
    U Function(Exception error) onFailure,
    U Function(T value) onSuccess,
  ) {
    return switch (this) {
      Success<T>(value: final value) => onSuccess(value),
      Failure<T>(error: final error) => onFailure(error),
    };
  }
}

/// Success result
final class Success<T> extends Result<T> {
  @override
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Success<T> && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// Failure result
final class Failure<T> extends Result<T> {
  @override
  final Exception error;

  const Failure(this.error);

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Failure<T> && error == other.error;
  }

  @override
  int get hashCode => error.hashCode;
}
