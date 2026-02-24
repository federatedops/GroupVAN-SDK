/// Authentication models for GroupVAN SDK
///
/// Models the JWT-based authentication system used by GroupVAN API.
/// Supports access tokens, refresh tokens, and automatic token management.
library auth_models;

import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../models/auth.dart' show User;
part 'auth_models.g.dart';

/// Login request model
@JsonSerializable()
class LoginRequest extends Equatable {
  /// Email for authentication
  final String email;

  /// Password for authentication
  final String password;

  const LoginRequest({required this.email, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  @override
  List<Object?> get props => [email, password];
}

/// Token response from authentication endpoints
///
/// Note: refresh_token is no longer returned in API responses.
/// It is now set as an HttpOnly cookie by the server.
@JsonSerializable()
class TokenResponse extends Equatable {
  /// JWT access token for API requests
  @JsonKey(name: 'access_token')
  final String accessToken;

  /// Token expiration time in seconds
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  /// Token type (typically 'Bearer')
  @JsonKey(name: 'token_type', defaultValue: 'Bearer')
  final String tokenType;

  const TokenResponse({
    required this.accessToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);

  @override
  List<Object?> get props => [accessToken, expiresIn, tokenType];
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
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiration * 1000;

  /// Whether the token will expire within the given duration
  bool willExpireWithin(Duration duration) {
    final expirationTime = DateTime.fromMillisecondsSinceEpoch(
      expiration * 1000,
    );
    final threshold = DateTime.now().add(duration);
    return expirationTime.isBefore(threshold);
  }

  /// Time until token expires
  Duration get timeUntilExpiration {
    final expirationTime = DateTime.fromMillisecondsSinceEpoch(
      expiration * 1000,
    );
    final now = DateTime.now();
    if (expirationTime.isBefore(now)) {
      return Duration.zero;
    }
    return expirationTime.difference(now);
  }

  @override
  List<Object?> get props => [userId, type, issuedAt, expiration, jti, member];
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
///
/// Note: refreshToken is no longer stored client-side on web.
/// The browser manages the refresh token via HttpOnly cookies.
@immutable
class AuthStatus extends Equatable {
  /// Current authentication state
  final AuthState state;

  /// Access token if authenticated
  final String? accessToken;

  /// Decoded token claims if available
  final TokenClaims? claims;

  final User? userInfo;

  /// Last authentication error if any
  final String? error;

  /// Additional metadata for the current state (e.g., error context)
  final Map<String, dynamic>? metadata;

  /// Timestamp of last successful authentication
  final DateTime? authenticatedAt;

  /// Timestamp of last token refresh
  final DateTime? refreshedAt;

  const AuthStatus({
    required this.state,
    this.accessToken,
    this.claims,
    this.userInfo,
    this.error,
    this.metadata,
    this.authenticatedAt,
    this.refreshedAt,
  });

  /// Create unauthenticated status
  const AuthStatus.unauthenticated()
    : state = AuthState.unauthenticated,
      accessToken = null,
      claims = null,
      userInfo = null,
      error = null,
      metadata = null,
      authenticatedAt = null,
      refreshedAt = null;

  /// Create authenticating status
  const AuthStatus.authenticating()
    : state = AuthState.authenticating,
      accessToken = null,
      claims = null,
      userInfo = null,
      error = null,
      metadata = null,
      authenticatedAt = null,
      refreshedAt = null;

  /// Create authenticated status
  AuthStatus.authenticated({
    required String accessToken,
    required TokenClaims claims,
    User? userInfo,
  }) : state = AuthState.authenticated,
       accessToken = accessToken,
       claims = claims,
       userInfo = userInfo,
       error = null,
       metadata = null,
       authenticatedAt = DateTime.now(),
       refreshedAt = null;

  /// Create refreshing status
  AuthStatus.refreshing({
    required String accessToken,
    required TokenClaims claims,
    required DateTime authenticatedAt,
    User? userInfo,
  }) : state = AuthState.refreshing,
       accessToken = accessToken,
       claims = claims,
       userInfo = userInfo,
       error = null,
       metadata = null,
       authenticatedAt = authenticatedAt,
       refreshedAt = null;

  /// Create expired status
  AuthStatus.expired({
    String? error,
    required String accessToken,
    required DateTime authenticatedAt,
    DateTime? refreshedAt,
    User? userInfo,
  }) : state = AuthState.expired,
       accessToken = accessToken,
       claims = null,
       userInfo = userInfo,
       error = error,
       metadata = null,
       authenticatedAt = authenticatedAt,
       refreshedAt = refreshedAt;

  /// Create failed status
  AuthStatus.failed({required String error, Map<String, dynamic>? metadata})
    : state = AuthState.failed,
      accessToken = null,
      claims = null,
      userInfo = null,
      error = error,
      metadata = metadata,
      authenticatedAt = null,
      refreshedAt = null;

  /// Whether currently authenticated
  bool get isAuthenticated => state == AuthState.authenticated;

  /// Whether an access token is available (even if expired)
  bool get hasTokens => accessToken != null;

  /// Whether authentication is in progress
  bool get isLoading =>
      state == AuthState.authenticating || state == AuthState.refreshing;

  /// Whether access token needs refresh
  bool get needsRefresh {
    if (!hasTokens || claims == null) return false;
    return claims!.willExpireWithin(const Duration(minutes: 2));
  }

  /// Copy with new values
  AuthStatus copyWith({
    AuthState? state,
    String? accessToken,
    TokenClaims? claims,
    User? userInfo,
    String? error,
    Map<String, dynamic>? metadata,
    DateTime? authenticatedAt,
    DateTime? refreshedAt,
  }) {
    return AuthStatus(
      state: state ?? this.state,
      accessToken: accessToken ?? this.accessToken,
      claims: claims ?? this.claims,
      userInfo: userInfo ?? this.userInfo,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
      refreshedAt: refreshedAt ?? this.refreshedAt,
    );
  }

  @override
  List<Object?> get props => [
    state,
    accessToken,
    claims,
    userInfo,
    error,
    metadata,
    authenticatedAt,
    refreshedAt,
  ];

  @override
  String toString() {
    return 'AuthStatus(state: $state, hasTokens: $hasTokens, error: $error)';
  }
}
