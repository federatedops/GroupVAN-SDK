/// Professional HTTP client implementation using Dio
///
/// Provides enterprise-grade HTTP functionality with interceptors,
/// retry logic, caching, and comprehensive error handling.
library http_client;

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' hide Response;
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:uuid/uuid.dart';

import '../logging.dart';
import 'exceptions.dart';
import 'response.dart';

/// Configuration for the HTTP client
class HttpClientConfig {
  /// Base URL for API requests
  final String baseUrl;

  /// Default timeout for requests
  final Duration timeout;

  /// Default timeout for connections
  final Duration connectTimeout;

  /// Default timeout for receiving data
  final Duration receiveTimeout;

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Enable request/response logging
  final bool enableLogging;

  /// Enable caching
  final bool enableCaching;

  /// Cache directory path
  final String? cacheDirectory;

  /// Default cache duration
  final Duration cacheDuration;

  /// API token for authentication
  final String? token;

  /// Additional default headers
  final Map<String, String> defaultHeaders;

  const HttpClientConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableLogging = true,
    this.enableCaching = true,
    this.cacheDirectory,
    this.cacheDuration = const Duration(minutes: 5),
    this.token,
    this.defaultHeaders = const {},
  });

  HttpClientConfig copyWith({
    String? baseUrl,
    Duration? timeout,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    int? maxRetries,
    bool? enableLogging,
    bool? enableCaching,
    String? cacheDirectory,
    Duration? cacheDuration,
    String? token,
    Map<String, String>? defaultHeaders,
  }) {
    return HttpClientConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      timeout: timeout ?? this.timeout,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      maxRetries: maxRetries ?? this.maxRetries,
      enableLogging: enableLogging ?? this.enableLogging,
      enableCaching: enableCaching ?? this.enableCaching,
      cacheDirectory: cacheDirectory ?? this.cacheDirectory,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      token: token ?? this.token,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
    );
  }
}

/// Professional HTTP client using Dio
class GroupVanHttpClient {
  late final Dio _dio;
  final HttpClientConfig _config;
  final Uuid _uuid = const Uuid();

  /// Cache store for HTTP responses
  CacheStore? _cacheStore;

  GroupVanHttpClient(this._config) {
    _initializeDio();
  }

