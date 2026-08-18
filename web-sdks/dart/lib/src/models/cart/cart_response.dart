import 'cart_item.dart';

class SavedCart {
  final String cartId;
  final String name;

  const SavedCart({required this.cartId, required this.name});

  factory SavedCart.fromJson(Map<String, dynamic> json) =>
      SavedCart(cartId: json['cart_id'], name: json['name']);

  Map<String, dynamic> toJson() => {'cart_id': cartId, 'name': name};
}

class SavedCartsResponse {
  final List<SavedCart> carts;

  const SavedCartsResponse({required this.carts});

  factory SavedCartsResponse.fromJson(Map<String, dynamic> json) =>
      SavedCartsResponse(
        carts: (json['carts'] as List<dynamic>)
            .map<SavedCart>((cart) => SavedCart.fromJson(cart))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'carts': carts.map((cart) => cart.toJson()).toList(),
  };
}

class CartResponse {
  final String cartId;
  final List<CartItem> items;

  const CartResponse({required this.cartId, required this.items});

  factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
    cartId: json['cart_id'],
    items: (json['items'] as List<dynamic>).map<CartItem>((item) => CartItem.fromJson(item)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'cart_id': cartId,
    'items': items.map((item) => item.toJson()).toList(),
  };
}
