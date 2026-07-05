import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/marketplace_repository.dart';

class SupabaseMarketplaceRepository implements MarketplaceRepository {
  final SupabaseClient _client;

  SupabaseMarketplaceRepository(this._client);

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name', ascending: true);
    
    return (response as List).map((json) => CategoryModel.fromJson(json)).toList();
  }

  @override
  Future<void> ensureCurrentUserProfile(String userId, {String? name}) async {
    // Check if profile exists
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
        
    if (existing == null) {
      // Insert minimal profile
      await _client.from('profiles').insert({
        'id': userId,
        'name': name ?? 'User',
        'role': 'user', // strictly default role
      });
    }
  }

  @override
  Future<List<ProductModel>> getProducts({String? query, String? categoryId, String? condition, int offset = 0, int limit = 20}) async {
    var filter = _client
        .from('products')
        .select('*, categories(*), product_images(*)')
        .eq('status', 'active');
        
    if (categoryId != null && categoryId.isNotEmpty) {
      filter = filter.eq('category_id', categoryId);
    }
    
    if (condition != null && condition.isNotEmpty) {
      filter = filter.eq('condition', condition);
    }
        
    if (query != null && query.isNotEmpty) {
      filter = filter.or('title.ilike.%$query%,description.ilike.%$query%,brand.ilike.%$query%');
    }
    
    final response = await filter
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
        
    return (response as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<ProductModel> fetchProductDetail(String productId) async {
    final response = await _client
        .from('products')
        .select('*, categories(*), product_images(*)')
        .eq('id', productId)
        .single();
        
    return ProductModel.fromJson(response);
  }

  @override
  Future<List<String>> fetchWishlistProductIds(String userId) async {
    final response = await _client
        .from('wishlists')
        .select('product_id')
        .eq('user_id', userId);
        
    return (response as List).map((json) => json['product_id'] as String).toList();
  }

  @override
  Future<List<ProductModel>> fetchWishlistedProducts(String userId) async {
    final response = await _client
        .from('wishlists')
        .select('products(*, categories(*), product_images(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // The response is a list of wishlists, each containing a 'products' object
    return (response as List)
        .map((json) => json['products'] as Map<String, dynamic>?)
        .where((productJson) => productJson != null)
        .map((productJson) => ProductModel.fromJson(productJson!))
        .toList();
  }

  @override
  Future<void> toggleWishlist(String userId, String productId, bool isCurrentlyWishlisted) async {
    if (isCurrentlyWishlisted) {
      await _client
          .from('wishlists')
          .delete()
          .match({'user_id': userId, 'product_id': productId});
    } else {
      await _client
          .from('wishlists')
          .insert({'user_id': userId, 'product_id': productId});
    }
  }
}
