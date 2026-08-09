/**
 * Product info models for the GroupVAN API
 */

/**
 * Product info attribute
 */
export class ProductInfoAttribute {
  constructor({ name, values }) {
    this.name = name;
    this.values = values;
  }

  static fromJson(json) {
    return new ProductInfoAttribute({
      name: json.name,
      values: json.values || [],
    });
  }
}

/**
 * Product info response
 */
export class ProductInfoResponse {
  constructor({
    sku,
    partNumber,
    mfrCode,
    mfrName,
    description,
    attributes,
    images,
    documents,
  }) {
    this.sku = sku;
    this.partNumber = partNumber;
    this.mfrCode = mfrCode;
    this.mfrName = mfrName;
    this.description = description;
    this.attributes = attributes;
    this.images = images;
    this.documents = documents;
  }

  static fromJson(json) {
    return new ProductInfoResponse({
      sku: json.sku,
      partNumber: json.part_number,
      mfrCode: json.mfr_code,
      mfrName: json.mfr_name,
      description: json.description,
      attributes: (json.attributes || []).map(a => ProductInfoAttribute.fromJson(a)),
      images: json.images || [],
      documents: json.documents || [],
    });
  }
}
