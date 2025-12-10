// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'two_factor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TwoFactorSetupResponse _$TwoFactorSetupResponseFromJson(
  Map<String, dynamic> json,
) => TwoFactorSetupResponse(
  secret: json['secret'] as String,
  qrCodeUri: json['qr_code_uri'] as String,
  backupCodes: (json['backup_codes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$TwoFactorSetupResponseToJson(
  TwoFactorSetupResponse instance,
) => <String, dynamic>{
  'secret': instance.secret,
  'qr_code_uri': instance.qrCodeUri,
  'backup_codes': instance.backupCodes,
};

TwoFactorVerifyRequest _$TwoFactorVerifyRequestFromJson(
  Map<String, dynamic> json,
) => TwoFactorVerifyRequest(code: json['code'] as String);

Map<String, dynamic> _$TwoFactorVerifyRequestToJson(
  TwoFactorVerifyRequest instance,
) => <String, dynamic>{'code': instance.code};

TwoFactorVerifyResponse _$TwoFactorVerifyResponseFromJson(
  Map<String, dynamic> json,
) => TwoFactorVerifyResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
);

Map<String, dynamic> _$TwoFactorVerifyResponseToJson(
  TwoFactorVerifyResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
};

TwoFactorStatus _$TwoFactorStatusFromJson(Map<String, dynamic> json) =>
    TwoFactorStatus(
      totpEnabled: json['totp_enabled'] as bool,
      totpSetupAt: json['totp_setup_at'] == null
          ? null
          : DateTime.parse(json['totp_setup_at'] as String),
      emailOtpAvailable: json['email_otp_available'] as bool? ?? true,
      passkeyEnabled: json['passkey_enabled'] as bool? ?? false,
      passkeyCount: (json['passkey_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TwoFactorStatusToJson(TwoFactorStatus instance) =>
    <String, dynamic>{
      'totp_enabled': instance.totpEnabled,
      'totp_setup_at': instance.totpSetupAt?.toIso8601String(),
      'email_otp_available': instance.emailOtpAvailable,
      'passkey_enabled': instance.passkeyEnabled,
      'passkey_count': instance.passkeyCount,
    };

EmailOtpResponse _$EmailOtpResponseFromJson(Map<String, dynamic> json) =>
    EmailOtpResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$EmailOtpResponseToJson(EmailOtpResponse instance) =>
    <String, dynamic>{'success': instance.success, 'message': instance.message};
