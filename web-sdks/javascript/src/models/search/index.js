/**
 * Search models for the GroupVAN API
 */

import { PartType } from '../catalogs.js';
import { Part } from '../products/part.js';

/**
 * Vehicle and part type search result
 */
export class VehicleAndPartType {
  constructor({ vehicleIndex, vehicleDescription, partTypes }) {
    this.vehicleIndex = vehicleIndex;
    this.vehicleDescription = vehicleDescription;
    this.partTypes = partTypes;
  }

  toJson() {
    return {
      vehicle_index: this.vehicleIndex,
      vehicle_description: this.vehicleDescription,
      part_types: this.partTypes.map(pt => pt.toJson()),
    };
  }

  static fromJson(json) {
    return new VehicleAndPartType({
      vehicleIndex: json.vehicle_index,
      vehicleDescription: json.vehicle_description,
      partTypes: (json.part_types || []).map(pt => PartType.fromJson(pt)),
    });
  }
}

/**
 * Member category search result
 */
export class MemberCategory {
  constructor({ id, name, subcategories }) {
    this.id = id;
    this.name = name;
    this.subcategories = subcategories;
  }

  static fromJson(json) {
    return new MemberCategory({
      id: json.id,
      name: json.name,
      subcategories: (json.subcategories || []).map(sc => MemberCategory.fromJson(sc)),
    });
  }
}

/**
 * Omni search response
 */
export class OmniSearchResponse {
  constructor({ partTypes, parts, vehicles, memberCategories }) {
    this.partTypes = partTypes;
    this.parts = parts;
    this.vehicles = vehicles;
    this.memberCategories = memberCategories;
  }

  static fromJson(json) {
    return new OmniSearchResponse({
      partTypes: (json.part_types || []).map(pt => PartType.fromJson(pt)),
      parts: (json.parts || []).map(p => Part.fromJson(p)),
      vehicles: (json.vehicles || []).map(v => VehicleAndPartType.fromJson(v)),
      memberCategories: (json.member_categories || []).map(mc => MemberCategory.fromJson(mc)),
    });
  }

  toJson() {
    return {
      part_types: this.partTypes.map(pt => pt.toJson()),
      parts: this.parts,
      vehicles: this.vehicles.map(v => v.toJson()),
      member_categories: this.memberCategories,
    };
  }
}
