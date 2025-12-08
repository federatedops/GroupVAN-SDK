import 'cart_item.dart';

class CartResponse {
  final String cartId;
  final List<CartItem> items;

  const CartResponse({required this.cartId, required this.items});

  factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
    cartId: json['cart_id'],
    items: json['items'].map((item) => CartItem.fromJson(item)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'cart_id': cartId,
    'items': items.map((item) => item.toJson()).toList(),
  };
}
