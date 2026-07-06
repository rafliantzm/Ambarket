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

  SupabaseSellerRepository(this._client);

  @override
  Future<List<ProductModel>> fetchMyProducts(String sellerId, {int offset = 0, int limit = 20}) async {
    final response = await _client
        .from('products')
        .select('''
          *,
          categories (*),
          product_images (*)
        ''')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => ProductModel.fromJson(json)).toList();
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
        .select('''
          *,
          categories (*),
          product_images (*)
        ''')
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

    return (response as List).map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<SellerProductStats> fetchSellerProductStats(String sellerId) async {
    // Perform concurrent count queries for different statuses
    final results = await Future.wait([
      _client.from('products').select('id').eq('seller_id', sellerId).count(CountOption.exact),
      _client.from('products').select('id').eq('seller_id', sellerId).eq('status', 'active').count(CountOption.exact),
      _client.from('products').select('id').eq('seller_id', sellerId).eq('status', 'reserved').count(CountOption.exact),
      _client.from('products').select('id').eq('seller_id', sellerId).eq('status', 'sold').count(CountOption.exact),
      _client.from('products').select('id').eq('seller_id', sellerId).eq('status', 'archived').count(CountOption.exact),
      _client.from('products').select('id').eq('seller_id', sellerId).eq('status', 'hidden').count(CountOption.exact),
      _client.from('products').select('id').eq('seller_id', sellerId).eq('status', 'rejected').count(CountOption.exact),
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
  Future<void> reactivateArchivedProduct(String productId, String sellerId) async {
    await updateProductStatus(productId, sellerId, 'active');
  }

  @override
  Future<ProductModel> fetchMyProductDetail(String productId, String sellerId) async {
    final response = await _client
        .from('products')
        .select('''
          *,
          categories (*),
          product_images (*)
        ''')
        .eq('id', productId)
        .eq('seller_id', sellerId)
        .single();

    return ProductModel.fromJson(response);
  }

  @override
  Future<ProductModel> createProduct(String sellerId, CreateProductInput input) async {
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
  Future<void> updateProduct(String productId, String sellerId, UpdateProductInput input) async {
    await _client
        .from('products')
        .update(input.toJson())
        .eq('id', productId)
        .eq('seller_id', sellerId);
  }

  @override
  Future<void> updateProductStatus(String productId, String sellerId, String status) async {
    final updateData = <String, dynamic>{'status': status};
    if (status == 'sold') {
      updateData['sold_at'] = DateTime.now().toIso8601String();
    }
    
    await _client
        .from('products')
        .update(updateData)
        .eq('id', productId)
        .eq('seller_id', sellerId);
  }

  @override
  Future<void> uploadProductImage(String productId, String sellerId, Uint8List imageBytes, bool isPrimary) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Path format: {seller_id}/{product_id}/{timestamp}.jpg
    final imagePath = '$sellerId/$productId/$timestamp.jpg';

    // Upload to Storage
    await _client.storage.from('product-images').uploadBinary(
      imagePath,
      imageBytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );

    // Get public URL
    final imageUrl = _client.storage.from('product-images').getPublicUrl(imagePath);

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

    await _client
        .from('product_images')
        .delete()
        .eq('id', imageId);
  }

  @override
  Future<SellerDashboardStats> fetchSellerDashboardStats(String sellerId) async {
    // Products counts
    final activeProductsRes = await _client.from('products').select('id').eq('seller_id', sellerId).eq('status', 'available').count(CountOption.exact);
    final soldProductsRes = await _client.from('products').select('id').eq('seller_id', sellerId).eq('status', 'sold').count(CountOption.exact);
    final reservedProductsRes = await _client.from('products').select('id').eq('seller_id', sellerId).eq('status', 'reserved').count(CountOption.exact);

    // Orders counts
    final pendingOrdersRes = await _client.from('orders').select('id').eq('seller_id', sellerId).eq('status', 'pending_payment').count(CountOption.exact);
    final paidOrdersRes = await _client.from('orders').select('id').eq('seller_id', sellerId).eq('status', 'paid').count(CountOption.exact);
    final packedOrdersRes = await _client.from('orders').select('id').eq('seller_id', sellerId).eq('status', 'packed').count(CountOption.exact);
    final shippedOrdersRes = await _client.from('orders').select('id').eq('seller_id', sellerId).eq('status', 'shipped').count(CountOption.exact);
    final completedOrdersRes = await _client.from('orders').select('id').eq('seller_id', sellerId).eq('status', 'completed').count(CountOption.exact);

    // Offers counts
    final pendingOffersRes = await _client.from('offers').select('id').eq('seller_id', sellerId).eq('status', 'pending').count(CountOption.exact);

    // Total revenue from completed orders
    final completedOrdersData = await _client.from('orders').select('total_price').eq('seller_id', sellerId).eq('status', 'completed');
    double revenue = 0.0;
    for (var row in completedOrdersData) {
      if (row['total_price'] != null) {
        revenue += (row['total_price'] as num).toDouble();
      }
    }

    // Rating
    // If we have reviews table we could query it. Assuming we don't have direct access or it's heavy, we default to 0 for now
    // If we have a 'profiles' or 'seller_profiles' rating, we could fetch it.
    final profileData = await _client.from('profiles').select('rating, total_reviews').eq('id', sellerId).maybeSingle();
    double avgRating = 0.0;
    int reviewsCount = 0;
    if (profileData != null) {
      if (profileData['rating'] != null) avgRating = (profileData['rating'] as num).toDouble();
      if (profileData['total_reviews'] != null) reviewsCount = profileData['total_reviews'] as int;
    }

    return SellerDashboardStats(
      activeProductsCount: activeProductsRes.count,
      soldProductsCount: soldProductsRes.count,
      reservedProductsCount: reservedProductsRes.count,
      pendingOrdersCount: pendingOrdersRes.count,
      paidOrdersCount: paidOrdersRes.count,
      packedOrdersCount: packedOrdersRes.count,
      shippedOrdersCount: shippedOrdersRes.count,
      completedOrdersCount: completedOrdersRes.count,
      pendingOffersCount: pendingOffersRes.count,
      averageRating: avgRating,
      totalReviews: reviewsCount,
      totalRevenueDummy: revenue,
    );
  }

  @override
  Future<List<OrderModel>> fetchRecentSellerOrders(String sellerId, {int limit = 5}) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).map((json) => OrderModel.fromJson(json)).toList();
  }

  @override
  Future<List<OfferModel>> fetchRecentSellerOffers(String sellerId, {int limit = 5}) async {
    final response = await _client
        .from('offers')
        .select()
        .eq('seller_id', sellerId)
        .eq('status', 'pending') // Usually recent offers are pending offers that need action
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).map((json) => OfferModel.fromJson(json)).toList();
  }
}
