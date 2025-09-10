/// Authentication models for GroupVAN SDK
/// 
/// Models the JWT-based authentication system used by GroupVAN API.
/// Supports access tokens, refresh tokens, and automatic token management.
library auth_models;

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'auth_models.g.dart';

/// Login request model
@JsonSerializable()
class LoginRequest extends Equatable {
  /// Username for authentication
  final String username;

  /// Password for authentication  
  final String password;

  /// Developer ID assigned by GroupVAN
  @JsonKey(name: 'developer_id')
  final String developerId;

  /// Integration name for authentication
  final String integration;

  const LoginRequest({
    required this.username,
    required this.password,
    required this.developerId,
    required this.integration,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => 
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  @override
  List<Object?> get props => [username, password, developerId, integration];
}

/// Token response from authentication endpoints
@JsonSerializable()
class TokenResponse extends Equatable {
  /// JWT access token for API requests
  @JsonKey(name: 'access_token')
  final String accessToken;

  /// JWT refresh token for obtaining new access tokens
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  /// Token expiration time in seconds
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  /// Token type (typically 'Bearer')
  @JsonKey(name: 'token_type', defaultValue: 'Bearer')
  final String tokenType;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => 
      _$TokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn, tokenType];
}

/// Refresh token request
@JsonSerializable()
class RefreshTokenRequest extends Equatable {
  /// Refresh token to use for generating new access token
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) => 
      _$RefreshTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);

  @override
  List<Object?> get props => [refreshToken];
}

/// Logout request  
@JsonSerializable()
class LogoutRequest extends Equatable {
  /// Refresh token to blacklist
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  const LogoutRequest({required this.refreshToken});

  factory LogoutRequest.fromJson(Map<String, dynamic> json) => 
      _$LogoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutRequestToJson(this);

  @override
  List<Object?> get props => [refreshToken];
}

/// JWT token claims decoded from access token
@JsonSerializable()
class TokenClaims extends Equatable {
  /// User ID from the token
  @JsonKey(name: 'sub')
  final String userId;

  /// Token type (access/refresh)
  @JsonKey(name: 'type', defaultValue: 'access')
  final String type;

  /// Token issued at timestamp
  @JsonKey(name: 'iat')
  final int issuedAt;

  /// Token expiration timestamp
  @JsonKey(name: 'exp')
  final int expiration;

  /// Token JTI (unique identifier)
  @JsonKey(name: 'jti')
  final String jti;

  /// Member ID if present
  @JsonKey(name: 'member')
  final String? member;

  const TokenClaims({
    required this.userId,
    required this.issuedAt,
    required this.expiration,
    required this.jti,
    this.type = 'access',
    this.member,
  });

  factory TokenClaims.fromJson(Map<String, dynamic> json) => 
      _$TokenClaimsFromJson(json);

  Map<String, dynamic> toJson() => _$TokenClaimsToJson(this);

  /// Whether the token is expired
  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiration * 1000;

  /// Whether the token will expire within the given duration
  bool willExpireWithin(Duration duration) {
    final expirationTime = DateTime.fromMillisecondsSinceEpoch(expiration * 1000);
    final threshold = DateTime.now().add(duration);
    return expirationTime.isBefore(threshold);
  }

  /// Time until token expires
  Duration get timeUntilExpiration {
    final expirationTime = DateTime.fromMillisecondsSinceEpoch(expiration * 1000);
    final now = DateTime.now();
    if (expirationTime.isBefore(now)) {
      return Duration.zero;
    }
    return expirationTime.difference(now);
  }

  @override
  List<Object?> get props => [
        userId,
        type,
        issuedAt,
        expiration,
        jti,
        member,
      ];
}

/// Authentication state
enum AuthState {
  /// Not authenticated
  unauthenticated,
  /// Currently authenticating
  authenticating,
  /// Authenticated with valid tokens
  authenticated,
  /// Token refresh in progress
  refreshing,
  /// Authentication expired
  expired,
  /// Authentication failed
  failed,
}

