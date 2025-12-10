/// Impersonation models for GroupVAN Admin SDK
///
/// Models for user impersonation feature allowing catalog_developer role users
/// to temporarily assume the identity of another user for debugging/support.
library impersonation;

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'impersonation.g.dart';

/// Two-factor authentication method used for impersonation
enum TwoFactorMethod {
  /// TOTP via authenticator app (Google Authenticator, Authy, etc.)
  @JsonValue('totp')
  totp,

  /// Email OTP (fallback option)
  @JsonValue('email')
  email,

  /// Passkey/WebAuthn (most secure - phishing-resistant)
  @JsonValue('passkey')
  passkey,
}

/// Reason for impersonation session ending
enum ImpersonationEndReason {
  @JsonValue('expired')
  expired,
  @JsonValue('manual')
  manual,
  @JsonValue('logout')
  logout,
  @JsonValue('refresh_limit')
  refreshLimit,
}

/// Request to start an impersonation session
///
/// Supports three 2FA methods (in priority order):
/// 1. Passkey: Provide [passkeyChallengeId] + [passkeyCredential]
/// 2. TOTP: Provide [twoFactorCode] (6-digit from authenticator app)
/// 3. Email OTP: Provide [twoFactorCode] (6-digit from email)
@JsonSerializable()
@immutable
class StartImpersonationRequest extends Equatable {
  /// The user ID to impersonate
  @JsonKey(name: 'target_user_id')
  final String targetUserId;

  /// Two-factor authentication code (TOTP or email OTP)
  /// Not required if using passkey authentication
  @JsonKey(name: 'two_factor_code')
  final String? twoFactorCode;

  /// Challenge ID from passkey authentication begin response
  /// Required when using passkey authentication
  @JsonKey(name: 'passkey_challenge_id')
  final String? passkeyChallengeId;

  /// Credential response from navigator.credentials.get()
  /// Required when using passkey authentication
  @JsonKey(name: 'passkey_credential')
  final Map<String, dynamic>? passkeyCredential;

  const StartImpersonationRequest({
    required this.targetUserId,
    this.twoFactorCode,
    this.passkeyChallengeId,
    this.passkeyCredential,
  });

  /// Create request for TOTP or email OTP authentication
  factory StartImpersonationRequest.withCode({
    required String targetUserId,
    required String twoFactorCode,
  }) =>
      StartImpersonationRequest(
        targetUserId: targetUserId,
        twoFactorCode: twoFactorCode,
      );

  /// Create request for passkey authentication
  factory StartImpersonationRequest.withPasskey({
    required String targetUserId,
    required String passkeyChallengeId,
    required Map<String, dynamic> passkeyCredential,
  }) =>
      StartImpersonationRequest(
        targetUserId: targetUserId,
        passkeyChallengeId: passkeyChallengeId,
        passkeyCredential: passkeyCredential,
      );

  factory StartImpersonationRequest.fromJson(Map<String, dynamic> json) =>
      _$StartImpersonationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartImpersonationRequestToJson(this);

  @override
  List<Object?> get props =>
      [targetUserId, twoFactorCode, passkeyChallengeId, passkeyCredential];
}

/// Request to end an impersonation session
@JsonSerializable()
@immutable
class EndImpersonationRequest extends Equatable {
  /// The impersonation session ID to end
  @JsonKey(name: 'impersonation_session_id')
  final String impersonationSessionId;

  const EndImpersonationRequest({required this.impersonationSessionId});

  factory EndImpersonationRequest.fromJson(Map<String, dynamic> json) =>
      _$EndImpersonationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EndImpersonationRequestToJson(this);

  @override
  List<Object?> get props => [impersonationSessionId];
}

/// Target user information returned in impersonation response
@JsonSerializable()
@immutable
class ImpersonationTargetUser extends Equatable {
  /// Target user's ID
  final String id;

  /// Target user's email
  final String email;

  /// Target user's name
  final String name;

  /// Target user's member organization ID
  @JsonKey(name: 'member_id')
  final String? memberId;

  const ImpersonationTargetUser({
    required this.id,
    required this.email,
    required this.name,
    this.memberId,
  });

  factory ImpersonationTargetUser.fromJson(Map<String, dynamic> json) =>
      _$ImpersonationTargetUserFromJson(json);

  Map<String, dynamic> toJson() => _$ImpersonationTargetUserToJson(this);

  @override
  List<Object?> get props => [id, email, name, memberId];
}

/// Response from starting an impersonation session
@JsonSerializable()
@immutable
class ImpersonationResponse extends Equatable {
  /// JWT access token for the impersonation session
  @JsonKey(name: 'access_token')
  final String accessToken;

