/**
 * Interchange models for the GroupVAN API
 */

/**
 * Interchange brand
 */
export class InterchangeBrand {
  constructor({ code, name }) {
    this.code = code;
    this.name = name;
  }

  static fromJson(json) {
    return new InterchangeBrand({
      code: json.code,
      name: json.name,
    });
  }
}

/**
 * Interchange part type
 */
export class InterchangePartType {
  constructor({ id, name }) {
    this.id = id;
    this.name = name;
  }

  static fromJson(json) {
    return new InterchangePartType({
      id: json.id,
      name: json.name,
    });
  }
}

/**
 * Interchange part
 */
export class InterchangePart {
  constructor({
    mfrCode,
    mfrName,
    partNumber,
    partTypeId,
    partTypeName,
    position,
    interchangeType,
  }) {
    this.mfrCode = mfrCode;
    this.mfrName = mfrName;
    this.partNumber = partNumber;
    this.partTypeId = partTypeId;
    this.partTypeName = partTypeName;
    this.position = position;
    this.interchangeType = interchangeType;
  }

  static fromJson(json) {
    return new InterchangePart({
      mfrCode: json.mfr_code,
      mfrName: json.mfr_name,
      partNumber: json.part_number,
      partTypeId: json.part_type_id,
      partTypeName: json.part_type_name,
      position: json.position,
      interchangeType: json.interchange_type,
    });
  }
}

/**
 * Interchange response
 */
export class Interchange {
  constructor({ brands = null, partTypes = null, parts = null }) {
    this.brands = brands;
    this.partTypes = partTypes;
    this.parts = parts;
  }

  static fromJson(json) {
    return new Interchange({
      brands: json.brands ? json.brands.map(b => InterchangeBrand.fromJson(b)) : null,
      partTypes: json.terms ? json.terms.map(pt => InterchangePartType.fromJson(pt)) : null,
      parts: json.interchanges ? json.interchanges.map(p => InterchangePart.fromJson(p)) : null,
    });
  }
}
