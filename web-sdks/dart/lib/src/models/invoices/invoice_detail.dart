/// A single line item inside an invoice
class InvoiceDetail {
  final double itemQuantity;
  final String lineCode;
  final String partNumber;
  final String description;
  final double listPrice;
  final double cost;

  const InvoiceDetail({
    required this.itemQuantity,
    required this.lineCode,
    required this.partNumber,
    required this.description,
    required this.listPrice,
    required this.cost,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) => InvoiceDetail(
    itemQuantity: (json['item_quantity'] as num).toDouble(),
    lineCode: json['line_code'] as String,
    partNumber: json['part_number'] as String,
    description: (json['description'] ?? '') as String,
    listPrice: (json['list_price'] as num).toDouble(),
    cost: (json['cost'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'item_quantity': itemQuantity,
    'line_code': lineCode,
    'part_number': partNumber,
    'description': description,
    'list_price': listPrice,
    'cost': cost,
  };
}
