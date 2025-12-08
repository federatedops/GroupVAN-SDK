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
    type: CartItemType.values.byName(json['type']),
    sku: json['sku'],
    id: json['id'],
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
    'type': type.name,
    'sku': sku,
    'id': id,
  };
}
