import '../models/category_model.dart';
import '../models/product_model.dart';

abstract class MarketplaceRepository {
  Future<void> ensureCurrentUserProfile(String userId, {String? name});
  Future<List<CategoryModel>> fetchCategories();
  Future<List<ProductModel>> getProducts({String? query, String? categoryId, String? condition, int offset = 0, int limit = 20});
  Future<ProductModel> fetchProductDetail(String productId);
  Future<List<String>> fetchWishlistProductIds(String userId);
  Future<List<ProductModel>> fetchWishlistedProducts(String userId);
  Future<void> toggleWishlist(String userId, String productId, bool isCurrentlyWishlisted);
}