  /// Initialize Dio with all interceptors and configuration
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: _config.connectTimeout,
        receiveTimeout: _config.receiveTimeout,
        sendTimeout: _config.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_config.token != null) 'Authorization': 'Bearer ${_config.token}',
          ..._config.defaultHeaders,
        },
      ),
    );

    // On web, enable withCredentials so the browser includes HttpOnly cookies
    // (refresh_token) in cross-origin requests to *.groupvan.com
    if (kIsWeb) {
      _dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
    }

    // Sanitize sendTimeout for requests without a body (esp. required on Web)
    _dio.interceptors.add(SendTimeoutSanitizerInterceptor());

    // Add authentication interceptor
    _dio.interceptors.add(AuthInterceptor(_config.token));

    // Add retry interceptor
    _dio.interceptors.add(RetryInterceptor(_config.maxRetries));

    // Add caching if enabled
    if (_config.enableCaching) {
      _initializeCache();
    }

    // Add logging interceptor (should be last for complete request/response logging)
    if (_config.enableLogging) {
      _dio.interceptors.add(LoggingInterceptor());
    }

    // Add correlation ID interceptor
    _dio.interceptors.add(CorrelationInterceptor(_uuid));

    // Add error handling interceptor
    _dio.interceptors.add(ErrorHandlingInterceptor());
  }

  /// Initialize cache store
  void _initializeCache() {
    final cacheOptions = CacheOptions(
      store: _cacheStore ?? MemCacheStore(),
      policy: CachePolicy.request,
      // hitCacheOnErrorExcept removed for compatibility
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      cipher: null,
      allowPostMethod: false,
    );

    _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
  }

  String get baseUrl => _config.baseUrl;

  String get origin => window.location.origin;

  /// Make a GET request
  Future<GroupVanResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? decoder,
  }) async {
    final startTime = DateTime.now();
    final correlationId = _uuid.v4();

    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options:
            options?.copyWith(extra: {'correlation_id': correlationId}) ??
            Options(extra: {'correlation_id': correlationId}),
        cancelToken: cancelToken,
      );

      return _buildResponse<T>(
        response,
        startTime,
        correlationId,
        decoder: decoder,
      );
    } on DioException catch (e) {
      throw _handleDioException(e, correlationId);
    }
  }

  /// Make a POST request
  Future<GroupVanResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? decoder,
  }) async {
    final startTime = DateTime.now();
    final correlationId = _uuid.v4();

    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options:
            options?.copyWith(extra: {'correlation_id': correlationId}) ??
            Options(extra: {'correlation_id': correlationId}),
        cancelToken: cancelToken,
      );

      return _buildResponse<T>(
        response,
        startTime,
        correlationId,
        decoder: decoder,
      );
    } on DioException catch (e) {
      throw _handleDioException(e, correlationId);
    }
  }

  /// Make a PUT request
  Future<GroupVanResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? decoder,
  }) async {
    final startTime = DateTime.now();
    final correlationId = _uuid.v4();

    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options:
            options?.copyWith(extra: {'correlation_id': correlationId}) ??
            Options(extra: {'correlation_id': correlationId}),
        cancelToken: cancelToken,
      );

      return _buildResponse<T>(
        response,
        startTime,
        correlationId,
        decoder: decoder,
      );
    } on DioException catch (e) {
      throw _handleDioException(e, correlationId);
    }
  }

  /// Make a PATCH request
  Future<GroupVanResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? decoder,
  }) async {
    final startTime = DateTime.now();
    final correlationId = _uuid.v4();

    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options:
            options?.copyWith(extra: {'correlation_id': correlationId}) ??
            Options(extra: {'correlation_id': correlationId}),
        cancelToken: cancelToken,
      );

      return _buildResponse<T>(
        response,
        startTime,
        correlationId,
        decoder: decoder,
      );
    } on DioException catch (e) {
      throw _handleDioException(e, correlationId);
    }
  }

  /// Make a DELETE request
  Future<GroupVanResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? decoder,
  }) async {
    final startTime = DateTime.now();
    final correlationId = _uuid.v4();

    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options:
            options?.copyWith(extra: {'correlation_id': correlationId}) ??
            Options(extra: {'correlation_id': correlationId}),
        cancelToken: cancelToken,
      );

      return _buildResponse<T>(
        response,
        startTime,
        correlationId,
        decoder: decoder,
      );
    } on DioException catch (e) {
      throw _handleDioException(e, correlationId);
    }
  }

  /// Build GroupVanResponse from Dio response
  GroupVanResponse<T> _buildResponse<T>(
    Response<dynamic> response,
    DateTime startTime,
    String correlationId, {
    T Function(dynamic)? decoder,
  }) {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    // Decode data using provided decoder or return as-is
    final T data = decoder != null
        ? decoder(response.data)
        : response.data as T;

    // Check if response was cached
    final fromCache =
        response.headers.value('cache-control')?.contains('hit') ?? false;
    final cacheDate = response.headers.value('date');
    final cacheTimestamp = cacheDate != null
        ? DateTime.tryParse(cacheDate)
        : null;

    return GroupVanResponse<T>(
      data: data,
      statusCode: response.statusCode ?? 0,
      headers: response.headers.map.map(
        (key, value) => MapEntry(key, value.join(', ')),
      ),
      requestMetadata: RequestMetadata(
        method: response.requestOptions.method,
        url: response.realUri.toString(),
        headers: response.requestOptions.headers.cast<String, String>(),
        body: response.requestOptions.data,
        timestamp: startTime,
        timeout:
            response.requestOptions.sendTimeout ?? const Duration(seconds: 30),
        retryAttempt: response.requestOptions.extra['retry_count'] ?? 0,
        correlationId: correlationId,
      ),
      responseMetadata: ResponseMetadata(
        timestamp: endTime,
        duration: duration,
        sizeBytes: response.headers.value('content-length') != null
            ? int.tryParse(response.headers.value('content-length')!)
            : null,
        compressed: response.headers.value('content-encoding') == 'gzip',
        encoding: response.headers.value('content-encoding'),
        server: response.headers.value('server'),
        correlationId: correlationId,
      ),
      fromCache: fromCache,
      cacheTimestamp: cacheTimestamp,
    );
  }

  /// Handle DioException and convert to GroupVan exception
  GroupVanException _handleDioException(DioException e, String correlationId) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Request timeout: ${e.message}',
          endpoint: e.requestOptions.path,
          method: e.requestOptions.method,
          context: {'correlation_id': correlationId},
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final responseData = e.response?.data?.toString();

        if (statusCode == 400 && responseData != null) {
          Map<String, dynamic> responseJson = e.response!.data;
          if (responseJson['title'] == 'User not found') {
            final email = responseJson['detail'].split(' ')[1];
            return AuthenticationException(
              'FedLink account must be linked to sign in.',
              errorType: AuthErrorType.accountNotLinked,
              context: {'correlation_id': correlationId, 'email': email},
            );
          }
        }

        // Handle authentication errors
        if (statusCode == 401) {
          return AuthenticationException(
            'Authentication failed: ${e.message}',
            errorType: AuthErrorType.invalidToken,
            context: {'correlation_id': correlationId},
          );
        }

        // Handle authorization errors
        if (statusCode == 403) {
          return AuthenticationException(
            'Access forbidden: ${e.message}',
            errorType: AuthErrorType.insufficientPermissions,
            context: {'correlation_id': correlationId},
          );
        }

        // Handle rate limiting
        if (statusCode == 429) {
          final retryAfter = e.response?.headers.value('retry-after');
          return RateLimitException(
            'Rate limit exceeded: ${e.message}',
            retryAfterSeconds: retryAfter != null
                ? int.tryParse(retryAfter)
                : null,
            context: {'correlation_id': correlationId},
          );
        }

        return HttpException(
          e.message ?? 'HTTP error occurred',
          statusCode: statusCode,
          endpoint: e.requestOptions.path,
          method: e.requestOptions.method,
          responseBody: responseData,
          context: {'correlation_id': correlationId},
        );

      case DioExceptionType.cancel:
        return NetworkException(
          'Request was cancelled',
          endpoint: e.requestOptions.path,
          method: e.requestOptions.method,
          context: {'correlation_id': correlationId},
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          'Connection error: ${e.message}',
          endpoint: e.requestOptions.path,
          method: e.requestOptions.method,
          context: {'correlation_id': correlationId},
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          'SSL certificate error: ${e.message}',
          endpoint: e.requestOptions.path,
          method: e.requestOptions.method,
          context: {'correlation_id': correlationId},
        );

      case DioExceptionType.unknown:
        return NetworkException(
          'Unknown error: ${e.message}',
          endpoint: e.requestOptions.path,
          method: e.requestOptions.method,
          context: {'correlation_id': correlationId},
        );
    }
  }

  /// Close the HTTP client
  void close() {
    _dio.close();
  }
}

