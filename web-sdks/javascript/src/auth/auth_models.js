/**
 * Authentication models for GroupVAN SDK
 *
 * Models the JWT-based authentication system used by GroupVAN API.
 */

/**
 * Login request model
 */
export class LoginRequest {
  /**
   * @param {Object} options
   * @param {string} options.email - Email for authentication
   * @param {string} options.password - Password for authentication
   */
  constructor({ email, password }) {
    this.email = email;
    this.password = password;
  }

  toJson() {
    return {
      email: this.email,
      password: this.password,
    };
  }

  static fromJson(json) {
    return new LoginRequest({
      email: json.email,
      password: json.password,
    });
  }
}

/**
 * Token response from authentication endpoints
 */
export class TokenResponse {
  /**
   * @param {Object} options
   * @param {string} options.accessToken - JWT access token for API requests
   * @param {string} options.refreshToken - JWT refresh token for obtaining new access tokens
   * @param {number} options.expiresIn - Token expiration time in seconds
   * @param {string} [options.tokenType='Bearer'] - Token type
   */
  constructor({ accessToken, refreshToken, expiresIn, tokenType = 'Bearer' }) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.expiresIn = expiresIn;
    this.tokenType = tokenType;
  }

  toJson() {
    return {
      access_token: this.accessToken,
      refresh_token: this.refreshToken,
      expires_in: this.expiresIn,
      token_type: this.tokenType,
    };
  }

  static fromJson(json) {
    return new TokenResponse({
      accessToken: json.access_token,
      refreshToken: json.refresh_token,
      expiresIn: json.expires_in,
      tokenType: json.token_type || 'Bearer',
    });
  }
}

/**
 * Refresh token request
 */
export class RefreshTokenRequest {
  /**
   * @param {Object} options
   * @param {string} options.refreshToken - Refresh token to use for generating new access token
   */
  constructor({ refreshToken }) {
    this.refreshToken = refreshToken;
  }

  toJson() {
    return {
      refresh_token: this.refreshToken,
    };
  }

  static fromJson(json) {
    return new RefreshTokenRequest({
      refreshToken: json.refresh_token,
    });
  }
}

/**
 * Logout request
 */
export class LogoutRequest {
  /**
   * @param {Object} options
   * @param {string} options.refreshToken - Refresh token to blacklist
   */
  constructor({ refreshToken }) {
    this.refreshToken = refreshToken;
  }

  toJson() {
    return {
      refresh_token: this.refreshToken,
    };
  }

  static fromJson(json) {
    return new LogoutRequest({
      refreshToken: json.refresh_token,
    });
  }
}

/**
 * JWT token claims decoded from access token
 */
export class TokenClaims {
  /**
   * @param {Object} options
   * @param {string} options.userId - User ID from the token
   * @param {string} [options.type='access'] - Token type (access/refresh)
   * @param {number} options.issuedAt - Token issued at timestamp (seconds)
   * @param {number} options.expiration - Token expiration timestamp (seconds)
   * @param {string} options.jti - Token JTI (unique identifier)
   * @param {string} [options.member] - Member ID if present
   */
  constructor({ userId, type = 'access', issuedAt, expiration, jti, member = null }) {
    this.userId = userId;
    this.type = type;
    this.issuedAt = issuedAt;
    this.expiration = expiration;
    this.jti = jti;
    this.member = member;
  }

  /**
   * Whether the token is expired
   * @returns {boolean}
   */
  get isExpired() {
    return Date.now() > this.expiration * 1000;
  }

  /**
   * Whether the token will expire within the given duration
   * @param {number} durationMs - Duration in milliseconds
   * @returns {boolean}
   */
  willExpireWithin(durationMs) {
    const expirationTime = new Date(this.expiration * 1000);
    const threshold = new Date(Date.now() + durationMs);
    return expirationTime < threshold;
  }

  /**
   * Time until token expires in milliseconds
   * @returns {number}
   */
  get timeUntilExpirationMs() {
    const expirationTime = this.expiration * 1000;
    const now = Date.now();
    if (expirationTime < now) {
      return 0;
    }
    return expirationTime - now;
  }

  toJson() {
    return {
      sub: this.userId,
      type: this.type,
      iat: this.issuedAt,
      exp: this.expiration,
      jti: this.jti,
      member: this.member,
    };
  }

  static fromJson(json) {
    return new TokenClaims({
      userId: json.sub,
      type: json.type || 'access',
      issuedAt: json.iat,
      expiration: json.exp,
      jti: json.jti,
      member: json.member,
    });
  }
}

/**
 * Authentication state
 * @enum {string}
 */
export const AuthState = {
  UNAUTHENTICATED: 'unauthenticated',
  AUTHENTICATING: 'authenticating',
  AUTHENTICATED: 'authenticated',
  REFRESHING: 'refreshing',
  EXPIRED: 'expired',
  FAILED: 'failed',
};

/**
 * Current authentication status
 */
