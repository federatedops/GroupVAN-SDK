/**
 * Product listing model
 */

import { Part } from './part.js';

/**
 * Product listing - a collection of parts for a category
 */
export class ProductListing {
  constructor({ partTypeId, partTypeName, parts }) {
    this.partTypeId = partTypeId;
    this.partTypeName = partTypeName;
    this.parts = parts;
  }

  static fromJson(json) {
    return new ProductListing({
      partTypeId: json.part_type_id,
      partTypeName: json.part_type_name,
      parts: (json.parts || []).map(p => Part.fromJson(p)),
    });
  }

  toJson() {
    return {
      part_type_id: this.partTypeId,
      part_type_name: this.partTypeName,
      parts: this.parts,
    };
  }
}
