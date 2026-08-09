/**
 * Item pricing models
 */

/**
 * Item pricing location
 */
export class ItemPricingLocation {
  constructor({
    canOrder,
    cost,
    description,
    id,
    list,
    packCode,
    packQuantity,
    quantityAvailable,
    sortOrder,
    type,
    core = null,
  }) {
    this.canOrder = canOrder;
    this.cost = cost;
    this.description = description;
    this.id = id;
    this.list = list;
    this.packCode = packCode;
    this.packQuantity = packQuantity;
    this.quantityAvailable = quantityAvailable;
    this.sortOrder = sortOrder;
    this.type = type;
    this.core = core;
  }

  static fromJson(json) {
    return new ItemPricingLocation({
      canOrder: json.can_order,
      cost: json.cost,
      description: json.description,
      id: json.id,
      list: json.list,
      core: json.core,
      packCode: json.pack_code,
      packQuantity: json.pack_quantity,
      quantityAvailable: json.quantity_available,
      sortOrder: json.sort_order,
      type: json.type,
    });
  }
}

/**
 * Item pricing
 */
export class ItemPricing {
  constructor({ comment, id, locations, mfrCode, mfrDescription, partDescription, partNumber, statusCode }) {
    this.comment = comment;
    this.id = id;
    this.locations = locations;
    this.mfrCode = mfrCode;
    this.mfrDescription = mfrDescription;
    this.partDescription = partDescription;
    this.partNumber = partNumber;
    this.statusCode = statusCode;
  }

  static fromJson(json) {
    return new ItemPricing({
      comment: json.comment,
      id: json.id,
      locations: (json.locations || []).map(loc => ItemPricingLocation.fromJson(loc)),
      mfrCode: json.mfr_code,
      mfrDescription: json.mfr_description,
      partDescription: json.part_description,
      partNumber: json.part_number,
      statusCode: json.status_code,
    });
  }
}

/**
 * Item pricing request
 */
export class ItemPricingRequest {
  constructor({ id, mfrCode, partNumber }) {
    this.id = id;
    this.mfrCode = mfrCode;
    this.partNumber = partNumber;
  }

  toJson() {
    return {
      id: this.id,
      mfr_code: this.mfrCode,
      part_number: this.partNumber,
    };
  }
}
