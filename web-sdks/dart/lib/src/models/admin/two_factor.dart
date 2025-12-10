/// Two-factor authentication models for GroupVAN Admin SDK
///
/// Models for 2FA setup and verification required for impersonation.
library two_factor;

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'two_factor.g.dart';

/// Response from 2FA setup containing TOTP secret
@JsonSerializable()
@immutable
class TwoFactorSetupResponse extends Equatable {
  /// TOTP secret key for authenticator app
  final String secret;

  /// QR code URI for scanning with authenticator app
  @JsonKey(name: 'qr_code_uri')
  final String qrCodeUri;

  /// Backup codes for account recovery
  @JsonKey(name: 'backup_codes')
  final List<String>? backupCodes;

  const TwoFactorSetupResponse({
    required this.secret,
    required this.qrCodeUri,
    this.backupCodes,
  });

  factory TwoFactorSetupResponse.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorSetupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TwoFactorSetupResponseToJson(this);

  @override
  List<Object?> get props => [secret, qrCodeUri, backupCodes];
}

/// Request to verify TOTP code during setup
@JsonSerializable()
@immutable
class TwoFactorVerifyRequest extends Equatable {
  /// TOTP code from authenticator app
  final String code;

  const TwoFactorVerifyRequest({required this.code});

  factory TwoFactorVerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorVerifyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TwoFactorVerifyRequestToJson(this);

  @override
  List<Object?> get props => [code];
}

/// Response from 2FA verification
@JsonSerializable()
@immutable
class TwoFactorVerifyResponse extends Equatable {
  /// Whether the verification was successful
  final bool success;

  /// Message with result details
  final String message;

  const TwoFactorVerifyResponse({
    required this.success,
    required this.message,
  });

  factory TwoFactorVerifyResponse.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorVerifyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TwoFactorVerifyResponseToJson(this);

  /// Alias for backwards compatibility
  bool get verified => success;

  @override
  List<Object?> get props => [success, message];
}

/// Current 2FA status for a user
///
/// Shows which 2FA methods are available/enabled:
/// - Passkey (most secure, recommended)
/// - TOTP (authenticator app)
/// - Email OTP (fallback, always available)
@JsonSerializable()
@immutable
class TwoFactorStatus extends Equatable {
  /// Whether TOTP is enabled
  @JsonKey(name: 'totp_enabled')
  final bool totpEnabled;

  /// When TOTP was set up
  @JsonKey(name: 'totp_setup_at')
  final DateTime? totpSetupAt;

  /// Whether email OTP is available as fallback
  @JsonKey(name: 'email_otp_available')
  final bool emailOtpAvailable;

  /// Whether passkey authentication is enabled
  @JsonKey(name: 'passkey_enabled')
  final bool passkeyEnabled;

  /// Number of registered passkeys
  @JsonKey(name: 'passkey_count')
  final int passkeyCount;

  const TwoFactorStatus({
    required this.totpEnabled,
    this.totpSetupAt,
    this.emailOtpAvailable = true,
    this.passkeyEnabled = false,
    this.passkeyCount = 0,
  });

  factory TwoFactorStatus.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorStatusFromJson(json);

  Map<String, dynamic> toJson() => _$TwoFactorStatusToJson(this);

  /// Whether any 2FA method is enabled (passkey or TOTP)
  bool get hasSecure2FA => passkeyEnabled || totpEnabled;

  /// The recommended 2FA method to use (passkey > TOTP > email)
  String get recommendedMethod {
    if (passkeyEnabled) return 'passkey';
    if (totpEnabled) return 'totp';
    return 'email';
  }

  @override
  List<Object?> get props => [
        totpEnabled,
        totpSetupAt,
        emailOtpAvailable,
        passkeyEnabled,
        passkeyCount,
      ];
}

/// Response from requesting email OTP
@JsonSerializable()
@immutable
class EmailOtpResponse extends Equatable {
  /// Whether the request was successful
  final bool success;

  /// Message showing where OTP was sent (e.g., "OTP code sent to rus***@email.com")
  final String message;

  const EmailOtpResponse({
    required this.success,
    required this.message,
  });

  factory EmailOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$EmailOtpResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EmailOtpResponseToJson(this);

  /// Alias for backwards compatibility
  bool get sent => success;

  @override
  List<Object?> get props => [success, message];
}
