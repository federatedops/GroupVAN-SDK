/**
 * Part model
 */

import { PartApplication } from './part_application.js';
import { ItemPricing } from './item_pricing.js';
import { Asset } from '../assets/asset.js';

/**
 * Part model representing a product part
 */
export class Part {
  constructor({
    id,
    sku,
    rank,
    tier,
    mfrCode,
    mfrName,
    autoCareBrandId = null,
    partNumber,
    parentPartTypeId = null,
    partTypeId = null,
    partTypeName = null,
    buyersGuide,
    productInfo,
    interchange,
    memberNote = null,
    applications,
    assets = null,
    pricing = null,
  }) {
    this.id = id;
    this.sku = sku;
    this.rank = rank;
    this.tier = tier;
    this.mfrCode = mfrCode;
    this.mfrName = mfrName;
    this.autoCareBrandId = autoCareBrandId;
    this.partNumber = partNumber;
    this.parentPartTypeId = parentPartTypeId;
    this.partTypeId = partTypeId;
    this.partTypeName = partTypeName;
    this.buyersGuide = buyersGuide;
    this.productInfo = productInfo;
    this.interchange = interchange;
    this.memberNote = memberNote;
    this.applications = applications;
    this.assets = assets;
    this.pricing = pricing;
  }

  static fromJson(json) {
    return new Part({
      id: json.id,
      sku: json.sku,
      rank: json.rank,
      tier: json.tier,
      mfrCode: json.mfr_code,
      mfrName: json.mfr_name,
      autoCareBrandId: json.auto_care_brand_id,
      partNumber: json.part_number,
      parentPartTypeId: json.parent_part_type_id,
      partTypeId: json.part_type_id,
      partTypeName: json.part_type_name,
      buyersGuide: json.buyers_guide,
      productInfo: json.product_info,
      interchange: json.interchange,
      memberNote: json.member_note,
      applications: (json.applications || []).map(a => PartApplication.fromJson(a)),
      assets: json.asset ? Asset.fromJson(json.asset) : null,
      pricing: json.pricing ? ItemPricing.fromJson(json.pricing) : null,
    });
  }

  /**
   * Compare parts for sorting
   * @param {Part} other
   * @returns {number}
   */
  compareTo(other) {
    let compare = this.tier - other.tier;
    if (compare !== 0) return compare;

    compare = this.rank - other.rank;
    if (compare !== 0) return compare;

    compare = this.mfrCode.localeCompare(other.mfrCode);
    if (compare !== 0) return compare;

    compare = (this.partTypeName || '').localeCompare(other.partTypeName || '');
    if (compare !== 0) return compare;

    return this.partNumber.localeCompare(other.partNumber);
  }

  /**
   * Get per-car quantity from applications
   * @returns {string}
   */
  perCarQuantity() {
    for (const application of this.applications) {
      for (const display of application.displays) {
        if (display.name === 'Qty') {
          return display.value;
        }
      }
    }
    return '1';
  }

  /**
   * Get cost from first location
   * @returns {number}
   */
  cost() {
    if (!this.pricing) return 0;
    const firstLocation = this.pricing.locations.find(loc => loc.sortOrder === 1);
    return firstLocation?.cost || 0;
  }

  /**
   * Get list price from first location
   * @returns {number}
   */
  list() {
    if (!this.pricing) return 0;
    const firstLocation = this.pricing.locations.find(loc => loc.sortOrder === 1);
    return firstLocation?.list || 0;
  }

  /**
   * Get core charge from first location
   * @returns {number|null}
   */
  core() {
    if (!this.pricing) return null;
    const firstLocation = this.pricing.locations.find(loc => loc.sortOrder === 1);
    return firstLocation?.core || null;
  }

  /**
   * Get quantity at first location as text
   * @returns {string}
   */
  quantityAtLocationText() {
    if (!this.pricing) return '0';
    const firstLocation = this.pricing.locations.find(loc => loc.sortOrder === 1);
    const qty = firstLocation?.quantityAvailable || 0;
    return qty > 100 ? '100+' : qty.toString();
  }
}
