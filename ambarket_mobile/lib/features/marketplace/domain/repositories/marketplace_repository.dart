import '../models/category_model.dart';
import '../models/product_model.dart';

abstract class MarketplaceRepository {
  Future<void> ensureCurrentUserProfile(String userId, {String? name});
  Future<List<CategoryModel>> fetchCategories();
  Future<List<ProductModel>> getProducts({
    String? query,
    String? categoryId,
    String? condition,
    int offset = 0,
    int limit = 20,
  });

  // Home Sections
  Future<List<ProductModel>> fetchRecommendedProducts({
    int limit = 10,
    int offset = 0,
  });
  Future<List<ProductModel>> fetchLatestProducts({
    int limit = 10,
    int offset = 0,
  });
  Future<List<ProductModel>> fetchBestDealProducts({
    int limit = 10,
    int offset = 0,
  });
  Future<List<ProductModel>> fetchNearbyProducts(
    String? location, {
    int limit = 10,
    int offset = 0,
  });
  Future<List<ProductModel>> fetchRelatedProducts(
    String productId,
    String categoryId, {
    int limit = 6,
  });
  Future<List<ProductModel>> fetchSellerActiveProducts(
    String sellerId, {
    String? query,
    String? categoryId,
    int limit = 20,
    int offset = 0,
  });

  Future<ProductModel> fetchProductDetail(String productId);
}
