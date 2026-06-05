/// Cart API: low-level [CartClient] and public [GroupVANCart].
library;

import '../core/exceptions.dart';
import '../core/response.dart';
import '../logging.dart';
import '../models/models.dart';
import 'base_client.dart';

/// Cart API client for cart item management
class CartClient extends ApiClient {

  const CartClient(super.httpClient, super.authManager);

  /// Add items to cart
  Future<Result<CartResponse>> addToCart({
    required AddToCartRequest request,
  }) async {

    try {
      final response = await patch<Map<String, dynamic>>(
        '/v3/cart/items/add',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(CartResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.cart.severe('Failed to add items to cart: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to add items to cart: $e'),
      );
    }
  }

  /// Remove items from cart
  Future<Result<CartResponse>> removeFromCart({
    required RemoveFromCartRequest request,
  }) async {

    try {
      final response = await patch<Map<String, dynamic>>(
        '/v3/cart/items/remove',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(CartResponse.fromJson(response.data));
    } catch (e) {
      GroupVanLogger.cart.severe('Failed to remove items from cart: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to remove items from cart: $e'),
      );
    }
  }

  /// Checkout a cart, placing orders for all items
  Future<Result<CheckoutResponse>> checkout({
    required CheckoutRequest request,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/v3/cart/checkout',
        data: request.toJson(),
        decoder: (data) => data as Map<String, dynamic>,
      );

      return Success(CheckoutResponse.fromJson(response.data, response.statusCode));
    } catch (e) {
      GroupVanLogger.cart.severe('Failed to checkout cart: $e');
      return Failure(
        e is GroupVanException
            ? e
            : NetworkException('Failed to checkout cart: $e'),
      );
    }
  }
}

/// Namespaced cart API
class GroupVANCart {
  final CartClient _client;

  const GroupVANCart(this._client);

  /// Add items to cart
  Future<CartResponse> addToCart(AddToCartRequest request) async {
    final result = await _client.addToCart(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Remove items from cart
  Future<CartResponse> removeFromCart(RemoveFromCartRequest request) async {
    final result = await _client.removeFromCart(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }

  /// Checkout a cart, placing orders for all items
  Future<CheckoutResponse> checkout(CheckoutRequest request) async {
    final result = await _client.checkout(request: request);
    if (result.isFailure) {
      throw Exception('Unexpected error: ${result.error}');
    }
    return result.value;
  }
}
