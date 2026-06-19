/**
 * Catalog models for the V3 Catalogs API
 */

/**
 * Display tier enum
 * @enum {string}
 */
export const DisplayTier = {
  PRIMARY: 'primary',
  SECONDARY: 'secondary',
};

/**
 * Catalog type enum
 * @enum {string}
 */
export const CatalogType = {
  SUPPLY: 'supply',
  VEHICLE: 'vehicle',
};

/**
 * Get CatalogType from string
 * @param {string} value
 * @returns {string}
 */
export function catalogTypeFromString(value) {
  switch (value.toLowerCase()) {
    case 'supply':
      return CatalogType.SUPPLY;
    case 'vehicle':
      return CatalogType.VEHICLE;
    default:
      return CatalogType.SUPPLY;
  }
}

/**
 * Get display name for CatalogType
 * @param {string} type
 * @returns {string}
 */
export function catalogTypeDisplayName(type) {
  switch (type) {
    case CatalogType.SUPPLY:
      return 'Supply Catalog';
    case CatalogType.VEHICLE:
      return 'Vehicle Catalog';
    default:
      return 'Unknown Catalog';
  }
}

/**
 * Catalog model
 */
export class Catalog {
  constructor({ id, name, type }) {
    this.id = id;
    this.name = name;
    this.type = type;
  }

  toJson() {
    return {
      id: this.id,
      name: this.name,
      type: this.type,
    };
  }

  static fromJson(json) {
    return new Catalog({
      id: json.id,
      name: json.name,
      type: catalogTypeFromString(json.type),
    });
  }

  copyWith({ id, name, type } = {}) {
    return new Catalog({
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    });
  }
}

/**
 * Part type information used in categories
 */
export class PartType {
  constructor({ displayTier, id, name, popularityGroup, slangList }) {
    this.displayTier = displayTier;
    this.id = id;
    this.name = name;
    this.popularityGroup = popularityGroup;
    this.slangList = slangList;
  }

  toJson() {
    return {
      display_tier: this.displayTier,
      id: this.id,
      name: this.name,
      popularity_group: this.popularityGroup,
      slang_list: this.slangList,
    };
  }

  static fromJson(json) {
    return new PartType({
      displayTier: json.display_tier || null,
      id: json.id,
      name: json.name,
      popularityGroup: json.popularity_group,
      slangList: json.slang_list || [],
    });
  }
}

/**
 * Vehicle category information
 */
export class VehicleCategory {
  constructor({ displayTier, id, name, partTypes }) {
    this.displayTier = displayTier;
    this.id = id;
    this.name = name;
    this.partTypes = partTypes;
  }

  toJson() {
    return {
      display_tier: this.displayTier,
      id: this.id,
      name: this.name,
      part_types: this.partTypes.map(pt => pt.toJson()),
    };
  }

  static fromJson(json) {
    return new VehicleCategory({
      displayTier: json.display_tier,
      id: json.id,
      name: json.name,
      partTypes: (json.part_types || []).map(pt => PartType.fromJson(pt)),
    });
  }
}

/**
 * Top category
 */
export class TopCategory {
  constructor({ id, name }) {
    this.id = id;
    this.name = name;
  }

  toJson() {
    return { id: this.id, name: this.name };
  }

  static fromJson(json) {
    return new TopCategory({ id: json.id, name: json.name });
  }
}

/**
 * Supply subcategory information
 */
export class SupplySubcategory {
  constructor({ id, name }) {
    this.id = id;
    this.name = name;
  }

  toJson() {
    return { id: this.id, name: this.name };
  }

  static fromJson(json) {
    return new SupplySubcategory({ id: json.id, name: json.name });
  }
}

/**
 * Supply category information
 */
export class SupplyCategory {
  constructor({ id, name, subcategories }) {
    this.id = id;
    this.name = name;
    this.subcategories = subcategories;
  }

  toJson() {
    return {
      id: this.id,
      name: this.name,
      subcategories: this.subcategories.map(sc => sc.toJson()),
    };
  }

  static fromJson(json) {
    return new SupplyCategory({
      id: json.id,
      name: json.name,
      subcategories: (json.subcategories || []).map(sc => SupplySubcategory.fromJson(sc)),
    });
  }
}

/**
 * Application asset information
 */
export class ApplicationAsset {
  constructor({ applicationId, type, language, uri }) {
    this.applicationId = applicationId;
    this.type = type;
    this.language = language;
    this.uri = uri;
  }

  toJson() {
    return {
      application_id: this.applicationId,
      type: this.type,
      language: this.language,
      uri: this.uri,
    };
  }

  static fromJson(json) {
    return new ApplicationAsset({
      applicationId: json.application_id,
      type: json.type,
      language: json.language,
      uri: json.uri,
    });
  }
}

/**
 * Application assets request
 */
export class ApplicationAssetsRequest {
  constructor({ applicationIds, languageCode = null }) {
    this.applicationIds = applicationIds;
    this.languageCode = languageCode;
  }

  toJson() {
    const json = {
      application_ids: this.applicationIds.join(','),
    };
    if (this.languageCode !== null) {
      json.language_code = this.languageCode;
    }
    return json;
  }
}

/**
 * Part type for product requests
 */
export class PartTypeRequest {
  constructor({ id, name }) {
    this.id = id;
    this.name = name;
  }

  toJson() {
    return { id: this.id, name: this.name };
  }
}

/**
 * Product listing request
 */
export class ProductListingRequest {
  constructor({ vehicleIndex, itemIds, showAll }) {
    this.vehicleIndex = vehicleIndex;
    this.itemIds = itemIds;
    this.showAll = showAll;
  }

  toJson() {
    return {
      vehicle_index: this.vehicleIndex,
      item_ids: this.itemIds,
      show_all: this.showAll,
    };
  }
}
