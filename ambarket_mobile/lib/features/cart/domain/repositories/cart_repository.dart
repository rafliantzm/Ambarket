import '../models/cart_item_model.dart';

abstract class CartRepository {
  Future<List<CartItemModel>> fetchCartItems(String userId);
  Future<CartItemModel> addToCart(String userId, String productId);
  Future<void> removeFromCart(String cartItemId);
  Future<void> removeProductFromCart(String userId, String productId);
  Future<void> clearCart(String userId);
}
