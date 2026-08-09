/**
 * Vehicle models for the GroupVAN API
 */

import { Vehicle } from './shared.js';

/**
 * Vehicle group information
 */
export class VehicleGroup {
  constructor({ id, name, description }) {
    this.id = id;
    this.name = name;
    this.description = description;
  }

  toJson() {
    return {
      id: this.id,
      name: this.name,
      description: this.description,
    };
  }

  static fromJson(json) {
    return new VehicleGroup({
      id: json.id,
      name: json.name,
      description: json.description,
    });
  }
}

/**
 * Vehicle search request
 */
export class VehicleSearchRequest {
  constructor({ query, groupId = null, pageNumber = 1 }) {
    this.query = query;
    this.groupId = groupId;
    this.pageNumber = pageNumber;
  }

  toJson() {
    const json = {
      query: this.query,
      page: this.pageNumber,
    };
    if (this.groupId !== null) {
      json.group_id = this.groupId;
    }
    return json;
  }
}

/**
 * Vehicle search response
 */
export class VehicleSearchResponse {
  constructor({ vehicles, totalCount, page }) {
    this.vehicles = vehicles;
    this.totalCount = totalCount;
    this.page = page;
  }

  static fromJson(json) {
    return new VehicleSearchResponse({
      vehicles: (json.vehicles || []).map(v => Vehicle.fromJson(v)),
      totalCount: json.total_count,
      page: json.page,
    });
  }
}

/**
 * VIN search request
 */
export class VinSearchRequest {
  constructor({ vin }) {
    this.vin = vin;
  }

  toJson() {
    return { vin: this.vin };
  }
}

/**
 * Plate search request
 */
export class PlateSearchRequest {
  constructor({ plate, state }) {
    this.plate = plate;
    this.state = state;
  }

  toJson() {
    return { plate: this.plate, state: this.state };
  }
}

/**
 * Vehicle filter request
 */
export class VehicleFilterRequest {
  constructor({ groupId, yearId = null, makeId = null, modelId = null }) {
    this.groupId = groupId;
    this.yearId = yearId;
    this.makeId = makeId;
    this.modelId = modelId;
  }

  toJson() {
    const json = { group_id: this.groupId };
    if (this.yearId !== null) json.year_id = this.yearId;
    if (this.makeId !== null) json.make_id = this.makeId;
    if (this.modelId !== null) json.model_id = this.modelId;
    return json;
  }
}

/**
 * Vehicle filter option
 */
export class VehicleFilterOption {
  constructor({ id, name, regions }) {
    this.id = id;
    this.name = name;
    this.regions = regions;
  }

  static fromJson(json, type) {
    return new VehicleFilterOption({
      id: json[`${type}_id`],
      name: json[`${type}_name`],
      regions: json[`${type}_regions`] || [],
    });
  }
}

/**
 * Vehicle filter response
 */
export class VehicleFilterResponse {
  constructor({ models, makes, years }) {
    this.models = models;
    this.makes = makes;
    this.years = years;
  }

  static fromJson(json) {
    return new VehicleFilterResponse({
      models: (json.models || []).map(m => VehicleFilterOption.fromJson(m, 'model')),
      makes: (json.makes || []).map(m => VehicleFilterOption.fromJson(m, 'make')),
      years: (json.years || []).map(y => VehicleFilterOption.fromJson(y, 'year')),
    });
  }
}

/**
 * Fleet information
 */
export class Fleet {
  constructor({ id, name, timestamp }) {
    this.id = id;
    this.name = name;
    this.timestamp = timestamp;
  }

  toJson() {
    return {
      id: this.id,
      name: this.name,
      timestamp: this.timestamp,
    };
  }

  static fromJson(json) {
    return new Fleet({
      id: json.id,
      name: json.name,
      timestamp: json.timestamp,
    });
  }
}

/**
 * Engine search request
 */
export class EngineSearchRequest {
  constructor({ groupId, yearId, makeId, modelId }) {
    this.groupId = groupId;
    this.yearId = yearId;
    this.makeId = makeId;
    this.modelId = modelId;
  }

  toJson() {
    return {
      group_id: this.groupId,
      year_id: this.yearId,
      make_id: this.makeId,
      model_id: this.modelId,
    };
  }
}

/**
 * Engine search response
 */
export class EngineSearchResponse {
  constructor({ vehicles }) {
    this.vehicles = vehicles;
  }

  static fromJson(json) {
    return new EngineSearchResponse({
      vehicles: (json.vehicles || []).map(v => Vehicle.fromJson(v)),
    });
  }
}

// Re-export Vehicle for convenience
export { Vehicle };
