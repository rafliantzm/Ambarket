import 'dart:typed_data';
import '../../../marketplace/domain/models/product_model.dart';
import '../models/create_product_input.dart';

abstract class SellerRepository {
  Future<List<ProductModel>> fetchMyProducts(String sellerId, {int offset = 0, int limit = 20});
  Future<ProductModel> fetchMyProductDetail(String productId, String sellerId);
  Future<ProductModel> createProduct(String sellerId, CreateProductInput input);
  Future<void> updateProduct(String productId, String sellerId, UpdateProductInput input);
  Future<void> updateProductStatus(String productId, String sellerId, String status);
  Future<void> deleteProductImage(String imageId, String sellerId);
  Future<void> uploadProductImage(String productId, String sellerId, Uint8List imageBytes, bool isPrimary);
}
