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
      expiresIn: (json['expires_in'] as num).toInt(),
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );

Map<String, dynamic> _$TokenResponseToJson(TokenResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'expires_in': instance.expiresIn,
      'token_type': instance.tokenType,
    };

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