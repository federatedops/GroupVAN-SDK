// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'impersonation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartImpersonationRequest _$StartImpersonationRequestFromJson(
  Map<String, dynamic> json,
) => StartImpersonationRequest(
  targetUserId: json['target_user_id'] as String,
  twoFactorCode: json['two_factor_code'] as String?,
  passkeyChallengeId: json['passkey_challenge_id'] as String?,
  passkeyCredential: json['passkey_credential'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$StartImpersonationRequestToJson(
  StartImpersonationRequest instance,
) => <String, dynamic>{
  'target_user_id': instance.targetUserId,
  'two_factor_code': instance.twoFactorCode,
  'passkey_challenge_id': instance.passkeyChallengeId,
  'passkey_credential': instance.passkeyCredential,
};

EndImpersonationRequest _$EndImpersonationRequestFromJson(
  Map<String, dynamic> json,
) => EndImpersonationRequest(
  impersonationSessionId: json['impersonation_session_id'] as String,
);

Map<String, dynamic> _$EndImpersonationRequestToJson(
  EndImpersonationRequest instance,
) => <String, dynamic>{
  'impersonation_session_id': instance.impersonationSessionId,
};

ImpersonationTargetUser _$ImpersonationTargetUserFromJson(
  Map<String, dynamic> json,
) => ImpersonationTargetUser(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  memberId: json['member_id'] as String?,
);

Map<String, dynamic> _$ImpersonationTargetUserToJson(
  ImpersonationTargetUser instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'member_id': instance.memberId,
};

ImpersonationResponse _$ImpersonationResponseFromJson(
  Map<String, dynamic> json,
) => ImpersonationResponse(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
  tokenType: json['token_type'] as String? ?? 'Bearer',
  impersonationSessionId: json['impersonation_session_id'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
  targetUser: ImpersonationTargetUser.fromJson(
    json['target_user'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ImpersonationResponseToJson(
  ImpersonationResponse instance,
) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'expires_in': instance.expiresIn,
  'token_type': instance.tokenType,
  'impersonation_session_id': instance.impersonationSessionId,
  'expires_at': instance.expiresAt.toIso8601String(),
  'target_user': instance.targetUser,
};

EndImpersonationResponse _$EndImpersonationResponseFromJson(
  Map<String, dynamic> json,
) => EndImpersonationResponse(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
  tokenType: json['token_type'] as String? ?? 'Bearer',
);

Map<String, dynamic> _$EndImpersonationResponseToJson(
  EndImpersonationResponse instance,
) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'expires_in': instance.expiresIn,
  'token_type': instance.tokenType,
};

ImpersonationSession _$ImpersonationSessionFromJson(
  Map<String, dynamic> json,
) => ImpersonationSession(
  id: json['id'] as String,
  adminUserId: json['admin_user_id'] as String,
  adminEmail: json['admin_email'] as String?,
  targetUserId: json['target_user_id'] as String,
  targetEmail: json['target_email'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
  endReason: $enumDecodeNullable(
    _$ImpersonationEndReasonEnumMap,
    json['end_reason'],
  ),
  ipAddress: json['ip_address'] as String?,
  userAgent: json['user_agent'] as String?,
  twoFactorMethod: $enumDecode(
    _$TwoFactorMethodEnumMap,
    json['two_factor_method'],
  ),
  refreshCount: (json['refresh_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ImpersonationSessionToJson(
  ImpersonationSession instance,
) => <String, dynamic>{
  'id': instance.id,
  'admin_user_id': instance.adminUserId,
  'admin_email': instance.adminEmail,
  'target_user_id': instance.targetUserId,
  'target_email': instance.targetEmail,
  'created_at': instance.createdAt.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
  'ended_at': instance.endedAt?.toIso8601String(),
  'end_reason': _$ImpersonationEndReasonEnumMap[instance.endReason],
  'ip_address': instance.ipAddress,
  'user_agent': instance.userAgent,
  'two_factor_method': _$TwoFactorMethodEnumMap[instance.twoFactorMethod]!,
  'refresh_count': instance.refreshCount,
};

const _$ImpersonationEndReasonEnumMap = {
  ImpersonationEndReason.expired: 'expired',
  ImpersonationEndReason.manual: 'manual',
  ImpersonationEndReason.logout: 'logout',
  ImpersonationEndReason.refreshLimit: 'refresh_limit',
};

const _$TwoFactorMethodEnumMap = {
  TwoFactorMethod.totp: 'totp',
  TwoFactorMethod.email: 'email',
  TwoFactorMethod.passkey: 'passkey',
};

ImpersonationSessionsResponse _$ImpersonationSessionsResponseFromJson(
  Map<String, dynamic> json,
) => ImpersonationSessionsResponse(
  sessions: (json['sessions'] as List<dynamic>)
      .map((e) => ImpersonationSession.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$ImpersonationSessionsResponseToJson(
  ImpersonationSessionsResponse instance,
) => <String, dynamic>{'sessions': instance.sessions, 'total': instance.total};
