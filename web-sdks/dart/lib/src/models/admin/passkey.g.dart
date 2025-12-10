// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passkey.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PasskeyInfo _$PasskeyInfoFromJson(Map<String, dynamic> json) => PasskeyInfo(
  id: json['id'] as String,
  deviceName: json['device_name'] as String,
  authenticatorType: json['authenticator_type'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  lastUsedAt: json['last_used_at'] == null
      ? null
      : DateTime.parse(json['last_used_at'] as String),
);

Map<String, dynamic> _$PasskeyInfoToJson(PasskeyInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device_name': instance.deviceName,
      'authenticator_type': instance.authenticatorType,
      'created_at': instance.createdAt.toIso8601String(),
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
    };

PasskeyListResponse _$PasskeyListResponseFromJson(Map<String, dynamic> json) =>
    PasskeyListResponse(
      passkeys: (json['passkeys'] as List<dynamic>)
          .map((e) => PasskeyInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$PasskeyListResponseToJson(
  PasskeyListResponse instance,
) => <String, dynamic>{'passkeys': instance.passkeys, 'total': instance.total};

PasskeyRegistrationBeginResponse _$PasskeyRegistrationBeginResponseFromJson(
  Map<String, dynamic> json,
) => PasskeyRegistrationBeginResponse(
  challengeId: json['challenge_id'] as String,
  options: json['options'] as Map<String, dynamic>,
);

Map<String, dynamic> _$PasskeyRegistrationBeginResponseToJson(
  PasskeyRegistrationBeginResponse instance,
) => <String, dynamic>{
  'challenge_id': instance.challengeId,
  'options': instance.options,
};

PasskeyRegistrationCompleteRequest _$PasskeyRegistrationCompleteRequestFromJson(
  Map<String, dynamic> json,
) => PasskeyRegistrationCompleteRequest(
  challengeId: json['challenge_id'] as String,
  credential: json['credential'] as Map<String, dynamic>,
  deviceName: json['device_name'] as String?,
);

Map<String, dynamic> _$PasskeyRegistrationCompleteRequestToJson(
  PasskeyRegistrationCompleteRequest instance,
) => <String, dynamic>{
  'challenge_id': instance.challengeId,
  'credential': instance.credential,
  'device_name': instance.deviceName,
};

PasskeyRegistrationCompleteResponse
_$PasskeyRegistrationCompleteResponseFromJson(Map<String, dynamic> json) =>
    PasskeyRegistrationCompleteResponse(
      passkeyId: json['passkey_id'] as String,
      deviceName: json['device_name'] as String,
      authenticatorType: json['authenticator_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PasskeyRegistrationCompleteResponseToJson(
  PasskeyRegistrationCompleteResponse instance,
) => <String, dynamic>{
  'passkey_id': instance.passkeyId,
  'device_name': instance.deviceName,
  'authenticator_type': instance.authenticatorType,
  'created_at': instance.createdAt.toIso8601String(),
};

PasskeyAuthenticationBeginResponse _$PasskeyAuthenticationBeginResponseFromJson(
  Map<String, dynamic> json,
) => PasskeyAuthenticationBeginResponse(
  challengeId: json['challenge_id'] as String,
  options: json['options'] as Map<String, dynamic>,
);

Map<String, dynamic> _$PasskeyAuthenticationBeginResponseToJson(
  PasskeyAuthenticationBeginResponse instance,
) => <String, dynamic>{
  'challenge_id': instance.challengeId,
  'options': instance.options,
};

PasskeyImpersonationRequest _$PasskeyImpersonationRequestFromJson(
  Map<String, dynamic> json,
) => PasskeyImpersonationRequest(
  targetUserId: json['target_user_id'] as String,
  passkeyChallengeId: json['passkey_challenge_id'] as String,
  passkeyCredential: json['passkey_credential'] as Map<String, dynamic>,
);

Map<String, dynamic> _$PasskeyImpersonationRequestToJson(
  PasskeyImpersonationRequest instance,
) => <String, dynamic>{
  'target_user_id': instance.targetUserId,
  'passkey_challenge_id': instance.passkeyChallengeId,
  'passkey_credential': instance.passkeyCredential,
};