export class AuthStatus {
  /**
   * @param {Object} options
   * @param {string} options.state - Current authentication state
   * @param {string} [options.accessToken] - Access token if authenticated
   * @param {string} [options.refreshToken] - Refresh token if authenticated
   * @param {TokenClaims} [options.claims] - Decoded token claims if available
   * @param {Object} [options.userInfo] - User info object
   * @param {string} [options.error] - Last authentication error if any
   * @param {Object} [options.metadata] - Additional metadata
   * @param {Date} [options.authenticatedAt] - Timestamp of last successful authentication
   * @param {Date} [options.refreshedAt] - Timestamp of last token refresh
   */
  constructor({
    state,
    accessToken = null,
    refreshToken = null,
    claims = null,
    userInfo = null,
    error = null,
    metadata = null,
    authenticatedAt = null,
    refreshedAt = null,
  }) {
    this.state = state;
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.claims = claims;
    this.userInfo = userInfo;
    this.error = error;
    this.metadata = metadata;
    this.authenticatedAt = authenticatedAt;
    this.refreshedAt = refreshedAt;
  }

  /**
   * Create unauthenticated status
   * @returns {AuthStatus}
   */
  static unauthenticated() {
    return new AuthStatus({ state: AuthState.UNAUTHENTICATED });
  }

  /**
   * Create authenticating status
   * @returns {AuthStatus}
   */
  static authenticating() {
    return new AuthStatus({ state: AuthState.AUTHENTICATING });
  }

  /**
   * Create authenticated status
   * @param {Object} options
   * @param {string} options.accessToken
   * @param {string} options.refreshToken
   * @param {TokenClaims} options.claims
   * @param {Object} [options.userInfo]
   * @returns {AuthStatus}
   */
  static authenticated({ accessToken, refreshToken, claims, userInfo = null }) {
    return new AuthStatus({
      state: AuthState.AUTHENTICATED,
      accessToken,
      refreshToken,
      claims,
      userInfo,
      authenticatedAt: new Date(),
    });
  }

  /**
   * Create refreshing status
   * @param {Object} options
   * @param {string} options.accessToken
   * @param {string} options.refreshToken
   * @param {TokenClaims} options.claims
   * @param {Date} options.authenticatedAt
   * @param {Object} [options.userInfo]
   * @returns {AuthStatus}
   */
  static refreshing({ accessToken, refreshToken, claims, authenticatedAt, userInfo = null }) {
    return new AuthStatus({
      state: AuthState.REFRESHING,
      accessToken,
      refreshToken,
      claims,
      userInfo,
      authenticatedAt,
    });
  }

  /**
   * Create expired status
   * @param {Object} options
   * @param {string} [options.error]
   * @param {string} options.accessToken
   * @param {string} options.refreshToken
   * @param {Date} options.authenticatedAt
   * @param {Date} [options.refreshedAt]
   * @param {Object} [options.userInfo]
   * @returns {AuthStatus}
   */
  static expired({ error = null, accessToken, refreshToken, authenticatedAt, refreshedAt = null, userInfo = null }) {
    return new AuthStatus({
      state: AuthState.EXPIRED,
      accessToken,
      refreshToken,
      userInfo,
      error,
      authenticatedAt,
      refreshedAt,
    });
  }

  /**
   * Create failed status
   * @param {Object} options
   * @param {string} options.error
   * @param {Object} [options.metadata]
   * @returns {AuthStatus}
   */
  static failed({ error, metadata = null }) {
    return new AuthStatus({
      state: AuthState.FAILED,
      error,
      metadata,
    });
  }

  /**
   * Whether currently authenticated
   * @returns {boolean}
   */
  get isAuthenticated() {
    return this.state === AuthState.AUTHENTICATED;
  }

  /**
   * Whether tokens are available (even if expired)
   * @returns {boolean}
   */
  get hasTokens() {
    return this.accessToken !== null && this.refreshToken !== null;
  }

  /**
   * Whether authentication is in progress
   * @returns {boolean}
   */
  get isLoading() {
    return this.state === AuthState.AUTHENTICATING || this.state === AuthState.REFRESHING;
  }

  /**
   * Whether access token needs refresh
   * @returns {boolean}
   */
  get needsRefresh() {
    if (!this.hasTokens || !this.claims) return false;
    return this.claims.willExpireWithin(2 * 60 * 1000); // 2 minutes
  }

  /**
   * Copy with new values
   * @param {Object} overrides
   * @returns {AuthStatus}
   */
  copyWith(overrides = {}) {
    return new AuthStatus({
      state: overrides.state ?? this.state,
      accessToken: overrides.accessToken ?? this.accessToken,
      refreshToken: overrides.refreshToken ?? this.refreshToken,
      claims: overrides.claims ?? this.claims,
      userInfo: overrides.userInfo ?? this.userInfo,
      error: overrides.error ?? this.error,
      metadata: overrides.metadata ?? this.metadata,
      authenticatedAt: overrides.authenticatedAt ?? this.authenticatedAt,
      refreshedAt: overrides.refreshedAt ?? this.refreshedAt,
    });
  }

  toString() {
    return `AuthStatus(state: ${this.state}, hasTokens: ${this.hasTokens}, error: ${this.error})`;
  }
}
