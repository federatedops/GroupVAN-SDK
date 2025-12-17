enum CartItemType { member, catalog, labor, miscellaneous }

class CartItem {
  final String mfrCode;
  final String partNumber;
  final double listPrice;
  final double cost;
  final double core;
  final double quantity;
  final String memberNumber;
  final String locationId;
  final CartItemType type;
  final int? sku;
  final int? id;
  final String? partTypeName;
  final String? brand;
  final String? itemGroupKey;
  final String? locationDescription;

  const CartItem({
    required this.mfrCode,
    required this.partNumber,
    required this.listPrice,
    required this.cost,
    required this.core,
    required this.quantity,
    required this.memberNumber,
    required this.locationId,
    required this.type,
    this.sku,
    this.id,
    this.partTypeName,
    this.brand,
    this.itemGroupKey,
    this.locationDescription,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    mfrCode: json['mfr_code'],
    partNumber: json['part_number'],
    listPrice: json['list_price'],
    cost: json['cost'],
    core: json['core'],
    quantity: json['quantity'],
    memberNumber: json['member_number'],
    locationId: json['location_id'],
    type: CartItemType.values.byName(json['item_type']),
    sku: json['sku'],
    id: json['id'],
    partTypeName: json['part_type_name'],
    brand: json['brand'],
    itemGroupKey: json['item_group_key'],
    locationDescription: json['location_description'],
  );

  Map<String, dynamic> toJson() => {
    'mfr_code': mfrCode,
    'part_number': partNumber,
    'list_price': listPrice,
    'cost': cost,
    'core': core,
    'quantity': quantity,
    'member_number': memberNumber,
    'location_id': locationId,
    'item_type': type.name,
    'sku': sku,
    'id': id,
    'part_type_name': partTypeName,
    'brand': brand,
    'item_group_key': itemGroupKey,
    'location_description': locationDescription,
  };
}
