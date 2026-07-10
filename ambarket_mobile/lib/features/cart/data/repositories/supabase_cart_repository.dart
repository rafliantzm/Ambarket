import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/cart_item_model.dart';
import '../../domain/repositories/cart_repository.dart';

class SupabaseCartRepository implements CartRepository {
  final SupabaseClient _client;

  SupabaseCartRepository(this._client);

  @override
  Future<List<CartItemModel>> fetchCartItems(String userId) async {
    final response = await _client
        .from('cart_items')
        .select('*, product:products(*, seller:profiles(*), product_images(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CartItemModel.fromJson(json))
        .toList();
  }

  @override
  Future<CartItemModel> addToCart(String userId, String productId) async {
    // Check if product is active and not owned by user
    final productCheck = await _client
        .from('products')
        .select('seller_id, status')
        .eq('id', productId)
        .single();

    if (productCheck['seller_id'] == userId) {
      throw Exception('Tidak bisa menambahkan produk sendiri ke keranjang.');
    }
    if (productCheck['status'] != 'active') {
      throw Exception('Produk ini tidak tersedia.');
    }

    final response = await _client
        .from('cart_items')
        .insert({'user_id': userId, 'product_id': productId, 'quantity': 1})
        .select('*, product:products(*, seller:profiles(*), product_images(*))')
        .single();

    return CartItemModel.fromJson(response);
  }

  @override
  Future<void> removeFromCart(String cartItemId) async {
    await _client.from('cart_items').delete().eq('id', cartItemId);
  }

  @override
  Future<void> clearCart(String userId) async {
    await _client.from('cart_items').delete().eq('user_id', userId);
  }

  @override
  Future<void> removeProductFromCart(String userId, String productId) async {
    await _client
        .from('cart_items')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }
}