/// Send-timeout sanitizer to avoid using sendTimeout on requests without a body
class SendTimeoutSanitizerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final hasNoBody = options.data == null;

    if (hasNoBody &&
        (method == 'GET' || method == 'HEAD' || method == 'OPTIONS')) {
      options.sendTimeout = null;
    }

    handler.next(options);
  }
}

/// Authentication interceptor
class AuthInterceptor extends Interceptor {
  String? _token;

  AuthInterceptor(this._token);

  void updateToken(String? token) {
    _token = token;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_token != null) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    handler.next(options);
  }
}

/// Retry interceptor with exponential backoff
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration baseDelay;
  final double backoffMultiplier;

  RetryInterceptor(
    this.maxRetries, {
    this.baseDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra['retry_count'] ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      // Calculate delay with exponential backoff
      final delay = Duration(
        milliseconds:
            (baseDelay.inMilliseconds * (1 << retryCount) * backoffMultiplier)
                .round(),
      );

      GroupVanLogger.apiClient.info(
        'Retrying request ${retryCount + 1}/$maxRetries after ${delay.inMilliseconds}ms',
      );

      await Future.delayed(delay);

      // Update retry count
      err.requestOptions.extra['retry_count'] = retryCount + 1;

      // Retry the request
      try {
        final response = await Dio().fetch(err.requestOptions);
        handler.resolve(response);
      } on DioException catch (e) {
        handler.next(e);
      }
    } else {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException error) {
    // Retry on network errors and 5xx server errors
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500) ||
        error.response?.statusCode == 429; // Rate limit
  }
}

/// Logging interceptor
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final correlationId = options.extra['correlation_id'] ?? 'unknown';
    GroupVanLogger.apiClient.fine(
      '[$correlationId] ${options.method} ${options.uri}',
    );

    if (options.data != null) {
      GroupVanLogger.apiClient.finest(
        '[$correlationId] Request body: ${options.data}',
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final correlationId =
        response.requestOptions.extra['correlation_id'] ?? 'unknown';
    GroupVanLogger.apiClient.fine(
      '[$correlationId] Response: ${response.statusCode} (${response.data?.toString().length ?? 0} bytes)',
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final correlationId =
        err.requestOptions.extra['correlation_id'] ?? 'unknown';
    GroupVanLogger.apiClient.warning(
      '[$correlationId] Error: ${err.type} - ${err.message}',
    );

    handler.next(err);
  }
}

/// Correlation ID interceptor
class CorrelationInterceptor extends Interceptor {
  final Uuid _uuid;

  CorrelationInterceptor(this._uuid);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add correlation ID if not already present
    if (!options.extra.containsKey('correlation_id')) {
      options.extra['correlation_id'] = _uuid.v4();
    }

    // Add correlation ID to headers
    options.headers['X-Correlation-ID'] = options.extra['correlation_id'];

    handler.next(options);
  }
}

/// Error handling interceptor
class ErrorHandlingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error details
    final correlationId =
        err.requestOptions.extra['correlation_id'] ?? 'unknown';
    GroupVanLogger.apiClient.severe(
      '[$correlationId] HTTP Error: ${err.type} - ${err.message}',
    );

    handler.next(err);
  }
}
