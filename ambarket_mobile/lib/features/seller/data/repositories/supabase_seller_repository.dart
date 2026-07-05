import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../marketplace/domain/models/product_model.dart';
import '../../domain/models/create_product_input.dart';
import '../../domain/repositories/seller_repository.dart';

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
}
