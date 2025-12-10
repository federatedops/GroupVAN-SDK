/// GroupVAN Admin Client for impersonation and 2FA
///
/// Provides admin functionality for catalog_developer role users including:
/// - User impersonation for debugging/support
/// - Two-factor authentication setup and verification (TOTP, email OTP, passkey)
/// - Passkey/WebAuthn registration and management
library admin_client;

import 'package:dio/dio.dart';

import '../auth/auth_manager.dart';
import '../core/exceptions.dart';
import '../core/http_client.dart';
import '../core/response.dart';
import '../logging.dart';
import '../models/admin/admin.dart';

/// Admin API client for impersonation and 2FA management
///
/// This client provides methods for:
/// - Starting and ending user impersonation sessions
/// - Setting up and verifying TOTP 2FA
/// - Requesting email OTP as fallback
/// - Registering and managing passkeys (WebAuthn)
/// - Viewing impersonation session history
///
/// Only users with the `catalog_developer` role can use these endpoints.
class AdminClient {
  final GroupVanHttpClient _httpClient;
  final AuthManager _authManager;

  /// Callback invoked when impersonation starts
  final void Function(ImpersonationResponse)? onImpersonationStart;

  /// Callback invoked when impersonation ends
  final void Function(EndImpersonationResponse)? onImpersonationEnd;

  const AdminClient(
    this._httpClient,
    this._authManager, {
    this.onImpersonationStart,
    this.onImpersonationEnd,
  });