  /// JWT refresh token for the impersonation session
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  /// Token expiration time in seconds
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  /// Token type (typically 'Bearer')
  @JsonKey(name: 'token_type', defaultValue: 'Bearer')
  final String tokenType;

  /// Unique identifier for this impersonation session
  @JsonKey(name: 'impersonation_session_id')
  final String impersonationSessionId;

  /// When the impersonation session expires (max 1 hour)
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  /// Information about the user being impersonated
  @JsonKey(name: 'target_user')
  final ImpersonationTargetUser targetUser;

  const ImpersonationResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
    required this.impersonationSessionId,
    required this.expiresAt,
    required this.targetUser,
  });

  factory ImpersonationResponse.fromJson(Map<String, dynamic> json) =>
      _$ImpersonationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ImpersonationResponseToJson(this);

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        expiresIn,
        tokenType,
        impersonationSessionId,
        expiresAt,
        targetUser,
      ];
}

/// Response from ending an impersonation session
@JsonSerializable()
@immutable
class EndImpersonationResponse extends Equatable {
  /// JWT access token for the admin's original session
  @JsonKey(name: 'access_token')
  final String accessToken;

  /// JWT refresh token for the admin's original session
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  /// Token expiration time in seconds
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  /// Token type (typically 'Bearer')
  @JsonKey(name: 'token_type', defaultValue: 'Bearer')
  final String tokenType;

  const EndImpersonationResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  factory EndImpersonationResponse.fromJson(Map<String, dynamic> json) =>
      _$EndImpersonationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EndImpersonationResponseToJson(this);

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresIn, tokenType];
}

/// Record of an impersonation session for audit purposes
@JsonSerializable()
@immutable
class ImpersonationSession extends Equatable {
  /// Unique session identifier
  final String id;

  /// User ID of the admin who initiated impersonation
  @JsonKey(name: 'admin_user_id')
  final String adminUserId;

  /// Email of the admin who initiated impersonation
  @JsonKey(name: 'admin_email')
  final String? adminEmail;

  /// User ID being impersonated
  @JsonKey(name: 'target_user_id')
  final String targetUserId;

  /// Email of the user being impersonated
  @JsonKey(name: 'target_email')
  final String? targetEmail;

  /// When the session started
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// When the session expires
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  /// When the session actually ended (if ended early)
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;

  /// Reason the session ended
  @JsonKey(name: 'end_reason')
  final ImpersonationEndReason? endReason;

  /// IP address of the admin when starting impersonation
  @JsonKey(name: 'ip_address')
  final String? ipAddress;

  /// User agent of the admin's browser/client
  @JsonKey(name: 'user_agent')
  final String? userAgent;

  /// 2FA method used to authorize impersonation
  @JsonKey(name: 'two_factor_method')
  final TwoFactorMethod twoFactorMethod;

  /// Number of token refreshes during this session
  @JsonKey(name: 'refresh_count')
  final int refreshCount;

  const ImpersonationSession({
    required this.id,
    required this.adminUserId,
    this.adminEmail,
    required this.targetUserId,
    this.targetEmail,
    required this.createdAt,
    required this.expiresAt,
    this.endedAt,
    this.endReason,
    this.ipAddress,
    this.userAgent,
    required this.twoFactorMethod,
    this.refreshCount = 0,
  });

  factory ImpersonationSession.fromJson(Map<String, dynamic> json) =>
      _$ImpersonationSessionFromJson(json);

  Map<String, dynamic> toJson() => _$ImpersonationSessionToJson(this);

  /// Whether this session is currently active
  bool get isActive =>
      endedAt == null && DateTime.now().isBefore(expiresAt);

  /// Time remaining until session expires
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  @override
  List<Object?> get props => [
        id,
        adminUserId,
        adminEmail,
        targetUserId,
        targetEmail,
        createdAt,
        expiresAt,
        endedAt,
        endReason,
        ipAddress,
        userAgent,
        twoFactorMethod,
        refreshCount,
      ];
}

/// Response containing list of impersonation sessions
@JsonSerializable()
@immutable
class ImpersonationSessionsResponse extends Equatable {
  /// List of impersonation sessions
  final List<ImpersonationSession> sessions;

  /// Total number of sessions matching the query
  final int total;

  const ImpersonationSessionsResponse({
    required this.sessions,
    required this.total,
  });

  factory ImpersonationSessionsResponse.fromJson(Map<String, dynamic> json) =>
      _$ImpersonationSessionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ImpersonationSessionsResponseToJson(this);

  @override
  List<Object?> get props => [sessions, total];
}
