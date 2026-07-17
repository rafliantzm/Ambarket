import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/marketplace_repository.dart';

class SupabaseMarketplaceRepository implements MarketplaceRepository {
  final SupabaseClient _client;
  static const _productListSelect = '''
    id,
    seller_id,
    category_id,
    title,
    price,
    condition,
    is_negotiable,
    status,
    created_at,
    categories (id, name, icon, created_at),
    product_images (id, product_id, image_url, is_primary, created_at)
  ''';
  static const _productDetailSelect = '*, categories(*), product_images(*)';

  SupabaseMarketplaceRepository(this._client);

  @override
  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
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
  Future<List<ProductModel>> getProducts({
    String? query,
    String? categoryId,
    String? condition,
    int offset = 0,
    int limit = 20,
  }) async {
    var filter = _client
        .from('products')
        .select(_productListSelect)
        .eq('status', 'active');

    if (categoryId != null && categoryId.isNotEmpty) {
      filter = filter.eq('category_id', categoryId);
    }

    if (condition != null && condition.isNotEmpty) {
      filter = filter.eq('condition', condition);
    }

    if (query != null && query.isNotEmpty) {
      filter = filter.or(
        'title.ilike.%$query%,description.ilike.%$query%,brand.ilike.%$query%',
      );
    }

    final response = await filter
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ProductModel>> fetchRecommendedProducts({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _client
        .from('products')
        .select(_productListSelect)
        .eq('status', 'active')
        .order(
          'created_at',
          ascending: false,
        ) // Using latest as a proxy for recommended for now
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ProductModel>> fetchLatestProducts({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _client
        .from('products')
        .select(_productListSelect)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ProductModel>> fetchBestDealProducts({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _client
        .from('products')
        .select(_productListSelect)
        .eq('status', 'active')
        .order('price', ascending: true) // Lowest price first
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ProductModel>> fetchNearbyProducts(
    String? location, {
    int limit = 10,
    int offset = 0,
  }) async {
    var filter = _client
        .from('products')
        .select(_productListSelect)
        .eq('status', 'active');

    if (location != null && location.isNotEmpty) {
      filter = filter.ilike('location', '%$location%');
    }

    final response = await filter
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ProductModel>> fetchRelatedProducts(
    String productId,
    String categoryId, {
    int limit = 6,
  }) async {
    final response = await _client
        .from('products')
        .select(_productListSelect)
        .eq('status', 'active')
        .eq('category_id', categoryId)
        .neq('id', productId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ProductModel>> fetchSellerActiveProducts(
    String sellerId, {
    String? query,
    String? categoryId,
    int limit = 20,
    int offset = 0,
  }) async {
    var filter = _client
        .from('products')
        .select(_productListSelect)
        .eq('status', 'active')
        .eq('seller_id', sellerId);

    if (categoryId != null && categoryId.isNotEmpty) {
      filter = filter.eq('category_id', categoryId);
    }

    if (query != null && query.isNotEmpty) {
      filter = filter.or(
        'title.ilike.%$query%,description.ilike.%$query%,brand.ilike.%$query%',
      );
    }

    final response = await filter
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  @override
  Future<ProductModel> fetchProductDetail(String productId) async {
    final response = await _client
        .from('products')
        .select(_productDetailSelect)
        .eq('id', productId)
        .single();

    return ProductModel.fromJson(response);
  }
}