  /// Make an authenticated request with admin token
  Future<GroupVanResponse<T>> _authenticatedRequest<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? decoder,
  }) async {
    final accessToken = _authManager.currentStatus.accessToken;
    if (accessToken == null) {
      throw AuthenticationException(
        'Not authenticated',
        errorType: AuthErrorType.missingToken,
      );
    }

    final options = Options(
      method: method,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    switch (method.toUpperCase()) {
      case 'GET':
        return await _httpClient.get<T>(
          path,
          queryParameters: queryParameters,
          decoder: decoder,
          options: options,
        );
      case 'POST':
        return await _httpClient.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          decoder: decoder,
          options: options,
        );
      case 'DELETE':
        return await _httpClient.delete<T>(
          path,
          queryParameters: queryParameters,
          decoder: decoder,
          options: options,
        );
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  // ============================================
  // Impersonation Methods
  // ============================================

  /// Start impersonating another user with TOTP or email OTP
  ///
  /// Requires:
  /// - `catalog_developer` role
  /// - Valid 2FA code (TOTP or email OTP)
  ///
  /// The target user cannot be another admin/developer.
  /// Impersonation sessions last a maximum of 1 hour.
  ///
  /// For passkey authentication, use [startImpersonationWithPasskey] instead.
  ///
  /// Returns tokens for the impersonation session.
  Future<Result<ImpersonationResponse>> startImpersonation({
    required String targetUserId,
    required String twoFactorCode,
  }) async {
    try {
      final request = StartImpersonationRequest.withCode(
        targetUserId: targetUserId,
        twoFactorCode: twoFactorCode,
      );

      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'POST',
        path: '/v3/admin/impersonate',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      final impersonationResponse = ImpersonationResponse.fromJson(response.data);

      // Notify callback if set
      onImpersonationStart?.call(impersonationResponse);

      GroupVanLogger.admin.info(
        'Started impersonation session: ${impersonationResponse.impersonationSessionId}',
      );

      return Success(impersonationResponse);
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to start impersonation: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to start impersonation: $e'),
      );
    }
  }

  /// Start impersonating another user with passkey authentication
  ///
  /// Requires:
  /// - `catalog_developer` role
  /// - Valid passkey credential from [beginPasskeyAuthentication]
  ///
  /// This is the most secure impersonation method (phishing-resistant).
  ///
  /// The target user cannot be another admin/developer.
  /// Impersonation sessions last a maximum of 1 hour.
  ///
  /// Returns tokens for the impersonation session.
  Future<Result<ImpersonationResponse>> startImpersonationWithPasskey({
    required String targetUserId,
    required String passkeyChallengeId,
    required Map<String, dynamic> passkeyCredential,
  }) async {
    try {
      final request = StartImpersonationRequest.withPasskey(
        targetUserId: targetUserId,
        passkeyChallengeId: passkeyChallengeId,
        passkeyCredential: passkeyCredential,
      );

      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'POST',
        path: '/v3/admin/impersonate',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      final impersonationResponse = ImpersonationResponse.fromJson(response.data);

      // Notify callback if set
      onImpersonationStart?.call(impersonationResponse);

      GroupVanLogger.admin.info(
        'Started impersonation session with passkey: ${impersonationResponse.impersonationSessionId}',
      );

      return Success(impersonationResponse);
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to start impersonation with passkey: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to start impersonation with passkey: $e'),
      );
    }
  }

  /// End the current impersonation session
  ///
  /// Returns the admin's original tokens.
  Future<Result<EndImpersonationResponse>> endImpersonation({
    required String impersonationSessionId,
  }) async {
    try {
      final request = EndImpersonationRequest(
        impersonationSessionId: impersonationSessionId,
      );

      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'POST',
        path: '/v3/admin/impersonate/end',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      final endResponse = EndImpersonationResponse.fromJson(response.data);

      // Notify callback if set
      onImpersonationEnd?.call(endResponse);

      GroupVanLogger.admin.info(
        'Ended impersonation session: $impersonationSessionId',
      );

      return Success(endResponse);
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to end impersonation: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to end impersonation: $e'),
      );
    }
  }

  /// Get impersonation session history
  ///
  /// Returns recent impersonation sessions for audit purposes.
  /// Can filter by admin user ID or target user ID.
  Future<Result<ImpersonationSessionsResponse>> getImpersonationSessions({
    String? adminUserId,
    String? targetUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (adminUserId != null) {
        queryParams['admin_user_id'] = adminUserId;
      }
      if (targetUserId != null) {
        queryParams['target_user_id'] = targetUserId;
      }

      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'GET',
        path: '/v3/admin/impersonate/sessions',
        queryParameters: queryParams,
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(ImpersonationSessionsResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to get impersonation sessions: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get impersonation sessions: $e'),
      );
    }
  }

  // ============================================
  // Two-Factor Authentication Methods
  // ============================================

  /// Get current 2FA status
  ///
  /// Returns whether TOTP is enabled and email OTP availability.
  Future<Result<TwoFactorStatus>> getTwoFactorStatus() async {
    try {
      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'GET',
        path: '/v3/admin/2fa/status',
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(TwoFactorStatus.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to get 2FA status: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get 2FA status: $e'),
      );
    }
  }

  /// Set up TOTP 2FA
  ///
  /// Returns the secret and QR code URI for the authenticator app.
  /// After scanning, call [verifyTwoFactor] to complete setup.
  Future<Result<TwoFactorSetupResponse>> setupTwoFactor() async {
    try {
      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'POST',
        path: '/v3/admin/2fa/setup',
        decoder: (data) => data as Map<String, dynamic>,
      );

      GroupVanLogger.admin.info('Generated TOTP setup for user');
      return Success(TwoFactorSetupResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to setup 2FA: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to setup 2FA: $e'),
      );
    }
  }

  /// Verify TOTP code to complete 2FA setup
  ///
  /// Call this after [setupTwoFactor] with the code from the authenticator app.
  Future<Result<TwoFactorVerifyResponse>> verifyTwoFactor({
    required String code,
  }) async {
    try {
      final request = TwoFactorVerifyRequest(code: code);

      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'POST',
        path: '/v3/admin/2fa/verify',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      final verifyResponse = TwoFactorVerifyResponse.fromJson(response.data);

      if (verifyResponse.success) {
        GroupVanLogger.admin.info('TOTP 2FA verified and enabled');
      } else {
        GroupVanLogger.admin.warning('TOTP verification failed: ${verifyResponse.message}');
      }

      return Success(verifyResponse);
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to verify 2FA: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to verify 2FA: $e'),
      );
    }
  }

  /// Request email OTP as fallback
  ///
  /// Sends a 6-digit OTP to the admin's email address.
  /// Rate limited to 3 requests per 15 minutes.
  Future<Result<EmailOtpResponse>> requestEmailOtp() async {
    try {
      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'POST',
        path: '/v3/admin/2fa/email-otp',
        decoder: (data) => data as Map<String, dynamic>,
      );

      final otpResponse = EmailOtpResponse.fromJson(response.data);

      if (otpResponse.success) {
        GroupVanLogger.admin.info('Email OTP requested: ${otpResponse.message}');
      }

      return Success(otpResponse);
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to request email OTP: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to request email OTP: $e'),
      );
    }
  }

  // ============================================
  // Passkey/WebAuthn Methods
  // ============================================

  /// Get list of registered passkeys
  ///
  /// Returns all active passkeys for the current user.
  Future<Result<PasskeyListResponse>> getPasskeys() async {
    try {
      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'GET',
        path: '/v3/admin/2fa/passkeys',
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(PasskeyListResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to get passkeys: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to get passkeys: $e'),
      );
    }
  }

  /// Begin passkey registration ceremony
  ///
  /// Returns WebAuthn options for navigator.credentials.create().
  ///
  /// Usage:
  /// 1. Call this method to get registration options
  /// 2. Call navigator.credentials.create() with [PasskeyRegistrationBeginResponse.options]
  /// 3. Call [completePasskeyRegistration] with the credential
  Future<Result<PasskeyRegistrationBeginResponse>> beginPasskeyRegistration() async {
    try {
      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'POST',
        path: '/v3/admin/2fa/passkey/register/begin',
        decoder: (data) => data as Map<String, dynamic>,
      );

      GroupVanLogger.admin.info('Passkey registration ceremony started');
      return Success(PasskeyRegistrationBeginResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to begin passkey registration: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to begin passkey registration: $e'),
      );
    }
  }

  /// Complete passkey registration ceremony
  ///
  /// Call this after [beginPasskeyRegistration] with the credential
  /// from navigator.credentials.create().
  ///
  /// [challengeId] - The challenge ID from [beginPasskeyRegistration]
  /// [credential] - The credential response from navigator.credentials.create()
  /// [deviceName] - Optional user-friendly name for the passkey
  Future<Result<PasskeyRegistrationCompleteResponse>> completePasskeyRegistration({
    required String challengeId,
    required Map<String, dynamic> credential,
    String? deviceName,
  }) async {
    try {
      final request = PasskeyRegistrationCompleteRequest(
        challengeId: challengeId,
        credential: credential,
        deviceName: deviceName,
      );

      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'POST',
        path: '/v3/admin/2fa/passkey/register/complete',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      GroupVanLogger.admin.info('Passkey registered successfully');
      return Success(PasskeyRegistrationCompleteResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to complete passkey registration: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to complete passkey registration: $e'),
      );
    }
  }

  /// Begin passkey authentication ceremony
  ///
  /// Returns WebAuthn options for navigator.credentials.get().
  /// Use this before impersonation to verify identity with a passkey.
  ///
  /// Usage:
  /// 1. Call this method to get authentication options
  /// 2. Call navigator.credentials.get() with [PasskeyAuthenticationBeginResponse.options]
  /// 3. Call [startImpersonationWithPasskey] with the credential
  Future<Result<PasskeyAuthenticationBeginResponse>> beginPasskeyAuthentication() async {
    try {
      final response = await _authenticatedRequest<Map<String, dynamic>>(
        method: 'POST',
        path: '/v3/admin/2fa/passkey/authenticate/begin',
        decoder: (data) => data as Map<String, dynamic>,
      );

      GroupVanLogger.admin.info('Passkey authentication ceremony started');
      return Success(PasskeyAuthenticationBeginResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to begin passkey authentication: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to begin passkey authentication: $e'),
      );
    }
  }

  /// Revoke/delete a passkey
  ///
  /// The passkey will no longer be usable for authentication.
  Future<Result<bool>> revokePasskey({required String passkeyId}) async {
    try {
      await _authenticatedRequest<Map<String, dynamic>>(
        method: 'DELETE',
        path: '/v3/admin/2fa/passkey/$passkeyId',
        decoder: (data) => data as Map<String, dynamic>,
      );

      GroupVanLogger.admin.info('Passkey revoked: $passkeyId');
      return const Success(true);
    } catch (e) {
      GroupVanLogger.admin.severe('Failed to revoke passkey: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to revoke passkey: $e'),
      );
    }
  }
}

