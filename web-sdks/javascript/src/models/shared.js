/**
 * Shared models used across different API endpoints
 */

/**
 * Paginated request parameters
 */
export class PaginatedRequest {
  constructor({ offset = 0, limit = 20 } = {}) {
    this.offset = offset;
    this.limit = limit;
  }

  toJson() {
    const json = {};
    if (this.offset !== null && this.offset !== undefined) {
      json.offset = this.offset;
    }
    if (this.limit !== null && this.limit !== undefined) {
      json.limit = this.limit;
    }
    return json;
  }
}

/**
 * Vehicle model representing basic vehicle information
 */
export class Vehicle {
  constructor({
    index,
    year,
    make,
    model,
    engineId = null,
    engine = null,
    vin = null,
    previousVehicleId = null,
    description = null,
    fleetVehicleId = null,
  }) {
    this.index = index;
    this.year = year;
    this.make = make;
    this.model = model;
    this.engineId = engineId;
    this.engine = engine;
    this.vin = vin;
    this.previousVehicleId = previousVehicleId;
    this.description = description;
    this.fleetVehicleId = fleetVehicleId;
  }

  toJson() {
    const json = {
      index: this.index,
      year: this.year,
      make: this.make,
      model: this.model,
    };
    if (this.engineId !== null) json.engine_id = this.engineId;
    if (this.engine !== null) json.engine = this.engine;
    if (this.vin !== null) json.vin = this.vin;
    if (this.previousVehicleId !== null) json.previous_vehicle_id = this.previousVehicleId;
    if (this.description !== null) json.description = this.description;
    if (this.fleetVehicleId !== null) json.fleet_vehicle_id = this.fleetVehicleId;
    return json;
  }

  static fromJson(json) {
    return new Vehicle({
      index: json.index,
      year: json.year,
      make: json.make,
      model: json.model,
      engineId: json.engine_id,
      engine: json.engine,
      vin: json.vin,
      previousVehicleId: json.previous_vehicle_id,
      description: json.description,
      fleetVehicleId: json.fleet_vehicle_id,
    });
  }
}
