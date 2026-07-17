import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../domain/models/create_product_input.dart';
import '../../domain/repositories/seller_repository.dart';
import '../../domain/models/seller_dashboard_stats.dart';
import '../../domain/models/seller_product_stats.dart';
import '../../../order/domain/models/order_model.dart';
import '../../../offer/domain/models/offer_model.dart';

class SupabaseSellerRepository implements SellerRepository {
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
  static const _productDetailSelect = '''
    *,
    categories (*),
    product_images (*)
  ''';

  SupabaseSellerRepository(this._client);

  @override
  Future<List<ProductModel>> fetchMyProducts(
    String sellerId, {
    int offset = 0,
    int limit = 20,
  }) async {
    final response = await _client
        .from('products')
        .select(_productListSelect)
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ProductModel>> fetchSellerProductsFiltered(
    String sellerId, {
    String status = 'all',
    String searchQuery = '',
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client
        .from('products')
        .select(_productListSelect)
        .eq('seller_id', sellerId);

    if (status != 'all') {
      query = query.eq('status', status);
    }

    if (searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$searchQuery%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  @override
  Future<SellerProductStats> fetchSellerProductStats(String sellerId) async {
    // Perform concurrent count queries for different statuses
    final results = await Future.wait([
      _client
          .from('products')
          .select('id')
          .eq('seller_id', sellerId)
          .count(CountOption.exact),
      _client
          .from('products')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('status', 'active')
          .count(CountOption.exact),
      _client
          .from('products')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('status', 'reserved')
          .count(CountOption.exact),
      _client
          .from('products')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('status', 'sold')
          .count(CountOption.exact),
      _client
          .from('products')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('status', 'archived')
          .count(CountOption.exact),
      _client
          .from('products')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('status', 'hidden')
          .count(CountOption.exact),
      _client
          .from('products')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('status', 'rejected')
          .count(CountOption.exact),
    ]);

    return SellerProductStats(
      totalProducts: results[0].count,
      activeProducts: results[1].count,
      reservedProducts: results[2].count,
      soldProducts: results[3].count,
      archivedProducts: results[4].count,
      hiddenProducts: results[5].count,
      rejectedProducts: results[6].count,
    );
  }

  @override
  Future<void> archiveProduct(String productId, String sellerId) async {
    await updateProductStatus(productId, sellerId, 'archived');
  }

  @override
  Future<void> reactivateArchivedProduct(
    String productId,
    String sellerId,
  ) async {
    await updateProductStatus(productId, sellerId, 'active');
  }

  @override
  Future<ProductModel> fetchMyProductDetail(
    String productId,
    String sellerId,
  ) async {
    final response = await _client
        .from('products')
        .select(_productDetailSelect)
        .eq('id', productId)
        .eq('seller_id', sellerId)
        .single();

    return ProductModel.fromJson(response);
  }

  @override
  Future<ProductModel> createProduct(
    String sellerId,
    CreateProductInput input,
  ) async {
    // 1. Insert product
    final productResponse = await _client
        .from('products')
        .insert(input.toJson(sellerId))
        .select()
        .single();

    final productId = productResponse['id'] as String;

    // 2. Upload images with rollback
    if (input.imageBytesList.isNotEmpty) {
      try {
        for (var i = 0; i < input.imageBytesList.length; i++) {
          final bytes = input.imageBytesList[i];
          final isPrimary = i == 0;
          await uploadProductImage(productId, sellerId, bytes, isPrimary);
        }
      } catch (e) {
        // Rollback: Delete the product row if image upload fails
        await _client.from('products').delete().eq('id', productId);
        throw Exception('Gagal mengunggah gambar. Produk dibatalkan: $e');
      }
    }

    // 3. Return full product detail
    return fetchMyProductDetail(productId, sellerId);
  }

  @override
  Future<void> updateProduct(
    String productId,
    String sellerId,
    UpdateProductInput input,
  ) async {
    final updatedProduct = await _client
        .from('products')
        .update(input.toJson())
        .eq('id', productId)
        .eq('seller_id', sellerId)
        .select('id')
        .maybeSingle();

    if (updatedProduct == null) {
      throw Exception(
        'Produk tidak dapat diperbarui. Pastikan produk masih ada dan Anda memiliki akses.',
      );
    }

    if (input.newImageBytesList.isNotEmpty) {
      // 1. Fetch old images
      final oldImages = await _client
          .from('product_images')
          .select('id, image_url')
          .eq('product_id', productId);

      // 2. Delete old images from storage (best effort)
      for (var row in oldImages) {
        try {
          final imageUrl = row['image_url'] as String;
          final urlParts = imageUrl.split('product-images/');
          if (urlParts.length > 1) {
            await _client.storage.from('product-images').remove([urlParts[1]]);
          }
        } catch (_) {}
      }

      // 3. Delete old images from DB
      await _client.from('product_images').delete().eq('product_id', productId);

      // 4. Upload new images
      for (var i = 0; i < input.newImageBytesList.length; i++) {
        await uploadProductImage(
          productId,
          sellerId,
          input.newImageBytesList[i],
          i == 0,
        );
      }
    }
  }

  @override
  Future<void> updateProductStatus(
    String productId,
    String sellerId,
    String status,
  ) async {
    final updateData = <String, dynamic>{'status': status};
    if (status == 'sold') {
      updateData['sold_at'] = DateTime.now().toIso8601String();
    }

    final updatedProduct = await _client
        .from('products')
        .update(updateData)
        .eq('id', productId)
        .eq('seller_id', sellerId)
        .select('id')
        .maybeSingle();

    if (updatedProduct == null) {
      throw Exception(
        'Status produk tidak dapat diperbarui. Pastikan produk masih ada dan Anda memiliki akses.',
      );
    }
  }

  @override
  Future<void> uploadProductImage(
    String productId,
    String sellerId,
    Uint8List imageBytes,
    bool isPrimary,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Path format: {seller_id}/{product_id}/{timestamp}.jpg
    final imagePath = '$sellerId/$productId/$timestamp.jpg';

    // Upload to Storage
    await _client.storage
        .from('product-images')
        .uploadBinary(
          imagePath,
          imageBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    // Get public URL
    final imageUrl = _client.storage
        .from('product-images')
        .getPublicUrl(imagePath);

    // Insert into product_images table
    try {
      await _client.from('product_images').insert({
        'product_id': productId,
        'image_url': imageUrl,
        'is_primary': isPrimary,
      });
    } catch (e) {
      // If DB insert fails, cleanup the uploaded file in Storage
      await _client.storage.from('product-images').remove([imagePath]);
      rethrow;
    }
  }

  @override
  Future<void> deleteProductImage(String imageId, String sellerId) async {
    // 1. Get image info to extract path (optional, for actually deleting from storage)
    final imageResponse = await _client
        .from('product_images')
        .select('image_url, product_id')
        .eq('id', imageId)
        .single();

    final productId = imageResponse['product_id'] as String;

    // Verify seller owns this product
    final productCheck = await _client
        .from('products')
        .select('id')
        .eq('id', productId)
        .eq('seller_id', sellerId)
        .maybeSingle();

    if (productCheck == null) {
      throw Exception('Unauthorized to delete this image');
    }

    // Note: Due to RLS we could technically just attempt delete,
    // but the actual storage bucket object should ideally be deleted too.
    // For now we'll delete the db record, which removes it from UI.
    // To delete from storage, we'd need to parse the URL.
    final imageUrl = imageResponse['image_url'] as String;
    final urlParts = imageUrl.split('product-images/');
    if (urlParts.length > 1) {
      final storagePath = urlParts[1];
      try {
        await _client.storage.from('product-images').remove([storagePath]);
      } catch (e) {
        // Ignore storage delete errors if any, continue to DB delete
      }
    }

    await _client.from('product_images').delete().eq('id', imageId);
  }

  @override
  Future<SellerDashboardStats> fetchSellerDashboardStats(
    String sellerId,
  ) async {
    final results = await Future.wait<dynamic>([
      _client.from('products').select('status').eq('seller_id', sellerId),
      _client
          .from('orders')
          .select('status, total_price, created_at')
          .eq('seller_id', sellerId),
      _client
          .from('offers')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('status', 'pending'),
    ]);

    final products = List<Map<String, dynamic>>.from(results[0] as List);
    final orders = List<Map<String, dynamic>>.from(results[1] as List);
    final pendingOffers = List<Map<String, dynamic>>.from(results[2] as List);

    int countProductsByStatus(String status) {
      return products.where((row) => row['status'] == status).length;
    }

    int countOrdersByStatus(String status) {
      return orders.where((row) => row['status'] == status).length;
    }

    double revenue = 0.0;
    final today = DateTime.now();
    final firstChartDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));
    final salesLast7Days = List<double>.filled(7, 0);

    for (final row in orders) {
      if (row['status'] == 'completed' && row['total_price'] != null) {
        final totalPrice = (row['total_price'] as num).toDouble();
        revenue += totalPrice;

        final createdAt = DateTime.tryParse(
          row['created_at']?.toString() ?? '',
        );
        if (createdAt != null) {
          final orderDay = DateTime(
            createdAt.year,
            createdAt.month,
            createdAt.day,
          );
          final chartIndex = orderDay.difference(firstChartDay).inDays;
          if (chartIndex >= 0 && chartIndex < salesLast7Days.length) {
            salesLast7Days[chartIndex] += totalPrice;
          }
        }
      }
    }

    // Rating and Reviews
    // Note: The profiles table does not have rating and total_reviews columns in the current schema.
    // If you need them, they should be queried from a reviews table or added to profiles.
    double avgRating = 0.0;
    int reviewsCount = 0;

    return SellerDashboardStats(
      activeProductsCount: countProductsByStatus('active'),
      soldProductsCount: countProductsByStatus('sold'),
      reservedProductsCount: countProductsByStatus('reserved'),
      pendingOrdersCount: countOrdersByStatus('pending_payment'),
      paidOrdersCount: countOrdersByStatus('paid'),
      packedOrdersCount: countOrdersByStatus('packed'),
      shippedOrdersCount: countOrdersByStatus('shipped'),
      completedOrdersCount: countOrdersByStatus('completed'),
      pendingOffersCount: pendingOffers.length,
      averageRating: avgRating,
      totalReviews: reviewsCount,
      totalRevenueDummy: revenue,
      salesLast7Days: salesLast7Days,
      cancelledOrdersCount: countOrdersByStatus('cancelled'),
      returnedOrdersCount: countOrdersByStatus('returned'),
    );
  }

  @override
  Future<List<OrderModel>> fetchRecentSellerOrders(
    String sellerId, {
    int limit = 5,
  }) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).map((json) => OrderModel.fromJson(json)).toList();
  }

  @override
  Future<List<OfferModel>> fetchRecentSellerOffers(
    String sellerId, {
    int limit = 5,
  }) async {
    final response = await _client
        .from('offers')
        .select()
        .eq('seller_id', sellerId)
        .eq(
          'status',
          'pending',
        ) // Usually recent offers are pending offers that need action
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).map((json) => OfferModel.fromJson(json)).toList();
  }
}