/// Current authentication status
@immutable
class AuthStatus extends Equatable {
  /// Current authentication state
  final AuthState state;

  /// Access token if authenticated
  final String? accessToken;

  /// Refresh token if authenticated
  final String? refreshToken;

  /// Decoded token claims if available
  final TokenClaims? claims;

  /// Last authentication error if any
  final String? error;

  /// Timestamp of last successful authentication
  final DateTime? authenticatedAt;

  /// Timestamp of last token refresh
  final DateTime? refreshedAt;

  const AuthStatus({
    required this.state,
    this.accessToken,
    this.refreshToken,
    this.claims,
    this.error,
    this.authenticatedAt,
    this.refreshedAt,
  });

  /// Create unauthenticated status
  const AuthStatus.unauthenticated()
      : state = AuthState.unauthenticated,
        accessToken = null,
        refreshToken = null,
        claims = null,
        error = null,
        authenticatedAt = null,
        refreshedAt = null;

  /// Create authenticating status  
  const AuthStatus.authenticating()
      : state = AuthState.authenticating,
        accessToken = null,
        refreshToken = null,
        claims = null,
        error = null,
        authenticatedAt = null,
        refreshedAt = null;

  /// Create authenticated status
  AuthStatus.authenticated({
    required String accessToken,
    required String refreshToken,
    required TokenClaims claims,
  }) : state = AuthState.authenticated,
        accessToken = accessToken,
        refreshToken = refreshToken,
        claims = claims,
        error = null,
        authenticatedAt = DateTime.now(),
        refreshedAt = null;

  /// Create refreshing status
  AuthStatus.refreshing({
    required String accessToken,
    required String refreshToken,
    required TokenClaims claims,
    required DateTime authenticatedAt,
  }) : state = AuthState.refreshing,
        accessToken = accessToken,
        refreshToken = refreshToken,
        claims = claims,
        error = null,
        authenticatedAt = authenticatedAt,
        refreshedAt = null;

  /// Create expired status
  AuthStatus.expired({
    String? error,
    required String accessToken,
    required String refreshToken,
    required DateTime authenticatedAt,
    DateTime? refreshedAt,
  }) : state = AuthState.expired,
        accessToken = accessToken,
        refreshToken = refreshToken,
        claims = null,
        error = error,
        authenticatedAt = authenticatedAt,
        refreshedAt = refreshedAt;

  /// Create failed status
  AuthStatus.failed({
    required String error,
  }) : state = AuthState.failed,
        accessToken = null,
        refreshToken = null,
        claims = null,
        error = error,
        authenticatedAt = null,
        refreshedAt = null;

  /// Whether currently authenticated
  bool get isAuthenticated => state == AuthState.authenticated;

  /// Whether tokens are available (even if expired)
  bool get hasTokens => accessToken != null && refreshToken != null;

  /// Whether authentication is in progress
  bool get isLoading => state == AuthState.authenticating || state == AuthState.refreshing;

  /// Whether access token needs refresh
  bool get needsRefresh {
    if (!hasTokens || claims == null) return false;
    return claims!.willExpireWithin(const Duration(minutes: 2));
  }

  /// Copy with new values
  AuthStatus copyWith({
    AuthState? state,
    String? accessToken,
    String? refreshToken,
    TokenClaims? claims,
    String? error,
    DateTime? authenticatedAt,
    DateTime? refreshedAt,
  }) {
    return AuthStatus(
      state: state ?? this.state,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      claims: claims ?? this.claims,
      error: error ?? this.error,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
      refreshedAt: refreshedAt ?? this.refreshedAt,
    );
  }

  @override
  List<Object?> get props => [
        state,
        accessToken,
        refreshToken,
        claims,
        error,
        authenticatedAt,
        refreshedAt,
      ];

  @override
  String toString() {
    return 'AuthStatus(state: $state, hasTokens: $hasTokens, error: $error)';
  }
}