// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  username: json['username'] as String,
  password: json['password'] as String,
  developerId: json['developer_id'] as String,
  integration: json['integration'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'developer_id': instance.developerId,
      'integration': instance.integration,
    };

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
);

Map<String, dynamic> _$TokenClaimsToJson(TokenClaims instance) =>
    <String, dynamic>{
      'sub': instance.userId,
      'type': instance.type,
      'iat': instance.issuedAt,
      'exp': instance.expiration,
      'jti': instance.jti,
      'member': instance.member,
    };
