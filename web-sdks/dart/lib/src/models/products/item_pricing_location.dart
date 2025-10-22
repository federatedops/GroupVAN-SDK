class ItemPricingLocationModel {
  const ItemPricingLocationModel({
    required this.canOrder,
    required this.cost,
    required this.description,
    required this.id,
    required this.list,
    required this.packCode,
    required this.packQuantity,
    required this.quantityAvailable,
    required this.sortOrder,
    required this.type,
    this.core,
  });

  final bool canOrder;
  final double cost;
  final String description;
  final String id;
  final double list;
  final String packCode;
  final int packQuantity;
  final double quantityAvailable;
  final int sortOrder;
  final int type;
  final double? core;

  factory ItemPricingLocationModel.fromJson(Map<String, dynamic> json) {
    return ItemPricingLocationModel(
      canOrder: json['can_order'],
      cost: json['cost'],
      description: json['description'],
      id: json['id'],
      list: json['list'],
      core: json['core'],
      packCode: json['pack_code'],
      packQuantity: json['pack_quantity'],
      quantityAvailable: json['quantity_available'],
      sortOrder: json['sort_order'],
      type: json['type'],
    );
  }
}
