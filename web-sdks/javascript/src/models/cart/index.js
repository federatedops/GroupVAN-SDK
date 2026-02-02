/**
 * Cart models for the GroupVAN API
 */

/**
 * Cart item type enum
 * @enum {string}
 */
export const CartItemType = {
  MEMBER: 'member',
  CATALOG: 'catalog',
  LABOR: 'labor',
  MISCELLANEOUS: 'miscellaneous',
};

/**
 * Cart item model
 */
export class CartItem {
  constructor({
    mfrCode,
    partNumber,
    listPrice,
    cost,
    core,
    quantity,
    memberNumber,
    locationId,
    type,
    sku = null,
    id = null,
    partTypeName = null,
    brand = null,
    itemGroupKey = null,
    locationDescription = null,
  }) {
    this.mfrCode = mfrCode;
    this.partNumber = partNumber;
    this.listPrice = listPrice;
    this.cost = cost;
    this.core = core;
    this.quantity = quantity;
    this.memberNumber = memberNumber;
    this.locationId = locationId;
    this.type = type;
    this.sku = sku;
    this.id = id;
    this.partTypeName = partTypeName;
    this.brand = brand;
    this.itemGroupKey = itemGroupKey;
    this.locationDescription = locationDescription;
  }

  toJson() {
    return {
      mfr_code: this.mfrCode,
      part_number: this.partNumber,
      list_price: this.listPrice,
      cost: this.cost,
      core: this.core,
      quantity: this.quantity,
      member_number: this.memberNumber,
      location_id: this.locationId,
      item_type: this.type,
      sku: this.sku,
      id: this.id,
      part_type_name: this.partTypeName,
      brand: this.brand,
      item_group_key: this.itemGroupKey,
      location_description: this.locationDescription,
    };
  }

  static fromJson(json) {
    return new CartItem({
      mfrCode: json.mfr_code,
      partNumber: json.part_number,
      listPrice: json.list_price,
      cost: json.cost,
      core: json.core,
      quantity: json.quantity,
      memberNumber: json.member_number,
      locationId: json.location_id,
      type: json.item_type,
      sku: json.sku,
      id: json.id,
      partTypeName: json.part_type_name,
      brand: json.brand,
      itemGroupKey: json.item_group_key,
      locationDescription: json.location_description,
    });
  }
}

/**
 * Add to cart request
 */
export class AddToCartRequest {
  constructor({ cartId = null, items, purchaseOrderNumber = null, comment = null }) {
    this.cartId = cartId;
    this.items = items;
    this.purchaseOrderNumber = purchaseOrderNumber;
    this.comment = comment;
  }

  toJson() {
    return {
      cart_id: this.cartId,
      items: this.items.map(item => item.toJson()),
      purchase_order_number: this.purchaseOrderNumber,
      comment: this.comment,
    };
  }

  static fromJson(json) {
    return new AddToCartRequest({
      cartId: json.cart_id,
      items: (json.items || []).map(item => CartItem.fromJson(item)),
      purchaseOrderNumber: json.purchase_order_number,
      comment: json.comment,
    });
  }
}

/**
 * Removal item for cart
 */
export class RemovalItem {
  constructor({ id, quantity }) {
    this.id = id;
    this.quantity = quantity;
  }

  toJson() {
    return { id: this.id, quantity: this.quantity };
  }

  static fromJson(json) {
    return new RemovalItem({ id: json.id, quantity: json.quantity });
  }
}

/**
 * Remove from cart request
 */
export class RemoveFromCartRequest {
  constructor({ cartId, items }) {
    this.cartId = cartId;
    this.items = items;
  }

  toJson() {
    return {
      cart_id: this.cartId,
      items: this.items.map(item => item.toJson()),
    };
  }

  static fromJson(json) {
    return new RemoveFromCartRequest({
      cartId: json.cart_id,
      items: (json.items || []).map(item => RemovalItem.fromJson(item)),
    });
  }
}

/**
 * Cart response
 */
export class CartResponse {
  constructor({ cartId, items, totalCost, totalList }) {
    this.cartId = cartId;
    this.items = items;
    this.totalCost = totalCost;
    this.totalList = totalList;
  }

  static fromJson(json) {
    return new CartResponse({
      cartId: json.cart_id,
      items: (json.items || []).map(item => CartItem.fromJson(item)),
      totalCost: json.total_cost,
      totalList: json.total_list,
    });
  }
}
