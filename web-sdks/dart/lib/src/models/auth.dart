/// Authentication models for the GroupVAN API
class LoginRequest {
  final String username;
  final String password;
  final String integration;

  const LoginRequest({
    required this.username,
    required this.password,
    required this.integration,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'integration': integration,
  };
}

/// V3 Login request with client ID
class V3LoginRequest extends LoginRequest {
  final String clientId;

  const V3LoginRequest({
    required super.username,
    required super.password,
    required super.integration,
    required this.clientId,
  });

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'client_id': clientId};
}

/// Token response from login/refresh endpoints
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
    accessToken: json['access_token'],
    refreshToken: json['refresh_token'],
    expiresIn: json['expires_in'],
    tokenType: json['token_type'] ?? 'Bearer',
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': expiresIn,
    'token_type': tokenType,
  };
}

/// Refresh token request
class RefreshTokenRequest {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}

/// Logout request
class LogoutRequest {
  final String refreshToken;

  const LogoutRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}

/// Vehicle lookup types for catalog token
enum VehicleLookupType {
  none('NONE'),
  vin('VIN'),
  search('SEARCH'),
  config('CONFIG');

  const VehicleLookupType(this.value);
  final String value;
}

/// Catalog token request
class CatalogTokenRequest {
  final String accountId;
  final VehicleLookupType vehicleLookup;
  final String cartId;
  final String accountName;
  final String locationId;
  final String terminalId;
  final String vin;
  final String yearId;
  final String makeId;
  final String modelId;
  final String groupId;
  final String engineId;
  final String configId;
  final String configType;
  final String baseVehicleId;
  final String vehicleToEngineConfigId;

  const CatalogTokenRequest({
    required this.accountId,
    required this.vehicleLookup,
    this.cartId = '',
    this.accountName = '',
    this.locationId = '',
    this.terminalId = '',
    this.vin = '',
    this.yearId = '',
    this.makeId = '',
    this.modelId = '',
    this.groupId = '',
    this.engineId = '',
    this.configId = '',
    this.configType = '',
    this.baseVehicleId = '',
    this.vehicleToEngineConfigId = '',
  });

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'vehicle_lookup': vehicleLookup.value,
    'cart_id': cartId,
    'account_name': accountName,
    'location_id': locationId,
    'terminal_id': terminalId,
    'vin': vin,
    'year_id': yearId,
    'make_id': makeId,
    'model_id': modelId,
    'group_id': groupId,
    'engine_id': engineId,
    'config_id': configId,
    'config_type': configType,
    'base_vehicle_id': baseVehicleId,
    'vehicle_to_engine_config_id': vehicleToEngineConfigId,
  };
}

/// Catalog token response
class CatalogTokenResponse {
  final String accessToken;

  const CatalogTokenResponse({required this.accessToken});

  factory CatalogTokenResponse.fromJson(Map<String, dynamic> json) =>
      CatalogTokenResponse(accessToken: json['access_token']);

  Map<String, dynamic> toJson() => {'access_token': accessToken};
}
