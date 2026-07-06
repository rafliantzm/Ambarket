import 'dart:typed_data';
import '../../../marketplace/domain/models/product_model.dart';
import '../models/create_product_input.dart';
import '../models/seller_dashboard_stats.dart';
import '../../../order/domain/models/order_model.dart';
import '../../../offer/domain/models/offer_model.dart';
import '../models/seller_product_stats.dart';

abstract class SellerRepository {
  Future<List<ProductModel>> fetchMyProducts(String sellerId, {int offset = 0, int limit = 20});
  Future<List<ProductModel>> fetchSellerProductsFiltered(
    String sellerId, {
    String status = 'all',
    String searchQuery = '',
    int limit = 20,
    int offset = 0,
  });
  Future<ProductModel> fetchMyProductDetail(String productId, String sellerId);
  Future<ProductModel> createProduct(String sellerId, CreateProductInput input);
  Future<void> updateProduct(String productId, String sellerId, UpdateProductInput input);
  Future<void> updateProductStatus(String productId, String sellerId, String status);
  Future<void> archiveProduct(String productId, String sellerId);
  Future<void> reactivateArchivedProduct(String productId, String sellerId);
  Future<void> deleteProductImage(String imageId, String sellerId);
  Future<void> uploadProductImage(String productId, String sellerId, Uint8List imageBytes, bool isPrimary);
  Future<SellerProductStats> fetchSellerProductStats(String sellerId);

  // Phase 8E Dashboard
  Future<SellerDashboardStats> fetchSellerDashboardStats(String sellerId);
  Future<List<OrderModel>> fetchRecentSellerOrders(String sellerId, {int limit = 5});
  Future<List<OfferModel>> fetchRecentSellerOffers(String sellerId, {int limit = 5});
}
