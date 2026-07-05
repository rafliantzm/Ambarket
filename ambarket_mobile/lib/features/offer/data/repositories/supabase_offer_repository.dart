import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/offer_model.dart';
import '../../domain/repositories/offer_repository.dart';

class SupabaseOfferRepository implements OfferRepository {
  final SupabaseClient _client;

  SupabaseOfferRepository(this._client);

  @override
  Future<OfferModel> createOffer(String buyerId, CreateOfferInput input) async {
    // 1. Fetch product to validate seller and status
    final productResp = await _client
        .from('products')
        .select('seller_id, status, is_negotiable')
        .eq('id', input.productId)
        .single();
    
    if (productResp['status'] != 'active') {
      throw Exception('Produk tidak aktif atau sudah terjual.');
    }
    
    if (productResp['is_negotiable'] == false) {
      throw Exception('Produk ini tidak bisa ditawar.');
    }

    if (productResp['seller_id'] == buyerId) {
      throw Exception('Anda tidak bisa menawar produk sendiri.');
    }

    if (productResp['seller_id'] != input.sellerId) {
      throw Exception('Data penjual tidak valid.');
    }

    if (input.offerPrice <= 0) {
      throw Exception('Harga tawaran harus lebih dari 0.');
    }

    // 2. Insert offer
    final response = await _client
        .from('offers')
        .insert(input.toJson(buyerId))
        .select('*, products(*, product_images(*)), buyer:profiles!buyer_id(*), seller:profiles!seller_id(*)')
        .single();
        
    return OfferModel.fromJson(response);
  }

  @override
  Future<List<OfferModel>> fetchMySentOffers(String buyerId) async {
    final response = await _client
        .from('offers')
        .select('*, products(*, product_images(*)), seller:profiles!seller_id(*)')
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => OfferModel.fromJson(json)).toList();
  }

  @override
  Future<List<OfferModel>> fetchMyReceivedOffers(String sellerId) async {
    final response = await _client
        .from('offers')
        .select('*, products(*, product_images(*)), buyer:profiles!buyer_id(*)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => OfferModel.fromJson(json)).toList();
  }

  @override
  Future<List<OfferModel>> fetchOffersForProduct(String productId) async {
    final response = await _client
        .from('offers')
        .select('*, buyer:profiles!buyer_id(*)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => OfferModel.fromJson(json)).toList();
  }

  @override
  Future<void> cancelOffer(String offerId, String buyerId) async {
    await _client
        .from('offers')
        .update({'status': 'cancelled'})
        .eq('id', offerId)
        .eq('buyer_id', buyerId)
        .eq('status', 'pending');
  }

  @override
  Future<void> acceptOffer(String offerId, String sellerId) async {
    await _client
        .from('offers')
        .update({'status': 'accepted'})
        .eq('id', offerId)
        .eq('seller_id', sellerId)
        .eq('status', 'pending');
  }

  @override
  Future<void> rejectOffer(String offerId, String sellerId) async {
    await _client
        .from('offers')
        .update({'status': 'rejected'})
        .eq('id', offerId)
        .eq('seller_id', sellerId)
        .eq('status', 'pending');
  }
}
