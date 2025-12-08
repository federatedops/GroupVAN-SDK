import 'cart_item.dart';

class AddToCartRequest {
  final String? cartId;
  final List<CartItem> items;
  final String? purchaseOrderNumber;
  final String? comment;

  const AddToCartRequest({
    this.cartId,
    required this.items,
    this.purchaseOrderNumber,
    this.comment,
  });

  factory AddToCartRequest.fromJson(Map<String, dynamic> json) =>
      AddToCartRequest(
        cartId: json['cart_id'],
        items: json['items'].map((item) => CartItem.fromJson(item)).toList(),
        purchaseOrderNumber: json['purchase_order_number'],
        comment: json['comment'],
      );

  Map<String, dynamic> toJson() => {
    'cart_id': cartId,
    'items': items.map((item) => item.toJson()).toList(),
    'purchase_order_number': purchaseOrderNumber,
    'comment': comment,
  };
}

class RemovalItem {
  final int id;
  final double quantity;

  const RemovalItem({required this.id, required this.quantity});

  factory RemovalItem.fromJson(Map<String, dynamic> json) =>
      RemovalItem(id: json['id'], quantity: json['quantity']);

  Map<String, dynamic> toJson() => {'id': id, 'quantity': quantity};
}

class RemoveFromCartRequest {
  final String cartId;
  final List<RemovalItem> items;

  const RemoveFromCartRequest({required this.cartId, required this.items});

  factory RemoveFromCartRequest.fromJson(Map<String, dynamic> json) =>
      RemoveFromCartRequest(
        cartId: json['cart_id'],
        items: json['items'].map((item) => RemovalItem.fromJson(item)).toList(),
      );

  Map<String, dynamic> toJson() => {
    'cart_id': cartId,
    'items': items.map((item) => item.toJson()).toList(),
  };
}