/// High-level admin interface for the GroupVAN SDK
///
/// Provides convenient methods for impersonation with automatic
/// token management through the AuthManager.
class GroupVANAdmin {
  final AdminClient _client;
  final AuthManager _authManager;

  /// Current impersonation session (if any)
  ImpersonationSession? _currentSession;

  GroupVANAdmin(GroupVanHttpClient httpClient, AuthManager authManager)
      : _client = AdminClient(httpClient, authManager),
        _authManager = authManager;

  /// Whether currently impersonating another user
  bool get isImpersonating => _currentSession != null;

  /// Current impersonation session details
  ImpersonationSession? get currentImpersonation => _currentSession;

  /// Start impersonating a user with TOTP or email OTP
  ///
  /// Requires valid 2FA code. Automatically manages token switching.
  /// For passkey authentication, use [startImpersonationWithPasskey].
  Future<ImpersonationSession> startImpersonation({
    required String targetUserId,
    required String twoFactorCode,
  }) async {
    if (isImpersonating) {
      throw StateError(
        'Already impersonating a user. End the current session first.',
      );
    }

    final result = await _client.startImpersonation(
      targetUserId: targetUserId,
      twoFactorCode: twoFactorCode,
    );

    if (result.isFailure) {
      throw result.error;
    }

    final response = result.value;

    // Create session record
    _currentSession = ImpersonationSession(
      id: response.impersonationSessionId,
      adminUserId: _authManager.currentStatus.claims?.userId ?? '',
      targetUserId: targetUserId,
      targetEmail: response.targetUser.email,
      createdAt: DateTime.now(),
      expiresAt: response.expiresAt,
      twoFactorMethod: TwoFactorMethod.totp,
    );

    return _currentSession!;
  }

