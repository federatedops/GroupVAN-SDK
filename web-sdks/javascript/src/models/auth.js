/**
 * Authentication models for the GroupVAN API
 */

/**
 * Location information
 */
export class Location {
  constructor({ id, name, address, city, state, zip, phone }) {
    this.id = id;
    this.name = name;
    this.address = address;
    this.city = city;
    this.state = state;
    this.zip = zip;
    this.phone = phone;
  }

  toJson() {
    return {
      id: this.id,
      name: this.name,
      address: this.address,
      city: this.city,
      state: this.state,
      zip: this.zip,
      phone: this.phone,
    };
  }

  static fromJson(json) {
    return new Location({
      id: json.id,
      name: json.name,
      address: json.address,
      city: json.city,
      state: json.state,
      zip: json.zip,
      phone: json.phone,
    });
  }
}

/**
 * User information
 */
export class User {
  constructor({
    id,
    email,
    name,
    createdAt,
    roles,
    hasIdentifixAccess,
    picture = null,
    memberId = null,
    location = null,
  }) {
    this.id = id;
    this.email = email;
    this.name = name;
    this.createdAt = createdAt;
    this.roles = roles;
    this.hasIdentifixAccess = hasIdentifixAccess;
    this.picture = picture;
    this.memberId = memberId;
    this.location = location;
  }

  toJson() {
    return {
      id: this.id,
      email: this.email,
      name: this.name,
      created_at: this.createdAt.toISOString(),
      roles: this.roles,
      has_identifix_access: this.hasIdentifixAccess,
      picture: this.picture,
      member_id: this.memberId,
      location: this.location?.toJson(),
    };
  }

  static fromJson(json) {
    return new User({
      id: json.id,
      email: json.email,
      name: json.name,
      createdAt: new Date(json.created_at),
      roles: json.roles || [],
      hasIdentifixAccess: json.has_identifix_access || false,
      picture: json.picture,
      memberId: json.member_id,
      location: json.location ? Location.fromJson(json.location) : null,
    });
  }
}

/**
 * Vehicle lookup types for catalog token
 * @enum {string}
 */
export const VehicleLookupType = {
  NONE: 'NONE',
  VIN: 'VIN',
  SEARCH: 'SEARCH',
  CONFIG: 'CONFIG',
};

/**
 * Catalog token request
 */
export class CatalogTokenRequest {
  constructor({
    accountId,
    vehicleLookup,
    cartId = '',
    accountName = '',
    locationId = '',
    terminalId = '',
    vin = '',
    yearId = '',
    makeId = '',
    modelId = '',
    groupId = '',
    engineId = '',
    configId = '',
    configType = '',
    baseVehicleId = '',
    vehicleToEngineConfigId = '',
  }) {
    this.accountId = accountId;
    this.vehicleLookup = vehicleLookup;
    this.cartId = cartId;
    this.accountName = accountName;
    this.locationId = locationId;
    this.terminalId = terminalId;
    this.vin = vin;
    this.yearId = yearId;
    this.makeId = makeId;
    this.modelId = modelId;
    this.groupId = groupId;
    this.engineId = engineId;
    this.configId = configId;
    this.configType = configType;
    this.baseVehicleId = baseVehicleId;
    this.vehicleToEngineConfigId = vehicleToEngineConfigId;
  }

  toJson() {
    return {
      account_id: this.accountId,
      vehicle_lookup: this.vehicleLookup,
      cart_id: this.cartId,
      account_name: this.accountName,
      location_id: this.locationId,
      terminal_id: this.terminalId,
      vin: this.vin,
      year_id: this.yearId,
      make_id: this.makeId,
      model_id: this.modelId,
      group_id: this.groupId,
      engine_id: this.engineId,
      config_id: this.configId,
      config_type: this.configType,
      base_vehicle_id: this.baseVehicleId,
      vehicle_to_engine_config_id: this.vehicleToEngineConfigId,
    };
  }
}
