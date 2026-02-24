/// Authentication models for the GroupVAN API
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

/// V3 Login request with client ID
class V3LoginRequest extends LoginRequest {
  final String clientId;

  const V3LoginRequest({
    required super.username,
    required super.password,
    required this.clientId,
  });

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'client_id': clientId};
}

/// Token response from login/refresh endpoints
///
/// Note: refresh_token is no longer returned in API responses.
/// It is now set as an HttpOnly cookie by the server.
class TokenResponse {
  final String accessToken;
  final int expiresIn;
  final String tokenType;

  const TokenResponse({
    required this.accessToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
    accessToken: json['access_token'],
    expiresIn: json['expires_in'],
    tokenType: json['token_type'] ?? 'Bearer',
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'expires_in': expiresIn,
    'token_type': tokenType,
  };
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

class Location {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String phone;
  final bool inNetwork;

  const Location({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.phone,
    required this.inNetwork,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    city: json['city'],
    state: json['state'],
    zip: json['zip'],
    phone: json['phone'],
    inNetwork: json['in_network'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'state': state,
    'zip': zip,
    'phone': phone,
    'in_network': inNetwork,
  };
}

class User {
  final int id;
  final String email;
  final String name;
  final DateTime createdAt;
  final String? picture;
  final String? memberId;
  final List<Location> locations;
  final bool hasIdentifixAccess;
  final bool canExportBuyersGuide;
  final List<String> roles;
  final bool showCartButtonWhenNoPrice;
  final List<String> deliveryExpectations;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.roles,
    required this.hasIdentifixAccess,
    this.canExportBuyersGuide = false,
    this.showCartButtonWhenNoPrice = false,
    this.picture,
    this.memberId,
    this.locations = const [],
    this.deliveryExpectations = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    name: json['name'],
    createdAt: DateTime.parse(json['created_at']),
    roles: List<String>.from(json['roles'] as List),
    hasIdentifixAccess: json['has_identifix_access'],
    canExportBuyersGuide: json['can_export_buyers_guide'] ?? false,
    showCartButtonWhenNoPrice: json['show_cart_button_when_no_price'] ?? false,
    picture: json['picture'],
    memberId: json['member_id'],
    locations: (json['locations'] as List?)
        ?.map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    deliveryExpectations: List<String>.from(json['delivery_expectations'] as List? ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'picture': picture,
    'member_id': memberId,
    'locations': locations.map((e) => e.toJson()).toList(),
    'roles': roles,
    'has_identifix_access': hasIdentifixAccess,
    'can_export_buyers_guide': canExportBuyersGuide,
    'show_cart_button_when_no_price': showCartButtonWhenNoPrice,
    'delivery_expectations': deliveryExpectations,
  };
}