  /// Start impersonating a user with passkey authentication
  ///
  /// This is the most secure method (phishing-resistant).
  /// Requires passkey credential from [beginPasskeyAuthentication].
  Future<ImpersonationSession> startImpersonationWithPasskey({
    required String targetUserId,
    required String passkeyChallengeId,
    required Map<String, dynamic> passkeyCredential,
  }) async {
    if (isImpersonating) {
      throw StateError(
        'Already impersonating a user. End the current session first.',
      );
    }

    final result = await _client.startImpersonationWithPasskey(
      targetUserId: targetUserId,
      passkeyChallengeId: passkeyChallengeId,
      passkeyCredential: passkeyCredential,
    );

    if (result.isFailure) {
      throw result.error;
    }

    final response = result.value;

    // Create session record
    _currentSession = ImpersonationSession(
      id: response.impersonationSessionId,
      adminUserId: _authManager.currentStatus.claims?.userId ?? '',
      targetUserId: targetUserId,
      targetEmail: response.targetUser.email,
      createdAt: DateTime.now(),
      expiresAt: response.expiresAt,
      twoFactorMethod: TwoFactorMethod.passkey,
    );

    return _currentSession!;
  }

  /// End the current impersonation session
  ///
  /// Automatically restores original admin tokens.
  Future<void> endImpersonation() async {
    if (!isImpersonating || _currentSession == null) {
      throw StateError('Not currently impersonating a user.');
    }

    final result = await _client.endImpersonation(
      impersonationSessionId: _currentSession!.id,
    );

    // Clear impersonation state regardless of result
    _currentSession = null;

    if (result.isFailure) {
      throw result.error;
    }
  }

  /// Get impersonation history for audit
  Future<List<ImpersonationSession>> getImpersonationHistory({
    int limit = 50,
  }) async {
    final result = await _client.getImpersonationSessions(limit: limit);

    if (result.isFailure) {
      throw result.error;
    }

    return result.value.sessions;
  }

  /// Get current 2FA status
  Future<TwoFactorStatus> getTwoFactorStatus() async {
    final result = await _client.getTwoFactorStatus();

    if (result.isFailure) {
      throw result.error;
    }

    return result.value;
  }

  /// Set up TOTP 2FA
  ///
  /// Returns setup information including QR code URI for scanning.
  Future<TwoFactorSetupResponse> setupTwoFactor() async {
    final result = await _client.setupTwoFactor();

    if (result.isFailure) {
      throw result.error;
    }

    return result.value;
  }

  /// Verify TOTP code to complete 2FA setup
  Future<bool> verifyTwoFactor({required String code}) async {
    final result = await _client.verifyTwoFactor(code: code);

    if (result.isFailure) {
      throw result.error;
    }

    return result.value.verified;
  }

  /// Request email OTP
  Future<EmailOtpResponse> requestEmailOtp() async {
    final result = await _client.requestEmailOtp();

    if (result.isFailure) {
      throw result.error;
    }

    return result.value;
  }

  // ============================================
  // Passkey Methods
  // ============================================

  /// Get list of registered passkeys
  Future<List<PasskeyInfo>> getPasskeys() async {
    final result = await _client.getPasskeys();

    if (result.isFailure) {
      throw result.error;
    }

    return result.value.passkeys;
  }

  /// Begin passkey registration
  ///
  /// Returns options for navigator.credentials.create().
  /// After getting the credential, call [completePasskeyRegistration].
  Future<PasskeyRegistrationBeginResponse> beginPasskeyRegistration() async {
    final result = await _client.beginPasskeyRegistration();

    if (result.isFailure) {
      throw result.error;
    }

    return result.value;
  }

  /// Complete passkey registration
  ///
  /// [challengeId] - From [beginPasskeyRegistration] response
  /// [credential] - From navigator.credentials.create()
  /// [deviceName] - Optional friendly name for the passkey
  Future<PasskeyRegistrationCompleteResponse> completePasskeyRegistration({
    required String challengeId,
    required Map<String, dynamic> credential,
    String? deviceName,
  }) async {
    final result = await _client.completePasskeyRegistration(
      challengeId: challengeId,
      credential: credential,
      deviceName: deviceName,
    );

    if (result.isFailure) {
      throw result.error;
    }

    return result.value;
  }

  /// Begin passkey authentication for impersonation
  ///
  /// Returns options for navigator.credentials.get().
  /// After getting the credential, call [startImpersonationWithPasskey].
  Future<PasskeyAuthenticationBeginResponse> beginPasskeyAuthentication() async {
    final result = await _client.beginPasskeyAuthentication();

    if (result.isFailure) {
      throw result.error;
    }

    return result.value;
  }

  /// Revoke/delete a passkey
  Future<void> revokePasskey({required String passkeyId}) async {
    final result = await _client.revokePasskey(passkeyId: passkeyId);

    if (result.isFailure) {
      throw result.error;
    }
  }
}
