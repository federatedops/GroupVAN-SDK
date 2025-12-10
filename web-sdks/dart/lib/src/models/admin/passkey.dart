/// Passkey/WebAuthn models for GroupVAN Admin SDK
///
/// Models for passkey registration and authentication used as 2FA
/// for impersonation. Passkeys are the most secure 2FA option,
/// providing phishing-resistant authentication using biometrics
/// (Touch ID, Face ID, Windows Hello) or hardware security keys.
library passkey;

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'passkey.g.dart';

/// Type of authenticator used for passkey
enum PasskeyAuthenticatorType {
  /// Built-in authenticator (Touch ID, Face ID, Windows Hello)
  @JsonValue('platform')
  platform,

  /// External hardware key (YubiKey, etc.)
  @JsonValue('cross-platform')
  crossPlatform,
}

/// Information about a registered passkey
@JsonSerializable()
@immutable
class PasskeyInfo extends Equatable {
  /// Unique passkey identifier
  final String id;

  /// User-friendly device name (e.g., "MacBook Pro Touch ID")
  @JsonKey(name: 'device_name')
  final String deviceName;

  /// Type of authenticator (platform or cross-platform)
  @JsonKey(name: 'authenticator_type')
  final String authenticatorType;

  /// When the passkey was registered
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// When the passkey was last used for authentication
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;

  const PasskeyInfo({
    required this.id,
    required this.deviceName,
    required this.authenticatorType,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory PasskeyInfo.fromJson(Map<String, dynamic> json) =>
      _$PasskeyInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PasskeyInfoToJson(this);

  /// Whether this is a platform authenticator (biometric)
  bool get isPlatformAuthenticator => authenticatorType == 'platform';

  /// Whether this is a cross-platform authenticator (hardware key)
  bool get isCrossPlatformAuthenticator =>
      authenticatorType == 'cross-platform';

  @override
  List<Object?> get props =>
      [id, deviceName, authenticatorType, createdAt, lastUsedAt];
}

/// Response containing list of passkeys
@JsonSerializable()
@immutable
class PasskeyListResponse extends Equatable {
  /// List of registered passkeys
  final List<PasskeyInfo> passkeys;

  /// Total number of passkeys
  final int total;

  const PasskeyListResponse({
    required this.passkeys,
    required this.total,
  });

  factory PasskeyListResponse.fromJson(Map<String, dynamic> json) =>
      _$PasskeyListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PasskeyListResponseToJson(this);

  @override
  List<Object?> get props => [passkeys, total];
}

/// Response from beginning passkey registration
///
/// Contains the WebAuthn options to pass to navigator.credentials.create()
@JsonSerializable()
@immutable
class PasskeyRegistrationBeginResponse extends Equatable {
  /// Challenge ID to include when completing registration
  @JsonKey(name: 'challenge_id')
  final String challengeId;

  /// WebAuthn PublicKeyCredentialCreationOptions as a Map
  /// Pass directly to navigator.credentials.create()
  final Map<String, dynamic> options;

  const PasskeyRegistrationBeginResponse({
    required this.challengeId,
    required this.options,
  });

  factory PasskeyRegistrationBeginResponse.fromJson(
          Map<String, dynamic> json) =>
      _$PasskeyRegistrationBeginResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PasskeyRegistrationBeginResponseToJson(this);

  @override
  List<Object?> get props => [challengeId, options];
}

/// Request to complete passkey registration
@JsonSerializable()
@immutable
class PasskeyRegistrationCompleteRequest extends Equatable {
  /// Challenge ID from begin registration response
  @JsonKey(name: 'challenge_id')
  final String challengeId;

  /// Credential response from navigator.credentials.create()
  final Map<String, dynamic> credential;

  /// Optional user-friendly name for this passkey
  @JsonKey(name: 'device_name')
  final String? deviceName;

  const PasskeyRegistrationCompleteRequest({
    required this.challengeId,
    required this.credential,
    this.deviceName,
  });

  factory PasskeyRegistrationCompleteRequest.fromJson(
          Map<String, dynamic> json) =>
      _$PasskeyRegistrationCompleteRequestFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PasskeyRegistrationCompleteRequestToJson(this);

  @override
  List<Object?> get props => [challengeId, credential, deviceName];
}

/// Response from completing passkey registration
@JsonSerializable()
@immutable
class PasskeyRegistrationCompleteResponse extends Equatable {
  /// Unique identifier for the registered passkey
  @JsonKey(name: 'passkey_id')
  final String passkeyId;

  /// Device name for the passkey
  @JsonKey(name: 'device_name')
  final String deviceName;

  /// Type of authenticator
  @JsonKey(name: 'authenticator_type')
  final String authenticatorType;

  /// When the passkey was created
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const PasskeyRegistrationCompleteResponse({
    required this.passkeyId,
    required this.deviceName,
    required this.authenticatorType,
    required this.createdAt,
  });

  factory PasskeyRegistrationCompleteResponse.fromJson(
          Map<String, dynamic> json) =>
      _$PasskeyRegistrationCompleteResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PasskeyRegistrationCompleteResponseToJson(this);

  @override
  List<Object?> get props =>
      [passkeyId, deviceName, authenticatorType, createdAt];
}

/// Response from beginning passkey authentication
///
/// Contains the WebAuthn options to pass to navigator.credentials.get()
@JsonSerializable()
@immutable
class PasskeyAuthenticationBeginResponse extends Equatable {
  /// Challenge ID to include in impersonation request
  @JsonKey(name: 'challenge_id')
  final String challengeId;

  /// WebAuthn PublicKeyCredentialRequestOptions as a Map
  /// Pass directly to navigator.credentials.get()
  final Map<String, dynamic> options;

  const PasskeyAuthenticationBeginResponse({
    required this.challengeId,
    required this.options,
  });

  factory PasskeyAuthenticationBeginResponse.fromJson(
          Map<String, dynamic> json) =>
      _$PasskeyAuthenticationBeginResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PasskeyAuthenticationBeginResponseToJson(this);

  @override
  List<Object?> get props => [challengeId, options];
}

/// Request to start impersonation with passkey authentication
@JsonSerializable()
@immutable
class PasskeyImpersonationRequest extends Equatable {
  /// The user ID to impersonate
  @JsonKey(name: 'target_user_id')
  final String targetUserId;

  /// Challenge ID from passkey authentication begin response
  @JsonKey(name: 'passkey_challenge_id')
  final String passkeyChallengeId;

  /// Credential response from navigator.credentials.get()
  @JsonKey(name: 'passkey_credential')
  final Map<String, dynamic> passkeyCredential;

  const PasskeyImpersonationRequest({
    required this.targetUserId,
    required this.passkeyChallengeId,
    required this.passkeyCredential,
  });

  factory PasskeyImpersonationRequest.fromJson(Map<String, dynamic> json) =>
      _$PasskeyImpersonationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PasskeyImpersonationRequestToJson(this);

  @override
  List<Object?> get props =>
      [targetUserId, passkeyChallengeId, passkeyCredential];
}
