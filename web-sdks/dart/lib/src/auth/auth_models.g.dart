// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) =>
    TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );

Map<String, dynamic> _$TokenResponseToJson(TokenResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'expires_in': instance.expiresIn,
      'token_type': instance.tokenType,
    };

RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    RefreshTokenRequest(refreshToken: json['refresh_token'] as String);

Map<String, dynamic> _$RefreshTokenRequestToJson(
  RefreshTokenRequest instance,
) => <String, dynamic>{'refresh_token': instance.refreshToken};

LogoutRequest _$LogoutRequestFromJson(Map<String, dynamic> json) =>
    LogoutRequest(refreshToken: json['refresh_token'] as String);

Map<String, dynamic> _$LogoutRequestToJson(LogoutRequest instance) =>
    <String, dynamic>{'refresh_token': instance.refreshToken};

TokenClaims _$TokenClaimsFromJson(Map<String, dynamic> json) => TokenClaims(
  userId: json['sub'] as String,
  issuedAt: (json['iat'] as num).toInt(),
  expiration: (json['exp'] as num).toInt(),
  jti: json['jti'] as String,
  type: json['type'] as String? ?? 'access',
  member: json['member'] as String?,
  isImpersonating: json['imp'] as bool? ?? false,
  impersonatedBy: json['imp_by'] as String?,
  impersonationSessionId: json['imp_session'] as String?,
);

Map<String, dynamic> _$TokenClaimsToJson(TokenClaims instance) =>
    <String, dynamic>{
      'sub': instance.userId,
      'type': instance.type,
      'iat': instance.issuedAt,
      'exp': instance.expiration,
      'jti': instance.jti,
      'member': instance.member,
      'imp': instance.isImpersonating,
      'imp_by': instance.impersonatedBy,
      'imp_session': instance.impersonationSessionId,
    };
